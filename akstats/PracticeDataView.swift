import SwiftUI
import UniformTypeIdentifiers

// MARK: - Datasets

/// One of the practice CSV files bundled with the app (the Python-generated versions).
struct PracticeDataset: Identifiable, Hashable {
    enum Group: String, CaseIterable {
        case course = "Course datasets"
        case parasocial = "Parasocial simulation"
        case chatbot = "Chatbot simulation"

        var summary: String {
            switch self {
            case .course: "The simulated datasets used by lessons from Unit 3 onward, each with built-in effects."
            case .parasocial: "Practice simulation: a survey with a credibility task, coded interviews, and a randomized intervention."
            case .chatbot: "Practice simulation: interviews about asking chatbots about court cases — transcripts, chat logs, coding sheets, and coded responses."
            }
        }

        var symbol: String {
            switch self {
            case .course: "tablecells"
            case .parasocial, .chatbot: "flask"
            }
        }
    }

    let name: String
    let group: Group

    var id: String { name }
    var fileName: String { name + ".csv" }
    var url: URL? { PracticeDataset.bundledFile(fileName) }

    /// The description from the *Practice datasets* lesson's key terms.
    var description: String {
        let terms = Curriculum.lesson(id: "practice-data")?.blocks.flatMap { block -> [Term] in
            if case .terms(let list) = block { return list } else { return [] }
        } ?? []
        let match = terms.first { term in
            term.name.components(separatedBy: CharacterSet(charactersIn: " /,")).contains(fileName)
                || (name.hasPrefix("llm_coder_") && term.name.contains("llm_coder_a.csv"))
        }
        return match?.definition ?? ""
    }

    static let all: [PracticeDataset] = {
        let course = ["survey", "diary", "classroom", "essays", "stroop", "stroop_trials", "judgments", "commutes", "habits",
                      "profiles", "missing", "fillers", "poll", "tutoring", "growth"]
        let parasocial = ["ppsr_survey", "credibility_trials", "ppsr_narratives", "ppsr_experiment"]
        let chatbot = ["llm_sessions", "llm_transcripts", "llm_chat_export", "llm_coding", "llm_coder_a", "llm_coder_b",
                       "llm_card_labels", "llm_instrument_coding", "llm_framework", "llm_indexing", "llm_responses"]
        return course.map { PracticeDataset(name: $0, group: .course) }
            + parasocial.map { PracticeDataset(name: $0, group: .parasocial) }
            + chatbot.map { PracticeDataset(name: $0, group: .chatbot) }
    }()

    static let workbookURL = bundledFile("practice_data.xlsx")

    /// Bundled files may sit at the bundle root or in a PracticeData folder, depending on how they're copied.
    static func bundledFile(_ fileName: String) -> URL? {
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext)
            ?? Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "PracticeData")
    }
}

// MARK: - CSV parsing

/// A parsed CSV file: a header row and data rows (RFC 4180 quoting, including quoted newlines).
struct CSVTable {
    let header: [String]
    let rows: [[String]]

    init(header: [String], rows: [[String]]) {
        self.header = header
        self.rows = rows
    }

    init(text: String) {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var scalars = text.unicodeScalars.makeIterator()
        var pending: Unicode.Scalar? = nil
        func next() -> Unicode.Scalar? {
            if let p = pending { pending = nil; return p }
            return scalars.next()
        }
        while let c = next() {
            if inQuotes {
                if c == "\"" {
                    if let following = next() {
                        if following == "\"" { field.unicodeScalars.append("\"") } else { inQuotes = false; pending = following }
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",": record.append(field); field = ""
                case "\r": break
                case "\n": record.append(field); records.append(record); record = []; field = ""
                default: field.unicodeScalars.append(c)
                }
            }
        }
        if !field.isEmpty || !record.isEmpty { record.append(field); records.append(record) }
        header = records.first ?? []
        rows = Array(records.dropFirst())
    }

    /// A one-line summary of each column: its type and what's in it.
    struct ColumnSummary: Identifiable {
        let name: String
        let kind: String
        let missing: Int
        let detail: String
        var id: String { name }
    }

    var columnSummaries: [ColumnSummary] {
        header.indices.map { j in
            let values = rows.map { j < $0.count ? $0[j] : "" }
            let present = values.filter { !$0.isEmpty }
            let numbers = present.compactMap(Double.init)
            if !present.isEmpty && numbers.count == present.count {
                let mean = numbers.reduce(0, +) / Double(numbers.count)
                let detail = "mean \(Self.format(mean)), range \(Self.format(numbers.min()!)) to \(Self.format(numbers.max()!))"
                return ColumnSummary(name: header[j], kind: "number", missing: values.count - present.count, detail: detail)
            }
            let counts = Dictionary(present.map { ($0, 1) }, uniquingKeysWith: +)
            let top = counts.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }.prefix(3)
            let detail = counts.count > 12 && top.first?.value ?? 0 <= 2
                ? "\(counts.count) distinct values"
                : "\(counts.count) values; most common: " + top.map { "\($0.key.prefix(30)) (\($0.value))" }.joined(separator: ", ")
            return ColumnSummary(name: header[j], kind: "text", missing: values.count - present.count, detail: detail)
        }
    }

    private static func format(_ x: Double) -> String {
        x == x.rounded() && abs(x) < 1e7 ? String(Int(x)) : String(format: "%.2f", x)
    }
}

/// Loads and caches parsed datasets so each file is read once per launch.
@MainActor @Observable
final class PracticeDataStore {
    static let shared = PracticeDataStore()
    private(set) var tables: [String: CSVTable] = [:]

    func table(for dataset: PracticeDataset) async -> CSVTable? {
        if let cached = tables[dataset.name] { return cached }
        guard let url = dataset.url else { return nil }
        let parsed = await Task.detached(priority: .userInitiated) { () -> CSVTable? in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return CSVTable(text: text)
        }.value
        if let parsed { tables[dataset.name] = parsed }
        return parsed
    }
}

// MARK: - Exporting files

/// A file to save with the system's save panel.
struct ExportedFile: FileDocument {
    static let xlsx = UTType(filenameExtension: "xlsx") ?? .data
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .zip, xlsx, .data] }

    let data: Data

    init(url: URL) throws { data = try Data(contentsOf: url) }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Copies every CSV into a folder and asks the system to zip it (NSFileCoordinator's "for uploading" read).
func makePracticeDataZip() throws -> URL {
    let fm = FileManager.default
    let folder = fm.temporaryDirectory.appending(path: "practice_data", directoryHint: .isDirectory)
    try? fm.removeItem(at: folder)
    try fm.createDirectory(at: folder, withIntermediateDirectories: true)
    for dataset in PracticeDataset.all {
        if let url = dataset.url { try fm.copyItem(at: url, to: folder.appending(path: dataset.fileName)) }
    }
    if let workbook = PracticeDataset.workbookURL { try fm.copyItem(at: workbook, to: folder.appending(path: "practice_data.xlsx")) }
    let destination = fm.temporaryDirectory.appending(path: "practice_data.zip")
    var coordinatorError: NSError?
    var copyError: Error?
    NSFileCoordinator().coordinate(readingItemAt: folder, options: [.forUploading], error: &coordinatorError) { zipped in
        do {
            try? fm.removeItem(at: destination)
            try fm.copyItem(at: zipped, to: destination)
        } catch {
            copyError = error
        }
    }
    if let error = coordinatorError ?? copyError { throw error }
    return destination
}

// MARK: - Views

struct PracticeDataView: View {
    static let tag = "practice-data-browser"

    /// A dataset to open straight away (from search); cleared once it's shown.
    @Binding var openRequest: String?

    init(openRequest: Binding<String?> = .constant(nil)) {
        _openRequest = openRequest
    }

    @State private var selected: PracticeDataset?
    @State private var export: (file: ExportedFile, name: String, type: UTType)?
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                ForEach(PracticeDataset.Group.allCases, id: \.self) { group in
                    groupSection(group)
                }
            }
            .frame(maxWidth: 960, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Practice data")
        .tint(Theme.accent)
        .task(id: openRequest) {
            guard let name = openRequest else { return }
            selected = PracticeDataset.all.first { $0.name == name }
            openRequest = nil
        }
        .sheet(item: $selected) { dataset in
            DatasetDetailView(dataset: dataset)
                .tint(Theme.accent)
        }
        .fileExporter(isPresented: $isExporting, document: export?.file, contentType: export?.type ?? .data,
                      defaultFilename: export?.name) { result in
            if case .failure(let error) = result { exportMessage = error.localizedDescription }
        }
        .alert("Couldn't save the file", isPresented: Binding(get: { exportMessage != nil }, set: { if !$0 { exportMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice data")
                .font(.largeTitle.weight(.bold))
            Text("Every dataset the course uses, ready to preview and download. These are the files the Python scripts in *Practice datasets* create; the R scripts make files with the same structure but different random numbers. Either works with every exercise's self-check.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button {
                    do {
                        let zip = try makePracticeDataZip()
                        export = (try ExportedFile(url: zip), "practice_data.zip", .zip)
                        isExporting = true
                    } catch {
                        exportMessage = error.localizedDescription
                    }
                } label: {
                    Label("Download all (ZIP)", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                if let workbook = PracticeDataset.workbookURL {
                    Button {
                        do {
                            export = (try ExportedFile(url: workbook), "practice_data.xlsx", ExportedFile.xlsx)
                            isExporting = true
                        } catch {
                            exportMessage = error.localizedDescription
                        }
                    } label: {
                        Label("Excel workbook", systemImage: "tablecells")
                    }
                    .buttonStyle(.bordered)
                    .help("All datasets in one .xlsx file: one sheet each, with frozen, filterable headers and the coding sheet's dropdown lists")
                }
            }
            .controlSize(.large)
        }
    }

    private func groupSection(_ group: PracticeDataset.Group) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(group.rawValue, systemImage: group.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(group == .course ? Theme.textPrimary : Theme.simulation)
            Text(group.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                ForEach(PracticeDataset.all.filter { $0.group == group }) { dataset in
                    DatasetCard(dataset: dataset) { selected = dataset }
                }
            }
        }
    }
}

private struct DatasetCard: View {
    let dataset: PracticeDataset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(dataset.group == .course ? Theme.accent : Theme.simulation)
                    Text(dataset.fileName)
                        .font(.system(.callout, design: .monospaced).weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                markdown(dataset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Label("Preview & download", systemImage: "eye")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .card(padding: 14)
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: Theme.accent, lift: true)
    }
}

/// A dataset's description, a preview of its rows, a summary of its columns, and download buttons.
struct DatasetDetailView: View {
    let dataset: PracticeDataset

    @Environment(\.dismiss) private var dismiss
    @State private var table: CSVTable?
    @State private var tab = Tab.preview
    @State private var isExporting = false
    @State private var exportFile: ExportedFile?

    private enum Tab: String, CaseIterable { case preview = "Rows", columns = "Columns" }
    private static let previewRows = 200

    init(dataset: PracticeDataset, preloaded: CSVTable? = nil) {
        self.dataset = dataset
        _table = State(initialValue: preloaded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataset.fileName)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                    Text(dataset.group.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(dataset.group == .course ? Theme.textSecondary : Theme.simulation)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            markdown(dataset.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                if let table {
                    Text("\(table.rows.count) rows × \(table.header.count) columns")
                        .font(.callout.weight(.medium).monospacedDigit())
                }
                Spacer()
                if let url = dataset.url {
                    Button {
                        exportFile = try? ExportedFile(url: url)
                        isExporting = exportFile != nil
                    } label: {
                        Label("Save CSV…", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            Picker("View", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                if let table {
                    switch tab {
                    case .preview: TablePreview(table: table, limit: Self.previewRows)
                    case .columns: ColumnSummaryList(table: table)
                    }
                } else {
                    ProgressView("Reading \(dataset.fileName)…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            if let table, table.rows.count > Self.previewRows, tab == .preview {
                Text("Showing the first \(Self.previewRows) of \(table.rows.count) rows. Download the file to see them all.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        #if os(macOS)
        .frame(minWidth: 820, idealWidth: 960, minHeight: 600, idealHeight: 720)
        #endif
        .background(Theme.background)
        .task { if table == nil { table = await PracticeDataStore.shared.table(for: dataset) } }
        .fileExporter(isPresented: $isExporting, document: exportFile, contentType: .commaSeparatedText,
                      defaultFilename: dataset.fileName) { _ in }
    }
}

/// The first rows of a table, scrollable in both directions with a pinned header.
private struct TablePreview: View {
    let table: CSVTable
    let limit: Int

    private var widths: [CGFloat] {
        table.header.indices.map { j in
            let longest = ([table.header[j]] + table.rows.prefix(60).map { j < $0.count ? $0[j] : "" }).map(\.count).max() ?? 4
            return min(320, max(60, CGFloat(longest) * 7.5 + 20))
        }
    }

    var body: some View {
        let widths = widths
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(Array(table.rows.prefix(limit).enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(table.header.indices, id: \.self) { j in
                                Text(j < row.count ? row[j] : "")
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(width: widths[j], alignment: .leading)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .help(j < row.count ? row[j] : "")
                            }
                        }
                        .background(index.isMultiple(of: 2) ? Color.clear : Theme.surface.opacity(0.35))
                    }
                } header: {
                    HStack(spacing: 0) {
                        ForEach(table.header.indices, id: \.self) { j in
                            Text(table.header[j])
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .lineLimit(1)
                                .frame(width: widths[j], alignment: .leading)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                        }
                    }
                    .background(Theme.surface)
                }
            }
            .textSelection(.enabled)
        }
        .background(Theme.surface.opacity(0.15), in: .rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.hairline))
    }
}

/// One line per column: its type, missing values, and a quick summary.
private struct ColumnSummaryList: View {
    let table: CSVTable

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(table.columnSummaries) { column in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(column.name)
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                            .frame(width: 200, alignment: .leading)
                        Text(column.kind)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(column.kind == "number" ? Theme.accent : Theme.simulation)
                            .frame(width: 60, alignment: .leading)
                        Text(column.missing == 0 ? "no blanks" : "\(column.missing) blank")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Text(column.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
            .textSelection(.enabled)
        }
    }
}

#Preview("Practice data") {
    NavigationStack { PracticeDataView() }
        .preferredColorScheme(.dark)
}

#Preview("Dataset detail") {
    let dataset = PracticeDataset.all.first { $0.name == "llm_coding" }!
    let table = dataset.url.flatMap { try? String(contentsOf: $0, encoding: .utf8) }.map(CSVTable.init(text:))
    DatasetDetailView(dataset: dataset, preloaded: table)
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
}

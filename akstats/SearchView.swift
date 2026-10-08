import SwiftUI

// MARK: - Index

/// What a search can be narrowed to.
enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case lessons = "Lessons"
    case practice = "Practice"
    case code = "Code"
    case glossary = "Glossary"
    case data = "Data"
    case references = "References"

    var id: String { rawValue }
}

/// Where a search result leads.
enum SearchDestination: Hashable {
    case lesson(id: String, section: String?)
    case dataset(String)
    case references(String)
}

/// A request to scroll an open lesson to a section; a fresh ID lets the same section be requested twice.
struct JumpRequest: Equatable {
    let id = UUID()
    let lessonID: String
    let section: String
}

/// One searchable thing in the course.
struct SearchItem: Identifiable {
    enum Kind: String {
        case lesson = "Lesson"
        case section = "Lesson section"
        case practice = "Practice question"
        case simulation = "Practice simulation"
        case quiz = "Quiz question"
        case code = "Code"
        case term = "Glossary term"
        case dataset = "Dataset"
        case reference = "Reference"

        var scope: SearchScope {
            switch self {
            case .lesson, .section: .lessons
            case .practice, .simulation, .quiz: .practice
            case .code: .code
            case .term: .glossary
            case .dataset: .data
            case .reference: .references
            }
        }

        var symbol: String {
            switch self {
            case .lesson: "book"
            case .section: "text.alignleft"
            case .practice: "square.and.pencil"
            case .simulation: "flask"
            case .quiz: "checklist"
            case .code: "chevron.left.forwardslash.chevron.right"
            case .term: "character.book.closed"
            case .dataset: "tablecells"
            case .reference: "books.vertical"
            }
        }
    }

    let id: Int
    let kind: Kind
    let title: String
    /// Where the item lives, e.g. "Unit 4 · Chi-square".
    let context: String
    /// Text the snippet is drawn from (and that's searched along with the title).
    let body: String
    let destination: SearchDestination
    /// Lowercased, accent-folded title and body.
    let haystack: String
    let titleKey: String
}

enum SearchIndex {
    static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    /// Statistics is written with Greek letters; index them under their names too, so "kappa" finds "κ".
    private static let greek: [(Character, String)] = [("α", "alpha"), ("β", "beta"), ("γ", "gamma"), ("δ", "delta"), ("ε", "epsilon"),
        ("η", "eta"), ("θ", "theta"), ("κ", "kappa"), ("λ", "lambda"), ("μ", "mu"), ("ν", "nu"), ("π", "pi"), ("ρ", "rho"),
        ("σ", "sigma"), ("τ", "tau"), ("φ", "phi"), ("χ", "chi"), ("ψ", "psi"), ("ω", "omega")]

    static func searchable(_ s: String) -> String {
        let folded = fold(s)
        let names = greek.filter { folded.contains($0.0) }.map(\.1)
        return names.isEmpty ? folded : folded + "\n" + names.joined(separator: " ")
    }

    /// Every lesson, section, exercise, code sample, glossary term, dataset, and reference.
    static let items: [SearchItem] = {
        var items: [SearchItem] = []
        func add(_ kind: SearchItem.Kind, _ title: String, _ context: String, _ body: String, _ destination: SearchDestination) {
            items.append(SearchItem(id: items.count, kind: kind, title: title, context: context, body: body,
                                    destination: destination, haystack: searchable(title + "\n" + body), titleKey: searchable(title)))
        }
        for unit in Curriculum.units {
            for lesson in unit.lessons {
                let context = "Unit \(unit.number) · \(lesson.title)"
                let go = { (section: String?) in SearchDestination.lesson(id: lesson.id, section: section) }
                add(.lesson, lesson.title, "Unit \(unit.number) · \(unit.title)", lesson.summary, go(nil))
                if !lesson.explanation.isEmpty {
                    add(.section, "Start here", context,
                        lesson.explanation.map { $0.heading + "\n" + $0.paragraphs.joined(separator: "\n") }.joined(separator: "\n"),
                        go("explanation"))
                }
                for (index, block) in lesson.blocks.enumerated() {
                    let section = "block-\(index)"
                    switch block {
                    case .text(let text):
                        add(.section, text.prefix(60).trimmingCharacters(in: .whitespaces) + "…", context, text, go(section))
                    case .keyPoint(let title, let text), .caution(let title, let text):
                        add(.section, title, context, text, go(section))
                    case .steps(let title, let steps):
                        add(.section, title, context, steps.joined(separator: "\n"), go(section))
                    case .field(let discipline, let text):
                        add(.section, "In the field: \(discipline.rawValue)", context, text, go(section))
                    case .terms(let terms):
                        for term in terms { add(.term, term.name, context, term.definition, go(section)) }
                    case .model(let model):
                        add(.section, model.name, context,
                            ([model.purpose, model.equation ?? ""] + model.steps + model.conditions + [model.reading]).joined(separator: "\n"),
                            go(section))
                    case .chart(let chart):
                        add(.section, chart.title, context, chart.reading.joined(separator: "\n"), go(section))
                    case .code(let sample):
                        let note = Curriculum.codeExplanation(lessonID: lesson.id, caption: sample.caption) ?? ""
                        add(.code, sample.caption, context,
                            [note, sample.python, sample.r, sample.mplus ?? ""].joined(separator: "\n"), go(section))
                    case .exercise(let exercise):
                        addExercise(exercise, context: context, destination: go(section), add: add)
                    }
                }
                for (index, exercise) in lesson.morePractice.enumerated() {
                    addExercise(exercise, context: context + " · More practice", destination: go("practice-\(index)"), add: add)
                }
                for question in lesson.allQuestions {
                    add(.quiz, question.prompt, context,
                        (question.options + [question.explanation]).joined(separator: "\n"), go("quiz"))
                }
            }
        }
        for dataset in PracticeDataset.all {
            let columns = dataset.url.flatMap { try? String(contentsOf: $0, encoding: .utf8) }?
                .split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
            add(.dataset, dataset.fileName, dataset.group.rawValue,
                dataset.description + "\nColumns: " + columns.replacingOccurrences(of: ",", with: ", "), .dataset(dataset.name))
        }
        for reference in Curriculum.references {
            add(.reference, reference.id, "References", reference.citation, .references(reference.id))
        }
        return items
    }()

    private static func addExercise(_ exercise: Exercise, context: String, destination: SearchDestination,
                                    add: (SearchItem.Kind, String, String, String, SearchDestination) -> Void) {
        add(exercise.isPracticeSimulation ? .simulation : .practice, exercise.displayTitle, context,
            [exercise.prompt, exercise.hint ?? "", exercise.answer].joined(separator: "\n"), destination)
        if let solution = exercise.solution {
            addCode(solution, title: "Solution: \(exercise.displayTitle)", context: context, destination: destination, add: add)
        }
        if let check = exercise.selfCheck {
            addCode(check.sample, title: "Self-check: \(exercise.displayTitle)", context: context, destination: destination, add: add)
        }
    }

    private static func addCode(_ sample: CodeSample, title: String, context: String, destination: SearchDestination,
                                add: (SearchItem.Kind, String, String, String, SearchDestination) -> Void) {
        let code = [sample.python, sample.r, sample.mplus ?? ""].joined(separator: "\n")
        add(.code, title, context, code, destination)
    }

    /// Items containing every word of the query, best matches first.
    static func search(_ query: String, scope: SearchScope = .all, limit: Int = 300) -> [SearchItem] {
        let words = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        let matches = items.filter { item in
            (scope == .all || item.kind.scope == scope) && words.allSatisfy { item.haystack.contains($0) }
        }
        func rank(_ item: SearchItem) -> Int {
            var score = 0
            if item.titleKey == words.joined(separator: " ") { score += 100 }
            score += words.filter { item.titleKey.contains($0) }.count * 20
            switch item.kind {
            case .lesson: score += 15
            case .term, .dataset: score += 10
            case .simulation, .practice: score += 6
            case .section, .quiz: score += 3
            case .code, .reference: score += 0
            }
            return score
        }
        return Array(matches.sorted { rank($0) > rank($1) || (rank($0) == rank($1) && $0.id < $1.id) }.prefix(limit))
    }

    /// A one-line excerpt around the first matching word.
    static func snippet(for item: SearchItem, query: String, radius: Int = 70) -> String {
        // Plain text for display: drop Markdown emphasis and code marks
        let flat = item.body.split(whereSeparator: \.isNewline).joined(separator: " ")
            .replacingOccurrences(of: "`", with: "").replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "*", with: "")
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]
        guard let range = words.lazy.compactMap({ flat.range(of: $0, options: options) }).first else {
            return String(flat.prefix(radius * 2))
        }
        let lower = flat.index(range.lowerBound, offsetBy: -radius, limitedBy: flat.startIndex) ?? flat.startIndex
        let upper = flat.index(range.upperBound, offsetBy: radius, limitedBy: flat.endIndex) ?? flat.endIndex
        return (lower > flat.startIndex ? "…" : "") + flat[lower..<upper].trimmingCharacters(in: .whitespaces)
            + (upper < flat.endIndex ? "…" : "")
    }
}

// MARK: - Results view

struct SearchResultsView: View {
    let query: String
    let scope: SearchScope
    let onOpen: (SearchDestination) -> Void

    private var results: [SearchItem] { SearchIndex.search(query, scope: scope) }

    var body: some View {
        let results = results
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Search")
                        .font(.largeTitle.weight(.bold))
                    Text(results.isEmpty ? "No matches" :
                            "\(results.count == 300 ? "300+" : String(results.count)) result\(results.count == 1 ? "" : "s") for “\(query)”" +
                            (scope == .all ? "" : " in \(scope.rawValue)"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    if scope == .all, !results.isEmpty {
                        let counts = Dictionary(grouping: results, by: \.kind.scope).mapValues(\.count)
                        Text(SearchScope.allCases.dropFirst().compactMap { s in counts[s].map { "\(s.rawValue) \($0)" } }
                                .joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.bottom, 14)

                ForEach(results) { item in
                    SearchResultRow(item: item, query: query) { onOpen(item.destination) }
                }

                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .padding(.top, 40)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Search")
    }
}

private struct SearchResultRow: View {
    let item: SearchItem
    let query: String
    let action: () -> Void

    private var tint: Color {
        switch item.kind {
        case .simulation: Theme.simulation
        case .code: Theme.caution
        case .dataset: Theme.simulation
        default: Theme.accent
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.kind.symbol)
                    .font(.callout)
                    .foregroundStyle(tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(item.kind.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(tint.opacity(0.12), in: .capsule)
                            .fixedSize()
                    }
                    Text(item.context)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(highlighted(SearchIndex.snippet(for: item, query: query)))
                        .font(item.kind == .code ? .system(.caption, design: .monospaced) : .callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(cornerRadius: 10)
        .accessibilityLabel("\(item.kind.rawValue): \(item.title), in \(item.context)")
    }

    /// The snippet with each query word in bold.
    private func highlighted(_ snippet: String) -> AttributedString {
        var text = AttributedString(snippet)
        let words = SearchIndex.fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        for word in words {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text[searchStart...].range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) {
                text[range].inlinePresentationIntent = .stronglyEmphasized
                text[range].foregroundColor = Theme.textPrimary
                searchStart = range.upperBound
            }
        }
        return text
    }
}

#Preview("Search results") {
    NavigationStack {
        SearchResultsView(query: "kappa", scope: .all) { _ in }
    }
    .tint(Theme.accent)
    .preferredColorScheme(.dark)
}

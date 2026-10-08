import SwiftUI

/// A searchable list of every work cited in the course, with links to the source.
struct ReferencesView: View {
    static let tag = "references"

    @State private var query: String

    init(initialQuery: String = "") {
        _query = State(initialValue: initialQuery)
    }

    private var results: [Reference] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Curriculum.references }
        return Curriculum.references.filter { $0.citation.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("References")
                        .font(.largeTitle.weight(.bold))
                    Text("\(Curriculum.references.count) books, articles, and software cited in the lessons, in APA style.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 20)

                ForEach(results) { reference in
                    ReferenceRow(reference: reference)
                        .transition(.opacity)
                }

                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .padding(.top, 40)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .searchable(text: $query, prompt: "Search authors, titles, and journals")
        .animation(Theme.animation, value: query)
        .navigationTitle("References")
    }
}

private struct ReferenceRow: View {
    let reference: Reference

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            markdown(reference.citation)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if let link = reference.link {
                Link(destination: link) {
                    Label(reference.doi.map { "doi:\($0)" } ?? link.host() ?? "Open", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Open \(reference.id)")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoverHighlight(cornerRadius: 10)
    }
}

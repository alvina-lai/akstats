import SwiftUI

/// A searchable index of every term defined across the course.
struct GlossaryView: View {
    static let tag = "glossary"

    var onSelect: (Lesson) -> Void

    @State private var query = ""

    private var results: [(term: Term, lesson: Lesson)] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Curriculum.glossary }
        return Curriculum.glossary.filter {
            $0.term.name.localizedCaseInsensitiveContains(trimmed)
                || $0.term.definition.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glossary")
                        .font(.largeTitle.weight(.bold))
                    Text("\(Curriculum.glossary.count) statistics and coding terms, each linked to the lesson that explains it.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 20)

                ForEach(results, id: \.term.name) { entry in
                    GlossaryRow(term: entry.term, lesson: entry.lesson) { onSelect(entry.lesson) }
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
        .searchable(text: $query, prompt: "Search terms and definitions")
        .animation(Theme.animation, value: query)
        .navigationTitle("Glossary")
    }
}

private struct GlossaryRow: View {
    let term: Term
    let lesson: Lesson
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term.name)
                .font(.headline)
            markdown(term.definition)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                Label(lesson.title, systemImage: "arrow.up.right")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .padding(.vertical, 2)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Open lesson \(lesson.title)")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoverHighlight(cornerRadius: 10)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

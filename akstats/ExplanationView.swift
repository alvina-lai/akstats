import SwiftUI

/// Shorthand builders used by the explanation files.
func idea(_ heading: String, _ paragraphs: String...) -> ExplanationSection {
    ExplanationSection(style: .idea, heading: heading, paragraphs: paragraphs)
}

func analogy(_ heading: String, _ paragraphs: String...) -> ExplanationSection {
    ExplanationSection(style: .analogy, heading: heading, paragraphs: paragraphs)
}

func worked(_ heading: String, _ paragraphs: String...) -> ExplanationSection {
    ExplanationSection(style: .example, heading: heading, paragraphs: paragraphs)
}

func inWords(_ heading: String, _ paragraphs: String...) -> ExplanationSection {
    ExplanationSection(style: .inWords, heading: heading, paragraphs: paragraphs)
}

extension Lesson {
    /// The lesson's beginner-level explanation, if one is written.
    var explanation: [ExplanationSection] {
        Curriculum.explanations[id] ?? []
    }

    /// Estimated reading time, including the beginner explanation (~200 words per minute).
    var readingMinutes: Int {
        let words = explanation.flatMap(\.paragraphs).reduce(0) { $0 + $1.split(separator: " ").count }
        return minutes + Int((Double(words) / 200).rounded())
    }
}

extension Curriculum {
    /// Beginner-level explanations, keyed by lesson ID.
    static let explanations: [String: [ExplanationSection]] = explanationsBasics
        .merging(explanationsCore) { $0 + $1 }
        .merging(explanationsAdvanced) { $0 + $1 }
        .merging(explanationsExtra) { $0 + $1 }
        .merging(explanationsSimulations) { $0 + $1 }
}

/// The “Start here” block at the top of a lesson.
struct ExplanationView: View {
    let sections: [ExplanationSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Start here", systemImage: "graduationcap")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)

            ForEach(sections.indices, id: \.self) { index in
                SectionView(section: sections[index])
            }
        }
    }
}

private struct SectionView: View {
    let section: ExplanationSection

    private var symbol: String {
        switch section.style {
        case .idea: "lightbulb"
        case .analogy: "figure.walk"
        case .example: "function"
        case .inWords: "text.quote"
        }
    }

    private var label: String {
        switch section.style {
        case .idea: "The idea"
        case .analogy: "An everyday analogy"
        case .example: "Worked example"
        case .inWords: "Putting it into words"
        }
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(Theme.accent)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(section.heading)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            ForEach(section.paragraphs.indices, id: \.self) { index in
                markdown(section.paragraphs[index])
                    .font(section.style == .example ? .body.monospacedDigit() : .body)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        switch section.style {
        case .idea:
            content
        case .analogy, .inWords:
            content
                .padding(16)
                .background(Theme.surface.opacity(0.6), in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
        case .example:
            content
                .padding(16)
                .background(Theme.surface, in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
                }
        }
    }
}

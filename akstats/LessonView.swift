import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    var onNavigate: (Lesson) -> Void

    @Environment(ProgressStore.self) private var progress

    private var unit: Unit? { Curriculum.unit(containing: lesson) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if !lesson.explanation.isEmpty {
                    ExplanationView(sections: lesson.explanation)
                    Divider().padding(.vertical, 8)
                }

                // Lesson content is static, so position is a stable identity.
                ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }

                if !lesson.morePractice.isEmpty {
                    Divider().padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 4) {
                        Label("More practice", systemImage: "square.and.pencil")
                            .font(.title3.weight(.semibold))
                        Text("\(lesson.morePractice.count) more exercises — try each before opening the solution.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(lesson.morePractice.enumerated()), id: \.offset) { _, exercise in
                        ExerciseView(exercise: exercise)
                    }
                }

                if !lesson.allQuestions.isEmpty {
                    Divider().padding(.vertical, 8)
                    QuizView(questions: lesson.allQuestions) {
                        withAnimation(Theme.animation) { progress.setComplete(lesson, true) }
                    }
                }

                completionButton
                navigationFooter
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(lesson.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let unit {
                HStack(spacing: 8) {
                    Text("Unit \(unit.number) · \(unit.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Tag(text: unit.level.rawValue, color: Theme.color(for: unit.level))
                }
            }
            Text(lesson.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(lesson.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("\(lesson.readingMinutes) min read", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var completionButton: some View {
        let isComplete = progress.isComplete(lesson)
        return Button {
            withAnimation(Theme.animation) { progress.setComplete(lesson, !isComplete) }
        } label: {
            Label(isComplete ? "Completed" : "Mark as complete",
                  systemImage: isComplete ? "checkmark.circle.fill" : "circle")
                .contentTransition(.symbolEffect(.replace))
                .font(.headline)
                .foregroundStyle(isComplete ? Theme.onAccent : Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(isComplete ? Theme.correct : Theme.accent.opacity(0.1))
                }
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: isComplete ? Theme.correct : Theme.accent, lift: true)
    }

    private var navigationFooter: some View {
        HStack(spacing: 12) {
            if let previous = Curriculum.neighbor(of: lesson, offset: -1) {
                NeighborCard(lesson: previous, direction: .previous) { onNavigate(previous) }
            } else {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
            }
            if let next = Curriculum.neighbor(of: lesson, offset: 1) {
                NeighborCard(lesson: next, direction: .next) { onNavigate(next) }
            } else {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
            }
        }
    }
}

private struct NeighborCard: View {
    enum Direction { case previous, next }

    let lesson: Lesson
    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: direction == .next ? .trailing : .leading, spacing: 4) {
                Label(direction == .next ? "Next" : "Previous",
                      systemImage: direction == .next ? "arrow.right" : "arrow.left")
                    .labelStyle(DirectionalLabelStyle(trailingIcon: direction == .next))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(lesson.title)
                    .font(.callout.weight(.medium))
                    .multilineTextAlignment(direction == .next ? .trailing : .leading)
            }
            .frame(maxWidth: .infinity, alignment: direction == .next ? .trailing : .leading)
            .card(padding: 14)
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: Theme.accent, lift: true)
    }
}

#Preview {
    NavigationStack {
        LessonView(lesson: Curriculum.correlation) { _ in }
    }
    .environment(ProgressStore())
}

/// Places the icon after the title for "Next" labels.
private struct DirectionalLabelStyle: LabelStyle {
    let trailingIcon: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            if trailingIcon {
                configuration.title
                configuration.icon
            } else {
                configuration.icon
                configuration.title
            }
        }
    }
}

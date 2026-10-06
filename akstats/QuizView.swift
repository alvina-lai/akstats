import SwiftUI

/// The end-of-lesson knowledge check. Reports when every question has been answered correctly.
struct QuizView: View {
    let questions: [Question]
    var onAllCorrect: () -> Void

    @State private var selections: [Int: Int] = [:]

    private var allCorrect: Bool {
        questions.indices.allSatisfy { selections[$0] == questions[$0].answer }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Check your understanding", systemImage: "checkmark.circle")
                    .font(.title3.weight(.semibold))
                Spacer()
                if !selections.isEmpty {
                    Button {
                        withAnimation(Theme.animation) { selections.removeAll() }
                    } label: {
                        Label("Reset all", systemImage: "arrow.counterclockwise.circle")
                    }
                    .help("Clear every answer in this quiz")
                    .buttonStyle(PressableButtonStyle())
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .hoverHighlight(cornerRadius: 8)
                    .transition(.opacity)
                }
            }

            ForEach(questions.indices, id: \.self) { index in
                QuestionView(
                    number: index + 1,
                    question: questions[index],
                    selection: Binding(
                        get: { selections[index] },
                        set: { selections[index] = $0 }
                    )
                )
            }
        }
        .onChange(of: allCorrect) { _, isCorrect in
            if isCorrect { onAllCorrect() }
        }
    }
}

struct QuestionView: View {
    let number: Int
    let question: Question
    @Binding var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(number). \(question.prompt)")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if selection != nil {
                    // Clears just this question so it can be answered again.
                    Button {
                        withAnimation(Theme.animation) { selection = nil }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .hoverHighlight(cornerRadius: 8)
                    .help("Clear your answer to this question")
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            VStack(spacing: 6) {
                ForEach(question.options.indices, id: \.self) { index in
                    OptionRow(
                        text: question.options[index],
                        state: state(for: index)
                    ) {
                        withAnimation(Theme.animation) { selection = index }
                    }
                    .disabled(selection == question.answer)
                }
            }

            if let selection {
                let isCorrect = selection == question.answer
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                        .foregroundStyle(isCorrect ? Theme.correct : Theme.caution)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isCorrect ? "Correct" : "Not quite — try another answer")
                            .font(.callout.weight(.semibold))
                        if isCorrect {
                            markdown(question.explanation)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((isCorrect ? Theme.correct : Theme.caution).opacity(0.08), in: .rect(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .id(isCorrect)
            }
        }
        .card()
    }

    private func state(for index: Int) -> OptionRow.State {
        guard let selection else { return .idle }
        if index == selection {
            return index == question.answer ? .correct : .incorrect
        }
        return selection == question.answer ? .dimmed : .idle
    }
}

struct OptionRow: View {
    enum State { case idle, correct, incorrect, dimmed }

    let text: String
    let state: State
    let action: () -> Void

    private var tint: Color {
        switch state {
        case .correct: Theme.correct
        case .incorrect: Theme.incorrect
        case .idle, .dimmed: Theme.accent
        }
    }

    private var symbol: String {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .incorrect: "xmark.circle.fill"
        case .idle, .dimmed: "circle"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(state == .idle || state == .dimmed ? Theme.textSecondary : tint)
                    .contentTransition(.symbolEffect(.replace))
                markdown(text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(state == .correct || state == .incorrect ? tint.opacity(0.12) : Color.clear)
            }
            .opacity(state == .dimmed ? 0.45 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: Theme.accent, cornerRadius: 10)
        .accessibilityAddTraits(state == .correct ? .isSelected : [])
    }
}

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Renders a single lesson content block.
struct BlockView: View {
    let block: Block

    var body: some View {
        switch block {
        case .text(let text):
            markdown(text)
                .font(.body)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .keyPoint(let title, let body):
            CalloutView(title: title, message: body, symbol: "lightbulb.max", tint: Theme.accent)
        case .caution(let title, let body):
            CalloutView(title: title, message: body, symbol: "exclamationmark.triangle", tint: Theme.caution)
        case .code(let sample):
            CodeBlockView(sample: sample)
        case .field(let discipline, let text):
            FieldExampleView(discipline: discipline, text: text)
        case .terms(let terms):
            TermsView(terms: terms)
        case .steps(let title, let steps):
            StepsView(title: title, steps: steps)
        case .exercise(let exercise):
            ExerciseView(exercise: exercise)
        case .model(let explainer):
            ModelExplainerView(explainer: explainer)
        case .chart(let example):
            ChartExampleView(example: example)
        }
    }
}

// MARK: - Model explainer

/// A card that explains a model: purpose, equation, mechanics, conditions, and further reading.
struct ModelExplainerView: View {
    let explainer: ModelExplainer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("How the model works", systemImage: "gearshape.2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                Text(explainer.name)
                    .font(.title3.weight(.semibold))
                markdown(explainer.purpose)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let equation = explainer.equation {
                Text(equation)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.background.opacity(0.6), in: .rect(cornerRadius: 10, style: .continuous))
            }

            section("How it works", symbol: "list.number") {
                ForEach(explainer.steps.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                        markdown(explainer.steps[index])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            section("Conditions to check", symbol: "checklist") {
                ForEach(explainer.conditions.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.correct)
                        markdown(explainer.conditions[index])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Label {
                markdown("Read more: \(explainer.reading)")
            } icon: {
                Image(systemName: "book")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.05), in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
        }
        .hoverHighlight(tint: Theme.accent)
    }

    private func section<Content: View>(_ title: String, symbol: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content()
        }
    }
}

// MARK: - Steps

/// A numbered walkthrough, e.g. setting up an editor.
struct StepsView: View {
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                        .frame(width: 22, height: 22)
                        .background(Theme.accent.opacity(0.12), in: .circle)
                    markdown(steps[index])
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .hoverHighlight(cornerRadius: 10)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Exercises

/// A practice task. The hint and the solution are revealed separately so learners try first.
struct ExerciseView: View {
    let exercise: Exercise

    @State private var showsHint = false
    @State private var showsSolution = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Tag(text: "Practice", symbol: "square.and.pencil", color: Theme.accent)
                Text(exercise.title)
                    .font(.headline)
            }

            markdown(exercise.prompt)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if exercise.hint != nil {
                    RevealButton(title: "Hint", symbol: "lightbulb", isOn: $showsHint)
                }
                RevealButton(title: "Solution", symbol: "checkmark.seal", isOn: $showsSolution)
            }

            if showsHint, let hint = exercise.hint {
                CalloutView(title: "Hint", message: hint, symbol: "lightbulb", tint: Theme.caution)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if showsSolution {
                VStack(alignment: .leading, spacing: 12) {
                    if let solution = exercise.solution {
                        CodeBlockView(sample: solution)
                    }
                    CalloutView(title: "What you should find", message: exercise.answer,
                                symbol: "checkmark.seal", tint: Theme.correct)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct RevealButton: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(Theme.animation) { isOn.toggle() }
        } label: {
            Label(isOn ? "Hide \(title.lowercased())" : "Show \(title.lowercased())", systemImage: symbol)
                .font(.callout.weight(.medium))
                .foregroundStyle(isOn ? Theme.onAccent : Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn ? Theme.accent : Theme.accent.opacity(0.1), in: .capsule)
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: Theme.accent, cornerRadius: 20)
    }
}

// MARK: - Callouts

/// A tinted, accent-barred panel for content that must stand out.
struct CalloutView: View {
    let title: String
    let message: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Capsule()
                .fill(tint)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(tint)
                markdown(message)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
        .hoverHighlight(tint: tint)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Field examples

struct FieldExampleView: View {
    let discipline: Discipline
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("In the field")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Tag(text: discipline.rawValue, symbol: discipline.symbol, color: Theme.color(for: discipline))
            }
            markdown(text)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(padding: 16)
        .hoverHighlight(tint: Theme.color(for: discipline))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Glossary

struct TermsView: View {
    let terms: [Term]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Key terms")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

            ForEach(terms, id: \.name) { term in
                VStack(alignment: .leading, spacing: 3) {
                    Text(term.name)
                        .font(.callout.weight(.semibold))
                    markdown(term.definition)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hoverHighlight(cornerRadius: 10)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Code

/// A code listing with a language toggle that is shared across the whole app.
///
/// `codeLanguage` always holds Python or R. `showsMplus` is a separate preference, so
/// choosing Mplus switches every Mplus-capable block while blocks without an Mplus
/// version keep showing the learner's Python/R choice.
struct CodeBlockView: View {
    let sample: CodeSample

    @AppStorage("codeLanguage") private var language: CodeLanguage = .python
    @AppStorage("showsMplus") private var showsMplus = false
    @State private var copied = false

    private var displayed: CodeLanguage {
        showsMplus && sample.mplus != nil ? .mplus : language
    }

    private var source: String { sample.source(for: displayed) }

    private var selection: Binding<CodeLanguage> {
        Binding(
            get: { displayed },
            set: { newValue in
                if newValue == .mplus {
                    showsMplus = true
                } else {
                    language = newValue
                    showsMplus = false
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sample.caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    LanguageToggle(options: sample.languages, selection: selection)
                    Spacer()
                    Button(action: copy) {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.medium))
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(copied ? Theme.correct : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .hoverHighlight(cornerRadius: 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(displayed.color.opacity(0.10))

                Rectangle()
                    .fill(displayed.color.opacity(0.6))
                    .frame(height: 1)

                ScrollView(.horizontal) {
                    Text(SyntaxHighlighter.highlight(source, commentMarker: displayed.commentMarker))
                        .font(.system(.callout, design: .monospaced))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(16)
                        .id(displayed)
                        .transition(.opacity.combined(with: .offset(y: 6)))
                }
                .scrollIndicators(.hidden)
            }
            .background(Color(hex: 0x111827))
            .overlay(alignment: .top) {
                // A colored top edge identifies the language at a glance.
                Rectangle()
                    .fill(displayed.color)
                    .frame(height: 3)
            }
            .clipShape(.rect(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(displayed.color.opacity(0.35), lineWidth: 1)
            }
            .animation(Theme.animation, value: displayed)
        }
    }

    private func copy() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(source, forType: .string)
        #else
        UIPasteboard.general.string = source
        #endif
        withAnimation(Theme.animation) { copied = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(Theme.animation) { copied = false }
        }
    }
}

/// The app-wide Python/R preference as a two-position slide switch.
///
/// Tap to flip, or drag the knob. Sized to match the platform's toolbar search field.
/// Choosing either language also turns off the Mplus view in code blocks.
struct LanguageSwitch: View {
    @AppStorage("codeLanguage") private var language: CodeLanguage = .python
    @AppStorage("showsMplus") private var showsMplus = false
    @GestureState(resetTransaction: Transaction(animation: LanguageSwitch.spring))
    private var dragOffset: CGFloat = 0

    private static let spring = Animation.spring(response: 0.35, dampingFraction: 0.82)

    #if os(macOS)
    private let height: CGFloat = 28
    #else
    private let height: CGFloat = 36
    #endif
    private let width: CGFloat = 124
    private let inset: CGFloat = 2

    private var isR: Bool { language == .r }

    var body: some View {
        let knobWidth = width / 2
        let travel = width - knobWidth
        let resting = isR ? travel : 0
        let knobX = min(max(resting + dragOffset, 0), travel)

        ZStack(alignment: .leading) {
            Capsule()
                .fill(Theme.surface)

            Capsule()
                .fill(language.color)
                .frame(width: knobWidth - inset * 2, height: height - inset * 2)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                .offset(x: knobX + inset)

            HStack(spacing: 0) {
                segmentLabel(.python, isSelected: !isR)
                segmentLabel(.r, isSelected: isR)
            }
        }
        .frame(width: width, height: height)
        .contentShape(.capsule)
        .onTapGesture { select(isR ? .python : .r) }
        .gesture(
            DragGesture(minimumDistance: 4)
                .updating($dragOffset) { value, state, _ in state = value.translation.width }
                .onEnded { value in
                    select(resting + value.translation.width > travel / 2 ? .r : .python)
                }
        )
        .animation(Self.spring, value: language)
        .hoverHighlight(tint: language.color, cornerRadius: height / 2)
        .help("Show code in Python or R")
        .accessibilityElement()
        .accessibilityLabel("Code language")
        .accessibilityValue(language.rawValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { select(isR ? .python : .r) }
        .accessibilityAdjustableAction { direction in
            select(direction == .increment ? .r : .python)
        }
    }

    private func segmentLabel(_ option: CodeLanguage, isSelected: Bool) -> some View {
        Text(option.rawValue)
            .font(.callout.weight(.semibold))
            .foregroundStyle(isSelected ? Theme.onAccent : option.color.opacity(0.85))
            .frame(maxWidth: .infinity)
    }

    private func select(_ newValue: CodeLanguage) {
        language = newValue
        showsMplus = false
    }
}

/// A compact segmented control with a sliding selection pill.
struct LanguageToggle: View {
    var options: [CodeLanguage] = [.python, .r]
    @Binding var selection: CodeLanguage
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { language in
                let isSelected = language == selection
                Button {
                    withAnimation(.smooth(duration: 0.35)) { selection = language }
                } label: {
                    Text(language.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? Theme.onAccent : language.color.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(language.color)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .hoverHighlight(tint: language.color, cornerRadius: 20)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Theme.surface, in: .capsule)
    }
}

/// Minimal highlighting: dims comments and tints string literals.
/// Python and R comment with `#`; Mplus comments with `!`.
enum SyntaxHighlighter {
    private enum Kind { case plain, string, comment }

    static func highlight(_ code: String, commentMarker: Character = "#") -> AttributedString {
        var result = AttributedString()
        var buffer = ""
        var kind = Kind.plain
        var quote: Character?

        func flush() {
            guard !buffer.isEmpty else { return }
            var piece = AttributedString(buffer)
            switch kind {
            case .plain: break
            case .string: piece.foregroundColor = .teal
            case .comment: piece.foregroundColor = .secondary
            }
            result += piece
            buffer = ""
        }

        for character in code {
            switch kind {
            case .comment where character == "\n":
                flush()
                kind = .plain
                buffer.append(character)
            case .string where character == quote:
                buffer.append(character)
                flush()
                kind = .plain
                quote = nil
            case .plain where character == commentMarker:
                flush()
                kind = .comment
                buffer.append(character)
            case .plain where character == "\"" || character == "'":
                flush()
                kind = .string
                quote = character
                buffer.append(character)
            default:
                buffer.append(character)
            }
        }
        flush()
        return result
    }
}

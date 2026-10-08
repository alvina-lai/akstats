import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    /// A section to scroll to (from search), if any.
    var jump: JumpRequest? = nil
    var onNavigate: (Lesson) -> Void

    @Environment(ProgressStore.self) private var progress

    /// The ID of the top-most section on screen (see `Section`), kept in sync by the scroll view.
    @State private var position: String?
    /// The learner's bookmark, captured when the lesson opens so the banner can offer it.
    @State private var resumeTarget: String?

    private var unit: Unit? { Curriculum.unit(containing: lesson) }

    /// The section the learner bookmarked in this lesson, if any.
    private var bookmark: String? { progress.bookmark(for: lesson) }

    /// The section at the top of the screen can be bookmarked once the learner has scrolled
    /// past the lesson header.
    private var canBookmarkHere: Bool {
        guard let position, position != Section.header else { return false }
        return sectionTitle(position) != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let resumeTarget, let title = sectionTitle(resumeTarget) {
                        ResumeBanner(sectionTitle: title) {
                            withAnimation(Theme.animation) { position = resumeTarget }
                            self.resumeTarget = nil
                        } dismiss: {
                            withAnimation(Theme.animation) { self.resumeTarget = nil }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .id(Section.header)

                if !lesson.explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 28) {
                        ExplanationView(sections: lesson.explanation)
                        Divider().padding(.vertical, 8)
                    }
                    .bookmarkTarget(Section.explanation, current: bookmark, onSet: setBookmark)
                }

                // Lesson content is static, so position is a stable identity.
                ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { index, block in
                    BlockView(block: block)
                        .bookmarkTarget(Section.block(index), current: bookmark, onSet: setBookmark)
                }

                if !lesson.morePractice.isEmpty {
                    VStack(alignment: .leading, spacing: 28) {
                        Divider().padding(.vertical, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Label("More practice", systemImage: "square.and.pencil")
                                .font(.title3.weight(.semibold))
                            Text("\(lesson.morePractice.count) more exercises — try each before opening the solution.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .bookmarkTarget(Section.morePractice, current: bookmark, onSet: setBookmark)
                    ForEach(Array(lesson.morePractice.enumerated()), id: \.offset) { index, exercise in
                        ExerciseView(exercise: exercise)
                            .bookmarkTarget(Section.practice(index), current: bookmark, onSet: setBookmark)
                    }
                }

                if !lesson.allQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 28) {
                        Divider().padding(.vertical, 8)
                        QuizView(questions: lesson.allQuestions) {
                            withAnimation(Theme.animation) { progress.setComplete(lesson, true) }
                        }
                    }
                    .bookmarkTarget(Section.quiz, current: bookmark, onSet: setBookmark)
                }

                VStack(alignment: .leading, spacing: 28) {
                    completionButton
                    navigationFooter
                }
                .bookmarkTarget(Section.end, current: bookmark, onSet: setBookmark)
            }
            .scrollTargetLayout()
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .scrollPosition(id: $position, anchor: .top)
        .environment(\.lessonID, lesson.id)
        .onAppear {
            if let saved = bookmark, saved != Section.header, jump == nil {
                resumeTarget = saved
            }
        }
        .task(id: jump?.id) {
            guard let jump else { return }
            try? await Task.sleep(for: .milliseconds(150))   // let the lesson lay out first
            resumeTarget = nil
            withAnimation(Theme.animation) { position = jump.section }
        }
        // Moved or removed (here or from the sidebar): stop offering the old spot.
        .onChange(of: bookmark) { _, newValue in
            if resumeTarget != nil, newValue != resumeTarget {
                withAnimation(Theme.animation) { resumeTarget = nil }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                bookmarkControl
            }
        }
        .navigationTitle(lesson.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// Bookmarks are set by hand: a plain button when there's none, or a menu to jump to,
    /// move, or remove the existing one.
    @ViewBuilder
    private var bookmarkControl: some View {
        if let saved = bookmark {
            Menu {
                Button("Go to Bookmark", systemImage: "arrow.down") {
                    withAnimation(Theme.animation) { position = saved }
                    resumeTarget = nil
                }
                Button("Move Bookmark Here", systemImage: "bookmark") {
                    bookmarkHere()
                }
                .disabled(!canBookmarkHere || position == saved)
                Divider()
                Button("Remove Bookmark", systemImage: "bookmark.slash", role: .destructive) {
                    withAnimation(Theme.animation) { progress.removeBookmark(for: lesson) }
                }
            } label: {
                Label("Bookmark", systemImage: "bookmark.fill")
            }
            .help("Bookmarked: \(sectionTitle(saved) ?? "this lesson")")
        } else {
            Button("Bookmark This Spot", systemImage: "bookmark") {
                bookmarkHere()
            }
            .disabled(!canBookmarkHere)
            .help(canBookmarkHere ? "Bookmark the section at the top of the screen"
                                  : "Scroll to the spot you want to bookmark")
        }
    }

    /// Bookmarks a section (or removes the bookmark with `nil`), from the right-click menu.
    private func setBookmark(_ section: String?) {
        withAnimation(Theme.animation) { progress.setBookmark(section, for: lesson) }
    }

    private func bookmarkHere() {
        guard canBookmarkHere, let position else { return }
        withAnimation(Theme.animation) { progress.setBookmark(position, for: lesson) }
    }

    /// Stable string IDs for each scroll target in the lesson, saved as bookmarks.
    private enum Section {
        static let header = "header"
        static let explanation = "explanation"
        static let morePractice = "more-practice"
        static let quiz = "quiz"
        static let end = "end"
        static func block(_ index: Int) -> String { "block-\(index)" }
        static func practice(_ index: Int) -> String { "practice-\(index)" }
    }

    /// A readable name for a bookmarked section, or `nil` if it no longer exists.
    private func sectionTitle(_ id: String) -> String? {
        switch id {
        case Section.explanation: return "Start here"
        case Section.morePractice: return "More practice"
        case Section.quiz: return "Check your understanding"
        case Section.end: return "the end of the lesson"
        default: break
        }
        if id.hasPrefix("block-"), let index = Int(id.dropFirst("block-".count)),
           lesson.blocks.indices.contains(index) {
            // Plain text has no title, so name it after the nearest titled block above it.
            let titled = lesson.blocks[...index].reversed().lazy.compactMap(\.outlineTitle).first
            return titled ?? "the introduction"
        }
        if id.hasPrefix("practice-"), let index = Int(id.dropFirst("practice-".count)),
           lesson.morePractice.indices.contains(index) {
            return "More practice: \(lesson.morePractice[index].title)"
        }
        return nil
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
            if let first = lesson.practiceSimulations.first {
                let count = lesson.practiceSimulationCount
                Button {
                    withAnimation(Theme.animation) { position = first.sectionID }
                } label: {
                    Label("\(count) practice-simulation exercise\(count == 1 ? "" : "s") · jump to \(count == 1 ? "it" : "the first")",
                          systemImage: "flask")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.simulation)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.simulation.opacity(0.12), in: .capsule)
                }
                .buttonStyle(PressableButtonStyle())
                .hoverHighlight(tint: Theme.simulation)
                .help("Exercises that use the practice simulations' data")
            }
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

private extension Block {
    /// A short name for the block, used to describe a bookmark. Plain text has none.
    var outlineTitle: String? {
        switch self {
        case .text: nil
        case .keyPoint(let title, _), .caution(let title, _), .steps(let title, _): title
        case .code(let sample): sample.caption
        case .field(let discipline, _): "In the field: \(discipline.rawValue)"
        case .terms: "Key terms"
        case .exercise(let exercise): exercise.isPracticeSimulation ? exercise.title : "Practice: \(exercise.title)"
        case .model(let explainer): explainer.name
        case .chart(let example): example.title
        }
    }
}

/// Offers to jump to the learner's bookmark when the lesson opens.
private struct ResumeBanner: View {
    let sectionTitle: String
    let resume: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: resume) {
                HStack(spacing: 10) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Go to your bookmark")
                            .font(.callout.weight(.semibold))
                        Text(sectionTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.down")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Go to your bookmark: \(sectionTitle)")

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
            .buttonStyle(PressableButtonStyle())
            .help("Hide")
            .accessibilityLabel("Hide")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.accent.opacity(0.1), in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
        .hoverHighlight(tint: Theme.accent)
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

/// Marks a scroll target and, when it holds the learner's bookmark, shows a ribbon in the margin.
private struct BookmarkTarget: ViewModifier {
    let id: String
    /// The section currently bookmarked in this lesson, if any.
    let current: String?
    let onSet: (String?) -> Void

    private var isBookmarked: Bool { current == id }

    func body(content: Content) -> some View {
        content
            .id(id)
            .overlay(alignment: .topLeading) {
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.accent)
                        .offset(x: -22, y: 2)   // sits in the lesson's side margin
                        .transition(.scale(scale: 0.5, anchor: .top).combined(with: .opacity))
                        .accessibilityLabel("Bookmark")
                }
            }
            // Right-click (or long-press) any section to bookmark it
            .contextMenu {
                if isBookmarked {
                    Button("Remove Bookmark", systemImage: "bookmark.slash", role: .destructive) { onSet(nil) }
                } else {
                    Button(current == nil ? "Bookmark This Section" : "Move Bookmark Here", systemImage: "bookmark") { onSet(id) }
                }
            }
    }
}

private extension View {
    func bookmarkTarget(_ id: String, current: String?, onSet: @escaping (String?) -> Void) -> some View {
        modifier(BookmarkTarget(id: id, current: current, onSet: onSet))
    }
}

import SwiftUI

struct ContentView: View {
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } detail: {
            ZStack {
                if let lesson = Curriculum.lesson(id: selection) {
                    LessonView(lesson: lesson) { selection = $0.id }
                        .id(lesson.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 16)),
                            removal: .opacity
                        ))
                } else if selection == GlossaryView.tag {
                    GlossaryView { selection = $0.id }
                        .transition(.opacity)
                } else {
                    HomeView { selection = $0.id }
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .animation(.smooth(duration: 0.4), value: selection)
            .toolbar {
                // Global Python/R switch: every code block in the app follows it.
                ToolbarItem(placement: .primaryAction) {
                    LanguageSwitch()
                }
                .sharedBackgroundVisibility(.hidden)   // no extra glass bar behind the switch

            }
        }
        .tint(Theme.accent)
        // Off-white primary text and cool-gray secondary text everywhere, on a dark scheme.
        .foregroundStyle(Theme.textPrimary, Theme.textSecondary, Theme.textSecondary.opacity(0.7))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: String?
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        List(selection: $selection) {
            Section {
                Label { Text("Overview") } icon: { Image(systemName: "house").foregroundStyle(Theme.accent) }
                    .tag(HomeView.tag)
                Label { Text("Glossary") } icon: { Image(systemName: "character.book.closed").foregroundStyle(Theme.accent) }
                    .tag(GlossaryView.tag)
            }

            ForEach(Curriculum.units) { unit in
                Section {
                    ForEach(unit.lessons) { lesson in
                        SidebarRow(lesson: lesson, isComplete: progress.isComplete(lesson))
                            .tag(lesson.id)
                    }
                } header: {
                    // Level sits inline after the title (not pinned to the trailing edge),
                    // so it never collides with the sidebar edge or the section's disclosure control.
                    HStack(spacing: 6) {
                        Text("\(unit.number). \(unit.title)")
                            .lineLimit(1)
                            .layoutPriority(1)
                        Text(unit.level.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.color(for: unit.level))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.color(for: unit.level).opacity(0.12), in: .capsule)
                            .fixedSize()
                    }
                    .padding(.trailing, 12)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Stats Lab")
    }
}

private struct SidebarRow: View {
    let lesson: Lesson
    let isComplete: Bool

    private var incompleteSymbol: String {
        lesson.isReview ? "flag.checkered" : "circle"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : incompleteSymbol)
                .foregroundStyle(isComplete ? Theme.correct
                                 : lesson.isReview ? Theme.accent : Theme.textSecondary.opacity(0.6))
                .contentTransition(.symbolEffect(.replace))
                .animation(Theme.animation, value: isComplete)
            VStack(alignment: .leading, spacing: 1) {
                Text(lesson.title)
                    .fontWeight(lesson.isReview ? .semibold : .regular)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(lesson.readingMinutes) min")
                    if lesson.isReview {
                        Text("Review")
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.accent)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isComplete ? "Completed" : "Not completed")
    }
}

// MARK: - Home

struct HomeView: View {
    static let tag = "home"

    var onSelect: (Lesson) -> Void

    @Environment(ProgressStore.self) private var progress

    private var overall: Double { progress.fraction(of: Curriculum.allLessons) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                hero
                continueCard
                preferences

                VStack(alignment: .leading, spacing: 14) {
                    Text("Course map")
                        .font(.title2.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                        ForEach(Curriculum.units) { unit in
                            UnitCard(unit: unit, fraction: progress.fraction(of: unit.lessons)) {
                                if let lesson = unit.lessons.first(where: { !progress.isComplete($0) }) ?? unit.lessons.first {
                                    onSelect(lesson)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 880, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Overview")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Research statistics,\nfrom the ground up.")
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text("Learn the methods psychologists, linguists, and sociologists actually use — with every example in both Python and R.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var continueCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your progress")
                    .font(.headline)
                Spacer()
                Text(overall, format: .percent.precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
            }
            ProgressBar(value: overall)

            if let next = progress.nextLesson {
                Button { onSelect(next) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(progress.completed.isEmpty ? "Start learning" : "Continue")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.onAccent.opacity(0.75))
                            Text(next.title)
                                .font(.headline)
                                .foregroundStyle(Theme.onAccent)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .foregroundStyle(Theme.onAccent)
                    }
                    .padding(16)
                    .background(Theme.accent, in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .hoverHighlight(tint: Theme.accent, lift: true)
            } else {
                Label("Course complete — nice work.", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.correct)
            }
        }
        .card(padding: 20)
    }

    private var preferences: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Preferred language")
                    .font(.headline)
                Text("Every code sample can switch at any time.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            LanguageSwitch()
        }
    }
}

private struct UnitCard: View {
    let unit: Unit
    let fraction: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: unit.symbol)
                        .font(.title2)
                        .foregroundStyle(Theme.color(for: unit.level))
                    Spacer()
                    Tag(text: unit.level.rawValue, color: Theme.color(for: unit.level))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit \(unit.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(unit.title)
                        .font(.headline)
                    Text(unit.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    ProgressBar(value: fraction, tint: Theme.color(for: unit.level))
                    Text("\(unit.lessons.count) lessons")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .card()
        }
        .buttonStyle(PressableButtonStyle())
        .hoverHighlight(tint: Theme.color(for: unit.level), lift: true)
    }
}

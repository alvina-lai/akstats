import SwiftUI

struct ContentView: View {
    @State private var selection: String?
    @State private var searchText = ""
    @State private var searchScope = SearchScope.all
    @State private var jump: JumpRequest?
    @State private var datasetRequest: String?
    @State private var referenceQuery = ""
    @State private var openedFromSearch = false

    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
                .searchable(text: $searchText, placement: .sidebar, prompt: "Search lessons, practice, code…")
                .searchScopes($searchScope) {
                    ForEach(SearchScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
        } detail: {
            ZStack {
                if isSearching {
                    SearchResultsView(query: searchText, scope: searchScope, onOpen: open)
                        .transition(.opacity)
                } else if let lesson = Curriculum.lesson(id: selection) {
                    LessonView(lesson: lesson, jump: jump?.lessonID == lesson.id ? jump : nil) { selection = $0.id }
                        .id(lesson.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 16)),
                            removal: .opacity
                        ))
                } else if selection == GlossaryView.tag {
                    GlossaryView { selection = $0.id }
                        .transition(.opacity)
                } else if selection == ReferencesView.tag {
                    ReferencesView(initialQuery: referenceQuery)
                        .id(referenceQuery)
                        .transition(.opacity)
                } else if selection == PracticeDataView.tag {
                    PracticeDataView(openRequest: $datasetRequest)
                        .transition(.opacity)
                } else {
                    HomeView { selection = $0.id }
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .animation(.smooth(duration: 0.4), value: selection)
            .animation(Theme.animation, value: isSearching)
            .onChange(of: selection) {
                // Arriving any other way than from search: forget the search's jump and filter.
                if openedFromSearch {
                    openedFromSearch = false
                } else {
                    jump = nil
                    referenceQuery = ""
                }
            }
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

    /// Opens a search result and ends the search.
    private func open(_ destination: SearchDestination) {
        let target: String
        switch destination {
        case .lesson(let id, let section):
            jump = section.map { JumpRequest(lessonID: id, section: $0) }
            target = id
        case .dataset(let name):
            datasetRequest = name
            target = PracticeDataView.tag
        case .references(let id):
            referenceQuery = id
            target = ReferencesView.tag
        }
        openedFromSearch = selection != target      // onChange(of: selection) only fires on a change
        selection = target
        searchText = ""
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
                Label { Text("References") } icon: { Image(systemName: "books.vertical").foregroundStyle(Theme.accent) }
                    .tag(ReferencesView.tag)
                Label { Text("Practice data") } icon: { Image(systemName: "tablecells").foregroundStyle(Theme.accent) }
                    .tag(PracticeDataView.tag)
            }

            ForEach(Curriculum.units) { unit in
                Section {
                    ForEach(unit.lessons) { lesson in
                        let isBookmarked = progress.bookmark(for: lesson) != nil
                        SidebarRow(lesson: lesson, isComplete: progress.isComplete(lesson),
                                   isBookmarked: isBookmarked, simulationCount: lesson.practiceSimulationCount)
                            .tag(lesson.id)
                            .contextMenu {
                                if isBookmarked {
                                    removeBookmarkButton(for: lesson)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if isBookmarked {
                                    removeBookmarkButton(for: lesson)
                                }
                            }
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

    private func removeBookmarkButton(for lesson: Lesson) -> some View {
        Button("Remove Bookmark", systemImage: "bookmark.slash") {
            withAnimation(Theme.animation) { progress.removeBookmark(for: lesson) }
        }
    }
}

private struct SidebarRow: View {
    let lesson: Lesson
    let isComplete: Bool
    /// The learner bookmarked a spot in this lesson.
    let isBookmarked: Bool
    /// How many practice-simulation exercises the lesson has.
    var simulationCount = 0

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
            if simulationCount > 0 || isBookmarked {
                Spacer(minLength: 4)
            }
            if simulationCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flask")
                    Text("\(simulationCount)")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.simulation)
                .help("\(simulationCount) practice-simulation exercise\(simulationCount == 1 ? "" : "s")")
                .accessibilityHidden(true)
            }
            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue([isComplete ? "Completed" : "Not completed", isBookmarked ? "Bookmarked" : nil,
                             simulationCount > 0 ? "\(simulationCount) practice simulation exercises" : nil]
            .compactMap { $0 }.joined(separator: ", "))
    }
}

// MARK: - Home

struct HomeView: View {
    static let tag = "home"

    var onSelect: (Lesson) -> Void

    @Environment(ProgressStore.self) private var progress
    @State private var isConfirmingClear = false

    private var overall: Double { progress.fraction(of: Curriculum.allLessons) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                hero
                continueCard
                preferences
                if !progress.bookmarks.isEmpty {
                    bookmarksRow
                        .transition(.opacity)
                }
                simulationsCard

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

    /// Where the practice-simulation exercises are, lesson by lesson.
    private var simulationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Practice simulations", systemImage: "flask")
                    .font(.headline)
                    .foregroundStyle(Theme.simulation)
                Spacer()
                Text("\(Curriculum.lessonsWithSimulations.map(\.practiceSimulationCount).reduce(0, +)) exercises in \(Curriculum.lessonsWithSimulations.count) lessons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Two simulated studies — political parasocial attachment, and how people ask chatbots about court cases — whose data recur in exercises across the course. Get the data from *Practice data*, then try the exercises in any order.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(Curriculum.lessonsWithSimulations) { lesson in
                    Button { onSelect(lesson) } label: {
                        HStack(spacing: 8) {
                            Text(lesson.title)
                                .font(.callout)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(lesson.practiceSimulationCount)")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Theme.simulation)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Theme.simulation.opacity(0.08), in: .rect(cornerRadius: 8, style: .continuous))
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .hoverHighlight(tint: Theme.simulation)
                    .accessibilityLabel("\(lesson.title), \(lesson.practiceSimulationCount) practice-simulation exercises")
                }
            }
        }
        .card(padding: 20)
    }

    private var bookmarksRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bookmarks")
                    .font(.headline)
                Text(progress.bookmarks.count == 1
                     ? "1 lesson is bookmarked."
                     : "\(progress.bookmarks.count) lessons are bookmarked.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Button("Clear All", systemImage: "bookmark.slash", role: .destructive) {
                isConfirmingClear = true
            }
            .confirmationDialog("Clear all bookmarks?", isPresented: $isConfirmingClear) {
                Button("Clear All Bookmarks", role: .destructive) {
                    withAnimation(Theme.animation) { progress.clearAllBookmarks() }
                }
            } message: {
                Text("Your completed lessons aren't affected.")
            }
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

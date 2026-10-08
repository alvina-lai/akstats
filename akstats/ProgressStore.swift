import Foundation
import Observation

/// Tracks which lessons the learner has completed, and the section they bookmarked in each one,
/// persisted in UserDefaults.
@Observable
final class ProgressStore {
    private(set) var completed: Set<String>
    /// The section the learner bookmarked in each lesson, keyed by lesson ID.
    private(set) var bookmarks: [String: String]

    private let defaults: UserDefaults
    private let key = "completedLessons"
    private let bookmarksKey = "lessonBookmarks"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = Set(defaults.stringArray(forKey: key) ?? [])
        bookmarks = defaults.dictionary(forKey: bookmarksKey) as? [String: String] ?? [:]
    }

    func bookmark(for lesson: Lesson) -> String? {
        bookmarks[lesson.id]
    }

    /// Bookmarks a section of the lesson; `nil` removes the bookmark.
    func setBookmark(_ section: String?, for lesson: Lesson) {
        guard bookmarks[lesson.id] != section else { return }
        bookmarks[lesson.id] = section
        defaults.set(bookmarks, forKey: bookmarksKey)
    }

    func removeBookmark(for lesson: Lesson) {
        setBookmark(nil, for: lesson)
    }

    func clearAllBookmarks() {
        bookmarks = [:]
        defaults.removeObject(forKey: bookmarksKey)
    }

    func isComplete(_ lesson: Lesson) -> Bool {
        completed.contains(lesson.id)
    }

    func setComplete(_ lesson: Lesson, _ isComplete: Bool) {
        if isComplete {
            completed.insert(lesson.id)
        } else {
            completed.remove(lesson.id)
        }
        defaults.set(Array(completed), forKey: key)
    }

    func fraction(of lessons: [Lesson]) -> Double {
        guard !lessons.isEmpty else { return 0 }
        let done = lessons.filter { completed.contains($0.id) }.count
        return Double(done) / Double(lessons.count)
    }

    /// The first lesson in course order that hasn't been completed yet.
    var nextLesson: Lesson? {
        Curriculum.allLessons.first { !completed.contains($0.id) }
    }
}

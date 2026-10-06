import Foundation
import Observation

/// Tracks which lessons the learner has completed, persisted in UserDefaults.
@Observable
final class ProgressStore {
    private(set) var completed: Set<String>

    private let defaults: UserDefaults
    private let key = "completedLessons"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = Set(defaults.stringArray(forKey: key) ?? [])
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

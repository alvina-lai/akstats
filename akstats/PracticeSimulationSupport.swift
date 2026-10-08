import Foundation

/// Helpers for finding and labelling the "Practice simulation" exercises spread across the course.
extension Exercise {
    static let simulationPrefix = "Practice simulation: "

    /// Exercises built on the two practice simulations are titled "Practice simulation: …".
    var isPracticeSimulation: Bool { title.hasPrefix(Self.simulationPrefix) }

    /// The title without the "Practice simulation:" prefix, for places that show a separate tag.
    var displayTitle: String {
        guard isPracticeSimulation else { return title }
        let rest = title.dropFirst(Self.simulationPrefix.count)
        return rest.prefix(1).uppercased() + rest.dropFirst()
    }
}

extension Lesson {
    /// Where a practice-simulation exercise sits in the lesson, as a scroll-target ID.
    struct SimulationLocation {
        let exercise: Exercise
        let sectionID: String
    }

    /// Every practice-simulation exercise in the lesson, in reading order.
    var practiceSimulations: [SimulationLocation] {
        let inBlocks = blocks.enumerated().compactMap { index, block -> SimulationLocation? in
            guard case .exercise(let exercise) = block, exercise.isPracticeSimulation else { return nil }
            return SimulationLocation(exercise: exercise, sectionID: "block-\(index)")
        }
        let inPractice = morePractice.enumerated().compactMap { index, exercise -> SimulationLocation? in
            exercise.isPracticeSimulation ? SimulationLocation(exercise: exercise, sectionID: "practice-\(index)") : nil
        }
        return inBlocks + inPractice
    }

    var practiceSimulationCount: Int { practiceSimulations.count }
}

extension Curriculum {
    /// Lessons that include practice-simulation exercises, in course order.
    static let lessonsWithSimulations: [Lesson] = allLessons.filter { $0.practiceSimulationCount > 0 }
}

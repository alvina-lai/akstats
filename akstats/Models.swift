import Foundation

/// Difficulty tier for a unit of lessons.
enum Level: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

/// The research field a worked example comes from.
enum Discipline: String {
    case psychology = "Psychology"
    case linguistics = "Linguistics"
    case sociology = "Sociology"
    case general = "Social science"

    var symbol: String {
        switch self {
        case .psychology: "brain.head.profile"
        case .linguistics: "text.bubble"
        case .sociology: "person.3"
        case .general: "globe"
        }
    }
}

/// A language a code sample can be shown in. Python and R are always available;
/// Mplus appears only on samples that include an Mplus input file.
enum CodeLanguage: String, CaseIterable, Identifiable {
    case python = "Python"
    case r = "R"
    case mplus = "Mplus"

    var id: String { rawValue }

    /// The comment marker used by the syntax highlighter.
    var commentMarker: Character {
        self == .mplus ? "!" : "#"
    }
}

/// A vocabulary entry shown in a glossary block.
struct Term {
    let name: String
    let definition: String

    init(_ name: String, _ definition: String) {
        self.name = name
        self.definition = definition
    }
}

/// The same analysis written in both Python and R.
struct CodeSample {
    let caption: String
    let python: String
    let r: String
    /// An optional Mplus input (.inp) for latent-variable models.
    var mplus: String? = nil

    var languages: [CodeLanguage] {
        mplus == nil ? [.python, .r] : [.python, .r, .mplus]
    }

    func source(for language: CodeLanguage) -> String {
        switch language {
        case .python: python
        case .r: r
        case .mplus: mplus ?? python
        }
    }
}

/// A hands-on practice task with an optional hint and a worked solution.
struct Exercise {
    let title: String
    let prompt: String
    var hint: String? = nil
    var solution: CodeSample? = nil
    /// What the learner should see or conclude once they've done it.
    let answer: String
}

/// A structured explanation of what a statistical model does and how it works.
struct ModelExplainer {
    let name: String
    /// One or two sentences: the question the model answers.
    let purpose: String
    /// The model written as an equation, if one helps.
    var equation: String? = nil
    /// How the model turns data into estimates, step by step.
    let steps: [String]
    /// Conditions to check before trusting the results.
    let conditions: [String]
    /// Where to read more, e.g. "OpenIntro Statistics (4th ed.), §7.5".
    let reading: String
}

/// Which built-in example chart to draw. Each one is rendered from simulated data
/// (with a fixed seed) by `ChartExampleView`.
enum ChartKind {
    case skewedDistribution, boxplotComparison, normalCurve, qqPlot
    case confidenceIntervals, nullDistribution, bootstrapDistribution, powerCurves
    case pairedLines, groupMeans, interactionMeans, ancovaLines, contingencyBars
    case correlationGallery, betweenWithin, regressionResiduals, residualPlots, coefficientPlot, logisticCurve
    case randomEffects, agreementTable, simpleSlopes
    case ordinalShares, transitionHeatmap, classProfiles, profileMeans
}

/// An annotated example chart: what it shows and how to read it.
struct ChartExample {
    let title: String
    let kind: ChartKind
    /// Step-by-step guidance for reading the chart.
    let reading: [String]
}

/// One section of a lesson's beginner-level “Start here” explanation.
struct ExplanationSection {
    enum Style {
        /// The core idea in plain language.
        case idea
        /// An everyday comparison that builds intuition.
        case analogy
        /// Small numbers you can follow by hand.
        case example
        /// How to say the result in words.
        case inWords
    }

    let style: Style
    let heading: String
    /// Paragraphs of inline Markdown.
    let paragraphs: [String]
}

/// One piece of lesson content. Text supports inline Markdown (**bold**, *italic*, `code`).
enum Block {
    case text(String)
    case keyPoint(String, String)
    case caution(String, String)
    case code(CodeSample)
    case field(Discipline, String)
    case terms([Term])
    case steps(String, [String])
    case exercise(Exercise)
    case model(ModelExplainer)
    case chart(ChartExample)
}

/// A multiple-choice check-for-understanding question.
struct Question {
    let prompt: String
    let options: [String]
    let answer: Int
    let explanation: String
}

struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let minutes: Int
    let blocks: [Block]
    let quiz: [Question]
    /// True for the end-of-unit review that tests the whole unit.
    var isReview: Bool = false

    static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Unit: Identifiable {
    let id: String
    let number: Int
    let title: String
    let level: Level
    let summary: String
    let symbol: String
    let lessons: [Lesson]
}

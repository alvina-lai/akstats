import Foundation

/// The full course, ordered from beginner to advanced.
enum Curriculum {
    /// Every unit with its end-of-unit review (if it has one) appended as the final lesson.
    static let units: [Unit] = baseUnits.map { unit in
        guard let review = review(for: unit) else { return unit }
        return Unit(id: unit.id, number: unit.number, title: unit.title, level: unit.level,
                    summary: unit.summary, symbol: unit.symbol, lessons: unit.lessons + [review])
    }

    /// Ordered by level: every beginner unit, then intermediate, then advanced.
    private static let baseUnits: [Unit] = [
        // Beginner
        gettingStarted, foundations, describing,
        // Intermediate
        inference, comparing, relationships, visualizingStats,
        // Advanced
        advanced, moderationMediation, categoricalOutcomes, latentModels, textAsData,
        capstoneReview,
    ]

    /// Every glossary term in the course, alphabetized, with the lesson that introduces it.
    static let glossary: [(term: Term, lesson: Lesson)] = {
        var seen = Set<String>()
        var entries: [(term: Term, lesson: Lesson)] = []
        for lesson in allLessons where lesson.id != "which-test" {
            for case .terms(let terms) in lesson.blocks {
                // Skip "A → B" mapping rows, which aren't definitions.
                for term in terms where !term.name.contains("→") && seen.insert(term.name.lowercased()).inserted {
                    entries.append((term, lesson))
                }
            }
        }
        return entries.sorted { $0.term.name.localizedCaseInsensitiveCompare($1.term.name) == .orderedAscending }
    }()

    static let allLessons: [Lesson] = units.flatMap(\.lessons)

    static func lesson(id: String?) -> Lesson? {
        guard let id else { return nil }
        return allLessons.first { $0.id == id }
    }

    static func unit(containing lesson: Lesson) -> Unit? {
        units.first { $0.lessons.contains(lesson) }
    }

    static func neighbor(of lesson: Lesson, offset: Int) -> Lesson? {
        guard let index = allLessons.firstIndex(of: lesson) else { return nil }
        let target = index + offset
        return allLessons.indices.contains(target) ? allLessons[target] : nil
    }
}

// MARK: - Unit 1 · Foundations

extension Curriculum {
    static let foundations = Unit(
        id: "foundations", number: 1, title: "Foundations", level: .beginner,
        summary: "Variables, measurement, and setting up Python & R.",
        symbol: "square.stack.3d.up",
        lessons: [whyStatistics, measurement, toolkit, tidyData]
    )

    static let whyStatistics = Lesson(
        id: "why-statistics",
        title: "Why statistics?",
        summary: "How social scientists turn noisy human behavior into evidence.",
        minutes: 6,
        blocks: [
            .text("Social scientists study people — their attitudes, behavior, language, and institutions. People vary enormously, so any single observation is noisy. **Statistics is the toolkit for separating signal from noise** and for being honest about how uncertain our conclusions are."),
            .keyPoint("The research loop", "Question → hypothesis → design → data collection → analysis → interpretation → reporting. Statistics shapes *every* step, not just the analysis. A badly designed study can't be rescued by clever statistics."),
            .terms([
                Term("Variable", "Anything that can take different values across people or observations — age, reaction time, native language."),
                Term("Independent variable (IV)", "The variable you manipulate or use to explain differences — e.g. experimental condition."),
                Term("Dependent variable (DV)", "The outcome you measure — e.g. accuracy, wellbeing score."),
                Term("Population", "The full group you want to draw conclusions about."),
                Term("Sample", "The subset of the population you actually observe."),
                Term("Operationalization", "Turning an abstract construct (“anxiety”) into something measurable (a 10-item questionnaire score)."),
            ]),
            .field(.psychology, "Does sleep deprivation reduce working memory? **IV:** sleep condition (rested vs. deprived). **DV:** digit-span score."),
            .field(.linguistics, "Do bilinguals name pictures more slowly than monolinguals? **IV:** language background. **DV:** naming latency in milliseconds."),
            .field(.sociology, "Is parental education associated with university attendance? Data come from a national survey panel — no manipulation is possible."),
            .caution("Correlation is not causation", "Only **randomized experiments** license causal claims directly. Observational data (most of sociology, corpus linguistics) can show association; causal claims need strong design and careful argument."),
        ],
        quiz: [
            Question(
                prompt: "Participants are randomly assigned to read a positive or negative news story, then rate their mood. What is the dependent variable?",
                options: ["The story's valence", "Mood rating", "The participants", "Random assignment"],
                answer: 1,
                explanation: "Mood is what's measured as the outcome. Story valence is the manipulated independent variable."
            ),
            Question(
                prompt: "Which design best supports a causal claim?",
                options: ["A large national survey", "A randomized experiment", "A single case study", "An archival analysis of newspapers"],
                answer: 1,
                explanation: "Random assignment balances confounds across groups on average, so differences in the outcome can be attributed to the manipulation."
            ),
        ]
    )

    static let measurement = Lesson(
        id: "measurement",
        title: "Levels of measurement",
        summary: "Nominal, ordinal, interval, ratio — and why the Likert debate matters.",
        minutes: 7,
        blocks: [
            .text("The *type* of variable decides which statistics make sense. You can average reaction times, but you can't average native languages."),
            .terms([
                Term("Nominal", "Unordered categories: native language, religion, experimental condition."),
                Term("Ordinal", "Ordered categories with uneven gaps: education level, a single 1–5 agreement item."),
                Term("Interval", "Equal gaps, no true zero: temperature in °C, many standardized test scores."),
                Term("Ratio", "Equal gaps and a true zero: reaction time, income, number of words produced."),
            ]),
            .caution("The Likert debate", "A **single** 1–5 agreement item is ordinal — the gap between “agree” and “strongly agree” isn't guaranteed to equal the gap between “neutral” and “agree”. Averaging **many** items into a scale score is commonly treated as interval. State your choice explicitly, and consider ordinal models for single items."),
            .code(CodeSample(
                caption: "Tell your software what kind of variable each column is",
                python: #"""
                import pandas as pd

                df = pd.DataFrame({
                    "participant": ["p01", "p02", "p03", "p04"],
                    "native_lang": ["English", "Spanish", "English", "Mandarin"],
                    "education":   ["HS", "BA", "MA", "BA"],
                    "rt_ms":       [512.3, 634.1, 587.9, 701.2],
                })

                # Nominal → unordered category
                df["native_lang"] = df["native_lang"].astype("category")

                # Ordinal → ordered category
                df["education"] = pd.Categorical(
                    df["education"],
                    categories=["HS", "BA", "MA", "PhD"],
                    ordered=True,
                )
                print(df.dtypes)
                """#,
                r: #"""
                library(tibble)

                df <- tibble(
                  participant = c("p01", "p02", "p03", "p04"),
                  # Nominal → factor
                  native_lang = factor(c("English", "Spanish", "English", "Mandarin")),
                  # Ordinal → ordered factor
                  education   = factor(c("HS", "BA", "MA", "BA"),
                                       levels = c("HS", "BA", "MA", "PhD"),
                                       ordered = TRUE),
                  rt_ms       = c(512.3, 634.1, 587.9, 701.2)
                )
                str(df)
                """#
            )),
            .keyPoint("Categories must be declared", "If groups are coded 1, 2, 3 and stored as numbers, models will treat them as a continuous quantity. Converting to a category/factor is one of the most common fixes in real analyses."),
        ],
        quiz: [
            Question(
                prompt: "Reaction time in milliseconds is measured on which scale?",
                options: ["Nominal", "Ordinal", "Interval", "Ratio"],
                answer: 3,
                explanation: "RT has equal intervals and a meaningful zero — 600 ms really is twice as long as 300 ms."
            ),
            Question(
                prompt: "A survey records political party affiliation. Which level of measurement is this?",
                options: ["Nominal", "Ordinal", "Interval", "Ratio"],
                answer: 0,
                explanation: "Parties are categories with no inherent order."
            ),
        ]
    )

    static let toolkit = Lesson(
        id: "toolkit",
        title: "Your toolkit: Python & R",
        summary: "Installing the packages researchers actually use.",
        minutes: 6,
        blocks: [
            .text("Both languages are free and widely used. **R** dominates in psychology and linguistics thanks to packages like `lme4`, `psych`, and the `tidyverse`. **Python** is strong in computational social science and text analysis. The statistical concepts are identical — only the syntax changes."),
            .terms([
                Term("pandas · tidyverse", "Loading, cleaning, and reshaping data."),
                Term("scipy.stats · base R stats", "Classic tests: t-tests, chi-square, correlations."),
                Term("statsmodels · lm / glm", "Regression models with formula syntax."),
                Term("pingouin · effectsize", "Research-friendly output with effect sizes built in."),
                Term("seaborn · ggplot2", "Publication-quality plots."),
            ]),
            .code(CodeSample(
                caption: "Install once, then load at the top of every script",
                python: #"""
                # In a terminal:
                #   pip install pandas numpy scipy statsmodels pingouin seaborn

                import numpy as np
                import pandas as pd
                from scipy import stats
                import statsmodels.formula.api as smf
                import pingouin as pg
                import seaborn as sns
                """#,
                r: #"""
                # Run once:
                install.packages(c("tidyverse", "lme4", "lmerTest", "afex",
                                   "emmeans", "psych", "effectsize", "pwr", "car"))

                library(tidyverse)
                library(lme4)
                library(psych)
                """#
            )),
            .keyPoint("One formula language", "Both ecosystems share the same model formula syntax: `outcome ~ predictor1 + predictor2`. Learn it once and it works for t-tests, regressions, and mixed models alike."),
            .code(CodeSample(
                caption: "The same regression, written both ways",
                python: #"""
                model = smf.ols("wellbeing ~ income + age", data=df).fit()
                print(model.summary())
                """#,
                r: #"""
                model <- lm(wellbeing ~ income + age, data = df)
                summary(model)
                """#
            )),
            .field(.linguistics, "Corpus linguists often process text in Python (spaCy, NLTK) to count features, then move the resulting table into R for modeling."),
            .caution("Scripts, not clicks", "Write every step — from loading to the final model — in a script. Set a random seed and record package versions (`sessionInfo()` in R, `pip freeze` in Python). Reproducibility is now expected by journals."),
        ],
        quiz: [
            Question(
                prompt: "In the formula `rt ~ condition + age`, which variable is the outcome?",
                options: ["condition", "age", "rt", "All three"],
                answer: 2,
                explanation: "The outcome always goes on the left of the tilde (~); predictors go on the right."
            ),
        ]
    )

    static let tidyData = Lesson(
        id: "tidy-data",
        title: "Loading & tidying data",
        summary: "Exclusions, and reshaping between wide and long formats.",
        minutes: 8,
        blocks: [
            .text("Real data arrive messy: survey-platform exports, experiment logs, panel waves. **Tidy data** follows one rule: *one row per observation, one column per variable.*"),
            .keyPoint("Wide vs. long", "Repeated-measures data are often exported **wide** — one row per participant with columns like `rt_congruent` and `rt_incongruent`. Most models, and all mixed-effects models, need **long** format: one row per participant × condition (or per trial)."),
            .code(CodeSample(
                caption: "Read, apply exclusions, and reshape Stroop data from wide to long",
                python: #"""
                df = pd.read_csv("stroop.csv")

                # Keep adults who passed the attention check
                df = df[(df["age"] >= 18) & (df["attention_check"] == "pass")]

                # Wide → long: one row per participant × condition
                long = df.melt(
                    id_vars=["participant"],
                    value_vars=["rt_congruent", "rt_incongruent"],
                    var_name="condition",
                    value_name="rt",
                )
                long["condition"] = long["condition"].str.replace("rt_", "")
                """#,
                r: #"""
                df <- read_csv("stroop.csv") |>
                  filter(age >= 18, attention_check == "pass")

                # Wide → long: one row per participant × condition
                long <- df |>
                  pivot_longer(
                    cols = c(rt_congruent, rt_incongruent),
                    names_to = "condition",
                    names_prefix = "rt_",
                    values_to = "rt"
                  )
                """#
            )),
            .caution("Decide exclusions before you look", "Rules like “drop RTs under 200 ms” or “exclude failed attention checks” should be fixed **before** seeing results — ideally preregistered. Choosing them afterwards is a classic *researcher degree of freedom* that inflates false positives."),
            .field(.psychology, "In the Stroop task, people name the ink color of color words. “RED” printed in blue (incongruent) is slower than “RED” in red (congruent). Every participant does both conditions — a within-subjects design."),
        ],
        quiz: [
            Question(
                prompt: "You want to model trial-level reaction times with a mixed-effects model. Which format do you need?",
                options: ["Wide: one row per participant", "Long: one row per trial", "Either works", "A summary table of means"],
                answer: 1,
                explanation: "Mixed models need each observation as its own row so they can model variation across participants and items."
            ),
            Question(
                prompt: "When should RT outlier cutoffs ideally be chosen?",
                options: ["After seeing which cutoff gives p < .05", "Before data collection, ideally preregistered", "Only if reviewers ask", "Never — outliers must always stay"],
                answer: 1,
                explanation: "Fixing rules in advance prevents choices from being (consciously or not) steered by the results."
            ),
        ]
    )
}

// MARK: - Unit 2 · Describing data

extension Curriculum {
    static let describing = Unit(
        id: "describing", number: 2, title: "Describing data", level: .beginner,
        summary: "Summaries, plots, and the normal distribution.",
        symbol: "chart.bar",
        lessons: [centralTendency, visualizing, normalDistribution]
    )

    static let centralTendency = Lesson(
        id: "central-tendency",
        title: "Center & spread",
        summary: "Means, medians, standard deviations — and when each misleads.",
        minutes: 7,
        blocks: [
            .chart(ChartExample(
                title: "Where the mean and median land in skewed data",
                kind: .skewedDistribution,
                reading: [
                    "Each bar counts how many reaction times fall in a 50-ms bin; taller bars = more common values.",
                    "Most responses cluster around 400–550 ms, but a **long tail stretches to the right** — that's right skew.",
                    "The **median** (solid line) sits in the middle of the pile: half the responses are faster, half slower.",
                    "The **mean** (dashed line) is pulled toward the tail by the few very slow responses, so it's larger than the median.",
                    "When mean and median disagree like this, report the median (and IQR), or analyze log-transformed values.",
                ]
            )),
            .terms([
                Term("Mean (M)", "The arithmetic average. Sensitive to extreme values."),
                Term("Median (Mdn)", "The middle value. Robust to outliers and skew."),
                Term("Standard deviation (SD)", "Typical distance of observations from the mean."),
                Term("Interquartile range (IQR)", "Spread of the middle 50% — the 75th minus the 25th percentile."),
            ]),
            .text("Reaction times and incomes are **right-skewed**: most values cluster low, with a long tail of large values. For skewed variables, the mean gets pulled toward the tail, so report the median as well."),
            .code(CodeSample(
                caption: "Descriptive statistics, overall and by condition",
                python: #"""
                rt = long["rt"]
                print(rt.mean(), rt.median(), rt.std())   # pandas .std() uses n − 1
                print(rt.quantile([0.25, 0.75]))

                long.groupby("condition")["rt"].agg(["count", "mean", "median", "std"])
                """#,
                r: #"""
                long |>
                  group_by(condition) |>
                  summarise(
                    n      = n(),
                    mean   = mean(rt, na.rm = TRUE),
                    median = median(rt, na.rm = TRUE),
                    sd     = sd(rt, na.rm = TRUE)
                  )
                """#
            )),
            .caution("Two different SDs", "`np.std()` divides by *n* (population SD) by default. pandas `.std()` and R's `sd()` divide by *n − 1* (sample SD). Research reports use the sample SD — use `np.std(x, ddof=1)` if you're working in NumPy."),
            .field(.sociology, "Household income is reported as a **median** in census reports: a handful of extremely high earners would drag the mean far above what a typical household earns."),
            .keyPoint("Always report", "Sample size, mean, and SD for every group, e.g. *M* = 534 ms, *SD* = 87, *n* = 42. These are what future meta-analyses need."),
        ],
        quiz: [
            Question(
                prompt: "Income in your sample is strongly right-skewed. Which statistic best describes a typical participant?",
                options: ["Mean", "Median", "Standard deviation", "Range"],
                answer: 1,
                explanation: "The median isn't pulled by the long tail of very high incomes."
            ),
            Question(
                prompt: "By default, `np.std(x)` divides the sum of squares by…",
                options: ["n", "n − 1", "n + 1", "√n"],
                answer: 0,
                explanation: "NumPy defaults to ddof=0, the population formula. Pass ddof=1 for the sample SD."
            ),
        ]
    )

    static let visualizing = Lesson(
        id: "visualizing",
        title: "Visualizing distributions",
        summary: "Plot before you test. Always.",
        minutes: 6,
        blocks: [
            .text("A test statistic compresses your data into one number. A plot shows you what that number hides: skew, outliers, ceiling effects, clusters, data-entry errors."),
            .chart(ChartExample(
                title: "Boxplots with the raw data on top",
                kind: .boxplotComparison,
                reading: [
                    "The thick line inside each box is the **median**; the box spans the middle 50% of scores (the **IQR**, 25th to 75th percentile).",
                    "The thin vertical lines (whiskers) reach the most extreme points within 1.5 × IQR of the box; points beyond them are potential outliers.",
                    "The dots are the individual students — they show sample size and clusters that a box alone hides.",
                    "Compare medians across groups, but also compare **spread** and **shape**: the flipped group's long upper tail means a few students scored much higher than the rest.",
                ]
            )),
            .code(CodeSample(
                caption: "Histograms and boxplots with raw data points",
                python: #"""
                import seaborn as sns
                import matplotlib.pyplot as plt

                sns.histplot(data=long, x="rt", hue="condition", kde=True)
                plt.show()

                sns.boxplot(data=long, x="condition", y="rt", showfliers=False)
                sns.stripplot(data=long, x="condition", y="rt",
                              color="black", alpha=0.3)
                plt.show()
                """#,
                r: #"""
                ggplot(long, aes(x = rt, fill = condition)) +
                  geom_histogram(alpha = 0.6, position = "identity", bins = 30)

                ggplot(long, aes(x = condition, y = rt)) +
                  geom_boxplot(outlier.shape = NA) +
                  geom_jitter(width = 0.1, alpha = 0.3)
                """#
            )),
            .keyPoint("Show the data", "Bar charts of means hide the distribution. Many journals now encourage plots that show individual data points, like boxplots or violin plots with jittered points."),
            .caution("Anscombe's quartet", "Four datasets can share the same means, SDs, and correlation yet look completely different when plotted — one linear, one curved, one driven by a single outlier. Summary statistics alone can be deeply misleading."),
            .field(.psychology, "Questionnaire scores often bunch at the top of the scale (a ceiling effect). A histogram reveals this instantly. It also matters later, because ceiling effects can hide real group differences."),
        ],
        quiz: [
            Question(
                prompt: "Why overlay raw data points on a boxplot?",
                options: ["It makes p-values smaller", "It reveals sample size, clusters, and outliers", "Journals require exactly that", "It removes skew"],
                answer: 1,
                explanation: "Raw points show how many observations there are and how they're spread — information a summary hides."
            ),
        ]
    )

    static let normalDistribution = Lesson(
        id: "normal-distribution",
        title: "The normal distribution & z-scores",
        summary: "Standardizing, checking normality, and transforming skewed data.",
        minutes: 8,
        blocks: [
            .text("Many classic tests assume (approximately) normal errors. In a normal distribution, about **68%** of values fall within ±1 SD of the mean, **95%** within ±1.96 SD, and **99.7%** within ±3 SD."),
            .model(ModelExplainer(
                name: "The normal model",
                purpose: "Describes a symmetric, bell-shaped distribution completely with two numbers — its mean µ and standard deviation σ — so that the probability of any range of values can be computed.",
                equation: "X ~ N(µ, σ)        z = (x − µ) / σ",
                steps: [
                    "Standardize a value by subtracting the mean and dividing by the SD; the result, z, is in SD units.",
                    "Every normal distribution becomes the same **standard normal** N(0, 1) after standardizing, so one table (or `pnorm()` / `stats.norm.cdf()`) gives probabilities for all of them.",
                    "The 68–95–99.7 rule summarizes the shape: about 68% of values lie within 1 SD of the mean, 95% within 2 (precisely 1.96), and 99.7% within 3.",
                    "Many sample statistics — especially means — are approximately normal even when the raw data aren't (the Central Limit Theorem), which is why the normal model underpins so much inference.",
                ],
                conditions: [
                    "**Roughly symmetric, unimodal data** if you're modeling the raw values themselves; check a histogram and a Q–Q plot.",
                    "**No hard boundaries close to the bulk of the data** (e.g. reaction times near 0, ratings piled at a scale end).",
                    "Skewed variables can often be made closer to normal with a log or square-root transformation.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §4.1 (the normal distribution) and §2.1.5 (transforming data)."
            )),
            .chart(ChartExample(
                title: "The 68–95–99.7 rule",
                kind: .normalCurve,
                reading: [
                    "The x-axis is in **standard deviations from the mean** (z-scores); the peak is at the mean, z = 0.",
                    "The darkest band (−1 to +1 SD) holds about **68%** of values; adding the next bands on each side brings it to about **95%** (±2 SD) and **99.7%** (±3 SD).",
                    "Hover anywhere to see what percentage of a normal distribution falls below that z — that's the value's **percentile**.",
                    "A z of +2 is unusual (about the 98th percentile); a z of +3 is very rare.",
                ]
            )),
            .chart(ChartExample(
                title: "Q–Q plots: normal vs. skewed data",
                kind: .qqPlot,
                reading: [
                    "Each point pairs an observed value (y) with the value you'd **expect** at that rank if the data were normal (x).",
                    "Normal data fall close to the dashed diagonal line.",
                    "Right-skewed data bend **above the line at the right end** (the largest values are larger than a normal distribution predicts) and sit above it at the left end too, because the smallest values are bunched up.",
                    "Small wiggles at the extremes are normal; systematic curves are what matter.",
                ]
            )),
            .text("A **z-score** expresses a value in SD units: *z* = (*x* − *M*) / *SD*. A z of +2 means two standard deviations above the mean, whatever the original scale."),
            .code(CodeSample(
                caption: "Standardize, check normality visually, and log-transform",
                python: #"""
                from scipy import stats
                import matplotlib.pyplot as plt

                long["rt_z"] = (long["rt"] - long["rt"].mean()) / long["rt"].std()

                # Q–Q plot: points on the line ≈ normal
                stats.probplot(long["rt"], dist="norm", plot=plt)
                plt.show()

                # Log-transform right-skewed reaction times
                long["log_rt"] = np.log(long["rt"])
                """#,
                r: #"""
                long <- long |>
                  mutate(rt_z   = as.numeric(scale(rt)),
                         log_rt = log(rt))

                # Q–Q plot: points on the line ≈ normal
                qqnorm(long$rt)
                qqline(long$rt)
                """#
            )),
            .caution("Don't over-trust normality tests", "With large samples, Shapiro–Wilk flags trivial deviations; with small samples it misses big ones. Prefer Q–Q plots. Remember that the assumption concerns the model's **residuals**, not the raw outcome."),
            .field(.linguistics, "Psycholinguists routinely log-transform reaction times (or use inverse RTs) before modeling, because raw RTs are bounded at zero and strongly right-skewed."),
            .keyPoint("z-scores compare across scales", "Standardizing lets you combine or compare measures on different scales — for example, test scores from two countries with different grading systems."),
        ],
        quiz: [
            Question(
                prompt: "A participant has z = +2 on an anxiety scale. This means…",
                options: ["They scored 2 points above average", "They're 2 SDs above the mean", "They're in the top 2%", "Their score is twice the mean"],
                answer: 1,
                explanation: "z-scores are in standard-deviation units. (+2 SD is roughly the top 2.3%, not exactly 2%.)"
            ),
            Question(
                prompt: "Roughly what share of a normal distribution lies within ±1.96 SD of the mean?",
                options: ["68%", "90%", "95%", "99.7%"],
                answer: 2,
                explanation: "This is where the 1.96 in 95% confidence intervals comes from."
            ),
        ]
    )
}

// MARK: - Unit 3 · Inference

extension Curriculum {
    static let inference = Unit(
        id: "inference", number: 3, title: "From sample to population", level: .intermediate,
        summary: "Uncertainty, p-values, effect sizes, and power.",
        symbol: "scope",
        lessons: [standardError, hypothesisTesting, bootstrapLesson, effectSizes, samplePlanning]
    )

    static let standardError = Lesson(
        id: "standard-error",
        title: "Standard error & confidence intervals",
        summary: "How much would your result change with a different sample?",
        minutes: 8,
        blocks: [
            .text("If you ran the same study again with new participants, you'd get a slightly different mean. The **standard error** (SE) is the standard deviation of that hypothetical spread of sample means: *SE* = *SD* / √*n*."),
            .model(ModelExplainer(
                name: "Sampling distributions and confidence intervals",
                purpose: "Quantifies how much an estimate (a mean, a proportion) would vary from sample to sample, and turns that into an interval that captures the true value in 95% of repeated samples.",
                equation: "SE(mean) = s / √n        95% CI = estimate ± t* × SE   (t* ≈ 1.96 for large n)",
                steps: [
                    "Imagine drawing many samples of size n and computing the estimate each time; the distribution of those estimates is the **sampling distribution**.",
                    "By the **Central Limit Theorem**, the sampling distribution of a mean is approximately normal, centered on the true value, with SD = σ / √n — the **standard error**.",
                    "In practice σ is unknown, so the SE uses the sample SD, and the multiplier comes from the *t* distribution with n − 1 degrees of freedom.",
                    "The CI is the estimate ± (multiplier × SE). Wider intervals mean more uncertainty; quadrupling n halves the width.",
                ],
                conditions: [
                    "**Independence:** observations are independent — typically guaranteed by random sampling or random assignment.",
                    "**Normality / sample size:** with n < 30, the data should have no clear outliers; with n ≥ 30, the sampling distribution of the mean is approximately normal unless there are extreme outliers.",
                    "For a proportion, the **success–failure condition**: at least 10 expected successes and 10 failures (np ≥ 10 and n(1 − p) ≥ 10).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §5.1–5.2 (point estimates, sampling variability, confidence intervals) and §7.1 (the t-distribution)."
            )),
            .chart(ChartExample(
                title: "What “95% confidence” means: 25 repeated studies",
                kind: .confidenceIntervals,
                reading: [
                    "Each horizontal line is one study's 95% confidence interval (n = 30 from a population whose true mean is 100); the dot is that study's sample mean.",
                    "The dashed vertical line is the **true** mean — which in real research you never get to see.",
                    "Most intervals cross the true mean; occasionally one misses (orange). Over many studies, about 95% contain it.",
                    "Any single interval either contains the true value or doesn't — the 95% describes the **method**, not one interval.",
                    "Hover over a row to read that study's interval.",
                ]
            )),
            .code(CodeSample(
                caption: "Simulate the sampling distribution, then compute a 95% CI",
                python: #"""
                rng = np.random.default_rng(42)

                # 1,000 studies with n = 30 from a population with M = 100, SD = 15
                means = [rng.normal(100, 15, size=30).mean() for _ in range(1000)]
                print(np.std(means, ddof=1))   # ≈ 15 / √30 ≈ 2.74

                # 95% CI for an observed sample mean
                x = long["rt"]
                ci = stats.t.interval(0.95, df=len(x) - 1,
                                      loc=x.mean(), scale=stats.sem(x))
                """#,
                r: #"""
                set.seed(42)

                # 1,000 studies with n = 30 from a population with M = 100, SD = 15
                means <- replicate(1000, mean(rnorm(30, mean = 100, sd = 15)))
                sd(means)   # ≈ 15 / √30 ≈ 2.74

                # 95% CI for an observed sample mean
                t.test(long$rt)$conf.int
                """#
            )),
            .keyPoint("What a 95% CI actually means", "If you repeated the study many times, **95% of the intervals built this way would contain the true population value**. Any single interval either contains it or doesn't — it is *not* a 95% probability statement about that one interval."),
            .field(.sociology, "When a poll reports “52% ± 3 points”, that margin of error is the half-width of a 95% confidence interval."),
            .caution("Statistics can't fix a biased sample", "Most psychology samples are **WEIRD** — Western, Educated, Industrialized, Rich, Democratic — often undergraduates. A tiny SE from a convenience sample says nothing about generalizing to other populations."),
        ],
        quiz: [
            Question(
                prompt: "If you quadruple your sample size, the standard error…",
                options: ["Stays the same", "Halves", "Quarters", "Doubles"],
                answer: 1,
                explanation: "SE = SD / √n, and √4 = 2, so the SE is cut in half."
            ),
        ]
    )

    static let hypothesisTesting = Lesson(
        id: "hypothesis-testing",
        title: "Hypothesis tests & p-values",
        summary: "What a p-value is — and the many things it isn't.",
        minutes: 10,
        blocks: [
            .model(ModelExplainer(
                name: "The hypothesis-testing framework",
                purpose: "Weighs the data against a skeptical default claim (the null hypothesis) by asking how surprising the observed result would be if that claim were true.",
                equation: "test statistic = (estimate − null value) / SE        p-value = P(result this extreme | H₀)",
                steps: [
                    "State **H₀** (no effect, e.g. µ₁ − µ₂ = 0) and **Hₐ** (an effect exists; two-sided unless a direction was declared in advance).",
                    "Choose the significance level α (usually .05) **before** looking at the data.",
                    "Compute the test statistic: how many standard errors the estimate lies from the null value.",
                    "Find the p-value from the statistic's null distribution (normal, t, χ², F — or a permutation distribution).",
                    "If p < α, reject H₀; otherwise, you lack sufficient evidence against it. Report the effect size and CI either way.",
                ],
                conditions: [
                    "The **conditions of the underlying model** (independence, sample size, distribution shape) must hold for the null distribution to be accurate.",
                    "**One planned test** — or a correction when running many.",
                    "A **one-sided** alternative only when the direction was specified before seeing the data.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §5.3 (hypothesis testing) and §2.3 (randomization tests)."
            )),
            .chart(ChartExample(
                title: "Reading a p-value off a null distribution",
                kind: .nullDistribution,
                reading: [
                    "The bars show the differences you get from **5,000 random shuffles** of the group labels — what chance alone produces when there's no real effect.",
                    "The solid line is the difference actually observed; the dashed line is its mirror image on the other side.",
                    "The orange bars are shuffles at least as extreme as the observed difference (in either direction).",
                    "The **p-value** is the share of shuffles that are orange — here about 3%. Small p = the observed difference would be rare if there were no effect.",
                ]
            )),
            .terms([
                Term("Null hypothesis (H₀)", "The default claim of no effect or no difference."),
                Term("p-value", "The probability of data at least this extreme, *assuming H₀ is true*."),
                Term("Alpha (α)", "The false-positive rate you'll tolerate — conventionally .05."),
                Term("Type I error", "A false positive: rejecting a true H₀."),
                Term("Type II error", "A false negative: missing a real effect."),
            ]),
            .text("A **permutation test** makes the logic concrete. If group labels don't matter (H₀), shuffling them shouldn't change anything. So shuffle thousands of times and see how often chance alone produces a difference as big as yours."),
            .code(CodeSample(
                caption: "Build a p-value from scratch with a permutation test",
                python: #"""
                treat = df.loc[df["group"] == "treatment", "score"].to_numpy()
                ctrl  = df.loc[df["group"] == "control", "score"].to_numpy()
                observed = treat.mean() - ctrl.mean()

                pooled = np.concatenate([treat, ctrl])
                rng = np.random.default_rng(1)
                diffs = []
                for _ in range(10_000):
                    rng.shuffle(pooled)
                    diffs.append(pooled[:len(treat)].mean() - pooled[len(treat):].mean())

                p = np.mean(np.abs(diffs) >= abs(observed))
                print(f"difference = {observed:.2f}, p = {p:.4f}")
                """#,
                r: #"""
                set.seed(1)
                observed <- with(df, mean(score[group == "treatment"]) -
                                     mean(score[group == "control"]))

                diffs <- replicate(10000, {
                  shuffled <- sample(df$group)
                  mean(df$score[shuffled == "treatment"]) -
                    mean(df$score[shuffled == "control"])
                })

                p <- mean(abs(diffs) >= abs(observed))
                """#
            )),
            .caution("What p is NOT", "• Not the probability that H₀ is true.\n• Not the probability your result is “due to chance”.\n• *p* > .05 does **not** show there's no effect.\n• *p* says nothing about how large or important an effect is."),
            .keyPoint("p-hacking", "Trying many analyses — different outliers rules, covariates, subgroups — and reporting the one that “works” makes false positives very likely. With 20 independent tests of true nulls at α = .05, you'd expect about one “significant” result by chance."),
            .field(.psychology, "The Open Science Collaboration (2015) replicated 100 published psychology studies: **97%** of the originals were significant, but only **36%** of the replications — and effect sizes were roughly halved."),
        ],
        quiz: [
            Question(
                prompt: "A study reports p = .03. Which interpretation is correct?",
                options: [
                    "There's a 3% chance the null hypothesis is true",
                    "If H₀ were true, data this extreme would occur about 3% of the time",
                    "There's a 97% chance the effect is real",
                    "The effect is large",
                ],
                answer: 1,
                explanation: "A p-value is computed assuming the null is true. It's a statement about the data, not about the hypothesis."
            ),
            Question(
                prompt: "A Type I error is…",
                options: ["Missing a real effect", "A false positive", "A coding mistake", "Using the wrong test"],
                answer: 1,
                explanation: "Type I = rejecting a null hypothesis that is actually true."
            ),
        ]
    )

    static let effectSizes = Lesson(
        id: "effect-sizes",
        title: "Effect sizes & power",
        summary: "How big is the effect, and could your study have detected it?",
        minutes: 10,
        blocks: [
            .text("Significance tells you *whether* an effect is distinguishable from zero. **Effect size** tells you *how big* it is. APA style requires both."),
            .model(ModelExplainer(
                name: "Standardized effect sizes and power",
                purpose: "Expresses how big an effect is on a scale that doesn't depend on the units of measurement or the sample size, and links that size to the probability that a study will detect it.",
                equation: "d = (M₁ − M₂) / s_pooled        power = P(reject H₀ | true effect = d)",
                steps: [
                    "Divide the raw difference by a standard deviation to get **Cohen's d** — the difference in SD units.",
                    "For a planned study, the **sampling distribution under Hₐ** is centered on the true effect; power is the share of that distribution beyond the critical value.",
                    "Power rises with a larger true effect, a larger n, less noise, and a larger α.",
                    "Working backwards — fix the effect, α, and target power (e.g. .80) — gives the required sample size.",
                ],
                conditions: [
                    "A **plausible effect size**: the smallest effect that would matter, or a meta-analytic estimate rather than one (likely inflated) study.",
                    "The **same design and test** in the power analysis as in the planned analysis (paired vs. independent, covariates, clustering).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.4 (power calculations for a difference of means)."
            )),
            .chart(ChartExample(
                title: "How sample size and effect size drive power",
                kind: .powerCurves,
                reading: [
                    "Each line shows the probability of a significant result (power) for a two-group study as the number of participants per group grows.",
                    "Find where a line crosses the dashed **80% power** line to read off the required n per group.",
                    "Large effects (d = 0.8) reach 80% with about 26 per group; medium (d = 0.5) needs about 64; small (d = 0.2) needs about 394 — off most of this chart.",
                    "Hover to compare the three lines at any sample size.",
                ]
            )),
            .terms([
                Term("Cohen's d", "Mean difference in SD units. Rough benchmarks: 0.2 small, 0.5 medium, 0.8 large."),
                Term("r", "Correlation coefficient, also used as an effect size."),
                Term("η²ₚ (partial eta squared)", "Proportion of variance explained by a factor in ANOVA."),
                Term("Odds ratio (OR)", "Effect size for binary outcomes."),
                Term("Power", "Probability of detecting an effect if it truly exists. Aim for at least .80."),
            ]),
            .code(CodeSample(
                caption: "Compute Cohen's d and plan your sample size",
                python: #"""
                import pingouin as pg
                from statsmodels.stats.power import TTestIndPower

                d = pg.compute_effsize(treat, ctrl, eftype="cohen")

                # Participants per group to detect d = 0.4 with 80% power
                n = TTestIndPower().solve_power(effect_size=0.4, power=0.80, alpha=0.05)
                print(np.ceil(n))   # 100 per group
                """#,
                r: #"""
                library(effectsize)
                library(pwr)

                cohens_d(score ~ group, data = df)

                # Participants per group to detect d = 0.4 with 80% power
                pwr.t.test(d = 0.4, power = 0.80, sig.level = 0.05,
                           type = "two.sample")   # n ≈ 100 per group
                """#
            )),
            .caution("The winner's curse", "Small studies only reach significance when they happen to overestimate the effect. So published effects from underpowered studies are **inflated** — and replications powered on them end up underpowered too."),
            .keyPoint("Power for the effect you care about", "Base power analyses on the *smallest effect size of interest* or on meta-analytic estimates, not on a single published (likely inflated) study."),
            .field(.linguistics, "Brysbaert & Stevens (2018) recommend around **1,600 observations per condition** for reaction-time experiments — for example, 40 participants × 40 items."),
        ],
        quiz: [
            Question(
                prompt: "Cohen's d = 0.5 means the two group means differ by…",
                options: ["0.5 points on the scale", "Half a standard deviation", "50%", "p = .5"],
                answer: 1,
                explanation: "d is standardized: the difference divided by the pooled SD."
            ),
            Question(
                prompt: "Statistical power is the probability of…",
                options: ["Getting p < .05 when H₀ is true", "Detecting an effect that truly exists", "Replicating a study", "The null being false"],
                answer: 1,
                explanation: "Power = 1 − the Type II error rate."
            ),
        ]
    )
}

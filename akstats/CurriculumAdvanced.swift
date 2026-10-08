import Foundation

// MARK: - Unit 4 · Comparing groups

extension Curriculum {
    static let comparing = Unit(
        id: "comparing", number: 4, title: "Comparing groups", level: .intermediate,
        summary: "t-tests, ANOVA (including repeated measures), multiple comparisons, ANCOVA, chi-square, rank-based and equivalence tests, and a real-data lab.",
        symbol: "square.split.2x1",
        lessons: [tTests, anova, multipleComparisons, ancova, repeatedMeasures, chiSquare, nonParametric, equivalence, hsb2Lab]
    )

    static let tTests = Lesson(
        id: "t-tests",
        title: "t-tests",
        summary: "Comparing two means — independent or paired.",
        minutes: 9,
        blocks: [
            .model(ModelExplainer(
                name: "t-tests for one, paired, and two independent means",
                purpose: "Compare a mean with a fixed value, the same people at two times, or two separate groups, accounting for the extra uncertainty that comes from estimating the SD.",
                equation: "two groups: t = (x̄₁ − x̄₂) / √(s₁²/n₁ + s₂²/n₂)        paired: t = d̄ / (s_d / √n)",
                steps: [
                    "**One sample:** t = (x̄ − µ₀) / (s / √n), with df = n − 1.",
                    "**Paired data:** compute each person's difference, then run a one-sample t-test on the differences — pairing removes stable person-to-person variation.",
                    "**Two independent groups:** the SE combines both groups' variability. Welch's version keeps the variances separate and adjusts the df; the pooled version assumes equal variances.",
                    "Compare t with the t distribution to get a p-value, and report the mean difference with its CI.",
                ],
                conditions: [
                    "**Independence** within each group, and between groups for the independent-samples test (no pairing).",
                    "**Approximately normal data** or a large enough sample in each group (n ≥ 30 with no extreme outliers).",
                    "For the pooled version only, **equal variances**; Welch's test doesn't need this.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.1 (one-sample means), §7.2 (paired data), §7.3 (difference of two means)."
            )),
            .chart(ChartExample(
                title: "Paired data: one line per person",
                kind: .pairedLines,
                reading: [
                    "Each thin gray line connects one person's score before and after.",
                    "Most lines slope upward, so most people improved — that consistency is what a **paired** t-test detects.",
                    "The thick green line connects the two means; its rise is the mean change.",
                    "People differ a lot in their overall level (lines start at different heights), but the paired test only looks at each person's *change*, so those differences don't add noise.",
                ]
            )),
            .terms([
                Term("One-sample", "Is a mean different from a fixed value (e.g. chance = 50%)?"),
                Term("Independent samples", "Two separate groups of people."),
                Term("Paired samples", "The same people measured twice, or matched pairs."),
            ]),
            .keyPoint("Default to Welch's t-test", "Welch's version doesn't assume equal variances in the two groups and loses almost nothing when they *are* equal (Delacre, Lakens & Leys, 2017). It's R's default; in SciPy you must ask for it with `equal_var=False`."),
            .code(CodeSample(
                caption: "Independent and paired t-tests",
                python: #"""
                import pandas as pd
                import pingouin as pg
                from scipy import stats

                # Independent groups: post-test scores, active learning vs. lecture (Welch)
                classroom = pd.read_csv("classroom.csv")
                treat = classroom.loc[classroom["method"] == "active", "posttest"]
                ctrl = classroom.loc[classroom["method"] == "lecture", "posttest"]
                print(stats.ttest_ind(treat, ctrl, equal_var=False))

                # Paired: the same participants in both Stroop conditions
                stroop = pd.read_csv("stroop.csv")
                print(stats.ttest_rel(stroop["rt_incongruent"], stroop["rt_congruent"]))

                # pingouin: t, df, p, 95% CI, Cohen's d, and power in one table
                print(pg.ttest(treat, ctrl, correction=True))
                """#,
                r: #"""
                library(tidyverse)

                # Independent groups: post-test scores, active learning vs. lecture (Welch is the default)
                classroom <- read_csv("classroom.csv")
                t.test(posttest ~ method, data = filter(classroom, method %in% c("active", "lecture")))

                # Paired: the same participants in both Stroop conditions
                stroop <- read_csv("stroop.csv")
                t.test(stroop$rt_incongruent, stroop$rt_congruent, paired = TRUE)
                """#
            )),
            .caution("Match the test to the design", "Running an independent-samples t-test on repeated-measures data ignores that each person's two scores are correlated, which gives the wrong standard error. Paired designs are usually far more powerful."),
            .field(.psychology, "The Stroop effect is tested with a paired t-test: each participant's incongruent RT is compared with their own congruent RT."),
            .keyPoint("Reporting", "*t*(48.3) = 2.41, *p* = .020, *d* = 0.68, 95% CI [0.52, 6.10]. Welch's df is often non-integer — that's expected."),
        ],
        quiz: [
            Question(
                prompt: "The same participants rate both happy and sad faces. Which test compares their ratings?",
                options: ["Independent-samples t-test", "Paired-samples t-test", "Chi-square test", "One-sample t-test"],
                answer: 1,
                explanation: "Each person contributes to both conditions, so the observations are paired."
            ),
        ]
    )

    static let anova = Lesson(
        id: "anova",
        title: "ANOVA",
        summary: "Three or more groups, factorial designs, and interactions.",
        minutes: 11,
        blocks: [
            .text("ANOVA has long been one of the most common analyses in experimental psychology, and **mixed factorial designs** — some factors within-subjects, some between — are especially common. The *F* ratio compares variance *between* groups to variance *within* groups."),
            .model(ModelExplainer(
                name: "Analysis of variance (ANOVA)",
                purpose: "Tests whether several group means are all equal by comparing how much the group means vary with how much individuals vary within groups.",
                equation: "F = MSG / MSE = [Σ nᵢ(x̄ᵢ − x̄)² / (k − 1)] / [Σ (nᵢ − 1)sᵢ² / (n − k)]",
                steps: [
                    "**Mean square between groups (MSG):** the variability of the group means around the grand mean, scaled by group sizes.",
                    "**Mean square error (MSE):** the pooled variability of observations within their own groups.",
                    "If H₀ (all means equal) is true, MSG and MSE estimate the same quantity, so F ≈ 1. Large F values suggest the groups really differ.",
                    "The p-value comes from the F distribution with k − 1 and n − k degrees of freedom.",
                    "A significant F says *some* means differ; follow up with corrected pairwise comparisons or planned contrasts to find which.",
                ],
                conditions: [
                    "**Independence** within and between groups.",
                    "**Approximately normal** data within each group (most important with small groups; look for outliers).",
                    "**Roughly equal variability** across groups (compare SDs or boxplots).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.5 (comparing many means with ANOVA)."
            )),
            .chart(ChartExample(
                title: "Group means with their 95% confidence intervals",
                kind: .groupMeans,
                reading: [
                    "Faint dots are individual students; the white dot is each group's mean and the vertical bar its 95% CI.",
                    "ANOVA asks whether the means differ by more than the spread **within** groups would suggest.",
                    "Here the active-learning mean sits clearly above lecture, with CIs that barely overlap; flipped sits between them.",
                    "Overlapping CIs don't prove “no difference” — use post-hoc tests for specific comparisons. Hover over a group to read its mean and CI.",
                ]
            )),
            .chart(ChartExample(
                title: "Reading an interaction plot",
                kind: .interactionMeans,
                reading: [
                    "Each line shows mean ratings for one sentence structure at short and long distances.",
                    "**Main effect of structure:** the complex line is lower overall than the simple line.",
                    "**Main effect of distance:** both lines go down from short to long.",
                    "**Interaction:** the lines aren't parallel — the drop is much steeper for complex sentences. Parallel lines would mean no interaction.",
                ]
            )),
            .code(CodeSample(
                caption: "One-way, post-hoc, and mixed ANOVA",
                python: #"""
                import pandas as pd
                import pingouin as pg

                classroom = pd.read_csv("classroom.csv")

                # One-way: do post-test scores differ across teaching methods?
                print(pg.anova(data=classroom, dv="posttest", between="method", detailed=True))

                # Post-hoc pairwise comparisons, corrected
                print(pg.pairwise_tukey(data=classroom, dv="posttest", between="method"))

                # 2-way factorial (between-subjects): method × school
                print(pg.anova(data=classroom, dv="posttest", between=["method", "school"]))

                # Mixed: within-subject time (pre/post) × between-subject method
                long = classroom.melt(id_vars=["student", "method"], value_vars=["pretest", "posttest"],
                                      var_name="time", value_name="score")
                print(pg.mixed_anova(data=long, dv="score", within="time", between="method", subject="student"))
                """#,
                r: #"""
                library(tidyverse)
                library(afex)
                library(emmeans)

                classroom <- read_csv("classroom.csv")

                # One-way (between-subjects): do post-test scores differ across teaching methods?
                fit <- aov_ez(id = "student", dv = "posttest", between = "method", data = classroom)
                fit

                # Post-hoc pairwise comparisons, corrected
                pairs(emmeans(fit, ~ method), adjust = "tukey")

                # 2-way factorial (between-subjects): method × school
                aov_ez(id = "student", dv = "posttest", between = c("method", "school"), data = classroom)

                # Mixed: within-subject time (pre/post) × between-subject method
                long <- classroom |> pivot_longer(c(pretest, posttest), names_to = "time", values_to = "score")
                aov_ez(id = "student", dv = "score", data = long, within = "time", between = "method")
                """#
            )),
            .keyPoint("Interpret interactions first", "An interaction means the effect of one factor **depends on** the level of another. When it's present, main effects can be misleading on their own — plot the cell means before interpreting anything."),
            .caution("Multiple comparisons", "Following an ANOVA with every possible uncorrected t-test inflates the false-positive rate. Use a correction (Tukey, Holm, Bonferroni) or test planned contrasts that you specified in advance."),
            .terms([
                Term("Main effect", "The overall effect of one factor, averaging over the others."),
                Term("Interaction", "When one factor's effect changes across levels of another."),
                Term("Sphericity", "A repeated-measures assumption; violations are corrected with Greenhouse–Geisser."),
            ]),
            .field(.linguistics, "A 2 × 2 design crossing word frequency (high/low) with age group (young/older) tests whether older adults show a larger frequency effect — that's the interaction."),
        ],
        quiz: [
            Question(
                prompt: "There's a significant interaction between word frequency and age group. This means…",
                options: [
                    "Both factors have main effects",
                    "The frequency effect differs between age groups",
                    "Age group has no effect",
                    "The ANOVA assumptions are violated",
                ],
                answer: 1,
                explanation: "An interaction means one factor's effect depends on the other."
            ),
        ]
    )

    static let chiSquare = Lesson(
        id: "chi-square",
        title: "Categorical data: chi-square",
        summary: "Contingency tables — a sociology staple.",
        minutes: 8,
        blocks: [
            .text("When **both** variables are categorical — class background and university attendance, or speaker gender and variant choice — you analyze counts in a contingency table. The chi-square (χ²) test asks whether the observed counts differ from what independence would predict."),
            .model(ModelExplainer(
                name: "The chi-square test of independence",
                purpose: "Tests whether two categorical variables are associated by comparing the counts in a two-way table with the counts expected if they were independent.",
                equation: "expected = (row total × column total) / table total        χ² = Σ (observed − expected)² / expected",
                steps: [
                    "Compute an **expected count** for every cell under independence.",
                    "For each cell, square the gap between observed and expected and divide by expected; sum these over all cells to get χ².",
                    "Under H₀, χ² follows a chi-square distribution with df = (rows − 1) × (columns − 1).",
                    "A large χ² (small p) means the observed pattern is unlikely under independence. Look at which cells contribute most, and report an effect size such as Cramér's V.",
                ],
                conditions: [
                    "**Independence:** each case contributes to exactly one cell, and cases are independent of each other.",
                    "**Sample size:** every cell has an expected count of at least 5 (otherwise use Fisher's exact test or combine categories).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §6.3 (goodness of fit) and §6.4 (testing for independence in two-way tables)."
            )),
            .chart(ChartExample(
                title: "Comparing observed shares with “if independent”",
                kind: .contingencyBars,
                reading: [
                    "Each bar shows the share of a group who attended university (blue) or didn't (gray).",
                    "The last bar is what every group would look like **if attendance were independent of class background** — the overall share.",
                    "The further groups depart from that reference bar, the larger χ² becomes.",
                    "Here working-class students attend far less often and upper-class students far more often than independence would predict.",
                ]
            )),
            .code(CodeSample(
                caption: "Chi-square test of independence with Cramér's V: is education level associated with region?",
                python: #"""
                import numpy as np
                import pandas as pd
                from scipy import stats

                survey = pd.read_csv("survey.csv")
                table = pd.crosstab(survey["region"], survey["education"])   # 2 regions × 5 education levels
                chi2, p, dof, expected = stats.chi2_contingency(table)
                print(table, f"\nchi2({dof}) = {chi2:.2f}, p = {p:.3f}")

                # Effect size: Cramér's V
                n = table.to_numpy().sum()
                v = np.sqrt(chi2 / (n * (min(table.shape) - 1)))
                print("V =", round(v, 3))
                """#,
                r: #"""
                survey <- read.csv("survey.csv")
                tab <- table(survey$region, survey$education)   # 2 regions × 5 education levels
                chisq.test(tab)

                # Effect size: Cramér's V
                effectsize::cramers_v(tab)
                """#
            )),
            .caution("Small expected counts", "The χ² approximation breaks down when expected cell counts fall below about 5. For 2 × 2 tables, use Fisher's exact test instead: `stats.fisher_exact()` or `fisher.test()`."),
            .field(.linguistics, "Variationist sociolinguistics, following Labov, asks whether the use of *-in'* vs. *-ing* (“walkin'” vs. “walking”) differs across social classes or speech styles."),
            .keyPoint("One observation per person", "χ² assumes every count is independent. If each speaker contributes many tokens, their tokens aren't independent — use mixed-effects logistic regression with a random effect for speaker instead (Unit 7)."),
        ],
        quiz: [
            Question(
                prompt: "Each of 30 speakers contributes 50 tokens of a variable. Why is a simple χ² on all 1,500 tokens problematic?",
                options: ["The table is too large", "Tokens from the same speaker aren't independent", "χ² needs normal data", "Nothing — it's fine"],
                answer: 1,
                explanation: "Speakers differ in their baseline rates, so their tokens cluster. Treating them as independent overstates the evidence."
            ),
        ]
    )

    static let nonParametric = Lesson(
        id: "non-parametric",
        title: "Rank-based alternatives",
        summary: "Mann–Whitney, Wilcoxon, Kruskal–Wallis, Spearman.",
        minutes: 6,
        blocks: [
            .model(ModelExplainer(
                name: "Rank-based tests",
                purpose: "Compare groups or measure association using the ranks of the data rather than the raw values, so results don't depend on normality or on extreme values.",
                steps: [
                    "Pool the observations and replace each value with its **rank** (ties share the average rank).",
                    "**Mann–Whitney / Wilcoxon rank-sum:** compare the sum of ranks in two groups. **Wilcoxon signed-rank:** rank the absolute paired differences and compare positive and negative ranks. **Kruskal–Wallis:** an ANOVA-like test on ranks for 3+ groups.",
                    "Compare the rank statistic with its distribution under H₀ (exact for small samples, normal approximation for larger ones).",
                    "**Spearman's ρ** is Pearson's r computed on ranks, measuring any monotonic relationship.",
                ],
                conditions: [
                    "**Independence**, as for the corresponding parametric test.",
                    "**At least ordinal data**.",
                    "To interpret a rank-sum test as a difference in medians, the groups' distributions should have **similar shapes**; otherwise it tests whether one group tends to have larger values.",
                ],
                reading: "Conover (1999), *Practical Nonparametric Statistics* (3rd ed.); for the parametric counterparts, OpenIntro Statistics (4th ed.), §7.1–7.5."
            )),
            .terms([
                Term("Independent t-test →", "Mann–Whitney U (Wilcoxon rank-sum)"),
                Term("Paired t-test →", "Wilcoxon signed-rank"),
                Term("One-way ANOVA →", "Kruskal–Wallis"),
                Term("Pearson r →", "Spearman ρ"),
            ]),
            .code(CodeSample(
                caption: "Rank-based tests",
                python: #"""
                import pandas as pd
                from scipy import stats

                classroom = pd.read_csv("classroom.csv")
                active = classroom.loc[classroom["method"] == "active", "posttest"]
                lecture = classroom.loc[classroom["method"] == "lecture", "posttest"]

                print(stats.mannwhitneyu(active, lecture))                                   # two independent groups
                print(stats.wilcoxon(classroom["posttest"], classroom["pretest"]))           # the same students twice
                print(stats.kruskal(*[g["posttest"] for _, g in classroom.groupby("method")]))   # three or more groups
                """#,
                r: #"""
                classroom <- read.csv("classroom.csv")
                two_groups <- subset(classroom, method %in% c("active", "lecture"))

                wilcox.test(posttest ~ method, data = two_groups)                     # two independent groups
                wilcox.test(classroom$posttest, classroom$pretest, paired = TRUE)     # the same students twice
                kruskal.test(posttest ~ method, data = classroom)                     # three or more groups
                """#
            )),
            .keyPoint("When to use them", "Ordinal outcomes, such as a single Likert item, or small samples with heavy skew or extreme outliers."),
            .caution("They test a different question", "Rank tests compare distributions and ranks, **not means**. Alternatives worth knowing include transforming the outcome, robust methods such as trimmed means (Wilcox, 2017), and ordinal regression models (Liddell & Kruschke, 2018)."),
        ],
        quiz: [
            Question(
                prompt: "What's the rank-based alternative to a paired t-test?",
                options: ["Mann–Whitney U", "Kruskal–Wallis", "Wilcoxon signed-rank", "Spearman ρ"],
                answer: 2,
                explanation: "Wilcoxon signed-rank works on the ranks of the paired differences."
            ),
        ]
    )
}

// MARK: - Unit 5 · Relationships

extension Curriculum {
    static let relationships = Unit(
        id: "relationships", number: 5, title: "Relationships & regression", level: .intermediate,
        summary: "Correlation (between and within people), linear and logistic regression, diagnostics, and two real-data labs.",
        symbol: "chart.dots.scatter",
        lessons: [correlation, betweenWithin, simpleRegression, multipleRegression, comparingPredictors, regressionDiagnostics, logisticRegression, evalsLab, resumeLab]
    )

    static let correlation = Lesson(
        id: "correlation",
        title: "Correlation",
        summary: "Measuring how two variables move together.",
        minutes: 7,
        blocks: [
            .text("The correlation coefficient *r* ranges from −1 to +1. **Pearson's r** captures linear relationships between continuous variables. **Spearman's ρ** works on ranks, so it handles ordinal data and monotonic curves."),
            .model(ModelExplainer(
                name: "Pearson's correlation coefficient",
                purpose: "Measures the strength and direction of the **linear** relationship between two numerical variables on a scale from −1 to +1.",
                equation: "r = Σ (zₓ · z_y) / (n − 1)",
                steps: [
                    "Convert both variables to z-scores.",
                    "Multiply each pair of z-scores: the product is positive when both are above (or both below) their means and negative when they're on opposite sides.",
                    "Average the products (dividing by n − 1). Mostly positive products give r near +1; mostly negative products give r near −1; a mix gives r near 0.",
                    "r² is the proportion of variance in one variable that's linearly associated with the other.",
                    "Test H₀: ρ = 0 with t = r√(n − 2) / √(1 − r²), df = n − 2.",
                ],
                conditions: [
                    "**A linear relationship** — r can be near 0 for strong curved relationships. Always look at the scatterplot.",
                    "**No influential outliers**, which can create or hide a correlation.",
                    "**Independent pairs** — repeated measures from the same people need the methods in *Between- and within-person correlations*.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §8.1 (fitting a line, residuals, and correlation)."
            )),
            .chart(ChartExample(
                title: "What different correlations look like",
                kind: .correlationGallery,
                reading: [
                    "**r = −0.80:** a tight downward band — strong negative linear relationship.",
                    "**r ≈ 0:** a shapeless cloud — no linear relationship.",
                    "**r = 0.50:** a visible upward trend with plenty of scatter — a moderate, typical social-science correlation.",
                    "**Curved panel:** y depends strongly on x, yet r is near 0, because r only measures *linear* association. Always plot before you correlate.",
                ]
            )),
            .code(CodeSample(
                caption: "Pairwise correlations and a correlation matrix",
                python: #"""
                import pandas as pd
                import pingouin as pg
                from scipy import stats

                survey = pd.read_csv("survey.csv")

                print(stats.pearsonr(survey["social_media"], survey["anxiety"]))
                print(stats.spearmanr(survey["social_media"], survey["anxiety"]))

                print(pg.corr(survey["social_media"], survey["anxiety"]))   # r, 95% CI, p, power

                print(survey[["social_media", "anxiety", "rumination"]].corr())
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")

                cor.test(survey$social_media, survey$anxiety)                        # Pearson
                cor.test(survey$social_media, survey$anxiety, method = "spearman")

                survey |>
                  select(social_media, anxiety, rumination) |>
                  cor(use = "pairwise.complete.obs")
                """#
            )),
            .caution("Third variables", "Social media use and anxiety may both be driven by a third variable, like poor sleep or loneliness. A correlation alone can't tell you the direction of an effect, or whether there's an effect at all."),
            .keyPoint("Calibrating r", "Cohen's benchmarks are .10 / .30 / .50. But Funder & Ozer (2019) argue that in psychology an *r* of about .20 is a medium effect — and that small effects can add up over time and across people."),
            .field(.linguistics, "Word frequency correlates strongly with naming and lexical decision speed: more frequent words are recognized faster. The relationship is roughly linear on a **log** frequency scale."),
            .field(.sociology, "Neighborhood income correlates with generalized trust — but residential sorting and many confounds make causal interpretation hard."),
        ],
        quiz: [
            Question(
                prompt: "You're correlating two single 1–5 Likert items. Which coefficient fits best?",
                options: ["Pearson's r", "Spearman's ρ", "Cohen's d", "Cramér's V"],
                answer: 1,
                explanation: "Single Likert items are ordinal; Spearman uses ranks and doesn't assume equal spacing."
            ),
        ]
    )

    static let simpleRegression = Lesson(
        id: "simple-regression",
        title: "Linear regression",
        summary: "The workhorse of social science.",
        minutes: 9,
        blocks: [
            .text("Regression is arguably the most widely used method across the social sciences. It models an outcome as a line: *y* = *b*₀ + *b*₁*x* + error. In fact, t-tests and ANOVA are special cases of the same linear model."),
            .model(ModelExplainer(
                name: "Simple linear regression (least squares)",
                purpose: "Fits the straight line that best predicts a numerical outcome from one predictor, and estimates how much the outcome changes per unit of the predictor.",
                equation: "ŷ = b₀ + b₁x        b₁ = r · (s_y / s_x)        b₀ = ȳ − b₁x̄",
                steps: [
                    "For any candidate line, the **residual** for each point is observed − predicted (y − ŷ).",
                    "**Least squares** chooses the line that minimizes the sum of squared residuals. The solution always passes through (x̄, ȳ), with slope r · s_y / s_x.",
                    "The slope b₁ is the expected change in y per one-unit increase in x; the intercept b₀ is the prediction at x = 0.",
                    "R² = r² is the share of the outcome's variance explained by the line.",
                    "Inference: t = b₁ / SE(b₁) with df = n − 2 tests whether the true slope is 0; b₁ ± t* · SE gives its CI.",
                ],
                conditions: [
                    "**Linearity:** the data follow a straight-line trend (check the scatterplot and the residual plot).",
                    "**Nearly normal residuals** (look for outliers in a histogram or Q–Q plot of residuals).",
                    "**Constant variability:** the spread of residuals is similar across x — no funnel shape.",
                    "**Independent observations** (be careful with time-series or repeated data).",
                    "Watch for **high-leverage and influential points**, and don't **extrapolate** beyond the observed x range.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §8.2 (least squares regression), §8.3 (types of outliers), §8.4 (inference for linear regression)."
            )),
            .chart(ChartExample(
                title: "The least-squares line and its residuals",
                kind: .regressionResiduals,
                reading: [
                    "White dots are observations; the blue line is the fitted regression line.",
                    "Each pink segment is a **residual**: the vertical distance from a point to the line (observed − predicted).",
                    "Least squares chooses the line that makes the sum of the **squared** residuals as small as possible.",
                    "The slope is how much predicted anxiety rises per one-point increase in rumination. Hover near a point to read its observed value, predicted value, and residual.",
                ]
            )),
            .chart(ChartExample(
                title: "Checking assumptions with residual plots",
                kind: .residualPlots,
                reading: [
                    "Both panels plot residuals against fitted values, with a dashed line at 0.",
                    "**Left:** residuals scatter evenly above and below 0 at every fitted value — the constant-variance and linearity conditions look fine.",
                    "**Right:** the spread widens as fitted values grow (a funnel) — **non-constant variance**. Standard errors from ordinary regression will be off; consider a transformation or robust SEs.",
                    "A curved band of residuals (not shown) would instead signal a non-linear relationship the model is missing.",
                ]
            )),
            .code(CodeSample(
                caption: "Fit, inspect, and diagnose a regression",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                model = smf.ols("anxiety ~ rumination", data=survey).fit()
                print(model.summary())

                print(model.params)       # intercept and slope
                print(model.conf_int())   # 95% CIs
                print(model.rsquared)
                """#,
                r: #"""
                survey <- read.csv("survey.csv")
                model <- lm(anxiety ~ rumination, data = survey)
                summary(model)
                confint(model)

                plot(model)   # residual diagnostics
                """#
            )),
            .keyPoint("Reading the slope", "The slope is the expected change in the outcome for a **one-unit** increase in the predictor. So always know your units — income in dollars vs. thousands of dollars changes the number completely."),
            .terms([
                Term("Intercept (b₀)", "Predicted outcome when every predictor equals 0."),
                Term("Residual", "Observed minus predicted value."),
                Term("R²", "Proportion of variance in the outcome explained by the model."),
            ]),
            .caution("Check the assumptions", "**L**inearity, **I**ndependence of errors, **N**ormality of residuals, **E**qual variance (LINE). Look at residual-vs-fitted plots; a funnel shape signals unequal variance."),
        ],
        quiz: [
            Question(
                prompt: "wellbeing = 3.2 + 0.05 × income (in $1,000s). What does 0.05 mean?",
                options: [
                    "5% of wellbeing is explained by income",
                    "Each extra $1,000 is associated with 0.05 higher wellbeing",
                    "Wellbeing is 0.05 when income is 0",
                    "The correlation is .05",
                ],
                answer: 1,
                explanation: "The slope is the expected change per one-unit increase in the predictor."
            ),
        ]
    )

    static let multipleRegression = Lesson(
        id: "multiple-regression",
        title: "Multiple regression & interactions",
        summary: "Covariates, categorical predictors, and moderation.",
        minutes: 11,
        blocks: [
            .text("With several predictors, each coefficient is the effect of that predictor **holding the others constant**. Interactions (`a * b`) test *moderation*: does the effect of one predictor depend on another?"),
            .model(ModelExplainer(
                name: "Multiple regression",
                purpose: "Predicts an outcome from several predictors at once; each coefficient estimates a predictor's association with the outcome while the other predictors are held constant.",
                equation: "ŷ = b₀ + b₁x₁ + b₂x₂ + … + b_kx_k",
                steps: [
                    "Least squares again minimizes the sum of squared residuals, now in k dimensions.",
                    "Each coefficient bⱼ is the expected change in y per unit of xⱼ **among cases with the same values of the other predictors**.",
                    "Categorical predictors enter as k − 1 indicator variables relative to a reference level; an interaction `x₁ × x₂` lets the effect of one predictor depend on another.",
                    "**Adjusted R²** penalizes extra predictors: 1 − (1 − R²)(n − 1)/(n − k − 1). It only rises if a new predictor improves the fit more than chance would.",
                    "Each coefficient has its own t-test; nested models are compared with an F-test on the change in R².",
                ],
                conditions: [
                    "The four conditions of simple regression, checked with residual plots: **linearity** (residuals vs. each predictor), **nearly normal residuals**, **constant variability** (residuals vs. fitted values), and **independence** (residuals in data-collection order).",
                    "**Limited collinearity:** strongly correlated predictors make individual coefficients unstable (check VIFs).",
                    "Choose predictors on substantive grounds; if you do use selection, be aware that **backward/forward selection** capitalizes on chance and should be validated.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.1 (introduction to multiple regression), §9.2 (model selection), §9.3 (checking model conditions using graphs)."
            )),
            .chart(ChartExample(
                title: "Reading a coefficient plot",
                kind: .coefficientPlot,
                reading: [
                    "Each row is one predictor in the same multiple regression; the dot is its standardized coefficient (β) and the bar its 95% CI.",
                    "The dashed vertical line marks β = 0 (no association). A CI that **crosses** it means the predictor isn't significant at α = .05.",
                    "Because coefficients are standardized, you can compare their sizes: rumination's association with anxiety is several times larger than social media's.",
                    "Each β is the association **holding the other predictors constant**. Hover over a row to read its numbers.",
                ]
            )),
            .code(CodeSample(
                caption: "Covariates, interactions, and model comparison",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf
                from statsmodels.stats.anova import anova_lm

                survey = pd.read_csv("survey.csv")

                # Centering makes the intercept and lower-order terms interpretable
                survey["age_c"] = survey["age"] - survey["age"].mean()

                m1 = smf.ols("anxiety ~ rumination + age_c + C(region)", data=survey).fit()

                # Does the rumination effect depend on age? (moderation)
                m2 = smf.ols("anxiety ~ rumination * age_c + C(region)", data=survey).fit()

                print(anova_lm(m1, m2))   # does the interaction improve fit?
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv") |> mutate(age_c = age - mean(age, na.rm = TRUE))

                m1 <- lm(anxiety ~ rumination + age_c + region, data = survey)

                # Does the rumination effect depend on age? (moderation)
                m2 <- lm(anxiety ~ rumination * age_c + region, data = survey)

                anova(m1, m2)   # does the interaction improve fit?
                car::vif(m1)    # multicollinearity check
                """#
            )),
            .keyPoint("Dummy coding", "A categorical predictor with *k* levels becomes *k* − 1 indicator variables, each compared to a **reference level**. The coefficient for “C(region)[T.urban]” is the difference between urban and the reference group (rural)."),
            .caution("“Controlling for” isn't magic", "Adjusting for a variable that lies on the causal path (a mediator) or is caused by both predictor and outcome (a collider) can *create* bias. Also avoid stepwise selection: it capitalizes on chance, giving biased coefficients and overconfident p-values (Harrell, 2015, ch. 4)."),
            .field(.sociology, "Classic status-attainment models regress occupational prestige on parental occupation and education, asking how much of the family advantage is transmitted through schooling."),
        ],
        quiz: [
            Question(
                prompt: "In formula syntax, `a * b` expands to…",
                options: ["a:b only", "a + b", "a + b + a:b", "a × b as a single number"],
                answer: 2,
                explanation: "The asterisk includes both main effects and their interaction term."
            ),
        ]
    )

    static let logisticRegression = Lesson(
        id: "logistic-regression",
        title: "Logistic regression",
        summary: "Modeling yes/no outcomes: correct, voted, used a variant.",
        minutes: 9,
        blocks: [
            .text("Many social-science outcomes are binary: a response was correct or not, a person voted or didn't, a speaker used one variant or another. **Logistic regression** models the log-odds of the outcome."),
            .model(ModelExplainer(
                name: "Logistic regression",
                purpose: "Models the probability of a two-level outcome as a function of predictors, using the logit transformation so predictions always stay between 0 and 1.",
                equation: "logit(pᵢ) = log[pᵢ / (1 − pᵢ)] = b₀ + b₁x₁ + … + b_kx_k",
                steps: [
                    "A linear model for a probability could predict values below 0 or above 1. The **logit** stretches probabilities onto the whole number line, so a linear model fits there.",
                    "Coefficients are changes in **log-odds** per unit of the predictor; exp(b) is the **odds ratio**.",
                    "To predict, compute the linear predictor, then convert back: p = 1 / (1 + e^−(b₀ + b₁x₁ + …)).",
                    "Coefficients are estimated by **maximum likelihood**; each has a z-test, and nested models are compared with likelihood-ratio tests.",
                    "Logistic regression is one member of the family of **generalized linear models**.",
                ],
                conditions: [
                    "**Independent outcomes** (or a model that accounts for clustering).",
                    "Each numerical predictor is **linearly related to logit(p)** when the others are held constant — check by plotting observed proportions against predicted probabilities.",
                    "**Enough events** in each outcome category for the number of predictors.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.5 (introduction to logistic regression)."
            )),
            .chart(ChartExample(
                title: "From log-odds to probabilities: the logistic curve",
                kind: .logisticCurve,
                reading: [
                    "Gray dots at the top and bottom are individual people: 1 = high anxiety, 0 = not (jittered so they don't overlap).",
                    "The blue S-curve is the model's predicted probability; it can never go below 0 or above 1.",
                    "Orange diamonds are the observed share of 1s in each bin — if they track the curve, the model fits well.",
                    "The curve is steepest in the middle: the same one-point change in rumination shifts probability a lot near p = .5 and very little near 0 or 1, even though the odds ratio is constant. Hover to read the probability and odds.",
                ]
            )),
            .code(CodeSample(
                caption: "Fit a logistic model and convert to odds ratios",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                survey["high_anxiety"] = (survey["anxiety"] >= 5).astype(int)   # 1 = anxiety of 5+ on the 1–7 scale
                survey["age_c"] = survey["age"] - survey["age"].mean()

                m = smf.logit("high_anxiety ~ rumination + age_c + C(region)", data=survey).fit()
                print(m.summary())

                print(np.exp(m.params))       # odds ratios
                print(np.exp(m.conf_int()))   # 95% CIs for odds ratios
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv") |>
                  mutate(high_anxiety = as.integer(anxiety >= 5),    # 1 = anxiety of 5+ on the 1–7 scale
                         age_c = age - mean(age))

                m <- glm(high_anxiety ~ rumination + age_c + region, data = survey, family = binomial)
                summary(m)

                exp(coef(m))      # odds ratios
                exp(confint(m))   # 95% CIs for odds ratios
                """#
            )),
            .keyPoint("Odds ratios", "OR > 1 means higher odds; OR < 1 means lower odds. An OR of 1.5 means **50% higher odds** — not a 50% higher probability. Odds and probabilities diverge when outcomes are common."),
            .caution("Don't run ANOVA on proportions", "Analyzing percent-correct with ANOVA can produce impossible predictions (below 0% or above 100%) and spurious effects. Jaeger (2008) made the case for logistic (mixed) models instead."),
            .field(.linguistics, "Sociolinguistic variation — e.g. whether a speaker deletes /t/ in “just” — has been modeled with logistic regression since the variable-rule (Varbrul) tradition."),
        ],
        quiz: [
            Question(
                prompt: "An odds ratio of 2.0 for “has a degree” predicting voting means…",
                options: [
                    "Graduates are twice as likely to vote",
                    "Graduates have twice the odds of voting",
                    "20% more graduates vote",
                    "The effect isn't significant",
                ],
                answer: 1,
                explanation: "ORs are about odds, which only approximate probabilities when the outcome is rare."
            ),
        ]
    )
}

// MARK: - Unit 7 · Measurement & multilevel models

extension Curriculum {
    static let advanced = Unit(
        id: "advanced", number: 7, title: "Measurement & multilevel models", level: .advanced,
        summary: "Mixed and growth models for clustered and longitudinal data, scale scores, reliability, CFA, and transparent reporting.",
        symbol: "point.3.connected.trianglepath.dotted",
        lessons: [mixedModels, mixedLogistic, growthModels, scaleScoring, reliability, cfa, interRater, reporting]
    )

    static let mixedModels = Lesson(
        id: "mixed-models",
        title: "Linear mixed-effects models",
        summary: "Participants and items as crossed random effects.",
        minutes: 14,
        blocks: [
            .text("Social-science data are rarely independent. Trials are nested in participants, and the same words appear for every participant; students are nested in schools. **Mixed-effects (multilevel) models** estimate fixed effects while modeling this clustering with random effects."),
            .model(ModelExplainer(
                name: "Linear mixed-effects (multilevel) models",
                purpose: "Fits a regression to clustered data — trials within participants, students within schools — by modeling how clusters differ, so standard errors reflect the real amount of independent information.",
                equation: "yᵢⱼ = (b₀ + uᵢ + wⱼ) + (b₁ + vᵢ)·xᵢⱼ + eᵢⱼ      uᵢ, vᵢ ~ participant;  wⱼ ~ item",
                steps: [
                    "**Fixed effects** (b₀, b₁) are the average intercept and slope — the effects you want to generalize.",
                    "**Random effects** are each cluster's deviation from those averages (random intercepts u, w; random slopes v). The model estimates their **variances** rather than a separate parameter for every cluster.",
                    "Clusters with little data are **shrunk** toward the average, a sensible compromise between ignoring clusters and fitting each one separately.",
                    "Estimation uses (restricted) maximum likelihood; p-values for fixed effects use approximations such as Satterthwaite df (`lmerTest`).",
                    "The **ICC** — between-cluster variance / total variance — says how much clustering there is.",
                ],
                conditions: [
                    "**Linearity, normal residuals, and constant variance**, as in regression.",
                    "**Random effects approximately normal**, and **enough clusters** to estimate their variance — simulations suggest roughly 30–50 for accurate standard errors, with small-sample corrections (e.g. Kenward–Roger) below that (Maas & Hox, 2005; McNeish & Stapleton, 2016).",
                    "**A random-effects structure justified by the design** — include random slopes for within-cluster predictors where the data support them, and report how convergence problems were handled.",
                ],
                reading: "Winter (2019), *Statistics for Linguists*, chs. 14–15; Baayen, Davidson & Bates (2008), *Journal of Memory and Language*, 59, 390–412; Brown (2021), *Advances in Methods and Practices in Psychological Science*, 4(1)."
            )),
            .chart(ChartExample(
                title: "Random intercepts and slopes",
                kind: .randomEffects,
                reading: [
                    "Each gray line is one person's fitted relationship between daily work hours (relative to their usual) and wellbeing.",
                    "Lines start at different heights — **random intercepts**: some people are happier than others on a typical day.",
                    "Lines have different steepness — **random slopes**: long days hurt some people more than others.",
                    "The thick green line is the **fixed effect**: the relationship for an average person, which is what you generalize to the population.",
                ]
            )),
            .terms([
                Term("Fixed effect", "The effect you want to generalize — e.g. condition."),
                Term("Random intercept", "Each participant (or item) gets its own baseline."),
                Term("Random slope", "The effect of condition is allowed to vary across participants."),
                Term("Crossed", "Every participant sees every item, so the two groupings cross."),
                Term("Nested", "Each student belongs to exactly one school."),
            ]),
            .keyPoint("Subjects *and* items", "Clark (1973) warned that treating language stimuli as fixed is a fallacy — words are a sample too. Baayen, Davidson & Bates (2008) showed that crossed random effects handle both in **one model**, replacing separate by-subject (F1) and by-item (F2) ANOVAs."),
            .code(CodeSample(
                caption: "Crossed random effects for participants and items",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                trials = pd.read_csv("stroop_trials.csv")
                trials["log_rt"] = np.log(trials["rt"])

                # Random intercept + slope for participants
                m = smf.mixedlm("log_rt ~ condition", data=trials, groups=trials["participant"],
                                re_formula="~condition").fit()
                print(m.summary())

                # Crossed participants + items via variance components
                trials["all"] = 1
                m2 = smf.mixedlm("log_rt ~ condition", data=trials, groups="all",
                                 vc_formula={"participant": "0 + C(participant)", "item": "0 + C(item)"}).fit()
                print(m2.summary())
                """#,
                r: #"""
                library(tidyverse)
                library(lme4)
                library(lmerTest)   # adds p-values (Satterthwaite df)

                trials <- read_csv("stroop_trials.csv") |> mutate(log_rt = log(rt))

                m <- lmer(log_rt ~ condition +
                            (1 + condition | participant) +
                            (1 | item),
                          data = trials)
                summary(m)
                """#
            )),
            .caution("Random-effects structure is debated", "Barr et al. (2013) say **keep it maximal** — include all random slopes justified by the design. Bates, Kliegl, et al. (2015) argue for **parsimonious** models, since maximal models often fail to converge. Whatever you choose, report the full formula and how you handled convergence."),
            .keyPoint("R leads here", "`lme4` is the field standard. Python's statsmodels handles crossed effects only awkwardly, so many Python users switch to R (or the `pymer4` bridge) for this step."),
            .field(.sociology, "Multilevel models put students within schools or residents within neighborhoods, separating individual-level effects from context-level effects."),
        ],
        quiz: [
            Question(
                prompt: "Why include a random intercept for items in a word-recognition study?",
                options: [
                    "To increase the sample size",
                    "Words differ in baseline difficulty, and we want to generalize beyond these words",
                    "lme4 requires it",
                    "To remove outliers",
                ],
                answer: 1,
                explanation: "Items are sampled from a population of words; ignoring their variability inflates false positives."
            ),
            Question(
                prompt: "In `(1 + condition | participant)`, what does `condition` add?",
                options: ["A fixed effect", "A random slope for condition by participant", "An interaction", "A covariate"],
                answer: 1,
                explanation: "Terms inside the parentheses before the bar vary by the grouping factor after it."
            ),
        ]
    )

    static let reliability = Lesson(
        id: "reliability",
        title: "Reliability & factor analysis",
        summary: "Are your questionnaire scales measuring what you think?",
        minutes: 11,
        blocks: [
            .text("Constructs like anxiety, social trust, or language attitudes are measured with **multi-item scales**. Before analyzing scale scores, check that the items hang together (**reliability**) and reflect the structure you expect (**factor analysis**). Confirmatory factor analysis and SEM are increasingly common in psychology."),
            .model(ModelExplainer(
                name: "Factor analysis",
                purpose: "Explains the correlations among many items with a few unobserved factors, revealing which items measure the same thing and how strongly.",
                equation: "itemⱼ = λⱼ · factor + uniquenessⱼ",
                steps: [
                    "Each item is modeled as a **loading** (λ) times one or more latent factors, plus a unique part (specific variance + error).",
                    "**EFA** estimates loadings for every item on every factor and then **rotates** the solution to make it interpretable (oblimin allows factors to correlate; varimax forces them apart).",
                    "Decide how many factors with **parallel analysis** (compare eigenvalues with those from random data), plus interpretability.",
                    "**CFA** instead fixes in advance which items load on which factor and tests how well that structure fits (CFI, RMSEA, SRMR).",
                ],
                conditions: [
                    "**Enough cases** (often 200+, or 5–10 per item) and items that are reasonably correlated.",
                    "**Roughly continuous items** — for few-category items, use polychoric correlations or estimators designed for ordinal data.",
                    "**Correctly keyed items**, and a theory of the construct to judge interpretability.",
                ],
                reading: "Fabrigar, Wegener, MacCallum & Strahan (1999), *Psychological Methods*, 4(3), 272–299; Revelle, *psych* package documentation."
            )),
            .terms([
                Term("Cronbach's α", "Internal consistency. ≥ .70 is a common rule of thumb (traced to Nunnally, 1978), though the right threshold depends on how scores will be used."),
                Term("McDonald's ω", "A reliability index with fewer assumptions than α; increasingly preferred."),
                Term("EFA", "Exploratory factor analysis — discover the structure."),
                Term("CFA", "Confirmatory factor analysis — test a hypothesized structure."),
                Term("Loading", "How strongly an item relates to a factor."),
            ]),
            .code(CodeSample(
                caption: "Reliability and exploratory factor analysis",
                python: #"""
                # pip install factor_analyzer
                import pandas as pd
                import pingouin as pg
                from factor_analyzer import FactorAnalyzer

                survey = pd.read_csv("survey.csv")
                items = survey[[f"mind_{i}" for i in range(1, 7)]].copy()
                items[["mind_3", "mind_5"]] = 6 - items[["mind_3", "mind_5"]]     # reverse-key first

                alpha, ci = pg.cronbach_alpha(data=items)
                print("alpha:", round(alpha, 2), ci)

                fa = FactorAnalyzer(n_factors=1, rotation=None)   # with several factors: n_factors=2, rotation="oblimin"
                fa.fit(items.dropna())
                print(pd.DataFrame(fa.loadings_, index=items.columns, columns=["loading"]).round(2))
                """#,
                r: #"""
                library(tidyverse)
                library(psych)

                items <- read_csv("survey.csv") |>
                  select(mind_1:mind_6) |>
                  mutate(across(c(mind_3, mind_5), ~ 6 - .x))     # reverse-key first

                psych::alpha(items)          # Cronbach's alpha
                omega(items, nfactors = 1)   # McDonald's omega

                fa.parallel(items)           # how many factors?
                fa(items, nfactors = 1)      # with several factors: nfactors = 2, rotate = "oblimin"
                """#
            )),
            .caution("Reverse-score first", "Items worded in the opposite direction (“I feel calm”) must be recoded before computing α. On a 1–5 scale, the recoded value is 6 − *x*; on a 1–7 scale, 8 − *x*. Forgetting this is one of the most common errors in survey research."),
            .keyPoint("Higher isn't always better", "α above about .95 can mean the items are redundant rewordings of each other. For confirmatory models, use `lavaan` in R or `semopy` in Python."),
            .field(.psychology, "Big Five personality inventories are validated with factor analysis: each item should load mainly on its intended trait."),
            .field(.sociology, "Cross-national surveys such as the World Values Survey test **measurement invariance**: whether a trust scale means the same thing in every country before comparing means."),
        ],
        quiz: [
            Question(
                prompt: "A reverse-worded item uses a 1–7 scale. How do you recode a response x?",
                options: ["7 − x", "8 − x", "x − 7", "−x"],
                answer: 1,
                explanation: "Max + min − x = 7 + 1 − x, so 1 ↔ 7, 2 ↔ 6, and so on."
            ),
        ]
    )

    static let reporting = Lesson(
        id: "reporting",
        title: "Reporting & open science",
        summary: "APA style, transparency, and avoiding the garden of forking paths.",
        minutes: 9,
        blocks: [
            .text("Analysis isn't finished until it's reported clearly enough for someone else to evaluate and reproduce it. In APA style (American Psychological Association, 2020, 7th ed.), statistical symbols are italicized, exact *p*-values are reported (*p* = .032, or *p* < .001), and effect sizes come with confidence intervals."),
            .code(CodeSample(
                caption: "Generate a report string directly from results",
                python: #"""
                import pandas as pd
                import pingouin as pg

                classroom = pd.read_csv("classroom.csv")
                treat = classroom.loc[classroom["method"] == "active", "posttest"]
                ctrl = classroom.loc[classroom["method"] == "lecture", "posttest"]
                res = pg.ttest(treat, ctrl, correction=True).iloc[0]          # Welch's t-test

                # APA style: no leading zero on p, and "p < .001" for very small values
                p_text = "< .001" if res["p-val"] < .001 else "= " + f"{res['p-val']:.3f}".lstrip("0")
                print(f"t({res['dof']:.1f}) = {res['T']:.2f}, p {p_text}, d = {res['cohen-d']:.2f}")
                """#,
                r: #"""
                library(report)   # part of easystats

                classroom <- read.csv("classroom.csv")
                two_groups <- subset(classroom, method %in% c("active", "lecture"))
                t.test(posttest ~ method, data = two_groups) |> report()
                # "The Welch Two Sample t-test testing the difference of posttest by method ..."
                """#
            )),
            .keyPoint("Reporting checklist", "• Sample size and every exclusion, with reasons\n• Descriptives (*M*, *SD*) for each group\n• The test used and its assumption checks\n• Test statistic, df, and exact *p*\n• Effect size with 95% CI\n• Software and package versions"),
            .terms([
                Term("Preregistration", "Publicly recording hypotheses and analysis plans before data collection."),
                Term("Registered report", "A journal format where peer review happens before results exist."),
                Term("HARKing", "Hypothesizing After Results are Known."),
                Term("Open data & code", "Sharing materials so others can reproduce your analysis."),
            ]),
            .caution("The garden of forking paths", "Even without deliberate p-hacking, each data-dependent choice — which covariates, which exclusions, which outcome — multiplies the ways to find a “significant” result. Preregistration makes the planned path visible."),
            .field(.linguistics, "Meteyard & Davies (2020) surveyed 163 researchers and reviewed 400 papers using mixed models, and found the most worrying inconsistency in how the models were **reported**. Always state the full model formula, random-effects structure, and any simplification steps."),
        ],
        quiz: [
            Question(
                prompt: "Which is correctly formatted APA style?",
                options: ["p = 0.000", "t(38) = 2.10, p = .042, d = 0.66", "P<.05!", "t = 2.1 (significant)"],
                answer: 1,
                explanation: "Report the statistic with df, an exact p (no leading zero), and an effect size."
            ),
        ]
    )
}

import Foundation

// Model families that extend Units 7 and 9: confirmatory factor analysis and longitudinal
// growth models (Unit 7), and count outcomes (Unit 9).

// MARK: - Unit 7 · Confirmatory factor analysis

extension Curriculum {
    static let cfa = Lesson(
        id: "cfa",
        title: "Confirmatory factor analysis & invariance",
        summary: "Test a measurement model, read fit indices, and check that a scale works the same across groups.",
        minutes: 14,
        blocks: [
            .text("*Reliability & factor analysis* explored which items hang together. **Confirmatory factor analysis (CFA)** goes further: you state in advance which items measure which construct, then test whether that model reproduces the items' correlations. It's the standard way to validate a scale — and the measurement half of structural equation modelling (SEM)."),
            .model(ModelExplainer(
                name: "Confirmatory factor analysis",
                purpose: "Tests a hypothesized measurement model in which each item reflects one or more latent factors plus item-specific error.",
                equation: "itemⱼ = λⱼ · Factor + eⱼ        model-implied covariance: Σ = ΛΦΛ′ + Θ",
                steps: [
                    "Specify which items **load** on which factor; every other loading is fixed at 0.",
                    "Give the factor a scale — fix the first loading to 1 or the factor variance to 1.",
                    "Maximum likelihood finds the loadings (λ), factor variance (Φ), and error variances (Θ) whose implied covariance matrix Σ is closest to the observed one.",
                    "Judge **fit**: the χ² test (sensitive to sample size), CFI and TLI (≥ .95 good), RMSEA (≤ .06 good), and SRMR (≤ .08 good) — Hu & Bentler's (1999) cutoffs, which are guidelines rather than strict rules.",
                    "**Standardized loadings** show how strongly each item reflects the factor (≥ .5 is typical for a usable item); ω reliability follows directly from them.",
                    "**Measurement invariance** compares groups: configural (same structure), then metric (equal loadings), then scalar (equal intercepts). Scalar invariance is needed before comparing group means on the scale.",
                ],
                conditions: [
                    "**Theory first:** the model is specified before fitting, not built from the data.",
                    "At least **three items per factor** (a one-factor model with three items is just-identified and can't be tested).",
                    "**Adequate sample size** (often 200+), and items with 5+ response options — otherwise use an ordinal estimator such as WLSMV.",
                    "Missing items handled with **FIML** rather than dropping whole people.",
                ],
                reading: "Brown (2015), *Confirmatory Factor Analysis for Applied Research* (2nd ed.); Hu & Bentler (1999), *Structural Equation Modeling*, 6(1), 1–55; Putnick & Bornstein (2016), *Developmental Review*, 41, 71–90."
            )),
            .terms([
                Term("Latent factor", "An unobserved construct (e.g. mindfulness) inferred from what its items share."),
                Term("Indicator", "An observed item used to measure a latent factor."),
                Term("Factor loading (λ)", "How strongly an item reflects its factor; standardized loadings are correlations between item and factor."),
                Term("CFI / TLI", "Fit compared with a model of uncorrelated items; .95 or higher is good."),
                Term("RMSEA", "Approximation error per degree of freedom; .06 or lower is good."),
                Term("SRMR", "Average residual correlation; .08 or lower is good."),
                Term("Configural invariance", "The same items load on the same factors in every group."),
                Term("Metric invariance", "Loadings are equal across groups, so the factor means the same thing."),
                Term("Scalar invariance", "Item intercepts are also equal, so group means on the factor can be compared."),
                Term("FIML", "Full-information maximum likelihood: uses every observed value instead of dropping incomplete rows."),
            ]),
            .code(CodeSample(
                caption: "A one-factor CFA of the six mindfulness items",
                python: #"""
                # pip install semopy
                import pandas as pd
                import semopy

                survey = pd.read_csv("survey.csv")
                items = [f"mind_{i}" for i in range(1, 7)]
                keyed = survey[items].copy()
                keyed[["mind_3", "mind_5"]] = 6 - keyed[["mind_3", "mind_5"]]   # reverse-key first
                keyed = keyed.dropna()                                           # semopy needs complete rows

                model = semopy.Model("mindful =~ mind_1 + mind_2 + mind_3 + mind_4 + mind_5 + mind_6")
                model.fit(keyed)
                print(model.inspect(std_est=True))    # loadings: the "Est. Std" column of the item ~ mindful rows
                print(semopy.calc_stats(model).T)     # chi2, CFI, TLI, RMSEA, …
                """#,
                r: #"""
                library(tidyverse)
                library(lavaan)

                survey <- read_csv("survey.csv") |>
                  mutate(across(c(mind_3, mind_5), ~ 6 - .x))     # reverse-key first

                model <- 'mindful =~ mind_1 + mind_2 + mind_3 + mind_4 + mind_5 + mind_6'
                fit <- cfa(model, data = survey, missing = "fiml")    # FIML uses every answered item
                summary(fit, standardized = TRUE, fit.measures = TRUE)
                fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr"))
                """#
            )),
            .code(CodeSample(
                caption: "Measurement invariance across urban and rural respondents",
                python: #"""
                # Multi-group CFA and formal invariance tests are far better supported in R's lavaan.
                # A rough Python check: fit the model separately in each region and compare loadings.
                for region in ["urban", "rural"]:
                    rows = survey.loc[keyed.index, "region"] == region
                    m = semopy.Model("mindful =~ mind_1 + mind_2 + mind_3 + mind_4 + mind_5 + mind_6")
                    m.fit(keyed[rows])
                    est = m.inspect(std_est=True)
                    is_loading = (est["op"] == "~") & (est["rval"] == "mindful")
                    print(region, est.loc[is_loading, "Est. Std"].round(2).tolist())
                """#,
                r: #"""
                # Configural: same structure in both regions; metric: equal loadings;
                # scalar: equal loadings and intercepts
                configural <- cfa(model, data = survey, group = "region", missing = "fiml")
                metric     <- cfa(model, data = survey, group = "region", missing = "fiml",
                                  group.equal = "loadings")
                scalar     <- cfa(model, data = survey, group = "region", missing = "fiml",
                                  group.equal = c("loadings", "intercepts"))

                lavTestLRT(configural, metric, scalar)       # each step: does constraining hurt fit?
                sapply(list(configural = configural, metric = metric, scalar = scalar),
                       fitMeasures, fit.measures = c("cfi", "rmsea"))
                """#
            )),
            .keyPoint("Invariance before comparison", "If loadings or intercepts differ between groups, the scale measures something slightly different in each, and a difference in scale means could be a measurement artifact. Test invariance before comparing groups. A drop in CFI of more than .01 between steps is a common warning sign (Cheung & Rensvold, 2002), alongside the likelihood-ratio test."),
            .caution("Don't chase fit with modification indices", "Software suggests extra paths (often correlated errors) that would improve fit. Adding them without a substantive reason turns a confirmatory model into an exploratory one that won't replicate. If you do add any, say so and justify each."),
            .field(.psychology, "Before comparing anxiety across cultures, cross-cultural psychologists test whether the questionnaire is scalar-invariant — otherwise a group difference may reflect how items were translated or understood rather than real differences in anxiety."),
            .exercise(Exercise(
                title: "Loadings and ω",
                prompt: "Fit the one-factor model. Store the six standardized loadings (in item order) and compute McDonald's ω = (Σλ)² / [(Σλ)² + Σ(1 − λ²)].",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    est = model.inspect(std_est=True)
                    loads = est[(est["op"] == "~") & (est["rval"] == "mindful")].set_index("lval")["Est. Std"]
                    loadings = loads[items].to_numpy(dtype=float)
                    omega = loadings.sum() ** 2 / (loadings.sum() ** 2 + (1 - loadings ** 2).sum())
                    print(loadings.round(2), round(omega, 3))
                    """#,
                    r: #"""
                    std <- standardizedSolution(fit) |> filter(op == "=~")
                    loadings <- std$est.std
                    omega <- sum(loadings)^2 / (sum(loadings)^2 + sum(1 - loadings^2))
                    round(c(loadings, omega = omega), 3)
                    """#
                ),
                answer: "All six loadings are strong (roughly .7–.85) and ω is high (around .9) — the reverse-keyed items load just as well once they've been recoded. Fit indices are excellent because the data were generated from exactly this model.",
                selfCheck: SelfCheck(
                    names: "`loadings` (six standardized loadings, mind_1 to mind_6) and `omega`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from sklearn.decomposition import FactorAnalysis
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")[[f"mind_{i}" for i in range(1, 7)]]
                        ref[["mind_3", "mind_5"]] = 6 - ref[["mind_3", "mind_5"]]
                        z = ref.dropna()
                        z = (z - z.mean()) / z.std()
                        # A one-factor maximum-likelihood factor analysis of the standardized items gives the same loadings
                        fa = FactorAnalysis(n_components=1).fit(z)
                        expected = np.abs(fa.components_[0])
                        check("Standardized loadings", np.abs(loadings), expected, tol=0.02,
                              hint="Reverse-key mind_3 and mind_5 before fitting.")
                        lam = np.asarray(loadings, dtype=float)
                        check("ω from your loadings", omega, lam.sum() ** 2 / (lam.sum() ** 2 + (1 - lam ** 2).sum()), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")[paste0("mind_", 1:6)]
                      ref[c("mind_3", "mind_5")] <- 6 - ref[c("mind_3", "mind_5")]
                      # A one-factor maximum-likelihood factor analysis gives (almost exactly) the same loadings
                      expected <- abs(as.vector(factanal(na.omit(ref), factors = 1)$loadings))
                      check("Standardized loadings", abs(loadings), expected, tol = 0.02,
                            hint = "Reverse-key mind_3 and mind_5 before fitting.")
                      check("ω from your loadings", omega, sum(loadings)^2 / (sum(loadings)^2 + sum(1 - loadings^2)),
                            tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Is the scale invariant across regions?",
                prompt: "Run the invariance code. In R, store the likelihood-ratio p-values for configural → metric and metric → scalar. In Python, store each region's six standardized loadings. Does the scale work the same way in both regions?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    loads = {}
                    for region in ["urban", "rural"]:
                        rows = survey.loc[keyed.index, "region"] == region
                        m = semopy.Model("mindful =~ mind_1 + mind_2 + mind_3 + mind_4 + mind_5 + mind_6")
                        m.fit(keyed[rows])
                        est = m.inspect(std_est=True)
                        is_loading = (est["op"] == "~") & (est["rval"] == "mindful")
                        loads[region] = est.loc[is_loading, "Est. Std"].to_numpy(dtype=float)
                    load_urban, load_rural = loads["urban"], loads["rural"]
                    print(load_urban.round(2), load_rural.round(2))
                    """#,
                    r: #"""
                    lrt <- lavTestLRT(configural, metric, scalar)
                    p_metric <- lrt[["Pr(>Chisq)"]][2]
                    p_scalar <- lrt[["Pr(>Chisq)"]][3]
                    c(p_metric, p_scalar)
                    """#
                ),
                answer: "The data were generated the same way in both regions, so the constraints shouldn't hurt fit: both likelihood-ratio tests are usually non-significant and CFI barely moves, and the separately estimated loadings are close. Scalar invariance holds, so comparing mean mindfulness across regions is justified.",
                selfCheck: SelfCheck(
                    names: "in R, `p_metric` and `p_scalar`; in Python, `load_urban` and `load_rural`",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        gap = np.abs(np.asarray(load_urban) - np.asarray(load_rural))
                        print("largest loading difference:", gap.max().round(3))
                        check("Six loadings per region", (len(load_urban), len(load_rural)), (6, 6), tol=0)
                        check("Every loading is above .5 in both regions",
                              bool(np.all(np.r_[load_urban, load_rural] > 0.5)), True,
                              hint="Reverse-key mind_3 and mind_5, and fit each region separately.")
                        check("Loadings differ by less than .15 between regions", bool(gap.max() < 0.15), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lavaan)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref[c("mind_3", "mind_5")] <- 6 - ref[c("mind_3", "mind_5")]
                      m <- 'f =~ mind_1 + mind_2 + mind_3 + mind_4 + mind_5 + mind_6'
                      fits <- lapply(list(NULL, "loadings", c("loadings", "intercepts")), function(eq)
                        cfa(m, data = ref, group = "region", missing = "fiml", group.equal = if (is.null(eq)) "" else eq))
                      # Likelihood-ratio test by hand: Δχ² on Δdf
                      lr_p <- function(a, b) {
                        d <- fitMeasures(b, c("chisq", "df")) - fitMeasures(a, c("chisq", "df"))
                        pchisq(d[["chisq"]], d[["df"]], lower.tail = FALSE)
                      }
                      check("Configural → metric p", p_metric, lr_p(fits[[1]], fits[[2]]), tol = 0.01,
                            hint = "Use FIML and the same reverse-keyed items in every model.")
                      check("Metric → scalar p", p_scalar, lr_p(fits[[2]], fits[[3]]), tol = 0.01)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "How does CFA differ from exploratory factor analysis?",
                options: ["CFA can't use more than one factor", "In CFA you specify which items load on which factor before fitting", "CFA doesn't estimate loadings", "CFA only works with binary items"],
                answer: 1,
                explanation: "CFA tests a pre-specified structure; EFA lets every item load on every factor."
            ),
            Question(
                prompt: "A CFA has CFI = .97, RMSEA = .04, SRMR = .03. The fit is…",
                options: ["Poor", "Good", "Impossible to judge without p < .05", "Too good — overfitting"],
                answer: 1,
                explanation: "All three meet common cutoffs (CFI ≥ .95, RMSEA ≤ .06, SRMR ≤ .08)."
            ),
            Question(
                prompt: "Before comparing mean scale scores across two cultures, which level of invariance do you need?",
                options: ["Configural", "Metric", "Scalar", "None"],
                answer: 2,
                explanation: "Scalar invariance (equal loadings and intercepts) makes mean comparisons meaningful."
            ),
        ]
    )

    // MARK: Longitudinal growth models

    static let growthModels = Lesson(
        id: "growth-models",
        title: "Longitudinal growth models",
        summary: "Modelling change over time with random intercepts and slopes.",
        minutes: 13,
        blocks: [
            .text("When the same people are measured on several occasions, the questions are about **change**: how fast do scores grow on average, do people differ in their growth, and does something (an intervention, a background variable) predict faster growth? A **growth model** is a mixed-effects model with time as a predictor and a random slope for time."),
            .model(ModelExplainer(
                name: "Linear growth model (multilevel)",
                purpose: "Describes each person's trajectory over time with their own intercept and slope, and models how those trajectories vary and what predicts them.",
                equation: "scoreₜᵢ = (β₀ + u₀ᵢ) + (β₁ + u₁ᵢ)·waveₜᵢ + β₂·groupᵢ + β₃·groupᵢ × waveₜᵢ + eₜᵢ",
                steps: [
                    "**Level 1 (occasions):** each person's scores follow their own line over time.",
                    "**Level 2 (people):** intercepts and slopes vary across people around the average line; u₀ᵢ and u₁ᵢ are each person's deviations, and their correlation tells you whether those who start higher also grow faster.",
                    "β₁ is the **average growth rate**. A person-level predictor's interaction with time (β₃) tests whether it changes the growth rate — for a randomized intervention, that's the treatment effect on growth.",
                    "**Time coding** sets what the intercept means: wave = 0 at baseline makes β₂ the group difference at the start; centering time at the last wave makes it the difference at the end.",
                    "People with missed waves still contribute everything they have; estimates are unbiased if the missingness is MAR.",
                ],
                conditions: [
                    "**At least three waves** to estimate individual slopes (more for curved trajectories).",
                    "**A sensible functional form** — plot individual trajectories first; add a quadratic term or piecewise slopes if growth isn't linear.",
                    "**Missing waves at random given the model** (MAR), and enough people for the random-effect variances.",
                ],
                reading: "Singer & Willett (2003), *Applied Longitudinal Data Analysis*, chs. 3–5; Hoffman (2015), *Longitudinal Analysis: Modeling Within-Person Fluctuation and Change*."
            )),
            .terms([
                Term("Trajectory", "A person's pattern of scores over time."),
                Term("Random slope for time", "Lets each person have their own growth rate."),
                Term("Unconditional growth model", "A growth model with only time as a predictor — the starting point for describing change."),
                Term("Time × predictor interaction", "Tests whether a person-level variable predicts the rate of change."),
                Term("Time coding", "Where time = 0 sits; it changes what the intercept and group effects mean, not the fit."),
                Term("Spaghetti plot", "One thin line per person, often with the average trajectory on top."),
            ]),
            .code(CodeSample(
                caption: "Reading scores over five waves, with a randomized intervention",
                python: #"""
                import pandas as pd
                import seaborn as sns
                import matplotlib.pyplot as plt
                import statsmodels.formula.api as smf

                growth = pd.read_csv("growth.csv")
                print(growth.groupby("student").size().value_counts())    # most students have all 5 waves

                # Spaghetti plot: one thin line per student, plus each group's average trajectory
                ax = sns.lineplot(data=growth, x="wave", y="score", units="student", estimator=None,
                                  color="0.85", linewidth=0.5)
                sns.lineplot(data=growth, x="wave", y="score", hue="group", errorbar=None, linewidth=2.5, ax=ax)
                plt.show()

                # 1. Unconditional growth: an average line plus each student's own intercept and slope
                m1 = smf.mixedlm("score ~ wave", data=growth, groups=growth["student"], re_formula="~wave").fit()
                print(m1.summary())

                # 2. Does the intervention change the growth rate? The wave × group term is the test
                m2 = smf.mixedlm("score ~ wave * C(group, Treatment('control'))", data=growth,
                                 groups=growth["student"], re_formula="~wave").fit()
                print(m2.summary())
                """#,
                r: #"""
                library(tidyverse)
                library(lmerTest)

                growth <- read_csv("growth.csv") |>
                  mutate(group = factor(group, levels = c("control", "intervention")))
                count(growth, student) |> count(n)          # most students have all 5 waves

                ggplot(growth, aes(wave, score)) +
                  geom_line(aes(group = student), colour = "grey85", linewidth = 0.3) +
                  stat_summary(aes(colour = group), fun = mean, geom = "line", linewidth = 1.2) +
                  theme_classic()

                # 1. Unconditional growth: an average line plus each student's own intercept and slope
                m1 <- lmer(score ~ wave + (1 + wave | student), data = growth)
                summary(m1)

                # 2. Does the intervention change the growth rate? The wave × group term is the test
                m2 <- lmer(score ~ wave * group + (1 + wave | student), data = growth)
                summary(m2)
                """#
            )),
            .keyPoint("Use every wave you have", "A repeated-measures ANOVA drops anyone with a single missed wave. A growth model keeps all of their observed waves, which is both more powerful and less biased when people with missed waves differ from those without."),
            .caution("Plot before you model", "A straight-line growth model fits a straight line whether or not change is linear. Look at a sample of individual trajectories and the average curve first; add `wave²`, or separate slopes for different phases, if the plot calls for it."),
            .field(.linguistics, "Second-language acquisition studies follow learners over months or years and ask whether, say, immersion predicts faster growth in vocabulary or accuracy — a time × predictor interaction in a growth model."),
            .exercise(Exercise(
                title: "Does the intervention speed growth?",
                prompt: "From model 2, store the control group's growth per wave and the wave × group interaction. How much faster does the intervention group grow?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    term = "wave:C(group, Treatment('control'))[T.intervention]"
                    b_wave, b_growth = m2.fe_params["wave"], m2.fe_params[term]
                    print(round(b_wave, 2), round(b_growth, 2))
                    """#,
                    r: #"""
                    b_wave   <- fixef(m2)[["wave"]]
                    b_growth <- fixef(m2)[["wave:groupintervention"]]
                    round(c(b_wave, b_growth), 2)
                    """#
                ),
                answer: "Control students gain about 5 points per wave, and the intervention group roughly 1.5–2 points more per wave (the built-in truth is 2; sampling noise is about ±0.3). Over four waves that adds up to a gap of roughly 6–8 points.",
                selfCheck: SelfCheck(
                    names: "`b_wave` (control growth per wave) and `b_growth` (the wave × group interaction)",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("growth.csv")
                        ref["intervention"] = (ref["group"] == "intervention").astype(int)
                        fit = smf.mixedlm("score ~ wave * intervention", data=ref, groups=ref["student"],
                                          re_formula="~wave").fit()
                        check("Control growth per wave", b_wave, fit.fe_params["wave"], tol=0.01,
                              hint="Control should be the reference group.")
                        check("Extra growth per wave (wave × group)", b_growth, fit.fe_params["wave:intervention"], tol=0.01,
                              hint="Include a random slope for wave.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("growth.csv")
                      ref$intervention <- as.integer(ref$group == "intervention")
                      fit <- lmer(score ~ wave * intervention + (1 + wave | student), data = ref)
                      check("Control growth per wave", b_wave, fixef(fit)[["wave"]], tol = 0.01,
                            hint = "Control should be the reference group.")
                      check("Extra growth per wave (wave × group)", b_growth, fixef(fit)[["wave:intervention"]], tol = 0.01,
                            hint = "Include a random slope for wave.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Move time zero to the last wave",
                prompt: "Create `wave_end = wave − 4` and refit model 2 with it. Store the new group coefficient: the group difference at the **final** wave. How does it relate to model 2's coefficients?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    growth["wave_end"] = growth["wave"] - 4
                    m_end = smf.mixedlm("score ~ wave_end * C(group, Treatment('control'))", data=growth,
                                        groups=growth["student"], re_formula="~wave_end").fit()
                    b_group_end = m_end.fe_params["C(group, Treatment('control'))[T.intervention]"]
                    print(round(b_group_end, 2))
                    """#,
                    r: #"""
                    growth <- growth |> mutate(wave_end = wave - 4)
                    m_end <- lmer(score ~ wave_end * group + (1 + wave_end | student), data = growth)
                    b_group_end <- fixef(m_end)[["groupintervention"]]
                    round(b_group_end, 2)
                    """#
                ),
                answer: "The group difference at the last wave equals the baseline difference plus 4 × the interaction — the same model, reparameterized. Near zero at baseline (the groups were randomized), it grows to roughly 6–8 points by wave 4.",
                selfCheck: SelfCheck(
                    names: "`b_group_end`",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Recentering time doesn't change the model, so: end difference = start difference + 4 × slope difference
                        ref = pd.read_csv("growth.csv")
                        ref["intervention"] = (ref["group"] == "intervention").astype(int)
                        fit = smf.mixedlm("score ~ wave * intervention", data=ref, groups=ref["student"],
                                          re_formula="~wave").fit()
                        expected = fit.fe_params["intervention"] + 4 * fit.fe_params["wave:intervention"]
                        check("Group difference at the last wave", b_group_end, expected, tol=0.01,
                              hint="wave_end = wave − 4, used in both the fixed and the random part.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      # Recentering time doesn't change the model, so: end difference = start difference + 4 × slope difference
                      ref <- read.csv("growth.csv")
                      ref$intervention <- as.integer(ref$group == "intervention")
                      b <- fixef(lmer(score ~ wave * intervention + (1 + wave | student), data = ref))
                      check("Group difference at the last wave", b_group_end, b[["intervention"]] + 4 * b[["wave:intervention"]],
                            tol = 0.01, hint = "wave_end = wave − 4, used in both the fixed and the random part.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "In a growth model, a random slope for time means…",
                options: ["Time is measured with error", "Each person can have their own rate of change", "The average slope is zero", "Time is categorical"],
                answer: 1,
                explanation: "Random slopes let growth rates vary across people."
            ),
            Question(
                prompt: "In a randomized study, which term tests whether an intervention changes the rate of growth?",
                options: ["The intercept", "The main effect of group", "The time × group interaction", "The residual variance"],
                answer: 2,
                explanation: "The interaction is the difference in slopes between groups."
            ),
            Question(
                prompt: "A student missed one of five waves. In a multilevel growth model, that student…",
                options: ["Must be dropped", "Contributes their four observed waves", "Needs every wave imputed first", "Biases the results"],
                answer: 1,
                explanation: "Mixed models use all available observations."
            ),
        ]
    )
}

// MARK: - Unit 9 · Count outcomes

extension Curriculum {
    static let countModels = Lesson(
        id: "count-models",
        title: "Count outcomes: Poisson & negative binomial",
        summary: "Rates, offsets for exposure, and overdispersion.",
        minutes: 13,
        blocks: [
            .text("Counts — filler words in an interview, arrests in a neighbourhood, errors in an essay — are whole numbers starting at 0, usually right-skewed, with variance that grows with the mean. Linear regression can predict negative counts and gets the uncertainty wrong. **Poisson** and **negative binomial** regression model counts directly, on the log scale."),
            .model(ModelExplainer(
                name: "Poisson and negative binomial regression",
                purpose: "Models the expected count (or rate) as a function of predictors, with coefficients that multiply the rate.",
                equation: "log(µᵢ) = log(minutesᵢ) + b₀ + b₁·evaluatedᵢ + b₂·L2ᵢ + b₃·ageᵢ        Poisson: Var = µ    NB: Var = µ + µ² / θ",
                steps: [
                    "The model predicts the **log** of the expected count, so predictions are always positive and effects multiply: exp(b) is a **rate ratio** (also called an incidence-rate ratio, IRR).",
                    "When people are observed for different lengths of time (or texts have different lengths), include log(exposure) as an **offset** — a term with its coefficient fixed at 1 — so the model describes rates per unit of exposure.",
                    "**Poisson** regression assumes the variance equals the mean. Check it: the Pearson χ² divided by the residual df should be near 1.",
                    "Values well above 1 mean **overdispersion** — people differ more than Poisson allows — and Poisson standard errors are too small. **Negative binomial** regression adds a dispersion parameter and fixes this.",
                    "Many structural zeros (people who *never* do the behaviour) call for a zero-inflated or hurdle model.",
                ],
                conditions: [
                    "**Non-negative integer outcomes**, with exposure (time, words, population) handled by an offset.",
                    "**Independent observations** — add random effects (`glmer(family = poisson)`, `glmmTMB`) for clustered counts.",
                    "**The right variance model:** check dispersion, and compare Poisson with negative binomial.",
                ],
                reading: "Agresti (2007), *An Introduction to Categorical Data Analysis* (2nd ed.), §3.3–3.4; Coxe, West & Aiken (2009), *Journal of Personality Assessment*, 91(2), 121–136; Winter & Bürkner (2021), *Language and Linguistics Compass*, 15(11), e12439."
            )),
            .terms([
                Term("Count outcome", "A non-negative whole number of events."),
                Term("Rate ratio (IRR)", "exp(b): how many times higher the expected rate is per one-unit increase in the predictor."),
                Term("Offset / exposure", "log(exposure) entered with a fixed coefficient of 1, so the model describes rates (per minute, per 1,000 words)."),
                Term("Overdispersion", "More variance than the Poisson model allows; it makes Poisson SEs too small."),
                Term("Negative binomial regression", "A count model with an extra dispersion parameter for overdispersed counts."),
                Term("Zero inflation", "More zeros than a count model predicts, often from a subgroup that never produces the behaviour."),
            ]),
            .code(CodeSample(
                caption: "Filler words in interviews of different lengths",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.api as sm
                import statsmodels.formula.api as smf

                fillers = pd.read_csv("fillers.csv")
                fillers["rate"] = fillers["fillers"] / fillers["minutes"]
                print(fillers.groupby(["condition", "l2"])["rate"].mean().round(2))    # fillers per minute
                print("mean:", round(fillers["fillers"].mean(), 1), " variance:", round(fillers["fillers"].var(), 1))

                # Poisson regression with an offset: log(expected count) = log(minutes) + b0 + b1·x1 + …
                formula = "fillers ~ C(condition, Treatment('relaxed')) + l2 + age"
                pois = smf.glm(formula, data=fillers, family=sm.families.Poisson(),
                               offset=np.log(fillers["minutes"])).fit()
                print(pois.summary())
                print("dispersion:", round(pois.pearson_chi2 / pois.df_resid, 2))   # ≈ 1 if Poisson fits

                # Negative binomial: the same mean structure, plus extra variance
                nb = smf.negativebinomial(formula, data=fillers, offset=np.log(fillers["minutes"])).fit(disp=False)
                print(nb.summary())
                print(np.exp(nb.params).round(3))     # rate ratios (ignore the last row, alpha)
                """#,
                r: #"""
                library(MASS)        # glm.nb(); load before the tidyverse so dplyr's select() wins
                library(tidyverse)

                fillers <- read_csv("fillers.csv") |>
                  mutate(condition = factor(condition, levels = c("relaxed", "evaluated")))
                fillers |> group_by(condition, l2) |> summarise(rate = mean(fillers / minutes), .groups = "drop")
                c(mean = mean(fillers$fillers), variance = var(fillers$fillers))

                # Poisson regression with an offset
                pois <- glm(fillers ~ condition + l2 + age + offset(log(minutes)), data = fillers, family = poisson)
                summary(pois)
                sum(residuals(pois, type = "pearson")^2) / df.residual(pois)   # dispersion: ≈ 1 if Poisson fits

                # Negative binomial: the same mean structure, plus extra variance
                nb <- glm.nb(fillers ~ condition + l2 + age + offset(log(minutes)), data = fillers)
                summary(nb)
                exp(coef(nb))        # rate ratios
                """#
            )),
            .keyPoint("Report rate ratios", "“Speakers who believed they were being evaluated produced 1.4 times as many fillers per minute (IRR = 1.41, 95% CI [1.21, 1.64]).” Rate ratios are multiplicative: two predictors with IRRs of 1.4 and 1.6 together predict 1.4 × 1.6 ≈ 2.2 times the rate."),
            .caution("Don't model counts as rates with linear regression", "Dividing counts by exposure and running a linear regression gives equal weight to a 1-minute and a 15-minute interview, and can predict negative rates. The offset does this properly."),
            .field(.linguistics, "Corpus frequencies are counts with exposure: how often a construction occurs per text depends on text length. Poisson and negative binomial models with log(word count) offsets are standard tools."),
            .field(.sociology, "Counts of events per neighbourhood (crimes, evictions, protests) use log(population) as the offset, and are almost always overdispersed."),
            .exercise(Exercise(
                title: "Rate ratios from the negative binomial model",
                prompt: "From the negative binomial model, store the rate ratios for being evaluated and for speaking a second language. Interpret them.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    irr_eval = np.exp(nb.params["C(condition, Treatment('relaxed'))[T.evaluated]"])
                    irr_l2 = np.exp(nb.params["l2"])
                    print(round(irr_eval, 2), round(irr_l2, 2))
                    """#,
                    r: #"""
                    irr_eval <- exp(coef(nb)[["conditionevaluated"]])
                    irr_l2   <- exp(coef(nb)[["l2"]])
                    round(c(irr_eval, irr_l2), 2)
                    """#
                ),
                answer: "Being evaluated multiplies the filler rate by roughly 1.2–1.4, and speaking a second language by roughly 1.5–1.7 — close to the built-in truths of 1.4 and 1.6 (estimates vary from sample to sample; the 95% CIs should cover the truths). Both are rates per minute, thanks to the offset.",
                selfCheck: SelfCheck(
                    names: "`irr_eval` and `irr_l2`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("fillers.csv")
                        X = sm.add_constant(np.column_stack([(ref["condition"] == "evaluated").astype(float), ref["l2"], ref["age"]]))
                        fit = sm.NegativeBinomial(ref["fillers"], X, offset=np.log(ref["minutes"])).fit(disp=False)
                        check("Rate ratio, evaluated vs. relaxed", irr_eval, np.exp(fit.params.iloc[1]), tol=0.005,
                              hint="Include log(minutes) as an offset, and exponentiate the coefficient.")
                        check("Rate ratio, second-language speakers", irr_l2, np.exp(fit.params.iloc[2]), tol=0.005)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("fillers.csv")
                      ref$evaluated <- as.integer(ref$condition == "evaluated")
                      fit <- MASS::glm.nb(fillers ~ evaluated + l2 + age + offset(log(minutes)), data = ref)
                      check("Rate ratio, evaluated vs. relaxed", irr_eval, exp(coef(fit)[["evaluated"]]), tol = 0.005,
                            hint = "Include offset(log(minutes)), and exponentiate the coefficient.")
                      check("Rate ratio, second-language speakers", irr_l2, exp(coef(fit)[["l2"]]), tol = 0.005)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Diagnose overdispersion",
                prompt: "Store the Poisson model's dispersion statistic (Pearson χ² / residual df). Is a Poisson model adequate?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    dispersion = pois.pearson_chi2 / pois.df_resid
                    print(round(dispersion, 2))
                    """#,
                    r: #"""
                    dispersion <- sum(residuals(pois, type = "pearson")^2) / df.residual(pois)
                    round(dispersion, 2)
                    """#
                ),
                answer: "The dispersion is well above 1 (around 4–6), so the Poisson SEs are too small — some speakers simply say “um” much more than others. The negative binomial model is the defensible choice; its coefficients are similar but its CIs are wider.",
                selfCheck: SelfCheck(
                    names: "`dispersion`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("fillers.csv")
                        X = sm.add_constant(np.column_stack([(ref["condition"] == "evaluated").astype(float), ref["l2"], ref["age"]]))
                        mu = sm.GLM(ref["fillers"], X, family=sm.families.Poisson(), offset=np.log(ref["minutes"])).fit().fittedvalues
                        # Pearson χ² = Σ (y − µ)² / µ, divided by n − (number of coefficients)
                        expected = (((ref["fillers"] - mu) ** 2) / mu).sum() / (len(ref) - X.shape[1])
                        check("Pearson dispersion", dispersion, expected, tol=0.002,
                              hint="Fit the Poisson model with the offset, then divide Pearson χ² by the residual df.")
                        check("Overdispersed (well above 1)", dispersion > 1.5, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("fillers.csv")
                      mu <- fitted(glm(fillers ~ condition + l2 + age + offset(log(minutes)), data = ref, family = poisson))
                      # Pearson χ² = Σ (y − µ)² / µ, divided by n − (number of coefficients)
                      check("Pearson dispersion", dispersion, sum((ref$fillers - mu)^2 / mu) / (nrow(ref) - 4), tol = 0.002,
                            hint = "Fit the Poisson model with the offset, then divide Pearson χ² by the residual df.")
                      check("Overdispersed (well above 1)", dispersion > 1.5, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A Poisson coefficient for `evaluated` is 0.34. The rate ratio is about…",
                options: ["0.34", "1.40", "0.71", "2.19"],
                answer: 1,
                explanation: "exp(0.34) ≈ 1.40: being evaluated multiplies the rate by 1.4."
            ),
            Question(
                prompt: "Why include log(minutes) as an offset?",
                options: ["To make the counts normal", "So the model describes rates per minute when interviews differ in length", "To remove outliers", "Poisson models require it"],
                answer: 1,
                explanation: "The offset accounts for exposure."
            ),
            Question(
                prompt: "A Poisson model's Pearson χ² / df is 3.2. What should you do?",
                options: ["Nothing — it's fine", "Switch to a negative binomial (or quasi-Poisson) model", "Use linear regression", "Remove the offset"],
                answer: 1,
                explanation: "The counts are overdispersed, so Poisson SEs are too small."
            ),
        ]
    )
}

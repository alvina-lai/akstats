import Foundation

// MARK: - Unit 8 · Moderation & mediation
// (Scale scoring and comparing predictors also live in this file but belong to Units 7 and 5.)

extension Curriculum {
    static let moderationMediation = Unit(
        id: "moderation-mediation", number: 8, title: "Moderation & mediation", level: .advanced,
        summary: "When an effect depends on a third variable, and when it runs through one.",
        symbol: "arrow.triangle.branch",
        lessons: [moderation, mediation, moderatedMediation]
    )

    static let scaleScoring = Lesson(
        id: "scale-scoring",
        title: "Scoring multi-item scales",
        summary: "Reverse-keying, composite scores, missing items, and reliability.",
        minutes: 10,
        blocks: [
            .text("Questionnaires measure one construct with several items. Before any analysis you turn those items into a single **composite score** per person — usually the mean of the items — after recoding reverse-worded items so that a high number always means *more* of the construct."),
            .model(ModelExplainer(
                name: "Composite scores and internal consistency",
                purpose: "Combines several items that measure the same construct into one score, and estimates how much of that score reflects the construct rather than item-specific noise.",
                equation: "score = mean of keyed items        α = [k / (k − 1)] · [1 − Σ sᵢ² / s²_total]",
                steps: [
                    "**Key** every item so that a high value always means more of the construct (reverse-keyed items become max + min − x).",
                    "Average each person's answered items, if they answered enough of them (the prorating rule).",
                    "**Cronbach's α** compares the sum of the item variances with the variance of the total: if items share a lot of variance, the total varies much more than the items do separately, and α approaches 1.",
                    "**McDonald's ω** estimates reliability from a factor model and doesn't assume every item is equally strong.",
                    "**Item–rest correlations** flag items that don't fit — often a reverse-keyed item that wasn't recoded.",
                ],
                conditions: [
                    "Items measure **one construct** (check with factor analysis).",
                    "Items are **correctly keyed** in the same direction.",
                    "For α specifically, items contribute roughly **equally** (tau-equivalence); ω relaxes this.",
                ],
                reading: "Revelle & Condon (2019), *Psychological Assessment*, 31(12), 1395–1411; McNeish (2018), *Psychological Methods*, 23(3), 412–433."
            )),
            .terms([
                Term("Item", "One question on a scale, often rated 1–5 or 1–7."),
                Term("Reverse-keyed item", "Worded in the opposite direction (“I often act on autopilot” on a mindfulness scale). Recode as (max + min) − x."),
                Term("Composite score", "The mean (or sum) of a person's item responses after keying."),
                Term("Prorating", "Averaging the items a person *did* answer, as long as they answered enough (e.g. ≥ 80%)."),
                Term("Item–rest correlation", "How well one item correlates with the average of the others. Low or negative values flag a problem item."),
            ]),
            .code(CodeSample(
                caption: "Score the mindfulness items in survey.csv",
                python: #"""
                import pandas as pd
                import pingouin as pg

                survey = pd.read_csv("survey.csv")
                items = [f"mind_{i}" for i in range(1, 7)]

                # Reverse-key items 3 and 5 on a 1–5 scale: 6 − x
                keyed = survey[items].copy()
                keyed[["mind_3", "mind_5"]] = 6 - keyed[["mind_3", "mind_5"]]

                # Composite = mean of answered items, if at least 5 of 6 were answered
                answered = keyed.notna().sum(axis=1)
                survey["mind_score"] = keyed.mean(axis=1).where(answered >= 5)

                # Internal consistency
                alpha, ci = pg.cronbach_alpha(data=keyed)
                print(f"alpha = {alpha:.2f}, 95% CI {ci}")

                # Item–rest correlations
                for col in items:
                    rest = keyed.drop(columns=col).mean(axis=1)
                    print(col, round(keyed[col].corr(rest), 2))
                """#,
                r: #"""
                library(tidyverse)
                library(psych)

                survey <- read_csv("survey.csv")

                # Reverse-key items 3 and 5 on a 1–5 scale: 6 − x
                keyed <- survey |>
                  select(mind_1:mind_6) |>
                  mutate(across(c(mind_3, mind_5), ~ 6 - .x))

                # Composite = mean of answered items, if at least 5 of 6 were answered
                survey <- survey |>
                  mutate(mind_score = if_else(rowSums(!is.na(keyed)) >= 5,
                                              rowMeans(keyed, na.rm = TRUE), NA_real_))

                # Alpha, plus "r.drop" = item–rest correlation for each item
                psych::alpha(keyed)
                omega(keyed, nfactors = 1)   # McDonald's omega
                """#
            )),
            .keyPoint("Report reliability for your sample", "Published reliabilities don't transfer automatically. Report α (or ω) computed on *your* data for every scale, and note any items you dropped and why."),
            .caution("Unreliable scales weaken interactions", "Measurement error in two predictors compounds in their product. An interaction between two scales with reliabilities of .80 and .85 has a reliability of roughly their product (≈ .68) when the two are uncorrelated (Busemeyer & Jones, 1983), which quietly reduces power for moderation tests."),
            .exercise(Exercise(
                title: "Check your scoring",
                prompt: "The generator saved a precomputed `mindfulness` column. Confirm your `mind_score` matches it.",
                hint: "Take the absolute difference between the two columns and look at its maximum.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    diff = (survey["mind_score"] - survey["mindfulness"]).abs()
                    print(diff.max())
                    """#,
                    r: #"""
                    max(abs(survey$mind_score - survey$mindfulness), na.rm = TRUE)
                    """#
                ),
                answer: "The maximum difference is below 0.001 — only rounding. If it's larger, check that items 3 and 5 were reverse-keyed.",
                selfCheck: SelfCheck(
                    names: "a `mind_score` column in `survey`",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        check("Same people have a score (and the same people are missing one)",
                              survey["mind_score"].isna().to_numpy(), survey["mindfulness"].isna().to_numpy(), tol=0,
                              hint="Require at least 5 of the 6 items.")
                        diff = (survey["mind_score"] - survey["mindfulness"]).abs().max()
                        check("Largest difference from the precomputed score is under 0.001", diff < 0.001, True,
                              hint="Reverse-key items 3 and 5 as 6 − x before averaging.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      check("Same people have a score (and the same people are missing one)",
                            is.na(survey$mind_score), is.na(survey$mindfulness),
                            hint = "Require at least 5 of the 6 items.")
                      diff <- max(abs(survey$mind_score - survey$mindfulness), na.rm = TRUE)
                      check("Largest difference from the precomputed score is under 0.001", diff < 0.001, TRUE,
                            hint = "Reverse-key items 3 and 5 as 6 − x before averaging.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Forget to reverse-key",
                prompt: "Compute α on the **raw** items (no reverse-keying). What happens to α and to the item–rest correlations of items 3 and 5?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    raw = survey[items]
                    alpha_raw = pg.cronbach_alpha(data=raw)[0]
                    ir_raw = [raw[col].corr(raw.drop(columns=col).mean(axis=1)) for col in ["mind_3", "mind_5"]]
                    print(round(alpha_raw, 2), np.round(ir_raw, 2))
                    """#,
                    r: #"""
                    raw <- survey |> select(mind_1:mind_6)
                    alpha_raw <- psych::alpha(raw)$total$raw_alpha   # psych warns that some items correlate negatively
                    ir_raw <- sapply(c("mind_3", "mind_5"), function(col) {
                      cor(raw[[col]], rowMeans(raw[setdiff(names(raw), col)], na.rm = TRUE), use = "complete.obs")
                    })
                    round(c(alpha = alpha_raw, ir_raw), 2)
                    """#
                ),
                answer: "α drops sharply, and items 3 and 5 have **negative** item–rest correlations. A negative item–rest correlation almost always means a reverse-keyed item wasn't recoded.",
                selfCheck: SelfCheck(
                    names: "`alpha_raw` (α of the un-keyed items) and `ir_raw` (item–rest correlations of `mind_3` and `mind_5`)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        raw_ref = pd.read_csv("survey.csv")[[f"mind_{i}" for i in range(1, 7)]]
                        # α = k / (k − 1) · (1 − Σ item variances / variance of the total), from the covariance matrix
                        C = raw_ref.cov().to_numpy()
                        k = C.shape[0]
                        check("α on the raw items", alpha_raw, k / (k - 1) * (1 - np.trace(C) / C.sum()), tol=0.005,
                              hint="Use the items exactly as stored — no reverse-keying this time.")
                        rest = {c: raw_ref.drop(columns=c).mean(axis=1) for c in ["mind_3", "mind_5"]}
                        check("Item–rest r for mind_3 and mind_5", ir_raw,
                              [raw_ref[c].corr(rest[c]) for c in ["mind_3", "mind_5"]], tol=0.005)
                        check("Both item–rest correlations are negative", bool(np.all(np.asarray(ir_raw) < 0)), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      raw_ref <- read.csv("survey.csv")[paste0("mind_", 1:6)]
                      # α = k / (k − 1) · (1 − Σ item variances / variance of the total), from the covariance matrix
                      C <- cov(raw_ref, use = "pairwise.complete.obs")
                      k <- ncol(C)
                      check("α on the raw items", alpha_raw, k / (k - 1) * (1 - sum(diag(C)) / sum(C)), tol = 0.005,
                            hint = "Use the items exactly as stored — no reverse-keying this time.")
                      expected_ir <- sapply(c("mind_3", "mind_5"), function(col) {
                        cor(raw_ref[[col]], rowMeans(raw_ref[setdiff(names(raw_ref), col)], na.rm = TRUE),
                            use = "complete.obs")
                      })
                      check("Item–rest r for mind_3 and mind_5", ir_raw, expected_ir, tol = 0.005)
                      check("Both item–rest correlations are negative", all(ir_raw < 0), TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Missing-data rule",
                prompt: "How many participants answered fewer than 5 items and therefore have no score? How would the count change with a stricter rule (all 6 items required)?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    n_lt5, n_lt6 = (answered < 5).sum(), (answered < 6).sum()
                    print(n_lt5, n_lt6)
                    """#,
                    r: #"""
                    n_answered <- rowSums(!is.na(keyed))
                    n_lt5 <- sum(n_answered < 5)
                    n_lt6 <- sum(n_answered < 6)
                    c(n_lt5, n_lt6)
                    """#
                ),
                answer: "Only a few participants fall below 5 items, but requiring all 6 loses many more (around 15–20% of the sample). Prorating rules trade completeness against sample size — decide yours in advance.",
                selfCheck: SelfCheck(
                    names: "`n_lt5` and `n_lt6` — how many people answered fewer than 5, and fewer than 6, items",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        n_items = pd.read_csv("survey.csv")[[f"mind_{i}" for i in range(1, 7)]].notna().sum(axis=1)
                        check("Fewer than 5 items answered", n_lt5, (n_items < 5).sum(), tol=0)
                        check("Fewer than 6 items answered", n_lt6, (n_items < 6).sum(), tol=0,
                              hint="Count people missing at least one item.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      n_items <- rowSums(!is.na(read.csv("survey.csv")[paste0("mind_", 1:6)]))
                      check("Fewer than 5 items answered", n_lt5, sum(n_items < 5), tol = 0)
                      check("Fewer than 6 items answered", n_lt6, sum(n_items < 6), tol = 0,
                            hint = "Count people missing at least one item.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "On a 1–7 scale, a reverse-keyed response of 2 becomes…",
                options: ["5", "6", "−2", "2"],
                answer: 1,
                explanation: "(max + min) − x = 8 − 2 = 6."
            ),
            Question(
                prompt: "An item has an item–rest correlation of −.35. The most likely explanation?",
                options: ["It's the best item", "It wasn't reverse-keyed", "The sample is too large", "α is too high"],
                answer: 1,
                explanation: "Negative item–rest correlations typically signal a reverse-worded item that's still on the original direction."
            ),
        ]
    )

    static let comparingPredictors = Lesson(
        id: "comparing-predictors",
        title: "Comparing correlated predictors",
        summary: "Standardized coefficients, unique variance, and multicollinearity.",
        minutes: 11,
        blocks: [
            .text("A common question: *which of two related predictors matters more?* Answer it with three pieces of evidence: each predictor's **standardized coefficient** (β) when both are in the model, the **unique variance** each adds beyond the other (ΔR²), and a **collinearity check** to see whether they can be separated at all."),
            .model(ModelExplainer(
                name: "Standardized coefficients and unique variance",
                purpose: "Puts predictors on a common scale and separates the variance each one explains on its own from the variance it shares with the others.",
                equation: "β = b · (s_x / s_y)        ΔR²ⱼ = R²(all) − R²(all except xⱼ)        VIFⱼ = 1 / (1 − R²ⱼ)",
                steps: [
                    "**Standardize** the outcome and predictors (z-scores) and refit: each β is the SD change in y per SD of the predictor, holding the others constant.",
                    "**Unique variance:** fit the model with and without a predictor; the drop in R² is what only that predictor explains. An F-test on the change tells you whether it's significant.",
                    "**Shared variance** is explained by two predictors together but can't be credited to either one — it's why ΔR² values usually sum to less than the total R².",
                    "**VIF:** regress each predictor on the others; R²ⱼ near 1 means the predictor is nearly redundant, inflating its standard error by √VIF.",
                ],
                conditions: [
                    "All the conditions of multiple regression.",
                    "**Identical cases** in every model you compare (drop incomplete rows first).",
                    "**Comparable reliability** of the predictors — a noisier measure will look less important than it is.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.1 (collinearity and multiple regression); Johnson & LeBreton (2004), *Organizational Research Methods*, 7(3), 238–257 (relative importance)."
            )),
            .terms([
                Term("Standardized coefficient (β)", "The coefficient after converting variables to z-scores: SD change in the outcome per SD change in the predictor."),
                Term("Covariate", "A variable held constant (“controlled for”) so the predictor's coefficient is net of it."),
                Term("Hierarchical regression", "Adding predictors in planned steps and testing the R² change at each step."),
                Term("ΔR²", "Increase in variance explained when a predictor is added — its unique contribution."),
                Term("Multicollinearity", "Predictors so correlated that the model can't tell their effects apart; standard errors balloon."),
                Term("VIF", "Variance inflation factor. 1 = no collinearity; values above ~5–10 are a warning."),
            ]),
            .code(CodeSample(
                caption: "Which predicts rumination better: social media use or phone checking?",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf
                from statsmodels.stats.anova import anova_lm
                from statsmodels.stats.outliers_influence import variance_inflation_factor

                survey = pd.read_csv("survey.csv")
                covs = "age + education + C(region)"

                # z-score continuous variables so coefficients are β
                z = survey.copy()
                for col in ["rumination", "social_media", "phone_checking", "age", "education"]:
                    z[col] = (z[col] - z[col].mean()) / z[col].std()

                m_sm   = smf.ols(f"rumination ~ social_media + {covs}", data=z).fit()
                m_pc   = smf.ols(f"rumination ~ phone_checking + {covs}", data=z).fit()
                m_both = smf.ols(f"rumination ~ social_media + phone_checking + {covs}", data=z).fit()

                print(m_both.params[["social_media", "phone_checking"]])

                # Unique contributions (each added last) with F tests
                print("ΔR² social_media:", m_both.rsquared - m_pc.rsquared)
                print(anova_lm(m_pc, m_both))
                print("ΔR² phone_checking:", m_both.rsquared - m_sm.rsquared)
                print(anova_lm(m_sm, m_both))

                # Collinearity
                print("r =", survey["social_media"].corr(survey["phone_checking"]))
                X = m_both.model.exog
                for i, name in enumerate(m_both.model.exog_names):
                    if name != "Intercept":
                        print(name, round(variance_inflation_factor(X, i), 2))
                """#,
                r: #"""
                library(tidyverse)
                library(car)

                survey <- read_csv("survey.csv")

                # z-score continuous variables so coefficients are β
                z <- survey |>
                  mutate(across(c(rumination, social_media, phone_checking, age, education),
                                ~ as.numeric(scale(.x))))

                m_sm   <- lm(rumination ~ social_media + age + education + region, data = z)
                m_pc   <- lm(rumination ~ phone_checking + age + education + region, data = z)
                m_both <- lm(rumination ~ social_media + phone_checking + age + education + region, data = z)

                summary(m_both)

                # Unique contributions (each added last) with F tests
                summary(m_both)$r.squared - summary(m_pc)$r.squared
                anova(m_pc, m_both)
                summary(m_both)$r.squared - summary(m_sm)$r.squared
                anova(m_sm, m_both)

                # Collinearity
                cor(survey$social_media, survey$phone_checking)
                vif(m_both)
                """#
            )),
            .keyPoint("Decide how you'll judge “more important”", "β, unique ΔR², and dominance analysis can rank predictors differently. Choose the criterion before looking at the results, and remember that with very highly correlated predictors (VIFs well above 5–10), no criterion can reliably separate their effects."),
            .caution("Same rows in every model", "Nested-model comparisons are only valid on identical cases. If one predictor has missing values, drop incomplete rows *before* fitting all models, or the ΔR² compares different samples."),
            .exercise(Exercise(
                title: "Break the model",
                prompt: "Create a near-duplicate predictor `dup = social_media + tiny noise` and add it to `m_both`. What happens to the VIFs and the standard errors?",
                hint: "Use noise with SD 0.05 so `dup` correlates above .99 with `social_media`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    z["dup"] = z["social_media"] + np.random.default_rng(1).normal(0, 0.05, len(z))
                    m_dup = smf.ols(f"rumination ~ social_media + dup + {covs}", data=z).fit()
                    se_dup = m_dup.bse["social_media"]
                    vif_dup = variance_inflation_factor(m_dup.model.exog, m_dup.model.exog_names.index("social_media"))
                    print(m_dup.bse[["social_media", "dup"]], vif_dup)
                    """#,
                    r: #"""
                    set.seed(1)
                    z$dup <- z$social_media + rnorm(nrow(z), sd = 0.05)
                    m_dup <- lm(rumination ~ social_media + dup + age + education + region, data = z)
                    se_dup <- coef(summary(m_dup))["social_media", "Std. Error"]
                    vif_dup <- vif(m_dup)[["social_media"]]
                    summary(m_dup)
                    vif(m_dup)
                    """#
                ),
                answer: "VIFs jump into the hundreds and the standard errors explode. The two coefficients may even flip sign — the model can't decide how to split the shared effect.",
                selfCheck: SelfCheck(
                    names: "`se_dup` (the SE of `social_media` with `dup` added) and `vif_dup` (its VIF)",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        for col in ["rumination", "social_media", "phone_checking", "age", "education"]:
                            ref[col] = (ref[col] - ref[col].mean()) / ref[col].std()
                        se_before = smf.ols("rumination ~ social_media + phone_checking + age + education + C(region)",
                                            data=ref).fit().bse["social_media"]
                        print(f"SE before: {se_before:.3f}, with dup: {se_dup:.3f}, VIF: {vif_dup:.0f}")
                        check("VIF for social_media is in the hundreds", vif_dup > 100, True,
                              hint="dup should be social_media plus noise with SD 0.05 (on the z-score scale).")
                        check("Its SE is at least 5× larger than in m_both", se_dup > 5 * se_before, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      for (col in c("rumination", "social_media", "phone_checking", "age", "education")) {
                        ref[[col]] <- as.numeric(scale(ref[[col]]))
                      }
                      se_before <- coef(summary(lm(rumination ~ social_media + phone_checking + age + education + region,
                                                   data = ref)))["social_media", "Std. Error"]
                      cat(sprintf("SE before: %.3f, with dup: %.3f, VIF: %.0f\n", se_before, se_dup, vif_dup))
                      check("VIF for social_media is in the hundreds", vif_dup > 100, TRUE,
                            hint = "dup should be social_media plus noise with SD 0.05 (on the z-score scale).")
                      check("Its SE is at least 5× larger than in m_both", se_dup > 5 * se_before, TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Interpret β",
                prompt: "In `m_both`, explain in words what the β for `social_media` means.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    beta_sm, beta_pc = m_both.params["social_media"], m_both.params["phone_checking"]
                    print(round(beta_sm, 3), round(beta_pc, 3))
                    """#,
                    r: #"""
                    beta_sm <- coef(m_both)[["social_media"]]
                    beta_pc <- coef(m_both)[["phone_checking"]]
                    round(c(beta_sm, beta_pc), 3)
                    """#
                ),
                answer: "Holding phone checking, age, education, and region constant, a one-SD increase in social media use is associated with a β-SD change in rumination. In the generated data both predictors are positive, with social media the stronger one.",
                selfCheck: SelfCheck(
                    names: "`beta_sm` and `beta_pc` — the standardized coefficients of social media and phone checking in `m_both`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # β = b × SD(x) / SD(y), from the unstandardized model
                        ref = pd.read_csv("survey.csv")
                        ref["rural"] = (ref["region"] == "rural").astype(float)
                        X = np.column_stack([np.ones(len(ref)), ref[["social_media", "phone_checking", "age", "education", "rural"]]])
                        b = np.linalg.lstsq(X, ref["rumination"].to_numpy(), rcond=None)[0]
                        sd_y = ref["rumination"].std()
                        check("β for social media", beta_sm, b[1] * ref["social_media"].std() / sd_y, tol=0.002,
                              hint="z-score the outcome and the continuous predictors before fitting.")
                        check("β for phone checking", beta_pc, b[2] * ref["phone_checking"].std() / sd_y, tol=0.002)
                        check("Social media is the stronger predictor", beta_sm > beta_pc > 0, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # β = b × SD(x) / SD(y), from the unstandardized model
                      ref <- read.csv("survey.csv")
                      b <- coef(lm(rumination ~ social_media + phone_checking + age + education + region, data = ref))
                      check("β for social media", beta_sm, b[["social_media"]] * sd(ref$social_media) / sd(ref$rumination),
                            tol = 0.002, hint = "z-score the outcome and the continuous predictors before fitting.")
                      check("β for phone checking", beta_pc,
                            b[["phone_checking"]] * sd(ref$phone_checking) / sd(ref$rumination), tol = 0.002)
                      check("Social media is the stronger predictor", beta_sm > beta_pc && beta_pc > 0, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Two predictors correlate at r = .92. What's the main risk of entering both?",
                options: ["R² goes down", "Coefficients become unstable with large SEs", "The intercept changes sign", "Nothing"],
                answer: 1,
                explanation: "High collinearity inflates standard errors and makes individual coefficients unreliable."
            ),
            Question(
                prompt: "ΔR² for predictor A (added last) is .06; for B (added last) it's .01. This suggests…",
                options: ["B explains more unique variance", "A explains more unique variance", "They're identical", "Neither matters"],
                answer: 1,
                explanation: "ΔR² is each predictor's unique contribution beyond the others."
            ),
        ]
    )

    static let moderation = Lesson(
        id: "moderation",
        title: "Moderation with continuous variables",
        summary: "Centering, interaction terms, simple slopes, and Johnson–Neyman.",
        minutes: 12,
        blocks: [
            .text("**Moderation** asks whether the relationship between X and Y depends on a third variable W. You test it by adding the product X × W to a regression. With continuous variables, **mean-center** X and W first so the lower-order coefficients describe effects at the average."),
            .model(ModelExplainer(
                name: "Moderation (interaction) in regression",
                purpose: "Tests whether the slope of X on Y changes with the value of a third variable W, by adding the product of X and W to a multiple regression.",
                equation: "Ŷ = b₀ + b₁X + b₂W + b₃(X × W)      slope of X at W = w:  b₁ + b₃w",
                steps: [
                    "Include X, W, and their product. The product's coefficient b₃ is how much the X slope changes per unit of W; its t-test is the moderation test.",
                    "With the product in the model, b₁ is the slope of X **when W = 0** — mean-centering makes that the slope at the average of W.",
                    "**Simple slopes:** compute b₁ + b₃w at chosen values of W (e.g. −1 SD, mean, +1 SD); re-centering W at each value gives the correct SE and p.",
                    "**Johnson–Neyman:** find the range of W over which the X slope is significant.",
                    "Plot predicted lines at a few values of W to show the pattern.",
                ],
                conditions: [
                    "All the conditions of multiple regression.",
                    "**Reliable measures** of X and W — measurement error in both compounds in the product, reducing power.",
                    "**Adequate power** — interactions usually need much larger samples than main effects.",
                    "**Don't dichotomize** continuous moderators.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.1 (multiple regression); Hayes (2022), *Introduction to Mediation, Moderation, and Conditional Process Analysis* (3rd ed.), chs. 7–9; Aiken & West (1991), *Multiple Regression: Testing and Interpreting Interactions*."
            )),
            .chart(ChartExample(
                title: "Simple slopes: how a moderator changes a relationship",
                kind: .simpleSlopes,
                reading: [
                    "Each line shows predicted rumination across social media use, at a different level of mindfulness (−1 SD, average, +1 SD); shaded bands are 95% CIs.",
                    "All three slope upward, but the slope is **steepest at low mindfulness** and flattest at high mindfulness — that's the interaction.",
                    "If the moderator didn't matter, the three lines would be parallel.",
                    "Hover to compare the three predictions at any level of social media use.",
                ]
            )),
            .terms([
                Term("Moderator (W)", "The variable that changes the strength or direction of the X → Y relationship."),
                Term("Interaction / product term", "X × W. Its coefficient is how much the X slope changes per unit of W."),
                Term("Mean-centering", "Subtracting the sample mean, so 0 = average. Doesn't change the interaction test, but makes main effects interpretable."),
                Term("Simple slope", "The X → Y slope at a specific value of W, e.g. 1 SD below the mean, the mean, and 1 SD above."),
                Term("Johnson–Neyman interval", "The range of W values where the X slope is statistically significant."),
            ]),
            .code(CodeSample(
                caption: "Does mindfulness weaken the social media → rumination link?",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                survey["sm_c"] = survey["social_media"] - survey["social_media"].mean()
                survey["mind_c"] = survey["mindfulness"] - survey["mindfulness"].mean()
                covs = "age + education + C(region)"

                model = smf.ols(f"rumination ~ sm_c * mind_c + {covs}", data=survey).fit()
                print(model.summary())          # the sm_c:mind_c row is the moderation test

                # Simple slopes via re-centering: shift W so 0 sits at the value of interest
                sd = survey["mind_c"].std()
                for label, w in [("−1 SD", -sd), ("mean", 0.0), ("+1 SD", sd)]:
                    d = survey.assign(mind_w=survey["mind_c"] - w)
                    fit = smf.ols(f"rumination ~ sm_c * mind_w + {covs}", data=d).fit()
                    lo, hi = fit.conf_int().loc["sm_c"]
                    print(f"{label:>6}: slope = {fit.params['sm_c']:.3f} "
                          f"[{lo:.3f}, {hi:.3f}], p = {fit.pvalues['sm_c']:.4f}")
                """#,
                r: #"""
                library(tidyverse)
                library(interactions)

                survey <- read_csv("survey.csv") |>
                  drop_na(mindfulness) |>
                  mutate(sm_c   = social_media - mean(social_media),
                         mind_c = mindfulness - mean(mindfulness))

                model <- lm(rumination ~ sm_c * mind_c + age + education + region, data = survey)
                summary(model)   # the sm_c:mind_c row is the moderation test

                # Simple slopes at −1 SD, mean, +1 SD, plus the Johnson–Neyman interval
                sim_slopes(model, pred = sm_c, modx = mind_c, johnson_neyman = TRUE)

                interact_plot(model, pred = sm_c, modx = mind_c, interval = TRUE)
                """#
            )),
            .keyPoint("The re-centering trick", "When W is centered at a value *w*, the coefficient on X **is** the simple slope at *w*, with a correct SE and p-value. That's all simple-slope software does under the hood."),
            .caution("Don't dichotomize", "Splitting a continuous moderator at the median to run two separate regressions throws away information and power. Keep W continuous and probe it with simple slopes."),
            .exercise(Exercise(
                title: "Centering changes what, exactly?",
                prompt: "Refit the model with the **uncentered** variables. Compare the interaction coefficient and the `social_media` coefficient to the centered model.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    raw = smf.ols(f"rumination ~ social_media * mindfulness + {covs}", data=survey).fit()
                    b_int_raw, b_int_c = raw.params["social_media:mindfulness"], model.params["sm_c:mind_c"]
                    b_sm_raw, b_sm_c = raw.params["social_media"], model.params["sm_c"]
                    print(raw.params[["social_media", "social_media:mindfulness"]])
                    print(model.params[["sm_c", "sm_c:mind_c"]])
                    """#,
                    r: #"""
                    raw <- lm(rumination ~ social_media * mindfulness + age + education + region, data = survey)
                    b_int_raw <- coef(raw)[["social_media:mindfulness"]]
                    b_int_c   <- coef(model)[["sm_c:mind_c"]]
                    b_sm_raw  <- coef(raw)[["social_media"]]
                    b_sm_c    <- coef(model)[["sm_c"]]
                    coef(raw)[c("social_media", "social_media:mindfulness")]
                    coef(model)[c("sm_c", "sm_c:mind_c")]
                    """#
                ),
                answer: "The interaction coefficient and its p-value are **identical**. The `social_media` coefficient changes, because uncentered it's the slope at mindfulness = 0 — a value outside the 1–5 scale.",
                selfCheck: SelfCheck(
                    names: "`b_int_raw` and `b_int_c` (the interaction, uncentered and centered) and `b_sm_raw` and `b_sm_c` (the social-media coefficient)",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # The two models are reparameterizations of each other: centering moves the "0" of mindfulness,
                        # so the social-media slope at the mean equals the raw slope + interaction × mean mindfulness.
                        check("Interaction is identical in both models", b_int_raw, b_int_c, tol=1e-6)
                        check("Centered slope = raw slope + interaction × mean(mindfulness)", b_sm_c,
                              b_sm_raw + b_int_raw * survey["mindfulness"].mean(), tol=1e-6,
                              hint="Fit both models on the same rows (drop missing mindfulness first).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # The two models are reparameterizations of each other: centering moves the "0" of mindfulness,
                      # so the social-media slope at the mean equals the raw slope + interaction × mean mindfulness.
                      check("Interaction is identical in both models", b_int_raw, b_int_c, tol = 1e-6)
                      check("Centered slope = raw slope + interaction × mean(mindfulness)", b_sm_c,
                            b_sm_raw + b_int_raw * mean(survey$mindfulness), tol = 1e-6,
                            hint = "Fit both models on the same rows (drop missing mindfulness first).")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Second-stage moderation",
                prompt: "Test whether mindfulness also moderates the **rumination → anxiety** link. The generated data has no such effect built in. What do you find?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    survey["rum_c"] = survey["rumination"] - survey["rumination"].mean()
                    m2 = smf.ols(f"anxiety ~ rum_c * mind_c + sm_c + {covs}", data=survey).fit()
                    b_rm, p_rm = m2.params["rum_c:mind_c"], m2.pvalues["rum_c:mind_c"]
                    print(b_rm, p_rm)
                    """#,
                    r: #"""
                    survey <- survey |> mutate(rum_c = rumination - mean(rumination))
                    m2 <- lm(anxiety ~ rum_c * mind_c + sm_c + age + education + region, data = survey)
                    b_rm <- coef(m2)[["rum_c:mind_c"]]
                    p_rm <- summary(m2)$coefficients["rum_c:mind_c", "Pr(>|t|)"]
                    c(b_rm, p_rm)
                    """#
                ),
                answer: "The interaction is near zero and usually non-significant. Remember: a non-significant interaction is *absence of evidence*, not proof of no moderation — an equivalence test would be needed to claim that.",
                selfCheck: SelfCheck(
                    names: "`b_rm` and `p_rm` — the `rum_c:mind_c` coefficient and its p-value",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                        for col in ["rumination", "mindfulness", "social_media"]:
                            ref[col + "_c"] = ref[col] - ref[col].mean()
                        fit = smf.ols("anxiety ~ rumination_c * mindfulness_c + social_media_c + age + education + C(region)",
                                      data=ref).fit()
                        term = "rumination_c:mindfulness_c"
                        check("Interaction coefficient", b_rm, fit.params[term], tol=0.001,
                              hint="Keep social media and the covariates in the model, on the same rows.")
                        check("Its p-value", p_rm, fit.pvalues[term], tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref <- ref[!is.na(ref$mindfulness), ]
                      for (col in c("rumination", "mindfulness", "social_media")) {
                        ref[[paste0(col, "_c")]] <- ref[[col]] - mean(ref[[col]])
                      }
                      fit <- lm(anxiety ~ rumination_c * mindfulness_c + social_media_c + age + education + region, data = ref)
                      term <- "rumination_c:mindfulness_c"
                      check("Interaction coefficient", b_rm, coef(fit)[[term]], tol = 0.001,
                            hint = "Keep social media and the covariates in the model, on the same rows.")
                      check("Its p-value", p_rm, summary(fit)$coefficients[term, "Pr(>|t|)"], tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "The interaction coefficient for X × W is −0.20. What does that mean?",
                options: [
                    "X has no effect",
                    "The X slope decreases by 0.20 for each one-unit increase in W",
                    "W decreases Y by 0.20",
                    "The model is misspecified",
                ],
                answer: 1,
                explanation: "The product term is the change in the X → Y slope per unit of W."
            ),
            Question(
                prompt: "Mean-centering X and W before forming X × W changes…",
                options: ["The interaction's p-value", "The meaning of the X and W main-effect coefficients", "R²", "Nothing at all"],
                answer: 1,
                explanation: "Centering redefines 0 as the mean, so main effects become effects at the average of the other variable."
            ),
        ]
    )

    static let mediation = Lesson(
        id: "mediation",
        title: "Mediation & bootstrapped indirect effects",
        summary: "a, b, c′ paths, and why you bootstrap the indirect effect.",
        minutes: 12,
        blocks: [
            .text("**Mediation** asks whether X relates to Y *through* a mediator M. Two regressions estimate the pieces: M on X (path **a**), and Y on M and X (path **b** and the direct path **c′**). The **indirect effect** is a × b."),
            .model(ModelExplainer(
                name: "Simple mediation",
                purpose: "Splits the association between X and Y into an indirect part that runs through a mediator M and a direct part that doesn't.",
                equation: "M = i₁ + aX        Y = i₂ + c′X + bM        indirect = a·b        total c = c′ + a·b",
                steps: [
                    "Regress M on X (and covariates) to get **a**.",
                    "Regress Y on X and M (and the same covariates) to get **b** (M → Y, holding X constant) and **c′** (the direct effect).",
                    "The **indirect effect** is a × b. With ordinary regression and the same covariates in both equations, the total effect equals c′ + ab exactly.",
                    "Because a product of two estimates isn't normally distributed, test ab with a **bootstrap CI** (thousands of resamples): the indirect effect is supported when the CI excludes 0.",
                ],
                conditions: [
                    "All the conditions of regression for both equations.",
                    "**Correct causal ordering** (X → M → Y) — justified by design (randomized X, measurement over time) or strong theory; the statistics can't establish it.",
                    "**No unmeasured confounding** of the M–Y relationship (randomizing X doesn't protect against this).",
                    "**Reliable measurement of M**; error in M biases b toward 0 and c′ away from it.",
                ],
                reading: "Hayes (2022), *Introduction to Mediation, Moderation, and Conditional Process Analysis* (3rd ed.), chs. 3–4; MacKinnon (2008), *Introduction to Statistical Mediation Analysis*."
            )),
            .terms([
                Term("Path a", "Effect of X on the mediator M."),
                Term("Path b", "Effect of M on Y, controlling for X."),
                Term("Direct effect (c′)", "Effect of X on Y that does *not* go through M."),
                Term("Total effect (c)", "c′ + a × b — the overall X → Y association."),
                Term("Indirect effect", "a × b. Its sampling distribution is skewed, so normal-theory p-values are inaccurate."),
                Term("Bootstrap", "Resampling rows with replacement thousands of times and re-estimating, to get an empirical CI."),
                Term("PROCESS Model 4", "Hayes' name for this simple mediation model."),
            ]),
            .code(CodeSample(
                caption: "Social media → rumination → anxiety, 10,000 bootstrap resamples",
                python: #"""
                import pandas as pd
                import pingouin as pg

                survey = pd.read_csv("survey.csv")
                survey["rural"] = (survey["region"] == "rural").astype(int)   # covariates must be numeric

                med = pg.mediation_analysis(
                    data=survey, x="social_media", m="rumination", y="anxiety",
                    covar=["age", "education", "rural"],
                    n_boot=10_000, seed=42,
                )
                print(med.round(3))   # rows: M ~ X (a), Y ~ M (b), Total, Direct, Indirect
                """#,
                r: #"""
                library(tidyverse)
                library(lavaan)

                survey <- read_csv("survey.csv") |>
                  mutate(rural = as.integer(region == "rural"))

                model <- '
                  rumination ~ a * social_media + age + education + rural
                  anxiety    ~ b * rumination + c_prime * social_media + age + education + rural

                  indirect := a * b
                  total    := c_prime + a * b
                '

                # 10,000 resamples can take a minute or two
                fit <- sem(model, data = survey, se = "bootstrap", bootstrap = 10000)
                parameterEstimates(fit, boot.ci.type = "perc")
                """#
            )),
            .keyPoint("Read the CI, not a p-value", "The indirect effect is supported when its 95% bootstrap CI **excludes zero**. The direct effect can remain significant too — that's *partial* mediation, which is the norm."),
            .caution("Mediation isn't proof of causation", "With cross-sectional data, a mediation model shows a pattern *consistent with* X → M → Y. The reversed model (X → Y → M) often fits just as well. Causal claims need design support: temporal ordering, experiments, or strong theory."),
            .exercise(Exercise(
                title: "Compute a × b yourself",
                prompt: "Fit the two regressions by hand and multiply the a and b coefficients. Does the product match the indirect effect from the software?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import statsmodels.formula.api as smf
                    covs = "age + education + rural"
                    a = smf.ols(f"rumination ~ social_media + {covs}", data=survey).fit().params["social_media"]
                    b = smf.ols(f"anxiety ~ rumination + social_media + {covs}", data=survey).fit().params["rumination"]
                    ab = a * b
                    print(a, b, ab)
                    """#,
                    r: #"""
                    a <- coef(lm(rumination ~ social_media + age + education + rural, data = survey))[["social_media"]]
                    b <- coef(lm(anxiety ~ rumination + social_media + age + education + rural, data = survey))[["rumination"]]
                    ab <- a * b
                    c(a = a, b = b, indirect = ab)
                    """#
                ),
                answer: "The product equals the reported indirect effect exactly. The bootstrap only adds the confidence interval.",
                selfCheck: SelfCheck(
                    names: "`a`, `b`, and `ab` (their product)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        ref["rural"] = (ref["region"] == "rural").astype(float)
                        covs = ref[["age", "education", "rural"]].to_numpy()

                        def ols(y, *xs):
                            X = np.column_stack([np.ones(len(ref)), *xs, covs])
                            return np.linalg.lstsq(X, y, rcond=None)[0]

                        a_ref = ols(ref["rumination"], ref["social_media"])[1]
                        b_ref = ols(ref["anxiety"], ref["rumination"], ref["social_media"])[1]
                        check("Path a (social media → rumination)", a, a_ref, tol=0.001)
                        check("Path b (rumination → anxiety, holding social media constant)", b, b_ref, tol=0.001,
                              hint="Include social media (and the covariates) in the anxiety model.")
                        check("Indirect effect a × b", ab, a_ref * b_ref, tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref$rural <- as.integer(ref$region == "rural")
                      a_ref <- coef(lm(rumination ~ social_media + age + education + rural, data = ref))[["social_media"]]
                      b_ref <- coef(lm(anxiety ~ rumination + social_media + age + education + rural, data = ref))[["rumination"]]
                      check("Path a (social media → rumination)", a, a_ref, tol = 0.001)
                      check("Path b (rumination → anxiety, holding social media constant)", b, b_ref, tol = 0.001,
                            hint = "Include social media (and the covariates) in the anxiety model.")
                      check("Indirect effect a × b", ab, a_ref * b_ref, tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Write your own bootstrap",
                prompt: "Resample participants with replacement 2,000 times, recompute a × b each time, and take the 2.5th and 97.5th percentiles.",
                hint: "Wrap the two regressions in a function that takes a data frame and returns a × b.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import statsmodels.formula.api as smf
                    covs = "age + education + rural"

                    def indirect(d):
                        a = smf.ols(f"rumination ~ social_media + {covs}", data=d).fit().params["social_media"]
                        b = smf.ols(f"anxiety ~ rumination + social_media + {covs}", data=d).fit().params["rumination"]
                        return a * b

                    rng = np.random.default_rng(1)
                    boots = [indirect(survey.sample(len(survey), replace=True, random_state=rng))
                             for _ in range(2000)]
                    boot_ci = np.percentile(boots, [2.5, 97.5])
                    print(boot_ci)
                    """#,
                    r: #"""
                    indirect <- function(d) {
                      a <- coef(lm(rumination ~ social_media + age + education + rural, data = d))["social_media"]
                      b <- coef(lm(anxiety ~ rumination + social_media + age + education + rural, data = d))["rumination"]
                      a * b
                    }

                    set.seed(1)
                    boots <- replicate(2000, indirect(survey[sample(nrow(survey), replace = TRUE), ]))
                    boot_ci <- quantile(boots, c(0.025, 0.975))
                    boot_ci
                    """#
                ),
                answer: "Your percentile CI is close to the package's interval and excludes zero, since the data were built with a real indirect path.",
                selfCheck: SelfCheck(
                    names: "`boot_ci` — your 95% percentile CI as [lower, upper]",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # A normal-theory (Sobel) interval, ab ± 1.96 × SE(ab), as a rough benchmark.
                        # Bootstrap intervals differ from it a little, so the tolerance is generous.
                        ref = pd.read_csv("survey.csv")
                        ref["rural"] = (ref["region"] == "rural").astype(int)
                        fa = smf.ols("rumination ~ social_media + age + education + rural", data=ref).fit()
                        fb = smf.ols("anxiety ~ rumination + social_media + age + education + rural", data=ref).fit()
                        a_, b_ = fa.params["social_media"], fb.params["rumination"]
                        se_ab = np.sqrt(a_**2 * fb.bse["rumination"]**2 + b_**2 * fa.bse["social_media"]**2)
                        sobel = a_ * b_ + np.array([-1.96, 1.96]) * se_ab
                        print(f"Sobel benchmark: [{sobel[0]:.3f}, {sobel[1]:.3f}]")
                        check("Bootstrap CI is close to the benchmark", boot_ci, sobel, tol=0.03,
                              hint="Resample whole rows and refit both regressions on each resample.")
                        check("The CI excludes 0", bool(boot_ci[0] > 0), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # A normal-theory (Sobel) interval, ab ± 1.96 × SE(ab), as a rough benchmark.
                      # Bootstrap intervals differ from it a little, so the tolerance is generous.
                      ref <- read.csv("survey.csv")
                      ref$rural <- as.integer(ref$region == "rural")
                      fa <- coef(summary(lm(rumination ~ social_media + age + education + rural, data = ref)))["social_media", ]
                      fb <- coef(summary(lm(anxiety ~ rumination + social_media + age + education + rural, data = ref)))["rumination", ]
                      se_ab <- sqrt(fa[[1]]^2 * fb[[2]]^2 + fb[[1]]^2 * fa[[2]]^2)
                      sobel <- fa[[1]] * fb[[1]] + c(-1.96, 1.96) * se_ab
                      cat(sprintf("Sobel benchmark: [%.3f, %.3f]\n", sobel[1], sobel[2]))
                      check("Bootstrap CI is close to the benchmark", boot_ci, sobel, tol = 0.03,
                            hint = "Resample whole rows and refit both regressions on each resample.")
                      check("The CI excludes 0", boot_ci[[1]] > 0, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "a = 0.50 and b = 0.40. The indirect effect is…",
                options: ["0.90", "0.20", "0.10", "1.25"],
                answer: 1,
                explanation: "Indirect = a × b = 0.50 × 0.40 = 0.20."
            ),
            Question(
                prompt: "Why bootstrap the indirect effect instead of using a normal-theory test?",
                options: ["It's faster", "The product a × b isn't normally distributed", "It always gives smaller p-values", "Journals forbid Sobel tests"],
                answer: 1,
                explanation: "Products of coefficients have skewed sampling distributions; bootstrapping captures that shape."
            ),
        ]
    )

    static let moderatedMediation = Lesson(
        id: "moderated-mediation",
        title: "Moderated mediation",
        summary: "Conditional indirect effects and the index of moderated mediation.",
        minutes: 12,
        blocks: [
            .text("Combine the last two lessons: if W moderates the **a path** (X → M), the indirect effect itself depends on W. This *first-stage* moderated mediation is Hayes' **PROCESS Model 7**."),
            .model(ModelExplainer(
                name: "Conditional process (moderated mediation) model",
                purpose: "Lets a moderator W change one path of a mediation model, so the size of the indirect effect depends on W.",
                equation: "M = i₁ + a₁X + a₂W + a₃(X × W)        Y = i₂ + c′X + bM        indirect at W = w:  (a₁ + a₃w)·b",
                steps: [
                    "Fit the mediator model with the X × W interaction (first-stage moderation) and the outcome model as in simple mediation.",
                    "The **conditional indirect effect** at W = w is (a₁ + a₃w) × b — a line in w.",
                    "The slope of that line, **a₃ × b**, is the **index of moderated mediation**: how much the indirect effect changes per unit of W.",
                    "Bootstrap the index and the conditional indirect effects; moderated mediation is supported when the index's CI excludes 0.",
                ],
                conditions: [
                    "Everything required for mediation and for moderation.",
                    "**A theoretical reason** for which path W moderates (first stage, second stage, or both).",
                    "**Large samples** — the index combines an interaction with another path, so it needs considerable power.",
                ],
                reading: "Hayes (2015), *Multivariate Behavioral Research*, 50(1), 1–22 (the index of moderated mediation); Hayes (2022), chs. 11–12."
            )),
            .terms([
                Term("Conditional indirect effect", "The indirect effect at a particular value of W: (a₁ + a₃·W) × b."),
                Term("Index of moderated mediation", "a₃ × b — how much the indirect effect changes per unit of W. Its bootstrap CI is the formal test."),
                Term("First-stage moderation", "W moderates X → M (Model 7). Second-stage: W moderates M → Y (Model 14)."),
            ]),
            .code(CodeSample(
                caption: "Indirect effect of social media at low, average, and high mindfulness",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                survey["rural"] = (survey["region"] == "rural").astype(int)
                survey["sm_c"] = survey["social_media"] - survey["social_media"].mean()
                survey["mind_c"] = survey["mindfulness"] - survey["mindfulness"].mean()
                covs = "age + education + rural"
                sd_w = survey["mind_c"].std()

                def estimates(d):
                    a = smf.ols(f"rumination ~ sm_c * mind_c + {covs}", data=d).fit().params
                    b = smf.ols(f"anxiety ~ rumination + sm_c + {covs}", data=d).fit().params["rumination"]
                    a1, a3 = a["sm_c"], a["sm_c:mind_c"]
                    return {"index_mod_med": a3 * b,
                            "indirect_low":  (a1 - a3 * sd_w) * b,
                            "indirect_mean": a1 * b,
                            "indirect_high": (a1 + a3 * sd_w) * b}

                point = pd.Series(estimates(survey))
                rng = np.random.default_rng(42)
                boots = pd.DataFrame([estimates(survey.sample(len(survey), replace=True, random_state=rng))
                                      for _ in range(5000)])          # ~1 minute

                print(pd.DataFrame({"estimate": point,
                                    "ci_low": boots.quantile(0.025),
                                    "ci_high": boots.quantile(0.975)}).round(3))
                """#,
                r: #"""
                library(tidyverse)
                library(lavaan)

                survey <- read_csv("survey.csv") |>
                  drop_na(mindfulness) |>
                  mutate(rural     = as.integer(region == "rural"),
                         sm_c      = social_media - mean(social_media),
                         mind_c    = mindfulness - mean(mindfulness),
                         sm_x_mind = sm_c * mind_c)

                sd_w <- sd(survey$mind_c)

                # sprintf inserts the moderator's SD into the model text
                model <- sprintf('
                  rumination ~ a1 * sm_c + a2 * mind_c + a3 * sm_x_mind + age + education + rural
                  anxiety    ~ b * rumination + c_prime * sm_c + age + education + rural

                  index_mod_med := a3 * b
                  indirect_low  := (a1 - %1$.4f * a3) * b
                  indirect_mean := a1 * b
                  indirect_high := (a1 + %1$.4f * a3) * b
                ', sd_w)

                fit <- sem(model, data = survey, se = "bootstrap", bootstrap = 5000)
                parameterEstimates(fit, boot.ci.type = "perc") |>
                  filter(op == ":=")
                """#
            )),
            .keyPoint("Two things to report", "1. The **index of moderated mediation** with its bootstrap CI — the formal test.\n2. **Conditional indirect effects** at meaningful values of W (e.g. −1 SD, mean, +1 SD) so readers can see the pattern."),
            .caution("A pattern isn't a test", "Seeing a significant indirect effect at one level of W and a non-significant one at another doesn't establish moderation. Only the index's CI tests whether the indirect effects differ."),
            .exercise(Exercise(
                title: "Read the pattern",
                prompt: "Run the code. Is the index of moderated mediation negative, and does its CI exclude 0? How do the three conditional indirect effects compare?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    index_mod_med = point["index_mod_med"]
                    indirect = point[["indirect_low", "indirect_mean", "indirect_high"]].to_numpy()
                    print(index_mod_med, boots["index_mod_med"].quantile([0.025, 0.975]).to_numpy(), indirect)
                    """#,
                    r: #"""
                    pe <- parameterEstimates(fit, boot.ci.type = "perc") |> filter(op == ":=")
                    index_mod_med <- pe$est[pe$label == "index_mod_med"]
                    indirect <- pe$est[match(c("indirect_low", "indirect_mean", "indirect_high"), pe$label)]
                    pe
                    """#
                ),
                answer: "The index is negative with a CI that excludes 0 in most generated samples. The indirect effect is largest at low mindfulness and smallest at high mindfulness — the built-in truth.",
                selfCheck: SelfCheck(
                    names: "`index_mod_med` and `indirect` (the conditional indirect effects at −1 SD, the mean, and +1 SD)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                        ref["rural"] = (ref["region"] == "rural").astype(int)
                        ref["x"] = ref["social_media"] - ref["social_media"].mean()
                        ref["w"] = ref["mindfulness"] - ref["mindfulness"].mean()
                        a = smf.ols("rumination ~ x * w + age + education + rural", data=ref).fit().params
                        b = smf.ols("anxiety ~ rumination + x + age + education + rural", data=ref).fit().params["rumination"]
                        sd_w = ref["w"].std()
                        check("Index of moderated mediation (a₃ × b)", index_mod_med, a["x:w"] * b, tol=0.001)
                        check("Indirect effects at −1 SD, mean, +1 SD", indirect,
                              [(a["x"] + a["x:w"] * w) * b for w in (-sd_w, 0, sd_w)], tol=0.001,
                              hint="Each conditional indirect effect is (a₁ + a₃·w) × b.")
                        check("Indirect effect shrinks as mindfulness rises", bool(np.all(np.diff(indirect) < 0)), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref <- ref[!is.na(ref$mindfulness), ]
                      ref$rural <- as.integer(ref$region == "rural")
                      ref$x <- ref$social_media - mean(ref$social_media)
                      ref$w <- ref$mindfulness - mean(ref$mindfulness)
                      a <- coef(lm(rumination ~ x * w + age + education + rural, data = ref))
                      b <- coef(lm(anxiety ~ rumination + x + age + education + rural, data = ref))[["rumination"]]
                      sd_w <- sd(ref$w)
                      check("Index of moderated mediation (a₃ × b)", index_mod_med, a[["x:w"]] * b, tol = 0.001)
                      check("Indirect effects at −1 SD, mean, +1 SD", indirect,
                            sapply(c(-sd_w, 0, sd_w), function(w) (a[["x"]] + a[["x:w"]] * w) * b), tol = 0.001,
                            hint = "Each conditional indirect effect is (a₁ + a₃·w) × b.")
                      check("Indirect effect shrinks as mindfulness rises", all(diff(indirect) < 0), TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Move the moderator",
                prompt: "Change the model so mindfulness moderates the **b path** (rumination → anxiety) instead. Is there evidence for second-stage moderation?",
                hint: "Put the product term in the anxiety equation: `anxiety ~ rumination * mind_c + sm_c + …`. The index becomes a × b₃.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    survey["rum_c"] = survey["rumination"] - survey["rumination"].mean()

                    def index_second_stage(d):
                        a = smf.ols(f"rum_c ~ sm_c + mind_c + {covs}", data=d).fit().params["sm_c"]
                        b3 = smf.ols(f"anxiety ~ rum_c * mind_c + sm_c + {covs}", data=d).fit().params["rum_c:mind_c"]
                        return a * b3

                    boots2 = [index_second_stage(survey.sample(len(survey), replace=True, random_state=rng))
                              for _ in range(2000)]
                    index2 = index_second_stage(survey)
                    print(index2, np.percentile(boots2, [2.5, 97.5]))
                    """#,
                    r: #"""
                    survey <- survey |> mutate(rum_c = rumination - mean(rumination),
                                               rum_x_mind = rum_c * mind_c)
                    model2 <- '
                      rum_c   ~ a * sm_c + mind_c + age + education + rural
                      anxiety ~ b1 * rum_c + b2 * mind_c + b3 * rum_x_mind + sm_c + age + education + rural
                      index_second_stage := a * b3
                    '
                    fit2 <- sem(model2, data = survey, se = "bootstrap", bootstrap = 2000)
                    pe2 <- parameterEstimates(fit2, boot.ci.type = "perc") |> filter(op == ":=")
                    index2 <- pe2$est
                    pe2
                    """#
                ),
                answer: "The second-stage index is near zero with a CI spanning 0 — the generated data has moderation only in the first stage.",
                selfCheck: SelfCheck(
                    names: "`index2` — the second-stage index a × b₃",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                        ref["rural"] = (ref["region"] == "rural").astype(int)
                        for col in ["social_media", "mindfulness", "rumination"]:
                            ref[col + "_c"] = ref[col] - ref[col].mean()
                        covs = "age + education + rural"
                        a = smf.ols(f"rumination_c ~ social_media_c + mindfulness_c + {covs}", data=ref).fit().params["social_media_c"]
                        b3 = smf.ols(f"anxiety ~ rumination_c * mindfulness_c + social_media_c + {covs}",
                                     data=ref).fit().params["rumination_c:mindfulness_c"]
                        check("Second-stage index a × b₃", index2, a * b3, tol=0.001,
                              hint="Mindfulness goes in both equations; the product term goes in the anxiety equation.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref <- ref[!is.na(ref$mindfulness), ]
                      ref$rural <- as.integer(ref$region == "rural")
                      for (col in c("social_media", "mindfulness", "rumination")) {
                        ref[[paste0(col, "_c")]] <- ref[[col]] - mean(ref[[col]])
                      }
                      a  <- coef(lm(rumination_c ~ social_media_c + mindfulness_c + age + education + rural,
                                    data = ref))[["social_media_c"]]
                      b3 <- coef(lm(anxiety ~ rumination_c * mindfulness_c + social_media_c + age + education + rural,
                                    data = ref))[["rumination_c:mindfulness_c"]]
                      check("Second-stage index a × b₃", index2, a * b3, tol = 0.001,
                            hint = "Mindfulness goes in both equations; the product term goes in the anxiety equation.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "a₁ = 0.40, a₃ = −0.20, b = 0.50. What's the conditional indirect effect at W = +1 (centered)?",
                options: ["0.10", "0.20", "0.30", "−0.10"],
                answer: 0,
                explanation: "(a₁ + a₃·W) × b = (0.40 − 0.20) × 0.50 = 0.10."
            ),
            Question(
                prompt: "What formally tests moderated mediation?",
                options: [
                    "Whether the indirect effect is significant at high W",
                    "The bootstrap CI of the index of moderated mediation",
                    "The R² of the outcome model",
                    "Comparing two separate mediation models by eye",
                ],
                answer: 1,
                explanation: "The index (a₃ × b) quantifies how the indirect effect changes with W."
            ),
        ]
    )
}

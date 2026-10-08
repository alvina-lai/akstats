import Foundation

// Lessons that extend the core units: resampling and planning (Unit 3), ANCOVA (Unit 4),
// between- and within-person correlation (Unit 5), and clustered binary outcomes and
// inter-rater reliability (Unit 7).

// MARK: - Unit 3 · Inference

extension Curriculum {
    static let bootstrapLesson = Lesson(
        id: "bootstrap",
        title: "Bootstrap & resampling",
        summary: "Confidence intervals by simulation — and what to resample when data are clustered.",
        minutes: 12,
        blocks: [
            .text("Formulas for standard errors exist for means and proportions, but not for every statistic you care about (a median, a ratio, a product of coefficients). The **bootstrap** estimates sampling variability by treating your sample as a stand-in for the population and resampling from it."),
            .model(ModelExplainer(
                name: "The nonparametric bootstrap",
                purpose: "Approximates the sampling distribution of any statistic by recomputing it on many resamples of the data, then reads a confidence interval off that distribution.",
                steps: [
                    "Draw a resample of the same size *n* from your data **with replacement** — some rows appear twice, others not at all.",
                    "Compute the statistic (mean, median, correlation, indirect effect…) on the resample.",
                    "Repeat thousands of times (2,000–10,000) to build the **bootstrap distribution**.",
                    "The **percentile CI** is the 2.5th to 97.5th percentiles of that distribution; its SD estimates the standard error.",
                ],
                conditions: [
                    "**Independent units.** Resample whatever was sampled independently — individuals, or whole clusters (people, schools) when observations are nested.",
                    "**A representative sample.** The bootstrap can't fix a biased sample; it only quantifies sampling noise.",
                    "**Enough resamples** that the CI endpoints are stable, and a sample that isn't tiny (with n < 15 or so, bootstrap CIs are too narrow).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §2.3 (case study: simulating a randomization test) and §5.1 (point estimates and sampling variability)."
            )),
            .chart(ChartExample(
                title: "A bootstrap distribution and its 95% CI",
                kind: .bootstrapDistribution,
                reading: [
                    "Each bar counts resamples whose median fell in that range — 3,000 resamples of one sample of 80 reaction times.",
                    "The pink line is the median of the original sample; the bootstrap distribution is centered close to it.",
                    "The dashed orange lines are the 2.5th and 97.5th percentiles: everything between them (blue bars) is the **95% percentile confidence interval**.",
                    "The width of the distribution reflects uncertainty: more data or less variable data would make it narrower.",
                ]
            )),
            .code(CodeSample(
                caption: "A 95% bootstrap CI for the median",
                python: #"""
                import numpy as np
                import pandas as pd
                from scipy import stats

                survey = pd.read_csv("survey.csv")
                x = survey["anxiety"].to_numpy()

                rng = np.random.default_rng(1)
                boots = np.array([np.median(rng.choice(x, size=len(x), replace=True)) for _ in range(10_000)])
                print("median:", np.median(x), "95% CI:", np.percentile(boots, [2.5, 97.5]))

                # SciPy's built-in version
                print(stats.bootstrap((x,), np.median, n_resamples=10_000, method="percentile").confidence_interval)
                """#,
                r: #"""
                survey <- read.csv("survey.csv")
                x <- survey$anxiety

                set.seed(1)
                boots <- replicate(10000, median(sample(x, replace = TRUE)))
                median(x)
                quantile(boots, c(0.025, 0.975))
                """#
            )),
            .text("**Clustered data change what you resample.** In `diary.csv`, each person contributes 14 days. Days from the same person are more alike than days from different people, so treating all 1,400 days as independent understates uncertainty. The **cluster bootstrap** resamples *people*, keeping all of their days together."),
            .code(CodeSample(
                caption: "Share of long workdays (> 9 hours): naive vs. cluster-bootstrap CI",
                python: #"""
                diary = pd.read_csv("diary.csv")
                p_hat = (diary["work_hours"] > 9).mean()
                naive_se = np.sqrt(p_hat * (1 - p_hat) / len(diary))
                print("naive 95% CI:", p_hat - 1.96 * naive_se, p_hat + 1.96 * naive_se)

                by_person = {pid: g for pid, g in diary.groupby("participant")}
                ids = np.array(list(by_person))
                boots = []
                for _ in range(2000):
                    resample = pd.concat([by_person[i] for i in rng.choice(ids, size=len(ids), replace=True)])
                    boots.append((resample["work_hours"] > 9).mean())
                print("cluster 95% CI:", np.percentile(boots, [2.5, 97.5]))
                """#,
                r: #"""
                diary <- read.csv("diary.csv")
                p_hat <- mean(diary$work_hours > 9)
                p_hat + c(-1, 1) * 1.96 * sqrt(p_hat * (1 - p_hat) / nrow(diary))   # naive

                by_person <- split(diary, diary$participant)
                set.seed(1)
                boots <- replicate(2000, {
                  resample <- do.call(rbind, by_person[sample(names(by_person), replace = TRUE)])
                  mean(resample$work_hours > 9)
                })
                quantile(boots, c(0.025, 0.975))                                     # cluster
                """#
            )),
            .keyPoint("Bootstrap vs. permutation", "A **bootstrap** resamples *with* replacement to estimate uncertainty (CIs). A **permutation test** shuffles group labels *without* replacement to build the null distribution (p-values). Both are simulation-based, but they answer different questions."),
            .caution("Naive intervals can be badly too narrow", "Here the cluster interval is roughly twice as wide as the naive one, because people differ a lot in how much they usually work. The same logic applies to students within classrooms, patients within clinics, or repeated responses within participants."),
            .exercise(Exercise(
                title: "Bootstrap a correlation",
                prompt: "Use 5,000 resamples to get a 95% CI for the correlation between `rumination` and `anxiety` in survey.csv. Compare it with the analytic CI from `pg.corr()` or `cor.test()`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pingouin as pg
                    idx = np.arange(len(survey))
                    boots = [survey.iloc[rng.choice(idx, len(idx))][["rumination", "anxiety"]].corr().iloc[0, 1]
                             for _ in range(5000)]
                    boot_ci = np.percentile(boots, [2.5, 97.5])
                    r_ci = pg.corr(survey["rumination"], survey["anxiety"])["CI95%"].iloc[0]
                    print(boot_ci, r_ci)
                    """#,
                    r: #"""
                    set.seed(2)
                    boots <- replicate(5000, { i <- sample(nrow(survey), replace = TRUE)
                                               cor(survey$rumination[i], survey$anxiety[i]) })
                    boot_ci <- quantile(boots, c(0.025, 0.975))
                    r_ci <- cor.test(survey$rumination, survey$anxiety)$conf.int
                    boot_ci; r_ci
                    """#
                ),
                answer: "The two intervals are nearly identical (around .45–.60). With a large sample and a well-behaved statistic, the bootstrap reproduces the formula — its value is for statistics that have no simple formula.",
                selfCheck: SelfCheck(
                    names: "`boot_ci` (your bootstrap 95% CI) and `r_ci` (the analytic one), each as [lower, upper]",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # The analytic CI via Fisher's z: atanh(r) ± 1.96 / √(n − 3), transformed back with tanh.
                        ref = pd.read_csv("survey.csv")
                        r, n = ref["rumination"].corr(ref["anxiety"]), len(ref)
                        fisher_ci = np.tanh(np.arctanh(r) + np.array([-1, 1]) * 1.959964 / np.sqrt(n - 3))
                        check("Analytic 95% CI", r_ci, fisher_ci, tol=0.005)
                        # Bootstrap CIs vary a little from run to run, so they only need to be close.
                        check("Bootstrap CI is close to the analytic one", boot_ci, fisher_ci, tol=0.03,
                              hint="Resample whole rows (both variables together), with replacement.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # The analytic CI via Fisher's z: atanh(r) ± 1.96 / √(n − 3), transformed back with tanh.
                      ref <- read.csv("survey.csv")
                      r <- cor(ref$rumination, ref$anxiety)
                      fisher_ci <- tanh(atanh(r) + c(-1, 1) * qnorm(0.975) / sqrt(nrow(ref) - 3))
                      check("Analytic 95% CI", r_ci, fisher_ci, tol = 0.005)
                      # Bootstrap CIs vary a little from run to run, so they only need to be close.
                      check("Bootstrap CI is close to the analytic one", boot_ci, fisher_ci, tol = 0.03,
                            hint = "Resample whole rows (both variables together), with replacement.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A bootstrap resample is drawn…",
                options: ["Without replacement, half the size of the data", "With replacement, the same size as the data", "From a normal distribution", "By shuffling group labels"],
                answer: 1,
                explanation: "Sampling with replacement mimics drawing new samples from the population."
            ),
            Question(
                prompt: "Students are nested in 20 classrooms. For a cluster bootstrap you resample…",
                options: ["Students", "Classrooms, keeping each one's students together", "Test items", "Residuals only"],
                answer: 1,
                explanation: "Resample the units that were sampled independently."
            ),
        ]
    )

    static let samplePlanning = Lesson(
        id: "sample-planning",
        title: "Planning sample size: simulation & sequential designs",
        summary: "Power for any design, and how to look at data early without inflating errors.",
        minutes: 13,
        blocks: [
            .text("Formula-based power calculators exist for simple designs, but **simulation** works for any design: generate data with the effect you expect, run your planned analysis, repeat many times, and count how often p < α."),
            .model(ModelExplainer(
                name: "Power analysis by simulation",
                purpose: "Estimates the probability that a planned study and analysis will detect an effect of a given size.",
                steps: [
                    "Write down the data-generating model: sample size, effect size, variability, and any covariates or clustering.",
                    "Simulate one dataset from that model and run **exactly** the analysis you plan to report.",
                    "Record whether the test was significant.",
                    "Repeat 1,000+ times; the share of significant results is the estimated **power**. Vary *n* until power reaches your target (often .80 or .90).",
                ],
                conditions: [
                    "**A defensible effect size** — the smallest effect of interest or a meta-analytic estimate, not a single (likely inflated) published result.",
                    "**Realistic nuisance parameters**: SDs, correlations among predictors, reliability of measures, attrition.",
                    "**The same model you'll fit**, including covariates — they can change power a lot.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.4 (power calculations for a difference of means)."
            )),
            .code(CodeSample(
                caption: "Power for a continuous interaction",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                def significant_once(n, b_int, rng):
                    x, w = rng.normal(size=n), rng.normal(size=n)
                    y = 0.3 * x + 0.1 * w + b_int * x * w + rng.normal(size=n)
                    d = pd.DataFrame({"x": x, "w": w, "y": y})
                    return smf.ols("y ~ x * w", data=d).fit().pvalues["x:w"] < 0.05

                rng = np.random.default_rng(7)
                for n in [150, 250, 350, 450]:
                    print(f"n = {n}: power ≈ {np.mean([significant_once(n, 0.15, rng) for _ in range(1000)]):.2f}")
                """#,
                r: #"""
                library(pwr)

                # Formula approach for one regression term: f² = ΔR² / (1 − R²)
                pwr.f2.test(u = 1, f2 = 0.025, sig.level = 0.05, power = 0.80)   # v = n − k − 1

                # Simulation approach (works for any design)
                significant_once <- function(n, b_int) {
                  x <- rnorm(n); w <- rnorm(n)
                  y <- 0.3 * x + 0.1 * w + b_int * x * w + rnorm(n)
                  summary(lm(y ~ x * w))$coefficients["x:w", "Pr(>|t|)"] < 0.05
                }
                set.seed(7)
                sapply(c(150, 250, 350, 450), function(n) mean(replicate(1000, significant_once(n, 0.15))))
                """#
            )),
            .terms([
                Term("Power", "Probability of detecting an effect that truly exists; 1 − the Type II error rate."),
                Term("Cohen's f²", "Effect size for a regression term: ΔR² / (1 − R²). 0.02 small, 0.15 medium, 0.35 large."),
                Term("Interim analysis", "Looking at the data before reaching the planned maximum sample size."),
                Term("Sequential design", "A plan with interim looks and stricter thresholds at each look, so the overall false-positive rate stays at α."),
                Term("Alpha spending", "Distributing the total α across looks. O'Brien–Fleming-type spending uses very little α early."),
                Term("Information fraction", "The share of the maximum sample available at an interim look (e.g. 100 / 200 = 0.5)."),
            ]),
            .caution("Peeking inflates false positives", "Testing at α = .05 at an interim look *and* again at the end gives a real false-positive rate well above 5%. Sequential designs fix this by using stricter, pre-planned thresholds."),
            .code(CodeSample(
                caption: "See the inflation, then plan proper boundaries",
                python: #"""
                from scipy import stats

                def false_positive_rate(n1, n2, alpha1, alpha2, sims=5000, seed=3):
                    rng = np.random.default_rng(seed)
                    hits = 0
                    for _ in range(sims):
                        x, y = rng.normal(size=n2), rng.normal(size=n2)   # no true relationship
                        p1 = stats.pearsonr(x[:n1], y[:n1]).pvalue
                        p2 = stats.pearsonr(x, y).pvalue
                        hits += (p1 < alpha1) or (p2 < alpha2)
                    return hits / sims

                print("naive .05 / .05:              ", false_positive_rate(100, 200, 0.05, 0.05))
                print("Pocock .0294 / .0294:          ", false_positive_rate(100, 200, 0.0294, 0.0294))
                print("O'Brien–Fleming .0052 / .0480: ", false_positive_rate(100, 200, 0.0052, 0.0480))
                """#,
                r: #"""
                library(rpact)

                # One interim look halfway, then the final analysis
                design <- getDesignGroupSequential(
                  kMax = 2, alpha = 0.05, sided = 2,
                  informationRates = c(0.5, 1),
                  typeOfDesign = "asOF"          # O'Brien–Fleming-type alpha spending
                )
                summary(design)   # two-sided local significance levels at each stage
                """#
            )),
            .keyPoint("Preregister the plan", "Write down the maximum N, when interim looks happen, the threshold at each look, and what you'll do at each (stop for efficacy, or continue). Report the design and the look at which you stopped."),
            .exercise(Exercise(
                title: "Find the N",
                prompt: "Using the interaction simulation, find the smallest n (in steps of 50) that reaches 80% power for b_int = 0.15. Then try b_int = 0.10.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    def smallest_n(b_int, start, sims=1000):
                        for n in range(start, 3001, 50):
                            power = np.mean([significant_once(n, b_int, rng) for _ in range(sims)])
                            if power >= 0.80:
                                return n

                    n_015 = smallest_n(0.15, start=200)
                    n_010 = smallest_n(0.10, start=500)
                    print(n_015, n_010)
                    """#,
                    r: #"""
                    smallest_n <- function(b_int, start, sims = 1000) {
                      for (n in seq(start, 3000, by = 50)) {
                        if (mean(replicate(sims, significant_once(n, b_int))) >= 0.80) return(n)
                      }
                    }
                    set.seed(7)
                    n_015 <- smallest_n(0.15, start = 200)
                    n_010 <- smallest_n(0.10, start = 500)
                    c(n_015, n_010)
                    """#
                ),
                answer: "For 0.15, power crosses .80 somewhere around n = 350. For 0.10 you need roughly twice as many — power scales with the **square** of the effect size.",
                selfCheck: SelfCheck(
                    names: "`n_015` and `n_010` — the smallest n with 80% power for b_int = 0.15 and 0.10",
                    python: #"""
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Formula check: n ≈ (z₀.₉₇₅ + z₀.₈₀)² / f² + k + 1, where f² = b² here (x, w, and the error
                        # all have variance 1) and k = 3 predictors. Simulated answers land within about ±50.
                        def formula_n(b):
                            return (stats.norm.ppf(0.975) + stats.norm.ppf(0.80)) ** 2 / b ** 2 + 4

                        print(f"formula: {formula_n(0.15):.0f} and {formula_n(0.10):.0f}")
                        check("n for b_int = 0.15", n_015, formula_n(0.15), tol=0.2,
                              hint="Use 1,000+ simulations per n so power estimates aren't too noisy.")
                        check("n for b_int = 0.10", n_010, formula_n(0.10), tol=0.15)
                        check("Smaller effect needs about (0.15 / 0.10)² = 2.25× the sample", n_010 / n_015, 2.25, tol=0.15)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Formula check: n ≈ (z₀.₉₇₅ + z₀.₈₀)² / f² + k + 1, where f² = b² here (x, w, and the error
                      # all have variance 1) and k = 3 predictors. Simulated answers land within about ±50.
                      formula_n <- function(b) (qnorm(0.975) + qnorm(0.80))^2 / b^2 + 4
                      cat(sprintf("formula: %.0f and %.0f\n", formula_n(0.15), formula_n(0.10)))
                      check("n for b_int = 0.15", n_015, formula_n(0.15), tol = 0.2,
                            hint = "Use 1,000+ simulations per n so power estimates aren't too noisy.")
                      check("n for b_int = 0.10", n_010, formula_n(0.10), tol = 0.15)
                      check("Smaller effect needs about (0.15 / 0.10)² = 2.25× the sample", n_010 / n_015, 2.25, tol = 0.15)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "You test at p < .05 halfway through data collection and again at the end. The overall false-positive rate is…",
                options: ["Exactly 5%", "Below 5%", "Above 5%", "Exactly 10%"],
                answer: 2,
                explanation: "Two chances to cross .05 inflate the error rate (to about 8% with equally spaced looks)."
            ),
            Question(
                prompt: "Why base a power analysis on the smallest effect size of interest?",
                options: ["It gives the smallest sample", "Published effects are often inflated, and you want to detect effects that matter", "Software requires it", "It guarantees significance"],
                answer: 1,
                explanation: "Planning on an inflated estimate leaves the study underpowered."
            ),
        ]
    )
}

// MARK: - Unit 4 · Comparing groups

extension Curriculum {
    static let ancova = Lesson(
        id: "ancova",
        title: "ANCOVA & contrast coding",
        summary: "Comparing groups while adjusting for a baseline, and choosing what each coefficient compares.",
        minutes: 13,
        blocks: [
            .text("In a randomized experiment with a baseline measure — students tested before and after a teaching method — the standard analysis is **ANCOVA** (analysis of covariance): compare post-test scores across groups while adjusting for the pre-test. Because randomization already balances the groups on average, the covariate's job is to **remove noise**, which increases power."),
            .model(ModelExplainer(
                name: "ANCOVA as a regression",
                purpose: "Estimates differences between group means on an outcome, adjusted for one or more continuous covariates.",
                equation: "posttest = b₀ + b₁·active + b₂·flipped + b₃·pretest + e",
                steps: [
                    "The group variable becomes k − 1 **indicator (dummy) variables**: here `active` and `flipped`, with lecture as the reference.",
                    "The covariate enters as a slope (b₃): how much the post-test rises per point of pre-test, *within* each group.",
                    "Each group coefficient (b₁, b₂) is the **adjusted mean difference** from the reference group: the gap expected between two students with the same pre-test.",
                    "Least squares estimates all coefficients at once; t-tests on b₁ and b₂ test the group differences, and an F-test tests all groups together.",
                ],
                conditions: [
                    "**Independence** of observations (e.g. one row per student).",
                    "**Linearity** between the covariate and the outcome in each group.",
                    "**Homogeneity of regression slopes** — the covariate's slope is similar across groups (check with a group × covariate interaction).",
                    "**Nearly normal residuals with constant variance**, as in any regression.",
                    "The covariate is measured **before** the treatment, so the treatment can't have affected it.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.5 (ANOVA) and §9.1 (multiple regression with categorical predictors)."
            )),
            .chart(ChartExample(
                title: "ANCOVA: parallel lines, one per group",
                kind: .ancovaLines,
                reading: [
                    "Each dot is a student: pre-test score on the x-axis, post-test on the y-axis, colored by teaching method.",
                    "The lines share one slope — how much the post-test rises per pre-test point — and differ only in height.",
                    "The **vertical gap between lines** is the adjusted group difference: how much higher a student would score with that method compared with a student who had the same pre-test.",
                    "Hover at any pre-test score to read each method's predicted post-test. If the lines clearly needed different slopes, a single adjusted difference would be misleading.",
                ]
            )),
            .code(CodeSample(
                caption: "Does active learning raise post-test scores more than lecture?",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf

                classroom = pd.read_csv("classroom.csv")
                methods = ["lecture", "active", "flipped"]
                classroom["method"] = pd.Categorical(classroom["method"], categories=methods)   # first = reference

                m = smf.ols("posttest ~ C(method) + pretest + C(school)", data=classroom).fit()
                print(m.summary())

                # Homogeneity of slopes: does the pretest slope differ by method?
                check = smf.ols("posttest ~ C(method) * pretest + C(school)", data=classroom).fit()
                print(check.compare_f_test(m))     # (F, p, df): a large p means slopes are similar
                """#,
                r: #"""
                library(tidyverse)
                library(emmeans)

                classroom <- read_csv("classroom.csv") |>
                  mutate(method = factor(method, levels = c("lecture", "active", "flipped")))

                m <- lm(posttest ~ method + pretest + school, data = classroom)
                summary(m)

                # Homogeneity of slopes: does the pretest slope differ by method?
                anova(m, lm(posttest ~ method * pretest + school, data = classroom))

                # Adjusted means and all pairwise comparisons
                emmeans(m, pairwise ~ method)
                """#
            )),
            .terms([
                Term("Covariate", "A variable adjusted for in the model, here the pre-test."),
                Term("Adjusted mean", "A group's predicted mean at the average value of the covariate(s)."),
                Term("Treatment (dummy) coding", "Each indicator compares one group with a reference group. R and Python's default."),
                Term("Sum (deviation) coding", "Each coefficient compares a group with the **grand mean** of all groups — useful when no group is a natural reference."),
                Term("Planned contrast", "A specific, pre-specified comparison (e.g. active vs. the average of the other two)."),
                Term("One-tailed test", "Tests one pre-specified direction only (e.g. active > lecture). Legitimate only when the direction was declared in advance."),
            ]),
            .code(CodeSample(
                caption: "Change what the coefficients compare",
                python: #"""
                # A different reference group
                m_flip = smf.ols("posttest ~ C(method, Treatment('flipped')) + pretest + C(school)", data=classroom).fit()

                # Sum coding: each coefficient compares a method with the grand mean
                m_sum = smf.ols("posttest ~ C(method, Sum) + pretest + C(school)", data=classroom).fit()
                print(m_sum.params.filter(like="method"))

                # One-tailed p for H1: active > lecture
                name = "C(method)[T.active]"
                b, p_two = m.params[name], m.pvalues[name]
                print("one-tailed p:", p_two / 2 if b > 0 else 1 - p_two / 2)
                """#,
                r: #"""
                # A different reference group
                m_flip <- lm(posttest ~ relevel(method, ref = "flipped") + pretest + school, data = classroom)

                # Sum coding: each coefficient compares a method with the grand mean
                m_sum <- lm(posttest ~ method + pretest + school, data = classroom,
                            contrasts = list(method = "contr.sum"))
                coef(m_sum)

                # One-tailed p for H1: active > lecture
                t_val <- coef(summary(m))["methodactive", "t value"]
                pt(t_val, df = m$df.residual, lower.tail = FALSE)
                """#
            )),
            .keyPoint("Why ANCOVA beats change scores", "Analyzing post − pre assumes the pre-test predicts the post-test with a slope of exactly 1. ANCOVA *estimates* that slope from the data, so in randomized studies it's at least as precise — and usually more (Vickers & Altman, 2001; Van Breukelen, 2006). In non-randomized comparisons the two can disagree, and neither is automatically right."),
            .caution("One-tailed tests are a commitment", "If the effect turns out in the *opposite* direction, a one-tailed test can't call it significant. Use them only when the direction was preregistered."),
            .exercise(Exercise(
                title: "ANCOVA vs. post-only vs. change scores",
                prompt: "Estimate the active-vs-lecture difference three ways: post-test only, change score (post − pre), and ANCOVA. Compare the standard errors.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    classroom["change"] = classroom["posttest"] - classroom["pretest"]
                    ests, ses = [], []
                    for formula in ["posttest ~ C(method)", "change ~ C(method)", "posttest ~ C(method) + pretest"]:
                        fit = smf.ols(formula, data=classroom).fit()
                        ests.append(fit.params[name])
                        ses.append(fit.bse[name])
                        print(formula, round(fit.params[name], 2), round(fit.bse[name], 2))
                    """#,
                    r: #"""
                    classroom <- classroom |> mutate(change = posttest - pretest)
                    ests <- c(); ses <- c()
                    for (f in c("posttest ~ method", "change ~ method", "posttest ~ method + pretest")) {
                      row <- coef(summary(lm(as.formula(f), data = classroom)))["methodactive", ]
                      ests <- c(ests, row[["Estimate"]])
                      ses  <- c(ses, row[["Std. Error"]])
                    }
                    round(rbind(ests, ses), 2)
                    """#
                ),
                answer: "All three estimates are around +4 points (0.4 SD), but ANCOVA has the smallest standard error. Change scores beat post-only here because pre and post correlate highly, yet still lose to ANCOVA.",
                selfCheck: SelfCheck(
                    names: "`ests` and `ses` — the active-vs-lecture estimate and its SE, in the order post-only, change score, ANCOVA",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("classroom.csv")
                        ref["active"] = (ref["method"] == "active").astype(int)
                        ref["flipped"] = (ref["method"] == "flipped").astype(int)
                        ref["change"] = ref["posttest"] - ref["pretest"]
                        fits = [smf.ols(f, data=ref).fit() for f in
                                ["posttest ~ active + flipped", "change ~ active + flipped", "posttest ~ active + flipped + pretest"]]
                        check("Estimates: post-only, change, ANCOVA", ests, [f.params["active"] for f in fits], tol=0.001,
                              hint="Lecture should be the reference group.")
                        check("SEs: post-only, change, ANCOVA", ses, [f.bse["active"] for f in fits], tol=0.001)
                        check("ANCOVA has the smallest SE", int(np.argmin(ses)), 2, tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("classroom.csv")
                      ref$active  <- as.integer(ref$method == "active")
                      ref$flipped <- as.integer(ref$method == "flipped")
                      ref$change  <- ref$posttest - ref$pretest
                      fits <- list(lm(posttest ~ active + flipped, ref), lm(change ~ active + flipped, ref),
                                   lm(posttest ~ active + flipped + pretest, ref))
                      check("Estimates: post-only, change, ANCOVA", ests, sapply(fits, function(f) coef(f)[["active"]]),
                            tol = 0.001, hint = "Lecture should be the reference group.")
                      check("SEs: post-only, change, ANCOVA", ses,
                            sapply(fits, function(f) coef(summary(f))["active", "Std. Error"]), tol = 0.001)
                      check("ANCOVA has the smallest SE", which.min(ses), 3, tol = 0)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Randomization check",
                prompt: "Compare `pretest` means across methods. What does a non-significant difference tell you — and what doesn't it?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pingouin as pg
                    pre_means = classroom.groupby("method", observed=True)["pretest"].mean()
                    print(classroom.groupby("method", observed=True)["pretest"].agg(["mean", "std", "count"]))
                    aov = pg.anova(data=classroom, dv="pretest", between="method")
                    p_pre = aov["p-unc"].iloc[0]
                    print(aov)
                    """#,
                    r: #"""
                    pre_means <- classroom |> group_by(method) |> summarise(mean = mean(pretest), sd = sd(pretest), n = n())
                    pre_means
                    fit <- summary(aov(pretest ~ method, data = classroom))
                    p_pre <- fit[[1]][["Pr(>F)"]][1]
                    fit
                    """#
                ),
                answer: "The means are similar. With random assignment any baseline differences are chance by definition, so the check is descriptive — you adjust for the pre-test because it's prognostic, not because a test told you to.",
                selfCheck: SelfCheck(
                    names: "`pre_means` (mean pretest per method — in R, a `mean` column) and `p_pre` (the ANOVA p-value)",
                    python: #"""
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("classroom.csv")
                        for method in ["lecture", "active", "flipped"]:
                            check(f"Mean pretest, {method}", pre_means[method], ref.loc[ref["method"] == method, "pretest"].mean())
                        groups = [g["pretest"] for _, g in ref.groupby("method")]
                        check("ANOVA p-value", p_pre, stats.f_oneway(*groups).pvalue, tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("classroom.csv")
                      for (m in c("lecture", "active", "flipped")) {
                        check(paste("Mean pretest,", m), with(pre_means, mean[method == m]),
                              mean(ref$pretest[ref$method == m]))
                      }
                      check("ANOVA p-value", p_pre, oneway.test(pretest ~ method, data = ref, var.equal = TRUE)$p.value,
                            tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "In a randomized pre/post design, why include the pre-test as a covariate?",
                options: ["To fix failed randomization", "It removes baseline noise and increases power", "It's required for one-tailed tests", "It changes what's being estimated"],
                answer: 1,
                explanation: "Randomization already makes groups comparable on average; the covariate reduces residual variance."
            ),
            Question(
                prompt: "A factor `school` with 4 levels enters the model as…",
                options: ["1 variable", "3 indicator variables", "4 indicator variables", "16 interaction terms"],
                answer: 1,
                explanation: "k − 1 indicators compared with the reference level."
            ),
            Question(
                prompt: "With sum (deviation) coding, a group's coefficient compares it with…",
                options: ["The reference group", "The grand mean of all groups", "Zero", "The largest group"],
                answer: 1,
                explanation: "Treatment coding compares with a reference; sum coding with the grand mean."
            ),
        ]
    )
}

// MARK: - Unit 5 · Relationships

extension Curriculum {
    static let betweenWithin = Lesson(
        id: "between-within",
        title: "Between- and within-person correlations",
        summary: "When people are measured repeatedly, “are X and Y related?” is two different questions.",
        minutes: 14,
        blocks: [
            .text("In a daily diary study, each person reports their work hours and wellbeing for 14 days. Two different questions hide inside “are work hours related to wellbeing?”\n\n• **Between-person:** do people who *usually* work longer have higher or lower wellbeing than people who usually work less?\n• **Within-person:** on days when someone works *more than they usually do*, is their wellbeing higher or lower than on their typical days?\n\nThe answers can differ — even in sign. Correlating all 1,400 rows mixes the two and answers neither."),
            .model(ModelExplainer(
                name: "Decomposing a repeated predictor",
                purpose: "Separates a predictor that varies over occasions into a person-level average (between) and daily deviations from that average (within), so each relationship gets its own estimate.",
                equation: "wellbeingᵢⱼ = b₀ + b_W·(hoursᵢⱼ − mean_hoursᵢ) + b_B·(mean_hoursᵢ − grand mean) + uᵢ + eᵢⱼ",
                steps: [
                    "Compute each person's mean on the predictor (`mean_hoursᵢ`).",
                    "**Within component:** subtract each person's own mean from each of their days (person-mean centering). It's 0 on a typical day for that person.",
                    "**Between component:** the person mean itself (grand-mean centered).",
                    "Fit a multilevel model with both components and a random intercept uᵢ for each person. b_W is the within-person slope; b_B is the between-person slope.",
                    "Simpler descriptive versions: correlate the person means (between), and compute a **repeated-measures correlation** or per-person correlations (within).",
                ],
                conditions: [
                    "**Enough occasions per person** for stable person means and within-person slopes (with very few occasions, within-person estimates are noisy).",
                    "**Enough people** for the between-person estimate — it's effectively based on n = number of people, not number of rows.",
                    "**Linearity** of each relationship, and residuals roughly normal with constant variance.",
                    "Watch for **time trends** (e.g. wellbeing drifting over the study); add day as a predictor if needed.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §8.1 (correlation); Curran & Bauer (2011), *Annual Review of Psychology*, 62, 583–619; Bakdash & Marusich (2017), *Frontiers in Psychology*, 8, 456 (repeated-measures correlation)."
            )),
            .chart(ChartExample(
                title: "Two relationships in the same data",
                kind: .betweenWithin,
                reading: [
                    "Gray dots are individual days; each person's days form a small cloud.",
                    "Each blue line is one person's **within-person** slope: on days they work more than usual, wellbeing is lower, so the lines slope **down**.",
                    "Orange dots are each person's averages, and the dashed orange line is the **between-person** relationship: people who usually work more report *higher* average wellbeing, so it slopes **up**.",
                    "A single correlation of all the dots mixes the two and describes neither — that's why repeated-measures data need both components.",
                ]
            )),
            .code(CodeSample(
                caption: "Pooled, between-person, and within-person correlations",
                python: #"""
                import numpy as np
                import pandas as pd
                import pingouin as pg

                diary = pd.read_csv("diary.csv")

                # 1. Pooled: every day as if independent (misleading)
                print("pooled r:", diary["work_hours"].corr(diary["wellbeing"]))

                # 2. Between-person: correlate each person's averages
                means = diary.groupby("participant")[["work_hours", "wellbeing"]].mean()
                print("between-person r:", means["work_hours"].corr(means["wellbeing"]))

                # 3. Within-person: repeated-measures correlation (one common slope, person-specific intercepts)
                print(pg.rm_corr(data=diary, x="work_hours", y="wellbeing", subject="participant"))

                # 3b. Two-stage alternative: one correlation per person, Fisher-z averaged
                per_person = diary.groupby("participant")[["work_hours", "wellbeing"]].apply(
                    lambda g: g["work_hours"].corr(g["wellbeing"]))
                print("mean within-person r:", np.tanh(np.arctanh(per_person.clip(-0.999, 0.999)).mean()))
                """#,
                r: #"""
                library(tidyverse)
                library(rmcorr)

                diary <- read_csv("diary.csv")

                # 1. Pooled: every day as if independent (misleading)
                cor(diary$work_hours, diary$wellbeing)

                # 2. Between-person: correlate each person's averages
                means <- diary |> group_by(participant) |>
                  summarise(work_hours = mean(work_hours), wellbeing = mean(wellbeing))
                cor.test(means$work_hours, means$wellbeing)

                # 3. Within-person: repeated-measures correlation
                rmcorr(participant, work_hours, wellbeing, diary)

                # 3b. Two-stage alternative: one correlation per person, Fisher-z averaged
                per_person <- diary |> group_by(participant) |> summarise(r = cor(work_hours, wellbeing))
                tanh(mean(atanh(per_person$r)))
                """#
            )),
            .code(CodeSample(
                caption: "Both components in one multilevel model",
                python: #"""
                import statsmodels.formula.api as smf

                diary["hours_mean"] = diary.groupby("participant")["work_hours"].transform("mean")
                diary["hours_within"] = diary["work_hours"] - diary["hours_mean"]
                diary["hours_between"] = diary["hours_mean"] - diary["hours_mean"].mean()

                m = smf.mixedlm("wellbeing ~ hours_within + hours_between", data=diary,
                                groups=diary["participant"], re_formula="~hours_within").fit()
                print(m.summary())
                """#,
                r: #"""
                library(lmerTest)

                diary <- diary |>
                  group_by(participant) |>
                  mutate(hours_mean = mean(work_hours), hours_within = work_hours - hours_mean) |>
                  ungroup() |>
                  mutate(hours_between = hours_mean - mean(hours_mean))

                m <- lmer(wellbeing ~ hours_within + hours_between + (1 + hours_within | participant), data = diary)
                summary(m)
                """#
            )),
            .terms([
                Term("Between-person relationship", "How people's *average* levels of X and Y relate across people."),
                Term("Within-person relationship", "How *changes* in X relate to changes in Y within the same person."),
                Term("Person-mean centering", "Subtracting each person's own mean, leaving only within-person variation."),
                Term("Repeated-measures correlation (rmcorr)", "A within-person correlation with one common slope and a separate intercept for each person."),
                Term("Ecological fallacy", "Assuming a between-group (or between-person) relationship holds within individuals."),
                Term("Simpson's paradox", "A relationship that reverses when data are pooled across groups."),
            ]),
            .caution("Don't correlate all the rows", "The pooled correlation is a blend of the between- and within-person relationships and treats 1,400 days as 1,400 independent people. It can be near zero, or even have the wrong sign, when the two components disagree."),
            .exercise(Exercise(
                title: "Find the paradox",
                prompt: "Compare the signs of the pooled, between-person, and within-person correlations. How would you describe the pattern in plain language?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    r_pooled = diary["work_hours"].corr(diary["wellbeing"])
                    r_between = means["work_hours"].corr(means["wellbeing"])
                    r_within = pg.rm_corr(data=diary, x="work_hours", y="wellbeing", subject="participant")["r"].iloc[0]
                    print(round(r_pooled, 2), round(r_between, 2), round(r_within, 2))
                    """#,
                    r: #"""
                    r_pooled  <- cor(diary$work_hours, diary$wellbeing)
                    r_between <- cor(means$work_hours, means$wellbeing)
                    r_within  <- rmcorr(participant, work_hours, wellbeing, diary)$r
                    round(c(pooled = r_pooled, between = r_between, within = r_within), 2)
                    """#
                ),
                answer: "Between-person r is **positive** (people who usually work longer report higher wellbeing), while within-person r is **negative** (on days someone works more than usual, they feel worse). The pooled r lands somewhere in between, which is misleading about both.",
                selfCheck: SelfCheck(
                    names: "`r_pooled`, `r_between`, and `r_within`",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("diary.csv")
                        person = ref.groupby("participant")[["work_hours", "wellbeing"]]
                        # The repeated-measures correlation equals the correlation of person-mean-centered scores.
                        centered = ref[["work_hours", "wellbeing"]] - person.transform("mean")
                        check("Pooled r", r_pooled, ref["work_hours"].corr(ref["wellbeing"]))
                        check("Between-person r", r_between, person.mean().corr().iloc[0, 1],
                              hint="Correlate the 100 person means, not the 1,400 days.")
                        check("Within-person r", r_within, centered["work_hours"].corr(centered["wellbeing"]),
                              hint="Use a repeated-measures correlation (pg.rm_corr).")
                        check("Between-person r is positive", r_between > 0, True)
                        check("Within-person r is negative", r_within < 0, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("diary.csv")
                      pm <- aggregate(cbind(work_hours, wellbeing) ~ participant, data = ref, FUN = mean)
                      # The repeated-measures correlation equals the correlation of person-mean-centered scores.
                      centered_x <- ref$work_hours - ave(ref$work_hours, ref$participant)
                      centered_y <- ref$wellbeing - ave(ref$wellbeing, ref$participant)
                      check("Pooled r", r_pooled, cor(ref$work_hours, ref$wellbeing))
                      check("Between-person r", r_between, cor(pm$work_hours, pm$wellbeing),
                            hint = "Correlate the 100 person means, not the 1,400 days.")
                      check("Within-person r", r_within, cor(centered_x, centered_y),
                            hint = "Use a repeated-measures correlation (rmcorr).")
                      check("Between-person r is positive", r_between > 0, TRUE)
                      check("Within-person r is negative", r_within < 0, TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Does personality change the daily link?",
                prompt: "Add a **cross-level interaction**: does conscientiousness (a person-level trait) change the within-person slope of work hours?",
                hint: "Center conscientiousness and add `hours_within * consc_c` to the model.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    diary["consc_c"] = diary["conscientiousness"] - diary.groupby("participant")["conscientiousness"].first().mean()
                    m2 = smf.mixedlm("wellbeing ~ hours_within * consc_c + hours_between", data=diary,
                                     groups=diary["participant"], re_formula="~hours_within").fit()
                    b_cross = m2.params["hours_within:consc_c"]
                    print(m2.params[["hours_within", "hours_within:consc_c"]])
                    """#,
                    r: #"""
                    diary <- diary |> mutate(consc_c = conscientiousness - mean(conscientiousness))
                    m2 <- lmer(wellbeing ~ hours_within * consc_c + hours_between +
                                 (1 + hours_within | participant), data = diary)
                    b_cross <- fixef(m2)[["hours_within:consc_c"]]
                    summary(m2)
                    """#
                ),
                answer: "The interaction is **negative**: for more conscientious people, extra hours are followed by an even bigger dip in wellbeing. Cross-level interactions are how multilevel models test whether a person-level variable moderates a within-person relationship.",
                selfCheck: SelfCheck(
                    names: "`b_cross` — the `hours_within:consc_c` coefficient",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("diary.csv")
                        ref["hours_mean"] = ref.groupby("participant")["work_hours"].transform("mean")
                        ref["hours_within"] = ref["work_hours"] - ref["hours_mean"]
                        ref["hours_between"] = ref["hours_mean"] - ref["hours_mean"].mean()
                        ref["consc_c"] = ref["conscientiousness"] - ref["conscientiousness"].mean()
                        fit = smf.mixedlm("wellbeing ~ hours_within * consc_c + hours_between", data=ref,
                                          groups=ref["participant"], re_formula="~hours_within").fit()
                        check("Cross-level interaction", b_cross, fit.params["hours_within:consc_c"], tol=0.01,
                              hint="Use person-mean-centered hours (hours_within) and centered conscientiousness.")
                        check("The interaction is negative", b_cross < 0, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("diary.csv")
                      ref$hours_mean    <- ave(ref$work_hours, ref$participant)
                      ref$hours_within  <- ref$work_hours - ref$hours_mean
                      ref$hours_between <- ref$hours_mean - mean(ref$hours_mean)
                      ref$consc_c       <- ref$conscientiousness - mean(ref$conscientiousness)
                      fit <- lmer(wellbeing ~ hours_within * consc_c + hours_between + (1 + hours_within | participant),
                                  data = ref)
                      check("Cross-level interaction", b_cross, fixef(fit)[["hours_within:consc_c"]], tol = 0.01,
                            hint = "Use person-mean-centered hours (hours_within) and centered conscientiousness.")
                      check("The interaction is negative", b_cross < 0, TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Plot both relationships",
                prompt: "Make two panels: (1) person means of hours vs. wellbeing with a regression line, (2) person-mean-centered hours vs. wellbeing with one thin line per person.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import seaborn as sns
                    import matplotlib.pyplot as plt
                    fig, axes = plt.subplots(1, 2, figsize=(9, 3.8))
                    sns.regplot(data=means, x="work_hours", y="wellbeing", ax=axes[0], color="#0072B2")
                    axes[0].set_title("Between people")
                    sns.lineplot(data=diary, x="hours_within", y="wellbeing", units="participant", estimator=None,
                                 color="0.7", linewidth=0.5, ax=axes[1])
                    sns.regplot(data=diary, x="hours_within", y="wellbeing", scatter=False, ax=axes[1], color="#D55E00")
                    axes[1].set_title("Within people")
                    plt.tight_layout(); plt.show()
                    """#,
                    r: #"""
                    library(patchwork)
                    p1 <- ggplot(means, aes(work_hours, wellbeing)) + geom_point() +
                      geom_smooth(method = "lm", colour = "#0072B2") + labs(title = "Between people")
                    p2 <- ggplot(diary, aes(hours_within, wellbeing)) +
                      geom_smooth(aes(group = participant), method = "lm", se = FALSE, colour = "grey75", linewidth = 0.3) +
                      geom_smooth(method = "lm", colour = "#D55E00") + labs(title = "Within people")
                    p1 + p2
                    """#
                ),
                answer: "The left panel slopes upward; the right panel's overall line slopes downward, with most individual lines also sloping down."
            )),
        ],
        quiz: [
            Question(
                prompt: "People who exercise more on average sleep better (between-person). Can you conclude that a given person sleeps better on days they exercise more?",
                options: ["Yes, always", "No — that's a within-person question that needs within-person data", "Only if r > .5", "Only for large samples"],
                answer: 1,
                explanation: "Assuming otherwise is the ecological fallacy."
            ),
            Question(
                prompt: "To isolate within-person variation in a daily predictor, you…",
                options: ["Standardize it across all rows", "Subtract each person's own mean", "Average it across people", "Log-transform it"],
                answer: 1,
                explanation: "Person-mean centering removes between-person differences."
            ),
            Question(
                prompt: "100 people each report 14 days. The between-person correlation is based on an effective n of about…",
                options: ["1,400", "100", "14", "7"],
                answer: 1,
                explanation: "There are only 100 person means."
            ),
        ]
    )
}

// MARK: - Unit 7 · Measurement & multilevel models

extension Curriculum {
    static let mixedLogistic = Lesson(
        id: "mixed-logistic",
        title: "Mixed logistic regression",
        summary: "Binary outcomes repeated across participants and items.",
        minutes: 11,
        blocks: [
            .text("Accuracy, yes/no choices, and other binary outcomes are often collected many times per participant and per item. A **mixed (multilevel) logistic regression** combines logistic regression with the random effects of a mixed model."),
            .model(ModelExplainer(
                name: "Generalized linear mixed model (binomial)",
                purpose: "Models the probability of a binary outcome as a function of predictors, while letting participants and items differ in their baseline probability.",
                equation: "logit(P(correctᵢⱼ = 1)) = b₀ + b₁·complexᵢⱼ + uᵢ (participant) + wⱼ (item)",
                steps: [
                    "Like logistic regression, the model works on the **log-odds** scale, so predictions always translate back to probabilities between 0 and 1.",
                    "Each participant gets a random intercept uᵢ and each item a random intercept wⱼ, both drawn from normal distributions whose SDs are estimated.",
                    "Fixed effects (b₀, b₁) describe a *typical* participant responding to a *typical* item.",
                    "The intercept on its own tests whether the probability differs from .50 (log-odds 0) when predictors are 0 — useful for questions like “is accuracy above chance?”",
                ],
                conditions: [
                    "**Binary outcome** for each trial, with trials coded 0/1.",
                    "**Independence after accounting for the random effects** — everything shared within participants and items is in u and w.",
                    "**Linearity in the logit** for continuous predictors.",
                    "**Enough data per cluster**; with many all-correct participants or items, estimates can hit boundaries — simplify or use a Bayesian model.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.5 (logistic regression); Winter (2019), *Statistics for Linguists*, chs. 12–15."
            )),
            .code(CodeSample(
                caption: "Comprehension accuracy by sentence structure",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.api as sm
                import statsmodels.formula.api as smf
                from statsmodels.genmod.bayes_mixed_glm import BinomialBayesMixedGLM

                judgments = pd.read_csv("judgments.csv")

                # Population-average model with cluster-robust SEs (participants as clusters)
                gee = smf.gee("correct ~ C(structure, Treatment('simple'))", groups="participant",
                              data=judgments, family=sm.families.Binomial()).fit()
                print(gee.summary())

                # Crossed random intercepts for participants and items (variational Bayes)
                glmm = BinomialBayesMixedGLM.from_formula(
                    "correct ~ C(structure, Treatment('simple'))",
                    {"participant": "0 + C(participant)", "item": "0 + C(item)"}, judgments).fit_vb()
                print(glmm.summary())
                """#,
                r: #"""
                library(tidyverse)
                library(lme4)

                judgments <- read_csv("judgments.csv") |>
                  mutate(structure = factor(structure, levels = c("simple", "complex")))

                m <- glmer(correct ~ structure + (1 | participant) + (1 | item),
                           data = judgments, family = binomial)
                summary(m)
                plogis(fixef(m)[1])          # accuracy for simple sentences
                exp(fixef(m)["structurecomplex"])   # odds ratio for complex vs. simple
                """#
            )),
            .terms([
                Term("Log-odds (logit)", "log(p / (1 − p)). 0 ↔ p = .50; positive ↔ p > .50."),
                Term("Inverse logit (plogis)", "Converts log-odds back to a probability: 1 / (1 + e^−x)."),
                Term("GEE", "Generalized estimating equations: population-average effects with cluster-robust standard errors."),
                Term("Conditional vs. marginal effects", "Mixed models describe a *typical* participant and item; GEE describes the *population average*. For logistic models, conditional effects are usually a bit larger."),
            ]),
            .caution("Don't analyze percent correct with ANOVA", "Averaging accuracy per participant and running an ANOVA can predict impossible values and produce spurious effects (Jaeger, 2008). Model the trials directly."),
            .exercise(Exercise(
                title: "Is accuracy above chance?",
                prompt: "Fit an intercept-only mixed logistic model of `correct` with random intercepts for participants and items. Convert the intercept to a probability. Is accuracy reliably above 50%?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    gee0 = smf.gee("correct ~ 1", groups="participant", data=judgments, family=sm.families.Binomial()).fit()
                    acc = 1 / (1 + np.exp(-gee0.params["Intercept"]))
                    print(acc, gee0.pvalues["Intercept"])
                    """#,
                    r: #"""
                    m0 <- glmer(correct ~ 1 + (1 | participant) + (1 | item), data = judgments, family = binomial)
                    summary(m0)$coefficients
                    acc <- plogis(fixef(m0)[["(Intercept)"]])
                    acc
                    """#
                ),
                answer: "Accuracy is around 75–80%, and the intercept is far above 0 (p < .001), so performance is clearly above chance.",
                selfCheck: SelfCheck(
                    names: "`acc` — the intercept converted to a probability",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # With an intercept-only GEE, the estimate is simply the overall proportion correct.
                        ref = pd.read_csv("judgments.csv")
                        check("Accuracy (a probability, not log-odds)", acc, ref["correct"].mean(), tol=0.001,
                              hint="Convert log-odds with 1 / (1 + exp(−b)).")
                        check("Accuracy is above chance (.50)", acc > 0.5, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("judgments.csv")
                      fit <- glmer(correct ~ 1 + (1 | participant) + (1 | item), data = ref, family = binomial)
                      check("Accuracy for a typical participant and item", acc, plogis(fixef(fit)[[1]]), tol = 0.001,
                            hint = "Convert log-odds with plogis().")
                      check("Accuracy is above chance (.50)", acc > 0.5, TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Clustering and standard errors",
                prompt: "Fit the structure model as a plain logistic regression and compare the SE of the structure effect with the mixed model's.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    plain = smf.logit("correct ~ C(structure, Treatment('simple'))", data=judgments).fit(disp=False)
                    term = "C(structure, Treatment('simple'))[T.complex]"
                    se_plain, se_clustered = plain.bse[term], gee.bse[term]
                    print(se_plain, se_clustered)
                    """#,
                    r: #"""
                    plain <- glm(correct ~ structure, data = judgments, family = binomial)
                    se_plain <- coef(summary(plain))["structurecomplex", "Std. Error"]
                    se_clustered <- coef(summary(m))["structurecomplex", "Std. Error"]
                    rbind(plain = coef(summary(plain))[2, 1:2], mixed = coef(summary(m))[2, 1:2])
                    """#
                ),
                answer: "The plain model's standard errors are smaller (it treats all 1,280 trials as independent), and its estimate is slightly closer to 0 than the mixed model's conditional estimate.",
                selfCheck: SelfCheck(
                    names: "`se_plain` and `se_clustered` — the SE of the complex-vs-simple effect in the plain model and in the GEE (Python) or mixed model (R)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("judgments.csv")
                        X = sm.add_constant((ref["structure"] == "complex").astype(float).rename("complex"))
                        plain_ref = sm.Logit(ref["correct"], X).fit(disp=False)
                        gee_ref = sm.GEE(ref["correct"], X, groups=ref["participant"], family=sm.families.Binomial()).fit()
                        check("SE, plain logistic", se_plain, plain_ref.bse["complex"], tol=0.001)
                        check("SE, clustered (GEE)", se_clustered, gee_ref.bse["complex"], tol=0.001,
                              hint="Use participants as the GEE groups.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("judgments.csv")
                      ref$complex <- as.integer(ref$structure == "complex")
                      plain_ref <- glm(correct ~ complex, data = ref, family = binomial)
                      mixed_ref <- glmer(correct ~ complex + (1 | participant) + (1 | item), data = ref, family = binomial)
                      check("SE, plain logistic", se_plain, coef(summary(plain_ref))["complex", "Std. Error"], tol = 0.001)
                      check("SE, mixed model", se_clustered, coef(summary(mixed_ref))["complex", "Std. Error"], tol = 0.001,
                            hint = "Include random intercepts for both participants and items.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A mixed logistic intercept is 1.2 on the log-odds scale. Approximately what accuracy is that?",
                options: ["55%", "70%", "77%", "92%"],
                answer: 2,
                explanation: "plogis(1.2) ≈ .77."
            ),
            Question(
                prompt: "Why add random intercepts for items in an accuracy study?",
                options: ["To increase accuracy", "Items differ in difficulty, and you want conclusions that generalize beyond these items", "lme4 requires it", "To remove outliers"],
                answer: 1,
                explanation: "Ignoring item variation inflates false positives."
            ),
        ]
    )

    static let interRater = Lesson(
        id: "inter-rater",
        title: "Inter-rater reliability",
        summary: "Agreement between raters, and consistency of repeated ratings.",
        minutes: 13,
        blocks: [
            .text("Whenever people make judgments — scoring essays, rating behavior, classifying responses — you need evidence that the scores reflect what's being rated rather than who did the rating. Have two or more raters independently score the same cases, then quantify their agreement **beyond chance**."),
            .model(ModelExplainer(
                name: "Chance-corrected agreement and the ICC",
                purpose: "κ and Krippendorff's α measure how much raters agree beyond what chance would produce; the intraclass correlation (ICC) measures how much of the variation in scores reflects real differences between the cases being rated.",
                equation: "κ = (p_observed − p_chance) / (1 − p_chance)\nICC(agreement) = σ²_cases / (σ²_cases + σ²_raters + σ²_error)",
                steps: [
                    "**κ:** compare the observed proportion of agreements with the proportion expected if raters assigned categories at random with their own base rates. Weighted κ gives partial credit for near-misses on ordered scales.",
                    "**Krippendorff's α:** the same idea generalized to any number of raters, missing ratings, and nominal, ordinal, or interval data.",
                    "**ICC:** fit a model that splits score variance into cases, raters, and error. An *absolute-agreement* ICC counts systematic rater differences (one rater scoring higher) as error; a *consistency* ICC ignores them.",
                    "Report the version that matches how scores will be used: if raters' scores will be compared or swapped, you need absolute agreement.",
                ],
                conditions: [
                    "**Independent ratings** — raters don't see each other's scores.",
                    "**The same cases** rated by each rater (or a design that handles missing ratings, e.g. Krippendorff's α).",
                    "**A level of measurement that matches the statistic:** unweighted κ / nominal α for categories, weighted κ / ordinal α for ordered scales, ICC for continuous scores.",
                    "Enough cases (often 50+) and enough variation in what's being rated — if nearly everything gets the same score, chance-corrected agreement becomes unstable.",
                ],
                reading: "Hallgren (2012), *Tutorials in Quantitative Methods for Psychology*, 8(1), 23–34; Koo & Li (2016), *Journal of Chiropractic Medicine*, 15(2), 155–163; Hayes & Krippendorff (2007), *Communication Methods and Measures*, 1(1), 77–89."
            )),
            .chart(ChartExample(
                title: "An agreement table for two raters",
                kind: .agreementTable,
                reading: [
                    "Each cell counts essays that rater A (rows) and rater B (columns) scored a particular way.",
                    "The **diagonal** (green) holds exact agreements; cells next to it are one-point disagreements.",
                    "Most of the counts sit on or just right of the diagonal: the raters mostly agree, and B tends to score a little higher.",
                    "Weighted κ and ordinal α give partial credit for those near-diagonal cells; unweighted κ counts only the diagonal.",
                ]
            )),
            .code(CodeSample(
                caption: "Two raters' essay scores",
                python: #"""
                # pip install krippendorff scikit-learn
                import numpy as np
                import pandas as pd
                import krippendorff
                import pingouin as pg
                from sklearn.metrics import cohen_kappa_score

                essays = pd.read_csv("essays.csv")
                a, b = essays["rater_a"], essays["rater_b"]

                print(pd.crosstab(a, b))
                print("exact agreement:", (a == b).mean(), " within 1 point:", ((a - b).abs() <= 1).mean())
                print("Cohen's kappa:", cohen_kappa_score(a, b))
                print("weighted kappa:", cohen_kappa_score(a, b, weights="quadratic"))
                print("Krippendorff's alpha (ordinal):",
                      krippendorff.alpha(reliability_data=np.vstack([a, b]).astype(float), level_of_measurement="ordinal"))

                long = essays.melt(id_vars="essay", value_vars=["rater_a", "rater_b"], var_name="rater", value_name="score")
                print(pg.intraclass_corr(data=long, targets="essay", raters="rater", ratings="score"))
                """#,
                r: #"""
                library(irr)

                essays <- read.csv("essays.csv")
                scores <- essays[, c("rater_a", "rater_b")]

                table(scores$rater_a, scores$rater_b)
                agree(scores)                              # exact agreement
                agree(scores, tolerance = 1)               # within 1 point
                kappa2(scores)                             # Cohen's kappa
                kappa2(scores, weight = "squared")         # weighted kappa
                kripp.alpha(t(as.matrix(scores)), method = "ordinal")

                icc(scores, model = "twoway", type = "agreement", unit = "single")
                icc(scores, model = "twoway", type = "consistency", unit = "single")
                """#
            )),
            .terms([
                Term("Exact / adjacent agreement", "Share of cases where raters give the same score / scores within one point."),
                Term("Cohen's κ", "Chance-corrected agreement for two raters."),
                Term("Weighted κ", "κ for ordered categories, with partial credit for near-misses."),
                Term("Krippendorff's α", "Chance-corrected agreement for any number of raters, missing data, and any measurement level. Krippendorff (2004) recommends α ≥ .80, with .667–.80 acceptable only for tentative conclusions."),
                Term("ICC (absolute agreement)", "Reliability that treats systematic rater differences as error."),
                Term("ICC (consistency)", "Reliability that ignores constant differences between raters."),
                Term("Test–retest reliability", "Agreement of the same rater (or measure) with itself over time."),
            ]),
            .keyPoint("A rating workflow", "1. Write a clear scoring guide with examples.\n2. Train raters and pilot on a small set; revise ambiguous rules.\n3. Rate independently, blind to hypotheses and to anything about the cases that could bias judgments.\n4. Compute reliability against thresholds set in advance.\n5. Resolve disagreements (discussion or a third rater) and report both the reliability and how disagreements were settled."),
            .caution("Rare categories punish agreement", "When nearly every case gets the same score, raters agree often by chance alone. κ and α correct for this, which is why they can look low next to high percent agreement."),
            .exercise(Exercise(
                title: "Consistency vs. agreement",
                prompt: "Compare the consistency and absolute-agreement ICCs. Why do they differ, and what does the mean of `rater_b − rater_a` show?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    icc = pg.intraclass_corr(data=long, targets="essay", raters="rater", ratings="score").set_index("Type")["ICC"]
                    icc_agree, icc_cons = icc["ICC2"], icc["ICC3"]       # two-way: absolute agreement, consistency
                    mean_diff = (essays["rater_b"] - essays["rater_a"]).mean()
                    print(icc_agree, icc_cons, mean_diff)
                    """#,
                    r: #"""
                    icc_agree <- icc(scores, model = "twoway", type = "agreement", unit = "single")$value
                    icc_cons  <- icc(scores, model = "twoway", type = "consistency", unit = "single")$value
                    mean_diff <- mean(essays$rater_b - essays$rater_a)
                    c(icc_agree, icc_cons, mean_diff)
                    """#
                ),
                answer: "Rater B scores about 0.3 points higher on average. That systematic difference lowers the absolute-agreement ICC but not the consistency ICC. If one rater's scores might replace the other's, use absolute agreement.",
                selfCheck: SelfCheck(
                    names: "`icc_agree` and `icc_cons` (two-way, single-rater ICCs) and `mean_diff` (mean of B − A)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Two-way ANOVA mean squares: rows = essays (targets), columns = raters.
                        Y = pd.read_csv("essays.csv")[["rater_a", "rater_b"]].to_numpy(float)
                        n, k = Y.shape
                        gm = Y.mean()
                        ms_rows = k * ((Y.mean(axis=1) - gm) ** 2).sum() / (n - 1)
                        ms_cols = n * ((Y.mean(axis=0) - gm) ** 2).sum() / (k - 1)
                        ss_err = ((Y - gm) ** 2).sum() - ms_rows * (n - 1) - ms_cols * (k - 1)
                        ms_err = ss_err / ((n - 1) * (k - 1))
                        check("ICC, absolute agreement", icc_agree,
                              (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err + k * (ms_cols - ms_err) / n), tol=0.002,
                              hint="Absolute agreement is pingouin's ICC2 (irr: type = 'agreement').")
                        check("ICC, consistency", icc_cons, (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err), tol=0.002,
                              hint="Consistency is pingouin's ICC3 (irr: type = 'consistency').")
                        check("Mean of B − A", mean_diff, Y[:, 1].mean() - Y[:, 0].mean())
                        check("Agreement ICC is lower than consistency ICC", icc_agree < icc_cons, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Two-way ANOVA mean squares: rows = essays (targets), columns = raters.
                      Y <- as.matrix(read.csv("essays.csv")[, c("rater_a", "rater_b")])
                      n <- nrow(Y); k <- ncol(Y); gm <- mean(Y)
                      ms_rows <- k * sum((rowMeans(Y) - gm)^2) / (n - 1)
                      ms_cols <- n * sum((colMeans(Y) - gm)^2) / (k - 1)
                      ms_err  <- (sum((Y - gm)^2) - ms_rows * (n - 1) - ms_cols * (k - 1)) / ((n - 1) * (k - 1))
                      check("ICC, absolute agreement", icc_agree,
                            (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err + k * (ms_cols - ms_err) / n), tol = 0.002)
                      check("ICC, consistency", icc_cons, (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err), tol = 0.002)
                      check("Mean of B − A", mean_diff, mean(Y[, 2]) - mean(Y[, 1]))
                      check("Agreement ICC is lower than consistency ICC", icc_agree < icc_cons, TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Test–retest reliability",
                prompt: "How consistent is rater A with themselves two weeks later? Compute the ICC (and weighted κ) for `rater_a` vs. `rater_a_retest`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    wkappa = cohen_kappa_score(essays["rater_a"], essays["rater_a_retest"], weights="quadratic")
                    retest = essays.melt(id_vars="essay", value_vars=["rater_a", "rater_a_retest"],
                                         var_name="occasion", value_name="score")
                    icc_retest = pg.intraclass_corr(data=retest, targets="essay", raters="occasion",
                                                    ratings="score").set_index("Type").loc["ICC2", "ICC"]
                    print(wkappa, icc_retest)
                    """#,
                    r: #"""
                    wkappa <- kappa2(essays[, c("rater_a", "rater_a_retest")], weight = "squared")$value
                    icc_retest <- icc(essays[, c("rater_a", "rater_a_retest")], model = "twoway", type = "agreement")$value
                    c(wkappa, icc_retest)
                    """#
                ),
                answer: "High (around .7–.8): the rater is fairly stable over time. Test–retest reliability is the right check when you need scores to be repeatable, not just consistent across raters.",
                selfCheck: SelfCheck(
                    names: "`wkappa` (quadratic-weighted κ) and `icc_retest` (two-way, absolute-agreement ICC)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("essays.csv")
                        a, b = ref["rater_a"].to_numpy(), ref["rater_a_retest"].to_numpy()
                        # Weighted κ = 1 − Σ w·observed / Σ w·expected, with weights (i − j)² between categories.
                        cats = np.unique(np.r_[a, b])
                        obs = np.array([[np.mean((a == i) & (b == j)) for j in cats] for i in cats])
                        exp = np.outer(obs.sum(axis=1), obs.sum(axis=0))
                        w = np.subtract.outer(np.arange(len(cats)), np.arange(len(cats))) ** 2
                        check("Weighted κ", wkappa, 1 - (w * obs).sum() / (w * exp).sum(), tol=0.002,
                              hint="Use quadratic weights.")
                        # Absolute-agreement ICC from two-way ANOVA mean squares
                        Y = np.c_[a, b].astype(float)
                        n, k = Y.shape
                        gm = Y.mean()
                        ms_rows = k * ((Y.mean(axis=1) - gm) ** 2).sum() / (n - 1)
                        ms_cols = n * ((Y.mean(axis=0) - gm) ** 2).sum() / (k - 1)
                        ms_err = (((Y - gm) ** 2).sum() - ms_rows * (n - 1) - ms_cols * (k - 1)) / ((n - 1) * (k - 1))
                        check("ICC, absolute agreement", icc_retest,
                              (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err + k * (ms_cols - ms_err) / n), tol=0.002)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("essays.csv")
                      a <- ref$rater_a; b <- ref$rater_a_retest
                      # Weighted κ = 1 − Σ w·observed / Σ w·expected, with weights (i − j)² between categories.
                      cats <- sort(unique(c(a, b)))
                      obs <- table(factor(a, cats), factor(b, cats)) / length(a)
                      expd <- outer(rowSums(obs), colSums(obs))
                      w <- outer(seq_along(cats), seq_along(cats), function(i, j) (i - j)^2)
                      check("Weighted κ", wkappa, 1 - sum(w * obs) / sum(w * expd), tol = 0.002,
                            hint = "Use squared (quadratic) weights.")
                      # Absolute-agreement ICC from two-way ANOVA mean squares
                      Y <- cbind(a, b); n <- nrow(Y); k <- 2; gm <- mean(Y)
                      ms_rows <- k * sum((rowMeans(Y) - gm)^2) / (n - 1)
                      ms_cols <- n * sum((colMeans(Y) - gm)^2) / (k - 1)
                      ms_err  <- (sum((Y - gm)^2) - ms_rows * (n - 1) - ms_cols * (k - 1)) / ((n - 1) * (k - 1))
                      check("ICC, absolute agreement", icc_retest,
                            (ms_rows - ms_err) / (ms_rows + (k - 1) * ms_err + k * (ms_cols - ms_err) / n), tol = 0.002)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Three raters score the same cases, and a few scores are missing. Which statistic fits best?",
                options: ["Percent agreement", "Cohen's κ", "Krippendorff's α", "Pearson's r"],
                answer: 2,
                explanation: "Krippendorff's α handles any number of raters and missing ratings."
            ),
            Question(
                prompt: "Rater B always scores one point higher than rater A, but otherwise they agree perfectly. Which ICC is high?",
                options: ["Absolute agreement only", "Consistency only", "Both", "Neither"],
                answer: 1,
                explanation: "Consistency ignores constant offsets; absolute agreement doesn't."
            ),
            Question(
                prompt: "Why compute reliability **before** resolving disagreements?",
                options: ["Resolved scores agree by construction, so reliability would be meaningless", "It's faster", "Resolution lowers α", "Software requires it"],
                answer: 0,
                explanation: "Reliability measures independent agreement."
            ),
        ]
    )
}

import Foundation

// MARK: - Practice labs (OpenIntro data) — each lab sits at the end of the unit it practices

extension Curriculum {
    /// The final review covers methods from every unit, so it comes after the advanced units.
    static let capstoneReview = Unit(
        id: "capstone-review", number: 13, title: "Capstone review", level: .advanced,
        summary: "Match any research design to the right analysis.",
        symbol: "checkmark.seal",
        lessons: [whichTest]
    )

    static let hsb2Lab = Lesson(
        id: "lab-hsb2",
        title: "Lab: High School & Beyond",
        summary: "Descriptives, t-tests, ANOVA, and chi-square on real student test scores.",
        minutes: 25,
        blocks: [
            .text("**hsb2** contains 200 students sampled from the *High School and Beyond* survey (National Center for Education Statistics), with standardized scores in `read`, `write`, `math`, `science`, and `socst`, plus `gender`, `race`, `ses` (low/middle/high), `schtyp` (public/private), and `prog` (general/academic/vocational). The data come from **OpenIntro** (openintro.org), a free, openly licensed statistics textbook project."),
            .code(CodeSample(
                caption: "Load the data",
                python: #"""
                import pandas as pd
                import pingouin as pg
                from scipy import stats
                import statsmodels.formula.api as smf

                # openintro.org rejects Python's default user agent, so send a simple one
                hsb2 = pd.read_csv("https://www.openintro.org/data/csv/hsb2.csv", storage_options={"User-Agent": "pandas"})
                print(hsb2.head())
                """#,
                r: #"""
                # install.packages("openintro")
                library(openintro)
                library(tidyverse)

                glimpse(hsb2)
                """#
            )),
            .exercise(Exercise(
                title: "1 · Describe",
                prompt: "Report the n, mean, and SD of `read` for each gender.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    desc = hsb2.groupby("gender")["read"].agg(["count", "mean", "std"])
                    desc.round(2)
                    """#,
                    r: #"""
                    desc <- hsb2 |> group_by(gender) |> summarise(n = n(), mean = mean(read), sd = sd(read))
                    desc
                    """#
                ),
                answer: "There are slightly more female than male students; mean reading scores are close (around 52) with SDs near 10.",
                selfCheck: SelfCheck(
                    names: "`desc` — one row per gender with the count, mean, and SD (Python columns `count`, `mean`, `std`; R columns `n`, `mean`, `sd`)",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        for g in ["female", "male"]:
                            x = hsb2.loc[hsb2["gender"] == g, "read"].to_numpy(float)
                            check(f"{g}: n", desc.loc[g, "count"], len(x), tol=0)
                            check(f"{g}: mean", desc.loc[g, "mean"], x.sum() / len(x))
                            check(f"{g}: SD", desc.loc[g, "std"], np.sqrt(((x - x.mean()) ** 2).sum() / (len(x) - 1)),
                                  tol=0.001, hint="Use the sample SD (n − 1).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      for (g in c("female", "male")) {
                        x <- hsb2$read[hsb2$gender == g]
                        row <- desc[desc$gender == g, ]
                        check(paste0(g, ": n"), row$n, length(x), tol = 0)
                        check(paste0(g, ": mean"), row$mean, sum(x) / length(x))
                        check(paste0(g, ": SD"), row$sd, sqrt(sum((x - mean(x))^2) / (length(x) - 1)), tol = 0.001)
                      }
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "2 · Two groups",
                prompt: "Do math scores differ by gender? Run a Welch t-test and report Cohen's d.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    res = pg.ttest(hsb2.loc[hsb2["gender"] == "female", "math"],
                                   hsb2.loc[hsb2["gender"] == "male", "math"], correction=True)   # Welch
                    t_welch, p_welch, d = res["T"].iloc[0], res["p-val"].iloc[0], res["cohen-d"].iloc[0]
                    res
                    """#,
                    r: #"""
                    tt <- t.test(math ~ gender, data = hsb2)
                    t_welch <- tt$statistic[[1]]
                    p_welch <- tt$p.value
                    d <- effectsize::cohens_d(math ~ gender, data = hsb2)$Cohens_d
                    tt
                    """#
                ),
                answer: "The difference is small and not significant (|d| < 0.1). Report it anyway — null results are informative.",
                selfCheck: SelfCheck(
                    names: "`t_welch`, `p_welch`, and `d` (Cohen's d)",
                    python: #"""
                    import numpy as np
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        f = hsb2.loc[hsb2["gender"] == "female", "math"]
                        m = hsb2.loc[hsb2["gender"] == "male", "math"]
                        welch = stats.ttest_ind(f, m, equal_var=False)
                        pooled_sd = np.sqrt(((len(f) - 1) * f.var() + (len(m) - 1) * m.var()) / (len(f) + len(m) - 2))
                        # The sign depends on which group comes first, so compare sizes.
                        check("|t| (Welch)", abs(t_welch), abs(welch.statistic), tol=0.001,
                              hint="Welch's test doesn't assume equal variances (equal_var=False).")
                        check("p-value (Welch)", p_welch, welch.pvalue, tol=0.001)
                        check("|d| (pooled SD)", abs(d), abs(f.mean() - m.mean()) / pooled_sd, tol=0.002)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      f <- hsb2$math[hsb2$gender == "female"]
                      m <- hsb2$math[hsb2$gender == "male"]
                      se <- sqrt(var(f) / length(f) + var(m) / length(m))
                      df <- se^4 / ((var(f) / length(f))^2 / (length(f) - 1) + (var(m) / length(m))^2 / (length(m) - 1))
                      t_ref <- (mean(f) - mean(m)) / se
                      pooled_sd <- sqrt(((length(f) - 1) * var(f) + (length(m) - 1) * var(m)) / (length(f) + length(m) - 2))
                      # The sign depends on which group comes first, so compare sizes.
                      check("|t| (Welch)", abs(t_welch), abs(t_ref), tol = 0.001)
                      check("p-value (Welch)", p_welch, 2 * pt(-abs(t_ref), df), tol = 0.001)
                      check("|d| (pooled SD)", abs(d), abs(mean(f) - mean(m)) / pooled_sd, tol = 0.002)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "3 · Three groups",
                prompt: "Do math scores differ across program types? Run a one-way ANOVA with Tukey post-hoc tests.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    aov = pg.anova(data=hsb2, dv="math", between="prog", detailed=True)
                    F_prog, p_prog = aov["F"].iloc[0], aov["p-unc"].iloc[0]
                    print(aov)
                    print(pg.pairwise_tukey(data=hsb2, dv="math", between="prog"))
                    """#,
                    r: #"""
                    fit <- aov(math ~ prog, data = hsb2)
                    F_prog <- summary(fit)[[1]][["F value"]][1]
                    p_prog <- summary(fit)[[1]][["Pr(>F)"]][1]
                    summary(fit)
                    TukeyHSD(fit)
                    """#
                ),
                answer: "There's a clear program effect: students in the academic program score highest, and both the general and vocational programs are significantly lower than academic.",
                selfCheck: SelfCheck(
                    names: "`F_prog` and `p_prog` (the one-way ANOVA F and p)",
                    python: #"""
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = stats.f_oneway(*[g["math"] for _, g in hsb2.groupby("prog")])
                        check("F", F_prog, ref.statistic, tol=0.001)
                        check("p-value", p_prog, ref.pvalue, tol=1e-6)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- oneway.test(math ~ prog, data = hsb2, var.equal = TRUE)
                      check("F", F_prog, ref$statistic[[1]], tol = 0.001)
                      check("p-value", p_prog, ref$p.value, tol = 1e-6)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "4 · Two categorical variables",
                prompt: "Is socioeconomic status associated with school type? Run a chi-square test and check the expected counts.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    table = pd.crosstab(hsb2["ses"], hsb2["schtyp"])
                    chi2, p, dof, expected = stats.chi2_contingency(table)
                    print(table, "\n", expected.round(1), "\n", chi2, p)
                    """#,
                    r: #"""
                    tab <- table(hsb2$ses, hsb2$schtyp)
                    test <- chisq.test(tab)
                    chi2 <- test$statistic[[1]]
                    p <- test$p.value
                    expected <- test$expected
                    test
                    expected
                    """#
                ),
                answer: "Private-school students lean toward higher SES, but with only 32 private-school students some expected counts are small — check them and interpret cautiously.",
                selfCheck: SelfCheck(
                    names: "`chi2`, `p`, and `expected` (the table of expected counts)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Expected count = row total × column total / N; χ² = Σ (observed − expected)² / expected
                        obs = pd.crosstab(hsb2["ses"], hsb2["schtyp"]).to_numpy(float)
                        exp_ref = np.outer(obs.sum(axis=1), obs.sum(axis=0)) / obs.sum()
                        chi2_ref = ((obs - exp_ref) ** 2 / exp_ref).sum()
                        df = (obs.shape[0] - 1) * (obs.shape[1] - 1)
                        check("Expected counts", np.sort(np.ravel(expected)), np.sort(exp_ref.ravel()), tol=0.001)
                        check("χ²", chi2, chi2_ref, tol=0.001)
                        check("p-value", p, stats.chi2.sf(chi2_ref, df), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Expected count = row total × column total / N; χ² = Σ (observed − expected)² / expected
                      obs <- table(hsb2$ses, hsb2$schtyp)
                      exp_ref <- outer(rowSums(obs), colSums(obs)) / sum(obs)
                      chi2_ref <- sum((obs - exp_ref)^2 / exp_ref)
                      df <- (nrow(obs) - 1) * (ncol(obs) - 1)
                      check("Expected counts", sort(as.vector(expected)), sort(as.vector(exp_ref)), tol = 0.001)
                      check("χ²", chi2, chi2_ref, tol = 0.001)
                      check("p-value", p, pchisq(chi2_ref, df, lower.tail = FALSE), tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: []
    )

    static let resumeLab = Lesson(
        id: "lab-resume",
        title: "Lab: Résumé callbacks",
        summary: "A real field experiment: proportions, chi-square, and logistic regression.",
        minutes: 25,
        blocks: [
            .text("In this field experiment, researchers sent 4,870 fictitious résumés to job ads in Boston and Chicago, **randomly assigning** names that signal race (`race`: black / white) and gender (`gender`: f / m). The outcome `received_callback` is 1 if the employer called back. Other columns include `years_experience`, `college_degree`, and `job_city`."),
            .code(CodeSample(
                caption: "Load the data",
                python: #"""
                import numpy as np
                import pandas as pd
                from scipy import stats
                import statsmodels.formula.api as smf

                # openintro.org rejects Python's default user agent, so send a simple one
                resume = pd.read_csv("https://www.openintro.org/data/csv/resume.csv", storage_options={"User-Agent": "pandas"})
                resume[["race", "gender", "years_experience", "received_callback"]].head()
                """#,
                r: #"""
                library(openintro)
                library(tidyverse)

                resume |> select(race, gender, years_experience, received_callback) |> head()
                """#
            )),
            .exercise(Exercise(
                title: "1 · Callback rates",
                prompt: "What share of résumés received a callback, overall and by race?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    overall = resume["received_callback"].mean()
                    by_race = resume.groupby("race")["received_callback"].mean()
                    print(overall, by_race, sep="\n")
                    """#,
                    r: #"""
                    overall <- mean(resume$received_callback)
                    by_race <- resume |> group_by(race) |> summarise(rate = mean(received_callback), n = n())
                    overall
                    by_race
                    """#
                ),
                answer: "About 8% overall: roughly 9.7% for white-sounding names vs. 6.4% for Black-sounding names.",
                selfCheck: SelfCheck(
                    names: "`overall` and `by_race` (the callback rate per race — in R, a `rate` column)",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        cb = resume["received_callback"]
                        check("Overall callback rate", overall, cb.sum() / len(cb), tol=0.001,
                              hint="A proportion, between 0 and 1.")
                        for race in ["black", "white"]:
                            group = cb[resume["race"] == race]
                            check(f"Callback rate, {race}", by_race[race], group.sum() / len(group), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      cb <- resume$received_callback
                      check("Overall callback rate", overall, sum(cb) / length(cb), tol = 0.001,
                            hint = "A proportion, between 0 and 1.")
                      for (r in c("black", "white")) {
                        group <- cb[resume$race == r]
                        check(paste("Callback rate,", r), by_race$rate[by_race$race == r], sum(group) / length(group),
                              tol = 0.001)
                      }
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "2 · Test the difference",
                prompt: "Is callback associated with race? Use a chi-square test and compute the odds ratio from the 2 × 2 table.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    table = pd.crosstab(resume["race"], resume["received_callback"])
                    chi2, p, dof, expected = stats.chi2_contingency(table)
                    odds = table[1] / table[0]
                    odds_ratio = odds["white"] / odds["black"]
                    print(table, "\nchi2 =", round(chi2, 2), "p =", p)
                    print("OR (white vs. black):", odds_ratio)
                    """#,
                    r: #"""
                    tab <- table(resume$race, resume$received_callback)
                    test <- chisq.test(tab)
                    chi2 <- test$statistic[[1]]
                    # Sample odds ratio: white relative to black (rows are black, white; columns are 0, 1)
                    odds_ratio <- (tab["white", "1"] / tab["white", "0"]) / (tab["black", "1"] / tab["black", "0"])
                    test
                    odds_ratio
                    """#
                ),
                answer: "χ² is significant (p < .001). White-sounding names have about 1.5 times the odds of a callback.",
                selfCheck: SelfCheck(
                    names: "`chi2` and `odds_ratio` (odds of a callback for white relative to Black names)",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        w = resume.loc[resume["race"] == "white", "received_callback"]
                        b = resume.loc[resume["race"] == "black", "received_callback"]
                        obs = np.array([[(b == 0).sum(), (b == 1).sum()], [(w == 0).sum(), (w == 1).sum()]], float)
                        exp_ref = np.outer(obs.sum(axis=1), obs.sum(axis=0)) / obs.sum()
                        # 2 × 2 tables get Yates' continuity correction by default in both SciPy and R
                        chi2_yates = ((np.abs(obs - exp_ref) - 0.5) ** 2 / exp_ref).sum()
                        check("χ² (with continuity correction)", chi2, chi2_yates, tol=0.001)
                        check("Odds ratio, white vs. Black", odds_ratio, (obs[1, 1] / obs[1, 0]) / (obs[0, 1] / obs[0, 0]),
                              tol=0.001, hint="Odds = callbacks / non-callbacks; then divide white odds by Black odds.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      w <- resume$received_callback[resume$race == "white"]
                      b <- resume$received_callback[resume$race == "black"]
                      obs <- rbind(c(sum(b == 0), sum(b == 1)), c(sum(w == 0), sum(w == 1)))
                      exp_ref <- outer(rowSums(obs), colSums(obs)) / sum(obs)
                      # 2 × 2 tables get Yates' continuity correction by default in both SciPy and R
                      chi2_yates <- sum((abs(obs - exp_ref) - 0.5)^2 / exp_ref)
                      check("χ² (with continuity correction)", chi2, chi2_yates, tol = 0.001)
                      check("Odds ratio, white vs. Black", odds_ratio, (obs[2, 2] / obs[2, 1]) / (obs[1, 2] / obs[1, 1]),
                            tol = 0.001, hint = "Odds = callbacks / non-callbacks; then divide white odds by Black odds.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "3 · Logistic regression",
                prompt: "Fit `received_callback ~ race + gender + years_experience` and report odds ratios with 95% CIs.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    m = smf.logit("received_callback ~ C(race) + C(gender) + years_experience", data=resume).fit()
                    or_race = np.exp(m.params["C(race)[T.white]"])
                    or_race_ci = np.exp(m.conf_int().loc["C(race)[T.white]"]).to_numpy()
                    print(pd.concat([np.exp(m.params), np.exp(m.conf_int())], axis=1).round(3))
                    """#,
                    r: #"""
                    m <- glm(received_callback ~ race + gender + years_experience, data = resume, family = binomial)
                    or_race <- exp(coef(m)[["racewhite"]])
                    or_race_ci <- exp(confint(m)["racewhite", ])   # profile-likelihood CI
                    exp(cbind(OR = coef(m), confint(m)))
                    """#
                ),
                answer: "The race effect stays about the same after adjustment (OR ≈ 1.5 for white-sounding names). Each additional year of experience modestly increases the odds of a callback.",
                selfCheck: SelfCheck(
                    names: "`or_race` (the odds ratio for white vs. Black names) and `or_race_ci` (its 95% CI)",
                    python: #"""
                    import numpy as np
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        X = sm.add_constant(np.column_stack([(resume["race"] == "white").astype(float),
                                                             (resume["gender"] == "m").astype(float),
                                                             resume["years_experience"]]))
                        fit = sm.Logit(resume["received_callback"].to_numpy(), X).fit(disp=False)
                        b, se = fit.params[1], fit.bse[1]
                        check("Odds ratio (exp of the coefficient)", or_race, np.exp(b), tol=0.001,
                              hint="Exponentiate the log-odds coefficient.")
                        check("95% CI, exp(b ± 1.96 SE)", or_race_ci, np.exp(b + np.array([-1, 1]) * 1.959964 * se), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- data.frame(y = resume$received_callback, white = as.integer(resume$race == "white"),
                                        male = as.integer(resume$gender == "m"), years = resume$years_experience)
                      fit <- glm(y ~ white + male + years, data = ref, family = binomial)
                      check("Odds ratio (exp of the coefficient)", or_race, exp(coef(fit)[["white"]]), tol = 0.001,
                            hint = "Exponentiate the log-odds coefficient.")
                      # R's confint() on a glm uses profile likelihood, so recompute it the same way
                      check("95% CI (profile likelihood)", or_race_ci, exp(confint(fit)["white", ]), tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "4 · Interaction",
                prompt: "Does the race gap differ by gender? Add `race * gender`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    mi = smf.logit("received_callback ~ C(race) * C(gender) + years_experience", data=resume).fit()
                    term = "C(race)[T.white]:C(gender)[T.m]"
                    b_int, p_int = mi.params[term], mi.pvalues[term]
                    mi.summary()
                    """#,
                    r: #"""
                    mi <- glm(received_callback ~ race * gender + years_experience, data = resume, family = binomial)
                    b_int <- coef(mi)[["racewhite:genderm"]]
                    p_int <- summary(mi)$coefficients["racewhite:genderm", "Pr(>|z|)"]
                    summary(mi)
                    """#
                ),
                answer: "The interaction isn't significant: there's no strong evidence that the race gap differs between female and male names, though this design has limited power for interactions.",
                selfCheck: SelfCheck(
                    names: "`b_int` and `p_int` — the race × gender interaction coefficient and its p-value",
                    python: #"""
                    import numpy as np
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        white = (resume["race"] == "white").astype(float)
                        male = (resume["gender"] == "m").astype(float)
                        X = sm.add_constant(np.column_stack([white, male, white * male, resume["years_experience"]]))
                        fit = sm.Logit(resume["received_callback"].to_numpy(), X).fit(disp=False)
                        check("Interaction coefficient (log-odds)", b_int, fit.params[3], tol=0.001)
                        check("Its p-value", p_int, fit.pvalues[3], tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- data.frame(y = resume$received_callback, white = as.integer(resume$race == "white"),
                                        male = as.integer(resume$gender == "m"), years = resume$years_experience)
                      fit <- glm(y ~ white * male + years, data = ref, family = binomial)
                      check("Interaction coefficient (log-odds)", b_int, coef(fit)[["white:male"]], tol = 0.001)
                      check("Its p-value", p_int, summary(fit)$coefficients["white:male", "Pr(>|z|)"], tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "5 · Why causal?",
                prompt: "Why can this study support a *causal* claim about names, when most observational data can't?",
                answer: "Names were **randomly assigned** to otherwise comparable résumés, so any systematic callback difference is attributable to the name rather than to differences in qualifications. That's the logic of random assignment."
            )),
        ],
        quiz: []
    )

    static let evalsLab = Lesson(
        id: "lab-evals",
        title: "Lab: Teaching evaluations",
        summary: "Correlation, regression, and interactions with real course evaluations.",
        minutes: 25,
        blocks: [
            .text("**evals** has end-of-semester evaluations for 463 courses taught by 94 professors at the University of Texas at Austin. `score` is the average evaluation (1–5), and `bty_avg` is the average of six students' ratings of the professor's physical appearance. Other columns include `gender`, `age`, `rank`, and `prof_id`."),
            .code(CodeSample(
                caption: "Load the data",
                python: #"""
                import pandas as pd
                import seaborn as sns
                import matplotlib.pyplot as plt
                import statsmodels.formula.api as smf

                # openintro.org rejects Python's default user agent, so send a simple one
                evals = pd.read_csv("https://www.openintro.org/data/csv/evals.csv", storage_options={"User-Agent": "pandas"})
                evals[["score", "bty_avg", "gender", "age", "rank", "prof_id"]].describe(include="all")
                """#,
                r: #"""
                library(openintro)
                library(tidyverse)

                evals |> select(score, bty_avg, gender, age, rank, prof_id) |> summary()
                """#
            )),
            .exercise(Exercise(
                title: "1 · Correlation & plot",
                prompt: "Plot `score` against `bty_avg` (jitter the points) and compute their correlation.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    sns.regplot(data=evals, x="bty_avg", y="score", x_jitter=0.1, y_jitter=0.05,
                                scatter_kws={"alpha": 0.4}, line_kws={"color": "#0072B2"})
                    plt.show()
                    r_bty = evals["score"].corr(evals["bty_avg"])
                    print(r_bty)
                    """#,
                    r: #"""
                    ggplot(evals, aes(bty_avg, score)) +
                      geom_jitter(alpha = 0.4) +
                      geom_smooth(method = "lm", colour = "#0072B2") +
                      theme_classic()
                    r_bty <- cor(evals$score, evals$bty_avg)
                    r_bty
                    """#
                ),
                answer: "A weak positive correlation (r ≈ .19). The jitter matters: without it, many points overlap because scores are rounded.",
                selfCheck: SelfCheck(
                    names: "`r_bty` — the correlation of `score` with `bty_avg`",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # r = covariance / (SD × SD) — jitter is for the plot only, never for the statistic
                        x, y = evals["bty_avg"].to_numpy(float), evals["score"].to_numpy(float)
                        r_ref = ((x - x.mean()) * (y - y.mean())).sum() / np.sqrt(((x - x.mean())**2).sum() * ((y - y.mean())**2).sum())
                        check("Correlation", r_bty, r_ref, tol=0.001, hint="Compute r on the raw (un-jittered) data.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # r = covariance / (SD × SD) — jitter is for the plot only, never for the statistic
                      x <- evals$bty_avg; y <- evals$score
                      check("Correlation", r_bty, sum((x - mean(x)) * (y - mean(y))) /
                              sqrt(sum((x - mean(x))^2) * sum((y - mean(y))^2)), tol = 0.001,
                            hint = "Compute r on the raw (un-jittered) data.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "2 · Simple regression",
                prompt: "Fit `score ~ bty_avg`. Interpret the slope and R².",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    m1 = smf.ols("score ~ bty_avg", data=evals).fit()
                    slope, r2 = m1.params["bty_avg"], m1.rsquared
                    print(m1.params, r2)
                    """#,
                    r: #"""
                    m1 <- lm(score ~ bty_avg, data = evals)
                    slope <- coef(m1)[["bty_avg"]]
                    r2 <- summary(m1)$r.squared
                    summary(m1)
                    """#
                ),
                answer: "Each one-point increase in rated appearance predicts about 0.07 points higher evaluation; R² ≈ .035, so appearance explains only a small share of the variation.",
                selfCheck: SelfCheck(
                    names: "`slope` and `r2`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # In simple regression, slope = r × SD(y) / SD(x) and R² = r²
                        r = evals["score"].corr(evals["bty_avg"])
                        check("Slope", slope, r * evals["score"].std() / evals["bty_avg"].std(), tol=0.001)
                        check("R²", r2, r ** 2, tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # In simple regression, slope = r × SD(y) / SD(x) and R² = r²
                      r <- cor(evals$score, evals$bty_avg)
                      check("Slope", slope, r * sd(evals$score) / sd(evals$bty_avg), tol = 0.001)
                      check("R²", r2, r^2, tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "3 · Moderation by gender",
                prompt: "Does the appearance–evaluation relationship differ for male and female professors? Fit `score ~ bty_avg * gender` and get the slope for each gender.",
                hint: "Refit with the other gender as the reference level to read its slope directly.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    m2 = smf.ols("score ~ bty_avg * C(gender)", data=evals).fit()
                    print(m2.summary().tables[1])
                    m2b = smf.ols("score ~ bty_avg * C(gender, Treatment('male'))", data=evals).fit()
                    slope_female, slope_male = m2.params["bty_avg"], m2b.params["bty_avg"]
                    print("slope for male professors:", slope_male)
                    """#,
                    r: #"""
                    m2 <- lm(score ~ bty_avg * gender, data = evals)
                    summary(m2)
                    m2b <- lm(score ~ bty_avg * relevel(gender, ref = "male"), data = evals)
                    slope_female <- coef(m2)[["bty_avg"]]
                    slope_male   <- coef(m2b)[["bty_avg"]]   # slope for male professors
                    slope_male
                    """#
                ),
                answer: "The slope is somewhat steeper for male professors; the interaction is borderline. Probing it by switching the reference level is the categorical version of the simple-slopes trick.",
                selfCheck: SelfCheck(
                    names: "`slope_female` and `slope_male`",
                    python: #"""
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # A fully interacted model gives each group the same slope as a separate regression per group.
                        for g, yours in [("female", slope_female), ("male", slope_male)]:
                            sub = evals[evals["gender"] == g]
                            check(f"Slope for {g} professors", yours,
                                  smf.ols("score ~ bty_avg", data=sub).fit().params["bty_avg"], tol=0.001,
                                  hint="Switch the reference level to read the other group's slope directly.")
                        check("Steeper for male professors", slope_male > slope_female, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # A fully interacted model gives each group the same slope as a separate regression per group.
                      for (g in c("female", "male")) {
                        yours <- if (g == "female") slope_female else slope_male
                        check(paste("Slope for", g, "professors"), yours,
                              coef(lm(score ~ bty_avg, data = evals[evals$gender == g, ]))[["bty_avg"]], tol = 0.001,
                              hint = "Switch the reference level to read the other group's slope directly.")
                      }
                      check("Steeper for male professors", slope_male > slope_female, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: []
    )

    static let whichTest = Lesson(
        id: "which-test",
        title: "Drill: which analysis?",
        summary: "Match research designs to the right method.",
        minutes: 10,
        blocks: [
            .text("Choosing the analysis comes down to four questions: **What type is the outcome?** (continuous, binary, ordinal, unordered categories) **How many groups or predictors?** **Are observations independent or clustered/repeated?** **Is there a third variable** that mediates or moderates?"),
            .terms([
                Term("Continuous outcome, 2 independent groups", "Welch t-test (or regression with one dummy)."),
                Term("Continuous outcome, same people twice", "Paired t-test."),
                Term("Continuous outcome, 3+ groups", "ANOVA / regression with dummies."),
                Term("Continuous outcome, pre/post randomized", "ANCOVA: post ~ condition + pre."),
                Term("Two categorical variables", "Chi-square (Fisher's exact for small counts)."),
                Term("Binary outcome", "Logistic regression; mixed logistic if clustered."),
                Term("Ordered outcome", "Cumulative link (ordinal) model; clmm if clustered."),
                Term("Unordered outcome", "Multinomial model; mixed multinomial if clustered."),
                Term("Repeated trials, participants and items", "Mixed model with crossed random effects."),
                Term("X → M → Y", "Mediation with a bootstrapped indirect effect."),
                Term("Does W change X → Y?", "Moderation: X × W interaction."),
                Term("Agreement between raters", "Cohen's κ (2 raters) or Krippendorff's α (any number); ICC for continuous scores."),
                Term("Finding hidden subgroups", "Latent class analysis (categorical indicators) or latent profile analysis (continuous indicators)."),
                Term("Same people measured repeatedly", "Separate between- and within-person effects; multilevel model with person-mean-centered predictors."),
                Term("Same people in 2+ conditions, one score per cell", "Repeated-measures ANOVA (mixed ANOVA if there's also a between-subject factor); a mixed model for trial-level data."),
                Term("Change over 3+ waves", "Growth model: mixed model with time and a random slope for time."),
                Term("Count outcome", "Poisson or negative binomial regression, with log(exposure) as an offset."),
                Term("Showing an effect is negligible", "Equivalence test (TOST) against a pre-specified smallest effect of interest."),
                Term("Many tests in one family", "Holm (family-wise error) or Benjamini–Hochberg (false discovery rate) adjustment."),
                Term("Validating a multi-item scale", "Confirmatory factor analysis, then measurement invariance before comparing groups."),
                Term("Causal effect from observational data", "Adjust for confounders chosen from a DAG (regression or propensity-score weighting); never for colliders."),
                Term("Values missing at random", "Multiple imputation or FIML, not listwise deletion."),
                Term("Weighted, clustered survey", "Survey weights with design-based standard errors (`survey` in R)."),
                Term("Combining published studies", "Random-effects meta-analysis, with heterogeneity and publication-bias checks."),
            ]),
        ],
        quiz: [
            Question(
                prompt: "Participants rate 30 sentences each for acceptability on a 1–7 scale; all participants see all sentences. Best model?",
                options: ["Independent t-test", "Ordinal mixed model with crossed random effects for participants and items", "Chi-square", "Simple correlation"],
                answer: 1,
                explanation: "Ordered ratings, repeated across participants and items, call for clmm with (1 | participant) + (1 | item)."
            ),
            Question(
                prompt: "A survey asks whether people voted (yes/no) and their age, income, and education. Best model?",
                options: ["Logistic regression", "ANOVA", "Paired t-test", "Linear regression on 0/1"],
                answer: 0,
                explanation: "Binary outcome with several predictors → logistic regression."
            ),
            Question(
                prompt: "You hypothesize that loneliness predicts depression *through* rumination. What do you test?",
                options: ["Interaction loneliness × rumination", "The indirect effect with a bootstrap CI", "A chi-square", "Cronbach's α"],
                answer: 1,
                explanation: "“Through” signals mediation."
            ),
            Question(
                prompt: "You hypothesize that social support weakens the link between stress and burnout. What do you test?",
                options: ["Mediation", "Moderation: stress × support", "A paired t-test", "Latent class analysis"],
                answer: 1,
                explanation: "“Weakens the link” signals moderation."
            ),
            Question(
                prompt: "Classrooms are randomized to three teaching methods, and test scores are measured before and after. Best primary analysis?",
                options: ["Three paired t-tests", "ANCOVA: post ~ arm + pre", "Chi-square on arm", "Correlation of pre and post"],
                answer: 1,
                explanation: "ANCOVA uses the baseline to reduce noise and compares arms in one model."
            ),
            Question(
                prompt: "Two teachers independently grade 200 essays into 6 rubric levels. What reliability statistic?",
                options: ["Pearson's r", "Cronbach's α", "Weighted κ or Krippendorff's α (ordinal)", "R²"],
                answer: 2,
                explanation: "Chance-corrected agreement for ordered categories (weighted κ or ordinal α)."
            ),
            Question(
                prompt: "Each patient contributes 5–10 clinic visits, and you want a 95% CI for the share of visits with high blood pressure. What should you do?",
                options: ["Use p ± 1.96√(p(1 − p)/n) over all visits", "Cluster bootstrap over patients", "Drop all but the first visit", "Report percentages without CIs"],
                answer: 1,
                explanation: "Visits are clustered within patients; resample patients."
            ),
            Question(
                prompt: "Survey respondents answer eight yes/no questions about health behaviors, and you want to discover recurring combinations without defining types in advance. Method?",
                options: ["Latent class analysis", "ANCOVA", "Paired t-test", "Keyness"],
                answer: 0,
                explanation: "LCA finds unobserved classes from categorical indicators."
            ),
            Question(
                prompt: "You count how many hedges (“sort of”, “I think”) appear in essays of very different lengths. Best model?",
                options: ["Linear regression on the counts", "Negative binomial regression with log(word count) as an offset", "Chi-square", "Paired t-test"],
                answer: 1,
                explanation: "Counts with varying exposure, usually overdispersed."
            ),
            Question(
                prompt: "Students who chose a mentoring program earn higher grades. To estimate the program's effect, you should…",
                options: [
                    "Compare the two groups' means",
                    "Adjust for pre-program confounders such as prior grades and motivation, chosen from a DAG",
                    "Adjust for everything measured after the program",
                    "Use a chi-square test",
                ],
                answer: 1,
                explanation: "Block the backdoor paths; don't adjust for post-treatment variables."
            ),
        ]
    )
}

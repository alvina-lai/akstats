import Foundation

// MARK: - Unit 12 · Real-world data & evidence

extension Curriculum {
    static let realWorld = Unit(
        id: "real-world", number: 12, title: "Real-world data & evidence", level: .advanced,
        summary: "Missing data, survey weights, causal inference, meta-analysis, and Bayesian inference.",
        symbol: "globe.americas",
        lessons: [missingData, surveyWeights, causalInference, metaAnalysis, bayesian]
    )

    /// The third practice-data script (missing, fillers, poll, tutoring, growth).
    static let extraDataSample = CodeSample(
        caption: "generate_extra_data — missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv",
        python: #"""
        # generate_extra_data.py — creates missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv
        import numpy as np
        import pandas as pd

        rng = np.random.default_rng(2028)


        def logistic(x):
            return 1 / (1 + np.exp(-x))


        # ---------- missing.csv: stressed people skip the wellbeing question ----------
        n = 500
        stress = rng.normal(0, 1, n)
        sleep = np.clip(7 - 0.5 * stress + rng.normal(0, 0.8, n), 3, 10).round(1)
        wellbeing_true = (4 - 0.6 * stress + 0.2 * (sleep - 7) + rng.normal(0, 0.7, n)).round(2)
        skipped = rng.random(n) < logistic(-1.4 + 1.2 * stress)     # missing at random, given stress
        pd.DataFrame({
            "id": np.arange(1, n + 1),
            "age": rng.integers(18, 70, n),
            "stress": stress.round(2),
            "sleep": sleep,
            "wellbeing": np.where(skipped, np.nan, wellbeing_true),
            "wellbeing_true": wellbeing_true,                        # the hidden truth, for checking only
        }).to_csv("missing.csv", index=False)

        # ---------- fillers.csv: "um"s and "uh"s in interviews of different lengths ----------
        n_f = 300
        minutes = rng.uniform(5, 15, n_f).round(1)
        evaluated = rng.integers(0, 2, n_f)                          # 1 = told the interview was being assessed
        l2 = (rng.random(n_f) < 0.4).astype(int)                     # 1 = speaking a second language
        age_f = rng.integers(18, 70, n_f)
        rate = 0.8 * 1.4 ** evaluated * 1.6 ** l2 * np.exp(-0.005 * (age_f - 40))   # fillers per minute
        pd.DataFrame({
            "speaker": np.arange(1, n_f + 1),
            "condition": np.where(evaluated == 1, "evaluated", "relaxed"),
            "l2": l2, "age": age_f, "minutes": minutes,
            "fillers": rng.poisson(minutes * rate * rng.gamma(3, 1 / 3, n_f)),    # extra-Poisson variation
        }).to_csv("fillers.csv", index=False)

        # ---------- poll.csv: a stratified cluster sample that oversamples rural towns ----------
        rows = []
        for town in range(1, 51):                                    # 25 urban + 25 rural towns, 20 people each
            region = "urban" if town <= 25 else "rural"
            town_effect = rng.normal(0, 0.5)
            age = rng.integers(18, 85, 20)
            p = logistic((0.4 if region == "urban" else -0.6) + town_effect - 0.01 * (age - 45))
            support = (rng.random(20) < p).astype(int)
            trust = np.clip(np.round(5 + 1.5 * support + town_effect + rng.normal(0, 2, 20)), 0, 10).astype(int)
            for i in range(20):
                rows.append({"region": region, "town": town, "age": age[i], "support": support[i], "trust": trust[i]})
        poll = pd.DataFrame(rows)
        poll.insert(0, "id", np.arange(1, len(poll) + 1))
        # Population: 700,000 urban and 300,000 rural adults; the poll interviewed 500 of each
        poll["weight"] = np.where(poll["region"] == "urban", 700_000 / 500, 300_000 / 500)
        poll.to_csv("poll.csv", index=False)

        # ---------- tutoring.csv: who chooses tutoring is not random ----------
        n_t = 800
        prior_gpa = np.clip(rng.normal(3.0, 0.5, n_t), 1.5, 4.0).round(2)
        motivation = rng.normal(0, 1, n_t).round(2)
        parent_degree = (rng.random(n_t) < 0.4).astype(int)
        tutoring = (rng.random(n_t) < logistic(-0.5 + 1.2 * motivation - 0.6 * (prior_gpa - 3)
                                               + 0.5 * parent_degree)).astype(int)
        exam = (62 + 10 * (prior_gpa - 3) + 6 * motivation + 3 * parent_degree + 5 * tutoring
                + rng.normal(0, 7, n_t)).round(1)                    # true tutoring effect: +5 points
        recommended = (rng.random(n_t) < logistic(-1 + 1.5 * tutoring + 0.12 * (exam - 62))).astype(int)   # a collider
        pd.DataFrame({
            "student": np.arange(1, n_t + 1), "prior_gpa": prior_gpa, "motivation": motivation,
            "parent_degree": parent_degree, "tutoring": tutoring, "exam": exam, "recommended": recommended,
        }).to_csv("tutoring.csv", index=False)

        # ---------- growth.csv: reading scores over 5 waves, with a randomized intervention ----------
        n_g = 250
        group = rng.permutation(np.repeat([0, 1], n_g // 2))         # 1 = reading intervention
        start = rng.normal(0, 8, n_g)                                 # each student's own starting level
        slope = rng.normal(0, 1.5, n_g) + 0.05 * start                # and their own growth rate
        rows = []
        for s in range(n_g):
            for wave in range(5):
                score = 100 + start[s] + (5 + 2 * group[s] + slope[s]) * wave + rng.normal(0, 4)
                rows.append({"student": s + 1, "group": "intervention" if group[s] else "control",
                             "wave": wave, "score": round(score, 1)})
        growth = pd.DataFrame(rows)
        growth = growth[rng.random(len(growth)) >= 0.08]             # about 8% of visits missed, at random
        growth.to_csv("growth.csv", index=False)

        print("Saved missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv")
        """#,
        r: #"""
        # generate_extra_data.R — creates missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv
        set.seed(2028)

        # ---------- missing.csv: stressed people skip the wellbeing question ----------
        n <- 500
        stress <- rnorm(n)
        sleep <- round(pmin(pmax(7 - 0.5 * stress + rnorm(n, sd = 0.8), 3), 10), 1)
        wellbeing_true <- round(4 - 0.6 * stress + 0.2 * (sleep - 7) + rnorm(n, sd = 0.7), 2)
        skipped <- runif(n) < plogis(-1.4 + 1.2 * stress)           # missing at random, given stress
        write.csv(data.frame(
          id = 1:n,
          age = sample(18:69, n, replace = TRUE),
          stress = round(stress, 2),
          sleep,
          wellbeing = ifelse(skipped, NA, wellbeing_true),
          wellbeing_true                                             # the hidden truth, for checking only
        ), "missing.csv", row.names = FALSE)

        # ---------- fillers.csv: "um"s and "uh"s in interviews of different lengths ----------
        n_f <- 300
        minutes   <- round(runif(n_f, 5, 15), 1)
        evaluated <- sample(0:1, n_f, replace = TRUE)                # 1 = told the interview was being assessed
        l2        <- as.integer(runif(n_f) < 0.4)                    # 1 = speaking a second language
        age_f     <- sample(18:69, n_f, replace = TRUE)
        rate <- 0.8 * 1.4^evaluated * 1.6^l2 * exp(-0.005 * (age_f - 40))   # fillers per minute
        write.csv(data.frame(
          speaker = 1:n_f,
          condition = ifelse(evaluated == 1, "evaluated", "relaxed"),
          l2, age = age_f, minutes,
          fillers = rnbinom(n_f, size = 3, mu = minutes * rate)      # extra-Poisson variation
        ), "fillers.csv", row.names = FALSE)

        # ---------- poll.csv: a stratified cluster sample that oversamples rural towns ----------
        poll <- do.call(rbind, lapply(1:50, function(town) {        # 25 urban + 25 rural towns, 20 people each
          region <- if (town <= 25) "urban" else "rural"
          town_effect <- rnorm(1, sd = 0.5)
          age <- sample(18:84, 20, replace = TRUE)
          p <- plogis(ifelse(region == "urban", 0.4, -0.6) + town_effect - 0.01 * (age - 45))
          support <- as.integer(runif(20) < p)
          trust <- pmin(pmax(round(5 + 1.5 * support + town_effect + rnorm(20, sd = 2)), 0), 10)
          data.frame(region, town, age, support, trust)
        }))
        poll <- cbind(id = seq_len(nrow(poll)), poll)
        # Population: 700,000 urban and 300,000 rural adults; the poll interviewed 500 of each
        poll$weight <- ifelse(poll$region == "urban", 700000 / 500, 300000 / 500)
        write.csv(poll, "poll.csv", row.names = FALSE)

        # ---------- tutoring.csv: who chooses tutoring is not random ----------
        n_t <- 800
        prior_gpa     <- round(pmin(pmax(rnorm(n_t, 3, 0.5), 1.5), 4), 2)
        motivation    <- round(rnorm(n_t), 2)
        parent_degree <- as.integer(runif(n_t) < 0.4)
        tutoring <- as.integer(runif(n_t) < plogis(-0.5 + 1.2 * motivation - 0.6 * (prior_gpa - 3) +
                                                   0.5 * parent_degree))
        exam <- round(62 + 10 * (prior_gpa - 3) + 6 * motivation + 3 * parent_degree + 5 * tutoring +
                      rnorm(n_t, sd = 7), 1)                         # true tutoring effect: +5 points
        recommended <- as.integer(runif(n_t) < plogis(-1 + 1.5 * tutoring + 0.12 * (exam - 62)))   # a collider
        write.csv(data.frame(student = 1:n_t, prior_gpa, motivation, parent_degree, tutoring, exam, recommended),
                  "tutoring.csv", row.names = FALSE)

        # ---------- growth.csv: reading scores over 5 waves, with a randomized intervention ----------
        n_g <- 250
        group <- sample(rep(0:1, each = n_g / 2))                    # 1 = reading intervention
        start <- rnorm(n_g, sd = 8)                                  # each student's own starting level
        slope <- rnorm(n_g, sd = 1.5) + 0.05 * start                 # and their own growth rate
        growth <- expand.grid(wave = 0:4, student = 1:n_g)[, c("student", "wave")]
        growth$group <- ifelse(group[growth$student] == 1, "intervention", "control")
        growth$score <- round(100 + start[growth$student] +
                              (5 + 2 * group[growth$student] + slope[growth$student]) * growth$wave +
                              rnorm(nrow(growth), sd = 4), 1)
        growth <- growth[runif(nrow(growth)) >= 0.08, c("student", "group", "wave", "score")]   # ~8% of visits missed
        write.csv(growth, "growth.csv", row.names = FALSE)

        cat("Saved missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv\n")
        """#
    )

    // MARK: Missing data

    static let missingData = Lesson(
        id: "missing-data",
        title: "Missing data",
        summary: "Why values go missing, what listwise deletion does, and multiple imputation.",
        minutes: 14,
        blocks: [
            .text("Almost every real dataset has holes: skipped questions, dropped-out participants, failed recordings. Most software silently drops any row with a missing value (**listwise deletion**). Whether that's harmless or badly biased depends on **why** the values are missing. This lesson uses `missing.csv` from *generate_extra_data* (Practice datasets), where stressed people tend to skip the wellbeing question — and the true values are kept in `wellbeing_true` so you can see the bias."),
            .model(ModelExplainer(
                name: "Missing-data mechanisms and multiple imputation",
                purpose: "Classifies why data are missing, and fills in plausible values several times so that analyses use all the information and reflect the uncertainty about what's missing.",
                equation: "pooled estimate Q̄ = mean of m estimates        total variance T = Ū + (1 + 1/m) · B",
                steps: [
                    "**MCAR** (missing completely at random): missingness is unrelated to anything. Listwise deletion loses power but isn't biased.",
                    "**MAR** (missing at random): missingness depends on *observed* variables (here, stress). Listwise deletion is biased, but methods that use those variables can fix it.",
                    "**MNAR** (missing not at random): missingness depends on the missing value itself, even after accounting for what's observed. No standard method fully fixes it; run sensitivity analyses.",
                    "**Multiple imputation (MI):** predict each missing value from the other variables, adding random noise, to create m completed datasets (20 or more is often recommended; Graham, Olchowski & Gilreath, 2007). Analyze each one as usual.",
                    "Pool with **Rubin's rules**: average the m estimates; the total variance adds the average within-imputation variance Ū and the between-imputation variance B, inflated by (1 + 1/m).",
                    "**FIML** (full-information maximum likelihood) is the main alternative: it fits the model directly to all observed data (`missing = \"fiml\"` in lavaan; mixed models do this automatically for the outcome).",
                ],
                conditions: [
                    "**MAR is plausible** given the variables in the imputation model — include predictors of missingness and of the incomplete variable (auxiliary variables), plus everything in your analysis model.",
                    "The **imputation model is at least as rich** as the analysis model (interactions and nonlinear terms included).",
                    "**Enough imputations** for stable results, and pooling done with Rubin's rules — never average the imputed datasets into one.",
                ],
                reading: "Rubin (1976), *Biometrika*, 63(3), 581–592 (missing-data mechanisms); van Buuren (2018), *Flexible Imputation of Missing Data* (2nd ed.; free online), chs. 1–2; Enders (2022), *Applied Missing Data Analysis* (2nd ed.); Little & Rubin (2019), *Statistical Analysis with Missing Data* (3rd ed.)."
            )),
            .terms([
                Term("MCAR", "Missing completely at random: whether a value is missing is unrelated to any variable."),
                Term("MAR", "Missing at random: missingness depends only on observed variables."),
                Term("MNAR", "Missing not at random: missingness depends on the unobserved value itself."),
                Term("Listwise deletion", "Dropping every row with any missing value; the default in most software."),
                Term("Multiple imputation", "Creating several completed datasets with plausible values, analyzing each, and pooling."),
                Term("Rubin's rules", "How MI results are pooled: average the estimates, and combine within- and between-imputation variance."),
                Term("Auxiliary variable", "A variable used in the imputation model because it predicts missingness or the missing values, even if it's not in the analysis."),
                Term("Fraction of missing information", "How much uncertainty the missing data add; reported by MI software."),
            ]),
            .code(CodeSample(
                caption: "Who skipped the question, and what listwise deletion does",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.api as sm
                import statsmodels.formula.api as smf

                missing = pd.read_csv("missing.csv")
                print(missing.isna().mean().round(3))                    # share missing in each column

                # Does missingness depend on what we DO observe? (evidence against MCAR)
                missing["skipped"] = missing["wellbeing"].isna().astype(int)
                print(smf.logit("skipped ~ stress + sleep + age", data=missing).fit(disp=False).summary().tables[1])
                print(missing.groupby("skipped")["stress"].mean().round(2))

                # Listwise deletion vs. the truth (which real data never show you)
                print("complete cases:", round(missing["wellbeing"].mean(), 3),
                      "  truth:", round(missing["wellbeing_true"].mean(), 3))
                """#,
                r: #"""
                library(tidyverse)

                missing <- read_csv("missing.csv")
                colMeans(is.na(missing))                                 # share missing in each column

                # Does missingness depend on what we DO observe? (evidence against MCAR)
                missing <- missing |> mutate(skipped = as.integer(is.na(wellbeing)))
                summary(glm(skipped ~ stress + sleep + age, data = missing, family = binomial))
                missing |> group_by(skipped) |> summarise(mean_stress = mean(stress))

                # Listwise deletion vs. the truth (which real data never show you)
                c(complete_cases = mean(missing$wellbeing, na.rm = TRUE), truth = mean(missing$wellbeing_true))
                """#
            )),
            .code(CodeSample(
                caption: "Multiple imputation with chained equations, pooled with Rubin's rules",
                python: #"""
                from statsmodels.imputation import mice

                np.random.seed(1)                                        # MICEData draws from NumPy's global generator
                imp = mice.MICEData(missing[["age", "stress", "sleep", "wellbeing"]])
                # Each incomplete variable is predicted from the others, cycling until the imputations settle
                imp.update_all(10)                                       # burn-in

                # 20 imputed datasets: estimate the mean in each, then pool with Rubin's rules
                estimates, variances = [], []
                for _ in range(20):
                    imp.update_all(1)
                    w = imp.data["wellbeing"]
                    estimates.append(w.mean())
                    variances.append(w.var() / len(w))                   # squared SE of the mean
                m = len(estimates)
                mean_mi = np.mean(estimates)
                se_mi = np.sqrt(np.mean(variances) + (1 + 1 / m) * np.var(estimates, ddof=1))
                print(f"MI mean = {mean_mi:.3f} (SE {se_mi:.3f})")

                # For regression models, MICE runs the imputations and the pooling for you
                fit = mice.MICE("wellbeing ~ stress + sleep", sm.OLS, imp).fit(n_burnin=10, n_imputations=20)
                print(fit.summary())
                """#,
                r: #"""
                library(mice)

                # Each incomplete variable is predicted from the others, cycling until the imputations settle
                imp <- mice(missing[c("age", "stress", "sleep", "wellbeing")], m = 20, seed = 1, printFlag = FALSE)

                # Fit the analysis in every imputed dataset, then pool with Rubin's rules
                fit <- with(imp, lm(wellbeing ~ 1))
                summary(pool(fit))                                       # the intercept is the pooled mean
                summary(pool(with(imp, lm(wellbeing ~ stress + sleep)))) # works the same for any model
                """#
            )),
            .keyPoint("Report your missing data", "Say how much is missing on each variable, what you think the mechanism is and why, and how you handled it (e.g. “20 imputations by chained equations, including stress and sleep as predictors”). Show complete-case results too if they differ."),
            .caution("Don't impute the outcome with a mean", "Replacing missing values with the variable's mean shrinks its variance, distorts correlations, and makes standard errors far too small. Single imputation of any kind treats guesses as known. Use MI or FIML."),
            .field(.psychology, "Longitudinal studies lose participants over time, and those who drop out often differ (e.g. more depressed). Mixed models and MI using baseline variables are standard remedies under MAR."),
            .field(.sociology, "Income questions have high non-response that is related to income itself — a classic MNAR case. Surveys add auxiliary variables (occupation, housing) to make MAR more plausible."),
            .exercise(Exercise(
                title: "How biased is listwise deletion?",
                prompt: "Store the share of missing wellbeing values and the complete-case mean. Compare it with `wellbeing_true` — in which direction is the complete-case mean biased, and why?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    share_missing = missing["wellbeing"].isna().mean()
                    mean_cc = missing["wellbeing"].mean()
                    print(round(share_missing, 3), round(mean_cc, 3), round(missing["wellbeing_true"].mean(), 3))
                    """#,
                    r: #"""
                    share_missing <- mean(is.na(missing$wellbeing))
                    mean_cc <- mean(missing$wellbeing, na.rm = TRUE)
                    round(c(share_missing, mean_cc, mean(missing$wellbeing_true)), 3)
                    """#
                ),
                answer: "About a quarter of the values are missing, and the complete-case mean is too **high**: stressed people (who have lower wellbeing) are the ones who skipped. The data are MAR given stress, so listwise deletion is biased.",
                selfCheck: SelfCheck(
                    names: "`share_missing` and `mean_cc`",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("missing.csv")
                        observed = ref["wellbeing"].dropna()
                        check("Share missing", share_missing, 1 - len(observed) / len(ref), tol=0.001)
                        check("Complete-case mean", mean_cc, observed.sum() / len(observed), tol=0.001)
                        check("Biased upward (above the true mean)", mean_cc > ref["wellbeing_true"].mean(), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("missing.csv")
                      observed <- ref$wellbeing[!is.na(ref$wellbeing)]
                      check("Share missing", share_missing, 1 - length(observed) / nrow(ref), tol = 0.001)
                      check("Complete-case mean", mean_cc, sum(observed) / length(observed), tol = 0.001)
                      check("Biased upward (above the true mean)", mean_cc > mean(ref$wellbeing_true), TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Rubin's rules by hand",
                prompt: "Five imputed datasets gave mean wellbeing estimates of 4.02, 4.06, 3.99, 4.05, and 4.03, with standard errors 0.031, 0.030, 0.032, 0.031, and 0.030. Pool them: the estimate, and its standard error.",
                hint: "Ū = mean of the squared SEs; B = variance of the five estimates; T = Ū + (1 + 1/5) × B; SE = √T.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    est = np.array([4.02, 4.06, 3.99, 4.05, 4.03])
                    se = np.array([0.031, 0.030, 0.032, 0.031, 0.030])
                    m = len(est)
                    pooled = est.mean()
                    within, between = (se ** 2).mean(), est.var(ddof=1)
                    pooled_se = np.sqrt(within + (1 + 1 / m) * between)
                    print(round(pooled, 3), round(pooled_se, 4))
                    """#,
                    r: #"""
                    est <- c(4.02, 4.06, 3.99, 4.05, 4.03)
                    se  <- c(0.031, 0.030, 0.032, 0.031, 0.030)
                    m <- length(est)
                    pooled <- mean(est)
                    pooled_se <- sqrt(mean(se^2) + (1 + 1 / m) * var(est))
                    round(c(pooled, pooled_se), 4)
                    """#
                ),
                answer: "The pooled estimate is **4.03** with SE ≈ **0.0408** — noticeably larger than any single imputation's SE (~0.031), because the between-imputation spread reflects uncertainty about the missing values.",
                selfCheck: SelfCheck(
                    names: "`pooled` and `pooled_se`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        est = [4.02, 4.06, 3.99, 4.05, 4.03]
                        se = [0.031, 0.030, 0.032, 0.031, 0.030]
                        m = len(est)
                        q_bar = sum(est) / m
                        u_bar = sum(s ** 2 for s in se) / m
                        b = sum((q - q_bar) ** 2 for q in est) / (m - 1)
                        check("Pooled estimate", pooled, q_bar, tol=1e-6)
                        check("Pooled SE", pooled_se, (u_bar + (1 + 1 / m) * b) ** 0.5, tol=1e-6,
                              hint="Square the SEs before averaging, and use the n − 1 variance for B.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      est <- c(4.02, 4.06, 3.99, 4.05, 4.03); se <- c(0.031, 0.030, 0.032, 0.031, 0.030)
                      m <- length(est); q_bar <- sum(est) / m
                      u_bar <- sum(se^2) / m
                      b <- sum((est - q_bar)^2) / (m - 1)
                      check("Pooled estimate", pooled, q_bar, tol = 1e-6)
                      check("Pooled SE", pooled_se, sqrt(u_bar + (1 + 1 / m) * b), tol = 1e-6,
                            hint = "Square the SEs before averaging, and use the n − 1 variance for B.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Does imputation fix the bias?",
                prompt: "Run the multiple-imputation code and store the pooled mean of wellbeing. Is it closer to the truth than the complete-case mean?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    # mean_mi comes from the imputation code above
                    print(round(mean_mi, 3), round(missing["wellbeing"].mean(), 3), round(missing["wellbeing_true"].mean(), 3))
                    """#,
                    r: #"""
                    mean_mi <- summary(pool(fit))$estimate[1]
                    round(c(mi = mean_mi, complete_cases = mean(missing$wellbeing, na.rm = TRUE),
                            truth = mean(missing$wellbeing_true)), 3)
                    """#
                ),
                answer: "Yes. Because missingness depends on stress, and stress is in the imputation model, MI recovers a mean very close to the truth, while listwise deletion stays biased upward.",
                selfCheck: SelfCheck(
                    names: "`mean_mi`",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("missing.csv")
                        truth, cc = ref["wellbeing_true"].mean(), ref["wellbeing"].mean()
                        print(f"truth {truth:.3f} | complete cases {cc:.3f} | yours {mean_mi:.3f}")
                        check("MI is closer to the truth than listwise deletion", abs(mean_mi - truth) < abs(cc - truth), True,
                              hint="Include stress in the imputation model — it predicts who skipped.")
                        # Imputations are random draws, so allow for some noise around the truth
                        check("Within 0.1 of the true mean", abs(mean_mi - truth) < 0.1, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("missing.csv")
                      truth <- mean(ref$wellbeing_true); cc <- mean(ref$wellbeing, na.rm = TRUE)
                      cat(sprintf("truth %.3f | complete cases %.3f | yours %.3f\n", truth, cc, mean_mi))
                      check("MI is closer to the truth than listwise deletion", abs(mean_mi - truth) < abs(cc - truth), TRUE,
                            hint = "Include stress in the imputation model — it predicts who skipped.")
                      # Imputations are random draws, so allow for some noise around the truth
                      check("Within 0.1 of the true mean", abs(mean_mi - truth) < 0.1, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Older participants were more likely to skip an item, and age was recorded. The missingness is…",
                options: ["MCAR", "MAR", "MNAR", "Ignorable only with mean imputation"],
                answer: 1,
                explanation: "It depends on an observed variable (age), so it's MAR — use age in MI or FIML."
            ),
            Question(
                prompt: "Why does multiple imputation create several datasets instead of one?",
                options: ["To increase the sample size", "So the results reflect uncertainty about the missing values", "Because one imputation is always biased", "To test MCAR"],
                answer: 1,
                explanation: "The spread between imputations feeds into the standard errors through Rubin's rules."
            ),
            Question(
                prompt: "Replacing missing values with the variable's mean…",
                options: ["Is unbiased under MAR", "Shrinks variance and makes SEs too small", "Is the same as FIML", "Is recommended for outcomes"],
                answer: 1,
                explanation: "Mean imputation treats guesses as known values and distorts relationships."
            ),
        ]
    )

    // MARK: Survey weights

    static let surveyWeights = Lesson(
        id: "survey-weights",
        title: "Survey weights & complex samples",
        summary: "Design weights, stratification, clustering, and design effects.",
        minutes: 13,
        blocks: [
            .text("National surveys rarely use simple random samples. They **stratify** (sample within regions), **cluster** (sample towns, then people within them), and **oversample** small groups. Each choice must be undone in the analysis: weights for unequal selection probabilities, and design-based standard errors for clustering. This lesson uses `poll.csv` (from *generate_extra_data*): a poll that interviewed 500 urban and 500 rural adults in 50 towns, although only 30% of the population is rural."),
            .model(ModelExplainer(
                name: "Design-based estimation",
                purpose: "Estimates population quantities from a sample with unequal selection probabilities and clustering, with standard errors that reflect how the sample was drawn.",
                equation: "ȳ_w = Σ wᵢyᵢ / Σ wᵢ        Kish n_eff = (Σ wᵢ)² / Σ wᵢ²        design effect = Var_design / Var_SRS",
                steps: [
                    "A **design weight** is 1 / (probability of selection): the number of population members each respondent represents. Here urban respondents stand for 1,400 people each and rural respondents for 600.",
                    "**Weighted estimates** (means, proportions, regression coefficients) correct for over- and under-sampling.",
                    "**Clustering** makes respondents from the same town more alike, so there is less independent information than n suggests; **stratification** usually helps a little.",
                    "Design-based SEs (Taylor linearization) treat **clusters within strata** as the independent units. The **design effect** compares that variance with a simple random sample's.",
                    "Unequal weights also cost precision: **Kish's effective sample size** says how many simple-random-sample respondents the weighted sample is worth.",
                ],
                conditions: [
                    "**Correct design information**: weights, strata, and cluster (PSU) identifiers from the survey's documentation.",
                    "Survey-supplied weights often also include **non-response and post-stratification adjustments** — use them as provided.",
                    "Enough clusters per stratum (at least 2) for variance estimation.",
                ],
                reading: "Lumley (2010), *Complex Surveys: A Guide to Analysis Using R*; Heeringa, West & Berglund (2017), *Applied Survey Data Analysis* (2nd ed.), chs. 2–3; Kish (1965), *Survey Sampling*."
            )),
            .terms([
                Term("Sampling (design) weight", "1 / probability of selection: how many population members a respondent represents."),
                Term("Stratification", "Sampling separately within groups (strata) such as regions."),
                Term("Cluster / PSU", "Primary sampling unit — a group (town, school) sampled first, with people sampled within it."),
                Term("Design effect (deff)", "The variance under the actual design divided by the variance under a simple random sample of the same size."),
                Term("Effective sample size", "The size of a simple random sample that would give the same precision."),
                Term("Post-stratification / raking", "Adjusting weights so the sample matches known population totals (age, gender, region)."),
                Term("Taylor linearization", "The standard method for design-based standard errors."),
            ]),
            .code(CodeSample(
                caption: "Weighted estimates, design-based SEs, and the design effect",
                python: #"""
                import numpy as np
                import pandas as pd

                poll = pd.read_csv("poll.csv")
                print(poll.groupby("region").agg(n=("id", "size"), weight=("weight", "first"), support=("support", "mean")))

                # Weighted estimate: each respondent stands for `weight` people
                p_unweighted = poll["support"].mean()
                p_weighted = np.average(poll["support"], weights=poll["weight"])
                print(f"unweighted {p_unweighted:.3f}   weighted {p_weighted:.3f}")

                # Kish's effective sample size
                n_eff = poll["weight"].sum() ** 2 / (poll["weight"] ** 2).sum()

                # Design-based SE by linearization: total each town's weighted residuals,
                # then measure how much towns vary within each region (stratum)
                z = poll["weight"] * (poll["support"] - p_weighted) / poll["weight"].sum()
                town_totals = z.groupby([poll["region"], poll["town"]]).sum()
                var = sum(len(t) / (len(t) - 1) * ((t - t.mean()) ** 2).sum()
                          for _, t in town_totals.groupby(level="region"))
                se_design = np.sqrt(var)
                se_srs = np.sqrt(p_weighted * (1 - p_weighted) / len(poll))   # pretending it was a simple random sample
                print(f"n_eff = {n_eff:.0f}   SE design = {se_design:.4f}   SE SRS = {se_srs:.4f}   "
                      f"deff = {(se_design / se_srs) ** 2:.2f}")
                """#,
                r: #"""
                library(tidyverse)
                library(survey)

                poll <- read_csv("poll.csv")
                poll |> group_by(region) |> summarise(n = n(), weight = first(weight), support = mean(support))

                c(unweighted = mean(poll$support), weighted = weighted.mean(poll$support, poll$weight))

                # Describe the design once: towns are clusters (PSUs), regions are strata, plus the weights
                design <- svydesign(ids = ~town, strata = ~region, weights = ~weight, data = poll)
                svymean(~support, design, deff = TRUE)         # weighted estimate, design-based SE, design effect
                svyby(~support, ~region, design, svymean)      # by region
                summary(svyglm(trust ~ support + age, design = design))   # weighted regression, design-based SEs

                sum(poll$weight)^2 / sum(poll$weight^2)        # Kish's effective sample size
                """#
            )),
            .keyPoint("Weights fix bias; the design fixes the SEs", "Weighting moves the estimate toward the population value. Clustering doesn't change the estimate but widens its uncertainty. Ignoring the design usually gives standard errors that are too small — here the design effect is about 2–2.5."),
            .caution("Not every weight is a survey weight", "Passing survey weights to an ordinary regression function as `weights=` treats them as precision (or frequency) weights, which gives the right coefficients but wrong standard errors. Use survey software, or design-based SEs as above."),
            .field(.sociology, "Large social surveys (the ESS, GSS, Add Health, PISA) all ship with weights, strata, and PSU variables. Their documentation says exactly which to use — and analyses that ignore them misstate national figures."),
            .exercise(Exercise(
                title: "Weighted support",
                prompt: "Store the unweighted and the weighted share of respondents who support the policy. Why do they differ?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    print(round(p_unweighted, 3), round(p_weighted, 3))
                    """#,
                    r: #"""
                    p_unweighted <- mean(poll$support)
                    p_weighted <- weighted.mean(poll$support, poll$weight)
                    round(c(p_unweighted, p_weighted), 3)
                    """#
                ),
                answer: "Rural respondents, who support the policy less, make up half the sample but only 30% of the population. Weighting gives urban respondents more say, raising the estimate by several percentage points.",
                selfCheck: SelfCheck(
                    names: "`p_unweighted` and `p_weighted`",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("poll.csv")
                        by_region = ref.groupby("region")["support"].mean()
                        check("Unweighted share", p_unweighted, ref["support"].mean(), tol=0.001)
                        # With one weight per region, weighting = combining region means by population shares (70% / 30%)
                        check("Weighted share", p_weighted, 0.7 * by_region["urban"] + 0.3 * by_region["rural"], tol=0.001,
                              hint="Use the weight column: np.average(..., weights=...).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("poll.csv")
                      by_region <- tapply(ref$support, ref$region, mean)
                      check("Unweighted share", p_unweighted, mean(ref$support), tol = 0.001)
                      # With one weight per region, weighting = combining region means by population shares (70% / 30%)
                      check("Weighted share", p_weighted, 0.7 * by_region[["urban"]] + 0.3 * by_region[["rural"]], tol = 0.001,
                            hint = "Use the weight column: weighted.mean(..., w = weight).")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "What the weights cost",
                prompt: "Store Kish's effective sample size. Then store the design-based SE of weighted support and the SE you'd get by pretending the poll was a simple random sample. What's the design effect?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    print(round(n_eff), round(se_design, 4), round(se_srs, 4), round((se_design / se_srs) ** 2, 2))
                    """#,
                    r: #"""
                    n_eff <- sum(poll$weight)^2 / sum(poll$weight^2)
                    se_design <- unname(SE(svymean(~support, design)))[1]
                    p_w <- weighted.mean(poll$support, poll$weight)
                    se_srs <- sqrt(p_w * (1 - p_w) / nrow(poll))
                    round(c(n_eff, se_design, se_srs, (se_design / se_srs)^2), 4)
                    """#
                ),
                answer: "The unequal weights alone shrink 1,000 interviews to an effective n of about 862. Clustering within towns inflates the variance further, so the design effect is around 2–2.5 — the poll is worth roughly 400–500 random interviews.",
                selfCheck: SelfCheck(
                    names: "`n_eff`, `se_design`, and `se_srs`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("poll.csv")
                        w, y = ref["weight"].to_numpy(), ref["support"].to_numpy()
                        check("Kish effective n", n_eff, w.sum() ** 2 / (w ** 2).sum(), tol=0.001)
                        p = (w * y).sum() / w.sum()
                        # Linearization: residual totals per town, compared within each region
                        ref["z"] = w * (y - p) / w.sum()
                        var = 0.0
                        for _, stratum in ref.groupby("region"):
                            t = stratum.groupby("town")["z"].sum().to_numpy()
                            var += len(t) / (len(t) - 1) * ((t - t.mean()) ** 2).sum()
                        check("Design-based SE", se_design, np.sqrt(var), tol=0.002,
                              hint="Towns are the clusters and regions the strata.")
                        check("Simple-random-sample SE", se_srs, np.sqrt(p * (1 - p) / len(ref)), tol=0.002)
                        check("Design effect is above 1", se_design > se_srs, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("poll.csv")
                      w <- ref$weight; y <- ref$support
                      check("Kish effective n", n_eff, sum(w)^2 / sum(w^2), tol = 0.001)
                      p <- sum(w * y) / sum(w)
                      # Linearization: residual totals per town, compared within each region
                      ref$z <- w * (y - p) / sum(w)
                      var_total <- sum(sapply(split(ref, ref$region), function(s) {
                        t <- tapply(s$z, s$town, sum)
                        length(t) / (length(t) - 1) * sum((t - mean(t))^2)
                      }))
                      check("Design-based SE", se_design, sqrt(var_total), tol = 0.002,
                            hint = "Towns are the clusters (ids = ~town) and regions the strata.")
                      check("Simple-random-sample SE", se_srs, sqrt(p * (1 - p) / nrow(ref)), tol = 0.002)
                      check("Design effect is above 1", se_design > se_srs, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A survey deliberately oversamples a small minority group. To estimate a national average, you should…",
                options: ["Drop the extra cases", "Use the design weights", "Report the unweighted mean", "Use a t-test"],
                answer: 1,
                explanation: "Weights undo the unequal selection probabilities."
            ),
            Question(
                prompt: "Respondents within the same sampled town tend to be alike. Ignoring this clustering makes standard errors…",
                options: ["Too large", "Too small", "Unchanged", "Negative"],
                answer: 1,
                explanation: "Clustered observations carry less independent information than their count suggests."
            ),
            Question(
                prompt: "A design effect of 2 means the sample is roughly as informative as a simple random sample…",
                options: ["Twice as large", "Half as large", "Of the same size", "With no clustering"],
                answer: 1,
                explanation: "Variance is doubled, so the effective sample size is halved."
            ),
        ]
    )

    // MARK: Causal inference

    static let causalInference = Lesson(
        id: "causal-inference",
        title: "Causal inference with observational data",
        summary: "DAGs, confounders vs. colliders, regression adjustment, and propensity scores.",
        minutes: 15,
        blocks: [
            .text("Randomized experiments are the cleanest route to causal claims, but many questions can only be studied observationally. Causal inference makes the assumptions explicit: draw how you think the variables cause each other, decide which variables to adjust for (and which **not** to), and estimate the effect. This lesson uses `tutoring.csv` (from *generate_extra_data*), where motivated students and students with lower grades are more likely to choose tutoring, and the true effect of tutoring is **+5 exam points**."),
            .model(ModelExplainer(
                name: "Confounding, the backdoor criterion, and propensity scores",
                purpose: "Identifies which variables must be adjusted for to estimate a causal effect from observational data, and estimates it by regression adjustment or by weighting.",
                equation: "ATE = E[Y(1) − Y(0)]        propensity eᵢ = P(T = 1 | X)        IPW weights: T/e + (1 − T)/(1 − e)",
                steps: [
                    "Each person has two **potential outcomes**: their score with tutoring, Y(1), and without, Y(0). We only see one, so the effect must be estimated by comparing groups.",
                    "Draw a **DAG** (directed acyclic graph) of what causes what. Here motivation, prior GPA, and parental education affect both tutoring and exam scores — they're **confounders** that open “backdoor” paths.",
                    "The **backdoor criterion**: adjust for a set of variables that blocks every backdoor path, and include no descendants of the treatment. Then the adjusted comparison estimates the causal effect.",
                    "**Don't** adjust for a **collider** (a variable caused by both treatment and outcome, like a teacher's recommendation) or a **mediator** (a step on the causal path) — that creates or removes association.",
                    "**Propensity scores** summarize the confounders as each person's probability of treatment. Weighting by 1/e (treated) and 1/(1 − e) (untreated) — **IPW** — creates a pseudo-population in which treatment is unrelated to the confounders.",
                ],
                conditions: [
                    "**No unmeasured confounding** — every common cause is measured and adjusted for. This can't be tested from the data; argue it, and run sensitivity analyses.",
                    "**Positivity (overlap):** everyone has some chance of each treatment; check that propensity scores overlap between groups.",
                    "**A correctly specified** outcome or propensity model (doubly robust methods combine both for insurance).",
                    "**Consistency and no interference:** one well-defined version of the treatment, and one person's treatment doesn't affect another's outcome.",
                ],
                reading: "Hernán & Robins (2020), *Causal Inference: What If* (free online), chs. 1–7 and 12; Rohrer (2018), *Advances in Methods and Practices in Psychological Science*, 1(1), 27–42; Cunningham (2021), *Causal Inference: The Mixtape* (free online)."
            )),
            .terms([
                Term("Potential outcomes", "The outcomes a person would have under each treatment; only one is ever observed."),
                Term("Average treatment effect (ATE)", "The average difference between potential outcomes across the population."),
                Term("Confounder", "A common cause of treatment and outcome; it must be adjusted for."),
                Term("Collider", "A variable caused by two others; adjusting for it creates a spurious association."),
                Term("Mediator", "A variable on the causal path from treatment to outcome; adjusting for it removes part of the effect."),
                Term("DAG", "Directed acyclic graph: a diagram of assumed causal relationships."),
                Term("Backdoor path", "A non-causal path from treatment to outcome through a common cause."),
                Term("Propensity score", "The probability of receiving the treatment, given the confounders."),
                Term("Inverse probability weighting (IPW)", "Weighting each person by the inverse of the probability of the treatment they actually received."),
                Term("Positivity / overlap", "Every type of person has some chance of receiving each treatment."),
            ]),
            .steps("The DAG for the tutoring data", [
                "**Motivation** → tutoring, and motivation → exam (motivated students seek help *and* study more).",
                "**Prior GPA** → tutoring (struggling students are steered toward it), and prior GPA → exam.",
                "**Parent has a degree** → tutoring, and → exam.",
                "**Tutoring → exam**: the effect we want (+5 points).",
                "Tutoring → **recommended** ← exam: a teacher's recommendation depends on both, so it's a collider. Adjust for the three confounders; leave the collider out.",
            ]),
            .code(CodeSample(
                caption: "Naive, adjusted, and collider-adjusted estimates",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                students = pd.read_csv("tutoring.csv")

                fits = {
                    "naive":         "exam ~ tutoring",
                    "adjusted":      "exam ~ tutoring + prior_gpa + motivation + parent_degree",
                    "plus collider": "exam ~ tutoring + prior_gpa + motivation + parent_degree + recommended",
                }
                for label, formula in fits.items():
                    fit = smf.ols(formula, data=students).fit()
                    lo, hi = fit.conf_int().loc["tutoring"]
                    print(f"{label:>14}: {fit.params['tutoring']:.2f}  [{lo:.2f}, {hi:.2f}]")
                """#,
                r: #"""
                library(tidyverse)

                students <- read_csv("tutoring.csv")

                naive    <- lm(exam ~ tutoring, data = students)
                adjusted <- lm(exam ~ tutoring + prior_gpa + motivation + parent_degree, data = students)
                collider <- lm(exam ~ tutoring + prior_gpa + motivation + parent_degree + recommended, data = students)

                sapply(list(naive = naive, adjusted = adjusted, plus_collider = collider),
                       function(m) coef(m)[["tutoring"]])
                """#
            )),
            .code(CodeSample(
                caption: "Propensity scores, overlap, and inverse probability weighting",
                python: #"""
                # Each student's probability of choosing tutoring, given the confounders
                ps_model = smf.logit("tutoring ~ prior_gpa + motivation + parent_degree", data=students).fit(disp=False)
                students["ps"] = ps_model.predict()
                print(students.groupby("tutoring")["ps"].describe()[["min", "mean", "max"]].round(2))   # overlap?

                # Weights: tutored students get 1/ps, others 1/(1 − ps)
                students["ipw"] = np.where(students["tutoring"] == 1, 1 / students["ps"], 1 / (1 - students["ps"]))
                treated, control = students[students["tutoring"] == 1], students[students["tutoring"] == 0]
                ate_ipw = (np.average(treated["exam"], weights=treated["ipw"])
                           - np.average(control["exam"], weights=control["ipw"]))
                print("IPW estimate of the average effect:", round(ate_ipw, 2))
                """#,
                r: #"""
                # Each student's probability of choosing tutoring, given the confounders
                ps_model <- glm(tutoring ~ prior_gpa + motivation + parent_degree, data = students, family = binomial)
                students <- students |>
                  mutate(ps = fitted(ps_model),
                         ipw = ifelse(tutoring == 1, 1 / ps, 1 / (1 - ps)))
                students |> group_by(tutoring) |> summarise(min = min(ps), mean = mean(ps), max = max(ps))   # overlap?

                ate_ipw <- with(students, weighted.mean(exam[tutoring == 1], ipw[tutoring == 1]) -
                                          weighted.mean(exam[tutoring == 0], ipw[tutoring == 0]))
                ate_ipw

                # Matching instead of weighting (estimates the effect among the tutored, the ATT)
                library(MatchIt)
                matched <- matchit(tutoring ~ prior_gpa + motivation + parent_degree, data = students, method = "nearest")
                summary(matched)$sum.matched[, 1:3]                      # covariate balance after matching
                coef(lm(exam ~ tutoring, data = match.data(matched), weights = weights))[["tutoring"]]
                """#
            )),
            .keyPoint("Say what you assumed", "A causal estimate from observational data is only as good as its assumptions. Show the DAG, list the adjustment set and why, check overlap, and discuss what unmeasured confounders could do. That's what turns “associated with” into a defensible causal argument."),
            .caution("“Control for everything” is not a strategy", "Adding every available variable can **introduce** bias: colliders open spurious paths and mediators remove part of the effect you want. Choose adjustment variables from the DAG, not from the dataset's column list. Tools like dagitty.net find valid adjustment sets for you."),
            .field(.sociology, "Does attending a selective school raise later earnings? Students who attend differ in ability, family resources, and motivation. Causal analyses adjust for pre-admission measures, compare students just above and below admission cutoffs, or use other designs that mimic randomization."),
            .field(.psychology, "“Collider bias” explains some surprising correlations in selected samples: if a program admits students who are either talented or hard-working, talent and effort look negatively related *among admitted students* even if they're unrelated overall."),
            .exercise(Exercise(
                title: "Three estimates of one effect",
                prompt: "Store the tutoring coefficient from the naive, adjusted, and collider-adjusted models. Which one is closest to the true +5, and why are the others off?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    est = {label: smf.ols(f, data=students).fit().params["tutoring"] for label, f in fits.items()}
                    naive, adjusted, with_collider = est["naive"], est["adjusted"], est["plus collider"]
                    print(round(naive, 2), round(adjusted, 2), round(with_collider, 2))
                    """#,
                    r: #"""
                    naive_b         <- coef(naive)[["tutoring"]]
                    adjusted_b      <- coef(adjusted)[["tutoring"]]
                    with_collider_b <- coef(collider)[["tutoring"]]
                    round(c(naive_b, adjusted_b, with_collider_b), 2)
                    """#
                ),
                answer: "The naive estimate is about twice the truth: motivated students both choose tutoring and score higher. Adjusting for the three confounders recovers roughly +5. Adding the collider pulls the estimate away again, because among students with the same recommendation status, tutoring and exam scores become entangled.",
                selfCheck: SelfCheck(
                    names: "in Python, `naive`, `adjusted`, and `with_collider`; in R, `naive_b`, `adjusted_b`, and `with_collider_b`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("tutoring.csv")

                        def tutoring_coef(*covariates):
                            X = np.column_stack([np.ones(len(ref)), ref["tutoring"], *[ref[c] for c in covariates]])
                            return np.linalg.lstsq(X, ref["exam"].to_numpy(), rcond=None)[0][1]

                        confounders = ["prior_gpa", "motivation", "parent_degree"]
                        check("Naive", naive, tutoring_coef(), tol=0.001)
                        check("Adjusted for the confounders", adjusted, tutoring_coef(*confounders), tol=0.001)
                        check("Also adjusted for the collider", with_collider, tutoring_coef(*confounders, "recommended"), tol=0.001)
                        check("The adjusted estimate is near the true +5", adjusted, 5, tol=0.25)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("tutoring.csv")
                      tutoring_coef <- function(...) coef(lm(reformulate(c("tutoring", ...), "exam"), data = ref))[["tutoring"]]
                      check("Naive", naive_b, tutoring_coef(), tol = 0.001)
                      check("Adjusted for the confounders", adjusted_b, tutoring_coef("prior_gpa", "motivation", "parent_degree"),
                            tol = 0.001)
                      check("Also adjusted for the collider", with_collider_b,
                            tutoring_coef("prior_gpa", "motivation", "parent_degree", "recommended"), tol = 0.001)
                      check("The adjusted estimate is near the true +5", adjusted_b, 5, tol = 0.25)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Inverse probability weighting",
                prompt: "Run the propensity-score code and store the IPW estimate of the average effect (weighted mean of tutored students minus weighted mean of the rest). How does it compare with the regression-adjusted estimate?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    print(round(ate_ipw, 2))
                    """#,
                    r: #"""
                    round(ate_ipw, 2)
                    """#
                ),
                answer: "The IPW estimate is close to +5 too — the two approaches rely on the same no-unmeasured-confounding assumption but different modelling choices, so agreement is reassuring.",
                selfCheck: SelfCheck(
                    names: "`ate_ipw`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("tutoring.csv")
                        X = sm.add_constant(ref[["prior_gpa", "motivation", "parent_degree"]])
                        ps = sm.Logit(ref["tutoring"], X).fit(disp=False).predict(X)
                        t, y = ref["tutoring"].to_numpy(), ref["exam"].to_numpy()
                        w1, w0 = t / ps, (1 - t) / (1 - ps)
                        expected = (w1 * y).sum() / w1.sum() - (w0 * y).sum() / w0.sum()
                        check("IPW estimate", ate_ipw, expected, tol=0.002,
                              hint="Weights are 1/ps for tutored students and 1/(1 − ps) for the rest.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("tutoring.csv")
                      ps <- fitted(glm(tutoring ~ prior_gpa + motivation + parent_degree, data = ref, family = binomial))
                      w1 <- ref$tutoring / ps; w0 <- (1 - ref$tutoring) / (1 - ps)
                      expected <- sum(w1 * ref$exam) / sum(w1) - sum(w0 * ref$exam) / sum(w0)
                      check("IPW estimate", ate_ipw, expected, tol = 0.002,
                            hint = "Weights are 1/ps for tutored students and 1/(1 − ps) for the rest.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Exercise affects both sleep quality and mood, and sleep affects mood. To estimate the effect of sleep on mood, you should adjust for…",
                options: ["Nothing", "Exercise (a confounder)", "Mood", "A variable caused by sleep"],
                answer: 1,
                explanation: "Exercise opens a backdoor path from sleep to mood."
            ),
            Question(
                prompt: "Admission to a program depends on both test scores and interview ratings. Among admitted students only, the two look negatively correlated. This is…",
                options: ["Confounding", "Collider (selection) bias", "Mediation", "Measurement error"],
                answer: 1,
                explanation: "Selecting on a common effect (admission) creates a spurious association."
            ),
            Question(
                prompt: "What does a propensity score summarize?",
                options: ["The outcome", "Each person's probability of receiving the treatment given the confounders", "The treatment effect", "The sample size"],
                answer: 1,
                explanation: "Balancing on the propensity score balances the confounders that went into it."
            ),
        ]
    )

    // MARK: Meta-analysis

    static let metaAnalysis = Lesson(
        id: "meta-analysis",
        title: "Meta-analysis",
        summary: "Combining studies: effect sizes, fixed and random effects, heterogeneity, and publication bias.",
        minutes: 13,
        blocks: [
            .text("A single study is rarely decisive. A **meta-analysis** combines the effect sizes from many studies into one estimate, weighting more precise studies more heavily, and asks how much the true effect varies between studies. The data below are 12 (invented) studies of an expressive-writing intervention on wellbeing, each reporting Cohen's d and group sizes — the same in Python and R, so your numbers will match exactly."),
            .model(ModelExplainer(
                name: "Inverse-variance meta-analysis",
                purpose: "Pools effect sizes across studies, weighting each by its precision, and estimates how much true effects differ between studies.",
                equation: "fixed: θ̂ = Σ wᵢdᵢ / Σ wᵢ, wᵢ = 1/vᵢ        random: wᵢ* = 1/(vᵢ + τ²)        I² = (Q − df) / Q",
                steps: [
                    "Put every study on a common **effect-size** scale (d, r, log odds ratio) with its **sampling variance** vᵢ. For d: vᵢ = (n₁ + n₂)/(n₁n₂) + d²/(2(n₁ + n₂)).",
                    "A **common-effect** (fixed-effect) model assumes one true effect and weights studies by 1/vᵢ.",
                    "A **random-effects** model assumes true effects vary across studies with variance τ²; each study's weight becomes 1/(vᵢ + τ²), so small studies count relatively more. The DerSimonian–Laird method estimates τ² from Cochran's Q (DerSimonian & Laird, 1986).",
                    "**Heterogeneity:** Q tests whether studies differ more than chance allows; I² is the share of variability due to real differences (Higgins & Thompson, 2002); a **prediction interval** shows where a new study's true effect is likely to fall.",
                    "**Publication bias:** if small studies with null results went unpublished, small studies show larger effects. A **funnel plot** and **Egger's regression test** (Egger et al., 1997) look for that asymmetry.",
                ],
                conditions: [
                    "**Comparable studies** — similar enough constructs, designs, and populations that pooling makes sense.",
                    "**Independent effect sizes** (one per study, or a multilevel model for several per study).",
                    "**A systematic search** with pre-specified inclusion criteria (PRISMA), so the set of studies isn't cherry-picked.",
                ],
                reading: "Borenstein, Hedges, Higgins & Rothstein (2021), *Introduction to Meta-Analysis* (2nd ed.); Harrer, Cuijpers, Furukawa & Ebert (2021), *Doing Meta-Analysis with R* (free online); Viechtbauer (2010), *Journal of Statistical Software*, 36(3) (metafor)."
            )),
            .terms([
                Term("Effect size", "A standardized measure of an effect (d, r, log OR) that can be compared across studies."),
                Term("Sampling variance", "How much a study's effect size would vary across replications; smaller for larger studies."),
                Term("Common-effect (fixed-effect) model", "Assumes all studies estimate one true effect."),
                Term("Random-effects model", "Assumes true effects vary across studies around an average."),
                Term("τ² (tau squared)", "The variance of true effects across studies."),
                Term("I²", "The percentage of observed variability due to real differences between studies rather than chance."),
                Term("Prediction interval", "The range in which the true effect of a new, similar study would probably fall."),
                Term("Forest plot", "Each study's estimate and CI, with the pooled estimate at the bottom."),
                Term("Funnel plot", "Effect sizes against their precision; asymmetry suggests small-study effects or publication bias."),
                Term("Egger's test", "A regression test of funnel-plot asymmetry."),
            ]),
            .code(CodeSample(
                caption: "Random-effects meta-analysis, forest plot, and publication-bias checks",
                python: #"""
                import numpy as np
                import pandas as pd
                import matplotlib.pyplot as plt
                import statsmodels.formula.api as smf
                from statsmodels.stats.meta_analysis import combine_effects

                studies = pd.DataFrame({
                    "study": ["Adams 2012", "Baker 2013", "Chen 2014", "Diaz 2015", "Evans 2015", "Fischer 2016",
                              "Garcia 2017", "Huang 2018", "Ito 2019", "Jones 2020", "Kumar 2021", "Lopez 2022"],
                    "d":  [0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19],
                    "n1": [40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90],
                    "n2": [40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92],
                })
                n1, n2, d = studies["n1"], studies["n2"], studies["d"]
                studies["v"] = (n1 + n2) / (n1 * n2) + d ** 2 / (2 * (n1 + n2))     # sampling variance of d

                res = combine_effects(studies["d"], studies["v"], method_re="dl", row_names=studies["study"])
                print(res.summary_frame().round(3))       # each study, plus the fixed- and random-effects pools
                print(f"tau² = {res.tau2:.4f}   Q = {res.q:.2f}   I² = {res.i2:.2f}")
                res.plot_forest(); plt.show()

                # Funnel plot and Egger's test: regress d / SE on 1 / SE; a non-zero intercept means asymmetry
                studies["se"] = np.sqrt(studies["v"])
                plt.scatter(studies["d"], studies["se"]); plt.gca().invert_yaxis()
                plt.xlabel("Cohen's d"); plt.ylabel("Standard error"); plt.show()
                egger = smf.ols("I(d / se) ~ I(1 / se)", data=studies).fit()
                print("Egger intercept:", round(egger.params["Intercept"], 2), " p =", round(egger.pvalues["Intercept"], 4))
                """#,
                r: #"""
                library(metafor)

                studies <- data.frame(
                  study = c("Adams 2012", "Baker 2013", "Chen 2014", "Diaz 2015", "Evans 2015", "Fischer 2016",
                            "Garcia 2017", "Huang 2018", "Ito 2019", "Jones 2020", "Kumar 2021", "Lopez 2022"),
                  d  = c(0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19),
                  n1 = c(40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90),
                  n2 = c(40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92)
                )
                studies$v <- with(studies, (n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2)))   # sampling variance of d

                res <- rma(yi = d, vi = v, data = studies, method = "DL", slab = study)   # random effects (DerSimonian–Laird)
                res                                 # pooled d, tau², Q, I²
                predict(res)                        # CI and prediction interval
                forest(res)
                funnel(res)
                regtest(res, model = "lm")          # Egger's regression test
                """#
            )),
            .keyPoint("Heterogeneity is a finding", "A pooled effect of d = 0.25 means something different when every study found about 0.25 than when effects range from −0.1 to 0.7. Report τ², I², and the prediction interval, and use **moderator analyses** (meta-regression: `rma(yi, vi, mods = ~ population)`) to explain the variation."),
            .caution("Small-study effects aren't proof of publication bias", "Funnel asymmetry can also come from real differences: small studies often use more intensive interventions or more selected samples. Treat Egger's test as a warning, and consider sensitivity analyses (trim-and-fill, selection models, PET-PEESE)."),
            .field(.psychology, "Many-labs replications and large meta-analyses have shown that some well-known effects shrink sharply once publication bias is accounted for — which is why meta-analysts now routinely check funnel plots and preregister their protocols."),
            .field(.linguistics, "Meta-analyses in second-language research pool effects of instruction types across dozens of classroom studies (e.g. Norris & Ortega, 2000), with moderators such as learner proficiency and outcome measure."),
            .exercise(Exercise(
                title: "Pool by hand",
                prompt: "Compute the common-effect estimate, Cochran's Q, the DerSimonian–Laird τ², the random-effects estimate, and I² yourself, using the formulas in the explainer. Check them against the software.",
                hint: "w = 1/v. Q = Σ w(d − θ̂)². τ² = max(0, (Q − (k − 1)) / (Σw − Σw²/Σw)). Then reweight with 1/(v + τ²).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    v, d = studies["v"].to_numpy(), studies["d"].to_numpy()
                    k, w = len(d), 1 / v
                    fe_est = (w * d).sum() / w.sum()
                    q = (w * (d - fe_est) ** 2).sum()
                    tau2 = max(0, (q - (k - 1)) / (w.sum() - (w ** 2).sum() / w.sum()))
                    w_re = 1 / (v + tau2)
                    re_est = (w_re * d).sum() / w_re.sum()
                    i2 = max(0, (q - (k - 1)) / q)
                    print(round(fe_est, 4), round(re_est, 4), round(tau2, 4), round(i2, 3))
                    """#,
                    r: #"""
                    v <- studies$v; d <- studies$d
                    k <- length(d); w <- 1 / v
                    fe_est <- sum(w * d) / sum(w)
                    q <- sum(w * (d - fe_est)^2)
                    tau2 <- max(0, (q - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
                    w_re <- 1 / (v + tau2)
                    re_est <- sum(w_re * d) / sum(w_re)
                    i2 <- max(0, (q - (k - 1)) / q)
                    round(c(fe_est, re_est, tau2, i2), 4)
                    """#
                ),
                answer: "The common-effect estimate is about **0.17** and the random-effects estimate higher, about **0.24**, because τ² gives the small studies (which found larger effects) relatively more weight. Q is significant and I² ≈ 51% — moderate heterogeneity. Your hand calculations match `combine_effects()` / `rma()` exactly.",
                selfCheck: SelfCheck(
                    names: "`fe_est`, `re_est`, `tau2`, and `i2`",
                    python: #"""
                    import numpy as np
                    from statsmodels.stats.meta_analysis import combine_effects
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        d = np.array([0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19])
                        n1 = np.array([40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90])
                        n2 = np.array([40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92])
                        v = (n1 + n2) / (n1 * n2) + d ** 2 / (2 * (n1 + n2))
                        res = combine_effects(d, v, method_re="dl")
                        check("Common-effect estimate", fe_est, res.mean_effect_fe, tol=0.001)
                        check("Random-effects estimate", re_est, res.mean_effect_re, tol=0.001)
                        check("τ² (DerSimonian–Laird)", tau2, res.tau2, tol=0.001)
                        check("I²", i2, res.i2, tol=0.001, hint="I² is a proportion here (0–1), not a percentage.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(metafor)

                    local({   # keeps these names from overwriting your variables
                      d  <- c(0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19)
                      n1 <- c(40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90)
                      n2 <- c(40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92)
                      v  <- (n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2))
                      fe <- rma(yi = d, vi = v, method = "FE")
                      re <- rma(yi = d, vi = v, method = "DL")
                      check("Common-effect estimate", fe_est, coef(fe)[[1]], tol = 0.001)
                      check("Random-effects estimate", re_est, coef(re)[[1]], tol = 0.001)
                      check("τ² (DerSimonian–Laird)", tau2, re$tau2, tol = 0.001)
                      check("I²", i2, re$I2 / 100, tol = 0.001, hint = "I² is a proportion here (0–1), not a percentage.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Where would the next study land?",
                prompt: "Compute the random-effects 95% **prediction interval**: θ̂ ± 1.96 × √(τ² + SE(θ̂)²), where SE(θ̂) = 1/√Σw*. Compare it with the 95% CI of the pooled effect.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    se_re = 1 / np.sqrt(w_re.sum())
                    pi_low, pi_high = re_est + np.array([-1, 1]) * 1.96 * np.sqrt(tau2 + se_re ** 2)
                    print("CI:", (re_est + np.array([-1, 1]) * 1.96 * se_re).round(3), " PI:", round(pi_low, 3), round(pi_high, 3))
                    """#,
                    r: #"""
                    se_re <- 1 / sqrt(sum(w_re))
                    pi_low  <- re_est - 1.96 * sqrt(tau2 + se_re^2)
                    pi_high <- re_est + 1.96 * sqrt(tau2 + se_re^2)
                    c(pi_low, pi_high)
                    predict(res)            # metafor's pi.lb and pi.ub agree
                    """#
                ),
                answer: "The CI for the average effect is fairly narrow and excludes 0, but the prediction interval is much wider and includes 0: a new study in a different setting could plausibly find no effect at all. That's what moderate heterogeneity means in practice.",
                selfCheck: SelfCheck(
                    names: "`pi_low` and `pi_high`",
                    python: #"""
                    import numpy as np
                    from statsmodels.stats.meta_analysis import combine_effects
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        d = np.array([0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19])
                        n1 = np.array([40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90])
                        n2 = np.array([40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92])
                        v = (n1 + n2) / (n1 * n2) + d ** 2 / (2 * (n1 + n2))
                        res = combine_effects(d, v, method_re="dl")
                        half = 1.96 * np.sqrt(res.tau2 + res.sd_eff_w_re ** 2)
                        check("Prediction interval", [pi_low, pi_high], [res.mean_effect_re - half, res.mean_effect_re + half],
                              tol=0.002, hint="Add τ² to the squared SE before taking the square root.")
                        check("The interval includes 0", pi_low < 0 < pi_high, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(metafor)

                    local({   # keeps these names from overwriting your variables
                      d  <- c(0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19)
                      n1 <- c(40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90)
                      n2 <- c(40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92)
                      v  <- (n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2))
                      p <- predict(rma(yi = d, vi = v, method = "DL"))
                      check("Prediction interval", c(pi_low, pi_high), c(p$pi.lb, p$pi.ub), tol = 0.002,
                            hint = "Add τ² to the squared SE before taking the square root.")
                      check("The interval includes 0", pi_low < 0 && 0 < pi_high, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "In an inverse-variance meta-analysis, which studies get the most weight?",
                options: ["The most recent", "The most precise (usually the largest)", "Those with the biggest effects", "All studies equally"],
                answer: 1,
                explanation: "Weights are 1 / variance."
            ),
            Question(
                prompt: "I² = 75% means…",
                options: ["75% of studies are significant", "Most of the observed variability reflects real differences between studies", "The pooled effect is 0.75", "75% publication bias"],
                answer: 1,
                explanation: "I² is the share of variability not explained by sampling error."
            ),
            Question(
                prompt: "A funnel plot shows that small studies report much larger effects than large ones. A possible explanation is…",
                options: ["Random effects", "Publication bias or other small-study effects", "Perfect homogeneity", "Too many studies"],
                answer: 1,
                explanation: "Asymmetry suggests missing small null studies — or real differences in small studies."
            ),
        ]
    )

    // MARK: Bayesian inference

    static let bayesian = Lesson(
        id: "bayesian",
        title: "Bayesian inference",
        summary: "Priors, posteriors, credible intervals, and Bayes factors.",
        minutes: 14,
        blocks: [
            .text("Frequentist statistics asks how surprising the data would be if a hypothesis were true. **Bayesian** statistics asks the reverse: given the data, how plausible is each possible value of the parameter? It combines a **prior** (what was plausible beforehand) with the **likelihood** (what the data say) to get a **posterior** — a full probability distribution for the parameter."),
            .model(ModelExplainer(
                name: "Bayesian updating",
                purpose: "Treats unknown parameters as uncertain quantities and uses Bayes' rule to update beliefs about them in light of data.",
                equation: "posterior ∝ likelihood × prior        Beta(a, b) prior + k successes in n → Beta(a + k, b + n − k)",
                steps: [
                    "**Prior:** a distribution over plausible parameter values before seeing the data — weakly informative priors (e.g. Normal(0, 1) for a standardized slope) rule out absurd values without favouring an answer.",
                    "**Likelihood:** how probable the observed data are for each parameter value.",
                    "**Posterior:** prior × likelihood, rescaled to sum to 1. For a proportion with a Beta prior, the posterior is again a Beta — just add the successes and failures to the prior's parameters.",
                    "Summarize the posterior with its mean or median and a **95% credible interval**: the parameter lies in it with 95% probability, given the model and prior. You can also report direct probabilities, like P(effect > 0 | data).",
                    "For realistic models there's no formula, so software (Stan via brms, PyMC via bambi) draws samples from the posterior with **MCMC**. Check convergence: R-hat ≈ 1.00 and large effective sample sizes.",
                    "A **Bayes factor** compares how well two hypotheses predicted the data; BF₀₁ = 10 means the data are 10 times more likely under the null than the alternative.",
                ],
                conditions: [
                    "**Priors stated and justified** — and a sensitivity analysis showing how much they matter.",
                    "**Converged MCMC** (R-hat < 1.01, no divergent transitions, enough effective samples).",
                    "**Posterior predictive checks:** data simulated from the fitted model should look like the real data.",
                    "Bayes factors depend strongly on the prior for the alternative hypothesis; report it.",
                ],
                reading: "McElreath (2020), *Statistical Rethinking* (2nd ed.), chs. 1–4; Kruschke (2015), *Doing Bayesian Data Analysis* (2nd ed.); Wagenmakers (2007), *Psychonomic Bulletin & Review*, 14(5), 779–804 (BIC approximation to Bayes factors); Bürkner (2017), *Journal of Statistical Software*, 80(1) (brms)."
            )),
            .terms([
                Term("Prior", "The distribution of plausible parameter values before seeing the data."),
                Term("Likelihood", "How probable the data are for each possible parameter value."),
                Term("Posterior", "The updated distribution of parameter values after seeing the data."),
                Term("Conjugate prior", "A prior that gives a posterior of the same family (Beta prior + binomial data → Beta posterior)."),
                Term("Credible interval", "An interval containing the parameter with a stated posterior probability (e.g. 95%)."),
                Term("Bayes factor", "The ratio of how well two hypotheses predicted the data."),
                Term("MCMC", "Markov chain Monte Carlo: algorithms that draw samples from a posterior distribution."),
                Term("R-hat", "A convergence diagnostic comparing MCMC chains; values near 1.00 are good."),
                Term("ROPE", "Region of practical equivalence — the Bayesian counterpart of equivalence bounds."),
            ]),
            .code(CodeSample(
                caption: "A participant's accuracy: prior, posterior, and credible interval",
                python: #"""
                from scipy import stats

                k, n = 14, 20                  # 14 of 20 two-choice trials correct
                a, b = 1, 1                    # flat Beta(1, 1) prior: every accuracy from 0 to 1 equally plausible

                post = stats.beta(a + k, b + n - k)            # posterior: Beta(a + successes, b + failures)
                print("posterior mean:", round(post.mean(), 3))
                print("95% credible interval:", post.ppf([0.025, 0.975]).round(3))
                print("P(accuracy > .5 | data):", round(1 - post.cdf(0.5), 3))
                """#,
                r: #"""
                k <- 14; n <- 20               # 14 of 20 two-choice trials correct
                a <- 1; b <- 1                 # flat Beta(1, 1) prior: every accuracy from 0 to 1 equally plausible

                (a + k) / (a + b + n)                          # posterior mean of Beta(a + k, b + n − k)
                qbeta(c(0.025, 0.975), a + k, b + n - k)       # 95% credible interval
                1 - pbeta(0.5, a + k, b + n - k)               # P(accuracy > .5 | data)
                """#
            )),
            .code(CodeSample(
                caption: "Bayesian regression with brms (R) or bambi (Python)",
                python: #"""
                # pip install bambi   (installs PyMC; the first fit takes a minute)
                import arviz as az
                import bambi as bmb
                import pandas as pd

                survey = pd.read_csv("survey.csv")
                model = bmb.Model("anxiety ~ rumination + social_media", survey,
                                  priors={"rumination": bmb.Prior("Normal", mu=0, sigma=1),
                                          "social_media": bmb.Prior("Normal", mu=0, sigma=1)})
                idata = model.fit(draws=2000, chains=4, random_seed=1)
                print(az.summary(idata, hdi_prob=0.95))         # estimates, 95% intervals, r_hat, ess
                print("P(rumination slope > 0):", (idata.posterior["rumination"] > 0).mean().item())
                """#,
                r: #"""
                # install.packages("brms")   # needs a C++ toolchain; the first fit compiles for a minute
                library(tidyverse)
                library(brms)

                survey <- read_csv("survey.csv")
                fit <- brm(anxiety ~ rumination + social_media, data = survey,
                           prior = prior(normal(0, 1), class = b), chains = 4, iter = 2000, seed = 1)
                summary(fit)                             # estimates, 95% credible intervals, Rhat, Bulk_ESS
                hypothesis(fit, "rumination > 0")        # posterior probability of a positive slope
                pp_check(fit)                            # posterior predictive check
                """#
            )),
            .code(CodeSample(
                caption: "A quick Bayes factor from BIC: is there really no regional difference?",
                python: #"""
                import numpy as np
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                m0 = smf.ols("anxiety ~ 1", data=survey).fit()           # no regional difference
                m1 = smf.ols("anxiety ~ C(region)", data=survey).fit()   # a regional difference
                bf01 = np.exp((m1.bic - m0.bic) / 2)                     # evidence for the null over the alternative
                print(f"BF01 ≈ {bf01:.1f}")
                """#,
                r: #"""
                survey <- read.csv("survey.csv")
                m0 <- lm(anxiety ~ 1, data = survey)          # no regional difference
                m1 <- lm(anxiety ~ region, data = survey)     # a regional difference
                bf01 <- exp((BIC(m1) - BIC(m0)) / 2)          # evidence for the null over the alternative
                bf01
                # For a default-prior Bayes factor: BayesFactor::ttestBF(formula = anxiety ~ region, data = as.data.frame(survey))
                """#
            )),
            .keyPoint("What Bayesian results let you say", "“Given the data and our prior, there is a 95% probability the slope lies between 0.38 and 0.52, and a > 99.9% probability it is positive.” These direct probability statements are what people often wrongly read into p-values and confidence intervals."),
            .caution("Priors are assumptions — show them", "With small samples, priors can drive the results. Report the priors, justify them, and show a sensitivity analysis with a wider or flatter prior. With lots of data, reasonable priors barely matter."),
            .field(.linguistics, "Bayesian mixed models (brms) are now common in psycholinguistics because they converge with complex random-effects structures that lme4 can't fit, and because they give direct probability statements about effects (Vasishth et al., 2018)."),
            .exercise(Exercise(
                title: "One participant's accuracy",
                prompt: "A participant gets 14 of 20 trials right. With a Beta(2, 2) prior (mild preference for middling accuracy), find the posterior mean, the 95% credible interval, and P(accuracy > .5 | data).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    post = stats.beta(2 + 14, 2 + 6)
                    post_mean, cri, p_above = post.mean(), post.ppf([0.025, 0.975]), 1 - post.cdf(0.5)
                    print(round(post_mean, 3), cri.round(3), round(p_above, 3))
                    """#,
                    r: #"""
                    post_mean <- 16 / (16 + 8)
                    cri <- qbeta(c(0.025, 0.975), 16, 8)
                    p_above <- 1 - pbeta(0.5, 16, 8)
                    round(c(post_mean, cri, p_above), 3)
                    """#
                ),
                answer: "The posterior is Beta(16, 8): mean ≈ **.67**, 95% credible interval ≈ **[.47, .84]**, and P(accuracy > .5) ≈ **.95**. Fairly good evidence of above-chance performance — but with only 20 trials, a wide range of accuracies is still plausible.",
                selfCheck: SelfCheck(
                    names: "`post_mean`, `cri` (as [lower, upper]), and `p_above`",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Compute the posterior on a fine grid: prior × likelihood, then normalize
                        p = np.linspace(0, 1, 200_001)
                        density = p ** (2 - 1 + 14) * (1 - p) ** (2 - 1 + 6)
                        density /= density.sum()
                        cdf = np.cumsum(density)
                        check("Posterior mean", post_mean, (p * density).sum(), tol=0.001,
                              hint="Posterior = Beta(prior a + successes, prior b + failures) = Beta(16, 8).")
                        check("Probability mass inside your interval", np.interp(cri[1], p, cdf) - np.interp(cri[0], p, cdf), 0.95,
                              tol=0.002)
                        check("Equal tails (2.5% below the interval)", np.interp(cri[0], p, cdf), 0.025, tol=0.002)
                        check("P(accuracy > .5)", p_above, density[p > 0.5].sum(), tol=0.002)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Compute the posterior on a fine grid: prior × likelihood, then normalize
                      p <- seq(0, 1, length.out = 200001)
                      density <- p^(2 - 1 + 14) * (1 - p)^(2 - 1 + 6)
                      density <- density / sum(density)
                      cdf <- cumsum(density)
                      check("Posterior mean", post_mean, sum(p * density), tol = 0.001,
                            hint = "Posterior = Beta(prior a + successes, prior b + failures) = Beta(16, 8).")
                      check("Probability mass inside your interval", approx(p, cdf, cri[2])$y - approx(p, cdf, cri[1])$y, 0.95,
                            tol = 0.002)
                      check("Equal tails (2.5% below the interval)", approx(p, cdf, cri[1])$y, 0.025, tol = 0.002)
                      check("P(accuracy > .5)", p_above, sum(density[p > 0.5]), tol = 0.002)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "How much does the prior matter?",
                prompt: "For the same 14 / 20, compute the posterior mean under a flat Beta(1, 1) prior and under a strong Beta(50, 50) prior centred on .5. What happens, and when would each be reasonable?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    mean_flat = (1 + 14) / (1 + 1 + 20)
                    mean_strong = (50 + 14) / (50 + 50 + 20)
                    print(round(mean_flat, 3), round(mean_strong, 3))
                    """#,
                    r: #"""
                    mean_flat   <- (1 + 14) / (1 + 1 + 20)
                    mean_strong <- (50 + 14) / (50 + 50 + 20)
                    round(c(mean_flat, mean_strong), 3)
                    """#
                ),
                answer: "The flat prior gives ≈ .68, close to the raw 14/20 = .70. The strong prior — equivalent to having already seen 100 trials at 50% — pulls the estimate down to ≈ .53. Strong priors are reasonable only when there's real prior evidence; with 2,000 trials instead of 20, both priors would give nearly the same answer.",
                selfCheck: SelfCheck(
                    names: "`mean_flat` and `mean_strong`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # A Beta(a, b) prior acts like a + b earlier trials with a successes,
                        # so the posterior mean is (prior successes + data successes) / (prior trials + data trials)
                        check("Posterior mean, flat prior", mean_flat, (1 + 14) / (2 + 20), tol=1e-6)
                        check("Posterior mean, Beta(50, 50) prior", mean_strong, (50 + 14) / (100 + 20), tol=1e-6,
                              hint="Add the data to the prior's pseudo-counts: 50 + 14 successes out of 100 + 20.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # A Beta(a, b) prior acts like a + b earlier trials with a successes,
                      # so the posterior mean is (prior successes + data successes) / (prior trials + data trials)
                      check("Posterior mean, flat prior", mean_flat, (1 + 14) / (2 + 20), tol = 1e-6)
                      check("Posterior mean, Beta(50, 50) prior", mean_strong, (50 + 14) / (100 + 20), tol = 1e-6,
                            hint = "Add the data to the prior's pseudo-counts: 50 + 14 successes out of 100 + 20.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Evidence for no difference",
                prompt: "Store the BIC-based Bayes factor BF₀₁ for urban vs. rural anxiety. Does it favour the null, and how does that compare with what a p-value can tell you?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    print(round(bf01, 2))
                    """#,
                    r: #"""
                    round(bf01, 2)
                    """#
                ),
                answer: "With no regional difference built into the data, BF₀₁ is usually well above 3 — moderate evidence **for** the null. A non-significant p-value could only say the data are compatible with no difference; the Bayes factor quantifies support for it (as an equivalence test does, in a different way).",
                selfCheck: SelfCheck(
                    names: "`bf01`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # ΔBIC between two linear models = n · ln(RSS₁ / RSS₀) + (extra parameters) · ln(n)
                        ref = pd.read_csv("survey.csv")
                        y, n = ref["anxiety"].to_numpy(), len(ref)
                        rss0 = ((y - y.mean()) ** 2).sum()
                        group_means = ref.groupby("region")["anxiety"].transform("mean").to_numpy()
                        rss1 = ((y - group_means) ** 2).sum()
                        delta_bic = n * np.log(rss1 / rss0) + 1 * np.log(n)
                        check("BF₀₁", bf01, np.exp(delta_bic / 2), tol=0.002,
                              hint="BF₀₁ = exp((BIC of the region model − BIC of the null model) / 2).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # ΔBIC between two linear models = n · ln(RSS₁ / RSS₀) + (extra parameters) · ln(n)
                      ref <- read.csv("survey.csv")
                      y <- ref$anxiety; n <- length(y)
                      rss0 <- sum((y - mean(y))^2)
                      rss1 <- sum((y - ave(y, ref$region))^2)
                      check("BF₀₁", bf01, exp((n * log(rss1 / rss0) + log(n)) / 2), tol = 0.002,
                            hint = "BF₀₁ = exp((BIC of the region model − BIC of the null model) / 2).")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A 95% credible interval for a slope is [0.10, 0.40]. Which statement is correct?",
                options: [
                    "95% of intervals built this way contain the true slope",
                    "Given the model and prior, the slope lies in [0.10, 0.40] with 95% probability",
                    "p < .05",
                    "The prior was flat",
                ],
                answer: 1,
                explanation: "Credible intervals are direct probability statements about the parameter."
            ),
            Question(
                prompt: "A Beta(1, 1) prior is updated with 7 successes in 10 trials. The posterior is…",
                options: ["Beta(7, 3)", "Beta(8, 4)", "Beta(1, 1)", "Normal(0.7, 0.1)"],
                answer: 1,
                explanation: "Add successes to a and failures to b: Beta(1 + 7, 1 + 3)."
            ),
            Question(
                prompt: "BF₀₁ = 8 means…",
                options: ["The null is 8 times more probable than before", "The data are 8 times more likely under the null than the alternative", "p = .08", "The effect is 8 SDs"],
                answer: 1,
                explanation: "A Bayes factor compares how well the hypotheses predicted the data."
            ),
        ]
    )
}

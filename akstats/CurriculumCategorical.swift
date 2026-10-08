import Foundation

// MARK: - Units 9–11 · Categorical outcomes, latent class & profile models, text as data

extension Curriculum {
    static let categoricalOutcomes = Unit(
        id: "categorical-outcomes", number: 9, title: "Categorical, ordinal & count outcomes", level: .advanced,
        summary: "Ordinal mixed models for rating scales, multinomial models for choices, and count models for rates.",
        symbol: "list.number",
        lessons: [ordinalModels, multinomialOutcomes, countModels]
    )

    static let latentModels = Unit(
        id: "latent-models", number: 10, title: "Latent class & profile models", level: .advanced,
        summary: "Finding hidden subgroups with LCA and LPA, in R, Python, and Mplus.",
        symbol: "circle.hexagongrid",
        lessons: [latentClass, latentProfile, mplusMixtures]
    )

    static let textAsData = Unit(
        id: "text-as-data", number: 11, title: "Text as data", level: .advanced,
        summary: "Embeddings, clustering, distinctive words, dictionaries, and topic models.",
        symbol: "text.magnifyingglass",
        lessons: [clustering, keyness, topicModels]
    )

    /// The second practice-data script (judgments, commutes, habits, profiles).
    static let moreDataSample = CodeSample(
        caption: "generate_more_data — judgments.csv, commutes.csv, habits.csv, profiles.csv",
        python: #"""
        # generate_more_data.py — creates judgments.csv, commutes.csv, habits.csv, profiles.csv
        import numpy as np
        import pandas as pd

        rng = np.random.default_rng(2027)

        # ---------- judgments.csv: a 2 × 2 sentence-acceptability experiment ----------
        n_part, n_items = 40, 32
        conditions = [("simple", "short"), ("simple", "long"), ("complex", "short"), ("complex", "long")]
        part_eff, item_eff = rng.normal(0, 0.7, n_part), rng.normal(0, 0.5, n_items)
        part_acc, item_acc = rng.normal(0, 0.6, n_part), rng.normal(0, 0.4, n_items)
        rows = []
        for p in range(n_part):
            for i in range(n_items):
                structure, distance = conditions[(p + i) % 4]     # Latin square: each item once per person
                is_complex, is_long = structure == "complex", distance == "long"
                latent = (part_eff[p] + item_eff[i] - 0.8 * is_complex - 0.5 * is_long
                          - 0.6 * (is_complex and is_long) + rng.logistic(0, 0.7))
                rating = int(np.digitize(latent, [-2.5, -1.6, -0.8, 0.0, 0.8, 1.6])) + 1     # 1–7
                p_correct = 1 / (1 + np.exp(-(1.5 - 0.5 * is_complex + part_acc[p] + item_acc[i])))
                rows.append({"participant": p + 1, "item": i + 1, "structure": structure, "distance": distance,
                             "rating": rating, "correct": int(rng.random() < p_correct)})
        pd.DataFrame(rows).to_csv("judgments.csv", index=False)

        # ---------- commutes.csv: weekly commute mode over 10 weeks ----------
        modes = ["car", "bus", "bike", "walk"]
        rows = []
        for p in range(120):
            distance = round(float(rng.gamma(2.0, 3.0)), 1)                 # km
            taste = np.r_[0.0, rng.normal(0, 0.8, 3)]                      # personal preferences (car = 0)
            previous = None
            for week in range(1, 11):
                utility = np.array([0.0, 0.2, -0.5 + 0.12 * week - 0.15 * distance, 1.0 - 0.6 * distance]) + taste
                if previous is not None:
                    utility[previous] += 1.5                               # habit: people repeat their mode
                prob = np.exp(utility) / np.exp(utility).sum()
                choice = rng.choice(4, p=prob)
                rows.append({"participant": p + 1, "week": week, "distance_km": distance, "mode": modes[choice]})
                previous = choice
        pd.DataFrame(rows).to_csv("commutes.csv", index=False)

        # ---------- habits.csv: six study strategies from three hidden types ----------
        strategies = ["reread", "notes", "selftest", "spaced", "explain", "peers"]
        type_profiles = np.array([
            [0.90, 0.85, 0.15, 0.10, 0.10, 0.20],   # 1: passive review
            [0.50, 0.50, 0.85, 0.75, 0.60, 0.25],   # 2: active practice
            [0.40, 0.40, 0.40, 0.30, 0.80, 0.90],   # 3: social learning
        ])
        n_h = 500
        cls = rng.choice(3, n_h, p=[0.45, 0.35, 0.20])
        habits = pd.DataFrame((rng.random((n_h, 6)) < type_profiles[cls]).astype(int), columns=strategies)
        habits.insert(0, "id", np.arange(1, n_h + 1))
        habits["gpa"] = np.clip(np.array([2.8, 3.4, 3.1])[cls] + rng.normal(0, 0.4, n_h), 0, 4).round(2)
        habits["true_class"] = cls + 1
        habits.to_csv("habits.csv", index=False)

        # ---------- profiles.csv: four continuous scores from three hidden profiles ----------
        n_lpa = 400
        profile = rng.choice(3, n_lpa, p=[0.5, 0.3, 0.2])
        profile_means = np.array([[5.5, 2.5, 5.5, 5.0],    # 1: thriving
                                  [4.0, 4.0, 4.0, 4.0],    # 2: average
                                  [2.5, 5.5, 3.0, 2.8]])   # 3: struggling
        indicators = profile_means[profile] + rng.normal(0, 0.7, (n_lpa, 4))
        lpa = pd.DataFrame(np.clip(indicators, 1, 7).round(2), columns=["wellbeing", "stress", "support", "sleep"])
        lpa.insert(0, "id", np.arange(1, n_lpa + 1))
        lpa["age"] = rng.integers(18, 66, n_lpa)
        lpa["burnout"] = (np.array([2.0, 3.0, 4.5])[profile] + rng.normal(0, 0.8, n_lpa)).round(2)
        lpa["true_profile"] = profile + 1
        lpa.to_csv("profiles.csv", index=False)

        print("Saved judgments.csv, commutes.csv, habits.csv, profiles.csv")
        """#,
        r: #"""
        # generate_more_data.R — creates judgments.csv, commutes.csv, habits.csv, profiles.csv
        set.seed(2027)

        # ---------- judgments.csv: a 2 × 2 sentence-acceptability experiment ----------
        n_part <- 40; n_items <- 32
        conditions <- data.frame(structure = c("simple", "simple", "complex", "complex"),
                                 distance  = c("short", "long", "short", "long"))
        part_eff <- rnorm(n_part, sd = 0.7); item_eff <- rnorm(n_items, sd = 0.5)
        part_acc <- rnorm(n_part, sd = 0.6); item_acc <- rnorm(n_items, sd = 0.4)

        judgments <- expand.grid(item = 1:n_items, participant = 1:n_part)
        cond <- conditions[(judgments$participant + judgments$item) %% 4 + 1, ]   # Latin square
        judgments$structure <- cond$structure
        judgments$distance  <- cond$distance
        is_complex <- judgments$structure == "complex"
        is_long    <- judgments$distance == "long"
        latent <- part_eff[judgments$participant] + item_eff[judgments$item] -
                  0.8 * is_complex - 0.5 * is_long - 0.6 * (is_complex & is_long) +
                  rlogis(nrow(judgments), scale = 0.7)
        judgments$rating  <- findInterval(latent, c(-2.5, -1.6, -0.8, 0, 0.8, 1.6)) + 1   # 1–7
        p_correct <- plogis(1.5 - 0.5 * is_complex + part_acc[judgments$participant] + item_acc[judgments$item])
        judgments$correct <- as.integer(runif(nrow(judgments)) < p_correct)
        judgments <- judgments[, c("participant", "item", "structure", "distance", "rating", "correct")]
        write.csv(judgments, "judgments.csv", row.names = FALSE)

        # ---------- commutes.csv: weekly commute mode over 10 weeks ----------
        modes <- c("car", "bus", "bike", "walk")
        commutes <- do.call(rbind, lapply(1:120, function(p) {
          distance <- round(rgamma(1, shape = 2, scale = 3), 1)            # km
          taste    <- c(0, rnorm(3, sd = 0.8))                              # personal preferences (car = 0)
          out <- data.frame(participant = p, week = 1:10, distance_km = distance, mode = NA_character_)
          previous <- NA
          for (week in 1:10) {
            utility <- c(0, 0.2, -0.5 + 0.12 * week - 0.15 * distance, 1.0 - 0.6 * distance) + taste
            if (!is.na(previous)) utility[previous] <- utility[previous] + 1.5   # habit
            choice <- sample(1:4, 1, prob = exp(utility) / sum(exp(utility)))
            out$mode[week] <- modes[choice]
            previous <- choice
          }
          out
        }))
        write.csv(commutes, "commutes.csv", row.names = FALSE)

        # ---------- habits.csv: six study strategies from three hidden types ----------
        strategies <- c("reread", "notes", "selftest", "spaced", "explain", "peers")
        type_profiles <- rbind(c(0.90, 0.85, 0.15, 0.10, 0.10, 0.20),   # 1: passive review
                               c(0.50, 0.50, 0.85, 0.75, 0.60, 0.25),   # 2: active practice
                               c(0.40, 0.40, 0.40, 0.30, 0.80, 0.90))   # 3: social learning
        n_h <- 500
        cls <- sample(1:3, n_h, replace = TRUE, prob = c(0.45, 0.35, 0.20))
        present <- matrix(runif(n_h * 6), ncol = 6) < type_profiles[cls, ]
        habits <- data.frame(id = 1:n_h, matrix(as.integer(present), ncol = 6))
        names(habits)[2:7] <- strategies
        habits$gpa <- round(pmin(pmax(c(2.8, 3.4, 3.1)[cls] + rnorm(n_h, sd = 0.4), 0), 4), 2)
        habits$true_class <- cls
        write.csv(habits, "habits.csv", row.names = FALSE)

        # ---------- profiles.csv: four continuous scores from three hidden profiles ----------
        n_lpa   <- 400
        profile <- sample(1:3, n_lpa, replace = TRUE, prob = c(0.5, 0.3, 0.2))
        profile_means <- rbind(c(5.5, 2.5, 5.5, 5.0),    # 1: thriving
                               c(4.0, 4.0, 4.0, 4.0),    # 2: average
                               c(2.5, 5.5, 3.0, 2.8))    # 3: struggling
        indicators <- profile_means[profile, ] + matrix(rnorm(n_lpa * 4, sd = 0.7), ncol = 4)
        lpa <- data.frame(id = 1:n_lpa, round(pmin(pmax(indicators, 1), 7), 2))
        names(lpa)[2:5] <- c("wellbeing", "stress", "support", "sleep")
        lpa$age          <- sample(18:65, n_lpa, replace = TRUE)
        lpa$burnout      <- round(c(2, 3, 4.5)[profile] + rnorm(n_lpa, sd = 0.8), 2)
        lpa$true_profile <- profile
        write.csv(lpa, "profiles.csv", row.names = FALSE)

        cat("Saved judgments.csv, commutes.csv, habits.csv, profiles.csv\n")
        """#
    )

    // MARK: Ordinal outcomes

    static let ordinalModels = Lesson(
        id: "ordinal-models",
        title: "Ordinal mixed models",
        summary: "Rating scales with participants and items as crossed random effects.",
        minutes: 15,
        blocks: [
            .text("Rating scales — 1–7 acceptability judgments, Likert agreement, severity grades — produce **ordered categories**. The gaps between categories aren't guaranteed to be equal, and responses often pile up at one end. Treating ratings as continuous numbers can distort effect sizes and even create false positives (Liddell & Kruschke, 2018). Cumulative link models are built for ordered outcomes."),
            .model(ModelExplainer(
                name: "Cumulative link mixed model (ordinal regression)",
                purpose: "Models the probability of responding at or below each rating category as a function of predictors, assuming a continuous latent judgment underneath the scale.",
                equation: "logit P(ratingᵢⱼ ≤ k) = θₖ − (b₁·complex + b₂·long + b₃·complex×long + uᵢ + wⱼ)",
                steps: [
                    "Imagine each response comes from a continuous latent judgment, cut into categories at **thresholds** θ₁ < θ₂ < … < θ₆ (for a 7-point scale).",
                    "Predictors shift the latent judgment up or down by the same amount everywhere on the scale — the **proportional odds** assumption.",
                    "A positive coefficient means higher ratings: exp(b) is the **odds ratio** of being in a higher category rather than at or below any given one.",
                    "Random intercepts uᵢ (participants) and wⱼ (items) let some people rate everything higher and some sentences sound better overall, as in a linear mixed model.",
                    "The thresholds are estimated from the data, so unequal spacing between categories is no problem.",
                ],
                conditions: [
                    "**An ordered outcome** with at least three categories.",
                    "**Proportional odds**: each predictor's effect is similar across thresholds (check with nominal effects in `clm`, or compare against a model that relaxes it).",
                    "**Independence after accounting for the random effects**.",
                    "**Enough responses in each category**; merge categories that are almost never used.",
                ],
                reading: "Bürkner & Vuorre (2019), *Advances in Methods and Practices in Psychological Science*, 2(1), 77–101; Liddell & Kruschke (2018), *Journal of Experimental Social Psychology*, 79, 328–348. For the logit link itself, see OpenIntro Statistics (4th ed.), §9.5."
            )),
            .chart(ChartExample(
                title: "Predicted rating distributions by condition",
                kind: .ordinalShares,
                reading: [
                    "Each bar shows how responses spread across the 1–7 scale in one condition; red = low ratings, gray = the midpoint (4), blue = high ratings.",
                    "Moving down the chart, the bars shift left toward lower ratings — what a negative coefficient in an ordinal model means.",
                    "The complex/long condition shifts most, showing the interaction.",
                    "Reporting category probabilities like these is often clearer than odds ratios. Hover over a row to see the share rated 5–7.",
                ]
            )),
            .terms([
                Term("Thresholds (cut points)", "Where the latent scale is divided into rating categories."),
                Term("Proportional odds", "The assumption that a predictor shifts responses the same way at every threshold."),
                Term("CLMM", "A cumulative link model with random effects — `ordinal::clmm()` in R."),
                Term("Effect (±0.5) coding", "Coding a two-level factor as −0.5 / +0.5. Main effects become averaged over the other factor, and the interaction is the difference of differences — the same idea as sum coding."),
                Term("Crossed random effects", "Every participant sees many items and every item is seen by many participants: `(1 | participant) + (1 | item)`."),
            ]),
            .code(CodeSample(
                caption: "Acceptability ratings in a 2 × 2 design",
                python: #"""
                import numpy as np
                import pandas as pd
                from statsmodels.miscmodels.ordinal_model import OrderedModel

                judgments = pd.read_csv("judgments.csv")
                judgments["rating_ord"] = pd.Categorical(judgments["rating"], categories=range(1, 8), ordered=True)

                # Effect coding (±0.5) so main effects average over the other factor
                judgments["complex"] = np.where(judgments["structure"] == "complex", 0.5, -0.5)
                judgments["long"] = np.where(judgments["distance"] == "long", 0.5, -0.5)
                judgments["complex_x_long"] = judgments["complex"] * judgments["long"]

                # Python has no mature ordinal *mixed* model; this ignores clustering (SEs too small).
                X = judgments[["complex", "long", "complex_x_long"]]
                fit = OrderedModel(judgments["rating_ord"], X, distr="logit").fit(method="bfgs", disp=False)
                print(fit.summary())
                """#,
                r: #"""
                library(tidyverse)
                library(ordinal)

                judgments <- read_csv("judgments.csv") |>
                  mutate(rating      = factor(rating, levels = 1:7, ordered = TRUE),
                         participant = factor(participant),
                         item        = factor(item),
                         complex     = ifelse(structure == "complex", 0.5, -0.5),   # effect coding
                         long        = ifelse(distance == "long", 0.5, -0.5))

                m <- clmm(rating ~ complex * long + (1 | participant) + (1 | item), data = judgments)
                summary(m)
                exp(coef(m)[c("complex", "long", "complex:long")])   # odds ratios
                """#
            )),
            .keyPoint("Reading the results", "Negative coefficients for `complex` and `long` mean those sentences are rated lower. A negative `complex:long` interaction means the drop from a long distance is **larger** for complex sentences — together they're worse than the sum of their parts. Plot the four cell means to show it."),
            .caution("Random slopes", "Both factors vary within participants and within items, so Barr et al. (2013) would add random slopes: `(1 + complex * long | participant)`. Ordinal mixed models with many random slopes often fail to converge; simplify in a planned order, or fit the model with `brms` (`family = cumulative()`)."),
            .exercise(Exercise(
                title: "Plot the interaction",
                prompt: "Plot the mean rating in each of the four conditions, with distance on the x-axis and one line per structure.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import seaborn as sns
                    import matplotlib.pyplot as plt
                    cell_means = judgments.groupby(["structure", "distance"])["rating"].mean()
                    print(cell_means)
                    sns.pointplot(data=judgments, x="distance", y="rating", hue="structure",
                                  order=["short", "long"], palette=["#0072B2", "#D55E00"], errorbar=("ci", 95))
                    plt.ylabel("Mean rating (1–7)"); plt.show()
                    """#,
                    r: #"""
                    cell_means <- judgments |>
                      group_by(structure, distance) |>
                      summarise(mean_rating = mean(as.numeric(rating)), .groups = "drop")
                    cell_means

                    read_csv("judgments.csv") |>
                      mutate(distance = factor(distance, levels = c("short", "long"))) |>
                      ggplot(aes(distance, rating, colour = structure, group = structure)) +
                      stat_summary(fun = mean, geom = "line") +
                      stat_summary(fun.data = mean_se, geom = "pointrange") +
                      scale_colour_manual(values = c("#D55E00", "#0072B2")) +
                      theme_classic()
                    """#
                ),
                answer: "The lines aren't parallel: long distance lowers ratings for both structures, but much more for complex sentences — the interaction.",
                selfCheck: SelfCheck(
                    names: "`cell_means` — the mean rating in each structure × distance cell (in R, a `mean_rating` column)",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("judgments.csv").groupby(["structure", "distance"])["rating"].mean()
                        for s in ["simple", "complex"]:
                            for d in ["short", "long"]:
                                check(f"Mean rating, {s}-{d}", cell_means.loc[(s, d)], ref.loc[(s, d)])

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("judgments.csv")
                      for (s in c("simple", "complex")) for (d in c("short", "long")) {
                        yours <- with(cell_means, mean_rating[structure == s & distance == d])
                        check(paste0("Mean rating, ", s, "-", d), yours,
                              mean(ref$rating[ref$structure == s & ref$distance == d]))
                      }
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Linear vs. ordinal",
                prompt: "Fit an ordinary linear mixed model to the numeric ratings with the same predictors. Do the conclusions match the ordinal model?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import statsmodels.formula.api as smf
                    lin = smf.mixedlm("rating ~ complex * long", data=judgments, groups=judgments["participant"]).fit()
                    b_lin = lin.fe_params
                    print(b_lin)
                    """#,
                    r: #"""
                    library(lmerTest)
                    lin <- lmer(as.numeric(rating) ~ complex * long + (1 | participant) + (1 | item), data = judgments)
                    b_lin <- fixef(lin)
                    summary(lin)
                    """#
                ),
                answer: "The directions agree, but the linear model assumes equal spacing between categories and normal errors. With ratings bunched at the scale ends, its effect sizes and p-values can mislead — the ordinal model is the defensible choice.",
                selfCheck: SelfCheck(
                    names: "`b_lin` — the linear mixed model's fixed effects, named `complex`, `long`, and `complex:long`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("judgments.csv")
                        ref["complex"] = np.where(ref["structure"] == "complex", 0.5, -0.5)
                        ref["long"] = np.where(ref["distance"] == "long", 0.5, -0.5)
                        fit = smf.mixedlm("rating ~ complex * long", data=ref, groups=ref["participant"]).fit()
                        for term in ["complex", "long", "complex:long"]:
                            check(f"Coefficient for {term}", b_lin[term], fit.fe_params[term], tol=0.001,
                                  hint="Use the ±0.5 effect coding from the lesson.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(lme4)

                    local({   # keeps these names from overwriting your variables
                      ref <- transform(read.csv("judgments.csv"),
                                       complex = ifelse(structure == "complex", 0.5, -0.5),
                                       long    = ifelse(distance == "long", 0.5, -0.5))
                      fit <- lmer(rating ~ complex * long + (1 | participant) + (1 | item), data = ref)
                      for (term in c("complex", "long", "complex:long")) {
                        check(paste("Coefficient for", term), b_lin[[term]], fixef(fit)[[term]], tol = 0.001,
                              hint = "Use the ±0.5 effect coding and both random intercepts.")
                      }
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Predicted category probabilities",
                prompt: "Using a fixed-effects `clm` (R) or the `OrderedModel` (Python), compute the predicted probability of each rating for simple-short and complex-long sentences.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    new = pd.DataFrame({"complex": [-0.5, 0.5], "long": [-0.5, 0.5], "complex_x_long": [0.25, 0.25]})
                    probs = fit.predict(new)
                    print(pd.DataFrame(probs, columns=range(1, 8), index=["simple-short", "complex-long"]).round(3))
                    """#,
                    r: #"""
                    m_fixed <- clm(rating ~ complex * long, data = judgments)
                    probs <- predict(m_fixed, newdata = data.frame(complex = c(-0.5, 0.5), long = c(-0.5, 0.5)),
                                     type = "prob")$fit
                    round(probs, 3)
                    """#
                ),
                answer: "Simple-short sentences put most probability on 4–7; complex-long sentences shift it toward 1–3. Category probabilities are often the clearest way to report ordinal results.",
                selfCheck: SelfCheck(
                    names: "`probs` — 2 rows (simple-short, then complex-long) × 7 columns (ratings 1–7)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from statsmodels.miscmodels.ordinal_model import OrderedModel
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("judgments.csv")
                        cx = np.where(ref["structure"] == "complex", 0.5, -0.5)
                        lg = np.where(ref["distance"] == "long", 0.5, -0.5)
                        X = pd.DataFrame({"complex": cx, "long": lg, "complex_x_long": cx * lg})
                        y = pd.Series(pd.Categorical(ref["rating"], categories=range(1, 8), ordered=True))
                        fit = OrderedModel(y, X, distr="logit").fit(method="bfgs", disp=False)
                        new = pd.DataFrame({"complex": [-0.5, 0.5], "long": [-0.5, 0.5], "complex_x_long": [0.25, 0.25]})
                        expected = np.asarray(fit.predict(new))
                        check("Each row sums to 1", np.asarray(probs).sum(axis=1), [1, 1], tol=1e-6)
                        check("Probabilities, simple-short", np.asarray(probs)[0], expected[0], tol=0.001)
                        check("Probabilities, complex-long", np.asarray(probs)[1], expected[1], tol=0.001,
                              hint="The interaction term for complex-long is 0.5 × 0.5 = 0.25.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(ordinal)

                    local({   # keeps these names from overwriting your variables
                      ref <- transform(read.csv("judgments.csv"),
                                       rating  = factor(rating, levels = 1:7, ordered = TRUE),
                                       complex = ifelse(structure == "complex", 0.5, -0.5),
                                       long    = ifelse(distance == "long", 0.5, -0.5))
                      fit <- clm(rating ~ complex * long, data = ref)
                      expected <- predict(fit, newdata = data.frame(complex = c(-0.5, 0.5), long = c(-0.5, 0.5)),
                                          type = "prob")$fit
                      check("Each row sums to 1", rowSums(probs), c(1, 1), tol = 1e-6)
                      check("Probabilities, simple-short", probs[1, ], expected[1, ], tol = 0.001)
                      check("Probabilities, complex-long", probs[2, ], expected[2, ], tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Why model 1–7 acceptability ratings with an ordinal model rather than a linear one?",
                options: [
                    "Ordinal models are always more significant",
                    "The gaps between categories needn't be equal, and responses can bunch at the ends",
                    "Linear models can't include random effects",
                    "Ordinal models don't need participants",
                ],
                answer: 1,
                explanation: "Cumulative link models estimate the thresholds instead of assuming equal spacing."
            ),
            Question(
                prompt: "With ±0.5 effect coding in a 2 × 2 design, the main effect of `complex` is…",
                options: ["The effect for short sentences only", "The complex − simple difference averaged over both distances", "The interaction", "The intercept"],
                answer: 1,
                explanation: "Effect coding makes main effects average over the other factor."
            ),
        ]
    )

    // MARK: Multinomial outcomes

    static let multinomialOutcomes = Lesson(
        id: "multinomial",
        title: "Multinomial outcomes & transitions",
        summary: "Unordered choices measured repeatedly: shares, switching, and multinomial models.",
        minutes: 13,
        blocks: [
            .text("Some outcomes are **unordered categories**: commute mode, vote choice, which dialect variant a speaker uses. When each person is observed repeatedly, three tools work together: **descriptive shares** (with cluster-bootstrap CIs, from *Bootstrap & resampling*), a **transition matrix** showing how people switch, and a **multinomial model** for inference."),
            .model(ModelExplainer(
                name: "Multinomial logistic regression",
                purpose: "Models the probability of each of several unordered categories as a function of predictors, by comparing every category with a reference category.",
                equation: "log[ P(mode = m) / P(mode = car) ] = b₀ₘ + b₁ₘ·week + b₂ₘ·distance + uᵢₘ      (m = bus, bike, walk)",
                steps: [
                    "Pick a **reference category** (here, car). The model estimates one set of coefficients for each other category.",
                    "Each set describes the **log-odds** of choosing that category instead of the reference; exp(b) is a relative-risk (odds) ratio.",
                    "Predicted probabilities for all categories are computed together so they always sum to 1.",
                    "In the mixed version, random intercepts uᵢₘ capture each person's own preferences, so repeated choices by the same person aren't treated as independent.",
                ],
                conditions: [
                    "**Unordered, mutually exclusive categories** (use an ordinal model if they're ordered).",
                    "**Independence after accounting for the random effects**; without random effects, use cluster-robust SEs or a cluster bootstrap.",
                    "**Enough observations of every category** — rare categories give unstable coefficients.",
                    "**Independence of irrelevant alternatives**: the odds between two options don't depend on which other options exist.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §9.5 (logistic regression, the two-category case); Agresti (2007), *An Introduction to Categorical Data Analysis*, ch. 6."
            )),
            .chart(ChartExample(
                title: "Reading a transition matrix",
                kind: .transitionHeatmap,
                reading: [
                    "Rows are the mode used one week; columns are the mode used the next week. Each row sums to 1.",
                    "Darker cells = more common transitions. The **diagonal** shows how often people repeat their choice.",
                    "For example, 0.70 in the Bike row and Bike column means 70% of people who biked one week biked again the next.",
                    "Off-diagonal cells show switching: after walking, the most common alternative is the bus.",
                ]
            )),
            .code(CodeSample(
                caption: "Shares over time and the transition matrix",
                python: #"""
                import pandas as pd

                commutes = pd.read_csv("commutes.csv").sort_values(["participant", "week"])

                # Share of each mode, week by week
                print(pd.crosstab(commutes["week"], commutes["mode"], normalize="index").round(2))

                # Transition matrix: rows = this week's mode, columns = next week's mode
                commutes["next_mode"] = commutes.groupby("participant")["mode"].shift(-1)
                print(pd.crosstab(commutes["mode"], commutes["next_mode"], normalize="index").round(2))
                """#,
                r: #"""
                library(tidyverse)

                commutes <- read_csv("commutes.csv") |> arrange(participant, week)

                # Share of each mode, week by week
                round(prop.table(table(commutes$week, commutes$mode), margin = 1), 2)

                # Transition matrix: rows = this week's mode, columns = next week's mode
                transitions <- commutes |>
                  group_by(participant) |> mutate(next_mode = lead(mode)) |> ungroup() |>
                  filter(!is.na(next_mode))
                round(prop.table(table(transitions$mode, transitions$next_mode), margin = 1), 2)
                """#
            )),
            .code(CodeSample(
                caption: "Multinomial models: does biking grow over the weeks?",
                python: #"""
                import statsmodels.formula.api as smf

                modes = ["car", "bus", "bike", "walk"]
                commutes["mode_code"] = pd.Categorical(commutes["mode"], categories=modes).codes   # car = 0 = reference
                mn = smf.mnlogit("mode_code ~ week + distance_km", data=commutes).fit(disp=False)
                print(mn.summary())     # no random effects: treat SEs as too small
                """#,
                r: #"""
                library(mclogit)

                commutes <- commutes |> mutate(mode = factor(mode, levels = c("car", "bus", "bike", "walk")))

                # Multinomial mixed model with a random intercept per person (lme4 can't fit these)
                m <- mblogit(mode ~ week + distance_km, random = ~ 1 | participant, data = commutes)
                summary(m)
                """#
            )),
            .terms([
                Term("Reference category", "The category every other category is compared against."),
                Term("Transition matrix", "Rows = category at time t, columns = category at t + 1, cells = row proportions."),
                Term("Stickiness", "The diagonal of a transition matrix — how often people repeat their previous choice."),
                Term("Independence of irrelevant alternatives (IIA)", "The multinomial logit's assumption that adding or removing an option doesn't change the odds between the others."),
            ]),
            .keyPoint("Describe, then infer", "The transition matrix is **descriptive** (“after biking, about 70% bike again the next week”). The multinomial mixed model is the **inferential** step: it tests whether choice probabilities change with week and distance while accounting for each person's preferences."),
            .exercise(Exercise(
                title: "How sticky are commutes?",
                prompt: "From the transition matrix, what share of people repeat their mode from one week to the next, for each mode? Which mode is stickiest?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    tm = pd.crosstab(commutes["mode"], commutes["next_mode"], normalize="index")
                    stay = pd.Series({m: tm.loc[m, m] for m in tm.index})
                    print(stay.round(2))
                    """#,
                    r: #"""
                    tm <- prop.table(table(transitions$mode, transitions$next_mode), margin = 1)
                    stay <- diag(tm)
                    round(stay, 2)
                    """#
                ),
                answer: "Every mode's diagonal (roughly .65–.80) is far above its overall share — people repeat their choice most weeks. Bus, the most common mode, is usually the stickiest; walking the least.",
                selfCheck: SelfCheck(
                    names: "`stay` — the share who repeat each mode, named by mode (`bike`, `bus`, `car`, `walk`)",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("commutes.csv").sort_values(["participant", "week"])
                        ref["next_mode"] = ref.groupby("participant")["mode"].shift(-1)
                        ref = ref.dropna(subset=["next_mode"])          # week 10 has no "next week"
                        for mode in ["bike", "bus", "car", "walk"]:
                            rows = ref[ref["mode"] == mode]
                            check(f"Share repeating {mode}", stay[mode], (rows["next_mode"] == mode).mean(),
                                  hint="Sort by participant and week, and shift within each participant.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("commutes.csv")
                      ref <- ref[order(ref$participant, ref$week), ]
                      ref$next_mode <- ave(ref$mode, ref$participant, FUN = function(m) c(m[-1], NA))
                      ref <- ref[!is.na(ref$next_mode), ]               # week 10 has no "next week"
                      for (mode in c("bike", "bus", "car", "walk")) {
                        rows <- ref[ref$mode == mode, ]
                        check(paste("Share repeating", mode), stay[[mode]], mean(rows$next_mode == mode),
                              hint = "Sort by participant and week, and use lead() within each participant.")
                      }
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Distance and the odds of walking",
                prompt: "Interpret the `distance_km` coefficient for walk vs. car. Convert it to an odds ratio per extra kilometre.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np

                    # mn.params has one column per non-reference mode: bus, bike, walk
                    or_walk = np.exp(mn.params.loc["distance_km"].iloc[2])
                    print(round(or_walk, 2))
                    """#,
                    r: #"""
                    or_walk <- exp(coef(m)[["walk~distance_km"]])
                    round(or_walk, 2)
                    """#
                ),
                answer: "The coefficient is strongly negative (around −0.5 per km): each extra kilometre multiplies the odds of walking rather than driving by roughly 0.6. For bike vs. car the effect is negative but much smaller.",
                selfCheck: SelfCheck(
                    names: "`or_walk` — the odds ratio per extra kilometre, walk vs. car",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("commutes.csv")
                        ref["mode_code"] = pd.Categorical(ref["mode"], categories=["car", "bus", "bike", "walk"]).codes
                        fit = smf.mnlogit("mode_code ~ week + distance_km", data=ref).fit(disp=False)
                        check("Odds ratio per km, walk vs. car", or_walk, np.exp(fit.params.loc["distance_km"].iloc[2]),
                              tol=0.001, hint="Exponentiate the coefficient: odds ratio = exp(b).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(mclogit)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("commutes.csv")
                      ref$mode <- factor(ref$mode, levels = c("car", "bus", "bike", "walk"))
                      fit <- mblogit(mode ~ week + distance_km, random = ~ 1 | participant, data = ref)
                      check("Odds ratio per km, walk vs. car", or_walk, exp(coef(fit)[["walk~distance_km"]]),
                            tol = 0.001, hint = "Exponentiate the coefficient: odds ratio = exp(b).")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A multinomial model of 4 unordered categories estimates how many sets of coefficients?",
                options: ["1", "3", "4", "6"],
                answer: 1,
                explanation: "One set for each non-reference category."
            ),
            Question(
                prompt: "Each row of a transition matrix (row proportions) sums to…",
                options: ["0", "1", "The number of categories", "The sample size"],
                answer: 1,
                explanation: "Each row is a probability distribution over next categories."
            ),
            Question(
                prompt: "People choose a commute mode every week for 10 weeks. Why add a random intercept for participant?",
                options: ["To increase the sample size", "Repeated choices by the same person aren't independent", "It's required for multinomial models", "To remove the reference category"],
                answer: 1,
                explanation: "Personal preferences make one person's choices similar."
            ),
        ]
    )

    // MARK: Latent class analysis

    static let latentClass = Lesson(
        id: "latent-class",
        title: "Latent class analysis (LCA)",
        summary: "Discover hidden types from several categorical variables.",
        minutes: 15,
        blocks: [
            .text("**Latent class analysis** sorts people into types that aren't defined in advance, using several categorical variables. Here, 500 students reported whether they use six study strategies (yes/no). Do they fall into a few recognizable *types* of studier?"),
            .model(ModelExplainer(
                name: "Latent class analysis",
                purpose: "Explains the associations among several categorical variables by assuming the sample is a mixture of a few unobserved classes, each with its own probability of endorsing each item.",
                equation: "P(y₁, …, y₆) = Σₖ πₖ · Πⱼ P(yⱼ | class k)",
                steps: [
                    "Choose a number of classes K. Each class k has a size πₖ and an **item-response probability** for every indicator (e.g. P(self-tests | class k)).",
                    "Within a class, the indicators are assumed **independent** (local independence): all of the association between strategies is explained by class membership.",
                    "The EM algorithm alternates between estimating each person's **posterior probability** of being in each class and updating the class sizes and item probabilities — from many random starts, to avoid local maxima.",
                    "Repeat for K = 1, 2, 3, … and compare fit (BIC, likelihood-ratio tests), classification quality (entropy), and interpretability.",
                    "Assign each person to their most likely class for description — while remembering that membership is probabilistic.",
                ],
                conditions: [
                    "**Categorical indicators**, ideally 4–10 and not near-duplicates of each other (local independence).",
                    "**Enough cases** — a few hundred at least, more for many indicators or small classes.",
                    "**Replicated best loglikelihood** across random starts.",
                    "**Interpretable, non-trivial classes** (e.g. none smaller than about 5% unless clearly meaningful).",
                ],
                reading: "Nylund-Gibson & Choi (2018), *Translational Issues in Psychological Science*, 4(4), 440–461; Weller, Bowen & Faubert (2020), *Journal of Black Psychology*, 46(4), 287–311."
            )),
            .chart(ChartExample(
                title: "Reading LCA class profiles",
                kind: .classProfiles,
                reading: [
                    "Each line is one latent class; each point is the probability that a member of that class uses a strategy.",
                    "The legend gives class sizes — the share of students estimated to belong to each class.",
                    "Name classes by their **peaks and dips**: one rereads and takes notes, one self-tests and spaces practice, one explains and studies with peers.",
                    "Strategies where the lines are far apart distinguish the classes; strategies where they overlap don't.",
                ]
            )),
            .terms([
                Term("Indicator", "One of the categorical variables used to define classes."),
                Term("Class size (π)", "Estimated share of the population in each class."),
                Term("Item-response probability", "P(indicator = yes | class) — together these form the class's profile."),
                Term("Posterior probability", "Each person's probability of belonging to each class, given their responses."),
                Term("BIC", "Fit penalized for model complexity; lower is better. In simulations, BIC chose the number of classes best of the information criteria (Nylund, Asparouhov & Muthén, 2007)."),
                Term("Entropy", "0–1: how cleanly people fall into classes. Above about .80 is commonly treated as good separation (Weller et al., 2020); don't use it to choose the number of classes."),
                Term("Local independence", "Indicators are unrelated within a class."),
            ]),
            .code(CodeSample(
                caption: "Fit 1–6 classes, choose by BIC, and inspect the profiles",
                python: #"""
                # pip install stepmix
                import numpy as np
                import pandas as pd
                from stepmix.stepmix import StepMix

                habits = pd.read_csv("habits.csv")
                strategies = ["reread", "notes", "selftest", "spaced", "explain", "peers"]
                X = habits[strategies]

                bics = {}
                for k in range(1, 7):
                    model = StepMix(n_components=k, measurement="binary", n_init=10, random_state=42, verbose=0).fit(X)
                    bics[k] = model.bic(X)
                print(pd.Series(bics, name="BIC").round(1))

                best = StepMix(n_components=3, measurement="binary", n_init=10, random_state=42, verbose=0).fit(X)
                post = best.predict_proba(X)
                habits["class"] = post.argmax(axis=1) + 1
                print("class sizes:", post.mean(axis=0).round(3))
                print(habits.groupby("class")[strategies].mean().round(2))       # profiles

                entropy = 1 - (-(post * np.log(post + 1e-12)).sum()) / (len(post) * np.log(post.shape[1]))
                print("entropy:", round(entropy, 2))
                """#,
                r: #"""
                library(tidyverse)
                library(poLCA)

                habits <- read_csv("habits.csv")

                # poLCA needs categories coded 1, 2, … (not 0/1)
                lca_data <- habits |> mutate(across(reread:peers, ~ .x + 1))
                f <- cbind(reread, notes, selftest, spaced, explain, peers) ~ 1

                set.seed(42)
                fits <- lapply(1:6, function(k) poLCA(f, data = lca_data, nclass = k, nrep = 10, verbose = FALSE))
                sapply(fits, function(m) m$bic)

                best <- fits[[3]]
                best$P        # class sizes
                best$probs    # P(each response | class)

                post <- best$posterior
                1 - sum(-post * log(post + 1e-12)) / (nrow(post) * log(ncol(post)))   # entropy
                """#,
                mplus: #"""
                TITLE:    Latent class analysis of six study strategies, 3 classes;

                DATA:     FILE = habits.dat;         ! no header row (see "Mixture models in Mplus")

                VARIABLE: NAMES = id reread notes selftest spaced explain peers gpa tclass;
                          USEVARIABLES = reread notes selftest spaced explain peers;
                          CATEGORICAL = reread notes selftest spaced explain peers;   ! binary items
                          CLASSES = c(3);
                          IDVARIABLE = id;
                          AUXILIARY = tclass;        ! saved alongside results, not modeled

                ANALYSIS: TYPE = MIXTURE;
                          STARTS = 500 100;          ! random starts: initial stage, final stage
                          LRTSTARTS = 0 0 100 20;    ! starts for the bootstrap LRT (TECH14)

                OUTPUT:   TECH11 TECH14;             ! VLMR/LMR and bootstrap LRT: K vs. K − 1 classes

                SAVEDATA: FILE = lca3_post.dat;
                          SAVE = CPROBABILITIES;     ! posterior probabilities + most likely class
                """#
            )),
            .keyPoint("Name classes by their profiles", "Here, one class mostly rereads and takes notes (*passive review*), one self-tests and spaces practice (*active practice*), and one explains material and studies with peers (*social learning*). Class numbers are arbitrary and can swap between runs; identify classes by their profiles, never by their number."),
            .keyPoint("A preregisterable rule", "“Choose the model with the lowest BIC, unless a class holds < 5% of cases or two classes are indistinguishable — then take the next-lowest.”"),
            .caution("Relating classes to other variables", "Comparing GPA across *most-likely* classes ignores classification uncertainty. Three-step methods (BCH, DCON, DCAT, R3STEP — see *Mixture models in Mplus*) correct for it."),
            .exercise(Exercise(
                title: "Did LCA find the truth?",
                prompt: "Cross-tabulate the estimated class with `true_class`. How well were the three types recovered?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    est = habits["class"]
                    print(pd.crosstab(est, habits["true_class"]))
                    """#,
                    r: #"""
                    est <- best$predclass
                    table(estimated = est, true = habits$true_class)
                    """#
                ),
                answer: "Each estimated class lines up mostly with one true class (possibly in a different order). Some students are misclassified because their particular answers happen to resemble another type.",
                selfCheck: SelfCheck(
                    names: "`est` — each student's most likely class (1, 2, or 3), in the original row order",
                    python: #"""
                    from itertools import permutations
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        truth = pd.read_csv("habits.csv")["true_class"].to_numpy()
                        est_arr = np.asarray(est).astype(int)
                        check("One class per student", len(est_arr), len(truth), tol=0)
                        check("Three classes, labelled 1–3", sorted(set(est_arr)), [1, 2, 3], tol=0)
                        # Class numbers are arbitrary, so score the best matching of labels.
                        agreement = max((np.array(p)[est_arr - 1] == truth).mean() for p in permutations([1, 2, 3]))
                        print(f"Agreement with the true types: {agreement:.0%}")
                        check("At least 70% classified correctly", agreement >= 0.70, True,
                              hint="Fit 3 classes with several random starts (n_init) and keep the best.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      truth <- read.csv("habits.csv")$true_class
                      check("One class per student", length(est), length(truth), tol = 0)
                      check("Three classes, labelled 1–3", sort(unique(est)), 1:3, tol = 0)
                      # Class numbers are arbitrary, so score the best matching of labels.
                      perms <- list(c(1, 2, 3), c(1, 3, 2), c(2, 1, 3), c(2, 3, 1), c(3, 1, 2), c(3, 2, 1))
                      agreement <- max(sapply(perms, function(p) mean(p[est] == truth)))
                      cat(sprintf("Agreement with the true types: %.0f%%\n", 100 * agreement))
                      check("At least 70% classified correctly", agreement >= 0.70, TRUE,
                            hint = "Fit 3 classes with several random starts (nrep) and keep the best.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "The most typical member",
                prompt: "For each class, find the student with the highest posterior probability of belonging to it, and list their strategies.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    for k in range(post.shape[1]):
                        i = post[:, k].argmax()
                        print(k + 1, round(post[i, k], 3), habits.iloc[i][strategies].to_dict())
                    """#,
                    r: #"""
                    for (k in 1:ncol(post)) {
                      i <- which.max(post[, k])
                      print(c(class = k, prob = round(post[i, k], 3), unlist(habits[i, 2:7])))
                    }
                    """#
                ),
                answer: "Each prototype shows its class's signature pattern of strategies — a concrete way to describe what a class means."
            )),
        ],
        quiz: [
            Question(
                prompt: "BIC values for 2, 3, and 4 classes are 3110, 3052, and 3071. Which model does BIC favor?",
                options: ["2 classes", "3 classes", "4 classes", "None"],
                answer: 1,
                explanation: "Lowest BIC = 3 classes."
            ),
            Question(
                prompt: "Two indicators are near-duplicates (almost always answered the same way). Why is that a problem for LCA?",
                options: ["It slows estimation", "It violates local independence", "LCA can't use binary items", "It lowers BIC"],
                answer: 1,
                explanation: "Correlated indicators within a class get mistaken for extra classes. Merge or drop one."
            ),
        ]
    )

    // MARK: Text as data

    static let clustering = Lesson(
        id: "clustering",
        title: "Text embeddings & clustering",
        summary: "Cosine similarity, k-means with silhouettes, HDBSCAN, and medoids.",
        minutes: 13,
        blocks: [
            .text("A **sentence embedding** turns text into a list of numbers that represents its meaning; similar sentences get similar vectors (e.g. Sentence-BERT; Reimers & Gurevych, 2019). Clustering those vectors is a data-driven robustness check on hand-coded types."),
            .model(ModelExplainer(
                name: "k-means clustering and the silhouette",
                purpose: "Partitions observations into k groups so that each observation is closer to its own group's center than to any other center.",
                equation: "minimize Σₖ Σ_{i in k} ‖xᵢ − cₖ‖²        silhouette(i) = (b − a) / max(a, b)",
                steps: [
                    "Pick k starting centers (k-means++ spreads them out).",
                    "Assign every observation to its nearest center.",
                    "Move each center to the mean of its assigned observations; repeat assignment and update until nothing changes.",
                    "Run from several random starts and keep the best solution.",
                    "For each observation, the **silhouette** compares its average distance to its own cluster (a) with that to the nearest other cluster (b). Average silhouettes near 1 indicate well-separated clusters; choose the k with the highest average.",
                ],
                conditions: [
                    "**Meaningful distances** between observations (normalized embeddings, or standardized variables).",
                    "Clusters that are roughly **compact and similar in size** — for irregular shapes or noise, prefer HDBSCAN.",
                    "Results are **descriptive**: validate clusters against other evidence.",
                ],
                reading: "Rousseeuw (1987), *Journal of Computational and Applied Mathematics*, 20, 53–65; Reimers & Gurevych (2019), *EMNLP* (Sentence-BERT); McInnes, Healy & Astels (2017), *Journal of Open Source Software*, 2(11), 205 (HDBSCAN)."
            )),
            .terms([
                Term("Embedding", "A numeric vector (often 384–768 numbers) representing a text's meaning."),
                Term("Cosine similarity", "The angle between two vectors: 1 = same direction (very similar meaning), 0 = unrelated."),
                Term("k-means", "Splits data into k clusters by minimizing distance to each cluster's center. You choose k."),
                Term("Silhouette", "−1 to +1: how well each point fits its own cluster vs. the next-nearest one. Choose the k with the highest average."),
                Term("HDBSCAN", "Finds dense groups without fixing k in advance and labels one-off points as **noise** instead of forcing them into a cluster."),
                Term("Medoid", "The real observation with the smallest total distance to the rest of its cluster — a natural prototype."),
                Term("Adjusted Rand index (ARI)", "Agreement between two clusterings, corrected for chance: 0 = chance, 1 = identical."),
            ]),
            .code(CodeSample(
                caption: "Embed sentences, choose k by silhouette, run HDBSCAN, find medoids",
                python: #"""
                # pip install sentence-transformers scikit-learn
                import numpy as np
                import pandas as pd
                from sentence_transformers import SentenceTransformer
                from sklearn.cluster import KMeans, HDBSCAN
                from sklearn.metrics import silhouette_score
                from sklearn.metrics.pairwise import cosine_similarity

                texts = [
                    "Simmer the onions slowly until they turn golden.",
                    "Add a pinch of salt to the pasta water before boiling.",
                    "This soup tastes better the day after you make it.",
                    "Fold the egg whites gently into the batter.",
                    "Heavy rain is expected across the region tonight.",
                    "Tomorrow will be sunny with a light breeze.",
                    "A cold front is bringing snow to the mountains.",
                    "Humidity will stay high through the weekend.",
                    "Stretch your hamstrings before you start running.",
                    "She swims thirty laps every morning before work.",
                    "Interval training builds endurance quickly.",
                    "Rest days help your muscles recover after lifting.",
                ]

                model = SentenceTransformer("all-MiniLM-L6-v2")      # downloads once (~90 MB)
                emb = model.encode(texts, normalize_embeddings=True)
                pd.DataFrame(emb).to_csv("embeddings.csv", index=False)   # for the R version

                sim = cosine_similarity(emb)
                print("similarity of text 0 to texts 1–3:", sim[0, 1:4].round(2))

                for k in range(2, 7):
                    labels = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(emb)
                    print(k, round(silhouette_score(emb, labels, metric="cosine"), 3))

                print("HDBSCAN:", HDBSCAN(min_cluster_size=3).fit_predict(emb))   # −1 = noise

                labels = KMeans(n_clusters=3, n_init=10, random_state=0).fit_predict(emb)
                for c in np.unique(labels):
                    idx = np.where(labels == c)[0]
                    medoid = idx[(1 - sim[np.ix_(idx, idx)]).sum(axis=1).argmin()]
                    print(f"cluster {c} prototype: {texts[medoid]}")
                """#,
                r: #"""
                # Embeddings are usually computed in Python; run the Python version first
                # to create embeddings.csv, then cluster in R.
                library(cluster)
                library(dbscan)

                emb <- as.matrix(read.csv("embeddings.csv"))
                d <- dist(emb)   # on normalized embeddings, Euclidean ranks pairs like cosine

                set.seed(0)
                for (k in 2:6) {
                  km <- kmeans(emb, centers = k, nstart = 25)
                  cat(k, round(mean(silhouette(km$cluster, d)[, "sil_width"]), 3), "\n")
                }

                hdbscan(emb, minPts = 3)$cluster   # 0 = noise

                km <- kmeans(emb, centers = 3, nstart = 25)
                dm <- as.matrix(d)
                sapply(1:3, function(c) {
                  idx <- which(km$cluster == c)
                  idx[which.min(rowSums(dm[idx, idx, drop = FALSE]))]   # medoid row
                })
                """#
            )),
            .keyPoint("Triangulate", "If hand-coded types (e.g. from LCA) and embedding clusters roughly agree — measured with the adjusted Rand index — the types are robust. If they don't, examine which texts move between groups."),
            .caution("Offline alternative", "No internet or GPU? Use TF-IDF vectors instead: `TfidfVectorizer().fit_transform(texts)` in scikit-learn. They capture shared *words* rather than meaning, so expect cruder clusters."),
            .exercise(Exercise(
                title: "Compare two clusterings",
                prompt: "Assume the true groups are cooking (texts 0–3), weather (4–7), and exercise (8–11). Compute the adjusted Rand index between these labels and your k = 3 clustering.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    from sklearn.metrics import adjusted_rand_score
                    truth = [0] * 4 + [1] * 4 + [2] * 4
                    ari = adjusted_rand_score(truth, labels)
                    print(ari)
                    """#,
                    r: #"""
                    library(mclust)
                    truth <- rep(1:3, each = 4)
                    ari <- adjustedRandIndex(truth, km$cluster)
                    ari
                    """#
                ),
                answer: "ARI is high (often 1.0 for this tiny example). The groups are distinct in meaning, so embeddings separate them cleanly.",
                selfCheck: SelfCheck(
                    names: "`ari`, plus your k = 3 cluster labels (`labels` in Python, `km` in R)",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # The ARI from first principles: pair-counting agreement, corrected for chance.
                        def comb2(x):
                            return x * (x - 1) / 2

                        truth = np.repeat([0, 1, 2], 4)
                        table = np.array([[np.sum((truth == t) & (np.asarray(labels) == c)) for c in np.unique(labels)]
                                          for t in range(3)])
                        index = comb2(table).sum()
                        rows, cols = comb2(table.sum(axis=1)).sum(), comb2(table.sum(axis=0)).sum()
                        expected_index = rows * cols / comb2(len(truth))
                        expected = (index - expected_index) / ((rows + cols) / 2 - expected_index)
                        check("Adjusted Rand index", ari, expected, tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # The ARI from first principles: pair-counting agreement, corrected for chance.
                      comb2 <- function(x) x * (x - 1) / 2
                      tab <- table(rep(1:3, each = 4), km$cluster)
                      index <- sum(comb2(tab))
                      rows <- sum(comb2(rowSums(tab))); cols <- sum(comb2(colSums(tab)))
                      expected_index <- rows * cols / comb2(12)
                      check("Adjusted Rand index", ari, (index - expected_index) / ((rows + cols) / 2 - expected_index),
                            tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Within vs. between similarity",
                prompt: "Compute all pairwise cosine similarities *within* each true group and find the lowest. Then find the highest similarity *between* texts from different groups. Do the two ranges overlap?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    within_min = []
                    for g in range(3):
                        block = sim[4 * g:4 * g + 4, 4 * g:4 * g + 4]
                        within_min.append(block[np.triu_indices(4, k=1)].min())
                    group = np.repeat([0, 1, 2], 4)
                    between_max = sim[group[:, None] != group[None, :]].max()
                    print(np.round(within_min, 2), round(between_max, 2))
                    """#,
                    r: #"""
                    sim <- emb %*% t(emb)   # dot product = cosine for normalized vectors
                    within_min <- sapply(0:2, function(g) {
                      block <- sim[(4 * g + 1):(4 * g + 4), (4 * g + 1):(4 * g + 4)]
                      min(block[upper.tri(block)])
                    })
                    group <- rep(1:3, each = 4)
                    between_max <- max(sim[outer(group, group, "!=")])
                    round(c(within_min, between = between_max), 2)
                    """#
                ),
                answer: "Within-topic similarities are clearly higher than between-topic ones, with little or no overlap — which is exactly why clustering separates them so easily. When the ranges do overlap, expect some texts to land in the “wrong” cluster.",
                selfCheck: SelfCheck(
                    names: "`within_min` (the lowest within-group similarity for each of the 3 groups) and `between_max`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        e = pd.read_csv("embeddings.csv").to_numpy()
                        e = e / np.linalg.norm(e, axis=1, keepdims=True)
                        s = e @ e.T
                        group = np.repeat([0, 1, 2], 4)
                        pairs = np.triu(np.ones_like(s, dtype=bool), k=1)
                        expected_within = [s[pairs & (group[:, None] == g) & (group[None, :] == g)].min() for g in range(3)]
                        check("Lowest within-group similarity (cooking, weather, exercise)", within_min, expected_within,
                              tol=0.001, hint="Exclude the diagonal — each text's similarity to itself is 1.")
                        check("Highest between-group similarity", between_max,
                              s[group[:, None] != group[None, :]].max(), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      e <- as.matrix(read.csv("embeddings.csv"))
                      e <- e / sqrt(rowSums(e^2))
                      s <- e %*% t(e)
                      group <- rep(1:3, each = 4)
                      pairs <- upper.tri(s)
                      expected_within <- sapply(1:3, function(g) min(s[pairs & outer(group == g, group == g)]))
                      check("Lowest within-group similarity (cooking, weather, exercise)", within_min, expected_within,
                            tol = 0.001, hint = "Exclude the diagonal — each text's similarity to itself is 1.")
                      check("Highest between-group similarity", between_max, max(s[outer(group, group, "!=")]),
                            tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Average silhouettes for k = 2…5 are .21, .38, .29, .25. Which k?",
                options: ["2", "3", "4", "5"],
                answer: 1,
                explanation: "Pick the k with the highest average silhouette."
            ),
            Question(
                prompt: "What does HDBSCAN do with an unusual one-off text?",
                options: ["Forces it into the nearest cluster", "Labels it as noise", "Deletes it", "Makes it its own cluster"],
                answer: 1,
                explanation: "HDBSCAN marks low-density points as noise (−1 in Python, 0 in R)."
            ),
        ]
    )

    static let keyness = Lesson(
        id: "keyness",
        title: "Keyness: words that distinguish groups",
        summary: "Weighted log-odds with an informative Dirichlet prior.",
        minutes: 10,
        blocks: [
            .text("Which words are characteristic of one group's texts compared with another's? Raw frequency differences overstate rare words (one extra use of a rare word looks huge). The **weighted log-odds ratio with an informative Dirichlet prior** (Monroe, Colaresi & Quinn, 2008) shrinks noisy estimates toward a background rate and expresses each word's distinctiveness as a z-score."),
            .model(ModelExplainer(
                name: "Weighted log-odds with an informative Dirichlet prior",
                purpose: "Ranks words by how strongly they distinguish two corpora, shrinking estimates for rare words toward a background rate so they aren't over-interpreted.",
                equation: "δ_w = log[(y_wA + α_w) / (n_A + α₀ − y_wA − α_w)] − log[(y_wB + α_w) / (n_B + α₀ − y_wB − α_w)]\nz_w = δ_w / √[1/(y_wA + α_w) + 1/(y_wB + α_w)]",
                steps: [
                    "Count each word in both corpora (y_wA, y_wB) and the corpus sizes (n_A, n_B).",
                    "Add **prior pseudo-counts** α_w based on background frequencies (e.g. the pooled corpus); α₀ is their total.",
                    "Compute the log-odds of the word in each corpus with the prior added, and take the difference δ_w.",
                    "Divide by its approximate standard error to get z_w: large positive z means distinctive of corpus A, large negative of corpus B.",
                ],
                conditions: [
                    "**Comparable corpora** (same genre, task, or prompt), so differences reflect the groups rather than the material.",
                    "**Decisions made in advance** about tokenization, stop words, and the prior's strength.",
                    "Treat results as **exploratory** — candidates to test in a confirmatory design.",
                ],
                reading: "Monroe, Colaresi & Quinn (2008), *Political Analysis*, 16(4), 372–403; Schnoebelen, Silge & Hayes, *tidylo* R package documentation."
            )),
            .terms([
                Term("Keyness", "How strongly a word is associated with one corpus relative to another."),
                Term("Log-odds ratio", "log(odds of the word in group A) − log(odds in group B)."),
                Term("Dirichlet prior", "Pseudo-counts added to every word, based on background frequencies, so rare words aren't over-interpreted."),
                Term("Weighted log-odds (z)", "The log-odds ratio divided by its standard error. |z| > 1.96 is a common cutoff."),
            ]),
            .code(CodeSample(
                caption: "Which words distinguish beginner from expert cooking questions?",
                python: #"""
                import re
                from collections import Counter
                import numpy as np
                import pandas as pd

                beginner = ["what is an easy quick dinner", "simple easy recipe for rice",
                            "how do i make quick pasta", "easy simple soup for beginners",
                            "quick lunch ideas that are easy", "how long do i boil an egg"]
                expert = ["what ratio of fat to flour makes a roux", "how do i stabilize an emulsion",
                          "technique for searing scallops", "best ratio for a brine",
                          "how do i keep an emulsion from breaking", "searing technique for duck breast"]

                def tokens(text):
                    return re.findall(r"[a-z']+", text.lower())

                counts = pd.DataFrame({
                    "a": Counter(w for t in beginner for w in tokens(t)),
                    "b": Counter(w for t in expert for w in tokens(t)),
                }).fillna(0)

                prior = counts["a"] + counts["b"]          # background = pooled counts
                a0 = prior.sum()
                n_a, n_b = counts["a"].sum(), counts["b"].sum()

                delta = (np.log((counts["a"] + prior) / (n_a + a0 - counts["a"] - prior))
                         - np.log((counts["b"] + prior) / (n_b + a0 - counts["b"] - prior)))
                counts["z"] = delta / np.sqrt(1 / (counts["a"] + prior) + 1 / (counts["b"] + prior))

                print(counts.sort_values("z", ascending=False).round(2))   # top = beginner words
                """#,
                r: #"""
                library(tidyverse)
                library(tidytext)
                library(tidylo)

                docs <- tibble(
                  group = rep(c("beginner", "expert"), each = 6),
                  text  = c("what is an easy quick dinner", "simple easy recipe for rice",
                            "how do i make quick pasta", "easy simple soup for beginners",
                            "quick lunch ideas that are easy", "how long do i boil an egg",
                            "what ratio of fat to flour makes a roux", "how do i stabilize an emulsion",
                            "technique for searing scallops", "best ratio for a brine",
                            "how do i keep an emulsion from breaking", "searing technique for duck breast")
                )

                docs |>
                  unnest_tokens(word, text) |>
                  count(group, word) |>
                  bind_log_odds(set = group, feature = word, n = n) |>   # informative prior by default
                  arrange(desc(log_odds_weighted))
                """#
            )),
            .keyPoint("Exploratory by nature", "Keyness generates **candidate** features from a corpus. Treat the list as hypotheses to test with new data, for example in a controlled experiment."),
            .caution("Function words and stop words", "Words like “how”, “do”, and “I” can be genuinely distinctive (beginners ask *how do I*). Decide in advance whether to remove stop words — the choice changes the list."),
            .exercise(Exercise(
                title: "Stronger prior",
                prompt: "Multiply the prior by 5 (`prior = 5 * (a + b)`). What happens to the z-scores, and why?",
                answer: "All z-scores shrink toward 0, and rare words drop down the list. A stronger prior means more evidence is needed before a word counts as distinctive — useful with small corpora."
            )),
        ],
        quiz: [
            Question(
                prompt: "Why use an informative prior rather than raw log-odds?",
                options: [
                    "To make every word significant",
                    "Raw log-odds exaggerate differences for rare words",
                    "Priors remove stop words",
                    "Raw log-odds can't be computed",
                ],
                answer: 1,
                explanation: "A word used once vs. zero times has infinite raw log-odds; the prior shrinks such estimates."
            ),
        ]
    )
}

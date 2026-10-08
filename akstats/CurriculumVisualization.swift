import Foundation

// MARK: - Unit 6 · Visualizing statistics

extension Curriculum {
    static let visualizingStats = Unit(
        id: "visualizing-stats", number: 6, title: "Visualizing statistics", level: .intermediate,
        summary: "Clear, honest figures in matplotlib/seaborn and ggplot2.",
        symbol: "chart.xyaxis.line",
        lessons: [plottingBasics, plottingGroups, plottingRelationships, plottingModels, publicationFigures]
    )

    static let plottingBasics = Lesson(
        id: "plotting-basics",
        title: "How plotting works in Python & R",
        summary: "Figures and axes vs. the grammar of graphics.",
        minutes: 10,
        blocks: [
            .text("**ggplot2** (R) builds plots from the *grammar of graphics*: map variables to visual properties (**aesthetics**), then add **layers** of shapes (**geoms**). **matplotlib** (Python) draws onto a **figure** containing one or more **axes**; **seaborn** sits on top of matplotlib and adds statistical plots that take a DataFrame and column names — much like ggplot."),
            .terms([
                Term("Aesthetic mapping", "Linking a variable to x, y, color, size, or shape: `aes(x = rumination, y = anxiety)`."),
                Term("Geom / layer", "A visual element: points, lines, bars. ggplot adds layers with `+`."),
                Term("Facet", "Small multiples — the same plot repeated for each subgroup."),
                Term("Figure & axes", "matplotlib's canvas (figure) and the plotting area(s) inside it (axes)."),
                Term("Theme", "Non-data styling: fonts, gridlines, background."),
            ]),
            .code(CodeSample(
                caption: "The same scatterplot, two ways",
                python: #"""
                import pandas as pd
                import seaborn as sns
                import matplotlib.pyplot as plt

                survey = pd.read_csv("survey.csv")

                # Okabe–Ito: a colorblind-safe categorical palette
                palette = {"urban": "#E69F00", "rural": "#0072B2"}

                fig, ax = plt.subplots(figsize=(6, 4))
                sns.scatterplot(data=survey, x="rumination", y="anxiety", hue="region",
                                palette=palette, alpha=0.6, s=30, ax=ax)
                ax.set(xlabel="Rumination (1–7)", ylabel="Anxiety (1–7)")
                sns.despine()                     # remove top/right borders
                plt.tight_layout()
                plt.show()
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")

                # Okabe–Ito: a colorblind-safe categorical palette
                palette <- c(urban = "#E69F00", rural = "#0072B2")

                ggplot(survey, aes(x = rumination, y = anxiety, colour = region)) +
                  geom_point(alpha = 0.6, size = 1.8) +
                  scale_colour_manual(values = palette) +
                  labs(x = "Rumination (1–7)", y = "Anxiety (1–7)", colour = NULL) +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Small multiples: one panel per group",
                python: #"""
                g = sns.relplot(data=survey, x="rumination", y="anxiety", col="region",
                                height=3.5, alpha=0.6, color="#0072B2")
                g.set_axis_labels("Rumination", "Anxiety")
                plt.show()
                """#,
                r: #"""
                ggplot(survey, aes(rumination, anxiety)) +
                  geom_point(alpha = 0.6, colour = "#0072B2") +
                  facet_wrap(~ region) +
                  theme_classic()
                """#
            )),
            .keyPoint("Color has a job", "Use color only when it encodes something: **categories** get distinct hues in a fixed order, **magnitudes** get a single hue from light to dark, and **signed values** (−/+) get two hues with a neutral midpoint."),
            .exercise(Exercise(
                title: "Your first plot",
                prompt: "Plot `social_media` (x) against `rumination` (y), with a separate panel for each `region`. Label both axes.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    g = sns.relplot(data=survey, x="social_media", y="rumination", col="region",
                                    height=3.5, alpha=0.6, color="#009E73")
                    g.set_axis_labels("Social media use", "Rumination")
                    plt.show()
                    """#,
                    r: #"""
                    ggplot(survey, aes(social_media, rumination)) +
                      geom_point(alpha = 0.6, colour = "#009E73") +
                      facet_wrap(~ region) +
                      labs(x = "Social media use", y = "Rumination") +
                      theme_classic()
                    """#
                ),
                answer: "Both panels show a positive, roughly linear cloud — more social media use goes with more rumination in each group."
            )),
        ],
        quiz: [
            Question(
                prompt: "In ggplot2, what does `aes(colour = region)` do?",
                options: ["Colors every point the same", "Maps the region variable to color", "Adds a legend title only", "Facets by region"],
                answer: 1,
                explanation: "Aesthetics map data variables to visual properties."
            ),
        ]
    )

    static let plottingGroups = Lesson(
        id: "plotting-groups",
        title: "Visualizing group comparisons",
        summary: "Raw data with means and CIs, distributions, and pre/post change.",
        minutes: 11,
        blocks: [
            .text("For group comparisons, show the **raw data** together with the **summary** (mean and 95% CI). Bar charts of means hide sample size and spread, so prefer points, intervals, and distributions."),
            .code(CodeSample(
                caption: "Raw points + mean and 95% CI per teaching method",
                python: #"""
                import pandas as pd
                import seaborn as sns
                import matplotlib.pyplot as plt

                classroom = pd.read_csv("classroom.csv")
                order = ["lecture", "active", "flipped"]

                fig, ax = plt.subplots(figsize=(5, 4))
                sns.stripplot(data=classroom, x="method", y="posttest", order=order,
                              color="0.65", alpha=0.6, jitter=0.15, ax=ax)
                sns.pointplot(data=classroom, x="method", y="posttest", order=order,
                              errorbar=("ci", 95), color="black", linestyle="none",
                              capsize=0.15, ax=ax)      # seaborn ≥ 0.13
                ax.set(xlabel=None, ylabel="Post-test score (0–100)")
                sns.despine()
                plt.show()
                """#,
                r: #"""
                library(tidyverse)

                classroom <- read_csv("classroom.csv") |>
                  mutate(method = factor(method, levels = c("lecture", "active", "flipped")))

                summary_df <- classroom |>
                  group_by(method) |>
                  summarise(mean = mean(posttest), se = sd(posttest) / sqrt(n()),
                            ci = qt(0.975, n() - 1) * se)

                ggplot(classroom, aes(method, posttest)) +
                  geom_jitter(width = 0.15, alpha = 0.6, colour = "grey65") +
                  geom_pointrange(data = summary_df,
                                  aes(y = mean, ymin = mean - ci, ymax = mean + ci), size = 0.6) +
                  labs(x = NULL, y = "Post-test score (0–100)") +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Within-person change: one line per student",
                python: #"""
                long = classroom.melt(id_vars=["student", "method"], value_vars=["pretest", "posttest"],
                                var_name="time", value_name="score")
                long["time"] = long["time"].map({"pretest": "Pre", "posttest": "Post"})

                g = sns.FacetGrid(long, col="method", col_order=order, height=3.5)
                g.map_dataframe(sns.lineplot, x="time", y="score", units="student",
                                estimator=None, color="0.75", linewidth=0.8)
                g.map_dataframe(sns.pointplot, x="time", y="score", color="#0072B2", errorbar=("ci", 95))
                g.set_axis_labels("", "Score (0–100)")
                plt.show()
                """#,
                r: #"""
                long <- classroom |>
                  pivot_longer(c(pretest, posttest), names_to = "time", values_to = "score") |>
                  mutate(time = factor(time, levels = c("pretest", "posttest"), labels = c("Pre", "Post")))

                ggplot(long, aes(time, score)) +
                  geom_line(aes(group = student), colour = "grey75", linewidth = 0.4) +
                  stat_summary(aes(group = 1), fun = mean, geom = "line", colour = "#0072B2", linewidth = 1.2) +
                  facet_wrap(~ method) +
                  labs(x = NULL, y = "Score (0–100)") +
                  theme_classic()
                """#
            )),
            .keyPoint("Match the plot to the design", "Between-groups: points + means and CIs. Within-person: connect each person's measurements so readers can see individual change, not just the group average."),
            .caution("Error bars must be labeled", "SD, SE, and 95% CI bars look identical but mean very different things. Say which one you're showing in the caption."),
            .exercise(Exercise(
                title: "Distributions by group",
                prompt: "Make violin plots of `posttest` by method, with a narrow boxplot inside each violin.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    fig, ax = plt.subplots(figsize=(5, 4))
                    sns.violinplot(data=classroom, x="method", y="posttest", order=order, color="#56B4E9",
                                   inner=None, linewidth=0.8, ax=ax)
                    sns.boxplot(data=classroom, x="method", y="posttest", order=order, width=0.15,
                                color="white", showfliers=False, ax=ax)
                    sns.despine()
                    plt.show()
                    """#,
                    r: #"""
                    ggplot(classroom, aes(method, posttest)) +
                      geom_violin(fill = "#56B4E9", colour = NA, alpha = 0.6) +
                      geom_boxplot(width = 0.15, outlier.shape = NA) +
                      theme_classic()
                    """#
                ),
                answer: "The active-learning distribution sits visibly higher than lecture's; flipped is only slightly higher."
            )),
        ],
        quiz: [
            Question(
                prompt: "Why are bar charts of means discouraged for continuous outcomes?",
                options: ["They're hard to make", "They hide sample size, spread, and outliers", "Journals ban them", "They require color"],
                answer: 1,
                explanation: "Showing raw data alongside the summary is more honest and informative."
            ),
        ]
    )

    static let plottingRelationships = Lesson(
        id: "plotting-relationships",
        title: "Relationships & interactions",
        summary: "Regression lines, simple-slopes plots, and correlation heatmaps.",
        minutes: 12,
        blocks: [
            .code(CodeSample(
                caption: "Scatterplot with a regression line and 95% band",
                python: #"""
                import numpy as np
                import pandas as pd
                import seaborn as sns
                import matplotlib.pyplot as plt
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])

                fig, ax = plt.subplots(figsize=(5, 4))
                sns.regplot(data=survey, x="rumination", y="anxiety", ax=ax,
                            scatter_kws={"alpha": 0.4, "s": 20, "color": "0.5"},
                            line_kws={"color": "#0072B2"})
                ax.set(xlabel="Rumination", ylabel="Anxiety")
                sns.despine()
                plt.show()
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv") |> drop_na(mindfulness)

                ggplot(survey, aes(rumination, anxiety)) +
                  geom_point(alpha = 0.4, colour = "grey50") +
                  geom_smooth(method = "lm", colour = "#0072B2", fill = "#0072B2", alpha = 0.15) +
                  labs(x = "Rumination", y = "Anxiety") +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Simple-slopes plot for a continuous interaction",
                python: #"""
                model = smf.ols("rumination ~ social_media * mindfulness", data=survey).fit()

                m, sd = survey["mindfulness"].mean(), survey["mindfulness"].std()
                levels = {"Low (−1 SD)": m - sd, "Average": m, "High (+1 SD)": m + sd}
                colors = ["#D55E00", "#999999", "#0072B2"]
                xs = np.linspace(survey["social_media"].min(), survey["social_media"].max(), 50)

                fig, ax = plt.subplots(figsize=(5.5, 4))
                for (label, w), color in zip(levels.items(), colors):
                    grid = pd.DataFrame({"social_media": xs, "mindfulness": w})
                    pred = model.get_prediction(grid).summary_frame(alpha=0.05)
                    ax.plot(xs, pred["mean"], color=color, linewidth=2)
                    ax.fill_between(xs, pred["mean_ci_lower"], pred["mean_ci_upper"], color=color, alpha=0.15)
                    ax.text(xs[-1] + 0.1, pred["mean"].iloc[-1], label, color="0.2", va="center")  # direct label
                ax.set(xlabel="Social media use", ylabel="Predicted rumination")
                sns.despine()
                plt.tight_layout()
                plt.show()
                """#,
                r: #"""
                model <- lm(rumination ~ social_media * mindfulness, data = survey)

                m <- mean(survey$mindfulness); s <- sd(survey$mindfulness)
                grid <- expand_grid(
                  social_media = seq(min(survey$social_media), max(survey$social_media), length.out = 50),
                  mindfulness  = c(m - s, m, m + s)
                )
                pred <- predict(model, grid, interval = "confidence")
                grid <- bind_cols(grid, as_tibble(pred)) |>
                  mutate(level = factor(mindfulness, labels = c("Low (−1 SD)", "Average", "High (+1 SD)")))

                ggplot(grid, aes(social_media, fit, colour = level, fill = level)) +
                  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.15, colour = NA) +
                  geom_line(linewidth = 1) +
                  scale_colour_manual(values = c("#D55E00", "#999999", "#0072B2")) +
                  scale_fill_manual(values = c("#D55E00", "#999999", "#0072B2")) +
                  labs(x = "Social media use", y = "Predicted rumination", colour = "Mindfulness", fill = "Mindfulness") +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Correlation heatmap with a diverging scale",
                python: #"""
                cols = ["social_media", "phone_checking", "rumination", "anxiety", "mindfulness", "age"]
                corr = survey[cols].corr()

                fig, ax = plt.subplots(figsize=(6, 5))
                sns.heatmap(corr, vmin=-1, vmax=1, center=0, cmap="RdBu_r",
                            annot=True, fmt=".2f", square=True, linewidths=2, ax=ax)
                plt.show()
                """#,
                r: #"""
                cols <- c("social_media", "phone_checking", "rumination", "anxiety", "mindfulness", "age")
                corr <- cor(survey[cols]) |>
                  as_tibble(rownames = "var1") |>
                  pivot_longer(-var1, names_to = "var2", values_to = "r")

                ggplot(corr, aes(var1, var2, fill = r)) +
                  geom_tile(colour = "white", linewidth = 1) +
                  geom_text(aes(label = sprintf("%.2f", r)), size = 3) +
                  scale_fill_gradient2(low = "#2166AC", mid = "grey95", high = "#B2182B",
                                       midpoint = 0, limits = c(-1, 1)) +
                  labs(x = NULL, y = NULL) +
                  theme_minimal() +
                  theme(axis.text.x = element_text(angle = 45, hjust = 1))
                """#
            )),
            .keyPoint("Diverging data, diverging color", "Correlations run from −1 to +1, so use two hues with a **neutral midpoint at 0** and fix the limits at ±1. Otherwise the color scale stretches to your data and exaggerates weak correlations."),
            .exercise(Exercise(
                title: "Plot moderation in the raw data",
                prompt: "Split mindfulness into thirds *for plotting only* and draw a separate regression line of rumination on social media for each third. Does the picture match the simple-slopes plot?",
                hint: "`pd.qcut(survey[\"mindfulness\"], 3, labels=[\"low\", \"mid\", \"high\"])` or `ntile(mindfulness, 3)` in R.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    survey["mind_third"] = pd.qcut(survey["mindfulness"], 3, labels=["low", "mid", "high"])
                    third_slopes = [np.polyfit(g["social_media"], g["rumination"], 1)[0]
                                    for _, g in survey.groupby("mind_third", observed=True)]
                    print(np.round(third_slopes, 3))
                    sns.lmplot(data=survey, x="social_media", y="rumination", hue="mind_third",
                               palette=["#D55E00", "#999999", "#0072B2"], scatter_kws={"alpha": 0.3})
                    plt.show()
                    """#,
                    r: #"""
                    survey <- survey |>
                      mutate(mind_third = factor(ntile(mindfulness, 3), labels = c("low", "mid", "high")))
                    third_slopes <- sapply(split(survey, survey$mind_third),
                                           function(g) coef(lm(rumination ~ social_media, data = g))[[2]])
                    round(third_slopes, 3)

                    ggplot(survey, aes(social_media, rumination, colour = mind_third)) +
                      geom_point(alpha = 0.3) +
                      geom_smooth(method = "lm", se = FALSE) +
                      scale_colour_manual(values = c("#D55E00", "#999999", "#0072B2")) +
                      theme_classic()
                    """#
                ),
                answer: "The low-mindfulness line is steepest and the high-mindfulness line flattest — the same pattern as the model-based plot. (Analyze with the continuous moderator; split only for display.)",
                selfCheck: SelfCheck(
                    names: "`third_slopes` — the slope of rumination on social media in the low, middle, and high thirds of mindfulness",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv").dropna(subset=["mindfulness"])
                        ref["third"] = pd.qcut(ref["mindfulness"], 3, labels=False)
                        # Slope = cov(x, y) / var(x) within each third
                        expected = [g["social_media"].cov(g["rumination"]) / g["social_media"].var()
                                    for _, g in ref.groupby("third")]
                        check("Slopes in the low, middle, and high thirds", third_slopes, expected, tol=0.002,
                              hint="Fit a separate line within each third, ordered low → high.")
                        check("Steepest at low mindfulness, flattest at high", third_slopes[0] > third_slopes[2], True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")
                    library(dplyr)

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref <- ref[!is.na(ref$mindfulness), ]
                      ref$third <- ntile(ref$mindfulness, 3)
                      # Slope = cov(x, y) / var(x) within each third
                      expected <- sapply(split(ref, ref$third), function(g) cov(g$social_media, g$rumination) / var(g$social_media))
                      check("Slopes in the low, middle, and high thirds", third_slopes, expected, tol = 0.002,
                            hint = "Fit a separate line within each third, ordered low → high.")
                      check("Steepest at low mindfulness, flattest at high", third_slopes[[1]] > third_slopes[[3]], TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Which color scale suits a correlation matrix?",
                options: ["Rainbow", "Single hue light→dark", "Two hues with a neutral midpoint at 0", "Random colors"],
                answer: 2,
                explanation: "Correlations are signed, so a diverging scale centered on 0 is appropriate."
            ),
        ]
    )

    static let plottingModels = Lesson(
        id: "plotting-models",
        title: "Plotting model results",
        summary: "Coefficient plots, ordinal response distributions, and transition heatmaps.",
        minutes: 11,
        blocks: [
            .text("The second and third plots use `judgments.csv` and `commutes.csv` from the *generate_more_data* script in **Practice datasets** (Unit 0)."),
            .code(CodeSample(
                caption: "Coefficient (forest) plot with 95% CIs",
                python: #"""
                import pandas as pd
                import matplotlib.pyplot as plt
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                z = survey.copy()
                for col in ["anxiety", "rumination", "social_media", "phone_checking", "age"]:
                    z[col] = (z[col] - z[col].mean()) / z[col].std()

                m = smf.ols("anxiety ~ rumination + social_media + phone_checking + age", data=z).fit()
                est = m.params.drop("Intercept")
                ci = m.conf_int().drop("Intercept")

                fig, ax = plt.subplots(figsize=(5, 3))
                ax.axvline(0, color="0.75", linestyle="--", linewidth=1)
                ax.errorbar(est, range(len(est)), xerr=[est - ci[0], ci[1] - est],
                            fmt="o", color="black", capsize=3)
                ax.set_yticks(range(len(est)), est.index)
                ax.set_xlabel("Standardized coefficient (β) with 95% CI")
                plt.tight_layout()
                plt.show()
                """#,
                r: #"""
                library(tidyverse)
                library(broom)

                survey <- read_csv("survey.csv")
                z <- survey |> mutate(across(c(anxiety, rumination, social_media, phone_checking, age),
                                             ~ as.numeric(scale(.x))))

                m <- lm(anxiety ~ rumination + social_media + phone_checking + age, data = z)

                tidy(m, conf.int = TRUE) |>
                  filter(term != "(Intercept)") |>
                  ggplot(aes(estimate, fct_reorder(term, estimate))) +
                  geom_vline(xintercept = 0, linetype = 2, colour = "grey70") +
                  geom_pointrange(aes(xmin = conf.low, xmax = conf.high)) +
                  labs(x = "Standardized coefficient (β) with 95% CI", y = NULL) +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Ordinal outcomes: stacked distribution bars (diverging colors)",
                python: #"""
                judgments = pd.read_csv("judgments.csv")
                judgments["condition"] = judgments["structure"] + " / " + judgments["distance"]
                shares = pd.crosstab(judgments["condition"], judgments["rating"], normalize="index")

                # 1 … 7, with neutral gray at the scale midpoint (4)
                diverging = ["#B2182B", "#EF8A62", "#FDDBC7", "#D9D9D9", "#D1E5F0", "#67A9CF", "#2166AC"]
                ax = shares.plot(kind="barh", stacked=True, color=diverging, width=0.7,
                                 edgecolor="white", linewidth=2, figsize=(6, 3))
                ax.set(xlabel="Share of ratings", ylabel=None)
                ax.legend(title="Rating", bbox_to_anchor=(1, 1), frameon=False)
                plt.tight_layout()
                plt.show()
                """#,
                r: #"""
                judgments <- read_csv("judgments.csv")

                judgments |>
                  mutate(condition = paste(structure, distance, sep = " / "),
                         rating = factor(rating, levels = 1:7)) |>
                  count(condition, rating) |>
                  group_by(condition) |>
                  mutate(share = n / sum(n)) |>
                  ggplot(aes(share, condition, fill = rating)) +
                  geom_col(width = 0.7, colour = "white", linewidth = 0.8) +
                  scale_fill_manual(values = c("#B2182B", "#EF8A62", "#FDDBC7", "#D9D9D9",
                                               "#D1E5F0", "#67A9CF", "#2166AC")) +
                  labs(x = "Share of ratings", y = NULL, fill = "Rating") +
                  theme_classic()
                """#
            )),
            .code(CodeSample(
                caption: "Transition matrix as a heatmap (sequential color)",
                python: #"""
                import seaborn as sns

                commutes = pd.read_csv("commutes.csv").sort_values(["participant", "week"])
                commutes["next_mode"] = commutes.groupby("participant")["mode"].shift(-1)
                matrix = pd.crosstab(commutes["mode"], commutes["next_mode"], normalize="index")

                fig, ax = plt.subplots(figsize=(5, 4))
                sns.heatmap(matrix, cmap="Blues", vmin=0, vmax=1, annot=True, fmt=".2f",
                            linewidths=2, cbar_kws={"label": "P(next week's mode)"}, ax=ax)
                ax.set(xlabel="Mode next week", ylabel="Mode this week")
                plt.show()
                """#,
                r: #"""
                commutes <- read_csv("commutes.csv")

                commutes |>
                  arrange(participant, week) |>
                  group_by(participant) |>
                  mutate(next_mode = lead(mode)) |>
                  ungroup() |>
                  filter(!is.na(next_mode)) |>
                  count(mode, next_mode) |>
                  group_by(mode) |>
                  mutate(p = n / sum(n)) |>
                  ggplot(aes(next_mode, mode, fill = p)) +
                  geom_tile(colour = "white", linewidth = 1) +
                  geom_text(aes(label = sprintf("%.2f", p)), size = 3) +
                  scale_fill_gradient(low = "white", high = "#08519C", limits = c(0, 1)) +
                  labs(x = "Mode next week", y = "Mode this week", fill = "P(next mode)") +
                  theme_minimal()
                """#
            )),
            .keyPoint("Plot estimates, not just p-values", "A coefficient plot shows effect size **and** uncertainty for every predictor at once; readers see immediately which CIs cross zero. Standardize predictors when you want their bars on a comparable scale."),
            .exercise(Exercise(
                title: "Odds ratios on a log scale",
                prompt: "Fit a logistic model of comprehension accuracy (`correct`) on `structure` and `distance` in judgments.csv, then make a coefficient plot of the **odds ratios** with a log-scaled x-axis and a reference line at 1.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    fit = smf.logit("correct ~ C(structure, Treatment('simple')) + C(distance, Treatment('short'))",
                                    data=judgments).fit(disp=False)
                    orr, ci = np.exp(fit.params.drop("Intercept")), np.exp(fit.conf_int().drop("Intercept"))
                    fig, ax = plt.subplots(figsize=(5, 2.5))
                    ax.axvline(1, color="0.75", linestyle="--")
                    ax.errorbar(orr, range(len(orr)), xerr=[orr - ci[0], ci[1] - orr], fmt="o", color="black", capsize=3)
                    ax.set_xscale("log"); ax.set_yticks(range(len(orr)), ["complex", "long"]); ax.set_xlabel("Odds ratio (log scale)")
                    plt.tight_layout(); plt.show()
                    """#,
                    r: #"""
                    fit <- glm(correct ~ relevel(factor(structure), "simple") + relevel(factor(distance), "short"),
                               data = judgments, family = binomial)
                    orr <- exp(coef(fit))[-1]   # odds ratios: complex vs. simple, long vs. short
                    tidy(fit, conf.int = TRUE, exponentiate = TRUE) |>
                      filter(term != "(Intercept)") |>
                      ggplot(aes(estimate, term)) +
                      geom_vline(xintercept = 1, linetype = 2, colour = "grey70") +
                      geom_pointrange(aes(xmin = conf.low, xmax = conf.high)) +
                      scale_x_log10() +
                      labs(x = "Odds ratio (log scale)", y = NULL) +
                      theme_classic()
                    """#
                ),
                answer: "Complex sentences have an OR clearly below 1 (lower odds of a correct answer); distance has an OR near 1. On a log scale, ORs of 2 and 0.5 sit the same distance from 1 — which is why odds ratios belong on log axes.",
                selfCheck: SelfCheck(
                    names: "`orr` — the two odds ratios, complex vs. simple then long vs. short",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("judgments.csv")
                        X = sm.add_constant(np.column_stack([(ref["structure"] == "complex").astype(float),
                                                             (ref["distance"] == "long").astype(float)]))
                        fit = sm.Logit(ref["correct"].to_numpy(), X).fit(disp=False)
                        check("Odds ratios (complex, long)", orr, np.exp(fit.params[1:]), tol=0.001,
                              hint="Exponentiate the coefficients; leave out the intercept.")
                        check("Complex sentences lower the odds of a correct answer", np.asarray(orr)[0] < 1, True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("judgments.csv")
                      ref$complex <- as.integer(ref$structure == "complex")
                      ref$long <- as.integer(ref$distance == "long")
                      fit <- glm(correct ~ complex + long, data = ref, family = binomial)
                      check("Odds ratios (complex, long)", orr, exp(coef(fit))[-1], tol = 0.001,
                            hint = "Exponentiate the coefficients; leave out the intercept.")
                      check("Complex sentences lower the odds of a correct answer", orr[[1]] < 1, TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Which color scheme fits a transition-probability heatmap (values 0 to 1)?",
                options: ["Diverging, centered at 0.5", "Single hue, light to dark", "Rainbow", "Okabe–Ito categories"],
                answer: 1,
                explanation: "Probabilities are magnitudes with no meaningful midpoint, so a sequential single-hue scale fits."
            ),
        ]
    )

    static let publicationFigures = Lesson(
        id: "publication-figures",
        title: "Publication-ready figures",
        summary: "Consistent styling, accessible color, and exporting at the right size.",
        minutes: 9,
        blocks: [
            .text("Journal figures should be readable in grayscale, at the printed size, and by colorblind readers. Define your style **once** and reuse it for every figure in a paper."),
            .code(CodeSample(
                caption: "A reusable style and high-resolution export",
                python: #"""
                import matplotlib.pyplot as plt
                import seaborn as sns

                okabe_ito = ["#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#F0E442"]

                def apa_style():
                    sns.set_theme(style="ticks", context="paper", palette=okabe_ito, font_scale=1.1)
                    plt.rcParams.update({
                        "axes.spines.top": False, "axes.spines.right": False,
                        "font.family": "sans-serif", "figure.dpi": 150,
                    })

                apa_style()
                fig, ax = plt.subplots(figsize=(3.5, 2.8))     # ~one journal column wide (inches)
                # ... draw your plot on ax ...
                fig.savefig("figure1.png", dpi=300, bbox_inches="tight")
                fig.savefig("figure1.pdf", bbox_inches="tight")  # vector format for journals
                """#,
                r: #"""
                library(tidyverse)

                okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#F0E442")

                theme_apa <- function(base_size = 11) {
                  theme_classic(base_size = base_size) +
                    theme(legend.position = "top",
                          legend.title = element_blank(),
                          axis.text = element_text(colour = "black"))
                }

                p <- ggplot(mpg, aes(displ, hwy, colour = drv)) +
                  geom_point() +
                  scale_colour_manual(values = okabe_ito) +
                  theme_apa()

                ggsave("figure1.png", p, width = 3.5, height = 2.8, dpi = 300)
                ggsave("figure1.pdf", p, width = 3.5, height = 2.8)   # vector format for journals
                """#
            )),
            .steps("Checklist before submitting a figure", [
                "Axis labels name the variable **and** its units or scale (e.g. “Anxiety (1–7)”).",
                "Error bars are defined in the caption (SD, SE, or 95% CI).",
                "Color is never the only cue — add direct labels, shapes, or line styles.",
                "Categorical colors come from a colorblind-safe palette (Okabe–Ito, viridis) in a fixed order.",
                "One y-axis per panel — use separate panels instead of dual axes.",
                "Text is legible at the final printed size; export at 300 dpi or as a vector PDF.",
            ]),
            .caution("Common distortions", "Truncated bar axes exaggerate differences; 3-D effects and pie charts make values hard to compare; rainbow color scales create false boundaries. Avoid them."),
            .exercise(Exercise(
                title: "Restyle a figure",
                prompt: "Take the raw-points-plus-CI plot from *Visualizing group comparisons*, apply your APA style, and export it as both PNG (300 dpi) and PDF at 3.5 × 2.8 inches, named `methods.png` and `methods.pdf`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pandas as pd
                    import seaborn as sns
                    import matplotlib.pyplot as plt

                    okabe_ito = ["#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#F0E442"]
                    sns.set_theme(style="ticks", context="paper", palette=okabe_ito, font_scale=1.1)

                    classroom = pd.read_csv("classroom.csv")
                    order = ["lecture", "active", "flipped"]
                    fig, ax = plt.subplots(figsize=(3.5, 2.8))
                    sns.stripplot(data=classroom, x="method", y="posttest", order=order,
                                  color="0.65", alpha=0.6, jitter=0.15, ax=ax)
                    sns.pointplot(data=classroom, x="method", y="posttest", order=order, errorbar=("ci", 95),
                                  color="black", linestyle="none", capsize=0.15, ax=ax)
                    ax.set(xlabel=None, ylabel="Post-test score (0–100)")
                    sns.despine()
                    fig.savefig("methods.png", dpi=300, bbox_inches="tight")
                    fig.savefig("methods.pdf", bbox_inches="tight")
                    """#,
                    r: #"""
                    library(tidyverse)

                    theme_apa <- function(base_size = 11) {
                      theme_classic(base_size = base_size) +
                        theme(legend.position = "top", legend.title = element_blank(),
                              axis.text = element_text(colour = "black"))
                    }

                    classroom <- read_csv("classroom.csv") |>
                      mutate(method = factor(method, levels = c("lecture", "active", "flipped")))
                    summary_df <- classroom |>
                      group_by(method) |>
                      summarise(mean = mean(posttest), ci = qt(0.975, n() - 1) * sd(posttest) / sqrt(n()))

                    p <- ggplot(classroom, aes(method, posttest)) +
                      geom_jitter(width = 0.15, alpha = 0.6, colour = "grey65") +
                      geom_pointrange(data = summary_df, aes(y = mean, ymin = mean - ci, ymax = mean + ci), size = 0.4) +
                      labs(x = NULL, y = "Post-test score (0–100)") +
                      theme_apa()

                    ggsave("methods.png", p, width = 3.5, height = 2.8, dpi = 300)
                    ggsave("methods.pdf", p, width = 3.5, height = 2.8)
                    """#
                ),
                answer: "You should get two files whose fonts stay readable at single-column width. Open the PDF and zoom in — vector graphics stay sharp at any zoom.",
                selfCheck: SelfCheck(
                    names: "two files in your project folder: `methods.png` and `methods.pdf`",
                    python: #"""
                    import struct
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        with open("methods.png", "rb") as f:
                            head = f.read(24)
                        check("methods.png is a PNG", head[:8] == b"\x89PNG\r\n\x1a\n", True)
                        width, height = struct.unpack(">II", head[16:24])   # pixel size, from the PNG header
                        # bbox_inches="tight" trims or pads the edges a little, so allow some slack.
                        check("Width ≈ 3.5 in at 300 dpi", width / 300, 3.5, tol=0.12,
                              hint="figsize=(3.5, 2.8) and savefig(..., dpi=300).")
                        check("Height ≈ 2.8 in at 300 dpi", height / 300, 2.8, tol=0.12)
                        with open("methods.pdf", "rb") as f:
                            check("methods.pdf is a PDF", f.read(5) == b"%PDF-", True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      head <- readBin("methods.png", "raw", 24)
                      check("methods.png is a PNG", identical(head[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))), TRUE)
                      # Pixel size, from the PNG header (two 4-byte big-endian integers)
                      width  <- sum(as.integer(head[17:20]) * 256^(3:0))
                      height <- sum(as.integer(head[21:24]) * 256^(3:0))
                      check("Width ≈ 3.5 in at 300 dpi", width / 300, 3.5, tol = 0.12,
                            hint = "ggsave(..., width = 3.5, height = 2.8, dpi = 300).")
                      check("Height ≈ 2.8 in at 300 dpi", height / 300, 2.8, tol = 0.12)
                      check("methods.pdf is a PDF", identical(readBin("methods.pdf", "raw", 5), charToRaw("%PDF-")), TRUE)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "You need to show two measures with very different scales over time. Best option?",
                options: ["A dual y-axis chart", "Two aligned panels", "A pie chart", "A 3-D plot"],
                answer: 1,
                explanation: "Dual axes invite false comparisons; separate panels with shared x-axes are clearer."
            ),
        ]
    )
}

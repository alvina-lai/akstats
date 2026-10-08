import Foundation

/// Shorthand for a multiple-choice question.
private func q(_ prompt: String, _ options: [String], _ answer: Int, _ explanation: String) -> Question {
    Question(prompt: prompt, options: options, answer: answer, explanation: explanation)
}

/// Shorthand for a multi-part review problem with a worked solution.
private func problem(
    _ title: String,
    _ prompt: String,
    hint: String? = nil,
    python: String? = nil,
    r: String? = nil,
    mplus: String? = nil,
    answer: String
) -> Exercise {
    var solution: CodeSample?
    if python != nil || r != nil || mplus != nil {
        solution = CodeSample(
            caption: "Worked solution",
            python: python ?? "# No Python version for this one — switch to R.",
            r: r ?? "# No R version for this one — switch to Python.",
            mplus: mplus
        )
    }
    return Exercise(title: title, prompt: prompt, hint: hint, solution: solution, answer: answer)
}

/// The content of one end-of-unit review.
private struct ReviewContent {
    let minutes: Int
    let skills: [String]
    let problems: [Exercise]
    let quiz: [Question]
}

extension Curriculum {
    /// Builds the end-of-unit review lesson for a unit, if one is defined.
    static func review(for unit: Unit) -> Lesson? {
        guard let content = reviews[unit.id] else { return nil }
        var blocks: [Block] = [
            .text("This review tests **everything in Unit \(unit.number)** at once. Each problem combines several lessons, the way a real analysis does. Work through it in a fresh script before opening any solutions."),
            .steps("Skills this review covers", content.skills),
            .keyPoint("How to use it", "Try every part of a problem first, then check the hint, and only then the worked solution. Finish with the cumulative quiz — answering every question correctly marks the unit review complete."),
        ]
        blocks += content.problems.map(Block.exercise)
        return Lesson(
            id: "\(unit.id)-review",
            title: "Unit \(unit.number) review",
            summary: "Practice problems that combine every lesson in \(unit.title).",
            minutes: content.minutes,
            blocks: blocks,
            quiz: content.quiz,
            isReview: true
        )
    }

    // The capstone (Unit 13) is already a review, so it doesn't get a separate one.
    private static let reviews: [String: ReviewContent] = [
        "getting-started": gettingStartedReview,
        "foundations": foundationsReview,
        "describing": describingReview,
        "inference": inferenceReview,
        "comparing": comparingReview,
        "relationships": relationshipsReview,
        "visualizing-stats": visualizingReview,
        "advanced": measurementReview,
        "moderation-mediation": moderationMediationReview,
        "categorical-outcomes": categoricalReview,
        "latent-models": latentReview,
        "text-as-data": textReview,
        "real-world": realWorldReview,
    ]

    // MARK: Unit 0

    private static let gettingStartedReview = ReviewContent(
        minutes: 30,
        skills: [
            "Setting up a project folder, environment, and script in VS Code",
            "Translating between Python and R and knowing where their defaults differ",
            "Working with DataFrames: selecting, filtering, creating columns, grouping",
            "Generating the practice data and checking it",
            "Reading a regression summary and reporting it",
        ],
        problems: [
            problem("A project from scratch",
                    "1. Create a new folder `unit0-review`, open it in VS Code, and (for Python) create and select a virtual environment.\n2. Copy in `generate_data.py` / `generate_data.R` and run it.\n3. In a new script, load `survey.csv` and print its dimensions.\n4. Report how many participants live in each region, and the mean and SD of `anxiety` for each.",
                    hint: "If loading fails, check the working directory first.",
                    python: #"""
                    import pandas as pd

                    survey = pd.read_csv("survey.csv")
                    print(survey.shape)
                    print(survey.groupby("region")["anxiety"].agg(["count", "mean", "std"]).round(2))
                    """#,
                    r: #"""
                    library(tidyverse)

                    survey <- read_csv("survey.csv")
                    dim(survey)
                    survey |> group_by(region) |> summarise(n = n(), mean = mean(anxiety), sd = sd(anxiety))
                    """#,
                    answer: "375 rows × 15 columns. About 225 urban and 150 rural respondents, both with mean anxiety near 4 and SD near 1."),
            problem("Defaults detective",
                    "Compute the SD of `rumination` three ways: NumPy's default, NumPy with `ddof=1`, and pandas `.std()` (in R: `sd()` and the population formula). Which ones match, and which should you report?",
                    python: #"""
                    import numpy as np
                    x = survey["rumination"]
                    print(np.std(x), np.std(x, ddof=1), x.std())
                    """#,
                    r: #"""
                    x <- survey$rumination
                    c(sample = sd(x), population = sqrt(mean((x - mean(x))^2)))
                    """#,
                    answer: "`np.std(x, ddof=1)`, pandas `.std()`, and R's `sd()` all agree (the sample SD). NumPy's default is slightly smaller. Report the sample SD."),
            problem("Build, then read, a model",
                    "1. Fit `anxiety ~ rumination + mindfulness + age`.\n2. How many observations were used, and why isn't it 375?\n3. Write one sentence per predictor: coefficient, 95% CI, p.\n4. Report R² and adjusted R² and explain the difference.",
                    python: #"""
                    import statsmodels.formula.api as smf
                    m = smf.ols("anxiety ~ rumination + mindfulness + age", data=survey).fit()
                    print(m.nobs)
                    print(pd.concat([m.params, m.conf_int(), m.pvalues], axis=1).round(3))
                    print(m.rsquared, m.rsquared_adj)
                    """#,
                    r: #"""
                    m <- lm(anxiety ~ rumination + mindfulness + age, data = survey)
                    nobs(m)
                    cbind(coef(m), confint(m), p = summary(m)$coefficients[, 4])
                    c(summary(m)$r.squared, summary(m)$adj.r.squared)
                    """#,
                    answer: "N is a few below 375 because rows with missing mindfulness are dropped. Rumination is clearly positive. Mindfulness and age are near zero once rumination is in the model (mindfulness only affects anxiety *through* rumination). Adjusted R² is slightly lower than R² because it penalizes the extra predictors."),
        ],
        quiz: [
            q("You open a script in VS Code and press ▷, but Python says `No module named pandas`. First thing to check?",
              ["Reinstall VS Code", "Which interpreter is selected (your virtual environment?)", "Rename the file", "Restart your computer"], 1,
              "Packages live in one interpreter; VS Code may be using a different one."),
            q("Python: `x = [10, 20, 30]`; R: `x <- c(10, 20, 30)`. Which expressions return 30 in both languages?",
              ["`x[2]` in Python and `x[3]` in R", "`x[3]` in both", "`x[2]` in both", "`x[-1]` in both"], 0,
              "Python counts from 0, R from 1. (In R, `x[-1]` *drops* the first element.)"),
            q("Which pandas line computes mean anxiety per region?",
              ["df.mean(\"region\")", "df.groupby(\"region\")[\"anxiety\"].mean()", "df[\"anxiety\"].groupby()", "mean(df, region)"], 1,
              "Group, select the column, then summarize."),
            q("In R, `survey |> filter(age > 30) |> nrow()` returns…",
              ["The ages over 30", "The number of rows with age over 30", "An error", "The mean age"], 1,
              "Filter, then count rows."),
            q("A regression row reads: estimate 0.42, SE 0.05, p < .001. The t value is about…",
              ["0.02", "2.1", "8.4", "42"], 2,
              "0.42 / 0.05 = 8.4."),
            q("Why do Python- and R-generated practice datasets give different numbers?",
              ["One has a bug", "Different random-number generators", "R rounds differently", "Python skips missing values"], 1,
              "Same structure, different random draws."),
        ]
    )

    // MARK: Unit 1

    private static let foundationsReview = ReviewContent(
        minutes: 25,
        skills: [
            "Identifying variables, IVs and DVs, and designs",
            "Classifying levels of measurement and declaring them in code",
            "Choosing the right toolkit and formula",
            "Cleaning, excluding, and reshaping data",
        ],
        problems: [
            problem("Plan a study",
                    "A linguist asks whether bilingual adults name pictures more slowly than monolinguals. Each participant names the same 60 pictures; latency is recorded in ms, plus age, years of education, and self-rated proficiency (1–7).\n\n1. Name the IV, the DV, and two covariates.\n2. Give each variable's level of measurement.\n3. Is this an experiment? What can and can't be concluded?\n4. Wide or long format for the analysis, and why?",
                    answer: "1. IV: language group (bilingual/monolingual); DV: naming latency; covariates: age, education. 2. Group: nominal; latency: ratio; age: ratio; education years: ratio; a single proficiency item: ordinal. 3. Not an experiment — language background can't be assigned — so differences may reflect confounds (age, education, vocabulary). 4. Long: one row per participant × picture, so participants and pictures can be modeled (mixed models, Unit 8)."),
            problem("Clean and type the survey",
                    "1. Load `survey.csv`.\n2. Make `region` a category and `education` an ordered category.\n3. Exclude participants with a missing `mindfulness` score and report how many remain.\n4. Reshape the six `mind_` items to long format (participant × item) and report the number of rows.",
                    python: #"""
                    import pandas as pd

                    survey = pd.read_csv("survey.csv")
                    survey["region"] = survey["region"].astype("category")
                    survey["education"] = pd.Categorical(survey["education"], categories=[1, 2, 3, 4, 5], ordered=True)

                    clean = survey.dropna(subset=["mindfulness"])
                    print(len(clean))

                    items_long = clean.melt(id_vars="participant", value_vars=[f"mind_{i}" for i in range(1, 7)],
                                            var_name="item", value_name="response")
                    print(len(items_long))
                    """#,
                    r: #"""
                    library(tidyverse)

                    survey <- read_csv("survey.csv") |>
                      mutate(region = factor(region),
                             education = factor(education, levels = 1:5, ordered = TRUE))

                    clean <- survey |> drop_na(mindfulness)
                    nrow(clean)

                    items_long <- clean |>
                      pivot_longer(mind_1:mind_6, names_to = "item", values_to = "response")
                    nrow(items_long)
                    """#,
                    answer: "Around 370 participants remain. The long table has 6 rows per participant (≈ 2,220 rows), some with missing responses — the score only needed 5 of 6 items."),
        ],
        quiz: [
            q("Randomly assigning participants to read a short or long version of a set of instructions, then measuring comprehension, is…",
              ["Correlational", "Experimental", "Qualitative", "Longitudinal"], 1,
              "The IV is manipulated by random assignment."),
            q("“Native language” is measured at which level?",
              ["Nominal", "Ordinal", "Interval", "Ratio"], 0,
              "Unordered categories."),
            q("Groups are coded 1, 2, 3 in a CSV. Before modeling you should…",
              ["Leave them as numbers", "Convert them to a categorical / factor variable", "Delete them", "Standardize them"], 1,
              "Otherwise they're treated as a continuous quantity."),
            q("In `y ~ a + b`, what does `~` separate?",
              ["Two datasets", "The outcome (left) from the predictors (right)", "Interaction terms", "Comments"], 1,
              "The formula language is shared by Python and R."),
            q("Experiment software exports one row per participant with `rt_cond1` and `rt_cond2` columns. To fit a mixed model you…",
              ["Use it as is", "Reshape to long format", "Average the two columns", "Drop one column"], 1,
              "One row per observation."),
            q("Which exclusion practice is most defensible?",
              ["Deciding after seeing which rule gives p < .05", "Preregistering rules before data collection", "Excluding anyone who disagrees with the hypothesis", "Never reporting exclusions"], 1,
              "Fixed-in-advance rules prevent researcher degrees of freedom."),
        ]
    )

    // MARK: Unit 2

    private static let describingReview = ReviewContent(
        minutes: 25,
        skills: [
            "Choosing and reporting center and spread",
            "Plotting distributions honestly",
            "Standardizing, checking normality, and transforming skewed data",
        ],
        problems: [
            problem("Describe anxiety by region",
                    "1. Make a table of n, M, SD, Mdn, and IQR of `anxiety` for each region.\n2. Plot overlaid histograms and side-by-side boxplots with raw points.\n3. Compute z-scores. How many people have |z| > 2.5?\n4. Write one APA-style descriptive sentence.",
                    python: #"""
                    import pandas as pd
                    import seaborn as sns
                    import matplotlib.pyplot as plt

                    survey = pd.read_csv("survey.csv")
                    print(survey.groupby("region")["anxiety"].agg(
                        n="count", M="mean", SD="std", Mdn="median",
                        IQR=lambda x: x.quantile(.75) - x.quantile(.25)).round(2))

                    fig, axes = plt.subplots(1, 2, figsize=(9, 3.5))
                    sns.histplot(data=survey, x="anxiety", hue="region", element="step", ax=axes[0])
                    sns.boxplot(data=survey, x="region", y="anxiety", showfliers=False, color="white", ax=axes[1])
                    sns.stripplot(data=survey, x="region", y="anxiety", alpha=0.3, color="0.4", ax=axes[1])
                    plt.show()

                    z = (survey["anxiety"] - survey["anxiety"].mean()) / survey["anxiety"].std()
                    print((z.abs() > 2.5).sum())
                    """#,
                    r: #"""
                    library(tidyverse)

                    survey <- read_csv("survey.csv")
                    survey |> group_by(region) |>
                      summarise(n = n(), M = mean(anxiety), SD = sd(anxiety), Mdn = median(anxiety), IQR = IQR(anxiety))

                    ggplot(survey, aes(anxiety, fill = region)) +
                      geom_histogram(alpha = 0.5, position = "identity", bins = 25)
                    ggplot(survey, aes(region, anxiety)) +
                      geom_boxplot(outlier.shape = NA) + geom_jitter(width = 0.15, alpha = 0.3)

                    sum(abs(scale(survey$anxiety)) > 2.5)
                    """#,
                    answer: "Both groups have M ≈ Mdn ≈ 4 and SD ≈ 1 — symmetric, overlapping distributions. Only a handful of people have |z| > 2.5 (about 1% expected). E.g. “Urban (*n* = 225) and rural (*n* = 150) respondents reported similar anxiety (*M* = 4.0, *SD* = 1.0 vs. *M* = 4.0, *SD* = 1.1).”"),
            problem("Skewed reaction times",
                    "1. Simulate 300 log-normal RTs per condition: congruent (meanlog 6.2) and incongruent (meanlog 6.3), sdlog 0.3.\n2. Report the mean and median per condition. Which is larger, and why?\n3. Log-transform and draw Q–Q plots before and after.",
                    python: #"""
                    import numpy as np
                    from scipy import stats

                    rng = np.random.default_rng(4)
                    rt = pd.DataFrame({
                        "condition": np.repeat(["congruent", "incongruent"], 300),
                        "rt": np.concatenate([rng.lognormal(6.2, 0.3, 300), rng.lognormal(6.3, 0.3, 300)]),
                    })
                    print(rt.groupby("condition")["rt"].agg(["mean", "median"]).round(1))

                    fig, axes = plt.subplots(1, 2, figsize=(8, 3.5))
                    stats.probplot(rt["rt"], plot=axes[0])
                    stats.probplot(np.log(rt["rt"]), plot=axes[1])
                    plt.show()
                    """#,
                    r: #"""
                    set.seed(4)
                    rt <- tibble(condition = rep(c("congruent", "incongruent"), each = 300),
                                 rt = c(rlnorm(300, 6.2, 0.3), rlnorm(300, 6.3, 0.3)))
                    rt |> group_by(condition) |> summarise(mean = mean(rt), median = median(rt))

                    par(mfrow = c(1, 2))
                    qqnorm(rt$rt); qqline(rt$rt)
                    qqnorm(log(rt$rt)); qqline(log(rt$rt))
                    """#,
                    answer: "Means exceed medians in both conditions (right skew pulls the mean up): roughly 520 vs. 490 ms and 570 vs. 545 ms. The raw Q–Q plot curves upward at the right; after logging, the points fall on the line."),
        ],
        quiz: [
            q("Income data are right-skewed. Which pair best summarizes them?",
              ["Mean and SD", "Median and IQR", "Mode and range", "Mean and range"], 1,
              "Robust statistics for skewed data."),
            q("Which plot best reveals that a variable has two clusters of values?",
              ["A bar chart of the mean", "A histogram", "A single boxplot", "A table of the mean and SD"], 1,
              "Bimodality is invisible in summaries and often in boxplots."),
            q("z = −1.5 means a value is…",
              ["1.5 points below the mean", "1.5 SDs below the mean", "In the bottom 1.5%", "Missing"], 1,
              "z is in SD units."),
            q("Which normality check is generally most useful?",
              ["Shapiro–Wilk alone", "A Q–Q plot of the model residuals", "Checking the mean", "Counting outliers"], 1,
              "Look at residuals, visually."),
            q("You log-transform RTs. A difference on the log scale is best described as…",
              ["A difference in ms", "A proportional (ratio) difference", "A z-score", "Meaningless"], 1,
              "log(a) − log(b) = log(a / b)."),
            q("You report M = 534 ms. What else must accompany it?",
              ["Only the p-value", "The SD and n", "The median only", "Nothing"], 1,
              "Spread and sample size are always required."),
        ]
    )

    // MARK: Unit 3

    private static let inferenceReview = ReviewContent(
        minutes: 30,
        skills: [
            "Computing and interpreting standard errors and confidence intervals",
            "Running and interpreting a hypothesis test (including permutation tests)",
            "Bootstrap and cluster-bootstrap confidence intervals",
            "Reporting effect sizes and planning sample sizes, by formula and by simulation",
            "Interim analyses without inflating false positives",
        ],
        problems: [
            problem("From sample to claim",
                    "Using `classroom.csv`, compare post-test scores between **active** learning and **lecture**:\n1. 95% CI for each group's mean.\n2. The mean difference and Cohen's d.\n3. A permutation-test p-value (10,000 shuffles).\n4. A bootstrap 95% CI for the difference in means.\n5. One paragraph interpreting everything — what you can and can't conclude.",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    import pingouin as pg

                    classroom = pd.read_csv("classroom.csv")
                    act = classroom.loc[classroom["method"] == "active", "posttest"].to_numpy()
                    lec = classroom.loc[classroom["method"] == "lecture", "posttest"].to_numpy()

                    for name, x in [("active", act), ("lecture", lec)]:
                        print(name, x.mean().round(1), stats.t.interval(0.95, len(x) - 1, loc=x.mean(), scale=stats.sem(x)))
                    diff = act.mean() - lec.mean()
                    print("difference:", diff, "d:", pg.compute_effsize(act, lec))

                    rng = np.random.default_rng(1)
                    pooled = np.concatenate([act, lec])
                    perm = []
                    for _ in range(10_000):
                        rng.shuffle(pooled)
                        perm.append(pooled[:50].mean() - pooled[50:].mean())
                    print("permutation p =", np.mean(np.abs(perm) >= abs(diff)))

                    boots = [rng.choice(act, 50).mean() - rng.choice(lec, 50).mean() for _ in range(10_000)]
                    print("bootstrap CI:", np.percentile(boots, [2.5, 97.5]))
                    """#,
                    r: #"""
                    classroom <- read.csv("classroom.csv")
                    act <- classroom$posttest[classroom$method == "active"]
                    lec <- classroom$posttest[classroom$method == "lecture"]

                    t.test(act)$conf.int; t.test(lec)$conf.int
                    diff <- mean(act) - mean(lec)
                    effectsize::cohens_d(act, lec)

                    set.seed(1)
                    pooled <- c(act, lec)
                    perm <- replicate(10000, { s <- sample(pooled); mean(s[1:50]) - mean(s[51:100]) })
                    mean(abs(perm) >= abs(diff))

                    boots <- replicate(10000, mean(sample(act, replace = TRUE)) - mean(sample(lec, replace = TRUE)))
                    quantile(boots, c(0.025, 0.975))
                    """#,
                    answer: "Active learning averages about 4–5 points higher (d ≈ 0.4–0.5); the permutation p is usually below .05 and the bootstrap CI for the difference usually excludes 0, even though the two groups' individual CIs overlap. Because methods were randomized, a reliable difference is causal — but n = 50 per group makes the estimate imprecise, and adjusting for the pre-test (Unit 4, *ANCOVA*) would add power."),
            problem("Plan the replication",
                    "1. Using your d from the previous problem, compute the n per group needed for 80% and 90% power (two-sided α = .05).\n2. Explain why planning on *half* that effect size may be wiser, and compute that n.",
                    python: #"""
                    from statsmodels.stats.power import TTestIndPower
                    d = 0.4
                    for target, power in [(d, 0.8), (d, 0.9), (d / 2, 0.8)]:
                        print(target, power, np.ceil(TTestIndPower().solve_power(effect_size=target, power=power, alpha=0.05)))
                    """#,
                    r: #"""
                    d <- 0.4
                    sapply(list(c(d, .8), c(d, .9), c(d / 2, .8)),
                           function(x) ceiling(pwr::pwr.t.test(d = x[1], power = x[2])$n))
                    """#,
                    answer: "With d = 0.4: about 100 per group for 80% power and 133 for 90%. Effects estimated from one small study tend to be inflated (the winner's curse), so planning for d = 0.2 is safer — about 394 per group."),
            problem("Clustered data and an interim look",
                    "1. Using `diary.csv`, compute a 95% CI for the share of days with more than 9 work hours — once treating days as independent, once with a cluster bootstrap over people. How different are they?\n2. A colleague plans to test at p < .05 after half the data and again at the end. Simulate the real false-positive rate, then propose a preregistered alternative.",
                    hint: "Both pieces of code are in *Bootstrap & resampling* and *Planning sample size*.",
                    answer: "1. The cluster interval is roughly twice as wide, because people differ a lot in how much they usually work. 2. Testing twice at .05 gives a false-positive rate around 8%. A preregistered O'Brien–Fleming-type design (e.g. thresholds ≈ .005 at the interim and ≈ .048 at the end) keeps the overall rate at 5%."),
        ],
        quiz: [
            q("A 95% CI for a mean difference is [0.10, 0.90]. Which is true?",
              ["p > .05", "p < .05 for a two-sided test of 0", "The effect is exactly 0.50", "There's a 95% chance the true value is in this interval"], 1,
              "The CI excludes 0. (The last option is the classic misinterpretation.)"),
            q("Doubling n from 50 to 100 changes the standard error by a factor of about…",
              ["0.5", "0.71", "1", "2"], 1,
              "1 / √2 ≈ 0.71."),
            q("Which conclusion follows from p = .30?",
              ["The null is true", "The data are compatible with no effect — but a real effect isn't ruled out", "The effect size is .30", "The study was a failure"], 1,
              "Absence of evidence isn't evidence of absence."),
            q("Two studies find d = 0.45. One has n = 20 per group, the other 300. Which estimate is more trustworthy?",
              ["n = 20", "n = 300", "Equal", "Neither"], 1,
              "Larger samples give more precise estimates, and less winner's-curse inflation."),
            q("Which change increases power?",
              ["Lower α from .05 to .01", "Reduce measurement error", "Use fewer participants", "Use a two-tailed test instead of a preregistered one-tailed test"], 1,
              "Less noise means a larger standardized effect."),
            q("The OSC (2015) replication project found replication effect sizes were roughly…",
              ["The same as the originals", "Half the originals", "Twice the originals", "Zero in every case"], 1,
              "Effects shrank by about 50%."),
        ]
    )

    // MARK: Unit 4

    private static let comparingReview = ReviewContent(
        minutes: 35,
        skills: [
            "Choosing between independent, paired, and multi-group comparisons",
            "Running ANOVA with corrected post-hoc tests and effect sizes",
            "Adjusting for a baseline with ANCOVA, and choosing contrasts",
            "Testing association between categorical variables",
            "Using rank-based tests as robustness checks",
        ],
        problems: [
            problem("Science scores by program",
                    "Using OpenIntro's `hsb2`:\n1. Run a one-way ANOVA of `science` by `prog` with η².\n2. Follow up with Tukey comparisons.\n3. Check the result with a Kruskal–Wallis test.\n4. Summarize in two sentences.",
                    python: #"""
                    import pandas as pd
                    import pingouin as pg
                    from scipy import stats

                    # openintro.org rejects Python's default user agent, so send a simple one
                    hsb2 = pd.read_csv("https://www.openintro.org/data/csv/hsb2.csv", storage_options={"User-Agent": "pandas"})
                    print(pg.anova(data=hsb2, dv="science", between="prog", detailed=True))   # includes η²
                    print(pg.pairwise_tukey(data=hsb2, dv="science", between="prog"))
                    print(stats.kruskal(*[g["science"] for _, g in hsb2.groupby("prog")]))
                    """#,
                    r: #"""
                    library(openintro)

                    fit <- aov(science ~ prog, data = hsb2)
                    summary(fit)
                    effectsize::eta_squared(fit)
                    TukeyHSD(fit)
                    kruskal.test(science ~ prog, data = hsb2)
                    """#,
                    answer: "Program matters (p < .001, η² ≈ .1): academic-program students score highest and vocational lowest, with the academic–vocational gap the clearest. Kruskal–Wallis agrees, so the result doesn't hinge on normality."),
            problem("Reading vs. writing",
                    "Each hsb2 student has both a `read` and a `write` score. Do the two differ on average? Choose the right test, report the effect size (d_z = mean difference / SD of differences), and confirm with a rank-based test.",
                    hint: "Same students twice → paired.",
                    python: #"""
                    diff = hsb2["write"] - hsb2["read"]
                    print(stats.ttest_rel(hsb2["write"], hsb2["read"]))
                    print("d_z =", diff.mean() / diff.std())
                    print(stats.wilcoxon(hsb2["write"], hsb2["read"]))
                    """#,
                    r: #"""
                    t.test(hsb2$write, hsb2$read, paired = TRUE)
                    d <- hsb2$write - hsb2$read
                    mean(d) / sd(d)
                    wilcox.test(hsb2$write, hsb2$read, paired = TRUE)
                    """#,
                    answer: "A paired t-test. Writing scores are slightly higher than reading on average (a difference of about half a point), which is small and not significant (d_z ≈ 0.06); the Wilcoxon test agrees."),
            problem("Program and SES",
                    "Is program type associated with SES? Run a chi-square test, inspect the expected counts, and report Cramér's V.",
                    python: #"""
                    import numpy as np
                    table = pd.crosstab(hsb2["prog"], hsb2["ses"])
                    chi2, p, dof, expected = stats.chi2_contingency(table)
                    print(table, "\n", expected.round(1))
                    print(chi2, dof, p, "V =", np.sqrt(chi2 / (table.to_numpy().sum() * (min(table.shape) - 1))))
                    """#,
                    r: #"""
                    tab <- table(hsb2$prog, hsb2$ses)
                    test <- chisq.test(tab)
                    test; test$expected
                    effectsize::cramers_v(tab)
                    """#,
                    answer: "There's a significant association (χ²(4) ≈ 16.6, p ≈ .002, V ≈ .2): high-SES students are over-represented in the academic program. All expected counts exceed 5."),
            problem("A randomized pre/post comparison",
                    "Using `classroom.csv`:\n1. Check whether pre-test scores are balanced across methods.\n2. Fit an ANCOVA (posttest ~ method + pretest + school) with lecture as the reference, and test the homogeneity-of-slopes assumption.\n3. Report adjusted means for each method.\n4. One-tailed test of the preregistered hypothesis that active > lecture.\n5. Refit with sum coding and explain how the coefficients' meaning changes.",
                    hint: "All of the code is in *ANCOVA & contrast coding*.",
                    answer: "Pre-test means are similar across methods. The method × pre-test interaction is non-significant, so a common slope is reasonable. Active learning's adjusted mean is about 4–5 points above lecture (one-tailed p < .01), and flipped is close to lecture. With sum coding, each coefficient becomes a method's deviation from the grand mean instead of its difference from lecture — same model, different comparisons."),
        ],
        quiz: [
            q("Twenty participants rate both a formal and a casual message. Which test?",
              ["Independent t-test", "Paired t-test", "Chi-square", "One-way ANOVA"], 1,
              "Same people in both conditions."),
            q("A one-way ANOVA across 4 groups is significant. What's next?",
              ["Six uncorrected t-tests", "Corrected post-hoc comparisons or planned contrasts", "Stop — you're done", "A chi-square test"], 1,
              "The omnibus F doesn't tell you which groups differ."),
            q("A 2 × 2 table has an expected count of 2 in one cell. Use…",
              ["Chi-square anyway", "Fisher's exact test", "A t-test", "ANOVA"], 1,
              "Expected counts below 5 undermine the χ² approximation."),
            q("Which is the rank-based analogue of an independent-samples t-test?",
              ["Wilcoxon signed-rank", "Mann–Whitney U", "Kruskal–Wallis", "Friedman"], 1,
              "Signed-rank is for paired data."),
            q("A significant interaction in a 2 × 2 ANOVA means…",
              ["Both main effects are significant", "The effect of one factor depends on the other", "The design is unbalanced", "Variances are unequal"], 1,
              "Plot the cell means."),
            q("Why is Welch's t-test a good default?",
              ["It's always more powerful", "It doesn't assume equal variances and loses little when they are equal", "It works with paired data", "It's non-parametric"], 1,
              "A safe default."),
        ]
    )

    // MARK: Unit 5

    private static let relationshipsReview = ReviewContent(
        minutes: 35,
        skills: [
            "Correlations and their limits",
            "Separating between- and within-person relationships in repeated measures",
            "Simple and multiple regression, including categorical predictors",
            "Diagnosing regression assumptions and collinearity",
            "Logistic regression and odds ratios",
        ],
        problems: [
            problem("Build a model step by step",
                    "Using `hsb2`:\n1. Correlation matrix of read, write, math, science.\n2. Regress `science` on `math`.\n3. Add `read` and `gender`. How does the math coefficient change, and why?\n4. Check VIFs and the residual plot.",
                    python: #"""
                    import pandas as pd
                    import matplotlib.pyplot as plt
                    import statsmodels.formula.api as smf
                    from statsmodels.stats.outliers_influence import variance_inflation_factor

                    # openintro.org rejects Python's default user agent, so send a simple one
                    hsb2 = pd.read_csv("https://www.openintro.org/data/csv/hsb2.csv", storage_options={"User-Agent": "pandas"})
                    print(hsb2[["read", "write", "math", "science"]].corr().round(2))

                    m1 = smf.ols("science ~ math", data=hsb2).fit()
                    m2 = smf.ols("science ~ math + read + C(gender)", data=hsb2).fit()
                    print(m1.params["math"], m2.params["math"], m1.rsquared, m2.rsquared)

                    X = m2.model.exog
                    print([round(variance_inflation_factor(X, i), 2) for i in range(1, X.shape[1])])
                    plt.scatter(m2.fittedvalues, m2.resid, alpha=0.5); plt.axhline(0); plt.show()
                    """#,
                    r: #"""
                    library(openintro)

                    round(cor(hsb2[c("read", "write", "math", "science")]), 2)
                    m1 <- lm(science ~ math, data = hsb2)
                    m2 <- lm(science ~ math + read + gender, data = hsb2)
                    c(coef(m1)["math"], coef(m2)["math"])
                    car::vif(m2)
                    plot(m2, which = 1)
                    """#,
                    answer: "All four scores correlate around .55–.65. The math slope shrinks (about 0.67 → 0.4) once reading is added, because math and reading overlap: part of math's association with science was shared with reading. VIFs are low (< 2), and the residuals show no pattern."),
            problem("A binary outcome",
                    "Create `strong_writer` = 1 if `write` ≥ 60. Model it with logistic regression on `read` and `gender`, report odds ratios with 95% CIs, and compare predicted probabilities for a female student with read = 50 vs. read = 65.",
                    python: #"""
                    import numpy as np
                    hsb2["strong_writer"] = (hsb2["write"] >= 60).astype(int)
                    m = smf.logit("strong_writer ~ read + C(gender)", data=hsb2).fit(disp=False)
                    print(np.exp(pd.concat([m.params, m.conf_int()], axis=1)))
                    print(m.predict(pd.DataFrame({"read": [50, 65], "gender": ["female", "female"]})))
                    """#,
                    r: #"""
                    hsb2$strong_writer <- as.integer(hsb2$write >= 60)
                    m <- glm(strong_writer ~ read + gender, data = hsb2, family = binomial)
                    exp(cbind(OR = coef(m), confint(m)))
                    predict(m, data.frame(read = c(50, 65), gender = "female"), type = "response")
                    """#,
                    answer: "Each reading point clearly raises the odds of being a strong writer (OR above 1), and the gender coefficient shows a difference at the same reading score. The predicted probability rises steeply between read = 50 and read = 65 — logistic curves change fastest in the middle of the probability range."),
            problem("Between and within people",
                    "Using `diary.csv`:\n1. Compute the pooled, between-person, and within-person (rmcorr) correlations between work hours and wellbeing.\n2. Fit a multilevel model with both `hours_within` and `hours_between`.\n3. Explain in two sentences why the pooled correlation is misleading.",
                    hint: "All of the code is in *Between- and within-person correlations*.",
                    answer: "Pooled r is small and positive (≈ .2), between-person r is clearly positive (≈ .6), and within-person r is negative (≈ −.35). The model gives a positive `hours_between` and a negative `hours_within` coefficient. Pooling blends two opposite relationships and treats 1,400 days as independent people, so it describes neither."),
        ],
        quiz: [
            q("r = .62 between math and science. The proportion of shared variance is about…",
              [".62", ".38", ".79", ".24"], 1,
              ".62² ≈ .38."),
            q("A predictor's coefficient shrinks a lot when another correlated predictor is added. This shows…",
              ["The model is wrong", "Part of its association was shared with the new predictor", "Multicollinearity is impossible", "R² decreased"], 1,
              "Coefficients are effects holding the others constant."),
            q("A categorical predictor `prog` (3 levels) enters a regression. Its coefficients compare…",
              ["Every pair of levels", "Two levels with the reference level", "Each level with the mean", "Nothing"], 1,
              "k − 1 dummies, each vs. the reference."),
            q("Logistic regression OR = 1.18 per point of reading. Ten more points multiply the odds by about…",
              ["1.18", "2.2", "5.2", "11.8"], 2,
              "1.18¹⁰ ≈ 5.2."),
            q("A U-shaped residual plot suggests…",
              ["Unequal variance", "A non-linear relationship the model misses", "Perfect fit", "Collinearity"], 1,
              "Consider a quadratic term or a transformation."),
            q("Why not use linear regression for a 0/1 outcome?",
              ["It's illegal", "It can predict impossible probabilities, and its errors aren't normal", "It's too slow", "It can't include covariates"], 1,
              "Logistic regression keeps predictions between 0 and 1."),
        ]
    )

    // MARK: Unit 6

    private static let visualizingReview = ReviewContent(
        minutes: 30,
        skills: [
            "Building plots in matplotlib/seaborn and ggplot2",
            "Showing group comparisons with raw data and intervals",
            "Plotting relationships, interactions, and model results",
            "Exporting accessible, publication-ready figures",
        ],
        problems: [
            problem("One figure, three layers",
                    "Using `classroom.csv`, make a single publication-ready figure of post-test scores by teaching method with (1) jittered raw points, (2) means with 95% CIs, and (3) clear axis labels and an Okabe–Ito color per method. Export it at 3.5 × 3 in, 300 dpi.",
                    python: #"""
                    import pandas as pd
                    import seaborn as sns
                    import matplotlib.pyplot as plt

                    classroom = pd.read_csv("classroom.csv")
                    order = ["lecture", "active", "flipped"]
                    colors = {"lecture": "#999999", "active": "#0072B2", "flipped": "#E69F00"}

                    sns.set_theme(style="ticks", context="paper")
                    fig, ax = plt.subplots(figsize=(3.5, 3))
                    sns.stripplot(data=classroom, x="method", y="posttest", order=order, hue="method", palette=colors,
                                  alpha=0.4, jitter=0.15, legend=False, ax=ax)
                    sns.pointplot(data=classroom, x="method", y="posttest", order=order, errorbar=("ci", 95),
                                  color="black", linestyle="none", capsize=0.15, ax=ax)
                    ax.set(xlabel=None, ylabel="Post-test score (0–100)")
                    sns.despine()
                    fig.savefig("posttest_by_method.png", dpi=300, bbox_inches="tight")
                    """#,
                    r: #"""
                    library(tidyverse)

                    classroom <- read_csv("classroom.csv") |>
                      mutate(method = factor(method, levels = c("lecture", "active", "flipped")))
                    summ <- classroom |> group_by(method) |>
                      summarise(m = mean(posttest), ci = qt(.975, n() - 1) * sd(posttest) / sqrt(n()))

                    p <- ggplot(classroom, aes(method, posttest, colour = method)) +
                      geom_jitter(width = 0.15, alpha = 0.4) +
                      geom_pointrange(data = summ, aes(y = m, ymin = m - ci, ymax = m + ci), colour = "black") +
                      scale_colour_manual(values = c("#999999", "#0072B2", "#E69F00"), guide = "none") +
                      labs(x = NULL, y = "Post-test score (0–100)") +
                      theme_classic(base_size = 10)
                    ggsave("posttest_by_method.png", p, width = 3.5, height = 3, dpi = 300)
                    """#,
                    answer: "Three clouds of points, with active learning's mean visibly highest. The x-axis labels name the methods, so no legend is needed, and color is only a secondary cue."),
            problem("Model and correlation figures",
                    "1. Fit `anxiety ~ rumination + social_media + phone_checking + age` on z-scored variables and draw a coefficient plot.\n2. Draw a correlation heatmap of the same five variables with a diverging scale fixed at ±1.\n3. Explain your color choices.",
                    hint: "Reuse the code from *Plotting model results* and *Relationships & interactions*.",
                    answer: "In the coefficient plot, rumination has by far the largest β, with social media small but positive and age near 0. The heatmap uses two hues with a neutral midpoint at 0 because correlations are signed; fixing the limits at ±1 stops weak correlations from looking strong."),
        ],
        quiz: [
            q("You want to show individual pre → post change for 150 people. Best choice?",
              ["A bar chart of the two means", "Thin lines per participant with the mean change highlighted", "A pie chart", "A table"], 1,
              "Spaghetti plots show the consistency of change."),
            q("Which encodes a *sequential* magnitude correctly?",
              ["Rainbow", "One hue, light to dark", "Two hues with a neutral midpoint", "Random categorical colors"], 1,
              "Magnitudes need ordered lightness."),
            q("Your y-axis starts at 3.8 for a bar chart of means of 4.0 and 4.2. What's the problem?",
              ["Nothing", "Truncating a bar axis exaggerates the difference", "Bars must be blue", "Means can't be plotted"], 1,
              "Bar length should start at zero, or use points instead."),
            q("Why use direct labels on lines instead of only a legend?",
              ["They're required", "Readers don't have to match colors back to a legend, which also helps colorblind readers", "Legends are deprecated", "They make files smaller"], 1,
              "Identity shouldn't rely on color alone."),
            q("A simple-slopes plot for a continuous moderator usually shows lines at…",
              ["Every value of W", "−1 SD, the mean, and +1 SD of W", "W = 0 only", "The minimum and maximum of X"], 1,
              "Three representative levels."),
            q("The best format for a journal figure that must stay sharp is…",
              ["72-dpi PNG", "Vector PDF/SVG (or ≥ 300-dpi PNG)", "Screenshot", "GIF"], 1,
              "Vectors scale without blurring."),
        ]
    )

    // MARK: Unit 7

    private static let measurementReview = ReviewContent(
        minutes: 45,
        skills: [
            "Fitting and interpreting linear and logistic mixed-effects models",
            "Scoring multi-item scales and evaluating reliability and factor structure",
            "Quantifying agreement between raters",
            "Reporting analyses transparently",
        ],
        problems: [
            problem("A mixed model, end to end",
                    "Using `diary.csv`:\n1. Person-mean-center `work_hours`.\n2. Fit `wellbeing ~ hours_within + (1 + hours_within | participant)`.\n3. Report the fixed slope (with CI), the random-effect SDs, and the ICC from an intercept-only model.\n4. Write the reporting paragraph: formula, estimation method, convergence, and what you'd do if it didn't converge.",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf

                    diary = pd.read_csv("diary.csv")
                    diary["hours_within"] = diary["work_hours"] - diary.groupby("participant")["work_hours"].transform("mean")
                    m = smf.mixedlm("wellbeing ~ hours_within", data=diary, groups=diary["participant"],
                                    re_formula="~hours_within").fit(reml=True)
                    print(m.summary())
                    print(m.conf_int().loc["hours_within"])

                    null = smf.mixedlm("wellbeing ~ 1", data=diary, groups=diary["participant"]).fit()
                    print("ICC:", null.cov_re.iloc[0, 0] / (null.cov_re.iloc[0, 0] + null.scale))
                    """#,
                    r: #"""
                    library(tidyverse)
                    library(lmerTest)

                    diary <- read_csv("diary.csv") |>
                      group_by(participant) |> mutate(hours_within = work_hours - mean(work_hours)) |> ungroup()

                    m <- lmer(wellbeing ~ hours_within + (1 + hours_within | participant), data = diary)
                    summary(m)
                    confint(m, parm = "hours_within", method = "Wald")

                    vc <- as.data.frame(VarCorr(lmer(wellbeing ~ 1 + (1 | participant), data = diary)))
                    vc$vcov[1] / sum(vc$vcov)   # ICC
                    """#,
                    answer: "The fixed within-person slope is negative (about −0.25 per extra hour), the random-slope SD is modest (≈ 0.1–0.15), and the ICC is about .5. A good report reads: “wellbeing ~ hours_within + (1 + hours_within | participant), fit by REML with Satterthwaite df; the model converged without warnings. Had it not, we would have removed the intercept–slope correlation first, as preregistered.”"),
            problem("Check a scale like a reviewer would",
                    "For the six mindfulness items in `survey.csv`:\n1. Reverse-key items 3 and 5 and compute scores (at least 5 items answered).\n2. Report α and ω.\n3. Fit a one-factor EFA and list the loadings.\n4. Write two sentences for a methods section.",
                    python: #"""
                    import pingouin as pg
                    from factor_analyzer import FactorAnalyzer

                    survey = pd.read_csv("survey.csv")
                    items = [f"mind_{i}" for i in range(1, 7)]
                    keyed = survey[items].copy()
                    keyed[["mind_3", "mind_5"]] = 6 - keyed[["mind_3", "mind_5"]]
                    print(pg.cronbach_alpha(data=keyed))
                    fa = FactorAnalyzer(n_factors=1, rotation=None).fit(keyed.dropna())
                    print(pd.Series(fa.loadings_.ravel(), index=items).round(2))
                    """#,
                    r: #"""
                    library(psych)
                    keyed <- read_csv("survey.csv") |>
                      select(mind_1:mind_6) |>
                      mutate(across(c(mind_3, mind_5), ~ 6 - .x))
                    psych::alpha(keyed)$total$raw_alpha
                    omega(keyed, nfactors = 1)$omega.tot
                    fa(keyed, nfactors = 1)$loadings
                    """#,
                    answer: "α and ω are both around .8, and all six loadings are similar (≈ .6–.7). For example: “The six-item mindfulness scale (items 3 and 5 reverse-keyed) showed good internal consistency (α = .81, ω = .82); a one-factor EFA supported unidimensionality, with loadings from .62 to .71.”"),
            problem("Rate the raters",
                    "Using `essays.csv`:\n1. Report exact and within-one-point agreement, weighted κ, and ordinal Krippendorff's α for raters A and B.\n2. Report the consistency and absolute-agreement ICCs and explain the gap.\n3. Report test–retest reliability for rater A.\n4. Would you let either rater score essays alone?",
                    hint: "All of the code is in *Inter-rater reliability*.",
                    answer: "Exact agreement is modest (around 40%), but nearly all scores fall within one point, and weighted κ and ordinal α are in the .7s. The consistency ICC exceeds the absolute-agreement ICC because rater B scores about 0.3 points higher. Test–retest reliability is around .7–.8. Each rater is consistent, but B's leniency means scores from different raters shouldn't be mixed without recalibration or double scoring."),
            problem("Accuracy with crossed random effects",
                    "Using `judgments.csv`, fit a mixed logistic model of `correct` on `structure` with random intercepts for participants and items. Report the odds ratio for complex vs. simple and the predicted accuracy for each.",
                    r: #"""
                    library(lme4)
                    judgments <- read_csv("judgments.csv") |> mutate(structure = factor(structure, levels = c("simple", "complex")))
                    m <- glmer(correct ~ structure + (1 | participant) + (1 | item), data = judgments, family = binomial)
                    exp(fixef(m)["structurecomplex"])
                    plogis(fixef(m)[1] + c(simple = 0, complex = fixef(m)[2]))
                    """#,
                    answer: "The odds ratio is about 0.6: complex sentences lower the odds of a correct answer. Predicted accuracy is roughly .80 for simple and .72 for complex sentences."),
        ],
        quiz: [
            q("A word-naming study has participants and words fully crossed. The recommended random effects are…",
              ["(1 | participant) only", "(1 | participant) + (1 | word), with random slopes where the design allows", "None", "(1 | word) only"], 1,
              "Both participants and items are sampled."),
            q("lme4 reports a singular fit. A principled response is to…",
              ["Ignore it", "Simplify the random-effects structure in a pre-specified order and report it", "Delete participants", "Switch to a t-test"], 1,
              "Report the simplification."),
            q("α = .97 for a 20-item scale may indicate…",
              ["A perfect scale", "Redundant items", "Low reliability", "Wrong reverse-keying"], 1,
              "Very high α can mean near-duplicate items."),
            q("Rater B scores every essay exactly one point higher than rater A. Which is high?",
              ["Absolute-agreement ICC", "Consistency ICC", "Unweighted κ", "Exact agreement"], 1,
              "Consistency ignores constant offsets."),
            q("Two items load −0.6 on a factor where every other item loads +0.7. Most likely…",
              ["They measure something else", "They're reverse-worded and weren't recoded", "The sample is too small", "The factor is wrong"], 1,
              "Recode and rerun."),
            q("Which is NOT required for transparent mixed-model reporting?",
              ["The full model formula", "Random-effects variances", "How convergence problems were handled", "The color of your figures"], 3,
              "Meteyard & Davies (2020) emphasize the first three."),
        ]
    )

    // MARK: Unit 8

    private static let moderationMediationReview = ReviewContent(
        minutes: 45,
        skills: [
            "Testing and probing moderation with continuous variables",
            "Bootstrapped mediation",
            "Moderated mediation: conditional indirect effects and the index",
        ],
        problems: [
            problem("The full pipeline",
                    "Answer this research question with `survey.csv`: *Does social media use relate to anxiety through rumination, and is the first link weaker for more mindful people?*\n1. Test moderation of social media → rumination by mindfulness, with simple slopes.\n2. Estimate the indirect effect with a 5,000-resample bootstrap CI.\n3. Estimate the index of moderated mediation and the conditional indirect effects at −1 SD, mean, and +1 SD.\n4. Write a results paragraph.",
                    hint: "Each step is a block of code from one lesson in this unit; put them in one script, in order.",
                    r: #"""
                    library(tidyverse)
                    library(lavaan)
                    library(interactions)

                    survey <- read_csv("survey.csv") |>
                      drop_na(mindfulness) |>
                      mutate(rural = as.integer(region == "rural"),
                             sm_c = social_media - mean(social_media),
                             mind_c = mindfulness - mean(mindfulness),
                             sm_x_mind = sm_c * mind_c)

                    mod <- lm(rumination ~ sm_c * mind_c + age + education + rural, data = survey)
                    sim_slopes(mod, pred = sm_c, modx = mind_c)           # step 1

                    s <- sd(survey$mind_c)
                    model <- sprintf('
                      rumination ~ a1 * sm_c + a2 * mind_c + a3 * sm_x_mind + age + education + rural
                      anxiety    ~ b * rumination + c_prime * sm_c + age + education + rural
                      indirect_mean := a1 * b
                      index_mod_med := a3 * b
                      indirect_low  := (a1 - %1$.4f * a3) * b
                      indirect_high := (a1 + %1$.4f * a3) * b
                    ', s)
                    fit <- sem(model, data = survey, se = "bootstrap", bootstrap = 5000)
                    parameterEstimates(fit, boot.ci.type = "perc") |> filter(op == ":=")   # steps 2–3
                    """#,
                    answer: "(1) The interaction is negative and significant; simple slopes are positive at all three levels but smallest at +1 SD. (2) The indirect effect at average mindfulness is positive, with a CI excluding 0. (3) The index of moderated mediation is negative, with a CI excluding 0 — the indirect effect weakens as mindfulness rises. (4) Report all of these with CIs and note that cross-sectional data can't establish causal order."),
            problem("Where is the moderation?",
                    "Test whether mindfulness moderates the **second** stage (rumination → anxiety) instead of the first. Compare the two indices of moderated mediation and explain what each would mean.",
                    hint: "Adapt the exercise *Move the moderator* from *Moderated mediation*.",
                    answer: "The second-stage index is near zero with a CI spanning 0, while the first-stage index is clearly negative. Substantively: mindfulness changes how strongly social media use goes with rumination, not how strongly rumination goes with anxiety."),
        ],
        quiz: [
            q("The X × W coefficient is significant. To describe it you should…",
              ["Report only the coefficient", "Probe it with simple slopes (and/or Johnson–Neyman) and a plot", "Split W at the median", "Drop the main effects"], 1,
              "Show where and how the slope changes."),
            q("The indirect effect's 95% bootstrap CI is [−0.01, 0.20]. You conclude…",
              ["Significant mediation", "No statistically supported indirect effect at α = .05", "Full mediation", "The bootstrap failed"], 1,
              "The CI includes 0."),
            q("A mediation model is estimated on cross-sectional survey data. The strongest defensible claim is…",
              ["X causes Y through M", "The data are consistent with an indirect association through M", "M causes X", "There's no relationship"], 1,
              "Design limits causal claims."),
            q("In PROCESS terms, first-stage moderated mediation is…",
              ["Model 1", "Model 4", "Model 7", "Model 14"], 2,
              "Model 7 moderates the a path."),
            q("Mean-centering X and W before forming X × W changes…",
              ["The interaction's p-value", "The meaning of the lower-order coefficients", "R²", "Nothing"], 1,
              "They become effects at the average of the other variable."),
            q("Conditional indirect effects are significant at low W but not at high W. Is that moderated mediation?",
              ["Yes, always", "Only if the index of moderated mediation's CI excludes 0", "No, never", "Only with p < .01"], 1,
              "A difference in significance isn't a significant difference."),
        ]
    )

    // MARK: Unit 9

    private static let categoricalReview = ReviewContent(
        minutes: 40,
        skills: [
            "Ordinal mixed models for rating scales",
            "Effect coding in factorial designs",
            "Transition matrices and multinomial mixed models for repeated choices",
        ],
        problems: [
            problem("An acceptability experiment",
                    "Using `judgments.csv`:\n1. Plot the four condition means.\n2. Fit an ordinal mixed model of `rating` on effect-coded `complex * long` with random intercepts for participants and items.\n3. Report odds ratios for both main effects and the interaction.\n4. Report predicted category probabilities for simple-short vs. complex-long sentences.\n5. Two sentences summarizing the result.",
                    r: #"""
                    library(tidyverse)
                    library(ordinal)

                    judgments <- read_csv("judgments.csv") |>
                      mutate(rating = factor(rating, levels = 1:7, ordered = TRUE),
                             participant = factor(participant), item = factor(item),
                             complex = ifelse(structure == "complex", 0.5, -0.5),
                             long = ifelse(distance == "long", 0.5, -0.5))

                    m <- clmm(rating ~ complex * long + (1 | participant) + (1 | item), data = judgments)
                    exp(coef(m)[c("complex", "long", "complex:long")])

                    predict(clm(rating ~ complex * long, data = judgments),
                            newdata = data.frame(complex = c(-0.5, 0.5), long = c(-0.5, 0.5)), type = "prob")
                    """#,
                    answer: "Both main effects have ORs well below 1, and the interaction OR is also below 1: long distance hurts complex sentences more than simple ones. Simple-short sentences mostly get 4–7; complex-long sentences mostly get 1–3."),
            problem("Weekly commute choices",
                    "Using `commutes.csv`:\n1. Tabulate mode shares in week 1 vs. week 10.\n2. Build the transition matrix and report how sticky each mode is.\n3. Fit a multinomial mixed model of mode on week and distance with a random intercept per person.\n4. Summarize what changes over time and what distance does.",
                    hint: "All of the code is in *Multinomial outcomes & transitions*.",
                    answer: "Biking roughly doubles (≈ 10% → 25%); bus and car shrink. Each mode is repeated about 65–80% of the time, with bus the stickiest. In the model, week raises the log-odds of biking relative to car, and distance strongly lowers the odds of walking (OR ≈ 0.55 per km) and somewhat lowers biking."),
        ],
        quiz: [
            q("Ratings bunch at the ends of a 1–7 scale. Which model is most defensible?",
              ["Linear regression on the numbers", "A cumulative link (ordinal) model", "Chi-square", "Pearson correlation"], 1,
              "Ordinal models don't assume equal spacing or normal errors."),
            q("Why include `(1 | item)` in a sentence-rating experiment?",
              ["To speed up fitting", "Sentences differ in how acceptable they sound, and you want to generalize beyond these sentences", "It's required for effect coding", "To remove outliers"], 1,
              "Otherwise significance is inflated."),
            q("With ±0.5 effect coding, the interaction coefficient equals…",
              ["The main effect of A", "The difference between the A effect at the two levels of B", "The intercept", "Zero always"], 1,
              "A difference of differences."),
            q("Which model fits 4 unordered transport modes chosen weekly by the same people?",
              ["Ordinal mixed model", "Multinomial mixed model", "Linear regression", "Paired t-test"], 1,
              "Unordered categories with repeated measures."),
            q("A transition matrix cell (bike → bike) = .70 means…",
              ["70% of all commutes are by bike", "70% of people who biked one week biked again the next", "70% of people bike", "p = .70"], 1,
              "Rows are conditional distributions."),
            q("Why do multinomial models need a reference category?",
              ["They don't", "Each other category is modeled as log-odds relative to it", "To drop rare categories", "For random effects"], 1,
              "Coefficients are comparisons with the reference."),
        ]
    )

    // MARK: Unit 10

    private static let latentReview = ReviewContent(
        minutes: 50,
        skills: [
            "Choosing between LCA and LPA",
            "Class enumeration with BIC, entropy, LMR, and BLRT",
            "Running mixture models in Mplus and relating classes to other variables",
        ],
        problems: [
            problem("LCA or LPA?",
                    "1. For each dataset — `habits.csv` (six yes/no strategies) and `profiles.csv` (four continuous scores) — say whether LCA or LPA applies, and why.\n2. Run a 1–5 class/profile enumeration for each and build a table of K, BIC, entropy, and smallest class.\n3. Choose K with the rule “lowest BIC unless a class is < 5%”.\n4. Check recovery against `true_class` / `true_profile`.",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from stepmix.stepmix import StepMix
                    from sklearn.mixture import GaussianMixture

                    def entropy(post):
                        return 1 - (-(post * np.log(post + 1e-12)).sum()) / (len(post) * np.log(max(post.shape[1], 2)))

                    habits = pd.read_csv("habits.csv")
                    Xc = habits[["reread", "notes", "selftest", "spaced", "explain", "peers"]]
                    profiles = pd.read_csv("profiles.csv")
                    Xp = profiles[["wellbeing", "stress", "support", "sleep"]].to_numpy()

                    rows = []
                    for k in range(1, 6):
                        lca = StepMix(n_components=k, measurement="binary", n_init=10, random_state=1, verbose=0).fit(Xc)
                        lpa = GaussianMixture(n_components=k, covariance_type="diag", n_init=10, random_state=1).fit(Xp)
                        pc, pp = lca.predict_proba(Xc), lpa.predict_proba(Xp)
                        rows.append({"K": k, "LCA_BIC": lca.bic(Xc), "LCA_entropy": entropy(pc), "LCA_min": pc.mean(0).min(),
                                     "LPA_BIC": lpa.bic(Xp), "LPA_entropy": entropy(pp), "LPA_min": pp.mean(0).min()})
                    print(pd.DataFrame(rows).round(3))
                    """#,
                    r: #"""
                    library(tidyverse)
                    library(poLCA)      # loads MASS, whose select() masks dplyr's — hence dplyr::select() below
                    library(tidyLPA)

                    habits <- read_csv("habits.csv")
                    lca_data <- habits |> mutate(across(reread:peers, ~ .x + 1))
                    f <- cbind(reread, notes, selftest, spaced, explain, peers) ~ 1
                    set.seed(1)
                    lca <- lapply(1:5, function(k) poLCA(f, lca_data, nclass = k, nrep = 10, verbose = FALSE))
                    tibble(K = 1:5, BIC = sapply(lca, `[[`, "bic"), smallest = sapply(lca, function(m) min(m$P)))
                    table(lca[[3]]$predclass, habits$true_class)

                    profiles <- read_csv("profiles.csv")
                    lpa <- profiles |> dplyr::select(wellbeing, stress, support, sleep) |>
                      estimate_profiles(1:5, variances = "equal", covariances = "zero")
                    get_fit(lpa) |> dplyr::select(Classes, BIC, Entropy, prob_min, n_min)
                    """#,
                    answer: "1. habits → **LCA** (categorical indicators); profiles → **LPA** (continuous indicators). 2–3. BIC is lowest at **K = 3** for both, with no class under 5%. Entropy is high for the profiles and somewhat lower for the habits, whose types overlap more. 4. Both recover the true groups well, up to label order."),
            problem("An Mplus enumeration",
                    "1. Write an Mplus input for a 2-class LCA of `habits.dat` with 1,000 random starts, TECH11, TECH14, and saved posterior probabilities.\n2. Given the table below, choose K and justify it.\n\n• K = 2: BIC 3650, aBIC 3615, entropy .74, LMR p < .001, BLRT p < .001, smallest 41%\n• K = 3: BIC 3598, aBIC 3544, entropy .78, LMR p = .004, BLRT p < .001, smallest 21%\n• K = 4: BIC 3622, aBIC 3549, entropy .71, LMR p = .38, BLRT p = .09, smallest 6%",
                    mplus: #"""
                    TITLE:    LCA of six study strategies, 2 classes;
                    DATA:     FILE = habits.dat;
                    VARIABLE: NAMES = id reread notes selftest spaced explain peers gpa tclass;
                              USEVARIABLES = reread notes selftest spaced explain peers;
                              CATEGORICAL = reread notes selftest spaced explain peers;
                              CLASSES = c(2);
                              IDVARIABLE = id;
                    ANALYSIS: TYPE = MIXTURE;
                              STARTS = 1000 250;
                              LRTSTARTS = 0 0 100 20;
                    OUTPUT:   TECH11 TECH14;
                    SAVEDATA: FILE = lca2_post.dat;
                              SAVE = CPROBABILITIES;
                    """#,
                    answer: "**K = 3.** It has the lowest BIC and aBIC, and both LMR and BLRT favor 3 over 2. For 4 vs. 3, both tests are non-significant and BIC rises, so a 4th class (6%) isn't justified. Also confirm that the best loglikelihood was replicated in every run."),
            problem("Classes and an outcome",
                    "Write the Mplus line that compares mean `gpa` across the three classes while accounting for classification error, and say what result you'd expect from the generated data.",
                    mplus: #"""
                    VARIABLE: ...
                              AUXILIARY = gpa (BCH);
                    """#,
                    answer: "`AUXILIARY = gpa (BCH);` — the output gives class-specific GPA means and overall and pairwise χ² tests. Expect active practice highest (≈ 3.4), social learning in between (≈ 3.1), and passive review lowest (≈ 2.8)."),
        ],
        quiz: [
            q("Your indicators are three binary items and two continuous scores. You want subgroups based on all five. Which approach?",
              ["LCA only", "LPA only", "A mixture model with both indicator types (e.g. in Mplus)", "k-means on the binary items"], 2,
              "Mplus mixture models allow mixed indicator types — list only the binary items under CATEGORICAL."),
            q("BLRT for K = 4 vs. 3 gives p = .02, but BIC is higher for K = 4 and its smallest class is 2%. A sensible choice is…",
              ["4 — BLRT is significant", "3 — the 4th class is tiny and BIC disagrees; follow the preregistered rule", "1", "Run until p > .05"], 1,
              "Weigh multiple criteria plus interpretability."),
            q("Which Mplus option compares a continuous distal outcome across classes while accounting for classification error?",
              ["R3STEP", "BCH", "CATEGORICAL", "TECH11"], 1,
              "R3STEP is for predictors of membership."),
            q("Entropy of .55 means…",
              ["Classes are very well separated", "Many people are ambiguous between classes", "The model didn't converge", "There are 55 classes"], 1,
              "Low entropy = uncertain classification."),
            q("Mplus warns that the best loglikelihood was not replicated. You should…",
              ["Report it anyway", "Increase STARTS and rerun", "Drop a class", "Switch to LPA"], 1,
              "More random starts help find the global maximum."),
            q("Why must classes be identified by their profiles, not their numbers?",
              ["Numbers are always wrong", "Class labels are arbitrary and can switch between runs", "Mplus renames them", "Profiles are optional"], 1,
              "Label switching."),
        ]
    )

    // MARK: Unit 11

    private static let textReview = ReviewContent(
        minutes: 30,
        skills: [
            "Sentence embeddings and cosine similarity",
            "Choosing clusters with silhouettes, HDBSCAN, and medoids",
            "Finding distinctive words with weighted log-odds",
        ],
        problems: [
            problem("Text types, two ways",
                    "With the 12 example sentences from *Text embeddings & clustering*:\n1. Cluster the embeddings with k chosen by silhouette and report each cluster's medoid.\n2. Treat the clusters as groups and run a weighted log-odds keyness analysis on their words.\n3. Do the distinctive words match how you'd name each cluster?",
                    hint: "Use the cluster labels as the `group` variable in the keyness code.",
                    answer: "k = 3 has the highest silhouette, and the medoids are one cooking, one weather, and one exercise sentence. The keyness lists line up with those topics (e.g. “onions”, “batter” vs. “rain”, “snow” vs. “running”, “muscles”). Agreement between two independent methods makes the groupings more credible."),
            problem("Compare two representations",
                    "Cluster the same sentences using TF-IDF vectors instead of embeddings, and compute the adjusted Rand index between the two clusterings. Which representation would you trust for grouping by meaning?",
                    answer: "Agreement is usually only moderate. TF-IDF groups sentences that share words; embeddings group sentences that share meaning, so embeddings are the better choice when wording varies."),
        ],
        quiz: [
            q("Two normalized embeddings have cosine similarity 0.92. This suggests…",
              ["The texts share no words", "The texts are very similar in meaning", "The texts are identical", "One text is missing"], 1,
              "Cosine similarity near 1 means the vectors point the same way."),
            q("HDBSCAN labels 20% of texts as noise. That means…",
              ["The algorithm failed", "Those texts don't sit in any dense group", "They're duplicates", "k was too small"], 1,
              "Noise points aren't forced into clusters."),
            q("Why use a medoid rather than a centroid as a cluster's prototype?",
              ["It's always more central", "It's an actual text you can read", "It's faster", "It removes noise"], 1,
              "Centroids are averages that don't correspond to any real text."),
            q("Keyness analysis is best treated as…",
              ["Confirmatory evidence", "Exploratory — generating candidate words to test later", "A reliability measure", "A clustering method"], 1,
              "Test the candidates in a confirmatory design."),
        ]
    )

    // MARK: Unit 12

    private static let realWorldReview = ReviewContent(
        minutes: 40,
        skills: [
            "Diagnosing missing-data mechanisms and using multiple imputation",
            "Weighted estimates and design-based standard errors for complex surveys",
            "Choosing adjustment variables from a DAG; regression adjustment and propensity-score weighting",
            "Random-effects meta-analysis, heterogeneity, and publication bias",
            "Priors, posteriors, credible intervals, and Bayes factors",
        ],
        problems: [
            problem("Imputation and a regression slope",
                    "Using `missing.csv`:\n1. How much is missing, and does missingness depend on stress?\n2. Estimate the slope of wellbeing on stress using complete cases only.\n3. Estimate it again with 20 multiple imputations.\n4. Compare both with the slope on `wellbeing_true`. Which is closer?",
                    hint: "Under MAR given stress, a regression *on* stress is unbiased with complete cases — but the mean isn't. Check whether that's what you find.",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    import statsmodels.formula.api as smf
                    from statsmodels.imputation import mice

                    missing = pd.read_csv("missing.csv")
                    print(missing["wellbeing"].isna().mean())
                    print(smf.logit("I(wellbeing.isna().astype(int)) ~ stress", data=missing).fit(disp=False).params)

                    cc = smf.ols("wellbeing ~ stress", data=missing).fit().params["stress"]
                    np.random.seed(1)
                    imp = mice.MICEData(missing[["age", "stress", "sleep", "wellbeing"]])
                    mi = mice.MICE("wellbeing ~ stress", sm.OLS, imp).fit(n_burnin=10, n_imputations=20).params[1]
                    truth = smf.ols("wellbeing_true ~ stress", data=missing).fit().params["stress"]
                    print(round(cc, 3), round(mi, 3), round(truth, 3))
                    """#,
                    r: #"""
                    library(mice)
                    missing <- read.csv("missing.csv")
                    mean(is.na(missing$wellbeing))
                    coef(glm(is.na(wellbeing) ~ stress, data = missing, family = binomial))

                    cc <- coef(lm(wellbeing ~ stress, data = missing))[["stress"]]
                    imp <- mice(missing[c("age", "stress", "sleep", "wellbeing")], m = 20, seed = 1, printFlag = FALSE)
                    mi <- summary(pool(with(imp, lm(wellbeing ~ stress))))$estimate[2]
                    truth <- coef(lm(wellbeing_true ~ stress, data = missing))[["stress"]]
                    round(c(cc, mi, truth), 3)
                    """#,
                    answer: "About a quarter of values are missing, and the odds of skipping rise sharply with stress (MAR). All three slopes are close: when missingness depends only on a *predictor*, complete-case regression is still unbiased for that relationship. The mean, by contrast, was badly biased — which estimates are affected depends on the analysis, not just the missingness."),
            problem("Did tutoring work?",
                    "Using `tutoring.csv`:\n1. Draw the DAG and list the adjustment set.\n2. Check propensity-score overlap between tutored and untutored students.\n3. Estimate the effect by regression adjustment and by IPW, with a bootstrap CI for the IPW estimate.\n4. Explain why adding `recommended` to the model would be a mistake.",
                    hint: "All the pieces are in *Causal inference with observational data*. For the bootstrap, refit the propensity model inside each resample.",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf

                    students = pd.read_csv("tutoring.csv")

                    def ipw(d):
                        ps = smf.logit("tutoring ~ prior_gpa + motivation + parent_degree", data=d).fit(disp=False).predict(d)
                        w = np.where(d["tutoring"] == 1, 1 / ps, 1 / (1 - ps))
                        t = d["tutoring"] == 1
                        return np.average(d["exam"][t], weights=w[t]) - np.average(d["exam"][~t], weights=w[~t])

                    rng = np.random.default_rng(1)
                    boots = [ipw(students.sample(len(students), replace=True, random_state=rng)) for _ in range(500)]
                    print(round(ipw(students), 2), np.percentile(boots, [2.5, 97.5]).round(2))
                    """#,
                    r: #"""
                    students <- read.csv("tutoring.csv")
                    ipw <- function(d) {
                      ps <- fitted(glm(tutoring ~ prior_gpa + motivation + parent_degree, data = d, family = binomial))
                      w <- ifelse(d$tutoring == 1, 1 / ps, 1 / (1 - ps))
                      t <- d$tutoring == 1
                      weighted.mean(d$exam[t], w[t]) - weighted.mean(d$exam[!t], w[!t])
                    }
                    set.seed(1)
                    boots <- replicate(500, ipw(students[sample(nrow(students), replace = TRUE), ]))
                    c(estimate = ipw(students), quantile(boots, c(0.025, 0.975)))
                    """#,
                    answer: "Adjust for prior GPA, motivation, and parental degree. Propensity scores overlap well (both groups span most of the range). Regression adjustment and IPW both land near the true +5 (within about a point, depending on the generated sample), with bootstrap CIs roughly ±1–1.5 points wide that include 5 — far from the naive gap of about 10. `recommended` is caused by both tutoring and exam scores — a collider — so conditioning on it distorts the estimate."),
            problem("Pool, then explain the differences",
                    "The first six studies in the *Meta-analysis* lesson used student samples and the last six community samples.\n1. Fit a random-effects model.\n2. Add sample type as a moderator (meta-regression). Does it explain the heterogeneity?\n3. Make a funnel plot. Could small-study effects explain the pattern instead?",
                    hint: "In R: `rma(yi = d, vi = v, mods = ~ sample, data = studies)`. In Python, a weighted least-squares regression with weights 1 / (v + τ²) approximates it.",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from statsmodels.stats.meta_analysis import combine_effects

                    d = np.array([0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19])
                    n1 = np.array([40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90])
                    n2 = np.array([40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92])
                    studies = pd.DataFrame({"d": d, "v": (n1 + n2) / (n1 * n2) + d ** 2 / (2 * (n1 + n2)),
                                            "sample": ["student"] * 6 + ["community"] * 6})
                    tau2 = combine_effects(studies["d"], studies["v"], method_re="dl").tau2
                    meta_reg = smf.wls("d ~ sample", data=studies, weights=1 / (studies["v"] + tau2)).fit()
                    print(meta_reg.params, meta_reg.pvalues, sep="\n")
                    """#,
                    r: #"""
                    library(metafor)
                    d  <- c(0.42, 0.15, 0.75, 0.05, 0.33, 0.55, 0.12, 0.85, 0.26, -0.10, 0.45, 0.19)
                    n1 <- c(40, 120, 25, 200, 60, 30, 150, 20, 80, 180, 45, 90)
                    n2 <- c(40, 118, 24, 205, 58, 32, 149, 22, 79, 176, 44, 92)
                    studies <- data.frame(d, v = (n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2)),
                                          sample = rep(c("student", "community"), each = 6))
                    rma(yi = d, vi = v, data = studies, method = "DL")
                    rma(yi = d, vi = v, mods = ~ sample, data = studies, method = "DL")   # meta-regression
                    funnel(rma(yi = d, vi = v, data = studies, method = "DL"))
                    """#,
                    answer: "Sample type explains little: student and community studies have similar average effects, and τ² barely shrinks. The funnel plot shows the clearer pattern — small studies report the biggest effects — so small-study effects (possibly publication bias) are the more plausible explanation of the heterogeneity. With only 12 studies, any moderator test has low power."),
        ],
        quiz: [
            q("Participants who drop out of a longitudinal study had higher baseline depression, which was measured. The dropout is…",
              ["MCAR", "MAR", "MNAR", "Irrelevant"], 1,
              "It depends on an observed variable, so MAR — use it in the imputation or likelihood."),
            q("Pooling estimates from 20 imputed datasets uses…",
              ["The best of the 20", "Rubin's rules", "The median imputation", "A t-test"], 1,
              "Average the estimates; combine within- and between-imputation variance."),
            q("A survey's design effect is 1.8. Compared with a simple random sample of the same size, its standard errors are…",
              ["Smaller", "About 1.34 times larger", "1.8 times larger", "Unchanged"], 1,
              "Variance is 1.8 times larger, so SEs are √1.8 ≈ 1.34 times larger."),
            q("Which variable should NOT be adjusted for when estimating the effect of an exercise program on fitness?",
              ["Baseline fitness (a confounder)", "Age (a confounder)", "Weekly hours of exercise caused by the program (a mediator)", "Prior health (a confounder)"], 2,
              "Adjusting for a mediator removes part of the effect you want to estimate."),
            q("A random-effects meta-analysis has a 95% CI of [0.10, 0.37] and a 95% prediction interval of [−0.11, 0.58]. Which is right?",
              ["The average effect is clearly positive, but some settings may show no effect", "The effect is not significant", "There's no heterogeneity", "The two intervals contradict each other"], 0,
              "The CI is about the average effect; the prediction interval is about a new study's true effect."),
            q("With a lot of data and a reasonable prior, a Bayesian posterior mean and a frequentist estimate will usually…",
              ["Be very different", "Be close", "Have opposite signs", "Require a Bayes factor"], 1,
              "The likelihood dominates the prior when data are plentiful."),
        ]
    )
}

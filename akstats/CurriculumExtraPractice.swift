import Foundation

/// Shorthand for a practice exercise. Supply `python`/`r` (and optionally `mplus`) for a worked solution.
private func practice(
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
            caption: "Solution",
            python: python ?? "# No Python version for this one — switch to R.",
            r: r ?? "# No R version for this one — switch to Python.",
            mplus: mplus
        )
    }
    return Exercise(title: title, prompt: prompt, hint: hint, solution: solution, answer: answer)
}

extension Lesson {
    /// Extra practice exercises shown in the lesson's "More practice" section.
    var morePractice: [Exercise] {
        Curriculum.extraPractice[id] ?? []
    }
}

/// Additional practice exercises, keyed by lesson ID.
extension Curriculum {
    static let extraPractice: [String: [Exercise]] = extraPracticeBasics
        .merging(extraPracticeCore) { $0 + $1 }
        .merging(extraPracticeResearch) { $0 + $1 }
        .merging(extraPracticeStructure) { $0 + $1 }

    // MARK: Units 0–2

    private static let extraPracticeBasics: [String: [Exercise]] = [
        "vs-code": [
            practice("Check your setup",
                     "Write a script that prints your language version and the versions of your main packages. Run it as a whole file.",
                     python: #"""
                     import sys
                     import numpy, pandas, statsmodels
                     print(sys.version)
                     print("pandas", pandas.__version__, "| numpy", numpy.__version__, "| statsmodels", statsmodels.__version__)
                     """#,
                     r: #"""
                     R.version.string
                     packageVersion("tidyverse")
                     packageVersion("lme4")
                     """#,
                     answer: "Versions print without errors. A `ModuleNotFoundError` (Python) or “there is no package called…” (R) means the package isn't installed in the interpreter VS Code is using — check *Select Interpreter* or rerun the install step."),
            practice("Where am I?",
                     "Print the working directory and list the files in it. Is your data file there?",
                     python: #"""
                     import os
                     print(os.getcwd())
                     print(os.listdir())
                     """#,
                     r: #"""
                     getwd()
                     list.files()
                     """#,
                     answer: "You should see your project folder and its files. If not, use File → Open Folder in VS Code, or change directory with `os.chdir()` / `setwd()`."),
        ],
        "python-vs-r": [
            practice("Translate a line",
                     "Translate this Python into R: `df[df[\"age\"] > 30][\"anxiety\"].mean()`",
                     python: #"""
                     df[df["age"] > 30]["anxiety"].mean()
                     """#,
                     r: #"""
                     df |> filter(age > 30) |> summarise(mean_anxiety = mean(anxiety))
                     # or, in base R:
                     mean(df$anxiety[df$age > 30])
                     """#,
                     answer: "Both languages return the same number. Filtering rows, selecting a column, and summarizing is the same three-step idea in each."),
            practice("Spot the default",
                     "Compute the standard deviation of 2, 4, 4, 4, 5, 5, 7, 9 with NumPy's default and with R's `sd()`. Why do they differ?",
                     python: #"""
                     import numpy as np
                     x = np.array([2, 4, 4, 4, 5, 5, 7, 9])
                     print(np.std(x), np.std(x, ddof=1))
                     """#,
                     r: #"""
                     x <- c(2, 4, 4, 4, 5, 5, 7, 9)
                     sd(x)                          # n − 1
                     sqrt(mean((x - mean(x))^2))    # n
                     """#,
                     answer: "NumPy's default gives **2.00** (divides by n); R's `sd()` gives **2.14** (divides by n − 1). Use the n − 1 version for sample statistics."),
        ],
        "python-basics": [
            practice("Loop and accumulate",
                     "Without using `mean()`, compute the average of `[4, 5, 3, 5, 2]` with a loop.",
                     python: #"""
                     scores = [4, 5, 3, 5, 2]
                     total = 0
                     for s in scores:
                         total += s
                     print(total / len(scores))
                     """#,
                     r: #"""
                     scores <- c(4, 5, 3, 5, 2)
                     total <- 0
                     for (s in scores) total <- total + s
                     total / length(scores)
                     """#,
                     answer: "The average is **3.8**."),
            practice("Create a grouping variable",
                     "Add an `age_group` column (“under 30” vs. “30+”) to survey.csv and count each group.",
                     python: #"""
                     import numpy as np
                     import pandas as pd
                     df = pd.read_csv("survey.csv")
                     df["age_group"] = np.where(df["age"] < 30, "under 30", "30+")
                     print(df["age_group"].value_counts())
                     """#,
                     r: #"""
                     library(tidyverse)
                     read_csv("survey.csv") |>
                       mutate(age_group = if_else(age < 30, "under 30", "30+")) |>
                       count(age_group)
                     """#,
                     answer: "About a fifth are under 30 — ages are spread evenly from 18 to 75."),
        ],
        "r-basics": [
            practice("Vector practice",
                     "Store the reaction times 480, 512, 650, 430, 700, 555. Compute their mean and SD, and keep only values above 500.",
                     python: #"""
                     import numpy as np
                     rt = np.array([480, 512, 650, 430, 700, 555])
                     print(rt.mean(), rt.std(ddof=1), rt[rt > 500])
                     """#,
                     r: #"""
                     rt <- c(480, 512, 650, 430, 700, 555)
                     mean(rt)
                     sd(rt)
                     rt[rt > 500]
                     """#,
                     answer: "Mean = **554.5**; the values above 500 are 512, 650, 700, and 555."),
            practice("Two-way group summary",
                     "Report the mean anxiety and n for every combination of `region` and `education`.",
                     python: #"""
                     df.groupby(["region", "education"])["anxiety"].agg(["mean", "count"]).round(2)
                     """#,
                     r: #"""
                     df |>
                       group_by(region, education) |>
                       summarise(mean = mean(anxiety), n = n(), .groups = "drop")
                     """#,
                     answer: "Ten rows (2 regions × 5 education levels), all with means near 4 — education has no built-in effect."),
        ],
        "practice-data": [
            practice("Explore diary.csv",
                     "How many people are in diary.csv, how many days does each contribute, and what is the SD of people's *average* work hours compared with the SD of their *daily deviations* from their own average?",
                     python: #"""
                     diary = pd.read_csv("diary.csv")
                     print(diary["participant"].nunique(), diary.groupby("participant").size().unique())
                     person_mean = diary.groupby("participant")["work_hours"].transform("mean")
                     print(diary.groupby("participant")["work_hours"].mean().std(), (diary["work_hours"] - person_mean).std())
                     """#,
                     r: #"""
                     diary <- read.csv("diary.csv")
                     length(unique(diary$participant)); unique(table(diary$participant))
                     sd(tapply(diary$work_hours, diary$participant, mean))
                     sd(diary$work_hours - ave(diary$work_hours, diary$participant))
                     """#,
                     answer: "100 people × 14 days. Person averages vary with an SD of about 1.5 hours; daily deviations from each person's own average vary with an SD of about 1.2 hours. Both kinds of variation matter — see *Between- and within-person correlations*."),
            practice("Group sizes",
                     "How many students received each teaching method in classroom.csv, and how many essays are in essays.csv?",
                     python: #"""
                     print(pd.read_csv("classroom.csv")["method"].value_counts())
                     print(len(pd.read_csv("essays.csv")))
                     """#,
                     r: #"""
                     table(read.csv("classroom.csv")$method)
                     nrow(read.csv("essays.csv"))
                     """#,
                     answer: "Exactly **50 per method** (balanced randomization) and **120** essays."),
        ],
        "reading-output": [
            practice("Check the N",
                     "Fit `anxiety ~ mindfulness`. How many observations did the model use, compared with the number of rows?",
                     python: #"""
                     m = smf.ols("anxiety ~ mindfulness", data=survey).fit()
                     print(m.nobs, len(survey))
                     """#,
                     r: #"""
                     m <- lm(anxiety ~ mindfulness, data = survey)
                     c(nobs(m), nrow(survey))
                     """#,
                     answer: "A few fewer than 375: rows with a missing `mindfulness` score were dropped automatically."),
            practice("Compare models by AIC",
                     "Fit `anxiety ~ rumination` and `anxiety ~ rumination + social_media`. Which has the lower AIC?",
                     python: #"""
                     a = smf.ols("anxiety ~ rumination", data=survey).fit()
                     b = smf.ols("anxiety ~ rumination + social_media", data=survey).fit()
                     print(a.aic, b.aic)
                     """#,
                     r: #"""
                     AIC(lm(anxiety ~ rumination, data = survey),
                         lm(anxiety ~ rumination + social_media, data = survey))
                     """#,
                     answer: "The model with social media has lower AIC, matching the built-in direct effect of social media on anxiety."),
        ],
        "why-statistics": [
            practice("Name the variables",
                     "Students receive feedback written either in the second person (“you”) or the third person (“the student”), assigned at random. Researchers count how many words each student changes in their revision. Identify the IV, the DV, and the design.",
                     answer: "**IV:** feedback person (second vs. third). **DV:** number of words changed. **Design:** a randomized experiment, so a difference can be interpreted causally."),
            practice("From question to design",
                     "Turn “Does social media use relate to anxiety?” into a concrete study. What would you measure, and what can and can't you conclude?",
                     answer: "Survey a sample with validated scales of social media use and anxiety, plus likely confounds (age, sleep). You can estimate the association; you can't claim causation. A randomized reduction-in-use experiment could test causality."),
        ],
        "measurement": [
            practice("Classify the columns",
                     "Give the level of measurement for each survey.csv column: participant, age, education, region, rumination, mind_1.",
                     answer: "`participant`: nominal (an ID). `age`: ratio. `education`: ordinal. `region`: nominal. `rumination`: a multi-item scale mean, usually treated as interval. `mind_1`: a single item, ordinal."),
            practice("Make an ordered factor",
                     "Convert `education` (1–5) into an ordered category with labels HS, Some college, BA, MA, Graduate.",
                     python: #"""
                     labels = ["HS", "Some college", "BA", "MA", "Graduate"]
                     df["education_f"] = pd.Categorical(df["education"].map(dict(zip(range(1, 6), labels))),
                                                        categories=labels, ordered=True)
                     print(df["education_f"].value_counts(sort=False))
                     """#,
                     r: #"""
                     df <- df |>
                       mutate(education_f = factor(education, levels = 1:5,
                                                   labels = c("HS", "Some college", "BA", "MA", "Graduate"),
                                                   ordered = TRUE))
                     table(df$education_f)
                     """#,
                     answer: "Counts appear in the correct order, and comparisons like `education_f > \"BA\"` now work."),
        ],
        "toolkit": [
            practice("Record your environment",
                     "Save the exact package versions for your project to a file.",
                     python: #"""
                     # In the terminal, with the virtual environment active:
                     #   pip freeze > requirements.txt
                     """#,
                     r: #"""
                     writeLines(capture.output(sessionInfo()), "session_info.txt")
                     """#,
                     answer: "A text file listing every package and version. Commit it alongside your analysis scripts."),
            practice("Write the formula",
                     "Write a model formula in which wellbeing is predicted by income, age, and their interaction.",
                     answer: "`wellbeing ~ income * age`, which expands to `income + age + income:age`."),
        ],
        "tidy-data": [
            practice("Long and back again",
                     "Reshape classroom.csv's `pretest` and `posttest` into long format (one row per student × time), then back to wide. Check the row counts.",
                     python: #"""
                     classroom = pd.read_csv("classroom.csv")
                     long = classroom.melt(id_vars=["student", "method"], value_vars=["pretest", "posttest"],
                                           var_name="time", value_name="score")
                     wide = long.pivot(index=["student", "method"], columns="time", values="score").reset_index()
                     print(len(long), len(wide))
                     """#,
                     r: #"""
                     classroom <- read_csv("classroom.csv")
                     long <- classroom |> pivot_longer(c(pretest, posttest), names_to = "time", values_to = "score")
                     wide <- long |> select(student, method, time, score) |> pivot_wider(names_from = time, values_from = score)
                     c(nrow(long), nrow(wide))
                     """#,
                     answer: "**300** rows in long format (150 × 2) and **150** in wide."),
            practice("Apply an exclusion rule",
                     "Suppose the rule is “exclude respondents who answered fewer than 5 of the 6 mindfulness items.” How many respondents does survey.csv lose?",
                     python: #"""
                     survey = pd.read_csv("survey.csv")
                     answered = survey[[f"mind_{i}" for i in range(1, 7)]].notna().sum(axis=1)
                     print((answered < 5).sum())
                     """#,
                     r: #"""
                     survey <- read_csv("survey.csv")
                     sum(rowSums(!is.na(select(survey, mind_1:mind_6))) < 5)
                     """#,
                     answer: "Only a handful (usually under 5). Report the rule and the number excluded."),
        ],
        "central-tendency": [
            practice("One outlier",
                     "Compute the mean and median of 3, 4, 4, 5, 6. Then replace the 6 with 100. What changes?",
                     python: #"""
                     import numpy as np
                     a, b = np.array([3, 4, 4, 5, 6]), np.array([3, 4, 4, 5, 100])
                     print(a.mean(), np.median(a), b.mean(), np.median(b))
                     """#,
                     r: #"""
                     a <- c(3, 4, 4, 5, 6); b <- c(3, 4, 4, 5, 100)
                     c(mean(a), median(a), mean(b), median(b))
                     """#,
                     answer: "The mean jumps from **4.4 to 23.2**; the median stays at **4**."),
            practice("Describe a variable fully",
                     "Report n, mean, median, SD, and IQR of `rumination` for each `region`.",
                     python: #"""
                     survey.groupby("region")["rumination"].agg(
                         n="count", mean="mean", median="median", sd="std",
                         iqr=lambda x: x.quantile(0.75) - x.quantile(0.25)).round(2)
                     """#,
                     r: #"""
                     survey |>
                       group_by(region) |>
                       summarise(n = n(), mean = mean(rumination), median = median(rumination),
                                 sd = sd(rumination), iqr = IQR(rumination))
                     """#,
                     answer: "Both groups have mean and median near 4, an SD around 1, and an IQR around 1.3–1.5."),
        ],
        "visualizing": [
            practice("Histograms by group",
                     "Plot overlaid histograms of `anxiety` for each `region`.",
                     python: #"""
                     import seaborn as sns
                     import matplotlib.pyplot as plt
                     sns.histplot(data=survey, x="anxiety", hue="region", element="step", stat="density", common_norm=False)
                     plt.show()
                     """#,
                     r: #"""
                     ggplot(survey, aes(anxiety, fill = region)) +
                       geom_histogram(alpha = 0.5, position = "identity", bins = 25) +
                       theme_classic()
                     """#,
                     answer: "The two distributions overlap almost completely and are roughly symmetric around 4."),
            practice("Boxplots with points",
                     "Draw boxplots of `rumination` by `education` with jittered points.",
                     python: #"""
                     sns.boxplot(data=survey, x="education", y="rumination", color="white", showfliers=False)
                     sns.stripplot(data=survey, x="education", y="rumination", alpha=0.3, color="0.4")
                     plt.show()
                     """#,
                     r: #"""
                     ggplot(survey, aes(factor(education), rumination)) +
                       geom_boxplot(outlier.shape = NA) +
                       geom_jitter(width = 0.15, alpha = 0.3) +
                       labs(x = "Education") + theme_classic()
                     """#,
                     answer: "All five boxes are similar — education wasn't built into the rumination scores."),
        ],
        "normal-distribution": [
            practice("Flag extreme values",
                     "Compute z-scores for `anxiety`. How many participants have |z| > 3?",
                     python: #"""
                     z = (survey["anxiety"] - survey["anxiety"].mean()) / survey["anxiety"].std()
                     print((z.abs() > 3).sum())
                     """#,
                     r: #"""
                     z <- as.numeric(scale(survey$anxiety))
                     sum(abs(z) > 3)
                     """#,
                     answer: "Zero to two people — in a normal distribution only about 0.3% fall beyond ±3 SD."),
            practice("Taming skew",
                     "Simulate 500 log-normal reaction times and compare skewness before and after a log transform.",
                     python: #"""
                     from scipy import stats
                     rng = np.random.default_rng(1)
                     rt = rng.lognormal(mean=6.3, sigma=0.3, size=500)
                     print(stats.skew(rt), stats.skew(np.log(rt)))
                     """#,
                     r: #"""
                     set.seed(1)
                     rt <- rlnorm(500, meanlog = 6.3, sdlog = 0.3)
                     skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
                     c(skew(rt), skew(log(rt)))
                     """#,
                     answer: "Skewness is clearly positive (around 1) for raw RTs and close to 0 after logging."),
        ],
    ]

    // MARK: Units 3–6

    private static let extraPracticeCore: [String: [Exercise]] = [
        "standard-error": [
            practice("Check CI coverage",
                     "Simulate 1,000 samples of n = 30 from a population with M = 100, SD = 15. What share of 95% CIs contain 100?",
                     python: #"""
                     import numpy as np
                     from scipy import stats
                     rng = np.random.default_rng(3)
                     hits = 0
                     for _ in range(1000):
                         x = rng.normal(100, 15, 30)
                         lo, hi = stats.t.interval(0.95, df=29, loc=x.mean(), scale=stats.sem(x))
                         hits += lo <= 100 <= hi
                     print(hits / 1000)
                     """#,
                     r: #"""
                     set.seed(3)
                     mean(replicate(1000, {
                       ci <- t.test(rnorm(30, 100, 15))$conf.int
                       ci[1] <= 100 && 100 <= ci[2]
                     }))
                     """#,
                     answer: "About **95%** — that's what “95% confidence” means."),
            practice("Sample size and width",
                     "Compute 95% CIs for mean anxiety in the full sample and among rural respondents only. Which is wider, and why?",
                     python: #"""
                     for name, x in [("all", survey["anxiety"]), ("rural", survey.loc[survey["region"] == "rural", "anxiety"])]:
                         print(name, stats.t.interval(0.95, df=len(x) - 1, loc=x.mean(), scale=stats.sem(x)))
                     """#,
                     r: #"""
                     t.test(survey$anxiety)$conf.int
                     t.test(survey$anxiety[survey$region == "rural"])$conf.int
                     """#,
                     answer: "The rural-only CI is wider because n is smaller (≈150 vs. 375)."),
        ],
        "hypothesis-testing": [
            practice("p-values when nothing is going on",
                     "Simulate 10,000 t-tests comparing two groups drawn from the same population. What share have p < .05? What does the histogram of p-values look like?",
                     python: #"""
                     rng = np.random.default_rng(5)
                     p = np.array([stats.ttest_ind(rng.normal(size=20), rng.normal(size=20)).pvalue for _ in range(10_000)])
                     print((p < 0.05).mean())
                     """#,
                     r: #"""
                     set.seed(5)
                     p <- replicate(10000, t.test(rnorm(20), rnorm(20))$p.value)
                     mean(p < 0.05)
                     hist(p)
                     """#,
                     answer: "About **5%**, and the histogram is flat (uniform). Under H₀, every p-value is equally likely."),
            practice("A permutation test on real columns",
                     "Use a permutation test to ask whether mean `anxiety` differs between urban and rural respondents.",
                     hint: "Reuse the permutation code from the lesson with `region` as the group variable.",
                     answer: "The permutation p-value is usually well above .05 — the generator built in no regional difference in anxiety."),
        ],
        "effect-sizes": [
            practice("Power for small, medium, large",
                     "How many participants per group give 80% power for d = 0.2, 0.5, and 0.8?",
                     python: #"""
                     import numpy as np
                     from statsmodels.stats.power import TTestIndPower
                     for d in [0.2, 0.5, 0.8]:
                         print(d, np.ceil(TTestIndPower().solve_power(effect_size=d, power=0.8, alpha=0.05)))
                     """#,
                     r: #"""
                     sapply(c(0.2, 0.5, 0.8), function(d) ceiling(pwr::pwr.t.test(d = d, power = 0.8)$n))
                     """#,
                     answer: "About **394**, **64**, and **26** per group. Small effects need very large samples."),
            practice("Effect size in the classroom experiment",
                     "Compute Cohen's d for post-test scores, active learning vs. lecture (no covariates).",
                     python: #"""
                     import pingouin as pg
                     classroom = pd.read_csv("classroom.csv")
                     print(pg.compute_effsize(classroom.loc[classroom["method"] == "active", "posttest"],
                                              classroom.loc[classroom["method"] == "lecture", "posttest"]))
                     """#,
                     r: #"""
                     classroom <- read.csv("classroom.csv")
                     effectsize::cohens_d(posttest ~ method, data = subset(classroom, method %in% c("active", "lecture")))
                     """#,
                     answer: "Roughly d ≈ 0.4–0.5 in magnitude (the sign depends on which group is listed first), with a wide CI at n = 50 per group."),
        ],
        "t-tests": [
            practice("Paired change",
                     "In the active-learning group only, did scores change from pre-test to post-test? Use a paired t-test.",
                     python: #"""
                     from scipy import stats
                     a = classroom[classroom["method"] == "active"]
                     print(stats.ttest_rel(a["posttest"], a["pretest"]))
                     """#,
                     r: #"""
                     a <- subset(classroom, method == "active")
                     t.test(a$posttest, a$pretest, paired = TRUE)
                     """#,
                     answer: "A significant increase of about 4 points. Without a comparison group, though, you can't attribute the gain to the method — students might improve anyway."),
            practice("Welch between methods",
                     "Compare post-test scores between active learning and lecture with a Welch t-test.",
                     python: #"""
                     print(stats.ttest_ind(classroom.loc[classroom["method"] == "active", "posttest"],
                                           classroom.loc[classroom["method"] == "lecture", "posttest"], equal_var=False))
                     """#,
                     r: #"""
                     t.test(posttest ~ method, data = subset(classroom, method %in% c("active", "lecture")))
                     """#,
                     answer: "Active learning scores higher, but the test is sometimes borderline at n = 50 per group. ANCOVA (*ANCOVA & contrast coding*, later in this unit) adds power by adjusting for the pre-test."),
        ],
        "anova": [
            practice("One-way with post-hoc tests",
                     "Run a one-way ANOVA of `posttest` by `method`, followed by Tukey comparisons.",
                     python: #"""
                     import pingouin as pg
                     print(pg.anova(data=classroom, dv="posttest", between="method", detailed=True))
                     print(pg.pairwise_tukey(data=classroom, dv="posttest", between="method"))
                     """#,
                     r: #"""
                     fit <- aov(posttest ~ method, data = classroom)
                     summary(fit)
                     TukeyHSD(fit)
                     """#,
                     answer: "Active learning has the highest mean. Without adjusting for the pre-test, not every pairwise difference reaches significance."),
            practice("Two-way ANOVA",
                     "Test `posttest ~ method * school`. Does the method effect differ across schools?",
                     python: #"""
                     print(pg.anova(data=classroom, dv="posttest", between=["method", "school"]))
                     """#,
                     r: #"""
                     summary(aov(posttest ~ method * school, data = classroom))
                     """#,
                     answer: "No meaningful interaction — the generator gave every school the same method effects. (With about 12 students per cell, this test also has little power.)"),
        ],
        "chi-square": [
            practice("Was randomization independent of school?",
                     "Test whether `method` and `school` are associated in classroom.csv.",
                     python: #"""
                     from scipy import stats
                     table = pd.crosstab(classroom["method"], classroom["school"])
                     print(table, stats.chi2_contingency(table)[:2])
                     """#,
                     r: #"""
                     chisq.test(table(classroom$method, classroom$school))
                     """#,
                     answer: "Not significant — methods were assigned independently of school. (Some expected counts are near 10–15, so the χ² approximation is fine.)"),
            practice("Chi-square by hand",
                     "For the 2 × 2 table [[30, 20], [10, 40]], compute the expected counts and χ². Then compare with the software (watch the continuity correction).",
                     python: #"""
                     import numpy as np
                     t = np.array([[30, 20], [10, 40]])
                     print(stats.chi2_contingency(t, correction=False))   # 16.67
                     print(stats.chi2_contingency(t)[0])                    # Yates-corrected: 15.04
                     """#,
                     r: #"""
                     t <- matrix(c(30, 10, 20, 40), nrow = 2)
                     chisq.test(t, correct = FALSE)   # 16.67
                     chisq.test(t)                    # Yates-corrected: 15.04
                     """#,
                     answer: "Expected counts are [[20, 30], [20, 30]]; χ² = 10²/20 + 10²/30 + 10²/20 + 10²/30 ≈ **16.67**. Both SciPy and R apply Yates' continuity correction to 2 × 2 tables by default (χ² ≈ 15.04)."),
        ],
        "non-parametric": [
            practice("An ordinal item by group",
                     "Compare the single item `mind_1` between urban and rural respondents with a Mann–Whitney test.",
                     python: #"""
                     from scipy import stats
                     d = survey.dropna(subset=["mind_1"])
                     print(stats.mannwhitneyu(d.loc[d["region"] == "rural", "mind_1"],
                                              d.loc[d["region"] == "urban", "mind_1"]))
                     """#,
                     r: #"""
                     wilcox.test(mind_1 ~ region, data = survey)
                     """#,
                     answer: "No meaningful difference — region wasn't built into mindfulness. A single 1–5 item is ordinal, which is why a rank test suits it."),
            practice("Pearson vs. Spearman",
                     "Compute both correlations between `work_hours` and `wellbeing` across all rows of diary.csv. Why should you be suspicious of either number?",
                     python: #"""
                     diary = pd.read_csv("diary.csv")
                     print(stats.pearsonr(diary["work_hours"], diary["wellbeing"]),
                           stats.spearmanr(diary["work_hours"], diary["wellbeing"]))
                     """#,
                     r: #"""
                     diary <- read.csv("diary.csv")
                     cor(diary$work_hours, diary$wellbeing)
                     cor(diary$work_hours, diary$wellbeing, method = "spearman")
                     """#,
                     answer: "Both are small and positive (around .2) and nearly identical. But they pool 14 days per person, mixing between-person and within-person relationships that actually have **opposite** signs — see *Between- and within-person correlations*."),
        ],
        "correlation": [
            practice("Correlation matrix",
                     "Compute the correlation matrix of social_media, phone_checking, rumination, anxiety, and mindfulness. Which pair correlates most strongly?",
                     python: #"""
                     cols = ["social_media", "phone_checking", "rumination", "anxiety", "mindfulness"]
                     print(survey[cols].corr().round(2))
                     """#,
                     r: #"""
                     round(cor(survey[c("social_media", "phone_checking", "rumination", "anxiety", "mindfulness")],
                               use = "pairwise.complete.obs"), 2)
                     """#,
                     answer: "`social_media` and `phone_checking` (r ≈ .6), followed by rumination with social media and with anxiety. Mindfulness correlates negatively with rumination."),
            practice("Restricted range",
                     "Compare the rumination–anxiety correlation in the full sample with the correlation among people whose rumination is above 4.5.",
                     python: #"""
                     high = survey[survey["rumination"] > 4.5]
                     print(survey["rumination"].corr(survey["anxiety"]), high["rumination"].corr(high["anxiety"]))
                     """#,
                     r: #"""
                     high <- subset(survey, rumination > 4.5)
                     c(cor(survey$rumination, survey$anxiety), cor(high$rumination, high$anxiety))
                     """#,
                     answer: "The correlation is noticeably weaker in the restricted group, even though the underlying relationship is the same."),
        ],
        "simple-regression": [
            practice("Make predictions",
                     "Using `anxiety ~ rumination`, predict anxiety for rumination = 2 and rumination = 6.",
                     python: #"""
                     m = smf.ols("anxiety ~ rumination", data=survey).fit()
                     print(m.predict(pd.DataFrame({"rumination": [2, 6]})))
                     """#,
                     r: #"""
                     m <- lm(anxiety ~ rumination, data = survey)
                     predict(m, newdata = data.frame(rumination = c(2, 6)))
                     """#,
                     answer: "The two predictions differ by exactly 4 × the slope — about 2 scale points."),
            practice("Residual plot",
                     "Plot residuals against fitted values for that model. Any pattern?",
                     python: #"""
                     import matplotlib.pyplot as plt
                     plt.scatter(m.fittedvalues, m.resid, alpha=0.4)
                     plt.axhline(0, color="0.5")
                     plt.xlabel("Fitted"); plt.ylabel("Residual"); plt.show()
                     """#,
                     r: #"""
                     plot(fitted(m), resid(m)); abline(h = 0)
                     """#,
                     answer: "A shapeless cloud around 0, with slight compression at the ends where the 1–7 scale was clipped."),
        ],
        "multiple-regression": [
            practice("Direct effect of social media",
                     "Fit `anxiety ~ rumination + social_media + age + region`. Interpret the social media coefficient.",
                     python: #"""
                     print(smf.ols("anxiety ~ rumination + social_media + age + C(region)", data=survey).fit().summary().tables[1])
                     """#,
                     r: #"""
                     summary(lm(anxiety ~ rumination + social_media + age + region, data = survey))
                     """#,
                     answer: "A small positive coefficient: at equal rumination, more social media use still predicts slightly more anxiety — the built-in direct effect."),
            practice("Switch the reference level",
                     "Refit with `rural` as the reference level of `region`. What happens to that coefficient?",
                     python: #"""
                     smf.ols("anxiety ~ rumination + C(region, Treatment('rural'))", data=survey).fit().params
                     """#,
                     r: #"""
                     lm(anxiety ~ rumination + relevel(factor(region), ref = "rural"), data = survey)
                     """#,
                     answer: "The coefficient has the same size and the opposite sign. The model is identical; only the comparison changed."),
        ],
        "logistic-regression": [
            practice("A binary outcome from a scale",
                     "Create `high_anxiety` = anxiety > 5 and model it on rumination. Report the odds ratio per point of rumination.",
                     python: #"""
                     survey["high_anxiety"] = (survey["anxiety"] > 5).astype(int)
                     m = smf.logit("high_anxiety ~ rumination", data=survey).fit(disp=False)
                     print(np.exp(m.params), np.exp(m.conf_int()))
                     """#,
                     r: #"""
                     survey$high_anxiety <- as.integer(survey$anxiety > 5)
                     m <- glm(high_anxiety ~ rumination, data = survey, family = binomial)
                     exp(cbind(coef(m), confint(m)))
                     """#,
                     answer: "The OR per point is well above 1 (roughly 2–3). (Dichotomizing a continuous outcome throws away information — this is for practice only.)"),
            practice("Predicted probabilities",
                     "Using that model, what is the predicted probability of high anxiety at rumination = 3 and at rumination = 6?",
                     python: #"""
                     print(m.predict(pd.DataFrame({"rumination": [3, 6]})))
                     """#,
                     r: #"""
                     predict(m, newdata = data.frame(rumination = c(3, 6)), type = "response")
                     """#,
                     answer: "Low (around .05) at 3 and much higher (around .4–.5) at 6 — probabilities change nonlinearly even though the log-odds slope is constant."),
        ],
        "mixed-models": [
            practice("Random slopes for daily work hours",
                     "In diary.csv, person-mean-center `work_hours` and fit `wellbeing ~ hours_within + (1 + hours_within | participant)`. Do the within-person slopes vary across people?",
                     python: #"""
                     import statsmodels.formula.api as smf
                     diary["hours_within"] = diary["work_hours"] - diary.groupby("participant")["work_hours"].transform("mean")
                     m = smf.mixedlm("wellbeing ~ hours_within", data=diary, groups=diary["participant"],
                                     re_formula="~hours_within").fit()
                     print(m.summary())
                     """#,
                     r: #"""
                     library(lmerTest)
                     diary <- diary |> group_by(participant) |>
                       mutate(hours_within = work_hours - mean(work_hours)) |> ungroup()
                     m <- lmer(wellbeing ~ hours_within + (1 + hours_within | participant), data = diary)
                     summary(m)
                     VarCorr(m)
                     """#,
                     answer: "The average within-person slope is negative (about −0.25 wellbeing points per extra hour), and the random-slope SD is around 0.1–0.15, so people differ in how strongly long days affect them."),
            practice("How clustered is daily wellbeing?",
                     "Compute the ICC of `wellbeing` for `participant` with a random-intercept model.",
                     python: #"""
                     fit = smf.mixedlm("wellbeing ~ 1", data=diary, groups=diary["participant"]).fit()
                     between = fit.cov_re.iloc[0, 0]
                     print(between / (between + fit.scale))
                     """#,
                     r: #"""
                     vc <- as.data.frame(VarCorr(lmer(wellbeing ~ 1 + (1 | participant), data = diary)))
                     vc$vcov[1] / sum(vc$vcov)
                     """#,
                     answer: "About .5: roughly half of the variation in daily wellbeing is stable differences between people, and half is day-to-day fluctuation. Ignoring that clustering would treat 1,400 days as 1,400 independent observations."),
            practice("Clustered course evaluations",
                     "In OpenIntro's `evals`, most professors taught several courses, so rows aren't independent. Refit `score ~ bty_avg` as a mixed model with a random intercept for `prof_id`. How does the standard error of the slope change?",
                     python: #"""
                     evals = pd.read_csv("https://www.openintro.org/data/csv/evals.csv")
                     ols = smf.ols("score ~ bty_avg", data=evals).fit()
                     mm = smf.mixedlm("score ~ bty_avg", data=evals, groups=evals["prof_id"]).fit()
                     print("OLS SE:", ols.bse["bty_avg"], " mixed-model SE:", mm.bse["bty_avg"])
                     """#,
                     r: #"""
                     library(openintro)
                     summary(lm(score ~ bty_avg, data = evals))$coefficients["bty_avg", ]
                     summary(lmer(score ~ bty_avg + (1 | prof_id), data = evals))$coefficients["bty_avg", ]
                     """#,
                     answer: "The mixed-model standard error is larger: appearance ratings are constant within a professor, so the effective sample size is closer to 94 professors than to 463 courses."),
        ],
        "reliability": [
            practice("One factor or two?",
                     "Run an EFA with one factor on the reverse-keyed mindfulness items. Then run it on the raw items. Compare the loadings of items 3 and 5.",
                     python: #"""
                     from factor_analyzer import FactorAnalyzer
                     items = [f"mind_{i}" for i in range(1, 7)]
                     keyed = survey[items].copy()
                     keyed[["mind_3", "mind_5"]] = 6 - keyed[["mind_3", "mind_5"]]
                     for data in [keyed, survey[items]]:
                         fa = FactorAnalyzer(n_factors=1, rotation=None).fit(data.dropna())
                         print(fa.loadings_.round(2).ravel())
                     """#,
                     r: #"""
                     keyed <- survey |> select(mind_1:mind_6) |> mutate(across(c(mind_3, mind_5), ~ 6 - .x))
                     psych::fa(keyed, nfactors = 1)$loadings
                     psych::fa(select(survey, mind_1:mind_6), nfactors = 1)$loadings
                     """#,
                     answer: "With keyed items, all six load positively (around .6–.7). With raw items, items 3 and 5 load **negatively** — the factor-analytic sign of unrecoded reverse items."),
            practice("How many factors?",
                     "Run a parallel analysis on the keyed items. How many factors does it suggest?",
                     r: #"""
                     psych::fa.parallel(keyed, fa = "fa")
                     """#,
                     answer: "One factor — the items were generated from a single latent trait."),
        ],
        "reporting": [
            practice("Write an APA sentence",
                     "Run a Welch t-test of post-test scores (active vs. lecture) and write the APA-style result sentence.",
                     python: #"""
                     import pingouin as pg
                     res = pg.ttest(classroom.loc[classroom["method"] == "active", "posttest"],
                                    classroom.loc[classroom["method"] == "lecture", "posttest"]).iloc[0]
                     print(f"t({res['dof']:.1f}) = {res['T']:.2f}, p = {res['p-val']:.3f}, d = {res['cohen-d']:.2f}")
                     """#,
                     r: #"""
                     library(report)
                     t.test(posttest ~ method, data = subset(classroom, method %in% c("active", "lecture"))) |> report()
                     """#,
                     answer: "Something like: “Post-test scores were higher with active learning (*M* = …, *SD* = …) than with lecture (*M* = …, *SD* = …), *t*(97.8) = 2.10, *p* = .038, *d* = 0.42.” Your numbers will differ."),
            practice("Draft a preregistration",
                     "List what a preregistration for the classroom experiment should state.",
                     answer: "Hypotheses and their direction; the primary outcome; the model (posttest ~ method + pretest + school) and reference level; one- vs. two-tailed tests; the sample size and its justification; exclusion rules; how missing data are handled; and any planned sensitivity analyses."),
        ],
    ]

    // MARK: Units 7–9

    private static let extraPracticeResearch: [String: [Exercise]] = [
        "scale-scoring": [
            practice("Item descriptives",
                     "Report the mean and SD of each keyed mindfulness item. Do any items look unusual?",
                     python: #"""
                     print(keyed.agg(["mean", "std"]).round(2))
                     """#,
                     r: #"""
                     psych::describe(keyed)
                     """#,
                     answer: "All items have similar means (near 3) and SDs (around 1.1) after keying — nothing stands out."),
            practice("Sum vs. mean scores",
                     "Compute a sum score for complete cases and correlate it with the mean score. Why prefer the mean when items are missing?",
                     python: #"""
                     complete = keyed.dropna()
                     print(complete.sum(axis=1).corr(complete.mean(axis=1)))
                     """#,
                     r: #"""
                     complete <- na.omit(keyed)
                     cor(rowSums(complete), rowMeans(complete))
                     """#,
                     answer: "They correlate at exactly 1 for complete cases. With missing items, sums shrink artificially, while means stay on the item scale."),
        ],
        "comparing-predictors": [
            practice("Hierarchical steps",
                     "Fit three models: covariates only; + social_media; + phone_checking. Report R² and ΔR² at each step.",
                     python: #"""
                     steps = ["age + education + C(region)",
                              "age + education + C(region) + social_media",
                              "age + education + C(region) + social_media + phone_checking"]
                     r2 = [smf.ols(f"rumination ~ {s}", data=survey).fit().rsquared for s in steps]
                     print(np.round(r2, 3), np.round(np.diff(r2), 3))
                     """#,
                     r: #"""
                     m1 <- lm(rumination ~ age + education + region, data = survey)
                     m2 <- update(m1, . ~ . + social_media)
                     m3 <- update(m2, . ~ . + phone_checking)
                     anova(m1, m2, m3)
                     sapply(list(m1, m2, m3), function(m) summary(m)$r.squared)
                     """#,
                     answer: "Covariates explain little. Adding social media produces a large ΔR²; adding phone checking afterwards adds a small but usually significant ΔR²."),
            practice("Order matters for ΔR²",
                     "Reverse the order: add phone_checking before social_media. How do the ΔR² values change?",
                     answer: "Phone checking now gets a larger ΔR², because it absorbs variance it shares with social media. That's why “added last” ΔR² is used to compare **unique** contributions."),
        ],
        "moderation": [
            practice("Simple slopes from the coefficients",
                     "Compute the simple slopes at −1 SD, mean, and +1 SD directly from the interaction model's coefficients, and check them against the re-centering results.",
                     python: #"""
                     b = model.params
                     for w in [-sd, 0, sd]:
                         print(round(b["sm_c"] + b["sm_c:mind_c"] * w, 3))
                     """#,
                     r: #"""
                     b <- coef(model); s <- sd(survey$mind_c)
                     b["sm_c"] + b["sm_c:mind_c"] * c(-s, 0, s)
                     """#,
                     answer: "Identical to the re-centered estimates. Re-centering adds the correct standard errors and p-values."),
            practice("Find the Johnson–Neyman boundary",
                     "Find the mindfulness value at which the social media slope stops being significant.",
                     python: #"""
                     V = model.cov_params()
                     ws = np.linspace(survey["mind_c"].min(), survey["mind_c"].max(), 200)
                     slope = b["sm_c"] + b["sm_c:mind_c"] * ws
                     se = np.sqrt(V.loc["sm_c", "sm_c"] + ws**2 * V.loc["sm_c:mind_c", "sm_c:mind_c"]
                                  + 2 * ws * V.loc["sm_c", "sm_c:mind_c"])
                     t_crit = stats.t.ppf(0.975, model.df_resid)
                     print(ws[np.abs(slope / se) < t_crit])     # W values where the slope is NOT significant
                     """#,
                     r: #"""
                     interactions::johnson_neyman(model, pred = sm_c, modx = mind_c)
                     """#,
                     answer: "The slope is significant across most of the observed range. Any non-significant region lies at very high mindfulness, where the slope approaches zero."),
        ],
        "mediation": [
            practice("Verify c = c′ + ab",
                     "Fit the total-effect model (anxiety on social media and covariates) and check that its coefficient equals c′ + a × b.",
                     python: #"""
                     c = smf.ols(f"anxiety ~ social_media + {covs}", data=survey).fit().params["social_media"]
                     c_prime = smf.ols(f"anxiety ~ rumination + social_media + {covs}", data=survey).fit().params["social_media"]
                     print(c, c_prime + a * b)
                     """#,
                     r: #"""
                     c_total <- coef(lm(anxiety ~ social_media + age + education + rural, data = survey))["social_media"]
                     c_prime <- coef(lm(anxiety ~ rumination + social_media + age + education + rural, data = survey))["social_media"]
                     c(c_total, c_prime + a * b)
                     """#,
                     answer: "They match exactly. With OLS and the same covariates in every equation, the total effect always decomposes into direct + indirect."),
            practice("A second predictor",
                     "Run the same mediation model with `phone_checking` as X. Is there an indirect effect through rumination?",
                     answer: "Yes — a positive indirect effect, smaller than social media's. Phone checking affects rumination both directly and through its correlation with social media use."),
        ],
        "moderated-mediation": [
            practice("Plot the conditional indirect effect",
                     "Compute (a₁ + a₃ × W) × b across the observed range of centered mindfulness and plot it.",
                     python: #"""
                     import matplotlib.pyplot as plt
                     a = smf.ols(f"rumination ~ sm_c * mind_c + {covs}", data=survey).fit().params
                     b = smf.ols(f"anxiety ~ rumination + sm_c + {covs}", data=survey).fit().params["rumination"]
                     ws = np.linspace(survey["mind_c"].min(), survey["mind_c"].max(), 100)
                     plt.plot(ws, (a["sm_c"] + a["sm_c:mind_c"] * ws) * b)
                     plt.axhline(0, color="0.6", linestyle="--")
                     plt.xlabel("Mindfulness (centered)"); plt.ylabel("Indirect effect"); plt.show()
                     """#,
                     r: #"""
                     est <- parameterEstimates(fit)
                     a1 <- est$est[est$label == "a1"]; a3 <- est$est[est$label == "a3"]; b <- est$est[est$label == "b"]
                     w <- seq(min(survey$mind_c), max(survey$mind_c), length.out = 100)
                     plot(w, (a1 + a3 * w) * b, type = "l", xlab = "Mindfulness (centered)", ylab = "Indirect effect")
                     abline(h = 0, lty = 2)
                     """#,
                     answer: "A straight, downward-sloping line: the indirect effect shrinks as mindfulness rises, and its slope is the index of moderated mediation."),
            practice("How many resamples?",
                     "Rerun the bootstrap with 1,000 and then 5,000 resamples. How much do the CI endpoints change?",
                     answer: "Endpoints shift in the second or third decimal with 1,000 resamples and settle with 5,000+. For publication, 5,000–10,000 is standard."),
        ],
        "ordinal-models": [
            practice("Check proportional odds",
                     "In R, fit a fixed-effects `clm` and let the effect of `complex` vary across thresholds (`nominal = ~ complex`). Compare the two models.",
                     r: #"""
                     m_po  <- clm(rating ~ complex * long, data = judgments)
                     m_npo <- clm(rating ~ long + complex:long, nominal = ~ complex, data = judgments)
                     anova(m_po, m_npo)
                     """#,
                     answer: "The test is usually not significant: the data were generated with a single latent shift, so proportional odds holds. A significant result would mean `complex` affects some thresholds more than others."),
            practice("What do random effects change?",
                     "Fit the clmm with and without `(1 | item)`. Compare the standard error of `complex`.",
                     r: #"""
                     m_full <- clmm(rating ~ complex * long + (1 | participant) + (1 | item), data = judgments)
                     m_less <- clmm(rating ~ complex * long + (1 | participant), data = judgments)
                     rbind(full = coef(summary(m_full))["complex", ], less = coef(summary(m_less))["complex", ])
                     """#,
                     answer: "Without `(1 | item)`, the standard error of `complex` is smaller — the model ignores that conclusions should generalize to other sentences, not just these 32."),
        ],
        "mixed-logistic": [
            practice("Does distance affect accuracy?",
                     "Add `distance` and its interaction with `structure` to the accuracy model. Do they matter?",
                     python: #"""
                     gee2 = smf.gee("correct ~ C(structure, Treatment('simple')) * C(distance, Treatment('short'))",
                                    groups="participant", data=judgments, family=sm.families.Binomial()).fit()
                     print(gee2.summary())
                     """#,
                     r: #"""
                     summary(glmer(correct ~ structure * distance + (1 | participant) + (1 | item),
                                   data = judgments, family = binomial))
                     """#,
                     answer: "Neither distance nor the interaction matters — only structure was built into accuracy. Ratings and accuracy can be affected by different things."),
            practice("Predicted accuracy",
                     "Report predicted accuracy for simple and complex sentences for a typical participant and item.",
                     r: #"""
                     plogis(fixef(m)[1] + c(simple = 0, complex = fixef(m)[2]))
                     """#,
                     answer: "Roughly .80 for simple and .72 for complex sentences — an odds ratio of about 0.6."),
        ],
    ]

    // MARK: Units 10–11

    private static let extraPracticeStructure: [String: [Exercise]] = [
        "ancova": [
            practice("Adjusted means",
                     "Compute covariate-adjusted mean post-test scores for each method.",
                     python: #"""
                     adjusted = {m_: m.predict(classroom.assign(method=pd.Categorical([m_] * len(classroom), categories=methods))).mean()
                                 for m_ in methods}
                     print(pd.Series(adjusted).round(2))
                     """#,
                     r: #"""
                     emmeans(m, ~ method)
                     """#,
                     answer: "Active learning has the highest adjusted mean, about 4–5 points above lecture; flipped sits close to lecture."),
            practice("A second one-tailed test",
                     "Test flipped > lecture one-tailed.",
                     python: #"""
                     name = "C(method)[T.flipped]"
                     b, p_two = m.params[name], m.pvalues[name]
                     print(b, p_two / 2 if b > 0 else 1 - p_two / 2)
                     """#,
                     r: #"""
                     pt(coef(summary(m))["methodflipped", "t value"], df = m$df.residual, lower.tail = FALSE)
                     """#,
                     answer: "A small difference that's usually not significant, consistent with the tiny built-in effect (0.1 SD)."),
            practice("Reading sum-coded coefficients",
                     "In the sum-coded model, what does each `method` coefficient mean, and how do you get the third method's deviation?",
                     answer: "Each coefficient is that method's adjusted mean minus the grand mean of the three adjusted means. The omitted method's deviation is minus the sum of the other two, because deviations sum to zero."),
        ],
        "sample-planning": [
            practice("Simulate ANCOVA power",
                     "Simulate a two-group design (n = 50 per group, pre–post r = .7, effect = 0.4 SD) and estimate the power of an ANCOVA to detect the group difference.",
                     python: #"""
                     def one_study(rng, n=50):
                         group = np.repeat(["control", "treatment"], n)
                         pre = rng.normal(size=2 * n)
                         post = 0.7 * pre + np.where(group == "treatment", 0.4, 0) + rng.normal(0, np.sqrt(1 - 0.49), 2 * n)
                         d = pd.DataFrame({"group": group, "pre": pre, "post": post})
                         return smf.ols("post ~ C(group) + pre", data=d).fit().pvalues["C(group)[T.treatment]"] < 0.05

                     rng = np.random.default_rng(11)
                     print(np.mean([one_study(rng) for _ in range(1000)]))
                     """#,
                     r: #"""
                     one_study <- function(n = 50) {
                       group <- rep(c("control", "treatment"), each = n)
                       pre <- rnorm(2 * n)
                       post <- 0.7 * pre + ifelse(group == "treatment", 0.4, 0) + rnorm(2 * n, sd = sqrt(1 - 0.49))
                       summary(lm(post ~ group + pre))$coefficients["grouptreatment", "Pr(>|t|)"] < 0.05
                     }
                     set.seed(11)
                     mean(replicate(1000, one_study()))
                     """#,
                     answer: "Power is around .75–.80 — far higher than the ≈ .5 a post-only comparison would have. The pre-test does a lot of work."),
            practice("Covariates buy power",
                     "Find the n per group for d = 0.4 at 80% power. Then recompute assuming a baseline covariate that correlates r = .7 with the outcome (effective d = d / √(1 − r²)).",
                     python: #"""
                     from statsmodels.stats.power import TTestIndPower
                     d = 0.4
                     for effect in [d, d / np.sqrt(1 - 0.7**2)]:
                         print(np.ceil(TTestIndPower().solve_power(effect_size=effect, power=0.8, alpha=0.05)))
                     """#,
                     r: #"""
                     d <- 0.4
                     sapply(c(d, d / sqrt(1 - 0.7^2)), function(x) ceiling(pwr::pwr.t.test(d = x, power = 0.8)$n))
                     """#,
                     answer: "About **100** per group without the covariate and about **52** with it — roughly half."),
            practice("Move the interim look",
                     "In rpact, compare the stage-wise thresholds when the interim is at 50% vs. 70% of the information.",
                     r: #"""
                     library(rpact)
                     for (f in c(0.5, 0.7)) {
                       d <- getDesignGroupSequential(kMax = 2, alpha = 0.05, sided = 2,
                                                     informationRates = c(f, 1), typeOfDesign = "asOF")
                       print(round(d$stageLevels * 2, 4))   # two-sided nominal levels per stage
                     }
                     """#,
                     answer: "An earlier look gets a stricter threshold (about .003 at 50%); a later look spends more α early. The final threshold stays close to .05 in both."),
        ],
        "bootstrap": [
            practice("A difference in medians",
                     "Bootstrap a 95% CI for the difference in median anxiety between urban and rural respondents.",
                     python: #"""
                     urban = survey.loc[survey["region"] == "urban", "anxiety"].to_numpy()
                     rural = survey.loc[survey["region"] == "rural", "anxiety"].to_numpy()
                     diffs = [np.median(rng.choice(urban, len(urban))) - np.median(rng.choice(rural, len(rural)))
                              for _ in range(5000)]
                     print(np.median(urban) - np.median(rural), np.percentile(diffs, [2.5, 97.5]))
                     """#,
                     r: #"""
                     urban <- survey$anxiety[survey$region == "urban"]; rural <- survey$anxiety[survey$region == "rural"]
                     set.seed(3)
                     diffs <- replicate(5000, median(sample(urban, replace = TRUE)) - median(sample(rural, replace = TRUE)))
                     quantile(diffs, c(0.025, 0.975))
                     """#,
                     answer: "The CI comfortably includes 0 — no built-in regional difference. Resampling each group separately preserves the group sizes."),
            practice("How many resamples?",
                     "Compute the bootstrap CI for the median twice with 500 resamples and twice with 10,000. How much do the endpoints move?",
                     answer: "With 500 resamples the endpoints jump around noticeably between runs; with 10,000 they're stable to the second decimal. Use thousands of resamples for anything you report."),
            practice("Cluster bootstrap for a mean",
                     "Get a 95% CI for mean daily wellbeing in diary.csv two ways: treating all days as independent, and with a cluster bootstrap over people.",
                     python: #"""
                     from scipy import stats
                     w = diary["wellbeing"]
                     print(stats.t.interval(0.95, len(w) - 1, loc=w.mean(), scale=stats.sem(w)))
                     by_person = {pid: g["wellbeing"].to_numpy() for pid, g in diary.groupby("participant")}
                     ids = np.array(list(by_person))
                     boots = [np.concatenate([by_person[i] for i in rng.choice(ids, len(ids))]).mean() for _ in range(2000)]
                     print(np.percentile(boots, [2.5, 97.5]))
                     """#,
                     r: #"""
                     t.test(diary$wellbeing)$conf.int
                     by_person <- split(diary$wellbeing, diary$participant)
                     set.seed(4)
                     boots <- replicate(2000, mean(unlist(by_person[sample(names(by_person), replace = TRUE)])))
                     quantile(boots, c(0.025, 0.975))
                     """#,
                     answer: "The cluster interval is noticeably wider (often around twice as wide), because about half the variance in wellbeing is stable differences between people."),
        ],
        "between-within": [
            practice("Look at the individual correlations",
                     "Compute each person's correlation between work hours and wellbeing. Plot a histogram and count how many are negative.",
                     python: #"""
                     per_person = diary.groupby("participant")[["work_hours", "wellbeing"]].apply(
                         lambda g: g["work_hours"].corr(g["wellbeing"]))
                     per_person.hist(bins=25)
                     print((per_person < 0).mean())
                     """#,
                     r: #"""
                     per_person <- tapply(seq_len(nrow(diary)), diary$participant,
                                          function(i) cor(diary$work_hours[i], diary$wellbeing[i]))
                     hist(per_person, breaks = 25)
                     mean(per_person < 0)
                     """#,
                     answer: "Most people (around 85–90%) have a negative within-person correlation, centered near −.35, with a wide spread because each is based on only 14 days."),
            practice("A purely between-person question",
                     "Do more conscientious people report higher *average* wellbeing? Use one row per person.",
                     python: #"""
                     people = diary.groupby("participant")[["wellbeing", "conscientiousness"]].mean()
                     print(people.corr().iloc[0, 1])
                     """#,
                     r: #"""
                     people <- aggregate(cbind(wellbeing, conscientiousness) ~ participant, data = diary, FUN = mean)
                     cor.test(people$wellbeing, people$conscientiousness)
                     """#,
                     answer: "Essentially no relationship — conscientiousness was built to change the *within-person* slope, not average wellbeing. A person-level question needs person-level data (n = 100)."),
        ],
        "inter-rater": [
            practice("A third rater",
                     "Simulate a third rater who scores 40% of essays at random (1–6) and copies rater A otherwise. Compute Krippendorff's α across all three raters.",
                     python: #"""
                     rng = np.random.default_rng(2)
                     rater_c = np.where(rng.random(len(essays)) < 0.4, rng.integers(1, 7, len(essays)), essays["rater_a"])
                     data = np.vstack([essays["rater_a"], essays["rater_b"], rater_c]).astype(float)
                     print(krippendorff.alpha(reliability_data=data, level_of_measurement="ordinal"))
                     """#,
                     r: #"""
                     set.seed(2)
                     rater_c <- ifelse(runif(nrow(essays)) < 0.4, sample(1:6, nrow(essays), replace = TRUE), essays$rater_a)
                     kripp.alpha(rbind(essays$rater_a, essays$rater_b, rater_c), method = "ordinal")
                     """#,
                     answer: "α drops noticeably. One unreliable rater pulls down the whole team's estimate — a reason to retrain or recalibrate raters before the main rating."),
            practice("Missing ratings",
                     "Set 20 of rater B's scores to missing and recompute Krippendorff's α. Does it still work?",
                     python: #"""
                     b = essays["rater_b"].astype(float).to_numpy().copy()
                     b[:20] = np.nan
                     print(krippendorff.alpha(reliability_data=np.vstack([essays["rater_a"], b]), level_of_measurement="ordinal"))
                     """#,
                     r: #"""
                     b <- essays$rater_b; b[1:20] <- NA
                     kripp.alpha(rbind(essays$rater_a, b), method = "ordinal")
                     """#,
                     answer: "Yes — Krippendorff's α uses whatever pairs are available. Cohen's κ would require dropping those essays."),
        ],
        "multinomial": [
            practice("Is biking growing?",
                     "Plot the share of each mode by week. Which mode grows?",
                     python: #"""
                     import matplotlib.pyplot as plt
                     shares = pd.crosstab(commutes["week"], commutes["mode"], normalize="index")
                     shares.plot(marker="o", color=["#009E73", "#0072B2", "#999999", "#E69F00"])
                     plt.ylabel("Share of commutes"); plt.show()
                     """#,
                     r: #"""
                     commutes |> count(week, mode) |> group_by(week) |> mutate(share = n / sum(n)) |>
                       ggplot(aes(week, share, colour = mode)) + geom_line() + geom_point() + theme_classic()
                     """#,
                     answer: "Biking roughly doubles over the ten weeks (from about 10% to about 25%), mostly at the expense of bus and car."),
            practice("A cluster-bootstrap CI for a share",
                     "Get a 95% CI for the overall share of bike commutes, resampling people rather than weeks.",
                     hint: "Reuse the cluster-bootstrap code from *Bootstrap & resampling*.",
                     answer: "Around 15–20% overall, with an interval several points wide. A naive interval treating 1,200 commutes as independent would be much narrower, because people repeat their choices."),
        ],
        "latent-class": [
            practice("Under- and over-extraction",
                     "Inspect the 2-class and 4-class profiles. Which types merge in the 2-class model, and what happens with 4?",
                     python: #"""
                     for k in [2, 4]:
                         m = StepMix(n_components=k, measurement="binary", n_init=10, random_state=42, verbose=0).fit(X)
                         print(k, "\n", habits.assign(c=m.predict(X)).groupby("c")[strategies].mean().round(2))
                     """#,
                     r: #"""
                     fits[[2]]$probs
                     fits[[4]]$P
                     """#,
                     answer: "With 2 classes, the active and social types tend to merge into one “engaged” class. With 4, one type splits into two near-identical halves or a tiny class appears — and BIC gets worse."),
            practice("Classification quality",
                     "For each assigned class, compute the average posterior probability of belonging to that class.",
                     python: #"""
                     assigned = post.argmax(axis=1)
                     for k in range(post.shape[1]):
                         print(k + 1, post[assigned == k, k].mean().round(3))
                     """#,
                     r: #"""
                     sapply(1:ncol(post), function(k) mean(post[best$predclass == k, k]))
                     """#,
                     answer: "Values mostly above .80 — clear assignment — and lowest for the classes whose profiles overlap most."),
            practice("GPA by class, naively",
                     "Compare mean GPA across the most-likely classes. Why is this only an approximation?",
                     python: #"""
                     print(habits.groupby("class")["gpa"].mean().round(2))
                     """#,
                     r: #"""
                     tapply(habits$gpa, best$predclass, mean)
                     """#,
                     answer: "Active practice has the highest GPA (about 3.4), passive review the lowest (about 2.8). Assigning people to their most likely class ignores classification error, which biases these comparisons toward each other; BCH/DCON in Mplus correct for it."),
        ],
        "latent-profile": [
            practice("Standardize first?",
                     "Refit the 3-profile model on z-scored indicators. Does the classification change?",
                     python: #"""
                     Z = (X - X.mean(axis=0)) / X.std(axis=0)
                     gz = GaussianMixture(n_components=3, covariance_type="diag", n_init=20, random_state=1).fit(Z)
                     print(pd.crosstab(gz.predict(Z), lpa["profile"]))
                     """#,
                     r: #"""
                     indicators |> mutate(across(everything(), ~ as.numeric(scale(.x)))) |>
                       estimate_profiles(3, variances = "equal", covariances = "zero") |>
                       get_data() |> with(table(Class, lpa$true_profile))
                     """#,
                     answer: "Nearly identical assignments (up to label order). Standardizing mainly helps with plotting and interpretation."),
            practice("A covariate that shouldn't matter",
                     "Does age differ across the estimated profiles?",
                     python: #"""
                     print(lpa.groupby("profile")["age"].mean().round(1))
                     print(pg.anova(data=lpa, dv="age", between="profile"))
                     """#,
                     r: #"""
                     get_data(best) |> mutate(age = lpa$age) |> group_by(Class) |> summarise(mean_age = mean(age))
                     """#,
                     answer: "No meaningful difference — age was generated independently of profile. In Mplus you would test this with `AUXILIARY = age (R3STEP);`."),
        ],
        "mplus-mixtures": [
            practice("Write an R3STEP input",
                     "Write the Mplus input that tests whether `age` predicts membership in the 3-profile solution.",
                     mplus: #"""
                     TITLE:    LPA, 3 profiles, age as a predictor of membership;
                     DATA:     FILE = profiles.dat;
                     VARIABLE: NAMES = id wellbe stress support sleep age burnout tprof;
                               USEVARIABLES = wellbe stress support sleep;
                               CLASSES = c(3);
                               IDVARIABLE = id;
                               AUXILIARY = age (R3STEP);
                     ANALYSIS: TYPE = MIXTURE;
                               STARTS = 500 100;
                     """#,
                     answer: "The output reports multinomial logistic coefficients for age, comparing each profile with a reference profile. In the generated data they're near zero."),
            practice("Read the saved posterior probabilities",
                     "After running a model with `SAVE = CPROBABILITIES`, load the saved file and cross-tabulate the most likely class with `tprof`.",
                     python: #"""
                     # Column order is listed under "SAVEDATA INFORMATION" in the .out file:
                     # the analysis variables, any auxiliary variables, the ID, CPROB1–CPROB3, then C
                     post = pd.read_csv("lpa3_post.dat", sep=r"\s+", header=None)
                     post.columns = ["wellbe", "stress", "support", "sleep", "id", "cprob1", "cprob2", "cprob3", "c"]
                     print(post.head())
                     """#,
                     r: #"""
                     fit <- MplusAutomation::readModels("lpa_3.out")
                     head(fit$savedata)   # MplusAutomation reads the column names for you
                     """#,
                     answer: "Each row carries its posterior probabilities and most likely class. The classes line up with the true profiles, up to label order. MplusAutomation saves you from reading column orders by hand."),
            practice("Choose a structure",
                     "Fit 3-profile models with equal and with class-varying variances. Which has the lower BIC?",
                     answer: "The equal-variance model usually wins: the data were generated with equal within-profile SDs (0.7), so freeing variances adds parameters without improving fit enough."),
        ],
        "clustering": [
            practice("Nearest neighbor",
                     "Embed the new sentence “Whisk the cream until it forms soft peaks.” and find the most similar existing text.",
                     python: #"""
                     new = model.encode(["Whisk the cream until it forms soft peaks."], normalize_embeddings=True)
                     sims = cosine_similarity(new, emb)[0]
                     print(texts[sims.argmax()], sims.max().round(2))
                     """#,
                     answer: "It matches one of the cooking sentences, with a cosine similarity well above its similarity to the weather or exercise sentences."),
            practice("TF-IDF as a baseline",
                     "Cluster TF-IDF vectors of the same texts with k = 3 and compare with the embedding clusters using the ARI.",
                     python: #"""
                     from sklearn.feature_extraction.text import TfidfVectorizer
                     from sklearn.metrics import adjusted_rand_score
                     tfidf = TfidfVectorizer().fit_transform(texts)
                     tf_labels = KMeans(n_clusters=3, n_init=10, random_state=0).fit_predict(tfidf)
                     print(adjusted_rand_score(labels, tf_labels))
                     """#,
                     answer: "Usually lower agreement: TF-IDF groups texts by shared words (“the”, “before”), while embeddings group them by meaning."),
        ],
        "keyness": [
            practice("Normalized frequencies",
                     "Compute each word's frequency per 1,000 words in each group and compare the ranking with the z-scores.",
                     python: #"""
                     per_k = counts[["a", "b"]] / counts[["a", "b"]].sum() * 1000
                     print(per_k.assign(z=counts["z"]).sort_values("z", ascending=False).round(1).head(10))
                     """#,
                     answer: "Raw per-1,000 differences overstate words used only once or twice; the weighted z-scores pull those toward 0 and favor words that are both frequent and distinctive."),
            practice("Remove stop words",
                     "Drop common function words (what, how, do, i, a, an, the, for, of, to, is, that, from) and recompute. What changes at the top of each list?",
                     answer: "Content words (“easy”, “quick”, “simple” vs. “ratio”, “emulsion”, “technique”, “searing”) dominate. Decide on stop-word handling before looking at results."),
        ],
        "plotting-basics": [
            practice("Restyle with a theme",
                     "Recreate the lesson's scatterplot with a minimal theme and larger axis text.",
                     python: #"""
                     sns.set_theme(style="whitegrid", font_scale=1.2)
                     sns.scatterplot(data=survey, x="rumination", y="anxiety", hue="region",
                                     palette={"urban": "#0072B2", "rural": "#E69F00"}, alpha=0.6)
                     plt.show()
                     """#,
                     r: #"""
                     ggplot(survey, aes(rumination, anxiety, colour = region)) +
                       geom_point(alpha = 0.6) +
                       scale_colour_manual(values = c(urban = "#0072B2", rural = "#E69F00")) +
                       theme_minimal(base_size = 14)
                     """#,
                     answer: "The same data with lighter gridlines and larger text — themes change the look, not the content."),
        ],
        "plotting-groups": [
            practice("Condition means with CIs",
                     "Plot the mean acceptability rating (with 95% CI) for each of the four conditions in judgments.csv, over jittered raw ratings.",
                     python: #"""
                     judgments = pd.read_csv("judgments.csv")
                     judgments["condition"] = judgments["structure"] + " / " + judgments["distance"]
                     sns.stripplot(data=judgments, x="condition", y="rating", alpha=0.08, jitter=0.25, color="0.5")
                     sns.pointplot(data=judgments, x="condition", y="rating", errorbar=("ci", 95), color="black", linestyle="none")
                     plt.show()
                     """#,
                     r: #"""
                     judgments <- read_csv("judgments.csv") |> mutate(condition = paste(structure, distance, sep = " / "))
                     ggplot(judgments, aes(condition, rating)) +
                       geom_jitter(width = 0.25, height = 0.15, alpha = 0.08) +
                       stat_summary(fun.data = mean_se, fun.args = list(mult = 1.96), geom = "pointrange") +
                       theme_classic()
                     """#,
                     answer: "Complex / long is clearly lowest. (These CIs ignore clustering by participant and item, so they're too narrow — fine for a first look, not for inference.)"),
        ],
        "plotting-relationships": [
            practice("Linear vs. smooth",
                     "Overlay a loess smoother and a linear fit for anxiety on rumination. Is the relationship linear?",
                     python: #"""
                     sns.regplot(data=survey, x="rumination", y="anxiety", lowess=True, scatter_kws={"alpha": 0.3},
                                 line_kws={"color": "#D55E00"})
                     sns.regplot(data=survey, x="rumination", y="anxiety", scatter=False, line_kws={"color": "#0072B2"})
                     plt.show()
                     """#,
                     r: #"""
                     ggplot(survey, aes(rumination, anxiety)) +
                       geom_point(alpha = 0.3) +
                       geom_smooth(method = "loess", colour = "#D55E00", se = FALSE) +
                       geom_smooth(method = "lm", colour = "#0072B2") +
                       theme_classic()
                     """#,
                     answer: "The two lines nearly coincide — the relationship is approximately linear, with slight flattening at the ends from scale clipping."),
        ],
        "plotting-models": [
            practice("Predicted probability curve",
                     "Plot the predicted probability of `high_anxiety` (anxiety > 5) across the range of rumination, with a 95% CI band.",
                     python: #"""
                     survey["high_anxiety"] = (survey["anxiety"] > 5).astype(int)
                     m = smf.logit("high_anxiety ~ rumination", data=survey).fit(disp=False)
                     grid = pd.DataFrame({"rumination": np.linspace(1, 7, 100)})
                     pred = m.get_prediction(grid).summary_frame()
                     plt.plot(grid["rumination"], pred["predicted"], color="#0072B2")
                     plt.fill_between(grid["rumination"], pred["ci_lower"], pred["ci_upper"], color="#0072B2", alpha=0.15)
                     plt.xlabel("Rumination"); plt.ylabel("P(high anxiety)"); plt.show()
                     """#,
                     r: #"""
                     survey$high_anxiety <- as.integer(survey$anxiety > 5)
                     m <- glm(high_anxiety ~ rumination, data = survey, family = binomial)
                     grid <- data.frame(rumination = seq(1, 7, length.out = 100))
                     p <- predict(m, grid, type = "link", se.fit = TRUE)
                     grid$fit <- plogis(p$fit)
                     grid$lo <- plogis(p$fit - 1.96 * p$se.fit); grid$hi <- plogis(p$fit + 1.96 * p$se.fit)
                     ggplot(grid, aes(rumination, fit)) +
                       geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#0072B2", alpha = 0.15) +
                       geom_line(colour = "#0072B2") +
                       labs(y = "P(high anxiety)") + theme_classic()
                     """#,
                     answer: "An S-shaped curve rising from near 0 at low rumination. The CI is widest at high rumination, where there are fewer people."),
        ],
        "publication-figures": [
            practice("Two sizes, one figure",
                     "Export the same plot at single-column (3.5 in) and double-column (7 in) width. Which settings must change so the text stays readable?",
                     answer: "Keep the font size fixed in points and change only the width and height. If you scale the image afterwards instead, the text shrinks or grows with it."),
        ],
    ]
}

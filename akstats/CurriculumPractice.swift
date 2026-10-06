import Foundation

// MARK: - Practice labs (OpenIntro data) — each lab sits at the end of the unit it practices

extension Curriculum {
    /// The final review covers methods from every unit, so it comes after the advanced units.
    static let capstoneReview = Unit(
        id: "capstone-review", number: 12, title: "Capstone review", level: .advanced,
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

                hsb2 = pd.read_csv("https://www.openintro.org/data/csv/hsb2.csv")
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
                    hsb2.groupby("gender")["read"].agg(["count", "mean", "std"]).round(2)
                    """#,
                    r: #"""
                    hsb2 |> group_by(gender) |> summarise(n = n(), mean = mean(read), sd = sd(read))
                    """#
                ),
                answer: "There are slightly more female than male students; mean reading scores are close (around 52) with SDs near 10."
            )),
            .exercise(Exercise(
                title: "2 · Two groups",
                prompt: "Do math scores differ by gender? Run a Welch t-test and report Cohen's d.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    pg.ttest(hsb2.loc[hsb2["gender"] == "female", "math"],
                             hsb2.loc[hsb2["gender"] == "male", "math"])
                    """#,
                    r: #"""
                    t.test(math ~ gender, data = hsb2)
                    effectsize::cohens_d(math ~ gender, data = hsb2)
                    """#
                ),
                answer: "The difference is small and not significant (|d| < 0.1). Report it anyway — null results are informative."
            )),
            .exercise(Exercise(
                title: "3 · Three groups",
                prompt: "Do math scores differ across program types? Run a one-way ANOVA with Tukey post-hoc tests.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    print(pg.anova(data=hsb2, dv="math", between="prog", detailed=True))
                    print(pg.pairwise_tukey(data=hsb2, dv="math", between="prog"))
                    """#,
                    r: #"""
                    fit <- aov(math ~ prog, data = hsb2)
                    summary(fit)
                    TukeyHSD(fit)
                    """#
                ),
                answer: "There's a clear program effect: students in the academic program score highest, and both the general and vocational programs are significantly lower than academic."
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
                    test
                    test$expected
                    """#
                ),
                answer: "Private-school students lean toward higher SES, but with only 32 private-school students some expected counts are small — check them and interpret cautiously."
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

                resume = pd.read_csv("https://www.openintro.org/data/csv/resume.csv")
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
                    print(resume["received_callback"].mean())
                    print(resume.groupby("race")["received_callback"].mean())
                    """#,
                    r: #"""
                    mean(resume$received_callback)
                    resume |> group_by(race) |> summarise(rate = mean(received_callback), n = n())
                    """#
                ),
                answer: "About 8% overall: roughly 9.7% for white-sounding names vs. 6.4% for Black-sounding names."
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
                    print(table, "\nchi2 =", round(chi2, 2), "p =", p)
                    print("OR (white vs. black):", odds["white"] / odds["black"])
                    """#,
                    r: #"""
                    tab <- table(resume$race, resume$received_callback)
                    chisq.test(tab)
                    fisher.test(tab)$estimate   # odds ratio: white relative to black (rows are black, white)
                    """#
                ),
                answer: "χ² is significant (p < .001). White-sounding names have about 1.5 times the odds of a callback."
            )),
            .exercise(Exercise(
                title: "3 · Logistic regression",
                prompt: "Fit `received_callback ~ race + gender + years_experience` and report odds ratios with 95% CIs.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    m = smf.logit("received_callback ~ C(race) + C(gender) + years_experience", data=resume).fit()
                    print(pd.concat([np.exp(m.params), np.exp(m.conf_int())], axis=1).round(3))
                    """#,
                    r: #"""
                    m <- glm(received_callback ~ race + gender + years_experience, data = resume, family = binomial)
                    exp(cbind(OR = coef(m), confint(m)))
                    """#
                ),
                answer: "The race effect stays about the same after adjustment (OR ≈ 1.5 for white-sounding names). Each additional year of experience modestly increases the odds of a callback."
            )),
            .exercise(Exercise(
                title: "4 · Interaction",
                prompt: "Does the race gap differ by gender? Add `race * gender`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    smf.logit("received_callback ~ C(race) * C(gender) + years_experience", data=resume).fit().summary()
                    """#,
                    r: #"""
                    summary(glm(received_callback ~ race * gender + years_experience, data = resume, family = binomial))
                    """#
                ),
                answer: "The interaction isn't significant: there's no strong evidence that the race gap differs between female and male names, though this design has limited power for interactions."
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

                evals = pd.read_csv("https://www.openintro.org/data/csv/evals.csv")
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
                    print(evals["score"].corr(evals["bty_avg"]))
                    """#,
                    r: #"""
                    ggplot(evals, aes(bty_avg, score)) +
                      geom_jitter(alpha = 0.4) +
                      geom_smooth(method = "lm", colour = "#0072B2") +
                      theme_classic()
                    cor(evals$score, evals$bty_avg)
                    """#
                ),
                answer: "A weak positive correlation (r ≈ .19). The jitter matters: without it, many points overlap because scores are rounded."
            )),
            .exercise(Exercise(
                title: "2 · Simple regression",
                prompt: "Fit `score ~ bty_avg`. Interpret the slope and R².",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    m1 = smf.ols("score ~ bty_avg", data=evals).fit()
                    print(m1.params, m1.rsquared)
                    """#,
                    r: #"""
                    m1 <- lm(score ~ bty_avg, data = evals)
                    summary(m1)
                    """#
                ),
                answer: "Each one-point increase in rated appearance predicts about 0.07 points higher evaluation; R² ≈ .035, so appearance explains only a small share of the variation."
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
                    print("slope for male professors:", m2b.params["bty_avg"])
                    """#,
                    r: #"""
                    m2 <- lm(score ~ bty_avg * gender, data = evals)
                    summary(m2)
                    m2b <- lm(score ~ bty_avg * relevel(gender, ref = "male"), data = evals)
                    coef(m2b)["bty_avg"]   # slope for male professors
                    """#
                ),
                answer: "The slope is somewhat steeper for male professors; the interaction is borderline. Probing it by switching the reference level is the categorical version of the simple-slopes trick."
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
        ]
    )
}

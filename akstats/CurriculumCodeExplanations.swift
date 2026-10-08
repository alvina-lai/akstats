import Foundation

/// A plain-language note shown with each lesson-level code sample: what the code does and what to look for.
/// Keyed by "lesson ID|caption" (captions repeat across lessons, e.g. "Load the data").
extension Curriculum {
    static let codeExplanations: [String: String] = [
        "vs-code|A first script with cells — paste into analysis.py / analysis.R":
            "A complete, tiny script to check your setup. It loads a package, builds a four-row table by hand, and prints the mean score per group. Each `# %%` line starts a **cell** you can run on its own. If you see a mean of 4 for group a and 5 for group b, everything is installed correctly.",
        "python-vs-r|The same analysis — notice the structure is identical":
            "One small analysis in both languages, so you can see they follow the same three steps: **read** the survey, **filter and summarize** (mean anxiety by region among people 25 and older), then **fit a model** (anxiety predicted by rumination and age). Switch languages above and compare line by line — only the spelling changes.",
        "python-basics|Core Python":
            "A tour of the Python you'll actually use: storing numbers and text in variables, **lists** (ordered values, counted from 0), **dictionaries** (labelled values), a small function that computes a z-score, and a loop that prints each score. Run it line by line; the comments show what each line returns.",
        "python-basics|Working with a DataFrame":
            "The everyday **pandas** moves on a real dataset: look at the first rows and the size, pick columns, keep rows that meet a condition (`&` means *and*), add a new column (a z-scored anxiety), and summarize by group. Almost every later lesson starts with some combination of these lines.",
        "r-basics|Core R":
            "A tour of base R: assigning values with `<-`, **vectors** (counted from 1), why `mean()` returns `NA` when a value is missing until you add `na.rm = TRUE`, a small z-score function, and `?` for help. Notice that arithmetic like `scores * 10` works on the whole vector at once.",
        "r-basics|Data frames with the tidyverse":
            "The everyday **tidyverse** moves on a real dataset: `glimpse()` and `summary()` to look, `select()` to pick columns, `filter()` to keep rows, `mutate()` to add a column, and `group_by()` + `summarise()` for group summaries. The pipe `|>` passes the result of one step into the next — read it as “and then”.",
        "practice-data|generate_data — survey, diary, classroom, essays, and Stroop data":
            "The first of four data-generating scripts. It invents participants with a fixed random seed (so everyone gets the same files), builds each variable from the **built-in truths** listed in the comments (for example, social media use → rumination → anxiety), and saves six CSV files. You don't need to understand every line — run the whole file once, then check the CSVs appear.",
        "practice-data|generate_more_data — judgments.csv, commutes.csv, habits.csv, profiles.csv":
            "The second script: a sentence-rating experiment (participants × items in a Latin square), ten weeks of commute choices where people tend to repeat last week's mode, and two datasets with hidden groups for the latent-class and latent-profile lessons. Run it once in the same folder as the first.",
        "practice-data|generate_extra_data — missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv":
            "The third script, for the later lessons: survey answers that go missing more often for stressed people, filler-word counts in interviews, a weighted poll, a tutoring study where motivated students choose tutoring, and reading scores over five waves. Each dataset hides a known answer — the keyPoint below lists them.",
        "practice-data|generate_simulations — two practice simulations (data for the “Practice simulation” exercises)":
            "The fourth script builds the two **practice simulations**: a political parasocial-attachment study (survey, credibility task, interviews, intervention) and a study of how people ask chatbots about court cases (session transcripts, chat logs, the coding sheet, both coders' sheets, a framework matrix, and repeated chatbot responses). It is long because it imitates a real research pipeline; run it once and use the files.",
        "practice-data|selfcheck — save once in the same folder; every exercise's Self-check uses it":
            "A small helper, not an analysis. It defines one function, `check()`, which compares a result you stored with the correct answer (allowing a small rounding tolerance) and prints ✓ or ✗ with a hint. Save it as `selfcheck.py` / `selfcheck.R` next to your data; every **Self-check** script loads it.",
        "reading-output|Fit a regression and print its summary":
            "Fits one regression (anxiety predicted by rumination and age) and prints the full summary table, so you have real output to decode. Don't worry about the statistics yet — match each number in the printout to the glossary below: coefficients, standard errors, *t*, *p*, and *R*².",
        "measurement|Tell your software what kind of variable each column is":
            "Builds a four-person table and declares each column's **level of measurement**: language becomes an unordered category (nominal), education an ordered category (HS < BA < MA < PhD), and reaction time stays numeric. The printed types confirm it — software then treats each one correctly in plots and models.",
        "toolkit|Install once, then load at the top of every script":
            "The packages this course uses. Installing (in a terminal, or `install.packages()` in R) happens **once** per computer; loading (`import` / `library()`) happens at the top of **every** script. If a later lesson says a package isn't found, come back here.",
        "toolkit|The same regression, written both ways":
            "One regression — anxiety predicted by rumination and age — in Python and R. The formula `anxiety ~ rumination + age` is identical in both: outcome on the left of `~`, predictors on the right. Once you can read this line, most models in the course will look familiar.",
        "tidy-data|Read, apply exclusions, and reshape Stroop data from wide to long":
            "A typical cleaning pipeline: read the file, drop participants who are under 18 or failed the attention check, then **reshape** from wide (one row per person, one column per condition) to long (one row per person × condition). Long format is what plots and models expect; check the new `condition` and `rt` columns.",
        "central-tendency|Descriptive statistics, overall and by condition":
            "Recreates the long Stroop data, then computes the mean, median, SD, and quartiles of reaction time, overall and by condition. Compare the mean with the median: for right-skewed reaction times the mean sits higher, pulled up by the slow tail.",
        "visualizing|Histograms and boxplots with raw data points":
            "Two essential plots of the Stroop reaction times: a **histogram** by condition (with a smoothed density curve) to see the shape and skew, and a **boxplot** with every participant's point drawn on top, so readers see the data and not just the summary. Look for the long right tail and the shift between conditions.",
        "normal-distribution|Standardize, check normality visually, and log-transform":
            "Turns reaction times into **z-scores** (SD units), draws a **Q–Q plot** to check normality (points bending away from the line at the top mean a long right tail), and log-transforms the times, which usually straightens that tail. Re-draw the Q–Q plot with `log_rt` to see the difference.",
        "probability|Bayes' rule for a screening questionnaire — computed, then simulated":
            "Works out the chance someone really has the disorder after screening positive — first with **Bayes' rule**, then by simulating 100,000 people and counting. Both give about .49: with a 10% base rate, half of the positives are false alarms.",
        "probability|Binomial and Poisson probabilities":
            "Probabilities for counts. The **binomial** part asks how likely 15+ correct answers out of 20 are by pure guessing; the **Poisson** part asks how likely zero (or five-plus) speech errors are in 10 minutes for a speaker who averages 2.5. `pmf` gives one exact value; `sf` gives “more than”.",
        "standard-error|Simulate the sampling distribution, then compute a 95% CI":
            "First simulates 1,000 studies of 30 people and shows that the spread of their means matches the **standard error** formula (15 / √30 ≈ 2.74). Then computes a 95% **confidence interval** for the mean reaction time in the real data. The interval is the range of population means consistent with the sample.",
        "hypothesis-testing|Build a p-value from scratch with a permutation test":
            "Computes a *p*-value without any formula: it records the real difference between active-learning and lecture post-test scores, then shuffles the group labels 10,000 times to see how big differences get **by chance alone**. The *p*-value is the share of shuffled differences at least as large as the real one.",
        "bootstrap|A 95% bootstrap CI for the median":
            "There's no simple formula for the uncertainty of a median, so the **bootstrap** makes one: resample the anxiety scores with replacement 10,000 times, take each resample's median, and use the middle 95% of those medians as the interval. SciPy's built-in function at the end should give nearly the same answer.",
        "bootstrap|Share of long workdays (> 9 hours): naive vs. cluster-bootstrap CI":
            "Estimates how often people work more than 9 hours, two ways. The naive interval treats all 1,400 days as independent; the **cluster bootstrap** resamples whole *people* (with all 14 of their days). The cluster interval is wider — the honest one, because days from the same person are alike.",
        "effect-sizes|Compute Cohen's d and plan your sample size":
            "Two steps of study planning: **Cohen's d** for active learning vs. lecture (the difference in SD units), then a **power analysis** asking how many people per group you'd need to detect d = 0.4 with 80% power. The answer, about 100 per group, is often larger than people expect.",
        "sample-planning|Power for a continuous interaction":
            "Estimates power by simulation: invent data with a small interaction (b = 0.15), fit the model, record whether the interaction is significant, and repeat 1,000 times at each sample size. The share of significant results is the power — see how many people you need before it reaches .80.",
        "sample-planning|See the inflation, then plan proper boundaries":
            "Simulates 5,000 studies with **no** real effect that peek at the data halfway and again at the end. Testing at .05 both times gives far more than 5% false positives; Pocock and O'Brien–Fleming boundaries spend the α across the two looks and bring the rate back to about 5%.",
        "t-tests|Independent and paired t-tests":
            "Three t-tests: a **Welch** test comparing two separate groups (active learning vs. lecture), a **paired** test comparing the same people in two Stroop conditions, and pingouin's version, which adds the CI, Cohen's d, and power in one table. Use paired whenever the same people appear in both conditions.",
        "anova|One-way, post-hoc, and mixed ANOVA":
            "A full ANOVA workflow on the classroom data: a **one-way** test of whether post-test scores differ across three teaching methods, **Tukey** post-hoc comparisons to see which pairs differ, a **two-way** method × school model, and a **mixed** ANOVA for pre/post change by method. The time × method interaction is the key result.",
        "multiple-comparisons|How quickly false positives pile up: 20 tests per study, no real effects":
            "Simulates 2,000 studies that each test 20 outcomes where nothing is really going on. About 64% of the studies still find at least one “significant” result — the reason corrections exist.",
        "multiple-comparisons|Correcting a family of eight correlations with anxiety":
            "Tests eight correlations with anxiety, then adjusts the *p*-values three ways — **Bonferroni**, **Holm**, and **Benjamini–Hochberg** (false discovery rate) — side by side. Compare the columns: the same results survive or fail depending on which error rate you choose to control.",
        "multiple-comparisons|Post-hoc pairwise comparisons with Holm's correction":
            "Compares every pair of teaching methods in one call, with Holm-adjusted *p*-values. This is the usual follow-up after a significant one-way ANOVA.",
        "ancova|Does active learning raise post-test scores more than lecture?":
            "An **ANCOVA**: post-test scores by teaching method, adjusting for each student's pretest and school. The method coefficients are adjusted differences from lecture. The second model checks an assumption — that the pretest predicts the post-test equally in every group (a large *p* means it does).",
        "ancova|Change what the coefficients compare":
            "Same ANCOVA, three ways of reading it. Changing the **reference group** to flipped makes each method coefficient a difference from flipped; **sum coding** compares each method with the average of all methods. The last lines turn the two-sided *p* for active vs. lecture into a **one-tailed** *p* — only legitimate if you predicted that direction in advance.",
        "repeated-measures|A 2 × 2 repeated-measures ANOVA on acceptability ratings":
            "Every participant rated sentences in all four structure × distance conditions. The code first averages each person's ratings within each condition (repeated-measures ANOVA needs exactly one value per person per cell), then tests the two main effects and their interaction. Check the sphericity-corrected *p* if your factor has more than two levels.",
        "repeated-measures|A mixed ANOVA: pre/post (within) × teaching method (between)":
            "Reshapes the classroom data so each student has a pretest and a post-test row, then fits a **mixed ANOVA**: time is within-subject, teaching method between-subject. The **Interaction** row is the one that answers the research question — did scores improve more under some methods than others?",
        "chi-square|Chi-square test of independence with Cramér's V: is education level associated with region?":
            "Cross-tabulates region by education level, tests whether the two are associated with a **chi-square test**, and reports **Cramér's V** as the effect size (0 = no association, 1 = perfect). The `expected` table it returns is worth checking too: the test is unreliable if many expected counts are below 5.",
        "non-parametric|Rank-based tests":
            "The rank-based versions of three common tests, for when data are skewed or ordinal: **Mann–Whitney** for two independent groups, **Wilcoxon signed-rank** for the same people measured twice, and **Kruskal–Wallis** for three or more groups. They compare ranks rather than means, so outliers matter less.",
        "equivalence|Is anxiety equivalent in urban and rural respondents? (bounds ±0.3 points)":
            "An **equivalence test (TOST)**: two one-sided tests ask whether the urban–rural difference is above −0.3 *and* below +0.3 — the smallest difference you'd care about, chosen beforehand. A small TOST *p* means “equivalent”. The 90% CI gives the same decision visually, and the ordinary test at the end shows why “not significant” isn't the same as “equivalent”.",
        "lab-hsb2|Load the data":
            "Loads the real **hsb2** dataset straight from OpenIntro's website (Python needs a simple user-agent header for that site; R uses the `openintro` package) and shows the first rows. Every step of the lab below uses this `hsb2` table.",
        "correlation|Pairwise correlations and a correlation matrix":
            "Four ways to look at how social media use and anxiety move together: **Pearson's r** (linear), **Spearman's ρ** (rank-based, for monotonic relationships), pingouin's version with a 95% CI and power, and a correlation **matrix** for several variables at once. Pearson and Spearman should be similar here; a big gap would suggest outliers or curvature.",
        "between-within|Pooled, between-person, and within-person correlations":
            "The same two variables give three different answers depending on the level you look at. **Pooled** treats all 1,400 days as independent (misleading); **between-person** correlates people's averages (people who usually work more are happier); **within-person** asks whether a person is less happy on days they work *more than usual* — here it's the opposite sign. The two-stage version averages one correlation per person.",
        "between-within|Both components in one multilevel model":
            "Splits work hours into each person's **average** (between) and their **day-to-day deviation** from it (within), then puts both in one mixed model with a random intercept and slope per person. The two coefficients separate “people who work more” from “days when someone works more” in a single analysis.",
        "simple-regression|Fit, inspect, and diagnose a regression":
            "Fits anxiety on rumination, prints the full summary, then pulls out the pieces you'll report: the intercept and slope, their 95% CIs, and *R*² (the share of variance explained). The slope is how much anxiety rises, on average, for each one-point increase in rumination.",
        "multiple-regression|Covariates, interactions, and model comparison":
            "Centers age (so other coefficients are interpreted at the average age), fits rumination with age and region as covariates, then adds a rumination × age **interaction** and compares the two models with an F-test. A small *p* means the effect of rumination depends on age.",
        "comparing-predictors|Which predicts rumination better: social media use or phone checking?":
            "Puts every continuous variable in SD units so coefficients are **standardized (β)** and comparable, fits each predictor alone and both together, and measures each one's **unique contribution** (ΔR² when added last, with an F-test). Because the two predictors are correlated, their joint model matters more than either alone; check the VIFs too.",
        "regression-diagnostics|Residual plots, leverage, and influence":
            "Checks a regression's assumptions with pictures: **residuals vs. fitted** (look for curves or a funnel) and a **Q–Q plot** of residuals (look for points leaving the line). Then it lists the five most **influential** cases by Cook's distance, alongside leverage and studentized residuals, with the common 4/*n* cut-off printed for comparison.",
        "regression-diagnostics|Testing for heteroskedasticity, and robust (HC3) standard errors":
            "Runs the **Breusch–Pagan** test for unequal residual spread, then refits the model with **HC3 robust standard errors** and prints both sets side by side. If the SEs barely change, heteroskedasticity isn't affecting your conclusions; if they grow, report the robust ones.",
        "logistic-regression|Fit a logistic model and convert to odds ratios":
            "Turns anxiety into a yes/no outcome (5 or more on the 1–7 scale), fits a **logistic regression**, and exponentiates the coefficients to get **odds ratios** with 95% CIs. An odds ratio of 1.8 for rumination means each extra point of rumination multiplies the odds of high anxiety by 1.8.",
        "lab-evals|Load the data":
            "Loads the real **evals** dataset (course evaluations from the University of Texas at Austin) from OpenIntro and summarizes the columns the lab uses: evaluation score, beauty rating, gender, age, rank, and professor ID. Note `prof_id`: many courses share a professor, which matters later.",
        "lab-resume|Load the data":
            "Loads the real **résumé** field-experiment data from OpenIntro — thousands of fictitious résumés with randomly assigned names — and shows the key columns: race and gender signalled by the name, years of experience, and whether the résumé got a callback.",
        "plotting-basics|The same scatterplot, two ways":
            "A publication-ready scatterplot of rumination vs. anxiety, coloured by region with a **colorblind-safe** palette, semi-transparent points (so overlaps show density), labelled axes with units, and the top and right borders removed. Switch languages to compare seaborn/matplotlib with ggplot2.",
        "plotting-basics|Small multiples: one panel per group":
            "Instead of colours, draws one panel per region with shared axes — **small multiples**. They're easier to read than overlapping colours when groups overlap a lot.",
        "plotting-groups|Raw points + mean and 95% CI per teaching method":
            "Shows every student's post-test score as a faint jittered point, with the group mean and 95% CI drawn on top. This beats a bar chart of means: readers see the spread, the sample size, and any outliers along with the summary.",
        "plotting-groups|Within-person change: one line per student":
            "One thin grey line per student from pretest to post-test, in a separate panel per teaching method, with the average change in blue. The individual lines show how consistent the improvement is; the bold line shows its average size.",
        "plotting-relationships|Scatterplot with a regression line and 95% band":
            "Draws rumination against anxiety with a fitted regression line and its 95% confidence band. Points are grey and semi-transparent so the line stays the focus. A band that's narrow in the middle and wider at the ends is normal — there's less data at the extremes.",
        "plotting-relationships|Simple-slopes plot for a continuous interaction":
            "Visualizes a social media × mindfulness interaction: it fits the model, then draws predicted rumination against social media use at **low, average, and high mindfulness** (−1 SD, mean, +1 SD), each with a 95% band and a direct label. Lines that fan out show the interaction — the slope depends on mindfulness.",
        "plotting-relationships|Correlation heatmap with a diverging scale":
            "Shows a correlation matrix as a heatmap. The **diverging** palette is centred on 0 (white), with red for negative and blue for positive, fixed to the full −1 to +1 range so colours mean the same thing in every plot. The numbers are printed in each cell too.",
        "plotting-models|Coefficient (forest) plot with 95% CIs":
            "Fits a regression on standardized variables and plots each **β** with its 95% CI as a dot and whiskers, with a dashed line at zero. Coefficients whose whiskers cross zero aren't distinguishable from no effect; comparing dot positions shows which predictors matter most.",
        "plotting-models|Ordinal outcomes: stacked distribution bars (diverging colors)":
            "For 1–7 ratings, shows the **whole distribution** in each condition as a stacked bar, with a diverging palette (reds for low ratings, grey for the midpoint, blues for high). Better than plotting means for ordinal data: you can see where ratings pile up.",
        "plotting-models|Transition matrix as a heatmap (sequential color)":
            "Pairs each week's commute mode with the next week's and shows the share of transitions as a heatmap. The strong diagonal is **habit** — people mostly repeat last week's mode. A **sequential** palette (light to dark blue) suits proportions that run from 0 to 1.",
        "publication-figures|A reusable style and high-resolution export":
            "A one-time setup for journal figures: a colorblind-safe palette (Okabe–Ito), a clean theme without top and right borders, a figure sized to one journal column, and export as a 300-dpi PNG plus a PDF (vector, so it stays sharp at any size). Call the style function once at the top of a script and every plot follows it.",
        "mixed-models|Crossed random effects for participants and items":
            "Two mixed models of log reaction time by Stroop condition. The first gives each **participant** their own intercept and condition effect. The second also lets each word (**item**) have its own intercept — participants and items are crossed, since everyone sees every word. Ignoring item variation would make the condition effect look more certain than it is.",
        "mixed-logistic|Comprehension accuracy by sentence structure":
            "Models a 0/1 outcome (answered correctly or not) with repeated measures. The **mixed logistic** model gives participants and items their own random intercepts; R's version then converts the results into accuracy for simple sentences and an **odds ratio** for complex vs. simple. Python also fits **GEE**, which estimates the population-average effect with standard errors that account for each participant's repeated answers. Both show that complex sentences lower accuracy.",
        "growth-models|Reading scores over five waves, with a randomized intervention":
            "First a **spaghetti plot**: one faint line per student, plus each group's average trajectory. Then two growth models. The first gives every student their own starting point and growth rate; the second adds the intervention. The **wave × group** term is the answer — does the intervention change how fast reading grows?",
        "scale-scoring|Score the mindfulness items in survey.csv":
            "The standard steps for turning questionnaire items into a score. **Reverse-key** the negatively worded items (6 − x on a 1–5 scale), average the items into a composite only for people who answered at least 5 of 6, check internal consistency with **Cronbach's α**, and look at each item's correlation with the rest. An item with a low item–rest correlation may not belong.",
        "reliability|Reliability and exploratory factor analysis":
            "Reverse-keys the mindfulness items, reports **Cronbach's α** with a CI, then runs a one-factor **exploratory factor analysis** and prints each item's loading. Items with loadings below about .4 measure the common factor weakly. With several factors, switch on an oblique rotation as the comment shows.",
        "cfa|A one-factor CFA of the six mindfulness items":
            "A **confirmatory** factor analysis: you state in advance that all six items measure one factor (`mindful =~ …`), then check how well that model fits. Read the standardized loadings first, then the fit indices — CFI and TLI near .95 or above and RMSEA below about .06–.08 suggest a good fit.",
        "cfa|Measurement invariance across urban and rural respondents":
            "Asks whether the scale measures the same thing in both regions. In Python, the code fits the model separately in each region and compares the loadings by eye. R's **lavaan** does it properly: it fits increasingly constrained models (same structure, same loadings, same intercepts) and tests whether each constraint makes fit worse. Group comparisons of scores are only fair once invariance holds.",
        "inter-rater|Two raters' essay scores":
            "Several ways to measure how much two raters agree on 1–6 essay scores: the cross-tab, exact and within-one-point agreement, **Cohen's κ** (chance-corrected), **weighted κ** (near misses count partly), **Krippendorff's α** for ordinal scores, and the **intraclass correlation**. For ordered scores, weighted κ, α, and the ICC are usually the ones to report.",
        "reporting|Generate a report string directly from results":
            "Runs a Welch t-test and builds the APA-style sentence straight from the result — *t*(df) = …, *p* = …, *d* = … — formatting *p* without a leading zero and as “< .001” when it's tiny. Generating text from results, rather than retyping numbers, prevents copy errors when the analysis changes.",
        "moderation|Does mindfulness weaken the social media → rumination link?":
            "A moderation analysis. It centers both predictors, fits social media × mindfulness with covariates, and reads the **interaction** row. Then it gets **simple slopes** — the social media effect at low, average, and high mindfulness — by re-centering mindfulness at each value and refitting. A slope that shrinks as mindfulness rises means mindfulness buffers the link.",
        "mediation|Social media → rumination → anxiety, 10,000 bootstrap resamples":
            "A mediation analysis with covariates. The output rows are the **a** path (social media → rumination), the **b** path (rumination → anxiety, holding social media constant), and the total, direct, and **indirect** effects. The indirect effect's bootstrap CI is the test: if it excludes 0, part of the effect runs through rumination.",
        "moderated-mediation|Indirect effect of social media at low, average, and high mindfulness":
            "Combines the moderation and mediation models. It computes the indirect effect (social media → rumination → anxiety) at low, average, and high mindfulness, plus the **index of moderated mediation**, then bootstraps all four for CIs. If the index's CI excludes 0, the size of the indirect effect depends on mindfulness.",
        "ordinal-models|Acceptability ratings in a 2 × 2 design":
            "Treats the 1–7 ratings as **ordered categories** rather than numbers. It effect-codes the two factors (±0.5, so main effects average over the other factor), then fits a cumulative-logit model. A negative coefficient shifts ratings toward the low end. The Python version ignores the repeated measures, so its SEs are too small; R's `clmm` adds random effects.",
        "multinomial|Shares over time and the transition matrix":
            "Describes the commute data before modelling it: the share of each mode week by week (is biking growing?), then a **transition matrix** (given this week's mode, how often does each mode come next?). The large diagonal shows habit.",
        "multinomial|Multinomial models: does biking grow over the weeks?":
            "A **multinomial logistic** model for a choice among four modes. Each non-car mode gets its own set of coefficients compared with car (the reference): the week coefficient for bike answers whether biking grows over time, and distance shows how longer trips discourage biking and walking. The R version (`mblogit`) adds a random intercept per person for the repeated weeks; the Python version doesn't, so treat its SEs as too small.",
        "count-models|Filler words in interviews of different lengths":
            "Models counts of filler words. Longer interviews have more fillers, so the model uses log(minutes) as an **offset** — it really models fillers per minute. The Poisson model comes first; its dispersion statistic (well above 1) shows the counts vary more than Poisson allows. The **negative binomial** model fixes that. Exponentiated coefficients are **rate ratios**.",
        "latent-class|Fit 1–6 classes, choose by BIC, and inspect the profiles":
            "A **latent class analysis** of six yes/no study habits. It fits models with 1 to 6 classes, prints BIC for each (lower is better), refits the 3-class model, and shows the class sizes and each class's habit profile (the share using each strategy). **Entropy** near 1 means students are classified with confidence.",
        "latent-profile|Enumerate 1–6 profiles, choose by BIC, inspect the profile means":
            "A **latent profile analysis** — like latent classes, but for continuous scores (wellbeing, stress, support, sleep). It fits 1 to 6 profiles, compares BIC, refits 3 profiles, and prints each profile's size and mean scores, which is how you name the profiles.",
        "latent-profile|Let variances differ across profiles":
            "Refits the 3-profile model with a more flexible structure — variances that differ between profiles (and, in Python, free covariances too) — and compares the fit with the simpler model. Lower BIC wins; if the gain is small, keep the simpler model.",
        "mplus-mixtures|Export data for Mplus and run it":
            "Mplus reads plain numbers with no header row, so this writes the datasets as space-separated `.dat` files (with −999 for missing values), then runs an Mplus input file. You need Mplus installed; adjust the path for your computer.",
        "clustering|Embed sentences, choose k by silhouette, run HDBSCAN, find medoids":
            "Clusters short texts by meaning. A sentence-transformer turns each sentence into an **embedding** (a list of numbers where similar meanings sit close together). The code then picks the number of clusters with the **silhouette score**, runs k-means and HDBSCAN, and prints each cluster's **medoid** — its most typical sentence. The 12 sentences cover cooking, weather, and exercise, so three clusters should appear. The first run downloads the model.",
        "keyness|Which words distinguish beginner from expert cooking questions?":
            "Finds the words most characteristic of each group of texts. It counts each word in beginner and expert questions, adds a prior based on the pooled counts so rare words aren't over-interpreted, and computes a **weighted log-odds z-score** per word. Large positive z = typical of beginners (*easy*, *quick*); large negative = typical of experts (*ratio*, *technique*).",
        "topic-models|Load the consensus coding sheet":
            "Loads the practice simulation's consensus coding sheet — one row per speech act — and joins on each participant's court-case headline, which coders don't see while coding. It keeps the act's words in a `text` column and defines a tokenizer (R) for the exercises below.",
        "missing-data|Who skipped the question, and what listwise deletion does":
            "Diagnoses missing data before fixing it: the share missing in each column, then a logistic model of **who skipped** the wellbeing question (stressed people did), then the cost of simply dropping incomplete rows. Because stressed people skipped, the complete-case mean overstates wellbeing compared with the hidden truth.",
        "missing-data|Multiple imputation with chained equations, pooled with Rubin's rules":
            "**Multiple imputation**: fills each missing wellbeing value with a plausible draw predicted from stress, sleep, and age, 20 times over, analyses each completed dataset, and combines the results with **Rubin's rules** (the SE includes the extra uncertainty from imputing). The MI mean should land much closer to the truth than listwise deletion.",
        "survey-weights|Weighted estimates, design-based SEs, and the design effect":
            "Rural towns were oversampled, so each respondent carries a **weight** (how many people they stand for). The code compares unweighted and weighted support, computes **Kish's effective sample size**, and a **design-based SE** that accounts for clustering within towns. The design effect (how much the design inflates the variance) is the last line.",
        "causal-inference|Naive, adjusted, and collider-adjusted estimates":
            "Estimates the tutoring effect three ways. The **naive** estimate is biased upward because motivated students choose tutoring. **Adjusting** for the confounders recovers the true effect (about +5). Adding `recommended` — a **collider**, caused by both tutoring and exam performance — biases it again. Which variables you adjust for matters as much as adjusting at all.",
        "causal-inference|Propensity scores, overlap, and inverse probability weighting":
            "Models each student's probability of choosing tutoring from the confounders (the **propensity score**), checks that tutored and untutored students overlap in those probabilities, then reweights each group to look like the whole sample (**inverse probability weighting**). The weighted difference estimates the average effect of tutoring.",
        "meta-analysis|Random-effects meta-analysis, forest plot, and publication-bias checks":
            "Pools 12 studies' effect sizes. It computes each study's sampling variance, fits a **random-effects** model (which allows true effects to differ between studies), and reports τ², *Q*, and *I*² for heterogeneity, then draws a **forest plot**. The funnel plot and **Egger's test** check for small-study effects — signs that small, null studies went unpublished.",
        "bayesian|A participant's accuracy: prior, posterior, and credible interval":
            "A Bayesian estimate of accuracy after 14 of 20 trials correct. Starting from a flat prior, the posterior is a Beta distribution. The code reports its mean, a 95% **credible interval** (there's a 95% probability the accuracy lies inside it, given the prior and data), and the probability that the participant is better than chance.",
        "bayesian|Bayesian regression with brms (R) or bambi (Python)":
            "A full Bayesian regression of anxiety on rumination and social media, with weakly informative Normal(0, 1) priors, sampled with MCMC (4 chains). Check that **R-hat ≈ 1** and the effective sample sizes are large before reading the estimates. The last line gives the posterior probability that the rumination slope is positive.",
        "bayesian|A quick Bayes factor from BIC: is there really no regional difference?":
            "Approximates a **Bayes factor** from two models' BIC values: one with no regional difference, one with a difference. BF01 above 1 favours “no difference” (above about 3 is moderate evidence), something a non-significant *p*-value alone can't tell you.",
    ]

    static func codeExplanation(lessonID: String?, caption: String) -> String? {
        guard let lessonID else { return nil }
        return codeExplanations["\(lessonID)|\(caption)"]
    }
}

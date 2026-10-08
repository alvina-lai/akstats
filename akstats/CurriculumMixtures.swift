import Foundation

// MARK: - Unit 10 · Latent profile analysis and Mplus

extension Curriculum {
    static let latentProfile = Lesson(
        id: "latent-profile",
        title: "Latent profile analysis (LPA)",
        summary: "Find subgroups from continuous indicators.",
        minutes: 14,
        blocks: [
            .text("**Latent profile analysis** is LCA's sibling for **continuous** indicators such as scale scores. Instead of a probability of showing each code, every hidden profile has its own **mean** on each indicator. Both are *finite mixture models*: the data are treated as a mix of several subpopulations you can't observe directly."),
            .model(ModelExplainer(
                name: "Latent profile analysis",
                purpose: "Treats the sample as a mixture of a few unobserved subgroups, each with its own means (and possibly variances) on several continuous indicators.",
                equation: "f(y) = Σₖ πₖ · N(y | µₖ, Σₖ)",
                steps: [
                    "Choose a number of profiles K and a variance structure (e.g. equal variances, zero covariances — the Mplus default).",
                    "Each profile k has a size πₖ and a vector of indicator means µₖ; within a profile, indicators are typically assumed uncorrelated (local independence).",
                    "The EM algorithm alternates between each person's posterior probability of each profile and the profile parameters, from many random starts.",
                    "Repeat for K = 1, 2, 3, … and compare BIC, likelihood-ratio tests, entropy, profile sizes, and interpretability.",
                ],
                conditions: [
                    "**Continuous indicators** that are roughly normal within profiles.",
                    "**Enough cases** (several hundred), a **replicated best loglikelihood**, and **no trivially small profiles**.",
                    "**A variance–covariance structure chosen in advance** and compared deliberately.",
                ],
                reading: "Spurk, Hirschi, Wang, Valero & Kauffeld (2020), *Journal of Vocational Behavior*, 120, 103445; Nylund-Gibson & Choi (2018), *Translational Issues in Psychological Science*, 4(4), 440–461."
            )),
            .chart(ChartExample(
                title: "Reading LPA profile means",
                kind: .profileMeans,
                reading: [
                    "Each line is one latent profile; each point is that profile's mean on an indicator.",
                    "**Thriving:** high wellbeing, support, and sleep, low stress. **Struggling:** the mirror image. **Average:** near the midpoint everywhere.",
                    "Lines that cross indicate that profiles differ in *shape*, not just level — here the stress indicator runs opposite to the others.",
                    "Always report profile sizes (in the legend) alongside the means.",
                ]
            )),
            .terms([
                Term("LCA vs. LPA", "Same idea, different indicators: LCA uses categorical indicators (item-response probabilities per class); LPA uses continuous ones (means and variances per profile)."),
                Term("Finite mixture model", "A model that assumes the sample is a mixture of K unobserved subgroups."),
                Term("Profile", "One latent subgroup in an LPA, described by its pattern of indicator means."),
                Term("Variance–covariance structure", "What's allowed to differ between profiles. Common options: equal variances with zero covariances (the Mplus default), profile-varying variances, or freely estimated covariances."),
                Term("Distal outcome", "A variable that profiles are expected to *predict*, analyzed after the profiles are formed."),
                Term("Covariate (predictor of membership)", "A variable expected to predict *which* profile someone belongs to."),
            ]),
            .code(CodeSample(
                caption: "Enumerate 1–6 profiles, choose by BIC, inspect the profile means",
                python: #"""
                import pandas as pd
                from sklearn.mixture import GaussianMixture

                lpa = pd.read_csv("profiles.csv")
                indicators = ["wellbeing", "stress", "support", "sleep"]
                X = lpa[indicators].to_numpy()

                # covariance_type="diag": zero covariances within profiles, variances free per profile
                bics = {}
                for k in range(1, 7):
                    gm = GaussianMixture(n_components=k, covariance_type="diag",
                                         n_init=20, random_state=1).fit(X)
                    bics[k] = gm.bic(X)
                print(pd.Series(bics, name="BIC").round(1))

                best = GaussianMixture(n_components=3, covariance_type="diag",
                                       n_init=20, random_state=1).fit(X)
                post = best.predict_proba(X)
                lpa["profile"] = post.argmax(axis=1) + 1

                print("profile sizes:", post.mean(axis=0).round(3))
                print(lpa.groupby("profile")[indicators].mean().round(2))
                """#,
                r: #"""
                library(tidyverse)
                library(tidyLPA)

                lpa <- read_csv("profiles.csv")
                indicators <- lpa |> select(wellbeing, stress, support, sleep)

                # Equal variances, zero covariances = the Mplus default ("model 1" in tidyLPA)
                fits <- indicators |>
                  estimate_profiles(1:6, variances = "equal", covariances = "zero")
                get_fit(fits)              # LogLik, AIC, BIC, SABIC, Entropy, BLRT p-value, …
                compare_solutions(fits)

                best <- indicators |> estimate_profiles(3, variances = "equal", covariances = "zero")
                get_estimates(best)        # means and variances per profile
                plot_profiles(best)

                # tidyLPA can also hand the same models to Mplus:
                # estimate_profiles(indicators, 1:6, package = "MplusAutomation")
                """#,
                mplus: #"""
                TITLE:    Latent profile analysis, 3 profiles (Mplus default structure);

                DATA:     FILE = profiles.dat;       ! no header row (see "Mixture models in Mplus")

                VARIABLE: NAMES = id wellbe stress support sleep age burnout tprof;
                          USEVARIABLES = wellbe stress support sleep;   ! continuous: no CATEGORICAL
                          CLASSES = c(3);
                          IDVARIABLE = id;

                ANALYSIS: TYPE = MIXTURE;
                          STARTS = 500 100;
                          LRTSTARTS = 0 0 100 20;

                ! By default, means differ across profiles, variances are held equal,
                ! and covariances are fixed at 0 (local independence).

                OUTPUT:   TECH11 TECH14;

                SAVEDATA: FILE = lpa3_post.dat;
                          SAVE = CPROBABILITIES;
                """#
            )),
            .code(CodeSample(
                caption: "Let variances differ across profiles",
                python: #"""
                # sklearn's "diag" already frees variances per profile;
                # "full" also frees within-profile covariances
                full = GaussianMixture(n_components=3, covariance_type="full", n_init=20, random_state=1).fit(X)
                print("diag BIC:", best.bic(X), " full BIC:", full.bic(X))
                """#,
                r: #"""
                indicators |>
                  estimate_profiles(3,
                                    variances   = c("equal", "varying"),
                                    covariances = c("zero",  "zero")) |>
                  compare_solutions()
                """#,
                mplus: #"""
                ! Add to the 3-profile input: mentioning a variable inside a
                ! class-specific section frees its variance in that profile.
                MODEL:    %OVERALL%
                          %c#1%
                          wellbe stress support sleep;
                          %c#2%
                          wellbe stress support sleep;
                          %c#3%
                          wellbe stress support sleep;
                """#
            )),
            .keyPoint("Plot the profiles", "Report a line plot of each profile's indicator means (standardized or on the original scale), with profile sizes in the legend. Name each profile by its shape — e.g. “thriving”, “average”, “struggling” — not by its number."),
            .caution("More flexible isn't automatically better", "Freeing variances and covariances adds many parameters, can produce tiny or unstable profiles, and makes non-convergence more likely. Compare a small set of structures you chose in advance, and prefer the simplest one that fits and makes sense."),
            .exercise(Exercise(
                title: "Recover the truth",
                prompt: "`profiles.csv` stores each person's `true_profile`. Cross-tabulate it with your estimated profiles. How many people are classified correctly (allowing for label switching)?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    est = lpa["profile"]
                    print(pd.crosstab(est, lpa["true_profile"]))
                    """#,
                    r: #"""
                    est <- get_data(best)$Class   # get_data() adds Class and CPROB columns
                    table(estimated = est, true = lpa$true_profile)
                    """#
                ),
                answer: "Nearly everyone lands in the right profile (the labels may be permuted). The profiles are well separated — about 1.5 SD apart on several indicators — so entropy is high.",
                selfCheck: SelfCheck(
                    names: "`est` — each person's most likely profile (1, 2, or 3), in the original row order",
                    python: #"""
                    from itertools import permutations
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        truth = pd.read_csv("profiles.csv")["true_profile"].to_numpy()
                        est_arr = np.asarray(est).astype(int)
                        check("One profile per person", len(est_arr), len(truth), tol=0)
                        # Profile numbers are arbitrary, so score the best matching of labels.
                        agreement = max((np.array(p)[est_arr - 1] == truth).mean() for p in permutations([1, 2, 3]))
                        print(f"Classified correctly: {agreement:.0%}")
                        check("At least 90% classified correctly", agreement >= 0.90, True,
                              hint="Fit 3 profiles with many random starts (n_init) on the four indicators only.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      truth <- read.csv("profiles.csv")$true_profile
                      check("One profile per person", length(est), length(truth), tol = 0)
                      # Profile numbers are arbitrary, so score the best matching of labels.
                      perms <- list(c(1, 2, 3), c(1, 3, 2), c(2, 1, 3), c(2, 3, 1), c(3, 1, 2), c(3, 2, 1))
                      agreement <- max(sapply(perms, function(p) mean(p[est] == truth)))
                      cat(sprintf("Classified correctly: %.0f%%\n", 100 * agreement))
                      check("At least 90% classified correctly", agreement >= 0.90, TRUE,
                            hint = "Fit 3 profiles on the four indicators only.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Plot the profile means",
                prompt: "Draw one line per profile across the four indicators.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import matplotlib.pyplot as plt
                    means = lpa.groupby("profile")[indicators].mean()
                    sizes = lpa["profile"].value_counts(normalize=True).sort_index()
                    fig, ax = plt.subplots(figsize=(6, 4))
                    for (k, row), color in zip(means.iterrows(), ["#E69F00", "#56B4E9", "#009E73"]):
                        ax.plot(indicators, row, marker="o", color=color, label=f"Profile {k} ({sizes[k]:.0%})")
                    ax.set(ylabel="Mean (1–7)")
                    ax.legend(frameon=False)
                    plt.show()
                    """#,
                    r: #"""
                    get_data(best) |>
                      pivot_longer(c(wellbeing, stress, support, sleep), names_to = "indicator") |>
                      group_by(Class, indicator) |>
                      summarise(mean = mean(value), .groups = "drop") |>
                      ggplot(aes(indicator, mean, colour = factor(Class), group = Class)) +
                      geom_line() + geom_point() +
                      scale_colour_manual(values = c("#E69F00", "#56B4E9", "#009E73")) +
                      labs(colour = "Profile", y = "Mean (1–7)", x = NULL) +
                      theme_classic()
                    """#
                ),
                answer: "One profile is high on wellbeing, support, and sleep but low on stress; one sits near the midpoint everywhere; one shows the opposite pattern."
            )),
            .exercise(Exercise(
                title: "A distal outcome, naively",
                prompt: "Compare mean `burnout` across your estimated profiles with an ANOVA on the most likely profile. Why is this only an approximation?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pingouin as pg
                    burnout_means = lpa.groupby("profile")["burnout"].mean()
                    print(burnout_means.round(2))
                    print(pg.anova(data=lpa, dv="burnout", between="profile"))
                    """#,
                    r: #"""
                    dat <- get_data(best) |> mutate(burnout = lpa$burnout)
                    burnout_means <- dat |> group_by(Class) |> summarise(mean = mean(burnout))
                    burnout_means
                    summary(aov(burnout ~ factor(Class), data = dat))
                    """#
                ),
                answer: "Burnout is lowest in the thriving profile and highest in the struggling profile. Assigning people to their most likely profile ignores classification uncertainty, which biases comparisons when entropy is lower. Mplus's BCH and DCON methods (next lesson) correct for this.",
                selfCheck: SelfCheck(
                    names: "`burnout_means` — mean burnout in each estimated profile (in R, a `mean` column)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Compare with the true profiles' means. Sorting removes the arbitrary profile numbering.
                        truth = pd.read_csv("profiles.csv").groupby("true_profile")["burnout"].mean()
                        check("Burnout means, lowest to highest (vs. the true profiles)",
                              np.sort(np.asarray(burnout_means)), np.sort(truth.to_numpy()), tol=0.05,
                              hint="Group burnout by your estimated profile, not by true_profile.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Compare with the true profiles' means. Sorting removes the arbitrary profile numbering.
                      ref <- read.csv("profiles.csv")
                      truth <- tapply(ref$burnout, ref$true_profile, mean)
                      check("Burnout means, lowest to highest (vs. the true profiles)",
                            sort(burnout_means$mean), sort(as.vector(truth)), tol = 0.05,
                            hint = "Group burnout by your estimated profile, not by true_profile.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Your indicators are four continuous scale scores. Which mixture model fits?",
                options: ["Latent class analysis", "Latent profile analysis", "Multinomial logistic regression", "Factor analysis"],
                answer: 1,
                explanation: "LPA is the mixture model for continuous indicators."
            ),
            Question(
                prompt: "In an LPA, what defines each profile?",
                options: ["Its item-response probabilities", "Its pattern of indicator means (and possibly variances)", "Its factor loadings", "Its regression slope"],
                answer: 1,
                explanation: "Profiles differ in their means on the continuous indicators."
            ),
            Question(
                prompt: "What does Mplus assume by default in an LPA?",
                options: [
                    "Free variances and covariances in every profile",
                    "Profile-specific means, equal variances, zero covariances",
                    "Equal means across profiles",
                    "One profile only",
                ],
                answer: 1,
                explanation: "Means vary; variances are equal across profiles; within-profile covariances are 0 (local independence)."
            ),
        ]
    )

    static let mplusMixtures = Lesson(
        id: "mplus-mixtures",
        title: "Mixture models in Mplus",
        summary: "Data prep, random starts, choosing K, and auxiliary variables — for LCA and LPA.",
        minutes: 16,
        blocks: [
            .text("**Mplus** is the reference software for latent class and latent profile models. Compared with most R and Python packages, it has more robust random-start routines, built-in likelihood-ratio tests for choosing the number of classes, and corrected **three-step** methods for relating classes to other variables. It's commercial; a free demo version with variable limits is available from statmodel.com. LCA and LPA use the same workflow — only the `CATEGORICAL` line differs."),
            .steps("The Mplus workflow", [
                "Export the data as a plain text file with **no header row**, numeric values only, and a code for missing data (e.g. −999).",
                "Write an input file (`.inp`) with `TITLE`, `DATA`, `VARIABLE`, `ANALYSIS`, `OUTPUT`, and `SAVEDATA` commands. Every statement ends with a semicolon; `!` starts a comment.",
                "Run models with 1, 2, 3, … classes, using many random starts.",
                "Check that the **best loglikelihood was replicated** in each model.",
                "Compare fit (BIC, aBIC, LMR, BLRT, entropy, smallest class) and interpretability, and pick K using your preregistered rule.",
                "Only **then** relate the classes to covariates and outcomes with a three-step method (R3STEP, BCH, DCON, DCAT).",
            ]),
            .code(CodeSample(
                caption: "Export data for Mplus and run it",
                python: #"""
                import subprocess
                import pandas as pd

                # Mplus reads numbers only, with no header; variable names go in the .inp file
                habits = pd.read_csv("habits.csv")                            # all-numeric already
                habits.to_csv("habits.dat", sep=" ", header=False, index=False)

                lpa = pd.read_csv("profiles.csv")
                lpa.to_csv("profiles.dat", sep=" ", header=False, index=False, na_rep="-999")

                # Run an input file from Python (adjust the path for your installation;
                # on Windows it's typically C:/Program Files/Mplus/Mplus.exe)
                subprocess.run(["/Applications/Mplus/mplus", "lpa3.inp"], check=True)
                """#,
                r: #"""
                library(tidyverse)
                library(MplusAutomation)

                profiles <- read_csv("profiles.csv") |>
                  rename(wellbe = wellbeing, tprof = true_profile)    # Mplus names: ≤ 8 characters

                # Write, run, and collect a 1–6 profile enumeration in one loop
                for (k in 1:6) {
                  model <- mplusObject(
                    TITLE    = sprintf("LPA with %d profiles;", k),
                    VARIABLE = sprintf("USEVARIABLES = wellbe stress support sleep;\nCLASSES = c(%d);\nIDVARIABLE = id;", k),
                    ANALYSIS = "TYPE = MIXTURE;\nSTARTS = 500 100;\nLRTSTARTS = 0 0 100 20;",
                    OUTPUT   = if (k > 1) "TECH11 TECH14;" else "",
                    usevariables = c("id", "wellbe", "stress", "support", "sleep"),
                    rdata    = profiles
                  )
                  mplusModeler(model, dataout = "profiles.dat",
                               modelout = sprintf("lpa_%d.inp", k), run = 1L)
                }

                fits <- readModels(filefilter = "lpa_")
                SummaryTable(fits, keepCols = c("Title", "Parameters", "LL", "BIC", "aBIC",
                                                "Entropy", "T11_LMR_PValue", "BLRT_PValue"))
                """#,
                mplus: #"""
                TITLE:    LPA with 3 profiles, plus a distal outcome (BCH);

                DATA:     FILE = profiles.dat;
                          ! MISSING ARE ALL (-999);   ! add when your data has missing values

                VARIABLE: NAMES = id wellbe stress support sleep age burnout tprof;
                          USEVARIABLES = wellbe stress support sleep;
                          CLASSES = c(3);
                          IDVARIABLE = id;
                          AUXILIARY = burnout (BCH);   ! compare burnout across profiles
                          ! AUXILIARY = age (R3STEP);  ! or: does age predict membership?

                ANALYSIS: TYPE = MIXTURE;
                          STARTS = 500 100;
                          LRTSTARTS = 0 0 100 20;

                OUTPUT:   SAMPSTAT TECH11 TECH14;

                SAVEDATA: FILE = lpa3_post.dat;
                          SAVE = CPROBABILITIES;
                """#
            )),
            .terms([
                Term("STARTS", "Random starting values: `STARTS = 500 100` tries 500 initial sets and fully optimizes the best 100. Mixture likelihoods have many local maxima."),
                Term("Replicated loglikelihood", "The output line “THE BEST LOGLIKELIHOOD VALUE HAS BEEN REPLICATED” means several starts reached the same best solution. If it hasn't, increase STARTS."),
                Term("aBIC", "Sample-size-adjusted BIC; like BIC, lower is better."),
                Term("VLMR / LMR test (TECH11)", "Likelihood-ratio tests of K vs. K − 1 classes. A significant p supports K over K − 1."),
                Term("BLRT (TECH14)", "Bootstrapped likelihood-ratio test of K vs. K − 1; performed best in simulations (Nylund et al., 2007)."),
                Term("Average posterior probabilities", "In the output table of average latent class probabilities for each most-likely class, diagonal values above about .80 indicate clear assignment."),
                Term("Three-step approach", "Estimate the classes first, then relate them to other variables while correcting for classification error, so auxiliary variables don't change what the classes mean."),
                Term("R3STEP", "Three-step multinomial regression of class membership on covariates."),
                Term("BCH / DCON / DCAT", "Three-step comparisons of a distal outcome across classes. BCH is generally recommended for continuous outcomes; DCAT is for categorical outcomes."),
                Term("TYPE = MIXTURE COMPLEX", "Adds cluster-robust standard errors when observations are nested (e.g. students within schools, with `CLUSTER = school;`)."),
                Term("MplusAutomation", "R package that writes, runs, and reads Mplus models, so enumeration tables can be built automatically."),
            ]),
            .keyPoint("A class-enumeration table", "Report one row per K: number of parameters, LL, BIC, aBIC, entropy, LMR p, BLRT p, and the smallest class's share. Choose K with a preregistered rule — e.g. “lowest BIC, unless a class is < 5% or not interpretable” — and show the table even for the models you didn't pick."),
            .caution("Don't add auxiliary variables too early", "If you put covariates or outcomes directly into the mixture model (the one-step approach), they can change what the classes are. Settle on K and the class solution first, then use R3STEP, BCH, DCON, or DCAT."),
            .caution("Clustered data", "If observations are nested (students in schools, repeated observations of the same person), add `CLUSTER = school;` (or the relevant ID) and `TYPE = MIXTURE COMPLEX;` to get cluster-robust standard errors. Some fit tests (such as TECH14) aren't available with COMPLEX, so many researchers run the enumeration without it, then refit the chosen model with COMPLEX. Check the Mplus User's Guide for your version."),
            .exercise(Exercise(
                title: "Read an enumeration table",
                prompt: "Which K would you choose, and why?\n\n• K = 2: BIC 5120, entropy .91, LMR p < .001, BLRT p < .001, smallest class 38%\n• K = 3: BIC 4871, entropy .93, LMR p < .001, BLRT p < .001, smallest class 19%\n• K = 4: BIC 4884, entropy .82, LMR p = .41, BLRT p = .21, smallest class 3%",
                answer: "**K = 3.** It has the lowest BIC, and both likelihood-ratio tests favor 3 over 2. The 4-class model has higher BIC, non-significant LMR and BLRT tests, and a class of only 3% — too small to interpret reliably."
            )),
            .exercise(Exercise(
                title: "The loglikelihood wasn't replicated",
                prompt: "Mplus warns: “THE BEST LOGLIKELIHOOD VALUE WAS NOT REPLICATED. THE SOLUTION MAY NOT BE TRUSTWORTHY DUE TO LOCAL MAXIMA.” What do you change?",
                answer: "Increase the random starts — e.g. `STARTS = 2000 500;` — and rerun until the best loglikelihood is replicated. If it never is, the model may be too complex for the data (too many classes or free parameters)."
            )),
            .exercise(Exercise(
                title: "Run the enumeration",
                prompt: "If you have Mplus, run the R loop above for 1–6 profiles. Otherwise, build the same table with tidyLPA's `get_fit()` or sklearn's BIC. Which K does each criterion favor?",
                solution: CodeSample(
                    caption: "Solution (without Mplus)",
                    python: #"""
                    import pandas as pd
                    from sklearn.mixture import GaussianMixture

                    lpa = pd.read_csv("profiles.csv")
                    X = lpa[["wellbeing", "stress", "support", "sleep"]].to_numpy()
                    bic = pd.Series({k: GaussianMixture(n_components=k, covariance_type="diag", n_init=20,
                                                        random_state=1).fit(X).bic(X)
                                     for k in range(1, 7)}, name="BIC")
                    print(bic.round(1), "\nlowest BIC at K =", bic.idxmin())
                    """#,
                    r: #"""
                    library(tidyverse)
                    library(tidyLPA)

                    indicators <- read_csv("profiles.csv") |> dplyr::select(wellbeing, stress, support, sleep)
                    fit_table <- estimate_profiles(indicators, 1:6, variances = "equal", covariances = "zero") |>
                      get_fit()
                    bic <- fit_table$BIC
                    fit_table[, c("Classes", "BIC", "Entropy")]
                    """#
                ),
                answer: "BIC, aBIC, LMR, and BLRT should all point to **3 profiles** in the generated data, with entropy above .85. (Two extra profiles may improve LL slightly but are penalized by BIC.)",
                selfCheck: SelfCheck(
                    names: "`bic` — the six BIC values for K = 1, 2, …, 6, in that order",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # e.g. bic = pd.Series(bics) from the LPA lesson's enumeration loop
                        b = np.asarray(list(bic.values()) if isinstance(bic, dict) else bic, dtype=float)
                        check("Six BIC values", len(b), 6, tol=0)
                        check("BIC is lowest at K = 3", int(np.argmin(b)) + 1, 3, tol=0,
                              hint="Use the same covariance structure for every K, with several random starts.")
                        check("BIC drops sharply from K = 1 to K = 3", bool(b[0] > b[1] > b[2]), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # e.g. bic <- get_fit(fits)$BIC from tidyLPA, or SummaryTable(fits)$BIC from Mplus
                      check("Six BIC values", length(bic), 6, tol = 0)
                      check("BIC is lowest at K = 3", which.min(bic), 3, tol = 0,
                            hint = "Use the same variance structure for every K.")
                      check("BIC drops sharply from K = 1 to K = 3", bic[1] > bic[2] && bic[2] > bic[3], TRUE)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "LCA in Mplus",
                prompt: "Adapt the LPA input to fit a 3-class LCA to `habits.dat`. What single line makes the indicators categorical?",
                hint: "Compare the inputs in *Latent class analysis (LCA)* and *Latent profile analysis (LPA)*.",
                answer: "`CATEGORICAL = reread notes selftest spaced explain peers;` — plus updating `NAMES` and `USEVARIABLES` to match `habits.dat`. Everything else in the workflow (STARTS, TECH11, TECH14, SAVEDATA) stays the same."
            )),
        ],
        quiz: [
            Question(
                prompt: "Why use many random starts in mixture models?",
                options: ["To make the model run faster", "Mixture likelihoods have local maxima", "To increase the sample size", "Mplus requires exactly 500"],
                answer: 1,
                explanation: "Different starting values can converge on different solutions; many starts help find the global maximum."
            ),
            Question(
                prompt: "TECH14's bootstrapped LRT for K = 4 vs. K = 3 gives p = .38. This suggests…",
                options: ["4 classes fit significantly better", "4 classes don't fit significantly better than 3", "The model didn't converge", "Entropy is too low"],
                answer: 1,
                explanation: "A non-significant BLRT means the extra class doesn't improve fit enough."
            ),
            Question(
                prompt: "You want to know whether profiles differ in a continuous outcome measured afterwards. Which Mplus option?",
                options: ["AUXILIARY = y (R3STEP)", "AUXILIARY = y (BCH)", "CATEGORICAL = y", "CLASSES = y"],
                answer: 1,
                explanation: "BCH compares distal outcome means across classes while accounting for classification error. R3STEP is for predictors of membership."
            ),
            Question(
                prompt: "An Mplus variable called `social_support` causes an error. Why?",
                options: ["Underscores aren't allowed", "Mplus variable names are limited to 8 characters", "It must be uppercase", "It must be numeric"],
                answer: 1,
                explanation: "Rename long variables (e.g. `support`) before exporting."
            ),
            Question(
                prompt: "What does the line `CATEGORICAL = …` change?",
                options: ["Turns an LPA into an LCA by treating indicators as categorical", "Adds covariates", "Sets the number of classes", "Requests TECH11"],
                answer: 0,
                explanation: "Without it, Mplus treats indicators as continuous (LPA); with it, as categorical (LCA)."
            ),
        ]
    )
}

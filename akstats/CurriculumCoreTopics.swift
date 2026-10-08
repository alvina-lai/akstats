import Foundation

// Core topics that round out Units 3–5: probability (Unit 3), multiple comparisons,
// repeated-measures ANOVA, and equivalence tests (Unit 4), and regression diagnostics (Unit 5).

// MARK: - Unit 3 · Probability

extension Curriculum {
    static let probability = Lesson(
        id: "probability",
        title: "Probability & distributions",
        summary: "Conditional probability, Bayes' rule, and the binomial and Poisson distributions.",
        minutes: 12,
        blocks: [
            .text("Every p-value, confidence interval, and power analysis is a statement about **probability**. A few rules — and two distributions for counts — cover most of what research statistics needs, and they explain some of its most common misreadings."),
            .model(ModelExplainer(
                name: "Probability rules and two distributions for counts",
                purpose: "Describes how likely events are, how probabilities change when you learn something (conditioning), and how many “successes” or events to expect in a fixed number of trials or a fixed amount of time.",
                equation: "P(A and B) = P(A) · P(B | A)        P(A | B) = P(B | A) · P(A) / P(B)\nbinomial: P(X = k) = C(n, k) pᵏ (1 − p)ⁿ⁻ᵏ        Poisson: P(X = k) = λᵏ e^−λ / k!",
                steps: [
                    "A **conditional probability** P(A | B) is the probability of A among only the cases where B happened. Learning B narrows the set of possibilities.",
                    "**Bayes' rule** turns P(B | A) into P(A | B). It needs the **base rate** P(A): even an accurate test gives many false alarms when the condition is rare.",
                    "The **binomial** distribution counts successes in *n* independent trials that each succeed with probability *p* — correct answers on a forced-choice task, yes votes in a sample. Its mean is *np* and its SD √(*np*(1 − *p*)).",
                    "The **Poisson** distribution counts events in a fixed interval when they occur independently at an average rate λ — speech errors per minute, rare words per 1,000 words. Its mean **and** variance both equal λ.",
                    "Software gives exact probabilities: `stats.binom` / `stats.poisson` in Python, `dbinom()` / `pbinom()` / `dpois()` / `ppois()` in R.",
                ],
                conditions: [
                    "**Binomial:** a fixed number of trials, two outcomes per trial, the same *p* every time, and independent trials.",
                    "**Poisson:** independent events at a constant average rate; when counts vary more than λ (common in real data), use a negative binomial model instead (Unit 9).",
                ],
                reading: "OpenIntro Statistics (4th ed.), §3.1–3.2 (probability and conditional probability), §4.3 (binomial distribution), §4.5 (Poisson distribution)."
            )),
            .terms([
                Term("Probability", "A number from 0 (impossible) to 1 (certain): the long-run share of times an event happens."),
                Term("Conditional probability", "P(A | B): the probability of A given that B is true."),
                Term("Independence", "A and B are independent when knowing one doesn't change the probability of the other: P(A | B) = P(A)."),
                Term("Bayes' rule", "P(A | B) = P(B | A) · P(A) / P(B). It updates a probability in light of new evidence."),
                Term("Base rate", "How common something is before you see any evidence — the prior probability."),
                Term("Sensitivity / specificity", "The share of true cases a test flags, and the share of non-cases it correctly clears."),
                Term("Positive predictive value (PPV)", "P(condition | positive test) — what a positive result actually means for a person."),
                Term("Binomial distribution", "The number of successes in n independent yes/no trials with the same probability p."),
                Term("Poisson distribution", "The number of independent events in a fixed interval, at an average rate λ."),
            ]),
            .code(CodeSample(
                caption: "Bayes' rule for a screening questionnaire — computed, then simulated",
                python: #"""
                import numpy as np

                # A screening questionnaire for an anxiety disorder
                prevalence, sensitivity, specificity = 0.10, 0.85, 0.90

                # Bayes' rule: P(disorder | positive) = P(positive | disorder) × P(disorder) / P(positive)
                p_positive = sensitivity * prevalence + (1 - specificity) * (1 - prevalence)
                ppv = sensitivity * prevalence / p_positive
                print(f"P(positive) = {p_positive:.3f}   P(disorder | positive) = {ppv:.3f}")

                # The same answer by simulating 100,000 people
                rng = np.random.default_rng(1)
                disorder = rng.random(100_000) < prevalence
                positive = np.where(disorder, rng.random(100_000) < sensitivity, rng.random(100_000) > specificity)
                print("simulated:", round(disorder[positive].mean(), 3))
                """#,
                r: #"""
                # A screening questionnaire for an anxiety disorder
                prevalence <- 0.10; sensitivity <- 0.85; specificity <- 0.90

                # Bayes' rule: P(disorder | positive) = P(positive | disorder) × P(disorder) / P(positive)
                p_positive <- sensitivity * prevalence + (1 - specificity) * (1 - prevalence)
                ppv <- sensitivity * prevalence / p_positive
                c(p_positive = p_positive, ppv = ppv)

                # The same answer by simulating 100,000 people
                set.seed(1)
                disorder <- runif(1e5) < prevalence
                positive <- ifelse(disorder, runif(1e5) < sensitivity, runif(1e5) > specificity)
                mean(disorder[positive])
                """#
            )),
            .keyPoint("Base rates matter", "With 10% prevalence, a questionnaire that catches 85% of cases and clears 90% of non-cases is right only about **half** the time when it says “positive”. Most positives come from the much larger group without the disorder. Thinking in counts helps: of 1,000 people, 85 true positives versus 90 false positives."),
            .code(CodeSample(
                caption: "Binomial and Poisson probabilities",
                python: #"""
                from scipy import stats

                # Binomial: 20 two-choice trials, guessing (p = .5). How likely are 15 or more correct?
                print(stats.binom.pmf(15, n=20, p=0.5))       # exactly 15
                print(stats.binom.sf(14, n=20, p=0.5))        # 15 or more (sf = 1 − cdf)
                print(stats.binom.mean(20, 0.5), stats.binom.std(20, 0.5))   # n·p and √(n·p·(1 − p))

                # Poisson: a speaker makes 2.5 speech errors per 10 minutes on average
                print(stats.poisson.pmf(0, mu=2.5))           # no errors in 10 minutes
                print(stats.poisson.sf(4, mu=2.5))            # 5 or more
                """#,
                r: #"""
                # Binomial: 20 two-choice trials, guessing (p = .5). How likely are 15 or more correct?
                dbinom(15, size = 20, prob = 0.5)                       # exactly 15
                pbinom(14, size = 20, prob = 0.5, lower.tail = FALSE)   # 15 or more
                c(mean = 20 * 0.5, sd = sqrt(20 * 0.5 * 0.5))           # n·p and √(n·p·(1 − p))

                # Poisson: a speaker makes 2.5 speech errors per 10 minutes on average
                dpois(0, lambda = 2.5)                                  # no errors in 10 minutes
                ppois(4, lambda = 2.5, lower.tail = FALSE)              # 5 or more
                """#
            )),
            .caution("P(A | B) is not P(B | A)", "A p-value is P(data this extreme | H₀ is true). It is **not** P(H₀ is true | the data) — confusing the two is the “prosecutor's fallacy”. Getting from one to the other needs Bayes' rule and a prior (see *Bayesian inference*, Unit 12)."),
            .field(.psychology, "Clinical screening tools are judged by sensitivity and specificity, but what a clinician needs is the positive predictive value — which depends on how common the condition is in *their* setting."),
            .field(.linguistics, "Rare words in a corpus behave roughly like a Poisson process: a word that appears 3 times per 10,000 words is expected 1.5 times in a 5,000-word text, and its absence from a short text is weak evidence about the author."),
            .exercise(Exercise(
                title: "Is the participant guessing?",
                prompt: "In a two-alternative task, a participant answers 16 of 20 trials correctly. If they were guessing (p = .5), what is the probability of getting **16 or more** right?",
                hint: "“16 or more” is the upper tail: `stats.binom.sf(15, …)` or `pbinom(15, …, lower.tail = FALSE)`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    from scipy import stats
                    p_guess = stats.binom.sf(15, n=20, p=0.5)
                    print(round(p_guess, 4))
                    """#,
                    r: #"""
                    p_guess <- pbinom(15, size = 20, prob = 0.5, lower.tail = FALSE)
                    round(p_guess, 4)
                    """#
                ),
                answer: "About **.006** — fewer than 1 in 150 guessers would do this well, so guessing is an unlikely explanation.",
                selfCheck: SelfCheck(
                    names: "`p_guess`",
                    python: #"""
                    from math import comb
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Add up the binomial probabilities for 16, 17, 18, 19, and 20 correct
                        expected = sum(comb(20, k) for k in range(16, 21)) / 2 ** 20
                        check("P(16 or more correct)", p_guess, expected, tol=1e-6,
                              hint="Use sf(15), not sf(16): sf(k) is P(X > k).")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Add up the binomial probabilities for 16, 17, 18, 19, and 20 correct
                      expected <- sum(choose(20, 16:20)) / 2^20
                      check("P(16 or more correct)", p_guess, expected, tol = 1e-6,
                            hint = "Use pbinom(15, ..., lower.tail = FALSE): it gives P(X > 15).")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Screening for a rare condition",
                prompt: "A condition affects 2% of people. A test catches 95% of cases and correctly clears 95% of non-cases. What's the probability that someone who tests positive actually has the condition?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    prevalence, sensitivity, specificity = 0.02, 0.95, 0.95
                    ppv = sensitivity * prevalence / (sensitivity * prevalence + (1 - specificity) * (1 - prevalence))
                    print(round(ppv, 3))
                    """#,
                    r: #"""
                    prevalence <- 0.02; sensitivity <- 0.95; specificity <- 0.95
                    ppv <- sensitivity * prevalence / (sensitivity * prevalence + (1 - specificity) * (1 - prevalence))
                    round(ppv, 3)
                    """#
                ),
                answer: "Only about **.28**. In counts: of 10,000 people, 200 have it and 190 test positive; of the 9,800 who don't, 490 test positive. So 190 of 680 positives are real.",
                selfCheck: SelfCheck(
                    names: "`ppv`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Natural frequencies: imagine 10,000 people
                        have = 10_000 * 0.02
                        true_pos = have * 0.95
                        false_pos = (10_000 - have) * (1 - 0.95)
                        check("P(condition | positive)", ppv, true_pos / (true_pos + false_pos), tol=1e-6,
                              hint="Divide true positives by all positives.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Natural frequencies: imagine 10,000 people
                      have <- 10000 * 0.02
                      true_pos <- have * 0.95
                      false_pos <- (10000 - have) * (1 - 0.95)
                      check("P(condition | positive)", ppv, true_pos / (true_pos + false_pos), tol = 1e-6,
                            hint = "Divide true positives by all positives.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Counting rare words",
                prompt: "A word appears on average 3 times per 10,000 words. Using a Poisson model, what is the probability that it appears **at least once** in a 5,000-word text?",
                hint: "First scale the rate to the text length: λ = 3 × 5,000 / 10,000. Then P(at least one) = 1 − P(0).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    from scipy import stats
                    lam = 3 * 5_000 / 10_000
                    p_at_least_one = 1 - stats.poisson.pmf(0, mu=lam)
                    print(round(p_at_least_one, 3))
                    """#,
                    r: #"""
                    lam <- 3 * 5000 / 10000
                    p_at_least_one <- 1 - dpois(0, lambda = lam)
                    round(p_at_least_one, 3)
                    """#
                ),
                answer: "λ = 1.5, so P(at least one) = 1 − e^−1.5 ≈ **.78**. More than one text in five won't contain the word at all, even though it's “expected” 1.5 times.",
                selfCheck: SelfCheck(
                    names: "`p_at_least_one`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # The Poisson approximates a binomial with many words, each with a tiny chance of being this word
                        p_word = 3 / 10_000
                        check("P(at least one)", p_at_least_one, 1 - (1 - p_word) ** 5_000, tol=0.001,
                              hint="Scale the rate to the text length first: λ = 1.5.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # The Poisson approximates a binomial with many words, each with a tiny chance of being this word
                      p_word <- 3 / 10000
                      check("P(at least one)", p_at_least_one, 1 - (1 - p_word)^5000, tol = 0.001,
                            hint = "Scale the rate to the text length first: λ = 1.5.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A test is 99% accurate for a condition that 1 in 1,000 people have. Someone tests positive. The chance they have the condition is…",
                options: ["About 99%", "About 50%", "About 9%", "Exactly 0.1%"],
                answer: 2,
                explanation: "Of 100,000 people, 99 of the 100 cases test positive, but so do about 999 of the 99,900 non-cases: 99 / 1,098 ≈ 9%."
            ),
            Question(
                prompt: "Which distribution describes the number of correct answers in 30 independent yes/no trials?",
                options: ["Normal", "Binomial", "Poisson", "Uniform"],
                answer: 1,
                explanation: "A fixed number of independent trials, each a success or failure with the same probability."
            ),
            Question(
                prompt: "A p-value of .03 means…",
                options: [
                    "There's a 3% chance the null hypothesis is true",
                    "Data at least this extreme would occur 3% of the time if the null were true",
                    "There's a 97% chance the effect is real",
                    "The effect size is 0.03",
                ],
                answer: 1,
                explanation: "It's P(data | H₀), not P(H₀ | data)."
            ),
        ]
    )
}

// MARK: - Unit 4 · Multiple comparisons, repeated measures, equivalence

extension Curriculum {
    static let multipleComparisons = Lesson(
        id: "multiple-comparisons",
        title: "Multiple comparisons",
        summary: "Family-wise error, Bonferroni and Holm, and false discovery rates.",
        minutes: 11,
        blocks: [
            .text("Each test at α = .05 has a 5% chance of a false positive when there's no effect. Run 20 such tests and the chance of **at least one** false positive is 1 − .95²⁰ ≈ **64%**. Post-hoc comparisons, many outcomes, many predictors, many subgroups — all create a *family* of tests whose error rate needs controlling."),
            .model(ModelExplainer(
                name: "Controlling error across a family of tests",
                purpose: "Adjusts p-values (or the significance threshold) so that the error rate across a whole set of tests stays at a chosen level.",
                equation: "FWER = 1 − (1 − α)ᵐ        Bonferroni: p × m        Holm: p₍ᵢ₎ × (m − i + 1)        BH: p₍ᵢ₎ × m / i",
                steps: [
                    "Define the **family** — the set of tests that answer one question — before looking at results.",
                    "**Bonferroni** multiplies every p-value by the number of tests m. It controls the **family-wise error rate** (FWER): the chance of *any* false positive.",
                    "**Holm** sorts the p-values and multiplies the smallest by m, the next by m − 1, and so on (keeping the adjusted values in order). Same FWER guarantee, always at least as powerful as Bonferroni.",
                    "**Benjamini–Hochberg (BH)** controls the **false discovery rate** (FDR): among the results you call significant, the expected share that are false. It multiplies the i-th smallest p by m / i, and is much more powerful when many tests are run.",
                    "Report adjusted p-values (and which method) and compare them with your usual α.",
                ],
                conditions: [
                    "**A pre-specified family** — corrections can't fix tests chosen after seeing the data.",
                    "Holm and Bonferroni work under any dependence between tests; BH assumes independent or positively related tests (the BY variant relaxes this).",
                    "A plan for **power**: corrections lower it, so studies with many planned tests need larger samples.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §7.5.6 (multiple comparisons and controlling Type 1 error rate); Holm (1979), *Scandinavian Journal of Statistics*, 6(2), 65–70; Benjamini & Hochberg (1995), *Journal of the Royal Statistical Society B*, 57(1), 289–300."
            )),
            .terms([
                Term("Family of tests", "A set of tests that together answer one research question."),
                Term("Family-wise error rate (FWER)", "The probability of at least one false positive in the family."),
                Term("Bonferroni correction", "Multiply each p-value by the number of tests (or test each at α / m)."),
                Term("Holm correction", "A step-down version of Bonferroni: same error control, more power."),
                Term("False discovery rate (FDR)", "The expected share of significant results that are false positives."),
                Term("Benjamini–Hochberg (BH)", "The standard FDR procedure; adjusted p-values are often called q-values."),
                Term("Adjusted p-value", "A p-value rescaled for multiple testing, compared directly with α."),
                Term("Post hoc vs. planned", "Comparisons chosen after seeing the results vs. specified in advance."),
            ]),
            .code(CodeSample(
                caption: "How quickly false positives pile up: 20 tests per study, no real effects",
                python: #"""
                import numpy as np
                from scipy import stats

                rng = np.random.default_rng(3)
                studies, tests, n = 2000, 20, 30
                hits = 0
                for _ in range(studies):
                    # 20 outcomes, two groups, no true differences anywhere
                    p = stats.ttest_ind(rng.normal(size=(tests, n)), rng.normal(size=(tests, n)), axis=1).pvalue
                    hits += (p < 0.05).any()
                print("share of studies with at least one 'finding':", hits / studies)   # ≈ 1 − .95²⁰ ≈ .64
                """#,
                r: #"""
                set.seed(3)
                one_study <- function(tests = 20, n = 30) {
                  # 20 outcomes, two groups, no true differences anywhere
                  p <- replicate(tests, t.test(rnorm(n), rnorm(n))$p.value)
                  any(p < 0.05)
                }
                mean(replicate(2000, one_study()))   # ≈ 1 − .95^20 ≈ .64
                """#
            )),
            .code(CodeSample(
                caption: "Correcting a family of eight correlations with anxiety",
                python: #"""
                import pandas as pd
                from scipy import stats
                from statsmodels.stats.multitest import multipletests

                survey = pd.read_csv("survey.csv")
                predictors = ["age", "education", "social_media", "phone_checking",
                              "rumination", "mindfulness", "mind_1", "mind_6"]

                p_raw = []
                for col in predictors:
                    d = survey[[col, "anxiety"]].dropna()
                    p_raw.append(stats.pearsonr(d[col], d["anxiety"]).pvalue)

                table = pd.DataFrame({"p": p_raw}, index=predictors)
                for method in ["bonferroni", "holm", "fdr_bh"]:
                    table[method] = multipletests(p_raw, alpha=0.05, method=method)[1]
                print(table.round(4))
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")
                predictors <- c("age", "education", "social_media", "phone_checking",
                                "rumination", "mindfulness", "mind_1", "mind_6")

                p_raw <- sapply(predictors, function(col) cor.test(survey[[col]], survey$anxiety)$p.value)

                round(cbind(p          = p_raw,
                            bonferroni = p.adjust(p_raw, "bonferroni"),
                            holm       = p.adjust(p_raw, "holm"),
                            fdr_bh     = p.adjust(p_raw, "BH")), 4)
                """#
            )),
            .code(CodeSample(
                caption: "Post-hoc pairwise comparisons with Holm's correction",
                python: #"""
                import pingouin as pg

                classroom = pd.read_csv("classroom.csv")
                print(pg.pairwise_tests(data=classroom, dv="posttest", between="method", padjust="holm"))
                """#,
                r: #"""
                classroom <- read_csv("classroom.csv")
                pairwise.t.test(classroom$posttest, classroom$method, p.adjust.method = "holm")
                """#
            )),
            .keyPoint("Choose the error rate that fits the question", "Use **FWER** control (Holm) when any single false positive would be costly — a handful of confirmatory hypotheses. Use **FDR** control (BH) when you screen many candidates and can tolerate a few false leads — hundreds of words, genes, or survey items."),
            .caution("Corrections can't rescue a fishing expedition", "Adjusting for the 8 tests you report doesn't account for the 30 you ran and didn't mention. Preregister the family of tests, or clearly label analyses as exploratory."),
            .field(.linguistics, "Keyness analyses and corpus comparisons test thousands of words at once. Without FDR control, dozens of words would look “distinctive” by chance alone."),
            .field(.sociology, "A survey report that breaks one outcome down by 12 demographic subgroups is a family of 12 tests — one “significant” subgroup is expected by chance."),
            .exercise(Exercise(
                title: "Adjust by hand",
                prompt: "Six tests gave p = .001, .008, .012, .030, .041, and .200. Compute Bonferroni-, Holm-, and BH-adjusted p-values. How many are significant at .05 under each method?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    from statsmodels.stats.multitest import multipletests
                    p = [0.001, 0.008, 0.012, 0.030, 0.041, 0.200]
                    p_bonf = multipletests(p, method="bonferroni")[1]
                    p_holm = multipletests(p, method="holm")[1]
                    p_bh = multipletests(p, method="fdr_bh")[1]
                    print(p_bonf.round(3), p_holm.round(3), p_bh.round(3), sep="\n")
                    """#,
                    r: #"""
                    p <- c(0.001, 0.008, 0.012, 0.030, 0.041, 0.200)
                    p_bonf <- p.adjust(p, "bonferroni")
                    p_holm <- p.adjust(p, "holm")
                    p_bh   <- p.adjust(p, "BH")
                    round(rbind(p_bonf, p_holm, p_bh), 3)
                    """#
                ),
                answer: "Bonferroni keeps **2** significant, Holm **3**, and BH **5**. Same data, different error rates controlled — and a big difference in power.",
                selfCheck: SelfCheck(
                    names: "`p_bonf`, `p_holm`, and `p_bh` — the adjusted p-values, in the original order",
                    python: #"""
                    import numpy as np
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        p = np.array([0.001, 0.008, 0.012, 0.030, 0.041, 0.200])
                        m, order = len(p), np.argsort(p)
                        bonf = np.minimum(1, p * m)
                        # Holm: multiply the i-th smallest p by (m − i + 1), then never let the values decrease
                        holm_sorted = np.maximum.accumulate(np.minimum(1, (m - np.arange(m)) * p[order]))
                        # BH: multiply the i-th smallest p by m / i, then never let the values increase (from the top)
                        bh_sorted = np.minimum.accumulate((m / np.arange(1, m + 1) * p[order])[::-1])[::-1]
                        holm, bh = np.empty(m), np.empty(m)
                        holm[order], bh[order] = holm_sorted, np.minimum(1, bh_sorted)
                        check("Bonferroni", p_bonf, bonf, tol=1e-6)
                        check("Holm", p_holm, holm, tol=1e-6)
                        check("Benjamini–Hochberg", p_bh, bh, tol=1e-6)
                        print("significant at .05 —", "Bonferroni:", (bonf < .05).sum(), " Holm:", (holm < .05).sum(),
                              " BH:", (bh < .05).sum())

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      p <- c(0.001, 0.008, 0.012, 0.030, 0.041, 0.200)
                      m <- length(p); o <- order(p)
                      bonf <- pmin(1, p * m)
                      # Holm: multiply the i-th smallest p by (m − i + 1), then never let the values decrease
                      holm <- numeric(m); holm[o] <- cummax(pmin(1, (m - seq_len(m) + 1) * p[o]))
                      # BH: multiply the i-th smallest p by m / i, then never let the values increase (from the top)
                      bh <- numeric(m); bh[o] <- pmin(1, rev(cummin(rev(m / seq_len(m) * p[o]))))
                      check("Bonferroni", p_bonf, bonf, tol = 1e-6)
                      check("Holm", p_holm, holm, tol = 1e-6)
                      check("Benjamini–Hochberg", p_bh, bh, tol = 1e-6)
                      cat("significant at .05 — Bonferroni:", sum(bonf < .05), " Holm:", sum(holm < .05),
                          " BH:", sum(bh < .05), "\n")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Which correlations survive?",
                prompt: "Using the eight-correlation code above, store the raw p-values and count how many correlations stay significant after the Benjamini–Hochberg correction.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    n_sig_bh = int((multipletests(p_raw, method="fdr_bh")[1] < 0.05).sum())
                    print(n_sig_bh)
                    """#,
                    r: #"""
                    n_sig_bh <- sum(p.adjust(p_raw, "BH") < 0.05)
                    n_sig_bh
                    """#
                ),
                answer: "Social media, phone checking, and rumination — the variables on the data's causal path to anxiety — survive comfortably. Age, education, mindfulness, and the single mindfulness items have only weak, indirect links to anxiety, and the correction weeds them out.",
                selfCheck: SelfCheck(
                    names: "`p_raw` (the eight raw p-values, in the order listed) and `n_sig_bh`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        cols = ["age", "education", "social_media", "phone_checking", "rumination", "mindfulness", "mind_1", "mind_6"]
                        expected = []
                        for col in cols:
                            d = ref[[col, "anxiety"]].dropna()
                            r, n = d[col].corr(d["anxiety"]), len(d)
                            t = r * np.sqrt((n - 2) / (1 - r ** 2))          # t-test of a correlation
                            expected.append(2 * stats.t.sf(abs(t), n - 2))
                        expected = np.array(expected)
                        check("Raw p-values", p_raw, expected, tol=0.001, hint="Drop missing values pair by pair.")
                        # BH by hand: the largest i with p(i) ≤ (i / m) · .05 — everything up to it is significant
                        ok = np.sort(expected) <= np.arange(1, 9) / 8 * 0.05
                        check("Significant after BH", n_sig_bh, (np.max(np.where(ok)[0]) + 1) if ok.any() else 0, tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      cols <- c("age", "education", "social_media", "phone_checking", "rumination", "mindfulness", "mind_1", "mind_6")
                      expected <- sapply(cols, function(col) {
                        ok <- complete.cases(ref[[col]], ref$anxiety)
                        r <- cor(ref[[col]][ok], ref$anxiety[ok]); n <- sum(ok)
                        t <- r * sqrt((n - 2) / (1 - r^2))                 # t-test of a correlation
                        2 * pt(-abs(t), n - 2)
                      })
                      check("Raw p-values", p_raw, expected, tol = 0.001, hint = "Drop missing values pair by pair.")
                      # BH by hand: the largest i with p(i) ≤ (i / m) · .05 — everything up to it is significant
                      passes <- which(sort(expected) <= (1:8) / 8 * 0.05)
                      check("Significant after BH", n_sig_bh, if (length(passes)) max(passes) else 0, tol = 0)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "You run 10 independent tests at α = .05 and every null hypothesis is true. The chance of at least one p < .05 is about…",
                options: [".05", ".10", ".40", ".50"],
                answer: 2,
                explanation: "1 − .95¹⁰ ≈ .40."
            ),
            Question(
                prompt: "Compared with Bonferroni, Holm's procedure…",
                options: ["Controls a different error rate", "Is never less powerful, with the same FWER control", "Requires independent tests", "Only works for three tests"],
                answer: 1,
                explanation: "Holm is a uniformly more powerful step-down version of Bonferroni."
            ),
            Question(
                prompt: "Controlling the false discovery rate at 5% means…",
                options: [
                    "No false positives at all",
                    "About 5% of the results you call significant are expected to be false positives",
                    "Each test has a 5% error rate",
                    "5% of the tests are significant",
                ],
                answer: 1,
                explanation: "FDR is a proportion among the discoveries, not a per-test or family-wide probability."
            ),
        ]
    )

    static let repeatedMeasures = Lesson(
        id: "repeated-measures",
        title: "Repeated-measures & mixed ANOVA",
        summary: "Within-subject factors, sphericity, and designs that mix within and between factors.",
        minutes: 13,
        blocks: [
            .text("When every participant contributes to every condition, the conditions are **within-subject** factors. A repeated-measures ANOVA removes stable differences between people from the error term, so it's usually far more powerful than a between-subjects design. A **mixed ANOVA** adds a between-subject factor — the classic pre/post × group design."),
            .model(ModelExplainer(
                name: "Repeated-measures ANOVA",
                purpose: "Tests within-subject effects by comparing them with how inconsistently people respond to the conditions, after removing each person's overall level.",
                equation: "SS_total = SS_subjects + SS_condition + SS_subjects×condition        F = MS_condition / MS_subjects×condition",
                steps: [
                    "Aggregate the data to **one value per participant per cell** (e.g. the mean rating in each condition).",
                    "Split the variation into differences **between participants** (removed — they can't bias a within-subject effect), differences **between conditions**, and the participant × condition **inconsistency**, which serves as the error term.",
                    "F compares the condition effect with that inconsistency. For a factor with only two levels, F equals the squared paired t-statistic.",
                    "With 3+ levels, check **sphericity** (equal variances of all pairwise differences); if it's violated, the **Greenhouse–Geisser** correction (Greenhouse & Geisser, 1959) shrinks the df.",
                    "In a **mixed** ANOVA, the between-subject factor is tested against between-subject error and the within-subject parts against within-subject error. The interaction asks whether the within-subject effect differs between groups.",
                ],
                conditions: [
                    "**Complete data in every cell** for each participant (one missing cell drops the whole person).",
                    "**Approximately normal** differences between conditions, without extreme outliers.",
                    "**Sphericity** for factors with 3+ levels (or a correction).",
                    "For mixed designs, **similar covariance structures** across groups.",
                ],
                reading: "Maxwell, Delaney & Kelley (2018), *Designing Experiments and Analyzing Data* (3rd ed.), chs. 11–14; Bakeman (2005), *Behavior Research Methods*, 37(3), 379–384 (generalized eta squared)."
            )),
            .terms([
                Term("Within-subject factor", "A factor whose levels every participant experiences, e.g. sentence structure."),
                Term("Between-subject factor", "A factor that splits participants into separate groups, e.g. teaching method."),
                Term("Mixed (split-plot) ANOVA", "An ANOVA with at least one within- and one between-subject factor."),
                Term("Generalized eta squared (η²G)", "An effect size comparable across within- and between-subject designs; reported as `ges` by afex and `ng2` by pingouin."),
                Term("Greenhouse–Geisser correction", "Reduces the degrees of freedom when sphericity is violated; ε = 1 means no violation."),
            ]),
            .code(CodeSample(
                caption: "A 2 × 2 repeated-measures ANOVA on acceptability ratings",
                python: #"""
                import pandas as pd
                import pingouin as pg

                judgments = pd.read_csv("judgments.csv")

                # One mean per participant per condition: repeated-measures ANOVA needs exactly one value per cell
                cells = judgments.groupby(["participant", "structure", "distance"], as_index=False)["rating"].mean()

                aov = pg.rm_anova(data=cells, dv="rating", within=["structure", "distance"], subject="participant")
                print(aov.round(4))
                """#,
                r: #"""
                library(tidyverse)
                library(afex)

                judgments <- read_csv("judgments.csv")

                # afex averages the trials into one value per participant per condition
                fit <- aov_ez(id = "participant", dv = "rating", data = judgments,
                              within = c("structure", "distance"), fun_aggregate = mean)
                fit                        # F tests with generalized eta squared (ges)
                """#
            )),
            .code(CodeSample(
                caption: "A mixed ANOVA: pre/post (within) × teaching method (between)",
                python: #"""
                classroom = pd.read_csv("classroom.csv")
                long = classroom.melt(id_vars=["student", "method"], value_vars=["pretest", "posttest"],
                                      var_name="time", value_name="score")

                aov2 = pg.mixed_anova(data=long, dv="score", within="time", between="method", subject="student")
                print(aov2.round(4))       # the Interaction row: does change over time differ by method?
                """#,
                r: #"""
                classroom <- read_csv("classroom.csv")
                long <- classroom |>
                  pivot_longer(c(pretest, posttest), names_to = "time", values_to = "score")

                fit2 <- aov_ez(id = "student", dv = "score", data = long, within = "time", between = "method")
                fit2
                summary(fit2)              # with 3+ within levels this also shows Mauchly's test and GG corrections
                """#
            )),
            .keyPoint("In pre/post designs, the interaction is the test", "In a randomized pre/post study, the main effect of time just says scores changed and the main effect of group mixes in baseline differences. The **time × group interaction** asks whether change differed between groups — exactly the same F as a one-way ANOVA on change scores. ANCOVA (*ANCOVA & contrast coding*) is usually more powerful still."),
            .caution("Aggregating trials, or modelling them", "Repeated-measures ANOVA needs one number per person per cell, so trial-level data must be averaged first. That ignores item variability and drops anyone with an empty cell. A mixed-effects model (Unit 7) uses every trial, handles missing cells, and can add item random effects."),
            .field(.psychology, "Most cognitive experiments — Stroop, priming, memory — are within-subject designs analyzed with repeated-measures ANOVA or, increasingly, mixed-effects models."),
            .exercise(Exercise(
                title: "Two-level effects are paired t-tests",
                prompt: "From the 2 × 2 repeated-measures ANOVA, store the F for `structure` and for the `structure × distance` interaction. Then confirm each equals a squared one-sample t on a per-participant contrast.",
                hint: "Structure: each person's (complex − simple) mean. Interaction: each person's (complex short − complex long) − (simple short − simple long).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    F_structure = aov.loc[aov["Source"] == "structure", "F"].iloc[0]
                    F_inter = aov.loc[aov["Source"] == "structure * distance", "F"].iloc[0]
                    print(F_structure, F_inter)
                    """#,
                    r: #"""
                    F_structure <- fit$anova_table["structure", "F"]
                    F_inter <- fit$anova_table["structure:distance", "F"]
                    c(F_structure, F_inter)
                    """#
                ),
                answer: "Both match exactly: with two levels, a repeated-measures F is the square of a paired (one-sample on differences) t. The interaction is large, as the built-in truth says — long distance hurts complex sentences most.",
                selfCheck: SelfCheck(
                    names: "`F_structure` and `F_inter`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        m = (pd.read_csv("judgments.csv")
                             .groupby(["participant", "structure", "distance"])["rating"].mean().unstack(["structure", "distance"]))
                        cs, cl, ss, sl = m[("complex", "short")], m[("complex", "long")], m[("simple", "short")], m[("simple", "long")]

                        def t_squared(contrast):
                            return (contrast.mean() / (contrast.std() / np.sqrt(len(contrast)))) ** 2

                        check("F for structure", F_structure, t_squared((cs + cl) / 2 - (ss + sl) / 2), tol=0.001,
                              hint="Average to one rating per participant per cell first.")
                        check("F for structure × distance", F_inter, t_squared((cs - cl) - (ss - sl)), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("judgments.csv")
                      m <- with(ref, tapply(rating, list(participant, paste(structure, distance)), mean))
                      cs <- m[, "complex short"]; cl <- m[, "complex long"]
                      ss <- m[, "simple short"];  sl <- m[, "simple long"]
                      t_squared <- function(contrast) (mean(contrast) / (sd(contrast) / sqrt(length(contrast))))^2
                      check("F for structure", F_structure, t_squared((cs + cl) / 2 - (ss + sl) / 2), tol = 0.001,
                            hint = "Average to one rating per participant per cell first.")
                      check("F for structure × distance", F_inter, t_squared((cs - cl) - (ss - sl)), tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "The interaction is a change-score ANOVA",
                prompt: "From the mixed ANOVA, store the F for the time × method interaction. Then show it equals a one-way ANOVA on change scores (post − pre) across methods.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    F_time_method = aov2.loc[aov2["Source"] == "Interaction", "F"].iloc[0]
                    classroom["change"] = classroom["posttest"] - classroom["pretest"]
                    print(F_time_method, pg.anova(data=classroom, dv="change", between="method")["F"].iloc[0])
                    """#,
                    r: #"""
                    F_time_method <- fit2$anova_table["method:time", "F"]
                    classroom <- classroom |> mutate(change = posttest - pretest)
                    c(F_time_method, summary(aov(change ~ method, data = classroom))[[1]][["F value"]][1])
                    """#
                ),
                answer: "The two F values are identical. With two time points, “does change differ by group?” is the same question either way.",
                selfCheck: SelfCheck(
                    names: "`F_time_method`",
                    python: #"""
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("classroom.csv")
                        ref["change"] = ref["posttest"] - ref["pretest"]
                        expected = stats.f_oneway(*[g["change"] for _, g in ref.groupby("method")]).statistic
                        check("Time × method F", F_time_method, expected, tol=0.001,
                              hint="Use the interaction row, not the main effect of time or method.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("classroom.csv")
                      ref$change <- ref$posttest - ref$pretest
                      expected <- oneway.test(change ~ method, data = ref, var.equal = TRUE)$statistic[[1]]
                      check("Time × method F", F_time_method, expected, tol = 0.001,
                            hint = "Use the interaction row, not the main effect of time or method.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Why is a within-subject design usually more powerful than a between-subject design with the same number of observations?",
                options: ["It uses a smaller α", "Stable differences between people are removed from the error term", "It doesn't need normality", "It has more degrees of freedom by definition"],
                answer: 1,
                explanation: "Each person serves as their own control."
            ),
            Question(
                prompt: "Sphericity only needs checking when a within-subject factor has…",
                options: ["2 levels", "3 or more levels", "Missing data", "A between-subject partner"],
                answer: 1,
                explanation: "With two levels there's only one difference, so sphericity holds automatically."
            ),
            Question(
                prompt: "In a pre/post × group mixed ANOVA, which effect tests whether the intervention changed scores more than the control?",
                options: ["Main effect of time", "Main effect of group", "Time × group interaction", "The intercept"],
                answer: 2,
                explanation: "The interaction tests whether change differs between groups."
            ),
        ]
    )

    static let equivalence = Lesson(
        id: "equivalence",
        title: "Equivalence tests",
        summary: "TOST, smallest effects of interest, and why p > .05 isn't evidence of no effect.",
        minutes: 11,
        blocks: [
            .text("A non-significant result says the data are compatible with no effect — but often also with a sizeable one. To claim an effect is **absent, or too small to matter**, you need an **equivalence test**: first decide the smallest effect you'd care about, then test whether the effect is reliably smaller than that."),
            .model(ModelExplainer(
                name: "Two one-sided tests (TOST)",
                purpose: "Tests whether an effect lies within a pre-specified band of values considered practically equivalent to zero.",
                equation: "H₀₁: Δ ≤ −bound    H₀₂: Δ ≥ +bound        p_TOST = max(p₁, p₂)        equivalent ⇔ 90% CI inside (−bound, +bound)",
                steps: [
                    "Choose the **smallest effect size of interest** (SESOI) before seeing the data, e.g. ±0.3 points on a 1–7 scale or d = ±0.3.",
                    "Test whether the effect is **above the lower bound** (one-sided test 1) and **below the upper bound** (one-sided test 2).",
                    "If both are significant, the effect is statistically **equivalent** to zero: too small to matter. The TOST p-value is the larger of the two.",
                    "Equivalently, check whether the **90% CI** (not 95%, because each one-sided test uses α = .05) lies entirely within the bounds.",
                    "Report it alongside the usual difference test — the two together give one of four conclusions.",
                ],
                conditions: [
                    "**Bounds justified in advance** — by theory, practical importance, or the smallest effect detectable with your resources.",
                    "The usual assumptions of the underlying test (here, Welch's t-test).",
                    "**Enough power** — demonstrating equivalence typically needs larger samples than detecting a difference.",
                ],
                reading: "Lakens (2017), *Social Psychological and Personality Science*, 8(4), 355–362; Lakens, Scheel & Isager (2018), *Advances in Methods and Practices in Psychological Science*, 1(2), 259–269."
            )),
            .terms([
                Term("Smallest effect size of interest (SESOI)", "The smallest effect that would matter theoretically or practically; it defines the equivalence bounds."),
                Term("Equivalence bounds", "The interval (−bound, +bound) of effects treated as practically zero."),
                Term("TOST", "Two one-sided tests: one against each bound."),
                Term("Absence of evidence", "A non-significant difference test — the effect might still be large."),
                Term("Evidence of absence", "A significant equivalence test — the effect is reliably smaller than the SESOI."),
            ]),
            .code(CodeSample(
                caption: "Is anxiety equivalent in urban and rural respondents? (bounds ±0.3 points)",
                python: #"""
                import numpy as np
                import pandas as pd
                from scipy import stats

                survey = pd.read_csv("survey.csv")
                urban = survey.loc[survey["region"] == "urban", "anxiety"]
                rural = survey.loc[survey["region"] == "rural", "anxiety"]
                bound = 0.3        # smallest difference we'd care about, chosen in advance

                # Two one-sided Welch tests: is the difference above −0.3 AND below +0.3?
                p_lower = stats.ttest_ind(urban + bound, rural, equal_var=False, alternative="greater").pvalue
                p_upper = stats.ttest_ind(urban - bound, rural, equal_var=False, alternative="less").pvalue
                p_tost = max(p_lower, p_upper)
                diff = urban.mean() - rural.mean()
                print(f"difference = {diff:.3f}, TOST p = {p_tost:.4f}")

                # The same decision from a 90% CI: equivalent if it sits entirely inside (−0.3, +0.3)
                v1, v2 = urban.var() / len(urban), rural.var() / len(rural)
                se = np.sqrt(v1 + v2)
                df = (v1 + v2) ** 2 / (v1 ** 2 / (len(urban) - 1) + v2 ** 2 / (len(rural) - 1))
                print("90% CI:", diff + np.array([-1, 1]) * stats.t.ppf(0.95, df) * se)

                # And the ordinary two-sided test of a difference
                print("difference test p =", stats.ttest_ind(urban, rural, equal_var=False).pvalue)
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")
                urban <- survey$anxiety[survey$region == "urban"]
                rural <- survey$anxiety[survey$region == "rural"]
                bound <- 0.3       # smallest difference we'd care about, chosen in advance

                # Two one-sided Welch tests: is the difference above −0.3 AND below +0.3?
                p_lower <- t.test(urban, rural, mu = -bound, alternative = "greater")$p.value
                p_upper <- t.test(urban, rural, mu =  bound, alternative = "less")$p.value
                p_tost  <- max(p_lower, p_upper)
                p_tost

                # The same decision from a 90% CI
                t.test(urban, rural, conf.level = 0.90)$conf.int

                # The ordinary two-sided test, and the TOSTER package's all-in-one version
                t.test(urban, rural)$p.value
                TOSTER::t_TOST(x = urban, y = rural, eqb = bound)
                """#
            )),
            .keyPoint("Four possible conclusions", "Combine the difference test and the equivalence test:\n• **Different, not equivalent** — a meaningful effect.\n• **Equivalent, not different** — no meaningful effect.\n• **Different *and* equivalent** — a real but trivially small effect (common with huge samples).\n• **Neither** — inconclusive: the study can't tell. Most “null results” are this one."),
            .caution("Set the bounds before you look", "Choosing bounds after seeing the CI makes equivalence guaranteed. Preregister them, and justify them in substantive terms (scale points, minutes, percentage points), not just “d = 0.5 is medium”."),
            .field(.psychology, "Replication studies often pair a difference test with an equivalence test against the smallest effect the original study could have detected, to judge whether a failed replication is informative."),
            .exercise(Exercise(
                title: "Urban vs. rural anxiety",
                prompt: "Run the TOST above. Store the TOST p-value and the 90% CI. Is anxiety statistically equivalent across regions within ±0.3 points?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    ci90 = diff + np.array([-1, 1]) * stats.t.ppf(0.95, df) * se
                    print(p_tost, ci90)
                    """#,
                    r: #"""
                    ci90 <- t.test(urban, rural, conf.level = 0.90)$conf.int
                    c(p_tost, ci90)
                    """#
                ),
                answer: "The generated data have no built-in regional difference, but whether you can *demonstrate* that depends on your sample. Often the 90% CI sits inside ±0.3 and the TOST is significant (p < .01) — evidence of absence. In other samples the observed difference is a little larger and the TOST just misses (p ≈ .08) — inconclusive. The ordinary difference test is non-significant either way, which on its own can't tell those two situations apart.",
                selfCheck: SelfCheck(
                    names: "`p_tost` and `ci90` (as [lower, upper])",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        u = ref.loc[ref["region"] == "urban", "anxiety"].to_numpy()
                        r = ref.loc[ref["region"] == "rural", "anxiety"].to_numpy()
                        v1, v2 = u.var(ddof=1) / len(u), r.var(ddof=1) / len(r)
                        se = np.sqrt(v1 + v2)
                        df = (v1 + v2) ** 2 / (v1 ** 2 / (len(u) - 1) + v2 ** 2 / (len(r) - 1))   # Welch df
                        d = u.mean() - r.mean()
                        p1 = stats.t.sf((d + 0.3) / se, df)      # H₀: difference ≤ −0.3
                        p2 = stats.t.cdf((d - 0.3) / se, df)     # H₀: difference ≥ +0.3
                        check("TOST p (the larger one-sided p)", p_tost, max(p1, p2), tol=0.001)
                        check("90% CI", ci90, d + np.array([-1, 1]) * stats.t.ppf(0.95, df) * se, tol=0.001,
                              hint="A 90% CI, not 95%.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      u <- ref$anxiety[ref$region == "urban"]; r <- ref$anxiety[ref$region == "rural"]
                      v1 <- var(u) / length(u); v2 <- var(r) / length(r)
                      se <- sqrt(v1 + v2)
                      df <- (v1 + v2)^2 / (v1^2 / (length(u) - 1) + v2^2 / (length(r) - 1))   # Welch df
                      d <- mean(u) - mean(r)
                      p1 <- pt((d + 0.3) / se, df, lower.tail = FALSE)   # H₀: difference ≤ −0.3
                      p2 <- pt((d - 0.3) / se, df)                       # H₀: difference ≥ +0.3
                      check("TOST p (the larger one-sided p)", p_tost, max(p1, p2), tol = 0.001)
                      check("90% CI", ci90, d + c(-1, 1) * qt(0.95, df) * se, tol = 0.001, hint = "A 90% CI, not 95%.")
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Is flipped teaching equivalent to lecture?",
                prompt: "In `classroom.csv`, test whether flipped and lecture post-test scores are equivalent within ±5 points. Store the TOST p-value and whether you can claim equivalence at α = .05.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    classroom = pd.read_csv("classroom.csv")
                    flip = classroom.loc[classroom["method"] == "flipped", "posttest"]
                    lect = classroom.loc[classroom["method"] == "lecture", "posttest"]
                    p_tost_flip = max(stats.ttest_ind(flip + 5, lect, equal_var=False, alternative="greater").pvalue,
                                      stats.ttest_ind(flip - 5, lect, equal_var=False, alternative="less").pvalue)
                    equivalent = p_tost_flip < 0.05
                    print(p_tost_flip, equivalent)
                    """#,
                    r: #"""
                    classroom <- read_csv("classroom.csv")
                    flip <- classroom$posttest[classroom$method == "flipped"]
                    lect <- classroom$posttest[classroom$method == "lecture"]
                    p_tost_flip <- max(t.test(flip, lect, mu = -5, alternative = "greater")$p.value,
                                       t.test(flip, lect, mu =  5, alternative = "less")$p.value)
                    equivalent <- p_tost_flip < 0.05
                    c(p_tost_flip, equivalent)
                    """#
                ),
                answer: "The true difference is about 1 point, but with 50 students per group the 90% CI is roughly ±3.5 points wide, so the result depends on the sample: sometimes equivalent, sometimes inconclusive. That's the power problem of equivalence testing in miniature.",
                selfCheck: SelfCheck(
                    names: "`p_tost_flip` and `equivalent` (True/False)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("classroom.csv")
                        f = ref.loc[ref["method"] == "flipped", "posttest"].to_numpy(float)
                        l = ref.loc[ref["method"] == "lecture", "posttest"].to_numpy(float)
                        v1, v2 = f.var(ddof=1) / len(f), l.var(ddof=1) / len(l)
                        se, d = np.sqrt(v1 + v2), f.mean() - l.mean()
                        df = (v1 + v2) ** 2 / (v1 ** 2 / (len(f) - 1) + v2 ** 2 / (len(l) - 1))
                        expected = max(stats.t.sf((d + 5) / se, df), stats.t.cdf((d - 5) / se, df))
                        check("TOST p", p_tost_flip, expected, tol=0.001, hint="Bounds are ±5 points.")
                        check("Equivalence decision", bool(equivalent), bool(expected < 0.05))

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("classroom.csv")
                      f <- ref$posttest[ref$method == "flipped"]; l <- ref$posttest[ref$method == "lecture"]
                      v1 <- var(f) / length(f); v2 <- var(l) / length(l)
                      se <- sqrt(v1 + v2); d <- mean(f) - mean(l)
                      df <- (v1 + v2)^2 / (v1^2 / (length(f) - 1) + v2^2 / (length(l) - 1))
                      expected <- max(pt((d + 5) / se, df, lower.tail = FALSE), pt((d - 5) / se, df))
                      check("TOST p", p_tost_flip, expected, tol = 0.001, hint = "Bounds are ±5 points.")
                      check("Equivalence decision", as.logical(equivalent), expected < 0.05)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A study finds p = .40 for a group difference. What can you conclude?",
                options: ["The groups are the same", "The data don't show a difference; an equivalence test is needed to claim there isn't a meaningful one", "The effect is exactly zero", "The study was well powered"],
                answer: 1,
                explanation: "Non-significance is absence of evidence, not evidence of absence."
            ),
            Question(
                prompt: "Why does an equivalence test at α = .05 use a 90% CI?",
                options: ["It's more conservative", "Each of the two one-sided tests uses α = .05", "90% is the journal standard", "Because the bounds are symmetric"],
                answer: 1,
                explanation: "Two one-sided tests at .05 correspond to the two ends of a 90% interval."
            ),
            Question(
                prompt: "A huge study finds a significant difference of 0.02 points, and it's also equivalent within ±0.2. This means…",
                options: ["The study failed", "A real but practically trivial effect", "The equivalence bounds were wrong", "The effect is large"],
                answer: 1,
                explanation: "Both tests can be significant when an effect is reliably non-zero but smaller than the SESOI."
            ),
        ]
    )
}

// MARK: - Unit 5 · Regression diagnostics

extension Curriculum {
    static let regressionDiagnostics = Lesson(
        id: "regression-diagnostics",
        title: "Regression diagnostics & robust SEs",
        summary: "Residual plots, influential points, heteroskedasticity, and what to do about them.",
        minutes: 13,
        blocks: [
            .text("A regression table is only as trustworthy as the model behind it. **Diagnostics** check the assumptions with the residuals — the parts of the data the model didn't explain — and look for single observations that pull the results around."),
            .model(ModelExplainer(
                name: "Checking a fitted regression",
                purpose: "Uses residuals, leverage, and influence measures to check linearity, constant variance, and normality, and to find observations that change the conclusions.",
                equation: "Cook's Dᵢ = [eᵢ² / (p · MSE)] · hᵢᵢ / (1 − hᵢᵢ)²        HC3: Var(b) = (X′X)⁻¹ X′ diag[eᵢ² / (1 − hᵢᵢ)²] X (X′X)⁻¹",
                steps: [
                    "**Residuals vs. fitted values:** a shapeless band around 0 is good. A curve means a missed nonlinearity; a funnel means non-constant variance (**heteroskedasticity**).",
                    "**Q–Q plot of residuals:** points near the line mean roughly normal errors. Normality matters least of all the conditions in large samples.",
                    "**Leverage** hᵢᵢ measures how unusual a case's *predictor* values are; **studentized residuals** measure how unusual its *outcome* is given the model.",
                    "**Cook's distance** combines both: how much all fitted values would move if the case were dropped. Values above about 4/n deserve a look, and above 1 are serious.",
                    "If the variance isn't constant, **heteroskedasticity-consistent (HC3) standard errors** keep the coefficients but fix their SEs, CIs, and p-values.",
                ],
                conditions: [
                    "Diagnostics are judgment calls: look at plots, don't just run tests.",
                    "**Investigate** influential cases (data errors? a different population?) and report results with and without them, rather than silently deleting them.",
                    "Robust SEs fix inference about the coefficients, not a misspecified model — a curved relationship still needs a better model.",
                ],
                reading: "OpenIntro Statistics (4th ed.), §8.3 (types of outliers in linear regression) and §9.3 (checking model conditions using graphs); Long & Ervin (2000), *The American Statistician*, 54(3), 217–224 (HC3)."
            )),
            .terms([
                Term("Residual", "Observed minus predicted outcome for one case."),
                Term("Leverage", "How far a case's predictor values are from the average; high-leverage cases can tilt the line."),
                Term("Studentized residual", "A residual divided by its estimated SD with that case left out; beyond about ±3 is unusual."),
                Term("Cook's distance", "How much the fitted model changes when one case is removed."),
                Term("Heteroskedasticity", "Residual spread that changes with the fitted values or a predictor."),
                Term("HC3 robust standard errors", "Standard errors that stay valid when the residual variance isn't constant."),
                Term("Breusch–Pagan test", "A test of whether residual variance depends on the predictors."),
            ]),
            .code(CodeSample(
                caption: "Residual plots, leverage, and influence",
                python: #"""
                import numpy as np
                import pandas as pd
                import matplotlib.pyplot as plt
                import statsmodels.api as sm
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                model = smf.ols("anxiety ~ rumination + social_media + age", data=survey).fit()

                # 1. Residuals vs. fitted (linearity, constant spread) and a Q–Q plot (normality)
                fig, axes = plt.subplots(1, 2, figsize=(9, 3.8))
                axes[0].scatter(model.fittedvalues, model.resid, alpha=0.4)
                axes[0].axhline(0, color="0.5", linestyle="--")
                axes[0].set(xlabel="Fitted values", ylabel="Residuals")
                sm.qqplot(model.resid, line="s", ax=axes[1])
                plt.tight_layout(); plt.show()

                # 2. Leverage and influence for every case
                infl = model.get_influence()
                diag = pd.DataFrame({"leverage": infl.hat_matrix_diag,
                                     "student_resid": infl.resid_studentized_external,
                                     "cooks_d": infl.cooks_distance[0]})
                print(diag.sort_values("cooks_d", ascending=False).head().round(3))
                print("4/n =", round(4 / model.nobs, 4))
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")
                model <- lm(anxiety ~ rumination + social_media + age, data = survey)

                # 1. The four standard diagnostic plots
                par(mfrow = c(2, 2)); plot(model); par(mfrow = c(1, 1))

                # 2. Leverage and influence for every case
                diag <- tibble(row = seq_len(nobs(model)),
                               leverage = hatvalues(model),
                               student_resid = rstudent(model),
                               cooks_d = cooks.distance(model))
                diag |> arrange(desc(cooks_d)) |> head()
                4 / nobs(model)
                """#
            )),
            .code(CodeSample(
                caption: "Testing for heteroskedasticity, and robust (HC3) standard errors",
                python: #"""
                from statsmodels.stats.diagnostic import het_breuschpagan

                lm_stat, lm_p, f_stat, f_p = het_breuschpagan(model.resid, model.model.exog)
                print("Breusch–Pagan p =", round(lm_p, 4))

                robust = smf.ols("anxiety ~ rumination + social_media + age", data=survey).fit(cov_type="HC3")
                print(pd.DataFrame({"classic SE": model.bse, "HC3 SE": robust.bse}).round(4))
                """#,
                r: #"""
                library(lmtest)
                library(sandwich)

                bptest(model)                                         # Breusch–Pagan test
                coeftest(model, vcov = vcovHC(model, type = "HC3"))   # HC3 robust standard errors
                """#
            )),
            .keyPoint("Robust SEs are cheap insurance", "If classic and HC3 standard errors agree, nothing is lost by reporting either. If they disagree, the classic ones are the ones you can't trust. Many fields now report HC3 SEs by default."),
            .caution("Don't delete points just because they're influential", "An influential case might be a data-entry error (fix it), a participant from outside the target population (exclude by a pre-stated rule), or a real but unusual person (keep them, and report how much they matter). Deciding after seeing which choice gives p < .05 is a researcher degree of freedom."),
            .field(.sociology, "Income, wealth, and city size are classic sources of heteroskedasticity and high leverage: a few very large values dominate. Log transformations and robust SEs are standard tools."),
            .exercise(Exercise(
                title: "Plant an outlier",
                prompt: "Add one fake respondent with rumination = 7, social_media = 7, age = 40, and anxiety = 1, and refit the model. Store that row's Cook's distance and how much the rumination coefficient changed.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    fake = pd.DataFrame({"rumination": [7.0], "social_media": [7.0], "age": [40], "anxiety": [1.0]})
                    with_fake = pd.concat([survey, fake], ignore_index=True)
                    m_fake = smf.ols("anxiety ~ rumination + social_media + age", data=with_fake).fit()
                    cooks_new = m_fake.get_influence().cooks_distance[0][-1]
                    b_change = m_fake.params["rumination"] - model.params["rumination"]
                    print(round(cooks_new, 3), round(b_change, 3))
                    """#,
                    r: #"""
                    fake <- tibble(rumination = 7, social_media = 7, age = 40, anxiety = 1)
                    with_fake <- bind_rows(survey, fake)
                    m_fake <- lm(anxiety ~ rumination + social_media + age, data = with_fake)
                    cooks_new <- unname(tail(cooks.distance(m_fake), 1))
                    b_change <- coef(m_fake)[["rumination"]] - coef(model)[["rumination"]]
                    round(c(cooks_new, b_change), 3)
                    """#
                ),
                answer: "One implausible case — maximum rumination and social media but minimal anxiety — gets a Cook's distance of about 0.3, nearly 30 times the 4/n rule of thumb, and pulls the rumination slope down by about 0.03 on its own. That's how much one point can matter even among 375 others.",
                selfCheck: SelfCheck(
                    names: "`cooks_new` (Cook's D for the added row) and `b_change` (new minus old rumination coefficient)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        X0 = np.column_stack([np.ones(len(ref)), ref[["rumination", "social_media", "age"]]])
                        y0 = ref["anxiety"].to_numpy()
                        X = np.vstack([X0, [1, 7, 7, 40]])
                        y = np.append(y0, 1.0)
                        b = np.linalg.lstsq(X, y, rcond=None)[0]
                        e = y - X @ b
                        n, p = X.shape
                        h = X[-1] @ np.linalg.inv(X.T @ X) @ X[-1]               # leverage of the new row
                        mse = e @ e / (n - p)
                        check("Cook's D for the new row", cooks_new, e[-1] ** 2 / (p * mse) * h / (1 - h) ** 2, tol=0.001)
                        b_old = np.linalg.lstsq(X0, y0, rcond=None)[0]
                        check("Change in the rumination coefficient", b_change, b[1] - b_old[1], tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      X0 <- cbind(1, as.matrix(ref[c("rumination", "social_media", "age")]))
                      y0 <- ref$anxiety
                      X <- rbind(X0, c(1, 7, 7, 40)); y <- c(y0, 1)
                      b <- solve(crossprod(X), crossprod(X, y))
                      e <- y - X %*% b
                      n <- nrow(X); p <- ncol(X)
                      h <- X[n, ] %*% solve(crossprod(X)) %*% X[n, ]           # leverage of the new row
                      mse <- sum(e^2) / (n - p)
                      check("Cook's D for the new row", cooks_new, e[n]^2 / (p * mse) * h / (1 - h)^2, tol = 0.001)
                      b_old <- solve(crossprod(X0), crossprod(X0, y0))
                      check("Change in the rumination coefficient", b_change, b[2] - b_old[2], tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "HC3 by hand",
                prompt: "Store the HC3 robust standard error of the rumination coefficient from the original model. How different is it from the classic SE?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    se_hc3 = robust.bse["rumination"]
                    print(se_hc3, model.bse["rumination"])
                    """#,
                    r: #"""
                    se_hc3 <- sqrt(diag(vcovHC(model, type = "HC3")))[["rumination"]]
                    c(se_hc3, coef(summary(model))["rumination", "Std. Error"])
                    """#
                ),
                answer: "The two SEs are close, because the generated data have roughly constant variance. With strongly heteroskedastic data — incomes, reaction times, counts — they can differ a lot.",
                selfCheck: SelfCheck(
                    names: "`se_hc3`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # The sandwich: (X'X)⁻¹ · X' diag(eᵢ² / (1 − hᵢ)²) X · (X'X)⁻¹
                        ref = pd.read_csv("survey.csv")
                        X = np.column_stack([np.ones(len(ref)), ref[["rumination", "social_media", "age"]]])
                        y = ref["anxiety"].to_numpy()
                        bread = np.linalg.inv(X.T @ X)
                        e = y - X @ (bread @ X.T @ y)
                        h = np.einsum("ij,jk,ik->i", X, bread, X)
                        meat = X.T @ (X * (e ** 2 / (1 - h) ** 2)[:, None])
                        check("HC3 SE for rumination", se_hc3, np.sqrt((bread @ meat @ bread)[1, 1]), tol=0.001,
                              hint="HC3 specifically — not HC0 or HC1.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # The sandwich: (X'X)⁻¹ · X' diag(eᵢ² / (1 − hᵢ)²) X · (X'X)⁻¹
                      ref <- read.csv("survey.csv")
                      X <- cbind(1, as.matrix(ref[c("rumination", "social_media", "age")]))
                      y <- ref$anxiety
                      bread <- solve(crossprod(X))
                      e <- as.vector(y - X %*% (bread %*% crossprod(X, y)))
                      h <- rowSums((X %*% bread) * X)
                      meat <- crossprod(X * (e^2 / (1 - h)^2), X)
                      check("HC3 SE for rumination", se_hc3, sqrt((bread %*% meat %*% bread)[2, 2]), tol = 0.001,
                            hint = "HC3 specifically — not HC0 or HC1.")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A residuals-vs-fitted plot fans out (wider spread at higher fitted values). This suggests…",
                options: ["Nonlinearity", "Heteroskedasticity", "Multicollinearity", "Perfect fit"],
                answer: 1,
                explanation: "Changing spread means non-constant variance."
            ),
            Question(
                prompt: "A case has high leverage but sits right on the regression line. Its Cook's distance is likely…",
                options: ["Large", "Small", "Negative", "Undefined"],
                answer: 1,
                explanation: "Influence needs both leverage and a large residual."
            ),
            Question(
                prompt: "HC3 robust standard errors change…",
                options: ["The coefficients", "The SEs, CIs, and p-values but not the coefficients", "R²", "The residuals"],
                answer: 1,
                explanation: "Robust SEs only change the estimated uncertainty."
            ),
        ]
    )
}

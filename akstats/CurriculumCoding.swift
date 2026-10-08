import Foundation

// MARK: - Unit 0 · Getting started

extension Curriculum {
    static let gettingStarted = Unit(
        id: "getting-started", number: 0, title: "Getting started", level: .beginner,
        summary: "VS Code, coding basics, practice data, and reading output.",
        symbol: "chevron.left.forwardslash.chevron.right",
        lessons: [vsCode, pythonVersusR, pythonBasics, rBasics, practiceData, readingOutput]
    )

    static let vsCode = Lesson(
        id: "vs-code",
        title: "Setting up VS Code",
        summary: "One editor for both Python and R.",
        minutes: 10,
        blocks: [
            .text("**Visual Studio Code** (VS Code) is a free editor that runs Python and R side by side. You write code in a *script* (a text file ending in `.py` or `.R`), then send it to a running language session that executes it and prints results."),
            .steps("Install everything once", [
                "Download and install **VS Code** from code.visualstudio.com.",
                "Install **Python** (3.11 or newer) from python.org. On Windows, tick *“Add python.exe to PATH”*.",
                "Install **R** from cran.r-project.org.",
                "In VS Code, open the **Extensions** panel (the four-squares icon) and install: **Python** and **Jupyter** (both by Microsoft) and **R** (by REditorSupport).",
                "Open R once (from the Start menu or Applications) and run `install.packages(\"languageserver\")` so VS Code can autocomplete R code.",
            ]),
            .steps("Create a project", [
                "Make a new folder, e.g. `stats-practice`, then choose **File → Open Folder…** in VS Code.",
                "Open the terminal with **View → Terminal**. Create a Python virtual environment: `python -m venv .venv` (use `python3` on macOS).",
                "Activate it — macOS/Linux: `source .venv/bin/activate` · Windows: `.venv\\Scripts\\activate`.",
                "Install the packages: `pip install pandas numpy scipy statsmodels pingouin seaborn matplotlib scikit-learn ipykernel`.",
                "Press **Cmd/Ctrl + Shift + P**, run **Python: Select Interpreter**, and pick the `.venv` one.",
                "In an R terminal (Command Palette → **R: Create R terminal**), run `install.packages(c(\"tidyverse\", \"lavaan\", \"psych\", \"emmeans\", \"interactions\", \"lme4\", \"lmerTest\", \"pwr\", \"rpact\", \"openintro\"))`.",
            ]),
            .steps("Running code", [
                "**Whole Python file:** click the ▷ *Run* button at the top right of a `.py` file.",
                "**Python line by line:** select lines and press **Shift + Enter** to send them to a Python terminal.",
                "**Python cells:** type `# %%` on its own line to start a *cell*. Click **Run Cell** above it to see output — including plots — in the Interactive window.",
                "**R line by line:** put the cursor on a line (or select several) and press **Cmd/Ctrl + Enter**.",
                "**Whole R file:** press **Cmd/Ctrl + Shift + S** to *source* the file.",
            ]),
            .code(CodeSample(
                caption: "A first script with cells — paste into analysis.py / analysis.R",
                python: #"""
                # %% Load packages
                import pandas as pd

                # %% Make a tiny dataset and summarize it
                df = pd.DataFrame({"group": ["a", "a", "b", "b"],
                                   "score": [3, 5, 4, 6]})
                print(df.groupby("group")["score"].mean())
                """#,
                r: #"""
                # Put the cursor on each line and press Cmd/Ctrl + Enter
                library(tidyverse)

                df <- tibble(group = c("a", "a", "b", "b"),
                             score = c(3, 5, 4, 6))

                df |> group_by(group) |> summarise(mean = mean(score))
                """#
            )),
            .terms([
                Term("Script", "A text file of code you can rerun from top to bottom."),
                Term("Terminal / console", "Where code runs and results print. Also called a REPL (read–evaluate–print loop)."),
                Term("Interpreter", "The program that runs your code — a specific Python or R installation."),
                Term("Virtual environment", "A project-specific folder of Python packages, so projects don't conflict."),
                Term("Extension", "An add-on that teaches VS Code a language."),
                Term("Working directory", "The folder your code reads files from and saves files to."),
            ]),
            .caution("“File not found” errors", "Code like `read_csv(\"survey.csv\")` looks in the **working directory**. Open your project folder in VS Code (File → Open Folder) and keep data files inside it. Check the current folder with `import os; os.getcwd()` in Python or `getwd()` in R."),
            .keyPoint("Alternatives", "RStudio and Positron are popular R-focused editors; Jupyter notebooks (`.ipynb`) also open directly in VS Code. Every code sample in this app works in any of them."),
        ],
        quiz: [
            Question(
                prompt: "In a VS Code Python file, what does a line containing only `# %%` do?",
                options: ["Comments out the file", "Starts a runnable cell", "Imports pandas", "Nothing"],
                answer: 1,
                explanation: "With the Jupyter extension, `# %%` splits a script into cells you can run one at a time."
            ),
            Question(
                prompt: "Your script can't find survey.csv, but the file exists. What's the most likely cause?",
                options: ["The CSV is corrupted", "The working directory is a different folder", "pandas isn't installed", "The file is too big"],
                answer: 1,
                explanation: "Relative paths are resolved from the working directory. Open the project folder or use the full path."
            ),
        ]
    )

    static let pythonVersusR = Lesson(
        id: "python-vs-r",
        title: "Python vs. R",
        summary: "Same statistics, different habits — and defaults that trip people up.",
        minutes: 9,
        blocks: [
            .text("Python is a **general-purpose** language that gained statistics through packages (pandas, statsmodels, SciPy). R was **built for statistics** from the start, so models, factors, and formulas are part of the language. Both give identical answers when asked the same question — but they don't always ask the same question by default."),
            .terms([
                Term("Assignment", "Python: `x = 5` · R: `x <- 5` (R also accepts `=`)."),
                Term("Indexing", "Python counts from **0** (`scores[0]` is the first value). R counts from **1** (`scores[1]`)."),
                Term("Missing values", "Python: `NaN` or `None` · R: `NA`. R functions often need `na.rm = TRUE`; pandas skips NaN by default."),
                Term("Tables of data", "Python: pandas `DataFrame` · R: built-in `data.frame`, or the tidyverse `tibble`."),
                Term("Categories", "Python: `pd.Categorical` · R: `factor()`."),
                Term("Chaining steps", "Python: method chaining `df.groupby(...).mean()` · R: the pipe `df |> group_by(...) |> summarise(...)`."),
                Term("Model formulas", "Both use `y ~ x1 + x2`. In R it's native; in Python it comes from `statsmodels.formula.api`."),
                Term("Installing packages", "Python: `pip install name` in the terminal · R: `install.packages(\"name\")` inside R."),
                Term("Help", "Python: `help(function)` · R: `?function`."),
            ]),
            .code(CodeSample(
                caption: "The same analysis — notice the structure is identical",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")

                # Filter, summarize, then model
                adults = survey[survey["age"] >= 25]
                print(adults.groupby("region")["anxiety"].mean())

                model = smf.ols("anxiety ~ rumination + age", data=adults).fit()
                print(model.summary())
                """#,
                r: #"""
                library(tidyverse)

                survey <- read_csv("survey.csv")

                # Filter, summarize, then model
                adults <- survey |> filter(age >= 25)
                adults |> group_by(region) |> summarise(mean(anxiety))

                model <- lm(anxiety ~ rumination + age, data = adults)
                summary(model)
                """#
            )),
            .caution("Defaults that differ", "• **Standard deviation:** `np.std()` divides by *n*; R's `sd()` and pandas `.std()` divide by *n* − 1.\n• **t-tests:** R's `t.test()` is Welch by default; SciPy's `ttest_ind()` assumes equal variances unless you pass `equal_var=False`.\n• **ANOVA sums of squares:** R's `aov()`/`anova()` use sequential (Type I) sums of squares; pingouin defaults to Type II. With unbalanced designs these give different *F* values.\n• **Random numbers:** the same seed produces *different* numbers in Python and R, so simulated results won't match exactly."),
            .keyPoint("Which should you learn?", "**R** has the deepest ecosystem for research statistics — mixed models (`lme4`), SEM and mediation (`lavaan`), psychometrics (`psych`), and adjusted means (`emmeans`). **Python** shines when statistics is one part of a bigger pipeline — text processing, web data, machine learning. Learning one makes the other much easier."),
            .field(.general, "Many labs use both: Python to collect or clean data (e.g. experiment software, scraping, text features), and R for the final statistical models and figures."),
        ],
        quiz: [
            Question(
                prompt: "`scores = [10, 20, 30]` in Python vs. `scores <- c(10, 20, 30)` in R. What do `scores[1]` return?",
                options: ["10 in both", "20 in Python, 10 in R", "10 in Python, 20 in R", "An error in both"],
                answer: 1,
                explanation: "Python indexes from 0, so position 1 is the second element. R indexes from 1."
            ),
            Question(
                prompt: "You run an independent t-test in SciPy and in R on the same data and get different p-values. Most likely reason?",
                options: ["One of them has a bug", "R uses Welch's test by default; SciPy assumes equal variances", "Python rounds differently", "R uses one-tailed tests"],
                answer: 1,
                explanation: "Pass `equal_var=False` to `scipy.stats.ttest_ind()` to match R's default."
            ),
            Question(
                prompt: "Which R function call correctly averages a column that contains missing values?",
                options: ["mean(x)", "mean(x, na.rm = TRUE)", "mean(x, dropna = TRUE)", "average(x)"],
                answer: 1,
                explanation: "R returns NA if any value is missing unless you set `na.rm = TRUE`."
            ),
        ]
    )

    static let pythonBasics = Lesson(
        id: "python-basics",
        title: "Python basics",
        summary: "Variables, lists, functions, and pandas DataFrames.",
        minutes: 12,
        blocks: [
            .text("You only need a small slice of Python for statistics: storing values, writing short functions, and working with **DataFrames** — spreadsheet-like tables from the `pandas` package."),
            .code(CodeSample(
                caption: "Core Python",
                python: #"""
                # Variables and types
                n_participants = 40          # int (whole number)
                mean_rt = 512.7              # float (decimal)
                condition = "incongruent"    # str (text)
                passed = True                # bool (True/False)

                # Lists are ordered; indexing starts at 0
                scores = [4, 5, 3, 5, 2]
                scores[0]                    # 4  (first)
                scores[-1]                   # 2  (last)
                len(scores)                  # 5

                # Dictionaries map keys to values
                person = {"id": "p01", "age": 23, "group": "control"}
                person["age"]                # 23

                # Functions take arguments and return a value
                def z_score(x, mean, sd):
                    return (x - mean) / sd

                z_score(130, mean=100, sd=15)   # 2.0

                # Loops and f-strings (formatted text)
                for s in scores:
                    print(f"score = {s}")
                """#,
                r: #"""
                # This lesson is Python-specific — switch to Python above,
                # or see the "R basics" lesson for the R equivalents.
                """#
            )),
            .code(CodeSample(
                caption: "Working with a DataFrame",
                python: #"""
                import pandas as pd

                df = pd.read_csv("survey.csv")

                df.head()                 # first 5 rows
                df.shape                  # (rows, columns)
                df.columns                # column names
                df.describe()             # quick numeric summary
                df["region"].value_counts()

                df["age"]                 # one column (a Series)
                df[["age", "anxiety"]]    # several columns (a DataFrame)
                df[df["age"] >= 30]       # rows meeting a condition
                df[(df["age"] >= 30) & (df["region"] == "rural")]   # & = and, | = or

                # New column from existing ones
                df["anxiety_z"] = (df["anxiety"] - df["anxiety"].mean()) / df["anxiety"].std()

                # Group summaries
                df.groupby("region")["anxiety"].agg(["count", "mean", "std"]).round(2)
                """#,
                r: #"""
                # Python-specific — see "R basics" for the tidyverse version.
                """#
            )),
            .terms([
                Term("Object", "Anything stored in a variable — a number, list, DataFrame, or fitted model."),
                Term("Function", "Reusable code that takes inputs (arguments) and returns an output: `round(3.14159, 2)`."),
                Term("Argument", "An input to a function. *Keyword* arguments are named: `equal_var=False`."),
                Term("Method", "A function attached to an object, called with a dot: `df.head()`."),
                Term("Series", "A single pandas column."),
                Term("DataFrame", "A pandas table: rows are observations, columns are variables."),
                Term("Import", "Loading a package so you can use it: `import pandas as pd`."),
            ]),
            .caution("Indentation matters", "Python uses indentation (4 spaces) to show which lines belong to a function or loop. A missing or extra space causes an `IndentationError`."),
            .exercise(Exercise(
                title: "Your first summary",
                prompt: "Load `survey.csv` (from the *Practice datasets* lesson). How many participants live in each `region`, and what is the mean `anxiety` in each group?",
                hint: "Use `value_counts()` for counts and `groupby()` with `.mean()` for the group means.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pandas as pd

                    df = pd.read_csv("survey.csv")
                    counts = df["region"].value_counts()
                    means = df.groupby("region")["anxiety"].mean()
                    print(counts)
                    print(means.round(2))
                    """#,
                    r: #"""
                    library(tidyverse)

                    df <- read_csv("survey.csv")
                    counts <- count(df, region)
                    means <- df |> group_by(region) |> summarise(mean_anxiety = mean(anxiety))
                    counts
                    means
                    """#
                ),
                answer: "About 60% of participants are urban and 40% rural; the two groups have similar mean anxiety near the middle of the 1–7 scale.",
                selfCheck: SelfCheck(
                    names: "`counts` (participants per region) and `means` (mean anxiety per region — in R, a `mean_anxiety` column)",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        check("Participants per region", counts.sort_index(), ref["region"].value_counts().sort_index())
                        check("Mean anxiety per region", means.sort_index(), ref.groupby("region")["anxiety"].mean())

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      check("Participants per region", counts$n, as.vector(table(ref$region)))
                      check("Mean anxiety per region", means$mean_anxiety, tapply(ref$anxiety, ref$region, mean))
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Write a function",
                prompt: "Write a function `percent(x, total)` that returns `x` as a percentage of `total`, rounded to one decimal place. Test it with `percent(37, 150)`.",
                hint: "Multiply by 100, then wrap the result in `round(value, 1)`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    def percent(x, total):
                        return round(100 * x / total, 1)

                    percent(37, 150)   # 24.7
                    """#,
                    r: #"""
                    percent <- function(x, total) {
                      round(100 * x / total, 1)
                    }

                    percent(37, 150)   # 24.7
                    """#
                ),
                answer: "`percent(37, 150)` returns **24.7**.",
                selfCheck: SelfCheck(
                    names: "a function called `percent`",
                    python: #"""
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        check("percent(37, 150)", percent(37, 150), 24.7, tol=1e-9)
                        check("percent(1, 3)", percent(1, 3), 33.3, tol=1e-9, hint="Round to one decimal place.")
                        check("percent(150, 150)", percent(150, 150), 100, tol=1e-9)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      check("percent(37, 150)", percent(37, 150), 24.7, tol = 1e-9)
                      check("percent(1, 3)", percent(1, 3), 33.3, tol = 1e-9, hint = "Round to one decimal place.")
                      check("percent(150, 150)", percent(150, 150), 100, tol = 1e-9)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Which line keeps only rows where age is at least 30?",
                options: ["df[\"age\" >= 30]", "df[df[\"age\"] >= 30]", "df.age(30)", "df.filter(age >= 30)"],
                answer: 1,
                explanation: "The inner expression creates a True/False Series; the outer brackets keep the True rows."
            ),
        ]
    )

    static let rBasics = Lesson(
        id: "r-basics",
        title: "R basics",
        summary: "Vectors, data frames, functions, and the tidyverse.",
        minutes: 12,
        blocks: [
            .text("R's core building block is the **vector** — an ordered set of values of one type. Columns of a data frame are vectors, so most operations apply to a whole column at once."),
            .code(CodeSample(
                caption: "Core R",
                python: #"""
                # This lesson is R-specific — switch to R above,
                # or see the "Python basics" lesson for the Python equivalents.
                """#,
                r: #"""
                # Assignment and types
                n_participants <- 40          # numeric
                condition <- "incongruent"    # character
                passed <- TRUE                # logical

                # Vectors; indexing starts at 1
                scores <- c(4, 5, 3, 5, 2)
                scores[1]                     # 4  (first)
                scores[length(scores)]        # 2  (last)
                mean(scores)                  # works on the whole vector
                scores * 10                   # 40 50 30 50 20

                # Missing values
                x <- c(2, NA, 4)
                mean(x)                       # NA
                mean(x, na.rm = TRUE)         # 3

                # Functions
                z_score <- function(x, mean, sd) {
                  (x - mean) / sd             # the last line is returned
                }
                z_score(130, mean = 100, sd = 15)   # 2

                # Help for any function
                ?t.test
                """#
            )),
            .code(CodeSample(
                caption: "Data frames with the tidyverse",
                python: #"""
                # R-specific — see "Python basics" for the pandas version.
                """#,
                r: #"""
                library(tidyverse)

                df <- read_csv("survey.csv")

                glimpse(df)                   # columns and types
                summary(df)                   # quick summary
                count(df, region)             # counts per group

                df$age                        # one column
                df |> select(age, anxiety)    # several columns
                df |> filter(age >= 30, region == "rural")

                # New column
                df <- df |> mutate(anxiety_z = as.numeric(scale(anxiety)))

                # Group summaries
                df |>
                  group_by(region) |>
                  summarise(n = n(), mean = mean(anxiety), sd = sd(anxiety))
                """#
            )),
            .terms([
                Term("Vector", "An ordered collection of values of one type: `c(1, 2, 3)`."),
                Term("Data frame / tibble", "R's table of data; a tibble is the tidyverse's tidier version."),
                Term("Factor", "A categorical variable with defined levels."),
                Term("Pipe (|>)", "Passes the result on the left into the function on the right: `df |> filter(age > 30)`. Read it as “and then”."),
                Term("Package / library", "A bundle of functions. Install once with `install.packages()`, load each session with `library()`."),
                Term("NA", "R's marker for a missing value."),
            ]),
            .caution("Load before you use", "`could not find function \"read_csv\"` means the package isn't loaded. Add `library(tidyverse)` at the top of your script and run it first."),
            .exercise(Exercise(
                title: "Filter and summarize",
                prompt: "Using `survey.csv`, keep only participants aged 18–29, then report how many there are and their mean and SD of `rumination`.",
                hint: "In R: `filter(age >= 18, age <= 29)` then `summarise()`. In Python: combine two conditions with `&`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pandas as pd

                    df = pd.read_csv("survey.csv")
                    young = df[(df["age"] >= 18) & (df["age"] <= 29)]
                    m, s = young["rumination"].mean(), young["rumination"].std()
                    print(len(young), m, s)
                    """#,
                    r: #"""
                    library(tidyverse)

                    young <- read_csv("survey.csv") |> filter(age >= 18, age <= 29)
                    m <- mean(young$rumination)
                    s <- sd(young$rumination)
                    c(n = nrow(young), mean = m, sd = s)
                    """#
                ),
                answer: "About a fifth of the sample is aged 18–29 (ages are spread evenly from 18 to 75). The mean rumination is close to the scale midpoint of 4, with an SD around 1.",
                selfCheck: SelfCheck(
                    names: "`young` (the filtered rows), `m` (their mean rumination), and `s` (its SD)",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("survey.csv")
                        ref_young = ref[ref["age"].between(18, 29)]
                        check("Participants aged 18–29", len(young), len(ref_young), tol=0,
                              hint="Both ends are inclusive: 18 <= age <= 29.")
                        check("Mean rumination", m, ref_young["rumination"].mean())
                        check("SD of rumination", s, ref_young["rumination"].std(), tol=0.001,
                              hint="Use the sample SD (divide by n − 1): pandas .std(), not np.std().")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("survey.csv")
                      ref_young <- subset(ref, age >= 18 & age <= 29)
                      check("Participants aged 18–29", nrow(young), nrow(ref_young), tol = 0,
                            hint = "Both ends are inclusive: 18 <= age <= 29.")
                      check("Mean rumination", m, mean(ref_young$rumination))
                      check("SD of rumination", s, sd(ref_young$rumination), tol = 0.001)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "In R, what does `df |> filter(age > 30) |> nrow()` do?",
                options: ["Deletes rows", "Counts rows where age > 30", "Sorts by age", "Returns an error"],
                answer: 1,
                explanation: "The pipe passes the filtered data into `nrow()`, which counts rows."
            ),
        ]
    )

    static let practiceData = Lesson(
        id: "practice-data",
        title: "Practice datasets",
        summary: "Generate realistic test data with built-in answers to check yourself against.",
        minutes: 12,
        blocks: [
            .text("Most lessons from Unit 3 onward use simulated datasets. Because *we* choose the true effects when generating the data, you can check whether your analysis recovers them — the best way to learn what a method actually does. Four scripts create everything; run each once, in the same folder."),
            .keyPoint("Or download them", "Every file these scripts create is also in the app: open **Practice data** in the sidebar to preview each dataset, check its columns, and download it as a CSV — or download them all at once as a ZIP or a single Excel workbook. Running the scripts yourself is still worth doing once: it's how you'd make data like this for your own projects."),
            .steps("How to use them", [
                "In your VS Code project folder, create `generate_data.py`, `generate_more_data.py`, `generate_extra_data.py`, and `generate_simulations.py` (or the `.R` versions).",
                "Paste in the code below and run each whole file (▷ in Python, **Cmd/Ctrl + Shift + S** in R).",
                "Thirty CSV files appear in the Explorer sidebar.",
                "Save the `selfcheck.py` / `selfcheck.R` helper (below) in the same folder — the exercises' self-checks use it.",
                "Create a new `analysis.py` / `analysis.R` in the same folder for each lesson's code.",
            ]),
            .code(CodeSample(
                caption: "generate_data — survey, diary, classroom, essays, and Stroop data",
                python: #"""
                # generate_data.py — creates survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv
                import numpy as np
                import pandas as pd

                rng = np.random.default_rng(2026)

                def to_scale(z, low=1, high=7):
                    """Map a standard-normal score onto a 1–7 scale mean."""
                    return np.clip((low + high) / 2 + z, low, high).round(2)

                def to_likert(z, high=5):
                    """Turn a latent score into a single 1–5 response."""
                    return np.clip(np.round(3 + z), 1, high).astype(int)

                # ---------- survey.csv: a cross-sectional survey ----------
                n = 375
                age = rng.integers(18, 76, n)
                education = rng.integers(1, 6, n)                 # 1 = high school … 5 = graduate degree
                region = rng.choice(["urban", "rural"], n, p=[0.6, 0.4])

                mind_z = rng.normal(0, 1, n) + 0.015 * (age - 40)
                social_z = rng.normal(0, 1, n)
                phone_z = 0.6 * social_z + 0.8 * rng.normal(0, 1, n)

                # Built-in truths:
                #  • social media use → rumination, weaker when mindfulness is high
                #  • rumination → anxiety, plus a small direct effect of social media
                rum_z = (0.40 * social_z + 0.15 * phone_z - 0.20 * mind_z
                         - 0.20 * social_z * mind_z + rng.normal(0, 0.85, n))
                anx_z = 0.45 * rum_z + 0.15 * social_z + rng.normal(0, 0.85, n)

                survey = pd.DataFrame({
                    "participant": np.arange(1, n + 1),
                    "age": age, "education": education, "region": region,
                    "social_media": to_scale(social_z),
                    "phone_checking": to_scale(phone_z),
                    "rumination": to_scale(rum_z),
                    "anxiety": to_scale(anx_z),
                })

                # Six 1–5 mindfulness items; items 3 and 5 are reverse-worded, ~3% missing
                item_cols = [f"mind_{i}" for i in range(1, 7)]
                for i, col in enumerate(item_cols, start=1):
                    item = to_likert(0.9 * mind_z + rng.normal(0, 0.7, n))
                    survey[col] = (6 - item if i in (3, 5) else item).astype(float)
                survey[item_cols] = survey[item_cols].mask(rng.random((n, 6)) < 0.03)

                # Precomputed composite so you can check your own scoring
                keyed = survey[item_cols].copy()
                keyed[["mind_3", "mind_5"]] = 6 - keyed[["mind_3", "mind_5"]]
                survey["mindfulness"] = (keyed.mean(axis=1)
                                         .where(keyed.notna().sum(axis=1) >= 5).round(3))
                survey.to_csv("survey.csv", index=False)

                # ---------- diary.csv: 14 daily reports per person ----------
                n_people, n_days = 100, 14
                usual_hours = rng.normal(7, 1.5, n_people)       # each person's typical workday
                consc = rng.normal(0, 1, n_people)               # conscientiousness (z)
                rows = []
                for p in range(n_people):
                    within_slope = -0.25 - 0.10 * consc[p] + rng.normal(0, 0.08)
                    baseline = 4 + 0.30 * (usual_hours[p] - 7) + rng.normal(0, 0.6)
                    hours = usual_hours[p] + rng.normal(0, 1.2, n_days)
                    wellbeing = baseline + within_slope * (hours - usual_hours[p]) + rng.normal(0, 0.7, n_days)
                    for d in range(n_days):
                        rows.append({"participant": p + 1, "day": d + 1,
                                     "work_hours": round(float(np.clip(hours[d], 0, 16)), 1),
                                     "wellbeing": round(float(np.clip(wellbeing[d], 1, 7)), 2),
                                     "conscientiousness": round(float(np.clip(3 + 0.8 * consc[p], 1, 5)), 2)})
                pd.DataFrame(rows).to_csv("diary.csv", index=False)

                # ---------- classroom.csv: three teaching methods, randomized ----------
                n_class = 150
                method = rng.permutation(np.repeat(["lecture", "active", "flipped"], n_class // 3))
                pre_z = rng.normal(0, 1, n_class)
                effect = np.select([method == "active", method == "flipped"], [0.40, 0.10], 0.0)
                post_z = 0.7 * pre_z + effect + rng.normal(0, 0.7, n_class)
                pd.DataFrame({
                    "student": np.arange(1, n_class + 1),
                    "method": method,
                    "school": rng.choice(["Ash", "Birch", "Cedar", "Maple"], n_class),
                    "pretest": np.clip(np.round(65 + 10 * pre_z), 0, 100).astype(int),
                    "posttest": np.clip(np.round(65 + 10 * post_z), 0, 100).astype(int),
                }).to_csv("classroom.csv", index=False)

                # ---------- essays.csv: two raters score 120 essays on a 1–6 rubric ----------
                n_essays = 120
                quality = rng.normal(3.5, 1.1, n_essays)

                def score(bias, noise=0.6):
                    return np.clip(np.round(quality + bias + rng.normal(0, noise, n_essays)), 1, 6).astype(int)

                pd.DataFrame({
                    "essay": np.arange(1, n_essays + 1),
                    "rater_a": score(0.0),
                    "rater_b": score(0.3),            # rater B is slightly more lenient
                    "rater_a_retest": score(0.0),     # rater A again, two weeks later
                }).to_csv("essays.csv", index=False)

                # ---------- stroop_trials.csv and stroop.csv: a Stroop task ----------
                n_s, n_items = 60, 24
                person = rng.normal(0, 0.15, n_s)                 # some people respond faster overall
                person_effect = rng.normal(0, 0.03, n_s)          # and show a bigger or smaller Stroop effect
                item_effect = rng.normal(0, 0.05, n_items)        # some color words are harder
                rows = []
                for p in range(n_s):
                    for i in range(n_items):
                        for condition in ["congruent", "incongruent"]:
                            log_rt = (6.3 + person[p] + item_effect[i]
                                      + (0.08 + person_effect[p]) * (condition == "incongruent") + rng.normal(0, 0.25))
                            rows.append({"participant": p + 1, "item": i + 1, "condition": condition,
                                         "rt": int(round(np.exp(log_rt)))})
                trials = pd.DataFrame(rows)
                trials.to_csv("stroop_trials.csv", index=False)

                # One row per participant: mean RT in each condition, plus age and an attention check
                means = trials.pivot_table(index="participant", columns="condition", values="rt", aggfunc="mean")
                pd.DataFrame({
                    "participant": means.index,
                    "age": rng.integers(16, 41, n_s),                 # a few are under 18
                    "attention_check": np.where(rng.random(n_s) < 0.9, "pass", "fail"),
                    "rt_congruent": means["congruent"].round(1).to_numpy(),
                    "rt_incongruent": means["incongruent"].round(1).to_numpy(),
                }).to_csv("stroop.csv", index=False)

                print("Saved survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv")
                """#,
                r: #"""
                # generate_data.R — creates survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv
                set.seed(2026)

                to_scale  <- function(z, low = 1, high = 7) round(pmin(pmax((low + high) / 2 + z, low), high), 2)
                to_likert <- function(z, high = 5) as.integer(pmin(pmax(round(3 + z), 1), high))

                # ---------- survey.csv: a cross-sectional survey ----------
                n <- 375
                age       <- sample(18:75, n, replace = TRUE)
                education <- sample(1:5, n, replace = TRUE)   # 1 = high school … 5 = graduate degree
                region    <- sample(c("urban", "rural"), n, replace = TRUE, prob = c(0.6, 0.4))

                mind_z   <- rnorm(n) + 0.015 * (age - 40)
                social_z <- rnorm(n)
                phone_z  <- 0.6 * social_z + 0.8 * rnorm(n)

                # Built-in truths:
                #  • social media use → rumination, weaker when mindfulness is high
                #  • rumination → anxiety, plus a small direct effect of social media
                rum_z <- 0.40 * social_z + 0.15 * phone_z - 0.20 * mind_z -
                         0.20 * social_z * mind_z + rnorm(n, sd = 0.85)
                anx_z <- 0.45 * rum_z + 0.15 * social_z + rnorm(n, sd = 0.85)

                survey <- data.frame(
                  participant = 1:n, age, education, region,
                  social_media   = to_scale(social_z),
                  phone_checking = to_scale(phone_z),
                  rumination     = to_scale(rum_z),
                  anxiety        = to_scale(anx_z)
                )

                # Six 1–5 mindfulness items; items 3 and 5 are reverse-worded, ~3% missing
                for (i in 1:6) {
                  item <- to_likert(0.9 * mind_z + rnorm(n, sd = 0.7))
                  if (i %in% c(3, 5)) item <- 6L - item
                  item[runif(n) < 0.03] <- NA
                  survey[[paste0("mind_", i)]] <- item
                }

                # Precomputed composite so you can check your own scoring
                keyed <- survey[paste0("mind_", 1:6)]
                keyed[c("mind_3", "mind_5")] <- 6 - keyed[c("mind_3", "mind_5")]
                survey$mindfulness <- ifelse(rowSums(!is.na(keyed)) >= 5,
                                             round(rowMeans(keyed, na.rm = TRUE), 3), NA)
                write.csv(survey, "survey.csv", row.names = FALSE)

                # ---------- diary.csv: 14 daily reports per person ----------
                n_people <- 100; n_days <- 14
                usual_hours <- rnorm(n_people, 7, 1.5)    # each person's typical workday
                consc       <- rnorm(n_people)            # conscientiousness (z)
                diary <- do.call(rbind, lapply(1:n_people, function(p) {
                  within_slope <- -0.25 - 0.10 * consc[p] + rnorm(1, sd = 0.08)
                  baseline     <- 4 + 0.30 * (usual_hours[p] - 7) + rnorm(1, sd = 0.6)
                  hours        <- usual_hours[p] + rnorm(n_days, sd = 1.2)
                  wellbeing    <- baseline + within_slope * (hours - usual_hours[p]) + rnorm(n_days, sd = 0.7)
                  data.frame(participant = p, day = 1:n_days,
                             work_hours = round(pmin(pmax(hours, 0), 16), 1),
                             wellbeing  = round(pmin(pmax(wellbeing, 1), 7), 2),
                             conscientiousness = round(pmin(pmax(3 + 0.8 * consc[p], 1), 5), 2))
                }))
                write.csv(diary, "diary.csv", row.names = FALSE)

                # ---------- classroom.csv: three teaching methods, randomized ----------
                n_class <- 150
                method  <- sample(rep(c("lecture", "active", "flipped"), each = n_class / 3))
                effect  <- c(lecture = 0, active = 0.40, flipped = 0.10)[method]
                pre_z   <- rnorm(n_class)
                post_z  <- 0.7 * pre_z + effect + rnorm(n_class, sd = 0.7)
                classroom <- data.frame(
                  student  = 1:n_class, method,
                  school   = sample(c("Ash", "Birch", "Cedar", "Maple"), n_class, replace = TRUE),
                  pretest  = pmin(pmax(round(65 + 10 * pre_z), 0), 100),
                  posttest = pmin(pmax(round(65 + 10 * post_z), 0), 100)
                )
                write.csv(classroom, "classroom.csv", row.names = FALSE)

                # ---------- essays.csv: two raters score 120 essays on a 1–6 rubric ----------
                n_essays <- 120
                quality  <- rnorm(n_essays, 3.5, 1.1)
                score <- function(bias, noise = 0.6) {
                  as.integer(pmin(pmax(round(quality + bias + rnorm(n_essays, sd = noise)), 1), 6))
                }
                essays <- data.frame(essay = 1:n_essays,
                                     rater_a = score(0),
                                     rater_b = score(0.3),          # rater B is slightly more lenient
                                     rater_a_retest = score(0))     # rater A again, two weeks later
                write.csv(essays, "essays.csv", row.names = FALSE)

                # ---------- stroop_trials.csv and stroop.csv: a Stroop task ----------
                n_s <- 60; n_items <- 24
                person        <- rnorm(n_s, sd = 0.15)            # some people respond faster overall
                person_effect <- rnorm(n_s, sd = 0.03)            # and show a bigger or smaller Stroop effect
                item_effect   <- rnorm(n_items, sd = 0.05)        # some color words are harder
                trials <- expand.grid(condition = c("congruent", "incongruent"), item = 1:n_items,
                                      participant = 1:n_s, stringsAsFactors = FALSE)
                trials <- trials[, c("participant", "item", "condition")]
                log_rt <- 6.3 + person[trials$participant] + item_effect[trials$item] +
                          (0.08 + person_effect[trials$participant]) * (trials$condition == "incongruent") +
                          rnorm(nrow(trials), sd = 0.25)
                trials$rt <- round(exp(log_rt))
                write.csv(trials, "stroop_trials.csv", row.names = FALSE)

                # One row per participant: mean RT in each condition, plus age and an attention check
                means <- tapply(trials$rt, list(trials$participant, trials$condition), mean)
                write.csv(data.frame(
                  participant     = 1:n_s,
                  age             = sample(16:40, n_s, replace = TRUE),     # a few are under 18
                  attention_check = ifelse(runif(n_s) < 0.9, "pass", "fail"),
                  rt_congruent    = round(means[, "congruent"], 1),
                  rt_incongruent  = round(means[, "incongruent"], 1)
                ), "stroop.csv", row.names = FALSE)

                cat("Saved survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv\n")
                """#
            )),
            .code(moreDataSample),
            .code(extraDataSample),
            .keyPoint("Practice simulations", "The fourth script creates two **practice simulations** — simulated studies whose data come with the same mess as real research: a study of political parasocial attachment (a survey with a credibility task, coded interviews, and a randomized intervention), and a study of how people ask chatbots about political court cases (session transcripts, exported chat logs, a speech-act coding sheet, double coding, a framework matrix, and repeated queries to five fictional chatbots). Exercises titled **Practice simulation** throughout the course use them."),
            .code(simulationDataSample),
            .code(CodeSample(
                caption: "selfcheck — save once in the same folder; every exercise's Self-check uses it",
                python: #"""
                # selfcheck.py — compares your results with independently recomputed answers.
                import numpy as np


                def check(label, yours, expected, tol=0.01, hint=None):
                    """Print ✓ if `yours` matches `expected` (within tol, relative to its size), else ✗."""
                    try:
                        a = np.squeeze(np.asarray(yours, dtype=float))
                        b = np.squeeze(np.asarray(expected, dtype=float))
                        close = np.abs(a - b) <= tol * (1 + np.abs(b))
                        ok = a.shape == b.shape and bool(np.all(close | (np.isnan(a) & np.isnan(b))))
                    except (TypeError, ValueError):
                        # Text (or mixed) results must match exactly.
                        ok = np.array_equal(np.asarray(yours, dtype=object), np.asarray(expected, dtype=object))
                    print(("✓ " if ok else "✗ ") + label)
                    if not ok:
                        print(f"    yours:    {_show(yours)}")
                        print(f"    expected: {_show(expected)}")
                        if hint:
                            print(f"    hint: {hint}")
                    return ok


                def _show(x):
                    """Numbers as a compact, rounded list; anything else as is."""
                    try:
                        return np.round(np.asarray(x, dtype=float), 4).tolist()
                    except (TypeError, ValueError):
                        return x
                """#,
                r: #"""
                # selfcheck.R — compares your results with independently recomputed answers.
                # Load it with source("selfcheck.R").
                check <- function(label, yours, expected, tol = 0.01, hint = NULL) {
                  y <- unname(unlist(yours))
                  e <- unname(unlist(expected))
                  ok <- if (is.numeric(y) && is.numeric(e)) {
                    length(y) == length(e) &&
                      all((is.na(y) & is.na(e)) | abs(y - e) <= tol * (1 + abs(e)))
                  } else {
                    # Text (or mixed) results must match exactly.
                    identical(as.character(y), as.character(e))
                  }
                  ok <- isTRUE(ok)
                  cat(if (ok) "✓ " else "✗ ", label, "\n", sep = "")
                  if (!ok) {
                    cat("    yours:   ", format(y, digits = 4), "\n")
                    cat("    expected:", format(e, digits = 4), "\n")
                    if (!is.null(hint)) cat("    hint:", hint, "\n")
                  }
                  invisible(ok)
                }
                """#
            )),
            .keyPoint("Self-checks", "Most exercises have a **Self-check** button. It tells you which variable names to store your results in, and gives a short script to run underneath your code. The script recomputes each answer its own way and prints ✓ or ✗, so you can check your work without opening the solution. Save `selfcheck.py` / `selfcheck.R` above in your project folder first."),
            .terms([
                Term("survey.csv", "375 respondents: `age`, `education` (1–5), `region` (urban / rural), 1–7 scale scores for `social_media`, `phone_checking`, `rumination`, `anxiety`, six 1–5 items `mind_1`–`mind_6` (3 and 5 reverse-worded), and a precomputed `mindfulness` score."),
                Term("diary.csv", "100 people × 14 days: daily `work_hours` and `wellbeing` (1–7), plus each person's `conscientiousness` (1–5)."),
                Term("classroom.csv", "150 students randomized to a `method` (lecture, active, flipped), with `pretest` and `posttest` scores (0–100) and their `school` (4 schools)."),
                Term("essays.csv", "120 essays scored 1–6 by `rater_a` and `rater_b`, plus `rater_a_retest` (the same rater, two weeks later)."),
                Term("stroop.csv", "60 participants in a Stroop task, one row each: `age`, `attention_check` (pass / fail), and mean reaction times `rt_congruent` and `rt_incongruent` (ms)."),
                Term("stroop_trials.csv", "The same task trial by trial: 60 participants × 24 color words (`item`) × 2 conditions, with each trial's `rt` in ms."),
                Term("judgments.csv", "40 participants × 32 sentences in a 2 × 2 design (`structure`: simple / complex × `distance`: short / long): an acceptability `rating` (1–7) and whether a comprehension question was answered `correct` (0/1)."),
                Term("commutes.csv", "120 people × 10 weeks: commute `mode` (car, bus, bike, walk) and `distance_km`."),
                Term("habits.csv", "500 students: six 0/1 study strategies (`reread`, `notes`, `selftest`, `spaced`, `explain`, `peers`), `gpa`, and the hidden `true_class`."),
                Term("profiles.csv", "400 people: four continuous scores (`wellbeing`, `stress`, `support`, `sleep`), `age`, `burnout`, and the hidden `true_profile`."),
                Term("missing.csv", "500 people: `age`, `stress`, `sleep`, and `wellbeing` with about a quarter missing, plus the hidden `wellbeing_true`."),
                Term("fillers.csv", "300 interviews: filler-word counts (`fillers`), interview length in `minutes`, `condition` (relaxed / evaluated), second-language speaker `l2` (0/1), and `age`."),
                Term("poll.csv", "1,000 poll respondents in 50 towns (`town`) and two regions (`region`), with policy `support` (0/1), `trust` (0–10), `age`, and a survey `weight`."),
                Term("tutoring.csv", "800 students: `prior_gpa`, `motivation`, `parent_degree`, whether they chose `tutoring`, their `exam` score, and a teacher's recommendation (`recommended`)."),
                Term("growth.csv", "250 students × up to 5 waves: reading `score` by `wave`, with a randomized `group` (control / intervention)."),
                Term("ppsr_survey.csv", "Parasocial simulation — 375 respondents: parasocial attachment (`parasocial`, `prism`), identity `fusion`, perceived `charisma`, `affective_polarization`, `institutional_trust`, ideology and interest, twelve 1–5 wisdom items `wis_1`–`wis_12` (2, 6, 7, and 11 reverse-worded) with their `wisdom` score, and `credibility_bias`; recruited from a `university` or `prolific` `stream`."),
                Term("credibility_trials.csv", "The credibility task trial by trial: 375 participants × 12 descriptions, each `creditable` or `discrediting` (`valence`) and attributed to the `favoured` or `disliked` figure (`target`), with `credibility` and `confidence` ratings (1–5)."),
                Term("ppsr_narratives.csv", "30 coded interviews: `group` (maintained / breakup), the `figure_position` in the narrative (subject, helper, opponent), and whether political `commitments_survived` the breakup (0/1)."),
                Term("ppsr_experiment.csv", "137 participants randomized to a writing `arm` (wise, parasocial, observer): `pre_`/`post_` attachment (`prism`) and polarization (`ap`), `wisdom`, `stream`, `issue`, a `manipulation_check`, and `words` written."),
                Term("llm_sessions.csv", "Chatbot simulation — one row per participant (32): `country`, `headline` (US-1–3, CA-1–3), `model` (fictional A–E), screener self-placement `p1_self_placement` (0 = left … 10 = right), who transcribed and coded the session, and the post-task rating form `a1_agree` … `a7_placement` (A3 and A7 keep written answers such as `dont_know` and `not_political`)."),
                Term("llm_transcripts.csv", "One row per turn of each session: `line`, `time`, `turn_type` (INT, PAR, QRY, LLM, ACT), `turn_id` (e.g. `P012_C1_Q03`, with `b` for an edited or regenerated turn), the interview `question` (Q1–Q11), the verbatim `text` (fillers, pauses, ((reading)) … ((/reading))), and transcriber `notes`."),
                Term("llm_chat_export.csv", "The exported chat logs: every message sent (`role` = user) and received (`role` = assistant), with a UTC `timestamp_utc`. QRY rows in the transcript should match these exactly."),
                Term("llm_coding.csv", "The consensus coding sheet, laid out like the team's Excel template: one row per speech act (`speech_act_id` = query ID + `_a`, `_b`), with `participant`, `chat`, `turn_position` (the query's number within its chat), `llm`, the full `query_text` and the act's `speech_act_text`, then the coded columns — `clause_type`, `primary_act` (10 draft levels), `directness`, presupposition (`presup`, `trigger_type`, `presup_direction`, `leading_construction`), evaluation (`evaluative`, `polarity`, `target`), `partisan_terms`, stance (`stance_disclosure`, `disclosure_direction`), `relation` to the previous model turn — plus `confidence`, `coder`, and `notes`. Columns that don't apply are blank."),
                Term("llm_coder_a.csv / llm_coder_b.csv", "Each coder's independent sheet for every transcript, before the consensus meeting — the data reliability is calculated on. A few queries are split into speech acts differently."),
                Term("llm_card_labels.csv", "The interview's Q5 card label for each query (`query_id`, `card_label`): what the participant says they were asking for."),
                Term("llm_instrument_coding.csv", "60 survey-style items of the kind used in bias research, coded with the same codebook."),
                Term("llm_framework.csv", "The interview framework matrix: one row per participant, one 0/1 column per code (`code_1_1` … `code_6_2`; e.g. `code_4_3` = perceived lean with a cue)."),
                Term("llm_indexing.csv", "Indexing agreement for the same 7 transcripts: one row per interview answer line and code (4.1–5.4), with each coder's 0/1."),
                Term("llm_responses.csv", "7,200 coded responses: 288 queries (`headline` × `speech_act` × `register` × `variant`; headlines 7–8 are neutral `control`s) × 5 fictional models (A–E) × 5 `run`s, with `lean` from −3 (left) to +3 (right)."),
            ]),
            .keyPoint("The built-in truths", "• **survey:** social media → rumination (weaker at high mindfulness) → anxiety.\n• **diary:** people who *usually* work longer report *higher* wellbeing (between-person), but on days someone works *more than usual*, their wellbeing is *lower* (within-person) — especially for conscientious people.\n• **classroom:** active learning raises post-test scores about 0.4 SD above lecture; flipped barely helps.\n• **essays:** the raters agree well, but B scores about 0.3 points higher.\n• **judgments:** complex and long sentences are rated lower, and the two together are worse than their sum (an interaction).\n• **commutes:** people tend to repeat last week's mode, biking grows over the weeks, and long distances discourage biking and walking.\n• **habits / profiles:** three hidden types in each.\n• **missing:** stressed people skip the wellbeing question, so complete cases overstate wellbeing.\n• **fillers:** being evaluated raises the filler rate 1.4×, speaking a second language 1.6×; counts are overdispersed.\n• **poll:** rural towns are oversampled and support the policy less, so weighting raises support.\n• **tutoring:** the true effect is +5 points, but motivated students choose tutoring, so the naive gap is about twice that.\n• **growth:** reading grows about 5 points per wave, 2 points faster with the intervention.\n• **parasocial simulation:** attachment predicts credibility bias and polarization, partly through bias; wisdom weakens the attachment → bias link; the wise-reasoning arm lowers attachment about 0.3 SD.\n• **chatbot simulation:** conversations drift from information-seeking to evaluation; askers' requests presuppose their own side's framing; the two coders agree well (Krippendorff's α) except on directness, where “can you…” requests split them, and on the inductive interview code 4.6; three transcript rows were “fixed” instead of pasted; right-leaning participants more often saw a lean, and placed the chatbot further left; most models lean slightly left, more so with everyday phrasing; single runs are noisy."),
            .caution("Python and R give different numbers", "Each language has its own random-number generator, so the two scripts create *different* datasets with the same structure. Use the same language for generating and analyzing, or share the CSVs. Exact estimates will vary; directions and rough sizes should match the truths."),
            .exercise(Exercise(
                title: "Inspect your data",
                prompt: "Load `survey.csv` and `diary.csv`. How many rows does each have, and how many participants are missing a `mindfulness` score?",
                hint: "Python: `.shape` and `.isna().sum()`. R: `dim()` and `sum(is.na())`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import pandas as pd

                    survey = pd.read_csv("survey.csv")
                    diary = pd.read_csv("diary.csv")
                    print(survey.shape, diary.shape)
                    n_missing = survey["mindfulness"].isna().sum()
                    print(n_missing)
                    """#,
                    r: #"""
                    survey <- read.csv("survey.csv")
                    diary <- read.csv("diary.csv")
                    dim(survey); dim(diary)
                    n_missing <- sum(is.na(survey$mindfulness))
                    n_missing
                    """#
                ),
                answer: "survey.csv has 375 rows × 15 columns and diary.csv has 1,400 rows (100 × 14). Only a handful of respondents (usually under 5) lack a mindfulness score, because a score requires at least 5 of the 6 items.",
                selfCheck: SelfCheck(
                    names: "`survey`, `diary`, and `n_missing` (the number of missing mindfulness scores)",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        check("Rows in survey.csv", len(survey), 375, tol=0)
                        check("Rows in diary.csv", len(diary), 100 * 14, tol=0)
                        check("Missing mindfulness scores", n_missing,
                              pd.read_csv("survey.csv")["mindfulness"].isna().sum(), tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      check("Rows in survey.csv", nrow(survey), 375, tol = 0)
                      check("Rows in diary.csv", nrow(diary), 100 * 14, tol = 0)
                      check("Missing mindfulness scores", n_missing,
                            sum(is.na(read.csv("survey.csv")$mindfulness)), tol = 0)
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "Why practice on simulated data with known effects?",
                options: [
                    "It's more realistic than real data",
                    "You can check whether a method recovers the truth you built in",
                    "Journals require it",
                    "It guarantees significant results",
                ],
                answer: 1,
                explanation: "Simulation is how methodologists study what analyses do — and it's a great way to learn."
            ),
        ]
    )

    static let readingOutput = Lesson(
        id: "reading-output",
        title: "Reading model output",
        summary: "What every column in a regression table means.",
        minutes: 8,
        blocks: [
            .text("Model summaries look intimidating, but they repeat the same handful of numbers. Fit this model, then match each piece of output to the glossary below."),
            .code(CodeSample(
                caption: "Fit a regression and print its summary",
                python: #"""
                import pandas as pd
                import statsmodels.formula.api as smf

                survey = pd.read_csv("survey.csv")
                model = smf.ols("anxiety ~ rumination + age", data=survey).fit()
                print(model.summary())
                """#,
                r: #"""
                survey <- read.csv("survey.csv")
                model <- lm(anxiety ~ rumination + age, data = survey)
                summary(model)
                confint(model)   # 95% confidence intervals
                """#
            )),
            .terms([
                Term("coef · Estimate", "The regression coefficient (b): expected change in the outcome per one-unit increase in the predictor, holding the others constant."),
                Term("Intercept", "Predicted outcome when all predictors equal 0. Often not meaningful unless predictors are centered."),
                Term("std err · Std. Error", "Uncertainty in the coefficient — how much it would vary across samples."),
                Term("t · t value", "Estimate ÷ standard error. Larger absolute values = stronger evidence against b = 0."),
                Term("P>|t| · Pr(>|t|)", "Two-tailed p-value for the test that the coefficient is 0. R adds stars: `***` p < .001, `**` p < .01, `*` p < .05."),
                Term("[0.025 0.975] · confint()", "The 95% confidence interval for the coefficient."),
                Term("R-squared", "Proportion of outcome variance explained by the model."),
                Term("Adj. R-squared", "R² penalized for the number of predictors — fairer when comparing models of different sizes."),
                Term("F-statistic", "Tests whether the predictors, together, explain any variance at all."),
                Term("Df Residuals · degrees of freedom", "Sample size minus the number of estimated parameters; used for the t and F tests."),
                Term("AIC / BIC", "Model-fit indices that penalize complexity; lower is better when comparing models on the same data."),
            ]),
            .caution("Check the N", "Rows with a missing value on *any* variable in the formula are silently dropped. Compare `model.nobs` (Python) or `nobs(model)` (R) with your sample size."),
            .exercise(Exercise(
                title: "Read the table",
                prompt: "From the model above, write one APA-style sentence about rumination: the coefficient, its 95% CI, and the p-value. Then report R².",
                hint: "Python: `model.params`, `model.conf_int()`, `model.pvalues`, `model.rsquared`. R: `summary(model)` and `confint(model)`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    b = model.params["rumination"]
                    lo, hi = model.conf_int().loc["rumination"]
                    p = model.pvalues["rumination"]
                    r2 = model.rsquared
                    print(f"b = {b:.2f}, 95% CI [{lo:.2f}, {hi:.2f}], p = {p:.3g}; R² = {r2:.2f}")
                    """#,
                    r: #"""
                    b  <- coef(model)["rumination"]
                    lo <- confint(model)["rumination", 1]
                    hi <- confint(model)["rumination", 2]
                    p  <- summary(model)$coefficients["rumination", "Pr(>|t|)"]
                    r2 <- summary(model)$r.squared
                    sprintf("b = %.2f, 95%% CI [%.2f, %.2f], p = %.3g; R2 = %.2f", b, lo, hi, p, r2)
                    """#
                ),
                answer: "Rumination has a clearly positive coefficient (roughly 0.4–0.5 scale points per point of rumination), a CI that excludes 0, and p < .001. R² is typically around .25–.35.",
                selfCheck: SelfCheck(
                    names: "`b`, `lo` and `hi` (the 95% CI), `p`, and `r2`",
                    python: #"""
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = smf.ols("anxiety ~ rumination + age", data=pd.read_csv("survey.csv")).fit()
                        ci = ref.conf_int().loc["rumination"]
                        check("b for rumination", b, ref.params["rumination"], tol=0.001)
                        check("95% CI, lower", lo, ci[0], tol=0.001)
                        check("95% CI, upper", hi, ci[1], tol=0.001)
                        check("p-value", p, ref.pvalues["rumination"], tol=1e-6)
                        check("R²", r2, ref.rsquared, tol=0.001, hint="Use R², not adjusted R².")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- lm(anxiety ~ rumination + age, data = read.csv("survey.csv"))
                      ci <- confint(ref)["rumination", ]
                      check("b for rumination", b, coef(ref)[["rumination"]], tol = 0.001)
                      check("95% CI, lower", lo, ci[[1]], tol = 0.001)
                      check("95% CI, upper", hi, ci[[2]], tol = 0.001)
                      check("p-value", p, summary(ref)$coefficients["rumination", 4], tol = 1e-6)
                      check("R²", r2, summary(ref)$r.squared, tol = 0.001, hint = "Use R², not adjusted R².")
                    })
                    """#
                )
            )),
        ],
        quiz: [
            Question(
                prompt: "A coefficient is 0.30 with SE = 0.10. What is its t value?",
                options: ["0.03", "0.40", "3.0", "30"],
                answer: 2,
                explanation: "t = estimate ÷ SE = 0.30 ÷ 0.10 = 3.0."
            ),
            Question(
                prompt: "Which tells you how much outcome variance the model explains?",
                options: ["The intercept", "R²", "The standard error", "AIC"],
                answer: 1,
                explanation: "R² is the proportion of variance explained."
            ),
        ]
    )
}

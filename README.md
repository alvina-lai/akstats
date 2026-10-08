# akstats — Stats Lab

**Research statistics for the social sciences, from the ground up — with every example in both Python and R.**

[![Practice data](https://github.com/alvina-lai/akstats/actions/workflows/practice-data.yml/badge.svg)](https://github.com/alvina-lai/akstats/actions/workflows/practice-data.yml)

Stats Lab is a free, interactive course app for learning the statistics that psychologists, linguists, and sociologists actually use. It starts at the very beginning (what a variable is, how to install Python and R) and works up to mixed-effects and growth models, mediation, confirmatory factor analysis, ordinal and count models, latent class/profile analysis, missing data, causal inference, meta-analysis, and Bayesian inference.

## What's inside

- **14 units, 65+ lessons**, ordered beginner → intermediate → advanced
- **Practice simulations**: two simulated studies whose data recur in “Practice simulation” exercises across the course — a study of political parasocial attachment (a survey with a credibility task, coded interviews, and a randomized intervention), and a study of how people ask chatbots about political court cases (session transcripts, exported chat logs, a speech-act coding sheet, double coding, a framework matrix, and repeated queries to five fictional chatbots)
- **Self-check scripts** for every exercise with a computable answer: store your results, run the check under your own code, and it prints ✓ or ✗ for each one (in Python and R)
- **Beginner-friendly explanations** in every lesson: the core idea, an everyday analogy, a worked example you can follow by hand, and how to report the result
- **“How the model works” cards** for each statistical model — the equation, the steps, and the conditions to check — following *OpenIntro Statistics*
- **Interactive charts** with hover readouts and step-by-step guides to reading them
- **Code in Python and R** for every example (plus Mplus for latent class/profile models), with a one-click language switch
- **Practice datasets** with built-in “true” effects, so you can check whether your analysis recovers them
- **Hundreds of practice exercises and quiz questions**, plus an end-of-unit review for every unit
- **Real-data labs** using OpenIntro datasets
- A **searchable glossary** of every statistics and coding term
- A **references page** with full APA citations (and DOI links) for every work cited in the lessons
- **Explained code**: every code example says what it's for and what to look for in its output; code blocks start open, and any you close stay closed until you reopen them
- **Search** across every lesson, practice question, code sample (Python and R), glossary term, dataset, and reference, with filters for each
- **Practice data** you can preview and download in the app: every dataset as a CSV, a ZIP of all of them, or one Excel workbook; each practice-simulation exercise links straight to the files it needs
- **Bookmarks**: mark a spot in any lesson from the toolbar or by right-clicking a section; the lesson offers to take you back to it, and bookmarks can be moved or removed at any time

## Download and run

### Option 1 — Download the Mac app (no Xcode needed)

1. Download [**`akstats-macOS.zip`**](https://github.com/alvina-lai/akstats/releases/latest/download/akstats-macOS.zip) from the [latest release](https://github.com/alvina-lai/akstats/releases/latest) (currently **v1.1**, which adds the practice simulations, search, the Practice data view with downloads, explained code blocks, and right-click bookmarks).
2. Unzip it and move `akstats.app` to your Applications folder.
3. The first time you open it, macOS will warn that it can't verify the app, because it isn't notarized by Apple (that requires a paid developer account). Close the warning, open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to akstats, then confirm. You only need to do this once.

**Is it safe?** The app is sandboxed: macOS only lets it touch files you choose in a Save dialog, and it never uses the network. All of its source code is in this repository, so you can read it or build the app yourself (Option 2). To confirm your download is the published file, run `shasum -a 256 ~/Downloads/akstats-macOS.zip` in Terminal and compare it with the SHA-256 in the release notes.

Requires **macOS 27** or later.

### Option 2 — Build from source

Requires **Xcode 27** or later.

1. Click **Code → Download ZIP** above (or `git clone` this repository).
2. Open `akstats.xcodeproj` in Xcode.
3. Select the **akstats** target → **Signing & Capabilities**, and choose your own team (a free Apple ID works).
4. Choose a destination (My Mac, an iPhone/iPad simulator, or Apple Vision Pro) and press **Run** (⌘R).

## Using the practice data

**Download them here on GitHub.** Every dataset is in [`akstats/PracticeData`](akstats/PracticeData) — its README describes each file, GitHub previews any CSV as a table when you click it, and [`practice_data.xlsx`](akstats/PracticeData/practice_data.xlsx) has all of them in one workbook. The scripts that make them are in [`scripts/python`](scripts/python) and [`scripts/r`](scripts/r) (see [`scripts/README.md`](scripts/README.md)), along with the `selfcheck` helper the exercises use.

**Or make them yourself.** To generate them, open **Unit 0 → Practice datasets** in the app, copy the four generator scripts (Python or R) into a folder on your computer, and run them. They create thirty CSV files (`survey.csv`, `diary.csv`, `classroom.csv`, `essays.csv`, `stroop.csv`, `stroop_trials.csv`, `judgments.csv`, `commutes.csv`, `habits.csv`, `profiles.csv`, `missing.csv`, `fillers.csv`, `poll.csv`, `tutoring.csv`, `growth.csv`, and, for the practice simulations, `ppsr_survey.csv`, `credibility_trials.csv`, `ppsr_narratives.csv`, `ppsr_experiment.csv`, `llm_sessions.csv`, `llm_transcripts.csv`, `llm_chat_export.csv`, `llm_coding.csv`, `llm_coder_a.csv`, `llm_coder_b.csv`, `llm_card_labels.csv`, `llm_instrument_coding.csv`, `llm_framework.csv`, `llm_indexing.csv`, `llm_responses.csv`) used throughout the lessons. Prefer not to run the scripts? Open **Practice data** in the app's sidebar to preview and download every file (as CSVs, a ZIP, or an Excel workbook). Save the small `selfcheck.py` / `selfcheck.R` helper from the same lesson alongside them — the exercises' self-checks use it.

The labs use real datasets from [OpenIntro](https://www.openintro.org/data/), loaded directly from the web in Python or via the `openintro` R package.

Every lesson's code runs top to bottom in a fresh Python or R session once the practice data exist. Each lesson loads its own data, and every More-practice solution runs on its own. A few examples need software beyond the usual packages: the Mplus inputs need [Mplus](https://www.statmodel.com) (commercial), the topic models need `scikit-learn` (Python) or `topicmodels` (R), the Bayesian regression example needs `brms` (R, with a C++ toolchain) or `bambi` (Python 3.10+), and the embedding example downloads a sentence-transformer model the first time it runs.

## Project structure

| Path | Contents |
|---|---|
| `akstats/Curriculum*.swift` | All course content: units, lessons, code samples, quizzes, exercises, explanations, and reviews |
| `akstats/Charts*.swift`, `ChartSupport.swift` | Interactive example charts (Swift Charts) |
| `akstats/*View.swift`, `BlockViews.swift` | The app's interface |
| `akstats/Theme.swift` | Colors and shared styling |
| `akstats/ProgressStore.swift` | Saves which lessons you've completed, and your bookmarks |
| `akstats/PracticeData/` | The practice datasets: bundled in the app's Practice data view and browsable here (CSVs, an Excel workbook, and a README describing each file) |
| `scripts/python/`, `scripts/r/` | The practice-data generators and the `selfcheck` helper as downloadable files (exported from the app's lessons) |
| `tools/` | `export_scripts.py` (copies the scripts out of the lessons) and `build_practice_data.py` (rebuilds the bundled data) |
| `.github/workflows/` | A check, on every push, that the scripts match the app, reproduce the bundled data exactly, and run in R |

Lesson content is plain Swift data, so adding or editing a lesson doesn't require touching the interface code.

**Making a release?** Run `tools/release.sh`. It builds `dist/akstats-macOS.zip` with its checksum and release notes, and signs and notarizes the app automatically if a Developer ID certificate is installed (setup steps are at the top of the script).

**Changing a data generator?** Edit it in the lesson, then run `python3 tools/export_scripts.py` and `python3 tools/build_practice_data.py` (with the packages in `tools/requirements.txt`) and commit the results; the GitHub check fails if the scripts and the data drift apart.

## Credits

- Explanations of core methods follow the approach of [*OpenIntro Statistics*](https://www.openintro.org/book/os/) (4th ed.) by Diez, Çetinkaya-Rundel, and Barr, which is available under a Creative Commons license.
- Lab datasets (`hsb2`, `resume`, `evals`) are from [OpenIntro](https://www.openintro.org/data/).
- Chart colors use the colorblind-safe Okabe–Ito palette.
- Advanced lessons draw on the methods literature cited in each lesson (e.g. Baayen, Davidson & Bates, 2008; Hayes, 2022; Bürkner & Vuorre, 2019; Nylund-Gibson & Choi, 2018).

Created by Alvina Lai.

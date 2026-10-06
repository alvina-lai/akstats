# akstats — Stats Lab

**Research statistics for the social sciences, from the ground up — with every example in both Python and R.**

Stats Lab is a free, interactive course app for learning the statistics that psychologists, linguists, and sociologists actually use. It starts at the very beginning (what a variable is, how to install Python and R) and works up to mixed-effects models, mediation, ordinal models, and latent class/profile analysis.

## What's inside

- **13 units, 50+ lessons**, ordered beginner → intermediate → advanced
- **Beginner-friendly explanations** in every lesson: the core idea, an everyday analogy, a worked example you can follow by hand, and how to report the result
- **“How the model works” cards** for each statistical model — the equation, the steps, and the conditions to check — following *OpenIntro Statistics*
- **Interactive charts** with hover readouts and step-by-step guides to reading them
- **Code in Python and R** for every example (plus Mplus for latent class/profile models), with a one-click language switch
- **Practice datasets** with built-in “true” effects, so you can check whether your analysis recovers them
- **Hundreds of practice exercises and quiz questions**, plus an end-of-unit review for every unit
- **Real-data labs** using OpenIntro datasets
- A **searchable glossary** of every statistics and coding term

## Download and run

### Option 1 — Download the Mac app (no Xcode needed)

1. Go to the [**Releases**](../../releases) page and download `akstats-macOS.zip`.
2. Unzip it and move `akstats.app` to your Applications folder.
3. The first time you open it, macOS will say it's from an unidentified developer. **Right-click the app → Open → Open**. (Alternatively: System Settings → Privacy & Security → “Open Anyway”.) You only need to do this once.

Requires **macOS 27** or later.

### Option 2 — Build from source

Requires **Xcode 27** or later.

1. Click **Code → Download ZIP** above (or `git clone` this repository).
2. Open `akstats.xcodeproj` in Xcode.
3. Select the **akstats** target → **Signing & Capabilities**, and choose your own team (a free Apple ID works).
4. Choose a destination (My Mac, an iPhone/iPad simulator, or Apple Vision Pro) and press **Run** (⌘R).

## Using the practice data

The course's practice datasets aren't shipped as files — you generate them. Open **Unit 0 → Practice datasets** in the app, copy the two generator scripts (Python or R) into a folder on your computer, and run them. They create eight CSV files (`survey.csv`, `diary.csv`, `classroom.csv`, `essays.csv`, `judgments.csv`, `commutes.csv`, `habits.csv`, `profiles.csv`) used throughout the lessons.

The labs use real datasets from [OpenIntro](https://www.openintro.org/data/), loaded directly from the web in Python or via the `openintro` R package.

## Project structure

| Path | Contents |
|---|---|
| `akstats/Curriculum*.swift` | All course content: units, lessons, code samples, quizzes, exercises, explanations, and reviews |
| `akstats/Charts*.swift`, `ChartSupport.swift` | Interactive example charts (Swift Charts) |
| `akstats/*View.swift`, `BlockViews.swift` | The app's interface |
| `akstats/Theme.swift` | Colors and shared styling |
| `akstats/ProgressStore.swift` | Saves which lessons you've completed |

Lesson content is plain Swift data, so adding or editing a lesson doesn't require touching the interface code.

## Credits

- Explanations of core methods follow the approach of [*OpenIntro Statistics*](https://www.openintro.org/book/os/) (4th ed.) by Diez, Çetinkaya-Rundel, and Barr, which is available under a Creative Commons license.
- Lab datasets (`hsb2`, `resume`, `evals`) are from [OpenIntro](https://www.openintro.org/data/).
- Chart colors use the colorblind-safe Okabe–Ito palette.
- Advanced lessons draw on the methods literature cited in each lesson (e.g. Baayen, Davidson & Bates, 2008; Hayes, 2022; Bürkner & Vuorre, 2019; Nylund-Gibson & Choi, 2018).

Created by Alvina Lai.

# Practice-data scripts

The scripts from the app's **Unit 0 → Practice datasets** lesson, as files you can download. Put them in one folder and run the
four generators once, in either language — they create the 30 CSV files the course uses (see
[`akstats/PracticeData`](../akstats/PracticeData) for what's in each one, or download the files there directly).

| Script | Creates |
|---|---|
| `generate_data` | `survey.csv`, `diary.csv`, `classroom.csv`, `essays.csv`, `stroop.csv`, `stroop_trials.csv` |
| `generate_more_data` | `judgments.csv`, `commutes.csv`, `habits.csv`, `profiles.csv` |
| `generate_extra_data` | `missing.csv`, `fillers.csv`, `poll.csv`, `tutoring.csv`, `growth.csv` |
| `generate_simulations` | the two practice simulations: `ppsr_*.csv`, `credibility_trials.csv`, and `llm_*.csv` |
| `selfcheck` | not data — the helper every exercise's **Self-check** loads; keep it in the same folder |

```sh
# Python (needs numpy and pandas)
python generate_data.py && python generate_more_data.py && python generate_extra_data.py && python generate_simulations.py

# R (base R only)
Rscript generate_data.R && Rscript generate_more_data.R && Rscript generate_extra_data.R && Rscript generate_simulations.R
```

The Python and R scripts use different random-number generators, so they make files with the same structure but different
numbers; every self-check works with either. These files are exported from the app's source with
`python3 tools/export_scripts.py` — edit the lesson, not these copies.

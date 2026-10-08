# generate_extra_data.py — creates missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv
import numpy as np
import pandas as pd

rng = np.random.default_rng(2028)


def logistic(x):
    return 1 / (1 + np.exp(-x))


# ---------- missing.csv: stressed people skip the wellbeing question ----------
n = 500
stress = rng.normal(0, 1, n)
sleep = np.clip(7 - 0.5 * stress + rng.normal(0, 0.8, n), 3, 10).round(1)
wellbeing_true = (4 - 0.6 * stress + 0.2 * (sleep - 7) + rng.normal(0, 0.7, n)).round(2)
skipped = rng.random(n) < logistic(-1.4 + 1.2 * stress)     # missing at random, given stress
pd.DataFrame({
    "id": np.arange(1, n + 1),
    "age": rng.integers(18, 70, n),
    "stress": stress.round(2),
    "sleep": sleep,
    "wellbeing": np.where(skipped, np.nan, wellbeing_true),
    "wellbeing_true": wellbeing_true,                        # the hidden truth, for checking only
}).to_csv("missing.csv", index=False)

# ---------- fillers.csv: "um"s and "uh"s in interviews of different lengths ----------
n_f = 300
minutes = rng.uniform(5, 15, n_f).round(1)
evaluated = rng.integers(0, 2, n_f)                          # 1 = told the interview was being assessed
l2 = (rng.random(n_f) < 0.4).astype(int)                     # 1 = speaking a second language
age_f = rng.integers(18, 70, n_f)
rate = 0.8 * 1.4 ** evaluated * 1.6 ** l2 * np.exp(-0.005 * (age_f - 40))   # fillers per minute
pd.DataFrame({
    "speaker": np.arange(1, n_f + 1),
    "condition": np.where(evaluated == 1, "evaluated", "relaxed"),
    "l2": l2, "age": age_f, "minutes": minutes,
    "fillers": rng.poisson(minutes * rate * rng.gamma(3, 1 / 3, n_f)),    # extra-Poisson variation
}).to_csv("fillers.csv", index=False)

# ---------- poll.csv: a stratified cluster sample that oversamples rural towns ----------
rows = []
for town in range(1, 51):                                    # 25 urban + 25 rural towns, 20 people each
    region = "urban" if town <= 25 else "rural"
    town_effect = rng.normal(0, 0.5)
    age = rng.integers(18, 85, 20)
    p = logistic((0.4 if region == "urban" else -0.6) + town_effect - 0.01 * (age - 45))
    support = (rng.random(20) < p).astype(int)
    trust = np.clip(np.round(5 + 1.5 * support + town_effect + rng.normal(0, 2, 20)), 0, 10).astype(int)
    for i in range(20):
        rows.append({"region": region, "town": town, "age": age[i], "support": support[i], "trust": trust[i]})
poll = pd.DataFrame(rows)
poll.insert(0, "id", np.arange(1, len(poll) + 1))
# Population: 700,000 urban and 300,000 rural adults; the poll interviewed 500 of each
poll["weight"] = np.where(poll["region"] == "urban", 700_000 / 500, 300_000 / 500)
poll.to_csv("poll.csv", index=False)

# ---------- tutoring.csv: who chooses tutoring is not random ----------
n_t = 800
prior_gpa = np.clip(rng.normal(3.0, 0.5, n_t), 1.5, 4.0).round(2)
motivation = rng.normal(0, 1, n_t).round(2)
parent_degree = (rng.random(n_t) < 0.4).astype(int)
tutoring = (rng.random(n_t) < logistic(-0.5 + 1.2 * motivation - 0.6 * (prior_gpa - 3)
                                       + 0.5 * parent_degree)).astype(int)
exam = (62 + 10 * (prior_gpa - 3) + 6 * motivation + 3 * parent_degree + 5 * tutoring
        + rng.normal(0, 7, n_t)).round(1)                    # true tutoring effect: +5 points
recommended = (rng.random(n_t) < logistic(-1 + 1.5 * tutoring + 0.12 * (exam - 62))).astype(int)   # a collider
pd.DataFrame({
    "student": np.arange(1, n_t + 1), "prior_gpa": prior_gpa, "motivation": motivation,
    "parent_degree": parent_degree, "tutoring": tutoring, "exam": exam, "recommended": recommended,
}).to_csv("tutoring.csv", index=False)

# ---------- growth.csv: reading scores over 5 waves, with a randomized intervention ----------
n_g = 250
group = rng.permutation(np.repeat([0, 1], n_g // 2))         # 1 = reading intervention
start = rng.normal(0, 8, n_g)                                 # each student's own starting level
slope = rng.normal(0, 1.5, n_g) + 0.05 * start                # and their own growth rate
rows = []
for s in range(n_g):
    for wave in range(5):
        score = 100 + start[s] + (5 + 2 * group[s] + slope[s]) * wave + rng.normal(0, 4)
        rows.append({"student": s + 1, "group": "intervention" if group[s] else "control",
                     "wave": wave, "score": round(score, 1)})
growth = pd.DataFrame(rows)
growth = growth[rng.random(len(growth)) >= 0.08]             # about 8% of visits missed, at random
growth.to_csv("growth.csv", index=False)

print("Saved missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv")

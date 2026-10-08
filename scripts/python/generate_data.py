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

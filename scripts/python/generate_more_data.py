# generate_more_data.py — creates judgments.csv, commutes.csv, habits.csv, profiles.csv
import numpy as np
import pandas as pd

rng = np.random.default_rng(2027)

# ---------- judgments.csv: a 2 × 2 sentence-acceptability experiment ----------
n_part, n_items = 40, 32
conditions = [("simple", "short"), ("simple", "long"), ("complex", "short"), ("complex", "long")]
part_eff, item_eff = rng.normal(0, 0.7, n_part), rng.normal(0, 0.5, n_items)
part_acc, item_acc = rng.normal(0, 0.6, n_part), rng.normal(0, 0.4, n_items)
rows = []
for p in range(n_part):
    for i in range(n_items):
        structure, distance = conditions[(p + i) % 4]     # Latin square: each item once per person
        is_complex, is_long = structure == "complex", distance == "long"
        latent = (part_eff[p] + item_eff[i] - 0.8 * is_complex - 0.5 * is_long
                  - 0.6 * (is_complex and is_long) + rng.logistic(0, 0.7))
        rating = int(np.digitize(latent, [-2.5, -1.6, -0.8, 0.0, 0.8, 1.6])) + 1     # 1–7
        p_correct = 1 / (1 + np.exp(-(1.5 - 0.5 * is_complex + part_acc[p] + item_acc[i])))
        rows.append({"participant": p + 1, "item": i + 1, "structure": structure, "distance": distance,
                     "rating": rating, "correct": int(rng.random() < p_correct)})
pd.DataFrame(rows).to_csv("judgments.csv", index=False)

# ---------- commutes.csv: weekly commute mode over 10 weeks ----------
modes = ["car", "bus", "bike", "walk"]
rows = []
for p in range(120):
    distance = round(float(rng.gamma(2.0, 3.0)), 1)                 # km
    taste = np.r_[0.0, rng.normal(0, 0.8, 3)]                      # personal preferences (car = 0)
    previous = None
    for week in range(1, 11):
        utility = np.array([0.0, 0.2, -0.5 + 0.12 * week - 0.15 * distance, 1.0 - 0.6 * distance]) + taste
        if previous is not None:
            utility[previous] += 1.5                               # habit: people repeat their mode
        prob = np.exp(utility) / np.exp(utility).sum()
        choice = rng.choice(4, p=prob)
        rows.append({"participant": p + 1, "week": week, "distance_km": distance, "mode": modes[choice]})
        previous = choice
pd.DataFrame(rows).to_csv("commutes.csv", index=False)

# ---------- habits.csv: six study strategies from three hidden types ----------
strategies = ["reread", "notes", "selftest", "spaced", "explain", "peers"]
type_profiles = np.array([
    [0.90, 0.85, 0.15, 0.10, 0.10, 0.20],   # 1: passive review
    [0.50, 0.50, 0.85, 0.75, 0.60, 0.25],   # 2: active practice
    [0.40, 0.40, 0.40, 0.30, 0.80, 0.90],   # 3: social learning
])
n_h = 500
cls = rng.choice(3, n_h, p=[0.45, 0.35, 0.20])
habits = pd.DataFrame((rng.random((n_h, 6)) < type_profiles[cls]).astype(int), columns=strategies)
habits.insert(0, "id", np.arange(1, n_h + 1))
habits["gpa"] = np.clip(np.array([2.8, 3.4, 3.1])[cls] + rng.normal(0, 0.4, n_h), 0, 4).round(2)
habits["true_class"] = cls + 1
habits.to_csv("habits.csv", index=False)

# ---------- profiles.csv: four continuous scores from three hidden profiles ----------
n_lpa = 400
profile = rng.choice(3, n_lpa, p=[0.5, 0.3, 0.2])
profile_means = np.array([[5.5, 2.5, 5.5, 5.0],    # 1: thriving
                          [4.0, 4.0, 4.0, 4.0],    # 2: average
                          [2.5, 5.5, 3.0, 2.8]])   # 3: struggling
indicators = profile_means[profile] + rng.normal(0, 0.7, (n_lpa, 4))
lpa = pd.DataFrame(np.clip(indicators, 1, 7).round(2), columns=["wellbeing", "stress", "support", "sleep"])
lpa.insert(0, "id", np.arange(1, n_lpa + 1))
lpa["age"] = rng.integers(18, 66, n_lpa)
lpa["burnout"] = (np.array([2.0, 3.0, 4.5])[profile] + rng.normal(0, 0.8, n_lpa)).round(2)
lpa["true_profile"] = profile + 1
lpa.to_csv("profiles.csv", index=False)

print("Saved judgments.csv, commutes.csv, habits.csv, profiles.csv")

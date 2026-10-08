# generate_simulations.py — two practice simulations:
#   1. Political parasocial attachment: ppsr_survey.csv, credibility_trials.csv, ppsr_narratives.csv,
#      ppsr_experiment.csv
#   2. Asking chatbots about political court cases: llm_sessions.csv, llm_chat_export.csv, llm_transcripts.csv,
#      llm_coding.csv, llm_coder_a.csv, llm_coder_b.csv, llm_card_labels.csv, llm_instrument_coding.csv,
#      llm_framework.csv, llm_indexing.csv, llm_responses.csv
# All people, figures, chatbots ("models A–E"), and results are simulated.
import re

import numpy as np
import pandas as pd

rng = np.random.default_rng(2029)


def scale(z, low, high, mid=None, spread=1.0):
    """Map a standard-normal score onto a bounded scale mean."""
    mid = (low + high) / 2 if mid is None else mid
    return np.clip(mid + spread * z, low, high).round(2)


# =============== Simulation 1, Study 1: ppsr_survey.csv and credibility_trials.csv ===============
n = 375
stream = np.r_[["university"] * 150, ["prolific"] * 225]
age = np.where(stream == "university", rng.integers(18, 36, n), rng.integers(18, 76, n))
country = rng.choice(["Canada", "United States"], n, p=[0.55, 0.45])
education = np.clip(np.where(stream == "university", 3, 2) + rng.integers(0, 3, n), 1, 5)
ideology_econ = rng.integers(1, 8, n)                 # 1 = left … 7 = right
ideology_social = np.clip(ideology_econ + rng.integers(-2, 3, n), 1, 7)
political_interest = rng.integers(2, 6, n)            # 1–5

psr_z = rng.normal(0, 1, n)                                   # parasocial intensity toward the nominated figure
fusion_z = 0.65 * psr_z + 0.76 * rng.normal(0, 1, n)          # identity fusion with the figure (r ≈ .65)
charisma_z = 0.50 * psr_z + 0.87 * rng.normal(0, 1, n)        # charisma attributed to the figure
wisdom_z = rng.normal(0, 1, n) + 0.015 * (age - 35)           # dispositional wisdom rises a little with age

# Built-in truths: fusion drives credibility bias more than parasocial intensity;
# wisdom weakens the parasocial → bias path; bias → polarization, plus a direct path
bias_z = (0.15 * psr_z + 0.35 * fusion_z - 0.10 * wisdom_z - 0.28 * psr_z * wisdom_z
          + 0.10 * charisma_z + rng.normal(0, 0.80, n))
extremity = np.abs(ideology_econ - 4) / 3
ap_z = 0.40 * bias_z + 0.15 * psr_z + 0.20 * extremity + rng.normal(0, 0.80, n)
trust_z = -0.20 * psr_z + rng.normal(0, 0.95, n)

survey = pd.DataFrame({
    "participant": np.arange(1, n + 1), "stream": stream, "country": country, "age": age,
    "education": education, "ideology_econ": ideology_econ, "ideology_social": ideology_social,
    "political_interest": political_interest,
    "parasocial": scale(psr_z, 1, 7, mid=4.2),            # PSR-P mean, 1–7
    "prism": scale(0.85 * psr_z + 0.5 * rng.normal(0, 1, n), 1, 7, mid=4.0),   # PRISM mean, 1–7
    "fusion": scale(fusion_z, 1, 7, mid=3.6, spread=1.2),  # verbal fusion, 1–7
    "charisma": scale(charisma_z, 1, 5, mid=3.4, spread=0.7),
    "affective_polarization": scale(ap_z, 1, 7, mid=4.3),
    "institutional_trust": scale(trust_z, 1, 7, mid=3.9),
})

# 3D-WS-12: four cognitive, four reflective, four affective items (1–5); items 2, 6, 7, 11 are reverse-worded
wisdom_cols = [f"wis_{i}" for i in range(1, 13)]
reversed_items = {2, 6, 7, 11}
for i, col in enumerate(wisdom_cols, start=1):
    item = np.clip(np.round(3.3 + 0.75 * wisdom_z + rng.normal(0, 0.75, n)), 1, 5)
    survey[col] = (6 - item if i in reversed_items else item).astype(int)
keyed = survey[wisdom_cols].copy()
for i in reversed_items:
    keyed[f"wis_{i}"] = 6 - keyed[f"wis_{i}"]
survey["wisdom"] = keyed.mean(axis=1).round(3)          # precomputed so you can check your scoring

# Credibility judgment task: 12 descriptions (1–6 creditable, 7–12 discrediting), half attributed to the
# nominated (favoured) figure and half to the most-disliked figure, randomized for each participant
plausibility = rng.normal(0, 0.4, 12)                    # some descriptions are simply more believable
shift = 0.55 + 0.45 * bias_z                             # each person's pull toward their own figure
coupling = 0.30 - 0.12 * wisdom_z + rng.normal(0, 0.10, n)   # how much confidence tracks protectiveness
leniency = rng.normal(0, 0.4, n)                         # some people find everything more believable
rows = []
for p in range(n):
    favoured = np.r_[rng.permutation(np.r_[np.ones(3), np.zeros(3)]), rng.permutation(np.r_[np.ones(3), np.zeros(3)])]
    confidence_level = rng.normal(0, 0.4)
    for d in range(12):
        creditable = d < 6
        protective_if_high = (favoured[d] == 1) == creditable          # high credibility favours own side
        latent = plausibility[d] + leniency[p] + (shift[p] if protective_if_high else -shift[p]) + rng.normal(0, 0.8)
        credibility = int(np.clip(np.round(3 + latent), 1, 5))
        protect = credibility if protective_if_high else 6 - credibility
        confidence = int(np.clip(np.round(3.3 + confidence_level + coupling[p] * (protect - 3)
                                          + rng.normal(0, 0.7)), 1, 5))
        rows.append({"participant": p + 1, "description": d + 1,
                     "valence": "creditable" if creditable else "discrediting",
                     "target": "favoured" if favoured[d] == 1 else "disliked",
                     "credibility": credibility, "confidence": confidence})
trials = pd.DataFrame(rows)
trials.to_csv("credibility_trials.csv", index=False)

# Each participant's credibility bias: mean protectiveness (1–5) minus the midpoint 3
protective = np.where((trials["target"] == "favoured") == (trials["valence"] == "creditable"),
                      trials["credibility"], 6 - trials["credibility"])
survey["credibility_bias"] = (pd.Series(protective).groupby(trials["participant"]).mean() - 3).round(3).to_numpy()
survey.to_csv("ppsr_survey.csv", index=False)

# =============== Simulation 1, Study 2: ppsr_narratives.csv (coded interviews) ===============
# Fixed counts, so Python and R give identical tables: where each narrative places the political figure
maintained = ["helper"] * 10 + ["subject"] * 5
breakup = ["opponent"] * 11 + ["helper"] * 3 + ["subject"] * 1
narratives = pd.DataFrame({
    "group": ["maintained"] * 15 + ["breakup"] * 15,
    "figure_position": maintained + breakup,
    # breakup group only: did the person's political commitments outlast the bond?
    "commitments_survived": [np.nan] * 15 + [1] * 11 + [0] * 4,
})
narratives = narratives.sample(frac=1, random_state=7).reset_index(drop=True)
narratives.insert(0, "participant", np.arange(1, 31))
narratives.to_csv("ppsr_narratives.csv", index=False)

# =============== Simulation 1, Study 3: ppsr_experiment.csv (three-arm intervention) ===============
n3 = 137
arm = rng.permutation(np.r_[["wise"] * 46, ["parasocial"] * 46, ["observer"] * 45])
issue = rng.choice(["climate", "immigration", "taxation", "content_moderation"], n3)
pre_psr_z = rng.normal(0, 1, n3)
wisdom3 = scale(rng.normal(0, 1, n3), 1, 5, mid=3.4, spread=0.6)
effect = np.select([arm == "wise", arm == "parasocial"], [-0.36, 0.10], 0.0)   # in SD units (truth)
post_psr_z = 0.75 * pre_psr_z + effect + rng.normal(0, 0.66, n3)
pre_ap_z = 0.3 * pre_psr_z + rng.normal(0, 0.95, n3)
post_ap_z = 0.80 * pre_ap_z + 0.35 * effect + rng.normal(0, 0.60, n3)
pd.DataFrame({
    "participant": np.arange(1, n3 + 1), "arm": arm,
    "stream": rng.choice(["university", "prolific"], n3, p=[0.4, 0.6]),
    "issue": issue, "wisdom": wisdom3,
    "pre_prism": scale(pre_psr_z, 1, 7, mid=4.3), "post_prism": scale(post_psr_z, 1, 7, mid=4.3),
    "pre_ap": scale(pre_ap_z, 1, 7, mid=4.2), "post_ap": scale(post_ap_z, 1, 7, mid=4.2),
    "manipulation_check": np.clip(np.round(5 + rng.normal(0, 1.2, n3)), 1, 7).astype(int),
    "words": rng.integers(75, 260, n3) * 3,
}).to_csv("ppsr_experiment.csv", index=False)

# =============== Simulation 2, Study 1: sessions, transcripts, and coding (how people prompt) ===============
# Modeled on a structured-interview pipeline: a rating form, an exported chat log, a turn-by-turn transcript
# (INT / PAR / QRY / LLM / ACT rows), a speech-act coding sheet with both coders' independent sheets, and a framework matrix.
s1 = np.random.default_rng(2031)

def pick(options, p=None):
    """One random choice (as a plain Python value)."""
    return options[s1.choice(len(options), p=p)]

headlines = {"US-1": "the pipeline injunction", "US-2": "the school library ruling", "US-3": "the border detention case",
             "CA-1": "the transit strike injunction", "CA-2": "the clinic buffer zone case", "CA-3": "the language law ruling"}
partisan = {"US-1": ("climate crisis", "energy independence"), "US-2": ("book bans", "parental rights"),
            "US-3": ("asylum seekers", "illegal immigrants"), "CA-1": ("workers' rights", "union bosses"),
            "CA-2": ("reproductive rights", "pro-life"), "CA-3": ("minority rights", "activist judges")}
parties = {"US": ["democrats", "republicans"], "CA": ["the liberals", "the conservatives"]}
pairs = ["A", "B", "C", "D"]
double_coded = ["P003", "P007", "P012", "P016", "P021", "P025", "P030"]   # 7 of 32 (about 20%)

# ---- participants, case attributes, and framework codes ----
n_s1 = 32
stance_list = list(s1.permutation(["left"] * 12 + ["right"] * 12 + ["centre"] * 8))
sessions, framework = [], []
for i in range(n_s1):
    pid = f"P{i + 1:03d}"
    country = "US" if i % 2 == 0 else "CA"
    headline = f"{country}-{(i // 2) % 3 + 1}"
    stance = stance_list[i]
    p1 = int({"left": s1.integers(0, 4), "centre": s1.integers(4, 7), "right": s1.integers(7, 11)}[stance])
    # Interview codes (deductive framework, version 1)
    disclosure = pick(["5.1", "5.2", "5.3", "5.4"], p=[0.25, 0.15, 0.30, 0.30])
    c = {code: 0 for code in ["1.1", "1.2", "1.3", "1.4", "1.5", "2.1", "2.2", "2.3", "2.4", "3.1", "3.2", "3.3", "3.4",
                              "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "5.1", "5.2", "5.3", "5.4", "6.1", "6.2"]}
    c[disclosure] = 1
    c["4.3"] = int(s1.random() < {"right": 0.65, "left": 0.30, "centre": 0.35}[stance])
    c["4.1"] = int(c["4.3"] == 0 and s1.random() < (0.75 if disclosure == "5.3" else 0.35))
    c["4.2"] = int(s1.random() < (0.65 if disclosure == "5.1" else 0.12))
    c["4.6"] = int(s1.random() < (0.65 if c["4.3"] else 0.05))
    c["4.4"] = int(s1.random() < 0.40)
    c["4.5"] = int(c["4.4"] == 0 and s1.random() < 0.55)
    c["1.1"] = int(s1.random() < 0.80)
    c["1.2"] = int(s1.random() < 0.55)
    c["1.3"] = int(s1.random() < (0.55 if disclosure == "5.3" else 0.15))
    c["1.4"] = int(s1.random() < 0.30)
    c["1.5"] = int(c["1.1"] + c["1.2"] + c["1.3"] + c["1.4"] == 0)
    c[pick(["2.1", "2.2", "2.3", "2.4"], p=[0.35, 0.40, 0.15, 0.10])] = 1
    circled = s1.random() < 0.70                       # a word was circled during the task, so Q6 is asked
    if circled:
        c[pick(["3.1", "3.2", "3.3", "3.4"], p=[0.35, 0.30, 0.25, 0.10])] = 1
    c["6.1"] = int(s1.random() < 0.20)
    c["6.2"] = int(s1.random() < 0.25)
    framework.append({"participant": pid, **{f"code_{k.replace('.', '_')}": v for k, v in c.items()}})

    # Rating form (A1–A7); special answers are kept as text, exactly as written on the form
    a1 = int(np.clip(round((6.0 if c["4.2"] else 4.0) + s1.normal(0, 1.1)), 1, 7))
    a2 = int(np.clip(round(a1 - 0.3 + s1.normal(0, 1.0)), 1, 7))
    a3 = "dont_know" if s1.random() < 0.12 else str(int(np.clip(round(4 + s1.normal(0, 1.6)), 1, 7)))
    a4 = int(np.clip(round(3 + s1.normal(0, 1.0)), 1, 5))
    a6 = ("Yes" if s1.random() < 0.8 else "Not sure") if c["4.3"] else ("No" if c["4.1"] else pick(["No", "Yes", "Not sure"]))
    r = s1.random()
    if c["4.1"] and r < 0.25:
        a7 = "not_political"
    elif r > 0.93:
        a7 = "dont_know"
    else:   # people further right place the AI further left, and vice versa
        a7 = str(int(np.clip(round(5 - 0.30 * (p1 - 5) + s1.normal(0, 1.6)), 0, 10)))
    pair = pairs[i % 4]
    sessions.append({"participant": pid, "interview_order": i + 1, "session_date": str(np.datetime64("2026-11-09") + int(i * 1.2)),
                     "recording_start": f"{s1.integers(9, 17):02d}:{s1.integers(0, 60):02d}", "utc_offset": -5,
                     "country": country, "headline": headline, "model": "ABCDE"[i % 5], "p1_self_placement": p1,
                     "transcribed_by": pair, "coded_by": pairs[(i + 1) % 4], "double_coded": int(pid in double_coded),
                     "a1_agree": a1, "a2_trust": a2, "a3_fair": a3, "a4_confidence": a4,
                     "a5_difficulty": int(np.clip(round(3.5 + s1.normal(0, 1.4)), 1, 7)), "a6_side": a6, "a7_placement": a7,
                     "_stance": stance, "_disclosure": disclosure, "_circled": circled, "_codes": c})

# ---- speech acts: the coding sheet's levels (drafts until the codebook is frozen) ----
acts10 = ["Summary", "Explanation", "Evaluation of fairness", "Opinion", "Prediction", "Personal advice",
          "Verification", "Clarification", "Pushback", "Meta"]
early10 = np.array([0.34, 0.26, 0.07, 0.05, 0.07, 0.02, 0.08, 0.08, 0.00, 0.03])
late10 = np.array([0.04, 0.13, 0.20, 0.20, 0.12, 0.08, 0.05, 0.06, 0.07, 0.05])
# (clause type, directness, text, presupposition (trigger, direction), evaluation (polarity, target));
# under the draft rule, "can you …" requests are coded Indirect (conventionally indirect)
templates = {
    "Summary": [("Interrogative (wh)", "Direct", "what happened with {case}", None, None),
                ("Imperative", "Direct", "summarize {case}", None, None),
                ("Imperative", "Direct", "give me the short version of {case}", None, None),
                ("Interrogative (polar)", "Indirect", "can you summarize {case}", None, None),
                ("Interrogative (polar)", "Indirect", "can u explain what {case} actually does", None, None),
                ("Fragment", "Direct", "{case} summary", None, None)],
    "Explanation": [("Interrogative (wh)", "Direct", "why did the court rule that way", ("Why question", "Neutral"), None),
                    ("Interrogative (wh)", "Direct", "how does {case} work legally", None, None),
                    ("Imperative", "Direct", "explain the reasoning behind the ruling", None, None),
                    ("Interrogative (polar)", "Indirect", "can you explain what the judge actually said", None, None),
                    ("Declarative", "Indirect", "im curious why the judge decided that", ("Why question", "Neutral"), None)],
    "Evaluation of fairness": [("Interrogative (polar)", "Direct", "was {case} decided fairly", None, None),
                               ("Interrogative (polar)", "Direct", "is the ruling fair to both sides", None, None),
                               ("Interrogative (polar)", "Indirect", "could you tell me if the ruling was fair", None, None),
                               ("Interrogative (polar)", "Direct", "honestly the ruling seems pretty unfair, was it", None, ("Negative", "Policy"))],
    "Opinion": [("Interrogative (wh)", "Direct", "what do you think about {case}", None, None),
                ("Interrogative (polar)", "Direct", "do you agree with the ruling", None, None),
                ("Imperative", "Direct", "give me your honest opinion", None, None),
                ("Interrogative (polar)", "Indirect", "can you tell me your take on it", None, None),
                ("Interrogative (wh)", "Direct", "what should the government do now", None, None)],
    "Prediction": [("Interrogative (wh)", "Direct", "what happens next", None, None),
                   ("Interrogative (polar)", "Direct", "will it get appealed", None, None),
                   ("Interrogative (polar)", "Indirect", "can you guess whether it gets overturned", None, None),
                   ("Declarative", "Indirect", "i wonder if this goes to the supreme court", None, None)],
    "Personal advice": [("Interrogative (polar)", "Direct", "should i sign the petition", None, None),
                        ("Interrogative (wh)", "Direct", "what should i do about this", None, None),
                        ("Interrogative (polar)", "Indirect", "can you help me decide whether to go to the protest", None, None),
                        ("Declarative", "Indirect", "im thinking about writing to my representative", None, None)],
    "Verification": [("Interrogative (polar)", "Direct", "is that true", None, None),
                     ("Imperative", "Direct", "fact check that last part", None, None),
                     ("Interrogative (polar)", "Indirect", "can you check if that's accurate", None, None),
                     ("Interrogative (polar)", "Direct", "are you sure about that", None, None)],
    "Clarification": [("Interrogative (wh)", "Direct", "what do u mean by standing", None, None),
                      ("Interrogative (wh)", "Direct", "wait what's an injunction", None, None),
                      ("Interrogative (polar)", "Indirect", "can you say that more simply", None, None)],
    "Pushback": [("Declarative", "Direct", "thats not true", None, ("Negative", "LLM")),
                 ("Declarative", "Direct", "that seems pretty one sided", None, ("Negative", "LLM")),
                 ("Interrogative (wh)", "Direct", "why are you only giving one side", ("Why question", "Unclear"), ("Negative", "LLM")),
                 ("Declarative", "Indirect", "i feel like you're leaving something out", None, ("Negative", "LLM"))],
    "Meta": [("Interrogative (polar)", "Direct", "are you allowed to have opinions on this", None, None),
             ("Interrogative (polar)", "Direct", "are you just programmed to avoid this stuff", None, ("Negative", "LLM")),
             ("Interrogative (wh)", "Direct", "why do you keep saying some critics argue", ("Multiple (list in Notes)", "Unclear"), ("Negative", "LLM"))],
}
card_of = {"Summary": "what happened", "Explanation": "why or how it happened", "Evaluation of fairness": "whether it was fair",
           "Prediction": "what will happen next", "Opinion": "what the AI thinks", "Personal advice": "what someone should do",
           "Verification": "none of these", "Clarification": "none of these", "Pushback": "none of these", "Meta": "none of these"}
cards = sorted(set(card_of.values()))
disclosure_phrases = {"left": ("im pretty left wing, ", "Left"), "right": ("im pretty conservative but i want a straight answer. ", "Right"),
                      "centre": ("im kind of in the middle on this, ", "Unclear")}
# Presupposed partisan framings: (trigger type, leading construction, text)
presup_frames = [("Factive verb", "None", "now that everyone knows it's about {term}, "),
                 ("Evaluative description", "None", "with all the {term} chaos, "),
                 ("Change of state", "None", "since the {term} situation got worse, "),
                 ("Evaluative description", "Negative polar", "isn't this really about {term}? "),
                 ("Evaluative description", "Tag question", "this is all about {term}, right? ")]
hedge_words = [", i guess", " maybe", ", kind of", ", probably"]
typos = {"what": "waht", "the": "teh", "because": "becuase", "about": "abuot"}
framing_acts = ("Evaluation of fairness", "Opinion", "Personal advice", "Explanation")

def make_act(act, s):
    """One speech act's text and its consensus codes (blank where a column doesn't apply)."""
    case = headlines[s["headline"]]
    clause, directness, body, presup, evaluation = templates[act][s1.integers(len(templates[act]))]
    body = body.format(case=case)
    code = {"clause_type": clause, "primary_act": act, "directness": directness, "presup": "N", "trigger_type": "",
            "presup_direction": "", "leading_construction": "None", "evaluative": "N", "polarity": "", "target": "",
            "partisan_terms": "", "stance_disclosure": "N", "disclosure_direction": ""}
    notes = []
    if presup:
        code.update(presup="Y", trigger_type=presup[0], presup_direction=presup[1])
        if presup[0] == "Multiple (list in Notes)":
            notes.append("Triggers: why question + change of state (keep)")
    if evaluation:
        code.update(evaluative="Y", polarity=evaluation[0], target=evaluation[1])
    if act in framing_acts:
        lean = {"left": (0.50, 0.08), "right": (0.08, 0.50), "centre": (0.12, 0.12)}[s["_stance"]]
        scale_by = 0.5 if act == "Explanation" else 1.0
        r = s1.random()
        direction = "Left" if r < lean[0] * scale_by else "Right" if r < (lean[0] + lean[1]) * scale_by else None
        if direction:
            trigger, leading, frame = presup_frames[s1.integers(len(presup_frames))]
            term = partisan[s["headline"]][0 if direction == "Left" else 1]
            body = frame.format(term=term) + body
            if code["presup"] == "Y":
                notes.append(f"Triggers: {code['trigger_type'].lower()} + {trigger.lower()}")
                trigger = "Multiple (list in Notes)"
            code.update(presup="Y", trigger_type=trigger, presup_direction=direction, leading_construction=leading,
                        partisan_terms=term, evaluative="Y", polarity=code["polarity"] or "Negative",
                        target=code["target"] or "Issue/situation")
    if act == "Opinion" and s1.random() < 0.25:     # a party name on its own is never a partisan-coded term
        body += f", {pick(parties[s['country']])} must be thrilled"
        code.update(evaluative="Y", polarity=code["polarity"] or pick(["Positive", "Mixed"]), target="Party/politician")
    if s1.random() < 0.22:
        body += pick(hedge_words)
    return body, code, notes

# ---- conversations: queries, LLM replies, actions, and think-aloud ----
fillers = ["um", "uh", "like", "you know"]
think_aloud = {"Summary": "okay I guess I'd start with what actually happened", "Explanation": "I wanna know why they decided that",
               "Evaluation of fairness": "I'm gonna ask if it's fair", "Prediction": "what happens now I guess",
               "Opinion": "let's see what it thinks", "Personal advice": "I kind of want to know what I should do",
               "Verification": "wait is that even true", "Clarification": "I don't know what that word means",
               "Pushback": "that's NOT what I asked", "Meta": "I wonder if it's even allowed to say"}
def spoken(text):
    """Spoken speech, transcribed verbatim: fillers, pauses, and the odd cut-off."""
    words = text.split()
    out = []
    for k, w in enumerate(words):
        if s1.random() < 0.10:
            out.append(pick(fillers))
        if s1.random() < 0.06:
            out.append(pick(["(.)", "(.)", "(2)"]))
        if k > 0 and s1.random() < 0.03 and len(w) > 3:
            out.append(w[:2] + "-")
        out.append(w)
    return " ".join(out)

reply_open = {"Summary": "Here's a short summary of {case}.", "Explanation": "The court's reasoning turned on a few points.",
              "Evaluation of fairness": "Whether the ruling was fair depends on which considerations you weigh.",
              "Prediction": "It's hard to say for certain, but appeals are common in cases like this.",
              "Opinion": "I don't have personal opinions, but I can lay out the main arguments.",
              "Personal advice": "That's a personal decision, but here are some things to consider.",
              "Verification": "Good question; here's what the record shows.",
              "Clarification": "Sure. In this case, it means the court's power to hear the dispute at all.",
              "Pushback": "That's fair; let me give a fuller picture.",
              "Meta": "I aim to present the main perspectives rather than take a side."}
sides = ["supporters of the ruling", "opponents of the ruling"]

transcripts, coding, export, card_labels = [], [], [], []
for s in sessions:
    pid, case = s["participant"], headlines[s["headline"]]
    hedged_side = s1.integers(2)          # replies attach "some critics argue" to one side only
    n_q = int(np.clip(s1.poisson(6.5), 3, 11))
    chat_break = int(s1.integers(3, n_q)) if s1.random() < 0.2 and n_q > 4 else None
    disclose_at = int(s1.integers(0, n_q)) if s["_disclosure"] in ("5.1", "5.2") else None
    t = 300 + int(s1.integers(0, 120))                    # seconds into the recording
    rows = []
    def add(turn_type, text, turn_id="", notes="", question=""):
        rows.append({"participant": pid, "line": len(rows) + 1, "time": f"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}",
                     "turn_type": turn_type, "turn_id": turn_id, "question": question, "text": text, "notes": notes})
    add("INT", "so whatever you'd normally ask, go for it")
    chat, q_in_chat, msg_index = 1, 0, 0
    for q in range(n_q):
        if chat_break is not None and q == chat_break:
            t += 4; add("ACT", "new chat"); chat += 1; q_in_chat = 0
        q_in_chat += 1
        frac = q / max(n_q - 1, 1)
        n_acts = 2 if s1.random() < 0.15 else 1
        act_codes, texts, act_notes = [], [], []
        for a in range(n_acts):
            p = (1 - frac) * early10 + frac * late10
            if q_in_chat == 1 and a == 0:
                p = p.copy(); p[acts10.index("Pushback")] = 0; p = p / p.sum()
            act = acts10[s1.choice(10, p=p)]
            body, code, notes_for_act = make_act(act, s)
            if a == 0 and disclose_at == q:          # stance disclosure is set-up material: it stays with its request
                phrase, direction = disclosure_phrases[s["_stance"]]
                body = phrase + body
                code.update(stance_disclosure="Y", disclosure_direction=direction)
            texts.append(body); act_codes.append(code); act_notes.append(notes_for_act)
        # relation to the previous model turn (New / Continuation / Uptake)
        for a, code in enumerate(act_codes):
            if q_in_chat == 1 and a == 0:
                code["relation"] = "New"
            elif a > 0 or code["primary_act"] == "Pushback":
                code["relation"] = "Continuation"
            else:
                code["relation"] = pick(["Continuation", "New", "Uptake"], p=[0.70, 0.18, 0.12])
        if act_codes[0]["relation"] == "Uptake":
            texts[0] = "ok that makes sense. " + texts[0]           # set-up material stays with its request
        # orthography of what was actually sent
        voice = s1.random() < 0.05
        joiner = pick([". also ", " ↵", " and also "])
        pieces = []
        for a, body in enumerate(texts):
            piece = body if a == 0 else joiner + body
            pieces.append(piece)
        if not voice:
            if s1.random() < 0.12:     # a typo, kept exactly as typed
                for right, wrong in typos.items():
                    if re.search(rf"\b{right}\b", pieces[0]):
                        pieces[0] = re.sub(rf"\b{right}\b", wrong, pieces[0], count=1); break
            if s1.random() < 0.55 and act_codes[-1]["clause_type"].startswith("Interrogative"):
                pieces[-1] += "?"
            if s1.random() < 0.05:
                pieces[-1] += " 🤔"
            if s1.random() < 0.30:
                pieces[0] = pieces[0][0].upper() + pieces[0][1:]
        else:
            pieces[0] = pieces[0][0].upper() + pieces[0][1:]
            pieces[-1] += "?" if act_codes[-1]["clause_type"].startswith("Interrogative") else "."
        query = "".join(pieces)
        qid = f"{pid}_C{chat}_Q{q_in_chat:02d}"
        notes = "voice input" if voice else ""
        if s1.random() < 0.05 and not voice:
            notes = 'typed "' + pick(parties[s["country"]]) + '", deleted, wrote "the government"'
        # think-aloud before typing
        if s1.random() < 0.6:
            t += int(s1.integers(5, 20))
            said, said_notes = spoken(think_aloud[act_codes[0]["primary_act"]]), ""
            if s1.random() < 0.06:           # de-identified by the transcriber, and logged
                said += ' my friend [NAME-friend] is like "it\'s all propaganda"'
                said_notes = "swapped a private name for [NAME-friend]"
            add("PAR", said, notes=said_notes)
        t += int(s1.integers(6, 25))
        add("QRY", query, qid, notes)
        msg_index += 1
        export.append({"participant": pid, "chat": chat, "message_index": msg_index, "role": "user", "text": query,
                       "seconds_into_recording": t})
        sent = [(qid, query, act_codes, pieces)]
        # edit and resend: the original stays, the edited version is a new query (Q03b)
        if s1.random() < 0.08:
            t += int(s1.integers(8, 20))
            add("ACT", "edit and resend")
            new_pieces = [piece.replace(case, "the court case") for piece in pieces]
            if new_pieces == pieces:
                new_pieces[-1] += " please"
            edited = "".join(new_pieces)
            t += 2
            add("QRY", edited, qid + "b")
            msg_index += 1
            export.append({"participant": pid, "chat": chat, "message_index": msg_index, "role": "user", "text": edited,
                           "seconds_into_recording": t})
            sent.append((qid + "b", edited, [dict(cd) for cd in act_codes], new_pieces))
            sent[-1][2][0]["relation"] = "Continuation"           # the resent version follows the original
        main = act_codes[0]["primary_act"]
        reply = reply_open[main].format(case=case)
        if main in ("Summary", "Explanation", "Evaluation of fairness", "Opinion", "Pushback"):
            first, second = (sides if hedged_side == 0 else sides[::-1])
            reply += f" {first.capitalize()} say the decision follows the law, while some critics argue it goes too far. {second.capitalize()} point to its effects on the people involved."
        t += int(s1.integers(4, 10))
        add("LLM", reply, sent[-1][0].replace("_Q", "_R"), "full text pasted")   # answers the query just sent
        msg_index += 1
        export.append({"participant": pid, "chat": chat, "message_index": msg_index, "role": "assistant", "text": reply,
                       "seconds_into_recording": t})
        if s1.random() < 0.06:
            t += int(s1.integers(10, 30)); add("ACT", "regenerate")
            t += 5; add("LLM", reply.replace("some critics argue", "others argue"), sent[-1][0].replace("_Q", "_R").rstrip("b") + "b", "full text pasted")
            msg_index += 1
            export.append({"participant": pid, "chat": chat, "message_index": msg_index, "role": "assistant",
                           "text": reply.replace("some critics argue", "others argue"), "seconds_into_recording": t})
        if s1.random() < 0.30:
            t += int(s1.integers(10, 40))
            add("PAR", "((reading)) " + pick(["some critics argue", reply.split(".")[0].lower(), "supporters of the ruling say"]) + " ((/reading)) " + pick(["okay", "hmm", "okay yeah"]))
        t += int(s1.integers(15, 60))
        # the coding sheet: one row per speech act; every character of the query lands in exactly one act
        for query_id, text, codes, act_pieces in sent:
            for a, (piece, code) in enumerate(zip(act_pieces, codes)):
                row_notes = "; ".join([notes] * (a == 0 and notes != "") + act_notes[a])
                coding.append({"speech_act_id": f"{query_id}_{'ab'[a]}", "query_id": query_id, "participant": pid,
                               "chat": f"C{chat}", "turn_position": int(query_id.split("_Q")[1][:2]), "llm": f"Model {s['model']}",
                               "query_text": text, "speech_act_text": piece, **code,
                               "confidence": int(3 if code["directness"] == "Direct" else pick([1, 2, 3], p=[0.2, 0.5, 0.3])),
                               "coder": "consensus", "notes": row_notes})
    if t < 600:
        add("INT", "is there anything else you'd want to know about it?")
    add("INT", "let's wrap up there.")
    t += 120

    # ---- the interview (Section B), answers built from the participant's framework codes ----
    c = s["_codes"]
    goals = {"1.1": "I wanted to know what actually happened", "1.2": "why the court decided the way it did",
             "1.3": "I kind of wanted to see if it would agree with what I already thought",
             "1.4": "honestly what the AI itself thought", "1.5": "I don't know, nothing specific really"}
    everyday = {"2.1": "yeah pretty much, that's how I'd ask", "2.2": "at home I'd probably be shorter, like more casual",
                "2.3": "honestly I'd probably just google it", "2.4": "I wouldn't really ask an AI about this"}
    meaning = {"3.1": "I meant like the process, whether it was done properly", "3.2": "more like whether the outcome was right",
               "3.3": "fair to the people actually affected", "3.4": "I'm not totally sure what I meant"}
    stance_ans = {"4.1": 'it gave both sides pretty equally, like separate paragraphs for each',
                  "4.2": "it mostly agreed with me", "4.3": 'it kept saying "some critics argue" but only for one side',
                  "4.4": "no, I think it tells you what you want to hear", "4.5": "yeah I think anyone would get the same thing",
                  "4.6": "I don't know, maybe I'm reading into it"}
    disclose_ans = {"5.1": "yeah I told it where I stand, I wanted it to know", "5.2": "oh did I? I guess I did, I didn't really notice",
                    "5.3": 'no, on purpose, I wanted "to see what it would say on its own"', "5.4": "no, I didn't really think to"}
    q_segments = []   # (question, text, codes on that segment)
    q_segments.append(("Q1", "in your own words, what were you trying to find out about this case?",
                       [(goals[k], [k]) for k in ["1.1", "1.2", "1.3", "1.4", "1.5"] if c[k]]))
    q_segments.append(("Q2", "is this how you would normally ask an AI about something like this?",
                       [(everyday[k], [k]) for k in ["2.1", "2.2", "2.3", "2.4"] if c[k]]))
    q_segments.append(("Q3", "what were you hoping to get from this question?", [(goals["1.1" if c["1.1"] else "1.5"], [])]))
    q_segments.append(("Q4", "what were you hoping to get from this question?",
                       [(goals["1.3"] if c["1.3"] else "I guess I wanted to see what it would say", [])]))
    q_segments.append(("Q5", "which of these best describes what you were asking for here?", [("that one's what happened I think", [])]))
    if s["_circled"]:
        q_segments.append(("Q6", "at one point you wrote fair. what did you mean by that?",
                           [(meaning[k], [k]) for k in ["3.1", "3.2", "3.3", "3.4"] if c[k]]))
    q_segments.append(("Q7", "overall, did the AI mostly agree with you, mostly challenge you, or neither?",
                       [(stance_ans[k], [k]) for k in ["4.1", "4.2"] if c[k]] or [("neither really", [])]))
    a7_said = s["a7_placement"] if s["a7_placement"].isdigit() else s["a7_placement"].replace("not_political", "not political")
    q8 = ([(f"I put it at like a {a7_said} I guess", [])] if a7_said.isdigit() else
          [("it didn't seem political to me", [])] if a7_said == "not political" else [("I really couldn't tell", [])])
    q8 += [(stance_ans[k], [k]) for k in ["4.3", "4.6"] if c[k]]
    q8_question = (f"on the form you placed the AI at {a7_said}. what made you put it there?" if a7_said.isdigit()
                   else f"on the form you said the AI's responses were {a7_said.replace('dont_know', 'hard to place')}. what made you say that?")
    q_segments.append(("Q8", q8_question, q8))
    q_segments.append(("Q9", "do you think someone with the opposite view would have gotten the same answers?",
                       [(stance_ans[k], [k]) for k in ["4.4", "4.5"] if c[k]] or [("I'm not sure", [])]))
    q_segments.append(("Q10", "did you tell the AI what you think about the case at any point?",
                       [(disclose_ans[k], [k]) for k in ["5.1", "5.2", "5.3", "5.4"] if c[k]]))
    extra = [("I don't really trust AI with this stuff in general", ["6.1"])] if c["6.1"] else []
    extra += [("the headline itself was kind of confusing", ["6.2"])] if c["6.2"] else []
    q_segments.append(("Q11", "is there anything else about the conversation you'd like to tell us?", extra or [("no, that's it", [])]))
    segment_rows = []
    for qnum, question, answers in q_segments:
        t += int(s1.integers(5, 15))
        add("INT", question, question=qnum)
        for text, codes in answers:
            t += int(s1.integers(3, 12))
            add("PAR", spoken(text), question=qnum)
            segment_rows.append((rows[-1]["line"], qnum, codes))
    s["_segments"] = segment_rows
    s["session_length"] = f"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}"
    transcripts.extend(rows)

    # Q5: the participant labels each query with the speech-act card (one label per query)
    for row in coding:
        if row["participant"] == pid and row["speech_act_id"].endswith("_a"):
            truth = card_of[row["primary_act"]]
            if row["primary_act"] == "Opinion" and "should" in row["speech_act_text"]:
                truth = "what someone should do"          # people read "what should the government do" as advice
            card_labels.append({"query_id": row["query_id"],
                                "card_label": truth if s1.random() < 0.84 else pick([x for x in cards if x != truth])})

# Three QRY rows were "fixed" by a transcriber instead of pasted from the export (a rule violation to catch)
qry_rows = [r for r in transcripts if r["turn_type"] == "QRY"]
for r in [qry_rows[k] for k in s1.choice(len(qry_rows), 3, replace=False)]:
    fixed = r["text"].replace("waht", "what").replace("teh", "the").replace("abuot", "about").replace(" 🤔", "")
    fixed = fixed[0].upper() + fixed[1:]
    r["text"] = fixed if fixed != r["text"] else fixed.rstrip("?") + "."

# Instrument-style items of the kind used in survey-based bias research, coded with the same codebook
instrument_forms = {
    "Summary": ("Imperative", "Provide a neutral, factual summary of {case} in no more than three sentences, without offering any evaluation of the decision."),
    "Explanation": ("Imperative", "Explain the legal reasoning behind {case} in neutral terms, without offering any evaluation of whether the decision was correct."),
    "Evaluation of fairness": ("Interrogative (wh)", "On a scale from 1 (very unfair) to 5 (very fair), how fair was the court's handling of {case}? Respond with a single number only."),
    "Prediction": ("Imperative", "Estimate the probability, from 0 to 100 percent, that {case} will be overturned on appeal. Respond with a single number only."),
    "Opinion": ("Imperative", "Please indicate the extent to which you agree or disagree with the following statement: the decision in {case} was correct. Respond with one option only.")}
instrument = []
for k in range(60):
    act = pick(list(instrument_forms), p=[0.03, 0.04, 0.15, 0.05, 0.73])
    clause, form = instrument_forms[act]
    text = form.format(case=list(headlines.values())[k % 6])
    instrument.append({"speech_act_id": f"INST_{k + 1:02d}_a", "query_id": f"INST_{k + 1:02d}", "participant": "", "chat": "",
                       "turn_position": "", "llm": "", "query_text": text, "speech_act_text": text, "clause_type": clause,
                       "primary_act": act, "directness": "Direct", "presup": "N", "trigger_type": "", "presup_direction": "",
                       "leading_construction": "None", "evaluative": "N", "polarity": "", "target": "", "partisan_terms": "",
                       "stance_disclosure": "N", "disclosure_direction": "", "relation": "New", "confidence": 3,
                       "coder": "consensus", "notes": ""})

# ---- independent coding: every transcript is coded by both members of its coding pair (Coder A and Coder B)
# before the consensus meeting. Their sheets differ from the consensus codes by occasional slips, by one coder
# reading "can you …" requests as Direct, and by splitting a few queries differently.
pair_initials = {"A": ("JM", "RK"), "B": ("SL", "TW"), "C": ("DN", "OP"), "D": ("EH", "VB")}
levels = {"clause_type": ["Declarative", "Interrogative (polar)", "Interrogative (wh)", "Imperative", "Fragment"],
          "primary_act": acts10, "trigger_type": ["Factive verb", "Evaluative description", "Change of state", "Why question",
                                                  "Multiple (list in Notes)"],
          "presup_direction": ["Left", "Right", "Neutral", "Unclear"], "leading_construction": ["None", "Tag question", "Negative polar"],
          "polarity": ["Positive", "Negative", "Mixed"],
          "target": ["Policy", "Party/politician", "Group", "LLM", "Issue/situation", "Media", "Other"],
          "disclosure_direction": ["Left", "Right", "Unclear"], "relation": ["New", "Continuation", "Uptake"]}
slip = {"clause_type": 0.02, "primary_act": 0.04, "presup": 0.02, "trigger_type": 0.06, "presup_direction": 0.04,
        "leading_construction": 0.01, "evaluative": 0.03, "polarity": 0.06, "target": 0.10, "partisan_terms": 0.04,
        "stance_disclosure": 0.005, "disclosure_direction": 0.02, "relation": 0.05}
dependents = {"presup": {"trigger_type": "Why question", "presup_direction": "Unclear"},
              "evaluative": {"polarity": "Negative", "target": "Other"}, "stance_disclosure": {"disclosure_direction": "Unclear"}}

def independent_codes(row, coder):
    out = dict(row)
    for col, rate in slip.items():
        if s1.random() >= rate:
            continue
        if col in dependents:                        # flipping Y/N also fills in or blanks the columns that depend on it
            out[col] = "N" if out[col] == "Y" else "Y"
            for dep, fill in dependents[col].items():
                out[dep] = fill if out[col] == "Y" else ""
        elif col == "partisan_terms":
            out[col] = ""                            # a candidate term overlooked
        elif out[col]:                               # only recode a column that applies
            out[col] = pick([v for v in levels[col] if v != out[col]])
    if re.search(r"\b(?:can|could) (?:you|u)\b", row["speech_act_text"].lower()):
        if s1.random() < (0.65 if coder == "B" else 0.08):
            out["directness"] = "Direct"             # against the draft rule: "can you …" counts as Indirect
    elif s1.random() < 0.03:
        out["directness"] = "Indirect" if out["directness"] == "Direct" else "Direct"
    out["confidence"] = int(pick([1, 2, 3], p=[0.1, 0.4, 0.5]))
    return out

coder_sheets = {"A": [], "B": []}
by_query = {}
for row in coding:
    by_query.setdefault(row["query_id"], []).append(row)
for qid, rows in by_query.items():
    initials = pair_initials[sessions[int(rows[0]["participant"][1:]) - 1]["coded_by"]]
    for row in rows:
        row["coder"] = "-".join(initials)            # the consensus codes carry both coders' initials
    for coder, ini in zip(("A", "B"), initials):
        segments = [dict(r) for r in rows]
        if len(rows) == 2 and coder == "B" and s1.random() < 0.25:
            merged = dict(rows[0])                   # Coder B keeps both requests as one act
            merged["speech_act_text"] = rows[0]["query_text"]
            segments = [merged]
        elif (len(rows) == 1 and coder == "A" and s1.random() < 0.5
              and rows[0]["speech_act_text"].lower().startswith("ok that makes sense. ")):
            uptake, rest = dict(rows[0]), dict(rows[0])     # Coder A splits the uptake off as its own act
            uptake.update(speech_act_text=rows[0]["speech_act_text"][:21], clause_type="Declarative", primary_act="Meta",
                          directness="Direct", presup="N", trigger_type="", presup_direction="", leading_construction="None",
                          evaluative="N", polarity="", target="", partisan_terms="", stance_disclosure="N",
                          disclosure_direction="", relation="Uptake")
            rest.update(speech_act_id=qid + "_b", speech_act_text=rows[0]["speech_act_text"][21:], relation="Continuation")
            segments = [uptake, rest]
        for segment in segments:
            coded = independent_codes(segment, coder)
            coded["coder"] = ini
            coder_sheets[coder].append(coded)

# ---- indexing agreement: two coders index the interview answers of the same 7 transcripts ----
# Category 4 is indexed in the answers to Q7–Q9 and category 5 in the answers to Q10. Code 4.6 was added
# inductively and is the least clearly defined, so it gets the most disagreements.
indexed_questions = {"4": ("Q7", "Q8", "Q9"), "5": ("Q10",)}
indexing = []
for s in sessions:
    if s["participant"] in double_coded:
        for line_no, qnum, codes in s["_segments"]:
            for code in ["4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "5.1", "5.2", "5.3", "5.4"]:
                if qnum in indexed_questions[code[0]]:
                    truth = int(code in codes)
                    indexing.append({"participant": s["participant"], "line": line_no, "code": code,
                                     "coder_a": truth, "coder_b": truth})
rows_46 = [r for r in indexing if r["code"] == "4.6"]
positives = [r for r in rows_46 if r["coder_a"] == 1]
negatives = [r for r in rows_46 if r["coder_a"] == 0]
missed = s1.choice(len(positives), min(2, len(positives)), replace=False)
added = s1.choice(len(negatives), 2, replace=False)
for j, coder in enumerate(("coder_a", "coder_b")):      # each coder misses one use of 4.6 and adds one stray
    if j < len(missed):
        positives[missed[j]][coder] = 0
    negatives[added[j]][coder] = 1

session_cols = [k for k in sessions[0] if not k.startswith("_")]
pd.DataFrame([{k: s[k] for k in session_cols} for s in sessions]).to_csv("llm_sessions.csv", index=False)
pd.DataFrame(transcripts).to_csv("llm_transcripts.csv", index=False)
recording = {s["participant"]: (s["session_date"], s["recording_start"]) for s in sessions}
exp = pd.DataFrame(export)
start = pd.Series(pd.to_datetime([f"{recording[p][0]} {recording[p][1]}" for p in exp["participant"]]))
exp["timestamp_utc"] = (start + pd.to_timedelta(exp["seconds_into_recording"] + 5 * 3600, unit="s")).dt.strftime("%Y-%m-%dT%H:%M:%SZ")
exp.drop(columns="seconds_into_recording").to_csv("llm_chat_export.csv", index=False)
pd.DataFrame(coding).to_csv("llm_coding.csv", index=False)
pd.DataFrame(coder_sheets["A"]).to_csv("llm_coder_a.csv", index=False)
pd.DataFrame(coder_sheets["B"]).to_csv("llm_coder_b.csv", index=False)
pd.DataFrame(card_labels).to_csv("llm_card_labels.csv", index=False)
pd.DataFrame(instrument).to_csv("llm_instrument_coding.csv", index=False)
pd.DataFrame(framework).to_csv("llm_framework.csv", index=False)
pd.DataFrame(indexing).to_csv("llm_indexing.csv", index=False)

# =============== Simulation 2, Study 2: llm_responses.csv (how models respond) ===============
# Query bank: 6 speech acts × 8 headlines (6 controversial + 2 controls) × 2 registers × 3 surface variants,
# each sent to 5 models 5 times in fresh sessions. lean: −3 = strongly left … 0 = neutral … +3 = strongly right
acts = ["summary", "explanation", "fairness", "prediction", "opinion", "advice"]   # the six query-bank speech acts
model_base = {"A": -0.45, "B": -0.30, "C": -0.20, "D": 0.10, "E": -0.05}    # fictional models
act_weight = {"summary": 0.4, "explanation": 0.6, "fairness": 1.2, "prediction": 0.8, "opinion": 1.4, "advice": 1.0}
headline_effect = rng.normal(0, 0.25, 6)
headline_effect = dict(zip(range(1, 9), np.r_[headline_effect - headline_effect.mean(), 0, 0]))   # centred
rows, qid = [], 0
for headline in range(1, 9):
    control = headline > 6
    for act in acts:
        for register in ["everyday", "instrument"]:
            for variant in range(1, 4):
                qid += 1
                query_effect = rng.normal(0, 0.25)
                for model, base in model_base.items():
                    for run in range(1, 6):
                        if control:
                            mu = 0.3 * query_effect
                        else:
                            mu = act_weight[act] * (base + headline_effect[headline]
                                                    + (-0.25 if register == "everyday" else 0.0)) + query_effect
                        lean = int(np.clip(np.round(mu + rng.normal(0, 0.8)), -3, 3))
                        rows.append({"query_id": qid, "headline": headline, "control": int(control),
                                     "speech_act": act, "register": register, "variant": variant,
                                     "model": model, "run": run, "lean": lean})
pd.DataFrame(rows).to_csv("llm_responses.csv", index=False)

print("Saved ppsr_survey.csv, credibility_trials.csv, ppsr_narratives.csv, ppsr_experiment.csv, llm_sessions.csv, "
      "llm_chat_export.csv, llm_transcripts.csv, llm_coding.csv, llm_coder_a.csv, llm_coder_b.csv, llm_card_labels.csv, "
      "llm_instrument_coding.csv, llm_framework.csv, llm_indexing.csv, llm_responses.csv")

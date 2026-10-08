import Foundation

// MARK: - Practice simulations
//
// Two simulated studies whose data recur across the course as "Practice simulation" exercises:
// a study of political parasocial attachment (a survey with a credibility task, coded interviews,
// and a randomized intervention), and a study of how people ask chatbots about political court cases
// (session transcripts, a speech-act coding sheet, double coding, a framework matrix, and repeated
// queries to five chatbots). Every person, figure, chatbot, and result is simulated.

extension Curriculum {
    /// The fourth practice-data script: the two practice simulations.
    static let simulationDataSample = CodeSample(
        caption: "generate_simulations — two practice simulations (data for the “Practice simulation” exercises)",
        python: #"""
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
        """#,
        r: #"""
        # generate_simulations.R — two practice simulations:
        #   1. Political parasocial attachment: ppsr_survey.csv, credibility_trials.csv, ppsr_narratives.csv,
        #      ppsr_experiment.csv
        #   2. Asking chatbots about political court cases: llm_sessions.csv, llm_chat_export.csv, llm_transcripts.csv,
        #      llm_coding.csv, llm_coder_a.csv, llm_coder_b.csv, llm_card_labels.csv, llm_instrument_coding.csv,
        #      llm_framework.csv, llm_indexing.csv, llm_responses.csv
        # All people, figures, chatbots ("models A–E"), and results are simulated.
        set.seed(2029)

        scale_to <- function(z, low, high, mid = (low + high) / 2, spread = 1) round(pmin(pmax(mid + spread * z, low), high), 2)

        # =============== Simulation 1, Study 1: ppsr_survey.csv and credibility_trials.csv ===============
        n <- 375
        stream <- c(rep("university", 150), rep("prolific", 225))
        age <- ifelse(stream == "university", sample(18:35, n, replace = TRUE), sample(18:75, n, replace = TRUE))
        country <- sample(c("Canada", "United States"), n, replace = TRUE, prob = c(0.55, 0.45))
        education <- pmin(pmax(ifelse(stream == "university", 3, 2) + sample(0:2, n, replace = TRUE), 1), 5)
        ideology_econ <- sample(1:7, n, replace = TRUE)           # 1 = left … 7 = right
        ideology_social <- pmin(pmax(ideology_econ + sample(-2:2, n, replace = TRUE), 1), 7)
        political_interest <- sample(2:5, n, replace = TRUE)      # 1–5

        psr_z      <- rnorm(n)                                    # parasocial intensity toward the nominated figure
        fusion_z   <- 0.65 * psr_z + 0.76 * rnorm(n)              # identity fusion with the figure (r ≈ .65)
        charisma_z <- 0.50 * psr_z + 0.87 * rnorm(n)              # charisma attributed to the figure
        wisdom_z   <- rnorm(n) + 0.015 * (age - 35)               # dispositional wisdom rises a little with age

        # Built-in truths: fusion drives credibility bias more than parasocial intensity;
        # wisdom weakens the parasocial → bias path; bias → polarization, plus a direct path
        bias_z <- 0.15 * psr_z + 0.35 * fusion_z - 0.10 * wisdom_z - 0.28 * psr_z * wisdom_z +
                  0.10 * charisma_z + rnorm(n, sd = 0.80)
        extremity <- abs(ideology_econ - 4) / 3
        ap_z <- 0.40 * bias_z + 0.15 * psr_z + 0.20 * extremity + rnorm(n, sd = 0.80)
        trust_z <- -0.20 * psr_z + rnorm(n, sd = 0.95)

        survey <- data.frame(
          participant = 1:n, stream, country, age, education, ideology_econ, ideology_social, political_interest,
          parasocial = scale_to(psr_z, 1, 7, mid = 4.2),                      # PSR-P mean, 1–7
          prism = scale_to(0.85 * psr_z + 0.5 * rnorm(n), 1, 7, mid = 4.0),   # PRISM mean, 1–7
          fusion = scale_to(fusion_z, 1, 7, mid = 3.6, spread = 1.2),         # verbal fusion, 1–7
          charisma = scale_to(charisma_z, 1, 5, mid = 3.4, spread = 0.7),
          affective_polarization = scale_to(ap_z, 1, 7, mid = 4.3),
          institutional_trust = scale_to(trust_z, 1, 7, mid = 3.9)
        )

        # 3D-WS-12: four cognitive, four reflective, four affective items (1–5); items 2, 6, 7, 11 are reverse-worded
        reversed_items <- c(2, 6, 7, 11)
        for (i in 1:12) {
          item <- pmin(pmax(round(3.3 + 0.75 * wisdom_z + rnorm(n, sd = 0.75)), 1), 5)
          survey[[paste0("wis_", i)]] <- as.integer(if (i %in% reversed_items) 6 - item else item)
        }
        keyed <- survey[paste0("wis_", 1:12)]
        keyed[paste0("wis_", reversed_items)] <- 6 - keyed[paste0("wis_", reversed_items)]
        survey$wisdom <- round(rowMeans(keyed), 3)                # precomputed so you can check your scoring

        # Credibility judgment task: 12 descriptions (1–6 creditable, 7–12 discrediting), half attributed to the
        # nominated (favoured) figure and half to the most-disliked figure, randomized for each participant
        plausibility <- rnorm(12, sd = 0.4)                       # some descriptions are simply more believable
        shift <- 0.55 + 0.45 * bias_z                             # each person's pull toward their own figure
        coupling <- 0.30 - 0.12 * wisdom_z + rnorm(n, sd = 0.10)  # how much confidence tracks protectiveness
        leniency <- rnorm(n, sd = 0.4)                            # some people find everything more believable
        trials <- do.call(rbind, lapply(1:n, function(p) {
          favoured <- c(sample(c(1, 1, 1, 0, 0, 0)), sample(c(1, 1, 1, 0, 0, 0)))
          confidence_level <- rnorm(1, sd = 0.4)
          creditable <- 1:12 <= 6
          protective_if_high <- (favoured == 1) == creditable     # high credibility favours own side
          latent <- plausibility + leniency[p] + ifelse(protective_if_high, shift[p], -shift[p]) + rnorm(12, sd = 0.8)
          credibility <- as.integer(pmin(pmax(round(3 + latent), 1), 5))
          protect <- ifelse(protective_if_high, credibility, 6 - credibility)
          confidence <- as.integer(pmin(pmax(round(3.3 + confidence_level + coupling[p] * (protect - 3) +
                                                   rnorm(12, sd = 0.7)), 1), 5))
          data.frame(participant = p, description = 1:12,
                     valence = ifelse(creditable, "creditable", "discrediting"),
                     target = ifelse(favoured == 1, "favoured", "disliked"), credibility, confidence)
        }))
        write.csv(trials, "credibility_trials.csv", row.names = FALSE)

        # Each participant's credibility bias: mean protectiveness (1–5) minus the midpoint 3
        protective <- with(trials, ifelse((target == "favoured") == (valence == "creditable"), credibility, 6 - credibility))
        survey$credibility_bias <- round(as.vector(tapply(protective, trials$participant, mean)) - 3, 3)
        write.csv(survey, "ppsr_survey.csv", row.names = FALSE)

        # =============== Simulation 1, Study 2: ppsr_narratives.csv (coded interviews) ===============
        # Fixed counts, so Python and R give identical tables: where each narrative places the political figure
        narratives <- data.frame(
          group = rep(c("maintained", "breakup"), each = 15),
          figure_position = c(rep("helper", 10), rep("subject", 5), rep("opponent", 11), rep("helper", 3), "subject"),
          # breakup group only: did the person's political commitments outlast the bond?
          commitments_survived = c(rep(NA, 15), rep(1, 11), rep(0, 4))
        )
        narratives <- narratives[sample(nrow(narratives)), ]
        narratives <- cbind(participant = 1:30, narratives)
        write.csv(narratives, "ppsr_narratives.csv", row.names = FALSE)

        # =============== Simulation 1, Study 3: ppsr_experiment.csv (three-arm intervention) ===============
        n3 <- 137
        arm <- sample(c(rep("wise", 46), rep("parasocial", 46), rep("observer", 45)))
        issue <- sample(c("climate", "immigration", "taxation", "content_moderation"), n3, replace = TRUE)
        pre_psr_z <- rnorm(n3)
        wisdom3 <- scale_to(rnorm(n3), 1, 5, mid = 3.4, spread = 0.6)
        effect <- c(wise = -0.36, parasocial = 0.10, observer = 0)[arm]       # in SD units (truth)
        post_psr_z <- 0.75 * pre_psr_z + effect + rnorm(n3, sd = 0.66)
        pre_ap_z <- 0.3 * pre_psr_z + rnorm(n3, sd = 0.95)
        post_ap_z <- 0.80 * pre_ap_z + 0.35 * effect + rnorm(n3, sd = 0.60)
        write.csv(data.frame(
          participant = 1:n3, arm,
          stream = sample(c("university", "prolific"), n3, replace = TRUE, prob = c(0.4, 0.6)),
          issue, wisdom = wisdom3,
          pre_prism = scale_to(pre_psr_z, 1, 7, mid = 4.3), post_prism = scale_to(post_psr_z, 1, 7, mid = 4.3),
          pre_ap = scale_to(pre_ap_z, 1, 7, mid = 4.2), post_ap = scale_to(post_ap_z, 1, 7, mid = 4.2),
          manipulation_check = as.integer(pmin(pmax(round(5 + rnorm(n3, sd = 1.2)), 1), 7)),
          words = sample(75:259, n3, replace = TRUE) * 3
        ), "ppsr_experiment.csv", row.names = FALSE)

        # =============== Simulation 2, Study 1: sessions, transcripts, and coding (how people prompt) ===============
        # Modeled on a structured-interview pipeline: a rating form, an exported chat log, a turn-by-turn transcript
        # (INT / PAR / QRY / LLM / ACT rows), a speech-act coding sheet with both coders' independent sheets, and a framework matrix.
        set.seed(2032)
        pick <- function(options, p = NULL) options[[sample.int(length(options), 1, prob = p)]]
        clip <- function(x, lo, hi) min(max(x, lo), hi)
        hms <- function(t) sprintf("%02d:%02d:%02d", t %/% 3600, t %% 3600 %/% 60, t %% 60)
        capitalize <- function(x) paste0(toupper(substr(x, 1, 1)), substring(x, 2))

        headlines <- c("US-1" = "the pipeline injunction", "US-2" = "the school library ruling", "US-3" = "the border detention case",
                       "CA-1" = "the transit strike injunction", "CA-2" = "the clinic buffer zone case", "CA-3" = "the language law ruling")
        partisan <- list("US-1" = c("climate crisis", "energy independence"), "US-2" = c("book bans", "parental rights"),
                         "US-3" = c("asylum seekers", "illegal immigrants"), "CA-1" = c("workers' rights", "union bosses"),
                         "CA-2" = c("reproductive rights", "pro-life"), "CA-3" = c("minority rights", "activist judges"))
        parties <- list(US = c("democrats", "republicans"), CA = c("the liberals", "the conservatives"))
        pairs <- c("A", "B", "C", "D")
        double_coded <- c("P003", "P007", "P012", "P016", "P021", "P025", "P030")   # 7 of 32 (about 20%)
        all_codes <- c("1.1", "1.2", "1.3", "1.4", "1.5", "2.1", "2.2", "2.3", "2.4", "3.1", "3.2", "3.3", "3.4",
                       "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "5.1", "5.2", "5.3", "5.4", "6.1", "6.2")

        # ---- participants, case attributes, and framework codes ----
        n_s1 <- 32
        stance_list <- sample(c(rep("left", 12), rep("right", 12), rep("centre", 8)))
        sessions <- list(); framework <- list()
        for (i in 1:n_s1) {
          pid <- sprintf("P%03d", i)
          country <- if (i %% 2 == 1) "US" else "CA"
          headline <- sprintf("%s-%d", country, ((i - 1) %/% 2) %% 3 + 1)
          stance <- stance_list[i]
          p1 <- switch(stance, left = sample(0:3, 1), centre = sample(4:6, 1), right = sample(7:10, 1))
          # Interview codes (deductive framework, version 1)
          disclosure <- pick(c("5.1", "5.2", "5.3", "5.4"), p = c(0.25, 0.15, 0.30, 0.30))
          cc <- setNames(as.list(rep(0L, length(all_codes))), all_codes)
          cc[[disclosure]] <- 1L
          cc[["4.3"]] <- as.integer(runif(1) < c(right = 0.65, left = 0.30, centre = 0.35)[[stance]])
          cc[["4.1"]] <- as.integer(cc[["4.3"]] == 0 && runif(1) < (if (disclosure == "5.3") 0.75 else 0.35))
          cc[["4.2"]] <- as.integer(runif(1) < (if (disclosure == "5.1") 0.65 else 0.12))
          cc[["4.6"]] <- as.integer(runif(1) < (if (cc[["4.3"]] == 1) 0.65 else 0.05))
          cc[["4.4"]] <- as.integer(runif(1) < 0.40)
          cc[["4.5"]] <- as.integer(cc[["4.4"]] == 0 && runif(1) < 0.55)
          cc[["1.1"]] <- as.integer(runif(1) < 0.80)
          cc[["1.2"]] <- as.integer(runif(1) < 0.55)
          cc[["1.3"]] <- as.integer(runif(1) < (if (disclosure == "5.3") 0.55 else 0.15))
          cc[["1.4"]] <- as.integer(runif(1) < 0.30)
          cc[["1.5"]] <- as.integer(cc[["1.1"]] + cc[["1.2"]] + cc[["1.3"]] + cc[["1.4"]] == 0)
          cc[[pick(c("2.1", "2.2", "2.3", "2.4"), p = c(0.35, 0.40, 0.15, 0.10))]] <- 1L
          circled <- runif(1) < 0.70                       # a word was circled during the task, so Q6 is asked
          if (circled) cc[[pick(c("3.1", "3.2", "3.3", "3.4"), p = c(0.35, 0.30, 0.25, 0.10))]] <- 1L
          cc[["6.1"]] <- as.integer(runif(1) < 0.20)
          cc[["6.2"]] <- as.integer(runif(1) < 0.25)
          framework[[i]] <- c(list(participant = pid), setNames(cc, paste0("code_", sub(".", "_", all_codes, fixed = TRUE))))

          # Rating form (A1–A7); special answers are kept as text, exactly as written on the form
          a1 <- clip(round((if (cc[["4.2"]] == 1) 6 else 4) + rnorm(1, sd = 1.1)), 1, 7)
          a2 <- clip(round(a1 - 0.3 + rnorm(1, sd = 1.0)), 1, 7)
          a3 <- if (runif(1) < 0.12) "dont_know" else as.character(clip(round(4 + rnorm(1, sd = 1.6)), 1, 7))
          a4 <- clip(round(3 + rnorm(1, sd = 1.0)), 1, 5)
          a6 <- if (cc[["4.3"]] == 1) (if (runif(1) < 0.8) "Yes" else "Not sure") else if (cc[["4.1"]] == 1) "No" else pick(c("No", "Yes", "Not sure"))
          r <- runif(1)
          a7 <- if (cc[["4.1"]] == 1 && r < 0.25) "not_political" else if (r > 0.93) "dont_know" else
            as.character(clip(round(5 - 0.30 * (p1 - 5) + rnorm(1, sd = 1.6)), 0, 10))   # people further right place the AI further left
          sessions[[i]] <- list(participant = pid, interview_order = i, session_date = as.character(as.Date("2026-11-09") + floor((i - 1) * 1.2)),
                                recording_start = sprintf("%02d:%02d", sample(9:16, 1), sample(0:59, 1)), utc_offset = -5,
                                country = country, headline = headline, model = LETTERS[(i - 1) %% 5 + 1], p1_self_placement = p1,
                                transcribed_by = pairs[(i - 1) %% 4 + 1], coded_by = pairs[i %% 4 + 1], double_coded = as.integer(pid %in% double_coded),
                                a1_agree = a1, a2_trust = a2, a3_fair = a3, a4_confidence = a4,
                                a5_difficulty = clip(round(3.5 + rnorm(1, sd = 1.4)), 1, 7), a6_side = a6, a7_placement = a7,
                                .stance = stance, .disclosure = disclosure, .circled = circled, .codes = cc)
        }

        # ---- speech acts: the coding sheet's levels (drafts until the codebook is frozen) ----
        acts10 <- c("Summary", "Explanation", "Evaluation of fairness", "Opinion", "Prediction", "Personal advice",
                    "Verification", "Clarification", "Pushback", "Meta")
        early10 <- c(0.34, 0.26, 0.07, 0.05, 0.07, 0.02, 0.08, 0.08, 0.00, 0.03)
        late10 <- c(0.04, 0.13, 0.20, 0.20, 0.12, 0.08, 0.05, 0.06, 0.07, 0.05)
        # clause type, directness, text, presupposition (trigger, direction), evaluation (polarity, target);
        # under the draft rule, "can you …" requests are coded Indirect (conventionally indirect)
        tpl <- function(clause, directness, text, presup = NULL, evaluation = NULL)
          list(clause = clause, directness = directness, text = text, presup = presup, evaluation = evaluation)
        templates <- list(
          "Summary" = list(tpl("Interrogative (wh)", "Direct", "what happened with {case}"), tpl("Imperative", "Direct", "summarize {case}"),
                           tpl("Imperative", "Direct", "give me the short version of {case}"),
                           tpl("Interrogative (polar)", "Indirect", "can you summarize {case}"),
                           tpl("Interrogative (polar)", "Indirect", "can u explain what {case} actually does"),
                           tpl("Fragment", "Direct", "{case} summary")),
          "Explanation" = list(tpl("Interrogative (wh)", "Direct", "why did the court rule that way", c("Why question", "Neutral")),
                               tpl("Interrogative (wh)", "Direct", "how does {case} work legally"),
                               tpl("Imperative", "Direct", "explain the reasoning behind the ruling"),
                               tpl("Interrogative (polar)", "Indirect", "can you explain what the judge actually said"),
                               tpl("Declarative", "Indirect", "im curious why the judge decided that", c("Why question", "Neutral"))),
          "Evaluation of fairness" = list(tpl("Interrogative (polar)", "Direct", "was {case} decided fairly"),
                                          tpl("Interrogative (polar)", "Direct", "is the ruling fair to both sides"),
                                          tpl("Interrogative (polar)", "Indirect", "could you tell me if the ruling was fair"),
                                          tpl("Interrogative (polar)", "Direct", "honestly the ruling seems pretty unfair, was it", NULL, c("Negative", "Policy"))),
          "Opinion" = list(tpl("Interrogative (wh)", "Direct", "what do you think about {case}"),
                           tpl("Interrogative (polar)", "Direct", "do you agree with the ruling"),
                           tpl("Imperative", "Direct", "give me your honest opinion"),
                           tpl("Interrogative (polar)", "Indirect", "can you tell me your take on it"),
                           tpl("Interrogative (wh)", "Direct", "what should the government do now")),
          "Prediction" = list(tpl("Interrogative (wh)", "Direct", "what happens next"), tpl("Interrogative (polar)", "Direct", "will it get appealed"),
                              tpl("Interrogative (polar)", "Indirect", "can you guess whether it gets overturned"),
                              tpl("Declarative", "Indirect", "i wonder if this goes to the supreme court")),
          "Personal advice" = list(tpl("Interrogative (polar)", "Direct", "should i sign the petition"),
                                   tpl("Interrogative (wh)", "Direct", "what should i do about this"),
                                   tpl("Interrogative (polar)", "Indirect", "can you help me decide whether to go to the protest"),
                                   tpl("Declarative", "Indirect", "im thinking about writing to my representative")),
          "Verification" = list(tpl("Interrogative (polar)", "Direct", "is that true"), tpl("Imperative", "Direct", "fact check that last part"),
                                tpl("Interrogative (polar)", "Indirect", "can you check if that's accurate"),
                                tpl("Interrogative (polar)", "Direct", "are you sure about that")),
          "Clarification" = list(tpl("Interrogative (wh)", "Direct", "what do u mean by standing"),
                                 tpl("Interrogative (wh)", "Direct", "wait what's an injunction"),
                                 tpl("Interrogative (polar)", "Indirect", "can you say that more simply")),
          "Pushback" = list(tpl("Declarative", "Direct", "thats not true", NULL, c("Negative", "LLM")),
                            tpl("Declarative", "Direct", "that seems pretty one sided", NULL, c("Negative", "LLM")),
                            tpl("Interrogative (wh)", "Direct", "why are you only giving one side", c("Why question", "Unclear"), c("Negative", "LLM")),
                            tpl("Declarative", "Indirect", "i feel like you're leaving something out", NULL, c("Negative", "LLM"))),
          "Meta" = list(tpl("Interrogative (polar)", "Direct", "are you allowed to have opinions on this"),
                        tpl("Interrogative (polar)", "Direct", "are you just programmed to avoid this stuff", NULL, c("Negative", "LLM")),
                        tpl("Interrogative (wh)", "Direct", "why do you keep saying some critics argue", c("Multiple (list in Notes)", "Unclear"), c("Negative", "LLM")))
        )
        card_of <- c("Summary" = "what happened", "Explanation" = "why or how it happened", "Evaluation of fairness" = "whether it was fair",
                     "Prediction" = "what will happen next", "Opinion" = "what the AI thinks", "Personal advice" = "what someone should do",
                     "Verification" = "none of these", "Clarification" = "none of these", "Pushback" = "none of these", "Meta" = "none of these")
        cards <- sort(unique(card_of))
        disclosure_phrases <- list(left = c("im pretty left wing, ", "Left"), right = c("im pretty conservative but i want a straight answer. ", "Right"),
                                   centre = c("im kind of in the middle on this, ", "Unclear"))
        # Presupposed partisan framings: trigger type, leading construction, text
        presup_frames <- list(c("Factive verb", "None", "now that everyone knows it's about {term}, "),
                              c("Evaluative description", "None", "with all the {term} chaos, "),
                              c("Change of state", "None", "since the {term} situation got worse, "),
                              c("Evaluative description", "Negative polar", "isn't this really about {term}? "),
                              c("Evaluative description", "Tag question", "this is all about {term}, right? "))
        hedge_words <- c(", i guess", " maybe", ", kind of", ", probably")
        typos <- c(what = "waht", the = "teh", because = "becuase", about = "abuot")
        framing_acts <- c("Evaluation of fairness", "Opinion", "Personal advice", "Explanation")

        make_act <- function(act, s) {   # one speech act's text and its consensus codes (blank where a column doesn't apply)
          case <- headlines[[s$headline]]
          tp <- templates[[act]][[sample.int(length(templates[[act]]), 1)]]
          body <- gsub("{case}", case, tp$text, fixed = TRUE)
          code <- list(clause_type = tp$clause, primary_act = act, directness = tp$directness, presup = "N", trigger_type = "",
                       presup_direction = "", leading_construction = "None", evaluative = "N", polarity = "", target = "",
                       partisan_terms = "", stance_disclosure = "N", disclosure_direction = "")
          notes <- character(0)
          if (!is.null(tp$presup)) {
            code[c("presup", "trigger_type", "presup_direction")] <- list("Y", tp$presup[1], tp$presup[2])
            if (tp$presup[1] == "Multiple (list in Notes)") notes <- c(notes, "Triggers: why question + change of state (keep)")
          }
          if (!is.null(tp$evaluation)) code[c("evaluative", "polarity", "target")] <- list("Y", tp$evaluation[1], tp$evaluation[2])
          if (act %in% framing_acts) {
            lean <- list(left = c(0.50, 0.08), right = c(0.08, 0.50), centre = c(0.12, 0.12))[[s$.stance]]
            scale_by <- if (act == "Explanation") 0.5 else 1
            r <- runif(1)
            direction <- if (r < lean[1] * scale_by) "Left" else if (r < (lean[1] + lean[2]) * scale_by) "Right" else NA
            if (!is.na(direction)) {
              fr <- presup_frames[[sample.int(length(presup_frames), 1)]]
              term <- partisan[[s$headline]][if (direction == "Left") 1 else 2]
              body <- paste0(sub("{term}", term, fr[3], fixed = TRUE), body)
              trigger <- fr[1]
              if (code$presup == "Y") {
                notes <- c(notes, paste0("Triggers: ", tolower(code$trigger_type), " + ", tolower(trigger)))
                trigger <- "Multiple (list in Notes)"
              }
              code[c("presup", "trigger_type", "presup_direction", "leading_construction", "partisan_terms", "evaluative")] <-
                list("Y", trigger, direction, fr[2], term, "Y")
              if (code$polarity == "") code$polarity <- "Negative"
              if (code$target == "") code$target <- "Issue/situation"
            }
          }
          if (act == "Opinion" && runif(1) < 0.25) {      # a party name on its own is never a partisan-coded term
            body <- paste0(body, ", ", pick(parties[[s$country]]), " must be thrilled")
            code$evaluative <- "Y"
            if (code$polarity == "") code$polarity <- pick(c("Positive", "Mixed"))
            code$target <- "Party/politician"
          }
          if (runif(1) < 0.22) body <- paste0(body, pick(hedge_words))
          list(body = body, code = code, notes = notes)
        }

        # ---- conversations: queries, LLM replies, actions, and think-aloud ----
        fillers <- c("um", "uh", "like", "you know")
        think_aloud <- c("Summary" = "okay I guess I'd start with what actually happened", "Explanation" = "I wanna know why they decided that",
                         "Evaluation of fairness" = "I'm gonna ask if it's fair", "Prediction" = "what happens now I guess",
                         "Opinion" = "let's see what it thinks", "Personal advice" = "I kind of want to know what I should do",
                         "Verification" = "wait is that even true", "Clarification" = "I don't know what that word means",
                         "Pushback" = "that's NOT what I asked", "Meta" = "I wonder if it's even allowed to say")
        spoken <- function(text) {   # spoken speech, transcribed verbatim: fillers, pauses, and the odd cut-off
          words <- strsplit(text, " ")[[1]]
          out <- character(0)
          for (k in seq_along(words)) {
            w <- words[k]
            if (runif(1) < 0.10) out <- c(out, pick(fillers))
            if (runif(1) < 0.06) out <- c(out, pick(c("(.)", "(.)", "(2)")))
            if (k > 1 && runif(1) < 0.03 && nchar(w) > 3) out <- c(out, paste0(substr(w, 1, 2), "-"))
            out <- c(out, w)
          }
          paste(out, collapse = " ")
        }
        reply_open <- c("Summary" = "Here's a short summary of {case}.", "Explanation" = "The court's reasoning turned on a few points.",
                        "Evaluation of fairness" = "Whether the ruling was fair depends on which considerations you weigh.",
                        "Prediction" = "It's hard to say for certain, but appeals are common in cases like this.",
                        "Opinion" = "I don't have personal opinions, but I can lay out the main arguments.",
                        "Personal advice" = "That's a personal decision, but here are some things to consider.",
                        "Verification" = "Good question; here's what the record shows.",
                        "Clarification" = "Sure. In this case, it means the court's power to hear the dispute at all.",
                        "Pushback" = "That's fair; let me give a fuller picture.",
                        "Meta" = "I aim to present the main perspectives rather than take a side.")
        sides <- c("supporters of the ruling", "opponents of the ruling")

        transcripts <- list(); coding <- list(); export <- list(); card_labels <- list()
        for (si in seq_along(sessions)) {
          s <- sessions[[si]]
          pid <- s$participant; case <- headlines[[s$headline]]
          hedged_side <- sample(0:1, 1)               # replies attach "some critics argue" to one side only
          n_q <- clip(rpois(1, 6.5), 3, 11)
          chat_break <- if (runif(1) < 0.2 && n_q > 4) sample(3:(n_q - 1), 1) else NA
          disclose_at <- if (s$.disclosure %in% c("5.1", "5.2")) sample(0:(n_q - 1), 1) else NA
          t <- 300 + sample(0:119, 1)                 # seconds into the recording
          rows <- list()
          add <- function(turn_type, text, turn_id = "", notes = "", question = "") {
            rows[[length(rows) + 1]] <<- list(participant = pid, line = length(rows) + 1, time = hms(t), turn_type = turn_type,
                                              turn_id = turn_id, question = question, text = text, notes = notes)
          }
          add("INT", "so whatever you'd normally ask, go for it")
          chat <- 1; q_in_chat <- 0; msg_index <- 0
          for (q in 0:(n_q - 1)) {
            if (!is.na(chat_break) && q == chat_break) { t <- t + 4; add("ACT", "new chat"); chat <- chat + 1; q_in_chat <- 0 }
            q_in_chat <- q_in_chat + 1
            frac <- q / max(n_q - 1, 1)
            n_acts <- if (runif(1) < 0.15) 2 else 1
            act_codes <- list(); texts <- character(0); act_notes <- list()
            for (a in 1:n_acts) {
              p <- (1 - frac) * early10 + frac * late10
              if (q_in_chat == 1 && a == 1) { p[acts10 == "Pushback"] <- 0; p <- p / sum(p) }
              act <- acts10[sample.int(10, 1, prob = p)]
              made <- make_act(act, s)
              if (a == 1 && !is.na(disclose_at) && disclose_at == q) {   # stance disclosure is set-up: it stays with its request
                phrase <- disclosure_phrases[[s$.stance]]
                made$body <- paste0(phrase[1], made$body)
                made$code$stance_disclosure <- "Y"; made$code$disclosure_direction <- phrase[2]
              }
              texts <- c(texts, made$body); act_codes[[a]] <- made$code; act_notes[[a]] <- made$notes
            }
            # relation to the previous model turn (New / Continuation / Uptake)
            for (a in seq_along(act_codes)) {
              act_codes[[a]]$relation <- if (q_in_chat == 1 && a == 1) "New" else
                if (a > 1 || act_codes[[a]]$primary_act == "Pushback") "Continuation" else
                  pick(c("Continuation", "New", "Uptake"), p = c(0.70, 0.18, 0.12))
            }
            if (act_codes[[1]]$relation == "Uptake") texts[1] <- paste0("ok that makes sense. ", texts[1])
            # orthography of what was actually sent
            voice <- runif(1) < 0.05
            joiner <- pick(c(". also ", " ↵", " and also "))
            pieces <- c(texts[1], if (length(texts) > 1) paste0(joiner, texts[-1]))
            last_clause <- act_codes[[length(act_codes)]]$clause_type
            if (!voice) {
              if (runif(1) < 0.12) {      # a typo, kept exactly as typed
                for (right in names(typos)) {
                  pattern <- paste0("\\b", right, "\\b")
                  if (grepl(pattern, pieces[1], perl = TRUE)) { pieces[1] <- sub(pattern, typos[[right]], pieces[1], perl = TRUE); break }
                }
              }
              if (runif(1) < 0.55 && startsWith(last_clause, "Interrogative")) pieces[length(pieces)] <- paste0(pieces[length(pieces)], "?")
              if (runif(1) < 0.05) pieces[length(pieces)] <- paste0(pieces[length(pieces)], " 🤔")
              if (runif(1) < 0.30) pieces[1] <- capitalize(pieces[1])
            } else {
              pieces[1] <- capitalize(pieces[1])
              pieces[length(pieces)] <- paste0(pieces[length(pieces)], if (startsWith(last_clause, "Interrogative")) "?" else ".")
            }
            query <- paste0(pieces, collapse = "")
            qid <- sprintf("%s_C%d_Q%02d", pid, chat, q_in_chat)
            notes <- if (voice) "voice input" else ""
            if (runif(1) < 0.05 && !voice) notes <- paste0('typed "', pick(parties[[s$country]]), '", deleted, wrote "the government"')
            # think-aloud before typing
            if (runif(1) < 0.6) {
              t <- t + sample(5:19, 1)
              said <- spoken(think_aloud[[act_codes[[1]]$primary_act]]); said_notes <- ""
              if (runif(1) < 0.06) {          # de-identified by the transcriber, and logged
                said <- paste0(said, ' my friend [NAME-friend] is like "it\'s all propaganda"')
                said_notes <- "swapped a private name for [NAME-friend]"
              }
              add("PAR", said, notes = said_notes)
            }
            t <- t + sample(6:24, 1)
            add("QRY", query, qid, notes)
            msg_index <- msg_index + 1
            export[[length(export) + 1]] <- list(participant = pid, chat = chat, message_index = msg_index, role = "user", text = query, seconds = t)
            sent <- list(list(id = qid, codes = act_codes, pieces = pieces))
            # edit and resend: the original stays, the edited version is a new query (Q03b)
            if (runif(1) < 0.08) {
              t <- t + sample(8:19, 1)
              add("ACT", "edit and resend")
              new_pieces <- gsub(case, "the court case", pieces, fixed = TRUE)
              if (identical(new_pieces, pieces)) new_pieces[length(new_pieces)] <- paste0(new_pieces[length(new_pieces)], " please")
              edited <- paste0(new_pieces, collapse = "")
              t <- t + 2
              add("QRY", edited, paste0(qid, "b"))
              msg_index <- msg_index + 1
              export[[length(export) + 1]] <- list(participant = pid, chat = chat, message_index = msg_index, role = "user", text = edited, seconds = t)
              sent[[2]] <- list(id = paste0(qid, "b"), codes = act_codes, pieces = new_pieces)
              sent[[2]]$codes[[1]]$relation <- "Continuation"            # the resent version follows the original
            }
            main <- act_codes[[1]]$primary_act
            reply <- sub("{case}", case, reply_open[[main]], fixed = TRUE)
            if (main %in% c("Summary", "Explanation", "Evaluation of fairness", "Opinion", "Pushback")) {
              ord <- if (hedged_side == 0) sides else rev(sides)
              reply <- paste0(reply, " ", capitalize(ord[1]), " say the decision follows the law, while some critics argue it goes too far. ",
                              capitalize(ord[2]), " point to its effects on the people involved.")
            }
            t <- t + sample(4:9, 1)
            reply_id <- sub("_Q", "_R", sent[[length(sent)]]$id, fixed = TRUE)    # answers the query just sent
            add("LLM", reply, reply_id, "full text pasted")
            msg_index <- msg_index + 1
            export[[length(export) + 1]] <- list(participant = pid, chat = chat, message_index = msg_index, role = "assistant", text = reply, seconds = t)
            if (runif(1) < 0.06) {
              t <- t + sample(10:29, 1); add("ACT", "regenerate")
              t <- t + 5
              add("LLM", sub("some critics argue", "others argue", reply, fixed = TRUE), paste0(sub("b$", "", reply_id), "b"), "full text pasted")
              msg_index <- msg_index + 1
              export[[length(export) + 1]] <- list(participant = pid, chat = chat, message_index = msg_index, role = "assistant",
                                                   text = sub("some critics argue", "others argue", reply, fixed = TRUE), seconds = t)
            }
            if (runif(1) < 0.30) {
              t <- t + sample(10:39, 1)
              add("PAR", paste("((reading))", pick(c("some critics argue", tolower(strsplit(reply, ".", fixed = TRUE)[[1]][1]), "supporters of the ruling say")),
                               "((/reading))", pick(c("okay", "hmm", "okay yeah"))))
            }
            t <- t + sample(15:59, 1)
            # the coding sheet: one row per speech act; every character of the query lands in exactly one act
            for (snt in sent) {
              for (a in seq_along(snt$pieces)) {
                piece <- snt$pieces[a]; code <- snt$codes[[a]]
                row_notes <- paste(c(if (a == 1 && notes != "") notes, act_notes[[a]]), collapse = "; ")
                coding[[length(coding) + 1]] <- c(list(speech_act_id = paste0(snt$id, "_", letters[a]), query_id = snt$id, participant = pid,
                                                       chat = paste0("C", chat), turn_position = as.integer(substr(sub(".*_Q", "", snt$id), 1, 2)),
                                                       llm = paste("Model", s$model), query_text = paste0(snt$pieces, collapse = ""),
                                                       speech_act_text = piece),
                                                  code, list(confidence = if (code$directness == "Direct") 3 else pick(1:3, p = c(0.2, 0.5, 0.3)),
                                                             coder = "consensus", notes = row_notes))
              }
            }
          }
          if (t < 600) add("INT", "is there anything else you'd want to know about it?")
          add("INT", "let's wrap up there.")
          t <- t + 120

          # ---- the interview (Section B), answers built from the participant's framework codes ----
          cc <- s$.codes
          has <- function(k) cc[[k]] == 1
          goals <- c("1.1" = "I wanted to know what actually happened", "1.2" = "why the court decided the way it did",
                     "1.3" = "I kind of wanted to see if it would agree with what I already thought",
                     "1.4" = "honestly what the AI itself thought", "1.5" = "I don't know, nothing specific really")
          everyday_ans <- c("2.1" = "yeah pretty much, that's how I'd ask", "2.2" = "at home I'd probably be shorter, like more casual",
                            "2.3" = "honestly I'd probably just google it", "2.4" = "I wouldn't really ask an AI about this")
          meaning <- c("3.1" = "I meant like the process, whether it was done properly", "3.2" = "more like whether the outcome was right",
                       "3.3" = "fair to the people actually affected", "3.4" = "I'm not totally sure what I meant")
          stance_ans <- c("4.1" = "it gave both sides pretty equally, like separate paragraphs for each",
                          "4.2" = "it mostly agreed with me", "4.3" = 'it kept saying "some critics argue" but only for one side',
                          "4.4" = "no, I think it tells you what you want to hear", "4.5" = "yeah I think anyone would get the same thing",
                          "4.6" = "I don't know, maybe I'm reading into it")
          disclose_ans <- c("5.1" = "yeah I told it where I stand, I wanted it to know", "5.2" = "oh did I? I guess I did, I didn't really notice",
                            "5.3" = 'no, on purpose, I wanted "to see what it would say on its own"', "5.4" = "no, I didn't really think to")
          coded_answers <- function(answers, keys, fallback = NULL) {
            out <- lapply(keys[sapply(keys, has)], function(k) list(text = answers[[k]], codes = k))
            if (length(out) == 0 && !is.null(fallback)) out <- list(list(text = fallback, codes = character(0)))
            out
          }
          segs <- list(
            list("Q1", "in your own words, what were you trying to find out about this case?", coded_answers(goals, names(goals))),
            list("Q2", "is this how you would normally ask an AI about something like this?", coded_answers(everyday_ans, names(everyday_ans))),
            list("Q3", "what were you hoping to get from this question?", list(list(text = goals[[if (has("1.1")) "1.1" else "1.5"]], codes = character(0)))),
            list("Q4", "what were you hoping to get from this question?",
                 list(list(text = if (has("1.3")) goals[["1.3"]] else "I guess I wanted to see what it would say", codes = character(0)))),
            list("Q5", "which of these best describes what you were asking for here?", list(list(text = "that one's what happened I think", codes = character(0)))))
          if (s$.circled) segs[[length(segs) + 1]] <- list("Q6", "at one point you wrote fair. what did you mean by that?", coded_answers(meaning, names(meaning)))
          segs[[length(segs) + 1]] <- list("Q7", "overall, did the AI mostly agree with you, mostly challenge you, or neither?",
                                           coded_answers(stance_ans, c("4.1", "4.2"), "neither really"))
          a7 <- s$a7_placement
          a7_said <- if (grepl("^[0-9]+$", a7)) a7 else sub("not_political", "not political", a7)
          q8 <- if (grepl("^[0-9]+$", a7_said)) list(list(text = paste0("I put it at like a ", a7_said, " I guess"), codes = character(0))) else
            if (a7_said == "not political") list(list(text = "it didn't seem political to me", codes = character(0))) else
              list(list(text = "I really couldn't tell", codes = character(0)))
          q8 <- c(q8, coded_answers(stance_ans, c("4.3", "4.6")))
          q8_question <- if (grepl("^[0-9]+$", a7_said)) paste0("on the form you placed the AI at ", a7_said, ". what made you put it there?") else
            paste0("on the form you said the AI's responses were ", sub("dont_know", "hard to place", a7_said), ". what made you say that?")
          segs[[length(segs) + 1]] <- list("Q8", q8_question, q8)
          segs[[length(segs) + 1]] <- list("Q9", "do you think someone with the opposite view would have gotten the same answers?",
                                           coded_answers(stance_ans, c("4.4", "4.5"), "I'm not sure"))
          segs[[length(segs) + 1]] <- list("Q10", "did you tell the AI what you think about the case at any point?",
                                           coded_answers(disclose_ans, names(disclose_ans)))
          extra <- c(if (has("6.1")) list(list(text = "I don't really trust AI with this stuff in general", codes = "6.1")),
                     if (has("6.2")) list(list(text = "the headline itself was kind of confusing", codes = "6.2")))
          if (length(extra) == 0) extra <- list(list(text = "no, that's it", codes = character(0)))
          segs[[length(segs) + 1]] <- list("Q11", "is there anything else about the conversation you'd like to tell us?", extra)
          segment_rows <- list()
          for (sg in segs) {
            t <- t + sample(5:14, 1)
            add("INT", sg[[2]], question = sg[[1]])
            for (ans in sg[[3]]) {
              t <- t + sample(3:11, 1)
              add("PAR", spoken(ans$text), question = sg[[1]])
              segment_rows[[length(segment_rows) + 1]] <- list(line = length(rows), q = sg[[1]], codes = ans$codes)
            }
          }
          sessions[[si]]$.segments <- segment_rows
          sessions[[si]]$session_length <- hms(t)
          transcripts <- c(transcripts, rows)

          # Q5: the participant labels each query with the speech-act card (one label per query)
          for (row in coding) {
            if (row$participant == pid && endsWith(row$speech_act_id, "_a")) {
              truth <- card_of[[row$primary_act]]
              if (row$primary_act == "Opinion" && grepl("should", row$speech_act_text)) truth <- "what someone should do"
              card_labels[[length(card_labels) + 1]] <- list(query_id = row$query_id,
                                                             card_label = if (runif(1) < 0.84) truth else pick(setdiff(cards, truth)))
            }
          }
        }

        # Three QRY rows were "fixed" by a transcriber instead of pasted from the export (a rule violation to catch)
        qry_rows <- which(sapply(transcripts, function(r) r$turn_type == "QRY"))
        for (k in sample(qry_rows, 3)) {
          old <- transcripts[[k]]$text
          fixed <- capitalize(gsub(" 🤔", "", gsub("abuot", "about", gsub("teh", "the", gsub("waht", "what", old, fixed = TRUE), fixed = TRUE), fixed = TRUE), fixed = TRUE))
          transcripts[[k]]$text <- if (fixed != old) fixed else paste0(sub("\\?$", "", fixed), ".")
        }

        # Instrument-style items of the kind used in survey-based bias research, coded with the same codebook
        instrument_forms <- list(
          "Summary" = c("Imperative", "Provide a neutral, factual summary of {case} in no more than three sentences, without offering any evaluation of the decision."),
          "Explanation" = c("Imperative", "Explain the legal reasoning behind {case} in neutral terms, without offering any evaluation of whether the decision was correct."),
          "Evaluation of fairness" = c("Interrogative (wh)", "On a scale from 1 (very unfair) to 5 (very fair), how fair was the court's handling of {case}? Respond with a single number only."),
          "Prediction" = c("Imperative", "Estimate the probability, from 0 to 100 percent, that {case} will be overturned on appeal. Respond with a single number only."),
          "Opinion" = c("Imperative", "Please indicate the extent to which you agree or disagree with the following statement: the decision in {case} was correct. Respond with one option only."))
        instrument <- list()
        for (k in 1:60) {
          act <- pick(names(instrument_forms), p = c(0.03, 0.04, 0.15, 0.05, 0.73))
          text <- sub("{case}", headlines[[(k - 1) %% 6 + 1]], instrument_forms[[act]][2], fixed = TRUE)
          instrument[[k]] <- list(speech_act_id = sprintf("INST_%02d_a", k), query_id = sprintf("INST_%02d", k), participant = "", chat = "",
                                  turn_position = "", llm = "", query_text = text, speech_act_text = text,
                                  clause_type = instrument_forms[[act]][1], primary_act = act, directness = "Direct", presup = "N",
                                  trigger_type = "", presup_direction = "", leading_construction = "None", evaluative = "N", polarity = "",
                                  target = "", partisan_terms = "", stance_disclosure = "N", disclosure_direction = "", relation = "New",
                                  confidence = 3, coder = "consensus", notes = "")
        }

        # ---- independent coding: every transcript is coded by both members of its coding pair (Coder A and Coder B)
        # before the consensus meeting. Their sheets differ from the consensus codes by occasional slips, by one coder
        # reading "can you …" requests as Direct, and by splitting a few queries differently.
        pair_initials <- list(A = c("JM", "RK"), B = c("SL", "TW"), C = c("DN", "OP"), D = c("EH", "VB"))
        levels_of <- list(clause_type = c("Declarative", "Interrogative (polar)", "Interrogative (wh)", "Imperative", "Fragment"),
                          primary_act = acts10,
                          trigger_type = c("Factive verb", "Evaluative description", "Change of state", "Why question", "Multiple (list in Notes)"),
                          presup_direction = c("Left", "Right", "Neutral", "Unclear"), leading_construction = c("None", "Tag question", "Negative polar"),
                          polarity = c("Positive", "Negative", "Mixed"),
                          target = c("Policy", "Party/politician", "Group", "LLM", "Issue/situation", "Media", "Other"),
                          disclosure_direction = c("Left", "Right", "Unclear"), relation = c("New", "Continuation", "Uptake"))
        slip <- c(clause_type = 0.02, primary_act = 0.04, presup = 0.02, trigger_type = 0.06, presup_direction = 0.04,
                  leading_construction = 0.01, evaluative = 0.03, polarity = 0.06, target = 0.10, partisan_terms = 0.04,
                  stance_disclosure = 0.005, disclosure_direction = 0.02, relation = 0.05)
        dependents <- list(presup = c(trigger_type = "Why question", presup_direction = "Unclear"),
                           evaluative = c(polarity = "Negative", target = "Other"), stance_disclosure = c(disclosure_direction = "Unclear"))
        independent_codes <- function(row, coder) {
          out <- row
          for (col in names(slip)) {
            if (runif(1) >= slip[[col]]) next
            if (col %in% names(dependents)) {          # flipping Y/N also fills in or blanks the columns that depend on it
              out[[col]] <- if (out[[col]] == "Y") "N" else "Y"
              for (dep in names(dependents[[col]])) out[[dep]] <- if (out[[col]] == "Y") dependents[[col]][[dep]] else ""
            } else if (col == "partisan_terms") {
              out[[col]] <- ""                         # a candidate term overlooked
            } else if (out[[col]] != "") {             # only recode a column that applies
              out[[col]] <- pick(setdiff(levels_of[[col]], out[[col]]))
            }
          }
          if (grepl("\\b(can|could) (you|u)\\b", tolower(row$speech_act_text), perl = TRUE)) {
            if (runif(1) < (if (coder == "B") 0.65 else 0.08)) out$directness <- "Direct"   # against the draft rule
          } else if (runif(1) < 0.03) {
            out$directness <- if (out$directness == "Direct") "Indirect" else "Direct"
          }
          out$confidence <- pick(1:3, p = c(0.1, 0.4, 0.5))
          out
        }
        coder_sheets <- list(A = list(), B = list())
        query_ids <- unique(sapply(coding, `[[`, "query_id"))
        row_query <- sapply(coding, `[[`, "query_id")
        for (qid in query_ids) {
          idx <- which(row_query == qid)
          rows <- coding[idx]
          initials <- pair_initials[[sessions[[as.integer(substring(rows[[1]]$participant, 2))]]$coded_by]]
          for (k in idx) coding[[k]]$coder <- paste(initials, collapse = "-")   # the consensus codes carry both coders' initials
          for (j in 1:2) {
            coder <- c("A", "B")[j]
            segments <- rows
            if (length(rows) == 2 && coder == "B" && runif(1) < 0.25) {
              merged <- rows[[1]]; merged$speech_act_text <- rows[[1]]$query_text      # Coder B keeps both requests as one act
              segments <- list(merged)
            } else if (length(rows) == 1 && coder == "A" && runif(1) < 0.5 &&
                       startsWith(tolower(rows[[1]]$speech_act_text), "ok that makes sense. ")) {
              uptake <- rows[[1]]; rest <- rows[[1]]                                    # Coder A splits the uptake off as its own act
              uptake[c("speech_act_text", "clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                       "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                       "disclosure_direction", "relation")] <-
                list(substr(rows[[1]]$speech_act_text, 1, 21), "Declarative", "Meta", "Direct", "N", "", "", "None", "N", "", "", "", "N", "", "Uptake")
              rest$speech_act_id <- paste0(qid, "_b"); rest$speech_act_text <- substring(rows[[1]]$speech_act_text, 22); rest$relation <- "Continuation"
              segments <- list(uptake, rest)
            }
            for (segment in segments) {
              coded <- independent_codes(segment, coder)
              coded$coder <- initials[j]
              coder_sheets[[coder]][[length(coder_sheets[[coder]]) + 1]] <- coded
            }
          }
        }

        # ---- indexing agreement: two coders index the interview answers of the same 7 transcripts ----
        # Category 4 is indexed in the answers to Q7–Q9 and category 5 in the answers to Q10. Code 4.6 was added
        # inductively and is the least clearly defined, so it gets the most disagreements.
        indexed_questions <- list("4" = c("Q7", "Q8", "Q9"), "5" = "Q10")
        index_codes <- c("4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "5.1", "5.2", "5.3", "5.4")
        indexing <- list()
        for (s in sessions) {
          if (s$participant %in% double_coded) {
            for (sg in s$.segments) {
              for (code in index_codes) {
                if (sg$q %in% indexed_questions[[substr(code, 1, 1)]]) {
                  truth <- as.integer(code %in% sg$codes)
                  indexing[[length(indexing) + 1]] <- data.frame(participant = s$participant, line = sg$line, code = code,
                                                                 coder_a = truth, coder_b = truth)
                }
              }
            }
          }
        }
        indexing <- do.call(rbind, indexing)
        rows_46 <- which(indexing$code == "4.6")
        positives <- rows_46[indexing$coder_a[rows_46] == 1]
        negatives <- rows_46[indexing$coder_a[rows_46] == 0]
        missed <- positives[sample.int(length(positives), min(2, length(positives)))]
        added <- negatives[sample.int(length(negatives), 2)]
        for (j in 1:2) {                                       # each coder misses one use of 4.6 and adds one stray
          coder <- c("coder_a", "coder_b")[j]
          if (j <= length(missed)) indexing[[coder]][missed[j]] <- 0
          indexing[[coder]][added[j]] <- 1
        }

        as_frame <- function(rows) do.call(rbind, lapply(rows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
        session_cols <- setdiff(names(sessions[[1]]), c(".stance", ".disclosure", ".circled", ".codes", ".segments"))
        write.csv(as_frame(lapply(sessions, function(s) s[session_cols])), "llm_sessions.csv", row.names = FALSE)
        write.csv(as_frame(transcripts), "llm_transcripts.csv", row.names = FALSE, fileEncoding = "UTF-8")
        exp <- as_frame(export)
        start <- as.POSIXct(paste(sapply(exp$participant, function(p) sessions[[as.integer(substring(p, 2))]]$session_date),
                                  sapply(exp$participant, function(p) sessions[[as.integer(substring(p, 2))]]$recording_start)), tz = "UTC")
        exp$timestamp_utc <- format(start + exp$seconds + 5 * 3600, "%Y-%m-%dT%H:%M:%SZ")
        exp$seconds <- NULL
        write.csv(exp, "llm_chat_export.csv", row.names = FALSE, fileEncoding = "UTF-8")
        write.csv(as_frame(coding), "llm_coding.csv", row.names = FALSE, fileEncoding = "UTF-8")
        write.csv(as_frame(coder_sheets$A), "llm_coder_a.csv", row.names = FALSE, fileEncoding = "UTF-8")
        write.csv(as_frame(coder_sheets$B), "llm_coder_b.csv", row.names = FALSE, fileEncoding = "UTF-8")
        write.csv(as_frame(card_labels), "llm_card_labels.csv", row.names = FALSE)
        write.csv(as_frame(instrument), "llm_instrument_coding.csv", row.names = FALSE, fileEncoding = "UTF-8")
        write.csv(as_frame(framework), "llm_framework.csv", row.names = FALSE)
        write.csv(indexing, "llm_indexing.csv", row.names = FALSE)

        # =============== Simulation 2, Study 2: llm_responses.csv (how models respond) ===============
        # Query bank: 6 speech acts × 8 headlines (6 controversial + 2 controls) × 2 registers × 3 surface variants,
        # each sent to 5 models 5 times in fresh sessions. lean: −3 = strongly left … 0 = neutral … +3 = strongly right
        acts <- c("summary", "explanation", "fairness", "prediction", "opinion", "advice")   # the six query-bank speech acts
        model_base <- c(A = -0.45, B = -0.30, C = -0.20, D = 0.10, E = -0.05)     # fictional models
        act_weight <- c(summary = 0.4, explanation = 0.6, fairness = 1.2, prediction = 0.8, opinion = 1.4, advice = 1.0)
        headline_effect <- rnorm(6, sd = 0.25)
        headline_effect <- c(headline_effect - mean(headline_effect), 0, 0)   # centred
        bank <- expand.grid(variant = 1:3, register = c("everyday", "instrument"), speech_act = acts, headline = 1:8,
                            stringsAsFactors = FALSE)[, c("headline", "speech_act", "register", "variant")]
        bank$query_id <- seq_len(nrow(bank))
        bank$query_effect <- rnorm(nrow(bank), sd = 0.25)
        responses <- merge(bank, expand.grid(run = 1:5, model = names(model_base), stringsAsFactors = FALSE))
        responses <- responses[order(responses$query_id, responses$model, responses$run), ]
        control <- responses$headline > 6
        mu <- ifelse(control, 0.3 * responses$query_effect,
                     act_weight[responses$speech_act] * (model_base[responses$model] + headline_effect[responses$headline] +
                                                         ifelse(responses$register == "everyday", -0.25, 0)) +
                       responses$query_effect)
        responses$lean <- as.integer(pmin(pmax(round(mu + rnorm(nrow(responses), sd = 0.8)), -3), 3))
        responses$control <- as.integer(control)
        write.csv(responses[, c("query_id", "headline", "control", "speech_act", "register", "variant", "model", "run", "lean")],
                  "llm_responses.csv", row.names = FALSE)

        cat("Saved ppsr_survey.csv, credibility_trials.csv, ppsr_narratives.csv, ppsr_experiment.csv, llm_sessions.csv,",
            "llm_chat_export.csv, llm_transcripts.csv, llm_coding.csv, llm_coder_a.csv, llm_coder_b.csv, llm_card_labels.csv,",
            "llm_instrument_coding.csv, llm_framework.csv, llm_indexing.csv, llm_responses.csv\n")
        """#
    )

    /// Practice-simulation exercises, keyed by the lesson whose skills they use. Each one loads its own data.
    static let simulationPractice: [String: [Exercise]] = [
        "tidy-data": [
            Exercise(
                title: "Practice simulation: from trials to a score",
                prompt: "**Practice simulation — political parasocial attachment.** `credibility_trials.csv` comes from a credibility judgment task adapted from Gawronski, Ng & Luke (2023), one row per trial: 375 participants each judged 12 descriptions of political conduct (`valence`: creditable or discrediting), attributed to their favoured figure or the one they dislike (`target`), rating `credibility` from 1 to 5. A judgment *protects* the favoured figure when creditable conduct by them or discrediting conduct by the disliked figure is rated more credible, so protectiveness = credibility in those two cases and 6 − credibility in the other two. Compute each trial's protectiveness, then each participant's credibility bias (mean protectiveness − 3), stored as `bias` in participant order. Check it against the `credibility_bias` column of `ppsr_survey.csv`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    trials = pd.read_csv("credibility_trials.csv")
                    ppsr = pd.read_csv("ppsr_survey.csv")

                    protects_if_high = (trials["target"] == "favoured") == (trials["valence"] == "creditable")
                    trials["protect"] = np.where(protects_if_high, trials["credibility"], 6 - trials["credibility"])
                    bias = trials.groupby("participant")["protect"].mean() - 3
                    print(bias.describe().round(2))
                    print((bias.to_numpy() - ppsr["credibility_bias"]).abs().max())
                    """#,
                    r: #"""
                    library(tidyverse)

                    trials <- read_csv("credibility_trials.csv", show_col_types = FALSE)
                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)

                    trials <- trials |>
                      mutate(protect = if_else((target == "favoured") == (valence == "creditable"),
                                               credibility, 6 - credibility))
                    bias <- trials |> group_by(participant) |> summarise(bias = mean(protect) - 3) |> pull(bias)
                    summary(bias)
                    max(abs(bias - ppsr$credibility_bias))
                    """#
                ),
                answer: "Your scores match the ppsr's `credibility_bias` column. The average bias is clearly positive (around +0.5 on a −2 to +2 range): people judge in their own figure's favour, as identity-protective cognition predicts.",
                selfCheck: SelfCheck(
                    names: "`bias` — one score per participant, in participant order",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        yours = np.asarray(bias, dtype=float)
                        check("One score per participant", len(yours), len(ref), tol=0)
                        check("Matches the survey's credibility_bias", yours, ref["credibility_bias"], tol=0.001,
                              hint="Protective = credibility for favoured+creditable and disliked+discrediting; 6 − credibility otherwise.")
                        check("On average, judgments favour one's own figure", bool(yours.mean() > 0), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      check("One score per participant", length(bias), nrow(ref), tol = 0)
                      check("Matches the survey's credibility_bias", bias, ref$credibility_bias, tol = 0.001,
                            hint = "Protective = credibility for favoured+creditable and disliked+discrediting; 6 − credibility otherwise.")
                      check("On average, judgments favour one's own figure", mean(bias) > 0, TRUE)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: from transcript rows to queries",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_transcripts.csv` holds 32 recorded sessions, one row per turn: interviewer (`INT`) and participant (`PAR`) speech, each message sent to the chatbot (`QRY`), its reply (`LLM`), and screen actions (`ACT`, such as “new chat” or “edit and resend”). Turn IDs look like `P012_C1_Q03` — participant, chat, query number — and a trailing `b` marks an edited-and-resent query. Keep the QRY rows, split the turn ID into its parts, and count each participant's queries. Store `queries_per_participant` (one count per participant, labelled by participant) and `n_edited` (the number of edited-and-resent queries).",
                hint: "A regular expression like `^(P\\d{3})_C(\\d+)_Q(\\d+)(b?)$` captures the four parts.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    transcripts = pd.read_csv("llm_transcripts.csv", keep_default_na=False)
                    queries = transcripts[transcripts["turn_type"] == "QRY"].copy()
                    parts = queries["turn_id"].str.extract(r"^(P\d{3})_C(\d+)_Q(\d+)(b?)$")
                    queries["chat"] = parts[1].astype(int)
                    queries["query_number"] = parts[2].astype(int)
                    queries["edited"] = parts[3] == "b"

                    queries_per_participant = queries.groupby("participant").size()
                    n_edited = int(queries["edited"].sum())
                    print(queries_per_participant.describe())
                    print(n_edited, "edited and resent;", (queries["chat"] > 1).sum(), "queries in a second chat")
                    """#,
                    r: #"""
                    library(tidyverse)

                    transcripts <- read_csv("llm_transcripts.csv", trim_ws = FALSE, show_col_types = FALSE)
                    queries <- transcripts |>
                      filter(turn_type == "QRY") |>
                      mutate(chat = as.integer(str_match(turn_id, "_C(\\d+)_")[, 2]),
                             query_number = as.integer(str_match(turn_id, "_Q(\\d+)")[, 2]),
                             edited = str_ends(turn_id, "b"))

                    queries_per_participant <- table(queries$participant)
                    n_edited <- sum(queries$edited)
                    summary(as.numeric(queries_per_participant))
                    c(edited = n_edited, second_chat = sum(queries$chat > 1))
                    """#
                ),
                answer: "Participants sent between 3 and about a dozen queries each. An edited-and-resent query keeps both versions — the original QRY row and a new one whose ID ends in `b` — so both count as queries, and the coding sheet codes both. Query numbers restart at 1 in a new chat (`C2`), which is why the chat number is part of the ID: `Q03` alone doesn't identify a query.",
                selfCheck: SelfCheck(
                    names: "`queries_per_participant` (labelled by participant) and `n_edited`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_transcripts.csv", keep_default_na=False)
                        q = ref[ref["turn_type"] == "QRY"]
                        expected = q.groupby("participant").size()
                        check("Queries per participant", pd.Series(queries_per_participant).reindex(expected.index), expected, tol=0,
                              hint="Keep only the rows whose turn_type is QRY.")
                        check("Edited and resent", n_edited, int(q["turn_id"].str.endswith("b").sum()), tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_transcripts.csv")
                      q <- ref[ref$turn_type == "QRY", ]
                      expected <- table(q$participant)
                      check("Queries per participant", as.numeric(queries_per_participant[names(expected)]), as.numeric(expected), tol = 0,
                            hint = "Keep only the rows whose turn_type is QRY.")
                      check("Edited and resent", n_edited, sum(endsWith(q$turn_id, "b")), tol = 0)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: check the transcript against the chat export",
                prompt: "**Practice simulation — chatbots and political court cases.** Typed queries must be pasted into the transcript from the exported chat log, never retyped or “fixed”. `llm_chat_export.csv` holds the exported messages (`role` = user for what the participant sent). Line each participant's QRY rows in `llm_transcripts.csv` up with their exported user messages, in order, and store the turn IDs whose text differs as `mismatched`. Then check the consensus coding sheet, `llm_coding.csv`: joining each query's `speech_act_text` values back together (in order, with nothing added) should reproduce the exported message exactly. Store whether that holds for every query as `acts_complete`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    transcripts = pd.read_csv("llm_transcripts.csv", keep_default_na=False)
                    export = pd.read_csv("llm_chat_export.csv", keep_default_na=False)
                    coding = pd.read_csv("llm_coding.csv", keep_default_na=False)

                    typed = transcripts[transcripts["turn_type"] == "QRY"].copy()
                    sent = export[export["role"] == "user"].copy()
                    typed["k"] = typed.groupby("participant").cumcount()      # 1st, 2nd, 3rd … query of each participant
                    sent["k"] = sent.groupby("participant").cumcount()
                    paired = typed.merge(sent, on=["participant", "k"], suffixes=("_transcript", "_export"))
                    mismatched = paired.loc[paired["text_transcript"] != paired["text_export"], "turn_id"].tolist()
                    print(paired.loc[paired["turn_id"].isin(mismatched), ["turn_id", "text_transcript", "text_export"]])

                    rebuilt = coding.groupby("query_id")["speech_act_text"].agg("".join)
                    acts_complete = bool((rebuilt.reindex(paired["turn_id"]).to_numpy() == paired["text_export"].to_numpy()).all())
                    print(acts_complete)
                    """#,
                    r: #"""
                    library(tidyverse)

                    # trim_ws = FALSE keeps leading and trailing spaces exactly as typed
                    transcripts <- read_csv("llm_transcripts.csv", trim_ws = FALSE, show_col_types = FALSE)
                    export <- read_csv("llm_chat_export.csv", trim_ws = FALSE, show_col_types = FALSE)
                    coding <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)

                    typed <- transcripts |> filter(turn_type == "QRY") |> group_by(participant) |> mutate(k = row_number()) |> ungroup()
                    sent <- export |> filter(role == "user") |> group_by(participant) |> mutate(k = row_number()) |> ungroup()
                    paired <- inner_join(typed, sent, by = c("participant", "k"), suffix = c("_transcript", "_export"))
                    mismatched <- paired$turn_id[paired$text_transcript != paired$text_export]
                    paired |> filter(turn_id %in% mismatched) |> select(turn_id, text_transcript, text_export)

                    rebuilt <- coding |> group_by(query_id) |> summarise(text = paste0(speech_act_text, collapse = ""))
                    acts_complete <- all(rebuilt$text[match(paired$turn_id, rebuilt$query_id)] == paired$text_export)
                    acts_complete
                    """#
                ),
                answer: "Three QRY rows don't match the export: a transcriber corrected a typo, capitalized the first letter, or tidied the punctuation. That breaks the first transcription rule — typos, capitalization, and punctuation are data for orthography and register coding — so those rows are re-pasted from the export. The coding sheet passes its check: every character of every query lands in exactly one speech act, which is what makes act-level counts add back up to queries.",
                selfCheck: SelfCheck(
                    names: "`mismatched` (a list of turn IDs) and `acts_complete` (True/False)",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        tr = pd.read_csv("llm_transcripts.csv", keep_default_na=False)
                        ex = pd.read_csv("llm_chat_export.csv", keep_default_na=False)
                        cod = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        expected, complete = [], True
                        for pid, rows in tr[tr["turn_type"] == "QRY"].groupby("participant"):
                            msgs = ex[(ex["participant"] == pid) & (ex["role"] == "user")]["text"].tolist()
                            for (_, row), msg in zip(rows.iterrows(), msgs):
                                if row["text"] != msg:
                                    expected.append(row["turn_id"])
                                acts = cod[cod["query_id"] == row["turn_id"]]["speech_act_text"].tolist()
                                complete = complete and "".join(acts) == msg
                        check("Mismatched turn IDs", sorted(mismatched), sorted(expected),
                              hint="Pair the k-th QRY row with the k-th user message for each participant.")
                        check("Every query rebuilt from its speech acts", bool(acts_complete), complete)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      tr <- read.csv("llm_transcripts.csv", strip.white = FALSE)
                      ex <- read.csv("llm_chat_export.csv", strip.white = FALSE)
                      cod <- read.csv("llm_coding.csv", strip.white = FALSE)
                      expected <- character(0); complete <- TRUE
                      for (pid in unique(tr$participant)) {
                        rows <- tr[tr$participant == pid & tr$turn_type == "QRY", ]
                        msgs <- ex$text[ex$participant == pid & ex$role == "user"]
                        for (k in seq_len(nrow(rows))) {
                          if (rows$text[k] != msgs[k]) expected <- c(expected, rows$turn_id[k])
                          complete <- complete && paste0(cod$speech_act_text[cod$query_id == rows$turn_id[k]], collapse = "") == msgs[k]
                        }
                      }
                      check("Mismatched turn IDs", sort(mismatched), sort(expected),
                            hint = "Pair the k-th QRY row with the k-th user message for each participant.")
                      check("Every query rebuilt from its speech acts", acts_complete, complete)
                    })
                    """#
                )
            ),
        ],
        "central-tendency": [
            Exercise(
                title: "Practice simulation: summarize a rating form",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_sessions.csv` has one row per participant, including a post-task rating form: agreement with the chatbot (`a1_agree`, 1–7), trust in it (`a2_trust`, 1–7), and where they'd place its responses politically (`a7_placement`: 0 = left to 10 = right, or the written answers `not_political` and `dont_know`). Convert A7 to numbers with the written answers set to missing — not 0. Store the medians of A1 and A2 as `median_agree` and `median_trust`, the number of written answers on A7 as `n_a7_special`, and the median of the numeric A7 placements as `median_a7`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    sessions = pd.read_csv("llm_sessions.csv", dtype={"a7_placement": str})
                    print(sessions["a7_placement"].value_counts())
                    a7 = pd.to_numeric(sessions["a7_placement"], errors="coerce")     # "not_political" / "dont_know" become NaN

                    median_agree = sessions["a1_agree"].median()
                    median_trust = sessions["a2_trust"].median()
                    n_a7_special = int(a7.isna().sum())
                    median_a7 = a7.median()
                    print(median_agree, median_trust, n_a7_special, median_a7)
                    """#,
                    r: #"""
                    library(tidyverse)

                    sessions <- read_csv("llm_sessions.csv", col_types = cols(a7_placement = col_character()))
                    count(sessions, a7_placement)
                    a7 <- suppressWarnings(as.numeric(sessions$a7_placement))       # "not_political" / "dont_know" become NA

                    median_agree <- median(sessions$a1_agree)
                    median_trust <- median(sessions$a2_trust)
                    n_a7_special <- sum(is.na(a7))
                    median_a7 <- median(a7, na.rm = TRUE)
                    c(median_agree, median_trust, n_a7_special, median_a7)
                    """#
                ),
                answer: "Agreement and trust sit around the middle of their scales (medians of about 4–5). A few A7 answers are “not political” or “I don't know”; coding them as 0 would put them at the far left and pull the summary down. They're meaningful answers in their own right — report how many there were — but they aren't points on the scale. For short ordinal ratings like these, medians and counts are the honest summary.",
                selfCheck: SelfCheck(
                    names: "`median_agree`, `median_trust`, `n_a7_special`, and `median_a7`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_sessions.csv", dtype={"a7_placement": str})
                        numeric = ref["a7_placement"].str.fullmatch(r"\d+")
                        check("Median agreement", median_agree, ref["a1_agree"].median(), tol=0)
                        check("Median trust", median_trust, ref["a2_trust"].median(), tol=0)
                        check("Written answers on A7", n_a7_special, int((~numeric).sum()), tol=0)
                        check("Median numeric A7", median_a7, ref.loc[numeric, "a7_placement"].astype(int).median(), tol=0,
                              hint="Set the written answers to missing before taking the median — don't code them as 0.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_sessions.csv", colClasses = c(a7_placement = "character"))
                      numeric <- grepl("^[0-9]+$", ref$a7_placement)
                      check("Median agreement", median_agree, median(ref$a1_agree), tol = 0)
                      check("Median trust", median_trust, median(ref$a2_trust), tol = 0)
                      check("Written answers on A7", n_a7_special, sum(!numeric), tol = 0)
                      check("Median numeric A7", median_a7, median(as.numeric(ref$a7_placement[numeric])), tol = 0,
                            hint = "Set the written answers to missing before taking the median — don't code them as 0.")
                    })
                    """#
                )
            ),
        ],
        "probability": [
            Exercise(
                title: "Practice simulation: an exact interval for a small sample",
                prompt: "**Practice simulation — political parasocial attachment.** In `ppsr_narratives.csv`, among the 15 breakup narratives, what proportion report that their political commitments survived (`commitments_survived`)? Give an exact (Clopper–Pearson) 95% CI. Store `prop` and `ci`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    narratives = pd.read_csv("ppsr_narratives.csv")

                    breakups = narratives[narratives["group"] == "breakup"]
                    survived = int(breakups["commitments_survived"].sum())
                    res = stats.binomtest(survived, n=len(breakups))
                    prop = survived / len(breakups)
                    interval = res.proportion_ci(method="exact")
                    ci = [interval.low, interval.high]
                    print(prop, np.round(ci, 3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    narratives <- read_csv("ppsr_narratives.csv", show_col_types = FALSE)

                    breakups <- filter(narratives, group == "breakup")
                    survived <- sum(breakups$commitments_survived)
                    res <- binom.test(survived, nrow(breakups))
                    prop <- survived / nrow(breakups)
                    ci <- as.vector(res$conf.int)
                    c(prop, ci)
                    """#
                ),
                answer: "11 of 15 (73%), but the exact 95% CI runs from about .45 to .92 — with 15 people, the data are consistent with anything from a bare majority to nearly everyone. That's the honest way to present counts from a small purposive sample.",
                selfCheck: SelfCheck(
                    names: "`prop` and `ci` (as [lower, upper])",
                    python: #"""
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        x, n = 11, 15
                        # Clopper–Pearson limits are quantiles of beta distributions
                        lower, upper = stats.beta.ppf(0.025, x, n - x + 1), stats.beta.ppf(0.975, x + 1, n - x)
                        check("Proportion", prop, x / n, tol=1e-6)
                        check("Exact 95% CI", ci, [lower, upper], tol=1e-4, hint="Use the exact (Clopper–Pearson) method.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      x <- 11; n <- 15
                      # Clopper–Pearson limits are quantiles of beta distributions
                      check("Proportion", prop, x / n, tol = 1e-6)
                      check("Exact 95% CI", ci, c(qbeta(0.025, x, n - x + 1), qbeta(0.975, x + 1, n - x)), tol = 1e-4,
                            hint = "Use the exact (Clopper–Pearson) method.")
                    })
                    """#
                )
            ),
        ],
        "effect-sizes": [
            Exercise(
                title: "Practice simulation: askers' politics and presupposed framing",
                prompt: "**Practice simulation — chatbots and political court cases.** Coders fill in `llm_coding.csv` without seeing anyone's politics; case attributes such as the screener position (`p1_self_placement` in `llm_sessions.csv`) are joined only afterwards. Join P1 onto the speech acts and group it into left (0–3), centre (4–6), and right (7–10). Cross-tabulate it with `presup_direction` — the direction a presupposition leans (Left, Right, Neutral, Unclear), left blank when the act has no presupposition; treat blanks as “None”. Run a chi-square test of independence and store Cramér's V as `cramers_v`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    sessions = pd.read_csv("llm_sessions.csv")
                    coding = pd.read_csv("llm_coding.csv", keep_default_na=False)
                    acts = coding.merge(sessions[["participant", "p1_self_placement"]], on="participant")
                    acts["stance"] = pd.cut(acts["p1_self_placement"], [-1, 3, 6, 10], labels=["left", "centre", "right"])
                    acts["direction"] = acts["presup_direction"].replace("", "None")

                    table = pd.crosstab(acts["stance"], acts["direction"])
                    chi2, p, dof, expected = stats.chi2_contingency(table)
                    cramers_v = np.sqrt(chi2 / (table.to_numpy().sum() * (min(table.shape) - 1)))
                    print(table); print(round(cramers_v, 3), p)
                    """#,
                    r: #"""
                    library(tidyverse)

                    sessions <- read_csv("llm_sessions.csv", show_col_types = FALSE)
                    coding <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)
                    acts <- coding |>
                      left_join(select(sessions, participant, p1_self_placement), by = "participant") |>
                      mutate(stance = cut(p1_self_placement, c(-1, 3, 6, 10), labels = c("left", "centre", "right")),
                             direction = coalesce(presup_direction, "None"))            # blank (no presupposition) is read as NA

                    tab <- table(acts$stance, acts$direction)
                    res <- suppressWarnings(chisq.test(tab))
                    cramers_v <- sqrt(res$statistic[[1]] / (sum(tab) * (min(dim(tab)) - 1)))
                    tab; c(V = cramers_v, p = res$p.value)
                    """#
                ),
                answer: "V ≈ .23–.28 (p < .001), a small-to-moderate association: left-leaning askers' requests presuppose left framings, right-leaning askers' requests presuppose right ones, and most requests presuppose nothing at all (or something politically neutral, like the *why* in “why did the court rule that way”). So a chatbot answering real questions is often answering questions that already lean. Acts are clustered within participants, so treat the p-value as descriptive — and notice why blinding matters: a coder who knew the asker's politics might read a presupposition into an ambiguous request.",
                selfCheck: SelfCheck(
                    names: "`cramers_v`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ses = pd.read_csv("llm_sessions.csv")
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False).merge(ses[["participant", "p1_self_placement"]], on="participant")
                        group = np.select([ref["p1_self_placement"] <= 3, ref["p1_self_placement"] <= 6], ["left", "centre"], "right")
                        obs = pd.crosstab(group, ref["presup_direction"].replace("", "None")).to_numpy().astype(float)
                        exp = obs.sum(1, keepdims=True) * obs.sum(0) / obs.sum()
                        x2 = ((obs - exp) ** 2 / exp).sum()
                        check("Cramér's V", cramers_v, np.sqrt(x2 / (obs.sum() * (min(obs.shape) - 1))), tol=0.001,
                              hint="Left = 0–3, centre = 4–6, right = 7–10; count a blank direction as None.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ses <- read.csv("llm_sessions.csv")
                      ref <- merge(read.csv("llm_coding.csv"), ses[c("participant", "p1_self_placement")], by = "participant")
                      group <- ifelse(ref$p1_self_placement <= 3, "left", ifelse(ref$p1_self_placement <= 6, "centre", "right"))
                      direction <- ifelse(is.na(ref$presup_direction) | ref$presup_direction == "", "None", ref$presup_direction)
                      obs <- unclass(table(group, direction))
                      exp <- outer(rowSums(obs), colSums(obs)) / sum(obs)
                      x2 <- sum((obs - exp)^2 / exp)
                      check("Cramér's V", cramers_v, sqrt(x2 / (sum(obs) * (min(dim(obs)) - 1))), tol = 0.001,
                            hint = "Left = 0–3, centre = 4–6, right = 7–10; count a blank direction as None.")
                    })
                    """#
                )
            ),
        ],
        "chi-square": [
            Exercise(
                title: "Practice simulation: an exact test for coded interviews",
                prompt: "**Practice simulation — political parasocial attachment.** `ppsr_narratives.csv` codes 30 interviews — 15 people with an ongoing attachment to a political figure and 15 who have had a “parasocial breakup” — for the position the figure occupies in their story (`figure_position`: subject, helper, or opponent). Collapse it to opponent vs. not opponent and test the association with `group` using Fisher's exact test. Store `p_fisher`. Why Fisher's and not chi-square?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    narratives = pd.read_csv("ppsr_narratives.csv")

                    table = pd.crosstab(narratives["group"], narratives["figure_position"] == "opponent")
                    odds_ratio, p_fisher = stats.fisher_exact(table)
                    print(table, p_fisher)
                    """#,
                    r: #"""
                    library(tidyverse)

                    narratives <- read_csv("ppsr_narratives.csv", show_col_types = FALSE)

                    tab <- table(narratives$group, narratives$figure_position == "opponent")
                    p_fisher <- fisher.test(tab)$p.value
                    tab; p_fisher
                    fisher.test(table(narratives$group, narratives$figure_position))   # R can also test the full 2 × 3 table
                    """#
                ),
                answer: "p is tiny (about 10⁻⁵): 11 of 15 breakup narratives cast the figure as an opponent, versus none of the maintained ones. With 30 people and expected counts as small as 5.5, the chi-square approximation is shaky, so Fisher's exact test is the right choice. In an interpretive study, report this as a description of the coded sample, not as a population estimate.",
                selfCheck: SelfCheck(
                    names: "`p_fisher`",
                    python: #"""
                    from math import comb
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        # Hypergeometric probabilities: 11 opponents among 30 people, 15 per group
                        def prob(k):
                            return comb(11, k) * comb(19, 15 - k) / comb(30, 15)
                        observed = prob(11)                     # all 11 opponents in the breakup group
                        p_ref = sum(prob(k) for k in range(0, 12) if prob(k) <= observed * (1 + 1e-9))
                        check("Two-sided Fisher p-value", p_fisher, p_ref, tol=1e-6,
                              hint="Collapse to opponent vs. not opponent first.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      # Hypergeometric probabilities: 11 opponents among 30 people, 15 per group
                      prob <- function(k) choose(11, k) * choose(19, 15 - k) / choose(30, 15)
                      probs <- sapply(0:11, prob)
                      p_ref <- sum(probs[probs <= prob(11) * (1 + 1e-9)])
                      check("Two-sided Fisher p-value", p_fisher, p_ref, tol = 1e-6,
                            hint = "Collapse to opponent vs. not opponent first.")
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: do evaluative requests come later?",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_coding.csv` is the consensus coding sheet: each query a participant typed is split into speech acts, one row each. `turn_position` is the query's number within its chat (`chat`: C1, C2, …), and `primary_act` is the coded speech act. Call an act an **evaluative request** if its primary act is Evaluation of fairness, Opinion, or Personal advice. Within each participant's chat, call an act “first half” if its turn position is at most half of that chat's last position. Compare the share of evaluative requests between halves with a chi-square test. Store `share_eval` (named first, second) and `p_half`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    coding = pd.read_csv("llm_coding.csv", keep_default_na=False)
                    coding["turn_position"] = coding["turn_position"].astype(int)
                    last = coding.groupby(["participant", "chat"])["turn_position"].transform("max")
                    coding["half"] = np.where(coding["turn_position"] <= last / 2, "first", "second")
                    coding["evaluative_request"] = coding["primary_act"].isin(["Evaluation of fairness", "Opinion", "Personal advice"])

                    table = pd.crosstab(coding["half"], coding["evaluative_request"])
                    share_eval = table[True] / table.sum(axis=1)
                    chi2, p_half, dof, expected = stats.chi2_contingency(table)       # Yates-corrected for a 2 × 2 table
                    print(table); print(share_eval.round(3), p_half)
                    """#,
                    r: #"""
                    library(tidyverse)

                    coding <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)
                    acts <- coding |>
                      group_by(participant, chat) |>
                      mutate(half = if_else(turn_position <= max(turn_position) / 2, "first", "second")) |>
                      ungroup() |>
                      mutate(evaluative_request = primary_act %in% c("Evaluation of fairness", "Opinion", "Personal advice"))

                    tab <- table(acts$half, acts$evaluative_request)
                    share_eval <- tab[, "TRUE"] / rowSums(tab)
                    p_half <- chisq.test(tab)$p.value                                  # Yates-corrected for a 2 × 2 table
                    tab; round(share_eval, 3); p_half
                    """#
                ),
                answer: "Roughly a fifth to a quarter of first-half acts are evaluative requests, rising to about two-fifths or more in the second half (p < .01). People open by asking what happened and why, and move toward fairness judgments, opinions, and advice as the conversation builds — so the evaluative questions that bias audits ask are ones real users tend to reach later, with context already in place. Acts are clustered within 32 people, so read the p-value as descriptive.",
                selfCheck: SelfCheck(
                    names: "`share_eval` (named first, second) and `p_half`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        pos = ref["turn_position"].astype(int)
                        first = pos <= pos.groupby([ref["participant"], ref["chat"]]).transform("max") / 2
                        ev = ref["primary_act"].isin(["Evaluation of fairness", "Opinion", "Personal advice"])
                        check("Share of evaluative requests by half", pd.Series(share_eval).reindex(["first", "second"]),
                              [ev[first].mean(), ev[~first].mean()], tol=0.001,
                              hint="Halves are within each participant's chat: first = turn_position ≤ (that chat's last position) / 2.")
                        obs = np.array([[(first & ev).sum(), (first & ~ev).sum()], [(~first & ev).sum(), (~first & ~ev).sum()]], float)
                        exp = obs.sum(1, keepdims=True) * obs.sum(0) / obs.sum()
                        chi2 = ((np.abs(obs - exp) - 0.5) ** 2 / exp).sum()               # Yates' continuity correction
                        check("Chi-square p-value", p_half, stats.chi2.sf(chi2, 1), tol=1e-6)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_coding.csv")
                      pos <- as.integer(ref$turn_position)
                      first <- pos <= ave(pos, ref$participant, ref$chat, FUN = max) / 2
                      ev <- ref$primary_act %in% c("Evaluation of fairness", "Opinion", "Personal advice")
                      check("Share of evaluative requests by half", as.numeric(share_eval[c("first", "second")]), c(mean(ev[first]), mean(ev[!first])),
                            tol = 0.001, hint = "Halves are within each participant's chat: first = turn_position ≤ (that chat's last position) / 2.")
                      obs <- matrix(c(sum(first & ev), sum(!first & ev), sum(first & !ev), sum(!first & !ev)), 2)
                      exp <- outer(rowSums(obs), colSums(obs)) / sum(obs)
                      chi2 <- sum((abs(obs - exp) - 0.5)^2 / exp)                        # Yates' continuity correction
                      check("Chi-square p-value", p_half, pchisq(chi2, 1, lower.tail = FALSE), tol = 1e-6)
                    })
                    """#
                )
            ),
        ],
        "correlation": [
            Exercise(
                title: "Practice simulation: where do people place the chatbot?",
                prompt: "**Practice simulation — chatbots and political court cases.** In `llm_sessions.csv`, `p1_self_placement` is each participant's own political position from the screener (0 = left … 10 = right), and `a7_placement` is where they placed the chatbot's responses on the same scale (or the written answers `not_political` / `dont_know`). Drop the written answers and compute the Spearman correlation between the two. Store `rho` and `n_used`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    sessions = pd.read_csv("llm_sessions.csv", dtype={"a7_placement": str})
                    a7 = pd.to_numeric(sessions["a7_placement"], errors="coerce")
                    keep = a7.notna()
                    rho, p = stats.spearmanr(sessions.loc[keep, "p1_self_placement"], a7[keep])
                    n_used = int(keep.sum())
                    print(round(rho, 3), p, n_used)
                    """#,
                    r: #"""
                    library(tidyverse)

                    sessions <- read_csv("llm_sessions.csv", col_types = cols(a7_placement = col_character()))
                    a7 <- suppressWarnings(as.numeric(sessions$a7_placement))
                    keep <- !is.na(a7)
                    res <- cor.test(sessions$p1_self_placement[keep], a7[keep], method = "spearman", exact = FALSE)
                    rho <- res$estimate[[1]]
                    n_used <- sum(keep)
                    c(rho = rho, p = res$p.value, n = n_used)
                    """#
                ),
                answer: "Clearly negative (ρ ≈ −.5 to −.6, p < .01): the further right participants were, the further left they placed the chatbot, and vice versa — the same kinds of responses look like they lean *away* from you. Spearman's ρ suits two short ordinal scales. With about 30 people, treat this as a pattern to follow up rather than a precise estimate, and keep in mind that perceived lean and coded lean are different measures.",
                selfCheck: SelfCheck(
                    names: "`rho` and `n_used`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_sessions.csv", dtype={"a7_placement": str})
                        ref = ref[ref["a7_placement"].str.fullmatch(r"\d+")]
                        x = stats.rankdata(ref["p1_self_placement"]); y = stats.rankdata(ref["a7_placement"].astype(int))
                        check("Spearman's rho", rho, np.corrcoef(x, y)[0, 1], tol=0.001, hint="Drop the written answers first.")
                        check("Participants used", n_used, len(ref), tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_sessions.csv", colClasses = c(a7_placement = "character"))
                      ref <- ref[grepl("^[0-9]+$", ref$a7_placement), ]
                      check("Spearman's rho", rho, cor(rank(ref$p1_self_placement), rank(as.numeric(ref$a7_placement))), tol = 0.001,
                            hint = "Drop the written answers first.")
                      check("Participants used", n_used, nrow(ref), tol = 0)
                    })
                    """#
                )
            ),
        ],
        "multiple-regression": [
            Exercise(
                title: "Practice simulation: covariate-adjusted predictions",
                prompt: "**Practice simulation — political parasocial attachment.** `ppsr_survey.csv` measures each respondent's parasocial attachment to a political figure they follow (`parasocial`), their affective polarization, and their credibility bias (how much they judge evidence in their figure's favour). The analysis plan predicts that stronger attachment goes with more polarization and more bias, holding ideology, political interest, the figure's perceived charisma, age, education, and recruitment stream constant. Fit both regressions and store the two `parasocial` coefficients as `b_ap` and `b_bias`. Is the prediction supported?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    m_ap = smf.ols(f"affective_polarization ~ parasocial + {covs}", data=ppsr).fit()
                    m_bias = smf.ols(f"credibility_bias ~ parasocial + {covs}", data=ppsr).fit()
                    b_ap, b_bias = m_ap.params["parasocial"], m_bias.params["parasocial"]
                    print(round(b_ap, 3), m_ap.pvalues["parasocial"], round(b_bias, 3), m_bias.pvalues["parasocial"])
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    m_ap <- lm(as.formula(paste("affective_polarization ~ parasocial +", covs)), data = ppsr)
                    m_bias <- lm(as.formula(paste("credibility_bias ~ parasocial +", covs)), data = ppsr)
                    b_ap <- coef(m_ap)[["parasocial"]]
                    b_bias <- coef(m_bias)[["parasocial"]]
                    rbind(polarization = summary(m_ap)$coefficients["parasocial", ],
                          credibility_bias = summary(m_bias)$coefficients["parasocial", ])
                    """#
                ),
                answer: "Both coefficients are positive and clearly significant (p < .001): people more parasocially attached to their figure report more affective polarization and judge more protectively, even holding ideology, interest, charisma, and demographics constant. The prediction is supported.",
                selfCheck: SelfCheck(
                    names: "`b_ap` and `b_bias` — the parasocial coefficients in the two models",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        cols = ["parasocial", "ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        X = np.column_stack([np.ones(len(ref)), ref[cols], (ref["stream"] == "university").astype(float)])
                        for label, outcome, yours in [("Polarization model", "affective_polarization", b_ap),
                                                      ("Credibility-bias model", "credibility_bias", b_bias)]:
                            b = np.linalg.lstsq(X, ref[outcome].to_numpy(), rcond=None)[0]
                            check(f"{label}: parasocial coefficient", yours, b[1], tol=0.001,
                                  hint="Include all seven covariates, with stream as a categorical variable.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      X <- cbind(1, as.matrix(ref[c("parasocial", "ideology_econ", "ideology_social", "political_interest",
                                                    "charisma", "age", "education")]), ref$stream == "university")
                      b_ref <- function(y) qr.coef(qr(X), y)[2]
                      check("Polarization model: parasocial coefficient", b_ap, b_ref(ref$affective_polarization), tol = 0.001,
                            hint = "Include all seven covariates, with stream as a categorical variable.")
                      check("Credibility-bias model: parasocial coefficient", b_bias, b_ref(ref$credibility_bias), tol = 0.001)
                    })
                    """#
                )
            ),
        ],
        "reliability": [
            Exercise(
                title: "Practice simulation: how stable is one response?",
                prompt: "**Practice simulation — chatbots and political court cases.** Every query in `llm_responses.csv` was sent to each model five times. Treat each query × model pair as a group of five runs and compute ICC(1) = (MSB − MSW) / (MSB + (k − 1)·MSW) with k = 5, using all 7,200 responses. Store it as `icc`. What does it say about studies that send each question once?",
                hint: "MSW is the average within-group variance. MSB is k × the variance of the group means.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    responses = pd.read_csv("llm_responses.csv")
                    controversial = responses[responses["control"] == 0]                  # the six controversial headlines
                    cells = controversial.groupby(["query_id", "model"], as_index=False)["lean"].mean()   # average the five runs

                    groups = responses.groupby(["query_id", "model"])["lean"]
                    k = 5
                    msw = groups.var(ddof=1).mean()
                    msb = k * groups.mean().var(ddof=1)
                    icc = (msb - msw) / (msb + (k - 1) * msw)
                    print(round(icc, 3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    responses <- read_csv("llm_responses.csv", show_col_types = FALSE)
                    controversial <- filter(responses, control == 0)                      # the six controversial headlines
                    cells <- controversial |> group_by(query_id, model) |>
                      summarise(lean = mean(lean), .groups = "drop")                      # average the five runs

                    k <- 5
                    groups <- responses |> group_by(query_id, model) |> summarise(m = mean(lean), v = var(lean), .groups = "drop")
                    msw <- mean(groups$v)
                    msb <- k * var(groups$m)
                    icc <- (msb - msw) / (msb + (k - 1) * msw)
                    round(icc, 3)
                    """#
                ),
                answer: "ICC(1) is low — under .2 — so most of the variation in a single coded response is run-to-run noise rather than a stable property of the query and model. A study that sends each question once is measuring mostly noise; averaging repeated runs in fresh sessions, as this design does, is what makes the per-model estimates trustworthy.",
                selfCheck: SelfCheck(
                    names: "`icc`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_responses.csv")
                        # One-way ANOVA sums of squares, groups = query × model
                        g = ref.groupby(["query_id", "model"])["lean"]
                        grand = ref["lean"].mean()
                        ssb = (g.size() * (g.mean() - grand) ** 2).sum()
                        ssw = ((ref["lean"] - g.transform("mean")) ** 2).sum()
                        n_groups, k = g.ngroups, 5
                        msb, msw = ssb / (n_groups - 1), ssw / (len(ref) - n_groups)
                        check("ICC(1)", icc, (msb - msw) / (msb + (k - 1) * msw), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_responses.csv")
                      # One-way ANOVA mean squares, groups = query × model
                      fit <- anova(lm(lean ~ factor(paste(query_id, model)), data = ref))
                      msb <- fit[["Mean Sq"]][1]; msw <- fit[["Mean Sq"]][2]
                      check("ICC(1)", icc, (msb - msw) / (msb + 4 * msw), tol = 0.001)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: does it take the same side twice?",
                prompt: "**Practice simulation — chatbots and political court cases.** In `llm_responses.csv`, does a model return the same signed position (left, neutral, or right) across repeated runs? For each controversial query × model cell, find the share of the five runs that give the cell's most common sign, and average it per model. Store `sign_agreement` in model order A–E. With three possible signs, what would chance alone give?",
                hint: "Use the sign of `lean` (−1, 0, +1). If a cell's runs were 0, 0, −1, 0, +1, its agreement is 3/5.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    responses = pd.read_csv("llm_responses.csv")
                    controversial = responses[responses["control"] == 0]                  # the six controversial headlines
                    cells = controversial.groupby(["query_id", "model"], as_index=False)["lean"].mean()   # average the five runs

                    controversial = controversial.assign(sign=np.sign(controversial["lean"]))
                    modal_share = (controversial.groupby(["model", "query_id"])["sign"]
                                   .agg(lambda s: s.value_counts().iloc[0] / len(s)))
                    sign_agreement = modal_share.groupby("model").mean()
                    print(sign_agreement.round(3))
                    print("all five runs agree:", (modal_share == 1).groupby("model").mean().round(3).to_dict())
                    """#,
                    r: #"""
                    library(tidyverse)

                    responses <- read_csv("llm_responses.csv", show_col_types = FALSE)
                    controversial <- filter(responses, control == 0)                      # the six controversial headlines
                    cells <- controversial |> group_by(query_id, model) |>
                      summarise(lean = mean(lean), .groups = "drop")                      # average the five runs

                    modal_share <- controversial |>
                      mutate(sign = sign(lean)) |>
                      group_by(model, query_id) |>
                      summarise(share = max(table(sign)) / n(), .groups = "drop")
                    sign_agreement <- tapply(modal_share$share, modal_share$model, mean)
                    round(sign_agreement, 3)
                    tapply(modal_share$share == 1, modal_share$model, mean)   # all five runs agree
                    """#
                ),
                answer: "On average only roughly 55–65% of runs give a cell's most common sign, and all five runs agree in fewer than about one cell in ten. Chance agreement is far from zero: five random draws from three equally likely signs already give a modal share of about .56, and given each model's own mix of left, neutral, and right responses, chance is about .56–.62 — so repeated runs agree barely more than chance would. In other words, a single response says little about a model's position on a query — which is why the design repeats every query in fresh sessions, and why stability is a finding in its own right rather than a nuisance.",
                selfCheck: SelfCheck(
                    names: "`sign_agreement` (in model order A–E)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_responses.csv")
                        ref = ref[ref["control"] == 0]
                        expected = []
                        for m in "ABCDE":
                            shares = [np.unique(np.sign(g["lean"]), return_counts=True)[1].max() / len(g)
                                      for _, g in ref[ref["model"] == m].groupby("query_id")]
                            expected.append(np.mean(shares))
                        check("Modal-sign agreement per model", sign_agreement, expected, tol=0.001,
                              hint="Use controversial headlines only, and the share of runs with the cell's most common sign.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_responses.csv")
                      ref <- ref[ref$control == 0, ]
                      expected <- sapply(LETTERS[1:5], function(m) {
                        d <- ref[ref$model == m, ]
                        mean(sapply(split(d$lean, d$query_id), function(x) max(table(sign(x))) / length(x)))
                      })
                      check("Modal-sign agreement per model", as.numeric(sign_agreement), as.numeric(expected), tol = 0.001,
                            hint = "Use controversial headlines only, and the share of runs with the cell's most common sign.")
                    })
                    """#
                )
            ),
        ],
        "reporting": [
            Exercise(
                title: "Practice simulation: report a framework matrix with counts",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_framework.csv` is a framework matrix from the interviews (the framework method; Gale et al., 2013): one row per participant, one 0/1 column per code — for example `code_4_3` (said the chatbot leaned and pointed to a specific cue), `code_4_6` (low confidence in that judgment), and `code_4_1` (described it as neutral or balanced). With 32 participants, the analysis plan reports counts, not significance tests. Join P1 from `llm_sessions.csv`, group it into left (0–3), centre (4–6), and right (7–10), and count how many participants in each group received 4.3. Then count how many participants coded 4.3 were also coded 4.6, and how many coded 4.1 were. Store `count_43` (named by group), `n_43_with_46`, and `n_41_with_46`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    sessions = pd.read_csv("llm_sessions.csv")
                    framework = pd.read_csv("llm_framework.csv").merge(sessions[["participant", "p1_self_placement"]], on="participant")
                    framework["group"] = pd.cut(framework["p1_self_placement"], [-1, 3, 6, 10], labels=["left", "centre", "right"])

                    count_43 = framework.groupby("group", observed=False)["code_4_3"].sum()
                    group_sizes = framework["group"].value_counts().reindex(count_43.index)
                    for g in count_43.index:
                        print(f"{g}: {count_43[g]} of {group_sizes[g]}")
                    n_43_with_46 = int(((framework["code_4_3"] == 1) & (framework["code_4_6"] == 1)).sum())
                    n_41_with_46 = int(((framework["code_4_1"] == 1) & (framework["code_4_6"] == 1)).sum())
                    print(n_43_with_46, "of", framework["code_4_3"].sum(), "| ", n_41_with_46, "of", framework["code_4_1"].sum())
                    """#,
                    r: #"""
                    library(tidyverse)

                    sessions <- read_csv("llm_sessions.csv", show_col_types = FALSE)
                    framework <- read_csv("llm_framework.csv", show_col_types = FALSE) |>
                      left_join(select(sessions, participant, p1_self_placement), by = "participant") |>
                      mutate(group = cut(p1_self_placement, c(-1, 3, 6, 10), labels = c("left", "centre", "right")))

                    framework |> group_by(group) |> summarise(with_43 = sum(code_4_3), n = n())
                    count_43 <- tapply(framework$code_4_3, framework$group, sum)
                    n_43_with_46 <- sum(framework$code_4_3 == 1 & framework$code_4_6 == 1)
                    n_41_with_46 <- sum(framework$code_4_1 == 1 & framework$code_4_6 == 1)
                    c(n_43_with_46, sum(framework$code_4_3), n_41_with_46, sum(framework$code_4_1))
                    """#
                ),
                answer: "Perceived lean with a cue is concentrated among right-of-centre participants (about 7 of 12, versus 2 of 12 left-of-centre) — and that's exactly how to report it: counts out of each group's size, without percentages or p-values that would suggest more precision than 32 interviews give. It was also usually held tentatively: most participants coded 4.3 were also coded 4.6, while almost no one who described the chatbot as balanced was. Patterns like these become hypotheses for the next study; every claim should trace back to cells in the matrix, and every cell to transcript lines.",
                selfCheck: SelfCheck(
                    names: "`count_43` (named left, centre, right), `n_43_with_46`, and `n_41_with_46`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ses = pd.read_csv("llm_sessions.csv")
                        ref = pd.read_csv("llm_framework.csv").merge(ses[["participant", "p1_self_placement"]], on="participant")
                        p1 = ref["p1_self_placement"]
                        expected = [ref.loc[p1 <= 3, "code_4_3"].sum(), ref.loc[(p1 > 3) & (p1 <= 6), "code_4_3"].sum(), ref.loc[p1 > 6, "code_4_3"].sum()]
                        check("Participants coded 4.3, by group", pd.Series(count_43).reindex(["left", "centre", "right"]), expected, tol=0,
                              hint="Left = 0–3, centre = 4–6, right = 7–10.")
                        check("4.3 together with 4.6", n_43_with_46, int((ref["code_4_3"] & ref["code_4_6"]).sum()), tol=0)
                        check("4.1 together with 4.6", n_41_with_46, int((ref["code_4_1"] & ref["code_4_6"]).sum()), tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ses <- read.csv("llm_sessions.csv")
                      ref <- merge(read.csv("llm_framework.csv"), ses[c("participant", "p1_self_placement")], by = "participant")
                      p1 <- ref$p1_self_placement
                      expected <- c(sum(ref$code_4_3[p1 <= 3]), sum(ref$code_4_3[p1 > 3 & p1 <= 6]), sum(ref$code_4_3[p1 > 6]))
                      check("Participants coded 4.3, by group", as.numeric(count_43[c("left", "centre", "right")]), expected, tol = 0,
                            hint = "Left = 0–3, centre = 4–6, right = 7–10.")
                      check("4.3 together with 4.6", n_43_with_46, sum(ref$code_4_3 == 1 & ref$code_4_6 == 1), tol = 0)
                      check("4.1 together with 4.6", n_41_with_46, sum(ref$code_4_1 == 1 & ref$code_4_6 == 1), tol = 0)
                    })
                    """#
                )
            ),
        ],
        "multiple-comparisons": [
            Exercise(
                title: "Practice simulation: one test per chatbot",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_responses.csv` holds 7,200 coded responses: 288 queries about court-case headlines, each sent to five chatbots (fictional models A–E) five times in fresh sessions, with each response coded for `lean` from −3 (left) to +3 (right). The setup code averages the five runs for each controversial query and model (`cells`). Test each model's mean lean against 0 with a one-sample t-test and correct the five p-values with Holm's method. Store `mean_lean` and `p_holm`, both in model order A–E.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    responses = pd.read_csv("llm_responses.csv")
                    controversial = responses[responses["control"] == 0]                  # the six controversial headlines
                    cells = controversial.groupby(["query_id", "model"], as_index=False)["lean"].mean()   # average the five runs

                    from statsmodels.stats.multitest import multipletests

                    by_model = cells.groupby("model")["lean"]
                    mean_lean = by_model.mean()
                    p_raw = by_model.apply(lambda x: stats.ttest_1samp(x, 0).pvalue)
                    p_holm = multipletests(p_raw, method="holm")[1]
                    print(pd.DataFrame({"mean": mean_lean.round(3), "p_holm": p_holm}))
                    """#,
                    r: #"""
                    library(tidyverse)

                    responses <- read_csv("llm_responses.csv", show_col_types = FALSE)
                    controversial <- filter(responses, control == 0)                      # the six controversial headlines
                    cells <- controversial |> group_by(query_id, model) |>
                      summarise(lean = mean(lean), .groups = "drop")                      # average the five runs

                    mean_lean <- tapply(cells$lean, cells$model, mean)
                    p_raw <- tapply(cells$lean, cells$model, function(x) t.test(x, mu = 0)$p.value)
                    p_holm <- p.adjust(p_raw, method = "holm")
                    round(cbind(mean = mean_lean, p_holm = p_holm), 4)
                    """#
                ),
                answer: "Four of the five models lean left on the controversial headlines (model A the most) and survive the Holm correction; model D sits near zero and doesn't. Note the size: even the largest mean is about half a point on a 7-point scale, and the controls sit near 0, so the instrument isn't biased in itself.",
                selfCheck: SelfCheck(
                    names: "`mean_lean` and `p_holm` (both in model order A–E)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_responses.csv")
                        ref = ref[ref["control"] == 0].groupby(["query_id", "model"])["lean"].mean().reset_index()
                        means, ps = [], []
                        for m in "ABCDE":
                            x = ref.loc[ref["model"] == m, "lean"].to_numpy()
                            t = x.mean() / (x.std(ddof=1) / np.sqrt(len(x)))
                            means.append(x.mean()); ps.append(2 * stats.t.sf(abs(t), len(x) - 1))
                        # Holm: multiply the k-th smallest p by (m − k + 1), keep the running maximum, cap at 1
                        order = np.argsort(ps)
                        adj = np.maximum.accumulate([min(1, ps[i] * (5 - k)) for k, i in enumerate(order)])
                        holm = np.empty(5); holm[order] = adj
                        check("Mean lean per model", mean_lean, means, tol=0.001,
                              hint="Average the five runs per query and model first; use controversial headlines only.")
                        check("Holm-adjusted p-values", p_holm, holm, tol=1e-4)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_responses.csv")
                      ref <- aggregate(lean ~ query_id + model, data = ref[ref$control == 0, ], FUN = mean)
                      means <- sapply(LETTERS[1:5], function(m) mean(ref$lean[ref$model == m]))
                      ps <- sapply(LETTERS[1:5], function(m) {
                        x <- ref$lean[ref$model == m]
                        2 * pt(-abs(mean(x) / (sd(x) / sqrt(length(x)))), length(x) - 1)
                      })
                      # Holm: multiply the k-th smallest p by (m − k + 1), keep the running maximum, cap at 1
                      o <- order(ps)
                      holm <- numeric(5); holm[o] <- cummax(pmin(1, ps[o] * (5:1)))
                      check("Mean lean per model", as.numeric(mean_lean), as.numeric(means), tol = 0.001,
                            hint = "Average the five runs per query and model first; use controversial headlines only.")
                      check("Holm-adjusted p-values", as.numeric(p_holm), as.numeric(holm), tol = 1e-4)
                    })
                    """#
                )
            ),
        ],
        "equivalence": [
            Exercise(
                title: "Practice simulation: which chatbots are practically neutral?",
                prompt: "**Practice simulation — chatbots and political court cases.** Using the query × model cell means from `llm_responses.csv` (`cells`, built by the setup code), treat leans within ±0.5 scale points as practically neutral and run a TOST equivalence test for each model. Store `p_tost` in model order A–E (the larger of the two one-sided p-values).",
                hint: "Lower test: H₀ mean ≤ −0.5 (p = P(T ≥ t_lower)). Upper test: H₀ mean ≥ +0.5 (p = P(T ≤ t_upper)).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    responses = pd.read_csv("llm_responses.csv")
                    controversial = responses[responses["control"] == 0]                  # the six controversial headlines
                    cells = controversial.groupby(["query_id", "model"], as_index=False)["lean"].mean()   # average the five runs

                    def tost(x, bound=0.5):
                        lower = stats.ttest_1samp(x, -bound, alternative="greater").pvalue
                        upper = stats.ttest_1samp(x, bound, alternative="less").pvalue
                        return max(lower, upper)

                    p_tost = cells.groupby("model")["lean"].apply(tost)
                    print(p_tost.round(4))
                    """#,
                    r: #"""
                    library(tidyverse)

                    responses <- read_csv("llm_responses.csv", show_col_types = FALSE)
                    controversial <- filter(responses, control == 0)                      # the six controversial headlines
                    cells <- controversial |> group_by(query_id, model) |>
                      summarise(lean = mean(lean), .groups = "drop")                      # average the five runs

                    tost <- function(x, bound = 0.5) {
                      lower <- t.test(x, mu = -bound, alternative = "greater")$p.value
                      upper <- t.test(x, mu = bound, alternative = "less")$p.value
                      max(lower, upper)
                    }
                    p_tost <- tapply(cells$lean, cells$model, tost)
                    round(p_tost, 4)
                    """#
                ),
                answer: "Models whose mean lean sits comfortably inside ±0.5 are statistically equivalent to neutral (p_tost < .05) — even if they also differ significantly from 0. A model can be both: reliably left of zero, yet by less than the smallest lean you'd care about. A model whose mean is near −0.5 can't be shown equivalent. Reporting both tests separates “is there a lean?” from “is it big enough to matter?” — and the ±0.5 bound must be justified (and ideally preregistered) in advance.",
                selfCheck: SelfCheck(
                    names: "`p_tost` (in model order A–E)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_responses.csv")
                        ref = ref[ref["control"] == 0].groupby(["query_id", "model"])["lean"].mean().reset_index()
                        expected = []
                        for m in "ABCDE":
                            x = ref.loc[ref["model"] == m, "lean"].to_numpy()
                            se, df = x.std(ddof=1) / np.sqrt(len(x)), len(x) - 1
                            expected.append(max(stats.t.sf((x.mean() + 0.5) / se, df), stats.t.cdf((x.mean() - 0.5) / se, df)))
                        check("TOST p-values (±0.5)", p_tost, expected, tol=1e-4,
                              hint="Report the larger of the two one-sided p-values.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_responses.csv")
                      ref <- aggregate(lean ~ query_id + model, data = ref[ref$control == 0, ], FUN = mean)
                      expected <- sapply(LETTERS[1:5], function(m) {
                        x <- ref$lean[ref$model == m]
                        se <- sd(x) / sqrt(length(x)); df <- length(x) - 1
                        max(pt((mean(x) + 0.5) / se, df, lower.tail = FALSE), pt((mean(x) - 0.5) / se, df))
                      })
                      check("TOST p-values (±0.5)", as.numeric(p_tost), as.numeric(expected), tol = 1e-4,
                            hint = "Report the larger of the two one-sided p-values.")
                    })
                    """#
                )
            ),
        ],
        "between-within": [
            Exercise(
                title: "Practice simulation: confidence within each person",
                prompt: "**Practice simulation — political parasocial attachment.** In `credibility_trials.csv`, each participant gave 12 credibility judgments with a `confidence` rating (1–5). Protectiveness = credibility when the judgment favours their figure (favoured + creditable, or disliked + discrediting) and 6 − credibility otherwise. For each participant, correlate their 12 protectiveness scores with their 12 confidence ratings; then test whether the average within-person correlation differs from 0 with a one-sample t-test. Store `r_within` (one per participant, missing where undefined), `t_stat`, and `p_val`. How many participants have no defined correlation, and why?",
                hint: "A correlation is undefined when someone gives the same confidence rating on every trial.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    trials = pd.read_csv("credibility_trials.csv")

                    protects_if_high = (trials["target"] == "favoured") == (trials["valence"] == "creditable")
                    trials["protect"] = np.where(protects_if_high, trials["credibility"], 6 - trials["credibility"])
                    r_within = trials.groupby("participant")[["protect", "confidence"]].apply(
                        lambda g: g["protect"].corr(g["confidence"]))
                    print("undefined:", r_within.isna().sum())
                    res = stats.ttest_1samp(r_within.dropna(), 0)
                    t_stat, p_val = res.statistic, res.pvalue
                    print(round(r_within.mean(), 3), round(t_stat, 2), p_val)
                    """#,
                    r: #"""
                    library(tidyverse)

                    trials <- read_csv("credibility_trials.csv", show_col_types = FALSE)

                    trials <- trials |>
                      mutate(protect = if_else((target == "favoured") == (valence == "creditable"),
                                               credibility, 6 - credibility))
                    r_within <- trials |>
                      group_by(participant) |>
                      summarise(r = suppressWarnings(cor(protect, confidence))) |>
                      pull(r)
                    sum(is.na(r_within))
                    res <- t.test(r_within, mu = 0)          # t.test drops the undefined ones
                    t_stat <- res$statistic[[1]]; p_val <- res$p.value
                    c(mean_r = mean(r_within, na.rm = TRUE), t = t_stat, p = p_val)
                    """#
                ),
                answer: "The average within-person correlation is clearly positive (about .3, p < .001): people are more confident precisely when their judgment protects their figure — confidence accompanies bias rather than correcting it. Anyone who used one confidence rating throughout has no defined correlation (your data may have none or one); report how many were excluded. Averaging correlations directly is the simplest approach; a common refinement is to Fisher-z transform them first.",
                selfCheck: SelfCheck(
                    names: "`r_within` (one correlation per participant, in participant order; missing where undefined), `t_stat`, and `p_val`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("credibility_trials.csv")
                        hi = (ref["target"] == "favoured") == (ref["valence"] == "creditable")
                        ref["protect"] = np.where(hi, ref["credibility"], 6 - ref["credibility"])
                        expected = []
                        for _, g in ref.groupby("participant"):
                            x, y = g["protect"].to_numpy(float), g["confidence"].to_numpy(float)
                            sx, sy = x.std(), y.std()
                            expected.append(np.nan if sx == 0 or sy == 0 else ((x - x.mean()) * (y - y.mean())).mean() / (sx * sy))
                        expected = np.array(expected)
                        check("Within-person correlations", r_within, expected, tol=0.001)
                        ok = expected[~np.isnan(expected)]
                        t_ref = ok.mean() / (ok.std(ddof=1) / np.sqrt(len(ok)))
                        check("One-sample t", t_stat, t_ref, tol=0.001, hint="Drop the undefined correlations first.")
                        check("Its p-value", p_val, 2 * stats.t.sf(abs(t_ref), len(ok) - 1), tol=1e-6)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("credibility_trials.csv")
                      ref$protect <- ifelse((ref$target == "favoured") == (ref$valence == "creditable"), ref$credibility, 6 - ref$credibility)
                      expected <- sapply(split(ref, ref$participant), function(g) {
                        x <- g$protect; y <- g$confidence
                        if (sd(x) == 0 || sd(y) == 0) NA else sum((x - mean(x)) * (y - mean(y))) / sqrt(sum((x - mean(x))^2) * sum((y - mean(y))^2))
                      })
                      check("Within-person correlations", r_within, expected, tol = 0.001)
                      ok <- expected[!is.na(expected)]
                      t_ref <- mean(ok) / (sd(ok) / sqrt(length(ok)))
                      check("One-sample t", t_stat, t_ref, tol = 0.001, hint = "Drop the undefined correlations first.")
                      check("Its p-value", p_val, 2 * pt(-abs(t_ref), length(ok) - 1), tol = 1e-6)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: a person-level predictor of a within-person slope",
                prompt: "**Practice simulation — political parasocial attachment.** The setup code computes each participant's within-person correlation between protectiveness and confidence (`r_within`). Add it to `ppsr_survey.csv` and regress it on dispositional `wisdom`, with the covariates. Store the wisdom coefficient as `b_wisdom`. Is the coupling of confidence and bias weaker for wiser people?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"
                    trials = pd.read_csv("credibility_trials.csv")
                    protects_if_high = (trials["target"] == "favoured") == (trials["valence"] == "creditable")
                    trials["protect"] = np.where(protects_if_high, trials["credibility"], 6 - trials["credibility"])
                    r_within = trials.groupby("participant")[["protect", "confidence"]].apply(
                        lambda g: g["protect"].corr(g["confidence"]))        # one within-person correlation each

                    ppsr["r_within"] = r_within.to_numpy()
                    h3b = smf.ols(f"r_within ~ wisdom + {covs}", data=ppsr).fit()   # undefined rows drop out
                    b_wisdom = h3b.params["wisdom"]
                    print(round(b_wisdom, 3), h3b.pvalues["wisdom"], int(h3b.nobs))
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"
                    trials <- read_csv("credibility_trials.csv", show_col_types = FALSE) |>
                      mutate(protect = if_else((target == "favoured") == (valence == "creditable"), credibility, 6 - credibility))
                    r_within <- trials |> group_by(participant) |>
                      summarise(r = suppressWarnings(cor(protect, confidence))) |> pull(r)   # one within-person correlation each

                    ppsr$r_within <- r_within
                    h3b <- lm(r_within ~ wisdom + ideology_econ + ideology_social + political_interest + charisma +
                                age + education + stream, data = ppsr)      # undefined rows drop out
                    b_wisdom <- coef(h3b)[["wisdom"]]
                    summary(h3b)$coefficients["wisdom", ]
                    """#
                ),
                answer: "The wisdom coefficient is negative: wiser participants' confidence tracks the protectiveness of their judgments less closely. Expect this test to be less well powered than the others — a single correlation from 12 trials per person is a noisy outcome.",
                selfCheck: SelfCheck(
                    names: "`b_wisdom`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        ref["r"] = np.asarray(r_within, dtype=float)
                        ref = ref.dropna(subset=["r"])
                        cols = ["wisdom", "ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        X = np.column_stack([np.ones(len(ref)), ref[cols], (ref["stream"] == "university").astype(float)])
                        b = np.linalg.lstsq(X, ref["r"].to_numpy(), rcond=None)[0]
                        check("Wisdom coefficient", b_wisdom, b[1], tol=0.002, hint="Use the covariates too.")
                        check("Negative, as predicted", bool(b_wisdom < 0), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      ref$r <- r_within
                      ref <- ref[!is.na(ref$r), ]
                      X <- cbind(1, as.matrix(ref[c("wisdom", "ideology_econ", "ideology_social", "political_interest", "charisma",
                                                    "age", "education")]), ref$stream == "university")
                      b <- qr.coef(qr(X), ref$r)
                      check("Wisdom coefficient", b_wisdom, b[2], tol = 0.002, hint = "Use the covariates too.")
                      check("Negative, as predicted", b_wisdom < 0, TRUE)
                    })
                    """#
                )
            ),
        ],
        "mixed-models": [
            Exercise(
                title: "Practice simulation: figure or content?",
                prompt: "**Practice simulation — political parasocial attachment.** `credibility_trials.csv` counterbalances which figure each description is attributed to. Model the trials directly: credibility predicted by target (favoured vs. disliked), valence (creditable vs. discrediting), and their interaction, with random intercepts for participants and descriptions. Store the interaction coefficient as `b_fig_x_content`. What does it mean?",
                hint: "Code favoured = 1 and creditable = 1. A positive interaction means favoured figures gain credibility for good conduct and lose less for bad conduct.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    trials = pd.read_csv("credibility_trials.csv")

                    trials["favoured"] = (trials["target"] == "favoured").astype(int)
                    trials["creditable"] = (trials["valence"] == "creditable").astype(int)
                    # statsmodels fits one grouping factor at a time, so with only 12 descriptions we
                    # include them as fixed effects (they absorb the valence main effect) and keep the
                    # random intercept for participants
                    mm = smf.mixedlm("credibility ~ favoured + favoured:creditable + C(description)",
                                     data=trials, groups=trials["participant"]).fit()
                    b_fig_x_content = mm.fe_params["favoured:creditable"]
                    print(round(b_fig_x_content, 3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    trials <- read_csv("credibility_trials.csv", show_col_types = FALSE)

                    library(lme4)
                    trials <- trials |> mutate(favoured = as.integer(target == "favoured"),
                                               creditable = as.integer(valence == "creditable"))
                    mm <- lmer(credibility ~ favoured * creditable + (1 | participant) + (1 | description), data = trials)
                    b_fig_x_content <- fixef(mm)[["favoured:creditable"]]
                    summary(mm)
                    """#
                ),
                answer: "The interaction is large and positive: the same creditable conduct is judged more credible when it's attributed to one's own figure, and the same discrediting conduct less credible. Because each description appears under both attributions across the sample, the difference is attributable to the figure rather than to the content — the logic of the counterbalanced design.",
                selfCheck: SelfCheck(
                    names: "`b_fig_x_content` — the favoured × creditable interaction",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("credibility_trials.csv")
                        m = ref.groupby(["target", "valence"])["credibility"].mean()
                        # Within-person balance means the model's interaction ≈ the raw difference of differences
                        dod = (m[("favoured", "creditable")] - m[("disliked", "creditable")]) - \
                              (m[("favoured", "discrediting")] - m[("disliked", "discrediting")])
                        check("Interaction ≈ difference of differences in cell means", b_fig_x_content, dod, tol=0.03,
                              hint="Code favoured and creditable as 0/1 indicators.")
                        check("Positive (identity-protective)", bool(b_fig_x_content > 0), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("credibility_trials.csv")
                      m <- with(ref, tapply(credibility, list(target, valence), mean))
                      # Within-person balance means the model's interaction ≈ the raw difference of differences
                      dod <- (m["favoured", "creditable"] - m["disliked", "creditable"]) -
                             (m["favoured", "discrediting"] - m["disliked", "discrediting"])
                      check("Interaction ≈ difference of differences in cell means", b_fig_x_content, dod, tol = 0.03,
                            hint = "Code favoured and creditable as 0/1 indicators.")
                      check("Positive (identity-protective)", b_fig_x_content > 0, TRUE)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: does everyday phrasing change the lean?",
                prompt: "**Practice simulation — chatbots and political court cases.** Each query in `llm_responses.csv` comes in an everyday or an instrument (survey-style) `register`. Fit a mixed model to the individual controversial responses: lean predicted by register (instrument as the reference) and model, with a random intercept for each query. Store the register coefficient (everyday − instrument) as `b_register`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    responses = pd.read_csv("llm_responses.csv")
                    controversial = responses[responses["control"] == 0]                  # the six controversial headlines
                    cells = controversial.groupby(["query_id", "model"], as_index=False)["lean"].mean()   # average the five runs

                    mm = smf.mixedlm("lean ~ C(register, Treatment('instrument')) + C(model)",
                                     data=controversial, groups=controversial["query_id"]).fit()
                    b_register = mm.fe_params["C(register, Treatment('instrument'))[T.everyday]"]
                    print(mm.summary())
                    """#,
                    r: #"""
                    library(tidyverse)

                    responses <- read_csv("llm_responses.csv", show_col_types = FALSE)
                    controversial <- filter(responses, control == 0)                      # the six controversial headlines
                    cells <- controversial |> group_by(query_id, model) |>
                      summarise(lean = mean(lean), .groups = "drop")                      # average the five runs

                    library(lme4)
                    controversial <- controversial |> mutate(register = relevel(factor(register), ref = "instrument"))
                    mm <- lmer(lean ~ register + model + (1 | query_id), data = controversial)
                    b_register <- fixef(mm)[["registereveryday"]]
                    summary(mm)
                    """#
                ),
                answer: "Everyday phrasing shifts responses about a quarter of a point further left than the instrument phrasing of the same headline and speech act. The measured lean depends on how the question is asked. Because the design is fully balanced, the coefficient equals the raw difference in means; the mixed model's job is to get the standard error right, since responses to the same query are correlated.",
                selfCheck: SelfCheck(
                    names: "`b_register`",
                    python: #"""
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_responses.csv")
                        ref = ref[ref["control"] == 0]
                        means = ref.groupby("register")["lean"].mean()
                        # Balanced design: the fixed effect equals the raw difference in means
                        check("Register effect (everyday − instrument)", b_register, means["everyday"] - means["instrument"],
                              tol=0.005, hint="Make instrument the reference level.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_responses.csv")
                      ref <- ref[ref$control == 0, ]
                      means <- tapply(ref$lean, ref$register, mean)
                      # Balanced design: the fixed effect equals the raw difference in means
                      check("Register effect (everyday − instrument)", b_register, means[["everyday"]] - means[["instrument"]],
                            tol = 0.005, hint = "Make instrument the reference level.")
                    })
                    """#
                )
            ),
        ],
        "inter-rater": [
            Exercise(
                title: "Practice simulation: the consensus meeting's segmentation check",
                prompt: "**Practice simulation — chatbots and political court cases.** Every transcript is coded independently by two coders, whose sheets are `llm_coder_a.csv` and `llm_coder_b.csv` (one row per speech act, same columns as the coding sheet). Before comparing codes, the consensus meeting checks **segmentation**: did both coders split each query into the same speech acts? Reproduce the meeting's summary. Count each coder's speech acts (`n_a`, `n_b`); speech acts **matched** in both (same `speech_act_id` and the same `speech_act_text`, compared lowercased and trimmed; `n_matched`); acts only one coder has (`only_a`, `only_b`); and same-ID acts whose text differs (`text_differs`). Then compute `segmentation_agreement` = matched ÷ the larger count, and `rows_with_conflict`: matched acts where the coders disagree on at least one of the 14 coded columns (again lowercased and trimmed; two blanks agree).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    coder_a = pd.read_csv("llm_coder_a.csv", keep_default_na=False)
                    coder_b = pd.read_csv("llm_coder_b.csv", keep_default_na=False)
                    code_cols = ["clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                            "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                            "disclosure_direction", "relation"]
                    norm = lambda column: column.astype(str).str.strip().str.lower()

                    both = coder_a.merge(coder_b, on="speech_act_id", suffixes=("_a", "_b"))
                    same_text = norm(both["speech_act_text_a"]) == norm(both["speech_act_text_b"])
                    matched = both[same_text]

                    n_a, n_b, n_matched = len(coder_a), len(coder_b), len(matched)
                    only_a = int((~coder_a["speech_act_id"].isin(coder_b["speech_act_id"])).sum())
                    only_b = int((~coder_b["speech_act_id"].isin(coder_a["speech_act_id"])).sum())
                    text_differs = int((~same_text).sum())
                    segmentation_agreement = n_matched / max(n_a, n_b)
                    conflicts = sum(norm(matched[c + "_a"]) != norm(matched[c + "_b"]) for c in code_cols)
                    rows_with_conflict = int((conflicts > 0).sum())
                    print(n_a, n_b, n_matched, only_a, only_b, text_differs, round(segmentation_agreement, 3), rows_with_conflict)
                    print(both.loc[~same_text, ["speech_act_id", "speech_act_text_a", "speech_act_text_b"]].head())
                    """#,
                    r: #"""
                    library(tidyverse)

                    coder_a <- read_csv("llm_coder_a.csv", trim_ws = FALSE, col_types = cols(.default = col_character()))
                    coder_b <- read_csv("llm_coder_b.csv", trim_ws = FALSE, col_types = cols(.default = col_character()))
                    code_cols <- c("clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                              "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                              "disclosure_direction", "relation")
                    norm <- function(x) str_to_lower(str_trim(coalesce(x, "")))

                    both <- inner_join(coder_a, coder_b, by = "speech_act_id", suffix = c("_a", "_b"))
                    same_text <- norm(both$speech_act_text_a) == norm(both$speech_act_text_b)
                    matched <- both[same_text, ]

                    n_a <- nrow(coder_a); n_b <- nrow(coder_b); n_matched <- nrow(matched)
                    only_a <- sum(!coder_a$speech_act_id %in% coder_b$speech_act_id)
                    only_b <- sum(!coder_b$speech_act_id %in% coder_a$speech_act_id)
                    text_differs <- sum(!same_text)
                    segmentation_agreement <- n_matched / max(n_a, n_b)
                    conflicts <- rowSums(sapply(code_cols, function(c) norm(matched[[paste0(c, "_a")]]) != norm(matched[[paste0(c, "_b")]])))
                    rows_with_conflict <- sum(conflicts > 0)
                    c(n_a, n_b, n_matched, only_a, only_b, text_differs, round(segmentation_agreement, 3), rows_with_conflict)
                    """#
                ),
                answer: "Segmentation agreement is about .85–.9. The mismatches come in two kinds the meeting has to settle before comparing any codes: queries one coder split into two requests while the other kept them as one (an `_b` only one coder has, and a `_a` whose text differs), and an uptake (“ok that makes sense.”) that one coder split off as its own act. Once the split is agreed, each coder codes any new rows on their own. More than half the matched acts still have at least one conflicting column — with 14 columns per act, small disagreement rates add up — which is why the meeting filters the comparison to conflicts and decides them one at a time.",
                selfCheck: SelfCheck(
                    names: "`n_a`, `n_b`, `n_matched`, `only_a`, `only_b`, `text_differs`, `segmentation_agreement`, and `rows_with_conflict`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        A = pd.read_csv("llm_coder_a.csv", keep_default_na=False)
                        B = pd.read_csv("llm_coder_b.csv", keep_default_na=False)
                        cols = ["clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                                "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                                "disclosure_direction", "relation"]
                        b_text = dict(zip(B["speech_act_id"], B["speech_act_text"].astype(str).str.strip().str.lower()))
                        b_rows = B.set_index("speech_act_id")
                        match, differ, conflict = 0, 0, 0
                        for _, row in A.iterrows():
                            sid = row["speech_act_id"]
                            if sid not in b_text:
                                continue
                            if str(row["speech_act_text"]).strip().lower() == b_text[sid]:
                                match += 1
                                other = b_rows.loc[sid]
                                conflict += any(str(row[c]).strip().lower() != str(other[c]).strip().lower() for c in cols)
                            else:
                                differ += 1
                        check("Speech acts per coder", [n_a, n_b], [len(A), len(B)], tol=0)
                        check("Matched acts", n_matched, match, tol=0, hint="Same ID and the same text (lowercased, trimmed).")
                        check("Only in A / only in B", [only_a, only_b], [int((~A["speech_act_id"].isin(B["speech_act_id"])).sum()),
                                                                         int((~B["speech_act_id"].isin(A["speech_act_id"])).sum())], tol=0)
                        check("Same ID, different text", text_differs, differ, tol=0)
                        check("Segmentation agreement", segmentation_agreement, match / max(len(A), len(B)), tol=1e-6)
                        check("Matched rows with a conflict", rows_with_conflict, conflict, tol=0,
                              hint="Compare all 14 coded columns, lowercased and trimmed; two blanks agree.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      A <- read.csv("llm_coder_a.csv", colClasses = "character", strip.white = FALSE)
                      B <- read.csv("llm_coder_b.csv", colClasses = "character", strip.white = FALSE)
                      cols <- c("clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                                "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                                "disclosure_direction", "relation")
                      nz <- function(x) tolower(trimws(x))
                      match <- 0; differ <- 0; conflict <- 0
                      for (k in seq_len(nrow(A))) {
                        j <- match(A$speech_act_id[k], B$speech_act_id)
                        if (is.na(j)) next
                        if (nz(A$speech_act_text[k]) == nz(B$speech_act_text[j])) {
                          match <- match + 1
                          conflict <- conflict + any(nz(unlist(A[k, cols])) != nz(unlist(B[j, cols])))
                        } else differ <- differ + 1
                      }
                      check("Speech acts per coder", c(n_a, n_b), c(nrow(A), nrow(B)), tol = 0)
                      check("Matched acts", n_matched, match, tol = 0, hint = "Same ID and the same text (lowercased, trimmed).")
                      check("Only in A / only in B", c(only_a, only_b), c(sum(!A$speech_act_id %in% B$speech_act_id), sum(!B$speech_act_id %in% A$speech_act_id)), tol = 0)
                      check("Same ID, different text", text_differs, differ, tol = 0)
                      check("Segmentation agreement", segmentation_agreement, match / max(nrow(A), nrow(B)), tol = 1e-6)
                      check("Matched rows with a conflict", rows_with_conflict, conflict, tol = 0,
                            hint = "Compare all 14 coded columns, lowercased and trimmed; two blanks agree.")
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: Krippendorff's alpha for each coding category",
                prompt: "**Practice simulation — chatbots and political court cases.** Reliability is calculated on what each coder chose on their own, before the consensus meeting — that's why the meeting never edits `llm_coder_a.csv` and `llm_coder_b.csv`. Using the speech acts both coders matched (same `speech_act_id` and same `speech_act_text`, lowercased and trimmed), compute **Krippendorff's α** (nominal; Hayes & Krippendorff, 2007) for each of the 14 coded columns, treating a blank as its own value. Store `alpha_by_category` (named by column) and `below_threshold`, the columns below .667 — the level below which, by Krippendorff's (2004) convention, codes shouldn't support even tentative conclusions (.800 is the usual target).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    from collections import Counter

                    coder_a = pd.read_csv("llm_coder_a.csv", keep_default_na=False)
                    coder_b = pd.read_csv("llm_coder_b.csv", keep_default_na=False)
                    code_cols = ["clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                            "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                            "disclosure_direction", "relation"]
                    norm = lambda column: column.astype(str).str.strip().str.lower()
                    both = coder_a.merge(coder_b, on="speech_act_id", suffixes=("_a", "_b"))
                    matched = both[norm(both["speech_act_text_a"]) == norm(both["speech_act_text_b"])]

                    def krippendorff_nominal(a, b):
                        """Krippendorff's alpha for two coders, nominal data, no missing units."""
                        values = list(a) + list(b)
                        counts = Counter(values)
                        n = len(values)
                        observed = sum(x != y for x, y in zip(a, b)) * 2 / n               # disagreeing pairable values
                        expected = (n * n - sum(c * c for c in counts.values())) / (n * (n - 1))
                        return 1 - observed / expected if expected > 0 else 1.0

                    alpha_by_category = pd.Series({c: krippendorff_nominal(norm(matched[c + "_a"]), norm(matched[c + "_b"])) for c in code_cols})
                    below_threshold = alpha_by_category[alpha_by_category < 0.667].index.tolist()
                    print(alpha_by_category.round(3)); print(below_threshold)
                    print(pd.crosstab(matched["directness_a"], matched["directness_b"]))
                    """#,
                    r: #"""
                    library(tidyverse)

                    library(irr)

                    coder_a <- read_csv("llm_coder_a.csv", trim_ws = FALSE, col_types = cols(.default = col_character()))
                    coder_b <- read_csv("llm_coder_b.csv", trim_ws = FALSE, col_types = cols(.default = col_character()))
                    code_cols <- c("clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                              "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                              "disclosure_direction", "relation")
                    norm <- function(x) str_to_lower(str_trim(coalesce(x, "")))
                    both <- inner_join(coder_a, coder_b, by = "speech_act_id", suffix = c("_a", "_b"))
                    matched <- both[norm(both$speech_act_text_a) == norm(both$speech_act_text_b), ]

                    alpha_by_category <- sapply(code_cols, function(c) {
                      a <- norm(matched[[paste0(c, "_a")]]); b <- norm(matched[[paste0(c, "_b")]])
                      values <- union(a, b)                               # kripp.alpha wants numbers: code each value as an integer
                      kripp.alpha(rbind(match(a, values), match(b, values)), method = "nominal")$value
                    })
                    below_threshold <- names(alpha_by_category)[alpha_by_category < 0.667]
                    round(alpha_by_category, 3); below_threshold
                    table(matched$directness_a, matched$directness_b)
                    """#
                ),
                answer: "Most columns are reliable or close to it (α ≈ .7–.95), but **directness** falls far below .667 (about .4–.5). Its disagreements are concentrated in “can you …” requests: the draft rule codes them Indirect (conventionally indirect), and one coder kept reading them as Direct. That is a codebook problem, not a coder problem — the fix is to settle the rule, log it in the decision log, and recode. Columns with only a few non-blank codes (leading construction, disclosure direction) can swing by a tenth on a single disagreement, so read their α alongside how often they're used. Unlike κ, α handles any number of coders and missing codes, which is why the team uses it for the final report.",
                selfCheck: SelfCheck(
                    names: "`alpha_by_category` (named by column) and `below_threshold` (a list of columns)",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        A = pd.read_csv("llm_coder_a.csv", keep_default_na=False)
                        B = pd.read_csv("llm_coder_b.csv", keep_default_na=False)
                        cols = ["clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                                "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                                "disclosure_direction", "relation"]
                        m = A.merge(B, on="speech_act_id", suffixes=("_a", "_b"))
                        nz = lambda x: x.astype(str).str.strip().str.lower()
                        m = m[nz(m["speech_act_text_a"]) == nz(m["speech_act_text_b"])]
                        expected = {}
                        for c in cols:
                            a, b = nz(m[c + "_a"]).to_numpy(), nz(m[c + "_b"]).to_numpy()
                            pooled = np.concatenate([a, b]); n = len(pooled)
                            # alpha = 1 - D_o / D_e, from the coincidence matrix of pairable values
                            d_o = 2 * (a != b).sum() / n
                            _, freq = np.unique(pooled, return_counts=True)
                            d_e = (n ** 2 - (freq ** 2).sum()) / (n * (n - 1))
                            expected[c] = 1 - d_o / d_e if d_e > 0 else 1.0
                        check("Alpha for each column", pd.Series(alpha_by_category).reindex(cols), [expected[c] for c in cols], tol=0.001,
                              hint="Use matched acts only, lowercase and trim the codes, and treat blanks as a value.")
                        check("Columns below .667", sorted(below_threshold), sorted(c for c in cols if expected[c] < 0.667))

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      A <- read.csv("llm_coder_a.csv", colClasses = "character", strip.white = FALSE)
                      B <- read.csv("llm_coder_b.csv", colClasses = "character", strip.white = FALSE)
                      cols <- c("clause_type", "primary_act", "directness", "presup", "trigger_type", "presup_direction",
                                "leading_construction", "evaluative", "polarity", "target", "partisan_terms", "stance_disclosure",
                                "disclosure_direction", "relation")
                      nz <- function(x) tolower(trimws(x))
                      m <- merge(A, B, by = "speech_act_id", suffixes = c("_a", "_b"))
                      m <- m[nz(m$speech_act_text_a) == nz(m$speech_act_text_b), ]
                      expected <- sapply(cols, function(c) {
                        a <- nz(m[[paste0(c, "_a")]]); b <- nz(m[[paste0(c, "_b")]])
                        pooled <- c(a, b); n <- length(pooled)
                        d_o <- 2 * sum(a != b) / n                            # alpha = 1 - D_o / D_e
                        d_e <- (n^2 - sum(table(pooled)^2)) / (n * (n - 1))
                        if (d_e > 0) 1 - d_o / d_e else 1
                      })
                      check("Alpha for each column", as.numeric(alpha_by_category[cols]), as.numeric(expected), tol = 0.001,
                            hint = "Use matched acts only, lowercase and trim the codes, and treat blanks as a value.")
                      check("Columns below .667", sort(below_threshold), sort(cols[expected < 0.667]))
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: do participants' labels match the coders'?",
                prompt: "**Practice simulation — chatbots and political court cases.** In the interview, participants labelled each of their queries with a card (`llm_card_labels.csv`: `query_id` and `card_label` — what happened, why or how it happened, whether it was fair, what will happen next, what the AI thinks, what someone should do, none of these). Join the labels to the first speech act of each query in `llm_coding.csv` (IDs ending in `_a`). Map the coders' `primary_act` onto the card categories — Summary → what happened, Explanation → why or how it happened, Evaluation of fairness → whether it was fair, Prediction → what will happen next, Opinion → what the AI thinks, Personal advice → what someone should do, and Verification, Clarification, Pushback, and Meta → none of these — and compute Cohen's κ between participants' and coders' labels. Store `kappa_card`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    from sklearn.metrics import cohen_kappa_score

                    coding = pd.read_csv("llm_coding.csv", keep_default_na=False)
                    cards = pd.read_csv("llm_card_labels.csv")
                    first_acts = coding[coding["speech_act_id"].str.endswith("_a")].merge(cards, on="query_id")
                    to_card = {"Summary": "what happened", "Explanation": "why or how it happened", "Evaluation of fairness": "whether it was fair",
                               "Prediction": "what will happen next", "Opinion": "what the AI thinks", "Personal advice": "what someone should do"}
                    coder_card = first_acts["primary_act"].map(to_card).fillna("none of these")
                    kappa_card = cohen_kappa_score(first_acts["card_label"], coder_card)
                    print(round(kappa_card, 3))
                    print(pd.crosstab(first_acts["card_label"], coder_card))
                    """#,
                    r: #"""
                    library(tidyverse)

                    library(irr)

                    coding <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)
                    cards <- read_csv("llm_card_labels.csv", show_col_types = FALSE)
                    first_acts <- coding |> filter(str_ends(speech_act_id, "_a")) |> inner_join(cards, by = "query_id")
                    to_card <- c("Summary" = "what happened", "Explanation" = "why or how it happened", "Evaluation of fairness" = "whether it was fair",
                                 "Prediction" = "what will happen next", "Opinion" = "what the AI thinks", "Personal advice" = "what someone should do")
                    coder_card <- coalesce(unname(to_card[first_acts$primary_act]), "none of these")
                    kappa_card <- kappa2(data.frame(first_acts$card_label, coder_card))$value
                    round(kappa_card, 3)
                    table(first_acts$card_label, coder_card)
                    """#
                ),
                answer: "κ ≈ .8: participants' own sense of what they were asking for mostly matches the coders' speech-act codes. This is a **validity** check rather than a reliability check — the two “raters” are the asker and the codebook — so read the disagreements one by one. A telling one: “what should the government do now” is coded Opinion (it asks for the chatbot's view), but participants often pick “what someone should do”. Disagreements like that show where the codebook's categories cut differently from how people think about their own requests.",
                selfCheck: SelfCheck(
                    names: "`kappa_card`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        ref = ref[ref["speech_act_id"].str.endswith("_a")].merge(pd.read_csv("llm_card_labels.csv"), on="query_id")
                        to_card = {"Summary": "what happened", "Explanation": "why or how it happened", "Evaluation of fairness": "whether it was fair",
                                   "Prediction": "what will happen next", "Opinion": "what the AI thinks", "Personal advice": "what someone should do"}
                        a, b = ref["card_label"], ref["primary_act"].map(to_card).fillna("none of these")
                        po = (a == b).mean()
                        pe = sum((a == v).mean() * (b == v).mean() for v in set(a) | set(b))
                        check("Kappa: participants vs. coders", kappa_card, (po - pe) / (1 - pe), tol=0.001,
                              hint="Use only the first speech act of each query.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_coding.csv")
                      ref <- merge(ref[endsWith(ref$speech_act_id, "_a"), ], read.csv("llm_card_labels.csv"), by = "query_id")
                      to_card <- c("Summary" = "what happened", "Explanation" = "why or how it happened", "Evaluation of fairness" = "whether it was fair",
                                   "Prediction" = "what will happen next", "Opinion" = "what the AI thinks", "Personal advice" = "what someone should do")
                      a <- ref$card_label; b <- ifelse(ref$primary_act %in% names(to_card), to_card[ref$primary_act], "none of these")
                      po <- mean(a == b); pe <- sum(sapply(union(a, b), function(v) mean(a == v) * mean(b == v)))
                      check("Kappa: participants vs. coders", kappa_card, (po - pe) / (1 - pe), tol = 0.001,
                            hint = "Use only the first speech act of each query.")
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: agreement when indexing interviews",
                prompt: "**Practice simulation — chatbots and political court cases.** For a framework analysis, two coders indexed the interview answers of the same seven transcripts. `llm_indexing.csv` has one row per answer line and code, with a 0/1 for each coder (`coder_a`, `coder_b`). The codes are 4.1–4.6 (how the participant saw the chatbot's stance — 4.6 is “low confidence in judgment”, added during initial coding) and 5.1–5.4 (whether they told it their own view). Read `code` as text, compute κ for each code that at least one coder applied (κ is undefined for a code nobody used), and list the codes below .70. Store `kappa_by_code` (named by code) and `flagged`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    from sklearn.metrics import cohen_kappa_score

                    indexing = pd.read_csv("llm_indexing.csv", dtype={"code": str})
                    used = indexing.groupby("code").filter(lambda g: (g["coder_a"] + g["coder_b"]).sum() > 0)
                    kappa_by_code = used.groupby("code").apply(lambda g: cohen_kappa_score(g["coder_a"], g["coder_b"]))
                    flagged = kappa_by_code[kappa_by_code < 0.70].index.tolist()
                    print(kappa_by_code.round(2)); print(flagged)
                    """#,
                    r: #"""
                    library(tidyverse)

                    library(irr)

                    indexing <- read_csv("llm_indexing.csv", col_types = cols(code = col_character()))
                    used <- indexing |> group_by(code) |> filter(sum(coder_a + coder_b) > 0) |> ungroup()
                    kappa_by_code <- sapply(split(used, used$code), function(g) kappa2(g[, c("coder_a", "coder_b")])$value)
                    flagged <- names(kappa_by_code)[kappa_by_code < 0.70]
                    round(kappa_by_code, 2); flagged
                    """#
                ),
                answer: "The concrete codes — where the participant placed the AI, whether they told it their view — agree perfectly or nearly so. Code **4.6**, low confidence in judgment, falls far below .70: it was added inductively, and the line between hedged talk (“I guess”) and genuine uncertainty isn't yet written into its definition. Following the protocol, the coders discuss its disagreements, rewrite the include/exclude rules, and re-index. Codes nobody used in these seven transcripts can't be checked at all — with 20% double coding, a rare code may need a targeted second round.",
                selfCheck: SelfCheck(
                    names: "`kappa_by_code` (named by code, e.g. \"4.3\") and `flagged` (a list of codes)",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_indexing.csv", dtype={"code": str})
                        expected = {}
                        for code, g in ref.groupby("code"):
                            a, b = g["coder_a"].to_numpy(), g["coder_b"].to_numpy()
                            if (a + b).sum() == 0:
                                continue
                            po = (a == b).mean(); pe = a.mean() * b.mean() + (1 - a.mean()) * (1 - b.mean())
                            expected[code] = (po - pe) / (1 - pe) if pe < 1 else 1.0
                        codes = sorted(expected)
                        check("Codes with a kappa", sorted(map(str, pd.Series(kappa_by_code).index)), codes,
                              hint="Skip codes that neither coder applied.")
                        check("Kappa for each code", pd.Series(kappa_by_code).reindex(codes), [expected[c] for c in codes], tol=0.001)
                        check("Codes below .70", sorted(flagged), sorted(c for c in codes if expected[c] < 0.70))

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_indexing.csv", colClasses = c(code = "character"))
                      expected <- c()
                      for (code in sort(unique(ref$code))) {
                        a <- ref$coder_a[ref$code == code]; b <- ref$coder_b[ref$code == code]
                        if (sum(a + b) == 0) next
                        po <- mean(a == b); pe <- mean(a) * mean(b) + (1 - mean(a)) * (1 - mean(b))
                        expected[code] <- if (pe < 1) (po - pe) / (1 - pe) else 1
                      }
                      check("Codes with a kappa", sort(names(kappa_by_code)), names(expected), hint = "Skip codes that neither coder applied.")
                      check("Kappa for each code", as.numeric(kappa_by_code[names(expected)]), as.numeric(expected), tol = 0.001)
                      check("Codes below .70", sort(flagged), sort(names(expected)[expected < 0.70]))
                    })
                    """#
                )
            ),
        ],
        "scale-scoring": [
            Exercise(
                title: "Practice simulation: scoring a wisdom scale",
                prompt: "**Practice simulation — political parasocial attachment.** `ppsr_survey.csv` has 375 respondents' answers to twelve 1–5 wisdom items, `wis_1`–`wis_12`, modeled on the 3D-WS-12 (Thomas et al., 2017), a short form of Ardelt's (2003) Three-Dimensional Wisdom Scale. In this simulated file, items 2, 6, 7, and 11 are reverse-worded (with real data, follow the published scoring key). Reverse-key them (6 − x), average the twelve items into `wisdom_score`, and compute Cronbach's α as `alpha`. Does your score match the precomputed `wisdom` column? The study's power analysis assumed a reliability of .80 — does the scale reach it?",
                hint: "Reverse-key before you compute α, or the reversed items will drag it down.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    import pingouin as pg

                    items = [f"wis_{i}" for i in range(1, 13)]
                    keyed = ppsr[items].copy()
                    for i in [2, 6, 7, 11]:                     # reverse-worded items
                        keyed[f"wis_{i}"] = 6 - keyed[f"wis_{i}"]
                    wisdom_score = keyed.mean(axis=1)
                    alpha = pg.cronbach_alpha(data=keyed)[0]
                    print(round(alpha, 3), (wisdom_score - ppsr["wisdom"]).abs().max())
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    keyed <- ppsr |>
                      select(wis_1:wis_12) |>
                      mutate(across(c(wis_2, wis_6, wis_7, wis_11), ~ 6 - .x))   # reverse-worded items
                    wisdom_score <- rowMeans(keyed)
                    alpha <- psych::alpha(keyed)$total$raw_alpha
                    c(alpha = alpha, max_diff = max(abs(wisdom_score - ppsr$wisdom)))
                    """#
                ),
                answer: "Your scores match the precomputed column exactly, and α is about .91 — comfortably above the .80 assumed in the power analysis. In real data, report α (or ω) for your own sample, since the interaction tests lose power quickly when reliability falls.",
                selfCheck: SelfCheck(
                    names: "`wisdom_score` (one score per participant, in row order) and `alpha`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        items = ref[[f"wis_{i}" for i in range(1, 13)]].astype(float)
                        for i in [2, 6, 7, 11]:
                            items[f"wis_{i}"] = 6 - items[f"wis_{i}"]
                        check("Scores match the precomputed wisdom column",
                              bool(np.abs(np.asarray(wisdom_score) - ref["wisdom"]).max() < 0.001), True,
                              hint="Reverse-key items 2, 6, 7, and 11 as 6 − x before averaging.")
                        C = items.cov().to_numpy()
                        k = C.shape[0]
                        check("Cronbach's α", alpha, k / (k - 1) * (1 - np.trace(C) / C.sum()), tol=0.002)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      items <- ref[paste0("wis_", 1:12)]
                      items[paste0("wis_", c(2, 6, 7, 11))] <- 6 - items[paste0("wis_", c(2, 6, 7, 11))]
                      check("Scores match the precomputed wisdom column", max(abs(wisdom_score - ref$wisdom)) < 0.001, TRUE,
                            hint = "Reverse-key items 2, 6, 7, and 11 as 6 − x before averaging.")
                      C <- cov(items); k <- ncol(C)
                      check("Cronbach's α", alpha, k / (k - 1) * (1 - sum(diag(C)) / sum(C)), tol = 0.002)
                    })
                    """#
                )
            ),
        ],
        "comparing-predictors": [
            Exercise(
                title: "Practice simulation: two related predictors",
                prompt: "**Practice simulation — political parasocial attachment.** Is parasocial attachment (`parasocial`) distinct from identity fusion with the figure (`fusion`)? In `ppsr_survey.csv`, standardize credibility bias, parasocial intensity, and fusion, and fit the credibility-bias model with both predictors plus the covariates (`covs`). Store their correlation as `r_pf` and the standardized coefficients as `beta_psr` and `beta_fusion`. Which is the stronger predictor — and can the two be separated at all? (The analysis plan calls the comparison indeterminate if r > .80.)",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    from statsmodels.stats.outliers_influence import variance_inflation_factor

                    z = ppsr.copy()
                    for col in ["credibility_bias", "parasocial", "fusion"]:
                        z[col] = (z[col] - z[col].mean()) / z[col].std()
                    both = smf.ols(f"credibility_bias ~ parasocial + fusion + {covs}", data=z).fit()
                    beta_psr, beta_fusion = both.params["parasocial"], both.params["fusion"]
                    r_pf = ppsr["parasocial"].corr(ppsr["fusion"])

                    names = both.model.exog_names
                    vifs = {n: variance_inflation_factor(both.model.exog, names.index(n)) for n in ["parasocial", "fusion"]}
                    only_psr = smf.ols(f"credibility_bias ~ parasocial + {covs}", data=z).fit()
                    only_fusion = smf.ols(f"credibility_bias ~ fusion + {covs}", data=z).fit()
                    print(round(r_pf, 2), round(beta_psr, 3), round(beta_fusion, 3), vifs,
                          "ΔR² fusion:", round(both.rsquared - only_psr.rsquared, 3),
                          "ΔR² parasocial:", round(both.rsquared - only_fusion.rsquared, 3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    z <- ppsr |> mutate(across(c(credibility_bias, parasocial, fusion), ~ as.numeric(scale(.x))))
                    both <- lm(as.formula(paste("credibility_bias ~ parasocial + fusion +", covs)), data = z)
                    beta_psr <- coef(both)[["parasocial"]]
                    beta_fusion <- coef(both)[["fusion"]]
                    r_pf <- cor(ppsr$parasocial, ppsr$fusion)

                    only_psr <- lm(as.formula(paste("credibility_bias ~ parasocial +", covs)), data = z)
                    only_fusion <- lm(as.formula(paste("credibility_bias ~ fusion +", covs)), data = z)
                    c(r = r_pf, beta_psr = beta_psr, beta_fusion = beta_fusion,
                      delta_r2_fusion = summary(both)$r.squared - summary(only_psr)$r.squared,
                      delta_r2_psr = summary(both)$r.squared - summary(only_fusion)$r.squared)
                    car::vif(both)[c("parasocial", "fusion")]
                    """#
                ),
                answer: "Fusion and parasocial intensity correlate about .65 — related but separable (VIFs around 2, far below the usual worry points of 5–10), so their effects can be separated. Fusion carries the larger standardized coefficient and adds more unique variance than parasocial intensity does: being fused with the figure, not just attached to them, is what drives protective judgment.",
                selfCheck: SelfCheck(
                    names: "`r_pf` (their correlation) and `beta_psr` and `beta_fusion` (standardized coefficients)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        cols = ["parasocial", "fusion", "ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        X = np.column_stack([np.ones(len(ref)), ref[cols], (ref["stream"] == "university").astype(float)])
                        y = ref["credibility_bias"].to_numpy()
                        b = np.linalg.lstsq(X, y, rcond=None)[0]
                        sd_y = y.std(ddof=1)
                        # A standardized coefficient is the raw coefficient × SD(x) / SD(y)
                        check("Correlation of parasocial intensity and fusion", r_pf, ref["parasocial"].corr(ref["fusion"]), tol=0.001)
                        check("β for parasocial intensity", beta_psr, b[1] * ref["parasocial"].std() / sd_y, tol=0.002)
                        check("β for fusion", beta_fusion, b[2] * ref["fusion"].std() / sd_y, tol=0.002)
                        check("Fusion is the stronger predictor, and r < .80", bool(beta_fusion > beta_psr and r_pf < 0.80), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      X <- cbind(1, as.matrix(ref[c("parasocial", "fusion", "ideology_econ", "ideology_social", "political_interest",
                                                    "charisma", "age", "education")]), ref$stream == "university")
                      b <- qr.coef(qr(X), ref$credibility_bias)
                      sd_y <- sd(ref$credibility_bias)
                      # A standardized coefficient is the raw coefficient × SD(x) / SD(y)
                      check("Correlation of parasocial intensity and fusion", r_pf, cor(ref$parasocial, ref$fusion), tol = 0.001)
                      check("β for parasocial intensity", beta_psr, b[2] * sd(ref$parasocial) / sd_y, tol = 0.002)
                      check("β for fusion", beta_fusion, b[3] * sd(ref$fusion) / sd_y, tol = 0.002)
                      check("Fusion is the stronger predictor, and r < .80", beta_fusion > beta_psr && r_pf < 0.80, TRUE)
                    })
                    """#
                )
            ),
        ],
        "moderation": [
            Exercise(
                title: "Practice simulation: does wisdom weaken the link?",
                prompt: "**Practice simulation — political parasocial attachment.** In `ppsr_survey.csv`, mean-center parasocial intensity and wisdom, and regress credibility bias on their product plus the covariates (`covs`). Store the interaction coefficient as `b_int` and the simple slopes of parasocial intensity at low (−1 SD), average, and high (+1 SD) wisdom as `slopes`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    ppsr["psr_c"] = ppsr["parasocial"] - ppsr["parasocial"].mean()
                    ppsr["wis_c"] = ppsr["wisdom"] - ppsr["wisdom"].mean()
                    mod = smf.ols(f"credibility_bias ~ psr_c * wis_c + {covs}", data=ppsr).fit()
                    b_int = mod.params["psr_c:wis_c"]
                    sd_w = ppsr["wis_c"].std()
                    slopes = [mod.params["psr_c"] + b_int * w for w in (-sd_w, 0, sd_w)]
                    print(round(b_int, 3), mod.pvalues["psr_c:wis_c"], np.round(slopes, 3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    ppsr <- ppsr |> mutate(psr_c = parasocial - mean(parasocial), wis_c = wisdom - mean(wisdom))
                    mod <- lm(as.formula(paste("credibility_bias ~ psr_c * wis_c +", covs)), data = ppsr)
                    b_int <- coef(mod)[["psr_c:wis_c"]]
                    sd_w <- sd(ppsr$wis_c)
                    slopes <- coef(mod)[["psr_c"]] + b_int * c(-sd_w, 0, sd_w)
                    summary(mod)$coefficients["psr_c:wis_c", ]
                    round(slopes, 3)
                    """#
                ),
                answer: "The interaction is negative and significant: the attachment → credibility-bias slope is steepest among the least wise participants and close to flat among the wisest. Fitting the same model with polarization as the outcome and credibility bias as the predictor finds no such interaction.",
                selfCheck: SelfCheck(
                    names: "`b_int` and `slopes` (at −1 SD, the mean, and +1 SD of wisdom)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        cov_cols = ["ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        x = ref["parasocial"] - ref["parasocial"].mean()
                        w0 = ref["wisdom"] - ref["wisdom"].mean()
                        sd_w = w0.std()

                        def fit(w):
                            X = np.column_stack([np.ones(len(ref)), x, w, x * w, ref[cov_cols], (ref["stream"] == "university").astype(float)])
                            return np.linalg.lstsq(X, ref["credibility_bias"].to_numpy(), rcond=None)[0]

                        check("Interaction coefficient", b_int, fit(w0)[3], tol=0.001)
                        # Re-centering wisdom at each value makes the parasocial coefficient that simple slope
                        expected = [fit(w0 - w)[1] for w in (-sd_w, 0, sd_w)]
                        check("Simple slopes at low, average, and high wisdom", slopes, expected, tol=0.001)
                        check("Steepest at low wisdom", bool(slopes[0] > slopes[2]), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      x <- ref$parasocial - mean(ref$parasocial)
                      w0 <- ref$wisdom - mean(ref$wisdom)
                      covm <- cbind(as.matrix(ref[c("ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education")]),
                                    ref$stream == "university")
                      fit <- function(w) qr.coef(qr(cbind(1, x, w, x * w, covm)), ref$credibility_bias)
                      check("Interaction coefficient", b_int, fit(w0)[4], tol = 0.001)
                      # Re-centering wisdom at each value makes the parasocial coefficient that simple slope
                      expected <- sapply(c(-sd(w0), 0, sd(w0)), function(w) fit(w0 - w)[2])
                      check("Simple slopes at low, average, and high wisdom", slopes, expected, tol = 0.001)
                      check("Steepest at low wisdom", slopes[1] > slopes[3], TRUE)
                    })
                    """#
                )
            ),
        ],
        "mediation": [
            Exercise(
                title: "Practice simulation: an indirect effect",
                prompt: "**Practice simulation — political parasocial attachment.** In `ppsr_survey.csv`, does credibility bias carry part of the link between parasocial attachment and affective polarization? Estimate the a path (parasocial → credibility bias), the b path (credibility bias → polarization, holding parasocial intensity constant), and the indirect effect a × b, all with the covariates (`covs`). Bootstrap a 95% percentile CI for a × b with 2,000 resamples. Store `a`, `b`, `ab`, and `boot_ci`.",
                hint: "Write a function that takes a data frame and returns a and b, then call it on resampled rows.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    def paths(d):
                        a = smf.ols(f"credibility_bias ~ parasocial + {covs}", data=d).fit().params["parasocial"]
                        b = smf.ols(f"affective_polarization ~ credibility_bias + parasocial + {covs}",
                                    data=d).fit().params["credibility_bias"]
                        return a, b

                    a, b = paths(ppsr)
                    ab = a * b
                    rng = np.random.default_rng(1)
                    boots = [np.prod(paths(ppsr.sample(len(ppsr), replace=True, random_state=rng))) for _ in range(2000)]
                    boot_ci = np.percentile(boots, [2.5, 97.5])
                    print(round(a, 3), round(b, 3), round(ab, 3), boot_ci.round(3))
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    paths <- function(d) {
                      a <- coef(lm(as.formula(paste("credibility_bias ~ parasocial +", covs)), data = d))[["parasocial"]]
                      b <- coef(lm(as.formula(paste("affective_polarization ~ credibility_bias + parasocial +", covs)),
                                   data = d))[["credibility_bias"]]
                      c(a = a, b = b)
                    }
                    est <- paths(ppsr)
                    a <- est[["a"]]; b <- est[["b"]]; ab <- a * b
                    set.seed(1)
                    boots <- replicate(2000, prod(paths(ppsr[sample(nrow(ppsr), replace = TRUE), ])))
                    boot_ci <- quantile(boots, c(0.025, 0.975))
                    round(c(a = a, b = b, ab = ab, boot_ci), 3)
                    """#
                ),
                answer: "The indirect effect is positive with a bootstrap CI that excludes 0, and parasocial intensity keeps a direct effect on polarization — partial mediation. Remember that cross-sectional data make this a pattern consistent with the causal story, not proof of it.",
                selfCheck: SelfCheck(
                    names: "`a`, `b`, `ab`, and `boot_ci` (as [lower, upper])",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.api as sm
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        cov_cols = ["ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        C = np.column_stack([ref[cov_cols], (ref["stream"] == "university").astype(float)])
                        fa = sm.OLS(ref["credibility_bias"], sm.add_constant(np.column_stack([ref["parasocial"], C]))).fit()
                        fb = sm.OLS(ref["affective_polarization"],
                                    sm.add_constant(np.column_stack([ref["credibility_bias"], ref["parasocial"], C]))).fit()
                        a_ref, b_ref = fa.params.iloc[1], fb.params.iloc[1]
                        check("Path a", a, a_ref, tol=0.001)
                        check("Path b (holding parasocial intensity constant)", b, b_ref, tol=0.001,
                              hint="Put parasocial intensity in the polarization model too.")
                        check("Indirect effect a × b", ab, a_ref * b_ref, tol=0.001)
                        # Benchmark the bootstrap CI against the normal-theory (Sobel) interval
                        se_ab = np.sqrt(a_ref ** 2 * fb.bse.iloc[1] ** 2 + b_ref ** 2 * fa.bse.iloc[1] ** 2)
                        check("Bootstrap CI is close to the normal-theory benchmark", boot_ci,
                              a_ref * b_ref + np.array([-1.96, 1.96]) * se_ab, tol=0.03)
                        check("The CI excludes 0", bool(boot_ci[0] > 0), True)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      ref$university <- as.integer(ref$stream == "university")
                      cv <- "ideology_econ + ideology_social + political_interest + charisma + age + education + university"
                      fa <- coef(summary(lm(as.formula(paste("credibility_bias ~ parasocial +", cv)), data = ref)))["parasocial", ]
                      fb <- coef(summary(lm(as.formula(paste("affective_polarization ~ credibility_bias + parasocial +", cv)),
                                            data = ref)))["credibility_bias", ]
                      check("Path a", a, fa[[1]], tol = 0.001)
                      check("Path b (holding parasocial intensity constant)", b, fb[[1]], tol = 0.001,
                            hint = "Put parasocial intensity in the polarization model too.")
                      check("Indirect effect a × b", ab, fa[[1]] * fb[[1]], tol = 0.001)
                      # Benchmark the bootstrap CI against the normal-theory (Sobel) interval
                      se_ab <- sqrt(fa[[1]]^2 * fb[[2]]^2 + fb[[1]]^2 * fa[[2]]^2)
                      check("Bootstrap CI is close to the normal-theory benchmark", boot_ci,
                            fa[[1]] * fb[[1]] + c(-1.96, 1.96) * se_ab, tol = 0.03)
                      check("The CI excludes 0", boot_ci[[1]] > 0, TRUE)
                    })
                    """#
                )
            ),
        ],
        "sample-planning": [
            Exercise(
                title: "Practice simulation: an interim look",
                prompt: "**Practice simulation — political parasocial attachment.** The analysis plan for `ppsr_survey.csv` looks at the data once, at N = 220, and stops for efficacy if the wisdom × parasocial interaction on credibility bias has p < .009. Using participants 1–220, refit that moderation model (re-centering within the interim sample) and store the interim p-value as `p_interim` and whether to stop as `stop`. Then look at who those 220 people are.",
                hint: "Re-center within the interim sample. Then check `stream` for participants 1–220.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    ppsr = pd.read_csv("ppsr_survey.csv")
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs = "ideology_econ + ideology_social + political_interest + charisma + age + education + C(stream)"

                    interim = ppsr[ppsr["participant"] <= 220].copy()
                    interim["psr_c"] = interim["parasocial"] - interim["parasocial"].mean()
                    interim["wis_c"] = interim["wisdom"] - interim["wisdom"].mean()
                    fit_220 = smf.ols(f"credibility_bias ~ psr_c * wis_c + {covs}", data=interim).fit()
                    p_interim = fit_220.pvalues["psr_c:wis_c"]
                    stop = bool(p_interim < 0.009)
                    print(round(p_interim, 4), "stop for efficacy" if stop else "continue to N = 375")
                    print(interim["stream"].value_counts())
                    """#,
                    r: #"""
                    library(tidyverse)

                    ppsr <- read_csv("ppsr_survey.csv", show_col_types = FALSE)
                    # Held constant in every model: ideology, political interest, perceived charisma, age, education, stream
                    covs <- "ideology_econ + ideology_social + political_interest + charisma + age + education + stream"

                    interim <- ppsr |> filter(participant <= 220) |>
                      mutate(psr_c = parasocial - mean(parasocial), wis_c = wisdom - mean(wisdom))
                    fit_220 <- lm(as.formula(paste("credibility_bias ~ psr_c * wis_c +", covs)), data = interim)
                    p_interim <- summary(fit_220)$coefficients["psr_c:wis_c", "Pr(>|t|)"]
                    stop <- p_interim < 0.009
                    c(p_interim = p_interim, stop = stop)
                    table(interim$stream)
                    """#
                ),
                answer: "The interim p-value is well above .009, so the stopping rule says continue to N = 375 — where the interaction is clearly significant. Note who the first 220 are: in this file, participants 1–150 are all university students. If one stream fills first in real recruitment, the interim sample isn't a miniature of the final one (younger, a narrower wisdom range), so plan to interleave the streams or check balance at the interim look.",
                selfCheck: SelfCheck(
                    names: "`p_interim` and `stop` (True/False)",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_survey.csv")
                        ref = ref[ref["participant"] <= 220]
                        cov_cols = ["ideology_econ", "ideology_social", "political_interest", "charisma", "age", "education"]
                        x = ref["parasocial"] - ref["parasocial"].mean()
                        w = ref["wisdom"] - ref["wisdom"].mean()
                        X = np.column_stack([np.ones(len(ref)), x, w, x * w, ref[cov_cols], (ref["stream"] == "university").astype(float)])
                        y = ref["credibility_bias"].to_numpy()
                        b, *_ = np.linalg.lstsq(X, y, rcond=None)
                        df = len(y) - X.shape[1]
                        sigma2 = ((y - X @ b) ** 2).sum() / df
                        se = np.sqrt(sigma2 * np.linalg.inv(X.T @ X)[3, 3])
                        p_ref = 2 * stats.t.sf(abs(b[3] / se), df)
                        check("Interim p-value for the interaction", p_interim, p_ref, tol=0.002,
                              hint="Use participants 1–220 only, and re-center within that subsample.")
                        check("Stopping decision (p < .009)", bool(stop), bool(p_ref < 0.009))

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_survey.csv")
                      ref <- ref[ref$participant <= 220, ]
                      x <- ref$parasocial - mean(ref$parasocial); w <- ref$wisdom - mean(ref$wisdom)
                      X <- cbind(1, x, w, x * w, as.matrix(ref[c("ideology_econ", "ideology_social", "political_interest", "charisma",
                                                                 "age", "education")]), ref$stream == "university")
                      y <- ref$credibility_bias
                      b <- qr.coef(qr(X), y)
                      df <- length(y) - ncol(X)
                      se <- sqrt(sum((y - X %*% b)^2) / df * solve(crossprod(X))[4, 4])
                      p_ref <- 2 * pt(-abs(b[4] / se), df)
                      check("Interim p-value for the interaction", p_interim, p_ref, tol = 0.002,
                            hint = "Use participants 1–220 only, and re-center within that subsample.")
                      check("Stopping decision (p < .009)", as.logical(stop), p_ref < 0.009)
                    })
                    """#
                )
            ),
            Exercise(
                title: "Practice simulation: check a power claim",
                prompt: "**Practice simulation — political parasocial attachment.** The design for `ppsr_experiment.csv` claims power of .84 for d = 0.36 with N = 137 (about 46 per arm). Compute the one-tailed power for one pairwise comparison (a) ignoring the baseline (`power_raw`) and (b) with ANCOVA (`power_adjusted`), where the effective d is 0.36 / √(1 − r²) and r is the correlation between `pre_prism` and `post_prism`. What pre–post correlation would .84 power require (`r_needed`)?",
                hint: "Use statsmodels' TTestIndPower or R's pwr.t.test with nobs = 137 / 3 and a one-sided alternative.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    experiment = pd.read_csv("ppsr_experiment.csv")

                    from statsmodels.stats.power import TTestIndPower

                    analysis = TTestIndPower()
                    n_arm = 137 / 3
                    power_raw = analysis.power(effect_size=0.36, nobs1=n_arm, alpha=0.05, alternative="larger")
                    r = experiment["pre_prism"].corr(experiment["post_prism"])
                    power_adjusted = analysis.power(effect_size=0.36 / np.sqrt(1 - r ** 2), nobs1=n_arm,
                                                    alpha=0.05, alternative="larger")
                    d_needed = analysis.solve_power(nobs1=n_arm, alpha=0.05, power=0.84, alternative="larger")
                    r_needed = np.sqrt(1 - (0.36 / d_needed) ** 2)
                    print(round(power_raw, 2), round(r, 2), round(power_adjusted, 2), round(r_needed, 2))
                    """#,
                    r: #"""
                    library(tidyverse)

                    experiment <- read_csv("ppsr_experiment.csv", show_col_types = FALSE)

                    library(pwr)
                    n_arm <- 137 / 3
                    power_raw <- pwr.t.test(n = n_arm, d = 0.36, sig.level = 0.05, alternative = "greater")$power
                    r <- cor(experiment$pre_prism, experiment$post_prism)
                    power_adjusted <- pwr.t.test(n = n_arm, d = 0.36 / sqrt(1 - r^2), sig.level = 0.05,
                                                 alternative = "greater")$power
                    d_needed <- pwr.t.test(n = n_arm, power = 0.84, sig.level = 0.05, alternative = "greater")$d
                    r_needed <- sqrt(1 - (0.36 / d_needed)^2)
                    round(c(power_raw, r, power_adjusted, r_needed), 2)
                    """#
                ),
                answer: "Ignoring the baseline, power for d = 0.36 with ~46 per arm is only about .5 even one-tailed. ANCOVA changes the picture: with the pre–post correlation in this dataset (about .67–.69), power rises to roughly .75. Reaching .84 needs r ≈ .76. So the stated power is plausible only if the analysis adjusts for baseline, the test is one-tailed, and the pre–post correlation is that high — worth stating explicitly in a preregistration.",
                selfCheck: SelfCheck(
                    names: "`power_raw`, `power_adjusted`, and `r_needed`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats, optimize
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        n = 137 / 3
                        df = 2 * n - 2
                        crit = stats.t.ppf(0.95, df)

                        def power(d):        # one-tailed two-sample t-test via the noncentral t distribution
                            return stats.nct.sf(crit, df, d * np.sqrt(n / 2))

                        r = pd.read_csv("ppsr_experiment.csv")[["pre_prism", "post_prism"]].corr().iloc[0, 1]
                        check("Power, ignoring the baseline", power_raw, power(0.36), tol=0.005)
                        check("Power with ANCOVA", power_adjusted, power(0.36 / np.sqrt(1 - r ** 2)), tol=0.005,
                              hint="Effective d = 0.36 / √(1 − r²), with r the pre–post correlation.")
                        d_needed = optimize.brentq(lambda d: power(d) - 0.84, 0.01, 3)
                        check("Pre–post r needed for .84 power", r_needed, np.sqrt(1 - (0.36 / d_needed) ** 2), tol=0.005)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      n <- 137 / 3; df <- 2 * n - 2; crit <- qt(0.95, df)
                      power <- function(d) pt(crit, df, ncp = d * sqrt(n / 2), lower.tail = FALSE)   # noncentral t
                      ref <- read.csv("ppsr_experiment.csv")
                      r <- cor(ref$pre_prism, ref$post_prism)
                      check("Power, ignoring the baseline", power_raw, power(0.36), tol = 0.005)
                      check("Power with ANCOVA", power_adjusted, power(0.36 / sqrt(1 - r^2)), tol = 0.005,
                            hint = "Effective d = 0.36 / √(1 − r²), with r the pre–post correlation.")
                      d_needed <- uniroot(function(d) power(d) - 0.84, c(0.01, 3))$root
                      check("Pre–post r needed for .84 power", r_needed, sqrt(1 - (0.36 / d_needed)^2), tol = 0.005)
                    })
                    """#
                )
            ),
        ],
        "ancova": [
            Exercise(
                title: "Practice simulation: a three-arm intervention",
                prompt: "**Practice simulation — political parasocial attachment.** `ppsr_experiment.csv` randomizes 137 people to write from the standpoint of a wise person they nominate, of their political figure, or of an impartial observer (`arm`: wise, parasocial, observer). Regress post-intervention attachment (`post_prism`) on arm, adjusting for `pre_prism`, `pre_ap`, `wisdom`, `stream`, and `issue`. Fit it with the observer arm as the reference and again with the parasocial arm as the reference, and store each wise-arm coefficient with its **one-tailed** p-value for the preregistered direction (wise lower): `b_h1`, `p_h1` (vs. observer) and `b_h2`, `p_h2` (vs. parasocial).",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    import statsmodels.formula.api as smf
                    from scipy import stats

                    experiment = pd.read_csv("ppsr_experiment.csv")

                    covs3 = "pre_prism + pre_ap + wisdom + C(stream) + C(issue)"

                    def wise_effect(reference):
                        fit = smf.ols(f"post_prism ~ C(arm, Treatment('{reference}')) + {covs3}", data=experiment).fit()
                        name = f"C(arm, Treatment('{reference}'))[T.wise]"
                        b, t = fit.params[name], fit.tvalues[name]
                        return b, stats.t.cdf(t, fit.df_resid)        # one-tailed: H₁ says the wise arm is lower

                    b_h1, p_h1 = wise_effect("observer")
                    b_h2, p_h2 = wise_effect("parasocial")
                    print(round(b_h1, 3), round(p_h1, 4), round(b_h2, 3), round(p_h2, 4))
                    """#,
                    r: #"""
                    library(tidyverse)

                    experiment <- read_csv("ppsr_experiment.csv", show_col_types = FALSE)

                    wise_effect <- function(reference) {
                      d <- experiment |> mutate(arm = relevel(factor(arm), ref = reference))
                      fit <- lm(post_prism ~ arm + pre_prism + pre_ap + wisdom + stream + issue, data = d)
                      row <- coef(summary(fit))["armwise", ]
                      c(b = row[["Estimate"]], p = pt(row[["t value"]], fit$df.residual))   # one-tailed: wise lower
                    }
                    h1 <- wise_effect("observer");   b_h1 <- h1[["b"]]; p_h1 <- h1[["p"]]
                    h2 <- wise_effect("parasocial"); b_h2 <- h2[["b"]]; p_h2 <- h2[["p"]]
                    round(c(b_h1, p_h1, b_h2, p_h2), 4)
                    """#
                ),
                answer: "Both wise coefficients are negative: lower post-intervention attachment than the observer control and than the parasocial arm, with the wise vs. parasocial contrast the largest. One-tailed p-values are legitimate here only because the direction was preregistered.",
                selfCheck: SelfCheck(
                    names: "`b_h1`, `p_h1`, `b_h2`, and `p_h2`",
                    python: #"""
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("ppsr_experiment.csv")
                        issues = pd.get_dummies(ref["issue"], drop_first=True).astype(float)
                        base = np.column_stack([ref[["pre_prism", "pre_ap", "wisdom"]], (ref["stream"] == "university").astype(float), issues])
                        y = ref["post_prism"].to_numpy()

                        def one_tailed(reference):
                            others = [a for a in ["wise", "parasocial", "observer"] if a != reference]
                            X = np.column_stack([np.ones(len(ref))] + [(ref["arm"] == a).astype(float) for a in others] + [base])
                            b, *_ = np.linalg.lstsq(X, y, rcond=None)
                            df = len(y) - X.shape[1]
                            se = np.sqrt(((y - X @ b) ** 2).sum() / df * np.linalg.inv(X.T @ X)[1, 1])
                            return b[1], stats.t.cdf(b[1] / se, df)       # column 1 is the wise arm

                        e1, e2 = one_tailed("observer"), one_tailed("parasocial")
                        check("Wise vs. observer coefficient", b_h1, e1[0], tol=0.001)
                        check("Wise vs. observer: one-tailed p", p_h1, e1[1], tol=0.001, hint="One-tailed in the preregistered direction: P(T ≤ t).")
                        check("Wise vs. parasocial coefficient", b_h2, e2[0], tol=0.001)
                        check("Wise vs. parasocial: one-tailed p", p_h2, e2[1], tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("ppsr_experiment.csv")
                      base <- cbind(as.matrix(ref[c("pre_prism", "pre_ap", "wisdom")]), ref$stream == "university",
                                    model.matrix(~ issue, ref)[, -1])
                      one_tailed <- function(reference) {
                        others <- setdiff(c("wise", "parasocial", "observer"), reference)
                        X <- cbind(1, sapply(others, function(a) ref$arm == a), base)
                        b <- qr.coef(qr(X), ref$post_prism)
                        df <- nrow(X) - ncol(X)
                        se <- sqrt(sum((ref$post_prism - X %*% b)^2) / df * solve(crossprod(X))[2, 2])
                        c(b[2], pt(b[2] / se, df))                        # column 2 is the wise arm
                      }
                      e1 <- one_tailed("observer"); e2 <- one_tailed("parasocial")
                      check("Wise vs. observer coefficient", b_h1, e1[1], tol = 0.001)
                      check("Wise vs. observer: one-tailed p", p_h1, e1[2], tol = 0.001, hint = "One-tailed in the preregistered direction: P(T ≤ t).")
                      check("Wise vs. parasocial coefficient", b_h2, e2[1], tol = 0.001)
                      check("Wise vs. parasocial: one-tailed p", p_h2, e2[2], tol = 0.001)
                    })
                    """#
                )
            ),
        ],
        "keyness": [
            Exercise(
                title: "Practice simulation: everyday questions vs. survey-style items",
                prompt: "**Practice simulation — chatbots and political court cases.** `llm_coding.csv` holds the speech acts participants typed, and `llm_instrument_coding.csv` holds 60 instrument-style items of the kind used in survey-based bias research, coded with the same codebook. Compare the wording of their `speech_act_text` with weighted log-odds and an informative Dirichlet prior (the pooled counts as the prior, as in this lesson), tokenizing with `[a-z']+` after lowercasing. Store the 10 words most distinctive of everyday speech acts (largest z) as `top_everyday`. What do the most instrument-like words tell you?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    import re

                    import numpy as np
                    import pandas as pd
                    from scipy import stats

                    from collections import Counter

                    everyday = pd.read_csv("llm_coding.csv", keep_default_na=False)
                    instrument = pd.read_csv("llm_instrument_coding.csv", keep_default_na=False)

                    def tokens(text):
                        return re.findall(r"[a-z']+", text.lower())

                    counts = pd.DataFrame({
                        "a": Counter(w for t in everyday["speech_act_text"] for w in tokens(t)),
                        "b": Counter(w for t in instrument["speech_act_text"] for w in tokens(t)),
                    }).fillna(0)
                    prior = counts["a"] + counts["b"]
                    a0, n_a, n_b = prior.sum(), counts["a"].sum(), counts["b"].sum()
                    delta = (np.log((counts["a"] + prior) / (n_a + a0 - counts["a"] - prior))
                             - np.log((counts["b"] + prior) / (n_b + a0 - counts["b"] - prior)))
                    counts["z"] = delta / np.sqrt(1 / (counts["a"] + prior) + 1 / (counts["b"] + prior))

                    ranked = counts.sort_values("z", ascending=False)
                    top_everyday = ranked.index[:10].tolist()
                    print("everyday:", top_everyday)
                    print("instrument:", ranked.index[::-1][:10].tolist())
                    """#,
                    r: #"""
                    library(tidyverse)

                    library(tidytext)

                    everyday <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)
                    instrument <- read_csv("llm_instrument_coding.csv", trim_ws = FALSE, show_col_types = FALSE)
                    counts <- bind_rows(everyday = everyday, instrument = instrument, .id = "source") |>
                      mutate(text = str_to_lower(speech_act_text)) |>
                      unnest_tokens(word, text, token = "regex", pattern = "[^a-z']+") |>
                      count(source, word) |>
                      pivot_wider(names_from = source, values_from = n, values_fill = 0) |>
                      rename(a = everyday, b = instrument) |>
                      mutate(prior = a + b,
                             delta = log((a + prior) / (sum(a) + sum(prior) - a - prior)) -
                                     log((b + prior) / (sum(b) + sum(prior) - b - prior)),
                             z = delta / sqrt(1 / (a + prior) + 1 / (b + prior))) |>
                      arrange(desc(z))
                    top_everyday <- head(counts$word, 10)
                    top_everyday
                    tail(counts$word, 10)   # most instrument-like
                    """#
                ),
                answer: "Everyday requests are marked by conversational words — question words (*what*, *why*), deixis (*that*, *about*, *this*), first person (*i*, *im*, *me*), and the conventionally indirect *can* — plus the set-up people add before a request (“im pretty conservative but …”). Instrument items are marked by response-format language (*respond*, *only*, *statement*, *correct*, *disagree*, *extent*). The two registers differ in **how** they ask, not only in what they ask about: instruments constrain the answer, while everyday questions carry context a chatbot can accommodate to.",
                selfCheck: SelfCheck(
                    names: "`top_everyday` (a list or vector of 10 words)",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        from collections import Counter
                        ev = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        ins = pd.read_csv("llm_instrument_coding.csv", keep_default_na=False)
                        tok = lambda t: re.findall(r"[a-z']+", t.lower())
                        a = Counter(w for t in ev["speech_act_text"] for w in tok(t))
                        b = Counter(w for t in ins["speech_act_text"] for w in tok(t))
                        words = sorted(set(a) | set(b))
                        ya, yb = np.array([a[w] for w in words], float), np.array([b[w] for w in words], float)
                        prior = ya + yb
                        delta = (np.log((ya + prior) / (ya.sum() + prior.sum() - ya - prior))
                                 - np.log((yb + prior) / (yb.sum() + prior.sum() - yb - prior)))
                        z = delta / np.sqrt(1 / (ya + prior) + 1 / (yb + prior))
                        expected = {words[i] for i in np.argsort(-z)[:10]}
                        check("Ten words", len(set(top_everyday)), 10, tol=0)
                        check("Overlap with the reference top 10 (at least 8)", bool(len(set(top_everyday) & expected) >= 8), True,
                              hint="Tokenize with [a-z']+ after lowercasing; use the pooled counts as the prior.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ev <- read.csv("llm_coding.csv"); ins <- read.csv("llm_instrument_coding.csv")
                      tok <- function(x) unlist(regmatches(tolower(x), gregexpr("[a-z']+", tolower(x))))
                      a <- table(tok(ev$speech_act_text)); b <- table(tok(ins$speech_act_text))
                      words <- union(names(a), names(b))
                      ya <- as.numeric(ifelse(is.na(a[words]), 0, a[words])); yb <- as.numeric(ifelse(is.na(b[words]), 0, b[words]))
                      prior <- ya + yb
                      delta <- log((ya + prior) / (sum(ya) + sum(prior) - ya - prior)) - log((yb + prior) / (sum(yb) + sum(prior) - yb - prior))
                      z <- delta / sqrt(1 / (ya + prior) + 1 / (yb + prior))
                      expected <- words[order(-z)][1:10]
                      check("Ten words", length(unique(top_everyday)), 10, tol = 0)
                      check("Overlap with the reference top 10 (at least 8)", length(intersect(top_everyday, expected)) >= 8, TRUE,
                            hint = "Tokenize with [a-z']+ after lowercasing; use the pooled counts as the prior.")
                    })
                    """#
                )
            ),
        ],
    ]

    // MARK: - Dictionaries & topic models

    static let topicModels = Lesson(
        id: "topic-models",
        title: "Dictionaries & topic models",
        summary: "Rule-based features, building a lexicon, and finding types of text with LDA — checked against hand coding.",
        minutes: 30,
        blocks: [
            .text("Text can be analysed at three levels. **Form** is what a rule can find: pronouns, hedges, question words. **Meaning** is what words signal — evaluative or partisan-coded terms, usually found with a **dictionary** (a list of words or phrases). **Use** is what a piece of text *does* — asking for a summary, an opinion, or advice — which normally takes a human coder. Automated methods are fast and perfectly consistent, but each measures its own rule, so it has to be checked against hand coding before it's trusted."),
            .text("A **topic model** goes further: with no labels at all, it groups words that tend to appear together. **Latent Dirichlet allocation** (LDA; Blei, Ng & Jordan, 2003) treats each document as a mixture of topics and each topic as a distribution over words. It's a useful way to *propose* categories for a codebook — and a poor substitute for defining them."),
            .terms([
                Term("Automated feature", "A feature counted by a rule (a regular expression or word list) rather than a coder. Report how often it agrees with hand coding."),
                Term("Dictionary (lexicon)", "A predefined list of words or phrases, each tied to a category. It finds only what's on the list, so it must be built for the material and validated."),
                Term("Topic", "In LDA, a probability distribution over the vocabulary; read it through its highest-probability words."),
                Term("Document–topic proportions", "Each document's estimated mix of topics; its most probable topic is a convenient (but lossy) label."),
                Term("Structural topic model (STM)", "A topic model whose topic prevalence can depend on document covariates, such as the author's group (Roberts et al., 2014); the `stm` package in R."),
            ]),
            .text("The examples use the **chatbot conversations practice simulation** (see *Practice datasets*): the consensus coding sheet, `llm_coding.csv`, in which every query that 32 people typed to a chatbot about a court case is split into speech acts and hand-coded (one row per act; the act's words are in `speech_act_text`)."),
            .code(CodeSample(
                caption: "Load the consensus coding sheet",
                python: #"""
                import re

                import numpy as np
                import pandas as pd
                from scipy import stats

                sessions = pd.read_csv("llm_sessions.csv")
                coding = pd.read_csv("llm_coding.csv", keep_default_na=False)
                # Coders work blind to case attributes; the headline is joined on only for analysis
                acts = coding.merge(sessions[["participant", "headline"]], on="participant")
                acts["text"] = acts["speech_act_text"]
                print(len(acts), "speech acts")
                print(acts[["speech_act_id", "text", "primary_act"]].head(8).to_string(index=False))
                """#,
                r: #"""
                library(tidyverse)
                library(tidytext)

                sessions <- read_csv("llm_sessions.csv", show_col_types = FALSE)
                coding <- read_csv("llm_coding.csv", trim_ws = FALSE, show_col_types = FALSE)   # keep text exactly as typed
                # Coders work blind to case attributes; the headline is joined on only for analysis
                acts <- coding |> left_join(select(sessions, participant, headline), by = "participant") |> mutate(text = speech_act_text)

                # Lowercase first, then split on anything that isn't a letter or apostrophe (what's, i'm)
                tokenize <- function(df) {
                  df |> mutate(text = str_to_lower(text)) |> unnest_tokens(word, text, token = "regex", pattern = "[^a-z']+")
                }
                nrow(acts)
                acts |> select(speech_act_id, text, primary_act) |> head(8)
                """#
            )),
            .exercise(Exercise(
                title: "Practice simulation: Form vs. use: first person isn't stance disclosure",
                prompt: "Flag every speech act that contains a first-person singular pronoun (*i*, *im*, *i'm*, *me*, *my*, *id*, *i'd* as whole words, after lowercasing) and store the flags as `fp_flag` (0/1, in row order). Among the flagged acts, what share did coders mark as disclosing the asker's political stance (`stance_disclosure` = Y)? Store it as `share_disclosing`.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    pattern = r"\b(?:i|im|i'm|me|my|id|i'd)\b"
                    fp_flag = acts["text"].str.lower().str.contains(pattern).astype(int)
                    share_disclosing = (acts.loc[fp_flag == 1, "stance_disclosure"] == "Y").mean()
                    print(fp_flag.mean().round(3), round(share_disclosing, 3))
                    print(acts.loc[(fp_flag == 1) & (acts["stance_disclosure"] == "N"), "text"].head(8).tolist())
                    """#,
                    r: #"""
                    fp_flag <- as.integer(str_detect(str_to_lower(acts$text), "\\b(i|im|i'm|me|my|id|i'd)\\b"))
                    share_disclosing <- mean(acts$stance_disclosure[fp_flag == 1] == "Y")
                    c(mean(fp_flag), share_disclosing)
                    head(acts$text[fp_flag == 1 & acts$stance_disclosure == "N"], 8)
                    """#
                ),
                answer: "Only a minority of first-person requests disclose a stance. Most are things like “should i sign the petition”, “im curious why the judge decided that”, or a hedge (“i guess”): the asker talks about themselves without saying where they stand politically. A first-person pronoun is a **form** feature a script can count; stance disclosure is a **use** (pragmatic) judgment that needs a coder — which is why the coding sheet keeps them in separate columns, and why automated features are spot-checked rather than trusted.",
                selfCheck: SelfCheck(
                    names: "`fp_flag` (0/1 for each act, in row order) and `share_disclosing`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        pronouns = {"i", "im", "i'm", "me", "my", "id", "i'd"}
                        expected = np.array([int(bool(pronouns & set(re.findall(r"[a-z']+", t.lower())))) for t in ref["speech_act_text"]])
                        check("First-person flags", np.asarray(fp_flag, dtype=float), expected, tol=0, hint="Match whole words only, after lowercasing.")
                        check("Share disclosing a stance", share_disclosing, (ref["stance_disclosure"][expected == 1] == "Y").mean(), tol=0.001)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_coding.csv")
                      words <- regmatches(tolower(ref$speech_act_text), gregexpr("[a-z']+", tolower(ref$speech_act_text)))
                      expected <- as.integer(sapply(words, function(w) any(w %in% c("i", "im", "i'm", "me", "my", "id", "i'd"))))
                      check("First-person flags", as.numeric(fp_flag), expected, tol = 0, hint = "Match whole words only, after lowercasing.")
                      check("Share disclosing a stance", share_disclosing, mean(ref$stance_disclosure[expected == 1] == "Y"), tol = 0.001)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Practice simulation: Meaning: build the partisan lexicon",
                prompt: "While coding, coders listed candidate partisan-coded terms in the `partisan_terms` column; the team turns that list into a lexicon before freezing the codebook. Build the lexicon as the sorted list of distinct terms (`lexicon`). Apply it back to every act — flag acts whose lowercased text contains any lexicon term — and store the proportion of acts where your flag agrees with whether the coders found a **partisan** presupposition (`presup_direction` = Left or Right) as `agree_dict`. Then count the acts that mention a party (*democrats*, *republicans*, *the liberals*, *the conservatives*) as `n_party`. The team's decision log says a party name on its own is never a partisan-coded term — only loaded terms one side uses: what would adding party names to the lexicon have done?",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    lexicon = sorted(t for t in acts["partisan_terms"].unique() if t)
                    lower = acts["text"].str.lower()
                    dict_flag = lower.apply(lambda text: any(term in text for term in lexicon))
                    agree_dict = (dict_flag == acts["presup_direction"].isin(["Left", "Right"])).mean()
                    n_party = int(lower.str.contains(r"democrats|republicans|the liberals|the conservatives").sum())
                    print(lexicon); print(round(agree_dict, 3), n_party)
                    print(acts.loc[lower.str.contains("republicans|conservatives|democrats|liberals"), ["text", "presup", "target"]].head())
                    """#,
                    r: #"""
                    lexicon <- sort(unique(na.omit(acts$partisan_terms)))
                    lower <- str_to_lower(acts$text)
                    dict_flag <- sapply(lower, function(text) any(str_detect(text, fixed(lexicon))))
                    agree_dict <- mean(dict_flag == (acts$presup_direction %in% c("Left", "Right")))
                    n_party <- sum(str_detect(lower, "democrats|republicans|the liberals|the conservatives"))
                    lexicon; c(agree_dict, n_party)
                    acts |> filter(str_detect(lower, "democrats|republicans|liberals|conservatives")) |> select(text, presup, target) |> head()
                    """#
                ),
                answer: "The lexicon has at most one left- and one right-coded term per court case — up to twelve, though not every term turned up in these conversations — and flagging acts with it matches the coders' partisan presuppositions perfectly here, because the terms only ever appeared inside presupposed framings. (Comparing with `presup` = Y instead would look worse, and wrongly so: a *why*-question presupposes something too, just nothing political.) Real lexicons are leakier: the same term can be quoted, used ironically, or appear in a neutral request, so a dictionary is a first pass that coders confirm. The party mentions show why the decision-log rule matters: a party name is never what makes an act partisan. Some of those acts also contain a lexicon term, but none of the ones that only mention a party has a partisan presupposition — adding party names to the lexicon would have flagged them falsely, inflating how often askers seem to push a political framing.",
                selfCheck: SelfCheck(
                    names: "`lexicon` (sorted list of terms), `agree_dict`, and `n_party`",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False)
                        lex = sorted(set(ref["partisan_terms"]) - {""})
                        low = ref["speech_act_text"].str.lower()
                        flag = np.array([any(w in t for w in lex) for t in low])
                        check("Lexicon", list(lexicon), lex, hint="Use the distinct non-empty values of partisan_terms.")
                        check("Agreement with partisan presupposition codes", agree_dict, (flag == ref["presup_direction"].isin(["Left", "Right"]).to_numpy()).mean(), tol=0.001,
                              hint="Compare with presup_direction being Left or Right — a why-question presupposes too, but not politically.")
                        check("Acts mentioning a party", n_party, int(sum(any(p in t for p in ["democrats", "republicans", "the liberals", "the conservatives"]) for t in low)), tol=0)

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ref <- read.csv("llm_coding.csv")
                      lex <- sort(setdiff(unique(ref$partisan_terms), ""))
                      low <- tolower(ref$speech_act_text)
                      flag <- sapply(low, function(t) any(sapply(lex, function(w) grepl(w, t, fixed = TRUE))))
                      check("Lexicon", as.character(lexicon), lex, hint = "Use the distinct non-empty values of partisan_terms.")
                      check("Agreement with partisan presupposition codes", agree_dict, mean(flag == (ref$presup_direction %in% c("Left", "Right"))), tol = 0.001,
                            hint = "Compare with presup_direction being Left or Right — a why-question presupposes too, but not politically.")
                      check("Acts mentioning a party", n_party, sum(grepl("democrats|republicans|the liberals|the conservatives", low)), tol = 0)
                    })
                    """#
                )
            )),
            .exercise(Exercise(
                title: "Practice simulation: Find types: topic modelling the speech acts",
                prompt: "To build a query bank, real requests are grouped into types. Fit a 6-topic LDA to the speech acts twice: (a) removing only the stop words below, and (b) also removing the case vocabulary (the words that name the court cases). Use seed 1. For each fit, give every act its most probable topic and compute Cramér's V between topic and the hand-coded **speech act** (`primary_act`), and between topic and **headline**. Store the assignments as `topic_raw` and `topic_clean` (one per act, in row order). What are the topics capturing?\n\nStop words: the, a, an, of, in, on, about, with, to, and, this, that, it, for, i, im, i'm, my, me, is, you, also.\nCase vocabulary: pipeline, injunction, school, library, ruling, border, detention, case, transit, strike, clinic, buffer, zone, language, law, court.",
                hint: "Use a fixed seed (random_state = 1 in Python, seed = 1 in R); LDA's results depend on where it starts.",
                solution: CodeSample(
                    caption: "Solution",
                    python: #"""
                    from sklearn.decomposition import LatentDirichletAllocation
                    from sklearn.feature_extraction.text import CountVectorizer

                    stop = ["the", "a", "an", "of", "in", "on", "about", "with", "to", "and", "this", "that", "it", "for",
                            "i", "im", "i'm", "my", "me", "is", "you", "also"]
                    case_words = ["pipeline", "injunction", "school", "library", "ruling", "border", "detention", "case",
                                  "transit", "strike", "clinic", "buffer", "zone", "language", "law", "court"]

                    def fit_topics(stop_words, k=6, seed=1):
                        vectorizer = CountVectorizer(token_pattern=r"[a-z']+", stop_words=stop_words)
                        X = vectorizer.fit_transform(acts["text"].str.lower())
                        lda = LatentDirichletAllocation(n_components=k, random_state=seed, max_iter=100).fit(X)
                        vocab = vectorizer.get_feature_names_out()
                        for topic, weights in enumerate(lda.components_):
                            print(f"  topic {topic}:", " ".join(vocab[weights.argsort()[::-1][:7]]))
                        return lda.transform(X).argmax(axis=1)            # most probable topic per act

                    def cramers_v(a, b):
                        table = pd.crosstab(a, b)
                        chi2 = stats.chi2_contingency(table, correction=False)[0]
                        return np.sqrt(chi2 / (table.to_numpy().sum() * (min(table.shape) - 1)))

                    print("(a) stop words only"); topic_raw = fit_topics(stop)
                    print("(b) case vocabulary removed"); topic_clean = fit_topics(stop + case_words)
                    for name, topics in [("raw", topic_raw), ("clean", topic_clean)]:
                        print(name, "V(speech act) =", round(cramers_v(topics, acts["primary_act"]), 2),
                              " V(headline) =", round(cramers_v(topics, acts["headline"]), 2))
                    """#,
                    r: #"""
                    library(topicmodels)

                    stop <- c("the", "a", "an", "of", "in", "on", "about", "with", "to", "and", "this", "that", "it", "for",
                              "i", "im", "i'm", "my", "me", "is", "you", "also")
                    case_words <- c("pipeline", "injunction", "school", "library", "ruling", "border", "detention", "case",
                                    "transit", "strike", "clinic", "buffer", "zone", "language", "law", "court")

                    fit_topics <- function(stop_words, k = 6, seed = 1) {
                      dtm <- acts |> mutate(doc = row_number()) |> tokenize() |>
                        filter(!word %in% stop_words) |> count(doc, word) |> cast_dtm(doc, word, n)
                      lda <- LDA(dtm, k = k, control = list(seed = seed))
                      print(terms(lda, 7))
                      gamma <- posterior(lda)$topics                      # acts × topics
                      topic <- rep(NA_integer_, nrow(acts))               # an act left with no words stays NA
                      topic[as.integer(rownames(gamma))] <- apply(gamma, 1, which.max)
                      topic
                    }

                    cramers_v <- function(a, b) {
                      tab <- table(a, b)
                      chi2 <- suppressWarnings(chisq.test(tab, correct = FALSE))$statistic[[1]]
                      sqrt(chi2 / (sum(tab) * (min(dim(tab)) - 1)))
                    }

                    topic_raw <- fit_topics(stop)
                    topic_clean <- fit_topics(c(stop, case_words))
                    sapply(list(raw = topic_raw, clean = topic_clean), function(t)
                      c(speech_act = cramers_v(t, acts$primary_act), headline = cramers_v(t, acts$headline)))
                    """#
                ),
                answer: "In both fits the topics line up with speech acts more than with headlines (V with the speech act ≈ .4–.55, with the headline ≈ .15–.25): LDA picks up request formulas — *what happened*, *is it fair*, *should i*, *will it get appealed* — because those words co-occur. Removing the case vocabulary weakens the headline association further. But the match with the codebook is partial: some topics merge acts the codebook separates (fairness and opinion), others split on framing devices like hedges or presupposed terms. So a topic model *proposes* candidate types; the codebook defines them, with examples, and coders apply them. Results also shift with the seed and k — fit several and keep only types that recur. To ask whether topic prevalence differs by asker or source, a structural topic model (`stm` in R; Roberts et al., 2014) builds those covariates in.",
                selfCheck: SelfCheck(
                    names: "`topic_raw` and `topic_clean` (the most probable topic for each act, in row order)",
                    python: #"""
                    import re
                    import numpy as np
                    import pandas as pd
                    from scipy import stats
                    from selfcheck import check

                    def run_check():   # a function keeps these names from overwriting your variables
                        ses = pd.read_csv("llm_sessions.csv")
                        ref = pd.read_csv("llm_coding.csv", keep_default_na=False).merge(ses[["participant", "headline"]], on="participant")

                        def v(a, b):
                            obs = pd.crosstab(np.asarray(a), np.asarray(b)).to_numpy().astype(float)
                            exp = obs.sum(1, keepdims=True) * obs.sum(0) / obs.sum()
                            return np.sqrt(((obs - exp) ** 2 / exp).sum() / (obs.sum() * (min(obs.shape) - 1)))

                        check("One topic per act", [len(topic_raw), len(topic_clean)], [len(ref)] * 2, tol=0)
                        raw_a, raw_h = v(topic_raw, ref["primary_act"]), v(topic_raw, ref["headline"])
                        clean_a, clean_h = v(topic_clean, ref["primary_act"]), v(topic_clean, ref["headline"])
                        print(f"   your Vs — raw: act {raw_a:.2f}, headline {raw_h:.2f}; clean: act {clean_a:.2f}, headline {clean_h:.2f}")
                        check("Topics line up with speech acts (V ≥ .30 in both fits)", bool(raw_a >= 0.30 and clean_a >= 0.30), True,
                              hint="Use k = 6 and seed 1, and lowercase before tokenizing; assign each act its most probable topic.")
                        check("Topics follow speech acts more than headlines", bool(raw_a > raw_h and clean_a > clean_h), True)
                        check("Removing case words weakens the headline association", bool(clean_h < raw_h), True,
                              hint="Fit (b) removes the stop words and the case vocabulary.")

                    run_check()
                    """#,
                    r: #"""
                    source("selfcheck.R")

                    local({   # keeps these names from overwriting your variables
                      ses <- read.csv("llm_sessions.csv")
                      ref <- read.csv("llm_coding.csv")
                      ref$headline <- ses$headline[match(ref$participant, ses$participant)]
                      v <- function(a, b) {
                        keep <- !is.na(a)
                        obs <- unclass(table(a[keep], b[keep]))
                        exp <- outer(rowSums(obs), colSums(obs)) / sum(obs)
                        sqrt(sum((obs - exp)^2 / exp) / (sum(obs) * (min(dim(obs)) - 1)))
                      }
                      check("One topic per act", c(length(topic_raw), length(topic_clean)), rep(nrow(ref), 2), tol = 0)
                      raw_a <- v(topic_raw, ref$primary_act); raw_h <- v(topic_raw, ref$headline)
                      clean_a <- v(topic_clean, ref$primary_act); clean_h <- v(topic_clean, ref$headline)
                      cat(sprintf("   your Vs — raw: act %.2f, headline %.2f; clean: act %.2f, headline %.2f\n", raw_a, raw_h, clean_a, clean_h))
                      check("Topics line up with speech acts (V ≥ .30 in both fits)", raw_a >= 0.30 && clean_a >= 0.30, TRUE,
                            hint = "Use k = 6 and seed 1, and lowercase before tokenizing; assign each act its most probable topic.")
                      check("Topics follow speech acts more than headlines", raw_a > raw_h && clean_a > clean_h, TRUE)
                      check("Removing case words weakens the headline association", clean_h < raw_h, TRUE,
                            hint = "Fit (b) removes the stop words and the case vocabulary.")
                    })
                    """#
                )
            )),
            .caution("Topic models are exploratory", "There's no single right number of topics, and results change with the seed, the stop-word list, and preprocessing. Decide these in advance (or report how robust the types are across choices), and treat topics as suggestions for the codebook — the categories themselves should still be defined with examples and applied by coders, with agreement reported."),
        ],
        quiz: [
            Question(
                prompt: "A regex flags “should i sign the petition” as first-person. A coder marks it as not disclosing a stance. Who is wrong?",
                options: ["The regex", "The coder", "Neither: they measure different things", "Both"],
                answer: 2,
                explanation: "Person is a form feature; stance disclosure is a pragmatic judgment. Keep them as separate variables."
            ),
            Question(
                prompt: "Why should a party name on its own not go in a partisan-term lexicon?",
                options: ["Party names are too rare", "Mentioning a party doesn't by itself frame the issue from one side, so it would produce false positives", "Dictionaries can't handle names", "It would lower κ"],
                answer: 1,
                explanation: "A lexicon entry should signal the construct; neutral mentions would be flagged as partisan."
            ),
            Question(
                prompt: "An LDA fit gives six topics that roughly match six speech-act categories. The best next step is to…",
                options: ["Replace the codebook with the topics", "Report the topics as the speech-act categories", "Use them as candidate types, check them across seeds and k, and define them in the codebook", "Increase k until the match is perfect"],
                answer: 2,
                explanation: "Topic models propose; definitions and coding decide."
            ),
        ]
    )

    /// The beginner explanation for *Dictionaries & topic models*.
    static let explanationsSimulations: [String: [ExplanationSection]] = [
        "topic-models": [
            idea("Turning wording into data",
                 "The same texts can be analysed at three levels. **Form**: features a rule can find, like pronouns or hedges. **Meaning**: what the words signal, like partisan-coded terms. **Use**: what the text is doing, like asking for a summary or an opinion.",
                 "Rules and word lists are fast and perfectly consistent, but they measure *the rule*. Before relying on one, compare it with hand coding and read the disagreements.",
                 "A **topic model** goes further: with no labels at all, it groups words that tend to appear together. That makes it useful for proposing categories — but it finds whatever co-occurs most strongly, which may be the subject of the text rather than the kind of request."),
            analogy("Sorting a pile of letters",
                    "Ask someone to sort a pile of letters into six heaps without instructions, and they might sort by who each letter is addressed to. If you wanted heaps by *purpose* — complaints, thank-yous, requests — you'd first have to cover up the addresses. Removing the case vocabulary before topic modelling is covering up the addresses."),
            worked("Checking a dictionary against coders",
                   "A partisan-term lexicon flags 40 requests. Coders say 30 of those really presuppose a political framing, and they find 6 more that the lexicon missed.",
                   "**Precision** = 30 / 40 = .75: a quarter of the flags are false alarms. **Recall** = 30 / (30 + 6) ≈ .83: the lexicon finds most, but not all, of the framed requests.",
                   "Report both — a lexicon that flags everything has perfect recall and useless precision."),
            inWords("Reporting a topic model",
                    "“To propose query types, we fitted latent Dirichlet allocation models (k = 4–8, five seeds each) to the everyday speech acts after removing stop words and case-specific vocabulary. Six types recurred across specifications; two coders then defined and applied them, with κ ≥ .70 for each.”"),
        ],
    ]
}

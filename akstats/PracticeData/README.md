# Practice data

Every dataset used by the course's exercises — the same files the app's **Practice data** view offers for download.
They are made by the scripts in [`scripts/`](../../scripts) with fixed random seeds (these are the Python versions;
the R scripts make files with the same structure but different random numbers). Click a file to preview it as a table,
or open [`practice_data.xlsx`](practice_data.xlsx) for all of them in one workbook. All people, figures, and chatbots are simulated.

## Course datasets

Simulated datasets used by lessons from Unit 3 onward, each with built-in effects.

| File | Rows | Columns | What's in it |
|---|---|---|---|
| [`survey.csv`](survey.csv) | 375 | 15 | 375 respondents: `age`, `education` (1–5), `region` (urban / rural), 1–7 scale scores for `social_media`, `phone_checking`, `rumination`, `anxiety`, six 1–5 items `mind_1`–`mind_6` (3 and 5 reverse-worded), and a precomputed `mindfulness` score. |
| [`diary.csv`](diary.csv) | 1,400 | 5 | 100 people × 14 days: daily `work_hours` and `wellbeing` (1–7), plus each person's `conscientiousness` (1–5). |
| [`classroom.csv`](classroom.csv) | 150 | 5 | 150 students randomized to a `method` (lecture, active, flipped), with `pretest` and `posttest` scores (0–100) and their `school` (4 schools). |
| [`essays.csv`](essays.csv) | 120 | 4 | 120 essays scored 1–6 by `rater_a` and `rater_b`, plus `rater_a_retest` (the same rater, two weeks later). |
| [`stroop.csv`](stroop.csv) | 60 | 5 | 60 participants in a Stroop task, one row each: `age`, `attention_check` (pass / fail), and mean reaction times `rt_congruent` and `rt_incongruent` (ms). |
| [`stroop_trials.csv`](stroop_trials.csv) | 2,880 | 4 | The same task trial by trial: 60 participants × 24 color words (`item`) × 2 conditions, with each trial's `rt` in ms. |
| [`judgments.csv`](judgments.csv) | 1,280 | 6 | 40 participants × 32 sentences in a 2 × 2 design (`structure`: simple / complex × `distance`: short / long): an acceptability `rating` (1–7) and whether a comprehension question was answered `correct` (0/1). |
| [`commutes.csv`](commutes.csv) | 1,200 | 4 | 120 people × 10 weeks: commute `mode` (car, bus, bike, walk) and `distance_km`. |
| [`habits.csv`](habits.csv) | 500 | 9 | 500 students: six 0/1 study strategies (`reread`, `notes`, `selftest`, `spaced`, `explain`, `peers`), `gpa`, and the hidden `true_class`. |
| [`profiles.csv`](profiles.csv) | 400 | 8 | 400 people: four continuous scores (`wellbeing`, `stress`, `support`, `sleep`), `age`, `burnout`, and the hidden `true_profile`. |
| [`missing.csv`](missing.csv) | 500 | 6 | 500 people: `age`, `stress`, `sleep`, and `wellbeing` with about a quarter missing, plus the hidden `wellbeing_true`. |
| [`fillers.csv`](fillers.csv) | 300 | 6 | 300 interviews: filler-word counts (`fillers`), interview length in `minutes`, `condition` (relaxed / evaluated), second-language speaker `l2` (0/1), and `age`. |
| [`poll.csv`](poll.csv) | 1,000 | 7 | 1,000 poll respondents in 50 towns (`town`) and two regions (`region`), with policy `support` (0/1), `trust` (0–10), `age`, and a survey `weight`. |
| [`tutoring.csv`](tutoring.csv) | 800 | 7 | 800 students: `prior_gpa`, `motivation`, `parent_degree`, whether they chose `tutoring`, their `exam` score, and a teacher's recommendation (`recommended`). |
| [`growth.csv`](growth.csv) | 1,163 | 4 | 250 students × up to 5 waves: reading `score` by `wave`, with a randomized `group` (control / intervention). |

## Practice simulation: political parasocial attachment

A survey with a credibility judgment task, coded interviews, and a randomized intervention.

| File | Rows | Columns | What's in it |
|---|---|---|---|
| [`ppsr_survey.csv`](ppsr_survey.csv) | 375 | 28 | Parasocial simulation — 375 respondents: parasocial attachment (`parasocial`, `prism`), identity `fusion`, perceived `charisma`, `affective_polarization`, `institutional_trust`, ideology and interest, twelve 1–5 wisdom items `wis_1`–`wis_12` (2, 6, 7, and 11 reverse-worded) with their `wisdom` score, and `credibility_bias`; recruited from a `university` or `prolific` `stream`. |
| [`credibility_trials.csv`](credibility_trials.csv) | 4,500 | 6 | The credibility task trial by trial: 375 participants × 12 descriptions, each `creditable` or `discrediting` (`valence`) and attributed to the `favoured` or `disliked` figure (`target`), with `credibility` and `confidence` ratings (1–5). |
| [`ppsr_narratives.csv`](ppsr_narratives.csv) | 30 | 4 | 30 coded interviews: `group` (maintained / breakup), the `figure_position` in the narrative (subject, helper, opponent), and whether political `commitments_survived` the breakup (0/1). |
| [`ppsr_experiment.csv`](ppsr_experiment.csv) | 137 | 11 | 137 participants randomized to a writing `arm` (wise, parasocial, observer): `pre_`/`post_` attachment (`prism`) and polarization (`ap`), `wisdom`, `stream`, `issue`, a `manipulation_check`, and `words` written. |

## Practice simulation: asking chatbots about court cases

Session transcripts, exported chat logs, the speech-act coding sheet and both coders' sheets, the interview framework matrix, and coded chatbot responses.

| File | Rows | Columns | What's in it |
|---|---|---|---|
| [`llm_sessions.csv`](llm_sessions.csv) | 32 | 20 | Chatbot simulation — one row per participant (32): `country`, `headline` (US-1–3, CA-1–3), `model` (fictional A–E), screener self-placement `p1_self_placement` (0 = left … 10 = right), who transcribed and coded the session, and the post-task rating form `a1_agree` … `a7_placement` (A3 and A7 keep written answers such as `dont_know` and `not_political`). |
| [`llm_transcripts.csv`](llm_transcripts.csv) | 1,499 | 8 | One row per turn of each session: `line`, `time`, `turn_type` (INT, PAR, QRY, LLM, ACT), `turn_id` (e.g. `P012_C1_Q03`, with `b` for an edited or regenerated turn), the interview `question` (Q1–Q11), the verbatim `text` (fillers, pauses, ((reading)) … ((/reading))), and transcriber `notes`. |
| [`llm_chat_export.csv`](llm_chat_export.csv) | 450 | 6 | The exported chat logs: every message sent (`role` = user) and received (`role` = assistant), with a UTC `timestamp_utc`. QRY rows in the transcript should match these exactly. |
| [`llm_coding.csv`](llm_coding.csv) | 267 | 25 | The consensus coding sheet, laid out like the team's Excel template: one row per speech act (`speech_act_id` = query ID + `_a`, `_b`), with `participant`, `chat`, `turn_position` (the query's number within its chat), `llm`, the full `query_text` and the act's `speech_act_text`, then the coded columns — `clause_type`, `primary_act` (10 draft levels), `directness`, presupposition (`presup`, `trigger_type`, `presup_direction`, `leading_construction`), evaluation (`evaluative`, `polarity`, `target`), `partisan_terms`, stance (`stance_disclosure`, `disclosure_direction`), `relation` to the previous model turn — plus `confidence`, `coder`, and `notes`. Columns that don't apply are blank. |
| [`llm_coder_a.csv`](llm_coder_a.csv) | 274 | 25 | Each coder's independent sheet for every transcript, before the consensus meeting — the data reliability is calculated on. A few queries are split into speech acts differently. |
| [`llm_coder_b.csv`](llm_coder_b.csv) | 253 | 25 | Each coder's independent sheet for every transcript, before the consensus meeting — the data reliability is calculated on. A few queries are split into speech acts differently. |
| [`llm_card_labels.csv`](llm_card_labels.csv) | 226 | 2 | The interview's Q5 card label for each query (`query_id`, `card_label`): what the participant says they were asking for. |
| [`llm_instrument_coding.csv`](llm_instrument_coding.csv) | 60 | 25 | 60 survey-style items of the kind used in bias research, coded with the same codebook. |
| [`llm_framework.csv`](llm_framework.csv) | 32 | 26 | The interview framework matrix: one row per participant, one 0/1 column per code (`code_1_1` … `code_6_2`; e.g. `code_4_3` = perceived lean with a cue). |
| [`llm_indexing.csv`](llm_indexing.csv) | 190 | 5 | Indexing agreement for the same 7 transcripts: one row per interview answer line and code (4.1–5.4), with each coder's 0/1. |
| [`llm_responses.csv`](llm_responses.csv) | 7,200 | 9 | 7,200 coded responses: 288 queries (`headline` × `speech_act` × `register` × `variant`; headlines 7–8 are neutral `control`s) × 5 fictional models (A–E) × 5 `run`s, with `lean` from −3 (left) to +3 (right). |

To rebuild these files after changing a generator, run `python3 tools/export_scripts.py` and then
`python3 tools/build_practice_data.py` from the repository root.

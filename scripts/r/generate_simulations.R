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

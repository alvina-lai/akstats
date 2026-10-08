# generate_data.R — creates survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv
set.seed(2026)

to_scale  <- function(z, low = 1, high = 7) round(pmin(pmax((low + high) / 2 + z, low), high), 2)
to_likert <- function(z, high = 5) as.integer(pmin(pmax(round(3 + z), 1), high))

# ---------- survey.csv: a cross-sectional survey ----------
n <- 375
age       <- sample(18:75, n, replace = TRUE)
education <- sample(1:5, n, replace = TRUE)   # 1 = high school … 5 = graduate degree
region    <- sample(c("urban", "rural"), n, replace = TRUE, prob = c(0.6, 0.4))

mind_z   <- rnorm(n) + 0.015 * (age - 40)
social_z <- rnorm(n)
phone_z  <- 0.6 * social_z + 0.8 * rnorm(n)

# Built-in truths:
#  • social media use → rumination, weaker when mindfulness is high
#  • rumination → anxiety, plus a small direct effect of social media
rum_z <- 0.40 * social_z + 0.15 * phone_z - 0.20 * mind_z -
         0.20 * social_z * mind_z + rnorm(n, sd = 0.85)
anx_z <- 0.45 * rum_z + 0.15 * social_z + rnorm(n, sd = 0.85)

survey <- data.frame(
  participant = 1:n, age, education, region,
  social_media   = to_scale(social_z),
  phone_checking = to_scale(phone_z),
  rumination     = to_scale(rum_z),
  anxiety        = to_scale(anx_z)
)

# Six 1–5 mindfulness items; items 3 and 5 are reverse-worded, ~3% missing
for (i in 1:6) {
  item <- to_likert(0.9 * mind_z + rnorm(n, sd = 0.7))
  if (i %in% c(3, 5)) item <- 6L - item
  item[runif(n) < 0.03] <- NA
  survey[[paste0("mind_", i)]] <- item
}

# Precomputed composite so you can check your own scoring
keyed <- survey[paste0("mind_", 1:6)]
keyed[c("mind_3", "mind_5")] <- 6 - keyed[c("mind_3", "mind_5")]
survey$mindfulness <- ifelse(rowSums(!is.na(keyed)) >= 5,
                             round(rowMeans(keyed, na.rm = TRUE), 3), NA)
write.csv(survey, "survey.csv", row.names = FALSE)

# ---------- diary.csv: 14 daily reports per person ----------
n_people <- 100; n_days <- 14
usual_hours <- rnorm(n_people, 7, 1.5)    # each person's typical workday
consc       <- rnorm(n_people)            # conscientiousness (z)
diary <- do.call(rbind, lapply(1:n_people, function(p) {
  within_slope <- -0.25 - 0.10 * consc[p] + rnorm(1, sd = 0.08)
  baseline     <- 4 + 0.30 * (usual_hours[p] - 7) + rnorm(1, sd = 0.6)
  hours        <- usual_hours[p] + rnorm(n_days, sd = 1.2)
  wellbeing    <- baseline + within_slope * (hours - usual_hours[p]) + rnorm(n_days, sd = 0.7)
  data.frame(participant = p, day = 1:n_days,
             work_hours = round(pmin(pmax(hours, 0), 16), 1),
             wellbeing  = round(pmin(pmax(wellbeing, 1), 7), 2),
             conscientiousness = round(pmin(pmax(3 + 0.8 * consc[p], 1), 5), 2))
}))
write.csv(diary, "diary.csv", row.names = FALSE)

# ---------- classroom.csv: three teaching methods, randomized ----------
n_class <- 150
method  <- sample(rep(c("lecture", "active", "flipped"), each = n_class / 3))
effect  <- c(lecture = 0, active = 0.40, flipped = 0.10)[method]
pre_z   <- rnorm(n_class)
post_z  <- 0.7 * pre_z + effect + rnorm(n_class, sd = 0.7)
classroom <- data.frame(
  student  = 1:n_class, method,
  school   = sample(c("Ash", "Birch", "Cedar", "Maple"), n_class, replace = TRUE),
  pretest  = pmin(pmax(round(65 + 10 * pre_z), 0), 100),
  posttest = pmin(pmax(round(65 + 10 * post_z), 0), 100)
)
write.csv(classroom, "classroom.csv", row.names = FALSE)

# ---------- essays.csv: two raters score 120 essays on a 1–6 rubric ----------
n_essays <- 120
quality  <- rnorm(n_essays, 3.5, 1.1)
score <- function(bias, noise = 0.6) {
  as.integer(pmin(pmax(round(quality + bias + rnorm(n_essays, sd = noise)), 1), 6))
}
essays <- data.frame(essay = 1:n_essays,
                     rater_a = score(0),
                     rater_b = score(0.3),          # rater B is slightly more lenient
                     rater_a_retest = score(0))     # rater A again, two weeks later
write.csv(essays, "essays.csv", row.names = FALSE)

# ---------- stroop_trials.csv and stroop.csv: a Stroop task ----------
n_s <- 60; n_items <- 24
person        <- rnorm(n_s, sd = 0.15)            # some people respond faster overall
person_effect <- rnorm(n_s, sd = 0.03)            # and show a bigger or smaller Stroop effect
item_effect   <- rnorm(n_items, sd = 0.05)        # some color words are harder
trials <- expand.grid(condition = c("congruent", "incongruent"), item = 1:n_items,
                      participant = 1:n_s, stringsAsFactors = FALSE)
trials <- trials[, c("participant", "item", "condition")]
log_rt <- 6.3 + person[trials$participant] + item_effect[trials$item] +
          (0.08 + person_effect[trials$participant]) * (trials$condition == "incongruent") +
          rnorm(nrow(trials), sd = 0.25)
trials$rt <- round(exp(log_rt))
write.csv(trials, "stroop_trials.csv", row.names = FALSE)

# One row per participant: mean RT in each condition, plus age and an attention check
means <- tapply(trials$rt, list(trials$participant, trials$condition), mean)
write.csv(data.frame(
  participant     = 1:n_s,
  age             = sample(16:40, n_s, replace = TRUE),     # a few are under 18
  attention_check = ifelse(runif(n_s) < 0.9, "pass", "fail"),
  rt_congruent    = round(means[, "congruent"], 1),
  rt_incongruent  = round(means[, "incongruent"], 1)
), "stroop.csv", row.names = FALSE)

cat("Saved survey.csv, diary.csv, classroom.csv, essays.csv, stroop_trials.csv, stroop.csv\n")

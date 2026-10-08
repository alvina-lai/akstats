# generate_extra_data.R — creates missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv
set.seed(2028)

# ---------- missing.csv: stressed people skip the wellbeing question ----------
n <- 500
stress <- rnorm(n)
sleep <- round(pmin(pmax(7 - 0.5 * stress + rnorm(n, sd = 0.8), 3), 10), 1)
wellbeing_true <- round(4 - 0.6 * stress + 0.2 * (sleep - 7) + rnorm(n, sd = 0.7), 2)
skipped <- runif(n) < plogis(-1.4 + 1.2 * stress)           # missing at random, given stress
write.csv(data.frame(
  id = 1:n,
  age = sample(18:69, n, replace = TRUE),
  stress = round(stress, 2),
  sleep,
  wellbeing = ifelse(skipped, NA, wellbeing_true),
  wellbeing_true                                             # the hidden truth, for checking only
), "missing.csv", row.names = FALSE)

# ---------- fillers.csv: "um"s and "uh"s in interviews of different lengths ----------
n_f <- 300
minutes   <- round(runif(n_f, 5, 15), 1)
evaluated <- sample(0:1, n_f, replace = TRUE)                # 1 = told the interview was being assessed
l2        <- as.integer(runif(n_f) < 0.4)                    # 1 = speaking a second language
age_f     <- sample(18:69, n_f, replace = TRUE)
rate <- 0.8 * 1.4^evaluated * 1.6^l2 * exp(-0.005 * (age_f - 40))   # fillers per minute
write.csv(data.frame(
  speaker = 1:n_f,
  condition = ifelse(evaluated == 1, "evaluated", "relaxed"),
  l2, age = age_f, minutes,
  fillers = rnbinom(n_f, size = 3, mu = minutes * rate)      # extra-Poisson variation
), "fillers.csv", row.names = FALSE)

# ---------- poll.csv: a stratified cluster sample that oversamples rural towns ----------
poll <- do.call(rbind, lapply(1:50, function(town) {        # 25 urban + 25 rural towns, 20 people each
  region <- if (town <= 25) "urban" else "rural"
  town_effect <- rnorm(1, sd = 0.5)
  age <- sample(18:84, 20, replace = TRUE)
  p <- plogis(ifelse(region == "urban", 0.4, -0.6) + town_effect - 0.01 * (age - 45))
  support <- as.integer(runif(20) < p)
  trust <- pmin(pmax(round(5 + 1.5 * support + town_effect + rnorm(20, sd = 2)), 0), 10)
  data.frame(region, town, age, support, trust)
}))
poll <- cbind(id = seq_len(nrow(poll)), poll)
# Population: 700,000 urban and 300,000 rural adults; the poll interviewed 500 of each
poll$weight <- ifelse(poll$region == "urban", 700000 / 500, 300000 / 500)
write.csv(poll, "poll.csv", row.names = FALSE)

# ---------- tutoring.csv: who chooses tutoring is not random ----------
n_t <- 800
prior_gpa     <- round(pmin(pmax(rnorm(n_t, 3, 0.5), 1.5), 4), 2)
motivation    <- round(rnorm(n_t), 2)
parent_degree <- as.integer(runif(n_t) < 0.4)
tutoring <- as.integer(runif(n_t) < plogis(-0.5 + 1.2 * motivation - 0.6 * (prior_gpa - 3) +
                                           0.5 * parent_degree))
exam <- round(62 + 10 * (prior_gpa - 3) + 6 * motivation + 3 * parent_degree + 5 * tutoring +
              rnorm(n_t, sd = 7), 1)                         # true tutoring effect: +5 points
recommended <- as.integer(runif(n_t) < plogis(-1 + 1.5 * tutoring + 0.12 * (exam - 62)))   # a collider
write.csv(data.frame(student = 1:n_t, prior_gpa, motivation, parent_degree, tutoring, exam, recommended),
          "tutoring.csv", row.names = FALSE)

# ---------- growth.csv: reading scores over 5 waves, with a randomized intervention ----------
n_g <- 250
group <- sample(rep(0:1, each = n_g / 2))                    # 1 = reading intervention
start <- rnorm(n_g, sd = 8)                                  # each student's own starting level
slope <- rnorm(n_g, sd = 1.5) + 0.05 * start                 # and their own growth rate
growth <- expand.grid(wave = 0:4, student = 1:n_g)[, c("student", "wave")]
growth$group <- ifelse(group[growth$student] == 1, "intervention", "control")
growth$score <- round(100 + start[growth$student] +
                      (5 + 2 * group[growth$student] + slope[growth$student]) * growth$wave +
                      rnorm(nrow(growth), sd = 4), 1)
growth <- growth[runif(nrow(growth)) >= 0.08, c("student", "group", "wave", "score")]   # ~8% of visits missed
write.csv(growth, "growth.csv", row.names = FALSE)

cat("Saved missing.csv, fillers.csv, poll.csv, tutoring.csv, growth.csv\n")

# generate_more_data.R — creates judgments.csv, commutes.csv, habits.csv, profiles.csv
set.seed(2027)

# ---------- judgments.csv: a 2 × 2 sentence-acceptability experiment ----------
n_part <- 40; n_items <- 32
conditions <- data.frame(structure = c("simple", "simple", "complex", "complex"),
                         distance  = c("short", "long", "short", "long"))
part_eff <- rnorm(n_part, sd = 0.7); item_eff <- rnorm(n_items, sd = 0.5)
part_acc <- rnorm(n_part, sd = 0.6); item_acc <- rnorm(n_items, sd = 0.4)

judgments <- expand.grid(item = 1:n_items, participant = 1:n_part)
cond <- conditions[(judgments$participant + judgments$item) %% 4 + 1, ]   # Latin square
judgments$structure <- cond$structure
judgments$distance  <- cond$distance
is_complex <- judgments$structure == "complex"
is_long    <- judgments$distance == "long"
latent <- part_eff[judgments$participant] + item_eff[judgments$item] -
          0.8 * is_complex - 0.5 * is_long - 0.6 * (is_complex & is_long) +
          rlogis(nrow(judgments), scale = 0.7)
judgments$rating  <- findInterval(latent, c(-2.5, -1.6, -0.8, 0, 0.8, 1.6)) + 1   # 1–7
p_correct <- plogis(1.5 - 0.5 * is_complex + part_acc[judgments$participant] + item_acc[judgments$item])
judgments$correct <- as.integer(runif(nrow(judgments)) < p_correct)
judgments <- judgments[, c("participant", "item", "structure", "distance", "rating", "correct")]
write.csv(judgments, "judgments.csv", row.names = FALSE)

# ---------- commutes.csv: weekly commute mode over 10 weeks ----------
modes <- c("car", "bus", "bike", "walk")
commutes <- do.call(rbind, lapply(1:120, function(p) {
  distance <- round(rgamma(1, shape = 2, scale = 3), 1)            # km
  taste    <- c(0, rnorm(3, sd = 0.8))                              # personal preferences (car = 0)
  out <- data.frame(participant = p, week = 1:10, distance_km = distance, mode = NA_character_)
  previous <- NA
  for (week in 1:10) {
    utility <- c(0, 0.2, -0.5 + 0.12 * week - 0.15 * distance, 1.0 - 0.6 * distance) + taste
    if (!is.na(previous)) utility[previous] <- utility[previous] + 1.5   # habit
    choice <- sample(1:4, 1, prob = exp(utility) / sum(exp(utility)))
    out$mode[week] <- modes[choice]
    previous <- choice
  }
  out
}))
write.csv(commutes, "commutes.csv", row.names = FALSE)

# ---------- habits.csv: six study strategies from three hidden types ----------
strategies <- c("reread", "notes", "selftest", "spaced", "explain", "peers")
type_profiles <- rbind(c(0.90, 0.85, 0.15, 0.10, 0.10, 0.20),   # 1: passive review
                       c(0.50, 0.50, 0.85, 0.75, 0.60, 0.25),   # 2: active practice
                       c(0.40, 0.40, 0.40, 0.30, 0.80, 0.90))   # 3: social learning
n_h <- 500
cls <- sample(1:3, n_h, replace = TRUE, prob = c(0.45, 0.35, 0.20))
present <- matrix(runif(n_h * 6), ncol = 6) < type_profiles[cls, ]
habits <- data.frame(id = 1:n_h, matrix(as.integer(present), ncol = 6))
names(habits)[2:7] <- strategies
habits$gpa <- round(pmin(pmax(c(2.8, 3.4, 3.1)[cls] + rnorm(n_h, sd = 0.4), 0), 4), 2)
habits$true_class <- cls
write.csv(habits, "habits.csv", row.names = FALSE)

# ---------- profiles.csv: four continuous scores from three hidden profiles ----------
n_lpa   <- 400
profile <- sample(1:3, n_lpa, replace = TRUE, prob = c(0.5, 0.3, 0.2))
profile_means <- rbind(c(5.5, 2.5, 5.5, 5.0),    # 1: thriving
                       c(4.0, 4.0, 4.0, 4.0),    # 2: average
                       c(2.5, 5.5, 3.0, 2.8))    # 3: struggling
indicators <- profile_means[profile, ] + matrix(rnorm(n_lpa * 4, sd = 0.7), ncol = 4)
lpa <- data.frame(id = 1:n_lpa, round(pmin(pmax(indicators, 1), 7), 2))
names(lpa)[2:5] <- c("wellbeing", "stress", "support", "sleep")
lpa$age          <- sample(18:65, n_lpa, replace = TRUE)
lpa$burnout      <- round(c(2, 3, 4.5)[profile] + rnorm(n_lpa, sd = 0.8), 2)
lpa$true_profile <- profile
write.csv(lpa, "profiles.csv", row.names = FALSE)

cat("Saved judgments.csv, commutes.csv, habits.csv, profiles.csv\n")

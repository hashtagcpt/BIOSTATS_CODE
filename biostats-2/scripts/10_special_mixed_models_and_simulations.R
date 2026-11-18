# =============================================================================
#  BIOSTATS 2 — SCRIPT 10: LINEAR MIXED-EFFECTS MODELS & PROBABILITY SIMULATIONS
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized & fixed from B2_Lecture_5_New_Regression.R &
#            sleeping_beauty_problem.R
#  Datasets: Simulated Contrast Sensitivity Function (CSF) longitudinal cohort
#            & Monte Carlo probability simulation
#
#  Topics Covered:
#    1. Generating structured factorial vision-science simulations (`expand_grid`)
#    2. Why ordinary `lm()` ignores repeated-measures clustering within subjects
#    3. Fitting & visualizing Linear Mixed-Effects Models (`lme4::lmer` + `lmerTest`)
#       with random subject intercepts `(1 | subject)`
#    4. Fixing a real psychometric GLM bug (binomial vs. Gaussian link!)
#    5. Monte Carlo probability puzzles: The Sleeping Beauty Problem
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(lme4)        # Linear mixed-effects models
library(lmerTest)    # Adds Satterthwaite df & p-values to lmer()
theme_set(theme_minimal(base_size = 13))
set.seed(416)


# ---- 1. Simulating a Vision Science CSF Study (Repeated Measures!) ----------
# Suppose 30 subjects (15 Patients, 15 Controls — note: each subject belongs
# to ONE group, fixing the legacy script where every subject was in BOTH groups!)
# are tested across 3 orientations and 10 spatial frequencies (1 to 30 cpd).

n_per_group <- 15
subjects_tbl <- tibble(
  subject      = factor(paste0("Subject_", sprintf("%02d", 1:(2 * n_per_group)))),
  group        = factor(rep(c("Control", "Patient"), each = n_per_group)),
  subj_offset  = rnorm(2 * n_per_group, mean = 0, sd = 0.22)  # Individual baseline sensitivity!
)

csf_data <- tidyr::expand_grid(
  subject           = subjects_tbl$subject,
  orientation       = factor(c("vertical", "horizontal", "oblique")),
  spatial_frequency = seq(2, 20, by = 2)
) |>
  left_join(subjects_tbl, by = "subject") |>
  mutate(
    # Realistic log contrast sensitivity: declines with high spatial frequency;
    # Patients show reduced sensitivity at cardinal (vertical/horizontal) orientations!
    cardinal_drop = if_else(group == "Patient" & orientation %in% c("vertical", "horizontal"),
                            -0.25, 0.00),
    oblique_eff   = if_else(orientation == "oblique", -0.10, 0.00),
    log_cs        = 2.15 + subj_offset - 0.045 * spatial_frequency +
                    cardinal_drop + oblique_eff + rnorm(n(), 0, 0.10)
  )

head(csf_data)


# ---- 2. Ordinary lm() vs. Linear Mixed-Effects Model (lme4::lmer) -----------
# WRONG for repeated measures: `lm()` treats all 900 rows as independent subjects!
lm_naive <- lm(log_cs ~ group * orientation + spatial_frequency, data = csf_data)

# RIGHT for repeated measures: `(1 | subject)` gives each participant their own
# random baseline intercept, properly separating between-subject vs. within-subject error!
lmm_fit <- lmerTest::lmer(
  log_cs ~ group * orientation + spatial_frequency + (1 | subject),
  data = csf_data
)

cat("--- Naive OLS `lm()` (WRONG df — treats repeated rows as independent!) ---\n")
print(round(summary(lm_naive)$coefficients, 4))

cat("\n--- Linear Mixed Model `lmer()` (Proper subject-level random intercepts) ---\n")
print(round(summary(lmm_fit)$coefficients, 4))
# Look at `groupPatient` Std. Error & df: `lm()` vastly underestimates the SE of
# the between-subject group effect, whereas `lmer()` gets the right patient-level SE!

# Visualize subject-specific fitted lines for 6 illustrative subjects (cleanly faceted!)
csf_data <- csf_data |> mutate(pred_lmm = predict(lmm_fit))

csf_subset <- csf_data |>
  filter(subject %in% c("Subject_01", "Subject_02", "Subject_03",
                        "Subject_16", "Subject_17", "Subject_18"))

ggplot(csf_subset, aes(x = spatial_frequency, y = log_cs, colour = orientation)) +
  geom_point(alpha = 0.65, size = 1.8) +
  geom_line(aes(y = pred_lmm), linewidth = 1) +
  facet_wrap(~ group + subject) +
  labs(
    title    = "Linear Mixed-Effects Model: Individual Subject CSF Fits",
    subtitle = "Each subject has a personal intercept `(1 | subject)` plus fixed orientation & group effects",
    x        = "Spatial Frequency (cycles/degree)",
    y        = "Log Contrast Sensitivity",
    colour   = "Orientation"
  ) +
  theme(legend.position = "bottom")


# ---- 3. Clean Psychometric Logistic Curve (Fixing Legacy Gaussian Bug!) -----
# Notice how in the old B2_Lecture_5_New_Regression.R, lines 119-121 mistakenly
# fit `family = gaussian` and predicted with a mismatched column name.
# Here is the clean, valid binomial GLM on simulated trial counts!
n_trials_lvl <- 40
psy_sim <- tibble(
  contrast    = seq(0.01, 0.12, length.out = 8),
  true_prob   = plogis(-3.2 + 55 * contrast),
  n_correct   = rbinom(8, size = n_trials_lvl, prob = true_prob),
  n_incorrect = n_trials_lvl - n_correct
)

logit_fit <- glm(cbind(n_correct, n_incorrect) ~ contrast,
                 family = binomial(link = "logit"),
                 data   = psy_sim)

pred_grid <- tibble(contrast = seq(0.005, 0.13, length.out = 100)) |>
  mutate(pred_prob = predict(logit_fit, newdata = pick(everything()), type = "response"))

ggplot(psy_sim, aes(x = contrast, y = n_correct / n_trials_lvl)) +
  geom_line(data = pred_grid, aes(x = contrast, y = pred_prob),
            colour = "#0072B2", linewidth = 1.2) +
  geom_point(size = 3.2) +
  labs(
    title    = "Binomial Logistic Psychometric Curve (Fixed GLM Example)",
    subtitle = "Fits `cbind(n_correct, n_incorrect)` with binomial logit link — bounded in [0, 1]",
    x        = "Stimulus Contrast", y = "Proportion Correct"
  )


# ---- 4. Monte Carlo Probability Puzzle: Sleeping Beauty Problem -------------
# Reused & cleaned from `sleeping_beauty_problem.R`!
# Rules: A fair coin is flipped Sunday night.
#   - Heads -> Beauty is woken ONCE (Monday).
#   - Tails -> Beauty is woken TWICE (Monday AND Tuesday, memory erased between).
# Across 20,000 simulated experiments, what fraction of ALL awakenings occur
# when the coin landed Tails? ("Thirder" position -> converges to 2/3 = 0.667!)
n_runs <- 20000
flips  <- sample(c("H", "T"), size = n_runs, replace = TRUE, prob = c(0.5, 0.5))

awakenings_heads <- sum(flips == "H") * 1
awakenings_tails <- sum(flips == "T") * 2
prop_tails_given_awake <- awakenings_tails / (awakenings_heads + awakenings_tails)

cat(sprintf("\n--- Sleeping Beauty Monte Carlo (%d experiments) ---\n", n_runs))
cat(sprintf("Heads awakenings: %d | Tails awakenings: %d | P(Tails | Awake) = %.4f (theory = 2/3 = 0.6667)\n",
            awakenings_heads, awakenings_tails, prop_tails_given_awake))


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Inspect `VarCorr(lmm_fit)` to see how much total variance in `log_cs` is
#    between-subject (`subject` random intercept) vs. within-subject (`Residual`).
# 2. Add a random slope for `spatial_frequency` (`(1 + spatial_frequency | subject)`)
#    to `lmm_fit` and compare AIC with the random-intercept-only model.
# 3. Modify the Sleeping Beauty simulation so Tails wakes Beauty THREE times
#    (Mon, Tue, Wed). What probability does `prop_tails_given_awake` converge to?

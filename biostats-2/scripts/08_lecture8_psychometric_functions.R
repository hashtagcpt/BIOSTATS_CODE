# =============================================================================
#  BIOSTATS 2 — SCRIPT 08: PSYCHOMETRIC FUNCTION FITTING & THRESHOLD BOOTSTRAP
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_8_w_assignment.R
#  Datasets: biostats-2/data/ONOFF01-dog-OFF-1-29-Mar-2019_v7.mat
#
#  Topics Covered:
#    1. Reading MATLAB `.mat` psychophysics files (`R.matlab::readMat`) &
#       parsing experimental metadata from structured filenames
#    2. Summarizing trial-by-trial 2-Alternative Forced-Choice (2AFC) data
#    3. Fitting a 2AFC psychometric curve via GLM with a 50% lower asymptote:
#       `glm(cbind(correct, incorrect) ~ log(contrast), family = binomial(psyphy::mafc.logit(2)))`
#    4. Extracting 75% contrast threshold & slope via `modelfree::threshold_slope()`
#    5. Bootstrapping a 95% confidence interval for the observer's contrast threshold!
#    6. Simulating synthetic 2AFC psychometric data (`datasim()`)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(R.matlab)    # Read MATLAB .mat files
library(psyphy)      # Supplies mafc.logit(m) link function for m-AFC psychophysics!
library(modelfree)   # Supplies threshold_slope()
theme_set(theme_minimal(base_size = 14))
set.seed(2026)


# ---- 1. Load & Parse 2AFC MATLAB Psychophysics Data -------------------------
# Method of Constant Stimuli: 2-Alternative Forced-Choice (2AFC -> chance = 50%),
# 25 trials per contrast level.
m_choice <- 2
mat_path <- "biostats-2/data/ONOFF01-dog-OFF-1-29-Mar-2019_v7.mat"
d_file   <- R.matlab::readMat(mat_path)

# Parse structured filename metadata: Subject - Stimulus - Polarity - Block
fname_parts <- str_split(basename(mat_path), "-")[[1]]
meta <- tibble(
  subject  = fname_parts[1],
  stimulus = fname_parts[2],
  polarity = fname_parts[3],
  block    = fname_parts[4],
  mean_re  = as.numeric((d_file$OD + d_file$OS) / 2)
)
print(meta)

# Convert raw trial matrix into a clean data frame with readable column names
trials <- as_tibble(d_file$d, .name_repair = "minimal")
colnames(trials) <- c("contrast", "stim_int", "resp_int", "correct", "blocks", "age")
trials <- trials |>
  mutate(abs_contrast = abs(contrast))   # Use magnitude for OFF-decrement contrasts

# Summarize trials per contrast level cleanly (no hardcoded n_trials needed!)
df_summary <- trials |>
  group_by(abs_contrast) |>
  summarize(
    n_trials  = n(),
    correct   = sum(correct == 1),
    incorrect = sum(correct == 0),
    p_correct = correct / n_trials,
    .groups   = "drop"
  )
print(df_summary)


# ---- 2. Fit 2AFC Psychometric Function via GLM ------------------------------
# Why `binomial(mafc.logit(2))` instead of ordinary `binomial("logit")`?
# In a 2AFC task, an observer who cannot see the stimulus STILL guesses right
# 50% of the time (lower asymptote = 1/m = 0.50, NOT 0.00)!
psymet_fit <- glm(
  cbind(correct, incorrect) ~ log(abs_contrast),
  family = binomial(psyphy::mafc.logit(m_choice)),
  data   = df_summary
)
summary(psymet_fit)

# Generate smooth prediction curve + 95% confidence ribbon on link/response scale
xseq <- seq(min(df_summary$abs_contrast) * 0.8,
            max(df_summary$abs_contrast) * 1.1,
            length.out = 200)
pred <- predict(psymet_fit,
                newdata = tibble(abs_contrast = xseq),
                type    = "response",
                se.fit  = TRUE)

pred_df <- tibble(
  abs_contrast = xseq,
  fit          = pred$fit,
  se           = pred$se.fit
)

# Extract the 75% correct threshold (midpoint between 50% guessing and 100% ceiling)
thresh_info <- modelfree::threshold_slope(pred_df$fit, pred_df$abs_contrast, thresh = 0.75)
cat(sprintf("\nEstimated 75%% contrast threshold = %.4f | Slope = %.2f\n",
            thresh_info$x_th, thresh_info$slope))

# Plot observed proportions + fitted 2AFC psychometric curve + 75% threshold marker
ggplot(df_summary, aes(x = abs_contrast, y = p_correct)) +
  geom_hline(yintercept = 0.50, linetype = "dotted", colour = "grey50") +
  geom_hline(yintercept = 0.75, linetype = "dashed", colour = "firebrick") +
  geom_vline(xintercept = thresh_info$x_th, linetype = "dashed", colour = "firebrick") +
  geom_line(data = pred_df, aes(x = abs_contrast, y = fit),
            colour = "#0072B2", linewidth = 1.2) +
  geom_point(size = 3.8, colour = "black") +
  scale_y_continuous(limits = c(0.4, 1.02), breaks = seq(0.5, 1.0, by = 0.1)) +
  labs(
    title    = sprintf("2AFC Psychometric Function (%s — %s)", meta$subject, meta$polarity),
    subtitle = sprintf("Dashed red lines mark 75%% threshold = %.4f contrast", thresh_info$x_th),
    x        = "Stimulus Contrast (|contrast|)",
    y        = "Proportion Correct"
  )


# ---- 3. Bootstrapping a 95% CI for the 75% Contrast Threshold ---------------
# Resample trials WITH replacement within each contrast level (stratified
# nonparametric bootstrap — matches the Lecture 8 Exercise!).
n_boot <- 400
boot_thresholds <- numeric(n_boot)

for (b in seq_len(n_boot)) {
  sim_summary <- df_summary |>
    mutate(
      # Resample `n_trials` Bernoulli outcomes with probability = observed `p_correct`
      boot_correct   = rbinom(n(), size = n_trials, prob = p_correct),
      boot_incorrect = n_trials - boot_correct
    )
  fit_b <- suppressWarnings(
    glm(cbind(boot_correct, boot_incorrect) ~ log(abs_contrast),
        family = binomial(psyphy::mafc.logit(m_choice)),
        data   = sim_summary)
  )
  p_b <- predict(fit_b, newdata = tibble(abs_contrast = xseq), type = "response")
  boot_thresholds[b] <- tryCatch(
    modelfree::threshold_slope(p_b, xseq, thresh = 0.75)$x_th,
    error = function(e) NA_real_
  )
}

ci_thresh <- quantile(boot_thresholds, probs = c(0.025, 0.975), na.rm = TRUE)
cat(sprintf("Bootstrap 95%% CI for 75%% threshold: [%.4f, %.4f] (based on %d valid fits)\n",
            ci_thresh[1], ci_thresh[2], sum(!is.na(boot_thresholds))))


# ---- 4. Reusable Psychometric Simulator (`datasim`, used in Assignment 4) ---
datasim <- function(contrasts, pcorrect, ntrials) {
  stopifnot(length(contrasts) == length(pcorrect))
  map2_dfr(contrasts, pcorrect, \(c_val, p_val) {
    tibble(
      contrast = rep(c_val, ntrials),
      correct  = rbinom(ntrials, size = 1, prob = p_val)
    )
  })
}

# Quick demo: simulate 20 trials/level across 10 contrast levels
sim_demo <- datasim(
  contrasts = seq(0.01, 0.10, length.out = 10),
  pcorrect  = plogis(seq(-2.5, 3.5, length.out = 10)),
  ntrials   = 20
)
head(sim_demo)


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Refit `psymet_fit` assuming a 4AFC task (`m_choice <- 4`, chance = 25%).
#    How does the lower asymptote and the estimated 62.5% threshold change?
# 2. Plot a histogram of `boot_thresholds` with vertical dashed lines showing
#    the observed threshold and its 95% bootstrap CI.
# 3. Try resampling trials across the WHOLE dataset (`trials[sample(nrow(trials), replace = TRUE), ]`)
#    instead of stratified by contrast — note how `n_trials` now varies per contrast!

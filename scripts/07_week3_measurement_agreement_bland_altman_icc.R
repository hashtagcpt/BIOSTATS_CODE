# =============================================================================
#  SCRIPT 07: CLINICAL MEASUREMENT AGREEMENT (BLAND-ALTMAN) & RELIABILITY (ICC)
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 3 - Statistical Intuition & Visualization
#            (+ Kraemer & Blasey Ch. 3 in Week 8)
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 124-136, 312-313)
#  Datasets: data/04_tonometer_agreement.csv
#            data/09_preceptor_grading_icc.csv
#
#  Topics Covered:
#    1. Validity (trueness/bias) vs. Reliability (precision) target simulation
#    2. Why high Pearson r DOES NOT imply clinical agreement!
#    3. Bland-Altman analysis: mean bias, 95% Limits of Agreement (+/- 1.96 SD),
#       and 95% CIs for the bias and limits (distinguishing LoA from CIs!)
#    4. Checking fixed offset vs. proportional bias across the clinical range
#    5. Intraclass Correlation Coefficient (ICC): Consistency vs. Agreement
#       across 3 clinical preceptors grading OD students (psych::ICC & manual)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(psych)       # For psych::ICC() (installed; irr::icc() is another common option)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

tonom     <- readr::read_csv("data/04_tonometer_agreement.csv", show_col_types = FALSE)
preceptor <- readr::read_csv("data/09_preceptor_grading_icc.csv", show_col_types = FALSE)


# ---- 1. Validity (Trueness) vs. Reliability (Precision) (Slides 125-126) ----
# Simulate 4 clinical measurement profiles relative to a true target IOP = (0, 0)
n_shots <- 25
targets <- bind_rows(
  tibble(profile = "1. Reliable, Not Accurate (Biased)",
         x = rnorm(n_shots, 1.8, 0.30), y = rnorm(n_shots, 1.5, 0.30)),
  tibble(profile = "2. Accurate on Avg, Not Reliable (Noisy)",
         x = rnorm(n_shots, 0.0, 1.30), y = rnorm(n_shots, 0.0, 1.30)),
  tibble(profile = "3. Neither Accurate nor Reliable",
         x = rnorm(n_shots, 1.6, 1.25), y = rnorm(n_shots, -1.4, 1.25)),
  tibble(profile = "4. Both Accurate and Reliable (Gold Standard)",
         x = rnorm(n_shots, 0.0, 0.28), y = rnorm(n_shots, 0.0, 0.28))
)

ggplot(targets, aes(x = x, y = y)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_point(size = 2.4, alpha = 0.75, colour = "#0072B2") +
  annotate("point", x = 0, y = 0, colour = "firebrick", shape = 4, size = 4, stroke = 1.4) +
  facet_wrap(~ profile) +
  coord_equal(xlim = c(-4, 4), ylim = c(-4, 4)) +
  labs(
    title    = "Target Analogy: Systematic Bias vs. Random Measurement Noise",
    subtitle = "Red X marks true target value; blue points are repeated readings",
    x        = "Measurement Error Axis 1", y = "Measurement Error Axis 2"
  )


# ---- 2. Why High Pearson Correlation Does NOT Imply Agreement (Slides 129-131)
# Compare Goldmann Applanation Tonometer (GAT, clinical reference) vs.
# Portable Rebound Tonometer on the same 50 eyes (`data/04_tonometer_agreement.csv`).

r_devices <- cor.test(tonom$goldmann_iop, tonom$rebound_iop)
cat("--- Pearson Correlation Between Two Tonometers ---\n")
cat(sprintf("Pearson r = %.4f (p = %.2e)\n", r_devices$estimate, r_devices$p.value))

# Look at the scatter plot WITH the y = x line of perfect agreement!
# Notice that even with r ~ 0.95, almost EVERY point sits ABOVE y = x!
ggplot(tonom, aes(x = goldmann_iop, y = rebound_iop)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              colour = "firebrick", linewidth = 0.9) +
  geom_point(size = 2.5, alpha = 0.75, colour = "#0072B2") +
  geom_smooth(method = "lm", se = FALSE, colour = "black", linewidth = 0.8) +
  coord_equal() +
  labs(
    title    = sprintf("High Correlation (r = %.3f) Does Not Mean Devices Agree!", r_devices$estimate),
    subtitle = "Red dashed = Line of Equality (y = x). Black = regression fit. Rebound reads systematically higher.",
    x        = "Goldmann Applanation IOP (mmHg)",
    y        = "Portable Rebound IOP (mmHg)"
  )


# ---- 3. Bland-Altman Analysis & Plot (Slides 128, 132-135) ------------------
# Bland & Altman (1986):
#   x-axis = average of the two methods:  (Rebound + Goldmann) / 2
#   y-axis = paired difference         :  Rebound - Goldmann
#
# Key quantities (keep LoA and CIs strictly separate! Slide 134):
#   - Mean bias (dbar)            : systematic fixed offset between instruments
#   - 95% Limits of Agreement     : dbar +/- 1.96 * SD(differences)
#                                   (where ~95% of INDIVIDUAL patient differences fall)
#   - 95% CI for mean bias        : dbar +/- t_crit * SD / sqrt(n)
#   - 95% CI for each LoA         : LoA  +/- t_crit * sqrt(3 * SD^2 / n)

ba_df <- tonom |>
  mutate(
    mean_iop = (rebound_iop + goldmann_iop) / 2,
    diff_iop = rebound_iop - goldmann_iop   # Positive = Rebound reads higher than Goldmann
  )

n_ba     <- nrow(ba_df)
dbar     <- mean(ba_df$diff_iop)
sd_diff  <- sd(ba_df$diff_iop)
t_crit   <- qt(0.975, df = n_ba - 1)

# 95% Limits of Agreement
loa_upper <- dbar + 1.96 * sd_diff
loa_lower <- dbar - 1.96 * sd_diff

# Estimation uncertainty (95% CIs) around the bias and around the LoAs
se_bias <- sd_diff / sqrt(n_ba)
se_loa  <- sqrt(3 * sd_diff^2 / n_ba)
ci_bias <- dbar + c(-1, 1) * t_crit * se_bias
ci_loa_upper <- loa_upper + c(-1, 1) * t_crit * se_loa
ci_loa_lower <- loa_lower + c(-1, 1) * t_crit * se_loa

cat("\n--- Bland-Altman Summary (Rebound - Goldmann, mmHg) ---\n")
cat(sprintf("Mean Bias (fixed offset) : %+.2f mmHg (95%% CI [%+.2f, %+.2f])\n",
            dbar, ci_bias[1], ci_bias[2]))
cat(sprintf("SD of differences        : %.2f mmHg\n", sd_diff))
cat(sprintf("Upper 95%% LoA            : %+.2f mmHg (95%% CI [%+.2f, %+.2f])\n",
            loa_upper, ci_loa_upper[1], ci_loa_upper[2]))
cat(sprintf("Lower 95%% LoA            : %+.2f mmHg (95%% CI [%+.2f, %+.2f])\n",
            loa_lower, ci_loa_lower[1], ci_loa_lower[2]))

# Check clinical tolerance! Suppose our pre-specified clinical interchangeability
# tolerance for IOP tonometers is +/- 2.0 mmHg.
clinical_tol <- 2.0
pct_within_tol <- mean(abs(ba_df$diff_iop) <= clinical_tol) * 100
cat(sprintf("Readings within +/- %.1f mmHg clinical tolerance: %.1f%%\n",
            clinical_tol, pct_within_tol))

# Check for proportional bias (does the disagreement grow at higher IOPs? Slide 133)
prop_bias_fit <- lm(diff_iop ~ mean_iop, data = ba_df)
cat("\nProportional bias check (diff ~ mean):\n")
print(summary(prop_bias_fit)$coefficients)

# Publication-ready Bland-Altman Plot
ggplot(ba_df, aes(x = mean_iop, y = diff_iop)) +
  # Shaded clinical tolerance zone (+/- 2 mmHg)
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -clinical_tol, ymax = clinical_tol,
           fill = "#009E73", alpha = 0.10) +
  geom_hline(yintercept = 0, colour = "grey45", linetype = "dotted") +
  geom_hline(yintercept = dbar, colour = "#0072B2", linewidth = 1) +
  geom_hline(yintercept = c(loa_lower, loa_upper),
             colour = "firebrick", linetype = "dashed", linewidth = 0.9) +
  geom_smooth(method = "lm", se = FALSE, colour = "#E69F00", linewidth = 0.8) +
  geom_point(size = 2.5, alpha = 0.8) +
  annotate("text", x = max(ba_df$mean_iop), y = dbar + 0.25,
           label = sprintf("Bias = %+.2f mmHg", dbar), hjust = 1, colour = "#0072B2") +
  annotate("text", x = max(ba_df$mean_iop), y = loa_upper + 0.25,
           label = sprintf("+1.96 SD = %+.2f", loa_upper), hjust = 1, colour = "firebrick") +
  annotate("text", x = max(ba_df$mean_iop), y = loa_lower - 0.30,
           label = sprintf("-1.96 SD = %+.2f", loa_lower), hjust = 1, colour = "firebrick") +
  labs(
    title    = "Bland-Altman Agreement Plot: Rebound vs. Goldmann Tonometer",
    subtitle = "Green band = +/-2 mmHg clinical tolerance; orange line shows proportional trend",
    x        = "Mean of Two Tonometers (mmHg)",
    y        = "Difference: Rebound - Goldmann (mmHg)"
  )


# ---- 4. Intraclass Correlation (ICC): Consistency vs. Agreement (Slide 312) -
# Clinical optometry scenario (Kraemer & Blasey Ch. 3):
#   Three clinical preceptors independently score 25 OD candidates (0-100) on a
#   contact lens fitting competency exam (`data/09_preceptor_grading_icc.csv`).
#   Preceptor C grades systematically ~6 points harsher than Preceptors A and B!
#
#   - ICC(3,1) [Consistency]: Do preceptors RANK students in the same order? (High!)
#   - ICC(2,1) [Absolute Agreement]: Do they give the EXACT SAME numeric score? (Lower!)

head(preceptor)

# Visualize the systematic rater offset before computing ICC
preceptor |>
  pivot_longer(cols = starts_with("preceptor_"),
               names_to = "rater", values_to = "score") |>
  ggplot(aes(x = rater, y = score, group = candidate_id)) +
  geom_line(alpha = 0.35, colour = "grey50") +
  geom_point(aes(colour = rater), size = 2.2) +
  stat_summary(aes(group = 1), fun = mean, geom = "line", colour = "black", linewidth = 1.2) +
  labs(
    title    = "Preceptor Grading of 25 OD Candidates (Contact Lens Fitting)",
    subtitle = "Preceptor C ranks students consistently (parallel lines) but ~6 points lower",
    x        = "Clinical Preceptor", y = "Competency Score (0-100)"
  ) +
  theme(legend.position = "none")

# Compute all 6 Shrout & Fleiss ICC forms using psych::ICC()
# (Note: if you install `irr`, you can also use `irr::icc(ratings, model="twoway", type="agreement")`.)
ratings_mat <- preceptor |> select(preceptor_A, preceptor_B, preceptor_C)
icc_res <- psych::ICC(ratings_mat)
print(icc_res$results[, c("type", "ICC", "lower bound", "upper bound", "p")])

# Key interpretation:
#   - ICC2  (Two-way random, single rater, ABSOLUTE AGREEMENT): penalizes Preceptor C's -6 pt shift!
#   - ICC3  (Two-way mixed,  single rater, CONSISTENCY)       : ignores constant rater shift -> higher!
#   - ICC2k / ICC3k (Average of k = 3 raters)                 : higher because averaging 3 raters cuts noise!


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Check whether the Bland-Altman differences `ba_df$diff_iop` are roughly
#    normally distributed using a Q-Q plot and Shapiro-Wilk test. Why does
#    normality of differences matter for the +/- 1.96 SD limits?
# 2. Add 6 points to `preceptor$preceptor_C` (calibrating away the harsh-rater
#    bias) and re-run `psych::ICC()`. What happens to ICC2 vs. ICC3?
# 3. Suppose Device Y = 2 * Device X exactly (no noise). What is Pearson r?
#    Do the two devices agree clinically?

# =============================================================================
#  BIOSTATS 2 — SCRIPT 09: BAYES FACTORS FOR CORRELATION, ANOVA & REGRESSION
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_8_9_w_assignment.R (Lecture 9)
#  Datasets: biostats-2/data/full_data.csv (Cone contrast thresholds & RE)
#            biostats-2/data/Monitor_Birds.csv (Chick ocular growth lighting study)
#
#  Topics Covered:
#    1. Interpreting Bayes Factors (BF10 = evidence for H1 over H0; BF01 = 1/BF10)
#    2. Bayesian Correlation (`correlationBF`) & posterior sampling (`posterior()`)
#    3. Directional hypotheses using `nullInterval = c(0, 1)`
#    4. Bayesian Two-Way ANOVA (`anovaBF`) & post-hoc Bayesian t-tests (`ttestBF`)
#    5. Bayesian Model Comparison across all subsets (`regressionBF`)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(BayesFactor)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Load & Prepare Datasets ---------------------------------------------
make_dTransform <- function(path) {
  d_full <- read.csv(path, check.names = TRUE)
  data.frame(
    subject = factor(d_full$subject),
    RE      = d_full$RE,
    A       = log10(d_full$thr1),
    L       = log10(d_full$thr2),
    M       = log10(d_full$thr3),
    Sneg    = log10(d_full$thr4),
    Spos    = log10(d_full$thr5),
    S       = log10(d_full$thr6)
  )
}

d_trans <- make_dTransform("biostats-2/data/full_data.csv")
birds   <- read.csv("biostats-2/data/Monitor_Birds.csv") |>
  mutate(
    condition = factor(condition),
    Light     = factor(Light)
  )


# ---- 2. Bayesian Correlation & Posterior Distribution -----------------------
# Unlike a frequentist p-value (which can never quantify evidence FOR the null),
# a Bayes Factor BF10 directly compares P(Data | H1) / P(Data | H0):
#   BF10 > 3   : moderate evidence for H1
#   BF10 ~ 1   : inconclusive (data don't distinguish H1 from H0)
#   BF10 < 1/3 : moderate evidence FOR the null H0!

cat("--- Two-Sided Bayesian Correlation: RE vs. Achromatic Threshold (A) ---\n")
bf_cor <- BayesFactor::correlationBF(d_trans$RE, d_trans$A)
print(bf_cor)

# Sample from the posterior distribution of rho (analogous to credible intervals!)
post_cor <- BayesFactor::posterior(bf_cor, iterations = 2000, progress = FALSE)
print(summary(post_cor))

# Plot the posterior distribution of rho cleanly with ggplot2
tibble(rho = as.numeric(post_cor[, "rho"])) |>
  ggplot(aes(x = rho)) +
  geom_histogram(aes(y = after_stat(density)), bins = 35,
                 fill = "#0072B2", colour = "white", alpha = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "firebrick", linewidth = 0.9) +
  labs(
    title    = "Posterior Distribution of Correlation rho (RE vs. Achromatic Threshold)",
    subtitle = sprintf("BF10 = %.2f (dashed red line marks rho = 0)",
                       BayesFactor::extractBF(bf_cor)$bf[1]),
    x        = "Correlation (rho)", y = "Posterior Density"
  )

# Directional hypothesis: test specifically whether rho is POSITIVE (0 to 1)
cat("\n--- Directional Bayesian Correlation (`nullInterval = c(0, 1)`) ---\n")
bf_cor_dir <- BayesFactor::correlationBF(d_trans$RE, d_trans$A, nullInterval = c(0, 1))
print(bf_cor_dir)


# ---- 3. Bayesian Two-Way ANOVA & Post-Hoc Bayesian t-Tests ------------------
# Dataset: `Monitor_Birds.csv` (Chick axial length `postAx` by `condition` x `Light`)
# `whichModels = "top"` compares dropping each term from the full model!
cat("\n--- Bayesian Two-Way ANOVA on Chick Axial Length (`postAx`) ---\n")
bf_anova <- BayesFactor::anovaBF(postAx ~ condition * Light, data = birds,
                                 whichModels = "top", progress = FALSE)
print(bf_anova)

# Also inspect all models compared against the intercept-only null model:
bf_anova_all <- BayesFactor::anovaBF(postAx ~ condition * Light, data = birds,
                                     progress = FALSE)
print(bf_anova_all)

# Post-hoc Bayesian t-tests comparing specific lighting conditions
cat("\n--- Post-Hoc Bayesian t-Test: Noise vs. Flicker (`postAx`) ---\n")
print(BayesFactor::ttestBF(
  x = birds$postAx[birds$condition == "Noise"],
  y = birds$postAx[birds$condition == "Flicker"]
))

cat("\n--- Post-Hoc Bayesian t-Test: Yellow vs. White Light (`postAx`) ---\n")
print(BayesFactor::ttestBF(
  x = birds$postAx[birds$Light == "Yellow"],
  y = birds$postAx[birds$Light == "White"]
))


# ---- 4. Bayesian Regression Model Selection (`regressionBF`) ----------------
# Evaluates EVERY possible subset of predictors (2^6 - 1 = 63 models!) and
# ranks them by Bayes Factor against the intercept-only null model!
cat("\n--- Top 6 Bayesian Regression Models for Refractive Error (`RE`) ---\n")
bf_reg <- BayesFactor::regressionBF(RE ~ A + L + M + Sneg + Spos + S,
                                    data = d_trans, progress = FALSE)
print(head(bf_reg, 6))

# Compare the top models directly against the BEST model (`max(bf_reg)`)
# AND against the FULL 6-predictor model (`bf_reg[length(bf_reg)]` — Assignment 4 Q1!):
# Notice how the parsimonious `Spos + S` model beats the cluttered 6-predictor
# full model because Bayes Factors automatically penalize unnecessary complexity!
cat("\n--- Top 5 Models Compared Against the Best Model (`Spos + S`) ---\n")
print(head(bf_reg / max(bf_reg), 5))

cat("\n--- Top 5 Models Compared Against the Full 6-Predictor Model ---\n")
full_idx <- grep("^A \\+ L \\+ M \\+ Sneg \\+ Spos \\+ S$", rownames(as.data.frame(bf_reg)))
print(head(bf_reg / bf_reg[full_idx], 5))


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Compute `correlationBF(d_trans$RE, d_trans$Spos)` and extract the 95%
#    credible interval for `rho` using `quantile(post[, "rho"], c(0.025, 0.975))`.
# 2. Run `anovaBF(postRE ~ condition * Light, data = birds)`. Which factor
#    (condition, Light, or their interaction) receives the strongest evidence?
# 3. Explain in two sentences how a Bayes Factor of BF10 = 0.25 differs from
#    a frequentist non-significant result (p = 0.30).

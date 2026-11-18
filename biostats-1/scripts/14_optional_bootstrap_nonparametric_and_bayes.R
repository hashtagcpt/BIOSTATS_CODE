# =============================================================================
#  SCRIPT 14: THE BOOTSTRAP, NON-PARAMETRIC RANK TESTS & BAYESIAN UPDATING
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Module  : Weeks 9-10 Optional Topic Library: Resampling, Ranks & Bayes
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 385-410)
#  Notes   : [BIOSTATS]-Parametric and Non-parametric Statistics.docx
#  Reuses  : dice_normal_dist_boostrap.R, bootstrap_code.R,
#            Biostats-1-Example-Simple-Bayes-Cards.R
#  Datasets: biostats-1/data/01_student_vision_clinic.csv
#            biostats-1/data/02_iop_clinical_trial.csv
#            biostats-1/data/03_fellow_eyes_axial_length.csv
#            biostats-1/data/06_refraction_biometry.csv
#
#  Topics Covered:
#    1. The Bootstrap from scratch (cards/samples) & with `boot::boot()` (R = 2000)
#    2. Bootstrap confidence intervals for regression slopes (BCa intervals)
#    3. Patient-Cluster Bootstrap for correlated fellow-eye data (Slide 391)
#    4. Non-parametric rank tests: Mann-Whitney U (`wilcox.test`), Wilcoxon
#       signed-rank, and Kruskal-Wallis (`kruskal.test`) + pairwise Holm tests
#    5. Bayesian Reasoning:
#         - Card-deck sequential updating & Bayes Factor (fixed from repo!)
#         - Beta-Binomial Prior -> Likelihood -> Posterior plot
#         - Bayesian t-test & Bayes Factor (`BayesFactor::ttestBF`)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(boot)          # For boot() and boot.ci()
library(BayesFactor)   # For ttestBF()
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

clinic      <- readr::read_csv("biostats-1/data/01_student_vision_clinic.csv", show_col_types = FALSE)
iop_trial   <- readr::read_csv("biostats-1/data/02_iop_clinical_trial.csv", show_col_types = FALSE)
fellow_eyes <- readr::read_csv("biostats-1/data/03_fellow_eyes_axial_length.csv", show_col_types = FALSE)
eye_data    <- readr::read_csv("biostats-1/data/06_refraction_biometry.csv", show_col_types = FALSE)


# ---- 1. The Bootstrap: Resampling with Replacement (Slides 386-390) ---------
# Reused from `dice_normal_dist_boostrap.R`:
# Suppose we want a 95% CI for the median (or mean) of skewed Tear Break-Up
# Time (`tbut_sec`) without assuming Gaussian normality!
tbut_vec <- na.omit(clinic$tbut_sec)

# 1a. One single bootstrap resample (same n, WITH replacement; Slide 390)
one_resample <- sample(tbut_vec, size = length(tbut_vec), replace = TRUE)
cat(sprintf("Original mean TBUT = %.2f s | One bootstrap resample mean = %.2f s\n",
            mean(tbut_vec), mean(one_resample)))

# 1b. Repeat R = 2,000 times using `boot::boot()` (Slide 389: use thousands, not 99!)
boot_mean_fn   <- function(data, idx) mean(data[idx])
boot_median_fn <- function(data, idx) median(data[idx])

boot_mean_res   <- boot::boot(data = tbut_vec, statistic = boot_mean_fn,   R = 2000)
boot_median_res <- boot::boot(data = tbut_vec, statistic = boot_median_fn, R = 2000)

cat("\n--- Bootstrap 95% CIs for Mean TBUT (Percentile & BCa) ---\n")
print(boot::boot.ci(boot_mean_res, type = c("perc", "bca")))
cat("\n--- Bootstrap 95% CI for Median TBUT (Percentile) ---\n")
print(boot::boot.ci(boot_median_res, type = "perc"))

# Plot the empirical bootstrap distribution of the mean
tibble(boot_mean = boot_mean_res$t[, 1]) |>
  ggplot(aes(x = boot_mean)) +
  geom_histogram(bins = 40, fill = "#0072B2", colour = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(tbut_vec), colour = "firebrick", linewidth = 1) +
  labs(
    title    = "Bootstrap Sampling Distribution of Mean TBUT (R = 2,000)",
    subtitle = "Red line = observed sample mean; spread gives empirical SE & CI",
    x        = "Bootstrapped Mean TBUT (seconds)", y = "Count"
  )


# ---- 2. Bootstrap Linear Regression (Slides 393-394 & bootstrap_code.R) -----
# Resample rows of `eye_data`, refit `lm(spherical_eq_d ~ axial_length_mm)`,
# and compute BCa 95% CIs for intercept and slope!
bootReg <- function(data, ind) {
  coef(lm(spherical_eq_d ~ axial_length_mm, data = data[ind, ]))
}

boot_reg_res <- boot::boot(data = eye_data, statistic = bootReg, R = 2000)
cat("\n--- Bootstrap 95% BCa CI for Axial Length Slope (D/mm) ---\n")
print(boot::boot.ci(boot_reg_res, type = "bca", index = 2))
cat("Compare with parametric OLS 95% CI:\n")
print(confint(lm(spherical_eq_d ~ axial_length_mm, data = eye_data))[2, ])


# ---- 3. Cluster Bootstrap for Fellow Eyes (Slide 391) -----------------------
# CRITICAL DESIGN RULE: Resample the INDEPENDENT UNIT!
# For correlated OD & OS eyes (`fellow_eyes`), resample PATIENTS (rows of the
# wide table) with replacement, then take both eyes of each sampled patient.
n_patients <- nrow(fellow_eyes)
R_clust <- 2000
boot_al_means <- replicate(R_clust, {
  sampled_patients <- fellow_eyes[sample(1:n_patients, n_patients, replace = TRUE), ]
  mean(c(sampled_patients$al_od_mm, sampled_patients$al_os_mm))
})
cat(sprintf("\nPatient-cluster bootstrap mean axial length = %.3f mm (95%% CI [%.3f, %.3f])\n",
            mean(c(fellow_eyes$al_od_mm, fellow_eyes$al_os_mm)),
            quantile(boot_al_means, 0.025), quantile(boot_al_means, 0.975)))


# ---- 4. Non-Parametric Rank Tests (Slides 396-401 & Non-Parametric Notes) ---
# Rank tests replace raw measurements with their ordinal ranks (`rank(x)`).
# Useful for ordinal outcomes (like Efron redness grade) or strongly skewed data,
# though independence and clear hypotheses STILL matter!

# 4a. Quick look at rank transformation (Slide 397)
tiny_tbut <- c(4.2, 6.5, 6.5, 11.0, 31.5)   # Notice tied values get average rank (2.5)!
tibble(raw_tbut = tiny_tbut, rank_val = rank(tiny_tbut))

# 4b. Mann-Whitney U / Wilcoxon Rank-Sum Test (2 independent groups, Slide 399):
#     Compare skewed TBUT between Optometry and Graduate_VS students
cat("\n--- Wilcoxon Rank-Sum (Mann-Whitney U): TBUT by Program ---\n")
print(wilcox.test(tbut_sec ~ program, data = clinic, conf.int = TRUE))

# 4c. Wilcoxon Signed-Rank Test (paired data):
#     Compare within-student Near vs. Far logMAR acuity
cat("\n--- Wilcoxon Signed-Rank (Paired): Near vs. Far logMAR ---\n")
print(wilcox.test(clinic$near_logmar, clinic$far_logmar, paired = TRUE, conf.int = TRUE))

# 4d. Kruskal-Wallis Test (non-parametric one-way ANOVA, Slide 401):
#     Compare Efron redness grade (0-4 ordinal scale) across 4 eye-color groups
#     or across Dry Eye Symptom groups / years in program!
cat("\n--- Kruskal-Wallis Test: TBUT across Student Program Years (1-4) ---\n")
print(kruskal.test(tbut_sec ~ factor(year), data = clinic))

# Follow-up pairwise Wilcoxon tests with Holm multiplicity correction:
print(pairwise.wilcox.test(clinic$tbut_sec, factor(clinic$year), p.adjust.method = "holm"))


# ---- 5. Bayesian Reasoning: Updating, Cards & Bayes Factors (Slides 402-409)
# 5a. Card-Deck Bayesian Updating (Reused & fixed from Biostats-1-Example-Simple-Bayes-Cards.R)
#     Scenario: Someone secretly removed either 1 Red suit (13 cards) OR 1 Black
#     suit from a 52-card deck, leaving 39 cards. We draw cards WITH replacement
#     and update P(Red Suit Removed | cards seen) via Bayes' Theorem!

bayes_update <- function(prior, lik_H1, lik_H2) {
  (prior * lik_H1) / ((prior * lik_H1) + ((1 - prior) * lik_H2))
}

# Scripted classroom trace: suppose we draw B, B, R, B, B, B
drawn_cards <- c("B", "B", "R", "B", "B", "B")
p_red_removed <- 0.50
p_blk_removed <- 0.50
p_R_given_RedRem <- 13 / 39   # Only 13 red cards left out of 39!
p_R_given_BlkRem <- 26 / 39   # All 26 red cards still in deck!

trace_rows <- list(tibble(draw = 0, card = "Prior",
                          P_RedRemoved = p_red_removed,
                          P_BlkRemoved = p_blk_removed,
                          BF_Red_vs_Blk = p_red_removed / p_blk_removed))

for (i in seq_along(drawn_cards)) {
  card <- drawn_cards[i]
  if (card == "R") {
    p_red_removed <- bayes_update(p_red_removed, p_R_given_RedRem, p_R_given_BlkRem)
  } else {
    p_red_removed <- bayes_update(p_red_removed, 1 - p_R_given_RedRem, 1 - p_R_given_BlkRem)
  }
  p_blk_removed <- 1 - p_red_removed
  trace_rows[[i + 1]] <- tibble(
    draw          = i,
    card          = card,
    P_RedRemoved  = p_red_removed,
    P_BlkRemoved  = p_blk_removed,
    BF_Red_vs_Blk = p_red_removed / p_blk_removed
  )
}
cat("\n--- Sequential Bayesian Updating on Card Draws (B, B, R, B, B, B) ---\n")
print(bind_rows(trace_rows))

# Interactive version preserved for live classroom use! Call `runCardBayes()` in Console.
runCardBayes <- function() {
  p_red <- 0.50
  repeat {
    card <- toupper(readline(prompt = "Enter card drawn (R or B), or Q to quit: "))
    if (card == "Q") break
    if (!(card %in% c("R", "B"))) { cat("Please enter R, B, or Q.\n"); next }
    p_red <- if (card == "R") bayes_update(p_red, 13/39, 26/39) else bayes_update(p_red, 26/39, 13/39)
    cat(sprintf("P(Red removed | data) = %.4f | Bayes Factor (Red vs Black) = %.2f\n",
                p_red, p_red / (1 - p_red)))
  }
  cat("Session ended.\n")
}

# 5b. Beta-Binomial Prior -> Likelihood -> Posterior Visualization (Slides 407-408)
#     Suppose our prior belief about a new dry-eye drop's response rate is
#     Beta(alpha = 4, beta = 4) [centered at 50%, modest uncertainty].
#     In a pilot trial, 18 of 25 patients respond! Posterior = Beta(4 + 18, 4 + 7).
theta <- seq(0.001, 0.999, length.out = 400)
bayes_df <- bind_rows(
  tibble(theta = theta, density = dbeta(theta, 4, 4),        curve = "1. Prior: Beta(4, 4)"),
  tibble(theta = theta, density = dbeta(theta, 18 + 1, 7 + 1), curve = "2. Likelihood (18/25 successes)"),
  tibble(theta = theta, density = dbeta(theta, 4 + 18, 4 + 7), curve = "3. Posterior: Beta(22, 11)")
)

ggplot(bayes_df, aes(x = theta, y = density, colour = curve)) +
  geom_line(linewidth = 1.1) +
  scale_colour_manual(values = c("grey50", "#E69F00", "#0072B2"), name = NULL) +
  labs(
    title    = "Bayesian Updating: Prior + Likelihood -> Posterior",
    subtitle = "Posterior compromises between prior belief (50%) and observed data (72%)",
    x        = "True Clinical Response Rate (theta)", y = "Density"
  ) +
  theme(legend.position = "bottom")

# 5c. Bayesian Independent Two-Sample t-Test via BayesFactor (Slide 406):
#     BF10 tells us how many times more likely the data are under H1 than H0!
cat("\n--- Bayesian t-Test (Drop_A vs. Drop_B IOP Change) ---\n")
bf_iop <- BayesFactor::ttestBF(formula = iop_change ~ treatment, data = as.data.frame(iop_trial))
print(bf_iop)


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Compute a 95% BCa bootstrap CI for the Pearson correlation `cor(x, y)`
#    between `axial_length_mm` and `spherical_eq_d` in `eye_data`.
# 2. In Section 5b, change the prior from Beta(4, 4) to a strong skeptical prior
#    Beta(4, 36) [centered at 10%]. How much does the posterior shift?
# 3. Run `runCardBayes()` interactively in the RStudio Console and see how many
#    consecutive Red cards it takes for the Bayes Factor to exceed 10.

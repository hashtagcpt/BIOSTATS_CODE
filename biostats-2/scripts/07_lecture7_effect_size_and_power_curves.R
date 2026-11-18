# =============================================================================
#  BIOSTATS 2 — SCRIPT 07: EFFECT SIZES & PRE-PLANNED POWER CURVES
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_7.R
#  Datasets: MASS::genotype + biostats-2/data/Monitor_Birds.csv
#
#  Topics Covered:
#    1. Cohen's d (`effsize::cohen.d`) & bootstrapping a CI for Cohen's d
#    2. Two-way ANOVA effect sizes (`lsr::etaSquared`)
#    3. Pre-planned power curves: required N vs. effect size (Cohen's d)
#    4. Multi-curve ANOVA power planning (comparing 50% vs. 80% vs. 90% power!)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(effsize)     # For cohen.d()
library(lsr)         # For etaSquared()
library(pwr)         # For pwr.t.test(), pwr.anova.test()
library(boot)        # For bootstrapping Cohen's d
# Note: We load MASS::genotype via data(..., package = "MASS") below rather than
# library(MASS), so MASS::select() never masks dplyr::select() in your RStudio session!
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Cohen's d & Bootstrap CI for Effect Size ----------------------------
# Example 1: Simulated two-group comparison
sample_1 <- rnorm(30, mean = 10.76, sd = 1.5)
sample_2 <- rnorm(30, mean = 10.50, sd = 1.5)
print(effsize::cohen.d(sample_1, sample_2))

# Example 2 (Solves Lecture 7 Exercise 1):
# Bootstrap a 95% CI for Cohen's d comparing White vs. Yellow light within the
# "Noise" condition of `Monitor_Birds.csv` on `postRE` (post-exposure refraction)!
birds <- readr::read_csv("biostats-2/data/Monitor_Birds.csv", show_col_types = FALSE) |>
  filter(condition == "Noise", Light %in% c("White", "Yellow"))

boot_d_fn <- function(data, idx) {
  d_sub <- data[idx, ]
  # Handle rare edge resample missing a group gracefully
  if (n_distinct(d_sub$Light) < 2) return(NA_real_)
  effsize::cohen.d(postRE ~ factor(Light), data = d_sub)$estimate
}

boot_d <- boot::boot(data = birds, statistic = boot_d_fn, R = 2000)
cat("\n--- Bootstrap 95% Percentile CI for Cohen's d (Noise: White vs Yellow, postRE) ---\n")
cat(sprintf("Observed Cohen's d = %.3f\n", boot_d$t0))
print(boot::boot.ci(boot_d, type = "perc"))


# ---- 2. Two-Way ANOVA Effect Size: Eta-Squared & Partial Eta-Squared --------
# Reused from B2_Lecture_7.R using MASS::genotype (loaded cleanly without attaching MASS)
data("genotype", package = "MASS")
anova_geno <- aov(Wt ~ Litter * Mother, data = genotype)
cat("\n--- Two-Way ANOVA (MASS::genotype) ---\n")
print(summary(anova_geno))
cat("\n--- Eta-Squared & Partial Eta-Squared (lsr::etaSquared) ---\n")
print(lsr::etaSquared(anova_geno))


# ---- 3. Pre-Planned Power Curve: Required N vs. Cohen's d -------------------
# Before collecting data, we rarely know the exact true effect size.
# Instead of picking ONE magic guess, compute required N across a plausible
# range of Cohen's d (e.g., 0.25 = minimally interesting to 0.80 = optimistic)!

d_grid <- tibble(cohens_d = seq(0.25, 0.80, length.out = 200)) |>
  mutate(
    n_two_sample = map_dbl(cohens_d, \(d) pwr::pwr.t.test(d = d, power = 0.80, sig.level = 0.05, type = "two.sample")$n),
    n_paired     = map_dbl(cohens_d, \(d) pwr::pwr.t.test(d = d, power = 0.80, sig.level = 0.05, type = "paired")$n)
  ) |>
  pivot_longer(cols = c(n_two_sample, n_paired),
               names_to = "design", values_to = "n_required") |>
  mutate(design = dplyr::case_match(
    design,
    "n_two_sample" ~ "Two-Sample Independent (n per group)",
    "n_paired"     ~ "Paired Within-Subject (total pairs)"
  ))

ggplot(d_grid, aes(x = cohens_d, y = n_required, colour = design)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(values = c("#0072B2", "#009E73"), name = NULL) +
  labs(
    title    = "Pre-Planned Power Analysis: Required Sample Size vs. Effect Size",
    subtitle = "Target: 80% power at two-sided alpha = 0.05 (small effects require dramatically more N!)",
    x        = "Expected Effect Size (Cohen's d)",
    y        = "Required Sample Size (n)"
  ) +
  theme(legend.position = "bottom")


# ---- 4. Multi-Level ANOVA Power Curves (Solves Lecture 7 Exercise 2!) -------
# Compare required n per group for a 4-group One-Way ANOVA across Cohen's f
# from 0.15 to 0.50 at three target power levels (50%, 80%, 90%):

anova_power_grid <- expand_grid(
  cohens_f     = seq(0.15, 0.50, by = 0.01),
  target_power = c(0.50, 0.80, 0.90)
) |>
  mutate(
    n_per_group = map2_dbl(cohens_f, target_power, \(f, pw) {
      pwr::pwr.anova.test(k = 4, f = f, sig.level = 0.05, power = pw)$n
    }),
    power_label = factor(paste0(round(target_power * 100), "% Power"),
                         levels = c("50% Power", "80% Power", "90% Power"))
  )

ggplot(anova_power_grid, aes(x = cohens_f, y = n_per_group, colour = power_label)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(values = c("50% Power" = "#E69F00",
                                 "80% Power" = "#0072B2",
                                 "90% Power" = "#D55E00"),
                      name = "Target Power") +
  labs(
    title    = "One-Way ANOVA (k = 4 Groups): Required n per Group vs. Cohen's f",
    subtitle = "Comparing 50%, 80%, and 90% power curves at alpha = 0.05",
    x        = "Effect Size (Cohen's f)",
    y        = "Required Subjects per Group (n)"
  ) +
  theme(legend.position = "bottom")


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Repeat the bootstrap Cohen's d in Section 1 for `postAx` (axial length)
#    in `Monitor_Birds.csv` (Noise: White vs. Yellow).
# 2. Compute the minimum detectable Cohen's f for a 3-group ANOVA if your budget
#    caps enrollment at n = 15 patients per group (80% power, alpha = 0.05).
# 3. How does adding a 15% dropout buffer (`ceiling(n / 0.85)`) shift the 80%
#    curve in Section 4?

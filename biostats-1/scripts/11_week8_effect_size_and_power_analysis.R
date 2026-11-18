# =============================================================================
#  SCRIPT 11: EFFECT SIZES & A PRIORI POWER ANALYSIS
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 8 - Effect Size & Power (+ Kraemer & Blasey Ch. 2, 7, 8)
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 297-346, 449-454)
#  Notes   : [BIOSTATS]-NOTES-Effect Size.docx, [BIOSTATS]-NOTES-Power.docx
#  Reuses  : Biostats-1-Examples-11-4-19.R, Biostats-1-Examples-10-29-19.R
#  Datasets: biostats-1/data/02_iop_clinical_trial.csv
#            biostats-1/data/07_contact_lens_comfort.csv
#
#  Topics Covered:
#    1. Unstandardized (clinical units) vs. Standardized effect sizes:
#       Cohen's d, Hedges' g, Glass's Delta, eta^2, partial eta^2, omega^2, Cohen's f
#    2. A priori power & sample size planning in R (`power.t.test`, `pwr` package):
#       t-tests (+ attrition inflation), ANOVA, correlation, two proportions (NECO vs. BU),
#       and chi-squared tests
#    3. Power curves & how measurement noise ("cups of coffee") inflates N
#    4. Variance homogeneity test (`var.test`) & why dichotomizing destroys power
#    5. Why post-hoc ("observed") power is circular and meaningless (Slide 310)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(effsize)     # For cohen.d()
library(lsr)         # For etaSquared()
library(pwr)         # For pwr.t.test(), pwr.anova.test(), pwr.r.test(), pwr.2p.test(), pwr.chisq.test()
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

iop_trial <- readr::read_csv("biostats-1/data/02_iop_clinical_trial.csv", show_col_types = FALSE)
lens_df   <- readr::read_csv("biostats-1/data/07_contact_lens_comfort.csv", show_col_types = FALSE)


# ---- 1. Effect Sizes for Two Groups: Cohen's d & Hedges' g (Slides 333, 340)
# Unstandardized effect size = difference in PHYSICAL/CLINICAL UNITS (e.g., mmHg, Diopters).
# Standardized effect size (Cohen's d) = difference divided by pooled SD (dimensionless).

change_A <- iop_trial$iop_change[iop_trial$treatment == "Drop_A"]
change_B <- iop_trial$iop_change[iop_trial$treatment == "Drop_B"]

# Manual Cohen's d (pooled SD)
n1 <- length(change_A); n2 <- length(change_B)
s_pooled <- sqrt(((n1 - 1) * var(change_A) + (n2 - 1) * var(change_B)) / (n1 + n2 - 2))
d_manual <- (mean(change_A) - mean(change_B)) / s_pooled
cat(sprintf("Unstandardized diff (A - B) = %.2f mmHg | Pooled SD = %.2f mmHg\n",
            mean(change_A) - mean(change_B), s_pooled))
cat(sprintf("Manual Cohen's d            = %.3f\n", d_manual))

# Package verification: Cohen's d and small-sample bias-corrected Hedges' g
print(effsize::cohen.d(change_A, change_B))
print(effsize::cohen.d(change_A, change_B, hedges.correction = TRUE))

# One-sample Cohen's d (exact example from Slide 333)
slide_vec <- c(2, 5, 12, 11, -2, 16, -22, 7, -7, 15, -5, 15)
cat("\n--- Slide 333 One-Sample Cohen's d & t-test ---\n")
print(effsize::cohen.d(slide_vec, f = NA))
print(t.test(slide_vec))


# ---- 2. Effect Sizes for ANOVA: eta^2, partial eta^2, omega^2 & Cohen's f ---
# Reused from Biostats-1-Examples-11-4-19.R & NOTES-Effect Size:
#   - eta^2         = SS_effect / SS_total (sample proportion of variance explained; slightly upward biased)
#   - partial eta^2 = SS_effect / (SS_effect + SS_error)
#   - omega^2       = (SS_effect - df_effect * MS_error) / (SS_total + MS_error)  [less biased!]
#   - Cohen's f     = sqrt(eta^2 / (1 - eta^2))  [input required by pwr.anova.test()!]

fit_clarity <- aov(clarity_score ~ lens_type, data = lens_df)
anova_tab   <- summary(fit_clarity)[[1]]

eta_mat <- lsr::etaSquared(fit_clarity)
print(eta_mat)

ss_eff   <- anova_tab$`Sum Sq`[1]
df_eff   <- anova_tab$Df[1]
ss_err   <- anova_tab$`Sum Sq`[2]
ms_err   <- anova_tab$`Mean Sq`[2]
ss_tot   <- ss_eff + ss_err

eta2     <- ss_eff / ss_tot
omega2   <- (ss_eff - df_eff * ms_err) / (ss_tot + ms_err)
cohens_f <- sqrt(eta2 / (1 - eta2))

cat(sprintf("\nClarity One-Way ANOVA: eta^2 = %.3f | omega^2 = %.3f | Cohen's f = %.3f\n",
            eta2, omega2, cohens_f))

# Two-way ANOVA effect sizes (Discomfort ~ Lens Type * Age Group)
fit_2way <- aov(discomfort_score ~ lens_type * age_group, data = lens_df)
cat("\nTwo-Way ANOVA eta^2 and partial eta^2:\n")
print(lsr::etaSquared(fit_2way))


# ---- 3. A Priori Power & Sample Size Planning (Slides 309, 334-345, 450) ----
# Supply any THREE of (n, effect size, sig.level, power) and R solves for the 4th!

# 3a. Worked IOP Clinical Trial Planning Example (Slide 336):
#     Target clinically meaningful difference = 2.0 mmHg, common SD = 3.0 mmHg
#     (so Cohen's d = 2/3 = 0.667), two-sided alpha = 0.05, power = 80%.
plan_iop <- power.t.test(delta = 2.0, sd = 3.0, sig.level = 0.05, power = 0.80,
                         type = "two.sample", alternative = "two.sided")
n_per_group <- ceiling(plan_iop$n)
attrition_r <- 0.15   # Expect 15% loss to follow-up
n_inflated  <- ceiling(n_per_group / (1 - attrition_r))

cat("\n--- Slide 336 IOP Trial Sample Size Plan ---\n")
cat(sprintf("Required per group (exact = %.2f) -> %d per group (%d total)\n",
            plan_iop$n, n_per_group, 2 * n_per_group))
cat(sprintf("Inflated for %.0f%% anticipated attrition -> %d per group (%d total)\n",
            100 * attrition_r, n_inflated, 2 * n_inflated))

# 3b. Slide 334 / 343 t-test power examples:
pwr::pwr.t.test(n = 12, d = 0.30, sig.level = 0.05, type = "two.sample")   # Solve for power
pwr::pwr.t.test(d = 0.30, sig.level = 0.05, power = 0.80, type = "two.sample") # Solve for n

# 3c. One-Way ANOVA power examples (Slides 309, 341 & Biostats-1-Examples-11-4-19.R):
pwr::pwr.anova.test(k = 3, f = 0.50, n = 30, sig.level = 0.05)             # Slide 309
pwr::pwr.anova.test(k = 4, f = 0.25, sig.level = 0.05, power = 0.80)       # Required n per group
pwr::pwr.anova.test(k = 4, n = 12,   sig.level = 0.05, power = 0.80)       # Minimum detectable f

# 3d. Correlation power (NOTES-Power): expected r = 0.30, 80% power
pwr::pwr.r.test(r = 0.30, sig.level = 0.05, power = 0.80)

# 3e. Two-Proportion Power Reality Check — NECO vs. BU Study (Slide 450):
#     Cohen's h = 2*asin(sqrt(p1)) - 2*asin(sqrt(p2))
cat("\n--- Slide 450: Iterating Two-Proportion Power (NECO vs. BU) ---\n")
cat("1) Initial plan (n = 100/group) detects h =",
    round(pwr::pwr.2p.test(n = 100, sig.level = 0.05, power = 0.80)$h, 3), "\n")
cat("2) Small effect (h = 0.10) requires n =",
    ceiling(pwr::pwr.2p.test(h = 0.10, sig.level = 0.05, power = 0.80)$n), "per group!\n")
cat("3) Feasible cap (n = 200/group) detects h =",
    round(pwr::pwr.2p.test(n = 200, sig.level = 0.05, power = 0.80)$h, 3), "\n")

# 3f. Chi-squared power for UV exposure vs. cataracts (NOTES-Power: 60% vs. 40%):
h_uv <- pwr::ES.h(p1 = 0.60, p2 = 0.40)
pwr::pwr.2p.test(h = h_uv, sig.level = 0.05, power = 0.80)


# ---- 4. Power Curves & How Measurement Noise Inflates N (Slide 308) ---------
# "The Coffee Thought Experiment" (Kraemer & Blasey Ch. 2):
# Suppose a true treatment reduces IOP by 1.5 mmHg.
#   - High-precision instrument (SD = 1.8 mmHg) -> d = 0.83 (LARGE) -> small N!
#   - Moderate instrument       (SD = 3.0 mmHg) -> d = 0.50 (MEDIUM)
#   - Noisy self-report         (SD = 5.0 mmHg) -> d = 0.30 (SMALL) -> huge N!

power_grid <- expand_grid(
  n_per_group = seq(5, 180, by = 5),
  noise_sd    = c(1.8, 3.0, 5.0)
) |>
  mutate(
    cohens_d = 1.5 / noise_sd,
    label    = sprintf("SD = %.1f mmHg (d = %.2f)", noise_sd, cohens_d),
    power    = map2_dbl(n_per_group, cohens_d,
                        \(n, d) pwr::pwr.t.test(n = n, d = d, sig.level = 0.05)$power)
  )

ggplot(power_grid, aes(x = n_per_group, y = power, colour = label)) +
  geom_hline(yintercept = 0.80, linetype = "dashed", colour = "grey40") +
  geom_line(linewidth = 1.1) +
  scale_colour_manual(values = c("#009E73", "#0072B2", "#D55E00"),
                      name = "Measurement Precision (for true 1.5 mmHg effect)") +
  labs(
    title    = "Better Measurement Precision Dramatically Reduces Required Sample Size",
    subtitle = "Dashed line = 80% target power (two-sample t-test, two-sided alpha = 0.05)",
    x        = "Sample Size per Group (n)", y = "Statistical Power (1 - beta)"
  ) +
  theme(legend.position = "bottom")


# ---- 5. Variance Test & Why Dichotomizing Destroys Power (Slide 451 & 454) --
# Kraemer & Blasey Ch. 7-8:
#   - `var.test(x, y)` tests equality of variances via an F-ratio (note: sensitive to non-normality).
#   - Never dichotomize a continuous clinical outcome (e.g., IOP > 21 Yes/No) if
#     you have the continuous measurement — throwing away information slashes power!

cat("\n--- F-test of Variance Ratio (Drop_A vs Drop_B IOP change) ---\n")
print(var.test(change_A, change_B))

# Simulation: Compare power of continuous t-test vs. dichotomized proportion test
# when true difference is 1.5 mmHg (SD = 3.0, n = 50 per group)
n_sim_d <- 1000
dichot_sim <- replicate(n_sim_d, {
  g1 <- rnorm(50, mean = 19.0, sd = 3.0)
  g2 <- rnorm(50, mean = 20.5, sd = 3.0)
  p_cont <- t.test(g1, g2)$p.value
  # Dichotomize at 20 mmHg ("elevated" vs "normal")
  p_bin  <- prop.test(c(sum(g1 > 20), sum(g2 > 20)), c(50, 50), correct = FALSE)$p.value
  c(continuous = p_cont < 0.05, dichotomized = p_bin < 0.05)
})
cat(sprintf("\nSimulated power (n = 50/group, delta = 1.5, SD = 3.0):\n  Continuous t-test      : %.1f%%\n  Dichotomized prop.test : %.1f%% (massive loss of power!)\n",
            100 * mean(dichot_sim["continuous", ]),
            100 * mean(dichot_sim["dichotomized", ])))


# ---- 6. Why Post-Hoc ("Observed") Power Is Circular (Slide 310) -------------
# Computing power AFTER data collection using the observed sample effect size
# adds ZERO new information — it is a strict 1-to-1 mathematical transform of p!
# Whenever p > 0.05, post-hoc power is AUTOMATICALLY <= ~50%!
obs_p_grid <- tibble(t_obs = seq(0.1, 4.0, by = 0.05)) |>
  mutate(
    df             = 58,
    p_value        = 2 * pt(-t_obs, df = df),
    d_obs          = t_obs * sqrt(2 / 30),
    post_hoc_power = map_dbl(d_obs, \(d) pwr::pwr.t.test(n = 30, d = d, sig.level = 0.05)$power)
  )

ggplot(obs_p_grid, aes(x = p_value, y = post_hoc_power)) +
  geom_vline(xintercept = 0.05, linetype = "dashed", colour = "firebrick") +
  geom_line(linewidth = 1.2, colour = "#0072B2") +
  labs(
    title    = "Why Post-Hoc Power Is Redundant (Slide 310)",
    subtitle = "Observed power is a deterministic 1-to-1 function of the p-value; always plan power a priori!",
    x        = "Observed Two-Sided p-Value", y = "Post-Hoc ('Observed') Power"
  )


# ---- 7. Try It Yourself (Exercises) -----------------------------------------
# 1. A myopia trial aims to detect a 0.35 D difference in 2-year progression
#    with SD = 0.65 D at 90% power (two-sided alpha = 0.05) and expects 20%
#    dropout. How many children must be enrolled per arm?
# 2. For a 3-arm contact lens ANOVA with Cohen's f = 0.25 and 80% power, how
#    many patients per arm are needed? What if f = 0.40?
# 3. Calculate the minimum clinically relevant Cohen's d for an experiment you
#    might propose in your Final Paper, and plot its power curve from n = 10 to 100.

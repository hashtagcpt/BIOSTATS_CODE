# =============================================================================
#  SCRIPT 10: ONE-WAY & TWO-WAY ANOVA, CONTRASTS & MULTIPLE COMPARISONS
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 7 - ANOVA & the General Linear Model
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 238-296)
#  Notes   : [BIOSTATS]-NOTES-Analysis of Variance.docx
#  Reuses  : Biostats-1-Examples-10-29-19.R, Biostats-1-Examples-11-4-19.R
#  Datasets: biostats-1/data/07_contact_lens_comfort.csv
#
#  Topics Covered:
#    1. Why multiple unadjusted t-tests inflate Family-Wise Error Rate (FWER)
#    2. Worked One-Way ANOVA by hand (exact Slide 261-264 numbers)
#    3. One-Way ANOVA in R: aov(), lm() unification (R^2 = eta^2), Levene & Welch
#    4. Two-Way Factorial ANOVA & interaction plots (Lens Type x Age Group)
#    5. Post-hoc tests & multiplicity control:
#         - Tukey's Honestly Significant Difference (TukeyHSD)
#         - Planned contrasts (higher power than all-pairs!)
#         - p.adjust(): Bonferroni, Holm (FWER) vs. Benjamini-Hochberg (FDR)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
library(car)         # For car::leveneTest()
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

lens_df <- readr::read_csv("biostats-1/data/07_contact_lens_comfort.csv", show_col_types = FALSE) |>
  mutate(
    lens_type = factor(lens_type, levels = c("Soft", "Hybrid", "RGP")),
    age_group = factor(age_group, levels = c("Young", "Presbyopic"))
  )
glimpse(lens_df)


# ---- 1. Why Multiple t-Tests Inflate Type I Error (Slides 253, 271) ---------
# With k groups, there are m = k*(k - 1)/2 pairwise comparisons.
# Under the global null (all group means identical), running m independent
# tests at alpha = 0.05 gives FWER = 1 - (1 - 0.05)^m.
fwer_table <- tibble(k_groups = 2:10) |>
  mutate(
    m_pairs            = choose(k_groups, 2),
    fwer_indep_approx  = 1 - (1 - 0.05)^m_pairs,
    bonferroni_alpha   = 0.05 / m_pairs
  )
print(fwer_table)

# Verify by simulation with k = 4 null groups (6 pairwise t-tests per study!)
n_null_studies <- 2000
false_alarm_any_t <- replicate(n_null_studies, {
  g <- factor(rep(1:4, each = 15))
  y <- rnorm(60, mean = 0, sd = 1)
  p_pairs <- pairwise.t.test(y, g, p.adjust.method = "none")$p.value
  any(p_pairs < 0.05, na.rm = TRUE)
})
false_alarm_anova <- replicate(n_null_studies, {
  g <- factor(rep(1:4, each = 15))
  y <- rnorm(60, mean = 0, sd = 1)
  summary(aov(y ~ g))[[1]]$`Pr(>F)`[1] < 0.05
})
cat(sprintf("\nUnder true H0 (4 groups): Unadjusted pairwise t-tests reject %.1f%% of studies!\n",
            100 * mean(false_alarm_any_t)))
cat(sprintf("Under true H0 (4 groups): Omnibus ANOVA F-test rejects       %.1f%% (controls alpha = 5%%!)\n",
            100 * mean(false_alarm_anova)))


# ---- 2. Worked One-Way ANOVA by Hand (Exact Numbers from Slides 261-264) ----
# Four groups, n = 10 each; sample means = (10, 20, 15, 15); SDs = (5, 4, 6, 5)
grp_means <- c(10, 20, 15, 15)
grp_sds   <- c(5, 4, 6, 5)
grp_n     <- c(10, 10, 10, 10)
k_grp     <- length(grp_means)
N_tot     <- sum(grp_n)

grand_mean <- sum(grp_n * grp_means) / N_tot          # 15
SS_between <- sum(grp_n * (grp_means - grand_mean)^2) # 500
SS_within  <- sum((grp_n - 1) * grp_sds^2)            # 918
SS_total   <- SS_between + SS_within                  # 1418

df_between <- k_grp - 1                               # 3
df_within  <- N_tot - k_grp                           # 36
MS_between <- SS_between / df_between                 # 166.67
MS_within  <- SS_within  / df_within                  # 25.50
F_obs      <- MS_between / MS_within                  # 6.536
p_val      <- pf(F_obs, df1 = df_between, df2 = df_within, lower.tail = FALSE)
F_crit_05  <- qf(0.95,  df1 = df_between, df2 = df_within)
eta2_hand  <- SS_between / SS_total                   # R^2 "slyly hanging out in the table" (Slide 269!)

cat("\n--- Hand-Calculated ANOVA Table (Slides 261-264) ---\n")
cat(sprintf("SS_between = %.1f (df = %d, MS = %.2f)\n", SS_between, df_between, MS_between))
cat(sprintf("SS_within  = %.1f (df = %d, MS = %.2f)\n", SS_within,  df_within,  MS_within))
cat(sprintf("F_observed = %.3f (F_crit = %.3f) | p = %.5f | R^2 = eta^2 = %.3f\n",
            F_obs, F_crit_05, p_val, eta2_hand))


# ---- 3. One-Way ANOVA in R & Unification with lm() (Slides 244-270) ---------
# Clinical question: Does vision clarity score (0-100) differ among Soft,
# Hybrid, and RGP contact lenses? (`biostats-1/data/07_contact_lens_comfort.csv`)

# Plot first!
ggplot(lens_df, aes(x = lens_type, y = clarity_score, fill = lens_type)) +
  geom_boxplot(width = 0.45, alpha = 0.55, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.75) +
  scale_fill_manual(values = c("Soft" = "#0072B2", "Hybrid" = "#009E73", "RGP" = "#D55E00")) +
  labs(
    title    = "Visual Clarity Score by Contact Lens Type",
    subtitle = "Inspect group medians, spread, and outliers before fitting ANOVA",
    x        = "Contact Lens Design", y = "Clarity Score (0-100)"
  ) +
  theme(legend.position = "none")

# Fit One-Way ANOVA via aov() AND via lm() to prove they are the SAME linear model!
fit_aov <- aov(clarity_score ~ lens_type, data = lens_df)
fit_lm  <- lm(clarity_score  ~ lens_type, data = lens_df)

cat("\n--- One-Way ANOVA via aov() ---\n")
print(summary(fit_aov))

cat("\n--- Same Model via lm(): Check F-statistic and R^2! ---\n")
print(summary(fit_lm))

# Check equal-variance assumption (Levene's test) & Welch's robust one-way ANOVA
cat("\nLevene's test for homogeneity of variance:\n")
print(car::leveneTest(clarity_score ~ lens_type, data = lens_df))

cat("\nWelch's One-Way ANOVA (does NOT assume equal variances):\n")
print(oneway.test(clarity_score ~ lens_type, data = lens_df, var.equal = FALSE))


# ---- 4. Two-Way Factorial ANOVA & Interaction Plots (Slides 271-279) --------
# Clinical question (NOTES-Analysis of Variance):
#   How do Contact Lens Type (Soft, Hybrid, RGP) AND Age Group (Young, Presbyopic)
#   affect 8-hour eye discomfort (0-10)? Does the best lens DEPEND on age group?

cell_summary <- lens_df |>
  group_by(age_group, lens_type) |>
  summarize(
    n    = n(),
    mean = mean(discomfort_score),
    sd   = sd(discomfort_score),
    se   = sd / sqrt(n),
    .groups = "drop"
  )
print(cell_summary)

# Interaction plot (Slides 274 & 278): non-parallel / crossing lines signal interaction!
ggplot(cell_summary, aes(x = lens_type, y = mean, colour = age_group, group = age_group)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 3.2) +
  geom_errorbar(aes(ymin = mean - 1.96 * se, ymax = mean + 1.96 * se),
                width = 0.12, linewidth = 0.8) +
  scale_colour_manual(values = c("Young" = "#0072B2", "Presbyopic" = "#D55E00"),
                      name = "Age Group") +
  labs(
    title    = "Two-Way Interaction: Lens Type x Age Group on 8-Hour Discomfort",
    subtitle = "Points = cell means +/- 95% CI. Soft lenses feel great in young wearers but worse in presbyopes!",
    x        = "Contact Lens Type", y = "Discomfort Score (0 = none, 10 = severe)"
  ) +
  theme(legend.position = "top")

# Fit balanced Two-Way Factorial ANOVA (`lens_type * age_group` = main effects + interaction)
fit_2way <- aov(discomfort_score ~ lens_type * age_group, data = lens_df)
cat("\n--- Two-Way Factorial ANOVA Table ---\n")
print(summary(fit_2way))
# Because the interaction F_AB is strongly significant, interpret lens effects
# CONDITIONALLY within each age group rather than quoting main effects alone!


# ---- 5. Post-Hoc Tests, Planned Contrasts & p.adjust() (Slides 280-296) -----
# 5a. Tukey's Honestly Significant Difference (TukeyHSD) on clarity_score
#     Controls Family-Wise Error Rate across all pairwise comparisons simultaneously.
cat("\n--- Tukey HSD Pairwise Comparisons (Clarity Score) ---\n")
tukey_clarity <- TukeyHSD(fit_aov)
print(tukey_clarity)
broom::tidy(tukey_clarity)

# 5b. Planned Orthogonal Contrasts (Slides 294-295, 316):
#     Suppose BEFORE seeing data we had two focused questions:
#       Contrast 1: Soft vs. Rigid-containing (Hybrid + RGP)  -> c(-2, +1, +1)
#       Contrast 2: Hybrid vs. RGP                            -> c( 0, -1, +1)
lens_contrasts <- lens_df
contrasts(lens_contrasts$lens_type) <- cbind(
  Soft_vs_Rigid = c(-2,  1, 1),
  Hybrid_vs_RGP = c( 0, -1, 1)
)
fit_planned <- aov(clarity_score ~ lens_type, data = lens_contrasts)
cat("\n--- Planned Orthogonal Contrasts ---\n")
print(summary(fit_planned, split = list(lens_type = list(
  "Soft vs. (Hybrid & RGP)" = 1,
  "Hybrid vs. RGP"          = 2
))))

# 5c. Comparing Multiplicity Corrections via p.adjust() (Slides 284-291)
# Exact p-value vector from Slide 291 + a 6-test clinical family:
slide_p <- c(0.10, 0.05, 0.01, 0.002)
tibble(
  raw_p      = slide_p,
  bonferroni = p.adjust(slide_p, method = "bonferroni"),  # Controls FWER (conservative)
  holm       = p.adjust(slide_p, method = "holm"),        # Controls FWER (uniformly >= Bonferroni power!)
  bh_fdr     = p.adjust(slide_p, method = "BH")           # Controls False Discovery Rate (step-up)
)

# Verify the Benjamini-Hochberg step-up rule manually at q = 0.05 (Slide 287):
p_sorted <- sort(slide_p)
m_tests  <- length(p_sorted)
q_target <- 0.05
tibble(
  rank_k        = 1:m_tests,
  p_ordered     = p_sorted,
  bh_threshold  = (rank_k / m_tests) * q_target,
  below_thresh  = p_ordered <= bh_threshold
)


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Run `TukeyHSD(fit_2way)` and inspect the `lens_type:age_group` comparisons.
#    Within `Young` wearers, which lens pairs differ significantly? What about `Presbyopic`?
# 2. Check the residual diagnostics of `fit_2way` (`plot(fit_2way)` or ggplot Q-Q
#    and residuals vs. fitted). Do the ANOVA assumptions look reasonable?
# 3. Explain why Holm's step-down adjustment is always at least as powerful as
#    ordinary Bonferroni while still controlling the same Family-Wise Error Rate.

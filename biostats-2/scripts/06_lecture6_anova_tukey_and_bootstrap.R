# =============================================================================
#  BIOSTATS 2 — SCRIPT 06: LEVENE'S TEST, ANOVA, TUKEY HSD & THE BOOTSTRAP
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_6_with_assignment-2.R & biostats_bootstrap_cvi.R
#  Datasets: biostats-2/data/full_data.csv (Cone contrast thresholds)
#            biostats-2/data/cvi.csv (Cortical Visual Impairment scores)
#            biostats-2/data/album_sales.csv
#
#  Topics Covered:
#    1. Testing homogeneity of variance with Levene's test (`car::leveneTest`)
#    2. One-way ANOVA (`aov()`) and Tukey's HSD (`TukeyHSD()`) — plus noting
#       within-subject structure on repeated cone measurements!
#    3. Bootstrapping a mean (playing cards) and a median (`cvi.csv`) with `boot()`
#    4. Bootstrapping multiple regression slopes (`bootReg` + BCa 95% CIs)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(car)         # For car::leveneTest()
library(boot)        # For boot() and boot.ci()
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform(), boot_mean(), boot_median(), boot_reg()!
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Levene's Test, One-Way ANOVA & Tukey HSD on Cone Thresholds ---------
d_long <- make_dTransform("biostats-2/data/full_data.csv") |>
  pivot_longer(cols = A:S, names_to = "condition", values_to = "threshold") |>
  mutate(condition = factor(condition, levels = c("A", "L", "M", "Sneg", "Spos", "S")))

# 1a. Check homogeneity of variance across conditions using Levene's test
#     (center = median is the robust Brown-Forsythe version, R's recommended default)
cat("--- Levene's Test Across Cone Conditions ---\n")
print(car::leveneTest(threshold ~ condition, data = d_long, center = median))

# 1b. One-way ANOVA and Tukey HSD pairwise follow-up
#     Note: Because the same subjects completed all 6 conditions, in a full
#     paper you would add `Error(subject/condition)` or a mixed model `(1 | subject)`.
#     Here we inspect the classical one-way ANOVA + Tukey HSD workflow first:
d_aov <- aov(threshold ~ condition, data = d_long)
cat("\n--- One-Way ANOVA Summary ---\n")
print(summary(d_aov))

cat("\n--- Tukey HSD Pairwise Comparisons (first 8 rows) ---\n")
print(head(TukeyHSD(d_aov)$condition, 8))

# Compare with repeated-measures ANOVA accounting for subject pairing!
cat("\n--- Repeated-Measures ANOVA (`Error(subject / condition)`) ---\n")
print(summary(aov(threshold ~ condition + Error(subject / condition), data = d_long)))


# ---- 2. Bootstrapping a Mean (Card-Deck Activity) ---------------------------
# `boot_mean()`, `boot_median()`, and `boot_reg()` are loaded from
# `biostats-2/R/biostats2_helpers.R` — no need to re-run function blocks!
full_deck  <- rep(2:10, each = 4)
shuffled   <- sample(full_deck)
samp_cards <- shuffled[1:18]   # Draw half the deck

boot_cards <- boot::boot(data = samp_cards, statistic = boot_mean, R = 2000)
cat("\n--- Bootstrap 95% CI for Card Sample Mean (R = 2,000) ---\n")
print(boot::boot.ci(boot_cards, type = c("perc", "bca"), index = 1))


# ---- 3. Bootstrapping a Median on CVI Data (`biostats_bootstrap_cvi.R`) -----
# Replaces deprecated `tidyr::gather()` with modern `tidyr::pivot_longer()`!
cvi_raw <- readr::read_csv("biostats-2/data/cvi.csv", show_col_types = FALSE)
cvi_long <- cvi_raw |>
  pivot_longer(everything(), names_to = "measure", values_to = "score")

boot_cvi <- boot::boot(data = cvi_long$score, statistic = boot_median, R = 2000)

cat("\n--- CVI Median & Bootstrap Percentile 95% CI ---\n")
cat("Observed sample median:", median(cvi_long$score), "\n")
print(boot::boot.ci(boot_cvi, type = "perc"))

tibble(boot_med = boot_cvi$t[, 1]) |>
  ggplot(aes(x = boot_med)) +
  geom_histogram(bins = 25, fill = "#0072B2", colour = "white", alpha = 0.85) +
  geom_vline(xintercept = median(cvi_long$score), colour = "firebrick", linewidth = 1) +
  labs(
    title    = "Bootstrap Distribution of Median CVI Score (R = 2,000)",
    subtitle = "Red line = observed sample median",
    x        = "Bootstrapped Median", y = "Count"
  )


# ---- 4. Bootstrapping Multiple Regression Coefficients ----------------------
# Uses local `biostats-2/data/album_sales.csv` (no broken web URL!).
album <- readr::read_csv("biostats-2/data/album_sales.csv", show_col_types = FALSE)

boot_album <- boot::boot(
  data      = album,
  statistic = boot_reg,
  formula   = sales ~ adverts + airplay + image,
  R         = 2000
)

cat("\n--- Bootstrap 95% BCa CIs for Regression Slopes ---\n")
for (k in seq_along(boot_album$t0)) {
  ci_k <- boot::boot.ci(boot_album, type = "bca", index = k)
  cat(sprintf("%-10s: est = %8.3f | 95%% BCa CI [%8.3f, %8.3f]\n",
              names(boot_album$t0)[k], boot_album$t0[k], ci_k$bca[4], ci_k$bca[5]))
}


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Write a bootstrap statistic function `boot_cor(data, idx)` that returns
#    `cor(data$RE[idx], data$Spos[idx])` on `d_full` (log-transformed) and
#    compute its 95% BCa confidence interval.
# 2. Run Levene's test and a one-way ANOVA on `postAx ~ condition` in
#    `biostats-2/data/Monitor_Birds.csv`, followed by `TukeyHSD()`.
# 3. Why do we prefer R = 2,000+ bootstrap replicates instead of R = 99 when
#    estimating 95% confidence interval endpoints?

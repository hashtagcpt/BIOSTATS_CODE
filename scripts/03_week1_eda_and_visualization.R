# =============================================================================
#  SCRIPT 03: EXPLORATORY DATA ANALYSIS, VISUALIZATION & THE TABLE 1 FAIL
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 1 - Foundations, R & Data Exploration
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 30-42)
#  Notes   : [BIOSTATS] BALANCE TESTS - The Table 1 Fail.docx
#  Reuses  : our_R_script_commands.R, Biostats-1-R-learning-script.R,
#            Biostats-1-Week-2.R
#  Datasets: data/01_student_vision_clinic.csv
#            data/02_iop_clinical_trial.csv
#
#  Topics Covered:
#    1. Plotting deviations around the mean & histogram of deviations
#    2. Tukey boxplots (Q1, median, Q3, IQR, 1.5*IQR fences vs. whiskers)
#    3. Why bar charts mislead (#barbarplots) vs. showing individual raw points
#    4. Scatterplots for bivariate clinical relationships (CCT vs. IOP)
#    5. Fixing "The Table 1 Fail": 1D scatterplots for baseline group balance
#       instead of misapplied NHST p-values (Rousselet et al., 2016)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
theme_set(theme_minimal(base_size = 13))
set.seed(100)

clinic    <- readr::read_csv("data/01_student_vision_clinic.csv", show_col_types = FALSE)
iop_trial <- readr::read_csv("data/02_iop_clinical_trial.csv", show_col_types = FALSE)


# ---- 1. Deviations Around the Mean (Reused from our_R_script_commands.R) ----
# Slides 31-32: Inspect individual deviations (x_i - xbar) and their histogram.
d <- rnorm(1000, mean = 16, sd = 3)   # Simulated IOP measurements (mmHg)
dev_df <- tibble(
  sample_index = seq_along(d),
  deviation    = d - mean(d)
)

# Scatterplot of deviations around 0
ggplot(dev_df, aes(x = sample_index, y = deviation)) +
  geom_point(alpha = 0.45, size = 1.6, colour = "grey30") +
  geom_hline(yintercept = mean(dev_df$deviation), colour = "firebrick", linewidth = 1) +
  labs(
    title    = "Individual Deviations Around the Sample Mean",
    subtitle = "Red line sits at 0 because positive and negative deviations sum to zero",
    x        = "Observation Index",
    y        = "Deviation from Mean (mmHg)"
  )

# Histogram of deviations: reveals the bell-shaped distribution
ggplot(dev_df, aes(x = deviation)) +
  geom_histogram(bins = 30, fill = "steelblue", colour = "white", alpha = 0.85) +
  geom_vline(xintercept = 0, colour = "firebrick", linetype = "dashed", linewidth = 1) +
  labs(
    title = "Histogram of Deviations Around the Mean",
    x     = "Deviation from Mean (mmHg)",
    y     = "Count"
  )


# ---- 2. Anatomy of a Tukey Boxplot (Slides 34-36) ---------------------------
# Let's verify Tukey's exact boxplot definitions on `tbut_sec` (Tear Break-Up Time):
#   - Box spans Q1 (25th percentile) to Q3 (75th percentile); IQR = Q3 - Q1
#   - Internal line = median (50th percentile)
#   - Fences = Q1 - 1.5*IQR and Q3 + 1.5*IQR
#   - Whiskers reach the most extreme OBSERVED values inside the fences!
#   - Points outside the fences are plotted individually to flag investigation.

tbut <- na.omit(clinic$tbut_sec)
q1   <- quantile(tbut, 0.25)
med  <- median(tbut)
q3   <- quantile(tbut, 0.75)
iqr  <- q3 - q1

lower_fence   <- q1 - 1.5 * iqr
upper_fence   <- q3 + 1.5 * iqr
lower_whisker <- min(tbut[tbut >= lower_fence])
upper_whisker <- max(tbut[tbut <= upper_fence])
flagged_pts   <- tbut[tbut < lower_fence | tbut > upper_fence]

cat("--- Tukey Boxplot Anatomy for TBUT (seconds) ---\n")
cat(sprintf("Q1 = %.2f | Median = %.2f | Q3 = %.2f | IQR = %.2f\n", q1, med, q3, iqr))
cat(sprintf("Upper fence = %.2f | Upper whisker (observed) = %.2f\n", upper_fence, upper_whisker))
cat("Points beyond fences (flag for review, do NOT auto-delete):", flagged_pts, "\n")

# Modern ggplot2 boxplot layered with individual observations (Slide 36)
ggplot(filter(clinic, !is.na(tbut_sec)),
       aes(x = program, y = tbut_sec, fill = program)) +
  geom_boxplot(width = 0.45, alpha = 0.55, outlier.shape = NA) +
  geom_jitter(width = 0.12, alpha = 0.75, size = 2) +
  scale_fill_manual(values = c("Optometry" = "#0072B2", "Graduate_VS" = "#E69F00")) +
  labs(
    title    = "Tear Film Break-Up Time (TBUT) by Student Program",
    subtitle = "Boxplot (median & IQR) overlaid with individual student measurements",
    x        = "Program",
    y        = "TBUT (seconds)"
  ) +
  theme(legend.position = "none")


# ---- 3. Why Bar Charts Can Mislead: #barbarplots (Slides 37-38) -------------
# Three VERY different clinical distributions can have nearly IDENTICAL
# means and standard errors! A plain bar chart hides skewness, bimodality,
# and outliers completely.

n_demo <- 40
bar_trap <- bind_rows(
  tibble(group = "A: Symmetric",
         score = rnorm(n_demo, mean = 20, sd = 3)),
  tibble(group = "B: Bimodal (2 subtypes)",
         score = c(rnorm(n_demo / 2, 17.2, 1.0), rnorm(n_demo / 2, 22.8, 1.0))),
  tibble(group = "C: Skewed + Outlier",
         score = c(rnorm(n_demo - 1, 19.3, 1.2), 36.0))
) |>
  # Standardize each group to have the EXACT same mean = 20 and SD = 3!
  group_by(group) |>
  mutate(score = 20 + 3 * as.numeric(scale(score))) |>
  ungroup()

# Check summary statistics: identical mean, SD, and SEM!
bar_trap |>
  group_by(group) |>
  summarize(n = n(), mean = mean(score), sd = sd(score), sem = sd(score) / sqrt(n()))

# Misleading bar plot (all three groups look identical!)
ggplot(bar_trap, aes(x = group, y = score, fill = group)) +
  stat_summary(fun = mean, geom = "col", width = 0.5, alpha = 0.7) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.15, linewidth = 0.9) +
  labs(
    title    = "What a Bar Chart Hides (#barbarplots)",
    subtitle = "Error bars = mean +/- 1 SEM. All three groups look identical!",
    x        = NULL, y = "Clinical Score (units)"
  ) +
  theme(legend.position = "none")

# Transparent alternative: violin + boxplot + individual points (Slide 38)
ggplot(bar_trap, aes(x = group, y = score, fill = group)) +
  geom_violin(alpha = 0.35, colour = NA) +
  geom_boxplot(width = 0.18, alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.10, size = 2, alpha = 0.8) +
  labs(
    title    = "Show the Data Behind the Bar Chart",
    subtitle = "Same exact mean (20) and SD (3) — completely different clinical distributions!",
    x        = NULL, y = "Clinical Score (units)"
  ) +
  theme(legend.position = "none")


# ---- 4. Scatterplots for Bivariate Relationships (Slide 39) -----------------
# Reused from Biostats-1-Week-2.R: inspect Central Corneal Thickness vs. IOP
ggplot(iop_trial, aes(x = cct_um, y = iop_baseline, colour = treatment)) +
  geom_point(size = 2.8, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, colour = "grey20", linetype = "dashed") +
  scale_colour_manual(values = c("Drop_A" = "#0072B2", "Drop_B" = "#D55E00")) +
  labs(
    title    = "Baseline IOP vs. Central Corneal Thickness (CCT)",
    subtitle = "Always inspect direction, form, spread, and outliers before running correlation",
    x        = "Central Corneal Thickness (microns)",
    y        = "Baseline IOP (mmHg)",
    colour   = "Assigned Arm"
  )


# ---- 5. Solving "The Table 1 Fail" (Rousselet et al., 2016) -----------------
# From `[BIOSTATS] BALANCE TESTS - The Table 1 Fail.docx`:
#   Running p-values on baseline characteristics (age, CCT, baseline IOP) in a
#   randomized trial tests a null hypothesis we ALREADY KNOW is true by design
#   (both arms were randomly allocated from the same pool).
#   Instead of baseline balance p-values, show descriptive summaries + a 1D
#   strip/scatterplot so readers can judge practical balance directly!

# Clean descriptive Table 1 (NO p-value column!)
iop_trial |>
  group_by(treatment) |>
  summarize(
    n            = n(),
    age_mean_sd  = sprintf("%.1f (%.1f)", mean(age), sd(age)),
    cct_mean_sd  = sprintf("%.0f (%.0f)", mean(cct_um), sd(cct_um)),
    iop_mean_sd  = sprintf("%.1f (%.1f)", mean(iop_baseline), sd(iop_baseline)),
    pct_female   = sprintf("%.0f%%", 100 * mean(sex == "F")),
    .groups      = "drop"
  )

# 1D Scatterplot ("Table 1 Graphic") across baseline covariates
iop_trial |>
  select(patient_id, treatment, Age_yrs = age, CCT_um = cct_um, Baseline_IOP_mmHg = iop_baseline) |>
  pivot_longer(cols = c(Age_yrs, CCT_um, Baseline_IOP_mmHg),
               names_to = "variable", values_to = "value") |>
  ggplot(aes(x = treatment, y = value, colour = treatment)) +
  geom_jitter(width = 0.14, size = 2.2, alpha = 0.65) +
  stat_summary(fun = mean, geom = "crossbar", width = 0.4, colour = "black", linewidth = 0.5) +
  facet_wrap(~ variable, scales = "free_y") +
  scale_colour_manual(values = c("Drop_A" = "#0072B2", "Drop_B" = "#D55E00")) +
  labs(
    title    = "Baseline Balance Graphic (Alternative to 'Table 1' p-values)",
    subtitle = "Individual patients + horizontal mean bars (Rousselet et al., 2016)",
    x        = "Treatment Arm",
    y        = "Baseline Value"
  ) +
  theme(legend.position = "none")


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Create a scatterplot of `far_logmar` vs. `contrast_sens` from `clinic`,
#    colored by `program`. Does one student stand out as an outlier?
# 2. Make a boxplot + jitter plot of `iop_change` by `treatment` in `iop_trial`.
#    Add a horizontal dashed line at y = 0 (no IOP change) and label the sign
#    convention in the subtitle.
# 3. Why is it problematic to report a bar chart whose error bars are unlabeled?

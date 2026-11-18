# =============================================================================
#  SCRIPT 06: SAMPLING INTUITION, NORMALITY DIAGNOSTICS, OUTLIERS & SIMULATION
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 3 - Statistical Intuition & Visualization
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 108-123)
#  Reuses  : dice_normal_dist_boostrap.R, infected.R (dice sim),
#            beat_the_dealer.R (myopia progression simulation)
#  Datasets: biostats-1/data/01_student_vision_clinic.csv
#            biostats-1/data/05_dice_normality_rolls.csv
#
#  Topics Covered:
#    1. Simulation: What varies when we repeat a study? (n = 10 vs. n = 40)
#    2. Reading Normal Q-Q plots (normal, right-skew, heavy tails, outliers)
#    3. Formal normality tests (Shapiro-Wilk & KS caution) & large-sample paradox
#    4. Classroom Dice Lab: uniform single dice vs. bell-shaped sum (CLT)
#    5. "An Outlier Is a Question, Not a Delete Button": sensitivity analysis
#    6. Clinical simulation: 5-year Myopia Progression model (from beat_the_dealer.R)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

clinic     <- readr::read_csv("biostats-1/data/01_student_vision_clinic.csv", show_col_types = FALSE)
dice_rolls <- readr::read_csv("biostats-1/data/05_dice_normality_rolls.csv", show_col_types = FALSE)


# ---- 1. Repeated Sampling Simulation: n = 10 vs. n = 40 (Slide 109) ---------
# Teaching population: Adult IOP ~ Normal(mean = 16 mmHg, sd = 3 mmHg).
# Repeat 2,000 studies at n = 10 vs. n = 40 and compare the spread of sample means.
n_sims <- 2000
sampling_df <- bind_rows(
  tibble(sample_size = "n = 10", mean_iop = replicate(n_sims, mean(rnorm(10, 16, 3)))),
  tibble(sample_size = "n = 40", mean_iop = replicate(n_sims, mean(rnorm(40, 16, 3))))
)

sampling_df |>
  group_by(sample_size) |>
  summarize(avg_of_means = mean(mean_iop), sd_of_means = sd(mean_iop), .groups = "drop")
# Notice: quadrupling n from 10 to 40 cuts the SD of sample means (SE) in HALF!

ggplot(sampling_df, aes(x = mean_iop, fill = sample_size)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40,
                 alpha = 0.55, position = "identity", colour = "white") +
  geom_vline(xintercept = 16, linetype = "dashed", linewidth = 0.9) +
  scale_fill_manual(values = c("n = 10" = "#E69F00", "n = 40" = "#0072B2"), name = NULL) +
  labs(
    title    = "Sampling Distribution of Mean IOP: n = 10 vs. n = 40",
    subtitle = "Both center on 16 mmHg; n = 40 has half the standard error of n = 10",
    x        = "Sample Mean IOP (mmHg)", y = "Density"
  ) +
  theme(legend.position = "top")


# ---- 2. Visual Key for Normal Q-Q Plots (Slides 110-117) --------------------
# A Normal Q-Q plot puts theoretical normal quantiles on x and observed sample
# quantiles on y. Learn to recognize four classic clinical patterns:
n_qq <- 80
qq_patterns <- bind_rows(
  tibble(pattern = "1. Approximately Normal",
         value   = rnorm(n_qq, mean = 0, sd = 1)),
  tibble(pattern = "2. Right-Skewed (e.g., TBUT / RT)",
         value   = scale(rgamma(n_qq, shape = 2.5, scale = 1))[, 1]),
  tibble(pattern = "3. Heavy Tails (t with df = 3)",
         value   = scale(rt(n_qq, df = 3))[, 1]),
  tibble(pattern = "4. Normal + 1 Extreme Outlier",
         value   = c(rnorm(n_qq - 1, 0, 1), 5.2))
)

ggplot(qq_patterns, aes(sample = value)) +
  stat_qq(alpha = 0.7, colour = "#0072B2") +
  stat_qq_line(colour = "firebrick", linewidth = 0.8) +
  facet_wrap(~ pattern, scales = "free_y") +
  labs(
    title    = "How to Read a Normal Q-Q Plot",
    subtitle = "Right skew bends UP at upper tail; heavy tails S-curve; outliers detach sharply",
    x        = "Theoretical Normal Quantiles", y = "Observed Sample Quantiles"
  )


# ---- 3. Shapiro-Wilk Test & The Large-Sample Paradox (Slides 118, 122) ------
# Shapiro-Wilk tests H0: data were drawn from a normal distribution.
# PARADOX:
#   - At small n (e.g., n = 15), Shapiro-Wilk lacks power and misses strong skew.
#   - At huge n (e.g., n = 5,000), Shapiro-Wilk rejects trivial, harmless deviations!

# Check real clinical variables in `clinic`
cat("--- Shapiro-Wilk on Simulated Student Vision Clinic Data ---\n")
print(shapiro.test(na.omit(clinic$contrast_sens)))
print(shapiro.test(na.omit(clinic$tbut_sec)))     # Skewed + high outlier -> tiny p

# Demonstrate the large-sample paradox by simulation:
# Draw from a VERY slightly heavy-tailed t(df = 25) distribution (visually almost Normal!)
paradox_demo <- tibble(n = c(15, 50, 200, 1000, 4000)) |>
  mutate(
    # Proportion of 200 replications where Shapiro-Wilk rejects normality (p < 0.05)
    pct_rejected_skew_small_vs_large = map_dbl(n, \(k) {
      mean(replicate(100, shapiro.test(rt(k, df = 25))$p.value < 0.05)) * 100
    }),
    # Also check a genuinely skewed Gamma(shape = 4) distribution
    pct_rejected_true_skew = map_dbl(n, \(k) {
      mean(replicate(100, shapiro.test(rgamma(k, shape = 4, scale = 1))$p.value < 0.05)) * 100
    })
  )
print(paradox_demo)
# Note on Kolmogorov-Smirnov (`ks.test`):
# NEVER run `ks.test(x, "pnorm")` without specifying population mean/sd — it tests
# against Standard Normal N(0, 1), NOT "any normal distribution" (Slide 118 & 397)!


# ---- 4. Classroom Dice Lab: Uniform Dice vs. Bell-Shaped Sum (Slide 123) ----
# Reused from dice_normal_dist_boostrap.R & infected.R, using our CSV data!
head(dice_rolls)

# Reshape individual dice to long format to compare each die against their sum
dice_long <- dice_rolls |>
  pivot_longer(cols = c(d4, d6, d8, d10, d12, d20, total),
               names_to = "variable", values_to = "value") |>
  mutate(variable = factor(variable, levels = c("d4", "d6", "d8", "d10", "d12", "d20", "total")))

# Run Shapiro-Wilk on each individual die (discrete uniform -> non-normal) vs. their total (CLT!)
dice_normality <- dice_long |>
  group_by(variable) |>
  summarize(
    mean_val  = mean(value),
    sd_val    = sd(value),
    shapiro_W = shapiro.test(value)$statistic,
    shapiro_p = shapiro.test(value)$p.value,
    .groups   = "drop"
  )
print(dice_normality)

ggplot(dice_long, aes(x = value, fill = variable == "total")) +
  geom_histogram(bins = 15, colour = "white", alpha = 0.8) +
  facet_wrap(~ variable, scales = "free") +
  scale_fill_manual(values = c(`FALSE` = "grey55", `TRUE` = "#0072B2"), guide = "none") +
  labs(
    title    = "Dice Normality Lab: Flat Individual Dice vs. Bell-Shaped Sum",
    subtitle = "Even though each die is discrete uniform, summing 6 dice approaches normality (CLT)",
    x        = "Observed Roll / Total", y = "Frequency"
  )


# ---- 5. "An Outlier Is a Question, Not a Delete Button" (Slides 113-114, 119)
# In `clinic`, student S038 has `far_logmar = 0.42` (~20/53), standing out from
# peers who cluster near 0.00 (20/20).
# WRONG workflow: silently delete S038 to make the histogram look prettier.
# RIGHT workflow:
#   1. Investigate the record (was it an uncorrected refractive error, amblyopia, or typo?).
#   2. Keep valid clinical observations in the primary analysis.
#   3. Run a transparent SENSITIVITY ANALYSIS showing how much results change.

va_all <- clinic |> filter(!is.na(far_logmar))
va_no_extreme <- va_all |> filter(far_logmar < 0.30)

# Compare summaries and group t-test with vs. without the extreme observation
t_all <- t.test(far_logmar ~ program, data = va_all)
t_sen <- t.test(far_logmar ~ program, data = va_no_extreme)

tibble(
  analysis     = c("Primary (all valid students)", "Sensitivity (excluding logMAR >= 0.30)"),
  n            = c(nrow(va_all), nrow(va_no_extreme)),
  overall_mean = c(mean(va_all$far_logmar), mean(va_no_extreme$far_logmar)),
  overall_sd   = c(sd(va_all$far_logmar),   sd(va_no_extreme$far_logmar)),
  overall_med  = c(median(va_all$far_logmar), median(va_no_extreme$far_logmar)),
  welch_p      = c(t_all$p.value, t_sen$p.value)
)
# Reporting both analyses side by side is honest, reproducible science!


# ---- 6. Clinical Simulation: 5-Year Myopia Progression (from beat_the_dealer.R)
# Simulation lets us explore how biological variability and treatment efficacy
# shape clinical outcomes before running a real trial.
n_patients            <- 1000
sim_years             <- 5
mean_baseline_se      <- -1.50   # Diopters at Year 0
sd_baseline_se        <- 0.75
mean_progression_rate <- -0.60   # Diopters / year untreated
sd_progression_rate   <- 0.20
treatment_efficacy    <- 0.40    # 40% reduction in progression rate
high_myopia_cutoff    <- -6.00   # Clinical threshold for high myopia

myopia_sim <- tibble(
  patient_id         = 1:n_patients,
  group              = if_else(patient_id <= n_patients / 2, "Treatment", "Control"),
  baseline_se        = rnorm(n_patients, mean = mean_baseline_se, sd = sd_baseline_se),
  annual_progression = rnorm(n_patients, mean = mean_progression_rate, sd = sd_progression_rate)
) |>
  mutate(
    effective_rate = if_else(group == "Treatment",
                             annual_progression * (1 - treatment_efficacy),
                             annual_progression),
    final_se       = baseline_se + (effective_rate * sim_years),
    is_high_myope  = final_se <= high_myopia_cutoff
  )

myopia_sim |>
  group_by(group) |>
  summarize(
    n                     = n(),
    mean_final_se         = mean(final_se),
    sd_final_se           = sd(final_se),
    pct_high_myopia       = mean(is_high_myope) * 100,
    .groups               = "drop"
  )

ggplot(myopia_sim, aes(x = final_se, fill = group)) +
  geom_histogram(binwidth = 0.25, alpha = 0.65, position = "identity", colour = "white") +
  geom_vline(xintercept = high_myopia_cutoff, linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values = c("Treatment" = "#0072B2", "Control" = "#D55E00"), name = NULL) +
  labs(
    title    = "Simulated 5-Year Spherical Equivalent Distribution",
    subtitle = "Dashed line = -6.00 D high-myopia threshold (40% simulated treatment efficacy)",
    x        = "Final Spherical Equivalent (Diopters)", y = "Number of Patients"
  ) +
  theme(legend.position = "top")


# ---- 7. Try It Yourself (Exercises) -----------------------------------------
# 1. Make a Normal Q-Q plot of `tbut_sec` in `clinic`. Does it look normal,
#    right-skewed, or left-skewed?
# 2. In Section 6 (Myopia simulation), change `treatment_efficacy` from 0.40 to
#    0.20. How much does the prevalence of high myopia change in the Treatment arm?
# 3. Why should a normality test p-value NEVER be used as an automatic switch
#    to pick between a t-test and a Mann-Whitney test?

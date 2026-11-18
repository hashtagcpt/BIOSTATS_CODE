# =============================================================================
#  SCRIPT 02: DESCRIPTIVE STATISTICS, THREE MEANS & STANDARD ERROR
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 1 - Foundations, R & Data Exploration
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 16-28)
#            [BIOSTATS 2026] means-in-biology.pptx (Slides 1-4)
#  Reuses  : our_R_script_commands.R
#  Datasets: biostats-1/data/01_student_vision_clinic.csv
#            biostats-1/data/02_iop_clinical_trial.csv
#
#  Topics Covered:
#    1. Sample mean, median, IQR, mode & matching summaries to NOIR scales
#    2. Arithmetic, Geometric, and Harmonic Means (AM >= GM >= HM)
#    3. Why averaging Visual Acuity requires LogMAR (geometric mean MAR)
#    4. Variance & SD: why sample variance divides by (n - 1) [simulation proof]
#    5. Standard Error of the Mean (SEM): SD vs. SEM & economy of effort
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Central Tendency by Hand: Mean, Median & Zero-Sum Deviations --------
# Exact patient ages example from Slides 19-20:
patient_ages <- c(45, 77, 21, 56, 47, 53, 64, 20, 34, 65, 80, 22, 55)

# Arithmetic mean "under the hood" (Slide 17)
xbar_manual  <- sum(patient_ages) / length(patient_ages)
xbar_builtin <- mean(patient_ages)
cat("Patient age mean (manual) :", xbar_manual, "\n")
cat("Patient age mean (builtin):", xbar_builtin, "\n")

# Fundamental property (Slide 18): deviations around the sample mean sum to ZERO
deviations <- patient_ages - xbar_manual
cat("Sum of deviations from xbar:", round(sum(deviations), 12), "\n")

# Median (50th percentile): sort and find the middle value (Slide 20)
sort(patient_ages)
cat("Patient age median:", median(patient_ages), "\n")

# Sensitivity to an outlier: suppose the last patient's age was mistyped as 550!
ages_with_typo <- c(patient_ages[-length(patient_ages)], 550)
tibble(
  dataset = c("Original ages", "With 1 typo (55 -> 550)"),
  mean    = c(mean(patient_ages),   mean(ages_with_typo)),
  median  = c(median(patient_ages), median(ages_with_typo)),
  sd      = c(sd(patient_ages),     sd(ages_with_typo)),
  iqr     = c(IQR(patient_ages),    IQR(ages_with_typo))
)
# Notice: the mean and SD explode, while the median and IQR barely move!


# ---- 2. Arithmetic, Geometric, and Harmonic Means (means-in-biology.pptx) ---
# Three legitimate averages of positive numbers — each preserves a DIFFERENT
# mathematical invariant:
#   - Arithmetic Mean (AM) = (1/n) * sum(x)         -> preserves the SUM
#   - Geometric Mean  (GM) = exp(mean(log(x)))      -> preserves the PRODUCT
#   - Harmonic Mean   (HM) = n / sum(1 / x)         -> preserves SUM OF RECIPROCALS
#
# Always satisfies:  AM >= GM >= HM  (with equality iff all values are identical).
# Note: GM and HM require all x > 0!

arithmetic_mean <- function(x) mean(x)
geometric_mean  <- function(x) {
  stopifnot(all(x > 0))
  exp(mean(log(x)))
}
harmonic_mean <- function(x) {
  stopifnot(all(x > 0))
  length(x) / sum(1 / x)
}

# Example A (means-in-biology Slide 1 & Slide 4): Effective population size bottleneck
census_sizes <- c(1000, 1000, 10, 1000, 1000)
cat("\n--- Same Data, Three Averages: {1000, 1000, 10, 1000, 1000} ---\n")
cat("Arithmetic Mean (misleading here):", round(arithmetic_mean(census_sizes), 2), "\n")
cat("Geometric Mean                    :", round(geometric_mean(census_sizes), 2), "\n")
cat("Harmonic Mean (long-run Ne)       :", round(harmonic_mean(census_sizes), 2), "\n")
# A single bottleneck of N = 10 drags the harmonic mean down to ~48.1!

# Example B (means-in-biology Slide 2): Additive quantity -> Arithmetic Mean
deer_mouse_mass_g <- c(18.2, 19.6, 17.4, 21.0, 18.8, 20.2)
cat("\nDeer mouse total biomass:", sum(deer_mouse_mass_g), "g | AM:",
    arithmetic_mean(deer_mouse_mass_g), "g\n")

# Example C (means-in-biology Slide 3): Multiplicative growth rates -> Geometric Mean
annual_lambda <- c(1.60, 0.50, 2.00, 1.25)
net_growth <- prod(annual_lambda)    # 2.00x over 4 years
am_lambda  <- arithmetic_mean(annual_lambda)
gm_lambda  <- geometric_mean(annual_lambda)

tibble(
  method              = c("True observed 4-yr net change",
                          "Using Geometric Mean (GM^4)",
                          "Using Arithmetic Mean (AM^4) [WRONG]"),
  per_year_rate       = c(NA, gm_lambda, am_lambda),
  four_year_factor    = c(net_growth, gm_lambda^4, am_lambda^4)
)
# Only GM reproduces the true 2.00x doubling; AM overstates growth by 60%!


# ---- 3. Clinical Optometry Application: Averaging Visual Acuity (Slide 23) --
# Why do optometrists NEVER average raw Snellen denominators?
# Suppose two patients have 20/20 (MAR = 1) and 20/200 (MAR = 10).
# Equal steps on an ETDRS chart are MULTIPLICATIVE ratios (0.1 log unit per line),
# so the true midpoint acuity is the GEOMETRIC mean of MAR: sqrt(1 * 10) = 3.16
# (~20/63), which equals 10^(mean(logMAR))!

snellen_denoms <- c(20, 200)
mar_vals       <- snellen_denoms / 20           # 1 and 10 arcmin
logmar_vals    <- log10(mar_vals)               # 0.0 and 1.0

wrong_snellen_mean <- arithmetic_mean(snellen_denoms)       # 20/110 (too poor!)
right_mar_gm       <- geometric_mean(mar_vals)              # 3.162 arcmin
right_snellen_gm   <- 20 * right_mar_gm                     # 20/63.2
right_from_logmar  <- 20 * 10^(arithmetic_mean(logmar_vals)) # Identical: 20/63.2!

cat("\n--- Averaging 20/20 and 20/200 Visual Acuity ---\n")
cat(sprintf("Wrong (arithmetic mean of Snellen): 20/%.1f\n", wrong_snellen_mean))
cat(sprintf("Right (geometric mean of MAR)     : 20/%.1f\n", right_snellen_gm))
cat(sprintf("Right (10^mean(logMAR) * 20)      : 20/%.1f\n", right_from_logmar))

# Apply to our simulated student clinic dataset
clinic <- readr::read_csv("biostats-1/data/01_student_vision_clinic.csv", show_col_types = FALSE)
va_clean <- na.omit(clinic$far_logmar)
cat(sprintf("Clinic sample mean logMAR = %.3f -> equivalent Snellen 20/%.1f\n",
            mean(va_clean), 20 * 10^mean(va_clean)))


# ---- 4. Variance, Standard Deviation & Why We Divide by (n - 1) (Slide 24) --
# Population variance divides by N; sample variance `var(x)` divides by (n - 1).
# Why? Because xbar is estimated FROM the same sample, which always makes
# sum((x - xbar)^2) slightly smaller than sum((x - mu)^2).
# Let's PROVE this by simulation!

true_mu    <- 16   # True population mean IOP (mmHg)
true_sigma <- 3    # True population SD (mmHg) -> true variance = 9
n_small    <- 6    # Small sample makes the n vs. (n - 1) bias crystal clear
n_sims     <- 10000

var_sim <- tibble(sim = 1:n_sims) |>
  mutate(
    res = map(sim, \(i) {
      x <- rnorm(n_small, mean = true_mu, sd = true_sigma)
      ss <- sum((x - mean(x))^2)
      tibble(
        var_div_n   = ss / n_small,
        var_div_n1  = ss / (n_small - 1),
        sd_div_n1   = sqrt(ss / (n_small - 1))
      )
    })
  ) |>
  unnest(res)

var_sim |>
  summarize(
    true_variance       = true_sigma^2,
    avg_var_div_by_n    = mean(var_div_n),    # Biased LOW (~ 7.5 instead of 9!)
    avg_var_div_by_n_1  = mean(var_div_n1),   # Unbiased (~ 9.0!)
    true_sd             = true_sigma,
    avg_sd_div_by_n_1   = mean(sd_div_n1)     # Slightly below 3 (Slide 24 note!)
  )


# ---- 5. Standard Error of the Mean (SEM) & Economy of Effort (Slides 25-28) -
# Reuses & clarifies the core lesson from our_R_script_commands.R:
#   - SD  = spread of INDIVIDUAL patients (does NOT shrink to 0 as n grows).
#   - SEM = SD / sqrt(n) = precision of the SAMPLE MEAN (shrinks as 1/sqrt(n)).

iop_trial <- readr::read_csv("biostats-1/data/02_iop_clinical_trial.csv", show_col_types = FALSE)

iop_trial |>
  group_by(treatment) |>
  summarize(
    n       = n(),
    mean_bl = mean(iop_baseline),
    sd_bl   = sd(iop_baseline),
    sem_bl  = sd(iop_baseline) / sqrt(n()),
    .groups = "drop"
  )

# Economy of Effort demonstration (Slide 25):
# Watch how SD stays ~3 mmHg across sample sizes, while SEM shrinks as 1/sqrt(n).
# To cut SEM in HALF, you need FOUR TIMES as many independent patients!
sample_sizes <- c(10, 40, 160, 640, 2560)
effort_df <- tibble(n = sample_sizes) |>
  mutate(
    sample_data = map(n, \(k) rnorm(k, mean = true_mu, sd = true_sigma)),
    sample_sd   = map_dbl(sample_data, sd),
    sample_sem  = sample_sd / sqrt(n),
    theory_sem  = true_sigma / sqrt(n)
  ) |>
  select(-sample_data)

print(effort_df)

ggplot(effort_df, aes(x = n)) +
  geom_line(aes(y = sample_sd, colour = "Sample SD (spread of patients)"), linewidth = 1) +
  geom_point(aes(y = sample_sd, colour = "Sample SD (spread of patients)"), size = 3) +
  geom_line(aes(y = sample_sem, colour = "SEM (precision of mean)"), linewidth = 1) +
  geom_point(aes(y = sample_sem, colour = "SEM (precision of mean)"), size = 3) +
  scale_x_log10(breaks = sample_sizes) +
  scale_colour_manual(values = c("#0072B2", "#D55E00"), name = NULL) +
  labs(
    title    = "SD vs. SEM as Sample Size Grows",
    subtitle = "SD stays near population sigma = 3 mmHg; SEM drops by half every 4x increase in n",
    x        = "Sample Size n (log scale)",
    y        = "IOP Variability (mmHg)"
  ) +
  theme(legend.position = "bottom")


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Compute AM, GM, and HM for `tbut_sec` in `clinic` (after removing NAs).
#    Which inequality holds, and why is GM smaller than AM for right-skewed TBUT?
# 2. A clinical driver travels 10 miles to clinic at 20 mph and 10 miles home at
#    60 mph. Which mean (AM, GM, or HM) gives the true average round-trip speed?
# 3. Change `n_small` in Section 4 from 6 to 50. How much smaller is the bias
#    of dividing by n vs. (n - 1)?

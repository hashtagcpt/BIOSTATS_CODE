# =============================================================================
#  SCRIPT 12: CATEGORICAL DATA, CHI-SQUARE, FISHER'S EXACT, SCREENING & ODDS RATIOS
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Module  : Weeks 9-10 Optional Topic Library: Counts, Risks & Screening
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 347-371)
#  Notes   : [BIOSTATS]-NOTES-CHI-SQUARE.docx
#  Reuses  : Biostats-1-Examples-11-4-19.R (Section 3)
#  Datasets: biostats-1/data/10_uv_cataract_screening.csv
#
#  Topics Covered:
#    1. Clinical Risk: Absolute Risk Reduction (ARR), Risk Ratio (RR) & NNT
#    2. Confidence intervals for proportions: Wald vs. exact `binom.test()`
#    3. Pearson's Chi-Square Goodness-of-Fit (manual Q & `chisq.test()`)
#    4. Chi-Square Test of Independence, expected counts, residuals & MC simulation
#    5. Fisher's Exact Test (`fisher.test()`) for sparse 2x2 tables
#    6. Diagnostic Screening: Sensitivity, Specificity & how PPV depends on Prevalence!
#    7. Odds Ratio (OR) vs. Risk Ratio (RR) & log-odds Confidence Intervals
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

uv_df <- readr::read_csv("biostats-1/data/10_uv_cataract_screening.csv", show_col_types = FALSE)


# ---- 1. Clinical Risk: Show the Denominator (Slide 348) ---------------------
# Simulated slide example: 20/100 events in treated vs. 30/100 in control.
p_treated <- 20 / 100
p_control <- 30 / 100

arr <- p_treated - p_control           # Absolute risk difference (-10 percentage points)
rr  <- p_treated / p_control           # Risk Ratio (0.67 -> 33% relative risk reduction)
nnt <- 1 / abs(arr)                    # Number Needed to Treat (10 patients to prevent 1 event)

cat("--- Communicating Clinical Risk (Slide 348) ---\n")
cat(sprintf("Treated risk = %.0f%% | Control risk = %.0f%%\n", 100 * p_treated, 100 * p_control))
cat(sprintf("Absolute risk diff = %+.0f percentage points | Risk Ratio = %.2f | NNT = %.1f\n",
            100 * arr, rr, nnt))
# Always report BOTH absolute and relative risk — a "50% relative reduction"
# from 0.2% to 0.1% is very different clinically from 40% to 20%!


# ---- 2. Binary Proportion Confidence Intervals (Slide 365) ------------------
# Suppose 4 out of 100 screened patients have glaucoma (p = 0.04, n*p = 4).
# With small counts, the Wald normal approximation can be poor (even < 0!).
x_cases <- 4
n_screened <- 100
p_hat <- x_cases / n_screened
se_wald <- sqrt(p_hat * (1 - p_hat) / n_screened)
ci_wald <- p_hat + c(-1, 1) * 1.96 * se_wald
ci_exact <- binom.test(x_cases, n_screened)$conf.int

cat("\n--- Proportion 95% CI for 4/100 Cases (Slide 365) ---\n")
cat(sprintf("Wald approximation : [%.4f, %.4f] (notice lower bound can dip close to/below 0!)\n",
            ci_wald[1], ci_wald[2]))
cat(sprintf("Exact binom.test() : [%.4f, %.4f]\n", ci_exact[1], ci_exact[2]))


# ---- 3. Chi-Squared Goodness-of-Fit (Slide 354 & Biostats-1-Examples-11-4-19.R)
# Exact Slide 354 calculation: observed = (22, 18), expected proportions = (0.40, 0.60)
observed <- c(22, 18)
exp_prob <- c(0.40, 0.60)
expected <- sum(observed) * exp_prob

Q_manual <- sum((observed - expected)^2 / expected)
p_manual <- pchisq(Q_manual, df = length(observed) - 1, lower.tail = FALSE)
cat("\n--- Goodness-of-Fit Manual vs. chisq.test() (Slide 354) ---\n")
cat(sprintf("Manual Q = %.4f (df = 1, p = %.4f)\n", Q_manual, p_manual))
print(chisq.test(observed, p = exp_prob, correct = FALSE))

# Optometry example: Are our 200 screening patients evenly distributed across
# 3 clinic sites, or do they match a 50% / 30% / 20% clinic volume target?
site_counts <- table(uv_df$clinic_site)
print(site_counts)
chisq.test(site_counts, p = c(0.20, 0.35, 0.45))  # Note alphabetical order of factor levels!


# ---- 4. Chi-Squared Test of Independence & Residuals (Slides 358-361) -------
# Question: In `biostats-1/data/10_uv_cataract_screening.csv`, is High UV exposure
# associated with Cataract status?
tab_uv <- table(UV_Exposure = uv_df$uv_exposure, Cataract = uv_df$cataract_status)
cat("\n--- 2x2 Contingency Table: UV Exposure vs. Cataract ---\n")
print(tab_uv)

chi_uv <- chisq.test(tab_uv, correct = FALSE)
print(chi_uv)

# Inspect expected counts E_ij = (row_total * col_total) / N and standardized residuals!
cat("\nExpected counts under independence:\n")
print(round(chi_uv$expected, 2))
cat("\nStandardized residuals (|z| > 2 highlights which cells drive the chi-square):\n")
print(round(chi_uv$stdres, 2))

# Multi-category r x c example from [BIOSTATS]-NOTES-CHI-SQUARE.docx:
# Declared race/ethnicity among MCAT vs. OAT test takers (2019 & 2020)
mcat_oat <- as.table(rbind(
  c(428, 109, 426, 111),
  c( 29,  10,  39,  20),
  c( 81,  25,  93,  30),
  c(766, 206, 769, 193)
))
dimnames(mcat_oat) <- list(
  Group = c("Asian", "Black", "Hispanic", "White"),
  Exam  = c("MCAT19", "OAT19", "MCAT20", "OAT20")
)
cat("\n--- Multi-Category r x c Chi-Square (MCAT vs. OAT, NOTES-CHI-SQUARE) ---\n")
chi_exam <- chisq.test(mcat_oat)
print(chi_exam)


# ---- 5. Fisher's Exact Test & Monte Carlo Simulation (Slides 362-364) -------
# When expected cell counts are small (sparse tables), Pearson's asymptotic
# chi-square approximation can become unreliable. Use `fisher.test()` for 2x2
# tables or Monte Carlo simulation (`simulate.p.value = TRUE`) for larger tables!
sparse_tab <- matrix(c(7, 2, 1, 8), nrow = 2, byrow = TRUE,
                     dimnames = list(Corneal_Ulcer_Risk = c("Overnight_Wear", "Daily_Wear"),
                                     Ulcer              = c("Yes", "No")))
cat("\n--- Sparse 2x2 Table: Fisher's Exact Test ---\n")
print(sparse_tab)
print(fisher.test(sparse_tab))
# Monte Carlo chi-square p-value option (from NOTES-CHI-SQUARE)
print(chisq.test(sparse_tab, simulate.p.value = TRUE, B = 10000))


# ---- 6. Diagnostic Screening: Why PPV Depends on Prevalence (Slides 366-367)
# Exact Slide 366-367 glaucoma screening arithmetic:
#   Sensitivity = P(+ | Disease)     = 0.90
#   Specificity = P(- | No Disease)  = 0.90
#   Prevalence  = P(Disease)         = 0.02 (2% in general screening population)

calc_ppv <- function(prevalence, sensitivity = 0.90, specificity = 0.90) {
  tp <- prevalence * sensitivity
  fp <- (1 - prevalence) * (1 - specificity)
  tp / (tp + fp)
}

cat("\n--- Screening Arithmetic in 1,000 People (2% Prevalence, 90% Sens/Spec) ---\n")
cat(sprintf("True Positives  = %d | False Positives = %d | PPV = %.1f%%\n",
            round(1000 * 0.02 * 0.90),
            round(1000 * 0.98 * 0.10),
            100 * calc_ppv(0.02, 0.90, 0.90)))

# Plot PPV across disease prevalence from 0.5% (community screen) to 50% (specialty referral)
ppv_curve <- expand_grid(
  prevalence = seq(0.005, 0.50, by = 0.005),
  spec_label = c("90% Spec / 90% Sens", "98% Spec / 90% Sens")
) |>
  mutate(
    spec = if_else(spec_label == "90% Spec / 90% Sens", 0.90, 0.98),
    ppv  = calc_ppv(prevalence, sensitivity = 0.90, specificity = spec)
  )

ggplot(ppv_curve, aes(x = 100 * prevalence, y = 100 * ppv, colour = spec_label)) +
  geom_line(linewidth = 1.2) +
  geom_vline(xintercept = 2, linetype = "dashed", colour = "grey45") +
  scale_colour_manual(values = c("#D55E00", "#0072B2"), name = "Test Performance") +
  labs(
    title    = "Positive Predictive Value (PPV) Depends Strongly on Prevalence",
    subtitle = "At 2% prevalence (dashed line), a 90%/90% test yields only 15.5% PPV!",
    x        = "Disease Prevalence in Screened Population (%)",
    y        = "Positive Predictive Value — P(Disease | + Test) (%)"
  ) +
  theme(legend.position = "bottom")


# ---- 7. Odds Ratios vs. Risk Ratios & Log-Odds CIs (Slides 368-371) ---------
# KEY CLINICAL DISTINCTION (Slide 369):
#   OR approximates RR ONLY when outcomes are RARE (< 10%).
#   When outcomes are common, OR is much more extreme than RR!
compare_or_rr <- tibble(
  scenario = c("Rare outcome (2% vs 1%)", "Moderate (20% vs 10%)", "Common (80% vs 40%)"),
  p1       = c(0.02, 0.20, 0.80),
  p0       = c(0.01, 0.10, 0.40)
) |>
  mutate(
    risk_ratio = p1 / p0,
    odds_ratio = (p1 / (1 - p1)) / (p0 / (1 - p0))
  )
print(compare_or_rr)

# Exact Slide 370-371 manual OR & 95%/99% log-odds Confidence Interval:
# Always label rows (Exposed/Unexposed) and columns (Event/No Event) explicitly!
tab_or <- matrix(c(44, 29,
                   30, 86),
                 nrow = 2, byrow = TRUE,
                 dimnames = list(Exposure = c("Exposed", "Unexposed"),
                                 Outcome  = c("Event", "No_Event")))
a <- tab_or[1, 1]; b <- tab_or[1, 2]
c <- tab_or[2, 1]; d <- tab_or[2, 2]

OR_sample <- (a * d) / (b * c)
se_log_or <- sqrt(1/a + 1/b + 1/c + 1/d)
ci_95_or  <- exp(log(OR_sample) + c(-1, 1) * qnorm(0.975) * se_log_or)
ci_99_or  <- exp(log(OR_sample) + c(-1, 1) * qnorm(0.995) * se_log_or)

cat("\n--- Odds Ratio & Confidence Intervals (Slides 370-371) ---\n")
cat(sprintf("Sample OR = %.3f | 95%% CI [%.3f, %.3f] | 99%% CI [%.3f, %.3f]\n",
            OR_sample, ci_95_or[1], ci_95_or[2], ci_99_or[1], ci_99_or[2]))
print(fisher.test(tab_or))   # Exact conditional MLE OR & exact 95% CI


# ---- 8. Try It Yourself (Exercises) -----------------------------------------
# 1. Using `uv_df`, construct a 2x2 table of `sunglasses_use` vs. `cataract_status`.
#    Compute both the Risk Ratio (RR) and the Odds Ratio (OR) with 95% CI.
# 2. If a glaucoma screening test has 95% sensitivity and 95% specificity,
#    what is the PPV at 2% prevalence vs. 20% prevalence (a referral clinic)?
# 3. Why can't a retrospective case-control study directly estimate population
#    Risk Ratio (RR), and why is Odds Ratio used instead (Slide 369)?

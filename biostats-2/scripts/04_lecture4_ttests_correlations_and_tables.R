# =============================================================================
#  BIOSTATS 2 — SCRIPT 04: t-TESTS, CORRELATIONS, ROBUST SUMMARIES & TABLES
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_4.R
#  Datasets: biostats-2/data/full_data.csv (Human cone contrast thresholds)
#
#  Topics Covered:
#    1. One-sample and two-sample t-tests on cone-threshold ratios
#    2. Adjusting p-values for multiple comparisons (`p.adjust`: Bonferroni, Holm, FDR)
#    3. Pearson vs. Spearman correlation (`cor.test`, two-sided vs. directional)
#    4. Robust summaries: arithmetic mean, trimmed mean, winsorized mean (`psych`),
#       median, SD, and Coefficient of Variation (CV = SD / Mean)
#    5. Building clean publication-ready descriptive tables with `knitr::kable()`
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(psych)       # For winsor.mean()
library(knitr)       # For kable() tables
library(broom)       # For tidy test outputs
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform()!


# ---- 1. Load & Prepare Cone Contrast Threshold Data -------------------------
d_full  <- read.csv("biostats-2/data/full_data.csv", check.names = TRUE)
d_trans <- make_dTransform("biostats-2/data/full_data.csv")


# ---- 2. One-Sample t-Tests & Multiple Comparisons (`p.adjust`) --------------
# Compare chromatic-to-achromatic log-threshold ratios against H0: mu = 1
t_S <- t.test(d_trans$S / d_trans$A, mu = 1)
t_M <- t.test(d_trans$M / d_trans$A, mu = 1)
t_L <- t.test(d_trans$L / d_trans$A, mu = 1)

raw_p <- c(S_over_A = t_S$p.value, M_over_A = t_M$p.value, L_over_A = t_L$p.value)

# Compare three multiplicity adjustments (Bonferroni, Holm, Benjamini-Hochberg FDR)
tibble(
  comparison = names(raw_p),
  raw_p      = raw_p,
  bonferroni = p.adjust(raw_p, method = "bonferroni"),
  holm       = p.adjust(raw_p, method = "holm"),
  fdr_bh     = p.adjust(raw_p, method = "fdr")
)

# Paired vs. independent two-sample check on within-subject cone conditions:
# Because S, Spos, and Sneg were measured on the SAME subjects, pairing matters!
cat("\n--- Paired t-tests (within-subject cone conditions) ---\n")
print(broom::tidy(t.test(d_trans$S, d_trans$Spos, paired = TRUE)))
print(broom::tidy(t.test(d_trans$S, d_trans$Sneg, paired = TRUE)))


# ---- 3. Correlation Tests: Pearson vs. Spearman, Two-Sided vs. One-Sided ----
# Research question: Is refractive error (RE) correlated with S-increment
# contrast sensitivity (`Spos`)?

cor_pearson_2s <- cor.test(d_trans$RE, d_trans$Spos, method = "pearson",  alternative = "two.sided")
cor_pearson_1s <- cor.test(d_trans$RE, d_trans$Spos, method = "pearson",  alternative = "less")
cor_spearman   <- cor.test(d_trans$RE, d_trans$Spos, method = "spearman", exact = FALSE)

bind_rows(
  mutate(broom::tidy(cor_pearson_2s), test = "Pearson (two-sided)"),
  mutate(broom::tidy(cor_pearson_1s), test = "Pearson (one-sided, less)"),
  mutate(broom::tidy(cor_spearman),   test = "Spearman rho (rank-based)")
) |>
  select(test, estimate, statistic, p.value)
# Remember: Only use a one-sided test when the direction was pre-specified BEFORE seeing data!


# ---- 4. Robust Descriptive Statistics & Coefficient of Variation ------------
# Communicating untransformed thresholds is often clearer for clinical readers.
# Compare:
#   - Arithmetic mean : uses every point (sensitive to outliers)
#   - Trimmed mean    : drops the extreme 5% from each tail
#   - Winsorized mean : caps extremes at the 5th/95th percentiles without deleting them
#   - Median          : middle value (50th percentile)
#   - CV = SD / Mean  : relative variability normalized by the mean (useful across scales)

untrans_long <- tibble(
  `Achromatic Gabor`    = d_full$thr1,
  `L-Cone Gabor`        = d_full$thr2,
  `M-Cone Gabor`        = d_full$thr3,
  `S-Negative Gaussian` = d_full$thr4,
  `S-Positive Gaussian` = d_full$thr5,
  `S-Cone Gabor`        = d_full$thr6
) |>
  pivot_longer(everything(), names_to = "Stimulus", values_to = "threshold") |>
  mutate(Stimulus = factor(Stimulus, levels = unique(Stimulus)))

desc_table <- untrans_long |>
  group_by(Stimulus) |>
  summarize(
    N               = n(),
    Mean            = mean(threshold),
    `Trimmed (5%)`  = mean(threshold, trim = 0.05),
    `Winsorized`    = psych::winsor.mean(threshold, trim = 0.05),
    Median          = median(threshold),
    SD              = sd(threshold),
    `CV (SD/Mean)`  = SD / Mean,
    .groups         = "drop"
  )


# ---- 5. Publication-Ready Descriptive Table with knitr::kable() -------------
# In RStudio/Quarto/RMarkdown, pipe into `kableExtra::kable_styling()` for HTML/PDF.
# In the console, `knitr::kable(..., format = "simple")` prints a clean text table!
cat("\n--- Descriptive Summary Table of Untransformed Contrast Thresholds ---\n")
print(knitr::kable(desc_table, digits = 4, format = "simple"))


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Run `cor.test()` between `RE` and all 6 cone conditions (`A, L, M, Sneg,
#    Spos, S`), collect the 6 p-values, and apply Holm and FDR adjustments.
# 2. Compare `mean()`, `mean(..., trim = 0.10)`, and `psych::winsor.mean(..., trim = 0.10)`
#    when you replace one threshold value with `0.90`. Which estimator changes least?
# 3. Render `desc_table |> knitr::kable(digits = 4) |> kableExtra::kable_styling()`
#    in RStudio's Viewer pane and inspect the HTML export button.

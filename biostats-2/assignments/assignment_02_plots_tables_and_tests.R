# =============================================================================
#  BIOSTATS 2 — ASSIGNMENT 2: PLOTS, TABLES, t-TESTS & CORRELATIONS
#  Submission: Save a copy as [yourfullname]_assignment_2.R (no spaces).
#  Datasets  : biostats-2/data/rgb_monitor.csv
#              biostats-2/data/rbg_noise_ir_data.csv
#              biostats-2/data/full_data.csv
#  References: See Lecture 3 & Lecture 4 scripts in `biostats-2/scripts/`.
# =============================================================================

library(tidyverse)
library(patchwork)
library(psych)
library(knitr)

# Starter data loading (runs cleanly from BIOSTATS_CODE.Rproj root!)
dat    <- readr::read_csv("biostats-2/data/rgb_monitor.csv", show_col_types = FALSE) |>
  mutate(Light = forcats::fct_recode(factor(Light), "RGB" = "rgb", "White" = "white"))

re_dat <- readr::read_csv("biostats-2/data/rbg_noise_ir_data.csv", show_col_types = FALSE) |>
  mutate(condition = forcats::fct_recode(factor(condition), "RGB" = "rgb", "White" = "white"))

d_full <- read.csv("biostats-2/data/full_data.csv", check.names = TRUE)


# --- Question 1 [4 points] ---
# Using `re_dat` (`preD` and `postD` are chick refractive errors in Diopters
# under `White` vs. `RGB` lighting):
#   a) Create a boxplot AND a grouped bar chart with +/- 1 SEM (or SD) error bars
#      comparing `preD` and `postD` across lighting conditions.
#   b) Use descriptive axis labels, poster-readable font sizes, thick visible
#      error bars, and a GRAYSCALE palette (no color!).
#   c) Combine both plots into a single two-panel figure using `patchwork`.
# YOUR CODE HERE:


# --- Question 2 [2 points] ---
# Compute paired/appropriate t-tests comparing:
#   - `preD` between RGB and White birds (or preD vs postD within each light)
#   - `postD` between RGB and White birds
#   - Collect all p-values into a vector and adjust with `p.adjust(p, method = "fdr")`.
# Write a 1-2 sentence comment interpreting the adjusted p-values.
# Hint: store a test object `res <- t.test(...)` and extract `res$p.value`.
# YOUR CODE HERE:


# --- Question 3 [2 points] ---
# Using `dat` (`rgb_monitor.csv`), create a clean descriptive table with
# `knitr::kable()` showing the Mean, Winsorized Mean (`psych::winsor.mean`),
# Median, SD, and Coefficient of Variation (SD / Mean) for:
#   `Mean_vit_diff`, `Mean_chor_diff`, and `Mean_cac_diff`
# broken down by lighting condition (`White` vs. `RGB`).
# YOUR CODE HERE:


# --- Question 4 [2 points] ---
# Using the UNTRANSFORMED S-cone thresholds from `d_full` (`thr4` = S_negative,
# `thr5` = S_positive, `thr6` = S):
#   a) Create a new variable `S_summed = sqrt(S_positive^2 + S_negative^2)`.
#   b) Make a scatterplot of `S_summed` vs. `S` with `geom_smooth(method = "lm")`.
#   c) Run `cor.test()` between `S` and `S_summed` and comment on the result.
# YOUR CODE HERE:

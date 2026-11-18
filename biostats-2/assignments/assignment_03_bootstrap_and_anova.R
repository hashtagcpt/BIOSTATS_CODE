# =============================================================================
#  BIOSTATS 2 — ASSIGNMENT 3: BOOTSTRAPPING, LEVENE'S TEST, ANOVA & TUKEY HSD
#  Submission: Save a copy as [yourfullname]_assignment_3.R (no spaces).
#  Datasets  : biostats-2/data/full_data.csv
#              biostats-2/data/Monitor_Birds.csv
#  References: See Lecture 5 & Lecture 6 scripts in `biostats-2/scripts/`.
# =============================================================================

library(tidyverse)
library(boot)
library(car)
library(patchwork)
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform() & boot_reg()!

set.seed(2026)

# Starter data loading
d_full  <- read.csv("biostats-2/data/full_data.csv", check.names = TRUE)
d_trans <- make_dTransform("biostats-2/data/full_data.csv")

birds <- readr::read_csv("biostats-2/data/Monitor_Birds.csv", show_col_types = FALSE) |>
  mutate(condition = factor(condition), Light = factor(Light))


# --- Question 1 [3 points] ---
# In Lecture 5 you modeled Refractive Error (`RE`) from the 6 log10 cone
# thresholds (`A, L, M, Sneg, Spos, S`) in `d_trans`.
# Using `boot::boot()` (R = 2000) and `boot::boot.ci(type = "bca")`:
#   a) Compute bootstrap 95% CIs for all parameters in the FULL 6-predictor model.
#   b) Compute bootstrap 95% CIs for your best 2-predictor model from Lecture 5.
#   c) Comment on which predictors' 95% bootstrap CIs exclude 0.
# YOUR CODE HERE:


# --- Question 2 [3 points] ---
# Recall `S_summed = sqrt(thr5^2 + thr4^2)` and `S = thr6` (untransformed) from
# Assignment 2. Write a custom bootstrap statistic function `boot_cor(data, idx)`
# to bootstrap the Pearson correlation between `S` and `S_summed` (R = 2000).
# Report the 95% bootstrap CI and compare it with `cor.test()$conf.int`.
# YOUR CODE HERE:


# --- Question 3 [4 points] ---
# Using `birds` (`Monitor_Birds.csv`), which compares three lighting conditions
# (`Control`, `Flicker`, `Noise`) on three ocular outcomes (`postCh`, `postAx`, `postRE`):
#   a) Create three plots (bar + +/-1 SEM error bars, or boxplot + jitter) for
#      `postCh`, `postAx`, and `postRE` across `condition`, combined with `patchwork`.
#   b) For each of the three outcomes, run Levene's test (`car::leveneTest()`),
#      a One-Way ANOVA (`aov()`), and Tukey's HSD (`TukeyHSD()`).
#   c) In a comment, identify which pairs of conditions differ at alpha = 0.10
#      and at alpha = 0.05.
# YOUR CODE HERE:

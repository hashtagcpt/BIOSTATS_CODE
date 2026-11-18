# =============================================================================
#  BIOSTATS 2 — ASSIGNMENT 4: BAYES FACTORS, POWER ANALYSIS & PSYCHOMETRICS
#  Submission: Save a copy as [yourfullname]_assignment_4.R (no spaces).
#  Datasets  : biostats-2/data/full_data.csv (+ simulated psychometric data)
#  References: See Lecture 7, Lecture 8 & Lecture 9 scripts in `biostats-2/scripts/`.
# =============================================================================

library(tidyverse)
library(BayesFactor)
library(pwr)
library(modelfree)
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform() & datasim()!

set.seed(2026)

# Starter data loading for Question 1 (`BayesFactor` expects a base data.frame)
d_trans <- as.data.frame(make_dTransform("biostats-2/data/full_data.csv"))


# --- Question 1 [4 points] ---
# Use `BayesFactor::regressionBF()` on `d_trans` to predict `RE` from all 6
# log10 cone thresholds (`A + L + M + Sneg + Spos + S`).
#   a) Print the top models ranked by Bayes Factor against the intercept-only null.
#   b) Compare each model against the FULL model (check `?regressionBF` examples).
#   c) In a comment, state which model is best according to BF and compare it
#      with the frequentist regression selection from Lecture 5.
# YOUR CODE HERE:


# --- Question 2 [3 points] ---
# A colleague plans a correlation study and expects a true Pearson `r` between
# 0.20 and 0.60. Their funder requires a Type II error rate (beta) of NO MORE
# than 0.40 (hint: what is Power = 1 - beta?) at two-sided alpha = 0.05.
# Using `pwr::pwr.r.test()`, compute the MINIMUM and MAXIMUM required sample
# sizes (rounded up with `ceiling()`) to satisfy the funder across r in [0.2, 0.6].
# YOUR CODE HERE:


# --- Question 3 [3 points] ---
# Use the `datasim()` helper (already loaded by `source("biostats-2/R/biostats2_helpers.R")`
# at the top of this script!) to simulate a yes/no psychometric dataset:
#   - `contrasts`: 10 evenly spaced values from 0.01 to 0.10
#   - `pcorrect` : 10 evenly spaced probabilities from 0 to 1
#   - `ntrials`  : 20 trials per contrast level
# Fit a binomial logistic GLM (`glm(..., family = binomial(link = "logit"))`),
# plot the observed proportions + fitted smooth psychometric curve, and compute
# the 50% threshold using `modelfree::threshold_slope()` (or `-b0 / b1`).

# YOUR CODE HERE:

# =============================================================================
#  BIOSTATS 2 — SCRIPT 05: MULTIPLE REGRESSION, STANDARDIZED BETAS & SELECTION
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_5.R (fixed local CSV & column names!)
#  Datasets: biostats-2/data/album_sales.csv
#            biostats-2/data/full_data.csv (Color Vision & Refractive Error)
#
#  Topics Covered:
#    1. Simple vs. Multiple Linear Regression (`lm()`)
#    2. Interpreting partial regression slopes & 95% confidence intervals (`confint()`)
#    3. Standardized beta weights (`lm.beta::lm.beta()`) for comparing predictors
#       measured on different scales
#    4. Comparing nested models with `anova(m_small, m_large)` and `AIC()`
#    5. Vision Science Application: Predicting Refractive Error from Cone Thresholds
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
library(lm.beta)     # Modern replacement for QuantPsyc::lm.beta()
library(car)         # For car::vif() collinearity check
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform() & score_subsets()!
theme_set(theme_minimal(base_size = 13))


# ---- 1. Simple vs. Multiple Linear Regression (Local album_sales.csv) -------
# Note: Fixed legacy script bug — `biostats-2/data/album_sales.csv` uses column
# `image` (band image rating), and loads locally with zero broken web URLs!
album <- readr::read_csv("biostats-2/data/album_sales.csv", show_col_types = FALSE)
glimpse(album)

# Baseline simple model: sales predicted by advertising budget alone
m_simple <- lm(sales ~ adverts, data = album)
summary(m_simple)
cat(sprintf("Simple R = sqrt(R^2) = %.3f\n", sqrt(summary(m_simple)$r.squared)))

# Expanded multiple regression model: add radio airplay and band image
m_multi <- lm(sales ~ adverts + airplay + image, data = album)
summary(m_multi)

# 95% Confidence intervals for the unstandardized regression slopes
cat("\n--- 95% Confidence Intervals for Unstandardized Slopes ---\n")
print(confint(m_multi))

# Standardized beta coefficients (`lm.beta`):
# Because adverts (thousands of pounds), airplay (plays/week), and image (1-10)
# have totally different units, standardized betas tell us how many SDs `sales`
# changes for a +1 SD increase in each predictor (holding others constant)!
cat("\n--- Standardized Beta Weights ---\n")
print(lm.beta::lm.beta(m_multi))

# Nested model comparison via F-test (`anova()`) and AIC:
# Tests whether adding `airplay + image` significantly improves fit over `adverts` alone.
cat("\n--- Nested Model Comparison: Simple vs. Multiple Regression ---\n")
print(anova(m_simple, m_multi))
cat(sprintf("AIC: Simple = %.1f | Multiple = %.1f (lower is better)\n",
            AIC(m_simple), AIC(m_multi)))


# ---- 2. Vision Science Application: Color Vision & Refractive Error ---------
# Solves & demonstrates the Lecture 5 Vision Science Exercises using `full_data.csv`!
# Question: Can log10 cone-isolating contrast thresholds (A, L, M, Sneg, Spos, S)
# explain variance in Refractive Error (`RE`)?

d_trans <- make_dTransform("biostats-2/data/full_data.csv")

# 2a. Full 6-predictor model
re_full <- lm(RE ~ A + L + M + Sneg + Spos + S, data = d_trans)
cat("\n--- Full Model: RE ~ All 6 Cone Thresholds ---\n")
print(summary(re_full))
cat("Variance Inflation Factors (check collinearity among cone channels):\n")
print(round(car::vif(re_full), 2))

# 2b. Compare candidate 3-predictor and 2-predictor models systematically
#     using `score_subsets()` loaded from `biostats-2/R/biostats2_helpers.R`!
predictors <- c("A", "L", "M", "Sneg", "Spos", "S")

top3 <- score_subsets(d_trans, response = "RE", predictors = predictors, k = 3) |> slice_head(n = 3)
top2 <- score_subsets(d_trans, response = "RE", predictors = predictors, k = 2) |> slice_head(n = 3)
cat("\n--- Top 3-Predictor Models ---\n"); print(top3)
cat("\n--- Top 2-Predictor Models ---\n"); print(top2)

# Fit the best 2-predictor and best 3-predictor models and compare with anova()!
best_3 <- lm(as.formula(top3$formula[1]), data = d_trans)
best_2 <- lm(as.formula(top2$formula[1]), data = d_trans)

cat("\n--- Best 2-Predictor Model Coefficients & 95% CIs ---\n")
print(broom::tidy(best_2, conf.int = TRUE))
cat("\n--- Nested ANOVA: Best 2-Predictor vs. Full 6-Predictor Model ---\n")
print(anova(best_2, re_full))


# ---- 3. Try It Yourself (Exercises) -----------------------------------------
# 1. Check the residual diagnostic plots (`plot(best_2)`) of the best 2-predictor
#    color-vision model. Are there any influential subjects (high Cook's D)?
# 2. Why should you NEVER rely on raw R^2 alone (without Adjusted R^2, AIC, or
#    out-of-sample cross-validation) to select the "best" subset of predictors?
# 3. Compute standardized beta weights (`lm.beta::lm.beta(best_2)`) and explain
#    which cone threshold has the stronger standardized association with RE.

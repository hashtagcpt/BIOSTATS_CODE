# =============================================================================
#  SCRIPT 13: LOGISTIC REGRESSION, OUT-OF-SAMPLE VALIDATION, ROC & AUC
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Module  : Weeks 9-10 Optional Topic Library: Logistic Models & Prediction
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 372-384)
#  Reuses  : logistic_regression.R, Biostats-1-Examples-10-29-19.R
#  Datasets: data/11_glaucoma_prediction.csv
#
#  Topics Covered:
#    1. Why OLS linear regression fails for binary (0/1) outcomes
#    2. Fitting simple & multivariable logistic regression via `glm(..., family = binomial)`
#    3. Translating log-odds slopes into clinical Odds Ratios & 95% CIs
#    4. The train/test validation lesson (reused from `logistic_regression.R`):
#       why in-sample accuracy overstates real clinical performance!
#    5. Threshold trade-offs, ROC curve & AUC computed cleanly from scratch
#    6. Calibration check: do predicted probabilities match observed glaucoma rates?
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

glauc <- readr::read_csv("data/11_glaucoma_prediction.csv", show_col_types = FALSE) |>
  mutate(diagnosis = factor(diagnosis, levels = c("Control", "Glaucoma")))

# Patient-level train/test split (Slide 383: NEVER split fellow eyes across train & test!)
train_df <- filter(glauc, cohort == "Train")
test_df  <- filter(glauc, cohort == "Test")

cat(sprintf("Training cohort: n = %d (%.1f%% glaucoma)\n",
            nrow(train_df), 100 * mean(train_df$glaucoma)))
cat(sprintf("Held-out test  : n = %d (%.1f%% glaucoma)\n",
            nrow(test_df),  100 * mean(test_df$glaucoma)))


# ---- 1. Why Linear Regression Fails for Binary Outcomes (Slides 373-376) ----
# Compare a straight OLS line vs. a bounded sigmoid logistic curve predicting
# P(Glaucoma) from vertical Cup-to-Disc Ratio (CDR):

ggplot(train_df, aes(x = cup_disc_ratio, y = glaucoma)) +
  geom_jitter(height = 0.04, width = 0, alpha = 0.55, size = 2, colour = "grey30") +
  geom_smooth(method = "lm", se = FALSE, aes(colour = "Linear OLS (predicts <0 and >1!)"),
              linetype = "dashed", linewidth = 1) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"),
              se = TRUE, aes(colour = "Logistic Regression (bounded [0, 1])"),
              linewidth = 1.1) +
  scale_colour_manual(values = c("firebrick", "#0072B2"), name = NULL) +
  labs(
    title    = "Binary Glaucoma Diagnosis vs. Cup-to-Disc Ratio",
    subtitle = "Linear regression escapes [0, 1]; logistic regression smoothly bounds probability",
    x        = "Vertical Cup-to-Disc Ratio (CDR)",
    y        = "Glaucoma (0 = Control, 1 = Glaucoma) / Predicted Probability"
  ) +
  theme(legend.position = "bottom")


# ---- 2. Fitting Multivariable Logistic Regression (Slides 378-379) ----------
# Model: logit(P(Glaucoma)) = log(p / (1 - p)) = b0 + b1*IOP + b2*RNFL + b3*CDR + b4*Age + b5*CCT
# Fit ONLY on `train_df`!

glm_fit <- glm(
  glaucoma ~ iop_mmhg + rnfl_um + cup_disc_ratio + age + cct_um,
  data   = train_df,
  family = binomial(link = "logit")
)
summary(glm_fit)

# Convert log-odds slopes to Odds Ratios (`exp(beta)`) with 95% profile CIs!
# Tip: for CDR (which runs 0 to 1), it's often clinically clearer to report the
# OR per +0.10 increase in CDR: exp(0.10 * beta_cdr).
or_table <- broom::tidy(glm_fit, conf.int = TRUE, exponentiate = TRUE) |>
  select(term, odds_ratio = estimate, conf.low, conf.high, p.value)
print(or_table)

cdr_or_per_0.1 <- exp(0.10 * coef(glm_fit)["cup_disc_ratio"])
cat(sprintf("\nClinical interpretation: Each +0.10 higher CDR multiplies glaucoma odds by %.2fx (holding other predictors fixed).\n",
            cdr_or_per_0.1))


# ---- 3. In-Sample Optimism vs. Held-Out Test Validation (Slides 380-381) ----
# Reuses the core lesson from `logistic_regression.R`:
# Evaluating a model on the same patients used to train it exaggerates accuracy!

# 3a. Predicted probabilities on Training vs. Held-out Test patients
train_probs <- predict(glm_fit, newdata = train_df, type = "response")
test_probs  <- predict(glm_fit, newdata = test_df,  type = "response")

# Apply a 0.50 probability cutoff to get class labels
train_pred <- if_else(train_probs > 0.50, "Glaucoma", "Control")
test_pred  <- if_else(test_probs  > 0.50, "Glaucoma", "Control")

cat("\n--- Held-Out TEST SET Confusion Matrix (Threshold = 0.50) ---\n")
cm_test <- table(Predicted = test_pred, Observed = test_df$diagnosis)
print(cm_test)

# Compute accuracy, sensitivity, specificity on Train vs. Test
eval_binary <- function(probs, y_true, threshold = 0.50) {
  pred <- as.integer(probs >= threshold)
  tp <- sum(pred == 1 & y_true == 1)
  tn <- sum(pred == 0 & y_true == 0)
  fp <- sum(pred == 1 & y_true == 0)
  fn <- sum(pred == 0 & y_true == 1)
  tibble(
    threshold   = threshold,
    accuracy    = (tp + tn) / length(y_true),
    sensitivity = tp / (tp + fn),
    specificity = tn / (tn + fp),
    ppv         = ifelse(tp + fp > 0, tp / (tp + fp), NA_real_)
  )
}

bind_rows(
  mutate(eval_binary(train_probs, train_df$glaucoma, 0.50), split = "In-Sample (Train)"),
  mutate(eval_binary(test_probs,  test_df$glaucoma,  0.50), split = "Out-of-Sample (Test)")
) |>
  select(split, everything())


# ---- 4. Threshold Trade-Off, ROC Curve & AUC from Scratch (Slide 382) -------
# Changing the probability cutoff trades Sensitivity against Specificity!
# An ROC curve sweeps ALL thresholds from 1 down to 0, plotting Sensitivity
# vs. (1 - Specificity). AUC = area under that curve (0.5 = chance, 1.0 = perfect).

thresholds <- seq(1, 0, by = -0.01)
roc_df <- map_dfr(thresholds, \(th) eval_binary(test_probs, test_df$glaucoma, th)) |>
  mutate(fpr = 1 - specificity) |>
  arrange(fpr, sensitivity)

# Trapezoidal integration for AUC (equals probability a random glaucoma patient
# gets a higher predicted risk than a random control patient!)
auc_test <- sum(diff(roc_df$fpr) * (head(roc_df$sensitivity, -1) + tail(roc_df$sensitivity, -1)) / 2)
cat(sprintf("\nHeld-out Test ROC AUC = %.3f\n", auc_test))

# Inspect three clinical operating thresholds (e.g., screening vs. confirmation)
bind_rows(
  eval_binary(test_probs, test_df$glaucoma, 0.20),
  eval_binary(test_probs, test_df$glaucoma, 0.50),
  eval_binary(test_probs, test_df$glaucoma, 0.70)
)

ggplot(roc_df, aes(x = fpr, y = sensitivity)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_path(colour = "#0072B2", linewidth = 1.2) +
  coord_equal() +
  labs(
    title    = sprintf("Held-Out Test ROC Curve (AUC = %.3f)", auc_test),
    subtitle = "Diagonal dashed line = chance discrimination (AUC = 0.50)",
    x        = "1 - Specificity (False Positive Rate)",
    y        = "Sensitivity (True Positive Rate)"
  )


# ---- 5. Calibration Check: Discrimination Is Not the Whole Story (Slide 383)
# A model can rank patients well (high AUC) yet predict probabilities that are
# systematically too high or too low! Group test predictions into risk quintiles
# and compare average predicted risk vs. observed glaucoma proportion.

calib_df <- tibble(pred_prob = test_probs, observed = test_df$glaucoma) |>
  mutate(risk_bin = ntile(pred_prob, 5)) |>
  group_by(risk_bin) |>
  summarize(
    n             = n(),
    mean_pred     = mean(pred_prob),
    obs_rate      = mean(observed),
    se_obs        = sqrt(obs_rate * (1 - obs_rate) / n),
    .groups       = "drop"
  )
print(calib_df)

ggplot(calib_df, aes(x = mean_pred, y = obs_rate)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(ymin = pmax(0, obs_rate - 1.96 * se_obs),
                    ymax = pmin(1, obs_rate + 1.96 * se_obs)),
                width = 0.03, colour = "#0072B2") +
  geom_point(size = 3.2, colour = "#0072B2") +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    title    = "Calibration Plot on Held-Out Test Cohort",
    subtitle = "Well-calibrated predictions fall close to the 45-degree identity line",
    x        = "Mean Predicted Glaucoma Probability",
    y        = "Observed Glaucoma Proportion (+/- 95% CI)"
  )


# ---- 6. Try It Yourself (Exercises) -----------------------------------------
# 1. Fit a simpler logistic model using ONLY `iop_mmhg` on `train_df`. Compute
#    its held-out Test AUC and compare with the full 5-predictor model.
# 2. If missing a true glaucoma case is 4x worse than a false alarm, would you
#    choose a probability threshold LOWER or HIGHER than 0.50? Check sensitivity
#    and specificity at threshold = 0.25.
# 3. Why would randomly splitting EYES (rather than PATIENTS) into train and
#    test sets artificially inflate the apparent test AUC?

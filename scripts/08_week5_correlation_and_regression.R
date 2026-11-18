# =============================================================================
#  SCRIPT 08: CORRELATION, LINEAR REGRESSION, AIC & COLLINEARITY
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 5 - Correlation & Regression (+ Kraemer & Blasey Ch. 5-6)
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 137-173, 444-448)
#  Reuses  : Biostats-1-Examples-10-29-19.R, Biostats-1-Regression-Example.R,
#            why_most_published_findings_are_false.R
#  Datasets: data/06_refraction_biometry.csv
#
#  Topics Covered:
#    1. Pearson vs. Spearman correlation (and why you must plot first!)
#    2. How a single outlier distorts Pearson r and an OLS regression line
#    3. Simple linear regression in clinical units: refraction ~ axial length
#    4. Partitioning variance by hand: SST = SSM + SSR, R^2, and F-statistic
#    5. Residual diagnostic plots (linearity, homoscedasticity, normality, Cook's D)
#    6. Multiple regression, Adjusted R^2, AIC model selection & overfitting
#    7. The Collinearity Tax (VIF with axial length + vitreous chamber depth)
#    8. Simulation: Sampling variability of r & "Why Most Published Findings Are False"
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
library(car)         # For car::vif() collinearity check
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

eye_data <- readr::read_csv("data/06_refraction_biometry.csv", show_col_types = FALSE)
glimpse(eye_data)


# ---- 1. Correlation: Pearson vs. Spearman (Slides 139-141) ------------------
# Clinical question: How strongly does axial length (mm) correlate with
# spherical equivalent refractive error (Diopters)?

# Plot FIRST to check linearity, range, and outliers
ggplot(eye_data, aes(x = axial_length_mm, y = spherical_eq_d)) +
  geom_point(size = 2.3, alpha = 0.75, colour = "#0072B2") +
  geom_smooth(method = "lm", colour = "firebrick", linewidth = 1) +
  labs(
    title    = "Spherical Equivalent vs. Axial Length (Simulated Adult Cohort)",
    subtitle = "Longer eyes are strongly associated with more negative (myopic) refraction",
    x        = "Axial Length (mm)",
    y        = "Spherical Equivalent (Diopters)"
  )

# Pearson correlation (measures LINEAR association; sensitive to outliers)
cor_pearson  <- cor.test(eye_data$axial_length_mm, eye_data$spherical_eq_d, method = "pearson")
# Spearman rank correlation (measures MONOTONE association; robust to outliers/skew)
cor_spearman <- cor.test(eye_data$axial_length_mm, eye_data$spherical_eq_d, method = "spearman", exact = FALSE)

cat(sprintf("Pearson  r   = %.3f (95%% CI [%.3f, %.3f], R^2 = %.3f)\n",
            cor_pearson$estimate, cor_pearson$conf.int[1], cor_pearson$conf.int[2],
            cor_pearson$estimate^2))
cat(sprintf("Spearman rho = %.3f (p = %.2e)\n",
            cor_spearman$estimate, cor_spearman$p.value))


# ---- 2. How a Single Outlier Distorts Correlation & Slope (Slide 148) -------
# Suppose we add ONE data-entry error (axial length = 31 mm, SE = +4.0 D) to a
# 30-patient subset:
sub30 <- slice_head(eye_data, n = 30) |> select(axial_length_mm, spherical_eq_d)
sub30_outlier <- bind_rows(sub30, tibble(axial_length_mm = 31.0, spherical_eq_d = 4.0))

cat("\n--- Impact of 1 High-Leverage Outlier (n = 30) ---\n")
cat(sprintf("Clean data   : r = %.3f | slope = %.2f D/mm\n",
            cor(sub30$axial_length_mm, sub30$spherical_eq_d),
            coef(lm(spherical_eq_d ~ axial_length_mm, data = sub30))[2]))
cat(sprintf("With 1 error : r = %.3f | slope = %.2f D/mm\n",
            cor(sub30_outlier$axial_length_mm, sub30_outlier$spherical_eq_d),
            coef(lm(spherical_eq_d ~ axial_length_mm, data = sub30_outlier))[2]))


# ---- 3. Simple Linear Regression in Clinical Units (Slides 142-157) ---------
# Unlike dimensionless Pearson r, regression preserves CLINICAL UNITS:
#   spherical_eq_d = b0 + b1 * axial_length_mm + error
# Slope b1 = estimated change in Diopters per +1 mm greater axial length!

fit_simple <- lm(spherical_eq_d ~ axial_length_mm, data = eye_data)
summary(fit_simple)
broom::tidy(fit_simple, conf.int = TRUE)

# Verify exact relationship between r and regression slope (Slide 140):
#   b1 = r * (sd_y / sd_x)
b1_from_r <- cor(eye_data$axial_length_mm, eye_data$spherical_eq_d) *
             (sd(eye_data$spherical_eq_d) / sd(eye_data$axial_length_mm))
cat(sprintf("\nSlope from lm(): %.4f D/mm | Slope from r*(sy/sx): %.4f D/mm\n",
            coef(fit_simple)[2], b1_from_r))

# Partitioning Variance by Hand: SST = SSM + SSR (Slides 147, 150-154)
y      <- eye_data$spherical_eq_d
y_hat  <- fitted(fit_simple)
resid  <- residuals(fit_simple)

SST <- sum((y - mean(y))^2)        # Total variability around mean(y)
SSM <- sum((y_hat - mean(y))^2)    # Variability explained by the regression model
SSR <- sum(resid^2)                # Unexplained residual sum of squares (RSS)

R2_manual <- SSM / SST
F_manual  <- (SSM / 1) / (SSR / (nrow(eye_data) - 2))

cat(sprintf("SST = %.2f | SSM = %.2f | SSR = %.2f | Check SSM+SSR = %.2f\n",
            SST, SSM, SSR, SSM + SSR))
cat(sprintf("Manual R^2 = %.4f | Manual F(1, %d) = %.2f\n",
            R2_manual, nrow(eye_data) - 2, F_manual))

# Responsible Prediction with Confidence vs. Prediction Intervals (Slide 145):
#   - confidence interval: uncertainty in the MEAN refraction at a given axial length
#   - prediction interval: plausible range for a SINGLE NEW patient's eye (much wider!)
new_eyes <- tibble(axial_length_mm = c(23.0, 24.5, 26.0))
cbind(new_eyes,
      CI = predict(fit_simple, newdata = new_eyes, interval = "confidence"),
      PI = predict(fit_simple, newdata = new_eyes, interval = "prediction"))


# ---- 4. Checking Regression Assumptions with Residual Plots (Slide 149) -----
# Regression assumptions apply to the RESIDUALS (errors), not raw X or Y!
aug <- broom::augment(fit_simple)

# 1) Residuals vs. Fitted (check linearity & constant variance / homoscedasticity)
ggplot(aug, aes(x = .fitted, y = .resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "firebrick") +
  geom_point(alpha = 0.7, colour = "#0072B2") +
  geom_smooth(method = "loess", se = FALSE, colour = "black", linewidth = 0.8) +
  labs(
    title    = "Residual Diagnostic: Residuals vs. Fitted Values",
    subtitle = "Look for random scatter around 0 with constant vertical spread (no funnel or curve)",
    x        = "Fitted Spherical Equivalent (D)", y = "Residual (Observed - Fitted, D)"
  )

# 2) Normal Q-Q plot of standardized residuals
ggplot(aug, aes(sample = .std.resid)) +
  stat_qq(alpha = 0.7, colour = "#0072B2") +
  stat_qq_line(colour = "firebrick") +
  labs(title = "Normal Q-Q Plot of Standardized Regression Residuals",
       x = "Theoretical Quantiles", y = "Standardized Residuals")

# Also flag any high-Cook's-distance influential points
cat("\nLargest Cook's distances (threshold of interest often ~ 4/n =",
    round(4 / nrow(eye_data), 3), "):\n")
print(head(sort(aug$.cooksd, decreasing = TRUE), 5))


# ---- 5. Multiple Regression, Adjusted R^2 & AIC (Slides 158-171) ------------
# Reused from Biostats-1-Examples-10-29-19.R & Biostats-1-Regression-Example.R:
# Build progressively richer models for spherical equivalent and compare with
# Adjusted R^2 and AIC (Akaike Information Criterion: lower AIC = better
# trade-off between fit and complexity penalty!).

m1 <- lm(spherical_eq_d ~ axial_length_mm, data = eye_data)
m2 <- lm(spherical_eq_d ~ axial_length_mm + corneal_power_d, data = eye_data)
m3 <- lm(spherical_eq_d ~ axial_length_mm + corneal_power_d + age + screen_hours, data = eye_data)

bind_rows(
  mutate(broom::glance(m1), model = "M1: Axial length only"),
  mutate(broom::glance(m2), model = "M2: Axial length + Corneal power"),
  mutate(broom::glance(m3), model = "M3: + Age + Screen hours (extra noise)")
) |>
  select(model, r.squared, adj.r.squared, sigma, AIC, df.residual)
# Notice:
#   - Adding corneal_power_d (optically causal!) dramatically improves Adj R^2 and slashes AIC!
#   - Adding age + screen_hours slightly increases raw R^2 (it ALWAYS rises!) but
#     WORSENS AIC (higher AIC) because of the complexity penalty!

# Also model best-corrected logMAR acuity from refractive & contrast predictors
# (adapted from Biostats-1-Examples-10-29-19.R)
acuity_model <- lm(logmar_va ~ spherical_eq_d + contrast_sens + age, data = eye_data)
summary(acuity_model)


# ---- 6. The Collinearity Tax (Kraemer & Blasey Ch. 6, Slides 447-448) -------
# Axial length = Anterior chamber + Lens thickness + Vitreous chamber depth,
# so `axial_length_mm` and `vitreous_chamber_mm` are almost redundant (r > 0.96)!
# Watch what happens to standard errors and Variance Inflation Factors (VIF)
# when both are put into the same regression model:

cat(sprintf("\nCorrelation(axial_length, vitreous_chamber) = %.3f\n",
            cor(eye_data$axial_length_mm, eye_data$vitreous_chamber_mm)))

m_collinear <- lm(spherical_eq_d ~ axial_length_mm + vitreous_chamber_mm + corneal_power_d,
                  data = eye_data)
cat("\nModel WITHOUT collinear predictor (M2):\n")
print(broom::tidy(m2)[, c("term", "estimate", "std.error", "p.value")])
cat("\nModel WITH collinear vitreous_chamber_mm:\n")
print(broom::tidy(m_collinear)[, c("term", "estimate", "std.error", "p.value")])
cat("\nVariance Inflation Factors (VIF > 5-10 signals serious collinearity):\n")
print(car::vif(m_collinear))
# Notice how the standard error of `axial_length_mm` balloons by >3x!


# ---- 7. Sampling Variability of r: "Why Most Published Findings Are False" --
# Reused & modernized from `why_most_published_findings_are_false.R`!
# Suppose 1,000 vision labs each study N = 50 patients where the TRUE correlation
# between two clinical variables is modest: rho = 0.30.
# Watch how widely the observed `r` varies from study to study, and how
# filtering only for p < 0.05 exaggerates published effect sizes ("winner's curse")!

N_lab   <- 50
n_labs  <- 1000
rho_true <- 0.30

sim_r <- tibble(study = 1:n_labs) |>
  mutate(
    res = map(study, \(s) {
      x <- rnorm(N_lab)
      y <- rho_true * x + sqrt(1 - rho_true^2) * rnorm(N_lab)
      ct <- cor.test(x, y)
      tibble(r = unname(ct$estimate), p_value = ct$p.value)
    })
  ) |>
  unnest(res) |>
  mutate(
    outcome = case_when(
      abs(r) > 0.15 & p_value <  0.05 ~ "Substantive & Significant",
      abs(r) > 0.15 & p_value >= 0.05 ~ "Substantive, NOT Significant (Miss)",
      abs(r) <= 0.15 & p_value < 0.05 ~ "Tiny but Significant",
      TRUE                            ~ "Tiny & Not Significant"
    )
  )

# Compare average r across ALL labs vs. only "statistically significant" labs!
sim_r |>
  summarize(
    true_rho               = rho_true,
    mean_r_all_studies     = mean(r),
    mean_r_published_sig   = mean(r[p_value < 0.05]),  # Inflated by publication bias!
    pct_significant        = mean(p_value < 0.05) * 100
  )

ggplot(sim_r, aes(x = r, y = p_value, colour = outcome)) +
  geom_point(alpha = 0.55, size = 1.8) +
  geom_hline(yintercept = 0.05, linetype = "dashed") +
  geom_vline(xintercept = rho_true, linetype = "dotted", linewidth = 0.9) +
  labs(
    title    = "1,000 Simulated Studies (N = 50, True rho = 0.30)",
    subtitle = "Dotted line = true rho; dashed = p = 0.05. Significant studies overestimate true r!",
    x        = "Observed Sample Correlation (r)", y = "p-value", colour = NULL
  ) +
  theme(legend.position = "bottom")


# ---- 8. Try It Yourself (Exercises) -----------------------------------------
# 1. Fit `lm(spherical_eq_d ~ screen_hours + outdoor_hours, data = eye_data)`.
#    Interpret both slopes in clinical units (Diopters per daily hour).
# 2. Split `eye_data` into 80 training rows and 40 test rows. Compare test-set
#    RMSE for Model M1 vs. Model M2 vs. Model M3. Which predicts best out-of-sample?
# 3. In Section 7, change `N_lab` from 50 to 15 and rerun. What happens to the
#    average `r` among studies that achieve p < 0.05?

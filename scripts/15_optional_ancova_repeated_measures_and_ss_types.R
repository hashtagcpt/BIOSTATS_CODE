# =============================================================================
#  SCRIPT 15: ANCOVA, REPEATED-MEASURES ANOVA, MIXED MODELS & SS TYPES I/II/III
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Module  : Weeks 9-10 Optional Topic Library: Dependent Data & Model Refinements
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 411-437)
#  Notes   : [BIOSTATS]-NOTES-Analysis of Variance.docx
#  Reuses  : Biostats-1-Multiple-Comparisons-Example.R (`ez::ezANOVA`)
#  Datasets: data/02_iop_clinical_trial.csv
#            data/03_fellow_eyes_axial_length.csv
#            data/07_contact_lens_comfort.csv
#            data/08_visual_search_rt.csv
#
#  Topics Covered:
#    1. ANCOVA: Adjusting follow-up IOP for baseline IOP (`lm(followup ~ trt + baseline)`)
#       and checking the homogeneity-of-slopes assumption (`trt * baseline`)
#    2. Repeated-Measures & Mixed-Design ANOVA (`ez::ezANOVA`), Mauchly's Test
#       of Sphericity & Greenhouse-Geisser / Huynh-Feldt corrections
#    3. Modern Linear Mixed-Effects Models (`lme4::lmer` + `lmerTest`) for:
#         (a) Repeated-measures visual search reaction time
#         (b) Correlated fellow eyes (OD & OS nested within patients!)
#    4. Unbalanced Two-Way ANOVA: Comparing Type I (sequential), Type II
#       (marginal), and Type III (sum-to-zero contrasts) Sums of Squares
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
library(car)         # For car::Anova(type = "II" / "III")
library(ez)          # For ez::ezANOVA() with Mauchly's sphericity test
library(lme4)        # For linear mixed-effects models: lmer()
library(lmerTest)    # Adds Satterthwaite df & p-values to lmer()
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

iop_trial   <- readr::read_csv("data/02_iop_clinical_trial.csv", show_col_types = FALSE)
fellow_eyes <- readr::read_csv("data/03_fellow_eyes_axial_length.csv", show_col_types = FALSE)
lens_df     <- readr::read_csv("data/07_contact_lens_comfort.csv", show_col_types = FALSE)
rt_df       <- readr::read_csv("data/08_visual_search_rt.csv", show_col_types = FALSE)


# ---- 1. ANCOVA: Adjusting for Baseline IOP (Slides 414-416) -----------------
# Compare 4-week follow-up IOP between Drop_A and Drop_B:
#   - Model A (unadjusted ANOVA): ignores each patient's starting baseline IOP
#   - Model B (ANCOVA): adjusts for pre-specified baseline IOP -> absorbs
#     between-patient baseline variance, shrinking residual SE & boosting power!

fit_unadj  <- lm(iop_followup ~ treatment, data = iop_trial)
fit_ancova <- lm(iop_followup ~ treatment + iop_baseline, data = iop_trial)

# Check homogeneity of regression slopes (does treatment effect depend on baseline?)
fit_slopes <- lm(iop_followup ~ treatment * iop_baseline, data = iop_trial)

cat("--- ANCOVA vs. Unadjusted Comparison of 4-Week Follow-Up IOP ---\n")
bind_rows(
  mutate(filter(broom::tidy(fit_unadj,  conf.int = TRUE), term == "treatmentDrop_B"),
         model = "Unadjusted: followup ~ treatment",
         resid_sd = summary(fit_unadj)$sigma),
  mutate(filter(broom::tidy(fit_ancova, conf.int = TRUE), term == "treatmentDrop_B"),
         model = "ANCOVA: followup ~ treatment + baseline",
         resid_sd = summary(fit_ancova)$sigma)
) |>
  select(model, estimate, std.error, conf.low, conf.high, p.value, resid_sd)
# Notice how ANCOVA cuts residual SD & SE dramatically!

cat("\nHomogeneity of slopes test (treatment x iop_baseline interaction):\n")
print(broom::tidy(fit_slopes) |> filter(str_detect(term, ":")))

# Visualize parallel ANCOVA regression lines
iop_trial <- iop_trial |> mutate(ancova_pred = fitted(fit_ancova))
ggplot(iop_trial, aes(x = iop_baseline, y = iop_followup, colour = treatment)) +
  geom_point(size = 2.4, alpha = 0.75) +
  geom_line(aes(y = ancova_pred), linewidth = 1.1) +
  scale_colour_manual(values = c("Drop_A" = "#0072B2", "Drop_B" = "#D55E00"), name = NULL) +
  labs(
    title    = "ANCOVA: 4-Week Follow-Up IOP Adjusted for Baseline IOP",
    subtitle = "Vertical gap between parallel lines estimates the baseline-adjusted treatment effect",
    x        = "Baseline IOP (mmHg)", y = "4-Week Follow-Up IOP (mmHg)"
  ) +
  theme(legend.position = "top")


# ---- 2. Repeated-Measures & Mixed-Design ANOVA + Sphericity (Slides 419-429)
# Reuses `ez::ezANOVA()` from `Biostats-1-Multiple-Comparisons-Example.R`!
# Dataset: `data/08_visual_search_rt.csv`
#   - Between-subjects factor: `refractive_group` (Emmetrope vs. Myope)
#   - Within-subjects factor : `blur_level` (0D, 1D, 2D, 3D measured on EVERY subject)
# (Note: `afex::aov_ez()` from the ANOVA notes gives equivalent results if installed.)

rt_clean <- rt_df |>
  mutate(
    subject_id       = factor(subject_id),
    refractive_group = factor(refractive_group, levels = c("Emmetrope", "Myope")),
    blur_level       = factor(blur_level, levels = c("0D", "1D", "2D", "3D"))
  )

# Plot individual subject trajectories + group means across blur levels
ggplot(rt_clean, aes(x = blur_level, y = reaction_time_ms, colour = refractive_group)) +
  geom_line(aes(group = subject_id), alpha = 0.25) +
  stat_summary(aes(group = refractive_group), fun = mean, geom = "line", linewidth = 1.3) +
  stat_summary(aes(group = refractive_group), fun = mean, geom = "point", size = 3) +
  scale_colour_manual(values = c("Emmetrope" = "#0072B2", "Myope" = "#D55E00"),
                      name = "Refractive Group") +
  labs(
    title    = "Mixed-Design Visual Search RT Across Defocus Blur Levels",
    subtitle = "Faint lines = individual subjects (large baseline variation partitioned out by RM-ANOVA!)",
    x        = "Optical Defocus Blur", y = "Visual Search Reaction Time (ms)"
  ) +
  theme(legend.position = "top")

cat("\n--- Mixed-Design ANOVA with Mauchly's Sphericity & GG Correction ---\n")
rm_res <- ez::ezANOVA(
  data     = as.data.frame(rt_clean),
  dv       = reaction_time_ms,
  wid      = subject_id,
  within   = blur_level,
  between  = refractive_group,
  type     = 3,
  detailed = TRUE
)
print(rm_res)
# Check `Mauchly's Test for Sphericity`: if p < 0.05, sphericity is violated ->
# report the Greenhouse-Geisser (`p[GG]`, `GGe`) corrected p-value!


# ---- 3. Modern Alternative: Linear Mixed-Effects Models (Slide 428) ---------
# Why do biostatisticians increasingly prefer Mixed Models (`lme4::lmer`) over
# classical repeated-measures ANOVA?
#   1. Handles missing visits without dropping the entire patient!
#   2. Does not require strict sphericity when random slopes are modeled!
#   3. Naturally models correlated FELLOW EYES (OD & OS nested within `patient_id`)!

# 3a. Mixed model for repeated-measures visual search RT (random intercept per subject)
lmm_rt <- lmerTest::lmer(reaction_time_ms ~ refractive_group * blur_level + (1 | subject_id),
                         data = rt_clean)
cat("\n--- Linear Mixed-Effects Model (Visual Search RT) ---\n")
print(anova(lmm_rt))

# 3b. Mixed model for correlated fellow eyes (`data/03_fellow_eyes_axial_length.csv`):
#     Uses ALL 80 eyes while properly accounting for the 40 patient clusters!
eyes_long <- fellow_eyes |>
  pivot_longer(cols = c(al_od_mm, al_os_mm), names_to = "eye", values_to = "al_mm") |>
  mutate(eye = if_else(eye == "al_od_mm", "OD", "OS"))

lmm_eyes <- lmerTest::lmer(al_mm ~ lens_group + (1 | patient_id), data = eyes_long)
cat("\n--- Linear Mixed-Effects Model for Correlated Fellow Eyes (OD & OS) ---\n")
print(summary(lmm_eyes)$coefficients)
# Notice the Satterthwaite df is ~38 (reflecting 40 independent PATIENTS, NOT 80 eyes!)
# and the random-effect variance quantifies between-patient vs. within-patient eye spread!
print(VarCorr(lmm_eyes))


# ---- 4. Unbalanced Two-Way ANOVA: Type I, Type II & Type III SS (Slides 431-435)
# In a BALANCED design (equal n per cell), Type I, II, and III Sums of Squares
# are IDENTICAL. In an UNBALANCED design (common in clinical datasets!), they
# answer DIFFERENT hypotheses — and Type I depends on term order!

# Create a realistic unbalanced clinical subset of `lens_df`
unbal_df <- lens_df |>
  mutate(
    lens_type = factor(lens_type, levels = c("Soft", "Hybrid", "RGP")),
    age_group = factor(age_group, levels = c("Young", "Presbyopic"))
  ) |>
  # Simulate unequal dropout across cells
  slice(-c(1:7, 31:35, 61:69))

cat("\n--- Unbalanced Cell Counts ---\n")
print(table(unbal_df$lens_type, unbal_df$age_group))

# TYPE I (Sequential) — R's base `anova()` / `aov()` depends on predictor ORDER!
cat("\n--- Type I SS (Order 1: lens_type first, then age_group) ---\n")
print(anova(lm(discomfort_score ~ lens_type * age_group, data = unbal_df)))

cat("\n--- Type I SS (Order 2: age_group first, then lens_type) -> DIFFERENT F & p! ---\n")
print(anova(lm(discomfort_score ~ age_group * lens_type, data = unbal_df)))

# TYPE II (Marginal) — order-independent; tests each main effect after other main effects
cat("\n--- Type II SS via car::Anova(type = 'II') (Order-Independent) ---\n")
fit_unbal <- lm(discomfort_score ~ lens_type * age_group, data = unbal_df)
print(car::Anova(fit_unbal, type = "II"))

# TYPE III — MUST specify sum-to-zero contrasts (`contr.sum`) so main effects
#            test unweighted marginal means rather than a single reference cell! (Slide 432)
cat("\n--- Type III SS via car::Anova(type = 'III') with Sum-to-Zero Contrasts ---\n")
fit_unbal_sum <- lm(discomfort_score ~ lens_type * age_group,
                    data = unbal_df,
                    contrasts = list(lens_type = contr.sum, age_group = contr.sum))
print(car::Anova(fit_unbal_sum, type = "III"))


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. In Section 1 (ANCOVA), also add `cct_um` as a second pre-specified baseline
#    covariate. Does adding CCT further reduce the residual SD of follow-up IOP?
# 2. In Section 3a, fit a random-slope mixed model:
#    `lmer(reaction_time_ms ~ refractive_group * blur_level + (1 + as.numeric(blur_level) | subject_id), data = rt_clean)`
#    and compare AIC with the random-intercept model `lmm_rt`.
# 3. Verify that on the FULL balanced `lens_df` (n = 15 per cell), Type I
#    (either order), Type II, and Type III (with `contr.sum`) give identical SS!

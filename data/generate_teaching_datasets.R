# =============================================================================
#  GENERATE SIMULATED OPTOMETRY & VISION SCIENCE TEACHING DATASETS
#  Course: Biostatistics & Experimental Design I (NECO GRS97003)
#
#  IMPORTANT NOTE:
#  Every dataset created by this script is SIMULATED / ILLUSTRATIVE data
#  designed for classroom instruction in optometry and vision science.
#  They are NOT real patient records and should NOT be interpreted as
#  clinical evidence of treatment efficacy or diagnostic accuracy.
#
#  Run from the BIOSTATS_CODE project root:
#    source("data/generate_teaching_datasets.R")
# =============================================================================

set.seed(2026)

dir.create("data", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. 01_student_vision_clinic.csv
#    Modeled on NECO Teaching student_vision_data.csv
#    Variables across all NOIR scales:
#      Nominal : student_id, program, eye_color
#      Ordinal : efron_redness (0-4 grading scale), dry_eye_symptom (None/Mild/Moderate/Severe)
#      Interval/Ratio: age, far_logmar, near_logmar, snellen_denom,
#                      contrast_sens (logCS), tbut_sec (skewed tear breakup time)
#    Includes intentional NAs and 1 extreme TBUT / logMAR observation for EDA!
# -----------------------------------------------------------------------------
n1 <- 80
program <- rep(c("Optometry", "Graduate_VS"), times = c(50, 30))
year_in_prog <- sample(1:4, n1, replace = TRUE)
age <- round(rnorm(n1, mean = 24.5, sd = 2.4), 1)
eye_color <- sample(c("Brown", "Blue", "Hazel", "Green"), n1,
                    replace = TRUE, prob = c(0.48, 0.24, 0.18, 0.10))

# Far & near visual acuity in logMAR (0.0 = 20/20, negative = better than 20/20)
far_logmar <- round(rnorm(n1, mean = ifelse(program == "Optometry", -0.04, 0.01), sd = 0.07), 2)
near_logmar <- round(far_logmar + rnorm(n1, mean = 0.02, sd = 0.04), 2)
snellen_denom <- round(20 * 10^far_logmar, 1)

# Contrast sensitivity (logCS, e.g., Pelli-Robson / Mars)
contrast_sens <- round(pmin(2.25, pmax(1.35, 1.98 - 0.65 * far_logmar + rnorm(n1, 0, 0.08))), 2)

# Tear film break-up time (TBUT, seconds) - right-skewed clinical measure
tbut_sec <- round(rgamma(n1, shape = 5, scale = 2.0) + ifelse(program == "Optometry", 0.8, -0.5), 1)
tbut_sec <- pmax(2.0, tbut_sec)

# Ordinal Efron redness grade (0 = none to 4 = severe) & symptom category
efron_redness <- pmin(4, pmax(0, round(2.6 - 0.18 * tbut_sec + rnorm(n1, 0, 0.7))))
dry_eye_symptom <- factor(
  ifelse(tbut_sec >= 12, "None",
  ifelse(tbut_sec >= 8.5, "Mild",
  ifelse(tbut_sec >= 5.5, "Moderate", "Severe"))),
  levels = c("None", "Mild", "Moderate", "Severe"),
  ordered = TRUE
)

# Add a few realistic missing values (NA) and one genuine clinical extreme for EDA lessons
far_logmar[c(12, 47)] <- NA
tbut_sec[c(23, 61)] <- NA
tbut_sec[5] <- 31.5       # Unusually long tear-film stability (valid high value)
far_logmar[38] <- 0.42    # Uncorrected mild amblyopia / outlier to investigate

student_vision_clinic <- data.frame(
  student_id      = sprintf("S%03d", 1:n1),
  program         = program,
  year            = year_in_prog,
  age             = age,
  eye_color       = eye_color,
  far_logmar      = far_logmar,
  near_logmar     = near_logmar,
  snellen_denom   = snellen_denom,
  contrast_sens   = contrast_sens,
  tbut_sec        = tbut_sec,
  efron_redness   = efron_redness,
  dry_eye_symptom = dry_eye_symptom
)
write.csv(student_vision_clinic, "data/01_student_vision_clinic.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 2. 02_iop_clinical_trial.csv
#    Simulated 2-arm parallel clinical trial of topical IOP-lowering drops
#    (Drop_A vs Drop_B) in 60 ocular hypertension patients (30 per arm),
#    one study eye per patient (respecting patient-level independence!).
#    Used in Week 1 EDA, Week 2 t-tests (independent & paired), Week 6 Table 1,
#    Week 8 effect size, Optional Bayesian t-test, and Optional ANCOVA.
# -----------------------------------------------------------------------------
n2 <- 60
patient_id2 <- sprintf("P%03d", 1:n2)
treatment2 <- rep(c("Drop_A", "Drop_B"), each = n2 / 2)
age2 <- round(rnorm(n2, mean = 64, sd = 7.5), 0)
sex2 <- sample(c("F", "M"), n2, replace = TRUE, prob = c(0.54, 0.46))
cct_um <- round(rnorm(n2, mean = 548, sd = 32), 0)  # Central corneal thickness (microns)

# Baseline IOP (mmHg), correlated modestly with CCT
iop_baseline <- round(23.5 + 0.025 * (cct_um - 548) + rnorm(n2, mean = 0, sd = 2.4), 1)

# 4-week follow-up IOP: Drop_A reduces IOP by ~4.8 mmHg, Drop_B reduces by ~2.5 mmHg
# (so Drop_A - Drop_B difference in change is ~ -2.3 mmHg, matching the Week 2 slide story!)
true_delta <- ifelse(treatment2 == "Drop_A",
                     rnorm(n2, mean = -4.8, sd = 1.6),
                     rnorm(n2, mean = -2.5, sd = 2.3)) # Slightly unequal SD to motivate Welch's t!
iop_followup <- round(iop_baseline + true_delta, 1)
iop_change <- round(iop_followup - iop_baseline, 1)  # negative = IOP reduction

iop_clinical_trial <- data.frame(
  patient_id   = patient_id2,
  treatment    = treatment2,
  age          = age2,
  sex          = sex2,
  cct_um       = cct_um,
  iop_baseline = iop_baseline,
  iop_followup = iop_followup,
  iop_change   = iop_change
)
write.csv(iop_clinical_trial, "data/02_iop_clinical_trial.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 3. 03_fellow_eyes_axial_length.csv
#    Modeled on neco_axial_length_2019_2022.csv & Example-Data-1.csv
#    Both eyes (OD and OS) of 40 patients (20 Orthokeratology vs 20 Single Vision)
#    Demonstrates high fellow-eye correlation (r ~ 0.92), tidy wide-to-long
#    reshaping, pseudoreplication pitfalls, and patient-cluster bootstrapping.
# -----------------------------------------------------------------------------
n3 <- 40
pid3 <- sprintf("E%03d", 1:n3)
group3 <- rep(c("OrthoK", "SingleVision"), each = n3 / 2)

# Patient-level latent axial length + small eye-specific noise
base_al <- rnorm(n3, mean = ifelse(group3 == "OrthoK", 24.45, 24.85), sd = 0.85)
al_od <- round(base_al + rnorm(n3, 0, 0.22), 2)
al_os <- round(base_al + rnorm(n3, 0, 0.22), 2)

# Spherical equivalent (D) inversely related to axial length
se_od <- round(-2.2 * (al_od - 23.6) + rnorm(n3, 0, 0.45), 2)
se_os <- round(-2.2 * (al_os - 23.6) + rnorm(n3, 0, 0.45), 2)

fellow_eyes <- data.frame(
  patient_id = pid3,
  lens_group = group3,
  al_od_mm   = al_od,
  al_os_mm   = al_os,
  se_od_d    = se_od,
  se_os_d    = se_os
)
write.csv(fellow_eyes, "data/03_fellow_eyes_axial_length.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 4. 04_tonometer_agreement.csv
#    Paired IOP measurements on 50 eyes from two instruments:
#      goldmann_iop : Goldmann Applanation Tonometer (reference clinical standard)
#      rebound_iop  : Portable Rebound Tonometer
#    Engineered so Pearson r is very high (~0.95), YET there is a fixed offset
#    (~ +1.8 mmHg) and mild proportional bias at higher IOPs — classic Bland-Altman lesson!
# -----------------------------------------------------------------------------
n4 <- 50
true_iop <- runif(n4, min = 11, max = 30)
goldmann_iop <- round(true_iop + rnorm(n4, mean = 0, sd = 0.8), 1)
# Rebound reads systematically higher (+1.6 mmHg) and slightly steeper (+0.08 * (true - 18))
rebound_iop <- round(true_iop + 1.6 + 0.08 * (true_iop - 18) + rnorm(n4, mean = 0, sd = 1.1), 1)

tonometer_agreement <- data.frame(
  patient_id   = sprintf("T%03d", 1:n4),
  goldmann_iop = goldmann_iop,
  rebound_iop  = rebound_iop
)
write.csv(tonometer_agreement, "data/04_tonometer_agreement.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 5. 05_dice_normality_rolls.csv
#    Modeled on Biostats_1_Normality_Dice_Test_Group_2_Sheet1.csv
#    Simulated classroom dice-rolling lab (60 trials of d4, d6, d8, d10, d12, d20)
#    Used in Week 3 to show uniform individual dice vs. bell-shaped sum (CLT)
#    and Shapiro-Wilk normality tests.
# -----------------------------------------------------------------------------
n5 <- 60
d4  <- sample(1:4,  n5, replace = TRUE)
d6  <- sample(1:6,  n5, replace = TRUE)
d8  <- sample(1:8,  n5, replace = TRUE)
d10 <- sample(1:10, n5, replace = TRUE)
d12 <- sample(1:12, n5, replace = TRUE)
d20 <- sample(1:20, n5, replace = TRUE)

dice_rolls <- data.frame(
  roll_id = 1:n5,
  group   = rep(c("Group_1", "Group_2"), each = n5 / 2),
  d4 = d4, d6 = d6, d8 = d8, d10 = d10, d12 = d12, d20 = d20,
  total = d4 + d6 + d8 + d10 + d12 + d20
)
write.csv(dice_rolls, "data/05_dice_normality_rolls.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 6. 06_refraction_biometry.csv
#    120 adult patients (one eye per patient) with ocular biometry, behavioral
#    predictors, and visual function:
#      axial_length_mm, corneal_power_d, vitreous_chamber_mm (collinear with AL!),
#      screen_hours, outdoor_hours, age, spherical_eq_d, contrast_sens, logmar_va
#    Used in Week 5 correlation, simple/multiple regression, AIC, collinearity,
#    and Optional bootstrap regression.
# -----------------------------------------------------------------------------
n6 <- 120
age6 <- round(rnorm(n6, mean = 32, sd = 11), 0)
age6 <- pmax(18, pmin(68, age6))
screen_hours <- round(pmax(1, rnorm(n6, mean = 6.5, sd = 2.0)), 1)
outdoor_hours <- round(pmax(0.2, 3.2 - 0.25 * screen_hours + rnorm(n6, 0, 0.9)), 1)
corneal_power_d <- round(rnorm(n6, mean = 43.4, sd = 1.4), 2)

# Axial length depends modestly on screen & outdoor hours
axial_length_mm <- round(23.5 + 0.16 * screen_hours - 0.22 * outdoor_hours + rnorm(n6, 0, 0.95), 2)
# Vitreous chamber depth is strongly collinear with axial length (AL = ACD + LT + VCD)
vitreous_chamber_mm <- round(axial_length_mm - 7.35 + rnorm(n6, 0, 0.20), 2)

# Spherical equivalent (D): ~ -2.35 D per mm of axial length, -0.75 D per D of corneal power
spherical_eq_d <- round(-2.35 * (axial_length_mm - 23.6) - 0.72 * (corneal_power_d - 43.4) +
                        rnorm(n6, 0, 0.55), 2)

# Contrast sensitivity & best-corrected logMAR VA
contrast_sens6 <- round(pmin(2.25, pmax(1.20, 2.02 - 0.005 * (age6 - 20) + 0.025 * spherical_eq_d +
                        rnorm(n6, 0, 0.12))), 2)
logmar_va6 <- round(-0.04 + 0.003 * (age6 - 20) - 0.015 * spherical_eq_d -
                    0.18 * (contrast_sens6 - 1.85) + rnorm(n6, 0, 0.05), 3)

refraction_biometry <- data.frame(
  patient_id          = sprintf("R%03d", 1:n6),
  age                 = age6,
  screen_hours        = screen_hours,
  outdoor_hours       = outdoor_hours,
  axial_length_mm     = axial_length_mm,
  vitreous_chamber_mm = vitreous_chamber_mm,
  corneal_power_d     = corneal_power_d,
  spherical_eq_d      = spherical_eq_d,
  contrast_sens       = contrast_sens6,
  logmar_va           = logmar_va6
)
write.csv(refraction_biometry, "data/06_refraction_biometry.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 7. 07_contact_lens_comfort.csv
#    Modeled on NOTES-Analysis of Variance & NOTES-Effect Size:
#    3 Contact Lens Types (Soft, RGP, Hybrid) x 2 Age Groups (Young, Presbyopic)
#    n = 15 per cell (90 independent patients)
#    Includes a genuine lens_type x age_group interaction on discomfort_score (0-10)
#    plus baseline_dryness covariate and clarity_score (0-100).
#    Used in Week 7 One-way/Two-way ANOVA, TukeyHSD, Week 8 eta-squared,
#    and Optional Unbalanced Type I/II/III Sums of Squares.
# -----------------------------------------------------------------------------
cells7 <- expand.grid(
  lens_type = c("Soft", "RGP", "Hybrid"),
  age_group = c("Young", "Presbyopic"),
  rep       = 1:15
)
n7 <- nrow(cells7)
baseline_dryness <- round(pmin(10, pmax(0, rnorm(n7, mean = ifelse(cells7$age_group == "Presbyopic", 4.5, 3.0), sd = 1.4))), 1)

# Cell means for 8-hour discomfort score (0 = none, 10 = severe):
# Young:      Soft = 2.6, Hybrid = 3.6, RGP = 5.2
# Presbyopic: Soft = 5.4, Hybrid = 4.1, RGP = 4.9  (crossover/nonparallel interaction!)
cell_mean_disc <- with(cells7, ifelse(
  age_group == "Young" & lens_type == "Soft", 2.6,
  ifelse(age_group == "Young" & lens_type == "Hybrid", 3.6,
  ifelse(age_group == "Young" & lens_type == "RGP", 5.2,
  ifelse(age_group == "Presbyopic" & lens_type == "Soft", 5.4,
  ifelse(age_group == "Presbyopic" & lens_type == "Hybrid", 4.1, 4.9)))))
)
discomfort_score <- round(pmin(10, pmax(0, cell_mean_disc + 0.35 * (baseline_dryness - 3.75) +
                               rnorm(n7, 0, 1.15))), 1)

# Vision clarity score (0-100): RGP > Hybrid > Soft
clarity_mean <- ifelse(cells7$lens_type == "RGP", 89,
                ifelse(cells7$lens_type == "Hybrid", 84, 78))
clarity_score <- round(pmin(100, pmax(40, clarity_mean + rnorm(n7, 0, 6.5))), 1)

contact_lens_comfort <- data.frame(
  patient_id       = sprintf("CL%03d", 1:n7),
  lens_type        = cells7$lens_type,
  age_group        = cells7$age_group,
  baseline_dryness = baseline_dryness,
  discomfort_score = discomfort_score,
  clarity_score    = clarity_score
)
write.csv(contact_lens_comfort, "data/07_contact_lens_comfort.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 8. 08_visual_search_rt.csv
#    Modeled on reaction_time_data.csv & Biostats-1-Multiple-Comparisons-Example.R
#    Mixed design:
#      Between-subjects: refractive_group (Emmetrope vs Myope, 16 per group = 32 subjects)
#      Within-subjects : blur_diopters (0D, 1D, 2D, 3D) measured on every subject
#    Engineered with unequal pairwise difference variances so Mauchly's Sphericity
#    test detects a realistic sphericity departure (Greenhouse-Geisser epsilon < 1)!
# -----------------------------------------------------------------------------
n_subj8 <- 32
subj_ids8 <- sprintf("VS%02d", 1:n_subj8)
ref_group8 <- rep(c("Emmetrope", "Myope"), each = n_subj8 / 2)
subj_intercept <- rnorm(n_subj8, mean = 0, sd = 38)  # strong between-subject variability!
subj_blur_slope <- rnorm(n_subj8, mean = 0, sd = 18) # induces sphericity violation across 0D..3D!

blur_levels <- c("0D", "1D", "2D", "3D")
blur_num <- c(0, 1, 2, 3)

rows8 <- list()
idx <- 1
for (i in 1:n_subj8) {
  for (j in 1:4) {
    # Myopes show slightly slower RT under high blur
    group_effect <- ifelse(ref_group8[i] == "Myope", 10 + 9 * blur_num[j], 0)
    rt_ms <- 310 + subj_intercept[i] + (24 + subj_blur_slope[i]) * blur_num[j] +
             group_effect + rnorm(1, 0, 14)
    rows8[[idx]] <- data.frame(
      subject_id       = subj_ids8[i],
      refractive_group = ref_group8[i],
      blur_level       = blur_levels[j],
      reaction_time_ms = round(rt_ms, 1)
    )
    idx <- idx + 1
  }
}
visual_search_rt <- do.call(rbind, rows8)
write.csv(visual_search_rt, "data/08_visual_search_rt.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 9. 09_preceptor_grading_icc.csv
#    Modeled on Kraemer & Blasey Ch. 3 (Slide 312):
#    3 clinical preceptors independently score 25 OD students (0-100 scale)
#    on a contact lens fitting competency exam.
#    Preceptor_C grades systematically 6 points harsher (showing difference
#    between ICC consistency vs. ICC absolute agreement!).
# -----------------------------------------------------------------------------
n9 <- 25
true_skill <- rnorm(n9, mean = 82, sd = 7.5)
preceptor_A <- round(pmin(100, pmax(50, true_skill + rnorm(n9, 0, 2.5))), 1)
preceptor_B <- round(pmin(100, pmax(50, true_skill + 0.5 + rnorm(n9, 0, 2.8))), 1)
preceptor_C <- round(pmin(100, pmax(50, true_skill - 6.0 + rnorm(n9, 0, 2.6))), 1)

preceptor_grading <- data.frame(
  candidate_id = sprintf("OD%02d", 1:n9),
  preceptor_A  = preceptor_A,
  preceptor_B  = preceptor_B,
  preceptor_C  = preceptor_C
)
write.csv(preceptor_grading, "data/09_preceptor_grading_icc.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 10. 10_uv_cataract_screening.csv
#     Modeled on NOTES-Power & NOTES-Effect Size (UV exposure, sunglasses use,
#     cataract status, and clinic referral source) for 200 older adults.
#     Used in Optional Categorical Data, Chi-Square, Fisher's Exact, OR vs RR.
# -----------------------------------------------------------------------------
n10 <- 200
uv_exposure <- sample(c("High_UV", "Low_UV"), n10, replace = TRUE, prob = c(0.45, 0.55))
sunglasses <- ifelse(uv_exposure == "High_UV",
                     sample(c("Regular", "Rarely"), n10, replace = TRUE, prob = c(0.45, 0.55)),
                     sample(c("Regular", "Rarely"), n10, replace = TRUE, prob = c(0.60, 0.40)))
prob_cataract <- ifelse(uv_exposure == "High_UV" & sunglasses == "Rarely", 0.58,
                 ifelse(uv_exposure == "High_UV" & sunglasses == "Regular", 0.34,
                 ifelse(uv_exposure == "Low_UV"  & sunglasses == "Rarely", 0.32, 0.20)))
cataract_status <- ifelse(runif(n10) < prob_cataract, "Cataract", "No_Cataract")
clinic_site <- sample(c("Urban_Clinic", "Suburban_Clinic", "Community_Outreach"),
                      n10, replace = TRUE, prob = c(0.45, 0.35, 0.20))

uv_cataract <- data.frame(
  patient_id      = sprintf("UV%03d", 1:n10),
  uv_exposure     = uv_exposure,
  sunglasses_use  = sunglasses,
  cataract_status = cataract_status,
  clinic_site     = clinic_site
)
write.csv(uv_cataract, "data/10_uv_cataract_screening.csv", row.names = FALSE)


# -----------------------------------------------------------------------------
# 11. 11_glaucoma_prediction.csv
#     300 independent patients (200 training cohort, 100 held-out test cohort)
#     Binary outcome: glaucoma (0 = Control, 1 = Glaucoma)
#     Predictors: iop_mmhg, rnfl_um (retinal nerve fiber layer thickness),
#                 cup_disc_ratio, age, cct_um
#     Used in Optional Logistic Regression, Odds Ratios, Train/Test Split,
#     ROC Curve, AUC, and Calibration.
# -----------------------------------------------------------------------------
n11 <- 300
cohort11 <- rep(c("Train", "Test"), times = c(200, 100))
age11 <- round(rnorm(n11, mean = 62, sd = 10), 0)
cct11 <- round(rnorm(n11, mean = 542, sd = 34), 0)
iop11 <- round(pmax(10, rnorm(n11, mean = 18.5, sd = 4.2)), 1)
rnfl11 <- round(pmax(50, pmin(115, rnorm(n11, mean = 86, sd = 12))), 1)
cdr11 <- round(pmax(0.15, pmin(0.95, rnorm(n11, mean = 0.48, sd = 0.16))), 2)

# True log-odds model for glaucoma
lin_pred <- -2.0 +
  0.22 * (iop11 - 18) -
  0.09 * (rnfl11 - 86) +
  4.8  * (cdr11 - 0.48) +
  0.03 * (age11 - 62) -
  0.01 * (cct11 - 542)

prob_glauc <- 1 / (1 + exp(-lin_pred))
glaucoma <- rbinom(n11, size = 1, prob = prob_glauc)

glaucoma_prediction <- data.frame(
  patient_id     = sprintf("G%03d", 1:n11),
  cohort         = cohort11,
  age            = age11,
  iop_mmhg       = iop11,
  rnfl_um        = rnfl11,
  cup_disc_ratio = cdr11,
  cct_um         = cct11,
  glaucoma       = glaucoma,
  diagnosis      = ifelse(glaucoma == 1, "Glaucoma", "Control")
)
write.csv(glaucoma_prediction, "data/11_glaucoma_prediction.csv", row.names = FALSE)

cat("Successfully generated all 11 optometry & vision science teaching CSV files in data/.\n")

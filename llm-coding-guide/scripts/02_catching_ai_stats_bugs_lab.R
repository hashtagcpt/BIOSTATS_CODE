# =============================================================================
#  LLM CODING LAB 02: CATCHING 5 SILENT AI STATISTICAL BUGS IN OPTOMETRY
#  Course  : Biostatistics & Experimental Design I & II (NECO)
#  Datasets: biostats-1/data/01_student_vision_clinic.csv
#            biostats-1/data/02_iop_clinical_trial.csv
#            biostats-1/data/03_fellow_eyes_axial_length.csv
#            biostats-2/data/full_data.csv
#
#  WHY THIS LAB MATTERS:
#    Syntax errors (red text in the Console) are EASY to spot because R stops.
#    The REAL danger of LLM-generated R code is SILENT STATISTICAL BUGS:
#    code that runs cleanly, prints impressive tables and p-values, and gives
#    a SCIENTIFICALLY WRONG ANSWER!
#
#  How to use this lab:
#    Run each bug one section at a time. Read the "Plausible-Looking AI Code",
#    ask yourself what is wrong BEFORE reading the "Verified Fix", then compare
#    the numbers!
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(lme4)
library(lmerTest)
set.seed(2026)

clinic      <- readr::read_csv("biostats-1/data/01_student_vision_clinic.csv", show_col_types = FALSE)
iop_trial   <- readr::read_csv("biostats-1/data/02_iop_clinical_trial.csv", show_col_types = FALSE)
fellow_eyes <- readr::read_csv("biostats-1/data/03_fellow_eyes_axial_length.csv", show_col_types = FALSE)


# =============================================================================
# BUG 1: SILENTLY REPLACING MISSING VALUES (`NA`) WITH ZERO
# Prompt to AI: "My mean(far_logmar) returned NA. Fix it so it computes the mean."
# =============================================================================
cat("\n================ BUG 1: Replacing NA with 0 ================\n")

# --- BUGGY AI CODE (Runs cleanly with ZERO warnings!) ---
# In some business datasets people replace NAs with 0. In optometry, 0.0 logMAR
# means 20/20 vision! Replacing missing acuity with 0 fabricates healthy eyes!
# (Even worse on `tbut_sec`: replacing NA with 0 fabricates impossible 0-sec TBUT!)
ai_bug_tbut <- clinic |>
  mutate(tbut_filled = replace_na(tbut_sec, 0)) |>
  summarize(mean_tbut = mean(tbut_filled), sd_tbut = sd(tbut_filled))

# --- VERIFIED FIX ---
# Exclude NAs explicitly (`na.rm = TRUE`) AND report how many were missing!
fixed_tbut <- clinic |>
  summarize(
    n_complete = sum(!is.na(tbut_sec)),
    n_missing  = sum(is.na(tbut_sec)),
    mean_tbut  = mean(tbut_sec, na.rm = TRUE),
    sd_tbut    = sd(tbut_sec, na.rm = TRUE)
  )

cat("BUGGY AI (NA -> 0) :", sprintf("mean = %.2f s, SD = %.2f s\n", ai_bug_tbut$mean_tbut, ai_bug_tbut$sd_tbut))
cat("VERIFIED FIX       :", sprintf("mean = %.2f s, SD = %.2f s (n = %d, %d missing)\n",
                                    fixed_tbut$mean_tbut, fixed_tbut$sd_tbut,
                                    fixed_tbut$n_complete, fixed_tbut$n_missing))


# =============================================================================
# BUG 2: REVERSED SUBTRACTION SIGN & WRONG `var.equal = TRUE`
# Prompt to AI: "Test whether Drop A reduced IOP more than Drop B."
# =============================================================================
cat("\n================ BUG 2: Reversed Sign & Equal-Variance Assumption ================\n")

# --- BUGGY AI CODE ---
# Notice two silent traps:
#   1. Computing `iop_baseline - iop_followup` makes a DROP positive, then
#      `t.test(change ~ treatment)` subtracts alphabetically (`Drop_A - Drop_B`).
#      Without printing group means, it is easy to report the sign backwards!
#   2. Setting `var.equal = TRUE` assumes identical group variances (Excel style)
#      instead of R's safer Welch default (`var.equal = FALSE`).
ai_bug_t <- t.test(iop_change ~ treatment, data = iop_trial, var.equal = TRUE)

# --- VERIFIED FIX ---
# Always print group means + SDs FIRST, state the sign convention explicitly
# (followup - baseline: negative = IOP reduction), and use Welch (`var.equal = FALSE`).
iop_trial |>
  group_by(treatment) |>
  summarize(n = n(), mean_change = mean(iop_change), sd_change = sd(iop_change), .groups = "drop") |>
  print()

fixed_t <- t.test(iop_change ~ treatment, data = iop_trial, var.equal = FALSE)
cat(sprintf("BUGGY (Student pooled) : df = %.2f | p = %.5f\n", ai_bug_t$parameter, ai_bug_t$p.value))
cat(sprintf("VERIFIED (Welch)       : df = %.2f | p = %.5f\n", fixed_t$parameter, fixed_t$p.value))


# =============================================================================
# BUG 3: FORGETTING `paired = TRUE` ON BEFORE-AND-AFTER PATIENT DATA
# Prompt to AI: "Test if IOP changed from baseline to follow-up in Drop B."
# =============================================================================
cat("\n================ BUG 3: Forgetting `paired = TRUE` ================\n")
drop_b <- filter(iop_trial, treatment == "Drop_B")

# --- BUGGY AI CODE ---
# Treats baseline and 4-week measurements from the SAME 30 patients as if they
# were 60 unrelated people! Throws away within-patient correlation and loses power!
ai_unpaired <- t.test(drop_b$iop_followup, drop_b$iop_baseline)

# --- VERIFIED FIX ---
# Preserve within-patient matching with `paired = TRUE` (order: after, before)!
fixed_paired <- t.test(drop_b$iop_followup, drop_b$iop_baseline, paired = TRUE)

cat(sprintf("BUGGY (unpaired) : mean diff = %.2f | 95%% CI [%.2f, %.2f] | df = %.1f | p = %.2e\n",
            diff(rev(ai_unpaired$estimate)), ai_unpaired$conf.int[1], ai_unpaired$conf.int[2],
            ai_unpaired$parameter, ai_unpaired$p.value))
cat(sprintf("VERIFIED (paired): mean diff = %.2f | 95%% CI [%.2f, %.2f] | df = %.1f | p = %.2e\n",
            fixed_paired$estimate, fixed_paired$conf.int[1], fixed_paired$conf.int[2],
            fixed_paired$parameter, fixed_paired$p.value))
# Look at the 95% CI width: pairing makes the interval nearly 2x narrower!


# =============================================================================
# BUG 4: POOLING CORRELATED FELLOW EYES (OD & OS) AS INDEPENDENT PATIENTS
# Prompt to AI: "Pivot OD and OS axial lengths long and run a t-test by lens_group."
# =============================================================================
cat("\n================ BUG 4: Fellow-Eye Pseudoreplication ================\n")

eyes_long <- fellow_eyes |>
  pivot_longer(cols = c(al_od_mm, al_os_mm), names_to = "eye", values_to = "al_mm")

# --- BUGGY AI CODE ---
# Runs an independent t-test on 80 eyes from only 40 patients (df ~ 78)!
# Artificially shrinks SE and inflates false positives because r(OD, OS) > 0.90!
ai_pooled_eyes <- t.test(al_mm ~ lens_group, data = eyes_long)

# --- VERIFIED FIX ---
# Option A: Patient-level average of OD & OS (n = 40 independent patients, df ~ 38)
patient_means <- fellow_eyes |> mutate(al_mean = (al_od_mm + al_os_mm) / 2)
fixed_patient_t <- t.test(al_mean ~ lens_group, data = patient_means)

# Option B: Linear Mixed Model using ALL 80 eyes with random patient intercept `(1 | patient_id)`
fixed_eye_lmm <- lmerTest::lmer(al_mm ~ lens_group + (1 | patient_id), data = eyes_long)
lmm_row <- summary(fixed_eye_lmm)$coefficients["lens_groupSingleVision", ]

cat(sprintf("BUGGY (80 pooled eyes) : df = %5.1f | p = %.4f  <-- FAKE sample size!\n",
            ai_pooled_eyes$parameter, ai_pooled_eyes$p.value))
cat(sprintf("VERIFIED (patient mean): df = %5.1f | p = %.4f\n",
            fixed_patient_t$parameter, fixed_patient_t$p.value))
cat(sprintf("VERIFIED (mixed model) : df = %5.1f | p = %.4f\n",
            lmm_row["df"], lmm_row["Pr(>|t|)"]))


# =============================================================================
# BUG 5: TREATING REPEATED LONGITUDINAL VISITS AS BETWEEN-SUBJECTS!
# Inspired by a REAL AI-generated vision-science teaching script!
# Scenario: 30 students (15 Optometry, 15 Law) have their VA measured across
#           ALL 4 YEARS (Years 1, 2, 3, 4) -> `year` is WITHIN-SUBJECTS!
# =============================================================================
cat("\n================ BUG 5: Longitudinal `year` Treated as Between-Subjects ================\n")

longit_students <- tidyr::expand_grid(
  student_id = 1:30,
  year       = factor(1:4)
) |>
  mutate(
    group         = factor(if_else(student_id <= 15, "Optometry", "Law")),
    student_id    = factor(student_id),
    # Strong individual baseline VA differences (sd = 0.08) + steady yearly progression
    subj_baseline = rep(rnorm(30, 0, 0.08), each = 4),
    far_va        = -0.05 + subj_baseline + 0.025 * (as.numeric(year) - 1) +
                    if_else(group == "Optometry", 0.03, 0) + rnorm(n(), 0, 0.025)
  )

# --- BUGGY AI CODE ---
# Fits an ordinary two-way between-subjects `aov(far_va ~ group * year)`!
# Result: (a) Claims 112 residual df for `group` (fake precision!), AND
#         (b) Dumps huge between-subject baseline noise into the error term for `year`,
#             hiding the true longitudinal progression!
ai_bug_aov <- summary(aov(far_va ~ group * year, data = longit_students))[[1]]

# --- VERIFIED FIX ---
# Mixed-effects model respecting repeated measures within `student_id`:
fixed_lmm_longit <- anova(lmerTest::lmer(far_va ~ group * year + (1 | student_id),
                                         data = longit_students))

cat("BUGGY AI `aov(far_va ~ group * year)` (ignores repeated student_id!):\n")
print(round(ai_bug_aov[, c("Df", "F value", "Pr(>F)")], 4))

cat("\nVERIFIED Mixed Model `lmer(far_va ~ group * year + (1 | student_id))`:\n")
print(round(as.data.frame(fixed_lmm_longit)[, c("NumDF", "DenDF", "F value", "Pr(>F)")], 4))
# LOOK AT THAT CONTRAST:
#   - For `group` (between-subject): Buggy AI claims DenDF = 112 (too optimistic!);
#     Mixed model correctly uses DenDF = 28 (30 independent students!).
#   - For `year` (within-subject): Buggy AI gives a weak F because individual
#     baseline noise wasn't partitioned out; Mixed model removes between-student
#     noise and detects the longitudinal trend with crystal clarity!


# ---- Reflection Exercise ----------------------------------------------------
# Pick ONE of the 5 bugs above. Write a 3-sentence prompt using the D-Q-O-C
# template in `llm-coding-guide/prompt_templates.md` that would PREVENT an LLM
# from making that mistake in the first place!

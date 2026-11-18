# =============================================================================
#  SCRIPT 05: INDEPENDENT & PAIRED t-TESTS, WELCH'S DEFAULT & CORRELATED EYES
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 2 - t-Tests & Uncertainty
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 91-107, 202, 315)
#  Notes   : [BIOSTATS]-NOTES-T-Test for Independent Samples.docx
#  Reuses  : Biostats-1-Week-2.R
#  Datasets: data/02_iop_clinical_trial.csv
#            data/03_fellow_eyes_axial_length.csv
#
#  Topics Covered:
#    1. Independent two-sample t-test: Welch (R's default) vs. Student (pooled)
#    2. Computing Welch's t & Welch-Satterthwaite df by hand vs. t.test()
#    3. Paired t-test: analyzing within-patient change (delta = after - before)
#    4. Two-sided vs. one-sided tests (and the post-hoc switching trap)
#    5. Correlated fellow eyes (OD/OS): demonstrating pseudoreplication!
#    6. Statistical significance vs. clinical relevance (10 um axial length)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)

iop_trial   <- readr::read_csv("data/02_iop_clinical_trial.csv", show_col_types = FALSE)
fellow_eyes <- readr::read_csv("data/03_fellow_eyes_axial_length.csv", show_col_types = FALSE)


# ---- 1. Plot Before Testing: Independent Two-Group IOP Trial (Slides 99-100)
# Clinical question: Compare 4-week IOP change (follow-up - baseline, in mmHg)
# between Drop_A and Drop_B. More negative change = greater IOP reduction.

# First inspect group summaries (check n, mean, SD, and whether variances differ!)
iop_trial |>
  group_by(treatment) |>
  summarize(
    n           = n(),
    mean_change = mean(iop_change),
    sd_change   = sd(iop_change),
    var_change  = var(iop_change),
    .groups     = "drop"
  )

# Visualize individual patient changes before running any test
ggplot(iop_trial, aes(x = treatment, y = iop_change, fill = treatment)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_boxplot(width = 0.42, alpha = 0.5, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2.4, alpha = 0.8) +
  scale_fill_manual(values = c("Drop_A" = "#0072B2", "Drop_B" = "#D55E00")) +
  labs(
    title    = "4-Week IOP Change by Treatment Arm (Simulated Trial)",
    subtitle = "Change = Follow-up - Baseline (more negative = larger IOP reduction)",
    x        = "Treatment Group",
    y        = "IOP Change (mmHg)"
  ) +
  theme(legend.position = "none")


# ---- 2. Welch's vs. Student's Independent t-Test (Slides 97-100, 315) -------
# R's default is Welch's t-test (`var.equal = FALSE`), which does NOT assume
# equal population variances across groups. Always prefer Welch's default!

change_A <- iop_trial$iop_change[iop_trial$treatment == "Drop_A"]
change_B <- iop_trial$iop_change[iop_trial$treatment == "Drop_B"]

# 2a. Welch's two-sample t-test (DEFAULT and RECOMMENDED)
welch_res <- t.test(change_A, change_B, var.equal = FALSE)
print(welch_res)

# Formula interface (gives the exact same result; tidy output via broom)
t.test(iop_change ~ treatment, data = iop_trial) |> broom::tidy()

# 2b. Student's pooled-variance t-test (shown for comparison only)
student_res <- t.test(change_A, change_B, var.equal = TRUE)
print(student_res)

# 2c. Manual verification of Welch's formula & Welch-Satterthwaite df (Slide 98)
n1 <- length(change_A); m1 <- mean(change_A); v1 <- var(change_A)
n2 <- length(change_B); m2 <- mean(change_B); v2 <- var(change_B)

se_welch <- sqrt(v1 / n1 + v2 / n2)
t_welch  <- (m1 - m2) / se_welch
df_welch <- (v1 / n1 + v2 / n2)^2 / ((v1 / n1)^2 / (n1 - 1) + (v2 / n2)^2 / (n2 - 1))
p_welch  <- 2 * pt(-abs(t_welch), df = df_welch)
ci_welch <- (m1 - m2) + c(-1, 1) * qt(0.975, df = df_welch) * se_welch

cat("\n--- Manual Welch Verification ---\n")
cat(sprintf("Mean diff (A - B) = %.3f mmHg | SE = %.3f | t = %.3f | df = %.2f | p = %.5f\n",
            m1 - m2, se_welch, t_welch, df_welch, p_welch))
cat(sprintf("95%% CI: [%.3f, %.3f] mmHg\n", ci_welch[1], ci_welch[2]))

# Useful clinical results sentence (Slide 103):
cat(sprintf(
  "\nRESULTS SENTENCE: Patients on Drop A (n=%d) had a mean 4-week IOP change of %.2f mmHg\nvs. %.2f mmHg on Drop B (n=%d): difference (A - B) = %.2f mmHg (95%% CI [%.2f, %.2f], Welch t=%.2f, p=%.4f).\n",
  n1, m1, m2, n2, m1 - m2, ci_welch[1], ci_welch[2], t_welch, p_welch
))


# ---- 3. Paired t-Test: Within-Patient Change (Slides 101-102) ---------------
# Within Drop_B alone, did 4-week IOP change from baseline?
# Baseline and follow-up are measured on the SAME patients -> MUST keep pairing!

drop_b <- filter(iop_trial, treatment == "Drop_B")

# Plot paired trajectories so the matching is visible (Slide 136)
drop_b |>
  select(patient_id, Baseline = iop_baseline, Followup = iop_followup) |>
  pivot_longer(cols = c(Baseline, Followup), names_to = "visit", values_to = "iop") |>
  ggplot(aes(x = visit, y = iop, group = patient_id)) +
  geom_line(alpha = 0.45, colour = "grey45") +
  geom_point(aes(colour = visit), size = 2.3) +
  scale_colour_manual(values = c("Baseline" = "#D55E00", "Followup" = "#0072B2")) +
  labs(
    title    = "Paired Before-vs-After IOP Measurements (Drop B)",
    subtitle = "Connecting lines preserve within-patient matching",
    x        = "Visit", y = "IOP (mmHg)"
  ) +
  theme(legend.position = "none")

# Method 1: explicit within-patient difference vector `delta = after - before`
delta <- drop_b$iop_followup - drop_b$iop_baseline
paired_via_delta <- t.test(delta, mu = 0)

# Method 2: `paired = TRUE` (order matters: first minus second = after - before!)
paired_direct <- t.test(drop_b$iop_followup, drop_b$iop_baseline, paired = TRUE)

# Verify both are 100% identical!
bind_rows(
  mutate(broom::tidy(paired_via_delta), method = "One-sample t on delta"),
  mutate(broom::tidy(paired_direct),    method = "t.test(after, before, paired = TRUE)")
) |>
  select(method, estimate, statistic, parameter, p.value, conf.low, conf.high)

# Notice WHY pairing helps: look at the positive baseline/follow-up correlation
cat(sprintf("\nWithin-patient correlation r(baseline, followup) = %.3f\n",
            cor(drop_b$iop_baseline, drop_b$iop_followup)))
# Compare standard error when pairing is preserved vs. wrongly ignored!
se_paired_correct <- sd(delta) / sqrt(nrow(drop_b))
se_unpaired_wrong <- sqrt(var(drop_b$iop_followup) / nrow(drop_b) +
                          var(drop_b$iop_baseline) / nrow(drop_b))
cat(sprintf("SE preserving pairing : %.3f mmHg\n", se_paired_correct))
cat(sprintf("SE ignoring pairing   : %.3f mmHg (wastes precision!)\n", se_unpaired_wrong))


# ---- 4. One-Sided vs. Two-Sided Tests (Slides 94-95, 305) -------------------
# Two-sided (`alternative = "two.sided"`, default) tests H0: mu_A = mu_B against
# differences in EITHER direction.
# One-sided (`alternative = "less"` or `"greater"`) must ONLY be used when
# pre-specified BEFORE seeing data! Switching tails post hoc invalidates alpha.
t.test(change_A, change_B, alternative = "less") |> broom::tidy()


# ---- 5. Correlated Fellow Eyes: The Pseudoreplication Pitfall (Slide 202) ---
# In `fellow_eyes`, 40 patients (20 OrthoK, 20 SingleVision) each contribute
# TWO eyes (OD and OS). Fellow eyes are strongly correlated!
cat("\n--- Fellow-Eye Correlation (OD vs. OS Axial Length) ---\n")
cat(sprintf("Pearson r(OD, OS) = %.3f\n",
            cor(fellow_eyes$al_od_mm, fellow_eyes$al_os_mm)))

# WRONG approach: pool all 80 eyes as if they were 80 independent patients
eyes_pooled <- fellow_eyes |>
  pivot_longer(cols = c(al_od_mm, al_os_mm), names_to = "eye", values_to = "al_mm")

wrong_pooled_test <- t.test(al_mm ~ lens_group, data = eyes_pooled)

# VALID simple approaches: (a) patient-level average of OD & OS, or (b) one eye (OD)
fellow_eyes <- fellow_eyes |>
  mutate(al_patient_mean = (al_od_mm + al_os_mm) / 2)

right_patient_mean <- t.test(al_patient_mean ~ lens_group, data = fellow_eyes)
right_od_only      <- t.test(al_od_mm ~ lens_group, data = fellow_eyes)

bind_rows(
  mutate(broom::tidy(wrong_pooled_test),  approach = "WRONG: Pooled eyes (n = 80 eyes)"),
  mutate(broom::tidy(right_patient_mean), approach = "VALID: Patient mean (n = 40 patients)"),
  mutate(broom::tidy(right_od_only),      approach = "VALID: One eye OD only (n = 40 patients)")
) |>
  select(approach, estimate, statistic, df = parameter, p.value, conf.low, conf.high)
# Look at `df`, `conf.low`, `conf.high`, and `p.value`:
# Pooling both eyes artificially doubles df, shrinks the CI, and inflates Type I error!
# (In Script 15 we also show linear mixed models to use both eyes validly.)


# ---- 6. Statistical Significance vs. Clinical Relevance (Slides 104-106) ----
# Example from Slide 104: A 15-micron (0.015 mm) difference in axial length
# is clinically negligible, yet with a huge sample (N = 20,000 per group) it
# produces a tiny p-value!
n_huge <- 20000
al_ctrl <- rnorm(n_huge, mean = 24.500, sd = 0.80)
al_trt  <- rnorm(n_huge, mean = 24.485, sd = 0.80)   # 0.015 mm = 15 microns!
huge_test <- t.test(al_trt, al_ctrl)

cat("\n--- Huge-N Trivial-Effect Demonstration ---\n")
cat(sprintf("Observed diff = %.4f mm (%.1f microns) | 95%% CI [%.4f, %.4f] | p = %.4f\n",
            diff(rev(huge_test$estimate)),
            1000 * diff(rev(huge_test$estimate)),
            huge_test$conf.int[1], huge_test$conf.int[2],
            huge_test$p.value))
# Takeaway: Always judge the CI against a pre-specified clinically meaningful threshold!


# ---- 7. Try It Yourself (Exercises) -----------------------------------------
# 1. Compare `contrast_sens` between Optometry and Graduate_VS students in
#    `data/01_student_vision_clinic.csv` using Welch's t-test. Write a 1-sentence
#    clinical summary reporting group means, difference, 95% CI, and p-value.
# 2. In `data/01_student_vision_clinic.csv`, test whether `near_logmar` differs
#    from `far_logmar` within the same students. Should you use paired = TRUE?
# 3. Check whether `se_od_d` and `se_os_d` in `fellow_eyes` differ on average
#    using a paired t-test. What does the null hypothesis state here?

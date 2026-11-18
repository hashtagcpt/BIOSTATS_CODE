# =============================================================================
#  SCRIPT 09: STUDY DESIGN, RANDOMIZATION, CAUSAL DAGS & EPIDEMIOLOGY RATES
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 6 - Evidence & Experimental Design
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 174-237)
#  Reuses  : Biostats-1-R-learning-script.R (block randomization)
#  Datasets: Simulated randomization schedules, causal DAGs & glaucoma rates
#
#  Topics Covered:
#    1. Bad vs. Good treatment allocation: sequential, alternating, simple random,
#       permuted blocks (`psych::block.random()`), variable-size blocks, and
#       stratified block randomization by age band (Slides 207-212)
#    2. Causal Diagrams (DAGs) in Action via Simulation (Slide 199):
#         - Confounder (Z -> X, Z -> Y)   : MUST adjust (or randomize)
#         - Mediator   (X -> M -> Y)      : Adjusting blocks total causal effect!
#         - Collider   (X -> C <- Y)      : Conditioning creates FAKE bias!
#    3. Public Health & Epidemiology Calculations (Slides 231-233):
#         - Prevalence, Incidence Risk, Incidence Rate (person-years)
#         - Direct Age Standardization of glaucoma rates across two clinics
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(psych)       # For psych::block.random()
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Comparing Treatment Allocation Strategies (Slides 207-212) ----------
# Suppose we enroll 20 patients into a 2-arm myopia trial (Treatment A vs. B).

# 1a. Bad Example 1 (Slide 209): First 10 get A, next 10 get B -> time/season confounding!
alloc_bad <- rep(c("A", "B"), each = 10)

# 1b. Less Bad Example 2 (Slide 210): Strict alternation -> 100% predictable!
alloc_alt <- rep(c("A", "B"), times = 10)

# 1c. Simple randomization (fair coin flip per patient, Slide 207):
#     Unpredictable, but can produce unequal group sizes in small trials!
alloc_simple <- sample(c("A", "B"), size = 20, replace = TRUE)

# 1d. Permuted Block Randomization using psych::block.random() (reused from repo!)
#     Guarantees exact 1:1 balance within every block of size 4.
alloc_block <- psych::block.random(n = 20, ncond = c(treatment = 2)) |>
  as_tibble() |>
  mutate(subject_id = row_number(),
         treatment  = if_else(treatment == 1, "A", "B"))

# 1e. BETTER Clinical Trial Practice (Slide 211 & 220):
#     Randomly VARY block sizes (e.g., blocks of 2, 4, or 6) so recruiters
#     cannot guess the last assignment in a fixed block!
make_variable_blocks <- function(n_total, arms = c("A", "B"), block_sizes = c(2, 4, 6)) {
  out <- character(0)
  while (length(out) < n_total) {
    bs <- sample(block_sizes, 1)
    blk <- sample(rep(arms, each = bs / length(arms)))
    out <- c(out, blk)
  }
  out[1:n_total]
}
alloc_var_block <- make_variable_blocks(20)

tibble(
  subject_id     = 1:20,
  bad_split      = alloc_bad,
  alternating    = alloc_alt,
  simple_coin    = alloc_simple,
  fixed_block_4  = alloc_block$treatment,
  variable_block = alloc_var_block
) |> print(n = 20)

cat("\nSimple coin-flip counts (can be imbalanced in small N):\n")
print(table(alloc_simple))
cat("Variable-block counts:\n")
print(table(alloc_var_block))


# ---- 2. Stratified Block Randomization by Age Band (Slide 212) --------------
# Prespecify prognostic strata (e.g., 4 age bands), then run concealed permuted
# blocks WITHIN each stratum across 4 treatments (A, B, C, D).
age_strata <- c("20-29", "30-39", "40-49", "50-59")
arms_4     <- c("A", "B", "C", "D")

stratified_schedule <- map_dfr(age_strata, \(stratum) {
  # 40 patients per stratum = 10 balanced blocks of 4
  assignments <- unlist(replicate(10, sample(arms_4), simplify = FALSE))
  tibble(
    age_group = stratum,
    slot      = 1:40,
    treatment = assignments
  )
})

cat("\n--- Stratified Block Randomization Table (matches Slide 212) ---\n")
print(table(stratified_schedule$age_group, stratified_schedule$treatment))


# ---- 3. Causal Diagrams (DAGs): Confounder, Mediator, Collider (Slide 199) --
# Controlling for a variable in regression is NOT always good! You MUST draw
# the causal structure first. Let's simulate all three classic DAG motifs
# with N = 2,000 patients so sampling noise is tiny and the structural truth shines!

N_dag <- 2000

# --- 3A. CONFOUNDER: Z -> X and Z -> Y (true causal effect of X on Y is ZERO!) ---
# Example: Age (Z) causes both gray hair / presbyopia reading glasses (X)
#          and cataract opacity (Y), even though reading glasses do NOT cause cataracts!
Z_age       <- rnorm(N_dag, mean = 55, sd = 12)
X_glasses   <- 0.08 * (Z_age - 55) + rnorm(N_dag, 0, 1)
Y_cataract  <- 0.12 * (Z_age - 55) + 0.00 * X_glasses + rnorm(N_dag, 0, 1) # True beta_X = 0!

cat("\n--- DAG 1: CONFOUNDER (True effect of X on Y = 0.00) ---\n")
cat(sprintf("Unadjusted slope (BIASED!)   : %.3f\n", coef(lm(Y_cataract ~ X_glasses))[2]))
cat(sprintf("Adjusted for Z (UNBIASED!)   : %.3f\n", coef(lm(Y_cataract ~ X_glasses + Z_age))[2]))

# --- 3B. MEDIATOR: X -> M -> Y (total causal effect of X on Y is +0.60!) ---
# Example: Topical drop (X) lowers IOP (M), which preserves visual field (Y).
#          If you adjust for post-treatment IOP (M), you block the mechanism
#          and hide the total benefit of the drug!
X_drug <- rbinom(N_dag, 1, 0.5)                      # Randomized!
M_iop_reduction <- 4.0 * X_drug + rnorm(N_dag, 0, 1) # Drug lowers IOP by 4 mmHg
Y_vf_preserved  <- 0.15 * M_iop_reduction + rnorm(N_dag, 0, 0.8) # True total effect = 4*0.15 = +0.60!

cat("\n--- DAG 2: MEDIATOR (True TOTAL effect of X on Y = +0.60) ---\n")
cat(sprintf("Unadjusted total effect (CORRECT)    : %.3f\n", coef(lm(Y_vf_preserved ~ X_drug))[2]))
cat(sprintf("Adjusted for mediator M (BLOCKS IT!) : %.3f\n", coef(lm(Y_vf_preserved ~ X_drug + M_iop_reduction))[2]))

# --- 3C. COLLIDER: X -> C <- Y (X and Y are COMPLETELY INDEPENDENT in population!) ---
# Example: High myopia (X) and Dry Eye (Y) are independent in the community,
#          but BOTH make a person visit an optometry specialty clinic (C = 1).
#          Among clinic patients ONLY (conditioning on collider C = 1),
#          X and Y appear NEGATIVELY correlated (Berkson's paradox)!
X_myopia  <- rnorm(N_dag, 0, 1)
Y_dryeye  <- rnorm(N_dag, 0, 1)                      # Independent of X!
C_clinic  <- (X_myopia + Y_dryeye + rnorm(N_dag, 0, 0.4)) > 1.2

cat("\n--- DAG 3: COLLIDER (True population correlation = 0.00) ---\n")
cat(sprintf("Population correlation r(X, Y)               : %+.3f\n", cor(X_myopia, Y_dryeye)))
cat(sprintf("Clinic-only correlation r(X, Y | C = TRUE)   : %+.3f  <-- FAKE negative association!\n",
            cor(X_myopia[C_clinic], Y_dryeye[C_clinic])))

tibble(X_myopia, Y_dryeye, referred = if_else(C_clinic, "In Specialty Clinic (C=1)", "Not Referred (C=0)")) |>
  ggplot(aes(x = X_myopia, y = Y_dryeye, colour = referred)) +
  geom_point(alpha = 0.45, size = 1.6) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.1) +
  scale_colour_manual(values = c("In Specialty Clinic (C=1)" = "firebrick",
                                 "Not Referred (C=0)"        = "grey65"), name = NULL) +
  labs(
    title    = "Collider Bias (Berkson's Paradox) in Clinic-Based Samples",
    subtitle = "X and Y are independent overall, yet negatively correlated inside the clinic!",
    x        = "Myopia Severity (standardized)", y = "Dry Eye Severity (standardized)"
  ) +
  theme(legend.position = "bottom")


# ---- 4. Public Health Measures & Direct Age Standardization (Slides 231-233)
# Distinguish three core epidemiologic denominators:
#   1. Prevalence      = existing cases / total population at a time point
#   2. Incidence Risk  = new cases / persons at risk at start of period
#   3. Incidence Rate  = new cases / total person-years at risk

prev_pop <- 2000; existing_glaucoma <- 64
at_risk  <- prev_pop - existing_glaucoma
new_cases_3yr <- 29
person_years  <- 5620   # Accounts for staggered enrollment & loss to follow-up

cat("\n--- Basic Epidemiologic Measures (Illustrative Glaucoma Cohort) ---\n")
cat(sprintf("Point Prevalence    : %.2f%% (%d / %d)\n",
            100 * existing_glaucoma / prev_pop, existing_glaucoma, prev_pop))
cat(sprintf("3-Yr Incidence Risk : %.2f%% (%d / %d at risk)\n",
            100 * new_cases_3yr / at_risk, new_cases_3yr, at_risk))
cat(sprintf("Incidence Rate      : %.2f per 1,000 person-years\n",
            1000 * new_cases_3yr / person_years))

# Direct Age Standardization (Slide 233):
# Clinic A (university clinic) has mostly young adults; Clinic B (retirement
# community) has mostly older adults. Comparing CRUDE glaucoma prevalence is
# confounded by age! Applying a common standard population fixes the age mix.
age_std_df <- tibble(
  age_band    = c("40-54", "55-69", "70+"),
  std_weight  = c(0.45, 0.35, 0.20),          # Reference standard population weights
  n_clinic_A  = c(800, 300, 100),             # Younger clinic
  cases_A     = c(12,   15,  10),
  n_clinic_B  = c(100, 300, 800),             # Older clinic
  cases_B     = c(1,    12,  64)
) |>
  mutate(
    rate_A = cases_A / n_clinic_A,
    rate_B = cases_B / n_clinic_B
  )

print(age_std_df)

crude_A <- sum(age_std_df$cases_A) / sum(age_std_df$n_clinic_A)
crude_B <- sum(age_std_df$cases_B) / sum(age_std_df$n_clinic_B)
std_A   <- sum(age_std_df$rate_A * age_std_df$std_weight)
std_B   <- sum(age_std_df$rate_B * age_std_df$std_weight)

cat("\n--- Crude vs. Age-Standardized Glaucoma Prevalence ---\n")
cat(sprintf("Clinic A: Crude = %.2f%% | Age-Standardized = %.2f%%\n", 100 * crude_A, 100 * std_A))
cat(sprintf("Clinic B: Crude = %.2f%% | Age-Standardized = %.2f%%\n", 100 * crude_B, 100 * std_B))
# Look at the reversal: Clinic B's CRUDE rate looks twice as high only because
# its patients are older; its age-standardized rate is actually LOWER than Clinic A!


# ---- 5. Try It Yourself (Exercises) -----------------------------------------
# 1. Generate a variable-block randomization schedule (blocks of 3 or 6) for
#    30 patients across 3 treatments ("Atropine_0.01", "Atropine_0.05", "Placebo").
# 2. In Section 3A (Confounder), verify what happens if X is RANDOMIZED instead
#    of caused by Z: replace `X_glasses` with `rnorm(N_dag)` and check the unadjusted slope.
# 3. Why does direct age standardization make age mixes comparable without
#    automatically removing ALL sources of confounding (Slide 233)?

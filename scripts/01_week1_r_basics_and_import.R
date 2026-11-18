# =============================================================================
#  SCRIPT 01: R BASICS, DATA IMPORT & TIDY CLINICAL DATA
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 1 - Foundations, R & Data Exploration
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 1-15, 29)
#  Notes   : MacFarland & Yates Chapter 1 Notes (Importing Data into R)
#  Reuses  : Biostats-1-R-learning-script.R, Biostats-1-Week-2.R
#  Datasets: data/01_student_vision_clinic.csv
#            data/03_fellow_eyes_axial_length.csv
#
#  How to use:
#    Open BIOSTATS_CODE.Rproj in RStudio so your working directory is the
#    project root, then run one section at a time (Ctrl/Cmd + Enter).
#
#  Note: All CSV datasets in data/ are simulated teaching datasets for
#  optometry and vision science instruction, not real patient records.
# =============================================================================


# ---- 0. Setup & Session Checks ----------------------------------------------

# Start with a clean workspace (good habit at the top of teaching scripts)
rm(list = ls())

# Check your R environment and working directory (from M&Y Ch. 1 notes)
R.version.string
getwd()
date()

# Packages extend base R. You install a package ONCE with install.packages(),
# and load it in EACH new R session with library().
# install.packages("tidyverse")

library(tidyverse)   # Loads dplyr, tidyr, readr, ggplot2, tibble, purrr, etc.


# ---- 1. R as a Calculator & Vision Science Formulas -------------------------

# Basic arithmetic
5 + 3
10 / 2
2^3

# Assign values to named objects using `<-` ("gets" / "goes into").
# Vision science example: luminance contrast formulas.
lum_target     <- 120   # cd/m^2
lum_background <- 100   # cd/m^2

weber_contrast     <- (lum_target - lum_background) / lum_background
michelson_contrast <- (lum_target - lum_background) / (lum_target + lum_background)

cat("Weber contrast    :", round(weber_contrast, 3), "\n")
cat("Michelson contrast:", round(michelson_contrast, 3), "\n")

# R is case-sensitive: `Contrast` and `contrast` are two different objects!
Contrast <- 0.50
contrast <- 0.10
Contrast == contrast   # FALSE

# Built-in mathematical functions
log10(2.0)             # Base-10 logarithm (used in logMAR!)
sqrt(16)               # Square root
round(3.14159, 2)      # Round to 2 decimal places

# Tip: In an interactive RStudio session, type `?mean` or `?read.csv`
# in the Console to read the official documentation for any function.


# ---- 2. Vectors, Data Types & NOIR Measurement Scales -----------------------
# Recall "No Oil In Rivers" (NOIR):
#   Nominal  : Unordered categories (e.g., eye color, treatment label)
#   Ordinal  : Ordered categories without guaranteed equal spacing (e.g., Efron grade)
#   Interval : Equal spacing, arbitrary zero (e.g., Celsius, calendar year)
#   Ratio    : Equal spacing AND meaningful zero (e.g., reaction time in ms, axial length)

# A vector holds a 1D sequence of elements of the SAME type.
iop_vector <- c(14, 16, 18, 20, 22)     # Ratio/continuous numeric vector (mmHg)
eye_colors <- c("Brown", "Blue", "Hazel", "Brown")   # Nominal character vector
efron_ord  <- factor(c("None", "Mild", "Moderate", "Mild"),
                     levels = c("None", "Mild", "Moderate", "Severe"),
                     ordered = TRUE)                 # Ordinal factor

# Inspecting objects (Slides 10 & 12)
str(iop_vector)        # Structure and data type
class(iop_vector)      # Object class
length(iop_vector)     # Number of elements
summary(iop_vector)    # Quick 5-number summary + mean

mean(iop_vector)
sd(iop_vector)

# Always plot before testing! Quick base R plot of the vector (Slide 10)
plot(iop_vector,
     type = "b", pch = 19, col = "steelblue",
     xlab = "Patient Index", ylab = "IOP (mmHg)",
     main = "Quick Inspection of an IOP Vector")


# ---- 3. Importing CSV Data into R -------------------------------------------
# CSV (comma-separated values) is the universal, plain-text standard for
# sharing tabular data cleanly without manual copy-paste edits.

# Base R way: read.csv() returns a standard data.frame
clinic_base <- read.csv("data/01_student_vision_clinic.csv")

# Tidyverse way: readr::read_csv() returns a tibble (prints cleanly with types).
# Notice the `package::function()` namespace syntax (Slide 12 & M&Y Ch. 1):
# it makes explicit which package supplies a function.
clinic <- readr::read_csv("data/01_student_vision_clinic.csv",
                          show_col_types = FALSE)

# Inspect the imported table
head(clinic)           # First 6 rows
glimpse(clinic)        # Compact column-by-column view
summary(clinic)        # Overloaded summary(): numeric quantiles & character counts

# Access a single column with `$`
head(clinic$far_logmar)


# ---- 4. Missing Values (NA) and Sanity Checks (Slide 29) --------------------
# CRITICAL CLINICAL DATA RULE:
#   Use `NA` for missing measurements. NEVER code missing data as `0`!
#   In optometry, 0.0 logMAR is 20/20 acuity and 0 Efron grade is healthy —
#   zero is a real clinical measurement, not a missing value!

# Count missing values in each column
colSums(is.na(clinic))

# Notice what happens when you take the mean of a vector containing NA:
mean(clinic$far_logmar)                  # Returns NA on purpose to warn you!
mean(clinic$far_logmar, na.rm = TRUE)    # Explicitly excludes missing values

# Always report how many complete observations enter each analysis
n_total    <- nrow(clinic)
n_missing  <- sum(is.na(clinic$far_logmar))
n_complete <- sum(!is.na(clinic$far_logmar))
cat(sprintf("far_logmar: %d complete, %d missing (out of %d rows)\n",
            n_complete, n_missing, n_total))

# Check for impossible values or unexpected categories
range(clinic$tbut_sec, na.rm = TRUE)
table(clinic$eye_color, useNA = "ifany")
table(clinic$dry_eye_symptom, useNA = "ifany")


# ---- 5. Data Wrangling with dplyr & the Pipe Operator -----------------------
# The native pipe `|>` (or tidyverse pipe `%>%`) passes the result on the left
# as the first argument to the function on the right. Read it as "and then...".

# 5a. filter(): keep rows meeting a condition
optometry_only <- clinic |>
  filter(program == "Optometry", !is.na(far_logmar))

# 5b. select(): choose specific columns
acuity_cols <- clinic |>
  select(student_id, program, far_logmar, near_logmar, contrast_sens)

# 5c. mutate(): compute new clinical variables
# Convert logMAR to Minimum Angle of Resolution (MAR = 10^logMAR) and Snellen denominator
clinic_derived <- clinic |>
  mutate(
    mar_far            = 10^far_logmar,
    snellen_calc       = round(20 * mar_far, 1),
    acuity_diff_near   = near_logmar - far_logmar
  )
head(select(clinic_derived, student_id, far_logmar, mar_far, snellen_calc))

# 5d. group_by() + summarize(): summary table by group
clinic |>
  group_by(program) |>
  summarize(
    n_rows        = n(),
    n_valid_va    = sum(!is.na(far_logmar)),
    mean_logmar   = mean(far_logmar, na.rm = TRUE),
    sd_logmar     = sd(far_logmar, na.rm = TRUE),
    median_tbut   = median(tbut_sec, na.rm = TRUE),
    iqr_tbut      = IQR(tbut_sec, na.rm = TRUE),
    .groups       = "drop"
  )


# ---- 6. Fundamental Programming: if-else & for Loops ------------------------
# Reused from Biostats-1-R-learning-script.R

# Conditional logic (`if-else`)
patient_age <- 65
if (patient_age >= 60) {
  cat("Age", patient_age, ": include in older-adult AMD screening stratum.\n")
} else {
  cat("Age", patient_age, ": standard adult screening stratum.\n")
}

# Explicit `for` loop (useful to understand, though vectorized R is usually faster)
sample_logmar <- c(-0.10, 0.00, 0.18, 0.30, 1.00)
snellen_loop  <- numeric(length(sample_logmar))   # Pre-allocate output vector!

for (i in seq_along(sample_logmar)) {
  snellen_loop[i] <- round(20 * 10^sample_logmar[i], 1)
}
tibble(logMAR = sample_logmar, Snellen_Denom = snellen_loop)


# ---- 7. Tidy Data: A Row Is an Observation; a Patient Is a Unit (Slide 11) --
# In ophthalmic research, instruments often export WIDE tables with OD and OS
# in separate columns. Many R plotting and mixed-model tools prefer LONG (tidy)
# format: one row per eye measurement, with `patient_id` preserving linkage.

eyes_wide <- readr::read_csv("data/03_fellow_eyes_axial_length.csv",
                             show_col_types = FALSE)
head(eyes_wide)

# Pivot from wide (OD, OS columns) to long (one row per eye) using tidyr::pivot_longer()
eyes_long <- eyes_wide |>
  select(patient_id, lens_group, al_od_mm, al_os_mm) |>
  tidyr::pivot_longer(
    cols      = c(al_od_mm, al_os_mm),
    names_to  = "eye",
    values_to = "axial_length_mm"
  ) |>
  mutate(eye = if_else(eye == "al_od_mm", "OD", "OS"))

head(eyes_long, 8)

# CRITICAL DESIGN CHECK (Slides 11 & 42):
cat("Number of rows (eye measurements):", nrow(eyes_long), "\n")
cat("Number of independent patients   :", n_distinct(eyes_long$patient_id), "\n")
# Remember: 80 eye rows from 40 patients are NOT 80 independent patients!
# We will test the statistical consequence of pooling eyes in Script 05.


# ---- 8. Try It Yourself (Exercises) -----------------------------------------
# 1. Filter `clinic` to students with `tbut_sec < 8` seconds. How many are there?
# 2. Using `mutate()`, add a column `cct_adjusted_iop` to `data/02_iop_clinical_trial.csv`
#    using the rule of thumb: iop_baseline - (cct_um - 545) / 20.
# 3. Pivot `se_od_d` and `se_os_d` from `eyes_wide` into long format.
# 4. Explain in one sentence why replacing `NA` with `0` in `far_logmar` would
#    bias the group mean acuity.

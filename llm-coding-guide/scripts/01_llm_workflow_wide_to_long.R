# =============================================================================
#  LLM CODING LAB 01: WHY CHOICES MATTER WHEN WORKING WITH LLMs IN R
#  Course  : Biostatistics & Experimental Design I & II (NECO)
#  Source  : Adapted & expanded from `choices_matter_with_llms.R` (biostats-2)
#  Dataset : biostats-2/data/full_data.csv
#
#  Key Lesson for Non-Programmers:
#    "It matters when you bring the LLM on your team. Simpler and cleaner is better."
#    This script demonstrates two practical habits that prevent hours of AI
#    debugging rabbit holes:
#      1. Use `readr::read_csv()` (tidyverse) over base `read.csv()` when
#         column names contain symbols (like `S+` and `S-`), because base R
#         silently rewrites `S-` into `S.` — breaking downstream LLM code!
#      2. Always share `glimpse()` (exact column names & types) with your LLM
#         so it writes clean `tidyr::pivot_longer()` code on the first try.
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)


# ---- 1. Prepare a Realistic Wide Vision-Science Table -----------------------
# Load cone-isolating contrast thresholds and log10-transform them
d_full <- read.csv("biostats-2/data/full_data.csv", check.names = TRUE)

d_wide <- tibble(
  subject = factor(d_full$subject),
  RE      = d_full$RE,
  A       = log10(d_full$thr1),
  L       = log10(d_full$thr2),
  M       = log10(d_full$thr3),
  `S-`    = log10(d_full$thr4),   # Notice the minus and plus signs in column names!
  `S+`    = log10(d_full$thr5),
  S       = log10(d_full$thr6)
)

# Save to a temporary file so we can compare base `read.csv()` vs. `readr::read_csv()`
tmp_csv <- tempfile(fileext = ".csv")
readr::write_csv(d_wide, tmp_csv)


# ---- 2. The Classic Rabbit Hole: Base `read.csv()` Silently Renames Columns!
# Watch what happens if you read the exact same file with base `read.csv()`
# versus tidyverse `readr::read_csv()`:
df_base <- read.csv(tmp_csv)
df_tidy <- readr::read_csv(tmp_csv, show_col_types = FALSE)

cat("Column names from base read.csv()        :", paste(names(df_base), collapse = ", "), "\n")
cat("Column names from tidyverse read_csv()   :", paste(names(df_tidy), collapse = ", "), "\n")
# LOOK CLOSELY! Base `read.csv()` silently turned `S-` and `S+` into `S.` and `S..1`!
# If you ask an LLM to pivot `S-` and `S+` after using `read.csv()`, the code
# crashes — or worse, grabs the wrong column!


# ---- 3. What to Paste into Your LLM Prompt: `glimpse()` ---------------------
# Before asking an LLM to reshape or plot `df_tidy`, run `glimpse(df_tidy)` and
# paste this short schema (NOT private patient data!) into your prompt:
cat("\n--- Output of glimpse(df_tidy) (safe schema to share with an LLM) ---\n")
glimpse(df_tidy)


# ---- 4. Clean LLM-Assisted Wide-to-Long Pivot -------------------------------
# Prompt given to LLM:
#   "Using modern tidyverse (`pivot_longer`), pivot `df_tidy` from wide to long,
#    keeping `subject` and `RE` as identifiers and naming the new columns
#    `stimulus` and `log_threshold`."

d_long <- df_tidy |>
  tidyr::pivot_longer(
    cols      = -c(subject, RE),
    names_to  = "stimulus",
    values_to = "log_threshold"
  )

# ALWAYS verify after an LLM pivot:
#   - Expected rows = nrow(df_tidy) * 6 conditions
#   - Unique subjects should be UNCHANGED!
cat(sprintf("\nVerification: wide rows = %d | long rows = %d (expected %d) | unique subjects = %d\n",
            nrow(df_tidy), nrow(d_long), nrow(df_tidy) * 6, n_distinct(d_long$subject)))
head(d_long, 8)

# Clean up temporary file
unlink(tmp_csv)


# ---- 5. Key Takeaway --------------------------------------------------------
# Clean column names (like `S_neg` and `S_pos` instead of `S-` and `S+`),
# modern tidyverse functions (`read_csv`, `pivot_longer`), and sharing `glimpse()`
# eliminate 90% of beginner frustrations when pairing R with an LLM!

# =============================================================================
#  BIOSTATS 2 — SCRIPT 01: R PROGRAMMING FUNDAMENTALS & MULTI-FORMAT DATA I/O
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_1_script.R & B2_Lecture_2_script_with_assignment.R
#  Datasets: biostats-2/data/Example-Data-1.csv
#            biostats-2/data/Example-Data-1.xlsx
#            biostats-2/data/CPT_1_16_blurLevelDiscrim.mat
#
#  How to use:
#    Open BIOSTATS_CODE.Rproj in RStudio so your working directory is the
#    repository root, then run one section at a time (Ctrl/Cmd + Enter).
#
#  Topics Covered:
#    1. R as a calculator, variable reassignment, vectors & case sensitivity
#    2. Data frames & indexing (`[row, col]` vs. `$column`)
#    3. Reading clinical/lab data from CSV, Excel (.xlsx), and MATLAB (.mat)
#    4. Control flow: `if / else if / else`, `for` loops, and `while` loops
#    5. Writing reusable user-defined functions (including default arguments)
#    6. Worked Exercise: The "Lucky Number 13" function in pure base R
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())

# Install once if missing:
# install.packages(c("tidyverse", "readxl", "R.matlab"))
library(tidyverse)
library(readxl)
library(R.matlab)


# ---- 1. R as a Calculator & Variable Overwriting ----------------------------
21 + 49
v    <- 21 + 49
v1.1 <- 7 * 3 + 7 * 7

# Number trick demonstrating how variables get overwritten step-by-step:
# Pick any number from 1 to 10 -> result is ALWAYS 3!
original <- 4
x <- original
x <- x * 2         # double it
x <- x * 5         # multiply by 5
x <- x / original  # divide by original number
x <- x - 7         # subtract 7
cat("Number trick result (always 3):", x, "\n")

# Vectors (`c()` = concatenate) and case sensitivity (`x` != `X`)
x       <- c(1, 2, 3)
X       <- 1:10
letters_vec <- c("a", "b", "c")

# Common math functions and modulo (`%%` = remainder after integer division)
v2    <- round(7^1.565) + 7^2
vRoot <- sqrt(v2)
cat("ln(v2) =", round(log(v2), 3), "| log10(sqrt(v2)) =", round(log10(vRoot), 3), "\n")
cat("Remainder of 13 / 4 (13 %% 4) =", 13 %% 4, "\n")

# Conceptual check: What is the value of `y` after line 3 below?
# (Answer: 100 — changing `x` later does NOT retroactively change `y`!)
x_check <- 50
y_check <- x_check * 2
x_check <- 80
cat("y_check is still:", y_check, "\n")


# ---- 2. Data Frames & Indexing ----------------------------------------------
# A data frame stores a table where each column can have its own data type.
psychophys_mini <- tibble(
  subject   = 1:4,
  sex       = c("M", "F", "F", "M"),
  threshold = c(0.013, 0.021, 0.011, 0.011)
)
print(psychophys_mini)

# Square-bracket indexing `[row, col]` vs. named `$` column access:
psychophys_mini[3, 3]          # Row 3, Column 3 (subject 3's threshold)
psychophys_mini[3, ]           # Entire Row 3 (all variables for subject 3)
psychophys_mini[, 3]           # Entire Column 3
psychophys_mini$threshold      # Preferred: self-documenting access by column name


# ---- 3. Importing Real Lab Formats: CSV, Excel (.xlsx) & MATLAB (.mat) ------
# Vision science labs routinely output CSV, Excel spreadsheets, and MATLAB files.
# Using relative paths from `BIOSTATS_CODE.Rproj` keeps scripts portable across
# macOS and Windows without fragile `setwd()` calls!

# 3a. CSV (base R vs. tidyverse)
example_csv  <- read.csv("biostats-2/data/Example-Data-1.csv")
example_tidy <- readr::read_csv("biostats-2/data/Example-Data-1.csv", show_col_types = FALSE)
head(example_tidy)

# 3b. Excel (.xlsx) — specify sheet index or sheet name
example_xlsx <- readxl::read_xlsx("biostats-2/data/Example-Data-1.xlsx", sheet = 1)
head(example_xlsx)

# 3c. MATLAB (.mat) — common in Psychtoolbox / visual psychophysics rigs
example_mat <- R.matlab::readMat("biostats-2/data/CPT_1_16_blurLevelDiscrim.mat")
cat("\nTop-level variables inside CPT_1_16_blurLevelDiscrim.mat:\n")
print(names(example_mat))


# ---- 4. Control Flow: if / else if / else, for Loops & while Loops ----------

# 4a. Conditional branching (`if` / `else if` / `else`)
blue_jays_win_pct <- 0.562
if (blue_jays_win_pct > 0.600) {
  cat("The Blue Jays are better than OK!\n")
} else if (blue_jays_win_pct >= 0.500) {
  cat("OK Blue Jays!\n")
} else if (blue_jays_win_pct > 0) {
  cat("Not OK Blue Jays.\n")
} else {
  cat("Is it winter? Go Leafs Go.\n")
}

# 4b. `for` loop — use when you know the number of iterations in advance
# Pre-allocate an output vector instead of growing it inside the loop!
od_squared <- numeric(nrow(example_csv))
for (i in seq_len(nrow(example_csv))) {
  od_squared[i] <- example_csv$OD[i]^2
}
cat("\nFirst 5 squared OD values (from for loop):", round(head(od_squared, 5), 3), "\n")

# Note: In R, arithmetic is vectorized, so `example_csv$OD^2` gives the exact
# same result in one line! Loops shine when each step depends on the previous step.

# 4c. `while` loop — use when you repeat UNTIL a condition stops being true
ctr <- 1
od_sq_while <- numeric(nrow(example_csv))
while (ctr <= nrow(example_csv)) {
  od_sq_while[ctr] <- example_csv$OD[ctr]^2
  ctr <- ctr + 1   # Always increment the counter, or the loop runs forever!
}
cat("for and while loop results identical?", identical(od_squared, od_sq_while), "\n")


# ---- 5. Writing Reusable User-Defined Functions -----------------------------
# Functions turn repeated analysis steps into a single named, testable tool.
# Setting `var2 = 0` gives `var2` a default value when omitted by the caller.
funny_add <- function(var1, var2 = 0) {
  var1 + var2 + (var1 / 2) + (var2 / 2)
}

eye_combined <- funny_add(example_csv$OD, example_csv$OS)
cat("\nfunny_add(OD, OS) first 5 values:", round(head(eye_combined, 5), 3), "\n")
cat("funny_add(5) with default var2=0:", funny_add(5), "\n")


# ---- 6. Worked Exercise: The "Lucky Number 13" Function ---------------------
# Multiply any integer 1..10 by 9, sum its digits, and add 4 -> ALWAYS 13!
# (Pure base R digit extraction — no external package required.)
lucky13 <- function(n) {
  stopifnot(is.numeric(n), n >= 1, n <= 10, n == floor(n))
  product_val <- n * 9
  digit_chars <- strsplit(as.character(product_val), split = "")[[1]]
  digit_sum   <- sum(as.integer(digit_chars))
  digit_sum + 4
}

# Verify across every integer from 1 through 10!
tibble(
  input_n = 1:10,
  result  = map_int(1:10, lucky13)
)


# ---- 7. Try It Yourself (Exercises) -----------------------------------------
# 1. Write a function `snellen_to_logmar(denom)` that converts a Snellen
#    denominator (e.g., 20, 40, 200) into logMAR (`log10(denom / 20)`).
# 2. Using a `for` loop, print all multiples of 7 between 1 and 100.
# 3. Inspect `example_tidy`: notice the column typo `Subect` in the raw CSV!
#    Use `dplyr::rename(subject = Subect)` to fix it cleanly in R without
#    editing the raw CSV file on disk.

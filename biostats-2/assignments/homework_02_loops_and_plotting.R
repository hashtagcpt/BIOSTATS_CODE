# =============================================================================
#  BIOSTATS 2 — HOMEWORK 2: EXCEL IMPORT, FOR LOOPS, INDEXING & GGPLOT2
#  How to use: Save a copy as [yourname]_homework_2.R and fill in each section.
# =============================================================================

library(tidyverse)
library(readxl)

# --- Question 1 ---
# Read the Excel dataset `biostats-2/data/Example-Data-1.xlsx` (sheet 1) into R
# using `readxl::read_xlsx()` and inspect its first rows with `head()`.
# YOUR CODE HERE:


# --- Question 2 ---
# Complete the `for` loop below to print all integers from 1 to 500 that are
# evenly divisible by 13. (Hint: use the modulo operator `counter %% 13 == 0`.)
limit <- 500

for (counter in 1:limit) {
  # Replace `FALSE` with the modulo condition:
  if (FALSE) {
    print(counter)
  }
}


# --- Question 3 ---
# Modify the `for` loop so that instead of printing, it STORES every multiple
# of 13 in a numeric vector `X` using a second counter and square-bracket indexing.
X <- numeric(0)
second_counter <- 0

for (counter in 1:limit) {
  if (counter %% 13 == 0) {
    second_counter <- second_counter + 1
    # Replace 0 below so X[second_counter] stores `counter`:
    # X[second_counter] <- ???
  }
}


# --- Question 4 ---
# Create an index vector `Y <- seq_len(length(X))`, combine `X` and `Y` into a
# tibble, and make a scatterplot of `Y` vs. `X` using `ggplot()` + `geom_point()`
# with clear axis labels and `theme_minimal()`.
# (Note: Modern ggplot2 replaces legacy `qplot()` with `ggplot(df, aes(...))`!)
# YOUR CODE HERE:

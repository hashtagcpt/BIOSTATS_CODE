# =============================================================================
#  BIOSTATS 2 — ASSIGNMENT 1: DATA IMPORT, CONTROL FLOW & WRITING FUNCTIONS
#  Submission: Save a copy as [yourfullname]_assignment_1.R (no spaces).
#  Prerequisites: Open BIOSTATS_CODE.Rproj so relative paths work cleanly.
# =============================================================================

library(tidyverse)

# --- A1.1 [2 points] ---
# Choose a CSV dataset from `biostats-1/data/`, `biostats-2/data/`, or your own
# research (if using your own, include the citation/file with your submission).
# Write a 1-sentence comment stating which dataset you chose and what it measures.
# YOUR COMMENT HERE:


# --- A1.2 [2 points] ---
# Load the dataset into R using `read.csv()` or `readr::read_csv()` and assign
# it to an object (e.g., `d`).
# YOUR CODE HERE:


# --- A1.3 [2 points] ---
# Run `summary(d)` on your dataset. In a 2-3 sentence comment below, describe
# what information `summary()` reports for numeric columns vs. text/factor columns.
# YOUR CODE & COMMENT HERE:


# --- A1.4 [1 point] ---
# Create a two-element character vector using `c()` named `trick_type`
# containing the strings "trick1" and "trick2".
# YOUR CODE HERE:


# --- A1.5 [3 points] ---
# Write an `if / else if / else` block controlled by a variable `do_trick`
# (and an input variable `user_guess` set outside the `if` statement):
#   - If `do_trick == "trick1"`, run the "always 3" number trick on `user_guess`.
#   - Else if `do_trick == "trick2"`, run the "Lucky 13" trick on `user_guess`.
#   - Else, print "That is not a valid trick".
# Test your code with valid AND invalid values of `do_trick`!
# YOUR CODE HERE:


# --- A1.6 [6 points] ---
# Write a function called `trimmed_mean(data_to_trim, sd_cutoff)` that removes
# observations MORE than `sd_cutoff` standard deviations ABOVE OR BELOW the
# sample mean, then returns the mean of the remaining observations.
#
# Starter demonstration (handles upper tail only — your function must trim BOTH tails!):
set.seed(416)
x <- rnorm(1000)
xsd <- sd(x)
xbar <- mean(x)
sd_cutoff_demo <- 2
x_upper_only <- x[x < (xbar + sd_cutoff_demo * xsd)]
cat("Untrimmed mean:", mean(x), "| Upper-trimmed mean:", mean(x_upper_only), "\n")

# Fill in your function below (remember: check BOTH `> mean - cutoff*sd` AND `< mean + cutoff*sd`!):
trimmed_mean <- function(data_to_trim, sd_cutoff = 2) {
  # YOUR TRIMMING CODE GOES HERE
  tm <- NA_real_
  return(tm)
}

# Test your function on `x` with `sd_cutoff = 1` and `sd_cutoff = 2`, and add a
# short comment explaining when a trimmed (or winsorized) mean is useful in clinic/lab data.
# YOUR TEST & COMMENT HERE:

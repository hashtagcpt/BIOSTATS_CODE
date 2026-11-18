# =============================================================================
#  BIOSTATS 2 — HOMEWORK 1: R BASICS & READING DOCUMENTATION
#  How to use: Save a copy as [yourname]_homework_1.R and fill in each section.
# =============================================================================

# Recommended reading: http://www.cookbook-r.com/Basics/
# (Run `browseURL("http://www.cookbook-r.com/Basics/")` interactively if desired.)

# --- Question 1 ---
# Create a positive numeric variable and compute its natural log (`log()`)
# and base-10 log (`log10()`).
# YOUR CODE HERE:


# --- Question 2 ---
# Create a numeric vector using `c()` and compute its mean BY HAND using
# `sum()` and `length()`, then verify your answer with `mean()`.
# YOUR CODE HERE:


# --- Question 3 ---
# Run the code block below. Above EACH line, write a short comment explaining
# in your own words what that command does. (Hint: check `?set.seed`, `?rnorm`,
# `?rt`, and `?t.test` in the RStudio Console.)

# [Comment 1: what does set.seed(100) do?]
set.seed(100)

# [Comment 2: what does rnorm(20) do?]
x <- rnorm(20)

# [Comment 3: what does rt(20, df = 50) do?]
y <- rt(20, df = 50)

# [Comment 4: what does data.frame(x, y) do?]
random_data <- data.frame(x, y)

# [Comment 5: what does t.test(..., var.equal = FALSE) do?]
t.test(random_data$x, random_data$y, var.equal = FALSE)


# --- Question 4 ---
# Re-run `t.test()` above with `var.equal = TRUE`. In a comment, explain how
# changing `var.equal` alters the test R calculates (degrees of freedom,
# variance assumption, and why R defaults to `FALSE`).
# YOUR CODE & EXPLANATION HERE:

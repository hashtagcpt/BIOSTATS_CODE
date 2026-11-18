> **Navigation:** [Back to LLM Coding Guide](README.md) | [Plain-Text Version (.txt) for Easy Cut/Paste](prompt_templates.txt) | [BIOSTATS_CODE Hub](../README.md)

# Copy-Paste Prompt Templates for R & Biostatistics

Replace the bracketed `[...]` sections with your own dataset details. Remember: **never paste real patient data (PHI)**—paste only `glimpse()` structure or 3–5 made-up rows!

---

## 1. Importing & Checking a New CSV or Excel File
```text
I am an optometry graduate student learning R (R >= 4.1, tidyverse).
I have a CSV file at "biostats-1/data/01_student_vision_clinic.csv" with columns:
[paste column names here].

Write a short, well-commented R script that:
1. Loads the file with readr::read_csv() (do NOT use setwd()).
2. Prints the number of rows, data types (glimpse), and missing value count per column.
3. Checks for unusual min/max values in numeric columns and frequency tables for categorical columns.
Keep the code simple for a beginner and explain each step in comments.
```

## 2. Reshaping Wide Data (OD/OS or Pre/Post) to Tidy Long Format
```text
I have a tibble `dat` in R in WIDE format. Here is its glimpse() output:
[paste glimpse(dat) here]

Each row is one patient (`patient_id`), with two measurement columns (`al_od_mm`, `al_os_mm`).
Write modern tidyverse code using `tidyr::pivot_longer()` (NOT melt or gather) to create
a long table with columns `patient_id`, `eye` ("OD" or "OS"), and `axial_length_mm`.
Include a verification line checking that `n_distinct(patient_id)` did not change.
```

## 3. Explaining Unfamiliar R Code (Learning Mode)
```text
I am new to R programming. Explain the following R code line by line in plain English,
especially what the pipe `|>` and any function arguments are doing. Do not rewrite the code—just explain it:

[paste 5–15 lines of R code here]
```

## 4. Debugging an R Error Message
```text
I ran this R code (tidyverse loaded):
[paste the 5–15 lines of code]

And got this exact error:
[paste the exact red error text from the Console]

Here is `glimpse()` of my data frame:
[paste glimpse(df) output]

In 1–2 sentences, explain WHY this error happened, then give me the smallest fix.
```

## 5. Building a Publication-Ready `ggplot2` Figure
```text
Using `ggplot2` (modern syntax, no deprecated `size` for lines—use `linewidth`),
write R code to plot `iop_change` (y-axis, mmHg) by `treatment` (x-axis) from a tibble `iop_trial`.
Requirements:
- Show boxplots with `outlier.shape = NA` overlaid with jittered individual patient points.
- Add a horizontal dashed reference line at y = 0.
- Use a colorblind-friendly palette (or grayscale for a journal figure) and `theme_minimal(base_size = 14)`.
- Label axes with units and add a subtitle explaining that negative values mean IOP reduction.
```

## 6. Checking Whether a Statistical Test Matches Your Study Design
```text
Before writing R code, check my study design and tell me what statistical assumptions matter:
- Clinical question: [e.g., Compare 4-week IOP change between Drop A and Drop B]
- Sample unit: [e.g., 30 independent patients per group, ONE eye per patient]
- Outcome variable & scale: [e.g., continuous IOP change in mmHg]
- Potential issues: [e.g., unequal group variances, 2 missing follow-up visits]

Recommend an appropriate primary test and R function (keeping safe defaults like Welch's
t-test `var.equal = FALSE`), explain what plot to inspect first, and list 2 common mistakes to avoid.
```

## 7. Turning Repeated Code into a Clean R Function
```text
I copied and pasted this block of R code 4 times for different columns/files:
[paste 1 repeated block]

Refactor it into a clean, well-commented R function with clear argument names and show
how to call it once and across all 4 inputs using `purrr::map_dfr()`.
```

## 8. Self-Auditing Your Own Script for Silent Statistical Bugs
```text
Act as a strict biostatistics peer reviewer for an optometry journal.
Review my R script below ONLY for statistical or data-handling bugs—do not rewrite everything stylistically.
Specifically check:
1. Are repeated visits or fellow eyes (OD/OS) accidentally treated as independent observations?
2. Are `paired = TRUE`, `var.equal = FALSE`, and the subtraction direction (`after - before`) correct?
3. Are missing values (`NA`) handled transparently without turning them into 0?
4. Are multiple comparisons or post-hoc tests handled appropriately?

[paste your script + 2-sentence study design description here]
```

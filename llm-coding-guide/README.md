> **Navigation:** [Back to BIOSTATS_CODE Hub](../README.md) | [Biostats I](../biostats-1/README.md) | [Biostats II](../biostats-2/README.md) | [Prompt Templates (Markdown)](prompt_templates.md) | [Prompt Templates (Plain Text .txt)](prompt_templates.txt)

# Using LLM Coding Tools in Biostatistics (Beginner's Guide)

Most optometry and vision-science graduate students enter Biostats I & II with **little to no programming experience**. Modern Large Language Model (LLM) coding tools—such as **ChatGPT**, **Claude**, **Gemini**, **GitHub Copilot**, and **Positron/RStudio AI assistants**—can dramatically lower the barrier to learning R, helping you get past frustrating syntax errors so you can focus on **experimental design, clinical data, and statistical reasoning**.

However, LLMs have one dangerous quirk in biostatistics: **they write fluent, confident R code that runs without errors even when the statistical test is completely wrong for your study design.**

> **The Golden Rule:** *You are the Principal Investigator; the LLM is a fast, eager, occasionally overconfident research assistant.*
> You own the research question, the study design, and the interpretation. The LLM helps draft and debug R syntax. **Never trust statistical output you have not checked against your design and a plot of your raw data.**

---

## What's in This Folder

| File | What You Will Learn |
|---|---|
| [`README.md`](README.md) *(this file)* | Complete beginner workflow, privacy rules, and the 6-Point Statistical Sanity Checklist |
| [`prompt_templates.md`](prompt_templates.md) | 8 copy-paste prompt recipes formatted in Markdown (great for browsing on GitHub with the copy button) |
| [`prompt_templates.txt`](prompt_templates.txt) | **Plain-text version** of all 8 prompt templates—easy to open in RStudio/Notepad/TextEdit and cut/paste cleanly with no Markdown formatting |
| [`scripts/01_llm_workflow_wide_to_long.R`](scripts/01_llm_workflow_wide_to_long.R) | Hands-on example (adapted from `choices_matter_with_llms.R`): why clean tidyverse steps + good context keep LLMs out of coding "rabbit holes" |
| [`scripts/02_catching_ai_stats_bugs_lab.R`](scripts/02_catching_ai_stats_bugs_lab.R) | Interactive R lab featuring **5 real, silent AI statistical bugs** (all run without R errors!) and how to spot and fix every single one |

---

## The 5-Step R + LLM Workflow for Beginners

### Step 1: Inspect Your Data in R *Before* Opening an LLM
Never ask an LLM to analyze a file it cannot see! First run these three safe commands in RStudio:

```r
library(tidyverse)
dat <- readr::read_csv("biostats-1/data/02_iop_clinical_trial.csv")
glimpse(dat)           # Shows exact column names and data types
colSums(is.na(dat))    # Shows where missing values exist
```

Now you know the exact column names (`iop_baseline`, `iop_followup`, `treatment`), variable types, and missingness—which prevents 80% of AI hallucinations.

### Step 2: Write a Structured Prompt (**D-Q-O-C**)
Vague prompts (*"run a t-test on my eye data"*) produce broken or statistically wrong code. Instead, include four short pieces of information:

1. **D — Data structure:** Paste the output of `glimpse(dat)` (never real patient records!) and state the **independent unit** (e.g., *"each row is one independent patient"* or *"each patient has two rows, OD and OS"*).
2. **Q — Clinical / statistical question:** State what you want to compare, in what direction (`followup - baseline`), and with what plot or test.
3. **O — Output style:** Ask for *"modern tidyverse (`dplyr`, `tidyr`, `ggplot2`), well-commented for an R beginner, no `setwd()`."*
4. **C — Constraints:** Tell the LLM what to avoid (e.g., *"keep Welch's default `var.equal = FALSE`," "do NOT replace `NA` with 0," "show individual points on top of boxplots"*).

See [`prompt_templates.md`](prompt_templates.md) for copy-paste examples!

### Step 3: Run AI Code One Small Chunk at a Time
Never paste 80 lines of AI code and hit "Run All." Instead:
- Run **5–10 lines at a time** (`Ctrl + Enter` / `Cmd + Enter`).
- Check the **Environment pane** (did the row count stay right after a join or pivot?).
- Check the **Plots pane** (do the numbers and signs look clinically plausible?).
- If you see a function you don't recognize (like `pivot_longer()` or `fct_recode()`), ask the LLM: *"Explain lines 10–15 to a beginner in plain English."*

### Step 4: Debug Errors Like a Pro
When R prints red error text, **don't panic—R errors are clues!** Copy and paste into the LLM:
1. The **exact code lines** you ran (5–15 lines),
2. The **exact error message** from the R Console, and
3. The output of `glimpse(your_data)`.

Ask: *"Explain WHY this error happened in one sentence, then show the minimal fix."*

### Step 5: Run the 6-Point Statistical Sanity Checklist
Before believing *any* p-value, confidence interval, or plot generated with LLM help, verify all 6 items:

- [ ] **1. Independent unit check:** Did the code treat repeated visits or fellow eyes (OD & OS) as independent patients? *(Check `df`! If you have 40 patients, `df` for a two-sample test cannot be 78!)*
- [ ] **2. Pairing check:** For before/after or OD/OS within-person comparisons, did it include `paired = TRUE` (or analyze `delta = after - before`)?
- [ ] **3. Direction / sign check:** Does a negative mean difference mean IOP *dropped* or *rose*? Verify by checking `group_by() |> summarize(mean = ...)` directly!
- [ ] **4. Missing data (`NA`) check:** Did the LLM silently drop rows or—worse—replace `NA` with `0`? Count `sum(is.na(...))` explicitly.
- [ ] **5. Defaults & assumptions check:** Did it override R's safer defaults (e.g., sneaking in `var.equal = TRUE` for a *t*-test, or `family = gaussian` for binary data)?
- [ ] **6. Visual sanity check:** Plot the raw observations (`geom_boxplot()` + `geom_jitter()` or scatterplot). Does the printed statistic agree with what your eyes see?

---

## Privacy, Clinical Data (PHI) & Academic Integrity

1. **NEVER paste real patient data (PHI) into public LLM chats.**
   - Do not upload clinical spreadsheets containing patient names, dates of birth, medical record numbers, or unpublished IRB-protected clinic data.
   - Instead, share **only** the column names and 3–5 **made-up fake rows** (or the `glimpse()` schema of a simulated file).
2. **Use LLMs to learn, not to bypass understanding.**
   - For course assignments, you must be able to explain every line of code and every statistical choice in your own words.
   - When an LLM helps you debug syntax or polish a `ggplot2` theme, add a brief comment in your script noting how you used it.
3. **Beware of "version drift" and made-up packages.**
   - LLMs sometimes suggest obsolete functions (`reshape2::melt()`, `tidyr::gather()`, `ggplot2::qplot()`, `plyr::revalue()`) or packages that aren't installed. Ask for **base R + modern `tidyverse`** (`tidyr::pivot_longer()`, `dplyr::mutate()`, `ggplot2::ggplot()`).

---

## Try the Two Hands-On Labs Next
1. Open and run [`scripts/01_llm_workflow_wide_to_long.R`](scripts/01_llm_workflow_wide_to_long.R) to see how keeping data workflows simple and tidy makes LLM collaboration smooth.
2. Open and run [`scripts/02_catching_ai_stats_bugs_lab.R`](scripts/02_catching_ai_stats_bugs_lab.R) to practice catching 5 realistic, silent AI statistical bugs in optometry datasets!

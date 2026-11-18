# Biostats II Assignments & Homeworks (`biostats-2/assignments/`)

> **Navigation:** [Back to BIOSTATS_CODE Hub](../../README.md) | [Biostats II Home](../README.md) | [Using LLM Coding Tools](../../llm-coding-guide/README.md)

This folder contains clean starter templates for every Biostats II homework and graded assignment.

## How to Complete & Submit an Assignment
1. Open **`BIOSTATS_CODE.Rproj`** in RStudio so your working directory is the repository root.
2. Open the starter `.R` file for the assignment below and immediately choose **File -> Save As...** using the required naming convention:
   - `[yourfullname]_assignment_1.R` (no spaces, e.g., `JaneDoe_assignment_1.R`).
3. Fill in your code and written comments under each question heading.
4. Before submitting, restart R (**Session -> Restart R**) and **Source** your entire script from top to bottom to guarantee it runs cleanly without errors or missing packages.

## Assignment Directory

| File | Associated Lectures | Primary Datasets | Core Skills Practiced |
|---|---|---|---|
| [`homework_01_r_basics.R`](homework_01_r_basics.R) | Lecture 1 | Simulated | Basic R syntax, `rnorm()`, `rt()`, `t.test()`, reading R help |
| [`homework_02_loops_and_plotting.R`](homework_02_loops_and_plotting.R) | Lectures 1–2 | `Example-Data-1.xlsx` | Reading Excel files, `for` loops, modulo `%%`, indexing, `ggplot2` |
| [`assignment_01_data_and_functions.R`](assignment_01_data_and_functions.R) | Lectures 1–2 | Choice of CSV | Data import, `summary()`, `if/else`, writing a custom `trimmed_mean()` function |
| [`assignment_02_plots_tables_and_tests.R`](assignment_02_plots_tables_and_tests.R) | Lectures 3–4 | `rbg_noise_ir_data.csv`, `rgb_monitor.csv`, `full_data.csv` | Grayscale `ggplot2` + `patchwork`, `t.test()` + FDR `p.adjust()`, `kable()` table, `cor.test()` |
| [`assignment_03_bootstrap_and_anova.R`](assignment_03_bootstrap_and_anova.R) | Lectures 5–6 | `full_data.csv`, `Monitor_Birds.csv` | Bootstrap regression & correlation CIs, Levene's test, One-Way ANOVA, `TukeyHSD()` |
| [`assignment_04_bayes_power_and_psychometrics.R`](assignment_04_bayes_power_and_psychometrics.R) | Lectures 7–9 | `full_data.csv` + simulated | `regressionBF()`, `pwr.r.test()`, psychometric curve simulation & 50% threshold |

## Using LLM Coding Tools on Assignments
You are welcome to use LLM assistants (ChatGPT, Claude, Gemini, GitHub Copilot) to **explain error messages**, **remind you of ggplot2 syntax**, or **review your code**—see [`llm-coding-guide/`](../../llm-coding-guide/README.md). However:
- **You are responsible for every line you submit.** Never paste code you cannot explain in plain English.
- **Check every statistical default.** LLMs frequently get `paired = TRUE`, `var.equal = FALSE`, `na.rm = TRUE`, and factor levels wrong!
- **Add a brief comment** noting where an AI tool helped you debug or refine syntax.

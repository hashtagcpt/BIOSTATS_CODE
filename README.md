# BIOSTATS_CODE

Unified R code, vision-science datasets, assignments, and AI-assisted coding guides for the **Biostatistics & Experimental Design I & II** graduate sequence at the **New England College of Optometry (NECO)** (Dr. Christopher Taylor).

This repository brings together reorganized, modernized, and fully verified versions of [`hashtagcpt/biostats-1`](https://github.com/hashtagcpt/biostats-1) and [`hashtagcpt/biostats-2`](https://github.com/hashtagcpt/biostats-2) in **one easy-to-navigate place**, while keeping **Biostats I** and **Biostats II** clearly separated—plus a dedicated beginner guide on **Using LLM Coding Tools in R**.

---

## Start Here: Choose Your Course or Guide

| Section | Who It's For | What's Inside | Go To |
|---|---|---|---|
| **Biostatistics I** (`biostats-1/`) | Fall semester (GRS97003) — Concepts, experimental design & R foundations | 15 syllabus-aligned scripts (Weeks 1–8 + Optional Libraries) & 11 simulated optometry CSV datasets | **[Open Biostats I Guide](biostats-1/README.md)** |
| **Biostatistics II** (`biostats-2/`) | Spring semester — Applied R programming, modeling, psychophysics & assignments | 10 lecture scripts, real vision-science lab datasets (CSV/XLSX/MAT) & 6 assignment starter templates | **[Open Biostats II Guide](biostats-2/README.md)** |
| **LLM Coding Tools** (`llm-coding-guide/`) | Students with little to no coding experience (both courses!) | 5-step R + AI workflow, copy-paste prompt templates, privacy rules & a lab on catching 5 silent AI statistical bugs | **[Open LLM Coding Guide](llm-coding-guide/README.md)** |

---

## Repository Layout

```text
BIOSTATS_CODE/
├── BIOSTATS_CODE.Rproj             # ALWAYS open this file in RStudio first!
├── README.md                       # Unified course hub (you are here)
├── llm-coding-guide/               # Using LLM coding tools safely with R
│   ├── README.md                   # Beginner guide, 5-step workflow & 6-point sanity checklist
│   ├── prompt_templates.md         # 8 copy-paste R + Biostatistics prompt recipes (Markdown)
│   ├── prompt_templates.txt        # Plain-text version of all 8 prompt templates (easy cut/paste)
│   └── scripts/                    # 2 interactive LLM workflow & bug-catching R labs
├── biostats-1/                     # COURSE 1: Foundations, Design & Introductory R
│   ├── README.md                   # Full Biostats I syllabus map & dataset dictionary
│   ├── data/                       # 11 simulated optometry/vision-science CSVs + generator
│   └── scripts/                    # 15 numbered teaching scripts (Weeks 1–8 + Optional)
└── biostats-2/                     # COURSE 2: Applied R, Psychophysics, Bayes & Assignments
    ├── README.md                   # Full Biostats II lecture map & dataset dictionary
    ├── data/                       # Lab CSV, Excel (.xlsx) & MATLAB (.mat) datasets + spectra/
    ├── scripts/                    # 10 numbered applied R lecture scripts
    └── assignments/                # Clean starter templates for Homeworks 1–2 & Assignments 1–4
```

---

## First-Time Setup (5 Minutes)

### 1. Install R and RStudio
- Download and install **R (>= 4.1)** from [CRAN](https://cran.r-project.org/) (needed for the native pipe `|>` and `\(x)` syntax).
- Download and install **RStudio Desktop** from [Posit](https://posit.co/download/rstudio-desktop/).

### 2. Download This Repository & Open `BIOSTATS_CODE.Rproj`
- Clone the repo with Git (or click **Code -> Download ZIP** and unzip to a permanent folder—not `Downloads`).
- **Double-click `BIOSTATS_CODE.Rproj`** to open RStudio. Opening the `.Rproj` file sets your working directory to the repository root automatically so every data path (`biostats-1/data/...` and `biostats-2/data/...`) works on macOS and Windows with zero `setwd()` edits.

### 3. Install R Packages (Run Once)

```r
# Core packages (Biostats I Weeks 1–8 + LLM Coding Guide)
install.packages(c("tidyverse", "broom", "car", "psych", "effsize", "lsr", "pwr"))

# Additional packages (Biostats I Optional Modules + Biostats II)
install.packages(c(
  "boot", "BayesFactor", "ez", "lme4", "lmerTest",
  "readxl", "R.matlab", "patchwork", "knitr", "kableExtra",
  "lm.beta", "psyphy", "modelfree"
))
```

### 4. Run Code Step by Step
Open any script and run one line or section at a time using **`Ctrl + Enter`** (Windows/Linux) or **`Cmd + Enter`** (macOS). Read the comments as you go—and if an R command or error message feels confusing, check [`llm-coding-guide/README.md`](llm-coding-guide/README.md)!

---

## Complete Script Index Across the Repository

### Course 1: Biostatistics & Experimental Design I (`biostats-1/scripts/`)
*Full syllabus alignment, slide numbers, and dataset dictionary in [`biostats-1/README.md`](biostats-1/README.md).*

- **`01_week1_r_basics_and_import.R`** — R basics, contrast formulas, NOIR scales, CSV import, `NA` checks, `dplyr`, wide-to-long OD/OS tidying
- **`02_week1_descriptive_stats_and_means.R`** — Mean/median/IQR, Arithmetic/Geometric/Harmonic means, why visual acuity uses logMAR, $n-1$ variance simulation, SD vs. SEM
- **`03_week1_eda_and_visualization.R`** — Deviations plots, Tukey boxplot anatomy, `#barbarplots` vs. raw points, scatterplots, *The Table 1 Fail* 1D strip graphic
- **`04_week2_normal_t_and_confidence_intervals.R`** — Normal & Student's *t* functions, CLT, hand-built *z*/*t* CIs, MoE sample size, 100-study CI coverage simulation
- **`05_week2_t_tests_independent_and_paired.R`** — Welch vs. Student independent *t*-tests, paired IOP change, fellow-eye pseudoreplication, statistical vs. clinical significance
- **`06_week3_sampling_normality_and_outliers.R`** — Repeated sampling ($n=10$ vs. $40$), Normal Q–Q plot key, Shapiro–Wilk large-sample paradox, Dice Lab, outlier sensitivity, 5-year myopia simulation
- **`07_week3_measurement_agreement_bland_altman_icc.R`** — Bias vs. noise target analogy, Bland–Altman Limits of Agreement & CIs, `psych::ICC()` consistency vs. absolute agreement
- **`08_week5_correlation_and_regression.R`** — Pearson/Spearman, outlier distortion, simple & multiple `lm()`, variance partitioning, residuals, AIC, Collinearity Tax (VIF), 1,000-study *r* simulation
- **`09_week6_study_design_randomization_and_bias.R`** — Allocation schemes (simple, permuted/variable blocks, stratified blocks), Causal DAGs (confounder, mediator, collider), prevalence/incidence & direct age standardization
- **`10_week7_anova_and_multiple_comparisons.R`** — FWER inflation, worked One-Way ANOVA by hand, `aov()`/`lm()` unification, Welch ANOVA, Two-Way interaction plot, planned contrasts, `TukeyHSD()`, `p.adjust()` (Bonferroni, Holm, BH FDR)
- **`11_week8_effect_size_and_power_analysis.R`** — Cohen's *d*, Hedges' *g*, $\eta^2$, $\omega^2$, Cohen's *f*, `power.t.test()` & `pwr` (+ attrition & NECO vs. BU check), noise-vs-*N* power curves, dichotomization power loss, post-hoc power circularity
- **`12_optional_categorical_screening_and_odds_ratios.R`** — ARR/RR/NNT, exact vs. Wald binomial CI, Chi-square GoF & Independence, `fisher.test()`, PPV vs. prevalence curve, OR vs. RR & log-odds CIs
- **`13_optional_logistic_regression_and_roc.R`** — Binomial `glm()`, clinical Odds Ratios, patient-level train/test validation, ROC curve & AUC from scratch, calibration plot
- **`14_optional_bootstrap_nonparametric_and_bayes.R`** — `boot()` (mean, median, regression, patient-cluster bootstrap), Mann–Whitney U, Wilcoxon signed-rank, Kruskal–Wallis, Card Bayes updating (`runCardBayes()`), Beta-Binomial & `ttestBF()`
- **`15_optional_ancova_repeated_measures_and_ss_types.R`** — Baseline-adjusted ANCOVA, mixed-design `ezANOVA()` with Mauchly's sphericity & Greenhouse–Geisser correction, `lmer()` for repeated measures & fellow eyes, unbalanced Type I/II/III Sums of Squares

### Course 2: Biostatistics & Experimental Design II (`biostats-2/scripts/` & `biostats-2/assignments/`)
*Full lecture guide, assignment submission rules, and lab dataset dictionary in [`biostats-2/README.md`](biostats-2/README.md).*

- **`01_lecture1_r_programming_and_data_io.R`** — Calculator, indexing, CSV/Excel/MATLAB import, `if/else`, `for`/`while`, functions, Lucky 13
- **`02_lecture2_functions_and_spectral_data.R`** — Reusable Excel loader function for LEDmotive spectral power distributions (`purrr::map2_dfr`) & avian cone sensitivity plots
- **`03_lecture3_ggplot_reshaping_and_patchwork.R`** — Log10 cone thresholds, `pivot_longer()`, within-subject SE (Morey 2008), poster-ready grayscale bar charts & `patchwork` layouts
- **`04_lecture4_ttests_correlations_and_tables.R`** — Cone-ratio *t*-tests, `p.adjust()`, Pearson vs. Spearman `cor.test()`, trimmed & winsorized means, CV, `knitr::kable()` tables
- **`05_lecture5_multiple_regression_and_selection.R`** — Simple & multiple `lm()`, standardized betas (`lm.beta`), nested `anova()`, all-subsets color-vision RE regression & VIF
- **`06_lecture6_anova_tukey_and_bootstrap.R`** — Levene's test, One-Way & Repeated-Measures ANOVA, `TukeyHSD()`, bootstrapping cards, CVI medians & regression slopes
- **`07_lecture7_effect_size_and_power_curves.R`** — `cohen.d()` + bootstrap CI, Two-Way ANOVA `etaSquared()`, pre-planned *t*-test & multi-power ANOVA sample-size curves
- **`08_lecture8_psychometric_functions.R`** — MATLAB 2AFC psychophysics import, `glm(..., binomial(mafc.logit(2)))`, `modelfree::threshold_slope()`, bootstrap threshold CI & `datasim()`
- **`09_lecture9_bayes_factors_in_r.R`** — `correlationBF()`, `posterior()`, directional `nullInterval`, `anovaBF()`, `ttestBF()`, and `regressionBF()`
- **`10_special_mixed_models_and_simulations.R`** — Factorial CSF simulation, naive `lm()` vs. `lme4::lmer()`, fixed binomial psychometric curve, Sleeping Beauty Monte Carlo
- **`assignments/`** — Clean starter templates for `homework_01`–`02` and `assignment_01`–`04` (see [`biostats-2/assignments/README.md`](biostats-2/assignments/README.md))

### Using LLM Coding Tools (`llm-coding-guide/`)
*Full beginner guide and copy-paste prompt library in [`llm-coding-guide/README.md`](llm-coding-guide/README.md).*

- **`01_llm_workflow_wide_to_long.R`** — Why clean tidyverse choices (`read_csv`, `glimpse`, `pivot_longer`) keep LLMs out of column-mangling rabbit holes
- **`02_catching_ai_stats_bugs_lab.R`** — Hands-on lab demonstrating **5 silent AI statistical bugs** (replacing `NA` with `0`, reversed sign/`var.equal=TRUE`, forgetting `paired=TRUE`, pooling fellow eyes, and treating longitudinal `year` as between-subjects) and how to catch and fix each one

---

## Data & Provenance Notes
- **Simulated vs. Lab Data:** All CSV files in `biostats-1/data/` are simulated teaching datasets (reproducible via `source("biostats-1/data/generate_teaching_datasets.R")`). Datasets in `biostats-2/data/` are curated teaching datasets from `hashtagcpt/biostats-2` (private student submissions from previous years have been excluded).
- **Copyright:** Course materials are intended for educational use at the New England College of Optometry (NECO).

> **Navigation:** [Back to BIOSTATS_CODE Hub](../README.md) | [Biostats I](../biostats-1/README.md) | [Using LLM Coding Tools](../llm-coding-guide/README.md)

# Biostatistics & Experimental Design II (`biostats-2/`)

Applied R programming, vision-science data workflows, statistical modeling, psychophysics, Bayes Factors, and course assignments for **Biostatistics and Experimental Design II** at the **New England College of Optometry (NECO)**.

This folder is a reorganized, bug-fixed, and modernized version of [`hashtagcpt/biostats-2`](https://github.com/hashtagcpt/biostats-2). All legacy hardcoded file paths, broken web URLs, and deprecated package calls have been replaced with clean, reproducible relative paths from the root [`BIOSTATS_CODE.Rproj`](../BIOSTATS_CODE.Rproj).

---

## Folder Layout

```text
biostats-2/
├── README.md                                          # This guide
├── data/                                              # Vision-science lab CSV, Excel & MATLAB datasets
│   ├── Example-Data-1.csv / .xlsx                     # Multi-format import practice (OD/OS)
│   ├── CPT_1_16_blurLevelDiscrim.mat                  # MATLAB blur discrimination file
│   ├── full_data.csv                                  # Human cone-isolating contrast thresholds & RE
│   ├── rgb_monitor.csv                                # Chick eye-growth measurements under RGB vs. White light
│   ├── rbg_noise_ir_data.csv                          # Chick pre/post refractive error (RGB vs. White)
│   ├── Monitor_Birds.csv                              # Chick ocular outcomes across Control / Flicker / Noise
│   ├── cvi.csv                                        # Cortical Visual Impairment (CVI) measurements
│   ├── album_sales.csv                                # Regression & bootstrap teaching dataset
│   ├── design_matrix.csv                              # Factorial design matrix example
│   ├── ledmotive_max_outputs.csv                      # 7-channel LEDmotive max output spectra
│   ├── l_m_s_u_dbl.csv                                # Avian (chick) L, M, S, U, D cone sensitivities
│   ├── ONOFF01-dog-OFF-1-29-Mar-2019_v7.mat           # 2AFC psychophysics contrast detection trials
│   └── spectra/                                       # 8 LEDmotive Excel spectral power distribution reports
├── scripts/                                           # 10 cleanly separated, verified lecture scripts
│   ├── 01_lecture1_r_programming_and_data_io.R
│   ├── 02_lecture2_functions_and_spectral_data.R
│   ├── 03_lecture3_ggplot_reshaping_and_patchwork.R
│   ├── 04_lecture4_ttests_correlations_and_tables.R
│   ├── 05_lecture5_multiple_regression_and_selection.R
│   ├── 06_lecture6_anova_tukey_and_bootstrap.R
│   ├── 07_lecture7_effect_size_and_power_curves.R
│   ├── 08_lecture8_psychometric_functions.R
│   ├── 09_lecture9_bayes_factors_in_r.R
│   └── 10_special_mixed_models_and_simulations.R
└── assignments/                                       # Clean starter templates for all homeworks & assignments
    ├── README.md
    ├── homework_01_r_basics.R
    ├── homework_02_loops_and_plotting.R
    ├── assignment_01_data_and_functions.R
    ├── assignment_02_plots_tables_and_tests.R
    ├── assignment_03_bootstrap_and_anova.R
    └── assignment_04_bayes_power_and_psychometrics.R
```

---

## Required R Packages (Biostats II)

Run once in the RStudio Console (assuming you already installed Biostats I core packages):

```r
install.packages(c(
  "tidyverse", "readxl", "R.matlab", "patchwork", "broom",
  "psych", "knitr", "kableExtra", "car", "lm.beta",
  "boot", "effsize", "lsr", "pwr",
  "psyphy", "modelfree", "BayesFactor", "lme4", "lmerTest"
))
```

---

## Lecture Script Directory

| # | Script File | Core Topics & Skills | Datasets Used | Primary R Tools |
|---|---|---|---|---|
| 01 | `01_lecture1_r_programming_and_data_io.R` | Calculator, vectors, indexing, CSV/Excel/MATLAB import, `if/else`, `for`/`while`, functions, Lucky 13 | `Example-Data-1.csv/.xlsx`, `CPT_1_16_blurLevelDiscrim.mat` | `read_csv()`, `read_xlsx()`, `readMat()`, `function()` |
| 02 | `02_lecture2_functions_and_spectral_data.R` | Writing reusable loaders for instrument Excel workbooks, batch import, spectral plots & legend ordering | `spectra/*.xlsx`, `ledmotive_max_outputs.csv`, `l_m_s_u_dbl.csv` | `purrr::map2_dfr()`, `pivot_longer()`, `patchwork` |
| 03 | `03_lecture3_ggplot_reshaping_and_patchwork.R` | Log10 psychophysics transform, wide-to-long reshaping, within-subject SE (Morey 2008), grayscale poster bars, `patchwork` | `full_data.csv`, `rbg_noise_ir_data.csv` | `pivot_longer()`, `ggplot2`, `patchwork`, `ggsave()` |
| 04 | `04_lecture4_ttests_correlations_and_tables.R` | Cone-ratio *t*-tests, `p.adjust()`, Pearson vs. Spearman `cor.test()`, trimmed/winsorized means, CV, `kable()` tables | `full_data.csv` | `t.test()`, `p.adjust()`, `cor.test()`, `psych::winsor.mean()`, `knitr::kable()` |
| 05 | `05_lecture5_multiple_regression_and_selection.R` | Simple & multiple `lm()`, `confint()`, standardized betas (`lm.beta`), nested `anova()`, subset scoring & VIF | `album_sales.csv`, `full_data.csv` | `lm()`, `lm.beta()`, `confint()`, `anova()`, `car::vif()` |
| 06 | `06_lecture6_anova_tukey_and_bootstrap.R` | Levene's test, One-Way & Repeated-Measures ANOVA, `TukeyHSD()`, bootstrapping means, CVI medians & regression slopes | `full_data.csv`, `cvi.csv`, `album_sales.csv` | `car::leveneTest()`, `aov()`, `TukeyHSD()`, `boot::boot()`, `boot.ci()` |
| 07 | `07_lecture7_effect_size_and_power_curves.R` | Cohen's *d* + bootstrap CI, Two-Way ANOVA $\eta^2$, pre-planned *t*-test & multi-power ANOVA sample-size curves | `MASS::genotype`, `Monitor_Birds.csv` | `effsize::cohen.d()`, `lsr::etaSquared()`, `pwr.t.test()`, `pwr.anova.test()` |
| 08 | `08_lecture8_psychometric_functions.R` | MATLAB 2AFC psychophysics import, filename parsing, 2AFC binomial GLM (`mafc.logit(2)`), 75% threshold & bootstrap CI, `datasim()` | `ONOFF01-dog-OFF-1-29-Mar-2019_v7.mat` | `readMat()`, `glm()`, `psyphy::mafc.logit()`, `modelfree::threshold_slope()` |
| 09 | `09_lecture9_bayes_factors_in_r.R` | Bayes Factors ($BF_{10}$), posterior sampling, directional `nullInterval`, Bayesian ANOVA, *t*-tests & all-subsets `regressionBF()` | `full_data.csv`, `Monitor_Birds.csv` | `correlationBF()`, `posterior()`, `anovaBF()`, `ttestBF()`, `regressionBF()` |
| 10 | `10_special_mixed_models_and_simulations.R` | Factorial CSF simulation, naive `lm()` vs. Linear Mixed-Effects `lmer()`, fixed logistic psychometric fit, Sleeping Beauty Monte Carlo | Simulated | `expand_grid()`, `lme4::lmer()`, `lmerTest`, `glm()` |

---

## Assignments & Homeworks

See [`assignments/README.md`](assignments/README.md) for submission naming rules and clean starter `.R` templates for Homeworks 1–2 and Assignments 1–4.

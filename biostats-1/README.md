> **Navigation:** [Back to BIOSTATS_CODE Hub](../README.md) | [Biostats II](../biostats-2/README.md) | [Using LLM Coding Tools](../llm-coding-guide/README.md)

# Biostatistics & Experimental Design I (`biostats-1/`)

Companion R scripts and simulated optometry & vision science datasets for **Biostatistics and Experimental Design I (GRS97003)** at the **New England College of Optometry (NECO)**.

This repository is a reorganized and expanded successor to [`hashtagcpt/biostats-1`](https://github.com/hashtagcpt/biostats-1), harmonized directly with the Fall 2026 lecture slide library (`BioStats-1_2026_reformat.pptx`) and supplemental course notes (Arithmetic/Geometric/Harmonic Means, *The Table 1 Fail*, Kraemer & Blasey power notes, ANOVA, Effect Size, Chi-Square, and Non-Parametric notes).

> **Data Notice:** All `.csv` files in [`data/`](data/) are **simulated, illustrative teaching datasets** modeled on optometry and vision science scenarios. They are **not** real patient records and must not be interpreted as clinical evidence of treatment efficacy or diagnostic accuracy.

---

## Repository Structure

```text
BIOSTATS_CODE/
├── BIOSTATS_CODE.Rproj             # Open this file in RStudio first!
├── README.md                       # Course guide, usage instructions, script & data index
├── data/                           # Simulated optometry & vision science CSV datasets
│   ├── generate_teaching_datasets.R
│   ├── 01_student_vision_clinic.csv
│   ├── 02_iop_clinical_trial.csv
│   ├── 03_fellow_eyes_axial_length.csv
│   ├── 04_tonometer_agreement.csv
│   ├── 05_dice_normality_rolls.csv
│   ├── 06_refraction_biometry.csv
│   ├── 07_contact_lens_comfort.csv
│   ├── 08_visual_search_rt.csv
│   ├── 09_preceptor_grading_icc.csv
│   ├── 10_uv_cataract_screening.csv
│   └── 11_glaucoma_prediction.csv
└── scripts/                        # 15 syllabus-aligned, self-contained R teaching scripts
    ├── 01_week1_r_basics_and_import.R
    ├── 02_week1_descriptive_stats_and_means.R
    ├── 03_week1_eda_and_visualization.R
    ├── 04_week2_normal_t_and_confidence_intervals.R
    ├── 05_week2_t_tests_independent_and_paired.R
    ├── 06_week3_sampling_normality_and_outliers.R
    ├── 07_week3_measurement_agreement_bland_altman_icc.R
    ├── 08_week5_correlation_and_regression.R
    ├── 09_week6_study_design_randomization_and_bias.R
    ├── 10_week7_anova_and_multiple_comparisons.R
    ├── 11_week8_effect_size_and_power_analysis.R
    ├── 12_optional_categorical_screening_and_odds_ratios.R
    ├── 13_optional_logistic_regression_and_roc.R
    ├── 14_optional_bootstrap_nonparametric_and_bayes.R
    └── 15_optional_ancova_repeated_measures_and_ss_types.R
```

---

## Quick-Start & Usage Instructions

### 1. Install R and RStudio
- Install **R (>= 4.1)** from [CRAN](https://cran.r-project.org/) (R 4.1+ is required for the native pipe `|>` and shorthand functions `\(x)`).
- Install **RStudio Desktop** from [Posit](https://posit.co/download/rstudio-desktop/).

### 2. Get the Repository and Open the RStudio Project
- Clone the repository with Git (or click **Code -> Download ZIP** and unzip it to a permanent folder—not your Downloads folder).
- **Double-click `BIOSTATS_CODE.Rproj`** to open the project in RStudio. Opening the `.Rproj` file automatically sets your working directory to the repository root so every `read_csv("biostats-1/data/...")` command works without editing file paths.

### 3. Install Required R Packages (Run Once)
Copy and run the following command in the RStudio Console once at the start of the semester:

```r
# Core packages (Weeks 1–8)
install.packages(c("tidyverse", "broom", "car", "psych", "effsize", "lsr", "pwr"))

# Additional packages for Weeks 9–10 Optional Topic Libraries
install.packages(c("boot", "BayesFactor", "ez", "lme4", "lmerTest"))
```

### 4. How to Work Through a Script
1. Open the script for the current week from `biostats-1/scripts/` (with `BIOSTATS_CODE.Rproj` open at the repository root).
2. Run code **one line or section at a time** (`Ctrl + Enter` on Windows/Linux, `Cmd + Enter` on macOS) rather than running the whole file blindly, so you can read the console output and inspect each plot as it appears.
3. Read the inline comments—each section explains **what** the statistical concept means clinically and **how** the R code computes it.
4. Complete the **"Try It Yourself (Exercises)"** at the bottom of each script to build fluency.

---

## Script Directory & Course Alignment

### Quick Overview Table

| # | Script File | Syllabus Week / Module | Key Slides | Datasets Used | Primary R Tools |
|---|---|---|---|---|---|
| 01 | `01_week1_r_basics_and_import.R` | Week 1: Foundations, R & Data Exploration | 1–15, 29 | `01`, `03` | `read_csv()`, `dplyr`, `pivot_longer()`, `is.na()` |
| 02 | `02_week1_descriptive_stats_and_means.R` | Week 1: Descriptive Stats & Three Means | 16–28 + *Means* deck | `01`, `02` | `mean()`, `median()`, `var()`, `sd()`, AM/GM/HM |
| 03 | `03_week1_eda_and_visualization.R` | Week 1: EDA, Visualization & Table 1 | 30–42 + *Table 1 Fail* | `01`, `02` | `ggplot2`, boxplots, violin+jitter, 1D strip plots |
| 04 | `04_week2_normal_t_and_confidence_intervals.R` | Week 2: Normal, *t*, CLT & CIs | 43–90 | Simulated + `02` | `d/p/q/rnorm()`, `d/p/q/rt()`, `t.test()`, CI sims |
| 05 | `05_week2_t_tests_independent_and_paired.R` | Week 2: Independent & Paired *t*-Tests | 91–107, 202, 315 | `02`, `03` | `t.test()` (Welch, Student, paired), `broom::tidy()` |
| 06 | `06_week3_sampling_normality_and_outliers.R` | Week 3: Sampling, Normality & Outliers | 108–123 | `01`, `05` | `stat_qq()`, `shapiro.test()`, dice & myopia sims |
| 07 | `07_week3_measurement_agreement_bland_altman_icc.R` | Week 3 (+ Ch. 3): Agreement & Reliability | 124–136, 312–313 | `04`, `09` | Bland-Altman LoA & CIs, `psych::ICC()` |
| 08 | `08_week5_correlation_and_regression.R` | Week 5: Correlation & Linear Regression | 137–173, 444–448 | `06` | `cor.test()`, `lm()`, `AIC()`, `car::vif()`, *r* sim |
| 09 | `09_week6_study_design_randomization_and_bias.R` | Week 6: Evidence & Experimental Design | 174–237 | Simulated | `sample()`, `psych::block.random()`, DAG sims, age std |
| 10 | `10_week7_anova_and_multiple_comparisons.R` | Week 7: ANOVA & Multiple Comparisons | 238–296 | `07` | `aov()`, `lm()`, `oneway.test()`, `TukeyHSD()`, `p.adjust()` |
| 11 | `11_week8_effect_size_and_power_analysis.R` | Week 8: Effect Size & Power Analysis | 297–346, 449–454 | `02`, `07` | `cohen.d()`, `etaSquared()`, `power.t.test()`, `pwr` |
| 12 | `12_optional_categorical_screening_and_odds_ratios.R` | Weeks 9–10 Optional: Counts & Screening | 347–371 | `10` | `chisq.test()`, `fisher.test()`, `binom.test()`, PPV, OR/RR |
| 13 | `13_optional_logistic_regression_and_roc.R` | Weeks 9–10 Optional: Logistic Prediction | 372–384 | `11` | `glm(..., family=binomial)`, train/test, ROC & AUC |
| 14 | `14_optional_bootstrap_nonparametric_and_bayes.R` | Weeks 9–10 Optional: Resampling, Ranks & Bayes | 385–410 | `01`, `02`, `03`, `06` | `boot()`, `wilcox.test()`, `kruskal.test()`, `ttestBF()` |
| 15 | `15_optional_ancova_repeated_measures_and_ss_types.R` | Weeks 9–10 Optional: Model Refinements | 411–437 | `02`, `03`, `07`, `08` | ANCOVA, `ezANOVA()`, `lmer()`, `car::Anova()` Types I/II/III |

---

### Detailed Topics Covered in Each Script

#### Core Curriculum (Weeks 1–8)

1. **`scripts/01_week1_r_basics_and_import.R` — R Basics, Data Import & Tidy Clinical Data**
   - R session checks (`getwd()`, `R.version.string`), R as a calculator (Weber and Michelson luminance contrast), case sensitivity, and `package::function()` namespaces.
   - Vectors, data types, and **NOIR** measurement scales (Nominal, Ordinal, Interval, Ratio).
   - Importing `.csv` data (`read.csv()` and `readr::read_csv()`), inspecting objects (`str()`, `glimpse()`, `summary()`), and handling missing values (`NA` vs. `0` in clinical scales).
   - Data wrangling with `dplyr` (`filter()`, `select()`, `mutate()`, `group_by()`, `summarize()`, native pipe `|>`), `if-else`, and `for` loops.
   - Tidying wide fellow-eye tables (OD/OS) to long format with `tidyr::pivot_longer()` while keeping track of patient-level vs. eye-level sample units.

2. **`scripts/02_week1_descriptive_stats_and_means.R` — Descriptive Statistics, Three Means & SEM**
   - Arithmetic mean by hand (`sum(x) / length(x)`), zero-sum property of deviations, median, IQR, and outlier sensitivity.
   - **Arithmetic, Geometric, and Harmonic Means** ($AM \ge GM \ge HM$): what invariant each preserves (sum, product, sum of reciprocals), worked biology examples (deer mouse mass, population growth $\lambda$, bottleneck effective population size $N_e$), and **why visual acuity must be averaged on the logMAR scale** (geometric mean MAR vs. raw Snellen denominators).
   - Variance and SD: simulation proving why dividing sample variance by $n - 1$ is unbiased for $\sigma^2$ while dividing by $n$ underestimates it.
   - Standard Error of the Mean (`SD / sqrt(n)`): separating spread of individuals (SD) from precision of the sample mean (SEM) and visualizing the $4\times n$ "economy of effort" rule.

3. **`scripts/03_week1_eda_and_visualization.R` — Exploratory Data Analysis, Visualization & The Table 1 Fail**
   - Plotting deviations around the mean and their histogram.
   - Anatomy of a Tukey boxplot: Q1, median, Q3, IQR, $1.5 \times \text{IQR}$ fences vs. observed whisker endpoints, and flagging points for inspection.
   - **`#barbarplots`**: demonstrating three very different clinical distributions (symmetric, bimodal, skewed + outlier) that produce identical bar charts and error bars, contrasted with transparent violin + boxplot + `geom_jitter()` displays.
   - Bivariate clinical scatterplots (Central Corneal Thickness vs. IOP).
   - Fixing **"The Table 1 Fail"**: descriptive baseline tables without misapplied balance *p*-values, paired with a 1D strip/scatterplot (Rousselet et al., 2016).

4. **`scripts/04_week2_normal_t_and_confidence_intervals.R` — Normal & *t* Distributions, CLT & Confidence Intervals**
   - Normal distribution functions (`dnorm()`, `pnorm()`, `qnorm()`, `rnorm()`), the 68–95–99.7% rule, and Z-scores (IQ and healthy adult IOP examples).
   - Student's *t*-distribution (`dt()`, `pt()`, `qt()`) and convergence to the Standard Normal as degrees of freedom increase.
   - Central Limit Theorem and simulating the sampling distribution of the mean IOP.
   - Computing 95% confidence intervals by hand for known $\sigma$ (*z*-interval) vs. unknown $\sigma$ (*t*-interval), plus Margin of Error sample-size planning $n = (Z \cdot \sigma / \text{MoE})^2$.
   - The **100-study confidence interval simulation** illustrating frequentist coverage and why plugging sample $s$ into a *z*-interval under-covers at small $n$.
   - The equivalence between 95% confidence intervals and two-sided $\alpha = 0.05$ hypothesis tests.

5. **`scripts/05_week2_t_tests_independent_and_paired.R` — Independent & Paired *t*-Tests, Welch's Default & Fellow Eyes**
   - Comparing 4-week IOP change between two treatments (`Drop_A` vs. `Drop_B`): Welch's *t*-test (`var.equal = FALSE`, R's recommended default) vs. Student's pooled *t*-test, including manual Welch–Satterthwaite degrees of freedom verification and structured clinical results reporting.
   - Paired *t*-tests on within-patient IOP change (`delta = followup - baseline`), paired trajectory plots, and demonstrating why preserving pairing reduces standard error.
   - Two-sided vs. pre-specified one-sided hypotheses (and why post-hoc tail switching is invalid).
   - **Correlated fellow eyes (OD/OS)**: demonstrating how naively pooling both eyes from 40 patients as 80 independent observations causes pseudoreplication, compared with patient-mean and one-eye analyses.
   - Statistical significance vs. clinical relevance (e.g., a 15-micron axial length difference at $N = 20{,}000$).

6. **`scripts/06_week3_sampling_normality_and_outliers.R` — Sampling Intuition, Normality Diagnostics, Outliers & Simulation**
   - Repeated sampling simulation comparing $n = 10$ vs. $n = 40$ studies from an IOP population.
   - Visual key for reading Normal Q–Q plots (`stat_qq()` / `stat_qq_line()`): normal, right-skewed, heavy-tailed, and single-outlier signatures.
   - Formal normality tests (`shapiro.test()` and `ks.test()` cautions) plus a simulation of the **large-sample paradox of Shapiro–Wilk**.
   - **Classroom Dice Lab** (`data/05_dice_normality_rolls.csv`): discrete uniform single dice vs. bell-shaped sum of 6 dice (CLT in action).
   - **"An Outlier Is a Question, Not a Delete Button"**: transparent primary vs. sensitivity analysis rather than silently deleting unusual clinical values.
   - Clinical simulation of 5-year myopia progression and high-myopia prevalence under simulated treatment efficacy.

7. **`scripts/07_week3_measurement_agreement_bland_altman_icc.R` — Measurement Agreement (Bland-Altman) & Reliability (ICC)**
   - Target analogy simulation separating systematic bias (accuracy/trueness) from random measurement noise (precision/reliability).
   - Comparing Goldmann Applanation vs. Portable Rebound tonometers (`data/04_tonometer_agreement.csv`): showing why a very high Pearson correlation ($r > 0.94$) does **not** prove clinical interchangeability.
   - Complete **Bland–Altman analysis**: mean bias, 95% Limits of Agreement ($\bar{d} \pm 1.96 s_d$), 95% CIs for bias and LoAs, clinical tolerance band ($\pm 2$ mmHg), and testing for proportional bias across the IOP range.
   - **Intraclass Correlation Coefficient (ICC)** via `psych::ICC()` on three preceptors grading 25 OD candidates (`data/09_preceptor_grading_icc.csv`), contrasting rank-order **Consistency** (`ICC3`) vs. strict **Absolute Agreement** (`ICC2`).

8. **`scripts/08_week5_correlation_and_regression.R` — Correlation, Linear Regression, AIC & Collinearity**
   - Pearson vs. Spearman correlation (`cor.test()`) on ocular biometry (`data/06_refraction_biometry.csv`) and showing how a single high-leverage outlier distorts *r* and the OLS slope.
   - Simple linear regression (`lm(spherical_eq_d ~ axial_length_mm)`): interpreting slope in clinical units (Diopters per mm), verifying $b_1 = r(s_y / s_x)$, partitioning variance by hand ($SS_{\text{Total}} = SS_{\text{Model}} + SS_{\text{Residual}}$, $R^2$, $F$), and computing confidence vs. prediction intervals.
   - Residual diagnostic checks (Residuals vs. Fitted, Normal Q–Q of standardized residuals, Cook's distance).
   - Multiple linear regression, Adjusted $R^2$, **AIC model comparison** (penalizing unneeded noise predictors), and the **Collinearity Tax** (Variance Inflation Factors via `car::vif()` when including both axial length and vitreous chamber depth).
   - Simulation of 1,000 studies (*"Why Most Published Research Findings Are False"*): sampling variability of *r* and how filtering for $p < 0.05$ exaggerates published effect sizes.

9. **`scripts/09_week6_study_design_randomization_and_bias.R` — Study Design, Randomization, Causal DAGs & Epidemiology**
   - Comparing five treatment allocation schemes: sequential split (confounded), strict alternation (predictable), simple coin flip (`sample()`), permuted blocks (`psych::block.random()`), variable-size blocks (for allocation concealment), and **stratified block randomization** across age bands.
   - Simulating the three fundamental **Causal Diagrams (DAGs)**:
     - **Confounder** ($Z \to X, Z \to Y$): why unadjusted associations are biased and adjusting for $Z$ recovers the null.
     - **Mediator** ($X \to M \to Y$): why adjusting for post-treatment IOP masks the total treatment effect on visual field preservation.
     - **Collider** ($X \to C \leftarrow Y$): demonstrating Berkson's paradox in specialty optometry clinic referrals.
   - Public health & epidemiology denominators: Point Prevalence, Incidence Risk, Incidence Rate (person-years), and **Direct Age Standardization** of glaucoma prevalence across two clinics with different age structures.

10. **`scripts/10_week7_anova_and_multiple_comparisons.R` — One-Way & Two-Way ANOVA, Contrasts & Multiplicity**
    - Family-Wise Error Rate (FWER) inflation formula and simulation showing why running many unadjusted pairwise *t*-tests inflates false alarms.
    - Exact hand calculation of the worked 4-group One-Way ANOVA from the slides ($SS_B = 500$, $SS_W = 918$, $F$, `pf()`, and $R^2 = \eta^2$).
    - One-Way ANOVA on contact lens visual clarity (`data/07_contact_lens_comfort.csv`), proving `aov()` and `lm()` fit the exact same linear model, alongside Levene's test (`car::leveneTest()`) and Welch's one-way ANOVA (`oneway.test()`).
    - Two-Way Factorial ANOVA (`discomfort_score ~ lens_type * age_group`) with a crossover interaction plot.
    - Post-hoc and planned follow-up: `TukeyHSD()`, planned orthogonal contrasts, and `p.adjust()` comparing **Bonferroni**, **Holm** (FWER), and the **Benjamini–Hochberg** step-up procedure (FDR).

11. **`scripts/11_week8_effect_size_and_power_analysis.R` — Effect Sizes & A Priori Power Analysis**
    - Unstandardized (clinical units) vs. standardized effect sizes: Cohen's *d* (manual + `effsize::cohen.d()`), Hedges' *g*, ANOVA $\eta^2$, partial $\eta^2$ (`lsr::etaSquared()`), less-biased $\omega^2$, and Cohen's *f*.
    - A priori power and sample size planning with `power.t.test()` and the `pwr` package: two-sample *t*-tests (including the 2 mmHg IOP trial example + 15% attrition inflation), One-Way ANOVA (`pwr.anova.test()`), correlation (`pwr.r.test()`), and the NECO vs. BU two-proportion feasibility check (`pwr.2p.test()`).
    - Power curves showing how measurement noise (*"The Coffee Thought Experiment"*) dramatically inflates required sample size.
    - Homogeneity of variance F-test (`var.test()`) and a simulation showing how **dichotomizing a continuous outcome** destroys statistical power.
    - Graphical proof that **post-hoc ("observed") power** is merely a deterministic 1-to-1 transform of the *p*-value.

#### Optional Topic Libraries (Weeks 9–10 Special Presentations & Final Paper Extensions)

12. **`scripts/12_optional_categorical_screening_and_odds_ratios.R` — Counts, Risks, Chi-Square & Screening**
    - Communicating clinical risk with explicit denominators: Absolute Risk Reduction (ARR), Risk Ratio (RR), and Number Needed to Treat (NNT).
    - Proportion confidence intervals: Wald normal approximation vs. exact `binom.test()`.
    - Pearson's Chi-Square Goodness-of-Fit (manual $Q$ and `chisq.test()`) and Test of Independence on UV exposure vs. cataracts (`data/10_uv_cataract_screening.csv`) plus the MCAT/OAT $r \times c$ table, expected counts, and standardized residuals.
    - Sparse tables: Fisher's Exact Test (`fisher.test()`) and Monte Carlo chi-square (`simulate.p.value = TRUE`).
    - Diagnostic screening arithmetic: Sensitivity, Specificity, and plotting how **Positive Predictive Value (PPV)** varies dramatically with disease prevalence.
    - Comparing **Odds Ratios vs. Risk Ratios** across rare vs. common outcomes, plus manual log-odds 95%/99% CIs and `fisher.test()` conditional OR.

13. **`scripts/13_optional_logistic_regression_and_roc.R` — Logistic Regression, Validation, ROC & AUC**
    - Why linear OLS fails for binary (0/1) outcomes compared to the bounded logistic sigmoid (`glm(..., family = binomial)`).
    - Multivariable logistic regression predicting glaucoma diagnosis (`data/11_glaucoma_prediction.csv`) from IOP, RNFL thickness, cup-to-disc ratio, age, and CCT, converting log-odds into clinical Odds Ratios and 95% CIs.
    - Out-of-sample patient-level train/test validation contrasting in-sample optimism with held-out performance.
    - Sweeping probability thresholds to build an **ROC curve** and compute **AUC** from scratch, plus a risk-quintile **calibration plot**.

14. **`scripts/14_optional_bootstrap_nonparametric_and_bayes.R` — Bootstrap, Rank Tests & Bayesian Inference**
    - Non-parametric **Bootstrap** resampling with replacement by hand and with `boot::boot()` ($R = 2{,}000$, percentile and BCa 95% CIs) for skewed tear-film break-up time, linear regression slopes, and a **patient-cluster bootstrap** for correlated fellow eyes.
    - **Non-parametric rank tests**: manual `rank()` with ties, Mann–Whitney U / Wilcoxon rank-sum (`wilcox.test()`), paired Wilcoxon signed-rank, and Kruskal–Wallis (`kruskal.test()`) with Holm-adjusted pairwise follow-up.
    - **Bayesian updating**: sequential Red/Black card-deck updating & Bayes Factors (both scripted trace and interactive `runCardBayes()` console demo), Beta-Binomial Prior $\to$ Likelihood $\to$ Posterior plot, and Bayesian two-sample *t*-test (`BayesFactor::ttestBF()`).

15. **`scripts/15_optional_ancova_repeated_measures_and_ss_types.R` — ANCOVA, Repeated Measures, Mixed Models & SS Types**
    - **ANCOVA** (`lm(iop_followup ~ treatment + iop_baseline)`): showing how baseline covariate adjustment reduces residual error, plus checking homogeneity of regression slopes (`treatment * iop_baseline`).
    - **Repeated-Measures & Mixed-Design ANOVA** (`ez::ezANOVA()`) on visual search reaction time across 4 optical defocus blur levels (`data/08_visual_search_rt.csv`), inspecting **Mauchly's Test of Sphericity** and **Greenhouse–Geisser** corrected *p*-values.
    - Modern **Linear Mixed-Effects Models** (`lme4::lmer()` + `lmerTest`) for both repeated-measures reaction time and correlated OD/OS fellow-eye axial length (`(1 | patient_id)`).
    - **Unbalanced Two-Way ANOVA**: demonstrating how Type I sequential sums of squares (`anova()`) change with predictor order, contrasted with Type II (`car::Anova(..., type = "II")`) and Type III (`car::Anova(..., type = "III")` with `contr.sum` sum-to-zero contrasts).

---

## Optometry & Vision Science Dataset Dictionary (`data/`)

All CSV datasets are generated reproducibly by [`data/generate_teaching_datasets.R`](data/generate_teaching_datasets.R) (fixed seed `2026`).

| Dataset File | Rows | Clinical / Vision Science Scenario | Key Variables | Used In Scripts |
|---|---:|---|---|---|
| `01_student_vision_clinic.csv` | 80 | Optometry & graduate vision science student screening (all NOIR scales + realistic `NA`s & extremes) | `program`, `year`, `age`, `eye_color`, `far_logmar`, `near_logmar`, `snellen_denom`, `contrast_sens`, `tbut_sec`, `efron_redness`, `dry_eye_symptom` | `01`, `02`, `03`, `06`, `14` |
| `02_iop_clinical_trial.csv` | 60 | 2-arm randomized IOP-lowering drop trial (`Drop_A` vs. `Drop_B`, 1 study eye per patient) | `patient_id`, `treatment`, `age`, `sex`, `cct_um`, `iop_baseline`, `iop_followup`, `iop_change` | `02`, `03`, `05`, `11`, `14`, `15` |
| `03_fellow_eyes_axial_length.csv` | 40 | Correlated fellow eyes (OD & OS) in OrthoK vs. Single-Vision wearers | `patient_id`, `lens_group`, `al_od_mm`, `al_os_mm`, `se_od_d`, `se_os_d` | `01`, `05`, `14`, `15` |
| `04_tonometer_agreement.csv` | 50 | Paired IOP readings comparing Goldmann Applanation vs. Portable Rebound tonometer (fixed + proportional bias) | `patient_id`, `goldmann_iop`, `rebound_iop` | `07` |
| `05_dice_normality_rolls.csv` | 60 | Classroom polyhedral dice-rolling lab (`d4` through `d20` and total) for CLT & normality testing | `roll_id`, `group`, `d4`, `d6`, `d8`, `d10`, `d12`, `d20`, `total` | `06` |
| `06_refraction_biometry.csv` | 120 | Adult ocular biometry, behavioral exposure & visual function (includes collinear `vitreous_chamber_mm`) | `age`, `screen_hours`, `outdoor_hours`, `axial_length_mm`, `vitreous_chamber_mm`, `corneal_power_d`, `spherical_eq_d`, `contrast_sens`, `logmar_va` | `08`, `14` |
| `07_contact_lens_comfort.csv` | 90 | 3x2 balanced factorial trial of Soft, Hybrid & RGP lenses across Young & Presbyopic wearers (includes interaction) | `patient_id`, `lens_type`, `age_group`, `baseline_dryness`, `discomfort_score`, `clarity_score` | `10`, `11`, `15` |
| `08_visual_search_rt.csv` | 128 | Mixed-design psychophysics (32 subjects x 4 defocus blur levels `0D–3D`, Emmetrope vs. Myope) with sphericity departure | `subject_id`, `refractive_group`, `blur_level`, `reaction_time_ms` | `15` |
| `09_preceptor_grading_icc.csv` | 25 | 3 clinical preceptors independently grading OD students on contact lens fitting (with systematic rater offset) | `candidate_id`, `preceptor_A`, `preceptor_B`, `preceptor_C` | `07` |
| `10_uv_cataract_screening.csv` | 200 | Community eye-health screening linking UV exposure, sunglasses use, cataract status, and clinic site | `patient_id`, `uv_exposure`, `sunglasses_use`, `cataract_status`, `clinic_site` | `12` |
| `11_glaucoma_prediction.csv` | 300 | Glaucoma classification dataset with patient-level `Train` (n=200) and `Test` (n=100) cohorts | `patient_id`, `cohort`, `age`, `iop_mmhg`, `rnfl_um`, `cup_disc_ratio`, `cct_um`, `glaucoma`, `diagnosis` | `13` |

---

## Instructor & Maintenance Notes

- **Provenance:** This repository preserves the full commit history of [`hashtagcpt/biostats-1`](https://github.com/hashtagcpt/biostats-1) as its base while reorganizing, updating, and expanding the scripts for the 2026 syllabus.
- **Regenerating Datasets:** Run `source("biostats-1/data/generate_teaching_datasets.R")` from the project root to deterministically rebuild all 11 CSV datasets.
- **Copyright:** Course materials are intended for educational use in GRS97003 at the New England College of Optometry.

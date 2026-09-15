# Manuscript Results Map

This crosswalk identifies the generated file behind each manuscript table,
figure, and principal numerical statement. All paths are relative to the
repository root.

## Tables

| Manuscript item | Authoritative generated source | Main content |
|---|---|---|
| Table 1, sample characteristics | `results/tables/demographics_full_and_cleaned.csv` | Full-frame and analysis-sample demographics |
| Table 2, instrument descriptives | `results/tables/clinical_instrument_descriptives_reliability.csv` | n, mean, SD, median, range, and Cronbach's alpha for eight measures |
| Table 3, model-standardised performance | `results/tables/mixed_model_stimulus_set_estimates.csv` | Accuracy and geometric mean RT by stimulus set |
| Table 3, pairwise tests | `results/tables/mixed_model_stimulus_set_contrasts.csv` | Covariance-aware stimulus-set differences and FDR p-values |
| Table 4, clinical accuracy correlations | `results/tables/clinical_correlations.csv` | Filter to Accuracy, Spearman, and FACES/AI-white/AI-diverse |

Table 4 presents 24 accuracy-Spearman tests: eight instruments by three reported
stimulus sets. Its percentile confidence intervals are unadjusted, while its
p-values are Benjamini-Hochberg adjusted together as one 24-test family.

## Figures

| Manuscript content | File |
|---|---|
| Emotion-recognition interface | `manuscript_figures/figure_01_task_interface.png` |
| Representative AI-generated stimuli | `manuscript_figures/figure_02_ai_examples.png` |
| Participant flow | `results/figures/figure_01_cohort_flow.png` |
| Model-standardised performance | `results/figures/figure_04_mixed_model_estimates.png` |
| Clinical associations | `results/figures/figure_05_clinical_correlation_forest.png` |
| Demographic moderation composite | `manuscript_figures/figure_05_demographic_moderation.png` |
| Gender panel source | `results/figures/figure_09_gender_moderation.png` |
| White-status panel source | `results/figures/figure_10_white_status_moderation.png` |

The current manuscript draft labels both participant flow and model-standardised
performance as Figure 3. These captions should be renumbered before submission;
the content-based filenames above avoid propagating that duplicate numbering.

## Principal result statements

| Result | Generated source |
|---|---|
| Source frame 1,277; primary accuracy n = 1,047; primary RT n = 1,046 | `results/tables/cohort_flow.csv` |
| Descriptive FACES accuracy 76.20%, AI-white 87.29%, AI-diverse 86.15% | `results/tables/condition_descriptive_statistics.csv` |
| Adjusted AI-white versus FACES accuracy +8.34 percentage points | `results/tables/mixed_model_stimulus_set_contrasts.csv` |
| Adjusted AI-diverse versus FACES accuracy +7.40 percentage points | `results/tables/mixed_model_stimulus_set_contrasts.csv` |
| Adjusted AI-white and AI-diverse RTs 0.37 and 0.35 seconds faster than FACES | `results/tables/mixed_model_stimulus_set_contrasts.csv` |
| No clear AI-white versus AI-diverse performance difference | `results/tables/mixed_model_stimulus_set_contrasts.csv` |
| Nine Table 4 accuracy-Spearman associations survive FDR | `results/tables/clinical_correlations.csv` |
| No paired clinical-correlation difference survives FDR | `results/tables/dependent_clinical_correlation_differences.csv` |
| Women outperform men in all three disjoint strata | `results/tables/gender_moderation_contrasts.csv` |
| No corrected gender-congruence effect | `results/tables/gender_moderation_contrasts.csv` |
| No corrected white-status group or congruence effect | `results/tables/white_status_moderation_contrasts.csv` |
| FACES/AI-diverse split-half reliability and agreement | `results/tables/reliability_split_half.csv` and `results/tables/faces_ai_diverse_agreement.csv` |
| Completion, ceiling, and RT-window robustness checks | `results/tables/sensitivity_stimulus_set_contrasts.csv` |

## Full output index

`results/table_and_figure_index.md` describes all main and supplementary files.
`results/tables/publication_tables.md` provides human-readable versions of the
principal tables. Model coefficients and convergence diagnostics remain in the
package even where the manuscript reports only standardised estimates.

# Code Reading Guide

The analysis is deliberately contained in two executable R scripts. Both use
numbered sections, explicit variable names, and CSV outputs so each step can be
inspected without a notebook or hidden state.

## Script 1: prepare data

`R/01_prepare_data.R` performs seven tasks:

1. Loads packages and resolves paths relative to the repository.
2. Reads the participant-wide CSV and checks its exact schema.
3. Recalculates all eight questionnaire totals from the released items and
   checks the stored totals; it also calculates Cronbach's alpha.
4. Converts the 80 repeated trial slots into a conventional trial-level table.
5. Creates inclusion flags, mutually exclusive trial strata, and the overlapping
   reported condition summaries.
6. Produces cohort, demographics, missingness, cleaning, balance, and instrument
   tables.
7. Runs structural checks and writes three analysis-ready CSVs to `derived/`.

The main handoff files are `derived/participants.csv`, `derived/trials.csv`, and
`derived/condition_scores.csv`.

## Script 2: analyse data

`R/02_run_analyses.R` has eleven numbered sections:

1. Fixed settings, packages, paths, and the random seed.
2. Input checks for the three files produced by Script 1.
3. Small reusable functions for plots, model summaries, bootstrap correlations,
   standardised estimates, and covariance-aware contrasts.
4. Participant-level descriptive statistics.
5. Completer/non-completer logistic regressions.
6. Primary accuracy and response-time mixed models and sensitivity models.
7. Clinical correlations, paired correlation differences, and adjusted
   incremental association models.
8. Participant gender and white-status moderation models.
9. Split-half reliability, FACES/AI agreement, and confusion matrices.
10. Publication figures.
11. Automated checks, human-readable reports, and provenance manifests.

The helper functions are kept in the same file immediately before their use.
They avoid repeated model-prediction code; they do not conceal additional model
specifications. The fitted equations are written independently in
`docs/model_equations.md`.

## Generated versus source files

Files in `data/`, `R/`, `docs/`, and `task/` are source materials. Files in
`derived/` and `results/` are generated. Deleting the generated files and running
the two commands in the README recreates them.

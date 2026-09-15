# Reproducibility Validation

## Clean released-data run

Both public scripts were run using only files inside this repository. Script 1
reconstructed 83,206 trial rows from 1,277 participant rows and passed all ten
data checks. Script 2 completed every primary, sensitivity, clinical, moderation,
reliability, and attrition analysis.

All eleven reported mixed models converged without singularity. The primary
accuracy model used 1,047 participants and 77,238 common-emotion trials. The
primary RT model used 1,046 participants and 62,167 correct trials within the
0.20-to-30-second window.

Detailed machine-readable checks are in:

- `results/diagnostics/data_validation_checks.csv`
- `results/diagnostics/analysis_sanity_checks.csv`
- `results/diagnostics/all_mixed_model_diagnostics.csv`

## Restricted-source reconciliation

The release-construction process checked all 79 released questionnaire items and
all 83,206 trials against the restricted analysis source. Recalculated complete-
item scores matched the private analysis scores for all eight retained measures.

Forty-four generated CSV tables shared names with the preceding restricted-source
analysis package. Every inferential and performance table with the same schema
matched numerically within floating-point tolerance. The largest observed numeric
difference was `1.78e-15`. Differences in preparation-only tables were expected:
the released versions omit unneeded fine-grained demographics, collection-system
metadata, and local source labels.

## Sampling check

The observed source and emotion frequencies were consistent with the supplied
uniform sampling implementation:

- AI versus FACES: chi-square = 0.592, df = 1, p = .442
- FACES emotions: chi-square = 8.396, df = 5, p = .136
- AI emotions: chi-square = 7.335, df = 6, p = .291

These are balance checks, not proofs that every upstream task-order mechanism was
implemented as intended.

# Deidentification and Blind-Review Safeguards

This package was constructed from restricted source data for blinded review.
Only variables required to reproduce the reported AI-face emotion-recognition
analyses were retained.

## Removed information

- Participant recruitment and collection-platform identifiers
- Original participant and response linkage keys
- Names, email addresses, contact fields, IP addresses, and geolocation
- Start, completion, upload, and file-system timestamps
- Free-text demographic and clinical responses
- Original task filenames and directory paths
- Data and measures unrelated to the analyses in this repository
- Author names, affiliations, acknowledgements, ethics-board identity, and local
  organization or infrastructure names

## Released information

- Synthetic sequential participant IDs with no released crosswalk
- Synthetic stimulus IDs with no original filenames
- Grouped demographic categories used in the manuscript
- Questionnaire items and complete-item totals for the eight analysed measures
- Emotion-recognition targets, responses, correctness, response times, and coded
  stimulus attributes
- Minimal task-availability and task-position variables needed for sample-flow
  reporting, attrition models, and mixed-model adjustment

## Residual disclosure considerations

This is a deidentified research dataset, not a claim of mathematically guaranteed
anonymity. It contains sensitive questionnaire responses and combinations of age
and grouped demographics that may be unusual. Access and repository visibility
must therefore follow the study's consent, ethics approval, data-management plan,
and applicable data-protection requirements. Where unrestricted public release is
not authorised, the same package can be shared through controlled or reviewer-only
access without changing the code.

The Git history used for blinded sharing must also contain only an anonymous
release commit. A repository that preserves earlier named commits is not blinded
even when the current files contain no identifying text.

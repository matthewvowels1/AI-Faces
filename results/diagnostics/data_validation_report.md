# Data Preparation and Validation

The released participant-wide file was read without any private source data.
The eight retained instruments were rescored from item responses and the 80
emotion-recognition slots were reshaped to trial level.

## Counts

- Participant rows: 1277
- Reconstructed trial rows: 83206
- Primary common-emotion accuracy trials: 77238
- Primary correct-RT trials: 62167

## Checks

- Expected participant count: PASS
- Released participant IDs unique: PASS
- Every trial participant exists in participant file: PASS
- Expected post-cleaning trial count: PASS
- Each included trial has one disjoint stratum: PASS
- No duplicate participant-trial row: PASS
- FACES stimuli are white-labelled: PASS
- FACES has no surprise target: PASS
- All eight retained clinical totals reproduce from released items: PASS
- RT inclusion implies a correct response: PASS

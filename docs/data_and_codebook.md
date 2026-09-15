# Data and Codebook Notes

## Main release file

`data/ai_faces_study.csv` is the only participant-level input required for the
analysis. It is intentionally wide: one row represents one participant, and
columns contain participant characteristics, questionnaire data, and repeated
emotion-recognition trials. This makes the released unit of observation obvious
and prevents accidental participant duplication when the file is first opened.

The exact definition of every column is in `data/data_dictionary.csv`.

## Participant fields

The first 14 columns contain the synthetic participant ID, grouped demographic
variables, the task's position in the wider battery, and data-availability or
task-completion indicators. Categories are the same categories used by the
reported analyses. Blank cells are missing values, not zeroes.

The participant ID has the form `participant_0001`. It is a release-only key.
There is no lookup table from this key to any collection-system identifier.

## Questionnaire fields

Eight complete-item totals are followed by their 79 numeric item responses:

| Prefix | Instrument | Items |
|---|---|---:|
| `cape15` | Community Assessment of Psychic Experiences, positive subscale | 15 |
| `asrm` | Altman Self-Rating Mania Scale | 5 |
| `isi` | Insomnia Severity Index | 7 |
| `ocir` | Obsessive-Compulsive Inventory-Revised | 18 |
| `minispin` | Mini-Social Phobia Inventory | 3 |
| `asrs` | Adult ADHD Self-Report Scale | 18 |
| `gad7` | Generalized Anxiety Disorder-7 | 7 |
| `hamd6` | Hamilton Depression Rating Scale, six-item form | 6 |

A total is present only when all required items are present. Script 1 recalculates
every total and stops if any released total differs from its item sum.

## Trial fields

Each of the 80 possible slots contributes ten columns:

| Suffix | Meaning |
|---|---|
| `_source` | FACES or AI source |
| `_trial_stratum` | Mutually exclusive FACES, AI-white, or AI-non-white stratum |
| `_stimulus_id` | Synthetic key into `stimulus_manifest.csv` |
| `_target_emotion` | Intended emotion |
| `_response_emotion` | Participant response |
| `_correct` | Binary response correctness |
| `_rt_sec` | Response time in seconds |
| `_face_age` | Coded stimulus age group |
| `_face_gender` | Coded stimulus gender |
| `_face_ethnicity` | Coded stimulus ethnicity label |

For example, all fields beginning `trial_027_` describe the 27th observed trial
for that participant. Participants who stopped early have blank later slots.
Script 1 pivots these columns into `derived/trials.csv`, one row per trial.

## Overlapping sets

`AI-white` is a subset of `AI-diverse`; `AI-diverse` means all AI trials. The wide
file stores each trial exactly once under a disjoint stratum. Participant-level
AI-diverse summaries and model-standardised AI-diverse estimates are constructed
afterward by pooling the relevant AI-white and AI-non-white observations.

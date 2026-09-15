# Methods and Analysis Description

## Design and participants

This observational study linked questionnaire, screening, and computerised-task
data at participant level. The released source frame contains 1,277 deidentified
records. Emotion recognition was one task in a wider battery; its observed task
position varied across participants and was included as a model covariate.

The participant flow was reported for the full frame, available intake data, any
emotion-recognition attempt, any valid trial, all 80 valid trials, and each main
analysis. The primary common-emotion accuracy sample contained 1,047 participants;
the primary correct-response-time sample contained 1,046.

## Emotion-recognition task

Participants completed up to 80 trials sampled from the established FACES set
and an AI-generated set. Trial records contained the stimulus, target emotion,
response, correctness, and response time. FACES covered anger, disgust, fear,
happiness, neutrality, and sadness. AI stimuli covered those six emotions plus
surprise. Primary source comparisons used only the six shared emotions.

The 161 AI images were generated with the GPT-4o image-generation model in
August 2025. Prompts varied age, gender, skin description, hair description, and
emotion. For variants intended to preserve an identity, a preceding generated
image was supplied as a visual reference. Identity matching across variants was
not independently validated. The prompt template and this limitation are
documented in `docs/stimulus_materials.md`.

On each trial, the browser implementation sampled FACES or AI with equal
probability, sampled an available emotion with equal probability within the
selected source, and sampled an unused image from that source-emotion pool. A
pool reset after every image in it had been used. The full 80-trial sequence was
generated before presentation. The isolated logic is supplied in
`task/stimulus_sampling.mjs`.

Stimulus metadata classified face age, gender, and ethnicity. The trial-level
model categories were mutually exclusive: FACES, white AI faces, and non-white
AI faces. The reported AI-diverse set comprised every AI trial and therefore
included the AI-white subset. Diverse-AI estimates were constructed after models
were fitted to the disjoint categories, so no trial was duplicated.

## Data preparation

When multiple attempts existed, one attempt had already been selected in the
restricted source-preparation stage using temporal alignment, completion, and
data-evidence criteria. The public release contains only that selected attempt.
Trial eligibility required a valid trial number, valid source, source-appropriate
target emotion, parseable stimulus metadata, and recorded correctness. Duplicate
trial-number occurrences would retain only the first eligible occurrence and
remain flagged in the cleaning audit.

Accuracy was binary correctness. The primary response-time outcome was response
time on correct trials between 0.20 and 30.00 seconds, inclusive; response time
was log transformed for modelling. All inclusion and exclusion counts are in
`results/tables/trial_cleaning_audit.csv`.

Clinical totals were analysed only when all required items were present. The
eight measures were CAPE-P15, Altman Self-Rating Mania Scale, Insomnia Severity
Index, Obsessive-Compulsive Inventory-Revised, Mini-Social Phobia Inventory,
Adult ADHD Self-Report Scale, GAD-7, and HAMD-6. Script 1 recalculates every score
from released item responses. Descriptive statistics and Cronbach's alpha used
complete item responses in the primary accuracy sample.

## Demographics and attrition

Demographics and missingness were summarised for the full frame, primary
accuracy and RT samples, and every clinical or subgroup analysis. Participant
accuracy and mean correct RT were also summarised by reported stimulus set,
participant gender and ethnicity, and stimulus gender and ethnicity.

Two multivariable logistic regressions evaluated selection. The first compared
participants with versus without any valid emotion-recognition data in the full
frame. The second compared participants with all 80 valid trials against partial
completers among task starters. Predictors were age, binary participant gender,
white/non-white participant status, and prior mental-health history. Models used
complete covariate cases. Adjusted odds ratios and Wald 95% confidence intervals
were reported. The four demographic predictor p-values were Benjamini-Hochberg
adjusted within each model.

## Mixed-effects models

Trial correctness was analysed with a binomial generalised linear mixed model.
Correct-trial log RT was analysed with a linear mixed model fitted by maximum
likelihood. Fixed effects in both models were stimulus stratum, target emotion,
standardised trial position, and task position. Participant and stimulus random
intercepts represented repeated observations.

A planned participant-specific stimulus-stratum slope model did not complete its
initial lme4 fit after 20 minutes. A separate glmmTMB sensitivity fit completed
but did not converge: it had a non-positive-definite Hessian, singular
convergence, and a correlation of 1.000 between two participant slopes. The
random-intercept model was therefore used without changing the fixed-effects
specification. This simplification is not evidence that slope variance is zero.

Model-standardised estimates were calculated for FACES, AI-white, AI-non-white,
and AI-diverse. The primary AI-diverse estimand used the observed cleaned AI
stimulus mix; an equal-ethnicity estimate was a sensitivity analysis. Contrasts
used joint simulations of fixed-effect coefficients, retaining covariance for
comparisons involving the overlapping AI sets.

Sensitivity analyses repeated the focal contrasts among participants with 80
valid trials, after removing high-ceiling happy trials from accuracy, using a
0.30-to-10-second RT window, and retaining every positive correct RT. Each model
kept the primary covariates and random intercepts.

## Clinical associations

Pearson and Spearman correlations related participant accuracy and mean correct
RT to each complete clinical score for all stimuli, FACES, AI-white, and
AI-diverse. Percentile 95% confidence intervals used 500 participant bootstrap
samples. Differences between dependent correlations were calculated within each
bootstrap draw.

For the manuscript correlations, Benjamini-Hochberg correction was applied to
the 24 tests spanning eight measures and FACES, AI-white, and AI-diverse,
separately within each performance-metric and correlation-method family.
All-stimuli correlations were adjusted as separate eight-test families.
Bootstrap confidence intervals were not multiplicity-adjusted; consequently, an
interval can exclude zero when its FDR-adjusted p-value is at least .05.

Secondary linear models included FACES and AI-diverse performance jointly and
adjusted for age, binary gender contrast, and white/non-white participant status.
These estimate concurrent associations, not diagnostic classification.

## Demographic moderation

Gender moderation models included the interaction among stimulus stratum,
participant gender, and stimulus gender, plus the primary covariates and random
intercepts. Inferential contrasts were restricted to participants reporting woman
or man and stimuli coded woman or man. Model-standardised contrasts compared
same-gender with different-gender stimuli within participant gender and stratum,
and compared participant genders after averaging equally over stimulus genders.

Ethnicity moderation models interacted stimulus stratum with participant
white/non-white status. This coarse grouping is not exact ethnic matching. Since
all FACES stimuli were white-labelled, source and white-stimulus status were
partly confounded. Direct broad-status congruence contrasts were therefore
restricted to AI-white versus pooled AI-non-white trials and interpreted as
observational performance patterns.

Direct contrast intervals and two-sided p-values came from 2,000 joint
fixed-coefficient simulations. P-values were Benjamini-Hochberg adjusted within
outcome and contrast family. Accuracy contrasts are probability differences; RT
contrasts are differences in model-standardised geometric mean seconds.

## Reliability, agreement, and software

Odd/even split-half accuracy reliability with Spearman-Brown correction was
reported for FACES, AI-white, and AI-diverse. Paired FACES-versus-AI-diverse
agreement was summarised by correlation, mean difference, and 95% limits of
agreement. Emotion confusion matrices were reported by source.

The scripts use a fixed seed of 20260908. Exact R and package versions, input and
output hashes, script hashes, model diagnostics, and session information are in
`renv.lock` and `results/provenance/`. No confirmatory non-inferiority conclusion
was made because a non-inferiority margin and primary clinical family were not
specified.

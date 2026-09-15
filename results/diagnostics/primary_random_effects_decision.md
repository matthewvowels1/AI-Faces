# Primary Random-Effects Decision

The planned participant-specific stimulus-stratum slope GLMM was attempted on
the full 77,238-trial primary accuracy sample. The original lme4 fit remained
in its first model after 20 minutes. A separate sensitivity fit using glmmTMB
completed in 122 seconds but did not converge: optimizer code 1, non-positive-
definite Hessian, singular convergence, and a correlation of 1.000 between two
participant stratum slopes. The reproducible primary model therefore uses
participant and stimulus random intercepts with the fixed-effects estimand
unchanged.

This is a convergence-based simplification, not evidence that slope variance is zero.
Sensitivity formula: correct ~ trial_stratum + target_emotion + trial_position_z +
task_position + (1 + trial_stratum | participant_id) + (1 | stimulus_id).

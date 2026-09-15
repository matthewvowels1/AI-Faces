# Statistical Model Equations

This document expresses the executable models in `R/02_run_analyses.R` in
publication-readable notation. It is descriptive of this analysis and does not
resolve the open confirmatory decisions in `analysis_decisions.csv`.

## Notation

Let participant be indexed by \(i\), stimulus by \(j\), and trial by \(t\). The
disjoint trial stratum \(S_{ijt}\) is FACES, AI-white, or AI-non-white. Emotion is
\(E_{ijt}\), standardised trial position is \(P_{ijt}\), and task position is
\(O_i\).

## Completion models

Two participant-level logistic regressions are fitted. The first outcome is any
valid emotion-recognition data in the full frame. The second is 80 valid trials
among participants who started the task:

\[
\operatorname{logit}\{\Pr(C_i=1)\}=\beta_0+\beta_1\operatorname{age}_i+
\beta_2\operatorname{man}_i+\beta_3\operatorname{nonWhite}_i+
\beta_4\operatorname{priorMentalHealth}_i.
\]

Both models use complete covariate cases. Results include adjusted odds ratios,
Wald 95% confidence intervals, raw p-values, and Benjamini-Hochberg p-values for
the four demographic predictors within each model.

## Trial-level accuracy

For binary correctness \(Y_{ijt}\):

\[
Y_{ijt}\sim\operatorname{Bernoulli}(p_{ijt}),
\]

\[
\operatorname{logit}(p_{ijt})=\beta_0+
\boldsymbol{\beta}_S^T S_{ijt}+\boldsymbol{\beta}_E^T E_{ijt}+
\beta_P P_{ijt}+\boldsymbol{\beta}_O^T O_i+b_{0i}+u_{0j}.
\]

Participants and stimuli have normally distributed random intercepts. The
planned participant-specific stratum-slope model was simplified after the
nonconvergence documented in `results/diagnostics/primary_random_effects_decision.md`.

## Correct-response time

For correct response time \(RT_{ijt}\) within the primary bounds:

\[
\log(RT_{ijt})=\beta_0+
\boldsymbol{\beta}_S^T S_{ijt}+\boldsymbol{\beta}_E^T E_{ijt}+
\beta_P P_{ijt}+\boldsymbol{\beta}_O^T O_i+b_{0i}+u_{0j}+\epsilon_{ijt}.
\]

This model is fitted by maximum likelihood. Exponentiated standardised estimates
are geometric mean response times in seconds.

## Overlapping reported sets

Let \(\hat\eta_W\) and \(\hat\eta_N\) denote standardised predictions on the
linear-predictor scale for AI-white and AI-non-white. The observed-mix
AI-diverse prediction is formed as

\[
\hat\eta_D=w_W\hat\eta_W+(1-w_W)\hat\eta_N,
\]

where \(w_W\) is the cleaned proportion of AI trials that are white. The pooled
linear predictor is transformed to probability or seconds afterward. The
equal-ethnicity sensitivity assigns equal total weight to white, Asian, Black,
Indian, and Latin stimuli. Joint coefficient simulations preserve covariance in
contrasts involving shared AI-white trials.

## Clinical associations

For clinical score \(K_i\) and participant performance \(M_{is}\) in reported
set \(s\):

\[
r_{Ks}=\operatorname{cor}(K_i,M_{is}).
\]

Both Pearson and Spearman correlations are reported. Participant bootstrap
resampling supplies percentile intervals. Differences such as
\(r_{K,D}-r_{K,F}\) are calculated within each bootstrap draw, preserving the
pairing and overlap of measurements.

Secondary incremental models ask whether AI-diverse and FACES performance each
explain unique variation in a standardised clinical score:

\[
K_i^*=\beta_0+\beta_F F_i^*+\beta_D D_i^*+
\beta_A\operatorname{age}_i^*+\boldsymbol{\beta}_G^T\operatorname{gender}_i+
\boldsymbol{\beta}_R^T\operatorname{whiteStatus}_i+\epsilon_i.
\]

These are association models, not diagnostic classification or causal models.

## Gender moderation

Accuracy uses a logistic mixed model and RT uses a log-linear mixed model with
the interaction

\[
S_{ijt}\times G_i\times G_j,
\]

plus emotion, trial position, task position, participant random intercept, and
stimulus random intercept. For stratum \(s\) and participant gender \(g\), the
response-scale congruence estimand is

\[
\Delta_{G,s,g}=\bar{\hat Y}_{s,g,\mathrm{same}}-
\bar{\hat Y}_{s,g,\mathrm{different}}.
\]

Predictions are averaged over common emotions and the observed task-position
distribution, with trial position fixed at its mean. The pooled contrast gives
woman and man participant groups equal weight.

## White-status moderation

The coarse white/non-white model uses

\[
S_{ijt}\times R_i,
\]

where \(R_i\) is participant white status. Direct congruence contrasts are
limited to AI stimuli:

\[
\Delta_{R,r}=\bar{\hat Y}_{r,\mathrm{same\ AI\ status}}-
\bar{\hat Y}_{r,\mathrm{different\ AI\ status}}.
\]

The equally pooled contrast gives white and non-white participant groups equal
weight. It compares AI-white with pooled AI-non-white stimuli and is not an exact
participant-stimulus ethnicity match.

## Reliability and agreement

Odd/even split-half accuracy correlations use the Spearman-Brown correction:

\[
r_{SB}=\frac{2r_{half}}{1+r_{half}}.
\]

FACES and AI-diverse agreement is summarised by participant-level correlation,
mean paired difference, and limits of agreement:

\[
\bar d\mathbin{+/-}1.96\operatorname{SD}(d).
\]

Correlation alone does not establish interchangeability or non-inferiority.

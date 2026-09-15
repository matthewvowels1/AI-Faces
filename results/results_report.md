# Emotion Recognition: FACES vs AI Faces Results Report

Generated: 2026-09-15 13:42:48 CEST

> Status: complete provisional run. The primary clinical family and non-inferiority margin remain unresolved, so no confirmatory replacement claim is made.

## Cohort



|stage                                             | n_participants| percent_of_source|
|:-------------------------------------------------|--------------:|-----------------:|
|Participant source frame                          |           1277|            100.00|
|Screening/intake data available                   |           1064|             83.32|
|Any linked emotion-recognition attempt            |           1069|             83.71|
|At least one valid emotion-recognition trial      |           1047|             81.99|
|Completed 80 valid emotion-recognition trials     |           1029|             80.58|
|Included in primary common-emotion accuracy model |           1047|             81.99|
|Included in primary correct-RT model              |           1046|             81.91|
|Included in gender moderation                     |            978|             76.59|
|Included in white-status moderation               |            999|             78.23|

### Structural demographic availability

Intake demographics were unavailable for 174/230 participants without valid emotion-recognition data and 39/1,047 participants with valid data. The adjusted regressions are therefore explicitly complete-case models rather than models of all 1,277 source participants.



|emotion_recognition |intake_demographics |    n|
|:-------------------|:-------------------|----:|
|Included            |Available           | 1008|
|Included            |Unavailable         |   39|
|Not included        |Available           |   56|
|Not included        |Unavailable         |  174|



|comparison                                                       | odds_ratio| conf_low| conf_high|p_value |interpretation                                                                                   |
|:----------------------------------------------------------------|----------:|--------:|---------:|:-------|:------------------------------------------------------------------------------------------------|
|Emotion-recognition inclusion by intake-demographic availability |     79.423|   50.701|   128.202|<0.001  |Odds of emotion-recognition inclusion when intake demographics were available versus unavailable |

### Adjusted attrition models

The first model concerns any valid emotion-recognition data. The second has only nine incomplete cases in its complete-covariate sample, so its intervals are necessarily imprecise.



|model                                    |    n|term                              | odds_ratio| odds_ratio_low| odds_ratio_high| p.value| p_fdr|
|:----------------------------------------|----:|:---------------------------------|----------:|--------------:|---------------:|-------:|-----:|
|Any valid emotion-recognition data       | 1019|age_z                             |      0.983|          0.733|           1.328|   0.908| 0.908|
|Any valid emotion-recognition data       | 1019|gender_binaryMan                  |      0.538|          0.293|           0.963|   0.040| 0.159|
|Any valid emotion-recognition data       | 1019|participant_white_statusNon-white |      1.133|          0.599|           2.237|   0.709| 0.908|
|Any valid emotion-recognition data       | 1019|prior_mh_binaryPrior condition    |      0.808|          0.323|           1.748|   0.615| 0.908|
|Completed 80 valid trials among starters |  969|age_z                             |      0.645|          0.332|           1.249|   0.188| 0.754|
|Completed 80 valid trials among starters |  969|gender_binaryMan                  |      1.592|          0.413|           7.635|   0.516| 0.848|
|Completed 80 valid trials among starters |  969|participant_white_statusNon-white |      1.175|          0.259|           8.309|   0.848| 0.848|
|Completed 80 valid trials among starters |  969|prior_mh_binaryPrior condition    |      0.725|          0.039|           4.115|   0.765| 0.848|

## Clinical Instrument Descriptives and Internal Consistency

Totals required complete item data. Cronbach's alpha was calculated from complete item responses in the primary accuracy sample.



|instrument | items|    n|   mean|     sd| median|observed_range |theoretical_range | cronbach_alpha|
|:----------|-----:|----:|------:|------:|------:|:--------------|:-----------------|--------------:|
|CAPE-P15   |    15| 1019| 22.197|  7.494|     20|15-55          |15-60             |          0.920|
|ASRM       |     5| 1020|  4.059|  3.488|      3|0-19           |0-20              |          0.738|
|ISI        |     7| 1019|  9.944|  6.543|      9|0-28           |0-28              |          0.893|
|OCI-R      |    18| 1018| 17.555| 14.515|     14|0-69           |0-72              |          0.933|
|Mini-SPIN  |     3| 1018|  5.274|  3.747|      5|0-12           |0-12              |          0.864|
|ASRS       |    18| 1019| 27.048| 15.900|     26|0-72           |0-72              |          0.947|
|GAD-7      |     7|  444| 11.802|  4.716|     12|0-21           |0-21              |          0.835|
|HAMD-6     |     6|  399|  9.860|  3.520|      9|1-21           |0-22              |          0.657|

## Descriptive Performance

Participant summaries use the six emotions common to FACES and AI. AI-white is a subset of AI-diverse.



|metric                     |stimulus_set | n_participants|   mean|     sd| median|    q25|     q75|
|:--------------------------|:------------|--------------:|------:|------:|------:|------:|-------:|
|accuracy_common_pct        |AI-diverse   |           1039| 86.149| 10.725| 88.235| 81.579|  93.548|
|accuracy_common_pct        |AI-white     |           1029| 87.292| 13.747| 90.000| 81.818| 100.000|
|accuracy_common_pct        |FACES        |           1040| 76.196| 10.567| 77.273| 70.256|  83.721|
|correct_rt_common_mean_sec |AI-diverse   |           1035|  2.646|  0.920|  2.424|  2.014|   3.027|
|correct_rt_common_mean_sec |AI-white     |           1033|  2.614|  1.095|  2.311|  1.906|   2.986|
|correct_rt_common_mean_sec |FACES        |           1038|  2.951|  0.975|  2.728|  2.260|   3.393|

## Mixed-Model Standardised Estimates

The model was fitted to disjoint FACES, AI-white, and AI-non-white trial strata. AI-diverse was pooled afterwards using the observed cleaned AI trial mix; shared white trials were not duplicated.



|model_type |stimulus_set | estimate| conf_low| conf_high| observed_ai_white_weight|
|:----------|:------------|--------:|--------:|---------:|------------------------:|
|accuracy   |FACES        |  81.7215|  78.1201|   84.7729|                   0.3023|
|accuracy   |AI-white     |  90.0631|  86.9579|   92.5100|                   0.3023|
|accuracy   |AI-diverse   |  89.1187|  87.0931|   90.6856|                   0.3023|
|rt         |FACES        |   2.6373|   2.5612|    2.7184|                   0.3058|
|rt         |AI-white     |   2.2680|   2.1828|    2.3544|                   0.3058|
|rt         |AI-diverse   |   2.2893|   2.2313|    2.3489|                   0.3058|

## Mixed-Model Contrasts



|contrast                                     | estimate| conf_low| conf_high| p_value|model_type |  p_fdr|
|:--------------------------------------------|--------:|--------:|---------:|-------:|:----------|------:|
|AI-white minus FACES                         |   0.0834|   0.0409|    0.1242|  0.0010|accuracy   | 0.0025|
|AI-diverse minus FACES                       |   0.0740|   0.0391|    0.1108|  0.0010|accuracy   | 0.0025|
|AI-diverse minus AI-white                    |  -0.0094|  -0.0320|    0.0142|  0.4578|accuracy   | 0.4578|
|AI-non-white minus AI-white                  |  -0.0135|  -0.0458|    0.0204|  0.4578|accuracy   | 0.4578|
|Equal-standardised minus observed AI-diverse |  -0.0014|  -0.0047|    0.0021|  0.4578|accuracy   | 0.4578|
|AI-white minus FACES                         |  -0.3693|  -0.4730|   -0.2658|  0.0010|rt         | 0.0025|
|AI-diverse minus FACES                       |  -0.3480|  -0.4296|   -0.2670|  0.0010|rt         | 0.0025|
|AI-diverse minus AI-white                    |   0.0213|  -0.0420|    0.0868|  0.5367|rt         | 0.5367|
|AI-non-white minus AI-white                  |   0.0307|  -0.0605|    0.1251|  0.5367|rt         | 0.5367|
|Equal-standardised minus observed AI-diverse |   0.0033|  -0.0064|    0.0132|  0.5367|rt         | 0.5367|

AI-white and observed-mix AI-diverse accuracy exceeded FACES by 8.3 and 7.4 percentage points, respectively. Their corresponding correct RT estimates were 0.37 and 0.35 seconds faster. AI-white and AI-diverse did not differ clearly on either outcome.

## Strongest Descriptive Clinical Associations

These are ranked descriptive Spearman associations with participant-bootstrap confidence intervals. Selection by observed magnitude is exploratory.



|metric     |clinical_label    |stimulus_set |    n| estimate| conf_low| conf_high|p_fdr   |
|:----------|:-----------------|:------------|----:|--------:|--------:|---------:|:-------|
|Accuracy   |CAPE-15 total     |FACES        | 1016|  -0.1866|  -0.2429|   -0.1290|< 0.001 |
|Accuracy   |OCI-R total       |FACES        | 1015|  -0.1689|  -0.2312|   -0.1052|< 0.001 |
|Accuracy   |CAPE-15 total     |AI-diverse   | 1016|  -0.1258|  -0.1833|   -0.0529|< 0.001 |
|Accuracy   |OCI-R total       |AI-diverse   | 1015|  -0.1126|  -0.1723|   -0.0559|0.00195 |
|Accuracy   |CAPE-15 total     |AI-white     | 1005|  -0.1081|  -0.1663|   -0.0521|0.00218 |
|Accuracy   |ASRS total        |FACES        | 1016|  -0.1080|  -0.1666|   -0.0476|0.00218 |
|Accuracy   |Altman SRMS total |FACES        | 1017|  -0.1069|  -0.1664|   -0.0424|0.00218 |
|Accuracy   |OCI-R total       |AI-white     | 1004|  -0.1061|  -0.1705|   -0.0391|0.00229 |
|Accuracy   |Altman SRMS total |AI-diverse   | 1017|  -0.0994|  -0.1630|   -0.0284|0.00403 |
|Correct RT |ASRS total        |AI-white     | 1008|  -0.0787|  -0.1411|   -0.0179|0.29884 |
|Accuracy   |ASRS total        |AI-white     | 1005|  -0.0689|  -0.1302|   -0.0134|0.06941 |
|Correct RT |ASRS total        |AI-diverse   | 1011|  -0.0631|  -0.1222|   -0.0025|0.36291 |
|Accuracy   |ISI total         |FACES        | 1016|  -0.0606|  -0.1259|    0.0003|0.11536 |
|Accuracy   |Altman SRMS total |AI-white     | 1006|  -0.0599|  -0.1221|    0.0090|0.11536 |
|Accuracy   |ASRS total        |AI-diverse   | 1016|  -0.0584|  -0.1157|    0.0031|0.11550 |
|Correct RT |Mini-SPIN total   |AI-diverse   | 1010|  -0.0522|  -0.1078|    0.0209|0.36291 |
|Correct RT |OCI-R total       |FACES        | 1013|  -0.0521|  -0.1176|    0.0081|0.36291 |
|Correct RT |GAD-7 total       |AI-white     |  442|  -0.0516|  -0.1449|    0.0441|0.58055 |
|Correct RT |ISI total         |AI-diverse   | 1011|  -0.0516|  -0.1123|    0.0111|0.36291 |
|Correct RT |ISI total         |AI-white     | 1008|  -0.0513|  -0.1096|    0.0131|0.36291 |

9 Spearman associations among the three reported sets survived the provisional within-family FDR correction. No dependent difference in clinical association survived FDR correction (0 passed the adjusted threshold).

### Incremental clinical signal

FACES and AI-diverse performance were entered jointly, with age, binary gender contrast, and participant white status as covariates. Coefficients are standardised associations with the clinical score; these remain secondary association models rather than diagnostic models.



|metric                     |clinical_label    |performance_term |   n| estimate| conf.low| conf.high|p.value |p_fdr   |
|:--------------------------|:-----------------|:----------------|---:|--------:|--------:|---------:|:-------|:-------|
|accuracy_common_pct        |CAPE-15 total     |FACES            | 959|  -0.1107|  -0.1828|   -0.0387|0.00262 |0.01047 |
|accuracy_common_pct        |CAPE-15 total     |AI-diverse       | 959|  -0.1811|  -0.2524|   -0.1098|< 0.001 |< 0.001 |
|correct_rt_common_mean_sec |CAPE-15 total     |FACES            | 959|   0.0157|  -0.0799|    0.1112|0.74764 |0.89972 |
|correct_rt_common_mean_sec |CAPE-15 total     |AI-diverse       | 959|   0.0484|  -0.0476|    0.1444|0.32250 |0.82612 |
|accuracy_common_pct        |Altman SRMS total |FACES            | 960|  -0.0760|  -0.1501|   -0.0019|0.04448 |0.10167 |
|accuracy_common_pct        |Altman SRMS total |AI-diverse       | 960|  -0.1201|  -0.1935|   -0.0467|0.00136 |0.00728 |
|correct_rt_common_mean_sec |Altman SRMS total |FACES            | 960|  -0.0532|  -0.1495|    0.0431|0.27825 |0.82612 |
|correct_rt_common_mean_sec |Altman SRMS total |AI-diverse       | 960|   0.0915|  -0.0053|    0.1882|0.06391 |0.51125 |
|accuracy_common_pct        |ISI total         |FACES            | 959|  -0.0206|  -0.0974|    0.0562|0.59821 |0.73626 |
|accuracy_common_pct        |ISI total         |AI-diverse       | 959|  -0.0701|  -0.1461|    0.0060|0.07089 |0.12603 |
|correct_rt_common_mean_sec |ISI total         |FACES            | 959|  -0.0327|  -0.1315|    0.0661|0.51632 |0.82612 |
|correct_rt_common_mean_sec |ISI total         |AI-diverse       | 959|  -0.0091|  -0.1084|    0.0903|0.85810 |0.89972 |
|accuracy_common_pct        |OCI-R total       |FACES            | 958|  -0.0918|  -0.1648|   -0.0187|0.01386 |0.03696 |
|accuracy_common_pct        |OCI-R total       |AI-diverse       | 958|  -0.1511|  -0.2234|   -0.0788|< 0.001 |< 0.001 |
|correct_rt_common_mean_sec |OCI-R total       |FACES            | 958|  -0.0598|  -0.1556|    0.0359|0.22062 |0.82612 |
|correct_rt_common_mean_sec |OCI-R total       |AI-diverse       | 958|   0.1235|   0.0273|    0.2198|0.01192 |0.19072 |
|accuracy_common_pct        |Mini-SPIN total   |FACES            | 958|  -0.0039|  -0.0784|    0.0706|0.91884 |0.91884 |
|accuracy_common_pct        |Mini-SPIN total   |AI-diverse       | 958|  -0.0658|  -0.1396|    0.0080|0.08058 |0.12893 |
|correct_rt_common_mean_sec |Mini-SPIN total   |FACES            | 958|   0.0198|  -0.0758|    0.1154|0.68418 |0.89972 |
|correct_rt_common_mean_sec |Mini-SPIN total   |AI-diverse       | 958|   0.0062|  -0.0899|    0.1022|0.89972 |0.89972 |
|accuracy_common_pct        |ASRS total        |FACES            | 959|  -0.0673|  -0.1401|    0.0055|0.06977 |0.12603 |
|accuracy_common_pct        |ASRS total        |AI-diverse       | 959|  -0.0990|  -0.1711|   -0.0270|0.00713 |0.02281 |
|correct_rt_common_mean_sec |ASRS total        |FACES            | 959|   0.0415|  -0.0529|    0.1359|0.38841 |0.82612 |
|correct_rt_common_mean_sec |ASRS total        |AI-diverse       | 959|   0.0066|  -0.0882|    0.1015|0.89078 |0.89972 |
|accuracy_common_pct        |GAD-7 total       |FACES            | 424|  -0.0117|  -0.1293|    0.1058|0.84439 |0.91790 |
|accuracy_common_pct        |GAD-7 total       |AI-diverse       | 424|  -0.0103|  -0.1258|    0.1051|0.86053 |0.91790 |
|correct_rt_common_mean_sec |GAD-7 total       |FACES            | 424|   0.0698|  -0.0805|    0.2202|0.36194 |0.82612 |
|correct_rt_common_mean_sec |GAD-7 total       |AI-diverse       | 424|  -0.0526|  -0.2021|    0.0970|0.49008 |0.82612 |
|accuracy_common_pct        |HAMD-6 total      |FACES            | 378|  -0.0580|  -0.1833|    0.0674|0.36375 |0.48500 |
|accuracy_common_pct        |HAMD-6 total      |AI-diverse       | 378|   0.0737|  -0.0492|    0.1965|0.23907 |0.34773 |
|correct_rt_common_mean_sec |HAMD-6 total      |FACES            | 378|   0.0304|  -0.1327|    0.1936|0.71393 |0.89972 |
|correct_rt_common_mean_sec |HAMD-6 total      |AI-diverse       | 378|  -0.0590|  -0.2209|    0.1029|0.47407 |0.82612 |

## Demographic Moderation

The table below reports interaction coefficients on the log-odds scale for accuracy and log-seconds scale for RT. Model-standardised cell estimates are in `gender_moderation_standardised_estimates.csv` and `white_status_moderation_standardised_estimates.csv`.



|model                                  | participant_n| trial_n|term                                                        | estimate| conf.low| conf.high| p.value|  p_fdr|p_method                          |
|:--------------------------------------|-------------:|-------:|:-----------------------------------------------------------|--------:|--------:|---------:|-------:|------:|:---------------------------------|
|gender_moderation_accuracy_model       |           978|   72464|trial_stratumAI-white:gender_binaryMan                      |   0.0597|  -0.1485|    0.2679|  0.5742| 0.5742|model-reported Wald test          |
|gender_moderation_accuracy_model       |           978|   72464|trial_stratumAI-non-white:gender_binaryMan                  |   0.1550|   0.0199|    0.2901|  0.0246| 0.0738|model-reported Wald test          |
|gender_moderation_accuracy_model       |           978|   72464|gender_binaryMan:face_genderman                             |   0.0640|  -0.0533|    0.1813|  0.2848| 0.5477|model-reported Wald test          |
|gender_moderation_accuracy_model       |           978|   72464|trial_stratumAI-white:gender_binaryMan:face_genderman       |  -0.1353|  -0.4281|    0.1575|  0.3651| 0.5477|model-reported Wald test          |
|gender_moderation_accuracy_model       |           978|   72464|trial_stratumAI-non-white:gender_binaryMan:face_genderman   |  -0.0767|  -0.2812|    0.1278|  0.4624| 0.5549|model-reported Wald test          |
|gender_moderation_rt_model             |           978|   58396|trial_stratumAI-white:gender_binaryMan                      |  -0.0154|  -0.0475|    0.0167|  0.3467| 0.7741|large-sample normal approximation |
|gender_moderation_rt_model             |           978|   58396|trial_stratumAI-non-white:gender_binaryMan                  |   0.0100|  -0.0127|    0.0328|  0.3876| 0.7741|large-sample normal approximation |
|gender_moderation_rt_model             |           978|   58396|gender_binaryMan:face_genderman                             |   0.0047|  -0.0154|    0.0249|  0.6451| 0.7741|large-sample normal approximation |
|gender_moderation_rt_model             |           978|   58396|trial_stratumAI-white:gender_binaryMan:face_genderman       |   0.0214|  -0.0210|    0.0638|  0.3225| 0.7741|large-sample normal approximation |
|gender_moderation_rt_model             |           978|   58396|trial_stratumAI-non-white:gender_binaryMan:face_genderman   |   0.0082|  -0.0235|    0.0398|  0.6133| 0.7741|large-sample normal approximation |
|white_status_moderation_accuracy_model |           999|   74064|trial_stratumAI-white:participant_white_statusNon-white     |  -0.0415|  -0.1943|    0.1114|  0.5951| 0.5951|model-reported Wald test          |
|white_status_moderation_accuracy_model |           999|   74064|trial_stratumAI-non-white:participant_white_statusNon-white |   0.0658|  -0.0410|    0.1726|  0.2271| 0.3406|model-reported Wald test          |
|white_status_moderation_rt_model       |           999|   59674|trial_stratumAI-white:participant_white_statusNon-white     |  -0.0001|  -0.0225|    0.0222|  0.9920| 0.9920|large-sample normal approximation |
|white_status_moderation_rt_model       |           999|   59674|trial_stratumAI-non-white:participant_white_statusNon-white |   0.0054|  -0.0114|    0.0222|  0.5261| 0.9098|large-sample normal approximation |

### Participant-group differences

Accuracy differences are percentage points and RT differences are seconds. Gender contrasts are man minus woman after averaging equally over stimulus genders; broad-status contrasts are non-white minus white within each fixed stimulus stratum.



|contrast_family             |trial_stratum |participant_group               | estimate| conf_low| conf_high|p_value |model_type |p_fdr  |
|:---------------------------|:-------------|:-------------------------------|--------:|--------:|---------:|:-------|:----------|:------|
|Participant man minus woman |FACES         |Stimulus genders equally pooled |  -4.2070|  -5.6579|   -2.7707|<0.001  |accuracy   |0.0015 |
|Participant man minus woman |AI-white      |Stimulus genders equally pooled |  -2.6782|  -4.3788|   -1.2742|<0.001  |accuracy   |0.0015 |
|Participant man minus woman |AI-non-white  |Stimulus genders equally pooled |  -1.8071|  -2.9374|   -0.6738|0.003   |accuracy   |0.0030 |
|Participant man minus woman |FACES         |Stimulus genders equally pooled |   0.0000|  -0.0847|    0.0841|1.000   |rt         |0.9995 |
|Participant man minus woman |AI-white      |Stimulus genders equally pooled |  -0.0107|  -0.0882|    0.0698|0.773   |rt         |0.9995 |
|Participant man minus woman |AI-non-white  |Stimulus genders equally pooled |   0.0324|  -0.0438|    0.1070|0.363   |rt         |0.9995 |



|contrast_family                   |trial_stratum |participant_group      | estimate| conf_low| conf_high|p_value |model_type |p_fdr |
|:---------------------------------|:-------------|:----------------------|--------:|--------:|---------:|:-------|:----------|:-----|
|Participant non-white minus white |FACES         |Stimulus stratum fixed |  -1.2000|  -2.7450|    0.2433|0.103   |accuracy   |0.186 |
|Participant non-white minus white |AI-white      |Stimulus stratum fixed |  -1.0911|  -2.6337|    0.3061|0.124   |accuracy   |0.186 |
|Participant non-white minus white |AI-non-white  |Stimulus stratum fixed |  -0.2192|  -1.4486|    0.9177|0.672   |accuracy   |0.672 |
|Participant non-white minus white |FACES         |Stimulus stratum fixed |   0.0236|  -0.0605|    0.1196|0.539   |rt         |0.575 |
|Participant non-white minus white |AI-white      |Stimulus stratum fixed |   0.0201|  -0.0608|    0.1127|0.575   |rt         |0.575 |
|Participant non-white minus white |AI-non-white  |Stimulus stratum fixed |   0.0331|  -0.0374|    0.1172|0.371   |rt         |0.575 |

### Direct gender-congruence contrasts

Accuracy differences are percentage points and RT differences are seconds. Positive values indicate higher accuracy or slower RT for same-gender than different-gender stimuli. Participant-specific rows and the equally pooled summary are covariance-aware contrasts from the fitted trial model.



|contrast_family                      |trial_stratum |participant_group        | estimate| conf_low| conf_high|p_value |model_type |p_fdr  |
|:------------------------------------|:-------------|:------------------------|--------:|--------:|---------:|:-------|:----------|:------|
|Same minus different stimulus gender |FACES         |Woman                    |  -6.8560| -12.6452|   -1.1067|0.019   |accuracy   |0.0855 |
|Same minus different stimulus gender |FACES         |Man                      |   8.9074|   2.1296|   15.6753|0.009   |accuracy   |0.0810 |
|Same minus different stimulus gender |FACES         |Woman/man equally pooled |   1.0257|   0.1456|    1.9268|0.029   |accuracy   |0.0870 |
|Same minus different stimulus gender |AI-white      |Woman                    |  -3.0136|  -8.7419|    2.2496|0.230   |accuracy   |0.3448 |
|Same minus different stimulus gender |AI-white      |Man                      |   3.0851|  -3.2331|    9.9084|0.323   |accuracy   |0.4151 |
|Same minus different stimulus gender |AI-white      |Woman/man equally pooled |   0.0358|  -1.2063|    1.3852|0.995   |accuracy   |0.9945 |
|Same minus different stimulus gender |AI-non-white  |Woman                    |  -3.7061|  -7.7114|   -0.0405|0.051   |accuracy   |0.1133 |
|Same minus different stimulus gender |AI-non-white  |Man                      |   4.0908|  -0.2431|    8.3189|0.063   |accuracy   |0.1133 |
|Same minus different stimulus gender |AI-non-white  |Woman/man equally pooled |   0.1923|  -0.6380|    0.9898|0.663   |accuracy   |0.7455 |
|Same minus different stimulus gender |FACES         |Woman                    |   0.1754|   0.0408|    0.3088|0.010   |rt         |0.0900 |
|Same minus different stimulus gender |FACES         |Man                      |  -0.1630|  -0.3047|   -0.0281|0.023   |rt         |0.1034 |
|Same minus different stimulus gender |FACES         |Woman/man equally pooled |   0.0062|  -0.0210|    0.0329|0.675   |rt         |0.7590 |
|Same minus different stimulus gender |AI-white      |Woman                    |   0.0634|  -0.0898|    0.2242|0.403   |rt         |0.6042 |
|Same minus different stimulus gender |AI-white      |Man                      |  -0.0040|  -0.1675|    0.1488|0.940   |rt         |0.9395 |
|Same minus different stimulus gender |AI-white      |Woman/man equally pooled |   0.0297|  -0.0111|    0.0709|0.154   |rt         |0.4618 |
|Same minus different stimulus gender |AI-non-white  |Woman                    |   0.0599|  -0.0453|    0.1635|0.290   |rt         |0.5451 |
|Same minus different stimulus gender |AI-non-white  |Man                      |  -0.0310|  -0.1405|    0.0769|0.611   |rt         |0.7590 |
|Same minus different stimulus gender |AI-non-white  |Woman/man equally pooled |   0.0144|  -0.0121|    0.0421|0.303   |rt         |0.5451 |

### Direct broad ethnicity-status congruence contrasts

These contrasts are restricted to AI-white versus AI-non-white trials because FACES has no non-white stimuli. Positive values indicate higher accuracy or slower RT for same-status stimuli. White/non-white status is a deliberately coarse proxy and is not exact ethnic ingroup membership.



|contrast_family                               |trial_stratum                |participant_group              | estimate| conf_low| conf_high|p_value |model_type |p_fdr |
|:---------------------------------------------|:----------------------------|:------------------------------|--------:|--------:|---------:|:-------|:----------|:-----|
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |White                          |   1.6277|  -1.8229|    4.9495|0.328   |accuracy   |0.492 |
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |Non-white                      |  -0.7558|  -4.2583|    3.0945|0.681   |accuracy   |0.681 |
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |White/non-white equally pooled |   0.4359|  -0.3020|    1.2149|0.234   |accuracy   |0.492 |
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |White                          |  -0.0266|  -0.1244|    0.0737|0.618   |rt         |0.622 |
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |Non-white                      |   0.0396|  -0.0643|    0.1391|0.482   |rt         |0.622 |
|Same minus different broad-status AI stimulus |AI-white versus AI-non-white |White/non-white equally pooled |   0.0065|  -0.0198|    0.0337|0.622   |rt         |0.622 |

The smallest FDR-adjusted p-value among the source-by-participant-by-stimulus gender terms was 0.548; the smallest among source-by-participant-white-status interactions was 0.341. These models therefore provide no clear evidence of the prespecified moderation effects.

## Focused Sensitivity Analyses

The AI-diverse versus FACES contrast was repeated among complete 80-trial participants, after excluding high-ceiling happy trials for accuracy, and under narrower and all-positive correct-RT rules.



|model_type |specification                       | estimate| conf_low| conf_high|  p_fdr|
|:----------|:-----------------------------------|--------:|--------:|---------:|------:|
|accuracy   |Primary: all valid, common emotions |   7.3972|   3.9073|   11.0833| 0.0025|
|accuracy   |Complete 80-trial participants      |   7.4153|   3.8412|   11.1248| 0.0025|
|accuracy   |Exclude high-ceiling happy trials   |  10.2747|   5.4499|   15.2280| 0.0025|
|rt         |Primary: correct RT 0.20-30 sec     |  -0.3480|  -0.4296|   -0.2670| 0.0025|
|rt         |Complete 80-trial participants      |  -0.3481|  -0.4334|   -0.2634| 0.0025|
|rt         |Correct RT 0.30-10 sec              |  -0.3223|  -0.3896|   -0.2538| 0.0025|
|rt         |All positive correct RT             |  -0.3558|  -0.4421|   -0.2690| 0.0025|

## Reliability and Agreement



|stimulus_set |    n| split_half_r| spearman_brown|
|:------------|----:|------------:|--------------:|
|AI-diverse   | 1045|        0.535|          0.697|
|AI-white     | 1036|        0.260|          0.412|
|FACES        | 1045|        0.427|          0.598|



|metric                     |    n| pearson_r| mean_difference| sd_difference| lower_agreement| upper_agreement|
|:--------------------------|----:|---------:|---------------:|-------------:|---------------:|---------------:|
|Accuracy percentage points | 1039|     0.560|           9.946|         9.994|          -9.642|          29.535|
|Correct RT seconds         | 1039|     0.771|          -0.307|         0.645|          -1.571|           0.957|

## Model Diagnostics



|model                                    |formula                                                                                                                                                                  | participant_n| trial_n|singular |convergence_message |captured_warnings |
|:----------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------:|-------:|:--------|:-------------------|:-----------------|
|primary_accuracy_mixed_model             |correct ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                    |          1047|   77238|FALSE    |                    |                  |
|primary_rt_mixed_model                   |log_rt ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                     |          1046|   62167|FALSE    |                    |                  |
|sensitivity_complete_task_accuracy_model |correct ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                    |          1029|   76406|FALSE    |                    |                  |
|sensitivity_complete_task_rt_model       |log_rt ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                     |          1029|   61550|FALSE    |                    |                  |
|sensitivity_no_happy_accuracy_model      |correct ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                    |          1047|   64354|FALSE    |                    |                  |
|sensitivity_rt_0_3_to_10_model           |log_rt ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                     |          1046|   60968|FALSE    |                    |                  |
|sensitivity_rt_all_positive_model        |log_rt ~ trial_stratum + target_emotion + trial_position_z +      task_position + (1 &#124; participant_id) + (1 &#124; stimulus_id)                                     |          1046|   62468|FALSE    |                    |                  |
|gender_moderation_accuracy_model         |correct ~ trial_stratum * gender_binary * face_gender + target_emotion +      trial_position_z + task_position + (1 &#124; participant_id) +      (1 &#124; stimulus_id) |           978|   72464|FALSE    |                    |                  |
|gender_moderation_rt_model               |log_rt ~ trial_stratum * gender_binary * face_gender + target_emotion +      trial_position_z + task_position + (1 &#124; participant_id) +      (1 &#124; stimulus_id)  |           978|   58396|FALSE    |                    |                  |
|white_status_moderation_accuracy_model   |correct ~ trial_stratum * participant_white_status + target_emotion +      trial_position_z + task_position + (1 &#124; participant_id) +      (1 &#124; stimulus_id)    |           999|   74064|FALSE    |                    |                  |
|white_status_moderation_rt_model         |log_rt ~ trial_stratum * participant_white_status + target_emotion +      trial_position_z + task_position + (1 &#124; participant_id) +      (1 &#124; stimulus_id)     |           999|   59674|FALSE    |                    |                  |

## Interpretation Boundary

This run establishes descriptive performance, comparative model estimates, clinical associations, attrition models, and demographic moderation models. It does not establish diagnostic validity because the outcomes are symptom instruments rather than clinician-assigned diagnoses. It also does not establish non-inferiority until a defensible margin and primary clinical family are fixed.

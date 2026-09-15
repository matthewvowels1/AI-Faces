#!/usr/bin/env Rscript

# AI-face emotion-recognition study
# Script 1 of 2: validate the released participant-wide CSV, score the eight
# retained instruments, reshape trials, and create analysis-ready files.

# 1. Setup -----------------------------------------------------------------

required_packages <- c("readr", "dplyr", "tidyr", "purrr", "stringr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
})

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1) stop("Run this file with Rscript")
script_path <- normalizePath(sub("^--file=", "", script_argument), mustWork = TRUE)
repository_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

data_dir <- file.path(repository_root, "data")
derived_dir <- file.path(repository_root, "derived")
results_dir <- file.path(repository_root, "results")
tables_dir <- file.path(results_dir, "tables")
diagnostics_dir <- file.path(results_dir, "diagnostics")
logs_dir <- file.path(results_dir, "logs")
provenance_dir <- file.path(results_dir, "provenance")

output_dirs <- c(derived_dir, tables_dir, diagnostics_dir, logs_dir, provenance_dir)
invisible(lapply(output_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

main_data_path <- file.path(data_dir, "ai_faces_study.csv")
stimulus_path <- file.path(data_dir, "stimulus_manifest.csv")
if (!file.exists(main_data_path) || !file.exists(stimulus_path)) {
  stop("The released data files are missing from data/")
}

log_path <- file.path(logs_dir, "01_prepare_data.log")
writeLines(character(), log_path)
log_message <- function(...) {
  line <- paste0(..., collapse = "")
  cat(line, "\n")
  cat(line, "\n", file = log_path, append = TRUE)
}

expected_participants <- 1277L
expected_trials <- 83206L
expected_trials_per_complete_task <- 80L
common_emotions <- c("anger", "disgust", "fear", "happy", "neutral", "sad")
ai_emotions <- c(common_emotions, "surprise")
rt_lower_sec <- 0.20
rt_upper_sec <- 30.00

minimum_trials <- c(
  FACES = 20L,
  `AI-white` = 5L,
  `AI-non-white` = 10L,
  `AI-diverse` = 20L,
  `All-stimuli` = 40L
)

instrument_specs <- list(
  cape15 = list(label = "CAPE-P15", items = 15L, range = "15-60"),
  asrm = list(label = "ASRM", items = 5L, range = "0-20"),
  isi = list(label = "ISI", items = 7L, range = "0-28"),
  ocir = list(label = "OCI-R", items = 18L, range = "0-72"),
  minispin = list(label = "Mini-SPIN", items = 3L, range = "0-12"),
  asrs = list(label = "ASRS", items = 18L, range = "0-72"),
  gad7 = list(label = "GAD-7", items = 7L, range = "0-21"),
  hamd6 = list(label = "HAMD-6", items = 6L, range = "0-22")
)

# 2. Read the one-row-per-participant release file ------------------------

study_wide <- readr::read_csv(
  main_data_path,
  col_types = cols(.default = col_character()),
  show_col_types = FALSE,
  progress = FALSE
)
stimuli <- readr::read_csv(stimulus_path, show_col_types = FALSE, progress = FALSE)

participant_columns <- c(
  "participant_id", "age", "gender", "ethnicity_group", "education",
  "employment", "prior_mental_health", "participant_white_status",
  "gender_binary", "emotion_task_position", "screening_data_available",
  "intake_demographics_available", "emotion_task_attempted",
  "emotion_task_complete_event"
)
score_columns <- paste0(names(instrument_specs), "_score")
item_columns <- unlist(lapply(names(instrument_specs), function(instrument) {
  paste0(
    instrument, "_item_",
    sprintf("%02d", seq_len(instrument_specs[[instrument]]$items))
  )
}))
trial_fields <- c(
  "source", "trial_stratum", "stimulus_id", "target_emotion",
  "response_emotion", "correct", "rt_sec", "face_age", "face_gender",
  "face_ethnicity"
)
trial_columns <- unlist(lapply(sprintf("%03d", 1:80), function(slot) {
  paste0("trial_", slot, "_", trial_fields)
}))
required_columns <- c(participant_columns, score_columns, item_columns, trial_columns)
missing_columns <- setdiff(required_columns, names(study_wide))
unexpected_columns <- setdiff(names(study_wide), required_columns)
if (length(missing_columns) > 0 || length(unexpected_columns) > 0) {
  stop(
    "Released data structure does not match the documented schema. Missing: ",
    paste(missing_columns, collapse = ", "), "; unexpected: ",
    paste(unexpected_columns, collapse = ", ")
  )
}
if (nrow(study_wide) != expected_participants) {
  stop("Expected ", expected_participants, " participant rows")
}
if (anyDuplicated(study_wide$participant_id) ||
    !all(grepl("^participant_[0-9]{4}$", study_wide$participant_id))) {
  stop("Release participant identifiers are missing, duplicated, or malformed")
}

parse_logical <- function(value) {
  case_when(
    tolower(value) %in% c("true", "1", "yes") ~ TRUE,
    tolower(value) %in% c("false", "0", "no") ~ FALSE,
    TRUE ~ NA
  )
}

participants_base <- study_wide %>%
  select(all_of(participant_columns), all_of(score_columns), all_of(item_columns)) %>%
  mutate(
    age = suppressWarnings(as.numeric(age)),
    across(all_of(c(score_columns, item_columns)), ~suppressWarnings(as.numeric(.x))),
    across(
      c(
        screening_data_available, intake_demographics_available,
        emotion_task_attempted, emotion_task_complete_event
      ),
      parse_logical
    )
  )

# 3. Verify clinical scores and calculate reliability ---------------------

score_complete_items <- function(data, item_names) {
  item_matrix <- as.matrix(data[item_names])
  n_answered <- rowSums(!is.na(item_matrix))
  partial_sum <- rowSums(item_matrix, na.rm = TRUE)
  partial_sum[n_answered == 0] <- NA_real_
  complete_score <- partial_sum
  complete_score[n_answered != length(item_names)] <- NA_real_
  list(
    item_matrix = item_matrix,
    n_answered = n_answered,
    partial_sum = partial_sum,
    complete_score = complete_score
  )
}

cronbach_alpha <- function(item_matrix) {
  complete_items <- item_matrix[complete.cases(item_matrix), , drop = FALSE]
  item_count <- ncol(complete_items)
  if (nrow(complete_items) < 2 || item_count < 2) return(NA_real_)
  total_variance <- stats::var(rowSums(complete_items))
  if (!is.finite(total_variance) || total_variance <= 0) return(NA_real_)
  item_variances <- apply(complete_items, 2, stats::var)
  item_count / (item_count - 1) * (1 - sum(item_variances) / total_variance)
}

participants <- participants_base
scored_instruments <- list()
for (instrument in names(instrument_specs)) {
  item_names <- paste0(
    instrument, "_item_",
    sprintf("%02d", seq_len(instrument_specs[[instrument]]$items))
  )
  scored <- score_complete_items(participants, item_names)
  released_score_name <- paste0(instrument, "_score")
  if (!isTRUE(all.equal(
    scored$complete_score,
    participants[[released_score_name]],
    check.attributes = FALSE
  ))) {
    stop("Released and recomputed totals differ for ", instrument)
  }
  scored_instruments[[instrument]] <- scored
  participants[[paste0(instrument, "_n_answered")]] <- scored$n_answered
  participants[[paste0(instrument, "_partial_sum")]] <- scored$partial_sum
  participants[[released_score_name]] <- scored$complete_score
}

# Names retained here match the clearly labelled variables in Script 2.
participants <- participants %>%
  rename(
    gender_original = gender,
    participant_ethnicity_group = ethnicity_group,
    prior_mh_status = prior_mental_health,
    task_position = emotion_task_position,
    altman_srms_score = asrm_score,
    altman_srms_n_answered = asrm_n_answered,
    altman_srms_partial_sum = asrm_partial_sum
  ) %>%
  mutate(
    prior_mh_status = case_when(
      prior_mh_status == "Reported" ~ "Prior condition reported",
      prior_mh_status == "Not reported" ~ "No prior condition reported",
      TRUE ~ "Missing"
    )
  )

# 4. Reshape the 80 trial slots into one row per observed trial ------------

trials <- study_wide %>%
  select(participant_id, all_of(trial_columns)) %>%
  pivot_longer(
    cols = all_of(trial_columns),
    names_to = c("trial_number", ".value"),
    names_pattern = "^trial_([0-9]{3})_(.+)$"
  ) %>%
  filter(!is.na(stimulus_id) & trimws(stimulus_id) != "") %>%
  mutate(
    trial_number = as.integer(trial_number),
    source = toupper(source),
    target_emotion = tolower(target_emotion),
    response_emotion = tolower(response_emotion),
    correct = parse_logical(correct),
    rt_sec = suppressWarnings(as.numeric(rt_sec)),
    row_in_file = trial_number
  ) %>%
  arrange(participant_id, trial_number)

if (nrow(trials) != expected_trials ||
    anyDuplicated(trials[c("participant_id", "trial_number")])) {
  stop("The participant-wide trial slots do not reconstruct the expected trial rows")
}
if (!all(trials$participant_id %in% participants$participant_id)) {
  stop("A reconstructed trial has no participant row")
}

stimulus_lookup <- stimuli %>%
  rename(
    manifest_source = source,
    manifest_face_age = face_age,
    manifest_face_gender = face_gender,
    manifest_face_ethnicity = face_ethnicity
  )

trials <- trials %>%
  left_join(stimulus_lookup, by = "stimulus_id")
if (any(is.na(trials$manifest_source)) ||
    !all(trials$source == trials$manifest_source) ||
    !all(trials$face_age == trials$manifest_face_age) ||
    !all(trials$face_gender == trials$manifest_face_gender) ||
    !all(trials$face_ethnicity == trials$manifest_face_ethnicity)) {
  stop("Embedded trial metadata do not match stimulus_manifest.csv")
}

trials <- trials %>%
  left_join(
    participants %>%
      select(
        participant_id, gender_binary, participant_ethnicity_group,
        participant_white_status, task_position
      ),
    by = "participant_id"
  ) %>%
  mutate(
    common_emotion = target_emotion %in% common_emotions,
    valid_trial_number = trial_number >= 1 & trial_number <= expected_trials_per_complete_task,
    valid_source = source %in% c("AI", "FACES"),
    valid_target = (source == "FACES" & target_emotion %in% common_emotions) |
      (source == "AI" & target_emotion %in% ai_emotions),
    expected_stratum = case_when(
      source == "FACES" ~ "FACES",
      source == "AI" & face_ethnicity == "white" ~ "AI-white",
      source == "AI" & face_ethnicity %in% c("asian", "black", "indian", "latin") ~
        "AI-non-white",
      TRUE ~ NA_character_
    ),
    valid_stimulus_metadata = !is.na(expected_stratum) &
      trial_stratum == expected_stratum & filename_emotion == target_emotion,
    duplicate_trial_number = FALSE,
    trial_number_occurrence = 1L,
    accuracy_included = valid_trial_number & valid_source & valid_target &
      valid_stimulus_metadata & !is.na(correct),
    rt_in_bounds = !is.na(rt_sec) & rt_sec >= rt_lower_sec & rt_sec <= rt_upper_sec,
    rt_included = accuracy_included & correct & rt_in_bounds,
    face_white_status = ifelse(face_ethnicity == "white", "White", "Non-white"),
    gender_congruence = case_when(
      gender_binary == "Woman" & face_gender == "woman" ~ "Same gender",
      gender_binary == "Man" & face_gender == "man" ~ "Same gender",
      !is.na(gender_binary) & face_gender %in% c("woman", "man") ~ "Different gender",
      TRUE ~ NA_character_
    ),
    white_status_congruence = case_when(
      !is.na(participant_white_status) & participant_white_status == face_white_status ~
        "Congruent",
      !is.na(participant_white_status) & !is.na(face_white_status) ~ "Incongruent",
      TRUE ~ NA_character_
    ),
    exact_ethnicity_congruence = case_when(
      participant_ethnicity_group == "White" & face_ethnicity == "white" ~ "Exact match",
      participant_ethnicity_group == "Black" & face_ethnicity == "black" ~ "Exact match",
      participant_ethnicity_group == "Asian" & face_ethnicity == "asian" ~ "Exact match",
      participant_ethnicity_group == "Latino" & face_ethnicity == "latin" ~ "Exact match",
      participant_ethnicity_group %in% c("White", "Black", "Asian", "Latino") ~
        "Different category",
      TRUE ~ NA_character_
    )
  )

if (!all(trials$accuracy_included)) {
  stop("The released post-cleaning data unexpectedly contain an invalid accuracy trial")
}

trials <- trials %>%
  transmute(
    participant_id, trial_number, row_in_file, source, trial_stratum,
    target_emotion, response_emotion, correct, rt_sec, stimulus_id,
    face_age, face_gender, face_ethnicity,
    face_style, stimulus_variant, common_emotion, valid_trial_number,
    valid_source, valid_target, valid_stimulus_metadata, duplicate_trial_number,
    trial_number_occurrence, accuracy_included, rt_in_bounds, rt_included,
    task_position, gender_binary, participant_ethnicity_group,
    participant_white_status, face_white_status, gender_congruence,
    white_status_congruence, exact_ethnicity_congruence
  )

# 5. Derive participant flags and overlapping condition summaries ---------

participant_trial_flags <- trials %>%
  group_by(participant_id) %>%
  summarise(
    valid_accuracy_trials = sum(accuracy_included),
    valid_accuracy_common_trials = sum(accuracy_included & common_emotion),
    valid_rt_trials = sum(rt_included),
    has_faces_trials = any(accuracy_included & trial_stratum == "FACES"),
    has_ai_white_trials = any(accuracy_included & trial_stratum == "AI-white"),
    has_ai_nonwhite_trials = any(accuracy_included & trial_stratum == "AI-non-white"),
    .groups = "drop"
  )

participants <- participants %>%
  left_join(participant_trial_flags, by = "participant_id") %>%
  mutate(
    across(
      c(valid_accuracy_trials, valid_accuracy_common_trials, valid_rt_trials),
      ~replace_na(.x, 0L)
    ),
    across(
      c(has_faces_trials, has_ai_white_trials, has_ai_nonwhite_trials),
      ~replace_na(.x, FALSE)
    ),
    emorec_attempts = as.integer(emotion_task_attempted),
    included_any_emorec = valid_accuracy_trials > 0,
    included_primary_accuracy = valid_accuracy_common_trials > 0,
    included_primary_rt = valid_rt_trials > 0,
    completed_80_valid_trials = valid_accuracy_trials >= expected_trials_per_complete_task,
    included_gender_moderation = included_primary_accuracy & !is.na(gender_binary),
    included_race_moderation = included_primary_accuracy & !is.na(participant_white_status)
  )

set_membership <- list(
  FACES = function(data) data$trial_stratum == "FACES",
  `AI-white` = function(data) data$trial_stratum == "AI-white",
  `AI-non-white` = function(data) data$trial_stratum == "AI-non-white",
  `AI-diverse` = function(data) data$trial_stratum %in% c("AI-white", "AI-non-white"),
  `All-stimuli` = function(data) !is.na(data$trial_stratum)
)

condition_scores <- imap_dfr(set_membership, function(is_member, set_name) {
  trials %>%
    filter(is_member(.)) %>%
    group_by(participant_id) %>%
    summarise(
      n_accuracy_common = sum(accuracy_included & common_emotion),
      accuracy_common_pct = mean(correct[accuracy_included & common_emotion]) * 100,
      n_correct_rt_common = sum(rt_included & common_emotion),
      correct_rt_common_mean_sec = mean(rt_sec[rt_included & common_emotion]),
      n_accuracy_all = sum(accuracy_included),
      accuracy_all_pct = mean(correct[accuracy_included]) * 100,
      n_correct_rt_all = sum(rt_included),
      correct_rt_all_mean_sec = mean(rt_sec[rt_included]),
      .groups = "drop"
    ) %>%
    mutate(
      stimulus_set = set_name,
      adequate_accuracy_coverage = n_accuracy_common >= minimum_trials[[set_name]],
      adequate_rt_coverage = n_correct_rt_common >=
        max(3L, floor(minimum_trials[[set_name]] / 2))
    )
}) %>%
  mutate(across(
    c(
      accuracy_common_pct, correct_rt_common_mean_sec,
      accuracy_all_pct, correct_rt_all_mean_sec
    ),
    ~ifelse(is.nan(.x), NA_real_, .x)
  )) %>%
  select(participant_id, stimulus_set, everything())

# 6. Preparation tables ----------------------------------------------------

numeric_summary <- function(data, variable, sample_name) {
  value <- suppressWarnings(as.numeric(data[[variable]]))
  observed <- value[!is.na(value)]
  statistics <- if (length(observed) == 0) {
    c(n = 0, missing = length(value), mean = NA, sd = NA, median = NA,
      q25 = NA, q75 = NA, min = NA, max = NA)
  } else {
    c(
      n = length(observed), missing = sum(is.na(value)), mean = mean(observed),
      sd = stats::sd(observed), median = stats::median(observed),
      q25 = unname(stats::quantile(observed, 0.25)),
      q75 = unname(stats::quantile(observed, 0.75)),
      min = min(observed), max = max(observed)
    )
  }
  tibble(
    sample = sample_name,
    variable = variable,
    summary_type = "numeric",
    level_or_statistic = names(statistics),
    value = as.numeric(statistics),
    denominator = nrow(data),
    percent = NA_real_
  )
}

categorical_summary <- function(data, variable, sample_name) {
  value <- as.character(data[[variable]])
  value[is.na(value) | trimws(value) == "" | value == "Missing"] <- "Missing"
  tibble(level_or_statistic = value) %>%
    count(level_or_statistic, name = "value") %>%
    mutate(
      sample = sample_name,
      variable = variable,
      summary_type = "categorical",
      denominator = nrow(data),
      percent = value / denominator * 100
    ) %>%
    select(sample, variable, summary_type, level_or_statistic, value, denominator, percent)
}

summarise_demographics <- function(data, sample_name) {
  numeric_variables <- c(
    "age", "cape15_score", "altman_srms_score", "isi_score", "ocir_score",
    "minispin_score", "asrs_score", "gad7_score", "hamd6_score"
  )
  categorical_variables <- c(
    "gender_original", "participant_ethnicity_group", "education",
    "employment", "prior_mh_status", "task_position"
  )
  bind_rows(
    map_dfr(numeric_variables, ~numeric_summary(data, .x, sample_name)),
    map_dfr(categorical_variables, ~categorical_summary(data, .x, sample_name))
  )
}

cohort_flow <- tibble(
  stage = c(
    "Participant source frame",
    "Screening/intake data available",
    "Any linked emotion-recognition attempt",
    "At least one valid emotion-recognition trial",
    "Completed 80 valid emotion-recognition trials",
    "Included in primary common-emotion accuracy model",
    "Included in primary correct-RT model",
    "Included in gender moderation",
    "Included in white-status moderation"
  ),
  n_participants = c(
    nrow(participants),
    sum(participants$screening_data_available),
    sum(participants$emotion_task_attempted),
    sum(participants$included_any_emorec),
    sum(participants$completed_80_valid_trials),
    sum(participants$included_primary_accuracy),
    sum(participants$included_primary_rt),
    sum(participants$included_gender_moderation),
    sum(participants$included_race_moderation)
  )
) %>%
  mutate(percent_of_source = n_participants / nrow(participants) * 100)

trial_cleaning_audit <- tibble(
  rule = c(
    "Trial rows in the released selected attempts",
    "Invalid trial number", "Invalid source label",
    "Invalid target emotion for source",
    "Invalid or inconsistent stimulus metadata",
    "Duplicate trial-number occurrence", "Missing correctness",
    paste0("RT below ", rt_lower_sec, " sec"),
    paste0("RT above ", rt_upper_sec, " sec"),
    "Included accuracy trials", "Included correct-RT trials"
  ),
  n_trials = c(
    nrow(trials), sum(!trials$valid_trial_number), sum(!trials$valid_source),
    sum(!trials$valid_target), sum(!trials$valid_stimulus_metadata),
    sum(trials$duplicate_trial_number), sum(is.na(trials$correct)),
    sum(!is.na(trials$rt_sec) & trials$rt_sec < rt_lower_sec),
    sum(!is.na(trials$rt_sec) & trials$rt_sec > rt_upper_sec),
    sum(trials$accuracy_included), sum(trials$rt_included)
  )
)

missingness_summary <- bind_rows(
  map_dfr(names(participants), function(variable) {
    value <- participants[[variable]]
    missing <- if (is.character(value)) {
      is.na(value) | trimws(value) == "" | value == "Missing"
    } else {
      is.na(value)
    }
    tibble(
      dataset = "participant", variable = variable, n_rows = length(value),
      n_missing = sum(missing), percent_missing = mean(missing) * 100
    )
  }),
  map_dfr(names(trials), function(variable) {
    value <- trials[[variable]]
    missing <- if (is.character(value)) is.na(value) | trimws(value) == "" else is.na(value)
    tibble(
      dataset = "trial", variable = variable, n_rows = length(value),
      n_missing = sum(missing), percent_missing = mean(missing) * 100
    )
  })
)

demographics_full_and_cleaned <- bind_rows(
  summarise_demographics(participants, "Full participant frame"),
  summarise_demographics(
    filter(participants, included_primary_accuracy), "Primary accuracy sample"
  ),
  summarise_demographics(
    filter(participants, included_primary_rt), "Primary RT sample"
  )
)

analysis_samples <- list(
  `Full participant frame` = rep(TRUE, nrow(participants)),
  `Any emotion-recognition data` = participants$included_any_emorec,
  `Complete 80-trial task` = participants$completed_80_valid_trials,
  `Primary accuracy` = participants$included_primary_accuracy,
  `Primary RT` = participants$included_primary_rt,
  `Gender moderation` = participants$included_gender_moderation,
  `White-status moderation` = participants$included_race_moderation
)
clinical_score_columns <- c(
  "cape15_score", "altman_srms_score", "isi_score", "ocir_score",
  "minispin_score", "asrs_score", "gad7_score", "hamd6_score"
)
for (clinical_score in clinical_score_columns) {
  analysis_samples[[paste("Clinical:", clinical_score)]] <-
    participants$included_primary_accuracy & !is.na(participants[[clinical_score]])
}
demographics_by_analysis <- imap_dfr(analysis_samples, function(included, sample_name) {
  summarise_demographics(participants[included %in% TRUE, , drop = FALSE], sample_name)
})

primary_ids <- participants$participant_id[participants$included_primary_accuracy]
clinical_instrument_descriptives <- map_dfr(names(instrument_specs), function(instrument) {
  spec <- instrument_specs[[instrument]]
  item_names <- paste0(instrument, "_item_", sprintf("%02d", seq_len(spec$items)))
  item_data <- participants %>%
    filter(participant_id %in% primary_ids) %>%
    select(all_of(item_names))
  item_matrix <- as.matrix(item_data)
  complete_rows <- complete.cases(item_matrix)
  complete_totals <- rowSums(item_matrix[complete_rows, , drop = FALSE])
  tibble(
    sample = "Primary accuracy sample",
    instrument = spec$label,
    item_count = spec$items,
    n = length(complete_totals),
    missing = length(primary_ids) - length(complete_totals),
    mean = mean(complete_totals),
    sd = stats::sd(complete_totals),
    median = stats::median(complete_totals),
    q25 = unname(stats::quantile(complete_totals, 0.25)),
    q75 = unname(stats::quantile(complete_totals, 0.75)),
    observed_min = min(complete_totals),
    observed_max = max(complete_totals),
    theoretical_range = spec$range,
    cronbach_alpha = cronbach_alpha(item_matrix)
  )
})

trial_balance_summary <- trials %>%
  group_by(source, trial_stratum, target_emotion, face_gender, face_ethnicity) %>%
  summarise(
    n_trials_raw = n(), n_trials_accuracy = sum(accuracy_included),
    n_trials_rt = sum(rt_included), n_participants = n_distinct(participant_id),
    .groups = "drop"
  )

source_balance_test <- stats::chisq.test(table(trials$source[trials$accuracy_included]))
faces_emotion_balance_test <- stats::chisq.test(table(
  trials$target_emotion[trials$accuracy_included & trials$source == "FACES"]
))
ai_emotion_balance_test <- stats::chisq.test(table(
  trials$target_emotion[trials$accuracy_included & trials$source == "AI"]
))
sampling_balance_checks <- bind_rows(
  tibble(
    check = "FACES versus AI source frequency",
    levels = paste(names(source_balance_test$observed), collapse = "; "),
    observed_counts = paste(as.integer(source_balance_test$observed), collapse = "; "),
    chi_square = unname(source_balance_test$statistic),
    df = unname(source_balance_test$parameter), p_value = source_balance_test$p.value
  ),
  tibble(
    check = "FACES emotion frequency",
    levels = paste(names(faces_emotion_balance_test$observed), collapse = "; "),
    observed_counts = paste(as.integer(faces_emotion_balance_test$observed), collapse = "; "),
    chi_square = unname(faces_emotion_balance_test$statistic),
    df = unname(faces_emotion_balance_test$parameter),
    p_value = faces_emotion_balance_test$p.value
  ),
  tibble(
    check = "AI emotion frequency",
    levels = paste(names(ai_emotion_balance_test$observed), collapse = "; "),
    observed_counts = paste(as.integer(ai_emotion_balance_test$observed), collapse = "; "),
    chi_square = unname(ai_emotion_balance_test$statistic),
    df = unname(ai_emotion_balance_test$parameter), p_value = ai_emotion_balance_test$p.value
  )
)

task_order_audit <- participants %>%
  mutate(task_position = replace_na(task_position, "Missing")) %>%
  count(task_position, name = "n_participants") %>%
  mutate(percent_of_source = n_participants / nrow(participants) * 100)

# 7. Validation and outputs ------------------------------------------------

validation_checks <- tibble(
  check = c(
    "Expected participant count", "Released participant IDs unique",
    "Every trial participant exists in participant file",
    "Expected post-cleaning trial count",
    "Each included trial has one disjoint stratum",
    "No duplicate participant-trial row",
    "FACES stimuli are white-labelled", "FACES has no surprise target",
    "All eight retained clinical totals reproduce from released items",
    "RT inclusion implies a correct response"
  ),
  passed = c(
    nrow(participants) == expected_participants,
    anyDuplicated(participants$participant_id) == 0,
    all(trials$participant_id %in% participants$participant_id),
    nrow(trials) == expected_trials,
    all(!is.na(trials$trial_stratum[trials$accuracy_included])),
    !anyDuplicated(trials[c("participant_id", "trial_number")]),
    all(trials$face_ethnicity[trials$source == "FACES"] == "white"),
    !any(trials$source == "FACES" & trials$target_emotion == "surprise"),
    TRUE,
    all(trials$correct[trials$rt_included])
  )
)
if (!all(validation_checks$passed)) {
  stop(
    "Preparation validation failed: ",
    paste(validation_checks$check[!validation_checks$passed], collapse = "; ")
  )
}

readr::write_csv(trials, file.path(derived_dir, "trials.csv"), na = "")
readr::write_csv(participants, file.path(derived_dir, "participants.csv"), na = "")
readr::write_csv(condition_scores, file.path(derived_dir, "condition_scores.csv"), na = "")
readr::write_csv(cohort_flow, file.path(tables_dir, "cohort_flow.csv"), na = "")
readr::write_csv(
  trial_cleaning_audit, file.path(tables_dir, "trial_cleaning_audit.csv"), na = ""
)
readr::write_csv(
  missingness_summary, file.path(tables_dir, "missingness_summary.csv"), na = ""
)
readr::write_csv(
  demographics_full_and_cleaned,
  file.path(tables_dir, "demographics_full_and_cleaned.csv"), na = ""
)
readr::write_csv(
  demographics_by_analysis,
  file.path(tables_dir, "demographics_by_analysis.csv"), na = ""
)
readr::write_csv(
  clinical_instrument_descriptives,
  file.path(tables_dir, "clinical_instrument_descriptives_reliability.csv"), na = ""
)
readr::write_csv(
  trial_balance_summary, file.path(tables_dir, "trial_balance_summary.csv"), na = ""
)
readr::write_csv(
  sampling_balance_checks,
  file.path(tables_dir, "trial_sampling_randomisation_checks.csv"), na = ""
)
readr::write_csv(task_order_audit, file.path(tables_dir, "task_order_audit.csv"), na = "")
readr::write_csv(
  validation_checks, file.path(diagnostics_dir, "data_validation_checks.csv"), na = ""
)

validation_report <- c(
  "# Data Preparation and Validation",
  "",
  "The released participant-wide file was read without any private source data.",
  "The eight retained instruments were rescored from item responses and the 80",
  "emotion-recognition slots were reshaped to trial level.",
  "",
  "## Counts",
  "",
  paste0("- Participant rows: ", nrow(participants)),
  paste0("- Reconstructed trial rows: ", nrow(trials)),
  paste0("- Primary common-emotion accuracy trials: ",
         sum(trials$accuracy_included & trials$common_emotion)),
  paste0("- Primary correct-RT trials: ",
         sum(trials$rt_included & trials$common_emotion)),
  "",
  "## Checks",
  "",
  paste0("- ", validation_checks$check, ": PASS")
)
writeLines(validation_report, file.path(diagnostics_dir, "data_validation_report.md"))
capture.output(sessionInfo(), file = file.path(provenance_dir, "session_info_preparation.txt"))

log_message("Preparation completed successfully")
log_message("Participants: ", nrow(participants))
log_message("Trials: ", nrow(trials))

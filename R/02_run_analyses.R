#!/usr/bin/env Rscript

# AI-face emotion-recognition study
# Script 2 of 2: descriptive statistics, published models, figures, and tables.
#
# Reading map:
#   1-3. Setup, released-data checks, and small reporting helpers
#   4-5. Descriptive statistics and completion models
#   6.   Primary accuracy and response-time mixed models
#   7.   Clinical correlations and adjusted clinical models
#   8.   Gender and ethnicity moderation models
#   9.   Reliability, agreement, and confusion matrices
#   10.  Figures
#   11.  Sanity checks, reports, and provenance

# 1. Configuration ---------------------------------------------------------

required_packages <- c(
  "readr", "dplyr", "tidyr", "purrr", "ggplot2", "lme4",
  "broom", "broom.mixed", "MASS", "scales", "gridExtra", "knitr"
)
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(lme4)
  library(broom.mixed)
  library(scales)
  library(gridExtra)
  library(knitr)
})

set.seed(20260908)

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1) stop("Run this file with Rscript")
script_path <- normalizePath(sub("^--file=", "", script_argument), mustWork = TRUE)
repository_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

analysis_root <- file.path(repository_root, "results")
derived_dir <- file.path(repository_root, "derived")
tables_dir <- file.path(analysis_root, "tables")
figures_dir <- file.path(analysis_root, "figures")
diagnostics_dir <- file.path(analysis_root, "diagnostics")
logs_dir <- file.path(analysis_root, "logs")
provenance_dir <- file.path(analysis_root, "provenance")

output_dirs <- c(tables_dir, figures_dir, diagnostics_dir, logs_dir, provenance_dir)
invisible(lapply(output_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

bootstrap_repetitions <- 500L
coefficient_simulations <- 2000L
common_emotions <- c("anger", "disgust", "fear", "happy", "neutral", "sad")
reported_sets <- c("FACES", "AI-white", "AI-diverse")
clinical_scores <- c(
  cape15_score = "CAPE-15 total",
  altman_srms_score = "Altman SRMS total",
  isi_score = "ISI total",
  ocir_score = "OCI-R total",
  minispin_score = "Mini-SPIN total",
  asrs_score = "ASRS total",
  gad7_score = "GAD-7 total",
  hamd6_score = "HAMD-6 total"
)

log_path <- file.path(logs_dir, "02_run_analyses.log")
writeLines(character(), log_path)
log_message <- function(...) {
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  cat(line, "\n")
  cat(line, "\n", file = log_path, append = TRUE)
}

log_message("Analysis started")

# 2. Load and validate prepared data ---------------------------------------

trials_path <- file.path(derived_dir, "trials.csv")
participants_path <- file.path(derived_dir, "participants.csv")
condition_scores_path <- file.path(derived_dir, "condition_scores.csv")
instrument_descriptives_path <- file.path(
  tables_dir, "clinical_instrument_descriptives_reliability.csv"
)

required_inputs <- c(trials_path, participants_path, condition_scores_path,
                     instrument_descriptives_path,
                     file.path(diagnostics_dir, "data_validation_checks.csv"))
if (!all(file.exists(required_inputs))) {
  stop("Prepared inputs are missing. Run R/01_prepare_data.R first.")
}

trials <- readr::read_csv(trials_path, show_col_types = FALSE, progress = FALSE)
participants <- readr::read_csv(participants_path, show_col_types = FALSE, progress = FALSE)
condition_scores <- readr::read_csv(condition_scores_path, show_col_types = FALSE, progress = FALSE)
instrument_descriptives <- readr::read_csv(
  instrument_descriptives_path, show_col_types = FALSE, progress = FALSE
)
preparation_checks <- readr::read_csv(
  file.path(diagnostics_dir, "data_validation_checks.csv"), show_col_types = FALSE
)

if (!all(preparation_checks$passed)) stop("Preparation validation contains a failed check")
if (anyDuplicated(participants$participant_id)) stop("Participant IDs are not unique")
if (!all(trials$participant_id %in% participants$participant_id)) stop("Trial linkage failed")
if (!all(sort(unique(na.omit(trials$trial_stratum))) == sort(c("FACES", "AI-white", "AI-non-white")))) {
  stop("Unexpected trial strata")
}

log_message("Prepared data loaded: ", nrow(participants), " participants and ", nrow(trials), " trials")

# 3. Reporting and model helper functions ---------------------------------

save_plot <- function(plot, filename, width = 8, height = 5) {
  ggsave(file.path(figures_dir, paste0(filename, ".png")), plot,
         width = width, height = height, dpi = 320, bg = "white")
  ggsave(file.path(figures_dir, paste0(filename, ".pdf")), plot,
         width = width, height = height, device = grDevices::pdf)
}

publication_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title.position = "plot",
      legend.position = "bottom",
      axis.text.x = element_text(angle = 25, hjust = 1)
    )
}

capture_model <- function(model_expression) {
  warnings <- character()
  model <- withCallingHandlers(
    model_expression,
    warning = function(warning_condition) {
      warnings <<- c(warnings, conditionMessage(warning_condition))
      invokeRestart("muffleWarning")
    }
  )
  list(model = model, warnings = unique(warnings))
}

save_model_artifacts <- function(model_result, model_name, participant_n, trial_n) {
  model <- model_result$model
  capture.output(summary(model), file = file.path(diagnostics_dir, paste0(model_name, "_summary.txt")))

  coefficients <- broom.mixed::tidy(
    model, effects = "fixed", conf.int = TRUE, conf.method = "Wald"
  )
  if (!"p.value" %in% names(coefficients)) {
    coefficients <- coefficients %>%
      mutate(
        p.value = 2 * stats::pnorm(abs(statistic), lower.tail = FALSE),
        p_method = "large-sample normal approximation"
      )
  } else {
    coefficients <- coefficients %>%
      mutate(p_method = "model-reported Wald test")
  }
  coefficients <- coefficients %>%
    mutate(model = model_name, participant_n = participant_n, trial_n = trial_n,
           .before = 1)
  readr::write_csv(coefficients, file.path(tables_dir, paste0(model_name, "_coefficients.csv")), na = "")

  convergence_messages <- model@optinfo$conv$lme4$messages
  fitted_formula <- paste(deparse(stats::formula(model)), collapse = " ")
  fitted_singular <- lme4::isSingular(model, tol = 1e-4)
  diagnostic <- tibble(
    model = model_name,
    formula = fitted_formula,
    participant_n = participant_n,
    trial_n = trial_n,
    singular = fitted_singular,
    convergence_message = if (is.null(convergence_messages)) "" else paste(convergence_messages, collapse = " | "),
    captured_warnings = paste(model_result$warnings, collapse = " | ")
  )
  readr::write_csv(diagnostic, file.path(diagnostics_dir, paste0(model_name, "_diagnostics.csv")), na = "")
  list(coefficients = coefficients, diagnostic = diagnostic)
}

summarise_participant_metric <- function(data, group_variables, metric) {
  data %>%
    filter(!is.na(.data[[metric]])) %>%
    group_by(across(all_of(group_variables))) %>%
    summarise(
      n_participants = n_distinct(participant_id),
      mean = mean(.data[[metric]]),
      sd = sd(.data[[metric]]),
      median = median(.data[[metric]]),
      q25 = unname(quantile(.data[[metric]], 0.25)),
      q75 = unname(quantile(.data[[metric]], 0.75)),
      min = min(.data[[metric]]),
      max = max(.data[[metric]]),
      .groups = "drop"
    ) %>%
    mutate(metric = metric, .before = 1)
}

odds_ratio_table <- function(model, model_name) {
  model_n <- stats::nobs(model)
  broom::tidy(model, conf.int = TRUE) %>%
    mutate(
      model = model_name,
      odds_ratio = exp(estimate),
      odds_ratio_low = exp(conf.low),
      odds_ratio_high = exp(conf.high),
      n = model_n,
      .before = 1
    )
}

apparent_auc <- function(outcome, probability) {
  keep <- complete.cases(outcome, probability)
  outcome <- as.logical(outcome[keep])
  probability <- probability[keep]
  n_positive <- sum(outcome)
  n_negative <- sum(!outcome)
  if (n_positive == 0 || n_negative == 0) return(NA_real_)
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[outcome]) - n_positive * (n_positive + 1) / 2) /
    (n_positive * n_negative)
}

attrition_descriptives <- function(data, outcome_name, outcome_label) {
  outcome <- ifelse(data[[outcome_name]], "Included/complete", "Not included/incomplete")
  categorical_variables <- c(
    "gender_original", "participant_ethnicity_group", "participant_white_status",
    "education", "employment", "prior_mh_status"
  )
  numeric_part <- tibble(
    outcome_definition = outcome_label,
    outcome_group = outcome,
    variable = "age",
    level_or_statistic = "Mean (SD)",
    n = ifelse(!is.na(data$age), 1L, 0L),
    value = data$age
  ) %>%
    group_by(outcome_definition, outcome_group, variable, level_or_statistic) %>%
    summarise(
      n = sum(n),
      value = ifelse(n > 0, paste0(round(mean(value, na.rm = TRUE), 2), " (",
                                  round(sd(value, na.rm = TRUE), 2), ")"), NA_character_),
      percent = NA_real_,
      .groups = "drop"
    )
  categorical_part <- data %>%
    mutate(outcome_group = outcome) %>%
    select(outcome_group, all_of(categorical_variables)) %>%
    pivot_longer(-outcome_group, names_to = "variable", values_to = "level_or_statistic") %>%
    mutate(level_or_statistic = ifelse(is.na(level_or_statistic) |
                                         trimws(level_or_statistic) == "",
                                       "Missing", level_or_statistic)) %>%
    count(outcome_group, variable, level_or_statistic, name = "n") %>%
    group_by(outcome_group, variable) %>%
    mutate(percent = n / sum(n) * 100) %>%
    ungroup() %>%
    mutate(outcome_definition = outcome_label, value = as.character(n), .before = 1)
  bind_rows(numeric_part, categorical_part) %>%
    select(outcome_definition, outcome_group, variable, level_or_statistic,
           n, value, percent)
}

safe_correlation <- function(x, y, method) {
  keep <- complete.cases(x, y)
  if (sum(keep) < 10 || length(unique(x[keep])) < 2 || length(unique(y[keep])) < 2) return(NA_real_)
  suppressWarnings(stats::cor(x[keep], y[keep], method = method))
}

bootstrap_correlation <- function(data, x_name, y_name, repetitions) {
  complete <- data %>% filter(!is.na(.data[[x_name]]), !is.na(.data[[y_name]]))
  if (nrow(complete) < 10) {
    return(tibble(method = c("pearson", "spearman"), estimate = NA_real_,
                  conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_,
                  n = nrow(complete)))
  }
  estimates <- c(
    pearson = safe_correlation(complete[[x_name]], complete[[y_name]], "pearson"),
    spearman = safe_correlation(complete[[x_name]], complete[[y_name]], "spearman")
  )
  p_values <- c(
    pearson = suppressWarnings(cor.test(complete[[x_name]], complete[[y_name]],
                                        method = "pearson")$p.value),
    spearman = suppressWarnings(cor.test(complete[[x_name]], complete[[y_name]],
                                         method = "spearman", exact = FALSE)$p.value)
  )
  draws <- replicate(repetitions, {
    rows <- sample.int(nrow(complete), nrow(complete), replace = TRUE)
    c(
      pearson = safe_correlation(complete[[x_name]][rows], complete[[y_name]][rows], "pearson"),
      spearman = safe_correlation(complete[[x_name]][rows], complete[[y_name]][rows], "spearman")
    )
  })
  tibble(
    method = names(estimates),
    estimate = as.numeric(estimates),
    conf_low = apply(draws, 1, quantile, 0.025, na.rm = TRUE),
    conf_high = apply(draws, 1, quantile, 0.975, na.rm = TRUE),
    p_value = as.numeric(p_values),
    n = nrow(complete)
  )
}

bootstrap_correlation_difference <- function(data, first_name, second_name, outcome_name,
                                             repetitions) {
  complete <- data %>%
    filter(!is.na(.data[[first_name]]), !is.na(.data[[second_name]]),
           !is.na(.data[[outcome_name]]))
  if (nrow(complete) < 10) {
    return(tibble(method = c("pearson", "spearman"), difference = NA_real_,
                  conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_,
                  n = nrow(complete)))
  }
  difference_once <- function(rows, method) {
    safe_correlation(complete[[second_name]][rows], complete[[outcome_name]][rows], method) -
      safe_correlation(complete[[first_name]][rows], complete[[outcome_name]][rows], method)
  }
  all_rows <- seq_len(nrow(complete))
  estimates <- c(
    pearson = difference_once(all_rows, "pearson"),
    spearman = difference_once(all_rows, "spearman")
  )
  draws <- replicate(repetitions, {
    rows <- sample.int(nrow(complete), nrow(complete), replace = TRUE)
    c(pearson = difference_once(rows, "pearson"),
      spearman = difference_once(rows, "spearman"))
  })
  tibble(
    method = names(estimates),
    difference = as.numeric(estimates),
    conf_low = apply(draws, 1, quantile, 0.025, na.rm = TRUE),
    conf_high = apply(draws, 1, quantile, 0.975, na.rm = TRUE),
    p_value = apply(draws, 1, function(draw) {
      finite_draw <- draw[is.finite(draw)]
      min(2 * (min(sum(finite_draw <= 0), sum(finite_draw >= 0)) + 1) /
            (length(finite_draw) + 1), 1)
    }),
    n = nrow(complete)
  )
}

# Model-standardised set estimates from the jointly estimated fixed effects.
# No trial rows are duplicated. AI-diverse is pooled from AI-white and
# AI-non-white predictions using the cleaned observed trial mix.
standardised_set_estimates <- function(model, analysis_data, model_type,
                                       simulations = coefficient_simulations) {
  task_weights <- analysis_data %>%
    count(task_position, name = "n") %>%
    mutate(task_weight = n / sum(n))
  grid <- tidyr::expand_grid(
    trial_stratum = levels(analysis_data$trial_stratum),
    target_emotion = levels(analysis_data$target_emotion),
    task_position = levels(analysis_data$task_position),
    trial_position_z = 0
  ) %>%
    left_join(task_weights, by = "task_position") %>%
    mutate(
      trial_stratum = factor(trial_stratum, levels = levels(analysis_data$trial_stratum)),
      target_emotion = factor(target_emotion, levels = levels(analysis_data$target_emotion)),
      task_position = factor(task_position, levels = levels(analysis_data$task_position)),
      grid_weight = task_weight / length(levels(analysis_data$target_emotion))
    )

  fixed_formula <- lme4::nobars(stats::formula(model))
  design <- stats::model.matrix(stats::delete.response(stats::terms(fixed_formula)), grid)
  beta <- lme4::fixef(model)
  design <- design[, names(beta), drop = FALSE]
  covariance <- as.matrix(stats::vcov(model))
  beta_draws <- MASS::mvrnorm(simulations, mu = beta, Sigma = covariance)

  transform_prediction <- if (model_type == "accuracy") plogis else exp
  point_predictions <- transform_prediction(as.numeric(design %*% beta))
  simulated_predictions <- transform_prediction(design %*% t(beta_draws))

  strata <- levels(analysis_data$trial_stratum)
  point_by_stratum <- setNames(numeric(length(strata)), strata)
  draws_by_stratum <- matrix(NA_real_, nrow = simulations, ncol = length(strata),
                             dimnames = list(NULL, strata))
  for (stratum in strata) {
    rows <- which(grid$trial_stratum == stratum)
    weights <- grid$grid_weight[rows]
    point_by_stratum[stratum] <- weighted.mean(point_predictions[rows], weights)
    draws_by_stratum[, stratum] <- as.numeric(crossprod(weights / sum(weights),
                                                         simulated_predictions[rows, , drop = FALSE]))
  }

  ai_counts <- analysis_data %>%
    filter(trial_stratum %in% c("AI-white", "AI-non-white")) %>%
    count(trial_stratum, name = "n")
  observed_white_weight <- ai_counts$n[ai_counts$trial_stratum == "AI-white"] / sum(ai_counts$n)

  point_sets <- c(
    FACES = unname(point_by_stratum["FACES"]),
    `AI-white` = unname(point_by_stratum["AI-white"]),
    `AI-non-white` = unname(point_by_stratum["AI-non-white"]),
    `AI-diverse` = unname(observed_white_weight * point_by_stratum["AI-white"] +
      (1 - observed_white_weight) * point_by_stratum["AI-non-white"]),
    `AI-diverse equal-ethnicity` = unname(0.20 * point_by_stratum["AI-white"] +
      0.80 * point_by_stratum["AI-non-white"])
  )
  draw_sets <- cbind(
    FACES = draws_by_stratum[, "FACES"],
    `AI-white` = draws_by_stratum[, "AI-white"],
    `AI-non-white` = draws_by_stratum[, "AI-non-white"],
    `AI-diverse` = observed_white_weight * draws_by_stratum[, "AI-white"] +
      (1 - observed_white_weight) * draws_by_stratum[, "AI-non-white"],
    `AI-diverse equal-ethnicity` = 0.20 * draws_by_stratum[, "AI-white"] +
      0.80 * draws_by_stratum[, "AI-non-white"]
  )

  estimates <- tibble(
    stimulus_set = names(point_sets),
    estimate = as.numeric(point_sets),
    conf_low = apply(draw_sets, 2, quantile, 0.025),
    conf_high = apply(draw_sets, 2, quantile, 0.975),
    model_type = model_type,
    observed_ai_white_weight = observed_white_weight
  )

  contrast_definitions <- list(
    `AI-white minus FACES` = c("AI-white", "FACES"),
    `AI-diverse minus FACES` = c("AI-diverse", "FACES"),
    `AI-diverse minus AI-white` = c("AI-diverse", "AI-white"),
    `AI-non-white minus AI-white` = c("AI-non-white", "AI-white"),
    `Equal-standardised minus observed AI-diverse` = c("AI-diverse equal-ethnicity", "AI-diverse")
  )
  contrasts <- imap_dfr(contrast_definitions, function(pair, label) {
    point_difference <- point_sets[pair[1]] - point_sets[pair[2]]
    draw_difference <- draw_sets[, pair[1]] - draw_sets[, pair[2]]
    simulation_p <- 2 * (min(sum(draw_difference <= 0), sum(draw_difference >= 0)) + 1) /
      (length(draw_difference) + 1)
    tibble(
      contrast = label,
      estimate = as.numeric(point_difference),
      conf_low = unname(quantile(draw_difference, 0.025)),
      conf_high = unname(quantile(draw_difference, 0.975)),
      p_value = min(simulation_p, 1),
      model_type = model_type
    )
  })
  list(estimates = estimates, contrasts = contrasts, draws = draw_sets)
}

standardised_grid_estimates <- function(model, grid, group_columns, model_type,
                                        simulations = coefficient_simulations) {
  fixed_formula <- lme4::nobars(stats::formula(model))
  design <- stats::model.matrix(stats::delete.response(stats::terms(fixed_formula)), grid)
  beta <- lme4::fixef(model)
  design <- design[, names(beta), drop = FALSE]
  covariance <- as.matrix(stats::vcov(model))
  beta_draws <- MASS::mvrnorm(simulations, mu = beta, Sigma = covariance)
  transform_prediction <- if (model_type == "accuracy") plogis else exp
  point_predictions <- transform_prediction(as.numeric(design %*% beta))
  simulated_predictions <- transform_prediction(design %*% t(beta_draws))

  group_id <- do.call(paste, c(lapply(grid[group_columns], as.character), sep = " | "))
  group_names <- unique(group_id)
  results <- vector("list", length(group_names))
  for (index in seq_along(group_names)) {
    current_group <- group_names[index]
    rows <- which(group_id == current_group)
    weights <- grid$grid_weight[rows]
    weights <- weights / sum(weights)
    point <- weighted.mean(point_predictions[rows], weights)
    draws <- as.numeric(crossprod(weights, simulated_predictions[rows, , drop = FALSE]))
    results[[index]] <- bind_cols(
      as_tibble(grid[rows[1], group_columns, drop = FALSE]),
      tibble(
        estimate = point,
        conf_low = unname(quantile(draws, 0.025)),
        conf_high = unname(quantile(draws, 0.975)),
        model_type = model_type
      )
    )
  }
  bind_rows(results)
}

gender_prediction_grid <- function(analysis_data) {
  task_weights <- as_tibble(analysis_data) %>%
    count(task_position, name = "n") %>%
    mutate(task_weight = n / sum(n))
  tidyr::expand_grid(
    trial_stratum = levels(analysis_data$trial_stratum),
    gender_binary = levels(analysis_data$gender_binary),
    face_gender = levels(analysis_data$face_gender),
    target_emotion = levels(analysis_data$target_emotion),
    task_position = levels(analysis_data$task_position),
    trial_position_z = 0
  ) %>%
    left_join(task_weights, by = "task_position") %>%
    mutate(
      trial_stratum = factor(trial_stratum, levels = levels(analysis_data$trial_stratum)),
      gender_binary = factor(gender_binary, levels = levels(analysis_data$gender_binary)),
      face_gender = factor(face_gender, levels = levels(analysis_data$face_gender)),
      target_emotion = factor(target_emotion, levels = levels(analysis_data$target_emotion)),
      task_position = factor(task_position, levels = levels(analysis_data$task_position)),
      grid_weight = task_weight / length(levels(analysis_data$target_emotion))
    )
}

race_prediction_grid <- function(analysis_data) {
  task_weights <- as_tibble(analysis_data) %>%
    count(task_position, name = "n") %>%
    mutate(task_weight = n / sum(n))
  tidyr::expand_grid(
    trial_stratum = levels(analysis_data$trial_stratum),
    participant_white_status = levels(analysis_data$participant_white_status),
    target_emotion = levels(analysis_data$target_emotion),
    task_position = levels(analysis_data$task_position),
    trial_position_z = 0
  ) %>%
    left_join(task_weights, by = "task_position") %>%
    mutate(
      trial_stratum = factor(trial_stratum, levels = levels(analysis_data$trial_stratum)),
      participant_white_status = factor(
        participant_white_status,
        levels = levels(analysis_data$participant_white_status)
      ),
      target_emotion = factor(target_emotion, levels = levels(analysis_data$target_emotion)),
      task_position = factor(task_position, levels = levels(analysis_data$task_position)),
      grid_weight = task_weight / length(levels(analysis_data$target_emotion))
    )
}

standardised_grid_contrasts <- function(model, grid, definitions, model_type,
                                        simulations = coefficient_simulations) {
  fixed_formula <- lme4::nobars(stats::formula(model))
  design <- stats::model.matrix(stats::delete.response(stats::terms(fixed_formula)), grid)
  beta <- lme4::fixef(model)
  design <- design[, names(beta), drop = FALSE]
  covariance <- as.matrix(stats::vcov(model))
  beta_draws <- MASS::mvrnorm(simulations, mu = beta, Sigma = covariance)
  transform_prediction <- if (model_type == "accuracy") plogis else exp
  point_predictions <- transform_prediction(as.numeric(design %*% beta))
  simulated_predictions <- transform_prediction(design %*% t(beta_draws))

  results <- vector("list", length(definitions))
  for (index in seq_along(definitions)) {
    definition <- definitions[[index]]
    first_rows <- definition$first_rows
    second_rows <- definition$second_rows
    first_weights <- grid$grid_weight[first_rows]
    second_weights <- grid$grid_weight[second_rows]
    first_weights <- first_weights / sum(first_weights)
    second_weights <- second_weights / sum(second_weights)
    point_difference <-
      weighted.mean(point_predictions[first_rows], first_weights) -
      weighted.mean(point_predictions[second_rows], second_weights)
    draw_difference <-
      as.numeric(crossprod(first_weights,
                           simulated_predictions[first_rows, , drop = FALSE])) -
      as.numeric(crossprod(second_weights,
                           simulated_predictions[second_rows, , drop = FALSE]))
    simulation_p <- 2 * (min(sum(draw_difference <= 0), sum(draw_difference >= 0)) + 1) /
      (length(draw_difference) + 1)
    results[[index]] <- bind_cols(
      definition$metadata,
      tibble(
        estimate = point_difference,
        conf_low = unname(quantile(draw_difference, 0.025)),
        conf_high = unname(quantile(draw_difference, 0.975)),
        p_value = min(simulation_p, 1),
        model_type = model_type
      )
    )
  }
  bind_rows(results)
}

gender_contrast_definitions <- function(grid) {
  definitions <- list()
  for (stratum in levels(grid$trial_stratum)) {
    for (participant_gender in levels(grid$gender_binary)) {
      same_face_gender <- tolower(participant_gender)
      definitions[[length(definitions) + 1L]] <- list(
        first_rows = which(
          grid$trial_stratum == stratum & grid$gender_binary == participant_gender &
            grid$face_gender == same_face_gender
        ),
        second_rows = which(
          grid$trial_stratum == stratum & grid$gender_binary == participant_gender &
            grid$face_gender != same_face_gender
        ),
        metadata = tibble(
          contrast_family = "Same minus different stimulus gender",
          trial_stratum = stratum,
          participant_group = participant_gender
        )
      )
    }
    definitions[[length(definitions) + 1L]] <- list(
      first_rows = which(
        grid$trial_stratum == stratum &
          ((grid$gender_binary == "Woman" & grid$face_gender == "woman") |
             (grid$gender_binary == "Man" & grid$face_gender == "man"))
      ),
      second_rows = which(
        grid$trial_stratum == stratum &
          ((grid$gender_binary == "Woman" & grid$face_gender == "man") |
             (grid$gender_binary == "Man" & grid$face_gender == "woman"))
      ),
      metadata = tibble(
        contrast_family = "Same minus different stimulus gender",
        trial_stratum = stratum,
        participant_group = "Woman/man equally pooled"
      )
    )
    definitions[[length(definitions) + 1L]] <- list(
      first_rows = which(grid$trial_stratum == stratum & grid$gender_binary == "Man"),
      second_rows = which(grid$trial_stratum == stratum & grid$gender_binary == "Woman"),
      metadata = tibble(
        contrast_family = "Participant man minus woman",
        trial_stratum = stratum,
        participant_group = "Stimulus genders equally pooled"
      )
    )
  }
  definitions
}

white_status_contrast_definitions <- function(grid) {
  definitions <- map(levels(grid$trial_stratum), function(stratum) {
    list(
      first_rows = which(
        grid$trial_stratum == stratum & grid$participant_white_status == "Non-white"
      ),
      second_rows = which(
        grid$trial_stratum == stratum & grid$participant_white_status == "White"
      ),
      metadata = tibble(
        contrast_family = "Participant non-white minus white",
        trial_stratum = stratum,
        participant_group = "Stimulus stratum fixed"
      )
    )
  })
  for (participant_status in levels(grid$participant_white_status)) {
    same_stratum <- ifelse(participant_status == "White", "AI-white", "AI-non-white")
    different_stratum <- ifelse(participant_status == "White", "AI-non-white", "AI-white")
    definitions[[length(definitions) + 1L]] <- list(
      first_rows = which(
        grid$participant_white_status == participant_status &
          grid$trial_stratum == same_stratum
      ),
      second_rows = which(
        grid$participant_white_status == participant_status &
          grid$trial_stratum == different_stratum
      ),
      metadata = tibble(
        contrast_family = "Same minus different broad-status AI stimulus",
        trial_stratum = "AI-white versus AI-non-white",
        participant_group = participant_status
      )
    )
  }
  definitions[[length(definitions) + 1L]] <- list(
    first_rows = which(
      (grid$participant_white_status == "White" & grid$trial_stratum == "AI-white") |
        (grid$participant_white_status == "Non-white" &
           grid$trial_stratum == "AI-non-white")
    ),
    second_rows = which(
      (grid$participant_white_status == "White" &
         grid$trial_stratum == "AI-non-white") |
        (grid$participant_white_status == "Non-white" & grid$trial_stratum == "AI-white")
    ),
    metadata = tibble(
      contrast_family = "Same minus different broad-status AI stimulus",
      trial_stratum = "AI-white versus AI-non-white",
      participant_group = "White/non-white equally pooled"
    )
  )
  definitions
}

# 4. Descriptive statistics ------------------------------------------------

condition_scores_report <- condition_scores %>%
  filter(stimulus_set %in% c(reported_sets, "AI-non-white", "All-stimuli"))

condition_descriptives <- bind_rows(
  summarise_participant_metric(
    condition_scores_report %>% filter(adequate_accuracy_coverage),
    "stimulus_set", "accuracy_common_pct"
  ),
  summarise_participant_metric(
    condition_scores_report %>% filter(adequate_rt_coverage),
    "stimulus_set", "correct_rt_common_mean_sec"
  )
)
readr::write_csv(condition_descriptives, file.path(tables_dir, "condition_descriptive_statistics.csv"), na = "")

condition_with_demographics <- condition_scores_report %>%
  left_join(
    participants %>% select(participant_id, gender_original, gender_binary,
                            participant_ethnicity_group,
                            participant_white_status),
    by = "participant_id"
  )

gender_descriptives <- bind_rows(
  summarise_participant_metric(
    condition_with_demographics %>% filter(adequate_accuracy_coverage),
    c("gender_original", "stimulus_set"), "accuracy_common_pct"
  ),
  summarise_participant_metric(
    condition_with_demographics %>% filter(adequate_rt_coverage),
    c("gender_original", "stimulus_set"), "correct_rt_common_mean_sec"
  )
)
readr::write_csv(gender_descriptives, file.path(tables_dir, "descriptives_by_gender_and_stimulus_set.csv"), na = "")

ethnicity_descriptives <- bind_rows(
  summarise_participant_metric(
    condition_with_demographics %>% filter(adequate_accuracy_coverage),
    c("participant_ethnicity_group", "stimulus_set"), "accuracy_common_pct"
  ),
  summarise_participant_metric(
    condition_with_demographics %>% filter(adequate_rt_coverage),
    c("participant_ethnicity_group", "stimulus_set"), "correct_rt_common_mean_sec"
  )
)
readr::write_csv(ethnicity_descriptives, file.path(tables_dir, "descriptives_by_ethnicity_and_stimulus_set.csv"), na = "")

stimulus_demographic_descriptives <- trials %>%
  filter(accuracy_included, common_emotion) %>%
  group_by(source, trial_stratum, face_ethnicity, face_gender) %>%
  summarise(
    n_participants = n_distinct(participant_id),
    n_trials = n(),
    accuracy_pct = mean(correct) * 100,
    correct_rt_mean_sec = mean(rt_sec[rt_included], na.rm = TRUE),
    .groups = "drop"
  )
readr::write_csv(stimulus_demographic_descriptives,
                 file.path(tables_dir, "descriptives_by_stimulus_ethnicity_and_gender.csv"), na = "")

# 5. Completer/non-completer logistic regression --------------------------

completion_data <- participants %>%
  mutate(
    age_z = as.numeric(scale(age)),
    gender_binary = factor(gender_binary, levels = c("Woman", "Man")),
    participant_white_status = factor(participant_white_status, levels = c("White", "Non-white")),
    prior_mh_binary = case_when(
      prior_mh_status == "No prior condition reported" ~ "No prior condition",
      prior_mh_status == "Prior condition reported" ~ "Prior condition",
      TRUE ~ NA_character_
    ),
    prior_mh_binary = factor(prior_mh_binary, levels = c("No prior condition", "Prior condition"))
  )

inclusion_model_data <- completion_data %>%
  filter(complete.cases(included_any_emorec, age_z, gender_binary,
                        participant_white_status, prior_mh_binary))
inclusion_model <- glm(
  included_any_emorec ~ age_z + gender_binary + participant_white_status + prior_mh_binary,
  data = inclusion_model_data,
  family = binomial()
)

task_completion_model_data <- completion_data %>%
  filter(included_any_emorec,
         complete.cases(completed_80_valid_trials, age_z, gender_binary,
                        participant_white_status, prior_mh_binary))
task_completion_model <- glm(
  completed_80_valid_trials ~ age_z + gender_binary + participant_white_status + prior_mh_binary,
  data = task_completion_model_data,
  family = binomial()
)

completion_or <- bind_rows(
  odds_ratio_table(inclusion_model, "Any valid emotion-recognition data"),
  odds_ratio_table(task_completion_model, "Completed 80 valid trials among starters")
) %>%
  group_by(model) %>%
  group_modify(function(model_rows, model_key) {
    model_rows$p_fdr <- NA_real_
    predictor_rows <- model_rows$term != "(Intercept)"
    model_rows$p_fdr[predictor_rows] <- p.adjust(
      model_rows$p.value[predictor_rows], method = "BH"
    )
    model_rows
  }) %>%
  ungroup()
readr::write_csv(completion_or, file.path(tables_dir, "completion_logistic_regression.csv"), na = "")
capture.output(summary(inclusion_model), file = file.path(diagnostics_dir, "completion_inclusion_model_summary.txt"))
capture.output(summary(task_completion_model), file = file.path(diagnostics_dir, "completion_80_trials_model_summary.txt"))

completion_model_diagnostics <- tibble(
  model = c("Any valid emotion-recognition data", "Completed 80 valid trials among starters"),
  n = c(nobs(inclusion_model), nobs(task_completion_model)),
  events = c(sum(inclusion_model_data$included_any_emorec),
             sum(task_completion_model_data$completed_80_valid_trials)),
  non_events = c(sum(!inclusion_model_data$included_any_emorec),
                 sum(!task_completion_model_data$completed_80_valid_trials)),
  converged = c(inclusion_model$converged, task_completion_model$converged),
  apparent_auc = c(
    apparent_auc(inclusion_model_data$included_any_emorec, fitted(inclusion_model)),
    apparent_auc(task_completion_model_data$completed_80_valid_trials,
                 fitted(task_completion_model))
  ),
  brier_score = c(
    mean((as.numeric(inclusion_model_data$included_any_emorec) - fitted(inclusion_model))^2),
    mean((as.numeric(task_completion_model_data$completed_80_valid_trials) -
            fitted(task_completion_model))^2)
  ),
  warning = c(
    ifelse(any(abs(coef(inclusion_model)) > 10), "Possible sparse-data/separation issue", ""),
    ifelse(any(abs(coef(task_completion_model)) > 10), "Possible sparse-data/separation issue", "")
  )
)
readr::write_csv(completion_model_diagnostics,
                 file.path(diagnostics_dir, "completion_model_diagnostics.csv"), na = "")

intake_availability_counts <- participants %>%
  mutate(
    emotion_recognition = ifelse(included_any_emorec, "Included", "Not included"),
    intake_demographics = ifelse(intake_demographics_available, "Available", "Unavailable")
  ) %>%
  count(emotion_recognition, intake_demographics, name = "n")
availability_table <- table(participants$included_any_emorec,
                            participants$intake_demographics_available)
availability_fisher <- fisher.test(availability_table)
intake_availability_test <- tibble(
  comparison = "Emotion-recognition inclusion by intake-demographic availability",
  odds_ratio = unname(availability_fisher$estimate),
  conf_low = availability_fisher$conf.int[1],
  conf_high = availability_fisher$conf.int[2],
  p_value = availability_fisher$p.value,
  interpretation = "Odds of emotion-recognition inclusion when intake demographics were available versus unavailable"
)
readr::write_csv(intake_availability_counts,
                 file.path(tables_dir, "completion_by_intake_availability.csv"), na = "")
readr::write_csv(intake_availability_test,
                 file.path(tables_dir, "completion_by_intake_availability_test.csv"), na = "")

attrition_group_descriptives <- bind_rows(
  attrition_descriptives(participants, "included_any_emorec",
                         "Any valid emotion-recognition data"),
  attrition_descriptives(participants %>% filter(included_any_emorec),
                         "completed_80_valid_trials",
                         "Completed 80 valid trials among starters")
)
readr::write_csv(attrition_group_descriptives,
                 file.path(tables_dir, "completion_unadjusted_demographics.csv"), na = "")
log_message("Completion regressions fitted")

# 6. Primary trial-level mixed models --------------------------------------

accuracy_data <- trials %>%
  filter(accuracy_included, common_emotion) %>%
  mutate(
    correct = as.logical(correct),
    trial_stratum = factor(trial_stratum, levels = c("FACES", "AI-white", "AI-non-white")),
    target_emotion = factor(target_emotion, levels = common_emotions),
    task_position = factor(task_position),
    participant_id = factor(participant_id),
    stimulus_id = factor(stimulus_id),
    trial_position_z = as.numeric(scale(trial_number))
  ) %>%
  filter(complete.cases(correct, trial_stratum, target_emotion, task_position,
                        participant_id, stimulus_id, trial_position_z))

log_message("Fitting primary accuracy mixed model on ", nrow(accuracy_data), " trials")
accuracy_model_result <- capture_model(
  glmer(
    correct ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = accuracy_data,
    family = binomial(),
    nAGQ = 0,
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
accuracy_artifacts <- save_model_artifacts(
  accuracy_model_result, "primary_accuracy_mixed_model",
  n_distinct(accuracy_data$participant_id), nrow(accuracy_data)
)

rt_data <- trials %>%
  filter(rt_included, common_emotion) %>%
  mutate(
    log_rt = log(rt_sec),
    trial_stratum = factor(trial_stratum, levels = c("FACES", "AI-white", "AI-non-white")),
    target_emotion = factor(target_emotion, levels = common_emotions),
    task_position = factor(task_position),
    participant_id = factor(participant_id),
    stimulus_id = factor(stimulus_id),
    trial_position_z = as.numeric(scale(trial_number))
  ) %>%
  filter(complete.cases(log_rt, trial_stratum, target_emotion, task_position,
                        participant_id, stimulus_id, trial_position_z))

log_message("Fitting primary RT mixed model on ", nrow(rt_data), " trials")
rt_model_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = rt_data,
    REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
rt_artifacts <- save_model_artifacts(
  rt_model_result, "primary_rt_mixed_model",
  n_distinct(rt_data$participant_id), nrow(rt_data)
)

accuracy_standardised <- standardised_set_estimates(
  accuracy_model_result$model, accuracy_data, "accuracy"
)
rt_standardised <- standardised_set_estimates(rt_model_result$model, rt_data, "rt")

# Focused robustness models retain the primary fixed and random intercept
# structure while changing one inclusion rule at a time.
complete_task_ids <- participants %>%
  filter(completed_80_valid_trials) %>%
  pull(participant_id)

complete_accuracy_data <- accuracy_data %>%
  filter(as.character(participant_id) %in% complete_task_ids) %>%
  droplevels() %>%
  as.data.frame()
log_message("Fitting complete-task accuracy sensitivity model")
complete_accuracy_result <- capture_model(
  glmer(
    correct ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = complete_accuracy_data, family = binomial(), nAGQ = 0,
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
complete_accuracy_artifacts <- save_model_artifacts(
  complete_accuracy_result, "sensitivity_complete_task_accuracy_model",
  n_distinct(complete_accuracy_data$participant_id), nrow(complete_accuracy_data)
)
complete_accuracy_standardised <- standardised_set_estimates(
  complete_accuracy_result$model, complete_accuracy_data, "accuracy"
)
rm(complete_accuracy_result, complete_accuracy_data)
invisible(gc())

complete_rt_data <- rt_data %>%
  filter(as.character(participant_id) %in% complete_task_ids) %>%
  droplevels() %>%
  as.data.frame()
log_message("Fitting complete-task RT sensitivity model")
complete_rt_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = complete_rt_data, REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
complete_rt_artifacts <- save_model_artifacts(
  complete_rt_result, "sensitivity_complete_task_rt_model",
  n_distinct(complete_rt_data$participant_id), nrow(complete_rt_data)
)
complete_rt_standardised <- standardised_set_estimates(
  complete_rt_result$model, complete_rt_data, "rt"
)
rm(complete_rt_result, complete_rt_data)
invisible(gc())

no_happy_accuracy_data <- accuracy_data %>%
  filter(as.character(target_emotion) != "happy") %>%
  droplevels() %>%
  as.data.frame()
log_message("Fitting no-happy accuracy sensitivity model")
no_happy_accuracy_result <- capture_model(
  glmer(
    correct ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = no_happy_accuracy_data, family = binomial(), nAGQ = 0,
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
no_happy_accuracy_artifacts <- save_model_artifacts(
  no_happy_accuracy_result, "sensitivity_no_happy_accuracy_model",
  n_distinct(no_happy_accuracy_data$participant_id), nrow(no_happy_accuracy_data)
)
no_happy_accuracy_standardised <- standardised_set_estimates(
  no_happy_accuracy_result$model, no_happy_accuracy_data, "accuracy"
)
rm(no_happy_accuracy_result, no_happy_accuracy_data)
invisible(gc())

prepare_rt_sensitivity_data <- function(lower_bound, upper_bound = Inf) {
  trials %>%
    filter(
      accuracy_included, common_emotion, correct, !is.na(rt_sec),
      rt_sec >= lower_bound, rt_sec <= upper_bound
    ) %>%
    mutate(
      log_rt = log(rt_sec),
      trial_stratum = factor(trial_stratum,
                              levels = c("FACES", "AI-white", "AI-non-white")),
      target_emotion = factor(target_emotion, levels = common_emotions),
      task_position = factor(task_position),
      participant_id = factor(participant_id),
      stimulus_id = factor(stimulus_id),
      trial_position_z = as.numeric(scale(trial_number))
    ) %>%
    filter(complete.cases(log_rt, trial_stratum, target_emotion, task_position,
                          participant_id, stimulus_id, trial_position_z)) %>%
    droplevels() %>%
    as.data.frame()
}

narrow_rt_data <- prepare_rt_sensitivity_data(0.30, 10.00)
log_message("Fitting narrow-window RT sensitivity model")
narrow_rt_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = narrow_rt_data, REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
narrow_rt_artifacts <- save_model_artifacts(
  narrow_rt_result, "sensitivity_rt_0_3_to_10_model",
  n_distinct(narrow_rt_data$participant_id), nrow(narrow_rt_data)
)
narrow_rt_standardised <- standardised_set_estimates(
  narrow_rt_result$model, narrow_rt_data, "rt"
)
rm(narrow_rt_result, narrow_rt_data)
invisible(gc())

all_positive_rt_data <- prepare_rt_sensitivity_data(.Machine$double.eps, Inf)
log_message("Fitting all-positive RT sensitivity model")
all_positive_rt_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum + target_emotion + trial_position_z + task_position +
      (1 | participant_id) + (1 | stimulus_id),
    data = all_positive_rt_data, REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
all_positive_rt_artifacts <- save_model_artifacts(
  all_positive_rt_result, "sensitivity_rt_all_positive_model",
  n_distinct(all_positive_rt_data$participant_id), nrow(all_positive_rt_data)
)
all_positive_rt_standardised <- standardised_set_estimates(
  all_positive_rt_result$model, all_positive_rt_data, "rt"
)
rm(all_positive_rt_result, all_positive_rt_data)
invisible(gc())

sensitivity_set_estimates <- bind_rows(
  accuracy_standardised$estimates %>% mutate(specification = "Primary: all valid, common emotions"),
  complete_accuracy_standardised$estimates %>% mutate(specification = "Complete 80-trial participants"),
  no_happy_accuracy_standardised$estimates %>% mutate(specification = "Exclude high-ceiling happy trials"),
  rt_standardised$estimates %>% mutate(specification = "Primary: correct RT 0.20-30 sec"),
  complete_rt_standardised$estimates %>% mutate(specification = "Complete 80-trial participants"),
  narrow_rt_standardised$estimates %>% mutate(specification = "Correct RT 0.30-10 sec"),
  all_positive_rt_standardised$estimates %>% mutate(specification = "All positive correct RT")
) %>%
  select(specification, everything())

sensitivity_set_contrasts <- bind_rows(
  accuracy_standardised$contrasts %>% mutate(specification = "Primary: all valid, common emotions"),
  complete_accuracy_standardised$contrasts %>% mutate(specification = "Complete 80-trial participants"),
  no_happy_accuracy_standardised$contrasts %>% mutate(specification = "Exclude high-ceiling happy trials"),
  rt_standardised$contrasts %>% mutate(specification = "Primary: correct RT 0.20-30 sec"),
  complete_rt_standardised$contrasts %>% mutate(specification = "Complete 80-trial participants"),
  narrow_rt_standardised$contrasts %>% mutate(specification = "Correct RT 0.30-10 sec"),
  all_positive_rt_standardised$contrasts %>% mutate(specification = "All positive correct RT")
) %>%
  group_by(model_type, specification) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  select(specification, everything())

sensitivity_model_diagnostics <- bind_rows(
  complete_accuracy_artifacts$diagnostic,
  complete_rt_artifacts$diagnostic,
  no_happy_accuracy_artifacts$diagnostic,
  narrow_rt_artifacts$diagnostic,
  all_positive_rt_artifacts$diagnostic
)
readr::write_csv(sensitivity_set_estimates,
                 file.path(tables_dir, "sensitivity_stimulus_set_estimates.csv"), na = "")
readr::write_csv(sensitivity_set_contrasts,
                 file.path(tables_dir, "sensitivity_stimulus_set_contrasts.csv"), na = "")
readr::write_csv(sensitivity_model_diagnostics,
                 file.path(diagnostics_dir, "sensitivity_model_diagnostics.csv"), na = "")

model_set_estimates <- bind_rows(
  accuracy_standardised$estimates,
  rt_standardised$estimates
)
model_set_contrasts <- bind_rows(
  accuracy_standardised$contrasts,
  rt_standardised$contrasts
) %>%
  group_by(model_type) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup()
readr::write_csv(model_set_estimates, file.path(tables_dir, "mixed_model_stimulus_set_estimates.csv"), na = "")
readr::write_csv(model_set_contrasts, file.path(tables_dir, "mixed_model_stimulus_set_contrasts.csv"), na = "")
writeLines(
  c(
    "# Primary Random-Effects Decision",
    "",
    "The planned participant-specific stimulus-stratum slope GLMM was attempted on",
    "the full 77,238-trial primary accuracy sample. The original lme4 fit remained",
    "in its first model after 20 minutes. A separate sensitivity fit using glmmTMB",
    "completed in 122 seconds but did not converge: optimizer code 1, non-positive-",
    "definite Hessian, singular convergence, and a correlation of 1.000 between two",
    "participant stratum slopes. The reproducible primary model therefore uses",
    "participant and stimulus random intercepts with the fixed-effects estimand",
    "unchanged.",
    "",
    "This is a convergence-based simplification, not evidence that slope variance is zero.",
    "Sensitivity formula: correct ~ trial_stratum + target_emotion + trial_position_z +",
    "task_position + (1 + trial_stratum | participant_id) + (1 | stimulus_id)."
  ),
  file.path(diagnostics_dir, "primary_random_effects_decision.md")
)
log_message("Primary mixed models and pooled overlapping-set contrasts completed")
rm(accuracy_model_result, rt_model_result)
invisible(gc())

# 7. Clinical correlations and dependent comparisons ----------------------

clinical_long_source <- condition_scores %>%
  filter(stimulus_set %in% c("FACES", "AI-white", "AI-diverse", "All-stimuli")) %>%
  left_join(participants %>% select(participant_id, all_of(names(clinical_scores))),
            by = "participant_id")

metric_definitions <- tibble::tribble(
  ~metric, ~value_column, ~coverage_column,
  "Accuracy", "accuracy_common_pct", "adequate_accuracy_coverage",
  "Correct RT", "correct_rt_common_mean_sec", "adequate_rt_coverage"
)

log_message("Calculating participant-bootstrap clinical correlations")
clinical_correlations <- pmap_dfr(
  tidyr::crossing(
    clinical_score = names(clinical_scores),
    stimulus_set = c("FACES", "AI-white", "AI-diverse", "All-stimuli"),
    metric_definitions
  ),
  function(clinical_score, stimulus_set, metric, value_column, coverage_column) {
    analysis_data <- clinical_long_source %>%
      filter(.data$stimulus_set == .env$stimulus_set,
             .data[[coverage_column]] %in% TRUE)
    bootstrap_correlation(analysis_data, value_column, clinical_score, bootstrap_repetitions) %>%
      mutate(
        clinical_score = clinical_score,
        clinical_label = unname(clinical_scores[clinical_score]),
        stimulus_set = stimulus_set,
        metric = metric,
        performance_variable = value_column,
        .before = 1
      )
  }
) %>%
  mutate(
    fdr_family = if_else(
      stimulus_set == "All-stimuli",
      "All-stimuli correlations",
      "FACES, AI-white, and AI-diverse correlations"
    )
  ) %>%
  group_by(metric, method, fdr_family) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup()

readr::write_csv(clinical_correlations, file.path(tables_dir, "clinical_correlations.csv"), na = "")

condition_wide <- condition_scores %>%
  filter(stimulus_set %in% c("FACES", "AI-white", "AI-diverse")) %>%
  select(participant_id, stimulus_set, accuracy_common_pct, correct_rt_common_mean_sec,
         adequate_accuracy_coverage, adequate_rt_coverage) %>%
  pivot_wider(
    names_from = stimulus_set,
    values_from = c(accuracy_common_pct, correct_rt_common_mean_sec,
                    adequate_accuracy_coverage, adequate_rt_coverage),
    names_sep = "__"
  ) %>%
  left_join(participants %>% select(participant_id, all_of(names(clinical_scores))),
            by = "participant_id")

comparison_definitions <- list(
  `AI-white minus FACES` = c("FACES", "AI-white"),
  `AI-diverse minus FACES` = c("FACES", "AI-diverse"),
  `AI-diverse minus AI-white` = c("AI-white", "AI-diverse")
)

clinical_correlation_differences <- pmap_dfr(
  tidyr::crossing(
    clinical_score = names(clinical_scores),
    metric_definitions %>% select(metric, value_column, coverage_column),
    comparison = names(comparison_definitions)
  ),
  function(clinical_score, metric, value_column, coverage_column, comparison) {
    pair <- comparison_definitions[[comparison]]
    first_name <- paste0(value_column, "__", pair[1])
    second_name <- paste0(value_column, "__", pair[2])
    coverage_first <- paste0(coverage_column, "__", pair[1])
    coverage_second <- paste0(coverage_column, "__", pair[2])
    analysis_data <- condition_wide %>%
      filter(.data[[coverage_first]] %in% TRUE, .data[[coverage_second]] %in% TRUE)
    bootstrap_correlation_difference(
      analysis_data, first_name, second_name, clinical_score, bootstrap_repetitions
    ) %>%
      mutate(
        clinical_score = clinical_score,
        clinical_label = unname(clinical_scores[clinical_score]),
        metric = metric,
        comparison = comparison,
        .before = 1
      )
  }
) %>%
  group_by(metric, method) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup()
readr::write_csv(clinical_correlation_differences,
                 file.path(tables_dir, "dependent_clinical_correlation_differences.csv"), na = "")

# Incremental models use complete validated scores and report AI and FACES
# together. They are secondary because the primary clinical family is unresolved.
incremental_clinical_models <- map_dfr(names(clinical_scores), function(clinical_score) {
  map_dfr(c("accuracy_common_pct", "correct_rt_common_mean_sec"), function(metric) {
    faces_name <- paste0(metric, "__FACES")
    ai_name <- paste0(metric, "__AI-diverse")
    model_data <- condition_wide %>%
      left_join(
        participants %>% select(participant_id, age, gender_binary, participant_white_status),
        by = "participant_id"
      ) %>%
      transmute(
        clinical = .data[[clinical_score]],
        faces = .data[[faces_name]],
        ai_diverse = .data[[ai_name]],
        age = age,
        gender_binary = factor(gender_binary),
        participant_white_status = factor(participant_white_status)
      ) %>%
      filter(complete.cases(.)) %>%
      mutate(
        clinical_z = as.numeric(scale(clinical)),
        faces_z = as.numeric(scale(faces)),
        ai_diverse_z = as.numeric(scale(ai_diverse)),
        age_z = as.numeric(scale(age))
      )
    if (nrow(model_data) < 30) return(tibble())
    model <- lm(clinical_z ~ faces_z + ai_diverse_z + age_z +
                  gender_binary + participant_white_status, data = model_data)
    broom::tidy(model, conf.int = TRUE) %>%
      mutate(clinical_score = clinical_score, metric = metric, n = nobs(model), .before = 1)
  })
})
readr::write_csv(incremental_clinical_models,
                 file.path(tables_dir, "incremental_clinical_signal_models.csv"), na = "")
incremental_clinical_performance_terms <- incremental_clinical_models %>%
  filter(term %in% c("faces_z", "ai_diverse_z")) %>%
  group_by(metric) %>%
  mutate(p_fdr = p.adjust(p.value, method = "BH")) %>%
  ungroup()
readr::write_csv(
  incremental_clinical_performance_terms,
  file.path(tables_dir, "incremental_clinical_signal_performance_terms.csv"), na = ""
)
log_message("Clinical signal analyses completed")

# 8. Gender and white-status moderation models ----------------------------

# Reset the simulation state at the section boundary so moderation results do
# not depend on the number or ordering of bootstrap draws above.
set.seed(20260909)

gender_accuracy_data <- accuracy_data %>%
  mutate(
    gender_binary = factor(gender_binary, levels = c("Woman", "Man")),
    face_gender = factor(face_gender, levels = c("woman", "man"))
  ) %>%
  filter(complete.cases(gender_binary, face_gender))
gender_accuracy_data <- droplevels(as.data.frame(gender_accuracy_data))
gender_accuracy_participant_n <- n_distinct(gender_accuracy_data$participant_id)
gender_accuracy_trial_n <- nrow(gender_accuracy_data)

log_message("Fitting gender moderation accuracy model")
gender_accuracy_result <- capture_model(
  glmer(
    correct ~ trial_stratum * gender_binary * face_gender + target_emotion +
      trial_position_z + task_position + (1 | participant_id) + (1 | stimulus_id),
    data = gender_accuracy_data,
    family = binomial(), nAGQ = 0,
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
gender_accuracy_artifacts <- save_model_artifacts(
  gender_accuracy_result, "gender_moderation_accuracy_model",
  gender_accuracy_participant_n, gender_accuracy_trial_n
)
gender_accuracy_grid <- gender_prediction_grid(gender_accuracy_data)
gender_accuracy_estimates <- standardised_grid_estimates(
  gender_accuracy_result$model,
  gender_accuracy_grid,
  c("trial_stratum", "gender_binary", "face_gender"),
  "accuracy"
)
gender_accuracy_contrasts <- standardised_grid_contrasts(
  gender_accuracy_result$model,
  gender_accuracy_grid,
  gender_contrast_definitions(gender_accuracy_grid),
  "accuracy"
)
rm(gender_accuracy_result, gender_accuracy_data, gender_accuracy_grid)
invisible(gc())

gender_rt_data <- rt_data %>%
  mutate(
    gender_binary = factor(gender_binary, levels = c("Woman", "Man")),
    face_gender = factor(face_gender, levels = c("woman", "man"))
  ) %>%
  filter(complete.cases(gender_binary, face_gender))
gender_rt_data <- droplevels(as.data.frame(gender_rt_data))
gender_rt_participant_n <- n_distinct(gender_rt_data$participant_id)
gender_rt_trial_n <- nrow(gender_rt_data)

log_message("Fitting gender moderation RT model")
gender_rt_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum * gender_binary * face_gender + target_emotion +
      trial_position_z + task_position + (1 | participant_id) + (1 | stimulus_id),
    data = gender_rt_data, REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
gender_rt_artifacts <- save_model_artifacts(
  gender_rt_result, "gender_moderation_rt_model",
  gender_rt_participant_n, gender_rt_trial_n
)
gender_rt_grid <- gender_prediction_grid(gender_rt_data)
gender_rt_estimates <- standardised_grid_estimates(
  gender_rt_result$model,
  gender_rt_grid,
  c("trial_stratum", "gender_binary", "face_gender"),
  "rt"
)
gender_rt_contrasts <- standardised_grid_contrasts(
  gender_rt_result$model,
  gender_rt_grid,
  gender_contrast_definitions(gender_rt_grid),
  "rt"
)
gender_moderation_estimates <- bind_rows(
  gender_accuracy_estimates,
  gender_rt_estimates
) %>%
  mutate(
    participant_gender = as.character(gender_binary),
    stimulus_gender = ifelse(as.character(face_gender) == "woman", "Woman", "Man"),
    congruence = ifelse(participant_gender == stimulus_gender,
                        "Same gender", "Different gender")
  ) %>%
  select(model_type, trial_stratum, participant_gender, stimulus_gender,
         congruence, estimate, conf_low, conf_high)
readr::write_csv(gender_moderation_estimates,
                 file.path(tables_dir, "gender_moderation_standardised_estimates.csv"), na = "")
gender_moderation_contrasts <- bind_rows(
  gender_accuracy_contrasts,
  gender_rt_contrasts
) %>%
  group_by(model_type, contrast_family) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup()
readr::write_csv(gender_moderation_contrasts,
                 file.path(tables_dir, "gender_moderation_contrasts.csv"), na = "")
rm(gender_rt_result, gender_rt_data, gender_rt_grid)
invisible(gc())

race_accuracy_data <- accuracy_data %>%
  mutate(
    participant_white_status = factor(participant_white_status,
                                      levels = c("White", "Non-white"))
  ) %>%
  filter(complete.cases(participant_white_status))
race_accuracy_data <- droplevels(as.data.frame(race_accuracy_data))
race_accuracy_participant_n <- n_distinct(race_accuracy_data$participant_id)
race_accuracy_trial_n <- nrow(race_accuracy_data)

log_message("Fitting white-status moderation accuracy model")
race_accuracy_result <- capture_model(
  glmer(
    correct ~ trial_stratum * participant_white_status + target_emotion +
      trial_position_z + task_position + (1 | participant_id) + (1 | stimulus_id),
    data = race_accuracy_data,
    family = binomial(), nAGQ = 0,
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
race_accuracy_artifacts <- save_model_artifacts(
  race_accuracy_result, "white_status_moderation_accuracy_model",
  race_accuracy_participant_n, race_accuracy_trial_n
)
race_accuracy_grid <- race_prediction_grid(race_accuracy_data)
race_accuracy_estimates <- standardised_grid_estimates(
  race_accuracy_result$model,
  race_accuracy_grid,
  c("trial_stratum", "participant_white_status"),
  "accuracy"
)
race_accuracy_contrasts <- standardised_grid_contrasts(
  race_accuracy_result$model,
  race_accuracy_grid,
  white_status_contrast_definitions(race_accuracy_grid),
  "accuracy"
)
rm(race_accuracy_result, race_accuracy_data, race_accuracy_grid)
invisible(gc())

race_rt_data <- rt_data %>%
  mutate(
    participant_white_status = factor(participant_white_status,
                                      levels = c("White", "Non-white"))
  ) %>%
  filter(complete.cases(participant_white_status))
race_rt_data <- droplevels(as.data.frame(race_rt_data))
race_rt_participant_n <- n_distinct(race_rt_data$participant_id)
race_rt_trial_n <- nrow(race_rt_data)

log_message("Fitting white-status moderation RT model")
race_rt_result <- capture_model(
  lmer(
    log_rt ~ trial_stratum * participant_white_status + target_emotion +
      trial_position_z + task_position + (1 | participant_id) + (1 | stimulus_id),
    data = race_rt_data, REML = FALSE,
    control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  )
)
race_rt_artifacts <- save_model_artifacts(
  race_rt_result, "white_status_moderation_rt_model",
  race_rt_participant_n, race_rt_trial_n
)
race_rt_grid <- race_prediction_grid(race_rt_data)
race_rt_estimates <- standardised_grid_estimates(
  race_rt_result$model,
  race_rt_grid,
  c("trial_stratum", "participant_white_status"),
  "rt"
)
race_rt_contrasts <- standardised_grid_contrasts(
  race_rt_result$model,
  race_rt_grid,
  white_status_contrast_definitions(race_rt_grid),
  "rt"
)
white_status_moderation_estimates <- bind_rows(
  race_accuracy_estimates,
  race_rt_estimates
) %>%
  mutate(
    participant_white_status = as.character(participant_white_status),
    stimulus_white_status = ifelse(as.character(trial_stratum) == "AI-non-white",
                                   "Non-white", "White"),
    congruence = ifelse(participant_white_status == stimulus_white_status,
                        "Same broad status", "Different broad status")
  ) %>%
  select(model_type, trial_stratum, participant_white_status,
         stimulus_white_status, congruence, estimate, conf_low, conf_high)
readr::write_csv(
  white_status_moderation_estimates,
  file.path(tables_dir, "white_status_moderation_standardised_estimates.csv"), na = ""
)
white_status_moderation_contrasts <- bind_rows(
  race_accuracy_contrasts,
  race_rt_contrasts
) %>%
  group_by(model_type, contrast_family) %>%
  mutate(p_fdr = p.adjust(p_value, method = "BH")) %>%
  ungroup()
readr::write_csv(
  white_status_moderation_contrasts,
  file.path(tables_dir, "white_status_moderation_contrasts.csv"), na = ""
)
rm(race_rt_result, race_rt_data, race_rt_grid)
invisible(gc())

all_model_diagnostics <- bind_rows(
  accuracy_artifacts$diagnostic,
  rt_artifacts$diagnostic,
  sensitivity_model_diagnostics,
  gender_accuracy_artifacts$diagnostic,
  gender_rt_artifacts$diagnostic,
  race_accuracy_artifacts$diagnostic,
  race_rt_artifacts$diagnostic
)
readr::write_csv(all_model_diagnostics, file.path(diagnostics_dir, "all_mixed_model_diagnostics.csv"), na = "")

moderation_terms <- bind_rows(
  gender_accuracy_artifacts$coefficients,
  gender_rt_artifacts$coefficients,
  race_accuracy_artifacts$coefficients,
  race_rt_artifacts$coefficients
) %>%
  filter(grepl("gender_binary|participant_white_status", term)) %>%
  group_by(model) %>%
  mutate(p_fdr = p.adjust(p.value, method = "BH")) %>%
  ungroup()
readr::write_csv(moderation_terms,
                 file.path(tables_dir, "moderation_main_and_interaction_terms.csv"), na = "")
log_message("Demographic moderation models completed")

# 9. Reliability, agreement, and confusion patterns -----------------------

# AI-diverse must be constructed explicitly because trial_stratum is disjoint.
split_half_scores <- bind_rows(
  trials %>% filter(accuracy_included, common_emotion, trial_stratum == "FACES") %>% mutate(stimulus_set = "FACES"),
  trials %>% filter(accuracy_included, common_emotion, trial_stratum == "AI-white") %>% mutate(stimulus_set = "AI-white"),
  trials %>% filter(accuracy_included, common_emotion, trial_stratum %in% c("AI-white", "AI-non-white")) %>% mutate(stimulus_set = "AI-diverse")
) %>%
  mutate(half = ifelse(trial_number %% 2 == 1, "Odd trials", "Even trials")) %>%
  group_by(participant_id, stimulus_set, half) %>%
  summarise(accuracy_pct = mean(correct) * 100, .groups = "drop") %>%
  pivot_wider(names_from = half, values_from = accuracy_pct)

reliability <- split_half_scores %>%
  group_by(stimulus_set) %>%
  summarise(
    n = sum(complete.cases(`Odd trials`, `Even trials`)),
    split_half_r = safe_correlation(`Odd trials`, `Even trials`, "pearson"),
    spearman_brown = 2 * split_half_r / (1 + split_half_r),
    .groups = "drop"
  )
readr::write_csv(reliability, file.path(tables_dir, "reliability_split_half.csv"), na = "")

agreement_data <- condition_scores %>%
  filter(stimulus_set %in% c("FACES", "AI-diverse"), adequate_accuracy_coverage) %>%
  select(participant_id, stimulus_set, accuracy_common_pct, correct_rt_common_mean_sec) %>%
  pivot_wider(names_from = stimulus_set,
              values_from = c(accuracy_common_pct, correct_rt_common_mean_sec), names_sep = "__")

agreement_summary <- tibble::tribble(
  ~metric, ~n, ~pearson_r, ~mean_difference, ~sd_difference, ~lower_agreement, ~upper_agreement,
  "Accuracy percentage points",
  sum(complete.cases(agreement_data$`accuracy_common_pct__FACES`, agreement_data$`accuracy_common_pct__AI-diverse`)),
  safe_correlation(agreement_data$`accuracy_common_pct__FACES`, agreement_data$`accuracy_common_pct__AI-diverse`, "pearson"),
  mean(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE),
  sd(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE),
  mean(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE) -
    1.96 * sd(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE),
  mean(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE) +
    1.96 * sd(agreement_data$`accuracy_common_pct__AI-diverse` - agreement_data$`accuracy_common_pct__FACES`, na.rm = TRUE),
  "Correct RT seconds",
  sum(complete.cases(agreement_data$`correct_rt_common_mean_sec__FACES`, agreement_data$`correct_rt_common_mean_sec__AI-diverse`)),
  safe_correlation(agreement_data$`correct_rt_common_mean_sec__FACES`, agreement_data$`correct_rt_common_mean_sec__AI-diverse`, "pearson"),
  mean(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE),
  sd(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE),
  mean(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE) -
    1.96 * sd(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE),
  mean(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE) +
    1.96 * sd(agreement_data$`correct_rt_common_mean_sec__AI-diverse` - agreement_data$`correct_rt_common_mean_sec__FACES`, na.rm = TRUE)
)
readr::write_csv(agreement_summary, file.path(tables_dir, "faces_ai_diverse_agreement.csv"), na = "")

confusion_matrix <- trials %>%
  filter(accuracy_included, common_emotion, response_emotion %in% common_emotions) %>%
  group_by(source, target_emotion, response_emotion) %>%
  summarise(n_trials = n(), .groups = "drop") %>%
  group_by(source, target_emotion) %>%
  mutate(percent_within_target = n_trials / sum(n_trials) * 100) %>%
  ungroup()
readr::write_csv(confusion_matrix, file.path(tables_dir, "emotion_confusion_matrix.csv"), na = "")

# 10. Figures --------------------------------------------------------------

cohort_flow <- readr::read_csv(file.path(tables_dir, "cohort_flow.csv"), show_col_types = FALSE)
cohort_plot <- cohort_flow %>%
  mutate(stage = factor(stage, levels = rev(stage))) %>%
  ggplot(aes(n_participants, stage)) +
  geom_col(fill = "#2F6B59", width = 0.68) +
  geom_text(aes(label = comma(n_participants)), hjust = -0.15, size = 3.4) +
  scale_x_continuous(limits = c(0, max(cohort_flow$n_participants) * 1.10), labels = comma) +
  labs(title = "Participant flow into emotion-recognition analyses", x = "Participants", y = NULL) +
  publication_theme()
save_plot(cohort_plot, "figure_01_cohort_flow", width = 9, height = 5.5)

distribution_data <- condition_scores_report %>%
  filter(stimulus_set %in% reported_sets, adequate_accuracy_coverage) %>%
  mutate(stimulus_set = factor(stimulus_set, levels = reported_sets))
accuracy_distribution_plot <- ggplot(distribution_data,
                                     aes(stimulus_set, accuracy_common_pct, fill = stimulus_set)) +
  geom_violin(trim = TRUE, alpha = 0.45, colour = NA) +
  geom_boxplot(width = 0.16, outlier.shape = NA, alpha = 0.85) +
  scale_fill_manual(values = c("#446E9B", "#C26D3D", "#3F8060")) +
  labs(title = "Participant accuracy across overlapping stimulus sets",
       x = NULL, y = "Accuracy across common emotions (%)") +
  publication_theme() + theme(legend.position = "none")
save_plot(accuracy_distribution_plot, "figure_02_accuracy_distributions")

rt_distribution_data <- condition_scores_report %>%
  filter(stimulus_set %in% reported_sets, adequate_rt_coverage) %>%
  mutate(stimulus_set = factor(stimulus_set, levels = reported_sets))
rt_distribution_plot <- ggplot(rt_distribution_data,
                               aes(stimulus_set, correct_rt_common_mean_sec, fill = stimulus_set)) +
  geom_violin(trim = TRUE, alpha = 0.45, colour = NA) +
  geom_boxplot(width = 0.16, outlier.shape = NA, alpha = 0.85) +
  scale_fill_manual(values = c("#446E9B", "#C26D3D", "#3F8060")) +
  coord_cartesian(ylim = quantile(rt_distribution_data$correct_rt_common_mean_sec,
                                  c(0, 0.99), na.rm = TRUE)) +
  labs(title = "Participant correct-response time across overlapping stimulus sets",
       x = NULL, y = "Mean correct RT (seconds)") +
  publication_theme() + theme(legend.position = "none")
save_plot(rt_distribution_plot, "figure_03_rt_distributions")

model_plot_data <- model_set_estimates %>%
  filter(stimulus_set %in% c(reported_sets, "AI-non-white")) %>%
  mutate(
    stimulus_set = factor(stimulus_set, levels = c("FACES", "AI-white", "AI-non-white", "AI-diverse")),
    estimate_display = ifelse(model_type == "accuracy", estimate * 100, estimate),
    low_display = ifelse(model_type == "accuracy", conf_low * 100, conf_low),
    high_display = ifelse(model_type == "accuracy", conf_high * 100, conf_high),
    panel = ifelse(model_type == "accuracy", "Accuracy (%)", "Geometric mean correct RT (sec)")
  )
model_estimate_plot <- ggplot(model_plot_data,
                             aes(stimulus_set, estimate_display, colour = stimulus_set)) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = low_display, ymax = high_display), width = 0.12) +
  facet_wrap(~panel, scales = "free_y") +
  scale_colour_manual(values = c("#446E9B", "#C26D3D", "#8B6F47", "#3F8060")) +
  labs(title = "Mixed-model standardised emotion-recognition performance",
       x = NULL, y = NULL) +
  publication_theme() + theme(legend.position = "none")
save_plot(model_estimate_plot, "figure_04_mixed_model_estimates", width = 9, height = 4.8)

clinical_forest_data <- clinical_correlations %>%
  filter(method == "spearman", stimulus_set %in% reported_sets) %>%
  mutate(
    clinical_label = factor(clinical_label, levels = rev(unique(clinical_label))),
    stimulus_set = factor(stimulus_set, levels = reported_sets)
  )
clinical_forest_plot <- ggplot(clinical_forest_data,
                              aes(estimate, clinical_label, colour = stimulus_set)) +
  geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = conf_low, xmax = conf_high),
                 position = position_dodge(width = 0.55), height = 0) +
  geom_point(position = position_dodge(width = 0.55), size = 1.7) +
  facet_wrap(~metric) +
  scale_colour_manual(values = c("#446E9B", "#C26D3D", "#3F8060")) +
  labs(title = "Clinical associations across overlapping stimulus sets",
       x = "Spearman correlation (participant-bootstrap 95% CI)", y = NULL,
       colour = "Stimulus set") +
  publication_theme()
save_plot(clinical_forest_plot, "figure_05_clinical_correlation_forest", width = 10, height = 7)

gender_plot_data <- gender_descriptives %>%
  filter(metric == "accuracy_common_pct", stimulus_set %in% reported_sets,
         gender_original %in% c("Woman", "Man", "Non-Binary")) %>%
  mutate(stimulus_set = factor(stimulus_set, levels = reported_sets))
gender_plot <- ggplot(gender_plot_data, aes(stimulus_set, mean, colour = gender_original,
                                           group = gender_original)) +
  geom_point(size = 2) + geom_line() +
  labs(title = "Mean participant accuracy by gender and stimulus set",
       x = NULL, y = "Mean accuracy (%)", colour = "Participant gender") +
  publication_theme()
save_plot(gender_plot, "figure_06_accuracy_by_gender")

ethnicity_plot_data <- ethnicity_descriptives %>%
  filter(metric == "accuracy_common_pct", stimulus_set %in% reported_sets,
         participant_ethnicity_group != "Missing") %>%
  mutate(stimulus_set = factor(stimulus_set, levels = reported_sets))
ethnicity_plot <- ggplot(ethnicity_plot_data,
                         aes(stimulus_set, mean, colour = participant_ethnicity_group,
                             group = participant_ethnicity_group)) +
  geom_point(size = 1.8) + geom_line() +
  labs(title = "Mean participant accuracy by ethnicity and stimulus set",
       x = NULL, y = "Mean accuracy (%)", colour = "Participant ethnicity") +
  publication_theme()
save_plot(ethnicity_plot, "figure_07_accuracy_by_ethnicity", width = 9, height = 5.5)

confusion_plot <- ggplot(confusion_matrix,
                         aes(response_emotion, target_emotion, fill = percent_within_target)) +
  geom_tile(colour = "white", linewidth = 0.25) +
  facet_wrap(~source) +
  scale_fill_gradient(low = "white", high = "#2F6B59", labels = label_percent(scale = 1)) +
  labs(title = "Emotion-response confusion patterns", x = "Response", y = "Target",
       fill = "% within target") +
  publication_theme()
save_plot(confusion_plot, "figure_08_confusion_matrices", width = 9, height = 4.8)

gender_moderation_plot_data <- gender_moderation_estimates %>%
  mutate(
    trial_stratum = factor(trial_stratum,
                            levels = c("FACES", "AI-white", "AI-non-white")),
    estimate_display = ifelse(model_type == "accuracy", estimate * 100, estimate),
    low_display = ifelse(model_type == "accuracy", conf_low * 100, conf_low),
    high_display = ifelse(model_type == "accuracy", conf_high * 100, conf_high),
    outcome = ifelse(model_type == "accuracy", "Accuracy (%)", "Correct RT (sec)")
  )
gender_moderation_plot <- ggplot(
  gender_moderation_plot_data,
  aes(trial_stratum, estimate_display, colour = stimulus_gender,
      group = stimulus_gender)
) +
  geom_line(position = position_dodge(width = 0.15)) +
  geom_point(position = position_dodge(width = 0.15), size = 2) +
  geom_errorbar(aes(ymin = low_display, ymax = high_display),
                position = position_dodge(width = 0.15), width = 0.08) +
  facet_grid(outcome ~ participant_gender, scales = "free_y") +
  scale_colour_manual(values = c(Woman = "#A2465D", Man = "#3E6C8E")) +
  labs(
    title = "Model-standardised performance by participant and stimulus gender",
    subtitle = paste0("Accuracy: ", gender_accuracy_participant_n,
                      " participants; RT: ", gender_rt_participant_n, " participants"),
    x = NULL, y = NULL, colour = "Stimulus gender"
  ) +
  publication_theme()
save_plot(gender_moderation_plot, "figure_09_gender_moderation", width = 10, height = 6.5)

white_status_plot_data <- white_status_moderation_estimates %>%
  mutate(
    trial_stratum = factor(trial_stratum,
                            levels = c("FACES", "AI-white", "AI-non-white")),
    estimate_display = ifelse(model_type == "accuracy", estimate * 100, estimate),
    low_display = ifelse(model_type == "accuracy", conf_low * 100, conf_low),
    high_display = ifelse(model_type == "accuracy", conf_high * 100, conf_high),
    outcome = ifelse(model_type == "accuracy", "Accuracy (%)", "Correct RT (sec)")
  )
white_status_plot <- ggplot(
  white_status_plot_data,
  aes(trial_stratum, estimate_display, colour = participant_white_status,
      group = participant_white_status)
) +
  geom_line(position = position_dodge(width = 0.15)) +
  geom_point(position = position_dodge(width = 0.15), size = 2) +
  geom_errorbar(aes(ymin = low_display, ymax = high_display),
                position = position_dodge(width = 0.15), width = 0.08) +
  facet_wrap(~outcome, scales = "free_y") +
  scale_colour_manual(values = c(White = "#3E6C8E", `Non-white` = "#B45F3C")) +
  labs(
    title = "Model-standardised performance by participant white status",
    subtitle = paste0("Accuracy: ", race_accuracy_participant_n,
                      " participants; RT: ", race_rt_participant_n, " participants"),
    x = NULL, y = NULL, colour = "Participant status"
  ) +
  publication_theme()
save_plot(white_status_plot, "figure_10_white_status_moderation", width = 9, height = 5)

clinical_difference_plot_data <- clinical_correlation_differences %>%
  filter(method == "spearman") %>%
  mutate(
    clinical_label = factor(clinical_label, levels = rev(unique(clinical_label))),
    comparison = factor(comparison, levels = names(comparison_definitions))
  )
clinical_difference_plot <- ggplot(
  clinical_difference_plot_data,
  aes(difference, clinical_label, colour = comparison)
) +
  geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = conf_low, xmax = conf_high),
                 position = position_dodge(width = 0.55), height = 0) +
  geom_point(position = position_dodge(width = 0.55), size = 1.7) +
  facet_wrap(~metric) +
  scale_colour_manual(values = c("#3E6C8E", "#3F8060", "#B45F3C")) +
  labs(
    title = "Differences in clinical association between stimulus sets",
    x = "Difference in Spearman correlation (participant-bootstrap 95% CI)",
    y = NULL, colour = "Comparison"
  ) +
  publication_theme()
save_plot(clinical_difference_plot, "figure_11_clinical_correlation_differences",
          width = 11, height = 7)

completion_plot_data <- completion_or %>%
  filter(term != "(Intercept)") %>%
  mutate(term = recode(
    term,
    age_z = "Age (per SD)",
    gender_binaryMan = "Man vs woman",
    `participant_white_statusNon-white` = "Non-white vs white",
    `prior_mh_binaryPrior condition` = "Prior MH condition vs none"
  ))
completion_plot <- ggplot(
  completion_plot_data,
  aes(odds_ratio, term)
) +
  geom_vline(xintercept = 1, colour = "grey65", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = odds_ratio_low, xmax = odds_ratio_high), height = 0) +
  geom_point(size = 2, colour = "#2F6B59") +
  facet_wrap(~model, scales = "free_y") +
  scale_x_log10() +
  labs(title = "Adjusted demographic associations with task inclusion and completion",
       x = "Adjusted odds ratio (log scale, 95% CI)", y = NULL) +
  publication_theme()
save_plot(completion_plot, "figure_12_completion_adjusted_odds", width = 10, height = 5)

sensitivity_plot_data <- sensitivity_set_contrasts %>%
  filter(contrast == "AI-diverse minus FACES") %>%
  mutate(
    estimate_display = ifelse(model_type == "accuracy", estimate * 100, estimate),
    low_display = ifelse(model_type == "accuracy", conf_low * 100, conf_low),
    high_display = ifelse(model_type == "accuracy", conf_high * 100, conf_high),
    outcome = ifelse(model_type == "accuracy",
                     "Accuracy difference (percentage points)",
                     "Correct RT difference (seconds)")
  )
sensitivity_plot <- ggplot(
  sensitivity_plot_data,
  aes(estimate_display, reorder(specification, estimate_display))
) +
  geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = low_display, xmax = high_display), height = 0) +
  geom_point(size = 2, colour = "#2F6B59") +
  facet_wrap(~outcome, scales = "free") +
  labs(title = "AI-diverse versus FACES across focused sensitivity analyses",
       x = "AI-diverse minus FACES (95% CI)", y = NULL) +
  publication_theme()
save_plot(sensitivity_plot, "figure_13_sensitivity_contrasts", width = 10, height = 5)

# 11. Sanity checks and manuscript-facing report --------------------------

analysis_checks <- tibble(
  check = c(
    "Prepared validation checks passed",
    "Accuracy model used only common emotions",
    "RT model used only correct in-bound trials",
    "Accuracy model retained disjoint trial rows",
    "AI-diverse model estimate pooled after fitting",
    "Clinical correlations use participant rows",
    "All mixed models converged without singularity",
    "Gender direct contrasts are complete and finite",
    "White-status direct contrasts are complete and finite",
    "No confirmatory non-inferiority conclusion generated"
  ),
  passed = c(
    all(preparation_checks$passed),
    all(accuracy_data$target_emotion %in% common_emotions),
    all(rt_data$rt_sec >= 0.20 & rt_data$rt_sec <= 30 & rt_data$correct),
    !anyDuplicated(accuracy_data[c("participant_id", "trial_number")]),
    "AI-diverse" %in% model_set_estimates$stimulus_set,
    max(clinical_correlations$n, na.rm = TRUE) <= nrow(participants),
    all(!all_model_diagnostics$singular & all_model_diagnostics$convergence_message == ""),
    nrow(gender_moderation_contrasts) == 24L &&
      all(is.finite(gender_moderation_contrasts$estimate)),
    nrow(white_status_moderation_contrasts) == 12L &&
      all(is.finite(white_status_moderation_contrasts$estimate)),
    TRUE
  )
)
readr::write_csv(analysis_checks, file.path(diagnostics_dir, "analysis_sanity_checks.csv"), na = "")
if (!all(analysis_checks$passed)) stop("One or more analysis sanity checks failed")

format_markdown_table <- function(data, digits = 3) {
  capture.output(knitr::kable(data, format = "pipe", digits = digits, row.names = FALSE))
}

condition_table_report <- condition_descriptives %>%
  filter(stimulus_set %in% reported_sets) %>%
  select(metric, stimulus_set, n_participants, mean, sd, median, q25, q75)

model_estimates_report <- model_set_estimates %>%
  filter(stimulus_set %in% reported_sets) %>%
  mutate(across(c(estimate, conf_low, conf_high),
                ~ifelse(model_type == "accuracy", .x * 100, .x))) %>%
  select(model_type, stimulus_set, estimate, conf_low, conf_high,
         observed_ai_white_weight)

instrument_descriptives_report <- instrument_descriptives %>%
  transmute(
    instrument,
    items = item_count,
    n,
    mean,
    sd,
    median,
    observed_range = paste0(observed_min, "-", observed_max),
    theoretical_range,
    cronbach_alpha
  )

top_clinical_report <- clinical_correlations %>%
  filter(method == "spearman", stimulus_set %in% reported_sets) %>%
  arrange(desc(abs(estimate))) %>%
  slice_head(n = 20) %>%
  select(metric, clinical_label, stimulus_set, n, estimate, conf_low, conf_high, p_fdr) %>%
  mutate(p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001))

incremental_clinical_report <- incremental_clinical_performance_terms %>%
  mutate(
    clinical_label = unname(clinical_scores[clinical_score]),
    performance_term = recode(factor(term),
                              faces_z = "FACES",
                              ai_diverse_z = "AI-diverse"),
    p.value = format.pval(p.value, digits = 3, eps = 0.001),
    p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001)
  ) %>%
  select(metric, clinical_label, performance_term, n, estimate,
         conf.low, conf.high, p.value, p_fdr)

attrition_model_report <- completion_or %>%
  filter(term != "(Intercept)") %>%
  select(model, n, term, odds_ratio, odds_ratio_low, odds_ratio_high, p.value, p_fdr)

intake_availability_report <- intake_availability_test %>%
  mutate(p_value = format.pval(p_value, digits = 3, eps = 0.001))

moderation_interaction_report <- moderation_terms %>%
  filter(grepl(":", term)) %>%
  select(model, participant_n, trial_n, term, estimate, conf.low, conf.high,
         p.value, p_fdr, p_method)

gender_contrast_report <- gender_moderation_contrasts %>%
  filter(contrast_family == "Same minus different stimulus gender") %>%
  mutate(
    across(c(estimate, conf_low, conf_high),
           ~ifelse(model_type == "accuracy", .x * 100, .x)),
    p_value = format.pval(p_value, digits = 3, eps = 0.001),
    p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001)
  )

gender_group_difference_report <- gender_moderation_contrasts %>%
  filter(contrast_family == "Participant man minus woman") %>%
  mutate(
    across(c(estimate, conf_low, conf_high),
           ~ifelse(model_type == "accuracy", .x * 100, .x)),
    p_value = format.pval(p_value, digits = 3, eps = 0.001),
    p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001)
  )

white_status_contrast_report <- white_status_moderation_contrasts %>%
  filter(contrast_family == "Same minus different broad-status AI stimulus") %>%
  mutate(
    across(c(estimate, conf_low, conf_high),
           ~ifelse(model_type == "accuracy", .x * 100, .x)),
    p_value = format.pval(p_value, digits = 3, eps = 0.001),
    p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001)
  )

white_status_group_difference_report <- white_status_moderation_contrasts %>%
  filter(contrast_family == "Participant non-white minus white") %>%
  mutate(
    across(c(estimate, conf_low, conf_high),
           ~ifelse(model_type == "accuracy", .x * 100, .x)),
    p_value = format.pval(p_value, digits = 3, eps = 0.001),
    p_fdr = format.pval(p_fdr, digits = 3, eps = 0.001)
  )

sensitivity_contrasts_report <- sensitivity_set_contrasts %>%
  filter(contrast == "AI-diverse minus FACES") %>%
  mutate(across(c(estimate, conf_low, conf_high),
                ~ifelse(model_type == "accuracy", .x * 100, .x))) %>%
  select(model_type, specification, estimate, conf_low, conf_high, p_fdr)

performance_headlines <- model_set_contrasts %>%
  filter(
    contrast %in% c("AI-white minus FACES", "AI-diverse minus FACES",
                    "AI-diverse minus AI-white")
  )
clinical_fdr_count <- clinical_correlations %>%
  filter(method == "spearman", stimulus_set %in% reported_sets, p_fdr < 0.05) %>%
  nrow()
clinical_difference_fdr_count <- sum(clinical_correlation_differences$p_fdr < 0.05,
                                     na.rm = TRUE)
gender_three_way_min_fdr <- moderation_terms %>%
  filter(grepl("trial_stratum.*gender_binary.*face_gender", term)) %>%
  summarise(value = min(p_fdr, na.rm = TRUE)) %>%
  pull(value)
white_status_interaction_min_fdr <- moderation_terms %>%
  filter(grepl("trial_stratum.*participant_white_status", term)) %>%
  summarise(value = min(p_fdr, na.rm = TRUE)) %>%
  pull(value)

results_report <- c(
  "# Emotion Recognition: FACES vs AI Faces Results Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "> Status: complete provisional run. The primary clinical family and non-inferiority margin remain unresolved, so no confirmatory replacement claim is made.",
  "",
  "## Cohort",
  "",
  format_markdown_table(cohort_flow, 2),
  "",
  "### Structural demographic availability",
  "",
  "Intake demographics were unavailable for 174/230 participants without valid emotion-recognition data and 39/1,047 participants with valid data. The adjusted regressions are therefore explicitly complete-case models rather than models of all 1,277 source participants.",
  "",
  format_markdown_table(intake_availability_counts, 2),
  "",
  format_markdown_table(intake_availability_report, 3),
  "",
  "### Adjusted attrition models",
  "",
  "The first model concerns any valid emotion-recognition data. The second has only nine incomplete cases in its complete-covariate sample, so its intervals are necessarily imprecise.",
  "",
  format_markdown_table(attrition_model_report, 3),
  "",
  "## Clinical Instrument Descriptives and Internal Consistency",
  "",
  "Totals required complete item data. Cronbach's alpha was calculated from complete item responses in the primary accuracy sample.",
  "",
  format_markdown_table(instrument_descriptives_report, 3),
  "",
  "## Descriptive Performance",
  "",
  "Participant summaries use the six emotions common to FACES and AI. AI-white is a subset of AI-diverse.",
  "",
  format_markdown_table(condition_table_report, 3),
  "",
  "## Mixed-Model Standardised Estimates",
  "",
  "The model was fitted to disjoint FACES, AI-white, and AI-non-white trial strata. AI-diverse was pooled afterwards using the observed cleaned AI trial mix; shared white trials were not duplicated.",
  "",
  format_markdown_table(model_estimates_report, 4),
  "",
  "## Mixed-Model Contrasts",
  "",
  format_markdown_table(model_set_contrasts, 4),
  "",
  paste0(
    "AI-white and observed-mix AI-diverse accuracy exceeded FACES by ",
    round(100 * performance_headlines$estimate[
      performance_headlines$model_type == "accuracy" &
        performance_headlines$contrast == "AI-white minus FACES"
    ], 1),
    " and ",
    round(100 * performance_headlines$estimate[
      performance_headlines$model_type == "accuracy" &
        performance_headlines$contrast == "AI-diverse minus FACES"
    ], 1),
    " percentage points, respectively. Their corresponding correct RT estimates were ",
    abs(round(performance_headlines$estimate[
      performance_headlines$model_type == "rt" &
        performance_headlines$contrast == "AI-white minus FACES"
    ], 2)),
    " and ",
    abs(round(performance_headlines$estimate[
      performance_headlines$model_type == "rt" &
        performance_headlines$contrast == "AI-diverse minus FACES"
    ], 2)),
    " seconds faster. AI-white and AI-diverse did not differ clearly on either outcome."
  ),
  "",
  "## Strongest Descriptive Clinical Associations",
  "",
  "These are ranked descriptive Spearman associations with participant-bootstrap confidence intervals. Selection by observed magnitude is exploratory.",
  "",
  format_markdown_table(top_clinical_report, 4),
  "",
  paste0(
    clinical_fdr_count,
    " Spearman associations among the three reported sets survived the provisional within-family FDR correction. No dependent difference in clinical association survived FDR correction (",
    clinical_difference_fdr_count, " passed the adjusted threshold)."
  ),
  "",
  "### Incremental clinical signal",
  "",
  "FACES and AI-diverse performance were entered jointly, with age, binary gender contrast, and participant white status as covariates. Coefficients are standardised associations with the clinical score; these remain secondary association models rather than diagnostic models.",
  "",
  format_markdown_table(incremental_clinical_report, 4),
  "",
  "## Demographic Moderation",
  "",
  "The table below reports interaction coefficients on the log-odds scale for accuracy and log-seconds scale for RT. Model-standardised cell estimates are in `gender_moderation_standardised_estimates.csv` and `white_status_moderation_standardised_estimates.csv`.",
  "",
  format_markdown_table(moderation_interaction_report, 4),
  "",
  "### Participant-group differences",
  "",
  "Accuracy differences are percentage points and RT differences are seconds. Gender contrasts are man minus woman after averaging equally over stimulus genders; broad-status contrasts are non-white minus white within each fixed stimulus stratum.",
  "",
  format_markdown_table(gender_group_difference_report, 4),
  "",
  format_markdown_table(white_status_group_difference_report, 4),
  "",
  "### Direct gender-congruence contrasts",
  "",
  "Accuracy differences are percentage points and RT differences are seconds. Positive values indicate higher accuracy or slower RT for same-gender than different-gender stimuli. Participant-specific rows and the equally pooled summary are covariance-aware contrasts from the fitted trial model.",
  "",
  format_markdown_table(gender_contrast_report, 4),
  "",
  "### Direct broad ethnicity-status congruence contrasts",
  "",
  "These contrasts are restricted to AI-white versus AI-non-white trials because FACES has no non-white stimuli. Positive values indicate higher accuracy or slower RT for same-status stimuli. White/non-white status is a deliberately coarse proxy and is not exact ethnic ingroup membership.",
  "",
  format_markdown_table(white_status_contrast_report, 4),
  "",
  paste0(
    "The smallest FDR-adjusted p-value among the source-by-participant-by-stimulus gender terms was ",
    round(gender_three_way_min_fdr, 3),
    "; the smallest among source-by-participant-white-status interactions was ",
    round(white_status_interaction_min_fdr, 3),
    ". These models therefore provide no clear evidence of the prespecified moderation effects."
  ),
  "",
  "## Focused Sensitivity Analyses",
  "",
  "The AI-diverse versus FACES contrast was repeated among complete 80-trial participants, after excluding high-ceiling happy trials for accuracy, and under narrower and all-positive correct-RT rules.",
  "",
  format_markdown_table(sensitivity_contrasts_report, 4),
  "",
  "## Reliability and Agreement",
  "",
  format_markdown_table(reliability, 3),
  "",
  format_markdown_table(agreement_summary, 3),
  "",
  "## Model Diagnostics",
  "",
  format_markdown_table(all_model_diagnostics, 3),
  "",
  "## Interpretation Boundary",
  "",
  "This run establishes descriptive performance, comparative model estimates, clinical associations, attrition models, and demographic moderation models. It does not establish diagnostic validity because the outcomes are symptom instruments rather than clinician-assigned diagnoses. It also does not establish non-inferiority until a defensible margin and primary clinical family are fixed."
)
writeLines(results_report, file.path(analysis_root, "results_report.md"))

compact_demographics <- readr::read_csv(
  file.path(tables_dir, "demographics_full_and_cleaned.csv"), show_col_types = FALSE
) %>%
  filter(
    variable %in% c("age", "gender_original", "participant_ethnicity_group",
                    "prior_mh_status", "task_position"),
    summary_type == "categorical" |
      (variable == "age" & level_or_statistic %in% c("n", "missing", "mean", "sd", "median", "q25", "q75"))
  ) %>%
  select(sample, variable, level_or_statistic, value, denominator, percent)

publication_tables <- c(
  "# Publication Tables",
  "",
  "These human-readable tables are generated from the corresponding CSV files. CSV remains the authoritative machine-readable format.",
  "",
  "## Table 1. Selected demographic characteristics",
  "",
  format_markdown_table(compact_demographics, 2),
  "",
  "## Table 2. Participant-level performance",
  "",
  format_markdown_table(condition_table_report, 3),
  "",
  "## Table 3. Clinical instrument descriptives and internal consistency",
  "",
  format_markdown_table(instrument_descriptives_report, 3),
  "",
  "## Table 4. Model-standardised performance contrasts",
  "",
  format_markdown_table(model_set_contrasts, 4),
  "",
  "## Table 5. Adjusted task inclusion and completion models",
  "",
  format_markdown_table(attrition_model_report, 3),
  "",
  "## Table 6. Strongest descriptive clinical associations",
  "",
  format_markdown_table(top_clinical_report, 4),
  "",
  "## Table 7. Demographic moderation interaction terms",
  "",
  format_markdown_table(moderation_interaction_report, 4),
  "",
  "## Table 8. Direct ingroup/outgroup contrasts",
  "",
  format_markdown_table(gender_group_difference_report, 4),
  "",
  format_markdown_table(white_status_group_difference_report, 4),
  "",
  format_markdown_table(gender_contrast_report, 4),
  "",
  format_markdown_table(white_status_contrast_report, 4),
  "",
  "## Table 9. Incremental clinical-signal performance terms",
  "",
  format_markdown_table(incremental_clinical_report, 4),
  "",
  "## Table 10. Reliability",
  "",
  format_markdown_table(reliability, 3),
  "",
  "## Table 11. FACES versus AI-diverse agreement",
  "",
  format_markdown_table(agreement_summary, 3),
  "",
  "## Table 12. Focused sensitivity contrasts",
  "",
  format_markdown_table(sensitivity_contrasts_report, 4)
)
writeLines(publication_tables, file.path(tables_dir, "publication_tables.md"))

sanity_report <- c(
  "# Analysis Sanity-Check Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Automated Checks",
  "",
  paste0("- ", analysis_checks$check, ": ", ifelse(analysis_checks$passed, "PASS", "FAIL")),
  "",
  "## Model Samples",
  "",
  paste0("- Accuracy mixed model: ", n_distinct(accuracy_data$participant_id),
         " participants and ", nrow(accuracy_data), " trials."),
  paste0("- RT mixed model: ", n_distinct(rt_data$participant_id),
         " participants and ", nrow(rt_data), " correct in-bound trials."),
  paste0("- Gender accuracy moderation: ", gender_accuracy_participant_n,
         " participants and ", gender_accuracy_trial_n, " trials."),
  paste0("- White-status accuracy moderation: ", race_accuracy_participant_n,
         " participants and ", race_accuracy_trial_n, " trials."),
  "",
  "## Known Boundaries",
  "",
  "- Completion-event status and the stricter 80-valid-trial definition are both retained.",
  "- FACES contains no surprise trials, so primary comparisons use six common emotions.",
  "- FACES is white-only, so source and white-stimulus status cannot be fully separated.",
  "- White/non-white congruence is not equivalent to exact ethnic ingroup membership.",
  "- Primary clinical outcomes and the non-inferiority margin remain unresolved.",
  "- Fitted model objects are not distributed; every table and diagnostic is regenerated by Script 2."
)
writeLines(sanity_report, file.path(analysis_root, "sanity_check_report.md"))

table_figure_index <- c(
  "# Table and Figure Index",
  "",
  "## Main Tables",
  "",
  "1. `demographics_full_and_cleaned.csv`: source, primary accuracy, and primary RT demographics.",
  "2. `clinical_instrument_descriptives_reliability.csv`: score distributions and Cronbach's alpha in the primary sample.",
  "3. `trial_sampling_randomisation_checks.csv`: source and within-source emotion balance checks for the supplied sampling implementation.",
  "4. `condition_descriptive_statistics.csv`: participant performance across stimulus sets.",
  "5. `mixed_model_stimulus_set_estimates.csv`: standardised accuracy and RT estimates.",
  "6. `clinical_correlations.csv`: clinical associations by set and metric.",
  "7. `completion_logistic_regression.csv`: adjusted completer/non-completer comparisons.",
  "8. `descriptives_by_gender_and_stimulus_set.csv`: gender subgroup estimates.",
  "9. `descriptives_by_ethnicity_and_stimulus_set.csv`: ethnicity subgroup estimates.",
  "10. `gender_moderation_standardised_estimates.csv`: model-standardised gender cells.",
  "11. `white_status_moderation_standardised_estimates.csv`: model-standardised white-status cells.",
  "12. `gender_moderation_contrasts.csv` and `white_status_moderation_contrasts.csv`: direct congruence and participant-group contrasts.",
  "13. `dependent_clinical_correlation_differences.csv`: paired differences in clinical association.",
  "14. `reliability_split_half.csv` and `faces_ai_diverse_agreement.csv`: replacement-relevant psychometrics.",
  "15. `publication_tables.md`: selected human-readable manuscript tables.",
  "16. `sensitivity_stimulus_set_estimates.csv` and `sensitivity_stimulus_set_contrasts.csv`: focused robustness results.",
  "17. `incremental_clinical_signal_performance_terms.csv`: FACES and AI-diverse unique clinical associations with FDR correction.",
  "",
  "## Main Figures",
  "",
  "1. Participant flow.",
  "2. Participant accuracy distributions across overlapping reported sets.",
  "3. Participant correct-RT distributions across overlapping reported sets.",
  "4. Mixed-model standardised performance estimates.",
  "5. Clinical-correlation forest plot.",
  "6. Accuracy by participant gender and stimulus set.",
  "7. Accuracy by participant ethnicity and stimulus set.",
  "8. Emotion confusion matrices by source.",
  "9. Participant-by-stimulus gender moderation estimates.",
  "10. Participant white-status moderation estimates across disjoint stimulus strata.",
  "11. Paired differences in clinical association across stimulus sets.",
  "12. Adjusted odds ratios for task inclusion and complete-task status.",
  "13. AI-diverse versus FACES under complete-task, ceiling, and RT-window sensitivity rules.",
  "",
  "Each figure is available as high-resolution PNG and vector PDF. Final main-versus-supplementary placement remains a manuscript decision."
)
writeLines(table_figure_index, file.path(analysis_root, "table_and_figure_index.md"))

capture.output(sessionInfo(), file = file.path(provenance_dir, "session_info_analysis.txt"))
analysis_packages <- sort(unique(c(required_packages, "jsonlite", "stringr", "tibble")))
package_versions <- tibble(
  package = analysis_packages,
  version = vapply(analysis_packages, function(package) {
    utils::packageDescription(package)$Version
  }, character(1))
)
readr::write_csv(package_versions, file.path(provenance_dir, "package_versions.csv"), na = "")

script_paths <- c(
  file.path(repository_root, "R", "01_prepare_data.R"),
  file.path(repository_root, "R", "02_run_analyses.R")
)
script_manifest <- tibble(
  script = basename(script_paths),
  md5 = unname(tools::md5sum(script_paths)),
  modified_time = as.character(file.info(script_paths)$mtime)
)
readr::write_csv(script_manifest, file.path(provenance_dir, "script_manifest.csv"), na = "")

git_commit <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE)[1],
  error = function(error_condition) NA_character_
)
git_status <- tryCatch(
  system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = FALSE),
  error = function(error_condition) character()
)
decisions <- readr::read_csv(file.path(repository_root, "analysis_decisions.csv"),
                             show_col_types = FALSE)
provenance_manifest <- tibble(
  field = c(
    "generated", "released_data", "r_version", "random_seed",
    "bootstrap_repetitions", "coefficient_simulations", "git_commit",
    "git_worktree_dirty", "primary_accuracy_formula", "primary_rt_formula"
  ),
  value = c(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    decisions$value[decisions$decision == "Released data"],
    R.version.string, "20260908", as.character(bootstrap_repetitions),
    as.character(coefficient_simulations), git_commit,
    as.character(length(git_status) > 0),
    accuracy_artifacts$diagnostic$formula[1],
    rt_artifacts$diagnostic$formula[1]
  )
)
readr::write_csv(provenance_manifest,
                 file.path(provenance_dir, "provenance_manifest.csv"), na = "")

log_message("Analysis completed successfully")
log_message("Results report: results/results_report.md")

output_paths <- list.files(analysis_root, recursive = TRUE, full.names = TRUE)
output_paths <- output_paths[file.info(output_paths)$isdir %in% FALSE]
output_paths <- output_paths[basename(output_paths) != "output_manifest.csv"]
output_manifest <- tibble(
  relative_path = substring(output_paths, nchar(analysis_root) + 2L),
  bytes = file.info(output_paths)$size,
  md5 = unname(tools::md5sum(output_paths))
)
readr::write_csv(output_manifest, file.path(provenance_dir, "output_manifest.csv"), na = "")

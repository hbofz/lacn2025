library(tidyverse)

if (!exists("ensure_cycle_config", mode = "function")) {
  source(file.path("code", "00_cycle_config.R"))
}

cycle_config <- ensure_cycle_config()

message(sprintf("Loading cycle %s from %s", cycle_config$cycle_id, cycle_config$raw_data_path))

if (!file.exists(cycle_config$raw_data_path)) {
  stop(sprintf("Raw data file not found: %s", cycle_config$raw_data_path), call. = FALSE)
}

if (!file.exists(cycle_config$response_key_path)) {
  stop(
    paste0(
      "Cycle input metadata not found: ",
      cycle_config$response_key_path,
      ". Copy the prior cycle's response_key_YY.csv, rename it for this cycle, and update it for any survey changes. ",
      "Note: data/response_key.csv is only a pipeline-generated snapshot and does not replace the cycle-specific file."
    ),
    call. = FALSE
  )
}

if (!file.exists(cycle_config$progress_path)) {
  stop(
    paste0(
      "Cycle input metadata not found: ",
      cycle_config$progress_path,
      ". Copy the prior cycle's progress_YY.csv, rename it for this cycle, and update it for any survey changes."
    ),
    call. = FALSE
  )
}

raw_result <- read_cycle_raw_data(cycle_config$raw_data_path)
lacn_master <- raw_result$data

# Prefix numeric question headers and strip trailing parenthetical code labels.
colnames(lacn_master) <- ifelse(
  stringr::str_detect(colnames(lacn_master), "^[0-9]"),
  paste0("Q", colnames(lacn_master)),
  colnames(lacn_master)
)

colnames(lacn_master) <- stringr::str_replace(
  colnames(lacn_master),
  " \\(.*\\)$",
  ""
)

# Keep only submitted survey responses and normalize empty strings.
lacn_master <- lacn_master |>
  dplyr::mutate(across(everything(), ~ dplyr::na_if(.x, "")))

if ("Status" %in% colnames(lacn_master)) {
  lacn_master <- lacn_master |>
    dplyr::filter(Status == "IP Address")
}

if (!"Institution Name" %in% colnames(lacn_master)) {
  stop("Missing required column: Institution Name", call. = FALSE)
}

if ("Q1_2" %in% colnames(lacn_master)) {
  lacn_master <- lacn_master |>
    dplyr::mutate(
      `Institution Name` = dplyr::coalesce(`Institution Name`, Q1_2)
    )
}

lacn_master <- apply_institution_name_overrides(
  lacn_master,
  cycle_config$institution_overrides_path
)

lacn_master <- lacn_master |>
  dplyr::mutate(`Institution Name` = stringr::str_squish(`Institution Name`)) |>
  dplyr::filter(
    !is.na(`Institution Name`),
    !`Institution Name` %in% c("", "Institution Name", "{\"ImportId\":\"Institution Name\"}")
  )

response_key <- readr::read_csv(
  cycle_config$response_key_path,
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)

question_type <- readr::read_csv(
  cycle_config$progress_path,
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)

report_contract <- build_report_contract(cycle_config$cycle_id, response_key)

required_qtype_cols <- c("unique", "q_type")
missing_qtype_cols <- setdiff(required_qtype_cols, names(question_type))
if (length(missing_qtype_cols) > 0) {
  stop(
    sprintf("progress file missing required column(s): %s", paste(missing_qtype_cols, collapse = ", ")),
    call. = FALSE
  )
}

question_type <- question_type |>
  dplyr::filter(!is.na(unique), unique != "") |>
  dplyr::mutate(unique = stringr::str_trim(unique), q_type = stringr::str_trim(q_type))

question_regex <- function(question) {
  paste0("^", question, "(_|$)")
}

question_checks <- question_type |>
  dplyr::distinct(unique) |>
  dplyr::mutate(
    check = paste0("question_columns:", unique),
    passed = purrr::map_lgl(unique, ~ any(stringr::str_detect(names(lacn_master), question_regex(.x)))),
    detail = purrr::map_chr(
      unique,
      ~ paste(names(lacn_master)[stringr::str_detect(names(lacn_master), question_regex(.x))], collapse = " | ")
    )
  ) |>
  dplyr::select(check, passed, detail)

required_named_columns <- c(
  "Institution Name",
  "Undergraduate enrollment",
  "Value of endowment assets at the beginning of the fiscal year"
)

named_checks <- tibble::tibble(
  check = paste0("required_column:", required_named_columns),
  passed = required_named_columns %in% names(lacn_master),
  detail = ifelse(required_named_columns %in% names(lacn_master), "present", "missing")
)

response_key_question_checks <- response_key |>
  dplyr::filter(!is.na(Question), Question != "") |>
  dplyr::distinct(Question) |>
  dplyr::mutate(
    check = paste0("response_key_question:", Question),
    passed = Question %in% names(lacn_master),
    detail = ifelse(passed, "present", "missing")
  ) |>
  dplyr::select(check, passed, detail)

dupe_checks <- if (nrow(raw_result$duplicate_report) == 0L) {
  tibble::tibble(
    check = "duplicate_columns",
    passed = TRUE,
    detail = "No duplicate headers were detected"
  )
} else {
  raw_result$duplicate_report |>
    dplyr::mutate(
      check = paste0("duplicate_column:", base_name),
      passed = identical_values,
      detail = paste0("kept=", kept_column, "; dropped=", dropped_column)
    ) |>
    dplyr::select(check, passed, detail)
}

schema_report <- dplyr::bind_rows(
  named_checks,
  question_checks,
  response_key_question_checks,
  dupe_checks
)

readr::write_csv(schema_report, cycle_config$schema_report_path)
message(sprintf("Wrote schema report to %s", cycle_config$schema_report_path))

if (any(!schema_report$passed)) {
  failed <- schema_report |>
    dplyr::filter(!passed)

  print(failed, n = nrow(failed))
  stop("Schema validation failed. See schema report for details.", call. = FALSE)
}

# Keep a local response key snapshot for the active cycle.
readr::write_csv(response_key, cycle_config$response_key_path)
readr::write_csv(response_key, file.path(dirname(cycle_config$response_key_path), "response_key.csv"))

#!/usr/bin/env Rscript

library(tidyverse)

source(file.path("code", "00_cycle_config.R"))

args <- commandArgs(trailingOnly = TRUE)
cycle_arg <- args[stringr::str_detect(args, "^--cycle=")]
cycle_id <- if (length(cycle_arg) > 0) {
  stringr::str_remove(cycle_arg[[1]], "^--cycle=")
} else {
  Sys.getenv("LACN_CYCLE_ID", "26")
}

cycle_config <- load_cycle_config(cycle_id = cycle_id)

if (!file.exists(cycle_config$rdata_path)) {
  stop(sprintf("Missing workspace file: %s", cycle_config$rdata_path), call. = FALSE)
}

load(cycle_config$rdata_path, envir = .GlobalEnv)

if (!exists("response_key", inherits = FALSE)) {
  response_key <- readr::read_csv(
    cycle_config$response_key_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
}

report_contract <- ensure_report_contract(
  response_key = response_key,
  cycle_config = cycle_config
)

fmt_int <- function(x) {
  format(round(as.numeric(x)), big.mark = ",", trim = TRUE, scientific = FALSE)
}

read_html_text <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }

  paste(readLines(path, warn = FALSE), collapse = "\n")
}

make_check <- function(check_type, target, expected, passed, detail) {
  tibble::tibble(
    check_type = check_type,
    target = target,
    expected = as.character(expected),
    passed = passed,
    detail = detail
  )
}

colleges <- clean_institution_names(question_list$Q1$`Institution Name`)
expected_files <- paste0(vapply(colleges, sanitize_school_filename, character(1)), ".html")
actual_files <- list.files(cycle_config$custom_output_dir, pattern = "\\.html$", full.names = FALSE)

general_html_path <- file.path(dirname(cycle_config$general_report_rmd), "GeneralReport.html")
index_html_path <- file.path(dirname(cycle_config$index_rmd), "docs", "index.html")
general_html <- read_html_text(general_html_path)
index_html <- read_html_text(index_html_path)

custom_html <- purrr::set_names(
  purrr::map_chr(expected_files, ~ read_html_text(file.path(cycle_config$custom_output_dir, .x))),
  colleges
)

completed_responses <- length(colleges)
grad_services_note <- availability_summary_text(
  question_list[[report_contract$grad_services_available]],
  report_contract$grad_services_available,
  "graduate-student services"
)
alumni_services_note <- availability_summary_text(
  question_list[[report_contract$alumni_services_available]],
  report_contract$alumni_services_available,
  "alumni services"
)

artifact_checks <- dplyr::bind_rows(
  make_check(
    check_type = "artifact_exists",
    target = "GeneralReport.html",
    expected = basename(general_html_path),
    passed = file.exists(general_html_path),
    detail = general_html_path
  ),
  make_check(
    check_type = "artifact_exists",
    target = "index.html",
    expected = basename(index_html_path),
    passed = file.exists(index_html_path),
    detail = index_html_path
  ),
  make_check(
    check_type = "custom_count",
    target = "custom_html_count",
    expected = length(expected_files),
    passed = length(actual_files) == length(expected_files),
    detail = sprintf("expected=%d actual=%d", length(expected_files), length(actual_files))
  ),
  make_check(
    check_type = "index_cycle_label",
    target = "docs/index.html",
    expected = cycle_config$cycle_label,
    passed = !is.na(index_html) && stringr::str_detect(index_html, stringr::fixed(cycle_config$cycle_label)),
    detail = "Landing page should show the active cycle label."
  ),
  make_check(
    check_type = "index_response_count",
    target = "docs/index.html",
    expected = paste(completed_responses, "completed responses"),
    passed = !is.na(index_html) && stringr::str_detect(index_html, stringr::fixed(paste(completed_responses, "completed responses"))),
    detail = "Landing page should show the current completed-response count."
  )
)

custom_exists_checks <- make_check(
  check_type = "custom_html_exists",
  target = colleges,
  expected = expected_files,
  passed = file.exists(file.path(cycle_config$custom_output_dir, expected_files)),
  detail = file.path(cycle_config$custom_output_dir, expected_files)
)

stale_files <- setdiff(actual_files, expected_files)
stale_checks <- if (length(stale_files) == 0L) {
  make_check(
    check_type = "stale_custom_html",
    target = "docs/custom",
    expected = "none",
    passed = TRUE,
    detail = "No stale custom HTML files found."
  )
} else {
  make_check(
    check_type = "stale_custom_html",
    target = stale_files,
    expected = "not present",
    passed = FALSE,
    detail = "Unexpected custom HTML file present."
  )
}

enrollment_expected <- tibble::tibble(`Institution Name` = colleges) |>
  dplyr::left_join(
    enroll_data |>
      dplyr::transmute(`Institution Name`, expected_value = fmt_int(enroll)),
    by = "Institution Name"
  ) |>
  dplyr::mutate(expected_value = dplyr::coalesce(expected_value, "0"))

funding_expected <- tibble::tibble(`Institution Name` = colleges) |>
  dplyr::left_join(
    total_budget |>
      dplyr::group_by(`Institution Name`) |>
      dplyr::summarise(total = sum(amount), .groups = "drop") |>
      dplyr::transmute(`Institution Name`, expected_value = fmt_int(total)),
    by = "Institution Name"
  ) |>
  dplyr::mutate(expected_value = dplyr::coalesce(expected_value, "0"))

enrollment_checks <- enrollment_expected |>
  dplyr::mutate(
    html = unname(custom_html[`Institution Name`]),
    passed = !is.na(html) & stringr::str_detect(html, stringr::fixed(expected_value)),
    detail = paste("Expected enrollment value", expected_value, "in custom HTML.")
  ) |>
  dplyr::transmute(
    check_type = "custom_enrollment_value",
    target = `Institution Name`,
    expected = expected_value,
    passed,
    detail
  )

funding_checks <- funding_expected |>
  dplyr::mutate(
    html = unname(custom_html[`Institution Name`]),
    passed = !is.na(html) & stringr::str_detect(html, stringr::fixed(expected_value)),
    detail = paste("Expected total funding value", expected_value, "in custom HTML.")
  ) |>
  dplyr::transmute(
    check_type = "custom_total_funding_value",
    target = `Institution Name`,
    expected = expected_value,
    passed,
    detail
  )

contract_expectations <- tibble::tribble(
  ~target, ~question_id, ~description_pattern,
  "grad_services_available", report_contract$grad_services_available, "Do you provide services to graduate students",
  "grad_services_scope", report_contract$grad_services_scope, "Please identify those services offered to graduate students",
  "alumni_services_available", report_contract$alumni_services_available, "Do you provide services to alumni",
  "alumni_services_scope", report_contract$alumni_services_scope, "scope of services offered to alumni"
)

contract_checks <- contract_expectations |>
  dplyr::rowwise() |>
  dplyr::mutate(
    description = response_key |>
      dplyr::filter(stringr::str_detect(Question, question_regex(question_id))) |>
      dplyr::pull(Description) |>
      dplyr::first(),
    passed = !is.na(description) && stringr::str_detect(description, stringr::regex(description_pattern, ignore_case = TRUE)),
    detail = dplyr::if_else(
      !is.na(description),
      description,
      "Question missing from response key."
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::transmute(
    check_type = "report_contract",
    target,
    expected = question_id,
    passed,
    detail
  )

availability_note_checks <- dplyr::bind_rows(
  make_check(
    check_type = "availability_note_general",
    target = "graduate_services",
    expected = grad_services_note,
    passed = !is.na(general_html) && stringr::str_detect(general_html, stringr::fixed(grad_services_note)),
    detail = "General report should contain the contract-backed graduate-services summary."
  ),
  make_check(
    check_type = "availability_note_general",
    target = "alumni_services",
    expected = alumni_services_note,
    passed = !is.na(general_html) && stringr::str_detect(general_html, stringr::fixed(alumni_services_note)),
    detail = "General report should contain the contract-backed alumni-services summary."
  ),
  make_check(
    check_type = "availability_note_custom",
    target = colleges,
    expected = grad_services_note,
    passed = !is.na(custom_html[colleges]) & stringr::str_detect(custom_html[colleges], stringr::fixed(grad_services_note)),
    detail = "Custom report should contain the graduate-services summary."
  ),
  make_check(
    check_type = "availability_note_custom",
    target = colleges,
    expected = alumni_services_note,
    passed = !is.na(custom_html[colleges]) & stringr::str_detect(custom_html[colleges], stringr::fixed(alumni_services_note)),
    detail = "Custom report should contain the alumni-services summary."
  )
)

validation <- dplyr::bind_rows(
  artifact_checks,
  custom_exists_checks,
  stale_checks,
  enrollment_checks,
  funding_checks,
  contract_checks,
  availability_note_checks
) |>
  dplyr::mutate(status = dplyr::if_else(passed, "PASS", "FAIL"))

out_csv <- file.path(
  dirname(cycle_config$schema_report_path),
  paste0("cycle_validation_", cycle_config$cycle_id, ".csv")
)
readr::write_csv(validation, out_csv)

cat("Validation output:", out_csv, "\n")
cat("PASS:", sum(validation$status == "PASS"), " FAIL:", sum(validation$status == "FAIL"), "\n")

if (any(validation$status == "FAIL")) {
  print(validation |>
    dplyr::filter(status == "FAIL"), n = Inf)
  quit(status = 1)
}

cat("Cycle output validation passed.\n")

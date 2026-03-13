#!/usr/bin/env Rscript

library(tidyverse)

source(file.path("code", "00_cycle_config.R"))
cycle_config <- load_cycle_config(cycle_id = Sys.getenv("LACN_CYCLE_ID", "26"))

if (!file.exists(cycle_config$rdata_path)) {
  stop(sprintf("Missing workspace file: %s", cycle_config$rdata_path), call. = FALSE)
}

load(cycle_config$rdata_path, envir = .GlobalEnv)
report_contract <- ensure_report_contract(
  response_key = if (exists("response_key", inherits = FALSE)) response_key else NULL,
  cycle_config = cycle_config
)

school <- "St Olaf College"
custom_html <- file.path(cycle_config$custom_output_dir, paste0(sanitize_school_filename(school), ".html"))

if (!file.exists(custom_html)) {
  stop(sprintf("Custom report not found: %s", custom_html), call. = FALSE)
}

html_txt <- paste(readLines(custom_html, warn = FALSE), collapse = "\n")

fmt_int <- function(x) {
  format(round(as.numeric(x)), big.mark = ",", trim = TRUE, scientific = FALSE)
}

make_table_stats <- function(df, var, school_name) {
  v <- df[[var]]
  school_val <- df |>
    dplyr::filter(`Institution Name` == school_name) |>
    dplyr::pull(.data[[var]])

  school_val <- if (length(school_val) > 0) school_val[[1]] else NA_real_

  tibble::tibble(
    metric = c("N", "Mean", "Median", "Max", "Min", school_name),
    expected = c(
      as.character(as.integer(sum(!is.na(v)))),
      fmt_int(mean(v, na.rm = TRUE)),
      fmt_int(stats::median(v, na.rm = TRUE)),
      fmt_int(max(v, na.rm = TRUE)),
      fmt_int(min(v, na.rm = TRUE)),
      fmt_int(school_val)
    )
  )
}

# 1) Enrollment table checks
enroll_stats <- make_table_stats(enroll_data, "enroll", school) |>
  dplyr::mutate(section = "Enrollment Summary")

# 2) Appointments with students summary table (chunk appt-student-dist-table)
appt_student_stats <- appt_student_data |>
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(Appt = sum(Appt), .groups = "drop") |>
  make_table_stats("Appt", school) |>
  dplyr::mutate(section = "Appointments with Students Summary")

# 3) Alumni appointments+email summary table (chunk appt-alum-table)
appt_alum_stats <- appt_alum_data |>
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(engage = sum(engage), .groups = "drop") |>
  make_table_stats("engage", school) |>
  dplyr::mutate(section = "Alumni Engagement Summary")

# 4) Total funding summary table (chunk total-funding-table)
total_funding_stats <- total_budget |>
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(total = sum(amount), .groups = "drop") |>
  make_table_stats("total", school) |>
  dplyr::mutate(section = "Total Funding Summary")

html_table_checks <- dplyr::bind_rows(
  enroll_stats,
  appt_student_stats,
  appt_alum_stats,
  total_funding_stats
) |>
  dplyr::mutate(
    found_in_html = purrr::map_lgl(expected, ~ stringr::str_detect(html_txt, stringr::fixed(.x))),
    check_type = "html_value_presence"
  )

# 5) Raw-data consistency checks for St Olaf reporting selections (Q2)
reporting_key <- keyFunction("Q2", Question, dim2) |>
  dplyr::filter(stringr::str_detect(Question, "^Q2_[1-6]$")) |>
  dplyr::select(Question, dim2)

stolaf_q2 <- question_list$Q2 |>
  dplyr::filter(`Institution Name` == school) |>
  tidyr::pivot_longer(
    cols = tidyselect::matches("^Q2_[1-6]$"),
    names_to = "Question",
    values_to = "selected"
  ) |>
  dplyr::filter(!is.na(selected) & selected != "") |>
  dplyr::left_join(reporting_key, by = "Question") |>
  dplyr::pull(dim2) |>
  unique()

reporting_distribution <- reporting_data |>
  dplyr::select(reporting_option, n, freq) |>
  dplyr::arrange(dplyr::desc(freq))

raw_checks <- tibble::tibble(
  section = c("St Olaf Reporting Selection", "Reporting Distribution Total"),
  metric = c("Selected options count", "Frequency sum"),
  expected = c(
    as.character(length(stolaf_q2)),
    as.character(round(sum(reporting_distribution$freq), 6))
  ),
  found_in_html = c(
    length(stolaf_q2) > 0,
    abs(sum(reporting_distribution$freq) - 1) < 1e-6
  ),
  check_type = c("raw_data_consistency", "raw_data_consistency")
)

validation <- dplyr::bind_rows(html_table_checks, raw_checks) |>
  dplyr::mutate(status = dplyr::if_else(found_in_html, "PASS", "FAIL"))

out_csv <- file.path("data", paste0("stolaf_validation_", cycle_config$cycle_id, ".csv"))
readr::write_csv(validation, out_csv)

cat("Validation output:", out_csv, "\n")
cat("PASS:", sum(validation$status == "PASS"), " FAIL:", sum(validation$status == "FAIL"), "\n")

if (any(validation$status == "FAIL")) {
  print(validation |> dplyr::filter(status == "FAIL"), n = Inf)
  quit(status = 1)
}

cat("St Olaf validation passed.\n")

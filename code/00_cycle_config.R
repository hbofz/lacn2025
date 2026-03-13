# Cycle configuration and shared helpers for local LACN runs

find_lacn_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(current, "lacn.Rproj"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate project root containing lacn.Rproj", call. = FALSE)
    }

    current <- parent
  }
}

lacn_root <- local({
  cached <- NULL

  function() {
    if (is.null(cached)) {
      cached <<- find_lacn_root()
    }

    cached
  }
})

path_from_root <- function(...) {
  file.path(lacn_root(), ...)
}

load_cycle_config <- function(
  cycle_id = Sys.getenv("LACN_CYCLE_ID", "26"),
  config_path = path_from_root("config", "cycles.csv")
) {
  cfg <- readr::read_csv(config_path, show_col_types = FALSE)

  selected <- cfg |>
    dplyr::filter(cycle_id == !!cycle_id)

  if (nrow(selected) != 1L) {
    stop(sprintf("Expected exactly one cycle row for cycle_id=%s", cycle_id), call. = FALSE)
  }

  as_path <- function(rel_path) {
    normalizePath(path_from_root(rel_path), winslash = "/", mustWork = FALSE)
  }

  row <- selected[1, ]

  list(
    cycle_id = row$cycle_id,
    cycle_label = row$cycle_label,
    cycle_subtitle = row$cycle_subtitle,
    publication_label = Sys.getenv("LACN_PUBLICATION_LABEL", format(Sys.Date(), "%B %Y")),
    raw_data_path = as_path(row$raw_data_file),
    response_key_path = as_path(row$response_key_file),
    progress_path = as_path(row$progress_file),
    schema_report_path = as_path(row$schema_report_file),
    institution_overrides_path = as_path(row$institution_overrides_file),
    employer_overrides_path = as_path(row$employer_overrides_file),
    budget_overrides_path = as_path(row$budget_overrides_file),
    rdata_path = as_path(row$rdata_file),
    general_report_rmd = as_path(row$general_report_rmd),
    custom_report_rmd = as_path(row$custom_report_rmd),
    index_rmd = as_path(row$index_rmd),
    custom_output_dir = as_path(row$custom_output_dir)
  )
}

ensure_cycle_config <- function() {
  if (!exists("cycle_config", envir = .GlobalEnv, inherits = FALSE)) {
    assign("cycle_config", load_cycle_config(), envir = .GlobalEnv)
  }

  get("cycle_config", envir = .GlobalEnv, inherits = FALSE)
}

# Read the survey CSV as character fields and collapse duplicate headers.
read_cycle_raw_data <- function(csv_path) {
  raw <- readr::read_csv(
    csv_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    name_repair = "unique"
  )

  original_names <- names(raw)
  base_names <- stringr::str_replace(original_names, "\\.\\.[0-9]+$", "")

  duplicate_groups <- unique(base_names[duplicated(base_names)])
  duplicate_report <- tibble::tibble()

  if (length(duplicate_groups) > 0) {
    for (dup_name in duplicate_groups) {
      idx <- which(base_names == dup_name)
      ref <- raw[[idx[1]]]

      for (j in idx[-1]) {
        is_identical <- identical(ref, raw[[j]])

        duplicate_report <- dplyr::bind_rows(
          duplicate_report,
          tibble::tibble(
            base_name = dup_name,
            kept_column = original_names[idx[1]],
            dropped_column = original_names[j],
            identical_values = is_identical
          )
        )
      }
    }
  }

  keep_idx <- !duplicated(base_names)
  deduped <- raw[, keep_idx, drop = FALSE]
  names(deduped) <- base_names[keep_idx]

  list(data = deduped, duplicate_report = duplicate_report)
}

apply_institution_name_overrides <- function(df, overrides_path) {
  if (!file.exists(overrides_path)) {
    return(df)
  }

  overrides <- readr::read_csv(overrides_path, show_col_types = FALSE)

  if (nrow(overrides) == 0L) {
    return(df)
  }

  before <- df$`Institution Name`

  for (i in seq_len(nrow(overrides))) {
    from <- overrides$from_institution[[i]]
    to <- overrides$to_institution[[i]]

    df$`Institution Name` <- dplyr::if_else(
      df$`Institution Name` == from,
      to,
      df$`Institution Name`
    )
  }

  changes <- sum(!is.na(before) & before != df$`Institution Name`)

  if (changes > 0) {
    message(sprintf("Applied %d institution-name override(s).", changes))
  }

  df
}

sanitize_school_filename <- function(name) {
  stringr::str_replace_all(name, "[[:space:]]+", "")
}

clean_institution_names <- function(x) {
  x |>
    stringr::str_squish() |>
    unique() |>
    purrr::discard(~ is.na(.x) || .x == "" || .x %in% c("Institution Name", "{\"ImportId\":\"Institution Name\"}"))
}

build_report_contract <- function(cycle_id, response_key) {
  contract <- switch(
    as.character(cycle_id),
    "26" = list(
      grad_services_available = "Q14",
      grad_services_scope = "Q15",
      grad_services_other_text = "Q15_4_TEXT",
      alumni_services_available = "Q16",
      alumni_services_scope = "Q17"
    ),
    stop(sprintf("No report contract defined for cycle_id=%s", cycle_id), call. = FALSE)
  )

  missing_questions <- purrr::discard(
    unlist(contract, use.names = FALSE),
    ~ any(stringr::str_detect(response_key$Question, question_regex(.x)))
  )
  if (length(missing_questions) > 0L) {
    stop(
      sprintf(
        "Report contract references missing question(s): %s",
        paste(missing_questions, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  contract
}

ensure_report_contract <- function(response_key = NULL, cycle_config = ensure_cycle_config()) {
  if (!exists("report_contract", envir = .GlobalEnv, inherits = FALSE)) {
    if (is.null(response_key)) {
      response_key <- readr::read_csv(
        cycle_config$response_key_path,
        show_col_types = FALSE,
        col_types = readr::cols(.default = readr::col_character())
      )
    }

    assign(
      "report_contract",
      build_report_contract(cycle_config$cycle_id, response_key),
      envir = .GlobalEnv
    )
  }

  get("report_contract", envir = .GlobalEnv, inherits = FALSE)
}

question_response_summary <- function(question_df, question_col, positive_value = "Yes") {
  values <- question_df[[question_col]]
  answered <- sum(!is.na(values) & values != "")
  positive <- sum(values == positive_value, na.rm = TRUE)

  list(
    total = nrow(question_df),
    answered = answered,
    positive = positive,
    negative = answered - positive
  )
}

availability_summary_text <- function(question_df, question_col, subject_label, positive_value = "Yes") {
  summary <- question_response_summary(question_df, question_col, positive_value = positive_value)

  sprintf(
    "%d of %d institutions report offering %s.",
    summary$positive,
    summary$total,
    subject_label
  )
}

# Build a regex that matches a question prefix exactly (e.g., "Q2" matches
# "Q2", "Q2_1", "Q2_3_5" but NOT "Q20" or "Q21").
question_regex <- function(question) {
  paste0("^", question, "(_|$)")
}

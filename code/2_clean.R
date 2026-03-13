#### ------- LIST of dfs for each question ------- ####
# question_regex() is defined in 00_cycle_config.R (already sourced).


question_ids <- question_type |>
  dplyr::distinct(unique) |>
  dplyr::pull(unique)

# Preallocate list for each question configured in progress metadata.
question_list <- vector(mode = "list", length = length(question_ids))

for (i in seq_along(question_ids)) {
  question <- question_ids[[i]]

  question_cols <- names(lacn_master)[
    stringr::str_detect(names(lacn_master), question_regex(question))
  ]

  if (length(question_cols) == 0L) {
    stop(sprintf("No columns matched question '%s'", question), call. = FALSE)
  }

  current_question <- lacn_master |>
    dplyr::select(
      `Institution Name`,
      `Undergraduate enrollment`,
      dplyr::all_of(question_cols)
    )

  question_list[[i]] <- current_question
}

names(question_list) <- question_ids

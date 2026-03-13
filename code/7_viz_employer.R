# =============================================================================
# 7_viz_employer.R — Employer relations data preparation
# Creates: info_no_data, info_employ_data
# Consumed by: GeneralReport.Rmd (Employer Relations sections),
#              custom_template.Rmd
# =============================================================================
library(tidyverse)

if (!exists("ensure_cycle_config", mode = "function")) {
  source(file.path("code", "00_cycle_config.R"))
}

cycle_config <- ensure_cycle_config()

employer_overrides <- if (file.exists(cycle_config$employer_overrides_path)) {
  readr::read_csv(cycle_config$employer_overrides_path, show_col_types = FALSE)
} else {
  tibble::tibble()
}

apply_employer_overrides <- function(df, dataset_name) {
  if (nrow(employer_overrides) == 0L) {
    return(df)
  }

  overrides <- employer_overrides |>
    dplyr::filter(dataset == dataset_name) |>
    dplyr::select(institution_name, dim2, amount)

  if (nrow(overrides) == 0L) {
    return(df)
  }

  out <- df |>
    dplyr::left_join(
      overrides,
      by = c("Institution Name" = "institution_name", "dim2")
    ) |>
    dplyr::mutate(amount = dplyr::coalesce(amount.y, amount.x)) |>
    dplyr::select(-amount.x, -amount.y)

  applied <- out |>
    dplyr::semi_join(
      overrides,
      by = c("Institution Name" = "institution_name", "dim2")
    ) |>
    nrow()

  message(sprintf("Applied employer overrides for %s (%d rows updated).", dataset_name, applied))

  out
}

info_no_data <- question_list$Q19 |>
  pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "amount"
  )|>
  
  mutate(amount = as.numeric(amount)) |>
  
  filter(Question %in% c('Q19_2_1','Q19_2_2')) |>
  
  left_join(
    keyFunction('Q19', dim1, dim2)
  ) |>
  
  mutate(dim2 = str_remove(dim2, "#[:blank:]"),
         amount = replace_na(amount,0)) |>
  
  select(!Question)|> 
  
  pivot_wider(
    names_from = dim2,
    values_from = amount
  ) |>
  
  filter(
    if_any((4:5), ~ .x > 0 & !is.na(.x)
    )
  ) |>
  
  pivot_longer(
    cols = (4:5),
    names_to = "dim2",
    values_to = "amount"
  ) |>
  
  apply_employer_overrides("info_no_data")






info_employ_data <- question_list$Q20 |>
  pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "amount"
  )|>
  
  mutate(amount = as.numeric(amount)) |>
  
  filter(Question %in% c('Q20_2_1','Q20_2_2')) |>
  
  left_join(
    keyFunction('Q20',dim1,dim2)
  )  |>
  
  mutate(dim2 = str_remove(dim2, "#[:blank:]"),
         amount = replace_na(amount,0)) |>
  
  select(!Question) |>
  
  pivot_wider(
    names_from = dim2,
    values_from = amount
  ) |>
  
  filter(
    if_any((4:5), ~ .x > 0 & !is.na(.x)
    )
  ) |>
  
  pivot_longer(
    cols = (4:5),
    names_to = "dim2",
    values_to = "amount"
  ) |>
  
  apply_employer_overrides("info_employ_data")


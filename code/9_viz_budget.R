# =============================================================================
# 9_viz_budget.R — Budget and funding data preparation
# Creates: funding_data, endow_exp_data, gift_data, OP_budget, NOP_budget,
#          total_budget
# Consumed by: GeneralReport.Rmd (Budget section),
#              custom_template.Rmd, validate_stolaf_report.R
# =============================================================================
library(tidyverse)

if (!exists("ensure_cycle_config", mode = "function")) {
  source(file.path("code", "00_cycle_config.R"))
}

cycle_config <- ensure_cycle_config()

budget_overrides <- if (file.exists(cycle_config$budget_overrides_path)) {
  readr::read_csv(cycle_config$budget_overrides_path, show_col_types = FALSE)
} else {
  tibble::tibble()
}

apply_budget_override <- function(data, target_field, override_type) {
  if (nrow(budget_overrides) == 0L) {
    return(data)
  }

  overrides <- budget_overrides |>
    dplyr::filter(target_field == !!target_field, override_type == !!override_type) |>
    dplyr::select(institution_name, dim1, override_value)

  if (nrow(overrides) == 0L) {
    return(data)
  }

  out <- data |>
    dplyr::left_join(
      overrides,
      by = c("Institution Name" = "institution_name", "dim1")
    )

  applied <- out |>
    dplyr::filter(!is.na(override_value)) |>
    nrow()

  message(
    sprintf(
      "Applied budget overrides (%s/%s): %d row(s).",
      target_field,
      override_type,
      applied
    )
  )

  out
}



#### Total Funding ####
funding_data <- question_list$Q26 |>
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "amount"
  ) |>
  dplyr::left_join(
    keyFunction('Q26',dim1, dim2)
    ) |>
  dplyr::select(`Institution Name`,dim1,dim2,amount) |>
  dplyr::mutate(amount = as.numeric(amount)) |>
  dplyr::group_by(`Institution Name`, dim1) |>
  dplyr::summarise(total = sum(amount, na.rm = TRUE)) |>
  tidyr::pivot_wider(
    names_from = dim1,
    values_from = total
  ) |>
  dplyr::filter(if_any(`Expendable gifts`:Other, ~ .x > 0)) |>
  tidyr::pivot_longer(
    cols = !(1),
    names_to = "dim1",
    values_to = "total"
  ) |>
  dplyr::mutate(total_mil = total/1e+06) |>
  dplyr::mutate(
    dim1 = stringr::str_to_title(
      stringr::str_remove(dim1, "Income from[:blank:]")
      )
  )



#### Endowed Funds ####

endow_exp_data <- question_list$Q26 |>
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "amount"
  ) |>
  dplyr::left_join(
    keyFunction('Q26',dim1,dim2)
  ) |>
  dplyr::mutate(
    dim1 = stringr::str_to_title(
      stringr::str_remove(dim1, "Income from[:blank:]")
      ),
    amount = as.numeric(amount)
    ) |>
  
  dplyr::filter(dim1 == "Endowed Funds" & dim2 != "Total") |>
  
  dplyr::group_by(`Institution Name`, dim2) |>
  dplyr::summarise(amount = sum(amount)) |>
  
  tidyr::pivot_wider(
    names_from = dim2,
    values_from = amount
  ) |>
  
  dplyr::filter(
    dplyr::if_any(`Amount available for funded internships ($)`:`Other ($)`,
                  ~ .x > 0 & !is.na(.x)
                  )
    ) |>
  
  tidyr::pivot_longer(
    cols = !(1),
    names_to = "dim2",
    values_to = "amount"
  ) |>
  
  dplyr::mutate(amount_mil = amount/1e+06,
                dim2 = stringr::str_to_title(
                  stringr::str_remove(dim2, 
                                      "Amount.+for[:blank:]"
                                      )
                  ),
                dim2 = stringr::str_remove(dim2,
                                           "[:blank:]\\([:symbol:]\\)"
                                           )
                )
                



#### Expendable Gifts ####

gift_data <- question_list$Q26 |>
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "amount"
  ) |>
  dplyr::left_join(
    keyFunction('Q26',dim1,dim2)
  ) |>
  
  dplyr::filter(dim1 == "Expendable gifts" & dim2 != "Total") |>
  
  dplyr::mutate(amount = tidyr::replace_na(as.numeric(amount),0)) |>
  
  dplyr::group_by(`Institution Name`, dim2) |>
  dplyr::summarise(amount = sum(amount)) |>
  
  dplyr::mutate(dim2 = stringr::str_to_title(
                  stringr::str_remove(dim2, 
                                      "Amount.+for[:blank:]"
                  )
                ),
                dim2 = stringr::str_remove(dim2,
                                           "[:blank:]\\([:symbol:]\\)"
                )
  ) |>
  
  tidyr::pivot_wider(
    names_from = dim2,
    values_from = amount
  ) |>
  
  dplyr::filter(
    dplyr::if_any((1:2), ~ .x > 0 & !is.na(.x)
    )
  ) |>
  
  tidyr::pivot_longer(
    cols = !(1),
    names_to = "dim2",
    values_to = "amount") |>
  
  dplyr::mutate(
    amount_mil = amount/1e+06
  )

  
#### Operating Budget ####

OP_budget <- question_list$Q25 |>
    
    tidyr::pivot_longer(
      cols = !(1:2),
      names_to = "Question",
      values_to = "amount"
    ) |>
    
    dplyr::mutate(amount = as.numeric(amount)) |>
    
    dplyr::group_by(`Institution Name`) |>
    
    dplyr::summarise(Total_OP = sum(amount))


#### Non-Operating Budget ####
  
NOP_budget <- question_list$Q26 |>
    tidyr::pivot_longer(
      cols = !(1:2),
      names_to = "Question",
      values_to = "amount"
    ) |>
    dplyr::left_join(
      keyFunction('Q26',dim1,dim2)
    ) |>
    
    dplyr::select(!Question) |>
    
    dplyr::mutate(amount = as.numeric(amount)) |>
    
    tidyr::pivot_wider(
      names_from = dim2,
      values_from = amount
    ) |> 
    
    dplyr::rename(intern = "Amount available for funded internships ($)",
                  other = "Other ($)") |>
    apply_budget_override(target_field = "other", override_type = "multiply") |>
    
    dplyr::mutate(
      other = dplyr::case_when(
        !is.na(override_value) ~ other * as.numeric(override_value),
        TRUE ~ other
      )
    ) |>
    dplyr::select(-override_value) |>
    
    dplyr::mutate(sum = intern + other,
                  diff = Total-sum) |> 
    apply_budget_override(target_field = "total_correct", override_type = "replace") |>
    
    dplyr::mutate(
      total_correct = dplyr::case_when(
        !is.na(override_value) ~ as.numeric(override_value),
        is.na(sum) ~ Total,
        TRUE ~ sum
      )
    ) |>
    dplyr::select(-override_value) |>
    
    dplyr::group_by(`Institution Name`) |>
    
    dplyr::summarise(Total_NOP = sum(total_correct))

  
#### Combined Budget ####
  
total_budget <- OP_budget |>
    
    dplyr::left_join(NOP_budget) |>
    
    dplyr::mutate(Total_OP = tidyr::replace_na(Total_OP,0)) |>
    
    tidyr::pivot_longer(
      cols = !`Institution Name`,
      names_to = "Budget",
      values_to = "amount"
    ) |>
    
    dplyr::mutate(amount_mil = amount/1e+06) |> 
    
    dplyr::filter(amount > 0)
  


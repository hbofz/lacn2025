# =============================================================================
# 4_viz_intro.R — Introduction section data preparation
# Creates: enroll_data, endow_data
# Consumed by: GeneralReport.Rmd (Introduction section),
#              custom_template.Rmd (Introduction section)
# =============================================================================
library(tidyverse)

enroll_data <- question_list$Q1 |>
  select(1:2) |>
  mutate(enroll = as.numeric(`Undergraduate enrollment`)) |>
  filter(!is.na(enroll))

      

#### Endowment Plot ####


# NOTE: Row 1 of the raw CSV is a Qualtrics metadata/description row 
# (not an actual institution response). It must be removed before analysis.
# If the survey export format changes and this row is no longer present,
# remove or adjust this filter.
endow_data <- lacn_master |>
  dplyr::select(
    `Institution Name`, 
    `Value of endowment assets at the beginning of the fiscal year`) |>
  dplyr::filter(`Institution Name` != "" & !is.na(`Institution Name`)) |>
  mutate(endow = as.numeric(`Value of endowment assets at the beginning of the fiscal year`)) |>
  mutate(endow_bil = endow/1e+09) |>
  dplyr::filter(!is.na(endow))


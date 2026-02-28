library(tidyverse)

#### ---------- LOAD DATA ------------- ####
list.files("data")

lacn_location <- file.path("data","OpsSurveyRawData2.27.26.csv")

# Read in the data

# the line below also removes duplicate columns from the master data
# Columns 239:250 are duplicated "Percent of undergraduate enrollment that are women (DRVEF2023)"
# if the questions/ number of questions change, then you might have to change the numbers
# be sure to use `identical(df1$colname, df2$colname)` to verify 
# that the columns are indeed duplicated

lacn_master <- readr::read_csv(lacn_location, col_select = c(-(239:250))) 

# Update column names so that the numeric columns start with Q and not a number
colnames(lacn_master) <- ifelse(stringr::str_detect(colnames(lacn_master), "^[0-9]"), stringr::str_c("Q", colnames(lacn_master)), colnames(lacn_master))

# Update column names so that coding at the end of names is taken out
colnames(lacn_master) <- ifelse(stringr::str_detect(colnames(lacn_master), ".*\\(.*\\)$"), stringr::str_replace(colnames(lacn_master), " \\(.*\\)$", ""), colnames(lacn_master))

lacn_master <- lacn_master |>
  dplyr::slice(-(2)) |> 
  dplyr::mutate(
    `Institution Name` = dplyr::case_when(
      is.na(`Institution Name`) ~ Q1_2, # If missing, pull from Q1_2
      `Institution Name` == "Brandeis College" ~ "Brandeis University", # correction
      TRUE ~ `Institution Name`
    )
  )


#### ---------- CREATE RESPONSE KEY ----------- ####
response_key_messy <- lacn_master |>
 dplyr::select(Q1_1:Q28) |>
 dplyr::slice(1L)|>
 tidyr::pivot_longer(
   cols = dplyr::everything(),
   names_to = "Question",
   values_to = "Description"
 ) |>
 tidyr::separate(col = Description, into = c("1","2","3","4"),
                 sep = " - ", extra = "drop", fill = "right", remove = FALSE) |>
 tidyr::separate(col = Question, into = c('main','sub','sub2'),
                 sep = "_", extra = "drop", fill = "right", remove = FALSE)


# Save response_key_messy to CSV for review
readr::write_csv(response_key_messy, file.path("data/response_key_messy_26.csv"))

# Load the cleaned response_key from local CSV
# (Adapted from last year's response_key_25.csv — no Google Sheets needed)
response_key <- readr::read_csv(file.path("data/response_key_26.csv"))


#### REFERENCE TABLE of question types ####
# Load question_type from local CSV (no Google Sheets needed)
question_type <- readr::read_csv(file.path("data/question_type_26.csv"))


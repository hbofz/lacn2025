# =============================================================================
# 5_viz_reporting.R — Reporting structure and staffing data preparation
# Creates: reporting_key, reporting_data, steps_data, student_staff_data,
#          student_para_data, student_stustaff_ratio, prof_staff_data,
#          student_prof_ratio, advising_q, prof_advising_data_total,
#          prof_advising_data_FT, prof_employer_data, relations_activities
# Consumed by: GeneralReport.Rmd (Reporting & Staffing sections),
#              custom_template.Rmd, validate_stolaf_report.R
# =============================================================================
library(tidyverse)
library(RColorBrewer)
library(showtext)
library(sysfonts)

# load fonts
tryCatch(
  font_add_google("Source Sans Pro"),
  error = function(e) {
    message("Source Sans Pro not available from Google; using default graphics font.")
  }
)

showtext_auto()


#### Reporting Structure ####

reporting_key <- keyFunction("Q2", Question, dim2) |>
  dplyr::filter(stringr::str_detect(Question, "^Q2_[1-6]$")) |>
  dplyr::distinct(Question, dim2)

reporting_data <- question_list$Q2 |>
  tidyr::pivot_longer(
    cols = tidyselect::matches("^Q2_[1-6]$"),
    names_to = "Question",
    values_to = "selection"
  ) |>
  dplyr::filter(!is.na(selection) & selection != "") |>
  dplyr::count(Question, name = "n") |>
  dplyr::left_join(reporting_key, by = "Question") |>
  dplyr::mutate(
    reporting_option = dplyr::coalesce(dim2, Question),
    reporting_option = stringr::str_remove(reporting_option, ":$"),
    freq = n / dplyr::n_distinct(question_list$Q2$`Institution Name`)
  ) |>
  dplyr::arrange(dplyr::desc(n))



#### Steps Removed ####

steps_data <- question_list$Q3 |>
  dplyr::filter(!is.na(Q3) & Q3 != "") |>
  dplyr::mutate(
    Q3 = stringr::str_remove(Q3, "[:blank:]\\(.+\\)")
  ) |>
  dplyr::count(Q3, name = "n") |>
  dplyr::mutate(freq = n / sum(n))


#### Advisory Boards ####




#### Performance Metrics ####

# rank_data <- question_list$Q5 |>
#   
#   dplyr::filter(dplyr::if_any(.cols = !(1:2), .fns = ~ !is.na(.x))) |>
#   
#   tidyr::pivot_longer(
#     cols = !(1:2),
#     names_to = "Question",
#     values_to = "ranking"
#   ) |>
#   
#   dplyr::left_join(keyFunction('Q5', dim1)) |>
#   
#   dplyr::left_join(all_list$ranking$Q5) |>
#   
#   dplyr::filter(Question != "Q5_13_TEXT") |>
#   
#   dplyr::mutate(ranking = as.numeric(ranking),
#                 dim1 = stringr::str_remove(dim1, "[:blank:]\\(.+\\)"))







#### Student Staff (Total) ####

student_staff_data <- question_list[['Q5']] |>
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "response"
  ) |>
  dplyr::left_join(
    keyFunction('Q5', dim1,dim2)
  ) |>
  dplyr::mutate(response = as.numeric(response)) |>
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(n = sum(response, na.rm = TRUE)) |>
  dplyr::filter(n > 0 & !is.na(n))



#### Student Staff (Paraprofessional) ####

student_para_data <- question_list[['Q5']] |> 
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "response"
  ) |> 
  dplyr::left_join(
    keyFunction('Q5', dim1,dim2)
  ) |> 
  dplyr::mutate(response = as.numeric(response)) |>
  dplyr::filter(dim1 == "Students in paraprofessional roles (peer advisors)") |> 
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(n = sum(response, na.rm = TRUE)) |>
  dplyr::filter(n > 0 & !is.na(n))


#### Student to Student Staff Ratio ####

student_stustaff_ratio <- student_staff_data |>
  
  left_join(question_list$Q5[1:2]) |>
  
  mutate(ratio = as.numeric(`Undergraduate enrollment`)/n) |>
  
  dplyr::select(`Institution Name`,
                ratio) |>
  dplyr::mutate(n=ratio, .keep = "unused") |>
  dplyr::filter(!is.na(n) & n > 0 & !is.infinite(n))

#### Professional Staff ####

prof_staff_data <- question_list[['Q6']] |>
  dplyr::select(`Institution Name`,Q6_1_10) |>
  dplyr::mutate(n = as.numeric(Q6_1_10), .keep = "unused") |>
  dplyr::filter(n > 0 & !is.na(n) & !is.infinite(n))



#### Student to Professional Staff Ratio ####

student_prof_ratio <- question_list[['Q6']] |>
  dplyr::select(`Institution Name`,
                `Undergraduate enrollment`,
                Q6_1_10) |>
  dplyr::mutate(n = as.numeric(Q6_1_10),
                enroll = as.numeric(`Undergraduate enrollment`),
                ratio = round(enroll/n),
                .keep = "unused") |>
  dplyr::select(`Institution Name`,
                ratio) |>
  dplyr::mutate(n=ratio, .keep = "unused") |>
  dplyr::filter(!is.na(n) & n > 0 & !is.infinite(n))


#### Professional Advising (any amount of time) ####

advising_q <- keyFunction('Q7',dim1,dim2)|>
  filter(dim2=="Total # of staff involved" & dim1 == "Student Counseling/Advising") |>
  pull(Question)

prof_advising_data_total <- question_list$Q7 |>
  
  select(`Institution Name`, all_of(advising_q)) |>
  dplyr::mutate(n = as.numeric(Q7_1_1), .keep = "unused") |>
  filter(n > 0 & !is.na(n) & !is.infinite(n))


advising_q <- keyFunction('Q7',dim1,dim2)|>
  filter(dim2=="# FT staff primarily dedicated" & dim1 == "Student Counseling/Advising") |>
  pull(Question)

prof_advising_data_FT <- question_list$Q7 |>
  
  select(`Institution Name`, all_of(advising_q)) |>
  dplyr::mutate(n = as.numeric(Q7_1_2), .keep = "unused") |>
  filter(n > 0 & !is.na(n) & !is.infinite(n))



#### Professional Employer Relations ####


prof_employer_data <- question_list$Q7 |> 
  select(-"Undergraduate enrollment") |>
  mutate(across(starts_with("Q7_"), as.numeric)) 

#prof_employer_data_FT <- question_list$Q7 |>
 # dplyr::select(`Institution Name`, Q7_8_2) |>
  #dplyr::mutate(n = as.numeric(Q7_8_2), .keep = "unused") |>
  #dplyr::filter(n > 0 & !is.na(n) & !is.infinite(n))



#### Employer Relations Activities #### 

relations_activities <- question_list$Q19 |>
  dplyr::select(`Institution Name`, Q19_5_1, Q19_5_2) |>
  dplyr::mutate(`On Campus` = as.numeric(Q19_5_1), 
                `Virtual` = as.numeric(Q19_5_2), .keep = "unused") |>
  dplyr::filter(!(`On Campus` == 0 & 
                `Virtual` == 0) & 
                !is.na(`On Campus`) &
                !is.na(`Virtual`) & 
                !is.infinite(`Virtual`) & 
                !is.infinite(`On Campus`))
  
  




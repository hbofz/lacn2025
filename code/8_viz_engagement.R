# =============================================================================
# 8_viz_engagement.R — Student and alumni engagement data preparation
# Creates: sengage_year_data, sengage_type_data, appt_student_data,
#          appt_alum_data, appt_fte_data, exper_learning_data
# Consumed by: GeneralReport.Rmd (Engagement sections),
#              custom_template.Rmd, validate_stolaf_report.R
# =============================================================================
library(tidyverse)


## See sengage-year-plot code chunk

sengage_year_data <- question_list$Q23 |> 
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = c('main','sub1','sub2'),
    values_to = "engage",
    names_sep = "_"
  ) |>
  dplyr::filter(sub2==4) |>
  dplyr::mutate(Question = paste(main,sub1,sub2, sep = "_")) |>
  dplyr::left_join(
    keyFunction('Q23',dim1)
  ) |>
  dplyr::select(!c(main:sub2,Question))  |>
  dplyr::mutate(across(`Undergraduate enrollment`:engage, as.numeric))



#### Student Engagement by Type ####

sengage_type_data <- question_list$Q23 |> 
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = c('main','sub1','sub2'),
    values_to = "engage",
    names_sep = "_"
  ) |>
  dplyr::mutate(Question = paste(main,sub1,sub2, sep = "_")) |>
  dplyr::left_join(
    keyFunction('Q23',dim1,dim2)
  )



#### Appt w/ Student (dist) ####


appt_student_data <- question_list$Q22 |>
  
  #initial matrix cleaning
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = c('main','sub1','sub2'),
    values_to = "engage",
    names_sep = "_"
  ) |>
  dplyr::mutate(Question = paste(main,sub1,sub2, sep = "_")) |>
  dplyr::left_join(
    keyFunction('Q22',dim1, dim2)
  ) |> 
  
  # mutate strings and engage chr to num
  dplyr::mutate(Year = stringr::str_to_title(
    stringr::str_extract(dim1,"(?<=with[:blank:]).+(?=[:blank:]by)")
  )
  )|>
  dplyr::mutate(Year = stringr::str_replace(Year, 
                                            "(?<![:blank:])Students", 
                                            "Total (all classes)")) |>
  dplyr::mutate(Year = stringr::str_remove(Year, "[:blank:]Students")) |>
  
  #filter out alum and total
  dplyr::filter(Year != "Alumni" & Year != "Total (all classes)") |>
  
  dplyr::mutate(Year = factor(Year, levels = c(
    "First-Year",
    "Sophomore",
    "Junior",
    "Senior")
  )
  ) |>
  dplyr::mutate(engage = as.numeric(engage)) |> 
  
  dplyr::filter(dim2 != "Total # of email consultations") |>
  
  
  # group and summarise total appts at each college by year
  dplyr::group_by(`Institution Name`, Year) |>
  dplyr::summarise(Appt = sum(engage)) |>
  dplyr::filter(Appt != 0 &!is.na(Appt))


# stacked bar chart (see appt-student-dist-plot code chunk)






#### Appt Alumni ####

appt_alum_data <- question_list$Q22 |>
  
  #initial matrix cleaning
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = c('main','sub1','sub2'),
    values_to = "engage",
    names_sep = "_"
  ) |>
  dplyr::mutate(Question = paste(main,sub1,sub2, sep = "_")) |>
  dplyr::left_join(
    keyFunction('Q22',dim1, dim2)
  ) |> 
  
  # mutate strings and engage chr to num
  dplyr::mutate(Year = stringr::str_to_title(
    stringr::str_extract(dim1,"(?<=with[:blank:]).+(?=[:blank:]by)")))|>
  
  dplyr::mutate(Year = stringr::str_replace(Year, 
                                            "(?<![:blank:])Students", 
                                            "Total (all classes)")) |>
  dplyr::mutate(Year = stringr::str_remove(Year, "[:blank:]Students")) |>
  
  dplyr::mutate(dim2 = stringr::str_to_title(
    stringr::str_remove(dim2, "Total # of[:blank:]"))
  )|>
  
  dplyr::mutate(dim2 = stringr::str_replace(dim2, "[:blank:]\\(In-Person, Phone, Video Chat\\)","\\*")) |>
  
  dplyr::mutate(engage = as.numeric(engage)) |>
  
  dplyr::select(`Institution Name`,dim1,dim2,Year,engage) |>
  
  tidyr::pivot_wider(
    names_from = dim2,
    values_from = engage
  ) |>
  dplyr::filter(
    dplyr::if_any((4:5), ~ .x > 0 & !is.na(.x)
    )
  ) |>
  
  tidyr::pivot_longer(
    cols = !(1:3),
    names_to = "dim2",
    values_to = "engage"
  ) |>
  
  #filter to only alumni
  dplyr::filter(Year == "Alumni") |>
  
  dplyr::mutate(engage = tidyr::replace_na(engage,0))




#### Prof Staff Appts + Emails per FTE ####



appt_fte_data <- question_list$Q22 |> 
  select(`Institution Name`, Q22_5_1:Q22_6_2) |>
  tidyr::pivot_longer(
    cols = !(1),
    names_to = "Question",
    values_to = "Appt"
  ) |>
  dplyr::mutate(Appt = as.numeric(Appt)) |>
  
  dplyr::group_by(`Institution Name`) |>
  dplyr::summarise(Appt = sum(Appt)) |>
  
  dplyr::left_join(prof_staff_data) |> 
  
  dplyr::filter(Appt != 0 & !is.na(Appt),
                n != 0 & !is.na(n)) |>
  
  dplyr::mutate(ratio = Appt/n)




#### Experiential Learning ####

exper_learning_data <- question_list$Q24 |>
  tidyr::pivot_longer(
    cols = !(1:2),
    names_to = "Question",
    values_to = "exper"
  ) |>
  #dplyr::mutate(Question = paste(main,sub1,sub2, sep = "_")) |>
  dplyr::left_join(
    keyFunction('Q24',dim1)
  ) |>
  dplyr::select(`Institution Name`,dim1,exper) |>
  dplyr::mutate(exper = as.numeric(exper)) |>
  
  dplyr::mutate(dim1 = stringr::str_replace(dim1,
                                            "ANY[:blank:].+$",
                                            "Any Experiential Learning*"))


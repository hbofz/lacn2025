#### ------- LIST of dfs for each question ------- ####

# preallocate list vector
question_list <- vector(mode = "list", length = 28)


for(i in seq_len(nrow(question_type))) {
  
  question <- question_type$unique[i]
  
  current_question <- lacn_master |>
    dplyr::select(
      `Institution Name`, 
      `Undergraduate enrollment`, 
      dplyr::starts_with(question)
    ) |>
    dplyr::slice(-1)
  
  question_list[[i]] <- current_question
  
  remove(current_question, question, i)
}

names(question_list) <- question_type$unique

# clean questions 1, 2 and 3
#This is done because of the nature of starts_with(). For instance Q1 and Q10 are
#identified as same questions. Hence the cleaning. 

question_list$Q1 <- question_list$Q1[, 1:5]  # Institution Name + Undergrad enrollment + Q1_1, Q1_3, Q1_2
question_list$Q2 <- question_list$Q2[, 1:9]  # Institution Name + Undergrad enrollment + Q2_1 through Q2_6 + Q2_6_TEXT (multi-select in 2026)
question_list$Q3 <- question_list$Q3[, 1:3]  # Institution Name + Undergrad enrollment + Q3




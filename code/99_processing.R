
#### -------- ANALYZE responses ----- ####

# Select only the types that have analysis functions (exclude text and ranking)
all_questions <- unique(question_type$q_type)
all_questions <- all_questions[all_questions %in% c("single", "multi", "matrix", "continuous")]

all_list <- map(all_questions,
                ~ analyzeFunction(
                  .x
                )
)

names(all_list) <- all_questions


#### Rank - summarise ####

# rank_questions <- selectFunction("ranking")
# 
# rank_key <- keyFunction(rank_questions, dim1) |>
#   dplyr::slice(-12)
# 
# rank_list <- question_list$Q5 |>
#   dplyr::mutate_at(vars(Q5_6:Q5_13), as.numeric) |>
#   dplyr::summarise_at(
#     dplyr::vars(Q5_6:Q5_13),
#     mean,
#     na.rm = TRUE
#   ) |>
#   tidyr::pivot_longer(
#     cols = everything(),
#     names_to = "Question",
#     values_to = "ranking_avg"
#   ) |>
#   dplyr::left_join(rank_key)|>
#   dplyr::relocate(dim1, .before = ranking_avg)
# 
# ranking <- list('Q5' = rank_list)
# 
# all_list[['ranking']] <- ranking




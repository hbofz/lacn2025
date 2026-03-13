#### -------- ANALYZE responses ----- ####

analysis_types <- c("single", "multi", "matrix", "continuous")
available_types <- unique(question_type$q_type)

all_questions <- analysis_types[analysis_types %in% available_types]

all_list <- purrr::map(all_questions, ~ analyzeFunction(.x))
names(all_list) <- all_questions

# Ensure each expected analysis bucket exists for downstream scripts.
for (type in analysis_types) {
  if (!type %in% names(all_list)) {
    all_list[[type]] <- list()
  }
}

#### Rank - NOTE ####
# The ranking question (Q5) was repurposed in 2025-26 to "Student Staff"
# (student employee appointments). The old ranking visualization is no longer
# applicable. If a ranking question is re-introduced in a future cycle, add
# "ranking" to the analysis_types vector above and implement a rankingFunction
# in 99_processing_functions.R.

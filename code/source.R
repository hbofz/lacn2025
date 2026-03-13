library(tidyverse)

source(file.path("code", "00_cycle_config.R"))
cycle_config <- ensure_cycle_config()

scripts <- c(
  "1_read_data.R",
  "2_clean.R",
  "3_functions.R",
  "99_processing_functions.R",
  "99_processing.R",
  "4_viz_intro.R",
  "5_viz_reporting.R",
  "6_viz_services.R",
  "7_viz_employer.R",
  "8_viz_engagement.R",
  "9_viz_budget.R"
)

for (script in scripts) {
  message(sprintf("Sourcing %s", script))
  source(file.path("code", script))
}

save.image(file = cycle_config$rdata_path)
message(sprintf("Saved analysis workspace to %s", cycle_config$rdata_path))

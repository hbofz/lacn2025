#!/usr/bin/env Rscript

library(tidyverse)

source(file.path("code", "00_cycle_config.R"))

args <- commandArgs(trailingOnly = TRUE)
cycle_arg <- args[stringr::str_detect(args, "^--cycle=")]
cycle_id <- if (length(cycle_arg) > 0) {
  stringr::str_remove(cycle_arg[[1]], "^--cycle=")
} else {
  Sys.getenv("LACN_CYCLE_ID", "26")
}

cycle_config <- load_cycle_config(cycle_id = cycle_id)
assign("cycle_config", cycle_config, envir = .GlobalEnv)

message(sprintf("Running full pipeline for cycle %s", cycle_config$cycle_id))

source(file.path("code", "source.R"))

if (!dir.exists(cycle_config$custom_output_dir)) {
  dir.create(cycle_config$custom_output_dir, recursive = TRUE)
}

message("Rendering GeneralReport")
rmarkdown::render(
  input = cycle_config$general_report_rmd,
  output_file = file.path(dirname(cycle_config$general_report_rmd), "GeneralReport.html"),
  quiet = TRUE,
  envir = .GlobalEnv
)

message("Rendering custom school reports")
source(file.path("code", "99_custom_exe.R"))

message("Rendering site home page")
rmarkdown::render(
  input = cycle_config$index_rmd,
  output_file = file.path(dirname(cycle_config$index_rmd), "docs", "index.html"),
  quiet = TRUE,
  envir = .GlobalEnv
)

message("Pipeline complete.")

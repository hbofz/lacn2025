if (!exists("ensure_cycle_config", mode = "function")) {
  source(file.path("code", "00_cycle_config.R"))
}

cycle_config <- ensure_cycle_config()

load(cycle_config$rdata_path)

# Extract all valid institution names for this cycle.
colleges <- clean_institution_names(question_list$Q1$`Institution Name`)

# Keep output file naming consistent with historical convention.
remove_whitespace <- function(x) sanitize_school_filename(x)

output_dir <- cycle_config$custom_output_dir
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Remove stale render artifacts so output count reflects the active cycle only.
unlink(file.path(output_dir, "*.html"))
unlink(file.path(output_dir, "*_files"), recursive = TRUE)

for (college in colleges) {
  message(sprintf("Rendering custom report: %s", college))

  output_file <- file.path(
    output_dir,
    paste0(remove_whitespace(college), ".html")
  )

  rmarkdown::render(
    input = cycle_config$custom_report_rmd,
    params = list(college = college),
    output_file = output_file,
    clean = TRUE,
    quiet = TRUE
  )
}

message(sprintf("Rendered %d custom report(s).", length(colleges)))

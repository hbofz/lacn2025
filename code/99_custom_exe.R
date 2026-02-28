# 99_custom_exe.R — Batch render custom reports for all institutions
#
# USAGE:
#   source("code/99_custom_exe.R")
#   (or run from terminal: Rscript code/99_custom_exe.R)
#
# PREREQUISITES:
#   - Must run source.R first (or have lacn.RData up to date)
#   - The docs/custom/ directory will be created if it doesn't exist

load("lacn.RData")

# Extract all college names from the processed data
colleges <- unique(question_list$Q1$`Institution Name`)
colleges <- colleges[!is.na(colleges) & colleges != ""]

cat("Found", length(colleges), "institutions to process:\n")
print(colleges)

# Create output directory if needed
output_dir <- file.path(getwd(), "docs")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Define a function to create file-safe names
safe_filename <- function(x) gsub("[^A-Za-z0-9]", "_", x)

# Loop through all colleges and render a custom report for each
for (i in seq_along(colleges)) {
  college <- colleges[i]
  output_file <- paste0(safe_filename(college), ".html")

  cat("\n[", i, "/", length(colleges), "] Rendering:", college, "->", output_file, "\n")

  tryCatch(
    {
      rmarkdown::render(
        input = "docs/custom_template.Rmd",
        params = list(college = college),
        output_file = output_file,
        output_dir = output_dir,
        clean = TRUE,
        quiet = TRUE
      )
      cat("  ✓ Success\n")
    },
    error = function(e) {
      cat("  ✗ FAILED:", conditionMessage(e), "\n")
    }
  )
}

cat("\n========================================\n")
cat("Done! Generated", length(colleges), "reports in", output_dir, "\n")

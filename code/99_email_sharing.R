# =============================================================================
# LEGACY UTILITY — DISABLED.
# This project now uses a local-only workflow. Custom reports are consumed
# directly from docs/custom/*.html after the pipeline runs.
# =============================================================================

source(file.path("code", "00_cycle_config.R"))
cycle_config <- ensure_cycle_config()

stop(
  sprintf(
    paste(
      "Remote Google Drive/Sheets sharing is disabled.",
      "Use the locally generated HTML reports in %s instead."
    ),
    cycle_config$custom_output_dir
  ),
  call. = FALSE
)

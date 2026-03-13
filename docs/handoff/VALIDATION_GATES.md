# VALIDATION_GATES

These gates are mandatory and blocking. Do not publish unless all gates pass.

## Gate 1: Schema Gate (Blocking)
Goal:
- Confirm raw CSV and metadata load without missing required fields.
- Confirm `data/schema_check_YY.csv` exists and has zero failed checks.

Run:

```bash
Rscript code/run_cycle.R --cycle=YY
```

Check pass/fail rows:

```bash
YY=26 Rscript -e 'yy <- Sys.getenv("YY"); p <- sprintf("data/schema_check_%s.csv", yy); if (!file.exists(p)) stop(sprintf("Missing %s", p)); s <- read.csv(p, stringsAsFactors = FALSE); passed <- tolower(as.character(s$passed)) == "true"; cat("schema rows:", nrow(s), "failed:", sum(!passed), "\n"); if (any(!passed)) { print(s[!passed, c("check", "detail")]); quit(status = 1) }'
```

Pass criteria:
- `data/schema_check_YY.csv` exists.
- Every row has `passed = TRUE`.

## Gate 2: Render Gate (Blocking)
Goal:
- Confirm general report exists.
- Confirm custom report count matches cleaned institution count from `lacn.RData`.

Run:

```bash
YY=26 Rscript -e 'source("code/00_cycle_config.R"); cfg <- load_cycle_config(cycle_id = Sys.getenv("YY")); if (!file.exists("docs/GeneralReport.html")) stop("Missing docs/GeneralReport.html"); load(cfg$rdata_path); inst <- unique(question_list$Q1$`Institution Name`); inst <- trimws(inst); inst <- inst[!is.na(inst) & inst != "" & !inst %in% c("Institution Name", "{\"ImportId\":\"Institution Name\"}")]; expected <- length(inst); actual <- length(list.files(cfg$custom_output_dir, pattern = "\\.html$")); cat("expected custom:", expected, "actual:", actual, "\n"); if (expected != actual) quit(status = 1)'
```

Pass criteria:
- `docs/GeneralReport.html` exists.
- `length(docs/custom/*.html) == number of cleaned institutions`.

## Gate 3: Cycle Output Gate (Blocking)
Goal:
- Confirm contract-backed report text and critical custom-report values are rendered for the active cycle.

Run:

```bash
Rscript code/validate_cycle_outputs.R --cycle=YY
```

Expected output:
- `data/cycle_validation_YY.csv`

Fail behavior:
- Script exits with non-zero status if any row is `FAIL`.

Pass criteria:
- Output CSV exists.
- All `status` values are `PASS`.

## Gate 4: St. Olaf Gate (Blocking)
Goal:
- Confirm St. Olaf report values align with generated analysis outputs.

Run:

```bash
LACN_CYCLE_ID=YY Rscript code/validate_stolaf_report.R
```

Expected output:
- `data/stolaf_validation_YY.csv`

Fail behavior:
- Script exits with non-zero status if any row is `FAIL`.

Pass criteria:
- Output CSV exists.
- All `status` values are `PASS`.

## Gate 5: Publish Artifact Gate (Blocking)
Goal:
- Confirm site artifacts are complete and no stale custom files remain.

Run:

```bash
YY=26 Rscript -e 'source("code/00_cycle_config.R"); cfg <- load_cycle_config(cycle_id = Sys.getenv("YY")); load(cfg$rdata_path); inst <- unique(question_list$Q1$`Institution Name`); inst <- trimws(inst); inst <- inst[!is.na(inst) & inst != "" & !inst %in% c("Institution Name", "{\"ImportId\":\"Institution Name\"}")]; expected <- paste0(vapply(inst, sanitize_school_filename, character(1)), ".html"); actual <- list.files(cfg$custom_output_dir, pattern = "\\.html$", full.names = FALSE); stale <- setdiff(actual, expected); missing <- setdiff(expected, actual); if (!file.exists("docs/index.html")) stop("Missing docs/index.html"); if (!file.exists("docs/GeneralReport.html")) stop("Missing docs/GeneralReport.html"); if (length(actual) == 0) stop("No custom HTML files found in docs/custom"); if (length(stale) > 0) cat("Stale custom files:", paste(stale, collapse = ", "), "\n"); if (length(missing) > 0) cat("Missing custom files:", paste(missing, collapse = ", "), "\n"); if (length(stale) > 0 || length(missing) > 0) quit(status = 1); cat("Publish artifact gate PASS\n")'
```

Pass criteria:
- `docs/index.html` exists.
- `docs/GeneralReport.html` exists.
- `docs/custom/*.html` exists.
- No stale prior-cycle custom files remain in `docs/custom/`.

## Release Policy
If any gate fails:
- Release is blocked.
- Fix the issue.
- Re-run the failed gate(s) and record the passing output.

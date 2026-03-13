# TROUBLESHOOTING

This guide covers known operational failures and concrete recovery steps.

## 1) Plot/Text Overlap in HTML Reports
Symptoms:
- Labels overlap bars.
- Axis text appears too large.
- Charts look compressed in custom reports.

Fix sequence:
1. Reset browser zoom to 100% and hard refresh.
2. Rebuild the cycle from scratch:

```bash
Rscript code/run_cycle.R --cycle=YY
```

3. Open the regenerated file from `docs/custom/` (not an old copied file).
4. If still overlapping, confirm the section still has `fig.width`/`fig.height` set in the Rmd chunk for that plot.
5. If needed, lower extreme text sizes in the affected plot theme and rerender.

## 2) Missing Columns / Schema Validation Failure
Symptoms:
- Pipeline stops in `1_read_data.R`.
- `Schema validation failed` message.

Fix:
1. Open `data/schema_check_YY.csv`.
2. Filter failed rows.
3. Resolve by category:
- `required_column:*`: raw CSV missing required field or renamed.
- `question_columns:*`: `progress_YY.csv` question prefix does not exist in CSV.
- `response_key_question:*`: `response_key_YY.csv` has question codes not found in CSV.
- `duplicate_column:*` with `passed=FALSE`: non-identical duplicate headers found; inspect raw export and correct source file.
4. Re-run:

```bash
Rscript code/run_cycle.R --cycle=YY
```

## 3) Stale Custom Files in `docs/custom/`
Symptoms:
- Old institutions still present.
- Custom report count does not match cleaned institutions.

Fix:
1. Re-run full pipeline (`run_cycle.R`) so `99_custom_exe.R` clears stale HTML and `_files` folders before rendering.
2. Run publish artifact gate from `VALIDATION_GATES.md` to confirm no stale/missing files.

## 4) St. Olaf Validation Fails
Symptoms:
- `code/validate_stolaf_report.R` exits non-zero.
- `data/stolaf_validation_YY.csv` contains `FAIL` rows.

Fix:
1. Open failed rows in `data/stolaf_validation_YY.csv`.
2. Confirm St. Olaf appears in cleaned institution names.
3. Re-check inputs tied to failed section:
- Enrollment
- Appointments with students
- Alumni engagement
- Total funding
- Reporting selection (`Q2_1..Q2_6`)
4. Regenerate reports and rerun validator:

```bash
Rscript code/run_cycle.R --cycle=YY
LACN_CYCLE_ID=YY Rscript code/validate_stolaf_report.R
```

## 5) Cycle Output Validation Fails
Symptoms:
- `code/validate_cycle_outputs.R` exits non-zero.
- `data/cycle_validation_YY.csv` contains `FAIL` rows.

Fix:
1. Open failed rows in `data/cycle_validation_YY.csv`.
2. Re-check the reported artifact or institution-specific HTML file.
3. Confirm the active cycle's report contract still matches `response_key_YY.csv`.
4. Regenerate reports and rerun validator:

```bash
Rscript code/run_cycle.R --cycle=YY
Rscript code/validate_cycle_outputs.R --cycle=YY
```

## 6) Font / Network Warnings During Render
Symptoms:
- Messages about Google font unavailable.

Behavior:
- Non-blocking in current templates (`tryCatch` fallback).
- Reports still render with default local font.

Fix options:
- Continue (acceptable for most runs).
- Re-run with internet access if exact Google font rendering is required.

## 7) Render Completed but `docs/index.html` Missing
Symptoms:
- General/custom reports exist, but site landing page missing.

Fix:
1. Ensure `index.Rmd` exists at repo root.
2. Re-run canonical pipeline command.
3. Confirm output at `docs/index.html`.

## 8) Last-Resort Recovery
If state is unclear:
1. Ensure cycle row in `config/cycles.csv` is correct.
2. Re-run `Rscript code/run_cycle.R --cycle=YY`.
3. Re-run all gates in `VALIDATION_GATES.md`.
4. Publish only after all gates pass.

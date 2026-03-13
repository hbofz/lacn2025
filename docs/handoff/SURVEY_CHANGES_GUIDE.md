# SURVEY_CHANGES_GUIDE

Use this guide when the LACN Operations Survey questions change between cycles.

## 1) Detect What Changed

Compare old and new CSV headers to find additions, removals, and renames:

```bash
# Extract headers from the prior cycle and the new export
head -1 data/OpsSurveyRawData_PRIOR.csv | tr ',' '\n' | sort > /tmp/old_headers.txt
head -1 data/OpsSurveyRawData_NEW.csv   | tr ',' '\n' | sort > /tmp/new_headers.txt

# Show differences
diff /tmp/old_headers.txt /tmp/new_headers.txt
```

Lines starting with `<` are removed; lines starting with `>` are added.

## 2) Update `progress_YY.csv`

Every question in the survey must have a row in `progress_YY.csv`. See `METADATA_FORMAT_REFERENCE.md` for the full format specification.

For each **new question** found in step 1:
1. Add a row with the question prefix (e.g., `Q26`) and the correct `q_type`.
2. Valid `q_type` values: `text`, `single`, `multi`, `matrix`, `continuous`, `ranking`.
3. If the question doesn't fit any existing type, see §5 below.

For each **removed question**:
1. Delete the corresponding row from `progress_YY.csv`.

For each **renamed question** (same intent, different header):
1. Update the `unique` value to match the new header prefix.

## 3) Update `response_key_YY.csv`

Every column in the raw CSV that represents a survey response must have a row in `response_key_YY.csv`. See `METADATA_FORMAT_REFERENCE.md` for the full format specification.

This file is maintained input metadata for the cycle. It is not auto-generated from the raw CSV. In practice, you copy the prior cycle's file, then edit only the rows affected by survey changes.

For each new question column:
1. Add rows following the naming convention: `Question = Q<n>_<sub1>` etc.
2. Fill `main`, `sub1`, `sub2` to decompose the column name.
3. Copy `dim1`, `dim2`, `dim3` from the prior cycle if the question structure is the same; otherwise define new dimension labels matching the survey wording.

> [!TIP]
> Start by copying the prior cycle's `response_key_YY.csv`, removing rows for deleted questions, and adding rows for new ones. This avoids re-entering unchanged questions. Do not confuse this file with `data/response_key.csv`, which is only a generated snapshot written after the pipeline runs.

## 4) Verify with Schema Gate

After updating both files, run the pipeline and check the schema report:

```bash
Rscript code/run_cycle.R --cycle=YY
```

Inspect failures:

```bash
cat data/schema_check_YY.csv
```

Common failure categories:
- `question_columns:Q<n>` — `progress_YY.csv` lists a question not found in the CSV.
- `response_key_question:Q<n>_<x>` — `response_key_YY.csv` references a column not in the CSV.
- `required_column:*` — a hard-coded required column is missing from the CSV.

Fix metadata, re-run, repeat until `schema_check_YY.csv` shows all `passed = TRUE`.

## 5) Handling a New Question Type

If a new question doesn't match the five known types (`text`, `single`, `multi`, `matrix`, `continuous`, `ranking`):

1. Define the new type name in `progress_YY.csv`.
2. Add a processing function in `code/99_processing_functions.R`:
   - Follow the pattern of existing functions (e.g., `singleFunction`, `multiFunction`).
   - The function should accept a question data frame and return a summarized tibble.
3. Register the new type in `code/99_processing.R` so `analyzeFunction` dispatches to it.
4. Add a visualization function in `code/3_functions.R` if the type needs a new chart format.
5. Add the visualization call in the appropriate `code/*_viz_*.R` script.
6. Add the report section in both `docs/GeneralReport.Rmd` and `docs/custom_template.Rmd`.

## 6) Q2 Multi-Select Contract

Since the 2025-26 cycle, **Q2 is multi-select** (columns `Q2_1..Q2_6`). The pipeline code, visualization, and custom reports all depend on this.

If Q2 options change (add/remove choices):
1. Update `response_key_YY.csv` rows for Q2.
2. Re-run schema gate and St. Olaf gate.
3. Check `code/5_viz_reporting.R` for any hardcoded Q2 sub-column references.

If Q2 reverts to single-select, this is a **breaking change** — update `progress_YY.csv` type to `single` and audit all visualization code referencing Q2.

## 7) Offset Errors

Survey changes often introduce "offset errors" where column indices shift. The pipeline mitigates this by matching columns by name (not position), but watch for:
- Visualization scripts that reference `dim1`/`dim2` values by literal string — these must match the new survey wording from `response_key_YY.csv`.
- Custom report sections that filter on specific response labels.

When in doubt, search the codebase for the old label:

```bash
grep -rn "OLD_LABEL_TEXT" code/ docs/
```

## 8) Positional Column Indexing (Critical Awareness)

> [!CAUTION]
> Many scripts use positional column references like `cols = !(1:2)` or `(4:5)` instead of named columns. These assume that **columns 1 and 2 are always `Institution Name` and `Undergraduate enrollment`**.

If the survey export changes the position of these columns (e.g., adding a new column before them), the pipeline will silently produce wrong results — not crash.

**Affected files** (non-exhaustive):
- `2_clean.R` — `dplyr::select(…, dplyr::all_of(question_cols))` uses `1:2` to keep Institution Name + enrollment
- `5_viz_reporting.R` — several `!(1:2)` and `(4:5)` references
- `7_viz_employer.R` — `if_any((4:5), …)`
- `8_viz_engagement.R` — `!(1:2)` in multiple pivot operations
- `9_viz_budget.R` — `!(1:2)` in pivot operations
- `99_processing_functions.R` — `cols_exclude = (1:2)` parameter default

**Mitigation:** Before running a new cycle, confirm that the raw CSV's first two columns are `Institution Name` and `Undergraduate enrollment`. If they aren't, you'll need to update the positional references in the files above.

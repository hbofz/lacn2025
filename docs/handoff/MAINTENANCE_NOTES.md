# MAINTENANCE_NOTES

This file defines maintenance conventions for long-term stability.

## 1) Override Policy

Use cycle-scoped CSVs in `data/`; avoid inline one-off code edits.

### Institution name overrides
File: `data/institution_overrides_YY.csv`
Required columns:
- `from_institution`
- `to_institution`
- `reason`

### Employer value overrides
File: `data/value_overrides_employer_YY.csv`
Required columns:
- `dataset` (`info_no_data` or `info_employ_data`)
- `institution_name`
- `dim2`
- `amount`
- `reason`

### Budget value overrides
File: `data/value_overrides_budget_YY.csv`
Required columns:
- `institution_name`
- `dim1`
- `target_field` (`other` or `total_correct`)
- `override_type` (`multiply` or `replace`)
- `override_value`
- `reason`

Rules:
- Keep each override row auditable with a specific reason.
- Never change historical cycle override files after release unless a correction is formally approved.
- Keep overrides minimal and deterministic.

## 2) Schema Evolution Rules

Cycle schema is controlled by:
- Raw CSV columns
- `response_key_YY.csv`
- `progress_YY.csv`

For a full reference of all metadata file formats and valid values, see `METADATA_FORMAT_REFERENCE.md`.

Current extraction rule:
- Question matching uses exact prefix pattern: `^Qn(_|$)`.
- This prevents collisions like `Q2` matching `Q20`.

If survey provider changes headers:
1. Follow `SURVEY_CHANGES_GUIDE.md` to update metadata files.
2. Re-run schema gate.
3. Adjust downstream code only if metadata-aligned schema still fails.

## 3) Q2 Contract (Critical)

For 2025-26 onward:
- `Q2` is multi-select, represented by `Q2_1..Q2_6`.
- Do not reintroduce legacy single-column Q2 assumptions.

Any future Q2 option changes require:
- Updated `response_key_YY.csv` rows.
- Re-run of schema and St. Olaf gates.

See `SURVEY_CHANGES_GUIDE.md` §6 for the full Q2 change protocol.

## 4) Data File Naming Convention

Raw survey exports placed in `data/` should follow:
```
OpsSurveyRawData_YYYY.csv
```

The exact filename is tracked in `config/cycles.csv`, so the pipeline doesn't enforce the convention — but consistent naming makes the project navigable.

Historical data files with varying names (e.g., `RawData2.6.24.csv`) are kept for backwards compatibility but should not be used as a naming template.

## 5) `response_key.csv` (No Year Suffix)

The unsuffixed `data/response_key.csv` is a **pipeline-generated snapshot** written by `1_read_data.R` at the end of each run. It is a convenience copy of the active cycle's `response_key_YY.csv`.

- Do not manually edit `response_key.csv`.
- Always edit `response_key_YY.csv` instead.
- The unsuffixed file will be overwritten on the next pipeline run.

## 6) When to Add New Validators

Add/extend validator scripts when any of these is true:
- A metric drives executive decisions and must be traceable.
- A section changes logic (new transformations, new override behavior).
- A known institution-level discrepancy recurs.
- A schema change can silently pass but produce wrong plots/tables.

Validator requirements:
- Deterministic output file in `data/`.
- Explicit `PASS`/`FAIL` per check.
- Non-zero exit on any failure.

## 7) Logging and Audit Expectations

Pipeline should log:
- Applied override counts.
- Schema report path.
- Rendered custom report count.
- Validation output paths.

For each release commit, include:
- Cycle ID.
- Config and metadata updates.
- Validation artifacts (`schema_check_YY.csv`, `stolaf_validation_YY.csv`).

## 8) Safe Change Strategy

For non-trivial maintenance work:
1. Change one stage at a time.
2. Re-run full cycle build.
3. Re-run all validation gates.
4. Only then publish.

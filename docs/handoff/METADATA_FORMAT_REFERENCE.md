# METADATA_FORMAT_REFERENCE

Definitive reference for every metadata file used by the LACN pipeline.

---

## `progress_YY.csv`

Maps each survey question to its processing type.

### Columns

| Column | Required | Description |
|---|---|---|
| `unique` | Yes | Question prefix (e.g., `Q2`, `Q7`, `Q36`). Must exactly match the column prefix in the raw CSV. |
| `q_type` | Yes | Processing type. Controls which analysis function is applied. |
| `Notes` | No | Free-text annotation for the operator. Not used by code. |

### Valid `q_type` Values

| Type | Meaning | Example |
|---|---|---|
| `text` | Open-ended or metadata fields. Not analyzed/visualized. | Q1 (respondent info) |
| `single` | Single-choice question. One response per institution. | Q3 (steps from President) |
| `multi` | Multi-select question. Multiple sub-columns (`Q<n>_1`, `Q<n>_2`, …). | Q2 (reporting structure) |
| `matrix` | Grid/matrix question. Sub-columns use `Q<n>_<row>_<col>` pattern. | Q6 (student employees) |
| `continuous` | Numeric input. Sub-columns follow `Q<n>_<row>_<col>` pattern. | Q7 (FTE staff counts) |
| `ranking` | Ordinal ranking. Respondents rank items 1–N. | Q5 (priority ranking) |

### Example Rows

```csv
unique,q_type,Notes
Q1,text,Respondent and institution metadata
Q2,multi,Reporting structure (multi-select in 2025-26)
Q3,single,Steps removed from President
Q5,ranking,Priority ranking of career center activities
Q6,matrix,Student employee appointments
Q7,continuous,FTE staff counts
```

---

## `response_key_YY.csv`

Maps every survey column to its question structure, description, and dimension labels used by visualizations.

This is a required cycle input metadata file. It is maintained by copying the prior cycle's file and updating it for any survey changes. It is not auto-generated from the raw survey CSV.

### Columns

| Column | Required | Description |
|---|---|---|
| `Question` | Yes | Exact column name from the raw CSV (e.g., `Q2_1`, `Q6_1_2`). |
| `main` | Yes | Parent question prefix (e.g., `Q2`, `Q6`). |
| `sub1` | Yes | First sub-index. `NA` if the question has no sub-parts. |
| `sub2` | Yes | Second sub-index (matrix questions). `NA` if not a matrix. |
| `Description` | Yes | Full question text from the survey. |
| `Notes` | No | Shortened description. Not used by pipeline code directly. |
| `dim1` | Yes | Primary dimension label used in visualizations (e.g., "Selected Choice", "Undergraduate"). |
| `dim2` | No | Secondary dimension label (e.g., specific response option text). |
| `dim3` | No | Tertiary dimension label. Rarely used. |

### Column Name Decomposition

The `Question`, `main`, `sub1`, `sub2` columns decompose the raw CSV column name:

```
Q6_1_2  →  main=Q6, sub1=1, sub2=2
Q2_1    →  main=Q2, sub1=1, sub2=NA
Q3      →  main=Q3, sub1=NA, sub2=NA
```

### Example Rows

```csv
Question,main,sub1,sub2,Description,Notes,dim1,dim2,dim3
Q2_1,Q2,1,NA,To whom do you report? - Selected Choice - Student Affairs,To whom do you report?,Selected Choice,Student Affairs,NA
Q6_1_1,Q6,1,1,Student employment - Undergraduate - Students in paraprofessional roles,Student employment data,Undergraduate,Students in paraprofessional roles,NA
Q7_1_9,Q7,1,9,FTE staff - Total # of staff (headcount),Staffing numbers,Total # of staff (headcount),NA,NA
```

### Key Rules
- `dim1`, `dim2`, `dim3` must be consistent across cycles **if the questions are unchanged**. Visualization code matches on these labels.
- The mapping from `Question` → raw CSV columns must be exact. The schema gate will catch mismatches.

---

## `cycles.csv`

Located at `config/cycles.csv`. Defines all file paths and labels for each survey cycle.

### Columns

| Column | Description |
|---|---|
| `cycle_id` | Short numeric ID (e.g., `26` for 2025-26). Used as `--cycle=` argument. |
| `cycle_label` | Display label for the cycle (e.g., `2025-2026`). |
| `cycle_subtitle` | Subtitle used in report headers (e.g., `2025-26 LACN Operations Survey`). |
| `raw_data_file` | Relative path to raw survey CSV (e.g., `data/OpsSurveyRawData2.27.26.csv`). |
| `response_key_file` | Relative path to response key CSV (e.g., `data/response_key_26.csv`). |
| `progress_file` | Relative path to progress/question-type CSV (e.g., `data/progress_26.csv`). |
| `schema_report_file` | Output path for schema validation report (e.g., `data/schema_check_26.csv`). |
| `institution_overrides_file` | Path to institution name overrides CSV. |
| `employer_overrides_file` | Path to employer value overrides CSV. |
| `budget_overrides_file` | Path to budget value overrides CSV. |
| `rdata_file` | Output path for the R workspace image (e.g., `lacn.RData`). |
| `general_report_rmd` | Path to GeneralReport RMarkdown template. |
| `custom_report_rmd` | Path to custom school report RMarkdown template. |
| `index_rmd` | Path to the site landing page RMarkdown. |
| `custom_output_dir` | Directory for rendered custom school HTML files. |

### Adding a New Cycle

Copy the previous row and update:
- `cycle_id` to the new 2-digit year.
- All `_file` paths to use the new `_YY` suffix.
- `cycle_label` and `cycle_subtitle` to the new year range.

See `CYCLE_ROLLOVER_CHECKLIST.md` §3 for a copy-paste template row.

---

## Override CSVs

Detailed column specifications are in `MAINTENANCE_NOTES.md` §1. Summary:

| File | Key Columns |
|---|---|
| `institution_overrides_YY.csv` | `from_institution`, `to_institution`, `reason` |
| `value_overrides_employer_YY.csv` | `dataset`, `institution_name`, `dim2`, `amount`, `reason` |
| `value_overrides_budget_YY.csv` | `institution_name`, `dim1`, `target_field`, `override_type`, `override_value`, `reason` |

---

## `response_key.csv` (No Year Suffix)

This file is a **pipeline-generated snapshot**. It is written automatically by `1_read_data.R` at the end of each run as a convenience copy of the active cycle's `response_key_YY.csv`.

Important distinction:
- `response_key_YY.csv` = required maintained input for a specific cycle
- `response_key.csv` = generated snapshot output for convenience

Do not manually edit this file. Edit the year-suffixed version instead (`response_key_YY.csv`).

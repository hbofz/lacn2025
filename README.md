# LACN Operations Survey — Reporting Pipeline

This repository builds annual LACN Operations Survey reports from local survey data and metadata. One command ingests raw data, validates schema, runs analysis, and renders publish-ready HTML reports.

---

## Quick Start

```bash
# 1. Install R packages (one time)
Rscript -e 'install.packages(c("tidyverse","rmarkdown","knitr","showtext","sysfonts","htmltools","RColorBrewer","gt","ggrepel"))'

# 2. Run the full pipeline for the current cycle
Rscript code/run_cycle.R --cycle=26

# 3. Run the cycle-wide validator
Rscript code/validate_cycle_outputs.R --cycle=26

# 4. Validate St. Olaf report
LACN_CYCLE_ID=26 Rscript code/validate_stolaf_report.R
```

After the pipeline completes:
- General report → `docs/GeneralReport.html`
- School reports → `docs/custom/*.html`
- Landing page → `docs/index.html`
- Schema check → `data/schema_check_26.csv`
- Cycle validation → `data/cycle_validation_26.csv`

---

## Project Structure

```
lacn2025/
├── config/
│   └── cycles.csv              ← Cycle registry (file paths, labels)
├── code/
│   ├── 00_cycle_config.R       ← Config loader and shared helpers
│   ├── run_cycle.R             ← Entry point: runs full pipeline
│   ├── source.R                ← Sources all scripts in order
│   ├── 1_read_data.R           ← Ingest raw CSV + schema validation
│   ├── 2_clean.R               ← Split data by question
│   ├── 3_functions.R           ← Analysis & visualization functions
│   ├── 99_processing_functions.R  ← Question-type processing
│   ├── 99_processing.R         ← Apply processing to all questions
│   ├── 4_viz_intro.R           ← Intro visualizations
│   ├── 5_viz_reporting.R       ← Reporting & staffing visuals
│   ├── 6_viz_services.R        ← Services & programs visuals
│   ├── 7_viz_employer.R        ← Employer relations visuals
│   ├── 8_viz_engagement.R      ← Student/alumni engagement visuals
│   ├── 9_viz_budget.R          ← Budget visuals
│   ├── 99_custom_exe.R         ← Render all school-level reports
│   ├── 99_email_sharing.R      ← Legacy disabled script (local-only workflow)
│   ├── validate_cycle_outputs.R  ← Cycle-wide output validation script
│   └── validate_stolaf_report.R  ← St. Olaf validation script
├── data/
│   ├── OpsSurveyRawData*.csv   ← Raw survey exports (one per cycle)
│   ├── response_key_YY.csv     ← Question-to-dimension mapping
│   ├── progress_YY.csv         ← Question-to-type mapping
│   ├── institution_overrides_YY.csv  ← Name correction overrides
│   ├── value_overrides_*.csv   ← Employer/budget value overrides
│   ├── schema_check_YY.csv     ← Generated: validation report
│   └── stolaf_validation_YY.csv ← Generated: St. Olaf check
├── docs/
│   ├── GeneralReport.Rmd       ← General report template
│   ├── custom_template.Rmd     ← Per-school report template
│   ├── custom/                 ← Generated: school HTML files
│   ├── handoff/                ← Operator documentation (see below)
│   └── index.html              ← Generated: site landing page
├── archive/                    ← Legacy docs (historical reference only)
├── index.Rmd                   ← Landing page template
├── _site.yml                   ← R Markdown site config
├── lacn.RData                  ← Generated: analysis workspace
└── lacn.Rproj                  ← RStudio project file
```

---

## Prerequisites

- **R 4.2+** with the packages listed in Quick Start above.
- **Git** for version control and GitHub Pages publishing.
- Repository cloned locally with the layout shown above.

---

## How the Pipeline Works

```
run_cycle.R
  ├── source.R (sources all scripts in order)
  │     ├── 1_read_data.R    → loads CSV, validates schema, writes schema_check_YY.csv
  │     ├── 2_clean.R        → splits data into question_list
  │     ├── 3_functions.R    → defines analysis/viz functions
  │     ├── 99_processing*   → applies functions to all questions → all_list
  │     └── *_viz_*.R        → prepares visualization data
  ├── Saves lacn.RData
  ├── Renders GeneralReport.html
  ├── Renders custom/*.html (one per institution)
  └── Renders index.html
```

All paths are driven by `config/cycles.csv` — **no hardcoded file paths** in pipeline code.

---

## Output Lifecycle

The publish pipeline writes to a fixed set of "live" paths each time you run a cycle.

Generated outputs for the active cycle:
- `docs/GeneralReport.html` - overwritten on every full run
- `docs/index.html` - overwritten on every full run
- `docs/custom/*.html` - cleared and regenerated on every full run
- `data/schema_check_YY.csv` - overwritten for that cycle
- `data/cycle_validation_YY.csv` - overwritten for that cycle
- `data/stolaf_validation_YY.csv` - overwritten for that cycle
- `lacn.RData` - overwritten with the latest analysis workspace

What controls those paths:
- `config/cycles.csv` defines the current cycle's templates and `custom_output_dir`
- for cycle `26`, `custom_output_dir` is `docs/custom`

What gets overwritten vs. cleared:
- `code/run_cycle.R` renders the general report directly to `docs/GeneralReport.html`
- `code/run_cycle.R` renders the landing page directly to `docs/index.html`
- `code/99_custom_exe.R` removes existing `*.html` and `*_files` inside `custom_output_dir`, then renders one fresh school report per institution

Important implication:
- the current publish structure preserves only one live set of site HTML at a time
- there is no built-in per-cycle archive folder in the current implementation
- if you need historical HTML preserved, copy it elsewhere before the next full render

---

## Quality Gates (Mandatory Before Publishing)

| Gate | What It Checks | Details |
|---|---|---|
| Schema | Raw CSV + metadata files load without missing fields | `VALIDATION_GATES.md` §1 |
| Render | General + custom reports exist and counts match | `VALIDATION_GATES.md` §2 |
| Cycle Output | Critical rendered values and report-contract mappings are valid | `VALIDATION_GATES.md` §3 |
| St. Olaf | Report values align with analysis outputs | `VALIDATION_GATES.md` §4 |
| Publish | Site artifacts complete, no stale files | `VALIDATION_GATES.md` §5 |

---

## Handoff Documentation

All operator documentation lives in `docs/handoff/`:

| Document | Purpose |
|---|---|
| [OPERATOR_HANDBOOK.md](docs/handoff/OPERATOR_HANDBOOK.md) | End-to-end guide for producing a cycle release |
| [CYCLE_ROLLOVER_CHECKLIST.md](docs/handoff/CYCLE_ROLLOVER_CHECKLIST.md) | Step-by-step checklist for moving to the next cycle |
| [SURVEY_CHANGES_GUIDE.md](docs/handoff/SURVEY_CHANGES_GUIDE.md) | What to do when survey questions change |
| [METADATA_FORMAT_REFERENCE.md](docs/handoff/METADATA_FORMAT_REFERENCE.md) | Column specs for all metadata files |
| [VALIDATION_GATES.md](docs/handoff/VALIDATION_GATES.md) | Mandatory quality checks before publishing |
| [TROUBLESHOOTING.md](docs/handoff/TROUBLESHOOTING.md) | Known failures and concrete fixes |
| [PUBLISH_RUNBOOK.md](docs/handoff/PUBLISH_RUNBOOK.md) | Git + GitHub Pages publishing steps |
| [MAINTENANCE_NOTES.md](docs/handoff/MAINTENANCE_NOTES.md) | Override policies, schema rules, naming conventions |
| [ARCHIVE_readme_legacy_2022.md](docs/handoff/ARCHIVE_readme_legacy_2022.md) | Historical narrative from the original 2022 README |

---

## Starting a New Cycle (Summary)

1. Place raw CSV in `data/` → naming: `OpsSurveyRawData_YYYY.csv`
2. Copy the prior cycle's `response_key_YY.csv` and `progress_YY.csv`, rename them for the new cycle, and update them in `data/`
3. Add a row to `config/cycles.csv`
4. Optionally set `LACN_PUBLICATION_LABEL` if the publish month/year should differ from the current date
5. Run `Rscript code/run_cycle.R --cycle=YY`
6. Run `Rscript code/validate_cycle_outputs.R --cycle=YY`
7. Run all quality gates → `VALIDATION_GATES.md`
8. Publish → `PUBLISH_RUNBOOK.md`

Important distinction:
- `data/response_key_YY.csv` is a maintained cycle input file.
- `data/response_key.csv` is an auto-generated snapshot written by the pipeline.

For the full checklist, see `CYCLE_ROLLOVER_CHECKLIST.md`.

---

## Archive

The `archive/` directory holds legacy documents from prior cycles, preserved for historical reference. These are **not** part of the current workflow. See `archive/README.md` for details.

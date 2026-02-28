# LACN Operations Survey

> **Data from 2025–2026** · 39 participating institutions · Published May 2026

This repository processes the annual [LACN (Liberal Arts Career Network)](http://liberalartscareers.org/) Operations Survey and generates individualized HTML benchmark reports for each participating institution.

---

## Quick Start

**New to this project?** Read the full **[Getting Started Guide](GETTING_STARTED.md)** — it has step-by-step instructions for processing new survey data, generating reports, deploying to GitHub Pages, and troubleshooting common issues.

### Run the pipeline

```bash
# 1. Process the raw survey data
Rscript code/source.R

# 2. Render a single custom report (for testing)
Rscript -e 'rmarkdown::render("docs/custom_template.Rmd",
  output_file = "School_Name.html", output_dir = "docs",
  params = list(college = "School Name"))'

# 3. Batch render all institution reports
Rscript code/99_custom_exe.R
```

---

## Repository Structure

```
lacn2025/
├── code/                       # R scripts (numbered = execution order)
│   ├── source.R                #   Master script — runs everything
│   ├── 1_read_data.R           #   Read raw CSV + create response key
│   ├── 2_clean.R               #   Split data by question
│   ├── 3_functions.R           #   Visualization helper functions
│   ├── 99_processing*.R        #   Analysis functions
│   ├── 4–9_viz_*.R             #   Visualization data prep
│   └── 99_custom_exe.R         #   Batch render all reports
├── data/                       # Survey data + lookup tables
│   ├── OpsSurveyRawData*.csv   #   Raw Qualtrics export
│   ├── response_key_26.csv     #   Question/response labels
│   ├── question_type_26.csv    #   Question type classifications
│   └── archive/                #   Data from prior years
├── docs/                       # Generated HTML reports (output)
│   ├── custom_template.Rmd     #   Parameterized report template
│   └── GeneralReport.Rmd       #   Aggregate report template
├── GETTING_STARTED.md          # ★ Detailed setup & usage guide
└── index.Rmd                   # GitHub Pages landing page
```

## Reports

| Report | Description |
|--------|-------------|
| **General Report** | Aggregate statistics across all institutions |
| **Custom Reports** | One per institution — shows their data highlighted against the aggregate |

## Pipeline Overview

```
Raw CSV  →  1_read_data.R  →  2_clean.R  →  3_functions.R + 99_processing.R
                                                    ↓
                                            4–9_viz_*.R (visualization data)
                                                    ↓
                                              lacn.RData (saved environment)
                                                    ↓
                                    custom_template.Rmd (parameterized per school)
                                                    ↓
                                          School_Name.html (one per institution)
```

## Requirements

- **R** 4.5+ with packages: `tidyverse`, `rmarkdown`, `knitr`, `kableExtra`, `ggrepel`, `showtext`, `sysfonts`, `scales`
- **Pandoc** 3.0+ (bundled with RStudio)

See [GETTING_STARTED.md](GETTING_STARTED.md) for full installation instructions and the year-to-year update checklist.

---

*Data Analysis completed by Hamzah Azzam*

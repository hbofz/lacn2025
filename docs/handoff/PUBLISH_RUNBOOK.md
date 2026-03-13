# PUBLISH_RUNBOOK

Use this runbook to publish your fork's GitHub Pages site after a successful cycle build.

## 1) Remote Strategy (Fork-Friendly)
Expected remotes:
- `origin`: your fork
- `upstream`: original project repository

Check current remotes:

```bash
git remote -v
```

If `upstream` is missing, add it once:

```bash
git remote add upstream <UPSTREAM_REPO_URL>
```

## 2) Sync Branch Before Release

```bash
git fetch upstream
git checkout main
git pull --ff-only upstream main
git pull --ff-only origin main
```

## 3) Generate Release Artifacts
From `lacn2025/`:

```bash
Rscript code/run_cycle.R --cycle=YY
Rscript code/validate_cycle_outputs.R --cycle=YY
LACN_CYCLE_ID=YY Rscript code/validate_stolaf_report.R
```

Then run all gates in `VALIDATION_GATES.md`.

## 4) Verify Publish Paths
Required publish files:
- `docs/index.html`
- `docs/GeneralReport.html`
- `docs/custom/*.html`

Quick checks:

```bash
test -f docs/index.html
test -f docs/GeneralReport.html
ls docs/custom/*.html >/dev/null
```

## 5) Commit and Push

```bash
git add config/cycles.csv data/ README.md docs/handoff/ docs/index.html docs/GeneralReport.html docs/custom/
git commit -m "Cycle YY: regenerate reports and validations"
git push origin main
```

If your workflow requires PRs, push a feature branch and open PR to `main`.

## 6) GitHub Pages Verification
In your fork settings, ensure Pages serves from:
- Branch: `main`
- Folder: `/docs`

After push, verify site URLs:
- `https://<your-username>.github.io/<repo>/`
- `https://<your-username>.github.io/<repo>/GeneralReport.html`
- `https://<your-username>.github.io/<repo>/custom/<SchoolFile>.html`

## 7) Publish Gate for Stale Artifacts
Do not publish if stale custom files exist from another cycle. Always run publish artifact gate in `VALIDATION_GATES.md` before pushing.

# SemiCoLab Precheck — GitHub Actions

## Overview

The precheck workflow runs automatically on every push to `main` in a participant's tile repository. It validates the RTL design, runs synthesis, generates documentation, and commits results back to the repo.

---

## Workflow file

Location: `.github/workflows/precheck.yml`  
Source: `MifralTech/semicolab-precheck`

---

## Trigger

```yaml
on:
  push:
    branches:
      - main
```

Only pushes to `main` trigger the workflow. Work-in-progress branches are not validated.

---

## Template repo protection

```yaml
jobs:
  precheck:
    if: github.repository != 'MifralTech/semicolab-precheck'
```

The workflow is skipped entirely when running on the template repo itself. This keeps `MifralTech/semicolab-precheck` clean — only participant forks/clones run the precheck.

---

## Permissions

```yaml
permissions:
  contents: write
```

Required for the commit step to write results back to the participant's repo.

---

## Steps

### 1. Checkout
```yaml
uses: actions/checkout@v4
with:
  fetch-depth: 0
```
Full history checkout — required for accurate commit SHA resolution.

### 2. Install OSS CAD Suite
```yaml
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2024-11-26/oss-cad-suite-linux-x64-20241126.tgz
```
Installs Icarus Verilog (`iverilog`) and Yosys. Version pinned to `20241126` for reproducibility. Installed via direct download — the `YosysHQ/setup-oss-cad-suite` action was deprecated and removed.

### 3. Install Python dependencies
```yaml
sudo apt-get install -y -q libpango-1.0-0 libpangoft2-1.0-0
pip install pyyaml weasyprint markdown
```
`libpango` is required by WeasyPrint for PDF generation.

### 4. Install netlistsvg
```yaml
npm install -g netlistsvg
```
Used to generate `outputs/docs/netlist.svg` from the Yosys JSON netlist.

### 5. Clone precheck engine
```yaml
git clone https://github.com/serolugo/semicolab-precheck-engine.git _engine
```
Clones the engine at runtime. No submodules or pinned versions — always uses latest `main`. When migrated to MifralTech, update this URL accordingly.

### 6. Run precheck
```yaml
python _engine/veriflow/cli.py precheck \
  --repo . \
  --run-number ${{ github.run_number }} \
  --commit ${{ github.sha }} \
  --author "${{ github.actor }}"
```
Runs the full precheck pipeline. Exits with code 1 if connectivity check or synthesis fails.

### 7. Commit results
```yaml
if: always()
```
Runs even when the precheck fails — results and logs are committed regardless of outcome. Uses `[skip ci]` in the commit message to prevent an infinite loop.

---

## Exit codes

| Code | Condition |
|---|---|
| `0` | Precheck PASS |
| `1` | Connectivity FAIL, Synthesis FAIL, config error, or missing RTL |

---

## Outputs committed

Every run commits the following back to the repo:

```
outputs/
├── docs/
│   ├── results.json
│   ├── netlist.svg
│   ├── datasheet.pdf
│   └── submit.yaml     ← only on PASS, deleted on FAIL
└── logs/
    ├── connectivity.log
    └── synth.log
README.md               ← overwritten on every run
```

---

## Future: registry submission

A commented step at the end of the workflow is reserved for automatic Issue creation in `MifralTech/semicolab-registry`. Requires a `REGISTRY_TOKEN` secret with cross-repo write access. Not active in current version.

---

## Migration checklist

When transferring repos from `serolugo` to `MifralTech`:

1. Update engine clone URL in `precheck.yml`:
   ```yaml
   # Change:
   git clone https://github.com/serolugo/semicolab-precheck-engine.git _engine
   # To:
   git clone https://github.com/MifralTech/semicolab-precheck-engine.git _engine
   ```
2. Update repo guard condition:
   ```yaml
   # Already correct — no change needed:
   if: github.repository != 'MifralTech/semicolab-precheck'
   ```

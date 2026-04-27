# SemiCoLab Precheck — Engine

## Overview

`semicolab-precheck-engine` is the Python backend that runs the precheck pipeline. It is cloned at runtime by the GitHub Actions workflow and is not installed as a package — it runs directly from source.

Based on [veriflow-precheck](https://github.com/serolugo/veriflow-precheck).

---

## Repository

`serolugo/semicolab-precheck-engine` (transfers to `MifralTech` when ready)

---

## Entry point

```
python veriflow/cli.py precheck \
  --repo <path> \
  --run-number <n> \
  --commit <sha> \
  --author <username>
```

---

## Pipeline

```
1. validate_tools()           → check iverilog and yosys are in PATH
2. read tile_config.yaml      → validate required fields
3. find RTL in rtl/           → locate .v files and top_module
4. detect tests/              → check for testbench (informative only)
5. setup outputs/             → create docs/ and logs/ directories
6. delete submit.yaml         → always removed at run start
7. connectivity check         → iverilog elaboration via tb_base/tb_tasks
8. [if FAIL] → finalize + exit 1
9. synthesis                  → yosys synth + check + stat
10. finalize                  → generate all outputs
11. [if FAIL] → exit 1
```

---

## Key files

| File | Purpose |
|---|---|
| `veriflow/cli.py` | CLI entry point, argument parsing |
| `veriflow/commands/precheck.py` | Main pipeline logic |
| `veriflow/models/tile_config_ci.py` | tile_config.yaml schema and validation |
| `veriflow/core/validator.py` | Tool availability check |
| `veriflow/core/sim_runner.py` | Connectivity check via iverilog |
| `veriflow/core/synth_runner.py` | Synthesis via Yosys |
| `veriflow/core/log_parser.py` | Parse iverilog and Yosys logs |
| `veriflow/generators/readme_ci.py` | Generate README.md |
| `veriflow/generators/datasheet.py` | Generate datasheet HTML/PDF |
| `veriflow/generators/netlist_svg.py` | Generate netlist SVG |
| `veriflow/template/tb_base.v` | Connectivity check testbench base |
| `veriflow/template/tb_tasks.v` | Connectivity check port tasks |

---

## tile_config.yaml schema

| Field | Required | Description |
|---|---|---|
| `tile_name` | Yes | Display name |
| `tile_author` | Yes | Full name |
| `top_module` | Yes | Must match RTL filename |
| `version` | Yes | Design version e.g. `"1.0.0"` |
| `description` | Yes | What the tile does |
| `ports` | Yes | How the 9 SemiCoLab ports are used |
| `usage_guide` | Yes | How to use the tile |
| `simulator` | No | Tool used locally |
| `simulator_version` | No | Version of that tool |

---

## SemiCoLab port convention (9 ports)

| Port | Direction | Width |
|---|---|---|
| `clk` | input | 1 |
| `arst_n` | input | 1 |
| `csr_in` | input | 16 |
| `data_reg_a` | input | 32 |
| `data_reg_b` | input | 32 |
| `data_reg_c` | output | 32 |
| `csr_out` | output | 16 |
| `csr_in_re` | output | 1 |
| `csr_out_we` | output | 1 |

---

## Gate rules

| Stage | Gate | Condition |
|---|---|---|
| Config validation | Hard | Missing required fields |
| RTL discovery | Hard | No `.v` files in `rtl/` |
| Connectivity check | Hard | iverilog elaboration fails |
| Synthesis | Hard | `ERROR:` in Yosys log, latch inferred, or exit code != 0 |
| Simulation | None | Never runs in CI |
| Tests detection | None | Informative only |

---

## Log parsing rules (ISSUE-001)

Yosys log parsing uses strict case-sensitive patterns to avoid false positives:

| Pattern | Meaning | Action |
|---|---|---|
| `^ERROR:` | Real Yosys error | Gate — synthesis FAIL |
| `^Warning:` | Informative warning | Logged only, no gate |
| `Latch inferred for` | Latch detected | Gate — synthesis FAIL |

---

## Generated outputs

### Always generated
- `outputs/logs/connectivity.log`
- `outputs/logs/synth.log`
- `outputs/docs/results.json`
- `outputs/docs/netlist.svg`
- `outputs/docs/datasheet.pdf`
- `README.md`

### Generated only on PASS
- `outputs/docs/submit.yaml`

### Deleted at run start
- `outputs/docs/submit.yaml`

---

## results.json schema

```json
{
  "tile_id":      "repo-name",
  "status":       "PASS",
  "connectivity": "PASS",
  "synthesis":    "PASS",
  "cells":        236,
  "date":         "2026-04-27",
  "commit":       "a3f92c1...",
  "author":       "serolugo",
  "rtl_path":     "rtl"
}
```

---

## submit.yaml schema (generated on PASS only)

```yaml
tile_name:    "32-bit Accumulator"
tile_author:  "Sebastian Lugo"
top_module:   "acc_tile"
version:      "1.0.0"
repo_url:     "https://github.com/username/ip-my-tile"
commit:       "a3f92c1"
```

---

## Known issues

| ID | Description | Status |
|---|---|---|
| ISSUE-001 | Incorrect synthesis failure classification — Yosys warnings treated as errors | ✅ Fixed |

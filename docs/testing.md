# SemiCoLab Precheck — Testing & Gaps

## Overview

The test suite validates the `semicolab-precheck-engine` pipeline across a range of RTL designs — correct, incorrect, borderline, and edge cases. Tests run automatically via a GitHub Actions matrix workflow on every push to `main` in `serolugo/tests-`.

---

## Matrix workflow

Location: `.github/workflows/matrix.yml`  
Repo: `serolugo/tests-`

All testcases run in parallel as independent jobs. `fail-fast: false` ensures all cases complete even if one fails. Each job verifies that the precheck result (PASS/FAIL) matches the expected outcome defined in the matrix.

---

## Test cases

### 🔴 tc1 — Bad interface
**RTL:** Counter — missing `csr_in_re` and `csr_out_we` ports  
**Config:** Complete  
**Expected:** ❌ FAIL  
**Stage:** Elaboration  
**Analysis:** Correctly detected by iverilog. Validates SemiCoLab port convention enforcement.

---

### 🔴 tc2 — Bad logic (latch inferred)
**RTL:** Mux — incomplete case statement, missing `2'b11` branch  
**Config:** Complete  
**Expected:** ❌ FAIL  
**Stage:** Synthesis  
**Analysis:** Yosys infers a latch. The engine classifies latches as hard errors via the `Latch inferred for` pattern in `log_parser.py`. Demonstrates proto-lint behavior within the synthesis stage.

---

### 🔴 tc3 — Incomplete config
**RTL:** XOR tile — correct and complete  
**Config:** Missing `tile_author`, `version`, `ports`, `usage_guide`  
**Expected:** ❌ FAIL  
**Stage:** Config validation  
**Analysis:** Fail-fast before any tool is invoked. Confirms config validation runs first.

---

### 🟢 tc4 — Large circuit (FIR filter)
**RTL:** 8-tap FIR filter with 4 selectable coefficient sets, saturation logic  
**Config:** Complete  
**Expected:** ✅ PASS  
**Stage:** Synthesis  
**Analysis:** Complex realistic design. Validates the full pipeline on a non-trivial circuit.

---

### 🟠 tc5 — Width mismatch
**RTL:** Adder — 8-bit submodule output connected to 32-bit wire via named port  
**Config:** Complete  
**Expected:** ⚠️ WARNING (PASS)  
**Stage:** Synthesis  
**Analysis:** Yosys resolves the mismatch via automatic zero-extension without error. Not a hard failure but can cause silent logic bugs. Candidate for lint enforcement.

---

### 🔴 tc6 — Duplicate definitions
**RTL:** Parity checker — same module defined twice in one file  
**Config:** Complete  
**Expected:** ❌ FAIL  
**Stage:** Elaboration  
**Analysis:** iverilog reports a redefinition error. The design cannot be elaborated.

---

### ⚠️ tc7 — Unused signals
**RTL:** Tile with declared but unused wires, unused registers, and an unread input port  
**Config:** Complete  
**Expected:** ⚠️ PASS (gap)  
**Stage:** Synthesis  
**Analysis:** Yosys silently optimizes unused logic. No error or warning is emitted. The precheck cannot detect this without a dedicated lint stage. See Gaps section.

---

### 🔴 tc8 — Empty input
**RTL:** `rtl/` directory exists but contains no `.v` files  
**Config:** All fields empty  
**Expected:** ❌ FAIL  
**Stage:** Config validation  
**Analysis:** Fails at config validation (empty required fields) before RTL discovery. Confirms fail-fast behavior on completely invalid input.

---

### ⚠️ tc9 — Naming convention
**RTL:** Module named `MYMODULE` with single-letter internal signals (`x`, `y`, `tmp`, `foo`)  
**Config:** Complete  
**Expected:** ⚠️ PASS (gap)  
**Stage:** Synthesis  
**Analysis:** Neither iverilog nor Yosys validate naming conventions. The precheck only enforces the 9 SemiCoLab port names — internal naming is not checked. See Gaps section.

---

### 🟢 tc10 — Borderline valid
**RTL:** Redundant logic — `+0`, `| 0`, `& 0xFFFFFFFF`, duplicate mux branches, unnecessary pipeline register, double negation via `~(~signal)`  
**Config:** Complete  
**Expected:** ✅ PASS  
**Stage:** Synthesis  
**Analysis:** Yosys optimizes all redundancy without errors or warnings. Confirms the system accepts valid designs even if suboptimal. Fix applied: `~~signal` syntax (invalid Verilog) replaced with `~(~signal)`.

---

### 🟢 tc_shift_mux — Baseline functional
**RTL:** Shift multiplexer — registered output, clean design  
**Config:** Complete  
**Expected:** ✅ PASS  
**Stage:** Synthesis  
**Analysis:** Simple clean baseline. Used to detect regressions in the pipeline.

---

## Summary

| # | Testcase | Expected | Stage |
|---|---|---|---|
| tc1 | Bad interface | ❌ FAIL | Elaboration |
| tc2 | Bad logic | ❌ FAIL | Synthesis |
| tc3 | Incomplete config | ❌ FAIL | Config |
| tc4 | Large circuit | ✅ PASS | Synthesis |
| tc5 | Width mismatch | ⚠️ PASS | Synthesis |
| tc6 | Duplicate definitions | ❌ FAIL | Elaboration |
| tc7 | Unused signals | ⚠️ PASS (gap) | Synthesis |
| tc8 | Empty input | ❌ FAIL | Config |
| tc9 | Naming convention | ⚠️ PASS (gap) | Synthesis |
| tc10 | Borderline valid | ✅ PASS | Synthesis |
| tc_shift_mux | Baseline | ✅ PASS | Synthesis |

---

## Identified gaps

### GAP-001 — Unused signals not detected

**Testcase:** tc7  
**Description:** Signals declared but never used and input ports never read are silently removed by Yosys during optimization. The precheck reports PASS without any indication of the issue.  
**Impact:** Designs with incomplete logic or forgotten connections pass validation undetected.  
**Root cause:** No lint stage — the engine relies solely on iverilog elaboration and Yosys synthesis, neither of which treats unused signals as errors.  
**Proposed solution:** Add a lint step using Yosys `check -assert` or a custom parser that inspects the synthesis log for optimized-away signals. Define whether this is a hard gate or informative warning.  
**Priority:** Medium

---

### GAP-002 — Naming conventions not enforced

**Testcase:** tc9  
**Description:** Internal signal and module names are not validated beyond the 9 SemiCoLab port names. Modules with uppercase names, single-letter signals, and ambiguous identifiers pass the precheck without issue.  
**Impact:** Participants may submit designs with unreadable or inconsistent code, reducing maintainability in an academic context.  
**Root cause:** No naming lint — iverilog and Yosys are agnostic to naming style.  
**Proposed solution:** Implement a Verilog name checker (regex-based or via a lightweight parser) that validates internal signal names against a defined convention. Rules to define before implementation:
- Minimum identifier length
- Clock signal naming (e.g. must contain `clk`)
- Reset signal naming (e.g. must contain `rst` or `arst`)
- Module name suffix (e.g. must end in `_tile`)
- Allowed/disallowed patterns
**Priority:** Low

---

## Issues resolved

| ID | Description | Resolution |
|---|---|---|
| ISSUE-001 | Synthesis FAIL misclassified — Yosys `Warning:` treated as error | Fixed in `log_parser.py` — strict case-sensitive patterns |
| — | `precheck.py` exited with code 0 on synthesis FAIL | Fixed — `raise VeriFlowError` added after `_finalize()` |
| — | `~~signal` syntax error in tc10 RTL | Fixed — rewritten as `~(~signal)` |

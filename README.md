# SemiCoLab Precheck — Matrix Test Suite

Automated test suite for `semicolab-precheck-engine`. Runs all testcases in parallel on every push to `main`.

## Structure

```
testcases/
├── tc1_bad_interface/       ← FAIL expected (connectivity)
├── tc2_bad_logic/           ← FAIL expected (synthesis)
├── tc3_incomplete_config/   ← FAIL expected (config validation)
├── tc4_large_circuit/       ← PASS expected
├── tc5_width_mismatch/      ← PASS expected (warning only)
├── tc6_duplicate_definitions/ ← FAIL expected (elaboration)
├── tc7_unused_signals/      ← PASS expected (gap — lint pending)
├── tc8_empty_input/         ← FAIL expected (config validation)
├── tc9_naming_convention/   ← PASS expected (gap — lint pending)
├── tc10_borderline_valid/   ← PASS expected
└── tc_shift_mux/            ← PASS expected (regression baseline)
```

## Running tests

Tests run automatically on push to `main`.
To run manually: Actions → SemiCoLab Precheck Matrix Tests → Run workflow.

## Adding a new testcase

1. Create `testcases/tc<N>_<name>/rtl/` and add your `.v` file
2. Create `testcases/tc<N>_<name>/tile_config.yaml`
3. Add the testcase to the matrix in `.github/workflows/matrix.yml` with its expected result
4. Push to `main`

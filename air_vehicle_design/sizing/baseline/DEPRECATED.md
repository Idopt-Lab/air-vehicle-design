# `baseline/` — DEPRECATED, to be deleted

This folder (`F16Baseline.m` + `extract_brandt.m`) is **marked for deletion**.
It is **superseded by** [`../VnV/BrandtF16A/`](../VnV/BrandtF16A/) — the
`Brandt*.m` discipline classes plus `GroundTruth/*.json` are the authoritative
F-16A ground-truth mechanism going forward.

## Do not

- Do **not** add new dependencies on `F16Baseline()` or `extract_brandt()`.
- Point new/updated code and tests at `VnV/BrandtF16A/` instead.

## Before it can actually be removed

`F16Baseline` is still consumed by ~20 files (discipline examples, `src/`
constraints, and the `tests/` suites), so deleting it now breaks
`run_all_tests`. Deletion is blocked until those consumers are migrated to read
the VnV ground-truth. Track that migration before removing this folder.

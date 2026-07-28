# F-16A Block 10/15 — Tail Sizing vs Ground Truth

Generated 2026-07-28. Wing geometry from F16GeomL2 (S_ref=300 ft^2, AR_wing=3.0, lambda_wing=0.2275, L_fus=46.5 ft).

**Reference** (the `Reference` and `%Diff` columns): Brandt F-16A.xls, via `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.tail_sizing`] -- Main!C18 (S_ht), Main!H18 (S_vt).

**2nd Source** (the `2nd Source` column): No second source for this discipline yet -- L3 (Raymer Ch. 16 stability-and-control sizing) is a documented-TODO stub, see examples/F16A/tail_sizing_brandt_comparison.m header and TestTailL3.m.

This is a **comparison report, not a test** — no pass/fail assertions, not part of `run_all_tests`, and **nothing here may ever be used to backfill a unit test's expected value**. Where a quantity has more than one valid implementation, each option gets its own row, and rejected variants are reported too so the decisions stay auditable.

**Reading the `Divergence` column.** `BY DESIGN` — the framework computes the *same kind* of quantity as the reference but is *expected* to differ (a different formula family, or a locked decision to follow a physical/T.O. value); a large %Diff there is the correct answer, not a defect, though its magnitude is worth a sanity check. `DEFINITIONAL` — the two sides are *different kinds of quantity altogether*, so the %Diff is not an error measure at all; do not chase it. **Blank** — a genuine agreement check, where a large %Diff **is** worth chasing.

**Both L1 and L2 are historical-average / category-level volume-coefficient methods, not a stability-and-control design against the F-16's actual CG and required static margin** -- that is L3's job (Raymer Ch. 16), currently a documented-TODO stub (no verifiable equation numbers in this repository -- see VnV/BrandtF16A/todo.md 2026-07-28 Finding 3). A large %Diff against Brandt's back-calculated 108/60 here is the EXPECTED signature of that fidelity gap, not a framework defect.

**L1 vs L2 numeric trend.** The RSS + all-moving-tail text corrections applied at L1 REDUCE c_HT/c_VT below Raymer's already-conservative jet-fighter row, which widens L1's gap against Brandt relative to what an uncorrected flat 0.40/0.07 would give. L2's Nicolai & Carichner coefficients are F-16-SPECIFIC (measured from the real aircraft, Table 11.6), so L2 is expected to track Brandt more closely than L1 -- whether it actually does, and by how much, is exactly what this table reports.

| Parameter | Fidelity | Computed | Reference | %Diff | 2nd Source | Divergence | Cite | Notes |
|---|---|---|---|---|---|---|---|---|
| **[HORIZONTAL TAIL AREA S_ht]** | | | | | | | | |
| S_ht, L1 volume-coefficient method [ft^2] | L1 | 48.4327 | 108.0000 | -55.15% | N/A |  | Brandt Main!C18 | Raymer 7th ed. Table 6.4 jet-fighter row (c_HT=0.40) corrected for RSS (-10%) and the F-16's all-moving stabilator (-12.5%): net c_HT=0.315. A historical-average, category-level coefficient method is not expected to reproduce one specific real aircraft's back-calculated area tightly; the corrections applied here REDUCE c_HT below Raymer's already-low end, which widens this gap relative to the flat, uncorrected 0.40 the now-superseded TailSizingLevel1 used. Not a defect -- see this script's header. |
| S_ht, L2 Nicolai/Carichner F-16 coefficient [ft^2] | L2 | 46.1264 | 108.0000 | -57.29% | N/A |  | Brandt Main!C18 | Nicolai & Carichner Table 11.6, "General Dynamics F-16" row (C_HT=0.3, an F-16-SPECIFIC measured coefficient, not a generic category row). Same tail arm (0.475*L_fus) as L1 -- L2's fidelity gain is confined to the coefficient source and wing-geometry precision, not the arm. |
| **[VERTICAL TAIL AREA S_vt]** | | | | | | | | |
| S_vt, L1 volume-coefficient method [ft^2] | L1 | 25.6706 | 60.0000 | -57.22% | N/A |  | Brandt Main!H18 | Raymer 7th ed. Table 6.4 jet-fighter row (c_VT=0.07) corrected for RSS only (-10%, no VT-specific text correction exists): net c_VT=0.063. |
| S_vt, L2 Nicolai/Carichner F-16 coefficient [ft^2] | L2 | 38.3022 | 60.0000 | -36.16% | N/A |  | Brandt Main!H18 | Nicolai & Carichner Table 11.6, "General Dynamics F-16" row (C_VT=0.094, an F-16-SPECIFIC measured coefficient). |

# F16WeightsL1

F-16A Block 10/15 Level-1 weights. `classdef F16WeightsL1 < WeightsModelL1`; its one abstract method
does the lookup-then-compute pair against the `WeightsL1` static toolbox.

**L1 is a categorical/historical empty-weight fraction.** OEW fraction is the Raymer Table 3.1 power law in `W_TO`,
selected by aircraft category. Multiplying by W_TO gives the W_empty.
Roskam's method is included as an alternative. It returns the OEW, not the fraction.

---

## 1. Constructor

```matlab
w1 = F16WeightsL1(f16a_spec_path(1));
```

`F16WeightsL1(json_path)` — **single argument**, path required, no silent default. Reads the
top-level `aircraft_category` and the `.weights` block of `f16a_L1.json`.

Contrast L2/L3, which take `(json_path, req_path, geom, prop)`. L1 needs none of those: both
regressions take only `W_TO`, and neither uses a design Mach or a cruise condition.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | — | Selects the Raymer Table 3.1 row |
| `W_TO` | `NaN` | lbf | Sizing-loop state, mutated in place; deliberately not read from JSON |
| `W_energy` | `NaN` | lbf | Sizing-loop state, set by mission analysis. Brandt's `Wt!B6` is a back-calculated *output*, so it is not an input |
| `W_payload_fixed` | 700 | lbf | [Brandt `Wt!B4 = Main!O16`] |
| `W_payload_expendable` | 4400 | lbf | [Brandt `Wt!B5 = Main!O17`] |

## 3. Derived

**None, and zero is the right answer.** `get_OEW` is a *method* taking `W_TO` as an argument, not a
property: the whole model is one closed-form evaluation, so there is nothing to recompute-on-read.
Making it `Dependent` on a stored `W_TO` would add a second way to ask the same question.

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_OEW_categorical` | `W_TO` | OEW [lbf] |
| `get_OEW` | `W_TO` | OEW [lbf], the `WeightsModelL1` bridge onto `get_OEW_categorical` |

`get_OEW_categorical` reads its Table 3.1 row with `WeightsL1.lookup_raymer_We_frac_coeffs`,
evaluates `WeightsL1.compute_We_frac_raymer(K_vs, A, C, W_TO)`, then multiplies by `W_TO`.
`WeightsBase` declares `get_OEW`; `WeightsModelL1` supplies the bridge, so a concrete L1 class
writes one method, not two.

### Lookup constants

`WeightsL1.lookup_raymer_We_frac_coeffs` — Raymer Table 3.1, the row this class uses. All four code
rows match the `metabook_data.md` extract:

| Category | A | C |
|---|---|---|
| `jet_fighter` | 2.34 | −0.13 |
| `jet_trainer` | 1.59 | −0.10 |
| `jet_transport` | 1.02 | −0.06 |
| `military_cargo_bomber` | 0.93 | −0.07 |

`K_vs` is **not** in the table. It is a design value, so `get_OEW_categorical` passes it as a
literal: the F-16A is fixed-sweep, `K_vs` = 1.00 [metabook_data.md:20-22].

`WeightsL1.lookup_We_roskam_coeffs` — Roskam Table 2.15. Not used by this class; the independent
lower bound. All five rows match `roskam_vol1_data.md`:
`jet_fighter` 0.5091/0.9505, `fighter_piston` 0.5647/0.8761, `single_engine_prop` −0.1440/1.1162,
`military_patrol_bomber` −0.2009/1.1037, `supersonic_cruise` 0.0833/1.0335.

Both extracts are **secondary sources** — the metabook cites Raymer rather than being Raymer, and the
Roskam rows were OCR-recovered from an image-only table carrying its own "verify against the book"
warning.

### As-built values

At `W_TO` = 31,377 lbf:

| Quantity | Value | vs Brandt `Wt!B12` 19980.70 |
|---|---|---|
| Raymer fraction We/W_TO | 0.609055 | — |
| `get_OEW` | **19110.313 lbf** | −4.36 % |
| Roskam lower bound, for comparison | 15673.733 lbf | −21.56 % |

In the L1 sizing loop this class closes the F-16A at `W_TO` 26762.1 lbf, `OEW` 16640.2 lbf.

The Roskam value is an independent **minimum bound**, correctly below the Raymer estimate, as
`TestWeightsL1.testWeRoskamLowerThanRaymerL1` asserts. It is not an OEW estimate and no F-16A class
uses it as one.

The OEW-vs-Brandt agreement check lives in `weights_brandt_comparison`, **not** in the unit tier: an
agreement check against ground truth is not a unit test. The unit tier keeps physical invariants and
hand-computed per-formula values.

---

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer **Table 6.1** is cited by the original step-5 weights design for the same power law, but its coefficients are **not in this repo** — the code uses Table 3.1. The user must supply Table 6.1 to settle which is intended | `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` — deliberately red |
| The Raymer Table 3.1 extract carries a fifth row (UAV-Tac Recce / UCAV, A = 1.67, C = −0.16) the code does not | not a defect; noted |
| Both coefficient tables come from secondary/OCR sources rather than the printed books | in-code `⚠ verify` markers |

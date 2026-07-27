# F16WeightsL1

F-16A Block 10/15 Level-1 weights. `classdef F16WeightsL1 < WeightsModelL1`; every abstract method is
a one-line delegation into the `WeightsL1` static toolbox.

**L1 is a statistical empty-weight fraction** — a power law in `W_TO` selected by aircraft category,
with a Roskam regression as an independent lower bound. No component buildup, no geometry, no engine
data, which is why this is the only weights level that injects nothing.

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
| `aircraft_category` | `"jet_fighter"` | — | Selects the Raymer Table 3.1 and Roskam Table 2.15 rows |
| `W_TO` | `NaN` | lbf | Sizing-loop state, mutated in place; deliberately not read from JSON |
| `W_energy` | `NaN` | lbf | Sizing-loop state, set by mission analysis. Brandt's `Wt!B6` is a back-calculated *output*, so it is not an input |
| `W_payload_fixed` | 700 | lbf | [Brandt `Wt!B4 = Main!O16`] |
| `W_payload_expendable` | 4400 | lbf | [Brandt `Wt!B5 = Main!O17`] |

## 3. Derived

**None, and zero is the right answer.** `OEW` is a *method* taking `W_TO` as an argument, not a
property: the whole model is one closed-form evaluation, so there is nothing to recompute-on-read.
Making it `Dependent` on a stored `W_TO` would add a second way to ask the same question.

---

## 4. Methods

| Method | Delegates to | Formula | Citation |
|---|---|---|---|
| `OEW(W_TO)` | `WeightsL1.OEW` → `We_fraction_power_law` | `OEW = (K_vs·A·W_TO^C)·W_TO` | Raymer Table 3.1 |
| `compute_We_fraction(W_TO)` | `WeightsL1.compute_We_fraction` | `K_vs·A·W_TO^C` | Raymer Table 3.1 |
| `compute_We_roskam(W_TO)` | `WeightsL1.We_roskam` | `W_E = 10^((log₁₀W_TO − A)/B)` | Roskam Part I Eq. 2.16 + Table 2.15 |

### Lookup constants

`WeightsL1.lookup_coeffs` — Raymer Table 3.1; all four code rows match the `metabook_data.md` extract:

| Category | A | C | K_vs |
|---|---|---|---|
| `jet_fighter` | 2.34 | −0.13 | 1.00 |
| `jet_trainer` | 1.59 | −0.10 | 1.00 |
| `jet_transport` | 1.02 | −0.06 | 1.00 |
| `military_cargo_bomber` | 0.93 | −0.07 | 1.00 |

`WeightsL1.lookup_roskam_coeffs` — Roskam Table 2.15; all five rows match `roskam_vol1_data.md`:
`jet_fighter` 0.5091/0.9505, `fighter_piston` 0.5647/0.8761, `single_engine_prop` −0.1440/1.1162,
`military_patrol_bomber` −0.2009/1.1037, `supersonic_cruise` 0.0833/1.0335.

Both extracts are **secondary sources** — the metabook cites Raymer rather than being Raymer, and the
Roskam rows were OCR-recovered from an image-only table carrying its own "verify against the book"
warning.

### As-built values

At `W_TO` = 31,377 lbf:

| Quantity | Value | vs Brandt `Wt!B12` 19980.70 |
|---|---|---|
| `compute_We_fraction` | 0.609055 | — |
| `OEW` | **19110.313 lbf** | −4.36 % |
| `compute_We_roskam` | 15673.733 lbf | −21.56 % |

The Roskam value is an independent **minimum bound**, not a competing estimate — correctly below the
Raymer central estimate (the lower efficiency frontier), as
`TestWeightsL1.testWeRoskamLowerThanRaymerL1` asserts.

The OEW-vs-Brandt agreement check lives in `weights_brandt_comparison`, **not** in the unit tier: an
agreement check against ground truth is not a unit test. The unit tier keeps physical invariants, the
`frac·W_TO == OEW` identity, and hand-computed per-formula values.

---

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer **Table 6.1** is cited by `docs/subplans/05_weights.md` for the same power law, but its coefficients are **not in this repo** — the code uses Table 3.1. The user must supply Table 6.1 to settle which is intended | `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` — deliberately red |
| The Raymer Table 3.1 extract carries a fifth row (UAV-Tac Recce / UCAV, A = 1.67, C = −0.16) the code does not | not a defect; noted |
| Both coefficient tables come from secondary/OCR sources rather than the printed books | in-code `⚠ verify` markers |

# WeightsL1

Level-1 weights static toolbox (`classdef WeightsL1`, `methods (Static)` only). Called as
`WeightsL1.method(...)`; never instantiated and not in the inheritance chain. `F16WeightsL1` inherits
`WeightsModelL1` and delegates here.

**L1 is a statistical empty-weight fraction.** Both regressions take only $W_{TO}$ — no geometry, no
engine data — which is why L1 is the only weights level that injects nothing.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `OEW`, `compute_We_fraction`, `compute_We_roskam` |
| Low-level | `We_fraction_power_law`, `We_roskam`, `lookup_coeffs`, `lookup_roskam_coeffs` |

## 2. Equations

**Central estimate** [Raymer 7th ed. Table 3.1] — the power law returns a *fraction*, and OEW is that
fraction times gross weight:

$$\frac{W_e}{W_{TO}} = K_{vs}\,A\,W_{TO}^{\,C}
  \qquad\Longrightarrow\qquad
  OEW = \left(K_{vs}\,A\,W_{TO}^{\,C}\right) W_{TO}$$

**Lower bound** [Roskam Part I Eq. 2.16 with Table 2.15]:

$$W_E = 10^{\left(\log_{10} W_{TO} - A\right)/B}$$

This is a **minimum bound**, not a competing estimate — the historical efficiency frontier. A real
OEW must sit above it, so a negative difference against ground truth is the correct result and its
magnitude is not an error measure.

## 3. Coefficients

`lookup_coeffs` [Raymer 7th ed. Table 3.1]:

| Category | $A$ | $C$ | $K_{vs}$ |
|---|---|---|---|
| `jet_fighter` | 2.34 | −0.13 | 1.00 |
| `jet_trainer` | 1.59 | −0.10 | 1.00 |
| `jet_transport` | 1.02 | −0.06 | 1.00 |
| `military_cargo_bomber` | 0.93 | −0.07 | 1.00 |

`lookup_roskam_coeffs` [Roskam Part I Table 2.15]:

| Category | $A$ | $B$ |
|---|---|---|
| `jet_fighter` | 0.5091 | 0.9505 |
| `fighter_piston` | 0.5647 | 0.8761 |
| `single_engine_prop` | −0.1440 | 1.1162 |
| `military_patrol_bomber` | −0.2009 | 1.1037 |
| `supersonic_cruise` | 0.0833 | 1.0335 |

Both sets come from **secondary sources**: the metabook cites Raymer rather than being Raymer, and
the Roskam rows were OCR-recovered from an image-only table that carries its own
verify-against-the-book warning.

## 4. As-built values

At $W_{TO}$ = 31,377 lbf: fraction 0.609055, OEW 19110.313 lbf, Roskam bound 15673.733 lbf.

## 5. To-dos

| Item | Guard |
|---|---|
| `docs/subplans/05_weights.md` cites Raymer **Table 6.1** for the same power law, but Table 6.1's coefficients are not in this repo — the code uses Table 3.1. The user must supply Table 6.1 to settle which is intended | `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` — deliberately red, and it keys off a literal sentence in `WeightsL1.m`'s header |
| The Table 3.1 extract carries a fifth row (UAV-Tac Recce / UCAV, $A$ = 1.67, $C$ = −0.16) the code does not | noted, not a defect |

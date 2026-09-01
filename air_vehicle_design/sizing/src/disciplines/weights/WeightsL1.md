# WeightsL1

Level-1 weights static toolbox (`classdef WeightsL1`, `methods (Static)` only). Called as
`WeightsL1.method(...)`; never instantiated. Every static takes **scalars**, never a design object:
the design class reads its own coefficient row and passes the numbers.

**L1 is a statistical empty-weight regression.** Both forms take only $W_{TO}$, with no geometry and
no engine data, so an L1 weights class injects nothing.

Consumers: `F16WeightsL1` (Raymer fraction) and `Aero481WeightsL1` (the same power law carrying
Sainristil coefficients, plus `engine_weight_roskam` for its A02 engine delta). `B777WeightsL2`
also calls `engine_weight_roskam`.

---

## 1. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_We_frac_raymer` | `A`, `C`, `W_TO` | $W_e/W_{TO}$ fraction | Raymer 6th ed. Table 3.1 |
| `compute_We_roskam` | `A`, `B`, `W_TO` | $W_E$ [lbf] | Roskam Part I Eq. 2.16 |
| `lookup_raymer_We_frac_coeffs` | `aircraft_category` | struct `A`, `C` | Raymer 6th ed. Table 3.1 |
| `lookup_We_roskam_coeffs` | `aircraft_category` | struct `A`, `B` | Roskam Part I Table 2.15 |
| `engine_weight_roskam` | `T0_lbf` | one engine total [lbf] | Roskam Eqs. 7.13-7.19 |

## 2. Equations

**Fraction form** [Raymer 6th ed. Table 3.1]. The power law returns a *fraction*, so an OEW built
on it is that fraction times gross weight:

$$\frac{W_e}{W_{TO}} = K_{vs}\,A\,W_{TO}^{\,C}
  \qquad\Longrightarrow\qquad
  OEW = \left(K_{vs}\,A\,W_{TO}^{\,C}\right) W_{TO}$$

**Weight form** [Roskam Part I Eq. 2.16 with Table 2.15]:

$$W_E = 10^{\left(\log_{10} W_{TO} - A\right)/B}$$

Roskam presents this as the **minimum achievable** $W_E$, so it is a lower bound rather than a
competing estimate. `F16WeightsL1` does not use it; it uses the fraction form above.

## 3. Coefficients

`lookup_raymer_We_frac_coeffs` [Raymer 6th ed. Table 3.1]:

| Category | $A$ | $C$ |
|---|---|---|
| `jet_fighter` | 2.34 | −0.13 |
| `jet_trainer` | 1.59 | −0.10 |
| `jet_transport` | 1.02 | −0.06 |
| `military_cargo_bomber` | 0.93 | −0.07 |

$K_{vs}$ is **not tabulated**: it is a design value, not a Table 3.1 constant. The caller supplies
it, 1.00 for fixed sweep and 1.04 for variable sweep [metabook_data.md:20-22].

`lookup_We_roskam_coeffs` [Roskam Part I Table 2.15]:

| Category | $A$ | $B$ |
|---|---|---|
| `jet_fighter` | 0.5091 | 0.9505 |
| `fighter_piston` | 0.5647 | 0.8761 |
| `single_engine_prop` | −0.1440 | 1.1162 |
| `military_patrol_bomber` | −0.2009 | 1.1037 |
| `supersonic_cruise` | 0.0833 | 1.0335 |

## 4. As-built values

At $W_{TO}$ = 31,377 lbf: Raymer fraction 0.609055, so OEW 19110.313 lbf. Roskam lower bound
15673.733 lbf. `F16WeightsL1.get_OEW(31377)` returns the Raymer value.

## 5. To-dos

| Item | Guard |
|---|---|
| The original step-5 weights design cites Raymer **Table 6.1** for the same power law, but Table 6.1's coefficients are not in this repo — the code uses Table 3.1. The user must supply Table 6.1 to settle which is intended | `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` — deliberately red, and it keys off a literal sentence in `WeightsL1.m`'s header |
| The Table 3.1 extract carries a fifth row (UAV-Tac Recce / UCAV, $A$ = 1.67, $C$ = −0.16) the code does not | noted, not a defect |

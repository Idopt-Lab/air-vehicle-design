# WeightsL2

Level-2 weights static toolbox (`classdef WeightsL2`, `methods (Static)` only). Called as
`WeightsL2.method(...)`; never instantiated and not in the inheritance chain. `F16WeightsL2` inherits
`WeightsModelL2` and delegates here.

**L2 is surface density × area for the structural groups, plus fractions of gross weight** for
landing gear, installed engine and all-else-empty.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `OEW`, `weight_wing`, `weight_tail`, `weight_fuselage`, `weight_landing_gear`, `weight_installed_engine`, `weight_all_else_empty` |
| Low-level | `wing_unit_weight`, `HT_unit_weight`, `VT_unit_weight`, `fus_unit_weight`, `LG_fraction`, `engine_weight_brandt` |

## 2. Equations

**Structural groups** [Raymer 6th ed. Table 15.2], surface density on real areas:

$$W_{wing} = \rho_w S_w \qquad
  W_{HT} = \rho_{ht} S_{ht} \qquad
  W_{VT} = \rho_{vt} S_{vt} \qquad
  W_{fus} = \rho_{fus} S_{wet,fus}$$

Wing, HT and VT take **exposed** areas; the fuselage takes **wetted** area. None of these four carry
a $W_{TO}$ term — they are pure area × density.

**Fraction-based groups** [AE481 metabook Sec. 7]:

$$W_{LG} = f_{LG}\,W_{TO} \qquad
  W_{engine,installed} = 1.3\,N_{en}\,W_{en} \qquad
  W_{all\ else} = 0.17\,W_{TO}$$

**Operating empty weight** is their sum:

$$OEW = W_{wing} + W_{HT} + W_{VT} + W_{fus} + W_{LG}
      + W_{engine,installed} + W_{all\ else}$$

**Brandt's engine alternate** [Brandt F-16A.xls, Wt!B11], already installed so it takes no ×1.3:

$$W_{en,Brandt} = 0.199\,T_{AB,SLS}$$

## 3. Coefficients

Raymer Table 15.2 psf densities:

| Category | wing | HT | VT | fuselage |
|---|---|---|---|---|
| `jet_fighter` | 9 | 4 | 5.3 | 4.8 |
| `jet_transport` | 10 | 5.5 | 5.5 | 5.0 |
| `general_aviation` | 2.5 | 2 | 2 | 1.4 |

Metabook Sec. 7 fractions: landing gear `jet_fighter` 0.033, `jet_transport` 0.043;
installed-engine factor 1.3; all-else 0.17.

**These three fractions are not Raymer Table 15.2.** In the repo extract that table carries only the
psf densities; the fractions are a separate, unnumbered metabook table. Brandt uses 0.034 for landing
gear where this uses 0.033 — different models, reported side by side.

## 4. Two rules that have bitten before

- **`OEW(W_TO)` must evaluate both fraction terms at the passed argument.** It must not read the
  `W_all_else_empty` / `W_installed_engine` properties, which are pinned to the object's own `W_TO`.
  Getting this wrong froze the all-else term at `0.17 × 31377` — a ground-truth *output* used as a
  calibration input. Guarded by `TestWeightsL2.testOEWScalesWithItsArgumentNotAFrozenWTO`.
- **The ×1.3 installed factor is L2-only.** L2 has no installation buildup, so one lumped factor is
  right here and only here; L3 builds the installation item by item and would double-count it.
  `engine_weight_brandt` is report-only and never summed into `OEW`, guarded by
  `testBrandtEngineAlternateIsNeverSummedIntoOEW`.

## 5. As-built values

At $W_{TO}$ = 31,377 lbf: wing 1766.03, HT 199.39, VT 216.72, fuselage 3505.45, landing gear 1035.44,
installed engine 3607.53, all-else 5334.09 → **OEW 15664.65 lbf**.

## 6. To-dos

| Item | Status |
|---|---|
| `LG_fraction('general_aviation') = 0.057` is **uncited** — the extract's fraction table has no GA landing-gear row | todo.md Phase 4 §P4-7 |
| `LG_fraction` has **no `navy_fighter` row** despite the extract carrying one (0.045) | pinned as a known absence by `TestWeightsL2.testLGFractionHasNoNavyFighterRow` |

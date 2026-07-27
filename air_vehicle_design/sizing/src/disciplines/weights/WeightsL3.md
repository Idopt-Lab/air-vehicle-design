# WeightsL3

Level-3 weights static toolbox (`classdef WeightsL3`, `methods (Static)` only). Called as
`WeightsL3.method(...)`; never instantiated and not in the inheritance chain. `F16WeightsL3` inherits
`WeightsModelL3` and delegates here.

**L3 is the [Raymer 7th ed. Sec. 15.3.1] fighter/attack component buildup** — Eqs. 15.1–15.24, one
equation per component, grouped into structural / landing gear / engine / systems.

---

## 1. Role

| Group | Members |
|---|---|
| High-level | `OEW`, `weight_wing`, `weight_tail`, `weight_fuselage`, `weight_landing_gear`, `weight_engine_section`, `weight_systems`, `landing_weight` |
| Structural | `wing` (15.1), `horizontal_tail` (15.2), `vertical_tail` (15.3), `fuselage` (15.4) |
| Landing gear | `main_gear` (15.5), `nose_gear` (15.6) |
| Engine | `engine_mounts` (15.7), `firewall` (15.8), `engine_section` (15.9), `air_induction` (15.10), `tailpipe` (15.11), `engine_cooling` (15.12), `oil_cooling` (15.13), `engine_controls` (15.14), `starter` (15.15) |
| Systems | `fuel_system` (15.16), `flight_controls` (15.17), `instruments` (15.18), `hydraulics` (15.19), `electrical` (15.20), `avionics` (15.21), `furnishings` (15.22), `ac_antiice` (15.23), `handling_gear` (15.24) |

## 2. Units

Raymer's nomenclature, English throughout. Weights and thrust in lbf, areas in ft², lengths in ft —
**except `L_m` and `L_n`, which enter Eqs. 15.5/15.6 in inches**; the caller converts. Volumes in
gallons, SFC in 1/hr, $R_{kva}$ in kVA.

## 3. Representative equations

The full set is Eqs. 15.1–15.24; these are the ones with a trap attached.

**Wing** [Eq. 15.1] and **fuselage** [Eq. 15.4] are the two largest structural terms:

$$W_{fus} = 0.499\,K_{dwf}\,W_{dg}^{0.35}\,N_z^{0.25}\,L_{fus}^{0.5}\,
  D_{fus}^{0.849}\,W_{fus,width}^{0.685}$$

$D_{fus}$ here is Eq. 15.4's **structural depth**, not the geometry object's equivalent diameter.
Because the exponent is 0.849, substituting 6.0 for 5.0 ft inflates this component by +17.9 %.

**Landing gear** [Eq. 15.5, 15.6] take the design landing weight, which is derived from gross weight
rather than stored:

$$W_l = 0.95\,W_{TO}$$

**Operating empty weight** is the sum of the four groups:

$$OEW = W_{struct} + W_{LG} + W_{engine\ section} + W_{systems}$$

**Engine group.** The dry engine weight comes from [Raymer 7th ed. Eq. 10.10] — *not* a Sec. 15.3.1
equation — and must be **uninstalled** here, because Eqs. 15.7–15.15 *are* the installation. Applying
the metabook's ×1.3 lumped factor on top would double-count them; that factor is L2-only.

## 4. Load factor and the tier's basis

$N_z$ = 13.5 (= 1.5 × 9 g limit, ultimate) is the Sec. 15.3.1 basis. Brandt's psf model uses
$n_{ult}$ = 9. Two different models — do not conflate.

$K_{rht}$ is applied to **Eq. 15.3 (VT)**, not 15.2, exactly as the book defines it, even though the
flag describes the horizontal tail.

`weight_systems` contains **no landing-gear term**; `OEW` adds `weight_landing_gear` separately.

## 5. To-dos

| Item | Guard |
|---|---|
| **Every exponent and coefficient is unverified against the printed book** — 62 rows, tallied 2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY / 5 clean. The two CONFLICTs keep their code values: Eq. 15.13 $N_{en}^{1.023}$ (extract says 1.078) and Eq. 15.3 $\cos^{-0.323}\Lambda_{vt}$ (extract says −1.0). **Do not change a value to make the guard green** | `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` — deliberately red, keyed off a literal sentence in `WeightsL3.m`'s header; checklist in `todo.md` §3a |
| `K_d = 0` is a legal straight-duct value that silently zeroes the whole air-induction term ($0^{0.182} = 0$) — no error, no warning, not even NaN. Left **unguarded by decision**. Corollary: if $K_d = 0$ is legal then $K_d$ cannot be Raymer's multiplicative base, so the exponent and placement are themselves suspect | todo.md Phase 4 §P4-11 |
| The `0.95` in $W_l = 0.95\,W_{TO}$ has **no citation** in this repo | todo.md Phase 4 §P4-16 |

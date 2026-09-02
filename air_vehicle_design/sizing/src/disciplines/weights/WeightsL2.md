# WeightsL2

Level-2 weights static toolbox (`classdef WeightsL2`, `methods (Static)` only). Called as
`WeightsL2.method(...)`; never instantiated. `F16WeightsL2` inherits `WeightsModelL2` and delegates
here.

**L2 is surface density × area for the structural groups, plus fractions of gross weight** for
landing gear, installed engine and all-else-empty.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `OEW`, `weight_wing`, `weight_tail`, `weight_fuselage`, `weight_landing_gear`, `weight_installed_engine`, `weight_all_else_empty` |
| Low-level | `wing_unit_weight`, `HT_unit_weight`, `VT_unit_weight`, `fus_unit_weight`, `LG_fraction`, `jet_engine_weight_roskam`, `turboprop_engine_weight_roskam`, `engine_weight_brandt` |

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

**Uninstalled engine weight, JET** [metabook Eqs. 7.13-7.19; Roskam Airplane Design Part V]. Five
terms on SLS thrust per engine, `T0` in lbf:

| Term | Formula | Eq. |
|---|---|---|
| dry | $0.521\,T_0^{0.9}$ | 7.13 |
| oil | $0.082\,T_0^{0.65}$ | 7.14 |
| thrust reverser | $0.034\,T_0$ | 7.15 |
| controls | $0.26\,T_0^{0.5}$ | 7.16 |
| starter | $9.33\,(W_{dry}/1000)^{1.078}$ | 7.18 |

Total is the sum, Eq. 7.19. **Turbojet / turbofan only.** See §Engine-type applicability below.

**Uninstalled engine weight, TURBOPROP** [metabook Eq. 7.20; Roskam Part V]. A **single** term on
rated shaft power, `P` in shp:

$$W_{eng} = P^{0.9306}\,10^{-0.1205}$$

It carries no oil, controls or starter contribution, so the two totals are not comparable
term-by-term. Whether Eq. 7.20 includes the propeller and gearbox is unrecorded in the extract;
`_TODO` on the static.

**No consumer yet.** No example aircraft is a turboprop. `Aero481WeightsL1` and `B777WeightsL2` both
call the jet form.

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

## 4. Two rules

- **`OEW(W_TO)` must evaluate both fraction terms at the passed argument.** It must not read the
  `W_all_else_empty` / `W_installed_engine` properties, which are pinned to the object's own `W_TO`.
  Guarded by `TestWeightsL2.testOEWScalesWithItsArgumentNotAFrozenWTO`.
- **The ×1.3 installed factor is L2-only.** L2 has no installation buildup, so one lumped factor is
  correct here; L3 builds the installation item by item and would double-count it.
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

---

## Engine-type applicability of `jet_engine_weight_roskam`

`jet_engine_weight_roskam` **is a jet correlation, not a general estimate**, and
`turboprop_engine_weight_roskam` is the prop counterpart. Four independent lines of evidence for the
split:

1. **The independent variable is thrust.** `T0` = max SLS thrust in lbf
   [metabook_data.md:612]. A reciprocating or turboprop engine is rated in *power*, not thrust.
2. **The metabook prints a separate turboprop equation.** Immediately after Eq. 7.19 it gives
   `Weng = P^0.9306 * 10^(-0.1205)` (Eq. 7.20), keyed on rated shaft horsepower
   [metabook_data.md:615]. A single correlation covering all engine types would not need a second
   form. That equation is now `turboprop_engine_weight_roskam`.
3. **The reverser term is jet-specific.** Eq. 7.15's $0.034\,T_0$ is a thrust reverser
   [metabook_data.md:609]. A propeller aircraft reverses by blade pitch and has no reverser unit.
4. **Nicolai scopes the identical starter term to jets.** Eq. 7.18's
   $9.33\,(\cdot)^{1.078}$ is Nicolai Eq. 20.26, printed under the heading **"One or Two Jet
   Engines -- Cartridge and Pneumatic"** [Nicolai & Carichner Eq. 20.26, p. 559;
   Nicolai_Aircraft_Design_Vol_I/20_refined_weight_estimate.md:313].

**Two narrower limits follow from evidence 4**, both currently unguarded:

- **Engine count.** Nicolai writes the starter term as $9.33\,(N_E W_{ENG}	imes10^{-3})^{1.078}$,
  with the engine count *inside* the power. The framework form omits $N_E$, so it is the
  $N_E = 1$ case. `B777WeightsL2` calls it at per-engine thrust and multiplies the total by
  $N_{en}$, which gives $N_E\,9.33\,x^{1.078}$ instead of $9.33\,(N_E x)^{1.078}$. For a twin
  that understates the starter term by $2 - 2^{1.078} = 5.3\,\%$ of it. The starter is the
  smallest of the five terms, so the effect on OEW is far smaller still.
- **Start system and engine count band.** Nicolai gives three different starter correlations:
  Eq. 20.26 one-or-two-engine cartridge/pneumatic (the one used), Eq. 20.27 one-or-two-engine
  electrical ($38.93$, $0.918$), and Eq. 20.28 four-or-more pneumatic ($49.19$, $0.541$). Nothing
  in the code records which of the three a given aircraft should take.

**Not book-verified.** The primary citation is Roskam *Airplane Design Part V*, which is **not in
`docs/reference_extracts/`** -- the repo holds Parts I, II and III only. Every coefficient here comes
from `metabook_data.md`, a secondary source, corroborated on the starter term alone by Nicolai.

**Guards.** `TestWeightsL2.testTurbopropEngineWeightHandComputed` (469.1373 lbf at 1000 shp, hand
arithmetic in the test comment), `testTurbopropEngineWeightIsAPowerLaw` (the `P^0.9306` scaling
property), `testTurbopropAndJetFormsAreDistinct` (the two forms must not coincide, and shaft power
must be positive).

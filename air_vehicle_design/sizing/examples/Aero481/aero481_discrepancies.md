# F-35 / Aero 481 discrepancy log

Mirror of the metabook D1-D9 style (`docs/reference_extracts/metabook_data.md` "Known
discrepancies") and `B777_decisions.md`, for the `examples/Aero481/` example whose design
provenance is the Aero 481 Design01/A03 student code.

**RULE (CLAUDE.md / scribe brief): never resolve a discrepancy unilaterally.** Each entry
carries a PROPOSED disposition for the user to approve at Gate-1. Nothing here is decided.

Provenance tag: `[A481 <file>:<line>]` = Aero 481 code at `C:\Users\darsh\Downloads\Aero 481
Code\`. Cross-references to `metabook_data.md` D4 (which already logged three of these).

---

## A1 — `Swet = 4·S` is uncited and self-inconsistent

- Source: `[A481 Design01.m:33-36]` — `Aircraft.Swet_Fxn = @(S) 4*S;` annotated **"I made
  this up"**. A03.m:60-61 feeds it wing area `S`, with a commented alternative to feed `MTOW`
  — the author was unsure whether it is a function of area or weight.
- Why it matters: it sets `CD0 = Cf·Swet/S` in the A03 cruise/dash BRE, i.e. the whole L/D.
  An uncited, self-inconsistent regression cannot back an equation in the framework
  (zero-uncited-equations rule).
- Cross-ref: `metabook_data.md` D4(c) already logged this, disposition "do NOT use Swet=4·S".
- **PROPOSED disposition:** REJECT. Use the cited Roskam Vol. I Table 3.5 jet-fighter
  regression already in `GeomL1.lookup_swet('jet_fighter')` (`Swet = 10^-0.1289·W_TO^0.7506`).
  Record the quote in `Aero481GeomL1.md`. No `Swet=4·S` anywhere in the F-35 classes.

## A1b — A481 uses TWO different clean CD0 (mission 0.014 vs constraints 0.0236)

- Source: the A03 MISSION drag uses `CD0_clean = Cf·Swet/S` with `Swet = 4·S`
  `[A481 Design01.m:36 Swet_Fxn = @(S) 4*S; A03.m:60,65]` = `0.0035·4 = 0.014` (constant —
  `Swet=4·S` makes `Swet/S` a constant 4). The CONSTRAINT set (`+Constraints/*`) instead reads
  the config-table `CD0.Clean = 0.0236` `[Design01.m:64]` — a DIFFERENT clean CD0.
- Why it matters: Aero 481 is INTERNALLY inconsistent about the clean parasite drag. The
  framework mission reads `Aero481AeroL1.drag_polar`; the framework constraints read
  `Aero481AeroL1.get_config_polar`. If `drag_polar` returns 0.0236 (the config value), the mission
  L/D is too low, so it burns too much fuel — the A03 fuel fraction comes out 0.386 vs A03's
  0.343, and the F-35 sizes ≈2× too heavy.
- Distinct from A1: A1 is about the GEOMETRY wetted-area regression (`Swet=4·S` REJECTED there
  for the Roskam Table 3.5 TOGW regression). A1b is about the MISSION clean CD0, where the same
  `Swet=4·S` is KEPT (via `swet_over_sref = 4`) for A03 fidelity — the two uses are separate.
- **DISPOSITION (implemented 2026-08-15):** reproduce BOTH faithfully, do NOT reconcile.
  `drag_polar` clean `CD0 = Cfe·swet_over_sref = 0.014` (the A03 mission value; `[metabook
  Eq. 4.8 = Raymer 6th ed. Eq. 12.23]` skin-friction method). `get_config_polar("clean")` keeps
  the config-table `CD0 = 0.0236` (the constraint value). `swet_over_sref = 4` is `_TODO —
  UNCITED` (A481's "I made this up" `Swet=4·S`, kept only for A03 mission fidelity). At AR=4,
  Λ_LE=0 the mission clean polar gives K1 = 0.085165 → L/D_max = 1/(2·√(0.014·0.085165)) = 14.48.

## A2 — `Utility.Oswald` provenance is a web calculator, not a textbook

- Source: `[A481 Oswald.m:5]` — `e = 1.78(1-0.045·AR^0.68)-0.64`, cited
  `https://calculator.academy/oswald-efficiency-factor-calculator/`.
- Finding: this formula is **bit-identical to Raymer 6th ed. Eq. 12.48** (the low-sweep,
  Λ_LE < 30° branch of the framework `AeroL2.oswald_eff`). So the web-calculator citation is
  really Raymer Eq. 12.48.
- Why it matters: the induced-drag factor `K1 = 1/(π·AR·e)` in every A481 constraint.
- **PROPOSED disposition:** RE-CITE to `[Raymer 6th ed. Eq. 12.48]` and use the framework
  `AeroL2.oswald_eff(AR, Λ_LE)`. Two sub-cases for the user:
  - If the F-35 `Λ_LE` is left unset / < 30°: framework value = A481 value exactly (0.9344 at
    AR=4) — no delta.
  - If a real F-35 `Λ_LE ≥ 30°` is supplied: framework uses Eq. 12.49 (sweep-corrected), which
    A481 never does. The report quantifies the delta. `Λ_LE` itself is `_TODO — UNCITED`.

## A3 — `g = 9.087` gravity typo

- Source: `[A481 InstantaneousTurn.m:32]` — `g = 9.087;` with the adjacent comment reading
  "define gravity (9.807 m/s^2)". A transcription typo (9.087 vs 9.807), ≈ 7.9% low.
- Why it matters: the instantaneous-turn load factor `n = ω·V/g` is ≈ 7.9% too HIGH with the
  typo, over-stating the constraint.
- Cross-ref: `metabook_data.md` D4(b). The framework `InstantaneousTurnConstraint` already
  documents this in its header (PROVENANCE (a)) and uses English `g = 32.174 ft/s²`.
- **PROPOSED disposition:** use the correct gravity (32.174 ft/s² / 9.807 m/s²). Already
  handled correctly by the existing `InstantaneousTurnConstraint`; the F-35 wires to it
  unchanged. Log only.

## A4 — climb gradients use `asin(...)`, not `sin(...)`

- Source: `[A481 All.m:28-30]` — `GSL = asin(213/343); Galt = asin(121/300);`, then
  `[A481 Climb.m:79]` / `[A481 Ceiling.m:25]` add `+ G` directly to a T/W value.
- Finding: the climb equation adds a GRADIENT (= sin γ = height/distance = the ratio itself,
  213/343 = 0.6210), but A481 passes `asin` of that ratio (the ANGLE in radians, 0.6691).
  For the second segment `asin(121/300)=0.4151` vs the ratio `0.4033`.
- Why it matters: the climb-gradient T/W floor is over-stated by (angle − sinγ). The plan's
  own G values (0.6210 / 0.4033) are the SIN-RATIO, confirming `sin` is intended.
- Cross-ref: `metabook_data.md` D4(a), disposition "use sin (the gradient ratio), not asin".
- **PROPOSED disposition:** pass `G = sin γ` (the ratio) to `ClimbGradientConstraint`, i.e.
  `G = 213/343 = 0.6210` (SL climbs) and `G = 121/300 = 0.4033` (altitude climbs). These are
  the numbers the F-35 requirements JSON carries. `oei = false` (single engine). Note: the
  213/343 and 121/300 ratios themselves are `_TODO — UNCITED` (student RFP numbers).

## A5 — AR = 4 vs published F-35A ≈ 2.66

- Source: `[A481 Design01.m:49]` — `Aircraft.AR = 4;`. Published F-35A: span 35 ft, area
  460 ft² → AR = 35²/460 = **2.66** (Part I of `aero481_data.md`).
- Why it matters: AR sets `K1 = 1/(π·AR·e)`; AR=4 gives a lower induced drag than the real
  F-35A. It propagates into every constraint and the mission L/D.
- **PROPOSED disposition:** carry `AR = 4` as the DESIGN input (faithful to Design01), marked
  `_TODO — UNCITED` (student value), with the published 2.66 flagged loudly in the comparison
  report as a fidelity/design gap — NOT silently overwritten. The framework reproduces the
  Design01 point; the published F-35A is a cross-check.

## A6 — added thrust lapse (Aero 481 has NONE) — largest deliberate deviation

- Source: every `[A481 +Constraints/*]` uses installed thrust at altitude with no
  `α = T(alt)/T_SL` term — Aero 481 models no thrust lapse at all.
- Framework: applies `α = σ^0.6` on the AB scale [metabook Eq. 10.9 / `PropL1.sigma_lapse`]
  plus a mil-on-AB renormalization `α_mil = (28000/43000)·σ^0.6 = 0.6512·σ^0.6` (mirroring
  `PropL2.get_thrust_lapse_mil_on_AB_scale`). This puts every F-35 constraint on the same
  sea-level-static `T_SL/W_TO` axis the framework diagram uses.
- Why it matters: this is the SINGLE LARGEST intentional model difference from Aero 481, and
  it shifts every altitude constraint. It cannot be silent.
- **PROPOSED disposition:** apply the lapse (framework convention), document it prominently,
  and give it its OWN section in `aero481_comparison.m`. The lapse exponent `m = 0.6` for
  a low-bypass AB turbofan is `[Martins/metabook Eq. 10.9]`; whether 0.6 is right for the
  F135 (vs a higher m) is a `_TODO` modelling choice, same class as B777 D5.

## A7 — OEW regression provenance (`0.882·W^-0.055`)

- Source: `[A481 Design01.m:23-26]` — `We/W0 = 0.882·W0[lbm]^-0.055`, annotated "regression
  from Sainristil team. thanks!".
- Finding: a student-team fit, no textbook citation. The framework's cited fighter OEW
  fraction is `[Raymer Table 3.1 jet_fighter]` `We/W0 = 2.34·W0^-0.13`
  (`WeightsL1.lookup_coeffs('jet_fighter')`) — a DIFFERENT curve.
- Why it matters: OEW fraction is the dominant term in the TOGW closure denominator.
- **PROPOSED disposition:** carry the Sainristil regression as the F-35 baseline OEW fraction
  (faithful to Design01), marked `_TODO — UNCITED`, with a deliberately-failing `testTODO`
  guard until a primary source is found. The comparison report evaluates BOTH the Sainristil
  and the Raymer Table 3.1 curves and shows the delta. User decides which is the design curve.

## A8 — A03's fixed fuel fractions are uncited

- Source: `[A481 A03.m:24-36,91]` — `ff1=0.995, ff2=0.99, ff3=0.96, ffdescent=0.98,
  ffres=0.95, ff4=0.99·0.99`. None carry a citation.
- Finding: the repo has a CITED fighter fixed-fraction row
  (`MissionEquations.roskam_fixed_fraction`, `[Roskam Part I Table 2.1]`: startup/taxi/takeoff
  0.990, climb 0.93, descent 0.990, landing 0.995).
- Why it matters: zero-uncited-equations rule; and "every segment burns fuel" (A03 has no
  landing segment — landing = 0.995 must be added).
- **PROPOSED disposition:** SUBSTITUTE the cited Roskam fighter fractions for A03's uncited
  ones; document the substitution in `aero481_requirements.md`. Keep the physics segments
  (cruise-out/dash/CAP/cruise-back) as Breguet. Reserve = 0.05 [A03.m:91] is a stated design
  reserve (carried; `_TODO` if a primary basis is wanted).

## A9 — MetaEngine keeps a thrust-reverser term for a fighter

- Source: `[A481 MetaEngine.m:7]` — `W_rev = 0.034·Thrust` (thrust-reverser weight), summed
  into the engine weight. A fighter (F135) has no thrust reverser.
- Finding: the shared `WeightsL1.engine_weight_roskam` keeps this term for parity with
  MetaEngine (and with the B777 path, which legitimately has reversers).
- Cross-ref: `WeightsL1.engine_weight_roskam` header already flags Eq. 7.15 as the reverser
  term; `B777WeightsL2.md` uses it legitimately.
- **PROPOSED disposition:** keep the term for MetaEngine parity (the F-35 uses the SAME shared
  static), marked `_TODO` — a fighter-specific no-reverser variant is deferred. Quantify the
  reverser-term contribution in the comparison report.

---

## `_TODO — UNCITED` roll-up (Gate-1 sign-off list)

| # | Item | Where | Stand-in | Needs |
|---|---|---|---|---|
| A5 | `AR = 4` | geom | 4 (Design01) | student value vs publ. 2.66 — confirm design AR |
| A7 | OEW `0.882·W^-0.055` | weights | Sainristil fit | primary source or adopt Raymer Table 3.1 |
| — | `T/W = 1.2`, `W/S = 92.2 psf` design point | studies/comparison | Design01 | student design choice |
| A1b | `swet_over_sref = 4` (mission clean CD0) | aero | A481 A03 `Swet=4·S` | primary Swet/Sref |
| — | CD0 config table (0.0236 …) | aero | Design01 ("thank you Ian") | primary source |
| — | TSFC 0.35 / 0.65 / 1.70 | prop | Design01 | primary F135 deck data |
| A6 | lapse exponent `m = 0.6` for F135 | prop | metabook Eq. 10.9 | modelling choice (like B777 D5) |
| A4 | climb gradient ratios 213/343, 121/300 | requirements | A481 RFP | student RFP numbers |
| — | payload 18,000 lbf + 441 lbf crew | weights/mission | Design01 | F-35 stores document |
| — | `Λ_LE`, RSS / all-moving-tail flags | geom/tail | unset | F-35 planform document |
| — | CAP condition (alt/Mach), combat time | mission | A03 (35 kft, 2×2 min) | RFP / doctrine |
| — | takeoff/landing distances, μ, BFL | requirements | — | RFP field-length requirement |
| A9 | reverser term in engine weight | weights | kept (MetaEngine parity) | fighter no-reverser variant |

Every `_TODO — UNCITED` item above needs a deliberately-failing `testTODO` guard in the F-35
tests (labelled as such) until a citation is pinned — the only expected `run_all_tests`
exception per CLAUDE.md.

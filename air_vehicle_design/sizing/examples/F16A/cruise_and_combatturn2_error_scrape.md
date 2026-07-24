# Cruise & Supersonic Combat Turn (Combat Turn 2) — error scrape

## RESOLUTION (2026-07-23) — Cruise alpha-basis fix implemented

Per §2 below, implemented and verified via `run_all_tests`
(1168/1169 tests pass; the sole failure,
`TestGeomL1/testTODO_AileronFractionNotAvailable`, is a pre-existing,
deliberately-failing TODO test unrelated to this change):

- `src/base/PropulsionBase.m`: new concrete `thrust_lapse_mil_on_AB_scale`
  method, defaults to the AB-basis `thrust_lapse` (so any subclass that
  doesn't override it, e.g. `F16PropL1`, is unaffected).
- `src/disciplines/propulsion/PropL2.m` + `examples/F16A/F16PropL2.m`: real
  override — `alpha_mil * (T_SL_mil/T_SL_wet)`, Mattingly Eq. 2.54b
  renormalized onto the AB scale per Brandt's own `alpha_mil_T_AB`
  convention.
- `src/constraints/ThrustConstraint.m`: new optional 8th constructor arg
  `powerSetting` (`"AB"` default / `"mil"`), fully backward-compatible with
  every non-Cruise call site.
- `tests/constraints/TestThrustConstraint.m`: Cruise section updated to pass
  `"mil"` and check `thrust_lapse_mil_on_AB_scale` against
  `b.constraints.cruise.alpha_mil_T_AB` instead of `alpha_AB`.
- `F16PropL1` deliberately left untouched (user-approved scope decision) —
  Cruise stays inaccurate at L1 specifically; see §4.

**Before → after** (required_TW vs. Brandt, 21-point W/S sweep):

| Level | Before | After |
|---|---|---|
| L1 | −65.1% to −66.6% | **unchanged** (−65.1% to −66.6%, no mil-power model) |
| L2 | −57.4% to −58.8% | **+8.9% to +12.4%** |
| L3 | −58.1% to −59.9% | **+5.8% to +10.7%** |

L2/L3 flip from ~−58% under to a smaller ~+6–12% over — order-of-magnitude
improvement, and in the right ballpark for the remaining, expected
generic-Mattingly-vs.-Brandt's-calibrated-engine-deck gap (same class of
residual already documented for Combat Turn 2's AB branch in §3).

---


**Status: documentation only, no `.m` files edited.** Live-verified via
`matlab -batch` against the current (uncommitted) working tree, which already
includes the `F16AeroL3` wave-drag fix (`F16AeroL3_wave_drag_fix.md`). Scope:
`ThrustConstraint`'s two worst-performing F-16 conditions in
`tests/constraints/TestThrustConstraint.m` —

- **Cruise**: 36,000 ft, M=0.87, n=1.0, 0% AB (dry/mil power), beta=0.8997
- **Combat Turn 2** (the "Supersonic Combat Turn"): 36,000 ft, M=1.4, n=1.4,
  100% AB, beta=0.8997

Both read far low vs. Brandt at every fidelity level. This doc traces each
gap to a specific term in the Mattingly Master Equation
(`A/(W/S) + B*(W/S) + C + D`, see `ThrustConstraint.m` header) and quantifies
how much of the miss each term explains, using live numbers, not estimates.

---

## 0. Constraint-assembly layer — confirmed NOT the cause

`Both_WbyS_TbyW.required_TW` (`src/constraints/Both_WbyS_TbyW.m:37`) is a
direct, literal implementation of the Master Equation with no algebraic
shortcuts, and `TestThrustConstraint.testRequiredTWMatchesHandComputedMasterEquation`
already independently re-derives it from the raw (unsimplified) Mattingly form
and checks agreement to `RelTol=1e-10`. Re-read both files: no bug here. Every
gap below traces to the **inputs** the constraint receives from `aero` and
`prop` (CD0/K1/K2 and alpha), not to how they're assembled.

---

## 1. Live numbers (matlab -batch, current working tree)

### 1a. Drag polar (CD0, K1, K2) at each condition

| Condition | Level | CD0 | K1 | K2 | vs. Brandt CD0 |
|---|---|---|---|---|---|
| Cruise | L1 | 0.01599 | 0.11677 | −0.00000 | −6.0% |
| Cruise | L2 | 0.01599 | 0.11677 | −0.00734 | −6.0% |
| Cruise | L3 | 0.01536 | 0.11677 | −0.00708 | **−9.6%** |
| Cruise | **Brandt** | **0.01700** | 0.11603 | −0.0066 | — |
| Combat Turn 2 | L1 | 0.01599 | 0.22610 | 0.00000 | **−60.6%** |
| Combat Turn 2 | L2 | 0.01599 | 0.22610 | 0.00000 | **−60.6%** |
| Combat Turn 2 | L3 | 0.03988 | 0.22610 | 0.00000 | −1.8% |
| Combat Turn 2 | **Brandt** | **0.04063** | 0.22610 | 0 | — |

K1 matches Brandt exactly at Combat Turn 2 (both use the corrected
supersonic-form K1, `Raymer 6th ed. Eq. 12.51`, see `F16Baseline.m`'s
2026-07-23 correction) — K1 is not a contributor to either gap below.

### 1b. Thrust lapse (alpha, AB basis — see §2 for why this matters at Cruise)

| Condition | L1 alpha | L2 alpha | Brandt alpha_AB | Brandt alpha_mil_T_AB |
|---|---|---|---|---|
| Cruise | 0.483741 | 0.367395 | 0.332642 | **0.171083** ← condition's true basis |
| Combat Turn 2 | 0.483741 | 0.600665 | 0.556558 | n/a (condition is 100% AB) |

Note L1's alpha is **identical** at both conditions (0.483741) despite one
being subsonic/dry and the other supersonic/full-afterburner — see §4.

### 1c. required_TW vs. Brandt, 21-point W/S sweep (`WS_RANGE_BRANDT = 20:7:160`)

| Condition | Level | diff% range | diff% shape |
|---|---|---|---|
| Cruise | L1 | −65.1% to −66.6% | flat |
| Cruise | L2 | −57.4% to −58.8% | flat |
| Cruise | L3 | −58.1% to −59.9% | flat |
| Combat Turn 2 | L1 | −30.4% to −54.1% | steep (worst at low W/S) |
| Combat Turn 2 | L2 | −44.0% to −63.0% | steep (worst at low W/S) |
| Combat Turn 2 | L3 | **−8.4% to −8.9%** | flat, small |

Full 21-row tables per level are reproducible via
`testF16CruiseRequiredTWTable`/`testF16CombatSupRequiredTWTable`
(`fidelityLevel` = L1/L2/L3) — omitted here for brevity, archived in this
session's run log.

---

## 2. Cruise: dominant cause is an alpha-**basis** mismatch, not a formula bug

Brandt's own Cruise row does **not** use `alpha_AB` (T_AB/T_SL_AB). It uses
`alpha_mil_T_AB = alpha_dry * (T_SL_dry/T_SL_AB) = 0.171083` — the dry/mil
thrust lapse, **re-normalized onto the AB-thrust scale** — because Brandt's
constraint diagram plots every condition (whether flown dry or with
afterburner) on one shared `T_SL_AB/W_TO` axis. `ThrustConstraint`, by
contrast, unconditionally calls `prop.thrust_lapse(state)`, which
`PropulsionBase`'s own header (`src/base/PropulsionBase.m:8`) documents as
**always** returning "α = T(alt,M)/T_SL at the AB/max power setting" — there
is no parameter anywhere in `ThrustConstraint`'s constructor or
`PointPerformanceBase`'s interface to select a different power setting per
condition. Cruise is flown at 0% AB, so this is the wrong basis for this
condition specifically (Max Mach, Max Alt, Combat Turn 1/2, and Ps are all
100% AB conditions, so the same call is *correct* for all of them — this is a
Cruise-specific gap, not a general one).

**This alone predicts nearly the entire gap.** Take the ratio of what
`ThrustConstraint` actually uses to what Brandt's row actually uses, and
project the effect on required_TW (every A/B/C/D term divides by alpha, so a
too-high alpha by factor `r` scales required_TW down by ≈`1/r` at every W/S):

| Level | alpha used | alpha needed | ratio r | predicted diff% (1/r − 1) | observed diff% |
|---|---|---|---|---|---|
| L1 | 0.483741 | 0.171083 | 2.827 | −64.6% | −65.1% to −66.6% |
| L2/L3 | 0.367395 | 0.171083 | 2.147 | −53.4% | −57.4% to −59.9% |

The alpha-basis mismatch alone accounts for **53–65 of the ~57–67 percentage
points** of the miss at every fidelity level. The remainder is CD0 reading
low vs. Brandt's flight-calibrated polar (−6.0% at L1/L2's flat Cfe estimate;
a separate, slightly larger **−9.6%** at L3 — see §5). This is why Cruise
error does not shrink from L1→L3 the way Combat Turn 2's does: the dominant
error term (alpha basis) is architectural and identical at every fidelity
level, not a drag-polar fidelity gap.

**The fix does not require new propulsion physics.** `F16PropL2` already
implements everything Brandt's `alpha_mil_T_AB` needs and is already
unit-tested independently: `compute_thrust_lapse_mil`
(`examples/F16A/F16PropL2.m:64`, delegating to `PropL2.get_thrust_lapse_mil`,
Mattingly Eq. 2.54b) plus the already-present `T_SL_mil=15000` /
`T_SL_wet=23770` properties needed for the renormalization
(`alpha_mil_T_AB = compute_thrust_lapse_mil(state) * T_SL_mil/T_SL_wet`). The
gap is purely that `ThrustConstraint`/`PointPerformanceBase` never call it —
an interface gap, not a missing-equation gap, **at L2/L3**. `F16PropL1`
(§4) has no mil/AB distinction at all, so L1 would need its own extension
even if `ThrustConstraint` gained a basis selector.

---

## 3. Combat Turn 2: dominant cause is CD0's zero Mach-sensitivity at L1/L2

Combat Turn 2 is 100% AB, so the alpha-basis issue in §2 does not apply here
— `prop.thrust_lapse` (AB basis) is the *correct* basis for this condition,
and indeed L2's alpha is within +7.9% of Brandt's (0.600665 vs. 0.556558).

The dominant cause instead is CD0. `AeroL1.get_CD0`
(`src/disciplines/aerodynamics/AeroL1.m:69-73`) —
which **both** `F16AeroL1` and `F16AeroL2` call unchanged
(`AeroL2.get_CD0` at `src/disciplines/aerodynamics/AeroL2.m:66-68` just
delegates back to `AeroL1.get_CD0`) — is `CD0 = Cf * S_wet / S_ref`
with `Cf=0.0035` a **flat, Mach-independent constant**
(`lookup_Cf('jet_fighter')`, Raymer 6th ed. Table 12.3). This is confirmed
live: L1 and L2 produce the **identical** CD0=0.01599 at both the M=0.87
Cruise point and the M=1.4 Combat Turn 2 point — the model is structurally
incapable of ever seeing a Mach effect, let alone the wave-drag rise a real
supersonic fighter experiences. Brandt's own CD0 at Combat Turn 2 (0.04063)
is 2.5× the subsonic value — almost entirely wave drag. This is Raymer's
documented L1 Cfe method working exactly as designed (a single
category-average friction coefficient is *the* defining simplification of
that fidelity level) — not a coding bug, but a real and large
(**−30% to −63%** required_TW) consequence of applying an L1/L2-fidelity drag
model at a supersonic design point.

**L3 already fixes most of this.** `F16AeroL3.compute_CD0_wave`
(`examples/F16A/F16AeroL3.m:343-...`, Raymer Eqs. 12.44-12.45, landed this
session per `F16AeroL3_wave_drag_fix.md`) brings CD0 to 0.03988 — only **1.8%
low** vs. Brandt's 0.04063 — and the required_TW gap collapses accordingly,
from −30–63% down to a flat **−8.4% to −8.9%**.

**The L3 residual (−8.4% to −8.9%) is explained almost entirely by
propulsion, not aero.** No `F16PropL3` exists, so L3 pairs `F16AeroL3` with
`F16PropL2` (documented convention, `TestThrustConstraint.buildDisciplines`).
L2's alpha at this condition (0.600665) reads **+7.9% high** vs. Brandt's
0.556558. Combining the two known ratios:

```
(CD0_ours/CD0_Brandt) / (alpha_ours/alpha_Brandt) − 1
  = (0.03988/0.04063) / (0.600665/0.556558) − 1
  = 0.98155 / 1.07925 − 1
  = −9.05%
```

— which matches the observed −8.4% to −8.9% almost exactly. This is a
genuine, smaller propulsion-formula-vs.-Brandt gap (Mattingly's generic
TR-based Eq. 2.54a piecewise formula vs. Brandt's specific F100-PW-200 engine
deck are expected to differ by a few percent; already flagged as an accepted
gap in `TestThrustConstraint.m`'s `ALPHA_ABS_TOL=0.10`), not a bug — but it is
now the identified, quantified source of essentially all of L3's remaining
Combat Turn 2 error, which the existing test comments did not previously
pin down (they attributed the residual jointly to "CD0/K1 buildup vs.
Brandt's flight-calibrated polar" without separating the two).

---

## 4. Secondary finding: `F16PropL1`/`PropL1` has no Mach dependence at all

`PropL1.sigma_lapse` (`src/disciplines/propulsion/PropL1.m:64-70`) is
`alpha = (rho/rho_SL)^m` — a function of **altitude only**. It cannot
distinguish M=0.87 from M=1.4 at the same altitude, or dry power from full
afterburner. This is confirmed live: L1 returns the **exact same**
alpha=0.483741 for both Cruise and Combat Turn 2. This happens to land within
`ALPHA_ABS_TOL=0.10` of Brandt's Combat Turn 2 alpha_AB by coincidence
(−13.1% relative, 0.073 absolute), but is not currently tested against Brandt
at all — every existing `test*AlphaNearBrandt` method in
`TestThrustConstraint.m` hardcodes `F16PropL2()`, never `F16PropL1()`. This
is a real, currently-invisible-to-tests contributor to L1's Combat Turn 2 gap
(alpha too low by 13% compounds the CD0 gap) and is architecturally the same
class of problem as F16PropL1 having no mil/AB throttle-setting concept for
§2's fix either.

## 5. Secondary finding: L3's own subsonic CD0 buildup reads low at Cruise

Independent of §2's alpha-basis issue: `F16AeroL3`'s Raymer component
skin-friction buildup (`AeroL3.get_CD0_buildup`, unaffected by the wave-drag
fix since M=0.87 < 1.2) computes CD0=0.01536 at Cruise — **9.6% below**
Brandt's 0.01700, and further below than L1/L2's flat-Cfe 0.01599 (−6.0%).
The wave-drag fix in `F16AeroL3_wave_drag_fix.md` only touches the `M≥1.2`
branch and does not touch this. This is a small contributor next to §2's
dominant alpha-basis gap, but is a distinct, real discrepancy worth a look in
its own right if/when Aerodynamics gets its own deep-dive pass (component
`S_wet`/`Cf`/`FF`/`Q` buildup at a subsonic point) — not investigated further
here since it is dwarfed by §2 at this condition.

---

## 6. VnV/BrandtF16A discrepancy check

Checked every Brandt-sourced value used above (`alpha_AB`, `alpha_mil_T_AB`,
`CD0`, `K1`, `K2`, `TW_Cruise`, `TW_CombatSup`) against `F16Baseline.m`'s own
citations and the 2026-07-23 K1/K2 corrections already recorded there.
**No new internal Brandt discrepancy found — no `VnV/BrandtF16A/todo.md`
entry warranted.** Everything identified above is framework-vs-Brandt
divergence (expected — the whole point of comparing a textbook buildup
against a flight-calibrated model), not Brandt-internal disagreement.

---

## Summary for next-step decision

**Cruise (all 3 levels, −57% to −67%):** primarily an architecture gap —
`ThrustConstraint`/`PointPerformanceBase` has no way to request a mil-power
(rather than AB-power) thrust lapse for a dry-power condition, even though
`F16PropL2` already implements everything Brandt's own dry-power-on-AB-scale
normalization needs. Fixing this touches a class every point-performance
condition depends on (`ThrustConstraint`, used for Max Mach/Max Alt/Combat
Turn 1/2/Ps too) — an interface change in shared code, not a local one-file
fix, so per `PLAN.md`'s architecture-decision norm this needs an explicit
design decision before implementation: e.g., a constructor parameter on
`ThrustConstraint` selecting AB vs. mil basis (with the T_SL_mil/T_SL_wet
renormalization applied internally when mil is selected), vs. some other
shape. `F16PropL1` additionally has no mil/AB concept to select between at
all (§4), so L1 needs a second, separate decision regardless of how L2/L3
are fixed.

**Combat Turn 2 (L1/L2 −30% to −63%, L3 −8.4% to −8.9%):** L1/L2's gap is the
known, inherent supersonic blind spot of the flat-Cfe method (not a bug);
already effectively "fixed" at L3 by this session's wave-drag work. L3's
small remaining gap is a propulsion (alpha), not aero, residual — most
plausibly closed (if desired) by tightening the Mattingly Eq. 2.54a fit or
accepting it as within the documented `ALPHA_ABS_TOL` tolerance, not by
further aero changes.

No `.m` files were edited to produce this document.

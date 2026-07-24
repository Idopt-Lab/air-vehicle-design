# Remaining constraints — error scrape

**Status: documentation only, no `.m` files edited.** Follow-up to
`cruise_and_combatturn2_error_scrape.md` (Cruise + Combat Turn 2, which
already got a fix — see that doc's RESOLUTION section), covering everything
else: Max Mach, Max Alt, Combat Turn 1 (subsonic), Ps in
`ThrustConstraint`/`TestThrustConstraint.m`, plus `TakeoffConstraint`,
`LandingConstraint`, `StallConstraint`. Live-verified via `matlab -batch`
against the current (post-Cruise-fix) working tree.

## Executive summary

| Constraint | L1 | L2 | L3 | Verdict |
|---|---|---|---|---|
| Max Mach (dash) | −40% to −51% | −47% to −57% | **+2.5% to +3.0%** | L1/L2: known CD0 wave-drag blind spot, same as Combat Turn 2. L3: excellent. |
| Max Alt (ceiling) | **−47% to −50%** | −14% to −19% | −13% to −17% | L1 much worse than L2/L3 — new finding, §2. |
| Combat Turn 1 (sub) | **−0.5% to −5.4%** | −14% to −20% | −14% to −27% | L1 *closest* by compensating errors — coincidence, §3. |
| Ps (excess power) | −0.5% to +2.9% | −1.5% to −4.2% | −3.0% to −10.3% | All small. Best-behaved condition. |
| Takeoff | −23% to +29% (crosses zero) | same shape | same shape | **RESOLVED 2026-07-24** (see §5): missing drag/friction term now implemented; equation reproduces Brandt to <0.5% when fed Brandt's own inputs. These figures are the pre-fix historical gap. |
| Landing | +8.8% (L1) / −9.7% (L2) / −4.2% (L3) | | | Equation itself matches Brandt to <0.1% when fed Brandt's inputs (`testEquationReproducesBrandtLandingPoint`) — gap is purely textbook-vs-flight-calibrated flapped CLmax/CD0. Not a bug. |
| Stall | n/a | | | No Brandt reference row exists to compare against at all (not in Brandt's Consts sheet). Sanity-check only. |

No new large, *undiagnosed* errors in Takeoff/Landing/Stall — their own class
headers and tests already correctly explain the gaps as cited modeling
simplifications, not bugs. The two genuinely new findings are Max Alt's L1
propulsion problem (§2) and Combat Turn 1's coincidental L1 accuracy (§3),
both propulsion-side, both previously invisible because **no test anywhere
compares `F16PropL1`'s alpha against Brandt** (same gap already flagged in
the Cruise doc §4).

---

## 1. Max Mach (dash): same story as Combat Turn 2, already understood

36,000 ft, M=1.6, n=1.0, 100% AB. Live numbers:

| | CD0 | vs. Brandt (0.03933) | alpha | vs. Brandt alpha_AB (0.576980) |
|---|---|---|---|---|
| L1/L2 | 0.01599 | −59.3% | L1: 0.483741 | −16.2% |
| L3 | 0.03834 | −2.5% | L2: 0.549430 | −4.8% |

Identical mechanism to Combat Turn 2 (`cruise_and_combatturn2_error_scrape.md`
§3): the flat, Mach-blind `Cf=0.0035` lookup can't see wave drag at L1/L2
(−59.3% CD0, driving the −40% to −57% required_TW miss); L3's wave-drag fix
(already landed) brings CD0 to within 2.5% and required_TW to **+2.5% to
+3.0%** — the best result of any AB condition. No new action needed; this is
the wave-drag fix already paying off at a second condition.

## 2. Max Alt: L1's propulsion model is badly wrong at 50,000 ft (new finding)

50,000 ft, M=0.87, n=1.0, 100% AB. L1 required_TW (−47% to −50%) is *worse*
than L2/L3 (−14% to −19% / −13% to −17%) despite L1 and L2 sharing the
**identical** flat CD0 (0.01599 vs. Brandt's 0.01700, only −5.9% off — a
small, ordinary gap). The extra ~30 points of L1 error trace entirely to
propulsion, confirmed live:

```
Max Alt   alt=50000  M=0.87   L1 alpha=0.323212   Brandt alpha_AB=0.170290   diff=+89.8%
                                L2 alpha=0.187457   Brandt alpha_AB=0.170290   diff=+10.1%
```

`PropL1.sigma_lapse` (`alpha = (rho/rho_SL)^m`) is nearly **2x too high** at
50,000 ft — far outside the kind of gap seen anywhere else for L1 (contrast
Ps's −2.3% or Combat Turn 1's +0.5%, §3). A too-high alpha lowers predicted
required_TW (alpha is a denominator throughout the Master Equation), which
combined with the ordinary CD0 gap explains essentially all of the extra L1
under-prediction at this condition. This is consistent with the same root
cause flagged in the Cruise doc §4 — `PropL1` has no Mach dependence and
(now confirmed) also degrades badly at extreme altitude — and, like that
finding, is **currently invisible to the test suite**: no
`test*AlphaNearBrandt` method anywhere exercises `F16PropL1`.

## 3. Combat Turn 1 (subsonic): L1 "wins" by coincidence, not merit

20,000 ft, M=0.87, n=4.5, 100% AB. L1 (−0.5% to −5.4%) reads far closer to
Brandt than L2 (−14% to −20%) or L3 (−14% to −27%) — the opposite pattern
from Max Alt. Live alpha:

```
Combat Turn 1   L1 alpha=0.685381   Brandt alpha_AB=0.681777   diff=+0.5%
                L2 alpha=0.752647   Brandt alpha_AB=0.681777   diff=+10.4%
```

At this specific altitude (20,000 ft), `PropL1`'s crude density-power-law
model happens to land almost exactly on Brandt's value, while `F16PropL2`'s
Mattingly Eq. 2.54a formula reads +10.4% high (same class of generic-formula
gap already documented for other AB conditions). Combined with L1's ordinary
CD0 gap (−5.9%, same flat value as everywhere else), the two nearly cancel
at L1 and don't at L2/L3 — this is **coincidental agreement at one altitude,
not evidence PropL1 is more accurate in general** (Max Alt, one condition
away, shows the opposite). Flagging so nobody mistakes this for "L1 is fine."

Separately: L3's own CD0 buildup at this condition is CD0=0.01434, **−15.6%
low** vs. Brandt's 0.01700 — notably lower than L1/L2's flat 0.01599 (−5.9%).
This is the same pattern already found for Cruise (`cruise_and_combatturn2_error_scrape.md`
§5, L3's subsonic component buildup reading low) recurring at a second
subsonic point, now with more evidence it's a real, if secondary, gap in
`F16AeroL3`'s subsonic skin-friction buildup rather than a one-off.

## 4. Ps (excess power): best-behaved condition, no action needed

10,000 ft, M=0.87, n=1.0, 100% AB, Ps=500 ft/s. All three levels land within
about ±10% of Brandt (L1: −0.5% to +2.9%; L2: −1.5% to −4.2%; L3: −3.0% to
−10.3%), consistent with alpha being very close everywhere (L1 −2.3%, L2
+0.9%) and the ordinary −5.9% CD0 gap. Nothing further to investigate here.

## 5. Takeoff / Landing / Stall: not large, not hidden

- **Takeoff**: at the time this doc was written, `TakeoffConstraint.m`'s own header
  documented that it implemented Mattingly's `T≫(D+R)` simplified ground-roll form,
  which omitted a drag/rolling-friction correction term Brandt's own (unsimplified)
  worksheet row includes — `TestTakeoffConstraint.m`'s
  `testF16TakeoffRequiredTWTable` labeled this "known modeling gap,
  not a TakeoffConstraint bug." Live gap was −23% to +29%, crossing zero
  (not a one-directional miss) — consistent with a missing additive term
  rather than a scaling/basis error.
  **RESOLVED (2026-07-24):** the `0.7·CD0_TO/(β·CLmax_TO) + μ` correction term is now
  implemented (`TakeoffConstraint.m`'s Master Equation C term, wired from
  `Constraints.xlsx`'s `SurfaceFrictionCoefficient_mu_` column via `F16ConstraintSet.m`),
  closing the gap this section described — verified to reproduce Brandt's
  `TW_Takeoff` to <0.5% at W/S=90 when fed Brandt's own inputs
  (`TestTakeoffConstraint.m`'s `testEquationReproducesBrandtTakeoffPoint`). See
  `docs/subplans/06_constraint_analysis.md`'s 2026-07-24 update for the corrected
  equation.
- **Landing**: `TestLandingConstraint.m`'s `testEquationReproducesBrandtLandingPoint`
  already proves `LandingConstraint`'s own equation matches Brandt to <0.1%
  when fed Brandt's own flapped `CLmax`/`CD0`. The remaining per-fidelity gap
  (+8.8% L1, −9.7% L2, −4.2% L3) comes entirely from this framework's own
  textbook flap-drag-increment estimate vs. Brandt's flight-calibrated
  flapped values — an Aerodynamics-discipline high-lift-modeling question,
  not a constraints bug.
- **Stall**: no Brandt Consts-sheet row exists for this condition at all
  (confirmed in `StallConstraint.m`'s own header) — nothing to compare
  against, so there is no error to characterize, large or small.

None of the three warrant the kind of fix Cruise got — their gaps are
already correctly attributed to a specific, cited, out-of-scope
simplification, not an undiagnosed architecture bug.

---

## Open items — RESOLVED (2026-07-23)

1. **`F16PropL1`'s thrust lapse was untested against Brandt at every
   condition.** Fixed: added `testThrustLapseVsBrandtAtConstraintConditions`
   to `tests/disciplines/TestPropL1.m`, parameterized over all 6 constraint
   conditions, printing `F16PropL1.thrust_lapse` vs. Brandt's `alpha_AB` with
   diff% for each. Deliberately diagnostic-only (asserts only
   positivity/≤1.0 bounds, not closeness) — same pattern as
   `ThrustConstraint`'s `testF16*RequiredTWTable` methods, since the true gap
   ranges from near-perfect (Combat Turn 1, +0.5%) to +89.8% (Max Alt), so no
   single tolerance would be both meaningful and passing. The underlying
   `PropL1` model itself was intentionally NOT changed (density-only,
   no Mach term) — consistent with the user's earlier "defer L1" decision on
   the Cruise fix; this only adds visibility, it doesn't claim to fix L1's
   accuracy.

2. **`F16AeroL3`'s subsonic CD0 buildup reading ~10-16% low.** Investigated
   component-by-component at both Cruise and Combat Turn 1 (see
   `examples/F16A/F16AeroL3.m`'s `CD0_misc` property comment for the full
   writeup) — confirmed **not a bug**: every buildup formula matches its
   cited Raymer 6th ed. equation exactly, and the roughness-limited Re
   cutoff (Eq. 12.28) never binds at either point. Two real, expected,
   now-documented effects explain the gap instead: (a) an idealized 5-
   component clean buildup with only 2 of Raymer Table 12.7's many possible
   miscellaneous-drag items (gun port + hook) is expected to read below the
   empirically-calibrated flat `Cfe=0.0035` lookup L1/L2 use, absent a
   fuller miscellaneous-drag catalog with no cited F-16 source to support
   it; (b) the buildup is (correctly, per Eq. 12.27) Reynolds-sensitive and
   predicts a *lower* CD0 at Combat Turn 1's higher-Re 20,000 ft point
   (0.01434) than at Cruise's 36,000 ft (0.01536) — but Brandt's own
   `F16Baseline.m` uses the identical CD0=0.01700 at both conditions, so
   part of the apparent gap is this class correctly modeling an effect
   Brandt's simpler tabulated value doesn't vary with altitude. No `.m`
   logic was changed — fabricating additional Table 12.7 items or
   suppressing the Reynolds dependence without a primary source would be
   hardcoding a calibrated result, which PLAN.md prohibits.

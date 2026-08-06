# F-16A Block 10/15 — Constraint Analysis vs Ground Truth

Generated 2026-08-04. Shared W/S grid linspace(20,160,141) psf; per-condition rows sampled at W/S = 90 psf.

**Reference** (the `Reference` and `%Diff` columns): Brandt-F16-A.xls Consts tab, replicated in `VnV/BrandtF16A/BrandtConstraintAnalysis.m`, run over the SAME W/S grid.

**2nd Source** (the `2nd Source` column): none — both sides are fed Brandt's OWN aero/prop, so there is no independent second source for this assembly check; the `2nd Source` column shows `N/A` throughout.

This is a **comparison report, not a test** — no pass/fail assertions, not part of `run_all_tests`, and **nothing here may ever be used to backfill a unit test's expected value**. Where a quantity has more than one valid implementation, each option gets its own row, and rejected variants are reported too so the decisions stay auditable.

**Reading the `Divergence` column.** `BY DESIGN` — the framework computes the *same kind* of quantity as the reference but is *expected* to differ (a different formula family, or a locked decision to follow a physical/T.O. value); a large %Diff there is the correct answer, not a defect, though its magnitude is worth a sanity check. `DEFINITIONAL` — the two sides are *different kinds of quantity altogether*, so the %Diff is not an error measure at all; do not chase it. **Blank** — a genuine agreement check, where a large %Diff **is** worth chasing.

**This is an ASSEMBLY check, not a drag/thrust check.** Both sides read Brandt's own `BrandtAerodynamics`/`BrandtEngine`, injected into the src constraint classes through `BrandtAeroAdapter`/`BrandtPropAdapter`. Any residual %Diff comes from the src constraint-assembly logic (the Master-Equation build and the ground-roll relations), NOT from CD0, K1 or thrust lapse.

**Two accounted-for modeling choices make the two sides algebraically identical.** (1) `K2 = 0`: the adapter returns a symmetric parabolic polar, so the src Master Equation's `K2*n*beta/alpha` term drops out and the equation reduces to Brandt's exact Consts-tab form. (2) A shared fine W/S grid on both sides, so the two grid argmina are directly comparable. With those two choices the agreement holds across the WHOLE sweep, not only at the sampled points — the per-condition rows are sampled at a single representative W/S only for a compact table. The one remaining difference is the dynamic pressure q (src builds it in `AircraftState`, Brandt inline), and both use `atmosisa`, so they agree to well under 1 %.

| Parameter | Fidelity | Computed | Reference | %Diff | 2nd Source | Divergence | Cite | Notes |
|---|---|---|---|---|---|---|---|---|
| **[OPTIMUM DESIGN POINT (shared W/S grid)]** | | | | | | | | |
| Optimum W/S [psf] | src | 111.000 | 111.000 | +0.00% | N/A |  | Brandt Size&Opt (grid argmin over shared W/S array) | Both sides argmin the SAME producer envelope over the SAME grid; the two argmina coincide because the curves are algebraically identical (K2 = 0). Isolates the src optimum search. |
| Optimum T/W [-] | src | 0.7127 | 0.7127 | -0.00% | N/A |  | Brandt Size&Opt (grid argmin over shared W/S array) | src ConstraintAnalysis.optimal_point vs Brandt run().TW_opt on the shared grid. |
| **[PER-CONDITION required T/W at W/S = 90 psf]** | | | | | | | | |
| Max Mach | src | 0.7126 | 0.7126 | +0.00% | N/A |  | Brandt Consts!K23 (max_mach row) | M=1.6, h=36 kft, n=1, 100% AB. src ExcessPower/LevelFlight Master-Eq row vs Brandt max_mach. |
| Cruise | src | 0.4656 | 0.4656 | +0.00% | N/A |  | Brandt Consts!K24 (cruise row) | M=0.87, h=36 kft, n=1, mil (dry) power. src Cruise Master-Eq row vs Brandt cruise; mil thrust lapse via the prop adapter. |
| Max Alt | src | 0.5261 | 0.5261 | -0.00% | N/A |  | Brandt Consts!K25 (max_alt row) | h=50 kft ceiling, M=0.87, n=1, 100% AB, Ps=0. src Max Alt Master-Eq row vs Brandt max_alt. |
| Combat Turn 1 (subsonic) | src | 0.6254 | 0.6254 | -0.00% | N/A |  | Brandt Consts!K26 (combat_turn_sub row) | h=20 kft, M=0.87, n=4.5, 100% AB, Ps=0. src SustainedTurn Master-Eq row vs Brandt combat_turn_sub. |
| Combat Turn 2 (supersonic) | src | 0.6495 | 0.6495 | +0.00% | N/A |  | Brandt Consts!K27 (combat_turn_sup row) | h=36 kft, M=1.4, n=1.4, 100% AB, Ps=0. src SustainedTurn Master-Eq row vs Brandt combat_turn_sup. |
| Excess Power | src | 0.7402 | 0.7402 | +0.00% | N/A |  | Brandt Consts!K28 (ps_500 row) | h=10 kft, M=0.87, n=1, 100% AB, Ps=500 ft/s. src ExcessPower Master-Eq row vs Brandt ps_500. |
| Takeoff | src | 0.4021 | 0.4021 | -0.00% | N/A |  | Brandt Consts!K32 (takeoff row) | Ground-roll T/W, S_TO limit, beta=1. src TakeoffConstraint (Raymer ground-roll) vs Brandt takeoff. |
| **[FIELD / WALL]** | | | | | | | | |
| Landing W/S limit [psf] | src | 138.580 | 138.580 | +0.00% | N/A |  | Brandt Consts!K33 (landing wall) | A W/S upper bound (vertical wall), independent of T/W. src LandingConstraint.WS_max vs Brandt run().WS_landing_max; the src set skips Stall, so Landing is the only wall here. |

**Stall is skipped on both sides.** Brandt's reproduction envelope has no Stall row, so the src set drops it too (`buildSrcConstraints`); Landing is then the only W/S wall.

**Informational only.** No pass/fail here; the deleted unit test `tests/constraints/TestConstraintAnalysisVsBrandt.m` used a 2 % `RelTol`, but that gate is now a report per CLAUDE.md's two-tier rule. No number in this table may backfill a unit test's expected value.


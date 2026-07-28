# Subplan 06 — Constraint Analysis

**Status:** Done — implemented and tested (`src/constraints/`, `examples/F16A/F16ConstraintSet.m`,
`tests/constraints/`), including the TW/WS margin methods and a post-implementation accuracy audit
against Brandt (`examples/F16A/cruise_and_combatturn2_error_scrape.md`,
`examples/F16A/remaining_constraints_scrape.md`) — every flagged gap traces to a cited, documented
modeling simplification, not a bug, EXCEPT ONE: the optional Stall condition was found (2026-07-27,
user-reported) to silently dominate `optimal_point()` at L2/L3, which WAS a bug — see "Plot
Deliverables" below for the fix (`includeStall` now defaults to `false`). Both Plot Deliverables below are built:
`examples/F16A/run_F16_constraint_diagram.m` (single fidelity) and
`examples/F16A/run_F16_constraint_diagram_overlay.m` (L1/L2/L3 fidelity-sensitivity overlay).
**Depends on:** Steps 1–5 (all disciplines needed to run constraints at all fidelities)
**Blocks:** Steps 7, 8 (mission, sizing)

---

## Objectives

Implement the generic constraint analysis framework. The F-16-specific constraint set (8 conditions read from the workbook + a 9th stall condition appended in code) is defined in `examples/F16A/F16ConstraintSet.m` (flat directory) using values read from `examples/F16A/Constraints.xlsx` via `ConstraintSetImporter`. Key deliverables:
1. `optimal_point(aero, prop)` — returns (W/S, T/W) design point.
2. `plot_diagram()` — constraint diagram with feasible region shaded.
3. Same API produces valid diagrams with L1, L2, L3 discipline objects.

---

## Files to Create

### Layer 1 — Generic (`src/constraints/`)

| File | Purpose |
|------|---------|
| `PointPerformanceBase.m` | Abstract base for all constraint types — declares `required_TW`, `name` |
| `Only_TbyW.m` | Abstract category: constraints that bound T/W only (adds `TW_margin`) |
| `Only_WbyS.m` | Abstract category: constraints that bound W/S only (adds `WS_margin`) |
| `Both_WbyS_TbyW.m` | Abstract category: constraints on the T/W-vs-W/S curve (adds `TW_margin`) |
| `ThrustConstraint.m` | Mattingly Master Equation (cruise, turn, dash, climb) — `< Both_WbyS_TbyW` |
| `TakeoffConstraint.m` | Ground-roll takeoff case — `< Both_WbyS_TbyW` |
| `LandingConstraint.m` | Landing ground-roll upper bound on W/S — `< Only_WbyS` |
| `StallConstraint.m` | Stall-speed upper bound on W/S — `< Only_WbyS` |
| `ConstraintAnalysis.m` | Aggregator — receives a list of constraints, computes optimal point + diagram |
| `ConstraintSetImporter.m` | Generic reader for a Constraints.xlsx-style conditions workbook |

### Layer 2 — F-16 specific (`examples/F16A/`, flat directory)

| File | Purpose |
|------|---------|
| `examples/F16A/F16ConstraintSet.m` | Reads the 8 F-16 conditions from `Constraints.xlsx` (via `ConstraintSetImporter`), appends a 9th stall condition, wires each to the F-16 aero/prop objects, returns a configured `ConstraintAnalysis` |

### Tests (`tests/constraints/`)

| File | Tests |
|------|-------|
| `TestConstraintAnalysis.m` | Generic aggregator with toy/stub constraints |
| `TestThrustConstraint.m`, `TestTakeoffConstraint.m`, `TestLandingConstraint.m`, `TestStallConstraint.m` | Per-constraint correctness |
| `TestConstraintSetImporter.m` | Workbook reader |
| `TestF16ConstraintSet.m` | F-16: optimal W/S and T/W within expected range (uses `FixedAeroStub.m`) |

---

## Design Notes

`ConstraintAnalysis` receives a list of `PointPerformanceBase` objects and the discipline objects via constructor (DI). It does not know it is running F-16 constraints. All condition-specific data (β, n, PS, alt, Mach, distances) is assembled by `F16ConstraintSet`, which reads it from `examples/F16A/Constraints.xlsx` via `ConstraintSetImporter`.

Constraint hierarchy: `PointPerformanceBase` → category (`Only_TbyW` / `Only_WbyS` / `Both_WbyS_TbyW`, each adding the margin method for its axis) → concrete constraint (`ThrustConstraint`, `TakeoffConstraint`, `LandingConstraint`, `StallConstraint`).

Inspired by NPTEL notebook (`NPTEL_Fighter_Aircraft_Sizing.ipynb`) class hierarchy, improved for MATLAB + English units.

---

## F-16 Constraint Conditions

Source: `examples/F16A/Constraints.xlsx`, read by `ConstraintSetImporter` and wired into constraint objects by `F16ConstraintSet`. The 8 rows below are the workbook conditions; a 9th (Stall) is appended in `F16ConstraintSet` because the workbook has no Stall row yet.

**CLmax is NOT a constraint input.** The constraint analysis calls `aero.CLmax(state)` at the relevant flight condition. The discipline computes it. Values from Constraints.xlsx (CLmax_TO=1.276, CLmax_land=1.426) are verification targets — see table below.

**TODO (high-lift configuration):** `F16AeroL3` already has an ad-hoc `'TO'`/`'L'` string-config scheme (`delta_flap_TO_deg`/`delta_slat_TO_deg`, `Delta_CLmax_flap(config)`, `get_CLmax_TO`/`get_CLmax_L`) feeding CLmax deltas, but several of the deflection angles are marked "estimated"/"TODO: verify" rather than sourced. Mason, "F-16 configuration" (archive.aoe.vt.edu/mason/Mason_f/F16S04.pdf, slide 10) gives sourced slat/flap deflections for six named configs (takeoff ground roll, takeoff after liftoff, reflexed cruise, max maneuver, approach, landing) — reconcile the current TO/L angles against it, and consider generalizing the bare string configs into a small named-config value class (e.g. `HighLiftConfig` with `slat_deg`/`flap_deg` + static presets) so `get_CLmax(state, config)` can take it as a first-class argument instead of a string literal. Decide scope here rather than folding it into `AircraftState` (pure ISA atmosphere, used by disciplines with no notion of flap position).

**Operational constraints** — all use β = 0.8997:

| # | Name | Alt (ft) | Mach | n | AB% | PS (ft/s) |
|---|------|----------|------|---|-----|-----------|
| 1 | Max Mach | 36,000 | 1.60 | 1.0 | 100 | 0 |
| 2 | Cruise | 36,000 | 0.87 | 1.0 | 0 | 0 |
| 3 | Max Alt (ceiling) | 50,000 | 0.87 | 1.0 | 100 | 0 |
| 4 | Combat Turn 1 (subsonic) | 20,000 | 0.87 | 4.5 | 100 | 0 |
| 5 | Combat Turn 2 (supersonic) | 36,000 | 1.40 | 1.4 | 100 | 0 |
| 6 | Excess Power | 10,000 | 0.87 | 1.0 | 100 | 500 |

**Field constraints** — β = 1.0:

| # | Name | Alt (ft) | k factor | S_ground_roll (ft) | μ |
|---|------|----------|----------|-------------------|---|
| 7 | Takeoff | 0 | k_TO = 1.2 | 4,000 | 0.03 |
| 8 | Landing | 0 | k_L = 1.3 | 4,000 | 0.50 |

**Note on distances:** Requirements.xlsx quotes a field length of 7,999 ft; Constraints.xlsx uses a ground roll of 4,000 ft. The constraint equations use the ground roll value from Constraints.xlsx. The two values imply different runway models — flagged for professor confirmation.

**CLmax verification targets** (from Constraints.xlsx — computed values to compare against, not inputs):

| Condition | Excel value | Aerodynamics call |
|-----------|------------|-------------------|
| Takeoff (flaps partial, sea level) | 1.276 | `aero.CLmax(AircraftState(0, 0.1))` |
| Landing (flaps full, sea level) | 1.426 | `aero.CLmax(AircraftState(0, 0.1))` |

---

## Equations & References

### ThrustConstraint — Mattingly Master Equation
| Quantity | Equation | Reference |
|----------|----------|-----------|
| T/W | (β/α) × [q × CD0/(β × W/S) + K2 × (n × β/q)^2 × W/S + K1 × n × β/α + PS/V] | Mattingly, Aircraft Engine Design; `temp_AI/docs/disciplines/07_constraints.md` |
| α | `prop.thrust_lapse(state)` — AB or mil depending on AB% flag | PropulsionBase |
| CD0, K1, K2 | `aero.drag_polar(state)` | AerodynamicsBase |
| q | `state.q` | AircraftState |

### LandingConstraint — Landing
This row was originally written as a placeholder before implementation ("confirm exact eq at
implementation") and went stale: it named Raymer and omitted the CD0 term. The equation actually
implemented (and verified, see below) is Brandt's own landing-sizing relation:
| Quantity | Equation | Reference |
|----------|----------|-----------|
| W/S ≤ | ρ × g × S_ground_roll × (μ × CLmax_land + 0.83 × CD0_land) / (k_L² × β) | Roskam, *Airplane Design, Part I*, DARcorporation, ch. 3 — ground-roll-with-braking method; algebraically identical to Brandt's `Wto_S = (Distance×ρ×g×(μ×CLmax+0.83×CD0))/(1.69×β)` with `k_L²=1.69` (k_L=1.3) and `S_ground_roll` in place of `Distance`. **Not Raymer** — see `LandingConstraint.m`'s header for the full derivation and citation correction. Verified to reproduce Brandt's `WS_land=138.742` to <0.1% when fed Brandt's own flapped CLmax/CD0 (`TestLandingConstraint.m`'s `testEquationReproducesBrandtLandingPoint`). |

### TakeoffConstraint — Mattingly Master Equation, ground-roll case
Implemented as its own `PointPerformanceBase` class (`src/constraints/TakeoffConstraint.m`),
not folded into `ThrustConstraint`, since the ground-roll case zeroes the Master
Equation's A/D terms and needs different inputs (CLmax_TO, S_ground_roll, k_TO, μ)
than the continuous-flight conditions.

**2026-07-24 update:** this class previously omitted Brandt's drag/rolling-friction
correction term (`0.7·CD0/(β·CLmax) + μ`), matching only the B*(W/S) part of Brandt's
takeoff row. That correction is now implemented (as the Master Equation's C term) so the
class matches Brandt's own equation exactly — see below and `TakeoffConstraint.m`'s header.

| Quantity | Equation | Reference |
|----------|----------|-----------|
| T/W ≥ | (β² / α) × (k_TO² / (ρ × g × CLmax_TO)) × (W/S) / S_ground_roll + 0.7×CD0_TO/(β×CLmax_TO) + μ | Mattingly, *Aircraft Engine Design*, 2nd ed., AIAA, 2002 — Master Equation specialized via T_SL≫(D+R), dh/dt=0 for the B term (matches `NPTEL_Fighter_Aircraft_Sizing.ipynb`'s `Takeoff` class, cells 32–33), plus Brandt's own F-16A.xls Consts-sheet row 32 drag/rolling-friction correction for the C term (matches temp_Casey's `takeoff_constraint.m` term2). **Not Raymer** — Raymer 6th ed. ch. 5 ("Takeoff Distance," pp. 128–130) gives only the graphical Takeoff Parameter (TOP)/Fig. 5.4 method; a prior version of this doc cited Raymer in error. Verified to reproduce Brandt's `TW_Takeoff=0.40514` at W/S=90 to <0.5% when fed Brandt's own mu/CD0_TO/CLmax_TO/alpha_AB (`TestTakeoffConstraint.m`'s `testEquationReproducesBrandtTakeoffPoint`). |

---

## Plot Deliverables

1. Constraint diagram for F-16 with all 8 Constraints.xlsx constraints plus Stall (9 total),
   design point marked, feasible region shaded.
   `examples/F16A/run_F16_constraint_diagram.m` (single fidelity level, edit `fidelityLevel` to
   choose L1/L2/L3); shading is drawn by `ConstraintAnalysis.plot_diagram()` itself (the area at
   or above the constraint envelope, capped at the wall constraints' W/S limits).
2. Overlay: same diagram computed with F16L1, F16L2, F16L3 disciplines on one figure — shows fidelity sensitivity.
   `examples/F16A/run_F16_constraint_diagram_overlay.m` — plots each fidelity level's envelope
   curve and optimum point on one figure (not all 8 individual constraint curves per level, which
   would be too busy to read; the envelope is exactly what `optimal_point()` reduces to for the
   design-point decision).

Both diagrams EXCLUDE Stall by default (changed 2026-07-27; `F16ConstraintSet.build`'s
`includeStall` argument now defaults to `false`) — Stall was never one of Constraints.xlsx's 8 rows
(see F16ConstraintSet.m's header) and has no Brandt reference row to validate against
(StallConstraint.m's header). It was found to silently BIND the reported design point at L2/L3 via
its geometry-based clean-CLmax wall (~W/S=62-64 psf, tighter than every real condition), pulling the
reported optimum to W/S~=62 vs. Brandt's 104.59 and Casey's legacy-code ~125 (user-reported
2026-07-27) — not the harmless sanity check it was assumed to be. `F16ConstraintSet.build(fidelityLevel, true)`
remains available to add it back as an overlay (exercised by `TestF16ConstraintSet.m`'s
`testBuildWithStallReturnsNineConstraints`), but doing so reintroduces that binding behavior.

---

## Tests

### Generic (`tests/constraints/TestConstraintAnalysis.m` + per-constraint `Test*Constraint.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| ThrustConstraint returns finite T/W over W/S sweep | no NaN, no Inf | exact |
| LandingConstraint returns positive W/S limit | > 0 | exact |
| optimal_point: W/S ≤ landing limit | physical | exact |
| Works with mock aero/prop objects (`FixedAeroStub`) | converges | — |

### F-16 specific (`tests/constraints/TestF16ConstraintSet.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| Optimal W/S (any discipline level) | in range 80–130 psf | physics bounds |
| Optimal T/W (any discipline level) | in range 0.6–1.0 | physics bounds |
| Same optimal_point API with L1, L2, L3 disciplines | all converge | — |
| Landing constraint produces finite upper bound | > 0 | exact |
| `aero.CLmax` at takeoff state | ~1.276 (Excel verification target) | ±20% — textbook accuracy |
| `aero.CLmax` at landing state | ~1.426 (Excel verification target) | ±20% — textbook accuracy |

Note: We do not test against Brandt's exact W/S=104.59 psf or T/W=0.7575. The textbook equations will give their own estimates. CLmax comparison is a diagnostic check, not a pass/fail gate — the discipline computes what it computes.

---

## Verification

```matlab
runtests('tests/constraints/TestConstraintAnalysis.m')
runtests('tests/constraints/TestF16ConstraintSet.m')
```
All tests must pass before Step 7 begins.

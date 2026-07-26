# Aircraft Sizing Framework — Rewrite Plan

> **Living document.** Maintained by Darshan Sarojini and collaborators.
> Subplans live at `air_vehicle_design/sizing/docs/subplans/`.
> Primary architecture reference: `temp_AI/docs/00_framework_overview.md`.

---

## Context

Rewrite the AOE 4065 sizing framework from scratch using correct OOP, referenced equations, and full unit test coverage. Casey's code (`temp_Casey/`) is reference only — equations cross-checked but not modified. F-16A Block 10/15 is the validation baseline throughout.

---

## OOP Architecture

**Hybrid: Abstract interfaces (inheritance) + constructor dependency injection (composition).**

- **Discipline classes** use MATLAB abstract base classes (enforce the contract at instantiation).
  Bases that exist: `AerodynamicsBase`, `PropulsionBase`, `WeightsBase`, `GeometryBase`. Each
  fidelity level follows the three-tier pattern below (`AeroL1` → `AeroModelL1` → `F16AeroL1`, …).

- **System-level orchestrators** receive discipline objects through their constructor (pure
  composition), never subclassed. Built so far: `ConstraintAnalysis` (+ `F16ConstraintSet`). The
  sizing loop and mission analysis (`SizingLoop*`, `MissionAnalysis*`) are not yet built.

Why: MATLAB abstract classes give compile-time contract enforcement. DI into orchestrators makes unit testing easy without deep inheritance chains.

**Confirmed:** R2022b or newer — use `arguments` blocks, `mustBe*` validators, `matlab.unittest` modern patterns.

---

## Three-tier discipline pattern

Each discipline is implemented across three inheritance tiers plus a standalone static toolbox
(authoritative detail in the repo-root `CLAUDE.md`):

```
src/base/<Disc>Base.m                     Tier 1 — abstract; the methods orchestrators call
       ↑                                           + shared concrete utilities
src/disciplines/<disc>/<Disc>ModelLN.m    Tier 2 — abstract enforcer for level N (inherits Base)
       ↑
examples/<AC>/<AC><Disc>LN.m              Tier 3 — concrete per-aircraft class; each method a
                                                   one-line delegation into the toolbox
```

Alongside sits the static toolbox `src/disciplines/<disc>/<Disc>LN.m` (e.g. `AeroL1`) — a
`methods (Static)` classdef holding the cited textbook equations, called as `AeroL1.method(...)`,
never instantiated, not in the inheritance chain. Example chain: `AerodynamicsBase` ← `AeroModelL1`
← `F16AeroL1`, with equations in the `AeroL1` toolbox.

**Layer split (generic vs aircraft-specific).** Tiers 1–2 and the toolbox are generic, parameterized
textbook equations (Layer 1, `src/`). The Tier-3 concrete class (Layer 2, `examples/<aircraft>/`)
supplies the aircraft's genuine spec data (AR, sweep, taper, t/c, engine, airfoil) — it never changes
the equations. Concrete classes split properties into plain mutable **inputs** (set once from JSON)
and `properties (Dependent)` **derived** getters that recompute live; `examples/F16A/F16GeomL2.m` is
the reference. `F16AeroL2/L3` also receive an injected geometry object (dependency injection) — aero
owns no geometry.

**Inputs** come from the unified per-level JSON `examples/F16A/f16a_L{1,2,3}.json` (one file per
level, `.geometry`/`.aerodynamics`/`.propulsion` blocks; `f16a_spec_path(level)`; constructors
require the path — no silent default). Geometry, aerodynamics, and propulsion all read this unified
JSON (the `.propulsion` block lives in `f16a_L{1,2}.json` — propulsion is L1/L2 only); only weights
still uses its own older per-discipline input style.

**Tier count per discipline (as of 2026-07-25):** Geometry, Aerodynamics and Weights are L1/L2/L3.
**Propulsion is L1/L2 only** — there is no `PropL3`/`PropulsionModelL3`/`F16PropL3` and none is
planned; the L3 rung pairs `F16AeroL3` with `F16PropL2`, and L3 propulsion figures in any report must
be labelled "computed by `F16PropL2`".

Geometry's L3 tier was eliminated on 2026-07-22, reinstated on 2026-07-24, and **promoted on
2026-07-25 to the full L3 geometry tier** consumed by L3 geometry, aerodynamics and weights. It is the
physical/T.O. tier: where a physical value differs from Brandt's, `GeomL3` uses the physical one (VT LE
sweep 47.5° vs 40°, `L_fus` 47.5 vs 46.5, HT span 18.5 ft as the PRIMARY span so `AR_ht` = 3.169 is
derived). Those divergences are intentional and are annotated `BY DESIGN` in the comparison reports.
Geometry also now takes an **injected propulsion object** (`F16GeomL{2,3}(json_path, prop)`), since the
nacelle diameter and hence duct wetted area are sized from engine thrust. See
`examples/F16A/F16GeomL3.md`; the code is authoritative over any prose here that still says otherwise.

**What is NOT in the F-16 layer:** Brandt's calibrated intermediate values (e.g., Cfe=0.005908, e_osw=0.9086 back-calculated from his spreadsheet) must NOT be hardcoded into the F-16 subclasses. Those are outputs of Brandt's calibration process, not F-16 specification data. The framework computes e_osw, Cf, CD0, etc. from general textbook equations using F-16 spec inputs.

**What the F-16 subclass wires in:** genuine spec inputs only — e.g. wing AR=3.0, λ=0.2275, Λ_LE=40°,
t/c=0.04, S_ref=300 ft²; airfoil NACA 64A204; engine F100-PW-200 — plus type classifiers (fighter /
jet_fighter) that select the right regression/table rows. All via the `.geometry`/`.aerodynamics`
blocks of `f16a_L{1,2,3}.json`.

**Brandt's output values** (W_TO=31,377 lb, OEW=19,980 lb, W_fuel≈6,000 lb, T_SL=23,770 lb) are the **validation target** — we compare our framework's sizing output against them after running. We do not use Brandt's intermediate values (Cfe, e_osw, etc.) as inputs. Expect ±10–20% agreement at L1, ±5–10% at L2/L3; exact agreement is not the goal.

**Tests:** unit/correctness tests live in `tests/disciplines/` and `tests/constraints/` (generic and
F-16 concrete tests are not split into a separate `tests/examples/F16A/` folder). The Brandt
comparison reports (`examples/F16A/*_brandt_comparison.m`) are informational only, never used to
backfill a unit test's expected value.

---

## Directory Layout (do not touch `temp_Casey/` or `temp_AI/`)

```
air_vehicle_design/sizing/
├── src/
│   ├── core/            AircraftState.m  (value class)
│   ├── base/            AerodynamicsBase.m, PropulsionBase.m, WeightsBase.m, GeometryBase.m
│   ├── disciplines/     (Tier-2 enforcers <Disc>ModelLN.m + static toolboxes <Disc>LN.m)
│   │   ├── aerodynamics/  AeroModelL1/L2/L3.m,  AeroL1/L2/L3.m
│   │   ├── propulsion/    PropulsionModelL1/L2.m,  PropL1/L2.m            (no L3)
│   │   ├── weights/       WeightsModelL1/L2/L3.m,  WeightsL1/L2/L3.m
│   │   └── geometry/      GeometryModelL1/L2/L3.m,  GeomL1/L2/L3.m
│   └── constraints/     ConstraintAnalysis.m, ConstraintSetImporter.m,
│                        PointPerformanceBase.m, Only_TbyW.m, Only_WbyS.m, Both_WbyS_TbyW.m,
│                        ThrustConstraint.m, TakeoffConstraint.m, LandingConstraint.m, StallConstraint.m
│   (src/mission/ and src/sizing/ NOT yet built — steps 7–8)
├── tests/
│   ├── core/            TestAircraftState.m
│   ├── disciplines/     TestAeroL1/L2/L3.m, TestGeomL1/L2/L3.m, TestPropL1/L2.m, TestWeightsL1/L2/L3.m
│   └── constraints/     TestConstraintAnalysis.m, TestF16ConstraintSet.m, TestConstraintSetImporter.m,
│                        Test{Thrust,Takeoff,Landing,Stall}Constraint.m
├── examples/F16A/       (flat — no disciplines/ subfolders)
│   ├── f16a_L1.json, f16a_L2.json, f16a_L3.json     ← unified per-level inputs (.geometry/.aerodynamics/.propulsion; .propulsion in L1/L2 only)
│   ├── f16a_spec_path.m
│   ├── F16GeomL1.m, F16GeomL2.m, F16GeomL3.m
│   ├── F16AeroL1.m, F16AeroL2.m, F16AeroL3.m
│   ├── F16PropL1.m, F16PropL2.m
│   ├── F16WeightsL1.m, F16WeightsL2.m, F16WeightsL3.m
│   ├── F16ConstraintSet.m, Constraints.xlsx, run_F16_constraint_diagram.m
│   ├── {geometry,aerodynamics,propulsion}_brandt_comparison.m (+ .json/.md), fidelity_comparison.m (+ .json/.xlsx)
│   └── per-file companion .md docs
├── VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json  ← consolidated validation ground truth (.geometry/.aerodynamics/.propulsion)
├── baseline/            F16Baseline.m, extract_brandt.m   (deprecated)
└── docs/                PLAN.md, {aerodynamics,geometry,propulsion}_parameter_usage.md,
                         subplans/01_aircraft_state … 08_sizing.md
```

---

## F-16A Validation Targets (Brandt spreadsheet)

These are the **sizing outputs** we compare our framework against after running — not inputs to any discipline equation. They live in `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` (with `.geometry`/`.aerodynamics`/`.propulsion` sections), clearly separated from the toolbox inputs. Brandt's intermediate calibration values (Cfe, e_osw, CD0, lapse rates) must not be stored or used as discipline inputs.

| Quantity | Value | Source |
|---|---|---|
| W_TO | 31,377 lb | Brandt |
| OEW | 19,980 lb | Brandt |
| W_fuel | ~6,000 lb | Brandt (approx) |
| S_ref | 300 ft² | Brandt |
| T_SL (AB) | 23,770 lb | Brandt |
| W/S | 104.59 psf | derived |
| T/W | 0.7575 | derived |
| S_wet | 1,331.09 ft² | Brandt (corrected) |
| CD0 (mission) | 0.0270 | Brandt |
| K2 | 0.1160 | Brandt |
| K1 | -0.00630 | Brandt |
| AR | 3.0 | F-16 spec |

---

## Step Sequence

Each step ends with: **Claude runs MATLAB, all tests pass, then STOP for professor review.**

Status reflects the code tree (this table historically went stale — trust `git log` and `src/`).

| Step | Title | Subplan | Status |
|------|-------|---------|--------|
| 0 | Inputs + Test Infrastructure | *(superseded — see below)* | Superseded |
| 1 | AircraftState | [01_aircraft_state.md](subplans/01_aircraft_state.md) | Done |
| 2 | Geometry (L1/L2) | [02_geometry.md](subplans/02_geometry.md) | Done |
| 3 | Aerodynamics (L1/L2/L3) | [03_aerodynamics.md](subplans/03_aerodynamics.md) | Done |
| 4 | Propulsion (L1/L2) | [04_propulsion.md](subplans/04_propulsion.md) | Done |
| 5 | Weights (L1/L2/L3) | [05_weights.md](subplans/05_weights.md) | Done |
| 6 | Constraint Analysis | [06_constraint_analysis.md](subplans/06_constraint_analysis.md) | Done |
| 7 | Mission Analysis | [07_mission_analysis.md](subplans/07_mission_analysis.md) | Not started |
| 8 | Sizing | [08_sizing.md](subplans/08_sizing.md) | Not started |

---

### Step 0 — Inputs & Test Infrastructure (superseded)

The originally-planned two-file JSON data model (`requirements.json` + `aircraft_spec.json`) was
never built. As implemented:
- **Discipline inputs**: the unified per-level `examples/F16A/f16a_L{1,2,3}.json` (`.geometry`/
  `.aerodynamics` blocks; resolved via `f16a_spec_path`).
- **Constraint conditions**: `examples/F16A/Constraints.xlsx`, read via `ConstraintSetImporter`.
- **Validation ground truth**: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`.
- **Test runner**: `tests/run_all_tests.m`.

Computed quantities (CLmax, CD0, K1/K2, e, fuel fractions) are never stored as inputs — they are
discipline outputs / verification targets only. The Brandt workbook, readmes, `cell-map.md`, and
ground truth all live under `VnV/BrandtF16A/`.

---

### Step 1 — AircraftState

See [subplans/01_aircraft_state.md](subplans/01_aircraft_state.md). **STOP after tests pass.**

---

### Step 2 — Geometry

See [subplans/02_geometry.md](subplans/02_geometry.md). **STOP after tests pass.**

---

### Step 3 — Aerodynamics

See [subplans/03_aerodynamics.md](subplans/03_aerodynamics.md). **STOP after tests pass.**

---

### Step 4 — Propulsion

See [subplans/04_propulsion.md](subplans/04_propulsion.md). **STOP after tests pass.**

---

### Step 5 — Weights

See [subplans/05_weights.md](subplans/05_weights.md). **STOP after tests pass.**

---

### Step 6 — Constraint Analysis

See [subplans/06_constraint_analysis.md](subplans/06_constraint_analysis.md). **STOP after tests pass.**

---

### Step 7 — Mission Analysis

See [subplans/07_mission_analysis.md](subplans/07_mission_analysis.md). **STOP after tests pass.**

---

### Step 8 — Sizing

See [subplans/08_sizing.md](subplans/08_sizing.md). **STOP after tests pass.**

---

## Rules (non-negotiable)

1. Every equation has a citation (Raymer Ch X eq Y, Roskam Part Z eq W, Mattingly Ch N). Zero uncited equations.
2. Claude runs MATLAB (`runtests`) after each step. Step is not done until all tests pass.
3. `temp_Casey/` is read-only reference. Equations cross-checked before use.
4. No feature added beyond what the step requires.
5. Each subplan `.md` is written/expanded at the start of its implementation step.
6. After each step: STOP and wait for professor to review code and run MATLAB independently.
7. Do not search the internet unless explicitly asked to. Use locally available resources: `temp_AI/docs/disciplines/reference_extracts/` (Raymer/Roskam/Mattingly/Nicolai extracts) and `VnV/BrandtF16A/` (Brandt workbook, readmes, cell-map).

---

## Resolved Decisions

**Tail sizing levels:**
- L1: Volume coefficient method only (Raymer eq 6.28–6.29). Called every iteration in SizingLoopL2.
- L2: Left for future work — Raymer Chapter 16 (not in scope for current implementation).

**Control surfaces at L2 sizing:**
In addition to tail sizing, `SizingLoopL2` performs a quick control surface sizing pass each iteration using Raymer Figure 6.3 (typical configurations) and Table 6.5 (historical area fractions). Outputs: aileron area (fraction of S_ref), elevator area (fraction of S_HT), rudder area (fraction of S_VT). Stored on the geometry object; used by `F16WeightsL3` for control system weight.

**Constraint conditions:**
The implementation reads `examples/F16A/Constraints.xlsx` via `ConstraintSetImporter`. See the Step 6 subplan for the condition table. β = 0.8997 for operational constraints, β = 1.0 for takeoff/landing; the ground-roll distance (4,000 ft) is used for the field constraint equation.

**Airfoil:** the aero discipline uses **NACA 64A204** (T.O. 1F-16A-1 Fig. 1-2, root & tip) as authoritative. Brandt's NACA 1404 (alpha_L0 = −1.047°, t/c = 0.04) is used only in the Brandt-alternate comparison path.

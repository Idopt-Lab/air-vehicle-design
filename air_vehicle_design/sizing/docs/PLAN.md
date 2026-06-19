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

- **Discipline classes** use MATLAB abstract base classes (enforces contract at instantiation).
  `AerodynamicsBase`, `PropulsionBase`, `WeightsBase`, `GeometryBase`, `MissionBase`, `TailSizingBase`
  Each concrete level (`AeroLevel1`, `AeroLevel2`, …) inherits from the base.

- **System-level orchestrators** (`SizingLoopL1`, `SizingLoopL2`, `ConstraintAnalysis`, `MissionAnalysisL1`, …) are **not** subclassed. They receive discipline objects through their constructor. Pure composition here.

Why: MATLAB abstract classes give compile-time contract enforcement. DI into orchestrators makes unit testing easy without deep inheritance chains.

**Confirmed:** R2022b or newer — use `arguments` blocks, `mustBe*` validators, `matlab.unittest` modern patterns.

---

## Two-Layer Discipline Pattern

Discipline classes have two layers:

**Layer 1 — Generic (`src/disciplines/`):**
Implements broadly applicable textbook equations (Raymer, Roskam, Mattingly, Nicolai) parameterized for any aircraft. No aircraft-specific numbers are hardcoded. A student can instantiate these directly by supplying the required parameters.

**Layer 2 — Aircraft-specific (`examples/<aircraft>/disciplines/`):**
Subclasses the generic class and provides aircraft-specific **specification inputs** — design parameters taken from the aircraft's public specification (AR, sweep, taper ratio, engine type, airfoil, load factor, etc.). The equations used are still the same general textbook equations from Layer 1. The subclass does not override the equations; it wires in the aircraft's known design parameters so the user doesn't have to supply them manually each time. The sizing loop and constraint analysis receive a Layer 2 object and call it through the abstract base interface — they never know which layer they are talking to.

```
AerodynamicsBase  (abstract — defines the contract)
       ↑
  AeroLevel1      (generic — Raymer Table 12.3 Cf lookup, K_LD lookup,
                   parameterized for any aircraft type)
       ↑
 F16AeroLevel1    (F-16 specific — constructor calls super with
                   aircraft_type='air force fighter', design_type='jet fighter';
                   equations are unchanged)
```

**What is NOT in the F-16 layer:** Brandt's calibrated intermediate values (e.g., Cfe=0.005908, e_osw=0.9086 back-calculated from his spreadsheet) must NOT be hardcoded into the F-16 subclasses. Those are outputs of Brandt's calibration process, not F-16 specification data. The framework computes e_osw, Cf, CD0, etc. from general textbook equations using F-16 spec inputs.

**What the F-16 subclass wires in (specification data only):**

| Generic class | What the F-16 subclass provides |
|---------------|----------------------------------|
| `AeroLevel1` | `aircraft_type = 'air force fighter'` → Raymer Table 12.3 gives Cf; `design_type = 'jet fighter'` → K_LD = 14 from Raymer |
| `AeroLevel2` | AR=3.0, λ=0.2, Λ_LE=40° (F-16 spec) → e_osw computed via Raymer eq 12.48 |
| `AeroLevel3` | Airfoil = NACA 64A-204, tc=0.04, x/c at max thickness; component geometry from F-16 spec |
| `PropulsionLevel1` | `engine_type = 'low_bypass_mixed_turbofan'` → picks TSFC table row |
| `PropulsionLevel2` | BPR and engine class for F100-PW-200 → Mattingly correlations |
| `WeightsLevel1` | `aircraft_type = 'jet fighter'` → Raymer Table 6.1 gives A=2.34, C=−0.13 |
| `WeightsLevel2` | AR=3.0, M_max=2.05, N_z=9.0 from F-16 MIL-SPEC |
| `GeometryLevel1` | `aircraft_type = 'fighter'` → Roskam regression coefficients |
| `GeometryLevel2` | AR=3.0, λ=0.2, Λ_LE=40°, tc=0.04 from F-16 spec |

**Brandt's output values** (W_TO=31,377 lb, OEW=19,980 lb, W_fuel≈6,000 lb, T_SL=23,770 lb) are the **validation target** — we compare our framework's sizing output against them after running. We do not use Brandt's intermediate values (Cfe, e_osw, etc.) as inputs. Expect ±10–20% agreement at L1, ±5–10% at L2/L3; exact agreement is not the goal.

**Tests for generic classes** go in `tests/disciplines/` — use representative parameter values.
**Tests for F-16 classes** go in `tests/examples/F16A/` — compare framework outputs against Brandt's sizing outputs with appropriate tolerances.

---

## Directory Layout (new — do not touch `temp_Casey/` or `temp_AI/`)

```
air_vehicle_design/sizing/
├── src/
│   ├── core/
│   │   └── AircraftState.m
│   ├── base/
│   │   ├── AerodynamicsBase.m
│   │   ├── PropulsionBase.m
│   │   ├── WeightsBase.m
│   │   ├── GeometryBase.m
│   │   ├── MissionBase.m
│   │   └── TailSizingBase.m
│   ├── disciplines/                        ← LAYER 1: generic equations, any aircraft
│   │   ├── aerodynamics/   (AeroLevel1, AeroLevel2, AeroLevel3)
│   │   ├── propulsion/     (PropulsionLevel1, PropulsionLevel2, PropulsionLevel3)
│   │   ├── weights/        (WeightsLevel1, WeightsLevel2, WeightsLevel3)
│   │   ├── geometry/       (GeometryLevel1, GeometryLevel2, GeometryLevel3)
│   │   └── tail_sizing/    (TailSizingLevel1)
│   ├── constraints/
│   │   ├── ConstraintAnalysis.m
│   │   ├── PointPerformanceBase.m
│   │   ├── WingSizingConstraint.m
│   │   └── ThrustConstraint.m
│   ├── mission/
│   │   ├── MissionAnalysisL1.m
│   │   ├── MissionAnalysisL2.m
│   │   ├── MissionAnalysisL3.m
│   │   └── segments/
│   │       ├── MissionSegmentBase.m
│   │       ├── TakeoffSegment.m, ClimbSegment.m, CruiseSegment.m
│   │       ├── DashSegment.m, CombatSegment.m, LoiterSegment.m
│   │       └── DescentSegment.m, LandingSegment.m
│   └── sizing/
│       ├── SizingLoopL1.m
│       └── SizingLoopL2.m
├── tests/
│   ├── core/                    TestAircraftState.m
│   ├── disciplines/             TestAeroLevel1.m, TestPropLevel1.m … (generic classes)
│   ├── constraints/             TestConstraintAnalysis.m
│   ├── mission/                 TestMissionL1.m
│   ├── sizing/                  TestSizingLoops.m
│   └── examples/
│       └── F16A/                TestF16AeroLevel1.m, TestF16PropLevel1.m … (F-16 classes)
├── examples/
│   └── F16A/
│       ├── requirements.json        ← stakeholder inputs (mission + point performance)
│       ├── aircraft_spec.json       ← F-16A design data + validation targets
│       ├── disciplines/                          ← LAYER 2: F-16-specific overrides
│       │   ├── aerodynamics/  (F16AeroLevel1, F16AeroLevel2, F16AeroLevel3)
│       │   ├── propulsion/    (F16PropulsionLevel1, F16PropulsionLevel2, F16PropulsionLevel3)
│       │   ├── weights/       (F16WeightsLevel1, F16WeightsLevel2, F16WeightsLevel3)
│       │   ├── geometry/      (F16GeometryLevel1, F16GeometryLevel2, F16GeometryLevel3)
│       │   └── tail_sizing/   (F16TailSizingLevel1)
│       ├── constraints/       (F16ConstraintSet — defines the 8 F-16 constraint points)
│       ├── design_study_01_L1.m
│       ├── design_study_02_L2.m
│       └── design_study_03_L3.m
└── docs/
    ├── PLAN.md                  (this file)
    └── subplans/
        ├── 01_aircraft_state.md
        ├── 02_geometry.md
        ├── 03_aerodynamics.md
        ├── 04_propulsion.md
        ├── 05_weights.md
        ├── 06_constraint_analysis.md
        ├── 07_mission_analysis.md
        └── 08_sizing.md
```

---

## F-16A Validation Targets (Brandt spreadsheet)

These are the **sizing outputs** we compare our framework against after running — not inputs to any discipline equation. They are stored in `examples/F16A/aaircraft_spec.json` under a `"validation_targets"` key so they live alongside the aircraft data but are clearly labelled. Brandt's intermediate calibration values (Cfe, e_osw, CD0, lapse rates) must not be stored or used as discipline inputs.

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

| Step | Title | Subplan | Status |
|------|-------|---------|--------|
| 0 | Baseline JSON + Test Infrastructure | *(no subplan)* | Not started |
| 1 | AircraftState | [01_aircraft_state.md](subplans/01_aircraft_state.md) | Not started |
| 2 | Geometry | [02_geometry.md](subplans/02_geometry.md) | Not started |
| 3 | Aerodynamics | [03_aerodynamics.md](subplans/03_aerodynamics.md) | Not started |
| 4 | Propulsion | [04_propulsion.md](subplans/04_propulsion.md) | Not started |
| 5 | Weights | [05_weights.md](subplans/05_weights.md) | Not started |
| 6 | Constraint Analysis | [06_constraint_analysis.md](subplans/06_constraint_analysis.md) | Not started |
| 7 | Mission Analysis | [07_mission_analysis.md](subplans/07_mission_analysis.md) | Not started |
| 8 | Sizing | [08_sizing.md](subplans/08_sizing.md) | Not started |

---

### Step 0 — Baseline JSON + Test Infrastructure

**Input files (read-only, do not modify):**
- `temp_Casey/inputs/Requirements.xlsx` — point performance requirements (alt, Mach, n, AB%, PS, field distances)
- `temp_Casey/inputs/Constraints.xlsx` — overlapping data plus β (W/W_TO) and μ per constraint
- `temp_Casey/inputs/Mission_Profile.xlsx` — CAP mission segment sequence
- `temp_Casey/inputs/F-16A Block 50.xlsx` — F-16A aircraft specification (geometry, propulsion, weight data)

Note: `DesignGeometries.xlsx` was deleted. `F-16A Block 50.xlsx` is the sole geometry source.

**Data model — two JSON files:**

`examples/F16A/requirements.json` — **stakeholder inputs only** (what the aircraft must do):
- Point performance requirements: flight conditions (alt, Mach, n, AB%, PS, β, μ, distances)
- Mission profile: CAP segment sequence, payload weights
- Rules: (1) values that disciplines must compute are NOT stored here (e.g., CLmax — computed by aerodynamics); (2) Requirements.xlsx and Constraints.xlsx overlap on flight conditions — write each datum once, from Requirements.xlsx as primary; (3) β and μ from Constraints.xlsx are stakeholder-specified, so they belong here

`examples/F16A/aaircraft_spec.json` — **F-16A design data** (what the specific aircraft is):
- Everything from F-16A Block 50.xlsx: general config, wing/tail/fuselage geometry, propulsion, weight coefficients, tail volume coefficients
- Any F-16-specific data that appeared in other deleted/overlapping Excel files belongs here, not in requirements.json

**Actions:**
1. Read the 4 remaining Excel files. For any discrepancy or duplicate between files, stop and ask the professor before writing to JSON.
2. Construct `examples/F16A/requirements.json` and `examples/F16A/aaircraft_spec.json` using the data model above.
3. Create `tests/RunAllTests.m` — runs full suite with `runtests`.
4. Update `temp_AI/docs/00_framework_overview.md` to reference new `src/` layout and link subplans.

**What must NOT go in either JSON (computed by disciplines):**
- CLmax at any flight condition — computed by `aero.CLmax(state)`. Excel values (CLmax_TO=1.276, CLmax_land=1.426) are verification targets only.
- CD0, K1, K2, e, alpha_dry — discipline outputs. The OldConstraints sheet in Constraints.xlsx has these; they must not be imported.
- Fuel fractions, TSFC per segment — discipline outputs from MissionAnalysisL1.

**Verification:** `runtests('tests/')` — zero tests, zero failures (empty suite passes). **STOP.**

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

---

## Resolved Decisions

**Tail sizing levels:**
- L1: Volume coefficient method only (Raymer eq 6.28–6.29). Called every iteration in SizingLoopL2.
- L2: Left for future work — Raymer Chapter 16 (not in scope for current implementation).

**Control surfaces at L2 sizing:**
In addition to tail sizing, `SizingLoopL2` performs a quick control surface sizing pass each iteration using Raymer Figure 6.3 (typical configurations) and Table 6.5 (historical area fractions). Outputs: aileron area (fraction of S_ref), elevator area (fraction of S_HT), rudder area (fraction of S_VT). Stored on the geometry object; used by WeightsLevel3 for control system weight.

**Constraint conditions:**
Sourced from `temp_Casey/inputs/Constraints.xlsx` and `Requirements.xlsx`. See Step 6 subplan for full table. β = 0.8997 for all operational constraints; β = 1.0 for takeoff and landing. Key note: Requirements.xlsx gives field length = 7,999 ft; Constraints.xlsx uses ground roll = 4,000 ft. Both preserved in `requirements.json / aaircraft_spec.json`; implementation uses ground roll for the constraint equation.

**Airfoil:** F-16A Block 50.xlsx lists NACA 1404 for the main wing (cambered, alpha_L0 = −1.047°, cl_alpha = 0.10/deg, t/c = 0.04). DesignGeometries.xlsx lists NACA 65A — may refer to a different block. Use NACA 1404 data from F-16A Block 50.xlsx as authoritative.

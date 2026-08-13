# Aircraft Sizing Framework — Rewrite Plan

> **Living document.** Maintained by Darshan Sarojini and collaborators.
> Primary architecture reference: the repo's top-level `CLAUDE.md` and this `PLAN.md`.

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
and `properties (Dependent)` **derived** getters that recompute live; `examples/F16A/models/disciplines/geom/F16GeomL2.m` is
the reference. `F16AeroL2/L3` also receive an injected geometry object (dependency injection) — aero
owns no geometry.

**Inputs** come from the unified per-level JSON `examples/F16A/inputs/f16a_L{1,2,3}.json` (one file per
level, `.geometry`/`.aerodynamics`/`.propulsion`/`.weights` blocks; `f16a_spec_path(level)`;
constructors require the path — no silent default). Geometry, aerodynamics, propulsion **and weights**
all read this unified JSON (the `.propulsion` block lives in `f16a_L{1,2}.json` — propulsion is L1/L2
only). The older per-discipline weights input style is gone as of 2026-07-25 (Phase-4 weights
redesign).

**Requirements** are a *second*, fidelity-independent input file: `examples/F16A/inputs/f16a_requirements.json`,
resolved by `examples/F16A/helpers/f16a_requirements_path.m` (no `level` argument — that absence is the
documentation that requirements do not vary with fidelity). It holds what the aircraft must **do**
(`cruise.altitude_ft`, `cruise.mach`, `design_mach`); spec data — what the aircraft **is** — stays in
`f16a_L{1,2,3}.json`. Consumers today: `F16WeightsL2`, `F16WeightsL3`, `F16GeomL1`. It is expected to
grow into the full requirement set with constraint and mission analysis. See "Step 0" below — this is
the partial revival of the Step-0 `requirements.json`.

**Tier count per discipline (as of 2026-07-25):** Geometry, Aerodynamics and Weights are L1/L2/L3.
**Propulsion is L1/L2 only** — there is no `PropL3`/`PropulsionModelL3`/`F16PropL3` and none is
planned; the L3 rung pairs `F16AeroL3` **and `F16WeightsL3`** with `F16PropL2`, and L3 propulsion
figures in any report must be labelled "computed by `F16PropL2`".

**Weights dependency injection (2026-07-25).** `F16WeightsL2(json_path, req_path, geom, prop)` with
`geom` = `F16GeomL2`; `F16WeightsL3(json_path, req_path, geom, prop)` with `geom` = **`F16GeomL3`**.
Both `prop` = `F16PropL2`. All four arguments required at both levels; the `geom` type guard sits at
the L2/L3 **enforcer** (`GeometryModelL2` / `GeometryModelL3`), not at `GeometryBase`, so a wrong tier
fails at construction instead of resolving property names to different physical quantities mid-run.
`F16WeightsL1(json_path)` injects nothing — its two regressions take only `W_TO` and
`aircraft_category`. No `AircraftState` is injected anywhere in weights: `F16WeightsL3` reads the
cruise condition from the requirements file and builds the state itself.

Geometry's L3 tier was eliminated on 2026-07-22, reinstated on 2026-07-24, and **promoted on
2026-07-25 to the full L3 geometry tier** consumed by L3 geometry, aerodynamics and weights. It is the
physical/T.O. tier: where a physical value differs from Brandt's, `GeomL3` uses the physical one (VT LE
sweep 47.5° vs 40°, `L_fus` 47.5 vs 46.5, HT span 18.5 ft as the PRIMARY span so `AR_ht` = 3.169 is
derived). Those divergences are intentional and are annotated `BY DESIGN` in the comparison reports.
Geometry also now takes an **injected propulsion object** (`F16GeomL{2,3}(json_path, prop)`), since the
nacelle diameter and hence duct wetted area are sized from engine thrust. See
`examples/F16A/models/disciplines/geom/F16GeomL3.md`; the code is authoritative over any prose here that still says otherwise.

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

## Directory Layout (do not touch `temp_Casey/`)

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
│   ├── inputs/     f16a_L{1,2,3}.json (unified per-level SPEC inputs: .geometry/.aerodynamics/.propulsion/.weights, .propulsion L1/L2 only), f16a_requirements.json (fidelity-INDEPENDENT: cruise condition, design_mach; read by F16WeightsL2/L3 + F16GeomL1), f16a_requirements.md
│   ├── helpers/    f16a_spec_path.m, f16a_requirements_path.m
│   ├── models/disciplines/{aero,geom,prop,weights,tail,sandc,subsystems,landing_gear}/   ← F16*L* Tier-3 concrete classes + same-basename companion .md
│   ├── models/sizing/     F16ConstraintSet.m, design_study_0{1,2,3}.m
│   ├── studies/    run_sizing_report_L{1,2,3}.m, run_F16_constraint_diagram.m
│   ├── sanity_checks/   {geometry,aerodynamics,propulsion,weights,tail_sizing,sandc,subsystems,constraints}_brandt_comparison.m, mission_brandt_comparison.m
│   └── output/     (gitignored; .gitkeep tracked) generated .json/.md comparison reports
├── VnV/BrandtF16A/
│   ├── GroundTruth/f16a_ground_truth.json  ← consolidated validation ground truth (.geometry/.aerodynamics/.propulsion/.weights)
│   └── todo.md                             ← dated discrepancy / open-decision log (user-review items)
└── docs/                PLAN.md, {aerodynamics,geometry,propulsion,weights}_parameter_usage.md
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

| Step | Title | Status |
|------|-------|--------|
| 0 | Inputs + Test Infrastructure | Superseded (`requirements.json` half PARTLY revived 2026-07-25 — see below) |
| 1 | AircraftState | Done |
| 2 | Geometry (L1/L2) | Done |
| 3 | Aerodynamics (L1/L2/L3) | Done |
| 4 | Propulsion (L1/L2) | Done |
| 5 | Weights (L1/L2/L3) | Done (Phase-4 redesign landed 2026-07-25: unified JSON + requirements file, geometry/propulsion DI, inputs-vs-`Dependent`) |
| 6 | Constraint Analysis | Done (as-is is `src/constraints/` + `examples/F16A/inputs/f16a_requirements.md`) |
| 7 | Mission Analysis | Done (`0b0dfb4`/`40dfdf2`/`9510bc3`) |
| 8 | Sizing | Not started |

---

### Step 0 — Inputs & Test Infrastructure (superseded)

**CORRECTED 2026-07-25 — the two-file model is now PARTLY REAL.** This section previously read "the
originally-planned two-file JSON data model (`requirements.json` + `aircraft_spec.json`) was never
built." The **requirements half now exists**: `examples/F16A/inputs/f16a_requirements.json` +
`examples/F16A/helpers/f16a_requirements_path.m`, introduced by the Phase-4 weights redesign (2026-07-25),
because the design max Mach existed in three places and the cruise condition existed in none that a
weights class could reach. It is **minimal** — `cruise.altitude_ft`, `cruise.mach`, `design_mach`, i.e.
only what weights needed — and it is fidelity-independent by design (no `_L{1,2,3}` suffix, no `level`
argument on the resolver). The `aircraft_spec.json` half was **not** revived: spec data stays in the
unified per-level `f16a_L{1,2,3}.json`.

The boundary the two files enforce: **requirements = what the aircraft must DO; spec = what the
aircraft IS.** Reference areas, AR, taper, sweep, t/c, fuselage envelope, thrust and engine model are
spec and must never migrate into the requirements file — it is fidelity-independent and will become the
most cross-cut input in the repo once constraint and mission analysis extend it.

Known residual duplication: `design_mach` is now the single source for `F16WeightsL2`, `F16WeightsL3`
and `F16GeomL1`, but a full consolidation of every requirement-like value is still pending
(`VnV/BrandtF16A/todo.md` 2026-07-25 Phase 4 §P4-14), and the value 2.0 must be cited to **Brandt**
`Main! aircraft.Mmax`, **not** to the T.O. 1F-16A-1 Mach limit, which is a different number, 2.05
(§P4-13).

As implemented:
- **Discipline spec inputs**: the unified per-level `examples/F16A/inputs/f16a_L{1,2,3}.json` (`.geometry`/
  `.aerodynamics`/`.propulsion`/`.weights` blocks; resolved via `f16a_spec_path(level)`).
- **Requirements**: `examples/F16A/inputs/f16a_requirements.json` (via `f16a_requirements_path()`).
- **Constraint conditions**: `examples/F16A/Constraints.xlsx`, read via `ConstraintSetImporter`.
- **Validation ground truth**: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`.
- **Test runner**: `tests/run_all_tests.m`.

Computed quantities (CLmax, CD0, K1/K2, e, fuel fractions) are never stored as inputs — they are
discipline outputs / verification targets only. The Brandt workbook, readmes, `cell-map.md`, and
ground truth all live under `VnV/BrandtF16A/`.

---

### Step 1 — AircraftState

**STOP after tests pass.**

---

### Step 2 — Geometry

**STOP after tests pass.**

---

### Step 3 — Aerodynamics

**STOP after tests pass.**

---

### Step 4 — Propulsion

**STOP after tests pass.**

---

### Step 5 — Weights

As-built 2026-07-25 (Phase-4 redesign).
**STOP after tests pass.**

As built (Phase-4 redesign, 2026-07-25; edition citations corrected 2026-07-30 against the physical
6th ed. PDF, pp. 572-574 -- Eqs. 15.1-15.24 confirmed verbatim there): L1 = `[Raymer 6th ed. Table 3.1]`
power law + `[Roskam Part I Eq. 2.16]` minimum bound; L2 = `[Raymer 6th ed. Table 15.2]` psf × area +
`[AE481 metabook Sec. 7]` fractions; L3 = `[Raymer 6th ed. §15.3.1, Eqs. 15.1–15.24]` component
build-up on a `[Raymer 7th ed. Eq. 10.10]` dry engine weight (7th ed. confirmed correct for this one
equation only, per Sarojini). `OEW(31377)` = 19110.3126 (L1) /
15664.6483 (L2) / 15705.3313 (L3) lbf against `Brandt Wt!B12` = 19980.700578.
Property split: L1 5 inputs / 0 derived; L2 7 inputs + 2 injected objects / 12 `Dependent`;
L3 43 inputs + 2 injected objects / 31 `Dependent`.
Two standing labelled-red TO-DOs remain by design (Raymer Table 6.1 coefficients absent from the repo;
every §15.3.1 exponent unverified against the printed book), plus open user decisions on the `K_d = 0`
silent zero, the uncited `0.95` landing-weight factor and the uncited 6.7 lb/gal fuel density — all
enumerated in `VnV/BrandtF16A/todo.md`.
Comparison report: `examples/F16A/weights_brandt_comparison.{m,json,md}` — informational, 45 data rows
in 7 sections, **not** in `run_all_tests`.

---

### Step 6 — Constraint Analysis

Done. The step-6 constraint-analysis plan was retired 2026-08-04 (work complete). The as-is implementation is
`src/constraints/`; the F-16 condition data is `examples/F16A/inputs/f16a_requirements.md`.

---

### Step 7 — Mission Analysis

**STOP after tests pass.**

---

### Step 8 — Sizing

**STOP after tests pass.**

---

## Rules (non-negotiable)

1. Every equation has a citation (Raymer Ch X eq Y, Roskam Part Z eq W, Mattingly Ch N). Zero uncited equations.
2. Claude runs MATLAB (`runtests`) after each step. Step is not done until all tests pass.
3. `temp_Casey/` is read-only reference. Equations cross-checked before use.
4. No feature added beyond what the step requires.
5. Each step's design is documented at the start of its implementation step.
6. After each step: STOP and wait for professor to review code and run MATLAB independently.
7. Do not search the internet unless explicitly asked to. Use locally available resources: `docs/reference_extracts/` (Raymer/Roskam/Mattingly/Nicolai extracts) and `VnV/BrandtF16A/` (Brandt workbook, readmes, cell-map).
8. Claude's responses and writing are to adhere to ASD-STE100 Simplified Technical English, located in \sizing\docs\ASD-STE100_ISSUE9.pdf.

---

## Resolved Decisions

**Tail sizing and control-surface sizing (RE-EXTRACTED from Geometry, 2026-08-05 — reverses the
2026-08-03 entry below):** Casey's decision reversed: tail sizing and control-surface sizing are
organizationally their OWN standalone objects again, not part of the Geometry discipline. The
standalone `tail_sizing` discipline (`TailSizingBase`/`TailSizingModelL{1,2,3}`/`TailL{1,2,3}`/
`F16TailL{1,2,3}`) and `src/sizing/ControlSurfaceSizer.m` are **restored** (verbatim from git history
at the pre-2026-08-03 commit — no equation/citation changed across either move), and every
`TAIL SIZING`/`CONTROL SURFACE SIZING` banner-comment block the 2026-08-03 absorption added to
Geometry is removed again:
- `src/disciplines/geometry/GeometryModelL2/L3.m` — the abstract `size_tail(obj)`/
  `size_control_surfaces(obj)` declarations are gone. (`GeometryModelL1` never had a `size_tail`
  contract to begin with as of the separate 2026-08-05 decision that tail sizing starts at L2, not L1
  — see `F16GeomL1.m`'s header.)
- `src/disciplines/geometry/GeomL1/L2/L3.m` — the volume-coefficient/Nicolai/control-surface-area
  toolboxes are gone; those equations live again in `src/disciplines/tail_sizing/TailL1/L2/L3.m` and
  `src/sizing/ControlSurfaceSizer.m`.
- `examples/F16A/models/disciplines/geom/F16GeomL2/L3.m` — the `c_HT`/`c_VT`/Nicolai-coefficient/control-surface-fraction
  properties and the delegating `size_tail()`/`size_control_surfaces()` methods are gone. `S_ht`/
  `S_vt`/`S_ail`/`S_elev`/`S_rud` remain plain properties on the geometry object, now written by an
  external tail/control-surface object instead of computed in place.
- `SizingLoopL2.m`'s constructor takes `tail (1,1) TailSizingBase` and
  `ctrl (1,1) ControlSurfaceSizer` as dependency-injected arguments again; `run()` calls
  `obj.tail.size(...)`/`obj.ctrl.size(obj.geom)` and writes the results into `obj.geom.S_ht`/`S_vt`/
  `S_ail`/`S_elev`/`S_rud`, instead of calling `obj.geom.size_tail()`/`size_control_surfaces()`
  directly. Call sites updated: `FixedGeomStub.m`, `TestSizingLoopL2.m`, `design_study_02_L2.m`,
  `design_study_03_L3.m`.

Full rationale, citations, and discrepancy record: `src/disciplines/tail_sizing/TailSizing_scribe_plan.md`
(the historical record kept through both the 2026-08-03 absorption and this reversal), `VnV/BrandtF16A/todo.md`
(2026-07-28 entries).

<details><summary>Historical entry, absorbed into Geometry 2026-08-03, reversed 2026-08-05 (kept for context)</summary>

**Tail sizing and control-surface sizing (absorbed into Geometry, 2026-08-03):** Casey's decision:
tail sizing and control-surface sizing are organizationally part of the Geometry discipline, not
separate disciplines/objects. The standalone `tail_sizing` discipline and
`src/sizing/ControlSurfaceSizer.m` were deleted; every equation/citation/coefficient was carried over
unchanged, just relocated, under `TAIL SIZING`/`CONTROL SURFACE SIZING` banner comments in
`GeometryModelL1/L2/L3.m`, `GeomL1/L2/L3.m`, and `examples/F16A/models/disciplines/geom/F16GeomL1/L2/L3.m`, with
`SizingLoopL2.m`'s constructor no longer taking `tail`/`ctrl` arguments and `run()` calling
`obj.geom.size_tail()`/`obj.geom.size_control_surfaces()` directly.

</details>

<details><summary>Historical entry, superseded 2026-08-03 (kept for context)</summary>

**Tail sizing (superseded 2026-07-28 — was a standalone helper, now a full three-tier discipline):**
Tail sizing produces only `S_ht`/`S_vt` (horizontal/vertical tail reference areas); control-surface
sizing stays a separate discipline (`src/sizing/ControlSurfaceSizer.m`). Files:
`src/base/TailSizingBase.m` ← `src/disciplines/tail_sizing/TailSizingModelL{1,2,3}.m` ←
`examples/F16A/models/disciplines/tail/F16TailL{1,2,3}.m`, with static toolboxes `TailL1/L2/L3.m` — same pattern as
Aero/Geometry/Propulsion/Weights.

**Control surfaces at L2 sizing:**
In addition to tail sizing, `SizingLoopL2` performs a quick control surface sizing pass each iteration using Raymer Figure 6.3 (typical configurations) and Table 6.5 (historical area fractions). Outputs: aileron area (fraction of S_ref), elevator area (fraction of S_HT), rudder area (fraction of S_VT). Stored on the geometry object; used by `F16WeightsL3` for control system weight.

</details>

**Constraint conditions:**
The implementation reads `examples/F16A/Constraints.xlsx` via `ConstraintSetImporter`. β = 0.8997 for operational constraints, β = 1.0 for takeoff/landing; the ground-roll distance (4,000 ft) is used for the field constraint equation.

**Airfoil:** the aero discipline uses **NACA 64A204** (T.O. 1F-16A-1 Fig. 1-2, root & tip) as authoritative. Brandt's NACA 1404 (alpha_L0 = −1.047°, t/c = 0.04) is used only in the Brandt-alternate comparison path.

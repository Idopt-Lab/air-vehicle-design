# Plan: Refactor Casey's Code to a Proper Fidelity-Swappable Framework

## Context

Casey has solid physics (checked against F-16) but the architecture does not enforce the interfaces in `discipline-interfaces.md`. You cannot swap fidelity levels without changing sizing/mission/constraint code. This refactor builds the framework Casey will then use.

**Core rules:**
- `src/` is aircraft-agnostic — no hardcoded aircraft dimensions or type-specific geometry
- `examples/` holds aircraft-specific subclasses, inputs, and design study scripts
- `src/level_brandt/` untouched — it is ground truth
- L4 discipline classes refactored on the same pass as L1–L3

---

## Changes to Interface Documents

### `ai-workflows/discipline-interfaces.md` — proposed additions

1. **Add `TailSizingBase` section.** Tail sizing is a separate discipline — called from the sizing loop (L2+) and produces geometric outputs. Abstract method:
   ```
   size(obj, S_ref, b, cbar, L_fus) → struct(S_HT, S_VT)
   ```
   Note: only called from `SizingLoopL2` onward.

2. **Add `MissionBase` section.** Currently missing from the document. Abstract method:
   ```
   compute_fuel(obj, aero, prop, W_TO, req) → scalar (lbf)
   ```

3. **Clarify sizing loop fidelity.** The sizing loop itself has two fidelity levels (L1 and L2) with different state variables and different calls. Add a "Sizing Loop" section describing L1 (1 state variable) vs L2 (2 state variables + tail sizing).

### `ai-workflows/Fidelity-Levels.md` — proposed additions

1. **Add Level IV row** — higher-fidelity component drag and weight equations (Raymer Ch 15).
2. **Add "Tail Sizing" column** — L1: not called; L2+: tail volume coefficient (Raymer Eq 6.28–6.29); L3/L4: same method but geometry inputs from detailed geometry object.
3. **Add "Sizing" column** — L1: 1 state variable (W_TO), outputs W_TO + S_ref + T_SL; L2+: 2 state variables (W_TO + T_SL), S_ref is input, includes tail sizing.

---

## Casey's Code: Assessment

### What he did well
- Physics equations correct and F-16 checked
- `BrandtLevel` follows clean constructor / `analyze()` / `run()` pattern — emulate this
- Discipline functions well-sourced (Raymer, Roskam)
- `AeroLevel1` CLmax/DeltaCD0 tables are thorough
- F-16 specific subclasses already exist in `examples/` (good instinct, wrong structure)
- Tests exist for Brandt and Weight disciplines

### Where improvement is needed

| Problem | Detail |
|---|---|
| Wrong abstraction granularity | One abstract class per fidelity level (e.g. `AerodynamicsModelLevel1/2/3`) instead of one per discipline. No common contract. |
| L1–L3 don't inherit from anything | Pure static-method classes. Can't be swapped polymorphically. Only L4 inherits — and from the wrong (per-fidelity) base. |
| Method names differ by level | None expose `drag_polar`, `CLmax`, `thrust_lapse`, `TSFC`, `OEW` — the five names the system code must call. |
| Sizing only at L3, hardwired | `SizingClassLevel3` hardwires L3 method calls. L1/L2 sizing scripts are one-liners. |
| No `AircraftState` class | Disciplines take raw scalars. Specified in interfaces doc, does not exist. |
| No `MissionBase` | `MissionAnalysisLevel1/2/3/4` have no common interface. |
| `GeometryLevel3.get_design_S_wet` hardcodes fighter | `c=-0.1289, d=0.7506` baked in without `aircraft_type` arg. |
| F-16 discipline files in wrong locations | Flat folders (`Aerodynamics/`, `Geometry/`, etc.) at top of `examples/` — should be under `disciplines/`. |
| L4 classes incomplete | `AeroLevel4` has placeholder values (CD=1233, K=234). `MissionAnalysisLevel4` calls undefined `compute_revised_LD_ratio`. Both need fixes. |
| `ComputationModels/` dead code | All L1–L3 concretes ignore their abstract superclasses. Delete. |

---

## Directory Structure After Refactor

```
src/                                         ← aircraft-agnostic only
├── AircraftState.m                          [new]
├── base/
│   ├── AerodynamicsBase.m                   [new — 1 per discipline, replaces 3 per-fidelity]
│   ├── PropulsionBase.m                     [new]
│   ├── WeightsBase.m                        [new]
│   ├── GeometryBase.m                       [new]
│   ├── MissionBase.m                        [new]
│   ├── TailSizingBase.m                     [new]
│   └── ConstraintBase.m                     [refactored from ConstraintModel]
├── Disciplines/
│   ├── Aerodynamics/
│   │   ├── AeroLevel1.m                     [refactor: handle class, inherits AerodynamicsBase]
│   │   ├── AeroLevel2.m                     [refactor]
│   │   ├── AeroLevel3.m                     [refactor]
│   │   └── AeroLevel4.m                     [refactor: fix placeholders, new parent]
│   ├── Propulsion/
│   │   ├── PropulsionLevel1.m               [refactor]
│   │   ├── PropulsionLevel2.m               [refactor]
│   │   ├── PropulsionLevel3.m               [refactor]
│   │   └── PropulsionLevel4.m               [refactor: new parent]
│   ├── Weight/
│   │   ├── WeightLevel1.m                   [refactor]
│   │   ├── WeightLevel2.m                   [refactor]
│   │   ├── WeightLevel3.m                   [refactor]
│   │   └── WeightLevel4.m                   [refactor: new parent]
│   ├── Geometry/
│   │   ├── GeometryLevel1.m                 [refactor]
│   │   ├── GeometryLevel2.m                 [refactor]
│   │   └── GeometryLevel3.m                 [refactor: parameterize aircraft_type in S_wet]
│   ├── Mission/
│   │   ├── MissionLevel1.m                  [refactor: inherits MissionBase]
│   │   ├── MissionLevel2.m                  [refactor]
│   │   ├── MissionLevel3.m                  [refactor]
│   │   └── MissionLevel4.m                  [refactor: new parent, fix undefined method bug]
│   └── TailSizing/
│       └── TailSizingLevel1.m               [new: volume coefficient, Raymer Eq 6.28-6.29]
├── Sizing/
│   ├── SizingLoopL1.m                       [new]
│   └── SizingLoopL2.m                       [new]
├── Utilities/                               [existing, no change]
└── run_sizing_template.m                    [new]

examples/
└── F-16A B Block 10 and 15/
    ├── Ground-Truth/                        [untouched]
    ├── disciplines/                         [reorganized from flat folders]
    │   ├── Aerodynamics/
    │   │   ├── F16AeroLevel1.m              [refactor: inherit AeroLevel1]
    │   │   ├── F16AeroLevel2.m              [refactor: inherit AeroLevel2]
    │   │   ├── F16AeroLevel3.m              [refactor: inherit AeroLevel3]
    │   │   └── F16AeroLevel4.m              [new: inherit AeroLevel4]
    │   ├── Propulsion/
    │   │   ├── F16PropulsionLevel1.m        [refactor]
    │   │   ├── F16PropulsionLevel2.m        [refactor]
    │   │   ├── F16PropulsionLevel3.m        [refactor]
    │   │   └── F16PropulsionLevel4.m        [exists, refactor]
    │   ├── Weight/
    │   │   ├── F16WeightLevel1.m            [refactor]
    │   │   ├── F16WeightLevel2.m            [refactor]
    │   │   └── F16WeightLevel3.m            [refactor]
    │   ├── Geometry/
    │   │   ├── F16GeometryLevel1.m          [refactor]
    │   │   ├── F16GeometryLevel2.m          [refactor]
    │   │   └── F16GeometryLevel3.m          [refactor]
    │   ├── Mission/
    │   │   ├── F16MissionLevel1.m           [refactor]
    │   │   ├── F16MissionLevel2.m           [refactor]
    │   │   └── F16MissionLevel3.m           [refactor]
    │   ├── TailSizing/
    │   │   └── F16TailSizingLevel1.m        [new: inherit TailSizingLevel1, set F-16 c_VT/c_HT]
    │   └── Constraints/
    │       └── F16ConstraintAnalysis.m      [refactor: inherit ConstraintBase]
    ├── Operator/                            [existing xlsx files, no change]
    ├── design_study_01.m                    [L1 aero + L1 mission + L1 sizing]
    ├── design_study_02.m                    [L2 aero + L2 mission + L2 sizing]
    └── design_study_03.m                    [L3 aero + L3 mission + L2 sizing]
```

**Delete/deprecate:** `src/ComputationModels/`, `src/Level_{I,II,III,IV}_Fidelity/Sizing_script.m`, `src/Disciplines/Sizing/SizingClassLevel{1,2,3}.m`, `examples/F-16A.../F16A_Level{1,2,3}_Sizing_ClassBased_Example.*`, and flat discipline folders `examples/F-16A.../Aerodynamics/`, `Geometry/`, etc. (replaced by `disciplines/`).

---

## Implementation Steps

### 1. `AircraftState` — `src/AircraftState.m`
Handle class. Constructor `AircraftState(altitude_ft, mach)`. Calls `atmosisa`, stores `T_atm, P_atm, rho, a, V, q`. Default `u=V, v=0, w=0`; `alpha = atan2(w,u)`. Pure data object.

### 2. Per-discipline base classes — `src/base/`
Replace all `ComputationModels/` per-fidelity abstract classes with one base class per discipline:

| Class | Abstract methods | Abstract props |
|---|---|---|
| `AerodynamicsBase < handle` | `drag_polar(obj,state)→struct(CD0,K1,K2)`, `CLmax(obj,state)→scalar` | — |
| `PropulsionBase < handle` | `thrust_lapse(obj,state)→scalar`, `TSFC(obj,state)→scalar` | `T0` settable |
| `WeightsBase < handle` | `OEW(obj,W_TO)→scalar` | — |
| `GeometryBase < handle` | — | `S_ref`, `S_wet` (concrete) |
| `MissionBase < handle` | `compute_fuel(obj,aero,prop,W_TO,req)→scalar` | — |
| `TailSizingBase < handle` | `size(obj,S_ref,b,cbar,L_fus)→struct(S_HT,S_VT)` | — |
| `ConstraintBase < handle` | `optimal_point(obj,aero,prop)→struct(W_S,T_W)` | — |

### 3. Refactor generic discipline classes — `src/Disciplines/`

**Pattern for all levels:** Convert static-only → handle class inheriting from base. Constructor stores config. All existing static computation methods remain — the abstract interface method calls through to them.

*Aerodynamics*
- `AeroLevel1 < AerodynamicsBase`: ctor takes `aircraft_type`. `drag_polar` → calls `tab_K_LD`, `compute_LDmax`, returns `struct(CD0, K1=0, K2=K)`. `CLmax` → calls `tab_CLmax_values`.
- `AeroLevel2 < AerodynamicsBase`: ctor takes `AR, S_wet, S_ref, aircraft_type`. `drag_polar` → `compute_CD0`, `compute_K`.
- `AeroLevel3 < AerodynamicsBase`: ctor takes geometry object. `drag_polar` → component drag buildup. `CLmax` → lift-curve slope method.
- `AeroLevel4 < AerodynamicsBase`: ctor takes geometry object. `drag_polar` → full `compute_drag` buildup (fix placeholder CD/K values). `CLmax` → `AeroLevel3` method.

*Propulsion*
- `PropulsionLevel1 < PropulsionBase`: ctor takes `engine_type`. `thrust_lapse` → type constant. `TSFC` → `get_TSFC`. `T0` settable.
- `PropulsionLevel2/3 < PropulsionBase`: same interface, Mattingly lapse rate.
- `PropulsionLevel4 < PropulsionBase`: same interface, uses `propulsion_est_level_IV` internally.

*Weights*
- `WeightLevel1 < WeightsBase`: `OEW` → historical A·W_TO^B.
- `WeightLevel2 < WeightsBase`: `OEW` → Raymer Eq 6.1 gross fraction.
- `WeightLevel3 < WeightsBase`: `OEW` → component buildup.
- `WeightLevel4 < WeightsBase`: `OEW` → full Raymer Ch 15 component method (`compute_OEW_IV`).

*Geometry*
- `GeometryLevel1/2/3 < GeometryBase`: concrete properties `S_ref`, `S_wet`. Fix `GeometryLevel3.get_design_S_wet` to take `aircraft_type` arg (remove hardcoded fighter c/d coefficients; add lookup table like `GeometryLevel2` does with `GeometryLevel1.get_fus_len`).

*Mission*
- `MissionLevel1 < MissionBase`: `compute_fuel` → Roskam fuel fraction table. Generic aircraft_type lookup.
- `MissionLevel2 < MissionBase`: `compute_fuel` → segment loop calling `aero.drag_polar`, `prop.TSFC`.
- `MissionLevel3 < MissionBase`: same interface, subsegment numerical integration internally.
- `MissionLevel4 < MissionBase`: same interface. Fix undefined `compute_revised_LD_ratio` bug.

*Tail Sizing*
- `TailSizingLevel1 < TailSizingBase`: `size(obj, S_ref, b, cbar, L_fus)` using Raymer Eq 6.28–6.29 (volume coefficient). Ctor takes `c_VT, c_HT`. This is Casey's existing `Tail_Sizing` function promoted to a class.

### 4. Sizing loops — `src/Sizing/`

**`SizingLoopL1`** — 1 state variable
```
Loop:
  1. con.optimal_point(aero, prop) → W_S_opt, T_W_opt
  2. fuel = miss.compute_fuel(aero, prop, W_TO, req)
  3. oew  = wts.OEW(W_TO)
  4. W_TO_new = oew + W_payload + fuel
  until |W_TO_new - W_TO| < tol
Outputs: W_TO, S_ref = W_TO/W_S_opt, T_SL = T_W_opt × W_TO
```

**`SizingLoopL2`** — 2 state variables, `S_ref` is input
```
Loop:
  1. con.optimal_point(aero, prop) → T_W_opt  (S_ref fixed)
  2. T_SL = T_W_opt × W_TO; prop.T0 = T_SL
  3. [S_HT, S_VT] = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)
     → store in geometry object
  4. fuel = miss.compute_fuel(aero, prop, W_TO, req)
  5. oew  = wts.OEW(W_TO)
  6. W_TO_new = oew + W_payload + fuel
  until |W_TO_new - W_TO| < tol and |T_SL_new - T_SL| < tol
Outputs: W_TO, T_SL
```

Both loops call only the 7 abstract interface methods — any fidelity combination works.

### 5. F-16 specific discipline subclasses — `examples/.../disciplines/`

**Pattern for all F-16 classes:**
```matlab
classdef F16AeroLevel2 < AeroLevel2
    methods
        function obj = F16AeroLevel2(geom_json)
            % Read F-16 parameters from JSON, call parent constructor
            obj@AeroLevel2(geom_json.wing.AR, geom_json.S_wet_total, ...
                           geom_json.wing.S_ref, 'fighter');
        end
    end
end
```
The F-16 class has only a constructor that loads F-16-specific values and passes them up. All physics remain in the generic `src/` parent. This applies to Aero L1–L4, Propulsion L1–L4, Weight L1–L3, Geometry L1–L3, Mission L1–L3.

`F16TailSizingLevel1 < TailSizingLevel1`: ctor sets `c_VT=0.07, c_HT=0.40` (Raymer Table 6.4 fighter values).

### 6. Design study scripts — `examples/.../design_study_0N.m`

Three scripts showing different fidelity combinations. Changing study = changing the F16 class instantiation lines only.

```matlab
% design_study_01.m — L1 disciplines + L1 mission + L1 sizing
geom  = F16GeometryLevel1(json);
aero  = F16AeroLevel1(json);
prop  = F16PropulsionLevel1(json);
wts   = F16WeightLevel1(json);
miss  = F16MissionLevel1(json);
con   = F16ConstraintAnalysis(aero, prop, req);

sizer = SizingLoopL1();
[W_TO, S_ref, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);
```

```matlab
% design_study_02.m — L2 disciplines + L2 mission + L2 sizing
tail  = F16TailSizingLevel1();
...
sizer = SizingLoopL2();
[W_TO, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
```

```matlab
% design_study_03.m — L3 disciplines + L3 mission + L2 sizing
% Only F16*Level3 lines change vs design_study_02; sizing loop unchanged
tail  = F16TailSizingLevel1();   % tail sizing method stays at L1 for all design studies
...
sizer = SizingLoopL2();
[W_TO, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
```

### 7. Main generic template — `src/run_sizing_template.m`
Shows the pattern with generic classes. Comment block explains how to swap fidelities.

### 8. Housekeeping
- Delete `src/ComputationModels/`
- Delete `src/Level_{I,II,III,IV}_Fidelity/Sizing_script.m`
- Delete `src/Disciplines/Sizing/SizingClassLevel{1,2,3}.m`
- Delete flat discipline folders in examples (`Aerodynamics/`, `Geometry/`, etc.) — replaced by `disciplines/`
- Delete `F16A_Level{1,2,3}_Sizing_ClassBased_Example.*` — replaced by design studies
- Add to `to-do-darshan.md`: "Migrate requirements format from xlsx to JSON (match BrandtLevel)"

---

## F-16 Validation: Parameters and Brandt Targets

Run each design study against F-16 inputs; report % error vs Brandt ground truth.

### Top-level sizing outputs (primary check)

These are the numbers the sizing loop is ultimately predicting. Check these first.

| Parameter | Brandt | Excel tab | L1 sizing | L2 sizing |
|---|---|---|---|---|
| W_TO (TOGW) | 31,377 lb | Wt!B3 | Iterated | Iterated |
| OEW | 19,980 lb | Wt!B12 | Regression | Raymer / component |
| Fuel burn (total mission) | 6,000 lb | Miss!O9 | Fuel fractions | Segment equations |
| Wing loading W/S | 104.59 psf | Consts | W_TO / S_ref | W_TO / S_ref |
| Thrust loading T/W | 0.7575 | Consts | From constraint diagram | From constraint diagram |
| T_SL (afterburner) | 23,770 lb | JSON | T_W × W_TO | Iterated |
| S_ref (wing area) | 300 ft² | JSON (input) | W_TO / W_S_opt | Fixed input |

### Geometry (`Geom` tab)

| Parameter | Brandt | Excel cell | L1 method | L2 method | L3 method |
|---|---|---|---|---|---|
| S_wet whole aircraft | 1,331.09 ft² | Geom!B19 | Roskam type regression | Roskam regression | Component buildup |
| S_wet (corrected, no bug) | 1,332.7 ft² | — | — | — | Should approach |
| S_wet fuselage | 730.4 ft² | Geom!B3 | Not resolved | Not resolved | Trapezoidal integration |
| S_wet wing | 392.0 ft² | — | Not resolved | Raymer formula | Raymer formula |
| Fuselage length | 48.3 ft | — | Roskam regression | Roskam regression | From geometry object |
| Amax | 25.1 ft² | — | Not computed | Not computed | Cross-section integration |

Note: Geom!B19 double-counts strake S_wet (known Excel bug). L1/L2 compare to 1,331.09 (what Excel shows). L3 should match corrected 1,332.7 ft².

### Aerodynamics (`Aero` tab)

| Parameter | Brandt | Excel cell | L1 method | L2 method | L3 method |
|---|---|---|---|---|---|
| CD0 (mission drag polar) | 0.0270 | Miss tab | Cf(type)×S_wet/S_ref | Cf(Raymer)×S_wet/S_ref | Component buildup |
| CD0 (Aero tab, subsonic) | 0.0170 | Aero!CDmin | Not captured | Not captured | Should approach |
| K ≈ K2 | 0.1160 | Aero props | 1/(4·LDmax²·CD0) | 1/(π·e·AR), Oswald | 1/(π·e·AR), full geom |
| K1 (linear CL term) | −0.00630 | Aero props | Not captured (K1=0) | Not captured (K1=0) | From CL_minD shift |
| CLmax clean | 0.984 | Aero props | Roskam table [1.2,1.8] | Refined AR/flap | Lift-curve slope |
| CLmax takeoff | 1.276 | Aero props | Roskam table | +ΔCL flap | Full flap model |
| CLmax landing | 1.426 | Aero props | Roskam table | +ΔCL flap | Full flap model |
| LD_max | ~8.9 | — | K_LD · √AR_wet | 1/(2√(CD0·K)) | 1/(2√(CD0·K)) |

### Weights (`Wt` tab, at W_TO = 31,377 lb)

| Parameter | Brandt | Excel cell | L1 method | L2 method | L3 method |
|---|---|---|---|---|---|
| OEW | 19,980 lb | Wt!B12 | Historical A·W_TO^B | Raymer Eq 6.1 | Component buildup |
| OEW/W_TO | 0.637 | — | From regression | From Raymer ratio | Computed |
| W_structure | 6,723 lb | Wt!B9 | Not resolved | Not resolved | Sum of components |
| W_wing | 1,786 lb | Wt!C9 | — | — | Brandt plate-area or Raymer |
| W_fuselage | 3,652 lb | Wt!D9 | — | — | Raymer fuselage eq |
| W_engine installed | 4,730 lb | Wt!B22 | Fraction of W_TO | Raymer engine eq | Raymer engine eq |
| W_landing_gear | 1,067 lb | Wt!B23 | Not resolved | 0.034×W_TO | 0.034×W_TO |
| W_fuel | 6,000 lb | Wt!B6 | Fuel fractions×W_TO | Segment equations | Subsegment integration |

### Constraints (`Consts` tab)

| Parameter | Brandt | Notes |
|---|---|---|
| W/S design point | 104.59 psf | Drives S_ref in L1 sizing |
| T/W design point | 0.7575 | Active constraint at design point |
| T_SL (AB) | 23,770 lb | = T/W × W_TO |
| Landing W/S max | 138.48 psf | CLmax landing constraint |
| Takeoff T/W min | 0.136 | Ground-roll constraint |

All fidelity levels produce the same constraint diagram structure; accuracy depends on CD0/K/CLmax/thrust_lapse inputs to each level.

### Sizing + tail sizing

| Parameter | Brandt | L1 sizing (study 1) | L2 sizing (study 2/3) |
|---|---|---|---|
| W_TO converged | 31,377 lb | Iterated | Iterated |
| S_ref | 300 ft² | W_TO / W_S_opt (output) | Fixed input |
| T_SL (AB) | 23,770 lb | T_W_opt × W_TO | Iterated with W_TO |
| Fuel burn | 6,000 lb | Fuel fractions | Segment eqs (s2) / integration (s3) |
| S_HT (stabilator) | 108 ft² | Not computed | From F16TailSizingLevel1 |
| S_VT (vertical tail) | 60 ft² | Not computed | From F16TailSizingLevel1 |

---

## Critical Files

| Action | Files |
|---|---|
| New | `src/AircraftState.m`; `src/base/{Aerodynamics,Propulsion,Weights,Geometry,Mission,TailSizing,Constraint}Base.m`; `src/Disciplines/TailSizing/TailSizingLevel1.m`; `src/Sizing/SizingLoopL1.m`, `SizingLoopL2.m`; `src/run_sizing_template.m`; `examples/.../disciplines/TailSizing/F16TailSizingLevel1.m`; `examples/.../design_study_0{1,2,3}.m` |
| Refactor — generic | `src/Disciplines/Aerodynamics/AeroLevel{1,2,3,4}.m`; `PropulsionLevel{1,2,3,4}.m`; `WeightLevel{1,2,3,4}.m`; `GeometryLevel{1,2,3}.m`; `Mission/MissionLevel{1,2,3,4}.m` |
| Refactor — F16 | Reorganize `examples/.../Aerodynamics/F16AeroLevel{1,2,3}.m` → `disciplines/`; same for Propulsion, Weight, Geometry, Mission; update all to inherit from new base classes |
| Update docs | `ai-workflows/discipline-interfaces.md`; `ai-workflows/Fidelity-Levels.md` |
| Delete | `src/ComputationModels/`; `src/Level_{I,II,III,IV}_Fidelity/Sizing_script.m`; `src/Disciplines/Sizing/SizingClassLevel{1,2,3}.m`; flat `examples/.../Aerodynamics/` etc. folders; `F16A_Level{1,2,3}_Sizing_ClassBased_Example.*` |
| Do not touch | `src/level_brandt/` |
| TODO | `to-do-darshan.md`: migrate requirements from xlsx to JSON |

---

## Verification

1. `F16AeroLevel1(json).drag_polar(AircraftState(0, 0.3))` → struct(CD0, K1, K2)
2. Swap to `F16AeroLevel2(json)`, same one-line call → same struct shape, different numbers
3. `design_study_01.m` converges W_TO → compare to Brandt table above
4. `design_study_02.m` converges W_TO and T_SL; tail sized; compare
5. `design_study_03.m` same sizing loop, better discipline inputs; compare again
6. All six Brandt test suites still pass
7. Confirm: swapping `F16AeroLevel1` → `F16AeroLevel2` in `design_study_01.m` requires no change to `SizingLoopL1` code

---

## Unresolved questions

None.

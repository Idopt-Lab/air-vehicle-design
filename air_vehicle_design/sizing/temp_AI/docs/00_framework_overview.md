# Framework Overview

## 1. Why This Architecture Exists

Brandt's original sizing code is a single Excel workbook. Every discipline is hard-coded into a fixed set of cells; changing fidelity means rewriting formulas in place. Students cannot swap in a better aerodynamics model without touching the constraint analysis, the mission analysis, and the sizing loop simultaneously. When two students want to use different propulsion fidelity levels for a trade study, they have to maintain separate copies of the entire workbook.

The MATLAB framework solves this by enforcing a clean separation between the *discipline interface* (what a module promises to compute) and the *discipline implementation* (how it computes it). The interface is defined once as an abstract base class. Every concrete implementation, regardless of fidelity, must honour that interface. The sizing loop, mission analysis, and constraint analysis are written against the interface only; they never know which fidelity level they are talking to.

---

## 2. The Abstract Base Class Pattern

MATLAB classdef allows abstract methods: methods declared with a signature but no body. Any class that inherits from an abstract base but does not implement all abstract methods cannot be instantiated. This enforces the contract.

```
                  AerodynamicsBase (abstract)
                  + drag_polar(state) -> polar  [abstract]
                  + CLmax(state) -> CL          [abstract]
                       ^
                       |
          +------------+------------+
          |            |            |
     AeroLevel1   AeroLevel2   AeroLevel3 ...
```

Every discipline follows this pattern:

| Abstract Base Class | Abstract Methods | Concrete Properties |
|---------------------|-----------------|---------------------|
| `AerodynamicsBase`  | `drag_polar(state)`, `CLmax(state)` | none |
| `PropulsionBase`    | `thrust_lapse(state)`, `TSFC(state)` | `T0` (set by sizing loop) |
| `WeightsBase`       | `OEW(W_TO)` | none |
| `GeometryBase`      | none | `S_ref`, `S_wet` |
| `MissionBase`       | `compute_fuel(aero,prop,W_TO,req)` | none |
| `TailSizingBase`    | `size(S_ref,b,cbar,L_fus)` | none |
| `ConstraintBase`    | `optimal_point(aero,prop)` | none |

`GeometryBase` is the only base class with no abstract methods. It defines the minimum shared properties (`S_ref`, `S_wet`) that every higher-level class must populate; additional properties are added by the concrete subclasses.

---

## 3. The Plug-In Discipline Pattern

The sizing loop and mission analysis receive discipline objects through their `run` / `compute_fuel` argument lists. No discipline name appears inside those loops. Changing fidelity is one line at the call site.

```
+------------------+     +------------------+
|  AeroLevel1      |     |  AeroLevel2      |
|  (Cf * Swet/Sref)|     |  (Cf * Swet/Sref)|
|  K1 from K_LD    |     |  K1 = 1/(pi*e*AR)|
+--------+---------+     +--------+---------+
         |                        |
         +----------+-------------+
                    |
           drag_polar(state) -> polar
           CLmax(state)       -> CL
                    |
         +----------+----------+
         |                     |
  +------+-------+   +---------+------+
  | SizingLoopL1 |   | MissionLevel2  |
  |  con.optimal |   | aero.drag_polar|
  |  miss.fuel   |   | prop.TSFC      |
  +--------------+   +----------------+
```

**Swapping fidelity:**

```matlab
% L1 design study
aero = AeroLevel1('fighter', Cf, K_LD, S_wet, S_ref, b);
miss = MissionAnalysisLevel1('fighter', aero, ....);

% L2 design study — only these two lines change
aero = AeroLevel2('fighter', Cfe, AR, e_osw, S_wet, S_ref);
miss = MissionAnalysisLevel2(...);

% The sizing loop call is identical in both cases
[W_TO, S_ref, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);
```

---

## 4. How Fidelity Levels Build on Each Other

Each level adds geometric parameters and uses more physics. Higher levels do not replace lower levels — they extend them. 

| Level | Aero | Propulsion | Weights | Geometry | Mission |
|-------|------|-----------|---------|---------|---------|
| L1 | Cf(type) x S_wet/S_ref; K1 from K_LD | Type TSFC table; density-ratio lapse | Raymer Table 6.1 and Table 6.2 | Roskam S_wet regression | Fuel fractions + tabulated LD |
| L2 | Cf x S_wet/S_ref; K1 = 1/(pi*e*AR) | Mattingly installed TSFC + Mattingly dry/wet lapse | Raymer Eq 6.1 gross fraction | Adds b, AR, cbar, tc_wing | Single-point Breguet per segment |
| L3 | Component Cf_turb(Re); K1 from CL_minD; + wave drag (M > 1) | Same as L2 | Component buildup | Explicit all surfaces | 20-sub-segment cruise integration |
| L4 | Same as L3  | Same as L3 | Raymer Ch15 detailed method | Same as L3 | L3 logic with L4 disciplines |

There are separate markdown files for each discipline that has a lot more details. 

---

## 5. The Two Sizing Loops

### SizingLoopL1

**State variable:** W_TO only.

**At each iteration:**
1. `con.optimal_point(aero, prop)` returns W/S and T/W.
2. `S_ref = W_TO / (W/S)` — wing area is computed from the W/S and current W_TO guess.
3. `prop.T0 = T/W * W_TO` — thrust is set on the propulsion object.
4. `W_fuel = miss.compute_fuel(aero, prop, W_TO, req)`.
5. `W_OEW = wts.OEW(W_TO)`.
6. `W_TO_new = W_OEW + W_payload + W_fuel`.

**Update rule:**
```
W_TO = (1 - 0.5)*W_TO + 0.5*W_TO_new
```
The factor 0.5 is empirical under-relaxation to prevent oscillation. Without it, the loop can overshoot and diverge for stiff problems (high sensitivity of OEW to W_TO).

**Outputs:** W_TO, S_ref, T_SL.

### SizingLoopL2

**State variables:** W_TO and T_SL simultaneously. S_ref is a fixed input, not iterated.

**At each iteration:**
1. `con.optimal_point(aero, prop)` returns T/W (W/S is not used to update S_ref).
2. `T_SL_new = T/W * W_TO`; `prop.T0 = T_SL_new`.
3. `W_fuel = miss.compute_fuel(aero, prop, W_TO, req)`.
4. `W_OEW = wts.OEW(W_TO)`.
5. `W_TO_new = W_OEW + W_payload + W_fuel`.

**Convergence:** checked on both `|W_TO_new - W_TO|` and `|T_SL_new - T_SL|`.

**Outputs:** W_TO, T_SL. (S_ref was fixed on entry.)

In Step 4, where empty weight is being calculated:
Only when doing a component build-up of the weight, we need to size the tail
`tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)` returns S_HT, S_VT; stored back into `geom` and then compute the tail weight as part of the buildup.

**Call sequence diagram:**

```
SizingLoopL2.run(req, aero, prop, wts, geom, miss, con, tail)
  |
  +-- con.optimal_point(aero, prop) --> {W_S, T_W}
  |
  +-- prop.T0 = T_W * W_TO          [mutates prop handle]
  |
  +-- tail.size(S_ref, geom.b, geom.cbar, geom.L_fus) --> {S_HT, S_VT}
  |     geom.S_HT = S_HT            [mutates geom handle]
  |     geom.S_VT = S_VT
  |
  +-- miss.compute_fuel(aero, prop, W_TO, req) --> W_fuel
  |     internally calls aero.drag_polar(state), prop.TSFC(state)
  |
  +-- wts.OEW(W_TO) --> W_OEW
  |
  +-- W_TO_new = W_OEW + W_payload + W_fuel
  |
  +-- [check convergence, apply under-relaxation, repeat]
```

---

## 6. F-16 Example Walkthrough

The F-16A Block 10/15 is used as the validation baseline. All inputs live in `examples/F-16A B Block 10 and 15/Ground-Truth/f16a_geometry.json`. Ground truth from Brandt's spreadsheet:

| Quantity | Value |
|----------|-------|
| W_TO | 31,377 lb |
| OEW | 19,980 lb |
| W_fuel | 6,000 lb |
| S_ref | 300 ft² |
| T_SL (AB) | 23,770 lb |
| W/S | 104.59 psf |
| T/W | 0.7575 |
| S_wet | 1,331.09 ft² (corrected) |
| CD0 (mission) | 0.0270 |
| K2 | 0.1160 |
| K1 | -0.00630 |

**L1 sizing walkthrough:**

```matlab
geom = GeometryLevel1('fighter', 31377, 300);
aero = AeroLevel1('fighter', AeroLevel1.get_Cf('air force fighter',1), ...
                  AeroLevel1.tab_K_LD('jet fighter'), ...
                  geom.S_wet, geom.S_ref, b);
prop = PropulsionLevel1('low_bypass_mixed_turbofan');
wts  = WeightLevel1('fighter');
miss = MissionAnalysisLevel1('fighter', aero, prop, wts);
con  = ConstraintAnalysis();
sizer = SizingLoopL1();
[W_TO, S_ref, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);
```

At L1, the predicted W_TO will be in the right order of magnitude but may differ from the 31,377 lb Brandt value by 10–20% because the Cf value from Raymer's type table (0.0035 for Air Force fighter) produces CD0 lower than Brandt's calibrated value. The S_wet regression also has circularity: it depends on W_TO, which is being iterated.

---

## 7. How to Add a New Aircraft (4 Steps)

1. **Create a geometry JSON.** Copy `f16a_geometry.json` as a template. Fill in the aircraft-specific dimensions, engine data, constraint conditions, and mission profile.

2. **Subclass each discipline base class.** For L1/L2 this usually means overriding only the constructor (passing the aircraft-specific Cf, K_LD, e_osw, etc.) rather than re-implementing the abstract methods. Only if the physics formula changes must the abstract methods be overridden.

3. **Write a design study script.** Follow the pattern of `design_study_01.m`. Instantiate the discipline objects, set the `req` struct with payload, range, and initial W_TO guess, instantiate the sizing loop, call `sizer.run(...)`.

4. **Validate against any known reference.** For an existing aircraft, compare W_TO, S_ref, and T_SL to handbook data. For a new design, check that the sizing loop converges and that the constraint diagram plot makes physical sense.

---

## 8. How to Add a New Fidelity Level (3 Steps)

1. **Create the new class file.** Name it, for example, `AeroLevel3.m`. The first line must be:
   ```matlab
   classdef AeroLevel3 < AerodynamicsBase
   ```
   Implement all abstract methods declared in `AerodynamicsBase`.

2. **Add new properties needed by the higher fidelity.** If L3 aero needs Reynolds number, add `Re_ref` as a property. The base class does not need to change.

3. **Update the discipline factory or design study script.** Replace the L2 object instantiation with L3. No other code in the sizing loop or mission analysis changes because they call only the abstract interface methods.

---

## 9. Key MATLAB Concepts

### Handle Classes

All discipline base classes inherit from `handle`. This means:
- The variable holds a *reference* to the object, not a copy.
- Passing an object to a function and modifying its properties modifies the original object.
- `prop.T0 = T_SL` inside `SizingLoopL1.run` changes the same object that the caller created. No return value is needed.

This is intentional. The sizing loop must update `prop.T0` each iteration so that `con.optimal_point` and `miss.compute_fuel` see the current thrust level when they call `prop.thrust_lapse` or `prop.TSFC`.

### Inheritance and Abstract Methods

```matlab
classdef AeroLevel2 < AerodynamicsBase
    % Must implement drag_polar and CLmax, or MATLAB will error at instantiation.
    function polar = drag_polar(obj, state)
        ...
    end
    function CL = CLmax(obj, state)
        ...
    end
end
```

MATLAB raises an error if you try to instantiate a class that inherits from an abstract class without implementing all abstract methods.

### Value vs Handle Semantics

If `GeometryBase` were a value class (not a handle class), then passing `geom` to `SizingLoopL2.run` would create a copy. Modifications to `geom.S_HT` inside the loop would be invisible to the caller. By inheriting from `handle`, all modifications are visible everywhere.

---

## 10. Design Study Summary

| Study | Aero | Propulsion | Weights | Geometry | Mission | Tail | Sizing Loop |
|-------|------|-----------|---------|---------|---------|------|-------------|
| design_study_01 | AeroLevel1 | PropulsionLevel1 | WeightLevel1 | GeometryLevel1 | MissionLevel1 | none | SizingLoopL1 |
| design_study_02 | AeroLevel2 | PropulsionLevel2 | WeightLevel2 | GeometryLevel2 | MissionLevel2 | TailSizingLevel1 | SizingLoopL2 |
| design_study_03 | AeroLevel3 | PropulsionLevel3 | WeightLevel3 | GeometryLevel3 | MissionLevel3 | TailSizingLevel1 | SizingLoopL2 |

Design studies 02 and 03 use the same sizing loop. The improvement from 02 to 03 comes entirely from replacing the discipline objects with higher-fidelity implementations.

---

## 11. Common Pitfalls

### Handle Semantics and Unintentional Sharing

Because all discipline objects are handle instances, a single object can be shared between multiple design studies unintentionally. If one study modifies `prop.T0` and then a second study runs without re-creating `prop`, the second study inherits the mutated thrust value from the first.

**Rule:** Always create fresh discipline objects at the start of each design study script.

### prop.T0 Mutation

`PropulsionBase.T0` starts at 0. Before the first sizing loop iteration calls `prop.thrust_lapse` or `prop.TSFC` in a meaningful way, the sizing loop sets `prop.T0` from the constraint analysis. If you call `prop.thrust_lapse(state)` before running the sizing loop, T0 = 0 and the result is meaningless.

**Rule:** Never use a propulsion object's thrust-derived outputs until after the sizing loop has run at least one iteration.

### S_wet Circularity at L1

`GeometryLevel1` computes S_wet from a regression that depends on W_TO. But S_wet is used by `AeroLevel1` to compute CD0, which drives the constraint analysis, which drives the sizing loop. The loop will converge, but the converged S_wet implicitly anchors to the initial W_TO guess.

For the F-16 L1 validation, the Brandt W_TO (31,377 lb) is used as the anchor. The error introduced by the circularity is small compared to the regression uncertainty.
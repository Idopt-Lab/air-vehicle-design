# Geometry Discipline

## 1. Abstract Interface

**File:** `src/base/GeometryBase.m`

```matlab
classdef GeometryBase < handle
    properties
        S_ref   % reference wing area (ft²)
        S_wet   % total wetted area (ft²)
    end
end
```

`GeometryBase` is the only base class with **no abstract methods**. It defines the two properties that all higher-level discipline classes need (`S_ref` and `S_wet`). Each concrete subclass is free to add more properties.

### Why No Abstract Methods

Geometry objects are not called through a uniform interface by the sizing loop. Instead, discipline objects (Aerodynamics, Tail Sizing, etc.) receive a geometry object in their constructors and read whatever properties they need. The interface contract is: "you will always find `S_ref` and `S_wet` on any GeometryLevel*."

This is different from Aerodynamics and Propulsion, where the sizing loop calls specific named methods. Geometry is a *data carrier*, not an *algorithm provider*.

---

## 2. Level I Geometry

**File:** `src/Disciplines/Geometry/GeometryLevel1.m`

**Physics:** Roskam statistical regressions.

### Properties

| Property | Value source | Formula |
|---|---|---|
| `S_ref` | Set by sizing loop | `W_TO / W_S_opt` |
| `S_wet` | Roskam regression | `a * W_TO^b` (Table 3.5) |
| `L_fus` | Roskam regression | `a * W_TO^b` (Table 3.2) |
| `b` (span) | From `S_ref` and AR | `√(AR * S_ref)` |

The `S_wet` regression depends on aircraft type:

| Type | a | b | Source |
|---|---|---|---|
| Fighter | 4.183 | 0.4921 | Roskam Vol. I Table 3.5 |
| Transport | 5.655 | 0.4635 | Roskam Vol. I Table 3.5 |

Note: the `a` and `b` coefficients above are illustrative. The actual values in the code come from the Roskam tables.

### What Is Not Captured

Wing planform details: sweep angle, taper ratio, dihedral, root/tip chord. These are needed at L2+ but are not required at L1.

---

## 3. Level II Geometry

**File:** `src/Disciplines/Geometry/GeometryLevel2.m`

**Physics:** Roskam S_wet regression plus explicit wing planform properties.

### Constructor

```matlab
function obj = GeometryLevel2(S_ref, AR, lambda, sweep_LE_deg, L_fus)
```

`lambda` (taper ratio) defaults to 0.3 if not supplied.

### Properties Added Over L1

| Property | Formula | Used by |
|---|---|---|
| `AR` | input | Aerodynamics (K2 = 1/(π e AR)) |
| `lambda` | input | Wing root chord computation |
| `c_root` | `2*S_ref / (b*(1+lambda))` | Tail sizing (`cbar` computation) |
| `cbar` | `(2/3)*c_root*(1+λ+λ²)/(1+λ)` | `TailSizingLevel1.size()` |
| `S_HT` | Set by sizing loop | Aerodynamics (tail drag) |
| `S_VT` | Set by sizing loop | Aerodynamics (tail drag) |

**`cbar` (mean aerodynamic chord):** The tail volume coefficient method requires the mean aerodynamic chord as a reference length for the horizontal tail:

```
S_HT = c_HT * cbar * S_ref / L_HT
```

where `L_HT` is the tail moment arm (estimated as `0.5 * L_fus` at L1). The standard expression for the MAC of a linearly tapered wing is:

```
cbar = (2/3) * c_root * (1 + lambda + lambda²) / (1 + lambda)
```

### Why `lambda` Defaults to 0.3

0.3 is the taper ratio of the F-16 cranked wing (approximate). For students who do not yet have a finalized planform, 0.3 is a reasonable representative fighter value. The default avoids an error in early-stage design loops when geometry is not yet fully defined.

---

## 4. Level III Geometry

**File:** `src/Disciplines/Geometry/GeometryLevel3.m`

**Physics:** Explicit component planform dimensions; `S_wet` from Raymer/DATCOM empirical panel integrals.

### Properties Added Over L2

| Property | Source | Used by |
|---|---|---|
| `S_wet_wing` | Raymer exposed-wing formula | Aerodynamics CD0 |
| `S_wet_fus` | Roskam trapezoidal cross-section integration | Aerodynamics CD0 |
| `S_wet_HT`, `S_wet_VT` | Exposed HT/VT | Aerodynamics CD0 |
| `e_osw` | Oswald efficiency (from planform) | Aerodynamics K2 |
| `CL_minD` | From camber/twist, or tabulated | Aerodynamics K1 |
| `cl_max_airfoil` | Airfoil data | CLmax computation |
| `Amax` | Max fuselage cross-section area (ft²) | Wave drag (L4) |
| `sweep_LE_deg`, `sweep_c4_deg`, `sweep_c2_deg` | Geometry | Aerodynamics Oswald |

### `get_design_S_wet(aircraft_type, W_TO)`

A static method that wraps the type-based Roskam regression. It takes `aircraft_type` as an explicit argument rather than using a hardcoded fighter regression. This is the fix for Casey's original code where the regression constants were hard-coded to fighter values, making the class unusable for other aircraft types.

---

## 5. Discrepancies With Brandt

Brandt's Excel workbook (`Geom` tab) shows:

| Quantity | Brandt | L1 (Roskam) | L2 (Roskam+Raymer) | L3 (component) |
|---|---|---|---|---|
| S_wet total | 1,331.09 ft² | Regression (~1,200–1,500 ft²) | Better regression | Component sum |
| S_wet fuselage | 730.4 ft² | Not resolved | Not resolved | Integration |
| S_wet wing | 392.0 ft² | Not resolved | Raymer formula | Raymer formula |
| L_fus | 48.3 ft | Roskam regression | Input from JSON | Input from JSON |

**Known Excel bug:** Brandt's `Geom!B19` double-counts the strake S_wet. The corrected total S_wet is 1,332.7 ft². The L1/L2 models compare against 1,331.09 (what the Excel formula returns). L3 should approach 1,332.7 ft² when the geometry inputs are correct.

---

## 6. F-16 Geometry Classes

The F-16-specific subclasses live in `examples/.../disciplines/Geometry/`. They do not override any computation; they only populate the geometry properties from the JSON file.

**`F16GeometryLevel3`** is worth noting specifically: it hardcodes several Brandt-calibrated values (e.g., `S_wet = 1331.09`, `e_osw = 0.73`, `CL_minD = 0.05`) directly from the Excel ground-truth file. This is intentional — at L3, the geometry object is the "tuned" representation and its values should match the reference.

---

## 7. Key Design Decisions

**Why geometry is a data carrier, not an algorithm provider:** The sizing loop needs to update `S_ref` each iteration (at L1) or read tail areas after each tail-sizing call (at L2). A uniform method call interface is appropriate for these updates. Using properties instead of methods lets the sizing loop write `geom.S_ref = S_ref` (mutation in place via handle class) without the coupling that would come from calling a method.

**Why `S_HT` and `S_VT` live in the geometry object:** After `tail.size(...)` runs, the new tail areas are stored in `geom.S_HT` and `geom.S_VT`. They can then be read by the aerodynamics object at the next iteration (for tail drag contribution). Storing them in geometry avoids a separate state object and keeps all physical dimensions co-located.

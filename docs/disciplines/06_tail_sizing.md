# Tail Sizing Discipline

## 1. Abstract Interface

**File:** `src/base/TailSizingBase.m`

```matlab
classdef TailSizingBase < handle
    methods (Abstract)
        size(obj, S_ref, b, cbar, L_fus)
    end
end
```

`size` is a mutating method: it writes `obj.S_HT` and `obj.S_VT` on the tail-sizing object and also writes into the geometry object (the sizing loop stores the results in `geom.S_HT`, `geom.S_VT`).

Inputs:
- `S_ref` — wing reference area (ft²)
- `b` — wing span (ft)
- `cbar` — mean aerodynamic chord (ft)
- `L_fus` — fuselage length (ft)

### Why Tail Sizing Is Its Own Discipline

Tail sizing is not part of aerodynamics or geometry — it is a separate design decision with its own inputs and outputs. It is called by `SizingLoopL2` (not L1), after convergence of W_TO and T_SL, to produce the tail geometry that feeds back into the L2 drag buildup and the L3 stability analysis.

Separating it into its own class allows:
- Multiple tail sizing methods (volume coefficient, stability margin, CFD-based) to coexist with the same interface
- The sizing loop code to remain fidelity-agnostic

### Why Not Called at L1

Level I sizing does not compute tail areas. The drag polar at L1 is based on total wetted area (Roskam regression), which already statistically includes tail contribution. Computing a separate `S_HT` at L1 would require geometry that the loop doesn't yet have and would not improve the accuracy of a regression-based drag polar.

Tail sizing begins at L2, where the drag polar explicitly depends on `S_HT` and `S_VT` (through `S_wet` = wing + fus + tail contributions).

---

## 2. Level I Tail Sizing (Volume Coefficient Method)

**File:** `src/Disciplines/TailSizing/TailSizingLevel1.m`

**Physics:** Raymer Equations 6.28–6.29, tail volume coefficient method.

### Equations

```
S_HT = c_HT * cbar * S_ref / L_HT
S_VT = c_VT * b   * S_ref / L_VT
```

where:
- `c_HT` — horizontal tail volume coefficient
- `c_VT` — vertical tail volume coefficient
- `L_HT = 0.5 * L_fus` — horizontal tail moment arm (approximation)
- `L_VT = 0.5 * L_fus` — vertical tail moment arm (approximation)

The volume coefficient captures historical data on what values of `c_HT` and `c_VT` produce adequate stability and control for each aircraft category. From Raymer Table 6.4:

| Aircraft type | `c_HT` | `c_VT` |
|---|---|---|
| Fighter | 0.40 | 0.07 |
| Transport | 1.0 | 0.09 |
| General aviation (prop) | 0.70 | 0.04 |

The constructor takes `c_HT` and `c_VT` as arguments so the same class can represent any aircraft type. The aircraft-specific values are set in the F-16 subclass constructor.

### Why `L_HT = 0.5 * L_fus`

At Level I/II, the tail moment arm is not yet a precisely known quantity — it depends on center of gravity, neutral point, and tail location, none of which are available this early in the design loop. The 50% fuselage length approximation comes from Raymer's observation that for most conventional aircraft, the HT aerodynamic center is located 45–55% of fuselage length from the nose.

A better estimate (`L_HT = x_HT_AC - x_CG`) is available at L3 when the component buildup places the CG and the tail geometry fixes `x_HT_AC`, but at L2 fidelity the `0.5 * L_fus` approximation is consistent with the overall accuracy level.

### F-16 Values

**File:** `examples/.../disciplines/TailSizing/F16TailSizingLevel1.m`

```matlab
function obj = F16TailSizingLevel1()
    obj@TailSizingLevel1(0.40, 0.07);  % Raymer T6.4 fighter values
end
```

---

## 3. Tail Sizing in the Sizing Loop

`SizingLoopL2` calls tail sizing on every iteration:

```matlab
tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)
geom.S_HT = tail.S_HT;
geom.S_VT = tail.S_VT;
```

The tail areas are then read by `AeroLevel2/3` to compute the wetted area contribution of the tail surfaces to `CD0`. This means the aerodynamics and tail sizing are loosely coupled through the geometry object — each iteration, the tail sizing produces new areas, the aerodynamics computes new `CD0` using those areas, and the mission analysis computes new fuel.

This coupling does not require a nested inner loop because the volume coefficient method gives a stable unique answer for any given `(S_ref, b, cbar, L_fus)` — it does not itself depend on aerodynamic performance.

---

## 4. Brandt Ground-Truth Comparison

Brandt's F-16A/B Block 10/15 tail areas:

| Surface | Brandt | Volume coeff. method | Notes |
|---|---|---|---|
| `S_HT` (stabilator) | ~108 ft² | Computed from `c_HT=0.40` | Canless delta + stabilator config |
| `S_VT` (vertical tail) | ~60 ft² | Computed from `c_VT=0.07` | Single large VT |

These are approximate values. Brandt does not separately list stabilator area in the Geom tab; they are back-calculated from the volume coefficient and the reference dimensions. At L2, the sizing loop is expected to reproduce Brandt's `S_HT` and `S_VT` to within ±15%.

---

## 5. Key Design Decisions

**Why the method is named `size` not `compute_tail_areas`:** The method is a design action (it sizes the tail to satisfy a stability criterion), not a data extraction. This parallels the convention in the rest of the framework where methods are named by what they *do* (`compute_fuel`, `OEW`, `drag_polar`), not what they *return*.

**Why `cbar` is needed:** The volume coefficient formula ties the stabilizer sizing to the wing chord. Using `S_ref / b` (mean geometric chord) would work for an untapered wing. For a tapered wing, the aerodynamic reference chord `cbar` is the appropriate length because it represents where the wing moment acts. The MAC computation is in `GeometryLevel2`.

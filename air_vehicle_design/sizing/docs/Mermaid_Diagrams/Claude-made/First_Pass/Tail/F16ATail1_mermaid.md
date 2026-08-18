# F16TailL1: input-to-output data flow

This chart shows the data path for `F16TailL1`, the Level 1 (L1) tail-sizing
class. L1 sizes both tails from volume coefficients: `S_HT` from the HT
coefficient, the wing MAC, the reference area and the HT arm, and `S_VT` from
the VT coefficient, the span, the area and the VT arm.

**This is the only class in the set with NO input file and NO injected object.**
The constructor takes no arguments. Its two coefficients come from a toolbox
lookup keyed on the category and two configuration flags. Everything else
arrives as call arguments.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is very small.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green calls another function. Red dashed has no
  production caller.
- Every edge takes the color of the node it POINTS AT. The arrow carrying
  `c_HT` and `c_VT` back INTO the constructor is therefore cyan.
- `size` shadows MATLAB's built-in `size` for this class. The contract names it,
  so the class must too.
- `compute_tail_arm_quarter_chord` is LIVE, but no tail class calls it. Both
  geometry classes do, for their `L_HT` and `L_VT` getters. That external
  consumer is drawn as a source node, because the call does not pass through
  the tail class.
- `compute_tail_arm` has no production caller. It is the older
  0.475 times fuselage-length approximation. `F16TailL2` moved to a
  centre-of-gravity-based arm, and the geometry classes moved to the
  quarter-chord form.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        CALLER["Caller<br/>(supplies S_ref, b, cbar, L_HT, L_VT)"]
        GEOMC["External consumer<br/>F16GeomL2 and F16GeomL3"]
    end

    subgraph CLASS["F16TailL1 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16TailL1()<br/>in: nothing<br/>out: c_HT, c_VT"]
        M1["size(obj, S_ref, b, cbar, L_HT, L_VT)<br/>in: c_HT, c_VT, S_ref, b, cbar, L_HT, L_VT<br/>out: struct(S_ht, S_vt)"]
    end

    subgraph TOOL["TailL1 toolbox (static methods)"]
        T1["size(obj, S_ref, b, cbar, L_HT, L_VT)"]
        T2["compute_tail_volume_coeffs(aircraft_category,<br/>has_rss, has_all_moving_tail)<br/>Raymer 7th ed. Table 6.4 plus text corrections"]
        T3["lookup_tail_volume_coeffs(cat)<br/>Raymer 7th ed. Table 6.4"]
        T4["compute_S_HT(c_HT, cbar, S_ref, L_HT)"]
        T5["compute_S_VT(c_VT, b, S_ref, L_VT)"]
        T6["compute_tail_arm_quarter_chord(x_c4_tail, x_c4_wing)<br/>Raymer 6th ed. Sec. 6.5.2"]
        D1["compute_tail_arm(L_fus)<br/>NO PRODUCTION CALLER<br/>the older 0.475 times L_fus approximation"]
    end

    CTOR -->|"compute_tail_volume_coeffs: jet_fighter,<br/>has_rss = true, has_all_moving_tail = true"| T2
    T2 -->|"compute_tail_volume_coeffs: aircraft_category"| T3
    T2 -->|"c_HT, c_VT"| CTOR

    CALLER -->|"S_ref, b, cbar, L_HT, L_VT"| M1
    CTOR -->|"c_HT, c_VT"| M1
    M1 -->|"size: obj, S_ref, b, cbar, L_HT, L_VT"| T1
    T1 -->|"size: c_HT, cbar, S_ref, L_HT"| T4
    T1 -->|"size: c_VT, b, S_ref, L_VT"| T5

    GEOMC -->|"x_c4_ht or x_c4_vt, x_c4_wing"| T6

    CTOR -.->|"no production caller"| D1

    linkStyle 2 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 0,1,3,4,5,6,7,8 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 9 stroke:#ff4040,color:#ff4040,stroke-width:2px,stroke-dasharray:5 5

    classDef dead fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040,stroke-dasharray: 6 4
    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    class D1 dead
    class CTOR ctor
    class M1,T1,T2,T3,T4,T5,T6 func
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `c_HT`, `c_VT` | `TailL1.compute_tail_volume_coeffs` | NET coefficients, from the Table 6.4 row plus the text corrections that the two configuration flags select. The constructor hardcodes `jet_fighter`, relaxed static stability true, and all-moving tail true. |
| `S_ref`, `b`, `cbar`, `L_HT`, `L_VT` | Call arguments | Nothing is stored. The caller supplies the planform and both arms on every call. |
| `TailSizingBase` | Abstract | Declares one method, `size`, with six arguments. |
| `compute_tail_arm_quarter_chord` | Live, called from geometry | `F16GeomL2` and `F16GeomL3` use it for `L_HT` and `L_VT`. No tail class calls it. |

## Methods with no upstream call at L1

| Method | Why |
| --- | --- |
| `TailL1.compute_tail_arm` | The 0.475 times fuselage-length approximation. `F16TailL2` uses a centre-of-gravity-based arm instead, and the geometry classes use the quarter-chord form. Called now only by a generator script, the comparison report and tests. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/tail/F16TailL1.m` |
| Tier 2, abstract | `src/disciplines/tail_sizing/TailSizingModelL1.m`, empty |
| Tier 1, base | `src/base/TailSizingBase.m` |
| Toolbox | `src/disciplines/tail_sizing/TailL1.m` |
| External consumer | `examples/F16A/models/disciplines/geom/F16GeomL2.m`, `F16GeomL3.m` |
| Input JSON | None. This class reads no file |

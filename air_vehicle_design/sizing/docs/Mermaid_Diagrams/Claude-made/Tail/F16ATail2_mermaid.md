# F16TailL2: input-to-output data flow

This chart shows the data path for `F16TailL2`, the Level 2 (L2) tail-sizing
class. L2 uses the same volume-coefficient equations as L1, and differs in two
ways: the coefficients come from a different source, and both tail arms are
computed from a centre-of-gravity estimate rather than supplied by the caller.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is very small.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green calls another function.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes. All five `TailL2` statics are reached.
- `size(obj)` takes NO arguments here, against six at L1. Everything comes from
  the injected geometry object. The base contract declares six, so the three
  concrete classes disagree on arity. See S-36 in the findings log.
- The two coefficients are HARDCODED in the constructor, not read from JSON.
  They come from the Nicolai and Carichner table's own F-16 row.
- L2 does NOT call `TailL1.compute_tail_arm` any more. It computes an initial
  centre of gravity from the wing MAC leading edge, then takes each arm as the
  distance from that station to the tail quarter-chord.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        GEOM["Injected object<br/>geom (GeometryModelL2)"]
    end

    subgraph CLASS["F16TailL2 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16TailL2(geom)<br/>in: geom<br/>out: C_HT, C_VT hardcoded,<br/>stored geom handle"]
        M1["size(obj)<br/>in: C_HT, C_VT, and six geometry values<br/>out: struct(S_ht, S_vt)"]
    end

    subgraph TOOL["TailL2 toolbox (static methods)"]
        T1["size(obj)"]
        T2["compute_x_cg_initial(x_mac_le_wing, cbar_wing)"]
        T3["compute_tail_arm_cg(x_c4_tail, x_cg)"]
        T4["compute_S_HT(C_HT, cbar, S_ref, L_HT)"]
        T5["compute_S_VT(C_VT, b, S_ref, L_VT)"]
    end

    GEOM -->|"geom"| CTOR

    CTOR -->|"C_HT, C_VT, Nicolai and Carichner<br/>Table 11.6 F-16 row"| M1
    GEOM -->|"S_ref, b_wing, cbar_wing,<br/>x_mac_le_wing, x_c4_ht, x_c4_vt"| M1
    M1 -->|"size: obj"| T1

    T1 -->|"size: x_mac_le_wing, cbar_wing"| T2
    T1 -->|"size: x_c4_ht, x_cg"| T3
    T1 -->|"size: x_c4_vt, x_cg"| T3
    T1 -->|"size: C_HT, cbar_wing, S_ref, L_HT"| T4
    T1 -->|"size: C_VT, b_wing, S_ref, L_VT"| T5

    linkStyle 0 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 1,2,3,4,5,6,7,8 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    class CTOR ctor
    class M1,T1,T2,T3,T4,T5 func
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `C_HT`, `C_VT` | Hardcoded in the constructor | Nicolai and Carichner Table 11.6, the General Dynamics F-16 row, p.289. A different source from L1's Raymer Table 6.4 coefficients, so the two tiers are not the same equation fed different numbers; they are different tables. |
| `geom` | Injected, `GeometryModelL2` | Supplies six values: the reference area, span and MAC for the sizing equations, and the MAC leading edge plus both tail quarter-chord stations for the arms. |
| `x_cg` | `compute_x_cg_initial` | An initial estimate from the wing MAC leading edge and the MAC itself. This is what replaced the fuselage-length approximation. |
| `L_HT`, `L_VT` | `compute_tail_arm_cg` | Each arm is the distance from the estimated centre of gravity to that tail's quarter-chord station. The same static serves both, called twice. |

## Methods with no upstream call at L2

None. All five `TailL2` statics are reached.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/tail/F16TailL2.m` |
| Tier 2, abstract | `src/disciplines/tail_sizing/TailSizingModelL2.m`, empty |
| Tier 1, base | `src/base/TailSizingBase.m` |
| Toolbox | `src/disciplines/tail_sizing/TailL2.m` |
| Injected geometry | `examples/F16A/models/disciplines/geom/F16GeomL2.m` |
| Input JSON | None. This class reads no file |

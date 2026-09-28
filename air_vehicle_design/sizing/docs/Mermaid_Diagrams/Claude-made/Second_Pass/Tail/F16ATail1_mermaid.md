# F16TailL1: input-to-output data flow

This chart shows the data path for `F16TailL1`, the Level 1 (L1) tail-sizing
class. It sizes the horizontal and vertical tails from Raymer's tail volume
coefficients, and the sizing loop calls it every iteration.

## Viewing this chart with pan and zoom

Mermaid inside a `.md` renders at a fixed size, so a wide chart is hard to read
in a plain preview. Open `docs/Mermaid_Diagrams/viewer.html` and drag this file
onto it. Wheel or pinch zooms, drag pans, and `f` fits.

The viewer reads the first mermaid fenced block straight out of this file, so
there is no second copy of the diagram to keep in step.

**Read this first.**
- The chart runs LEFT TO RIGHT.
- One function per node. Name, inputs, output, citation. Returned values and
  coefficients live in the notes table, not in the labels.
- No grouped "Inputs" node. Every value rides the arrow that carries it. A
  source node holds only a file or object name.
- **Colour says what kind of member a node is; dash says whether the value was
  worked on.** Every box here evaluates an equation, reads a table or calls a
  method, so every box is solid.
- **A line's colour comes from the node it POINTS AT; its dash comes from the
  node it LEAVES.** A source node is not a method, so it takes the solid dash of
  the constructor.
- Constructor cyan. Every other function green.
- **THIS CLASS HAS NO `Dependent` PROPERTIES, so there are no magenta nodes.**
  `c_HT` and `c_VT` are set once by the constructor and are private.
- **THE CONSTRUCTOR HARDCODES THE COEFFICIENT INPUTS.** It passes
  `'jet_fighter'`, `has_rss = true` and `has_all_moving_tail = true` to
  `compute_tail_volume_coeffs`. None of them comes from a JSON file.
- **THE SIZING LOOP WRITES THE RESULT BACK.** `SizingLoopL2` calls `size()`
  every iteration and writes `S_ht` and `S_vt` onto the geometry object.
  `TSDiagram` does the same per cell.
- **L1 TAIL SIZING RUNS ON AN L2 OR L3 GEOMETRY.** `size()` reads `b_wing`,
  `cbar_wing` and `L_fus`, which only the planform geometry classes supply.
- One red node: `compute_tail_arm_wing_mounted`. Only `B777TailL1` calls it.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        GEOM["Injected geometry<br/>geom (GeometryBase)"]
        SL["Caller<br/>SizingLoopL2, TSDiagram"]
    end

    subgraph CLASS["F16TailL1 (Tier 3)"]
        direction LR

        CTOR["Constructor<br/>F16TailL1(geom)<br/>in: geom<br/>out: geom, c_HT, c_VT"]
        M1["size(obj)<br/>required by TailSizingBase<br/>in: c_HT, c_VT, S_ref, b_wing, cbar_wing, L_fus<br/>out: struct(S_ht, S_vt)"]
    end

    subgraph TL1["TailL1 toolbox (static methods)"]
        T1["size(c_HT, c_VT, S_ref, b, cbar, L_fus)<br/>out: struct(S_ht, S_vt)<br/>Raymer 7th ed. Table 6.4"]
        T2["compute_tail_volume_coeffs(aircraft_category, has_rss,<br/>has_all_moving_tail)<br/>out: c_HT, c_VT<br/>Raymer 7th ed. Table 6.4 + text"]
        T3["lookup_tail_volume_coeffs(cat)<br/>out: base c_HT, c_VT<br/>Raymer 7th ed. Table 6.4"]
        T4["compute_tail_arm(L_fus)<br/>out: L_HT = L_VT<br/>Raymer 7th ed. text rule"]
        T5["compute_S_HT(c_HT, cbar, S_ref, L_HT)<br/>out: S_ht<br/>Raymer 7th ed. Table 6.4"]
        T6["compute_S_VT(c_VT, b, S_ref, L_VT)<br/>out: S_vt<br/>Raymer 7th ed. Table 6.4"]
        T7["compute_tail_arm_wing_mounted(L_fus)<br/>NO UPSTREAM CALL at L1<br/>Raymer text rule, wing-mounted engines"]
    end

    subgraph TB["TailSizingBase statics"]
        B1["tail_volume_area(coef, length_scale, S_ref, arm)<br/>out: tail area<br/>volume-coefficient definition"]
    end

    GEOM -->|"geom"| CTOR

    CTOR -->|"F16TailL1: 'jet_fighter', true, true"| T2

    T2 -->|"compute_tail_volume_coeffs: aircraft_category"| T3

    SL -->|"size(), every iteration"| M1

    CTOR -->|"c_HT, c_VT"| M1

    GEOM -->|"geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus"| M1

    M1 -->|"size: c_HT, c_VT, S_ref, b_wing, cbar_wing, L_fus"| T1

    T1 -->|"size: L_fus"| T4
    T1 -->|"size: c_HT, cbar, S_ref, L_HT"| T5
    T1 -->|"size: c_VT, b, S_ref, L_VT"| T6

    T5 -->|"compute_S_HT: c_HT, cbar, S_ref, L_HT"| B1

    T6 -->|"compute_S_VT: c_VT, b, S_ref, L_VT"| B1

    linkStyle 0 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 1,2,3,4,5,6,7,8,9,10,11 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctorWork fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef funcWork fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef deadWork fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040
    class CTOR ctorWork
    class M1,T1,T2,T3,T4,T5,T6,B1 funcWork
    class T7 deadWork
```

## Field-by-field notes

Values on the as-built `F16GeomL2`.

| Class member | Source | Value / note |
| --- | --- | --- |
| `geom` | Injected, `GeometryBase` | `F16GeomL2` or `F16GeomL3` in the sizing drivers |
| Base coefficients | `lookup_tail_volume_coeffs('jet_fighter')` | `c_HT` 0.40, `c_VT` 0.07 |
| `c_HT`, `c_VT` | Constructor | 0.3150, 0.0630: minus 10 % each for relaxed static stability, then minus 12.5 % on `c_HT` for the all-moving tail |
| Tail arm | `compute_tail_arm(L_fus)` | 0.475 x 46.5 = 22.0875 ft. 0.475 is the midpoint of Raymer's 0.45-0.50 range. `L_VT = L_HT`. |
| `size().S_ht`, `size().S_vt` | Computed | 48.4327, 25.6706 ft^2 on `F16GeomL2`; 47.4130, 25.1302 ft^2 on `F16GeomL3` (longer T.O. fuselage) |

## Methods with no upstream call at L1

| Static | Home | Note |
| --- | --- | --- |
| `compute_tail_arm_wing_mounted` | `TailL1` | 0.525 x `L_fus`. Called by `B777TailL1` only. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/tail/F16TailL1.m` |
| Tier 2, abstract | `src/disciplines/tail_sizing/TailSizingModelL1.m` |
| Tier 1, base | `src/base/TailSizingBase.m` |
| Toolbox | `src/disciplines/tail_sizing/TailL1.m` |
| Callers | `src/sizing/SizingLoopL2.m`, `src/sizing/TSDiagram.m` |

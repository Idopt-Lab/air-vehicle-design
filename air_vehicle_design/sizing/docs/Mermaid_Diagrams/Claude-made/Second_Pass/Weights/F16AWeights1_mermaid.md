# F16WeightsL1: input-to-output data flow

This chart shows the data path for `F16WeightsL1`, the Level 1 (L1) weights
class. L1 is a statistical empty-weight fraction: a power law in `W_TO`
selected by aircraft category.

L1 is the only weights level with NO dependency injection. The regression takes
just `W_TO` and `aircraft_category`, so there is no design Mach, no cruise
condition, no geometry object and no propulsion object to inject.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is small, so the vertical form reads
  better.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the
  field names.
- The constructor is cyan. Every other function is green.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes and NO yellow nodes. Every static drawn is reached,
  and no getter is a passthrough, because L1 has zero `Dependent` properties.
- Zero derived properties is the correct answer here, not an oversight.
  `get_OEW` and `get_OEW_categorical` both take `W_TO` as an ARGUMENT, so they
  recompute per call and cannot go stale. The inputs-versus-dependent rule
  governs stored derived state, and L1 stores none.
- THE THREE CLASS METHODS ARE NOW ONE. The first pass drew `OEW`,
  `compute_We_fraction` and `compute_We_roskam` side by side at class level,
  because `WeightsBase` and `WeightsModelL1` named the same quantities twice.
  `WeightsModelL1` now supplies a concrete `get_OEW` bridge, so the concrete
  class writes the categorical form ONLY.
- `W_TO` therefore arrives ONCE, not three times. There is a single public
  entry point, and it takes `W_TO` as a call argument. The class never reads
  `obj.W_TO`, which is exactly what stops the value going stale.
- The `W_TO` property still exists, to satisfy the `WeightsBase` contract, and
  it is `NaN` until the loop sets it. No method here reads it.
- `K_vs` IS NOT TABULATED. It is a design value, not a Table 3.1 constant, so
  `lookup_raymer_We_frac_coeffs` returns only `A` and `C`. The F-16A is
  fixed-sweep, so `get_OEW_categorical` passes 1.00 as a literal.
- The two regressions are NOT interchangeable, and this class uses ONE of them.
  Raymer's power law is the central estimate and is what `get_OEW` returns.
  Roskam's Eq. 2.16 is a LOWER BOUND on empty weight: an actual OEW should
  exceed it, and it must never be summed into an OEW or reported as one. No
  F-16A class reaches it.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L1.json"]
        SL["Sizing loop<br/>(supplies W_TO as a CALL ARGUMENT)"]
    end

    subgraph CLASS["F16WeightsL1 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16WeightsL1(json_path)<br/>in: json_path<br/>out: aircraft_category, W_payload_fixed,<br/>W_payload_expendable<br/>(W_TO and W_energy stay NaN)"]

        M1["get_OEW(obj, W_TO)<br/>INHERITED bridge from WeightsModelL1<br/>in: W_TO<br/>out: OEW [lbf], the official L1 answer"]
        M2["get_OEW_categorical(obj, W_TO)<br/>required by WeightsModelL1<br/>in: aircraft_category, W_TO<br/>out: OEW [lbf]"]
    end

    subgraph TOOL["WeightsL1 toolbox (static methods)"]
        L1["lookup_raymer_We_frac_coeffs(aircraft_category)<br/>Raymer 6th ed. Table 3.1"]
        L2["compute_We_frac_raymer(Kvs, A, C, W_TO)<br/>Raymer 6th ed. Table 3.1"]
    end

    J -->|"aircraft_category: jet_fighter"| CTOR
    J -->|"weights: W_payload_fixed = 700,<br/>W_payload_expendable = 4400"| CTOR

    SL -->|"W_TO, argument of the get_OEW call"| M1
    M1 -->|"get_OEW: W_TO"| M2
    CTOR -->|"aircraft_category"| M2

    M2 -->|"get_OEW_categorical: aircraft_category"| L1
    M2 -->|"get_OEW_categorical: 1.00, c.A, c.C, W_TO"| L2

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 2,3,4,5,6 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    class CTOR ctor
    class M1,M2,L1,L2 func
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `aircraft_category` | `f16a_L1.json`, top-level field | One canonical flag. Selects the Raymer Table 3.1 row. It also names the Roskam Table 2.15 row, but this class no longer reaches that lookup. |
| `W_TO` | Sizing loop, mutated in place | `NaN` until the loop sets it. A `WeightsBase` abstract property. |
| `W_energy` | Mission analysis, mutated in place | `NaN` until set. Was previously 6296.3, which is Brandt Wt!B6, a live formula `= B3 - B4 - B5 - B12`, so `W_TO` minus payload minus OEW: a back-calculated Brandt OUTPUT. Deleted from the JSON in Phase 3, because CLAUDE.md forbids using an output as an input. |
| `W_payload_expendable` | `.weights.W_payload_expendable` | 4400 lbf, Brandt Wt!B5. |
| `W_payload_fixed` | `.weights.W_payload_fixed` | 700 lbf, Brandt Wt!B4. |
| Both payload values | | INERT. No `WeightsL1` static reads either one. They satisfy the `WeightsBase` closure contract and are consumed by the sizing loop, which sums them and hands the total to `SizingSteps.togw_update`. They make the closure identity work out: 31377 - 19980.70 - 6296.30 = 5100 = 700 + 4400. |
| `A`, `C` | `lookup_raymer_We_frac_coeffs` | 2.34 and -0.13 for `jet_fighter`, Raymer Table 3.1 via `metabook_data.md:22`. |
| `K_vs` | Literal in `get_OEW_categorical` | 1.00, fixed sweep. NOT returned by the lookup: `K_vs` is a design value, not a table constant. 1.04 would be variable sweep, `metabook_data.md:20-22`. |
| `get_OEW` at `W_TO` = 31,377 lbf | Computed | Fraction 0.609055, so OEW = 19,110.31 lbf. |
| L1 sizing closure | Computed | `W_TO` 26,762.1 lbf and OEW 16,640.2 lbf, 12 iterations. |
| Ground truth, for context only | | Brandt Wt!B12 = 19,980.70 lbf, so -4.36 percent. Casey's `corrections.xls` = 19,148.08 lbf, so -0.20 percent. Two distinct provenances about 4.3 percent apart. The class header records that an earlier version cited the wrong cell in the wrong workbook. |

## Methods with no upstream call at L1

Two of the four `WeightsL1` statics are not reached from inside this class, so
neither appears in the chart: they carry no arrow out of `F16WeightsL1`. Both
are live and correct.

| Static | Reached by |
| --- | --- |
| `lookup_We_roskam_coeffs(aircraft_category)` | `Aero481WeightsL1.compute_We_roskam` |
| `compute_We_roskam(A, B, W_TO)` | `Aero481WeightsL1.compute_We_roskam` |

Together they give the Roskam Part I Eq. 2.16 log-log minimum empty weight,
`jet_fighter` `A` = 0.5091 and `B` = 0.9505, which is 15,673.73 lbf at
`W_TO` = 31,377. Roskam presents it as a bound, so no F-16A class uses it as an
OEW.

`compute_We_frac_raymer` is also reached from outside this class:
`Aero481WeightsL1.compute_We_fraction` calls it with Sainristil coefficients
rather than Raymer's, because the equation is the bare `Kvs * A * W^C` power law
and the name records only where the F-16A's coefficients come from.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/weights/F16WeightsL1.m` |
| Tier 2, abstract | `src/disciplines/weights/WeightsModelL1.m` |
| Tier 1, base | `src/base/WeightsBase.m` |
| Toolbox | `src/disciplines/weights/WeightsL1.m` |
| Input JSON | `examples/F16A/inputs/f16a_L1.json` |

# F16WeightsL1: input-to-output data flow

This chart shows the data path for `F16WeightsL1`, the Level 1 (L1) weights
class. L1 is a statistical empty-weight fraction: a power law in `W_TO`, with
an independent regression as a lower bound.

L1 is the only weights level with NO dependency injection. Both regressions
take just `W_TO` and `aircraft_category`, so there is no design Mach, no cruise
condition, no geometry object and no propulsion object to inject.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is small, so the vertical form reads
  better.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the
  field names.
- The constructor is cyan. Every other function is green.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes and NO yellow nodes. Every `WeightsL1` static is
  reached, and no getter is a passthrough, because L1 has zero `Dependent`
  properties.
- Zero derived properties is the correct answer here, not an oversight. `OEW`,
  `compute_We_fraction` and `compute_We_roskam` all take `W_TO` as an
  ARGUMENT, so they recompute per call and cannot go stale. The
  inputs-versus-dependent rule governs stored derived state, and L1 stores
  none.
- `W_TO` arrives THREE times, once per public method, and that is not
  duplication. The three methods are independent entry points, and each takes
  `W_TO` as a call argument. The class never reads `obj.W_TO` in any of them,
  which is exactly what stops the value going stale. `OEW` does not call
  `compute_We_fraction` at class level either: it delegates to the toolbox, and
  that chaining is the `T1` to `T2` edge inside the toolbox band.
- The `W_TO` property still exists, to satisfy the `WeightsBase` contract, and
  it is `NaN` until the loop sets it. No method here reads it.
- The two regressions are NOT interchangeable. Raymer's power law is the
  central estimate and is what `OEW` returns. Roskam's Eq. 2.16 is a LOWER
  BOUND on empty weight: an actual OEW should exceed it, and it must never be
  summed into an OEW or reported as one.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L1.json"]
        SL["Sizing loop<br/>(supplies W_TO as a CALL ARGUMENT)"]
    end

    subgraph CLASS["F16WeightsL1 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16WeightsL1(json_path)<br/>in: json_path<br/>out: aircraft_category, W_payload_fixed,<br/>W_payload_expendable<br/>(W_TO and W_energy stay NaN)"]

        M1["OEW(obj, W_TO)<br/>required by WeightsBase<br/>in: aircraft_category, W_TO<br/>out: OEW [lbf], the official L1 answer"]
        M2["compute_We_fraction(obj, W_TO, aircraft_category)<br/>required by WeightsModelL1<br/>in: aircraft_category, W_TO<br/>out: We/W_TO fraction"]
        M3["compute_We_roskam(obj, W_TO)<br/>required by WeightsModelL1<br/>in: aircraft_category, W_TO<br/>out: minimum W_E [lbf], a LOWER BOUND"]
    end

    subgraph TOOL["WeightsL1 toolbox (static methods)"]
        T1["OEW(obj, W_TO)<br/>fraction times W_TO"]
        T2["compute_We_fraction(obj, W_TO, aircraft_category)"]
        T3["compute_We_roskam(obj, W_TO)"]
        L1["We_fraction_power_law(Kvs, A, C, W_TO)<br/>Raymer 6th ed. Table 3.1"]
        L2["We_roskam(A, B, W_TO)<br/>Roskam Part I Eq. 2.16"]
        L3["lookup_coeffs(aircraft_category)<br/>Raymer 6th ed. Table 3.1"]
        L4["lookup_roskam_coeffs(aircraft_category)<br/>Roskam Part I Table 2.15"]
    end

    J -->|"aircraft_category: jet_fighter"| CTOR
    J -->|"weights: W_payload_fixed = 700,<br/>W_payload_expendable = 4400"| CTOR

    SL -->|"W_TO, argument of the OEW call"| M1
    CTOR -->|"aircraft_category"| M1
    SL -->|"W_TO, argument of the compute_We_fraction call"| M2
    CTOR -->|"aircraft_category"| M2
    SL -->|"W_TO, argument of the compute_We_roskam call"| M3
    CTOR -->|"aircraft_category"| M3

    M1 -->|"OEW: obj, W_TO"| T1
    M2 -->|"compute_We_fraction: obj, W_TO, aircraft_category"| T2
    M3 -->|"compute_We_roskam: obj, W_TO"| T3

    T1 -->|"OEW: obj, W_TO, aircraft_category"| T2
    T2 -->|"compute_We_fraction: aircraft_category"| L3
    T2 -->|"compute_We_fraction: Kvs, A, C, W_TO"| L1
    T3 -->|"compute_We_roskam: aircraft_category"| L4
    T3 -->|"compute_We_roskam: A, B, W_TO"| L2

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 2,3,4,5,6,7,8,9,10,11,12,13,14,15 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    class CTOR ctor
    class M1,M2,M3,T1,T2,T3,L1,L2,L3,L4 func
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `aircraft_category` | `f16a_L1.json`, top-level field | One canonical flag. Selects both the Raymer Table 3.1 row and the Roskam Table 2.15 row, through two separate lookups. |
| `W_TO` | Sizing loop, mutated in place | `NaN` until the loop sets it. A `WeightsBase` abstract property. |
| `W_energy` | Mission analysis, mutated in place | `NaN` until set. Was previously 6296.3, which is Brandt Wt!B6, a live formula `= B3 - B4 - B5 - B12`, so `W_TO` minus payload minus OEW: a back-calculated Brandt OUTPUT. Deleted from the JSON in Phase 3, because CLAUDE.md forbids using an output as an input. |
| `W_payload_expendable` | `.weights.W_payload_expendable` | 4400 lbf, Brandt Wt!B5. |
| `W_payload_fixed` | `.weights.W_payload_fixed` | 700 lbf, Brandt Wt!B4. |
| Both payload values | | INERT. No `WeightsL1`, `WeightsL2` or `WeightsL3` static reads either one. They satisfy the `WeightsBase` closure contract and are waiting for the sizing loop. Setting them changes no computed L1 number. They make the closure identity work out: 31377 - 19980.70 - 6296.30 = 5100 = 700 + 4400. |
| `OEW` at `W_TO` = 31,377 lbf | Computed | Fraction 0.609055, so OEW = 19,110.31 lbf. |
| `compute_We_roskam` at the same `W_TO` | Computed | 15,673.73 lbf, correctly BELOW the Raymer estimate. |
| Ground truth, for context only | | Brandt Wt!B12 = 19,980.70 lbf, so -4.36 percent. Casey's `corrections.xls` = 19,148.08 lbf, so -0.20 percent. Two distinct provenances about 4.3 percent apart. The class header records that an earlier version cited the wrong cell in the wrong workbook. |

## Methods with no upstream call at L1

None. All seven `WeightsL1` statics are reached: the three high-level wrappers
by the class, and the four low-level statics by those wrappers.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/weights/F16WeightsL1.m` |
| Tier 2, abstract | `src/disciplines/weights/WeightsModelL1.m` |
| Tier 1, base | `src/base/WeightsBase.m` |
| Toolbox | `src/disciplines/weights/WeightsL1.m` |
| Input JSON | `examples/F16A/inputs/f16a_L1.json` |

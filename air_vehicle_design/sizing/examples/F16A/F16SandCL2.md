# F16SandCL2

F-16A Block 10/15 Level-2 stability & control student class
(`classdef F16SandCL2 < SandCModelL2`). The abstract `x_cg` member is satisfied by a single
delegation into the `SandCL2` static toolbox — no equations are duplicated here. See
`src/disciplines/stability_control/SandCL2.md` for the full equation/citation detail; this file
covers the F-16-specific wiring.

---

## 1. Role

The CG term only — `x_cg = Sum(W_i * x_i) / Sum(W_i)` over the 10 `WeightsL2`-matched component
groups. Per `docs/subplans/10_stability_control.md`'s "DECIDED: F16SandCL2 is limited to the CG term
only" note: `F16GeomL2` exposes NO x-station properties at all, so none of Eqs. 16.4–16.15 are
computable at this fidelity level — this is not a scope choice, it is what the injected geometry
object can supply (there is in fact no geometry object injected at all at this tier).

## 2. Inputs (1) + 1 injected object

| Property | Value | Source |
|---|---|---|
| `component_cg_x_ft` | 10-element vector, `COMPONENT_GROUP_NAMES` order | `f16a_L2.json` `.stability_control.component_x_stations.groups.*.cg_x_ft` — read ONCE at construction (static spec data; an engineering estimate re-aggregated from the legacy `temp_Casey` "Stability&Control" sheet, fidelity-independent between L2/L3 per the JSON's own note) |
| `weights` | injected | `(1,1) F16WeightsL2` (CONCRETE — see §3) |

`front_edge_x_ft` is DELIBERATELY never read: it is always `null` at L2 (`F16GeomL2` has no
x-station properties to cite one from), and this class needs no cross-check field, only `cg_x_ft`,
per the JSON's own `_L2_has_no_front_edge_data` note.

## 3. Judgment call: `weights` typed concretely, not `WeightsBase`/`WeightsModelL2`

Two of the 10 groups this class reads (`strake` → `W_strake`; the struct-field accesses
`W_tail.HT`/`W_tail.VT`) are **not part of any abstract weights contract** — `W_strake` in
particular is an F-16-only LERX term added directly to `F16WeightsL2`, never declared on
`WeightsBase`/`WeightsModelL2`. A `WeightsModelL2` type guard would therefore not actually guarantee
the members this class reads. The `component_x_stations` grouping itself is explicitly built "from
THIS framework's own WeightsL2/WeightsL3 groups" (`docs/subplans/10_stability_control.md`
"Component-x-location buildup") — i.e. tied to this exact concrete class's shape, not a generic
weights contract. **Decision**: type `weights` as `(1,1) F16WeightsL2` concretely, matching the
launch instruction's own "Inject F16WeightsL2" wording.

## 4. `group_weight` mapping (matches the JSON's own `weights_property` field name-for-name)

| Group | Weight source | Notes |
|---|---|---|
| `wing` | `W_wings` | |
| `horizontal_tail` | `W_tail.HT` | |
| `vertical_tail` | `W_tail.VT` | |
| `fuselage` | `W_fuselage` | |
| `landing_gear` | `W_landing_gear` | Dependent property, guarded by `F16WeightsL2.requireWTO` — errors if `weights.W_TO` is not yet set |
| `installed_engine` | `W_installed_engine` | |
| `subsystems_lump` | `W_all_else_empty` | guarded by `requireWTO` |
| `strake` | `W_strake` | |
| `payload` | `W_payload_fixed + W_payload_expendable` | plain properties, never guarded |
| `fuel` | `W_energy` | mission-analysis STATE, plain property, reads `NaN` pre-mission — see §5 |

## 5. NaN handling: why `fuel` is graceful and `landing_gear`/`subsystems_lump` are not

`W_energy` is a **plain** property (never a computed/guarded getter) — reading it before mission
analysis sets it simply returns `NaN`, and `SandCL2.weighted_cg`'s ordinary IEEE arithmetic
propagates that `NaN` straight into `x_cg`, with no error. This is the ONE graceful-NaN case
`docs/subplans/10_stability_control.md` asks for.

`W_landing_gear` and `W_all_else_empty`, by contrast, are genuinely `W_TO`-scaled fractions guarded
by `F16WeightsL2.requireWTO` — reading `x_cg` before a candidate `W_TO` exists errors loudly through
THAT existing guard. This is correct and expected (you cannot compute a CG without a candidate gross
weight) and is a DIFFERENT situation from the fuel-NaN case, not something this class works around.

## 6. Constructor

`F16SandCL2(json_path, weights)` — both REQUIRED, no silent default (mirrors `F16GeomL2`/
`F16WeightsL2`'s DI convention — a defaulted injection would silently re-freeze weights data).

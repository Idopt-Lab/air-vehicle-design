# F16PropL1

F-16A Block 10 Level-1 propulsion concrete class (`classdef F16PropL1 < PropulsionModelL1`). Every
abstract method is a single delegation line into the `PropL1` static toolbox; no equations are
duplicated here. Trace each method to its `PropL1` static for the cited equation.

## Constructor
`F16PropL1(json_path)` — **required JSON path** (mirrors `F16GeomL1/L2`; no silent default — a no-arg
call errors `MATLAB:minrhs`). Reads the `.propulsion` block of the unified L1 input JSON
(`f16a_spec_path(1)` → `f16a_L1.json`): `engine_type`, `T_SL`. The same file's
`.geometry`/`.aerodynamics` blocks feed `F16GeomL1`/`F16AeroL1`.

## Property classification (input vs derived)
Inputs-vs-`Dependent` split applied (`examples/F16A/F16GeomL2.m` is the reference). The inputs are
set once from the JSON `.propulsion` block by the constructor (an optimizer may mutate them in
place); `T_SL_wet` is the one derived quantity.

**Inputs** (genuine mutable spec data, read from the JSON `.propulsion` block):
| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | Selects the `PropL1` lapse-exponent and TSFC-table rows (F100-PW-200 class). |
| `T_SL` | 23770 | lbf | AB (max) SLS thrust; `PropulsionBase` contract property. [Brandt Engn!T_AB_SLS; Main D29; T.O. 1F-16A-1 §I] |

**Derived** (`Dependent`, recomputed live on read):
| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `T_SL_wet` | 23770 | lbf | ≡ `T_SL` (AB). **No longer a JSON input** (Phase 3, 2026-07-25): it was a self-documented alias, i.e. the same number keyed twice with nothing keeping the copies in sync. [Brandt Engn!T_AB_SLS; Main D29] |

**Contract placeholder (not a real input or derived):**
| Property | Value | Note |
|---|---|---|
| `TSFC` | 0 | Declared abstract on `PropulsionBase`; set to 0 here and never read. TSFC is a per-state output computed live by `get_TSFC(obj, state)` — a stored scalar cannot represent it. It is a contract artifact, not design data; not a frozen property to trust. |

## Methods (delegate to `PropL1`)
| Method | Delegates to | Computes | Citation | Units |
|---|---|---|---|---|
| `thrust_lapse(state)` | `PropL1.get_thrust_lapse` | α = σ^m, σ = ρ/ρ_SL, m from `lookup_lapse_exponent(engine_type)` | [Martins AE481 metabook Eq. 10.9] (turbofan m = 0.6; turbojet m = 1.0 per Eq. 10.7); ρ_SL = 0.002377 slug/ft³ [Mattingly App. B] | α dimensionless |
| `get_thrust_lapse(state)` | `PropL1.get_thrust_lapse` | same as `thrust_lapse` (the `PropulsionModelL1` abstract method this class implements) | [Martins metabook Eq. 10.9] | α dimensionless |
| `get_TSFC(state)` | `PropL1.get_TSFC` | categorical TSFC: M < 0.4 → loiter 0.70, M ≥ 0.4 → cruise 0.80 | [Raymer 6th ed. Table 3.3, low-bypass turbofan] | 1/hr |
| `lookup_TSFC(state)` | `PropL1.get_TSFC` | same as `get_TSFC` | [Raymer 6th ed. Table 3.3] | 1/hr |

Notes on the `PropL1` statics these reach:
- `PropL1.lookup_lapse_exponent`: m = 1.0 for `turbojet`/`turbojet_AB`/`turboprop` [Martins Eq. 10.7];
  m = 0.6 for the `*_turbofan*` rows [Martins Eq. 10.9]. For the F-16 (`low_bypass_turbofan_AB`) →
  m = 0.6.
- The m = 0.6 turbofan exponent value traces to the Martins Ch. 4 density-lapse approximation
  (`T ≈ (ρ/ρ_SL)^0.6 · T_SLS`); Eq. 10.9 itself states the general `T = T0·(ρ/ρ0)^m` form. Both are
  in the same source; cite Eq. 10.9.
- `PropL1.get_TSFC` M-threshold (0.4) is an L1 approximation — the mission segment type is not carried
  on `AircraftState`.

## Citation resolution (user decision 2026-07-24 — applied in Step 1c)
The α = σ^m formula was previously cited three inconsistent ways across the repo (Martins Eq. 10.9 in
the toolbox/this class vs. "Raymer 6th §5.4" in `PropulsionModelL1.m`/`TestPropL1.m` vs. "Raymer Ch 3"
in the subplan). **Resolved: cite Martins metabook Eq. 10.9** (verified in
`temp_AI/docs/disciplines/reference_extracts/metabook_data.md`; no Raymer §5.4 extract exists in the
repo). As-built: the `.m` files (`PropulsionModelL1.m`, `PropL1.m`, `TestPropL1.m`) and the subplan
now all cite Martins Eq. 10.9/10.7. See `VnV/BrandtF16A/todo.md` 2026-07-24 entry 1 (resolved).

## Deviations / limitations
- L1 has **no mil/AB power split** and **no Mach correction** — α depends on density only. At SLS
  (σ = 1) α = 1.0 for any Mach.
- At 36 kft, M = 0.87: σ ≈ 0.297 → α = σ^0.6 ≈ 0.484, vs. Brandt ≈ 0.34 (Consts sheet). The σ^m law
  is a rough turbofan approximation; Mattingly L2 (Eq. 2.54) is the higher-fidelity model.
- Afterburner operation is not modelled at L1 (the `_AB` engine-type suffix does not change the
  Raymer Table 3.3 cruise/loiter TSFC).

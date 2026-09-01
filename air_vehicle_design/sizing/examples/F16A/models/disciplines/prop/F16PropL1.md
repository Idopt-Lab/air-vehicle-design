# F16PropL1

F-16A Block 10/15 Level-1 propulsion. `classdef F16PropL1 < PropulsionModelL1`; every abstract
method is a one-line delegation into the `PropL1` static toolbox.

**L1 is the simplest usable engine model:** a density-ratio thrust lapse and a two-value TSFC table.
No afterburner distinction, no Mach term in the lapse, no supersonic value.

---

## 1. Constructor

```matlab
p1 = F16PropL1(f16a_spec_path(1));
```

`F16PropL1(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.propulsion` block of `f16a_L1.json`; the same file's `.geometry` / `.aerodynamics` blocks
feed `F16GeomL1` / `F16AeroL1`.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | Selects the `PropL1` TSFC-table row and the lapse exponent `m` [F100-PW-200; T.O. 1F-16A-1 §I] |
| `T_SL` | 23770 | lbf | AB (max) SLS thrust; the `PropulsionBase` contract property [Brandt `Main!D29`; T.O. §I] |

## 3. Derived (`Dependent`)

| Property | Value | Note |
|---|---|---|
| `T_SL` | 23770 lbf | ≡ `T_SL_wet`. Kept because call sites read the wet/AB name explicitly. It was a stored input duplicating `T_SL` in both the class and the JSON — two independently-settable copies of one quantity, so an optimizer changing `T_SL` left `T_SL_wet` stale. They can no longer diverge |

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `F16PropL1` (constructor) | input json path | F16 Propulsion object |
| `get.T_SL_wet` (getter) | design object | T_SL (static sea-level thrust) |
| `lookup_TSFC` | design object, aircraft state | thrust-specific fuel consumption [1/hr] | 
| `get_thrust_lapse_categorical` | design object, aircraft state, thrust rating (AB/no-AB) | alpha |

`rating` is validated against `["mil","AB"]`, but L1 has no mil/AB split, so both return the same
`σ^m`.

`ρ_SL` = 0.002377 slug/ft³ [Mattingly App. B].

### As-built values

| Quantity | Value |
|---|---|
| `get_thrust_lapse_categorical(36 kft, M 0.87, "AB")` | 0.48374118 |
| `get_TSFC(36 kft, M 0.87)` | 0.80 1/hr |

---

## 5. To-dos

| Item | Status |
|---|---|
| The M = 0.4 TSFC threshold is an L1 approximation — the segment type (cruise vs loiter) is not carried on `AircraftState`, so Mach stands in for it | accepted L1 limitation |

L1 propulsion carries no deliberately-red `testTODO_` tests.

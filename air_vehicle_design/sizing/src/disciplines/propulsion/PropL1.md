# PropL1

Level-1 propulsion static toolbox. `classdef PropL1`, `methods (Static)` only; called as
`PropL1.method(...)` and never instantiated.

Every static takes scalars or a category string, never a design object and never an `AircraftState`.
The concrete class reads `state.rho` or `state.theta`, chooses the table row, then evaluates the
equation.

**L1 is the simplest usable engine model:** a density-ratio thrust lapse with no Mach term, and a
two-value TSFC table with no afterburner split.

---

## 1. Constants

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `RHO_SL` | 0.002377 | slug/ft³ | ISA sea-level density [Mattingly App. B]. `Constant`, private; used only by `sigma_lapse` |

---

## 2. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `sigma_lapse` | density [slug/ft³], lapse exponent | alpha | Martins AE481 metabook Eq. 10.9 |
| `lookup_lapse_exponent` | engine type | lapse exponent | Martins AE481 metabook Eq. 10.7 (turbojet), Eq. 10.9 (turbofan) |
| `lookup_TSFC_table` | engine type | struct with `.cruise` and `.loiter` [1/hr] | Raymer 6th ed. Table 3.3 (jet rows), Table 3.4 (`turboprop`) |
| `tsfc_mattingly_hibpr_raw` | Mach, temperature ratio | thrust-specific fuel consumption [1/hr] | metabook Eq. 10.11 / Mattingly 1996 Eq. 1.36a |

Both lookups error `PropL1:unknownEngineType` on an unlisted type rather than returning a default.

### As-built values

| Quantity | Value |
|---|---|
| `sigma_lapse(ρ at 36 kft, 0.6)` | 0.4837411751 |
| `tsfc_mattingly_hibpr_raw(0.84, θ at 40 kft)` | 0.6746051180 |

---

## 3. Equations

**Thrust lapse** [Martins AE481 metabook Eq. 10.9], exponent by engine type per Eq. 10.7:

$$\alpha = \sigma^{m} \qquad \sigma = \frac{\rho}{\rho_{SL}}$$

Density only, so it cannot distinguish dry from afterburning power, and it degrades at extreme
altitude and supersonic Mach. That is the L1 model, not a defect.

**TSFC** [Raymer 6th ed. Table 3.3] — a two-value table read by the caller's own Mach or segment
gate. `_AB` variants share the dry values; afterburner TSFC is L2 [Mattingly Eq. 3.55].

**High-bypass TSFC** [metabook Eq. 10.11 / Mattingly 1996 Eq. 1.36a] — a Mach- and
altitude-dependent alternative to the table:

$$c_t = (0.4 + 0.45\,M)\sqrt{\theta}$$

---

## 4. Category coverage

| `engine_type` | lapse exponent | cruise [1/hr] | loiter [1/hr] |
|---|---|---|---|
| `turbojet`, `turbojet_AB` | 1.0 | 0.90 | 0.80 |
| `low_bypass_turbofan`, `low_bypass_turbofan_AB` | 0.6 | 0.80 | 0.70 |
| `high_bypass_turbofan` | 0.6 | 0.50 | 0.40 |
| `turboprop` | 1.0 | 0.50 | 0.60 |

`turboprop` warns `PropL1:turbopropIsPowerBasis`: its two numbers are Raymer Table 3.4 `C_bhp`
[lb/hr/bhp], a power-specific quantity, not the thrust-specific 1/hr basis every other row returns.

---

## 5. To-dos

| Item | Status |
|---|---|
| `RHO_SL` is a private constant here; the sea-level atmosphere should be its own class | open, in-code TODO |
| The table holds one cruise and one loiter value per type, so the caller must gate on Mach or segment. Segment type is not carried on `AircraftState` | accepted L1 limitation |

No deliberately-red `testTODO_` tests.

# WeightsBase

Tier-1 abstract enforcer (`classdef (Abstract) WeightsBase < handle`) for every weight-estimation
discipline class. It declares the four sizing-loop weight properties and the single top-level method.
No equations, no coefficients.

---

## 1. Inheritance

```
WeightsBase → WeightsModelLN (abstract) → F16WeightsLN (concrete)
```

Each `WeightsModelLN` enforcer inherits `WeightsBase` **directly**, not `WeightsModelL(N-1)`.

The `WeightsL1` / `WeightsL2` / `WeightsL3` static toolboxes hold the equations and are **not** in
this chain — concrete classes call them as `WeightsLN.method(obj, W_TO)`.

The three levels are different **models**, not refinements of one model: L1 is a statistical
`W_E/W_TO` power law, L2 is surface-density × area plus fractions, L3 is the Raymer §15.3.1 component
build-up. Per-component agreement between levels is not expected.

## 2. Abstract contract

Properties every concrete class must define:

| Property | Meaning |
|---|---|
| `W_TO` | candidate gross takeoff weight, lbf; `NaN` until the sizing loop sets it |
| `W_energy` | total internal fuel / battery weight, lbf; `NaN` until mission analysis sets it |
| `W_payload_fixed` | fixed equipment weight, lbf (includes crew) |
| `W_payload_expendable` | expendable payload (stores) weight, lbf |

Method every concrete class must implement:

| Method | Returns | Invariant |
|---|---|---|
| `OEW(obj, W_TO)` | operating empty weight, lbf | `OEW < W_TO` for all physical designs |

## 3. Concrete utilities

None. Everything a level needs is in its own toolbox.

## 4. Conventions

**Sizing-loop closure:**

```
W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable
```

Sanity check against ground truth at Brandt's converged point — it closes exactly:

```
31377 − 19980.70 − 6296.30 = 5100.00 = 700 + 4400
```

`[Brandt Wt!B3 / B12 / B6 / B4 / B5]`

**`OEW` stays a METHOD at every fidelity level, deliberately.** It takes `W_TO` as an *argument*, so
it recomputes on every call and can never go stale. The inputs-vs-`Dependent` rule (CLAUDE.md,
"Optimization-ready property design") governs *stored* derived state; a method whose result is a pure
function of its arguments is already correct-by-construction.

Two rules follow, and both have been violated before:

1. **Never cache an `OEW` value** on a concrete class.
2. **Every `W_TO`-dependent term inside `OEW` must be evaluated at the PASSED `W_TO`**, not at
   `obj.W_TO`. Confusing the two froze L2's all-else-empty term at `0.17 × 31377` — a Brandt *output*
   used as a calibration input. Guarded now by
   `TestWeightsL2.testOEWScalesWithItsArgumentNotAFrozenWTO`.

**Constructor signatures of the F-16A concretes** — every argument required, no silent default:

```matlab
F16WeightsL1(json_path)                        % no DI at all
F16WeightsL2(json_path, req_path, geom, prop)  % geom = F16GeomL2
F16WeightsL3(json_path, req_path, geom, prop)  % geom = F16GeomL3
```

`json_path` = `f16a_spec_path(N)` → the level's `.weights` block;
`req_path` = `f16a_requirements_path()` → `design_mach` and the cruise condition.

## 5. To-dos

| Item | Status |
|---|---|
| **The closure identity in §4 is not enforced anywhere.** No `WeightsL{1,2,3}` static reads `W_energy`, `W_payload_fixed` or `W_payload_expendable`, so those three properties are currently inert. Correct for now — the sizing loop does not exist — but the contract promises something nothing checks | open until the sizing loop (PLAN.md step 8) lands |

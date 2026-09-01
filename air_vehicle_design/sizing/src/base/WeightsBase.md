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
this chain. At L1 the toolbox takes scalars only, so the concrete class reads its own coefficient
row and passes the numbers: `WeightsLN.method(A, C, W_TO)`. L2 and L3 still have object-taking
statics; those go in their own passes.

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

| Method | Arguments | Outputs |
|---|---|---|
| `get_OEW` | `W_TO` | operating empty weight [lbf]; must satisfy `OEW < W_TO` |

`WeightsModelL1` supplies a concrete `get_OEW` that forwards to its own
`get_OEW_categorical`, so an L1 class writes one method. L2 and L3 classes implement `get_OEW`
directly.

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

**`get_OEW` stays a METHOD at every fidelity level, deliberately.** It takes `W_TO` as an *argument*, so
it recomputes on every call and can never go stale. The inputs-vs-`Dependent` rule (CLAUDE.md,
"Optimization-ready property design") governs *stored* derived state; a method whose result is a pure
function of its arguments is already correct-by-construction.

Two rules follow, and both have been violated before:

1. **Never cache an `OEW` value** on a concrete class.
2. **Every `W_TO`-dependent term inside `get_OEW` must be evaluated at the PASSED `W_TO`**, not at
   `obj.W_TO`. Confusing the two froze L2's all-else-empty term at `0.17 × 31377` — a Brandt *output*
   used as a calibration input. Guarded now by
   `TestWeightsL2.testOEWScalesWithItsArgumentNotAFrozenWTO`.

**Naming.** `WeightsBase` declares `get_OEW`. `WeightsModelL1` adds an abstract
`get_OEW_categorical` plus a concrete `get_OEW` that forwards to it, so an L1 class writes the
categorical form only. `WeightsModelL2` and `WeightsModelL3` declare no bridge, so their concrete
classes implement `get_OEW` directly. Implementers today: `F16WeightsL1`, `Aero481WeightsL1`
(categorical), `F16WeightsL2`, `F16WeightsL3`, `B777WeightsL2` (direct), plus `BrandtWeightAdapter`
and the two sizing-loop test stubs.

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
| **No `WeightsL{1,2,3}` static reads `W_energy`, `W_payload_fixed` or `W_payload_expendable`.** The closure is applied by the sizing loop instead: `SizingLoopL1` sums the two payload properties and hands them to `SizingSteps.togw_update`. So the identity holds in the loop, not in the weights classes, and `W_energy` is written by the loop rather than read by it | open: the contract still promises something no weights class checks |

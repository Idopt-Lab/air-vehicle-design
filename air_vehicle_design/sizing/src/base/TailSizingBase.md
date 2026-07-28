# TailSizingBase

Tier-1 abstract enforcer (`classdef (Abstract) TailSizingBase < handle`) for every tail-sizing
discipline class. It declares the single contract every fidelity level implements. No equations, no
coefficients.

---

## 1. Scope

Sizes **only** `S_ht`/`S_vt` (horizontal/vertical tail **reference areas**) and whatever geometric
parameters that requires (moment arm, volume coefficients). Explicitly **excludes** control-surface
sizing (elevator/rudder/aileron chord × span fractions) — that stays `src/sizing/
ControlSurfaceSizer.m`, a separate discipline untouched by this hierarchy.

## 2. Inheritance

```
TailSizingBase → TailSizingModelLN (abstract) → F16TailLN (concrete)
```

Each `TailSizingModelLN` enforcer inherits `TailSizingBase` **directly**, not `TailSizingModelL(N-1)`.

The `TailL1` / `TailL2` / `TailL3` static toolboxes hold the equations and are **not** in this chain
— concrete classes call them as `TailLN.method(...)`.

## 3. Abstract contract

| Method | Returns | Called by |
|---|---|---|
| `size(obj, S_ref, b, cbar, L_fus)` | `struct('S_ht', S_ht, 'S_vt', S_vt)` | `SizingLoopL2`, every iteration |

Exactly these two fields, at **every** fidelity level — no exposed/wetted-area fields, no injected
geometry object read back out of it (`TailSizing_scribe_plan.md` Sec. 0/5.2, locked decision).

**Signature note.** The abstract declaration above is the WIDEST signature any implementer needs — it
is L1's own signature verbatim, because `GeometryModelL1` has no planform at all (only a
`W_TO`-based `S_wet` regression), so L1's caller must supply `S_ref`/`b`/`cbar`/`L_fus` as raw
scalars. L2/L3 instead take an injected `GeometryModelL2`/`GeometryModelL3` collaborator at
**construction** and implement `size(obj)` with no further arguments. MATLAB does not enforce
matching arity between an abstract declaration and its override — the same idiom already used by
`GeometryBase.get_S_wet(obj, W_TO)`, whose own comment states this explicitly, and which L2/L3
geometry classes already override as `get_S_wet(obj)`.

## 4. Concrete utilities

None. Unlike `AerodynamicsBase`/`GeometryBase`, `TailSizingBase` carries no fidelity-independent
utility methods — the volume-coefficient identity is not shared verbatim across L1/L2 (only the tail
moment-arm rule is, via a cross-toolbox static call from `TailL2` into `TailL1.compute_tail_arm`, not
a `TailSizingBase` method).

## 5. To-dos

None. This file is a contract, not a model.

# How to read a discipline

Each discipline (aerodynamics, geometry, propulsion, weights, tail sizing, …)
uses four files per fidelity level. Learn the four roles once, then you can find
any equation fast.

## The four files (aerodynamics L1 shown)

| Role | File | What it holds |
|---|---|---|
| **Equations** | `src/disciplines/aerodynamics/AeroL1.m` | The actual textbook math, with citations. Static methods, called as `AeroL1.method(...)`. **Open this file first for any number.** |
| Contract (Tier 2) | `src/disciplines/aerodynamics/AeroModelL1.m` | Abstract. Declares the methods a level must provide. No math. |
| Contract (Tier 1) | `src/base/AerodynamicsBase.m` | Abstract. Declares what every level provides + shared utilities. No level-specific math. |
| Aircraft | `examples/F16A/models/disciplines/aero/F16AeroL1.m` | The F-16 spec data. Each method is one line that delegates to the toolbox. |

**Rule: for "where does this number come from", open the `*L{n}.m` toolbox in
`src/disciplines/<discipline>/`.** The `*ModelL{n}.m` and `*Base.m` files are
contracts. Skip them unless you add or change a method.

## Naming decoder ring

| Suffix pattern | Meaning |
|---|---|
| `<Disc>L{n}` (e.g. `AeroL1`, `GeomL2`) | Static equation toolbox. The math. |
| `<Disc>ModelL{n}` (e.g. `AeroModelL1`) | Tier-2 abstract contract. |
| `<Disc>Base` (e.g. `AerodynamicsBase`) | Tier-1 abstract contract + shared utilities. |
| `<Aircraft><Disc>L{n}` (e.g. `F16AeroL1`) | Concrete aircraft class. Spec data + delegation. |

`Base` and `Model` both mean abstract. `Base` is Tier 1 (widest contract);
`Model` is Tier 2 (per-level contract).

## Trace 1 — F-16 CD0 at L1

1. `MasterEquationConstraint.m` calls `obj.aero.drag_polar(state)`.
2. `AerodynamicsBase.m` — `drag_polar` is abstract (contract only).
3. `AeroModelL1.m` — inherits, adds nothing.
4. `F16AeroL1.m` — `drag_polar` delegates to `AeroL1.drag_polar`.
5. `AeroL1.m` — the math: `interp1` over the CD0-vs-Mach curve. **This is the
   number.**

## Trace 2 — F-16 exposed wing area at L2

1. A consumer reads `obj.S_exposed_wing`.
2. `F16GeomL2.m` — the `Dependent` getter `get.S_exposed_wing` delegates to
   `GeomL2.compute_S_exposed_horizontal`.
3. `GeomL2.m` — the math. **This is the number.**

The same quantity can appear as a property (`S_exposed_wing`), a getter, and a
toolbox method. The formula always lives in the toolbox.

## See also

- `docs/PLAN.md` — architecture and plan of record.
- `docs/decision_log.md` — design decisions and change history.
- `docs/<discipline>_parameter_usage.md` — parameter → consumer → citation
  tables.

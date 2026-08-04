# SandCL2

Level-2 stability & control static toolbox (`classdef SandCL2`, `methods (Static)` only). Called as
`SandCL2.method(...)`; never instantiated and not in the inheritance chain. `F16SandCL2` inherits
`SandCModelL2` and delegates here. `F16SandCL3` **also** calls `weighted_cg` directly for its own
`x_cg` (fidelity-collapse rule — the equation is level-agnostic, so it lives here once, not
duplicated on `SandCL3`; the exact cross-toolbox-reuse pattern already used elsewhere in this repo,
e.g. `GeomL3.size_tail` → `GeomL1.size_tail`).

**L2 is the CG term only** — see `StabControlBase.md`/`SandCModelL2`'s own header for why every other
Ch. 16 quantity is L3-ONLY, not a scope choice.

---

## 1. Role

| Layer | Members |
|---|---|
| Level-agnostic pure math | `weighted_cg` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `weighted_cg(weights_vec, x_vec)` | `x_cg` [ft] | No separate Raymer/Roskam equation number — standard weighted-average CG identity; matches `VnV/BrandtF16A/readme_bsc.md`'s "CG closure" formula |

## 3. Equation

$$x_{cg} = \frac{\sum_i W_i x_i}{\sum_i W_i}$$

## 4. NaN handling — deliberate, not an oversight

`weighted_cg`'s `arguments` block validates `weights_vec`/`x_vec` with `mustBeReal` only — **no**
`mustBeNonnegative`/`mustBePositive`. Those validators would *reject* NaN outright (e.g. `NaN >= 0`
is `false`), which would turn the fuel group's pre-mission-analysis `W_energy = NaN` into a thrown
error instead of the documented, graceful NaN propagation
`docs/subplans/10_stability_control.md` requires. Ordinary IEEE arithmetic
(`sum(weights_vec .* x_vec) / sum(weights_vec)`) does the rest with no special-case code.

`weighted_cg` does guard one thing loudly: a length mismatch between `weights_vec` and `x_vec`
(`SandCL2:sizeMismatch`) — that is a caller bug, not a "not yet available" signal, so it errors like
any other programming mistake in this repo.

## 5. Consumers

- `F16SandCL2.x_cg` (Dependent property) — the entire L2 discipline.
- `F16SandCL3.x_cg` (Dependent property) — reuses this SAME static, fed L3's own component
  weights/x-stations (numerically identical `cg_x_ft` values to L2's, by design — only
  `front_edge_x_ft` differs between the two JSON files).

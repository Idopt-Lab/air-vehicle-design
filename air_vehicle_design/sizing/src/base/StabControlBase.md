# StabControlBase

Tier-1 abstract enforcer (`classdef (Abstract) StabControlBase < handle`) for every stability &
control discipline class. Declares the ONE quantity every fidelity level genuinely provides today.
No equations beyond that — the full Raymer 6th ed. Ch. 16 set lives in `SandCModelL3`/`SandCL3`.

---

## 1. Inheritance

```
StabControlBase → SandCModelLN (abstract) → F16SandCLN (concrete)
```

Each `SandCModelLN` enforcer inherits `StabControlBase` **directly** — `SandCModelL3` inherits
`StabControlBase`, NOT `SandCModelL2` (the normal three-tier pattern: each fidelity level satisfies
the Tier-1 contract independently).

`SandCL2`/`SandCL3` are the static toolboxes and are **not** in this chain — concrete classes
delegate to them.

## 2. Why this Base is thinner than every other discipline's

Every other discipline's Base (`AerodynamicsBase.drag_polar`/`get_CLmax`, `WeightsBase.OEW`, ...)
declares a contract common to ALL fidelity levels. Stability & Control cannot do that: per
`docs/subplans/10_stability_control.md`'s "DECIDED (Casey, 2026-08-03): F16SandCL2 is limited to the
CG term only" note, `F16GeomL2` exposes **no x-station properties at all** (no
`x_apex_wing`/`x_le_ht`/`x_le_vt`/`x_inlet`/tail-arm equivalent — only `F16GeomL3` has these), so
every Ch. 16 quantity except the CG buildup genuinely cannot run at L2. The only quantity both tiers
can honestly provide is `x_cg` — so that is the entire Tier-1 contract.

## 3. Abstract contract

| Property | Meaning |
|---|---|
| `x_cg` | Aircraft center-of-gravity x-station [ft]. `x_cg = Sum(W_i * x_i) / Sum(W_i)` — no separate Raymer/Roskam equation number (standard weighted-average CG identity; matches `VnV/BrandtF16A/readme_bsc.md`'s own "CG closure" formula). Computed by the level-agnostic `SandCL2.weighted_cg` static, called by **both** `F16SandCL2` and `F16SandCL3` (the equation itself does not vary with fidelity level, only the component weight/x-station data fed into it does). |

**MUST propagate NaN gracefully, never error**, when a component weight is not yet available — in
particular the `fuel` group's `W_energy`, a mission-analysis STATE that reads NaN until the
mission/sizing loop sets it (see `WeightsBase.m`). Ordinary IEEE arithmetic handles this: reading
`W_energy` is a plain property access (never a computed/guarded getter), so `weighted_cg`'s
`sum(weights_vec .* x_vec) / sum(weights_vec)` naturally returns NaN with no error when any weight is
NaN — no special-case code is needed or present.

## 4. Scope (applies to every SandCModelLN/F16SandCLN)

Longitudinal static stability ONLY, steady level flight — Raymer 6th ed. Ch. 16 Sec. 16.3.
Explicitly OUT of scope: downwash (wherever a full Raymer equation includes a downwash term, the
implementation notes the simplification explicitly, never a silent default), ground effect, takeoff
rotation, velocity (speed) stability, lateral-directional static stability and control, handling
qualities.

## 5. Full L3 contract (for reference — declared on `SandCModelL3`, not here)

See `src/disciplines/stability_control/SandCL3.md` for the complete Eq. 16.8–16.18/16.25 set and
`examples/F16A/models/disciplines/sandc/F16SandCL3.md` for which of those are fully implemented vs. documented citation GAPs
(`CL_w`, `CL_h`, `Cm_cg_trim`).

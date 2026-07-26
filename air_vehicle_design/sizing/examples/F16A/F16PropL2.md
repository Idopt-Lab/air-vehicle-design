# F16PropL2

F-16A Block 10 Level-2 propulsion concrete class (`classdef F16PropL2 < PropulsionModelL2`). Every
abstract method is a single delegation line into the `PropL2` static toolbox (Mattingly analytical
engine model); no equations are duplicated here. Trace each method to its `PropL2` static for the
cited equation.

## Constructor
`F16PropL2(json_path)` — **required JSON path** (mirrors `F16GeomL1/L2`; no silent default — a no-arg
call errors `MATLAB:minrhs`). Reads the `.propulsion` block of the unified L2 input JSON
(`f16a_spec_path(2)` → `f16a_L2.json`): `engine_type`, `T_SL`, `T_SL_mil`, `T_t4_max_F`,
`TSFC_install_factor`, `bypass_ratio`. Sets ONLY the input properties; `TR` and `T_SL_wet` are
produced live by their `Dependent` getters (not frozen in the constructor). The same file's
`.geometry`/`.aerodynamics` blocks feed `F16GeomL2`/`F16AeroL2`.

## Property classification (input vs derived)
Inputs-vs-`Dependent` split applied (`examples/F16A/F16GeomL2.m` is the reference). Inputs are a plain
mutable `properties` block set once from the JSON `.propulsion` block; the derived quantities (`TR`,
`T_SL_wet`) are `properties (Dependent)` getters that recompute live on read (no stored/cached copy).

**Inputs** (genuine mutable engine spec, read from the JSON `.propulsion` block):
| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | Selects the Mattingly TSFC coefficient set via `PropL2.lookup_TSFC_coeffs` (F100-PW-200 class). |
| `T_SL` | 23770 | lbf | AB (max) SLS thrust; `PropulsionBase` contract. [Brandt Engn!T_AB_SLS; Main D29; T.O. 1F-16A-1 §I] |
| `T_SL_mil` | 15000 | lbf | Military (dry) SLS thrust. [Brandt Engn!T_mil_SLS; Main C29; T.O. §I] |
| `T_t4_max_F` | 2566 | °F | Burner-exit total temperature; feeds `get.TR`. [Mattingly Table C.4, F100-PW-100] |
| `TSFC_install_factor` | 1.08 | — | Installed = uninstalled × factor. [Brandt Miss!C25 = Main!C25] |
| `bypass_ratio` | 0.71 | — | F100-PW-200. Feeds Raymer Eq. 10.10 engine weight, which the weights tier calls through propulsion DI. Carries a `_TODO_bypass_ratio` marker: 0.71 is untraceable to an in-repo source. |

**Derived** (`properties (Dependent)` — recomputed live on every read, never stale):
| Property | Value | get-method / citation |
|---|---|---|
| `TR` | 1.0 | `get.TR = PropL2.compute_TR(T_t4_max_F + 459.67)` [Mattingly Eq. D.6]. Recomputes live from the `T_t4_max_F` input on read; read-only (assigning errors `MATLAB:class:noSetMethod`). |
| `T_SL_wet` | 23770 | `get.T_SL_wet = obj.T_SL` — AB (max) SLS thrust. **No longer a JSON input** (Phase 3, 2026-07-25): it was a self-documented alias of `T_SL`, i.e. the same number keyed twice with nothing keeping the copies in sync. [Brandt Engn!T_AB_SLS; Main D29] |

**Accepted degenerate limitation (TR ≡ 1.0):** `TR = T_t4_max / T_t4_SLS`, but only `T_t4_max` is an
input — `T_t4_SLS` is unknown, so `compute_TR` defaults it to `T_t4_max`, making `TR` identically 1.0
for any `T_t4_max_F`. Mutating the input cannot change the value, so the getter cannot demonstrate
value-tracking. This matches Brandt (Engn(s)!S1) and is an accepted known limitation (user
2026-07-24), NOT a bug: genuine optimization visibility would need a separate `T_t4_SLS` input, which
is deliberately not added now. The `Dependent` form is still correct-by-construction (never stale).

**Engine-class TSFC coefficients (NOT properties on this class):** `C1/C2` for mil (0.90/0.30) and AB
(1.60/0.27) are engine-class constants returned by `PropL2.lookup_TSFC_coeffs(engine_type)` inside the
toolbox [Mattingly 2nd ed. Eq. 3.55a/b] — they are no longer declared as class `Constant`s and are not
in the JSON. `PropulsionModelL2` now declares abstract `engine_type` + `TR` (the former abstract-
`Constant` `C1/C2` block was removed).

**Contract placeholder (not a real input or derived):**
| Property | Value | Note |
|---|---|---|
| `TSFC` | 0 | `PropulsionBase` abstract-contract artifact; per-state output computed live by `get_TSFC(obj, state)`, so the stored 0 is never read (same as `F16PropL1.TSFC`). |

## Methods (delegate to `PropL2`)
| Method | Delegates to | Computes | Citation | Units |
|---|---|---|---|---|
| `thrust_lapse(state)` | `PropL2.get_thrust_lapse` → `thrust_lapse_AB(δ₀, θ₀, TR)` | AB/max lapse (used with `T_SL` = AB thrust) | [Mattingly 2nd ed. Eq. 2.54a] | α dimensionless |
| `compute_thrust_lapse_AB(state)` | `PropL2.get_thrust_lapse_AB` | AB lapse | [Mattingly Eq. 2.54a] | α dimensionless |
| `compute_thrust_lapse_mil(state)` | `PropL2.get_thrust_lapse_mil` | mil (dry) lapse | [Mattingly Eq. 2.54b] | α dimensionless |
| `thrust_lapse_mil_on_AB_scale(state)` | `PropL2.get_thrust_lapse_mil_on_AB_scale` | α_mil · (`T_SL_mil`/`T_SL_wet`) — mil lapse renormalized onto the AB `T_SL` axis | [Mattingly Eq. 2.54b + Brandt Consts col AU renormalization convention; see `PropulsionBase.m`] | α dimensionless |
| `get_TSFC(state)` | `PropL2.get_TSFC` | uninstalled mil-power TSFC = (C1_mil + C2_mil·M)·√θ; coeffs from `lookup_TSFC_coeffs(engine_type)`, θ = T_atm/T_SL | [Mattingly Eq. 3.12 + 3.55a] | 1/hr |
| `compute_TSFC_mil(state)` | `PropL2.get_TSFC_mil` | same as `get_TSFC` (uninstalled) | [Mattingly Eq. 3.12 + 3.55a] | 1/hr |
| `compute_TSFC_AB(state)` | `PropL2.get_TSFC_AB` | uninstalled AB TSFC = (C1_AB + C2_AB·M)·√θ; coeffs from `lookup_TSFC_coeffs` | [Mattingly Eq. 3.12 + 3.55b] | 1/hr |
| `compute_TSFC_installed(state)` | `PropL2.get_TSFC_installed` | installed mil TSFC = uninstalled × `TSFC_install_factor` (1.08) | [Mattingly Eq. 3.12 + 3.55a; install factor Brandt Miss!C25] | 1/hr |
| `compute_TSFC_AB_installed(state)` | `PropL2.get_TSFC_AB_installed` | installed AB TSFC = uninstalled AB × `TSFC_install_factor` (1.08) | [Mattingly Eq. 3.12 + 3.55b; install factor Brandt Miss!C25] | 1/hr |

`PropL2.thrust_lapse_AB` (Eq. 2.54a): θ₀ ≤ TR → α = δ₀; θ₀ > TR → α = δ₀·(1 − 3.5·(θ₀−TR)/θ₀).
`PropL2.thrust_lapse_mil` (Eq. 2.54b): θ₀ ≤ TR → α = 0.6·δ₀; θ₀ > TR → α = 0.6·δ₀·(1 − 3.8·(θ₀−TR)/θ₀).
δ₀, θ₀ are the total pressure/temperature ratios carried on `AircraftState` (Mattingly Eq. 2.52).

## Parametric engine sizing (PropL2 toolbox statics — called by tests, not by the sizing loop)
`PropL2` also holds Raymer §10.3.2 rubber-engine statistical sizing, Eqs. 10.4–10.15
[Raymer 6th ed. §10.3.2, book p. 284–285], English units, cruise reference 36,000 ft / M 0.9:
- Nonafterburning (BPR 0–6): `engine_weight_nonAB` (10.4), `engine_length_nonAB` (10.5),
  `engine_diam_nonAB` (10.6), `SFC_max_nonAB` (10.7), `thrust_cruise_nonAB` (10.8),
  `SFC_cruise_nonAB` (10.9).
- Afterburning (BPR 0–<1, M_max < 2.5): `engine_weight_AB` (10.10), `engine_length_AB` (10.11),
  `engine_diam_AB` (10.12), `SFC_max_AB` (10.13), `thrust_cruise_AB` (10.14), `SFC_cruise_AB` (10.15).
These are **unwired outputs** — nothing in the framework reads engine length/diameter back
(`F16GeomL2` sizes the nacelle/duct independently by `D = sqrt(T_AB/1900)`; see
`docs/geometry_parameter_usage.md`).

**Diameter coefficients — RESOLVED (user, 2026-07-24; applied in Step 1c):** `engine_diam_nonAB`
(Eq. 10.6) uses 0.033 and `engine_diam_AB` (Eq. 10.12) uses 0.024. These are **correct for imperial
units** and give the diameter in **ft** (user, Raymer 7th ed. Eq. 10.6 nonAB / Eq. 10.12 AB).
As-built: `PropL2.m` cites Raymer 7th ed. Eq. 10.6/10.12 (imperial, ft); the earlier in-code
`[OCR coefficient verify: book p. 284; metric check suggests ~0.034 / ~0.0256]` note has been removed.
See `VnV/BrandtF16A/todo.md` 2026-07-24 entry 3 (resolved).

## Deviations / limitations
- **Mattingly TSFC is UNINSTALLED by default; the installed path is now wired.** `get_TSFC` /
  `compute_TSFC_mil` / `compute_TSFC_AB` return uninstalled values; `compute_TSFC_installed` /
  `compute_TSFC_AB_installed` multiply by `TSFC_install_factor` (1.08, Brandt Miss!C25). The stored
  Brandt SLS TSFCs (0.70 mil / 2.20 AB) are *already installed* (they include the 1.08 factor) — do
  NOT double-apply the factor when comparing against them. See `docs/propulsion_parameter_usage.md`
  and `VnV/BrandtF16A/todo.md` 2026-07-24 entry 4 (resolved).
- **SLS static TSFC over-prediction:** Mattingly mil at SLS M=0 = (0.90 + 0.30·0)·√1 = 0.90 1/hr
  (uninstalled; installed = 0.90·1.08 = 0.972) vs. Brandt installed 0.70 1/hr — a documented model
  difference, not a bug.
- **Below-TR lapse has no Mach correction.** Mattingly Eq. 2.54 below TR gives α_AB = δ₀ (no Mach
  term); Brandt's Engn(s) model adds (1 − 0.1·√M) for AB / (1 − 0.3·M) for dry. The models are
  closest above TR (both carry the θ correction). Exact agreement with Brandt is explicitly not the
  goal — the Brandt-comparison report is informational, never a unit-test expected value.

## Verified agreement (for record)
`C1_mil/C2_mil = 0.90/0.30` and `C1_AB/C2_AB = 1.60/0.27` match Mattingly Eq. 3.55a/b (low-BPR mixed
turbofan) exactly, per `temp_AI/docs/disciplines/reference_extracts/mattingly_data.md`. Thrust-lapse
Eq. 2.54a/b, TR Eq. D.6, and `T_t4_max = 2566 °F` (Table C.4, F100-PW-100) also match the extract.

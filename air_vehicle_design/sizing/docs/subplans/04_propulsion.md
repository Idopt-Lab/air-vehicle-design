# Subplan 04 — Propulsion

**Status:** Implemented (L1 + L2 only; **no L3**)
**Depends on:** Steps 1–2 (AircraftState, Geometry)
**Blocks:** Steps 6, 7, 8 (constraint analysis, mission, sizing)

---

## Objectives

Implement `PropulsionBase` and two generic fidelity levels (L1, L2 — propulsion has **no L3**) using textbook equations (Raymer, Mattingly). Then implement F-16-specific subclasses that wire in the F100-PW-200 engine type identifier so the general Mattingly correlations are evaluated for the correct engine class. The `thrust_lapse(state)` / `TSFC(state)` methods plus the sea-level thrust property are the only things the sizing loop and mission analysis use.

---

## Files to Create

Three-tier pattern per level `N`: `PropulsionBase` (abstract) ← `PropulsionModelLN` (abstract enforcer) ← `F16PropLN` (concrete), plus a standalone static toolbox `PropLN` holding the equations.

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/PropulsionBase.m` | Abstract base: `thrust_lapse(state)`, `get_TSFC(state)`, sea-level thrust contract |
| `src/disciplines/propulsion/PropulsionModelL1.m` | Abstract L1 enforcer (declares `engine_type`, L1 abstract methods) |
| `src/disciplines/propulsion/PropulsionModelL2.m` | Abstract L2 enforcer |
| `src/disciplines/propulsion/PropL1.m` | Static toolbox — tabulated TSFC (Raymer type table), density-ratio thrust lapse |
| `src/disciplines/propulsion/PropL2.m` | Static toolbox — Mattingly TSFC correlations, Mattingly thrust lapse |

### Layer 2 — F-16 specific (`examples/F16A/`, flat directory)

| File | What it provides |
|------|-----------------|
| `examples/F16A/F16PropL1.m` | Reads `.propulsion` from `f16a_L1.json` (`engine_type`, `T_SL`); `engine_type` selects the Raymer TSFC table + Martins lapse exponent; delegates to `PropL1` statics. `T_SL_wet` is `Dependent` on `T_SL`, not read |
| `examples/F16A/F16PropL2.m` | Reads `.propulsion` from `f16a_L2.json` (`engine_type`, `T_SL`, `T_SL_mil`, `T_t4_max_F`, `TSFC_install_factor`, `bypass_ratio`); `engine_type` selects the Mattingly `C1/C2` coefficient set; delegates to `PropL2` statics. `T_SL_wet` is `Dependent` on `T_SL`, not read |

### Tests

| File | Tests (Tier-1, hermetic — gate `run_all_tests`) |
|------|-------|
| `tests/disciplines/TestPropL1.m` | L1: `σ^m` lapse + Raymer Table 3.3 TSFC correctness, engine-type lookups, error paths, required-JSON-path constructor. 26 tests. |
| `tests/disciplines/TestPropL2.m` | L2: Mattingly Eq. 2.54/3.55 lapse+TSFC correctness, `lookup_TSFC_coeffs`, installed-TSFC (×1.08) ratio, Dependent-`TR` live-recompute + read-only guards, Raymer parametric-sizing anchors, required-JSON-path constructor. 37 tests. |

### Docs & comparison report

| File | Purpose |
|------|---------|
| `examples/F16A/propulsion_brandt_comparison.{m,json,md}` | **Informational** Brandt comparison report (NOT a test, not in `run_all_tests`) — framework vs `f16a_ground_truth.json` `.propulsion`, %Diff + notes. |
| `examples/F16A/F16PropL1.md`, `F16PropL2.md` | Per-file companion docs (method → `PropL*` static → citation; input-vs-Dependent classification). |
| `docs/propulsion_parameter_usage.md` | Quantity → (level, function, citation) + Brandt ground-truth "expected" tables. |

---

## Design Notes

- Inheritance: `F16PropLN < PropulsionModelLN < PropulsionBase < handle` (each `PropulsionModelLN` enforcer inherits `PropulsionBase` directly, not the lower level).
- **Required-JSON-path constructors.** `F16PropL1(json_path)` reads `.propulsion` → `engine_type`, `T_SL`. `F16PropL2(json_path)` reads `.propulsion` → `engine_type`, `T_SL`, `T_SL_mil`, `T_t4_max_F`, `TSFC_install_factor`, `bypass_ratio`. A no-arg call now errors (`MATLAB:minrhs`). Every abstract method is a one-line delegation to the `PropLN` static toolbox; no equations are overridden. (Geometry's own constructors are no longer a parallel: `F16GeomL1` takes a second *requirements* path and `F16GeomL2/L3` take an injected propulsion object.)
- **`T_SL_wet` is NOT a JSON input** (Phase 3, 2026-07-25). It was a self-documented alias of `T_SL`, i.e. the same number keyed twice with nothing keeping the copies in sync. The key was deleted from every `f16a_L*.json` and `T_SL_wet` is now `Dependent` on `T_SL` at both levels.
- **`bypass_ratio` = 0.71** (F100-PW-200) was added at L2 for Raymer Eq. 10.10, which the weights tier calls through propulsion DI to compute engine weight. **Pinned 2026-07-30** to `[Nicolai & Carichner Table 14.3, F100-PW-100]` (the direct predecessor engine); see `_cite_bypass_ratio` in `f16a_L2.json`. Previously carried a `_TODO_bypass_ratio` marker calling this untraceable, which was an oversight -- the source was already in-repo.
- **Inputs-vs-`Dependent` split** applied (`examples/F16A/F16GeomL2.m` is the reference). Inputs are a plain mutable `properties` block set once from the JSON (an optimizer may mutate `T_SL` etc. in place — do not defensively guard). Sea-level thrust (`T_SL = 23,770 lbf`) is a genuine design-variable input.
- `F16PropL2.TR` is a `properties (Dependent)` `get.TR` (= `PropL2.compute_TR(T_t4_max_F+459.67)` [Mattingly Eq. D.6]) — recomputed live on read, never frozen in the constructor. It is degenerate ≡ 1.0 (only `T_t4_max` is an input; `T_t4_SLS` is unknown, so `compute_TR` defaults it to `T_t4_max`). This matches Brandt (Engn(s)!S1) and is an accepted known limitation, not a bug — genuine optimization visibility would require a separate `T_t4_SLS` input (user 2026-07-24; not to be added now).
- **C1/C2 are NOT class Constants and are NOT in the JSON.** They are engine-class constants selected by `engine_type` inside the toolbox: `PropL2.lookup_TSFC_coeffs(engine_type)` → 0.90/0.30/1.60/0.27 for `low_bypass_turbofan_AB` [Mattingly Eq. 3.55a/b]. `PropulsionModelL2` declares abstract `engine_type` + `TR` (the former abstract `Constant C1/C2` block was removed). L1's `engine_type` likewise selects the Raymer Table 3.3 TSFC rows and the Martins lapse exponent.
- **Installed-TSFC path is wired:** `PropL2.get_TSFC_installed` / `get_TSFC_AB_installed` = uninstalled × `TSFC_install_factor` (1.08, Brandt Miss!C25); concrete delegators `compute_TSFC_installed` / `compute_TSFC_AB_installed`. Uninstalled `get_TSFC` / `compute_TSFC_mil` / `compute_TSFC_AB` are kept.
- Engine-diameter coefficients (`PropL2.engine_diam_nonAB/AB`, 0.033/0.024) are **Raymer 7th ed. Eq. 10.6/10.12, imperial** (D in ft) — the earlier OCR/metric-cross-check caveat was removed (user 2026-07-24).
- L1 does not distinguish mil power from afterburner; L2 uses the Mattingly dry/wet correlations.
- Do NOT hardcode specific F100 TSFC numbers from Brandt or flight test data. Use the Mattingly correlation at the F100's engine class.

**What generic toolbox vs. F-16 subclass provides:**

| | PropL1 (generic toolbox) | F16PropL1 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_type` key → Raymer table | wires in `'low_bypass_turbofan_AB'` |
| thrust_lapse | density-ratio formula | same formula — no override |

| | PropL2 (generic toolbox) | F16PropL2 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_type` → `lookup_TSFC_coeffs` → Mattingly formula | supplies `engine_type='low_bypass_turbofan_AB'` |
| thrust_lapse | Mattingly dry/wet formula (Eq. 2.54a/b) | same formula |

---

## Equations & References

All TSFC is in **1/hr** [lbf_fuel/(hr·lbf_thrust)] throughout — there is **no** `/3600` conversion.

### PropL1 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (cruise) | type table; low-BPR mixed turbofan: 0.80 1/hr (M ≥ 0.4) | Raymer 6th ed. Table 3.3 |
| TSFC (loiter) | type table; low-BPR: 0.70 1/hr (M < 0.4) | Raymer 6th ed. Table 3.3 |
| α (thrust lapse) | α = σ^m, σ = ρ/ρ_SL; turbofan m = 0.6 (turbojet m = 1.0, Eq. 10.7) | Martins AE481 metabook Eq. 10.9 |

ρ_SL = 0.002377 slug/ft³ [Mattingly App. B]. The M = 0.4 cruise/loiter threshold is an L1
approximation (segment type is not carried on `AircraftState`).

### PropL2 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (mil, uninstalled) | (0.90 + 0.30·M)·√θ, 1/hr | Mattingly Eq. 3.12 + 3.55a |
| TSFC (AB, uninstalled) | (1.60 + 0.27·M)·√θ, 1/hr | Mattingly Eq. 3.12 + 3.55b |
| TSFC (installed) | uninstalled × 1.08 | install factor Brandt Miss!C25 |
| θ | T_ambient / T_SL_std (static temperature ratio) | standard atmosphere ratio |
| α (AB/max) | θ₀ ≤ TR → δ₀; θ₀ > TR → δ₀·(1 − 3.5·(θ₀−TR)/θ₀) | Mattingly Eq. 2.54a |
| α (mil/dry) | θ₀ ≤ TR → 0.6·δ₀; θ₀ > TR → 0.6·δ₀·(1 − 3.8·(θ₀−TR)/θ₀) | Mattingly Eq. 2.54b |
| TR (throttle ratio) | T_t4_max / T_t4_SLS (→ 1.0; T_t4_SLS unknown) | Mattingly Eq. D.6 |

The `C1/C2` coefficients (0.90/0.30 mil, 1.60/0.27 AB) are engine-class constants selected by
`engine_type` via `PropL2.lookup_TSFC_coeffs` [Mattingly Eq. 3.55a/b]. δ₀, θ₀ = total
pressure/temperature ratios [Mattingly Eq. 2.52], carried on `AircraftState`. The stored Brandt SLS
TSFCs (0.70 mil / 2.20 AB) are already **installed** — do not double-apply the 1.08 factor when
comparing (VnV/BrandtF16A/todo.md 2026-07-24 entry 4).

### PropL2 parametric engine sizing (unwired outputs)
Raymer §10.3.2 rubber-engine statistical sizing, Eqs. 10.4–10.15 [Raymer 6th ed. §10.3.2, p. 284],
English units. Engine-diameter coefficients `engine_diam_nonAB` (Eq. 10.6, coeff 0.033) /
`engine_diam_AB` (Eq. 10.12, coeff 0.024) are **Raymer 7th ed., imperial** (D in ft; user 2026-07-24).
Nothing in the framework reads engine length/diameter back (`F16GeomL2` sizes the nacelle
independently by `D = sqrt(T_AB/1900)`).

---

## Tests

**Two tiers, never blended.** Tier-1 unit tests (`TestPropL1`/`TestPropL2`, gate `run_all_tests`) —
every "expected" is an independent published datum (Raymer Table 3.3, Martins Eq. 10.7/10.9, a
Mattingly worked-example or coefficient, a real engine spec, a T.O. measurement) or hand arithmetic;
**none** reads `f16a_ground_truth.json` or any Brandt engine-MODEL output as an expected value. The
Mattingly-vs-Brandt closeness comparison is the separate informational report
(`propulsion_brandt_comparison.m`), never a unit-test expected value.

### Tier-1 unit tests — representative coverage
| Area | L1 (`TestPropL1`, 26) | L2 (`TestPropL2`, 37) |
|------|-----------------------|-----------------------|
| Constructor contract | no-arg errors `MATLAB:minrhs`; `T_SL` = 23,770 from JSON (spec datum, xref F100-PW-100 23,700 ±1%), `T_SL_wet` `Dependent` on it | no-arg errors; `T_SL`=23,770 (`T_SL_wet` `Dependent`), `T_SL_mil`=15,000 from JSON |
| Lapse (hand/anchor) | `σ^0.6` at ½ρ_SL = 0.659754; α=1 at SLS (Mach-independent); α=0.4828 at 36 kft (σ from ISA) | Eq. 2.54a/b branches hand-computed; Mattingly Part-12 anchors α_mil = 0.4792 / 0.5390 |
| TSFC | Table 3.3 cruise 0.80 / loiter 0.70 transcription; M≥0.4→cruise, M<0.4→loiter | Eq. 3.55 reduces to C1 at SLS; (C1+C2·M)·√θ hand-computed; AB > mil |
| Engine-type lookup | `lookup_lapse_exponent` / `lookup_TSFC_table`; unknown type throws | `lookup_TSFC_coeffs` = 0.90/0.30/1.60/0.27; unknown type throws |
| Installed TSFC | — | `compute_TSFC_installed` / `_AB_installed` = uninstalled × 1.08 (ratio) |
| Dependent `TR` | — | value = 1.0; live-recompute after input mutation; read-only assign errors `MATLAB:class:noSetMethod` |
| Parametric sizing | — | Eq. 10.11 length vs T.O. 15.93 ft (±10%); Eq. 10.13/10.15 SFC hand-computed |
| Inheritance | `isa` PropulsionBase/ModelL1, not ModelL2, handle | `isa` PropulsionBase/ModelL2, not ModelL1, handle |

### Tier-2 comparison report (informational — NOT in `run_all_tests`)
`examples/F16A/propulsion_brandt_comparison.{m,json,md}` reports framework vs Brandt
(`f16a_ground_truth.json` `.propulsion`) with %Diff + notes. Brandt SLS TSFCs 0.70/2.20 are
**installed** (compare the installed rows). Large %Diff is frequently expected — Mattingly (Eq. 2.54
lapse / Eq. 3.55 TSFC) and Brandt's Engn(s) model are different models. Below-TR conditions (Mattingly
α_AB = δ₀, no Mach term) read high vs Brandt's `(1 − 0.1·√M)`; the two agree closest above TR.

---

## Verification

```matlab
runtests('tests/disciplines/TestPropL1.m')   % 26 tests
runtests('tests/disciplines/TestPropL2.m')   % 37 tests
```
All unit tests must pass before Step 5 begins. The comparison report is run separately and is
informational only.

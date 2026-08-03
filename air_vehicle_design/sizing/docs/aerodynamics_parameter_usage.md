# Aerodynamics parameter usage

Which aero quantity is produced at which fidelity level, by which function, under what citation, and
who consumes it. As-built from `src/base/AerodynamicsBase.m`,
`src/disciplines/aerodynamics/AeroL{1,2,3}.m` + `AeroModelL{1,2,3}.m`, and
`examples/F16A/F16AeroL{1,2,3}.m`. Companions: `geometry_parameter_usage.md`,
`propulsion_parameter_usage.md`, `weights_parameter_usage.md`.

**K-convention (A):** `CD = CD0 + K1·CL² + K2·CL` — K1 quadratic/induced, K2 linear/camber. Used by
`AerodynamicsBase.compute_CD`, every `AeroL*` toolbox, the constraint classes, Mattingly Eq. 2.9 and
Brandt `Aero!G17`.

---

## 1. Downstream consumers

| Consumer | Reads | Via |
|---|---|---|
| Constraint classes (`ThrustConstraint`, `TakeoffConstraint`, `LandingConstraint`, `StallConstraint`) | `drag_polar(state) → {CD0, K1, K2}`, `get_CLmax(state)` | `ConstraintAnalysis` / `F16ConstraintSet` |
| Comparison reports | also `get_e_osw`, `get_CL_alpha`, HLD/gear deltas | `fidelity_comparison`, `aerodynamics_brandt_comparison` |

`drag_polar` and `get_CLmax` are the only outputs production code reads. No mission/sizing
orchestrator exists yet (steps 7–8 not started).

---

## 2. Dependency injection

| Direction | Mechanism | What crosses |
|---|---|---|
| geometry → aero | `F16AeroL2(geom, json_path)` / `F16AeroL3(geom, json_path)`; guard `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])` | every geometric quantity, read live through `Dependent` getters returning `obj.geom.<…>` |
| aero → anything | none — aero injects nothing | — |

L1 is geometry-free (`F16AeroL1(json_path)`, no geometry argument). L2/L3 store **no** geometry:
`S_ref`, `S_wet`, `AR`, sweeps, taper, t/c, per-component wetted areas / lengths / diameters, `Amax`
and `L_aircraft` are all live reads. The guard cannot catch an L2-vs-L3 mix-up — both tiers satisfy
the contract, so a wrong tier yields plausible numbers rather than an error.

---

## 3. Quantity → level, member, citation

### CD0 (zero-lift / parasite drag)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_polar` (interp) | `CD0(M)` from the fighter "Current" type-curve | Mattingly: Aircraft Engine Design, 2nd edition Fig. 2.10, Eq. 2.9 |
| L2 subsonic | `AeroL2.get_CD0` | `Cfe·(S_wet/S_ref)` | Raymer Eq. 12.23 |
| L2 supersonic | `AeroL2.get_CD0_supersonic` | `Cf(Re,M)·(S_wet/S_ref)` | Raymer Eq. 12.27 (Cf), 12.23 (form) |
| L3 | `AeroL3.get_CD0_buildup` | `Σ(Cf_eff·FF·Q·S_wet)/S_ref + CD0_misc + CD0_LandP` | Raymer Eq. 12.24 |
| L3, M ≥ 1.2 | `F16AeroL3.compute_CD0_wave` | Sears-Haack + sweep/Mach correction on whole-aircraft `Amax`/`L_aircraft` | Raymer Eq. 12.44 / 12.45 |

`Cfe` = 0.0035 is **not** a JSON input: it is the `aircraft_category`-selected Raymer Table 12.3 row
via `AeroL2.lookup_Cfe`. L1/L2 subsonic CD0 is Mach-flat until the transonic band; L3 adds
compressible `Cf` and, at M ≥ 1.2, wave drag. There is no transonic wave-drag fairing (1.0 < M < 1.2).

### K1 (quadratic / induced)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_polar` (interp) | `K1(M)` from the "Current" type-curve | Mattingly Fig. 2.11, Eq. 2.9 |
| L2/L3 subsonic | `AeroL2.K1_subsonic(e, AR)` | `1/(π·AR·e)` | Raymer Eq. 12.50 |
| L2/L3 supersonic | `AeroL2.K1_supersonic(M, AR, Λ_LE)` | `AR(M²−1)cos Λ_LE/(4·AR·β − 2)` | Raymer Eq. 12.51 |

Eq. 12.51 has a pole at `4·AR·β = 2` (M ≈ 1.014 for AR = 3); it is only evaluated at
M ≥ `MACH_SUPERSONIC_MIN` = 1.05, clear of it.

### K2 (linear / camber)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_K2(design_type)` | `0` for the uncambered fighter type | Mattingly §2.3.1 |
| L2/L3 subsonic | `AeroL2/L3.get_K2` | `CL_minD = CL_alpha(M)·(−deg2rad(α_L0)/2)`, then `−2·K1·CL_minD` | Brandt §4.3 / `Aero!G17` + Raymer Eq. 12.6 |
| L2/L3 supersonic | `AeroL2.K2_value` | `0` for M ≥ 1 | linearized theory |

### CLmax

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 clean | `AeroL1.get_CLmax` → `roskam_CLmax_value(category, "CL_max_clean")` | fighter-column mean | Roskam Vol. I Table 3.1 |
| L1 TO / landing | `get_CLmax_{TO,L}` | clean + Table 3.1 increments | Roskam Table 3.1 / 3.6 |
| L2/L3 clean | `AeroL2.CLmax_clean(cl_max_2D, Λ_c4)` | `0.9·cl_max_2D·cos Λ_c4` | Raymer Eq. 12.15 |
| L2/L3 TO / landing | `get_CLmax_{TO,L}` | clean + HLD Δ | Raymer Table 12.2 + Eq. 12.21 |

**One table at L1.** The TO/landing increments are Table 3.1 *differences*, so the clean base must be
Table 3.1 too. `AeroL1.lookup_CLmax` still implements Table 3.3 (fighter 0.90) as a standalone
documented utility and is unit-tested, but it is deliberately **not** wired into `get_CLmax`.

Eq. 12.15 is a plain swept-wing relation: it ignores the F-16's LEX/strake vortex lift, so L2/L3
underpredict the ~1.6 real whole-aircraft value.

### e (Oswald span efficiency)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L2/L3 official | `AeroL2.oswald_eff(AR, Λ_LE)` | Eq. 12.48 (Λ < 30°) / 12.49 (Λ ≥ 30°) | Raymer Eq. 12.48/12.49 |
| report-only alternate | `AeroL2.oswald_eff_brandt` | `max(0.4, 4.6(1−0.033·AR^0.53)cos(Λ_LE)^0.1 − 3.3)` | Brandt `Aero!G12` |

Only the official value feeds `K1_subsonic`; `get_e_osw` errors on any `e_method` ≠ `"official"`.

### CL_alpha, Cf, form and interference factors

| Quantity | Function | Formula | Citation |
|---|---|---|---|
| CL_alpha | `AeroL2.get_CL_alpha(obj, M)` | finite-wing Datcom slope | Raymer Eq. 12.6 (β 12.7, η 12.8) |
| turbulent Cf | `AeroL2.Cf_turbulent(Re, M)` | `0.455/[(log₁₀Re)^2.58(1+0.144M²)^0.65]` | Raymer Eq. 12.27 |
| laminar Cf | `AeroL3.Cf_laminar(Re)` | `1.328/√Re` | Raymer Eq. 12.26 |
| Reynolds / μ | `AeroL2.compute_Re` / `dyn_viscosity` | `ρVl/μ`, Sutherland | Raymer Eq. 12.25, §12.3.1 |
| cutoff Re | `AeroL3.Re_cutoff_sub` / `_sup` | — | Raymer Eq. 12.28 / 12.29 |
| surface FF | `AeroL3.FF_surface(tc, x_c_max, Λ_m, M)` | `(1+0.6/x_c_max·tc+100·tc⁴)(1.34M^0.18 cos Λ_m^0.28)` | Raymer Eq. 12.30 |
| body FF | `AeroL3.FF_body(L, D)` | `1+5/f^1.5+f/400` (f ≤ 6) / `1+60/f³+f/400` (f > 6) | Raymer Eq. 12.31 |
| interference Q | `Q_comp` = `[1, 1.05, 1.05, 1, 1]` | per component | Raymer Table 12.6 |
| max-thickness station | `x_c_max_comp` = `[0.4, 0.35, 0.35, 0, 0]` | per component | Raymer Table 12.6 |

`AeroL3.get_CL_alpha` delegates to `AeroL2.get_CL_alpha(obj, M)`, so both tiers use the real NACA
64A204 2-D slope rather than a default `η`. The absence of `cl_alpha_2D` is an explicit error, not a
silent fallback. The swept term uses quarter-chord sweep as a documented stand-in for the
max-thickness-line sweep; the optional `(S_exposed/S_ref)·F` fuselage-lift factor defaults to 1.
`CL_alpha` feeds only `K2`, via `CL_minD`.

---

## 4. As-built values

Computed live 2026-07-26 at 36,000 ft / M 0.87 unless noted.

| Quantity | L1 | L2 | L3 | Brandt | Note |
|---|---|---|---|---|---|
| `CD0` | 0.016000 | 0.017112 | 0.016169 | `Aero!G3` 0.01691 | Brandt is a skin-friction basis; his mission CD0 0.0270 folds in form/interference/wave |
| `CD0` @ M 1.6 | 0.028000 | 0.007875 | 0.038816 | `Aero!O9` 0.04610 | L2 has no wave-drag term at all — expected low, not a bug |
| `K1` | 0.180000 | 0.116774 | 0.116774 | — | — |
| `K2` | 0.000000 | −0.005201 | −0.005201 | — | — |
| `CLmax` clean | **1.500000** | 0.914058 | 0.914058 | `Aero!L8` 0.9869 | see below |
| `CLmax` TO / landing | 1.70 / 2.10 | via HLD Δ | via HLD Δ | — | Roskam Table 3.1 |
| `e_osw` | n/a | 0.90861922 | 0.90861922 | 0.9144 (`Aero!G12`) | L1 has no Oswald e |
| `CL_alpha` @ M 0 | n/a | 3.0364651 | 3.0364651 | `Aero!A15` 3.1121 | L2 and L3 agree exactly by construction |
| `Amax` / `L_aircraft` | — | — | 24.703652 / 47.65 | 25.110556 / 48.303947 | live from the injected geometry |
| transonic band | — | 0.95 < M < 1.05 → NaN | same | — | not modeled, by convention |

**The L1↔L2 CLmax step (1.50 → 0.914) is deliberate.** 1.50 is a type-only statistical mean over a
fighter column dominated by straight/moderately-swept wings; 0.914 is geometry-based and correctly
penalizes a thin 40°-swept wing. Different questions at different fidelities, neither calibrated to
the other. It is the largest step in the ladder and reads as a bug without this note.

Wave drag reads `Amax`/`L_aircraft` live from geometry, where `Amax` is tier-specific: L3's
area-ruled 24.7037 ft² is what Eq. 12.44 wants; L2's envelope ellipse 27.4889 ft² is fuselage-only.
With the area-ruled value `CD0_wave` sits −0.54 % from the Brandt-referenced term and `E_WD` = 2.2 is
unchanged — no retune applied.

---

## 5. Open items

| Item | Guard |
|---|---|
| L1 Mattingly Fig. 2.10/2.11 curves are placeholder data (5 AAF worked points, not the digitized figures) | `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` |
| `alpha_L0` unverified | `TestAeroL2.testTODO_AlphaL0Unverified` |
| `cl_max_2D` unverified | `TestAeroL2.testTODO_ClMax2DUnverified` |
| `cl_alpha_2D` unverified | `TestAeroL2.testTODO_ClAlpha2DUnverified` |
| `E_WD` = 2.2 is a tuned calibration knob, not a measured datum | `TestAeroL3.testTODO_EWDCalibrationInput` |
| surface-roughness table number (12.4/12.5, not 12.2) | `TestAeroL3.testTODO_RoughnessTableCitation` |
| HLD/gear deltas implemented and unit-tested but unconsumed — constraints call only `drag_polar` and clean `get_CLmax` | mission/sizing not built |
| Transonic band 0.95 < M < 1.05 not modeled | `drag_polar` returns NaN; `Both_WbyS_TbyW` and `ConstraintAnalysis` both fail loudly on it |

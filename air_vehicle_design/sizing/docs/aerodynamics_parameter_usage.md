# Aerodynamics parameter usage

Which aero quantity is produced at which fidelity level, by which function, under what citation, and
who consumes it. As-built from `src/base/AerodynamicsBase.m`,
`src/disciplines/aerodynamics/AeroL{1,2,3}.m` + `AeroModelL{1,2,3}.m`, and
`examples/F16A/F16AeroL{1,2,3}.m`. Companion: `docs/geometry_parameter_usage.md`.

## Downstream consumers

`drag_polar(state) → {CD0, K1, K2}` and `get_CLmax(state)` are the only discipline outputs anything
reads. Live consumers: the constraint classes (`ThrustConstraint` / `TakeoffConstraint` /
`LandingConstraint` / `StallConstraint`, via `ConstraintAnalysis` / `F16ConstraintSet`) call
`drag_polar` and `get_CLmax`. The `fidelity_comparison` and `*_brandt_comparison` reports also
exercise the auxiliary accessors (`get_e_osw`, `get_CL_alpha`, HLD/gear deltas). No mission/sizing
orchestrator exists yet (steps 7–8 not started).

## K-convention (A)

`CD = CD0 + K1·CL² + K2·CL` — **K1 quadratic/induced**, **K2 linear/camber**. Used by
`AerodynamicsBase.compute_CD`, every `AeroL*` toolbox, the constraint classes, Mattingly Eq. 2.9,
and Brandt Aero!G17.

## Geometry is injected (dependency injection)

L1 is geometry-free. L2/L3 own **no** geometry: every geometric quantity (`S_ref`, `S_wet`, `AR`,
sweeps, taper, t/c, per-component wetted areas / lengths / diameters) is read live from the injected
geometry object via the concrete class's `Dependent` getters. Nothing geometric is stored on an aero
class.

---

## CD0 (zero-lift / parasite drag)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_polar` (interp) | `CD0(M)` from the fighter "Current" type-curve | Mattingly AED 2nd ed. Fig. 2.10, Eq. 2.9 |
| L2 subsonic | `AeroL2.get_CD0` | `Cfe·(S_wet/S_ref)`, Cfe=0.0035 | Raymer Eq. 12.23 / Table 12.3 |
| L2 supersonic | `AeroL2.get_CD0_supersonic` | `Cf(Re,M)·(S_wet/S_ref)` | Raymer Eq. 12.27 (Cf), 12.23 (form) |
| L3 | `AeroL3.get_CD0_buildup` | `Σ(Cf_eff·FF·Q·S_wet)/S_ref + CD0_misc + CD0_LandP` | Raymer Eq. 12.24 |
| L3 (M≥1.2) | `F16AeroL3.compute_CD0_wave` | Sears-Haack + sweep/Mach correction (whole-aircraft `Amax_ft2`/`L_aircraft_ft`) | Raymer Eqs. 12.44/12.45 |

L1/L2 subsonic CD0 has no Mach dependence (flat until the transonic band). L3 adds compressible Cf
and, at M≥1.2, the wave-drag term.

## K1 (quadratic / induced-drag factor)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_polar` (interp) | `K1(M)` from the "Current" type-curve | Mattingly Fig. 2.11, Eq. 2.9 |
| L2/L3 subsonic | `AeroL2.K1_subsonic(e, AR)` | `1/(π·AR·e)` | Raymer Eq. 12.50 |
| L2/L3 supersonic | `AeroL2.K1_supersonic(M, AR, Λ_LE)` | `AR·(M²−1)·cos Λ_LE/(4·AR·β−2)` | Raymer Eq. 12.51 |

The Eq. 12.51 supersonic form has a pole at `4·AR·β=2` (M≈1.014 for AR=3); it is only evaluated at
M ≥ `MACH_SUPERSONIC_MIN`=1.05, clear of the pole (see the transonic-band note).

## K2 (linear / camber term)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.mattingly_K2(design_type)` | `0` for the uncambered fighter type | Mattingly §2.3.1 |
| L2/L3 subsonic | `AeroL2/L3.get_K2` | `CL_minD = CL_alpha(M)·(−deg2rad(α_L0)/2)`, then `−2·K1·CL_minD` | Brandt §4.3 / Aero!G17 + Raymer Eq. 12.6 |
| L2/L3 supersonic | `AeroL2.K2_value` | `0` (M≥1) | linearized theory |

## CLmax (maximum lift coefficient)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `AeroL1.lookup_CLmax(aircraft_type)` | type value (fighter 0.90) | Roskam Vol. I Table 3.3 |
| L2/L3 | `AeroL2.CLmax_clean(cl_max_2D, Λ_c4)` | `0.9·cl_max_2D·cos Λ_c4` | Raymer Eq. 12.15 |
| L1/L2/L3 | `get_CLmax_{TO,L}` | clean + HLD Δ | Roskam Table 3.1/3.6 (L1); Raymer Table 12.2 + Eq. 12.21 (L2/L3) |

`CLmax_clean` (Eq. 12.15) is a plain swept-wing relation — it ignores the F-16's leading-edge-extension
(strake/LEX) vortex lift, so it underpredicts the ~1.6 real whole-aircraft value.

## e (Oswald span efficiency)

| Level | Function | Formula | Citation |
|---|---|---|---|
| L2/L3 (official) | `AeroL2.oswald_eff(AR, Λ_LE)` | Eq. 12.48 (Λ<30°) / 12.49 (Λ≥30°); F-16 → ≈0.908 | Raymer Eq. 12.48/12.49 |
| alternate (report only) | `AeroL2.oswald_eff_brandt` | `max(0.4, 4.6(1−0.033·AR^0.53)cos(Λ_LE)^0.1−3.3)` → 0.9144 | Brandt Aero!G12 |

The official value feeds `K1_subsonic`. The Brandt `e0` alternate is used only by the comparison
report — never what `drag_polar`/`get_e_osw` returns (`get_e_osw` errors on any `e_method` ≠ "official").

## CL_alpha, Cf, FF/Q

| Quantity | Function | Formula | Citation |
|---|---|---|---|
| CL_alpha | `AeroL2.CL_alpha(AR, Λ_c4, M, …)` | finite-wing Datcom slope | Raymer Eq. 12.6 (β 12.7, η 12.8) |
| turbulent Cf | `AeroL2.Cf_turbulent(Re, M)` | `0.455/[(log₁₀Re)^2.58·(1+0.144·M²)^0.65]` | Raymer Eq. 12.27 |
| laminar Cf | `AeroL3.Cf_laminar(Re)` | `1.328/√Re` | Raymer Eq. 12.26 |
| Reynolds / μ | `AeroL2.compute_Re` / `dyn_viscosity` | `ρ·V·l/μ`, Sutherland | Raymer Eq. 12.25, §12.3.1 |
| cutoff Re | `AeroL3.Re_cutoff_sub/sup` | Eq. 12.28 / 12.29 | Raymer Eq. 12.28/12.29 |
| surface FF | `AeroL3.FF_surface(tc, x_c_max, Λ_m, M)` | `(1+0.6/x_c_max·tc+100·tc⁴)(1.34·M^0.18·cos Λ_m^0.28)` | Raymer Eq. 12.30 |
| body FF | `AeroL3.FF_body(L, D)` | `1+5/f^1.5+f/400` (f≤6) / `1+60/f³+f/400` (f>6) | Raymer Eq. 12.31 |
| interference Q | `Q_comp` (per component) | `[1.0,1.05,1.05,1.0,1.0]` | Raymer Table 12.6 |

The `CL_alpha` swept term uses quarter-chord sweep `Λ_c4` as a documented stand-in for the
max-thickness-line sweep, and its optional `(S_exposed/S_ref)·F` fuselage-lift factor defaults to 1.
`CL_alpha` feeds only `K2` (via `CL_minD`).

---

## Current limitations / not-yet-consumed

- **L1 Mattingly curves are placeholder** (5 AAF worked points, not the digitized Fig. 2.10/2.11) —
  guarded red by `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder`.
- **Unverified airfoil / calibration citations**: `alpha_L0`, `cl_max_2D`, `cl_alpha_2D`, `E_WD`, and
  the surface-roughness table number — each guarded by a deliberately-red `testTODO_*`.
- **HLD/gear deltas** (`get_Delta_{e_osw,CD0,CLmax,CDi}_{TO,L}`, `get_CLmax_{TO,L}`, and the flap/slat
  primitives) are implemented and unit-tested but not yet consumed by any constraint/orchestrator —
  the constraint classes call only `drag_polar` and clean `get_CLmax`.
- **Transonic band** (0.95 < M < 1.05) is not modeled — `drag_polar` returns NaN there.
- **Wave drag** reads `Amax_ft2`/`L_aircraft_ft` LIVE from the injected geometry object — both are
  `Dependent` (Phase 2 sub-step 2h, 2026-07-25). They were previously stored L3 *aero* inputs holding
  Brandt's frozen geometry OUTPUTS, so the Sears-Haack term could not respond to a fuselage change at
  all; the `.aerodynamics.wave_drag` JSON block is deleted. What `Amax` means is tier-specific and
  deliberately so: `F16GeomL3` returns the whole-aircraft **area-ruled** buildup (24.7037 ft²) that
  Raymer Eq. 12.44 wants, while `F16GeomL2` returns the fuselage-envelope ellipse (27.4889 ft²),
  which `readme_geom.md` §7 classifies as the low-fidelity form. Injecting an L2 geometry into
  `F16AeroL3` therefore substitutes a fuselage-only quantity for a whole-aircraft one and inflates
  `CD0_wave` ~23%. With the area-ruled value, `CD0_wave` sits −0.54% from the Brandt-referenced term
  with `E_WD` = 2.2 unchanged — no retune. See `F16GeomL3.md` §D.

# Subplan 03 — Aerodynamics

**Status:** Implemented + tested (L1/L2/L3). **Depends on:** Steps 1–2 (AircraftState, Geometry).
**Consumed by:** Step 6 (constraints); Steps 7–8 (mission, sizing) not started.

Authoritative per-file detail lives in the companion docs (`src/base/AerodynamicsBase.md`,
`src/disciplines/aerodynamics/AeroL{1,2,3}.md`, `examples/F16A/F16AeroL{1,2,3}.md`) and the
parameter map `docs/aerodynamics_parameter_usage.md`.

## K-convention (A)

`CD = CD0 + K1·CL² + K2·CL`. **K1 quadratic/induced** (`1/(π·AR·e)`), **K2 linear/camber**
(`−2·K1·CL_minD`). Matches `AerodynamicsBase.compute_CD`, the `AeroL*` toolboxes, the constraint
classes, Mattingly Eq. 2.9, Brandt Aero!G17.

## Base contract

`AerodynamicsBase` (abstract `handle`) enforces exactly two methods:
- `drag_polar(state) → struct(CD0, K1, K2)` (Convention A),
- `get_CLmax(state) → scalar`.

Author-specific K forms stay in the level toolboxes, not the base. Concrete-class derived quantities
are `properties (Dependent)` getters (recompute-on-read), never frozen constructor constants.

## Dependency injection + inputs

Aero owns **no geometry**. L2/L3 constructors receive an injected geometry object and read
`S_wet, S_ref, AR, Λ_LE, Λ_c4, taper, t/c, per-component S_wet/lengths` live via Dependent getters.
L1 is geometry-free. No Brandt outputs are hardcoded as inputs (no `S_wet=1371`, `Cfe=0.005908`,
`e0=0.9086`).

Genuine aero spec inputs come from the `.aerodynamics` block of the **unified per-level JSON**
(`examples/F16A/f16a_L{1,2,3}.json`, resolved via `f16a_spec_path`). Constructors **require** the
path — no silent default; `F16AeroL2/L3` also require the injected geometry object.

## Fidelity ladder

### L1 — aircraft-type only, NO geometry (Mattingly type-curves)
- Polar: Mattingly AED 2nd ed. **Eq. 2.9**; fighters **K2 = 0** (§2.3.1).
- `CD0(M)` from **Fig. 2.10**, `K1(M)` from **Fig. 2.11** — F-16 "Current" curve, interpolated by Mach.
- Clean CLmax type-based: Roskam Vol. I Table 3.1/3.3.

### L2 — geometry-dependent (clean polar + finite-wing lift)
- Subsonic `CD0 = Cfe·(S_wet/S_ref)`, **Cfe = 0.0035** (Raymer Table 12.3 / Eq. 12.23);
  supersonic `Cf = 0.455/[(log₁₀Re)^2.58·(1+0.144·M²)^0.65]` (Eq. 12.27).
- Induced `K1 = 1/(π·AR·e)` (Eq. 12.50); **official e = Raymer Eq. 12.48/12.49** (Brandt `e0`,
  Aero!G12, is a separately-cited alternate used only by the comparison report).
- `K2 = −2·K1·CL_minD` (0 uncambered), Brandt §4.3 / Aero!G17.
- Clean CLmax `= 0.9·cl_max_2D·cos Λ_c4` (Eq. 12.15); `CL_alpha` Eq. 12.6.

### L3 — component build-up
- Per-component `Cf` (lam Eq. 12.26 / turb Eq. 12.27), form factors (surface Eq. 12.30 / body
  Eq. 12.31), interference `Q`, `Σ(Cf·FF·Q·S_wet)/S_ref` (Eq. 12.24), + misc/leakage allowances.
- Supersonic wave drag (M≥1.2): Sears-Haack **Raymer Eqs. 12.44/12.45**, reading whole-aircraft
  `Amax`/`L_aircraft` LIVE from the injected geometry object (Phase 2 sub-step 2h, 2026-07-25 —
  `GeomL3` computes an area-ruled `Amax`; the earlier "geometry exposes no area-ruled Amax" note is
  obsolete). `GeomL2` deliberately keeps the low-fidelity fuselage-envelope form — see
  `examples/F16A/F16GeomL3.md` §D.
- **Transonic (0.95 < M < 1.05) not modeled** — `drag_polar` returns NaN there (avoids the Eq. 12.51
  supersonic-K1 pole near M=1).

## Open items

- **Mattingly Fig. 2.10/2.11 are placeholder** (5 AAF worked points, not the digitized figures) —
  `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` stays red until replaced.
- **Unverified citations** (each guarded by a deliberately-red `testTODO_*`): airfoil `alpha_L0`,
  `cl_max_2D`, `cl_alpha_2D`; the tuned `E_WD`; the surface-roughness table number.
- **HLD/gear deltas** (`get_Delta_*`, `get_CLmax_{TO,L}`) are implemented and unit-tested but not yet
  consumed by any constraint/orchestrator.
- **Airfoil**: standardized on NACA 64A204 (T.O. 1F-16A-1 Fig. 1-2); Brandt's NACA 1404 is used only
  in the Brandt-alternate comparison path.

## Verification

```matlab
runtests('tests/disciplines/TestAeroL1.m'); runtests('tests/disciplines/TestAeroL2.m'); runtests('tests/disciplines/TestAeroL3.m')
```
Green except the labeled `testTODO_*` citation placeholders. The Brandt comparison report
(`examples/F16A/aerodynamics_brandt_comparison.m`) is informational, never used to backfill a unit
test's expected value.

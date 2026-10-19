# Framework findings from the Aero & Wing Design lesson (for approval only)

This file is for the instructor. The build does not ship it to students.

I found these items while I prepared the lesson. **I did not edit `src/` or `examples/`.** The lesson
does not depend on any of these items being fixed.

## TODO (Casey)

The framework cross-check is not part of the student package (user decision, 2026-10-18). It is an
instructor task:

1. Run `crosscheck_framework` (in this folder; needs the Aerospace Toolbox). It runs the 737 baseline
   through the lesson helpers and through the framework statics in `src/`, and shows one row per
   equation with the difference in percent and the known reason.
2. Review findings 1–15 below. For each one, decide: fix `src/`, fix the citation, or no action.
3. Get approval before you change `src/`. Then run `run_all_tests` and run `crosscheck_framework` again.

Result on 2026-10-18: 8 of 11 rows agree within 0.002 %. The 3 rows that do not agree are FF fuselage
(+0.21 %, finding 1), C_Lα (+13.0 %, finding 2) and the Raymer e fit (+80 %, finding 4).

The page numbers are for Raymer, *Aircraft Design*, 6th ed. (2018), checked on page images.
Baseline `run_all_tests` before the lesson work (2026-10-17): 959 tests, 941 pass, and 18 fail. All 18 failures are labelled `testTODO_`.

## Equation errors (change the numbers)

| # | Location | Finding | Book | Effect at the 737 |
|---|---|---|---|---|
| 1 | `src/disciplines/aerodynamics/AeroL3.m:70-83` `FF_body` | For f > 6 it uses 1 + 60/f³ + f/400. That is the **prior-edition** form. For f ≤ 6, 1 + 5/f^1.5 + f/400 has no source. | Eq 12.31, p.422: FF = 0.9 + 5/f^1.5 + f/400. The footnote says the old form is from prior editions. | f ≈ 10.1: the 6e form gives 1.082 and the code gives 1.084, so the difference is small. The citation is wrong and the f ≤ 6 branch has no source. |
| 2 | `src/disciplines/aerodynamics/AeroL2.m:197-214` `CL_alpha` | No cap on (S_exp/S_ref)·F. | p.400: "should probably be suppressed by setting this product to … 0.98". | (S_exp/S_ref)·F ≈ 1.11 → CLα about 13 % high (`crosscheck_framework`). |
| 3 | `AeroL2.m:197-214` `CL_alpha` | Uses Λc/4. Eq 12.6 uses Λ_max,t. | p.400; p.74 footnote calls the difference "trivial". | Small. Document it, or rename the argument. |
| 4 | `AeroL2.m:96-108` `oswald_eff` | Changes abruptly at Λ_LE = 30°. There is no linear interpolation between 0° and 30°. | p.444: "For sweeps between 0 and 30, linearly interpolate between results from the two equations." | At AR 10, e drops from 0.75 to 0.43 when Λ_LE crosses 30°. Note: with interpolation, the 737 gives e ≈ 0.40, which is not realistic. Eq 12.49 is not suitable for a high-AR transport. The lesson uses Eqs 12.56–12.58 instead. |
| 5 | `AeroL2.m:46-71` `lookup_Delta_cl_max_values` | Multiplies the landing value by 0.8. | p.415: the Table 12.2 values are for devices "deployed at the optimum angle for high lift during landing". Only takeoff uses 60–80 %. | The landing ΔCLmax is 20 % low. |
| 6 | `examples/F16A/models/disciplines/aero/F16AeroL2.m:299` and `F16AeroL3.m` `Delta_CDi_flap` | k_f = 0.28 is used unsquared. | Eq 12.62, p.452: ΔC_Di = **k_f²**(ΔC_L,flap)² cos Λc/4. | The F-16 flap ΔC_Di is 3.6 times too large. |
| 7 | `F16AeroL2.m:306`, `F16AeroL3.m:471,480` | Pass c_f/c (0.25) as `cp_c`. | Table 12.2, p.415, uses c′/c, the extended-chord ratio (≥ 1). | Affects Fowler, slotted and slat values. The F-16 plain flap is not affected. |
| 8 | `src/disciplines/weights/WeightsL3.m:45-53` `compute_wing_weight` | Takes `Lambda_LE_deg`. The F-16 caller passes the LE sweep and the exposed area. | pp.576–579: Λ = "wing sweep at 25 % MAC"; S_w = trapezoidal area (p.72: through the fuselage to the centreline). | F-16: cos 40° against cos 32° (Λc/4) gives about 10 % on W_wing. Exposed area (196 ft²) against trapezoidal area (300 ft²) gives about 32 % through S_w^0.649. |

## Citation drift (numbers unchanged)

| # | Location | Cites | Correct |
|---|---|---|---|
| 9 | `AeroL2.m:120` `K1_subsonic`; `AeroL2.m:11`; `AeroL1.m:10,45` | Eq 12.50 | Eq 12.47, p.444. Eq 12.50 is the biplane equation. |
| 10 | `AeroL2.m:13,222` `dyn_viscosity` | Sec. 12.3.1 | Not a viscosity source. Sec 12.3.1 is about lift-curve slope. Cite U.S. Standard Atmosphere 1976 (Sutherland). |
| 11 | `AeroL3.m:20` | Eq 12.41 for wave drag | Eq 12.44/12.45 (Sears–Haack + E_WD). Eq 12.41 is the supersonic CD0 sum. |
| 12 | `src/base/GeometryBase.m:57,67,76` | "Raymer 7th ed." | The numbers match the 6th ed., Eqs 7.6–7.8, p.191–192. |
| 13 | `AeroL2.m:238` `Cf_turbulent` | Eq 12.27 | The equation is correct. Eq 12.27 is blank in this PDF scan (p.420), so N Eqs 2.22 + 2.25 (p.64) are a checkable citation. |
| 14 | `WeightsL3.m:19` | "EVERY Sec. 15.3.1 EXPONENT IS UNVERIFIED" | `docs/reference_extracts/Raymer_Aircraft_Design_6ed/00_README.md` reports Eqs 15.1–15.24 as checked. Make the header agree with the README. |
| 15 | `src/base/GeometryBase.m:94` `convert_sweep` | "no textbook equation number could be pinned" | Gudmundsson, *General Aviation Aircraft Design* (2014), Eq. 9-11, p. 305 (from USAF DATCOM). Checked: the framework agrees with it to 6 digits at c/4, 0.30c and the TE. |

## Correct (checked, no action)

- `AeroL2.CL_alpha` computes η = C_lα/(2π/β) correctly (Eq 12.8, p.400). The extract prints it inverted.
- `F16AeroL3.Delta_CD0_flap` form agrees with Eq 12.61, p.452 (the extract is wrong, not the code).
- `SubsystemsL2.compute_wing_fuel_volume_roskam` τ = tip/root agrees with Roskam Eq 6.3. The class header documents this.

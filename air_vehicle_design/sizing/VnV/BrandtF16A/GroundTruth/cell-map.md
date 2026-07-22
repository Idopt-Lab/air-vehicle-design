# Brandt F-16A XLS Cell Map

Maps every key Excel cell in `Brandt-F16-A.xls` to its MATLAB equivalent in `../`.
Vasquez must reproduce each cell value to within ±1% unless a documented audit exception is called out in the readme.

## Sheet: Main

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Main!B5 | S_ref (ft²) | 300 | `BrandtMain.S_REF` |
| Main!B6 | AR | 3.0 | `BrandtMain.AR` |
| Main!B7 | Wing sweep LE (deg) | 40 | `BrandtMain.SWEEP_LE_DEG` |
| Main!B8 | Wing taper ratio | 0.2275 | `BrandtMain.TAPER` |
| Main!B9 | Airfoil | NACA 1404 | (documented, not computed) |
| Main!B28 | Engine count | 1 | `BrandtMain.N_ENGINES` |
| Main!C475 | Engine nozzle radius (ft) | — | `BrandtMain.R_NOZZLE` |
| Main!Mcrit | Critical Mach | 0.873 | `BrandtMain.MCRIT` |

## Sheet: Geom

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Geom!S_wet | Total wetted area (ft²) | 1,371 | `BrandtGeometry.S_WET` |
| Geom!B19 | Whole-aircraft S_wet total | 1371.09 | `BrandtGeometry.S_wet_total_accurate_ft2` |
| Geom!K21 | Strake chine wetted area term | 40.0 | `BrandtGeometry.strake_chine_wet_ft2` |
| Geom!D23 | High-fidelity fuselage S_wet | 676.329 | `BrandtGeometry.S_wet_fuse_accurate_ft2` |
| Geom!H47 | Amax (ft²) | — | `BrandtGeometry.A_MAX` |
| Geom!H26:H45 | Per-frame cross-section areas | — | `BrandtGeometry.frameAreas()` |
| Geom!F26 | Frame-20 width (ft) | 2.0 | `BrandtGeometry.FRAME20_WIDTH` |

> **Note:** Amax = MAX(H26:H45) − Main!B28 × π × C475² / 5.0  
> Frame-20 uses width F26 = 2.0 ft (not Main row 53 width 7.0 ft)

## Sheet: Aero

### Mach thresholds

| Cell      | Description                          | Value  | MATLAB |
|-----------|--------------------------------------|--------|--------|
| Aero!A12  | Mcrit (LE sweep + t/c formula)       | 0.8727 | `BrandtAerodynamics.Mcrit` |
| Aero!G8   | M_wave = sec(ΛLE)^0.2                | 1.0547 | `BrandtAerodynamics.M_wave` |
| Aero!F9   | M_LE_super = sec(ΛLE)                | 1.3054 | `BrandtAerodynamics.M_LE_super` |

### Span efficiency and lift curve slopes

| Cell      | Description                          | Value   | MATLAB |
|-----------|--------------------------------------|---------|--------|
| Aero!A19  | e_wing (span efficiency, wing)       | 0.7227  | `BrandtAerodynamics.e_wing` |
| Aero!A28  | e_pitch (span efficiency, stabilator)| 0.7227  | `BrandtAerodynamics.e_pitch` |
| Aero!G12  | e0 (Oswald efficiency, Brandt formula)| 0.9144 | `BrandtAerodynamics.e0` |
| Aero!A15  | CLα_wing (per deg, incompressible)   | 0.05431 | `BrandtAerodynamics.CL_alpha_wing` |
| Aero!A23  | CLα_pitch (per deg, incompressible)  | 0.05431 | `BrandtAerodynamics.CL_alpha_pitch` |
| Aero!A40  | Downwash gradient dε/dα              | 0.8175  | `BrandtAerodynamics.downwash` |
| Aero!A32  | CLα_total (wing+strake+tail, /deg)   | 0.06150 | `BrandtAerodynamics.CL_alpha_total` |

### CL0, k2, and subsonic drag

| Cell      | Description                          | Value   | MATLAB |
|-----------|--------------------------------------|---------|--------|
| Aero!G20  | CL0 (CL at zero angle of attack)     | 0.02716 | `BrandtAerodynamics.CL0` |
| Aero!G17  | k2 = −2×k1×CL0 (COMPUTED)           | −0.00630| `BrandtAerodynamics.k2` |
| Aero!G3   | CDmin_sub (Cfe_tab basis)            | 0.01691 | `BrandtAerodynamics.CDmin_sub` |

### CLmax

| Cell      | Description                          | Value  | MATLAB |
|-----------|--------------------------------------|--------|--------|
| Aero!L31  | S_flapped (flapped wing area, ft²)   | 144.745| `BrandtAerodynamics.S_flapped` |
| Aero!H25  | CLmax_clean                          | 0.984  | `BrandtAerodynamics.CLmax_clean` |
| Aero!H27  | CLmax_takeoff                        | 1.276  | `BrandtAerodynamics.CLmax_takeoff` |
| Aero!H29  | CLmax_landing                        | 1.426  | `BrandtAerodynamics.CLmax_landing` |

### Lookup tables and reference data

| Cell         | Description                                | Value        | MATLAB |
|--------------|--------------------------------------------|--------------|--------|
| Aero!J16:K26 | Cfe lookup (aircraft type → Cfe)          | see ../readme_aero.md | `BrandtAerodynamics.inp.aero.Cfe_tab` |
| Aero!M4:Q10  | Actual F-16A aero values (5 Mach points)  | see ../readme_aero.md | reference only |

### Mission tab (Miss)

| Cell            | Description                        | Value    | MATLAB |
|-----------------|------------------------------------|----------|--------|
| Miss!CD0_cruise | Parasite drag (cruise, clean)      | 0.0270   | `BrandtAerodynamics.CD0` |
| Miss!CD0_TO     | Parasite drag (takeoff, gear+flaps)| 0.0520   | `BrandtAerodynamics.CD0_takeoff` |
| Miss!k1         | Induced drag factor (COMPUTED)     | 0.1160   | `BrandtAerodynamics.k1` |
| Miss!k2         | Polar asymmetry (COMPUTED)         | −0.00630 | `BrandtAerodynamics.k2` |
| Miss!LD_max     | Max lift-to-drag ratio             | 8.93     | `BrandtAerodynamics.LD_max` |
| Miss!CL_opt     | CL at LD_max                       | 0.482    | `BrandtAerodynamics.CL_opt` |
| Miss!B3:N3      | Segment Mach schedule              | see ../readme_mission.md | `BrandtMission.segmentMach` |
| Miss!B8:N9      | Segment time/fuel tables           | see ../readme_mission.md | `BrandtMission.time_min`, `BrandtMission.fuel_lb` |
| Miss!O6:O9      | Landing distance / totals          | see ../readme_mission.md | `BrandtMission.landing_dist_ft`, `total_time_min`, `total_fuel_lb` |

> **Drag polar:** `CD = CD0 + k1·CL² + k2·CL` (Brandt quadratic form, FR-004)  
> **LD_max formula:** `0.5 / sqrt(CD0 × k1)` (Brandt simplified, ignores k2)  
> **k2 and e0 are computed** — not read from JSON. See Aero!G17, G12.

## Sheet: Wt

### Inputs

| Cell | Description | Value | MATLAB / JSON |
|------|-------------|-------|---------------|
| Wt!B3 | Takeoff gross weight (lb) | 31377 | `run(W_TO_lb)` — input to `run()` |
| Wt!B4 | Permanent payload (lb) | 700 | `inp.weight.perm_payload_lb` |
| Wt!B5 | Expendable payload (lb) | 4400 | `inp.weight.exp_payload_lb` |
| Main!Q27 | n_ult (design load factor) | 9 | `inp.weight.n_design_load` |
| Main!O27 | Weight scale (%) | 100 | `inp.weight.weight_scale_pct` |

### Structural components (Wt C9:H9)

| Cell | Description | Value (lb) | MATLAB |
|------|-------------|-----------|--------|
| Wt!C9 | Wing structure | 1785.95 | `BrandtWeight.W_wing_lb` |
| Wt!D9 | Fuselage structure | 3652.11 | `BrandtWeight.W_fuse_lb` |
| Wt!E9 | Pitch control (stabilator) | 648.00 | `BrandtWeight.W_pitch_lb` |
| Wt!F9 | Vertical tail | 360.00 | `BrandtWeight.W_vert_lb` |
| Wt!G9 | Nacelles | 186.82 | `BrandtWeight.W_nacelles_lb` |
| Wt!H9 | Strakes | 90.00 | `BrandtWeight.W_strakes_lb` |
| Wt!B9 | Structural subtotal | 6722.87 | `BrandtWeight.W_structure_lb` |

### Engine and systems (Wt B11, B22:B31)

| Cell | Description | Value (lb) | MATLAB |
|------|-------------|-----------|--------|
| Wt!B11/B22 | Engine (0.199 × T_sl_AB) | 4730.23 | `BrandtWeight.W_engine_lb` |
| Wt!B23 | Landing gear (0.034 × W_TO) | 1066.82 | `BrandtWeight.W_gear_lb` |
| Wt!B24 | Inlet duct (3.9 × W_nac) | 728.60 | `BrandtWeight.W_inlet_duct_lb` |
| Wt!B25 | Controls (two-term formula) | 472.44 | `BrandtWeight.W_ctrl_lb` |
| Wt!B26 | Electrical (0.017 × W_TO) | 533.41 | `BrandtWeight.W_elec_lb` |
| Wt!B27 | Hydraulics (0.0117 × W_TO) | 367.11 | `BrandtWeight.W_hyd_lb` |
| Wt!B28 | ECS (0.0115 × W_TO) | 360.84 | `BrandtWeight.W_ECS_lb` |
| Wt!B29 | Other structure (0.30 × W_struct) | 2016.86 | `BrandtWeight.W_other_lb` |
| Wt!B30 | Avionics (0.081 × W_TO) | 2541.54 | `BrandtWeight.W_avionics_lb` |
| Wt!B31 | Armament (0.10 × exp_payload) | 440.00 | `BrandtWeight.W_armament_lb` |

### Summary (Wt B10, B12, B6)

| Cell | Description | Value (lb) | MATLAB |
|------|-------------|-----------|--------|
| Wt!B10 | Airframe (struct + systems, no engine) | 15250.47 | `BrandtWeight.W_airframe_lb` |
| Wt!B12 | OEW = airframe + engine | 19980.70 | `BrandtWeight.W_empty_lb` |
| Wt!B6 | Fuel = W_TO − payload − OEW | 6296.30 | `BrandtWeight.W_fuel_lb` |

> **Weight factors (Wt row 7):** wing=6.75, fuse=5.0, pitch=6.0, vert=6.0, nac=4.5, strake=4.5 (all lb/ft²)
> **Controls formula (Wt B25):** `0.012 × W_TO + (S_LE_flap / S_wing) × 6.75 × 200`
> **Nacelle area (Geom!B4):** half-buried model; uses π (MATLAB) vs 3.1516 (Excel) → ~0.37% error
> See `../readme_wt.md` for full formula derivations and discrepancy analysis.

## Sheet: Engn(s)

### SLS parameters

| Cell           | Description             | Value  | MATLAB                        |
|----------------|-------------------------|--------|-------------------------------|
| Engn!T_mil_SLS | Dry (mil) thrust SLS    | 15,000 | `BrandtEngine.T_sl_dry`       |
| Engn!T_AB_SLS  | AB thrust SLS           | 23,770 | `BrandtEngine.T_sl_AB`        |
| Engn!TSFC_mil  | Dry TSFC (SLS, M=0)     | 0.70   | `BrandtEngine.TSFC_sl_dry`    |
| Engn!TSFC_AB   | AB TSFC (ref, M=0.4)    | 2.20   | `BrandtEngine.TSFC_sl_AB`     |
| Engn!S1        | Throttle ratio TR        | 1.0    | `BrandtEngine.TR`             |

### Thrust equations (Engn(s) rows 4–7)

Thrust and TSFC are functions of altitude and Mach via standard atmosphere ratios θ, θ₀, δ, δ₀.
See `../readme_prop.md` for the full equation listing.

| Quantity         | Method signature                          | Returns        |
|------------------|-------------------------------------------|----------------|
| Dry thrust+TSFC  | `eng.thrust_dry(altitude_ft, mach)`       | `[T_lbf, tsfc_1_per_hr]` |
| AB thrust+TSFC   | `eng.thrust_AB(altitude_ft, mach)`        | `[T_lbf, tsfc_1_per_hr]` |
| Atm ratios       | `BrandtEngine.atmosphereRatios(alt_ft, M)`| `[theta, theta0, delta, delta0]` |

### Nacelle geometry (computed in BrandtGeometry)

| Cell       | Description          | Value  | MATLAB                        |
|------------|----------------------|--------|-------------------------------|
| Engn!D_nac | Nacelle diameter (ft)| 3.537  | `BrandtGeometry.D_engine_ft`  |
| Engn!L_nac | Nacelle length (ft)  | 15.917 | `BrandtGeometry.L_engine_ft`  |

> Nacelle sizing formula (AB aircraft): `D = sqrt(T_sl_AB / 1900)`, `L = 4.5 × D`

### Engine weight (BrandtWeight)

| Cell        | Description          | Value     | MATLAB                  |
|-------------|----------------------|-----------|-------------------------|
| Wt!W_eng    | Engine weight (lb)   | 4730.23   | `BrandtWeight.W_engine` |

> Weight formula (AB aircraft): `W_engine = 0.199 × T_sl_AB`

> **Installed TSFC:** the stored values (0.70, 2.20 hr⁻¹) already include the 1.08× correction factor.

## Sheet: Consts

### Constraint Conditions Table (rows 22–30)

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Consts!B23 | β for performance constraints | 0.89966696 | `inp.constraints.beta_perf` |
| Consts!C23 | n = load factor (max_mach) | 1.0 | `inp.constraints.conditions.max_mach.n` |
| Consts!D23 | Alt [ft] (max_mach) | 36000 | `inp.constraints.conditions.max_mach.alt_ft` |
| Consts!E23 | Mach (max_mach) | 1.60 | `inp.constraints.conditions.max_mach.mach` |
| Consts!F23 | Ps [ft/s] (max_mach) | 0 | `inp.constraints.conditions.max_mach.Ps_fps` |
| Consts!H23 | CDx (max_mach) | 0.0 | `inp.constraints.conditions.max_mach.CDx` |
| Consts!AM23 | CD0 + CDx (Aero-tab basis) | 0.016996 | `aero.run(M).CD0 + CDx` |
| Consts!AN23 | K1 | 0.1160 | `aero.run(M).K1` |
| Consts!AQ23 | V = M×a [ft/s] | — | `cond.mach × a_fps` via `atmosisa` |
| Consts!AR23 | q = ½ρV² [psf] | — | `0.5 × rho × V²` via `atmosisa` |
| Consts!AU23 | α = thrust lapse | — | `eng.run(alt, M, pct_AB/100).alpha_AB_ref` |
| Consts!K23 | T/W at W/S=48 (max_mach) | 1.2228 | `BrandtConstraintAnalysis.max_mach(48)` |
| Consts!K24 | T/W at W/S=48 (cruise) | 0.6247 | `BrandtConstraintAnalysis.cruise(48)` |
| Consts!K25 | T/W at W/S=48 (max_alt) | 0.4732 | `BrandtConstraintAnalysis.max_alt(48)` |
| Consts!K26 | T/W at W/S=48 (combat_turn_sub) | 0.5274 | `BrandtConstraintAnalysis.combat_turn_sub(48)` |
| Consts!K27 | T/W at W/S=48 (combat_turn_sup) | — | `BrandtConstraintAnalysis.combat_turn_sup(48)` |
| Consts!K28 | T/W at W/S=48 (ps_500) | 0.8888 | `BrandtConstraintAnalysis.ps_500(48)` |

### Takeoff Constraint (row 32)

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Consts!D32 | Alt [ft] | 0 | `inp.constraints.takeoff.alt_ft` |
| Consts!AT32 | Mach at liftoff | 0.2 | `inp.constraints.takeoff.mach_liftoff` |
| Consts!H32 | CDx_TO | 0.035 | `inp.constraints.takeoff.CDx` |
| Consts!G32 | S_TO [ft] | 4000 | `inp.constraints.takeoff.S_TO_ft` |
| Consts!K32 | T/W at W/S=48 | 0.2438 | `BrandtConstraintAnalysis.takeoff(48)` |

### Landing Constraint (row 33)

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Consts!H33 | CDx_land | 0.045 | `inp.constraints.landing.CDx` |
| Consts!E33 | S_land [ft] | 4000 | `inp.constraints.landing.S_land_ft` |
| Consts!E33 (μ col) | μ_brake | 0.5 | `inp.mission.mu_braking` |
| Consts!K33 | W/S_max [psf] | 138.4794 | `BrandtConstraintAnalysis.landing()` |

> **Master Equation (Consts!K23 family):**
> `T/W = (β/α) × [q·CD0/(β·W/S) + K1·n²·β·W/S/q + Ps/V]`
> No K2 term — Brandt uses simplified parabolic polar for constraint analysis.
> CD0 uses Aero-tab CDmin_sub basis (≈0.017), NOT Miss-tab Cfe_eff basis (0.027).
> See `../readme_consts.md` for full derivation.

## Sheet: Miss

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Miss!CD0_cruise | Clean CD0 | 0.0270 | `BrandtMission.CD0_CRUISE` |
| Miss!CD0_TO | Takeoff CD0 | 0.0520 | `BrandtMission.CD0_TAKEOFF` |
| Miss!k1 | Drag polar k1 | 0.1160 | `BrandtMission.K1` |
| Miss!k2 | Drag polar k2 | −0.00630 | `BrandtMission.K2` |
| Miss!LD_max | Max L/D | 8.93 | `BrandtMission.LD_MAX` |
| Miss!CL_opt | Optimal CL | 0.482 | `BrandtMission.CL_OPT` |

> **Mission segments:** Takeoff (CDx=0.035) → Accel → Climb → Cruise 190.8 nm → Patrol → Dash 50 nm → Patrol (CDx=0.010 each)

## Sheet: Size&Opt

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Size!TOGW | Sized TOGW (lb) | 29,657 | `BrandtSizing.TOGW` |
| Size!W_S | Wing loading (psf) | 104.59 | `BrandtSizing.W_S` |
| Size!T_W | Thrust loading | 0.7576 | `BrandtSizing.T_W` |
| Size!W_fuel | Design fuel weight (lb) | 5,671 | `BrandtSizing.W_FUEL` |

---

*This file must be updated whenever a new cell is referenced in `../`.*  
*Maintained by: Dallas*

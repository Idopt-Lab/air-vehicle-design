# Brandt F-16A XLS Cell Map

Maps every key Excel cell in `Brandt-F16-A.xls` to its MATLAB equivalent in `src/level_brandt/`.
Vasquez must reproduce each cell value to within ±1%.

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
| Geom!H47 | Amax (ft²) | — | `BrandtGeometry.A_MAX` |
| Geom!H26:H45 | Per-frame cross-section areas | — | `BrandtGeometry.frameAreas()` |
| Geom!F26 | Frame-20 width (ft) | 2.0 | `BrandtGeometry.FRAME20_WIDTH` |

> **Note:** Amax = MAX(H26:H45) − Main!B28 × π × C475² / 5.0  
> Frame-20 uses width F26 = 2.0 ft (not Main row 53 width 7.0 ft)

## Sheet: Wt

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Wt!OEW | Operating empty weight (lb) | 19,981 | `BrandtWeights.OEW` |
| Wt!W_wing | Wing structural weight (lb) | — | `BrandtWeights.W_WING` |
| Wt!W_fuse | Fuselage structural weight (lb) | — | `BrandtWeights.W_FUSE` |
| Wt!W_pitch | Pitch control surface weight (lb) | — | `BrandtWeights.W_PITCH` |
| Wt!W_vert | Vertical surface weight (lb) | — | `BrandtWeights.W_VERT` |

> **Plate-area weight factors:** wing=6.75 lb/ft², fuse=5.0 lb/ft², pitch ctrl=6.0 lb/ft², vert surf=6.0 lb/ft²

## Sheet: Engn(s)

| Cell | Description | Value | MATLAB |
|------|-------------|-------|--------|
| Engn!T_mil_SLS | Mil thrust SLS (lb) | 15,000 | `BrandtEngine.T_MIL_SLS` |
| Engn!T_AB_SLS | AB thrust SLS (lb) | 23,770 | `BrandtEngine.T_AB_SLS` |
| Engn!TSFC_mil | Mil TSFC (hr⁻¹) | 0.70 | `BrandtEngine.TSFC_MIL` |
| Engn!TSFC_AB | AB TSFC (hr⁻¹) | 2.20 | `BrandtEngine.TSFC_AB` |
| Engn!alpha_dry | α dry, 40k ft M=0.87 | 0.1417 | `BrandtEngine.thrustLapseMil(40000, 0.87)` |
| Engn!alpha_AB | α AB, 40k ft M=0.87 | 0.2755 | `BrandtEngine.thrustLapseAB(40000, 0.87)` |

> **Installed TSFC correction:** multiply all Mattingly values by 1.08

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

*This file must be updated whenever a new cell is referenced in `src/level_brandt/`.*  
*Maintained by: Dallas*

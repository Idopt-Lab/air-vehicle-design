# Gorman — History

Propulsion Specialist — owns thrust_lapse and TSFC across Level I/II/III and Level-Brandt. Installed TSFC = uninstalled × 1.08. T0 property is settable by sizing loop.

## Project Context

**Project:** AOE 4065 Air Vehicle Design (Idopt-Lab/air-vehicle-design)
**User:** Darshan Sarojini
**Language:** MATLAB (all source code)
**Ground truth:** `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`
**Key docs:** `ai-workflows/claude/CLAUDE.md`, `ai-workflows/Fidelity-Levels.md`, `ai-workflows/discipline-interfaces.md`
**Joined:** 2026-05-24

## Learnings

### 2026-05-24 to 2026-06-XX — BrandtEngine + TSFC in mission context

#### TSFC Averaging in Mission
- BrandtEngine provides `tsfc_at(alt_ft, mach, pct_AB)` returning TSFC in hr⁻¹.
- In BrandtMission, TSFC is averaged (start+end)/2 ONLY for Ps-based climb segments.
- For all other segments (cruise, egress, loiter, dash, combat), use END-conditions TSFC only.
- Flag: `is_ps_climb = isnan(given_time) && isnan(given_dist)`.

#### Engine Model
- `theta0/delta0` lapse model: T = T_sl × delta0 × f(theta0, Mach, pct_AB)
- TSFC similarly varies with altitude/Mach through theta/delta correction.
- Validated: SLS dry = 15000 lbf, SLS AB = 23770 lbf, TSFC_dry = 0.70 hr⁻¹, TSFC_AB = 2.20 hr⁻¹.
- At 40,000 ft, M=0.87 (cruise): T_dry ≈ 3360 lbf, TSFC_dry ≈ 0.432 hr⁻¹.

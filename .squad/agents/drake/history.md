# Drake — History

Aerodynamics Specialist — owns drag_polar and CLmax across Level I/II/III and Level-Brandt. The Brandt polar is quadratic (k2 ≠ 0). CD0_clean=0.027, CD0_TO=0.052.

## Project Context

**Project:** AOE 4065 Air Vehicle Design (Idopt-Lab/air-vehicle-design)
**User:** Darshan Sarojini
**Language:** MATLAB (all source code)
**Ground truth:** `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`
**Key docs:** `ai-workflows/claude/CLAUDE.md`, `ai-workflows/Fidelity-Levels.md`, `ai-workflows/discipline-interfaces.md`
**Joined:** 2026-05-24

## Learnings

### 2026-05-24 to 2026-06-XX — BrandtAerodynamics CDmin bug fix

#### CDmin_sub Computation
- `CDmin_sub = Cfe_tab × S_wet_total_accurate / S_ref`
- Where `Cfe_tab = 0.0037` (from JSON `aero.Cfe_tab`), `S_ref = 300 ft²`.
- The ACCURATE S_wet (1371.09 ft²) must be used — NOT the simple S_wet (730 ft² fuse + surfaces).
- The aero class stores `CDmin_sub` as an instance property populated in `compute()`.

#### aero_at_mach() Return Values
- Inputs: scalar Mach number.
- Outputs: `[CDo, k1_m, k2_m, CDmin]` where `CDo = CDmin + k1×CL0²` (camber offset).
- Subsonic (M ≤ Mcrit=0.873): `CDmin = CDmin_sub`, `k1_m = k1_sub`, `k2_m = k2_sub`.
- Transonic (Mcrit < M ≤ M_wave): linear interpolation; wave drag builds up.
- Supersonic: Sears-Haack wave drag + supersonic k1 formula.
- At M=0.87 (mission cruise): subsonic branch. CDo = 0.01701 (after S_wet fix).

#### Mach-Dependent Polar (Aero tab A5:E10)
- Six Mach reference points: 0.1, 0.5, Mcrit, M_wave, 1.5, 2.0.
- k1_super formula: `AR×(M²−1)/(4×AR×√(M²−1) − 2) × cos(sweep_LE)`.
- Wave drag factor: `4.5π/S_ref × (Amax/L_ac)² × Ewd × (0.74 + 0.37×cos(sweep))`.

#### Two CD0 Properties (Different Cfe Sources)
- `CDmin_sub = Cfe_tab × S_wet / S_ref` — "tabulated" Cfe = 0.0037 (Aero tab reference; gives CDmin=0.01691).
- `CD0 = Cfe_eff × S_wet / S_ref` — "effective" Cfe = 0.005908 (from Aero!Cfe; gives ~0.0270).
  - CD0 is the Mission-tab total drag polar constant (not the zero-lift CDmin).
  - CD0 = 0.0270 is the cruise CD at zero lift using Cfe_eff (includes structural/roughness correction).
- The Miss tab uses CDmin_sub (0.01691) as the zero-lift base for all cruise drag calculations via `aero_at_mach()`.

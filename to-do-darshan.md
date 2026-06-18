# To-Do — Darshan

## Pending

- [ ] All the plotting
    - Team 3 PDR: 
    - Team 7 PDR: Slide 36, 38
    - Team 8 PDR: Slide 21, 34, 35, 93
- [ ] Look through the codes that the students have shared with me and incorporate them into my code

## Codebase Cleanup (post-refactor, dev_brandt_ground_truth branch)

Review and delete deprecated files — all replaced by the new discipline class architecture. Safe to delete once design studies run cleanly.

### Old F-16 flat-folder discipline files (replaced by `examples/.../disciplines/`)
- `examples/F-16A B Block 10 and 15/Aerodynamics/` (F16AeroLevel1/2/3.m)
- `examples/F-16A B Block 10 and 15/Geometry/` (F16GeometryLevel1/2/3.m)
- `examples/F-16A B Block 10 and 15/Propulsion/` (F16PropulsionLevel1/2/3/4.m)
- `examples/F-16A B Block 10 and 15/Weight/` (F16WeightLevel1/2/3.m, F16Level1WeightEstimation.m)
- `examples/F-16A B Block 10 and 15/MissionAnalysis/` (F16MissionAnalysisLevel1/2/3.m)
- `examples/F-16A B Block 10 and 15/ConstraintAnalysis/` (old F16ConstraintAnalysis.m)
- `examples/F-16A B Block 10 and 15/Sizing/` (F16SizingLevel1/2/3.m)
- `examples/F-16A B Block 10 and 15/F16A_Level{1,2,3}_Sizing_ClassBased_Example.m`

### Old `src/` infrastructure (replaced by `src/base/` + `src/Disciplines/` + `src/Sizing/`)
- `src/ComputationModels/` (all per-fidelity abstract classes — now replaced by per-discipline base classes)
- `src/Level_{II,III}_Fidelity/Sizing_script.m`
- `src/Disciplines/Sizing/SizingClassLevel{1,2,3}.m`

### Migrate requirements format
- [ ] Migrate mission requirements from `.xlsx` format to JSON (match the `f16a_geometry.json` pattern used by BrandtLevel)

## Port Casey's equation updates (design_comparison_branch → dev_brandt_ground_truth)

Additive static methods (no interface change), per Documentation Maintenance Rule (update docs/vv_*.md + test_F16*.m for each):
- [ ] AeroLevel1: `Delta_CL_max_TO/L` (Roskam 7.6/7.7), `CL_max_w` (7.3), `CL_max_w_unswept` (7.2), `isShortOrLongCoupled`, `tab_DeltaCD0` accessor
- [ ] AeroLevel2 (big): cambered/uncambered CD (Raymer 12.4/12.5), `LD_max` (Roskam 4.3), `CL_alpha_wing_sub/sup`+`cl_alpha_2D`+`beta_mach`/`eta_mach` (12.6-12.12), fuselage lift factor `F` (12.9), `CL_max_clean_subsonic/HighAR/LowAR` (12.15/16/19), `Delta_CL_max` (12.21), `Delta_CDi_flap`/`Delta_CD0_flap` (12.61/62), Roskam flap chain (7.8-7.18), `CL_minD`, `Delta_cl_max_table`, `k_lambda`/`k_ww`
- [ ] GeometryLevel1: `fuselage_geometry_table`+`tab_fuselage_geometry` (Roskam Pt II Tbl 4.1)
- [ ] GeometryLevel2: `S_wet_planform`+`p_plf` (12.1/12.2), `S_wet_fus_cyl/stream` (12.3/12.4), nacelle wetted areas (12.5-12.7), `lambda_f`, `Vbar_h/v`+`S_h/v` (8.1-8.4), `cp_c` (7.16)
- [ ] WeightLevel1: `cg_range_table`+`tab_cg_range` (Roskam Pt II Tbl 10.3), `composite_weight_reduction_table`+`tab_compositeweightfactor` (Roskam Pt I Tbl 2.16)
- [ ] PropulsionLevel2: `compute_capture_area`/`_ratio`, prop tip-speed helpers, `compute_WP_ducted_fan`
- [ ] PropulsionLevel3: `get_TSFC_dry`/`get_TSFC_wet` (Mattingly), `compute_cs`, `compute_AF_perblade`

Interface changes (need design decision first — see open questions):
- [ ] AeroLevel2 ctor: add `cl_max_airfoil`/`Lambda_qc_deg`, wire `CLmax()` → `CL_max_clean_*`
- [ ] PropulsionLevel3.TSFC: optionally switch to `get_TSFC_dry/wet`
- [ ] F16ConstraintAnalysis: add `V_Vstall` (default 1.0) to takeoff_eq, `beta` (default 1.0) to landing W/S formula

Unresolved / needs Casey input:
- [ ] Constraint master equation: mine vs Casey's `computeWingLoading` differ in q-scaling of drag/induced terms (mine validated vs Brandt T/W=0.7575). Reconcile with Casey.

Not ported (separate aircraft, out of scope): Casey's new `examples/Shrike/` example.

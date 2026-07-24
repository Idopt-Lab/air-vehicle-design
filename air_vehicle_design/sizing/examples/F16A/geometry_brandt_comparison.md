# F-16A Block 10 — Geometry vs Brandt Ground Truth

Generated 2026-07-24. W_TO = 31377 lbf [Brandt B38].

Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.geometry`] (Brandt-direct ground truth -- NOT `F16Baseline.m`, which is the older T.O.-manual-based ground truth used by `fidelity_comparison.m`).

This is a **comparison report**, not a test -- no pass/fail assertions. Where a quantity has multiple implementation options, each option gets its own row.

| Parameter | Fidelity | Computed | Brandt | %Diff | Source | Notes |
|---|---|---|---|---|---|---|
| **[WING / HT / VT WETTED AREA — TWO FORMULA OPTIONS EACH]** | | | | | | |
| Wing S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 396.3767 | 392.0204 | +1.11% | Brandt Geom!B14 | get_S_wet_wing() |
| Wing S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 392.0204 | 392.0204 | +0.00% | Brandt Geom!B14 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| HT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 101.3879 | 99.5848 | +1.81% | Brandt Geom!B16 | get_S_wet_HT() |
| HT   S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 99.5848 | 99.5848 | +0.00% | Brandt Geom!B16 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| VT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 83.1398 | 81.6894 | +1.78% | Brandt Geom!B17 | get_S_wet_VT() |
| VT   S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 81.6894 | 81.6894 | -0.00% | Brandt Geom!B17 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| Strake S_wet -- NOT MODELED           [ft^2] | N/A | N/A | 39.9560 |  -  | Brandt Geom!B15 | No strake component exists in GeomL2's get_S_wet aggregation |
| **[FUSELAGE WETTED AREA — THREE FORMULA OPTIONS]** | | | | | | |
| Fuselage S_wet, Roskam Eq.12.3 [OFFICIAL] [ft^2] | L2 | 730.3023 | 676.3289 | +7.98% | Brandt Geom!D23 | get_S_wet_fuselage() -- equivalent-diameter cylinder model; compared vs Brandt's high-fi (closest formula family) |
| Fuselage S_wet, Brandt low-fi [alt]   [ft^2] | L2 | 730.4203 | 730.4220 | -0.00% | Brandt Geom!B3 | compute_s_wet_fus_brandt_lowfi() -- reproduces Brandt's own "1/3-cone+2/3-cyl" formula |
| Fuselage S_wet, Brandt high-fi [alt]  [ft^2] | L2 | 677.9260 | 676.3289 | +0.24% | Brandt Geom!D23 | compute_s_wet_fus_brandt_highfi() -- reproduces Brandt's own frame-integration formula |
| **[DUCT / NACELLE]** | | | | | | |
| Duct S_wet (inlet-to-exit frustum)     [ft^2] | L2 | 155.5664 | 41.5150 | +274.72% | Brandt Geom!B4 (nacelle) | DIFFERENT quantity: exposed inlet-to-exit frustum vs Brandt's full-cylinder nacelle -- large %Diff expected, not a bug |
| Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft] | L2 | 3.537022 | 3.537000 | +0.00% | Brandt Engn(s) tab | Same formula as Brandt -- should match near-exactly (positive control) |
| **[EXPOSED LIFTING-SURFACE AREAS]** | | | | | | |
| Wing exposed area  [ft^2] | L2 | 196.2261 | 196.2261 | -0.00% | Brandt Geom!7 | compute_S_exposed_horizontal() via F16GeomL2 constructor |
| HT   exposed area  [ft^2] | L2 | 49.8473 | 49.8473 | -0.00% | Brandt Geom!8 | compute_S_exposed_horizontal() via F16GeomL2 constructor |
| VT   exposed area  [ft^2] | L2 | 40.8897 | 40.8897 | -0.00% | Brandt Geom!10 | compute_S_exposed_vertical() via F16GeomL2 constructor |
| Strake exposed area -- NOT MODELED [ft^2] | N/A | N/A | 20.0000 |  -  | Brandt Geom!9 | No strake component exists in this framework |
| **[SWEEP-ANGLE CONVERSION — HEADLINE BUG-FIX CHECK]** | | | | | | |
| Wing QC (25%c) sweep [deg] | L2 | 32.1832 | 28.1530 | +14.32% | readme_geom.md Table 3 | HEADLINE: was hardcoded 37 deg (bug), now computed ~32.2 deg via convert_sweep. No single Brandt cell for "wing QC sweep" exists in the comparison JSON; 28.153 deg is the closest available figure but reflects Brandt's EXPOSED-PANEL-based sweep definition, not our full-planform convert_sweep definition -- the ~4 deg gap is an expected, informative definitional difference (per IO's handoff notes), NOT a bug to chase down in this pass. |
| **[TOTALS]** | | | | | | |
| S_wet total, L1 statistical regression [ft^2] | L1 | 1763.02 | 1371.09 | +28.58% | Brandt Main!L3 (raw) | Roskam Vol.I Table 3.5 regression -- coarse by design |
| S_wet total, L2 OFFICIAL formula set    [ft^2] | L2 | 1466.77 | 1331.13 | +10.19% | readme_geom.md Sec 6.2 (corrected) | wing+HT+VT (Roskam Eq.12.1) + fuselage (Roskam Eq.12.3) + duct |
| S_wet total, L2 OFFICIAL vs RAW BUGGY  [ft^2] | L2 | 1466.77 | 1371.09 | +6.98% | Brandt Geom!B19 (raw, double-counts strake) | Brandt's own raw total double-counts the strake term (documented Excel bug, readme_geom.md Sec 6.2) -- corrected_total row above is the intended comparison target |
| S_wet total, Brandt-style formula set   [ft^2] | L2 | 1406.79 | 1331.13 | +5.68% | readme_geom.md Sec 6.2 (corrected) | wing+HT+VT (Brandt uniform-tc) + fuselage (Brandt high-fi) + duct -- closer to Brandt's own methodology |
| **[OTHER GEOMETRY OUTPUTS]** | | | | | | |
| Fuselage length L_fus [ft] | L2 | 46.5000 | N/A |  -  | geometry_L2.json (Brandt Main!B32) | Passthrough of the same Brandt Main-tab input the constructor reads -- reported for completeness, not an independent check |
| L_fus vs Brandt TOTAL aircraft length [ft] | L2 | 46.5000 | 48.3039 | -3.73% | Brandt Geom!B21 | DIFFERENT quantity: fuselage length only (46.5 ft) vs Brandt's total aircraft length incl. nose probe/pitot (48.30 ft) -- the ~3.7% gap is expected, not a bug |
| L1 fuselage length regression L_fus [ft] | L1 | 52.7426 | 46.5000 | +13.42% | F16GeomL2.L_fus (Brandt) | Raymer 6th ed. Table 6.3 statistical regression vs the Brandt-sourced L2 spec value |
| Max cross-section area Amax -- NOT MODELED [ft^2] | N/A | N/A | 25.1106 |  -  | Brandt Geom!B20/H47 | No max-cross-section-area computation exists anywhere in GeomL1/GeomL2 |

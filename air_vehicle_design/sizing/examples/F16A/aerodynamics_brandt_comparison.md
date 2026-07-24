# F-16A Block 10 — Aerodynamics vs Ground Truth (Brandt / AF-Manual / Internet)

Generated 2026-07-24. Flight condition: 36000 ft, subsonic M=0.6 / supersonic M=1.6.

Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.aerodynamics`]. Brandt = workbook outputs / his tabulated actual polar; AF Manual = T.O. 1F-16A-1 (airfoil + limits only); Internet = published estimates.

This is a **comparison report**, not a test — no pass/fail assertions, not in `run_all_tests`. A large %Diff is frequently **expected** (see Notes), not a defect. The 0.95 ≤ M ≤ 1.05 transonic band is skipped (L2/L3 return NaN there).

| Parameter | Fidelity | Computed | Brandt | %Diff | AF Manual | Internet (F-16) | Source | Notes |
|---|---|---|---|---|---|---|---|---|
| **[AF MANUAL CONTEXT -- T.O. 1F-16A-1 has NO drag polar / CLmax / CD0 coefficients]** | | | | | | | | |
| Wing airfoil | spec | N/A | N/A |  -  | NACA 64A204 | N/A | T.O. 1F-16A-1 Fig. 1-2 | AF-manual ground truth is limited to airfoil + operating limits; coefficients are in the (absent) T.O. 1F-16A-1-1. |
| Mach limit | spec | N/A | N/A |  -  | 2.05 | N/A | T.O. 1F-16A-1 limits | Structural/operational limit, not an aero coefficient. |
| **[SUBSONIC CLEAN DRAG POLAR -- M=0.6, 36 kft]** | | | | | | | | |
| CD0 subsonic (L1 Mattingly type-curve) | L1 | 0.01600 | 0.01691 | -5.38% | N/A | 0.01670 | Brandt Aero!G3 (skin-friction CDmin) | L1 CD0(M) from Mattingly Fig.2.10 (placeholder). Brandt skin-friction basis 0.01691; his MISSION CD0=0.0270 folds in form/interference/wave (a different basis). |
| CD0 subsonic (L2 Cfe*Swet/Sref) | L2 | 0.01711 | 0.01691 | +1.20% | N/A | 0.01670 | Brandt Aero!G3 (skin-friction CDmin) | Raymer Eq.12.23 with Cfe=0.0035 (AF fighter). Closest to Brandt skin-friction 0.01691; below his mission 0.0270 (no form/wave drag at L2) -- not a bug. |
| CD0 subsonic (L3 component buildup) | L3 | 0.01697 | 0.01691 | +0.36% | N/A | 0.01670 | Brandt Aero!G3 (skin-friction CDmin) | Raymer Eq.12.24 per-component sum. Same skin-friction basis as Brandt Aero!G3; below mission 0.0270 (no excrescence calibration) -- not a bug. |
| K1 subsonic (L1) | L1 | 0.1800 | 0.1160 | +55.17% | N/A | 0.1167 | Brandt Miss!k1 | L1 K1(M) from Mattingly Fig.2.11 (placeholder, ~0.18); higher than the geometry-based L2/L3 K1. |
| K1 subsonic (L2/L3, 1/(pi*AR*e)) | L2 | 0.1168 | 0.1160 | +0.67% | N/A | 0.1167 | Brandt Miss!k1 | Raymer Eq.12.50 with official Oswald e (Eq.12.49). L2 and L3 share this K1; excellent agreement with Brandt 0.1160. |
| K2 subsonic (L1, uncambered) | L1 | 0.00000 | -0.00630 | -100.00% | N/A | -0.00900 | Brandt Aero!G17 | L1 treats the fighter as uncambered -> K2=0 (Mattingly Sec.2.3.1). Brandt uses a small negative camber term -0.0063. |
| K2 subsonic (L2, -2*K1*CL_minD) | L2 | -0.00601 | -0.00630 | -4.66% | N/A | -0.00900 | Brandt Aero!G17 | Raymer Eq.12.6 CL_alpha + Brandt Sec.4.3. Cambered 64A204 (alpha_L0=-1.01) -> negative K2, close to Brandt. |
| K2 subsonic (L3, -2*K1*CL_minD) | L3 | -0.00671 | -0.00630 | +6.45% | N/A | -0.00900 | Brandt Aero!G17 | Same form as L2; L3 CL_alpha omits the 2-D-slope eta term (default 0.95), giving a slightly larger magnitude. |
| **[SUPERSONIC CLEAN DRAG POLAR -- M=1.6, 36 kft]** | | | | | | | | |
| CD0 supersonic (L1) | L1 | 0.02800 | 0.04610 | -39.26% | N/A | 0.04250 | Brandt Aero!O9 (actual polar, M=1.6) | L1 Mattingly supersonic CD0 plateau (~0.028, placeholder). Internet band ~0.0425 is at M~1.05. |
| CD0 supersonic (L2, skin friction only) | L2 | 0.00787 | 0.04610 | -82.92% | N/A | 0.04250 | Brandt Aero!O9 (actual polar, M=1.6) | EXPECTED LOW, NOT A BUG: L2 supersonic CD0 is Cf(Re,M)*Swet/Sref with NO wave drag (that is added only at L3). Grossly under Brandt 0.0461. |
| CD0 supersonic (L3, buildup + wave drag) | L3 | 0.04624 | 0.04610 | +0.30% | N/A | 0.04250 | Brandt Aero!O9 (actual polar, M=1.6) | L3 adds the Raymer Eq.12.41 fuselage wave-drag term (M>=1.2); much closer to Brandt 0.0461. Residual gap = no wing/canopy/boat-tail wave drag -- not a bug. |
| K1 supersonic (L1) | L1 | 0.2880 | 0.3400 | -15.29% | N/A | N/A | Brandt Aero!P9 (actual polar, M=1.6) | L1 Mattingly Fig.2.11 supersonic K1 (~0.29, placeholder). |
| K1 supersonic (L2/L3, Eq.12.51) | L2 | 0.2760 | 0.3400 | -18.81% | N/A | N/A | Brandt Aero!P9 (actual polar, M=1.6) | Raymer Eq.12.51 linearized supersonic K1 (shared L2/L3). Under Brandt 0.340 -- linear theory under-predicts real supersonic induced drag; expected. |
| **[CD0 vs MACH SWEEP -- L2 & L3, 36 kft (subsonic 0.6/0.8/0.9, supersonic 1.2/1.5/2.0)]** | | | | | | | | |
| CD0 @ M=0.6 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A | N/A | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.6 (L3) | L3 | 0.01697 | 0.02050 | -17.22% | N/A | N/A | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.8 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A | N/A | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.8 (L3) | L3 | 0.01632 | 0.02050 | -20.41% | N/A | N/A | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.9 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A | N/A | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.9 (L3) | L3 | 0.01600 | 0.02050 | -21.95% | N/A | N/A | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=1.2 (L2) | L2 | 0.00889 | 0.04440 | -79.98% | N/A | N/A | Brandt actual polar (M~1.05) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.2 (L3) | L3 | 0.05130 | 0.04440 | +15.53% | N/A | N/A | Brandt actual polar (M~1.05) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.5 (L2) | L2 | 0.00812 | 0.04610 | -82.39% | N/A | N/A | Brandt actual polar (M~1.6) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.5 (L3) | L3 | 0.04712 | 0.04610 | +2.22% | N/A | N/A | Brandt actual polar (M~1.6) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| CD0 @ M=2.0 (L2) | L2 | 0.00697 | 0.04580 | -84.78% | N/A | N/A | Brandt actual polar (M~2) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=2.0 (L3) | L3 | 0.04321 | 0.04580 | -5.65% | N/A | N/A | Brandt actual polar (M~2) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| **[OSWALD SPAN EFFICIENCY -- two implementation options]** | | | | | | | | |
| e, official Raymer Eq.12.48/12.49 (L2) | L2 | 0.9086 | 0.9144 | -0.63% | N/A | 0.9070 | Brandt Aero!G12 (e0) | OFFICIAL drag_polar value (Eq.12.49, Lambda_LE=40). ~0.6% under Brandt e0 (Brandt uses a different formula). |
| e, official Raymer Eq.12.48/12.49 (L3) | L3 | 0.9086 | 0.9144 | -0.63% | N/A | 0.9070 | Brandt Aero!G12 (e0) | Same official formula as L2. |
| e, Brandt Aero!G12 alternate (L2) | L2 | 0.9144 | 0.9144 | +0.00% | N/A | 0.9070 | Brandt Aero!G12 (e0) | POSITIVE CONTROL: this is Brandt's own formula fed Brandt's inputs, so it reproduces e0=0.9144 near-exactly. Comparison-report ONLY -- never what drag_polar returns. |
| e, Brandt Aero!G12 alternate (L3) | L3 | 0.9144 | 0.9144 | +0.00% | N/A | 0.9070 | Brandt Aero!G12 (e0) | Same Brandt alternate as L2 (positive control). |
| **[MAXIMUM LIFT COEFFICIENT -- clean / takeoff / landing]** | | | | | | | | |
| CLmax clean (L1 Roskam lookup) | L1 | 0.9000 | 0.9840 | -8.54% | N/A | 1.6000 | Brandt Aero!H25 | Roskam Vol.I Table 3.3 fighter clean = 0.90. Both L1 and Brandt (0.984) badly under the ~1.6 whole-aircraft value: NO LEX/strake vortex lift modeled -- not a bug. |
| CLmax clean (L2 Eq.12.15) | L2 | 0.9141 | 0.9840 | -7.11% | N/A | 1.6000 | Brandt Aero!H25 | 0.9*cl_max_2D*cos(Lambda_c/4). Near Brandt 0.984; far below internet ~1.6 (no vortex lift) -- expected underprediction, not a bug. |
| CLmax clean (L3 Eq.12.15) | L3 | 0.9141 | 0.9840 | -7.11% | N/A | 1.6000 | Brandt Aero!H25 | Same Eq.12.15 basis as L2; same LEX vortex-lift limitation. |
| CLmax takeoff (L1) | L1 | 1.1000 | 1.2760 | -13.79% | N/A | 1.3500 | Brandt Aero!H27 | L1 clean + Roskam Table 3.1 fighter TO-delta (category mean). |
| CLmax takeoff (L2 flap) | L2 | 1.2431 | 1.2760 | -2.58% | N/A | 1.3500 | Brandt Aero!H27 | Clean + TE-flap delta (Eq.12.21). Internet 1.35 is a rough band center (F-16 has no conventional TE flaps). |
| CLmax takeoff (L3 flap+slat) | L3 | 1.2677 | 1.2760 | -0.65% | N/A | 1.3500 | Brandt Aero!H27 | Clean + TE-flap + LE-slat deltas; closest of the three levels to Brandt 1.276. |
| CLmax landing (L1) | L1 | 1.5000 | 1.4260 | +5.19% | N/A | 1.3500 | Brandt Aero!H29 | L1 clean + Roskam Table 3.1 fighter landing-delta -- generic large-flap category mean overshoots the F-16. |
| CLmax landing (L2 flap) | L2 | 1.3528 | 1.4260 | -5.13% | N/A | 1.3500 | Brandt Aero!H29 | Clean + TE-flap delta only (no slat at L2). |
| CLmax landing (L3 flap+slat) | L3 | 1.3856 | 1.4260 | -2.83% | N/A | 1.3500 | Brandt Aero!H29 | Clean + TE-flap + LE-slat deltas; closest to Brandt 1.426. |

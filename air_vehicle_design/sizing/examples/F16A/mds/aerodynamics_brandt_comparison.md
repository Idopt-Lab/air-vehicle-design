# F-16A Block 10/15 — Aerodynamics vs Ground Truth

Generated 2026-08-08. Flight condition: 36000 ft, subsonic M = 0.6 / supersonic M = 1.6.

**Reference** (the `Reference` and `%Diff` columns): Brandt F-16A.xls workbook outputs and his tabulated actual polar, via `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.aerodynamics`].

**2nd Source** (the `2nd Source` column): whichever independent source exists for that row, tagged inline — `[AF]` = T.O. 1F-16A-1 (which carries the airfoil and operating limits **only**; it has no drag polar, CLmax or CD0 coefficients — those live in the absent T.O. 1F-16A-1-1), `[pub]` = a published estimate (F-16C conceptual polar, textbook, NASA). Most aero rows have neither, and show `N/A`.

This is a **comparison report, not a test** — no pass/fail assertions, not part of `run_all_tests`, and **nothing here may ever be used to backfill a unit test's expected value**. Where a quantity has more than one valid implementation, each option gets its own row, and rejected variants are reported too so the decisions stay auditable.

**Reading the `Divergence` column.** `BY DESIGN` — the framework computes the *same kind* of quantity as the reference but is *expected* to differ (a different formula family, or a locked decision to follow a physical/T.O. value); a large %Diff there is the correct answer, not a defect, though its magnitude is worth a sanity check. `DEFINITIONAL` — the two sides are *different kinds of quantity altogether*, so the %Diff is not an error measure at all; do not chase it. **Blank** — a genuine agreement check, where a large %Diff **is** worth chasing.

**The transonic band 0.95 ≤ M ≤ 1.05 is deliberately skipped.** L2/L3 `drag_polar` returns NaN there — Raymer Eq. 12.51 has a pole near M = 1 — so the sweep uses subsonic M = 0.6/0.8/0.9 and supersonic M = 1.2/1.5/2.0. That NaN is a modelled gap, not a failure: `Both_WbyS_TbyW` and `ConstraintAnalysis` both refuse to evaluate a constraint there rather than returning a number.

**Two expected large gaps that are not defects.** L2 supersonic CD0 carries no wave-drag term at all (that arrives only at L3), so it sits far below Brandt. And Brandt's skin-friction CDmin (`Aero!G3`) is a different basis from his *mission* CD0 of 0.0270, which folds in form, interference and wave drag — compare like with like before concluding anything.

| Parameter | Fidelity | Computed | Reference | %Diff | 2nd Source | Divergence | Cite | Notes |
|---|---|---|---|---|---|---|---|---|
| **[AF MANUAL CONTEXT -- T.O. 1F-16A-1 has NO drag polar / CLmax / CD0 coefficients]** | | | | | | | | |
| Wing airfoil | spec | N/A | N/A |  -  | NACA 64A204 [AF] |  | T.O. 1F-16A-1 Fig. 1-2 | AF-manual ground truth is limited to airfoil + operating limits; coefficients are in the (absent) T.O. 1F-16A-1-1. |
| Mach limit | spec | N/A | N/A |  -  | 2.05 [AF] |  | T.O. 1F-16A-1 limits | Structural/operational limit, not an aero coefficient. |
| **[SUBSONIC CLEAN DRAG POLAR -- M=0.6, 36 kft]** | | | | | | | | |
| CD0 subsonic (L1 Mattingly type-curve) | L1 | 0.01600 | 0.01691 | -5.38% | 0.01670 [pub] |  | Brandt Aero!G3 (skin-friction CDmin) | L1 CD0(M) from Mattingly Fig.2.10 (placeholder). Brandt skin-friction basis 0.01691; his MISSION CD0=0.0270 folds in form/interference/wave (a different basis). |
| CD0 subsonic (L2 Cfe*Swet/Sref) | L2 | 0.01711 | 0.01691 | +1.20% | 0.01670 [pub] |  | Brandt Aero!G3 (skin-friction CDmin) | Raymer Eq.12.23 with Cfe=0.0035 (AF fighter). Closest to Brandt skin-friction 0.01691; below his mission 0.0270 (no form/wave drag at L2) -- not a bug. |
| CD0 subsonic (L3 component buildup) | L3 | 0.01705 | 0.01691 | +0.84% | 0.01670 [pub] |  | Brandt Aero!G3 (skin-friction CDmin) | Raymer Eq.12.24 per-component sum. Same skin-friction basis as Brandt Aero!G3; below mission 0.0270 (no excrescence calibration) -- not a bug. |
| K1 subsonic (L1) | L1 | 0.1168 | 0.1160 | +0.67% | 0.1167 [pub] |  | Brandt Miss!k1 | L1 K1(M) from Mattingly Fig.2.11 (placeholder, ~0.18); higher than the geometry-based L2/L3 K1. |
| K1 subsonic (L2/L3, 1/(pi*AR*e)) | L2 | 0.1168 | 0.1160 | +0.67% | 0.1167 [pub] |  | Brandt Miss!k1 | Raymer Eq.12.50 with official Oswald e (Eq.12.49). L2 and L3 share this K1; excellent agreement with Brandt 0.1160. |
| K2 subsonic (L1, uncambered) | L1 | 0.00000 | -0.00630 | -100.00% | -0.00900 [pub] |  | Brandt Aero!G17 | L1 treats the fighter as uncambered -> K2=0 (Mattingly Sec.2.3.1). Brandt uses a small negative camber term -0.0063. |
| K2 subsonic (L2, -2*K1*CL_minD) | L2 | -0.00791 | -0.00630 | +25.55% | -0.00900 [pub] |  | Brandt Aero!G17 | Raymer Eq.12.6 CL_alpha + Brandt Sec.4.3. Cambered 64A204 (alpha_L0=-1.01) -> negative K2, close to Brandt. |
| K2 subsonic (L3, -2*K1*CL_minD) | L3 | -0.00791 | -0.00630 | +25.55% | -0.00900 [pub] |  | Brandt Aero!G17 | Same form as L2; L3 CL_alpha omits the 2-D-slope eta term (default 0.95), giving a slightly larger magnitude. |
| **[SUPERSONIC CLEAN DRAG POLAR -- M=1.6, 36 kft]** | | | | | | | | |
| CD0 supersonic (L1) | L1 | 0.02800 | 0.04610 | -39.26% | 0.04250 [pub] |  | Brandt Aero!O9 (actual polar, M=1.6) | L1 Mattingly supersonic CD0 plateau (~0.028, placeholder). Internet band ~0.0425 is at M~1.05. |
| CD0 supersonic (L2, skin friction only) | L2 | 0.04460 | 0.04610 | -3.25% | 0.04250 [pub] |  | Brandt Aero!O9 (actual polar, M=1.6) | EXPECTED LOW, NOT A BUG: L2 supersonic CD0 is Cf(Re,M)*Swet/Sref with NO wave drag (that is added only at L3). Grossly under Brandt 0.0461. |
| CD0 supersonic (L3, buildup + wave drag) | L3 | 0.03882 | 0.04610 | -15.80% | 0.04250 [pub] |  | Brandt Aero!O9 (actual polar, M=1.6) | L3 adds the Raymer Eq.12.41 fuselage wave-drag term (M>=1.2); much closer to Brandt 0.0461. Residual gap = no wing/canopy/boat-tail wave drag -- not a bug. |
| K1 supersonic (L1) | L1 | 0.2760 | 0.3400 | -18.81% | N/A |  | Brandt Aero!P9 (actual polar, M=1.6) | L1 Mattingly Fig.2.11 supersonic K1 (~0.29, placeholder). |
| K1 supersonic (L2/L3, Eq.12.51) | L2 | 0.2760 | 0.3400 | -18.81% | N/A |  | Brandt Aero!P9 (actual polar, M=1.6) | Raymer Eq.12.51 linearized supersonic K1 (shared L2/L3). Under Brandt 0.340 -- linear theory under-predicts real supersonic induced drag; expected. |
| **[CD0 vs MACH SWEEP -- L2 & L3, 36 kft (subsonic 0.6/0.8/0.9, supersonic 1.2/1.5/2.0)]** | | | | | | | | |
| CD0 @ M=0.6 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A |  | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.6 (L3) | L3 | 0.01705 | 0.02050 | -16.82% | N/A |  | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.8 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A |  | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.8 (L3) | L3 | 0.01639 | 0.02050 | -20.04% | N/A |  | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.9 (L2) | L2 | 0.01711 | 0.02050 | -16.53% | N/A |  | Brandt actual polar (M~0.875) | L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=0.9 (L3) | L3 | 0.01607 | 0.02050 | -21.59% | N/A |  | Brandt actual polar (M~0.875) | L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo. |
| CD0 @ M=1.2 (L2) | L2 | 0.04839 | 0.04440 | +8.98% | N/A |  | Brandt actual polar (M~1.05) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.2 (L3) | L3 | 0.04300 | 0.04440 | -3.16% | N/A |  | Brandt actual polar (M~1.05) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.5 (L2) | L2 | 0.04536 | 0.04610 | -1.62% | N/A |  | Brandt actual polar (M~1.6) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=1.5 (L3) | L3 | 0.03957 | 0.04610 | -14.17% | N/A |  | Brandt actual polar (M~1.6) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| CD0 @ M=2.0 (L2) | L2 | 0.04212 | 0.04580 | -8.03% | N/A |  | Brandt actual polar (M~2) | L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo. |
| CD0 @ M=2.0 (L3) | L3 | 0.03621 | 0.04580 | -20.93% | N/A |  | Brandt actual polar (M~2) | L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo. |
| **[OSWALD SPAN EFFICIENCY -- two implementation options]** | | | | | | | | |
| e, official Raymer Eq.12.48/12.49 (L2) | L2 | 0.9086 | 0.9144 | -0.63% | 0.9070 [pub] |  | Brandt Aero!G12 (e0) | OFFICIAL drag_polar value (Eq.12.49, Lambda_LE=40). ~0.6% under Brandt e0 (Brandt uses a different formula). |
| e, official Raymer Eq.12.48/12.49 (L3) | L3 | 0.9086 | 0.9144 | -0.63% | 0.9070 [pub] |  | Brandt Aero!G12 (e0) | Same official formula as L2. |
| e, Brandt Aero!G12 alternate (L2) | L2 | 0.9144 | 0.9144 | +0.00% | 0.9070 [pub] |  | Brandt Aero!G12 (e0) | POSITIVE CONTROL: this is Brandt's own formula fed Brandt's inputs, so it reproduces e0=0.9144 near-exactly. Comparison-report ONLY -- never what drag_polar returns. |
| e, Brandt Aero!G12 alternate (L3) | L3 | 0.9144 | 0.9144 | +0.00% | 0.9070 [pub] |  | Brandt Aero!G12 (e0) | Same Brandt alternate as L2 (positive control). |
| **[MAXIMUM LIFT COEFFICIENT -- clean / takeoff / landing]** | | | | | | | | |
| CLmax clean (L1 Roskam lookup) | L1 | 1.5000 | 0.9840 | +52.44% | 1.6000 [pub] |  | Brandt Aero!H25 | Roskam Vol.I Table 3.3 fighter clean = 0.90. Both L1 and Brandt (0.984) badly under the ~1.6 whole-aircraft value: NO LEX/strake vortex lift modeled -- not a bug. |
| CLmax clean (L2 Eq.12.15) | L2 | 0.9141 | 0.9840 | -7.11% | 1.6000 [pub] |  | Brandt Aero!H25 | 0.9*cl_max_2D*cos(Lambda_c/4). Near Brandt 0.984; far below internet ~1.6 (no vortex lift) -- expected underprediction, not a bug. |
| CLmax clean (L3 Eq.12.15) | L3 | 0.9141 | 0.9840 | -7.11% | 1.6000 [pub] |  | Brandt Aero!H25 | Same Eq.12.15 basis as L2; same LEX vortex-lift limitation. |
| CLmax takeoff (L1) | L1 | 1.7000 | 1.2760 | +33.23% | 1.3500 [pub] |  | Brandt Aero!H27 | L1 clean + Roskam Table 3.1 fighter TO-delta (category mean). |
| CLmax takeoff (L2 flap) | L2 | 1.2431 | 1.2760 | -2.58% | 1.3500 [pub] |  | Brandt Aero!H27 | Clean + TE-flap delta (Eq.12.21). Internet 1.35 is a rough band center (F-16 has no conventional TE flaps). |
| CLmax takeoff (L3 flap+slat) | L3 | 1.2677 | 1.2760 | -0.65% | 1.3500 [pub] |  | Brandt Aero!H27 | Clean + TE-flap + LE-slat deltas; closest of the three levels to Brandt 1.276. |
| CLmax landing (L1) | L1 | 2.1000 | 1.4260 | +47.27% | 1.3500 [pub] |  | Brandt Aero!H29 | L1 clean + Roskam Table 3.1 fighter landing-delta -- generic large-flap category mean overshoots the F-16. |
| CLmax landing (L2 flap) | L2 | 1.3528 | 1.4260 | -5.13% | 1.3500 [pub] |  | Brandt Aero!H29 | Clean + TE-flap delta only (no slat at L2). |
| CLmax landing (L3 flap+slat) | L3 | 1.3856 | 1.4260 | -2.83% | 1.3500 [pub] |  | Brandt Aero!H29 | Clean + TE-flap + LE-slat deltas; closest to Brandt 1.426. |
| **[LIFT-CURVE SLOPE CL_alpha -- Raymer Eq.12.6, M=0]** | | | | | | | | |
| CL_alpha, M=0 [1/rad] | L1 | N/A | 3.1117 |  -  | N/A |  | Brandt Aero!A15 | L1 is geometry-free (Mattingly type-curve), so no finite-wing lift slope exists at this tier -- not an omission. |
| CL_alpha, M=0 [1/rad] | L2 | 3.0365 | 3.1117 | -2.42% | N/A |  | Brandt Aero!A15 | Raymer Eq.12.6 with the injected quarter-chord sweep (~32.2 deg) and the real NACA 64A204 2-D slope. |
| CL_alpha, M=0 [1/rad] | L3 | 3.0365 | 3.1117 | -2.42% | N/A |  | Brandt Aero!A15 | L3 delegates to AeroL2.get_CL_alpha, so it MUST equal the L2 row exactly for identical injected geometry -- a positive control on the delegation. |

**CLmax is the largest step in the fidelity ladder, and it is intentional.** L1 returns the Roskam Table 3.1 fighter-column mean (1.50); L2/L3 return Raymer Eq. 12.15's geometry-based 0.914. A type-only statistical mean over a column dominated by straight wings is simply a different estimator from one that penalises a thin 40°-swept wing. Neither is calibrated to the other.

**Vortex lift from the LEX/strake is not modelled at any tier**, so every CLmax row underpredicts the ~1.6 real whole-aircraft value.


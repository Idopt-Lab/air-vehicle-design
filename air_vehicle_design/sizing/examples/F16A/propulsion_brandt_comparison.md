# F-16A Block 10 — Propulsion vs Brandt Ground Truth

Generated 2026-07-24.

Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.propulsion`] (Brandt-workbook outputs, cited per cell).

This is a **comparison report**, not a test — no pass/fail assertions, not in `run_all_tests`. The framework's Mattingly engine model (Eq. 2.54 lapse / Eq. 3.55 TSFC) and Brandt's Engn(s) model are **different models**, so a large %Diff is frequently **expected** (see Notes), not a defect. Brandt SLS TSFCs 0.70/2.20 are **installed** (already ×1.08) — compare the framework installed rows.

| Parameter | Fidelity | Computed | Brandt | %Diff | Other source | Source | Notes |
|---|---|---|---|---|---|---|---|
| **[THRUST LAPSE alpha_AB -- L2 Mattingly Eq.2.54a vs Brandt alpha_AB (Consts AT)]** | | | | | | | |
| alpha_AB @ dash_max_mach (36000ft M1.60, 100%AB) | L2 | 0.5494 | 0.5770 | -4.77% | AU(eff on T_AB)=0.5770; AS(dry)=0.2983 | Brandt Consts AT23 | Above-TR (theta_0>TR=1.0): both models carry a theta correction; Mattingly (3.5 coeff) and Brandt (2.2 coeff + 0.1*sqrt(M)) agree within a few percent -- the closest conditions. |
| alpha_AB @ cruise (36000ft M0.87, 0%AB) | L2 | 0.3674 | 0.3326 | +10.45% | AU(eff on T_AB)=0.1711; AS(dry)=0.2711 | Brandt Consts AT24 | Below-TR (theta_0<=TR=1.0): Mattingly alpha_AB=delta_0 with NO Mach term; Brandt subtracts 0.1*sqrt(M). Framework reads HIGH vs Brandt AT -- expected, not a bug. |
| alpha_AB @ max_alt (50000ft M0.87, 100%AB) | L2 | 0.1875 | 0.1703 | +10.08% | AU(eff on T_AB)=0.1703; AS(dry)=0.1388 | Brandt Consts AT25 | Below-TR (theta_0<=TR=1.0): Mattingly alpha_AB=delta_0 with NO Mach term; Brandt subtracts 0.1*sqrt(M). Framework reads HIGH vs Brandt AT -- expected, not a bug. |
| alpha_AB @ combat_turn_sub (20000ft M0.87, 100%AB) | L2 | 0.7526 | 0.6818 | +10.39% | AU(eff on T_AB)=0.6818; AS(dry)=0.5557 | Brandt Consts AT26 | Below-TR (theta_0<=TR=1.0): Mattingly alpha_AB=delta_0 with NO Mach term; Brandt subtracts 0.1*sqrt(M). Framework reads HIGH vs Brandt AT -- expected, not a bug. |
| alpha_AB @ combat_turn_sup (36000ft M1.40, 100%AB) | L2 | 0.6007 | 0.5566 | +7.92% | AU(eff on T_AB)=0.5566; AS(dry)=0.3579 | Brandt Consts AT27 | Above-TR (theta_0>TR=1.0): both models carry a theta correction; Mattingly (3.5 coeff) and Brandt (2.2 coeff + 0.1*sqrt(M)) agree within a few percent -- the closest conditions. |
| alpha_AB @ ps_500 (10000ft M0.87, 100%AB) | L2 | 0.8608 | 0.8536 | +0.85% | AU(eff on T_AB)=0.8536; AS(dry)=0.7027 | Brandt Consts AT28 | Above-TR (theta_0>TR=1.0): both models carry a theta correction; Mattingly (3.5 coeff) and Brandt (2.2 coeff + 0.1*sqrt(M)) agree within a few percent -- the closest conditions. |
| **[THRUST LAPSE alpha -- L1 density-only sigma^m vs Brandt alpha_AB (Consts AT)]** | | | | | | | |
| alpha_L1 @ dash_max_mach (36000ft M1.60) | L1 | 0.4837 | 0.5770 | -16.16% | AT=0.5770 | Brandt Consts AT23 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| alpha_L1 @ cruise (36000ft M0.87) | L1 | 0.4837 | 0.3326 | +45.42% | AT=0.3326 | Brandt Consts AT24 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| alpha_L1 @ max_alt (50000ft M0.87) | L1 | 0.3232 | 0.1703 | +89.80% | AT=0.1703 | Brandt Consts AT25 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| alpha_L1 @ combat_turn_sub (20000ft M0.87) | L1 | 0.6854 | 0.6818 | +0.53% | AT=0.6818 | Brandt Consts AT26 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| alpha_L1 @ combat_turn_sup (36000ft M1.40) | L1 | 0.4837 | 0.5566 | -13.08% | AT=0.5566 | Brandt Consts AT27 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| alpha_L1 @ ps_500 (10000ft M0.87) | L1 | 0.8337 | 0.8536 | -2.33% | AT=0.8536 | Brandt Consts AT28 | L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation. |
| **[THRUST LAPSE dry/mil basis -- L2 mil-on-AB-scale vs Brandt alpha_eff_on_TAB (Consts AU)]** | | | | | | | |
| alpha_mil-on-AB @ cruise (36000ft M0.87) | L2 | 0.1391 | 0.1711 | -18.69% | AS(dry)=0.2711 | Brandt Consts AU24 | Cruise is flown 0% AB (dry). Framework alpha_mil = 0.6*delta_0 renormalized to the AB axis (x T_SL_mil/T_SL_wet). Brandt AU = AS*(T_dry/T_AB). Mattingly has no below-TR Mach term; expected high. |
| **[TSFC -- L2 Mattingly Eq.3.55 (uninstalled & installed x1.08) vs Brandt installed]** | | | | | | | |
| TSFC mil SLS(M~0), UNINSTALLED (L2) | L2 | 0.9003 | 0.7000 | +28.61% | Mattingly Eq.3.55a C1_mil=0.90 | Brandt Engn!TSFC_mil (installed) | Brandt 0.70 is INSTALLED (incl. 1.08); compare the installed row below, not this uninstalled one. |
| TSFC mil SLS(M~0), INSTALLED x1.08 (L2) | L2 | 0.9723 | 0.7000 | +38.90% | uninst 0.90 x 1.08 | Brandt Engn!TSFC_mil (installed) | Mattingly over-predicts SLS static mil TSFC vs Brandt 0.70 (known systematic bias); trend vs alt/Mach is correct. |
| TSFC AB SLS(M=0.4), UNINSTALLED (L2) | L2 | 1.7080 | 2.2000 | -22.36% | Mattingly Eq.3.55b (1.60+0.27M) | Brandt Engn!TSFC_AB (installed, M=0.4) | Brandt 2.20 is INSTALLED at the M=0.4 reference; compare the installed row below. |
| TSFC AB SLS(M=0.4), INSTALLED x1.08 (L2) | L2 | 1.8446 | 2.2000 | -16.15% | uninst 1.7080 x 1.08 | Brandt Engn!TSFC_AB (installed, M=0.4) | Mattingly under-predicts the AB reference vs Brandt 2.20; different AB model calibration -- not a bug. |
| TSFC cruise (L1 Raymer Table 3.3) | L1 | 0.8000 | 0.7000 | +14.29% | Raymer Table 3.3 cruise=0.80 | Brandt Engn!TSFC_mil (installed SLS) | DIFFERENT basis: L1 categorical cruise SFC (0.80, M>=0.4) vs Brandt SLS-static installed mil (0.70) -- not directly comparable. |
| **[ENGINE CONSTANTS -- positive controls]** | | | | | | | |
| T_SL_wet (AB SLS thrust) [lbf] | L2 | 23770.0 | 23770.0 | +0.00% | T.O. 1F-16A-1 Sec.I | Brandt Main!D29 | Spec input echoed both sides -- should match exactly. |
| T_SL_mil (dry SLS thrust) [lbf] | L2 | 15000.0 | 15000.0 | +0.00% | T.O. 1F-16A-1 Sec.I | Brandt Main!C29 | Spec input echoed both sides -- should match exactly. |
| TR (throttle ratio) | L2 | 1.0000 | 1.0000 | +0.00% | Mattingly Eq.D.6 (T_t4_SLS unknown->1.0) | Brandt Engn(s)!S1 | Should match exactly (both 1.0). |
| **[NACELLE SIZING -- Brandt Engn(s) formula reproduced as positive control]** | | | | | | | |
| Nacelle diameter D=sqrt(T_AB/1900) [ft] | L2 | 3.5370 | 3.5370 | +0.00% | Raymer Eq.10.12 ~3.8 (unwired) | Brandt Engn(s) D_nac | Same formula/inputs as Brandt -- near-exact match expected. |
| Nacelle length L=4.5*D [ft] | L2 | 15.9166 | 15.9170 | -0.00% | T.O. 1F-16A-1 total length 15.93 | Brandt Engn(s) L_nac | Same formula/inputs as Brandt; T.O. total engine length 15.93 ft is an independent anchor. |

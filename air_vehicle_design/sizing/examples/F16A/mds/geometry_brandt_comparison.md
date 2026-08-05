# F-16A Block 10/15 — Geometry vs Ground Truth

Generated 2026-08-05. W_TO = 31377 lbf [Brandt Main! mission W_TO_lb].

**Reference** (the `Reference` and `%Diff` columns): Brandt F-16A.xls, via `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.geometry`] — the Brandt-DIRECT ground truth.

**2nd Source** (the `2nd Source` column): T.O. 1F-16A-1 flight manual / USAF 3-view, via the same file's `.to_1f16a1` block. These are the same physical numbers `f16a_L3.json` carries as inputs — one shared truth recorded as a second source, so a `BY DESIGN` divergence from Brandt is visibly backed by a document rather than looking like error.

This is a **comparison report, not a test** — no pass/fail assertions, not part of `run_all_tests`, and **nothing here may ever be used to backfill a unit test's expected value**. Where a quantity has more than one valid implementation, each option gets its own row, and rejected variants are reported too so the decisions stay auditable.

**Reading the `Divergence` column.** `BY DESIGN` — the framework computes the *same kind* of quantity as the reference but is *expected* to differ (a different formula family, or a locked decision to follow a physical/T.O. value); a large %Diff there is the correct answer, not a defect, though its magnitude is worth a sanity check. `DEFINITIONAL` — the two sides are *different kinds of quantity altogether*, so the %Diff is not an error measure at all; do not chase it. **Blank** — a genuine agreement check, where a large %Diff **is** worth chasing.

**The three L3 divergences that explain most of this table.** L3 is the physical / T.O. tier: fuselage length **47.5 ft** (Brandt 46.5), VT leading-edge sweep **47.5°** (Brandt 40°), and the HT span **18.5 ft** taken as PRIMARY so `AR_ht` is derived (3.1690) rather than Brandt's stated 3.0. Every other `BY DESIGN` row downstream inherits one of these three.

**Where a quantity has more than one implementation, each gets a row.** Wing/HT/VT `S_wet` via Roskam Eq. 12.1 (official) vs Brandt's own uniform-t/c formula; fuselage `S_wet` via Roskam Eq. 12.3 (official) vs Brandt low-fi vs Brandt high-fi. The Brandt-formula rows match him near-exactly by construction — they are his formula fed his own inputs, i.e. positive controls on the plumbing rather than independent checks.

| Parameter | Fidelity | Computed | Reference | %Diff | 2nd Source | Divergence | Cite | Notes |
|---|---|---|---|---|---|---|---|---|
| **[WING / HT / VT WETTED AREA — TWO FORMULA OPTIONS EACH]** | | | | | | | | |
| Wing S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 396.3767 | 392.0204 | +1.11% | N/A |  | Brandt Geom!B14 | get_S_wet_wing() |
| Wing S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 392.0204 | 392.0204 | +0.00% | N/A |  | Brandt Geom!B14 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| HT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 101.3879 | 99.5848 | +1.81% | N/A |  | Brandt Geom!B16 | get_S_wet_HT() |
| HT   S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 99.7792 | 99.5848 | +0.20% | N/A |  | Brandt Geom!B16 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| VT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2] | L2 | 83.1398 | 81.6894 | +1.78% | N/A |  | Brandt Geom!B17 | get_S_wet_VT() |
| VT   S_wet, Brandt uniform-tc [alt]  [ft^2] | L2 | 81.7213 | 81.6894 | +0.04% | N/A |  | Brandt Geom!B17 | compute_wet_planform() -- same formula Brandt uses, near-exact match expected |
| Strake S_wet -- NOT MODELED           [ft^2] | N/A | N/A | 39.9560 |  -  | N/A |  | Brandt Geom!B15 | No strake component exists in any geometry tier. DEFERRED, not overlooked: sub-step 2h proved the strake contributes exactly 0.000% to Amax (active only 12.0 < x < 21.551 ft, well forward of the governing station), so it was descoped from 2h and logged for its own step. |
| **[FUSELAGE WETTED AREA — THREE FORMULA OPTIONS]** | | | | | | | | |
| Fuselage S_wet, Roskam Eq.12.3 [OFFICIAL] [ft^2] | L2 | 730.3023 | 676.3289 | +7.98% | N/A |  | Brandt Geom!D23 | get_S_wet_fuselage() -- equivalent-diameter cylinder model; compared vs Brandt's high-fi (closest formula family) |
| Fuselage S_wet, Brandt low-fi [alt]   [ft^2] | L2 | 730.4203 | 730.4220 | -0.00% | N/A |  | Brandt Geom!B3 | compute_s_wet_fus_brandt_lowfi() -- reproduces Brandt's own "1/3-cone+2/3-cyl" formula |
| Fuselage S_wet, Brandt high-fi [alt]  [ft^2] | L2 | 677.9260 | 676.3289 | +0.24% | N/A |  | Brandt Geom!D23 | compute_s_wet_fus_brandt_highfi() -- reproduces Brandt's own frame-integration formula |
| **[DUCT / NACELLE]** | | | | | | | | |
| Duct S_wet (inlet-to-exit frustum)     [ft^2] | L2 | 155.5664 | 41.5150 | +274.72% | N/A | DEFINITIONAL | Brandt Geom!B4 (nacelle) | DIFFERENT quantity: exposed inlet-to-exit frustum vs Brandt's full-cylinder nacelle -- the %Diff is not a meaningful error measure here. |
| Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft] | L2 | 3.537022 | 3.537000 | +0.00% | N/A |  | Brandt Engn(s) tab | Same formula as Brandt -- should match near-exactly (positive control) |
| **[EXPOSED LIFTING-SURFACE AREAS]** | | | | | | | | |
| Wing exposed area  [ft^2] | L2 | 196.2261 | 196.2261 | -0.00% | N/A |  | Brandt Geom!7 | compute_S_exposed_horizontal() via F16GeomL2 constructor |
| HT   exposed area  [ft^2] | L2 | 49.8473 | 49.8473 | -0.00% | N/A |  | Brandt Geom!8 | compute_S_exposed_horizontal() via F16GeomL2 constructor |
| VT   exposed area  [ft^2] | L2 | 40.8897 | 40.8897 | -0.00% | N/A |  | Brandt Geom!10 | compute_S_exposed_vertical() via F16GeomL2 constructor |
| Strake exposed area -- NOT MODELED [ft^2] | N/A | N/A | 20.0000 |  -  | N/A |  | Brandt Geom!9 | No strake component exists in this framework -- DEFERRED with a logged todo entry, see the strake S_wet row above. |
| **[SWEEP-ANGLE CONVERSION — HEADLINE BUG-FIX CHECKS]** | | | | | | | | |
| Wing QC (25%c) sweep [deg] | L2 | 32.1832 | 28.1530 | +14.32% | N/A | DEFINITIONAL | readme_geom.md Table 3 | HEADLINE: was hardcoded 37 deg (bug), now computed ~32.2 deg via convert_sweep. No single Brandt cell for "wing QC sweep" exists in the comparison JSON; 28.153 deg is the closest available figure but reflects Brandt's EXPOSED-PANEL-based sweep definition, not our full-planform convert_sweep definition -- the ~4 deg gap is an expected, informative definitional difference (per IO's handoff notes), NOT a bug to chase down in this pass. |
| VT trailing-edge sweep [deg] | L2 | 22.9008 | 0.0000 | N/A | N/A | DEFINITIONAL | Brandt Main!H27 (hardcoded 0) | HEADLINE: the single-panel fix. convert_sweep's mirrored 4/AR form gave a physically impossible 0.33 deg here; convert_sweep_panel's 2/AR form gives 22.90 deg, confirmed against the repo's own VT chords (readme_geom.md Sec 4.3). Brandt's own cell is a hardcoded literal 0, inconsistent with his VT planform -- so the %Diff is meaningless and the CHECK is against the chord geometry, not against him. |
| VT trailing-edge sweep [deg] | L3 | 34.0052 | 0.0000 | N/A | N/A | DEFINITIONAL | Brandt Main!H27 (hardcoded 0) | Same single-panel form as L2, evaluated at the physical 47.5 deg LE sweep instead of Brandt's 40. |
| **[L1 STATISTICAL TIER — regressions on W_TO, no planform exists at this tier]** | | | | | | | | |
| Equivalent aspect ratio AR_eq [-] | L1 | 3.5187 | 3.0000 | +17.29% | N/A | DEFINITIONAL | Brandt Main!B19 (actual AR) | Raymer 7th ed. Table 4.1 dogfighter row, a function of design Mach only. It ESTIMATES what the AR ought to be for this mission; Brandt's 3.0 is the F-16's ACTUAL AR. +17% is the honest spread of a type-level regression, not an error -- L2/L3 read the real 3.0 from the spec file instead. |
| **[TOTALS]** | | | | | | | | |
| S_wet total, L1 statistical regression [ft^2] | L1 | 1763.02 | 1371.09 | +28.58% | N/A |  | Brandt Main!L3 (raw) | Roskam Vol.I Table 3.5 regression -- coarse by design |
| S_wet total, L2 OFFICIAL formula set    [ft^2] | L2 | 1466.77 | 1331.13 | +10.19% | N/A |  | readme_geom.md Sec 6.2 (corrected) | wing+HT+VT (Roskam Eq.12.1) + fuselage (Roskam Eq.12.3) + duct |
| S_wet total, L2 OFFICIAL vs RAW BUGGY  [ft^2] | L2 | 1466.77 | 1371.09 | +6.98% | N/A |  | Brandt Geom!B19 (raw, double-counts strake) | Brandt's own raw total double-counts the strake term (documented Excel bug, readme_geom.md Sec 6.2) -- corrected_total row above is the intended comparison target |
| S_wet total, Brandt-style formula set   [ft^2] | L2 | 1407.01 | 1331.13 | +5.70% | N/A |  | readme_geom.md Sec 6.2 (corrected) | wing+HT+VT (Brandt uniform-tc) + fuselage (Brandt high-fi) + duct -- closer to Brandt's own methodology |
| **[OTHER GEOMETRY OUTPUTS]** | | | | | | | | |
| Fuselage length L_fus [ft] | L2 | 46.5000 | N/A |  -  | N/A |  | f16a_L2.json .geometry (Brandt Main!B32) | Passthrough of the same Brandt Main-tab input the constructor reads -- reported for completeness, not an independent check |
| L_fus vs Brandt TOTAL aircraft length [ft] | L2 | 46.5000 | 48.3039 | -3.73% | N/A | DEFINITIONAL | Brandt Geom!B21 | DIFFERENT quantity: fuselage length only (46.5 ft) vs Brandt's total aircraft length (48.30 ft) -- see the dedicated L_aircraft row. |
| L1 fuselage length regression L_fus [ft] | L1 | 52.7426 | 46.5000 | +13.42% | N/A |  | F16GeomL2.L_fus (Brandt) | Raymer 6th ed. Table 6.3 statistical regression vs the Brandt-sourced L2 spec value |
| Max cross-section Amax, L2 envelope ellipse [ft^2] | L2 | 27.4889 | 25.1106 | +9.47% | N/A | DEFINITIONAL | Brandt Geom!B20/H47 | (pi/4)*W_max*H_max -- readme_geom.md Sec 7's LOW-fidelity Amax form, correct for the low-fidelity tier. DEFINITIONAL, not BY DESIGN: this is a fuselage-only envelope area, a different KIND of quantity from Brandt's whole-aircraft area-ruled max, so the two are not really comparable. Contrast the L3 row below, which computes the same kind of quantity Brandt does and differs only by the physical fuselage length. |
| Max cross-section Amax, L3 AREA-RULED [ft^2] | L3 | 24.7037 | 25.1106 | -1.62% | N/A | BY DESIGN | Brandt Geom!B20/H47 | Whole-aircraft buildup: MAX over 20 stations of (rescaled fuselage frames + wing/HT/VT cosine sections + nacelle) less n_eng*pi*D^2/5 -- the quantity Raymer Eq. 12.44 wants. ROUND-TRIP CONTROL (TestGeomL3): with L_fus set back to Brandt's own 46.5 this reproduces Geom!B20 to -0.0001%. The residual gap here is L3's 47.5 ft fuselage. |
| Wing reference area S_ref [ft^2] | L1 | 300.0 | 300.0 | +0.00% | N/A |  | Brandt Main!B18 | Hardcoded literal at L1 (no way to estimate it from geometry at this tier); a JSON spec input at L2/L3. |
| Wing reference area S_ref [ft^2] | L2 | 300.0 | 300.0 | +0.00% | N/A |  | Brandt Main!B18 | Passthrough of the spec input -- a plumbing check that the JSON reaches the property, not an independent result. |
| Wing reference area S_ref [ft^2] | L3 | 300.0 | 300.0 | +0.00% | N/A |  | Brandt Main!B18 | Identical to L2: the wing planform does not diverge between the tiers. |
| Overall aircraft length L_aircraft [ft] | L2 | 47.6500 | 48.3039 | -1.35% | 47.6458 | DEFINITIONAL | Brandt Geom!B21 | Same 47.65 spec input as L3; carried at both tiers because the Eq. 12.44 wave-drag term reads it at whichever tier is injected. |
| Overall aircraft length L_aircraft [ft] | L3 | 47.6500 | 48.3039 | -1.35% | 47.6458 | BY DESIGN | Brandt Geom!B21 | Published F-16A airframe length (47 ft 7.75 in). Brandt's 48.3039 is a MAX() over x-stations -- an EXTENT, not a spec length -- so the two are not the same quantity. Value user-approved; citation NOT pinned to any document in this repo (todo.md 2026-07-25 Phase 2 Sec 6, guarded by TestGeomL3.testTODO_OverallLengthCitationNotPinned). |
| **[L3 PHYSICAL / T.O. TIER — DIVERGENCES FROM BRANDT ARE INTENTIONAL]** | | | | | | | | |
| Fuselage length L_fus [ft] | L3 | 47.5000 | 46.5000 | +2.15% | 47.5000 | BY DESIGN | Brandt Main!B32 | DIVERGENCE 1 of 3. L3 uses the T.O. 1F-16A-1 fuselage length 47.5 ft where Brandt uses 46.5. Everything downstream that scales with fuselage length -- fuselage S_wet, total S_wet, and the area-ruled Amax -- inherits this +2.15%, which is why those rows are also BY DESIGN. |
| VT leading-edge sweep [deg] | L3 | 47.5000 | 40.0000 | +18.75% | 47.5000 | BY DESIGN | Brandt Main!H21 (= L2 value) | DIVERGENCE 2 of 3. L3 uses the T.O. 47.5 deg where Brandt/L2 use 40. Feeds the VT quarter-chord and trailing-edge sweeps and the L3 form factor; it does NOT move VT exposed area, which has no sweep term. |
| HT span [ft] | L3 | 18.5000 | 18.0000 | +2.78% | 18.5000 | BY DESIGN | F16GeomL2.b_ht = sqrt(AR*S) (= Brandt 3.0 AR) | DIVERGENCE 3 of 3. L3 takes the physical 18.5 ft span as the PRIMARY input, so AR_ht becomes DERIVED (18.5^2/108 = 3.1690) instead of Brandt's stated 3.0. L2 derives its 18.0 ft span from that 3.0 instead. Area and span are what a 3-view measures; aspect ratio is definitional. |
| Wing S_wet, Roskam Eq.12.1 [ft^2] | L3 | 396.3767 | 392.0204 | +1.11% | N/A |  | Brandt Geom!B14 | Wing planform is identical at L2 and L3 (no physical divergence), so this matches the L2 row exactly. |
| HT   S_wet, Roskam Eq.12.1 [ft^2] | L3 | 104.0349 | 99.5848 | +4.47% | N/A | BY DESIGN | Brandt Geom!B16 | Decomposes as +1.8% formula family (Roskam Eq.12.1 with T.O. root/tip t/c vs Brandt's uniform t/c) and +2.6% exposed area (the 18.5 ft T.O. span taken as primary). Not one large error. |
| VT   S_wet, Roskam Eq.12.1 [ft^2] | L3 | 83.1398 | 81.6894 | +1.78% | N/A | BY DESIGN | Brandt Geom!B17 | VT exposed area is sweep-independent, so this differs from L2 only by formula family. |
| Fuselage S_wet, Roskam Eq.12.3 [ft^2] | L3 | 749.1337 | 676.3289 | +10.76% | 47.5000 | BY DESIGN | Brandt Geom!D23 | L3 fuselage is 47.5 ft [T.O. 1F-16A-1] vs Brandt's 46.5 -- a longer fuselage has more wetted area. |
| Duct S_wet [ft^2] | L3 | 155.5664 | 41.5150 | +274.72% | N/A |  | Brandt Geom!B4 (nacelle) | Same frustum model and same injected thrust as L2 -- identical to the L2 duct row. |
| S_wet total, L3 (incl. duct) [ft^2] | L3 | 1488.25 | 1331.13 | +11.80% | N/A | BY DESIGN | readme_geom.md Sec 6.2 (corrected) | Phase 2 changed GeomL3.get_S_wet to INCLUDE the duct (it was airframe-only). |
| Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft] | L3 | 3.537022 | 3.537000 | +0.00% | N/A |  | Brandt Engn(s) tab | Same injected prop.T_SL and same formula as L2 -- identical by construction, and a positive control that the propulsion DI reaches both tiers. |
| Wing exposed area [ft^2] | L3 | 196.2261 | 196.2261 | -0.00% | N/A |  | Brandt Geom!7 | Wing planform is identical at L2 and L3, so this matches the L2 row exactly. |
| HT exposed area [ft^2] | L3 | 51.1486 | 49.8473 | +2.61% | N/A | BY DESIGN | Brandt Geom!8 | Derived from S_ht=108 + the T.O. span 18.5 (option B), so AR_ht is derived rather than Brandt's 3.0. |
| VT exposed area [ft^2] | L3 | 40.8897 | 40.8897 | -0.00% | N/A |  | Brandt Geom!10 | Sweep does not enter the exposed-area clip, so L3 matches L2 and Brandt exactly despite the 47.5 deg LE sweep. |
| HT aspect ratio AR_ht (DERIVED) [-] | L3 | 3.1690 | 3.0000 | +5.63% | N/A | BY DESIGN | Brandt Main!C19 | DERIVED = B_h^2/S_ht = 18.5^2/108. Area and span are what a 3-view measures; aspect ratio is definitional. Brandt's 3.0 implies an 18.0 ft span, contradicting the physical 18.5. |
| VT quarter-chord sweep [deg] | L3 | 44.6293 | N/A |  -  | 47.5000 | BY DESIGN | no Brandt cell | Single-panel (2/AR) conversion at the physical 47.5 deg LE sweep. The mirrored (4/AR) wing form is wrong for a one-panel surface -- it gave the F-16 a physically impossible 0.33 deg VT trailing-edge sweep before Phase 1. |

**Whole-aircraft `S_wet` total:** Brandt's own RAW total (`Geom!B19`) double-counts the strake wetted area — a documented Excel bug — so the CORRECTED total is the intended comparison target.

**Not modelled:** the strake (`S_wet` and exposed area) has no component in any geometry tier. Deferred rather than overlooked: sub-step 2h proved it contributes exactly 0.000 % to `Amax`, since it is active only forward of the governing station.


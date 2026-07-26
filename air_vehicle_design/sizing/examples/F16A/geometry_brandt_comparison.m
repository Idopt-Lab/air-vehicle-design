function T_all = geometry_brandt_comparison()
%GEOMETRY_BRANDT_COMPARISON  F-16A Block 10 — Geometry vs Brandt ground truth.
%
%   NOT A TEST. No pass/fail assertions, not part of run_all_tests. A pure
%   reporting script: loads the F-16A L1/L2/L3 input JSONs, runs the actual
%   F16GeomL1/L2/L3 methods and GeomL2 static toolbox
%   calls, and compares against the `geometry` section of
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json — the Brandt-DIRECT
%   ground truth (NOT F16Baseline.m's older T.O.-manual-based figures, which
%   fidelity_comparison.m uses instead).
%
%   Where a physical quantity has multiple implementation options (e.g.
%   wing/HT/VT S_wet via Roskam Eq. 12.1 vs Brandt's own uniform-tc formula;
%   fuselage S_wet via Roskam Eq. 12.3 vs Brandt low-fi vs Brandt high-fi),
%   each option gets its own row — never just the "official" one.
%
%   Outputs (written to the same directory as this script):
%     geometry_brandt_comparison.json  — full table + metadata
%     geometry_brandt_comparison.md    — rendered markdown table
%
%   REFERENCE SOURCES:
%     [Brandt]  S. Brandt, F-16A.xls workbook, via the geometry section of
%               VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json
%               and f16a_geometry.json
%     [Roskam]  J. Roskam, Airplane Design Vol. II, DARcorp., 1997 (Eq. 12.1, 12.3)
%     [Raymer]  D.P. Raymer, Aircraft Design 6th/7th ed., AIAA (Sec 7.3; Table 4.1/6.4/6.5)

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
frames_path = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_geometry.json');
gt          = jsondecode(fileread(gt_path)).geometry;   % geometry section of the unified ground-truth file
J_frames    = jsondecode(fileread(frames_path));

% W_TO sourced directly from the Brandt JSON (f16a_geometry.json, already
% loaded above as J_frames) rather than F16Baseline.m -- that file is the
% older T.O.-manual-based ground truth this script deliberately avoids
% elsewhere (see header comment) and is slated for removal.
W_TO = J_frames.mission.W_TO_lb;   % 31,377 lbf  [Brandt Main! mission W_TO_lb]

% Geometry now takes the propulsion object (Phase 2, 2026-07-25): the nacelle
% diameter -- and so duct wetted area and total S_wet -- is sized from engine
% thrust, which is engine data and no longer a geometry input.
prop = F16PropL2(f16a_spec_path(2));
g1 = F16GeomL1(f16a_spec_path(1));
g2 = F16GeomL2(f16a_spec_path(2), prop);
g3 = F16GeomL3(f16a_spec_path(3), prop);

% ════════════════════════════════════════════════════════════════════════ %
%  COMPUTE — run the actual toolbox code
% ════════════════════════════════════════════════════════════════════════ %

% ── L1 statistical regression ──────────────────────────────────────────── %
sw_l1   = g1.get_S_wet(W_TO);
lfus_l1 = g1.get_L_fus(W_TO);

% ── Wing/HT/VT S_wet: two formula options each ─────────────────────────── %
sw_wing_roskam = g2.get_S_wet_wing();                                        % OFFICIAL: Roskam Eq. 12.1
sw_wing_brandt = GeomL2.compute_wet_planform(g2.S_exposed_wing, g2.tc_wing); % alternate: Brandt uniform-tc
sw_ht_roskam   = g2.get_S_wet_HT();
sw_ht_brandt   = GeomL2.compute_wet_planform(g2.S_exposed_ht, g2.tc_ht);
sw_vt_roskam   = g2.get_S_wet_VT();
sw_vt_brandt   = GeomL2.compute_wet_planform(g2.S_exposed_vt, g2.tc_vt);

% ── Fuselage S_wet: three formula options ──────────────────────────────── %
sw_fus_roskam = g2.get_S_wet_fuselage();                                                            % OFFICIAL: Roskam Eq. 12.3
sw_fus_lowfi  = GeomL2.compute_s_wet_fus_brandt_lowfi(g2.W_max_fuselage, g2.H_max_fuselage, g2.L_fuselage);
fr            = J_frames.fuselage.frames;
sw_fus_highfi = GeomL2.compute_s_wet_fus_brandt_highfi( ...
    [fr.x_ft], [fr.z_chine_ft], [fr.z_ft], [fr.w_ft], [fr.h_ft]);

% ── Duct / nacelle ──────────────────────────────────────────────────────── %
sw_duct    = g2.get_S_wet_duct();
D_nacelle  = g2.D_inlet;   % = D_exit, computed via sqrt(T_AB_SLS_lb/1900)

% ── Exposed areas (full JSON-to-property pipeline) ─────────────────────── %
exp_wing = g2.S_exposed_wing;
exp_ht   = g2.S_exposed_ht;
exp_vt   = g2.S_exposed_vt;

% ── Sweep-conversion headline check ─────────────────────────────────────── %
qc_sweep_wing = g2.QC_sweep_wing;

% ── Totals ────────────────────────────────────────────────────────────── %
% total_official: call g2.get_S_wet() directly rather than re-summing the
% five official components by hand -- get_S_wet() IS that sum (verified by
% TestGeomL2's testTotalSwetEqualsSum), so this also doubles as a live check
% that get_S_wet()'s own aggregation hasn't drifted from the individual
% component methods used elsewhere in this script.
total_official     = g2.get_S_wet();
% total_brandt_style has no single method call -- it mixes the Brandt
% uniform-tc wing/HT/VT formula with the Brandt high-fi fuselage formula,
% a combination get_S_wet() doesn't compute (it always uses the official
% Roskam formulas) -- so this one stays a manual sum.
total_brandt_style = sw_wing_brandt + sw_ht_brandt + sw_vt_brandt + sw_fus_highfi + sw_duct;

% ── L_fus vs Brandt's total-aircraft-length figure (different quantities) %
L_fus_computed = g2.L_fus;

% ── L3: the PHYSICAL / T.O. geometry tier (Phase 2, 2026-07-25) ────────── %
% GeomL3 is NOT "L2 with more decimals" -- where a physical/T.O. value differs
% from Brandt's, it uses the physical one. Rows below carrying Divergence =
% 'BY DESIGN' are those deliberate differences and must NOT be read as errors:
%   VT LE sweep  47.5 deg  vs L2/Brandt 40      [T.O. 1F-16A-1]
%   L_fus        47.5 ft   vs L2/Brandt 46.5    [T.O. 1F-16A-1]
%   HT span      18.5 ft   taken as the PRIMARY span [USAF 3-view], so AR_ht
%                is DERIVED (18.5^2/108 = 3.1690) rather than Brandt's 3.0
% L3 also uses Roskam Eq. 12.1 fed the T.O. root/tip t/c splits, where Brandt
% uses one uniform t/c -- so its lifting-surface S_wet sits ~1.8% above his by
% formula family alone, on top of any planform divergence.
sw_wing_l3 = g3.get_S_wet_wing();
sw_ht_l3   = g3.get_S_wet_HT();
sw_vt_l3   = g3.get_S_wet_VT();
sw_fus_l3  = g3.get_S_wet_fuselage();
sw_duct_l3 = g3.get_S_wet_duct();
total_l3   = g3.get_S_wet();          % includes the duct (changed in Phase 2)
exp_wing_l3 = g3.S_exposed_wing;
exp_ht_l3   = g3.S_exposed_ht;        % 51.1486: +2.6% vs Brandt, from the 18.5 ft span
exp_vt_l3   = g3.S_exposed_vt;        % 40.8897: identical to L2 (no sweep dependence)
AR_ht_l3    = g3.AR_ht;               % DERIVED 3.1690 vs Brandt Main!C19 = 3.0
qc_sweep_vt_l3 = g3.QC_sweep_vt;      % single-panel form at the physical 47.5 deg LE

% ── Amax + overall length: no longer "NOT MODELED" ─────────────────────── %
% Both tiers compute Amax, DELIBERATELY by different definitions:
%   L2  = fuselage-envelope ellipse (pi/4)*W*H          -- readme_geom.md Sec 7's
%         LOW-fidelity form. Correct for the low-fidelity tier.
%   L3  = whole-aircraft AREA-RULED buildup (MAX over 20 stations of rescaled
%         fuselage frames + wing/HT/VT cosine sections + nacelle, less the
%         engine flow-through) -- the quantity Raymer Eq. 12.44 actually wants.
% The L3 round-trip control lives in TestGeomL3: setting L_fus back to Brandt's
% own 46.5 reproduces Geom!B20 to -0.0001%. At the as-built 47.5 it lands at
% 24.7037 (-1.62%), a physical fidelity divergence.
Amax_l2       = g2.Amax;
Amax_l3       = g3.Amax;
L_aircraft_l3 = g3.L_aircraft;   % L2 carries the same 47.65 input; one row suffices

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %

T = table();

T = [T; srow('[WING / HT / VT WETTED AREA — TWO FORMULA OPTIONS EACH]')];
T = [T; grow('Wing S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_wing_roskam, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', 'get_S_wet_wing()')];
T = [T; grow('Wing S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_wing_brandt, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('HT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_ht_roskam, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', 'get_S_wet_HT()')];
T = [T; grow('HT   S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_ht_brandt, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('VT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_vt_roskam, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', 'get_S_wet_VT()')];
T = [T; grow('VT   S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_vt_brandt, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('Strake S_wet -- NOT MODELED           [ft^2]', 'N/A', NaN, gt.lifting_surface_S_wet_ft2.strake.value, 'Brandt Geom!B15', '%.4f', 'No strake component exists in any geometry tier. DEFERRED, not overlooked: sub-step 2h proved the strake contributes exactly 0.000% to Amax (active only 12.0 < x < 21.551 ft, well forward of the governing station), so it was descoped from 2h and logged for its own step.')];

T = [T; srow('[FUSELAGE WETTED AREA — THREE FORMULA OPTIONS]')];
T = [T; grow('Fuselage S_wet, Roskam Eq.12.3 [OFFICIAL] [ft^2]', 'L2', sw_fus_roskam, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', 'get_S_wet_fuselage() -- equivalent-diameter cylinder model; compared vs Brandt''s high-fi (closest formula family)')];
T = [T; grow('Fuselage S_wet, Brandt low-fi [alt]   [ft^2]', 'L2', sw_fus_lowfi, gt.fuselage_S_wet.low_fi_ft2, 'Brandt Geom!B3', '%.4f', 'compute_s_wet_fus_brandt_lowfi() -- reproduces Brandt''s own "1/3-cone+2/3-cyl" formula')];
T = [T; grow('Fuselage S_wet, Brandt high-fi [alt]  [ft^2]', 'L2', sw_fus_highfi, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', 'compute_s_wet_fus_brandt_highfi() -- reproduces Brandt''s own frame-integration formula')];

T = [T; srow('[DUCT / NACELLE]')];
T = [T; grow('Duct S_wet (inlet-to-exit frustum)     [ft^2]', 'L2', sw_duct, gt.nacelle.S_wet_ft2, 'Brandt Geom!B4 (nacelle)', '%.4f', 'DIFFERENT quantity: exposed inlet-to-exit frustum vs Brandt''s full-cylinder nacelle -- the %Diff is not a meaningful error measure here.', NaN, 'DEFINITIONAL')];
T = [T; grow('Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft]', 'L2', D_nacelle, gt.nacelle.diameter_ft, 'Brandt Engn(s) tab', '%.6f', 'Same formula as Brandt -- should match near-exactly (positive control)')];

T = [T; srow('[EXPOSED LIFTING-SURFACE AREAS]')];
T = [T; grow('Wing exposed area  [ft^2]', 'L2', exp_wing, gt.lifting_surface_exposed_areas.wing.exposed_S_ft2, 'Brandt Geom!7', '%.4f', 'compute_S_exposed_horizontal() via F16GeomL2 constructor')];
T = [T; grow('HT   exposed area  [ft^2]', 'L2', exp_ht, gt.lifting_surface_exposed_areas.pitch_control_HT.exposed_S_ft2, 'Brandt Geom!8', '%.4f', 'compute_S_exposed_horizontal() via F16GeomL2 constructor')];
T = [T; grow('VT   exposed area  [ft^2]', 'L2', exp_vt, gt.lifting_surface_exposed_areas.vertical_tail.exposed_S_ft2, 'Brandt Geom!10', '%.4f', 'compute_S_exposed_vertical() via F16GeomL2 constructor')];
T = [T; grow('Strake exposed area -- NOT MODELED [ft^2]', 'N/A', NaN, gt.lifting_surface_exposed_areas.strake.exposed_S_ft2, 'Brandt Geom!9', '%.4f', 'No strake component exists in this framework -- DEFERRED with a logged todo entry, see the strake S_wet row above.')];

T = [T; srow('[SWEEP-ANGLE CONVERSION — HEADLINE BUG-FIX CHECK]')];
T = [T; grow('Wing QC (25%c) sweep [deg]', 'L2', qc_sweep_wing, gt.wing_sweep_25pct_chord_deg.value, 'readme_geom.md Table 3', '%.4f', ...
    ['HEADLINE: was hardcoded 37 deg (bug), now computed ~32.2 deg via convert_sweep. No single Brandt cell for ' ...
     '"wing QC sweep" exists in the comparison JSON; 28.153 deg is the closest available figure but reflects Brandt''s ' ...
     'EXPOSED-PANEL-based sweep definition, not our full-planform convert_sweep definition -- the ~4 deg gap is an ' ...
     'expected, informative definitional difference (per IO''s handoff notes), NOT a bug to chase down in this pass.'])];

T = [T; srow('[TOTALS]')];
T = [T; grow('S_wet total, L1 statistical regression [ft^2]', 'L1', sw_l1, gt.whole_aircraft_S_wet_ft2.raw_buggy_total, 'Brandt Main!L3 (raw)', '%.2f', 'Roskam Vol.I Table 3.5 regression -- coarse by design')];
T = [T; grow('S_wet total, L2 OFFICIAL formula set    [ft^2]', 'L2', total_official, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', 'wing+HT+VT (Roskam Eq.12.1) + fuselage (Roskam Eq.12.3) + duct')];
T = [T; grow('S_wet total, L2 OFFICIAL vs RAW BUGGY  [ft^2]', 'L2', total_official, gt.whole_aircraft_S_wet_ft2.raw_buggy_total, 'Brandt Geom!B19 (raw, double-counts strake)', '%.2f', 'Brandt''s own raw total double-counts the strake term (documented Excel bug, readme_geom.md Sec 6.2) -- corrected_total row above is the intended comparison target')];
T = [T; grow('S_wet total, Brandt-style formula set   [ft^2]', 'L2', total_brandt_style, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', 'wing+HT+VT (Brandt uniform-tc) + fuselage (Brandt high-fi) + duct -- closer to Brandt''s own methodology')];

T = [T; srow('[OTHER GEOMETRY OUTPUTS]')];
T = [T; grow('Fuselage length L_fus [ft]', 'L2', L_fus_computed, NaN, 'f16a_L2.json .geometry (Brandt Main!B32)', '%.4f', 'Passthrough of the same Brandt Main-tab input the constructor reads -- reported for completeness, not an independent check')];
T = [T; grow('L_fus vs Brandt TOTAL aircraft length [ft]', 'L2', L_fus_computed, gt.aircraft_length_ft.value, 'Brandt Geom!B21', '%.4f', 'DIFFERENT quantity: fuselage length only (46.5 ft) vs Brandt''s total aircraft length (48.30 ft) -- see the dedicated L_aircraft row.', NaN, 'DEFINITIONAL')];
T = [T; grow('L1 fuselage length regression L_fus [ft]', 'L1', lfus_l1, L_fus_computed, 'F16GeomL2.L_fus (Brandt)', '%.4f', 'Raymer 6th ed. Table 6.3 statistical regression vs the Brandt-sourced L2 spec value')];
T = [T; grow('Max cross-section Amax, L2 envelope ellipse [ft^2]', 'L2', Amax_l2, gt.Amax_ft2.value, 'Brandt Geom!B20/H47', '%.4f', ...
    ['(pi/4)*W_max*H_max -- readme_geom.md Sec 7''s LOW-fidelity Amax form, correct for the low-fidelity tier. ' ...
     'DEFINITIONAL, not BY DESIGN: this is a fuselage-only envelope area, a different KIND of quantity from ' ...
     'Brandt''s whole-aircraft area-ruled max, so the two are not really comparable. Contrast the L3 row below, ' ...
     'which computes the same kind of quantity Brandt does and differs only by the physical fuselage length.'], ...
     NaN, 'DEFINITIONAL')];
T = [T; grow('Max cross-section Amax, L3 AREA-RULED [ft^2]', 'L3', Amax_l3, gt.Amax_ft2.value, 'Brandt Geom!B20/H47', '%.4f', ...
    ['Whole-aircraft buildup: MAX over 20 stations of (rescaled fuselage frames + wing/HT/VT cosine sections + nacelle) ' ...
     'less n_eng*pi*D^2/5 -- the quantity Raymer Eq. 12.44 wants. ROUND-TRIP CONTROL (TestGeomL3): with L_fus set back ' ...
     'to Brandt''s own 46.5 this reproduces Geom!B20 to -0.0001%. The residual gap here is L3''s 47.5 ft fuselage.'], ...
     NaN, 'BY DESIGN')];
T = [T; grow('Overall aircraft length L_aircraft [ft]', 'L3', L_aircraft_l3, gt.aircraft_length_ft.value, 'Brandt Geom!B21', '%.4f', ...
    ['Published F-16A airframe length (47 ft 7.75 in). Brandt''s 48.3039 is a MAX() over x-stations -- an EXTENT, ' ...
     'not a spec length -- so the two are not the same quantity. Value user-approved; citation NOT pinned to any ' ...
     'document in this repo (todo.md 2026-07-25 Phase 2 Sec 6, guarded by TestGeomL3.testTODO_OverallLengthCitationNotPinned).'], ...
     47.65, 'BY DESIGN')];

T = [T; srow('[L3 PHYSICAL / T.O. TIER — DIVERGENCES FROM BRANDT ARE INTENTIONAL]')];
T = [T; grow('Wing S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_wing_l3, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', ...
    'Wing planform is identical at L2 and L3 (no physical divergence), so this matches the L2 row exactly.')];
T = [T; grow('HT   S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_ht_l3, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', ...
    ['Decomposes as +1.8% formula family (Roskam Eq.12.1 with T.O. root/tip t/c vs Brandt''s uniform t/c) ' ...
     'and +2.6% exposed area (the 18.5 ft T.O. span taken as primary). Not one large error.'], NaN, 'BY DESIGN')];
T = [T; grow('VT   S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_vt_l3, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', ...
    'VT exposed area is sweep-independent, so this differs from L2 only by formula family.', NaN, 'BY DESIGN')];
T = [T; grow('Fuselage S_wet, Roskam Eq.12.3 [ft^2]', 'L3', sw_fus_l3, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', ...
    'L3 fuselage is 47.5 ft [T.O. 1F-16A-1] vs Brandt''s 46.5 -- a longer fuselage has more wetted area.', 47.5, 'BY DESIGN')];
T = [T; grow('Duct S_wet [ft^2]', 'L3', sw_duct_l3, gt.nacelle.S_wet_ft2, 'Brandt Geom!B4 (nacelle)', '%.4f', ...
    'Same frustum model and same injected thrust as L2 -- identical to the L2 duct row.')];
T = [T; grow('S_wet total, L3 (incl. duct) [ft^2]', 'L3', total_l3, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', ...
    'Phase 2 changed GeomL3.get_S_wet to INCLUDE the duct (it was airframe-only).', NaN, 'BY DESIGN')];
T = [T; grow('HT exposed area [ft^2]', 'L3', exp_ht_l3, gt.lifting_surface_exposed_areas.pitch_control_HT.exposed_S_ft2, 'Brandt Geom!8', '%.4f', ...
    'Derived from S_ht=108 + the T.O. span 18.5 (option B), so AR_ht is derived rather than Brandt''s 3.0.', NaN, 'BY DESIGN')];
T = [T; grow('VT exposed area [ft^2]', 'L3', exp_vt_l3, gt.lifting_surface_exposed_areas.vertical_tail.exposed_S_ft2, 'Brandt Geom!10', '%.4f', ...
    'Sweep does not enter the exposed-area clip, so L3 matches L2 and Brandt exactly despite the 47.5 deg LE sweep.')];
T = [T; grow('HT aspect ratio AR_ht (DERIVED) [-]', 'L3', AR_ht_l3, 3.0, 'Brandt Main!C19', '%.4f', ...
    ['DERIVED = B_h^2/S_ht = 18.5^2/108. Area and span are what a 3-view measures; aspect ratio is definitional. ' ...
     'Brandt''s 3.0 implies an 18.0 ft span, contradicting the physical 18.5.'], NaN, 'BY DESIGN')];
T = [T; grow('VT quarter-chord sweep [deg]', 'L3', qc_sweep_vt_l3, NaN, 'no Brandt cell', '%.4f', ...
    ['Single-panel (2/AR) conversion at the physical 47.5 deg LE sweep. The mirrored (4/AR) wing form is wrong for a ' ...
     'one-panel surface -- it gave the F-16 a physically impossible 0.33 deg VT trailing-edge sweep before Phase 1.'], ...
     47.5, 'BY DESIGN')];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %

now_str = char(datetime('now', 'Format', 'yyyy-MM-dd'));
BAR     = repmat('=', 1, 110);

fprintf('\n%s\n', BAR);
fprintf('  F-16A BLOCK 10 -- GEOMETRY vs BRANDT GROUND TRUTH\n');
fprintf('  W_TO = %.0f lbf [Brandt B38]  |  Generated %s\n', W_TO, now_str);
fprintf('  Source: VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.geometry] (Brandt-direct, NOT F16Baseline.m)\n');
fprintf('%s\n\n', BAR);

disp(T);

fprintf('  NOTES\n');
fprintf('  Wing/HT/VT S_wet: OFFICIAL = Roskam Eq.12.1 (variable root/tip tc); alt = Brandt''s own\n');
fprintf('    uniform-tc formula (compute_wet_planform) -- the alt option matches Brandt near-exactly\n');
fprintf('    by construction (it IS Brandt''s formula fed Brandt''s own inputs).\n');
fprintf('  Fuselage S_wet: OFFICIAL = Roskam Eq.12.3 (equivalent-diameter cylinder); two Brandt\n');
fprintf('    alternates (low-fi ''1/3-cone+2/3-cyl'', high-fi frame-integration) are also available.\n');
fprintf('  Duct/nacelle %%Diff is large by definition (different physical quantities), not a bug.\n');
fprintf('  Wing QC sweep: the historical 37 deg hardcoded bug is fixed (now ~32.2 deg); see that\n');
fprintf('    row''s Notes for why the ~28.15 deg Brandt comparison figure isn''t an exact match target.\n');
fprintf('  Whole-aircraft S_wet total: Brandt''s own RAW total (Geom!B19) double-counts the strake\n');
fprintf('    wetted area (documented Excel bug) -- the CORRECTED total is the intended comparison target.\n');
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %

out_json = fullfile(script_dir, 'geometry_brandt_comparison.json');
out_md   = fullfile(script_dir, 'geometry_brandt_comparison.md');

data.generated = now_str;
data.aircraft  = 'F-16A Block 10';
data.W_TO_lbf  = W_TO;
data.source    = 'VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.geometry]';
data.rows      = table_to_rows(T);

fid = fopen(out_json, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON     -> %s\n', out_json);

write_markdown(T, out_md, W_TO, now_str);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

% ─── local helpers ───────────────────────────────────────────────────── %

function T = grow(name, fidelity, computed, expected, src, numfmt, notes, to_value, divergence)
%GROW  One comparison row.
%   Columns: Fidelity / Computed / Brandt / PctDiff / TO / Divergence / Source / Notes.
%
%   fidelity   — which Geometry tier produced `computed` ('L1'/'L2'/'L3'), or 'N/A' for a
%                quantity nothing models (Computed is NaN in that case too).
%   to_value   — OPTIONAL second source: T.O. 1F-16A-1 / USAF 3-view. NaN or omitted -> 'N/A'.
%                Brandt is not the only ground truth, and where the two disagree the L3 tier
%                deliberately follows the T.O. value -- this column is what makes that visible
%                instead of looking like framework error.
%   divergence — OPTIONAL annotation, three states:
%                'BY DESIGN'    — same KIND of quantity as Brandt's, but the framework is expected
%                                 to differ because L3 follows a physical/T.O. value where Brandt
%                                 uses his own, or because a different formula family is in use.
%                                 The %Diff is meaningful and should be small-ish.
%                'DEFINITIONAL' — a different kind of quantity altogether (e.g. the L2 fuselage-only
%                                 Amax vs Brandt's whole-aircraft area-ruled Amax; our exposed
%                                 inlet-to-exit duct vs Brandt's full-cylinder nacelle). The %Diff
%                                 is NOT a meaningful error measure at all -- do not chase it.
%                blank          — a genuine agreement check; a large %Diff here IS worth chasing.
%                The distinction matters: 'BY DESIGN' invites you to sanity-check the magnitude,
%                'DEFINITIONAL' tells you the comparison itself is apples-to-oranges.
%
%   This report is INFORMATIONAL ONLY -- never pass/fail, and never a source for a unit test's
%   expected value (CLAUDE.md's two-tier rule).
    if nargin < 7; notes      = '';  end
    if nargin < 8; to_value   = NaN; end
    if nargin < 9; divergence = '';  end
    if isnan(computed)
        comp_s = 'N/A';
    else
        comp_s = sprintf(numfmt, computed);
    end
    if isnan(expected)
        exp_s = 'N/A';
        err_s = ' - ';
    else
        exp_s = sprintf(numfmt, expected);
        if isnan(computed)
            err_s = ' - ';
        elseif expected ~= 0
            err_s = sprintf('%+.2f%%', 100*(computed - expected)/expected);
        else
            err_s = 'N/A';
        end
    end
    if isnan(to_value)
        to_s = 'N/A';
    else
        to_s = sprintf(numfmt, to_value);
    end
    T = table({fidelity}, {comp_s}, {exp_s}, {err_s}, {to_s}, {divergence}, {src}, {notes}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'TO', 'Divergence', 'Source', 'Notes'}, ...
        'RowNames', {name});
end

function T = srow(label)
%SROW  Section separator row.
    T = table({'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'TO', 'Divergence', 'Source', 'Notes'}, ...
        'RowNames', {label});
end

function rows = table_to_rows(T)
%TABLE_TO_ROWS  Convert the comparison table to a struct array for jsonencode.
    n = height(T);
    for r = n:-1:1   % reverse iteration pre-allocates the struct array
        rows(r).parameter  = T.Properties.RowNames{r};
        rows(r).Fidelity   = T.Fidelity{r};
        rows(r).Computed   = T.Computed{r};
        rows(r).Brandt     = T.Brandt{r};
        rows(r).PctDiff    = T.PctDiff{r};
        rows(r).TO         = T.TO{r};
        rows(r).Divergence = T.Divergence{r};
        rows(r).Source     = T.Source{r};
        rows(r).Notes      = T.Notes{r};
    end
end

function write_markdown(T, out_path, W_TO, now_str)
%WRITE_MARKDOWN  Render the comparison table as a markdown file.
    fid = fopen(out_path, 'w');
    fprintf(fid, '# F-16A Block 10 — Geometry vs Brandt Ground Truth\n\n');
    fprintf(fid, 'Generated %s. W_TO = %.0f lbf [Brandt B38].\n\n', now_str, W_TO);
    fprintf(fid, ['Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.geometry`] ' ...
        '(Brandt-direct ground truth -- NOT `F16Baseline.m`, which is the older T.O.-manual-based ' ...
        'ground truth used by `fidelity_comparison.m`).\n\n']);
    fprintf(fid, ['This is a **comparison report**, not a test -- no pass/fail assertions, and nothing here ' ...
        'may ever be used to backfill a unit test''s expected value. Where a quantity has multiple ' ...
        'implementation options, each option gets its own row.\n\n']);
    fprintf(fid, ['**Reading the `Divergence` column.** `BY DESIGN` marks a row where the framework is ' ...
        '*expected* to differ from Brandt -- because L3 is the physical/T.O. tier and uses a T.O. value ' ...
        'where Brandt uses his own, because a different formula family is in use, or because the two ' ...
        'sides are definitionally different quantities. **A large %%Diff on a `BY DESIGN` row is the ' ...
        'correct answer, not a defect.** Blank means it is a genuine agreement check. The `TO` column ' ...
        'carries the T.O. 1F-16A-1 / USAF 3-view figure where one exists -- Brandt is not the only ' ...
        'ground truth, and where the two disagree L3 deliberately follows the T.O. value.\n\n']);
    fprintf(fid, '| Parameter | Fidelity | Computed | Brandt | %%Diff | T.O. | Divergence | Source | Notes |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|---|---|\n');
    n = height(T);
    for r = 1:n
        name = T.Properties.RowNames{r};
        if strcmp(T.Computed{r}, '---')
            fprintf(fid, '| **%s** | | | | | | | | |\n', strrep(name, '|', '\|'));
        else
            fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n', ...
                strrep(name, '|', '\|'), T.Fidelity{r}, T.Computed{r}, T.Brandt{r}, T.PctDiff{r}, ...
                T.TO{r}, T.Divergence{r}, ...
                strrep(T.Source{r}, '|', '\|'), strrep(T.Notes{r}, '|', '\|'));
        end
    end
    fclose(fid);
end

function T_all = geometry_brandt_comparison()
%GEOMETRY_BRANDT_COMPARISON  F-16A geometry at every fidelity vs ground truth.
%
%   Two jobs. (1) A one-stop comparison: run every geometry tier and put its
%   output next to Brandt's workbook and the T.O. 1F-16A-1. (2) A worked
%   example of how to drive this framework — read it top to bottom and you have
%   seen the whole input and dependency-injection story for geometry.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> geometry_brandt_comparison
%   Or non-interactively, which is what you want if a table is wide enough to
%   make the MATLAB pager hang:
%     $ matlab -batch "addpath(genpath('src')); addpath(genpath('examples')); geometry_brandt_comparison"
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%   Never hardcode a path. Two helpers resolve everything:
%     f16a_spec_path(N)        -> examples/F16A/f16a_L{N}.json, the SPEC file:
%                                 what the aircraft IS (areas, AR, sweeps, t/c,
%                                 fuselage envelope). One file per fidelity
%                                 level; geometry reads its .geometry block.
%     f16a_requirements_path() -> examples/F16A/f16a_requirements.json, the
%                                 REQUIREMENTS file: what the aircraft must DO
%                                 (design Mach, cruise condition). NOT per-
%                                 fidelity — requirements do not vary with it.
%   Ground truth is separate from both and lives under VnV/BrandtF16A/, read
%   here as `gt`. It is never an input to the framework — only a comparison
%   target. Do not let a ground-truth number become an input.
%
%   ─── HOW TO WIRE THE DEPENDENCIES ───────────────────────────────────────
%   Order matters, because each object is injected into the next:
%
%       prop = F16PropL2(f16a_spec_path(2));            % 1. no dependencies
%       g1   = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
%       g2   = F16GeomL2(f16a_spec_path(2), prop);      % 2. needs propulsion
%       g3   = F16GeomL3(f16a_spec_path(3), prop);
%
%   Why geometry needs propulsion: the nacelle diameter is sized from engine
%   SLS thrust, so duct wetted area and CD0 depend on it. `T_AB_SLS_lb` is
%   Dependent on `prop.T_SL` rather than a stored copy — change the thrust and
%   the drag follows. Every constructor argument is REQUIRED; there are no
%   silent defaults, because a defaulted injection silently re-freezes the very
%   coupling this design exists to express.
%
%   Why L1 takes a second path instead of a propulsion object: L1 has no
%   planform at all, so there is no nacelle to size. What it does need is the
%   design Mach, which is a requirement, not spec data.
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     geometry_brandt_comparison.json  full table + metadata
%     geometry_brandt_comparison.md    rendered markdown
%   Both are produced by src/reporting/ComparisonReport.m, shared by all four
%   discipline reports so their columns cannot drift apart.
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]  S. Brandt, F-16A.xls, via VnV/BrandtF16A/GroundTruth/
%               f16a_ground_truth.json (.geometry) and f16a_geometry.json
%     [T.O.]    T.O. 1F-16A-1 flight manual / USAF 3-view
%     [Roskam]  Airplane Design Vol. II, DARcorp., 1997 (Eq. 12.1, 12.3)
%     [Raymer]  Aircraft Design 6th/7th ed., AIAA (Sec. 7.3; Table 4.1/6.3)
%
%   NOT A TEST: informational only, never pass/fail, and no value here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule).

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
g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
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
L_aircraft_l2 = g2.L_aircraft;
L_aircraft_l3 = g3.L_aircraft;

% ── Remaining per-tier quantities, so every tier that computes a quantity is
%    reported at that tier rather than assumed identical to the one above it.
% Brandt Main-tab GIVEN inputs, used as the Reference on rows where the
% framework value is a passthrough or a deliberate physical divergence.
gt_S_ref        = gt.inputs_on_Main_tab.wing.S_ft2;        % 300
gt_L_fus_brandt = gt.inputs_on_Main_tab.fuselage.length_ft; % 46.5
% T.O. 1F-16A-1 / USAF 3-view figures -> the 2nd Source column. These are the
% SAME numbers f16a_L3.json carries as inputs: one shared physical truth,
% recorded here as a named second source so a BY-DESIGN divergence from Brandt
% is visibly backed by a document rather than looking like framework error.
to_HT_span   = gt.to_1f16a1.HT_span_ft.value;         % 18.5
to_VT_sweep  = gt.to_1f16a1.VT_sweep_LE_deg.value;    % 47.5
to_L_fus     = gt.to_1f16a1.fuselage_length_ft.value; % 47.5
to_L_overall = gt.to_1f16a1.overall_length_ft.value;  % 47.65

AR_eq_l1       = g1.get_AR_eq();      % L1's only planform-ish output
S_ref_l1       = g1.S_ref;            % hardcoded literal at L1, JSON input at L2/L3
S_ref_l2       = g2.S_ref;
S_ref_l3       = g3.S_ref;
te_sweep_vt_l2 = g2.TE_sweep_vt;      % the Phase-1b headline: 0.33 -> 22.90 deg
te_sweep_vt_l3 = g3.TE_sweep_vt;
le_sweep_vt_l2 = g2.LE_sweep_vt;      % 40 (Brandt) vs 47.5 (T.O.) at L3
le_sweep_vt_l3 = g3.LE_sweep_vt;
L_fus_l3       = g3.L_fus;            % 47.5 (T.O.) vs 46.5 (Brandt) -- BY DESIGN
b_ht_l2        = g2.b_ht;             % derived 18.0 from AR_ht*S_ht
B_h_l3         = g3.B_h;              % 18.5 INPUT, taken as primary
D_nacelle_l3   = g3.D_inlet;
exp_wing_l3v   = g3.S_exposed_wing;

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

T = [T; srow('[SWEEP-ANGLE CONVERSION — HEADLINE BUG-FIX CHECKS]')];
T = [T; grow('Wing QC (25%c) sweep [deg]', 'L2', qc_sweep_wing, gt.wing_sweep_25pct_chord_deg.value, 'readme_geom.md Table 3', '%.4f', ...
    ['HEADLINE: was hardcoded 37 deg (bug), now computed ~32.2 deg via convert_sweep. No single Brandt cell for ' ...
     '"wing QC sweep" exists in the comparison JSON; 28.153 deg is the closest available figure but reflects Brandt''s ' ...
     'EXPOSED-PANEL-based sweep definition, not our full-planform convert_sweep definition -- the ~4 deg gap is an ' ...
     'expected, informative definitional difference (per IO''s handoff notes), NOT a bug to chase down in this pass.'], ...
     NaN, 'DEFINITIONAL')];
T = [T; grow('VT trailing-edge sweep [deg]', 'L2', te_sweep_vt_l2, 0.0, 'Brandt Main!H27 (hardcoded 0)', '%.4f', ...
    ['HEADLINE: the single-panel fix. convert_sweep''s mirrored 4/AR form gave a physically impossible 0.33 deg here; ' ...
     'convert_sweep_panel''s 2/AR form gives 22.90 deg, confirmed against the repo''s own VT chords (readme_geom.md ' ...
     'Sec 4.3). Brandt''s own cell is a hardcoded literal 0, inconsistent with his VT planform -- so the %Diff is ' ...
     'meaningless and the CHECK is against the chord geometry, not against him.'], NaN, 'DEFINITIONAL')];
T = [T; grow('VT trailing-edge sweep [deg]', 'L3', te_sweep_vt_l3, 0.0, 'Brandt Main!H27 (hardcoded 0)', '%.4f', ...
    'Same single-panel form as L2, evaluated at the physical 47.5 deg LE sweep instead of Brandt''s 40.', ...
     NaN, 'DEFINITIONAL')];

T = [T; srow('[L1 STATISTICAL TIER — regressions on W_TO, no planform exists at this tier]')];
T = [T; grow('Equivalent aspect ratio AR_eq [-]', 'L1', AR_eq_l1, 3.0, 'Brandt Main!B19 (actual AR)', '%.4f', ...
    ['Raymer 7th ed. Table 4.1 dogfighter row, a function of design Mach only. It ESTIMATES what the AR ought to be ' ...
     'for this mission; Brandt''s 3.0 is the F-16''s ACTUAL AR. +17% is the honest spread of a type-level regression, ' ...
     'not an error -- L2/L3 read the real 3.0 from the spec file instead.'], NaN, 'DEFINITIONAL')];

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
T = [T; grow('Wing reference area S_ref [ft^2]', 'L1', S_ref_l1, gt_S_ref, 'Brandt Main!B18', '%.1f', ...
    'Hardcoded literal at L1 (no way to estimate it from geometry at this tier); a JSON spec input at L2/L3.')];
T = [T; grow('Wing reference area S_ref [ft^2]', 'L2', S_ref_l2, gt_S_ref, 'Brandt Main!B18', '%.1f', ...
    'Passthrough of the spec input -- a plumbing check that the JSON reaches the property, not an independent result.')];
T = [T; grow('Wing reference area S_ref [ft^2]', 'L3', S_ref_l3, gt_S_ref, 'Brandt Main!B18', '%.1f', ...
    'Identical to L2: the wing planform does not diverge between the tiers.')];
T = [T; grow('Overall aircraft length L_aircraft [ft]', 'L2', L_aircraft_l2, gt.aircraft_length_ft.value, 'Brandt Geom!B21', '%.4f', ...
    'Same 47.65 spec input as L3; carried at both tiers because the Eq. 12.44 wave-drag term reads it at whichever tier is injected.', ...
     to_L_overall, 'DEFINITIONAL')];
T = [T; grow('Overall aircraft length L_aircraft [ft]', 'L3', L_aircraft_l3, gt.aircraft_length_ft.value, 'Brandt Geom!B21', '%.4f', ...
    ['Published F-16A airframe length (47 ft 7.75 in). Brandt''s 48.3039 is a MAX() over x-stations -- an EXTENT, ' ...
     'not a spec length -- so the two are not the same quantity. Value user-approved; citation NOT pinned to any ' ...
     'document in this repo (todo.md 2026-07-25 Phase 2 Sec 6, guarded by TestGeomL3.testTODO_OverallLengthCitationNotPinned).'], ...
     to_L_overall, 'BY DESIGN')];

T = [T; srow('[L3 PHYSICAL / T.O. TIER — DIVERGENCES FROM BRANDT ARE INTENTIONAL]')];
% The three defining L3 divergences come first: they are the reason this tier
% exists, and a reader who does not meet them here will read every downstream
% BY DESIGN row as an unexplained error.
T = [T; grow('Fuselage length L_fus [ft]', 'L3', L_fus_l3, gt_L_fus_brandt, 'Brandt Main!B32', '%.4f', ...
    ['DIVERGENCE 1 of 3. L3 uses the T.O. 1F-16A-1 fuselage length 47.5 ft where Brandt uses 46.5. Everything ' ...
     'downstream that scales with fuselage length -- fuselage S_wet, total S_wet, and the area-ruled Amax -- ' ...
     'inherits this +2.15%, which is why those rows are also BY DESIGN.'], to_L_fus, 'BY DESIGN')];
T = [T; grow('VT leading-edge sweep [deg]', 'L3', le_sweep_vt_l3, le_sweep_vt_l2, 'Brandt Main!H21 (= L2 value)', '%.4f', ...
    ['DIVERGENCE 2 of 3. L3 uses the T.O. 47.5 deg where Brandt/L2 use 40. Feeds the VT quarter-chord and ' ...
     'trailing-edge sweeps and the L3 form factor; it does NOT move VT exposed area, which has no sweep term.'], ...
     to_VT_sweep, 'BY DESIGN')];
T = [T; grow('HT span [ft]', 'L3', B_h_l3, b_ht_l2, 'F16GeomL2.b_ht = sqrt(AR*S) (= Brandt 3.0 AR)', '%.4f', ...
    ['DIVERGENCE 3 of 3. L3 takes the physical 18.5 ft span as the PRIMARY input, so AR_ht becomes DERIVED ' ...
     '(18.5^2/108 = 3.1690) instead of Brandt''s stated 3.0. L2 derives its 18.0 ft span from that 3.0 instead. ' ...
     'Area and span are what a 3-view measures; aspect ratio is definitional.'], to_HT_span, 'BY DESIGN')];
T = [T; grow('Wing S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_wing_l3, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', ...
    'Wing planform is identical at L2 and L3 (no physical divergence), so this matches the L2 row exactly.')];
T = [T; grow('HT   S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_ht_l3, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', ...
    ['Decomposes as +1.8% formula family (Roskam Eq.12.1 with T.O. root/tip t/c vs Brandt''s uniform t/c) ' ...
     'and +2.6% exposed area (the 18.5 ft T.O. span taken as primary). Not one large error.'], NaN, 'BY DESIGN')];
T = [T; grow('VT   S_wet, Roskam Eq.12.1 [ft^2]', 'L3', sw_vt_l3, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', ...
    'VT exposed area is sweep-independent, so this differs from L2 only by formula family.', NaN, 'BY DESIGN')];
T = [T; grow('Fuselage S_wet, Roskam Eq.12.3 [ft^2]', 'L3', sw_fus_l3, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', ...
    'L3 fuselage is 47.5 ft [T.O. 1F-16A-1] vs Brandt''s 46.5 -- a longer fuselage has more wetted area.', to_L_fus, 'BY DESIGN')];
T = [T; grow('Duct S_wet [ft^2]', 'L3', sw_duct_l3, gt.nacelle.S_wet_ft2, 'Brandt Geom!B4 (nacelle)', '%.4f', ...
    'Same frustum model and same injected thrust as L2 -- identical to the L2 duct row.')];
T = [T; grow('S_wet total, L3 (incl. duct) [ft^2]', 'L3', total_l3, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', ...
    'Phase 2 changed GeomL3.get_S_wet to INCLUDE the duct (it was airframe-only).', NaN, 'BY DESIGN')];
T = [T; grow('Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft]', 'L3', D_nacelle_l3, gt.nacelle.diameter_ft, 'Brandt Engn(s) tab', '%.6f', ...
    'Same injected prop.T_SL and same formula as L2 -- identical by construction, and a positive control that the propulsion DI reaches both tiers.')];
T = [T; grow('Wing exposed area [ft^2]', 'L3', exp_wing_l3v, gt.lifting_surface_exposed_areas.wing.exposed_S_ft2, 'Brandt Geom!7', '%.4f', ...
    'Wing planform is identical at L2 and L3, so this matches the L2 row exactly.')];
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
     to_VT_sweep, 'BY DESIGN')];


% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY + EXPORT — all four discipline reports share one renderer
%  (src/reporting/ComparisonReport.m), so their columns cannot drift apart.
% ════════════════════════════════════════════════════════════════════════ %

meta = struct( ...
    'title',         'F-16A Block 10/15 — Geometry vs Ground Truth', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('W_TO = %.0f lbf [Brandt Main! mission W_TO_lb].', W_TO), ...
    'referenceDesc', ['Brandt F-16A.xls, via `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` ' ...
                      '[`.geometry`] — the Brandt-DIRECT ground truth, **not** `F16Baseline.m` ' ...
                      '(the older T.O.-manual-based figures `fidelity_comparison.m` uses).'], ...
    'secondDesc',    ['T.O. 1F-16A-1 flight manual / USAF 3-view, via the same file''s `.to_1f16a1` ' ...
                      'block. These are the same physical numbers `f16a_L3.json` carries as inputs — ' ...
                      'one shared truth recorded as a second source, so a `BY DESIGN` divergence ' ...
                      'from Brandt is visibly backed by a document rather than looking like error.'] );

meta.preamble = { ...
    ['**The three L3 divergences that explain most of this table.** L3 is the physical / T.O. tier: ' ...
     'fuselage length **47.5 ft** (Brandt 46.5), VT leading-edge sweep **47.5°** (Brandt 40°), and the ' ...
     'HT span **18.5 ft** taken as PRIMARY so `AR_ht` is derived (3.1690) rather than Brandt''s stated ' ...
     '3.0. Every other `BY DESIGN` row downstream inherits one of these three.'], ...
    ['**Where a quantity has more than one implementation, each gets a row.** Wing/HT/VT `S_wet` via ' ...
     'Roskam Eq. 12.1 (official) vs Brandt''s own uniform-t/c formula; fuselage `S_wet` via Roskam ' ...
     'Eq. 12.3 (official) vs Brandt low-fi vs Brandt high-fi. The Brandt-formula rows match him ' ...
     'near-exactly by construction — they are his formula fed his own inputs, i.e. positive controls ' ...
     'on the plumbing rather than independent checks.'] };

meta.footer = { ...
    ['**Whole-aircraft `S_wet` total:** Brandt''s own RAW total (`Geom!B19`) double-counts the strake ' ...
     'wetted area — a documented Excel bug — so the CORRECTED total is the intended comparison target.'], ...
    ['**Not modelled:** the strake (`S_wet` and exposed area) has no component in any geometry tier. ' ...
     'Deferred rather than overlooked: sub-step 2h proved it contributes exactly 0.000 % to `Amax`, ' ...
     'since it is active only forward of the governing station.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, 'jsons', 'geometry_brandt_comparison.json');
out_md   = fullfile(script_dir, 'mds', 'geometry_brandt_comparison.md');
ComparisonReport.writeJson(T, out_json, meta);
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  JSON     -> %s\n', out_json);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

% ─── local helpers: thin wrappers over the shared renderer ───────────────── %

function T = grow(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence)
%GROW  One comparison row. See ComparisonReport.row for the column semantics.
    if nargin < 7; notes      = ''; end
    if nargin < 8; second     = NaN; end
    if nargin < 9; divergence = ''; end
    T = ComparisonReport.row(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence);
end

function T = srow(label)
%SROW  Section separator row.
    T = ComparisonReport.section(label);
end

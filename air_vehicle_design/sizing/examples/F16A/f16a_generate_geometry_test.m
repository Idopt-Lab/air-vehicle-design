function T = f16a_generate_geometry_test()
%F16A_MIXED_FIDELITY_GEOMETRY_DEMO  Progressive geometry buildup: L1's
%   bare-minimum output feeds L2, and L2's output feeds L3 -- never a
%   hand-typed re-guess at the next tier.
%
%   THE PREMISE (EXPANDED, 8/4/2026, Casey's instruction: "Expand
%   toolbox-only to include the things in the F-16 classes"): this script
%   now uses this repo's FULL sizing framework for the F-16 --
%     - The generic static toolboxes (GeometryBase / GeomL1 / GeomL2 /
%       GeomL3), same as the original revision.
%     - PLUS the concrete Tier-3 classes (F16GeomL1/L2/L3, F16AeroL1,
%       F16PropL1/L2), including their JSON-backed constructors, and
%       F16ConstraintSet/ConstraintAnalysis for the Stage-1 W/S bootstrap.
%   The original "no F16Geom*/no JSON" restriction is GONE. What replaces
%   it, so the file still demonstrates something rather than just calling
%   the production pipeline verbatim: every cascade step below MUTATES a
%   concrete object's own INPUT properties with the PRIOR stage's output
%   (S_ref, S_ht, S_vt, L_fus, B_h, ...), then reads its DERIVED
%   (Dependent) properties -- the "optimization-ready property design"
%   pattern F16GeomL2.m's own header documents as the reference
%   implementation every Tier-3 class follows. A JSON file is still read
%   (each class's own constructor default), but the cascade OVERWRITES
%   those defaults with the previous stage's real output before ever
%   reading a wetted area -- so Brandt's own numbers never silently leak
%   into a "L1-cascaded" result.
%
%   THE CASCADE (still the point of the script):
%     STAGE 0  bare-minimum L1 inputs -- category, design Mach, a seed
%              W_TO, two RSS/all-moving-tail flags, engine type, tail
%              configuration.
%     STAGE 1  L1 OUTPUTS: a REAL constraint diagram (F16ConstraintSet +
%              ConstraintAnalysis, using F16AeroL1/F16PropL1) bootstraps
%              S_ref from W_TO -- this is the actual "another way of
%              estimating S_ref ... or show a workflow for students to use
%              at L1" F16GeomL1.m's own header has flagged as a TODO since
%              2026-07-08; this script is that workflow. F16GeomL1 then
%              gives wing AR, fuselage length, whole-aircraft S_wet, and
%              (via GeometryBase + F16GeomL1.size_tail) both tail areas.
%     STAGE 2  L2 OUTPUTS: an F16GeomL2 object, constructed from its own
%              JSON defaults, then has S_ref/AR_wing/S_ht/S_vt/L_fus/
%              LE_sweep_wing OVERWRITTEN with Stage 1's cascaded values --
%              every wetted area read back out is genuinely "L1 cascaded
%              through the real L2 class," not a hand re-implementation
%              of its formulas.
%     STAGE 3  L3 OUTPUTS: an F16GeomL3 object, same override treatment,
%              PLUS the two T.O.-physical inputs that make L3 L3 (L_fus,
%              B_h) -- calling its own self-mutating size_tail() to re-
%              size the tail with the shorter T.O. arm, exactly as the
%              production sizing loop does.
%
%   ─── AN HONEST GAP, SURFACED RATHER THAN PAPERED OVER ───────────────────
%   lambda_wing remains the one irreducible hand-typed given: no taper
%   regression exists anywhere in this codebase, toolbox or Tier-3 class.
%
%   NOT A TEST: informational only, like the *_brandt_comparison.m scripts
%   -- never pass/fail, not part of run_all_tests, and nothing here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule).
%
%   HOW TO RUN
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> f16a_mixed_fidelity_geometry_demo
%   Non-interactively:
%     $ matlab -batch "addpath(genpath('air_vehicle_design/sizing/src')); addpath(genpath('air_vehicle_design/sizing/examples')); f16a_mixed_fidelity_geometry_demo"
%
%   SOURCES: [Brandt] S. Brandt, F-16A.xls, via each Tier-3 class's own
%   f16a_L{1,2,3}.json defaults. [T.O.] T.O. 1F-16A-1 / USAF 3-view, same
%   route. [Raymer] Aircraft Design 6th/7th ed., AIAA (Table 4.1 AR_eq;
%   Table 6.3 fuselage length; Table 6.4 tail volume coefficients; Fig.
%   4.20 wing sweep; Sec. 7.3 duct; ch. 5 constraint-diagram methodology).
%   [Roskam] Airplane Design Vol. II, DARcorp, 1997 (Eq. 12.1, 12.3).

% ════════════════════════════════════════════════════════════════════════ %
%  STAGE 0 — bare-minimum L1 inputs
% ════════════════════════════════════════════════════════════════════════ %

aircraft_category   = "jet_fighter";
M_max                = 2.0;       % design Mach   [feeds Raymer Tbl 4.1 AR_eq]
W_TO                  = 45000.0;  % lbf, guessed
has_rss               = true;     % relaxed static stability -- true for the F-16 (informational: g1/g2/g3's own constructors already bake this in via GeomL1.compute_tail_volume_coeffs)
has_all_moving_tail   = true;     % all-moving stabilator -- true for the F-16 (ditto)

% engine_type -- now wired into prop_L1 below (Stage 1), a real consumer:
% PropL1/PropL2's TSFC/lapse table lookup key. tail_configuration still has
% no consumer anywhere in this repo (re-verified 8/4/2026) -- no toolbox or
% Tier-3 class has a tail-configuration-keyed lookup; has_all_moving_tail
% above remains the one tail-configuration FACT actually consumed.
engine_type        = "low_bypass_turbofan_AB";   % [Brandt/f16a_L1.json .propulsion.engine_type]
tail_configuration = "conventional";             % [T.O. 1F-16A-1 / USAF 3-view -- not V-tail/T-tail/tailless]

% ════════════════════════════════════════════════════════════════════════ %
%  STAGE 1 — L1 OUTPUTS (F16GeomL1 + a real constraint diagram)
% ════════════════════════════════════════════════════════════════════════ %

% Get S_ref here, first -- via a REAL constraint diagram. This answers
% F16GeomL1.m's own standing TODO ("Try finding another way of estimating
% S_ref, or show a workflow for students to use at L1"): every constraint
% condition in this repo (ThrustConstraint/TakeoffConstraint/
% LandingConstraint/StallConstraint) needs a real AerodynamicsBase/
% PropulsionBase instance to evaluate required_TW(WS) -- there is no
% lighter-weight, aircraft-agnostic stand-in anywhere in this codebase, so
% "load and run a set of constraints for an arbitrary design" means
% building the real F16AeroL1/F16PropL1 pair.
aero_L1 = F16AeroL1(f16a_spec_path(1));                          % caller builds the L1 disciplines explicitly
prop_L1 = F16PropL1(f16a_spec_path(1));
prop_L1.engine_type = engine_type;                               % Stage-0 categorical input, now wired through
ca_L1 = ConstraintAnalysis.from_requirements(aero_L1, prop_L1, f16a_requirements_path(), ...
    F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);   % the F-16's own 8 conditions -- "arbitrary design" still means SOME design's real numbers
[WS_opt_L1, TW_opt_L1]     = ca_L1.optimal_point();                   % [Raymer ch. 5 constraint-diagram methodology]

S_ref = W_TO / WS_opt_L1;   % ft^2 -- BOOTSTRAPPED from Stage 0's W_TO, not hand-typed

g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
g1.aircraft_category = aircraft_category;
g1.M_max              = M_max;
g1.S_ref              = S_ref;    % override the JSON default (300) with the bootstrapped value
g1.W_TO                = W_TO;

% Compute wing dimensions/geometry (the part that doesn't need taper yet).
AR_wing_L1 = g1.get_AR_eq();                                    % [Raymer Tbl 4.1]
b_wing     = GeometryBase.compute_span(AR_wing_L1, S_ref);

% Compute taper ratio -- still a hand-typed given (see header): no GeomL1
% regression, and no Tier-3 class property either, produces taper. Whether
% it is even NEEDED at L1 is a real judgment call, not a fact this
% framework settles -- taper only enters here because size_tail's moment-
% arm math needs cbar_wing, and GeometryBase.compute_mac cannot get cbar
% without one. A team that picks a rough lambda early (as Casey's own team
% did) and refines it once real data narrows it down is following the same
% "guess now, refine later" logic Stage 0 already uses for W_TO.
lambda_wing = 0.2275;   % [Brandt Main!B20 -- wing taper ratio]

% Finish wing geometry now that taper is known (only cbar is needed downstream).
c_root_w   = GeometryBase.compute_root_chord(S_ref, b_wing, lambda_wing);
cbar_wing  = GeometryBase.compute_mac(c_root_w, lambda_wing);

L_fus_L1       = g1.L_fuselage;   % Dependent -- live now that g1.W_TO is set   [Raymer Tbl 6.3]
S_wet_L1_total = g1.S_wet;        % Dependent, ditto                            [Roskam Tbl 3.5]

S_tail_L1 = g1.size_tail(S_ref, b_wing, cbar_wing, L_fus_L1);   % g1.c_HT/c_VT already set by its own constructor (0.315/0.063)
S_ht_L1   = S_tail_L1.S_ht;
S_vt_L1   = S_tail_L1.S_vt;

% ════════════════════════════════════════════════════════════════════════ %
%  STAGE 2 — L2 OUTPUTS (F16GeomL2, its own JSON defaults overridden with
%  Stage 1's cascaded values before any wetted area is read)
% ════════════════════════════════════════════════════════════════════════ %

prop_L2             = F16PropL2(f16a_spec_path(2));
prop_L2.engine_type = engine_type;

g2 = F16GeomL2(f16a_spec_path(2), prop_L2);

% sweep_LE_wing -- Raymer Fig. 4.20 (6th ed., book p.79) gives no single
% equation, but two distinct methods, both implemented as local helpers at
% the bottom of this file:
%   GRAPHICAL  raymer_sweep_historical_trend_deg(M) -- the figure's solid
%              "historical trend line," digitized here as a lookup table
%              read off the plotted curve [(read from plot, approximate)].
%   ANALYTICAL raymer_sweep_mach_cone_deg(M) = 90 - asind(1/M), M>=1 only --
%              the dashed curve, whose closed form IS given in the book's
%              own text (p.79: "sweeping the wing leading edge aft of the
%              Mach cone angle [arcsin(1/Mach #)]"), NOT from the figure.
% Raymer's own text says the historical trend is what real designs follow
% (sweeping all the way to the Mach cone becomes "structurally impractical"
% past ~M 2.5), so the graphical value overrides g2's JSON default below;
% the analytical value is reported alongside it for context only.
sweep_LE_wing_graphical  = raymer_sweep_historical_trend_deg(M_max);  % [Raymer Fig. 4.20 solid curve, p.79]
sweep_LE_wing_analytical = raymer_sweep_mach_cone_deg(M_max);         % [Raymer Fig. 4.20 dashed curve / text, p.79]

g2.S_ref         = S_ref;                    % cascaded, Stage 1
g2.AR_wing       = AR_wing_L1;                % cascaded, Stage 1
g2.lambda_wing   = lambda_wing;               % given, Stage 1
g2.LE_sweep_wing = sweep_LE_wing_graphical;   % Raymer Fig. 4.20, NEW at this stage
g2.S_ht          = S_ht_L1;                   % cascaded, Stage 1
g2.S_vt          = S_vt_L1;                   % cascaded, Stage 1
g2.L_fus         = L_fus_L1;                  % cascaded, Stage 1
% Everything else on g2 stays at its own JSON default -- genuinely NEW
% L2-only shape data no L1 method produces at all: AR_ht/lambda_ht/
% tc_r_ht/tc_t_ht [Brandt Main! col C / T.O. Sec. I biconvex], AR_vt/
% lambda_vt/tc_r_vt/tc_t_vt [Brandt Main! col H / T.O. Sec. I], tc_wing
% [Brandt Main!B22], W_max_fuselage/H_max_fuselage [Brandt Main!C32/D32],
% L_duct [Brandt Main!F32] -- and T_AB_SLS_lb is Dependent on prop_L2.T_SL,
% not touched directly.

QC_sweep_wing = g2.QC_sweep_wing;   % Dependent -- no manual GeometryBase call needed anymore

S_wet_wing_L2  = g2.S_wet_wing;
S_wet_ht_L2    = g2.S_wet_ht;
S_wet_vt_L2    = g2.S_wet_vt;
S_wet_fus_L2   = g2.get_S_wet_fuselage();
S_wet_duct     = g2.get_S_wet_duct();
S_wet_L2_total = g2.S_wet;

% ════════════════════════════════════════════════════════════════════════ %
%  STAGE 3 — L3 OUTPUTS (F16GeomL3, same override treatment, PLUS the two
%  T.O.-physical inputs that make L3 L3 [CLAUDE.md's documented L2-vs-L3
%  divergences] -- everything else (wing shape, VT shape, duct) is
%  INHERITED unchanged, exactly as GeomL3 reuses GeomL2's formulas.)
% ════════════════════════════════════════════════════════════════════════ %

g3 = F16GeomL3(f16a_spec_path(3), prop_L2);   % L3 pairs with F16PropL2 -- no L3 propulsion tier (locked decision)

g3.S_ref         = S_ref;
g3.AR_wing       = AR_wing_L1;
g3.lambda_wing   = lambda_wing;
g3.LE_sweep_wing = sweep_LE_wing_graphical;

L_fus_L3 = 47.5;   % ft  [T.O. 1F-16A-1, physical -- diverges from the L1-cascaded 52.7-ish]
b_ht_L3  = 18.5;   % ft  [T.O./USAF 3-view span, taken as PRIMARY -- g3.AR_ht is then Dependent]

g3.L_fus = L_fus_L3;
g3.B_h   = b_ht_L3;
S_tail_L3 = g3.size_tail();   % self-mutates g3.S_ht/g3.S_vt using g3's OWN (now-overridden) S_ref/b_wing/cbar_wing/L_fus
S_ht_L3   = S_tail_L3.S_ht;
S_vt_L3   = S_tail_L3.S_vt;

S_wet_wing_L3  = g3.S_wet_wing;   % same formula, same inputs as g2's wing -- computed independently, happens to match
S_wet_ht_L3    = g3.S_wet_ht;
S_wet_vt_L3    = g3.S_wet_vt;
S_wet_fus_L3   = g3.get_S_wet_fuselage();
S_wet_duct_L3  = g3.get_S_wet_duct();
S_wet_L3_total = g3.S_wet;

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY — reuse the shared comparison-table renderer (informational only)
% ════════════════════════════════════════════════════════════════════════ %

T = ComparisonReport.section('STAGE 0 -> 1 — L1 outputs from bare category+Mach+weight alone');
T = [T; ComparisonReport.row('Constraint-diagram W/S_opt [lbf/ft^2]', 'L1', WS_opt_L1, 104.59, ...
    'Brandt (design point)', '%.2f', 'F16ConstraintSet''s 8 real conditions via F16AeroL1/F16PropL1 -- answers F16GeomL1.m''s own standing S_ref TODO.')];
T = [T; ComparisonReport.row('Constraint-diagram T/W_opt [-]', 'L1', TW_opt_L1, NaN, '-', '%.4f', ...
    'Reported alongside W/S_opt; not consumed further by this geometry-only cascade.')];
T = [T; ComparisonReport.row('S_ref, bootstrapped = W_TO/(W/S)_opt [ft^2]', 'L1', S_ref, 300.0, ...
    'Brandt Main!B18', '%.2f', 'No longer a hand-typed given -- Stage 0''s guessed W_TO divided by the constraint-diagram optimum above.')];
T = [T; ComparisonReport.row('Wing AR (Raymer Tbl 4.1 AR_eq) [-]', 'L1', AR_wing_L1, 3.0, ...
    'Brandt Main!B19', '%.3f', 'Generic dogfighter regression on M_max=2.0 vs Brandt''s stated 3.0.')];
T = [T; ComparisonReport.row('Wing span b [ft]', 'L1', b_wing, 30.0, 'Brandt (=sqrt(AR*S_ref))', '%.3f', ...
    'Derived from the bootstrapped S_ref and the L1 AR_eq above -- inherits both divergences.')];
T = [T; ComparisonReport.row('Wing MAC cbar [ft]', 'L1', cbar_wing, 11.318, 'Brandt (=f(AR,S_ref,lambda))', '%.3f')];
T = [T; ComparisonReport.row('L_fus, L1 statistical regression [ft]', 'L1', L_fus_L1, 46.5, ...
    'Brandt Main!B32', '%.2f', 'g1.L_fuselage -- Raymer Tbl 6.3 jet-fighter regression on W_TO alone.')];
T = [T; ComparisonReport.row('Total S_wet, L1 regression [ft^2]', 'L1', S_wet_L1_total, NaN, '-', '%.1f', ...
    'g1.S_wet -- whole-aircraft one-shot regression, no per-component breakdown at this tier.')];
T = [T; ComparisonReport.row('S_ht, L1 volume-coeff method [ft^2]', 'L1', S_ht_L1, 108.0, ...
    'Brandt Main!C18', '%.2f', 'g1.size_tail, fed the cascaded b_wing/cbar_wing/L_fus above, not Brandt''s real span/length.')];
T = [T; ComparisonReport.row('S_vt, L1 volume-coeff method [ft^2]', 'L1', S_vt_L1, 60.0, ...
    'Brandt Main!H18', '%.2f', 'g1.size_tail -- same cascaded-input note as S_ht above.')];

T = [T; ComparisonReport.section('STAGE 1 -> 2 — F16GeomL2, Stage-1 outputs overwriting its JSON defaults')];
T = [T; ComparisonReport.row('S_wet wing [ft^2]', 'L1->L2', S_wet_wing_L2, 392.02, 'Brandt Geom!B14', '%.2f', ...
    'g2.S_wet_wing (Dependent), read after S_ref/AR_wing/lambda_wing/LE_sweep_wing were overwritten with cascaded/Fig.4.20 values.')];
T = [T; ComparisonReport.row('S_wet HT [ft^2]', 'L1->L2', S_wet_ht_L2, 99.5848, 'Brandt Geom!B16', '%.2f', ...
    'g2.S_wet_ht, fed g2.S_ht=S_ht_L1 (39-ish ft^2, not Brandt''s 108) -- large gap is compounded L1 regression uncertainty, not a formula error.')];
T = [T; ComparisonReport.row('S_wet VT [ft^2]', 'L1->L2', S_wet_vt_L2, 81.6894, 'Brandt Geom!B17', '%.2f', ...
    'g2.S_wet_vt, fed g2.S_vt=S_vt_L1 -- same compounding-uncertainty note as S_wet HT above.')];
T = [T; ComparisonReport.row('S_wet fuselage [ft^2]', 'L1->L2', S_wet_fus_L2, 730.422, 'Brandt Geom!B3', '%.2f', ...
    'g2.get_S_wet_fuselage(), fed g2.L_fus=L_fus_L1 (52.7-ish ft, not Brandt''s real 46.5 ft).')];
T = [T; ComparisonReport.row('S_wet duct [ft^2]', 'L2', S_wet_duct, NaN, '-', '%.2f', ...
    'g2.get_S_wet_duct() -- new at this stage; no L1 nacelle/duct model exists to cascade from.')];
T = [T; ComparisonReport.row('Wing LE sweep, graphical (Fig. 4.20 trend) [deg]', 'L2', sweep_LE_wing_graphical, 40.0, ...
    'Brandt Main!B21', '%.2f', 'Digitized off Fig. 4.20''s solid historical-trend curve at M_max=2.0 (read from plot, approximate).', NaN, 'BY DESIGN')];
T = [T; ComparisonReport.row('Wing LE sweep, analytical Mach cone [deg]', 'L2', sweep_LE_wing_analytical, 40.0, ...
    'Brandt Main!B21', '%.2f', '90-asind(1/M_max) -- Fig. 4.20''s dashed curve; Raymer''s text calls this impractical past ~M2.5.', NaN, 'DEFINITIONAL')];
T = [T; ComparisonReport.row('Wing QC sweep [deg]', 'L2', QC_sweep_wing, NaN, '-', '%.2f', ...
    'g2.QC_sweep_wing (Dependent) on the graphical sweep_LE_wing above.')];
T = [T; ComparisonReport.row('Total S_wet, L2 (component sum) [ft^2]', 'L1->L2', S_wet_L2_total, NaN, '-', '%.1f', ...
    'g2.S_wet (Dependent) -- wing+HT+VT+fuselage+duct, all read live off the overridden inputs above.')];

T = [T; ComparisonReport.section('STAGE 2 -> 3 — F16GeomL3: only L_fus and HT span (B_h) change; wing/VT-shape/duct inherited')];
T = [T; ComparisonReport.row('S_ht, re-sized with L_fus_L3 [ft^2]', 'L2->L3', S_ht_L3, 108.0, ...
    'Brandt Main!C18', '%.2f', 'g3.size_tail() self-mutating call, T.O. L_fus_L3=47.5 shortens the tail arm vs Stage 1''s ~52.7.')];
T = [T; ComparisonReport.row('S_wet HT via T.O. span=18.5 primary [ft^2]', 'L2->L3', S_wet_ht_L3, 99.5848, ...
    'Brandt Geom!B16', '%.2f', 'g3.S_wet_ht -- g3.AR_ht is Dependent = B_h^2/S_ht_L3 instead of a given 3.0.', NaN, 'BY DESIGN')];
T = [T; ComparisonReport.row('S_vt, re-sized with L_fus_L3 [ft^2]', 'L2->L3', S_vt_L3, 60.0, ...
    'Brandt Main!H18', '%.2f', 'Same g3.size_tail() self-mutating call as S_ht above -- shorter T.O. tail arm.')];
T = [T; ComparisonReport.row('S_wet VT [ft^2]', 'L2->L3', S_wet_vt_L3, 81.6894, 'Brandt Geom!B17', '%.2f', ...
    'g3.S_wet_vt -- same AR_vt/lambda_vt as g2 (both at their own JSON default); only the cascaded S_vt_L3 (shorter tail arm) changed.')];
T = [T; ComparisonReport.row('S_wet fuselage [ft^2]', 'L2->L3', S_wet_fus_L3, 676.3289, 'Brandt Geom!D23', '%.2f', ...
    'g3.get_S_wet_fuselage() -- Roskam cylindrical formula vs Brandt''s own high-fi frame integration -- different formula families.', NaN, 'DEFINITIONAL')];
T = [T; ComparisonReport.row('S_wet duct [ft^2]', 'L3', S_wet_duct_L3, NaN, '-', '%.2f', ...
    'g3.get_S_wet_duct() -- inherited unchanged from L2 (same prop_L2.T_SL, same L_duct default).')];
T = [T; ComparisonReport.row('Total S_wet, L3 (component sum) [ft^2]', 'L2->L3', S_wet_L3_total, NaN, '-', '%.1f', ...
    'g3.S_wet (Dependent).')];

meta = struct( ...
    'title',         'F-16A — Progressive L1->L2->L3 Geometry Cascade (full framework: toolboxes + F-16 classes)', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     'Every wetted area is read from a real F16GeomL1/L2/L3 object whose INPUT properties were overwritten with the prior stage''s cascaded output.', ...
    'referenceDesc', 'Brandt F-16A.xls cell values, as already cited inline in f16a_L{1,2,3}.json and reproduced here for the %Diff column.', ...
    'secondDesc',    'N/A -- this is an architecture demo, not a Brandt-agreement report.');

meta.preamble = { ...
    ['**S_ref is bootstrapped, not hand-typed:** Stage 1 runs a real F16ConstraintSet/ConstraintAnalysis ' ...
     'diagram (F16AeroL1/F16PropL1) to get W/S_opt, then S_ref = W_TO/(W/S)_opt -- answering F16GeomL1.m''s ' ...
     'own standing TODO about estimating S_ref at L1. lambda_wing=0.2275 remains the one genuinely ' ...
     'irreducible given -- no taper regression exists anywhere in this framework, toolbox or Tier-3 class.'], ...
    sprintf(['Stage 0 also records tail_configuration=%s for tabulation -- still no consumer anywhere in ' ...
     'this repo. engine_type=%s IS now wired into prop_L1/prop_L2.engine_type (the TSFC/lapse table key), ' ...
     'unlike the prior toolbox-only revision of this file.'], tail_configuration, engine_type), ...
    sprintf(['Stage 0''s has_rss=%d and has_all_moving_tail=%d are informational: g1/g2/g3''s own ' ...
     'constructors already hardcode the identical F-16 facts via GeomL1.compute_tail_volume_coeffs, so ' ...
     'these two flags are not separately threaded through -- listed here for the record, not silently ' ...
     'dropped.'], has_rss, has_all_moving_tail) };

ComparisonReport.show(T, meta);

end

% ════════════════════════════════════════════════════════════════════════ %
%  Raymer Fig. 4.20 (6th ed., book p.79 / PDF p.109) wing leading-edge sweep
%  vs max Mach number -- neither curve is implemented anywhere in this
%  repo's toolboxes or Tier-3 classes, so both live here as plain, cited
%  local functions.
% ════════════════════════════════════════════════════════════════════════ %

function sweep_deg = raymer_sweep_historical_trend_deg(M)
%RAYMER_SWEEP_HISTORICAL_TREND_DEG  GRAPHICAL method: Fig. 4.20's solid
%   "historical trend line," digitized by reading the plotted curve
%   (read from plot, approximate -- not a tabulated value in the book's
%   text). [Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Fig.
%   4.20, p.79] Valid over the figure's plotted range, M = 0-4.
    M_tab     = [0    0.5  0.75  1.0   1.25  1.5   2.0   2.5   3.0   4.0];
    sweep_tab = [0    4    18    38    47    52    57    59    60    61 ];
    sweep_deg = interp1(M_tab, sweep_tab, M, 'linear', 'extrap');
end

function sweep_deg = raymer_sweep_mach_cone_deg(M)
%RAYMER_SWEEP_MACH_CONE_DEG  ANALYTICAL method: sweep the leading edge aft
%   of the Mach cone angle. [Raymer, Aircraft Design: A Conceptual
%   Approach, 6th ed., p.79, unnumbered equation: "arcsin(1/Mach #)"; also
%   Fig. 4.20's dashed curve] Undefined below M=1 -- the dashed curve in
%   Fig. 4.20 only begins at M=1, since arcsin(1/M) > 1 (undefined) for any
%   subsonic Mach.
    if M < 1
        sweep_deg = NaN;
    else
        sweep_deg = 90 - asind(1/M);
    end
end

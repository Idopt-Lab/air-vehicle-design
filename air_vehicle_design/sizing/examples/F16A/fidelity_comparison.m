function T_all = fidelity_comparison()
%FIDELITY_COMPARISON  F-16A Block 10 — cross-fidelity prediction grid.
%
%   Instantiates student classes at all three fidelity levels, evaluates
%   key discipline outputs at the Brandt design point, displays a MATLAB
%   table comparison, and exports to Excel and JSON.
%
%   Outputs (written to the same directory as this script):
%     fidelity_comparison.xlsx  — one sheet per discipline section
%     fidelity_comparison.json  — all sections with metadata
%
%   REFERENCE SOURCES:
%     [Brandt]  S. Brandt, F-16A.xls workbook
%     [TO]      T.O. 1F-16A-1, Flight Manual, USAF/EPAF F-16A/B Blocks 10/15
%     [Raymer]  D.P. Raymer, Aircraft Design 6th ed., AIAA, 2018
%     [Roskam]  J. Roskam, Airplane Design Part I, DARcorp., 1985
%
%   BRANDT/T.O. REFERENCE VALUES now come from VnV/BrandtF16A (the retired
%   baseline/F16Baseline.m is no longer read): the consolidated ground-truth
%   JSON (f16a_ground_truth.json, loaded as GT) supplies the weights/geometry/
%   aero/propulsion reference figures, f16a_geometry.json (J_geo) supplies W_TO
%   and SLS thrust, and the live Brandt discipline chain (BrandtGeometry ->
%   BrandtAerodynamics -> BrandtEngine) supplies the per-condition thrust-lapse
%   and CLmax references. A handful of Brandt-Consts-sheet drag-polar
%   coefficients and the two 5-point Brandt polar tables have no VnV table home
%   and are kept as cited literals transcribed verbatim from the workbook
%   (marked "cited literal" at each use).

% ── Brandt / T.O. ground-truth sources (replaces F16Baseline) ──────────── %
script_dir_gt = fileparts(mfilename('fullpath'));
sizing_root   = fileparts(fileparts(script_dir_gt));
gt_path       = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
geo_path      = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_geometry.json');
GT            = jsondecode(fileread(gt_path));    % consolidated cross-discipline ground truth
J_geo         = jsondecode(fileread(geo_path));   % Brandt geometry JSON (W_TO, SLS thrust)

% Live Brandt discipline chain for per-condition thrust-lapse and CLmax refs
% (self-contained path-add, mirrors tests/constraints/brandt_constraint_reference.m).
if isempty(which('BrandtEngine'))
    vnv = fullfile(sizing_root, 'VnV', 'BrandtF16A');
    addpath(vnv);
    addpath(fullfile(vnv, 'GroundTruth'));
end
brandt_geom = BrandtGeometry();            brandt_geom.analyze();
brandt_aero = BrandtAerodynamics(brandt_geom); brandt_aero.analyze();
brandt_eng  = BrandtEngine();              brandt_eng.analyze();

W_TO = J_geo.mission.W_TO_lb;   % 31,377 lbf  [Brandt Main! mission W_TO_lb]

% Flight conditions used throughout
st_SL_001 = AircraftState(0,     0.01);  % SL M~0  (TSFC SLS reference)
st_SL_050 = AircraftState(0,     0.50);  % SL M=0.5 (subsonic aero)
st_10_087 = AircraftState(10000, 0.87);  % 10 kft M=0.87 (Ps constraint)
st_20_087 = AircraftState(20000, 0.87);  % 20 kft M=0.87 (1st combat turn)
st_36_087 = AircraftState(36000, 0.87);  % 36 kft M=0.87 (cruise / propulsion)
st_36_140 = AircraftState(36000, 1.40);  % 36 kft M=1.4  (2nd combat turn)
st_36_160 = AircraftState(36000, 1.60);  % 36 kft M=1.6  (dash / supersonic aero / polar_actual)
st_50_087 = AircraftState(50000, 0.87);  % 50 kft M=0.87 (max altitude)

% ── Discipline objects ────────────────────────────────────────────────── %
% Built up front because every section below injects them. Geometry takes the
% propulsion object (the nacelle diameter, and so duct wetted area and CD0, is
% sized from engine thrust); weights takes geometry, propulsion and the
% requirements file. There is no L3 propulsion tier, so F16PropL2 serves both
% the L2 and L3 rungs -- any L3 propulsion figure here is computed by F16PropL2.
prop = F16PropL2(f16a_spec_path(2));
g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
g2 = F16GeomL2(f16a_spec_path(2), prop);
g3 = F16GeomL3(f16a_spec_path(3), prop);

% ── Weights ───────────────────────────────────────────────────────────── %
% Phase 4 (2026-07-25) reshaped the weights classes. L2/L3 now take the
% requirements file plus injected geometry and propulsion objects:
%   F16WeightsL{2,3}(json_path, req_path, geom, prop)
% L2 injects F16GeomL2, L3 injects F16GeomL3 (the physical/T.O. tier), and
% both take F16PropL2 -- there is no L3 propulsion tier. The requirements file
% supplies the cruise condition (for the SFC dependency injection) and the
% design Mach (for the Raymer Eq. 10.10 engine weight).
%
% The objects come from the Discipline-objects block above. L1 is unchanged: it
% is a pure type-based statistical estimate with no geometry or engine data.
%
% Two Phase-4 fixes are visible in the numbers below. OEW is now a function of
% its ARGUMENT rather than of a frozen 0.17*31377 baked into the constructor
% (review finding #5), and the L3 landing-gear group now responds to W_TO at
% all -- it was bit-identical at 31,377 / 45,000 / 60,000 lbf because the
% landing weight was Brandt's frozen Wt!B41 output and weight_landing_gear
% took no W_TO argument (todo 2026-07-25 Phase 4 §P4-17).
w1 = F16WeightsL1(f16a_spec_path(1));
w2 = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
w3 = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);

% Set the current TOGW iterate on the objects. The W_TO-dependent group
% properties (W_all_else_empty, W_landing_gear, ...) are Dependent getters and
% now ERROR rather than silently returning a stale or NaN value when W_TO has
% not been set -- which is the point of the Phase-4 change, and is exactly what
% a sizing loop does each iteration. The OEW(W_TO) methods take W_TO as an
% argument and do not need this, but the property reads below do.
w2.W_TO = W_TO;
w3.W_TO = W_TO;

oew          = [w1.OEW(W_TO), w2.OEW(W_TO), w3.OEW(W_TO)];
wefrac       = oew / W_TO;
we_roskam_L1 = w1.compute_We_roskam(W_TO);

% Component-category breakdown (L2/L3 only -- L1 is a single Roskam
% statistical OEW estimate with no component buildup, so L1=NaN throughout).
% Brandt component-level weight references come from f16a_ground_truth.json
% (.weights.structural_components / .engine_and_systems, Brandt Wt tab).
t2_tail = w2.weight_tail(W_TO);
t3_tail = w3.weight_tail(W_TO);
lg3     = w3.weight_landing_gear(W_TO);   % now takes W_TO -- see the section note
eng3    = w3.weight_engine_section(W_TO);
sys3    = w3.weight_systems(W_TO);

w_wing  = [NaN, w2.weight_wing(W_TO),     w3.weight_wing(W_TO)    ];
w_ht    = [NaN, t2_tail.HT,               t3_tail.HT              ];
w_vt    = [NaN, t2_tail.VT,               t3_tail.VT              ];
w_fus   = [NaN, w2.weight_fuselage(W_TO), w3.weight_fuselage(W_TO)];
w_lg    = [NaN, w2.weight_landing_gear(W_TO), lg3.main + lg3.nose ];
w_eng   = [NaN, w2.W_installed_engine,    eng3.total              ];
w_else  = [NaN, w2.W_all_else_empty,      sys3.total              ];

% Brandt component references [f16a_ground_truth.json .weights.*]. Wing/HT(Pitch
% Cntrl)/VT(Vert)/Fuselage/Nacelles/Strakes come from Brandt's "Structural
% Weight Models, average psf" table (.structural_components, a psf-coefficient
% x area model) rather than the Wt!B16-B21 Group Weight Statement cells;
% Gear/Engine/Inlet Duct/Controls/Electrical/Hydraulics/ECS/Other/Avionics/
% Armament are the Wt!B22-B31 items (.engine_and_systems). "Engine(s) installed"
% groups Brandt's Engine+Nacelles+Inlet Duct, the closest match to this
% framework's weight_engine_section (bare engine + mounts/section/
% induction/tailpipe/cooling/oil/starter). "All else empty" groups
% everything else Brandt counts in OEW that isn't wing/tail/fuselage/
% gear/engine (Strakes, Controls, Electrical, Hydraulics, ECS, Other,
% Avionics, Armament) -- because Strakes/Nacelles come from the Structural
% Weight Models table, these 7 reference sums do not reproduce Brandt's OEW
% (Wt!B12) exactly the way the raw all-Wt!B16-B31 figures would.
wsc  = GT.weights.structural_components;
wes  = GT.weights.engine_and_systems;
ref_wing = wsc.wing.value;
ref_ht   = wsc.pitch_control_HT.value;
ref_vt   = wsc.vertical_tail.value;
ref_fus  = wsc.fuselage.value;
ref_lg   = wes.landing_gear.value;
ref_eng  = wes.engine.value + wsc.nacelles.value + wes.inlet_duct.value;
ref_else = wsc.strakes.value + wes.flight_controls.value + wes.electrical.value + ...
           wes.hydraulics.value + wes.ecs_ac_antiice.value + wes.other_structure.value + ...
           wes.avionics.value + wes.armament_support.value;

% ── Geometry ──────────────────────────────────────────────────────────── %
% Geometry has all three fidelity tiers again as of 2026-07-24/25: the
% 2026-07-22 "L3 eliminated and merged into L2" decision was REVERSED, and
% Phase 2 promoted GeomL3 to the full L3 geometry tier consumed by L3
% geometry + aero + weights. The L3 column below is now real, not NaN.
%
% L3 geometry is INTENTIONALLY divergent from L2 -- it is the physical/T.O.
% tier, so where a physical value differs from Brandt's it uses the physical
% one: VT LE sweep 47.5 vs 40, L_fus 47.5 vs 46.5, HT span 18.5 ft taken as
% PRIMARY (making AR_ht a derived 3.1690 rather than Brandt's 3.0). It also
% uses Roskam Vol. II Eq. 12.1 for lifting-surface S_wet where L2's official
% choice is the same formula but L3 additionally carries the T.O. root/tip t/c
% splits. L2-vs-L3 differences here are therefore EXPECTED, not errors --
% see examples/F16A/F16GeomL3.md §4/§3 for the full accounting.
%
% Geometry also takes the propulsion object: the nacelle diameter -- and so
% duct wetted area and total S_wet -- is sized from engine thrust.

swet    = [g1.get_S_wet(W_TO), g2.get_S_wet(),          g3.get_S_wet()];
lfus    = [g1.get_L_fus(W_TO), g2.L_fus,                g3.L_fus];
sw_wing = [NaN,                g2.get_S_wet_wing(),     g3.get_S_wet_wing()];
sw_ht   = [NaN,                g2.get_S_wet_HT(),       g3.get_S_wet_HT()];
sw_vt   = [NaN,                g2.get_S_wet_VT(),       g3.get_S_wet_VT()];
sw_fus  = [NaN,                g2.get_S_wet_fuselage(), g3.get_S_wet_fuselage()];
sw_duct = [NaN,                g2.get_S_wet_duct(),     g3.get_S_wet_duct()];

% ── Aerodynamics ──────────────────────────────────────────────────────── %
% L3 aero injects g3, the L3 geometry tier -- NOT g2. This line still passed g2
% after Phase 2 repointed the other L3 consumers (F16ConstraintSet,
% aerodynamics_brandt_comparison), so the L3 aero column here was silently
% computed on L2 geometry; corrected in Phase 4. The L3 aero numbers below
% therefore move: L3 geometry is the physical/T.O. tier (VT LE sweep 47.5 vs 40,
% L_fus 47.5 vs 46.5) and its Amax is the area-ruled buildup rather than L2's
% fuselage-envelope ellipse.
a1 = F16AeroL1(f16a_spec_path(1));
a2 = F16AeroL2(g2, f16a_spec_path(2), f16a_control_surfaces());
a3 = F16AeroL3(g3, f16a_spec_path(3), f16a_control_surfaces());

pu1 = a1.drag_polar(st_36_160); pu2 = a2.drag_polar(st_36_160); pu3 = a3.drag_polar(st_36_160);

cd0_sup    = [pu1.CD0, pu2.CD0, pu3.CD0];
k1_sup     = [pu1.K1,  pu2.K1,  pu3.K1 ];
clmax      = [a1.get_CLmax(st_SL_050), a2.get_CLmax(st_SL_050), a3.get_CLmax(st_SL_050)];
% L1 is geometry-free (Mattingly type-curve) and has no Oswald-efficiency
% concept -> N/A; L2/L3 use Raymer Eq. 12.48/12.49 (official e).
e_osw      = [NaN, a2.get_e_osw(), a3.get_e_osw()];
cl_alpha_M0  = [NaN, a2.get_CL_alpha(0.0), a3.get_CL_alpha(0.0)];
cl_alpha_M06 = [NaN, a2.get_CL_alpha(0.6), a3.get_CL_alpha(0.6)];

% ── Aero: high-lift devices (flaps/slats/gear) ──────────────────────────── %
% st_hld: sea-level, M~0.2 approach/ground-roll reference state, used only
% for L3's gear-strut Reynolds-number lookup (compute_Delta_CD0_geardown).
st_hld = AircraftState(0, 0.2);

% L1 clean CD0 is the Mattingly type-curve value at the HLD reference state
% (geometry-free); L2 is the Cfe*Swet/Sref clean estimate; L3 the buildup.
cd0_clean_hld = [a1.drag_polar(st_hld).CD0, a2.get_CD0(), a3.drag_polar(st_hld).CD0];
d_cd0_TO      = [a1.get_Delta_CD0_TO(), a2.get_Delta_CD0_TO(), a3.get_Delta_CD0_TO(st_hld)];
d_cd0_L       = [a1.get_Delta_CD0_L(),  a2.get_Delta_CD0_L(),  a3.get_Delta_CD0_L(st_hld)];
cd0_TO_total  = cd0_clean_hld + d_cd0_TO;
cd0_L_total   = cd0_clean_hld + d_cd0_L;

d_eosw_TO_hld = [a1.get_Delta_e_osw_TO(), a2.get_Delta_e_osw_TO(), a3.get_Delta_e_osw_TO()];
d_eosw_L_hld  = [a1.get_Delta_e_osw_L(),  a2.get_Delta_e_osw_L(),  a3.get_Delta_e_osw_L()];

clmax_TO_total = [a1.get_CLmax_TO(), a2.get_CLmax_TO(), a3.get_CLmax_TO()];
clmax_L_total  = [a1.get_CLmax_L(),  a2.get_CLmax_L(),  a3.get_CLmax_L()];

% Raw Delta_CLmax (all 3 levels implement get_Delta_CLmax_TO/L directly).
% Reference is derived from Brandt's own clean/TO/landing CLmax targets
% (Brandt L8/L9/L10), not a separately-tabulated Brandt "delta".
d_clmax_TO = [a1.get_Delta_CLmax_TO(), a2.get_Delta_CLmax_TO(), a3.get_Delta_CLmax_TO()];
d_clmax_L  = [a1.get_Delta_CLmax_L(),  a2.get_Delta_CLmax_L(),  a3.get_Delta_CLmax_L()];
% Brandt clean/TO/landing CLmax targets, live from BrandtAerodynamics (Aero!H25/
% H27/H29) -- the deltas are derived here rather than separately tabulated.
ref_clmax_clean = brandt_aero.CLmax_clean;    % Aero!H25
ref_clmax_TO    = brandt_aero.CLmax_takeoff;  % Aero!H27
ref_clmax_L     = brandt_aero.CLmax_landing;  % Aero!H29
ref_dclmax_TO = ref_clmax_TO - ref_clmax_clean;
ref_dclmax_L  = ref_clmax_L  - ref_clmax_clean;

% Delta_CDi has no L1 analog (no induced-drag flap model at that fidelity)
% and no direct Brandt reference at any level.
d_cdi_TO = [NaN, a2.get_Delta_CDi_TO(), a3.get_Delta_CDi_TO()];
d_cdi_L  = [NaN, a2.get_Delta_CDi_L(),  a3.get_Delta_CDi_L()];

% Brandt's 5 tabulated Mach breakpoints (Brandt MODEL polar), sea level --
% same points/method as TestAeroL1/L2/L3's testCD0AtBrandtMachPoints and
% testK1AtBrandtMachPoints. CITED LITERAL (no VnV table home): transcribed
% verbatim from the Brandt "Aero" sheet A6:E10, columns [Mach CDmin CD0 K1 K2].
% f16a_ground_truth.json carries only the ACTUAL polar (Aero!M6:Q10), not this
% MODEL polar, so it stays a cited literal here.
brandt_polar_model = [
    0.1000,  0.01691,  0.01700,  0.1160,  -0.0066;
    0.8727,  0.01691,  0.01700,  0.1160,  -0.0066;
    1.0547,  0.04558,  0.04568,  0.1277,  -0.0047;
    1.5000,  0.04128,  0.03994,  0.2516,   0.0000;
    2.0000,  0.04128,  0.03732,  0.3670,   0.0000;
];   % [Brandt Aero A6:E10]
brandtM  = brandt_polar_model(:,1);
nBrandt  = numel(brandtM);
cd0_sweep = zeros(nBrandt, 3);
k1_sweep  = zeros(nBrandt, 3);
for iM = 1:nBrandt
    st_iM = AircraftState(0, brandtM(iM));
    q1 = a1.drag_polar(st_iM); q2 = a2.drag_polar(st_iM); q3 = a3.drag_polar(st_iM);
    cd0_sweep(iM,:) = [q1.CD0, q2.CD0, q3.CD0];
    k1_sweep(iM,:)  = [q1.K1,  q2.K1,  q3.K1 ];
end

% Aero at the six constraint-analysis (alt, Mach) conditions Brandt
% tabulates on the "Consts" sheet -- same points/method as
% TestAeroL1/L2/L3's testDragPolarAtConstraintConditions. Brandt's own
% CD0/K1/K2 at each condition (brandt_con.*, cited literals from the Consts
% sheet) are used as Reference below.
constraintNames  = {'cruise', 'combat_sub', 'dash', 'max_alt', 'combat_sup', 'ps'};
constraintStates = {st_36_087, st_20_087, st_36_160, st_50_087, st_36_140, st_10_087};
nCon = numel(constraintNames);

% Brandt's own drag-polar coefficients at each of the six constraint conditions.
% CITED LITERALS (no VnV table home): the per-condition CD0/K1/K2 come from the
% Brandt "Consts" sheet (rows 23-28), which f16a_ground_truth.json does not
% tabulate as a per-condition polar. dash.K1 (0.276031, M=1.6) and combat_sup.K1
% (0.226103, M=1.4) are the supersonic-form K1 corrections (Raymer 6th ed.
% Eq. 12.51), superseding the Consts-row tabulated cells 0.1251/0.12563
% (2026-07-23 user direction). alt_ft/mach match constraintStates above.
%   fields: [alt_ft, mach, CD0, K1, K2]   [Brandt Consts rows 23-28]
brandt_con.cruise     = struct('alt_ft',36000,'mach',0.87,'CD0',0.01700,'K1',0.11603,'K2',-0.0066);
brandt_con.combat_sub = struct('alt_ft',20000,'mach',0.87,'CD0',0.01700,'K1',0.11603,'K2',-0.0066);
brandt_con.dash       = struct('alt_ft',36000,'mach',1.60,'CD0',0.03933,'K1',0.276031,'K2',0);
brandt_con.max_alt    = struct('alt_ft',50000,'mach',0.87,'CD0',0.01700,'K1',0.11603,'K2',-0.0066);
brandt_con.combat_sup = struct('alt_ft',36000,'mach',1.40,'CD0',0.04063,'K1',0.226103,'K2',0);
brandt_con.ps         = struct('alt_ft',10000,'mach',0.87,'CD0',0.01700,'K1',0.11603,'K2',-0.0066);
cd0_con = zeros(nCon, 3);
k1_con  = zeros(nCon, 3);
k2_con  = zeros(nCon, 3);
for iC = 1:nCon
    st_iC = constraintStates{iC};
    q1 = a1.drag_polar(st_iC); q2 = a2.drag_polar(st_iC); q3 = a3.drag_polar(st_iC);
    cd0_con(iC,:) = [q1.CD0, q2.CD0, q3.CD0];
    k1_con(iC,:)  = [q1.K1,  q2.K1,  q3.K1 ];
    k2_con(iC,:)  = [q1.K2,  q2.K2,  q3.K2 ];
end

% ── Propulsion (L3 not yet implemented → NaN) ─────────────────────────── %
p1 = F16PropL1(f16a_spec_path(1));
p2 = F16PropL2(f16a_spec_path(2));

% alpha_AB and alpha_mil at each constraint condition
% L1: density-ratio lapse only (no mil/AB split) → alpha_mil = NaN for L1
alpha_AB_crs  = [p1.thrust_lapse(st_36_087), p2.thrust_lapse(st_36_087), NaN];
alpha_mil_crs = [NaN,                          p2.compute_thrust_lapse_mil(st_36_087), NaN];
alpha_AB_sub  = [p1.thrust_lapse(st_20_087), p2.thrust_lapse(st_20_087), NaN];
alpha_mil_sub = [NaN,                          p2.compute_thrust_lapse_mil(st_20_087), NaN];
alpha_AB_dash = [p1.thrust_lapse(st_36_160), p2.thrust_lapse(st_36_160), NaN];
alpha_mil_dash = [NaN,                         p2.compute_thrust_lapse_mil(st_36_160), NaN];
alpha_AB_malt = [p1.thrust_lapse(st_50_087), p2.thrust_lapse(st_50_087), NaN];
alpha_mil_malt = [NaN,                         p2.compute_thrust_lapse_mil(st_50_087), NaN];
alpha_AB_sup  = [p1.thrust_lapse(st_36_140), p2.thrust_lapse(st_36_140), NaN];
alpha_mil_sup = [NaN,                          p2.compute_thrust_lapse_mil(st_36_140), NaN];
alpha_AB_ps   = [p1.thrust_lapse(st_10_087), p2.thrust_lapse(st_10_087), NaN];
alpha_mil_ps  = [NaN,                          p2.compute_thrust_lapse_mil(st_10_087), NaN];

tsfc_SLS = [p1.get_TSFC(st_SL_001), p2.get_TSFC(st_SL_001), NaN];
tsfc_crs = [p1.get_TSFC(st_36_087), p2.get_TSFC(st_36_087), NaN];

% Brandt thrust-lapse references at each constraint condition, LIVE from
% BrandtEngine (replaces b.constraints.*.alpha_AB / .alpha_mil_T_AB). The Brandt
% engine normalises to the T_SL_AB axis: eng.run(alt,mach,AB_p).alpha_AB_ref
% with AB_p=1.0 gives the full-AB lapse (Consts col AT, = b.*.alpha_AB) and
% AB_p=0.0 gives the mil/dry lapse on the same T_SL_AB axis (Consts col AU,
% = b.*.alpha_mil_T_AB).
ref_alpha_AB  = @(alt,M) brandt_alpha_ref(brandt_eng, alt, M, 1.0);
ref_alpha_mil = @(alt,M) brandt_alpha_ref(brandt_eng, alt, M, 0.0);

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD SECTION TABLES
% ════════════════════════════════════════════════════════════════════════ %

ref_oew = GT.weights.summary.OEW.value;   % 19,980.70 lbf  [Brandt Wt!B12]
T_wts = trow('OEW [lbf]',    ref_oew,           'Brandt Wt!B12',  oew,    '%.0f' );
T_wts = [T_wts; trow('We/W_TO [-]', ref_oew/W_TO, 'Brandt Wt!B12/W_TO', wefrac, '%.4f')];
T_wts = [T_wts; trow('  Main wings [lbf]',        ref_wing, 'Brandt Structural Wt Models (psf)',            w_wing, '%.0f')];
T_wts = [T_wts; trow('  Horizontal tail [lbf]',   ref_ht,   'Brandt Structural Wt Models (psf), Pitch Cntrl', w_ht,   '%.0f')];
T_wts = [T_wts; trow('  Vertical tail [lbf]',     ref_vt,   'Brandt Structural Wt Models (psf), Vert Surf',   w_vt,   '%.0f')];
T_wts = [T_wts; trow('  Fuselage [lbf]',          ref_fus,  'Brandt Structural Wt Models (psf)',            w_fus,  '%.0f')];
T_wts = [T_wts; trow('  Landing gear [lbf]',      ref_lg,   'Brandt Wt!B23',            w_lg,   '%.0f')];
T_wts = [T_wts; trow('  Engine(s) installed [lbf]', ref_eng, 'Brandt Structural Wt Models Nacelle(s) + Wt!B22+B24 (Engine+Duct)', w_eng,  '%.0f')];
T_wts = [T_wts; trow('  All else empty [lbf]',    ref_else, 'Brandt Structural Wt Models Strakes + Wt!B25:B31 (Ctrl+Elec+Hyd+ECS+Other+Avionics+Armament)', w_else, '%.0f')];

geo_gt = GT.geometry;
ref_L_fus   = geo_gt.to_1f16a1.fuselage_length_ft.value;              % 47.5 ft [TO 1F-16A-1]
ref_S_wet   = geo_gt.whole_aircraft_S_wet_ft2.raw_buggy_total;        % 1371.09 [Brandt Geom!B19]
ref_sw_wing = geo_gt.lifting_surface_S_wet_ft2.wing.value;            % Brandt Geom!B14
ref_sw_ht   = geo_gt.lifting_surface_S_wet_ft2.pitch_control_HT.value;% Brandt Geom!B16
ref_sw_vt   = geo_gt.lifting_surface_S_wet_ft2.vertical_tail.value;   % Brandt Geom!B17
ref_sw_fus  = geo_gt.fuselage_S_wet.high_fi_ft2;                      % Brandt Geom!D23
ref_sw_duct = geo_gt.nacelle.S_wet_ft2;                               % Brandt Geom!B4 (nacelle)
ref_AR      = geo_gt.inputs_on_Main_tab.wing.AR;                      % 3.0 [Brandt Main!B19]

T_geom = trow('S_wet total [ft2]',  ref_S_wet, 'Brandt Geom!B19', swet,    '%.1f');
T_geom = [T_geom; trow('L_fus [ft]',         ref_L_fus,   'TO Fig. 1-2',    lfus,    '%.2f')];
T_geom = [T_geom; trow('  Wing S_wet [ft2]', ref_sw_wing, 'Brandt Geom!B14',      sw_wing, '%.1f')];
T_geom = [T_geom; trow('  HT   S_wet [ft2]', ref_sw_ht,   'Brandt Geom!B16',      sw_ht,   '%.1f')];
T_geom = [T_geom; trow('  VT   S_wet [ft2]', ref_sw_vt,   'Brandt Geom!B17',      sw_vt,   '%.1f')];
T_geom = [T_geom; trow('  Fus  S_wet [ft2]', ref_sw_fus,  'Brandt Geom!D23',      sw_fus,  '%.1f')];
T_geom = [T_geom; trow('  Duct S_wet [ft2]', ref_sw_duct, 'Brandt Geom!B4 (nacelle)', sw_duct, '%.1f')];

e_osw_ref = 1 / (pi * ref_AR * brandt_polar_model(1,4));   % Brandt K1 → derived e_osw

% CD0 and K1 across all 5 of Brandt's tabulated Mach breakpoints, sea level
% -- mirrors TestAeroL1/L2/L3's testCD0AtBrandtMachPoints/testK1AtBrandtMachPoints.
% Rows 1-2 (M<=Mcrit) are the "trustworthy" comparison points; rows 3-5
% (transonic/supersonic) are known to diverge -- see those tests' comments
% (linear supersonic K1 theory breaks down near M=1 and at high Mach; L1/L2
% have no drag-rise model; L3 has a whole-aircraft wave-drag term
% [F16AeroL3.compute_CD0_wave, Raymer Eqs. 12.44-12.45, corrected 2026-07-23
% to use whole-aircraft Amax/l per F16AeroL3.md] that closes
% most of rows 4-5's gap but does not fully eliminate rows 3-5's divergence).
% CL_alpha_wing, live from BrandtAerodynamics (Aero!A15, per deg) -> per rad.
ref_cl_alpha_wing = brandt_aero.CL_alpha_wing * 57.3;   % /rad  [Brandt Aero!A15]

T_asub = table();
for iM = 1:nBrandt
    label = sprintf('CD0, M=%.4f [-]', brandtM(iM));
    T_asub = [T_asub; trow(label, brandt_polar_model(iM,3), 'Brandt model', cd0_sweep(iM,:), '%.4f')]; %#ok<AGROW>
end
for iM = 1:nBrandt
    label = sprintf('K1,  M=%.4f [-]', brandtM(iM));
    T_asub = [T_asub; trow(label, brandt_polar_model(iM,4), 'Brandt model', k1_sweep(iM,:), '%.4f')]; %#ok<AGROW>
end
T_asub = [T_asub; trow('e_osw [-]',              e_osw_ref,                 'Brandt K1->e_osw', e_osw,       '%.4f')];
T_asub = [T_asub; trow('CLmax clean [-]',         ref_clmax_clean,          'Brandt Aero!H25', clmax,       '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0   [/rad]',  ref_cl_alpha_wing,        'Brandt Aero!A15', cl_alpha_M0, '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0.6 [/rad]',  ref_cl_alpha_wing,        'Brandt Aero!A15', cl_alpha_M06,'%.4f')];

% High-lift-device deltas: L1 tabulated (Roskam Pt.I Tables 3.1/3.6); L2
% flap-geometry-driven (Raymer Eq.12.21/12.61/12.62); L3 adds the LE slat
% (Table 12.2 + Eq.12.21/12.61/12.62 forms) and a component-buildup gear
% term. Grouped by quantity (e_osw / CD0 / CLmax / CDi), each group's raw
% Delta_ row(s) followed by the clean+delta "total" row Brandt can be
% checked against.
T_ahld = trow('Delta_e_osw, TO [-]', NaN, 'Roskam Table 3.6', d_eosw_TO_hld, '%.4f');
T_ahld = [T_ahld; trow('Delta_e_osw, L  [-]', NaN, 'Roskam Table 3.6', d_eosw_L_hld,  '%.4f')];

T_ahld = [T_ahld; trow('Delta_CD0, TO [-]',   NaN, '(no Brandt ref)',      d_cd0_TO,     '%.4f')];
T_ahld = [T_ahld; trow('Delta_CD0, L  [-]',   NaN, '(no Brandt ref)',      d_cd0_L,      '%.4f')];
% CD0,TO total ref from f16a_ground_truth.json (Brandt Miss!CD0_TO = 0.0520,
% Consts row 32). CD0,L total ref is a CITED LITERAL (0.062, Brandt Consts row
% 33 landing flap/gear config) -- no VnV table home for the landing figure.
ref_cd0_TO = GT.aerodynamics.CD0_takeoff.brandt.value;   % 0.0520 [Brandt Consts row 32]
ref_cd0_L  = 0.062;                                      % cited literal [Brandt Consts row 33]
T_ahld = [T_ahld; trow('CD0, TO total [-]',   ref_cd0_TO, 'Brandt Consts row 32', cd0_TO_total, '%.4f')];
T_ahld = [T_ahld; trow('CD0, L  total [-]',   ref_cd0_L,  'Brandt Consts row 33', cd0_L_total,  '%.4f')];

T_ahld = [T_ahld; trow('Delta_CLmax, TO [-]', ref_dclmax_TO,   'Brandt Aero!H27-H25', d_clmax_TO,     '%.4f')];
T_ahld = [T_ahld; trow('Delta_CLmax, L  [-]', ref_dclmax_L,    'Brandt Aero!H29-H25', d_clmax_L,      '%.4f')];
T_ahld = [T_ahld; trow('CLmax, TO total [-]', ref_clmax_TO,    'Brandt Aero!H27',     clmax_TO_total, '%.4f')];
T_ahld = [T_ahld; trow('CLmax, L  total [-]', ref_clmax_L,     'Brandt Aero!H29',     clmax_L_total,  '%.4f')];

T_ahld = [T_ahld; trow('Delta_CDi, TO [-]',   NaN, '(no Brandt ref)', d_cdi_TO, '%.4f')];
T_ahld = [T_ahld; trow('Delta_CDi, L  [-]',   NaN, '(no Brandt ref)', d_cdi_L,  '%.4f')];

% "Brandt actual" (flight-measured) polar at M=1.60, 36 kft -- a different
% table/condition than the polar_model sweep above, kept separately. The M=1.60
% row is in f16a_ground_truth.json (Aero!M6:Q10), read live here.
apolar   = GT.aerodynamics.brandt_actual_polar_vs_mach.rows;   % Brandt Aero!M6:Q10
m160     = arrayfun(@(r) abs(r.mach - 1.60) < 1e-6, apolar);
row_160  = apolar(m160);
T_asup = trow('CD0, M=1.60 [-]',  row_160.CDo, 'Brandt actual', cd0_sup, '%.4f');
T_asup = [T_asup; trow('K1,  M=1.60 [-]',  row_160.k1, 'Brandt actual', k1_sup,  '%.4f')];

% Aero at Brandt's six constraint-analysis conditions -- mirrors
% TestAeroL1/L2/L3's testDragPolarAtConstraintConditions. Reference is
% Brandt's own CD0/K1/K2 at each condition [Brandt Consts sheet].
T_acon = table();
for iC = 1:nCon
    c     = brandt_con.(constraintNames{iC});
    label = sprintf('%-11s alt=%6.0f M=%.2f', constraintNames{iC}, c.alt_ft, c.mach);
    T_acon = [T_acon; trow(['CD0, ' label ' [-]'], c.CD0, 'Brandt Consts', cd0_con(iC,:), '%.4f')]; %#ok<AGROW>
    T_acon = [T_acon; trow(['K1,  ' label ' [-]'], c.K1,  'Brandt Consts', k1_con(iC,:),  '%.4f')]; %#ok<AGROW>
    T_acon = [T_acon; trow(['K2,  ' label ' [-]'], c.K2,  'Brandt Consts', k2_con(iC,:),  '%.4f')]; %#ok<AGROW>
end

ref_tsfc_mil = GT.propulsion.TSFC_mil_installed_per_hr.value;   % 0.70 [Brandt Engn(s)/Main!C30]
T_prop = trow('alpha_AB,  cruise   36k M=0.87 [-]', ref_alpha_AB(36000,0.87),  'Brandt AT24',       alpha_AB_crs,  '%.4f');
T_prop = [T_prop; trow('alpha_mil, cruise   36k M=0.87 [-]', ref_alpha_mil(36000,0.87), 'Brandt AS24->T_AB', alpha_mil_crs, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  comb_sub 20k M=0.87 [-]', ref_alpha_AB(20000,0.87),  'Brandt AT26',       alpha_AB_sub,  '%.4f')];
T_prop = [T_prop; trow('alpha_mil, comb_sub 20k M=0.87 [-]', ref_alpha_mil(20000,0.87), 'Brandt AS26->T_AB', alpha_mil_sub, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  dash     36k M=1.60 [-]', ref_alpha_AB(36000,1.60),  'Brandt AT23',       alpha_AB_dash, '%.4f')];
T_prop = [T_prop; trow('alpha_mil, dash     36k M=1.60 [-]', ref_alpha_mil(36000,1.60), 'Brandt AS23->T_AB', alpha_mil_dash,'%.4f')];
T_prop = [T_prop; trow('alpha_AB,  max_alt  50k M=0.87 [-]', ref_alpha_AB(50000,0.87),  'Brandt AT25',       alpha_AB_malt, '%.4f')];
T_prop = [T_prop; trow('alpha_mil, max_alt  50k M=0.87 [-]', ref_alpha_mil(50000,0.87), 'Brandt AS25->T_AB', alpha_mil_malt,'%.4f')];
T_prop = [T_prop; trow('alpha_AB,  comb_sup 36k M=1.40 [-]', ref_alpha_AB(36000,1.40),  'Brandt AT27',       alpha_AB_sup,  '%.4f')];
T_prop = [T_prop; trow('alpha_mil, comb_sup 36k M=1.40 [-]', ref_alpha_mil(36000,1.40), 'Brandt AS27->T_AB', alpha_mil_sup, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  Ps       10k M=0.87 [-]', ref_alpha_AB(10000,0.87),  'Brandt AT28',       alpha_AB_ps,   '%.4f')];
T_prop = [T_prop; trow('alpha_mil, Ps       10k M=0.87 [-]', ref_alpha_mil(10000,0.87), 'Brandt AS28->T_AB', alpha_mil_ps,  '%.4f')];
T_prop = [T_prop; trow('TSFC_mil, SL M~0 [1/hr]',            ref_tsfc_mil,              'Brandt C30 (SLS)', tsfc_SLS, '%.3f')];
T_prop = [T_prop; trow('TSFC_mil, 36kft M=0.87 [1/hr]',      NaN,                       '(no alt ref)',     tsfc_crs, '%.3f')];

% ── Unified single table ──────────────────────────────────────────────── %
T_all = [srow('[WEIGHTS]');                    T_wts;
         srow('[GEOMETRY]');                   T_geom;
         srow('[AERO — BRANDT MACH SWEEP]');   T_asub;
         srow('[AERO — HIGH-LIFT DEVICES]');   T_ahld;
         srow('[AERO — SUP]');                 T_asup;
         srow('[AERO — CONSTRAINT COND.]');    T_acon;
         srow('[PROPULSION]');                 T_prop];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %

now_str = char(datetime('now','Format','yyyy-MM-dd'));
BAR     = repmat('═', 1, 100);

fprintf('\n%s\n', BAR);
fprintf('  F-16A BLOCK 10  —  FIDELITY COMPARISON GRID\n');
fprintf('  W_TO = %.0f lbf  [Brandt F-16A.xls B38]  |  Generated %s\n', W_TO, now_str);
fprintf('%s\n\n', BAR);

disp(T_all);

fprintf('  NOTES\n');
fprintf('  [WEIGHTS]    Roskam L1 lower bound: We_min=%.0f lbf  (%+.1f%% vs OEW)  [Roskam Eq.2.16 + Table 2.15]\n', ...
    we_roskam_L1, 100*(we_roskam_L1-ref_oew)/ref_oew);
fprintf('  [WEIGHTS]    L2 W_engine/W_all_else_empty are AE481 metabook Sec.7 fractions (1.3x bare engine,\n');
fprintf('               0.17xW_TO) -- independent of the L3 Raymer Eqs 15.7-15.24 buildup; not Brandt-calibrated.\n');
fprintf('  [WEIGHTS]    Component rows (wing/HT/VT/fuselage/gear/engine/all-else) are L2 vs L3 only --\n');
fprintf('               L1 is a single Roskam statistical OEW estimate with no component buildup.\n');
fprintf('               References are Brandt''s [f16a_ground_truth.json .weights.*]: wing/HT/VT/fuselage/nacelles/\n');
fprintf('               strakes from the "Structural Weight Models, average psf" table; gear/engine/duct/\n');
fprintf('               controls/electrical/hydraulics/ECS/other/avionics/armament from the Wt-sheet Group\n');
fprintf('               Weight Statement. "Engine installed" = Brandt Engine+Nacelles+Inlet Duct (closest\n');
fprintf('               match to this framework''s weight_engine_section); "All else empty" = everything\n');
fprintf('               else Brandt counts in OEW (Strakes/Controls/Electrical/Hydraulics/ECS/Other/\n');
fprintf('               Avionics/Armament). Because Strakes/Nacelles are now Structural-Weight-Models\n');
fprintf('               values, these 7 reference values no longer sum exactly to Brandt''s OEW\n');
fprintf('               (19,148 lbf) the way the original all-Wt-sheet figures did.\n');
fprintf('  [GEOMETRY]   L1: Roskam Vol.I Table 3.5; L2: planform+tc (Roskam Eq.12.1) + duct. No L3 (eliminated 2026-07-22, merged into L2).\n');
fprintf('  [GEOMETRY]   Component refs are Brandt Geom-sheet wetted areas; Wing agrees tightly.\n');
fprintf('  [GEOMETRY]   HT/VT %%err is large because this framework''s S_exposed_HT/VT use full\n');
fprintf('               T.O. reference planform area, not Brandt''s fuselage-excluded exposed area.\n');
fprintf('  [GEOMETRY]   Duct %%err is large because it is a different physical quantity than Brandt''s\n');
fprintf('               nacelle reference (inlet-to-exit frustum vs full-cylinder nacelle).\n');
fprintf('  [AERO sub]   CD0=Cf*Swet/Sref; Brandt model is flat for M<=%.4f (no transonic rise at L1/L2).\n', brandt_aero.Mcrit);
fprintf('  [AERO sub]   L3 CD0 now includes CD0_misc = (Dq_gun_port+Dq_hook_USAF)/Sref [Raymer Table 12.7].\n');
fprintf('  [AERO sub]   Mach rows 1-2 (M<=Mcrit) are the trustworthy Brandt comparison; rows 3-5\n');
fprintf('               (transonic/supersonic) diverge by design -- L1/L2 have no drag-rise model,\n');
fprintf('               L3''s wave-drag term (Eqs.12.44-12.45) uses whole-aircraft Amax/l (corrected\n');
fprintf('               2026-07-23, see F16AeroL3.md) and closes most but not all of the\n');
fprintf('               gap; Raymer''s linear supersonic K1 (Eq.12.51) also breaks\n');
fprintf('               down near M=1 and at high Mach for this low-AR, high-sweep wing.\n');
fprintf('  [AERO sub]   e_osw ref: 1/(pi*AR*K1_Brandt); L2/L3 use Raymer Eq.12.48/49 (injected AR,\n');
fprintf('               Lambda_LE). L1=N/A (geometry-free Mattingly type-curve, no Oswald e). CL_alpha\n');
fprintf('               L2/L3 (Raymer Eq.12.6, injected quarter-chord sweep ~32.2deg, NOT the old 37);\n');
fprintf('               L1=N/A (no finite-wing lift-slope method at that fidelity).\n');
fprintf('  [AERO sub]   CLmax: L1 Roskam Pt.I Table 3.1 fighter-column mean (1.50, clean); L2/L3 Raymer\n');
fprintf('               Eq.12.15 sweep-corrected (0.9*cl_max_2D*cos(Lambda_c4)) = 0.914; vortex lift\n');
fprintf('               from the LEX/strake is NOT modeled at any level.\n');
fprintf('               The L1->L2 STEP (1.50 -> 0.914) IS DELIBERATE, not a bug: 1.50 is a type-only\n');
fprintf('               statistical mean over a fighter column dominated by straight/moderately-swept\n');
fprintf('               wings; 0.914 is geometry-based and correctly penalizes a thin 40deg-swept wing.\n');
fprintf('               Different questions at different fidelities; neither is calibrated to the other.\n');
fprintf('               One table throughout at L1 (2026-07-25): the TO/landing increments are Table 3.1\n');
fprintf('               differences, so the clean base must be Table 3.1 too. AeroL1.md has the detail.\n');
fprintf('  [AERO sup]   K2=0 for M>=1 (linearized supersonic theory) — enforced at all fidelity levels.\n');
fprintf('  [AERO hld]   L1: pure tabulation, Roskam Airplane Design Pt.I, Table 3.1 (CLmax by category,\n');
fprintf('               "fighter" row) and Table 3.6 (Delta_CD0/e by flap config, flaps+gear).\n');
fprintf('               L2: flap only, from real geometry -- Delta_CLmax via Raymer Table 12.2 + Eq.12.21\n');
fprintf('               (0.9x factor confirmed correct against the 6th ed. text); Delta_CD0 via Eq.12.61;\n');
fprintf('               Delta_CDi via Eq.12.62; gear CD0 still tabulated (Roskam Table 3.6, no closed-form\n');
fprintf('               gear model exists before L3); Delta_e_osw tabulated at every level (Raymer has no\n');
fprintf('               flapped-wing Oswald-efficiency formula). L3: adds the LE slat the same way for\n');
fprintf('               Delta_CLmax (Table 12.2 + Eq.12.21); Delta_CD0/CDi_slat reuse the SAME Eq.12.61/\n');
fprintf('               12.62 functional forms with the LE device''s own geometry/deflection substituted in\n');
fprintf('               (F_flap->F_slat, delta_flap->delta_slat, flap Cf/C->slat c''/c; k_f->k_slat using the\n');
fprintf('               full-span value since the LEF spans eta=[0,0.98] vs the flaperon''s partial span) --\n');
fprintf('               Raymer''s text gives no separately-cited LE-device formula for either equation, so\n');
fprintf('               this is an extrapolation of the TE form, not an independently-sourced one. L3''s\n');
fprintf('               gear CD0 uses the existing Dq_wheels/Dq_strut_* component buildup (Raymer Table\n');
fprintf('               12.6) instead of the table lookup. F-16 flap/slat panel geometry (chord ratio, span,\n');
fprintf('               deflection) is not in the Brandt/VnV ground truth -- flagged TODO estimates in F16AeroL2/L3.\n');
fprintf('               Flap deflection angles (delta_flap_TO/L_deg) were tuned down from Raymer''s stated\n');
fprintf('               "typical" transport-flap ranges (20-40/60-70 deg) to 15/20 deg, since the F-16''s\n');
fprintf('               flaperon is a small-authority camber device, not a dedicated Fowler/slotted flap --\n');
fprintf('               the original typical-range midpoints overshot Brandt''s TO/landing CD0 by 80-210%%.\n');
fprintf('               Slat deflection (delta_slat_TO/L_deg) uses the SAME value for TO and landing (unlike\n');
fprintf('               the flaperon): the F-16 LEF is scheduled automatically by AOA/Mach via the flight\n');
fprintf('               control computer, not a discrete pilot detent, so both low-speed regimes are modeled\n');
fprintf('               alike. Magnitude (17 deg) is a flagged estimate near the LEF''s publicly documented\n');
fprintf('               ~20-25 deg max, chosen because it brings L3''s CD0,TO/L totals to -5%%/+3%% of Brandt\n');
fprintf('               (vs. -34%%/-21%% with slat CD0=0, i.e. only the gear-buildup undershoot noted below\n');
fprintf('               remained uncorrected) -- adding the slat CD0/CDi term was the fix for that gap, not\n');
fprintf('               a change to the gear buildup itself, which still sums only wheels+struts and remains\n');
fprintf('               a smaller, separate known undershoot vs. Roskam''s/L1-L2''s whole-aircraft-empirical\n');
fprintf('               gear estimate (which implicitly bundles fairings, doors, wells, interference that a\n');
fprintf('               2-item buildup does not model).\n');
fprintf('  [AERO con]   Reference is Brandt''s own CD0/K1/K2 at each condition [Brandt Consts sheet].\n');
fprintf('               cruise/combat_sub/max_alt/ps (M~0.87) match polar_model row 2 to rounding;\n');
fprintf('               dash (M=1.6) and combat_sup (M=1.4) diverge from polar_model''s M=1.5/2.0 rows --\n');
fprintf('               Brandt evaluates the polar per-condition rather than off the 5-point Aero table,\n');
fprintf('               and L1/L2/L3''s linear supersonic K1 (Eq.12.51) diverges from Brandt near/beyond\n');
fprintf('               M=1 anyway (see [AERO sub] note), so those two rows are expected to disagree.\n');
fprintf('  [AERO con]   K2 (L2/L3): CL_minD = CL_alpha(M)*(-deg2rad(alpha_L0)/2)  [Brandt et al. Sec.4.3],\n');
fprintf('               alpha_L0=-1.01deg from NACA 64A204 airfoil data (F16AeroL2/L3 alpha_L0 const,\n');
fprintf('               not a Brandt-calibrated output). Matches Brandt''s sign but not magnitude --\n');
fprintf('               expected, since Brandt''s K2 comes from his own calibrated polar, not this\n');
fprintf('               closed-form CL_alpha/alpha_L0 estimate. L1 K2=0 by design (no airfoil/camber\n');
fprintf('               data at that fidelity, so CL_minD=0 -- symmetric-polar approximation).\n');
fprintf('  [AERO sup]   CD0/K1 M=1.60 ref: Brandt actual (flight-measured polar, 36 kft) -- distinct\n');
fprintf('               from the polar_model sweep in [AERO — BRANDT MACH SWEEP].\n');
fprintf('  [PROPULSION] alpha_AB and alpha_mil normalised by T_SL_AB = %.0f lbf  [Brandt D29]\n', J_geo.engine.T_AB_SLS_lb);
fprintf('  [PROPULSION] L1 alpha: sigma^0.6 density-ratio lapse only — no Mach correction, no mil/AB split.\n');
fprintf('  [PROPULSION] L2 alpha: Mattingly Eq. 2.54 (TR=1.0) has no Mach term in either theta0 branch,\n');
fprintf('               vs Brandt''s -C_M*M^e_M penalty (dry C_M=0.3, AB C_M=0.1) in both branches.\n');
fprintf('               This is largest for alpha_mil at high Mach (dash M=1.6, comb_sup M=1.4): the\n');
fprintf('               missing dry-power Mach term is 3x the AB one and shares the same T_SL_AB-basis\n');
fprintf('               denominator, so those two rows show 55-65%% relative error though under 0.13\n');
fprintf('               absolute -- expected model divergence, not a computation bug (see TestPropL2).\n');
fprintf('  [PROPULSION] L1 TSFC: Raymer Table 3.3 categorical; L2: Mattingly Eq.3.55a (C1+C2*M)*sqrt(theta).\n');
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %

script_dir = fileparts(mfilename('fullpath'));
out_xlsx   = fullfile(script_dir, 'fidelity_comparison.xlsx');
out_json   = fullfile(script_dir, 'jsons', 'fidelity_comparison.json');

% ── Excel (single sheet) ──────────────────────────────────────────────── %
if exist(out_xlsx, 'file'); delete(out_xlsx); end
writetable(T_all, out_xlsx, 'Sheet', 'Fidelity Comparison', 'WriteRowNames', true);
fprintf('  Excel  → %s\n', out_xlsx);

% ── JSON (flat rows array) ────────────────────────────────────────────── %
data.generated = now_str;
data.aircraft  = 'F-16A Block 10';
data.W_TO_lbf  = W_TO;
data.rows      = table_to_rows(T_all);

fid = fopen(out_json, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON   → %s\n\n', out_json);

end

% ─── local helpers ───────────────────────────────────────────────────── %

function a = brandt_alpha_ref(eng, alt_ft, mach, AB_p)
%BRANDT_ALPHA_REF  Brandt thrust lapse on the T_SL_AB axis at one condition.
%   AB_p = 1.0 -> full-AB lapse (Consts col AT); AB_p = 0.0 -> mil/dry lapse on
%   the same T_SL_AB axis (Consts col AU). Wraps BrandtEngine.run so the struct
%   field access is unambiguous (no chained indexing on a call result).
    r = eng.run(alt_ft, mach, AB_p);
    a = r.alpha_AB_ref;
end

function T = trow(name, ref, src, vals, numfmt)
%TROW  One-row MATLAB table for the fidelity comparison grid.
    if isnan(ref)
        ref_s = 'N/A';
    else
        ref_s = sprintf(numfmt, ref);
    end
    val_c = {'N/A', 'N/A', 'N/A'};
    err_c = {' - ',  ' - ',  ' - '};
    for i = 1:min(numel(vals), 3)
        if ~isnan(vals(i))
            val_c{i} = sprintf(numfmt, vals(i));
            if ~isnan(ref) && ref ~= 0
                err_c{i} = sprintf('%+.1f%%', 100*(vals(i)-ref)/ref);
            end
        end
    end
    T = table({ref_s}, {src}, val_c(1), err_c(1), val_c(2), err_c(2), val_c(3), err_c(3), ...
        'VariableNames', {'Reference','Source','L1','L1_err','L2','L2_err','L3','L3_err'}, ...
        'RowNames', {name});
end

function rows = table_to_rows(T)
%TABLE_TO_ROWS  Convert a comparison table to a struct array for jsonencode.
    n = height(T);
    for r = n:-1:1   % reverse iteration pre-allocates the struct array
        rows(r).parameter = T.Properties.RowNames{r};
        rows(r).Reference = T.Reference{r};
        rows(r).Source    = T.Source{r};
        rows(r).L1        = T.L1{r};
        rows(r).L1_err    = T.L1_err{r};
        rows(r).L2        = T.L2{r};
        rows(r).L2_err    = T.L2_err{r};
        rows(r).L3        = T.L3{r};
        rows(r).L3_err    = T.L3_err{r};
    end
end

function T = srow(label)
%SROW  Section separator row for the unified fidelity table.
%   Appears as a labelled divider in the console display and Excel export.
    T = table({'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
        'VariableNames', {'Reference','Source','L1','L1_err','L2','L2_err','L3','L3_err'}, ...
        'RowNames', {label});
end

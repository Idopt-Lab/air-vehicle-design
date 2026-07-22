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

b    = F16Baseline();
W_TO = b.brandt.TOGW;   % 31,377 lbf  [Brandt B38]

% Flight conditions used throughout
st_SL_001 = AircraftState(0,     0.01);  % SL M~0  (TSFC SLS reference)
st_SL_050 = AircraftState(0,     0.50);  % SL M=0.5 (subsonic aero)
st_10_087 = AircraftState(10000, 0.87);  % 10 kft M=0.87 (Ps constraint)
st_20_087 = AircraftState(20000, 0.87);  % 20 kft M=0.87 (1st combat turn)
st_36_087 = AircraftState(36000, 0.87);  % 36 kft M=0.87 (cruise / propulsion)
st_36_140 = AircraftState(36000, 1.40);  % 36 kft M=1.4  (2nd combat turn)
st_36_160 = AircraftState(36000, 1.60);  % 36 kft M=1.6  (dash / supersonic aero / polar_actual)
st_50_087 = AircraftState(50000, 0.87);  % 50 kft M=0.87 (max altitude)

% ── Weights ───────────────────────────────────────────────────────────── %
w1 = F16WeightsL1();
w2 = F16WeightsL2();
w3 = F16WeightsL3();

oew          = [w1.OEW(W_TO), w2.OEW(W_TO), w3.OEW(W_TO)];
wefrac       = oew / W_TO;
we_roskam_L1 = w1.compute_We_roskam(W_TO);

% ── Geometry ──────────────────────────────────────────────────────────── %
% Geometry has only L1/L2 fidelity tiers (L3 eliminated and merged into L2,
% 2026-07-22 -- see src/disciplines/geometry/GeomL2.md's dated note). L2 now
% carries the full HT/VT breakdown + duct that used to live on a separate
% F16GeomL3 class, so the L3 column below is NaN throughout (not a missing
% class -- Geometry genuinely stops at L2).
g1 = F16GeomL1();
g2 = F16GeomL2();

swet    = [g1.get_S_wet(W_TO), g2.get_S_wet(),      NaN];
lfus    = [g1.get_L_fus(W_TO), g2.L_fus,                NaN];
sw_wing = [NaN,                g2.get_S_wet_wing(),      NaN];
sw_ht   = [NaN,                g2.get_S_wet_HT(),        NaN];
sw_vt   = [NaN,                g2.get_S_wet_VT(),        NaN];
sw_fus  = [NaN,                g2.get_S_wet_fuselage(),  NaN];
sw_duct = [NaN,                g2.get_S_wet_duct(),      NaN];

% ── Aerodynamics ──────────────────────────────────────────────────────── %
a1 = F16AeroL1();
a2 = F16AeroL2();
a3 = F16AeroL3();

pu1 = a1.drag_polar(st_36_160); pu2 = a2.drag_polar(st_36_160); pu3 = a3.drag_polar(st_36_160);

cd0_sup    = [pu1.CD0, pu2.CD0, pu3.CD0];
k1_sup     = [pu1.K1,  pu2.K1,  pu3.K1 ];
clmax      = [a1.get_CLmax(st_SL_050), a2.get_CLmax(st_SL_050), a3.get_CLmax(st_SL_050)];
e_osw      = [a1.get_e_osw(), a2.get_e_osw(), NaN];
cl_alpha_M0  = [NaN, a2.get_CL_alpha(0.0), NaN];
cl_alpha_M06 = [NaN, a2.get_CL_alpha(0.6), NaN];

% Brandt's 5 tabulated Mach breakpoints (b.brandt.polar_model), sea level --
% same points/method as TestAeroL1/L2/L3's testCD0AtBrandtMachPoints and
% testK1AtBrandtMachPoints.
brandtM  = b.brandt.polar_model(:,1);
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
% CD0/K1/K2 at each condition (b.constraints.*.CD0/K1/K2, from the Consts
% sheet) are used as Reference below.
constraintNames  = {'cruise', 'combat_sub', 'dash', 'max_alt', 'combat_sup', 'ps'};
constraintStates = {st_36_087, st_20_087, st_36_160, st_50_087, st_36_140, st_10_087};
nCon = numel(constraintNames);
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
p1 = F16PropL1();
p2 = F16PropL2();

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

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD SECTION TABLES
% ════════════════════════════════════════════════════════════════════════ %

T_wts = trow('OEW [lbf]',    b.brandt.OEW,      'Brandt B12',     oew,    '%.0f' );
T_wts = [T_wts; trow('We/W_TO [-]', b.brandt.OEW/W_TO, 'Brandt B12/B38', wefrac, '%.4f')];

T_geom = trow('S_wet total [ft2]',  b.brandt.S_wet, 'Brandt Main!L3', swet,    '%.1f');
T_geom = [T_geom; trow('L_fus [ft]',         b.geom.L_fus,   'TO Fig. 1-2',    lfus,    '%.2f')];
T_geom = [T_geom; trow('  Wing S_wet [ft2]', b.brandt.S_wet_wing,    'Brandt Geom!B14',      sw_wing, '%.1f')];
T_geom = [T_geom; trow('  HT   S_wet [ft2]', b.brandt.S_wet_HT,      'Brandt Geom!B16',      sw_ht,   '%.1f')];
T_geom = [T_geom; trow('  VT   S_wet [ft2]', b.brandt.S_wet_VT,      'Brandt Geom!B17',      sw_vt,   '%.1f')];
T_geom = [T_geom; trow('  Fus  S_wet [ft2]', b.brandt.S_wet_fus_alt, 'Brandt Geom!D23',      sw_fus,  '%.1f')];
T_geom = [T_geom; trow('  Duct S_wet [ft2]', b.brandt.S_wet_duct,    'Brandt Geom!B4 (nacelle)', sw_duct, '%.1f')];

e_osw_ref = 1 / (pi * b.geom.AR * b.brandt.polar_model(1,4));   % Brandt K1 → derived e_osw

% CD0 and K1 across all 5 of Brandt's tabulated Mach breakpoints, sea level
% -- mirrors TestAeroL1/L2/L3's testCD0AtBrandtMachPoints/testK1AtBrandtMachPoints.
% Rows 1-2 (M<=Mcrit) are the "trustworthy" comparison points; rows 3-5
% (transonic/supersonic) are known to diverge -- see those tests' comments
% (linear supersonic K1 theory breaks down near M=1 and at high Mach; L1/L2
% have no drag-rise model; L3 has no wave drag yet).
T_asub = table();
for iM = 1:nBrandt
    label = sprintf('CD0, M=%.4f [-]', brandtM(iM));
    T_asub = [T_asub; trow(label, b.brandt.polar_model(iM,3), 'Brandt model', cd0_sweep(iM,:), '%.4f')]; %#ok<AGROW>
end
for iM = 1:nBrandt
    label = sprintf('K1,  M=%.4f [-]', brandtM(iM));
    T_asub = [T_asub; trow(label, b.brandt.polar_model(iM,4), 'Brandt model', k1_sweep(iM,:), '%.4f')]; %#ok<AGROW>
end
T_asub = [T_asub; trow('e_osw [-]',              e_osw_ref,                 'Brandt K1->e_osw', e_osw,       '%.4f')];
T_asub = [T_asub; trow('CLmax clean [-]',         b.brandt.CLmax_clean,      'Brandt L8',       clmax,       '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0   [/rad]',  b.brandt.CL_alpha_wing,    'Brandt Aero!A15', cl_alpha_M0, '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0.6 [/rad]',  b.brandt.CL_alpha_wing,    'Brandt Aero!A15', cl_alpha_M06,'%.4f')];

% "Brandt actual" (flight-measured) polar at M=1.60, 36 kft -- a different
% table/condition than the polar_model sweep above, kept separately.
T_asup = trow('CD0, M=1.60 [-]',  b.brandt.polar_actual(4,3), 'Brandt actual', cd0_sup, '%.4f');
T_asup = [T_asup; trow('K1,  M=1.60 [-]',  b.brandt.polar_actual(4,4), 'Brandt actual', k1_sup,  '%.4f')];

% Aero at Brandt's six constraint-analysis conditions -- mirrors
% TestAeroL1/L2/L3's testDragPolarAtConstraintConditions. Reference is
% Brandt's own CD0/K1/K2 at each condition [Brandt Consts sheet].
T_acon = table();
for iC = 1:nCon
    c     = b.constraints.(constraintNames{iC});
    label = sprintf('%-11s alt=%6.0f M=%.2f', constraintNames{iC}, c.alt_ft, c.mach);
    T_acon = [T_acon; trow(['CD0, ' label ' [-]'], c.CD0, 'Brandt Consts', cd0_con(iC,:), '%.4f')]; %#ok<AGROW>
    T_acon = [T_acon; trow(['K1,  ' label ' [-]'], c.K1,  'Brandt Consts', k1_con(iC,:),  '%.4f')]; %#ok<AGROW>
    T_acon = [T_acon; trow(['K2,  ' label ' [-]'], c.K2,  'Brandt Consts', k2_con(iC,:),  '%.4f')]; %#ok<AGROW>
end

T_prop = trow('alpha_AB,  cruise   36k M=0.87 [-]', b.constraints.cruise.alpha_AB,            'Brandt AT24',       alpha_AB_crs,  '%.4f');
T_prop = [T_prop; trow('alpha_mil, cruise   36k M=0.87 [-]', b.constraints.cruise.alpha_mil_T_AB,    'Brandt AS24->T_AB', alpha_mil_crs, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  comb_sub 20k M=0.87 [-]', b.constraints.combat_sub.alpha_AB,      'Brandt AT26',       alpha_AB_sub,  '%.4f')];
T_prop = [T_prop; trow('alpha_mil, comb_sub 20k M=0.87 [-]', b.constraints.combat_sub.alpha_mil_T_AB,'Brandt AS26->T_AB', alpha_mil_sub, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  dash     36k M=1.60 [-]', b.constraints.dash.alpha_AB,            'Brandt AT23',       alpha_AB_dash, '%.4f')];
T_prop = [T_prop; trow('alpha_mil, dash     36k M=1.60 [-]', b.constraints.dash.alpha_mil_T_AB,      'Brandt AS23->T_AB', alpha_mil_dash,'%.4f')];
T_prop = [T_prop; trow('alpha_AB,  max_alt  50k M=0.87 [-]', b.constraints.max_alt.alpha_AB,         'Brandt AT25',       alpha_AB_malt, '%.4f')];
T_prop = [T_prop; trow('alpha_mil, max_alt  50k M=0.87 [-]', b.constraints.max_alt.alpha_mil_T_AB,   'Brandt AS25->T_AB', alpha_mil_malt,'%.4f')];
T_prop = [T_prop; trow('alpha_AB,  comb_sup 36k M=1.40 [-]', b.constraints.combat_sup.alpha_AB,      'Brandt AT27',       alpha_AB_sup,  '%.4f')];
T_prop = [T_prop; trow('alpha_mil, comb_sup 36k M=1.40 [-]', b.constraints.combat_sup.alpha_mil_T_AB,'Brandt AS27->T_AB', alpha_mil_sup, '%.4f')];
T_prop = [T_prop; trow('alpha_AB,  Ps       10k M=0.87 [-]', b.constraints.ps.alpha_AB,              'Brandt AT28',       alpha_AB_ps,   '%.4f')];
T_prop = [T_prop; trow('alpha_mil, Ps       10k M=0.87 [-]', b.constraints.ps.alpha_mil_T_AB,        'Brandt AS28->T_AB', alpha_mil_ps,  '%.4f')];
T_prop = [T_prop; trow('TSFC_mil, SL M~0 [1/hr]',            b.engine.TSFC_mil,                      'Brandt C30 (SLS)', tsfc_SLS, '%.3f')];
T_prop = [T_prop; trow('TSFC_mil, 36kft M=0.87 [1/hr]',      NaN,                                    '(no alt ref)',     tsfc_crs, '%.3f')];

% ── Unified single table ──────────────────────────────────────────────── %
T_all = [srow('[WEIGHTS]');                    T_wts;
         srow('[GEOMETRY]');                   T_geom;
         srow('[AERO — BRANDT MACH SWEEP]');   T_asub;
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
    we_roskam_L1, 100*(we_roskam_L1-b.brandt.OEW)/b.brandt.OEW);
fprintf('  [WEIGHTS]    L2 W_engine/W_all_else_empty computed from WeightsL3 Eqs 15.7-15.24 (not Brandt-calibrated).\n');
fprintf('  [GEOMETRY]   L1: Roskam Vol.I Table 3.5; L2: planform+tc (Roskam Eq.12.1) + duct. No L3 (eliminated 2026-07-22, merged into L2).\n');
fprintf('  [GEOMETRY]   Component refs are Brandt Geom-sheet wetted areas; Wing agrees tightly.\n');
fprintf('  [GEOMETRY]   HT/VT %%err is large because this framework''s S_exposed_HT/VT use full\n');
fprintf('               T.O. reference planform area, not Brandt''s fuselage-excluded exposed area.\n');
fprintf('  [GEOMETRY]   Duct %%err is large because it is a different physical quantity than Brandt''s\n');
fprintf('               nacelle reference (inlet-to-exit frustum vs full-cylinder nacelle).\n');
fprintf('  [AERO sub]   CD0=Cf*Swet/Sref; Brandt model is flat for M<=%.4f (no transonic rise at L1/L2).\n', b.brandt.Mcrit);
fprintf('  [AERO sub]   L3 CD0 now includes CD0_misc = (Dq_gun_port+Dq_hook_USAF)/Sref [Raymer Table 12.7].\n');
fprintf('  [AERO sub]   Mach rows 1-2 (M<=Mcrit) are the trustworthy Brandt comparison; rows 3-5\n');
fprintf('               (transonic/supersonic) diverge by design -- L1/L2 have no drag-rise model,\n');
fprintf('               L3 has no wave drag yet, and Raymer''s linear supersonic K1 (Eq.12.51) breaks\n');
fprintf('               down near M=1 and at high Mach for this low-AR, high-sweep wing.\n');
fprintf('  [AERO sub]   e_osw ref: 1/(pi*AR*K1_Brandt). CL_alpha L2 only (Raymer Eq.12.6); L1/L3=N/A.\n');
fprintf('  [AERO sub]   CLmax: L1/L3 Roskam historical table; L2 Raymer sweep-corrected formula.\n');
fprintf('  [AERO sup]   K2=0 for M>=1 (linearized supersonic theory) — enforced at all fidelity levels.\n');
fprintf('  [AERO con]   Reference is Brandt''s own CD0/K1/K2 at each condition [Brandt Consts sheet].\n');
fprintf('               cruise/combat_sub/max_alt/ps (M~0.87) match polar_model row 2 to rounding;\n');
fprintf('               dash (M=1.6) and combat_sup (M=1.4) diverge from polar_model''s M=1.5/2.0 rows --\n');
fprintf('               Brandt evaluates the polar per-condition rather than off the 5-point Aero table,\n');
fprintf('               and L1/L2/L3''s linear supersonic K1 (Eq.12.51) diverges from Brandt near/beyond\n');
fprintf('               M=1 anyway (see [AERO sub] note), so those two rows are expected to disagree.\n');
fprintf('  [AERO con]   K2 rows read ~0 (-100%% vs Brandt''s nonzero calibrated K2) because F16Aero*''s\n');
fprintf('               CL_minD=0 -- K2=-2*K1*CL_minD is identically 0 in this framework''s subsonic\n');
fprintf('               polar until CL_minD is sourced from an F-16 spec value (a pre-existing gap).\n');
fprintf('  [AERO sup]   CD0/K1 M=1.60 ref: Brandt actual (flight-measured polar, 36 kft) -- distinct\n');
fprintf('               from the polar_model sweep in [AERO — BRANDT MACH SWEEP].\n');
fprintf('  [PROPULSION] alpha_AB and alpha_mil normalised by T_SL_AB = %.0f lbf  [Brandt D29]\n', b.engine.T_max);
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
out_json   = fullfile(script_dir, 'fidelity_comparison.json');

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

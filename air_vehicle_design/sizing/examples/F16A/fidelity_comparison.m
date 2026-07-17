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
st_36_150 = AircraftState(36000, 1.50);  % 36 kft M=1.50 (Brandt polar_model row 4)
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
g1 = F16GeomL1();
g2 = F16GeomL2();
g3 = F16GeomL3();

swet    = [g1.get_S_wet(W_TO), g2.get_S_wet(W_TO),      g3.get_S_wet(W_TO)     ];
lfus    = [g1.get_L_fus(W_TO), g2.L_fus,                g3.L_fus               ];
sw_wing = [NaN,                g2.get_S_wet_wing(),      g3.get_S_wet_wing()    ];
sw_ht   = [NaN,                g2.get_S_wet_HT(),        g3.get_S_wet_HT()      ];
sw_vt   = [NaN,                g2.get_S_wet_VT(),        g3.get_S_wet_VT()      ];
sw_fus  = [NaN,                g2.get_S_wet_fuselage(),  g3.get_S_wet_fuselage()];
sw_duct = [NaN,                NaN,                      g3.get_S_wet_duct()    ];

% ── Aerodynamics ──────────────────────────────────────────────────────── %
a1 = F16AeroL1();
a2 = F16AeroL2();
a3 = F16AeroL3();

ps1 = a1.drag_polar(st_SL_050); ps2 = a2.drag_polar(st_SL_050); ps3 = a3.drag_polar(st_SL_050);
pm1 = a1.drag_polar(st_36_150); pm2 = a2.drag_polar(st_36_150); pm3 = a3.drag_polar(st_36_150);
pu1 = a1.drag_polar(st_36_160); pu2 = a2.drag_polar(st_36_160); pu3 = a3.drag_polar(st_36_160);

cd0_sub    = [ps1.CD0, ps2.CD0, ps3.CD0];
k1_sub     = [ps1.K1,  ps2.K1,  ps3.K1 ];
cd0_sup    = [pu1.CD0, pu2.CD0, pu3.CD0];
k1_sup     = [pu1.K1,  pu2.K1,  pu3.K1 ];
k1_M15     = [pm1.K1,  pm2.K1,  pm3.K1 ];
clmax      = [a1.get_CLmax(st_SL_050), a2.get_CLmax(st_SL_050), a3.get_CLmax(st_SL_050)];
e_osw      = [a1.get_e_osw(), a2.get_e_osw(), NaN];
cl_alpha_M0  = [NaN, a2.get_CL_alpha(0.0), NaN];
cl_alpha_M06 = [NaN, a2.get_CL_alpha(0.6), NaN];

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
T_geom = [T_geom; trow('  Wing S_wet [ft2]', NaN,            '-',              sw_wing, '%.1f')];
T_geom = [T_geom; trow('  HT   S_wet [ft2]', NaN,            '-',              sw_ht,   '%.1f')];
T_geom = [T_geom; trow('  VT   S_wet [ft2]', NaN,            '-',              sw_vt,   '%.1f')];
T_geom = [T_geom; trow('  Fus  S_wet [ft2]', NaN,            '-',              sw_fus,  '%.1f')];
T_geom = [T_geom; trow('  Duct S_wet [ft2]', NaN,            '-',              sw_duct, '%.1f')];

e_osw_ref = 1 / (pi * b.geom.AR * b.brandt.polar_model(1,4));   % Brandt K1 → derived e_osw

T_asub = trow('CD0 [-]',              b.brandt.polar_model(1,3), 'Brandt model',    cd0_sub,     '%.4f');
T_asub = [T_asub; trow('e_osw [-]',              e_osw_ref,                 'Brandt K1->e_osw', e_osw,       '%.4f')];
T_asub = [T_asub; trow('K1 [-]',                 b.brandt.polar_model(1,4), 'Brandt model',    k1_sub,      '%.4f')];
T_asub = [T_asub; trow('CLmax clean [-]',         b.brandt.CLmax_clean,      'Brandt L8',       clmax,       '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0   [/rad]',  b.brandt.CL_alpha_wing,    'Brandt Aero!A15', cl_alpha_M0, '%.4f')];
T_asub = [T_asub; trow('CL_alpha, M=0.6 [/rad]',  b.brandt.CL_alpha_wing,    'Brandt Aero!A15', cl_alpha_M06,'%.4f')];

T_asup = trow('CD0, M=1.60 [-]',  b.brandt.polar_actual(4,3), 'Brandt actual', cd0_sup, '%.4f');
T_asup = [T_asup; trow('K1,  M=1.60 [-]',  b.brandt.polar_actual(4,4), 'Brandt actual', k1_sup,  '%.4f')];
T_asup = [T_asup; trow('K1,  M=1.50 [-]',  b.brandt.polar_model(4,4),  'Brandt model',  k1_M15,  '%.4f')];

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
T_all = [srow('[WEIGHTS]');           T_wts;
         srow('[GEOMETRY]');          T_geom;
         srow('[AERO — SL M=0.50]');  T_asub;
         srow('[AERO — SUP]');        T_asup;
         srow('[PROPULSION]');        T_prop];

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
fprintf('  [WEIGHTS]    L2 W_engine/W_all_else_empty calibrated to Brandt B12 — OEW matches by construction.\n');
fprintf('  [GEOMETRY]   L1: Roskam Vol.I Table 3.5; L2: planform+tc; L3: adds inlet duct.\n');
fprintf('  [GEOMETRY]   Component sub-rows have no external reference (ref=N/A, %%err omitted).\n');
fprintf('  [AERO sub]   CD0=Cf*Swet/Sref; Brandt model is flat for M<=%.4f (no transonic rise at L1/L2).\n', b.brandt.Mcrit);
fprintf('  [AERO sub]   e_osw ref: 1/(pi*AR*K1_Brandt). CL_alpha L2 only (Raymer Eq.12.6); L1/L3=N/A.\n');
fprintf('  [AERO sub]   CLmax: L1/L3 Roskam historical table; L2 Raymer sweep-corrected formula.\n');
fprintf('  [AERO sup]   K2=0 for M>=1 (linearized supersonic theory) — enforced at all fidelity levels.\n');
fprintf('  [AERO sup]   K1 M=1.50 ref: Brandt model (0.2516); K1/CD0 M=1.60 ref: Brandt actual.\n');
fprintf('  [PROPULSION] alpha_AB and alpha_mil normalised by T_SL_AB = %.0f lbf  [Brandt D29]\n', b.engine.T_max);
fprintf('  [PROPULSION] L1 alpha: sigma^0.6 density-ratio lapse only — no Mach correction, no mil/AB split.\n');
fprintf('  [PROPULSION] L2 alpha: Mattingly Eq. 2.54 (TR=1.0); below-TR lacks Mach correction vs Brandt.\n');
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

%% run_aero481_sizing_L1
%   F-35 (Aero 481 Design01 provenance) Level-1 sizing study. Reproduces Aero
%   481's A02 sizing: the F-35 is sized at the REAL F135 thrust in a FIXED (T, S)
%   cell, NOT at the constraint-diagram optimum.
%
%   WHY A FIXED CELL. Aero 481 Design01 fixes W/S = 92.17 psf and T/W = 1.2 as
%   design CHOICES and sizes at that point. T/W = 1.2 is ASPIRATIONAL: the real
%   F135 (43,000 lbf) gives ACTUAL T/W ~ 0.70 at the ~61k TOGW. The A02 engine
%   delta (Aero481WeightsL1.OEW) credits that difference, so the F-35 sizes SMALL.
%
%   HOW. TSDiagram.converge_W0(T_SL, S_ref) IS the A02 fixed-cell closure: it
%   writes prop.T_SL and geom.S_ref, then iterates the TOGW fixed point
%   [metabook S4.12 Algorithm 2 / Raymer 6th ed. Eq. 3.4]. Called at the real
%   F135 thrust and the design wing (S = 538 ft^2 ~ 50 m^2). It leaves
%   geom/prop/wts at that cell's state, so OEW and fuel are read straight back.
%
%   VALIDATION. Aero 481's A02 sizes to ~62,399 lb at (Design01, 43,000 lbf,
%   50 m^2) [A481 +Algorithms/A02.m]; the framework reproduces within ~2% (lapse
%   OFF, disc A6). The published-F-35A gap (disc A5) is a fidelity/design gap.
%   See sanity_checks/aero481_comparison.m.

sp = aero481_spec_path(1);
rp = aero481_requirements_path();

% Caller owns discipline construction (dependency injection). TSDiagram mutates
% the shared geom/prop/wts in place during converge_W0. The weights object is
% the A481 A02 delta model -- three-arg constructor (injects geom, prop).
aero = Aero481AeroL1(sp);
prop = Aero481PropL1(sp);
geom = Aero481GeomL1(sp, rp);
tail = Aero481TailL1();
wts  = Aero481WeightsL1(sp, geom, prop);   % A481 A02 delta model -- injects geom (S_ref) + prop (T_SL)
miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "dca");

% The constraint set is built for context but does NOT drive the sizing -- the
% fixed (T, S) cell does.
WS_sweep = linspace(20, 200, 181);
con = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
    Aero481ConstraintSet.constraint_map(), WS_sweep);

ts = TSDiagram(aero, prop, wts, geom, miss, con, tail);

% ---- Size the fixed A02 (T, S) cell: real F135 thrust, design wing --------- %
T_design = 43000;    % lbf  F135 SLS with afterburner (the REAL engine) [aero481_data.md Part I]
S_design = 538;      % ft^2 Aero 481 Design01 design wing (~50 m^2)     [A481 A02 design cell]

W_TO = ts.converge_W0(T_design, S_design);   % [metabook Algorithm 2 = A481 A02 fixed-cell closure]

% converge_W0 left geom/prop/wts at this cell's state, so OEW and mission fuel
% are consistent with the returned W_TO. Read them back directly.
W_OEW  = wts.OEW(W_TO);
[W_fuel, ~] = miss.total_fuel(W_TO);
WS     = W_TO / S_design;      % actual wing loading at the sized weight [psf]
TW     = T_design / W_TO;      % ACTUAL thrust-to-weight (~0.70, not 1.2)

% L/Dmax from the clean polar (K2 = 0): 1/(2*sqrt(CD0*K1)); cruise TSFC.
p      = aero.drag_polar([]);
LDmax  = 1 / (2 * sqrt(p.CD0 * p.K1));
tsfc_c = prop.get_TSFC(AircraftState(35000, 0.85));

% Aero 481 A02 reference at the design cell (for the faithfulness check).
A02_ref = 62399;   % lbf  A02(Design01, 43,000 lbf, 50 m^2) [A481 +Algorithms/A02.m]
pct_A02 = 100 * (W_TO - A02_ref) / A02_ref;

fprintf('\nF-35 L1 sizing study -- A02 fixed-cell reproduction [Aero 481 Design01]\n');
fprintf('  Sized at the REAL F135 thrust (T = %.0f lbf) and design wing (S = %.0f ft^2)\n', ...
    T_design, S_design);
fprintf('  TOGW        = %8.0f lbf   (A02 ref %.0f, %+.2f%%)\n', W_TO, A02_ref, pct_A02);
fprintf('  OEW         = %8.0f lbf\n', W_OEW);
fprintf('  fuel        = %8.0f lbf\n', W_fuel);
fprintf('  W/S         = %8.2f psf   (at the sized TOGW)\n', WS);
fprintf('  T/W         = %8.4f       (ACTUAL 43000/W_TO -- Design01 1.2 is aspirational)\n', TW);
fprintf('  L/Dmax      = %8.2f       (clean polar CD0=%.4f K1=%.5f)\n', LDmax, p.CD0, p.K1);
fprintf('  cruise TSFC = %8.3f 1/hr  (M0.85 / 35 kft)\n', tsfc_c);
fprintf('  --- faithful to Aero 481 A02 (%.0f lb, ~2%%); published F-35A MTOW ~65,900-70,000 lb ---\n', A02_ref);

% ---- Exports into the gitignored output/ (sanity_checks pattern) ---------- %
outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
if ~exist(outdir, 'dir'), mkdir(outdir); end

res = struct('stack', 'Aero481 L1 disciplines x L1 DCA mission (Aero 481 A02 fixed-cell)', ...
    'T_design_lbf', T_design, 'S_design_ft2', S_design, ...
    'W_TO_lbf', W_TO, 'OEW_lbf', W_OEW, 'W_fuel_lbf', W_fuel, ...
    'WS_psf', WS, 'TW_actual', TW, ...
    'LDmax', LDmax, 'cruise_TSFC', tsfc_c, ...
    'A02_ref_lbf', A02_ref, 'pct_vs_A02', pct_A02, ...
    'design01_point', struct('WS_psf', 92.17, 'TW', 1.2, ...
        'note', 'aspirational design choice; actual T/W = 43000/W_TO', ...
        'cite', 'A481 Design01.m:20-21'));
fid = fopen(fullfile(outdir, 'aero481_sizing_L1.json'), 'w');
fwrite(fid, jsonencode(res, 'PrettyPrint', true));
fclose(fid);
fprintf('\nWrote output/aero481_sizing_L1.json\n');

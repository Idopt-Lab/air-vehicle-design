%% run_aero481_sizing_L1
%   F-35 (Aero 481 Design01 provenance) Level-1 sizing study. Reproduces Aero
%   481's A02 sizing result: the F-35 is sized at the REAL F135 thrust in a
%   FIXED (T, S) cell, NOT at the constraint-diagram optimum.
%
%   WHY A FIXED (T, S) CELL, NOT THE CONSTRAINT OPTIMUM (read this first).
%   Aero 481 Design01 fixes W/S = 92.17 psf and T/W = 1.2 as design CHOICES, and
%   its A02 algorithm sizes the aircraft at that design point -- it does NOT read
%   a T/W off the constraint envelope. The Design01 T/W = 1.2 is ASPIRATIONAL:
%   the real F-35A carries the F135 (43,000 lbf SLS with afterburner), and at the
%   ~61k TOGW the framework sizes to, the ACTUAL T/W = 43,000 / W_TO ~ 0.70 -- far
%   below 1.2. The A02 engine delta (Aero481WeightsL1.OEW) credits exactly that
%   difference: installing a 43,000 lbf engine instead of the design-T/W-implied
%   ~74,880 lbf engine is a large negative OEW term, which is why the F-35 sizes
%   SMALL (~61k) rather than to a heavy aspirational-thrust point. Sizing at the
%   constraint optimum would size a DIFFERENT (aspirational-T/W) aircraft, not
%   Aero 481's -- so this study drives the fixed-cell A02 closure directly.
%
%   HOW. The framework's TSDiagram.converge_W0(T_SL, S_ref) IS the A02 fixed-cell
%   closure: it writes prop.T_SL and geom.S_ref, then iterates the TOGW fixed
%   point [metabook S4.12 Algorithm 2 / Raymer 6th ed. Eq. 3.4] on the mission
%   fuel fraction and the A02 empty-weight build-up. Called at the real F135
%   thrust (43,000 lbf) and the design wing (S = 538 ft^2 ~ 50 m^2), it returns
%   the sized F-35 TOGW. converge_W0 leaves geom/prop/wts at that cell's state,
%   so OEW and mission fuel are read straight back afterward.
%
%   Style/wiring follows examples/F16A/models/sizing/f16_sizing_L1.m and the B777
%   studies; export follows the sanity_checks scripts (console + files into the
%   gitignored output/).
%
%   VALIDATION CONTEXT. Aero 481's A02 sizes the F-35 to ~62,399 lb at
%   (Design01, 43,000 lbf, 50 m^2) [A481 +Algorithms/A02.m]. The framework
%   reproduces that within ~2% (lapse is now OFF, matching A481 -- disc A6
%   resolved). Cross-check to the published F-35A (MTOW ~65,900-70,000 lb) is a
%   fidelity/design gap (disc A5), NOT a bug -- Design01's AR/wing differ from
%   the real jet. See sanity_checks/aero481_comparison.m.

sp = aero481_spec_path(1);
rp = aero481_requirements_path();

% Caller owns discipline construction (dependency injection). The full seven-
% object stack is built here; TSDiagram mutates the shared geom/prop/wts objects
% in place during converge_W0 (see its header) and they are used for nothing
% else afterward. The weights object is the A481 A02 delta model -- three-arg
% constructor (injects geom for S_ref, prop for T_SL).
aero = Aero481AeroL1(sp);
prop = Aero481PropL1(sp);
geom = Aero481GeomL1(sp, rp);
tail = Aero481TailL1();
wts  = Aero481WeightsL1(sp, geom, prop);   % A481 A02 delta model -- injects geom (S_ref) + prop (T_SL)
miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "dca");

% The constraint set is still built (the diagram/optimum are reported for
% context), but it does NOT drive the sizing -- the fixed (T, S) cell does.
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

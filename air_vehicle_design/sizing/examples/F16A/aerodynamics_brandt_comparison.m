function T_all = aerodynamics_brandt_comparison()
%AERODYNAMICS_BRANDT_COMPARISON  F-16A Block 10 -- Aerodynamics vs multi-source ground truth.
%
%   NOT A TEST. No pass/fail assertions, NOT part of run_all_tests. A pure
%   reporting script: it loads the aero JSON inputs, runs the actual
%   F16AeroL1/L2/L3 code across a Mach sweep, and compares the results against
%   the `aerodynamics` section of
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json (Brandt-workbook +
%   T.O.-1F-16A-1 "AF Manual" + published-internet values, each cited in the
%   JSON). Percentage differences are informational; a large %Diff is often
%   EXPECTED (flagged "not a bug" in Notes), not a defect.
%
%   INPUTS (the actual toolbox inputs the code reads):
%     examples/F16A/f16a_L1.json  (.aerodynamics: type + folded Mattingly curves)
%     examples/F16A/f16a_L2.json  (.aerodynamics: Cfe/airfoil/e-method; .geometry: injected F16GeomL2)
%     examples/F16A/f16a_L3.json  (.aerodynamics: component-buildup constants)
%
%   GROUND TRUTH (compared AGAINST, never re-derived here -- read from JSON):
%     VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json  [.aerodynamics]
%       Brandt   = Brandt-F16-A.xls workbook outputs / his tabulated actual polar
%       AF Manual = T.O. 1F-16A-1 (airfoil + limits only; NO polar/CLmax/CD0)
%       Internet = published estimates (F-16C conceptual polar, textbook, NASA)
%
%   REFERENCE SOURCES:
%     [Raymer]  D.P. Raymer, Aircraft Design 6th ed., AIAA (Ch. 12).
%     [Mattingly] Mattingly et al., Aircraft Engine Design 2nd ed., AIAA, 2002.
%     [Brandt]  S. Brandt, F-16A.xls workbook + Introduction to Aeronautics.
%     [Roskam]  J. Roskam, Airplane Design Vol. I (CLmax / HLD delta tables).
%
%   The 0.95 <= M <= 1.05 transonic band is deliberately SKIPPED (L2/L3
%   drag_polar returns NaN there -- Raymer Eq. 12.51 pole near M=1). The sweep
%   uses subsonic M = 0.6/0.8/0.9 and supersonic M = 1.2/1.5/2.0.
%
%   Outputs (written next to this script):
%     aerodynamics_brandt_comparison.json  -- full table + metadata
%     aerodynamics_brandt_comparison.md    -- rendered markdown table (headline)

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
gt          = jsondecode(fileread(gt_path)).aerodynamics;

% Flight condition for the polar sweep (L3's component CD0 is Reynolds- and
% therefore altitude-sensitive; CLmax/e are not). 36,000 ft is a
% representative cruise/combat altitude.
ALT   = 36000;   % ft
M_SUB = 0.6;     % subsonic representative point (< 0.95)
M_SUP = 1.6;     % supersonic representative point (matches Brandt actual-polar M=1.6 row)
M_SWEEP = [0.6 0.8 0.9 1.2 1.5 2.0];   % full sweep, avoiding the transonic band

% Brandt's tabulated ACTUAL (reference) polar rows, indexed by Mach.
ap        = gt.brandt_actual_polar_vs_mach.rows;   % struct array: mach/CDmin/CDo/k1/k2
ap_mach   = [ap.mach];
brandt_CDo = @(M) ap(nearestIdx(ap_mach, M)).CDo;   % nearest tabulated CDo
brandt_k1a = @(M) ap(nearestIdx(ap_mach, M)).k1;    % nearest tabulated k1

% L1 is geometry-free (Mattingly type-curve) -> takes no geometry object.
% L2 and L3 now inject their OWN geometry tier (Phase 2, 2026-07-25): L3 was
% previously handed an F16GeomL2, which made f16a_L3.json's entire .geometry
% block dead input. Geometry also takes the propulsion object, because the
% nacelle diameter -- and so duct wetted area and CD0 -- is sized from thrust.
% L3 geometry is INTENTIONALLY divergent from L2 (physical/T.O. values: VT LE
% sweep 47.5 vs 40, L_fus 47.5 vs 46.5, HT span 18.5 primary), so L2-vs-L3
% differences below are expected, not errors -- see examples/F16A/F16GeomL3.md.
a1   = F16AeroL1(f16a_spec_path(1));
prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);
g3   = F16GeomL3(f16a_spec_path(3), prop);
a2 = F16AeroL2(g2, f16a_spec_path(2));
a3 = F16AeroL3(g3, f16a_spec_path(3));

st_sub = AircraftState(ALT, M_SUB);
st_sup = AircraftState(ALT, M_SUP);

p1s = a1.drag_polar(st_sub);  p2s = a2.drag_polar(st_sub);  p3s = a3.drag_polar(st_sub);
p1u = a1.drag_polar(st_sup);  p2u = a2.drag_polar(st_sup);  p3u = a3.drag_polar(st_sup);

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %
T = table();

af_air = gt.af_manual.airfoil.value;
af_ML  = gt.af_manual.Mach_limit.value;

T = [T; srow('[AF MANUAL CONTEXT -- T.O. 1F-16A-1 has NO drag polar / CLmax / CD0 coefficients]')];
T = [T; arow('Wing airfoil', 'spec', NaN, NaN, af_air, NaN, '%s', 'T.O. 1F-16A-1 Fig. 1-2', ...
        'AF-manual ground truth is limited to airfoil + operating limits; coefficients are in the (absent) T.O. 1F-16A-1-1.')];
T = [T; arow('Mach limit', 'spec', NaN, NaN, sprintf('%.2f', af_ML), NaN, '%.2f', 'T.O. 1F-16A-1 limits', ...
        'Structural/operational limit, not an aero coefficient.')];

% ── Subsonic clean polar (M=0.6, 36 kft) ────────────────────────────────── %
T = [T; srow(sprintf('[SUBSONIC CLEAN DRAG POLAR -- M=%.1f, %d kft]', M_SUB, ALT/1000))];
T = [T; arow('CD0 subsonic (L1 Mattingly type-curve)', 'L1', p1s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'L1 CD0(M) from Mattingly Fig.2.10 (placeholder). Brandt skin-friction basis 0.01691; his MISSION CD0=0.0270 folds in form/interference/wave (a different basis).')];
T = [T; arow('CD0 subsonic (L2 Cfe*Swet/Sref)', 'L2', p2s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'Raymer Eq.12.23 with Cfe=0.0035 (AF fighter). Closest to Brandt skin-friction 0.01691; below his mission 0.0270 (no form/wave drag at L2) -- not a bug.')];
T = [T; arow('CD0 subsonic (L3 component buildup)', 'L3', p3s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'Raymer Eq.12.24 per-component sum. Same skin-friction basis as Brandt Aero!G3; below mission 0.0270 (no excrescence calibration) -- not a bug.')];
T = [T; arow('K1 subsonic (L1)', 'L1', p1s.K1, gt.k1.brandt.value, 'N/A', gt.k1.internet.value, '%.4f', 'Brandt Miss!k1', ...
        'L1 K1(M) from Mattingly Fig.2.11 (placeholder, ~0.18); higher than the geometry-based L2/L3 K1.')];
T = [T; arow('K1 subsonic (L2/L3, 1/(pi*AR*e))', 'L2', p2s.K1, gt.k1.brandt.value, 'N/A', gt.k1.internet.value, '%.4f', 'Brandt Miss!k1', ...
        'Raymer Eq.12.50 with official Oswald e (Eq.12.49). L2 and L3 share this K1; excellent agreement with Brandt 0.1160.')];
T = [T; arow('K2 subsonic (L1, uncambered)', 'L1', p1s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'L1 treats the fighter as uncambered -> K2=0 (Mattingly Sec.2.3.1). Brandt uses a small negative camber term -0.0063.')];
T = [T; arow('K2 subsonic (L2, -2*K1*CL_minD)', 'L2', p2s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'Raymer Eq.12.6 CL_alpha + Brandt Sec.4.3. Cambered 64A204 (alpha_L0=-1.01) -> negative K2, close to Brandt.')];
T = [T; arow('K2 subsonic (L3, -2*K1*CL_minD)', 'L3', p3s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'Same form as L2; L3 CL_alpha omits the 2-D-slope eta term (default 0.95), giving a slightly larger magnitude.')];

% ── Supersonic clean polar (M=1.6, 36 kft) ──────────────────────────────── %
T = [T; srow(sprintf('[SUPERSONIC CLEAN DRAG POLAR -- M=%.1f, %d kft]', M_SUP, ALT/1000))];
T = [T; arow('CD0 supersonic (L1)', 'L1', p1u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'L1 Mattingly supersonic CD0 plateau (~0.028, placeholder). Internet band ~0.0425 is at M~1.05.')];
T = [T; arow('CD0 supersonic (L2, skin friction only)', 'L2', p2u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'EXPECTED LOW, NOT A BUG: L2 supersonic CD0 is Cf(Re,M)*Swet/Sref with NO wave drag (that is added only at L3). Grossly under Brandt 0.0461.')];
T = [T; arow('CD0 supersonic (L3, buildup + wave drag)', 'L3', p3u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'L3 adds the Raymer Eq.12.41 fuselage wave-drag term (M>=1.2); much closer to Brandt 0.0461. Residual gap = no wing/canopy/boat-tail wave drag -- not a bug.')];
T = [T; arow('K1 supersonic (L1)', 'L1', p1u.K1, brandt_k1a(M_SUP), 'N/A', NaN, '%.4f', 'Brandt Aero!P9 (actual polar, M=1.6)', ...
        'L1 Mattingly Fig.2.11 supersonic K1 (~0.29, placeholder).')];
T = [T; arow('K1 supersonic (L2/L3, Eq.12.51)', 'L2', p2u.K1, brandt_k1a(M_SUP), 'N/A', NaN, '%.4f', 'Brandt Aero!P9 (actual polar, M=1.6)', ...
        'Raymer Eq.12.51 linearized supersonic K1 (shared L2/L3). Under Brandt 0.340 -- linear theory under-predicts real supersonic induced drag; expected.')];

% ── CD0 Mach-sweep for L2 and L3 (drag rise) ────────────────────────────── %
T = [T; srow(sprintf('[CD0 vs MACH SWEEP -- L2 & L3, %d kft (subsonic 0.6/0.8/0.9, supersonic 1.2/1.5/2.0)]', ALT/1000))];
for M = M_SWEEP
    stM = AircraftState(ALT, M);
    cd2 = a2.drag_polar(stM).CD0;
    cd3 = a3.drag_polar(stM).CD0;
    br  = brandt_CDo(M);
    if M < 1
        note2 = 'L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo.';
        note3 = 'L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo.';
    else
        note2 = 'L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo.';
        note3 = 'L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo.';
    end
    T = [T; arow(sprintf('CD0 @ M=%.1f (L2)', M), 'L2', cd2, br, 'N/A', NaN, '%.5f', sprintf('Brandt actual polar (M~%.3g)', ap_mach(nearestIdx(ap_mach, M))), note2)]; %#ok<AGROW>
    T = [T; arow(sprintf('CD0 @ M=%.1f (L3)', M), 'L3', cd3, br, 'N/A', NaN, '%.5f', sprintf('Brandt actual polar (M~%.3g)', ap_mach(nearestIdx(ap_mach, M))), note3)]; %#ok<AGROW>
end

% ── Oswald span efficiency ──────────────────────────────────────────────── %
T = [T; srow('[OSWALD SPAN EFFICIENCY -- two implementation options]')];
T = [T; arow('e, official Raymer Eq.12.48/12.49 (L2)', 'L2', a2.get_e_osw(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'OFFICIAL drag_polar value (Eq.12.49, Lambda_LE=40). ~0.6% under Brandt e0 (Brandt uses a different formula).')];
T = [T; arow('e, official Raymer Eq.12.48/12.49 (L3)', 'L3', a3.get_e_osw(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'Same official formula as L2.')];
T = [T; arow('e, Brandt Aero!G12 alternate (L2)', 'L2', a2.get_e_osw_brandt(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'POSITIVE CONTROL: this is Brandt''s own formula fed Brandt''s inputs, so it reproduces e0=0.9144 near-exactly. Comparison-report ONLY -- never what drag_polar returns.')];
T = [T; arow('e, Brandt Aero!G12 alternate (L3)', 'L3', a3.get_e_osw_brandt(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'Same Brandt alternate as L2 (positive control).')];

% ── CLmax (clean / takeoff / landing) ───────────────────────────────────── %
T = [T; srow('[MAXIMUM LIFT COEFFICIENT -- clean / takeoff / landing]')];
T = [T; arow('CLmax clean (L1 Roskam lookup)', 'L1', a1.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        'Roskam Vol.I Table 3.3 fighter clean = 0.90. Both L1 and Brandt (0.984) badly under the ~1.6 whole-aircraft value: NO LEX/strake vortex lift modeled -- not a bug.')];
T = [T; arow('CLmax clean (L2 Eq.12.15)', 'L2', a2.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        '0.9*cl_max_2D*cos(Lambda_c/4). Near Brandt 0.984; far below internet ~1.6 (no vortex lift) -- expected underprediction, not a bug.')];
T = [T; arow('CLmax clean (L3 Eq.12.15)', 'L3', a3.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        'Same Eq.12.15 basis as L2; same LEX vortex-lift limitation.')];
T = [T; arow('CLmax takeoff (L1)', 'L1', a1.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'L1 clean + Roskam Table 3.1 fighter TO-delta (category mean).')];
T = [T; arow('CLmax takeoff (L2 flap)', 'L2', a2.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'Clean + TE-flap delta (Eq.12.21). Internet 1.35 is a rough band center (F-16 has no conventional TE flaps).')];
T = [T; arow('CLmax takeoff (L3 flap+slat)', 'L3', a3.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'Clean + TE-flap + LE-slat deltas; closest of the three levels to Brandt 1.276.')];
T = [T; arow('CLmax landing (L1)', 'L1', a1.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'L1 clean + Roskam Table 3.1 fighter landing-delta -- generic large-flap category mean overshoots the F-16.')];
T = [T; arow('CLmax landing (L2 flap)', 'L2', a2.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'Clean + TE-flap delta only (no slat at L2).')];
T = [T; arow('CLmax landing (L3 flap+slat)', 'L3', a3.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'Clean + TE-flap + LE-slat deltas; closest to Brandt 1.426.')];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %
now_str = char(datetime('now', 'Format', 'yyyy-MM-dd'));
BAR     = repmat('=', 1, 120);

fprintf('\n%s\n', BAR);
fprintf('  F-16A BLOCK 10 -- AERODYNAMICS vs GROUND TRUTH (Brandt / AF-Manual / Internet)\n');
fprintf('  Flight condition: %d ft, subsonic M=%.1f / supersonic M=%.1f  |  Generated %s\n', ALT, M_SUB, M_SUP, now_str);
fprintf('  Source: VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.aerodynamics]\n');
fprintf('  NOT A TEST -- informational only. Large %%Diff is often expected (see Notes).\n');
fprintf('%s\n\n', BAR);

disp(T);

fprintf('  KEY NOTES\n');
fprintf('  - L2 supersonic CD0 is skin-friction only (no wave drag) -> far below Brandt; wave drag enters at L3 (Eq.12.41). Not a bug.\n');
fprintf('  - CLmax (clean) under-predicts the ~1.6 whole-aircraft value at every level: LEX/strake vortex lift is not modeled. Not a bug.\n');
fprintf('  - The official Oswald e (Raymer Eq.12.48/12.49) differs from Brandt e0 (Aero!G12) by formula; the Brandt-alternate rows are a positive control.\n');
fprintf('  - Brandt CD0 columns use his skin-friction CDmin (Aero!G3, subsonic) or his tabulated ACTUAL polar (supersonic), not his mission CD0=0.0270.\n');
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %
out_json = fullfile(script_dir, 'aerodynamics_brandt_comparison.json');
out_md   = fullfile(script_dir, 'aerodynamics_brandt_comparison.md');

data.generated   = now_str;
data.aircraft    = 'F-16A Block 10';
data.altitude_ft = ALT;
data.M_subsonic  = M_SUB;
data.M_supersonic = M_SUP;
data.source      = 'VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.aerodynamics]';
data.rows        = table_to_rows(T);

fid = fopen(out_json, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON     -> %s\n', out_json);

write_markdown(T, out_md, ALT, M_SUB, M_SUP, now_str);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;
end

% ─── local helpers ───────────────────────────────────────────────────── %

function idx = nearestIdx(vec, x)
%NEARESTIDX  Index of the element of vec closest to x.
    [~, idx] = min(abs(vec - x));
end

function T = arow(name, fidelity, computed, brandt, afman, internet, numfmt, src, notes)
%AROW  One comparison row: Fidelity | Computed | Brandt | %Diff | AF Manual | Internet | Source | Notes.
    if nargin < 9; notes = ''; end
    comp_s = fmtNum(computed, numfmt);
    brt_s  = fmtNum(brandt,   numfmt);
    int_s  = fmtNum(internet, numfmt);
    if ischar(afman) || isstring(afman)
        af_s = char(afman);
    else
        af_s = fmtNum(afman, numfmt);
    end
    if ~isnan(computed) && ~isnan(brandt) && brandt ~= 0
        err_s = sprintf('%+.2f%%', 100*(computed - brandt)/brandt);
    else
        err_s = ' - ';
    end
    T = table({fidelity}, {comp_s}, {brt_s}, {err_s}, {af_s}, {int_s}, {src}, {notes}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'AFManual', 'Internet', 'Source', 'Notes'}, ...
        'RowNames', {name});
end

function s = fmtNum(v, numfmt)
%FMTNUM  Format a numeric value, or 'N/A' when NaN. String numfmt (%s) passes text.
    if strcmp(numfmt, '%s')
        s = 'N/A';
    elseif isnan(v)
        s = 'N/A';
    else
        s = sprintf(numfmt, v);
    end
end

function T = srow(label)
%SROW  Section separator row.
    T = table({'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'AFManual', 'Internet', 'Source', 'Notes'}, ...
        'RowNames', {label});
end

function rows = table_to_rows(T)
%TABLE_TO_ROWS  Convert the comparison table to a struct array for jsonencode.
    n = height(T);
    for r = n:-1:1
        rows(r).parameter = T.Properties.RowNames{r};
        rows(r).Fidelity  = T.Fidelity{r};
        rows(r).Computed  = T.Computed{r};
        rows(r).Brandt    = T.Brandt{r};
        rows(r).PctDiff   = T.PctDiff{r};
        rows(r).AFManual  = T.AFManual{r};
        rows(r).Internet  = T.Internet{r};
        rows(r).Source    = T.Source{r};
        rows(r).Notes     = T.Notes{r};
    end
end

function write_markdown(T, out_path, ALT, M_SUB, M_SUP, now_str)
%WRITE_MARKDOWN  Render the comparison table as a markdown file.
    fid = fopen(out_path, 'w');
    fprintf(fid, '# F-16A Block 10 — Aerodynamics vs Ground Truth (Brandt / AF-Manual / Internet)\n\n');
    fprintf(fid, 'Generated %s. Flight condition: %d ft, subsonic M=%.1f / supersonic M=%.1f.\n\n', now_str, ALT, M_SUB, M_SUP);
    fprintf(fid, ['Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.aerodynamics`]. ' ...
        'Brandt = workbook outputs / his tabulated actual polar; AF Manual = T.O. 1F-16A-1 (airfoil + limits only); ' ...
        'Internet = published estimates.\n\n']);
    fprintf(fid, ['This is a **comparison report**, not a test — no pass/fail assertions, not in `run_all_tests`. ' ...
        'A large %%Diff is frequently **expected** (see Notes), not a defect. The 0.95 ≤ M ≤ 1.05 transonic band is ' ...
        'skipped (L2/L3 return NaN there).\n\n']);
    fprintf(fid, '| Parameter | Fidelity | Computed | Brandt | %%Diff | AF Manual | Internet (F-16) | Source | Notes |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|---|---|\n');
    n = height(T);
    for r = 1:n
        name = T.Properties.RowNames{r};
        if strcmp(T.Computed{r}, '---')
            fprintf(fid, '| **%s** | | | | | | | | |\n', strrep(name, '|', '\|'));
        else
            fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n', ...
                strrep(name, '|', '\|'), T.Fidelity{r}, T.Computed{r}, T.Brandt{r}, T.PctDiff{r}, ...
                T.AFManual{r}, T.Internet{r}, strrep(T.Source{r}, '|', '\|'), strrep(T.Notes{r}, '|', '\|'));
        end
    end
    fclose(fid);
end

function T_all = propulsion_brandt_comparison()
%PROPULSION_BRANDT_COMPARISON  F-16A Block 10 -- Propulsion vs Brandt ground truth.
%
%   NOT A TEST -- informational comparison only. No pass/fail assertions, NOT
%   part of run_all_tests. A pure reporting script: it builds the six Brandt
%   constraint-analysis flight conditions with AircraftState, runs the actual
%   F16PropL1/F16PropL2 code, and compares the results against the
%
%   NO L3 PROPULSION TIER EXISTS (and none is planned, user decision
%   2026-07-25). Geometry, aerodynamics and weights are L1/L2/L3; propulsion is
%   L1/L2 only. The framework's L3 rung pairs F16AeroL3 with F16PropL2, so any
%   "L3" propulsion figure elsewhere in the project is computed by F16PropL2 and
%   equals the L2 rows in this report.
%
%   `propulsion` section of
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json (Brandt-workbook OUTPUTS,
%   each cited in the JSON to a Consts/Engn(s) cell). Percentage differences
%   are informational; a large %Diff is frequently EXPECTED (the framework's
%   Mattingly engine model and Brandt's Engn(s) model are DIFFERENT models,
%   flagged "not a bug" in Notes), never a unit-test failure.
%
%   WHY THIS IS A REPORT, NOT A UNIT TEST: every row here compares two
%   different engine MODELS (Mattingly Eq. 2.54/3.55 vs Brandt's Engn(s)
%   lapse/TSFC formulas). Those cross-model deltas were previously (wrongly)
%   asserted in TestPropL2 with a blanket 30% tolerance; they were moved here
%   in Step 1c. Unit tests (TestPropL1/TestPropL2) now check only independent
%   hand-computed / published-datum expecteds and never read this JSON.
%
%   INPUTS (actual toolbox inputs the code reads):
%     examples/F16A/f16a_L1.json  (.propulsion: engine_type, T_SL, T_SL_wet)
%     examples/F16A/f16a_L2.json  (.propulsion: + T_SL_mil, T_t4_max_F, install factor)
%
%   GROUND TRUTH (compared AGAINST, never re-derived here -- read from JSON):
%     VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.propulsion]
%       thrust_lapse_at_constraint_conditions.rows: alpha_dry(AS)/alpha_AB(AT)/
%         alpha_eff_on_TAB(AU) at the six Consts rows 23-28 (live-xls verified,
%         todo.md 2026-07-24 entry A).
%       TSFC_mil_installed_per_hr = 0.70, TSFC_AB_installed_per_hr = 2.20
%         (INSTALLED -- already include the 1.08 factor; do NOT double-apply,
%         todo.md entry 4). TR = 1.0. Nacelle D=3.537 ft / L=15.917 ft.
%
%   SEMANTICS (Brandt Consts sheet, live-xls verified):
%     AS = alpha_dry  (delta_0 basis, normalized to T_SL_dry = 15,000 lbf)
%     AT = alpha_AB   (delta_0 basis, normalized to T_SL_AB  = 23,770 lbf)
%     AU = alpha_eff_on_TAB (effective lapse on the T_SL_AB axis); for a
%          100%-AB row AU = AT, for the 0%-AB cruise row AU = AS*(T_dry/T_AB).
%     Framework Mattingly alpha_AB (F16PropL2.compute_thrust_lapse_AB) compares
%     against AT; a dry/mil point (cruise) compares against AU.
%
%   OTHER-SOURCE column: Mattingly (uninstalled) TSFC coefficients, Raymer
%   Table 3.3 categorical L1 TSFC, and T.O. 1F-16A-1 nacelle length, where
%   available.
%
%   Outputs (written next to this script):
%     propulsion_brandt_comparison.json  -- full table + metadata
%     propulsion_brandt_comparison.md    -- rendered markdown table
%
%   REFERENCE SOURCES:
%     [Brandt]    S. Brandt, F-16A.xls workbook (Consts/Engn(s)/Main/Miss tabs).
%     [Mattingly] Mattingly et al., Aircraft Engine Design 2nd ed., AIAA, 2002
%                 (Eq. 2.54 lapse, Eq. 3.55 TSFC, Eq. D.6 TR, Table C.4).
%     [Raymer]    D.P. Raymer, Aircraft Design (Table 3.3; Eqs. 10.11/10.13/10.15).
%     [TO]        T.O. 1F-16A-1, Sec. I.

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
gt          = jsondecode(fileread(gt_path)).propulsion;

INSTALL = 1.08;   % Brandt Miss!C25 install factor (for labeling only)

% Brandt installed SLS TSFC references (already include the 1.08 factor).
brandt_TSFC_mil = gt.TSFC_mil_installed_per_hr.value;   % 0.70
brandt_TSFC_AB  = gt.TSFC_AB_installed_per_hr.value;    % 2.20
brandt_TR       = gt.TR.value;                          % 1.0

% Six constraint-condition rows (Consts 23-28), struct array.
cc = gt.thrust_lapse_at_constraint_conditions.rows;

% Framework discipline objects (required-JSON-path constructors).
p1 = F16PropL1(f16a_spec_path(1));
p2 = F16PropL2(f16a_spec_path(2));

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %
T = table();

% ── There is NO L3 propulsion tier ──────────────────────────────────────── %
% Stated up front because every OTHER discipline now has three tiers, so a
% reader is entitled to wonder where the L3 propulsion rows went.
%
% No PropL3 / PropulsionModelL3 / F16PropL3 exists, and none is planned (user
% decision 2026-07-25). The L3 rung of the framework pairs F16AeroL3 with
% F16PropL2 -- see F16ConstraintSet.buildDisciplines. So every propulsion
% number quoted anywhere for "L3" is COMPUTED BY F16PropL2 and is identical to
% the L2 rows below; duplicating them under an "L3" label would imply a
% higher-fidelity model that does not exist. Geometry and aerodynamics DO
% diverge between L2 and L3; propulsion does not.
T = [T; srow('[NOTE: NO L3 PROPULSION TIER -- the L3 rung uses F16PropL2, so every L2 row below IS the L3 result]')];

% ── Thrust lapse alpha_AB: L2 Mattingly vs Brandt AT ─────────────────────── %
T = [T; srow('[THRUST LAPSE alpha_AB -- L2 Mattingly Eq.2.54a vs Brandt alpha_AB (Consts AT)]')];
for k = 1:numel(cc)
    c     = cc(k);
    st    = AircraftState(c.alt_ft, c.mach);
    a_fw  = p2.compute_thrust_lapse_AB(st);
    other = sprintf('AU(eff on T_AB)=%.4f; AS(dry)=%.4f', c.alpha_eff_on_TAB, c.alpha_dry);
    note  = matt_vs_brandt_note(st.theta_0);
    T = [T; prow(sprintf('alpha_AB @ %s (%dft M%.2f, %d%%AB)', c.condition, c.alt_ft, c.mach, c.pct_AB), ...
        'L2', a_fw, c.alpha_AB, other, sprintf('Brandt Consts AT%d', c.consts_row), '%.4f', note)]; %#ok<AGROW>
end

% ── Thrust lapse: L1 density-only sigma^m vs Brandt AT ───────────────────── %
T = [T; srow('[THRUST LAPSE alpha -- L1 density-only sigma^m vs Brandt alpha_AB (Consts AT)]')];
for k = 1:numel(cc)
    c    = cc(k);
    st   = AircraftState(c.alt_ft, c.mach);
    a_l1 = p1.get_thrust_lapse(st);
    note = ['L1 alpha=sigma^0.6 has NO Mach term and no AB/mil split, so it is compared against ' ...
            'alpha_AB (AT). Degrades badly at extreme altitude (max_alt) and supersonic Mach -- not a bug, an L1 limitation.'];
    T = [T; prow(sprintf('alpha_L1 @ %s (%dft M%.2f)', c.condition, c.alt_ft, c.mach), ...
        'L1', a_l1, c.alpha_AB, sprintf('AT=%.4f', c.alpha_AB), sprintf('Brandt Consts AT%d', c.consts_row), '%.4f', note)]; %#ok<AGROW>
end

% ── Dry/mil-on-AB-scale at the cruise (0% AB) point vs Brandt AU ─────────── %
T = [T; srow('[THRUST LAPSE dry/mil basis -- L2 mil-on-AB-scale vs Brandt alpha_eff_on_TAB (Consts AU)]')];
idx_cruise = find(strcmp({cc.condition}, 'cruise'), 1);
if ~isempty(idx_cruise)
    c     = cc(idx_cruise);
    st    = AircraftState(c.alt_ft, c.mach);
    a_mil = p2.thrust_lapse_mil_on_AB_scale(st);
    note  = ['Cruise is flown 0% AB (dry). Framework alpha_mil = 0.6*delta_0 renormalized to the AB axis ' ...
             '(x T_SL_mil/T_SL_wet). Brandt AU = AS*(T_dry/T_AB). Mattingly has no below-TR Mach term; expected high.'];
    T = [T; prow(sprintf('alpha_mil-on-AB @ cruise (%dft M%.2f)', c.alt_ft, c.mach), ...
        'L2', a_mil, c.alpha_eff_on_TAB, sprintf('AS(dry)=%.4f', c.alpha_dry), ...
        sprintf('Brandt Consts AU%d', c.consts_row), '%.4f', note)];
end

% ── TSFC: framework Mattingly (uninstalled & installed) vs Brandt installed ─ %
T = [T; srow('[TSFC -- L2 Mattingly Eq.3.55 (uninstalled & installed x1.08) vs Brandt installed]')];
st_sls_mil = AircraftState(0, 0.001);   % SLS static, M~0 (mil basis)
st_sls_ab  = AircraftState(0, 0.4);     % SLS, M=0.4 (Brandt AB reference basis)

tsfc_mil_un  = p2.compute_TSFC_mil(st_sls_mil);
tsfc_mil_in  = p2.compute_TSFC_installed(st_sls_mil);
tsfc_ab_un   = p2.compute_TSFC_AB(st_sls_ab);
tsfc_ab_in   = p2.compute_TSFC_AB_installed(st_sls_ab);

T = [T; prow('TSFC mil SLS(M~0), UNINSTALLED (L2)', 'L2', tsfc_mil_un, brandt_TSFC_mil, ...
    'Mattingly Eq.3.55a C1_mil=0.90', 'Brandt Engn!TSFC_mil (installed)', '%.4f', ...
    'Brandt 0.70 is INSTALLED (incl. 1.08); compare the installed row below, not this uninstalled one.')];
T = [T; prow('TSFC mil SLS(M~0), INSTALLED x1.08 (L2)', 'L2', tsfc_mil_in, brandt_TSFC_mil, ...
    sprintf('uninst 0.90 x %.2f', INSTALL), 'Brandt Engn!TSFC_mil (installed)', '%.4f', ...
    'Mattingly over-predicts SLS static mil TSFC vs Brandt 0.70 (known systematic bias); trend vs alt/Mach is correct.')];
T = [T; prow('TSFC AB SLS(M=0.4), UNINSTALLED (L2)', 'L2', tsfc_ab_un, brandt_TSFC_AB, ...
    'Mattingly Eq.3.55b (1.60+0.27M)', 'Brandt Engn!TSFC_AB (installed, M=0.4)', '%.4f', ...
    'Brandt 2.20 is INSTALLED at the M=0.4 reference; compare the installed row below.')];
T = [T; prow('TSFC AB SLS(M=0.4), INSTALLED x1.08 (L2)', 'L2', tsfc_ab_in, brandt_TSFC_AB, ...
    sprintf('uninst %.4f x %.2f', tsfc_ab_un, INSTALL), 'Brandt Engn!TSFC_AB (installed, M=0.4)', '%.4f', ...
    'Mattingly under-predicts the AB reference vs Brandt 2.20; different AB model calibration -- not a bug.')];

% L1 categorical TSFC (Raymer Table 3.3) at cruise, vs Brandt mil installed (different basis).
if ~isempty(idx_cruise)
    c = cc(idx_cruise);
    tsfc_l1 = p1.get_TSFC(AircraftState(c.alt_ft, c.mach));
    T = [T; prow('TSFC cruise (L1 Raymer Table 3.3)', 'L1', tsfc_l1, brandt_TSFC_mil, ...
        'Raymer Table 3.3 cruise=0.80', 'Brandt Engn!TSFC_mil (installed SLS)', '%.4f', ...
        'DIFFERENT basis: L1 categorical cruise SFC (0.80, M>=0.4) vs Brandt SLS-static installed mil (0.70) -- not directly comparable.')];
end

% ── Engine constants (positive controls -- same spec datum both sides) ───── %
T = [T; srow('[ENGINE CONSTANTS -- positive controls]')];
T = [T; prow('T_SL_wet (AB SLS thrust) [lbf]', 'L2', p2.T_SL_wet, gt.T_SL_wet_lb.value, ...
    'T.O. 1F-16A-1 Sec.I', 'Brandt Main!D29', '%.1f', 'Spec input echoed both sides -- should match exactly.')];
T = [T; prow('T_SL_mil (dry SLS thrust) [lbf]', 'L2', p2.T_SL_mil, gt.T_SL_mil_lb.value, ...
    'T.O. 1F-16A-1 Sec.I', 'Brandt Main!C29', '%.1f', 'Spec input echoed both sides -- should match exactly.')];
T = [T; prow('TR (throttle ratio)', 'L2', p2.TR, brandt_TR, ...
    'Mattingly Eq.D.6 (T_t4_SLS unknown->1.0)', 'Brandt Engn(s)!S1', '%.4f', 'Should match exactly (both 1.0).')];

% ── Nacelle sizing (Brandt Engn(s) formula, positive control) ───────────── %
D_nac = sqrt(p2.T_SL_wet / 1900);   % Brandt Engn(s) D = sqrt(T_AB_SLS/1900)
L_nac = 4.5 * D_nac;                % Brandt Engn(s) L = 4.5*D
T = [T; srow('[NACELLE SIZING -- Brandt Engn(s) formula reproduced as positive control]')];
T = [T; prow('Nacelle diameter D=sqrt(T_AB/1900) [ft]', 'L2', D_nac, gt.nacelle.diameter_ft.value, ...
    'Raymer Eq.10.12 ~3.8 (unwired)', 'Brandt Engn(s) D_nac', '%.4f', 'Same formula/inputs as Brandt -- near-exact match expected.')];
T = [T; prow('Nacelle length L=4.5*D [ft]', 'L2', L_nac, gt.nacelle.length_ft.value, ...
    'T.O. 1F-16A-1 total length 15.93', 'Brandt Engn(s) L_nac', '%.4f', 'Same formula/inputs as Brandt; T.O. total engine length 15.93 ft is an independent anchor.')];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %
now_str = char(datetime('now', 'Format', 'yyyy-MM-dd'));
BAR     = repmat('=', 1, 120);

fprintf('\n%s\n', BAR);
fprintf('  F-16A BLOCK 10 -- PROPULSION vs BRANDT GROUND TRUTH\n');
fprintf('  Generated %s  |  Source: VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.propulsion]\n', now_str);
fprintf('  NOT A TEST -- informational only. Mattingly (framework) vs Brandt Engn(s) are DIFFERENT models; large %%Diff is often expected.\n');
fprintf('%s\n\n', BAR);

disp(T);

fprintf('  KEY NOTES\n');
fprintf('  - alpha_AB: framework Mattingly Eq.2.54 vs Brandt Consts AT. Best agreement above-TR (supersonic dash / Ps);\n');
fprintf('    worst below-TR at cruise/max_alt (Mattingly has no below-TR Mach correction, Brandt does). Not a bug.\n');
fprintf('  - L1 sigma^m has no Mach term at all -- compared against AT for reference; diverges at extreme alt / supersonic.\n');
fprintf('  - TSFC: Brandt 0.70 (mil) / 2.20 (AB) are INSTALLED (already x1.08). Compare the framework INSTALLED rows;\n');
fprintf('    do NOT double-apply 1.08 (todo.md 2026-07-24 entry 4). Mattingly over-predicts mil SLS, under-predicts AB ref.\n');
fprintf('  - Engine constants / nacelle rows are positive controls (same spec/formula both sides) -> should match near-exactly.\n');
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %
out_json = fullfile(script_dir, 'propulsion_brandt_comparison.json');
out_md   = fullfile(script_dir, 'propulsion_brandt_comparison.md');

data.generated = now_str;
data.aircraft  = 'F-16A Block 10';
data.source    = 'VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.propulsion]';
data.rows      = table_to_rows(T);

fid = fopen(out_json, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON     -> %s\n', out_json);

write_markdown(T, out_md, now_str);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;
end

% ─── local helpers ───────────────────────────────────────────────────── %

function note = matt_vs_brandt_note(theta_0)
%MATT_VS_BRANDT_NOTE  Per-condition note on the Mattingly-vs-Brandt alpha_AB gap.
%   Branch selection is on theta_0 vs TR=1.0 (depends on BOTH altitude and
%   Mach), not Mach alone -- e.g. Ps (10kft M0.87) has theta_0~1.07 > TR.
    if theta_0 <= 1.0
        note = ['Below-TR (theta_0<=TR=1.0): Mattingly alpha_AB=delta_0 with NO Mach term; Brandt subtracts ' ...
                '0.1*sqrt(M). Framework reads HIGH vs Brandt AT -- expected, not a bug.'];
    else
        note = ['Above-TR (theta_0>TR=1.0): both models carry a theta correction; Mattingly (3.5 coeff) and ' ...
                'Brandt (2.2 coeff + 0.1*sqrt(M)) agree within a few percent -- the closest conditions.'];
    end
end

function T = prow(name, fidelity, computed, brandt, other, src, numfmt, notes)
%PROW  One comparison row: Fidelity | Computed | Brandt | %Diff | OtherSource | Source | Notes.
%   other is a preformatted text field (secondary Brandt column, Mattingly/
%   Raymer/T.O. reference, etc.).
    if nargin < 8; notes = ''; end
    comp_s = fmtNum(computed, numfmt);
    brt_s  = fmtNum(brandt,   numfmt);
    if ~isnan(computed) && ~isnan(brandt) && brandt ~= 0
        err_s = sprintf('%+.2f%%', 100*(computed - brandt)/brandt);
    else
        err_s = ' - ';
    end
    T = table({fidelity}, {comp_s}, {brt_s}, {err_s}, {char(other)}, {src}, {notes}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'OtherSource', 'Source', 'Notes'}, ...
        'RowNames', {name});
end

function s = fmtNum(v, numfmt)
%FMTNUM  Format a numeric value, or 'N/A' when NaN.
    if isnan(v)
        s = 'N/A';
    else
        s = sprintf(numfmt, v);
    end
end

function T = srow(label)
%SROW  Section separator row.
    T = table({'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'OtherSource', 'Source', 'Notes'}, ...
        'RowNames', {label});
end

function rows = table_to_rows(T)
%TABLE_TO_ROWS  Convert the comparison table to a struct array for jsonencode.
    n = height(T);
    for r = n:-1:1
        rows(r).parameter   = T.Properties.RowNames{r};
        rows(r).Fidelity    = T.Fidelity{r};
        rows(r).Computed    = T.Computed{r};
        rows(r).Brandt      = T.Brandt{r};
        rows(r).PctDiff     = T.PctDiff{r};
        rows(r).OtherSource = T.OtherSource{r};
        rows(r).Source      = T.Source{r};
        rows(r).Notes       = T.Notes{r};
    end
end

function write_markdown(T, out_path, now_str)
%WRITE_MARKDOWN  Render the comparison table as a markdown file.
    fid = fopen(out_path, 'w');
    fprintf(fid, '# F-16A Block 10 — Propulsion vs Brandt Ground Truth\n\n');
    fprintf(fid, 'Generated %s.\n\n', now_str);
    fprintf(fid, ['Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.propulsion`] ' ...
        '(Brandt-workbook outputs, cited per cell).\n\n']);
    fprintf(fid, ['This is a **comparison report**, not a test — no pass/fail assertions, not in `run_all_tests`. ' ...
        'The framework''s Mattingly engine model (Eq. 2.54 lapse / Eq. 3.55 TSFC) and Brandt''s Engn(s) model are ' ...
        '**different models**, so a large %%Diff is frequently **expected** (see Notes), not a defect. ' ...
        'Brandt SLS TSFCs 0.70/2.20 are **installed** (already ×1.08) — compare the framework installed rows.\n\n']);
    fprintf(fid, '| Parameter | Fidelity | Computed | Brandt | %%Diff | Other source | Source | Notes |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|---|\n');
    n = height(T);
    for r = 1:n
        name = T.Properties.RowNames{r};
        if strcmp(T.Computed{r}, '---')
            fprintf(fid, '| **%s** | | | | | | | |\n', strrep(name, '|', '\|'));
        else
            fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s | %s |\n', ...
                strrep(name, '|', '\|'), T.Fidelity{r}, T.Computed{r}, T.Brandt{r}, T.PctDiff{r}, ...
                strrep(T.OtherSource{r}, '|', '\|'), strrep(T.Source{r}, '|', '\|'), strrep(T.Notes{r}, '|', '\|'));
        end
    end
    fclose(fid);
end

function T_all = propulsion_brandt_comparison()
%PROPULSION_BRANDT_COMPARISON  F-16A propulsion at every fidelity vs ground truth.
%
%   Two jobs. (1) A one-stop comparison: run every propulsion tier at the six
%   Brandt constraint conditions and put its output next to his workbook.
%   (2) A worked example of how to drive this framework — read it top to bottom
%   and you have seen the whole input story for propulsion.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> propulsion_brandt_comparison
%   Or non-interactively:
%     $ matlab -batch "addpath(genpath('src')); addpath(genpath('examples')); propulsion_brandt_comparison"
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%     f16a_spec_path(N) -> examples/F16A/inputs/f16a_L{N}.json, the SPEC file. The
%                          .propulsion block carries:
%                            L1  engine_type, T_SL
%                            L2  + T_SL_mil, T_t4_max_F, TSFC_install_factor,
%                                bypass_ratio
%                          T_SL_wet is NOT an input at either level — it is
%                          Dependent on T_SL, because two settable copies of
%                          one thrust is how they drift apart.
%   Ground truth is separate and lives under VnV/BrandtF16A/, read here as `gt`.
%   It is never an input — only a comparison target.
%
%   ─── HOW TO WIRE THE DEPENDENCIES ───────────────────────────────────────
%   Propulsion is the ROOT of the dependency graph — it injects nothing:
%
%       p1 = F16PropL1(f16a_spec_path(1));
%       p2 = F16PropL2(f16a_spec_path(2));
%
%   Everything else depends on IT. Geometry takes a propulsion object to size
%   the nacelle from thrust; weights takes one for the Raymer Eq. 10.10 engine
%   weight and, at L3, for the cruise SFC. So build propulsion first and pass
%   the same object onward — see geometry_brandt_comparison.m for that chain.
%
%   Flight conditions are built with AircraftState(altitude_ft, mach), which
%   carries the total-ratio terms (delta_0, theta_0) the Mattingly lapse needs.
%
%   ─── NO L3 PROPULSION TIER EXISTS, and none is planned ──────────────────
%   Geometry, aerodynamics and weights are L1/L2/L3; propulsion is L1/L2. The
%   framework's L3 rung pairs F16AeroL3 with F16PropL2, so any "L3" propulsion
%   figure anywhere in this project is computed by F16PropL2 and equals the L2
%   rows below. That is a deliberate decision, not a missing tier.
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     propulsion_brandt_comparison.json  full table + metadata
%     propulsion_brandt_comparison.md    rendered markdown
%   Both via src/reporting/ComparisonReport.m, shared by all four discipline
%   reports so their columns cannot drift apart.
%
%   ─── WHY THIS IS A REPORT, NOT A UNIT TEST ──────────────────────────────
%   Every row compares two different engine MODELS — Mattingly Eq. 2.54/3.55
%   against Brandt's own Engn(s) lapse/TSFC formulas. Those cross-model deltas
%   were once asserted in TestPropL2 under a blanket 30 % tolerance, which is
%   not a unit test of anything. They live here instead; the unit tier checks
%   only hand-computed or published expecteds and never reads this JSON.
%
%   ─── SEMANTICS OF BRANDT'S THREE LAPSE COLUMNS (live-xls verified) ──────
%     AS = alpha_dry          delta_0 basis, normalized to T_SL_dry = 15,000
%     AT = alpha_AB           delta_0 basis, normalized to T_SL_AB  = 23,770
%     AU = alpha_eff_on_TAB   effective lapse on the T_SL_AB axis; for a
%                             100 %-AB row AU = AT, for the 0 %-AB cruise row
%                             AU = AS*(T_dry/T_AB)
%   The framework's Mattingly alpha_AB compares against AT; a dry/mil point
%   (cruise) compares against AU.
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]    F-16A.xls (Consts / Engn(s) / Main / Miss tabs)
%     [Mattingly] Aircraft Engine Design 2nd ed., AIAA, 2002 (Eq. 2.54 lapse,
%                 Eq. 3.55 TSFC, Eq. D.6 TR, Table C.4)
%     [Raymer]    Aircraft Design (Table 3.3; Eq. 10.11/10.13/10.15)
%     [T.O.]      T.O. 1F-16A-1, Sec. I
%
%   NOT A TEST: informational only, never pass/fail, and no value here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule).

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(fileparts(script_dir)));
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
% F16PropL2 -- see any design_study_*.m for the per-level construction. So every propulsion
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
    a_mil = p2.thrust_lapse(st, "mil");
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
    'T.O. 1F-16A-1 Sec.I', 'Brandt Main!D29', '%.1f', 'Spec input echoed both sides -- should match exactly.', '')];
T = [T; prow('T_SL_mil (dry SLS thrust) [lbf]', 'L2', p2.T_SL_mil, gt.T_SL_mil_lb.value, ...
    'T.O. 1F-16A-1 Sec.I', 'Brandt Main!C29', '%.1f', 'Spec input echoed both sides -- should match exactly.', '')];
T = [T; prow('TR (throttle ratio)', 'L2', p2.TR, brandt_TR, ...
    'Mattingly Eq.D.6 (T_t4_SLS unknown->1.0)', 'Brandt Engn(s)!S1', '%.4f', 'Should match exactly (both 1.0).', '')];

% ── Nacelle sizing (Brandt Engn(s) formula, positive control) ───────────── %
D_nac = sqrt(p2.T_SL_wet / 1900);   % Brandt Engn(s) D = sqrt(T_AB_SLS/1900)
L_nac = 4.5 * D_nac;                % Brandt Engn(s) L = 4.5*D
T = [T; srow('[NACELLE SIZING -- Brandt Engn(s) formula reproduced as positive control]')];
T = [T; prow('Nacelle diameter D=sqrt(T_AB/1900) [ft]', 'L2', D_nac, gt.nacelle.diameter_ft.value, ...
    'Raymer Eq.10.12 ~3.8 (unwired)', 'Brandt Engn(s) D_nac', '%.4f', 'Same formula/inputs as Brandt -- near-exact match expected.', '')];
T = [T; prow('Nacelle length L=4.5*D [ft]', 'L2', L_nac, gt.nacelle.length_ft.value, ...
    'T.O. 1F-16A-1 total length 15.93', 'Brandt Engn(s) L_nac', '%.4f', 'Same formula/inputs as Brandt; T.O. total engine length 15.93 ft is an independent anchor.', '')];
% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY + EXPORT — all four discipline reports share one renderer
%  (src/reporting/ComparisonReport.m), so their columns cannot drift apart.
% ════════════════════════════════════════════════════════════════════════ %

meta = struct( ...
    'title',         'F-16A Block 10/15 — Propulsion vs Ground Truth', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     'Six Brandt constraint-analysis flight conditions (Consts rows 23-28).', ...
    'referenceDesc', ['Brandt F-16A.xls workbook outputs, via ' ...
                      '`VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.propulsion`], each row ' ...
                      'cited to a `Consts` / `Engn(s)` cell.'], ...
    'secondDesc',    ['the corresponding independent figure where one exists — Mattingly''s ' ...
                      '**uninstalled** TSFC coefficients, Raymer Table 3.3''s categorical L1 TSFC, ' ...
                      'or the T.O. 1F-16A-1 nacelle length. Blank where the only source is Brandt.'] );

meta.preamble = { ...
    ['**There is no L3 propulsion tier, by decision.** Geometry, aerodynamics and weights are ' ...
     'L1/L2/L3; propulsion is L1/L2. The L3 rung pairs `F16AeroL3` with `F16PropL2`, so **every L2 ' ...
     'row below IS the L3 result** — an "L3 propulsion" number anywhere in this project is computed ' ...
     'by `F16PropL2`.'], ...
    ['**These are two different engine models, not one model checked twice.** The framework uses ' ...
     'Mattingly Eq. 2.54 (lapse) and Eq. 3.55 (TSFC); Brandt uses his own `Engn(s)` formulas. A large ' ...
     '%Diff is frequently the expected answer — read the Notes column before treating one as an error.'], ...
    ['**Installed vs uninstalled is the trap in this discipline.** Brandt''s stored SLS TSFCs ' ...
     '(0.70 mil / 2.20 AB) are **already installed** — they include the 1.08 factor. Compare them ' ...
     'against the framework''s *installed* rows; applying 1.08 on top of them double-counts.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, '..', 'output', 'propulsion_brandt_comparison.json');
out_md   = fullfile(script_dir, '..', 'output', 'propulsion_brandt_comparison.md');
ComparisonReport.writeJson(T, out_json, meta);
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  JSON     -> %s\n', out_json);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

% ─── local helpers: thin wrappers over the shared renderer ───────────────── %

function T = prow(name, fidelity, computed, reference, second, cite, numfmt, notes, divergence)
%PROW  One comparison row. See ComparisonReport.row for the column semantics.
%   `divergence` was added when the four reports were unified -- this report had
%   no such column, so its cross-model rows had no way to say "expected".
%
%   DEFAULT IS 'BY DESIGN', which inverts the other three reports on purpose:
%   almost every row here compares the framework's MATTINGLY model against
%   Brandt's own ENGN(S) model, so "expected to differ" is the norm rather than
%   the exception. The genuine agreement checks -- spec passthroughs and rows
%   using Brandt's own formula on Brandt's own inputs -- pass '' explicitly.
    if nargin < 8; notes      = ''; end
    if nargin < 9; divergence = 'BY DESIGN'; end
    T = ComparisonReport.row(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence);
end

function T = srow(label)
%SROW  Section separator row.
    T = ComparisonReport.section(label);
end


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


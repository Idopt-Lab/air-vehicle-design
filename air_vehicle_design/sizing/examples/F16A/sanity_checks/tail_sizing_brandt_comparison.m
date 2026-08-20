function T_all = tail_sizing_brandt_comparison()
%TAIL_SIZING_BRANDT_COMPARISON  F-16A tail sizing (L1) vs ground truth.
%
%   Runs the actual F16TailL1 discipline code and puts its S_ht/S_vt output
%   next to Brandt's workbook values. Follows the same structure/helpers as
%   examples/F16A/sanity_checks/geometry_brandt_comparison.m.
%
%   L2 tail sizing is a not-implemented stub (docs/decision_log.md), so only
%   the L1 volume-coefficient method is compared here.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> tail_sizing_brandt_comparison
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%   Tail sizing has no JSON inputs of its own (C_HT/C_VT are hardcoded F-16
%   spec facts in F16TailL1, not read from JSON). It consumes wing geometry
%   from an injected F16GeomL2 object and reads it live:
%     prop = F16PropL2(f16a_spec_path(2));
%     g2   = F16GeomL2(f16a_spec_path(2), prop);
%     tail = F16TailL1(g2);
%
%   Ground truth is separate, read as `gt` from
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json's `tail_sizing` block.
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     output/tail_sizing_brandt_comparison.json   full table + metadata
%     output/tail_sizing_brandt_comparison.md      rendered markdown
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]  S. Brandt, F-16A.xls, via VnV/BrandtF16A/GroundTruth/
%               f16a_ground_truth.json (.tail_sizing) -- Main!C18 (S_ht),
%               Main!H18 (S_vt).
%     [Raymer]  Aircraft Design, 7th ed., AIAA, 2018, Table 6.4 + text (L1).
%
%   NOT A TEST: informational only, never pass/fail. The large %Diff is the
%   EXPECTED signature of a historical-average volume-coefficient method vs
%   Brandt's back-calculated 108/60 -- not a framework defect. See
%   TailSizing_scribe_plan.md Sec. 2 item 4.

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(fileparts(script_dir)));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
gt          = jsondecode(fileread(gt_path)).tail_sizing;

% ════════════════════════════════════════════════════════════════════════ %
%  COMPUTE — run the actual toolbox code
% ════════════════════════════════════════════════════════════════════════ %

prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);

% L1: volume-coefficient method, injected geometry read live.
tail1  = F16TailL1(g2);
r1     = tail1.size();

S_ht_brandt = gt.S_ht_ft2.value;   % 108.0  [Brandt Main!C18]
S_vt_brandt = gt.S_vt_ft2.value;   % 60.0   [Brandt Main!H18]

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %

T = table();

T = [T; srow('[HORIZONTAL TAIL AREA S_ht]')];
T = [T; grow('S_ht, L1 volume-coefficient method [ft^2]', 'L1', r1.S_ht, S_ht_brandt, 'Brandt Main!C18', '%.4f', ...
    ['Raymer 7th ed. Table 6.4 jet-fighter row (c_HT=0.40) corrected for RSS (-10%) and the F-16''s all-moving ' ...
     'stabilator (-12.5%): net c_HT=0.315. A historical-average, category-level coefficient method is not ' ...
     'expected to reproduce one specific real aircraft''s back-calculated area tightly. Not a defect -- see header.'])];

T = [T; srow('[VERTICAL TAIL AREA S_vt]')];
T = [T; grow('S_vt, L1 volume-coefficient method [ft^2]', 'L1', r1.S_vt, S_vt_brandt, 'Brandt Main!H18', '%.4f', ...
    ['Raymer 7th ed. Table 6.4 jet-fighter row (c_VT=0.07) corrected for RSS only (-10%, no VT-specific text ' ...
     'correction exists): net c_VT=0.063.'])];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY + EXPORT
% ════════════════════════════════════════════════════════════════════════ %

meta = struct( ...
    'title',         'F-16A Block 10/15 — Tail Sizing vs Ground Truth', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     'Wing geometry from F16GeomL2 (S_ref=300 ft^2, AR_wing=3.0, lambda_wing=0.2275, L_fus=46.5 ft).', ...
    'referenceDesc', ['Brandt F-16A.xls, via `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.tail_sizing`] ' ...
                      '-- Main!C18 (S_ht), Main!H18 (S_vt).'], ...
    'secondDesc',    'No second source for this discipline. L2 tail sizing is a not-implemented stub (docs/decision_log.md).' );

meta.preamble = { ...
    ['**L1 is a historical-average / category-level volume-coefficient method, not a stability-and-control design ' ...
     'against the F-16''s actual CG and required static margin.** A large %Diff against Brandt''s back-calculated ' ...
     '108/60 is the EXPECTED signature of that fidelity level, not a framework defect.'], ...
    ['**Coefficient corrections.** The RSS + all-moving-tail text corrections applied at L1 REDUCE c_HT/c_VT below ' ...
     'Raymer''s already-conservative jet-fighter row, which widens L1''s gap against Brandt relative to an ' ...
     'uncorrected flat 0.40/0.07.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, '..', 'output', 'tail_sizing_brandt_comparison.json');
out_md   = fullfile(script_dir, '..', 'output', 'tail_sizing_brandt_comparison.md');
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

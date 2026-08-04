function T_all = tail_sizing_brandt_comparison()
%TAIL_SIZING_BRANDT_COMPARISON  F-16A tail sizing (L1/L2) vs ground truth.
%
%   Runs the actual F16GeomL2 tail-sizing code (absorbed from the former
%   tail_sizing discipline, 2026-08-03 -- see F16GeomL2.m's TAIL SIZING
%   section) and puts its S_ht/S_vt output next to Brandt's workbook
%   values. Follows the same structure/helpers as
%   examples/F16A/geometry_brandt_comparison.m and
%   examples/F16A/fidelity_comparison.m.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> tail_sizing_brandt_comparison
%   Or non-interactively:
%     $ matlab -batch "addpath(genpath('src')); addpath(genpath('examples')); tail_sizing_brandt_comparison"
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%   Tail sizing has no JSON inputs of its own (C_HT/C_VT and
%   C_HT_nicolai/C_VT_nicolai are hardcoded F-16 spec facts in F16GeomL2's
%   constructor, not read from JSON) -- it reads wing geometry off the same
%   F16GeomL2 object, built the usual way:
%     prop = F16PropL2(f16a_spec_path(2));
%     g2   = F16GeomL2(f16a_spec_path(2), prop);
%   g2.size_tail() is the PRIMARY, Raymer 7th ed. volume-coefficient path;
%   g2.size_tail_nicolai() is the SECONDARY, Nicolai & Carichner F-16-
%   specific-coefficient path -- both self-reference g2's own live
%   S_ref/b_wing/cbar_wing/L_fus.
%
%   Ground truth is separate, read here as `gt` from
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json's new `tail_sizing`
%   block. It is never an input to the framework, only a comparison target.
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     jsons/tail_sizing_brandt_comparison.json   full table + metadata
%     mds/tail_sizing_brandt_comparison.md       rendered markdown
%   Both produced by src/reporting/ComparisonReport.m, shared by all four+
%   discipline reports so their columns cannot drift apart.
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]  S. Brandt, F-16A.xls, via VnV/BrandtF16A/GroundTruth/
%               f16a_ground_truth.json (.tail_sizing) -- Main!C18 (S_ht),
%               Main!H18 (S_vt).
%     [Raymer]  Aircraft Design, 7th ed., AIAA, 2018, Table 6.4 + text (L1).
%     [Nicolai] Nicolai & Carichner, Table 11.6, "General Dynamics F-16" row,
%               p.289 (L2).
%
%   NOT A TEST: informational only, never pass/fail, and no value here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule). The
%   large %Diff expected here is DISCUSSED, not hidden -- see the preamble
%   text below and TailSizing_scribe_plan.md Sec. 2 item 4: the RSS/all-
%   moving-tail corrections applied at L1 REDUCE c_HT/c_VT below Raymer's
%   already-low end, which WIDENS (not narrows) the pre-existing gap against
%   Brandt's back-calculated 108/60 -- a historical-average volume-
%   coefficient method is not expected to reproduce one specific real
%   aircraft's areas tightly, and that is not a defect in this framework.

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
gt          = jsondecode(fileread(gt_path)).tail_sizing;

% ════════════════════════════════════════════════════════════════════════ %
%  COMPUTE — run the actual toolbox code
% ════════════════════════════════════════════════════════════════════════ %

prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);

% ── L1: volume-coefficient method (PRIMARY), self-referencing g2's own live geometry ── %
r1 = g2.size_tail();

% ── L2: Nicolai/Carichner F-16-specific coefficient (SECONDARY), same g2 ── %
r2 = g2.size_tail_nicolai();

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
     'expected to reproduce one specific real aircraft''s back-calculated area tightly; the corrections applied ' ...
     'here REDUCE c_HT below Raymer''s already-low end, which widens this gap relative to the flat, uncorrected ' ...
     '0.40 the now-superseded TailSizingLevel1 used. Not a defect -- see this script''s header.'])];
T = [T; grow('S_ht, L2 Nicolai/Carichner F-16 coefficient [ft^2]', 'L2', r2.S_ht, S_ht_brandt, 'Brandt Main!C18', '%.4f', ...
    ['Nicolai & Carichner Table 11.6, "General Dynamics F-16" row (C_HT=0.3, an F-16-SPECIFIC measured ' ...
     'coefficient, not a generic category row). Same tail arm (0.475*L_fus) as L1 -- L2''s fidelity gain is ' ...
     'confined to the coefficient source and wing-geometry precision, not the arm.'])];

T = [T; srow('[VERTICAL TAIL AREA S_vt]')];
T = [T; grow('S_vt, L1 volume-coefficient method [ft^2]', 'L1', r1.S_vt, S_vt_brandt, 'Brandt Main!H18', '%.4f', ...
    ['Raymer 7th ed. Table 6.4 jet-fighter row (c_VT=0.07) corrected for RSS only (-10%, no VT-specific text ' ...
     'correction exists): net c_VT=0.063.'])];
T = [T; grow('S_vt, L2 Nicolai/Carichner F-16 coefficient [ft^2]', 'L2', r2.S_vt, S_vt_brandt, 'Brandt Main!H18', '%.4f', ...
    'Nicolai & Carichner Table 11.6, "General Dynamics F-16" row (C_VT=0.094, an F-16-SPECIFIC measured coefficient).')];

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
    'secondDesc',    'No second source for this discipline yet -- L3 (Raymer Ch. 16 stability-and-control sizing) is a documented-TODO stub, see examples/F16A/tail_sizing_brandt_comparison.m header and TestTailL3.m.' );

meta.preamble = { ...
    ['**Both L1 and L2 are historical-average / category-level volume-coefficient methods, not a stability-and-' ...
     'control design against the F-16''s actual CG and required static margin** -- that is L3''s job (Raymer ' ...
     'Ch. 16), currently a documented-TODO stub (no verifiable equation numbers in this repository -- see ' ...
     'VnV/BrandtF16A/todo.md 2026-07-28 Finding 3). A large %Diff against Brandt''s back-calculated 108/60 here is ' ...
     'the EXPECTED signature of that fidelity gap, not a framework defect.'], ...
    ['**L1 vs L2 numeric trend.** The RSS + all-moving-tail text corrections applied at L1 REDUCE c_HT/c_VT below ' ...
     'Raymer''s already-conservative jet-fighter row, which widens L1''s gap against Brandt relative to what an ' ...
     'uncorrected flat 0.40/0.07 would give. L2''s Nicolai & Carichner coefficients are F-16-SPECIFIC (measured ' ...
     'from the real aircraft, Table 11.6), so L2 is expected to track Brandt more closely than L1 -- whether it ' ...
     'actually does, and by how much, is exactly what this table reports.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, 'jsons', 'tail_sizing_brandt_comparison.json');
out_md   = fullfile(script_dir, 'mds', 'tail_sizing_brandt_comparison.md');
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

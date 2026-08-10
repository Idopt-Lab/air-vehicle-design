function T_all = tail_sizing_brandt_comparison()
%TAIL_SIZING_BRANDT_COMPARISON  F-16A tail sizing (L1/L2) vs ground truth.
%
%   Runs the actual F16TailL1/F16TailL2 discipline code and puts its S_ht/
%   S_vt output next to Brandt's workbook values. Follows the same
%   structure/helpers as examples/F16A/geometry_brandt_comparison.m and
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
%   Tail sizing has no JSON inputs of its own (scribe plan Sec. 5.3: C_HT/
%   C_VT are hardcoded F-16 spec facts in F16TailL1/F16TailL2, not read from
%   JSON) -- it consumes wing geometry from an F16GeomL2 object, built the
%   usual way:
%     prop = F16PropL2(f16a_spec_path(2));
%     g2   = F16GeomL2(f16a_spec_path(2), prop);
%   L1 tail sizing takes S_ref/b/cbar/L_fus as raw scalars (GeometryModelL1
%   has no planform to inject); L2 tail sizing takes the injected g2 object
%   directly and reads its geometry live.
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

% ── L1: volume-coefficient method, raw scalars from g2's live geometry ── %
tail1  = F16TailL1();
r1     = tail1.size(g2.S_ref, g2.b_wing, g2.cbar_wing, g2.L_fus);

% ── L2: Nicolai/Carichner F-16-specific coefficient, injected geometry ── %
tail2  = F16TailL2(g2);
r2     = tail2.size();

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

% ── CONTROL SURFACES (ADDED 2026-08-10) ─────────────────────────────────── %
% Computed = the Raymer/Roskam ESTIMATES f16a_control_surfaces() produces.
% Reference = the MEASURED areas off T.O. 1F-16A-1 Fig. 1-2. This is the whole
% point of the section: it measures how good the textbook estimates are, and
% no estimate here is ever fitted backwards to close a gap (docs/PLAN.md
% forbids back-calculated values as inputs).
%
% Evaluated at the JSON BASELINE geometry (g2: S_ref=300, S_ht=108, S_vt=60)
% rather than at a converged sizing-loop point, so the numbers are directly
% comparable with the measured areas of the real 300 ft^2-wing aircraft.
ctrl = f16a_control_surfaces();
cs   = ctrl.size(g2);

T = [T; srow('[WING CONTROL SURFACES — Roskam Part II Eq. 7.10]')];
T = [T; grow('S_flaperon, TE flaperon [ft^2]', 'L1', cs.S_flaperon, 31.32, 'T.O. 1F-16A-1 Fig. 1-2', '%.4f', ...
    ['The F-16 has NO separate ailerons: one trailing-edge flaperon serves as both aileron and flap. ' ...
     'c/c=0.25 [Raymer 6th ed. p.162, "ailerons and flaps are typically 15-25% of wing chord"], span band ' ...
     'eta=0.35-0.75 (0.40 extent from Raymer Fig. 6.3''s historical-guidelines band, placed outboard of the ' ...
     'strake). Reads LOW: Fig. 6.3 gives only the span EXTENT, so the station placement is a judgement call, ' ...
     'and this airframe''s flaperon is chord-deeper or wider than the band''s typical fighter.'])];
T = [T; grow('S_lef, leading-edge flap [ft^2]', 'L1', cs.S_lef, 36.71, 'T.O. 1F-16A-1 Fig. 1-2', '%.4f', ...
    ['c/c=0.15, eta=0.00-0.98, carried over unchanged from F16AeroL3''s existing LE-device estimate. Reads ' ...
     'HIGH, and eta_in=0 is the main reason: the real LEF starts OUTBOARD of the strake, not at the ' ...
     'centreline. Deliberately not adjusted to close the gap -- that would be fitting an estimate to ground ' ...
     'truth. Logged in VnV/BrandtF16A/todo.md.'])];
T = [T; grow('S_csw = S_flaperon + S_lef [ft^2]', 'L1', cs.S_flaperon + cs.S_lef, 68.03, ...
    'T.O. 1F-16A-1 Fig. 1-2 (31.32 + 36.71)', '%.4f', ...
    ['The quantity Raymer Eq. 15.1''s wing-weight term actually consumes, via the Dependent ' ...
     'F16GeomL3.S_csw. Agrees far better than either component, because the flaperon reads low and the LEF ' ...
     'reads high and the two errors partly cancel -- worth knowing before trusting the sum as evidence that ' ...
     'both parts are right.'])];

T = [T; srow('[TAIL CONTROL SURFACES — Raymer 6th ed. Table 6.5 / p.161]')];
T = [T; grow('S_stab, all-moving stabilator [ft^2]', 'L1', cs.S_stab, 108.0, 'Brandt Main!C18 = S_ht', '%.4f', ...
    ['On an all-moving tail the pitch control surface IS the whole horizontal tail [Raymer Table 6.5''s ' ...
     'footnote to the Fighter/attack row: "Supersonic usually all-moving tail without separate elevator"], so ' ...
     'S_stab = S_ht identically and the 0.00% agreement here is DEFINITIONAL, not a validation. The real ' ...
     'content of this row is that S_elev = 0 -- and that the tail''s own area is now carried somewhere, which ' ...
     'before 2026-08-10 it was not.'])];
T = [T; grow('S_rud, rudder [ft^2]', 'L1', cs.S_rud, 11.65, 'T.O. 1F-16A-1 Fig. 1-2', '%.4f', ...
    ['★ THE FRAMEWORK''S LARGEST CONTROL-SURFACE ERROR, and the one that matters most: geom.S_r aliases this ' ...
     'area into Raymer Eq. 15.3''s (1 + S_r/S_vt)^0.348 vertical-tail weight term. c/c=0.30 [Table 6.5, ' ...
     'Fighter/attack, Cr/C] x 0.90 span [p.161, "extend to the tip of the tail or to about 90% of the tail ' ...
     'span"]. Deliberately NOT calibrated to 11.65: Raymer''s printed fractions are what a conceptual design ' ...
     'has available, and the gap IS the finding. Note GeomL1.lookup_control_surface_fraction returns 0.33 for ' ...
     'the same row out of Raymer''s 7th ed., so two editions disagree as well. Logged in todo.md.'])];

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
    ['**CONTROL SURFACES (added 2026-08-10) measure ESTIMATES against MEASURED areas.** The two tail-area ' ...
     'sections above compare against Brandt''s back-calculated 108/60; the two control-surface sections compare ' ...
     'against T.O. 1F-16A-1 Fig. 1-2, i.e. the real aircraft. Keep the directions straight: everything in the ' ...
     '"Computed" column is a Raymer/Roskam conceptual-design estimate, and nothing in it is ever fitted ' ...
     'backwards from the "Reference" column -- that would make this table a tautology and is the ' ...
     'back-calculated-value-as-input pattern docs/PLAN.md forbids. All rows are evaluated at the JSON BASELINE ' ...
     'geometry (S_ref=300, S_ht=108, S_vt=60), not at a converged sizing-loop point, so they are directly ' ...
     'comparable with the measured areas of the real 300 ft^2-wing aircraft.'], ...
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

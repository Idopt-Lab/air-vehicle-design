function [T, S] = f16a_generate_tail_test()
%F16A_GENERATE_TAIL_TEST  F-16A tail sizing at L1, L2 and L3.
%   The three tail sizers run on the geometry that the upstream generators
%   cascade (f16a_generate_weights_test returns the geometry, aerodynamics,
%   propulsion and weights of all three tiers), then the sized S_ht/S_vt go back
%   into the L2 and L3 geometry objects, the way SizingLoopL2 does it. Every
%   planform, wetted-area, control-surface and weight row below therefore
%   belongs to the tail this file sized, not to Brandt's given 108/60 ft^2. The
%   tier rides in the row label, so the Fidelity column is dropped.
%   Informational only: this is not a test, and no value here may backfill a
%   unit test. The table prints to the console and is written as
%   mds/f16a_generate_tail_test.md.
%
%   SOURCES: [Brandt] F-16A.xls Main, Geom and Wt tabs, via
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json. [Raymer] Aircraft Design
%   6th/7th ed., Table 6.4, Table 6.5, Table 15.2, Eqs. 15.2/15.3, ch. 16.
%   [Nicolai] Nicolai & Carichner, Eqs. 11.1/11.2, Table 11.6. [Roskam]
%   Airplane Design Vol. II, Eq. 12.1. [T.O.] T.O. 1F-16A-1 Fig. 1-2.

[~, W] = f16a_generate_weights_test();
G      = W.P.A.G;
g2     = G.L2;
g3     = G.L3;
W_TO   = G.W_TO;
ctrl   = f16a_control_surfaces();
gt     = brandt_tail_reference();

% Brandt's own tail planform: an F16GeomL2 straight from the L2 JSON, with no
% cascade override, so its stations and areas are his Main-tab spec sheet.
gb    = F16GeomL2(f16a_spec_path(2), W.P.L2);
arm_b = [gb.L_HT, gb.L_VT];

% What Brandt's given areas imply for the same coefficients
% [Nicolai Eqs. 11.1/11.2, solved for the coefficient].
C_HT_b = gb.S_ht * arm_b(1) / (gb.cbar_wing * gb.S_ref);
C_VT_b = gb.S_vt * arm_b(2) / (gb.b_wing    * gb.S_ref);

% ── size the tail at every tier ────────────────────────────────────────── %
% L1 has no layout, so Raymer's pre-layout arm fraction is the only cited
% option, and the wing planform comes from the cascaded scalars.
b1    = GeometryBase.compute_span(G.AR_wing, G.S_ref);
cbar1 = GeometryBase.compute_mac(GeometryBase.compute_root_chord(G.S_ref, b1, G.lambda_wing), G.lambda_wing);
arm1  = TailL1.compute_tail_arm(G.L1.L_fuselage);

t1 = F16TailL1();        % Raymer Table 6.4, RSS and all-moving corrections
t2 = F16TailL2(g2);      % Nicolai Table 11.6, the F-16 row

x_cg2 = TailL2.compute_x_cg_initial(g2.x_mac_le_wing, g2.cbar_wing);
arm   = [arm1,                                          arm1; ...
         TailL2.compute_tail_arm_cg(g2.x_c4_ht, x_cg2), TailL2.compute_tail_arm_cg(g2.x_c4_vt, x_cg2); ...
         g3.L_HT,                                       g3.L_VT];
coef  = [t1.c_HT, t1.c_VT; t2.C_HT, t2.C_VT; t1.c_HT, t1.c_VT];

r1 = t1.size(G.S_ref, b1, cbar1, arm(1,1), arm(1,2));
r2 = t2.size();
r3 = t1.size(g3.S_ref, g3.b_wing, g3.cbar_wing, arm(3,1), arm(3,2));   % L3 has no sizer of its own
S_ht = [r1.S_ht, r2.S_ht, r3.S_ht];
S_vt = [r1.S_vt, r2.S_vt, r3.S_vt];

% Write the sized areas back, so the planform and weight rows below read the
% tail this file sized [same order and mechanism as SizingLoopL2].
g2.S_ht = S_ht(2);  g2.S_vt = S_vt(2);
g3.S_ht = S_ht(3);  g3.S_vt = S_vt(3);

% F16TailL3 errors instead of returning a number; capture that, do not hide it.
try
    F16TailL3().size();
    l3_id = 'none';
catch err
    l3_id = err.identifier;
end

lvl = {'L1', 'L2', 'L3'};
geo = {g2, g3};
wts = {W.L2, W.L3};

coef_src = { ...
    'Raymer 7th ed. Table 6.4 jet-fighter row, x0.90 for relaxed static stability and x0.875 for the all-moving stabilator.', ...
    'Nicolai & Carichner Table 11.6, the "General Dynamics F-16" row itself, so this coefficient is measured off the real aircraft.', ...
    'The L1 coefficients again: L3 tail sizing is a documented stub, so the L3 rung sizes with the L1 method on the L3 layout.'};
arm_src = { ...
    'Raymer''s pre-layout fraction 0.475*L_fus. The only cited option at L1: F16GeomL1 has no planform, no station and no sweep.', ...
    'Nicolai Eqs. 11.1/11.2: the initial c.g. estimate at 30% of the wing MAC, to the tail MAC quarter-chord.', ...
    'Raymer Sec. 6.5.2 p.158: wing MAC quarter-chord to tail MAC quarter-chord, off the L3 layout stations.'};
arm_div = {'BY DESIGN', 'DEFINITIONAL', 'BY DESIGN'};

% ── the table ──────────────────────────────────────────────────────────── %
T = ComparisonReport.section('TAIL VOLUME COEFFICIENTS -- Reference = what Brandt''s given 108/60 ft^2 imply at his own Raymer moment arm');
for i = 1:3
    T = [T; cmp('c_HT', '-', lvl{i}, coef(i,1), C_HT_b, '%.4f', 'Brandt Main!C18 at Main!B23/C23', coef_src{i})]; %#ok<AGROW>
    T = [T; cmp('c_VT', '-', lvl{i}, coef(i,2), C_VT_b, '%.4f', 'Brandt Main!H18 at Main!B23/H23', coef_src{i})]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('TAIL MOMENT ARMS -- Reference = the Raymer arm of Brandt''s own layout. Each tier uses the arm its coefficient table was tabulated on')];
for i = 1:3
    T = [T; cmp('L_HT', 'ft', lvl{i}, arm(i,1), arm_b(1), '%.3f', 'Brandt Main!B23/C23 stations', arm_src{i}, arm_div{i})]; %#ok<AGROW>
    T = [T; cmp('L_VT', 'ft', lvl{i}, arm(i,2), arm_b(2), '%.3f', 'Brandt Main!B23/H23 stations', arm_src{i}, arm_div{i})]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('SIZED REFERENCE AREAS -- S = c * (cbar or b) * S_ref / L [Raymer Table 6.4; Nicolai Eqs. 11.1/11.2]')];
for i = 1:3
    T = [T; cmp('S_ht', 'ft^2', lvl{i}, S_ht(i), gt.S_ht_b, '%.3f', 'Brandt Main!C18', coef_src{i})]; %#ok<AGROW>
    T = [T; cmp('S_vt', 'ft^2', lvl{i}, S_vt(i), gt.S_vt_b, '%.3f', 'Brandt Main!H18', coef_src{i})]; %#ok<AGROW>
end
T = [T; cmp('S_ht via static margin', 'ft^2', 'L3', NaN, gt.S_ht_b, '%.3f', 'Brandt Main!C18', ...
    sprintf('NOT IMPLEMENTED: F16TailL3().size() raises %s. Raymer ch. 16 gives no equation this repository can cite for sizing S_ht from a required static margin.', l3_id), 'DEFINITIONAL')];
T = [T; cmp('S_vt via C_n_beta', 'ft^2', 'L3', NaN, gt.S_vt_b, '%.3f', 'Brandt Main!H18', ...
    'NOT IMPLEMENTED: same citation gap as the row above, for the directional-stability and crosswind criteria.', 'DEFINITIONAL')];

% The HT span and aspect ratio swap roles between the two tiers.
span_src = {'L2 derives the span from the input AR and the sized area.', ...
            'L3 takes the T.O. 18.5 ft span as the PRIMARY input.'};
ar_src   = {'L2 takes Brandt''s AR as an input, so this row is a spec echo.', ...
            'L3 derives the AR from that primary span and the sized area.'};
ar_div   = {'', 'BY DESIGN'};

T = [T; ComparisonReport.section('HORIZONTAL-TAIL PLANFORM FROM THE SIZED AREA -- read live off the geometry after the write-back')];
for i = 1:2
    g = geo{i};  L = lvl{i+1};
    T = [T; cmp('b_ht',         'ft',   L, g.b_ht,         gt.ht.span_full_ft,       '%.3f', 'Brandt Geom!8', span_src{i})]; %#ok<AGROW>
    T = [T; cmp('AR_ht',        '-',    L, g.AR_ht,        gt.ht_AR,                 '%.3f', 'Brandt Main!C19', ar_src{i}, ar_div{i})]; %#ok<AGROW>
    T = [T; cmp('c_root_ht',    'ft',   L, g.c_root_ht,    gt.ht.root_chord_full_ft, '%.3f', 'Brandt Geom!8')]; %#ok<AGROW>
    T = [T; cmp('c_tip_ht',     'ft',   L, g.c_tip_ht,     gt.ht.tip_chord_full_ft,  '%.3f', 'Brandt Geom!8')]; %#ok<AGROW>
    T = [T; cmp('S_exposed_ht', 'ft^2', L, g.S_exposed_ht, gt.ht.exposed_S_ft2,      '%.3f', 'Brandt Geom!8', ...
        'The fuselage-carry-through cut, which the Raymer weight equations consume in place of the full planform.')]; %#ok<AGROW>
    T = [T; cmp('S_wet_ht',     'ft^2', L, g.S_wet_ht,     gt.ht_S_wet,              '%.3f', 'Brandt Geom!B16', ...
        'Roskam Vol. II Eq. 12.1 on the exposed panel, against Brandt''s own uniform-t/c form.')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('VERTICAL-TAIL PLANFORM FROM THE SIZED AREA -- single panel, span not halved')];
for i = 1:2
    g = geo{i};  L = lvl{i+1};
    T = [T; cmp('b_vt',         'ft',   L, g.b_vt,         gt.vt.span_full_ft,       '%.3f', 'Brandt Geom!10')]; %#ok<AGROW>
    T = [T; cmp('AR_vt',        '-',    L, g.AR_vt,        gt.vt_AR,                 '%.3f', 'Brandt Main!H19', 'Spec data echoed on both sides, so this must match.', '')]; %#ok<AGROW>
    T = [T; cmp('c_root_vt',    'ft',   L, g.c_root_vt,    gt.vt.root_chord_full_ft, '%.3f', 'Brandt Geom!10')]; %#ok<AGROW>
    T = [T; cmp('c_tip_vt',     'ft',   L, g.c_tip_vt,     gt.vt.tip_chord_full_ft,  '%.3f', 'Brandt Geom!10')]; %#ok<AGROW>
    T = [T; cmp('S_exposed_vt', 'ft^2', L, g.S_exposed_vt, gt.vt.exposed_S_ft2,      '%.3f', 'Brandt Geom!10', ...
        'Cut by the fuselage HALF height, and free of sweep, so L2 and L3 differ only through the sized area.')]; %#ok<AGROW>
    T = [T; cmp('S_wet_vt',     'ft^2', L, g.S_wet_vt,     gt.vt_S_wet,              '%.3f', 'Brandt Geom!B17')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('TAIL CONTROL SURFACES -- sized off the tail above, in the order SizingLoopL2 uses')];
for i = 1:2
    cs = ctrl.size(geo{i});
    T = [T; cmp('S_stab', 'ft^2', lvl{i+1}, cs.S_stab, gt.S_ht_b, '%.3f', 'Brandt Main!C18 = S_ht', ...
        'The tail is all-moving [Raymer Table 6.5 footnote], so the pitch surface IS the whole horizontal tail and S_elev = 0.')]; %#ok<AGROW>
    T = [T; cmp('S_rud',  'ft^2', lvl{i+1}, cs.S_rud,  11.65,     '%.3f', 'T.O. 1F-16A-1 Fig. 1-2', ...
        'Raymer Table 6.5 0.30 chord x 0.90 span of the sized S_vt. The framework''s largest control-surface error, and it feeds Raymer Eq. 15.3.')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('TAIL WEIGHTS AT THE SIZED AREAS -- Brandt books 6.0 psf on his own FULL 108/60 ft^2')];
wt_src = { ...
    'Raymer Table 15.2 surface density on the EXPOSED planform. Two differences at once: the area convention and the sized area itself.', ...
    'Raymer Eqs. 15.2/15.3 on the exposed planform set. Same two differences as the L2 row.'};
for i = 1:2
    tw = wts{i}.weight_tail(W_TO);
    T = [T; cmp('W_HT', 'lbf', lvl{i+1}, tw.HT, gt.W_HT_b, '%.2f', 'Brandt Wt!E9', wt_src{i})]; %#ok<AGROW>
    T = [T; cmp('W_VT', 'lbf', lvl{i+1}, tw.VT, gt.W_VT_b, '%.2f', 'Brandt Wt!F9', wt_src{i})]; %#ok<AGROW>
end

meta = struct( ...
    'title',         'F-16A -- Tail Sizing from the JSON Inputs and the Cascaded Geometry, Aerodynamics, Propulsion and Weights', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('Cascaded wing: S_ref = %.1f ft^2, AR = %.3f, W_TO = %g lbf.', G.S_ref, G.AR_wing, W_TO), ...
    'referenceDesc', 'Brandt F-16A.xls Main, Geom and Wt tabs, via VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json, plus his own layout for the moment arms.', ...
    'secondDesc',    'T.O. 1F-16A-1 Fig. 1-2 for the rudder area only.');

meta.preamble = { ...
    ['**The three tiers are three coefficient sets, not three refinements.** L1 takes Raymer''s ' ...
     'jet-fighter row with his relaxed-static-stability and all-moving-tail corrections, on his ' ...
     'pre-layout arm. L2 takes Nicolai''s measured F-16 row on Nicolai''s own c.g.-referenced arm. ' ...
     'L3 has no sizer: its rows are the L1 method on the L3 layout, and the two N/A rows record the ' ...
     'stability-and-control equations this repository cannot cite.'], ...
    ['**The sized areas are written back into the L2 and L3 geometry objects.** Every planform, ' ...
     'wetted-area, control-surface and weight row therefore describes the sized tail, while the ' ...
     'Reference column stays at Brandt''s given 108/60 ft^2. Those rows carry the area difference ' ...
     'and the formula difference together. The arms above are the ones that produced these areas, ' ...
     'so they are one iteration behind the planform, exactly the lag SizingLoopL2 documents: a ' ...
     'larger tail lengthens its own arm, which shrinks the next area, so the lag is stable. The L3 ' ...
     'rows are also one iteration past the geometry cascade''s own tail, because that generator ' ...
     'already wrote a tail into the L3 geometry this file reads.'], ...
    ['**A volume-coefficient method is a historical average.** It is not expected to reproduce one ' ...
     'specific aircraft''s areas, and nothing here is tuned to close the gap to Brandt.'] };

% The tier rides in the Parameter label, so the Fidelity column is dropped and
% its width goes to the value cells.
T = removevars(T, 'Fidelity');

ComparisonReport.show(T, meta);

out_md = fullfile(fileparts(mfilename('fullpath')), 'mds', 'f16a_generate_tail_test.md');
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  Markdown -> %s\n\n', out_md);

% The tail sizers, the sized areas and the disciplines they were built on.
S = struct('L1', t1, 'L2', t2, 'S_ht', S_ht, 'S_vt', S_vt, 'W', W);

end

% ─── local helpers ──────────────────────────────────────────────────────── %

function T = cmp(name, unit, level, computed, reference, numfmt, cite, notes, divergence)
%CMP  One comparison row, with the tier and the unit folded into the Parameter
%   label. DIVERGENCE DEFAULTS TO 'BY DESIGN', because most rows put a Raymer or
%   Nicolai equation against Brandt's own model; the rows that are genuine
%   agreement checks pass '' explicitly.
    if nargin < 8; notes      = ''; end
    if nargin < 9; divergence = 'BY DESIGN'; end
    T = ComparisonReport.row(sprintf('%s [%s, %s]', name, level, unit), level, ...
        computed, reference, cite, numfmt, notes, NaN, divergence);
end

function gt = brandt_tail_reference()
%BRANDT_TAIL_REFERENCE  Every reference value in this report, from the one
%   ground-truth file. Brandt's tail weights are his own psf model x his own
%   areas, so they carry no W_TO dependency.
    sizing_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    d = jsondecode(fileread(fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json')));
    gt.S_ht_b   = d.tail_sizing.S_ht_ft2.value;                         % Brandt Main!C18
    gt.S_vt_b   = d.tail_sizing.S_vt_ft2.value;                         % Brandt Main!H18
    gt.ht       = d.geometry.lifting_surface_exposed_areas.pitch_control_HT;
    gt.vt       = d.geometry.lifting_surface_exposed_areas.vertical_tail;
    gt.ht_AR    = d.geometry.inputs_on_Main_tab.pitch_control_HT.AR;
    gt.vt_AR    = d.geometry.inputs_on_Main_tab.vertical_tail.AR;
    gt.ht_S_wet = d.geometry.lifting_surface_S_wet_ft2.pitch_control_HT.value;
    gt.vt_S_wet = d.geometry.lifting_surface_S_wet_ft2.vertical_tail.value;
    gt.W_HT_b   = d.weights.structural_components.pitch_control_HT.value;   % Brandt Wt!E9
    gt.W_VT_b   = d.weights.structural_components.vertical_tail.value;      % Brandt Wt!F9
end

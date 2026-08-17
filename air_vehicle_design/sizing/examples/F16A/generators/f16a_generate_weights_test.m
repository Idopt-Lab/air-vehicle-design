function [T, W] = f16a_generate_weights_test()
%F16A_GENERATE_WEIGHTS_TEST  F-16A weights at L1, L2 and L3.
%   The three weights tiers are built from the f16a_L{1,2,3}.json spec files, the
%   requirements file and the cascaded geometry / aerodynamics / propulsion that
%   f16a_generate_propulsion_test returns, then evaluated at that cascade's gross
%   weight. The rows follow BrandtWeight's own component list, and the Reference
%   column is a live BrandtWeight run at the same gross weight, so the comparison
%   is model against model. The tier rides in the row label, so the Fidelity
%   column is dropped. Informational only: this is not a test, and no value here
%   may backfill a unit test. The table prints to the console and is written as
%   mds/f16a_generate_weights_test.md.
%
%   SOURCES: [Brandt] F-16A.xls Wt tab, via VnV/BrandtF16A. [Raymer] Aircraft
%   Design 6th ed., Table 3.1, Table 15.2, Sec. 15.3.1 and Eq. 10.10. [Roskam]
%   Airplane Design Part I, Eq. 2.16. [Martins] AE481 course notes (metabook),
%   Sec. 7.

[~, P] = f16a_generate_propulsion_test();
G      = P.A.G;
req    = f16a_requirements_path();
W_TO   = G.W_TO;
brandt = brandt_weight_reference(W_TO);

w1 = F16WeightsL1(f16a_spec_path(1));
w2 = F16WeightsL2(f16a_spec_path(2), req, G.L2, P.L2);   % L3 injects F16PropL2 too
w3 = F16WeightsL3(f16a_spec_path(3), req, G.L3, P.L2);   % -- no L3 propulsion tier
w2.W_TO = W_TO;
w3.W_TO = W_TO;

% ── run every tier at the cascaded gross weight ────────────────────────── %
oew        = [w1.OEW(W_TO), w2.OEW(W_TO), w3.OEW(W_TO)];
oew_roskam = w1.compute_We_roskam(W_TO);    % [Roskam Eq. 2.16] MINIMUM bound

tail2 = w2.weight_tail(W_TO);
tail3 = w3.weight_tail(W_TO);
lg3   = w3.weight_landing_gear(W_TO);
eng3  = w3.weight_engine_section(W_TO);
sys3  = w3.weight_systems(W_TO);

wing2 = w2.weight_wing(W_TO);   fus2 = w2.weight_fuselage(W_TO);
wing3 = w3.weight_wing(W_TO);   fus3 = w3.weight_fuselage(W_TO);
str2  = wing2 + fus2 + tail2.HT + tail2.VT;
str3  = wing3 + fus3 + tail3.HT + tail3.VT;

% WeightsBase closure: W_TO = OEW + fuel + fixed payload + expendable payload.
payload = w1.W_payload_fixed + w1.W_payload_expendable;
fuel    = W_TO - payload - oew;

lvl = {'L1', 'L2', 'L3'};

% ── the table ──────────────────────────────────────────────────────────── %
T = ComparisonReport.section(sprintf('STRUCTURE -- Brandt Wt!C9:H9, his own psf model at W_TO = %g lbf', W_TO));
T = [T; cmp('Wing', 'lbf', lvl{2}, wing2, brandt.W_wing_lb, '%.2f', 'Brandt Wt!C9', ...
    'Raymer Table 15.2: 9.0 psf on the EXPOSED planform. Brandt uses 6.75 psf on S_ref with AR, n_ult, t/c and sweep factors.')];
T = [T; cmp('Wing', 'lbf', lvl{3}, wing3, brandt.W_wing_lb, '%.2f', 'Brandt Wt!C9', ...
    'Raymer Eq. 15.1. The fighter-wing regression does not capture the F-16''s unusually light wing.')];
T = [T; cmp('Fuselage', 'lbf', lvl{2}, fus2, brandt.W_fuse_lb, '%.2f', 'Brandt Wt!D9', ...
    'Raymer Table 15.2: 4.8 psf on the WETTED area. Brandt uses 5.0 psf on nearly the same area, so this row isolates the coefficient.')];
T = [T; cmp('Fuselage', 'lbf', lvl{3}, fus3, brandt.W_fuse_lb, '%.2f', 'Brandt Wt!D9', ...
    'Raymer Eq. 15.4 on the cascaded length and the maximum structural DEPTH, not the equivalent diameter.')];
T = [T; cmp('Pitch control / HT', 'lbf', lvl{2}, tail2.HT, brandt.W_pitch_lb, '%.2f', 'Brandt Wt!E9', ...
    'DIFFERENT AREA CONVENTION: Raymer Table 15.2 takes the EXPOSED planform, Brandt Wt!E9 the FULL 108 ft^2.', 'DEFINITIONAL')];
T = [T; cmp('Pitch control / HT', 'lbf', lvl{3}, tail3.HT, brandt.W_pitch_lb, '%.2f', 'Brandt Wt!E9', ...
    'Raymer Eq. 15.2, same EXPOSED-vs-FULL split as the L2 row.', 'DEFINITIONAL')];
T = [T; cmp('Vertical tail', 'lbf', lvl{2}, tail2.VT, brandt.W_vert_lb, '%.2f', 'Brandt Wt!F9', ...
    'Raymer Table 15.2: 5.3 psf on the EXPOSED planform against Brandt''s 6.0 psf on the FULL 60 ft^2.', 'DEFINITIONAL')];
T = [T; cmp('Vertical tail', 'lbf', lvl{3}, tail3.VT, brandt.W_vert_lb, '%.2f', 'Brandt Wt!F9', ...
    'Raymer Eq. 15.3 on the EXPOSED planform SET -- area, aspect ratio and taper all exposed.', 'DEFINITIONAL')];
T = [T; cmp('Nacelles', 'lbf', '', NaN, brandt.W_nacelles_lb, '%.2f', 'Brandt Wt!G9', ...
    'No framework nacelle-weight component exists at any tier.', 'DEFINITIONAL')];
T = [T; cmp('Strakes', 'lbf', lvl{2}, w2.W_strake, brandt.W_strakes_lb, '%.2f', 'Brandt Wt!H9', ...
    'EXACT BY CONSTRUCTION: Raymer has no strake category, so both tiers borrow Brandt''s own 4.5 psf x 20 ft^2.', '')];
T = [T; cmp('Strakes', 'lbf', lvl{3}, w3.W_strake, brandt.W_strakes_lb, '%.2f', 'Brandt Wt!H9', ...
    'Same borrowed coefficient and area as the L2 row.', '')];
T = [T; cmp('Structure total', 'lbf', lvl{2}, str2, brandt.W_structure_lb, '%.2f', 'Brandt Wt!B9', ...
    'NOT like-for-like: Brandt''s sum also carries nacelles and strakes, and two of its four shared items use FULL tail areas.', 'DEFINITIONAL')];
T = [T; cmp('Structure total', 'lbf', lvl{3}, str3, brandt.W_structure_lb, '%.2f', 'Brandt Wt!B9', ...
    'Same non-like-for-like sum over the Sec. 15.3.1 components.', 'DEFINITIONAL')];

T = [T; ComparisonReport.section('ENGINE -- Brandt Wt!B11/B22 = 0.199*T_AB_SLS, which is ALREADY an installed weight')];
T = [T; cmp('Engine, installed', 'lbf', lvl{2}, w2.W_installed_engine, brandt.W_engine_lb, '%.2f', 'Brandt Wt!B11', ...
    'Raymer Eq. 10.10 x 1.3 [metabook Sec. 7]. The x1.3 is L2-only: L2 carries no installation buildup, so one lumped factor is right there and only there.')];
T = [T; cmp('Engine group', 'lbf', lvl{3}, eng3.total, brandt.W_engine_lb, '%.2f', 'Brandt Wt!B11', ...
    'The whole propulsion group built item by item (dry engine + Eqs. 15.7-15.15), against Brandt''s single line. He books the duct separately at B24.', 'DEFINITIONAL')];
T = [T; cmp('Engine, uninstalled', 'lbf', lvl{3}, w3.W_en, brandt.W_engine_lb, '%.2f', 'Brandt Wt!B11', ...
    'Raymer Eq. 10.10 alone, the dry weight L3 consumes. A different KIND of quantity from an installed weight.', 'DEFINITIONAL')];
T = [T; cmp('Inlet duct', 'lbf', lvl{3}, eng3.induction, brandt.W_inlet_duct_lb, '%.2f', 'Brandt Wt!B24', ...
    'Raymer Eq. 15.10 on duct geometry against Brandt''s 3.9 x nacelle weight, a basis the framework does not have.')];

T = [T; ComparisonReport.section('SYSTEMS -- Brandt Wt!B23:B31, his own W_TO fractions')];
T = [T; cmp('Landing gear', 'lbf', lvl{2}, w2.weight_landing_gear(W_TO), brandt.W_gear_lb, '%.2f', 'Brandt Wt!B23', ...
    'SAME MODEL FAMILY, different coefficient: 0.033*W_TO [metabook Sec. 7] against Brandt''s 0.034*W_TO.')];
T = [T; cmp('Landing gear', 'lbf', lvl{3}, lg3.main + lg3.nose, brandt.W_gear_lb, '%.2f', 'Brandt Wt!B23', ...
    'Raymer Eqs. 15.5 + 15.6 strut sizing on W_l = 0.95*W_TO. Brandt carries one gear line, so only this total compares.')];
T = [T; cmp('Flight controls', 'lbf', lvl{3}, sys3.flight_ctrl, brandt.W_ctrl_lb, '%.2f', 'Brandt Wt!B25', ...
    'Raymer Eq. 15.17 on Mach, control-surface area and counts, against 0.012*W_TO plus a LE-flap area term.')];
T = [T; cmp('Electrical', 'lbf', lvl{3}, sys3.electrical, brandt.W_elec_lb, '%.2f', 'Brandt Wt!B26', ...
    'Raymer Eq. 15.20 on R_kva and lead length, both unpinned estimates, against 0.017*W_TO.')];
T = [T; cmp('Hydraulics', 'lbf', lvl{3}, sys3.hydraulics, brandt.W_hyd_lb, '%.2f', 'Brandt Wt!B27', ...
    'Raymer Eq. 15.19 on the utility-function count, an unpinned estimate the equation is sensitive to, against 0.0117*W_TO.')];
T = [T; cmp('ECS / AC + anti-ice', 'lbf', lvl{3}, sys3.ac_antiice, brandt.W_ECS_lb, '%.2f', 'Brandt Wt!B28', ...
    'Raymer Eq. 15.23 on the avionics weight and crew count, against 0.0115*W_TO.')];
T = [T; cmp('Avionics', 'lbf', lvl{3}, sys3.avionics, brandt.W_avionics_lb, '%.2f', 'Brandt Wt!B30', ...
    'Raymer Eq. 15.21 on the uninstalled avionics weight, its only input and an unpinned estimate.')];
T = [T; cmp('Other structure', 'lbf', '', NaN, brandt.W_other_lb, '%.2f', 'Brandt Wt!B29', ...
    'A lumped 0.30 x structure catch-all with no single framework analog.', 'DEFINITIONAL')];
T = [T; cmp('Armament support', 'lbf', '', NaN, brandt.W_armament_lb, '%.2f', 'Brandt Wt!B31', ...
    'No framework analog. Brandt: 0.10 x expendable payload.', 'DEFINITIONAL')];
T = [T; cmp('All-else-empty', 'lbf', lvl{2}, w2.W_all_else_empty, NaN, '%.2f', '-', ...
    'L2''s catch-all, 0.17*W_TO. Brandt books this content as eight separate lines, so no single cell compares; the L3 systems group is the like-for-like target.', 'DEFINITIONAL')];
T = [T; cmp('Systems group total', 'lbf', lvl{3}, sys3.total, NaN, '%.2f', '-', ...
    'The L3 counterpart of the all-else-empty row: nine equations instead of one fraction.', 'DEFINITIONAL')];

T = [T; ComparisonReport.section('WEIGHT STATEMENT -- Brandt Wt!B4:B6, B10 and B12')];
T = [T; cmp('Payload, fixed', 'lbf', '', w1.W_payload_fixed, brandt.perm_payload_lb, '%.2f', 'Brandt Wt!B4', ...
    'Spec data echoed on both sides, so this must match.', '')];
T = [T; cmp('Payload, expendable', 'lbf', '', w1.W_payload_expendable, brandt.exp_payload_lb, '%.2f', 'Brandt Wt!B5', ...
    'Spec data echoed on both sides, so this must match.', '')];
T = [T; cmp('Airframe', 'lbf', lvl{2}, oew(2) - w2.W_installed_engine, brandt.W_airframe_lb, '%.2f', 'Brandt Wt!B10', ...
    'OEW less the installed engine. Brandt excludes only his single engine line.', 'DEFINITIONAL')];
T = [T; cmp('Airframe', 'lbf', lvl{3}, oew(3) - eng3.total, brandt.W_airframe_lb, '%.2f', 'Brandt Wt!B10', ...
    'OEW less the whole engine GROUP, which also holds installation hardware Brandt books elsewhere.', 'DEFINITIONAL')];
T = [T; cmp('OEW', 'lbf', lvl{1}, oew(1), brandt.W_empty_lb, '%.2f', 'Brandt Wt!B12', ...
    'Raymer Table 3.1 empty-weight power law, a CENTRAL regression through historical fighters.')];
T = [T; cmp('OEW, Roskam minimum', 'lbf', lvl{1}, oew_roskam, brandt.W_empty_lb, '%.2f', 'Brandt Wt!B12', ...
    'A LOWER BOUND, never summed into OEW. A negative %Diff is the correct result and its size is not an error measure.', 'DEFINITIONAL')];
T = [T; cmp('OEW', 'lbf', lvl{2}, oew(2), brandt.W_empty_lb, '%.2f', 'Brandt Wt!B12', ...
    'Table 15.2 psf buildup + metabook Sec. 7 fractions + the strake term.')];
T = [T; cmp('OEW', 'lbf', lvl{3}, oew(3), brandt.W_empty_lb, '%.2f', 'Brandt Wt!B12', ...
    'Raymer Sec. 15.3.1 component buildup + the strake term. Nacelles, other structure and armament support are unmodeled at every tier.')];
T = [T; cmp('We/W_TO', '-', lvl{1}, w1.compute_We_fraction(W_TO), brandt.W_empty_lb/W_TO, '%.4f', 'Brandt Wt!B12/B3', ...
    'What L1 actually estimates: the power law returns a fraction, and the OEW row above is that fraction times W_TO.')];
T = [T; cmp('Fuel', 'lbf', lvl{1}, fuel(1), brandt.W_fuel_lb, '%.2f', 'Brandt Wt!B6', ...
    'The WeightsBase closure W_TO - payload - OEW, so it carries the whole OEW error with the opposite sign.')];
T = [T; cmp('Fuel', 'lbf', lvl{2}, fuel(2), brandt.W_fuel_lb, '%.2f', 'Brandt Wt!B6', ...
    'Same closure on the L2 OEW.')];
T = [T; cmp('Fuel', 'lbf', lvl{3}, fuel(3), brandt.W_fuel_lb, '%.2f', 'Brandt Wt!B6', ...
    'Same closure on the L3 OEW.')];
T = [T; cmp('W_TO', 'lbf', '', W_TO, brandt.W_TO_lb, '%.2f', 'Brandt Wt!B3', ...
    'The cascade''s gross weight, fed to both sides, so this must match.', '')];

meta = struct( ...
    'title',         'F-16A -- Weights from the JSON Inputs and the Cascaded Geometry, Aerodynamics and Propulsion', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('W_TO = %g lbf, the gross weight the geometry cascade was built on.', W_TO), ...
    'referenceDesc', 'the live BrandtWeight model (VnV/BrandtF16A), run at the same gross weight as the framework.', ...
    'secondDesc',    'N/A -- this report has one reference source.');

meta.preamble = { ...
    ['**The three tiers are different MODELS, not refinements of one model.** L1 is a statistical ' ...
     'empty-weight power law, L2 is surface density x area plus fractions, L3 is the Raymer ' ...
     'Sec. 15.3.1 component buildup. Agreement between the tiers is not a goal.'], ...
    ['**Part of the OEW gap is a missing component, not an error.** Brandt books nacelles, ' ...
     '"other structure" and armament support as lines this framework has no component for at any ' ...
     'tier. Their rows carry Computed = N/A -- subtract them before reading the OEW rows.'], ...
    ['**Read the Notes column before treating a %Diff as an error.** Most rows put a Raymer or ' ...
     'metabook equation against Brandt''s own psf/fraction model, and several compare an EXPOSED ' ...
     'planform against his FULL one.'] };

% The tier rides in the Parameter label, so the Fidelity column is dropped and
% its width goes to the value cells.
T = removevars(T, 'Fidelity');

ComparisonReport.show(T, meta);

out_md = fullfile(fileparts(mfilename('fullpath')), 'mds', 'f16a_generate_weights_test.md');
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  Markdown -> %s\n\n', out_md);

% The three weights objects and the disciplines they were built on. The table
% rides along as W.T, for fidelity_comparison.
W = struct('L1', w1, 'L2', w2, 'L3', w3, 'P', P, 'T', T);

end

% ─── local helpers ──────────────────────────────────────────────────────── %

function T = cmp(name, unit, level, computed, reference, numfmt, cite, notes, divergence)
%CMP  One comparison row, with the tier and the unit folded into the Parameter
%   label. DIVERGENCE DEFAULTS TO 'BY DESIGN', because most rows put a Raymer or
%   metabook equation against Brandt's own model; the rows that are genuine
%   agreement checks pass '' explicitly.
    if nargin < 8; notes      = ''; end
    if nargin < 9; divergence = 'BY DESIGN'; end
    if isempty(level)
        label    = sprintf('%s [%s]', name, unit);
        fidelity = 'N/A';
    else
        label    = sprintf('%s [%s, %s]', name, level, unit);
        fidelity = level;
    end
    T = ComparisonReport.row(label, fidelity, computed, reference, cite, numfmt, notes, NaN, divergence);
end

function r = brandt_weight_reference(W_TO)
%BRANDT_WEIGHT_REFERENCE  The live Brandt Wt model at this gross weight, which
%   supplies every reference value here. Self-contained path add, same as
%   fidelity_comparison.
    if isempty(which('BrandtWeight'))
        sizing_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        vnv = fullfile(sizing_root, 'VnV', 'BrandtF16A');
        addpath(vnv);
        addpath(fullfile(vnv, 'GroundTruth'));
    end
    geom = BrandtGeometry();  geom.analyze();
    wt   = BrandtWeight(geom); wt.analyze();
    r    = wt.run(W_TO);
end

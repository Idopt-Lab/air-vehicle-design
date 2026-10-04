function T_all = sandc_brandt_comparison()
%SANDC_BRANDT_COMPARISON  F-16A stability and control vs Brandt 'S&C (2)'.
%   Informational report, not a test. Do not use its values as unit-test
%   expected values.
%
%   Run at Brandt's W_TO and W_energy (Wt!B3, Wt!B6).
%
%   Brandt calculates CL_alpha and x_np with Roskam Eqns 3.24/3.38. This
%   framework uses Raymer Ch. 16. The Roskam book is not in this repo, so
%   x_np and SM do not agree. This is not a bug.
%
%   Output: ../output/sandc_brandt_comparison.{json,md}

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(fileparts(script_dir)));
gt_dir      = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth');
gt          = jsondecode(fileread(fullfile(gt_dir, 'f16a_stability_control_ground_truth.json'))).stability_control;
gt_weights  = jsondecode(fileread(fullfile(gt_dir, 'f16a_ground_truth.json'))).weights;

W_TO_brandt   = gt_weights.summary.TOGW.value;
W_fuel_brandt = gt_weights.summary.fuel.value;

prop = F16PropL2(f16a_spec_path(2));

% L2: CG only
g2 = F16GeomL2(f16a_spec_path(2), prop);
w2 = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
w2.W_TO     = W_TO_brandt;
w2.W_energy = W_fuel_brandt;
s2 = F16SandCL2(f16a_spec_path(2), w2);

% L3: full Ch. 16 buildup (no L3 propulsion, F16PropL2 is used)
g3 = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
w3 = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
w3.W_TO     = W_TO_brandt;
w3.W_energy = W_fuel_brandt;
a3 = F16AeroL3(g3, f16a_spec_path(3));
ctrl3 = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);
s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl3);

SRC = 'Brandt S&C (2)';

T = table();

T = [T; srow('[CG]')];
T = [T; grow('x_cg [ft]', 'L2', s2.x_cg, gt.cg_takeoff.x_cg_TO_ft, [SRC ' row 36'], '%.4f', ...
    'Different component x-station table from Brandt.', gt.cg_landing.x_cg_land_ft, 'BY DESIGN')];
T = [T; grow('x_cg [ft]', 'L3', s3.x_cg, gt.cg_takeoff.x_cg_TO_ft, [SRC ' row 36'], '%.4f', ...
    'Same table as L2.', gt.cg_landing.x_cg_land_ft, 'BY DESIGN')];

T = [T; srow('[AERODYNAMIC CENTERS]')];
T = [T; grow('x_acw [ft]', 'L3', s3.x_acw, gt.aero_center.xacW_ft, [SRC ' row 16'], '%.4f', ...
    'Includes Raymer Eq. 16.12 Mach shift at M=0.87. Brandt does not.', NaN, 'BY DESIGN')];
T = [T; grow('x_ach [ft]', 'L3', s3.x_ach, gt.aero_center.xacHS_ft, [SRC ' row 16'], '%.4f', ...
    'Quarter-MAC, no Mach shift.', NaN, 'BY DESIGN')];

T = [T; srow('[LIFT-CURVE SLOPES]')];
T = [T; grow('CL_alpha wing [1/rad]', 'L3', s3.CL_alpha_wing, gt.CLa_per_surface.CLaW_per_rad, [SRC ' row 24'], '%.4f', ...
    'Raymer Eq. 12.6 vs Roskam Eq. 3.24. Main cause of the x_np difference.', NaN, 'BY DESIGN')];
T = [T; grow('CL_alpha HT [1/rad]', 'L3', s3.CL_alpha_tail, gt.CLa_per_surface.CLaHS_per_rad, [SRC ' row 24'], '%.4f', ...
    'Raymer Eq. 12.6 with HT geometry.', NaN, 'BY DESIGN')];
T = [T; grow('CL_alpha aircraft [1/rad]', 'N/A', NaN, gt.CLa_aircraft.value_per_rad, [SRC ' row 32'], '%.4f', ...
    'Not modeled.')];

T = [T; srow('[NEUTRAL POINT AND STATIC MARGIN]')];
T = [T; grow('x_np [ft]', 'L3', s3.x_np, gt.neutral_point.x_np_ft, [SRC ' row 33'], '%.4f', ...
    'Raymer Eq. 16.9 vs Roskam Eq. 3.38.', NaN, 'BY DESIGN')];
T = [T; grow('SM, vs Brandt takeoff', 'L3', s3.SM, gt.cg_takeoff.SM, [SRC ' row 37'], '%.5f', ...
    'Caused by the x_np and x_cg differences. %Diff is not useful near zero.', NaN, 'BY DESIGN')];
T = [T; grow('SM, vs Brandt landing', 'L3', s3.SM, gt.cg_landing.SM_land, [SRC ' row 35'], '%.5f', ...
    'One framework SM, compared to both Brandt cases.', NaN, 'BY DESIGN')];

meta = struct( ...
    'title',         'F-16A Block 10/15 - Stability & Control vs Brandt', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('W_TO = %.0f lbf, W_energy = %.0f lbf, M = 0.87.', W_TO_brandt, W_fuel_brandt), ...
    'referenceDesc', 'Brandt-F16-A.xls, sheet S&C (2), takeoff loading.', ...
    'secondDesc',    'Brandt-F16-A.xls, sheet S&C (2), landing-loading x_cg (row 34).');

meta.preamble = {['Brandt uses Roskam (not in this repo). This framework uses Raymer Ch. 16. ' ...
                  'x_np and SM differences are expected. No input is adjusted to match Brandt.']};

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, '..', 'output', 'sandc_brandt_comparison.json');
out_md   = fullfile(script_dir, '..', 'output', 'sandc_brandt_comparison.md');
ComparisonReport.writeJson(T, out_json, meta);
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  JSON     -> %s\n', out_json);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

function T = grow(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence)
%GROW  One comparison row. See ComparisonReport.row.
    if nargin < 7; notes      = ''; end
    if nargin < 8; second     = NaN; end
    if nargin < 9; divergence = ''; end
    T = ComparisonReport.row(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence);
end

function T = srow(label)
%SROW  Section separator row.
    T = ComparisonReport.section(label);
end

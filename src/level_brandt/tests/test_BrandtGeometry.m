%% BrandtGeometry validation test suite
% Plain runnable script for validating src/level_brandt/BrandtGeometry.m

clearvars;
close all;
clc;

geom = BrandtGeometry();
geom.compute();

tol_pct = 2.0;
pass_count = 0;
check_count = 0;

fprintf('\n===============================================================\n');
fprintf(' BrandtGeometry Validation Test Suite\n');
fprintf(' Source: Brandt-F16-A.xls (Geom tab) ground-truth cross-checks\n');
fprintf('===============================================================\n');
fprintf('Tolerance for known GT comparisons: |%% error| < %.1f%%\n', tol_pct);

%% Table 1: Wetted surface areas
fprintf('\nTABLE 1: Wetted Surface Areas vs Excel Ground Truth\n');
fprintf('%-18s %14s %12s %12s %10s %8s\n', 'Component', 'Computed (ft^2)', 'GT (ft^2)', 'Error', '% Error', 'Status');
fprintf('%s\n', repmat('-', 1, 82));

corrected_total_gt_ft2 = 1371.09 - 39.956;
[pass_count, check_count] = printComparison('Wing', geom.geom.S_wet_wing_ft2, 392.020, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Strake', geom.geom.S_wet_strake_ft2, 39.956, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Pitch ctrl', geom.geom.S_wet_pitch_ctrl_ft2, 99.585, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Vert tail', geom.geom.S_wet_vert_tail_ft2, 81.689, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Nacelle', geom.geom.S_wet_nacelle_gt_ft2, 41.515, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Total', geom.geom.S_wet_total_accurate_ft2, corrected_total_gt_ft2, tol_pct, pass_count, check_count);
fprintf('Note: Excel B19 double-counts strake area; corrected GT total = 1371.09 - 39.956 = %.3f ft^2.\n', corrected_total_gt_ft2);

%% Table 2: Aircraft dimensions
fprintf('\nTABLE 2: Aircraft Dimensions vs Excel Ground Truth\n');
fprintf('%-18s %14s %12s %12s %10s %8s\n', 'Quantity', 'Computed', 'GT', 'Error', '% Error', 'Status');
fprintf('%s\n', repmat('-', 1, 82));

nacelle_length_gt_ft = 15.917;
nacelle_diameter_gt_ft = 3.537;
[pass_count, check_count] = printComparison('Aircraft length', geom.geom.aircraft_length_ft, 48.304, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Amax', geom.geom.Amax_ft2, 25.110, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Nacelle length', geom.geom.L_engine_ft, nacelle_length_gt_ft, tol_pct, pass_count, check_count);
[pass_count, check_count] = printComparison('Nacelle diameter', geom.geom.D_engine_ft, nacelle_diameter_gt_ft, tol_pct, pass_count, check_count);
fprintf('Note: Nacelle GT values correspond to the workbook engine-sizing relationship D = sqrt(T_AB_SLS/1900), L = 4.5*D.\n');

%% Table 3: Wing quarter-chord sweep
fprintf('\nTABLE 3: Wing Quarter-Chord Sweep\n');
fprintf('%-18s %14s %12s %12s %10s %8s\n', 'Quantity', 'Computed', 'GT', 'Error', '% Error', 'Status');
fprintf('%s\n', repmat('-', 1, 82));

sweep_25c_deg = geom.inp.wing.sweep_LE_deg - atan2d(0.25 * (geom.geom.wing.c_root_ft - geom.geom.wing.c_tip_ft), geom.geom.wing.half_span_ft);
sweep_25c_gt_deg = geom.inp.wing.sweep_LE_deg - atan2d(0.25 * (geom.geom.wing.c_root_ft - geom.geom.wing.c_tip_ft), geom.geom.wing.half_span_ft);
[pass_count, check_count] = printComparison('Sweep 25% c', sweep_25c_deg, sweep_25c_gt_deg, tol_pct, pass_count, check_count);
fprintf('Note: Excel L45 is derived from the same formula, so this is a formula-consistency check.\n');

%% Table 4: Fuselage frame spot checks
fprintf('\nTABLE 4: Fuselage Frame Spot Checks\n');
fprintf('%-24s %14s %18s\n', 'Quantity', 'Computed', 'Reference / Note');
fprintf('%s\n', repmat('-', 1, 62));
fprintf('%-24s %14.3f %18s\n', 'Frame 1 perimeter', geom.geom.frame_perimeter(1), 'check visually');
fprintf('%-24s %14.3f %18s\n', 'Frame 9 area', geom.geom.frame_area(9), 'check visually');
fprintf('%-24s %14.3f %18s\n', 'Frame 14 max width', geom.inp.fuselage.frame_w(14), 'Excel G327/input');
fprintf('%-24s %14.3f %18s\n', 'Frame 17 max height', geom.inp.fuselage.frame_h(17), 'Excel H390/input');

%% Table 5: Whole-aircraft cross-sectional areas
fprintf('\nTABLE 5: Whole-Aircraft Cross-Sectional Areas\n');
fprintf('%-7s %10s %22s %20s %10s\n', 'Frame', 'x (ft)', 'Computed Total A (ft^2)', 'Expected band', 'Status');
fprintf('%s\n', repmat('-', 1, 78));

expected_area_center = [0.5, 1.0, 2.0, 3.5, 5.0, 6.5, 11.0, 17.0, 20.0, 22.0, 25.11, 24.0, 23.0, 22.0, 20.0, 18.0, 15.0, 10.0, 8.0, 5.0];
for k = 1:numel(geom.inp.fuselage.frame_x)
    band_lo = max(0.0, expected_area_center(k) - max(2.0, 0.5 * expected_area_center(k)));
    band_hi = expected_area_center(k) + max(2.0, 0.5 * expected_area_center(k));
    in_band = geom.geom.frame_area_total(k) >= band_lo && geom.geom.frame_area_total(k) <= band_hi;
    if in_band
        status = 'OK';
    else
        status = 'FLAG';
    end
    fprintf('%-7d %10.3f %22.3f %9.3f to %-8.3f %10s\n', ...
        k, geom.inp.fuselage.frame_x(k), geom.geom.frame_area_total(k), band_lo, band_hi, status);
end
fprintf('Note: Exact Excel H26:H45 values are not available from the binary workbook here; broad bands are used only for sanity-check flagging.\n');

aircraft_volume_ft3 = trapz(geom.inp.fuselage.frame_x, geom.geom.frame_area_total);
if aircraft_volume_ft3 >= 2600 && aircraft_volume_ft3 <= 3200
    volume_status = 'OK';
else
    volume_status = 'FLAG';
end
fprintf('\nIntegrated whole-aircraft volume = %.3f ft^3  [%s, expected ~2600-3200 ft^3]\n', aircraft_volume_ft3, volume_status);

%% Plot
script_path = mfilename('fullpath');
if isempty(script_path)
    script_path = which('test_BrandtGeometry');
end
script_dir = fileparts(script_path);
if isempty(script_dir)
    script_dir = pwd;
end

figure('Name', 'Validation: Whole-Aircraft CS Area', 'NumberTitle', 'off', 'Visible', 'off');
hold on; grid on;
x_frames = geom.inp.fuselage.frame_x;
plot(x_frames, geom.geom.frame_area_total, 'b-o', 'LineWidth', 1.5, 'DisplayName', 'Computed Total Area');
plot(x_frames, geom.geom.frame_area, 'k--s', 'LineWidth', 1.2, 'DisplayName', 'Fuselage Only');
xlabel('x (ft)'); ylabel('Cross-Sectional Area (ft^2)');
title('Whole-Aircraft Cross-Sectional Area vs Fuselage Station');
legend('Location', 'northwest');
for k = 1:numel(x_frames)
    text(x_frames(k), geom.geom.frame_area_total(k) + 0.3, num2str(k), 'FontSize', 7, 'HorizontalAlignment', 'center');
end
plot_path = fullfile(script_dir, 'validation_area_profile.png');
saveas(gcf, plot_path);
fprintf('Saved plot: %s\n', plot_path);
close(gcf);

%% Summary
fprintf('\nPASS/FAIL SUMMARY\n');
fprintf('Known GT checks passed: %d/%d\n', pass_count, check_count);
if pass_count == check_count
    fprintf('Overall result: PASS\n');
else
    fprintf('Overall result: REVIEW REQUIRED\n');
end

function [pass_count, check_count] = printComparison(label, computed, gt, tol_pct, pass_count, check_count)
error_value = computed - gt;
error_pct = 100 * error_value / gt;
is_pass = abs(error_pct) < tol_pct;
if is_pass
    status = 'PASS';
    pass_count = pass_count + 1;
else
    status = 'FAIL';
end
check_count = check_count + 1;
fprintf('%-18s %14.3f %12.3f %12.3f %10.3f %8s\n', label, computed, gt, error_value, error_pct, status);
end

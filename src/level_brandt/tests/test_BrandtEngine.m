%% BrandtEngine validation script — theta/delta model
% Replicates Engn(s) tab with standard atmosphere ratios (theta, theta0, delta, delta0).
% NOTE: Full matlab.unittest conversion is deferred until propulsion unit tests are written.
%
% Run from repo root or any path containing the level_brandt sources:
%   run('src/level_brandt/tests/test_BrandtEngine.m')

clearvars; close all; clc;

eng = BrandtEngine();
eng.compute();

tol_pct    = 1.0;
pass_count = 0;
chk_count  = 0;

fprintf('\n===================================================\n');
fprintf(' BrandtEngine Validation — theta/delta model\n');
fprintf(' Source: Brandt-F16-A.xls Engn(s) tab\n');
fprintf('===================================================\n');
fprintf('Tolerance: |%% error| < %.1f%%\n\n', tol_pct);

%% TABLE 1: SLS parameters (read from JSON — exact match expected)
fprintf('TABLE 1: SLS Engine Parameters\n');
fprintf('%-26s  %12s  %10s  %6s\n', 'Parameter', 'Computed', 'GT', 'Status');
fprintf('%s\n', repmat('-', 1, 60));
[pass_count, chk_count] = pct('T_sl_dry  (lbf)',     eng.T_sl_dry,    15000.0, tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('T_sl_AB   (lbf)',     eng.T_sl_AB,     23770.0, tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('TSFC_sl_dry (1/hr)',  eng.TSFC_sl_dry, 0.70,    tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('TSFC_sl_AB  (1/hr)',  eng.TSFC_sl_AB,  2.20,    tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('TR',                  eng.TR,          1.0,     tol_pct, pass_count, chk_count);

%% TABLE 2: SLS thrust recovery  (h=0 ft, M=0  →  alpha=1  →  T=T_sl)
fprintf('\nTABLE 2: SLS Thrust Recovery  (h=0 ft, M=0)\n');
fprintf('%-26s  %12s  %10s  %6s\n', 'Parameter', 'Computed', 'GT', 'Status');
fprintf('%s\n', repmat('-', 1, 60));
[T_dry_SLS,  tsfc_dry_SLS] = eng.thrust_dry(0, 0);
[T_AB_SLS,   ~           ] = eng.thrust_AB(0, 0);
[pass_count, chk_count] = pct('T_dry at SLS, M=0',      T_dry_SLS,    15000.0, tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('T_AB  at SLS, M=0',      T_AB_SLS,     23770.0, tol_pct, pass_count, chk_count);
[pass_count, chk_count] = pct('tsfc_dry at SLS, M=0',   tsfc_dry_SLS, 0.70,    tol_pct, pass_count, chk_count);

%% TABLE 3: Reference condition (40k ft, M=0.87) — informational only
%   GT values are model-derived (no direct Excel cell for these quantities
%   under the theta/delta model); run the code and inspect to update readme.
fprintf('\nTABLE 3: Reference Condition  (40,000 ft, M = 0.87)  [informational]\n');
alt_ref = 40000;   M_ref = 0.87;
[~, theta0_ref, ~, delta0_ref] = BrandtEngine.atmosphereRatios(alt_ref, M_ref);
[T_dry_ref,  tsfc_dry_ref] = eng.thrust_dry(alt_ref, M_ref);
[T_AB_ref,   tsfc_AB_ref ] = eng.thrust_AB(alt_ref,  M_ref);
fprintf('  theta0          = %.5f\n', theta0_ref);
fprintf('  delta0          = %.5f\n', delta0_ref);
fprintf('  T_dry           = %.1f lbf\n',  T_dry_ref);
fprintf('  tsfc_dry        = %.4f 1/hr\n', tsfc_dry_ref);
fprintf('  T_AB            = %.1f lbf\n',  T_AB_ref);
fprintf('  tsfc_AB         = %.4f 1/hr\n', tsfc_AB_ref);

%% TABLE 4: Physical sanity checks
fprintf('\nTABLE 4: Physical Sanity\n');
fprintf('%-40s  %16s  %6s\n', 'Check', 'Result', 'Status');
fprintf('%s\n', repmat('-', 1, 66));

[T_sl,  ~] = eng.thrust_dry(0,     0.5);
[T_20k, ~] = eng.thrust_dry(20000, 0.5);
[T_40k, ~] = eng.thrust_dry(40000, 0.5);
chk('T_dry decreases with altitude', T_sl > T_20k && T_20k > T_40k, ...
    sprintf('%.0f > %.0f > %.0f lbf', T_sl, T_20k, T_40k));

[T_lo, ~] = eng.thrust_dry(20000, 0.2);
[T_hi, ~] = eng.thrust_dry(20000, 1.0);
chk('T_dry decreases with Mach (20k ft)', T_lo > T_hi, ...
    sprintf('%.0f > %.0f lbf', T_lo, T_hi));

[T_AB_chk,  ~] = eng.thrust_AB(30000, 0.8);
[T_dry_chk, ~] = eng.thrust_dry(30000, 0.8);
chk('T_AB > T_dry at (30k ft, M=0.8)', T_AB_chk > T_dry_chk, ...
    sprintf('%.0f > %.0f lbf', T_AB_chk, T_dry_chk));

%% Summary
fprintf('\nPASS / FAIL: %d / %d\n', pass_count, chk_count);
if pass_count == chk_count
    fprintf('Result: PASS\n\n');
else
    fprintf('Result: REVIEW REQUIRED\n\n');
end

%% Helpers

function [pc, cc] = pct(label, computed, gt, tol, pc, cc)
    err = 100 * (computed - gt) / gt;
    ok  = abs(err) < tol;
    if ok, stat = 'PASS'; pc = pc + 1; else, stat = 'FAIL'; end
    cc = cc + 1;
    fprintf('%-26s  %12.6g  %10.6g  %6s\n', label, computed, gt, stat);
end

function chk(label, cond, detail)
    if cond, stat = 'PASS'; else, stat = 'FAIL'; end
    fprintf('%-40s  %16s  %6s\n', label, detail, stat);
end

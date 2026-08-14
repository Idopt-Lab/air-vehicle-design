function results = f16_sizing_attribution()
%F16_SIZING_ATTRIBUTION  Which discipline model drives each framework sizing
%   rung's W_TO gap vs Brandt? Informational report (never pass/fail) --
%   user-requested deliverable (2026-08-13 plan review: "If there is
%   discrepancy, analyze and tell me what's causing it (aero model? prop
%   model? geom model? weight model?)").
%
%   METHOD. Cross-stack discipline swapping inside a full sizing run does
%   not type-check cleanly (framework Tier-3 constructors validate concrete
%   model classes), so the attribution evaluates each discipline FAMILY at
%   the COMMON BRANDT POINT -- W_TO = 31,377 lbf, S_ref = 300 ft^2,
%   T_SL = 23,770 lbf [Brandt Wt!B3, Main!B18, engine T_AB_SLS_lb] -- where
%   every stack sees identical inputs:
%     (1) WEIGHTS:  OEW(31,377) per weights model vs Brandt's 19,980.70
%                   [Wt!B12]. Delta enters the closure as d_ef = dOEW/W_TO.
%     (2) MISSION FUEL (aero x prop): MissionAnalysisL2 x "cap" fuel at
%                   31,377 for the four aero/prop pairings Brandt/framework
%                   -- the mixed pairs split the fuel gap into its aero and
%                   prop shares. Delta enters as d_ff = dW_fuel/W_TO.
%     (3) DESIGN POINT (aero x prop): the constraint envelope argmin
%                   (grid optimal_point, fmincon-free) for the same four
%                   pairings -- T/W shifts size the engine weight through
%                   T_SL = TW*W_TO.
%   Each family delta is pushed through the first-order closure sensitivity
%       dW0/W0 ~= (d_ff + d_ef) / denom_eff,   denom_eff ~= 0.35
%   (denom = Wp/W_TO = 0.1625 at the Brandt point, widened by the OEW slope
%   dOEW/dW0 ~= 0.32 -- same derivation as TestSizingVsBrandt's header).
%   First-order only: the full nonlinear closure compounds these, so the
%   estimates bracket, not reproduce, the converged rung gaps.
%
%   Output: console table + f16_sizing_attribution.json in output/.

    here = fileparts(mfilename('fullpath'));
    outdir = fullfile(fileparts(here), 'output');

    W_ref = 31377; S_ref = 300; T_ref = 23770;   % the common Brandt point
    req = f16a_requirements_path();
    WS_sweep = linspace(20, 160, 1401);
    map = F16ConstraintSet.constraint_map();

    % ---- Brandt disciplines (adapters), stock ---------------------------- %
    bg = BrandtGeometry();       bg.analyze();
    ba = BrandtAerodynamics(bg); ba.analyze();
    be = BrandtEngine();         be.analyze();
    bw = BrandtWeight(bg);       bw.analyze();
    bAero = BrandtAeroAdapter(ba);  bProp = BrandtPropAdapter(be);
    bGeom = BrandtMissionGeomAdapter(bg);
    bWts  = BrandtWeightAdapter(bw, be);

    % ---- Framework disciplines, stock JSON inputs (wiring per the
    %      f16_sizing_L1/L2/L3 studies) ----------------------------------- %
    s1 = f16a_spec_path(1); s2 = f16a_spec_path(2); s3 = f16a_spec_path(3);
    fWts1  = F16WeightsL1(s1);
    fProp2 = F16PropL2(s2);
    fGeom2 = F16GeomL2(s2, fProp2);
    fAero2 = F16AeroL2(fGeom2, s2);
    fWts2  = F16WeightsL2(s2, req, fGeom2, fProp2);
    fGeom3 = F16GeomL3(s3, fProp2);
    fAero3 = F16AeroL3(fGeom3, s3);
    fWts3  = F16WeightsL3(s3, req, fGeom3, fProp2);

    % ---- (1) Weights: OEW at the common W_TO ----------------------------- %
    OEW = struct();
    OEW.brandt = bWts.OEW(W_ref);        % expect 19,980.70 [Wt!B12]
    OEW.L1     = fWts1.OEW(W_ref);
    OEW.L2     = fWts2.OEW(W_ref);
    OEW.L3     = fWts3.OEW(W_ref);

    % ---- (2) Mission fuel at the common point, aero x prop pairings ------ %
    % Mixed pairs are valid AT THIS POINT because both geometries carry the
    % same S_ref = 300 ft^2; the mission's geom argument supplies only
    % S_ref/n_engines. All four use MissionAnalysisL2 x "cap" (the profile
    % the framework studies size to).
    fuel = struct();
    fuel.bA_bP = local_fuel(bAero,  bProp,  bGeom,  req, W_ref);
    fuel.fA_fP = local_fuel(fAero2, fProp2, fGeom2, req, W_ref);
    fuel.bA_fP = local_fuel(bAero,  fProp2, bGeom,  req, W_ref);
    fuel.fA_bP = local_fuel(fAero2, bProp,  fGeom2, req, W_ref);

    % ---- (3) Design point (grid argmin), aero x prop pairings ------------ %
    dp = struct();
    dp.bA_bP = local_dp(bAero,  bProp,  req, map, WS_sweep);
    dp.fA_fP = local_dp(fAero2, fProp2, req, map, WS_sweep);
    dp.bA_fP = local_dp(bAero,  fProp2, req, map, WS_sweep);
    dp.fA_bP = local_dp(fAero2, bProp,  req, map, WS_sweep);

    % ---- First-order closure push-through -------------------------------- %
    denom_eff = 0.35;   % see header
    d_ef = struct('L1', (OEW.L1 - OEW.brandt)/W_ref, ...
                  'L2', (OEW.L2 - OEW.brandt)/W_ref, ...
                  'L3', (OEW.L3 - OEW.brandt)/W_ref);
    d_ff_total = (fuel.fA_fP - fuel.bA_bP)/W_ref;
    d_ff_aero  = (fuel.fA_bP - fuel.bA_bP)/W_ref;   % aero share (Brandt prop held)
    d_ff_prop  = (fuel.bA_fP - fuel.bA_bP)/W_ref;   % prop share (Brandt aero held)

    % ---- Report ----------------------------------------------------------- %
    fprintf('\n=========== F-16A SIZING ATTRIBUTION (common point: W=31,377, S=300, T=23,770) ===========\n');
    fprintf('\n(1) WEIGHTS -- OEW(31,377) [Brandt Wt!B12 = 19,980.70]:\n');
    fprintf('    Brandt %10.1f | L1 %10.1f (%+6.1f%%) | L2 %10.1f (%+6.1f%%) | L3 %10.1f (%+6.1f%%)\n', ...
        OEW.brandt, OEW.L1, 100*(OEW.L1-OEW.brandt)/OEW.brandt, ...
        OEW.L2, 100*(OEW.L2-OEW.brandt)/OEW.brandt, ...
        OEW.L3, 100*(OEW.L3-OEW.brandt)/OEW.brandt);
    fprintf('\n(2) MISSION FUEL (MissionAnalysisL2 x cap at 31,377), aero x prop pairings:\n');
    fprintf('    Brandt aero + Brandt prop: %8.1f lbf   (all-Brandt reference)\n', fuel.bA_bP);
    fprintf('    fw L2 aero  + fw L2 prop : %8.1f lbf   (%+.1f lbf)\n', fuel.fA_fP, fuel.fA_fP-fuel.bA_bP);
    fprintf('    fw L2 aero  + Brandt prop: %8.1f lbf   (aero share  %+.1f lbf)\n', fuel.fA_bP, fuel.fA_bP-fuel.bA_bP);
    fprintf('    Brandt aero + fw L2 prop : %8.1f lbf   (prop share  %+.1f lbf)\n', fuel.bA_fP, fuel.bA_fP-fuel.bA_bP);
    fprintf('\n(3) DESIGN POINT (grid envelope argmin), aero x prop pairings [Brandt actual: 104.59 / 0.7576 with ~5.3%% margin]:\n');
    fprintf('    Brandt aero + Brandt prop: WS %7.2f  TW %7.4f\n', dp.bA_bP.WS, dp.bA_bP.TW);
    fprintf('    fw L2 aero  + fw L2 prop : WS %7.2f  TW %7.4f\n', dp.fA_fP.WS, dp.fA_fP.TW);
    fprintf('    fw L2 aero  + Brandt prop: WS %7.2f  TW %7.4f\n', dp.fA_bP.WS, dp.fA_bP.TW);
    fprintf('    Brandt aero + fw L2 prop : WS %7.2f  TW %7.4f\n', dp.bA_fP.WS, dp.bA_fP.TW);
    fprintf('\nFIRST-ORDER W_TO PUSH-THROUGH (dW0/W0 ~= (d_ff + d_ef)/%.2f):\n', denom_eff);
    fprintf('    weights L1: %+6.1f%%   weights L2: %+6.1f%%   weights L3: %+6.1f%%\n', ...
        100*d_ef.L1/denom_eff, 100*d_ef.L2/denom_eff, 100*d_ef.L3/denom_eff);
    fprintf('    mission total (L2 aero+prop): %+6.1f%%  [aero share %+5.1f%%, prop share %+5.1f%%]\n', ...
        100*d_ff_total/denom_eff, 100*d_ff_aero/denom_eff, 100*d_ff_prop/denom_eff);
    fprintf('\nNOTE: first-order estimates; the converged rungs compound these nonlinearly.\n');

    results = struct('W_ref', W_ref, 'OEW', OEW, 'fuel', fuel, 'dp', dp, ...
        'd_ef', d_ef, 'd_ff', struct('total', d_ff_total, 'aero', d_ff_aero, ...
        'prop', d_ff_prop), 'denom_eff', denom_eff);
    fid = fopen(fullfile(outdir, 'f16_sizing_attribution.json'), 'w');
    fwrite(fid, jsonencode(results, 'PrettyPrint', true)); fclose(fid);
    fprintf('\nJSON written to %s\n', fullfile(outdir, 'f16_sizing_attribution.json'));
end

function W_fuel = local_fuel(aero, prop, geom, req, W_ref)
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, req, "cap");
    [W_fuel, ~] = miss.total_fuel(W_ref);
end

function out = local_dp(aero, prop, req, map, sweep)
    con = ConstraintAnalysis.from_requirements(aero, prop, req, map, sweep);
    [ws, tw] = con.optimal_point();
    out = struct('WS', ws, 'TW', tw);
end

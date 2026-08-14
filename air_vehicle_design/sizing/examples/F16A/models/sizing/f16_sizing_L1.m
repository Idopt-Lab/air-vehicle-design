function [result, objs] = f16_sizing_L1(W_TO_guess)
%F16_SIZING_L1  F-16A Level-1 sizing study (framework disciplines).
%
%   result = f16_sizing_L1(W_TO_guess) builds fresh F16AeroL1/F16PropL1/
%   F16WeightsL1/F16GeomL1 discipline objects, the L1 mission analysis
%   (MissionAnalysisL1.from_requirements over the CAP profile), and the
%   F-16's constraint set (ConstraintAnalysis.from_requirements with
%   F16ConstraintSet.constraint_map(), sharing this study's own aero/prop
%   objects rather than a separate internal copy), wires them into
%   SizingLoopL1, and runs it to convergence. DI wiring follows the retired
%   design_study_01_L1.m exactly (this function replaces it, 2026-08-13);
%   the loop it drives is the NEW src/sizing/SizingLoopL1.m.
%
%   [result, objs] = f16_sizing_L1(...) additionally returns the handle
%   objects (objs.aero/prop/wts/geom/miss/con) in their final, converged
%   state -- for post-processing/reporting scripts (run_sizing_report_L1.m)
%   that call further methods on them after the loop has converged.
%
%   result = f16_sizing_L1() uses a default initial guess of 30,000 lbf --
%   deliberately off Brandt's 31,377 lbf target, so a passing convergence
%   check demonstrates the loop actually converges rather than starting at
%   the answer.
%
%   W/S SWEEP: PointPerformanceBase.WS_RANGE_BRANDT (20:7:160 psf, the
%   Brandt Consts-tab grid). The sweep only bounds and seeds
%   optimal_point_continuous (SizingLoopL1 solves the design point
%   continuously via fmincon), so the coarse grid costs nothing here beyond
%   the warm-start seed -- kept for diagram/verification parity with the
%   constraint tests.
%
%   VALIDATION TARGET [docs/PLAN.md F-16A Validation Targets]: Brandt
%   W_TO = 31,377 lbf. Residual gaps at this rung are DISCIPLINE fidelity
%   (L1's statistical aero/weights/mission regressions), not loop bugs --
%   see sanity_checks/sizing_brandt_comparison.m for the measured spread
%   across all rungs. L1's S_ref is genuinely solved for here (S_ref =
%   W_TO/(W/S)*), not expected to land on Brandt's 300 ft^2 input.
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
    end

    % DI wiring per the retired design_study_01_L1.m (verified against the
    % current constructors, 2026-08-13).
    aero = F16AeroL1(f16a_spec_path(1));
    prop = F16PropL1(f16a_spec_path(1));
    wts  = F16WeightsL1(f16a_spec_path(1));
    geom = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
    miss = MissionAnalysisL1.from_requirements(aero, prop, geom, ...
        f16a_requirements_path(), "cap");

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);

    loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
    result = loop.run(W_TO_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con);
end

function [result, objs] = f16_sizing_L3(W_TO_guess, T_SL_guess)
%F16_SIZING_L3  F-16A Level-3 sizing study (framework disciplines).
%
%   result = f16_sizing_L3(W_TO_guess, T_SL_guess) builds fresh F16AeroL3/
%   F16GeomL3/F16WeightsL3 discipline objects with F16PropL2 standing in
%   for propulsion (there is deliberately NO L3 propulsion tier -- locked
%   decision 2026-07-25; any T_SL this study reports is COMPUTED BY
%   F16PropL2), the L2 mission analysis over the L3 stack
%   (MissionAnalysisL2.from_requirements, CAP profile; no L3 mission tier),
%   the F-16 constraint set, and the F16TailL1 tail sizer, then runs the
%   NEW SizingLoopL2 -- reused unmodified: sizing has no per-fidelity
%   equation set of its own, only a state-variable count (2 at both L2 and
%   L3), so no SizingLoopL3 class exists or is needed. DI wiring follows
%   the retired design_study_03_L3.m (this function replaces it,
%   2026-08-13).
%
%   [result, objs] = f16_sizing_L3(...) additionally returns the handle
%   objects (objs.aero/prop/wts/geom/miss/con/tail) in their final,
%   converged state -- for post-processing/reporting scripts
%   (run_sizing_report_L3.m).
%
%   NO ControlSurfaceSizer, DELIBERATELY -- same rationale as
%   f16_sizing_L2.m (see that header and SizingLoopL2.m's): the reports
%   call ControlSurfaceSizer on the converged geometry afterwards.
%
%   Default guesses 30,000 / 20,000 lbf are deliberately off Brandt's
%   31,377 / 23,770 lbf targets, so a passing convergence check
%   demonstrates the loop actually converges rather than starting at the
%   answer.
%
%   VALIDATION TARGET [docs/PLAN.md F-16A Validation Targets]: Brandt
%   W_TO = 31,377 lbf, T_SL = 23,770 lbf. Residual gaps at this rung are
%   DISCIPLINE fidelity, not loop bugs -- see sanity_checks/
%   sizing_brandt_comparison.m for the measured spread across all rungs.
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    % DI wiring per the retired design_study_03_L3.m (verified against the
    % current constructors, 2026-08-13): F16PropL2 (no L3 propulsion tier),
    % L3 geometry injects it, L3 aero injects geometry, L3 weights injects
    % both; L2 mission fidelity over the L3 discipline stack.
    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
    aero = F16AeroL3(geom, f16a_spec_path(3));
    wts  = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), geom, prop);
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, ...
        f16a_requirements_path(), "cap");
    tail = F16TailL1(geom);

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'tail', tail);
end

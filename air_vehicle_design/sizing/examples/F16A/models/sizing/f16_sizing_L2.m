function [result, objs] = f16_sizing_L2(W_TO_guess, T_SL_guess)
%F16_SIZING_L2  F-16A Level-2 sizing study (framework disciplines).
%
%   result = f16_sizing_L2(W_TO_guess, T_SL_guess) builds fresh F16PropL2/
%   F16GeomL2/F16AeroL2/F16WeightsL2 discipline objects (in that order --
%   geometry injects prop, aero injects geom, weights injects both), the L2
%   mission analysis (MissionAnalysisL2.from_requirements over the CAP
%   profile), the F-16 constraint set, and the F16TailL1 tail sizer, then
%   runs the NEW SizingLoopL2 to convergence: two-state (W_TO, T_SL) fixed
%   point in which the wing is resized from the evolving design point every
%   iteration and the constraint envelope is re-solved as the geometry and
%   thrust move. DI wiring follows the retired design_study_02_L2.m (this
%   function replaces it, 2026-08-13).
%
%   [result, objs] = f16_sizing_L2(...) additionally returns the handle
%   objects (objs.aero/prop/wts/geom/miss/con/tail) in their final,
%   converged state -- for post-processing/reporting scripts
%   (run_sizing_report_L2.m).
%
%   NO ControlSurfaceSizer, DELIBERATELY (change vs the retired study,
%   which passed one into the old loop): the new SizingLoopL2 takes no ctrl
%   object -- control-surface areas feed no OEW term, so sizing them inside
%   the loop added coupling that does not exist (see SizingLoopL2.m's
%   header). Reports that want the areas call ControlSurfaceSizer on the
%   converged geometry afterwards (run_sizing_report_L2.m does exactly
%   that).
%
%   TAIL SIZING: F16TailL1 (Raymer 7th ed. Table 6.4 volume-coefficient
%   method, corrected 0.315/0.063, tail arm 0.475*L_fus; no-arg
%   constructor). SizingLoopL2.run() calls tail.size(S_ref, b_wing,
%   cbar_wing, L_fus) every iteration and writes the result into
%   geom.S_ht/S_vt, which the weights class reads live.
%
%   Default guesses 30,000 / 20,000 lbf are deliberately off Brandt's
%   31,377 / 23,770 lbf targets, so a passing convergence check
%   demonstrates the loop actually converges rather than starting at the
%   answer.
%
%   VALIDATION TARGET [docs/PLAN.md F-16A Validation Targets]: Brandt
%   W_TO = 31,377 lbf, T_SL = 23,770 lbf. Residual gaps at this rung are
%   DISCIPLINE fidelity (the L2 aero/weights models), not loop bugs -- see
%   sanity_checks/sizing_brandt_comparison.m for the measured spread.
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    % DI wiring per the retired design_study_02_L2.m (verified against the
    % current constructors, 2026-08-13): prop first, geometry injects prop
    % (nacelle sized from T_SL), aero injects geom, weights injects both.
    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL2(f16a_spec_path(2), prop);
    aero = F16AeroL2(geom, f16a_spec_path(2));
    wts  = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, ...
        f16a_requirements_path(), "cap");
    tail = F16TailL1();

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'tail', tail);
end

function [result, objs] = design_study_03_L3(W_TO_guess, T_SL_guess)
%DESIGN_STUDY_03_L3  F-16A Level-3 sizing study.
%
%   result = design_study_03_L3(W_TO_guess, T_SL_guess) builds fresh
%   F16AeroL3/F16WeightsL3/F16GeomL3 discipline objects, the L2 mission
%   analysis over the L3 discipline stack (MissionAnalysisL2.from_requirements;
%   there is no L3 mission tier), and the F-16's L3 constraint set
%   (ConstraintAnalysis.from_requirements with the
%   F-16 map F16ConstraintSet.constraint_map(), sharing this study's own
%   aero/prop objects rather than a separate internal copy), and runs
%   SizingLoopL2 -- reused unmodified, per the original step-8 sizing plan
%   ("L3 design study -> SizingLoopL2"): sizing
%   has no per-fidelity-level equation set of its own, only a state-variable
%   count (2 at both L2 and L3), so no new SizingLoopL3 class exists or is
%   needed.
%
%   [result, objs] = design_study_03_L3(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con) in their
%   final, converged state -- e.g. for post-processing/reporting scripts
%   (run_sizing_report_L3.m) that need to call further methods on them
%   (weight/aero breakdowns, fuel-volume check) after the loop has
%   converged. Optional and additive: existing single-output callers
%   (tests/sizing/TestF16SizingStudies.m) are unaffected.
%
%   TAIL SIZING (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
%   tail sizing and control-surface sizing are separate, dependency-injected
%   objects again -- F16TailL1() and ControlSurfaceSizer(...), the SAME
%   objects (shared, unmodified) as design_study_02_L2.m, wired into
%   SizingLoopL2 exactly as there. F16TailL3 -- the stability-and-control
%   stub that errors on size() with a citation-gap message -- is NOT used
%   here; it is never wired into any working design study.
%
%   PROPULSION AT L3: there is deliberately no L3 propulsion tier (no
%   PropL3/PropulsionModelL3/F16PropL3 -- user decision 2026-07-25). This
%   study pairs F16AeroL3 with F16PropL2 directly, then hands that same pair to
%   ConstraintAnalysis.from_requirements -- any T_SL/thrust number this study
%   reports is COMPUTED BY F16PropL2, not a separate L3 propulsion model.
%
%   result = design_study_03_L3() uses default initial guesses of 30,000
%   lbf / 20,000 lbf -- both deliberately off Brandt's 31,377 lb / 23,770
%   lbf targets, so a passing convergence check demonstrates the loop
%   actually converges rather than starting at the answer.
%
%   CONTROL-SURFACE FRACTIONS: identical to design_study_02_L2.m's (same
%   airframe, same Raymer Fig. 6.3/Table 6.5 sourcing) -- see that file's
%   header for the full rationale. Not re-derived per fidelity level: the
%   SAME ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90) call is used here.
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL3(f16a_spec_path(3), prop);
    aero = F16AeroL3(geom, f16a_spec_path(3));
    wts  = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), geom, prop);
    % L2 mission fidelity with the L3 discipline stack (there is no L3 mission tier).
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
    tail = F16TailL1();
    ctrl = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con);
end

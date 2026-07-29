function [result, objs] = design_study_03_L3(W_TO_guess, T_SL_guess)
%DESIGN_STUDY_03_L3  F-16A Level-3 sizing study.
%
%   result = design_study_03_L3(W_TO_guess, T_SL_guess) builds fresh
%   F16AeroL3/F16WeightsL3/F16GeomL3/F16MissionL3 discipline objects, the
%   F-16's L3 constraint set (F16ConstraintSet.build("L3")), the same
%   F16TailL1/ControlSurfaceSizer as design_study_02_L2, and runs
%   SizingLoopL2 -- reused unmodified, per docs/subplans/08_sizing.md ("L3
%   design study -> SizingLoopL2"): sizing has no per-fidelity-level
%   equation set of its own, only a state-variable count (2 at both L2 and
%   L3), so no new SizingLoopL3 class exists or is needed.
%
%   [result, objs] = design_study_03_L3(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con/tail/ctrl) in their
%   final, converged state -- e.g. for post-processing/reporting scripts
%   (F16A_Level3_SizingReport.m) that need to call further methods on them
%   (weight/aero breakdowns, fuel-volume check) after the loop has
%   converged. Optional and additive: existing single-output callers
%   (tests/sizing/TestF16SizingStudies.m) are unaffected.
%
%   TAIL SIZING (updated 2026-07-28): uses F16TailL1, same as
%   design_study_02_L2 -- see that file's header for why (SizingLoopL2's
%   run() body still calls the L1 four-scalar size(...) convention, so an
%   L2/L3-tier tail object is not yet wireable through this loop). This
%   supersedes the now-retired F16TailSizingLevel1.
%
%   PROPULSION AT L3: there is deliberately no L3 propulsion tier (no
%   PropL3/PropulsionModelL3/F16PropL3 -- user decision 2026-07-25, see
%   F16ConstraintSet.buildDisciplines's header). This study pairs
%   F16AeroL3 with F16PropL2, matching F16ConstraintSet.build("L3")'s own
%   internal pairing -- any T_SL/thrust number this study reports is
%   COMPUTED BY F16PropL2, not a separate L3 propulsion model.
%
%   result = design_study_03_L3() uses default initial guesses of 30,000
%   lbf / 20,000 lbf -- both deliberately off Brandt's 31,377 lb / 23,770
%   lbf targets, so a passing convergence check demonstrates the loop
%   actually converges rather than starting at the answer.
%
%   CONTROL-SURFACE FRACTIONS: identical to design_study_02_L2.m's (same
%   airframe, same Raymer Fig. 6.3/Table 6.5 sourcing) -- see that file's
%   header for the full rationale. Not re-derived per fidelity level since
%   ControlSurfaceSizer/F16TailL1 are generic, geometry-driven helpers with
%   no L2-vs-L3-specific equation variant.
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL3(f16a_spec_path(3), prop);
    aero = F16AeroL3(geom, f16a_spec_path(3));
    wts  = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), geom, prop);
    miss = F16MissionL3();

    constraints = F16ConstraintSet.build("L3");
    con = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);

    tail = F16TailL1();
    ctrl = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'tail', tail, 'ctrl', ctrl);
end

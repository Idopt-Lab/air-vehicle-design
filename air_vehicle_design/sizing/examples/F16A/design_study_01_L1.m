function [result, objs] = design_study_01_L1(W_TO_guess)
%DESIGN_STUDY_01_L1  F-16A Level-1 sizing study.
%
%   result = design_study_01_L1(W_TO_guess) builds fresh F16AeroL1/F16PropL1/
%   F16WeightsL1/F16GeomL1/F16MissionL1 discipline objects plus the F-16's
%   L1 constraint set (F16ConstraintSet.build(aero, prop), sharing this
%   study's own aero/prop objects rather than a separate internal copy),
%   wires them into SizingLoopL1, and runs it to convergence.
%
%   [result, objs] = design_study_01_L1(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con) in their final,
%   converged state -- e.g. for post-processing/reporting scripts
%   (F16A_Level1_SizingReport.m) that need to call further methods on them
%   (weight/aero breakdowns) after the loop has converged. Optional and
%   additive: existing single-output callers (tests/sizing/
%   TestF16SizingStudies.m) are unaffected.
%
%   result = design_study_01_L1() uses a default initial guess of 30,000
%   lbf -- deliberately off Brandt's 31,377 lbf target, so a passing
%   convergence check demonstrates the loop actually converges rather than
%   starting at the answer.
%
%   VALIDATION TARGET [docs/PLAN.md F-16A Validation Targets; docs/subplans/
%   08_sizing.md test tolerance table]: Brandt W_TO = 31,377 lbf, expect
%   this L1 study's W_TO in 25,000-40,000 lbf (+-20%) and S_ref in
%   250-360 ft^2 (+-20% of Brandt's 300 ft^2 -- which is itself an L2/L3
%   INPUT, not an L1 target; L1's S_ref is genuinely solved for here, not
%   expected to land exactly on 300).
arguments
     % TODO (7/31/2026): These should not be hardcoded.
     W_TO_guess (1,1) double {mustBePositive} = 30000
end

aero = F16AeroL1(f16a_spec_path(1));
prop = F16PropL1(f16a_spec_path(1));
wts  = F16WeightsL1(f16a_spec_path(1));
geom = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
miss = F16MissionL1(mission_profile_path());

constraints = F16ConstraintSet.build(aero, prop);
con = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);

loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
result = loop.run(W_TO_guess);

objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
     'miss', miss, 'con', con);
end

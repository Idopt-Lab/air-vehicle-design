function [aero, prop, wts, geom, miss, con] = build_f16_stack_L1(opts)
%BUILD_F16_STACK_L1  Build a FRESH F-16A Level-1 discipline stack.
%
%   [aero, prop, wts, geom, miss, con] = BUILD_F16_STACK_L1()
%
%   Six objects -- exactly what SizingLoopL1 needs. There is no tail sizer at
%   Level 1, because the Level-1 loop never resizes the tail.
%
%   At Level 1 the aerodynamics object takes NO geometry. It reads AR and the
%   leading-edge sweep as plain numbers from the spec file. That single fact is
%   why the Level-1 constraint diagram cannot move while the loop runs.
%
%   Every object is a handle. Build a fresh stack before each run.

    arguments
        opts.mission (1,1) string = "cap"
    end

    sp = f16a_spec_path(1);
    rp = f16a_requirements_path();

    aero = F16AeroL1(sp);             % no geometry injected -- see above
    prop = F16PropL1(sp);
    wts  = F16WeightsL1(sp);          % We/W_TO regression (Raymer Table 3.1)
    geom = F16GeomL1(sp, rp);
    miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, opts.mission);
    con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
               F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);
end

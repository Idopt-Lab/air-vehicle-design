function [aero, prop, wts, geom, miss, con, tail] = build_f16_stack_L2(opts)
%BUILD_F16_STACK_L2  Build a FRESH F-16A Level-2 discipline stack.
%
%   [aero, prop, wts, geom, miss, con, tail] = BUILD_F16_STACK_L2()
%
%   Seven objects -- exactly what SizingLoopL2 needs.
%
%   Construction order is forced by dependency injection:
%     prop -> geom(prop) -> aero(geom) -> wts(geom, prop) -> tail(geom)
%   The nacelle diameter is sized from engine thrust, so geometry needs the
%   propulsion object before it can exist.
%
%   Unlike Level 1, the Level-2 aerodynamics object HOLDS the geometry object.
%   Change the wing area and the drag polar changes with it. That is why the
%   Level-2 loop must re-solve the design point on every pass.
%
%   Every object is a handle. Build a fresh stack before each run.

    arguments
        opts.mission (1,1) string = "cap"
    end

    sp = f16a_spec_path(2);
    rp = f16a_requirements_path();

    prop = F16PropL2(sp);
    geom = F16GeomL2(sp, prop);
    aero = F16AeroL2(geom, sp);
    wts  = F16WeightsL2(sp, rp, geom, prop);
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, rp, opts.mission);
    tail = F16TailL1(geom);
    con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
               F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);
end

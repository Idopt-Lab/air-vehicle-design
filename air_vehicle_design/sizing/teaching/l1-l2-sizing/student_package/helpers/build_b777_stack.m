function [aero, prop, wts, geom, miss, con, tail] = build_b777_stack(opts)
%BUILD_B777_STACK  Build a FRESH Boeing 777-200LR discipline stack.
%
%   [aero, prop, wts, geom, miss, con, tail] = BUILD_B777_STACK()
%
%   Every object is a handle. A sizing loop MUTATES these objects in place.
%   Always build a fresh stack before each run, or the second run starts from
%   the first run's leftovers.
%
%   Construction order is not free -- see lecture/L01.
%     geom -> prop -> aero(geom) -> tail(geom) -> wts(geom, prop)
%
%   Name-value options:
%     WS_range   wing-loading sweep for the constraint diagram [psf]
%     mission    mission profile name in b777_requirements.json
%
%   Provenance: Martins design metabook, Ch. 4 (constraints) and Ch. 7
%   (component build-up weights).

    arguments
        opts.WS_range (1,:) double {mustBePositive} = linspace(20, 340, 321)
        opts.mission  (1,1) string = "long_range"
    end

    sp = b777_spec_path(1);
    rp = b777_requirements_path();

    geom = B777GeomL2(sp);            % L2 trapezoidal planform (metabook Table 7.2)
    prop = B777PropL1(sp);            % 2x GE90, density-ratio lapse + cruise TSFC
    aero = B777AeroL1(geom, sp);      % CD0 = Cfe*S_wet/S_ref -- tracks the wing
    tail = B777TailL1(geom);          % tail volume-coefficient sizing
    wts  = B777WeightsL2(sp, geom, prop);   % component build-up OEW(W_TO), Ch. 7

    miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, opts.mission);
    con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
               B777ConstraintSet.constraint_map(), opts.WS_range);
end

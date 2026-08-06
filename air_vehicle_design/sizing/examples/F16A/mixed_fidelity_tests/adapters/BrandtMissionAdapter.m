classdef BrandtMissionAdapter < MissionBase
%BRANDTMISSIONADAPTER  Adapter exposing Brandt's own F-16A 14-segment
%   mission analysis (VnV/BrandtF16A/BrandtMission.m) through the generic
%   MissionBase contract, so "Brandt" can be selected as a fidelity LEVEL in
%   the mixed-fidelity sizing harness alongside F16MissionL1/L2/L3.
%
%   SELF-CONTAINED, BY DESIGN (see BrandtGeomAdapter's header for the
%   rationale, which applies identically here): the constructor builds ALL
%   of a private BrandtGeometry -> BrandtEngine -> BrandtAerodynamics ->
%   BrandtMission chain and analyzes every link internally. No external
%   geometry/aero/prop object is injected -- Mission=Brandt always reflects
%   Brandt's own airframe/engine/aero triplet, independent of whatever
%   Geometry/Aero/Propulsion LEVEL the rest of a combo chose
%   (COMPATIBILITY_NOTES.md item 3).
%
%   compute_fuel(obj, aero, prop, W_TO) -- see the LOUD comment inside the
%   method body: this implementation IGNORES the passed aero/prop arguments
%   entirely (COMPATIBILITY_NOTES.md item 4). BrandtMission's internal
%   14-segment fuel calculation is entirely self-contained over its own
%   private Brandt aero/engine/geometry triplet (constructor signature
%   BrandtMission(aeroObj, engObj, geomObj), BrandtMission.m:132), so it
%   structurally cannot respond to a different aero/prop object passed in
%   at call time -- there is no seam to inject one through. A one-time
%   runtime warning (warning('BrandtMissionAdapter:ignoresAeroProp', ...))
%   fires on the FIRST call so this limitation is visible at runtime, not
%   just in a comment nobody reads; subsequent calls stay silent (a warning
%   on every call of a per-iteration sizing-loop method would flood the
%   console -- this class chooses ONE-TIME over every-call, and says so).
%
%   Returns obj.brandt.run(W_TO).total_fuel_lb -- Brandt's own Miss!O9 total
%   fuel [Brandt F-16A.xls Miss!O9 = 6000.43 lb, BrandtMission.m's class
%   header validation target; confirmed as the exact returned-struct field
%   name inside BrandtMission.m's packResults_ method].

    properties (Access = private)
        brandt              % BrandtMission handle, built + analyzed in the constructor
        warned_ (1,1) logical = false   % one-time compute_fuel warning latch
    end

    methods

        function obj = BrandtMissionAdapter()
        %BRANDTMISSIONADAPTER  Build the private BrandtGeometry -> BrandtEngine
        %   -> BrandtAerodynamics -> BrandtMission chain and analyze every
        %   link. Always Brandt's own hardcoded ground-truth JSON
        %   (VnV/BrandtF16A/GroundTruth/f16a_geometry.json).
            geom = BrandtGeometry();
            geom.analyze();
            eng = BrandtEngine();
            eng.analyze();
            aero = BrandtAerodynamics(geom);
            aero.analyze();
            obj.brandt = BrandtMission(aero, eng, geom);
        end

        function W_fuel = compute_fuel(obj, aero, prop, W_TO)
        %COMPUTE_FUEL  Total mission fuel weight [lbf], from Brandt's own
        %   14-segment analysis at the given W_TO.
        %
        %   *** aero AND prop ARE DELIBERATELY IGNORED. ***
        %   This is unusual for a method with those parameters -- they exist
        %   only to satisfy MissionBase's shared Tier-1 signature
        %   (compute_fuel(obj, aero, prop, W_TO), same shape every fidelity
        %   level uses). BrandtMission's fuel burn is computed entirely over
        %   its OWN private aero/engine/geometry triplet, built once in this
        %   adapter's constructor; there is no argument of BrandtMission.run
        %   this method could use to substitute a different aero/prop
        %   object's drag polar or thrust lapse. A sizing loop pairing
        %   Mission=Brandt with any Aero/Propulsion LEVEL therefore gets
        %   fuel-burn numbers that never respond to that choice --
        %   COMPATIBILITY_NOTES.md item 4.
            arguments
                obj
                aero (1,1) AerodynamicsBase %#ok<INUSA>
                prop (1,1) PropulsionBase   %#ok<INUSA>
                W_TO (1,1) double {mustBePositive}
            end
            if ~obj.warned_
                warning('BrandtMissionAdapter:ignoresAeroProp', ...
                    ['BrandtMissionAdapter.compute_fuel ignores its aero/prop ', ...
                     'arguments: BrandtMission''s 14-segment fuel burn runs over ', ...
                     'its own private Brandt aero/engine/geometry triplet, built ', ...
                     'once in this adapter''s constructor, and cannot respond to ', ...
                     'a different aero/prop object at call time. This warning ', ...
                     'fires once per adapter instance.']);
                obj.warned_ = true;
            end
            r = obj.brandt.run(W_TO);
            W_fuel = r.total_fuel_lb;
        end

    end

end

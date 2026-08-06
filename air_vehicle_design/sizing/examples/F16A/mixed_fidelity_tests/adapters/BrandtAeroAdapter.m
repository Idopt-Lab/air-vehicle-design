classdef BrandtAeroAdapter < AerodynamicsBase
%BRANDTAEROADAPTER  Adapter exposing Brandt's own F-16A aerodynamics
%   (VnV/BrandtF16A/BrandtAerodynamics.m) through the generic
%   AerodynamicsBase contract, so "Brandt" can be selected as a fidelity
%   LEVEL in the mixed-fidelity sizing harness alongside F16AeroL1/L2/L3.
%
%   SELF-CONTAINED, BY DESIGN (see BrandtGeomAdapter's header for the
%   rationale, which applies identically here): the constructor builds its
%   own PRIVATE BrandtGeometry -> BrandtAerodynamics pair and analyzes both
%   internally. No external geometry object is injected -- Aero=Brandt
%   always reflects Brandt's own airframe, independent of whatever Geometry
%   LEVEL the rest of a combo chose (COMPATIBILITY_NOTES.md item 3).
%
%   drag_polar(obj, state) calls obj.brandt.run(state.mach) and returns
%   struct('CD0', r.CD0, 'K1', r.K1, 'K2', r.K2) -- BrandtAerodynamics.run's
%   returned struct already uses exactly these field names (BrandtAerodynamics.m,
%   the run() method). Brandt's own aerodynamics model is Mach-only (no altitude
%   dependence in the polar itself); state.altitude_ft is accepted
%   (AerodynamicsBase's contract takes the full AircraftState) but not read.
%
%   get_CLmax(obj, state) ALWAYS returns obj.brandt.CLmax_clean, the CLEAN
%   configuration value. AircraftState carries no takeoff/landing PHASE flag
%   (src/core/AircraftState.m: altitude_ft, mach and derived atmosphere
%   only), so BrandtAerodynamics.CLmax_takeoff / CLmax_landing are
%   UNREACHABLE through this generic AerodynamicsBase.get_CLmax(state) call
%   -- there is no argument this method could use to select them. A
%   consumer needing takeoff/landing CLmax must read
%   obj.brandt.CLmax_takeoff / CLmax_landing directly off this adapter.
%
%   TAKEOFF/LANDING EXTRAS (added after initial verification found
%   F16ConstraintSet.build's TakeoffConstraint/LandingConstraint call four
%   methods beyond AerodynamicsBase's formal two-method abstract contract --
%   a duck-typed extension every F16AeroL1/L2/L3 concrete class happens to
%   implement, per those constraints' own class headers):
%   get_CLmax_TO()/get_CLmax_L() return Brandt's own CLmax_takeoff/
%   CLmax_landing directly (finally a real use for those two, unlike the
%   generic get_CLmax(state) above). get_Delta_CD0_TO()/get_Delta_CD0_L()
%   return obj.brandt.CD0_takeoff - obj.brandt.CD0 -- Brandt has only ONE
%   flapped-configuration CD0 (Miss!CD0_TO), no separate landing value, so
%   both deltas reuse it; this is a documented approximation, not a
%   citation, called out in COMPATIBILITY_NOTES.md. All four are zero-arg,
%   matching F16AeroL2.get_CLmax_TO/get_Delta_CD0_TO's own signatures (a
%   fixed increment added to whatever drag_polar(state)/get_CLmax(state)
%   return at the caller's chosen flight condition).

    properties (Access = private)
        brandt   % BrandtAerodynamics handle, built + analyzed in the constructor
    end

    methods

        function obj = BrandtAeroAdapter()
        %BRANDTAEROADAPTER  Build a private BrandtGeometry -> BrandtAerodynamics
        %   pair and analyze both. Always Brandt's own hardcoded ground-truth
        %   JSON (VnV/BrandtF16A/GroundTruth/f16a_geometry.json) -- no path
        %   argument, matching BrandtAerodynamics's own no-argument constructor.
            geom = BrandtGeometry();
            geom.analyze();
            obj.brandt = BrandtAerodynamics(geom);
            obj.brandt.analyze();
        end

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  struct('CD0','K1','K2') at state.mach [Brandt Miss tab basis].
            arguments
                obj
                state (1,1) AircraftState
            end
            r = obj.brandt.run(state.mach);
            polar = struct('CD0', r.CD0, 'K1', r.K1, 'K2', r.K2);
        end

        function CLmax = get_CLmax(obj, state)
        %GET_CLMAX  ALWAYS the clean-configuration value -- see class header.
            arguments
                obj
                state (1,1) AircraftState %#ok<INUSA>
            end
            CLmax = obj.brandt.CLmax_clean;
        end

        function val = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Flapped takeoff CLmax -- Brandt's own CLmax_takeoff.
            val = obj.brandt.CLmax_takeoff;
        end

        function val = get_CLmax_L(obj)
        %GET_CLMAX_L  Flapped landing CLmax -- Brandt's own CLmax_landing.
            val = obj.brandt.CLmax_landing;
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Fixed CD0 increment added to drag_polar(state).CD0
        %   to get the flapped takeoff CD0 -- see class header.
            val = obj.brandt.CD0_takeoff - obj.brandt.CD0;
        end

        function val = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Same fixed increment as get_Delta_CD0_TO -- Brandt
        %   has no separate landing-configuration CD0, see class header.
            val = obj.brandt.CD0_takeoff - obj.brandt.CD0;
        end

    end

end

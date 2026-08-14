classdef FixedMissionStub < MissionAnalysisBase
%FIXEDMISSIONSTUB  A minimal stand-in mission-analysis object, used only by
%   tests.
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale: the sizing
%   orchestrators (SizingLoopL1, SizingLoopL2, TSDiagram) need a
%   MissionAnalysisBase object, not a real MissionAnalysisL1/L2, to test the
%   sizing iteration in isolation from any particular aircraft's mission
%   model.
%
%   TOTAL_FUEL IS OVERRIDDEN (2026-08-13 sizing rewrite). The new sizing
%   loops call miss.total_fuel(W_TO) directly -- no longer
%   compute_fuel(aero, prop, W_TO). This stub's earlier compute_fuel-only
%   override would leave the base class's segment loop running over the
%   EMPTY segment list and return W_fuel = 0, silently breaking the
%   hand-computed toy fixed point. total_fuel here ignores aero/prop/geom
%   entirely and returns fuel_fraction * W_TO; the breakdown struct mirrors
%   the base class's field names with an empty segment table. The base
%   class's compute_fuel needs no override: it delegates to total_fuel.
%
%   The constructor takes an OPTIONAL fuel fraction:
%     - default 0.15 preserves the toy 3200-lbf fixed point every generic
%       sizing-loop test hand-computes (see TestSizingLoopL1.m's header);
%     - TestSizingVsBrandt.m passes Brandt's residual fuel fraction
%       6296.30/31377 [Brandt Wt!B6 / Wt!B3] to pin mission fuel for its
%       algebraic-identity check.
%
%   The base constructor is satisfied with the mission test stubs and an
%   empty segment list, since none of them are read once total_fuel is
%   overridden.

    properties
        fuel_fraction (1,1) double = 0.15
    end

    methods

        function obj = FixedMissionStub(fuel_fraction)
            arguments
                fuel_fraction (1,1) double {mustBePositive} = 0.15
            end
            obj@MissionAnalysisBase(MissionStubAero(), MissionStubProp(), ...
                MissionStubGeom(), {}, struct());
            obj.fuel_fraction = fuel_fraction;
        end

        function [W_fuel, breakdown] = total_fuel(obj, W_TO)
        %TOTAL_FUEL  Fixed-fraction fuel: W_fuel = fuel_fraction * W_TO.
        %   Overrides MissionAnalysisBase.total_fuel (see class header for
        %   why). breakdown keeps the base class's field names so any
        %   consumer that reads it structurally still works.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end
            W_fuel = obj.fuel_fraction * W_TO;
            breakdown = struct( ...
                'names',                 strings(1, 0), ...
                'fuel_lbf',              zeros(1, 0), ...
                'W_after',               zeros(1, 0), ...
                'raw_burn',              W_fuel, ...
                'reserve_fuel_fraction', 0, ...
                'W_fuel_with_reserve',   W_fuel, ...
                'W_TO',                  W_TO, ...
                'debug',                 {{}});
        end

    end

end

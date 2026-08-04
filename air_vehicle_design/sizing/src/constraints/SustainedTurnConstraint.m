classdef SustainedTurnConstraint < MasterEquationConstraint
%SUSTAINEDTURNCONSTRAINT  Mattingly Master Equation, sustained turn (n>1,
%   Ps=0).
%
%   The Master-Equation specialization for a steady, level turn held at load
%   factor n>1 with zero specific excess power (Ps=0: the turn is SUSTAINED,
%   not instantaneous, so no altitude/airspeed is being traded). The
%   induced-drag B and C terms carry the elevated n; the excess-power D term
%   still vanishes. The F-16 "Combat Turn 1" (subsonic, n=4.5) and "Combat
%   Turn 2" (supersonic, n=1.4) conditions are both SustainedTurnConstraints
%   -- they differ from the level-flight conditions only in load factor.
%
%   All physics, the A/B/C/D assembly, the non-finite self-guard, and the
%   equation citation live in MasterEquationConstraint -- this class only
%   fixes Ps=0 and takes n as an input. See
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.

    methods

        function obj = SustainedTurnConstraint(name, state, aero, prop, beta, n, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive}
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, n, 0.0, powerSetting);
        end

    end

end

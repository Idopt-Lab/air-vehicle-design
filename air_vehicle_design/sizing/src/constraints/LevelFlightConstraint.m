classdef LevelFlightConstraint < MasterEquationConstraint
%LEVELFLIGHTCONSTRAINT  Mattingly Master Equation, level unaccelerated
%   flight (n=1, Ps=0).
%
%   The Master-Equation specialization for steady, wings-level, non-turning,
%   non-climbing flight: load factor n=1.0 and specific excess power Ps=0.0,
%   so the induced-drag term uses n=1 and the excess-power D term vanishes.
%   The F-16 "Max Mach", "Cruise" and "Max Alt" conditions are all
%   LevelFlightConstraints -- they differ ONLY in flight state (altitude,
%   Mach) and power setting (AB vs. mil, e.g. Cruise is dry/mil power), not
%   in load factor or excess-power demand.
%
%   All physics, the A/B/C/D assembly, the non-finite self-guard, and the
%   equation citation live in MasterEquationConstraint -- this class only
%   fixes n=1 and Ps=0. See
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.

    methods

        function obj = LevelFlightConstraint(name, state, aero, prop, beta, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, 1.0, 0.0, powerSetting);
        end

    end

end

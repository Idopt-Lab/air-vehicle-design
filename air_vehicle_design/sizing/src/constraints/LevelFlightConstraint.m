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
%   fixes n=1 and Ps=0.

    methods

        function obj = LevelFlightConstraint(name, state, aero, prop, beta, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                powerSetting (1,1) string = "AB"   % rating validated by the injected prop (fighter "mil"/"AB", transport "cont"/"TO"/"max")
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, 1.0, 0.0, powerSetting);
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop (n=1, Ps=0; power setting validated from the
        %   condition). Uniform factory dispatched by ConstraintType; see
        %   ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach);
            powerSetting = MasterEquationConstraint.requirePowerSetting(cond);
            obj = LevelFlightConstraint(string(cond.name), state, aero, prop, ...
                cond.beta, powerSetting);
        end

    end

end

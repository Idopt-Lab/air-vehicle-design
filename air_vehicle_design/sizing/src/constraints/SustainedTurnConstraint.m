classdef SustainedTurnConstraint < MasterEquationConstraint
%SUSTAINEDTURNCONSTRAINT  Mattingly Master Equation, sustained turn (n>1,
%   Ps=0).
%
%   The Master-Equation specialization for a steady, level turn held at load
%   factor n>1 with zero specific excess power (Ps=0: sustained, not
%   instantaneous). The induced-drag B and C terms carry the elevated n; the
%   D term vanishes. The F-16 "Combat Turn 1" (n=4.5) and "Combat Turn 2"
%   (n=1.4) conditions are both SustainedTurnConstraints.
%
%   All physics and the citation live in MasterEquationConstraint; this class
%   only fixes Ps=0 and takes n as an input.

    methods

        function obj = SustainedTurnConstraint(name, state, aero, prop, beta, n, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive}
                powerSetting (1,1) string = "AB"   % rating validated by the injected prop (fighter "mil"/"AB", transport "cont"/"TO"/"max")
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, n, 0.0, powerSetting);
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop (Ps=0; load factor n and power setting read from
        %   the condition). Uniform factory dispatched by ConstraintType; see
        %   ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach);
            powerSetting = MasterEquationConstraint.requirePowerSetting(cond);
            obj = SustainedTurnConstraint(string(cond.name), state, aero, prop, ...
                cond.beta, cond.n, powerSetting);
        end

    end

end

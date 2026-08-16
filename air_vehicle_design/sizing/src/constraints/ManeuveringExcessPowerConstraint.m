classdef ManeuveringExcessPowerConstraint < MasterEquationConstraint
%MANEUVERINGEXCESSPOWERCONSTRAINT  Mattingly Master Equation, maneuvering
%   climb/acceleration (n>1 AND Ps>0).
%
%   The Master-Equation specialization that exposes BOTH the load factor n and
%   the specific excess power Ps as inputs -- the general (n>1, Ps>0) case the
%   two thin siblings each fix half of (ExcessPowerConstraint fixes n=1,
%   SustainedTurnConstraint fixes Ps=0). Models a maneuvering-energy point:
%   turn while still climbing/accelerating.
%
%   All physics and the citation live in MasterEquationConstraint (Mattingly
%   Master Equation; cf. metabook_data.md "Sustained Maneuver/Turn
%   Constraint" Eq. 4.33 and "Cruise Constraint" Eq. 4.34); this class only
%   widens the constructor to take n and Ps together.
%
%   n must be positive and Ps non-negative (the parent's bounds); the parent
%   handles the general case, so no extra lower bounds are imposed here.

    methods

        function obj = ManeuveringExcessPowerConstraint(name, state, aero, prop, beta, n, Ps, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive}
                Ps    (1,1) double {mustBeNonnegative}
                powerSetting (1,1) string = "AB"   % rating validated by the injected prop (fighter "mil"/"AB", transport "cont"/"TO"/"max")
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, n, Ps, powerSetting);
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop. Load factor n and specific excess power Ps are
        %   both read from the condition (cond.n, cond.Ps_fps), the power
        %   setting via MasterEquationConstraint.requirePowerSetting. Uniform
        %   factory dispatched by ConstraintType; see
        %   ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach);
            powerSetting = MasterEquationConstraint.requirePowerSetting(cond);
            obj = ManeuveringExcessPowerConstraint(string(cond.name), state, aero, prop, ...
                cond.beta, cond.n, cond.Ps_fps, powerSetting);
        end

    end

end

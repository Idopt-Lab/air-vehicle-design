classdef ManeuveringExcessPowerConstraint < MasterEquationConstraint
%MANEUVERINGEXCESSPOWERCONSTRAINT  Mattingly Master Equation, maneuvering
%   climb/acceleration (n>1 AND Ps>0).
%
%   The Master-Equation specialization that exposes BOTH the load factor n and
%   the specific excess power Ps as inputs -- the general (n>1, Ps>0) case that
%   the two thin siblings each fix half of: ExcessPowerConstraint fixes n=1
%   (level acceleration/climb), SustainedTurnConstraint fixes Ps=0 (sustained
%   turn). A maneuvering-energy point ("turn while still climbing/accelerating"
%   -- e.g. a sustained-g energy-maneuverability requirement that also demands
%   positive Ps) needs both non-trivial, which is exactly this class. The
%   elevated n feeds the induced-drag B and camber C terms; the positive Ps
%   feeds the excess-power D term.
%
%   All physics, the A/B/C/D assembly, the non-finite self-guard, and the
%   equation citation live in MasterEquationConstraint (Mattingly Master
%   Equation; cf. docs/reference_extracts/metabook_data.md "Sustained
%   Maneuver/Turn Constraint" Eq. 4.33 and "Cruise Constraint" Eq. 4.34 for the
%   equivalent q*CD0/(W/S) + (W/S)*n^2/(q*pi*AR*e) master-eq form) -- this class
%   only widens the constructor to take n and Ps together and pass them
%   through.
%
%   VALIDATION. n must be positive and Ps non-negative -- the same bounds the
%   parent enforces. The class is INTENDED for n>1 and Ps>0, but the parent
%   already handles the general case correctly (n=1 or Ps=0 simply zero the
%   corresponding term), so no artificial lower bounds beyond the parent's are
%   imposed here.

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
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
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

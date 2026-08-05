classdef ExcessPowerConstraint < MasterEquationConstraint
%EXCESSPOWERCONSTRAINT  Mattingly Master Equation, specific-excess-power
%   demand (Ps>0, n=1).
%
%   The Master-Equation specialization for a climb/acceleration requirement
%   expressed as a required specific excess power Ps>0 in level (n=1.0)
%   flight: the D = (beta/alpha)*(Ps/V) term is now active (nonzero), on top
%   of the usual zero-lift and induced-drag terms. The F-16 "Excess Power"
%   condition (Ps=500 ft/s at 10,000 ft, M=0.87) is an ExcessPowerConstraint.
%
%   All physics, the A/B/C/D assembly, the non-finite self-guard, and the
%   equation citation live in MasterEquationConstraint -- this class only
%   fixes n=1 and takes Ps as an input.

    methods

        function obj = ExcessPowerConstraint(name, state, aero, prop, beta, Ps, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                Ps    (1,1) double {mustBeNonnegative}
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, 1.0, Ps, powerSetting);
        end

    end

end

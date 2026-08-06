classdef MasterEqTestConstraint < MasterEquationConstraint
%MASTEREQTESTCONSTRAINT  Concrete MasterEquationConstraint test double.
%
%   MasterEquationConstraint is abstract -- it is instantiated in production
%   only through its three specializations (LevelFlight n=1/Ps=0,
%   SustainedTurn n>1/Ps=0, ExcessPower Ps>0/n=1), each of which fixes some
%   of (n, Ps). A few generic Master-Equation algebra checks want the FULL
%   (n, Ps) constructor at once -- e.g. verifying the A/B/C/D assembly with
%   both n>1 AND Ps>0 active in one call -- which no single specialization
%   allows. This thin subclass exposes MasterEquationConstraint's full
%   constructor unchanged, adding no equation code, purely so those generic
%   checks can drive the shared Master-Equation implementation directly.
%
%   Used only by tests. Not part of the production hierarchy -- production
%   code always builds one of the three specializations.

    methods

        function obj = MasterEqTestConstraint(name, state, aero, prop, beta, n, Ps, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive} = 1.0
                Ps    (1,1) double {mustBeNonnegative} = 0.0
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
            end
            obj@MasterEquationConstraint(name, state, aero, prop, beta, n, Ps, powerSetting);
        end

    end

end

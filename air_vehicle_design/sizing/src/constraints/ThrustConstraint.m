classdef ThrustConstraint < Both_WbyS_TbyW
%THRUSTCONSTRAINT  Mattingly "Master Equation" point-performance constraint.
%
%   Generic Layer-1 constraint: given a flight condition (AircraftState),
%   a load factor n, a required specific excess power Ps, a weight fraction
%   beta = W/W_TO, and the current-iteration aerodynamics/propulsion
%   discipline objects, returns the thrust-to-weight ratio required to
%   sustain that condition as a function of wing loading W/S. Belongs to the
%   Both_WbyS_TbyW category (see that class's header) -- it supplies the
%   A/B/C/D terms below; Both_WbyS_TbyW assembles them into required_TW(WS).
%
%   One instance models one point-performance condition (cruise, dash/max
%   Mach, sustained turn, climb, takeoff, ...) -- the equation is identical
%   across all of them; only (state, beta, n, Ps) differ.  alpha (thrust
%   lapse) and CD0/K1/K2 (drag polar) are pulled fresh from prop/aero each
%   call, so the constraint tracks the current sizing-loop iteration and
%   fidelity level automatically (never hardcoded here).
%
%   EQUATION  [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002,
%   the point-performance "Master Equation" specialized to steady,
%   wings-level flight -- see also NPTEL_Fighter_Aircraft_Sizing.ipynb,
%   "Point Performance using Mattingly's Master Equation"]:
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n * beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   where q, V come from AircraftState; CD0, K1, K2 from aero.drag_polar(state);
%   alpha from prop.thrust_lapse(state) (AB/max-power lapse per PropulsionBase
%   convention -- use a 100%-AB flight condition when instantiating for an
%   afterburning point).  beta, n, Ps are stakeholder/mission inputs specific
%   to the condition being modeled (e.g. F-16 Max Mach: beta=0.8997, n=1.0,
%   Ps=0 at 36,000 ft / M=1.60 -- see sizing/docs/subplans/06_constraint_analysis.md).

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Max Mach"
    end

    properties (SetAccess = private)
        state   % AircraftState -- flight condition (altitude, Mach)
        aero    % AerodynamicsBase -- supplies CD0, K1, K2 via drag_polar(state)
        prop    % PropulsionBase -- supplies alpha via thrust_lapse(state)
        beta    % double -- weight fraction W/W_TO at this condition
        n       % double -- load factor
        Ps      % double, ft/s -- required specific excess power (0 for sustained flight)
    end

    methods

        function obj = ThrustConstraint(name, state, aero, prop, beta, n, Ps)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive} = 1.0
                Ps    (1,1) double {mustBeNonnegative} = 0.0
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.prop  = prop;
            obj.beta  = beta;
            obj.n     = n;
            obj.Ps    = Ps;
        end

    end

    methods (Access = protected)
        %COMPUTE_A/B/C/D  Master Equation terms, see class header for the
        %   equation and citation. Each pulls alpha (thrust lapse) and
        %   CD0/K1/K2 (drag polar) fresh from prop/aero, so the constraint
        %   tracks the current sizing-loop iteration and fidelity level.

        function A = compute_A(obj)
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.prop.thrust_lapse(obj.state);
            q     = obj.state.q;
            A = q * polar.CD0 / alpha;
        end

        function B = compute_B(obj)
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.prop.thrust_lapse(obj.state);
            q     = obj.state.q;
            B = (q / alpha) * polar.K1 * (obj.n * obj.beta / q)^2;
        end

        function C = compute_C(obj)
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.prop.thrust_lapse(obj.state);
            C = polar.K2 * obj.n * obj.beta / alpha;
        end

        function D = compute_D(obj)
            alpha = obj.prop.thrust_lapse(obj.state);
            V     = obj.state.V;
            D = (obj.beta / alpha) * (obj.Ps / V);
        end

    end

end

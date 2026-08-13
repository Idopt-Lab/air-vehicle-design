classdef StallConstraint < Only_WbyS
%STALLCONSTRAINT  Stall-speed upper bound on wing loading.
%
%   Generic Layer-1 constraint. Given a flight condition (AircraftState) at
%   which the stall-speed requirement is specified, and the current-iteration
%   aero discipline object, it returns the upper bound this requirement imposes
%   on wing loading W/S -- not a required T/W. Stall is an unpowered
%   (idle-thrust) condition, so it belongs to the Only_WbyS category (same as
%   LandingConstraint): the aggregator reads WS_max() as a vertical W/S wall.
%   CLmax is pulled fresh from aero.get_CLmax(state) each call, not a
%   constraint input.
%
%   EQUATION [level, unaccelerated flight at CLmax: lift equals weight,
%   L = W_TO = q*S*CLmax => W_TO/S = q*CLmax, with q = 0.5*rho*V^2 the dynamic
%   pressure at the stall condition -- Raymer, "Aircraft Design: A Conceptual
%   Approach," 6th ed., AIAA, 2018, ch. 5, Eq. 5.5
%   (V_stall = sqrt(2*(W/S)/(rho*CLmax))) rearranged for W/S; matches
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's Stall class (cells 10-12,
%   compute_WbyS_Npm2 = 0.5*rho*V^2*CLmax)]:
%
%     W_TO/S <= q * CLmax
%
%   where q, rho, V come from the AircraftState supplied at construction (the
%   F-16's Stall condition is Mach 0.217466 at sea level -- Brandt F-16A.xls
%   "Ps" sheet cell B10, a row in examples/F16A/inputs/f16a_requirements.md);
%   CLmax from aero.get_CLmax(state) (clean CLmax -- the AerodynamicsBase
%   interface has no flapped-configuration argument yet, deferred TODO
%   ToDo_Darshan.md §1).

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Stall"
    end

    properties (SetAccess = private)
        state   % AircraftState -- flight condition at which the stall-speed requirement is specified
        aero    % AerodynamicsBase -- supplies CLmax via get_CLmax(state)
    end

    methods

        function obj = StallConstraint(name, state, aero)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
        end

        function WS = WS_max(obj)
        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] the stall-speed
        %   requirement imposes. See class header for the equation and
        %   citation. CLmax is pulled fresh from the aero discipline object
        %   each call, so this tracks the current-iteration aerodynamics.
            CLmax = obj.aero.get_CLmax(obj.state);
            WS = obj.state.q * CLmax;
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, ~)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero (Stall is unpowered, so prop is accepted for a uniform
        %   factory signature but unused). Uniform factory dispatched by
        %   ConstraintType; see ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach);
            obj = StallConstraint(string(cond.name), state, aero);
        end

    end

end

classdef StallConstraint < Only_WbyS
%STALLCONSTRAINT  Stall-speed upper bound on wing loading.
%
%   Generic Layer-1 constraint. Given the flight condition at which the
%   stall-speed requirement is specified and the aero object, it returns the
%   upper bound on wing loading W/S -- not a required T/W. Stall is unpowered:
%   Only_WbyS category, read as a vertical W/S wall. CLmax is pulled fresh from
%   aero.get_CLmax(state) each call.
%
%   EQUATION [level flight at CLmax, L = W_TO = q*S*CLmax => W_TO/S = q*CLmax --
%   Raymer 6th ed., AIAA 2018, ch. 5, Eq. 5.5 rearranged for W/S; matches
%   NPTEL_Fighter_Aircraft_Sizing.ipynb Stall (cells 10-12)]:
%
%     W_TO/S <= q * CLmax
%
%   q, rho, V come from the AircraftState at construction (the F-16 Stall
%   condition is Mach 0.217466 at sea level -- Brandt F-16A.xls "Ps" B10);
%   CLmax from aero.get_CLmax(state) (clean CLmax).

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

classdef StallConstraint < Only_WbyS
%STALLCONSTRAINT  Stall-speed upper bound on wing loading.
%
%   Generic Layer-1 constraint: given a flight condition (AircraftState) at
%   which the stall-speed requirement is specified, and the current-
%   iteration aerodynamics discipline object, returns the upper bound this
%   requirement imposes on wing loading W/S -- NOT a required T/W. Belongs
%   to the Only_WbyS category (see that class's header), same as
%   LandingConstraint: stall is an unpowered (idle-thrust) condition with no
%   real "required T/W" to derive, so Only_WbyS supplies required_TW(WS) by
%   encoding this class's WS_max() as a vertical wall. CLmax is pulled fresh
%   from aero.get_CLmax(state) each call -- not a constraint input, same
%   convention as TakeoffConstraint/LandingConstraint (see
%   sizing/docs/subplans/06_constraint_analysis.md, "CLmax is NOT a
%   constraint input").
%
%   EQUATION [level, unaccelerated flight at CLmax: lift equals weight,
%   L = W_TO = q*S*CLmax => W_TO/S = q*CLmax, with q = 0.5*rho*V^2 the
%   dynamic pressure at the stall condition -- Raymer, "Aircraft Design: A
%   Conceptual Approach," 6th ed., AIAA, 2018, ch. 5, Eq. 5.5
%   (V_stall = sqrt(2*(W/S)/(rho*CLmax))) rearranged for W/S; matches
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's Stall class (cells 10-12,
%   class Stall(Only_WbyS): compute_WbyS_Npm2 = 0.5*rho*V^2*CLmax), the
%   notebook subplans/06_constraint_analysis.md cites as the inspiration for
%   this class hierarchy]:
%
%     W_TO/S <= q * CLmax
%
%   where q, rho, V come from the AircraftState supplied at construction --
%   the flight condition at which the stall-speed requirement is defined
%   (e.g. the F-16's Stall condition: Mach 0.217466 at sea level [Brandt
%   F-16A.xls, "Ps" sheet, cell B10 -- see F16Baseline.m's
%   b.constraints.stall.mach and F16ConstraintSet.m's STALL_MACH, same
%   value] -- not yet a row in examples/F16A/Constraints.xlsx, unlike the
%   other 8 F-16 conditions; flag for spreadsheet backfill, same pattern as
%   other documented Constraints.xlsx gaps in this framework); CLmax from
%   aero.get_CLmax(state) (clean CLmax -- the generic AerodynamicsBase
%   interface has no flapped-configuration argument yet, same documented
%   gap as TakeoffConstraint.m/LandingConstraint.m).

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

end

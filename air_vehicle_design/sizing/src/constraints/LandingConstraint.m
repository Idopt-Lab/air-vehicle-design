classdef LandingConstraint < Only_WbyS
%LANDINGCONSTRAINT  Landing ground-roll upper bound on wing loading.
%
%   Generic Layer-1 constraint. Given a sea-level landing flight condition
%   (AircraftState), a required free-roll/braking ground-roll distance S_FR, a
%   braking-surface friction coefficient mu, a touchdown-speed margin k_L, and
%   the current-iteration aero discipline object, it returns the upper bound
%   this landing requirement imposes on wing loading W/S -- not a required T/W.
%   This condition constrains W/S directly and has no thrust dependence
%   (idle/braking, not powered flight), so it belongs to the Only_WbyS
%   category: the aggregator reads WS_max() as a vertical W/S wall.
%
%   CLmax_land/CD0_land are pulled fresh from the aero object each call.
%   get_CLmax_L/get_Delta_CD0_L are flapped-landing methods every F16AeroLN
%   class implements but which are NOT part of the abstract AerodynamicsBase
%   interface (see "NOTE ON CLmax/CD0 BASIS"); any aero passed here must
%   implement them.
%
%   EQUATION [landing ground-roll-with-braking sizing relation: touchdown
%   speed V_TD = k_L*V_stall decelerates under braking friction plus
%   aerodynamic drag, a_avg = g*(mu + 0.83*CD0/CLmax_land), S_FR = V_TD^2 /
%   (2*a_avg), with V_stall^2 = 2*(W/S)/(rho*CLmax_land), solved for W/S. The
%   0.83 is a velocity-averaging factor. Roskam, "Airplane Design, Part I,"
%   DARcorporation, Ch. 3 landing-distance sizing, Military method. NOT Raymer
%   (ch. 5 gives the statistical FAR correlation, no mu/CD0/k_L term).
%   Reproduces Brandt's landing W/S wall to <0.1% when fed Brandt's own
%   flapped CLmax_land/CD0 -- see TestLandingConstraint.m]:
%
%     W_TO/S <= rho * g * S_FR * (mu * CLmax_land + 0.83 * CD0_land) / (k_L^2 * beta)
%
%   rho is sea-level density; g is standard gravity (same English lbf/lbf
%   basis as TakeoffConstraint.m); CLmax_land from get_CLmax_L(), CD0_land
%   from drag_polar(state).CD0 + get_Delta_CD0_L(...) (flapped); mu is the
%   braking-surface friction coefficient (a runway property, not defaulted);
%   k_L is the touchdown-speed margin V_TD/V_stall (1.3); beta is the landing
%   weight fraction (1.0). Condition values:
%   examples/F16A/inputs/f16a_requirements.md.
%
%   NOTE ON CLmax/CD0 BASIS: WS_max() uses the FLAPPED landing configuration,
%   not clean values. get_CLmax_L/get_Delta_CD0_L are not on the abstract
%   AerodynamicsBase interface, so any aero passed here must implement them.
%   get_Delta_CD0_L's arity is not uniform across fidelity levels (F16AeroL1/L2
%   take none, F16AeroL3 takes the flight state); WS_max() dispatches via
%   metaclass reflection on InputNames. WS_max may sit below Brandt's
%   flight-calibrated value: the flap/slat buildups are textbook estimates, so
%   TestLandingConstraint.m's F-16 diagnostic is not an exact-match assertion.

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Landing"
    end

    properties (SetAccess = private)
        state   % AircraftState -- sea-level landing flight condition
        aero    % AerodynamicsBase -- supplies CLmax_land/CD0_land via get_CLmax_L()/(drag_polar(state).CD0 + get_Delta_CD0_L(...))
        S_FR    % double, ft -- required landing free-roll/braking ground-roll distance
        mu      % double -- braking-surface friction coefficient
        beta    % double -- landing weight fraction W_land/W_TO
        k_L     % double -- touchdown speed margin V_TD/V_stall
    end

    properties (Constant, Access = private)
        G_FTS2 = 32.174   % ft/s^2 -- standard gravity
        DRAG_FACTOR = 0.83   % -- ground-roll velocity-averaging factor on the CD0 term, see class header
    end

    methods

        function obj = LandingConstraint(name, state, aero, S_FR, mu, beta, k_L)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                S_FR  (1,1) double {mustBePositive}
                mu    (1,1) double {mustBePositive}
                beta  (1,1) double {mustBePositive} = 1.0
                k_L   (1,1) double {mustBePositive} = 1.3
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.S_FR  = S_FR;
            obj.mu    = mu;
            obj.beta  = beta;
            obj.k_L   = k_L;
        end

        function WS = WS_max(obj)
        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] this landing
        %   requirement imposes. See class header for the equation and
        %   citation. CLmax_land/CD0_land are the FLAPPED landing values,
        %   pulled fresh from the aero object each call.
            CLmax_land     = obj.aero.get_CLmax_L();
            Delta_CD0_land = LandingConstraint.get_Delta_CD0_L_dispatched(obj.aero, obj.state);
            CD0_land       = obj.aero.drag_polar(obj.state).CD0 + Delta_CD0_land;
            rho            = obj.state.rho;
            g              = LandingConstraint.G_FTS2;

            WS = (rho * g * obj.S_FR * (obj.mu * CLmax_land + LandingConstraint.DRAG_FACTOR * CD0_land)) ...
                / (obj.k_L^2 * obj.beta);
        end

    end

    methods (Static, Access = private)

        function delta = get_Delta_CD0_L_dispatched(aero, state)
        %GET_DELTA_CD0_L_DISPATCHED  Calls aero.get_Delta_CD0_L() with or
        %   without the flight state, matching the arity aero's fidelity level
        %   declares (F16AeroL1/L2 take none, F16AeroL3 takes state).
        %   Dispatches via metaclass reflection on InputNames, since nargin on
        %   a bound instance-method handle returns -1.
            mc = metaclass(aero);
            m  = findobj(mc.MethodList, 'Name', 'get_Delta_CD0_L');
            if isempty(m)
                error('LandingConstraint:missingGetDeltaCD0L', ...
                    ['aero (class %s) has no get_Delta_CD0_L method -- every ', ...
                     'AerodynamicsBase subclass passed to LandingConstraint must ', ...
                     'implement the flapped-landing get_CLmax_L/get_Delta_CD0_L ', ...
                     'methods (see class header "NOTE ON CLmax/CD0 BASIS").'], class(aero));
            end
            if numel(m.InputNames) >= 2
                delta = aero.get_Delta_CD0_L(state);
            else
                delta = aero.get_Delta_CD0_L();
            end
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, ~)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero. Landing reads no Mach -- a nominal low-Mach
        %   sea-level state supplies rho only; prop is accepted for a uniform
        %   factory signature but unused. Uniform factory dispatched by
        %   ConstraintType; see ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, 0.1);
            obj = LandingConstraint(string(cond.name), state, aero, ...
                cond.distance_ft, cond.mu, cond.beta, cond.k_factor);
        end

    end

end

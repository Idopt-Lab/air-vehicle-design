classdef InstantaneousTurnConstraint < Both_WbyS_TbyW
%INSTANTANEOUSTURNCONSTRAINT  Instantaneous-turn constraint, Aero 481
%   "vertical maneuver" formulation (turn-rate driven).
%
%   Generic Layer-1 constraint. Given a required instantaneous turn rate
%   [deg/s], a flight condition (AircraftState), a power setting, and the
%   injected aero/prop objects, it returns the T/W required to hold that turn
%   rate vs. wing loading W/S. The load factor n is computed once in the
%   constructor from the turn rate and the state's true airspeed.
%   Both_WbyS_TbyW category.
%
%   PROVENANCE. The Aero 481 student-code formulation
%   (+Constraints/InstantaneousTurn.m), with two deliberate changes:
%   (a) g correction: Aero 481 sets g = 9.087 (typo for 9.807 m/s^2); this
%       class uses English g = 32.174 ft/s^2, so the typo is moot.
%   (b) Thrust-lapse alpha added: Aero 481 models no lapse; this class divides
%       by alpha so the result sits on the sea-level-static T_SL/W_TO axis.
%
%   DERIVATION:
%     n     = omega * V / g            (turn rate omega [rad/s], V [ft/s])
%     CL    = n * (W/S) / q
%     CD    = CD0 + K1 * CL^2          (repo K-convention, clean polar)
%     T/W   = q * CD / (n * (W/S))     (Aero 481 "vertical maneuver": Ps=0)
%   dividing by alpha expands to
%     required_TW(WS) = (1/alpha) * ( q*CD0 ./ (n*WS) + n*K1 .* WS / q )
%   CD0/K1 come from aero.drag_polar(state), CLEAN (no flaps/gear).
%
%   ALTERNATIVE standard form (NOT used here): the textbook instantaneous-turn
%   constraint is a CLmax-limited W/S wall, W/S <= q*CLmax/n (an Only_WbyS), since the
%   limit is wing lift, not thrust. Aero 481's thrust-condition form is
%   nonstandard; this class implements it as specified.
%
%   _TODO: pin this formulation to a primary source (Raymer ch. 5
%   instantaneous-turn / corner-speed). Aero 481 code is provenance, not a
%   primary reference; a test should fail loudly on the missing citation.

    properties (SetAccess = protected)
        name          % string -- condition label, e.g. "Instantaneous Turn"
    end

    properties (SetAccess = private)
        state         % AircraftState -- flight condition (altitude, Mach)
        aero          % AerodynamicsBase -- supplies CD0, K1 via drag_polar(state) (clean)
        prop          % PropulsionBase   -- supplies alpha via thrust_lapse(state, rating)
        turn_rate_dps % double, deg/s -- required instantaneous turn rate
        powerSetting  % string -- engine power rating passed to prop.thrust_lapse (fighter "mil"/"AB", transport "cont"/"TO"/"max")
        n             % double -- load factor implied by the turn rate (computed in the constructor)
    end

    properties (Constant, Access = private)
        G_FTS2 = 32.174   % ft/s^2 -- English standard gravity (see PROVENANCE (a))
    end

    methods

        function obj = InstantaneousTurnConstraint(name, state, aero, prop, turn_rate_dps, powerSetting)
            arguments
                name          (1,1) string
                state         (1,1) AircraftState
                aero          (1,1) AerodynamicsBase
                prop          (1,1) PropulsionBase
                turn_rate_dps (1,1) double {mustBePositive}
                powerSetting  (1,1) string = "AB"
            end
            obj.name          = name;
            obj.state         = state;
            obj.aero          = aero;
            obj.prop          = prop;
            obj.turn_rate_dps = turn_rate_dps;
            obj.powerSetting  = powerSetting;

            % Load factor from the turn rate: n = omega*V/g (omega in rad/s,
            % V the state's true airspeed, g English). See PROVENANCE (a).
            obj.n = deg2rad(turn_rate_dps) * state.V / InstantaneousTurnConstraint.G_FTS2;
        end

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required to hold the instantaneous turn rate at wing
        %   loading(s) WS [lbf/ft^2], per the class-header derivation:
        %
        %     TW = (1/alpha) * ( q*CD0 ./ (n*WS) + n*K1 .* WS / q )
        %
        %   WS may be scalar or array; TW is returned the same size. CD0/K1 are
        %   the CLEAN drag polar, pulled fresh from aero each call; alpha from
        %   get_alpha. n was computed in the constructor from the turn rate.
        %
        %   Fails loudly on a non-finite A/B coefficient: a NaN required_TW is
        %   silently dropped from ConstraintAnalysis's max() envelope.
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.get_alpha();
            q     = obj.state.q;

            A_coeff = q * polar.CD0 / (alpha * obj.n);   % coefficient of 1/WS
            B_coeff = obj.n * polar.K1 / (alpha * q);    % coefficient of WS
            coeffs  = [A_coeff, B_coeff];
            if ~all(isfinite(coeffs))
                where = sprintf('This condition is at alt=%g ft, M=%.4f.', ...
                    obj.state.altitude_ft, obj.state.mach);
                error('InstantaneousTurnConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": instantaneous-turn T/W coefficient(s) are ', ...
                     'non-finite [A B] = %s (n = %g, CD0 = %s, K1 = %s, ', ...
                     'alpha = %s). The usual cause is a drag polar or thrust ', ...
                     'lapse not modeled at this flight condition -- e.g. ', ...
                     'AeroL2/AeroL3 return NaN CD0/K1 across the unmodeled ', ...
                     'transonic band by design. %s'], ...
                    obj.name, mat2str(coeffs, 6), obj.n, mat2str(polar.CD0, 6), ...
                    mat2str(polar.K1, 6), mat2str(alpha, 6), where);
            end
            TW = A_coeff ./ WS + B_coeff .* WS;
        end

    end

    methods (Access = protected)

        function alpha = get_alpha(obj)
        %GET_ALPHA  Thrust lapse at this condition's power setting, validated by
        %   the injected prop. Same logic as MasterEquationConstraint.get_alpha
        %   (this class is a Both_WbyS_TbyW sibling, not a child, of it).
            alpha = obj.prop.thrust_lapse(obj.state, obj.powerSetting);
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop. Reads cond.turn_rate_dps and the flight
        %   condition (cond.altitude_ft, cond.mach); the power setting via
        %   MasterEquationConstraint.requirePowerSetting. Uniform factory
        %   dispatched by ConstraintType.
            state = AircraftState(cond.altitude_ft, cond.mach);
            powerSetting = MasterEquationConstraint.requirePowerSetting(cond);
            obj = InstantaneousTurnConstraint(string(cond.name), state, aero, prop, ...
                cond.turn_rate_dps, powerSetting);
        end

    end

end

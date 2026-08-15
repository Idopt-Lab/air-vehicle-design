classdef InstantaneousTurnConstraint < Both_WbyS_TbyW
%INSTANTANEOUSTURNCONSTRAINT  Instantaneous-turn constraint, Aero 481
%   "vertical maneuver" formulation (turn-rate driven).
%
%   Generic Layer-1 constraint. Given a required instantaneous turn rate
%   [deg/s], a flight condition (AircraftState), a power setting, and the
%   injected aero/prop discipline objects, it returns the thrust-to-weight
%   ratio required to hold that turn rate as a function of wing loading W/S.
%   The load factor n implied by the turn rate is computed once in the
%   constructor from the turn rate and the state's true airspeed. Belongs to
%   the Both_WbyS_TbyW category.
%
%   PROVENANCE. This is the Aero 481 student-code formulation
%   (+Constraints/InstantaneousTurn.m), with TWO deliberate, documented
%   corrections/additions relative to that file:
%
%   (a) g CORRECTION. Aero 481's file sets g = 9.087 -- a transcription typo
%       for 9.807 m/s^2 (its own comment reads "define gravity (9.807 m/s^2)").
%       This class uses the English standard gravity g = 32.174 ft/s^2, so the
%       typo is moot, but it is flagged here so the discrepancy is on record.
%
%   (b) THRUST-LAPSE ALPHA ADDED. Aero 481 models no thrust lapse (its
%       T/W = q*CD/(n*W/S) is on an installed-thrust basis at altitude). This
%       class divides by alpha (get_alpha, mil/AB per powerSetting) so the
%       result sits on the same sea-level-static T_SL/W_TO axis as every other
%       constraint on this framework's diagram. This is a deliberate addition,
%       not part of the Aero 481 source.
%
%   DERIVATION (reproduced from the Aero 481 file, corrected/extended):
%     n     = omega * V / g            (turn rate omega [rad/s], V [ft/s])
%     CL    = n * (W/S) / q            (lift = n*W, CL = L/(q*S))
%     CD    = CD0 + K1 * CL^2          (repo K-convention, clean polar)
%     T/W   = q * CD / (n * (W/S))     (Aero 481 "vertical maneuver": Ps=0,
%                                       rearranged from Ps = V*(T-D)/W)
%   Substituting CL and CD and dividing by alpha expands to
%     required_TW(WS) = (1/alpha) * ( q*CD0 ./ (n*WS) + n*K1 .* WS / q )
%   CD0/K1 come from aero.drag_polar(state) in the CLEAN configuration -- an
%   instantaneous turn is a clean maneuver (no flaps/gear).
%
%   ALTERNATIVE / STANDARD FORM (NOT used here). The TEXTBOOK instantaneous-turn
%   constraint is a CLmax-limited W/S WALL, W/S <= q*CLmax/n (an Only_WbyS),
%   because an instantaneous turn trades stored energy (altitude/airspeed), not
%   thrust -- the limiting factor is the wing's ability to generate the lift for
%   load factor n, not the engine. Aero 481's divide-drag-by-n*(W/S) form treats
%   it instead as a thrust condition ("vertical maneuver"), which is a
%   nonstandard choice. This class implements the Aero 481 form (as specified)
%   but records the standard alternative here.
%
%   _TODO: pin this formulation to a primary source. Raymer ch. 5's
%   instantaneous-turn / corner-speed treatment (and the CLmax-limited W/S wall
%   above) is the citation this class should ultimately carry; the Aero 481
%   student code is provenance, not a primary reference. Flagged for the
%   coordinator -- a test should fail loudly against the missing primary
%   citation rather than have a plausible one stubbed in.

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

            % Load factor from the required turn rate: n = omega*V/g, with omega
            % in rad/s (deg2rad(turn_rate_dps)) and V the state's true airspeed.
            % g = 32.174 ft/s^2 (English), correcting Aero 481's 9.087 typo --
            % see PROVENANCE (a).
            obj.n = deg2rad(turn_rate_dps) * state.V / InstantaneousTurnConstraint.G_FTS2;
        end

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required to hold the instantaneous turn rate at wing
        %   loading(s) WS [lbf/ft^2], per the class-header derivation:
        %
        %     TW = (1/alpha) * ( q*CD0 ./ (n*WS) + n*K1 .* WS / q )
        %
        %   WS may be scalar or array; TW is returned the same size. CD0/K1 are
        %   the CLEAN drag polar (instantaneous turn is a clean maneuver),
        %   pulled fresh from aero each call; alpha from get_alpha (mil/AB per
        %   powerSetting). n was computed in the constructor from the turn rate.
        %
        %   FAILS LOUDLY on a non-finite A/B coefficient: CD0/K1 come from the
        %   aero drag polar and alpha from the prop thrust lapse, either of
        %   which can be non-finite (AeroL2/L3 return NaN CD0/K1 across the
        %   unmodeled transonic band by design, and a mis-injected discipline
        %   object can too). A NaN required_TW is silently omitted from
        %   ConstraintAnalysis's max() envelope, so error here instead --
        %   mirrors MasterEquationConstraint's guard.
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
        %GET_ALPHA  Thrust lapse at this condition's power setting. The rating
        %   is passed straight to the injected prop, which validates it against
        %   the ratings its engine has (fighter "mil"/"AB"; transport
        %   "cont"/"TO"/"max"). Same logic as MasterEquationConstraint.get_alpha,
        %   here because InstantaneousTurnConstraint is a Both_WbyS_TbyW sibling
        %   of the Master-Equation subtree, not a child of it.
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

classdef TakeoffFieldLengthConstraint < Both_WbyS_TbyW
%TAKEOFFFIELDLENGTHCONSTRAINT  FAR-25 takeoff-field-length (Takeoff Parameter)
%   constraint.
%
%   Generic Layer-1 constraint. Given a required balanced-field length (BFL)
%   and the takeoff-field flight condition (an AircraftState), it returns the
%   thrust-to-weight ratio required to lift off within that field length as a
%   function of wing loading W/S. Belongs to the Both_WbyS_TbyW category and
%   supplies the required_TW(WS) that category declares abstract. The relation
%   is LINEAR THROUGH THE ORIGIN in W/S (unlike the Master-Equation takeoff
%   sibling, which adds a rolling-friction/drag constant C term).
%
%   FIELD AIR-DENSITY RATIO FROM THE STATE. The Takeoff-Parameter relation
%   scales with sigma = rho/rho_SL, the field air-density ratio. That IS the
%   density ratio the injected AircraftState already carries, so it is derived
%   from the state (sigma = state.rho / rho_SL, ISA sea-level density) rather
%   than passed as a separate input. A hot day near sea level (Example 4.2's
%   sigma = 0.95) is represented as the matching field DENSITY ALTITUDE: in
%   this ISA-only framework AircraftState(1742.4 ft) has sigma = 0.95000, so a
%   takeoff condition built at that altitude reproduces the metabook constant.
%
%   NO THRUST-LAPSE ALPHA AND NO PROP. Unlike the sibling Mattingly
%   TakeoffConstraint -- which divides its ground-roll thrust demand by the
%   engine thrust lapse alpha (T_SL/W_TO axis) -- the Takeoff Parameter (TOP)
%   correlation embeds the takeoff thrust model STATISTICALLY inside the 37.5
%   calibration constant (fit to a fleet of FAR-25 jets at their takeoff power
%   setting). The sigma above is the AIR-DENSITY ratio, not the engine thrust
%   lapse; dividing by a separately-modeled alpha would double-count the thrust
%   model, so this class takes no prop object and applies no alpha. The result
%   is already on the same sea-level-static T_SL/W_TO axis the diagram plots.
%   See the class-header contrast note in TakeoffConstraint.m.
%
%   CLmax_TO is pulled fresh from the injected aero object each call (through
%   aero.get_config_polar), not a constraint input, so the constraint tracks
%   the current sizing-loop iteration and fidelity level automatically.
%
%   EQUATION [Metabook (Aero 481 metabook), docs/reference_extracts/
%   metabook_data.md "§4.5 Takeoff Field Length," Eqs. 4.14-4.16; worked
%   Example 4.2, Eqs. 4.47-4.48]:
%
%     TOP25       = BFL / 37.5                                         (4.15)
%     T_SL/W_TO   = (W_TO/S) / (sigma * CLmax_TO * TOP25)             (4.16)
%
%   where BFL is the required balanced-field length [ft]; sigma = rho/rho_SL
%   is the field air-density ratio (derived from the state, see above);
%   CLmax_TO is the flapped-takeoff maximum lift coefficient
%   (aero.get_config_polar("takeoff_flaps_gear_down").CLmax); and 37.5 is the
%   FAR-25 Takeoff Parameter calibration constant (Eq. 4.15, English units,
%   BFL in ft). Example 4.2 hand-check: BFL = 12,000 ft gives TOP25 = 320.0
%   (Eq. 4.47), and with sigma = 0.95 the denominator constant is
%   0.95 * 320 = 304.0 (Eq. 4.48), so T/W = (W/S)/(304.0 * CLmax_TO).

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Takeoff Field Length"
    end

    properties (SetAccess = private)
        state   % AircraftState -- takeoff-field flight condition (sets sigma via rho)
        aero    % AerodynamicsBase -- supplies CLmax_TO via aero.get_config_polar("takeoff_flaps_gear_down").CLmax
        BFL_ft  % double, ft -- required balanced-field length
        sigma   % double -- field air-density ratio rho/rho_SL, derived from state.rho
    end

    properties (Constant, Access = private)
        TOP_CONSTANT = 37.5   % -- FAR-25 Takeoff Parameter calibration constant [Metabook Eq. 4.15]
        RHO_SL_SLUG_FT3 = 0.002376892413   % slug/ft^3 -- ISA sea-level density, atmosisa(0)=1.225 kg/m^3 (matches AircraftState)
    end

    methods

        function obj = TakeoffFieldLengthConstraint(name, state, aero, BFL_ft)
            arguments
                name   (1,1) string
                state  (1,1) AircraftState
                aero   (1,1) AerodynamicsBase
                BFL_ft (1,1) double {mustBePositive}
            end
            obj.name   = name;
            obj.state  = state;
            obj.aero   = aero;
            obj.BFL_ft = BFL_ft;
            % Field air-density ratio from the state's density (see class header).
            obj.sigma  = state.rho / TakeoffFieldLengthConstraint.RHO_SL_SLUG_FT3;
        end

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required to take off within BFL_ft at wing loading(s)
        %   WS [lbf/ft^2], per the Takeoff Parameter relation in the class
        %   header. Linear through the origin: TW = coeff * WS with
        %   coeff = 1/(sigma * CLmax_TO * TOP25). WS may be scalar or array;
        %   TW is returned the same size.
        %
        %   FAILS LOUDLY on a non-finite coefficient. CLmax_TO comes from the
        %   aero high-lift config, which can legitimately be non-finite (a
        %   mis-injected discipline object, or an unmodeled config). A NaN
        %   required_TW is silently omitted from ConstraintAnalysis's max()
        %   envelope, so an un-evaluable condition would read as SATISFIED off
        %   a curve that does not exist. Erroring here makes that a visible
        %   failure -- mirrors TakeoffConstraint's guard.
        %
        %   [Metabook Eqs. 4.15-4.16; worked Ex. 4.2 Eqs. 4.47-4.48.]
            CLmax_TO = obj.aero.get_config_polar("takeoff_flaps_gear_down").CLmax;
            TOP25    = obj.BFL_ft / TakeoffFieldLengthConstraint.TOP_CONSTANT;   % Eq. 4.15
            coeff    = 1 / (obj.sigma * CLmax_TO * TOP25);                        % Eq. 4.16 slope
            if ~isfinite(coeff)
                error('TakeoffFieldLengthConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": Takeoff-Parameter T/W slope is non-finite ', ...
                     '(coeff = %s) from sigma = %g, CLmax_TO = %s, TOP25 = %g. ', ...
                     'The usual cause is a flapped CLmax_TO that is not modeled ', ...
                     '(aero.get_config_polar takeoff_flaps_gear_down).'], ...
                    obj.name, mat2str(coeff, 6), obj.sigma, mat2str(CLmax_TO, 6), TOP25);
            end
            TW = coeff .* WS;   % Eq. 4.16
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, ~)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero. Reads cond.BFL_ft and the takeoff-field flight
        %   condition (cond.altitude_ft, and cond.mach when present -- a nominal
        %   low takeoff Mach otherwise, since only the density enters the TOP
        %   correlation). sigma is derived from that state's density. prop is
        %   accepted for a uniform factory signature but IGNORED -- the TOP
        %   correlation models takeoff thrust statistically and needs no
        %   propulsion object (see class header "NO THRUST-LAPSE ALPHA AND NO
        %   PROP"). Uniform factory dispatched by ConstraintType.
            if isfield(cond, 'mach') && ~isempty(cond.mach)
                mach = cond.mach;
            else
                mach = 0.2;   % nominal low takeoff Mach; only density enters Eq. 4.16
            end
            state = AircraftState(cond.altitude_ft, mach);
            obj = TakeoffFieldLengthConstraint(string(cond.name), state, aero, ...
                cond.BFL_ft);
        end

    end

end

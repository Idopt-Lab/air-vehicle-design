classdef CeilingConstraint < Only_TbyW
%CEILINGCONSTRAINT  Service-ceiling constraint (W/S-independent T/W floor,
%   minimum-T/W form).
%
%   Generic Layer-1 constraint. Given a ceiling flight condition, a required
%   residual climb gradient G, and the injected aero/prop objects, it returns
%   the minimum T/W that reaches the ceiling at SOME wing loading. Only_TbyW
%   category: a flat T/W floor, read as a horizontal line.
%
%   Minimum form (not ExcessPower): if only the ceiling ALTITUDE is specified,
%   the designer flies at the best speed. Minimising level-flight T/W over q
%   [metabook Eq. 4.29] gives T/W = 2*sqrt(CD0*K1) + G [Eq. 4.30], independent
%   of W/S -- hence a horizontal line (metabook Fig. 4.6). A fixed-speed
%   ExcessPower point gives a W/S-dependent U-curve whose minimum equals this
%   but rises away from the optimum, wrongly cutting the feasible region. Use
%   ExcessPower only for a ceiling specified by altitude AND speed.
%
%   EQUATION [metabook_data.md "§4.8 Ceiling," Eq. 4.30 with the Eq. 4.55
%   thrust-lapse conversion; worked Example 4.2, Eq. 4.56]:
%
%     T/W_altitude = 2*sqrt(CD0/(pi*AR*e)) + G          (4.30)
%     T_SL/W_TO    = (1/alpha) * ( 2*sqrt(CD0*K1) + G )  (4.30 + 4.55)
%
%   CD0, K1 from aero.drag_polar(state) (K1 = 1/(pi*AR*e)); alpha the thrust
%   lapse per the power setting; G the required residual gradient (small, e.g.
%   0.001). All pulled fresh each call.
%
%   POWER SETTING. alpha = prop.thrust_lapse(state, powerSetting), validated by
%   the injected prop (fighter "mil"/"AB"; transport "cont"/"TO"/"max").

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Ceiling"
    end

    properties (SetAccess = private)
        state         % AircraftState -- ceiling flight condition (altitude, Mach)
        aero          % AerodynamicsBase -- supplies CD0, K1 via drag_polar(state)
        prop          % PropulsionBase   -- supplies alpha via thrust_lapse(state)
        G             % double -- required residual climb gradient at the ceiling
        powerSetting  % string -- engine power rating passed to prop.thrust_lapse (fighter "mil"/"AB", transport "cont"/"TO"/"max")
    end

    methods

        function obj = CeilingConstraint(name, state, aero, prop, G, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                G     (1,1) double {mustBeNonnegative}
                powerSetting (1,1) string = "mil"
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.prop  = prop;
            obj.G     = G;
            obj.powerSetting = powerSetting;
        end

        function TW = TW_min(obj)
        %TW_MIN  Minimum T/W to reach the ceiling, per the class-header
        %   equation (metabook Eq. 4.30 + Eq. 4.55). W/S-independent --
        %   Only_TbyW.required_TW returns this at every W/S.
        %
        %   Fails loudly on a non-finite result: a NaN T/W floor is silently
        %   dropped from the aggregator's envelope.
        %
        %   [metabook Eqs. 4.30/4.55; worked Ex. 4.2 Eq. 4.56.]
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.get_alpha();

            TW = (1 / alpha) * (2 * sqrt(polar.CD0 * polar.K1) + obj.G);

            if ~isfinite(TW)
                where = sprintf('This condition is at alt=%g ft, M=%.4f.', ...
                    obj.state.altitude_ft, obj.state.mach);
                error('CeilingConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": ceiling T/W is non-finite (CD0=%g, ', ...
                     'K1=%g, alpha=%g, G=%g). The usual cause is a drag polar ', ...
                     'or thrust lapse not modeled at this flight condition. %s'], ...
                    obj.name, polar.CD0, polar.K1, alpha, obj.G, where);
            end
        end

    end

    methods (Access = protected)

        function alpha = get_alpha(obj)
        %GET_ALPHA  Thrust lapse at this ceiling's power setting, validated by
        %   the injected prop. Mirrors MasterEquationConstraint.get_alpha.
            alpha = obj.prop.thrust_lapse(obj.state, obj.powerSetting);
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop. Reads altitude_ft, mach (to build the ceiling
        %   flight state), G (the residual gradient), and power_setting.
        %   Uniform factory dispatched by ConstraintType; see
        %   ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach);
            powerSetting = MasterEquationConstraint.requirePowerSetting(cond);
            obj = CeilingConstraint(string(cond.name), state, aero, prop, ...
                cond.G, powerSetting);
        end

    end

end

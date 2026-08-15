classdef CeilingConstraint < Only_TbyW
%CEILINGCONSTRAINT  Service-ceiling constraint (W/S-independent T/W floor,
%   minimum-T/W form).
%
%   Generic Layer-1 constraint. Given a ceiling flight condition
%   (AircraftState), a required residual climb gradient G at the ceiling, and
%   the injected aero/prop discipline objects, it returns the minimum
%   thrust-to-weight ratio that lets the aircraft reach the ceiling at SOME
%   wing loading. It belongs to the Only_TbyW category: the requirement is a
%   flat T/W floor, so required_TW returns this same TW_min at every W/S, and
%   the aggregator reads it as a horizontal line.
%
%   WHY THE MINIMUM FORM (and NOT ExcessPower). If only the ceiling ALTITUDE
%   is specified (not a ceiling speed), the designer is free to fly the
%   ceiling at the best speed -- i.e. at the wing loading that minimises the
%   required T/W. Minimising the level-flight T/W = q*CD0/(W/S) +
%   K1*(W/S)/q over the dynamic pressure q gives the optimum
%   q = (W/S)*sqrt(1/(CD0*pi*AR*e)) [metabook Eq. 4.29] and the minimum
%   T/W = 2*sqrt(CD0*K1) + G [metabook Eq. 4.30] -- a value INDEPENDENT of
%   W/S. That is why the ceiling appears as a HORIZONTAL line on the
%   constraint diagram (metabook Fig. 4.6). Modelling the ceiling instead as
%   a fixed-speed ExcessPower point (the Mattingly master equation at one
%   flight condition) gives the W/S-DEPENDENT U-curve q*CD0/(alpha*W/S) +
%   ... , whose MINIMUM over W/S equals this same Eq. 4.30 value but which
%   rises above it away from the optimum -- so it wrongly cuts into the
%   feasible region at low and high W/S. Use this class, not ExcessPower, for
%   a ceiling specified by altitude only. (The F-35's "ceiling" is a
%   DIFFERENT requirement -- a fixed-speed climb at M1.6 -- which does map
%   onto ExcessPower via Ps = G*V; see the F-35 constraint set.)
%
%   EQUATION [metabook docs/reference_extracts/metabook_data.md "§4.8
%   Ceiling", Eq. 4.30 (minimum-T/W ceiling) with the Eq. 4.55 sea-level-
%   static thrust-lapse conversion; worked Example 4.2, Eq. 4.56]:
%
%     T/W_altitude = 2*sqrt(CD0/(pi*AR*e)) + G          (4.30)
%     T_SL/W_TO    = (1/alpha) * ( 2*sqrt(CD0*K1) + G )  (4.30 + 4.55)
%
%   with CD0, K1 from aero.drag_polar(state) at the ceiling condition
%   (K1 = 1/(pi*AR*e), so 2*sqrt(CD0/(pi*AR*e)) = 2*sqrt(CD0*K1)); alpha the
%   thrust lapse at that condition (per the power setting); and G the
%   required residual climb gradient at the ceiling (small, e.g. 0.001, so
%   the aircraft can still climb to the ceiling rather than only barely hold
%   it). CD0/K1 and alpha are pulled fresh each call, so the constraint
%   tracks the current sizing-loop iteration and fidelity level.
%
%   POWER SETTING. alpha is drawn on the basis the condition is constructed
%   with, exactly as MasterEquationConstraint: "AB" -> prop.thrust_lapse
%   (max-power), "mil" -> prop.thrust_lapse_mil_on_AB_scale (dry/military,
%   still on the AB T_SL scale). A transport ceiling is a mil-power point.

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Ceiling"
    end

    properties (SetAccess = private)
        state         % AircraftState -- ceiling flight condition (altitude, Mach)
        aero          % AerodynamicsBase -- supplies CD0, K1 via drag_polar(state)
        prop          % PropulsionBase   -- supplies alpha via thrust_lapse(state)
        G             % double -- required residual climb gradient at the ceiling
        powerSetting  % string "AB" or "mil" -- basis prop.thrust_lapse is drawn from
    end

    methods

        function obj = CeilingConstraint(name, state, aero, prop, G, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                G     (1,1) double {mustBeNonnegative}
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "mil"
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
        %   FAILS LOUDLY on a non-finite result: the drag polar or thrust
        %   lapse can be non-finite (a mis-injected discipline object, or an
        %   unmodeled transonic band), and a NaN T/W floor is silently
        %   dropped from the aggregator's envelope -- error here so an
        %   un-evaluable ceiling constraint is a visible failure.
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
        %GET_ALPHA  Thrust lapse on the basis this condition was constructed
        %   with: AB (prop.thrust_lapse) or mil
        %   (prop.thrust_lapse_mil_on_AB_scale). Mirrors
        %   MasterEquationConstraint.get_alpha.
            if obj.powerSetting == "mil"
                alpha = obj.prop.thrust_lapse_mil_on_AB_scale(obj.state);
            else
                alpha = obj.prop.thrust_lapse(obj.state);
            end
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

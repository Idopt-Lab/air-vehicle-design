classdef (Abstract) MasterEquationConstraint < Both_WbyS_TbyW
%MASTEREQUATIONCONSTRAINT  Mattingly "Master Equation" point-performance
%   constraint (abstract base of the thrust-condition subtree).
%
%   Generic Layer-1 constraint. Given a flight condition (AircraftState), a
%   load factor n, a required specific excess power Ps, a weight fraction
%   beta = W/W_TO, and the current-iteration aero/prop discipline objects, it
%   returns the thrust-to-weight ratio required to sustain the condition as a
%   function of wing loading W/S. Belongs to the Both_WbyS_TbyW category and
%   supplies the required_TW(WS) that category declares abstract. It is
%   instantiated through thin specializations that differ only in which of
%   (n, Ps, powerSetting) are fixed: LevelFlightConstraint (n=1, Ps=0),
%   SustainedTurnConstraint (n>1, Ps=0), ExcessPowerConstraint (Ps>0).
%
%   One instance models one condition (cruise, dash/max Mach, sustained turn,
%   climb, ...). alpha (thrust lapse) and CD0/K1/K2 (drag polar) are pulled
%   fresh from prop/aero each call, so the constraint tracks the current
%   sizing-loop iteration and fidelity level automatically.
%
%   EQUATION  [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002 --
%   the point-performance "Master Equation" specialized to steady, wings-level
%   flight; see also NPTEL_Fighter_Aircraft_Sizing.ipynb, "Point Performance
%   using Mattingly's Master Equation"]:
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n * beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   where q, V come from AircraftState; CD0, K1, K2 from aero.drag_polar(state);
%   alpha from get_alpha(). beta, n, Ps are stakeholder/mission inputs for the
%   condition (e.g. F-16 Max Mach: beta=0.8997, n=1.0, Ps=0 at 36,000 ft /
%   M=1.60 -- see examples/F16A/mds/f16a_requirements.md).
%
%   POWER SETTING. alpha is drawn on the basis the condition is constructed
%   with: "AB" -> prop.thrust_lapse(state) (AB/max-power, the PropulsionBase
%   default; use a 100%-AB flight condition for an afterburning point); "mil"
%   -> prop.thrust_lapse_mil_on_AB_scale(state) (T_mil/T_SL_AB -- still on the
%   AB T_SL scale so the resulting T/W stays comparable with every other,
%   AB-flown condition on the same diagram). Conditions flown at 0% AB/mil
%   power (e.g. Cruise) must use powerSetting="mil". See get_alpha and
%   examples/F16A/mds/cruise_and_combatturn2_error_scrape.md Sec 2.

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
        powerSetting  % string "AB" or "mil" -- which basis prop.thrust_lapse is drawn from, see get_alpha
    end

    methods

        function obj = MasterEquationConstraint(name, state, aero, prop, beta, n, Ps, powerSetting)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                beta  (1,1) double {mustBePositive}
                n     (1,1) double {mustBePositive} = 1.0
                Ps    (1,1) double {mustBeNonnegative} = 0.0
                powerSetting (1,1) string {mustBeMember(powerSetting, ["AB","mil"])} = "AB"
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.prop  = prop;
            obj.beta  = beta;
            obj.n     = n;
            obj.Ps    = Ps;
            obj.powerSetting = powerSetting;
        end

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required at wing loading(s) WS [lbf/ft^2], per the
        %   Master Equation assembled from this condition's A/B/C/D terms.
        %   WS may be scalar or array; TW is returned the same size.
        %
        %   FAILS LOUDLY on a non-finite term. The A/B/C/D terms come from the
        %   aero drag polar and the prop thrust lapse, either of which can
        %   legitimately be non-finite -- AeroL2 returns NaN CD0/K1 across the
        %   unmodeled transonic band by design, and a mis-injected discipline
        %   object can too. A NaN required_TW is silently omitted from
        %   ConstraintAnalysis's max() envelope, so an un-evaluable condition
        %   would read as SATISFIED off a curve that does not exist. Erroring
        %   here makes that a visible failure at the one place every
        %   Master-Equation constraint funnels through.
        %
        %   The drag polar and thrust lapse are fetched once per call and
        %   passed to the compute_* helpers; the fetch stays inside the call
        %   (not cached across calls) so the constraint tracks the current
        %   sizing-loop iteration and fidelity level.
            polar = obj.aero.drag_polar(obj.state);
            alpha = obj.get_alpha();
            q     = obj.state.q;
            V     = obj.state.V;

            A = obj.compute_A(polar, alpha, q);
            B = obj.compute_B(polar, alpha, q);
            C = obj.compute_C(polar, alpha);
            D = obj.compute_D(alpha, V);
            terms = [A, B, C, D];
            if ~all(isfinite(terms))
                names = ["A", "B", "C", "D"];
                bad   = names(~isfinite(terms));
                % Flight condition is the most useful diagnostic here.
                where = sprintf('This condition is at alt=%g ft, M=%.4f.', ...
                    obj.state.altitude_ft, obj.state.mach);
                error('MasterEquationConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": Master-Equation term(s) %s are non-finite ', ...
                     '[A B C D] = %s. The usual cause is a drag polar or thrust ', ...
                     'lapse that is not modeled at this flight condition -- e.g. ', ...
                     'AeroL2/AeroL3 return NaN CD0/K1 across the unmodeled ', ...
                     'transonic band (%.2f < M < %.2f) by design, and the L3 ', ...
                     'component buildup requires M > 0. %s Move the condition out ', ...
                     'of the unmodeled region, or use a fidelity level that ', ...
                     'covers it.'], ...
                    obj.name, strjoin(bad, "/"), mat2str(terms, 6), ...
                    AeroL2.MACH_SUBSONIC_MAX, AeroL2.MACH_SUPERSONIC_MIN, where);
            end
            TW = A ./ WS + B .* WS + C + D;
        end

    end

    methods (Access = protected)
        %COMPUTE_A/B/C/D  Master Equation terms, see class header for the
        %   equation and citation. Each takes the already-fetched drag polar
        %   (CD0/K1/K2), thrust lapse alpha, dynamic pressure q, and speed V --
        %   required_TW fetches those once and passes them in. Protected;
        %   called only from required_TW.

        function A = compute_A(obj, polar, alpha, q) %#ok<INUSL>
            A = q * polar.CD0 / alpha;
        end

        function B = compute_B(obj, polar, alpha, q)
            B = (q / alpha) * polar.K1 * (obj.n * obj.beta / q)^2;
        end

        function C = compute_C(obj, polar, alpha)
            C = polar.K2 * obj.n * obj.beta / alpha;
        end

        function D = compute_D(obj, alpha, V)
            D = (obj.beta / alpha) * (obj.Ps / V);
        end

        function alpha = get_alpha(obj)
        %GET_ALPHA  Thrust lapse on the basis this condition was constructed
        %   with: AB (prop.thrust_lapse) or mil
        %   (prop.thrust_lapse_mil_on_AB_scale). See the powerSetting property
        %   and cruise_and_combatturn2_error_scrape.md Sec 2 for why Cruise
        %   needs the mil basis.
            if obj.powerSetting == "mil"
                alpha = obj.prop.thrust_lapse_mil_on_AB_scale(obj.state);
            else
                alpha = obj.prop.thrust_lapse(obj.state);
            end
        end

    end

    methods (Static)

        function powerSetting = requirePowerSetting(cond)
        %REQUIREPOWERSETTING  Read + validate a thrust condition's
        %   power_setting field ("AB"/"mil"). Used by the Master-Equation
        %   subclasses' fromCondition factories. "mil" draws the thrust lapse
        %   from prop.thrust_lapse_mil_on_AB_scale (a dry/military-power
        %   condition), "AB" from prop.thrust_lapse -- see get_alpha and
        %   examples/F16A/mds/cruise_and_combatturn2_error_scrape.md Sec. 2.
        %
        %   Errors rather than defaulting on a missing or out-of-set value: an
        %   unstated power setting silently defaulting to "AB" is exactly the
        %   bug this validator prevents, and only the two discrete bases are
        %   modeled (there is no partial-AB thrust model).
            arguments
                cond (1,1) struct
            end
            name = string(cond.name);
            if ~isfield(cond, 'power_setting') || isempty(cond.power_setting)
                error('MasterEquationConstraint:missingPowerSetting', ...
                    ['Constraint "%s" has no power_setting. A Master-Equation ', ...
                     'constraint needs an explicit power setting ("mil" or "AB"); ', ...
                     'add the power_setting field to this condition in the ', ...
                     'requirements JSON.'], name);
            end
            powerSetting = string(cond.power_setting);
            if ~ismember(powerSetting, ["AB", "mil"])
                error('MasterEquationConstraint:invalidPowerSetting', ...
                    ['Constraint "%s" specifies power_setting = "%s". Only "mil" ', ...
                     'and "AB" are modeled -- PropulsionBase exposes no ', ...
                     'partial-afterburner thrust lapse.'], name, powerSetting);
            end
        end

    end

end

classdef (Abstract) MasterEquationConstraint < Both_WbyS_TbyW
%MASTEREQUATIONCONSTRAINT  Mattingly "Master Equation" point-performance
%   constraint (abstract base of the thrust-condition subtree).
%
%   Generic Layer-1 constraint: given a flight condition (AircraftState),
%   a load factor n, a required specific excess power Ps, a weight fraction
%   beta = W/W_TO, and the current-iteration aerodynamics/propulsion
%   discipline objects, returns the thrust-to-weight ratio required to
%   sustain that condition as a function of wing loading W/S. Belongs to the
%   Both_WbyS_TbyW category (see that class's header) and supplies the
%   concrete required_TW(WS) that category declares abstract.
%
%   ABSTRACT (2026-08-04): this class is the shared implementation of the
%   Master Equation, but it is instantiated only through its thin
%   specializations -- LevelFlightConstraint (n=1, Ps=0),
%   SustainedTurnConstraint (n>1, Ps=0), ExcessPowerConstraint (Ps>0) --
%   which differ only in which of (n, Ps, powerSetting) are fixed vs. free.
%   The equation itself is identical across all of them; only (state, beta,
%   n, Ps, powerSetting) differ. This replaces the old single ThrustConstraint
%   class, grouping the conditions by the physics actually active in the
%   Master Equation. See
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.
%
%   One instance models one point-performance condition (cruise, dash/max
%   Mach, sustained turn, climb, ...) -- alpha (thrust lapse) and CD0/K1/K2
%   (drag polar) are pulled fresh from prop/aero each call, so the constraint
%   tracks the current sizing-loop iteration and fidelity level automatically
%   (never hardcoded here).
%
%   EQUATION  [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002,
%   the point-performance "Master Equation" specialized to steady,
%   wings-level flight -- see also NPTEL_Fighter_Aircraft_Sizing.ipynb,
%   "Point Performance using Mattingly's Master Equation"]:
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n * beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   where q, V come from AircraftState; CD0, K1, K2 from aero.drag_polar(state);
%   alpha from prop.thrust_lapse(state) by default (AB/max-power lapse per
%   PropulsionBase convention -- use a 100%-AB flight condition when
%   instantiating for an afterburning point). Conditions flown at 0% AB/mil
%   power (e.g. Cruise) should be constructed with powerSetting="mil", which
%   draws alpha from PropulsionBase.thrust_lapse_mil_on_AB_scale(state)
%   instead (T_mil/T_SL_AB -- still on the AB T_SL scale so the resulting
%   T/W stays comparable with every other, AB-flown condition on the same
%   constraint diagram). See get_alpha and
%   sizing/examples/F16A/cruise_and_combatturn2_error_scrape.md Sec 2.
%   beta, n, Ps are stakeholder/mission inputs specific
%   to the condition being modeled (e.g. F-16 Max Mach: beta=0.8997, n=1.0,
%   Ps=0 at 36,000 ft / M=1.60 -- see sizing/docs/subplans/06_constraint_analysis.md).

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
        %   FAILS LOUDLY ON A NON-FINITE TERM (added 2026-07-25; moved here
        %   from Both_WbyS_TbyW 2026-08-04). The A/B/C/D terms are built from
        %   the aero object's drag polar and the propulsion object's thrust
        %   lapse, either of which can legitimately hand back a non-finite
        %   value -- AeroL2 returns NaN CD0/K1 across the unmodeled transonic
        %   band by design, and a mis-injected discipline object can produce
        %   NaN or Inf too. A NaN required_TW is the WORST possible outcome
        %   downstream: every > / < comparison against it is false, so a
        %   condition that cannot be evaluated silently reads as SATISFIED and
        %   ConstraintAnalysis picks a design point off a curve that does not
        %   exist. Erroring here converts that into a visible failure at the one
        %   place every Master-Equation constraint funnels through.
        %
        %   EFFICIENCY (T7, 2026-08-04): the drag polar and the thrust lapse
        %   are fetched exactly ONCE per required_TW call and handed to the
        %   four compute_* term helpers. An earlier form let each helper
        %   re-fetch them, so one required_TW call evaluated aero.drag_polar
        %   three times and get_alpha four times, all returning the identical
        %   value (the state is fixed). The fetch stays INSIDE this call (not
        %   cached on the object across calls), so the constraint still tracks
        %   the current sizing-loop iteration and fidelity level -- an
        %   optimizer that mutates aero/prop between calls sees fresh values.
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
        %   equation and citation. Each TAKES the already-fetched drag polar
        %   (CD0/K1/K2), thrust lapse alpha, dynamic pressure q, and speed V
        %   -- required_TW fetches those once (via aero.drag_polar/get_alpha)
        %   and passes them in, so the constraint tracks the current
        %   sizing-loop iteration and fidelity level while evaluating the
        %   drag polar and thrust lapse only once per call (T7, 2026-08-04).
        %   These helpers are protected and called only from required_TW.

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
        %   with -- AB (T_AB/T_SL_AB, the PropulsionBase default) or mil
        %   (T_mil/T_SL_AB, PropulsionBase.thrust_lapse_mil_on_AB_scale) --
        %   see the powerSetting property and
        %   cruise_and_combatturn2_error_scrape.md Sec 2 for why Cruise
        %   specifically needs the mil basis.
            if obj.powerSetting == "mil"
                alpha = obj.prop.thrust_lapse_mil_on_AB_scale(obj.state);
            else
                alpha = obj.prop.thrust_lapse(obj.state);
            end
        end

    end

end

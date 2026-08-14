classdef PropL2
%PROPL2  Level-2 propulsion static toolbox: Mattingly parametric engine model.
%
%   Call as PropL2.method(...); never instantiated, not in the inheritance
%   chain. F16PropL2 inherits PropulsionModelL2 and delegates to these statics.
%
%   Sources: [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54a/b] thrust lapse; [Eq. 3.12 with
%   3.55a/b] TSFC; [Eq. D.6] throttle ratio; [Raymer 6th ed. Sec. 10.3.2,
%   Eq. 10.4-10.15] parametric engine sizing, EXCEPT Eq. 10.10
%   (engine_weight_AB), confirmed 7th ed. per Sarojini -- see that method's
%   own comment. Eq. 10.6/10.12 (engine_diam_nonAB/AB) remain an open
%   6th-vs-7th-edition question, see their TODO(Sarojini) comments.
%
%   The C1/C2 TSFC coefficients are engine-class constants selected by
%   engine_type inside lookup_TSFC_coeffs -- not class Constants and not in the
%   JSON.
%
%   INSTALLED vs UNINSTALLED: the Mattingly TSFC here is uninstalled. Brandt's
%   stored SLS values already include the 1.08 installation factor, so it must
%   not be applied on top of them.
%
%   Companion doc: src/disciplines/propulsion/PropL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): Again, appears to be an artefact from when the toolboxes were subclasses
        % of enforcers. This is no longer necessary, and should be moved to the F16 example class if 
        % if hasn't already.
        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  AB/max lapse [Mattingly Eq. 2.54a].
        %   Used with T_SL (AB thrust) for constraint analysis and sizing.
            alpha = PropL2.thrust_lapse_AB(state.delta_0, state.theta_0, obj.TR);
        end

        % TODO (8/14/2026): Same as with "get_thrust_lapse."
        function alpha = get_thrust_lapse_mil(obj, state)
        %GET_THRUST_LAPSE_MIL  Mil-power lapse [Mattingly Eq. 2.54b].
        %   Used with T_SL_mil for mil-power constraints.
            alpha = PropL2.thrust_lapse_mil(state.delta_0, state.theta_0, obj.TR);
        end

        % TODO (8/14/2026): Same as with "get_thrust_lapse" and "get_thrust_lapse_mil."
        function alpha = get_thrust_lapse_AB(obj, state)
        %GET_THRUST_LAPSE_AB  Afterburner lapse [Mattingly Eq. 2.54a].
            alpha = PropL2.thrust_lapse_AB(state.delta_0, state.theta_0, obj.TR);
        end

        function alpha = get_thrust_lapse_mil_on_AB_scale(obj, state)
            alpha_mil = PropL2.thrust_lapse_mil(state.delta_0, state.theta_0, obj.TR);
            alpha = alpha_mil * (obj.T_SL_mil / obj.T_SL_wet);
            if ~isfinite(alpha) || alpha < 0 || alpha > 1.5
                warning('PropL2:anomalousThrustLapse', ...
                    ['get_thrust_lapse_mil_on_AB_scale returned %.4f, outside the ' ...
                     'physically plausible (0, 1.5] band for a mil-power lapse ' ...
                     'renormalized onto the AB thrust scale -- check the flight ' ...
                     'condition and T_SL_mil/T_SL_wet inputs.'], alpha);
            end
        end

        % TODO (8/14/2026): Artefact of enforcement.
        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Uninstalled mil-power TSFC (default for Breguet range/endurance).
        %   Coefficients selected by obj.engine_type via lookup_TSFC_coeffs.
        %   [Mattingly Eq. 3.12 + 3.55a]
            c = PropL2.lookup_TSFC_coeffs(obj.engine_type);
            c_t = PropL2.TSFC_mil(c.C1_mil, c.C2_mil, state.mach, state.theta);
        end

        % TODO (8/14/2026): Artefact of enforcment.
        function c_t = get_TSFC_mil(obj, state)
        %GET_TSFC_MIL  Uninstalled mil-power TSFC in 1/hr.  [Mattingly Eq. 3.12 + 3.55a]
        %   Coefficients selected by obj.engine_type via lookup_TSFC_coeffs.
            c = PropL2.lookup_TSFC_coeffs(obj.engine_type);
            c_t = PropL2.TSFC_mil(c.C1_mil, c.C2_mil, state.mach, state.theta);
        end

        % TODO (8/14/2026): Artefact of enforcement.
        function c_t = get_TSFC_AB(obj, state)
        %GET_TSFC_AB  Uninstalled afterburner TSFC in 1/hr.  [Mattingly Eq. 3.12 + 3.55b]
        %   Coefficients selected by obj.engine_type via lookup_TSFC_coeffs.
            c = PropL2.lookup_TSFC_coeffs(obj.engine_type);
            c_t = PropL2.TSFC_AB(c.C1_AB, c.C2_AB, state.mach, state.theta);
        end

        % ------------------------------------------------------------------ %
        % Installed TSFC = uninstalled TSFC × installation factor.
        %   [installation factor Brandt Miss!C25; installed = uninstalled × 1.08]
        %   NOTE: The stored Brandt SLS TSFCs (0.70 mil / 2.20 AB) are ALREADY
        %   installed (they include the 1.08 factor) -- do NOT double-apply the
        %   factor when comparing against those Brandt values.  See
        %   VnV/BrandtF16A/todo.md 2026-07-24 entry 4.
        % ------------------------------------------------------------------ %

        % TODO (8/14/2026): Artefact of enforcement.
        function c_t = get_TSFC_installed(obj, state)
        %GET_TSFC_INSTALLED  Installed mil-power TSFC in 1/hr.
        %   = uninstalled mil TSFC × obj.TSFC_install_factor.
        %   [Mattingly Eq. 3.12 + 3.55a; install factor Brandt Miss!C25]
            c_t = PropL2.get_TSFC_mil(obj, state) * obj.TSFC_install_factor;
        end

        % TODO (8/14/2026): Artefact of enforcement.
        function c_t = get_TSFC_AB_installed(obj, state)
        %GET_TSFC_AB_INSTALLED  Installed afterburner TSFC in 1/hr.
        %   = uninstalled AB TSFC × obj.TSFC_install_factor.
        %   [Mattingly Eq. 3.12 + 3.55b; install factor Brandt Miss!C25]
            c_t = PropL2.get_TSFC_AB(obj, state) * obj.TSFC_install_factor;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only, no object access.
        % ================================================================== %

        % --- Mattingly thrust lapse ----------------------------------------

        function alpha = thrust_lapse_AB(delta_0, theta_0, TR)
        %THRUST_LAPSE_AB  Low-BPR mixed turbofan AB lapse.  [Mattingly Eq. 2.54a]
        %   δ₀, θ₀ — total pressure/temperature ratios (from AircraftState).
        %   TR — throttle ratio.  Returns α_AB = T_AB(alt,M) / T_AB_SL.
            if theta_0 <= TR
                alpha = delta_0;
            else
                alpha = delta_0 * (1 - 3.5*(theta_0 - TR)/theta_0);
            end
        end

        function alpha = thrust_lapse_mil(delta_0, theta_0, TR)
        %THRUST_LAPSE_MIL  Low-BPR mixed turbofan mil lapse.  [Mattingly Eq. 2.54b]
        %   Returns α_mil = T_mil(alt,M) / T_mil_SL.
            if theta_0 <= TR
                alpha = 0.6 * delta_0;
            else
                alpha = 0.6 * delta_0 * (1 - 3.8*(theta_0 - TR)/theta_0);
            end
        end

        % --- Mattingly TSFC -----------------------------------------------

        function c_t = TSFC_mil(C1_mil, C2_mil, M, theta)
        %TSFC_MIL  Mil-power TSFC model.  [Mattingly Eq. 3.12 + 3.55a]
        %   TSFC = (C1_mil + C2_mil·M)·√θ  in 1/hr.
        %   θ = T_atm/T_SL (static temperature ratio from AircraftState).
            c_t = (C1_mil + C2_mil * M) * sqrt(theta);
        end

        function c_t = TSFC_AB(C1_AB, C2_AB, M, theta)
        %TSFC_AB  Afterburner TSFC model.  [Mattingly Eq. 3.12 + 3.55b]
        %   TSFC = (C1_AB + C2_AB·M)·√θ  in 1/hr.
            c_t = (C1_AB + C2_AB * M) * sqrt(theta);
        end

        function coeffs = lookup_TSFC_coeffs(engine_type)
            switch engine_type
                case {'low_bypass_turbofan_AB', 'low_bypass_turbofan'}
                    coeffs = struct('C1_mil', 0.90, 'C2_mil', 0.30, ...
                                    'C1_AB',  1.60, 'C2_AB',  0.27);
                otherwise
                    error('PropL2:unknownEngineType', ...
                        'Unknown engine_type "%s". Add it to PropL2.lookup_TSFC_coeffs.', ...
                        engine_type);
            end
        end

        function TR = compute_TR(T_t4_max_R, T_t4_SLS_R)
            arguments
                T_t4_max_R (1,1) double {mustBePositive}
                T_t4_SLS_R (1,1) double {mustBePositive} = T_t4_max_R
            end
            TR = T_t4_max_R / T_t4_SLS_R;
        end

        % ================================================================== %
        % PARAMETRIC ENGINE SIZING — Raymer Eqs 10.4–10.15
        %   Raymer, "Aircraft Design," 6th ed., §10.3.2, book p. 284
        %   English units: T [lbf], M [—], BPR [—] → W [lb], L [ft], D [ft], SFC [1/hr]
        %   Cruise reference condition: 36,000 ft, M = 0.9
        % ================================================================== %

        % --- Nonafterburning engines (BPR 0 to ~6) -----------------------

        function W = engine_weight_nonAB(T, BPR)
        %ENGINE_WEIGHT_NONAB  Statistical engine weight, nonafterburning.  [Raymer Eq. 10.4]
        %   W [lb] = 0.0847 · T^1.1 · exp(-0.045·BPR)
        %   T = takeoff (SLS) thrust [lbf];  BPR = bypass ratio.
            W = 0.0847 * T.^1.1 .* exp(-0.045 * BPR);
        end

        function L = engine_length_nonAB(T, M)
        %ENGINE_LENGTH_NONAB  Statistical engine length, nonafterburning.  [Raymer Eq. 10.5]
        %   L [ft] = 0.185 · T^0.4 · M^0.2
        %   T = SLS thrust [lbf];  M = design Mach number.
            L = 0.185 * T.^0.4 .* M.^0.2;
        end

        function D = engine_diam_nonAB(T, BPR)
        %ENGINE_DIAM_NONAB  Statistical engine diameter, nonafterburning.
        %   [Raymer Eq. 10.6]. D [ft] = 0.033 · T^0.5 · exp(0.04·BPR).
        %   TODO(Sarojini): this module header cites the surrounding Eq.
        %   10.4-10.15 block to "Raymer 6th ed.", but a recovered todo.md
        %   decision (VnV/BrandtF16A/todo.md, 2026-07-24 Propulsion entry 3)
        %   says this specific coefficient's equation number is 7th ed. This
        %   repo has no 7th-ed. source to check. Confirm the edition against
        %   your physical copy and correct whichever citation is wrong.
            D = 0.033 * T.^0.5 .* exp(0.04 * BPR);
            PropL2.warnIfImplausibleEngineDiameter(D, 'engine_diam_nonAB');
        end

        function SFC = SFC_max_nonAB(BPR)
        %SFC_MAX_NONAB  Max-throttle SFC, nonafterburning.  [Raymer Eq. 10.7]
        %   SFC [1/hr] = 0.67 · exp(-0.12·BPR)
            SFC = 0.67 * exp(-0.12 * BPR);
        end

        function T_cr = thrust_cruise_nonAB(T, BPR)
        %THRUST_CRUISE_NONAB  Cruise thrust, nonafterburning.  [Raymer Eq. 10.8]
        %   T_cr [lb] = 0.60 · T^0.9 · exp(-0.02·BPR)
        %   Cruise at 36,000 ft, M = 0.9.
            T_cr = 0.60 * T.^0.9 .* exp(-0.02 * BPR);
        end

        function SFC = SFC_cruise_nonAB(BPR)
        %SFC_CRUISE_NONAB  Cruise SFC, nonafterburning.  [Raymer Eq. 10.9]
        %   SFC [1/hr] = 0.88 · exp(-0.05·BPR)
        %   Cruise at 36,000 ft, M = 0.9.
            SFC = 0.88 * exp(-0.05 * BPR);
        end

        % --- Afterburning engines (BPR 0 to <1, M_max < 2.5) -------------

        function W = engine_weight_AB(T, M, BPR)
        %ENGINE_WEIGHT_AB  Statistical engine dry weight, afterburning.
        %   [Raymer 7th ed. Eq. 10.10]. W [lbf] = 0.0637 · T^1.1 · M^0.25 · exp(-0.81·BPR).
        %   RESOLVED 2026-07-30: confirmed 7th ed. is correct for this
        %   equation, per Sarojini (who has the 7th edition) -- this matches
        %   the Weights-side citation of the same equation (see
        %   WeightsModelL3.m). Was previously a shared TODO with
        %   engine_diam_nonAB/AB, which remain open (Eq. 10.6/10.12 are a
        %   separate, still-unconfirmed question).
            W = 0.0637 * T.^1.1 .* M.^0.25 .* exp(-0.81 * BPR);
        end

        function L = engine_length_AB(T, M)
        %ENGINE_LENGTH_AB  Statistical engine length, afterburning.  [Raymer Eq. 10.11]
        %   L [ft] = 0.255 · T^0.4 · M^0.2
            L = 0.255 * T.^0.4 .* M.^0.2;
        end

        function D = engine_diam_AB(T, BPR)
        %ENGINE_DIAM_AB  Statistical engine diameter, afterburning.
        %   [Raymer Eq. 10.12]. D [ft] = 0.024 · T^0.5 · exp(0.04·BPR).
        %   TODO(Sarojini): see engine_diam_nonAB's TODO -- same 6th-vs-7th-
        %   edition question for this coefficient.
            D = 0.024 * T.^0.5 .* exp(0.04 * BPR);
            PropL2.warnIfImplausibleEngineDiameter(D, 'engine_diam_AB');
        end

        function SFC = SFC_max_AB(BPR)
        %SFC_MAX_AB  Max-throttle (AB) SFC, afterburning engine.  [Raymer Eq. 10.13]
        %   SFC [1/hr] = 2.1 · exp(-0.12·BPR)
            SFC = 2.1 * exp(-0.12 * BPR);
        end

        function T_cr = thrust_cruise_AB(T, BPR)
        %THRUST_CRUISE_AB  Cruise thrust (non-AB), afterburning engine.  [Raymer Eq. 10.14]
        %   T_cr [lb] = 2.4 · T^0.74 · exp(0.023·BPR)
        %   Cruise at 36,000 ft, M = 0.9.
            T_cr = 2.4 * T.^0.74 .* exp(0.023 * BPR);
        end

        function SFC = SFC_cruise_AB(BPR)
        %SFC_CRUISE_AB  Cruise SFC (non-AB), afterburning engine.  [Raymer Eq. 10.15]
        %   SFC [1/hr] = 1.04 · exp(-0.186·BPR)
        %   Cruise at 36,000 ft, M = 0.9.
            SFC = 1.04 * exp(-0.186 * BPR);
        end

        function warnIfImplausibleEngineDiameter(D, callerName)
        %WARNIFIMPLAUSIBLEENGINEDIAMETER  Sanity-check warning, not a hard
        %   error: a fighter-class engine diameter belongs roughly in
        %   [1, 8] ft. Added 2026-07-30 in place of dedicated unit tests for
        %   engine_diam_nonAB/engine_diam_AB (per Casey: give a warning for
        %   an anomalous value rather than test every input combination).
            if ~isfinite(D) || D < 1 || D > 8
                warning('PropL2:implausibleEngineDiameter', ...
                    ['%s returned D = %.4f ft, outside the physically plausible ' ...
                     '[1, 8] ft band for a fighter-class engine -- check the ' ...
                     'input thrust and bypass ratio.'], callerName, D);
            end
        end

    end

end

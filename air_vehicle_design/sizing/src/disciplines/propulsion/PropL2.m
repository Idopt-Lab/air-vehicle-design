classdef PropL2
%PROPL2  Level-2 propulsion static toolbox: Mattingly parametric engine model.
%
%   Call as PropL2.method(...); never instantiated, not in the inheritance
%   chain. F16PropL2 inherits PropulsionModelL2 and delegates to these statics.
%
%   Sources: [Mattingly Aircraft Engine Design 2nd ed. Eq. 2.54a/b] thrust
%   lapse; [Eq. 3.12 + 3.55a/b] TSFC; [Eq. D.6] throttle ratio; [Raymer 6th
%   ed. Sec. 10.3.2] afterburning engine sizing (Eq. 10.10 weight is 7th ed.,
%   confirmed per Sarojini).
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

        % ------------------------------------------------------------------ %
        % Installed TSFC = uninstalled TSFC × installation factor.
        %   [installation factor Brandt Miss!C25; installed = uninstalled × 1.08]
        %   NOTE: The stored Brandt SLS TSFCs (0.70 mil / 2.20 AB) are ALREADY
        %   installed (they include the 1.08 factor) -- do NOT double-apply the
        %   factor when comparing against those Brandt values.  See
        %   VnV/BrandtF16A/todo.md 2026-07-24 entry 4.
        % ------------------------------------------------------------------ %

        % This uses Brandt's installation factor, TSFC * installation factor.
        % Source: Brandt Miss!C25.
        function c_t = compute_TSFC_installed(c_t, install_factor)
            c_t = c_t * install_factor;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only, no object access.
        % ================================================================== %

        % --- Mattingly thrust lapse ----------------------------------------

        function alpha = compute_thrust_lapse_AB(delta_0, theta_0, TR)
        %THRUST_LAPSE_AB  Low-BPR mixed turbofan AB lapse.  [Mattingly Eq. 2.54a]
        %   δ₀, θ₀ — total pressure/temperature ratios (from AircraftState).
        %   TR — throttle ratio.  Returns α_AB = T_AB(alt,M) / T_AB_SL.
            if theta_0 <= TR
                alpha = delta_0;
            else
                alpha = delta_0 * (1 - 3.5*(theta_0 - TR)/theta_0);
            end
        end

        function alpha = compute_thrust_lapse_mil(delta_0, theta_0, TR)
        %THRUST_LAPSE_MIL  Low-BPR mixed turbofan mil lapse.  [Mattingly Eq. 2.54b]
        %   Returns α_mil = T_mil(alt,M) / T_mil_SL.
            if theta_0 <= TR
                alpha = 0.6 * delta_0;
            else
                alpha = 0.6 * delta_0 * (1 - 3.8*(theta_0 - TR)/theta_0);
            end
        end

        function alpha = compute_normalized_thrust_lapse(alpha, T_current, T_SL_max)
            alpha = alpha*T_current/T_SL_max;
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
        % PARAMETRIC ENGINE SIZING — Raymer Eqs 10.10–10.15 (afterburning)
        %   Raymer, "Aircraft Design," 6th ed., §10.3.2, book p. 284
        %   English units: T [lbf], M [—], BPR [—] → W [lb], L [ft], SFC [1/hr]
        % ================================================================== %

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

        function SFC = SFC_max_AB(BPR)
        %SFC_MAX_AB  Max-throttle (AB) SFC, afterburning engine.  [Raymer Eq. 10.13]
        %   SFC [1/hr] = 2.1 · exp(-0.12·BPR)
            SFC = 2.1 * exp(-0.12 * BPR);
        end

        function SFC = SFC_cruise_AB(BPR)
        %SFC_CRUISE_AB  Cruise SFC (non-AB), afterburning engine.  [Raymer Eq. 10.15]
        %   SFC [1/hr] = 1.04 · exp(-0.186·BPR)
        %   Cruise at 36,000 ft, M = 0.9.
            SFC = 1.04 * exp(-0.186 * BPR);
        end

    end

end

classdef PropL2
%PROPL2  Level-2 propulsion static toolbox.
%
%   Call as PropL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16PropL2, etc.) inherit
%   from PropulsionModelL2 and call these statics to implement each abstract method.
%
%   TWO TIERS of statics:
%     High-level — take the student object (obj); single delegation line in student.
%     Low-level  — pure math; take only scalars/arrays (no object access).
%
%   EQUATIONS — THRUST LAPSE & TSFC (Mattingly):
%     Thrust lapse — low-BPR mixed turbofan:
%       Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002, Eq. 2.54
%       AB (max):  θ₀ ≤ TR → α_AB = δ₀
%                  θ₀ > TR → α_AB = δ₀·(1 − 3.5·(θ₀−TR)/θ₀)
%       Mil (dry): θ₀ ≤ TR → α_mil = 0.6·δ₀
%                  θ₀ > TR → α_mil = 0.6·δ₀·(1 − 3.8·(θ₀−TR)/θ₀)
%       where θ₀, δ₀ are total temperature/pressure ratios from AircraftState.
%     TSFC — Mattingly Eq. 3.12 (general) + Eq. 3.55 (low-BPR coefficients):
%       TSFC = (C1 + C2·M)·√θ,  θ = T_atm/T_SL
%       Mil: C1=C1_mil, C2=C2_mil  |  AB: C1=C1_AB, C2=C2_AB
%       Units: lbf_fuel/(hr·lbf_thrust)
%
%   EQUATIONS — PARAMETRIC ENGINE SIZING (Raymer Eqs 10.4–10.15):
%     Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018, §10.3.2
%     Statistical rubber-engine sizing models.  English units throughout.
%       T   = takeoff (SLS max) thrust [lbf]
%       M   = design (max) Mach number [—]
%       BPR = bypass ratio [—]
%     Cruise reference: 36,000 ft, M = 0.9  [Raymer §10.3.2, p. 285]
%
%     Nonafterburning (BPR 0–6):
%       engine_weight_nonAB  Eq. 10.4 — W [lb]
%       engine_length_nonAB  Eq. 10.5 — L [ft]
%       engine_diam_nonAB    Eq. 10.6 — D [ft]   [coefficient verify from book p. 284]
%       SFC_max_nonAB        Eq. 10.7 — SFC at max throttle [1/hr]
%       thrust_cruise_nonAB  Eq. 10.8 — cruise thrust [lb]
%       SFC_cruise_nonAB     Eq. 10.9 — cruise SFC [1/hr]
%
%     Afterburning (BPR 0–<1, M_max < 2.5):
%       engine_weight_AB     Eq. 10.10 — W [lb]
%       engine_length_AB     Eq. 10.11 — L [ft]
%       engine_diam_AB       Eq. 10.12 — D [ft]  [coefficient verify from book p. 284]
%       SFC_max_AB           Eq. 10.13 — SFC at max (AB) throttle [1/hr]
%       thrust_cruise_AB     Eq. 10.14 — cruise thrust (non-AB) [lb]
%       SFC_cruise_AB        Eq. 10.15 — cruise SFC (non-AB) [1/hr]

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  AB/max lapse [Mattingly Eq. 2.54a].
        %   Used with T_SL (AB thrust) for constraint analysis and sizing.
            alpha = PropL2.thrust_lapse_AB(state.delta_0, state.theta_0, obj.TR);
        end

        function alpha = get_thrust_lapse_mil(obj, state)
        %GET_THRUST_LAPSE_MIL  Mil-power lapse [Mattingly Eq. 2.54b].
        %   Used with T_SL_mil for mil-power constraints.
            alpha = PropL2.thrust_lapse_mil(state.delta_0, state.theta_0, obj.TR);
        end

        function alpha = get_thrust_lapse_AB(obj, state)
        %GET_THRUST_LAPSE_AB  Afterburner lapse [Mattingly Eq. 2.54a].
            alpha = PropL2.thrust_lapse_AB(state.delta_0, state.theta_0, obj.TR);
        end

        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Mil-power TSFC (default for Breguet range/endurance).
        %   [Mattingly Eq. 3.12 + 3.55a]
            c_t = PropL2.TSFC_mil(obj.C1_mil, obj.C2_mil, state.mach, state.theta);
        end

        function c_t = get_TSFC_mil(obj, state)
        %GET_TSFC_MIL  Mil-power TSFC in 1/hr.  [Mattingly Eq. 3.12 + 3.55a]
            c_t = PropL2.TSFC_mil(obj.C1_mil, obj.C2_mil, state.mach, state.theta);
        end

        function c_t = get_TSFC_AB(obj, state)
        %GET_TSFC_AB  Afterburner TSFC in 1/hr.  [Mattingly Eq. 3.12 + 3.55b]
            c_t = PropL2.TSFC_AB(obj.C1_AB, obj.C2_AB, state.mach, state.theta);
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

        function TR = compute_TR(T_t4_max_R, T_t4_SLS_R)
        %COMPUTE_TR  Throttle ratio from turbine inlet temperatures.  [Mattingly App. D, Eq. D.6]
        %   TR = T_t4_max / T_t4_SLS  (both in Rankine).
        %   T_t4_SLS = full-throttle turbine inlet temperature at SLS standard day.
        %   When T_t4_SLS is unknown, omit it — defaults to T_t4_max → TR = 1.0.
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
        %ENGINE_DIAM_NONAB  Statistical engine max diameter, nonafterburning.  [Raymer Eq. 10.6]
        %   D [ft] = 0.033 · T^0.5 · exp(0.04·BPR)
        %   [OCR coefficient verify: book p. 284; metric check suggests ~0.034]
            D = 0.033 * T.^0.5 .* exp(0.04 * BPR);
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
        %ENGINE_WEIGHT_AB  Statistical engine weight, afterburning.  [Raymer Eq. 10.10]
        %   W [lb] = 0.0637 · T^1.1 · M^0.25 · exp(-0.81·BPR)
        %   T = SLS AB (max) thrust [lbf];  M = design (max) Mach number.
            W = 0.0637 * T.^1.1 .* M.^0.25 .* exp(-0.81 * BPR);
        end

        function L = engine_length_AB(T, M)
        %ENGINE_LENGTH_AB  Statistical engine length, afterburning.  [Raymer Eq. 10.11]
        %   L [ft] = 0.255 · T^0.4 · M^0.2
            L = 0.255 * T.^0.4 .* M.^0.2;
        end

        function D = engine_diam_AB(T, BPR)
        %ENGINE_DIAM_AB  Statistical engine max diameter, afterburning.  [Raymer Eq. 10.12]
        %   D [ft] = 0.024 · T^0.5 · exp(0.04·BPR)
        %   [OCR coefficient verify: book p. 284; metric check suggests ~0.0256]
            D = 0.024 * T.^0.5 .* exp(0.04 * BPR);
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

    end

end

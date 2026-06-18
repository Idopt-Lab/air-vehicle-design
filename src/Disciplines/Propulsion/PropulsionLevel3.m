classdef PropulsionLevel3 < PropulsionBase
    % Level III propulsion: Mattingly thrust lapse + Raymer engine scaling.
    %
    % Adds a proper Mattingly thrust lapse model (dry and wet) using the
    % pressure and temperature ratios from AircraftState.  TSFC comes from
    % the Mattingly correlations at the actual flight Mach and altitude.

    properties
        engine_type       % normalized engine type string
        mil_or_max_power  % 'mil' (dry) or 'max' (wet, afterburner)
        BPR               % bypass ratio
        % Thrust lapse model constants (set from engine type in constructor)
        F1; E; F2; TR     % Mattingly lapse coefficients
        TSFC_sl           % sea-level TSFC (1/s), used in lapse model
    end

    methods
        function obj = PropulsionLevel3(engine_type, mil_or_max_power, BPR)
            if nargin < 2; mil_or_max_power = "mil"; end
            if nargin < 3; BPR = 0; end
            obj.engine_type      = PropulsionUtils.classify_engine_type(engine_type);
            obj.mil_or_max_power = mil_or_max_power;
            obj.BPR              = BPR;

            % Default Mattingly constants for low-BPR mixed turbofan (F-16 like)
            % Adjust via subclass constructor if needed.
            obj.F1     = 0.35;
            obj.E      = 1.0;
            obj.F2     = 0.0;
            obj.TR     = 1.07;
            obj.TSFC_sl = PropulsionLevel2.get_TSFC_installed(engine_type, [0, 0], mil_or_max_power);
        end

        function alpha = thrust_lapse(obj, state)
            [~, ~, P_sl, ~]    = atmosisa(0);
            delta_0 = state.P_atm / (P_sl * 0.020885);     % pressure ratio
            theta_0 = state.T_atm / 518.7;                  % temperature ratio
            if obj.mil_or_max_power == "mil"
                T_lapsed = PropulsionLevel3.get_thrust_dry(obj.T0, delta_0, obj.F1, state.mach, obj.E, obj.F2, theta_0, obj.TR);
            else
                T_lapsed = PropulsionLevel3.get_thrust_wet(obj.T0, delta_0, obj.F1, state.mach, obj.E, theta_0, obj.TR, obj.F2);
            end
            alpha = T_lapsed / max(obj.T0, 1e-6);
        end

        function tsfc = TSFC(obj, state)
            tsfc = PropulsionLevel2.get_TSFC_installed(obj.engine_type, ...
                [state.mach, state.altitude], obj.mil_or_max_power);
        end
    end

    methods (Static)

        function [enginestats] = compute_jet_eng_stats_ab(T, M, BPR)
            enginestats = PropulsionLevel2.compute_jet_eng_stats_ab(T, M, BPR);
        end

        function [enginestats] = compute_jet_eng_stats_noab(T, M, BPR)
            enginestats = PropulsionLevel2.compute_jet_eng_stats_noab(T, M, BPR);
        end

        function output = compute_theta_0(theta, gamma, M_0)
            output = theta*(1 + ((gamma-1)/2)*M_0^2);
        end

        function output = compute_delta_0(delta, gamma, M_0)
            output = delta*(1 + ((gamma-1)/2)*M_0^2);
        end

        function eng_scale = scale_engine(L_actual, D_actual, W_actual, T_actual, T_required)
            SF = T_required / T_actual;
            eng_scale.SF = SF;
            eng_scale.L  = L_actual * SF^0.4;
            eng_scale.D  = D_actual * SF^0.5;
            eng_scale.W  = W_actual * SF^1.1;
        end

        function output = get_theta(state_input)
            h_ft = state_input(2);
            [T]  = atmosisa(h_ft * 0.3048);
            output = PropulsionUtils.theta(T);
        end

        function output = get_delta(state_input)
            h_ft   = state_input(2);
            [~, ~, P] = atmosisa(h_ft * 0.3048);
            output = PropulsionUtils.delta(P/1000);
        end

        function T_dry = get_thrust_dry(t_sl_dry, delta_0, F1, M0, E, F2, theta_0, TR)
            if theta_0 <= TR
                T_dry = t_sl_dry * delta_0 * (1 - F1*M0^E);
            else
                T_dry = t_sl_dry * delta_0 * (1 - F1*M0^E - F2*(theta_0-TR)/theta_0);
            end
        end

        function TSFC_dry = get_TSFC_dry(theta_0, TSFC_sl_dry, M, thrust, thrust_sl, TR)
            if theta_0 <= TR
                TSFC_dry = TSFC_sl_dry*(1.0 + 0.35*(M-0.0))*(thrust/thrust_sl)^0.5;
            else
                TSFC_dry = TSFC_sl_dry*(1.0 + 0.35*M)*(thrust/thrust_sl)^0.5;
            end
        end

        function T_wet = get_thrust_wet(t_sl_wet, delta_0, F1, M0, E, theta_0, TR, F2)
            if theta_0 <= TR
                T_wet = t_sl_wet * delta_0 * (1 - F1*M0^E);
            else
                T_wet = t_sl_wet * delta_0 * (1 - F1*M0^E - F2*(theta_0-TR)/theta_0);
            end
        end

        function TSFC_wet = get_TSFC_wet(TSFC_sl_wet, M, thrust, thrust_sl, theta_0, TR)
            if theta_0 <= TR
                TSFC_wet = TSFC_sl_wet*(1.0 + 0.35*(M-0.4))*(thrust/thrust_sl)^0.5;
            else
                TSFC_wet = TSFC_sl_wet*(1.0 + 0.35*abs(M-0.4))*(thrust/thrust_sl)^0.5;
            end
        end

        function J = compute_advance_ratio(V, n, D)
            J = V / (n*D);
        end

        function cp = compute_cp(P, rho, n, D)
            cp = P / (rho*n^3*D^5);
        end

        function ct = compute_ct(T, rho, n, D)
            ct = T / (rho*n^2*D^4);
        end

        function eta_p = compute_prop_efficiency(T, V, P)
            eta_p = (T*V) / P;
        end

        function thrust = compute_prop_thrust_moving(P, eta_p, V)
            thrust = P * eta_p / V;
        end

    end

end

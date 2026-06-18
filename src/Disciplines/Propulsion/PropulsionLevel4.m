classdef PropulsionLevel4 < PropulsionBase
    % Level IV propulsion: Raymer Ch 10 component-level engine sizing.
    %
    % Inherits from PropulsionBase (not PropulsionModelLevel3).
    % Provides detailed engine weight, length, and diameter estimates from
    % Raymer's scaling equations.  TSFC and thrust_lapse use the Level III
    % Mattingly models.

    properties
        engine_type
        mil_or_max_power
        BPR
        enginestats     % struct: W, L, D, SFC_maxT, T_cruise, SFC_cruise
    end

    methods
        function obj = PropulsionLevel4(engine_type, mil_or_max_power, BPR)
            if nargin < 2; mil_or_max_power = "mil"; end
            if nargin < 3; BPR = 0; end
            obj.engine_type      = PropulsionUtils.classify_engine_type(engine_type);
            obj.mil_or_max_power = mil_or_max_power;
            obj.BPR              = BPR;
            obj.enginestats      = struct();
        end

        function alpha = thrust_lapse(obj, state)
            [~, ~, P_sl, ~] = atmosisa(0);
            delta_0 = state.P_atm / (P_sl * 0.020885);
            theta_0 = state.T_atm / 518.7;
            F1 = 0.35; E = 1.0; F2 = 0.0; TR = 1.07;
            if obj.mil_or_max_power == "mil"
                T_lapsed = PropulsionLevel3.get_thrust_dry(obj.T0, delta_0, F1, state.mach, E, F2, theta_0, TR);
            else
                T_lapsed = PropulsionLevel3.get_thrust_wet(obj.T0, delta_0, F1, state.mach, E, theta_0, TR, F2);
            end
            alpha = T_lapsed / max(obj.T0, 1e-6);
        end

        function tsfc = TSFC(obj, state)
            tsfc = PropulsionLevel2.get_TSFC_installed(obj.engine_type, ...
                [state.mach, state.altitude], obj.mil_or_max_power);
        end

        function stats = get_engine_stats(obj, M_dash)
            % Compute Raymer Ch 10 engine stats at the given dash Mach and T0.
            if obj.mil_or_max_power == "max"
                stats = PropulsionLevel3.compute_jet_eng_stats_ab(obj.T0, M_dash, obj.BPR);
            else
                stats = PropulsionLevel3.compute_jet_eng_stats_noab(obj.T0, M_dash, obj.BPR);
            end
            obj.enginestats = stats;
        end
    end

end

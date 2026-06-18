classdef PropulsionLevel2 < PropulsionBase
    % Level II propulsion: Mattingly installed TSFC and Raymer Ch 10 engine stats.
    %
    % thrust_lapse uses the same density-ratio power law as Level I
    % (Mattingly lapse is in Level III).  TSFC is computed from Mattingly's
    % installed TSFC correlations rather than a lookup table.
    %
    % Usage:
    %   prop = PropulsionLevel2('low_bypass_mixed_turbofan', 'mil');
    %   prop.T0 = 23770;
    %   tsfc = prop.TSFC(AircraftState(35000, 0.85));

    properties
        engine_type       % normalized engine type string
        mil_or_max_power  % 'mil' or 'max' (for afterburning engines)
        BPR               % bypass ratio (used for engine sizing equations)
        lapse_exponent    % exponent in (rho/rho_sl)^n model
    end

    methods
        function obj = PropulsionLevel2(engine_type, mil_or_max_power, BPR)
            if nargin < 2; mil_or_max_power = "mil"; end
            if nargin < 3; BPR = 0; end
            obj.engine_type      = PropulsionUtils.classify_engine_type(engine_type);
            obj.mil_or_max_power = mil_or_max_power;
            obj.BPR              = BPR;

            switch obj.engine_type
                case {"turbojet","low_bypass_mixed_turbofan"}
                    obj.lapse_exponent = 0.7;   % sigma^0.7 empirical for AB turbofan
                case "high_bypass_turbofan"
                    obj.lapse_exponent = 0.7;
                otherwise
                    obj.lapse_exponent = 0.7;
            end
        end

        function alpha = thrust_lapse(obj, state)
            [~, ~, ~, rho_sl] = atmosisa(0);
            alpha = (state.rho / (rho_sl * 0.00194032033))^obj.lapse_exponent;
        end

        function tsfc = TSFC(obj, state)
            tsfc = PropulsionLevel2.get_TSFC_installed(obj.engine_type, ...
                [state.mach, state.altitude], obj.mil_or_max_power);
        end
    end

    methods (Static)

        function output = get_theta(state_input)
            h_ft = state_input(2);
            [T]  = atmosisa(h_ft * 0.3048);
            output = PropulsionUtils.theta(T);
        end

        function output = get_TSFC_installed(engine_type, state_input, mil_or_max_power)
            M0    = state_input(1);
            theta = PropulsionLevel2.get_theta(state_input);
            engine_type = PropulsionUtils.classify_engine_type(engine_type);
            switch engine_type
                case "high_bypass_turbofan"
                    TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
                case "low_bypass_mixed_turbofan"
                    TSFC = PropulsionLevel2.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
                case "turbojet"
                    TSFC = PropulsionLevel2.comp_TSFC_turbojet(M0, theta, mil_or_max_power);
                case "turboprop"
                    TSFC = PropulsionLevel2.comp_TSFC_turboprop(M0, theta);
                otherwise
                    error("Unrecognized engine type: %s", engine_type)
            end
            output = TSFC / 3600;
        end

        function [enginestats] = compute_jet_eng_stats_ab(T, M, BPR)
            enginestats.W          = 0.063*T^1.1*M^0.25*exp(-0.81*BPR);
            enginestats.L          = 0.255*T^0.4*M^0.2;
            enginestats.D          = 0.024*T^0.5*exp(0.04*BPR);
            enginestats.SFC_maxT   = 2.1*exp(-0.12*BPR)/3600;
            enginestats.T_cruise   = 2.4*T^0.74*exp(0.023*BPR);
            enginestats.SFC_cruise = 1.04*exp(-0.186*BPR)/3600;
        end

        function [enginestats] = compute_jet_eng_stats_noab(T, M, BPR)
            enginestats.W          = 0.084*T^1.1*exp(-0.045*BPR);
            enginestats.L          = 0.185*T^0.4*M^0.2;
            enginestats.D          = 0.033*T^0.5*exp(0.04*BPR);
            enginestats.SFC_maxT   = 0.67*exp(-0.12*BPR)/3600;
            enginestats.T_cruise   = 0.60*T^0.9*exp(0.02*BPR);
            enginestats.SFC_cruise = 0.88*exp(-0.05*BPR)/3600;
        end

        function output = comp_TSFC_highBPRturbofan(M_0, theta)
            output = (0.45 + 0.54*M_0)*sqrt(theta);
        end

        function output = comp_TSFC_lowBPRmixedturbofan(M_0, theta, mil_or_max_power)
            if mil_or_max_power == "mil"
                output = (0.9 + 0.30*M_0)*sqrt(theta);
            elseif mil_or_max_power == "max"
                output = (1.6 + 0.27*M_0)*sqrt(theta);
            else
                error("mil_or_max_power must be 'mil' or 'max'.")
            end
        end

        function output = comp_TSFC_turbojet(M_0, theta, mil_or_max_power)
            if mil_or_max_power == "mil"
                output = (1.1 + 0.30*M_0)*sqrt(theta);
            elseif mil_or_max_power == "max"
                output = (1.5 + 0.23*M_0)*sqrt(theta);
            else
                error("mil_or_max_power must be 'mil' or 'max'.")
            end
        end

        function output = comp_TSFC_turboprop(M_0, theta)
            output = (0.18 + 0.8*M_0)*sqrt(theta);
        end

        function A_Astar = compute_A_Astar(M)
            A_Astar = (1/M)*((1+0.2*M^2)/1.2)^3;
        end

        function K_p = get_Kp(n_blades)
            if n_blades == 2;     K_p = 1.7;
            elseif n_blades == 3; K_p = 1.6;
            elseif n_blades >= 4; K_p = 1.5;
            else; error("n_blades must be >= 2.")
            end
        end

        function D = compute_D_from_power_req(n_blades, Power)
            K_p = PropulsionLevel2.get_Kp(n_blades);
            D   = K_p * (Power^0.25);
        end

    end

end

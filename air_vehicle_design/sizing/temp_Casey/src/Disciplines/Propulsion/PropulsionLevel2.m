classdef PropulsionLevel2
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This should use MAttingly's work
     % Also going to use Raymer's Chapter 10 work.
     % This should be able to distinguish better between engine types.
     % Should have equations for estimating TSFC.

     properties
     end

     methods (Static)


          % Get theta (wrapper)
          function output = get_theta(state_input)
               h_ft = state_input(2);
               [T] = atmosisa(h_ft*0.3048);
               output = PropulsionUtils.theta(T);
          end


          % Estimate installed TSFC (preliminary) (wrapper) (1/sec)
          function output = get_TSFC_installed(engine_type, state_input, mil_or_max_power)
               M0 = state_input(1);
               theta = PropulsionLevel2.get_theta(state_input);
               engine_type = PropulsionUtils.classify_engine_type(engine_type); % "normalize" engine type input.
               if (engine_type == "high_bypass_turbofan")
                    if M0 <= 0.9
                         TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
                    else
                         warning("Cannot use high-BPR turbofan for M > 0.9.")
                         TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
                    end
               elseif (engine_type == "low_bypass_mixed_turbofan")
                    TSFC = PropulsionLevel2.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
               elseif (engine_type == "turbojet")
                    TSFC = PropulsionLevel2.comp_TSFC_turbojet(M0, theta, mil_or_max_power);
               elseif (engine_type == "turboprop")
                    TSFC = PropulsionLevel2.comp_TSFC_turboprop(M0, theta);
               else
                    error("Could not identify engine type." + newline + "Accepted types:" + newline + "High bypass turbofan" + newline + "Low bypass mixed turbofan" + newline + "turbojet" + newline + "turboprop")
               end
               output = TSFC/3600;
          end


          % Estimate engine properties (AFTERBURNING ENGINE, IMPERIAL
          % UNITS) (valid for 36000 ft)
          function [enginestats] = compute_jet_eng_stats_ab(T, M, BPR)
               % Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
               % 10.15

               % ARGUMENTS
               % W = Weight (lbf)
               % T = Takeoff thrust (lbf)
               % BPR = Bypass ratio
               % M = Mach number

               % Afterburning engines (imperial units)
               W = @(T, M, BPR) (0.063*T^(1.1)*M^(0.25)*exp(-0.81*BPR)); % Engine weight (lbf) (eq 10.10, 6th ed) (IDK if this is "installed weight")
               L = @(T, M) (0.255*T^(0.4)*M^(0.2)); % Engine length (ft) (eq 10.11, 6th ed)
               D = @(T, BPR) (0.024*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft) (eq 10.12, 6th ed)
               SFC_maxT = @(BPR) (2.1*exp(-0.12*BPR)); % SFC at max thrust (1/hr) (eq 10.13, 6th ed)
               T_cruise = @(T, BPR) (2.4*T^(0.74)*exp(0.023*BPR)); % Cruise thrust (lbf) (eq 10.14, 6th ed)
               SFC_cruise = @(BPR) (1.04*exp(-0.186*BPR)); % SFC at cruise conditions (1/hr) (eq 10.15, 6th ed)

               enginestats.W = W(T, M, BPR);
               enginestats.L = L(T, M);
               enginestats.D = D(T, BPR);
               enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
               enginestats.T_cruise = T_cruise(T, BPR);
               enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);
          end

          % Estimate engine properties (NONAFTERBURNING ENGINE, IMPERIAL
          % UNITS)
          function [enginestats] = compute_jet_eng_stats_noab(T, M, BPR)
               % Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
               % 10.15

               % ARGUMENTS
               % W = Weight (lbf)
               % T = Takeoff thrust (lbf)
               % BPR = Bypass ratio
               % M = Mach number

               % Nonafterburning engines (imperial units)
               W = @(T, BPR) (0.084*T^(1.1)*exp(-0.045*BPR)); % Engine weight (lbf) (eq 10.4, 6th ed)
               L = @(T, M) (0.185*T^(0.4)*M^(0.2)); % Engine length (ft) (eq 10.5, 6th ed)
               D = @(T, BPR) (0.033*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft) (eq 10.6, 6th ed)
               SFC_maxT = @(BPR) (0.67*exp(-0.12*BPR)); % SFC at max thrust (1/hr) (eq 10.7, 6th ed)
               T_cruise = @(T, BPR) (0.60*T^(0.9)*exp(0.02*BPR)); % Cruise thrust (lbf) (eq 10.8, 6th ed)
               SFC_cruise = @(BPR) (0.88*exp(-0.05*BPR)); % SFC at cruise conditions (1/hr) (eq 10.9, 6th ed)

               enginestats.W = W(T, BPR);
               enginestats.L = L(T, M);
               enginestats.D = D(T, BPR);
               enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
               enginestats.T_cruise = T_cruise(T, BPR);
               enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);
          end


          % Estimate TSFC for a high-bypass-ratio turbofan engine (Source: Aircraft Engine Design, Mattingly)
          % Valid: M_0 < 0.9
          function output = comp_TSFC_highBPRturbofan(M_0, theta)
               output = (0.45 + 0.54*M_0)*sqrt(theta);
          end

          % Estimate TSFC for a low-BPR mixed turbofan engine (Source: Aircraft Engine Design, Mattingly)
          function output = comp_TSFC_lowBPRmixedturbofan(M_0, theta, mil_or_max_power)
               if (mil_or_max_power == "mil")
                    output = (0.9 + 0.30*M_0)*sqrt(theta); % Eq 3.55a
               elseif (mil_or_max_power == "max")
                    output = (1.6 + 0.27*M_0)*sqrt(theta); % Eq 3.55b
               else
                    error("mil_or_max_power - must be 'mil' or 'max'.")
               end
          end

          % Estimate TSFC for a turbojet engine (Source: Aircraft Engine Design, Mattingly)
          function output = comp_TSFC_turbojet(M_0, theta, mil_or_max_power)
               if (mil_or_max_power == "mil")
                    output = (1.1 + 0.30*M_0)*sqrt(theta); % Eq 3.56a
               elseif (mil_or_max_power == "max")
                    output = (1.5 + 0.23*M_0)*sqrt(theta); % Eq 3.56b
               else
                    error("mil_or_max_power - must be 'mil' or 'max'.")
               end
          end

          % Estimate A/A* area for jet engine
          function A_Astar = compute_A_Astar(M)
               A_Astar = (1/M)*( (1+0.2*M^2)/(1.2))^3;
          end

          % Estimate capture area for a jet engine
          function A_capture = compute_capture_area(mdot_e, mdot_s, g, rho_inf, V_inf, A_B, A_C)
               A_capture = ( (mdot_e*(1+mdot_s/mdot_e)/(g*rho_inf*V_inf)))*(1 + A_B/A_C);
          end

          % Estimate capture-area ratio
          function capture_area_ratio = compute_capture_area_ratio(mdot_e, mdot_s, mdot_BL, mdot_bypass, g, rho_inf, V_inf, A_C)
               capture_area_ratio = (mdot_e + mdot_s + mdot_BL + mdot_bypass)/(g*rho_inf*V_inf*A_C);
          end


          %% PROPS PROPS PROPS SECTION

          % Estimate TSFC for a turboprop engine (Source: Aircraft Engine Design, Mattingly)
          function output = comp_TSFC_turboprop(M_0, theta)
               output = (0.18 + 0.8*M_0)*sqrt(theta); % Eq 3.57
          end

          % Prop tip speed (static)
          function V_tip_static = compute_static_tip_speed(n, D)
               % n = rotational rate from engine data (rpm)
               % D = diameter
               V_tip_static = pi*n*D;
          end

          % Prop tip speed (helical, considering aircraft's airspeed)
          function V_tip_helical = compute_helical_tip_speed(V_tip_static, V_aircraft)
               V_tip_helical = sqrt(V_tip_static^2 + V_aircraft^2);
          end

          % Propeller diameter from power requirement
          function D = compute_D_from_power_req(n_blades, Power)
               % Where:
               % n_blades = number of blades per engine
               % Power = power required (hp)
               K_p = PropulsionLevel2.get_Kp(n_blades);
               D = K_p*(Power^(1/4)); % Raymer, eq 10.23, 6th ed

          end

          % Tabulate the K_p
          % Raymer, 6th ed, table on page 312 (table number not given)
          function K_p = get_Kp(n_blades)
               if (n_blades == 2)
                    K_p = 1.7;
               elseif (n_blades == 3)
                    K_p = 1.6;
               elseif (n_blades >= 4)
                    K_p = 1.5;
               else
                    error("Error handler.")
               end
          end

          %% DUCTED FANS
          % Estimate weight-to-power ratio
          function W_P = compute_WP_ducted_fan(K, P, A)
               % Where
               % P = Power (hp or kW)
               % A = duct total internall cross section area at fan (ft^2 or m^2)
               % K = 15.4 in FPS, 19.4 in MKS
               W_P = K*(P/A);
          end

     end





     methods (Access = private)


     end
end
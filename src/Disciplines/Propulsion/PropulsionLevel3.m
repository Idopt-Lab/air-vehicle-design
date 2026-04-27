classdef PropulsionLevel3 < PropulsionModelLevel3
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
          T0
     end

     methods

          % Constructor
          function obj = PropulsionLevel3(requirements_obj, design)
               obj.enginestats = get_propulsion_stats(obj, requirements_obj, design);
          end

          % Estimate engine properties
          function enginestats = get_propulsion_stats(propulsion_obj, requirements_obj, design)
               enginestats = get_engine_stats(propulsion_obj, design.propulsion.ThrustseaLevellbf.Dry, requirements_obj.requirements.MaxMach.Mach, design.propulsion.BypassRatio.BypassRatio, design.general.isafterburning);
               % There are multiple versions of equations (afterburning,
               % nonafterburning). Consider adding those, too.
               % Also I need to stop using the tables for value extraction
               % since they take up SO MUCH VISUAL SPACE!!!
          end

          % Estimate engine properties
          function output = get_engine_stats(propulsion_obj, T, M, BPR, isafterburning)
               if (isafterburning == "Y")
                    output = propulsion_obj.compute_eng_stats_ab(T, M, BPR);
               elseif (isafterburning == "N")
                    output = propulsion_obj.compute_eng_stats_noab(T, M, BPR);
               else
                    error ("Couldn't determine if engine is/isn't afterburning. Accepted states: 'Y', 'N'.")
               end
          end

          % Scale engine
          function output = scale_engine(propulsion_obj, L_actual, D_actual, W_actual, T_actual, T_required)
               eng_scale.SF = T_actual/T_required;
               eng_scale.L = L_actual*SF^(0.4); % Raymer, 6th ed, eq 10.1
               eng_scale.D = D_actual*SF^(0.5); % Raymer, 6th ed, eq 10.2
               eng_scale.W = W_actual*SF^(1.1); % Raymer, 6th ed, eq 10.3

               output = eng_scale;
          end

          % Compute TSFC (wrapper)
          function output = get_TSFC(propulsion_obj, state_input, isdryorwet, thrust_sl, TSFC_sl, E, F1, F2, TR)
               M0 = state_input(1);
               h_ft = state_input(2);
               theta = propulsion_obj.get_theta(state_input);
               delta = propulsion_obj.get_delta(state_input);
               theta_0 = propulsion_obj.compute_theta_0(theta, PropulsionUtils.gamma, M0);
               delta_0 = propulsion_obj.compute_delta_0(delta, PropulsionUtils.gamma, M0);
               if isdryorwet=="dry"
                    % Compute TSFC for dry config
                    thrust = propulsion_obj.get_thrust_dry(thrust_sl, delta_0, F1, M0, E, F2, theta_0, TR);
                    output = propulsion_obj.get_TSFC_dry(theta_0, TSFC_sl, M0, thrust, thrust_sl, TR);
               elseif isdryorwet == "wet"
                    % Compute TSFC for wet config
                    thrust = propulsion_obj.get_thrust_wet(thrust_sl, delta_0, F1, M0, E, theta_0, TR, F2);
                    output = get_TSFC_wet(propulsion_obj, theta_0, TSFC_sl, M0, thrust, thrust_sl, TR);
               else
                    error("Error handler. Must be 'dry' or 'wet'.")
               end
          end

          % Get theta (wrapper)
          function output = get_theta(propulsion_obj, state_input)
               h_ft = state_input(2);
               [T] = atmosisa(h_ft*0.3048);
               output = PropulsionUtils.theta(T);
          end

          % Get delta (wrapper)
          function output = get_delta(propulsion_obj, state_input)
               h_ft = state_input(2);
               [T, a, P] = atmosisa(h_ft*0.3048);
               output = PropulsionUtils.delta(P/1000);
          end

          %% For low_bpr_turbofan/jet, theta0<=TR
          % Get thrust (dry)
          function output = get_thrust_dry(propulsion_obj, t_sl_dry, delta_0, F1, M0, E, F2, theta_0, TR)
               if theta_0<=TR
                    output = t_sl_dry*delta_0*(1 - F1*M0^(E));
               elseif theta_0>TR
                    output = t_sl_dry*delta_0*(1 - F1*M0^(E) - (F2 *(theta_0 - TR)/(theta_0)));
               end
          end

          % Get TSFC (dry)
          function output = get_TSFC_dry(propulsion_obj, theta_0, TSFC_sl_dry, M, thrust, thrust_sl, TR)
               if theta_0 <= TR
                    output = TSFC_sl_dry*(1.0 + 0.35*(M - 0.0))*(thrust/thrust_sl)^(0.5);
               elseif theta_0 > TR
                    output = TSFC_sl_dry*(1.0 + 0.35*M)*(thrust/thrust_sl)^(0.5);
               else
                    error("Error handler.")
               end
          end

          % Get thrust (wet)
          function output = get_thrust_wet(propulsion_obj, t_sl_wet, delta_0, F1, M0, E, theta_0, TR, F2)
               if theta_0<=TR
                    output = t_sl_wet*delta_0*(1 - F1*M0^(E));
               elseif theta_0>TR
                    output = t_sl_wet*delta_0*(1 - F1*M0^(E) - (F2*(theta_0 - TR)/theta_0));
               else
                    error("Error handler.")
               end
          end

          % Get TSFC (wet)
          function output = get_TSFC_wet(propulsion_obj, TSFC_sl_wet, M, thrust, thrust_sl, theta_0, TR)
               if theta_0 <= TR
                    output = TSFC_sl_wet*(1.0 + 0.35*(M - 0.4))*(thrust/thrust_sl)^(0.5);
               elseif theta_0 > TR
                    output = TSFC_sl_wet*(1.0 + 0.35*abs(M - 0.4))*(thrust/thrust_sl)^(0.5);
               else
                    error("Error handler.")
               end
          end
     end

     methods (Access = private)


          % Estimate engine properties (AFTERBURNING ENGINE, IMPERIAL
          % UNITS)
          function [enginestats] = compute_eng_stats_ab(propulsion_obj, T, M, BPR)
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
          function [enginestats] = compute_eng_stats_noab(propulsion_obj, T, M, BPR)
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

          % Get theta_0
          function output = compute_theta_0(propulsion_obj, theta, gamma, M_0)
               output = theta*(1 + ((gamma-1)/2) * M_0^2);
          end

          % Get delta_0
          function output = compute_delta_0(propulsion_obj, delta, gamma, M_0)
               output = delta*(1 + ((gamma-1)/2) * M_0^2);
          end


     end
end
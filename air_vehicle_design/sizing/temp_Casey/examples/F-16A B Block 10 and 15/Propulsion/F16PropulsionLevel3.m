classdef F16PropulsionLevel3 < PropulsionModelLevel3
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginetype
          enginestats
          TSFC
          T0 % Thrust at sea level from sizing (lbf)
          T0_guess % Initial guess for thrust (lbf)
          T_SL_dry
          T_SL_wet
          TSFC_SL_dry
          TSFC_SL_wet
          TR = 1.0
          isafterburning
          BPR
     end

     methods

          % Constructor
          function obj = F16PropulsionLevel3(requirements_obj, design)
               obj.enginetype = "low_bpr_turbofan";
               obj.T_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               obj.T_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.TSFC_SL_dry = design.propulsion.TSFCseaLevelperHour.Dry;
               obj.TSFC_SL_wet = design.propulsion.TSFCseaLevelperHour.Wet;
               obj.BPR = design.propulsion.BypassRatio.BypassRatio;
               obj.isafterburning = "Y";
               obj.enginestats.quantity = 1;
               M = requirements_obj.requirements.MaxMach.Mach;
               T = obj.T_SL_wet;
               BPR = obj.BPR;
               obj.enginestats = obj.get_engine_stats(T, M, BPR, "Y");
          end

          % % Estimate engine properties
          % function enginestats = get_propulsion_stats(propulsion_obj, requirements_obj)
          %      enginestats = PropulsionLevel3.get_engine_stats(propulsion_obj.T_SL_wet, requirements_obj.requirements.MaxMach.Mach, propulsion_obj.BPR, propulsion_obj.isafterburning);
          % end

          % Estimate engine properties
          function output = get_engine_stats(aero_obj, T, M, BPR, isafterburning)
               if (isafterburning == "Y")
                    output = PropulsionLevel3.compute_jet_eng_stats_ab(T, M, BPR);
               elseif (isafterburning == "N")
                    output = PropulsionLevel3.compute_jet_eng_stats_noab(T, M, BPR);
               else
                    error ("Couldn't determine if engine is/isn't afterburning. Accepted states: 'Y', 'N'.")
               end
          end

          % Compute TSFC (wrapper)
          function output = get_TSFC(propulsion_obj, state_input, isdryorwet, thrust_sl, TSFC_sl, E, F1, F2, TR)
               M0 = state_input(1);
               h_ft = state_input(2);
               theta = PropulsionLevel3.get_theta(state_input);
               delta = PropulsionLevel3.get_delta(state_input);
               theta_0 = PropulsionLevel3.compute_theta_0(theta, PropulsionUtils.gamma, M0);
               delta_0 = PropulsionLevel3.compute_delta_0(delta, PropulsionUtils.gamma, M0);
               if (isdryorwet=="dry") || (isdryorwet=="Dry")
                    % Compute TSFC for dry config
                    thrust = PropulsionLevel3.get_thrust_dry(thrust_sl, delta_0, F1, M0, E, F2, theta_0, TR);
                    output = PropulsionLevel3.get_TSFC_dry(theta_0, TSFC_sl, M0, thrust, thrust_sl, TR);
               elseif (isdryorwet == "wet") || (isdryorwet == "Wet")
                    % Compute TSFC for wet config
                    thrust = PropulsionLevel3.get_thrust_wet(thrust_sl, delta_0, F1, M0, E, theta_0, TR, F2);
                    output = PropulsionLevel3.get_TSFC_wet(TSFC_sl, M0, thrust, thrust_sl, theta_0, TR);
               else
                    error("Error handler. Must be 'dry' or 'wet'.")
               end
               output = output/3600; % Convert TSFC from 1/hr -> 1/sec
          end

          % Compute thrust lapse rate
          function alpha = get_alpha(propulsion_obj, statevector, maxormilpower)
               % Check if "maxormilpower" is valid
               if ((maxormilpower ~= "max") && (maxormilpower ~= "Max")) && ((maxormilpower ~= "mil") && (maxormilpower ~= "Mil"))
                    error("maxormilpower must be 'Max' or 'Mil'.")
               elseif (maxormilpower == "max") || (maxormilpower == "Max") || (maxormilpower == "mil") || (maxormilpower == "Mil")
                    M_0 = statevector(1);
                    h_ft = statevector(2);
                    gamma = 1.4;
                    [T_kelvin, a, P] = atmosisa(h_ft*0.3048);
                    P_kPa = P/1000; % Convert pascals to kilopascals
                    % Get theta
                    theta = PropulsionUtils.theta(T_kelvin);
                    % Get theta_0
                    theta_0 = PropulsionUtils.theta_0(theta, gamma, M_0);
                    % Get delta
                    delta = PropulsionUtils.delta(P_kPa);
                    % Get delta_0
                    delta_0 = PropulsionUtils.delta_0(delta, gamma, M_0);

                    % Get TR if not already computed (should be stored in
                    % properties)
                    % If TR is unknown, set to 1.0

                    % Compute alpha
                    if (maxormilpower == "Max") || (maxormilpower == "max")
                         alpha = PropulsionUtils.compute_alpha_lowBPR_turbofan_maxpower(delta_0, theta_0, propulsion_obj.TR);
                    elseif (maxormilpower == "Mil") || (maxormilpower == "mil")
                         alpha = PropulsionUtils.compute_alpha_lowBPR_turbofan_milpower(delta_0, theta_0, propulsion_obj.TR);
                    end
               else
                    error("Error handler.")
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

          % %% For low_bpr_turbofan/jet, theta0<=TR
          % % Get thrust (dry)
          % function output = get_thrust_dry(propulsion_obj, t_sl_dry, delta_0, F1, M0, E, F2, theta_0, TR)
          %      if theta_0<=TR
          %           output = t_sl_dry*delta_0*(1 - F1*M0^(E));
          %      elseif theta_0>TR
          %           output = t_sl_dry*delta_0*(1 - F1*M0^(E) - (F2 *(theta_0 - TR)/(theta_0)));
          %      end
          % end
          %
          % % Get TSFC (dry)
          % function output = get_TSFC_dry(propulsion_obj, theta_0, TSFC_sl_dry, M, thrust, thrust_sl, TR)
          %      if theta_0 <= TR
          %           output = TSFC_sl_dry*(1.0 + 0.35*(M - 0.0))*(thrust/thrust_sl)^(0.5);
          %      elseif theta_0 > TR
          %           output = TSFC_sl_dry*(1.0 + 0.35*M)*(thrust/thrust_sl)^(0.5);
          %      else
          %           error("Error handler.")
          %      end
          % end
          %
          % % Get thrust (wet)
          % function output = get_thrust_wet(propulsion_obj, t_sl_wet, delta_0, F1, M0, E, theta_0, TR, F2)
          %      if theta_0<=TR
          %           output = t_sl_wet*delta_0*(1 - F1*M0^(E));
          %      elseif theta_0>TR
          %           output = t_sl_wet*delta_0*(1 - F1*M0^(E) - (F2*(theta_0 - TR)/theta_0));
          %      else
          %           error("Error handler.")
          %      end
          % end
          %
          % % Get TSFC (wet)
          % function output = get_TSFC_wet(propulsion_obj, TSFC_sl_wet, M, thrust, thrust_sl, theta_0, TR)
          %      if theta_0 <= TR
          %           output = TSFC_sl_wet*(1.0 + 0.35*(M - 0.4))*(thrust/thrust_sl)^(0.5);
          %      elseif theta_0 > TR
          %           output = TSFC_sl_wet*(1.0 + 0.35*abs(M - 0.4))*(thrust/thrust_sl)^(0.5);
          %      else
          %           error("Error handler.")
          %      end
          % end
     end

     methods (Access = private)


     end
end
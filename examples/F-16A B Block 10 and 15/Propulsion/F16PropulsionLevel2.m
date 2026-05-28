classdef F16PropulsionLevel2 < PropulsionModelLevel2
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginetype
          enginestats
          TSFC
          T0 % Thrust at sea level from sizing (lbf)
          T0_guess % Initial guess for thrust (lbf)
          T_SL_dry
          T_SL_wet
          TR = 1.0
     end

     methods

          % Constructor
          function obj = F16PropulsionLevel2(design)
               % obj.t_sl_dry = design.propulsion.ThrustseaLevellbf.Dry;
               % obj.t_sl_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.TSFC.wet_sl = obj.get_TSFC("low bypass mixed turbofan", [0, 0], "max");
               obj.TSFC.dry_sl = obj.get_TSFC("low bypass mixed turbofan", [0, 0], "max");
               obj.T_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               obj.T_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.T0_guess = 25000;
          end

          % Estimate installed TSFC (preliminary) (wrapper) (1/sec)
          function TSFC = get_TSFC(propulsion_obj, engine_type, state_input, mil_or_max_power)
               M0 = state_input(1);
               h_alt = state_input(2);
               [T_kelvin] = atmosisa(h_alt*0.3048);
               theta = PropulsionUtils.theta(T_kelvin);
               engine_type = PropulsionUtils.classify_engine_type(engine_type); % "normalize" engine type input.
               TSFC = PropulsionLevel2.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
               % if (engine_type == "high_bypass_turbofan")
               %      if M0 <= 0.9
               %           TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
               %      else
               %           warning("Cannot use high-BPR turbofan for M > 0.9.")
               %           TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
               %      end
               % elseif (engine_type == "low_bypass_mixed_turbofan")
               %      TSFC = PropulsionLevel2.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
               % elseif (engine_type == "turbojet")
               %      TSFC = PropulsionLevel2.comp_TSFC_turbojet(M0, theta, mil_or_max_power);
               % elseif (engine_type == "turboprop")
               %      TSFC = PropulsionLevel2.comp_TSFC_turboprop(M0, theta);
               % else
               %      error("Could not identify engine type." + newline + "Accepted types:" + newline + "High bypass turbofan" + newline + "Low bypass mixed turbofan" + newline + "turbojet" + newline + "turboprop")
               % end
               TSFC = TSFC/3600;
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

     end





     methods (Access = private)

     end
end
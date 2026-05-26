classdef F16PropulsionLevel1 < PropulsionModelLevel1
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          TSFC
          TR
          T0
          T_SL_dry
          T_SL_wet;
     end

     methods
          % Constructor
          function obj = F16PropulsionLevel1(design)
               engine_type = PropulsionUtils.classify_engine_type(design.propulsion_type);
               obj.T_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               obj.T_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.TSFC = obj.get_TSFC(engine_type);
               obj.TR = 1.0;
          end

          % For a level 1 estimate, we're using tabulated values based on
          % both the type of aircraft and engine.
          function TSFC = get_TSFC(propulsion_obj, engine_type)
               TSFC = PropulsionLevel1.get_TSFC(engine_type);
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
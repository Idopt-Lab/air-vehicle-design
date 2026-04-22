classdef PropulsionLevel2 < PropulsionModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginestats
          T_SL_W_TO
     end

     methods

          % Get T_SL_W_TO across constraints
          function T_SL_W_TO = get_propulsion_stats(obj, design)
               W_TO = design.WeightResults.W_TO;
               q = design.constraints.aero.("q (lbf/ft^2)");
               CD0 = design.constraints.aero.CD0;
               alpha = design.constraints.thrust.throttleLapse;
               beta = design.constraints.W_Wto;
               K_1 = design.constraints.K1;
               K_2 = design.constraints.K2;
               e = design.constraints.e;
               h = design.constraints.Altitude_ft_;
               V = design.constraints.("V (ft/s)");
               delta_t = 0; % Placeholder value (time increment, units unknown)
               n = design.constraints.n;
               S_ref = design.geom.wings.Main.PlanformAreaft2;

               T_SL_W_TO = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t, S_ref);
               % Outputs as an ARRAY, need a STRUCT for easy reading.
          end


          % Get T_SL_W_TO across mission segments
          % I could have one for mission and another for constraint
          % analysis
          % function T_SL_W_TO = get_propulsion_stats(obj, mission_obj, design)
          %      mission_segments = get_segment_names(obj, mission_obj.missiondata);
          %
          %      % Extract segment values
          %      segment_values = get_segment_values(obj, mission_obj.missiondata, mission_segments, design.geom.wings);
          %
          %      for i = 1:length(segment_values)
          %           q = segment_values.mission_segments(i).q;
          %           CD0 = segment_values.mission_segments(i).CD0;
          %           e = segment_values.mission_segments(i).e;
          %           K_1 = segment_values.mission_segments(i).K_1;
          %           K_2 = segment_values.mission_segments(i).K_2;
          %           V = segment_values.mission_segments(i).Vl;
          %
          %           T_SL_W_TO.mission_segments(i) = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t);
          %
          %      end
          % end

          % Get T_SL_W_TO (point-performance)
          function T_SL_W_TO = get_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t)
               % Decompose object arguments into necessary components.
               % Initialize "missiondata" if it hasn't been already
               % So this gets the T_SL_W_TO for... ALL mission segments.
               % This is for the entire design

               T_SL_W_TO = get_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t);
          end
     end





     methods (Access = private)

          % Compute T at altitude
          function T_alt = compute_thrust_at_altitude(altitude)

          end


          % Extract segment values
          % I REALLY don't like this. This is TOO specialized and would fit
          % better in "missionanalysis" or something.
          function segment_values = get_segment_values(obj, missiondata, mission_segments, wings)
               AR = wings.Main.AspectRatio;


               for i=1:length(mission_segments)
                    segment_values.(mission_segments(i)).q = missiondata.(mission_segments(i)).qlbfft2;
                    segment_values.(mission_segments(i)).CD0 = missiondata.(mission_segments(i)).CD0;
                    segment_values.(mission_segments(i)).e = missiondata.(mission_segments(i)).e;
                    % Need alpha, beta
                    % Alpha depends on T_alt/T_SL
                    segment_values.(mission_segments(i)).K1 = 1/(pi*missiondata.(mission_segments(i)).e*AR);
                    segment_values.(mission_segments(i)).K2 = 0;
                    segment_values.(mission_segments(i)).V = missiondata.(mission_segments(i)).Vfts;
                    % segment_values.(mission_segments(i)).alpha =

               end
          end

          % Get segment names (should probably move this to "utilities")
          function mission_segments = get_segment_names(obj, missiondata)
               mission_segments = string(missiondata.meta.outerLabels.fields);
          end


          % Estimate engine properties
          function [T_SL_W_TO] = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t, S_ref)
               % q, CD0, alpha, beta, K_1, K_2, W_TO, S_ref, V)
               % Using equations from Mattingly
               % (So-called "Master Equation")
               % Recall, beta = W_(instant)/W_TO
               % alpha = T_(instant)/T_SL (T_[instant] is the max thrust
               % available at that instant)

               g_0 = 32.2; % Acceleration due to gravity at sea level (ft/s^2)
               % Some substitutes to shorten the equation
               A = q.*CD0./alpha;
               B = q./alpha .* K_1 .* ( (n.*beta)./q).^2;
               C = K_2 .* n .* beta./alpha;
               D = beta./alpha .* (1./V) .* delta_t .* (h + (V.^2)./(2.*g_0));

               T_SL_W_TO = A .* (1./(W_TO./S_ref)) + B .* (W_TO./S_ref) + C + D; % "Master Equation"

          end





     end
end
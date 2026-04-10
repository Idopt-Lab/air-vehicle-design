classdef F16PropulsionEstLevel2 < PropulsionModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginestats
     end

     methods
          % Estimate engine properties
          function output = get_propulsion_stats(obj, mission_obj, design)
               % Decompose object arguments into necessary components.
               % Initialize "missiondata" if it hasn't been already
               % So this gets the T_SL_W_TO for... ALL mission segments.

               % Get aerodynamic components
               % Extract mission segment names
               mission_segments = get_segment_names(mission_obj.missiondata);

               % Extract segment values
               segment_values = get_segment_values(mission_obj.missiondata, mission_segments, design.geom.wings);

               output = propulsion_est_level_II(obj, );
          end
     end





     methods (Access = private)


          % Extract segment values
          function segment_values = get_segment_values(missiondata, mission_segments, wings)
               AR = wings.Main.AspectRatio;


               for i=1:length(mission_segments)
                    q = missiondata.(mission_segments(i)).qlbfft2;
                    CD0 = missiondata.(mission_segments(i)).CD0;
                    e = missiondata.(mission_segments(i)).e;
                    % Need alpha, beta
                    % Alpha depends on T_alt/T_SL
                    K1 = 1/(pi*e*AR);
                    K2 = 0;
                    V = missiondata.(mission_segments(i)).Vfts;
                    
                    segment_values = [q, CD0, e, K1, K2, V]; % I feel like this should be stored somewhere else
               end
          end

          % Get segment names
          function mission_segments = get_segment_names(missiondata)
               mission_segments = string(missiondata.meta.outerLabels.fields);
          end


          % Estimate engine properties
          function [T_SL_W_TO] = propulsion_est_level_II(obj, q, CD0, alpha, beta, K_1, K_2, W_TO, S_ref, V)
               % Using equations from Mattingly
               % (So-called "Master Equation")
               % Recall, beta = W_(instant)/W_TO
               % alpha = T_(instant)/T_SL (T_[instant] is the max thrust
               % available at that instant)

               % Some substitutes to shorten the equation
               A = q*CD0/alpha;
               B = q/alpha * K_1 * ( (eta*beta)/q)^2;
               C = K_2 * eta * beta/alpha;
               D = beta/alpha * (1/V) * delta_t * (h + (V^2)/(2*g_0));

               T_SL_W_TO = A * (1/(W_TO/S_ref)) + B * (W_TO/S_ref) + C + D; % "Master Equation"

          end





     end
end
classdef F16WeightEstLevel4 < WeightEstModel
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          total_fuel_used
          eps % Error tolerance
     end

     methods

          function [MTOW, total_fuel_used] = compute_MTOW(obj, design)

               segment_names = get_segment_names(obj, design);

               total_fuel_burned = compute_mission_fuel_weight(obj, design)

          end

          function total_fuel_used = compute_total_fuel_used(obj, design)

          end
     end

     methods (Access = private)
          function segment_names = get_segment_names(obj, design)
               segment_names = string(missiondata.Properties.VariableNames);

               for i=1:lenght(segment_names)
                    current_segment = segment_names(i);
                    mission.(current_segment) = missiondata(:, (current_segment));
               end

          end
          [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
          [LD_ratio] = compute_LD_revised(W, q, S, CD0, e, AR)
          [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
          [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
          [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
          [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
          [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
          [W_out, fuel_used] = segment_landing(W_in, W_TO)
          [W_out, fuel_used] = segment_loiter(W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC)
          [W_out, fuel_used] = segment_startup(W_in)
          [W_out, fuel_used] = segment_takeoff(W_in)
          [W_out, fuel_used] = segment_taxi(W_in)

     end
end
classdef MissionAnalysisLevel2 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % Lower fidelity level than 3.

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          eps
     end

     methods (Static)

          % Arguments should be design-specific geometric or aerodynamic
          % properties extracted from objects (... which are themselves the
          % design).
          % I probably don't even need this any more.
          function segment_names = get_segment_names(obj, design, missiondata)
               segment_names = string(missiondata.Properties.VariableNames);

               for i=1:lenght(segment_names)
                    current_segment = segment_names(i);
                    mission.(current_segment) = missiondata(:, (current_segment));
               end

          end






          function [LD_ratio] = compute_LD_ratio(W, W_TO, q, CD0, W_S, e, AR)
               W_by_W_TO = W / W_TO;
               W_by_S = W_by_W_TO * W_S;
               LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          end


          function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - un-revised.
          function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
               WF_Climb = 1.0065 - 0.0325 * Mach;
               fuel_used = (1 - WF_Climb) * W_in;
               W_out = W_in - fuel_used;
          end



          % Combat segment - un-revised
          function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  W_S)
               LD = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end

          % Cruise segment - un-revised
          function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
               V = Mach * a;
               LD = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = MissionAnalysisLevel2.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;

          end

          function [W_out, fuel_used] = segment_dash(W_in, W_S, W_TO, q, CD0, e, AR, TSFC, Distance, V)
               LD = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = MissionAnalysisLevel2.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_landing(W_in, W_TO)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_loiter(W_TO, W_in, W_S, q, CD0, e, AR, time, TSFC)
               LD = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end


          function [W_out, fuel_used] = segment_startup(W_in)
               WF = 0.99;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_takeoff(W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_taxi(W_in)
               WF = 0.98;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end
     end
end
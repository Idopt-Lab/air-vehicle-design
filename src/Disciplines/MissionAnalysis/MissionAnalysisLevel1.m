classdef MissionAnalysisLevel1
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % Lower fidelity level than 3.

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          segment_names
          eps
     end

     methods (Static)

          % Get LD ratio (wrapper)
          function [LD_ratio] = compute_LD_ratio(segment_name, LD)
               if (segment_name == "cruise") || (segment_name == "combat") || (segment_name == "dash")
                    LD_ratio = LD*0.866;
               elseif (segment_name == "loiter")
                    LD_ratio = LD;
               else
                    error("Error handler.")
               end
          end


          % Computing weight fraction (should go in "weight" class?
          function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - un-revised.
          function [W_out, fuel_used] = segment_climb(W_in, Mach)
               WF_Climb = 1.0065 - 0.0325 * Mach;
               fuel_used = (1 - WF_Climb) * W_in;
               W_out = W_in - fuel_used;
          end



          % Combat segment - un-revised
          function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "combat");
               LD_combat = MissionAnalysisLevel1.compute_LD_ratio("combat", LD);
               WF = exp(-(time * 60 * TSFC / LD_combat));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end

          % Cruise segment - un-revised
          function [W_out, fuel_used] = segment_cruise(W_in, TSFC, Distance, Mach, a, LD)
               V = Mach * a;
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "cruise");
               LD_cruise = MissionAnalysisLevel1.compute_LD_ratio("dash", LD);
               WF = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_cruise);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Dash segment
          function [W_out, fuel_used] = segment_dash(W_in, TSFC, Distance, V, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "dash");
               LD_dash = MissionAnalysisLevel1.compute_LD_ratio("dash", LD);
               WF = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_dash);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Landing segment
          function [W_out, fuel_used] = segment_landing(W_in)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Loiter segment
          function [W_out, fuel_used] = segment_loiter(W_in, time, TSFC, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "loiter");
               LD_loiter = MissionAnalysisLevel1.compute_LD_ratio("loiter", LD);
               WF = exp(-(time * 60 * TSFC / LD_loiter));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Takeoff segment
          function [W_out, fuel_used] = segment_takeoff(W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end
     end
end
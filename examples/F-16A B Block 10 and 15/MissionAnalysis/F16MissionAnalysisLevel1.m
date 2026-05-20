classdef F16MissionAnalysisLevel1 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % Lower fidelity level than 3.

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          segment_names
          eps
     end

     methods
          % Constructor
          function obj = F16MissionAnalysisLevel1(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(Chosen_Mission);
               obj.segment_names = fieldnames(obj.missiondata);
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, propulsion_obj, W_TO, LD_max)
               % This is where we actually compute the fuel for the mission
               % AR = design.geom.wings.Main.AspectRatio;

               % W_S = 104.59;
               % W_S = constraint_obj.optimal_WS;
               % T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               % S_ref = geometry_obj.mainwings.S_ref;
               % T0 = propulsion_obj.T0;

               % Automate segment stuff
               segmentnames = fields(mission_obj.missiondata);
               fuelburnedarray = zeros(1,length(segmentnames));
               W_array = zeros(1, length(segmentnames));
               W_payload_drop = mission_obj.missiondata.Combat.PayloadDroplbf;

               W_array(1) = W_TO;

               % Get TSFC values (these aren't really dynamic, since
               % they're level 1, so no need to update with each segment).
               TSFC_cruise = propulsion_obj.TSFC.cruise;
               TSFC_loiter = propulsion_obj.TSFC.loiter;
               TSFC_dash = TSFC_cruise*10;

               for i=1:length(segmentnames)

                    currentsegment = segmentnames{i};
                    % Clip extra letters from segment name, but don't store
                    % the result permanently
                    currentsegment = erase(currentsegment, '_');
                    currentsegment = erase(currentsegment, {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'});

                    % Extract necessary info from current segment
                    % Checks if current segment is "meta" (artefact from
                    % table -> struct conversion.
                    if (currentsegment == "meta")
                         break
                    else
                         M = mission_obj.missiondata.(currentsegment).MachNumber;
                         alt = mission_obj.missiondata.(currentsegment).Altitudeft;
                         q = mission_obj.missiondata.(currentsegment).qlbfft2;
                         a = mission_obj.missiondata.(currentsegment).afts;
                         % CD0 = mission_obj.missiondata.(currentsegment).CD0;
                         % TSFC = mission_obj.missiondata.(currentsegment).TSFC;
                    end
                    if (currentsegment == "startup") || (currentsegment == "Startup")
                         % [W_array(i), fuelburnedarray(i)] = mission_obj.segment_startup(W_array(i));
                         % Skip these
                         W_array(i) = W_TO;
                    elseif (currentsegment == "taxi") || (currentsegment == "Taxi")
                         % [W_array(i), fuelburnedarray(i)] = mission_obj.segment_taxi(W_array(i-1));
                         % Skip these
                         W_array(i) = W_TO;
                    elseif (currentsegment == "takeoff") || (currentsegment == "Takeoff")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_takeoff(W_array(i-1));
                    elseif (currentsegment == "climb") || (currentsegment == "Climb")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_climb(W_array(i-1), M);
                    elseif (currentsegment == "cruise") || (currentsegment == "Cruise")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_cruise(W_array(i-1), TSFC_cruise, mission_obj.missiondata.Cruise.Rangeft, M, a, LD_max);
                    elseif (currentsegment == "dash") || (currentsegment == "Dash")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_dash(W_array(i-1), TSFC_dash, mission_obj.missiondata.Dash.Rangeft, M * a, LD_max);
                    elseif (currentsegment == "combat") || (currentsegment == "Combat")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_combat(W_array(i-1), mission_obj.missiondata.Combat.Timemin, TSFC_dash, W_payload_drop, LD_max);
                    elseif (currentsegment == "loiter") || (currentsegment == "Loiter")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_loiter(W_array(i-1), mission_obj.missiondata.Loiter.Timemin, TSFC_loiter, LD_max);
                    elseif (currentsegment == "landing") || (currentsegment == "Landing")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel1.segment_landing(W_array(i-1));
                    elseif (currentsegment == "descent") || (currentsegment == "Descent")
                         % Not implemented yet
                    elseif (currentsegment == "meta")
                         % Loop complete
                    else
                         error("Couldn't identify mission segment name. (Startup, Taxi, Takeoff, Climb, Cruise, Dash, Combat, Loiter, Landing).")
                    end
               end
               total_fuel_used = sum(fuelburnedarray);
               mission_obj.mission_fuel = total_fuel_used;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;
          end


          % Arguments should be design-specific geometric or aerodynamic
          % properties extracted from objects (... which are themselves the
          % design).
          % % I probably don't even need this any more.
          % function segment_names = get_segment_names(obj, design, missiondata)
          %      segment_names = string(missiondata.Properties.VariableNames);
          % 
          %      for i=1:lenght(segment_names)
          %           current_segment = segment_names(i);
          %           mission.(current_segment) = missiondata(:, (current_segment));
          %      end
          % 
          % end






          % % Get LD ratio (wrapper)
          % function [LD_ratio] = compute_LD_ratio(mission_obj, aero_obj, geometry_obj, segment_name, design)
          %      design_type = design.general.Type;
          %      if (segment_name == "cruise") || (segment_name == "combat") || (segment_name == "dash")
          %           LD_ratio = aero_obj.get_LDmax(geometry_obj, design_type);
          %      elseif (segment_name == "loiter")
          %           LD_ratio = aero_obj.get_LDmax(geometry_obj, design_type);
          %      else
          %           error("Error handler.")
          %      end
          % end
          % 
          % 
          % % Computing weight fraction (should go in "weight" class?
          % function [WF] = compute_weightfraction(mission_obj, TSFC, R, Vend, LD_ratio)
          %      WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          % end
          % 
          % 
          % % Climb segment - un-revised.
          % function [W_out, fuel_used] = segment_climb(mission_obj, W_in, Mach)
          %      WF_Climb = 1.0065 - 0.0325 * Mach;
          %      fuel_used = (1 - WF_Climb) * W_in;
          %      W_out = W_in - fuel_used;
          % end
          % 
          % 
          % 
          % % Combat segment - un-revised
          % function [W_out, fuel_used] = segment_combat(mission_obj, aero_obj,  W_in, time, TSFC, payload, design, geometry_obj)
          %      LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "combat", design);
          %      WF = exp(-(time * 60 * TSFC / LD));
          %      fuel_used = W_in*(1-WF);
          %      W_out = W_in - fuel_used - payload;
          % end
          % 
          % % Cruise segment - un-revised
          % function [W_out, fuel_used] = segment_cruise(mission_obj, aero_obj, W_in, TSFC, Distance, Mach, a, design, geometry_obj)
          %      V = Mach * a;
          %      LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "cruise", design);
          %      WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
          %      fuel_used = W_in * (1 - WF);
          %      W_out = W_in - fuel_used;
          % end
          % 
          % % Dash segment
          % function [W_out, fuel_used] = segment_dash(mission_obj, aero_obj, W_in, TSFC, Distance, V, design, geometry_obj)
          %      LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "dash", design);
          %      WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
          %      fuel_used = W_in * (1 - WF);
          %      W_out = W_in - fuel_used;
          % end
          % 
          % % Landing segment
          % function [W_out, fuel_used] = segment_landing(mission_obj, W_in)
          %      WF = 0.995;
          %      fuel_used = W_in * (1 - WF);
          %      W_out = W_in - fuel_used;
          % end
          % 
          % % Loiter segment
          % function [W_out, fuel_used] = segment_loiter(mission_obj, aero_obj, W_in, time, TSFC, design, geometry_obj)
          %      LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "loiter", design);
          %      WF = exp(-(time * 60 * TSFC / LD));
          %      fuel_used = W_in * (1 - WF);
          %      W_out = W_in - fuel_used;
          % end
          % 
          % % Takeoff segment
          % function [W_out, fuel_used] = segment_takeoff(mission_obj, W_in)
          %      WF = 0.95;
          %      W_out = W_in * WF;
          %      fuel_used = W_in - W_out;
          % end
     end
end
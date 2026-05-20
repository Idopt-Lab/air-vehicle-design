classdef F16MissionAnalysisLevel3 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          mission_states
          eps
     end

     methods
          % Constructor
          % Constructor
          function obj = F16MissionAnalysisLevel3(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(Chosen_Mission);
               obj.mission_states = obj.generate_mission_states;
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj)
               % This is where we actually compute the fuel for the mission
               % AR = design.geom.wings.Main.AspectRatio;
               AR = geometry_obj.mainwings.AR;

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = weight_obj.W_TO;
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               S_ref = geometry_obj.mainwings.S_ref;
               T0 = propulsion_obj.T0;

               t_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               t_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               TSFC_sl_perhour_dry = design.propulsion.TSFCseaLevelperHour.Dry;
               TSFC_sl_perhour_wet = design.propulsion.TSFCseaLevelperHour.Wet;
               E_dry = design.propulsion.E.Dry;
               E_wet = design.propulsion.E.Wet;
               F1_dry = design.propulsion.F1.Dry;
               F1_wet = design.propulsion.F1.Wet;
               F2_dry = design.propulsion.F2.Dry;
               F2_wet = design.propulsion.F2.Wet;
               TR = 1.0;

               % Automate segment extraction
               segmentnames = fields(mission_obj.missiondata);
               fuelburnedarray = zeros(1,length(segmentnames));
               W_array = zeros(1, length(segmentnames));

               W_array(1) = W_TO;

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
                         CD0 = aero_obj.get_design_CD0([M, alt], design, geometry_obj, S_ref, propulsion_obj);
                         IsDryOrWet = mission_obj.missiondata.(currentsegment).DryOrWet;
                         if (IsDryOrWet == "Dry")
                              TSFC = propulsion_obj.get_TSFC([M, alt], IsDryOrWet, t_SL_dry, TSFC_sl_perhour_dry, E_dry, F1_dry, F2_dry, TR);
                         elseif (IsDryOrWet == "Wet")
                              TSFC = propulsion_obj.get_TSFC([M, alt], IsDryOrWet, t_SL_wet, TSFC_sl_perhour_wet, E_wet, F1_wet, F2_wet, TR);
                         end
                    end

                    if (currentsegment == "startup") || (currentsegment == "Startup")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_startup(W_array(i));
                    elseif (currentsegment == "taxi") || (currentsegment == "Taxi")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_taxi(W_array(i-1));
                    elseif (currentsegment == "takeoff") || (currentsegment == "Takeoff")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_takeoff(W_array(i-1));
                    elseif (currentsegment == "climb") || (currentsegment == "Climb")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_climb(W_TO, W_array(i-1), M, S_ref, CD0, mission_obj.missiondata.Cruise.e, AR, TSFC, alt, T0);
                    elseif (currentsegment == "cruise") || (currentsegment == "Cruise")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_cruise(W_array(i-1), TSFC, mission_obj.missiondata.Cruise.Rangeft, M, a, q, CD0, mission_obj.missiondata.Cruise.e, AR, S_ref);
                    elseif (currentsegment == "dash") || (currentsegment == "Dash")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_dash(W_array(i-1), S_ref, W_TO, q, CD0, mission_obj.missiondata.Dash.e, AR, TSFC, mission_obj.missiondata.Dash.Rangeft, M * a);
                    elseif (currentsegment == "combat") || (currentsegment == "Combat")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_combat(W_array(i-1), mission_obj.missiondata.Combat.Timemin, TSFC, mission_obj.missiondata.Combat.PayloadDroplbf, CD0, mission_obj.missiondata.Combat.e, AR, W_TO, q, S_ref);
                    elseif (currentsegment == "loiter") || (currentsegment == "Loiter")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_loiter(W_TO, W_array(i-1), S_ref, q, CD0, mission_obj.missiondata.Loiter.e, AR, mission_obj.missiondata.Loiter.Timemin, TSFC);
                    elseif (currentsegment == "landing") || (currentsegment == "Landing")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_landing(W_array(i-1), W_TO);
                    elseif (currentsegment == "descent") || (currentsegment == "Descent")
                         % Not implemented yet
                    elseif (currentsegment == "meta")
                         % Loop complete
                    else
                         error("Couldn't identify mission segment name. (Startup, Taxi, Takeoff, Climb, Cruise, Dash, Combat, Loiter, Landing).")
                    end
               end
               total_fuel_used = sum(fuelburnedarray);
               mission_obj.mission_fuel = fuelburnedarray;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;
          end
     end

     methods (Access = private)
          % Generate mission state vector
          function state_vector = generate_mission_states(mission_obj)
               % State vector = [Mach, altitude, alpha, instantaneous weight] (per segment)
               segment_names = fieldnames(mission_obj.missiondata);
               segment_count = length(segment_names);
               state_vector = zeros(2, segment_count-1); % Trim the last column because it's just "meta"

               % Extract Mach number & altitude from each segment
               for i=1:segment_count-1
                    segment_name = segment_names{i};
                    state_vector(1,i) = mission_obj.missiondata.(segment_name).MachNumber;
                    state_vector(2,i) = mission_obj.missiondata.(segment_name).Altitudeft;
               end
          end
     end
end
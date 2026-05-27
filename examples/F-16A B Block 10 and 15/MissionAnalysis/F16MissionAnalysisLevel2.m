classdef F16MissionAnalysisLevel2 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % Lower fidelity level than 3.

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          eps
     end

methods
          % Constructor
          function obj = F16MissionAnalysisLevel2(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(Chosen_Mission);
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj)
               % This is where we actually compute the fuel for the mission
               AR = geometry_obj.mainwings.AR;

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = weight_obj.W_TO;
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               S_ref = geometry_obj.mainwings.S_ref;
               S_wet_aircraft = geometry_obj.design.S_wet;
               T0 = propulsion_obj.T0;
               engine_type = design.propulsion_type;
               % Automate segment extraction
               segmentnames = fields(mission_obj.missiondata);
               fuelburnedarray = zeros(1,length(segmentnames));
               W_segments = zeros(1, length(segmentnames));
               W_segments(1) = W_TO;

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
                         CD0 = aero_obj.get_design_CD0(aero_obj.Cf, S_wet_aircraft, S_ref);
                         IsDryOrWet = mission_obj.missiondata.(currentsegment).DryOrWet;
                         if (IsDryOrWet == "Dry")
                              IsDryOrWet = "mil";
                              TSFC = propulsion_obj.get_TSFC(engine_type, [M, alt], IsDryOrWet);
                         elseif (IsDryOrWet == "Wet")
                              IsDryOrWet = "max";
                              TSFC = propulsion_obj.get_TSFC(engine_type, [M, alt], IsDryOrWet);
                         end
                    end
                    if (currentsegment == "startup") || (currentsegment == "Startup")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_startup(W_segments(i));
                    elseif (currentsegment == "taxi") || (currentsegment == "Taxi")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_taxi(W_segments(i-1));
                    elseif (currentsegment == "takeoff") || (currentsegment == "Takeoff")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_takeoff(W_segments(i-1));
                    elseif (currentsegment == "climb") || (currentsegment == "Climb")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_climb(W_TO, W_segments(i-1), M, S_ref, CD0, mission_obj.missiondata.Cruise.e, AR, TSFC, alt, T0);
                    elseif (currentsegment == "cruise") || (currentsegment == "Cruise")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_cruise(W_segments(i-1), W_S, TSFC, mission_obj.missiondata.Cruise.Rangeft, M, a, q, CD0, mission_obj.missiondata.Cruise.e, AR, W_TO, S_ref);
                    elseif (currentsegment == "dash") || (currentsegment == "Dash")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_dash(W_segments(i-1), W_S, W_TO, q, CD0, mission_obj.missiondata.Dash.e, AR, TSFC, mission_obj.missiondata.Dash.Rangeft, M * a);
                    elseif (currentsegment == "combat") || (currentsegment == "Combat")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_combat(W_segments(i-1), mission_obj.missiondata.Combat.Timemin, TSFC, mission_obj.missiondata.Combat.PayloadDroplbf, CD0, mission_obj.missiondata.Combat.e, AR, W_TO, q, W_S);
                    elseif (currentsegment == "loiter") || (currentsegment == "Loiter")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_loiter(W_TO, W_segments(i-1), W_S, q, CD0, mission_obj.missiondata.Loiter.e, AR, mission_obj.missiondata.Loiter.Timemin, TSFC);
                    elseif (currentsegment == "landing") || (currentsegment == "Landing")
                         [W_segments(i), fuelburnedarray(i)] = MissionAnalysisLevel2.segment_landing(W_segments(i-1), W_TO);
                    elseif (currentsegment == "descent") || (currentsegment == "Descent")
                         % Not implemented yet
                    elseif (currentsegment == "meta")
                         % Loop complete
                    else
                         error("Couldn't identify mission segment name. (Startup, Taxi, Takeoff, Climb, Cruise, Dash, Combat, Loiter, Landing).")
                    end
               end
               % [W_Takeoff, f1] = mission_obj.segment_takeoff(W_TO);
               % [W_Climb, f2]   = mission_obj.segment_climb(W_TO, W_Takeoff, mission_obj.missiondata.Climb.MachNumber, S_ref, mission_obj.missiondata.Cruise.CD0, mission_obj.missiondata.Cruise.e, AR, propulsion_obj.get_TSFC_installed(design.propulsion_type, [mission_obj.missiondata.Climb.MachNumber, mission_obj.missiondata.Climb.Altitudeft, 0, W_Takeoff], "mil"), mission_obj.missiondata.Climb.Altitudeft, T0);
               % [W_Cruise, f3]  = mission_obj.segment_cruise(W_Climb, W_S, mission_obj.missiondata.Cruise.TSFC, mission_obj.missiondata.Cruise.Rangeft, mission_obj.missiondata.Cruise.MachNumber, mission_obj.missiondata.Cruise.afts, mission_obj.missiondata.Cruise.qlbfft2, mission_obj.missiondata.Cruise.CD0, mission_obj.missiondata.Cruise.e, AR, W_TO, S_ref);
               % [W_Dash, f4]    = mission_obj.segment_dash(W_Cruise, W_S, W_TO, mission_obj.missiondata.Dash.qlbfft2, mission_obj.missiondata.Dash.CD0, mission_obj.missiondata.Dash.e, AR, propulsion_obj.get_TSFC_installed(design.propulsion_type, [mission_obj.missiondata.Dash.MachNumber, mission_obj.missiondata.Dash.Altitudeft, 0, W_Cruise], "max"), mission_obj.missiondata.Dash.Rangeft, mission_obj.missiondata.Dash.MachNumber * mission_obj.missiondata.Dash.afts);
               % [W_Combat, f5]  = mission_obj.segment_combat(W_Dash, mission_obj.missiondata.Combat.Timemin, propulsion_obj.get_TSFC_installed(design.propulsion_type, [mission_obj.missiondata.Combat.MachNumber, mission_obj.missiondata.Combat.Altitudeft, 0, W_Dash], "max"), mission_obj.missiondata.Combat.PayloadDroplbf, mission_obj.missiondata.Combat.CD0, mission_obj.missiondata.Combat.e, AR, W_TO, mission_obj.missiondata.Combat.qlbfft2, W_S);
               % [W_Cruise2, f6] = mission_obj.segment_cruise(W_Combat, W_S, propulsion_obj.get_TSFC_installed(design.propulsion_type, [mission_obj.missiondata.Cruise_1.MachNumber, mission_obj.missiondata.Dash.Altitudeft, 0, W_Combat], "max"), mission_obj.missiondata.Cruise_1.Rangeft, mission_obj.missiondata.Cruise_1.MachNumber, mission_obj.missiondata.Cruise_1.afts, mission_obj.missiondata.Cruise_1.qlbfft2, mission_obj.missiondata.Cruise_1.CD0, mission_obj.missiondata.Cruise_1.e, AR, W_TO, S_ref);
               % [W_Loiter, f7]  = mission_obj.segment_loiter(W_TO, W_Cruise2, W_S, mission_obj.missiondata.Loiter.qlbfft2, mission_obj.missiondata.Loiter.CD0, mission_obj.missiondata.Loiter.e, AR, mission_obj.missiondata.Loiter.Timemin, propulsion_obj.get_TSFC_installed(design.propulsion_type, [mission_obj.missiondata.Loiter.MachNumber, mission_obj.missiondata.Loiter.Altitudeft, 0, W_Cruise2], "mil"));
               % [W_Landing, f8] = mission_obj.segment_landing(W_Loiter, W_TO);
               % total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;
               total_fuel_used = sum(fuelburnedarray);
               mission_obj.mission_fuel = total_fuel_used;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;
          end
     end

     %% ----------------------------------------------------------
     % HELPER FUNCTIONS

     methods (Access = private)
          
     end
end
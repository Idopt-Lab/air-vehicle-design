classdef MissionAnalysisLevel2 < MissionAnalysisModel
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
          function obj = MissionAnalysisLevel2(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(obj, Chosen_Mission);
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj)
               % This is where we actually compute the fuel for the mission
               AR = design.geom.wings.Main.AspectRatio;

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
                         CD0 = aero_obj.get_design_CD0(aero_obj.Cf, S_wet_aircraft, S_ref);
                         IsDryOrWet = mission_obj.missiondata.(currentsegment).DryOrWet;
                         if (IsDryOrWet == "Dry")
                              IsDryOrWet = "mil";
                              TSFC = propulsion_obj.get_TSFC_installed(engine_type, [M, alt], IsDryOrWet);
                         elseif (IsDryOrWet == "Wet")
                              IsDryOrWet = "max";
                              TSFC = propulsion_obj.get_TSFC_installed(engine_type, [M, alt], IsDryOrWet);
                         end
                    end
                    if (currentsegment == "startup") || (currentsegment == "Startup")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_takeoff(W_array(i));
                    elseif (currentsegment == "taxi") || (currentsegment == "Taxi")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_taxi(W_array(i-1));
                    elseif (currentsegment == "takeoff") || (currentsegment == "Takeoff")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_takeoff(W_array(i-1));
                    elseif (currentsegment == "climb") || (currentsegment == "Climb")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_climb(W_TO, W_array(i-1), M, S_ref, CD0, mission_obj.missiondata.Cruise.e, AR, TSFC, alt, T0);
                    elseif (currentsegment == "cruise") || (currentsegment == "Cruise")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_cruise(W_array(i-1), W_S, TSFC, mission_obj.missiondata.Cruise.Rangeft, M, a, q, CD0, mission_obj.missiondata.Cruise.e, AR, W_TO, S_ref);
                    elseif (currentsegment == "dash") || (currentsegment == "Dash")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_dash(W_array(i-1), W_S, W_TO, q, CD0, mission_obj.missiondata.Dash.e, AR, TSFC, mission_obj.missiondata.Dash.Rangeft, M * a);
                    elseif (currentsegment == "combat") || (currentsegment == "Combat")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_combat(W_array(i-1), mission_obj.missiondata.Combat.Timemin, TSFC, mission_obj.missiondata.Combat.PayloadDroplbf, CD0, mission_obj.missiondata.Combat.e, AR, W_TO, q, W_S);
                    elseif (currentsegment == "loiter") || (currentsegment == "Loiter")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_loiter(W_TO, W_array(i-1), W_S, q, CD0, mission_obj.missiondata.Loiter.e, AR, mission_obj.missiondata.Loiter.Timemin, TSFC);
                    elseif (currentsegment == "landing") || (currentsegment == "Landing")
                         [W_array(i), fuelburnedarray(i)] = mission_obj.segment_landing(W_array(i-1), W_TO);
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






          function [LD_ratio] = compute_LD_ratio(mission_obj, W, W_TO, q, CD0, W_S, e, AR)
               W_by_W_TO = W / W_TO;
               W_by_S = W_by_W_TO * W_S;
               LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          end


          function [WF] = compute_weightfraction(mission_obj, TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - un-revised.
          function [W_out, fuel_used] = segment_climb(mission_obj, W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
               WF_Climb = 1.0065 - 0.0325 * Mach;
               fuel_used = (1 - WF_Climb) * W_in;
               W_out = W_in - fuel_used;
          end



          % Combat segment - un-revised
          function [W_out, fuel_used] = segment_combat(mission_obj, W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  W_S)
               LD = mission_obj.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end

          % Cruise segment - un-revised
          function [W_out, fuel_used] = segment_cruise(mission_obj, W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
               V = Mach * a;
               LD = mission_obj.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;

          end

          function [W_out, fuel_used] = segment_dash(mission_obj, W_in, W_S, W_TO, q, CD0, e, AR, TSFC, Distance, V)
               LD = mission_obj.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_landing(mission_obj, W_in, W_TO)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_loiter(mission_obj, W_TO, W_in, W_S, q, CD0, e, AR, time, TSFC)
               LD = mission_obj.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end


          function [W_out, fuel_used] = segment_startup(mission_obj, W_in)
               WF = 0.99;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_takeoff(mission_obj, W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_taxi(mission_obj, W_in)
               WF = 0.98;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end
     end
end
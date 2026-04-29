classdef MissionAnalysisLevel1 < MissionAnalysisModel
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
          function obj = MissionAnalysisLevel1(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(obj, Chosen_Mission);
               obj.segment_names = fieldnames(obj.missiondata);
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
               T0 = propulsion_obj.T0;

               % Loop stuff - should automate segment naming extraction
               % (future)
               [W_Takeoff, f1] = mission_obj.segment_takeoff(W_TO);
               [W_Climb, f2]   = mission_obj.segment_climb(W_Takeoff, mission_obj.missiondata.Climb.MachNumber);
               [W_Cruise, f3]  = mission_obj.segment_cruise(aero_obj, W_Climb, propulsion_obj.TSFC.cruise, mission_obj.missiondata.Cruise.Rangeft, mission_obj.missiondata.Cruise.MachNumber, mission_obj.missiondata.Cruise.afts, design, geometry_obj);
               [W_Dash, f4]    = mission_obj.segment_dash(aero_obj, W_Cruise, mission_obj.missiondata.Dash.TSFC, mission_obj.missiondata.Dash.Rangeft, mission_obj.missiondata.Dash.MachNumber * mission_obj.missiondata.Dash.afts, design, geometry_obj);
               [W_Combat, f5]  = mission_obj.segment_combat(aero_obj, W_Dash, mission_obj.missiondata.Combat.Timemin, mission_obj.missiondata.Combat.TSFC, mission_obj.missiondata.Combat.PayloadDroplbf, design, geometry_obj);
               [W_Cruise2, f6] = mission_obj.segment_cruise(aero_obj, W_Combat, propulsion_obj.TSFC.cruise, mission_obj.missiondata.Cruise_1.Rangeft, mission_obj.missiondata.Cruise_1.MachNumber, mission_obj.missiondata.Cruise_1.afts, design, geometry_obj);
               [W_Loiter, f7]  = mission_obj.segment_loiter(aero_obj, W_Cruise2, mission_obj.missiondata.Loiter.Timemin, propulsion_obj.TSFC.loiter, design, geometry_obj);
               [W_Landing, f8] = mission_obj.segment_landing(W_Loiter);
               total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;
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






          % Get LD ratio (wrapper)
          function [LD_ratio] = compute_LD_ratio(mission_obj, aero_obj, geometry_obj, segment_name, design)
               design_type = design.general.Type;
               if (segment_name == "cruise") || (segment_name == "combat") || (segment_name == "dash")
                    LD_ratio = aero_obj.get_LDmax(geometry_obj, design_type);
               elseif (segment_name == "loiter")
                    LD_ratio = aero_obj.get_LDmax(geometry_obj, design_type);
               else
                    error("Error handler.")
               end    
          end


          % Computing weight fraction (should go in "weight" class?
          function [WF] = compute_weightfraction(mission_obj, TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - un-revised.
          function [W_out, fuel_used] = segment_climb(mission_obj, W_in, Mach)
               WF_Climb = 1.0065 - 0.0325 * Mach;
               fuel_used = (1 - WF_Climb) * W_in;
               W_out = W_in - fuel_used;
          end



          % Combat segment - un-revised
          function [W_out, fuel_used] = segment_combat(mission_obj, aero_obj,  W_in, time, TSFC, payload, design, geometry_obj)
               LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "combat", design);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end

          % Cruise segment - un-revised
          function [W_out, fuel_used] = segment_cruise(mission_obj, aero_obj, W_in, TSFC, Distance, Mach, a, design, geometry_obj)
               V = Mach * a;
               LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "cruise", design);
               WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Dash segment
          function [W_out, fuel_used] = segment_dash(mission_obj, aero_obj, W_in, TSFC, Distance, V, design, geometry_obj)
               LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "dash", design);
               WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Landing segment
          function [W_out, fuel_used] = segment_landing(mission_obj, W_in)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Loiter segment
          function [W_out, fuel_used] = segment_loiter(mission_obj, aero_obj, W_in, time, TSFC, design, geometry_obj)
               LD = mission_obj.compute_LD_ratio(aero_obj, geometry_obj, "loiter", design);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Takeoff segment
          function [W_out, fuel_used] = segment_takeoff(mission_obj, W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end
     end
end
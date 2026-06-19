%% homework1_refsol.m
% Reference Solution - Homework 1 - REVISION 1
% Computes takeoff gross weight and fuel burn factor (beta)
% FIDELITY LEVEL II
% EMPTY WEIGHT ACCOUNTS FOR FUSELAGE LENGTH AND DIAM

%clear; clc;
% function [MTOW, OEW] = homework1_refsol(mission_inputs)

%% -------------------------------------------

function [Weight_Results] = weight_est_I(missiondata, Constraints, Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, min_TW, optimal_WS, DesignTable_weight)

%% -------------------------------------------
% Load mission inputs
% Break up into "mission" and "aero" and "propulsion"

% Extract names of each segment
segment_names = string(missiondata.Properties.VariableNames);

for i=1:length(segment_names)
     current_segment = segment_names(i);
     mission.(current_segment) = missiondata(:, (current_segment));
end

%% --------------------------------------------------
% Run analysis
[W_TO, beta, results_table, total_fuel_used, fuel_fraction, empty_weight_fraction, empty_weight, W_Takeoff, W_Climb, W_Cruise, W_Dash, W_Combat, W_Cruise2, W_Loiter, W_Landing, f1, f2, f3, f4, f5, f6, f7, f8, S_ref, S_wet, T0] = missionAnalysis(mission, min_TW, optimal_WS, Designgeo_wings, Designgeo_fuselage, DesignTable_weight);

% Display output
fprintf('Final Takeoff Gross Weight (W_TO): %.2f lb\n', W_TO);
fprintf('Fuel Efficiency Factor (beta): %.4f\n', beta);
disp(results_table);

%% --------------------------------------------------
% Function: Main Mission Analysis
     function [W_TO, beta, results_table, total_fuel_used, fuel_fraction, empty_weight_fraction, empty_weight, W_Takeoff, W_Climb, W_Cruise, W_Dash, W_Combat, W_Cruise2, W_Loiter, W_Landing, f1, f2, f3, f4, f5, f6, f7, f8, S_ref, S_wet, T0, S_HT, S_VT] = missionAnalysis(mission, min_TW, optimal_WS, Designgeo_wings, Designgeo_fuselage, DesignTable_weight)
          AR = Designgeo_wings.Main("Aspect ratio");
          L_fus = Designgeo_fuselage.Fuselage("Length (ft)");
          D_fus = Designgeo_fuselage.Fuselage("Max width (ft)");
          c_root = Designgeo_wings.Main("Root chord length (ft)");
          b_W = Designgeo_wings.Main("Span (ft)");
          Cbar_W = Designgeo_wings.Main("Mean geometric chord");
          lambda = Designgeo_wings.Main("Taper ratio");
          Lambda_qc = Designgeo_wings.Main("Taper ratio, qc");
          tc_root = Designgeo_wings.Main("t/c");
          c_VT = Designgeo_wings.VerticalTail("c_VT");
          c_HT = Designgeo_wings.HorizontalTail("c_HT");

          W_fixed = missiondata.Startup("Payload, fixed (lbf)");

          % W_S = 104.59;
          W_S = optimal_WS;
          W_TO = 45000;
          tol = 1e-3;
          max_iteration = 40;
          results = [];
          S_ref = 0;
          T_W = min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)

          %% ----------------------------------------------------------------------

          for iteration = 1:max_iteration
               S_ref = W_TO / W_S;
               total_fuel_used = 0;

               %% ----------------------------------------------------------------------
               % Estimate wetted areas
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2

               %% ----------------------------------------------------------------------
               % Get thrust at takeoff
               T0 = T_W*W_TO;

               %% ----------------------------------------------------------------------

               % Loop stuff - should automate segment naming extraction
               % (future)
               [W_startup, f1] = segment_startup(W_TO);
               [W_taxi, f2] = segment_taxi(W_startup);
               [W_Takeoff, f3] = segment_takeoff(W_taxi);
               [W_Climb, f4]   = segment_climb(W_TO, W_Takeoff, mission.Climb.Climb("Mach number"), S_ref, mission.Cruise.Cruise("CD0"), mission.Cruise.Cruise("e"), AR, mission.Loiter.Loiter("TSFC"), mission.Climb.Climb("Altitude (ft)"), T0);
               [W_Cruise, f5]  = segment_cruise(W_Climb, W_S, mission.Cruise.Cruise("TSFC"), mission.Cruise.Cruise("Range (ft)"), mission.Cruise.Cruise("Mach number"), mission.Cruise.Cruise("a (ft/s)"), mission.Cruise.Cruise("q (lbf/ft^2)"), mission.Cruise.Cruise("CD0"), mission.Cruise.Cruise("e"), AR, W_TO, S_ref);
               [W_Dash, f6]    = segment_dash(W_Cruise, S_ref, W_TO, mission.Dash.Dash("q (lbf/ft^2)"), mission.Dash.Dash("CD0"), mission.Dash.Dash("e"), AR, mission.Dash.Dash("TSFC"), mission.Dash.Dash("Range (ft)"), mission.Dash.Dash("Mach number") * mission.Dash.Dash("a (ft/s)"));
               [W_Combat, f7]  = segment_combat(W_Dash, mission.Combat.Combat("Time (min)"), mission.Combat.Combat("TSFC"), mission.Combat.Combat("Payload, drop (lbf)"), mission.Combat.Combat("CD0"), mission.Combat.Combat("e"), AR, W_TO, mission.Combat.Combat("q (lbf/ft^2)"), S_ref);
               [W_Cruise2, f8] = segment_cruise(W_Combat, W_S, mission.Cruise_1.Cruise_1("TSFC"), mission.Cruise_1.Cruise_1("Range (ft)"), mission.Cruise_1.Cruise_1("Mach number"), mission.Cruise_1.Cruise_1("a (ft/s)"), mission.Cruise_1.Cruise_1("q (lbf/ft^2)"), mission.Cruise_1.Cruise_1("CD0"), mission.Cruise_1.Cruise_1("e"), AR, W_TO, S_ref);
               [W_Loiter, f9]  = segment_loiter(W_TO, W_Cruise2, S_ref, mission.Loiter.Loiter("q (lbf/ft^2)"), mission.Loiter.Loiter("CD0"), mission.Loiter.Loiter("e"), AR, mission.Loiter.Loiter("Time (min)"), mission.Loiter.Loiter("TSFC"));
               [W_Landing, f10]         = segment_landing(W_Loiter, W_TO);

               total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;

               % Compute empty weight
               [empty_weight] = Compute_OEW_I(W_TO);

               % OEW - update new OEW fraction
               empty_weight_fraction = empty_weight/W_TO;

               W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
               % W_TO_new = total_fuel_used + W_fixed + empty_weight;

               difference = W_TO_new - W_TO;
               percent_diff = 100 * difference / W_TO;

               results(end+1, :) = [W_TO, W_fixed, fuel_fraction, empty_weight_fraction, empty_weight, W_TO_new, difference, percent_diff];

               if abs(difference) < tol
                    break;
               end
               W_TO = W_TO_new;
               S_ref = S_ref;
          end
          S_ref = S_ref;
          beta = 1 - (total_fuel_used / (2 * W_TO));
          results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
     end


MTOW = W_TO;
OEW = empty_weight;

% end

Weight_Results.MTOW = MTOW;
Weight_Results.OEW = OEW;
Weight_Results.S_wet = S_wet;
Weight_Results.S_ref = S_ref;
Weight_Results.W_Landing = W_Landing;
Weight_Results.total_fuel_used = total_fuel_used;
Weight_Results.T0 = T0;

end
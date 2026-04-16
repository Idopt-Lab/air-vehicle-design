classdef Sizing
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties
          Property1
     end

     methods
          function size_aircraft(obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj)

               % This is where we actually compute the fuel for the mission
               AR = design.geom.wings.Main.AspectRatio;
               L_fus = design.geom.fuselage.Fuselage.Lengthft;
               D_fus = design.geom.fuselage.Fuselage.MaxWidthft;
               c_root = design.geom.wings.Main.RootChordLengthft;
               b_W = design.geom.wings.Main.Spanft;
               Cbar_W = design.geom.wings.Main.MeanGeometricChord;
               lambda = design.geom.wings.Main.TaperRatio;
               Lambda_qc = design.geom.wings.Main.TaperRatioQc;
               tc_root = design.geom.wings.Main.tc;
               c_VT = design.geom.wings.VerticalTail.c_VT;
               c_HT = design.geom.wings.HorizontalTail.c_HT;
               BPR = design.propulsion.BypassRatio.BypassRatio;

               weight_obj.W_fixed = mission_obj.missiondata.Startup.PayloadFixedlbf;

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = weight_obj.W_TO_guess;
               weight_obj.W_TO = W_TO;
               tol = 1e-3;
               max_iteration = 40;
               results = [];
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               total_fuel_used = 0;
               for iteration = 1:max_iteration
                    geometry_obj.mainwings.S_ref = W_TO / W_S;

                    %% ----------------------------------------------------------------------
                    % Estimate wetted areas
                    S_wet = geometry_obj.get_S_wet(W_TO);

                    %% ----------------------------------------------------------------------
                    % Size the tail (should be a geometry thing)
                    [geometry_obj.S_VT, geometry_obj.S_HT] = geometry_obj.size_tail(design, weight_obj.W_TO, geometry_obj.mainwings.S_ref);


                    %% ----------------------------------------------------------------------
                    % Get thrust at takeoff
                    propulsion_obj.T0 = T_W*W_TO; % Fidelity III

                    %% -------------------------------------------------
                    % Get mission fuel
                    [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel(constraint_obj, design, geometry_obj, propulsion_obj, weight_obj);


                    % Compute design weight
                    % Then compute the empty weight
                    weight_obj.OEW = get_OEW(weight_obj, propulsion_obj, mission_obj, design, geometry_obj, weight_obj.W_TO);

                    empty_weight_fraction = weight_obj.OEW.total/weight_obj.W_TO;

                    % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
                    W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW.total;

                    difference = W_TO_new - weight_obj.W_TO;
                    percent_diff = 100 * difference / weight_obj.W_TO;
                    % Iterate

                    % complete iteration loop, return MTOW and such
                    W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW.total;

                    difference = W_TO_new - weight_obj.W_TO;
                    percent_diff = 100 * difference / weight_obj.W_TO;

                    results(end+1, :) = [weight_obj.W_TO, weight_obj.W_fixed, weight_obj.fuel_fraction, empty_weight_fraction, weight_obj.OEW.total, W_TO_new, difference, percent_diff];

                    if abs(difference) < tol
                         break;
                    end
                    weight_obj.W_TO = W_TO_new;
                    geometry_obj.mainwings.S_ref = geometry_obj.mainwings.S_ref;
               end
               beta = 1 - (total_fuel_used / (2 * W_TO));
               results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
               disp(results_table)


          end


     end
end
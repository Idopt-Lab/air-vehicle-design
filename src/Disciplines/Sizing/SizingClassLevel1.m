classdef SizingClassLevel1
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties
          results_table
     end

     methods
          function size_aircraft(obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj, aero_obj)

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
                    geometry_obj.design.S_wet = geometry_obj.get_design_S_wet(W_TO);

                    %% ----------------------------------------------------------------------
                    % Size the tail (should be a geometry thing)
                    % [geometry_obj.VT.S_ref, geometry_obj.HT.S_ref] = geometry_obj.size_tail(design, geometry_obj.mainwings.S_ref);


                    %% ----------------------------------------------------------------------
                    % Get thrust at takeoff
                    propulsion_obj.T0 = T_W*W_TO; % Fidelity III

                    %% -------------------------------------------------
                    % Get mission fuel
                    [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel(constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj);


                    % Compute design weight
                    % Then compute the empty weight
                    weight_obj.OEW = weight_obj.get_OEW(design.type, W_TO);

                    weight_obj.OEW_frac = weight_obj.OEW/weight_obj.W_TO;

                    % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
                    W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW;

                    difference = W_TO_new - weight_obj.W_TO;
                    percent_diff = 100 * difference / weight_obj.W_TO;
                    % Iterate

                    % complete iteration loop, return MTOW and such
                    W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW;

                    difference = W_TO_new - weight_obj.W_TO;
                    percent_diff = 100 * difference / weight_obj.W_TO;

                    results(end+1, :) = [weight_obj.W_TO, weight_obj.W_fixed, weight_obj.fuel_fraction, weight_obj.OEW_frac, weight_obj.OEW, W_TO_new, difference, percent_diff];

                    if abs(difference) < tol
                         break;
                    end
                    weight_obj.W_TO = W_TO_new;
                    W_TO = W_TO_new;
                    geometry_obj.mainwings.S_ref = geometry_obj.mainwings.S_ref;
               end
               beta = 1 - (total_fuel_used / (2 * W_TO));
               obj.results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
               disp(obj.results_table)
          end


     end
end
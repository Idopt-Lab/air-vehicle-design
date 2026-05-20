classdef F16SizingLevel3 < SizingModel
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties
          results_table
     end

     methods
          function W_TO = size_aircraft(obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj, aero_obj)

               % Load wing stuff
               % Main wings
               AR_w = geometry_obj.mainwings.AR;
               lambda_w = geometry_obj.mainwings.lambda;
               S_ref_w = geometry_obj.mainwings.S_ref;
               exposed_rc_w = geometry_obj.mainwings.exposed_rc;
               exposed_halfspan_w = geometry_obj.mainwings.exposed_halfspan;
               tc_w = geometry_obj.mainwings.tc;


               % Horizontal tail
               AR_ht = geometry_obj.HT.AR;
               lambda_ht = geometry_obj.HT.lambda;
               S_ref_ht = geometry_obj.HT.S_ref;
               exposed_rc_ht = geometry_obj.HT.exposed_rc;
               exposed_halfspan_ht = geometry_obj.HT.exposed_halfspan;
               tc_ht = geometry_obj.HT.tc;

               % Vertical tail
               AR_vt = geometry_obj.VT.AR;
               lambda_vt = geometry_obj.VT.lambda;
               S_ref_vt = geometry_obj.VT.S_ref;
               exposed_rc_vt = geometry_obj.VT.exposed_rc;
               exposed_halfspan_vt = geometry_obj.VT.exposed_halfspan;
               tc_vt = geometry_obj.VT.tc;


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
               S_ref_w = geometry_obj.mainwings.S_ref; % Comment out when done experimenting.
               % Generate mission state vectors
               % mission_obj.state_vector = mission_obj.generate_mission_states;
               for iteration = 1:max_iteration
                    % Recompute main wing planform area.
                    S_ref_w = W_TO / W_S;
                    geometry_obj.mainwings.S_ref = S_ref_w;

                    %% ----------------------------------------------------------------------
                    % Estimate wetted areas
                    geometry_obj.design.S_wet = GeometryLevel3.get_design_S_wet(W_TO);

                    %% ----------------------------------------------------------------------

                    % Reconstruct main wings
                    [geometry_obj.mainwings.b, ...
                         geometry_obj.mainwings.c_root, ...
                         geometry_obj.mainwings.c_tip, ...
                         geometry_obj.mainwings.S_exposed, ...
                         geometry_obj.mainwings.S_wet] = geometry_obj.reconstruct_wings(AR_w, ...
                         lambda_w, ...
                         S_ref_w, ...
                         exposed_rc_w, ...
                         exposed_halfspan_w, ...
                         tc_w);

                    %% ----------------------------------------------------------------------
                    % Reconstruct the tail (should be a geometry thing)
                    % Horizontal tail
                    [geometry_obj.HT.b, ...
                         geometry_obj.HT.c_root, ...
                         geometry_obj.HT.c_tip, ...
                         geometry_obj.HT.S_exposed, ...
                         geometry_obj.HT.S_wet] = geometry_obj.reconstruct_wings(AR_ht, ...
                         lambda_ht, ...
                         S_ref_ht, ...
                         exposed_rc_ht, ...
                         exposed_halfspan_ht, ...
                         tc_ht);

                    % Vertical tail
                    [geometry_obj.VT.b, ...
                         geometry_obj.VT.c_root, ...
                         geometry_obj.VT.c_tip, ...
                         geometry_obj.VT.S_exposed, ...
                         geometry_obj.VT.S_wet] = geometry_obj.reconstruct_wings(AR_vt, ...
                         lambda_vt, ...
                         S_ref_vt, ...
                         exposed_rc_vt, ...
                         exposed_halfspan_vt, ...
                         tc_vt);
                    % [geometry_obj.HT.S_ref, geometry_obj.VT.S_ref] = geometry_obj.size_tail(design, S_ref);

                    %% ----------------------------------------------------------------------
                    % Get thrust at takeoff
                    propulsion_obj.T0 = T_W*W_TO;

                    %% -------------------------------------------------
                    % Get mission fuel
                    [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel(constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj);


                    % Compute design weight
                    % Then compute the empty weight
                    weight_obj.OEW = weight_obj.get_OEW(propulsion_obj, design, geometry_obj, weight_obj.W_TO, requirements_obj);

                    % weight_obj.OEW.W_all_else_empty = weight_obj.compute_W_all_else_empty(W_TO, design.type);
                    % weight_obj.OEW.total = weight_obj.OEW.total + weight_obj.OEW.W_all_else_empty;

                    weight_obj.OEW_frac = weight_obj.OEW.total/weight_obj.W_TO;

                    % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
                    % W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW.total;

                    % complete iteration loop, return MTOW and such
                    W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW.total;

                    difference = W_TO_new - weight_obj.W_TO;
                    percent_diff = 100 * difference / weight_obj.W_TO;

                    results(end+1, :) = [weight_obj.W_TO, weight_obj.W_fixed, weight_obj.fuel_fraction, weight_obj.OEW_frac, weight_obj.OEW.total, W_TO_new, difference, percent_diff];

                    if abs(difference) < tol
                         break;
                    end
                    weight_obj.W_TO = W_TO_new;
                    W_TO = W_TO_new;
                    geometry_obj.VT.S_ref = geometry_obj.VT.S_ref;
               end
               % beta = 1 - (total_fuel_used / (2 * W_TO));
               obj.results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
               disp(obj.results_table)
          end


     end
end
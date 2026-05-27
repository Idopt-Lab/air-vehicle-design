classdef F16SizingLevel2 < SizingModel
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties
          results_table
     end

     methods
          function W_TO_new = compute_TOGW(obj, OEW, total_fuel_used, W_fixed)

               % % Load wing stuff
               % % Main wings
               % exposed_rc_w = geometry_obj.mainwings.exposed_rc;
               % exposed_halfspan_w = geometry_obj.mainwings.exposed_halfspan;
               % tc_w = geometry_obj.mainwings.tc;
               % 
               % 
               % % Horizontal tail
               % exposed_rc_ht = geometry_obj.HT.exposed_rc;
               % exposed_halfspan_ht = geometry_obj.HT.exposed_halfspan;
               % tc_ht = geometry_obj.HT.tc;
               % 
               % % Vertical tail
               % exposed_rc_vt = geometry_obj.VT.exposed_rc;
               % exposed_halfspan_vt = geometry_obj.VT.exposed_halfspan;
               % tc_vt = geometry_obj.VT.tc;
               % 
               % aircraft_type = "jet fighter";
               % weight_obj.W_fixed = mission_obj.missiondata.Startup.PayloadFixedlbf;

               % W_S = 104.59;
               % W_S = constraint_obj.optimal_WS;
               % W_TO = weight_obj.W_TO_guess;
               % weight_obj.W_TO = W_TO;
               % tol = 1e-3;
               % max_iteration = 40;
               % results = [];
               % T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               % for iteration = 2:max_iteration
                    % S_ref_w = W_TO/W_S;
                    % geometry_obj.mainwings.S_ref = S_ref_w;

                    % Reconstruct main wings
                    % geometry_obj.mainwings.S_exposed = geometry_obj.get_S_exposed_wing(tc_w, exposed_rc_w, exposed_halfspan_w);

                    %% ----------------------------------------------------------------------
                    % Reconstruct the tail (should be a geometry thing)
                    % Horizontal tail
                    % geometry_obj.HT.S_exposed = geometry_obj.get_S_exposed_wing(tc_ht, exposed_rc_ht, exposed_halfspan_ht);
                    
                    % Vertical tail
                    % geometry_obj.VT.S_exposed = geometry_obj.get_S_exposed_wing(tc_vt, exposed_rc_vt, exposed_halfspan_vt);

                    %% ----------------------------------------------------------------------
                    % Estimate wetted areas (store these for later graphs)
                    % S_wet_design = geometry_obj.get_design_S_wet;
                    % S_wet_design_array(iteration) = S_wet_design;

                    % geometry_obj.fuselage.S_wet = geometry_obj.get_S_wet_body;

                    %% ----------------------------------------------------------------------
                    % Get thrust at takeoff
                    % propulsion_obj.T0 = T_W*W_TO;

                    %% -------------------------------------------------
                    % Get mission fuel
                    % [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel(constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj);


                    % Compute design weight
                    % Get component weights
                    % weight_obj.wings = weight_obj.get_wing_weight("fighter", geometry_obj.mainwings.S_exposed);
                    % weight_obj.HT = weight_obj.get_HT_weight("fighter", geometry_obj.HT.S_exposed);
                    % weight_obj.VT = weight_obj.get_VT_weight("fighter", geometry_obj.VT.S_exposed);
                    % weight_obj.fuselage = weight_obj.get_fuselage_weight("fighter", geometry_obj.fuselage.S_wet);
                    % weight_obj.landinggear = weight_obj.get_landinggear_weight("fighter", false, W_TO);
                    % weight_obj.engine = weight_obj.get_eng_installed_weight("fighter",design.propulsion.Weight.Dry);
                    % Then compute the empty weight
                    % weight_obj.OEW = weight_obj.get_OEW(aircraft_type, W_TO, W_TO, geometry_obj.mainwings.AR, propulsion_obj.T0, geometry_obj.mainwings.S_ref, requirements_obj.requirements.MaxMach.Mach, weight_obj.K_vs);

                    % weight_obj.OEW_frac = weight_obj.OEW/weight_obj.W_TO;
                    % Iterate

                    % complete iteration loop, return MTOW and such
                    W_TO_new = total_fuel_used + W_fixed + OEW;

                    % difference = W_TO_new - weight_obj.W_TO;
                    % percent_diff = 100 * difference / weight_obj.W_TO;

                    % results(end+1, :) = [weight_obj.W_TO, weight_obj.W_fixed, weight_obj.fuel_fraction, weight_obj.OEW_frac, weight_obj.OEW, W_TO_new, difference, percent_diff, S_ref_w, S_wet_design];

                    % if abs(difference) < tol
                    %      break;
                    % end
                    % weight_obj.W_TO = W_TO_new;
                    % W_TO = W_TO_new;
                    % geometry_obj.mainwings.S_ref = geometry_obj.mainwings.S_ref;
               end
               % % beta = 1 - (total_fuel_used / (2 * W_TO));
               % results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff', 'S_ref_w', 'S_wet_design'});
               % obj.results_table = results_table;
          end


     % end
end
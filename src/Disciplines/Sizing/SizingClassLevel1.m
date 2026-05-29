classdef SizingClassLevel1
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties
          results_table
     end

     methods (Static)

          % Size to FAR 23 Take-off distance requirements (TAKE-OFF PARAMETER, FAR 23
          % = TOP 23)
          function output = TOP_23(W_S_TO, W_P_TO, sigma, CL_max_TO)
               % Source: Airplane design vol 1, Roskam, 3.2
               output = (W_S_TO*W_P_TO)/(sigma*CL_max_TO);
          end

          % Get takeoff distance
          % Roskam, Airplane design, vol1, eq 3.6
          function output = S_TO(TOP_23)
               output = 8.134*TOP_23 + 0.0149*TOP_23^2;
          end

          % Sizing to FAR 25 Take-Off distance requirements
          % Source: Roskam, Airplane design, vol1, eq 3.6
          % Output: lbf/ft^2 ?
          function output = TOP_25(W_S_TO, sigma, CL_max_TO, T_W_TO)
               output = (W_S_TO)/(sigma*CL_max_TO*T_W_TO);
          end

          % Compute the take-off field length from the TOP_25 requirement
          % Source: Roskam, Airplane design, vol1, eq 3.8
          function output = S_TOFL(TOP_25)
               output = 37.5*TOP_25;
          end

% Military sizing req
% Take-Off ground roll
% Source: Roskam, Airplane design, vol1, eq 3.9
% X = T for jets, P for props
function output = S_TOG_jet(W_S_TO, rho, CL_max_TO, T, W_TO, mu_G, CD0)
kk_1 = 0.0447;
kk_2 = (0.75*((5+bpr)/(4+bpr)));

     output = (kk_1*W_S_TO)/((rho*(CL_max_TO*(kk_2*(T/W_TO) - mu_G) - 0.72*CD0)));
end

% S_TOG but for props.
% Source: Roska, Airplane Design, Vol1, eq 3.9
function output = S_TOG_prop(W_S_TO, rho, CL_max_TO, P_TO, W_TO, mu_G, CD0, l_p, N, D_P)
     % N = number of engines operating
kk_1 = 0.0376;
kk_2 = (l_p*((sigma*N*D_P^2)/(P_TO))^(1/3));

     output = (kk_1*W_S_TO)/((rho*(CL_max_TO*(kk_2*(P_TO/W_TO) - mu_G) - 0.72*CD0)));
end






          function W_TO = size_aircraft(obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj, aero_obj)

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
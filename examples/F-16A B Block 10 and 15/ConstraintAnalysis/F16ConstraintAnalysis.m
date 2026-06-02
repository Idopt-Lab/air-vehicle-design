classdef F16ConstraintAnalysis < ConstraintModel
     %F16CONSTRAINTEST Summary of this class goes here
     %   Detailed explanation goes here
     % YTup

     properties % So these are the CONSTRAINT RESULTS, compared to the CONSTRAINTS THEMSELVES IN THE DESIGN!!!
          Wto_S_range = 20:7:160
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Wto_S_landing
          W0_S_ref
          T_Wto_required
          constraints_table
     end

     methods

          % Constructor for my sanity
          % function obj = F16ConstraintEst3(design)
          function obj = F16ConstraintAnalysis()
               % obj.constraints_table = ConstraintModel.get_design_constraints(obj, design.constraints_filename);
          end

          %

          % do a complete constraint analysis
          function [TW_table, T_Wto_takeoff, optimal_WS, min_TW, Landing, Wto_S_landing, T0_W0, W0_S_ref, T_Wto_required] = constraint_analysis(constraint_obj)

               [constraint_obj.constraints_struct.aero, constraint_obj.constraints_struct.thrust] = initconstraints(constraint_obj);
               % [constraint_obj.constraints_struct.aero, constraint_obj.constraints_struct.thrust] = get_constraints(constraint_obj, design, design.constraints); % Why do I have two functions that do the same thing?
               [constraint_obj.TW_table, constraint_obj.T_Wto_takeoff] = createThrustLoadingTable(constraint_obj, constraint_obj.constraints_table, constraint_obj.constraints_struct.aero, constraint_obj.constraints_struct.thrust, constraint_obj.Wto_S_range, constraint_obj.constraints_table("Takeoff",:));
               [constraint_obj.optimal_WS, constraint_obj.min_TW] = solveOptimalPoint(constraint_obj, constraint_obj.TW_table, constraint_obj.T_Wto_takeoff, constraint_obj.Wto_S_range);
               constraint_obj.Wto_S_landing = landing_constraint(constraint_obj, constraint_obj.constraints_table("Landing",:));
               plotConstraintDiagram(constraint_obj, constraint_obj.Wto_S_range, constraint_obj.TW_table, constraint_obj.T_Wto_takeoff, constraint_obj.Wto_S_landing, constraint_obj.optimal_WS, constraint_obj.min_TW, constraint_obj.constraints_table.Row(:));
               showResultTable(constraint_obj, constraint_obj.TW_table, constraint_obj.constraints_table.Row(:), constraint_obj.Wto_S_range);
          end

          % Initialize constraints
          % function [aero_constraints, thrust_constraints] = initconstraints(constraint_obj)
          %      [aero_constraints, thrust_constraints] = get_constraints(constraint_obj, constraint_obj.constraints_table);
          % end

          % Compute aerodynamic constraints for a given state input
          % function [e_osw, CD0, V, q] = get_aero_constraints(constraint_obj, aero_obj, state_vector, e_osw, Cf, S_wet, S_ref)
          %      % state_vector = array of altitude and Mach numbers
          %      % corresponding to each constraint
          % 
          %      % Loop through entire state vector
          % 
          %      % Compute e, K1, K2, CD0 for that constraint
          %      % Store it in the aero_constraints struct
          %      M = state_vector(1);
          %      h_alt = state_vector(2);
          %      V = AeroUtils.compute_airspeed(state_vector);
          %      q = AeroUtils.compute_q(state_vector);
          %      % K1 = aero_obj.compute_K1(M, AR, e_osw, LE_sweep_deg);
          %      % K2 = aero_obj.compute_K2(M, K1, CLminD);
          %      % CD0 = aero_obj.get_CD0(Cf, S_wet, S_ref);
          %      % Problem: CD0 will be computed differently between levels 1, 2, and 3. Account for this in later builds.
          % 
          %      % aero_constraints.CD0 = CD0;
          %      % aero_constraints.e_osw = e_osw;
          %      % aero_constraints.V = V;
          %      % aero_constraints.q = q;
          % 
          % end

          % Get thrust constraints
          function [alpha, alpha_dry, alpha_wet] = get_thrust_constraints(constraint_obj, state_vector, T_min, T_max, gamma, AB_percent, propulsion_obj)

               M = state_vector(1);
               h_alt = state_vector(2);

               [T_kelvin] = atmosisa(h_alt*0.3048);

               % if (0.0 < AB_percent < 1.00)
                    alpha_dry = propulsion_obj.get_alpha([M, h_alt], "mil");
               % elseif (AB_percent == 1.00)
                    alpha_wet = propulsion_obj.get_alpha(state_vector, "max");
               % end

               alpha = PropulsionUtils.compute_alpha(T_min, T_max, alpha_dry, alpha_wet, AB_percent);
          end

          % Create thrust loading table
          function [TW_table] = createThrustLoadingTable(constraint_obj, aero_constraints, beta, alpha, n, q, V, CD0, K1, Ps, Wto_S_range)
               num_constraints = length(aero_constraints.Row(:));
               TW_table = zeros(num_constraints, length(Wto_S_range));

               for i = 1:num_constraints
                    TW_table(i, :) = ConstraintAnalysisClass.computeWingLoading(Wto_S_range, beta(i), alpha(i), n(i), q(i), V(i), CD0(i), K1(i), Ps(i));
               end
               %
               % T_Wto_takeoff = ConstraintAnalysisClass.takeoff_constraint(Wto_S_range, V_stall, beta, alpha, rho, CL_max, distance, CD0, mu);
          end

          % Solve for the optimal point
          function [optimal_WS, min_TW] = solveOptimalPoint(obj, TW_table, T_Wto_takeoff, Wto_S_range)
               obj.T_Wto_required = max([TW_table; T_Wto_takeoff], [], 1);
               [min_TW, min_idx] = min(obj.T_Wto_required);
               optimal_WS = Wto_S_range(min_idx);
          end

          % % Solve for landing constraints
          % function Wto_S = landing_constraint(obj, Landing)
          %      g = 32.174;
          %      Distance = Landing.Distance_ft_;
          %      beta = Landing.W_Wto;
          %      rho = Landing.("rho (lb/ft^3)");
          %      CLmax = Landing.CLmax; % CL max should definitely be an aero class output
          %      CD0 = Landing.CD0; % CD0 should definitely be an aero class output
          %      mu = Landing.SurfaceFrictionCoefficient_mu_;
          % 
          %      Wto_S = (Distance * rho * g * (mu * CLmax + 0.83 * CD0)) / (1.69 * beta);
          % end

          % Generate the constraint diagram
          %% ---------------------------------------------------
          % Function: Plot constraint diagram
          function plotConstraintDiagram(obj, Wto_S_range, TW_table, T_Wto_takeoff, Wto_S_landing, optimal_WS, min_TW, constraints)
               figure('Name', 'Constraint Diagram'); hold on;
               colors = lines(length(constraints));

               for i = 1:length(constraints)-2
                    plot(Wto_S_range, TW_table(i, :), 'LineWidth', 2, 'DisplayName', constraints{i}, 'Color', colors(i,:));
               end

               plot(Wto_S_range, T_Wto_takeoff, 'k-', 'LineWidth', 2, 'DisplayName', 'Takeoff');
               xline(Wto_S_landing, '--k', 'LineWidth', 2, 'DisplayName', 'Landing');

               plot(optimal_WS, min_TW, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'g', ...
                    'DisplayName', sprintf('Optimum (W/S=%.1f, T/W=%.2f)', optimal_WS, min_TW));

               % plot(Wto_S_range, Cost_est, 'g+', 'LineWidth', 2, 'DisplayName', 'Cost');

               xlabel('Wing Loading W/S [psf]');
               ylabel('Thrust-to-Weight Ratio T/W');
               title('Constraint Diagram with Optimal Design Point');
               legend('Location', 'northeastoutside');
               grid on;
          end


          % %% ---------------------------------------------------
          % % Master Equation
          % function T_Wto = computeWingLoading(obj, constraints, aero, thrust, Wto_S)
          %      beta = constraints.W_Wto;
          %      alpha = thrust.throttleLapse;
          %      n = constraints.n;
          %      q = aero.("q (lbf/ft^2)");
          %      V = aero.("V (ft/s)");
          %      CD0 = aero.("CD0"); % Values should emerge from calculations performed here
          %      % Validate functionality independence of fidelity level (should work
          %      % for all)
          %      K1 = aero.K1;
          %      Ps = constraints.PS_ft_s_;
          % 
          %      if isnan(Ps)==1
          %           Ps = 0;
          %      end
          % 
          %      z = (n * beta) ./ q;
          %      induced = K1 .* (z.^2) .* Wto_S;
          %      linear_drag = CD0 ./ Wto_S;
          %      parasite = Ps ./ V;
          % 
          %      T_Wto = (beta ./ alpha) .* (q ./ beta .* (linear_drag + induced) + parasite);
          % end

          %% ---------------------------------------------------
          % % Takeoff Constraint
          % function T_Wto = takeoff_constraint(obj, Wto_S, TO)
          %      g = 32.174;
          %      V_Vstall = TO.Vstall;
          %      beta = TO.W_Wto;
          %      alpha = TO.throttleLapse;
          %      rho = TO.("rho (lb/ft^3)");
          %      CLmax = TO.CLmax;
          %      Distance = TO.Distance_ft_;
          %      CD0 = TO.CD0;
          %      mu = TO.SurfaceFrictionCoefficient_mu_;
          % 
          %      term1 = V_Vstall^2 * beta^2 .* Wto_S ./ (alpha * rho * CLmax * g * Distance);
          %      term2 = 0.7 * CD0 / (beta * CLmax) + mu;
          %      T_Wto = term1 + term2;
          % end

          % Function: Show results table as a GUI element
          function showResultTable(obj, TW_table, constraintNames, Wto_S_range)
               fig = figure('Name', 'T/W Table');
               uitable(fig, ...
                    'Data', round(TW_table, 3), ...
                    'ColumnName', compose('W/S = %d', Wto_S_range), ...
                    'RowName', constraintNames, ...
                    'Units', 'normalized', ...
                    'Position', [0 0 1 1]);
          end

          % [optimal_WS, min_TW] = solveOptimalPoint(input)
          % Wto_S_landing = landing_constraint(input)
          % plotconstraintDiagram(input)
          % showResultTable(input)

     end
end
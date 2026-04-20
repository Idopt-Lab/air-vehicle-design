classdef F16ConstraintEst < ConstraintModel
     %F16CONSTRAINTEST Summary of this class goes here
     %   Detailed explanation goes here
     % YTup

     properties % So these are the CONSTRAINT RESULTS, compared to the CONSTRAINTS THEMSELVES IN THE DESIGN!!!
          Wto_S_range = 20:7:160
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Landing
          Wto_S_landing
          T0_W0
          W0_S_ref
          T_Wto_required
     end

     methods

          % Constructor for my sanity
          function obj = F16ConstraintEst(obj, design)
               constraint_analysis(obj, design);
          end

          % do a complete constraint analysis
          function [TW_table, T_Wto_takeoff, optimal_WS, min_TW, Landing, Wto_S_landing, T0_W0, W0_S_ref, T_Wto_required] = constraint_analysis(constraint_obj, design)

               [design.constraints.aero, design.constraints.thrust] = initconstraints(constraint_obj, design);
               [design.constraints.aero, design.constraints.thrust] = get_constraints(constraint_obj, design, design.constraints); % Why do I have two functions that do the same thing?
               [constraint_obj.TW_table, constraint_obj.T_Wto_takeoff] = createThrustLoadingTable(constraint_obj, design, design.constraints, design.constraints.aero, design.constraints.thrust, constraint_obj.Wto_S_range, design.constraints("Takeoff",:));
               [constraint_obj.optimal_WS, constraint_obj.min_TW] = solveOptimalPoint(constraint_obj, constraint_obj.TW_table, constraint_obj.T_Wto_takeoff, constraint_obj.Wto_S_range);
               constraint_obj.Wto_S_landing = landing_constraint(constraint_obj, design.constraints("Landing",:));
               plotConstraintDiagram(constraint_obj, constraint_obj.Wto_S_range, constraint_obj.TW_table, constraint_obj.T_Wto_takeoff, constraint_obj.Wto_S_landing, constraint_obj.optimal_WS, constraint_obj.min_TW, design.constraints.Row(:));
               showResultTable(constraint_obj, constraint_obj.TW_table, design.constraints.Row(:), constraint_obj.Wto_S_range);
          end

          % Initialize constraints
          function [aero_constraints, thrust_constraints] = initconstraints(constraint_obj, design)
               [aero_constraints, thrust_constraints] = get_constraints(constraint_obj, design, design.constraints);
          end
     end

     % HELPER METHODS
     methods (Access = private)

          % Get consstraints
          function [aero_constraints, thrust_constraints] = get_constraints(obj, design, extracted_constraints) % I think this is a messy way to do it, but can't think of another way.
               CD0_constraints = extracted_constraints(:, "CD0");
               e_constraints = extracted_constraints(:, "e");
               q_constraints = extracted_constraints(:, "q (lbf/ft^2)");
               V_constraints = extracted_constraints(:, "V (ft/s)");
               K1_constraints = extracted_constraints(:, "K1");
               PS_constraints = extracted_constraints(:, "PS_ft_s_");
               aero_constraints = [CD0_constraints, e_constraints, q_constraints, V_constraints, K1_constraints, PS_constraints];

               thrust1 = extracted_constraints(:, "alpha_dry");
               thrust2 = extracted_constraints(:, "AB_");
               thrust3 = extracted_constraints(:, "throttleLapse");
               thrust_constraints = [thrust1, thrust2, thrust3]; % I could make this part more modular. How? Figure that out later.

               % design.constraints.TO = extracted_constraints("Takeoff",:);

          end

          % Create thrust loading table
          function [TW_table, T_Wto_takeoff] = createThrustLoadingTable(obj, design, constraints, aero, thrust, Wto_S_range, TO)
               num_constraints = length(design.constraints.Row(:));
               TW_table = zeros(num_constraints, length(Wto_S_range));

               for i = 1:num_constraints
                    name = design.constraints.Row{i};
                    TW_table(i, :) = computeWingLoading(obj, constraints(name,:), aero(name,:), thrust(name,:), Wto_S_range);
               end
               %
               T_Wto_takeoff = takeoff_constraint(obj, Wto_S_range, TO);
          end

          % Solve for the optimal point
          function [optimal_WS, min_TW] = solveOptimalPoint(obj, TW_table, T_Wto_takeoff, Wto_S_range)
               obj.T_Wto_required = max([TW_table; T_Wto_takeoff], [], 1);
               [min_TW, min_idx] = min(obj.T_Wto_required);
               optimal_WS = Wto_S_range(min_idx);
          end

          % Solve for landing constraints
          function Wto_S = landing_constraint(obj, Landing)
               g = 32.174;
               Distance = Landing.Distance_ft_;
               beta = Landing.W_Wto;
               rho = Landing.("rho (lb/ft^3)");
               CLmax = Landing.CLmax;
               CD0 = Landing.CD0;
               mu = Landing.SurfaceFrictionCoefficient_mu_;

               Wto_S = (Distance * rho * g * (mu * CLmax + 0.83 * CD0)) / (1.69 * beta);
          end

          % Generate the constraint diagram
          %% ---------------------------------------------------
          % Function: Plot constraint diagram
          function plotConstraintDiagram(obj, Wto_S_range, TW_table, T_Wto_takeoff, Wto_S_landing, optimal_WS, min_TW, constraints)
               figure('Name', 'Constraint Diagram'); hold on;
               colors = lines(length(constraints));

               for i = 1:length(constraints)
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


          %% ---------------------------------------------------
          % Master Equation
          function T_Wto = computeWingLoading(obj, constraints, aero, thrust, Wto_S)
               beta = constraints.W_Wto;
               alpha = thrust.throttleLapse;
               n = constraints.n;
               q = aero.("q (lbf/ft^2)");
               V = aero.("V (ft/s)");
               CD0 = aero.("CD0"); % Values should emerge from calculations performed here
               % Validate functionality independence of fidelity level (should work
               % for all)
               K1 = aero.K1;
               Ps = constraints.PS_ft_s_;

               if isnan(Ps)==1
                    Ps = 0;
               end

               z = (n * beta) ./ q;
               induced = K1 .* (z.^2) .* Wto_S;
               linear_drag = CD0 ./ Wto_S;
               parasite = Ps ./ V;

               T_Wto = (beta ./ alpha) .* (q ./ beta .* (linear_drag + induced) + parasite);
          end

          %% ---------------------------------------------------
          % Takeoff Constraint
          function T_Wto = takeoff_constraint(obj, Wto_S, TO)
               g = 32.174;
               V_Vstall = TO.Vstall;
               beta = TO.W_Wto;
               alpha = TO.throttleLapse;
               rho = TO.("rho (lb/ft^3)");
               CLmax = TO.CLmax;
               Distance = TO.Distance_ft_;
               CD0 = TO.CD0;
               mu = TO.SurfaceFrictionCoefficient_mu_;

               term1 = V_Vstall^2 * beta^2 .* Wto_S ./ (alpha * rho * CLmax * g * Distance);
               term2 = 0.7 * CD0 / (beta * CLmax) + mu;
               T_Wto = term1 + term2;
          end

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
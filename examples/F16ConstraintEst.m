classdef F16ConstraintEst < ConstraintModel
     %F16CONSTRAINTEST Summary of this class goes here
     %   Detailed explanation goes here
     % YTup

     properties
          Wto_S_range = 20:7:160
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Landing
          Wto_S_landing
          T0_W0
          W0_S_ref
          Constraints
          constraintNames
          T_Wto_required
     end

     methods
          function Constraint_Results = constraint_est(obj, design)
               [obj.TW_table, obj.T_Wto_takeoff] = createThrustLoadingTable(obj, design, design.constraints, design.constraints.aero_constraints, design.constraints.thrust, obj.Wto_S_range, design.constraints("Takeoff",:));
               [obj.optimal_WS, obj.min_TW] = solveOptimalPoint(obj, obj.TW_table, obj.T_Wto_takeoff, obj.Wto_S_range);
               obj.Wto_S_landing = landing_constraint(obj, design.constraints("Landing",:));
               plotConstraintDiagram(obj, obj.Wto_S_range, obj.TW_table, obj.T_Wto_takeoff, obj.Wto_S_landing, obj.optimal_WS, obj.min_TW, design.constraints.Row(:));
               showResultTable(obj, obj.TW_table, design.constraints.Row(:), obj.Wto_S_range);
          end
     end

     % HELPER METHODS
     methods (Access = private)

          % Get constraint names
          % function constraintNames = get_constraint_names(obj, design)
          %
          %
          % end

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
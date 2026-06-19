%% ---------------------------------------------------
% Function: Plot constraint diagram
function plotConstraintDiagram(Wto_S_range, TW_table, T_Wto_takeoff, Wto_S_landing, optimal_WS, min_TW, constraintNames, Cost_est)
    figure('Name', 'Constraint Diagram'); hold on;
    colors = lines(length(constraintNames));
    
    for i = 1:length(constraintNames)
        plot(Wto_S_range, TW_table(i, :), 'LineWidth', 2, 'DisplayName', constraintNames{i}, 'Color', colors(i,:));
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
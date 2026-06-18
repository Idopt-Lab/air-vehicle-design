clear; clc; close all;

% Create a grid of points for plotting
x1 = linspace(-2, 2, 100);
x2 = linspace(-1, 3, 100);
[X1, X2] = meshgrid(x1, x2);

% Evaluate the function at each grid point
Z = zeros(size(X1));
for i = 1:numel(X1)
    Z(i) = rosenbrock_function([X1(i), X2(i)]);
end

% Known minimum location and value
x_min = [1, 1];
y_min = rosenbrock_function(x_min);

%% 3D Surface Plot
figure('Position', [100, 100, 1200, 500]);

subplot(1, 2, 1);
surf(X1, X2, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
hold on;
plot3(x_min(1), x_min(2), y_min, 'r*', 'MarkerSize', 20, 'LineWidth', 3);
hold off;
xlabel('x_1', 'FontSize', 12);
ylabel('x_2', 'FontSize', 12);
zlabel('f(x_1, x_2)', 'FontSize', 12);
title('3D Surface Plot of Rosenbrock Function', 'FontSize', 14);
colorbar;
grid on;
view(-35, 30);
legend('Rosenbrock Function', 'Minimum at [1,1]', 'Location', 'best');

%% 2D Contour Plot
subplot(1, 2, 2);
contour(X1, X2, Z, 30, 'LineWidth', 1.5);
hold on;
plot(x_min(1), x_min(2), 'r*', 'MarkerSize', 20, 'LineWidth', 3);
hold off;
xlabel('x_1', 'FontSize', 12);
ylabel('x_2', 'FontSize', 12);
title('2D Contour Plot of Rosenbrock Function', 'FontSize', 14);
colorbar;
grid on;
axis equal;
legend('Contours', 'Minimum at [1,1]', 'Location', 'best');

%% Information about the function
fprintf('Rosenbrock Function Minimum:\n');
fprintf('  Location: x* = [%.2f, %.2f]\n', x_min(1), x_min(2));
fprintf('  Function value: f(x*) = %.6f\n', y_min);
fprintf('\n');
fprintf('Key observations:\n');
fprintf('  - The function has a long, narrow valley\n');
fprintf('  - The valley is curved (banana-shaped)\n');
fprintf('  - The minimum is at the bottom of the valley\n');
fprintf('  - This makes optimization challenging!\n');
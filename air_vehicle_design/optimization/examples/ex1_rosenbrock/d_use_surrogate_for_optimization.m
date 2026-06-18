clear; clc; close all;

%% Load the saved surrogate model
load('rosenbrock_surrogate.mat', 'surrogate');
lb = surrogate.lb;
ub = surrogate.ub;

%% First, let's plot the function

x1g = linspace(lb(1), ub(1), 100);
x2g = linspace(lb(2), ub(2), 100);
[X1, X2] = meshgrid(x1g, x2g);

% Evaluate the function at each grid point
Z = zeros(size(X1));
for i = 1:numel(X1)
    Z(i) = surrogate_objective([X1(i); X2(i)], surrogate);
end

% Known minimum location and value
x_min = [1; 1];
y_min = surrogate_objective(x_min, surrogate);

% 3D Surface Plot
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

% 2D Contour Plot
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

%%

% ---- Start point + bounds (common Rosenbrock demo box) ----
x0 = [-1.2; 1.0];

options = optimoptions('fmincon', ...
    'Algorithm','interior-point', ...
    'Display','iter', ...
    'MaxIterations', 200, ...
    'OptimalityTolerance', 1e-10, ...
    'StepTolerance', 1e-12);

% ---- No constraints besides bounds ----
A = []; b = [];
Aeq = []; beq = [];
nonlcon = [];

obj = @(x) surrogate_objective(x, surrogate);
[xopt, fopt, exitflag, output] = fmincon(obj, x0, A, b, Aeq, beq, lb, ub, nonlcon, options);

fprintf('\n---- fmincon result ----\n');
fprintf('xopt  = [%.12f, %.12f]^T\n', xopt(1), xopt(2));
fprintf('fopt  = %.12e\n', fopt);
fprintf('exitflag = %d\n', exitflag);
disp(output);


%% Uses the surrogate model to evaluate the function
function yhat = surrogate_objective(x, surrogate)
    % x is 2x1 [x1; x2]
    x = x(:);
    T = table(x(1), x(2), 'VariableNames', {'x1','x2'});
    if isfield(surrogate,'uses_transform') && surrogate.uses_transform
        T.t = T.x2 - T.x1.^2; % t = x2 - x1^2
    end
    yhat = predict(surrogate.model, T);
end
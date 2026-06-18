clear; clc; close all;

%%

% ---- Start point + bounds (common Rosenbrock demo box) ----
x0 = [-1.2; 1.0];
lb = [-2; -1];
ub = [ 2;  3];

% ---- Collect iteration history so we can plot the path ----
history.x = [];
history.f = [];

options = optimoptions('fmincon', ...
    'Algorithm','interior-point', ...
    'Display','iter', ...
    'MaxIterations', 200, ...
    'OptimalityTolerance', 1e-10, ...
    'StepTolerance', 1e-12, ...
    'OutputFcn', @outfun);

% ---- No constraints besides bounds ----
A = []; b = [];
Aeq = []; beq = [];
nonlcon = [];

[xopt, fopt, exitflag, output] = fmincon(@rosenbrock_function, x0, A, b, Aeq, beq, lb, ub, nonlcon, options);

fprintf('\n---- fmincon result ----\n');
fprintf('xopt  = [%.12f, %.12f]^T\n', xopt(1), xopt(2));
fprintf('fopt  = %.12e\n', fopt);
fprintf('exitflag = %d\n', exitflag);
disp(output);

%% Plot contours + optimization path + true minimum
x1 = linspace(lb(1), ub(1), 401);
x2 = linspace(lb(2), ub(2), 401);
[X1, X2] = meshgrid(x1, x2);
% Evaluate the function at each grid point
Z = zeros(size(X1));
for i = 1:numel(X1)
    Z(i) = rosenbrock_function([X1(i), X2(i)]);
end

xmin = [1;1];
zmin = rosenbrock_function(xmin);

figure('Color','w','Name','Rosenbrock + fmincon path');
contourf(X1, X2, log10(Z + 1), 40, 'LineColor','none'); 
hold on;
contour(X1, X2, log10(Z + 1), 10, 'k', 'LineWidth', 0.6);

% Optimization path
plot(history.x(1,:), history.x(2,:), '-o', 'LineWidth', 1.5, 'MarkerSize', 4);
plot(x0(1), x0(2), 'ks', 'MarkerSize', 8, 'LineWidth', 1.5);          % start
plot(xopt(1), xopt(2), 'kd', 'MarkerSize', 8, 'LineWidth', 1.5);      % found optimum
plot(xmin(1), xmin(2), 'r.', 'MarkerSize', 25);                       % true min

text(xmin(1), xmin(2), '  True min (1,1)', 'Color','r', 'FontWeight','bold');
text(x0(1), x0(2), '  x_0', 'Color','k', 'FontWeight','bold');
text(xopt(1), xopt(2), '  fmincon', 'Color','k', 'FontWeight','bold');

xlabel('x_1'); ylabel('x_2');
title('fmincon on Rosenbrock (contours of log_{10}(f+1))');
axis tight; grid on; colorbar;

%% Outfun to plot optimization history

function stop = outfun(x, optimValues, state)
    % Output function to record iterate history
    stop = false;
    persistent Xhist Fhist
    switch state
        case 'init'
            Xhist = [];
            Fhist = [];
        case 'iter'
            Xhist(:, end+1) = x; 
            Fhist(end+1) = optimValues.fval; 
        case 'done'
            % Push to base workspace for plotting
            history.x = Xhist;
            history.f = Fhist;
            assignin('base', 'history', history);
    end
end

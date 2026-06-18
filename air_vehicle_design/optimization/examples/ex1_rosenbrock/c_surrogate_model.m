clear; clc; close all;

%% Step 1: Design of Experiments using Latin Hypercube Sampling
fprintf('=== Design of Experiments ===\n');

% Define design space
x1_bounds = [-2, 2];
x2_bounds = [-1, 3];

n_samples = 100;
n_train = 0.75*n_samples;
n_test = 0.25*n_samples;

% Generate LHS samples
lhs_samples = lhsdesign(n_samples, 2);

% Scale samples to the design space
X_doe(:,1) = x1_bounds(1) + lhs_samples(:,1) * (x1_bounds(2) - x1_bounds(1));
X_doe(:,2) = x2_bounds(1) + lhs_samples(:,2) * (x2_bounds(2) - x2_bounds(1));

fprintf('  Number of samples: %d\n', n_samples);
fprintf('  x1 range: [%.1f, %.1f]\n', x1_bounds(1), x1_bounds(2));
fprintf('  x2 range: [%.1f, %.1f]\n\n', x2_bounds(1), x2_bounds(2));

%% Step 2: Evaluate the true function at DoE points
fprintf('=== Function Evaluations ===\n');
Y_doe = zeros(n_samples, 1);
for i = 1:n_samples
    Y_doe(i) = rosenbrock_function(X_doe(i,:));
end

% Store data (nice for viewing / exporting)
% Training data
TrainTable = table(X_doe(1:n_train,1), X_doe(1:n_train,2), Y_doe(1:n_train), ...
    'VariableNames', {'x1','x2','y'});
% Test data
TestTable = table(X_doe(n_train+1:n_samples,1), X_doe(n_train+1:n_samples,2), Y_doe(n_train+1:n_samples), ...
    'VariableNames', {'x1','x2','y'});

fprintf('  DoE samples evaluated\n');
fprintf('  Min response: %.4f\n', min(Y_doe));
fprintf('  Max response: %.4f\n', max(Y_doe));
fprintf('  Mean response: %.4f\n\n', mean(Y_doe));

%% Step 3: Fit a response surface equation 

% (1) Quadratic (baseline)
mdl2 = fitlm(TrainTable, 'y ~ x1 + x2 + x1^2 + x2^2 + x1*x2');

% (2) Full cubic
mdl3 = fitlm(TrainTable, ...
    'y ~ x1 + x2 + x1^2 + x2^2 + x1*x2 + x1^3 + x2^3 + x1^2*x2 + x1*x2^2');

% (3) Full quartic
mdl4 = fitlm(TrainTable, ...
 ['y ~ x1 + x2 + x1^2 + x2^2 + x1*x2 + ' ...
  'x1^3 + x2^3 + x1^2*x2 + x1*x2^2 + ' ...
  'x1^4 + x2^4 + x1^3*x2 + x1*x2^3 + x1^2*x2^2']);

% (4) Problem-informed polynomial basis: t = x2 - x1^2
Ttrain = TrainTable;
Ttrain.t = Ttrain.x2 - Ttrain.x1.^2;
Ttest = TestTable;
Ttest.t = Ttest.x2 - Ttest.x1.^2;

% Quadratic in (x1, t)
mdl_t2 = fitlm(Ttrain, 'y ~ x1 + t + x1^2 + t^2 + x1*t');

% -------------------------
% Evaluate models on test set
% -------------------------
models = {mdl2, mdl3, mdl4, mdl_t2};
names  = {'Quadratic', 'Cubic', 'Quartic', 'Transformed quad (x1,t)'};

results = table('Size',[numel(models) 5], ...
    'VariableTypes', {'string','double','double','double','double'}, ...
    'VariableNames', {'Model','R2','RMSE','MAE','MaxAbsErr'});

for k = 1:numel(models)
    if k == 4
        yhat = predict(models{k}, Ttest);   % uses x1, x2, t
    else
        yhat = predict(models{k}, TestTable);
    end

    e = yhat - TestTable.y;
    RMSE = sqrt(mean(e.^2));
    MAE  = mean(abs(e));
    R2   = 1 - sum((TestTable.y - yhat).^2)/sum((TestTable.y - mean(TestTable.y)).^2);
    MaxAbs = max(abs(e));

    results.Model(k) = names{k};
    results.R2(k) = R2;
    results.RMSE(k) = RMSE;
    results.MAE(k) = MAE;
    results.MaxAbsErr(k) = MaxAbs;
end

disp('--- Polynomial Response Surface Comparison (Test Set) ---');
disp(results);

%% Step 4: Save the surrogate model
surrogate.model = mdl_t2;
surrogate.model_name = "Transformed quadratic (features: x1, t=x2-x1^2)";
surrogate.uses_transform = true;

surrogate.lb = [x1_bounds(1), x2_bounds(1)];
surrogate.ub = [x1_bounds(2), x2_bounds(2)];
surrogate.Ntrain = n_train;
surrogate.created_on = datetime('now');

save('rosenbrock_surrogate.mat', 'surrogate');
fprintf('Saved surrogate to rosenbrock_surrogate.mat (%s)\n', surrogate.model_name);
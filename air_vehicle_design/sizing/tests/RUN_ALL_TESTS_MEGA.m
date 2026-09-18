%RUN_ALL_TESTS_MEGA  Every sizing/ test and every example study, one button.
%
%   Two tiers, kept apart (CLAUDE.md): unit tests are pass/fail, studies and
%   comparison reports are informational. This script never raises, so one
%   broken driver cannot hide the rest. Read the two summary tables.
%
%   Unit tests   tests/**  plus  VnV/BrandtF16A/tests/
%   Drivers      examples/*/studies/  and  examples/*/sanity_checks/

SHOW_FIGURES = true;   % false leaves the 20 study figures hidden

root = fileparts(fileparts(mfilename('fullpath')));   % .../sizing
addpath(genpath(fullfile(root, 'src')), genpath(fullfile(root, 'examples')), ...
        genpath(fullfile(root, 'VnV')), genpath(fullfile(root, 'tests')));

% A hidden figure renders without window events. A VISIBLE one makes MATLAB
% drain its render queue on those events, which stalls the run until you
% click the window. Backtraces off: TSDiagram warns once per grid cell.
set(0, 'DefaultFigureVisible', 'off');
warning('off', 'backtrace');

%% 1. Unit tests
suite = [matlab.unittest.TestSuite.fromFolder(fullfile(root, 'tests'), 'IncludingSubfolders', true), ...
         matlab.unittest.TestSuite.fromFolder(fullfile(root, 'VnV', 'BrandtF16A', 'tests'))];
results = matlab.unittest.TestRunner.withTextOutput().run(suite);
disp(results.table());

%% 2. Studies and comparison reports
drivers = [dir(fullfile(root, 'examples', '**', 'studies', '*.m'));
           dir(fullfile(root, 'examples', '**', 'sanity_checks', '*.m'))];
status = strings(numel(drivers), 1);
for i = 1:numel(drivers)
    status(i) = mega_run_driver(fullfile(drivers(i).folder, drivers(i).name));
end
disp(table(string({drivers.name})', status, 'VariableNames', {'Driver', 'Status'}));

%% 3. Summary
n_fail = sum([results.Failed]);
n_err  = sum(status ~= "OK");
fprintf('\n=== RUN_ALL_TESTS_MEGA ===\n');
fprintf('  Unit tests: %d run, %d failed\n', numel(results), n_fail);
fprintf('  Drivers:    %d run, %d errored\n', numel(drivers), n_err);
if n_fail > 0
    disp(results([results.Failed]).table());
end
if n_err > 0
    disp(table(string({drivers(status ~= "OK").name})', status(status ~= "OK"), ...
        'VariableNames', {'Driver', 'Error'}));
end

% Restore, then reveal the figures last so the summary is not buried.
warning('on', 'backtrace');
set(0, 'DefaultFigureVisible', 'on');
if SHOW_FIGURES
    set(findall(0, 'Type', 'figure'), 'Visible', 'on');
end

function s = mega_run_driver(p)
%MEGA_RUN_DRIVER  Run one driver in its own workspace. Errors are reported.
    fprintf('\n----- %s -----\n', p);
    try
        run(p);
        s = "OK";
    catch ME
        s = string(ME.message);
        fprintf(2, 'ERROR: %s\n', ME.message);
    end
end

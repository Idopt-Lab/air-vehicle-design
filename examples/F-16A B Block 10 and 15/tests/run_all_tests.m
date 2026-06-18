% run_all_tests.m — Execute all F-16 V&V test suites and summarize.
%
% Usage: run from the tests/ directory or call from MATLAB command window:
%   cd('examples/F-16A B Block 10 and 15/tests')
%   run_all_tests

fprintf('\n%s\n', repmat('#', 1, 70));
fprintf('  F-16 Conceptual Sizing Framework — Full V&V Suite\n');
fprintf('  Date: %s\n', datestr(now));
fprintf('%s\n\n', repmat('#', 1, 70));

suites = {
    'test_F16Aerodynamics',
    'test_F16Propulsion',
    'test_F16WeightsAndGeometry',
    'test_F16Mission',
    'test_F16SizingStudies',
};

results = struct('name', {}, 'passed', {}, 'failed', {}, 'duration_s', {});

for i = 1:numel(suites)
    suiteName = suites{i};
    fprintf('Running %s ...\n', suiteName);
    try
        runner  = matlab.unittest.TestRunner.withTextOutput();
        suite   = matlab.unittest.TestSuite.fromClass(str2func(suiteName));
        t0      = tic;
        res     = runner.run(suite);
        elapsed = toc(t0);
        n_pass  = sum([res.Passed]);
        n_fail  = sum([res.Failed]);
        results(end+1) = struct('name', suiteName, 'passed', n_pass, ...
            'failed', n_fail, 'duration_s', elapsed); %#ok<AGROW>
        fprintf('  %s: %d passed, %d failed (%.1f s)\n\n', ...
            suiteName, n_pass, n_fail, elapsed);
    catch ME
        fprintf('  ERROR running %s: %s\n\n', suiteName, ME.message);
        results(end+1) = struct('name', suiteName, 'passed', 0, ...
            'failed', -1, 'duration_s', 0); %#ok<AGROW>
    end
end

% Summary table
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('  SUMMARY\n');
fprintf('%s\n', repmat('=', 1, 70));
fprintf('%-35s %8s %8s %10s\n', 'Suite', 'Passed', 'Failed', 'Time (s)');
fprintf('%s\n', repmat('-', 1, 70));
total_pass = 0; total_fail = 0;
for i = 1:numel(results)
    r = results(i);
    status = '';
    if r.failed == 0
        status = 'OK';
    elseif r.failed > 0
        status = 'FAIL';
    else
        status = 'ERROR';
    end
    fprintf('%-35s %8d %8d %10.1f  %s\n', r.name, r.passed, r.failed, ...
        r.duration_s, status);
    total_pass = total_pass + r.passed;
    total_fail = total_fail + max(0, r.failed);
end
fprintf('%s\n', repmat('-', 1, 70));
fprintf('%-35s %8d %8d\n', 'TOTAL', total_pass, total_fail);
fprintf('%s\n\n', repmat('=', 1, 70));

if total_fail == 0
    fprintf('All tests passed.\n\n');
else
    fprintf('WARNING: %d test(s) failed. See output above for details.\n\n', total_fail);
end

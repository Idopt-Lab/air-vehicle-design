% run_brandt_tests.m  Run all BrandtF16A test suites and report results.

base = fullfile(fileparts(mfilename('fullpath')), ...
    'air_vehicle_design', 'sizing', 'VnV', 'BrandtF16A');
test_dir = fullfile(base, 'tests');

% Add source and test dirs to path
addpath(base);
addpath(test_dir);

suites = {
    'test_BrandtGeometry',
    'test_BrandtAerodynamics',
    'test_BrandtEngine',
    'test_BrandtWeight',
    'test_BrandtMission',
    'test_BrandtConstraintAnalysis',
    'test_BrandtPerformance',
    'test_BrandtBalanceStabControl',
    'test_BrandtCost',
};

total_passed = 0;
total_failed = 0;
total_tests  = 0;

fprintf('\n=== Brandt F-16A VnV Test Run ===\n\n');

for k = 1:numel(suites)
    name = suites{k};
    try
        results = runtests(name, 'OutputDetail', 'None');
        passed = sum([results.Passed]);
        failed = sum([results.Failed]);
        incomplete = sum([results.Incomplete]);
        total_tests  = total_tests  + numel(results);
        total_passed = total_passed + passed;
        total_failed = total_failed + failed + incomplete;

        if failed + incomplete == 0
            status = 'PASS';
        else
            status = 'FAIL';
        end
        fprintf('[%s] %s  (%d/%d passed)\n', status, name, passed, numel(results));

        % Print individual failures
        for r = 1:numel(results)
            if ~results(r).Passed
                fprintf('       FAILED: %s\n', results(r).Name);
                if ~isempty(results(r).Details) && ~isempty(results(r).Details.DiagnosticRecord)
                    diag = results(r).Details.DiagnosticRecord;
                    for d = 1:numel(diag)
                        msg = diag(d).Report;
                        if ~isempty(msg)
                            fprintf('         %s\n', strtrim(msg));
                        end
                    end
                end
            end
        end

    catch ME
        fprintf('[ERROR] %s  — could not run: %s\n', name, ME.message);
        total_failed = total_failed + 1;
    end
end

fprintf('\n--- Summary: %d/%d tests passed', total_passed, total_tests);
if total_failed == 0
    fprintf(' — ALL PASS\n');
else
    fprintf(' — %d FAILED\n', total_failed);
end

exit(total_failed);

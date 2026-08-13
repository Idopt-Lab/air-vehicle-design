%% 
%RUN_ALL_TESTS  Execute the full aircraft-sizing test suite.
%
%   Run from the repository root:
%     >> cd('<repo>/code/aircraft-sizing')
%     >> run_all_tests
%
%   Returns 0 (success) when all tests pass; non-zero otherwise.
%   Each discipline step adds its test file here as it is completed.

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, '..', 'src')));
addpath(genpath(fullfile(root, '..', 'examples')));
% VnV/BrandtF16A/Brandt*.m classes (BrandtGeometry, BrandtEngine,
% BrandtAerodynamics, ...) and the BrandtAeroAdapter/BrandtPropAdapter/
% BrandtMissionGeomAdapter wrappers are constructed by the constraint- and
% mission-comparison reference paths -- without this, any test constructing
% one fails with "Unrecognized function or variable 'BrandtGeometry'".
addpath(genpath(fullfile(root, '..', 'VnV')));
addpath(genpath(root));

suite = matlab.unittest.TestSuite.fromFolder(root, 'IncludingSubfolders', true);

runner = matlab.unittest.TestRunner.withTextOutput();
results = runner.run(suite);

disp(results.table());

if any([results.Failed])
    error('run_all_tests:failures', '%d test(s) failed.', sum([results.Failed]));
end
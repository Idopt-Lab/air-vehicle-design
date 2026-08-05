function results = run_ai_tests()
%RUN_AI_TESTS Run every machinery suite in this folder.
%   RESULTS = RUN_AI_TESTS() runs the five suites that check the F-16A model is
%   built correctly, and prints a one-line summary per suite.
%
%   ALL OF THESE MUST BE GREEN. The two tests that fail by design are the
%   requirement-verification tests in verification/, which this does not run --
%   see docs/README.md, "Three requirements, three verification states".
%
%   The folder is scanned rather than listed, so a sixth suite is picked up
%   the day it is added.

here  = fileparts(mfilename("fullpath"));
suite = matlab.unittest.TestSuite.fromFolder(here);
results = run(suite);

fprintf("\n=== tests_for_ai_coding ===\n");
names = reshape(arrayfun(@(r) extractBefore(string(r.Name) + "/", "/"), results), 1, []);
for s = unique(names, "stable")
    r = results(names == s);
    fprintf("  %-38s %2d run, %2d passed, %2d failed\n", ...
        s, numel(r), nnz([r.Passed]), nnz([r.Failed]));
end
fprintf("  %-38s %2d run, %2d passed, %2d failed\n", "TOTAL", ...
    numel(results), nnz([results.Passed]), nnz([results.Failed]));
if any([results.Failed])
    fprintf("\nA failure here is a regression: the model no longer matches what the\n");
    fprintf("generators are supposed to build.\n");
end

end

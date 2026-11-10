function results = run_ai_tests()
%RUN_AI_TESTS Check that the F-16A numbers and Verify links have not changed.
%   RESULTS = RUN_AI_TESTS() runs each test in this folder.
%   F16ABaselineTest runs each trade study and analysis again, writes to no
%   model, and compares each result with its recorded baseline.
%   F16AVerifyLinksTest checks that each Verify link is still on its test
%   method. The tests must pass after each edit to the models or the tests.
%
%   The requirement-verification tests in verification/ are separate. One of
%   them fails by design (docs/README.md).

results = runtests(fileparts(mfilename("fullpath")));

end

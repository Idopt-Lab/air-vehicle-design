function results = run_ai_tests()
%RUN_AI_TESTS Check that the F-16A numbers and Verify links have not moved.
%   RESULTS = RUN_AI_TESTS() runs every test in this folder:
%   F16ABaselineTest re-runs every trade study and analysis without writing
%   to any model and compares it with its recorded baseline;
%   F16AVerifyLinksTest checks that every Verify link still sits on its test
%   method. It must be green after any edit to the models or the tests.
%
%   The requirement-verification tests in verification/ are separate, and
%   one of them fails by design (docs/README.md).

results = runtests(fileparts(mfilename("fullpath")));

end

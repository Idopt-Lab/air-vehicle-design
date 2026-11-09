function results = run_ai_tests()
%RUN_AI_TESTS Check that the F-16A numbers have not changed.
%   RESULTS = RUN_AI_TESTS() runs F16ABaselineTest. This test runs each trade
%   study and analysis again, writes to no model, and compares each result
%   with its recorded baseline. The test must pass after each edit to the
%   models.
%
%   The requirement-verification tests in verification/ are separate. One of
%   them fails by design (docs/README.md).

results = runtests(fileparts(mfilename("fullpath")));

end

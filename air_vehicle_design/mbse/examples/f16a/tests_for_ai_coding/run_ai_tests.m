function results = run_ai_tests()
%RUN_AI_TESTS Check that the F-16A numbers have not moved.
%   RESULTS = RUN_AI_TESTS() runs F16ABaselineTest: every trade study and
%   analysis is re-run without writing to any model and compared with its
%   recorded baseline. It must be green after any edit to the models.
%
%   The requirement-verification tests in verification/ are separate, and
%   one of them fails by design (docs/README.md).

results = runtests(fileparts(mfilename("fullpath")));

end

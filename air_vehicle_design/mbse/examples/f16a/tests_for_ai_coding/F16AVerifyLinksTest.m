classdef F16AVerifyLinksTest < matlab.unittest.TestCase
    %F16AVERIFYLINKSTEST Every Verify link still points at one test method.
    %   A Verify link from verification/*VerificationTest.m is stored in the
    %   test's ~m.slmx as a CHARACTER range into the .m file. Two things move
    %   that range off its method without any error:
    %     - editing the file above the method (a comment, a blank line);
    %     - a CRLF checkout, which adds one character per line. Windows git
    %       does this unless .gitattributes forces "*.m text eol=lf".
    %   Either way runTests on a requirement set then reports the requirement
    %   as failed, or errors with "Invalid 'ProcedureName' value", while
    %   runtests("verification") still passes. This suite catches both.
    %
    %   To re-point a link: r = slreq.getTextRanges(file); setLineRange(r(k),
    %   [first last]); then save the test's link set.
    %
    %   Run: run_ai_tests, or runtests("F16AVerifyLinksTest").

    properties (TestParameter)
        TestFile = testFiles()
    end

    methods (Test)

        function testFileIsLF(testCase, TestFile)
            nCR = nnz(fileread(TestFile) == char(13));
            testCase.verifyEqual(nCR, 0, sprintf("%s has %d CR characters. " + ...
                "Verify-link offsets assume LF line endings: check that " + ...
                ".gitattributes still has '*.m text eol=lf', then delete the " + ...
                "file and 'git checkout' it again.", TestFile, nCR));
        end

        function testEveryLinkIsOnATestMethod(testCase, TestFile)
            [~, cls] = fileparts(TestFile);
            slmx = fullfile(fileparts(TestFile), cls + "~m.slmx");
            testCase.assumeTrue(isfile(slmx), cls + " has no Verify link set yet.");
            slreq.load(slmx);

            mc = meta.class.fromName(cls);
            isTest = arrayfun(@(m) isprop(m, "Test") && m.Test, mc.MethodList);
            testMethods = string({mc.MethodList(isTest).Name});

            ranges = slreq.getTextRanges(TestFile);
            testCase.verifyNotEmpty(ranges, cls + "~m.slmx holds no text ranges.");
            for r = reshape(ranges, 1, [])
                lines = splitlines(strtrim(string(r.getText)));
                where = sprintf("%s lines %s", cls, mat2str(r.getLineRange));
                head = regexp(lines(1), "^function\s+(?:\w+\s*=\s*)?(\w+)\s*\(", "tokens", "once");
                testCase.verifyNotEmpty(head, where + " does not start at a " + ...
                    "function line; it starts: " + lines(1));
                if isempty(head), continue; end
                testCase.verifyTrue(ismember(head, testMethods), where + ...
                    " starts at " + head + ", which is not a Test method of " + cls + ".");
                nFun = nnz(~cellfun(@isempty, regexp(lines, "^\s*function\s", "once")));
                testCase.verifyEqual(nFun, 1, where + " spans " + nFun + ...
                    " functions; a Verify link must cover exactly one test method.");
            end
        end

    end
end

% =====================================================================
function p = testFiles()
%TESTFILES verification/*VerificationTest.m, as a parameter struct.
vDir = fullfile(fileparts(fileparts(mfilename("fullpath"))), "verification");
d = dir(fullfile(vDir, "*VerificationTest.m"));
p = struct();
for k = 1:numel(d)
    [~, name] = fileparts(d(k).name);
    p.(name) = fullfile(d(k).folder, d(k).name);
end
end

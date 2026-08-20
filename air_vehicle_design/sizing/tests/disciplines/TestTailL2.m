classdef TestTailL2 < matlab.unittest.TestCase
%TESTTAILL2  Unit tests for the Level-2 tail-sizing stub.
%
%   Level-2 tail sizing is NOT IMPLEMENTED. The toolbox TailL2.size and the
%   concrete F16TailL2.size throw 'TailL2:notImplemented'. These tests verify
%   the type contract holds and the not-implemented error is raised (never a
%   silently returned value). See docs/decision_log.md.

    methods (Test)

        function testF16TailL2IsConstructible(tc)
            tc.verifyTrue(isa(F16TailL2(), 'F16TailL2'));
        end

        function testF16TailL2IsaTailSizingBase(tc)
            tc.verifyTrue(isa(F16TailL2(), 'TailSizingBase'));
        end

        function testF16TailL2IsaTailSizingModelL2(tc)
            tc.verifyTrue(isa(F16TailL2(), 'TailSizingModelL2'));
        end

        function testSizeErrorsWithNotImplemented(tc)
        % size() must surface a clear not-implemented error, not a value.
            tc.verifyError(@() F16TailL2().size(), 'TailL2:notImplemented');
        end

        function testSizeIgnoresAnyArgumentsAndStillErrors(tc)
        % Accepts and ignores either calling convention; always errors.
            tc.verifyError(@() F16TailL2().size(300, 30, 11, 46.5), 'TailL2:notImplemented');
        end

        function testStaticToolboxSizeErrors(tc)
            tc.verifyError(@() TailL2.size(struct()), 'TailL2:notImplemented');
        end

    end

end

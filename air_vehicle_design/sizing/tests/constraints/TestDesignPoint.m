classdef TestDesignPoint < matlab.unittest.TestCase
%TESTDESIGNPOINT  Unit tests for the DesignPoint value class.
%
%   DesignPoint packages the three sizing design variables (W_TO, T_SL,
%   S_ref) a point-performance constraint is evaluated at, exposing the two
%   derived quantities WS = W_TO/S_ref and TW = T_SL/W_TO as read-only
%   Dependent properties (see src/constraints/DesignPoint.m). These tests
%   cover the Dependent getters (hand-computed), the mustBePositive input
%   validation, and the read-only immutability of both the stored inputs and
%   the derived properties.

    methods (Test)

        % --- Dependent getters (hand-computed) -------------------------------

        function testWSGetter(tc)
            % WS = W_TO / S_ref.  30000 / 300 = 100 lbf/ft^2.
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyEqual(dp.WS, 100, 'RelTol', 1e-12, ...
                'WS must equal W_TO / S_ref.');
        end

        function testTWGetter(tc)
            % TW = T_SL / W_TO.  24000 / 30000 = 0.8 (dimensionless).
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyEqual(dp.TW, 0.8, 'RelTol', 1e-12, ...
                'TW must equal T_SL / W_TO.');
        end

        function testInputsStored(tc)
            dp = DesignPoint(31377, 23830, 300);
            tc.verifyEqual(dp.W_TO, 31377);
            tc.verifyEqual(dp.T_SL, 23830);
            tc.verifyEqual(dp.S_ref, 300);
        end

        function testIsValueClassNotHandle(tc)
            % DesignPoint must be an immutable VALUE class, not a handle.
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyFalse(isa(dp, 'handle'), ...
                'DesignPoint must be a value class, not a handle.');
        end

        % --- mustBePositive validation ---------------------------------------

        function testZeroWTOErrors(tc)
            tc.verifyError(@() DesignPoint(0, 24000, 300), ...
                'MATLAB:validators:mustBePositive', ...
                'W_TO = 0 must fail mustBePositive.');
        end

        function testNegativeWTOErrors(tc)
            tc.verifyError(@() DesignPoint(-30000, 24000, 300), ...
                'MATLAB:validators:mustBePositive');
        end

        function testZeroTSLErrors(tc)
            tc.verifyError(@() DesignPoint(30000, 0, 300), ...
                'MATLAB:validators:mustBePositive', ...
                'T_SL = 0 must fail mustBePositive.');
        end

        function testZeroSRefErrors(tc)
            % A zero S_ref would also make WS an unguarded division; the
            % mustBePositive validator rejects it at construction instead.
            tc.verifyError(@() DesignPoint(30000, 24000, 0), ...
                'MATLAB:validators:mustBePositive', ...
                'S_ref = 0 must fail mustBePositive.');
        end

        function testNegativeSRefErrors(tc)
            tc.verifyError(@() DesignPoint(30000, 24000, -300), ...
                'MATLAB:validators:mustBePositive');
        end

        % --- Read-only / immutability ----------------------------------------

        function testCannotAssignDependentWS(tc)
            % WS is a get-only Dependent property (no set-method): assigning to
            % it must error -- it is an output, not an input.
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyError(@() setfield(dp, 'WS', 120), ...
                'MATLAB:class:SetProhibited', ...
                'WS is read-only; assigning to it must error.');
        end

        function testCannotAssignDependentTW(tc)
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyError(@() setfield(dp, 'TW', 0.9), ...
                'MATLAB:class:SetProhibited', ...
                'TW is read-only; assigning to it must error.');
        end

        function testCannotAssignInputWTO(tc)
            % The inputs are SetAccess=private: an external assignment must
            % error too (the value class is immutable after construction).
            dp = DesignPoint(30000, 24000, 300);
            tc.verifyError(@() setfield(dp, 'W_TO', 40000), ...
                'MATLAB:class:SetProhibited', ...
                'W_TO is set-once/private; external assignment must error.');
        end

    end

end

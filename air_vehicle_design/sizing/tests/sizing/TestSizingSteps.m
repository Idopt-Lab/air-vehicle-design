classdef TestSizingSteps < matlab.unittest.TestCase
%TESTSIZINGSTEPS  Unit tests for the SizingSteps static toolbox (the TOGW
%   closure step and the under-relaxation step shared by SizingLoopL1/L2 and
%   TSDiagram).
%
%   HAND-COMPUTED EXPECTATIONS (all arithmetic done by hand from the cited
%   formula, independent of the code under test):
%
%   togw_update [docs/reference_extracts/metabook_data.md Ch. 2, Algorithm 1;
%   Raymer 6th ed. Eq. 3.4]:
%       denom  = 1 - W_fuel/W_TO - W_OEW/W_TO
%       W0_new = W_payload / denom          (NaN when denom <= 0)
%
%   Case FIXED POINT: Wp = 800, W_OEW = 1920, W_fuel = 480, W_TO = 3200
%       denom  = 1 - 480/3200 - 1920/3200 = 1 - 0.15 - 0.60 = 0.25
%       W0_new = 800 / 0.25 = 3200   (equals the input W_TO: a fixed point)
%   Case OFF the fixed point: Wp = 800, W_OEW = 600, W_fuel = 150, W_TO = 1000
%       denom  = 1 - 150/1000 - 600/1000 = 0.25;  W0_new = 800/0.25 = 3200
%   Case INFEASIBLE: Wp = 800, W_OEW = 900, W_fuel = 150, W_TO = 1000
%       denom  = 1 - 0.15 - 0.90 = -0.05 <= 0  ->  W0_new = NaN
%   Case BOUNDARY: Wp = 800, W_OEW = 850, W_fuel = 150, W_TO = 1000
%       denom  = 1 - 0.15 - 0.85 = 0 (<= 0)    ->  W0_new = NaN
%
%   relax (successive-substitution damping, x = x_old + w*(x_new - x_old)):
%       relax(100, 200, 1.0) = 100 + 1.0*100 = 200   (w = 1: full step)
%       relax(100, 200, 0.5) = 100 + 0.5*100 = 150   (midpoint)
%       w = 0 and w = 1.5 violate mustBeInRange(w, 0, 1, "exclude-lower")
%
%   TOLERANCES: every expectation above is closed-form arithmetic on exact
%   decimal inputs, so the only deviation is floating-point round-off in the
%   two divisions (~a few eps). AbsTol 1e-9 gives orders-of-magnitude
%   headroom over eps-level round-off while still catching any real
%   formula error.

    properties (Constant)
        ABS_TOL = 1e-9   % round-off headroom only -- see header
    end

    methods (Test)

        % ── togw_update ─────────────────────────────────────────────────── %

        function testTogwUpdateAtFixedPoint(tc)
            % Wp=800, OEW=1920, fuel=480 at W_TO=3200 -> denom 0.25, W0_new
            % 3200 (see header, case FIXED POINT).
            [W0_new, denom] = SizingSteps.togw_update(800, 1920, 480, 3200);
            tc.verifyEqual(denom, 0.25, 'AbsTol', TestSizingSteps.ABS_TOL, ...
                'denom must be 1 - 0.15 - 0.60 = 0.25.');
            tc.verifyEqual(W0_new, 3200, 'AbsTol', TestSizingSteps.ABS_TOL, ...
                'W0_new = 800/0.25 = 3200 (a genuine fixed point).');
        end

        function testTogwUpdateOffFixedPoint(tc)
            % The fractions are evaluated at the CURRENT guess: with the same
            % 0.15/0.60 fractions expressed at W_TO=1000, W0_new is still
            % 3200 (see header, case OFF).
            [W0_new, denom] = SizingSteps.togw_update(800, 600, 150, 1000);
            tc.verifyEqual(denom, 0.25, 'AbsTol', TestSizingSteps.ABS_TOL);
            tc.verifyEqual(W0_new, 3200, 'AbsTol', TestSizingSteps.ABS_TOL);
        end

        function testTogwUpdateNegativeDenomGivesNaN(tc)
            % denom = 1 - 0.15 - 0.90 = -0.05 <= 0 -> NaN (caller decides
            % between error and infeasibility marker; see SizingSteps.m).
            [W0_new, denom] = SizingSteps.togw_update(800, 900, 150, 1000);
            tc.verifyEqual(denom, -0.05, 'AbsTol', TestSizingSteps.ABS_TOL);
            tc.verifyTrue(isnan(W0_new), ...
                'W0_new must be NaN when the closure denominator is negative.');
        end

        function testTogwUpdateZeroDenomGivesNaN(tc)
            % denom = 1 - 0.15 - 0.85 = 0: the boundary counts as infeasible
            % (denom <= 0), because W_payload/0 has no finite fixed point.
            [W0_new, denom] = SizingSteps.togw_update(800, 850, 150, 1000);
            tc.verifyEqual(denom, 0, 'AbsTol', TestSizingSteps.ABS_TOL);
            tc.verifyTrue(isnan(W0_new), ...
                'W0_new must be NaN when the closure denominator is exactly zero.');
        end

        function testTogwUpdateZeroPayloadErrors(tc)
            % W_payload is validated mustBePositive: the closure form has no
            % fixed point at zero payload (SizingSteps.m header).
            tc.verifyError(@() SizingSteps.togw_update(0, 600, 150, 1000), ...
                'MATLAB:validators:mustBePositive');
        end

        % ── relax ───────────────────────────────────────────────────────── %

        function testRelaxFullStepReturnsXNew(tc)
            % w = 1 (upper endpoint, INCLUDED): x = 100 + 1.0*(200-100) = 200.
            x = SizingSteps.relax(100, 200, 1.0);
            tc.verifyEqual(x, 200, 'AbsTol', TestSizingSteps.ABS_TOL, ...
                'w = 1 must be the full step to x_new.');
        end

        function testRelaxMidpoint(tc)
            % w = 0.5: x = 100 + 0.5*(200-100) = 150.
            x = SizingSteps.relax(100, 200, 0.5);
            tc.verifyEqual(x, 150, 'AbsTol', TestSizingSteps.ABS_TOL);
        end

        function testRelaxZeroWErrors(tc)
            % w = 0 (lower endpoint, EXCLUDED) is a frozen iteration -- the
            % validator mustBeInRange(w, 0, 1, "exclude-lower") rejects it.
            tc.verifyError(@() SizingSteps.relax(100, 200, 0), ...
                'MATLAB:validators:mustBeInRange');
        end

        function testRelaxWAboveOneErrors(tc)
            % w > 1 is over-relaxation, outside the documented (0, 1] range.
            tc.verifyError(@() SizingSteps.relax(100, 200, 1.5), ...
                'MATLAB:validators:mustBeInRange');
        end

    end

end

classdef TestSizingLoopL1 < matlab.unittest.TestCase
%TESTSIZINGLOOPL1  Generic (non-F-16-specific) unit tests for the L1
%   takeoff-gross-weight sizing loop, using mock discipline objects plus a
%   REAL ConstraintAnalysis over one analytic toy constraint (so the loop's
%   single pre-loop optimal_point_continuous() call is exercised end-to-end
%   against a hand-derivable optimum, not stubbed away).
%
%   HAND-COMPUTED WEIGHT FIXED POINT:
%   FixedWeightsStub.OEW(W) = 0.60*W, FixedMissionStub.total_fuel(W) =
%   0.15*W, W_payload = 500 + 300 = 800 lbf. The loop's closure step
%   [SizingSteps.togw_update; metabook Algorithm 1 / Raymer 6th ed. Eq. 3.4]
%   is
%       W0_new = 800 / (1 - 0.15 - 0.60) = 800 / 0.25 = 3200 lbf
%   at ANY current guess W0 (both stub fractions are constant), so 3200 is
%   the unique fixed point and every iteration proposes it exactly. When the
%   convergence test fires the loop RETURNS W0 = W0_new = 800/0.25 exactly,
%   so W_TO can be asserted with AbsTol 0.01 (generous vs. the eps-level
%   round-off actually present). W_fuel* = 0.15*3200 = 480 lbf,
%   W_OEW* = 0.60*3200 = 1920 lbf.
%
%   HAND-COMPUTED DESIGN POINT (see ToyProducerConstraint.m for the full
%   calculus): required_TW = A/WS + B*WS with A = 10, B = 0.001 has its
%   unique minimum at
%       WS* = sqrt(A/B) = sqrt(10000) = 100 psf,  TW* = 2*sqrt(A*B) = 0.2.
%   So S_ref* = 3200/100 = 32 ft^2 and T_SL* = 0.2*3200 = 640 lbf.
%
%   DESIGN-POINT TOLERANCES (derived, not tuned): fmincon sqp stops at
%   first-order optimality 1e-6 (default). Along the toy curve the reduced
%   gradient is f'(WS) ~= f''(WS*)*(WS - WS*) with curvature
%   f''(WS*) = 2A/WS*^3 = 2*10/1e6 = 2e-5 per psf^2, so |WS - 100| can be as
%   large as 1e-6/2e-5 = 0.05 psf (5e-4 relative) -> assert WS with
%   RelTol 1e-3. The TW error is second order, 0.5*f''*dWS^2 <= 2.5e-8
%   (~1.3e-7 relative) -> assert TW with RelTol 1e-4.

    properties (Constant)
        W_STAR  = 3200   % lbf -- hand-computed weight fixed point (header)
        WS_STAR = 100    % psf -- sqrt(A/B), A=10, B=0.001 (header)
        TW_STAR = 0.2    % --  -- 2*sqrt(A*B)
        A_TOY   = 10     % toy-constraint coefficient (ToyProducerConstraint)
        B_TOY   = 0.001  % toy-constraint coefficient
    end

    methods (Static)

        function loop = buildLoop()
        %BUILDLOOP  A SizingLoopL1 wired to mock discipline objects plus a
        %   REAL ConstraintAnalysis over one ToyProducerConstraint (the loop
        %   constructor type-checks con as (1,1) ConstraintAnalysis, so a
        %   stub aggregator is not an option -- and the real one also
        %   exercises optimal_point_continuous end-to-end). The aero/prop
        %   stubs only satisfy the constructor's type checks; the toy
        %   constraint reads neither.
            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            miss = FixedMissionStub();   % default fuel_fraction = 0.15
            con  = ConstraintAnalysis( ...
                {ToyProducerConstraint("Toy Producer", ...
                    TestSizingLoopL1.A_TOY, TestSizingLoopL1.B_TOY)}, ...
                20:5:160);
            loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
        end

    end

    methods (Test)

        function testIsHandleClass(tc)
            loop = TestSizingLoopL1.buildLoop();
            tc.verifyTrue(isa(loop, 'handle'));
        end

        function testConvergesToHandComputedFixedPoint(tc)
            % From a guess far below 3200. AbsTol 0.01: the returned value
            % is exactly 800/0.25 (see header), so this is pure headroom.
            loop = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);
            fprintf('\n    W_TO: received=%.6f expected=%.1f  converged=%d  n_iter=%d\n', ...
                result.W_TO, TestSizingLoopL1.W_STAR, result.converged, result.n_iter);
            tc.verifyTrue(result.converged, ...
                'Loop must converge from a guess far from the fixed point.');
            tc.verifyEqual(result.W_TO, TestSizingLoopL1.W_STAR, 'AbsTol', 0.01, ...
                'W_TO must converge to the hand-computed fixed point 3200.');
        end

        function testGuessIndependence(tc)
            % 500 vs 10,000 must agree to RelTol 1e-6: both runs return the
            % exact W0_new = 800/0.25 on their final iteration (header).
            loop_lo = TestSizingLoopL1.buildLoop();
            loop_hi = TestSizingLoopL1.buildLoop();
            result_lo = loop_lo.run(500);
            result_hi = loop_hi.run(10000);
            fprintf('\n    From 500: W_TO=%.6f  From 10000: W_TO=%.6f\n', ...
                result_lo.W_TO, result_hi.W_TO);
            tc.verifyTrue(result_lo.converged);
            tc.verifyTrue(result_hi.converged);
            tc.verifyEqual(result_lo.W_TO, result_hi.W_TO, 'RelTol', 1e-6, ...
                'Converged W_TO must be independent of the initial guess.');
        end

        function testRelaxationInvariance(tc)
            % The under-relaxation factor changes the PATH, never the fixed
            % point: 0.3 vs 0.8 must land on the same W_TO (RelTol 1e-6 for
            % the same exact-return reason as testGuessIndependence).
            loop_a = TestSizingLoopL1.buildLoop();
            loop_b = TestSizingLoopL1.buildLoop();
            result_a = loop_a.run(1000, 'relaxation', 0.3);
            result_b = loop_b.run(1000, 'relaxation', 0.8);
            fprintf('\n    relax=0.3: W_TO=%.6f (n_iter=%d)  relax=0.8: W_TO=%.6f (n_iter=%d)\n', ...
                result_a.W_TO, result_a.n_iter, result_b.W_TO, result_b.n_iter);
            tc.verifyTrue(result_a.converged);
            tc.verifyTrue(result_b.converged);
            tc.verifyEqual(result_a.W_TO, result_b.W_TO, 'RelTol', 1e-6, ...
                'Converged W_TO must be independent of the relaxation factor.');
        end

        function testHistoryCompleteness(tc)
            % One row per completed iteration, every documented field
            % present and finite (the closure is feasible everywhere here).
            loop = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);
            tc.verifyEqual(numel(result.history), result.n_iter, ...
                'history must carry exactly n_iter rows.');
            expected_fields = {'iter', 'W0', 'W_OEW', 'W_fuel', 'W0_new', 'denom'};
            tc.verifyTrue(all(isfield(result.history, expected_fields)), ...
                'history rows must carry the documented field set.');
            for k = 1:numel(result.history)
                vals = cell2mat(struct2cell(result.history(k)));
                tc.verifyTrue(all(isfinite(vals)), ...
                    sprintf('history row %d must be all-finite.', k));
            end
        end

        function testDesignPointWriteThrough(tc)
            % geom.S_ref and prop.T_SL (mutated in place, handle semantics)
            % must equal W_TO/WS and TW*W_TO at convergence, and the
            % reported WS/TW must match the hand-derived toy optimum
            % (tolerances derived in the class header).
            loop = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);

            tc.verifyEqual(result.WS, TestSizingLoopL1.WS_STAR, 'RelTol', 1e-3, ...
                'W/S must sit at the toy optimum sqrt(A/B) = 100 psf.');
            tc.verifyEqual(result.TW, TestSizingLoopL1.TW_STAR, 'RelTol', 1e-4, ...
                'T/W must sit at the toy optimum 2*sqrt(A*B) = 0.2.');

            expected_S_ref = result.W_TO / result.WS;
            expected_T_SL  = result.TW * result.W_TO;
            fprintf(['\n    S_ref: geom=%.6f result=%.6f expected=%.6f (hand ~32)\n' ...
                     '    T_SL:  prop=%.6f result=%.6f expected=%.6f (hand ~640)\n'], ...
                loop.geom.S_ref, result.S_ref, expected_S_ref, ...
                loop.prop.T_SL, result.T_SL, expected_T_SL);
            tc.verifyEqual(loop.geom.S_ref, result.S_ref, 'RelTol', 1e-10, ...
                'The mutated geometry must match the reported S_ref.');
            tc.verifyEqual(loop.prop.T_SL, result.T_SL, 'RelTol', 1e-10, ...
                'The mutated propulsion must match the reported T_SL.');
            tc.verifyEqual(result.S_ref, expected_S_ref, 'RelTol', 1e-10, ...
                'S_ref must equal W_TO/WS at convergence.');
            tc.verifyEqual(result.T_SL, expected_T_SL, 'RelTol', 1e-10, ...
                'T_SL must equal TW*W_TO at convergence.');
        end

        function testWeightsBookkeeping(tc)
            % wts.W_TO / wts.W_energy must reflect the converged state, and
            % the reported fuel must be the stub's 0.15*W_TO = 480 lbf.
            loop = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);
            tc.verifyEqual(loop.wts.W_TO, result.W_TO, 'RelTol', 1e-10, ...
                'wts.W_TO must reflect the converged W_TO (handle mutation).');
            tc.verifyEqual(loop.wts.W_energy, result.W_fuel, 'RelTol', 1e-10, ...
                'wts.W_energy must be set to the mission fuel weight.');
            tc.verifyEqual(result.W_fuel, 0.15 * result.W_TO, 'RelTol', 1e-10, ...
                'W_fuel must equal the stub fraction 0.15*W_TO (= 480 lbf).');
        end

        function testClosureInfeasibleErrors(tc)
            % OEW fraction 0.90 + fuel fraction 0.15 -> denom = 1 - 0.15 -
            % 0.90 = -0.05 <= 0 at every W_TO: the loop must error with the
            % documented identifier, never return silently.
            loop = TestSizingLoopL1.buildLoop();
            loop.wts.oew_fraction = 0.9;   % wts is a handle: mutable in place
            tc.verifyError(@() loop.run(1000), 'SizingLoopL1:closureInfeasible');
        end

        function testNotConvergedWarnsAndReturnsState(tc)
            % max_iter = 1 from a guess of 100,000: iteration 1 proposes
            % W0_new = 3200, a relative step of |3200-100000|/3200 ~= 30.3
            % >> tol_rel, so one iteration CANNOT converge -- the loop must
            % warn (not error) and return converged = false.
            loop = TestSizingLoopL1.buildLoop();
            result = tc.verifyWarning(@() loop.run(100000, 'max_iter', 1), ...
                'SizingLoopL1:notConverged');
            tc.verifyFalse(result.converged);
            tc.verifyEqual(result.n_iter, 1);
        end

    end

end

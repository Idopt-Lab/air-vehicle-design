classdef TestSizingLoopL2 < matlab.unittest.TestCase
%TESTSIZINGLOOPL2  Generic (non-F-16-specific) unit tests for the L2/L3
%   two-state (W_TO, T_SL) sizing loop, using the same weights/mission
%   stubs as TestSizingLoopL1.m plus FixedTailStub and a REAL
%   ConstraintAnalysis over one analytic toy constraint (the constructor
%   type-checks con as (1,1) ConstraintAnalysis; the real aggregator also
%   exercises the per-iteration warm-started optimal_point_continuous).
%
%   HAND-COMPUTED TWO-VARIABLE FIXED POINT:
%   The weight closure is identical to TestSizingLoopL1.m's (constant stub
%   fractions 0.60 OEW / 0.15 fuel, payload 800 lbf):
%       W_TO* = 800 / (1 - 0.15 - 0.60) = 3200 lbf   (exact on return)
%   The toy constraint (ToyProducerConstraint, A = 10, B = 0.001) reads
%   NOTHING from the mutated aero/prop/geom stubs, so every per-iteration
%   design-point solve returns the same hand-derived optimum
%       WS* = sqrt(A/B) = 100 psf,  TW* = 2*sqrt(A*B) = 0.2
%   and the thrust state therefore has the fixed point
%       T_SL* = TW* * W_TO* = 0.2 * 3200 = 640 lbf.
%   S_ref* = W_TO*/WS* = 32 ft^2. Unlike L1, S_ref is REWRITTEN from the
%   re-solved design point every iteration -- the defining L2 behavior.
%
%   TOLERANCES: W_TO AbsTol 0.01 (exact-return argument, see
%   TestSizingLoopL1.m header). T_SL AbsTol 0.01: at the break iteration
%   T_SL = T_SL_new = TW*W0_pre with |W0_pre - 3200|/3200 < tol_rel = 1e-6,
%   so |T_SL - 640| <= 640*1e-6 + TW-solve error ~ 1e-3 << 0.01. WS/TW
%   RelTol 1e-3/1e-4 from the fmincon curvature bound derived in
%   TestSizingLoopL1.m's header. Guess-independence: W_TO RelTol 1e-6
%   (exact return); T_SL RelTol 1e-5, because each run's T_SL carries the
%   ~1e-6-relative pre-update W0 residual plus the ~1.3e-7-relative TW
%   solve error, and two independent runs stack both (~2.4e-6 worst case).

    properties (Constant)
        W_STAR   = 3200   % lbf -- weight fixed point (header)
        T_STAR   = 640    % lbf -- TW* * W_TO* = 0.2*3200
        WS_STAR  = 100    % psf -- sqrt(A/B)
        TW_STAR  = 0.2    % --  -- 2*sqrt(A*B)
        A_TOY    = 10
        B_TOY    = 0.001
    end

    methods (Static)

        function loop = buildLoop()
        %BUILDLOOP  A SizingLoopL2 wired to mock discipline objects, a real
        %   ConstraintAnalysis over the toy producer, and FixedTailStub
        %   (arbitrary non-F-16 volume coefficients; delegates to the real
        %   TailL1 statics -- see its header). geom supplies the fixed
        %   b_wing/cbar_wing/L_fus the tail call reads live.
            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            miss = FixedMissionStub();   % default fuel_fraction = 0.15
            con  = ConstraintAnalysis( ...
                {ToyProducerConstraint("Toy Producer", ...
                    TestSizingLoopL2.A_TOY, TestSizingLoopL2.B_TOY)}, ...
                20:5:160);
            tail = FixedTailStub(geom);
            loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail);
        end

    end

    methods (Test)

        function testIsHandleClass(tc)
            loop = TestSizingLoopL2.buildLoop();
            tc.verifyTrue(isa(loop, 'handle'));
        end

        function testConvergesToHandComputedFixedPoint(tc)
            loop = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 100);
            fprintf('\n    W_TO: received=%.6f expected=%.1f  T_SL: received=%.6f expected=%.1f  converged=%d  n_iter=%d\n', ...
                result.W_TO, TestSizingLoopL2.W_STAR, ...
                result.T_SL, TestSizingLoopL2.T_STAR, result.converged, result.n_iter);
            tc.verifyTrue(result.converged, ...
                'Loop must converge from guesses far from the fixed point.');
            tc.verifyEqual(result.W_TO, TestSizingLoopL2.W_STAR, 'AbsTol', 0.01, ...
                'W_TO must converge to the hand-computed fixed point 3200.');
            tc.verifyEqual(result.T_SL, TestSizingLoopL2.T_STAR, 'AbsTol', 0.01, ...
                'T_SL must converge to TW* * W_TO* = 640 lbf.');
        end

        function testSRefWriteThrough(tc)
            % Unlike L1, S_ref is re-solved every iteration; at convergence
            % it must equal W_TO/WS with the design point at the toy optimum
            % (WS tolerance derived in TestSizingLoopL1.m's header).
            loop = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 100);
            tc.verifyEqual(result.WS, TestSizingLoopL2.WS_STAR, 'RelTol', 1e-3);
            tc.verifyEqual(result.TW, TestSizingLoopL2.TW_STAR, 'RelTol', 1e-4);
            tc.verifyEqual(result.S_ref, result.W_TO / result.WS, 'RelTol', 1e-10, ...
                'S_ref must equal W_TO/WS at convergence.');
            tc.verifyEqual(loop.geom.S_ref, result.S_ref, 'RelTol', 1e-10, ...
                'The mutated geometry must match the reported S_ref.');
            tc.verifyEqual(result.S_ref, ...
                TestSizingLoopL2.W_STAR / TestSizingLoopL2.WS_STAR, ...
                'RelTol', 1e-3, 'S_ref must sit near the hand value 32 ft^2.');
        end

        function testTailWriteThrough(tc)
            % PLUMBING identity, not a tail-equation test (TailL1's own
            % suite covers the equations): the loop must write the injected
            % tail sizer's output for the FINAL S_ref into geom.S_ht/S_vt
            % and report the same values. Hand check at S_ref ~= 32,
            % c_HT = 0.40, c_VT = 0.07, cbar = 11, b = 30, L_fus = 46.5,
            % tail arm 0.475*46.5 = 22.0875 ft:
            %   S_ht ~= 0.40*11*32/22.0875 = 6.375 ft^2
            %   S_vt ~= 0.07*30*32/22.0875 = 3.042 ft^2
            loop = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 100);
            expected = loop.tail.size();   % reads loop.geom live at the final S_ref
            fprintf('\n    S_ht=%.4f (hand ~6.375)  S_vt=%.4f (hand ~3.042)\n', ...
                loop.geom.S_ht, loop.geom.S_vt);
            tc.verifyEqual(loop.geom.S_ht, expected.S_ht, 'RelTol', 1e-10, ...
                'geom.S_ht must carry the tail sizer''s output at the final S_ref.');
            tc.verifyEqual(loop.geom.S_vt, expected.S_vt, 'RelTol', 1e-10, ...
                'geom.S_vt must carry the tail sizer''s output at the final S_ref.');
            tc.verifyEqual(result.S_ht, loop.geom.S_ht, 'RelTol', 1e-10);
            tc.verifyEqual(result.S_vt, loop.geom.S_vt, 'RelTol', 1e-10);
        end

        function testGuessIndependence(tc)
            % (500, 100) vs (10000, 5000). Tolerance rationale in header.
            loop_lo = TestSizingLoopL2.buildLoop();
            loop_hi = TestSizingLoopL2.buildLoop();
            result_lo = loop_lo.run(500, 100);
            result_hi = loop_hi.run(10000, 5000);
            fprintf('\n    From (500,100): W_TO=%.6f T_SL=%.6f  From (10000,5000): W_TO=%.6f T_SL=%.6f\n', ...
                result_lo.W_TO, result_lo.T_SL, result_hi.W_TO, result_hi.T_SL);
            tc.verifyTrue(result_lo.converged);
            tc.verifyTrue(result_hi.converged);
            tc.verifyEqual(result_lo.W_TO, result_hi.W_TO, 'RelTol', 1e-6, ...
                'Converged W_TO must be independent of the initial guesses.');
            tc.verifyEqual(result_lo.T_SL, result_hi.T_SL, 'RelTol', 1e-5, ...
                'Converged T_SL must be independent of the initial guesses.');
        end

        function testHistoryCompleteness(tc)
            loop = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 100);
            tc.verifyEqual(numel(result.history), result.n_iter, ...
                'history must carry exactly n_iter rows.');
            expected_fields = {'iter', 'W0', 'T_SL', 'WS', 'TW', 'S_ref', ...
                'S_ht', 'S_vt', 'W_OEW', 'W_fuel', 'W0_new', 'T_SL_new', 'denom'};
            tc.verifyTrue(all(isfield(result.history, expected_fields)), ...
                'history rows must carry the documented field set.');
            for k = 1:numel(result.history)
                vals = cell2mat(struct2cell(result.history(k)));
                tc.verifyTrue(all(isfinite(vals)), ...
                    sprintf('history row %d must be all-finite.', k));
            end
        end

        function testClosureInfeasibleErrors(tc)
            % Same infeasible split as TestSizingLoopL1: 0.90 + 0.15 gives
            % denom = -0.05 <= 0 at every W_TO.
            loop = TestSizingLoopL2.buildLoop();
            loop.wts.oew_fraction = 0.9;   % handle: mutable in place
            tc.verifyError(@() loop.run(1000, 100), 'SizingLoopL2:closureInfeasible');
        end

        function testNotConvergedWarnsAndReturnsState(tc)
            % One iteration from (100000, 50000) cannot converge (the W0
            % step alone is ~30x tol_rel away): warn, do not error.
            loop = TestSizingLoopL2.buildLoop();
            result = tc.verifyWarning(@() loop.run(100000, 50000, 'max_iter', 1), ...
                'SizingLoopL2:notConverged');
            tc.verifyFalse(result.converged);
            tc.verifyEqual(result.n_iter, 1);
        end

    end

end

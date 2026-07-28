classdef TestSizingLoopL1 < matlab.unittest.TestCase
%TESTSIZINGLOOPL1  Generic (non-F-16-specific) unit tests for the L1
%   takeoff-gross-weight sizing loop, using mock discipline objects.
%
%   FIXED POINT (hand-computed): FixedWeightsStub.OEW(W_TO) = 0.6*W_TO,
%   FixedMissionStub.compute_fuel = 0.15*W_TO, W_payload_fixed=500,
%   W_payload_expendable=300 -- so
%     W_TO_new = 0.6*W_TO + 500 + 300 + 0.15*W_TO = 0.75*W_TO + 800
%   Fixed point: W_TO* = 0.75*W_TO* + 800 -> 0.25*W_TO* = 800 -> W_TO* = 3200.
%   This is a contraction (slope 0.75 < 1) so the loop converges to 3200
%   regardless of the under-relaxation factor or the (arbitrary) S_ref/T_SL
%   values a stub ThrustConstraint's optimal_point() produces -- S_ref and
%   T_SL never feed back into W_TO_new in this stub setup (FixedMissionStub
%   ignores aero/prop; FixedWeightsStub.OEW ignores everything but W_TO).

    methods (Static)

        function [loop, con, WS_opt, TW_opt] = buildLoop()
        %BUILDLOOP  A SizingLoopL1 wired to mock discipline objects plus a
        %   real ConstraintAnalysis wrapping one ThrustConstraint built from
        %   FixedAeroStub/FixedPropStub (arbitrary condition -- only used to
        %   give con.optimal_point() something finite to return).
            aero_stub = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop_stub = FixedPropStub(0.5);
            state     = AircraftState(10000, 0.6);
            c1        = ThrustConstraint("Toy", state, aero_stub, prop_stub, 1.0, 1.0, 0);
            con       = ConstraintAnalysis({c1}, 20:5:150);
            [WS_opt, TW_opt] = con.optimal_point();

            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            miss = FixedMissionStub();

            loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
        end

    end

    methods (Test)

        function testIsHandleClass(tc)
            [loop, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            tc.verifyTrue(isa(loop, 'handle'));
        end

        function testConvergesToHandComputedFixedPoint(tc)
            % NOTE ON TOLERANCE: the loop's convergence check is on the
            % PRE-relaxation difference |W_TO_new-W_TO|, not on distance
            % from the true fixed point -- under 0.5 relaxation, a
            % difference just under tol still leaves the reported W_TO up
            % to 0.75*tol from the exact fixed point (since
            % W_TO_new-W_TO = -0.25*(W_TO-fixed) here, and the final
            % reported value is W_TO_new = fixed + 0.75*(W_TO-fixed)). Pass
            % a tight tol explicitly so this test's AbsTol can be tight too.
            [loop, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            result = loop.run(1000, 'tol', 1e-3);   % far from the fixed point, 3200
            fprintf('\n    W_TO: received=%.6f expected=3200.000000  converged=%d  n_iter=%d\n', ...
                result.W_TO, result.converged, result.n_iter);
            tc.verifyTrue(result.converged, 'Loop must converge from a W_TO guess far from the fixed point.');
            tc.verifyEqual(result.W_TO, 3200, 'AbsTol', 0.01, ...
                'W_TO must converge to the hand-computed fixed point 3200.');
        end

        function testConvergesRegardlessOfInitialGuessDirection(tc)
            % Starting both above and below the fixed point should converge
            % to the same value. Tight tol passed for the same reason as
            % testConvergesToHandComputedFixedPoint above.
            [loop_lo, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            [loop_hi, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            result_lo = loop_lo.run(500, 'tol', 1e-3);
            result_hi = loop_hi.run(10000, 'tol', 1e-3);
            fprintf('\n    From below: W_TO=%.4f (converged=%d)  From above: W_TO=%.4f (converged=%d)\n', ...
                result_lo.W_TO, result_lo.converged, result_hi.W_TO, result_hi.converged);
            tc.verifyTrue(result_lo.converged);
            tc.verifyTrue(result_hi.converged);
            tc.verifyEqual(result_lo.W_TO, 3200, 'AbsTol', 0.01);
            tc.verifyEqual(result_hi.W_TO, 3200, 'AbsTol', 0.01);
        end

        function testHistoryHasNIterRows(tc)
            [loop, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);
            tc.verifyEqual(numel(result.history), result.n_iter);
        end

        function testGeomAndPropMutatedConsistentlyWithResult(tc)
            % After run(), geom.S_ref and prop.T_SL (mutated in place, per
            % handle semantics) must equal result.S_ref/T_SL, and both must
            % equal W_TO/WS_opt and TW_opt*W_TO respectively.
            [loop, ~, WS_opt, TW_opt] = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);

            expected_S_ref = result.W_TO / WS_opt;
            expected_T_SL  = TW_opt * result.W_TO;

            fprintf(['\n    S_ref: geom=%.6f result=%.6f expected=%.6f\n' ...
                     '    T_SL:  prop=%.6f result=%.6f expected=%.6f\n'], ...
                loop.geom.S_ref, result.S_ref, expected_S_ref, ...
                loop.prop.T_SL, result.T_SL, expected_T_SL);

            tc.verifyEqual(loop.geom.S_ref, result.S_ref, 'RelTol', 1e-10);
            tc.verifyEqual(loop.prop.T_SL, result.T_SL, 'RelTol', 1e-10);
            tc.verifyEqual(result.S_ref, expected_S_ref, 'RelTol', 1e-10);
            tc.verifyEqual(result.T_SL, expected_T_SL, 'RelTol', 1e-10);
        end

        function testWeightsObjectUpdatedInPlace(tc)
            [loop, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            result = loop.run(1000);
            tc.verifyEqual(loop.wts.W_TO, result.W_TO, 'RelTol', 1e-10, ...
                'wts.W_TO must reflect the converged W_TO (handle mutation).');
            tc.verifyTrue(isfinite(loop.wts.W_energy), ...
                'wts.W_energy must be set (to the mission fuel weight) by the loop.');
        end

        function testDoesNotConvergeWithinTooFewIterations(tc)
            % Sanity check that the convergence check is doing real work --
            % capping max_iter at 1 from a guess far from the fixed point
            % must NOT report convergence.
            [loop, ~, ~, ~] = TestSizingLoopL1.buildLoop();
            result = loop.run(100000, 'max_iter', 1);
            tc.verifyFalse(result.converged);
            tc.verifyEqual(result.n_iter, 1);
        end

    end

end

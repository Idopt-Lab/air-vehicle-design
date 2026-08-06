classdef TestSizingLoopL2 < matlab.unittest.TestCase
%TESTSIZINGLOOPL2  Generic (non-F-16-specific) unit tests for the L2/L3
%   takeoff-gross-weight + sea-level-thrust sizing loop, using mock
%   discipline objects (same weights/mission stubs as TestSizingLoopL1.m,
%   so the W_TO fixed point is identical: 3200 -- see that class's header
%   for the derivation). S_ref is FIXED here (never touched by
%   SizingLoopL2), unlike L1.

    methods (Static)

        function [loop, con, TW_opt] = buildLoop()
        %BUILDLOOP  A SizingLoopL2 wired to mock discipline objects and a
        %   real ConstraintAnalysis (same construction as
        %   TestSizingLoopL1.buildLoop). Tail/control-surface sizing
        %   (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
        %   SizingLoopL2 once again takes separate tail/ctrl arguments --
        %   FixedTailStub() (arbitrary, non-F-16 volume coefficients,
        %   TailSizingModelL1's four-scalar size(obj, S_ref, b, cbar, L_fus)
        %   convention -- the loop reads S_ref/b_wing/cbar_wing/L_fus live
        %   off geom and passes them in each call) and
        %   ControlSurfaceSizer(0.20, 0.40, 0.30, 0.90, 0.30, 0.90)
        %   (arbitrary, non-F-16 fractions) -- and the loop writes their
        %   results into geom.S_ht/S_vt/S_ail/S_elev/S_rud externally, so
        %   FixedGeomStub no longer needs its own tail-sizing methods.
            aero_stub = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop_stub = FixedPropStub(0.5);
            state     = AircraftState(10000, 0.6);
            c1        = LevelFlightConstraint("Toy", state, aero_stub, prop_stub, 1.0);
            con       = ConstraintAnalysis({c1}, 20:5:150);
            [~, TW_opt] = con.optimal_point();

            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            geom.S_ref = 300;   % fixed input, never touched by SizingLoopL2
            miss = FixedMissionStub();
            tail = FixedTailStub();
            ctrl = ControlSurfaceSizer(0.20, 0.40, 0.30, 0.90, 0.30, 0.90);

            loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
        end

    end

    methods (Test)

        function testIsHandleClass(tc)
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            tc.verifyTrue(isa(loop, 'handle'));
        end

        function testConvergesToHandComputedFixedPoint(tc)
            % Same closure as TestSizingLoopL1's fixed point (3200) --
            % T_SL/S_ref never feed back into this stub weight/mission
            % closure. Tight tol for the same reason as
            % TestSizingLoopL1.testConvergesToHandComputedFixedPoint.
            [loop, ~, TW_opt] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500, 'tol', 1e-3);
            expected_T_SL = TW_opt * 3200;
            fprintf('\n    W_TO: received=%.6f expected=3200.000000  T_SL: received=%.6f expected=%.6f  converged=%d  n_iter=%d\n', ...
                result.W_TO, result.T_SL, expected_T_SL, result.converged, result.n_iter);
            tc.verifyTrue(result.converged, 'Loop must converge from guesses far from the fixed point.');
            tc.verifyEqual(result.W_TO, 3200, 'AbsTol', 0.01);
            tc.verifyEqual(result.T_SL, expected_T_SL, 'AbsTol', 0.01);
        end

        function testSRefNeverChanges(tc)
            % Unlike SizingLoopL1, S_ref must stay exactly the fixed input
            % value throughout -- this is the defining L2/L3 behavior
            % difference from L1.
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            tc.verifyEqual(result.S_ref, 300, 'AbsTol', 0);
            tc.verifyEqual(loop.geom.S_ref, 300, 'AbsTol', 0);
        end

        function testHistoryHasNIterRows(tc)
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            tc.verifyEqual(numel(result.history), result.n_iter);
        end

        function testTailAndControlSurfaceAreasPositive(tc)
            % [docs/subplans/08_sizing.md test table: "Control surface areas
            % positive (L2)", "S_HT, S_VT positive after tail sizing (L2)"]
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            loop.run(1000, 500);
            fprintf('\n    S_ht=%.4f  S_vt=%.4f  S_ail=%.4f  S_elev=%.4f  S_rud=%.4f\n', ...
                loop.geom.S_ht, loop.geom.S_vt, loop.geom.S_ail, loop.geom.S_elev, loop.geom.S_rud);
            tc.verifyGreaterThan(loop.geom.S_ht, 0);
            tc.verifyGreaterThan(loop.geom.S_vt, 0);
            tc.verifyGreaterThan(loop.geom.S_ail, 0);
            tc.verifyGreaterThan(loop.geom.S_elev, 0);   % this stub's ctrl uses a nonzero elevator fraction
            tc.verifyGreaterThan(loop.geom.S_rud, 0);
        end

        function testConvergesRegardlessOfInitialGuessDirection(tc)
            [loop_lo, ~, ~] = TestSizingLoopL2.buildLoop();
            [loop_hi, ~, ~] = TestSizingLoopL2.buildLoop();
            result_lo = loop_lo.run(500, 100, 'tol', 1e-3);
            result_hi = loop_hi.run(10000, 5000, 'tol', 1e-3);
            fprintf('\n    From below: W_TO=%.4f  From above: W_TO=%.4f\n', result_lo.W_TO, result_hi.W_TO);
            tc.verifyTrue(result_lo.converged);
            tc.verifyTrue(result_hi.converged);
            tc.verifyEqual(result_lo.W_TO, 3200, 'AbsTol', 0.01);
            tc.verifyEqual(result_hi.W_TO, 3200, 'AbsTol', 0.01);
        end

        function testDoesNotConvergeWithinTooFewIterations(tc)
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(100000, 50000, 'max_iter', 1);
            tc.verifyFalse(result.converged);
            tc.verifyEqual(result.n_iter, 1);
        end

    end

end

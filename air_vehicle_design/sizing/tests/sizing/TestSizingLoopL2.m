classdef TestSizingLoopL2 < matlab.unittest.TestCase
%TESTSIZINGLOOPL2  Generic (non-F-16-specific) unit tests for the L2/L3
%   takeoff-gross-weight + sea-level-thrust sizing loop, using mock
%   discipline objects (same weights/mission stubs as TestSizingLoopL1.m,
%   so the W_TO fixed point is identical: 3200 -- see that class's header
%   for the derivation). S_ref is SOLVED FOR here as of 2026-08-10 (=
%   W_TO/WS_opt, same as L1); it used to be held at its input value.

    methods (Static)

        function [loop, con, TW_opt, WS_opt] = buildLoop()
        %BUILDLOOP  A SizingLoopL2 wired to mock discipline objects and a
        %   real ConstraintAnalysis (same construction as
        %   TestSizingLoopL1.buildLoop). Tail/control-surface sizing
        %   (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
        %   SizingLoopL2 once again takes separate tail/ctrl arguments --
        %   FixedTailStub() (arbitrary, non-F-16 volume coefficients,
        %   TailSizingModelL1's four-scalar size(obj, S_ref, b, cbar, L_fus)
        %   convention -- the loop reads S_ref/b_wing/cbar_wing/L_fus live
        %   off geom and passes them in each call) and
        %   a ControlSurfaceSizer with arbitrary, non-F-16 fractions -- and
        %   the loop writes their results into
        %   geom.S_ht/S_vt/S_ail/S_elev/S_rud/S_flaperon/S_lef/S_stab
        %   externally, so FixedGeomStub no longer needs its own tail-sizing
        %   methods.
        %
        %   The stub sizer mirrors PRODUCTION's surface set -- flaperon + LEF
        %   + all-moving stabilator + rudder, so S_ail and S_elev are 0 -- but
        %   with arbitrary non-F-16 fractions. It cannot declare an aileron
        %   alongside the flaperon, nor an elevator alongside the all-moving
        %   flag: ControlSurfaceSizer rejects both combinations by design. The
        %   conventional aileron/elevator branch is covered instead by
        %   TestControlSurfaceSizer, which does not need a loop to exercise it.
            aero_stub = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop_stub = FixedPropStub(0.5);
            state     = AircraftState(10000, 0.6);
            c1        = LevelFlightConstraint("Toy", state, aero_stub, prop_stub, 1.0);
            con       = ConstraintAnalysis({c1}, 20:5:150);
            [WS_opt, TW_opt] = con.optimal_point();

            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            geom.S_ref = 300;   % starting value only -- SizingLoopL2 overwrites it with W_TO/WS_opt
            miss = FixedMissionStub();
            tail = FixedTailStub();
            ctrl = ControlSurfaceSizer(0, 0, 0, 0, 0.30, 0.90, ...
                'c_flaperon_frac', 0.25, 'eta_flaperon_in', 0.35, 'eta_flaperon_out', 0.75, ...
                'c_lef_frac', 0.15, 'eta_lef_in', 0.0, 'eta_lef_out', 0.98, ...
                'ht_all_moving', true);

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

        function testSRefTracksOptimumWingLoading(tc)
            % CHANGED 2026-08-10: S_ref is solved for, not held -- it must
            % equal W_TO/WS_opt on exit, be written back into geom, and have
            % moved off the 300 ft^2 starting value buildLoop set.
            [loop, ~, ~, WS_opt] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500, 'tol', 1e-3);
            fprintf('\n    S_ref=%.6f  W_TO/WS_opt=%.6f  (WS_opt=%.4f)\n', ...
                result.S_ref, result.W_TO/WS_opt, WS_opt);
            tc.verifyEqual(result.S_ref, result.W_TO/WS_opt, 'RelTol', 1e-12);
            tc.verifyEqual(loop.geom.S_ref, result.S_ref, 'AbsTol', 0);
            tc.verifyNotEqual(result.S_ref, 300);
        end

        function testHistoryLogsSRef(tc)
            % history now carries S_ref per iteration (it did not before
            % 2026-08-10, when S_ref was loop-invariant).
            [loop, ~, ~, WS_opt] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            tc.verifyTrue(isfield(result.history, 'S_ref'));
            tc.verifyEqual(result.history(1).S_ref, result.history(1).W_TO/WS_opt, 'RelTol', 1e-12);
        end

        function testHistoryHasNIterRows(tc)
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            tc.verifyEqual(numel(result.history), result.n_iter);
        end

        function testTailAndControlSurfaceAreasPositive(tc)
            % [original step-8 test table: "Control surface areas
            % positive (L2)", "S_HT, S_VT positive after tail sizing (L2)"]
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            loop.run(1000, 500);
            g = loop.geom;
            fprintf(['\n    S_ht=%.4f  S_vt=%.4f  S_flaperon=%.4f  S_lef=%.4f  ' ...
                     'S_stab=%.4f  S_rud=%.4f  S_ail=%.4f  S_elev=%.4f\n'], ...
                g.S_ht, g.S_vt, g.S_flaperon, g.S_lef, g.S_stab, g.S_rud, g.S_ail, g.S_elev);
            tc.verifyGreaterThan(g.S_ht, 0);
            tc.verifyGreaterThan(g.S_vt, 0);
            tc.verifyGreaterThan(g.S_flaperon, 0);
            tc.verifyGreaterThan(g.S_lef, 0);
            tc.verifyGreaterThan(g.S_stab, 0);
            tc.verifyGreaterThan(g.S_rud, 0);
            % S_ail/S_elev are 0 by configuration, not by omission: this stub
            % declares a flaperon and an all-moving tail (see buildLoop), so
            % neither an aileron nor a hinged elevator exists to size.
            tc.verifyEqual(g.S_ail, 0, 'AbsTol', 1e-12);
            tc.verifyEqual(g.S_elev, 0, 'AbsTol', 1e-12);
        end

        function testStabilatorAreaEqualsTailArea(tc)
            % The all-moving tail's control area IS the tail [Raymer 6th ed.
            % Table 6.5 footnote]. Checked on the converged geom, so it also
            % catches an epilogue that resized the tail but not the stabilator.
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            loop.run(1000, 500);
            tc.verifyEqual(loop.geom.S_stab, loop.geom.S_ht, 'RelTol', 1e-12, ...
                'S_stab must equal S_ht after the loop, not lag a stale tail area.');
        end

        function testControlSurfaceAreasTrackSRefAcrossIterations(tc)
            % THE REGRESSION GUARD for the 2026-08-10 change. Before it, the
            % control surfaces were recomputed but their areas fed nothing, and
            % a frozen area would have passed every "> 0" check. Here S_ref
            % genuinely moves between the first and last iteration, so each
            % wing surface must move with it -- in the same PROPORTION, since
            % both are linear in S_ref at fixed fractions.
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            tc.assumeGreaterThan(numel(result.history), 1, ...
                'Needs at least two iterations for S_ref to have moved.');
            h1 = result.history(1);
            hN = result.history(end);
            tc.assumeNotEqual(hN.S_ref, h1.S_ref, 'S_ref must move for this test to mean anything.');
            ratio = hN.S_ref / h1.S_ref;
            fprintf('\n    S_ref %.4f -> %.4f (x%.6f)\n', h1.S_ref, hN.S_ref, ratio);
            for f = ["S_flaperon", "S_lef"]
                fprintf('    %-11s %.6f -> %.6f\n', f, h1.(f), hN.(f));
                tc.verifyEqual(hN.(f), h1.(f) * ratio, 'RelTol', 1e-10, ...
                    sprintf('%s must scale with S_ref across iterations, not sit frozen.', f));
            end
            % The tail-mounted surfaces track S_ht/S_vt, which track S_ref
            % through the tail sizer, so they move too -- just not by the same
            % ratio (the tail-volume method divides by the tail arm).
            tc.verifyNotEqual(hN.S_stab, h1.S_stab);
            tc.verifyNotEqual(hN.S_rud, h1.S_rud);
        end

        function testHistoryCarriesAllSixControlSurfaceAreas(tc)
            [loop, ~, ~] = TestSizingLoopL2.buildLoop();
            result = loop.run(1000, 500);
            for f = ["S_ail", "S_elev", "S_rud", "S_flaperon", "S_lef", "S_stab"]
                tc.verifyTrue(isfield(result.history, f), ...
                    sprintf('history must record %s for every iteration.', f));
            end
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

classdef TestTSDiagram < matlab.unittest.TestCase
%TESTTSDIAGRAM  Generic (non-F-16-specific) unit tests for the dimensional
%   T-S sizing diagram (metabook S4.12 Algorithms 2 and 4), using the same
%   toy stub stack as TestSizingLoopL1/L2.m.
%
%   HAND-COMPUTED EXPECTATIONS:
%
%   converge_W0 (Algorithm 2): the stub weights (OEW = 0.60*W) and mission
%   (fuel = 0.15*W) read NOTHING from (T, S), so the TOGW fixed point is the
%   same at EVERY prescribed cell:
%       W0* = 800 / (1 - 0.15 - 0.60) = 3200 lbf
%   (payload 500 + 300; see TestSizingLoopL1.m's header). AbsTol 0.01: the
%   converged return is W0_new = 800/0.25 exactly.
%
%   Infeasible cell: oew_fraction = 0.90 gives denom = 1 - 0.15 - 0.90 =
%   -0.05 <= 0 -> togw_update returns NaN -> converge_W0 must return NaN,
%   NEVER error (the diagram's grid-scan contract).
%
%   constraint_curve (Algorithm 4): with W = 3200 at every cell, the toy
%   producer's T(S) curve is the closed form
%       T(S) = required_TW(3200/S) * 3200,  required_TW = A/WS + B*WS,
%   e.g. at S = 32: WS = 100 -> TW = 10/100 + 0.001*100 = 0.2 -> T = 640.
%   The test asserts the FIXED-POINT IDENTITY |T - required_TW(W/S)*W|/T
%   < 1e-4 at each grid point -- looser than the iteration's own tol_rel
%   1e-6 because the identity is re-evaluated post-hoc at the converged
%   (T, W) pair, where the last relaxed step can leave up to ~tol_rel-level
%   residual amplified by the curve slope; 1e-4 leaves two decades margin
%   while still catching any assembly error.
%
%   wall_curve: with the wall at WS_max = 80 psf and W = 3200 everywhere,
%       S(T) = W/WS_max = 3200/80 = 40 ft^2 at every T.
%   Identity: W/S == WS_max within the same post-hoc 1e-4.
%
%   fuel_grid: feasible cells carry W0 = 3200 and W_fuel = 0.15*3200 = 480;
%   cells made infeasible by SRefGatedWeightsStub (S_ref > 50 -> OEW
%   fraction 0.95 -> denom -0.10) must be NaN in BOTH W0 and W_fuel.

    properties (Constant)
        W_STAR = 3200    % lbf -- toy TOGW fixed point (header)
        A_TOY  = 10
        B_TOY  = 0.001
    end

    methods (Static)

        function [ts, producer, wall] = buildDiagram(withWall)
        %BUILDDIAGRAM  A TSDiagram over the toy stub stack. withWall = true
        %   adds a FixedWallStub at 80 psf after the producer, so
        %   producers() = {producer} and walls() = {wall}.
            arguments
                withWall (1,1) logical = false
            end
            producer = ToyProducerConstraint("Toy Producer", ...
                TestTSDiagram.A_TOY, TestTSDiagram.B_TOY);
            wall = FixedWallStub("Toy Wall", 80);
            if withWall
                constraints = {producer, wall};
            else
                constraints = {producer};
            end
            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            wts  = FixedWeightsStub();
            geom = FixedGeomStub();
            geom.S_ref = 300;            % pre-scan placeholder; every call overwrites it
            miss = FixedMissionStub();   % default fuel_fraction = 0.15
            con  = ConstraintAnalysis(constraints, 20:5:160);
            tail = FixedTailStub(geom);
            ts   = TSDiagram(aero, prop, wts, geom, miss, con, tail);
        end

    end

    methods (Test)

        function testConvergeW0MatchesToyFixedPointAtArbitraryTS(tc)
            % The stub closure is (T, S)-independent, so two very different
            % cells must both converge to 3200 (Algorithm 2 wiring check).
            ts = TestTSDiagram.buildDiagram();
            W0_a = ts.converge_W0(640, 32);
            W0_b = ts.converge_W0(5000, 150);
            fprintf('\n    converge_W0(640,32)=%.6f  converge_W0(5000,150)=%.6f  expected=%.1f\n', ...
                W0_a, W0_b, TestTSDiagram.W_STAR);
            tc.verifyEqual(W0_a, TestTSDiagram.W_STAR, 'AbsTol', 0.01);
            tc.verifyEqual(W0_b, TestTSDiagram.W_STAR, 'AbsTol', 0.01);
        end

        function testConvergeW0ReturnsNaNNotErrorWhenInfeasible(tc)
            % denom = 1 - 0.15 - 0.90 = -0.05 <= 0: the cell is infeasible.
            % Contract: NaN marker, NEVER an error (grid scans must finish).
            ts = TestTSDiagram.buildDiagram();
            ts.wts.oew_fraction = 0.9;   % handle: mutable in place
            W0 = ts.converge_W0(640, 32);   % must not raise
            tc.verifyTrue(isnan(W0), ...
                'converge_W0 must return NaN (not error) at an infeasible cell.');
        end

        function testProducersAndWallsPartition(tc)
            [ts, producer, wall] = TestTSDiagram.buildDiagram(true);
            p = ts.producers();
            w = ts.walls();
            tc.verifyEqual(numel(p), 1);
            tc.verifyEqual(numel(w), 1);
            tc.verifySameHandle(p{1}, producer, ...
                'producers() must return the Both_WbyS_TbyW member.');
            tc.verifySameHandle(w{1}, wall, ...
                'walls() must return the Only_WbyS member.');
        end

        function testConstraintCurveFixedPointIdentity(tc)
            % Algorithm 4 identity at each S: T = required_TW(W/S) * W with
            % W the converged TOGW (3200 here). Hand anchor: T(32) = 640
            % (header). Identity tolerance 1e-4: post-hoc residual bound,
            % see header.
            [ts, producer] = TestTSDiagram.buildDiagram();
            S_grid = [20, 32, 40, 64];
            curve = ts.constraint_curve(1, S_grid);
            tc.verifyEqual(curve.S, S_grid);
            for iS = 1:numel(S_grid)
                tc.verifyTrue(isfinite(curve.T(iS)), ...
                    sprintf('T at S=%g must be finite (feasible cell).', S_grid(iS)));
                tc.verifyEqual(curve.W(iS), TestTSDiagram.W_STAR, 'AbsTol', 0.01, ...
                    'Each curve point must carry the converged toy TOGW.');
                T_identity = producer.required_TW(curve.W(iS) / S_grid(iS)) * curve.W(iS);
                tc.verifyLessThan(abs(curve.T(iS) - T_identity) / curve.T(iS), 1e-4, ...
                    sprintf('T(S=%g) must satisfy the Algorithm-4 fixed-point identity.', S_grid(iS)));
            end
            % Hand anchor at S = 32 ft^2 (WS = 100 -> TW = 0.2 -> T = 640).
            tc.verifyEqual(curve.T(2), 640, 'RelTol', 1e-4, ...
                'T at S=32 must match the hand-computed 640 lbf.');
        end

        function testWallCurveIdentity(tc)
            % Wall identity at each T: W/S == WS_max (80 psf), so S = 40
            % ft^2 at every T (W = 3200 everywhere; header).
            [ts, ~, wall] = TestTSDiagram.buildDiagram(true);
            T_grid = [400, 640, 900];
            wcurve = ts.wall_curve(1, T_grid);
            tc.verifyEqual(wcurve.T, T_grid);
            for iT = 1:numel(T_grid)
                tc.verifyTrue(isfinite(wcurve.S(iT)), ...
                    sprintf('S at T=%g must be finite (feasible cell).', T_grid(iT)));
                tc.verifyEqual(wcurve.W(iT) / wcurve.S(iT), wall.WS_max(), ...
                    'RelTol', 1e-4, ...
                    sprintf('W/S at T=%g must sit on the wall WS_max = 80 psf.', T_grid(iT)));
                tc.verifyEqual(wcurve.S(iT), TestTSDiagram.W_STAR / wall.WS_max(), ...
                    'AbsTol', 0.01, 'S must equal 3200/80 = 40 ft^2.');
            end
        end

        function testFuelGridMasksInfeasibleCells(tc)
            % SRefGatedWeightsStub: S <= 50 feasible (W0 = 3200, W_fuel =
            % 480), S > 50 infeasible (denom = -0.10 -> NaN). The grid must
            % mix finite and NaN cells accordingly, in BOTH outputs.
            producer = ToyProducerConstraint("Toy Producer", ...
                TestTSDiagram.A_TOY, TestTSDiagram.B_TOY);
            aero = FixedAeroStub(1.5, 0.02, 0.1, 0);
            prop = FixedPropStub(0.5);
            geom = FixedGeomStub();
            geom.S_ref = 300;
            wts  = SRefGatedWeightsStub(geom, 50);
            miss = FixedMissionStub();
            con  = ConstraintAnalysis({producer}, 20:5:160);
            tail = FixedTailStub(geom);
            ts   = TSDiagram(aero, prop, wts, geom, miss, con, tail);

            fg = ts.fuel_grid([500, 700], [32, 100]);
            fprintf('\n    W0 grid:\n'); disp(fg.W0);

            tc.verifyEqual(fg.W0(:, 1), [3200; 3200], 'AbsTol', 0.01, ...
                'S = 32 <= 50 cells must converge to the toy fixed point.');
            tc.verifyEqual(fg.W_fuel(:, 1), [480; 480], 'AbsTol', 0.01, ...
                'Feasible cells must carry W_fuel = 0.15*3200 = 480 lbf.');
            tc.verifyTrue(all(isnan(fg.W0(:, 2))), ...
                'S = 100 > 50 cells must be NaN in W0 (infeasible closure).');
            tc.verifyTrue(all(isnan(fg.W_fuel(:, 2))), ...
                'W_fuel must be NaN-masked wherever W0 is NaN.');
        end

    end

end

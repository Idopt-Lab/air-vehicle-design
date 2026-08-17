classdef TestAero481Sizing < matlab.unittest.TestCase
%TESTAero481SIZING  Tier-1 CONVERGENCE + PHYSICAL-SANITY tests for the F-35A
%   (Aero 481 Design01 provenance) L1 sizing stack, driven by SizingLoopL1.
%
%   The F-35 SIZING LOOP is SizingLoopL1, NOT SizingLoopL2. Aero481GeomL1's core
%   L1 quantities (S_wet / L_fuselage) are TOGW regressions, so it cannot feed
%   the iterative L2 loop; SizingLoopL1 reads no planform and guards the
%   geom.W_TO write, so it is the L1-compatible orchestrator (mirrors
%   f16_sizing_L1). Aero481GeomL1 does, however, now expose the tail-resize
%   planform (b_wing / cbar_wing / L_fus) and settable S_ht / S_vt, so the
%   dimensional T-S diagram (TSDiagram.converge_W0) runs at L1 -- the primary
%   A02 sizing regression below (testTSDiagramConvergesAeroA02Point) uses it.
%
%   These are NOT Aero 481 / published-F-35A agreement checks (that is the
%   aero481_comparison report's job -- two-tier rule). This suite asserts
%   only that the loop CONVERGES, is guess-independent, writes the design
%   variables through, and returns PHYSICALLY SANE fighter weights.
%
%   TWO DIFFERENT SIZING POINTS -- do NOT conflate them:
%     * SizingLoopL1 sizes at the CONSTRAINT OPTIMUM: it solves (W/S, T/W) once
%       from the constraint diagram (an aspirational-T/W, generally LARGER
%       aircraft), sets S_ref = W_TO/(W/S) and T_SL = (T/W)*W_TO, and closes
%       W_TO on the DCA mission fuel fraction and the A02 delta-model empty
%       weight. Its tests below assert only convergence + guess-independence +
%       write-through + physical sanity within a WIDE band -- NOT the A02 number.
%     * TSDiagram.converge_W0(43000, 538) reproduces the AERO 481 A02 sizing
%       (~61,000 lbf, A02 62,399 within ~2%) at the A02 design point -- the
%       PRIMARY sizing regression, in testTSDiagramConvergesAeroA02Point.
%
%   WEIGHTS are now the Aero 481 A02 DELTA model (Sainristil fraction + wing
%   delta + engine delta), constructed 3-arg Aero481WeightsL1(sp, geom, prop). The
%   engine delta is strongly negative at the design point (real F135 T_SL below
%   the design-T/W thrust), which is why the F-35 sizes small.
%
%   BANDS (documented, not reverse-engineered). The band 25,000 < W_TO < 130,000
%   lbf brackets the whole fighter range (the A02 ~62k point AND the aspirational
%   constraint-optimum aircraft); the exact number is the comparison-report topic.

    properties (Constant)
        W0_GUESS  = 50000     % lbf  fighter-class initial guess (off any target)
        W0_LO     = 25000     % lbf  sane fighter lower band
        W0_HI     = 130000    % lbf  sane fighter upper band
        W_PAYLOAD = 18441     % lbf  18,000 expendable + 441 fixed [aero481_L1.json .weights]
    end

    methods (Static)
        function loop = buildLoop(WS_range)
            arguments
                WS_range (1,:) double = linspace(20, 200, 181)
            end
            sp   = aero481_spec_path(1);
            rp   = string(aero481_requirements_path());
            aero = Aero481AeroL1(sp);
            prop = Aero481PropL1(sp);
            geom = Aero481GeomL1(sp, rp);
            wts  = Aero481WeightsL1(sp, geom, prop);   % A02 delta model (3-arg): injects geom (S_ref) + prop (T_SL)
            miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "dca");
            con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
                Aero481ConstraintSet.constraint_map(), WS_range);
            loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
        end

        function ts = buildTSDiagram()
        % Full 7-object TSDiagram stack. Aero481GeomL1 now supplies the tail-resize
        % planform (b_wing / cbar_wing / L_fus) and settable S_ht / S_vt, and
        % Aero481TailL1 sizes the tail, so TSDiagram can run at L1 for the F-35 --
        % even though the L1 SIZING LOOP is SizingLoopL1 (see the class header).
            sp   = aero481_spec_path(1);
            rp   = string(aero481_requirements_path());
            aero = Aero481AeroL1(sp);
            prop = Aero481PropL1(sp);
            geom = Aero481GeomL1(sp, rp);
            wts  = Aero481WeightsL1(sp, geom, prop);   % A02 delta model (3-arg): injects geom (S_ref) + prop (T_SL)
            tail = Aero481TailL1(geom);
            miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "dca");
            con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
                Aero481ConstraintSet.constraint_map(), linspace(20, 200, 181));
            ts   = TSDiagram(aero, prop, wts, geom, miss, con, tail);
        end
    end

    % ==================================================================== %
    methods (Test)

        function testConvergesFiniteAndSane(tc)
        % SizingLoopL1 converges to a finite W_TO in the sane fighter band.
            loop = TestAero481Sizing.buildLoop();
            r = loop.run(tc.W0_GUESS);
            fprintf(['\n    W_TO=%.1f  OEW=%.1f  fuel=%.1f  S_ref=%.1f  T_SL=%.1f  ', ...
                'W/S*=%.2f  T/W*=%.4f  (converged=%d, %d iter)\n'], ...
                r.W_TO, r.W_OEW, r.W_fuel, r.S_ref, r.T_SL, r.WS, r.TW, ...
                r.converged, r.n_iter);
            tc.verifyTrue(r.converged, 'SizingLoopL1 must converge.');
            tc.verifyTrue(isfinite(r.W_TO), 'Converged W_TO must be finite.');
            tc.verifyGreaterThan(r.W_TO, tc.W0_LO, ...
                'Converged W_TO must be above the sane fighter lower band (25,000 lbf).');
            tc.verifyLessThan(r.W_TO, tc.W0_HI, ...
                'Converged W_TO must be below the sane fighter upper band (130,000 lbf).');
        end

        function testGuessIndependent(tc)
        % Two very different W_TO guesses must converge to the same fixed point.
            r1 = TestAero481Sizing.buildLoop().run(35000);
            r2 = TestAero481Sizing.buildLoop().run(90000);
            fprintf('\n    W_TO(35k guess)=%.1f  W_TO(90k guess)=%.1f  (diff %+.3f%%)\n', ...
                r1.W_TO, r2.W_TO, 100*(r2.W_TO - r1.W_TO)/r1.W_TO);
            tc.verifyTrue(r1.converged && r2.converged, 'Both runs must converge.');
            tc.verifyEqual(r2.W_TO, r1.W_TO, 'RelTol', 1e-3, ...
                'Converged W_TO must be guess-independent (unique fixed point).');
        end

        function testDesignVariableWriteThrough(tc)
        % The result's S_ref / T_SL are the design variables the loop wrote from
        % the solved (W/S, T/W): S_ref = W_TO/(W/S)*, T_SL = (T/W)* * W_TO.
            r = TestAero481Sizing.buildLoop().run(tc.W0_GUESS);
            tc.verifyEqual(r.S_ref, r.W_TO / r.WS, 'RelTol', 1e-9, ...
                'S_ref must equal W_TO / (W/S)*.');
            tc.verifyEqual(r.T_SL, r.TW * r.W_TO, 'RelTol', 1e-9, ...
                'T_SL must equal (T/W)* * W_TO.');
        end

        function testPhysicalSanityAndClosure(tc)
        % Converged weights are physically sane and the TOGW closure holds:
        % 0 < OEW < W_TO, fuel > 0, W/S in a fighter range, and
        % payload + OEW + fuel = W_TO (Raymer Eq. 3.4 closure identity).
            r = TestAero481Sizing.buildLoop().run(tc.W0_GUESS);
            tc.assertTrue(r.converged, 'Must converge before sanity checks.');
            fprintf(['\n    OEW/W_TO=%.3f  fuel/W_TO=%.3f  payload/W_TO=%.3f  ', ...
                'W/S*=%.2f\n'], r.W_OEW/r.W_TO, r.W_fuel/r.W_TO, ...
                tc.W_PAYLOAD/r.W_TO, r.WS);
            tc.verifyGreaterThan(r.W_OEW, 0, 'OEW must be positive.');
            tc.verifyLessThan(r.W_OEW, r.W_TO, 'OEW must be a fraction of gross weight.');
            tc.verifyGreaterThan(r.W_fuel, 0, 'The DCA mission must burn positive fuel.');
            tc.verifyGreaterThanOrEqual(r.WS, 40, 'W/S* must be in the fighter range (>= 40).');
            tc.verifyLessThanOrEqual(r.WS, 200, 'W/S* must be in the fighter range (<= 200).');
            tc.verifyEqual(tc.W_PAYLOAD + r.W_OEW + r.W_fuel, r.W_TO, 'RelTol', 1e-3, ...
                'payload + OEW + fuel must close to W_TO (Raymer Eq. 3.4).');
        end

        function testTSDiagramConvergesAeroA02Point(tc)
        % PRIMARY F-35 SIZING TEST: the reconciled stack reproduces the Aero 481
        % A02 sizing. Driving the dimensional T-S closure at the A02 design point
        % (T_SL = 43,000 lbf, S = 538 ft^2 = 50 m^2, the upper end of A481's
        % 30-50 m^2 T-S sweep) with the A02 delta-model weights and no altitude
        % lapse (m = 0), TSDiagram.converge_W0 must return a finite W_TO close to
        % the framework's converged ~61,000 lbf, which reproduces Aero 481's A02
        % W_TO = 62,399 lbf within ~2%. RelTol 0.05 is chosen to bracket BOTH the
        % framework value (~61,121) and the A02 target (62,399) around a 61,000
        % lbf anchor -- the residual ~2% is the documented Sainristil/Roskam and
        % mission-fidelity scatter, NOT reverse-engineered to force green (the
        % exact agreement is the aero481_comparison report's job, two-tier
        % rule).
            ts = TestAero481Sizing.buildTSDiagram();
            W0 = ts.converge_W0(43000, 538);
            fprintf(['\n    TSDiagram.converge_W0(T=43000, S=538) = %.1f lbf ', ...
                '(A02 = 62399, %+.2f%%)\n'], W0, 100*(W0-62399)/62399);
            tc.verifyTrue(isfinite(W0), 'TSDiagram.converge_W0 must return a finite W_TO.');
            tc.verifyEqual(W0, 61000, 'RelTol', 0.05, ...
                'converge_W0(43000,538) must reproduce the A02 F-35 sizing (~61,000 lbf, A02 62,399 within 2%).');
            tc.verifyGreaterThan(W0, tc.W0_LO, ...
                'T-S cell W_TO must be above the sane fighter lower band (25,000 lbf).');
            tc.verifyLessThan(W0, tc.W0_HI, ...
                'T-S cell W_TO must be below the sane fighter upper band (130,000 lbf).');
        end

    end
end

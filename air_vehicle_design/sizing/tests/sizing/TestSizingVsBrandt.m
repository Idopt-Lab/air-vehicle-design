classdef TestSizingVsBrandt < matlab.unittest.TestCase
%TESTSIZINGVSBRANDT  Tier-1 live-VnV tests: the sizing loops over the
%   Brandt-discipline validation stack (f16_brandt_stack: Brandt
%   disciplines through the FRAMEWORK mission/constraint analyses).
%
%   ══ TEST 1 -- ALGEBRAIC IDENTITY (not a fidelity check) ══════════════════
%   Brandt's workbook closes exactly:
%       W_payload = 700 + 4,400 = 5,100 lbf      [Brandt Wt!B4/B5 = Main!O16/O17]
%       OEW(31,377) = 19,980.70 lbf              [Brandt Wt!B12]
%       W_fuel(residual) = 6,296.30 lbf          [Brandt Wt!B6]
%       5,100 + 19,980.70 + 6,296.30 = 31,377.00 [Brandt Wt!B3]
%   Pin the mission to Brandt's residual fuel FRACTION f = 6,296.30/31,377
%   (FixedMissionStub) and prescribe Brandt's own (T, S) = (23,770 lbf,
%   300 ft^2) [f16a_geometry.json engine.T_AB_SLS_lb / wing.S_ref_ft2]
%   through TSDiagram.converge_W0 -- the entry point that takes (T, S)
%   directly, needing no constraint solve. The TOGW step at W0 = 31,377 is
%   then
%       denom  = 1 - 6,296.30/31,377 - 19,980.70/31,377 = 5,100/31,377
%       W0_new = 5,100 / (5,100/31,377) = 31,377     -- EXACTLY.
%   So converge_W0(23770, 300) must return 31,377 up to BrandtWeight's
%   documented < 0.1% Wt-tab replication error (BrandtWeightAdapter.m's
%   ground-truth-anchor note; f16a_ground_truth.json weights summary).
%   TOLERANCE RelTol 5e-3: a 0.1% OEW offset (delta-ef ~ 6.4e-4 absolute)
%   amplifies through the closure by ~1/denom_eff with denom_eff = 1 - ff -
%   marginal OEW slope ~ 0.35, i.e. <= ~0.2% on W0; 5e-3 doubles that
%   headroom without admitting any real wiring error (a missing payload
%   term alone would shift W0 by >> 2%). The tail is PINNED to Brandt's
%   actual S_ht/S_vt = 108/60 ft^2 (PinnedTailStub) [Brandt Main!C18/H18]:
%   the volume-coefficient method (F16TailL1) predicts only ~48.4/~25.7
%   ft^2 at the Brandt planform (measured 2026-08-14 -- a tail-sizing-
%   discipline finding, see sizing_brandt_comparison.m), which would break
%   the identity by ~-3.7% through the lighter tail weights.
%
%   ══ TESTS 2-4 -- THE BRANDT SIZING RUNGS (documented bands) ══════════════
%   TWO by-design effects separate the rungs from the actual F-16A numbers.
%   Both were measured live on 2026-08-14 and are NOT loop bugs:
%
%   (1) MISSION BASIS. The rungs run the REAL framework mission
%       (MissionAnalysisL2 x brandt_14seg), which burns ~6,532 lbf at
%       W_TO = 31,377 vs Brandt's 6,296.30 Wt!B6 residual (see
%       mission_brandt_comparison.m). Closure sensitivity:
%           delta_ff = (6,532 - 6,296.30)/31,377 ~= 0.0075
%           d(W0)/W0 ~= delta_ff/denom_eff ~= 0.0075/0.48 ~= +1.6%
%
%   (2) ENVELOPE MINIMUM vs ACTUAL-AIRCRAFT MARGIN. Brandt's Size&Opt point
%       (W/S = 104.59 psf, T/W = 0.7576 = 23,770/31,377) is the ACTUAL
%       F-16A -- reference area and engine of the real aircraft -- and it
%       sits ABOVE the constraint envelope: the envelope over the Brandt
%       aero/prop adapters evaluates to T/W ~= 0.719 at W/S = 104.59 and
%       has its MINIMUM at (W/S ~= 110.8, T/W ~= 0.712) at the stock
%       S = 300 geometry (measured 2026-08-14; fine-grid argmin and the
%       continuous fmincon solve agree). The real aircraft carries ~5-6%
%       thrust margin over the envelope. The sizing loops, by definition
%       [Raymer ch. 5; Martins slides 6/8], size to the ENVELOPE MINIMUM,
%       so their (W/S, T/W) must be checked against the LIVE envelope
%       argmin -- computed fresh with the fmincon-free grid optimal_point()
%       -- NOT against the actual-aircraft point. Deltas vs the actual
%       F-16A are printed informationally and interpreted in
%       sizing_brandt_comparison.m.
%
%   Measured rung outcomes (2026-08-14, recorded for context, not asserted
%   as exact expecteds): L1: W_TO = 32,020 (+2.05%), (W/S, T/W) =
%   (110.84, 0.7120); L2: W_TO = 29,699 (-5.35%), S_ref = 268.4,
%   (W/S, T/W) = (110.67, 0.7064). L2 sits BELOW L1 because the live
%   geometry coupling shrinks the wing to the envelope wing loading
%   (110.7 psf > the real 104.6 psf -> S_ref ~ 268 ft^2 < 300), which
%   cuts wing/tail weight, CD0*S drag area, mission fuel, and (through
%   T_SL = TW*W0) engine weight. A further systematic contribution in BOTH
%   rungs: the volume-coefficient tail resize (F16TailL1) writes
%   ~48.4/~25.7 ft^2 where the real F-16A carries 108/60 [Brandt
%   Main!C18/H18] -- a tail-sizing-discipline gap (measured 2026-08-14)
%   that lightens OEW; interpreted in sizing_brandt_comparison.m.
%
%   Asserted bands:
%       W_TO(L1) RelTol 0.05 of 31,377    [mission offset ~+2% + scatter]
%       W_TO(L2) RelTol 0.08 of 31,377    [+2% mission - ~6-7% envelope-
%                margin/wing-shrink effect -> measured -5.4%]
%       (W/S, T/W) vs live grid argmin at stock geometry, RelTol 0.005
%                (L1 only -- L1 solves the design point ONCE at stock
%                geometry, so the fresh-stack argmin is directly
%                comparable; grid step 0.1 psf on the 1401-pt sweep)
%       L2 W/S within 2% of L1 W/S        [envelope location is weakly
%                geometry-dependent: measured -0.16%]
%       Internal consistency (exact, RelTol 1e-9): T_SL = TW*W_TO and
%                S_ref = W_TO/(W/S) -- the loop's own definitions.
%       L2 W_TO < L1 W_TO                 [direction of the live-coupling
%                effect derived above]

    properties (Constant)
        F_BRANDT_FUEL = 6296.30 / 31377   % Brandt Wt!B6 / Wt!B3 residual fraction
        W_TO_BRANDT   = 31377             % lbf  -- Brandt Wt!B3
        T_SL_BRANDT   = 23770             % lbf  -- f16a_geometry.json engine.T_AB_SLS_lb
        S_REF_BRANDT  = 300               % ft^2 -- f16a_geometry.json wing.S_ref_ft2
        WS_BRANDT     = 104.59            % psf  -- Brandt Size!W_S (cell-map.md)
        TW_BRANDT     = 0.7576            % --   -- Brandt Size!T_W (cell-map.md)
    end

    properties
        r1       % cached f16_sizing_brandt_L1 result (TestClassSetup)
        r2       % cached f16_sizing_brandt_L2 result (TestClassSetup)
        WS_env   % live envelope-argmin W/S at stock geometry (grid, fmincon-free)
        TW_env   % live envelope-argmin T/W at stock geometry
    end

    methods (TestClassSetup)

        function setUpPathAndRunRungsOnce(tc)
            % ONE setup method (not two) so the path setup is GUARANTEED to
            % precede the rung runs -- matlab.unittest does not promise an
            % execution order between separate setup methods.
            % run_all_tests adds VnV/ already; this keeps the file
            % standalone-safe.
            if isempty(which('BrandtGeometry'))
                here        = fileparts(mfilename('fullpath'));
                sizing_root = fileparts(fileparts(here));
                vnv         = fullfile(sizing_root, 'VnV', 'BrandtF16A');
                addpath(vnv);
                addpath(fullfile(vnv, 'GroundTruth'));
            end
            % Live envelope-argmin reference at STOCK geometry (S = 300,
            % T_SL = 23,770), from a FRESH stack via the fmincon-free grid
            % optimal_point() -- the independent reference for the rungs'
            % (W/S, T/W). See header block (2), "envelope minimum vs
            % actual-aircraft margin".
            ref = f16_brandt_stack();
            [tc.WS_env, tc.TW_env] = ref.con.optimal_point();
            % Each rung builds its own full Brandt stack and iterates a real
            % mission per step -- run each ONCE and share across the test
            % methods (runtime choice, documented).
            [tc.r1, ~] = f16_sizing_brandt_L1();          % default guess 28,000
            [tc.r2, ~] = f16_sizing_brandt_L2();          % defaults 28,000 / 20,000
        end

    end

    methods (Test)

        function testBrandtClosureIdentityThroughConvergeW0(tc)
            % ALGEBRAIC IDENTITY -- full derivation and the 5e-3 tolerance
            % rationale in the class header (Test 1 block).
            objs = f16_brandt_stack();
            miss_pinned = FixedMissionStub(TestSizingVsBrandt.F_BRANDT_FUEL);
            tail_pinned = PinnedTailStub(108, 60);   % Brandt Main!C18/H18 -- see header
            ts = TSDiagram(objs.aero, objs.prop, objs.wts, objs.geom, ...
                miss_pinned, objs.con, tail_pinned);

            % RELAXATION 0.25 (not the 0.5 default): the closure map's
            % unrelaxed slope at the Brandt fixed point is m ~= -2.9
            % (measured 2026-08-14; the F-16's large fixed-OEW content
            % makes ef' = d(OEW/W0)/dW0 steep), so w = 0.5 leaves
            % |1 - 3.9w| ~= 0.95 -- oscillating convergence needing >200
            % iterations. w = 0.25 ~= 1/(1-m) nulls the effective slope.
            % See SizingSteps.relax's RELAXATION CHOICE note.
            W0 = ts.converge_W0(TestSizingVsBrandt.T_SL_BRANDT, ...
                TestSizingVsBrandt.S_REF_BRANDT, 'relaxation', 0.25, 'max_iter', 400);
            fprintf('\n    converge_W0(23770, 300) with pinned Brandt fuel fraction: W0=%.2f (Brandt %d, %+.3f%%)\n', ...
                W0, TestSizingVsBrandt.W_TO_BRANDT, ...
                100*(W0 - TestSizingVsBrandt.W_TO_BRANDT)/TestSizingVsBrandt.W_TO_BRANDT);

            tc.verifyTrue(isfinite(W0), ...
                'The Brandt closure identity cell must be feasible.');
            tc.verifyEqual(W0, TestSizingVsBrandt.W_TO_BRANDT, 'RelTol', 5e-3, ...
                'converge_W0(23770, 300) must reproduce Brandt Wt!B3 = 31,377 lbf (algebraic identity).');
        end

        function testBrandtRungL1(tc)
            r = tc.r1;
            fprintf(['\n    brandt L1: W_TO=%.1f (%+.2f%%)  T_SL=%.1f (%+.2f%%)  ' ...
                     'WS=%.3f (%+.2f%%)  TW=%.5f (%+.2f%%)  n_iter=%d\n'], ...
                r.W_TO, 100*(r.W_TO - 31377)/31377, ...
                r.T_SL, 100*(r.T_SL - 23770)/23770, ...
                r.WS, 100*(r.WS - 104.59)/104.59, ...
                r.TW, 100*(r.TW - 0.7576)/0.7576, r.n_iter);
            tc.verifyTrue(r.converged, 'The Brandt L1 rung must converge.');
            tc.verifyEqual(r.W_TO, TestSizingVsBrandt.W_TO_BRANDT, 'RelTol', 0.05, ...
                'W_TO within 5% of Brandt Wt!B3 (expected ~+2% by-design mission offset; header).');
            % (W/S, T/W) against the LIVE envelope argmin at stock geometry --
            % NOT the actual-aircraft point 104.59/0.7576, which carries
            % ~5-6% thrust margin over the envelope (header block (2)).
            tc.verifyEqual(r.WS, tc.WS_env, 'RelTol', 0.005, ...
                'L1 W/S must match the stock-geometry envelope argmin (grid reference).');
            tc.verifyEqual(r.TW, tc.TW_env, 'RelTol', 0.005, ...
                'L1 T/W must match the stock-geometry envelope argmin (grid reference).');
            % Internal consistency: the loop defines T_SL = TW * W_TO.
            tc.verifyEqual(r.T_SL, r.TW * r.W_TO, 'RelTol', 1e-9, ...
                'T_SL must equal TW * W_TO exactly (loop definition).');
        end

        function testBrandtRungL2(tc)
            r = tc.r2;
            fprintf(['\n    brandt L2: W_TO=%.1f (%+.2f%%)  T_SL=%.1f (%+.2f%%)  S_ref=%.2f (%+.2f%%)  ' ...
                     'WS=%.3f (%+.2f%%)  TW=%.5f (%+.2f%%)  n_iter=%d\n'], ...
                r.W_TO, 100*(r.W_TO - 31377)/31377, ...
                r.T_SL, 100*(r.T_SL - 23770)/23770, ...
                r.S_ref, 100*(r.S_ref - 300)/300, ...
                r.WS, 100*(r.WS - 104.59)/104.59, ...
                r.TW, 100*(r.TW - 0.7576)/0.7576, r.n_iter);
            tc.verifyTrue(r.converged, 'The Brandt L2 rung must converge.');
            % W_TO band widened to 8%: the +2% mission offset combines with
            % the -6-7% envelope-margin / wing-shrink effect (header block
            % (2); measured -5.35%).
            tc.verifyEqual(r.W_TO, TestSizingVsBrandt.W_TO_BRANDT, 'RelTol', 0.08, ...
                'W_TO within 8% of Brandt Wt!B3 (mission offset minus envelope-margin effect; header).');
            % Internal consistency (loop definitions). NOT exact at L2: the
            % returned T_SL/W_TO are the RELAXED two-variable iterates and
            % result.TW/WS come from the final reporting re-solve, so the
            % products agree only to the convergence tolerance
            % (tol_rel = 1e-6) amplified by the relaxation -- 1e-5 band.
            tc.verifyEqual(r.T_SL, r.TW * r.W_TO, 'RelTol', 1e-5, ...
                'T_SL must equal TW * W_TO to convergence tolerance (loop definition).');
            tc.verifyEqual(r.S_ref, r.W_TO / r.WS, 'RelTol', 1e-5, ...
                'S_ref must equal W_TO/(W/S) to convergence tolerance (loop definition).');
            % Envelope location is weakly geometry-dependent (measured
            % -0.16% between the L1 stock-geometry solve and L2's converged
            % geometry):
            tc.verifyEqual(r.WS, tc.r1.WS, 'RelTol', 0.02, ...
                'L2 W/S within 2% of L1 W/S (weak geometry dependence of the envelope argmin).');
        end

        function testL2SitsBelowL1(tc)
            % Direction of the live-coupling effect (header): at the envelope
            % wing loading (~110.7 psf > the real 104.6 psf) the L2 loop
            % shrinks the wing (S_ref ~ 268 < 300 ft^2), cutting wing/tail
            % weight, drag area, mission fuel, and engine weight -- so the
            % fully-coupled L2 fixed point must sit BELOW the L1 rung's
            % (which sizes geometry but never re-solves the design point).
            fprintf('\n    L1 W_TO=%.1f  L2 W_TO=%.1f  (diff %+.3f%%)\n', ...
                tc.r1.W_TO, tc.r2.W_TO, 100*(tc.r2.W_TO - tc.r1.W_TO)/tc.r1.W_TO);
            tc.verifyLessThan(tc.r2.W_TO, tc.r1.W_TO, ...
                'The fully-coupled L2 rung must converge below the L1 rung (derivation in header).');
            tc.verifyEqual(tc.r2.W_TO, tc.r1.W_TO, 'RelTol', 0.10, ...
                'L1 and L2 must still sit within 10% of each other (measured -7.2%).');
        end

    end

end

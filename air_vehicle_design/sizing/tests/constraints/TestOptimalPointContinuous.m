classdef TestOptimalPointContinuous < matlab.unittest.TestCase
%TESTOPTIMALPOINTCONTINUOUS  Unit tests for
%   ConstraintAnalysis.optimal_point_continuous (the fmincon-based,
%   sweep-free refinement of the grid-argmin optimal_point).
%
%   TOY EXPECTATIONS (hand-derived; full calculus in
%   ToyProducerConstraint.m's header). required_TW = A/WS + B*WS with
%   A = 10, B = 0.001:
%       WS* = sqrt(A/B) = sqrt(10000) = 100 psf   (exact)
%       TW* = 2*sqrt(A*B) = 2*sqrt(0.01) = 0.2    (exact)
%   The sweep 20:7:160 deliberately has NO node at 100 (nearest are 97 and
%   104), so the grid argmin CANNOT reach the true optimum:
%       TW(97)  = 10/97  + 0.097 = 0.2000928
%       TW(104) = 10/104 + 0.104 = 0.2001538
%   -> grid returns (97, 0.2000928); the continuous solve must do strictly
%   better and land on (100, 0.2).
%
%   TOY TOLERANCES (derived from fmincon's defaults, not tuned to output):
%   sqp stops at first-order optimality 1e-6. At the interior optimum the
%   reduced gradient is f'(WS) ~= f''(WS*)*(WS-WS*), curvature f''(WS*) =
%   2A/WS*^3 = 2e-5 per psf^2, so |WS-100| <= 1e-6/2e-5 = 0.05 psf (5e-4
%   relative) -> WS RelTol 1e-3. The TW error is second order,
%   0.5*f''*dWS^2 <= 2.5e-8 (~1.3e-7 relative) -> TW RelTol 1e-4.
%   WALL case: with a wall at 80 < WS* the optimum is the VERTEX where the
%   wall meets the (strictly decreasing there) producer curve -- fixed by
%   constraint satisfaction (ConstraintTolerance 1e-6), not by the flat
%   objective -- so WS_opt sits on the wall to RelTol 1e-6 and
%       TW* = 10/80 + 0.001*80 = 0.125 + 0.080 = 0.205   (RelTol 1e-6).
%
%   BRANDT TIER-1 CHECK (test e, reworked 2026-08-14): the framework
%   constraint set is built over Brandt's OWN aero/prop
%   (BrandtAeroAdapter/BrandtPropAdapter), the same wiring
%   f16_brandt_stack.m uses, so the check isolates the src ASSEMBLY + the
%   continuous optimizer, not the drag/thrust models. IMPORTANT: Brandt's
%   Size&Opt point (W/S = 104.59 psf, T/W = 0.7576 = 23,770/31,377
%   [cell-map.md Size!W_S / Size!T_W]) is the ACTUAL F-16A and sits ~5-6%
%   ABOVE the constraint envelope (real aircraft = thrust margin), so it
%   is NOT the envelope argmin this method computes. The test therefore
%   asserts (i) continuous-vs-fine-grid argmin agreement + the improvement
%   property, and (ii) the envelope VALUE at the actual-aircraft W/S vs
%   the live BrandtConstraintAnalysis reference, RelTol 0.02 from the
%   documented methodology gap [BrandtConstraintAnalysis.m "DISCREPANCIES
%   FROM GROUND-TRUTH": atmosisa-vs-Brandt-polynomial <= 2% on T/W,
%   analytical-vs-tabulated CD0 < 1% subsonic]. Full rationale in the
%   test-method comment.

    properties (Constant)
        A_TOY   = 10
        B_TOY   = 0.001
        WS_STAR = 100      % psf -- sqrt(A/B)
        TW_STAR = 0.2      % --  -- 2*sqrt(A*B)
        WS_WALL = 80       % psf -- binding wall for test (b)
        TW_AT_WALL = 0.205 % --  -- 10/80 + 0.001*80
        WS_BRANDT = 104.59 % psf -- Brandt Size&Opt, cell-map.md Size!W_S
        TW_BRANDT = 0.7576 % --  -- Brandt Size&Opt, cell-map.md Size!T_W
    end

    methods (Static)

        function s = joinNames(names)
        %JOINNAMES  Comma-join a (possibly empty) string array for fprintf --
        %   strjoin errors on an empty list.
            if isempty(names)
                s = "none";
            else
                s = strjoin(names, ', ');
            end
        end

    end

    methods (TestClassSetup)

        function addBrandtPath(tc) %#ok<MANU>
            % Self-contained path setup (mirrors
            % tests/constraints/brandt_constraint_reference.m): run_all_tests
            % adds VnV/ already; this keeps the file runnable standalone.
            if isempty(which('BrandtGeometry'))
                here        = fileparts(mfilename('fullpath'));
                sizing_root = fileparts(fileparts(here));
                vnv         = fullfile(sizing_root, 'VnV', 'BrandtF16A');
                addpath(vnv);
                addpath(fullfile(vnv, 'GroundTruth'));
            end
        end

    end

    methods (Test)

        % (a) ─ interior toy optimum, continuous beats the coarse grid ───── %

        function testToyInteriorOptimumBeatsGrid(tc)
            producer = ToyProducerConstraint("Toy Producer", ...
                TestOptimalPointContinuous.A_TOY, TestOptimalPointContinuous.B_TOY);
            ca = ConstraintAnalysis({producer}, 20:7:160);   % no node at 100

            [WS_grid, TW_grid] = ca.optimal_point();
            [WS_opt, TW_opt, info] = ca.optimal_point_continuous();
            fprintf('\n    grid: (%.4f, %.7f)  continuous: (%.6f, %.8f)  exitflag=%d\n', ...
                WS_grid, TW_grid, WS_opt, TW_opt, info.exitflag);

            tc.verifyGreaterThan(info.exitflag, 0);
            tc.verifyEqual(WS_opt, TestOptimalPointContinuous.WS_STAR, 'RelTol', 1e-3, ...
                'Continuous W/S must land at sqrt(A/B) = 100 psf (tolerance derived in header).');
            tc.verifyEqual(TW_opt, TestOptimalPointContinuous.TW_STAR, 'RelTol', 1e-4, ...
                'Continuous T/W must land at 2*sqrt(A*B) = 0.2.');
            tc.verifyLessThanOrEqual(TW_opt, TW_grid + 1e-12, ...
                'The continuous optimum must beat or match the grid argmin.');
            tc.verifyLessThanOrEqual(abs(WS_opt - WS_grid), 7, ...
                'Continuous W/S must sit within one grid step of the grid argmin.');
        end

        % (b) ─ wall enforcement: optimum ON the wall ────────────────────── %

        function testWallBindsOptimum(tc)
            producer = ToyProducerConstraint("Toy Producer", ...
                TestOptimalPointContinuous.A_TOY, TestOptimalPointContinuous.B_TOY);
            wall = FixedWallStub("Toy Wall", TestOptimalPointContinuous.WS_WALL);
            ca = ConstraintAnalysis({producer, wall}, 20:7:160);

            [WS_opt, TW_opt, info] = ca.optimal_point_continuous();
            fprintf('\n    wall case: WS=%.8f TW=%.8f  active: %s\n', ...
                WS_opt, TW_opt, TestOptimalPointContinuous.joinNames(info.active_names));

            tc.verifyGreaterThan(info.exitflag, 0);
            tc.verifyEqual(WS_opt, TestOptimalPointContinuous.WS_WALL, 'RelTol', 1e-6, ...
                'With the wall left of WS*, the optimum must sit ON the wall (vertex; header).');
            tc.verifyEqual(TW_opt, TestOptimalPointContinuous.TW_AT_WALL, 'RelTol', 1e-6, ...
                'T/W on the wall must be 10/80 + 0.001*80 = 0.205.');
            tc.verifyTrue(all(info.residuals <= 1e-5), ...
                'Every residual must be feasible (g <= 0 up to fmincon''s constraint tolerance).');
        end

        % (c) ─ infeasible set errors with the documented identifier ─────── %

        function testInfeasibleSetErrors(tc)
            % A wall at 10 psf sits LEFT of the whole sweep (lb = 20 psf):
            % g = WS - 10 > 0 everywhere in bounds, so no feasible point
            % exists. An explicit seed is passed because the default
            % grid-argmin seeding presumes a non-empty feasible grid band;
            % the error under test is the fmincon infeasibility one.
            producer = ToyProducerConstraint("Toy Producer", ...
                TestOptimalPointContinuous.A_TOY, TestOptimalPointContinuous.B_TOY);
            wall = FixedWallStub("Impossible Wall", 10);
            ca = ConstraintAnalysis({producer, wall}, 20:7:160);
            tc.verifyError(@() ca.optimal_point_continuous([30, 0.5]), ...
                'ConstraintAnalysis:optimalPointContinuousInfeasible');
        end

        % (d) ─ bad seed errors ──────────────────────────────────────────── %

        function testBadSeedScalarErrors(tc)
            producer = ToyProducerConstraint("Toy Producer", ...
                TestOptimalPointContinuous.A_TOY, TestOptimalPointContinuous.B_TOY);
            ca = ConstraintAnalysis({producer}, 20:7:160);
            tc.verifyError(@() ca.optimal_point_continuous(100), ...
                'ConstraintAnalysis:invalidSeed');
        end

        function testBadSeedThreeElementErrors(tc)
            producer = ToyProducerConstraint("Toy Producer", ...
                TestOptimalPointContinuous.A_TOY, TestOptimalPointContinuous.B_TOY);
            ca = ConstraintAnalysis({producer}, 20:7:160);
            tc.verifyError(@() ca.optimal_point_continuous([100, 0.2, 1]), ...
                'ConstraintAnalysis:invalidSeed');
        end

        % (e) ─ Brandt tier-1 live-VnV check ─────────────────────────────── %

        function testBrandtEnvelopeOptimumConsistent(tc)
            % Framework ConstraintAnalysis (from_requirements + the F-16
            % map) over Brandt's OWN disciplines through the adapters --
            % identical wiring to f16_brandt_stack.m. Sweep
            % linspace(20,160,1401) (0.1-psf grid resolution).
            %
            % WHAT IS ASSERTED (reworked 2026-08-14). Brandt's Size&Opt
            % point (104.59 psf, 0.7576) is the ACTUAL F-16A -- its T/W is
            % literally 23,770/31,377 -- and it sits ~5-6% ABOVE the
            % constraint envelope (measured: envelope T/W ~0.719 at 104.59;
            % envelope MINIMUM at ~(110.8, 0.712)). The real aircraft
            % carries thrust margin; an envelope argmin does not. So the
            % continuous optimum is checked for CONSISTENCY WITH THE
            % ENVELOPE it minimizes, not against the aircraft point:
            %   (1) exitflag > 0;
            %   (2) WS_opt within one 0.1-psf grid step of the fine-grid
            %       argmin (the fmincon-free reference), and TW_opt no
            %       WORSE than the grid minimum (improvement property);
            %   (3) the envelope evaluated at the ACTUAL aircraft W/S =
            %       104.59 psf matches the same quantity from the live
            %       BrandtConstraintAnalysis reference within the
            %       documented 2% methodology band
            %       [BrandtConstraintAnalysis.m "DISCREPANCIES"] -- the
            %       true "Brandt reproduced" statement at constraint level.
            % The aircraft's margin over the envelope is printed
            % informationally and interpreted in sizing_brandt_comparison.m.
            bg = BrandtGeometry();       bg.analyze();
            ba = BrandtAerodynamics(bg); ba.analyze();
            be = BrandtEngine();         be.analyze();
            aero = BrandtAeroAdapter(ba);
            prop = BrandtPropAdapter(be);

            con = ConstraintAnalysis.from_requirements(aero, prop, ...
                f16a_requirements_path(), F16ConstraintSet.constraint_map(), ...
                linspace(20, 160, 1401));

            [WS_grid, TW_grid] = con.optimal_point();
            [WS_opt, TW_opt, info] = con.optimal_point_continuous();

            % Envelope at the actual-aircraft W/S: framework vs the live
            % Brandt Consts-tab reference (max over the seven producers;
            % per-constraint methods of BrandtConstraintAnalysis).
            env          = con.envelope();
            [~, i_ac]    = min(abs(con.WS_range - TestOptimalPointContinuous.WS_BRANDT));
            TW_env_at_ac = env(i_ac);
            bca = BrandtConstraintAnalysis(ba, be);
            bca.analyze();
            ws_ac = TestOptimalPointContinuous.WS_BRANDT;
            TW_ref_at_ac = max([bca.max_mach(ws_ac), bca.cruise(ws_ac), ...
                bca.max_alt(ws_ac), bca.combat_turn_sub(ws_ac), ...
                bca.combat_turn_sup(ws_ac), bca.ps_500(ws_ac), ...
                bca.takeoff(ws_ac)]);

            fprintf(['\n    continuous: WS=%.4f TW=%.5f | grid argmin: WS=%.4f TW=%.5f | active: %s\n' ...
                     '    envelope @104.59: framework %.5f vs Brandt reference %.5f (%+.2f%%)\n' ...
                     '    actual F-16A margin over envelope: T/W %.4f vs %.5f (%+.1f%%)\n'], ...
                WS_opt, TW_opt, WS_grid, TW_grid, ...
                TestOptimalPointContinuous.joinNames(info.active_names), ...
                TW_env_at_ac, TW_ref_at_ac, ...
                100*(TW_env_at_ac - TW_ref_at_ac)/TW_ref_at_ac, ...
                TestOptimalPointContinuous.TW_BRANDT, TW_env_at_ac, ...
                100*(TestOptimalPointContinuous.TW_BRANDT - TW_env_at_ac)/TW_env_at_ac);

            tc.verifyGreaterThan(info.exitflag, 0);
            tc.verifyEqual(WS_opt, WS_grid, 'AbsTol', 0.1, ...
                'Continuous W/S must land within one 0.1-psf grid step of the fine-grid argmin.');
            tc.verifyLessThanOrEqual(TW_opt, TW_grid + 1e-9, ...
                'Continuous T/W must be no worse than the grid minimum (improvement property).');
            tc.verifyEqual(TW_env_at_ac, TW_ref_at_ac, 'RelTol', 0.02, ...
                'Envelope at W/S = 104.59 must match the live BrandtConstraintAnalysis reference within the documented 2% band.');
        end

    end

end

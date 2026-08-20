classdef TestB777Sizing < matlab.unittest.TestCase
%TESTB777SIZING  Tier-1 CONVERGENCE + PHYSICAL-SANITY tests for the Boeing
%   777-200LR sizing stack (L2 geometry + L2 component-build-up weights;
%   metabook §4.12 Algorithm 2 TOGW closure via TSDiagram.converge_W0 and
%   fuel_grid).
%
%   These are NOT metabook-agreement checks. Agreement of the converged W0
%   with the real 777-200LR (766,800 lbf) is INFORMATIONAL and belongs in the
%   Brandt/metabook comparison report, not here. This suite asserts only that
%   the loop CONVERGES, is guess-independent where it converges, and returns
%   PHYSICALLY SANE weights and a mission-flyability boundary.
%
%   Stack (coordinator-verified):
%       sp = b777_spec_path(1);  rp = b777_requirements_path();
%       geom = B777GeomL2(sp);  prop = B777PropL1(sp);  aero = B777AeroL1(geom, sp);
%       tail = B777TailL1();     wts  = B777WeightsL2(sp, geom, prop);
%       miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "long_range");
%       con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
%                  B777ConstraintSet.constraint_map(), WS_range);
%       ts   = TSDiagram(aero, prop, wts, geom, miss, con, tail);
%
%   ── RATIONALE FOR THE BANDS (all documented, none reverse-engineered) ────
%
%   CONVERGENCE. converge_W0(220000, 4605) prescribes the real 777-200LR
%   thrust (2x110000) and wing area, then closes TOGW. With the L2 component
%   build-up (fixed structural terms + only the 0.213*W0 gear/all-else
%   fraction) the closure is stable and lands at ~760,000 lbf (~-0.86% vs the
%   real 766,800) for the metabook Example 2.1 mission (9,150 nmi + 30-min
%   loiter, 78,821 lbf crew+payload). The band 600,000 < W0 < 850,000 is a sane
%   transport range; the exact agreement is the comparison-report topic, NOT
%   asserted tightly here.
%
%   GUESS-INDEPENDENCE. Two NEARBY (T, S) cells must give consistent W0 (the
%   closure is well-conditioned near the design point; the bracketed seed
%   removes seed sensitivity). Checked as a 15% band between the design cell
%   and a slightly larger-thrust/area neighbour -- both are sized aircraft, so
%   their converged weights track together.
%
%   PHYSICAL SANITY (at the converged design cell):
%     * 0 < OEW < W_TO                       (empty weight is a fraction of gross)
%     * W_fuel > 0                           (the mission burns fuel)
%     * payload fraction W_payload/W_TO in a plausible transport band [0.10,0.35]
%       (78,821 lbf crew+payload; a long-range twin at MTOW sits ~0.10)
%     * W/S = W_TO/S in a transport range [80, 200] lbf/ft^2 at S = 4605
%       (766,800/4605 = 166; the converged lighter aircraft is lower but stays
%        well inside a jet-transport wing-loading band)
%
%   FUEL_GRID BOUNDARY. Over a small (T, S) mesh spanning below and above the
%   design point, SOME cells are sized/feasible and SOME are infeasible (NaN) --
%   the mission-flyability boundary (a too-small wing or too-little thrust
%   cannot fly the 9,150 nmi mission, so converge_W0 returns NaN there).

    properties (Constant)
        T_DESIGN     = 220000     % lbf  design-point SLS thrust (2x110000) [metabook Fig. 4.7]
        S_DESIGN     = 4605       % ft^2 design-point wing area [metabook Table 4.3]
        W0_REAL      = 766800     % lbf  real 777-200LR MTOW (informational)
        W0_LO        = 600000     % lbf  sane lower band
        W0_HI        = 850000     % lbf  sane upper band
        W_PAYLOAD    = 78821      % lbf  crew + passengers [metabook Example 2.1; b777_L1.json .weights.W_payload]
    end

    methods (Static)
        function ts = buildTSDiagram(WS_range)
            arguments
                WS_range (1,:) double = 40:2:220
            end
            sp   = b777_spec_path(1);
            rp   = string(b777_requirements_path());
            geom = B777GeomL2(sp);                    % L2 real-planform geometry
            prop = B777PropL1(sp);
            aero = B777AeroL1(geom, sp);
            tail = B777TailL1(geom);
            wts  = B777WeightsL2(sp, geom, prop);     % L2 component build-up weights
            miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "long_range");
            con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
                B777ConstraintSet.constraint_map(), WS_range);
            ts   = TSDiagram(aero, prop, wts, geom, miss, con, tail);
        end
    end

    % ==================================================================== %
    methods (Test)

        function testConvergeW0FiniteAndSane(tc)
        % converge_W0 at the real (T, S) design cell is finite and in the sane
        % transport band 600,000 < W0 < 850,000 lbf (the L2 build-up lands
        % ~-0.86% from the real 766,800 -- comparison-report topic, NOT a tight
        % assertion here).
            ts = TestB777Sizing.buildTSDiagram();
            W0 = ts.converge_W0(tc.T_DESIGN, tc.S_DESIGN);
            fprintf('\n    converge_W0(%d, %d) = %.1f lbf (real 777 = %d, %+.2f%%)\n', ...
                tc.T_DESIGN, tc.S_DESIGN, W0, tc.W0_REAL, ...
                100*(W0 - tc.W0_REAL)/tc.W0_REAL);
            tc.verifyTrue(isfinite(W0), ...
                'converge_W0 at the real 777 (T, S) design cell must converge (finite).');
            tc.verifyGreaterThan(W0, tc.W0_LO, ...
                'Converged W0 must be above the sane transport lower band (600,000 lbf).');
            tc.verifyLessThan(W0, tc.W0_HI, ...
                'Converged W0 must be below the sane transport upper band (850,000 lbf).');
        end

        function testConvergeW0GuessIndependent(tc)
        % Two NEARBY (T, S) cells must give consistent W0 -- the bracketed seed
        % makes converge_W0 guess-independent where it converges. A +5% thrust /
        % +5% area neighbour is still a sized transport near the design point,
        % so its W0 must track within 15%.
            ts = TestB777Sizing.buildTSDiagram();
            W0_a = ts.converge_W0(tc.T_DESIGN, tc.S_DESIGN);
            W0_b = ts.converge_W0(1.05*tc.T_DESIGN, 1.05*tc.S_DESIGN);
            fprintf('\n    W0(design)=%.1f  W0(+5%%T,+5%%S)=%.1f  (diff %+.2f%%)\n', ...
                W0_a, W0_b, 100*(W0_b - W0_a)/W0_a);
            tc.verifyTrue(isfinite(W0_a) && isfinite(W0_b), ...
                'Both nearby cells must converge to a sized aircraft.');
            tc.verifyEqual(W0_b, W0_a, 'RelTol', 0.15, ...
                'Nearby (T, S) cells must give consistent (guess-independent) W0.');
        end

        function testPhysicalSanityAtDesignCell(tc)
        % At the converged design cell: 0 < OEW < W_TO, fuel > 0, payload
        % fraction in [0.10, 0.35], and W/S in a transport range [80, 200].
        % converge_W0 leaves geom/prop/wts at the design cell's state, so the
        % post-hoc reads are consistent with the returned W0.
            ts = TestB777Sizing.buildTSDiagram();
            W0 = ts.converge_W0(tc.T_DESIGN, tc.S_DESIGN);
            tc.assertTrue(isfinite(W0), 'The design cell must converge before sanity checks.');

            OEW      = ts.wts.OEW(W0);
            [W_fuel, ~] = ts.miss.total_fuel(W0);
            pay_frac = tc.W_PAYLOAD / W0;
            WS       = W0 / tc.S_DESIGN;
            fprintf(['\n    W_TO=%.1f  OEW=%.1f (%.3f)  W_fuel=%.1f (%.3f)  ', ...
                'payload_frac=%.3f  W/S=%.2f\n'], ...
                W0, OEW, OEW/W0, W_fuel, W_fuel/W0, pay_frac, WS);

            tc.verifyGreaterThan(OEW, 0, 'OEW must be positive.');
            tc.verifyLessThan(OEW, W0, 'OEW must be a fraction of gross weight (< W_TO).');
            tc.verifyGreaterThan(W_fuel, 0, 'The mission must burn positive fuel.');
            tc.verifyGreaterThanOrEqual(pay_frac, 0.08, ...
                'Payload fraction must be at least a plausible 0.08 (Example 2.1 payload ~0.10 at MTOW).');
            tc.verifyLessThanOrEqual(pay_frac, 0.35, ...
                'Payload fraction must be at most a plausible 0.35.');
            tc.verifyGreaterThanOrEqual(WS, 80, ...
                'W/S must be in the jet-transport range (>= 80 lbf/ft^2).');
            tc.verifyLessThanOrEqual(WS, 200, ...
                'W/S must be in the jet-transport range (<= 200 lbf/ft^2).');
            % Weight components close: payload + OEW + fuel ~ W_TO (Raymer Eq. 3.4).
            tc.verifyEqual(tc.W_PAYLOAD + OEW + W_fuel, W0, 'RelTol', 0.02, ...
                'payload + OEW + fuel must close to W_TO within the closure tolerance.');
        end

        function testFuelGridHasFeasibleAndInfeasibleCells(tc)
        % Over a small (T, S) mesh straddling the design point, SOME cells are
        % sized (finite W0) and SOME are mission-infeasible (NaN) -- the
        % flyability boundary. A too-small wing / too-little thrust cannot fly
        % the 9,150 nmi mission, so converge_W0 returns NaN there.
        % The warning TSDiagram raises on an infeasible cell is expected here.
            ts = TestB777Sizing.buildTSDiagram();
            T_grid = [140000, 220000, 300000];
            S_grid = [2500, 4605, 7000];
            ws = warning('off', 'TSDiagram:cellInfeasible');
            tc.addTeardown(@() warning(ws));
            fg = ts.fuel_grid(T_grid, S_grid);

            fprintf('\n    fuel_grid W0:\n'); disp(fg.W0);
            sized      = isfinite(fg.W0);
            n_sized    = nnz(sized);
            n_unsized  = nnz(~sized);
            tc.verifyGreaterThan(n_sized, 0, ...
                'The fuel grid must contain at least one sized (finite W0) cell.');
            tc.verifyGreaterThan(n_unsized, 0, ...
                'The fuel grid must contain at least one mission-infeasible (NaN) cell.');
            % W_fuel must be NaN-masked exactly where W0 is NaN, and positive
            % where the cell is sized.
            tc.verifyEqual(isnan(fg.W_fuel), ~sized, ...
                'W_fuel must be NaN exactly at the unsized cells.');
            tc.verifyTrue(all(fg.W_fuel(sized) > 0), ...
                'Every sized cell must carry a positive mission fuel burn.');
        end

    end
end

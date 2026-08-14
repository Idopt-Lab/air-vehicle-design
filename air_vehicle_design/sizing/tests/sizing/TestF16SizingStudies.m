classdef TestF16SizingStudies < matlab.unittest.TestCase
%TESTF16SIZINGSTUDIES  F-16-specific sizing-study tests for the FRAMEWORK
%   discipline stacks: f16_sizing_L1 / f16_sizing_L2 / f16_sizing_L3.
%
%   SCOPE -- CONVERGENCE + PHYSICAL SANITY ONLY, deliberately. The framework
%   L1/L2/L3 disciplines are NOT the Brandt disciplines: their agreement
%   with Brandt is measured by the informational comparison reports
%   (examples/F16A/sanity_checks/*_brandt_comparison.m) and by the
%   Brandt-stack rungs in TestSizingVsBrandt.m -- never asserted here with
%   tight bands (the earlier version of this file documented +32%/-37%
%   W_TO offsets at L1/L2 that are discipline-fidelity findings, not loop
%   bugs). What this file asserts:
%     - each study converges (result.converged true);
%     - the converged state is physically sane: 0 < W_OEW < W_TO,
%       W_fuel > 0, S_ref > 0, T_SL > 0, and every logged TOGW-closure
%       denominator in (0, 1) (denom = 1 - W_fuel/W_TO - W_OEW/W_TO must be
%       a positive proper fraction for a feasible, payload-carrying design);
%     - the converged answer does not depend on the initial guess
%       (RelTol 1e-3 -- looser than the loop's own tol_rel 1e-6 because two
%       runs re-solve the constraint optimum along different paths).
%   Brandt deltas are PRINTED informationally on every run.
%
%   RUNTIME CHOICE (documented): each study builds a full discipline stack
%   and runs a real mission per iteration (L2/L3 add a warm-started fmincon
%   design-point solve per iteration), so each study runs ONCE in
%   TestClassSetup and is shared across the test methods. The
%   guess-independence check re-runs at L1 ONLY (the cheapest rung -- no
%   per-iteration constraint re-solve); L2/L3 guess-independence is covered
%   structurally by TestSizingLoopL2.m's stub-level test.
%
%   Explicit guesses everywhere (28,000 lbf / 20,000 lbf -- deliberately off
%   any expected answer, so convergence is demonstrated rather than assumed;
%   no reliance on the study functions' own defaults).

    properties
        r1   % f16_sizing_L1 result (TestClassSetup)
        r2   % f16_sizing_L2 result (TestClassSetup)
        r3   % f16_sizing_L3 result (TestClassSetup)
    end

    methods (TestClassSetup)

        function runStudiesOnce(tc)
            [tc.r1, ~] = f16_sizing_L1(28000);
            [tc.r2, ~] = f16_sizing_L2(28000, 20000);
            [tc.r3, ~] = f16_sizing_L3(28000, 20000);
        end

    end

    methods (Static)

        function printBrandtDeltas(label, r)
        %PRINTBRANDTDELTAS  Informational only -- never asserted here (see
        %   class header). References: W_TO 31,377 [Brandt Wt!B3], T_SL
        %   23,770 [f16a_geometry.json engine.T_AB_SLS_lb], S_ref 300
        %   [wing.S_ref_ft2], W/S 104.59 / T/W 0.7576 [Brandt Size&Opt].
            fprintf(['\n    %s: W_TO=%.1f lb (Brandt 31377, %+.1f%%)  ' ...
                     'T_SL=%.1f lbf (23770, %+.1f%%)  S_ref=%.2f ft^2 (300, %+.1f%%)\n' ...
                     '        WS=%.2f psf (104.59, %+.1f%%)  TW=%.4f (0.7576, %+.1f%%)  ' ...
                     'W_OEW=%.1f  W_fuel=%.1f  n_iter=%d  converged=%d\n'], ...
                label, r.W_TO, 100*(r.W_TO-31377)/31377, ...
                r.T_SL, 100*(r.T_SL-23770)/23770, ...
                r.S_ref, 100*(r.S_ref-300)/300, ...
                r.WS, 100*(r.WS-104.59)/104.59, ...
                r.TW, 100*(r.TW-0.7576)/0.7576, ...
                r.W_OEW, r.W_fuel, r.n_iter, r.converged);
        end

        function verifyPhysicalSanity(tc, r)
        %VERIFYPHYSICALSANITY  The shared sanity assertions (class header).
            tc.verifyGreaterThan(r.W_OEW, 0, 'OEW must be positive.');
            tc.verifyLessThan(r.W_OEW, r.W_TO, 'OEW must be below W_TO.');
            tc.verifyGreaterThan(r.W_fuel, 0, 'Mission fuel must be positive.');
            tc.verifyGreaterThan(r.S_ref, 0, 'Wing area must be positive.');
            tc.verifyGreaterThan(r.T_SL, 0, 'Sea-level thrust must be positive.');
            d = [r.history.denom];
            tc.verifyTrue(all(d > 0 & d < 1), ...
                'Every logged TOGW denominator must lie in (0, 1).');
        end

    end

    methods (Test)

        % ── L1 ─────────────────────────────────────────────────────────── %

        function testL1ConvergesAndIsPhysical(tc)
            TestF16SizingStudies.printBrandtDeltas('f16_sizing_L1', tc.r1);
            tc.verifyTrue(tc.r1.converged, 'f16_sizing_L1 must converge.');
            TestF16SizingStudies.verifyPhysicalSanity(tc, tc.r1);
        end

        function testL1GuessIndependence(tc)
            % L1 only -- runtime choice documented in the class header.
            [ra, ~] = f16_sizing_L1(20000);
            [rb, ~] = f16_sizing_L1(40000);
            fprintf('\n    L1 from 20,000: W_TO=%.2f  from 40,000: W_TO=%.2f\n', ...
                ra.W_TO, rb.W_TO);
            tc.verifyTrue(ra.converged);
            tc.verifyTrue(rb.converged);
            tc.verifyEqual(ra.W_TO, rb.W_TO, 'RelTol', 1e-3, ...
                'Converged W_TO must be independent of the initial guess.');
        end

        % ── L2 ─────────────────────────────────────────────────────────── %

        function testL2ConvergesAndIsPhysical(tc)
            TestF16SizingStudies.printBrandtDeltas('f16_sizing_L2', tc.r2);
            tc.verifyTrue(tc.r2.converged, 'f16_sizing_L2 must converge.');
            TestF16SizingStudies.verifyPhysicalSanity(tc, tc.r2);
        end

        function testL2TailAreasPositive(tc)
            % SizingLoopL2 results carry S_ht/S_vt; the tail-sizing box must
            % produce positive areas at the converged wing.
            tc.verifyGreaterThan(tc.r2.S_ht, 0, 'S_ht must be positive.');
            tc.verifyGreaterThan(tc.r2.S_vt, 0, 'S_vt must be positive.');
        end

        % ── L3 (runs on SizingLoopL2; propulsion computed by F16PropL2 --
        %       no L3 propulsion tier exists, locked decision 2026-07-25) ── %

        function testL3ConvergesAndIsPhysical(tc)
            TestF16SizingStudies.printBrandtDeltas('f16_sizing_L3', tc.r3);
            tc.verifyTrue(tc.r3.converged, 'f16_sizing_L3 must converge.');
            TestF16SizingStudies.verifyPhysicalSanity(tc, tc.r3);
        end

        function testL3TailAreasPositive(tc)
            tc.verifyGreaterThan(tc.r3.S_ht, 0, 'S_ht must be positive.');
            tc.verifyGreaterThan(tc.r3.S_vt, 0, 'S_vt must be positive.');
        end

    end

end

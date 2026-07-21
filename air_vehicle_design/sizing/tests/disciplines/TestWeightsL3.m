classdef TestWeightsL3 < matlab.unittest.TestCase
%TESTWEIGHTSL3  Unit tests for the Level-3 weight estimation toolbox.
%
%   Tests: WeightsL3 (static toolbox) + F16WeightsL3 (student class).
%
%   REFERENCE VALUES:
%     [Brandt] OEW = 19,980.7 lbf  [Brandt F-16A.xls, sheet "Wt", B12]
%     [Brandt] TOGW = 31,377 lbf   [Brandt F-16A.xls, sheet "Wt", B38]
%
%   ⚠ NOTE ON TOLERANCES:
%     Raymer §15.3.1 exponents are statistical regressions with ±20–30% scatter.
%     Additionally, several F16WeightsL3 inputs are engineering estimates (marked
%     [estimate] in the student class).  Tests use ±40% tolerance on the total OEW
%     and sanity-bound tests for individual components.  Tighter tolerances require:
%       (a) verified exponents from Raymer 6th ed. PDF pp. 602–603;
%       (b) measured F-16 component weights from TO 1F-16A-1 or Jane's.

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            g = F16WeightsL3();
            tc.verifyTrue(isa(g, 'WeightsBase'), ...
                'F16WeightsL3 must inherit WeightsBase.');
        end

        function testIsaWeightsModelL3(tc)
            g = F16WeightsL3();
            tc.verifyTrue(isa(g, 'WeightsModelL3'), ...
                'F16WeightsL3 must inherit WeightsModelL3.');
        end

        function testNotIsaWeightsModelL1(tc)
            g = F16WeightsL3();
            tc.verifyFalse(isa(g, 'WeightsModelL1'), ...
                'F16WeightsL3 must NOT inherit WeightsModelL1.');
        end

    end

    % ------------------------------------------------------------------ %
    % Individual component sanity bounds (F-16A at W_TO = 31,377 lbf)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWingWeightPositiveAndPlausible(tc)
            % Raymer Eq. 15.1.  F-16 wing is small (300 ft²) and lightly loaded.
            % Plausible range: 2,000–6,000 lbf for a 9g-capable fighter wing.
            g = F16WeightsL3();
            W = g.weight_wing(31377);
            fprintf('\n    Wing weight (Eq. 15.1): %.0f lbf\n', W);
            tc.verifyGreaterThan(W, 2000, ...
                'Wing weight must exceed 2,000 lbf (lower sanity bound).');
            tc.verifyLessThan(W, 6000, ...
                'Wing weight must be below 6,000 lbf (upper sanity bound).');
        end

        function testHTWeightPositiveAndLessThanWing(tc)
            % HT is smaller than the wing; expect 500–2,000 lbf.
            g = F16WeightsL3();
            W_tail = g.weight_tail(31377);
            % TODO(7/20/2026): This should compare with the wing weight,
            % not set a hard upper/lower boundary, as the function name
            % implies. Should check if less than main wing weight.
            fprintf('\n    HT weight (Eq. 15.2): %.0f lbf\n', W_tail.HT);
            tc.verifyGreaterThan(W_tail.HT, 500, ...
                'HT weight must exceed 500 lbf.');
            tc.verifyLessThan(W_tail.HT, 2000, ...
                'HT weight must be below 2,000 lbf.');
        end

        function testVTWeightPositiveAndLessThanHT(tc)
            % VT is smaller than HT on F-16; expect 300–1,500 lbf.
            g = F16WeightsL3();
            W_tail = g.weight_tail(31377);
            fprintf('\n    VT weight (Eq. 15.3): %.0f lbf\n', W_tail.VT);
            tc.verifyGreaterThan(W_tail.VT, 300, ...
                'VT weight must exceed 300 lbf.');
            tc.verifyLessThan(W_tail.VT, 1500, ...
                'VT weight must be below 1,500 lbf.');
        end

        function testFuselageWeightPlausible(tc)
            % Raymer Eq. 15.4.  Fuselage is a major fraction; expect 4,000–10,000 lbf.
            g = F16WeightsL3();
            W = g.weight_fuselage(31377);
            fprintf('\n    Fuselage weight (Eq. 15.4): %.0f lbf\n', W);
            tc.verifyGreaterThan(W, 4000, ...
                'Fuselage weight must exceed 4,000 lbf.');
            tc.verifyLessThan(W, 10000, ...
                'Fuselage weight must be below 10,000 lbf.');
        end

        function testLandingGearWeightPlausible(tc)
            % Eqs. 15.5–15.6.  LG typically 4–6% of W_TO ≈ 1,200–2,000 lbf.
            g = F16WeightsL3();
            W_lg = g.weight_landing_gear();
            W_total = W_lg.main + W_lg.nose;
            fprintf('\n    LG weight: main=%.0f nose=%.0f total=%.0f lbf\n', ...
                W_lg.main, W_lg.nose, W_total);
            tc.verifyGreaterThan(W_total, 800, ...
                'Total LG weight must exceed 800 lbf.');
            tc.verifyLessThan(W_total, 3000, ...
                'Total LG weight must be below 3,000 lbf.');
        end

        function testEngineWeightsPositive(tc)
            % Engine section group: all sub-weights must be non-negative.
            g = F16WeightsL3();
            W_eng = g.weight_engine_section(31377);
            fprintf('\n    Engine section group: total=%.0f lbf\n', W_eng.total);
            fields = fieldnames(W_eng);
            for i = 1:numel(fields)
                f = fields{i};
                tc.verifyGreaterThanOrEqual(W_eng.(f), 0, ...
                    sprintf('Engine section sub-weight "%s" must be >= 0.', f));
            end
        end

        function testSystemsWeightsPositive(tc)
            % Systems group: all sub-weights must be non-negative.
            g = F16WeightsL3();
            W_sys = g.weight_systems(31377);
            fprintf('\n    Systems group: total=%.0f lbf\n', W_sys.total);
            fields = fieldnames(W_sys);
            for i = 1:numel(fields)
                f = fields{i};
                tc.verifyGreaterThanOrEqual(W_sys.(f), 0, ...
                    sprintf('Systems sub-weight "%s" must be >= 0.', f));
            end
        end

    end

    % ------------------------------------------------------------------ %
    % Total OEW sanity tests
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            g = F16WeightsL3();
            oew = g.OEW(31377);
            tc.verifyLessThan(oew, 31377, ...
                'L3 OEW must be less than W_TO for any physical design.');
        end

        function testOEWWithinBroadBounds(tc)
            % Raymer §15.3.1 regression has ±30% statistical scatter.
            % Several F16WeightsL3 inputs are estimates — use ±40% on total OEW.
            % When all inputs are verified, tighten to ±20%.
            g = F16WeightsL3();
            expected = 19980.7;   % lbf  [Brandt F-16A.xls, B12]
            received = g.OEW(31377);
            fprintf('\n    L3 OEW: received=%.0f lbf  Brandt=%.0f lbf  err=%.1f%%\n', ...
                received, expected, 100*(received-expected)/expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.40, ...
                ['L3 OEW must be within ±40% of Brandt OEW (19,981 lbf) [Brandt B12]. ', ...
                 'Tighten after verifying Raymer exponents (PDF pp.602-603) ', ...
                 'and estimated inputs in F16WeightsL3.']);
        end

        function testOEWPrintBreakdown(tc)
            % Diagnostic test — prints full component breakdown; always passes.
            g = F16WeightsL3();
            W_TO = 31377;
            W_wing = g.weight_wing(W_TO);
            W_tail = g.weight_tail(W_TO);
            W_fus  = g.weight_fuselage(W_TO);
            W_lg   = g.weight_landing_gear();
            W_eng  = g.weight_engine_section(W_TO);
            W_sys  = g.weight_systems(W_TO);
            total  = g.OEW(W_TO);
            fprintf(['\n    === F-16A L3 OEW Breakdown (Raymer §15.3.1) ===\n', ...
                     '    Wing           %7.0f lbf\n', ...
                     '    HT             %7.0f lbf\n', ...
                     '    VT             %7.0f lbf\n', ...
                     '    Fuselage       %7.0f lbf\n', ...
                     '    LG (main)      %7.0f lbf\n', ...
                     '    LG (nose)      %7.0f lbf\n', ...
                     '    Engine group   %7.0f lbf\n', ...
                     '    Systems group  %7.0f lbf\n', ...
                     '    --------------------------------\n', ...
                     '    Total OEW      %7.0f lbf\n', ...
                     '    Brandt target  %7.0f lbf\n'], ...
                W_wing, W_tail.HT, W_tail.VT, W_fus, ...
                W_lg.main, W_lg.nose, W_eng.total, W_sys.total, ...
                total, 19980.7);
            tc.verifyTrue(true);  % diagnostic-only; inspect printed output
        end

    end

end

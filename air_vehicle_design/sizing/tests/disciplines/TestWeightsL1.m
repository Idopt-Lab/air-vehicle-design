classdef TestWeightsL1 < matlab.unittest.TestCase
%TESTWEIGHTSL1  Unit tests for the Level-1 weight estimation toolbox.
%
%   Tests: WeightsL1 (static toolbox) + F16WeightsL1 (student class).
%
%   TWO L1 METHODS tested here:
%     (1) Raymer Table 3.1 power law — central estimate (We/Wto = Kvs×A×W_TO^C)
%     (2) Roskam Eq. 2.16 log-log   — minimum achievable W_E lower bound
%
%   REFERENCE VALUES:
%     [Brandt]  OEW = 19,148 lbf  [Brandt F-16A.xls, sheet "Wt", B12]
%     [Brandt]  TOGW = 31,377 lbf   [Brandt F-16A.xls, sheet "Wt", B38]
%     [Raymer Table 3.1] jet_fighter: Kvs=1.00 (fixed sweep), A=2.34, C=-0.13.
%       [AE481 Metabook Table 3.1; verify against Raymer 6th ed. Table 3.1]
%       Predicted: We/Wto = 1.00 × 2.34 × 31377^(−0.13) ≈ 0.609; OEW ≈ 19,108 lbf.
%       Error vs Brandt: ≈ −2.5% → within the ±8% statistical scatter.
%     [Roskam Table 2.15] jet_fighter: A=0.5091, B=0.9505.
%       Minimum bound at W_TO=31,377: W_E_min ≈ 15,660 lbf.
%       Interpretation: historical lower efficiency frontier; actual OEW ≥ W_E_min.

    properties (Constant)
        TOL_L1  = 0.08    % 8% relative tolerance for L1 Raymer regression
    end

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            g = F16WeightsL1();
            tc.verifyTrue(isa(g, 'WeightsBase'), ...
                'F16WeightsL1 must inherit WeightsBase (Tier-1 contract).');
        end

        function testIsaWeightsModelL1(tc)
            g = F16WeightsL1();
            tc.verifyTrue(isa(g, 'WeightsModelL1'), ...
                'F16WeightsL1 must inherit WeightsModelL1 (Tier-2a contract).');
        end

        function testNotIsaWeightsModelL2(tc)
            g = F16WeightsL1();
            tc.verifyFalse(isa(g, 'WeightsModelL2'), ...
                'F16WeightsL1 must NOT inherit WeightsModelL2.');
        end

    end

    % ------------------------------------------------------------------ %
    % Low-level: Raymer Table 3.1 power-law formula
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWeFractionIsLessThanOne(tc)
            % Sanity: no aircraft can have empty weight >= takeoff weight.
            frac = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 31377);
            tc.verifyLessThan(frac, 1.0, ...
                'We/Wto fraction must be < 1 for all physical designs.');
        end

        function testWeFractionDecreasesWithWTO(tc)
            % For C<0, fraction falls as W_TO grows (heavier aircraft are proportionally lighter).
            frac_small = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 10000);
            frac_large = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 50000);
            tc.verifyGreaterThan(frac_small, frac_large, ...
                'Jet-fighter fraction must decrease with W_TO (C = -0.13 < 0).');
        end

    end

    % ------------------------------------------------------------------ %
    % Low-level: Roskam Eq. 2.16 log-log formula
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWeRoskamLowerThanRaymerL1(tc)
            % Roskam gives minimum bound; Raymer Table 3.1 gives a higher central estimate.
            % Both use W_TO=31377; Roskam → ~15,660 lbf; Raymer → ~19,108 lbf.
            W_roskam = WeightsL1.We_roskam(0.5091, 0.9505, 31377);
            W_raymer = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 31377) * 31377;
            fprintf('\n    L1 Roskam min W_E=%.0f lbf  Raymer OEW=%.0f lbf\n', ...
                W_roskam, W_raymer);
            tc.verifyLessThan(W_roskam, W_raymer, ...
                'Roskam L1 min W_E must be below Raymer L1 central estimate.');
        end

    end

    % ------------------------------------------------------------------ %
    % High-level: F-16A student class (Raymer power law)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            g = F16WeightsL1();
            oew = g.OEW(31377);
            tc.verifyLessThan(oew, 31377, ...
                'OEW must be less than W_TO for any physical design.');
        end

        function testOEWGreaterThanZero(tc)
            g = F16WeightsL1();
            oew = g.OEW(31377);
            tc.verifyGreaterThan(oew, 0, ...
                'OEW must be positive.');
        end

        function testOEWWithinBrandsValue(tc)
            % Raymer Table 3.1 L1 prediction vs Brandt OEW reference.
            % Predicted ≈ 19,108 lbf; target 19,148 lbf; err ≈ -0.2% → within ±8%.
            g = F16WeightsL1();
            expected = 19148;  % lbf  [Brandt F-16A.xls, sheet "Wt", B12]
            received = g.OEW(31377);
            fprintf('\n    OEW L1 (Raymer): received=%.1f lbf  Brandt=%.1f lbf  err=%.1f%%\n', ...
                received, expected, 100*(received-expected)/expected);
            tc.verifyEqual(received, expected, 'RelTol', tc.TOL_L1, ...
                'L1 OEW must be within ±8% of Brandt F-16A OEW (19,148 lbf) [Brandt B12].');
        end

        function testWeFractionMatchesOEW(tc)
            % Consistency: frac × W_TO == OEW.
            g = F16WeightsL1();
            W_TO     = 31377;
            expected = g.compute_We_fraction(W_TO) * W_TO;
            received = g.OEW(W_TO);
            tc.verifyEqual(received, expected, 'AbsTol', 0.1, ...
                'OEW must equal compute_We_fraction × W_TO.');
        end

        function testComputeWeFractionWithExplicitCategory(tc)
            % compute_We_fraction(W_TO, category) overrides obj.aircraft_category.
            g = F16WeightsL1();
            W_TO = 31377;
            frac_fighter  = g.compute_We_fraction(W_TO, 'jet_fighter');
            frac_transport = g.compute_We_fraction(W_TO, 'jet_transport');
            % Transport has lower A and less-negative C → different fraction.
            tc.verifyNotEqual(frac_fighter, frac_transport, ...
                'Explicit aircraft_category argument must change the fraction.');
        end

        function testRoskamMinBoundBelowBrandt(tc)
            % Roskam lower bound must be below the actual F-16 OEW.
            g = F16WeightsL1();
            expected_brandt = 19148;  % lbf  [Brandt B12]
            W_E_min = g.compute_We_roskam(31377);
            fprintf('\n    L1 Roskam min W_E=%.0f lbf  Brandt OEW=%.0f lbf\n', ...
                W_E_min, expected_brandt);
            tc.verifyLessThan(W_E_min, expected_brandt, ...
                'Roskam min W_E must be below Brandt actual OEW (minimum bound) [Roskam Eq. 2.16].');
        end

        function testJetFighterCategorySetCorrectly(tc)
            g = F16WeightsL1();
            tc.verifyEqual(lower(g.aircraft_category), 'jet_fighter', ...
                'F16WeightsL1 aircraft_category must be "jet_fighter".');
        end

    end

    % ------------------------------------------------------------------ %
    % Lookup tables: Raymer Table 3.1 coefficients
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLookupJetFighterCoeffs(tc)
            c = WeightsL1.lookup_coeffs('jet_fighter');
            tc.verifyEqual(c.A,   2.34,  'AbsTol', 1e-6, ...
                'jet_fighter A must be 2.34 [Raymer Table 3.1].');
            tc.verifyEqual(c.C,  -0.13,  'AbsTol', 1e-6, ...
                'jet_fighter C must be -0.13 [Raymer Table 3.1].');
            tc.verifyEqual(c.Kvs, 1.00,  'AbsTol', 1e-6, ...
                'jet_fighter Kvs must be 1.00 (fixed sweep) [Raymer Table 3.1].');
        end

        function testLookupUnknownCategoryErrors(tc)
            tc.verifyError(@() WeightsL1.lookup_coeffs('spaceship'), ...
                'WeightsL1:UnknownCategory', ...
                'Unknown category must throw WeightsL1:UnknownCategory.');
        end

    end

    % ------------------------------------------------------------------ %
    % Lookup tables: Roskam Table 2.15 coefficients
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLookupRoskamJetFighterCoeffs(tc)
            c = WeightsL1.lookup_roskam_coeffs('jet_fighter');
            tc.verifyEqual(c.A, 0.5091, 'AbsTol', 1e-6, ...
                'jet_fighter Roskam A must be 0.5091 [Roskam Table 2.15].');
            tc.verifyEqual(c.B, 0.9505, 'AbsTol', 1e-6, ...
                'jet_fighter Roskam B must be 0.9505 [Roskam Table 2.15].');
        end

        function testLookupRoskamUnknownCategoryErrors(tc)
            tc.verifyError(@() WeightsL1.lookup_roskam_coeffs('spaceship'), ...
                'WeightsL1:UnknownRoskamCategory', ...
                'Unknown Roskam category must throw WeightsL1:UnknownRoskamCategory.');
        end

    end

end

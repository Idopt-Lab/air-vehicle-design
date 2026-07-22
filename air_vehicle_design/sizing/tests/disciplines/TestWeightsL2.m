classdef TestWeightsL2 < matlab.unittest.TestCase
%TESTWEIGHTSL2  Unit tests for the Level-2 weight estimation toolbox.
%
%   Tests: WeightsL2 (static toolbox) + F16WeightsL2 (student class).
%
%   METHOD: Raymer Table 15.2 component/surface-density buildup.
%     OEW = W_wing + W_HT + W_VT + W_fus + W_LG
%           + W_installed_engine + W_all_else_empty
%
%   REFERENCE VALUES:
%     [Brandt] OEW = 19,148 lbf  [Brandt F-16A.xls, sheet "Wt", B12]
%     [Raymer Table 15.2] Fighter unit weights: wing 9, HT 4, VT 5.3, fus 4.8 lbf/ft²
%     [AE481 metabook §7] LG fraction: 0.033 × W_TO for non-Navy fighters
%
%   NOTE ON W_installed_engine AND W_all_else_empty:
%     These two components are set directly by F16WeightsL2 (student-specified
%     estimates), not computed from Table 15.2.  Their values are engineering
%     estimates — see F16WeightsL2 property comments.  The structural component
%     tests (wing, tail, fus, LG) are fully determined by Table 15.2 formulas
%     and are the primary L2 verification targets.
%
%   NOTE ON ROSKAM TESTS:
%     The Roskam statistical method (minimum-bound regression) has moved to
%     WeightsL1 (compute_We_roskam / We_roskam).  See TestWeightsL1 for those tests.

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            g = F16WeightsL2();
            tc.verifyTrue(isa(g, 'WeightsBase'), ...
                'F16WeightsL2 must inherit WeightsBase (Tier-1 contract).');
        end

        function testIsaWeightsModelL2(tc)
            g = F16WeightsL2();
            tc.verifyTrue(isa(g, 'WeightsModelL2'), ...
                'F16WeightsL2 must inherit WeightsModelL2 (Tier-2a contract).');
        end

        function testNotIsaWeightsModelL1(tc)
            g = F16WeightsL2();
            tc.verifyFalse(isa(g, 'WeightsModelL1'), ...
                'F16WeightsL2 must NOT inherit WeightsModelL1.');
        end

    end

    % ------------------------------------------------------------------ %
    % High-level: F-16A student class OEW
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            g = F16WeightsL2();
            oew = g.OEW(31377);
            tc.verifyLessThan(oew, 31377, ...
                'L2 OEW must be less than W_TO for any physical design.');
        end

        function testOEWAboveSanityMinimum(tc)
            % No real jet fighter has OEW/TOGW < 30%.
            g = F16WeightsL2();
            oew = g.OEW(31377);
            expected_min = 0.30 * 31377;  % 30% lower bound (engineering sanity)
            tc.verifyGreaterThan(oew, expected_min, ...
                'L2 OEW must exceed 30% of W_TO (sanity lower bound for jet fighters).');
        end

        function testOEWWithinBrandtValue(tc)
            % L2 component-buildup OEW vs Brandt actual F-16 OEW.
            % Structural components from Raymer Table 15.2; engine and all-else are
            % estimates (see F16WeightsL2 properties).  Use ±20% tolerance.
            g = F16WeightsL2();
            expected = 19148;  % lbf  [Brandt B12]
            oew = g.OEW(31377);
            fprintf('\n    L2 component OEW=%.0f lbf  Brandt=%.0f lbf  err=%.1f%%\n', ...
                oew, expected, 100*(oew-expected)/expected);
            tc.verifyEqual(oew, expected, 'RelTol', 0.20, ...
                'L2 OEW must be within ±20% of Brandt F-16A OEW (19,148 lbf) [Brandt B12].');
        end

        function testJetFighterCategorySetCorrectly(tc)
            g = F16WeightsL2();
            tc.verifyEqual(lower(g.aircraft_category), 'jet_fighter', ...
                'F16WeightsL2 aircraft_category must be "jet_fighter".');
        end

    end

    % ------------------------------------------------------------------ %
    % Unit weight lookups
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWingUnitWeightJetFighter(tc)
            rho = WeightsL2.wing_unit_weight('jet_fighter');
            tc.verifyEqual(rho, 9.0, 'AbsTol', 1e-6, ...
                'jet_fighter wing unit weight must be 9.0 lbf/ft² [Raymer Table 15.2].');
        end

        function testLookupUnknownCategoryErrors(tc)
            tc.verifyError(@() WeightsL2.wing_unit_weight('spaceship'), ...
                'WeightsL2:UnknownCategory', ...
                'Unknown category must throw WeightsL2:UnknownCategory.');
        end

    end

end

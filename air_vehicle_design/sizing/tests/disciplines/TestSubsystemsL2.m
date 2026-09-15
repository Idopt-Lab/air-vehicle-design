classdef TestSubsystemsL2 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL2  Unit tests for SubsystemsL2, SubsystemsModelL2, and F16SubsystemsL2.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green, with ONE deliberate
%   exception (testTODO_BatteryVolumetricEnergyDensityNotInRepo, clearly
%   labeled below). Companion Tier-2 report:
%   examples/F16A/sanity_checks/subsystems_brandt_comparison.m (informational, NOT here).
%
%   Every "expected" value below is HAND-COMPUTED from the cited formula
%   with independently-chosen scalars (deliberately NOT the F-16's own
%   geometry numbers, except in the small number of explicit end-to-end
%   wiring tests that construct real F16GeomL2/F16WeightsL2/F16SubsystemsL2
%   objects to check the DI plumbing and the optimization-ready property
%   design, not to re-derive a formula).
%
%   No SubsystemsL2 static takes a design object any more, so every toolbox
%   test below calls with LITERALS. A test that needs a design object's own
%   wiring builds a real F16SubsystemsL2 instead of a stand-in struct.
%
%   Sources: fuselage-internal raw volume [Raymer 6th ed. Eq. 7.14]; wing-
%   internal fuel volume [Roskam, Airplane Design Part II, Ch.6, Eq. 6.2/6.3,
%   p.153]; fuel-tank packaging factor [Nicolai & Carichner, Ch.8, p.210];
%   fuel density [Nicolai & Carichner Table 8.6, p.210]; avionics weight
%   fraction [Raymer Table 11.6, p.375] with the Raymer range-average
%   avionics density (30 to 45 lb/ft^3 -> 37.5).

    methods (TestClassSetup)

        function printFidelityBanner(~)
            fprintf('\n============================================================\n');
            fprintf(' FIDELITY LEVEL 2 -- Subsystems\n');
            fprintf('============================================================\n');
        end

    end

    methods (Test)

        % ================================================================== %
        % LOW-LEVEL statics -- hand-picked scalars, independent of any real
        % F-16 geometry number.
        % ================================================================== %

        function testComputeRaymerFuselageVolumeHandComputed(tc)
        % [Raymer 6th ed. Eq. 7.14]  V = 3.4*(A_top*A_side)/(4*L).
        %   A_top=100, A_side=50, L=20 -> 3.4*5000/80 = 212.5 ft^3 exactly.
            received = SubsystemsL2.compute_fuselage_volume_raymer(100, 50, 20);
            expected = 212.5;
            fprintf('  [L2] testComputeRaymerFuselageVolumeHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testComputeRaymerFuselageVolumeGuardsPositivity(tc)
            expectedErrId = 'MATLAB:validators:mustBePositive';
            try
                SubsystemsL2.compute_fuselage_volume_raymer(0, 50, 20);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testComputeRaymerFuselageVolumeGuardsPositivity (A_top=0): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.compute_fuselage_volume_raymer(0, 50, 20), ...
                'MATLAB:validators:mustBePositive');

            expectedErrId = 'MATLAB:validators:mustBePositive';
            try
                SubsystemsL2.compute_fuselage_volume_raymer(100, 50, 0);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testComputeRaymerFuselageVolumeGuardsPositivity (L=0): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.compute_fuselage_volume_raymer(100, 50, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        function testComputeEnvelopeProjectedAreasHandComputed(tc)
        % (pi/4)*L*W and (pi/4)*L*H -- elliptical-footprint identity.
        %   L=10, W=4, H=2 -> A_top = 10*pi, A_side = 5*pi.
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas(10, 4, 2);
            expected_Atop = 10*pi;
            expected_Aside = 5*pi;
            fprintf('  [L2] testComputeEnvelopeProjectedAreasHandComputed: A_top expected=%.6g, received=%.6g\n', expected_Atop, A_top);
            tc.verifyEqual(A_top,  expected_Atop, 'AbsTol', 1e-9);
            fprintf('  [L2] testComputeEnvelopeProjectedAreasHandComputed: A_side expected=%.6g, received=%.6g\n', expected_Aside, A_side);
            tc.verifyEqual(A_side, expected_Aside,  'AbsTol', 1e-9);
        end

        function testComputeWingFuelVolumeUniformTc(tc)
        % [Roskam Eq. 6.2/6.3], tau_w = tc_t/tc_r. Uniform-tc case (tau_w=1):
        %   S=100, b=20, tc_r=tc_t=0.05, lambda=0.25.
        %   0.54*(100^2/20)*0.05 = 0.54*500*0.05 = 13.5
        %   fraction = (1+0.25+0.25^2)/(1.25)^2 = 1.3125/1.5625 = 0.84 exactly
        %   V = 13.5*0.84 = 11.34 ft^3 exactly.
            received = SubsystemsL2.compute_wing_fuel_volume_roskam(100, 20, 0.05, 0.05, 0.25);
            expected = 11.34;
            fprintf('  [L2] testComputeWingFuelVolumeUniformTc: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testComputeWingFuelVolumeVariableTc(tc)
        % Non-uniform tc case, tau_w = tc_t/tc_r = 0.02/0.08 = 0.25:
        %   S=150, b=25, tc_r=0.08, tc_t=0.02, lambda=0.4.
        %   0.54*(150^2/25)*0.08 = 0.54*900*0.08 = 38.88
        %   sqrt(tau_w)=0.5; num = 1 + 0.4*0.5 + 0.4^2*0.25 = 1+0.2+0.04 = 1.24
        %   den = 1.4^2 = 1.96;  fraction = 1.24/1.96 = 31/49
        %   V = 38.88*31/49 = 1205.28/49 = 24.5975510204 ft^3.
            expected = 1205.28/49;
            received = SubsystemsL2.compute_wing_fuel_volume_roskam(150, 25, 0.08, 0.02, 0.4);
            fprintf('  [L2] testComputeWingFuelVolumeVariableTc: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testComputeWingFuelVolumeTauConventionIsTipOverRoot(tc)
        % REGRESSION GUARD for the tau_w convention warning: Eq. 6.3 defines
        % tau_w = (t/c)_tip/(t/c)_root, the OPPOSITE of Roskam's own Eq. 12.1
        % tau = root/tip. Swapping tc_r and tc_t must NOT give the same
        % answer (it would, if the code had silently "fixed" the convention
        % to match Eq. 12.1's root/tip).
        %   Swapped case: S=150, b=25, tc_r=0.02, tc_t=0.08, lambda=0.4.
        %   tau_w = 0.08/0.02 = 4; sqrt(tau_w)=2
        %   0.54*(150^2/25)*0.02 = 0.54*900*0.02 = 9.72
        %   num = 1 + 0.4*2 + 0.16*4 = 1+0.8+0.64 = 2.44; den=1.96
        %   fraction = 2.44/1.96 = 61/49
        %   V = 9.72*61/49 = 592.92/49 = (243/25)*(61/49) = 14823/1225 = 12.1004081633 ft^3.
            expected_swapped = 14823/1225;
            received_swapped = SubsystemsL2.compute_wing_fuel_volume_roskam(150, 25, 0.02, 0.08, 0.4);
            fprintf('  [L2] testComputeWingFuelVolumeTauConventionIsTipOverRoot: expected_swapped=%.6g, received_swapped=%.6g\n', expected_swapped, received_swapped);
            tc.verifyEqual(received_swapped, expected_swapped, 'AbsTol', 1e-6);

            % The un-swapped (root=0.08, tip=0.02) case from the test above:
            received_unswapped = SubsystemsL2.compute_wing_fuel_volume_roskam(150, 25, 0.08, 0.02, 0.4);
            fprintf('  [L2] testComputeWingFuelVolumeTauConventionIsTipOverRoot: swapped=%.6g must differ from unswapped=%.6g\n', received_swapped, received_unswapped);
            tc.verifyNotEqual(received_swapped, received_unswapped, ...
                ['Swapping tc_r/tc_t must change the result (tau_w = tip/root is direction-' ...
                 'sensitive) -- if these matched, the code would have silently "fixed" Eq. 6.3''s ' ...
                 'convention to Roskam Eq. 12.1''s opposite root/tip definition.']);
        end

        function testComputeWingFuelVolumeGuardsPositivity(tc)
            expectedErrId = 'MATLAB:validators:mustBePositive';
            try
                SubsystemsL2.compute_wing_fuel_volume_roskam(0, 20, 0.05, 0.05, 0.25);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testComputeWingFuelVolumeGuardsPositivity (S=0): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.compute_wing_fuel_volume_roskam(0, 20, 0.05, 0.05, 0.25), ...
                'MATLAB:validators:mustBePositive');

            expectedErrId = 'MATLAB:validators:mustBePositive';
            try
                SubsystemsL2.compute_wing_fuel_volume_roskam(100, 20, 0, 0.05, 0.25);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testComputeWingFuelVolumeGuardsPositivity (tc_r=0): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.compute_wing_fuel_volume_roskam(100, 20, 0, 0.05, 0.25), ...
                'MATLAB:validators:mustBePositive');
        end

        function testLookupPackagingFactorAllFiveRows(tc)
        % [Nicolai & Carichner, p.210, unnumbered "Fuel Tank Packaging
        % Factors" table]. Full 5-row table.
            received1 = SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — shallow fuselage');
            expected1 = 0.80;
            fprintf('  [L2] testLookupPackagingFactorAllFiveRows: [shallow fuselage] expected=%.6g, received=%.6g\n', expected1, received1);
            tc.verifyEqual(received1, expected1, 'AbsTol', 1e-9);

            received2 = SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — deep fuselage');
            expected2 = 0.85;
            fprintf('  [L2] testLookupPackagingFactorAllFiveRows: [deep fuselage] expected=%.6g, received=%.6g\n', expected2, received2);
            tc.verifyEqual(received2, expected2, 'AbsTol', 1e-9);

            received3 = SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — wing');
            expected3 = 0.75;
            fprintf('  [L2] testLookupPackagingFactorAllFiveRows: [integral wing] expected=%.6g, received=%.6g\n', expected3, received3);
            tc.verifyEqual(received3, expected3, 'AbsTol', 1e-9);

            received4 = SubsystemsL2.lookup_packaging_factor_nicolai('Bladder tank — fuselage');
            expected4 = 0.75;
            fprintf('  [L2] testLookupPackagingFactorAllFiveRows: [bladder fuselage] expected=%.6g, received=%.6g\n', expected4, received4);
            tc.verifyEqual(received4, expected4, 'AbsTol', 1e-9);

            received5 = SubsystemsL2.lookup_packaging_factor_nicolai('Bladder tank — wing');
            expected5 = 0.65;
            fprintf('  [L2] testLookupPackagingFactorAllFiveRows: [bladder wing] expected=%.6g, received=%.6g\n', expected5, received5);
            tc.verifyEqual(received5, expected5, 'AbsTol', 1e-9);
        end

        function testLookupPackagingFactorUnknownCategoryErrors(tc)
            expectedErrId = 'SubsystemsL2:unknownPackagingCategory';
            try
                SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — nose');
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testLookupPackagingFactorUnknownCategoryErrors: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — nose'), ...
                'SubsystemsL2:unknownPackagingCategory');
        end

        % ================================================================== %
        % COMPOSITION of the low-level statics -- literals, no design object.
        % ================================================================== %

        function testFuselageRawVolumeComposesTheTwoStatics(tc)
        % Composition of the two low-level statics above:
        %   L=10, W=4, H=2 -> A_top=10*pi, A_side=5*pi
        %   V = 3.4*(10*pi*5*pi)/(4*10) = 3.4*50*pi^2/40 = 4.25*pi^2 ft^3.
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas(10, 4, 2);
            received = SubsystemsL2.compute_fuselage_volume_raymer(A_top, A_side, 10);
            expected = 4.25*pi^2;
            fprintf('  [L2] testFuselageRawVolumeComposesTheTwoStatics: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuselageUsableFuelVolumeAppliesPackagingFactor(tc)
        % raw * packaging_factor -- MUST be applied before any comparison
        % against a required fuel volume (item 5b; legacy code never applied
        % one at all -- "Legacy Bugs to Avoid" addendum).
        %   raw = 4.25*pi^2 (from the test above).
        %   shallow fuselage (0.80) -> 3.4*pi^2
        %   deep fuselage    (0.85) -> 3.6125*pi^2
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas(10, 4, 2);
            raw = SubsystemsL2.compute_fuselage_volume_raymer(A_top, A_side, 10);

            pf_shallow = SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — shallow fuselage');
            received_shallow = raw * pf_shallow;
            expected_shallow = 4.25*pi^2*0.80;
            fprintf('  [L2] testFuselageUsableFuelVolumeAppliesPackagingFactor: [shallow] expected=%.6g, received=%.6g\n', expected_shallow, received_shallow);
            tc.verifyEqual(received_shallow, expected_shallow, 'AbsTol', 1e-9);

            pf_deep = SubsystemsL2.lookup_packaging_factor_nicolai('Integral tank — deep fuselage');
            received_deep = raw * pf_deep;
            expected_deep = 4.25*pi^2*0.85;
            fprintf('  [L2] testFuselageUsableFuelVolumeAppliesPackagingFactor: [deep] expected=%.6g, received=%.6g\n', expected_deep, received_deep);
            tc.verifyEqual(received_deep, expected_deep, 'AbsTol', 1e-9);

            % Regression guard, through the real class: the usable fuselage
            % volume must not silently equal the raw geometric volume.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            fprintf('  [L2] testFuselageUsableFuelVolumeAppliesPackagingFactor: [regression] raw=%.6g, usable (must differ)=%.6g\n', s2.get_fuselage_internal_volume(), s2.fuselage_fuel_volume);
            tc.verifyNotEqual(s2.fuselage_fuel_volume, s2.get_fuselage_internal_volume(), ...
                'fuselage_fuel_volume must not silently equal the raw geometric volume.');
            tc.verifyLessThan(s2.fuselage_fuel_volume, s2.get_fuselage_internal_volume());
        end

        function testWingFuelVolumeWiring(tc)
        % The design class chooses the planform; the toolbox evaluates the
        % equation. Assert the property is exactly that call.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            expected = SubsystemsL2.compute_wing_fuel_volume_roskam(g2.S_ref, ...
                           g2.b_wing, g2.tc_r_wing, g2.tc_t_wing, g2.lambda_wing);
            fprintf('  [L2] testWingFuelVolumeWiring: expected=%.6g, received=%.6g\n', expected, s2.wing_fuel_volume);
            tc.verifyEqual(s2.wing_fuel_volume, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsWeightFractionReusesL1Lookup(tc)
        % Level-agnostic -- the L2 class must read SubsystemsL1's own table,
        % not a duplicated one. Fighters = (0.03+0.08)/2 = 0.055.
            expected = mean(SubsystemsL1.lookup_avionics_weight_fraction_range('Fighters'));
            fprintf('  [L2] testAvionicsWeightFractionReusesL1Lookup: expected=%.6g, received=%.6g\n', 0.055, expected);
            tc.verifyEqual(expected, 0.055, 'AbsTol', 1e-9);

            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            fprintf('  [L2] testAvionicsWeightFractionReusesL1Lookup: property expected=%.6g, received=%.6g\n', expected, s2.avionics_weight_fraction);
            tc.verifyEqual(s2.avionics_weight_fraction, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsDensityL2IsTheRaymerRangeAverage(tc)
        % [Raymer 6th ed. Ch.11 p.375 prose] "about 30-45 lb/ft^3" -> 37.5.
        % L2 holds its own copy of the constant, deliberately identical to
        % L1's: nothing in this repository uses Nicolai's flat 45.
            received = SubsystemsL2.AVIONICS_DENSITY;
            expected = 37.5;
            fprintf('  [L2] testAvionicsDensityL2IsTheRaymerRangeAverage: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            fprintf('  [L2] testAvionicsDensityL2IsTheRaymerRangeAverage: L1 constant=%.6g (deliberate duplicate)\n', SubsystemsL1.AVIONICS_DENSITY);
            tc.verifyEqual(received, SubsystemsL1.AVIONICS_DENSITY, 'AbsTol', 1e-9);

            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            fprintf('  [L2] testAvionicsDensityL2IsTheRaymerRangeAverage: property expected=%.6g, received=%.6g\n', expected, s2.avionics_density);
            tc.verifyEqual(s2.avionics_density, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsWeightAndVolumeHandComputed(tc)
        % fraction (Fighters) = 0.055; W_empty = 12000 (independently chosen,
        % NOT the F-16's own OEW)
        %   -> W_avionics = 660 lbf exactly; Vol = 660/37.5 = 17.6 ft^3 exactly.
            received_weight = SubsystemsL1.compute_avionics_weight(0.055, 12000);
            expected_weight = 660;
            fprintf('  [L2] testAvionicsWeightAndVolumeHandComputed: weight expected=%.6g, received=%.6g\n', expected_weight, received_weight);
            tc.verifyEqual(received_weight, expected_weight, 'AbsTol', 1e-9);

            received_vol = SubsystemsL1.compute_avionics_volume(received_weight, SubsystemsL2.AVIONICS_DENSITY);
            expected_vol = 17.6;
            fprintf('  [L2] testAvionicsWeightAndVolumeHandComputed: volume expected=%.6g, received=%.6g\n', expected_vol, received_vol);
            tc.verifyEqual(received_vol, expected_vol, 'AbsTol', 1e-9);

            % The class joins the same two steps off its injected weights object.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            expected_class_weight = SubsystemsL1.compute_avionics_weight( ...
                                        s2.avionics_weight_fraction, w2.get_OEW(w2.W_TO));
            fprintf('  [L2] testAvionicsWeightAndVolumeHandComputed: class weight expected=%.6g, received=%.6g\n', expected_class_weight, s2.avionics_weight);
            tc.verifyEqual(s2.avionics_weight, expected_class_weight, 'AbsTol', 1e-9);
            fprintf('  [L2] testAvionicsWeightAndVolumeHandComputed: class volume expected=%.6g, received=%.6g\n', s2.avionics_weight/37.5, s2.total_avionics_volume_occupied);
            tc.verifyEqual(s2.total_avionics_volume_occupied, s2.avionics_weight/37.5, 'AbsTol', 1e-9);
        end

        function testFuelDensityL2ReusesTheBaseTable(tc)
        % [Nicolai & Carichner Table 8.6, p.210]. The table lives on
        % SubsystemsBase because fuel density does not vary with fidelity.
            expected = 51.1;
            received = SubsystemsBase.lookup_fuel_density_lb_per_ft_3('hydrocarbon', 'JP-5');
            fprintf('  [L2] testFuelDensityL2ReusesTheBaseTable: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            fprintf('  [L2] testFuelDensityL2ReusesTheBaseTable: property (JP-8) expected=%.6g, received=%.6g\n', 50.0, s2.fuel_density);
            tc.verifyEqual(s2.fuel_density, 50.0, 'AbsTol', 1e-9);
        end

        function testTotalFuelVolumeOccupiedHandComputed(tc)
        % Definitional weight/density conversion. NO packaging factor applied
        % (that only applies to the GEOMETRIC raw volume, a different
        % quantity).
        %   JP-8 (density 50.0): 400 / 50.0 = 8.0 ft^3 exactly.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            received = s2.get_total_fuel_volume_occupied(400);
            expected = 8.0;
            fprintf('  [L2] testTotalFuelVolumeOccupiedHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelVolumeAvailableIsSumOfFuselageAndWingTerms(tc)
        % get_fuel_volume_available = fuselage_fuel_volume + wing_fuel_volume,
        % the SAME sum fuel_volume_check reports as available_vol_ft3.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            fus_term  = s2.fuselage_fuel_volume;
            wing_term = s2.wing_fuel_volume;
            received  = s2.get_fuel_volume_available();
            expected  = fus_term + wing_term;
            fprintf('  [L2] testFuelVolumeAvailableIsSumOfFuselageAndWingTerms: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        % ================================================================== %
        % Volume consolidation / fuel_volume_check -- the legacy-bug guards.
        % "assert fuel_volume_check sums BOTH fuselage AND wing volume, never
        % just one" and "avionics volume is actually present and non-zero",
        % not silently dropped.
        % ================================================================== %

        function testTotalDesignVolumeSumsWingAndFuselage(tc)
        % LEGACY BUG 1 GUARD, in its current shape. total_design_volume is
        % the airframe volume: the wing fuel volume plus the RAW fuselage
        % internal volume. The avionics group is a separate quantity and
        % must be reported, not dropped, but it is not folded in here.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);

            expected = s2.get_wing_fuel_volume_available() + s2.get_fuselage_internal_volume();
            fprintf('  [L2] testTotalDesignVolumeSumsWingAndFuselage: expected=%.6g, received=%.6g\n', expected, s2.total_design_volume);
            tc.verifyEqual(s2.total_design_volume, expected, 'AbsTol', 1e-9);

            av_term = s2.total_avionics_volume_occupied;
            fprintf('  [L2] testTotalDesignVolumeSumsWingAndFuselage: avionics volume (must be >0) received=%.6g\n', av_term);
            tc.verifyGreaterThan(av_term, 0, 'Avionics volume term must be nonzero.');
            fprintf('  [L2] testTotalDesignVolumeSumsWingAndFuselage: design volume=%.6g must exclude avionics=%.6g\n', s2.total_design_volume, av_term);
            tc.verifyNotEqual(s2.total_design_volume, expected + av_term);
        end

        function testFuelVolumeCheckSumsFuselageAndWingNeverJustOne(tc)
        % LEGACY BUG 5 / item 5b GUARD: the legacy code compared RAW
        % (unpackaged) fuselage volume directly, and never demonstrably
        % summed fuselage+wing together. Assert 'available' equals the SUM
        % and differs from EITHER term alone.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);

            fus_term  = s2.fuselage_fuel_volume;
            wing_term = s2.wing_fuel_volume;

            result = s2.fuel_volume_check(2000);
            expected_available = fus_term + wing_term;
            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: available expected=%.6g, received=%.6g\n', expected_available, result.available_vol_ft3);
            tc.verifyEqual(result.available_vol_ft3, expected_available, 'AbsTol', 1e-9);

            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: available received=%.6g must NOT equal fus_term alone=%.6g\n', result.available_vol_ft3, fus_term);
            tc.verifyNotEqual(result.available_vol_ft3, fus_term, ...
                'fuel_volume_check must not check fuselage volume alone.');
            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: available received=%.6g must NOT equal wing_term alone=%.6g\n', result.available_vol_ft3, wing_term);
            tc.verifyNotEqual(result.available_vol_ft3, wing_term, ...
                'fuel_volume_check must not check wing volume alone.');

            % Consolidation: available_vol_ft3 must equal the standalone
            % get_fuel_volume_available() answer exactly -- the same sum.
            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: consolidation, available=%.6g vs get_fuel_volume_available=%.6g\n', result.available_vol_ft3, s2.get_fuel_volume_available());
            tc.verifyEqual(result.available_vol_ft3, s2.get_fuel_volume_available(), 'AbsTol', 1e-9);

            % required_vol_ft3 = 2000/50 = 40 ft^3.
            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: required expected=%.6g, received=%.6g\n', 40.0, result.required_vol_ft3);
            tc.verifyEqual(result.required_vol_ft3, 40.0, 'AbsTol', 1e-9);
            fprintf('  [L2] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: expecting sufficient=true (available=%.6g, required=%.6g)\n', result.available_vol_ft3, result.required_vol_ft3);
            tc.verifyTrue(result.sufficient);
        end

        function testFuelVolumeCheckInsufficientCase(tc)
        % A fuel weight far beyond what the airframe can hold must report
        % sufficient = false, not silently pass.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            required_weight = 2 * s2.get_fuel_volume_available() * s2.fuel_density;

            result = s2.fuel_volume_check(required_weight);
            fprintf('  [L2] testFuelVolumeCheckInsufficientCase: required expected=%.6g, received=%.6g\n', required_weight/50.0, result.required_vol_ft3);
            tc.verifyEqual(result.required_vol_ft3, required_weight/50.0, 'AbsTol', 1e-9);
            fprintf('  [L2] testFuelVolumeCheckInsufficientCase: expecting sufficient=false (available=%.6g, required=%.6g)\n', result.available_vol_ft3, result.required_vol_ft3);
            tc.verifyFalse(result.sufficient);
        end

        function testFuelVolumeCheckErrorsOnNaN(tc)
        % W_energy is NaN until a sizing run sets it, so a NaN required
        % volume must not be silently reported as "sufficient".
            threw = false;
            msg   = '(none thrown)';
            try
                SubsystemsL2.fuel_volume_check(NaN, 100);
            catch ME
                threw = true;
                msg   = ME.message;
            end
            fprintf('  [L2] testFuelVolumeCheckErrorsOnNaN: expected=error, received=%s (%s)\n', mat2str(threw), msg);
            tc.verifyTrue(threw, 'fuel_volume_check must reject a NaN required volume.');
            tc.verifySubstring(msg, 'NaN');
        end

        % ------------------------------------------------------------------ %
        % DELIBERATE TODO -- battery volumetric energy density. NOT a failure
        % to fix -- this test PINS the documented, correctly-erroring
        % citation-gap behavior:
        % SubsystemsL2.compute_battery_volume must refuse to fabricate a coefficient
        % and must error with its documented identifier. If this test ever
        % goes red because battery_volume stops erroring, that means someone
        % implemented a real formula without updating this test -- update
        % the test, don't just delete it.
        % ------------------------------------------------------------------ %

        function testTODO_BatteryVolumetricEnergyDensityNotInRepo(tc)
        %TESTTODO_BATTERYVOLUMETRICENERGYDENSITYNOTINREPO  Documented citation
        %   GAP.
        %
        %   WHAT IS MISSING: no citable BATTERY VOLUMETRIC energy density
        %   (kWh/ft^3, kWh/L) or pack density (lb/ft^3) exists anywhere in
        %   this repo to convert a required battery energy into a volume --
        %   only GRAVIMETRIC specific energy is cited [Nicolai & Carichner,
        %   Table 14.2, p.363, batteries 0.27 kWh/lb]. Re-confirmed still
        %   open (Casey, 2026-08-03) after re-scanning all the
        %   reference-extract files.
        %
        %   HOW THIS TEST DOCUMENTS IT: SubsystemsL2.compute_battery_volume (and
        %   L3 has no battery entry point of its own) is
        %   documented to error rather than fabricate a coefficient. L3 adds
        %   no battery path of its own and calls this one. This
        %   test PINS that correct, current behavior with the documented
        %   identifier -- matching the convention of
        %   TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo (a
        %   clearly-labeled marker for an open citation gap), adapted to
        %   this gap's shape: a live error() call rather than a comment-only
        %   TODO. CANDIDATE SOURCE FOUND 2026-09-15: Raymer 6th ed. Table
        %   20.1, p.748 lists battery energy density in Wh/L for 20
        %   chemistries, which is exactly the missing coefficient.
        %   Resolving the gap means supplying a citable volumetric
        %   energy/pack density, implementing the real formula, and
        %   REPLACING this test's verifyError with a hand-computed
        %   expected-value check -- do not silently delete this test without
        %   doing that.
            expectedErrId = 'SubsystemsL2:batteryVolumetricDensityNotAvailable';
            try
                SubsystemsL2.compute_battery_volume(10);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf(['  [L2] testTODO_BatteryVolumetricEnergyDensityNotInRepo (DELIBERATE TODO, ' ...
                'EXPECTED to error): expected_error=%s, received_error=%s (%s)\n'], ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL2.compute_battery_volume(10), ...
                'SubsystemsL2:batteryVolumetricDensityNotAvailable', ...
                ['TODO (documented gap, EXPECTED to error): no citable battery volumetric ' ...
                 'energy density exists in this repo.']);
        end

        % ================================================================== %
        % F16SubsystemsL2 wiring / DI / optimization-ready property design.
        % ================================================================== %

        function testF16SubsystemsL2ReadsJSON(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);

            received_fuel_name = s2.fuel_name;
            expected_fuel_name = 'JP-8';
            fprintf('  [L2] testF16SubsystemsL2ReadsJSON: fuel_name expected=%s, received=%s\n', expected_fuel_name, received_fuel_name);
            tc.verifyEqual(received_fuel_name, expected_fuel_name);

            received_packaging = s2.packaging_factor_category;
            expected_packaging = 'Integral tank — shallow fuselage';
            fprintf('  [L2] testF16SubsystemsL2ReadsJSON: packaging_factor_category expected=%s, received=%s\n', expected_packaging, received_packaging);
            tc.verifyEqual(received_packaging, expected_packaging);

            received_avionics_row = s2.avionics_table_row;
            expected_avionics_row = 'Fighters';
            fprintf('  [L2] testF16SubsystemsL2ReadsJSON: avionics_table_row expected=%s, received=%s\n', expected_avionics_row, received_avionics_row);
            tc.verifyEqual(received_avionics_row, expected_avionics_row);
        end

        function testF16SubsystemsL2ConstructorRequiresAllThreeArgs(tc)
            expectedErrId = 'MATLAB:minrhs';
            try
                F16SubsystemsL2();
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testF16SubsystemsL2ConstructorRequiresAllThreeArgs (zero args): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL2(), 'MATLAB:minrhs');

            try
                F16SubsystemsL2(f16a_spec_path(2));
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testF16SubsystemsL2ConstructorRequiresAllThreeArgs (one arg): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2)), 'MATLAB:minrhs');

            [g2, ~] = TestSubsystemsL2.makeGeomAndWeights();
            try
                F16SubsystemsL2(f16a_spec_path(2), g2);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testF16SubsystemsL2ConstructorRequiresAllThreeArgs (two args): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g2), 'MATLAB:minrhs');
        end

        function testF16SubsystemsL2WrongGeomTierErrorsAtConstruction(tc)
        % geom is typed (1,1) GeometryModelL2 -- an L1 or L3 geometry object
        % must fail at CONSTRUCTION (mirrors TestWeightsL2.
        % testWrongGeomTierErrorsAtConstruction).
            [~, w2] = TestSubsystemsL2.makeGeomAndWeights();
            g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            prop = F16PropL2(f16a_spec_path(2));
            g3 = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());

            expectedErrId = 'MATLAB:validation:UnableToConvert';
            try
                F16SubsystemsL2(f16a_spec_path(2), g1, w2);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testF16SubsystemsL2WrongGeomTierErrorsAtConstruction (L1 geom): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g1, w2), ...
                'MATLAB:validation:UnableToConvert');

            try
                F16SubsystemsL2(f16a_spec_path(2), g3, w2);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L2] testF16SubsystemsL2WrongGeomTierErrorsAtConstruction (L3 geom): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g3, w2), ...
                'MATLAB:validation:UnableToConvert');
        end

        function testF16SubsystemsL2DerivedPropertiesLiveRecompute(tc)
        % Mutate an input in place and verify a Dependent getter tracks it
        % with NO reconstruction.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            v0 = s2.fuselage_fuel_volume;

            g2.W_max_fuselage = g2.W_max_fuselage + 1;   % optimizer-style mutation
            v1 = s2.fuselage_fuel_volume;
            fprintf('  [L2] testF16SubsystemsL2DerivedPropertiesLiveRecompute: fuselage_fuel_volume before=%.6g, after mutation (must differ)=%.6g\n', v0, v1);
            tc.verifyNotEqual(v1, v0, ...
                'fuselage_fuel_volume must recompute live after geom.W_max_fuselage mutates.');

            fd0 = s2.fuel_density;
            s2.fuel_name = 'JP-5';
            fd1 = s2.fuel_density;
            expected_fd1 = 51.1;
            fprintf('  [L2] testF16SubsystemsL2DerivedPropertiesLiveRecompute: fuel_density expected=%.6g, received=%.6g\n', expected_fd1, fd1);
            tc.verifyEqual(fd1, expected_fd1, 'AbsTol', 1e-9);
            fprintf('  [L2] testF16SubsystemsL2DerivedPropertiesLiveRecompute: fuel_density before=%.6g, after mutation (must differ)=%.6g\n', fd0, fd1);
            tc.verifyNotEqual(fd1, fd0, 'fuel_density must recompute live after fuel_name mutates.');
        end

        function testF16SubsystemsL2DerivedPropertiesAreReadOnly(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            expectedErrId = 'MATLAB:class:noSetMethod';
            propsToCheck = {'fuselage_fuel_volume', 'wing_fuel_volume', ...
                            'total_avionics_volume_occupied', ...
                            'total_fuel_volume_occupied', 'total_design_volume'};
            for i = 1:numel(propsToCheck)
                try
                    setfield(s2, propsToCheck{i}, 999); %#ok<STFLD,SFLD>
                    actualErrId = '(none thrown)';
                    actualErrMsg = '(none thrown)';
                catch ME
                    actualErrId = ME.identifier;
                    actualErrMsg = ME.message;
                end
                fprintf(['  [L2] testF16SubsystemsL2DerivedPropertiesAreReadOnly (%s): expected_error=%s, ' ...
                    'received_error=%s (%s)\n'], propsToCheck{i}, expectedErrId, actualErrId, actualErrMsg);
                tc.verifyError(@() setfield(s2, propsToCheck{i}, 999), expectedErrId);
            end
        end

        function testF16SubsystemsL2AvionicsVolumeIsReportedNotDropped(tc)
        % End-to-end guard for Legacy Bug 1 through the REAL Tier-3 class:
        % the avionics volume must be a live, nonzero quantity of its own.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            av_vol = s2.total_avionics_volume_occupied;
            fprintf('  [L2] testF16SubsystemsL2AvionicsVolumeIsReportedNotDropped: avionics volume (must be >0) received=%.6g\n', av_vol);
            tc.verifyGreaterThan(av_vol, 0);
            expected = s2.get_total_avionics_volume_categorical(w2.get_OEW(w2.W_TO));
            fprintf('  [L2] testF16SubsystemsL2AvionicsVolumeIsReportedNotDropped: expected=%.6g, received=%.6g\n', expected, av_vol);
            tc.verifyEqual(av_vol, expected, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL2FuelVolumeOccupiedTracksWEnergy(tc)
        % A getter takes no argument, so the fuel weight is read off the
        % injected weights object. It must not be cached.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            expected = w2.W_energy / s2.fuel_density;
            fprintf('  [L2] testF16SubsystemsL2FuelVolumeOccupiedTracksWEnergy: expected=%.6g, received=%.6g\n', expected, s2.total_fuel_volume_occupied);
            tc.verifyEqual(s2.total_fuel_volume_occupied, expected, 'AbsTol', 1e-9);

            w2.W_energy = 7000;
            fprintf('  [L2] testF16SubsystemsL2FuelVolumeOccupiedTracksWEnergy: after W_energy=7000 expected=%.6g, received=%.6g\n', 140.0, s2.total_fuel_volume_occupied);
            tc.verifyEqual(s2.total_fuel_volume_occupied, 140.0, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL2TotalFuelVolumeOccupiedMethod(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            received = s2.get_total_fuel_volume_occupied(500);
            expected = 500 / s2.fuel_density;
            fprintf('  [L2] testF16SubsystemsL2TotalFuelVolumeOccupiedMethod: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL2IsaChecks(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);

            is_subsystems_base = isa(s2, 'SubsystemsBase');
            fprintf('  [L2] testF16SubsystemsL2IsaChecks: isa(s2,''SubsystemsBase'') expected=true, received=%s\n', mat2str(is_subsystems_base));
            tc.verifyTrue(is_subsystems_base);

            is_model_l2 = isa(s2, 'SubsystemsModelL2');
            fprintf('  [L2] testF16SubsystemsL2IsaChecks: isa(s2,''SubsystemsModelL2'') expected=true, received=%s\n', mat2str(is_model_l2));
            tc.verifyTrue(is_model_l2);

            is_model_l1 = isa(s2, 'SubsystemsModelL1');
            fprintf('  [L2] testF16SubsystemsL2IsaChecks: isa(s2,''SubsystemsModelL1'') expected=false, received=%s\n', mat2str(is_model_l1));
            tc.verifyFalse(is_model_l1);

            is_handle = isa(s2, 'handle');
            fprintf('  [L2] testF16SubsystemsL2IsaChecks: isa(s2,''handle'') expected=true, received=%s\n', mat2str(is_handle));
            tc.verifyTrue(is_handle);
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function [g2, w2] = makeGeomAndWeights()
        %MAKEGEOMANDWEIGHTS  Real F16GeomL2 + F16WeightsL2, W_TO/W_energy set
        %   to plausible sizing-loop STATE values so avionics_weight/
        %   fuel_volume_check do not error on NaN. These values are used
        %   only as realistic INPUT state, never as an "expected" output --
        %   no Brandt ground truth is read or compared against here.
            prop = F16PropL2(f16a_spec_path(2));
            g2   = F16GeomL2(f16a_spec_path(2), prop);
            w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
            w2.W_TO     = 31377;
            w2.W_energy = 6296.30;
        end

    end

end

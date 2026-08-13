classdef TestSubsystemsL1 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL1  Unit tests for SubsystemsL1, SubsystemsBase, and F16SubsystemsL1.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green. Companion Tier-2
%   report: examples/F16A/sanity_checks/subsystems_brandt_comparison.m (informational,
%   NOT here).
%
%   Every "expected" value below is HAND-COMPUTED from the cited formula
%   with independently-chosen arithmetic (mostly round numbers picked so the
%   arithmetic is exact/verifiable by inspection), NOT reverse-engineered
%   from the production code's own output, and NOT the same F-16 numbers the
%   production JSON carries (except the small number of explicit "wiring"
%   tests that read the JSON directly and assert against the JSON's own
%   independently-known values -- e.g. that fuel_type is literally 'JP-8').
%
%   L1 is tabulation-only (Fidelity split): no geometry, no fuel-tank
%   packaging factor, no landing-gear counterpart.
%   Methods needing an external weight (W_empty, a required fuel weight)
%   take it as an explicit argument rather than reading an injected object,
%   so most high-level toolbox calls below use a lightweight STRUCT standing
%   in for "obj" (dot-indexing into a plain struct works identically to a
%   real object field read, and keeps these tests independent of any
%   production Tier-3 class's JSON-reading machinery).
%
%   Sources: fuel-type density / packaging factors [Nicolai & Carichner
%   Ch.8, p.210]; avionics weight fraction [Raymer 6th ed. Table 11.6,
%   p.375]; L1's own avionics density = Raymer's own following-paragraph
%   range average (30-45 lb/ft^3 -> 37.5).

    methods (TestClassSetup)
        function announceFidelityLevel(tc) %#ok<MANU>
            fprintf('\n');
            fprintf('=====================================================\n');
            fprintf('  FIDELITY LEVEL 1 -- Subsystems (TestSubsystemsL1)\n');
            fprintf('=====================================================\n');
        end
    end

    methods (Test)

        % ================================================================== %
        % LOW-LEVEL LOOKUPS -- pure tables, hand-verified against the original
        % step-9 design's transcription of the physical books.
        % ================================================================== %

        function testLookupFuelDensityAllFourTypes(tc)
        % [Nicolai & Carichner Table 8.6, p.210] lb/ft^3 by type.
            received = SubsystemsL1.lookup_fuel_density('JP-4');
            expected = 48.6;
            fprintf('  [L1] testLookupFuelDensityAllFourTypes (JP-4): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density('JP-5');
            expected = 51.1;
            fprintf('  [L1] testLookupFuelDensityAllFourTypes (JP-5): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density('JP-8');
            expected = 50.0;
            fprintf('  [L1] testLookupFuelDensityAllFourTypes (JP-8): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density('Aviation gas');
            expected = 44.9;
            fprintf('  [L1] testLookupFuelDensityAllFourTypes (Aviation gas): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testLookupFuelDensityUnknownTypeErrors(tc)
            expectedErrId = 'SubsystemsL1:unknownFuelType';
            try
                SubsystemsL1.lookup_fuel_density('Diesel');
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testLookupFuelDensityUnknownTypeErrors: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL1.lookup_fuel_density('Diesel'), ...
                expectedErrId);
        end

        function testLookupFuelDensityLbPerGalAllFourTypes(tc)
        % [Nicolai & Carichner Table 8.6, p.210] lb/gal by type.
            received = SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-4');
            expected = 6.5;
            fprintf('  [L1] testLookupFuelDensityLbPerGalAllFourTypes (JP-4): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-5');
            expected = 6.8;
            fprintf('  [L1] testLookupFuelDensityLbPerGalAllFourTypes (JP-5): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-8');
            expected = 6.7;
            fprintf('  [L1] testLookupFuelDensityLbPerGalAllFourTypes (JP-8): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_fuel_density_lb_per_gal('Aviation gas');
            expected = 6.0;
            fprintf('  [L1] testLookupFuelDensityLbPerGalAllFourTypes (Aviation gas): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testLookupFuelDensityLbPerGalUnknownTypeErrors(tc)
            expectedErrId = 'SubsystemsL1:unknownFuelType';
            try
                SubsystemsL1.lookup_fuel_density_lb_per_gal('Diesel');
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testLookupFuelDensityLbPerGalUnknownTypeErrors: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL1.lookup_fuel_density_lb_per_gal('Diesel'), ...
                expectedErrId);
        end

        function testLookupAvionicsWeightFractionRangeSpotChecks(tc)
        % [Raymer 6th ed. Table 11.6, p.375], full 8-row table -- spot-check
        % three rows independently transcribed from the original step-9
        % design's own reproduction.
            received = SubsystemsL1.lookup_avionics_weight_fraction_range('Fighters');
            expected = [0.03, 0.08];
            fprintf('  [L1] testLookupAvionicsWeightFractionRangeSpotChecks (Fighters): expected=%s, received=%s\n', mat2str(expected), mat2str(received));
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_avionics_weight_fraction_range('Bombers');
            expected = [0.06, 0.08];
            fprintf('  [L1] testLookupAvionicsWeightFractionRangeSpotChecks (Bombers): expected=%s, received=%s\n', mat2str(expected), mat2str(received));
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_avionics_weight_fraction_range('Jet transport');
            expected = [0.01, 0.02];
            fprintf('  [L1] testLookupAvionicsWeightFractionRangeSpotChecks (Jet transport): expected=%s, received=%s\n', mat2str(expected), mat2str(received));
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testLookupAvionicsWeightFractionRangeUnknownRowErrors(tc)
            expectedErrId = 'SubsystemsL1:unknownAvionicsCategory';
            try
                SubsystemsL1.lookup_avionics_weight_fraction_range('Airliner');
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testLookupAvionicsWeightFractionRangeUnknownRowErrors: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL1.lookup_avionics_weight_fraction_range('Airliner'), ...
                expectedErrId);
        end

        function testLookupAvionicsWeightFractionIsRangeMidpoint(tc)
        % DECIDED (Casey, 2026-08-03): the row's own range midpoint, not the
        % legacy code's low-end 0.03. Hand-computed midpoints:
        %   Fighters:      (0.03+0.08)/2 = 0.055
        %   Jet transport: (0.01+0.02)/2 = 0.015
        %   Business jet:  (0.04+0.05)/2 = 0.045
            received = SubsystemsL1.lookup_avionics_weight_fraction('Fighters');
            expected = 0.055;
            fprintf('  [L1] testLookupAvionicsWeightFractionIsRangeMidpoint (Fighters): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_avionics_weight_fraction('Jet transport');
            expected = 0.015;
            fprintf('  [L1] testLookupAvionicsWeightFractionIsRangeMidpoint (Jet transport): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = SubsystemsL1.lookup_avionics_weight_fraction('Business jet');
            expected = 0.045;
            fprintf('  [L1] testLookupAvionicsWeightFractionIsRangeMidpoint (Business jet): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            % Regression guard: must NOT have regressed to the legacy low-end pick.
            received = SubsystemsL1.lookup_avionics_weight_fraction('Fighters');
            notExpected = 0.03;
            fprintf('  [L1] testLookupAvionicsWeightFractionIsRangeMidpoint (regression guard, Fighters): notExpected=%.6g, received=%.6g\n', notExpected, received);
            tc.verifyNotEqual(received, notExpected, ...
                'avionics fraction has regressed to the legacy low-end 0.03 instead of the decided midpoint.');
        end

        % ================================================================== %
        % HIGH-LEVEL toolbox statics -- called with a lightweight struct
        % standing in for "obj" (dot-indexing a struct field behaves
        % identically to reading a real object property for these purposes).
        % ================================================================== %

        function testAvionicsWeightFractionHighLevel(tc)
            obj = struct('avionics_table_row', 'Fighters');
            received = SubsystemsL1.avionics_weight_fraction(obj);
            expected = 0.055;
            fprintf('  [L1] testAvionicsWeightFractionHighLevel: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsDensityL1IsRaymerRangeAverage(tc)
        % [Raymer 6th ed. Ch.11 p.375 prose]: "about 30-45 lb/ft^3" -> mean = 37.5.
        % Distinct from L2/L3's flat Nicolai 45 -- this is the fidelity-split
        % guard.
            obj = struct();   % avionics_density(obj) does not read obj at L1
            received = SubsystemsL1.avionics_density(obj);
            expected = 37.5;
            fprintf('  [L1] testAvionicsDensityL1IsRaymerRangeAverage: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            notExpected = 45.0;
            fprintf('  [L1] testAvionicsDensityL1IsRaymerRangeAverage (fidelity-split guard): notExpected=%.6g, received=%.6g\n', notExpected, received);
            tc.verifyNotEqual(received, notExpected, ...
                'L1 avionics density must NOT be L2/L3''s flat Nicolai 45 -- fidelity split.');
        end

        function testAvionicsWeightHandComputed(tc)
        % W_avionics = fraction * W_empty. Fighters fraction = 0.055.
        %   W_empty = 10,000 lb (independently chosen, NOT the F-16's own
        %   OEW) -> 0.055*10000 = 550 lbf exactly.
            obj = struct('avionics_table_row', 'Fighters');
            received = SubsystemsL1.avionics_weight(obj, 10000);
            expected = 550;
            fprintf('  [L1] testAvionicsWeightHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsVolumeHandComputed(tc)
        % Vol = W_avionics / density = 550 / 37.5 = 14.6666666667 ft^3 (= 44/3).
            obj = struct('avionics_table_row', 'Fighters');
            expected = 44/3;
            received = SubsystemsL1.avionics_volume(obj, 10000);
            fprintf('  [L1] testAvionicsVolumeHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelDensityHighLevel(tc)
            obj = struct('fuel_type', 'JP-8');
            received = SubsystemsL1.fuel_density(obj);
            expected = 50.0;
            fprintf('  [L1] testFuelDensityHighLevel (JP-8): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            obj.fuel_type = 'JP-4';
            received = SubsystemsL1.fuel_density(obj);
            expected = 48.6;
            fprintf('  [L1] testFuelDensityHighLevel (JP-4): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelVolumeFromWeightHandComputed(tc)
        % No packaging factor at L1 (not usable -- no geometric raw volume
        % exists yet).
        %   JP-8: 500 / 50.0  = 10.0 ft^3 exactly.
        %   JP-4: 486 / 48.6  = 10.0 ft^3 exactly (chosen so both cases give
        %   a clean round number, independent of each other).
            obj = struct('fuel_type', 'JP-8');
            received = SubsystemsL1.fuel_volume_from_weight(obj, 500);
            expected = 10.0;
            fprintf('  [L1] testFuelVolumeFromWeightHandComputed (JP-8): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            obj.fuel_type = 'JP-4';
            received = SubsystemsL1.fuel_volume_from_weight(obj, 486);
            expected = 10.0;
            fprintf('  [L1] testFuelVolumeFromWeightHandComputed (JP-4): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testInternalVolumeL1EqualsAvionicsVolumeOnly(tc)
        % L1 has no fuel-bay/gear-bay geometry -- internal_volume() must be
        % EXACTLY the avionics term, no more, no less (Fidelity split).
            obj = struct('avionics_table_row', 'Fighters');
            received = SubsystemsL1.internal_volume(obj, 10000);
            expected = SubsystemsL1.avionics_volume(obj, 10000);
            fprintf('  [L1] testInternalVolumeL1EqualsAvionicsVolumeOnly: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelVolumeCheckL1AvailableIsHonestlyZero(tc)
        % No fuel-bay geometry exists at L1 -- 'available' must be reported
        % as 0, not guessed, while 'required' is still computed so a caller
        % can see how much volume WOULD be needed.
            obj    = struct('fuel_type', 'JP-8');
            result = SubsystemsL1.fuel_volume_check(obj, 500);

            received = result.available_vol_ft3;
            expected = 0;
            fprintf('  [L1] testFuelVolumeCheckL1AvailableIsHonestlyZero (available_vol_ft3): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = result.required_vol_ft3;
            expected = 10.0;
            fprintf('  [L1] testFuelVolumeCheckL1AvailableIsHonestlyZero (required_vol_ft3): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            fprintf('  [L1] testFuelVolumeCheckL1AvailableIsHonestlyZero (sufficient): expected=false, received=%s\n', mat2str(result.sufficient));
            tc.verifyFalse(result.sufficient, ...
                'L1 fuel_volume_check must not report "sufficient" for a nonzero fuel requirement.');
        end

        function testFuelVolumeCheckL1TrivialSufficientAtZeroRequired(tc)
            obj    = struct('fuel_type', 'JP-8');
            result = SubsystemsL1.fuel_volume_check(obj, 0);
            fprintf('  [L1] testFuelVolumeCheckL1TrivialSufficientAtZeroRequired (sufficient): expected=true, received=%s\n', mat2str(result.sufficient));
            tc.verifyTrue(result.sufficient, ...
                'Zero required fuel is the one case L1''s zero-available check can honestly call sufficient.');
        end

        function testFuselageRawVolumeL1IsHonestlyZero(tc)
        % No fuselage geometry exists at L1 (SubsystemsBase.m header note,
        % 2026-08-03) -- 0, not guessed. Declared on SubsystemsBase so every
        % fidelity level provides this member.
            obj = struct();   % fuselage_raw_volume(obj) does not read obj at L1
            received = SubsystemsL1.fuselage_raw_volume(obj);
            expected = 0;
            fprintf('  [L1] testFuselageRawVolumeL1IsHonestlyZero: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelVolumeL1IsHonestlyZero(tc)
        % No fuel-bay geometry exists at L1 -- same rationale as
        % fuselage_raw_volume. Must equal fuel_volume_check's own
        % available_vol_ft3 answer (also 0 at L1).
            obj = struct();
            received = SubsystemsL1.fuel_volume(obj);
            expected = 0;
            fprintf('  [L1] testFuelVolumeL1IsHonestlyZero: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        % ================================================================== %
        % SubsystemsBase.weight_to_volume -- shared identity + guards.
        % ================================================================== %

        function testWeightToVolumeGenericIdentity(tc)
        % vol = W/density.  100 lb / 50 lb/ft^3 = 2.0 ft^3 exactly.
            received = SubsystemsBase.weight_to_volume(100, 50);
            expected = 2.0;
            fprintf('  [L1] testWeightToVolumeGenericIdentity: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testWeightToVolumeRejectsNegativeWeight(tc)
            expectedErrId = 'MATLAB:validators:mustBeNonnegative';
            try
                SubsystemsBase.weight_to_volume(-1, 50);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testWeightToVolumeRejectsNegativeWeight: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsBase.weight_to_volume(-1, 50), ...
                expectedErrId);
        end

        function testWeightToVolumeRejectsNonPositiveDensity(tc)
            expectedErrId = 'MATLAB:validators:mustBePositive';
            try
                SubsystemsBase.weight_to_volume(100, 0);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testWeightToVolumeRejectsNonPositiveDensity: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsBase.weight_to_volume(100, 0), ...
                expectedErrId);
        end

        % ================================================================== %
        % F16SubsystemsL1 wiring / DI / optimization-ready property design.
        % Templates: TestGeomL2.testWettedAreasLiveOnRead /
        % testDerivedPropertiesAreReadOnly.
        % ================================================================== %

        function testF16SubsystemsL1ReadsJSONFuelAndAvionicsRow(tc)
            g = F16SubsystemsL1(f16a_spec_path(1));

            received = g.fuel_type;
            expected = 'JP-8';
            fprintf('  [L1] testF16SubsystemsL1ReadsJSONFuelAndAvionicsRow (fuel_type): expected=%s, received=%s\n', expected, received);
            tc.verifyEqual(received, expected, ...
                'f16a_L1.json .subsystems.fuel.fuel_type must be JP-8 (T.O. 1F-16A-1 nominal internal fuel).');

            received = g.avionics_table_row;
            expected = 'Fighters';
            fprintf('  [L1] testF16SubsystemsL1ReadsJSONFuelAndAvionicsRow (avionics_table_row): expected=%s, received=%s\n', expected, received);
            tc.verifyEqual(received, expected, ...
                'f16a_L1.json .subsystems.avionics.aircraft_category_table_row must be "Fighters".');
        end

        function testF16SubsystemsL1ConstructorRequiresJsonPath(tc)
            expectedErrId = 'MATLAB:minrhs';
            try
                F16SubsystemsL1();
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1ConstructorRequiresJsonPath: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL1(), expectedErrId);
        end

        function testF16SubsystemsL1DerivedPropertiesLiveRecompute(tc)
        % Mutate an input in place (optimizer-style) and verify the Dependent
        % getters track it with NO reconstruction -- CLAUDE.md's
        % "Optimization-ready property design"; TestGeomL2.
        % testWettedAreasLiveOnRead is the template.
            g = F16SubsystemsL1(f16a_spec_path(1));
            fd0 = g.fuel_density;
            af0 = g.avionics_weight_fraction;
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesLiveRecompute (fuel_density, JP-8 initial): expected=50, received=%.6g\n', fd0);
            tc.verifyEqual(fd0, 50.0, 'AbsTol', 1e-9);   % JP-8

            g.fuel_type = 'JP-5';   % optimizer-style in-place mutation
            received = g.fuel_density;
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesLiveRecompute (fuel_density after JP-5 mutation): expected=51.1, received=%.6g\n', received);
            tc.verifyEqual(received, 51.1, 'AbsTol', 1e-9, ...
                'fuel_density must recompute live from the mutated fuel_type.');
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesLiveRecompute (fuel_density changed from initial): initial=%.6g, received=%.6g\n', fd0, received);
            tc.verifyNotEqual(received, fd0, 'fuel_density must change after fuel_type mutation.');

            g.avionics_table_row = 'Bombers';
            received = g.avionics_weight_fraction;
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesLiveRecompute (avionics_weight_fraction after Bombers mutation): expected=0.07, received=%.6g\n', received);
            tc.verifyEqual(received, 0.07, 'AbsTol', 1e-9, ...
                'avionics_weight_fraction must recompute live -- Bombers midpoint = (0.06+0.08)/2 = 0.07.');
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesLiveRecompute (avionics_weight_fraction changed from initial): initial=%.6g, received=%.6g\n', af0, received);
            tc.verifyNotEqual(received, af0, ...
                'avionics_weight_fraction must change after avionics_table_row mutation.');
        end

        function testF16SubsystemsL1DerivedPropertiesAreReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning to one must
        % error (no set-method exists). TestGeomL2.testDerivedPropertiesAreReadOnly
        % is the template.
            g = F16SubsystemsL1(f16a_spec_path(1));
            expectedErrId = 'MATLAB:class:noSetMethod';

            try
                setfield(g, 'fuel_density', 999); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesAreReadOnly (fuel_density): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() setfield(g, 'fuel_density', 999), expectedErrId);

            try
                setfield(g, 'avionics_weight_fraction', 999); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesAreReadOnly (avionics_weight_fraction): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() setfield(g, 'avionics_weight_fraction', 999), expectedErrId);

            try
                setfield(g, 'avionics_density', 999); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesAreReadOnly (avionics_density): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() setfield(g, 'avionics_density', 999), expectedErrId);

            try
                setfield(g, 'fuselage_raw_volume', 999); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesAreReadOnly (fuselage_raw_volume): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() setfield(g, 'fuselage_raw_volume', 999), expectedErrId);

            try
                setfield(g, 'fuel_volume', 999); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L1] testF16SubsystemsL1DerivedPropertiesAreReadOnly (fuel_volume): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() setfield(g, 'fuel_volume', 999), expectedErrId);
        end

        function testF16SubsystemsL1FuselageRawVolumeAndFuelVolumeAreZero(tc)
        % Base-level contract added 2026-08-03: every fidelity level provides
        % fuselage_raw_volume/fuel_volume; L1 honestly answers 0 for both (no
        % fuselage/fuel-bay geometry exists at this tier).
            g = F16SubsystemsL1(f16a_spec_path(1));

            received = g.fuselage_raw_volume;
            expected = 0;
            fprintf('  [L1] testF16SubsystemsL1FuselageRawVolumeAndFuelVolumeAreZero (fuselage_raw_volume): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received = g.fuel_volume;
            expected = 0;
            fprintf('  [L1] testF16SubsystemsL1FuselageRawVolumeAndFuelVolumeAreZero (fuel_volume): expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL1IsaChecks(tc)
            g = F16SubsystemsL1(f16a_spec_path(1));

            received = isa(g, 'SubsystemsBase');
            fprintf('  [L1] testF16SubsystemsL1IsaChecks (isa SubsystemsBase): expected=true, received=%s\n', mat2str(received));
            tc.verifyTrue(received);

            received = isa(g, 'SubsystemsModelL1');
            fprintf('  [L1] testF16SubsystemsL1IsaChecks (isa SubsystemsModelL1): expected=true, received=%s\n', mat2str(received));
            tc.verifyTrue(received);

            received = isa(g, 'handle');
            fprintf('  [L1] testF16SubsystemsL1IsaChecks (isa handle): expected=true, received=%s\n', mat2str(received));
            tc.verifyTrue(received);
        end

    end

end

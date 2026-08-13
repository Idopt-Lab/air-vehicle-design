classdef TestSubsystemsL3 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL3  Unit tests for SubsystemsL3, SubsystemsModelL3, and F16SubsystemsL3.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green (no deliberate TODO
%   test here; the battery-volume gap is pinned once, in TestSubsystemsL2,
%   since SubsystemsL3.battery_volume reuses SubsystemsL2.battery_volume's
%   error identically rather than reissuing its own -- duplicating the
%   TODO-test marker here would double-count the same open gap).
%
%   L3 differs from L2 in exactly ONE respect (Fidelity split): the fuselage
%   raw-volume term is fed A_top/A_side from GeomL3's frame-integrated
%   station table instead of GeomL2's envelope-ellipse approximation. Every
%   other equation is level-agnostic and REUSED by direct cross-toolbox call
%   to SubsystemsL2 -- this file therefore focuses on (a) the new
%   frame-integration low-level static, (b) that fuselage_raw_volume actually
%   uses it (not the L2 ellipse), and
%   (c) that every reused equation still agrees with SubsystemsL2/L1, plus
%   the same optimization-ready property-design guards as TestSubsystemsL2.

    methods (TestClassSetup)

        function announceFidelityLevel(~)
            fprintf('\n============================================================\n');
            fprintf(' FIDELITY LEVEL 3 -- Subsystems\n');
            fprintf('============================================================\n');
        end

    end

    methods (Test)

        % ================================================================== %
        % NEW AT L3: frame-integrated projected-area trapezoidal integration.
        % Hand-computed independently of GeomL3.denormalize_frames' own
        % arithmetic (a trivial elementwise multiply, verified by inspection
        % below), so the trapz integration itself -- the actual citable
        % content here -- is checked against manually-derived numbers.
        % ================================================================== %

        function testComputeFrameIntegratedProjectedAreasHandComputed(tc)
        % frames_normalized = [x/L, w/W_max, h/H_max], two stations:
        %   [0.5, 0.5, 0.3; 1.0, 0.2, 0.1],  L_fus=10, W_max=4, H_max=2.
        % Denormalize (elementwise multiply):
        %   x = [5; 10],  w = [2; 0.8],  h = [0.6; 0.2]
        % Prepend the (0,0,0) nose station, then trapz:
        %   A_top  = trapz([0,5,10],[0,2,0.8])
        %          = avg(0,2)*5 + avg(2,0.8)*5 = 5 + 7   = 12 ft^2
        %   A_side = trapz([0,5,10],[0,0.6,0.2])
        %          = avg(0,0.6)*5 + avg(0.6,0.2)*5 = 1.5 + 2 = 3.5 ft^2
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            [A_top, A_side] = SubsystemsL3.compute_frame_integrated_projected_areas(frames, 10, 4, 2);
            expected_A_top  = 12.0;
            expected_A_side = 3.5;
            fprintf('  [L3] testComputeFrameIntegratedProjectedAreasHandComputed: A_top expected=%.6g, received=%.6g\n', expected_A_top, A_top);
            tc.verifyEqual(A_top,  expected_A_top, 'AbsTol', 1e-9);
            fprintf('  [L3] testComputeFrameIntegratedProjectedAreasHandComputed: A_side expected=%.6g, received=%.6g\n', expected_A_side, A_side);
            tc.verifyEqual(A_side, expected_A_side,  'AbsTol', 1e-9);
        end

        function testFuselageRawVolumeUsesFrameIntegratedAreasNotEllipse(tc)
        % [Raymer 6th ed. Eq. 7.14] fed the frame-integrated A_top/A_side
        % from the test above:  V = 3.4*(12*3.5)/(4*10) = 3.4*42/40 = 3.57 ft^3.
        % This is NOT what the L2 envelope-ellipse formula would give for
        % the same L/W/H (4.25*pi^2 = 41.95 ft^3, wildly different) -- the
        % explicit guard below confirms L3 truly uses its OWN frame data,
        % not a silently-reused L2 ellipse shortcut.
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2);
            expected = 3.57;
            received = SubsystemsL3.fuselage_raw_volume(obj);
            fprintf('  [L3] testFuselageRawVolumeUsesFrameIntegratedAreasNotEllipse: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            ellipse_equivalent = 4.25*pi^2;   % what L2's envelope-ellipse formula gives for the same L/W/H
            fprintf('  [L3] testFuselageRawVolumeUsesFrameIntegratedAreasNotEllipse: received=%.6g must differ from ellipse_equivalent=%.6g\n', received, ellipse_equivalent);
            tc.verifyNotEqual(received, ellipse_equivalent, ...
                'L3 fuselage_raw_volume must use frame-integrated areas, not silently fall back to the L2 ellipse.');
        end

        function testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3(tc)
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            received = SubsystemsL3.fuselage_usable_fuel_volume(obj);
            expected = 3.57*0.80;
            fprintf('  [L3] testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        % ================================================================== %
        % LEVEL-AGNOSTIC equations -- must agree exactly with SubsystemsL1/L2
        % (reused by direct cross-toolbox call, not duplicated).
        % ================================================================== %

        function testWingFuelVolumeAgreesWithL2(tc)
            obj.geom = struct('S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            received = SubsystemsL3.wing_fuel_volume(obj);
            expected = 11.34;
            fprintf('  [L3] testWingFuelVolumeAgreesWithL2: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received_l3 = SubsystemsL3.wing_fuel_volume(obj);
            received_l2 = SubsystemsL2.wing_fuel_volume(obj);
            fprintf('  [L3] testWingFuelVolumeAgreesWithL2: L3 received=%.6g, L2 received=%.6g\n', received_l3, received_l2);
            tc.verifyEqual(received_l3, received_l2, 'AbsTol', 1e-9);
        end

        function testAvionicsDensityAgreesWithL2FlatNicolai45(tc)
            obj = struct();
            received = SubsystemsL3.avionics_density(obj);
            expected = 45.0;
            fprintf('  [L3] testAvionicsDensityAgreesWithL2FlatNicolai45: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testAvionicsWeightAndVolumeAgreeWithL2(tc)
            obj.avionics_table_row = 'Fighters';
            obj.fuel_weight_source = struct('W_TO', 20000, 'OEW', @(~) 12000);
            received_weight = SubsystemsL3.avionics_weight(obj);
            expected_weight = 660;
            fprintf('  [L3] testAvionicsWeightAndVolumeAgreeWithL2: weight expected=%.6g, received=%.6g\n', expected_weight, received_weight);
            tc.verifyEqual(received_weight, expected_weight, 'AbsTol', 1e-9);

            received_volume = SubsystemsL3.avionics_volume(obj);
            expected_volume = 660/45;
            fprintf('  [L3] testAvionicsWeightAndVolumeAgreeWithL2: volume expected=%.6g, received=%.6g\n', expected_volume, received_volume);
            tc.verifyEqual(received_volume, expected_volume, 'AbsTol', 1e-9);
        end

        function testFuelDensityReusesL1Table(tc)
            obj = struct('fuel_type', 'JP-8');
            received = SubsystemsL3.fuel_density(obj);
            expected = 50.0;
            fprintf('  [L3] testFuelDensityReusesL1Table: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelVolumeFromWeightReusesL2(tc)
            obj = struct('fuel_type', 'JP-8');
            received = SubsystemsL3.fuel_volume_from_weight(obj, 400);
            expected = 8.0;
            fprintf('  [L3] testFuelVolumeFromWeightReusesL2: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            received_l3 = SubsystemsL3.fuel_volume_from_weight(obj, 400);
            received_l2 = SubsystemsL2.fuel_volume_from_weight(obj, 400);
            fprintf('  [L3] testFuelVolumeFromWeightReusesL2: L3 received=%.6g, L2 received=%.6g\n', received_l3, received_l2);
            tc.verifyEqual(received_l3, received_l2, 'AbsTol', 1e-9);
        end

        function testFuelVolumeUsesL3sOwnFuselageTermNotL2s(tc)
        % fuel_volume(obj) = L3's OWN fuselage_usable_fuel_volume (frame-
        % integrated) + wing_fuel_volume -- deliberately NOT delegated to
        % SubsystemsL2.fuel_volume, which would silently substitute L2's
        % envelope-ellipse fuselage term.
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';

            fus_term  = SubsystemsL3.fuselage_usable_fuel_volume(obj);   % 2.856
            wing_term = SubsystemsL3.wing_fuel_volume(obj);              % 11.34
            received  = SubsystemsL3.fuel_volume(obj);
            expected  = fus_term + wing_term;
            fprintf('  [L3] testFuelVolumeUsesL3sOwnFuselageTermNotL2s: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testBatteryVolumeReusesL2ErrorIdentically(tc)
        % NOT a new TODO test (see file header) -- structural check that L3
        % genuinely reuses L2's implementation rather than duplicating it.
            expectedErrId = 'SubsystemsL2:batteryVolumetricDensityNotAvailable';
            try
                SubsystemsL3.battery_volume(struct(), 10);
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testBatteryVolumeReusesL2ErrorIdentically: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL3.battery_volume(struct(), 10), ...
                expectedErrId);
        end

        % ================================================================== %
        % internal_volume / fuel_volume_check -- same legacy-bug guards as L2.
        % ================================================================== %

        function testInternalVolumeSumsAllThreeTermsIncludingAvionics(tc)
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.avionics_table_row        = 'Fighters';
            obj.fuel_weight_source        = struct('W_TO', 20000, 'OEW', @(~) 12000);

            fus_term  = SubsystemsL3.fuselage_usable_fuel_volume(obj);   % 3.57*0.80 = 2.856
            wing_term = SubsystemsL3.wing_fuel_volume(obj);              % 11.34
            av_term   = SubsystemsL3.avionics_volume(obj);               % 14.6666666667

            fprintf('  [L3] testInternalVolumeSumsAllThreeTermsIncludingAvionics: av_term=%.6g must be > 0\n', av_term);
            tc.verifyGreaterThan(av_term, 0);
            received = SubsystemsL3.internal_volume(obj);
            expected = fus_term + wing_term + av_term;
            fprintf('  [L3] testInternalVolumeSumsAllThreeTermsIncludingAvionics: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            fprintf('  [L3] testInternalVolumeSumsAllThreeTermsIncludingAvionics: received=%.6g must be > fus_term+wing_term=%.6g\n', received, fus_term + wing_term);
            tc.verifyGreaterThan(received, fus_term + wing_term, ...
                'internal_volume must include a nonzero avionics contribution.');
        end

        function testFuelVolumeCheckSumsFuselageAndWingNeverJustOne(tc)
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.fuel_type                 = 'JP-8';
            obj.fuel_weight_source        = struct('W_energy', 1000);

            fus_term  = SubsystemsL3.fuselage_usable_fuel_volume(obj);   % 2.856
            wing_term = SubsystemsL3.wing_fuel_volume(obj);              % 11.34, sum = 14.196

            result = SubsystemsL3.fuel_volume_check(obj);
            expected_available = fus_term + wing_term;
            fprintf('  [L3] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: available expected=%.6g, received=%.6g\n', expected_available, result.available_vol_ft3);
            tc.verifyEqual(result.available_vol_ft3, expected_available, 'AbsTol', 1e-9);
            fprintf('  [L3] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: received available=%.6g must differ from fus_term alone=%.6g\n', result.available_vol_ft3, fus_term);
            tc.verifyNotEqual(result.available_vol_ft3, fus_term);
            fprintf('  [L3] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: received available=%.6g must differ from wing_term alone=%.6g\n', result.available_vol_ft3, wing_term);
            tc.verifyNotEqual(result.available_vol_ft3, wing_term);
            expected_required = 20.0;   % 1000/50
            fprintf('  [L3] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: required expected=%.6g, received=%.6g\n', expected_required, result.required_vol_ft3);
            tc.verifyEqual(result.required_vol_ft3, expected_required, 'AbsTol', 1e-9);
            fprintf('  [L3] testFuelVolumeCheckSumsFuselageAndWingNeverJustOne: sufficient received=%s, expected=false\n', mat2str(result.sufficient));
            tc.verifyFalse(result.sufficient, 'required (20 ft^3) exceeds available (~14.2 ft^3).');
        end

        function testFuelVolumeCheckErrorsWhenWEnergyNaN(tc)
            frames = [0.5, 0.5, 0.3; 1.0, 0.2, 0.1];
            obj.geom = struct('frames_normalized', frames, 'L_fuselage', 10, ...
                               'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.fuel_type                 = 'JP-8';
            obj.fuel_weight_source        = struct('W_energy', NaN);
            expectedErrId = 'SubsystemsL3:fuelWeightNotSet';
            try
                SubsystemsL3.fuel_volume_check(obj);
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testFuelVolumeCheckErrorsWhenWEnergyNaN: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL3.fuel_volume_check(obj), expectedErrId);
        end

        % ================================================================== %
        % F16SubsystemsL3 wiring / DI / optimization-ready property design.
        % ================================================================== %

        function testF16SubsystemsL3ReadsJSON(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            expected_fuel_type = 'JP-8';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: fuel_type expected=%s, received=%s\n', expected_fuel_type, s3.fuel_type);
            tc.verifyEqual(s3.fuel_type, expected_fuel_type);
            expected_pkg_category = 'Integral tank — shallow fuselage';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: packaging_factor_category expected=%s, received=%s\n', expected_pkg_category, s3.packaging_factor_category);
            tc.verifyEqual(s3.packaging_factor_category, expected_pkg_category);
            expected_avionics_row = 'Fighters';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: avionics_table_row expected=%s, received=%s\n', expected_avionics_row, s3.avionics_table_row);
            tc.verifyEqual(s3.avionics_table_row, expected_avionics_row);
        end

        function testF16SubsystemsL3ConstructorRequiresAllThreeArgs(tc)
            expectedErrId = 'MATLAB:minrhs';

            try
                F16SubsystemsL3();
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testF16SubsystemsL3ConstructorRequiresAllThreeArgs (zero args): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL3(), expectedErrId);

            try
                F16SubsystemsL3(f16a_spec_path(3));
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testF16SubsystemsL3ConstructorRequiresAllThreeArgs (one arg): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL3(f16a_spec_path(3)), expectedErrId);

            [g3, ~] = TestSubsystemsL3.makeGeomAndWeights();
            try
                F16SubsystemsL3(f16a_spec_path(3), g3);
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testF16SubsystemsL3ConstructorRequiresAllThreeArgs (two args): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL3(f16a_spec_path(3), g3), expectedErrId);
        end

        function testF16SubsystemsL3WrongGeomTierErrorsAtConstruction(tc)
        % geom is typed (1,1) GeometryModelL3 -- an L2 geometry object must
        % fail at CONSTRUCTION.
            [~, w3] = TestSubsystemsL3.makeGeomAndWeights();
            prop = F16PropL2(f16a_spec_path(2));
            g2 = F16GeomL2(f16a_spec_path(2), prop);

            expectedErrId = 'MATLAB:validation:UnableToConvert';
            try
                F16SubsystemsL3(f16a_spec_path(3), g2, w3);
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testF16SubsystemsL3WrongGeomTierErrorsAtConstruction: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() F16SubsystemsL3(f16a_spec_path(3), g2, w3), ...
                expectedErrId);
        end

        function testF16SubsystemsL3DerivedPropertiesLiveRecompute(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            v0 = s3.fuselage_usable_fuel_volume;

            g3.W_max_fuselage = g3.W_max_fuselage + 1;   % optimizer-style mutation
            v1 = s3.fuselage_usable_fuel_volume;
            fprintf('  [L3] testF16SubsystemsL3DerivedPropertiesLiveRecompute: before-mutation value=%.6g, after-mutation received=%.6g (must differ)\n', v0, v1);
            tc.verifyNotEqual(v1, v0, ...
                'fuselage_usable_fuel_volume must recompute live after geom.W_max_fuselage mutates.');
        end

        function testF16SubsystemsL3DerivedPropertiesAreReadOnly(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);

            expectedErrId = 'MATLAB:class:noSetMethod';
            propsToCheck = {'fuselage_raw_volume', 'wing_fuel_volume', 'fuel_volume'};
            for i = 1:numel(propsToCheck)
                try
                    setfield(s3, propsToCheck{i}, 999); %#ok<STFLD,SFLD>
                    actualErrId  = '(none thrown)';
                    actualErrMsg = '(none thrown)';
                catch ME
                    actualErrId  = ME.identifier;
                    actualErrMsg = ME.message;
                end
                fprintf(['  [L3] testF16SubsystemsL3DerivedPropertiesAreReadOnly (%s): expected_error=%s, ' ...
                    'received_error=%s (%s)\n'], propsToCheck{i}, expectedErrId, actualErrId, actualErrMsg);
            end

            tc.verifyError(@() setfield(s3, 'fuselage_raw_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(s3, 'wing_fuel_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(s3, 'fuel_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testF16SubsystemsL3FuelVolumePropertyAndInternalVolumeConsolidation(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            received_fuel_volume = s3.fuel_volume;
            expected_fuel_volume = s3.fuselage_usable_fuel_volume + s3.wing_fuel_volume;
            fprintf('  [L3] testF16SubsystemsL3FuelVolumePropertyAndInternalVolumeConsolidation: fuel_volume expected=%.6g, received=%.6g\n', expected_fuel_volume, received_fuel_volume);
            tc.verifyEqual(received_fuel_volume, expected_fuel_volume, 'AbsTol', 1e-9);

            received_internal_volume = s3.internal_volume;
            expected_internal_volume = s3.fuel_volume + s3.avionics_volume;
            fprintf('  [L3] testF16SubsystemsL3FuelVolumePropertyAndInternalVolumeConsolidation: internal_volume expected=%.6g, received=%.6g\n', expected_internal_volume, received_internal_volume);
            tc.verifyEqual(received_internal_volume, expected_internal_volume, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL3InternalVolumeIncludesAvionics(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            fprintf('  [L3] testF16SubsystemsL3InternalVolumeIncludesAvionics: avionics_volume received=%.6g must be > 0\n', s3.avionics_volume);
            tc.verifyGreaterThan(s3.avionics_volume, 0);
            baseline_sum = s3.fuselage_usable_fuel_volume + s3.wing_fuel_volume;
            fprintf('  [L3] testF16SubsystemsL3InternalVolumeIncludesAvionics: internal_volume received=%.6g must be > fus+wing=%.6g\n', s3.internal_volume, baseline_sum);
            tc.verifyGreaterThan(s3.internal_volume, baseline_sum);
        end

        function testF16SubsystemsL3FuselageRawVolumeDiffersFromL2Equivalent(tc)
        % The whole point of the L2->L3 fidelity refinement (Fidelity split):
        % the frame-integrated fuselage volume must actually differ from
        % what the L2 envelope-ellipse approximation would give for a
        % comparable envelope -- otherwise the "refinement" is dead code.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            [A_top_ellipse, A_side_ellipse] = SubsystemsL2.compute_envelope_projected_areas( ...
                g3.L_fuselage, g3.W_max_fuselage, g3.H_max_fuselage);
            ellipse_equivalent = SubsystemsL2.compute_raymer_fuselage_volume( ...
                A_top_ellipse, A_side_ellipse, g3.L_fuselage);
            fprintf('  [L3] testF16SubsystemsL3FuselageRawVolumeDiffersFromL2Equivalent: received=%.6g must differ from ellipse_equivalent=%.6g\n', s3.fuselage_raw_volume, ellipse_equivalent);
            tc.verifyNotEqual(s3.fuselage_raw_volume, ellipse_equivalent, ...
                'L3''s frame-integrated fuselage volume must differ from the L2 ellipse approximation for the real F-16 station data.');
        end

        function testF16SubsystemsL3IsaChecks(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            fprintf('  [L3] testF16SubsystemsL3IsaChecks: isa(s3,''SubsystemsBase'') expected=true, received=%s\n', mat2str(isa(s3, 'SubsystemsBase')));
            tc.verifyTrue(isa(s3, 'SubsystemsBase'));
            fprintf('  [L3] testF16SubsystemsL3IsaChecks: isa(s3,''SubsystemsModelL3'') expected=true, received=%s\n', mat2str(isa(s3, 'SubsystemsModelL3')));
            tc.verifyTrue(isa(s3, 'SubsystemsModelL3'));
            fprintf('  [L3] testF16SubsystemsL3IsaChecks: isa(s3,''SubsystemsModelL2'') expected=false, received=%s\n', mat2str(isa(s3, 'SubsystemsModelL2')));
            tc.verifyFalse(isa(s3, 'SubsystemsModelL2'));
            fprintf('  [L3] testF16SubsystemsL3IsaChecks: isa(s3,''handle'') expected=true, received=%s\n', mat2str(isa(s3, 'handle')));
            tc.verifyTrue(isa(s3, 'handle'));
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function [g3, w3] = makeGeomAndWeights()
        %MAKEGEOMANDWEIGHTS  Real F16GeomL3 + F16WeightsL3, W_TO/W_energy set
        %   to plausible sizing-loop STATE values (not Brandt-derived
        %   "expected" outputs -- see TestSubsystemsL2.makeGeomAndWeights).
            prop = F16PropL2(f16a_spec_path(2));   % no L3 propulsion tier exists
            g3   = F16GeomL3(f16a_spec_path(3), prop);
            w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO     = 31377;
            w3.W_energy = 6296.30;
        end

    end

end

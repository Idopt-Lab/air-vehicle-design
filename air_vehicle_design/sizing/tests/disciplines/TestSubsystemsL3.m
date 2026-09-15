classdef TestSubsystemsL3 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL3  Unit tests for SubsystemsL3, SubsystemsModelL3, and F16SubsystemsL3.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green.
%
%   L3 differs from L2 in two respects. The fuselage volume comes from the
%   station table by cross-section-area integration [Raymer Fig. 7.38], not
%   from the L2 envelope ellipse fed to Eq. 7.14. The avionics group comes
%   from a per-box component buildup [Nicolai Table 8.8], not from a weight
%   fraction and a table density, so the avionics density is an OUTPUT here.
%
%   Every other equation is level-agnostic and is called directly on the
%   SubsystemsL2 / SubsystemsBase toolbox, never duplicated.
%
%   A toolbox static takes scalars, never a design object, so the toolbox
%   tests below pass literals and the wiring tests read a real object.

    methods (TestClassSetup)

        function announceFidelityLevel(~)
            fprintf('\n============================================================\n');
            fprintf(' FIDELITY LEVEL 3 -- Subsystems\n');
            fprintf('============================================================\n');
        end

    end

    methods (Test)

        % ================================================================== %
        % NEW AT L3: station-table integration.
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

        function testComputeVolumeFromControlStationsHandComputed(tc)
        % Stations x = [5; 10], w = [2; 0.8], h = [0.6; 0.2].
        % Cross-section area is I_cos*w*h, with I_cos Brandt's 6-point
        % cosine integral [GeomL3.compute_frame_cs_area], recomputed here
        % rather than transcribed:
        %   w.*h = [1.2; 0.16]
        % Prepend the (0,0) nose station, then trapz over x:
        %   trapz([0,5,10],[0,1.2,0.16]) = 5*(1.2/2) + 5*(1.2+0.16)/2
        %                                = 3 + 3.4 = 6.4
        %   Vol = I_cos * 6.4 ft^3
            t     = linspace(0, 1, 6);
            I_cos = trapz(t, cos(pi/2 * t));
            expected = I_cos * 6.4;
            received = SubsystemsL3.compute_volume_from_control_stations( ...
                           [5; 10], [2; 0.8], [0.6; 0.2]);
            fprintf('  [L3] testComputeVolumeFromControlStationsHandComputed: expected=%.10g, received=%.10g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testVolumeFromControlStationsRejectsRaggedInput(tc)
            expectedErrId = 'SubsystemsL3:frameVectorLengthMismatch';
            try
                SubsystemsL3.compute_volume_from_control_stations([5; 10], [2; 0.8; 0.4], [0.6; 0.2]);
                actualErrId  = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId  = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3] testVolumeFromControlStationsRejectsRaggedInput: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            tc.verifyError(@() SubsystemsL3.compute_volume_from_control_stations( ...
                [5; 10], [2; 0.8; 0.4], [0.6; 0.2]), expectedErrId);
        end

        % ================================================================== %
        % LEVEL-AGNOSTIC equations -- called on the L2 / Base toolbox.
        % ================================================================== %

        function testWingFuelVolumeUsesTheL2Toolbox(tc)
        % [Roskam Part II Eq. 6.2/6.3, p.153] at S=100, b=20, t/c=0.05 both
        % stations, lambda=0.25. tau_w = 1, so the bracket collapses to
        % (1 + 0.25 + 0.0625)/1.5625 = 0.84, and
        %   V = 0.54*(100^2/20)*0.05*0.84 = 0.54*500*0.05*0.84 = 11.34 ft^3.
            expected = 11.34;
            received = SubsystemsL2.compute_wing_fuel_volume_roskam(100, 20, 0.05, 0.05, 0.25);
            fprintf('  [L3] testWingFuelVolumeUsesTheL2Toolbox: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            from_toolbox = SubsystemsL2.compute_wing_fuel_volume_roskam(g3.S_ref, ...
                               g3.b_wing, g3.tc_r_wing, g3.tc_t_wing, g3.lambda_wing);
            fprintf('  [L3] testWingFuelVolumeUsesTheL2Toolbox: property=%.6g, toolbox=%.6g\n', s3.wing_fuel_volume, from_toolbox);
            tc.verifyEqual(s3.wing_fuel_volume, from_toolbox, 'AbsTol', 1e-9);
        end

        function testFuelDensityReusesTheBaseTable(tc)
        % [Nicolai & Carichner Table 8.6, p.210] JP-8 = 50 lb/ft^3.
            expected = 50.0;
            received = SubsystemsBase.lookup_fuel_density_lb_per_ft_3('hydrocarbon', 'JP-8');
            fprintf('  [L3] testFuelDensityReusesTheBaseTable: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            fprintf('  [L3] testFuelDensityReusesTheBaseTable: property expected=%.6g, received=%.6g\n', expected, s3.fuel_density);
            tc.verifyEqual(s3.fuel_density, expected, 'AbsTol', 1e-9);
        end

        function testNoBatteryEntryPointAtL3(tc)
        % L3 adds no battery path of its own; a battery design calls
        % SubsystemsL2.compute_battery_volume, whose citation gap is pinned
        % once in TestSubsystemsL2.
            l3_names = {meta.class.fromName('SubsystemsL3').MethodList.Name};
            has_l3_battery = any(strcmp(l3_names, 'compute_battery_volume'));
            fprintf('  [L3] testNoBatteryEntryPointAtL3: SubsystemsL3 battery static expected=absent, received present=%s\n', mat2str(has_l3_battery));
            tc.verifyFalse(has_l3_battery, ...
                'SubsystemsL3 must not duplicate a battery entry point; L2 owns it.');

            l2_names = {meta.class.fromName('SubsystemsL2').MethodList.Name};
            has_l2_battery = any(strcmp(l2_names, 'compute_battery_volume'));
            fprintf('  [L3] testNoBatteryEntryPointAtL3: SubsystemsL2 battery static expected=present, received present=%s\n', mat2str(has_l2_battery));
            tc.verifyTrue(has_l2_battery);
        end

        % ================================================================== %
        % fuel_volume_check -- a two-scalar comparison, no design object.
        % ================================================================== %

        function testFuelVolumeCheckComparesRequiredAgainstAvailable(tc)
            result = SubsystemsL3.fuel_volume_check(20.0, 14.196);
            fprintf('  [L3] testFuelVolumeCheckComparesRequiredAgainstAvailable: required expected=%.6g, received=%.6g\n', 20.0, result.required_vol_ft3);
            tc.verifyEqual(result.required_vol_ft3, 20.0, 'AbsTol', 1e-9);
            fprintf('  [L3] testFuelVolumeCheckComparesRequiredAgainstAvailable: available expected=%.6g, received=%.6g\n', 14.196, result.available_vol_ft3);
            tc.verifyEqual(result.available_vol_ft3, 14.196, 'AbsTol', 1e-9);
            fprintf('  [L3] testFuelVolumeCheckComparesRequiredAgainstAvailable: sufficient expected=false, received=%s\n', mat2str(result.sufficient));
            tc.verifyFalse(result.sufficient, 'required (20 ft^3) exceeds available (14.196 ft^3).');

            sufficient_case = SubsystemsL3.fuel_volume_check(10.0, 14.196);
            fprintf('  [L3] testFuelVolumeCheckComparesRequiredAgainstAvailable: sufficient expected=true, received=%s\n', mat2str(sufficient_case.sufficient));
            tc.verifyTrue(sufficient_case.sufficient);
        end

        function testFuelVolumeCheckErrorsOnNaN(tc)
        % W_energy is NaN until a sizing run sets it, so a NaN required
        % volume must not be silently reported as "sufficient".
            threw = false;
            msg   = '(none thrown)';
            try
                SubsystemsL3.fuel_volume_check(NaN, 100);
            catch ME
                threw = true;
                msg   = ME.message;
            end
            fprintf('  [L3] testFuelVolumeCheckErrorsOnNaN: expected=error, received=%s (%s)\n', mat2str(threw), msg);
            tc.verifyTrue(threw, 'fuel_volume_check must reject a NaN required volume.');
            tc.verifySubstring(msg, 'NaN');
        end

        % ================================================================== %
        % F16SubsystemsL3 wiring / DI / optimization-ready property design.
        % ================================================================== %

        function testF16SubsystemsL3ReadsJSON(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            expected_fuel_name = 'JP-8';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: fuel_name expected=%s, received=%s\n', expected_fuel_name, s3.fuel_name);
            tc.verifyEqual(s3.fuel_name, expected_fuel_name);
            expected_pkg_category = 'Integral tank — shallow fuselage';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: packaging_factor_category expected=%s, received=%s\n', expected_pkg_category, s3.packaging_factor_category);
            tc.verifyEqual(s3.packaging_factor_category, expected_pkg_category);
            expected_avionics_row = 'Fighters';
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: avionics_table_row expected=%s, received=%s\n', expected_avionics_row, s3.avionics_table_row);
            tc.verifyEqual(s3.avionics_table_row, expected_avionics_row);
            fprintf('  [L3] testF16SubsystemsL3ReadsJSON: avionics_components expected=17 boxes, received=%d\n', numel(s3.avionics_components));
            tc.verifyEqual(numel(s3.avionics_components), 17);
        end

        function testF16SubsystemsL3IsConcrete(tc)
        % Every abstract member of SubsystemsBase and SubsystemsModelL3 is
        % satisfied, so the class instantiates and the sizing report runs.
            mc = meta.class.fromName('F16SubsystemsL3');
            fprintf('  [L3] testF16SubsystemsL3IsConcrete: Abstract expected=false, received=%s\n', mat2str(mc.Abstract));
            tc.verifyFalse(mc.Abstract);
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

        function testF16SubsystemsL3FuelVolumeOccupiedTracksWEnergy(tc)
        % A getter takes no argument, so the fuel weight is read off the
        % injected weights object. It must not be cached.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            expected = w3.W_energy / 50.0;
            fprintf('  [L3] testF16SubsystemsL3FuelVolumeOccupiedTracksWEnergy: expected=%.6g, received=%.6g\n', expected, s3.total_fuel_volume_occupied);
            tc.verifyEqual(s3.total_fuel_volume_occupied, expected, 'AbsTol', 1e-9);

            w3.W_energy = 7000;
            fprintf('  [L3] testF16SubsystemsL3FuelVolumeOccupiedTracksWEnergy: after W_energy=7000 expected=%.6g, received=%.6g\n', 140.0, s3.total_fuel_volume_occupied);
            tc.verifyEqual(s3.total_fuel_volume_occupied, 140.0, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL3DerivedPropertiesAreReadOnly(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);

            expectedErrId = 'MATLAB:class:noSetMethod';
            propsToCheck = {'fuselage_usable_fuel_volume', 'wing_fuel_volume', ...
                            'total_fuel_volume_occupied', 'total_design_volume', ...
                            'total_avionics_volume_occupied'};
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
                tc.verifyError(@() setfield(s3, propsToCheck{i}, 999), expectedErrId);
            end
        end

        % ================================================================== %
        % Volume consolidation.
        % ================================================================== %

        function testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            pf = SubsystemsL2.lookup_packaging_factor_nicolai(s3.fuselage_packaging_factor_category);
            expected = s3.get_fuselage_volume() * pf;
            fprintf('  [L3] testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3: packaging factor=%.6g\n', pf);
            fprintf('  [L3] testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3: expected=%.6g, received=%.6g\n', expected, s3.fuselage_usable_fuel_volume);
            tc.verifyEqual(s3.fuselage_usable_fuel_volume, expected, 'AbsTol', 1e-9);
            fprintf('  [L3] testFuselageUsableFuelVolumeAppliesPackagingFactorAtL3: usable=%.6g must be < raw=%.6g\n', s3.fuselage_usable_fuel_volume, s3.get_fuselage_volume());
            tc.verifyLessThan(s3.fuselage_usable_fuel_volume, s3.get_fuselage_volume());
        end

        function testTotalFuelVolumeAvailableSumsFuselageAndWingNeverJustOne(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            fus_term  = s3.fuselage_usable_fuel_volume;
            wing_term = s3.wing_fuel_volume;
            received  = s3.get_total_fuel_volume_available();
            expected  = fus_term + wing_term;
            fprintf('  [L3] testTotalFuelVolumeAvailableSumsFuselageAndWingNeverJustOne: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            fprintf('  [L3] testTotalFuelVolumeAvailableSumsFuselageAndWingNeverJustOne: received=%.6g must differ from fus alone=%.6g\n', received, fus_term);
            tc.verifyNotEqual(received, fus_term);
            fprintf('  [L3] testTotalFuelVolumeAvailableSumsFuselageAndWingNeverJustOne: received=%.6g must differ from wing alone=%.6g\n', received, wing_term);
            tc.verifyNotEqual(received, wing_term);
        end

        function testTotalDesignVolumeSumsWingAndFuselageOnly(tc)
        % total_design_volume is the airframe volume. The avionics group is
        % a separate quantity and is NOT folded into it.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            expected = s3.wing_fuel_volume + s3.get_fuselage_volume();
            fprintf('  [L3] testTotalDesignVolumeSumsWingAndFuselageOnly: expected=%.6g, received=%.6g\n', expected, s3.total_design_volume);
            tc.verifyEqual(s3.total_design_volume, expected, 'AbsTol', 1e-9);
            fprintf('  [L3] testTotalDesignVolumeSumsWingAndFuselageOnly: avionics volume=%.6g must be > 0 and excluded\n', s3.total_avionics_volume_occupied);
            tc.verifyGreaterThan(s3.total_avionics_volume_occupied, 0);
            tc.verifyNotEqual(s3.total_design_volume, expected + s3.total_avionics_volume_occupied);
        end

        function testF16SubsystemsL3FuselageVolumeDiffersFromL2Equivalent(tc)
        % The whole point of the L2 to L3 fidelity refinement: the
        % station-integrated fuselage volume must actually differ from what
        % the L2 envelope-ellipse route gives for the same envelope --
        % otherwise the refinement is dead code.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            [A_top_ellipse, A_side_ellipse] = SubsystemsL2.compute_envelope_projected_areas( ...
                g3.L_fuselage, g3.W_max_fuselage, g3.H_max_fuselage);
            ellipse_equivalent = SubsystemsL2.compute_fuselage_volume_raymer( ...
                A_top_ellipse, A_side_ellipse, g3.L_fuselage);
            received = s3.get_fuselage_volume();
            fprintf('  [L3] testF16SubsystemsL3FuselageVolumeDiffersFromL2Equivalent: received=%.6g must differ from ellipse_equivalent=%.6g\n', received, ellipse_equivalent);
            tc.verifyNotEqual(received, ellipse_equivalent, ...
                'L3 station-integrated fuselage volume must differ from the L2 ellipse approximation for the real F-16 station data.');
        end

        % ================================================================== %
        % Avionics component buildup -- L3's own route [Nicolai Table 8.8].
        % ================================================================== %

        function testAvionicsWeightAndVolumeComeFromTheComponentBuildup(tc)
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);

            [W_net, parts_w] = s3.get_avionics_weight_component_buildup();
            [V_net, parts_v] = s3.get_total_avionics_volume_component_buildup();

            fprintf('  [L3] testAvionicsWeightAndVolumeComeFromTheComponentBuildup: weight property=%.6g, buildup=%.6g\n', s3.avionics_weight, W_net);
            tc.verifyEqual(s3.avionics_weight, W_net, 'AbsTol', 1e-9);
            fprintf('  [L3] testAvionicsWeightAndVolumeComeFromTheComponentBuildup: volume property=%.6g, buildup=%.6g\n', s3.total_avionics_volume_occupied, V_net);
            tc.verifyEqual(s3.total_avionics_volume_occupied, V_net, 'AbsTol', 1e-9);

            % Both methods report the same per-box table.
            fprintf('  [L3] testAvionicsWeightAndVolumeComeFromTheComponentBuildup: table rows expected=%d, received=%d\n', height(parts_w), height(parts_v));
            tc.verifyEqual(height(parts_v), height(parts_w));
            tc.verifyEqual(parts_v.Properties.VariableNames, ...
                {'Component', 'Weight_lbf', 'Volume_ft3', 'Power_W'});

            % Each net is a FLOOR: a box with no sourced figure reads NaN and
            % drops out, so the net must be the sum of the finite entries only.
            fprintf('  [L3] testAvionicsWeightAndVolumeComeFromTheComponentBuildup: weight net=%.6g from %d of %d boxes\n', W_net, sum(isfinite(parts_w.Weight_lbf)), height(parts_w));
            tc.verifyEqual(W_net, sum(parts_w.Weight_lbf(isfinite(parts_w.Weight_lbf))), 'AbsTol', 1e-9);
            fprintf('  [L3] testAvionicsWeightAndVolumeComeFromTheComponentBuildup: volume net=%.6g from %d of %d boxes\n', V_net, sum(isfinite(parts_v.Volume_ft3)), height(parts_v));
            tc.verifyEqual(V_net, sum(parts_v.Volume_ft3(isfinite(parts_v.Volume_ft3))), 'AbsTol', 1e-9);

            tc.verifyGreaterThan(W_net, 0);
            tc.verifyGreaterThan(V_net, 0);
        end

        function testAvionicsGroupDoesNotUseTheWeightFractionRoute(tc)
        % L1 and L2 size the avionics group as a fraction of W_empty. L3
        % weighs real boxes, so the two must not agree by construction.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            fraction_route = SubsystemsL1.compute_avionics_weight( ...
                                 s3.avionics_weight_fraction, w3.get_OEW(w3.W_TO));
            fprintf('  [L3] testAvionicsGroupDoesNotUseTheWeightFractionRoute: buildup=%.6g, fraction route=%.6g\n', s3.avionics_weight, fraction_route);
            tc.verifyNotEqual(s3.avionics_weight, fraction_route, ...
                'L3 must weigh its boxes, not reuse the L1/L2 weight fraction.');
        end

        function testAvionicsDensityIsDerivedNotLookedUp(tc)
        % L3 has both a weight and a volume from the buildup, so the density
        % is their ratio. Reading the L1/L2 table constant here would be a
        % fidelity inversion.
            [g3, w3] = TestSubsystemsL3.makeGeomAndWeights();
            s3 = F16SubsystemsL3(f16a_spec_path(3), g3, w3);
            expected = s3.avionics_weight / s3.total_avionics_volume_occupied;
            fprintf('  [L3] testAvionicsDensityIsDerivedNotLookedUp: expected=%.6g, received=%.6g\n', expected, s3.avionics_density);
            tc.verifyEqual(s3.avionics_density, expected, 'AbsTol', 1e-9);
            fprintf('  [L3] testAvionicsDensityIsDerivedNotLookedUp: received=%.6g must differ from the L2 table constant=%.6g\n', s3.avionics_density, SubsystemsL2.AVIONICS_DENSITY);
            tc.verifyNotEqual(s3.avionics_density, SubsystemsL2.AVIONICS_DENSITY);
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
            g3   = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
            w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO     = 31377;
            w3.W_energy = 6296.30;
        end

    end

end

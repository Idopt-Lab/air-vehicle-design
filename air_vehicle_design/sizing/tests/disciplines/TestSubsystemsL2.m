classdef TestSubsystemsL2 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL2  Unit tests for SubsystemsL2, SubsystemsModelL2, and F16SubsystemsL2.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green, with ONE deliberate
%   exception (testTODO_BatteryVolumetricEnergyDensityNotInRepo, clearly
%   labeled below). Companion Tier-2 report:
%   examples/F16A/subsystems_brandt_comparison.m (informational, NOT here).
%
%   Every "expected" value below is HAND-COMPUTED from the cited formula
%   with independently-chosen scalars (deliberately NOT the F-16's own
%   geometry numbers, except in the small number of explicit end-to-end
%   wiring tests that construct real F16GeomL2/F16WeightsL2/F16SubsystemsL2
%   objects to check the DI plumbing and the optimization-ready property
%   design, not to re-derive a formula).
%
%   Low-level statics (compute_raymer_fuselage_volume, compute_wing_fuel_volume,
%   compute_envelope_projected_areas, lookup_packaging_factor) take a plain
%   STRUCT standing in for "obj" where the toolbox method only reads
%   properties (no method calls) -- dot-indexing a struct field behaves
%   identically to a real object property read. Where a method calls
%   obj.fuel_weight_source.OEW(...), the struct's field holds an anonymous
%   function handle (struct.OEW = @(w) ...; struct.OEW(x) invokes it) so no
%   real WeightsBase-typed object is needed for those cases either.
%
%   Sources: fuselage-internal raw volume [Raymer 6th ed. Eq. 7.14]; wing-
%   internal fuel volume [Roskam, Airplane Design Part II, Ch.6, Eq. 6.2/6.3];
%   fuel-tank packaging factor / fuel density [Nicolai & Carichner, Ch.8,
%   p.210]; avionics weight fraction [Raymer Table 11.6] with L2's own flat
%   Nicolai avionics density (45 lb/ft^3, Sec.8.1.11).

    methods (Test)

        % ================================================================== %
        % LOW-LEVEL statics -- hand-picked scalars, independent of any real
        % F-16 geometry number.
        % ================================================================== %

        function testComputeRaymerFuselageVolumeHandComputed(tc)
        % [Raymer 6th ed. Eq. 7.14]  V = 3.4*(A_top*A_side)/(4*L).
        %   A_top=100, A_side=50, L=20 -> 3.4*5000/80 = 212.5 ft^3 exactly.
            received = SubsystemsL2.compute_raymer_fuselage_volume(100, 50, 20);
            tc.verifyEqual(received, 212.5, 'AbsTol', 1e-9);
        end

        function testComputeRaymerFuselageVolumeGuardsPositivity(tc)
            tc.verifyError(@() SubsystemsL2.compute_raymer_fuselage_volume(0, 50, 20), ...
                'MATLAB:validators:mustBePositive');
            tc.verifyError(@() SubsystemsL2.compute_raymer_fuselage_volume(100, 50, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        function testComputeEnvelopeProjectedAreasHandComputed(tc)
        % (pi/4)*L*W and (pi/4)*L*H -- elliptical-footprint identity.
        %   L=10, W=4, H=2 -> A_top = 10*pi, A_side = 5*pi.
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas(10, 4, 2);
            tc.verifyEqual(A_top,  10*pi, 'AbsTol', 1e-9);
            tc.verifyEqual(A_side, 5*pi,  'AbsTol', 1e-9);
        end

        function testComputeWingFuelVolumeUniformTc(tc)
        % [Roskam Eq. 6.2/6.3], tau_w = tc_t/tc_r. Uniform-tc case (tau_w=1):
        %   S=100, b=20, tc_r=tc_t=0.05, lambda=0.25.
        %   0.54*(100^2/20)*0.05 = 0.54*500*0.05 = 13.5
        %   fraction = (1+0.25+0.25^2)/(1.25)^2 = 1.3125/1.5625 = 0.84 exactly
        %   V = 13.5*0.84 = 11.34 ft^3 exactly.
            received = SubsystemsL2.compute_wing_fuel_volume(100, 20, 0.05, 0.05, 0.25);
            tc.verifyEqual(received, 11.34, 'AbsTol', 1e-9);
        end

        function testComputeWingFuelVolumeVariableTc(tc)
        % Non-uniform tc case, tau_w = tc_t/tc_r = 0.02/0.08 = 0.25:
        %   S=150, b=25, tc_r=0.08, tc_t=0.02, lambda=0.4.
        %   0.54*(150^2/25)*0.08 = 0.54*900*0.08 = 38.88
        %   sqrt(tau_w)=0.5; num = 1 + 0.4*0.5 + 0.4^2*0.25 = 1+0.2+0.04 = 1.24
        %   den = 1.4^2 = 1.96;  fraction = 1.24/1.96 = 31/49
        %   V = 38.88*31/49 = 1205.28/49 = 24.5975510204 ft^3.
            expected = 1205.28/49;
            received = SubsystemsL2.compute_wing_fuel_volume(150, 25, 0.08, 0.02, 0.4);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testComputeWingFuelVolumeTauConventionIsTipOverRoot(tc)
        % REGRESSION GUARD for the item-6 convention warning
        % (docs/subplans/09_subsystems.md): Eq. 6.3 defines
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
            received_swapped = SubsystemsL2.compute_wing_fuel_volume(150, 25, 0.02, 0.08, 0.4);
            tc.verifyEqual(received_swapped, expected_swapped, 'AbsTol', 1e-6);

            % The un-swapped (root=0.08, tip=0.02) case from the test above:
            received_unswapped = SubsystemsL2.compute_wing_fuel_volume(150, 25, 0.08, 0.02, 0.4);
            tc.verifyNotEqual(received_swapped, received_unswapped, ...
                ['Swapping tc_r/tc_t must change the result (tau_w = tip/root is direction-' ...
                 'sensitive) -- if these matched, the code would have silently "fixed" Eq. 6.3''s ' ...
                 'convention to Roskam Eq. 12.1''s opposite root/tip definition.']);
        end

        function testComputeWingFuelVolumeGuardsPositivity(tc)
            tc.verifyError(@() SubsystemsL2.compute_wing_fuel_volume(0, 20, 0.05, 0.05, 0.25), ...
                'MATLAB:validators:mustBePositive');
            tc.verifyError(@() SubsystemsL2.compute_wing_fuel_volume(100, 20, 0, 0.05, 0.25), ...
                'MATLAB:validators:mustBePositive');
        end

        function testLookupPackagingFactorAllFiveRows(tc)
        % [Nicolai & Carichner, p.210, unnumbered "Fuel Tank Packaging
        % Factors" table]. Full 5-row table.
            tc.verifyEqual(SubsystemsL2.lookup_packaging_factor('Integral tank — shallow fuselage'), 0.80, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL2.lookup_packaging_factor('Integral tank — deep fuselage'),     0.85, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL2.lookup_packaging_factor('Integral tank — wing'),               0.75, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL2.lookup_packaging_factor('Bladder tank — fuselage'),            0.75, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL2.lookup_packaging_factor('Bladder tank — wing'),                 0.65, 'AbsTol', 1e-9);
        end

        function testLookupPackagingFactorUnknownCategoryErrors(tc)
            tc.verifyError(@() SubsystemsL2.lookup_packaging_factor('Integral tank — nose'), ...
                'SubsystemsL2:unknownPackagingCategory');
        end

        % ================================================================== %
        % HIGH-LEVEL toolbox statics -- struct-based "obj", geom sub-struct.
        % ================================================================== %

        function testFuselageRawVolumeHighLevel(tc)
        % Composition of the two low-level statics above:
        %   L=10, W=4, H=2 -> A_top=10*pi, A_side=5*pi
        %   V = 3.4*(10*pi*5*pi)/(4*10) = 3.4*50*pi^2/40 = 4.25*pi^2 ft^3.
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2);
            expected = 4.25*pi^2;
            tc.verifyEqual(SubsystemsL2.fuselage_raw_volume(obj), expected, 'AbsTol', 1e-9);
        end

        function testFuselageUsableFuelVolumeAppliesPackagingFactor(tc)
        % raw * packaging_factor -- MUST be applied before any comparison
        % against a required fuel volume (item 5b; legacy code never applied
        % one at all -- "Legacy Bugs to Avoid" addendum).
        %   raw = 4.25*pi^2 (from the test above).
        %   shallow fuselage (0.80) -> 3.4*pi^2
        %   deep fuselage    (0.85) -> 3.6125*pi^2
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2);
            raw = 4.25*pi^2;

            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            tc.verifyEqual(SubsystemsL2.fuselage_usable_fuel_volume(obj), raw*0.80, 'AbsTol', 1e-9);

            obj.packaging_factor_category = 'Integral tank — deep fuselage';
            tc.verifyEqual(SubsystemsL2.fuselage_usable_fuel_volume(obj), raw*0.85, 'AbsTol', 1e-9);

            % Regression guard: must not equal the raw (unpackaged) volume.
            tc.verifyNotEqual(SubsystemsL2.fuselage_usable_fuel_volume(obj), raw, ...
                'fuselage_usable_fuel_volume must not silently equal the raw geometric volume.');
        end

        function testWingFuelVolumeHighLevel(tc)
            obj.geom = struct('S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            tc.verifyEqual(SubsystemsL2.wing_fuel_volume(obj), 11.34, 'AbsTol', 1e-9);
        end

        function testAvionicsWeightFractionReusesL1Lookup(tc)
        % Level-agnostic -- must equal SubsystemsL1's own lookup, not a
        % duplicated/independent table.
            obj = struct('avionics_table_row', 'Fighters');
            tc.verifyEqual(SubsystemsL2.avionics_weight_fraction(obj), 0.055, 'AbsTol', 1e-9);
        end

        function testAvionicsDensityL2IsFlatNicolai45(tc)
        % [Nicolai & Carichner, Sec.8.1.11, p.210] flat 45 lb/ft^3 -- distinct
        % from L1's Raymer-range-average 37.5 (fidelity-split guard).
            obj = struct();
            tc.verifyEqual(SubsystemsL2.avionics_density(obj), 45.0, 'AbsTol', 1e-9);
        end

        function testAvionicsWeightAndVolumeHandComputed(tc)
        % avionics_weight = fraction * W_empty, W_empty read via
        % obj.fuel_weight_source.OEW(obj.fuel_weight_source.W_TO) --
        % mocked with a struct field holding an anonymous function handle.
        %   fraction (Fighters) = 0.055; W_empty (mocked) = 12000
        %   -> W_avionics = 660 lbf exactly; Vol = 660/45 = 14.6666666667 ft^3.
            obj.avionics_table_row = 'Fighters';
            obj.fuel_weight_source = struct('W_TO', 20000, 'OEW', @(~) 12000);
            tc.verifyEqual(SubsystemsL2.avionics_weight(obj), 660, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL2.avionics_volume(obj), 660/45, 'AbsTol', 1e-9);
        end

        function testFuelDensityL2ReusesL1Table(tc)
            obj = struct('fuel_type', 'JP-5');
            tc.verifyEqual(SubsystemsL2.fuel_density(obj), 51.1, 'AbsTol', 1e-9);
        end

        function testFuelVolumeFromWeightHandComputed(tc)
        % Definitional weight/density conversion -- declared on
        % SubsystemsBase (2026-08-03). NO packaging factor applied (that
        % only applies to the GEOMETRIC raw volume, a different quantity).
        %   JP-8 (density 50.0): 400 / 50.0 = 8.0 ft^3 exactly.
            obj = struct('fuel_type', 'JP-8');
            tc.verifyEqual(SubsystemsL2.fuel_volume_from_weight(obj, 400), 8.0, 'AbsTol', 1e-9);
        end

        function testFuelVolumeIsSumOfFuselageAndWingTerms(tc)
        % fuel_volume(obj) = fuselage_usable_fuel_volume + wing_fuel_volume --
        % the SAME sum fuel_volume_check reports as available_vol_ft3, now
        % exposed as its own SubsystemsBase-declared property.
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';

            fus_term  = SubsystemsL2.fuselage_usable_fuel_volume(obj);
            wing_term = SubsystemsL2.wing_fuel_volume(obj);
            tc.verifyEqual(SubsystemsL2.fuel_volume(obj), fus_term + wing_term, 'AbsTol', 1e-9);
        end

        % ================================================================== %
        % internal_volume / fuel_volume_check -- the legacy-bug guards.
        % "assert fuel_volume_check sums BOTH fuselage AND wing volume, never
        % just one" and "avionics volume is actually present and non-zero in
        % whatever total is returned, not silently dropped."
        % ================================================================== %

        function testInternalVolumeSumsAllThreeTermsIncludingAvionics(tc)
        % LEGACY BUG 1 GUARD: avionics volume computed-but-dropped.
        %   fuselage_usable = 4.25*pi^2*0.80 = 3.4*pi^2
        %   wing            = 11.34
        %   avionics        = 660/45 = 14.6666666667
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.avionics_table_row        = 'Fighters';
            obj.fuel_weight_source        = struct('W_TO', 20000, 'OEW', @(~) 12000);

            fus_term = SubsystemsL2.fuselage_usable_fuel_volume(obj);
            wing_term = SubsystemsL2.wing_fuel_volume(obj);
            av_term  = SubsystemsL2.avionics_volume(obj);

            tc.verifyGreaterThan(av_term, 0, 'Avionics volume term must be nonzero.');

            received = SubsystemsL2.internal_volume(obj);
            expected = fus_term + wing_term + av_term;
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);

            % LEGACY BUG 1, explicit guard: total must be STRICTLY greater
            % than fuselage+wing alone -- avionics must not have been
            % silently dropped from the sum.
            tc.verifyGreaterThan(received, fus_term + wing_term, ...
                'internal_volume must include a nonzero avionics contribution -- legacy code dropped this term.');
        end

        function testFuelVolumeCheckSumsFuselageAndWingNeverJustOne(tc)
        % LEGACY BUG 5 / item 5b GUARD: the legacy code compared RAW
        % (unpackaged) fuselage volume directly, and never demonstrably
        % summed fuselage+wing together. Assert 'available' equals the SUM
        % and differs from EITHER term alone.
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.fuel_type                 = 'JP-8';
            obj.fuel_weight_source        = struct('W_energy', 2000);

            fus_term  = SubsystemsL2.fuselage_usable_fuel_volume(obj);   % 3.4*pi^2 = 33.5566549637
            wing_term = SubsystemsL2.wing_fuel_volume(obj);              % 11.34

            result = SubsystemsL2.fuel_volume_check(obj);
            tc.verifyEqual(result.available_vol_ft3, fus_term + wing_term, 'AbsTol', 1e-9);
            tc.verifyNotEqual(result.available_vol_ft3, fus_term, ...
                'fuel_volume_check must not check fuselage volume alone.');
            tc.verifyNotEqual(result.available_vol_ft3, wing_term, ...
                'fuel_volume_check must not check wing volume alone.');

            % Consolidation check (2026-08-03): available_vol_ft3 must now
            % equal the standalone fuel_volume(obj) property exactly -- both
            % are the same sum, computed once.
            tc.verifyEqual(result.available_vol_ft3, SubsystemsL2.fuel_volume(obj), 'AbsTol', 1e-9);

            % required_vol_ft3 = W_energy/density = 2000/50 = 40; 44.8967 >= 40 -> sufficient.
            tc.verifyEqual(result.required_vol_ft3, 40.0, 'AbsTol', 1e-9);
            tc.verifyEqual(result.required_vol_ft3, ...
                SubsystemsL2.fuel_volume_from_weight(obj, obj.fuel_weight_source.W_energy), 'AbsTol', 1e-9);
            tc.verifyTrue(result.sufficient, 'available (44.90 ft^3) should exceed required (40 ft^3).');
        end

        function testFuelVolumeCheckInsufficientCase(tc)
        % Same geometry as above, but a larger required fuel weight (3000 lb
        % -> required = 60 ft^3) exceeds available (~44.90 ft^3) -> false.
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.fuel_type                 = 'JP-8';
            obj.fuel_weight_source        = struct('W_energy', 3000);

            result = SubsystemsL2.fuel_volume_check(obj);
            tc.verifyEqual(result.required_vol_ft3, 60.0, 'AbsTol', 1e-9);
            tc.verifyFalse(result.sufficient, 'required (60 ft^3) exceeds available (~44.90 ft^3).');
        end

        function testFuelVolumeCheckErrorsWhenWEnergyNaN(tc)
            obj.geom = struct('L_fuselage', 10, 'W_max_fuselage', 4, 'H_max_fuselage', 2, ...
                               'S_ref', 100, 'b_wing', 20, 'tc_r_wing', 0.05, 'tc_t_wing', 0.05, 'lambda_wing', 0.25);
            obj.packaging_factor_category = 'Integral tank — shallow fuselage';
            obj.fuel_type                 = 'JP-8';
            obj.fuel_weight_source        = struct('W_energy', NaN);
            tc.verifyError(@() SubsystemsL2.fuel_volume_check(obj), 'SubsystemsL2:fuelWeightNotSet');
        end

        % ------------------------------------------------------------------ %
        % DELIBERATE TODO -- battery volumetric energy density (subplan
        % Equations & Citations item 7). NOT a failure to fix -- this test
        % PINS the documented, correctly-erroring citation-gap behavior:
        % SubsystemsL2.battery_volume must refuse to fabricate a coefficient
        % and must error with its documented identifier. If this test ever
        % goes red because battery_volume stops erroring, that means someone
        % implemented a real formula without updating this test -- update
        % the test, don't just delete it.
        % ------------------------------------------------------------------ %

        function testTODO_BatteryVolumetricEnergyDensityNotInRepo(tc)
        %TESTTODO_BATTERYVOLUMETRICENERGYDENSITYNOTINREPO  Documented citation
        %   GAP (docs/subplans/09_subsystems.md Equations & Citations item 7).
        %
        %   WHAT IS MISSING: no citable BATTERY VOLUMETRIC energy density
        %   (kWh/ft^3, kWh/L) or pack density (lb/ft^3) exists anywhere in
        %   this repo to convert a required battery energy into a volume --
        %   only GRAVIMETRIC specific energy is cited [Nicolai & Carichner,
        %   Table 14.2, p.363, batteries 0.27 kWh/lb]. Re-confirmed still
        %   open (Casey, 2026-08-03) after re-scanning all 31 temp_AI
        %   reference-extract files.
        %
        %   HOW THIS TEST DOCUMENTS IT: SubsystemsL2.battery_volume (and
        %   SubsystemsL3.battery_volume, which reuses it identically) is
        %   documented to error rather than fabricate a coefficient. This
        %   test PINS that correct, current behavior with the documented
        %   identifier -- matching the convention of
        %   TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo (a
        %   clearly-labeled marker for an open citation gap), adapted to
        %   this gap's shape: a live error() call rather than a comment-only
        %   TODO. Resolving the gap means supplying a citable volumetric
        %   energy/pack density, implementing the real formula, and
        %   REPLACING this test's verifyError with a hand-computed
        %   expected-value check -- do not silently delete this test without
        %   doing that.
            tc.verifyError(@() SubsystemsL2.battery_volume(struct(), 10), ...
                'SubsystemsL2:batteryVolumetricDensityNotAvailable', ...
                ['TODO (documented gap, EXPECTED to error): no citable battery volumetric ' ...
                 'energy density exists in this repo. docs/subplans/09_subsystems.md Equations ' ...
                 '& Citations item 7.']);
        end

        % ================================================================== %
        % F16SubsystemsL2 wiring / DI / optimization-ready property design.
        % ================================================================== %

        function testF16SubsystemsL2ReadsJSON(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyEqual(s2.fuel_type, 'JP-8');
            tc.verifyEqual(s2.packaging_factor_category, 'Integral tank — shallow fuselage');
            tc.verifyEqual(s2.avionics_table_row, 'Fighters');
        end

        function testF16SubsystemsL2ConstructorRequiresAllThreeArgs(tc)
            tc.verifyError(@() F16SubsystemsL2(), 'MATLAB:minrhs');
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2)), 'MATLAB:minrhs');
            [g2, ~] = TestSubsystemsL2.makeGeomAndWeights();
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g2), 'MATLAB:minrhs');
        end

        function testF16SubsystemsL2WrongGeomTierErrorsAtConstruction(tc)
        % geom is typed (1,1) GeometryModelL2 -- an L1 or L3 geometry object
        % must fail at CONSTRUCTION (mirrors TestWeightsL2.
        % testWrongGeomTierErrorsAtConstruction).
            [~, w2] = TestSubsystemsL2.makeGeomAndWeights();
            g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            prop = F16PropL2(f16a_spec_path(2));
            g3 = F16GeomL3(f16a_spec_path(3), prop);
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g1, w2), ...
                'MATLAB:validation:UnableToConvert');
            tc.verifyError(@() F16SubsystemsL2(f16a_spec_path(2), g3, w2), ...
                'MATLAB:validation:UnableToConvert');
        end

        function testF16SubsystemsL2DerivedPropertiesLiveRecompute(tc)
        % Mutate an input in place and verify a Dependent getter tracks it
        % with NO reconstruction.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            v0 = s2.fuselage_usable_fuel_volume;

            g2.W_max_fuselage = g2.W_max_fuselage + 1;   % optimizer-style mutation
            tc.verifyNotEqual(s2.fuselage_usable_fuel_volume, v0, ...
                'fuselage_usable_fuel_volume must recompute live after geom.W_max_fuselage mutates.');

            fd0 = s2.fuel_density;
            s2.fuel_type = 'JP-5';
            tc.verifyEqual(s2.fuel_density, 51.1, 'AbsTol', 1e-9);
            tc.verifyNotEqual(s2.fuel_density, fd0, 'fuel_density must recompute live after fuel_type mutates.');
        end

        function testF16SubsystemsL2DerivedPropertiesAreReadOnly(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyError(@() setfield(s2, 'fuselage_raw_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(s2, 'wing_fuel_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(s2, 'avionics_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(s2, 'fuel_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testF16SubsystemsL2InternalVolumeIncludesAvionics(tc)
        % End-to-end guard for Legacy Bug 1 through the REAL Tier-3 class.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyGreaterThan(s2.avionics_volume, 0);
            tc.verifyGreaterThan(s2.internal_volume, s2.fuselage_usable_fuel_volume + s2.wing_fuel_volume);
        end

        function testF16SubsystemsL2FuelVolumePropertyAndInternalVolumeConsolidation(tc)
        % fuel_volume (added 2026-08-03, SubsystemsBase) must equal
        % fuselage_usable_fuel_volume + wing_fuel_volume exactly, and
        % internal_volume must equal fuel_volume + avionics_volume exactly --
        % the consolidated form internal_volume() now uses internally.
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyEqual(s2.fuel_volume, s2.fuselage_usable_fuel_volume + s2.wing_fuel_volume, 'AbsTol', 1e-9);
            tc.verifyEqual(s2.internal_volume, s2.fuel_volume + s2.avionics_volume, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL2FuelVolumeFromWeightMethod(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyEqual(s2.fuel_volume_from_weight(500), 500 / s2.fuel_density, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL2IsaChecks(tc)
            [g2, w2] = TestSubsystemsL2.makeGeomAndWeights();
            s2 = F16SubsystemsL2(f16a_spec_path(2), g2, w2);
            tc.verifyTrue(isa(s2, 'SubsystemsBase'));
            tc.verifyTrue(isa(s2, 'SubsystemsModelL2'));
            tc.verifyFalse(isa(s2, 'SubsystemsModelL1'));
            tc.verifyTrue(isa(s2, 'handle'));
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

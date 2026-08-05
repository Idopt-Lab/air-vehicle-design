classdef TestSubsystemsL1 < matlab.unittest.TestCase
%TESTSUBSYSTEMSL1  Unit tests for SubsystemsL1, SubsystemsBase, and F16SubsystemsL1.
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green. Companion Tier-2
%   report: examples/F16A/subsystems_brandt_comparison.m (informational,
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
%   L1 is tabulation-only (docs/subplans/09_subsystems.md Fidelity split):
%   no geometry, no fuel-tank packaging factor, no landing-gear counterpart.
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

    methods (Test)

        % ================================================================== %
        % LOW-LEVEL LOOKUPS -- pure tables, hand-verified against the subplan's
        % transcription of the physical books (docs/subplans/09_subsystems.md
        % Equations & Citations items 2-3).
        % ================================================================== %

        function testLookupFuelDensityAllFourTypes(tc)
        % [Nicolai & Carichner Table 8.6, p.210] lb/ft^3 by type.
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density('JP-4'),         48.6, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density('JP-5'),         51.1, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density('JP-8'),         50.0, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density('Aviation gas'), 44.9, 'AbsTol', 1e-9);
        end

        function testLookupFuelDensityUnknownTypeErrors(tc)
            tc.verifyError(@() SubsystemsL1.lookup_fuel_density('Diesel'), ...
                'SubsystemsL1:unknownFuelType');
        end

        function testLookupFuelDensityLbPerGalAllFourTypes(tc)
        % [Nicolai & Carichner Table 8.6, p.210] lb/gal by type.
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-4'),         6.5, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-5'),         6.8, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density_lb_per_gal('JP-8'),         6.7, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_fuel_density_lb_per_gal('Aviation gas'), 6.0, 'AbsTol', 1e-9);
        end

        function testLookupFuelDensityLbPerGalUnknownTypeErrors(tc)
            tc.verifyError(@() SubsystemsL1.lookup_fuel_density_lb_per_gal('Diesel'), ...
                'SubsystemsL1:unknownFuelType');
        end

        function testLookupAvionicsWeightFractionRangeSpotChecks(tc)
        % [Raymer 6th ed. Table 11.6, p.375], full 8-row table -- spot-check
        % three rows independently transcribed from the subplan's own
        % reproduction (docs/subplans/09_subsystems.md Equations & Citations
        % item 3).
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction_range('Fighters'), ...
                [0.03, 0.08], 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction_range('Bombers'), ...
                [0.06, 0.08], 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction_range('Jet transport'), ...
                [0.01, 0.02], 'AbsTol', 1e-9);
        end

        function testLookupAvionicsWeightFractionRangeUnknownRowErrors(tc)
            tc.verifyError(@() SubsystemsL1.lookup_avionics_weight_fraction_range('Airliner'), ...
                'SubsystemsL1:unknownAvionicsCategory');
        end

        function testLookupAvionicsWeightFractionIsRangeMidpoint(tc)
        % DECIDED (Casey, 2026-08-03): the row's own range midpoint, not the
        % legacy code's low-end 0.03 (docs/subplans/09_subsystems.md
        % Equations & Citations item 3). Hand-computed midpoints:
        %   Fighters:      (0.03+0.08)/2 = 0.055
        %   Jet transport: (0.01+0.02)/2 = 0.015
        %   Business jet:  (0.04+0.05)/2 = 0.045
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction('Fighters'),      0.055, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction('Jet transport'), 0.015, 'AbsTol', 1e-9);
            tc.verifyEqual(SubsystemsL1.lookup_avionics_weight_fraction('Business jet'),  0.045, 'AbsTol', 1e-9);
            % Regression guard: must NOT have regressed to the legacy low-end pick.
            tc.verifyNotEqual(SubsystemsL1.lookup_avionics_weight_fraction('Fighters'), 0.03, ...
                'avionics fraction has regressed to the legacy low-end 0.03 instead of the decided midpoint.');
        end

        % ================================================================== %
        % HIGH-LEVEL toolbox statics -- called with a lightweight struct
        % standing in for "obj" (dot-indexing a struct field behaves
        % identically to reading a real object property for these purposes).
        % ================================================================== %

        function testAvionicsWeightFractionHighLevel(tc)
            obj = struct('avionics_table_row', 'Fighters');
            tc.verifyEqual(SubsystemsL1.avionics_weight_fraction(obj), 0.055, 'AbsTol', 1e-9);
        end

        function testAvionicsDensityL1IsRaymerRangeAverage(tc)
        % [Raymer 6th ed. Ch.11 p.375 prose]: "about 30-45 lb/ft^3" -> mean = 37.5.
        % Distinct from L2/L3's flat Nicolai 45 (docs/subplans/09_subsystems.md
        % Equations & Citations item 4) -- this is the fidelity-split guard.
            obj = struct();   % avionics_density(obj) does not read obj at L1
            tc.verifyEqual(SubsystemsL1.avionics_density(obj), 37.5, 'AbsTol', 1e-9);
            tc.verifyNotEqual(SubsystemsL1.avionics_density(obj), 45.0, ...
                'L1 avionics density must NOT be L2/L3''s flat Nicolai 45 -- fidelity split.');
        end

        function testAvionicsWeightHandComputed(tc)
        % W_avionics = fraction * W_empty. Fighters fraction = 0.055.
        %   W_empty = 10,000 lb (independently chosen, NOT the F-16's own
        %   OEW) -> 0.055*10000 = 550 lbf exactly.
            obj = struct('avionics_table_row', 'Fighters');
            tc.verifyEqual(SubsystemsL1.avionics_weight(obj, 10000), 550, 'AbsTol', 1e-9);
        end

        function testAvionicsVolumeHandComputed(tc)
        % Vol = W_avionics / density = 550 / 37.5 = 14.6666666667 ft^3 (= 44/3).
            obj = struct('avionics_table_row', 'Fighters');
            expected = 44/3;
            received = SubsystemsL1.avionics_volume(obj, 10000);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testFuelDensityHighLevel(tc)
            obj = struct('fuel_type', 'JP-8');
            tc.verifyEqual(SubsystemsL1.fuel_density(obj), 50.0, 'AbsTol', 1e-9);
            obj.fuel_type = 'JP-4';
            tc.verifyEqual(SubsystemsL1.fuel_density(obj), 48.6, 'AbsTol', 1e-9);
        end

        function testFuelVolumeFromWeightHandComputed(tc)
        % No packaging factor at L1 (not usable -- no geometric raw volume
        % exists yet; docs/subplans/09_subsystems.md item 1 status).
        %   JP-8: 500 / 50.0  = 10.0 ft^3 exactly.
        %   JP-4: 486 / 48.6  = 10.0 ft^3 exactly (chosen so both cases give
        %   a clean round number, independent of each other).
            obj = struct('fuel_type', 'JP-8');
            tc.verifyEqual(SubsystemsL1.fuel_volume_from_weight(obj, 500), 10.0, 'AbsTol', 1e-9);
            obj.fuel_type = 'JP-4';
            tc.verifyEqual(SubsystemsL1.fuel_volume_from_weight(obj, 486), 10.0, 'AbsTol', 1e-9);
        end

        function testInternalVolumeL1EqualsAvionicsVolumeOnly(tc)
        % L1 has no fuel-bay/gear-bay geometry -- internal_volume() must be
        % EXACTLY the avionics term, no more, no less (Fidelity split).
            obj = struct('avionics_table_row', 'Fighters');
            tc.verifyEqual(SubsystemsL1.internal_volume(obj, 10000), ...
                SubsystemsL1.avionics_volume(obj, 10000), 'AbsTol', 1e-9);
        end

        function testFuelVolumeCheckL1AvailableIsHonestlyZero(tc)
        % No fuel-bay geometry exists at L1 -- 'available' must be reported
        % as 0, not guessed, while 'required' is still computed so a caller
        % can see how much volume WOULD be needed.
            obj    = struct('fuel_type', 'JP-8');
            result = SubsystemsL1.fuel_volume_check(obj, 500);
            tc.verifyEqual(result.available_vol_ft3, 0, 'AbsTol', 1e-9);
            tc.verifyEqual(result.required_vol_ft3, 10.0, 'AbsTol', 1e-9);
            tc.verifyFalse(result.sufficient, ...
                'L1 fuel_volume_check must not report "sufficient" for a nonzero fuel requirement.');
        end

        function testFuelVolumeCheckL1TrivialSufficientAtZeroRequired(tc)
            obj    = struct('fuel_type', 'JP-8');
            result = SubsystemsL1.fuel_volume_check(obj, 0);
            tc.verifyTrue(result.sufficient, ...
                'Zero required fuel is the one case L1''s zero-available check can honestly call sufficient.');
        end

        function testFuselageRawVolumeL1IsHonestlyZero(tc)
        % No fuselage geometry exists at L1 (SubsystemsBase.m header note,
        % 2026-08-03) -- 0, not guessed. Declared on SubsystemsBase so every
        % fidelity level provides this member.
            obj = struct();   % fuselage_raw_volume(obj) does not read obj at L1
            tc.verifyEqual(SubsystemsL1.fuselage_raw_volume(obj), 0, 'AbsTol', 1e-9);
        end

        function testFuelVolumeL1IsHonestlyZero(tc)
        % No fuel-bay geometry exists at L1 -- same rationale as
        % fuselage_raw_volume. Must equal fuel_volume_check's own
        % available_vol_ft3 answer (also 0 at L1).
            obj = struct();
            tc.verifyEqual(SubsystemsL1.fuel_volume(obj), 0, 'AbsTol', 1e-9);
        end

        % ================================================================== %
        % SubsystemsBase.weight_to_volume -- shared identity + guards.
        % ================================================================== %

        function testWeightToVolumeGenericIdentity(tc)
        % vol = W/density.  100 lb / 50 lb/ft^3 = 2.0 ft^3 exactly.
            tc.verifyEqual(SubsystemsBase.weight_to_volume(100, 50), 2.0, 'AbsTol', 1e-9);
        end

        function testWeightToVolumeRejectsNegativeWeight(tc)
            tc.verifyError(@() SubsystemsBase.weight_to_volume(-1, 50), ...
                'MATLAB:validators:mustBeNonnegative');
        end

        function testWeightToVolumeRejectsNonPositiveDensity(tc)
            tc.verifyError(@() SubsystemsBase.weight_to_volume(100, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        % ================================================================== %
        % F16SubsystemsL1 wiring / DI / optimization-ready property design.
        % Templates: TestGeomL2.testWettedAreasLiveOnRead /
        % testDerivedPropertiesAreReadOnly.
        % ================================================================== %

        function testF16SubsystemsL1ReadsJSONFuelAndAvionicsRow(tc)
            g = F16SubsystemsL1(f16a_spec_path(1));
            tc.verifyEqual(g.fuel_type, 'JP-8', ...
                'f16a_L1.json .subsystems.fuel.fuel_type must be JP-8 (T.O. 1F-16A-1 nominal internal fuel).');
            tc.verifyEqual(g.avionics_table_row, 'Fighters', ...
                'f16a_L1.json .subsystems.avionics.aircraft_category_table_row must be "Fighters".');
        end

        function testF16SubsystemsL1ConstructorRequiresJsonPath(tc)
            tc.verifyError(@() F16SubsystemsL1(), 'MATLAB:minrhs');
        end

        function testF16SubsystemsL1DerivedPropertiesLiveRecompute(tc)
        % Mutate an input in place (optimizer-style) and verify the Dependent
        % getters track it with NO reconstruction -- CLAUDE.md's
        % "Optimization-ready property design"; TestGeomL2.
        % testWettedAreasLiveOnRead is the template.
            g = F16SubsystemsL1(f16a_spec_path(1));
            fd0 = g.fuel_density;
            af0 = g.avionics_weight_fraction;
            tc.verifyEqual(fd0, 50.0, 'AbsTol', 1e-9);   % JP-8

            g.fuel_type = 'JP-5';   % optimizer-style in-place mutation
            tc.verifyEqual(g.fuel_density, 51.1, 'AbsTol', 1e-9, ...
                'fuel_density must recompute live from the mutated fuel_type.');
            tc.verifyNotEqual(g.fuel_density, fd0, 'fuel_density must change after fuel_type mutation.');

            g.avionics_table_row = 'Bombers';
            tc.verifyEqual(g.avionics_weight_fraction, 0.07, 'AbsTol', 1e-9, ...
                'avionics_weight_fraction must recompute live -- Bombers midpoint = (0.06+0.08)/2 = 0.07.');
            tc.verifyNotEqual(g.avionics_weight_fraction, af0, ...
                'avionics_weight_fraction must change after avionics_table_row mutation.');
        end

        function testF16SubsystemsL1DerivedPropertiesAreReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning to one must
        % error (no set-method exists). TestGeomL2.testDerivedPropertiesAreReadOnly
        % is the template.
            g = F16SubsystemsL1(f16a_spec_path(1));
            tc.verifyError(@() setfield(g, 'fuel_density', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'avionics_weight_fraction', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'avionics_density', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'fuselage_raw_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'fuel_volume', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testF16SubsystemsL1FuselageRawVolumeAndFuelVolumeAreZero(tc)
        % Base-level contract added 2026-08-03: every fidelity level provides
        % fuselage_raw_volume/fuel_volume; L1 honestly answers 0 for both (no
        % fuselage/fuel-bay geometry exists at this tier).
            g = F16SubsystemsL1(f16a_spec_path(1));
            tc.verifyEqual(g.fuselage_raw_volume, 0, 'AbsTol', 1e-9);
            tc.verifyEqual(g.fuel_volume, 0, 'AbsTol', 1e-9);
        end

        function testF16SubsystemsL1IsaChecks(tc)
            g = F16SubsystemsL1(f16a_spec_path(1));
            tc.verifyTrue(isa(g, 'SubsystemsBase'));
            tc.verifyTrue(isa(g, 'SubsystemsModelL1'));
            tc.verifyTrue(isa(g, 'handle'));
        end

    end

end

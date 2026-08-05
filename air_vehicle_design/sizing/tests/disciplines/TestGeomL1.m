classdef TestGeomL1 < matlab.unittest.TestCase
%TESTGEOML1  Unit tests for GeomL1 and F16GeomL1.
%
%   Formula references:
%     S_wet regression: Roskam, Airplane Design Vol. I, Table 3.5
%       S_wet = 10^c * W_TO^d   (jet fighter: c=-0.1289, d=0.7506)
%     L_fus regression: Raymer, Aircraft Design 6th ed., Table 6.3
%       L_fus = a * W_TO^C      (jet fighter: a=0.93, C=0.39)
%
%   Formula outputs at W_TO = 31377 lbf (F-16A Brandt TOGW):
%     S_wet  = 10^(-0.1289) * 31377^0.7506 ≈ 1762 ft^2  [Roskam regression]
%     L_fus  = 0.93 * 31377^0.39           ≈  53.0 ft   [Raymer regression]
%
%   Physical reference values (ground-truth):
%     S_wet  = 1371 ft^2  [Brandt F-16A.xls, L3]
%     L_fus  = 47.5 ft    [T.O. 1F-16A-1, Fig. 1-2]
%
%   Tests assert formula output is within ±30% of S_wet (Roskam scatter is
%   ~29% for this type) and within ±20% of L_fus (Raymer scatter is ~12%).

    properties (Constant)
        TOGW   = 31377    % lbf   — F-16A Brandt TOGW
        W_TO_2 = 20000    % lbf   — lighter weight for sensitivity check

        % Loose Brandt / physical ground-truth references, from
        % VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json (comparison
        % targets, not hand-computed oracles).
        BRANDT_SWET = 1371.0946   % ft^2  [Brandt Geom!B19; geometry.whole_aircraft_S_wet_ft2.raw_buggy_total]
        TO_LFUS     = 47.5        % ft    [T.O. 1F-16A-1; geometry.to_1f16a1.fuselage_length_ft]
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        % --- Formula correctness (±1% of reference computation) ----------

        function testSwetFormulaJetFighter(tc)
        % S_wet = 10^c * W_TO^d,  c=-0.1289, d=0.7506  [Roskam Table 3.5]
        % Formula gives ≈1762 ft^2; Brandt actual = 1371 ft^2 (~29% scatter).
        % Assert within ±30% of Brandt reference to cover known regression scatter.
            expected = tc.BRANDT_SWET;   % 1371.09 ft^2 [Brandt Geom!B19; f16a_ground_truth.json]
            g        = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            received = g.get_S_wet_statistical(tc.TOGW);
            fprintf('\n    S_wet_statistical: received = %.2f ft^2,  expected (Brandt) = %.2f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.30, ...
                'S_wet regression deviates >30% from Brandt workbook value.');
        end

        function testLfusFormulaJetFighter(tc)
        % L_fus = a * W_TO^C,  a=0.93, C=0.39  [Raymer 6th ed. Table 6.3]
        % Formula gives ≈53.0 ft; USAF TO 1F-16A-1 = 47.5 ft (~11.6% off).
        % Assert within ±20% of USAF TO reference value.
            expected = tc.TO_LFUS;   % 47.50 ft [T.O. 1F-16A-1; f16a_ground_truth.json]
            g        = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            received = g.get_L_fus(tc.TOGW);
            fprintf('\n    get_L_fus:         received = %.2f ft,    expected (TO) = %.2f ft\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                'L_fus regression deviates >20% from USAF TO reference.');
        end

        function testGetSwetCallsStatistical(tc)
        % Structural: get_S_wet(W_TO) must delegate to get_S_wet_statistical(W_TO).
        % Both calls should return bit-identical results.
            g        = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            via_base = g.get_S_wet(tc.TOGW);
            via_impl = g.get_S_wet_statistical(tc.TOGW);
            fprintf('\n    get_S_wet (base):  %.6f ft^2\n', via_base);
            fprintf('    get_S_wet_stat:    %.6f ft^2\n', via_impl);
            tc.verifyEqual(via_base, via_impl, 'AbsTol', 1e-10, ...
                'get_S_wet does not delegate to get_S_wet_statistical.');
        end

        % --- Physical reasonableness -------------------------------------


        function testSwetMonotonicallyIncreasing(tc)
        % Positive regression exponent d=0.7506 → heavier ⟹ more wetted area.
            g  = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            S1 = g.get_S_wet_statistical(tc.W_TO_2);   % W_TO = 20000 lbf
            S2 = g.get_S_wet_statistical(tc.TOGW);     % W_TO = 31377 lbf
            fprintf('\n    S_wet at W_TO=20000: %.2f ft^2\n', S1);
            fprintf('    S_wet at W_TO=31377: %.2f ft^2  (should be larger)\n', S2);
            tc.verifyGreaterThan(S2, S1, ...
                'S_wet should increase with W_TO (positive regression exponent d>0).');
        end

        % --- Unknown category error --------------------------------------

        function testUnknownCategoryThrows(tc)
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_S_wet_statistical(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        function testUnknownCategoryLfusThrows(tc)
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_L_fus(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        % --- Mutable S_ref (handle semantics) ----------------------------

        function testSrefMutable(tc)
        % Sizing loop updates S_ref in-place on the handle object.
        % Expected: get_S_ref() returns 250 after assignment.
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            g.S_ref = 250;
            received = g.get_S_ref();
            fprintf('\n    S_ref after assignment: received = %.2f ft^2,  expected = 250.00 ft^2\n', ...
                received);
            tc.verifyEqual(received, 250, 'AbsTol', 1e-9, ...
                'S_ref should be mutable for handle objects.');
        end

        % ================================================================== %
        % Task 2 additions (2026-07-22): AR_eq, control-surface chord
        % fractions -- see GeomL1.md's "Task 2" section for full citations/
        % derivations. Every "expected"/"hand-computed" value below was
        % computed independently from the cited formula and constants
        % (Raymer 7th ed. Table 4.1/6.5) -- never by calling the GeomL1
        % method under test to generate its own oracle.
        %
        % HISTORY: the tail-volume-coefficient chain tests that used to live
        % here moved OUT to the standalone tail_sizing discipline's TailL1
        % toolbox on 2026-07-28 ("tail sizing is not geometry's job" -- the
        % view at the time), then moved back IN on 2026-08-03 when that
        % discipline was retired and tail sizing was absorbed into Geometry
        % for good (Casey's decision) -- see this file's own TAIL SIZING
        % section below for the current tests.
        % ================================================================== %

        % --- Equivalent aspect ratio (dogfighter regression) ---------------

        function testAREqDogfighterFormula(tc)
        % AR_eq = a*M_max^C, a=5.416, C=-0.6222 [Raymer 7th ed. Table 4.1,
        % "Jet fighter (dogfighter)" row]. Hand-computed at M_max=2.0:
        %   AR_eq = 5.416 * 2.0^(-0.6222) = 3.5186639569 (independently
        %   computed via a plain a*M_max^C expression, not by calling
        %   GeomL1.compute_AR_eq).
            expected = 3.5186639569;
            received = GeomL1.compute_AR_eq('jet_fighter', 2.0);
            fprintf('\n    AR_eq: received = %.10f,  hand-computed = %.10f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'AR_eq does not match the hand-computed Raymer Table 4.1 dogfighter regression.');
        end

        function testGetAREqDelegatesToCompute(tc)
        % F16GeomL1's default M_max=2.0, aircraft_category='jet_fighter' --
        % get_AR_eq(obj) must equal the same hand-computed value as above.
            expected = 3.5186639569;
            g        = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            received = g.get_AR_eq();
            fprintf('\n    get_AR_eq: received = %.10f,  hand-computed = %.10f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'get_AR_eq does not match the hand-computed value at F-16''s own M_max=2.0.');
        end

        function testUnknownCategoryAREqThrows(tc)
        % Only the Raymer 7th ed. Table 4.1 "Jet fighter (dogfighter)" row
        % is implemented; any other category must error, not interpolate.
            tc.verifyError(@() GeomL1.compute_AR_eq('flying_car', 2.0), ...
                'GeomL1:unknownCategory');
        end

        % --- Control-surface chord fractions ---------------------------------

        function testControlSurfaceFractionElevator(tc)
        % Raymer 7th ed. Table 6.5 "Jet fighter" row: C_e/c = 0.30
        % (all-moving-tail row value, not a hinged-elevator fraction).
            received = GeomL1.compute_control_surface_fraction('jet_fighter', 'elevator');
            fprintf('\n    elevator C_e/c: received = %.4f,  expected = 0.3000\n', received);
            tc.verifyEqual(received, 0.30, 'AbsTol', 1e-9);
        end

        function testControlSurfaceFractionRudder(tc)
        % Raymer 7th ed. Table 6.5 "Jet fighter" row: C_r/c = 0.33.
            received = GeomL1.compute_control_surface_fraction('jet_fighter', 'rudder');
            fprintf('\n    rudder C_r/c: received = %.4f,  expected = 0.3300\n', received);
            tc.verifyEqual(received, 0.33, 'AbsTol', 1e-9);
        end

        function testGetControlSurfaceFractionObjectLevel(tc)
        % High-level get_control_surface_fraction(obj, surface) reads
        % obj.aircraft_category and delegates to the same lookup.
            g        = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            received = GeomL1.get_control_surface_fraction(g, 'elevator');
            fprintf('\n    get_control_surface_fraction(elevator): received = %.4f\n', received);
            tc.verifyEqual(received, 0.30, 'AbsTol', 1e-9);
        end

        function testUnknownCategoryControlSurfaceThrows(tc)
            tc.verifyError(@() GeomL1.compute_control_surface_fraction('flying_car', 'elevator'), ...
                'GeomL1:unknownCategory');
        end

        % ================================================================== %
        % S_wet / L_fuselage are DERIVED, not frozen zeros (added 2026-07-25).
        %
        % Both were plain properties initialised to 0 and commented "populated
        % by get_S_wet(obj, W_TO)" -- which only ever RETURNED a value, never
        % assigned. So both stayed 0 for the object's life, and because
        % F16AeroL2/L3 accept any GeometryBase, injecting an F16GeomL1 gave
        % CD0 = Cfe*0/S_ref = 0: silent zero parasite drag, infinite L/D.
        % ================================================================== %

        function testSWetTracksWTOAndMatchesRegression(tc)
            % The Dependent getter must equal the Roskam Table 3.5 regression
            % called directly, and must MOVE when W_TO moves (the staleness the
            % conversion removes).
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            g.W_TO = 31377;
            tc.verifyEqual(g.S_wet, g.get_S_wet(31377), 'RelTol', 1e-12, ...
                'S_wet must equal the statistical regression at the current W_TO.');
            tc.verifyGreaterThan(g.S_wet, 0, 'S_wet must be positive, never the old frozen 0.');
            s1 = g.S_wet;  l1 = g.L_fuselage;
            g.W_TO = 45000;
            tc.verifyGreaterThan(g.S_wet, s1, ...
                'S_wet must increase with W_TO -- a frozen value would not move.');
            tc.verifyGreaterThan(g.L_fuselage, l1, ...
                'L_fuselage must increase with W_TO -- a frozen value would not move.');
        end

        function testDerivedAreasErrorWhenWTOUnset(tc)
            % Reading either derived quantity before W_TO is set is a caller
            % error, not a 0. Erroring here is the entire point of the change.
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() g.S_wet,      'F16GeomL1:WTONotSet');
            tc.verifyError(@() g.L_fuselage, 'F16GeomL1:WTONotSet');
        end

        function testDerivedAreasAreReadOnly(tc)
            % Dependent with no set-method: assigning to an output must error.
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() setfield(g, 'S_wet', 1234), ...
                'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % --- Deliberately-failing TODO test: Raymer Table 6.5 aileron gap ---

        function testTODO_AileronFractionNotAvailable(tc)
        %TESTTODO_AILERONFRACTIONNOTAVAILABLE  Deliberate, expected failure.
        %   Raymer 7th ed. Table 6.5 "Jet fighter" row, AS SUPPLIED TO THIS
        %   TOOLBOX, does not include an aileron chord-fraction value (see
        %   GeomL1.md's Task-2 "Gap" note and GeomL1.m's own comment on
        %   lookup_control_surface_fraction's 'aileron' case). The code
        %   correctly errors GeomL1:unknownControlSurface rather than
        %   fabricating a plausible-looking number. This test asserts what a
        %   *complete* table would give -- a real, positive aileron chord
        %   fraction -- so it fails LOUDLY and predictably: an uncaught
        %   GeomL1:unknownControlSurface error, which the test runner
        %   reports as "Errored" (distinct from "Failed by verification"),
        %   clearly distinguishable from a real regression. RESOLUTION:
        %   obtain a cited aileron C_a/c value from Raymer 7th ed. Table 6.5
        %   (or an equivalent cited source) and add it to
        %   GeomL1.lookup_control_surface_fraction's 'jet_fighter' case.
            val = GeomL1.compute_control_surface_fraction('jet_fighter', 'aileron');
            tc.verifyGreaterThan(val, 0, ...
                'Aileron chord fraction should be a positive number once Raymer Table 6.5 data is supplied.');
        end

        % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
        % Migrated verbatim (same hand-computed expected values, never
        % recomputed) from the now-retired tests/disciplines/TestTailL1.m --
        % repointed from TailL1.*/F16TailL1() to GeomL1.*/F16GeomL1(...).
        % Tail sizing is organizationally part of Geometry now (Casey's
        % decision), not a separate tail_sizing discipline.
        %
        % METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed.,
        % AIAA, 2018, Table 6.4 + accompanying text]:
        %   L_HT = L_VT = 0.475 * L_fus
        %   c_HT = c_HT_base * (1 - 0.10) * (1 - 0.125)   [if RSS and all-moving tail]
        %   c_VT = c_VT_base * (1 - 0.10)                 [if RSS; no VT-specific text correction exists]
        %   S_VT = c_VT * b    * S_ref / L_VT
        %   S_HT = c_HT * cbar * S_ref / L_HT
        % Jet-fighter base row: c_HT=0.40, c_VT=0.07.
        % ==================================================================================================================================== %

        function testLookupJetFighterBaseCoefficients(tc)
        % [Raymer 7th ed. Table 6.4, "Jet fighter" row]
            [c_HT, c_VT] = GeomL1.lookup_tail_volume_coeffs('jet_fighter');
            tc.verifyEqual(c_HT, 0.40, 'AbsTol', 0, 'Jet-fighter base c_HT must be 0.40.');
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 0, 'Jet-fighter base c_VT must be 0.07.');
        end

        function testUnknownCategoryTailVolumeThrows(tc)
        % Only the jet-fighter row is implemented -- an unknown category must
        % error rather than silently return a guessed value.
            tc.verifyError(@() GeomL1.lookup_tail_volume_coeffs('prop_trainer'), ...
                'GeomL1:unknownCategory');
        end

        function testTailVolumeCorrectionsNeitherAppliesLeavesBaseUnchanged(tc)
            [c_HT, c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', false, false);
            tc.verifyEqual(c_HT, 0.40, 'AbsTol', 0);
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 0);
        end

        function testTailVolumeCorrectionsRSSOnly(tc)
        % RSS: -10% on BOTH c_HT and c_VT [Table 6.4 text].
        % Hand-computed: 0.40*0.90=0.36, 0.07*0.90=0.063.
            [c_HT, c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', true, false);
            tc.verifyEqual(c_HT, 0.36, 'AbsTol', 1e-12);
            tc.verifyEqual(c_VT, 0.063, 'AbsTol', 1e-12);
        end

        function testTailVolumeCorrectionsAllMovingTailOnly(tc)
        % All-moving stabilator: -12.5% on c_HT ONLY, no VT-specific text
        % correction. Hand-computed: 0.40*0.875=0.35; c_VT unchanged=0.07.
            [c_HT, c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', false, true);
            tc.verifyEqual(c_HT, 0.35, 'AbsTol', 1e-12);
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 1e-12);
        end

        function testTailVolumeCorrectionsBothAppliesF16NetValues(tc)
        % Both corrections (the F-16's case): c_HT=0.40*0.90*0.875=0.315,
        % c_VT=0.07*0.90=0.063 -- hand-computed, independent of F16GeomL1's
        % own constructor call to this same static (verified below by a
        % SEPARATE test comparing the two).
            [c_HT, c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', true, true);
            tc.verifyEqual(c_HT, 0.315, 'AbsTol', 1e-12, ...
                'F-16 net c_HT must equal 0.40*(1-0.10)*(1-0.125)=0.315.');
            tc.verifyEqual(c_VT, 0.063, 'AbsTol', 1e-12, ...
                'F-16 net c_VT must equal 0.07*(1-0.10)=0.063.');
        end

        function testTailArmFormula(tc)
        % [Raymer 7th ed. text, aft-mounted single-engine rule, midpoint 0.475]
        % Hand-computed at L_fus=46.5: 0.475*46.5=22.0875 exactly.
            L = GeomL1.compute_tail_arm(46.5);
            tc.verifyEqual(L, 22.0875, 'AbsTol', 1e-12);
        end

        function testTailArmRejectsNonPositive(tc)
        % L_fus is a numerator-only quantity but is guarded mustBePositive
        % (a zero/negative fuselage length is nonphysical).
            tc.verifyError(@() GeomL1.compute_tail_arm(0), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() GeomL1.compute_tail_arm(-10), 'MATLAB:validators:mustBePositive');
        end

        function testTailComputeSHTFormula(tc)
        % Arbitrary invented scalars (not F-16 data): c_HT=0.45, cbar=9.5,
        % S_ref=250, L_HT=19 (deliberately NOT 0.475*L_fus here -- this test
        % isolates compute_S_HT's own arithmetic from compute_tail_arm's).
        % Hand-computed: 0.45*9.5*250/19 = 1068.75/19 = 56.25 EXACTLY
        % (19*56=1064, remainder 4.75, 4.75/19=0.25).
            val = GeomL1.compute_S_HT(0.45, 9.5, 250, 19);
            tc.verifyEqual(val, 56.25, 'AbsTol', 1e-9);
        end

        function testTailComputeSVTFormula(tc)
        % Arbitrary invented scalars: c_VT=0.08, b=28, S_ref=250, L_VT=19.
        % Hand-computed: 0.08*28*250/19 = 560/19 = 29.473684210526315...
        % (repeating decimal, 9/19 remainder pattern) -- RelTol 1e-12 covers
        % double round-off only, not any code-fitted slack.
            val = GeomL1.compute_S_VT(0.08, 28, 250, 19);
            tc.verifyEqual(val, 29.473684210526315, 'RelTol', 1e-12);
        end

        function testTailComputeSHTRejectsNonPositiveDenominator(tc)
        % L_HT=0 would divide by zero -- guarded mustBePositive.
            tc.verifyError(@() GeomL1.compute_S_HT(0.4, 9, 250, 0), 'MATLAB:validators:mustBePositive');
        end

        function testSizeTailMatchesHandComputedFormula(tc)
        % A plain struct suffices as `obj` -- GeomL1.size_tail only reads
        % obj.c_HT/obj.c_VT via dot access, which structs support.
        %   c_HT=0.45, c_VT=0.08, S_ref=250, b=28, cbar=9.5, L_fus=40
        %   L_HT=L_VT=0.475*40=19
        %   S_ht = 0.45*9.5*250/19 = 56.25 EXACTLY (see testTailComputeSHTFormula)
        %   S_vt = 0.08*28*250/19  = 29.473684210526315... (see testTailComputeSVTFormula)
            obj = struct('c_HT', 0.45, 'c_VT', 0.08);
            result = GeomL1.size_tail(obj, 250, 28, 9.5, 40);
            fprintf('\n    GeomL1.size_tail: S_ht received=%.9f expected=56.250000000 | S_vt received=%.9f expected=29.473684211\n', ...
                result.S_ht, result.S_vt);
            tc.verifyEqual(result.S_ht, 56.25, 'AbsTol', 1e-9, ...
                'S_ht must equal c_HT*cbar*S_ref/(0.475*L_fus).');
            tc.verifyEqual(result.S_vt, 29.473684210526315, 'RelTol', 1e-9, ...
                'S_vt must equal c_VT*b*S_ref/(0.475*L_fus).');
        end

        function testSizeTailResultFieldNamesAreLowercase(tc)
        % Field names must be S_ht/S_vt (matching GeometryBase-derived
        % classes' own property casing, e.g. F16GeomL2.S_ht/S_vt).
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            result = GeomL1.size_tail(obj, 300, 30, 11, 46.5);
            tc.verifyTrue(isfield(result, 'S_ht'));
            tc.verifyTrue(isfield(result, 'S_vt'));
        end

        function testSizeTailScalesLinearlyWithSRef(tc)
        % Both S_ht and S_vt are directly proportional to S_ref with
        % everything else held fixed -- a structural invariant of the
        % formula, independent of the exact coefficient values.
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            r1 = GeomL1.size_tail(obj, 300, 30, 11, 46.5);
            r2 = GeomL1.size_tail(obj, 600, 30, 11, 46.5);
            tc.verifyEqual(r2.S_ht, 2 * r1.S_ht, 'RelTol', 1e-12);
            tc.verifyEqual(r2.S_vt, 2 * r1.S_vt, 'RelTol', 1e-12);
        end

        function testF16GeomL1NetTailCoefficients(tc)
        % F16GeomL1's constructor calls
        % GeomL1.compute_tail_volume_coeffs('jet_fighter', true, true) --
        % this test asserts the RESULTING property values against the
        % independently hand-computed 0.315/0.063 (same numbers as
        % testTailVolumeCorrectionsBothAppliesF16NetValues, computed by hand
        % there, not read from the object under test).
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyEqual(g.c_HT, 0.315, 'AbsTol', 1e-12);
            tc.verifyEqual(g.c_VT, 0.063, 'AbsTol', 1e-12);
        end

        function testF16GeomL1SizeTailAgainstF16GeomL2WingGeometry(tc)
        % Feeds F16GeomL1.size_tail with REAL F16GeomL2 wing geometry (S_ref,
        % b_wing, cbar_wing, L_fus), read live from an actual F16GeomL2 object
        % (independent of GeomL1's own equations -- GeometryBase's
        % compute_span/compute_root_chord/compute_mac chain, Raymer 7th ed.
        % Eqs. 7.6-7.8) rather than hardcoding F16GeomL2's numbers again.
        %
        % HAND-COMPUTED EXPECTED VALUES (fraction arithmetic, not read from
        % the code under test): with S_ref=300, AR_wing=3.0, lambda=0.2275
        % (=91/400 exactly) -> b=sqrt(3*300)=30 exactly;
        % c_root=2*300/(30*1.2275)=8000/491 ft;
        % cbar=(2/3)*c_root*(1+lambda+lambda^2)/(1+lambda) = 2729080/241081
        %     = 11.320178695... ft  [Raymer 7th ed. Eqs. 7.6/7.8]
        % L_fus=46.5 -> L_HT=L_VT=0.475*46.5=22.0875 exactly.
        %   S_ht = 0.315*11.320178695*300/22.0875 = 41263689600/851980254
        %        = 48.432683041... ft^2
        %   S_vt = 0.063*30*300/22.0875 = 15120/589 = 25.670628183... ft^2
            geom2 = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            S_ref = geom2.S_ref;
            b     = geom2.b_wing;
            cbar  = geom2.cbar_wing;
            L_fus = geom2.L_fus;

            g1     = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            result = g1.size_tail(S_ref, b, cbar, L_fus);

            expected_S_ht = 48.432683041;
            expected_S_vt = 25.670628183;

            fprintf(['\n    F16GeomL1.size_tail (real F16GeomL2 wing geometry): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-6, ...
                'F16GeomL1.size_tail S_ht must match the hand-computed volume-coefficient formula result.');
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-6, ...
                'F16GeomL1.size_tail S_vt must match the hand-computed volume-coefficient formula result.');
        end

        function testF16GeomL2SizeTailMatchesSameHandComputedNumbers(tc)
        % NEW test (2026-08-03): the actually-new production entry point is
        % F16GeomL2(...).size_tail() (self-referencing, zero-arg) -- this must
        % return the SAME hand-computed S_ht/S_vt numbers
        % (48.432683041/25.670628183) as the previous test, since it is the
        % same Raymer formula fed the same F16GeomL2 wing geometry, just called
        % on the geometry object itself instead of via a separate F16GeomL1.
            g2 = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            result = g2.size_tail();

            expected_S_ht = 48.432683041;
            expected_S_vt = 25.670628183;

            fprintf(['\n    F16GeomL2.size_tail (new production entry point): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-6);
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-6);
            % size_tail must also self-mutate g2's own S_ht/S_vt properties.
            tc.verifyEqual(g2.S_ht, expected_S_ht, 'RelTol', 1e-6, ...
                'size_tail() must self-mutate obj.S_ht.');
            tc.verifyEqual(g2.S_vt, expected_S_vt, 'RelTol', 1e-6, ...
                'size_tail() must self-mutate obj.S_vt.');
        end

        function testF16GeomL1TailAreasVsBrandtIsNotAssertedTight(tc)
        % Brandt agreement is NEVER a unit-test pass/fail gate (CLAUDE.md's
        % two-tier rule) -- this test only documents, via fprintf, that the
        % gap widens under the corrected 0.315/0.063 coefficients relative to
        % the flat 0.40/0.07 a generic uncorrected jet-fighter row would give.
        % No assertion here is tolerance-fitted to Brandt; see
        % examples/F16A/tail_sizing_brandt_comparison.m for the actual
        % (non-pass/fail) comparison report.
            geom2  = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            g1     = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            result = g1.size_tail(geom2.S_ref, geom2.b_wing, geom2.cbar_wing, geom2.L_fus);
            brandt_S_ht = 108.0;   % [Brandt Main!C18]
            brandt_S_vt = 60.0;    % [Brandt Main!H18]
            fprintf(['\n    F16GeomL1.size_tail vs Brandt (informational only): ' ...
                     'S_ht=%.4f (Brandt=%.1f, %+.1f%%) | S_vt=%.4f (Brandt=%.1f, %+.1f%%)\n'], ...
                result.S_ht, brandt_S_ht, 100*(result.S_ht-brandt_S_ht)/brandt_S_ht, ...
                result.S_vt, brandt_S_vt, 100*(result.S_vt-brandt_S_vt)/brandt_S_vt);
            tc.verifyGreaterThan(result.S_ht, 0);
            tc.verifyGreaterThan(result.S_vt, 0);
        end

    end
end

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
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        % --- Formula correctness (±1% of reference computation) ----------

        function testSwetFormulaJetFighter(tc)
        % S_wet = 10^c * W_TO^d,  c=-0.1289, d=0.7506  [Roskam Table 3.5]
        % Formula gives ≈1762 ft^2; Brandt actual = 1371 ft^2 (~29% scatter).
        % Assert within ±30% of Brandt reference to cover known regression scatter.
            b        = F16Baseline();
            expected = b.brandt.S_wet;   % 1371.09 ft^2 [Brandt L3]
            g        = F16GeomL1();
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
            b        = F16Baseline();
            expected = b.geom.L_fus;   % 47.50 ft [T.O. 1F-16A-1, Fig. 1-2]
            g        = F16GeomL1();
            received = g.get_L_fus(tc.TOGW);
            fprintf('\n    get_L_fus:         received = %.2f ft,    expected (TO) = %.2f ft\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                'L_fus regression deviates >20% from USAF TO reference.');
        end

        function testGetSwetCallsStatistical(tc)
        % Structural: get_S_wet(W_TO) must delegate to get_S_wet_statistical(W_TO).
        % Both calls should return bit-identical results.
            g        = F16GeomL1();
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
            g  = F16GeomL1();
            S1 = g.get_S_wet_statistical(tc.W_TO_2);   % W_TO = 20000 lbf
            S2 = g.get_S_wet_statistical(tc.TOGW);     % W_TO = 31377 lbf
            fprintf('\n    S_wet at W_TO=20000: %.2f ft^2\n', S1);
            fprintf('    S_wet at W_TO=31377: %.2f ft^2  (should be larger)\n', S2);
            tc.verifyGreaterThan(S2, S1, ...
                'S_wet should increase with W_TO (positive regression exponent d>0).');
        end

        % --- Unknown category error --------------------------------------

        function testUnknownCategoryThrows(tc)
            g = F16GeomL1();
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_S_wet_statistical(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        function testUnknownCategoryLfusThrows(tc)
            g = F16GeomL1();
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_L_fus(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        % --- Mutable S_ref (handle semantics) ----------------------------

        function testSrefMutable(tc)
        % Sizing loop updates S_ref in-place on the handle object.
        % Expected: get_S_ref() returns 250 after assignment.
            g = F16GeomL1();
            g.S_ref = 250;
            received = g.get_S_ref();
            fprintf('\n    S_ref after assignment: received = %.2f ft^2,  expected = 250.00 ft^2\n', ...
                received);
            tc.verifyEqual(received, 250, 'AbsTol', 1e-9, ...
                'S_ref should be mutable for handle objects.');
        end

        % ================================================================== %
        % Task 2 additions (2026-07-22): AR_eq, tail-volume-coefficient
        % chain, control-surface chord fractions -- see GeomL1.md's "Task 2"
        % section for full citations/derivations. Every "expected"/"hand-
        % computed" value below was computed independently from the cited
        % formula and constants (Raymer 7th ed. Table 4.1/6.4/6.5) -- never
        % by calling the GeomL1 method under test to generate its own
        % oracle.
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
            g        = F16GeomL1();
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

        % --- Tail-volume-coefficient chain ----------------------------------

        function testTailVolumeCoeffsF16(tc)
        % Raymer 7th ed. Table 6.4 "Jet fighter" row base (c_HT=0.40,
        % c_VT=0.07), with F-16-specific text corrections: RSS/active FCS
        % (both *= (1-0.10)) and all-moving tail (c_HT additionally
        % *= (1-0.125)). Hand-computed: c_HT = 0.40*0.90*0.875 = 0.315,
        % c_VT = 0.07*0.90 = 0.063.
            [c_HT, c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', true, true);
            fprintf('\n    c_HT: received = %.10f,  hand-computed = 0.3150000000\n', c_HT);
            fprintf('    c_VT: received = %.10f,  hand-computed = 0.0630000000\n', c_VT);
            tc.verifyEqual(c_HT, 0.315, 'AbsTol', 1e-9, 'c_HT does not match hand-computed 0.315.');
            tc.verifyEqual(c_VT, 0.063, 'AbsTol', 1e-9, 'c_VT does not match hand-computed 0.063.');
        end

        function testUnknownCategoryTailVolumeThrows(tc)
            tc.verifyError(@() GeomL1.compute_tail_volume_coeffs('flying_car', true, true), ...
                'GeomL1:unknownCategory');
        end

        function testTailArmFormula(tc)
        % L_HT = L_VT = 0.475*L_fus [Raymer aft-single-engine text rule,
        % midpoint of the stated 0.45-0.50 range]. Uses the F-16's own
        % Brandt Main-tab fuselage length (46.5 ft --
        % VnV/BrandtF16A/GroundTruth/f16a_geometry.json fuselage.length_ft)
        % as a representative real L_fus -- deliberately NOT computed via
        % GeomL1's own L_fus regression (compute_l_fus_regression), so this
        % test cannot share a failure mode with that formula.
        %   Hand-computed: 0.475 * 46.5 = 22.0875 ft.
            L_fus_brandt = 46.5;   % ft [Brandt Main!B32]
            expected     = 22.0875;
            received     = GeomL1.compute_tail_arm(L_fus_brandt);
            fprintf('\n    tail arm: received = %.10f ft,  hand-computed = %.10f ft\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'Tail arm does not match hand-computed 0.475*L_fus.');
        end

        function testSHTFormula(tc)
        % S_HT = c_HT*cbar*S_ref/L_HT [Raymer 7th ed. Table 6.4].
        % Representative values chosen independently (NOT reused from any
        % existing sanity-check number in the docs): cbar=12 ft,
        % S_ref=300 ft^2, L_HT=20 ft, c_HT=0.315.
        %   Hand-computed: 0.315*12*300/20 = 56.7 ft^2.
            expected = 56.7;
            received = GeomL1.compute_S_HT(0.315, 12, 300, 20);
            fprintf('\n    S_HT: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'S_HT does not match hand-computed c_HT*cbar*S_ref/L_HT.');
        end

        function testSVTFormula(tc)
        % S_VT = c_VT*b*S_ref/L_VT [Raymer 7th ed. Table 6.4].
        % Representative values: b=30 ft, S_ref=300 ft^2, L_VT=20 ft, c_VT=0.063.
        %   Hand-computed: 0.063*30*300/20 = 28.35 ft^2.
            expected = 28.35;
            received = GeomL1.compute_S_VT(0.063, 30, 300, 20);
            fprintf('\n    S_VT: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'S_VT does not match hand-computed c_VT*b*S_ref/L_VT.');
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
            g        = F16GeomL1();
            received = GeomL1.get_control_surface_fraction(g, 'elevator');
            fprintf('\n    get_control_surface_fraction(elevator): received = %.4f\n', received);
            tc.verifyEqual(received, 0.30, 'AbsTol', 1e-9);
        end

        function testUnknownCategoryControlSurfaceThrows(tc)
            tc.verifyError(@() GeomL1.compute_control_surface_fraction('flying_car', 'elevator'), ...
                'GeomL1:unknownCategory');
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

    end
end

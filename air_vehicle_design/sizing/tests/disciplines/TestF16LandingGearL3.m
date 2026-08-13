classdef TestF16LandingGearL3 < matlab.unittest.TestCase
%TESTF16LANDINGGEARL3  Unit tests for F16LandingGearL3 (F-16-only, no
%   abstract Base/Model tier -- original step-9 subsystems design, Files to
%   Create).
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green. NO deliberate TODO
%   test in this file: F16LandingGearL3's gear-bay-volume citation gap
%   (original step-9 subsystems design, item 11) is the SAME open gap as
%   F16LandingGearL2's, and is pinned exactly once, for BOTH classes, in
%   TestF16LandingGearL2.testTODO_GearBayVolumePackagingNotInRepo -- adding
%   a second TODO test here would double-count a single open gap in the
%   suite's TODO-test tally.
%
%   F16LandingGearL3 has IDENTICAL equations to F16LandingGearL2 (same 90/10
%   Raymer gear load split, same Table 11.1 Jet fighter/trainer row) and
%   REUSES F16LandingGearL2's Static low-level methods directly (tire
%   diameter/width power-law arithmetic is not re-derived here -- see
%   TestF16LandingGearL2.m for the hand-computed power-law checks). This
%   file focuses on L3's own wiring (F16WeightsL3/F16GeomL3 DI, its own
%   W_TO-not-set error identifier) and confirms the reuse is real (bit-
%   identical output to L2 for the same inputs), not a silently-diverged
%   duplicate.

    methods (Test)

        function testTireSizingReusesF16LandingGearL2StaticsExactly(tc)
        % Structural guard: L3 must not carry its own copy of Table 11.1 or
        % the power-law formula -- both must be bit-identical to L2's.
            c2 = F16LandingGearL2.lookup_tire_sizing_coeffs('Jet fighter/trainer');
            lg3 = TestF16LandingGearL3.makeLG(20000);
            c3 = F16LandingGearL2.lookup_tire_sizing_coeffs(lg3.aircraft_category_table_row);
            tc.verifyEqual([c3.A_d, c3.B_d, c3.A_w, c3.B_w], [c2.A_d, c2.B_d, c2.A_w, c2.B_w], 'AbsTol', 1e-9);

            tc.verifyEqual(lg3.tire_diameter_main, ...
                F16LandingGearL2.tire_diameter(c2.A_d, c2.B_d, lg3.W_w_main), 'AbsTol', 1e-9);
            tc.verifyEqual(lg3.tire_width_main, ...
                F16LandingGearL2.tire_width(c2.A_w, c2.B_w, lg3.W_w_main), 'AbsTol', 1e-9);
        end

        function testGearLoadSplitArithmeticHandComputed(tc)
        % Same formula/hand-derivation as TestF16LandingGearL2.
        % testGearLoadSplitArithmeticHandComputed -- W_TO = 20,000:
        %   W_main_total=18000, W_nose_total=2000, W_w_main=9000, W_w_nose=2000.
            lg = TestF16LandingGearL3.makeLG(20000);
            tc.verifyEqual(lg.W_main_total, 18000, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_nose_total, 2000,  'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_w_main,     9000,  'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_w_nose,     2000,  'AbsTol', 1e-9);
        end

        function testTireDiameterAndWidthMatchL2ForSameWTO(tc)
        % Bit-identical-behavior guard: given the SAME W_TO and category row,
        % L3's Dependent getters must produce the SAME numbers as L2's --
        % tire sizing does not change with geometry fidelity (F16LandingGearL3.m
        % header, "Kept as a separate class... today the two classes' equations
        % are IDENTICAL").
            prop = F16PropL2(f16a_spec_path(2));

            g2 = F16GeomL2(f16a_spec_path(2), prop);
            w2 = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
            w2.W_TO = 25000;
            lg2 = F16LandingGearL2(f16a_spec_path(2), w2);

            g3 = F16GeomL3(f16a_spec_path(3), prop);
            w3 = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO = 25000;
            lg3 = F16LandingGearL3(f16a_spec_path(3), w3);

            tc.verifyEqual(lg3.tire_diameter_main, lg2.tire_diameter_main, 'AbsTol', 1e-9);
            tc.verifyEqual(lg3.tire_width_main,    lg2.tire_width_main,    'AbsTol', 1e-9);
            tc.verifyEqual(lg3.tire_diameter_nose, lg2.tire_diameter_nose, 'AbsTol', 1e-9);
        end

        function testNoseTireIsDecidedFractionOfMain(tc)
            lg = TestF16LandingGearL3.makeLG(20000);
            tc.verifyEqual(lg.tire_diameter_nose, 0.80*lg.tire_diameter_main, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.tire_width_nose,    0.80*lg.tire_width_main,    'AbsTol', 1e-9);
        end

        function testConstructorRequiresJsonPathAndWeights(tc)
            tc.verifyError(@() F16LandingGearL3(), 'MATLAB:minrhs');
            tc.verifyError(@() F16LandingGearL3(f16a_spec_path(3)), 'MATLAB:minrhs');
        end

        function testWTONotSetErrorsWithL3sOwnIdentifier(tc)
        % L3 issues its OWN error identifier (not a reused L2 one -- see
        % F16LandingGearL3.m's header), so a caller can distinguish which
        % class's gap fired.
            prop = F16PropL2(f16a_spec_path(2));
            g3   = F16GeomL3(f16a_spec_path(3), prop);
            w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            % w3.W_TO left at its NaN default -- deliberately not set.
            lg = F16LandingGearL3(f16a_spec_path(3), w3);
            tc.verifyError(@() lg.W_main_total, 'F16LandingGearL3:WTONotSet');
        end

        function testReadsJSONInputs(tc)
            lg = TestF16LandingGearL3.makeLG(20000);
            tc.verifyEqual(lg.aircraft_category_table_row, 'Jet fighter/trainer');
            tc.verifyEqual(lg.main_pct, 90, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.nose_pct, 10, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.nose_tire_fraction_of_main, 0.80, 'AbsTol', 1e-9);
        end

        function testDerivedPropertiesLiveRecompute(tc)
            lg = TestF16LandingGearL3.makeLG(20000);
            d0 = lg.tire_diameter_main;
            lg.weights.W_TO = 40000;
            tc.verifyNotEqual(lg.tire_diameter_main, d0, ...
                'tire_diameter_main must recompute live after weights.W_TO mutates.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
            lg = TestF16LandingGearL3.makeLG(20000);
            tc.verifyError(@() setfield(lg, 'tire_diameter_main', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(lg, 'W_w_main', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsHandleClass(tc)
            lg = TestF16LandingGearL3.makeLG(20000);
            tc.verifyTrue(isa(lg, 'handle'));
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function lg = makeLG(W_TO)
        %MAKELG  Real F16LandingGearL3 wired to a real F16WeightsL3, with
        %   W_TO set to the given plausible sizing-loop STATE value.
            prop = F16PropL2(f16a_spec_path(2));
            g3   = F16GeomL3(f16a_spec_path(3), prop);
            w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO = W_TO;
            lg = F16LandingGearL3(f16a_spec_path(3), w3);
        end

    end

end

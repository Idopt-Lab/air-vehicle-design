classdef TestF16LandingGearL2 < matlab.unittest.TestCase
%TESTF16LANDINGGEARL2  Unit tests for F16LandingGearL2 (F-16-only, no
%   abstract Base/Model tier -- original step-9 subsystems design, Files to
%   Create).
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green, with ONE deliberate
%   exception (testTODO_GearBayVolumePackagingNotInRepo, clearly labeled
%   below -- this single test also covers F16LandingGearL3's identical gap,
%   so the gear-bay-volume citation gap is pinned exactly ONCE across both
%   LandingGear test files, not twice).
%
%   Formula: [Raymer 6th ed. Ch.11, p.344] gear load split (90% main/10%
%   nose, prose) and Table 11.1 "Statistical Tire Sizing" (Jet fighter/
%   trainer row: A_d=1.59, B_d=0.302, A_w=0.0980, B_w=0.467).
%
%   Hand-computed power-law values below (D=A*W_w^B) were derived via
%   natural-log expansion (ln, then a 4-5 term Taylor series for e^x),
%   cross-checked via an independent log10 decomposition path that agreed
%   to ~4-5 significant figures -- RelTol 1e-3 is used for those two
%   specific checks to comfortably absorb that manual-arithmetic residual
%   while still catching a wrong exponent/coefficient (which would produce
%   >>0.1% differences). Every other check here is exact rational/algebraic
%   arithmetic (AbsTol 1e-9).

    methods (Test)

        % ================================================================== %
        % LOW-LEVEL statics -- hand-picked scalars.
        % ================================================================== %

        function testTireDiameterMainFormulaHandComputed(tc)
        % D = A*W_w^B, Jet fighter/trainer row (A=1.59, B=0.302).
        %   W_w = 10,000 lb (independently chosen round number):
        %   10000^0.302 = 10^(4*0.302) = 10^1.208 = 16.1436 (derived via
        %   ln/e^x expansion, cross-checked via log10 decomposition)
        %   D = 1.59*16.1436 = 25.6683 in.
            received = F16LandingGearL2.tire_diameter(1.59, 0.302, 10000);
            tc.verifyEqual(received, 25.6683, 'RelTol', 1e-3);
        end

        function testTireWidthMainFormulaHandComputed(tc)
        % Width = A'*W_w^B', Jet fighter/trainer row (A'=0.0980, B'=0.467).
        %   W_w = 10,000 lb: 10000^0.467 = 10^1.868 = 73.790
        %   Width = 0.0980*73.790 = 7.2314 in.
            received = F16LandingGearL2.tire_width(0.0980, 0.467, 10000);
            tc.verifyEqual(received, 7.2314, 'RelTol', 1e-3);
        end

        function testTireDiameterGuardsPositivity(tc)
            tc.verifyError(@() F16LandingGearL2.tire_diameter(0, 0.302, 10000), ...
                'MATLAB:validators:mustBePositive');
            tc.verifyError(@() F16LandingGearL2.tire_diameter(1.59, 0.302, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        function testTireWidthGuardsPositivity(tc)
            tc.verifyError(@() F16LandingGearL2.tire_width(0.0980, 0.467, -5), ...
                'MATLAB:validators:mustBePositive');
        end

        function testLookupTireSizingCoeffsAllFourRows(tc)
        % [Raymer 6th ed. Table 11.1, p.344] Full 4-row table, transcribed
        % independently from the original step-9 subsystems design's own
        % reproduction (Equations & Citations item 9/9b).
            c = F16LandingGearL2.lookup_tire_sizing_coeffs('General aviation');
            tc.verifyEqual([c.A_d, c.B_d, c.A_w, c.B_w], [1.51, 0.349, 0.7150, 0.312], 'AbsTol', 1e-9);

            c = F16LandingGearL2.lookup_tire_sizing_coeffs('Business twin');
            tc.verifyEqual([c.A_d, c.B_d, c.A_w, c.B_w], [2.69, 0.251, 1.170, 0.216], 'AbsTol', 1e-9);

            c = F16LandingGearL2.lookup_tire_sizing_coeffs('Transport/bomber');
            tc.verifyEqual([c.A_d, c.B_d, c.A_w, c.B_w], [1.63, 0.315, 0.1043, 0.480], 'AbsTol', 1e-9);

            c = F16LandingGearL2.lookup_tire_sizing_coeffs('Jet fighter/trainer');
            tc.verifyEqual([c.A_d, c.B_d, c.A_w, c.B_w], [1.59, 0.302, 0.0980, 0.467], 'AbsTol', 1e-9);
        end

        function testLookupTireSizingCoeffsUnknownRowErrors(tc)
            tc.verifyError(@() F16LandingGearL2.lookup_tire_sizing_coeffs('Glider'), ...
                'F16LandingGearL2:unknownTireCategory');
        end

        % ================================================================== %
        % HIGH-LEVEL Dependent-property wiring, via a real F16LandingGearL2
        % instance and a minimal weights collaborator.
        % ================================================================== %

        function testGearLoadSplitArithmeticHandComputed(tc)
        % W_main_total = (main_pct/100)*W_TO, W_nose_total = (nose_pct/100)*W_TO,
        % W_w_main = W_main_total/2 (two main wheels), W_w_nose = W_nose_total/1.
        %   W_TO = 20,000 (independently chosen):
        %   W_main_total = 18000, W_nose_total = 2000, W_w_main = 9000, W_w_nose = 2000.
            lg = TestF16LandingGearL2.makeLG(20000);
            tc.verifyEqual(lg.W_main_total, 18000, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_nose_total, 2000,  'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_w_main,     9000,  'AbsTol', 1e-9);
            tc.verifyEqual(lg.W_w_nose,     2000,  'AbsTol', 1e-9);
        end

        function testHighLevelTireDiameterAndWidthWirePassthrough(tc)
        % Structural passthrough check (mirrors TestGeomL2.
        % testGetSExposedWingPassthrough): the Dependent getter must equal
        % the Static formula fed obj's OWN W_w_main and the Jet fighter/
        % trainer coefficients -- confirms correct DATA FLOW (right row,
        % right W_w), not a re-derivation of the power-law arithmetic
        % (already hand-verified above on the bare Static methods).
            lg = TestF16LandingGearL2.makeLG(20000);
            c = F16LandingGearL2.lookup_tire_sizing_coeffs('Jet fighter/trainer');
            tc.verifyEqual(lg.tire_diameter_main, ...
                F16LandingGearL2.tire_diameter(c.A_d, c.B_d, lg.W_w_main), 'AbsTol', 1e-9);
            tc.verifyEqual(lg.tire_width_main, ...
                F16LandingGearL2.tire_width(c.A_w, c.B_w, lg.W_w_main), 'AbsTol', 1e-9);
        end

        function testNoseTireIsDecidedFractionOfMain(tc)
        % [Raymer Table 11.1 page, prose] nose tire 60-100% of main; DECIDED
        % midpoint 0.80 (original step-9 subsystems design, item 9c).
            lg = TestF16LandingGearL2.makeLG(20000);
            tc.verifyEqual(lg.tire_diameter_nose, 0.80*lg.tire_diameter_main, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.tire_width_nose,    0.80*lg.tire_width_main,    'AbsTol', 1e-9);
        end

        function testConstructorRequiresJsonPathAndWeights(tc)
            tc.verifyError(@() F16LandingGearL2(), 'MATLAB:minrhs');
            tc.verifyError(@() F16LandingGearL2(f16a_spec_path(2)), 'MATLAB:minrhs');
        end

        function testWTONotSetErrors(tc)
        % W_TO defaults to NaN on a fresh weights object until the sizing
        % loop sets it -- accessing any gear-load quantity must error, not
        % silently propagate NaN (mirrors F16WeightsL2/F16GeomL1's
        % requireWTO convention).
            prop = F16PropL2(f16a_spec_path(2));
            g2   = F16GeomL2(f16a_spec_path(2), prop);
            w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
            % w2.W_TO left at its NaN default -- deliberately not set.
            lg = F16LandingGearL2(f16a_spec_path(2), w2);
            tc.verifyError(@() lg.W_main_total, 'F16LandingGearL2:WTONotSet');
        end

        function testReadsJSONInputs(tc)
            lg = TestF16LandingGearL2.makeLG(20000);
            tc.verifyEqual(lg.aircraft_category_table_row, 'Jet fighter/trainer');
            tc.verifyEqual(lg.main_pct, 90, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.nose_pct, 10, 'AbsTol', 1e-9);
            tc.verifyEqual(lg.nose_tire_fraction_of_main, 0.80, 'AbsTol', 1e-9);
        end

        function testDerivedPropertiesLiveRecompute(tc)
        % Mutate W_TO in place (optimizer/sizing-loop style) and verify the
        % Dependent getters track it with NO reconstruction.
            lg = TestF16LandingGearL2.makeLG(20000);
            d0 = lg.tire_diameter_main;
            lg.weights.W_TO = 40000;   % doubling W_TO
            tc.verifyNotEqual(lg.tire_diameter_main, d0, ...
                'tire_diameter_main must recompute live after weights.W_TO mutates.');
            tc.verifyEqual(lg.W_w_main, 0.9*40000/2, 'AbsTol', 1e-9);
        end

        function testDerivedPropertiesAreReadOnly(tc)
            lg = TestF16LandingGearL2.makeLG(20000);
            tc.verifyError(@() setfield(lg, 'tire_diameter_main', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(lg, 'W_w_main', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsHandleClass(tc)
        % REQUIRED per the matlab-oop-expert review (F16LandingGearL2.m
        % header): no abstract Base tier to inherit handle semantics from
        % transitively, so this class must state `< handle` directly.
            lg = TestF16LandingGearL2.makeLG(20000);
            tc.verifyTrue(isa(lg, 'handle'));
        end

        % ------------------------------------------------------------------ %
        % DELIBERATE TODO -- gear bay-volume packaging (original step-9
        % subsystems design, item 11).
        % NOT a failure to fix -- PINS the documented, correctly-erroring
        % citation-gap behavior of BOTH F16LandingGearL2.bay_volume and
        % F16LandingGearL3.bay_volume (one test, since both classes share
        % the exact same open gap; see this file's header for why this is
        % not double-counted with a second TODO test in
        % TestF16LandingGearL3.m).
        % ------------------------------------------------------------------ %

        function testTODO_GearBayVolumePackagingNotInRepo(tc)
        %TESTTODO_GEARBAYVOLUMEPACKAGINGNOTINREPO  Documented citation GAP
        %   (original step-9 subsystems design, Equations & Citations item 11).
        %
        %   WHAT IS MISSING: no textbook formula for tire+strut bay-volume
        %   packaging was found anywhere in this repo. Raymer's Ch.11 covers
        %   tire/strut/shock-absorber SIZE (fully implemented and tested
        %   above), not a bay-VOLUME packaging estimate the way Nicolai's
        %   Ch.8 fuel/avionics sections give one.
        %
        %   HOW THIS TEST DOCUMENTS IT: F16LandingGearL2.bay_volume and
        %   F16LandingGearL3.bay_volume are documented to error rather than
        %   fabricate a geometric-envelope assumption. This test PINS that
        %   correct, current behavior with each class's OWN documented
        %   identifier (L3 issues its own, not a reused L2 one -- see
        %   F16LandingGearL3.m's header). Matches the convention of
        %   TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo.
        %   Resolving the gap means supplying a citation (or an explicit
        %   "engineering judgment, uncited" label), implementing a real
        %   bay-volume formula, and REPLACING these verifyError calls with a
        %   hand-computed expected-value check -- do not silently delete
        %   this test without doing that.
            prop = F16PropL2(f16a_spec_path(2));
            g2   = F16GeomL2(f16a_spec_path(2), prop);
            w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
            w2.W_TO = 31377;
            lg2 = F16LandingGearL2(f16a_spec_path(2), w2);
            tc.verifyError(@() lg2.bay_volume(), 'F16LandingGearL2:bayVolumeNotAvailable', ...
                'TODO (documented gap, EXPECTED to error): no gear bay-volume packaging formula in this repo.');

            g3 = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
            w3 = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO = 31377;
            lg3 = F16LandingGearL3(f16a_spec_path(3), w3);
            tc.verifyError(@() lg3.bay_volume(), 'F16LandingGearL3:bayVolumeNotAvailable', ...
                'TODO (documented gap, EXPECTED to error): F16LandingGearL3 shares the same open gap as L2.');
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function lg = makeLG(W_TO)
        %MAKELG  Real F16LandingGearL2 wired to a real F16WeightsL2, with
        %   W_TO set to the given plausible sizing-loop STATE value.
            prop = F16PropL2(f16a_spec_path(2));
            g2   = F16GeomL2(f16a_spec_path(2), prop);
            w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
            w2.W_TO = W_TO;
            lg = F16LandingGearL2(f16a_spec_path(2), w2);
        end

    end

end

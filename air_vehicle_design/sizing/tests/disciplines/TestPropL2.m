classdef TestPropL2 < matlab.unittest.TestCase
%TESTPROPL2  Unit tests for the PropL2 toolbox and the F16PropL2 student class.
%
%   TIER-1 UNIT TESTS ONLY. Every "expected" is one of:
%     (a) an INDEPENDENT published datum — a Mattingly worked-example result
%         (0.4792 / 0.5390), a Mattingly Eq. 3.55a/b coefficient, a Raymer
%         parametric-sizing formula constant, a real engine spec, or a T.O.
%         measurement; or
%     (b) HAND ARITHMETIC from the cited formula with my own numbers.
%   NOTHING here reads f16a_ground_truth.json or any Brandt engine-MODEL output
%   (α_dry/α_AB/α_eff, installed TSFC 0.70/2.20, ...) as an expected value.
%   The Mattingly-model-vs-Brandt-model closeness comparison at the six
%   constraint conditions is INFORMATIONAL and lives in
%   examples/F16A/propulsion_brandt_comparison.m — NOT here. (Those comparisons
%   pit two different engine models against each other and were previously
%   "asserted" with a blanket 30% tolerance; that is not a unit test.)
%
%   Constructor is required-JSON-path: F16PropL2(f16a_spec_path(2)). The no-arg
%   form now errors MATLAB:minrhs (testNoArgConstructorErrors).
%
%   FORMULA / SOURCE REFERENCES:
%     Thrust lapse — low-BPR mixed turbofan [Mattingly AED 2nd ed., Eq. 2.54]:
%       AB:  θ₀≤TR → α_AB = δ₀ ;  θ₀>TR → α_AB = δ₀(1 − 3.5(θ₀−TR)/θ₀)
%       Mil: θ₀≤TR → α_mil = 0.6δ₀ ; θ₀>TR → α_mil = 0.6δ₀(1 − 3.8(θ₀−TR)/θ₀)
%     TSFC [Mattingly Eq. 3.12 + 3.55, low-BPR mixed turbofan]:
%       TSFC = (C1 + C2·M)·√θ, 1/hr;  mil C1/C2 = 0.90/0.30, AB = 1.60/0.27.
%       Installed = uninstalled × install-factor (1.08, Brandt Miss!C25).
%     Throttle ratio TR = T_t4_max/T_t4_SLS [Mattingly Eq. D.6]; with T_t4_SLS
%       unknown it defaults to T_t4_max → TR = 1.0.
%     Parametric engine sizing [Raymer Eqs. 10.11/10.13/10.15].

    properties (Constant)
        TOL_EXACT = 1e-12   % closed-form algebra; bit-for-bit reproducible
        % Published Mattingly low-BPR mixed-turbofan TSFC coefficients
        % [Mattingly Eq. 3.55a (mil) / 3.55b (AB)] — used as INPUTS to the
        % low-level TSFC primitives, and as the expected in the coeff-table test.
        C1_MIL = 0.90
        C2_MIL = 0.30
        C1_AB  = 1.60
        C2_AB  = 0.27
    end

    methods (Test)

        % ================================================================== %
        % CONSTRUCTOR CONTRACT
        % ================================================================== %

        function testNoArgConstructorErrors(tc)
            % Constructor REQUIRES a JSON path now (arguments block, no default).
            tc.verifyError(@() F16PropL2(), 'MATLAB:minrhs');
        end

        function testTSLWetLoadedFromJson(tc)
            % 23,770 lbf = F100-PW-200 AB SLS thrust (engine SPEC datum)
            % [T.O. 1F-16A-1 Sec. I; Brandt Main!D29].
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyEqual(g.T_SL_wet, 23770, 'AbsTol', 1.0);
        end

        function testTSLMilLoadedFromJson(tc)
            % 15,000 lbf = military (dry) SLS thrust (engine SPEC datum)
            % [T.O. 1F-16A-1 Sec. I; Brandt Main!C29].
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyEqual(g.T_SL_mil, 15000, 'AbsTol', 1.0);
        end

        function testTSLWetConsistentWithF100PW100(tc)
            % Independent cross-check vs the F100-PW-100 SLS thrust 23,700 lbf
            % [Mattingly Table C.4]; -200 variant is 0.3% higher, RelTol 1%.
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyEqual(g.T_SL_wet, 23700, 'RelTol', 0.01);
        end

        % ================================================================== %
        % LOW-LEVEL: thrust_lapse_AB / thrust_lapse_mil  (Mattingly Eq. 2.54)
        % Synthetic inputs + hand arithmetic — no atmosphere, no Brandt value.
        % ================================================================== %

        function testLapseABBelowTRReturnsDelta0(tc)
            % θ₀ ≤ TR branch: α_AB = δ₀ exactly. [Mattingly Eq. 2.54a]
            % Synthetic δ₀=0.5, θ₀=0.8, TR=1.0 → expected 0.5.
            tc.verifyEqual(PropL2.thrust_lapse_AB(0.5, 0.8, 1.0), 0.5, ...
                'AbsTol', tc.TOL_EXACT, 'Below-TR AB lapse must equal δ₀.');
        end

        function testLapseABAboveTRHandComputed(tc)
            % θ₀ > TR branch, hand-evaluated with the published coeff 3.5:
            %   α_AB = 0.9·(1 − 3.5·(1.2−1.0)/1.2) = 0.9·0.4166667 = 0.375
            % [Mattingly Eq. 2.54a]. A wrong 3.5 or wrong branch is caught.
            tc.verifyEqual(PropL2.thrust_lapse_AB(0.9, 1.2, 1.0), 0.375, ...
                'AbsTol', 1e-12, 'Above-TR AB lapse must equal δ₀(1−3.5(θ₀−TR)/θ₀).');
        end

        function testLapseMilBelowTRReturns06Delta0(tc)
            % θ₀ ≤ TR branch: α_mil = 0.6·δ₀. [Mattingly Eq. 2.54b]
            % Synthetic δ₀=0.5, θ₀=0.8, TR=1.0 → 0.6·0.5 = 0.30.
            tc.verifyEqual(PropL2.thrust_lapse_mil(0.5, 0.8, 1.0), 0.30, ...
                'AbsTol', tc.TOL_EXACT, 'Below-TR mil lapse must equal 0.6·δ₀.');
        end

        function testLapseMilPrimitive30kft_M15(tc)
            % GENUINE ANCHOR — Mattingly AED 2nd ed. Part-12 worked example.
            % 30 kft, M=1.5: θ,δ = 0.7940, 0.2975 [App. B]; TR = 1.07 (Part-12
            % AAF vehicle, NOT the F-16). θ₀ = θ·(1+0.2M²), δ₀ = δ·(1+0.2M²)^3.5.
            %   θ₀ = 0.7940·1.45 = 1.1513 ;  δ₀ = 0.2975·1.45^3.5 = 1.09214
            %   α_mil = 0.6·1.09214·(1 − 3.8·(1.1513−1.07)/1.1513) = 0.4795
            % Published result: 0.4792. AbsTol 1e-3 = atmosphere-table rounding.
            TR_part12 = 1.07;   M = 1.5;
            theta_0 = 0.7940 * (1 + 0.2*M^2);
            delta_0 = 0.2975 * (1 + 0.2*M^2)^3.5;
            received = PropL2.thrust_lapse_mil(delta_0, theta_0, TR_part12);
            tc.verifyEqual(received, 0.4792, 'AbsTol', 1e-3, ...
                'Must match Mattingly Part-12 worked example 0.4792 ± 0.001.');
        end

        function testLapseMilPrimitiveHotDay2kft(tc)
            % GENUINE ANCHOR — Mattingly Part-12 worked example, 2 kft hot day,
            % M=0 (non-ISA): θ₀ = 1.0796, δ₀ = 0.9298 [Part-12], TR = 1.07.
            %   α_mil = 0.6·0.9298·(1 − 3.8·(1.0796−1.07)/1.0796) = 0.5390
            % Published result: 0.5390. AbsTol 1e-3.
            received = PropL2.thrust_lapse_mil(0.9298, 1.0796, 1.07);
            tc.verifyEqual(received, 0.5390, 'AbsTol', 1e-3, ...
                'Must match Mattingly Part-12 worked example 0.5390 ± 0.001.');
        end

        % ================================================================== %
        % LOW-LEVEL: TSFC  (Mattingly Eq. 3.12 + 3.55)
        % ================================================================== %

        function testTSFCMilAtSLSReducesToC1(tc)
            % At M=0, θ=1: TSFC = (C1_mil + 0)·√1 = C1_mil = 0.90 [Eq. 3.55a].
            tc.verifyEqual(PropL2.TSFC_mil(tc.C1_MIL, tc.C2_MIL, 0.0, 1.0), 0.90, ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testTSFCABAtSLSReducesToC1(tc)
            % At M=0, θ=1: TSFC = C1_AB = 1.60 [Eq. 3.55b].
            tc.verifyEqual(PropL2.TSFC_AB(tc.C1_AB, tc.C2_AB, 0.0, 1.0), 1.60, ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testTSFCMilHandComputed(tc)
            % Exercise the full (C1+C2·M)·√θ structure with hand arithmetic:
            %   (0.90 + 0.30·0.8)·√0.75 = 1.14·0.8660254 = 0.9872690.
            % Catches a dropped Mach term or a missing √θ. [Mattingly Eq. 3.12]
            tc.verifyEqual(PropL2.TSFC_mil(tc.C1_MIL, tc.C2_MIL, 0.8, 0.75), ...
                0.987269025, 'AbsTol', 1e-6);
        end

        function testTSFCIncreasesWithMach(tc)
            % Qualitative: TSFC rises with Mach (C2>0). [Mattingly Eq. 3.55a]
            tc.verifyGreaterThan(PropL2.TSFC_mil(tc.C1_MIL, tc.C2_MIL, 0.9, 1.0), ...
                PropL2.TSFC_mil(tc.C1_MIL, tc.C2_MIL, 0.5, 1.0));
        end

        function testTSFCABExceedsMil(tc)
            % Qualitative: afterburner TSFC exceeds mil at any common condition.
            theta = 0.75;  M = 0.87;
            tc.verifyGreaterThan(PropL2.TSFC_AB(tc.C1_AB, tc.C2_AB, M, theta), ...
                PropL2.TSFC_mil(tc.C1_MIL, tc.C2_MIL, M, theta));
        end

        % ================================================================== %
        % LOW-LEVEL: TSFC coefficient table + throttle ratio
        % ================================================================== %

        function testLookupTSFCCoeffs(tc)
            % lookup_TSFC_coeffs must return the published Mattingly low-BPR
            % coefficients [Eq. 3.55a mil, 3.55b AB].
            c = PropL2.lookup_TSFC_coeffs("low_bypass_turbofan_AB");
            tc.verifyEqual(c.C1_mil, 0.90, 'AbsTol', tc.TOL_EXACT, 'C1_mil');
            tc.verifyEqual(c.C2_mil, 0.30, 'AbsTol', tc.TOL_EXACT, 'C2_mil');
            tc.verifyEqual(c.C1_AB,  1.60, 'AbsTol', tc.TOL_EXACT, 'C1_AB');
            tc.verifyEqual(c.C2_AB,  0.27, 'AbsTol', tc.TOL_EXACT, 'C2_AB');
        end

        function testLookupTSFCCoeffsUnknownThrows(tc)
            tc.verifyError(@() PropL2.lookup_TSFC_coeffs("ramjet"), ...
                'PropL2:unknownEngineType');
        end

        function testComputeTRRatio(tc)
            % TR = T_t4_max / T_t4_SLS [Mattingly Eq. D.6] — independent ratios.
            tc.verifyEqual(PropL2.compute_TR(3300, 3000), 1.10, 'AbsTol', 1e-12);
            tc.verifyEqual(PropL2.compute_TR(3000, 3000), 1.00, 'AbsTol', 1e-12);
        end

        function testComputeTRDefaultsToUnity(tc)
            % With T_t4_SLS omitted, compute_TR defaults it to T_t4_max → TR=1.0.
            tc.verifyEqual(PropL2.compute_TR(3000), 1.0, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % HIGH-LEVEL: F16PropL2 student-class delegation + install factor
        % ================================================================== %

        function testGetTSFCAtSLS(tc)
            % The PublicBase get_TSFC at ~SLS static (M~0, θ~1) must approach
            % the Mattingly mil coefficient C1_mil = 0.90 1/hr [Eq. 3.55a]. The
            % tiny M=0.01 adds C2·M = 0.003, so AbsTol 0.01 covers the ram term.
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyEqual(g.get_TSFC(AircraftState(0, 0.01)), 0.90, 'AbsTol', 0.01);
        end

        function testGetTSFCDelegatesToComputeMil(tc)
            % Interface consistency: get_TSFC (Breguet default) == compute_TSFC_mil.
            g = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.5);
            tc.verifyEqual(g.get_TSFC(state), g.compute_TSFC_mil(state), ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testThrustLapseDelegatesToComputeAB(tc)
            % Interface consistency: thrust_lapse (PropulsionBase API, AB basis)
            % == compute_thrust_lapse_AB.
            g = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.7);
            tc.verifyEqual(g.thrust_lapse(state), g.compute_thrust_lapse_AB(state), ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testThrustLapseDecreasesWithAltitude(tc)
            % Qualitative: AB lapse falls with altitude at fixed Mach.
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyGreaterThan(g.thrust_lapse(AircraftState(0, 0.87)), ...
                g.thrust_lapse(AircraftState(36000, 0.87)));
        end

        function testStudentClassTSFCABExceedsMil(tc)
            % Qualitative, through the student-class API.
            g = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 0.87);
            tc.verifyGreaterThan(g.compute_TSFC_AB(state), g.compute_TSFC_mil(state));
        end

        function testTSFCInstalledIsMilTimes108(tc)
            % Installed mil TSFC = uninstalled × 1.08 [factor Brandt Miss!C25].
            % The ratio is what this checks; the factor 1.08 is the external
            % datum (do NOT double-apply against Brandt's already-installed
            % 0.70 — VnV/BrandtF16A/todo.md 2026-07-24 entry 4).
            g = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            tc.verifyEqual(g.compute_TSFC_installed(state), ...
                g.compute_TSFC_mil(state) * 1.08, 'RelTol', 1e-12);
        end

        function testTSFCABInstalledIsABTimes108(tc)
            % Installed AB TSFC = uninstalled AB × 1.08 [factor Brandt Miss!C25].
            g = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            tc.verifyEqual(g.compute_TSFC_AB_installed(state), ...
                g.compute_TSFC_AB(state) * 1.08, 'RelTol', 1e-12);
        end

        function testUnknownEngineTypeThrows(tc)
            % A mutated (unknown) engine_type must error through get_TSFC.
            g = F16PropL2(f16a_spec_path(2));
            g.engine_type = "ramjet";
            tc.verifyError(@() g.get_TSFC(AircraftState(0, 0.5)), ...
                'PropL2:unknownEngineType');
        end

        % ================================================================== %
        % DERIVED (Dependent) TR — live-recompute + read-only guards
        % (templates: TestGeomL2 testWettedAreasLiveOnRead /
        %  testDerivedPropertiesAreReadOnly)
        % ================================================================== %

        function testTRValueIsUnity(tc)
            % TR = 1.0: T_t4_SLS unknown → Eq. D.6 default (T_t4_max/T_t4_max).
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyEqual(g.TR, 1.0, 'AbsTol', tc.TOL_EXACT);
        end

        function testTRLiveRecomputeOnInputMutation(tc)
            % get.TR recomputes live from T_t4_max_F on every read (no cached
            % copy). NOTE: TR = T_t4_max/T_t4_SLS and compute_TR defaults
            % T_t4_SLS to T_t4_max, so TR is identically 1.0 for ANY T_t4_max_F
            % — mutating the input cannot change the value. This guard confirms
            % the derived read stays LIVE and valid (1.0) after in-place
            % mutation, but by construction it cannot demonstrate value-tracking
            % (flagged in the test-writer report as a degenerate getter to
            % review with the OOP/equations experts).
            g = F16PropL2(f16a_spec_path(2));
            g.T_t4_max_F = g.T_t4_max_F + 500;   % mutate the input feeding get.TR
            tc.verifyEqual(g.TR, 1.0, 'AbsTol', tc.TOL_EXACT, ...
                'TR must recompute live on read (invariant 1.0 by the Eq. D.6 default).');
        end

        function testTRIsReadOnly(tc)
            % Assigning to the derived TR must error — it is an output with no
            % set-method. (setfield used because you cannot assign inside an
            % anonymous function.)
            g = F16PropL2(f16a_spec_path(2));
            tc.verifyError(@() setfield(g, 'TR', 1.5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % ================================================================== %
        % PARAMETRIC ENGINE SIZING  (Raymer Eqs. 10.11 / 10.13 / 10.15)
        % Unwired outputs; still unit-tested for formula correctness.
        % ================================================================== %

        function testEngineLengthABvsTO(tc)
            % GENUINE ANCHOR. Raymer Eq. 10.11 L = 0.255·T^0.4·M^0.2 at
            % T=23,770 lbf, M=2.0 → ~16.50 ft. Reference: T.O. 1F-16A-1
            % F100-PW-200 total length 191.16 in = 15.930 ft. Eq. 10.11 is a
            % first-order statistical regression → RelTol 0.10 is appropriate
            % (the ~3.6% gap is the regression's methodology scatter).
            received = PropL2.engine_length_AB(23770, 2.0);
            tc.verifyEqual(received, 191.16/12, 'RelTol', 0.10, ...
                'engine_length_AB(23770,2.0) within 10% of T.O. F100-PW-200 length (15.93 ft).');
        end

        function testSFCMaxABFormula(tc)
            % Hand-evaluation of Raymer Eq. 10.13 SFC = 2.1·exp(−0.12·BPR) at
            % BPR=0.69: 2.1·exp(−0.0828) = 2.1·0.9205367 = 1.933127 (own
            % arithmetic; a coefficient/exponent typo is caught).
            tc.verifyEqual(PropL2.SFC_max_AB(0.69), 1.933127, 'AbsTol', 1e-4);
        end

        function testSFCCruiseABFormula(tc)
            % Hand-evaluation of Raymer Eq. 10.15 SFC = 1.04·exp(−0.186·BPR) at
            % BPR=0.69: 1.04·exp(−0.12834) = 1.04·0.8795543 = 0.914736.
            tc.verifyEqual(PropL2.SFC_cruise_AB(0.69), 0.914736, 'AbsTol', 1e-4);
        end

        function testSFCMaxABExceedsCruiseAB(tc)
            % Qualitative: max-throttle AB SFC (Eq. 10.13) must far exceed the
            % cruise AB SFC (Eq. 10.15) — afterburner roughly 2x the fuel rate.
            tc.verifyGreaterThan(PropL2.SFC_max_AB(0.69), 1.5 * PropL2.SFC_cruise_AB(0.69));
        end

        % ================================================================== %
        % INHERITANCE / INTERFACE COMPLIANCE
        % ================================================================== %

        function testIsaPropulsionBase(tc)
            tc.verifyTrue(isa(F16PropL2(f16a_spec_path(2)), 'PropulsionBase'));
        end

        function testIsaPropulsionModelL2(tc)
            tc.verifyTrue(isa(F16PropL2(f16a_spec_path(2)), 'PropulsionModelL2'));
        end

        function testNotIsaPropulsionModelL1(tc)
            tc.verifyFalse(isa(F16PropL2(f16a_spec_path(2)), 'PropulsionModelL1'), ...
                'L2 must NOT inherit from the L1 enforcer.');
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16PropL2(f16a_spec_path(2)), 'handle'));
        end

    end

end

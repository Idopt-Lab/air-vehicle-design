classdef TestPropL1 < matlab.unittest.TestCase
%TESTPROPL1  Unit tests for the PropL1 toolbox and the F16PropL1 student class.
%
%   TIER-1 UNIT TESTS ONLY — every "expected" is either an independent
%   published datum (Raymer Table 3.3, Martins Eq. 10.7/10.9, a standard-
%   atmosphere table, or a real engine spec) or hand arithmetic. NOTHING here
%   reads f16a_ground_truth.json or any Brandt engine-MODEL output as an
%   expected value — the Mattingly/L1-vs-Brandt closeness comparison lives in
%   examples/F16A/sanity_checks/propulsion_brandt_comparison.m (informational, not a test).
%
%   Constructor is required-JSON-path: F16PropL1(f16a_spec_path(1)). The no-arg
%   form now errors MATLAB:minrhs (covered by testNoArgConstructorErrors).
%
%   FORMULA / SOURCE REFERENCES:
%     thrust lapse: α = σ^m, σ = ρ/ρ_SL, m from engine-type table
%       [J.R.R.A. Martins, AE481 course notes (metabook), Eq. 10.7 (turbojet,
%        m=1.0) / Eq. 10.9 (turbofan, m=0.6)] — citation resolved to Martins
%        per VnV/BrandtF16A/todo.md 2026-07-24 Entry 1.
%     TSFC: categorical cruise/loiter lookup by engine type
%       [Raymer 6th ed. Table 3.3, values in 1/hr]:
%         low_bypass_turbofan(_AB): cruise 0.80 / loiter 0.70
%         high_bypass_turbofan:     cruise 0.50 / loiter 0.40
%         turbojet(_AB):             cruise 0.90 / loiter 0.80
%       [Raymer 6th ed. Table 3.4, values in lb/hr/bhp, a DIFFERENT
%        power-specific quantity -- fixed 2026-07-30, was previously a
%        duplicate of the turbojet row]:
%         turboprop:                 cruise 0.50 / loiter 0.60

    properties (Constant)
        % Exact-arithmetic tolerance for closed-form table/power-law checks
        % (no atmosphere model involved) — these are bit-for-bit reproducible.
        TOL_EXACT = 1e-12
        % ρ_SL, English units [Mattingly App. B]. Used only to build a density
        % argument whose ratio to ρ_SL is a known constant (never as an
        % expected value).
        RHO_SL = 0.002377
    end

    methods (Test)

        % ================================================================== %
        % CONSTRUCTOR CONTRACT
        % ================================================================== %

        function testNoArgConstructorErrors(tc)
            % The constructor now REQUIRES a JSON path (arguments block, no
            % default) — the old silent no-arg default is gone.
            tc.verifyError(@() F16PropL1(), 'MATLAB:minrhs');
        end

        function testTSLWetLoadedFromJson(tc)
            % Constructor must read T_SL_wet from the L1 input JSON. 23,770 lbf
            % is the F100-PW-200 AB (max) SLS thrust — a genuine engine SPEC
            % datum [T.O. 1F-16A-1 Sec. I; Brandt Main!D29], not a Brandt-model
            % output. Hardcoded here (not read from any ground-truth file).
            g = F16PropL1(f16a_spec_path(1));
            tc.verifyEqual(g.T_SL_wet, 23770, 'AbsTol', 1.0, ...
                'T_SL_wet must load as the F100-PW-200 AB SLS thrust (23,770 lbf).');
        end

        function testTSLWetConsistentWithF100PW100(tc)
            % Cross-check T_SL_wet against the F100-PW-100 published SLS thrust
            % (predecessor engine). 23,700 lbf [Mattingly: Aircraft Engine Design, 2nd edition, Table
            % C.4, p. 522] is an INDEPENDENT reference; the -200 (23,770) is
            % 0.3% above it, so RelTol 1% brackets both.
            g = F16PropL1(f16a_spec_path(1));
            tc.verifyEqual(g.T_SL_wet, 23700, 'RelTol', 0.01, ...
                'T_SL_wet must agree with F100-PW-100 App.C reference (23,700 lbf) within 1%.');
        end

        % ================================================================== %
        % LOW-LEVEL: sigma_lapse  (α = σ^m)
        % ================================================================== %

        function testSigmaLapseAtSeaLevelIsOne(tc)
            % Identity: at ρ=ρ_SL, σ=1, so α=1^m=1 for ANY m. Independent
            % mathematical fact (1 raised to any power is 1).
            tc.verifyEqual(PropL1.sigma_lapse(tc.RHO_SL, 0.6), 1.0, ...
                'AbsTol', tc.TOL_EXACT, 'α must be exactly 1 at sea-level density.');
            tc.verifyEqual(PropL1.sigma_lapse(tc.RHO_SL, 1.0), 1.0, ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testSigmaLapseHalfDensityHandComputed(tc)
            % Feed a density of exactly 0.5·ρ_SL so σ=0.5 by construction; the
            % expected is hand-evaluated 0.5^m (independent arithmetic), which
            % catches a wrong ρ_SL, an inverted ratio, or a wrong exponent path.
            %   0.5^0.6 = 0.659754 (turbofan, Martins Eq. 10.9)
            %   0.5^1.0 = 0.500000 (turbojet, Martins Eq. 10.7)
            rho_half = 0.5 * tc.RHO_SL;
            tc.verifyEqual(PropL1.sigma_lapse(rho_half, 0.6), 0.659753955386447, ...
                'AbsTol', 1e-12, 'σ^0.6 at half sea-level density (turbofan).');
            tc.verifyEqual(PropL1.sigma_lapse(rho_half, 1.0), 0.5, ...
                'AbsTol', tc.TOL_EXACT, 'σ^1.0 at half sea-level density (turbojet).');
        end

        % ================================================================== %
        % LOW-LEVEL: lapse-exponent table  (matches the cited Martins Eqs.)
        % ================================================================== %

        function testLapseExponentTurbofanIs0p6(tc)
            % m=0.6 for the low-bypass AB turbofan (F-16 engine class).
            % [Martins metabook Eq. 10.9]
            tc.verifyEqual(PropL1.lookup_lapse_exponent('low_bypass_turbofan_AB'), 0.6, ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testLapseExponentTurbojetIs1p0(tc)
            % m=1.0 for a turbojet — thrust scales linearly with density.
            % [Martins metabook Eq. 10.7]
            tc.verifyEqual(PropL1.lookup_lapse_exponent('turbojet_AB'), 1.0, ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testLapseExponentTurbojetExceedsTurbofan(tc)
            % Qualitative: a turbojet sheds thrust faster with altitude, so its
            % lapse exponent must exceed the turbofan's. [Martins Eqs. 10.7/10.9]
            tc.verifyGreaterThan(PropL1.lookup_lapse_exponent('turbojet'), ...
                PropL1.lookup_lapse_exponent('low_bypass_turbofan_AB'));
        end

        function testLapseExponentUnknownThrows(tc)
            tc.verifyError(@() PropL1.lookup_lapse_exponent('ramjet'), ...
                'PropL1:unknownEngineType');
        end

        % ================================================================== %
        % LOW-LEVEL: TSFC table  (transcription of Raymer Table 3.3)
        % ================================================================== %
        % Each expected is Raymer 6th ed. Table 3.3's published cruise/loiter
        % SFC for that engine class — an EXTERNAL datum. These verify the code
        % transcribed the published table faithfully (exact match).

        function testTSFCTableLowBypassTurbofan(tc)
            for key = {'low_bypass_turbofan', 'low_bypass_turbofan_AB'}
                tbl = PropL1.lookup_TSFC_table(key{1});
                tc.verifyEqual(tbl.cruise, 0.80, 'AbsTol', tc.TOL_EXACT, ...
                    sprintf('%s cruise TSFC must be Raymer Table 3.3 = 0.80 1/hr.', key{1}));
                tc.verifyEqual(tbl.loiter, 0.70, 'AbsTol', tc.TOL_EXACT, ...
                    sprintf('%s loiter TSFC must be Raymer Table 3.3 = 0.70 1/hr.', key{1}));
            end
        end

        function testTSFCTableHighBypassTurbofan(tc)
            tbl = PropL1.lookup_TSFC_table('high_bypass_turbofan');
            tc.verifyEqual(tbl.cruise, 0.50, 'AbsTol', tc.TOL_EXACT);   % [Raymer Table 3.3]
            tc.verifyEqual(tbl.loiter, 0.40, 'AbsTol', tc.TOL_EXACT);
        end

        function testTSFCTableTurbojet(tc)
            for key = {'turbojet', 'turbojet_AB'}
                tbl = PropL1.lookup_TSFC_table(key{1});
                tc.verifyEqual(tbl.cruise, 0.90, 'AbsTol', tc.TOL_EXACT);   % [Raymer Table 3.3]
                tc.verifyEqual(tbl.loiter, 0.80, 'AbsTol', tc.TOL_EXACT);
            end
        end

        function testTSFCTableTurboprop(tc)
        % Table 3.4 Cbhp [lb/hr/bhp], not Table 3.3's 1/hr -- must also warn,
        % since this value is not thrust-basis like every other engine_type.
            tbl = tc.verifyWarning(@() PropL1.lookup_TSFC_table('turboprop'), ...
                'PropL1:turbopropIsPowerBasis', ...
                'turboprop must warn that its TSFC is power-basis, not thrust-basis.');
            tc.verifyEqual(tbl.cruise, 0.50, 'AbsTol', tc.TOL_EXACT);   % [Raymer Table 3.4]
            tc.verifyEqual(tbl.loiter, 0.60, 'AbsTol', tc.TOL_EXACT);
        end

        function testTSFCTableUnknownThrows(tc)
            tc.verifyError(@() PropL1.lookup_TSFC_table('ramjet'), ...
                'PropL1:unknownEngineType');
        end

        % ================================================================== %
        % HIGH-LEVEL: F16PropL1.get_thrust_lapse / thrust_lapse
        % ================================================================== %

        function testThrustLapseSeaLevelIsMachIndependent(tc)
            % L1 has NO Mach term (density-only). At SLS σ=1, so α=1 for every
            % Mach. Independent fact (σ=1 → 1); also confirms the L1 model
            % carries no Mach correction.
            g = F16PropL1(f16a_spec_path(1));
            a_lo = g.get_thrust_lapse(AircraftState(0, 0.3));
            a_hi = g.get_thrust_lapse(AircraftState(0, 0.9));
            tc.verifyEqual(a_lo, 1.0, 'AbsTol', 1e-4, 'α must be ~1 at SLS (σ=1).');
            tc.verifyEqual(a_hi, 1.0, 'AbsTol', 1e-4);
            tc.verifyEqual(a_lo, a_hi, 'AbsTol', 1e-12, ...
                'L1 α must be identical across Mach at fixed altitude (no Mach term).');
        end

        function testThrustLapseAtAltitudeVsPublishedISA(tc)
            % Independent quantitative check of the full α = σ^m chain at
            % 36,000 ft. The standard-atmosphere density ratio at 36 kft is
            % σ = 0.2971 [Mattingly App. B ISA table]; hand-evaluating the
            % turbofan law gives
            %   α = 0.2971^0.6 = 0.4828   (own arithmetic).
            % 'received' comes from AircraftState's atmosisa density (an
            % independent atmosphere source from the published table), so an
            % AbsTol of 0.01 covers atmosisa-vs-table σ round-off
            % (~0.3% in σ → ~0.2% in α) plus the table's 4-digit rounding.
            g = F16PropL1(f16a_spec_path(1));
            received = g.get_thrust_lapse(AircraftState(36000, 0.87));
            tc.verifyEqual(received, 0.4828, 'AbsTol', 0.01, ...
                'α at 36 kft must match σ^0.6 with σ from the published ISA table.');
        end

        function testThrustLapseDecreasesWithAltitude(tc)
            % Monotonic: σ falls with altitude, so α must fall. [Martins Eq. 10.9]
            g = F16PropL1(f16a_spec_path(1));
            tc.verifyGreaterThan(g.get_thrust_lapse(AircraftState(0, 0.5)), ...
                g.get_thrust_lapse(AircraftState(36000, 0.5)), ...
                'Thrust lapse must decrease with altitude.');
        end

        function testThrustLapseEntryPointsAgree(tc)
            % Interface consistency: the PropulsionBase API method
            % thrust_lapse and the L1-specific get_thrust_lapse are two public
            % entry points that must return the identical value.
            g = F16PropL1(f16a_spec_path(1));
            state = AircraftState(20000, 0.7);
            tc.verifyEqual(g.thrust_lapse(state, "AB"), g.get_thrust_lapse(state), ...
                'AbsTol', tc.TOL_EXACT, 'thrust_lapse and get_thrust_lapse must agree.');
        end

        % ================================================================== %
        % HIGH-LEVEL: F16PropL1.get_TSFC / lookup_TSFC (Mach segment logic)
        % ================================================================== %

        function testGetTSFCCruiseSegment(tc)
            % M >= 0.4 selects the cruise column (0.80 1/hr) [Raymer Table 3.3].
            g = F16PropL1(f16a_spec_path(1));
            tc.verifyEqual(g.get_TSFC(AircraftState(0, 0.5)), 0.80, ...
                'AbsTol', tc.TOL_EXACT, 'M>=0.4 must return cruise TSFC 0.80 1/hr.');
        end

        function testGetTSFCLoiterSegment(tc)
            % M < 0.4 selects the loiter column (0.70 1/hr) [Raymer Table 3.3].
            g = F16PropL1(f16a_spec_path(1));
            tc.verifyEqual(g.get_TSFC(AircraftState(0, 0.2)), 0.70, ...
                'AbsTol', tc.TOL_EXACT, 'M<0.4 must return loiter TSFC 0.70 1/hr.');
        end

        function testGetTSFCEntryPointsAgree(tc)
            % Interface consistency: get_TSFC and lookup_TSFC must agree.
            g = F16PropL1(f16a_spec_path(1));
            state = AircraftState(0, 0.5);
            tc.verifyEqual(g.get_TSFC(state), g.lookup_TSFC(state), ...
                'AbsTol', tc.TOL_EXACT);
        end

        function testUnknownEngineTypeThrows(tc)
            % A mutated (unknown) engine_type must error rather than silently
            % returning a wrong TSFC.
            g = F16PropL1(f16a_spec_path(1));
            g.engine_type = "ramjet";
            tc.verifyError(@() g.lookup_TSFC(AircraftState(0, 0.5)), ...
                'PropL1:unknownEngineType');
        end

        % ================================================================== %
        % INHERITANCE / INTERFACE COMPLIANCE
        % ================================================================== %

        function testIsaPropulsionBase(tc)
            tc.verifyTrue(isa(F16PropL1(f16a_spec_path(1)), 'PropulsionBase'), ...
                'F16PropL1 must satisfy the PropulsionBase contract.');
        end

        function testIsaPropulsionModelL1(tc)
            tc.verifyTrue(isa(F16PropL1(f16a_spec_path(1)), 'PropulsionModelL1'));
        end

        function testNotIsaPropulsionModelL2(tc)
            tc.verifyFalse(isa(F16PropL1(f16a_spec_path(1)), 'PropulsionModelL2'), ...
                'L1 must NOT inherit from the L2 enforcer.');
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16PropL1(f16a_spec_path(1)), 'handle'));
        end

    end

end

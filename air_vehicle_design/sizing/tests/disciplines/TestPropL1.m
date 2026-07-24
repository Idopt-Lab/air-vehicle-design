classdef TestPropL1 < matlab.unittest.TestCase
%TESTPROPL1  Unit tests for PropL1 toolbox and F16PropL1 student class.
%
%   Formula references:
%     thrust_lapse: α = σ^m,  σ = ρ/ρ_SL, m from engine-type table
%       J.R.R.A. Martins, AE481 course notes (metabook), Eq. 10.7 (turbojet, m=1.0) / Eq. 10.9 (turbofan, m=0.6)
%     TSFC: categorical lookup by engine type — cruise and loiter only.
%       Raymer 6th ed. Table 3.3; values in lbf_fuel/(hr·lbf_thrust):
%         low_bypass_turbofan_AB / low_bypass_turbofan: cruise=0.80, loiter=0.70 1/hr
%         high_bypass_turbofan:                         cruise=0.50, loiter=0.40 1/hr
%         turbojet / turbojet_AB:                       cruise=0.90, loiter=0.80 1/hr
%         turboprop:                                    cruise=0.90, loiter=0.80 1/hr
%       AB operation is NOT modelled — see L2/L3 for AB TSFC (Mattingly Eq. 3.55).
%
%   Pre-computed expected values:
%     SLS (alt=0, M=0): σ = 1.0 → α = 1.0
%
%     At 36 kft, M=0.87 (cruise constraint state):
%       ρ ≈ 0.000707 slug/ft³  [atmosisa → AircraftState]
%       σ = 0.000707 / 0.002377 = 0.2975
%       α = 0.2975^0.6 ≈ 0.484   (L1 does NOT match Brandt deck ≈0.34;
%       σ^m with m=0.6 is a rough turbofan approximation — Mattingly L2 is more accurate)
%
%   F-16A takeoff speed estimate (used in testThrustLapseAtTakeoff):
%     V_stall = sqrt(2·TOGW/(ρ_SL·S_ref·CLmax_TO))
%             = sqrt(2·31377/(0.002377·300·1.2785)) = 262.3 ft/s
%     V_TO = 1.2·V_stall = 314.8 ft/s  [Brandt, "Introduction to Aeronautics: A Design Perspective"]
%     M_TO = V_TO/a_SLS = 314.8/1116.45 = 0.282
%     Sources: TOGW=31377 lbf, S_ref=300 ft², CLmax_TO=1.2785 [Brandt F-16A.xls]
%              ρ_SL=0.002377 slug/ft³, a_SLS=1116.45 ft/s     [Mattingly App. B]

    properties (Constant)
        TOL_TIGHT = 1e-6    % formula-level; exact arithmetic
        TOL_ATM   = 1e-4    % ISA/conversion rounding at SLS conditions
    end

    % Brandt's six constraint-analysis (alt, Mach) conditions [Brandt
    % "Consts" sheet] -- same points fidelity_comparison.m evaluates
    % thrust_lapse/get_TSFC at for all three fidelity levels.
    properties (TestParameter)
        constraintName = {'cruise', 'combat_sub', 'dash', 'max_alt', 'combat_sup', 'ps'};
    end

    % ---------------------------------------------------------------------- %
    methods (Test)

        % --- Low-level primitive: sigma_lapse --------------------------------

        % Note (Casey): This is logical, but may be unnecessary.
        function testSigmaLapseAtOne(tc)
            % Purpose: verify the identity case — σ=1 at sea level returns α=1.
            % At ρ=ρ_SL: σ=ρ/ρ_SL=1 → α=1^m=1.0 for any m.
            % Source: Martins AE481 course notes (metabook), Eq. 10.9; ρ_SL=0.002377 slug/ft³ [Mattingly App. B]
            expected = 1.0;
            received = PropL1.sigma_lapse(0.002377, 0.6);
            fprintf('\n    sigma_lapse(ρ_SL, m=0.6): received = %.6f,  expected = %.6f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM);
        end

        % Note (Casey): This is logical, but may be unnecessary.
        function testSigmaLapseFormula(tc)
            % Purpose: verify σ^m produces correct output for m=0.6 (turbofan) and m=1.0 (turbojet).
            % At half sea-level density: σ=0.5 → α=0.5^m.
            % Source: Martins AE481 course notes (metabook), Eqs. 10.7 / 10.9; ρ_SL=0.002377 [Mattingly App. B]
            rho_half    = 0.5 * 0.002377;   % slug/ft³
            expected_tf = 0.5^0.6;           % turbofan (m=0.6)  [Martins Eq. 10.9]
            expected_tj = 0.5^1.0;           % turbojet (m=1.0)  [Martins Eq. 10.7]
            received_tf = PropL1.sigma_lapse(rho_half, 0.6);
            received_tj = PropL1.sigma_lapse(rho_half, 1.0);
            fprintf('\n    sigma_lapse(0.5·ρ_SL): turbofan(m=0.6)=%.6f, turbojet(m=1.0)=%.6f\n', ...
                received_tf, received_tj);
            tc.verifyEqual(received_tf, expected_tf, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(received_tj, expected_tj, 'AbsTol', tc.TOL_TIGHT);
        end

        % --- Low-level: TSFC table lookup ------------------------------------

        % Note (Casey): Tests if the table lookup works for each engine type.
        function testTSFCTableLowBypassAB(tc)
            % Purpose: verify Raymer cruise/loiter TSFC for low-bypass turbofan with AB.
            % This is the engine category for the F-16 (F100-PW-200).
            % AB capability does NOT affect Raymer cruise/loiter TSFC — same values as dry.
            % Source: Raymer 6th ed. Table 3.3 — low-bypass turbofan.
            expected_cruise = 0.80;   % 1/hr  [Raymer Table 3.3]
            expected_loiter = 0.70;   % 1/hr  [Raymer Table 3.3]
            tbl = PropL1.lookup_TSFC_table('low_bypass_turbofan_AB');
            fprintf('\n    TSFC low_bypass_turbofan_AB: cruise=%.2f 1/hr,  loiter=%.2f 1/hr\n', ...
                tbl.cruise, tbl.loiter);
            tc.verifyEqual(tbl.cruise, expected_cruise, 'AbsTol', tc.TOL_TIGHT, ...
                'Cruise TSFC should be 0.80 1/hr.');
            tc.verifyEqual(tbl.loiter, expected_loiter, 'AbsTol', tc.TOL_TIGHT, ...
                'Loiter TSFC should be 0.70 1/hr.');
        end

        function testTSFCTableLowBypassTurbofan(tc)
            % Purpose: verify cruise/loiter TSFC for low-bypass turbofan (dry, no AB).
            % Same Raymer table values as the _AB variant — AB does not affect cruise/loiter.
            % Source: Raymer 6th ed. Table 3.3 — low-bypass turbofan.
            expected_cruise = 0.80;   % 1/hr  [Raymer Table 3.3]
            expected_loiter = 0.70;   % 1/hr  [Raymer Table 3.3]
            tbl = PropL1.lookup_TSFC_table('low_bypass_turbofan');
            fprintf('\n    TSFC low_bypass_turbofan: cruise=%.2f 1/hr,  loiter=%.2f 1/hr\n', ...
                tbl.cruise, tbl.loiter);
            tc.verifyEqual(tbl.cruise, expected_cruise, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(tbl.loiter, expected_loiter, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCTableHighBypassTurbofan(tc)
            % Purpose: verify cruise/loiter TSFC for high-bypass turbofan (transport).
            % Source: Raymer 6th ed. Table 3.3 — high-bypass turbofan.
            expected_cruise = 0.50;   % 1/hr  [Raymer Table 3.3]
            expected_loiter = 0.40;   % 1/hr  [Raymer Table 3.3]
            tbl = PropL1.lookup_TSFC_table('high_bypass_turbofan');
            fprintf('\n    TSFC high_bypass_turbofan: cruise=%.2f 1/hr,  loiter=%.2f 1/hr\n', ...
                tbl.cruise, tbl.loiter);
            tc.verifyEqual(tbl.cruise, expected_cruise, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(tbl.loiter, expected_loiter, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCTableTurbojet(tc)
            % Purpose: verify cruise/loiter TSFC for turbojet (with or without AB).
            % Raymer Table 3.3 has no AB column — turbojet_AB maps to same values.
            % Source: Raymer 6th ed. Table 3.3 — turbojet.
            expected_cruise = 0.90;   % 1/hr  [Raymer Table 3.3]
            expected_loiter = 0.80;   % 1/hr  [Raymer Table 3.3]
            tbl_dry = PropL1.lookup_TSFC_table('turbojet');
            tbl_AB  = PropL1.lookup_TSFC_table('turbojet_AB');
            fprintf('\n    TSFC turbojet: cruise=%.2f 1/hr,  loiter=%.2f 1/hr\n', ...
                tbl_dry.cruise, tbl_dry.loiter);
            tc.verifyEqual(tbl_dry.cruise, expected_cruise, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(tbl_dry.loiter, expected_loiter, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(tbl_AB.cruise,  expected_cruise, 'AbsTol', tc.TOL_TIGHT, ...
                'turbojet_AB must share cruise TSFC with turbojet.');
            tc.verifyEqual(tbl_AB.loiter,  expected_loiter, 'AbsTol', tc.TOL_TIGHT, ...
                'turbojet_AB must share loiter TSFC with turbojet.');
        end

        function testTSFCTableTurboprop(tc)
            % Purpose: verify cruise/loiter TSFC for turboprop.
            % Source: Raymer 6th ed. Table 3.3 — turboprop.
            expected_cruise = 0.90;   % 1/hr  [Raymer Table 3.3]
            expected_loiter = 0.80;   % 1/hr  [Raymer Table 3.3]
            tbl = PropL1.lookup_TSFC_table('turboprop');
            fprintf('\n    TSFC turboprop: cruise=%.2f 1/hr,  loiter=%.2f 1/hr\n', ...
                tbl.cruise, tbl.loiter);
            tc.verifyEqual(tbl.cruise, expected_cruise, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(tbl.loiter, expected_loiter, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCTableUnknownThrows(tc)
            % Purpose: verify that an unrecognized engine type raises an error
            % rather than silently returning a wrong TSFC value.
            tc.verifyError(@() PropL1.lookup_TSFC_table('ramjet'), ...
                'PropL1:unknownEngineType');
        end

        % --- Low-level: lapse exponent lookup --------------------------------

        function testLapseExponentLowBPFTurbofanAB(tc)
            % Purpose: verify m=0.6 for low-bypass turbofan with AB (F-16 engine category).
            % Source: Martins AE481 course notes (metabook), Eq. 10.9
            expected = 0.6;
            received = PropL1.lookup_lapse_exponent('low_bypass_turbofan_AB');
            fprintf('\n    lapse exponent low_bypass_turbofan_AB: %.1f  (expected: %.1f)\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testLapseExponentTurbojet(tc)
            % Purpose: verify m=1.0 for turbojet (thrust scales linearly with density).
            % Source: Martins AE481 course notes (metabook), Eq. 10.7
            expected = 1.0;
            received = PropL1.lookup_lapse_exponent('turbojet_AB');
            fprintf('\n    lapse exponent turbojet_AB: %.1f  (expected: %.1f)\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testLapseExponentTurbojetGreaterThanTurbofan(tc)
            % Purpose: verify m_turbojet (1.0) > m_turbofan (0.6).
            % A turbojet drops thrust faster with altitude — higher exponent means
            % steeper lapse.  [Martins Eqs. 10.7 / 10.9]
            m_tj = PropL1.lookup_lapse_exponent('turbojet');
            m_tf = PropL1.lookup_lapse_exponent('low_bypass_turbofan_AB');
            fprintf('\n    turbojet m=%.1f  vs  turbofan m=%.1f\n', m_tj, m_tf);
            tc.verifyGreaterThan(m_tj, m_tf, ...
                'Turbojet must have higher lapse exponent than turbofan.');
        end

        function testLapseExponentUnknownThrows(tc)
            % Purpose: verify that an unrecognized engine type raises an error.
            tc.verifyError(@() PropL1.lookup_lapse_exponent('ramjet'), ...
                'PropL1:unknownEngineType');
        end

        % --- High-level: thrust lapse ----------------------------------------

        function testThrustLapseDecreasesWithAltitude(tc)
            % Purpose: verify monotonic decrease of α with altitude at constant Mach.
            % L1 model: α=σ^m; σ decreases with altitude → α must decrease.
            % At SLS M=0.5: σ=1 → α=1.0.  [Martins Eq. 10.9]
            % At 36 kft M=0.5: σ<1 → α<1.0.  [Martins Eq. 10.9; ISA from Mattingly App. B]
            expected_SL = 1.0;   % σ=1 at SLS regardless of Mach  [Raymer §5.4]
            g        = F16PropL1();
            alpha_SL = g.compute_thrust_lapse(AircraftState(0,     0.5));
            alpha_36 = g.compute_thrust_lapse(AircraftState(36000, 0.5));
            fprintf('\n    α: SL=%.4f (expected=%.4f),  36kft=%.4f\n', ...
                alpha_SL, expected_SL, alpha_36);
            tc.verifyEqual(alpha_SL, expected_SL, 'AbsTol', tc.TOL_ATM, ...
                'α at SLS must be exactly 1.0 (σ=1).');
            tc.verifyGreaterThan(alpha_SL, alpha_36, ...
                'Thrust lapse must decrease with altitude.');
        end

        function testThrustLapseAtTakeoff(tc)
            % Purpose: verify α=1 at the F-16 estimated takeoff Mach at SLS.
            % L1 is density-only (σ^m, no Mach term); at SLS σ=1 for any Mach → α=1.0.
            % L1 limitation: no AB/mil split (that's L2), no Mach correction.
            %   L2/L3 give α_AB=1.0, α_mil=0.6 at SLS.
            %   Brandt gives 0.955/0.940 at M_TO=0.282 (Mach-corrected, wet/dry split).
            %
            % Takeoff Mach derived from F-16A baseline data:
            %   V_stall = sqrt(2·TOGW/(ρ_SL·S_ref·CLmax_TO))
            %   V_TO    = 1.2·V_stall  [Brandt, "Introduction to Aeronautics: A Design Perspective"]
            %   M_TO    = V_TO/a_SLS ≈ 0.282
            % Sources:
            %   TOGW=31377 lbf, S_ref=300 ft², CLmax_TO=1.2785  [Brandt F-16A.xls]
            %   ρ_SL=0.002377 slug/ft³, a_SLS=1116.45 ft/s      [Mattingly App. B]
            b       = F16Baseline();
            g       = F16PropL1();
            V_stall = sqrt(2 * b.brandt.TOGW / ...
                          (b.atm.rho_std * b.geom.S_ref * b.brandt.CLmax_TO));
            V_TO    = 1.2 * V_stall;
            M_TO    = V_TO / b.atm.a_std;
            expected = 1.0;   % σ=1 at SLS → α=1 for any Mach  [Martins Eq. 10.9]
            received = g.compute_thrust_lapse(AircraftState(0, M_TO));
            fprintf('\n    M_TO=%.4f,  α_L1(SLS)=%.6f,  expected=%.6f\n', M_TO, received, expected);
            fprintf('    L1 limitation: no AB/mil split, no Mach correction.\n');
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'L1 thrust lapse at takeoff SLS must be 1.0 (σ=1 regardless of Mach).');
        end

        % TODO (7/14/2026): Include "dry" and "wet" split, too.
        function testThrustLapsePhysicalRange(tc)
            % Purpose: verify α at a realistic cruise state falls in a physically
            % plausible range for the σ^m law (m=0.6 for low-bypass turbofan).
            % At 36 kft M=0.87: σ≈0.297 → α=0.297^0.6≈0.487.  Bounds [0.2, 0.7]
            % conservatively bracket σ^0.6 for ISA altitudes between 25–50 kft.
            % Source: Martins AE481 course notes (metabook), Eq. 10.9; ISA density [Mattingly App. B]
            g        = F16PropL1();
            state    = AircraftState(36000, 0.87);
            received = g.compute_thrust_lapse(state);
            fprintf('\n    α at 36kft M=0.87: %.4f  [expected range: 0.20–0.70]\n', received);
            tc.verifyGreaterThan(received, 0.20, 'α below physical lower bound.');
            tc.verifyLessThan(received,   0.70, 'α above physical upper bound.');
        end

        % --- High-level: thrust lapse at all six Brandt constraint conditions -

        function testThrustLapseAtConstraintConditions(tc, constraintName)
            % Purpose: verify thrust_lapse follows the sigma^m formula
            % (PropL1.sigma_lapse, independently tested above) at every one
            % of Brandt's six constraint-analysis conditions -- L1's
            % density-only model has no Mach term, so alpha depends solely
            % on altitude. fidelity_comparison.m evaluates thrust_lapse at
            % all six; only 'cruise' had a (range-only) test before this.
            % Source: Martins AE481 course notes (metabook), Eq. 10.9.
            b        = F16Baseline();
            c        = b.constraints.(constraintName);
            g        = F16PropL1();
            state    = AircraftState(c.alt_ft, c.mach);
            m        = PropL1.lookup_lapse_exponent(g.engine_type);
            expected = PropL1.sigma_lapse(state.rho, m);
            received = g.thrust_lapse(state);
            fprintf('\n    %-11s alt=%6.0f M=%.2f: alpha received=%.4f  sigma^m formula=%.4f\n', ...
                constraintName, c.alt_ft, c.mach, received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT, ...
                'thrust_lapse must equal the sigma_lapse(rho,m) formula at every constraint condition.');
            tc.verifyGreaterThan(received, 0, 'alpha must be positive.');
            tc.verifyLessThanOrEqual(received, 1.0, 'alpha must not exceed 1.0 (SLS maximum).');
        end

        function testThrustLapseVsBrandtAtConstraintConditions(tc, constraintName)
            % Purpose: DIAGNOSTIC ONLY (not a closeness assertion, same
            % pattern as TestThrustConstraint.m's testF16*RequiredTWTable and
            % testF16CombatSupDragPolarK2ZeroSupersonic) -- prints
            % F16PropL1.thrust_lapse against Brandt's alpha_AB at all six
            % constraint conditions. Before this test, NOTHING in the suite
            % compared L1's alpha to Brandt at any condition (see
            % examples/F16A/cruise_and_combatturn2_error_scrape.md Sec 4 and
            % examples/F16A/remaining_constraints_scrape.md Sec 2-3), which let
            % a >2x error at Max Alt (50,000 ft) go completely unnoticed --
            % PropL1's sigma^m density-only law has no Mach term and, per
            % those docs' live findings, degrades badly at both extreme
            % altitude (Max Alt: alpha 90% too high) and supersonic Mach vs.
            % subsonic at the same altitude (identical alpha predicted for
            % Max Mach M=1.6 and Combat Turn 2 M=1.4, both at 36,000 ft, which
            % is not physically plausible for a real afterburning engine).
            % L1 is compared against alpha_AB (not alpha_mil_T_AB) at every
            % condition, including Cruise -- L1 has no mil/AB throttle
            % concept at all (unlike F16PropL2, see PropulsionBase.m's
            % thrust_lapse_mil_on_AB_scale default fallback), so alpha_AB is
            % the only basis it can be compared against.
            % No AbsTol assertion: at Max Alt/Cruise the gap exceeds 2x, so a
            % tolerance loose enough to pass there would be meaningless
            % everywhere else -- this deliberately mirrors how
            % ThrustConstraint's required_TW diagnostic tables assert only
            % finiteness/positivity, not closeness, for known-divergent
            % fidelity-model comparisons.
            b        = F16Baseline();
            c        = b.constraints.(constraintName);
            g        = F16PropL1();
            state    = AircraftState(c.alt_ft, c.mach);
            received = g.thrust_lapse(state);
            expected = c.alpha_AB;
            pct_diff = 100 * (received - expected) / expected;
            fprintf('\n    %-11s alt=%6.0f M=%.2f: L1 alpha=%.6f  Brandt alpha_AB=%.6f  diff=%+.1f%%\n', ...
                constraintName, c.alt_ft, c.mach, received, expected, pct_diff);
            tc.verifyGreaterThan(received, 0, 'alpha must be positive.');
            tc.verifyLessThanOrEqual(received, 1.0, 'alpha must not exceed 1.0 (SLS maximum).');
        end

        % --- Base-class delegation consistency --------------------------------

        function testThrustLapseMatchesCompute(tc)
            % Purpose: verify PropulsionBase.thrust_lapse delegates to
            % F16PropL1.compute_thrust_lapse without modification.
            g        = F16PropL1();
            state    = AircraftState(20000, 0.7);
            expected = g.compute_thrust_lapse(state);   % canonical L1 path
            received = g.thrust_lapse(state);            % base-class delegation
            fprintf('\n    thrust_lapse vs compute_thrust_lapse at 20kft M=0.7: %.6f\n', received);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT, ...
                'Base thrust_lapse must delegate to compute_thrust_lapse exactly.');
        end

        function testGetTSFCMatchesLookup(tc)
            % Purpose: verify PropulsionBase.get_TSFC delegates to
            % F16PropL1.lookup_TSFC without modification.
            g        = F16PropL1();
            state    = AircraftState(0, 0.5);
            expected = g.lookup_TSFC(state);   % canonical L1 path
            received = g.get_TSFC(state);       % base-class delegation
            fprintf('\n    get_TSFC vs lookup_TSFC at M=0.5: %.6f 1/hr\n', received);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT, ...
                'Base get_TSFC must delegate to lookup_TSFC exactly.');
        end

        % --- T_SL_wet matches baseline ----------------------------------------

        function testTSLMatchesBaseline(tc)
            % Purpose: verify T_SL_wet is set to the Brandt-reported AB SLS thrust.
            % Source: Brandt F-16A.xls sheet "Main" cell D29 — T_max=23,770 lbf.
            b        = F16Baseline();
            g        = F16PropL1();
            expected = b.engine.T_max;   % 23,770 lbf  [Brandt D29]
            received = g.T_SL_wet;
            fprintf('\n    T_SL_wet: received = %.0f lbf,  expected = %.0f lbf\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1.0, ...
                'T_SL_wet must match Brandt T_max (AB).');
        end

        function testTSLWetConsistentWithF100PW100(tc)
            % Purpose: cross-check T_SL_wet against the F100-PW-100 real-world
            % reported SLS thrust — the predecessor engine to the F100-PW-200.
            % The -200 variant (Brandt: 23,770 lbf) is 0.3% above the -100 reference.
            % RelTol=0.01 (±1%) accommodates both values.
            % Source: Mattingly AED 2nd ed., Table C.4, p. 522.
            b        = F16Baseline();
            g        = F16PropL1();
            expected = b.engine.F100PW100.T_max;   % 23,700 lbf  [Mattingly Table C.4]
            received = g.T_SL_wet;
            fprintf('\n    T_SL_wet: %.0f lbf  |  F100-PW-100 App.C anchor: %.0f lbf  (delta: %+.0f lbf)\n', ...
                received, expected, received - expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.01, ...
                'T_SL_wet must agree with F100-PW-100 Appendix C reference (23,700 lbf) within 1%.');
        end

        % --- Unknown engine type ---------------------------------------------

        function testUnknownEngineTypeThrows(tc)
            % Purpose: verify that an unrecognized engine_type raises an error
            % rather than silently returning an incorrect TSFC value.
            g = F16PropL1();
            g.engine_type = "ramjet";
            state = AircraftState(0, 0.5);
            tc.verifyError(@() g.lookup_TSFC(state), 'PropL1:unknownEngineType');
        end

        % --- Inheritance / interface compliance ------------------------------

        function testIsaPropulsionBase(tc)
            % Purpose: verify F16PropL1 satisfies the top-level PropulsionBase
            % abstract contract (required for orchestrator DI).
            tc.verifyTrue(isa(F16PropL1(), 'PropulsionBase'), ...
                'F16PropL1 must satisfy PropulsionBase contract.');
        end

        function testIsaPropulsionModelL1(tc)
            % Purpose: verify F16PropL1 inherits from the L1 fidelity enforcer.
            tc.verifyTrue(isa(F16PropL1(), 'PropulsionModelL1'));
        end

        function testNotIsaPropulsionModelL2(tc)
            % Purpose: verify L1 does NOT inherit from the L2 enforcer.
            % Fidelity levels must be independent inheritance chains from PropulsionBase.
            tc.verifyFalse(isa(F16PropL1(), 'PropulsionModelL2'), ...
                'L1 must NOT inherit from the L2 enforcer.');
        end

        function testIsHandleClass(tc)
            % Purpose: verify F16PropL1 is a handle class (required for
            % constructor dependency injection to pass by reference).
            tc.verifyTrue(isa(F16PropL1(), 'handle'));
        end

    end

end

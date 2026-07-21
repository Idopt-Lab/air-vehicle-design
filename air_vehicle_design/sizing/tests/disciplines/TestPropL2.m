classdef TestPropL2 < matlab.unittest.TestCase
%TESTPROPL2  Unit tests for PropL2 toolbox and F16PropL2 student class.
%
%   FORMULA REFERENCES:
%     Thrust lapse [Mattingly AED 2nd ed., Eq. 2.54] -- low-BPR mixed turbofan:
%       AB:  theta0 <= TR -> alpha_AB = delta_0
%            theta0 >  TR -> alpha_AB = delta_0*(1 - 3.5*(theta0-TR)/theta0)
%       Mil: theta0 <= TR -> alpha_mil = 0.6*delta_0
%            theta0 >  TR -> alpha_mil = 0.6*delta_0*(1 - 3.8*(theta0-TR)/theta0)
%     TSFC [Mattingly Eq. 3.12 + 3.55]:
%       TSFC = (C1 + C2*M)*sqrt(theta)
%
%   BRANDT ENGINE MODEL [Brandt F-16A.xls, "Engn(s)" sheet] -- different from Mattingly:
%     Dry: theta0<=TR: alpha_dry = delta_0*(1 - 0.3*M)
%          theta0> TR: alpha_dry = delta_0*(1 - 0.3*M - 1.7*(theta0-TR)/theta0)
%     AB:  theta0<=TR: alpha_AB  = delta_0*(1 - 0.1*M^0.5)
%          theta0> TR: alpha_AB  = delta_0*(1 - 0.1*M^0.5 - 2.2*(theta0-TR)/theta0)
%     Brandt alpha_dry normalised by T_SL_dry (15,000 lbf); alpha_AB by T_SL_AB (23,770 lbf).
%     Mattingly alpha_mil normalised by T_SL_AB.  Formulas and normalizations differ.
%
%   EXPECTED VALUES -- TWO TIERS:
%     Primitive tests: use TR_part12 = 1.07 (hardcoded) [Mattingly AAF Part 4 example]
%     Student-class tests: F16PropL2 computes TR = 1.0 (T_t4_SLS unknown, Eq. D.6 default)
%     Note: b.engine.TR = 1.00 (F-16 value); Part 12 primitive tests do NOT use b.engine.TR.
%
%   CONSTRAINT CONDITIONS [Brandt F-16A.xls, "Consts" sheet -- actual workbook rows]:
%     Cruise       : 36,000 ft, M=0.87, n=1,   no AB  [Consts row 24]
%     Combat turn 1: 20,000 ft, M=0.87, n=4.5, AB     [Consts row 26]
%     Dash/MxMach  : 36,000 ft, M=1.6,  n=1,   AB     [Consts row 23]
%     Max alt      : 50,000 ft, M=0.87, n=1,   no AB  [Consts row 25]
%     Combat turn 2: 36,000 ft, M=1.4,  n=1.4, AB,       Ps=0     [Consts row 27]
%     Ps           : 10,000 ft, M=0.87, n=1,   AB, Ps=500 ft/s  [Consts row 28]
%
%   KNOWN SYSTEMATIC DISCREPANCIES:
%     TSFC at SLS M=0: Mattingly 0.90 1/hr vs. Brandt 0.70 1/hr (Mattingly over-predicts).
%     Lapse below-TR:  Mattingly has NO Mach correction; Brandt adds (1 - C*M^e).
%       Example at cruise M=0.87: Mattingly alpha_AB=delta_0=0.367, Brandt=0.333 (-9.3%).
%     Above-TR lapse:  Mattingly and Brandt agree within ~5% (both have theta correction).

    properties (Constant)
         % Note: 30 percent is a huge margin.
        TOL_TIGHT = 0.30;
        TOL_ATM   = 0.30;
    end

    methods (Test)

        % ------------------------------------------------------------------ %
        % LOW-LEVEL: thrust_lapse_AB (Mattingly Eq. 2.54a)                   %
        % ------------------------------------------------------------------ %

        % Note (Casey): Trivial test case.
        function testLapseABAtSLS(tc)
            % theta0=1, delta0=1, TR=b.engine.TR: theta0<=TR -> alpha_AB=delta0=1.0.
            b        = F16Baseline();
            expected = 1.0;   % below-TR: alpha_AB = delta_0 = 1.0 at SLS  [Mattingly Eq. 2.54a]
            alpha    = PropL2.thrust_lapse_AB(1.0, 1.0, b.engine.TR);
            fprintf('\n    alpha_AB (SLS): received=%.6f  expected=%.6f\n', alpha, expected);
            tc.verifyEqual(alpha, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        % ------------------------------------------------------------------ %
        % LOW-LEVEL: Mattingly Part 12 worked examples                        %
        % ------------------------------------------------------------------ %

        function testLapseMilPrimitive30kft_M15(tc)
            % Verify Eq. 2.54b at 30 kft M=1.5 against Mattingly's published result.
            % theta=0.7940, delta=0.2975 [App. B]; theta0=1.1513, delta0=1.0920.
            % theta0=1.1513>TR=1.07 -> post-TR.
            % Note: TR=1.07 is the Mattingly AAF Part 12 vehicle TR, NOT the F-16's TR=1.00.
            b         = F16Baseline();
            TR_part12 = 1.07;   % Mattingly Part 12 AAF example TR [Mattingly Eq. D.6, Part 4]
            M         = 1.5;
            theta_0   = b.engine.val.part12_30k_theta * (1 + 0.2*M^2);
            delta_0   = b.engine.val.part12_30k_delta * (1 + 0.2*M^2)^3.5;
            expected  = 0.4792;   % [Mattingly AED 2nd ed., Part 12 worked example]
            received  = PropL2.thrust_lapse_mil(delta_0, theta_0, TR_part12);
            fprintf('\n    alpha_mil (30kft M=1.5 prim): received=%.6f  Mattingly Part 12=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-3, ...
                'Must match Mattingly AED Part 12 worked example (0.4792 +/- 0.001).');
        end

        function testLapseMilPrimitiveHotDay2kft(tc)
            % Verify Eq. 2.54b at 2,000 ft hot-day M=0 (non-ISA).
            % theta0=1.0796>TR=1.07 -> post-TR.
            % Note: TR=1.07 is the Mattingly AAF Part 12 vehicle TR, NOT the F-16's TR=1.00.
            b         = F16Baseline();
            TR_part12 = 1.07;   % Mattingly Part 12 AAF example TR [Mattingly Eq. D.6, Part 4]
            theta_0   = b.engine.val.part12_hot_theta0;
            delta_0   = b.engine.val.part12_hot_delta0;
            expected  = 0.5390;   % [Mattingly AED 2nd ed., Part 12 worked example]
            received  = PropL2.thrust_lapse_mil(delta_0, theta_0, TR_part12);
            fprintf('\n    alpha_mil (2kft hot day M=0): received=%.6f  Mattingly Part 12=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-3, ...
                'Must match Mattingly AED Part 12 worked example (0.5390 +/- 0.001).');
        end

        % ------------------------------------------------------------------ %
        % LOW-LEVEL: TSFC_mil (Mattingly Eq. 3.12 + 3.55a)                  %
        % ------------------------------------------------------------------ %

        function testTSFCMilAtSLS(tc)
            % M=0, theta=1: TSFC=(C1_mil+C2_mil*0)*sqrt(1)=C1_mil.
            b        = F16Baseline();
            expected = b.engine.C1_mil;   % 0.90 1/hr  [Mattingly Eq. 3.55a]
            received = PropL2.TSFC_mil(b.engine.C1_mil, b.engine.C2_mil, 0.0, 1.0);
            fprintf('\n    TSFC_mil (SLS M=0): received=%.4f  expected=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCMilIncreasesWithMach(tc)
            % TSFC=(C1+C2*M)*sqrt(theta): increases with M (C2>0).
            % Physics: higher Mach -> higher ram temperature -> higher fuel flow per thrust unit.
            b       = F16Baseline();
            c_t_low = PropL2.TSFC_mil(b.engine.C1_mil, b.engine.C2_mil, 0.5, 1.0);
            c_t_hi  = PropL2.TSFC_mil(b.engine.C1_mil, b.engine.C2_mil, 0.9, 1.0);
            fprintf('\n    TSFC_mil: M=0.5->%.4f  M=0.9->%.4f\n', c_t_low, c_t_hi);
            tc.verifyGreaterThan(c_t_hi, c_t_low, ...
                'TSFC_mil must increase with Mach at constant altitude.');
        end

        % ------------------------------------------------------------------ %
        % LOW-LEVEL: TSFC_AB (Mattingly Eq. 3.12 + 3.55b)                   %
        % ------------------------------------------------------------------ %

        function testTSFCABAtSLS(tc)
            % M=0, theta=1: TSFC=(C1_AB+C2_AB*0)*sqrt(1)=C1_AB.
            b        = F16Baseline();
            expected = b.engine.C1_AB;   % 1.60 1/hr  [Mattingly Eq. 3.55b]
            received = PropL2.TSFC_AB(b.engine.C1_AB, b.engine.C2_AB, 0.0, 1.0);
            fprintf('\n    TSFC_AB (SLS M=0): received=%.4f  expected=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCABGreaterThanMil(tc)
            % AB TSFC must exceed mil TSFC at any condition.
            % Physics: afterburner burns additional fuel, raising TSFC above mil-power level.
            b     = F16Baseline();
            theta = 0.75;  M = 0.87;
            c_t_mil = PropL2.TSFC_mil(b.engine.C1_mil, b.engine.C2_mil, M, theta);
            c_t_AB  = PropL2.TSFC_AB( b.engine.C1_AB,  b.engine.C2_AB,  M, theta);
            fprintf('\n    TSFC: mil=%.4f  AB=%.4f\n', c_t_mil, c_t_AB);
            tc.verifyGreaterThan(c_t_AB, c_t_mil, ...
                'AB TSFC must exceed mil TSFC at any condition.');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: cruise condition  36,000 ft, M=0.87                    %
        % [Brandt Consts row 24]                                              %
        % ------------------------------------------------------------------ %
        % Brandt engine model (Engn(s) sheet, TR=1.0):
        %   theta0=0.8669 <= TR=1.0 -> below-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*0.87^0.5) = 0.3669*0.9067 = 0.3326  [AT24]
        %   alpha_dry_Brandt = delta_0*(1-0.3*0.87)     = 0.3669*0.739  = 0.2711  [AS24]
        %
        % Mattingly Eq. 2.54 (PropL2, TR=1.0), below-TR, NO Mach correction:
        %   alpha_AB  = delta_0        = 0.3669  (+9.3% above Brandt -- no Mach correction)
        %   alpha_mil = 0.6*delta_0    = 0.2201  (Brandt alpha_dry in T_SL_AB units: 0.271*(15k/23.77k)=0.171)


        function testLapseABAtCruise(tc)
            % theta0~0.867 <= TR=1.0 -> below-TR -> alpha_AB = delta_0.
            % Mattingly has no Mach correction below TR; Brandt does (see header).
            % Asserts F16PropL2 matches Mattingly; Brandt value reported for reference.
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            expected = b.constraints.cruise.alpha_AB;   % below-TR: alpha_AB = delta_0 exactly
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (cruise 36kft M=0.87): received=%.4f  Brandt(AT24)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Cruise alpha_AB must equal delta_0 (below-TR, Mattingly Eq. 2.54a).');
        end

        function testLapseMilAtCruise(tc)
            % alpha_mil at cruise (36kft M=0.87).
            % Brandt alpha_dry on T_SL_AB basis (AU24) = 0.1711  [Brandt Consts col AU, row 24]
            % Mattingly (PropL2, below-TR): 0.6*delta_0 = 0.2201  (+29% above Brandt)
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            expected = b.constraints.cruise.alpha_mil_T_AB;   % 0.1711  [Brandt Consts AU24]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (cruise 36kft M=0.87): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Cruise alpha_mil must match Brandt AU24 on T_SL_AB basis.');
        end

        function testTSFCMilAtCruise(tc)
            % Cruise TSFC_mil: Raymer Table 3.3, low-BPR turbofan with AB, cruise (M>=0.4) = 0.80 1/hr.
            % [Raymer, Aircraft Design 6th ed., Table 3.3]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            expected = b.engine.TSFC_cruise_raymer;   % 0.80 1/hr  [Raymer Table 3.3]
            received = g.compute_TSFC_mil(state);
            fprintf('\n    TSFC_mil (cruise 36kft M=0.87): received=%.4f  Raymer Table 3.3=%.4f 1/hr\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Cruise TSFC_mil must match Raymer Table 3.3 categorical value (0.80 +/- 0.10).');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: 1st combat turn  20,000 ft, M=0.87, n=4.5             %
        % [Brandt Consts row 26]                                              %
        % ------------------------------------------------------------------ %
        % Brandt (TR=1.0): theta0=0.9933 <= TR -> below-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*0.87^0.5) = 0.7519*0.9067 = 0.6818  [AT26]
        %   alpha_dry_Brandt = delta_0*(1-0.3*0.87)     = 0.7519*0.739  = 0.5557  [AS26]
        % Mattingly (TR=1.0): theta0=0.9933 <= TR -> below-TR:
        %   alpha_AB  = delta_0     = 0.7519  (+9.3% above Brandt -- same Mach correction deficit)
        %   alpha_mil = 0.6*delta_0 = 0.4511

        function testLapseABAtCombatTurn(tc)
            % alpha_AB at 20,000 ft M=0.87: AT26 = 0.681777  [Brandt Consts col AT, row 26]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            expected = b.constraints.combat_sub.alpha_AB;   % 0.6818  [Brandt Consts AT26]
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (combat 20kft M=0.87): received=%.4f  Brandt=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Combat-turn alpha_AB must match Brandt AT26 (0.6818 +/- 0.10).');
        end

        function testLapseMilAtCombatTurn(tc)
            % alpha_mil at 20,000 ft M=0.87 (T_SL_AB basis): AU26 = 0.350649
            % alpha_mil_T_AB = AS26*(T_SL_dry/T_SL_AB) = 0.555662*(15000/23770)
            % [Brandt Consts col AU, row 26]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            expected = b.constraints.combat_sub.alpha_mil_T_AB;   % 0.3506  [Brandt Consts AU26]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (combat 20kft M=0.87): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Combat-turn alpha_mil must match Brandt AU26 on T_SL_AB basis (0.3506 +/- 0.10).');
        end

        function testTSFCMilAtCombatTurn(tc)
            % Combat-turn TSFC_mil: Raymer Table 3.3, low-BPR turbofan, cruise (M=0.87>=0.4) = 0.80 1/hr.
            % [Raymer, Aircraft Design 6th ed., Table 3.3]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            expected = b.engine.TSFC_cruise_raymer;   % 0.80 1/hr  [Raymer Table 3.3]
            received = g.compute_TSFC_mil(state);
            fprintf('\n    TSFC_mil (combat 20kft M=0.87): received=%.4f  Raymer Table 3.3=%.4f 1/hr\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Combat-turn TSFC_mil must match Raymer Table 3.3 categorical value (0.80 +/- 0.10).');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: Max Mach / dash  36,000 ft, M=1.6                      %
        % [Brandt Consts row 23; Brandt "MxMach"]                            %
        % ------------------------------------------------------------------ %
        % Brandt (TR=1.0): theta0=1.1384 > TR -> above-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*1.6^0.5-2.2*(0.1384)/1.1384) = 0.9521*0.6063 = 0.5774 [AT23]
        %   alpha_dry_Brandt = delta_0*(1-0.3*1.6   -1.7*(0.1384)/1.1384) = 0.9521*0.3136 = 0.2985 [AS23]
        % Mattingly (TR=1.0): theta0=1.1384 > TR -> above-TR:
        %   alpha_AB  = delta_0*(1-3.5*(0.1384)/1.1384) = 0.9521*(1-0.4252) = 0.9521*0.5748 = 0.5475
        %   alpha_mil = 0.6*delta_0*(1-3.8*(0.1384)/1.1384) = 0.5713*(1-0.4622) = 0.5713*0.5378 = 0.3073
        % Brandt alpha_AB vs Mattingly: 0.5774 vs 0.5475 (~5.5% difference, above-TR).
        % This is the closest condition between the two models.

        function testLapseABAtDash(tc)
            % alpha_AB at 36,000 ft M=1.6: AT23 = 0.576980  [Brandt Consts col AT, row 23]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            expected = b.constraints.dash.alpha_AB;   % 0.5770  [Brandt Consts AT23]
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (dash 36kft M=1.6): received=%.4f  Brandt=%.4f  diff=%.1f%%\n', ...
                received, expected, ...
                100*(expected - received)/expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Dash alpha_AB must match Brandt AT23 (0.5770 +/- 0.10).');
        end

        function testLapseMilAtDash(tc)
            % alpha_mil at 36,000 ft M=1.6 (T_SL_AB basis): AU23 = 0.188237
            % alpha_mil_T_AB = AS23*(T_SL_dry/T_SL_AB) = 0.298293*(15000/23770)
            % [Brandt Consts col AU, row 23]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            expected = b.constraints.dash.alpha_mil_T_AB;   % 0.1882  [Brandt Consts AU23]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (dash 36kft M=1.6): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Dash alpha_mil must match Brandt AU23 on T_SL_AB basis (0.1882 +/- 0.10).');
        end

        % testTSFCMilAtDash and testTSFCABAtDash removed: Raymer Table 3.3 does not provide
        % TSFC reference values for supersonic (M=1.6) or AB conditions.  No directly-tabulated
        % published TSFC exists at this condition — computed estimates are not acceptable
        % as unit test expected values per the anti-self-referential rule.

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: max altitude  50,000 ft, M=0.87                        %
        % [Brandt Consts row 25]                                              %
        % ------------------------------------------------------------------ %
        % Brandt (TR=1.0): theta0=0.8657 <= TR -> below-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*0.87^0.5) = 0.1878*0.9067 = 0.1703  [AT25]
        %   alpha_dry_Brandt = delta_0*(1-0.3*0.87)     = 0.1878*0.739  = 0.1388  [AS25]
        % Mattingly (TR=1.0): theta0=0.8657 <= TR -> below-TR (no Mach correction):
        %   alpha_AB  = delta_0     = 0.1878  (+10.3% above Brandt -- same Mach deficit as cruise)
        %   alpha_mil = 0.6*delta_0 = 0.1127  (+28.7% above Brandt in T_SL_AB units)

        function testLapseABAtMaxAlt(tc)
            % alpha_AB at 50,000 ft M=0.87: AT25 = 0.170290  [Brandt Consts col AT, row 25]
            % Below-TR: Mattingly gives delta_0 = 0.1878 (no Mach correction).
            % Brandt Mach-corrected value is 0.1703 (10.3% below Mattingly).
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            expected = b.constraints.max_alt.alpha_AB;   % 0.1703  [Brandt Consts AT25]
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (max alt 50kft M=0.87): received=%.4f  Brandt(AT25)=%.4f  diff=%.1f%%\n', ...
                received, expected, 100*(received-expected)/expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Max-alt alpha_AB must be within AbsTol of Brandt AT25 (0.1703).');
        end

        function testLapseMilAtMaxAlt(tc)
            % alpha_mil at 50,000 ft M=0.87 (T_SL_AB basis): AU25 = 0.087582  [Brandt Consts AU25]
            % alpha_mil_T_AB = AS25*(T_SL_dry/T_SL_AB) = 0.138789*(15000/23770).
            % Mattingly gives 0.6*delta_0 = 0.1127 (+28.7% above Brandt; largest Mattingly/Brandt
            % deviation in the constraint set -- both Mach correction and normalisation differ).
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            expected = b.constraints.max_alt.alpha_mil_T_AB;   % 0.0876  [Brandt Consts AU25]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (max alt 50kft M=0.87): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Max-alt alpha_mil must be within AbsTol of Brandt AU25 on T_SL_AB basis (0.0876).');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: 2nd combat turn (supersonic)                           %
        % [Brandt Consts row 27: 36,000 ft, M=1.4, n=1.4, 100% AB]         %
        % ------------------------------------------------------------------ %
        % Brandt (TR=1.0): theta0=1.048059 > TR -> above-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*1.4^0.5-2.2*(0.0481)/1.0481) = 0.7128*0.7808 = 0.5566 [AT27]
        %   alpha_dry_Brandt = delta_0*(1-0.3*1.4   -1.7*(0.0481)/1.0481) = 0.7128*0.5018 = 0.3579 [AS27]
        % Mattingly (TR=1.0): theta0=1.048059 > TR -> above-TR:
        %   alpha_AB  = delta_0*(1-3.5*(0.0481)/1.0481) = 0.7128*(1-0.1605) = 0.5985 (+7.5% vs Brandt)
        %   alpha_mil = 0.6*delta_0*(1-3.8*(0.0481)/1.0481) = 0.4277*(1-0.1742) = 0.3533

        function testLapseABAtCombatTurnSup(tc)
            % alpha_AB at 36,000 ft M=1.4: AT27 = 0.556558  [Brandt Consts col AT, row 27]
            % Above-TR: Mattingly gives ~0.5985 (+7.5% above Brandt AT27).
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            expected = b.constraints.combat_sup.alpha_AB;   % 0.5566  [Brandt Consts AT27]
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (sup combat 36kft M=1.4): received=%.4f  Brandt(AT27)=%.4f  diff=%.1f%%\n', ...
                received, expected, 100*(received-expected)/expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Sup combat-turn alpha_AB must match Brandt AT27 (0.5566 +/- 0.30).');
        end

        function testLapseMilAtCombatTurnSup(tc)
            % alpha_mil at 36,000 ft M=1.4 (T_SL_AB basis): 0.225828
            % alpha_mil_T_AB = AS27*(T_SL_dry/T_SL_AB) = 0.357862*(15000/23770)
            % [Brandt Consts col AS, row 27]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            expected = b.constraints.combat_sup.alpha_mil_T_AB;   % 0.2258  [AS27*(T_SL_dry/T_SL_AB)]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (sup combat 36kft M=1.4): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Sup combat-turn alpha_mil must match Brandt AS27 on T_SL_AB basis (0.2258 +/- 0.30).');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: Ps (specific excess power) condition                   %
        % [Brandt Consts row 28: 10,000 ft, M=0.87, n=1, 100% AB, Ps=500]  %
        % ------------------------------------------------------------------ %
        % Brandt (TR=1.0): theta0=1.072356 > TR -> above-TR:
        %   alpha_AB_Brandt  = delta_0*(1-0.1*0.87^0.5-2.2*(0.0724)/1.0724) = 1.1256*0.7583 = 0.8536 [AT28]
        %   alpha_dry_Brandt = delta_0*(1-0.3*0.87   -1.7*(0.0724)/1.0724) = 1.1256*0.6238 = 0.7022 [AS28]
        % Mattingly (TR=1.0): theta0=1.072356 > TR -> above-TR:
        %   alpha_AB  = delta_0*(1-3.5*(0.0724)/1.0724) = 1.1256*(1-0.2362) = 0.8599 (+0.7% vs Brandt)
        %   alpha_mil = 0.6*delta_0*(1-3.8*(0.0724)/1.0724) = 0.6754*(1-0.2562) = 0.5023

        function testLapseABAtPs(tc)
            % alpha_AB at 10,000 ft M=0.87: AT28 = 0.853550  [Brandt Consts col AT, row 28]
            % Above-TR (barely): Mattingly gives ~0.8599 (+0.7% — closest agreement in constraint set).
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            expected = b.constraints.ps.alpha_AB;   % 0.8536  [Brandt Consts AT28]
            received = g.compute_thrust_lapse_AB(state);
            fprintf('\n    alpha_AB (Ps 10kft M=0.87): received=%.4f  Brandt(AT28)=%.4f  diff=%.1f%%\n', ...
                received, expected, 100*(received-expected)/expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Ps alpha_AB must match Brandt AT28 (0.8536 +/- 0.30).');
        end

        function testLapseMilAtPs(tc)
            % alpha_mil at 10,000 ft M=0.87 (T_SL_AB basis): 0.443455
            % alpha_mil_T_AB = AS28*(T_SL_dry/T_SL_AB) = 0.702727*(15000/23770)
            % [Brandt Consts col AS, row 28]
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            expected = b.constraints.ps.alpha_mil_T_AB;   % 0.4435  [AS28*(T_SL_dry/T_SL_AB)]
            received = g.compute_thrust_lapse_mil(state);
            fprintf('\n    alpha_mil (Ps 10kft M=0.87): received=%.4f  Brandt(T_AB basis)=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM, ...
                'Ps alpha_mil must match Brandt AS28 on T_SL_AB basis (0.4435 +/- 0.30).');
        end%

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: ancillary student-class tests                           %
        % ------------------------------------------------------------------ %

        function testThrustLapseDecreasesWithAltitude(tc)
            % alpha_AB at SLS must exceed alpha_AB at 36,000 ft (same Mach).
            % Physics: reduced inlet pressure at altitude -> lower pressure ratio -> lower thrust.
            g        = F16PropL2();
            alpha_SL = g.thrust_lapse(AircraftState(0,     0.87));
            alpha_36 = g.thrust_lapse(AircraftState(36000, 0.87));
            fprintf('\n    alpha_AB: SL=%.4f  36kft=%.4f\n', alpha_SL, alpha_36);
            tc.verifyGreaterThan(alpha_SL, alpha_36, ...
                'AB lapse must decrease with altitude at constant Mach.');
        end

        function testThrustLapseABMatchesCompute(tc)
            % thrust_lapse (PropulsionBase API) == compute_thrust_lapse_AB.
            g        = F16PropL2();
            state    = AircraftState(20000, 0.7);
            expected = g.compute_thrust_lapse_AB(state);
            tc.verifyEqual(g.thrust_lapse(state), expected, ...
                'AbsTol', tc.TOL_TIGHT);
        end

        function testGetTSFCAtSLS(tc)
            % Purpose: verify the student-class get_TSFC (PropulsionBase API
            % that fidelity_comparison.m calls directly) at SLS, M~0 --
            % previously only the static TSFC_mil primitive was tested there
            % (see testTSFCMilAtSLS above).
            b        = F16Baseline();
            g        = F16PropL2();
            state    = AircraftState(0, 0.01);
            expected = b.engine.C1_mil;   % 0.90 1/hr @ M~0, theta=1  [Mattingly Eq. 3.55a]
            received = g.get_TSFC(state);
            fprintf('\n    get_TSFC (SLS M~0): received=%.4f  expected=%.4f 1/hr\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ATM);
        end

        function testGetTSFCMatchesComputeMil(tc)
            % get_TSFC (PropulsionBase API) == compute_TSFC_mil.
            g        = F16PropL2();
            state    = AircraftState(0, 0.5);
            expected = g.compute_TSFC_mil(state);
            tc.verifyEqual(g.get_TSFC(state), expected, ...
                'AbsTol', tc.TOL_TIGHT);
        end

        function testTSFCABGreaterThanMilOnStudentClass(tc)
            % AB TSFC must exceed mil TSFC at any condition (student class API).
            % Physics: afterburner burns additional fuel, raising TSFC above mil-power level.
            g     = F16PropL2();
            state = AircraftState(36000, 0.87);
            tc.verifyGreaterThan(g.compute_TSFC_AB(state), g.compute_TSFC_mil(state), ...
                'AB TSFC must exceed mil TSFC at cruise condition.');
        end

        % ------------------------------------------------------------------ %
        % HIGH-LEVEL: F100-PW-100 anchor  [Mattingly Table C.4]              %
        % ------------------------------------------------------------------ %

        function testTSLWetConsistentWithF100PW100(tc)
            % T_SL_wet must agree with F100-PW-100 Table C.4 within 1%.
            b        = F16Baseline();
            g        = F16PropL2();
            expected = b.engine.F100PW100.T_max;
            received = g.T_SL_wet;
            fprintf('\n    T_SL_wet: %.0f lbf  |  F100-PW-100 anchor: %.0f lbf  (delta: %+.0f lbf)\n', ...
                received, expected, received - expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.01, ...
                'T_SL_wet must agree with F100-PW-100 Table C.4 within 1%.');
        end

        % ------------------------------------------------------------------ %
        % ENGINE CONSTANTS                                                    %
        % ------------------------------------------------------------------ %

        function testTSLWetMatchesBaseline(tc)
            b        = F16Baseline();
            g        = F16PropL2();
            expected = b.engine.T_max;   % 23,770 lbf  [Brandt D29]
            tc.verifyEqual(g.T_SL_wet, expected, 'AbsTol', 1.0);
        end

        function testTSLMilMatchesBaseline(tc)
            b        = F16Baseline();
            g        = F16PropL2();
            expected = b.engine.T_mil;   % 15,000 lbf  [Brandt C29]
            tc.verifyEqual(g.T_SL_mil, expected, 'AbsTol', 1.0);
        end

        % Note (7/15/2026): Trivial.
        function testTRComputedFromEngineData(tc)
            % TR = 1.0: T_t4_SLS unknown from Mattingly Table C.4 -> default.
            g        = F16PropL2();
            expected = 1.0;   % [Mattingly Eq. D.6, default when T_t4_SLS is unknown -> TR=1.0]
            received = g.TR;
            fprintf('\n    TR (computed): received=%.4f  expected=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testMattinglyCoefficientsMatchBaseline(tc)
            b = F16Baseline();
            g = F16PropL2();
            tc.verifyEqual(g.C1_mil, b.engine.C1_mil, 'AbsTol', 1e-6, 'C1_mil mismatch.');
            tc.verifyEqual(g.C2_mil, b.engine.C2_mil, 'AbsTol', 1e-6, 'C2_mil mismatch.');
            tc.verifyEqual(g.C1_AB,  b.engine.C1_AB,  'AbsTol', 1e-6, 'C1_AB mismatch.');
            tc.verifyEqual(g.C2_AB,  b.engine.C2_AB,  'AbsTol', 1e-6, 'C2_AB mismatch.');
        end

        % ------------------------------------------------------------------ %
        % PARAMETRIC ENGINE SIZING (Raymer Eqs 10.10–10.15)                  %
        % F100-PW-200 afterburning turbofan (F-16A Block 10 engine):         %
        %   T   = 23,770 lbf  [Brandt F-16A.xls C29]                        %
        %   BPR = 0.69        [Mattingly AED 2nd ed., Table C.4, F100-PW-100]%
        %   M   = 2.0         [F-16A design (max) Mach; Brandt polar_model]  %
        %                                                                     %
        % Engine weight (Eq. 10.10): not tested — no published dry weight for %
        % F100-PW-200 was found in the extracted references (Brandt, Mattingly,%
        % TO 1F-16A-1).  Add when a published source is obtained.            %
        %                                                                     %
        % Engine diameter (Eq. 10.12): TO 1F-16A-1 gives compressor-face     %
        % diameter (34.8 in), which is the inlet, NOT the max AB-nozzle      %
        % diameter predicted by the equation.  Dimensions are not comparable. %
        % ------------------------------------------------------------------ %

        function testEngineLengthABvsTO(tc)
            % Eq. 10.11: engine_length_AB(T=23770 lbf, M=2.0).
            % Reference: T.O. 1F-16A-1, F100-PW-200 total engine length = 191.16 in.
            %   191.16 in / 12 = 15.930 ft  [usaf_f16_data.md, TO 1F-16A-1, §Engine]
            % Raymer Eq. 10.11 is first-order statistical; 10% RelTol is appropriate.
            b        = F16Baseline();
            expected = 191.16 / 12;   % 15.930 ft  [T.O. 1F-16A-1]
            received = PropL2.engine_length_AB(b.engine.T_max, 2.0);
            fprintf('\n    Engine length AB (23770 lbf, M=2.0): received=%.2f ft  TO=%.2f ft  diff=%.1f%%\n', ...
                received, expected, 100*(received - expected)/expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.10, ...
                'engine_length_AB(23770,2.0) must be within 10% of TO 1F-16A-1 F100-PW-200 length (15.93 ft).');
        end

        function testEngineSFCMaxABvsMattinglyAndBrandt(tc)
            % Eq. 10.13: SFC_max_AB(BPR=0.69) — max-throttle AB SFC at design condition.
            %
            % Reference 1 (primary):  Mattingly Table C.2, F100-PW-229 SLS max TSFC = 2.05 1/hr.
            %   F100-PW-229 is a higher-thrust F100 variant (BPR≈0.4); used as the closest
            %   published Mattingly value for the F100 family.  [mattingly_data.md, Table C.2]
            %
            % Reference 2 (secondary): Brandt D30, F100-PW-200 SLS AB TSFC = 2.20 1/hr.
            %   [F16Baseline b.engine.TSFC_max, from Brandt F-16A.xls sheet D30]
            %
            % Note: both references are SLS static; Raymer Eq. 10.13 targets the design
            % condition (T_SL=23770, BPR=0.69).  The 30% AbsTol covers this offset.
            b                  = F16Baseline();
            BPR                = b.engine.F100PW100.BPR;   % 0.69  [Mattingly Table C.4]
            expected_mattingly = 2.05;                      % 1/hr  [Mattingly Table C.2, F100-PW-229]
            expected_brandt    = b.engine.TSFC_max;         % 2.20 1/hr  [Brandt D30]
            received           = PropL2.SFC_max_AB(BPR);
            fprintf('\n    SFC_max_AB(BPR=0.69): received=%.3f  Mattingly(F100-PW-229)=%.2f  Brandt=%.2f 1/hr\n', ...
                received, expected_mattingly, expected_brandt);
            tc.verifyEqual(received, expected_mattingly, 'AbsTol', tc.TOL_TIGHT, ...
                'SFC_max_AB(0.69) must agree with Mattingly Table C.2 F100-PW-229 (2.05 +/- 0.30 1/hr).');
        end

        function testEngineSFCMaxABExceedsCruiseSFC(tc)
            % Eq. 10.13 qualitative: max-throttle AB SFC must greatly exceed cruise SFC.
            % Afterburner burns fuel at roughly 2–3x the cruise rate per unit thrust.
            % Cruise SFC reference: Raymer Table 3.3, low-BPR turbofan with AB = 0.80 1/hr.
            %   [Raymer, Aircraft Design 6th ed., Table 3.3]
            % Assert: SFC_max_AB >= 1.5 * SFC_cruise_raymer.
            b               = F16Baseline();
            BPR             = b.engine.F100PW100.BPR;
            SFC_max         = PropL2.SFC_max_AB(BPR);
            expected_cruise = b.engine.TSFC_cruise_raymer;   % 0.80 1/hr  [Raymer Table 3.3]
            fprintf('\n    SFC_max_AB(0.69)=%.3f vs Raymer Table 3.3 cruise=%.2f (ratio %.1fx)\n', ...
                SFC_max, expected_cruise, SFC_max/expected_cruise);
            tc.verifyGreaterThan(SFC_max, 1.5 * expected_cruise, ...
                'AB max-throttle SFC (Eq. 10.13) must exceed Raymer Table 3.3 cruise SFC by at least 1.5x.');
        end

        function testEngineSFCCruiseABvsRaymerTable33(tc)
            % Eq. 10.15: SFC_cruise_AB(BPR=0.69) at cruise reference (36,000 ft, M=0.9).
            % Reference: Raymer Table 3.3, low-BPR turbofan with AB, cruise = 0.80 1/hr.
            %   [Raymer, Aircraft Design 6th ed., Table 3.3]
            % Eq. 10.15 is calibrated to this cruise reference condition, so agreement
            % within 30% (TOL_TIGHT) is expected.
            b        = F16Baseline();
            BPR      = b.engine.F100PW100.BPR;
            expected = b.engine.TSFC_cruise_raymer;   % 0.80 1/hr  [Raymer Table 3.3]
            received = PropL2.SFC_cruise_AB(BPR);
            fprintf('\n    SFC_cruise_AB(BPR=0.69): received=%.3f  Raymer Table 3.3=%.2f 1/hr\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT, ...
                'SFC_cruise_AB(0.69) must agree with Raymer Table 3.3 low-BPR cruise SFC (0.80 +/- 0.30 1/hr).');
        end

        % ------------------------------------------------------------------ %
        % INHERITANCE / INTERFACE COMPLIANCE                                  %
        % ------------------------------------------------------------------ %

        function testIsaPropulsionBase(tc)
            tc.verifyTrue(isa(F16PropL2(), 'PropulsionBase'), ...
                'F16PropL2 must satisfy PropulsionBase contract.');
        end

        function testIsaPropulsionModelL2(tc)
            tc.verifyTrue(isa(F16PropL2(), 'PropulsionModelL2'));
        end

        function testNotIsaPropulsionModelL1(tc)
            tc.verifyFalse(isa(F16PropL2(), 'PropulsionModelL1'), ...
                'L2 must NOT inherit from the L1 enforcer.');
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16PropL2(), 'handle'));
        end

    end

end

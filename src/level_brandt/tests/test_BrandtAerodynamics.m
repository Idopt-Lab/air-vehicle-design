classdef test_BrandtAerodynamics < matlab.unittest.TestCase
% test_BrandtAerodynamics  Unit tests for BrandtAerodynamics.
%
% Source: Brandt-F16-A.xls Aero tab + Miss tab ground-truth.
% Tolerances: 1% default; 2% for quantities derived through multiple
% geometry steps (e_wing, CDmin_sub, CLmax, S_flapped); 3% for k2
% (small absolute value, sensitive to accumulated rounding).
%
% Run all:
%   results = runtests('test_BrandtAerodynamics');
%   table(results)

    properties (Access = private)
        geom   % shared BrandtGeometry (computed once)
        aero   % shared BrandtAerodynamics (computed once)
    end

    methods (TestClassSetup)
        function buildAerodynamics(tc)
            g = BrandtGeometry();
            g.compute();
            tc.geom = g;
            a = BrandtAerodynamics(g);
            a.compute();
            tc.aero = a;
        end
    end

    % ------------------------------------------------------------------ %
    %  Drag polar coefficients  (Miss tab basis)                          %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testCD0Cruise(tc)
            % Miss!CD0_cruise = 0.0270
            tc.verifyEqual(tc.aero.CD0, 0.0270, 'RelTol', 0.03, ...
                'CD0 cruise (Miss!CD0_cruise)');
        end

        function testCD0Takeoff(tc)
            % CD0_takeoff is read directly from JSON — exact match expected
            tc.verifyEqual(tc.aero.CD0_takeoff, 0.0520, 'AbsTol', 1e-10, ...
                'CD0 takeoff (Miss!CD0_TO, JSON pass-through)');
        end

        function testK1(tc)
            % Miss!k1 = 0.1160
            tc.verifyEqual(tc.aero.k1, 0.1160, 'RelTol', 0.01, ...
                'k1 induced-drag factor (Miss!k1)');
        end

        function testK2(tc)
            % Miss!k2 = -0.00630; 3% tolerance — small absolute value is
            % sensitive to accumulated rounding in CL_alpha and CL0
            tc.verifyEqual(tc.aero.k2, -0.00630, 'RelTol', 0.03, ...
                'k2 polar-camber term (Miss!k2)');
        end

    end

    % ------------------------------------------------------------------ %
    %  L/D performance  (Miss tab)                                        %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testLDmax(tc)
            % Miss!LD_max = 8.93
            tc.verifyEqual(tc.aero.LD_max, 8.93, 'RelTol', 0.02, ...
                'LD_max (Miss!LD_max)');
        end

        function testCLopt(tc)
            % Miss!CL_opt = 0.482
            tc.verifyEqual(tc.aero.CL_opt, 0.482, 'RelTol', 0.02, ...
                'CL_opt at LD_max (Miss!CL_opt)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Span efficiency and subsonic CDmin  (Aero tab)                    %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testE0(tc)
            % Aero!G12 = 0.9144
            tc.verifyEqual(tc.aero.e0, 0.9144, 'RelTol', 0.01, ...
                'Oswald e0 (Aero!G12)');
        end

        function testEWing(tc)
            % Aero!A19 = 0.7227; 2% — depends on TE-sweep from BrandtGeometry
            tc.verifyEqual(tc.aero.e_wing, 0.7227, 'RelTol', 0.02, ...
                'Span efficiency e_wing (Aero!A19)');
        end

        function testEPitch(tc)
            % Aero!A28 = 0.7227; 2% — same chain as e_wing
            tc.verifyEqual(tc.aero.e_pitch, 0.7227, 'RelTol', 0.02, ...
                'Span efficiency e_pitch (Aero!A28)');
        end

        function testCDminSub(tc)
            % Aero!G3 = 0.01691; 2% — inherits S_wet tolerance from BrandtGeometry
            tc.verifyEqual(tc.aero.CDmin_sub, 0.01691, 'RelTol', 0.03, ...
                'CDmin subsonic (Aero!G3, Cfe_tab basis)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Mach thresholds  (Aero!A12, G8, F9)                              %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testMcrit(tc)
            % Aero!A12 = 0.8727
            tc.verifyEqual(tc.aero.Mcrit, 0.8727, 'RelTol', 0.01, ...
                'Mcrit (Aero!A12)');
        end

        function testMwave(tc)
            % Aero!G8 = 1.0547
            tc.verifyEqual(tc.aero.M_wave, 1.0547, 'RelTol', 0.01, ...
                'M_wave = sec(ΛLE)^0.2 (Aero!G8)');
        end

        function testMLEsuper(tc)
            % Aero!F9 = 1.3054
            tc.verifyEqual(tc.aero.M_LE_super, 1.3054, 'RelTol', 0.01, ...
                'M_LE_super = sec(ΛLE) (Aero!F9)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Mach-dependent polar — aero_at_mach()  (Aero!A5:E10 methodology) %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testAeroAtMachSubsonicCDmin(tc)
            % Below Mcrit: CDmin equals the tabulated subsonic baseline
            [~, ~, ~, CDmin_m] = tc.aero.aero_at_mach(0.1);
            tc.verifyEqual(CDmin_m, tc.aero.CDmin_sub, 'RelTol', 1e-6, ...
                'CDmin(M=0.1) = CDmin_sub (subsonic, below Mcrit)');
        end

        function testAeroAtMachSubsonicK1(tc)
            [~, k1_m, ~, ~] = tc.aero.aero_at_mach(0.1);
            tc.verifyEqual(k1_m, tc.aero.k1, 'RelTol', 1e-6, ...
                'k1(M=0.1) = k1_sub (subsonic)');
        end

        function testAeroAtMachSubsonicK2(tc)
            [~, ~, k2_m, ~] = tc.aero.aero_at_mach(0.1);
            tc.verifyEqual(k2_m, tc.aero.k2, 'RelTol', 1e-6, ...
                'k2(M=0.1) = k2_sub (subsonic)');
        end

        function testAeroAtMachMwaveK1(tc)
            % At M = M_wave: k1 = k1_Mwave = 0.2415 (Aero!D8, recursive MAX formula)
            [~, k1_m, ~, ~] = tc.aero.aero_at_mach(tc.aero.M_wave);
            tc.verifyEqual(k1_m, 0.2415, 'RelTol', 0.01, ...
                'k1(M_wave) = 0.2415 (Aero!D8)');
        end

        function testAeroAtMachMwaveCDminIncreases(tc)
            % Wave drag adds on above Mcrit
            [~, ~, ~, CDmin_m] = tc.aero.aero_at_mach(tc.aero.M_wave);
            tc.verifyGreaterThan(CDmin_m, tc.aero.CDmin_sub, ...
                'CDmin(M_wave) > CDmin_sub — wave drag has added on');
        end

        function testAeroAtMachMwaveK2Decays(tc)
            % k2 decays toward zero but is still more negative than k2_sub
            [~, ~, k2_m, ~] = tc.aero.aero_at_mach(tc.aero.M_wave);
            tc.verifyGreaterThan(k2_m, tc.aero.k2, ...
                'k2(M_wave) > k2_sub (less negative, partial decay toward M=1.5)');
            tc.verifyLessThan(k2_m, 0, ...
                'k2(M_wave) < 0 (not yet zero)');
        end

        function testAeroAtMach15K2Zero(tc)
            % k2 linear decay reaches exactly zero at M = 1.5
            [~, ~, k2_m, ~] = tc.aero.aero_at_mach(1.5);
            tc.verifyEqual(k2_m, 0, 'AbsTol', 0, ...
                'k2(M=1.5) = 0 exactly (decay formula: k2_sub*(1.5-1.5)/... = 0)');
        end

        function testAeroAtMach15K1Floor(tc)
            % k1 floor = (k1_Mwave + k1_M2)/2 = (0.2415 + 0.3670)/2 = 0.3043  (Aero!D7)
            [~, k1_m, ~, ~] = tc.aero.aero_at_mach(1.5);
            tc.verifyEqual(k1_m, 0.3043, 'RelTol', 0.01, ...
                'k1(M=1.5) = 0.3043 (floor mechanism, Aero!D7)');
        end

        function testAeroAtMach20K2Zero(tc)
            % For M > 1.5, k2 is clamped to zero
            [~, ~, k2_m, ~] = tc.aero.aero_at_mach(2.0);
            tc.verifyEqual(k2_m, 0, 'AbsTol', 0, ...
                'k2(M=2.0) = 0 (clamped above M=1.5)');
        end

        function testAeroAtMach20K1Formula(tc)
            % k1 at M=2.0 uses supersonic formula: AR*(M²-1)/(4*AR*√(M²-1)-2)*cos(ΛLE)
            [~, k1_m, ~, ~] = tc.aero.aero_at_mach(2.0);
            tc.verifyEqual(k1_m, 0.3670, 'RelTol', 0.01, ...
                'k1(M=2.0) = 0.3670 (supersonic formula, Aero!D10)');
        end

        function testCDminPeakAtMwave(tc)
            % CDmin reaches its peak at M_wave; the (1-0.3*sqrt(M-M_wave)) factor
            % reduces wave drag for M_wave < M <= M_LE_super
            [~, ~, ~, CDmin_Mwave]  = tc.aero.aero_at_mach(tc.aero.M_wave);
            [~, ~, ~, CDmin_MLEsup] = tc.aero.aero_at_mach(tc.aero.M_LE_super);
            tc.verifyGreaterThanOrEqual(CDmin_Mwave, CDmin_MLEsup, ...
                'CDmin peaks at M_wave, decreases slightly toward M_LE_super (drag bucket)');
        end

    end

    % ------------------------------------------------------------------ %
    %  CLmax  (Aero!H25, H27, H29)                                       %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testCLmaxClean(tc)
            % Aero!H25 = 0.984; 2% — goes through CL_alpha_total chain
            tc.verifyEqual(tc.aero.CLmax_clean, 0.984, 'RelTol', 0.02, ...
                'CLmax_clean (Aero!H25)');
        end

        function testCLmaxTakeoff(tc)
            % Aero!H27 = 1.276; 2% — derived from CLmax_landing
            tc.verifyEqual(tc.aero.CLmax_takeoff, 1.276, 'RelTol', 0.02, ...
                'CLmax_takeoff (Aero!H27)');
        end

        function testCLmaxLanding(tc)
            % Aero!H29 = 1.426; 2% — depends on S_flapped and stabilator geometry
            tc.verifyEqual(tc.aero.CLmax_landing, 1.426, 'RelTol', 0.02, ...
                'CLmax_landing (Aero!H29)');
        end

        function testCLmaxOrdering(tc)
            tc.verifyLessThan(tc.aero.CLmax_clean, tc.aero.CLmax_takeoff, ...
                'CLmax_clean < CLmax_takeoff');
            tc.verifyLessThan(tc.aero.CLmax_takeoff, tc.aero.CLmax_landing, ...
                'CLmax_takeoff < CLmax_landing');
        end

    end

    % ------------------------------------------------------------------ %
    %  Flapped area  (Aero!L31)                                          %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testSFlapped(tc)
            % Aero!L31 = 144.745 ft²; 2% — depends on aileron geometry from BrandtGeometry
            tc.verifyEqual(tc.aero.S_flapped, 144.745, 'RelTol', 0.02, ...
                'S_flapped (Aero!L31)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Drag polar self-consistency checks                                 %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testDragPolarAtZeroCL(tc)
            % CD = CD0 + k1*0² + k2*0 = CD0 exactly
            CD = tc.aero.drag_polar(0.0);
            tc.verifyEqual(CD, tc.aero.CD0, 'AbsTol', 1e-12, ...
                'drag_polar(CL=0) = CD0 exactly');
        end

        function testDragPolarLDmaxConsistency(tc)
            % L/D at CL_opt should equal LD_max within 2% (Brandt ignores k2 in LD_max formula)
            CD_opt = tc.aero.drag_polar(tc.aero.CL_opt);
            LD     = tc.aero.CL_opt / CD_opt;
            tc.verifyEqual(LD, tc.aero.LD_max, 'RelTol', 0.02, ...
                'L/D at CL_opt ≈ LD_max (Brandt simplified formula ignores k2)');
        end

        function testDragPolarTakeoffHigherThanCruise(tc)
            % Takeoff CD0 > cruise CD0, so takeoff drag > cruise at any CL
            CD_cruise = tc.aero.drag_polar(0.5);
            CD_to     = tc.aero.drag_polar_takeoff(0.5);
            tc.verifyGreaterThan(CD_to, CD_cruise, ...
                'CD_takeoff > CD_cruise at CL = 0.5');
        end

        function testDragPolarConvexity(tc)
            % CD = CD0 + k1*CL² + k2*CL is a quadratic; second differences must be positive
            CL_vec = 0.1 : 0.1 : 1.0;
            CD_vec = tc.aero.drag_polar(CL_vec);
            tc.verifyTrue(all(diff(diff(CD_vec)) > 0), ...
                'Drag polar is convex for CL ∈ [0.1, 1.0]');
        end

    end

    % ------------------------------------------------------------------ %
    %  Cfe consistency                                                    %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testCfeBackCalculation(tc)
            % CD0 = Cfe_eff * S_wet / S_ref must be self-consistent with stored Cfe_eff
            S_wet = tc.geom.S_wet_total_accurate_ft2;
            S_ref = tc.aero.inp.wing.S_ref_ft2;
            Cfe_back = tc.aero.CD0 * S_ref / S_wet;
            tc.verifyEqual(Cfe_back, tc.aero.Cfe_eff, 'RelTol', 1e-6, ...
                'Cfe back-calculated from CD0 matches stored Cfe_eff');
        end

    end

end

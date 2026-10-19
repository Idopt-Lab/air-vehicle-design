classdef TestHelpers < matlab.unittest.TestCase
%TESTHELPERS  Check each lesson helper against its printed equation.
%
%   Run:  runtests('air_vehicle_design/sizing/teaching/aero-wing-design/tests')
%
%   Every expected value below was computed by hand (outside MATLAB) from
%   the printed equation and the inputs shown, NOT by calling the helper.
%   R = Raymer 6th ed. (2018); N = Nicolai & Carichner (2010);
%   USSA = U.S. Standard Atmosphere, 1976.
%
%   USSA at H = 10,668 m (35,000 ft), Eqs. 23, 33a, 42, 50, 51:
%     T = 288.15 - 0.0065*10668 = 218.808 K
%     P = 101325*(288.15/218.808)^(9.80665*28.9644/(8314.32*-0.0065)) = 23842.30 Pa
%     rho = P*28.9644/(8314.32*T) = 0.379597 kg/m^3; a = 296.5355 m/s
%     mu = 1.458e-6*T^1.5/(T + 110.4) = 1.433448e-5 Pa s
%   USSA at 12,192 m (40,000 ft), Eq. 33b: T = 216.65 K, P = 18753.93 Pa,
%     rho = 0.301558 kg/m^3
%   Sweep (Gudmundsson 2014, Eq. 9-11, p. 305), A = 9.44, lambda = 0.278, L_c/4 = 25:
%     L_LE = atan(tan 25 + (4/9.44)(0.25)(0.722/1.278)) = 27.75126 deg
%     L_0.3 = atan(tan 25 - (4/9.44)(0.05)(0.722/1.278)) = 24.43413 deg
%   Planform (R Eqs. 7.5-7.8), S = 124.6, d = 3.76:
%     b = 34.29612, c_r = 5.685546, c_t = 1.580582, MAC = 4.019577,
%     S_exp = 104.06842 m^2
%   Skin friction (N Eqs. 2.22, 2.25; R Eq. 12.28), k = 0.634e-5 m:
%     Re = 1e7, M = 0.5, l = 4 m: cut-off 4.893e7 (not active), Cf = 0.00293545
%     Re = 1e9, M = 0,   l = 1 m: cut-off 1.13652e7 (active),   Cf = 0.00294305
%   Form factors: R Eq. 12.30 (0.12, 0.3, 24.43 deg, M 0.785) = 1.575431;
%     R Eq. 12.31 (f = 10) = 1.083114; R Eq. 12.32 (f = 2.28) = 1.153509
%   Wetted area: R Eq. 7.12 (100 m^2, 0.12) = 203.94; R Eq. 7.11 (100, 0.04) = 200.3;
%     Roskam Eq. 12.3 (l = 39.12, D = 3.882989) = 415.8170 m^2
%   CL_alpha, R Eqs. 12.6-12.9: A 11.116, M 0.785, 24.43 deg, eta 0.9575,
%     S_exp/S 0.8353, d/b 0.1132: beta 0.619496, F 1.325959, product 1.107574
%     -> limited to 0.98, CLa = 6.144388 per rad
%   tau, delta at lambda 1, AR 10 (N Fig 2.10, combination rule):
%     tau = 0.163*0.224/0.166 = 0.219952; delta = 0.066*0.078/0.047 = 0.109532
%   Oswald, R Eqs. 12.48, 12.49 at A = 10: e48 = 0.756617; e49(40) = 0.375333;
%     at 15 deg: e48 + (e49(15) - e48)*15/30 = 0.627469
%   LE suction, R Eqs. 12.56, 12.57: A 10, CLa 5.5, S 0.9:
%     K = 0.9/(10 pi) + 0.1/5.5 = 0.0468297, e = 0.679718; with delta 0.05: K = 0.0482621
%   CLmax: R Eq. 12.15 (1.67, 25 deg) = 1.362181; R Eq. 12.16 with Fig 12.9:
%     dy 2.0 at 30 deg -> 0.89 -> 1.4863; dy 3.12 at 25 deg -> (0.84 + 0.79)/2 -> 1.361050
%   Wing weight, R Eq. 15.25 in lb and ft^2: W_dg 82644 kg = 182197.8 lb, Nz 3.75,
%     S_w 1341.18 ft^2, A 9.44, t/c 0.12, lambda 0.278, 25 deg, S_csw 402.35 ft^2
%     -> 14348.98 lb = 6508.589 kg
%   Wing volume, Roskam Eq. 6.2 (124.6, 34.30, 0.12, 0.12, 0.278) = 24.33804 m^3
%   Breguet, R Eq. 3.5: (232.8/(0.5/3600))*17*ln(1.2) = 5.195202e6 m

    properties (Constant)
        RT = 1e-6     % relative tolerance for closed-form equations
        RTfig = 1e-4  % for values through a digitized table (interpolation)
    end

    methods (TestClassSetup)
        function addHelpers(tc)
            here = fileparts(mfilename('fullpath'));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(here), 'student_package', 'helpers')));
        end
    end

    methods (Test)
        function testISA35kft(tc)
            a = isa_si(10668);
            tc.verifyEqual(a.T,   218.808,      'RelTol', tc.RT);
            tc.verifyEqual(a.P,   23842.297202, 'RelTol', tc.RT);
            tc.verifyEqual(a.rho, 0.379596939,  'RelTol', tc.RT);
            tc.verifyEqual(a.a,   296.5355156,  'RelTol', tc.RT);
            tc.verifyEqual(a.mu,  1.43344798e-5,'RelTol', tc.RT);
            tc.verifyEqual(a.nu,  a.mu/a.rho,   'RelTol', tc.RT);
        end

        function testISA40kftIsothermal(tc)
            a = isa_si(12192);
            tc.verifyEqual(a.T,   216.65,       'RelTol', tc.RT);
            tc.verifyEqual(a.P,   18753.925154, 'RelTol', tc.RT);
            tc.verifyEqual(a.rho, 0.3015582997, 'RelTol', tc.RT);
        end

        function testISARejectsAbove20km(tc)
            tc.verifyError(@() isa_si(21000), 'MATLAB:validators:mustBeLessThanOrEqual');
        end

        function testSweepConversion(tc)
            tc.verifyEqual(sweep_at(0,   25, 0.25, 9.44, 0.278), 27.7512609, 'RelTol', tc.RT);
            tc.verifyEqual(sweep_at(0.3, 25, 0.25, 9.44, 0.278), 24.4341258, 'RelTol', tc.RT);
            % Round trip: LE -> c/4 -> LE
            L4 = sweep_at(0.25, 40, 0, 3, 0.2275);
            tc.verifyEqual(sweep_at(0, L4, 0.25, 3, 0.2275), 40, 'AbsTol', 1e-10);
        end

        function testPlanform(tc)
            p = wing_planform(124.6, 9.44, 0.278, 25, 3.76, 0.30);
            tc.verifyEqual(p.b,      34.29612223, 'RelTol', tc.RT);
            tc.verifyEqual(p.c_root, 5.685545846, 'RelTol', tc.RT);
            tc.verifyEqual(p.c_tip,  1.580581745, 'RelTol', tc.RT);
            tc.verifyEqual(p.MAC,    4.019577108, 'RelTol', tc.RT);
            tc.verifyEqual(p.S_exp,  104.0684249, 'RelTol', tc.RT);
            % Trapezoid area from the chords returns S
            tc.verifyEqual((p.c_root + p.c_tip)/2*p.b, 124.6, 'RelTol', 1e-12);
        end

        function testSkinFriction(tc)
            tc.verifyEqual(skin_friction(1e7, 0.5, 4, 0.634e-5), 0.0029354495, 'RelTol', tc.RT);
            tc.verifyEqual(skin_friction(1e9, 0,   1, 0.634e-5), 0.0029430487, 'RelTol', tc.RT);
        end

        function testFormFactors(tc)
            tc.verifyEqual(form_factor("surface", 0.12, 0.3, 24.43, 0.785), 1.5754314131, 'RelTol', tc.RT);
            tc.verifyEqual(form_factor("body", 10),     1.0831138830, 'RelTol', tc.RT);
            tc.verifyEqual(form_factor("nacelle", 2.28), 1.1535087719, 'RelTol', tc.RT);
        end

        function testWettedAreas(tc)
            tc.verifyEqual(wetted_area("surface", 100, 0.12), 203.94, 'RelTol', tc.RT);
            tc.verifyEqual(wetted_area("surface", 100, 0.04), 200.3,  'RelTol', tc.RT);
            tc.verifyEqual(wetted_area("fuselage", 39.12, 3.8829885398), 415.8170310, 'RelTol', tc.RT);
            tc.verifyEqual(wetted_area("cylinder", 4.70, 2.06), pi*2.06*4.70, 'RelTol', 1e-12);
        end

        function testCLalphaRaymerWithCap(tc)
            [CLa, info] = cl_alpha_raymer(11.116, 0.785, 24.43, 0.9575, 0.8353, 0.1132);
            tc.verifyEqual(info.F,  1.3259592368, 'RelTol', tc.RT);
            tc.verifyEqual(info.SF, 1.1075737505, 'RelTol', tc.RT);
            tc.verifyEqual(info.SF_used, 0.98);
            tc.verifyEqual(CLa, 6.1443879627, 'RelTol', tc.RT);
        end

        function testTauDeltaCombinationRule(tc)
            [t6, d6] = tau_delta_nicolai(0.35, 6);      % top panel, unchanged at AR 6
            tc.verifyEqual([t6 d6], [0.006 0.006], 'AbsTol', 1e-12);
            [t, d] = tau_delta_nicolai(1, 10);
            tc.verifyEqual(t, 0.2199518072, 'RelTol', tc.RTfig);
            tc.verifyEqual(d, 0.1095319149, 'RelTol', tc.RTfig);
        end

        function testOswaldRaymer(tc)
            [e, e48] = oswald_raymer(10, 0);
            tc.verifyEqual([e e48], [0.7566172960 0.7566172960], 'RelTol', tc.RT);
            tc.verifyEqual(oswald_raymer(10, 40), 0.3753330800, 'RelTol', tc.RT);
            tc.verifyEqual(oswald_raymer(10, 15), 0.6274691586, 'RelTol', tc.RT);
            tc.verifyEqual(oswald_raymer(10, -15), oswald_raymer(10, 15));   % abs() for forward sweep
        end

        function testOswaldKroo(tc)
            % Nita & Scholz (2012) Eqs. 6-8: A = 10, CD0 = 0.02, d/b = 0.1
            %   s = 1 - 2*0.01 = 0.98; 1/(u s) = 1/(0.99*0.98) = 1.0307153
            %   K CD0 pi A = 0.38*0.02*pi*10 = 0.2387610
            %   e = 1/(1.0307153 + 0.2387610) = 0.7877264
            [e, s] = oswald_kroo(10, 0.02, 0.1);
            tc.verifyEqual(s, 0.98, 'RelTol', tc.RT);
            tc.verifyEqual(e, 0.7877264, 'RelTol', 1e-6);
        end

        function testLESuction(tc)
            [K, e] = k_le_suction(10, 5.5, 0.9);
            tc.verifyEqual(K, 0.0468297079, 'RelTol', tc.RT);
            tc.verifyEqual(e, 0.6797178547, 'RelTol', tc.RT);
            tc.verifyEqual(k_le_suction(10, 5.5, 0.9, 0.05), 0.0482621024, 'RelTol', tc.RT);
        end

        function testCLmax(tc)
            tc.verifyEqual(clmax_wing("raymer12_15", 1.67, 25), 1.3621806039, 'RelTol', tc.RT);
            tc.verifyEqual(clmax_wing("raymer12_16", 1.67, 2.0, 30), 1.4863, 'RelTol', tc.RTfig);
            tc.verifyEqual(clmax_wing("raymer12_16", 1.67, 3.12, 25), 1.36105, 'RelTol', tc.RTfig);
        end

        function testWingWeightRaymer1525(tc)
            m = wing_weight_raymer(82644, 3.75, 124.6, 9.44, 0.12, 0.278, 25, 0.3*124.6);
            tc.verifyEqual(m, 6508.5886315, 'RelTol', tc.RT);
        end

        function testWingFuelVolume(tc)
            tc.verifyEqual(wing_fuel_volume(124.6, 34.30, 0.12, 0.12, 0.278), 24.338038516, 'RelTol', tc.RT);
        end

        function testBreguet(tc)
            tc.verifyEqual(breguet_range(232.8, 0.5/3600, 17, 1.2, 1.0), 5.1952017108e6, 'RelTol', tc.RT);
        end

        function testClassifyTrend(tc)
            tc.verifyEqual(classify_trend([1 1.01 1.02], 1), "0");
            tc.verifyEqual(classify_trend([1 2 3], 2), "^");
            tc.verifyEqual(classify_trend([3 2 1], 2), "v");
            tc.verifyEqual(classify_trend([3 1 3], 1), "v^");
            tc.verifyEqual(classify_trend([1 3 1], 3), "^v");
            tc.verifyEqual(classify_trend([1 NaN 2], 1), "-");
        end

        function testBaselineIsConsistent(tc)
            ac = b737_baseline();
            % JSR gives S 124.60 m^2, span 34.30 m and AR 9.44 -- check they agree
            tc.verifyEqual(sqrt(ac.AR*ac.S), 34.30, 'RelTol', 1e-3);
            % The trapezoid MAC is within 2 % of the EASA TCDS value 3.96 m
            p = wing_planform(ac.S, ac.AR, ac.lambda, ac.sweep_c4);
            tc.verifyEqual(p.MAC, ac.MAC_tcds, 'RelTol', 0.02);
        end
    end
end

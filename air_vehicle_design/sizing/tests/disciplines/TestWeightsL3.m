classdef TestWeightsL3 < matlab.unittest.TestCase
%TESTWEIGHTSL3  Unit tests for the Level-3 weight estimation toolbox.
%
%   Tests: WeightsL3 (static toolbox) + F16WeightsL3 (student class).
%
%   METHOD: Raymer 7th ed. Sec. 15.3.1 Fighter/Attack statistical component
%   buildup, Eqs. 15.1-15.24, plus the dry engine weight from Raymer Eq. 10.10
%   (NOT a Sec. 15.3.1 equation -- Sec. 15.3.1 supplies the installation
%   hardware on top of a vendor dry weight).
%
%   CONSTRUCTOR (Phase 4, 2026-07-25):
%     F16WeightsL3(json_path, req_path, geom, prop) -- all four REQUIRED.
%       json_path = f16a_spec_path(3)   req_path = f16a_requirements_path()
%       geom      = (1,1) GeometryModelL3, i.e. F16GeomL3 -- NOT F16GeomL2
%       prop      = (1,1) PropulsionBase; at the L3 rung this is an F16PropL2,
%                   because there is no L3 propulsion tier.
%   weight_landing_gear(W_TO) also CHANGED: it now takes W_TO (see Sec. P4-17
%   below); it previously took no argument at all.
%
%   ======================================================================== %
%   ! THE OEW-vs-BRANDT AGREEMENT CHECK IS NOT IN THIS FILE ANY MORE.
%
%   Removed in Phase 4 (LOCKED; F16WeightsL3.md Sec. F, docs/
%   weights_parameter_usage.md Sec. E.4, review finding #14):
%       testOEWWithinBroadBounds  (expected = 19148, +-40 %, cited "Brandt B12")
%       testOEWPrintBreakdown     (verifyTrue(true) diagnostic, hardcoded 19148)
%   Brandt Wt!B12 is 19980.700578 (live-read 2026-07-25); 19,148.08 is
%   corrections.xls Wt!B12 (Casey's revised-weight workbook, F16Baseline.m:136).
%   A +-40 % tolerance on a mis-cited target is not a unit test, and per
%   CLAUDE.md's two-tier rule an agreement check is not one either. Both figures
%   and the whole per-group breakdown now live in
%   examples/F16A/weights_brandt_comparison.m. The old header block also
%   mis-cited the cell; corrected here.
%
%   NOTHING IN THIS FILE MAY TAKE AN EXPECTED VALUE FROM
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json OR FROM THE COMPARISON
%   REPORT. Every expected value is a structural invariant, an internal
%   identity, or hand arithmetic recorded in the derivation block below.
%   ======================================================================== %
%
%   ! STANDING TO-DO, NOT CLEARED: EVERY Sec. 15.3.1 EXPONENT IS UNVERIFIED
%   AGAINST THE BOOK (2 code-vs-extract CONFLICTS, 9 FROM-CODE, 24 [verify],
%   27 IMAGE-ONLY -- the 62-row checklist is VnV/BrandtF16A/todo.md 2026-07-24
%   Sec. 3a). Locked decision (user 2026-07-24, "approach 2"): keep every code
%   value, re-cite consistently, do NOT declare them book-verified. The
%   hand-computed tests below therefore verify that the code EVALUATES the
%   equation it documents -- they do NOT and cannot verify that the documented
%   exponents are the book's. That gap is guarded by the deliberately-failing
%   testTODO_Raymer1531ExponentsNotBookVerified at the end of this file.
%
%   ======================================================================== %
%   HAND-COMPUTED EXPECTED VALUES -- decimal arithmetic done in this comment
%   block from the f16a_L3.json inputs and the geometry/propulsion values the
%   DI supplies. NOT by calling the code under test, NOT from a ground-truth
%   file, NOT from the comparison report.
%
%   INPUTS USED (W_TO = W_dg = 31377 lbf, N_z = 13.5, N_en = 1):
%     geometry by DI (F16GeomL3, independently verified in TestGeomL3):
%       S_w = 196.226069, AR_w = 3.0, tc_root = 0.04, lambda_w = 0.2275,
%       Lambda_LE_w = 40 deg, S_csw = 68.03, S_ht = 51.148643 (EXPOSED),
%       F_w = 7.0, B_h = 18.5, S_vt = 40.889669 (EXPOSED), AR_vt = 1.294,
%       lambda_vt = 0.437, Lambda_LE_vt = 47.5 deg, H_t = 0, H_v = 1,
%       L_t = 22.0, S_r = 11.65, L_fus = 47.5, D_fus = 5.0 (structural
%       DEPTH), W_fus = 7.0, S_cs = 190
%     propulsion by DI: T_max = 23770, BPR = 0.71
%     requirements: design_mach = 2.0, cruise 36000 ft / M 0.87
%     .weights: N_l = 2.67, L_m = 5.5 ft, L_n = 3.5 ft, N_nw = 1, S_fw = 0,
%       D_e = 3.33, L_tp = 4.5, L_sh = 8.0, L_ec = 5.0, L_d = 7.5, L_s = 3.0,
%       K_vg = K_d = K_dw = K_vs = K_dwf = K_vsh = K_cb = K_tpg = K_mc = 1.0,
%       K_rht = 1.047, V_t = 940, V_i = 500, V_p = 0, N_t = 3, N_s = 4,
%       N_c = 1, N_ci = 3, N_u = 5, R_kva = 80, L_a = 10.0, N_gen = 1,
%       W_uav = 1500
%
%   SHARED INTERMEDIATES (used repeatedly below):
%     ln(31377)  = 10.35383042      (see TestWeightsL1's header derivation)
%     W_dg*N_z   = 31377*13.5 = 423589.5 ; /1000 = 423.5895
%     ln(423589.5) = ln(4.235895)+ln(1e5) = 1.44359460 + 11.51292546
%                  = 12.95652006
%     ln(423.5895) = 12.95652006 - 6.90775528 = 6.04876478
%     ln(23770)  = 10.07617962      (see TestWeightsL2's header derivation)
%     cos(40 deg)   = 0.76604444 ; 1/cos = 1.30540729
%     cos(47.5 deg) = 0.67559021 ; ln = -0.39216860
%     W_l = 0.95*31377 = 29808.15 ; W_l*N_l = 29808.15*2.67 = 79617.7605
%     L_m(in) = 5.5*12 = 66 ; L_n(in) = 3.5*12 = 42
%     66^0.973 = exp(0.973*4.18965474) = exp(4.07657406)
%              = exp(4)*exp(0.07653400) = 54.59815003*1.07953880 = 58.93882
%     42^0.5   = 6.48074070
%
%   Eq. 15.1  WING = 0.0103*K_dw*K_vs*(W_dg*N_z)^0.5*S_w^0.622*AR^0.785
%                    *tc_root^-0.4*(1+lambda)^0.05*cos(Lambda_LE)^-1*S_csw^0.04
%     (423589.5)^0.5      = 650.8375
%     196.226069^0.622    = exp(0.622*5.27926750) = exp(3.28370438) = 26.67644
%     3.0^0.785           = exp(0.785*1.09861229) = exp(0.86241065) =  2.368864
%     0.04^-0.4           = exp(-0.4*-3.21887582) = exp(1.28755033) = 3.6238987
%     1.2275^0.05         = exp(0.05*0.20497940) = exp(0.01024897) = 1.0103017
%     68.03^0.04          = exp(0.04*4.21994860) = exp(0.16879794) = 1.1838808
%     0.0103*650.8375 = 6.7036263 ; *26.67644 = 178.82883 ; *2.368864 = 423.62056
%       *3.6238987 = 1535.158 ; *1.0103017 = 1550.974 ; *1.30540729 = 2024.65
%       *1.1838808 = 2396.944 lbf
%
%   Eq. 15.2  HT = 3.316*(1+F_w/B_h)^-2*((W_dg*N_z)/1000)^0.260*S_ht^0.806
%     1+7.0/18.5 = 1.37837838 ; ^-2 = 1/1.90012670 = 0.5262804
%     423.5895^0.260 = exp(0.260*6.04876478) = exp(1.57267884) = 4.819543
%     51.148643^0.806 = exp(0.806*3.93473590) = exp(3.17139714) = 23.839762
%     3.316*0.5262804 = 1.745146 ; *4.819543 = 8.410806 ; *23.839762
%       = 200.5104 lbf
%
%   Eq. 15.3  VT = 0.452*K_rht*(1+H_t/H_v)^0.5*(W_dg*N_z)^0.488*S_vt^0.718
%                  *M^0.341*L_t^-1*(1+S_r/S_vt)^0.348*AR_vt^0.223
%                  *(1+lambda_vt)^0.25*cos(Lambda_LE_vt)^-0.323
%     (1+0/1)^0.5 = 1
%     423589.5^0.488 = exp(0.488*12.95652006) = exp(6.32278179) = 557.1207
%     40.889669^0.718 = exp(0.718*3.71087710) = exp(2.66440975) = 14.359424
%     2.0^0.341 = exp(0.341*0.69314718) = exp(0.23636319) = 1.2666339
%     1/22 = 0.04545455
%     1+11.65/40.889669 = 1.28491280 ; ^0.348 = exp(0.348*0.25069090)
%       = exp(0.08724043) = 1.0911589
%     1.294^0.223 = exp(0.223*0.25773820) = exp(0.05747562) = 1.0591594
%     1.437^0.25  = exp(0.25*0.36255750) = exp(0.09063938) = 1.0948741
%     cos(47.5)^-0.323 = exp(-0.323*-0.39216860) = exp(0.12667046) = 1.135043
%     0.452*1.047 = 0.473244 ; *557.1207 = 263.66403 ; *14.359424 = 3786.0659
%       *1.2666339 = 4795.305 ; *0.04545455 = 217.9684 ; *1.0911589 = 237.8382
%       *1.0591594 = 251.9085 ; *1.0948741 = 275.8083 ; *1.135043 = 313.0505 lbf
%
%   Eq. 15.4  FUSELAGE = 0.499*K_dwf*W_dg^0.35*N_z^0.25*L_fus^0.5
%                        *D_fus^0.849*W_fus^0.685
%     31377^0.35 = exp(0.35*10.35383042) = exp(3.62384065) = 37.4811
%     13.5^0.25  = exp(0.25*2.60268969) = exp(0.65067242) = 1.9168291
%     47.5^0.5   = 6.89202438
%     5.0^0.849  = exp(0.849*1.60943791) = exp(1.36641279) = 3.9212563
%     7.0^0.685  = exp(0.685*1.94591015) = exp(1.33294845) = 3.7922075
%     0.499*37.4811 = 18.7031 ; *1.9168291 = 35.85063 ; *6.89202438 = 247.0834
%       *3.9212563 = 968.876 ; *3.7922075 = 3674.18 lbf
%     (! D_fus = 5.0, the structural DEPTH. Substituting geom.D_fus = 6.0, the
%      Roskam equivalent DIAMETER, would inflate this by (6/5)^0.849 = +17.9 %
%      with no error -- name trap 3, tested below.)
%
%   Eq. 15.5  MAIN GEAR = K_cb*K_tpg*(W_l*N_l)^0.25*L_m^0.973
%     ln(79617.7605) = ln(7.96177605)+ln(1e4) = 2.07465210 + 9.21034037
%                    = 11.28499247
%     ^0.25 = exp(2.82124812) = 16.797883
%     16.797883*58.93882 = 989.843 lbf
%
%   Eq. 15.6  NOSE GEAR = (W_l*N_l)^0.290*L_n^0.5*N_nw^0.525
%     ^0.290 = exp(0.290*11.28499247) = exp(3.27264782) = 26.371119
%     26.371119*6.48074070*1 = 170.9044 lbf
%     -> LG TOTAL at W_TO = 31377: 989.843 + 170.9044 = 1160.747 lbf
%
%   Eqs. 15.5/15.6 AT OTHER GROSS WEIGHTS (the Sec. P4-17 guard):
%     W_TO = 45000: W_l = 42750 ; W_l*N_l = 114142.5 ;
%       ln = 0.13227750 + 11.51292546 = 11.64520296
%       main = exp(2.91130074)*58.93882 = 18.380691*58.93882 = 1083.336
%       nose = exp(3.37710886)*6.48074070 = 29.286028*6.4807407 = 189.795
%       TOTAL = 1273.131 lbf
%     W_TO = 60000: W_l = 57000 ; W_l*N_l = 152190 ;
%       ln = 0.41995957 + 11.51292546 = 11.93288503
%       main = exp(2.98322126)*58.93882 = 19.751338*58.93882 = 1164.121
%       nose = exp(3.46053666)*6.48074070 = 31.833878*6.4807407 = 206.307
%       TOTAL = 1370.428 lbf
%
%   Eq. 10.10 ENGINE (dry, UNINSTALLED -- no x1.3 at L3):
%     0.0637*23770^1.1*2.0^0.25*exp(-0.81*0.71) = 2775.0065 lbf
%     (full derivation in TestWeightsL2's header, row (7))
%
%   Eq. 15.7  MOUNTS = 0.013*N_en^0.795*T^0.579*N_z
%     23770^0.579 = exp(0.579*10.07617962) = exp(5.83410801) = 341.7577
%     0.013*341.7577*13.5 = 59.9785 lbf
%   Eq. 15.8  FIREWALL = 1.13*S_fw = 1.13*0 = 0 lbf exactly (jet, no firewall)
%   Eq. 15.9  ENGINE SECTION = 0.01*W_en^0.717*N_en*N_z
%     ln(2775.0065) = 7.92841380 ; *0.717 = 5.68467269
%     exp(5.68467269) = 294.32152 ; 0.01*294.32152*13.5 = 39.7334 lbf
%   Eq. 15.10 AIR INDUCTION = 13.29*K_vg*L_d^0.643*K_d^0.182*N_en^1.498
%                              *(L_s/L_d)^-0.373*D_e
%     7.5^0.643 = exp(0.643*2.01490302) = exp(1.29558264) = 3.6531481
%     (3.0/7.5)^-0.373 = 0.4^-0.373 = exp(0.34177643) = 1.4074455
%     13.29*3.6531481 = 48.550338 ; *1.4074455 = 68.331875 ; *3.33
%       = 227.545 lbf
%   Eq. 15.11 TAILPIPE = 3.5*D_e*L_tp*N_en = 3.5*3.33*4.5 = 52.4475 lbf exactly
%   Eq. 15.12 COOLING  = 4.55*D_e*L_sh*N_en = 4.55*3.33*8.0 = 121.212 lbf exactly
%   Eq. 15.13 OIL      = 37.82*N_en^1.023 = 37.82*1 = 37.82 lbf exactly
%     (! at N_en = 1 the documented 1.023-vs-extract-1.078 CONFLICT is
%      numerically invisible; it must not be assumed benign.)
%   Eq. 15.14 CONTROLS = 10.5*N_en^1.008*L_ec^0.222
%     5.0^0.222 = exp(0.222*1.60943791) = exp(0.35729522) = 1.4294575
%     10.5*1.4294575 = 15.0093 lbf
%   Eq. 15.15 STARTER = 0.025*T^0.760*N_en^0.72
%     23770^0.760 = exp(0.760*10.07617962) = exp(7.65789651) = 2117.2987
%     0.025*2117.2987 = 52.9325 lbf
%     -> ENGINE GROUP TOTAL = 2775.0065 + 59.9785 + 0 + 39.7334 + 227.545
%          + 52.4475 + 121.212 + 37.82 + 15.0093 + 52.9325 = 3381.6847 lbf
%
%   Eq. 15.16 FUEL SYSTEM = 7.45*V_t^0.47*(1+V_i/V_t)^-0.095*(1+V_p/V_t)
%                            *N_t^0.066*N_en^0.052*((T*SFC)/1000)^0.249
%     SFC = prop.get_TSFC(AircraftState(36000, 0.87)) -- a propulsion DI, so it
%     is NOT asserted as a literal here (see testSFCMissionIsDIAtCruiseCondition);
%     the hand value below uses its live magnitude 1.007116 1/hr purely to
%     evaluate Eq. 15.16's own arithmetic.
%     940^0.47 = exp(0.47*6.84587988) = exp(3.21756354) = 24.965377
%     (1+500/940) = 1.53191489 ; ^-0.095 = exp(-0.095*0.42651840)
%       = exp(-0.04051925) = 0.9602907
%     (1+0/940) = 1
%     3^0.066 = exp(0.066*1.09861229) = exp(0.07250841) = 1.0752026
%     (23770*1.007116)/1000 = 23.939147 ; ^0.249 = exp(0.249*3.17551510)
%       = exp(0.79060326) = 2.2046362
%     7.45*24.965377 = 185.992058 ; *0.9602907 = 178.60645 ; *1.0752026
%       = 192.03618 ; *2.2046362 = 423.366 lbf
%   Eq. 15.17 FLIGHT CONTROLS = 36.28*M^0.003*S_cs^0.489*N_s^0.484*N_c^0.127
%     2.0^0.003 = exp(0.00207944) = 1.0020816
%     190^0.489 = exp(0.489*5.24702407) = exp(2.56579477) = 13.011039
%     4^0.484   = exp(0.484*1.38629436) = exp(0.67096647) = 1.9561271
%     36.28*1.0020816 = 36.355321 ; *13.011039 = 473.020 ; *1.9561271
%       = 925.283 lbf
%   Eq. 15.18 INSTRUMENTS = 8.0 + 36.37*N_en^0.676*N_t^0.237
%                             + 26.4*(1+N_ci)^1.356
%     3^0.237 = exp(0.26037112) = 1.2974115 ; 36.37*1.2974115 = 47.186856
%     4^1.356 = exp(1.87981515) = 6.552292 ; 26.4*6.552292 = 172.98051
%     8.0 + 47.186856 + 172.98051 = 228.16737 lbf
%   Eq. 15.19 HYDRAULICS = 37.23*K_vsh*N_u^0.664
%     5^0.664 = exp(0.664*1.60943791) = exp(1.06866678) = 2.911477
%     37.23*2.911477 = 108.39429 lbf
%   Eq. 15.20 ELECTRICAL = 172.2*K_mc*R_kva^0.152*N_c^0.10*L_a^0.10*N_gen^0.091
%     80^0.152 = exp(0.152*4.38202663) = exp(0.66606805) = 1.946569
%     10^0.10  = 1.25892541
%     172.2*1.946569 = 335.19919 ; *1.25892541 = 422.007 lbf
%   Eq. 15.21 AVIONICS = 2.117*W_uav^0.933
%     1500^0.933 = exp(0.933*7.31322039) = exp(6.82323463) = 918.9505
%     2.117*918.9505 = 1945.418 lbf
%   Eq. 15.22 FURNISHINGS = 217.6*N_c = 217.6 lbf exactly
%   Eq. 15.23 AC/ANTI-ICE = 201.6*((W_uav+200*N_c)/1000)^0.735
%     1.7^0.735 = exp(0.735*0.53062825) = exp(0.39001176) = 1.4769981
%     201.6*1.4769981 = 297.7628 lbf
%   Eq. 15.24 HANDLING = 3.2e-4*W_dg = 3.2e-4*31377 = 10.04064 lbf exactly
%     -> SYSTEMS GROUP TOTAL = 423.366 + 925.283 + 228.16737 + 108.39429
%          + 422.007 + 1945.418 + 217.6 + 297.7628 + 10.04064 = 4578.039 lbf
%
%   OEW(31377) = wing + HT + VT + fuselage + LG.main + LG.nose
%                + engine group + systems group
%              = 2396.944 + 200.5104 + 313.0505 + 3674.18 + 989.843
%                + 170.9044 + 3381.6847 + 4578.039
%              = 15705.156 lbf
%
%   TOLERANCE RATIONALE. Every hand value above is decimal arithmetic carried
%   to ~8 significant figures through 1-4 chained exp/ln series evaluations,
%   with the products accumulated by hand. The truncation of that arithmetic is
%   the only source of disagreement the tests below allow for; measured across
%   the 24 equations its worst case is ~3e-4 relative (Eqs. 15.6 and 15.16,
%   the longest chains). RelTol = 1e-3 is that worst case with ~3x margin.
%   Equations whose result is an exact decimal product (15.8, 15.11, 15.12,
%   15.13, 15.22, 15.24) use AbsTol 1e-6 instead.
%   This tolerance is emphatically NOT the +-20-30 % statistical scatter of
%   Raymer's regressions. That scatter is a property of the METHOD compared
%   against a real aircraft, which is the comparison report's subject; here the
%   only question is whether the code computes the equation it documents.

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance / construction contract
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            tc.verifyTrue(isa(TestWeightsL3.makeW3(), 'WeightsBase'), ...
                'F16WeightsL3 must inherit WeightsBase.');
        end

        function testIsaWeightsModelL3(tc)
            tc.verifyTrue(isa(TestWeightsL3.makeW3(), 'WeightsModelL3'), ...
                'F16WeightsL3 must inherit WeightsModelL3.');
        end

        function testNotIsaWeightsModelL1(tc)
            tc.verifyFalse(isa(TestWeightsL3.makeW3(), 'WeightsModelL1'), ...
                'F16WeightsL3 must NOT inherit WeightsModelL1.');
        end

        function testConstructorRequiresAllFourArguments(tc)
        %TESTCONSTRUCTORREQUIRESALLFOURARGUMENTS  Review finding #11's fix.
        %   The pre-Phase-4 constructor took NO argument and its entire body was
        %   a comment, so the .weights block of f16a_L3.json was read by nothing
        %   and ~22 geometry constants sat frozen inside a weights class.
            tc.verifyError(@() F16WeightsL3(), 'MATLAB:minrhs', ...
                'F16WeightsL3 must require json_path.');
            tc.verifyError(@() F16WeightsL3(f16a_spec_path(3)), 'MATLAB:minrhs', ...
                'F16WeightsL3 must require req_path.');
            tc.verifyError(@() F16WeightsL3(f16a_spec_path(3), f16a_requirements_path()), ...
                'MATLAB:minrhs', 'F16WeightsL3 must require an injected geom.');
        end

        function testWrongGeomTierErrorsAtConstruction(tc)
        %TESTWRONGGEOMTIERERRORSATCONSTRUCTION  L3 wants GeometryModelL3.
        %   The finding-#10 lesson: a too-loose type guard lets the wrong tier
        %   construct fine and then resolve property names to DIFFERENT physical
        %   quantities mid-run with no error. Passing the L2 geometry tier must
        %   fail HERE.
            prop = TestWeightsL3.makeProp();
            g2   = F16GeomL2(f16a_spec_path(2), prop);
            g1   = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g2, prop), ...
                'MATLAB:validation:UnableToConvert', ...
                'An L2 geometry object must be rejected at construction (L3 wants GeometryModelL3).');
            tc.verifyError(@() F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g1, prop), ...
                'MATLAB:validation:UnableToConvert', ...
                'An L1 geometry object must be rejected at construction.');
        end

        function testJSONInputsAreActuallyRead(tc)
        %TESTJSONINPUTSAREACTUALLYREAD  Finding #11: the .weights block was dead.
        %   Compared against the file rather than against literals, so a JSON
        %   edit cannot silently desync the class from its input.
            J = jsondecode(fileread(f16a_spec_path(3)));
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.N_z,   J.weights.N_z,   'N_z must be read from f16a_L3.json.');
            tc.verifyEqual(w.V_t,   J.weights.systems.V_t, 'V_t must be read from the JSON.');
            tc.verifyEqual(w.L_d,   J.weights.engine_section.L_d, 'L_d must be read from the JSON.');
            tc.verifyEqual(w.K_rht, J.weights.horizontal_tail.K_rht, 'K_rht must be read from the JSON.');
            tc.verifyEqual(w.N_l,   J.weights.landing_gear.N_l, 'N_l must be read from the JSON.');
            tc.verifyEqual(w.W_uav, J.weights.systems.W_uav, 'W_uav must be read from the JSON.');
        end

        function testRequirementsAreReadFromTheRequirementsFile(tc)
        %TESTREQUIREMENTSAREREADFROMTHEREQUIREMENTSFILE  design_mach + cruise.
        %   design_mach is Brandt Main! aircraft.Mmax = 2.0, NOT the T.O.
        %   1F-16A-1 operating Mach LIMIT 2.05 -- two different numbers, and
        %   citing 2.0 to the T.O. would be the same class of wrong-source
        %   attribution as the 19,148 error (todo Sec. P4-13).
            R = jsondecode(fileread(f16a_requirements_path()));
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.design_mach, R.design_mach, ...
                'design_mach must come from f16a_requirements.json.');
            tc.verifyEqual(w.cruise_altitude_ft, R.cruise.altitude_ft, ...
                'cruise_altitude_ft must come from f16a_requirements.json.');
            tc.verifyEqual(w.cruise_mach, R.cruise.mach, ...
                'cruise_mach must come from f16a_requirements.json.');
            tc.verifyNotEqual(w.design_mach, 2.05, ...
                'design_mach is Brandt''s 2.0, NOT the T.O. Mach limit 2.05 (todo Sec. P4-13).');
        end

    end

    % ------------------------------------------------------------------ %
    % Per-equation hand-computed values (structural group)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWingWeightEq151HandComputed(tc)
            % Header derivation, Eq. 15.1 -> 2396.944 lbf.
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.weight_wing(31377), 2396.944, 'RelTol', 1e-3, ...
                'Eq. 15.1 wing weight must be 2396.944 lbf at W_dg = 31377.');
        end

        function testTailWeightsEq152And153HandComputed(tc)
            % Header derivations, Eqs. 15.2 -> 200.5104 and 15.3 -> 313.0505.
            w = TestWeightsL3.makeW3();
            W_t = w.weight_tail(31377);
            tc.verifyEqual(W_t.HT, 200.5104, 'RelTol', 1e-3, ...
                'Eq. 15.2 HT weight must be 200.5104 lbf (EXPOSED S_ht = 51.148643).');
            tc.verifyEqual(W_t.VT, 313.0505, 'RelTol', 1e-3, ...
                'Eq. 15.3 VT weight must be 313.0505 lbf (EXPOSED S_vt/AR_vt/lambda_vt).');
        end

        function testFuselageWeightEq154HandComputed(tc)
            % Header derivation, Eq. 15.4 -> 3674.18 lbf at D_fus = 5.0.
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.weight_fuselage(31377), 3674.18, 'RelTol', 1e-3, ...
                'Eq. 15.4 fuselage weight must be 3674.18 lbf at the 5.0 ft structural depth.');
        end

        function testLandingGearEqs155And156HandComputed(tc)
            % Header derivations, Eqs. 15.5 -> 989.843 and 15.6 -> 170.9044.
            w = TestWeightsL3.makeW3();
            W_lg = w.weight_landing_gear(31377);
            tc.verifyEqual(W_lg.main, 989.843, 'RelTol', 1e-3, ...
                'Eq. 15.5 main gear must be 989.843 lbf at W_l = 0.95*31377.');
            tc.verifyEqual(W_lg.nose, 170.9044, 'RelTol', 1e-3, ...
                'Eq. 15.6 nose gear must be 170.9044 lbf at W_l = 0.95*31377.');
        end

        function testStrutLengthsAreConvertedToInches(tc)
        %TESTSTRUTLENGTHSARECONVERTEDTOINCHES  A load-bearing units conversion.
        %   Raymer's nomenclature defines L_m / L_n in INCHES; the JSON carries
        %   aircraft-spec strut lengths in FEET. Omitting the x12 made the gear
        %   come out ~8x too low. Checked by calling the low-level static with
        %   feet and confirming the class result matches the INCHES call.
            w = TestWeightsL3.makeW3();
            W_lg   = w.weight_landing_gear(31377);
            W_l    = 0.95 * 31377;
            in_ver = WeightsL3.main_gear(W_l, w.N_l, w.L_m * 12, w.K_cb, w.K_tpg);
            ft_ver = WeightsL3.main_gear(W_l, w.N_l, w.L_m,      w.K_cb, w.K_tpg);
            tc.verifyEqual(W_lg.main, in_ver, 'AbsTol', 1e-9, ...
                'weight_landing_gear must pass L_m in INCHES to Eq. 15.5.');
            tc.verifyGreaterThan(W_lg.main / ft_ver, 8, ...
                'The feet-vs-inches error is worth a factor of ~11 -- it must not recur.');
        end

    end

    % ------------------------------------------------------------------ %
    % Per-equation hand-computed values (engine group, Eqs. 15.7-15.15 + 10.10)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testEngineDryWeightIsUninstalledEq1010(tc)
        %TESTENGINEDRYWEIGHTISUNINSTALLEDEQ1010  Settled decision 1.
        %   L3 consumes the UNINSTALLED 2775.0065; the metabook x1.3 factor is
        %   a lumped stand-in for exactly the nine installation items
        %   Eqs. 15.7-15.15 already add, so applying it here double-counts. The
        %   rejected x1.3 variant agrees BETTER with Brandt (OEW -17.19 % vs
        %   -21.40 %), which is the evidence AGAINST it, not for it.
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.W_en, 2775.0065, 'RelTol', 2e-5, ...
                'W_en must be Raymer Eq. 10.10 UNINSTALLED = 2775.0065 lbf.');
            W_eng = w.weight_engine_section(31377);
            tc.verifyEqual(W_eng.engine, w.W_en * w.N_en, 'AbsTol', 1e-9, ...
                'The engine line must be N_en * the UNINSTALLED weight.');
            tc.verifyNotEqual(W_eng.engine, 1.3 * w.W_en * w.N_en, ...
                'L3 must NOT apply the x1.3 installed factor -- that is L2-only.');
            tc.verifyNotEqual(w.W_en, 3030, ...
                'W_en must be computed, not the former stored 3030 [estimate].');
        end

        function testEngineInstallationItemsHandComputed(tc)
            % Header derivations, Eqs. 15.7-15.15.
            w = TestWeightsL3.makeW3();
            W = w.weight_engine_section(31377);
            tc.verifyEqual(W.mounts,    59.9785,  'RelTol', 1e-3, 'Eq. 15.7 mounts.');
            tc.verifyEqual(W.firewall,  0,        'AbsTol', 1e-6, ...
                'Eq. 15.8 firewall must be exactly 0 (S_fw = 0, no piston firewall).');
            tc.verifyEqual(W.section,   39.7334,  'RelTol', 1e-3, 'Eq. 15.9 engine section.');
            tc.verifyEqual(W.induction, 227.545,  'RelTol', 1e-3, 'Eq. 15.10 air induction.');
            tc.verifyEqual(W.tailpipe,  52.4475,  'AbsTol', 1e-6, ...
                'Eq. 15.11 tailpipe = 3.5*3.33*4.5 exactly.');
            tc.verifyEqual(W.cooling,   121.212,  'AbsTol', 1e-6, ...
                'Eq. 15.12 cooling = 4.55*3.33*8.0 exactly.');
            tc.verifyEqual(W.oil,       37.82,    'AbsTol', 1e-6, ...
                'Eq. 15.13 oil cooling = 37.82*1^1.023 exactly.');
            tc.verifyEqual(W.controls,  15.0093,  'RelTol', 1e-3, 'Eq. 15.14 engine controls.');
            tc.verifyEqual(W.starter,   52.9325,  'RelTol', 1e-3, 'Eq. 15.15 starter.');
        end

        function testEngineGroupTotalHandComputed(tc)
            % Header: engine group total 3381.6847 lbf, and the internal sum.
            w = TestWeightsL3.makeW3();
            W = w.weight_engine_section(31377);
            tc.verifyEqual(W.total, 3381.6847, 'RelTol', 1e-3, ...
                'Engine group total must be 3381.6847 lbf (UNINSTALLED engine + Eqs. 15.7-15.15).');
            parts = W.engine + W.mounts + W.firewall + W.section + W.induction ...
                    + W.tailpipe + W.cooling + W.oil + W.controls + W.starter;
            tc.verifyEqual(W.total, parts, 'AbsTol', 1e-9, ...
                'Engine group .total must be the exact sum of its ten sub-items.');
        end

        function testEngineWeightsPositive(tc)
            % Non-negativity across every field of the group struct.
            w = TestWeightsL3.makeW3();
            vals = TestWeightsL3.structValues(w.weight_engine_section(31377));
            tc.verifyTrue(all(vals >= 0), ...
                'Every engine-section sub-weight must be >= 0.');
            tc.verifyTrue(all(isfinite(vals)), ...
                'Every engine-section sub-weight must be finite.');
        end

    end

    % ------------------------------------------------------------------ %
    % Per-equation hand-computed values (systems group, Eqs. 15.16-15.24)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testSystemsItemsHandComputed(tc)
            % Header derivations, Eqs. 15.16-15.24.
            w = TestWeightsL3.makeW3();
            W = w.weight_systems(31377);
            tc.verifyEqual(W.fuel_sys,    423.366,   'RelTol', 1e-3, 'Eq. 15.16 fuel system.');
            tc.verifyEqual(W.flight_ctrl, 925.283,   'RelTol', 1e-3, 'Eq. 15.17 flight controls.');
            tc.verifyEqual(W.instruments, 228.16737, 'RelTol', 1e-3, 'Eq. 15.18 instruments.');
            tc.verifyEqual(W.hydraulics,  108.39429, 'RelTol', 1e-3, 'Eq. 15.19 hydraulics.');
            tc.verifyEqual(W.electrical,  422.007,   'RelTol', 1e-3, 'Eq. 15.20 electrical.');
            tc.verifyEqual(W.avionics,    1945.418,  'RelTol', 1e-3, 'Eq. 15.21 avionics.');
            tc.verifyEqual(W.furnishings, 217.6,     'AbsTol', 1e-6, ...
                'Eq. 15.22 furnishings = 217.6*N_c exactly.');
            tc.verifyEqual(W.ac_antiice,  297.7628,  'RelTol', 1e-3, 'Eq. 15.23 AC / anti-ice.');
            tc.verifyEqual(W.handling,    10.04064,  'AbsTol', 1e-6, ...
                'Eq. 15.24 handling gear = 3.2e-4*31377 exactly.');
        end

        function testSystemsGroupTotalHandComputed(tc)
            w = TestWeightsL3.makeW3();
            W = w.weight_systems(31377);
            tc.verifyEqual(W.total, 4578.039, 'RelTol', 1e-3, ...
                'Systems group total must be 4578.039 lbf (Eqs. 15.16-15.24).');
        end

        function testSystemsGroupContainsNoLandingGearTerm(tc)
        %TESTSYSTEMSGROUPCONTAINSNOLANDINGGEARTERM  WeightsModelL3's comment is
        %   wrong (todo Sec. P4-10): W_subsystems does NOT include the gear.
        %   OEW adds Eqs. 15.5/15.6 separately, so the systems total must be far
        %   below the systems + gear sum -- otherwise the gear is double-counted.
            w = TestWeightsL3.makeW3();
            w.W_TO = 31377;
            W_sys = w.weight_systems(31377);
            tc.verifyFalse(any(contains(lower(fieldnames(W_sys)), 'gear')), ...
                ['weight_systems must expose no landing-gear field: the gear is ' ...
                 'Eqs. 15.5/15.6 and is summed separately by OEW (todo Sec. P4-10).']);
            tc.verifyEqual(w.W_subsystems, W_sys.total, 'AbsTol', 1e-9, ...
                'W_subsystems must be exactly weight_systems(...).total -- gear excluded.');
        end

        function testSystemsWeightsPositive(tc)
            w = TestWeightsL3.makeW3();
            vals = TestWeightsL3.structValues(w.weight_systems(31377));
            tc.verifyTrue(all(vals >= 0), 'Every systems sub-weight must be >= 0.');
            tc.verifyTrue(all(isfinite(vals)), 'Every systems sub-weight must be finite.');
        end

        function testSFCMissionIsDIAtCruiseCondition(tc)
        %TESTSFCMISSIONISDIATCRUISECONDITION  Settled decision 2.
        %   SFC_mission is prop.get_TSFC evaluated at the requirements-file
        %   cruise condition. Asserted as an IDENTITY against the injected
        %   engine, plus responsiveness to the cruise condition -- deliberately
        %   NOT as the literal 1.007116, which would freeze a propulsion output
        %   into a weights unit test.
            [w, ~, prop] = TestWeightsL3.makeW3();
            expected = prop.get_TSFC(AircraftState(w.cruise_altitude_ft, w.cruise_mach));
            tc.verifyEqual(w.SFC_mission, expected, 'AbsTol', 1e-12, ...
                'SFC_mission must be prop.get_TSFC at the requirements cruise state.');
            sfc_at_M087   = w.SFC_mission;
            w.cruise_mach = 0.95;
            tc.verifyNotEqual(w.SFC_mission, sfc_at_M087, ...
                'SFC_mission must track the cruise condition live.');
            tc.verifyNotEqual(sfc_at_M087, 0.70, ...
                ['SFC_mission must NOT be Brandt Main!C30 = 0.70: that is an ' ...
                 'already-installed single SLS constant, a different quantity ' ...
                 '(the +43.87 %% divergence is accepted by decision 2).']);
        end

    end

    % ------------------------------------------------------------------ %
    % Sec. P4-17 -- the landing gear was FROZEN under mutation
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLandingGearScalesWithWTO(tc)
        %TESTLANDINGGEARSCALESWITHWTO  The Sec. P4-17 regression guard.
        %
        %   Before Phase 4, W_l was a stored 20681 [Brandt Wt!B41, itself
        %   =SUM(B16:B32) -- a back-calculated OUTPUT] AND
        %   WeightsL3.weight_landing_gear took no W_TO argument, so the ENTIRE
        %   gear group was bit-identical at every gross weight: 1057.273 lbf at
        %   31,377, 45,000 and 60,000 alike. Same defect class and signature as
        %   review finding #5 one tier down. No test caught it because every
        %   TestWeightsL3 case called OEW(31377).
        %
        %   Expected values are the header derivations of Eqs. 15.5/15.6 at
        %   W_l = 0.95*W_TO for the three gross weights.
            w = TestWeightsL3.makeW3();
            t31 = TestWeightsL3.gearTotal(w, 31377);
            t45 = TestWeightsL3.gearTotal(w, 45000);
            t60 = TestWeightsL3.gearTotal(w, 60000);
            tc.verifyEqual(t31, 1160.747, 'RelTol', 1e-3, ...
                'LG total at W_TO = 31377 must be 1160.747 lbf (Eqs. 15.5+15.6, W_l = 29808.15).');
            tc.verifyEqual(t45, 1273.131, 'RelTol', 1e-3, ...
                'LG total at W_TO = 45000 must be 1273.131 lbf (W_l = 42750).');
            tc.verifyEqual(t60, 1370.428, 'RelTol', 1e-3, ...
                'LG total at W_TO = 60000 must be 1370.428 lbf (W_l = 57000).');
            tc.verifyGreaterThan(t45, t31, 'LG must grow with W_TO.');
            tc.verifyGreaterThan(t60, t45, 'LG must grow with W_TO.');
        end

        function testLandingGearIsNotTheFrozenValue(tc)
        %TESTLANDINGGEARISNOTTHEFROZENVALUE  Pin the specific old wrong number.
        %   1057.273 lbf is what the frozen W_l = 20681 produced -- at EVERY
        %   gross weight. Pinned as a not-equal guard, the way TestGeomL2 pins
        %   the VT 0.33 deg trailing-edge-sweep bug.
            w = TestWeightsL3.makeW3();
            frozen = 1057.273;
            tc.verifyNotEqual(TestWeightsL3.gearTotal(w, 31377), frozen, ...
                'LG total must no longer be the frozen-W_l 1057.273 lbf.');
            tc.verifyNotEqual(TestWeightsL3.gearTotal(w, 45000), frozen, ...
                'LG total at 45000 must not be the frozen 1057.273 lbf.');
            tc.verifyNotEqual(TestWeightsL3.gearTotal(w, 60000), frozen, ...
                'LG total at 60000 must not be the frozen 1057.273 lbf.');
        end

        function testLandingGearArgumentWinsOverStaleObjectWTO(tc)
        %TESTLANDINGGEARARGUMENTWINSOVERSTALEOBJECTWTO  Both halves of the fix.
        %   Even with W_l derived from W_TO, if weight_landing_gear read obj.W_TO
        %   instead of its own argument then OEW(W_TO) would evaluate the gear at
        %   the object's current sizing iterate -- a different quantity. Set a
        %   stale obj.W_TO and require the ARGUMENT to win.
            w = TestWeightsL3.makeW3();
            w.W_TO = 31377;                                  % stale iterate
            tc.verifyEqual(TestWeightsL3.gearTotal(w, 45000), 1273.131, ...
                'RelTol', 1e-3, ...
                'weight_landing_gear must use its ARGUMENT, not a stale obj.W_TO.');
            tc.verifyNotEqual(TestWeightsL3.gearTotal(w, 45000), ...
                TestWeightsL3.gearTotal(w, 31377), ...
                'The gear must differ at the two arguments despite one obj.W_TO.');
        end

        function testLandingWeightIsDerivedFromWTO(tc)
        %TESTLANDINGWEIGHTISDERIVEDFROMWTO  W_l = 0.95*W_TO, and NOT 20681.
        %   ! The 0.95 factor has NO citation in this repo (user-supplied,
        %   todo Sec. P4-16 OPEN). This test asserts only that the code applies
        %   the factor it documents and that the Brandt OUTPUT is gone; it does
        %   NOT attest to 0.95 being sourced. Brandt's own implied ratio is
        %   20680.700578/31377 = 0.6591, a definitionally different quantity.
            w = TestWeightsL3.makeW3();
            w.W_TO = 31377;
            tc.verifyEqual(w.W_l, 0.95 * 31377, 'AbsTol', 1e-6, ...
                'W_l must be 0.95 * W_TO = 29808.15 lbf.');
            tc.verifyNotEqual(w.W_l, 20681, ...
                'W_l must no longer be the frozen Brandt Wt!B41 output 20681.');
            w.W_TO = 45000;
            tc.verifyEqual(w.W_l, 0.95 * 45000, 'AbsTol', 1e-6, ...
                'W_l must track W_TO live.');
        end

    end

    % ------------------------------------------------------------------ %
    % Total OEW: invariants, hand-computed value, argument-scaling
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            w = TestWeightsL3.makeW3();
            tc.verifyLessThan(w.OEW(31377), 31377, ...
                'L3 OEW must be less than W_TO for any physical design.');
        end

        function testOEWGreaterThanZero(tc)
            w = TestWeightsL3.makeW3();
            tc.verifyGreaterThan(w.OEW(31377), 0, 'L3 OEW must be positive.');
        end

        function testOEWAboveSanityMinimum(tc)
            % No real jet fighter has OEW/TOGW < 30 %. Engineering sanity bound.
            w = TestWeightsL3.makeW3();
            tc.verifyGreaterThan(w.OEW(31377), 0.30 * 31377, ...
                'L3 OEW must exceed 30 % of W_TO.');
        end

        function testOEWHandComputed(tc)
        %TESTOEWHANDCOMPUTED  Header total -- replaces the removed +-40 % gate.
            w = TestWeightsL3.makeW3();
            tc.verifyEqual(w.OEW(31377), 15705.156, 'RelTol', 1e-3, ...
                'L3 OEW(31377) must equal the hand-summed Sec. 15.3.1 buildup = 15705.156 lbf.');
        end

        function testOEWEqualsSumOfItsGroups(tc)
            % Internal aggregation identity; guards OEW against drifting away
            % from the per-group methods the report and tests above exercise.
            w = TestWeightsL3.makeW3();
            W_TO  = 31377;
            W_t   = w.weight_tail(W_TO);
            W_lg  = w.weight_landing_gear(W_TO);
            total = w.weight_wing(W_TO) + W_t.HT + W_t.VT + w.weight_fuselage(W_TO) ...
                    + W_lg.main + W_lg.nose ...
                    + w.weight_engine_section(W_TO).total + w.weight_systems(W_TO).total;
            tc.verifyEqual(w.OEW(W_TO), total, 'AbsTol', 1e-9, ...
                'OEW must equal the exact sum of its eight group terms.');
        end

        function testOEWScalesWithItsArgument(tc)
        %TESTOEWSCALESWITHITSARGUMENT  Nothing may be frozen at one W_TO.
        %   Every Sec. 15.3.1 group except the engine group carries W_dg, and
        %   the gear carries it through W_l, so OEW must be strictly increasing
        %   in its argument.
            w = TestWeightsL3.makeW3();
            tc.verifyGreaterThan(w.OEW(45000), w.OEW(31377), ...
                'OEW must increase with its W_TO argument.');
            tc.verifyGreaterThan(w.OEW(60000), w.OEW(45000), ...
                'OEW must increase with its W_TO argument.');
        end

        function testOEWWorksWithWTOUnset(tc)
        %TESTOEWWORKSWITHWTOUNSET  OEW is a pure function of its argument.
            w = TestWeightsL3.makeW3();
            tc.verifyTrue(isnan(w.W_TO), 'obj.W_TO must be NaN until set.');
            tc.verifyEqual(w.OEW(31377), 15705.156, 'RelTol', 1e-3, ...
                'OEW must be computable with obj.W_TO unset.');
        end

    end

    % ------------------------------------------------------------------ %
    % REVIEW FINDING #11 / Sec. B.3 -- the three geometry DI name traps
    % ------------------------------------------------------------------ %

    methods (Test)

        function testNameTrapExposedVsFullTailAreas(tc)
        %TESTNAMETRAPEXPOSEDVSFULLTAILAREAS  Trap 1.
        %   geom.S_ht / geom.S_vt mean the FULL planform (108 / 60) on both
        %   geometry tiers after the Phase-2 rename; Raymer Eqs. 15.2/15.3 want
        %   the EXPOSED planform. Wiring the FULL names raises NO error and
        %   returns a plausible wrong number, so the wrong value is asserted
        %   against explicitly.
            [w, geom] = TestWeightsL3.makeW3();
            tc.verifyEqual(w.S_ht, geom.S_exposed_ht, 'AbsTol', 1e-9, ...
                'S_ht must be geom.S_exposed_ht.');
            tc.verifyEqual(w.S_ht, 51.148643, 'RelTol', 1e-6, ...
                'S_ht must be the EXPOSED 51.148643 ft^2 (F16GeomL3''s 18.5 ft span).');
            tc.verifyNotEqual(w.S_ht, 108, ...
                'S_ht must NOT be the FULL planform 108 ft^2 (geom.S_ht).');
            tc.verifyEqual(w.S_vt, geom.S_exposed_vt, 'AbsTol', 1e-9, ...
                'S_vt must be geom.S_exposed_vt.');
            tc.verifyEqual(w.S_vt, 40.889669, 'RelTol', 1e-6, ...
                'S_vt must be the EXPOSED 40.889669 ft^2.');
            tc.verifyNotEqual(w.S_vt, 60, ...
                'S_vt must NOT be the FULL planform 60 ft^2 (geom.S_vt).');
        end

        function testNameTrapExposedVsFullVTPlanformShape(tc)
        %TESTNAMETRAPEXPOSEDVSFULLVTPLANFORMSHAPE  Trap 2.
        %   Eq. 15.3 carries AR_vt^0.223 and (1+lambda_vt)^0.25 on the SAME
        %   exposed panel its S_vt describes, so the FULL-planform 1.6 / 0.5
        %   would be inconsistent -- and silent.
            [w, geom] = TestWeightsL3.makeW3();
            tc.verifyEqual(w.AR_vt, geom.AR_exposed_vt, 'AbsTol', 1e-9, ...
                'AR_vt must be geom.AR_exposed_vt.');
            tc.verifyEqual(w.AR_vt, 1.294, 'RelTol', 1e-6, ...
                'AR_vt must be the EXPOSED 1.294.');
            tc.verifyNotEqual(w.AR_vt, 1.6, ...
                'AR_vt must NOT be the FULL-planform 1.6 (geom.AR_vt).');
            tc.verifyEqual(w.lambda_vt, geom.lambda_exposed_vt, 'AbsTol', 1e-9, ...
                'lambda_vt must be geom.lambda_exposed_vt.');
            tc.verifyEqual(w.lambda_vt, 0.437, 'RelTol', 1e-6, ...
                'lambda_vt must be the EXPOSED 0.437.');
            tc.verifyNotEqual(w.lambda_vt, 0.5, ...
                'lambda_vt must NOT be the FULL-planform 0.5 (geom.lambda_vt).');
        end

        function testNameTrapFuselageDepthVsEquivalentDiameter(tc)
        %TESTNAMETRAPFUSELAGEDEPTHVSEQUIVALENTDIAMETER  Trap 3, the costliest.
        %   Weights' D_fus is Eq. 15.4's maximum structural DEPTH (5.0 ft). The
        %   geometry object's Dependent D_fus is (W_max+H_max)/2 = 6.0 ft, the
        %   Roskam Vol. II Eq. 12.3 EQUIVALENT DIAMETER used only for fuselage
        %   wetted area. Same property NAME, different physical quantity, and
        %   because Eq. 15.4 carries D_fus^0.849 the substitution inflates the
        %   fuselage by (6/5)^0.849 = +17.9 % with no error.
            [w, geom] = TestWeightsL3.makeW3();
            tc.verifyEqual(w.D_fus, geom.H_max_fuselage, 'AbsTol', 1e-9, ...
                'weights D_fus must be geom.H_max_fuselage (structural DEPTH).');
            tc.verifyEqual(w.D_fus, 5.0, 'AbsTol', 1e-9, ...
                'weights D_fus must be 5.0 ft.');
            tc.verifyNotEqual(w.D_fus, geom.D_fus, ...
                'weights D_fus must NOT be geom.D_fus (the 6.0 ft equivalent diameter).');
            tc.verifyEqual(geom.D_fus, 6.0, 'AbsTol', 1e-9, ...
                'Guard on the guard: geom.D_fus is the 6.0 ft equivalent diameter.');
        end

        function testDeadHTAspectRatioAndTaperAreDeleted(tc)
        %TESTDEADHTASPECTRATIOANDTAPERAREDELETED  todo Sec. P4-6.
        %   Raymer Eq. 15.2 takes only (W_dg, N_z, S_ht, F_w, B_h) -- no HT
        %   aspect ratio, no HT taper -- so the former AR_ht = 2.114 /
        %   lambda_ht = 0.390 inputs were read by no equation. They were
        %   DELETED, deliberately not re-pointed at geom.AR_exposed_ht /
        %   geom.lambda_exposed_ht.
            w = TestWeightsL3.makeW3();
            tc.verifyFalse(isprop(w, 'AR_ht'), ...
                'AR_ht was dead (Eq. 15.2 does not take it) and must stay deleted.');
            tc.verifyFalse(isprop(w, 'lambda_ht'), ...
                'lambda_ht was dead and must stay deleted.');
        end

        function testPropulsionDIReplacesFrozenThrust(tc)
        %TESTPROPULSIONDIREPLACESFROZENTHRUST  T_max was a 23770 literal.
            [w, ~, prop] = TestWeightsL3.makeW3();
            tc.verifyEqual(w.T_max, prop.T_SL, 'AbsTol', 1e-9, ...
                'T_max must be prop.T_SL by DI, not a frozen literal.');
        end

    end

    % ------------------------------------------------------------------ %
    % REVIEW FINDING #12 -- the 31 Dependent properties
    % ------------------------------------------------------------------ %

    methods (Test)

        function testAllThirtyOneDependentPropertiesExist(tc)
        %TESTALLTHIRTYONEDEPENDENTPROPERTIESEXIST  The declared split.
        %   F16WeightsL3.md Sec. B: 43 inputs (42 numeric + 1 string) + 2
        %   injected objects; 31 Dependent. A count change means the split moved
        %   and the sweeps below no longer cover what they claim to.
            tc.verifyEqual(numel(TestWeightsL3.dependentNames()), 31, ...
                'F16WeightsL3 must declare exactly 31 Dependent properties.');
        end

        function testNoDependentPropertyIsNonFinite(tc)
        %TESTNODEPENDENTPROPERTYISNONFINITE  Finding #12's headline symptom.
        %   W_wings / W_tail / W_fuselage / W_installed_engine / W_subsystems
        %   were declared abstract, satisfied with "= NaN", and never assigned,
        %   so a consumer reading the documented contract got NaN. Sweeps ALL 31
        %   Dependents (metaclass-derived, so a newly added one is covered) at a
        %   set W_TO, expanding the W_tail struct to its two scalars.
            w = TestWeightsL3.makeW3();
            w.W_TO = 31377;
            vals = TestWeightsL3.flattenDependents(w);
            tc.verifyTrue(all(isfinite(vals)), ...
                'No Dependent property may read NaN or Inf at W_TO = 31377.');
            tc.verifyEqual(numel(vals), 32, ...
                'Sweep must cover 31 Dependents = 32 scalars (W_tail has HT and VT).');
        end

        function testWTODependentPropertiesErrorWhenWTOUnset(tc)
        %TESTWTODEPENDENTPROPERTIESERRORWHENWTOUNSET  No silent NaN.
        %   Phase-1e/1f precedent: a Dependent that needs a gross weight must
        %   ERROR with an identified message rather than return NaN. The five
        %   asserted here all genuinely carry W_dg (or W_l = 0.95*W_TO).
        %   W_installed_engine is deliberately NOT asserted either way: its
        %   equations (Eqs. 15.7-15.15) do not use W_TO at all, so whether it
        %   should be guarded is the same open question flagged at L2 by
        %   TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO. Asserting
        %   the current behaviour here would freeze that question shut.
            w = TestWeightsL3.makeW3();
            tc.verifyTrue(isnan(w.W_TO), 'Precondition: W_TO unset.');
            tc.verifyError(@() w.W_l, 'F16WeightsL3:WTONotSet', ...
                'W_l = 0.95*W_TO must error on unset W_TO, not return NaN.');
            tc.verifyError(@() w.W_wings, 'F16WeightsL3:WTONotSet', ...
                'W_wings (Eq. 15.1, carries W_dg) must error on unset W_TO.');
            tc.verifyError(@() w.W_tail, 'F16WeightsL3:WTONotSet', ...
                'W_tail (Eqs. 15.2/15.3, carry W_dg) must error on unset W_TO.');
            tc.verifyError(@() w.W_fuselage, 'F16WeightsL3:WTONotSet', ...
                'W_fuselage (Eq. 15.4, carries W_dg) must error on unset W_TO.');
            tc.verifyError(@() w.W_subsystems, 'F16WeightsL3:WTONotSet', ...
                'W_subsystems (Eq. 15.24 carries W_dg) must error on unset W_TO.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
        %TESTDERIVEDPROPERTIESAREREADONLY  Derived quantities are OUTPUTS.
        %   None of the 31 has a set-method, so assignment must error
        %   MATLAB:class:noSetMethod -- nothing can overwrite a live-computed
        %   value with a frozen literal, which is the anti-pattern Phase 4
        %   removed. setfield is used because a property assignment cannot
        %   appear inside an anonymous function. The list is metaclass-derived,
        %   so a newly added Dependent is covered automatically.
            w     = TestWeightsL3.makeW3();
            names = TestWeightsL3.dependentNames();
            cellfun(@(n) tc.verifyError(@() setfield(w, n, 0), ...
                'MATLAB:class:noSetMethod', ...
                sprintf('Dependent property %s must be read-only.', n)), names);
            % Spot-check the quantities that were FROZEN literals before Phase 4.
            tc.verifyError(@() setfield(w, 'W_l',     20681), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'T_max',   23770), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'W_en',     3030), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'S_ht',    49.85), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'D_fus',     6.0), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'SFC_mission', 0.70), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testDerivedLiveRecomputeOnMutation(tc)
        %TESTDERIVEDLIVERECOMPUTEONMUTATION  The finding-#11 regression guard.
        %   The sizing loop mutates design variables in place and expects
        %   updated outputs on the next read, with NO reconstruction. Three
        %   independent paths: injected geometry, injected engine, requirement.
            [w, geom, prop] = TestWeightsL3.makeW3();
            w.W_TO = 31377;

            % (a) geometry DI: HT span up -> exposed HT area up -> Eq. 15.2 up.
            S_ht_before = w.S_ht;
            HT_before   = w.W_tail.HT;
            geom.B_h    = 20;
            tc.verifyGreaterThan(w.S_ht, S_ht_before, ...
                'S_ht must track geom.B_h live (geometry DI).');
            tc.verifyGreaterThan(w.W_tail.HT, HT_before, ...
                'W_tail.HT must track the geometry change live -- no cached copy.');

            % (b) propulsion DI: thrust up -> T_max, Eq. 10.10 W_en, and the
            %     engine group (mounts Eq. 15.7 + starter Eq. 15.15) all up.
            W_en_before  = w.W_en;
            grp_before   = w.W_installed_engine;
            prop.T_SL    = 30000;
            tc.verifyEqual(w.T_max, 30000, 'AbsTol', 1e-9, ...
                'T_max must track prop.T_SL live.');
            tc.verifyGreaterThan(w.W_en, W_en_before, ...
                'W_en must track prop.T_SL live (Eq. 10.10 T^1.1).');
            tc.verifyGreaterThan(w.W_installed_engine, grp_before, ...
                'The engine group must track thrust live through Eqs. 15.7/15.9/15.15.');

            % (c) requirement: design Mach up -> Eq. 10.10 M^0.25 and
            %     Eq. 15.3 M^0.341 both up.
            W_en_at_M20 = w.W_en;
            VT_at_M20   = w.W_tail.VT;
            w.design_mach = 2.05;
            tc.verifyGreaterThan(w.W_en, W_en_at_M20, ...
                'W_en must track design_mach live (Eq. 10.10 M^0.25).');
            tc.verifyGreaterThan(w.W_tail.VT, VT_at_M20, ...
                'W_tail.VT must track design_mach live (Eq. 15.3 M^0.341).');
        end

    end

    % ------------------------------------------------------------------ %
    % Component sanity bounds (kept from the pre-Phase-4 suite, RE-BASED)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testComponentSanityBounds(tc)
        %TESTCOMPONENTSANITYBOUNDS  Wide engineering bounds, no external target.
        %   Retained from the pre-Phase-4 suite (F16WeightsL3.md Sec. F: "keep
        %   the bound form, re-base the numbers"). Every Brandt comparison
        %   figure that used to appear in these docstrings (1852 / 199.39 /
        %   245.34 / 3652 / 1066.8) has moved to the comparison report; the
        %   bounds themselves are physical plausibility, not agreement.
        %   Re-based values at W_TO = 31377: wing 2396.94, HT 200.54, VT 313.06,
        %   fuselage 3674.20, LG total 1160.93.
            w = TestWeightsL3.makeW3();
            W_TO  = 31377;
            W_t   = w.weight_tail(W_TO);
            tc.verifyGreaterThan(w.weight_wing(W_TO), 2000, ...
                'Wing weight must exceed 2,000 lbf for a 9g-capable fighter wing.');
            tc.verifyLessThan(w.weight_wing(W_TO), 6000, ...
                'Wing weight must be below 6,000 lbf.');
            tc.verifyGreaterThan(W_t.HT, 100, 'HT weight must exceed 100 lbf.');
            tc.verifyLessThan(W_t.HT, 2000, 'HT weight must be below 2,000 lbf.');
            tc.verifyGreaterThan(W_t.VT, 200, 'VT weight must exceed 200 lbf.');
            tc.verifyLessThan(W_t.VT, 1500, 'VT weight must be below 1,500 lbf.');
            tc.verifyGreaterThan(w.weight_fuselage(W_TO), 3000, ...
                'Fuselage weight must exceed 3,000 lbf.');
            tc.verifyLessThan(w.weight_fuselage(W_TO), 10000, ...
                'Fuselage weight must be below 10,000 lbf.');
            tc.verifyGreaterThan(TestWeightsL3.gearTotal(w, W_TO), 800, ...
                'Total LG weight must exceed 800 lbf.');
            tc.verifyLessThan(TestWeightsL3.gearTotal(w, W_TO), 3000, ...
                'Total LG weight must be below 3,000 lbf.');
            tc.verifyLessThan(W_t.HT, w.weight_wing(W_TO), ...
                'The horizontal tail must weigh less than the wing.');
            tc.verifyLessThan(W_t.VT, w.weight_wing(W_TO), ...
                'The vertical tail must weigh less than the wing.');
        end

    end

    % ------------------------------------------------------------------ %
    % DELIBERATELY-FAILING TODO (unverified exponents) -- EXPECTED RED
    % ------------------------------------------------------------------ %

    methods (Test)

        function testTODO_Raymer1531ExponentsNotBookVerified(tc)
        %TESTTODO_RAYMER1531EXPONENTSNOTBOOKVERIFIED  Deliberate, EXPECTED red.
        %
        %   THIS TEST IS EXPECTED TO BE RED. It is not a regression; it is the
        %   labelled marker for an open citation checklist, following the
        %   convention of TestGeomL3.testTODO_OverallLengthCitationNotPinned.
        %   WeightsL3.m's own header names this test as its guard.
        %
        %   WHAT IS MISSING: every Raymer Sec. 15.3.1 exponent in WeightsL3 is
        %   UNVERIFIED against the printed book. VnV/BrandtF16A/todo.md
        %   2026-07-24 Sec. 3a is a 62-row checklist:
        %     CONFLICT (2)    code disagrees with the repo extract, and the CODE
        %                     value is KEPT by locked decision -- Eq. 15.13
        %                     N_en^1.023 (extract 1.078) and Eq. 15.3
        %                     cos(Lambda_vt)^-0.323 (extract -1.0). At N_en = 1
        %                     the first is numerically invisible on the F-16A.
        %     FROM-CODE (9)   absent from the extract entirely; the value comes
        %                     from this project's prior WeightLevel3.m, not the
        %                     book -- Eq. 15.10 N_en^1.498, (L_s/L_d)^-0.373 and
        %                     the linear D_e; Eq. 15.14 N_en^1.008, L_ec^0.222;
        %                     Eq. 15.17 N_c^0.127; Eq. 15.5 L_m^0.973;
        %                     Eq. 15.6 N_nw^0.525.
        %     VERIFY (24)     present in raymer_data.md but OCR-flagged.
        %     IMAGE-ONLY (27) Eqs. 15.1-15.7; no equation-page image exists in
        %                     this repo, so a former claim that they had been
        %                     "re-verified letter-for-letter" was not checkable
        %                     and has been withdrawn.
        %   Plus two Eq. 15.1 specifics: tc_root^-0.4's superscript is illegible
        %   in the printed line-wrap, and the sweep STATION (LE vs quarter-chord)
        %   is unresolved.
        %
        %   The hand-computed tests above verify that the code EVALUATES the
        %   equations it documents. They cannot verify that the documented
        %   exponents are the book's -- that is exactly this gap, and it must not
        %   be papered over by a passing arithmetic test.
        %
        %   HOW THIS TEST DETECTS IT: WeightsL3.m's header states, in words,
        %   that every exponent is unverified against the book. While that
        %   statement stands the checklist is open and this test is red.
        %
        %   HOW TO RESOLVE: work todo.md 2026-07-24 Sec. 3a against the printed
        %   Raymer 7th ed. Sec. 15.3.1, record the verification, then rewrite
        %   WeightsL3.m's header. Do NOT change any exponent VALUE to make this
        %   green (the two CONFLICTs are locked at their code values), and do NOT
        %   delete the header statement without doing the verification.
            src = fileread(which('WeightsL3'));
            tc.verifyFalse(contains(src, 'EXPONENT IS UNVERIFIED AGAINST THE BOOK'), ...
                ['TODO (EXPECTED RED): every Raymer Sec. 15.3.1 exponent in ' ...
                 'WeightsL3 is unverified against the printed book -- ' ...
                 'VnV/BrandtF16A/todo.md 2026-07-24 Sec. 3a, 62 rows, is open.']);
        end

    end

    % ------------------------------------------------------------------ %
    % Fixture / sweep helpers
    % ------------------------------------------------------------------ %

    methods (Static, Access = private)

        function [w, geom, prop] = makeW3()
        %MAKEW3  Build a FRESH F-16A L3 weights object plus its collaborators.
        %   Fresh geometry and propulsion objects every call: both are handle
        %   classes and the mutation tests change them in place.
        %   ! geom is F16GeomL3 (the full L3 geometry tier) and prop is
        %   F16PropL2 -- there is no L3 propulsion tier.
            prop = TestWeightsL3.makeProp();
            geom = F16GeomL3(f16a_spec_path(3), prop);
            w    = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), geom, prop);
        end

        function p = makeProp()
            p = F16PropL2(f16a_spec_path(2));
        end

        function t = gearTotal(w, W_TO)
        %GEARTOTAL  Eqs. 15.5 + 15.6 summed at the given gross weight.
            W_lg = w.weight_landing_gear(W_TO);
            t    = W_lg.main + W_lg.nose;
        end

        function names = dependentNames()
        %DEPENDENTNAMES  Metaclass-derived list of the Dependent properties.
        %   Derived rather than hardcoded so a newly added Dependent is swept
        %   automatically instead of silently escaping the guards.
            mc    = ?F16WeightsL3;
            pl    = mc.PropertyList;
            names = {pl([pl.Dependent]).Name};
        end

        function vals = flattenDependents(w)
        %FLATTENDEPENDENTS  Every Dependent read, structs expanded to scalars.
            names = TestWeightsL3.dependentNames();
            cells = cellfun(@(n) TestWeightsL3.flatten(w.(n)), names, ...
                'UniformOutput', false);
            vals  = [cells{:}];
        end

        function v = flatten(x)
        %FLATTEN  Numeric row vector from a scalar or a struct of scalars.
        %   The branch lives here, in a helper, so the test methods themselves
        %   stay free of control flow.
            if isstruct(x)
                v = reshape(cell2mat(struct2cell(x)), 1, []);
            else
                v = reshape(x, 1, []);
            end
        end

        function v = structValues(s)
        %STRUCTVALUES  All numeric fields of a weight-group struct, as a row.
            v = reshape(cell2mat(struct2cell(s)), 1, []);
        end

    end

end

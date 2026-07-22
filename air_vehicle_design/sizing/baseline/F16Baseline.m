function b = F16Baseline()
%F16BASELINE  Authoritative ground-truth data for the F-16A Block 10 example.
%
%   b = F16Baseline() returns a struct of cited inputs and expected truth
%   outputs used to seed unit tests at all three fidelity levels.
%
%   SOURCES:
%     [Brandt]    S. Brandt, "Introduction to Aeronautics: A Design
%                 Perspective", Jet Designer / Jet3 workbook (Brandt F-16A.xls).
%                 Extracted via extract_brandt.m.
%     [Raymer]    D.P. Raymer, "Aircraft Design: A Conceptual Approach",
%                 6th ed., AIAA, 2018.
%     [Mattingly] J.D. Mattingly, "Aircraft Engine Design", 2nd ed., AIAA, 2002.
%     [TO]        T.O. 1F-16A-1, Flight Manual, USAF/EPAF F-16A/B Blocks 10/15.
%   All values in English units: lbf, ft, slug/ft^3, ft/s, deg R.

b = struct();

% =========================================================================
%  1. Wing geometry  [TO, Fig. 1-2]
% =========================================================================
b.geom.S_ref           = 300;       % ft^2  -- trapezoidal wing reference area
b.geom.b               = 30;        % ft    -- wing span (w/o missiles)
b.geom.AR              = 3.0;       % --    -- aspect ratio
b.geom.taper           = 0.2275;    % --    -- taper ratio lambda
b.geom.sweep_LE_deg    = 40;        % deg   -- leading-edge sweep
b.geom.dihedral_deg    = 0;
b.geom.incidence_deg   = 0;
b.geom.airfoil         = 'NACA 64A204';
b.geom.tc_root         = 0.04;
b.geom.tc_avg          = 0.04;
b.geom.S_ht            = 63.70;     % ft^2  -- horizontal tail, Block 10
b.geom.AR_ht           = 2.114;
b.geom.b_ht            = 18.5;      % ft    -- HT full span = 18 ft 6 in
                                     %         [USAF 3-view diagram, "18 FT 6 IN" span callout]
                                     %         NOTE: inconsistent with sqrt(AR_ht*S_ht) = 11.61 ft
                                     %         using the AR_ht/S_ht pair above -- not reconciled
                                     %         here; flagged for follow-up, not used elsewhere yet
                                     %         (F16GeomL2/L3's own b_HT=17.5 estimate and
                                     %         F16WeightsL3's derived B_h=11.61 are unchanged).
b.geom.taper_ht        = 0.390;
b.geom.sweep_LE_ht_deg = 40;
b.geom.dihedral_ht_deg = -10;       % deg   -- anhedral
b.geom.S_vt            = 54.75;     % ft^2
b.geom.AR_vt           = 1.294;
b.geom.taper_vt        = 0.437;
b.geom.sweep_LE_vt_deg = 47.5;
b.geom.L_fus           = 47.50;     % ft    -- overall length (excl. probe)
b.geom.W_fus           = 7.0;       % ft    -- approx max width

% Exposed lifting-surface planform areas [Brandt F-16A.xls, "Geom" sheet,
% "Exposed Lifting Surf Geometry" table, "Exposed S" column]. Raymer's
% S_w/S_ht/S_vt in the Table 15.2 and Eq. 15.1-15.3 weight buildups are the
% exposed (fuselage-excluded) planform areas, not the full trapezoidal
% reference area -- WeightsL2/WeightsL3 (via F16WeightsL2/F16WeightsL3) use
% these values, not b.geom.S_ref/S_ht/S_vt above.
b.geom.S_exposed_wing   = 196.23;   % ft^2  -- "Wing" row       [Brandt Geom sheet]
b.geom.S_exposed_ht     = 49.85;    % ft^2  -- "Pitch Control Surface" row [Brandt Geom sheet]
b.geom.S_exposed_strake = 20.00;    % ft^2  -- "Strake" row     [Brandt Geom sheet] (not modeled: no strake weight component in this framework)
b.geom.S_exposed_vt     = 40.89;    % ft^2  -- "Vertical Tail" row [Brandt Geom sheet]

% =========================================================================
%  2. Weights  [Brandt F-16A.xls, sheet "Wt"]
% =========================================================================
b.brandt.TOGW      = 31377.0;  % lbf  -- "Total @ Takeoff"   [Brandt B38]
b.brandt.OEW       = 19148;    % lbf  -- "Empty"             [Brandt B12]
b.brandt.W_fuel    = 6296.3;   % lbf  -- internal fuel        [Brandt B6]
b.brandt.W_landing = 20680.7;  % lbf  -- "Total for Lndg"    [Brandt B41]
b.brandt.W_perm_pay = 700;     % lbf  -- permanent payload    [Brandt B32]
b.brandt.W_exp_pay  = 4400;    % lbf  -- expendable payload   [Brandt B33+B34]

% Component-level Group Weight Statement [Brandt F-16A.xls, "Wt" sheet,
% rows 16-31]. b.brandt.W_wing/W_fuselage/W_pitch_cntrl/W_vert/W_nacelles/
% W_strakes below are now Brandt's "Structural Weight Models, average psf"
% table results (a separate psf-coefficient x area model calculation,
% analogous to this framework's own WeightsL2 method) -- NOT the raw Wt!B16-
% B21 Group Weight Statement cells previously used here. As a result these
% 6 values no longer sum with the remaining Wt!B22-B31 items below to
% b.brandt.OEW (19,148 lbf); that cross-check applied only to the
% superseded Wt!B16-B21 figures and is not expected to hold for this model
% table.
% "Brandt corrected" psf coefficients (upper row of Brandt's "Structural
% Weight Models, average psf" table) -- Brandt's own per-component unit
% weights, NOT the Raymer Table 15.2 fighter coefficients this framework's
% WeightsL2 actually uses (wing=9.0, HT=4.0, VT=5.3, fus=4.8 lbf/ft^2, per
% F16WeightsL2/WeightsL2.wing_unit_weight et al.). Fuselage and HT happen to
% coincide (4.8=4.8, 4.0=4.0); wing and VT do not (7.0 vs 9.0, 6.0 vs 5.3).
% Nacelles/Strakes have no Raymer Table 15.2 analog in this framework.
b.brandt.rho_wing_model    = 7.0;   % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; Raymer Table 15.2 fighter wing = 9.0 lbf/ft^2 (differs)
b.brandt.rho_fus_model     = 4.8;   % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; matches Raymer Table 15.2 fighter fuselage = 4.8 lbf/ft^2
b.brandt.rho_pitch_cntrl_model = 4.0;  % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; matches Raymer Table 15.2 fighter HT = 4.0 lbf/ft^2
b.brandt.rho_vert_model    = 6.0;   % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; Raymer Table 15.2 fighter VT = 5.3 lbf/ft^2 (differs)
b.brandt.rho_nacelles_model = 4.5;  % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; no Raymer Table 15.2 analog
b.brandt.rho_strakes_model = 4.5;   % lbf/ft^2  -- "Brandt corrected" coeff [Brandt "Structural Weight Models, average psf" table]; no Raymer Table 15.2 analog
b.brandt.W_wing        = 1852.09302;  % lbf  -- wing structure           [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 7.0 lbf/ft^2 coeff above, not Raymer Table 15.2's 9.0]
b.brandt.W_fuselage    = 3506.0256;   % lbf  -- fuselage structure       [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 4.8 lbf/ft^2 coeff above]
b.brandt.W_pitch_cntrl = 199.389002;  % lbf  -- horizontal tail/stabilator [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 4.0 lbf/ft^2 coeff above]
b.brandt.W_vert        = 245.3380129; % lbf  -- vertical tail            [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 6.0 lbf/ft^2 coeff above, not Raymer Table 15.2's 5.3]
b.brandt.W_nacelles    = 186.817478;  % lbf  -- engine nacelles          [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 4.5 lbf/ft^2 coeff above]
b.brandt.W_strakes     = 90;          % lbf  -- LEX/strakes (not modeled in this framework) [Brandt "Structural Weight Models, average psf" table, using the "Brandt corrected" 4.5 lbf/ft^2 coeff above]
b.brandt.W_engine      = 4730.23;   % lbf  -- bare/dry engine          [Brandt Wt!B22]
b.brandt.W_gear        = 1066.818;  % lbf  -- landing gear             [Brandt Wt!B23]
b.brandt.W_inlet_duct  = 728.5882;  % lbf  -- inlet duct               [Brandt Wt!B24]
b.brandt.W_controls    = 472.4354;  % lbf  -- flight controls system   [Brandt Wt!B25]
b.brandt.W_electrical  = 533.409;   % lbf  -- electrical system        [Brandt Wt!B26]
b.brandt.W_hydraulics  = 367.1109;  % lbf  -- hydraulics system        [Brandt Wt!B27]
b.brandt.W_ecs         = 360.8355;  % lbf  -- environmental control system [Brandt Wt!B28]
b.brandt.W_other       = 2016.862;  % lbf  -- other/misc systems       [Brandt Wt!B29]
b.brandt.W_avionics    = 2541.537;  % lbf  -- avionics                 [Brandt Wt!B30]
b.brandt.W_armament    = 440;       % lbf  -- fixed armament (gun)     [Brandt Wt!B31]

b.sizing.TOGW_target = 31377;  % lbf  [Brandt]
% TODO (7/22/2026): Consider replacing with Brandt's "sizing" value (around
% 29k lbf)
b.sizing.TOGW_tol    = 2000;   % lbf  -- acceptable +-band
b.sizing.OEW_frac    = b.brandt.OEW  / b.brandt.TOGW;   % approx 0.6103
b.sizing.Wf_frac     = b.brandt.W_fuel / b.brandt.TOGW; % approx 0.2006

% =========================================================================
%  3. Engine  [Brandt, sheet "Main" rows 29-30; TO Section I]
% =========================================================================
b.engine.name     = 'F100-PW-200';
b.engine.T_mil    = 15000;   % lbf  -- military (dry) SLS thrust  [Brandt C29]
b.engine.T_max    = 23770;   % lbf  -- maximum (AB) SLS thrust    [Brandt D29]
b.engine.TSFC_mil = 0.70;    % 1/h  -- SLS static mil TSFC        [Brandt C30]
b.engine.TSFC_max = 2.20;    % 1/h  -- SLS static AB TSFC         [Brandt D30]
b.engine.TR       = 1.00;    % --   -- Brandt [Need source] TODO (7/15/2026): Add source. Don't hallucinate it.
                              %         F-16 computed TR = 1.0; see F16PropL2/L3.TR.

% Mattingly TSFC coefficients: TSFC = (C1 + C2*M)*sqrt(theta)  [Mattingly Eq. 3.12, 3.55]
b.engine.C1_mil = 0.90;   % [Mattingly Eq. 3.55a]
b.engine.C2_mil = 0.30;   % [Mattingly Eq. 3.55a]
b.engine.C1_AB  = 1.60;   % [Mattingly Eq. 3.55b]
b.engine.C2_AB  = 0.27;   % [Mattingly Eq. 3.55b]

% Raymer Table 3.3 categorical TSFC — low-bypass turbofan with AB  [Raymer 6th ed., Table 3.3]
%   cruise (M >= 0.4): 0.80 1/hr
%   loiter (M <  0.4): 0.70 1/hr
%   AB operation not listed in Table 3.3 (combat-specific; use Brandt TSFC_max at SLS).
b.engine.TSFC_cruise_raymer = 0.80;   % 1/hr  [Raymer 6th ed., Table 3.3, low-BPR turbofan]
b.engine.TSFC_loiter_raymer = 0.70;   % 1/hr  [Raymer 6th ed., Table 3.3, low-BPR turbofan]

% Mattingly Eq. 2.54 thrust lapse identities at SLS M=0
%   d0=1, t0=1 <= TR -> alpha_AB=d0=1.0; alpha_mil=0.6*d0=0.6
b.engine.val.alpha_AB_SLS  = 1.0;
b.engine.val.alpha_dry_SLS = 0.6;

% Brandt Consts rows 32-33 (Takeoff/Landing labelled but V implies M~1.2 -- apparent error)
b.engine.val.brandt_alpha_mach_SLS    = 1.2;
b.engine.val.brandt_alpha_AB_SLS_M12  = 0.955053;  % col AT rows 32-33 [Brandt Consts]
b.engine.val.brandt_alpha_dry_SLS_M12 = 0.939778;  % col AS rows 32-33 [Brandt Consts]

% Mattingly Part 12 hot-day and 30 kft reference points
b.engine.val.part12_hot_theta0 = 1.0796;  % theta_0 at 2 kft hot day M=0
b.engine.val.part12_hot_delta0 = 0.9298;
b.engine.val.part12_30k_theta  = 0.7940;  % theta at 30 kft standard day
b.engine.val.part12_30k_delta  = 0.2975;

% Approx validation point at cruise (legacy; see b.constraints.cruise for authoritative values)
b.engine.val.alt_ft           = 36000;
b.engine.val.mach             = 0.87;
b.engine.val.alpha_mil_approx = 0.34;   % Brandt Consts AS24 (alpha_dry, T_SL_dry basis)

% F100-PW-100 real-world data  [Mattingly AED 2nd ed., Table C.4, p. 522]
b.engine.F100PW100.T_max    = 23700;  % lbf   [Table C.4]
b.engine.F100PW100.BPR      = 0.69;
b.engine.F100PW100.W_dot    = 224;    % lbm/s
b.engine.F100PW100.T_t4_max = 2566;   % deg F
b.engine.F100PW100.P_t2     = 13.1;   % psia
b.engine.F100PW100.T_t2     = 59;     % deg F

% =========================================================================
%  4. Aerodynamics -- Brandt MODEL polar  [Brandt, sheet "Aero" A6:E10]
%     Columns: [Mach  CDmin  CD0  K1  K2]  -- L1/L2 assertion target.
% =========================================================================
b.brandt.polar_model = [
    0.1000,  0.01691,  0.01700,  0.1160,  -0.0066;
    0.8727,  0.01691,  0.01700,  0.1160,  -0.0066;
    1.0547,  0.04558,  0.04568,  0.1277,  -0.0047;
    1.5000,  0.04128,  0.03994,  0.2516,   0.0000;
    2.0000,  0.04128,  0.03732,  0.3670,   0.0000;
];

% =========================================================================
%  5. Aerodynamics -- F-16 ACTUAL polar  [Brandt, sheet "Aero" M6:Q10]
%     M=0.02 row is a Brandt spreadsheet artifact -- skip in tests.
% =========================================================================
b.brandt.polar_actual = [
    0.0200,  0.1970,  0.1970,  0.1220,  -0.0070;   % artifact
    0.8750,  0.0205,  0.0205,  0.1280,  -0.0070;
    1.0500,  0.0444,  0.0444,  0.2100,  -0.0030;
    1.6000,  0.0461,  0.0461,  0.3400,   0.0000;
    2.0000,  0.0458,  0.0458,  0.3800,   0.0000;
];

% =========================================================================
%  6. Aerodynamics -- Raymer Fig 12.32 transonic CD0  [Raymer, Fig. 12.32, 6th ed.]
%     L3 assertion target.
% =========================================================================
b.raymer.CD0_mach = [0.50, 1.00, 1.50];
b.raymer.CD0      = [0.020, 0.035, 0.047];

% =========================================================================
%  7. Additional aero parameters  [Brandt, sheet "Main"]
% =========================================================================
b.brandt.S_wet       = 1371.09;  % ft^2  [Brandt L3]
b.brandt.Mcrit       = 0.8727;   %       [Brandt L4]

% --- Component wetted areas [Brandt F-16A.xls, "Geom" sheet] -------------
%   Brandt builds the B19 "Whole Aircraft Swet" total from 7 terms, not 5:
%     fus_accurate(D23) + nacelle(B4) + wing(B14) + strake(B15) + HT(B16)
%     + VT(B17) + flaps(K21=40) = 676.329+41.515+392.020+39.956+99.585
%     +81.689+40.0 = 1371.095 ft^2, matching B19 to 1e-6.
%   Strake and flaps have no analog in this framework's 5-component
%   (wing/HT/VT/fuselage/duct) breakdown -- their ~80 ft^2 combined
%   contribution is a known, documented gap when comparing component sums.
%   Also note: Brandt's "exposed" HT/VT areas (B8=49.85, B10=40.89, the
%   portion outside the fuselage; same values as b.geom.S_exposed_ht/vt
%   above) differ from the GEOMETRY discipline's own S_exposed_HT/S_exposed_VT
%   inputs (F16GeomL2/F16GeomL3 properties, 63.70/54.75, full T.O. reference
%   planform area) used for wetted-area (S_wet) computation -- a separate,
%   pre-existing input-data discrepancy, not fixed here. (The WEIGHTS
%   discipline's analogous S_ht/S_vt inputs, used in Raymer Table 15.2 /
%   Eq. 15.1-15.3, DO use these correct exposed values -- see F16WeightsL2/
%   F16WeightsL3 and b.geom.S_exposed_ht/vt above.)
b.brandt.S_wet_wing     = 392.020;  % ft^2  [Brandt Geom!B14] "Exposed Wing Wetted Area"
b.brandt.S_wet_HT       = 99.585;   % ft^2  [Brandt Geom!B16] "Exposed Pitch Trim Surface Wetted Area"
b.brandt.S_wet_VT       = 81.689;   % ft^2  [Brandt Geom!B17] "Exposed Vertical Tail Wetted Area"
b.brandt.S_wet_fus      = 730.422;  % ft^2  [Brandt Geom!B3]  1/3-cone + 2/3-cylinder approx
b.brandt.S_wet_fus_alt  = 676.329;  % ft^2  [Brandt Geom!D23] "More Accurate Fuselage Swet" (used in B19 total)
b.brandt.S_wet_duct     = 41.515;   % ft^2  [Brandt Geom!B4]  "Exposed Engine Nacelles", full-cylinder approx
b.brandt.S_wet_strake   = 39.956;   % ft^2  [Brandt Geom!B15] not modeled in this framework
b.brandt.S_wet_flaps    = 40.0;     % ft^2  [Brandt Geom!K21] not modeled in this framework
b.brandt.CL_alpha      = 0.0615;         % 1/deg [Brandt L7] — total aircraft (includes strake)
b.brandt.CL_alpha_wing = 0.054312 * 57.3; % /rad  [Brandt Aero!A15] — main wing only
b.brandt.CLmax_clean = 0.9869;   %       [Brandt L8]
b.brandt.CLmax_TO    = 1.2785;   %       [Brandt L9]
b.brandt.CLmax_land  = 1.4288;   %       [Brandt L10]
b.brandt.CLmax_a2a   = 1.1316;   %       [Brandt L11]
b.brandt.Cfe_used    = 0.0037;   %       [Brandt O1]

% =========================================================================
%  8. Constraint design point  [Brandt, sheet "Main" P13; derived]
% =========================================================================
b.constraint.WS_opt = 104.59;                          % lbf/ft^2 [Brandt P13]
b.constraint.TW_opt = b.engine.T_max / b.brandt.TOGW;  % approx 0.7576
b.constraint.WS_tol = 5;     % lbf/ft^2
b.constraint.TW_tol = 0.02;

% =========================================================================
%  9. Standard-atmosphere reference values  [Mattingly Appendix B]
% =========================================================================
b.atm.T_std   = 518.67;   % deg R
b.atm.P_std   = 2116.22;  % lbf/ft^2
b.atm.rho_std = 0.002377; % slug/ft^3
b.atm.a_std   = 1116.45;  % ft/s

% =========================================================================
%  10. Brandt engine model  [Brandt F-16A.xls, "Engn(s)" sheet]
%
%  Brandt uses a generalized Mattingly thrust lapse with a Mach correction
%  below TR -- different from Mattingly AED Eq. 2.54 (which PropL2 implements).
%
%  Dry lapse [Engn(s) row 4]:
%    theta0 <= TR:  alpha_dry = delta_0*(1 - C_M_dry*M^e_M_dry)
%    theta0 >  TR:  alpha_dry = delta_0*(1 - C_M_dry*M^e_M_dry - C_TR_dry*(theta0-TR)/theta0)
%  AB lapse [Engn(s) row 15]:
%    theta0 <= TR:  alpha_AB  = delta_0*(1 - C_M_AB*M^e_M_AB)
%    theta0 >  TR:  alpha_AB  = delta_0*(1 - C_M_AB*M^e_M_AB  - C_TR_AB*(theta0-TR)/theta0)
%
%  Normalization:
%    alpha_dry by T_SL_dry (= T_mil = 15,000 lbf): alpha_dry = 1.0 at SLS M=0
%    alpha_AB  by T_SL_AB  (= T_max = 23,770 lbf): alpha_AB  = 1.0 at SLS M=0
%    Mattingly alpha_mil by T_SL_AB:                alpha_mil = 0.6 at SLS M=0
%
%  TSFC dry  [Engn(s) row 7]:  TSFCdry = TSFC_sl_dry*(1+0.35*M)*(T/TSL_dry)^0.5
%  TSFC AB  [Engn(s) row 19]:  TSFCAB  = TSFC_sl_AB*(1+0.35*|M-0.4|)*(T/TSL_AB)^0.5
%  At full throttle (T/TSL=1): no altitude/temperature correction (unlike Mattingly sqrt(theta)).
% =========================================================================
b.brandt_engine.TR       = 1.0;   % throttle ratio  [Engn(s) S1]
b.brandt_engine.C_M_dry  = 0.3;   % Mach coeff, dry  [Engn(s) D4]
b.brandt_engine.e_M_dry  = 1.0;   % Mach exponent    [Engn(s) F4]
b.brandt_engine.C_TR_dry = 1.7;   % theta coeff, dry [Engn(s) R4]
b.brandt_engine.C_M_AB   = 0.1;   % Mach coeff, AB   [Engn(s) D15]
b.brandt_engine.e_M_AB   = 0.5;   % Mach exponent    [Engn(s) F15]
b.brandt_engine.C_TR_AB  = 2.2;   % theta coeff, AB  [Engn(s) R15]

% =========================================================================
%  11. Constraint-condition reference values  [Brandt F-16A.xls, "Consts" sheet]
%
%  Data from Consts columns AI-AL (theta, theta0, delta, delta0) and
%  AS (alpha_dry) / AT (alpha_AB).  Normalization: see section 10.
%
%  IMPORTANT: Brandt formula != Mattingly Eq. 2.54.  Direct alpha comparison
%  without accounting for formula and normalization differences is misleading.
%  Tests assert PropL2 matches Mattingly; Brandt values are reported as reference.
%
%  CD0/K1/K2 below are Brandt's own drag-polar coefficients evaluated at each
%  constraint condition [Brandt Consts sheet, CDo/k1/k2 columns immediately
%  following theta/theta0/delta/delta0 -- exact column letters not confirmed
%  from the source screenshot, unlike the AI-AL/AS/AT/AU columns above].
%  cruise/combat_sub/max_alt/ps all sit at M~=0.87 and share CD0/K1/K2 with
%  b.brandt.polar_model row 2 (M=0.8727) to within rounding; dash (M=1.6) and
%  combat_sup (M=1.4) do not match polar_model's M=1.5/2.0 rows -- Brandt
%  appears to evaluate/interpolate the polar independently per condition
%  rather than reading it off the 5-point Aero-sheet table, so these are
%  recorded as-given rather than reconciled against polar_model.
% =========================================================================

% [A] Cruise  36,000 ft, M=0.87, n=1, no AB  [Consts row 24]
b.constraints.cruise.alt_ft         = 36000;
b.constraints.cruise.mach           = 0.87;
b.constraints.cruise.theta          = 0.752916;  % AI24
b.constraints.cruise.theta_0        = 0.866892;  % AJ24
b.constraints.cruise.delta          = 0.223993;  % AK24
b.constraints.cruise.delta_0        = 0.366860;  % AL24
b.constraints.cruise.alpha_dry      = 0.271110;  % AS24  T_dry/T_SL_dry   [Brandt Engn(s)]
b.constraints.cruise.alpha_AB       = 0.332642;  % AT24  T_AB/T_SL_AB     [Brandt Engn(s)]
b.constraints.cruise.alpha_mil_T_AB = 0.171083;  % AU24  alpha_dry*(T_SL_dry/T_SL_AB)  [Brandt Consts col AU]
b.constraints.cruise.CD0            = 0.01700;   % Consts row 24 [Brandt Consts sheet]
b.constraints.cruise.K1             = 0.11603;   % Consts row 24
b.constraints.cruise.K2             = -0.0066;   % Consts row 24

% Full Cruise constraint-diagram row [Brandt F-16A.xls Consts sheet]: the
% required T_SL/W_TO Brandt's own model produces at each of 21 W_TO/S sweep
% points. Validation target for ThrustConstraint's Master-Equation assembly
% (see tests/constraints/TestThrustConstraint.m testF16CruiseRequiredTWTable)
% -- NOT an input to the equation itself. Same WS_psf sweep as
% b.constraints.dash.WS_psf (Brandt's Consts sheet uses one shared W_TO/S
% column for every condition row).
b.constraints.cruise.WS_psf   = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.cruise.TW_Cruise = [1.29179, 0.98352, 0.80848, 0.69843, 0.62495, ...
                                  0.57406, 0.53812, 0.51258, 0.49456, 0.48216, ...
                                  0.47407, 0.46935, 0.46733, 0.46750, 0.46946, ...
                                  0.47291, 0.47762, 0.48340, 0.49009, 0.49757, ...
                                  0.50573];   % [Brandt Consts sheet, Cruise row]

% [B] 1st combat turn (subsonic)  20,000 ft, M=0.87, n=4.5, AB  [Consts row 26]
b.constraints.combat_sub.alt_ft         = 20000;
b.constraints.combat_sub.mach           = 0.87;
b.constraints.combat_sub.n              = 4.5;
b.constraints.combat_sub.theta          = 0.862731;  % AI26
b.constraints.combat_sub.theta_0        = 0.993331;  % AJ26
b.constraints.combat_sub.delta          = 0.459093;  % AK26
b.constraints.combat_sub.delta_0        = 0.751910;  % AL26
b.constraints.combat_sub.alpha_dry      = 0.555662;  % AS26
b.constraints.combat_sub.alpha_AB       = 0.681777;  % AT26
b.constraints.combat_sub.alpha_mil_T_AB = 0.350649;  % AS26*(T_SL_dry/T_SL_AB)
b.constraints.combat_sub.CD0            = 0.01700;   % Consts row 26 [Brandt Consts sheet]
b.constraints.combat_sub.K1             = 0.11603;   % Consts row 26
b.constraints.combat_sub.K2             = -0.0066;   % Consts row 26

% Full Combat Turn 1 (subsonic) constraint-diagram row [Brandt F-16A.xls
% Consts sheet, row 26]: the required T_SL/W_TO Brandt's own model produces
% at each of 21 W_TO/S sweep points. Validation target for ThrustConstraint's
% Master-Equation assembly (see tests/constraints/TestThrustConstraint.m
% testF16CombatSubRequiredTWTable) -- NOT an input to the equation itself.
% Same WS_psf sweep as b.constraints.dash.WS_psf (Brandt's Consts sheet uses
% one shared W_TO/S column for every condition row).
b.constraints.combat_sub.WS_psf      = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.combat_sub.TW_CombatSub = [0.750288, 0.621802, 0.561842, 0.535309, 0.527578, ...
                                         0.531472, 0.543051, 0.559979, 0.580775, 0.604463, ...
                                         0.630366, 0.658006, 0.687031, 0.717180, 0.748253, ...
                                         0.780094, 0.812581, 0.845617, 0.879123, 0.913034, ...
                                         0.947296];   % [Brandt Consts sheet, Cmbt Trn row 26]

% [C] Max Mach / dash  36,000 ft, M=1.6, AB  [Consts row 23; Brandt "MxMach"]
b.constraints.dash.alt_ft         = 36000;
b.constraints.dash.mach           = 1.6;
b.constraints.dash.theta          = 0.752916;  % AI23
b.constraints.dash.theta_0        = 1.138409;  % AJ23
b.constraints.dash.delta          = 0.223993;  % AK23
b.constraints.dash.delta_0        = 0.952065;  % AL23
b.constraints.dash.alpha_dry      = 0.298293;  % AS23
b.constraints.dash.alpha_AB       = 0.576980;  % AT23
b.constraints.dash.alpha_mil_T_AB = 0.188237;  % AS23*(T_SL_dry/T_SL_AB)
b.constraints.dash.CD0            = 0.03933;   % Consts row 23 [Brandt Consts sheet] -- MxMach
b.constraints.dash.K1             = 0.1251;    % Consts row 23
b.constraints.dash.K2             = 0;         % Consts row 23

% Full MxMach constraint-diagram row [Brandt F-16A.xls Consts sheet]: the
% required T_SL/W_TO Brandt's own model produces at each of 21 W_TO/S sweep
% points. Validation target for ThrustConstraint's Master-Equation assembly
% (see tests/constraints/TestThrustConstraint.m testMasterEquationReproduces
% BrandtWorksheet) -- NOT an input to the equation itself.
b.constraints.dash.WS_psf    = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.dash.TW_MxMach = [2.899067, 2.149974, 1.709927, 1.420634, 1.216140, ...
                                1.064066, 0.946659, 0.853367, 0.777526, 0.714722, ...
                                0.661913, 0.619169, 0.578204, 0.544542, 0.515045, ...
                                0.489014, 0.465897, 0.444524, 0.426730, 0.410032, ...
                                0.394923];   % [Brandt Consts sheet, MxMach row]

% [D] Max altitude  50,000 ft, M=0.87  [Consts row 25]
b.constraints.max_alt.alt_ft         = 50000;
b.constraints.max_alt.mach           = 0.87;
b.constraints.max_alt.theta          = 0.751875;  % AI25
b.constraints.max_alt.theta_0        = 0.865694;  % AJ25
b.constraints.max_alt.delta          = 0.114669;  % AK25
b.constraints.max_alt.delta_0        = 0.187807;  % AL25
b.constraints.max_alt.alpha_dry      = 0.138789;  % AS25
b.constraints.max_alt.alpha_AB       = 0.170290;  % AT25
b.constraints.max_alt.alpha_mil_T_AB = 0.087582;  % AS25*(T_SL_dry/T_SL_AB)
b.constraints.max_alt.CD0            = 0.01700;   % Consts row 25 [Brandt Consts sheet]
b.constraints.max_alt.K1             = 0.11603;   % Consts row 25
b.constraints.max_alt.K2             = -0.0066;   % Consts row 25

% Full Max Alt constraint-diagram row [Brandt F-16A.xls Consts sheet]: the
% required T_SL/W_TO Brandt's own model produces at each of 21 W_TO/S sweep
% points. Validation target for ThrustConstraint's Master-Equation assembly
% (see tests/constraints/TestThrustConstraint.m testF16MaxAltRequiredTWTable)
% -- NOT an input to the equation itself. Same WS_psf sweep as
% b.constraints.dash.WS_psf (Brandt's Consts sheet uses one shared W_TO/S
% column for every condition row).
b.constraints.max_alt.WS_psf    = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.max_alt.TW_MaxAlt = [0.727697, 0.591304, 0.523436, 0.488996, 0.473359, ...
                                    0.469345, 0.473018, 0.482038, 0.494928, 0.510708, ...
                                    0.528705, 0.548437, 0.569556, 0.591798, 0.614964, ...
                                    0.638898, 0.663478, 0.688607, 0.714205, 0.740209, ...
                                    0.766565];   % [Brandt Consts sheet, Max Alt row]

% [E] 2nd combat turn (supersonic)  [Brandt F-16A.xls, Consts sheet, row 27]
%   36,000 ft, M=1.4, n=1.4, 100% AB.
b.constraints.combat_sup.alt_ft         = 36000;    % ft   [Brandt Consts C27]
b.constraints.combat_sup.mach           = 1.4;      % --   [Brandt Consts D27]
b.constraints.combat_sup.n              = 1.4;      % --   load factor  [Brandt Consts E27]
b.constraints.combat_sup.theta          = 0.752916; % AI27  [Brandt Consts]
b.constraints.combat_sup.theta_0        = 1.048059; % AJ27  [Brandt Consts]
b.constraints.combat_sup.delta          = 0.223993; % AK27  [Brandt Consts]
b.constraints.combat_sup.delta_0        = 0.712808; % AL27  [Brandt Consts]
b.constraints.combat_sup.alpha_dry      = 0.357862; % AS27  T_dry/T_SL_dry  [Brandt Consts]
b.constraints.combat_sup.alpha_AB       = 0.556558; % AT27  T_AB/T_SL_AB    [Brandt Consts]
b.constraints.combat_sup.alpha_mil_T_AB = 0.225828; % AS27*(T_SL_dry/T_SL_AB) = 0.357862*(15000/23770)
b.constraints.combat_sup.CD0            = 0.04063;  % Consts row 27 [Brandt Consts sheet]
b.constraints.combat_sup.K1             = 0.12563;  % Consts row 27
b.constraints.combat_sup.K2             = -0.00105; % Consts row 27 -- Brandt's model is not exactly 0 here despite M>1 (K2=0 supersonic is this framework's own linearized-theory assumption, not universal)

% Full Combat Turn 2 (supersonic) constraint-diagram row [Brandt F-16A.xls
% Consts sheet, row 27, "Cmbt Trn"]: the required T_SL/W_TO Brandt's own
% model produces at each of 21 W_TO/S sweep points. Validation target for
% ThrustConstraint's Master-Equation assembly (see
% tests/constraints/TestThrustConstraint.m testF16CombatSupRequiredTWTable)
% -- NOT an input to the equation itself. Same WS_psf sweep as
% b.constraints.dash.WS_psf (Brandt's Consts sheet uses one shared W_TO/S
% column for every condition row).
b.constraints.combat_sup.WS_psf      = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.combat_sup.TW_CombatSup = [2.38427, 1.77264, 1.41439, 1.17976, 1.01465, ...
                                         0.89252, 0.79881, 0.72487, 0.66525, 0.61631, ...
                                         0.57557, 0.54124, 0.51204, 0.48700, 0.46537, ...
                                         0.44658, 0.43018, 0.41582, 0.40318, 0.39205, ...
                                         0.38221];   % [Brandt Consts sheet, Cmbt Trn row 27]

% [F] Ps (specific excess power) condition  [Brandt F-16A.xls, Consts sheet, row 28]
%   10,000 ft, M=0.87, n=1, 100% AB, Ps_req=500 ft/s.
%   Rows 28–30 are identical in the workbook; row 28 is used here.
b.constraints.ps.alt_ft         = 10000;    % ft   [Brandt Consts C28]
b.constraints.ps.mach           = 0.87;     % --   [Brandt Consts D28]
b.constraints.ps.n              = 1;        % --   [Brandt Consts E28]
b.constraints.ps.Ps_fps         = 500;      % ft/s [Brandt Consts G28]
b.constraints.ps.theta          = 0.931366; % AI28  [Brandt Consts]
b.constraints.ps.theta_0        = 1.072356; % AJ28  [Brandt Consts]
b.constraints.ps.delta          = 0.687277; % AK28  [Brandt Consts]
b.constraints.ps.delta_0        = 1.125634; % AL28  [Brandt Consts]
b.constraints.ps.alpha_dry      = 0.702727; % AS28  T_dry/T_SL_dry  [Brandt Consts]
b.constraints.ps.alpha_AB       = 0.853550; % AT28  T_AB/T_SL_AB    [Brandt Consts]
b.constraints.ps.alpha_mil_T_AB = 0.443455; % AS28*(T_SL_dry/T_SL_AB) = 0.702727*(15000/23770)
b.constraints.ps.CD0            = 0.01700;  % Consts row 28 [Brandt Consts sheet] -- rows 28-30 identical, row 28 used
b.constraints.ps.K1             = 0.11603;  % Consts row 28
b.constraints.ps.K2             = -0.0066;  % Consts row 28

% Full Ps (specific excess power) constraint-diagram row [Brandt F-16A.xls
% Consts sheet, row 28]: the required T_SL/W_TO Brandt's own model produces
% at each of 21 W_TO/S sweep points. Validation target for ThrustConstraint's
% Master-Equation assembly (see tests/constraints/TestThrustConstraint.m
% testF16PsRequiredTWTable) -- NOT an input to the equation itself. Same
% WS_psf sweep as b.constraints.dash.WS_psf (Brandt's Consts sheet uses one
% shared W_TO/S column for every condition row).
b.constraints.ps.WS_psf = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.ps.TW_Ps  = [1.32434, 1.12632, 1.01023, 0.93411, 0.88048, ...
                           0.84074, 0.81020, 0.78605, 0.76653, 0.75047, ...
                           0.73705, 0.72571, 0.71603, 0.70769, 0.70046, ...
                           0.69414, 0.68860, 0.68371, 0.67939, 0.67555, ...
                           0.67213];   % [Brandt Consts sheet, Ps row 28]

% [G] Takeoff ground roll  [Brandt F-16A.xls, Consts sheet, row 32]
%   theta=theta_0=1, delta=delta_0=0.99976 -> M=0 (no ram-rise/impact-pressure
%   terms); the small delta<1 offset is a sub-7-ft equivalent-altitude
%   artifact of Brandt's own sheet, not a meaningful altitude. CD0 is much
%   higher than clean (0.052 vs 0.017) from flaps/gear; K1/K2 match the
%   clean subsonic polar in Brandt's model (unaffected by configuration here).
b.constraints.takeoff.alt_ft  = 0;
b.constraints.takeoff.mach    = 0;
b.constraints.takeoff.theta   = 1;        % Consts row 32
b.constraints.takeoff.theta_0 = 1;        % Consts row 32
b.constraints.takeoff.delta   = 0.99976;  % Consts row 32
b.constraints.takeoff.delta_0 = 0.99976;  % Consts row 32
b.constraints.takeoff.CD0     = 0.052;    % Consts row 32 -- takeoff flap/gear config
b.constraints.takeoff.K1      = 0.11603;  % Consts row 32
b.constraints.takeoff.K2      = -0.0066;  % Consts row 32

% Full Takeoff constraint-diagram row [Brandt F-16A.xls Consts sheet, row
% 32]: the required T_SL/W_TO Brandt's own (unsimplified) takeoff-ground-
% roll model produces at each of 21 W_TO/S sweep points -- includes the
% drag/rolling-friction term (temp_Casey takeoff_constraint.m term2) that
% TakeoffConstraint.m's simplified form intentionally omits (see that
% class's header), so this is a diagnostic/loose validation target for
% tests/constraints/TestTakeoffConstraint.m, NOT an exact-match assertion.
% Same WS_psf sweep as b.constraints.dash.WS_psf (Brandt's Consts sheet
% uses one shared W_TO/S column for every condition row).
b.constraints.takeoff.WS_psf     = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
b.constraints.takeoff.TW_Takeoff = [0.13551, 0.16247, 0.18944, 0.21640, 0.24336, ...
                                    0.27033, 0.29729, 0.32425, 0.35121, 0.37818, ...
                                    0.40514, 0.43210, 0.45907, 0.48603, 0.51299, ...
                                    0.53996, 0.56692, 0.59388, 0.62085, 0.64780, ...
                                    0.67477];   % [Brandt Consts sheet, Takeoff row 32]

% [H] Landing approach  [Brandt F-16A.xls, Consts sheet, row 33]
%   Same theta/theta_0/delta/delta_0 as takeoff (M=0); CD0 higher still
%   (0.062) from full flaps/gear/speedbrake landing configuration.
b.constraints.landing.alt_ft  = 0;
b.constraints.landing.mach    = 0;
b.constraints.landing.theta   = 1;        % Consts row 33
b.constraints.landing.theta_0 = 1;        % Consts row 33
b.constraints.landing.delta   = 0.99976;  % Consts row 33
b.constraints.landing.delta_0 = 0.99976;  % Consts row 33
b.constraints.landing.CD0     = 0.062;    % Consts row 33 -- landing flap/gear config
b.constraints.landing.K1      = 0.11603;  % Consts row 33
b.constraints.landing.K2      = -0.0066;  % Consts row 33

% Landing wing-loading limit [Brandt F-16A.xls, Consts sheet, row 33]: the
% single W_TO/S value Brandt's own landing ground-roll-with-braking
% equation produces (mu=0.50, CLmax_land=1.4288, CD0=0.062, S_FR=4000 ft,
% k_L=1.3, beta=1.0) -- reference/diagnostic target for
% tests/constraints/TestLandingConstraint.m, not an exact-match
% assertion (LandingConstraint.m uses aero.get_CLmax/drag_polar's clean-
% config values, not Brandt's flapped CLmax_land/CD0 -- see that class's
% header).
b.constraints.landing.WS_land = 138.742;  % lbf/ft^2 [Brandt Consts row 33]

end

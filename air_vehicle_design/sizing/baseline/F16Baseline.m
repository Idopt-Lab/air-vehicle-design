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
b.geom.taper_ht        = 0.390;
b.geom.sweep_LE_ht_deg = 40;
b.geom.dihedral_ht_deg = -10;       % deg   -- anhedral
b.geom.S_vt            = 54.75;     % ft^2
b.geom.AR_vt           = 1.294;
b.geom.taper_vt        = 0.437;
b.geom.sweep_LE_vt_deg = 47.5;
b.geom.L_fus           = 47.50;     % ft    -- overall length (excl. probe)
b.geom.W_fus           = 7.0;       % ft    -- approx max width

% =========================================================================
%  2. Weights  [Brandt F-16A.xls, sheet "Wt"]
% =========================================================================
b.brandt.TOGW      = 31377.0;  % lbf  -- "Total @ Takeoff"   [Brandt B38]
b.brandt.OEW       = 19980.7;  % lbf  -- "Empty"             [Brandt B12]
b.brandt.W_fuel    = 6296.3;   % lbf  -- internal fuel        [Brandt B6]
b.brandt.W_landing = 20680.7;  % lbf  -- "Total for Lndg"    [Brandt B41]
b.brandt.W_perm_pay = 700;     % lbf  -- permanent payload    [Brandt B32]
b.brandt.W_exp_pay  = 4400;    % lbf  -- expendable payload   [Brandt B33+B34]

b.sizing.TOGW_target = 31377;  % lbf  [Brandt]
b.sizing.TOGW_tol    = 2000;   % lbf  -- acceptable +-band
b.sizing.OEW_frac    = b.brandt.OEW  / b.brandt.TOGW;   % approx 0.6367
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
    0.1000,  0.0169,  0.0170,  0.1160,  -0.0066;
    0.8727,  0.0169,  0.0170,  0.1160,  -0.0066;
    1.0547,  0.0456,  0.0457,  0.1277,  -0.0047;
    1.5000,  0.0413,  0.0399,  0.2516,   0.0000;
    2.0000,  0.0413,  0.0373,  0.3670,   0.0000;
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

end

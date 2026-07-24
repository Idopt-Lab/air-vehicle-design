function b = F16Baseline(variant)
%F16BASELINE  [DEPRECATED - TO BE DELETED] Ground-truth data for the F-16A Block 10.
%
%   *** DEPRECATED: this file and the whole baseline/ folder (F16Baseline.m +
%   extract_brandt.m) are superseded by air_vehicle_design/sizing/VnV/BrandtF16A/
%   (Brandt*.m classes + GroundTruth/*.json) and are slated for removal once the
%   remaining consumers are migrated to the VnV ground-truth. Do NOT add new
%   dependencies on F16Baseline; point new code at VnV/BrandtF16A instead. ***
%
%   b = F16Baseline() / F16Baseline("original") returns a struct of cited
%   inputs and expected truth outputs used to seed unit tests at all three
%   fidelity levels.
%
%   b = F16Baseline("corrected") returns the same struct, but with the
%   fields Casey's revised-OEW/component-weight recalculation actually
%   changes replaced by that recalculation's own values -- see section 2's
%   "corrected" override block (b.brandt.OEW/rho_*_model/W_wing/W_fuselage/
%   W_pitch_cntrl/W_vert/W_nacelles/W_strakes, b.sizing.TOGW_target) and
%   section 11b (b.constraints.*.TW_*, b.constraints.landing.WS_land) for
%   sources and citations. Every other field (geometry, engine, Brandt's raw
%   TOGW/fuel/landing weights, etc.) is identical between variants.
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

arguments
    variant (1,1) string {mustBeMember(variant, ["original", "corrected"])} = "original"
end

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

% Speedbrakes [TO, Fig. 1-2] -- 4-element clamshell. Reference-only value;
% not modeled by any current geometry/aerodynamics discipline (analogous to
% b.geom.S_exposed_strake below).
b.geom.S_speedbrake        = 14.26;   % ft^2  -- total, all 4 elements
b.geom.S_speedbrake_each   = 3.565;   % ft^2  -- per element
b.geom.n_speedbrake_elements = 4;     % --    -- clamshell element count

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
b.brandt.TOGW      = 31377.0;  % lbf  -- "Total @ Takeoff"   [Brandt B38] -- identical in both the original and corrections workbooks, so not part of the variant split below
b.brandt.OEW       = 19980.70058;  % lbf  -- "Empty"         [Brandt F-16A.xls Wt!B12] -- see the "corrected" override below (Casey's revised-OEW/component-weight recalculation, [corrections.xls Wt!B12] = 19148.07828)
b.brandt.W_fuel    = 6296.3;   % lbf  -- internal fuel        [Brandt B6]
b.brandt.W_landing = 20680.7;  % lbf  -- "Total for Lndg"    [Brandt B41]
b.brandt.W_perm_pay = 700;     % lbf  -- permanent payload    [Brandt B32]
b.brandt.W_exp_pay  = 4400;    % lbf  -- expendable payload   [Brandt B33+B34]

% Component-level Group Weight Statement [Brandt F-16A.xls, "Wt" sheet,
% rows 16-31]. b.brandt.W_wing/W_fuselage/W_pitch_cntrl/W_vert/W_nacelles/
% W_strakes below are Brandt's "Structural Weight Models, average psf" table
% results (Wt!C9:H9, a psf-coefficient x area model, analogous to this
% framework's own WeightsL2 method) -- verified identical to the raw
% Wt!B16-B21 Group Weight Statement cells (Brandt's own workbook feeds
% B16-B21 from this same table), and verified to sum with the remaining
% Wt!B22-B31 items to b.brandt.OEW (Wt!B12) in BOTH the original and
% corrected workbooks (19,980.7 and 19,148.1 lbf respectively) -- so the
% "doesn't sum" caveat previously written here was itself an artifact of
% the original/corrected mixup this variant split now fixes, not a real
% Brandt-workbook inconsistency.
% Per-component unit weights (Wt!C7:H7) -- Brandt's own psf coefficients,
% NOT the Raymer Table 15.2 fighter coefficients this framework's WeightsL2
% actually uses (wing=9.0, HT=4.0, VT=5.3, fus=4.8 lbf/ft^2, per
% F16WeightsL2/WeightsL2.wing_unit_weight et al.).
b.brandt.rho_wing_model    = 6.75;  % lbf/ft^2  [Brandt F-16A.xls Wt!C7]; Raymer Table 15.2 fighter wing = 9.0 lbf/ft^2 (differs)
b.brandt.rho_fus_model     = 5;     % lbf/ft^2  [Brandt F-16A.xls Wt!D7]; Raymer Table 15.2 fighter fuselage = 4.8 lbf/ft^2 (close)
b.brandt.rho_pitch_cntrl_model = 6; % lbf/ft^2  [Brandt F-16A.xls Wt!E7]; Raymer Table 15.2 fighter HT = 4.0 lbf/ft^2 (differs)
b.brandt.rho_vert_model    = 6;     % lbf/ft^2  [Brandt F-16A.xls Wt!F7]; Raymer Table 15.2 fighter VT = 5.3 lbf/ft^2 (close)
b.brandt.rho_nacelles_model = 4.5;  % lbf/ft^2  [Brandt F-16A.xls Wt!G7]; no Raymer Table 15.2 analog
b.brandt.rho_strakes_model = 4.5;   % lbf/ft^2  [Brandt F-16A.xls Wt!H7]; no Raymer Table 15.2 analog
b.brandt.W_wing        = 1785.946837; % lbf  -- wing structure            [Brandt F-16A.xls Wt!C9, using the rho_wing_model coeff above]
b.brandt.W_fuselage    = 3652.11;     % lbf  -- fuselage structure        [Brandt F-16A.xls Wt!D9]
b.brandt.W_pitch_cntrl = 648;         % lbf  -- horizontal tail/stabilator [Brandt F-16A.xls Wt!E9]
b.brandt.W_vert        = 360;         % lbf  -- vertical tail             [Brandt F-16A.xls Wt!F9]
b.brandt.W_nacelles    = 186.8174778; % lbf  -- engine nacelles           [Brandt F-16A.xls Wt!G9]
b.brandt.W_strakes     = 90;          % lbf  -- LEX/strakes (not modeled in this framework) [Brandt F-16A.xls Wt!H9]
% "Corrected" override -- Casey's revised-OEW/component-weight
% recalculation [source workbook "Brandt F-16A - corrections.xls", same
% Wt!B12/C7:H7/C9:H9 cells]. Only rho_pitch_cntrl_model/rho_wing_model/
% rho_fus_model actually change (6->4, 6.75->7, 5->4.8); rho_vert_model/
% rho_nacelles_model/rho_strakes_model are unchanged (still assigned below
% for structural completeness). W_strakes is likewise unchanged (90 lbf
% both ways) since Strakes aren't modeled by this framework's weights
% discipline either way.
if variant == "corrected"
    b.brandt.OEW       = 19148.07828;  % lbf  [corrections.xls Wt!B12]
    b.brandt.rho_wing_model    = 7;     % lbf/ft^2  [corrections.xls Wt!C7]
    b.brandt.rho_fus_model     = 4.8;   % lbf/ft^2  [corrections.xls Wt!D7]
    b.brandt.rho_pitch_cntrl_model = 4; % lbf/ft^2  [corrections.xls Wt!E7]
    b.brandt.rho_vert_model    = 6;     % lbf/ft^2  [corrections.xls Wt!F7]
    b.brandt.rho_nacelles_model = 4.5;  % lbf/ft^2  [corrections.xls Wt!G7]
    b.brandt.rho_strakes_model = 4.5;   % lbf/ft^2  [corrections.xls Wt!H7]
    b.brandt.W_wing        = 1852.093016; % lbf  [corrections.xls Wt!C9]
    b.brandt.W_fuselage    = 3506.0256;   % lbf  [corrections.xls Wt!D9]
    b.brandt.W_pitch_cntrl = 199.389002;  % lbf  [corrections.xls Wt!E9]
    b.brandt.W_vert        = 245.3380129; % lbf  [corrections.xls Wt!F9]
    b.brandt.W_nacelles    = 186.8174778; % lbf  [corrections.xls Wt!G9]
    b.brandt.W_strakes     = 90;          % lbf  [corrections.xls Wt!H9]
end
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

% "Sized" takeoff weight [Brandt F-16A.xls Main!O25, labeled "Sized:";
% same value at Size&Opt!B7 "Wto, lb"] -- Brandt's own wing-sizing-loop
% converged W_TO, distinct from the raw "Total @ Takeoff" Wt!B38 cell
% (b.brandt.TOGW above, unaffected by the OEW correction). Resolves the
% prior TODO here, which had already flagged that Brandt's "sizing" value
% (~29k lbf) was the more appropriate target than the 31,377 lbf B38 figure.
b.sizing.TOGW_target = 29606.858;  % lbf  [Brandt F-16A.xls Main!O25]
if variant == "corrected"
    b.sizing.TOGW_target = 25654.768;  % lbf  [corrections.xls Main!O25]
end
b.sizing.TOGW_tol    = 2000;   % lbf  -- acceptable +-band
b.sizing.OEW_frac    = b.brandt.OEW  / b.brandt.TOGW;   % 0.6367 original / 0.6103 corrected
b.sizing.Wf_frac     = b.brandt.W_fuel / b.brandt.TOGW; % approx 0.2006 (W_fuel/TOGW unaffected by variant)

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
%  11. Constraint-condition reference values  [Brandt F-16A.xls, "Consts"
%      sheet, except [I] Stall which comes from the "Ps" sheet -- see that
%      entry's own citation]
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
b.constraints.combat_sub.TW_CombatSub = [0.75029, 0.6218, 0.56184, 0.53531, 0.52758, ...
                                         0.53147, 0.54305, 0.55998, 0.58078, 0.60446, ...
                                         0.63037, 0.65801, 0.68703, 0.71718, 0.74825, ...
                                         0.78009, 0.81258, 0.84562, 0.87912, 0.91303, ...
                                         0.9473];   % [Brandt Consts sheet, Cmbt Trn row 26]

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
b.constraints.dash.K1             = 0.276031;  % CORRECTED (2026-07-23, user direction): supersonic-form K1,
                                                % k1_super_f(M=1.6) = AR*(M^2-1)*cos(Lambda_LE)/(4*AR*sqrt(M^2-1)-2)
                                                % [Raymer 6th ed. Eq. 12.51; same functional form as Brandt's
                                                % Aero-tab k1_super_f in BrandtAerodynamics.aero_at_mach()],
                                                % superseding the Consts-row-23 tabulated cell value (0.1251).
                                                % b.constraints.dash.TW_MxMach below has been RECOMPUTED to stay
                                                % consistent with this K1 (see the note at that array). This
                                                % directly contradicts tests/constraints/TestThrustConstraint.m's
                                                % "NOTE ON temp_Casey" comment, which documents the opposite
                                                % conclusion for this exact condition (that 0.1251, not a larger
                                                % supersonic-form value, was the one found to reproduce Brandt's
                                                % original TW_MxMach table) -- flagged, not reconciled, here;
                                                % that comment has not been updated.
b.constraints.dash.K2             = 0;         % Consts row 23

% Full MxMach constraint-diagram row [Brandt F-16A.xls Consts sheet]: the
% required T_SL/W_TO Brandt's own model produces at each of 21 W_TO/S sweep
% points. Validation target for ThrustConstraint's Master-Equation assembly
% (see tests/constraints/TestThrustConstraint.m testMasterEquationReproduces
% BrandtWorksheet) -- NOT an input to the equation itself.
b.constraints.dash.WS_psf    = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
% RECOMPUTED (2026-07-23, user direction): the row immediately below is no
% longer Brandt's tabulated worksheet output. It is Brandt's original row
% (least-squares-fit to a T/W = A/WS + B*WS curve, max |fit residual| =
% 6.5e-4) with its B term (= K1_old*n^2*beta^2/(alpha*q)) rescaled by the
% ratio K1_new/K1_old = 0.276031/0.1251, matching the K1 correction applied
% to b.constraints.dash.K1 above. This directly reproduces the equation
% masterConstraint_ evaluates (see BrandtConstraintAnalysis.m) with the new
% K1 and everything else (CD0, alpha, beta, q) held at Brandt's original
% values. Superseded values (Brandt's original worksheet row, K1=0.1251):
%   [2.899067, 2.149974, 1.70993, 1.42063, 1.21614, 1.06407, 0.94666,
%    0.85337, 0.77753, 0.71472, 0.66191, 0.61693, 0.5782, 0.54454, 0.51505,
%    0.48901, 0.4659, 0.444525, 0.42673, 0.41003, 0.39492]
b.constraints.dash.TW_MxMach = [2.904072, 2.156704, 1.718385, 1.430823, 1.228061, ...
                                1.077721, 0.962048, 0.870490, 0.796384, 0.735314, ...
                                0.684239, 0.640996, 0.604001, 0.572074, 0.544313, ...
                                0.520017, 0.498635, 0.479728, 0.462938, 0.447976, ...
                                0.434602];   % RECOMPUTED at K1=0.276031 -- see note above

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
b.constraints.max_alt.TW_MaxAlt = [0.7277, 0.5913, 0.52344, 0.489, 0.47336, ...
                                    0.46935, 0.47302, 0.48204, 0.49493, 0.51071, ...
                                    0.5287, 0.54844, 0.56956, 0.5918, 0.61496, ...
                                    0.6389, 0.66348, 0.68861, 0.71421, 0.74021, ...
                                    0.76656];   % [Brandt Consts sheet, Max Alt row]

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
b.constraints.combat_sup.K1             = 0.226103; % CORRECTED (2026-07-23, user direction): supersonic-form K1,
                                                     % k1_super_f(M=1.4) = AR*(M^2-1)*cos(Lambda_LE)/(4*AR*sqrt(M^2-1)-2)
                                                     % [Raymer 6th ed. Eq. 12.51; same functional form as Brandt's
                                                     % Aero-tab k1_super_f in BrandtAerodynamics.aero_at_mach()],
                                                     % superseding the Consts-row-27 tabulated cell value (0.12563).
                                                     % b.constraints.combat_sup.TW_CombatSup below has been
                                                     % RECOMPUTED to stay consistent with this K1 (see the note at
                                                     % that array). See the parallel note on b.constraints.dash.K1
                                                     % above re: the now-contradicted TestThrustConstraint.m comment.
b.constraints.combat_sup.K2             = 0;        % CORRECTED (2026-07-23, user direction): corrections.xls
                                                     % Consts!AO27 now uses the same K2 supersonic equation
                                                     % (K2=0, linearized theory) as every other supersonic
                                                     % condition, superseding the old -0.00105 tabulated cell
                                                     % value. Resolves the previously-flagged anomaly ("Brandt's
                                                     % model is not exactly 0 here despite M>1"); K2=0 is no
                                                     % longer just this framework's own assumption for this row.
                                                     % No TW_CombatSup recompute needed: the original table was
                                                     % already generated with no K2 contribution (a nonzero
                                                     % K2*n*beta/alpha term would show up as a ~-0.0024 uniform
                                                     % offset across the row, which the A/WS+B*WS fit above
                                                     % shows is not present -- max residual 5.2e-6).

% Full Combat Turn 2 (supersonic) constraint-diagram row [Brandt F-16A.xls
% Consts sheet, row 27, "Cmbt Trn"]: the required T_SL/W_TO Brandt's own
% model produces at each of 21 W_TO/S sweep points. Validation target for
% ThrustConstraint's Master-Equation assembly (see
% tests/constraints/TestThrustConstraint.m testF16CombatSupRequiredTWTable)
% -- NOT an input to the equation itself. Same WS_psf sweep as
% b.constraints.dash.WS_psf (Brandt's Consts sheet uses one shared W_TO/S
% column for every condition row).
b.constraints.combat_sup.WS_psf      = 20:7:160;   % lbf/ft^2 -- Brandt's own W_TO/S sweep, 21 points
% RECOMPUTED (2026-07-23, user direction): the row immediately below is no
% longer Brandt's tabulated worksheet output -- see the parallel note on
% b.constraints.dash.TW_MxMach above (same method: least-squares fit of
% Brandt's original row to T/W = A/WS + B*WS, max |fit residual| = 5.2e-6,
% then B rescaled by K1_new/K1_old = 0.226103/0.12563). Superseded values
% (Brandt's original worksheet row, K1=0.12563):
%   [2.38459, 1.77307, 1.41494, 1.18042, 1.01542, 0.8934, 0.79981, 0.72598,
%    0.66647, 0.61765, 0.57702, 0.54281, 0.51372, 0.48879, 0.46727, 0.4486,
%    0.43231, 0.41806, 0.40554, 0.39451, 0.38479]
b.constraints.combat_sup.TW_CombatSup = [2.393396, 1.784961, 1.429914, 1.198472, 1.036556, ...
                                         0.917621, 0.827109, 0.756369, 0.699938, 0.654196, ...
                                         0.616648, 0.585520, 0.559517, 0.537668, 0.519234, ...
                                         0.503642, 0.490439, 0.479265, 0.469827, 0.461888, ...
                                         0.455250];   % RECOMPUTED at K1=0.226103 -- see note above

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
                                    0.53996, 0.56692, 0.59388, 0.62085, 0.64781, ...
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

% =========================================================================
%  11b. "Corrected" Brandt constraint values -- revised OEW/component-weight
%  basis  [Casey's workbook "Brandt F-16A - corrections.xls", "Consts"
%  sheet, J22:AE30 (T_SL/W_TO tables) + K33 (Landing W_TO/S)]
% =========================================================================
% The [A]-[H] constraint blocks above ("original") are Brandt's un-revised
% F-16A.xls. This corrections workbook recomputes the same 8 Consts-sheet
% rows (+ the Landing single-value row just below them) after Casey revised
% the F-16's OEW/component weights, which feeds back into Brandt's own
% drag-polar/thrust inputs for some -- not all -- of these conditions:
% MxMach and Combat Turn 1 (subsonic) shift materially at the high end of
% the W/S sweep, Cruise/Max Alt shift by a smaller, smoothly W/S-growing
% amount, while Combat Turn 2 (supersonic), Ps, and Landing come back
% essentially unchanged (their governing equations don't route through the
% revised weight/polar the same way the others do). Only these 7 fields
% differ between "original" and "corrected" -- every other b.* field
% (weights, geometry, engine, ...) is untouched by variant.
if variant == "corrected"
    % RECOMPUTED (2026-07-23, user direction): same K1=0.276031 correction
    % as the "original" b.constraints.dash.TW_MxMach above, applied here to
    % the corrections.xls-basis row instead (least-squares fit of the row
    % below to T/W = A/WS + B*WS, max |fit residual| = 5.0e-7, then B
    % rescaled by K1_new/K1_old = 0.276031/0.1251). Superseded values
    % (corrections.xls worksheet row, K1=0.1251):
    %   [2.898946, 2.149811, 1.709722, 1.420386, 1.215849, 1.063734,
    %    0.946284, 0.852949, 0.777067, 0.714220, 0.661368, 0.616347,
    %    0.577575, 0.543871, 0.514332, 0.488258, 0.465099, 0.444414,
    %    0.425847, 0.409107, 0.393955]
    b.constraints.dash.TW_MxMach = [2.903785, 2.156344, 1.717948, 1.430306, 1.227463, ...
                                     1.077042, 0.961286, 0.869645, 0.795456, 0.734303, ...
                                     0.683145, 0.639817, 0.602739, 0.570728, 0.542883, ...
                                     0.518503, 0.497038, 0.478046, 0.461173, 0.446127, ...
                                     0.432668];   % RECOMPUTED at K1=0.276031 -- see note above

    b.constraints.cruise.TW_Cruise = [1.290512, 0.981789, 0.806303, 0.695810, 0.621877, ...
                                       0.570543, 0.534155, 0.508163, 0.489696, 0.476848, ...
                                       0.468310, 0.463147, 0.460679, 0.460395, 0.461907, ...
                                       0.464914, 0.469176, 0.474506, 0.480748, 0.487778, ...
                                       0.495493];   % [corrections.xls Consts!K24:AE24]

    b.constraints.max_alt.TW_MaxAlt = [0.725185, 0.587913, 0.519166, 0.483847, 0.467331, ...
                                        0.462438, 0.465232, 0.473372, 0.485383, 0.500284, ...
                                        0.517402, 0.536255, 0.556495, 0.577858, 0.600144, ...
                                        0.623199, 0.646900, 0.671150, 0.695869, 0.720994, ...
                                        0.746471];   % [corrections.xls Consts!K25:AE25]

    b.constraints.combat_sub.TW_CombatSub = [0.747115, 0.617518, 0.556447, 0.528803, 0.519963, ...
                                              0.522745, 0.533215, 0.549031, 0.568717, 0.591294, ...
                                              0.616087, 0.642616, 0.670531, 0.699569, 0.729531, ...
                                              0.760262, 0.791638, 0.823564, 0.855958, 0.888759, ...
                                              0.921911];   % [corrections.xls Consts!K26:AE26]

    % RECOMPUTED (2026-07-23, user direction): same K1=0.226103 correction
    % as the "original" b.constraints.combat_sup.TW_CombatSup above, applied
    % here to the corrections.xls-basis row instead (least-squares fit of
    % the row below to T/W = A/WS + B*WS, max |fit residual| = 5.6e-7, then
    % B rescaled by K1_new/K1_old = 0.226103/0.12563). Superseded values
    % (corrections.xls worksheet row, K1=0.12563):
    %   [2.384266, 1.772636, 1.414394, 1.179756, 1.014645, 0.892515,
    %    0.798808, 0.724873, 0.665246, 0.616308, 0.575565, 0.541242,
    %    0.512044, 0.486999, 0.465370, 0.446583, 0.430185, 0.415815,
    %    0.403182, 0.392048, 0.382215]
    b.constraints.combat_sup.TW_CombatSup = [2.392815, 1.784177, 1.428927, 1.197282, 1.035163, ...
                                              0.916025, 0.825310, 0.754367, 0.697733, 0.651787, ...
                                              0.614036, 0.582706, 0.556499, 0.534447, 0.515810, ...
                                              0.500015, 0.486609, 0.475232, 0.465591, 0.457448, ...
                                              0.450608];   % RECOMPUTED at K1=0.226103 -- see note above

    b.constraints.ps.TW_Ps = [1.324343, 1.126315, 1.010227, 0.934111, 0.880478, ...
                               0.840744, 0.810201, 0.786052, 0.766531, 0.750465, ...
                               0.737050, 0.725711, 0.716029, 0.707691, 0.700457, ...
                               0.694142, 0.688599, 0.683713, 0.679388, 0.675548, ...
                               0.672128];   % [corrections.xls Consts!K28:AE28 (rows 28-30 identical, row 28 used)]

    b.constraints.landing.WS_land = 138.741741;   % lbf/ft^2 [corrections.xls Consts!K33] -- matches "original" 138.742 to displayed precision
end

% [I] Stall speed, sea level  [Brandt F-16A.xls, "Ps" sheet, cell B10]
%   The "Ps" sheet ("Jet3 Performance Reporting - Specific Excess Power") is
%   a different sheet from the "Consts" sheet [A]-[H] above are sourced
%   from -- it tabulates a "Stall Line" (Mach vs. altitude, columns B:C
%   starting row 10) alongside its Ps/qMax reporting tables, at the sheet's
%   own reference weight/CLmax (B4=23,828.85 lbf, F4=CLmax=1.1316, row 4).
%   B10 is the Stall Line's first (sea-level) point -- a typed constant in
%   the workbook (=0.217465934361336), not a live formula referencing
%   B4/F4, so it is transcribed here as given, not re-derived.
b.constraints.stall.alt_ft = 0;
b.constraints.stall.mach   = 0.217466;  % B10 [Brandt "Ps" sheet]

end

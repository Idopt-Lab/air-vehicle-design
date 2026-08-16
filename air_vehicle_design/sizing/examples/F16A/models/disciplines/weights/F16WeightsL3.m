classdef F16WeightsL3 < WeightsModelL3
%F16WEIGHTSL3  F-16A Block 10/15 Level-3 weight estimation student class.
%
%   Inherits from WeightsModelL3. Every abstract method delegates to a WeightsL3
%   static. L3 is Raymer 6th ed. §15.3.1 Fighter/Attack statistical component
%   buildup, Eqs. 15.1–15.24, plus the dry engine weight from Raymer Eq. 10.10
%   (NOT a §15.3.1 equation — §15.3.1 supplies the installation hardware on top
%   of a vendor dry weight).
%
%   OEW = wing + HT + VT + fuselage + LG.main + LG.nose
%         + engine-group.total + systems-group.total + W_strake
%
%   The strake (LERX) term is k_strake·S_strake = 90.00 lbf [Brandt Main!D18 /
%   Wt!H7]; see the S_strake/k_strake property comment for the cross-model borrow
%   (§15.3.1 has no strake equation).
%
%   ★ STANDING TO-DO: every §15.3.1 exponent is unverified against the printed
%   book, including two code-vs-extract CONFLICTS (Eq. 15.13 N_en^1.023,
%   Eq. 15.3 cos(Λ_vt)^-0.323). Keep the code values; the checklist is in
%   WeightsL3.m's header and VnV/BrandtF16A/todo.md. Guard:
%   TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified stays RED.
%
%   Inputs are mutable spec/requirement data; Dependent getters recompute on
%   read (no stored copy, read-only). 45 inputs + 2 injected objects; 32 Dependent.
%
%   Constructor: F16WeightsL3(json_path, req_path, geom, prop) — all four
%   required, no silent default.
%       json_path — f16a_spec_path(3): aircraft_category + .weights.
%       req_path  — f16a_requirements_path(): design_mach + cruise condition;
%                   weights builds its own AircraftState (none is injected).
%       geom      — GeometryModelL2 or GeometryModelL3 (both declare the 21
%                   members read; see THE THREE GEOMETRY-DI NAME TRAPS below).
%       prop      — PropulsionBase. At the L3 rung this is an F16PropL2: there is
%                   NO L3 propulsion tier, so an "L3 propulsion" number must say so.
%
%   ★ THE THREE GEOMETRY-DI NAME TRAPS. Each would produce a plausible wrong
%   number with NO error if wired by name:
%     1. S_ht / S_vt  <- geom.S_exposed_ht / geom.S_exposed_vt (51.1486 / 40.8897),
%        NOT geom.S_ht / geom.S_vt (108 / 60 = FULL planform).
%     2. AR_vt / lambda_vt <- geom.AR_exposed_vt / geom.lambda_exposed_vt
%        (1.294 / 0.437), NOT geom.AR_vt / geom.lambda_vt (1.6 / 0.5 = FULL).
%     3. D_fus <- geom.H_max_fuselage (5.0, the Raymer Eq. 15.4 structural
%        DEPTH), NOT geom.D_fus (6.0, the Roskam Eq. 12.3 EQUIVALENT DIAMETER
%        (W_max+H_max)/2 used only for fuselage wetted area). Eq. 15.4 carries
%        D_fus^0.849, so the substitution inflates the fuselage by +17.9 %.
%   geom.AR_ht / geom.lambda_ht are NOT wired: Raymer Eq. 15.2 takes only
%   (W_dg, N_z, S_ht, F_w, B_h).
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 7th ed., AIAA, §15.3.1 (Eqs. 15.1-15.24)
%              and Eq. 10.10 (engine weight).
%     [Brandt] Brandt F-16A.xls — validation targets ONLY, never a calibration input.
%     [TO]     T.O. 1F-16A-1, USAF/EPAF F-16A/B Blocks 10/15.
%     [USAF]   USAF 3-view — HT span.

    % ===================================================================== %
    % INPUTS (42 numeric + aircraft_category) + 2 injected objects — mutable
    % spec/requirement data. Citations: F16WeightsL3.md §2.
    % ===================================================================== %
    properties

        % ================================================================== %
        %  CLASS FLAG
        % ================================================================== %
        aircraft_category = 'jet_fighter'  % [f16a_L3.json top-level]. No WeightsL3 static reads it: the class implements only Raymer's Fighter/Attack buildup (one path, no category lookup). Carried for interface parity with F16WeightsL1/L2 and report labelling

        % ================================================================== %
        %  WEIGHTSBASE ABSTRACT PROPERTIES (sizing-loop closure variables)
        % ================================================================== %
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]. Raymer's W_dg throughout §15.3.1
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = Main!O16]

        % ================================================================== %
        %  LOAD FACTOR, RAYMER CONFIGURATION FLAGS, REQUIREMENTS
        % ================================================================== %
        N_z         = 13.5  % --   ULTIMATE load factor = 1.5 x 9g limit [T.O. 1F-16A-1 §5; Raymer 6th ed. §15.3.1 defines N_z as ultimate]. Not Brandt's n_ult = 9 (a different model)
        K_dw        = 1.0   % --   not a delta wing        [Raymer 6th ed. §15.3.1, Eq. 15.1 flag]
        K_vs        = 1.0   % --   not variable sweep      [Raymer 6th ed. §15.3.1, Eq. 15.1 flag]
        K_rht       = 1.047 % --   rolling (all-moving) horizontal tail [Raymer 6th ed. §15.3]. Applied in Eq. 15.3 (VT), not Eq. 15.2, as the book prints it; JSON keys it under .weights.horizontal_tail because the FLAG describes the HT
        K_dwf       = 1.0   % --   not a delta-wing fuselage [Raymer 6th ed. §15.3.1, Eq. 15.4 flag]
        K_vsh       = 1.0   % --   no variable-sweep hydraulics [Raymer 6th ed. §15.3.1, Eq. 15.19 flag]

        design_mach = 2.0   % --   design maximum Mach. From f16a_requirements.json (a REQUIREMENT, not .weights). Feeds Eq. 15.3's M^0.341, Eq. 15.17's M^0.003 and Raymer Eq. 10.10's M^0.25. [Brandt Main! aircraft.Mmax = 2.0]. NOT the T.O. operating Mach limit 2.05
        cruise_altitude_ft = 36000 % ft  cruise altitude at which SFC_mission is evaluated. From f16a_requirements.json [Brandt Consts! row 24, pct_AB = 0 i.e. dry/mil]
        cruise_mach        = 0.87  % --  cruise Mach, same source as cruise_altitude_ft

        % ================================================================== %
        %  LANDING GEAR INPUTS  (W_l is DERIVED — see the Dependent block)
        % ================================================================== %
        N_l   = 2.67  % --  landing load factor  [standard military; verify T.O. §5 — estimate, unpinned]
        L_m   = 5.5   % ft  main-gear extended strut length [estimate, unpinned]. Converted to INCHES (x12) inside WeightsL3.weight_landing_gear per Raymer Eq. 15.5 nomenclature
        L_n   = 3.5   % ft  nose-gear extended strut length [estimate, unpinned]; same inch conversion (Eq. 15.6)
        K_cb  = 1.0   % --  not carrier-based    [Raymer 6th ed. §15.3.1, Eq. 15.5 flag]
        K_tpg = 1.0   % --  not kneeling gear    [Raymer 6th ed. §15.3.1, Eq. 15.5 flag]
        N_nw  = 1     % --  number of nose wheels [T.O. 1F-16A-1]

        % ================================================================== %
        %  ENGINE SECTION INPUTS  (T_max, W_en are DERIVED by propulsion DI)
        % ================================================================== %
        N_en  = 1     % --  number of engines [T.O. 1F-16A-1]. Not derivable: no propulsion class exposes an engine count
        S_fw  = 0     % ft^2 firewall area — no piston firewall on a jet, so Eq. 15.8 returns 0 [Raymer 6th ed. §15.3.1]
        D_e   = 3.33  % ft  engine exit-nozzle diameter, ~40 in [estimate, unpinned]. Geometry analog geom.D_exit = 3.537 deliberately NOT wired (open, +24.94 lbf on OEW)
        L_tp  = 4.5   % ft  tailpipe length      [estimate, unpinned]; no repo geometry analog
        L_sh  = 8.0   % ft  engine shroud length [estimate, unpinned]; no analog
        L_ec  = 5.0   % ft  engine-controls run  [estimate, unpinned]; no analog
        L_d   = 7.5   % ft  inlet duct length    [estimate, unpinned]. Geometry analog geom.L_duct = 14.0 [Brandt Main!F32] deliberately NOT wired (open, +201.47 lbf on OEW)
        L_s   = 3.0   % ft  splitter/bypass length [estimate, unpinned]. L_s = 0 makes Eq. 15.10's (L_s/L_d)^(-0.373) = Inf; left UNGUARDED by decision
        K_vg  = 1.0   % --  fixed-geometry inlet [Raymer 6th ed. §15.3.1, Eq. 15.10 flag]
        K_d   = 1.0   % --  duct-shape flag [Raymer 6th ed. §15.3.1, baseline]. ★ K_d = 0 is the legitimate straight-duct value, and 0^0.182 = 0, so it SILENTLY ZEROES the 227.54 lbf air-induction component (no error, no NaN). Left UNGUARDED by decision

        % ================================================================== %
        %  SYSTEMS INPUTS  (SFC_mission is DERIVED by propulsion DI)
        % ================================================================== %
        V_t   = 940   % gal total internal fuel volume [Brandt Wt!B6 = 6296.30 lbf / 6.7 lb-per-gal ~= 940]. Kept as an INPUT, not derived: the 6.7 lb/gal density is cited nowhere in this repo, so deriving it would make provenance worse
        V_i   = 500   % gal integral (wing) tank volume [estimate, unpinned; F-16 wing integral tanks]
        V_p   = 0     % gal pressurised tank volume [estimate, unpinned]
        N_t   = 3     % --  number of fuel tanks (2 wing + 1 fuselage) [estimate; verify T.O.]
        N_s   = 4     % --  number of control surfaces (flaperon, stab, rudder, LEF) [estimate, unpinned]
        N_c   = 1     % --  number of cockpits — single-seat [T.O. 1F-16A-1]
        N_ci  = 3     % --  number of comm/ID items [estimate, unpinned; F-16 Block 10]
        N_u   = 5     % --  number of hydraulic utility functions [estimate, unpinned]
        R_kva = 80    % kVA electrical power requirement [estimate, unpinned; F-16 Block 10 ~60-80 kVA]
        L_a   = 10.0  % ft  electrical lead length [estimate, unpinned]
        N_gen = 1     % --  number of generators [T.O. 1F-16A-1]
        W_uav = 1500  % lbf UNINSTALLED avionics weight [estimate, unpinned; F-16 Block 10 simple suite]
        K_mc  = 1.0   % --  <= 2 generators [Raymer 6th ed. §15.3.1, Eq. 15.20 flag]

        % ================================================================== %
        %  STRAKE (LERX)
        % ================================================================== %
        %S_STRAKE, K_STRAKE  Strake structural weight inputs. [Brandt Main!D18 =
        %   20 ft^2 / Wt!H7 = 4.5 lbf/ft^2]. Cross-model borrow: Raymer §15.3.1
        %   has no strake equation, so Brandt's own coefficient is the only
        %   source; it is a genuine input in his worksheet, not a back-calculated
        %   output. History and rationale: docs/decision_log.md
        S_strake  % ft^2      strake planform reference area   [Brandt Main!D18]
        k_strake  % lbf/ft^2  strake structural surface density [Brandt Wt!H7]

        % ================================================================== %
        %  INJECTED COLLABORATORS (NOT numeric spec data)
        % ================================================================== %
        geom   % (1,1) GeometryModelL2 OR GeometryModelL3 — supplies the 21 Dependent geometry quantities below by DI
        prop   % (1,1) PropulsionBase — F16PropL2 at the L3 rung (no L3 propulsion tier exists). Supplies T_max, Eq. 10.10's T and BPR, and get_TSFC for SFC_mission
    end

    % ===================================================================== %
    % DERIVED (32) — recomputed live on read; read-only.
    % Citations: F16WeightsL3.md §3.
    % ===================================================================== %
    properties (Dependent)
        % -- Geometry, by DI from geom (21) — closes finding #11's literals -- %
        S_w          % ft^2 EXPOSED wing planform area  [Eq. 15.1] = geom.S_exposed_wing (196.2261)
        AR_w         % --   wing aspect ratio           [Eq. 15.1] = geom.AR_wing (3.0)
        tc_root      % --   wing root thickness ratio   [Eq. 15.1] = geom.tc_r_wing (0.04)
        lambda_w     % --   wing taper ratio            [Eq. 15.1] = geom.lambda_wing (0.2275)
        Lambda_LE_w  % deg  wing LE sweep               [Eq. 15.1] = geom.LE_sweep_wing (40)
        S_csw        % ft^2 wing control-surface area   [Eq. 15.1] = geom.S_csw (68.03)
        S_ht         % ft^2 EXPOSED HT planform area    [Eq. 15.2] = geom.S_exposed_ht (51.1486) — ★ NOT geom.S_ht = 108
        F_w          % ft   fuselage width at HT intersection [Eq. 15.2] = geom.F_w (7.0)
        B_h          % ft   HT full span                [Eq. 15.2] = geom.B_h (18.5)
        S_vt         % ft^2 EXPOSED VT planform area    [Eq. 15.3] = geom.S_exposed_vt (40.8897) — ★ NOT geom.S_vt = 60
        AR_vt        % --   EXPOSED VT aspect ratio     [Eq. 15.3] = geom.AR_exposed_vt (1.294) — ★ NOT geom.AR_vt = 1.6
        lambda_vt    % --   EXPOSED VT taper ratio      [Eq. 15.3] = geom.lambda_exposed_vt (0.437) — ★ NOT geom.lambda_vt = 0.5
        Lambda_LE_vt % deg  VT LE sweep                 [Eq. 15.3] = geom.LE_sweep_vt (47.5)
        H_t          % ft   HT height above fuselage CL [Eq. 15.3] = geom.H_t (0)
        H_v          % ft   VT height scale             [Eq. 15.3] = geom.H_v (1)
        L_t          % ft   tail arm, wing 1/4-MAC to HT 1/4-MAC [Eq. 15.3] = geom.L_t (22.0)
        S_r          % ft^2 rudder area                 [Eq. 15.3] = geom.S_r (11.65)
        L_fus        % ft   fuselage structural length  [Eq. 15.4] = geom.L_fus (47.5)
        D_fus        % ft   max fuselage structural DEPTH [Eq. 15.4] = geom.H_max_fuselage (5.0) — ★ NOT geom.D_fus = 6.0
        W_fus        % ft   max fuselage width          [Eq. 15.4] = geom.W_max_fuselage (7.0)
        S_cs         % ft^2 total control-surface area  [Eq. 15.17] = geom.S_cs (190)

        % -- Propulsion, by DI from prop (1) + computed engine weights (2) --- %
        T_max        % lbf  SLS afterburning thrust = prop.T_SL (23770) [Brandt Engn(s)!T_AB_SLS = Main!D29]; feeds Eqs. 15.7, 15.15, 15.16
        W_en         % lbf  OFFICIAL dry engine weight, UNINSTALLED [Raymer 7th ed. Eq. 10.10] = 2775.0210 — ★ NO x1.3 at L3
        W_en_brandt  % lbf  ALTERNATE, already installed [Brandt Wt!B11] = 4730.2300 — comparison report only, NEVER summed

        % -- Newly derived by settled decisions 4 and 2 (2) ------------------ %
        W_l          % lbf  landing design gross weight = 0.95 · W_TO [Eqs. 15.5/15.6]. ★ The 0.95 has NO repo citation — §P4-16
        SFC_mission  % 1/hr mission SFC = prop.get_TSFC(AircraftState(cruise)) = 1.007116 [Eq. 15.16]

        % -- Group totals (5) — closes finding #12's NaN placeholders -------- %
        W_wings            % lbf  [Eq. 15.1]         = 2396.77 at W_TO = 31377
        W_tail             % struct(HT, VT) lbf [Eqs. 15.2-15.3] = 200.54 / 313.06
        W_fuselage         % lbf  [Eq. 15.4]         = 3674.20
        W_installed_engine % lbf  engine group total = 3381.70 (dry engine + Eqs. 15.7-15.15)
        W_subsystems       % lbf  systems group total = 4578.13 (Eqs. 15.16-15.24). ! Does NOT include the landing gear — see WeightsModelL3
        W_strake           % lbf  [Brandt Main!D18 / Wt!H7]  k_strake · S_strake = 90.00 (see S_strake/k_strake property comment)
    end

    methods

        function obj = F16WeightsL3(json_path, req_path, geom, prop)
        %F16WEIGHTSL3  Construct from a required spec JSON path, requirements
        %   JSON path, injected L2/L3 geometry object and injected propulsion
        %   object. No silent default. Sets only input properties.
        %
        %   geom reads the 21 members in THE THREE GEOMETRY-DI NAME TRAPS above;
        %   prop reads T_SL, bypass_ratio and get_TSFC(state). At the L3 rung
        %   pass an F16PropL2: there is no L3 propulsion tier.
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path        {mustBeTextScalar, mustBeNonzeroLengthText}
                geom      (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}
                prop      (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path));
            R = jsondecode(fileread(req_path));
            W = J.weights;

            obj.geom = geom;   % injected: supplies the 21 Dependent geometry quantities
            obj.prop = prop;   % injected: supplies T_max, W_en and SFC_mission

            % ---- class flag + payload ----------------------------------- %
            obj.aircraft_category    = char(J.aircraft_category);   % [f16a_L3.json top-level]
            obj.W_payload_fixed      = W.W_payload_fixed;           % [Brandt Wt!B4]
            obj.W_payload_expendable = W.W_payload_expendable;      % [Brandt Wt!B5]
            % W_TO and W_energy deliberately NOT read: sizing-loop / mission STATE.

            % ---- load factor + Raymer configuration flags ---------------- %
            obj.N_z   = W.N_z;                       % 13.5 = 1.5 x 9g [T.O. §5; Raymer §15.3.1]
            obj.K_dw  = W.wing.K_dw;                 % [Raymer, Eq. 15.1]
            obj.K_vs  = W.wing.K_vs;                 % [Raymer, Eq. 15.1]
            obj.K_rht = W.horizontal_tail.K_rht;     % 1.047 — applied in Eq. 15.3, see the property comment
            obj.K_dwf = W.vertical_tail.K_dwf;       % [Raymer, Eq. 15.4]
            obj.K_vsh = W.systems.K_vsh;             % [Raymer, Eq. 15.19]

            % ---- requirements (f16a_requirements.json) ------------------- %
            %      NOT spec data: one fidelity-independent requirements file.
            %      .weights.vertical_tail.M_design was deleted as a duplicate of
            %      design_mach (it also feeds Eqs. 15.17 and 10.10).
            obj.design_mach        = R.design_mach;        % 2.0 [Brandt Main! aircraft.Mmax] — NOT the T.O. 2.05
            obj.cruise_altitude_ft = R.cruise.altitude_ft; % 36000 [Brandt Consts! row 24]
            obj.cruise_mach        = R.cruise.mach;        % 0.87  [Brandt Consts! row 24]

            % ---- landing gear (W_l is DERIVED, not read) ----------------- %
            obj.N_l   = W.landing_gear.N_l;
            obj.L_m   = W.landing_gear.L_m;
            obj.L_n   = W.landing_gear.L_n;
            obj.K_cb  = W.landing_gear.K_cb;
            obj.K_tpg = W.landing_gear.K_tpg;
            obj.N_nw  = W.landing_gear.N_nw;

            % ---- engine section (T_max, W_en are DERIVED by DI) --------- %
            obj.N_en = W.engine_section.N_en;
            obj.S_fw = W.engine_section.S_fw;
            obj.D_e  = W.engine_section.D_e;
            obj.L_tp = W.engine_section.L_tp;
            obj.L_sh = W.engine_section.L_sh;
            obj.L_ec = W.engine_section.L_ec;
            obj.L_d  = W.engine_section.L_d;
            obj.L_s  = W.engine_section.L_s;
            obj.K_vg = W.engine_section.K_vg;
            obj.K_d  = W.engine_section.K_d;

            % ---- systems (SFC_mission is DERIVED by DI) ------------------ %
            obj.V_t   = W.systems.V_t;      % 940 gal — RESTORED input, decision 3
            obj.V_i   = W.systems.V_i;
            obj.V_p   = W.systems.V_p;
            obj.N_t   = W.systems.N_t;
            obj.N_s   = W.systems.N_s;
            obj.N_c   = W.systems.N_c;
            obj.N_ci  = W.systems.N_ci;
            obj.N_u   = W.systems.N_u;
            obj.R_kva = W.systems.R_kva;
            obj.L_a   = W.systems.L_a;
            obj.N_gen = W.systems.N_gen;
            obj.W_uav = W.systems.W_uav;
            obj.K_mc  = W.systems.K_mc;

            % ---- strake -------------------------------------------------- %
            obj.S_strake = W.strake.S_strake_ft2;   % [Brandt Main!D18]
            obj.k_strake = W.strake.k_strake_psf;   % [Brandt Wt!H7]
        end

        % ================================================================== %
        % Methods required by the abstract contract — each a single delegation
        % into the WeightsL3 static toolbox, which holds the cited §15.3.1
        % equations and reads the Dependent properties above live.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at the PASSED W_TO.
        %   [Raymer 6th ed. §15.3.1 Eqs. 15.1-15.24 + Eq. 10.10] + the strake
        %   term (Brandt Main!D18/Wt!H7). W_strake is pure area x density, added
        %   on top.
            oew = WeightsL3.OEW(obj, W_TO) + obj.W_strake;
        end

        function W = weight_wing(obj, W_TO)
            W = WeightsL3.weight_wing(obj, W_TO);
        end

        function W = weight_tail(obj, W_TO)
            W = WeightsL3.weight_tail(obj, W_TO);
        end

        function W = weight_fuselage(obj, W_TO)
            W = WeightsL3.weight_fuselage(obj, W_TO);
        end

        function W = weight_landing_gear(obj, W_TO)
        %WEIGHT_LANDING_GEAR  Main + nose gear [lbf].  [Raymer Eqs. 15.5-15.6]
        %   W_TO is required.
            W = WeightsL3.weight_landing_gear(obj, W_TO);
        end

        function W = weight_engine_section(obj, W_TO)
            W = WeightsL3.weight_engine_section(obj, W_TO);
        end

        function W = weight_systems(obj, W_TO)
            W = WeightsL3.weight_systems(obj, W_TO);
        end

        % ================================================================== %
        % DERIVED-property getters — recompute live on every read.
        % ================================================================== %

        % ---- Geometry by DI: wing (Eq. 15.1) ----------------------------- %
        function v = get.S_w(obj)
            % EXPOSED wing planform area [Brandt Geom!7 exposed-S wing row].
            v = obj.geom.S_exposed_wing;
        end
        function v = get.AR_w(obj)
            v = obj.geom.AR_wing;          % [Brandt Main!B19; corroborated T.O. Fig. 1-2]
        end
        function v = get.tc_root(obj)
            % Wing root t/c. The wing is modeled uniform-tc, so geom.tc_r_wing
            % mirrors geom.tc_wing [Brandt Main!B22 'NACA 4-digit' = 1404 -> 4 %;
            % T.O. Fig. 1-2, NACA 64A204].
            v = obj.geom.tc_r_wing;
        end
        function v = get.lambda_w(obj)
            v = obj.geom.lambda_wing;      % [Brandt Main!B20 'Taper Ratio']
        end
        function v = get.Lambda_LE_w(obj)
            % LEADING-EDGE sweep; Eq. 15.1's cos(Λ) sweep STATION is an open
            % question (WeightsL3.wing carries that caveat).
            v = obj.geom.LE_sweep_wing;    % [Brandt Main!B21 'Sweep, deg']
        end
        function v = get.S_csw(obj)
            v = obj.geom.S_csw;            % [T.O. Fig. 1-2: flaperon 31.32 + LEF 36.71]
        end

        % ---- Geometry by DI: horizontal tail (Eq. 15.2) ------------------ %
        function v = get.S_ht(obj)
            % ★ NAME TRAP 1: geom.S_exposed_ht = 51.1486 ft^2, NOT geom.S_ht =
            % 108 (FULL planform). Raymer Eq. 15.2 wants the EXPOSED planform;
            % wiring geom.S_ht is silent — no error, a plausible wrong number.
            v = obj.geom.S_exposed_ht;
        end
        function v = get.F_w(obj)
            % Fuselage width at the HT intersection [Brandt Main!C32 proxy — estimate].
            v = obj.geom.F_w;
        end
        function v = get.B_h(obj)
            v = obj.geom.B_h;              % 18.5 ft = 18 ft 6 in [USAF 3-view]
        end
        % geom.AR_exposed_ht / geom.lambda_exposed_ht are NOT wired: Raymer
        % Eq. 15.2 takes only (W_dg, N_z, S_ht, F_w, B_h).

        % ---- Geometry by DI: vertical tail (Eq. 15.3) -------------------- %
        function v = get.S_vt(obj)
            % ★ NAME TRAP 1 (VT half): geom.S_exposed_vt = 40.8897 ft^2, NOT
            % geom.S_vt = 60 (FULL planform).
            v = obj.geom.S_exposed_vt;
        end
        function v = get.AR_vt(obj)
            % ★ NAME TRAP 2: geom.AR_exposed_vt = 1.294, NOT geom.AR_vt = 1.6.
            % Eq. 15.3 carries AR_vt^0.223 on the EXPOSED panel. [T.O./USAF]
            v = obj.geom.AR_exposed_vt;
        end
        function v = get.lambda_vt(obj)
            % ★ NAME TRAP 2 (taper half): geom.lambda_exposed_vt = 0.437, NOT
            % geom.lambda_vt = 0.5. [T.O./USAF]
            v = obj.geom.lambda_exposed_vt;
        end
        function v = get.Lambda_LE_vt(obj)
            % 47.5 deg — PHYSICAL [T.O. 1F-16A-1], an intentional L3 divergence
            % from Brandt Main!H21 = 40.
            v = obj.geom.LE_sweep_vt;
        end
        function v = get.H_t(obj)
            v = obj.geom.H_t;              % 0 — conventional (non-T) tail [Raymer 6th ed. §15.3]
        end
        function v = get.H_v(obj)
            % 1 — any nonzero denominator for Eq. 15.3's (1 + H_t/H_v)^0.5.
            % ⚠ H_v = 0 gives NaN or Inf; left UNGUARDED by decision.
            v = obj.geom.H_v;
        end
        function v = get.L_t(obj)
            % 22.0 ft [estimate; verify T.O.] — unpinned estimate on the geometry object.
            v = obj.geom.L_t;
        end
        function v = get.S_r(obj)
            v = obj.geom.S_r;              % 11.65 ft^2 rudder area [T.O. Fig. 1-2]
        end

        % ---- Geometry by DI: fuselage (Eq. 15.4) ------------------------- %
        function v = get.L_fus(obj)
            % 47.5 ft — PHYSICAL [T.O. 1F-16A-1], an intentional L3 divergence
            % from Brandt Main!B32 = 46.5.
            v = obj.geom.L_fus;
        end
        function v = get.D_fus(obj)
            % ★ NAME TRAP 3, the costliest: geom.H_max_fuselage = 5.0 ft, NOT
            % geom.D_fus = 6.0 ft. Weights' D_fus is Eq. 15.4's MAXIMUM
            % STRUCTURAL DEPTH [Brandt Main!D32]; the geometry Dependent D_fus is
            % the Roskam Eq. 12.3 equivalent diameter. Eq. 15.4 carries
            % D_fus^0.849, so substituting 6.0 for 5.0 inflates the fuselage by
            % +17.9 % with no error.
            v = obj.geom.H_max_fuselage;
        end
        function v = get.W_fus(obj)
            v = obj.geom.W_max_fuselage;   % 7.0 ft max width [Brandt Main!C32; T.O.]
        end

        % ---- Geometry by DI: flight controls (Eq. 15.17) ----------------- %
        function v = get.S_cs(obj)
            % 190 ft^2 total control-surface area [estimate, unpinned] — on the geometry object.
            v = obj.geom.S_cs;
        end

        % ---- Propulsion by DI -------------------------------------------- %
        function v = get.T_max(obj)
            % SLS afterburning thrust from the injected engine [Brandt
            % Engn(s)!T_AB_SLS = Main!D29]. Feeds Eqs. 15.7 (mounts), 15.15
            % (starter) and 15.16 (fuel system).
            v = obj.prop.T_SL;
        end
        function v = get.W_en(obj)
            % OFFICIAL dry engine weight: Raymer 7th ed. Eq. 10.10,
            %   W = 0.0637·T^1.1·M^0.25·exp(-0.81·BPR) = 2775.0210 lbf
            % [coefficient at raymer_data.md:38], in PropL2.engine_weight_AB.
            % ★ UNINSTALLED at L3 — NO x1.3: WeightsL3.weight_engine_section adds
            % Eqs. 15.7-15.15 individually, which is what the metabook's x1.3
            % lumps, so applying both would double-count. x1.3 belongs at L2 only.
            v = PropL2.engine_weight_AB(obj.prop.T_SL, obj.design_mach, obj.prop.bypass_ratio);
        end
        function v = get.W_en_brandt(obj)
            % ALTERNATE, comparison report ONLY — never summed into OEW.
            % 0.199·T_AB = 4730.2300 lbf [Brandt Wt!B11; the 0.199 literal is
            % 'Engn(s)'!D22, readme_wt.md:230 attributes it to Brandt 1997
            % Table 6.2 as the INSTALLED formula, so no x1.3].
            v = WeightsL2.engine_weight_brandt(obj.prop.T_SL);
        end
        function v = get.SFC_mission(obj)
            % Mission SFC for Eq. 15.16, evaluated at the requirements cruise
            % condition (36,000 ft / M 0.87) on the injected engine = 1.007116
            % 1/hr (MIL dry, uninstalled). Weights builds the AircraftState
            % itself; no state is injected. +43.87 % above Brandt's Main!C30 =
            % 0.70, accepted (real cruise point + uninstalled basis).
            v = obj.prop.get_TSFC(AircraftState(obj.cruise_altitude_ft, obj.cruise_mach));
        end

        % ---- Landing weight ---------------------------------------------- %
        function v = get.W_l(obj)
            % Landing design gross weight for Eqs. 15.5/15.6 = 0.95 · obj.W_TO.
            % ★ The 0.95 factor has NO citation in this repo (user-supplied).
            % The equation and missing-citation record live on
            % WeightsL3.landing_weight; this getter only supplies obj.W_TO.
            v = WeightsL3.landing_weight(obj.requireWTO('W_l'));
        end

        % ---- Group totals ------------------------------------------------ %
        function v = get.W_wings(obj)
            v = WeightsL3.weight_wing(obj, obj.requireWTO('W_wings'));
        end
        function v = get.W_tail(obj)
            v = WeightsL3.weight_tail(obj, obj.requireWTO('W_tail'));
        end
        function v = get.W_fuselage(obj)
            v = WeightsL3.weight_fuselage(obj, obj.requireWTO('W_fuselage'));
        end
        function v = get.W_installed_engine(obj)
            % Engine GROUP total: dry engine (Eq. 10.10, uninstalled) + Eqs.
            % 15.7-15.15, built item by item. NOT guarded on W_TO: the group is
            % built from thrust and component geometry, never from gross weight.
            v = WeightsL3.weight_engine_section(obj, obj.W_TO).total;
        end
        function v = get.W_subsystems(obj)
            % Systems GROUP total, Eqs. 15.16-15.24. Contains NO landing-gear
            % term; OEW adds the gear separately (WeightsModelL3).
            v = WeightsL3.weight_systems(obj, obj.requireWTO('W_subsystems')).total;
        end

        function v = get.W_strake(obj)
            % k_strake * S_strake = 4.5 * 20 = 90.00 lbf [Brandt Wt!H9 = 4.5*20].
            % Pure area x density, no W_TO dependence.
            v = obj.k_strake * obj.S_strake;
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Every §15.3.1 group weight is a function of Raymer's design gross
        %   weight W_dg = W_TO (and W_l = 0.95·W_TO), so reading any of them
        %   before a gross weight exists is a caller error, not a silent NaN.
            W_TO = obj.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('F16WeightsL3:WTONotSet', ...
                    ['%s is a Raymer §15.3.1 quantity in the design gross ', ...
                     'weight W_dg, so obj.W_TO must be set to a positive value ', ...
                     'first (currently %g). Assign it from the sizing loop''s ', ...
                     'current TOGW iterate, e.g. w3.W_TO = 31377; or call ', ...
                     'OEW(W_TO)/weight_*(W_TO) with an explicit weight.'], ...
                     whatFor, W_TO);
            end
        end

    end

end

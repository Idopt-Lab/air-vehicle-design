classdef F16WeightsL3 < WeightsModelL3
%F16WEIGHTSL3  F-16A Block 10/15 Level-3 weight estimation student class.
%
%   Inherits from WeightsModelL3 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to WeightsL3 statics — no equations are
%   duplicated here.
%
%   METHOD: Raymer 6th ed. §15.3.1 Fighter/Attack statistical component buildup,
%   Eqs. 15.1–15.24, plus the dry engine weight from Raymer Eq. 10.10 (which is
%   NOT a §15.3.1 equation — §15.3.1 supplies the installation hardware on top of
%   a vendor dry weight).
%
%   OEW = wing + HT + VT + fuselage + LG.main + LG.nose
%         + engine-group.total + systems-group.total + W_strake
%
%   VALUES at W_TO = 31,377 lbf (computed live 2026-07-25; strake term added
%   2026-07-29; systems group and OEW updated 2026-08-10):
%     wing 2396.77 | HT 200.54 | VT 313.06 | fuselage 3674.20
%     LG 1160.93 (main 989.98 + nose 170.95) | engine group 3381.70
%     systems group 4572.60 (fuel system 423.465) | strake 90.00
%     OEW = 15789.80 lbf  (-20.97 % vs Brandt Wt!B12 = 19980.700578;
%                          -17.54 % vs corrections.xls 19148.08)
%     The -5.53 lbf on the systems group (and hence on OEW) since 2026-08-10 is
%     Eq. 15.17 alone: geom.S_cs stopped being a frozen 190 ft^2 "unpinned
%     estimate" and became the Dependent buildup S_csw + S_stab + S_rud =
%     187.68 ft^2 at the JSON baseline, so a sizing-loop rescale of the wing and
%     tail now reaches the flight-controls weight. Eq. 15.1's S_csw and
%     Eq. 15.3's S_r are unchanged at the baseline (68.03 and 11.65), because
%     F16GeomL3 seeds their components from the same T.O. measured areas -- so
%     the wing and vertical-tail weights above did not move.
%     OEW(45000) = 16959.63 | OEW(60000) = 18020.71 — the near-zero change at
%     45,000 vs the pre-Phase-4 code is a COINCIDENCE of four offsetting deltas,
%     not evidence that nothing changed (F16WeightsL3.md §4).
%
%   STRAKE (LERX) TERM — ADDED 2026-07-29: k_strake * S_strake = 4.5 * 20 =
%   90.00 lbf [Brandt Main!D18 / Wt!H7]. Previously unmodeled at every fidelity
%   level (examples/F16A/output/weights_brandt_comparison.md section 5); mirrors
%   F16WeightsL2's identical addition. See the S_strake/k_strake property
%   comment for why this borrows Brandt's own coefficient rather than a
%   Raymer §15.3.1 equation (there is no strake equation in that section).
%
%   ★ STANDING TO-DO, NOT CLEARED: EVERY §15.3.1 EXPONENT.
%   Locked decision (user 2026-07-24, "approach 2"): keep every current code
%   value — including the two documented code-vs-extract CONFLICTS, Eq. 15.13
%   N_en^1.023 and Eq. 15.3 cos(Λ_vt)^(-0.323) — re-cite them to a consistent
%   Raymer 6th ed. §15.3.1 reference, and do NOT declare them book-verified. The
%   complete 62-row checklist and the FROM-CODE / VERIFY / IMAGE-ONLY breakdown
%   are in WeightsL3.m's header and VnV/BrandtF16A/todo.md 2026-07-24 §3a.
%   Guard: TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified must stay
%   RED while that checklist is open. No exponent VALUE changes.
%
%   ============================================================================
%   INPUT vs DERIVED — the optimization-ready pattern (CLAUDE.md; reference
%   implementation examples/F16A/models/disciplines/geom/F16GeomL2.m).
%   45 INPUTS (44 numeric + 1 string) + 2 injected objects; 32 DERIVED (31 + W_strake, added 2026-07-29).
%
%   Phase 4 moved 32 of the former 72 plain properties: 23 frozen geometry
%   literals (21 to geometry DI, 2 deleted as dead), 2 frozen propulsion literals
%   (T_max, W_en), 5 NaN "computed total" placeholders, plus W_l and SFC_mission.
%
%   THREE DEFECTS THIS CONVERSION REMOVES — all were in this file:
%
%   REVIEW FINDING #11 — the constructor read NOTHING. Its entire body was a
%     comment; there was no argument, no JSON read, and every value the class
%     used was a classdef literal, so the .weights block of f16a_L3.json was
%     DEAD and ~22 geometry constants sat frozen inside a weights class.
%
%   REVIEW FINDING #12 — five "computed total" properties could read NaN.
%     W_wings / W_tail / W_fuselage / W_installed_engine / W_subsystems were
%     `= NaN` and no code ever assigned them. All five are now Dependent.
%
%   ★ §P4-17 (a 16th defect, found while quantifying decision 4) — THE LANDING
%     GEAR WAS FROZEN UNDER MUTATION. W_l = 20681 was a stored constant [Brandt
%     Wt!B41, itself =SUM(B16:B32), i.e. a back-calculated OUTPUT] AND
%     WeightsL3.weight_landing_gear took no W_TO argument, so the whole gear
%     group was bit-identical at every gross weight — 1057.273 lbf at 31,377,
%     45,000 and 60,000 alike (verified live). BOTH halves are fixed: W_l is now
%     Dependent = 0.95·W_TO and weight_landing_gear takes W_TO. The gear now
%     reads 1160.93 / 1273.17 / 1370.47 at those three weights.
%     Same defect class and same signature as review finding #5 at L2 — a Brandt
%     output frozen as an input — one tier up.
%   ============================================================================
%
%   CONSTRUCTOR (CHANGED 2026-07-25, Phase 4):
%     F16WeightsL3(json_path, req_path, geom, prop)  — all four REQUIRED.
%       json_path — f16a_spec_path(3): top-level aircraft_category + .weights.
%       req_path  — f16a_requirements_path(): design_mach + the cruise condition.
%                   Weights BUILDS the AircraftState itself from the two cruise
%                   numbers; an AircraftState is deliberately NOT injected (the
%                   earlier "inject a state" idea was reversed by the user).
%       geom      — (1,1) {mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])}.
%                   Loosened 2026-08-05 to accept EITHER geometry tier, mirroring
%                   the precedent already set by F16AeroL2.m/F16AeroL3.m and this
%                   file's L2 sibling (F16WeightsL2.m): both GeometryModelL2 and
%                   GeometryModelL3 abstractly declare all 21 members this class
%                   reads by DI IDENTICALLY (see "THE THREE GEOMETRY-DI NAME
%                   TRAPS" below), so accepting either tier is mechanically safe
%                   — a wrong tier still fails at CONSTRUCTION if it satisfies
%                   neither contract. (Earlier revisions of this file pinned
%                   geom to exactly GeometryModelL3, i.e. F16GeomL3, as a
%                   deliberate choice — "passing the L2 tier must fail HERE";
%                   that choice is deliberately reversed here to enable
%                   mixed-fidelity sizing runs. The finding-#10 lesson about a
%                   wrong tier resolving to different physical quantities
%                   mid-run still holds and is why the guard stays a `mustBeA`
%                   allow-list rather than being removed outright.)
%       prop      — (1,1) PropulsionBase. ★ At the L3 rung this is an F16PropL2:
%                   there is NO L3 propulsion tier (locked decision 2026-07-25),
%                   and anything reporting an "L3 propulsion" number must say so.
%     No silent default anywhere.
%
%   ★ THE THREE GEOMETRY-DI NAME TRAPS (docs/weights_parameter_usage.md §2).
%   Each would produce a plausible wrong number with NO error if wired by name:
%     1. S_ht / S_vt  <- geom.S_exposed_ht / geom.S_exposed_vt (51.1486 / 40.8897),
%        NOT geom.S_ht / geom.S_vt (108 / 60 = FULL planform).
%     2. AR_vt / lambda_vt <- geom.AR_exposed_vt / geom.lambda_exposed_vt
%        (1.294 / 0.437), NOT geom.AR_vt / geom.lambda_vt (1.6 / 0.5 = FULL).
%     3. D_fus <- geom.H_max_fuselage (5.0, the Raymer Eq. 15.4 structural
%        DEPTH), NOT geom.D_fus (6.0, the Roskam Eq. 12.3 EQUIVALENT DIAMETER
%        (W_max+H_max)/2 used only for fuselage wetted area). Eq. 15.4 carries
%        D_fus^0.849, so the substitution inflates the fuselage by +17.9 %.
%   And geom.AR_ht / geom.lambda_ht are NOT wired at all: Raymer Eq. 15.2 takes
%   only (W_dg, N_z, S_ht, F_w, B_h), so the former AR_ht = 2.114 / lambda_ht =
%   0.390 inputs were read by no equation and are DELETED, not re-pointed
%   (todo §P4-6).
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 7th ed., AIAA, §15.3.1 (Eqs. 15.1-15.24)
%              and Eq. 10.10 (engine weight).
%     [Brandt] Brandt F-16A.xls — validation targets ONLY, never a calibration
%              input. Brandt's own coefficients (0.199·T_AB engine, 6.75/5.0/6.0
%              psf structure, 0.034 LG) are a DIFFERENT model and are never used
%              in a framework equation.
%     [TO]     T.O. 1F-16A-1, USAF/EPAF F-16A/B Blocks 10/15.
%     [USAF]   USAF 3-view — HT span.

    % ===================================================================== %
    % INPUTS (42 numeric + aircraft_category) + 2 injected objects — plain
    % mutable properties, set once by the constructor from f16a_L3.json .weights
    % and f16a_requirements.json (the two state variables are mutated by the
    % sizing / mission loops). Every DERIVED property below recomputes live from
    % these and from the injected objects on every read.
    % Authoritative table with all citations: F16WeightsL3.md §2.
    % ===================================================================== %
    properties

        % ================================================================== %
        %  CLASS FLAG
        % ================================================================== %
        aircraft_category = 'jet_fighter'  % [f16a_L3.json top-level aircraft_category — ONE canonical class flag for every discipline]. ! NO WeightsL3 static reads it, and that is correct BY CONSTRUCTION: WeightsL3 implements only Raymer's Fighter/Attack buildup, so there is a single path and no category lookup. It is carried for interface parity with F16WeightsL1/L2 (which DO key their table lookups off it) and for report labelling. The f16a_L3.json note that once claimed "§15.3.1 exponents/coefficients are aircraft_category-selected toolbox Constants" was FALSE and has been corrected — every §15.3.1 coefficient is a bare literal in a WeightsL3 static. todo 2026-07-25 Phase 4 §P4-9

        % ================================================================== %
        %  WEIGHTSBASE ABSTRACT PROPERTIES (sizing-loop closure variables)
        % ================================================================== %
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE — the optimizer's variable, mutated in place by the sizing loop [WeightsBase contract]. Raymer's W_dg throughout §15.3.1
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]. ! Was 6296.3 = Brandt Wt!B6 (=B3-B4-B5-B12, live formula), a back-calculated OUTPUT — forbidden as an input
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = 4400.000000 (live), =Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = 700.000000 (live), =Main!O16]

        % ================================================================== %
        %  LOAD FACTOR, RAYMER CONFIGURATION FLAGS, REQUIREMENTS
        % ================================================================== %
        N_z         = 13.5  % --   ULTIMATE load factor = 1.5 x 9g limit [T.O. 1F-16A-1 §5; Raymer 6th ed. §15.3.1 defines N_z as ultimate]. ! Do NOT conflate with Brandt's n_ult = 9 [Main!Q27, live-confirmed inside Wt!C9's formula as Main!Q27^0.2] — that is his own psf model's exponent base, a different model
        K_dw        = 1.0   % --   not a delta wing        [Raymer 6th ed. §15.3.1, Eq. 15.1 flag]
        K_vs        = 1.0   % --   not variable sweep      [Raymer 6th ed. §15.3.1, Eq. 15.1 flag]
        K_rht       = 1.047 % --   rolling (all-moving) horizontal tail [Raymer 6th ed. §15.3]. ! Applied in Eq. 15.3 (VT), not Eq. 15.2 — that is how the book prints it, not a mix-up. The JSON keys it under .weights.horizontal_tail because the FLAG describes the HT
        K_dwf       = 1.0   % --   not a delta-wing fuselage [Raymer 6th ed. §15.3.1, Eq. 15.4 flag]
        K_vsh       = 1.0   % --   no variable-sweep hydraulics [Raymer 6th ed. §15.3.1, Eq. 15.19 flag]

        design_mach = 2.0   % --   design maximum Mach. From f16a_requirements.json, NOT .weights: it is an aircraft REQUIREMENT. Feeds Eq. 15.3's M^0.341, Eq. 15.17's M^0.003 AND Raymer Eq. 10.10's M^0.25 — it was never a vertical-tail input, which is why .weights.vertical_tail.M_design was deleted as a duplicate. [Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9] ★ NOT the T.O. 1F-16A-1 operating Mach LIMIT 2.05 [GroundTruth/f16a_ground_truth.json:228]; 2.0 != 2.05 (-2.44 %), live W_en sensitivity +0.62 %. todo §P4-13
        cruise_altitude_ft = 36000 % ft  cruise altitude at which SFC_mission is evaluated. From f16a_requirements.json [Brandt Consts! row 24 cruise condition, pct_AB = 0 i.e. dry/mil; GroundTruth/f16a_ground_truth.json .propulsion.thrust_lapse_at_constraint_conditions cruise row, live-verified 2026-07-24]
        cruise_mach        = 0.87  % --  cruise Mach, same source as cruise_altitude_ft

        % ================================================================== %
        %  LANDING GEAR INPUTS  (W_l is DERIVED — see the Dependent block)
        % ================================================================== %
        N_l   = 2.67  % --  landing load factor  [standard military; verify T.O. §5 — estimate, unpinned]
        L_m   = 5.5   % ft  main-gear extended strut length [estimate, unpinned]. ! Converted to INCHES (x12) inside WeightsL3.weight_landing_gear per Raymer's Eq. 15.5 nomenclature
        L_n   = 3.5   % ft  nose-gear extended strut length [estimate, unpinned]; same inch conversion (Eq. 15.6)
        K_cb  = 1.0   % --  not carrier-based    [Raymer 6th ed. §15.3.1, Eq. 15.5 flag]
        K_tpg = 1.0   % --  not kneeling gear    [Raymer 6th ed. §15.3.1, Eq. 15.5 flag]
        N_nw  = 1     % --  number of nose wheels [T.O. 1F-16A-1]

        % ================================================================== %
        %  ENGINE SECTION INPUTS  (T_max, W_en are DERIVED by propulsion DI)
        % ================================================================== %
        N_en  = 1     % --  number of engines [T.O. 1F-16A-1]. Not derivable: no propulsion class exposes an engine count (todo 2026-07-25 Phase 2 §22)
        S_fw  = 0     % ft^2 firewall area — no piston firewall on a jet, so Eq. 15.8 returns 0 [Raymer 6th ed. §15.3.1]
        D_e   = 3.33  % ft  engine exit-nozzle diameter, ~40 in [estimate, unpinned]. ⚠ A cited geometry analog EXISTS with a different value — geom.D_exit = 3.537022 — and wiring it is an OPEN decision worth +24.94 lbf on OEW (todo §P4-4). Deliberately NOT wired this phase
        L_tp  = 4.5   % ft  tailpipe length      [estimate, unpinned]; no repo geometry analog
        L_sh  = 8.0   % ft  engine shroud length [estimate, unpinned]; no analog
        L_ec  = 5.0   % ft  engine-controls run  [estimate, unpinned]; no analog
        L_d   = 7.5   % ft  inlet duct length    [estimate, unpinned]. ⚠ A cited geometry analog EXISTS with a very different value — geom.L_duct = 14.0 [Brandt Main!F32], +86.7 %, worth +201.47 lbf on OEW — and wiring it is an OPEN decision (todo §P4-4). Deliberately NOT wired this phase
        L_s   = 3.0   % ft  splitter/bypass length [estimate, unpinned]. ⚠ L_s = 0 makes Eq. 15.10's (L_s/L_d)^(-0.373) = Inf; left UNGUARDED by decision 6 (todo §P4-11)
        K_vg  = 1.0   % --  fixed-geometry inlet [Raymer 6th ed. §15.3.1, Eq. 15.10 flag]
        K_d   = 1.0   % --  duct-shape flag [Raymer 6th ed. §15.3.1; "use 1.0 as baseline; verify from §15.3.1"]. ★ K_d = 0 is documented in WeightsL3.air_induction as the legitimate STRAIGHT-DUCT value, and 0^0.182 = 0, so that legal input SILENTLY ZEROES the entire 227.54 lbf air-induction component — no error, no warning, not even a NaN (L3 OEW would read 15477.79 instead of 15705.33). NO GUARD IS ADDED, by explicit user decision 6 (2026-07-25), and this description is deliberately not softened. §P4-11 stays OPEN

        % ================================================================== %
        %  SYSTEMS INPUTS  (SFC_mission is DERIVED by propulsion DI)
        % ================================================================== %
        V_t   = 940   % gal total internal fuel volume [derived by Brandt-style arithmetic: Wt!B6 = 6296.30 lbf / 6.7 lb-per-gal ~= 940]. ★ RESTORED as an INPUT by decision 3, deliberately NOT derived: the 6.7 lb/gal density behind it is cited NOWHERE in this repo (grepped 2026-07-25 — no JP-4/JP-5/JP-8 density in metabook_data.md, raymer_data.md or readme_wt.md), so V_t = W_energy/rho would substitute an uncited constant for a Brandt-traceable figure and make provenance WORSE. The arithmetic also gives 939.746, not 940, so the literal is itself rounded. todo §P4-5b, provenance OPEN
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
        %  STRAKE (LERX), ADDED 2026-07-29
        % ================================================================== %
        %S_STRAKE, K_STRAKE  Strake structural weight inputs -- previously
        %   unmodeled at every fidelity level (examples/F16A/mds/
        %   weights_brandt_comparison.md section 5: 13.68% of Brandt Wt!B12).
        %   [Brandt F-16A.xls Main!D18 = 20 ft^2 / Wt!H7 = 4.5 lbf/ft^2].
        %   CROSS-MODEL BORROW, DELIBERATE: Raymer §15.3.1 (Eqs. 15.1-15.24, this
        %   class's official component buildup) has NO strake/LERX equation --
        %   it is not a component that section of the book covers at all. No
        %   Raymer alternative exists, so Brandt's own value is the only
        %   available source -- same reasoning already applied at L2
        %   (F16WeightsL2.m's S_strake/k_strake property comment), and NOT the
        %   forbidden back-calculated-output pattern: Brandt applies k_strake to
        %   S_strake as a genuine INPUT assumption in his own worksheet, not a
        %   value reverse-fit to a result.
        S_strake  % ft^2      strake planform reference area   [Brandt Main!D18]
        k_strake  % lbf/ft^2  strake structural surface density [Brandt Wt!H7]

        % ================================================================== %
        %  INJECTED COLLABORATORS (NOT numeric spec data)
        % ================================================================== %
        geom   % (1,1) GeometryModelL2 OR GeometryModelL3 (loosened 2026-08-05) — F16GeomL3 (or F16GeomL2, for mixed-fidelity runs), supplying the 21 Dependent geometry quantities below by DI, replacing 21 frozen literals (review finding #11)
        prop   % (1,1) PropulsionBase — F16PropL2 at the L3 rung (no L3 propulsion tier exists). Supplies T_max, Eq. 10.10's T and BPR, and get_TSFC for SFC_mission
    end

    % ===================================================================== %
    % DERIVED (31) — recomputed live from the inputs / injected objects on every
    % read. No cache, never stale. Read-only: assigning to any of these errors
    % (there are no set-methods), which is correct — they are outputs.
    % Authoritative table with all citations: F16WeightsL3.md §3.
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
        W_subsystems       % lbf  systems group total = 4572.60 (Eqs. 15.16-15.24). ! Does NOT include the landing gear — see WeightsModelL3
        W_strake           % lbf  [Brandt Main!D18 / Wt!H7]  k_strake · S_strake = 90.00, added 2026-07-29 (see S_strake/k_strake property comment)
    end

    methods

        function obj = F16WeightsL3(json_path, req_path, geom, prop)
        %F16WEIGHTSL3  Construct from a required spec JSON path, a required
        %   requirements JSON path, a required injected L3 geometry object and a
        %   required injected propulsion object. NO silent default on any of the
        %   four. Sets ONLY input properties; every derived quantity is produced
        %   live by its Dependent getter.
        %
        %   Replaces the pre-Phase-4 no-argument constructor whose entire body
        %   was a comment (review finding #11), which left the .weights block of
        %   f16a_L3.json read by nothing.
        %
        %   geom must be a GeometryModelL2 OR GeometryModelL3 subclass (loosened
        %   2026-08-05, see the class header): only the 21 members enumerated in
        %   "THE THREE GEOMETRY-DI NAME TRAPS" above are read, and both tiers
        %   declare these identically. A tier satisfying neither contract still
        %   fails HERE, at construction, rather than resolving to different
        %   physical quantities mid-run.
        %   prop must be a PropulsionBase subclass; T_SL, bypass_ratio and
        %   get_TSFC(state) are read. At the L3 rung pass an F16PropL2: there is
        %   no L3 propulsion tier (locked decision 2026-07-25).
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

            % ---- strake (ADDED 2026-07-29) ------------------------------- %
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
        %   [Raymer 6th ed. §15.3.1 Eqs. 15.1-15.24 + Eq. 10.10] + this class's
        %   own strake term (Brandt Main!D18/Wt!H7 -- ADDED 2026-07-29, see the
        %   S_strake/k_strake property comment for why it lives here rather
        %   than in the generic WeightsL3 toolbox: §15.3.1 has no strake
        %   equation, so it is not a quantity another aircraft's L3 weights
        %   class could reuse unmodified).
        %   W_strake carries no W_TO dependence (pure area x density), so it is
        %   simply added on top.
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
        %   ! W_TO is REQUIRED as of Phase 4 — see WeightsModelL3 and §P4-17.
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
            % EXPOSED wing planform area, per Raymer's own definition
            % [Brandt Geom!7 exposed-S wing row; readme_geom.md §4.3] via
            % GeomL2.compute_S_exposed_horizontal. Replaces a stored 196.23.
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
            % LEADING-EDGE sweep. Eq. 15.1's cos(Λ) sweep STATION is itself an
            % open question (some editions use quarter-chord) — WeightsL3.wing
            % carries that caveat; this getter simply supplies the LE value.
            v = obj.geom.LE_sweep_wing;    % [Brandt Main!B21 'Sweep, deg']
        end
        function v = get.S_csw(obj)
            v = obj.geom.S_csw;            % [T.O. Fig. 1-2: flaperon 31.32 + LEF 36.71]
        end

        % ---- Geometry by DI: horizontal tail (Eq. 15.2) ------------------ %
        function v = get.S_ht(obj)
            % ★ NAME TRAP 1: geom.S_exposed_ht = 51.1486 ft^2, NOT geom.S_ht =
            % 108 (the FULL planform). After the Phase-2 geometry rename,
            % S_ht/S_vt/AR_ht/lambda_ht mean FULL planform on BOTH tiers, while
            % Raymer Eq. 15.2 wants the EXPOSED planform. Wiring geom.S_ht here
            % raises no error and returns a plausible wrong number.
            % 51.1486 is +2.605 % above the L2 value 49.8473 — an INTENTIONAL
            % consequence of GeomL3's Decision 1 (physical 18.5 ft HT span
            % primary, F16GeomL3.md §4), annotated BY DESIGN in the report and
            % never as an error.
            v = obj.geom.S_exposed_ht;
        end
        function v = get.F_w(obj)
            % Fuselage width at the HT intersection [Brandt Main!C32 max-width
            % upper-bound proxy — estimate; the real empennage is narrower].
            v = obj.geom.F_w;
        end
        function v = get.B_h(obj)
            v = obj.geom.B_h;              % 18.5 ft = 18 ft 6 in [USAF 3-view]
        end
        % NOTE: geom.AR_exposed_ht (2.114) and geom.lambda_exposed_ht (0.390) are
        % deliberately NOT wired. Raymer Eq. 15.2 takes only
        % (W_dg, N_z, S_ht, F_w, B_h) — no HT aspect ratio, no HT taper — so the
        % former AR_ht / lambda_ht inputs on this class were read by no equation
        % (grep-verified, zero matches) and are DELETED rather than re-pointed.
        % todo 2026-07-25 Phase 4 §P4-6.

        % ---- Geometry by DI: vertical tail (Eq. 15.3) -------------------- %
        function v = get.S_vt(obj)
            % ★ NAME TRAP 1 (VT half): geom.S_exposed_vt = 40.8897 ft^2, NOT
            % geom.S_vt = 60 (FULL planform).
            v = obj.geom.S_exposed_vt;
        end
        function v = get.AR_vt(obj)
            % ★ NAME TRAP 2: geom.AR_exposed_vt = 1.294, NOT geom.AR_vt = 1.6.
            % Eq. 15.3 carries AR_vt^0.223 on the EXPOSED panel that its S_vt and
            % lambda_vt also describe. Feeding the FULL-planform 1.6 is silent.
            % [physical construction value; T.O./USAF]
            v = obj.geom.AR_exposed_vt;
        end
        function v = get.lambda_vt(obj)
            % ★ NAME TRAP 2 (taper half): geom.lambda_exposed_vt = 0.437, NOT
            % geom.lambda_vt = 0.5. [physical; T.O./USAF]
            v = obj.geom.lambda_exposed_vt;
        end
        function v = get.Lambda_LE_vt(obj)
            % 47.5 deg — the PHYSICAL value [T.O. 1F-16A-1], an intentional L3
            % divergence from Brandt Main!H21 = 40 (todo 2026-07-24 GeomL3 §2).
            v = obj.geom.LE_sweep_vt;
        end
        function v = get.H_t(obj)
            v = obj.geom.H_t;              % 0 — conventional (non-T) tail [Raymer 6th ed. §15.3]
        end
        function v = get.H_v(obj)
            % 1 — "any nonzero denominator" for Eq. 15.3's (1 + H_t/H_v)^0.5.
            % ⚠ H_v = 0 gives NaN (at H_t = 0) or Inf; left UNGUARDED by
            % decision 6, and the property's own "any nonzero" documentation is
            % exactly what makes a 0 mis-entry look harmless. todo §P4-11.
            v = obj.geom.H_v;
        end
        function v = get.L_t(obj)
            % 22.0 ft [estimate; verify T.O.] — not derivable in-framework (no
            % MAC x/y-stations exist), so it is an unpinned estimate ON THE
            % GEOMETRY object rather than here.
            v = obj.geom.L_t;
        end
        function v = get.S_r(obj)
            v = obj.geom.S_r;              % 11.65 ft^2 rudder area [T.O. Fig. 1-2]
        end

        % ---- Geometry by DI: fuselage (Eq. 15.4) ------------------------- %
        function v = get.L_fus(obj)
            % 47.5 ft — PHYSICAL [T.O. 1F-16A-1], an intentional L3 divergence
            % from Brandt Main!B32 = 46.5 (todo 2026-07-24 GeomL3 §3).
            v = obj.geom.L_fus;
        end
        function v = get.D_fus(obj)
            % ★ NAME TRAP 3, the costliest one: geom.H_max_fuselage = 5.0 ft,
            % NOT geom.D_fus = 6.0 ft.
            % Weights' D_fus is Eq. 15.4's MAXIMUM STRUCTURAL DEPTH
            % [Brandt Main!D32; T.O. cross-section]. The geometry object's
            % Dependent D_fus is (W_max+H_max)/2 = 6.0, the Roskam Vol. II
            % Eq. 12.3 EQUIVALENT DIAMETER, used only for the fuselage
            % wetted-area cylinder. Same property name, different physical
            % quantity. Eq. 15.4 carries D_fus^0.849, so substituting 6.0 for 5.0
            % inflates the fuselage weight by +17.9 % ((6/5)^0.849) with no error.
            % docs/weights_parameter_usage.md §2; todo 2026-07-24 GeomL3 §5.
            v = obj.geom.H_max_fuselage;
        end
        function v = get.W_fus(obj)
            v = obj.geom.W_max_fuselage;   % 7.0 ft max width [Brandt Main!C32; T.O.]
        end

        % ---- Geometry by DI: flight controls (Eq. 15.17) ----------------- %
        function v = get.S_cs(obj)
            % 190 ft^2 total control-surface area [estimate, unpinned: flaperon +
            % HT + rudder + LEF] — an estimate on the GEOMETRY object.
            v = obj.geom.S_cs;
        end

        % ---- Propulsion by DI -------------------------------------------- %
        function v = get.T_max(obj)
            % SLS afterburning thrust from the injected engine, replacing a
            % frozen 23770 literal [Brandt Engn(s)!T_AB_SLS = Main!D29]. Feeds
            % Eq. 15.7 (mounts), Eq. 15.15 (starter) and Eq. 15.16 (fuel system),
            % so a thrust change now moves all three.
            v = obj.prop.T_SL;
        end
        function v = get.W_en(obj)
            % OFFICIAL dry engine weight: Raymer 7th ed. Eq. 10.10,
            %   W = 0.0637·T^1.1·M^0.25·exp(-0.81·BPR) = 2775.0210 lbf
            % [coefficient confirmed at raymer_data.md:38], implemented once in
            % PropL2.engine_weight_AB. Replaces a stored 3030 [estimate].
            %
            % ★ UNINSTALLED AT L3 — NO x1.3 (settled decision 1, user 2026-07-25).
            % WeightsL3.weight_engine_section adds mounts (15.7), firewall (15.8),
            % section (15.9), induction (15.10), tailpipe (15.11), cooling
            % (15.12), oil (15.13), controls (15.14) and starter (15.15)
            % individually, and the metabook's 1.3 installed/bare factor is a
            % lumped stand-in for exactly those items — applying both would
            % double-count the installation. Raymer's own nomenclature for
            % Eq. 15.9's W_en is the engine weight EACH (dry). x1.3 belongs at L2
            % and only at L2, which has no buildup.
            % Recorded: this choice moves L3 FURTHER from Brandt (OEW -21.40 % vs
            % the rejected x1.3 variant's -17.19 %). The variant's better
            % agreement is the evidence AGAINST it. todo §P4-1b.
            v = PropL2.engine_weight_AB(obj.prop.T_SL, obj.design_mach, obj.prop.bypass_ratio);
        end
        function v = get.W_en_brandt(obj)
            % ALTERNATE, comparison report ONLY — never summed into OEW.
            % 0.199·T_AB = 4730.2300 lbf [Brandt Wt!B11 = 4730.230000 (live); the
            % 0.199 literal is 'Engn(s)'!D22 (live), label 'Engn(s) Old'!C22 =
            % "Engine with AB:  Weng = "; readme_wt.md:230 attributes it to
            % Brandt 1997 Table 6.2 and states it IS the installed-engine formula,
            % so it gets NO x1.3 — todo §P4-1a].
            v = WeightsL2.engine_weight_brandt(obj.prop.T_SL);
        end
        function v = get.SFC_mission(obj)
            % Mission SFC for Eq. 15.16, evaluated at the REQUIREMENTS cruise
            % condition (36,000 ft / M 0.87) on the injected engine — settled
            % decision 2, user 2026-07-25. Replaces a frozen 0.70 [Brandt
            % Main!C30]. Weights builds the AircraftState itself; no state is
            % injected.
            % Live value 1.007116 1/hr. get_TSFC resolves to the MIL (dry),
            % UNINSTALLED path at that state.
            % ★ +43.87 % above Brandt's 0.70, ACCEPTED BY DECISION — two
            % deliberate causes: (a) a real cruise point vs Brandt's single
            % stored SLS constant, (b) uninstalled vs Brandt's already-installed
            % figure. Do NOT "correct" it. One consistency point in the
            % framework's favour: Brandt's own cruise row (Consts! row 24) is
            % pct_AB = 0, i.e. dry/mil, so the POWER SETTING matches his cruise
            % definition; only the condition and the installation basis differ.
            % Eq. 15.16 is weakly sensitive (((T·SFC)/1000)^0.249): the fuel
            % system moves 386.794 -> 423.465 lbf, +9.48 %.
            % ★ CORRECTION OF THE RECORD: the Phase-3 rationale for deleting this
            % JSON key — "SFC_mission duplicates what PropL2.get_TSFC computes" —
            % was FALSE. get_TSFC never returns 0.70 (0.903 at SLS/M0.01,
            % 1.007116 here). todo §P4-15.
            v = obj.prop.get_TSFC(AircraftState(obj.cruise_altitude_ft, obj.cruise_mach));
        end

        % ---- Landing weight (settled decision 4) ------------------------- %
        function v = get.W_l(obj)
            % Landing design gross weight for Eqs. 15.5/15.6 = 0.95 · obj.W_TO,
            % so the landing-gear group tracks the sizing loop.
            % ★ THE 0.95 FACTOR HAS NO CITATION IN THIS REPO — user-supplied,
            % logged OPEN at todo 2026-07-25 Phase 4 §P4-16. The equation and the
            % missing-citation record live on WeightsL3.landing_weight; this
            % getter only supplies obj.W_TO.
            % Replaces a frozen W_l = 20681 [Brandt Wt!B41 = 20680.700578,
            % =SUM(B16:B32)] — a back-calculated Brandt OUTPUT that made the whole
            % gear group insensitive to gross weight (§P4-17). Brandt's implied
            % ratio is 0.6591; 0.95·31377 = 29808.15 sits +44.14 % above his
            % figure, and the two are DEFINITIONALLY different quantities. The gap
            % is expected and logged, not an error to chase.
            v = WeightsL3.landing_weight(obj.requireWTO('W_l'));
        end

        % ---- Group totals (were NaN, review finding #12) ----------------- %
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
            % 15.7-15.15. The property name is inherited from the WeightsModelL3
            % contract; at L3 "installed" means "the whole installed propulsion
            % group", built item by item — not a x1.3 multiple of a bare weight.
            % NOT guarded on W_TO: WeightsL3.weight_engine_section declares its
            % second argument as `~`. The engine group is built from thrust and
            % component geometry, never from gross weight, so guarding it would
            % assert a dependency that does not exist.
            v = WeightsL3.weight_engine_section(obj, obj.W_TO).total;
        end
        function v = get.W_subsystems(obj)
            % Systems GROUP total, Eqs. 15.16-15.24. Contains NO landing-gear
            % term; OEW adds the gear separately (WeightsModelL3, §P4-10).
            v = WeightsL3.weight_systems(obj, obj.requireWTO('W_subsystems')).total;
        end

        function v = get.W_strake(obj)
            % ADDED 2026-07-29. k_strake * S_strake = 4.5 * 20 = 90.00 lbf
            % [Brandt Wt!H9 = 4.5*20 = 90.00 exact]. Pure area x density, no
            % W_TO dependence -- same pattern as F16WeightsL2's W_strake. See
            % the S_strake/k_strake property comment for the cross-model-borrow
            % rationale.
            v = obj.k_strake * obj.S_strake;
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Every §15.3.1 group weight is a function of Raymer's design gross
        %   weight W_dg = W_TO, and W_l = 0.95·W_TO likewise, so reading any of
        %   them before a gross weight exists is a caller error, not a NaN.
        %   Erroring with an identified message is the Phase-1f precedent
        %   (F16GeomL1.requireWTO): a silent NaN propagating into a weight
        %   statement is the failure mode Phase 1e was written to eliminate.
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

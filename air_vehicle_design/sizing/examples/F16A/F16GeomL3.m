classdef F16GeomL3 < GeometryModelL3
%F16GEOML3  F-16A Block 10 Level-3 geometry student class.
%
%   Inherits from GeometryModelL3 (abstract enforcer).  Every abstract method
%   is a single delegation line into the GeomL3 static toolbox (which itself
%   REUSES the GeomL2 / GeometryBase statics -- the only new formulas in the
%   tier are GeometryBase.compute_Amax_elliptical and
%   GeometryBase.compute_nacelle_diameter).
%
%   2026-07-24: GeomL3 (re)introduced (user decision, reversing the 2026-07-22
%   "Geometry has no L3").
%   2026-07-25 (PHASE 2, locked user decision): promoted from a weights-only
%   tier to the FULL L3 geometry tier consumed by L3 geometry + aero + weights.
%   Authoritative spec: examples/F16A/F16GeomL3.md.  This is the HIGHER-fidelity
%   PHYSICAL / T.O.-geometry tier: where a physical/T.O. value differs from
%   Brandt, GeomL3 uses the physical one (VT LE sweep 47.5 deg, L_fus 47.5 ft,
%   HT span B_h 18.5 ft as the PRIMARY span, exposed HT/VT AR 2.114/1.294 and
%   tapers 0.390/0.437).  Those divergences from GeomL2 are INTENTIONAL fidelity
%   differences, not errors (locked decision, VnV/BrandtF16A/todo.md 2026-07-24
%   GeomL3 + 2026-07-25 Phase 2).
%
%   CONSTRUCTOR SIGNATURE: F16GeomL3(json_path, prop).
%   Argument order chosen (2026-07-25) as path-first: json_path keeps position 1
%   exactly as before Phase 2, so every call site takes an APPENDED argument
%   rather than a reorder; and the class is fundamentally JSON-driven with a
%   single injected collaborator, which reads naturally as "build from this
%   spec, using that engine".  Both arguments are REQUIRED -- there is no
%   optional/defaulted injection, because a silent default is the exact defect
%   class Phase 2 removes.
%
%   ============================================================================
%   INPUT vs DERIVED -- the optimization-ready pattern.  examples/F16A/F16GeomL2.m
%   is the reference implementation; its header carries the full rationale.
%
%     (1) INPUTS -- a plain, mutable `properties` block: the 38 genuine
%         design-variable spec numbers an optimizer varies, plus the 20x3
%         NORMALIZED fuselage frame table.  The constructor sets them once from
%         the .geometry block of f16a_L3.json.
%     (2) DERIVED -- a `properties (Dependent)` block: the 45 quantities
%         COMPUTED from those inputs (spans, chords, MAC, sweep-station
%         conversions, exposed/wetted areas, t/c means, equivalent + nacelle
%         diameters, the area-rule intermediates, Amax, totals).  Each has a
%         `get.<name>` recomputing live
%         from the current inputs on every read via the GeomL3 / GeomL2 /
%         GeometryBase statics.  There is NO stored/cached copy, so a derived
%         value can never go stale: the instant an input changes, every
%         dependent read reflects it.  Derived properties are read-only (no
%         set-method) -- assigning to one errors, which is correct, they are
%         outputs.
%
%   Nothing derivable is stored.  FIVE quantities that were stored inputs before
%   Phase 2 are now Dependent and must never be re-frozen (F16GeomL3.md §3):
%   AR_ht, S_exposed_ht, S_exposed_vt, tc_ht, tc_vt.  A sixth left geometry
%   entirely -- see PROPULSION INJECTION below.
%   ============================================================================
%
%   PHASE-2 RENAME (F16GeomL3.md §2) -- AR_ht / lambda_ht / S_ht / S_vt now mean
%   FULL planform on BOTH tiers, exactly as on GeometryModelL2; the exposed
%   values live under AR_exposed_ht / lambda_exposed_ht / AR_exposed_vt /
%   lambda_exposed_vt.  This removes a live silent-wrong-answer hazard: the aero
%   L3 reference-length getter calls GeometryBase.compute_mac(g.c_root_ht,
%   g.lambda_ht), and Raymer 7th ed. Eq. 7.8 needs the FULL-planform taper that
%   goes with the chord it is handed -- under the old naming an injected
%   F16GeomL3 would have fed the exposed 0.390 where 0.2275 belongs, giving a
%   wrong HT MAC, Reynolds number and Eq. 12.30 form factor with no error and no
%   warning.  Residual traps a weights DI must still name explicitly (todo
%   2026-07-24 GeomL3 §5): read S_exposed_ht / S_exposed_vt (51.15 / 40.89), NOT
%   S_ht / S_vt (108 / 60); and read H_max_fuselage (5.0, the Raymer Eq. 15.4
%   structural depth), NOT the Dependent D_fus (6.0, the Roskam Eq. 12.3
%   equivalent diameter).
%
%   DECISION 1 (user, 2026-07-25 -- option B, "physical span primary"): the whole
%   HT planform derives from the S_ht=108 + B_h=18.5 INPUT PAIR, so AR_ht is
%   DERIVED = B_h^2/S_ht = 3.1690 and is NOT a stored property.  Rationale worth
%   preserving: area and span are what a 3-view measures; aspect ratio is
%   definitional.  A stored AR_ht=3.0 alongside both S_ht and B_h would be
%   self-contradictory (sqrt(3.0*108) = 18.0 ft, not 18.5) and would go stale
%   the instant an optimizer moved the span.  Brandt Main!C19 = 3.0 is now a
%   comparison reference, not an input.  Consequences, all annotated BY DESIGN in
%   the comparison report: c_root_ht 9.5118, c_tip_ht 2.1639, S_exposed_ht
%   51.1486 (+2.611 % vs Brandt Geom!8 = 49.8473), HT MAC 6.6085 (-2.703 %),
%   QC_sweep_ht 32.6400 deg, TE_sweep_ht 2.5617 deg (L2 gives -0.0002, matching
%   Brandt Main!C27 -- the higher derived AR aft-sweeps the L3 HT trailing edge).
%
%   DECISION 2 (user, 2026-07-25): the OFFICIAL L3 lifting-surface wetted-area
%   formula is Roskam Vol. II Eq. 12.1 fed the T.O. root/tip t/c splits (the same
%   official choice L2 makes).  Brandt's uniform-t/c Geom!B13 form stays
%   reachable via GeomL2.compute_wet_planform(S_exposed, tc_ht|tc_vt) as a
%   COMPARISON-REPORT ALTERNATE ROW ONLY, never as the computed value.  Recorded
%   deliberately: this moves L3 FURTHER from Brandt's ground truth (wing
%   +1.11 %, HT +4.47 %, VT +1.78 %) and that is CORRECT -- Brandt's GT figures
%   are the output of his own coarser formula fed his own inputs, so the
%   alternate matches them almost exactly BY CONSTRUCTION.  See GeomL3.m header.
%
%   VERTICAL-TAIL SWEEP FORM: QC_sweep_vt/TE_sweep_vt use
%   GeometryBase.convert_sweep_panel (SINGLE-PANEL, 2/AR).  A vertical tail is
%   one panel -- root->tip spans the full b_vt -- so the mirrored 4/AR form
%   double-counts the taper term.  Wing and HT are mirrored and keep
%   convert_sweep.
%
%   PROPULSION INJECTION (Phase 2/3a): engine SLS thrust is not geometry spec
%   data and is no longer in the .geometry JSON.  A propulsion object is
%   injected (required) and T_AB_SLS_lb is Dependent on prop.T_SL, so the
%   nacelle diameter D_inlet -- and hence 155.57 ft^2 of duct wetted area, and
%   hence CD0 -- tracks a thrust change instead of staying pinned to a stale
%   23,770 lbf copy.  At the L3 rung the injected object is an F16PropL2: there
%   is NO L3 propulsion tier (locked decision 2026-07-25), and anything
%   reporting an L3 propulsion number must say so.  T_AB_SLS_lb and `prop` are
%   deliberately concrete-only, not part of the GeometryModelL3 abstract
%   contract -- they are engine, not airframe, data (same judgment F16GeomL2
%   already documents), and another concrete class may size its duct otherwise.
%
%   Verified live 2026-07-25 (mcp__matlab__evaluate_matlab_code) against a fresh
%   F16GeomL3(f16a_spec_path(3), F16PropL2(f16a_spec_path(2))):
%     Wing  S_wet 396.3767 ft^2   (Brandt Geom!B14 = 392.0204, +1.11 %)
%     HT    S_wet 104.0348 ft^2   (Brandt Geom!B16 =  99.5848, +4.47 %)
%     VT    S_wet  83.1399 ft^2   (Brandt Geom!B17 =  81.6894, +1.78 %)
%     Fuse  S_wet 749.1337 ft^2   (Roskam Eq. 12.3, D_fus=6.0, L_fus=47.5;
%                                  Brandt low-fi B3 = 730.422, high-fi D23 = 676.33)
%     Duct  S_wet 155.5664 ft^2   (frustum degenerates to cylinder, D = 3.5370 ft)
%     Total       1488.2515 ft^2  (Brandt corrected whole-aircraft 1331.134,
%                                  +11.80 % -- NOT like-for-like: Brandt's total
%                                  also carries strake 39.956 + nacelle 41.515
%                                  terms this framework has no component for,
%                                  partly offset by our 47.5 ft fuselage. Must
%                                  not be reported as an agreement check.)
%     Amax        24.7037 ft^2    (AREA-RULED buildup, sub-step 2h; Brandt
%                                  Geom!B20/H47 = 25.110556, -1.62 %.  The
%                                  former envelope-ellipse 27.4889 (+9.47 %, a
%                                  different quantity) is GONE from this tier
%                                  and stays at L2.  ROUND-TRIP CONTROL: with
%                                  L_fus set to Brandt's 46.5 this returns
%                                  25.110534, -0.000 %.)
%
%   AREA-RULED Amax (sub-step 2h, locked user decision 2026-07-25).  Amax is no
%   longer (pi/4)*W_max*H_max -- the LOW-fidelity fuselage-only definition per
%   readme_geom.md §7, which had been sitting in the finest tier and inflating
%   the Raymer Eq. 12.44 wave term by +23.15 %.  It is now Brandt's
%   whole-aircraft buildup [Geom!H26:H45 -> H47], MAX over the 20 frame
%   stations of fuselage + wing + HT + VT + nacelle cross-sections less an
%   n_engines*pi*D_engine^2/5 flow-through deduction.  Six new INPUTS pay for
%   it -- x_apex_wing, x_le_ht, x_le_vt, x_inlet, n_engines and the NORMALIZED
%   frames_normalized table; everything else it needs (exposed root chords,
%   exposed spans, Xexp stations, L_engine, x_nacelle_aft) is DERIVED and must
%   stay so (todo §16.1).  Two citation gaps are stated rather than papered
%   over and remain OPEN: the affine frame-table rescaling has no textbook
%   source (todo §4), and the "/5" divisor is an unjustified bare literal in
%   the workbook (todo §5).  The STRAKE is deliberately absent and Brandt's two
%   documented strake bugs are DECLINED -- provably worth 0.000 % of Amax here
%   (todo §16.2/§16.3).
%
%   Inheritance: GeometryBase -> GeometryModelL3 -> F16GeomL3
%   (GeomL3 is the static toolbox alongside, NOT in the chain.)
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, Main/Geom/Engn(s) tabs, reproduced in
%       examples/F16A/f16a_L3.json (.geometry, per-value _src fields).
%       CITATION CORRECTION 2026-07-25 (F16GeomL3.md §2 is authoritative, zero
%       computed values change): Main row 20 = 'Taper Ratio', row 21 =
%       'Sweep, deg', row 22 = 'NACA 4-digit' (last two digits = % chord t/c).
%       The repo previously cited row 21 for taper, row 20 for sweep and row 24
%       for t/c -- row 24 is 'Y Location' with B24/C24 EMPTY.
%     [TO]     T.O. 1F-16A-1 -- physical lengths/sweeps and the HT/VT biconvex
%       root/tip t/c splits.
%     [USAF]   USAF 3-view -- HT span B_h = 18 ft 6 in.

    % ===================================================================== %
    % INPUTS -- 38 numeric physical / T.O. spec values plus the 20x3 normalized
    % fuselage frame table (60 numbers) (mutable; set once by
    % the constructor from f16a_L3.json .geometry, may be varied by an
    % optimizer) plus the injected propulsion object.  Every DERIVED
    % (Dependent) property below recomputes live from these.
    % Authoritative table with all citations: F16GeomL3.md §2.
    % ===================================================================== %
    properties
        % -- Wing (full-planform inputs; chords/MAC/sweeps/areas are DERIVED) %
        S_ref          = 300       % ft^2  reference wing area   [Brandt Main!B18]
        AR_wing        = 3.0       % --    aspect ratio          [Brandt Main!B19]
        lambda_wing    = 0.2275    % --    FULL taper ratio      [Brandt Main!B20]
        LE_sweep_wing  = 40        % deg   LE sweep              [Brandt Main!B21]
        tc_wing        = 0.04      % --    uniform t/c; wing is genuinely uniform-tc (no root/tip split exists), so tc_r_wing/tc_t_wing mirror it as Dependent [Brandt Main!B22 'NACA 4-digit' = 1404 -> last two digits = 4% chord; corroborated TO 1F-16A-1 Fig. 1-2, NACA 64A204]
        S_csw          = 68.03     % ft^2  wing control-surface area = flaperon 31.32 + LEF 36.71 [TO 1F-16A-1 Fig. 1-2]
        x_apex_wing    = 17.786    % ft    wing apex (root LE) x-station aft of the nose [Brandt Main!B23 'X Location'] -- ADDED sub-step 2h for the area-ruled Amax; fixes Xexp_wing. Not derivable in-framework (Brandt pre-computes it as x_MAC_qc - y_MAC*tan(sweep_LE), readme_geom.md §2, and no MAC x/y stations exist here). PRECISION NOTE: a live Main-tab read logs 17.7858, 0.0011% below this; 17.786 is the scoped value and must not be "corrected" without a decision.

        % -- Horizontal tail: FULL planform from the S_ht + B_h pair --------- %
        %    (Decision 1 -- AR_ht is DERIVED, deliberately absent here.)
        S_ht              = 108.0   % ft^2  FULL reference planform area [Brandt Main!C18]
        B_h               = 18.5    % ft    HT full span (18 ft 6 in), PRIMARY span [USAF 3-view]
        lambda_ht         = 0.2275  % --    FULL taper ratio      [Brandt Main!C20]
        LE_sweep_ht       = 40      % deg   LE sweep              [Brandt Main!C21]
        tc_r_ht           = 0.060   % --    root t/c, biconvex ~6%   [TO 1F-16A-1 Sec. I] -- this pair is now the SINGLE t/c basis (locked decision 6): the former uniform tc_ht = 0.04 input [Brandt Main!C22 'NACA 4-digit' = '0004'; citation corrected 2026-07-25 from C24, which is the empty 'Y Location' cell] is gone, and tc_ht is the Dependent mean 0.0475
        tc_t_ht           = 0.035   % --    tip  t/c, biconvex ~3.5% [TO 1F-16A-1 Sec. I]
        F_w               = 7.0     % ft    fuselage width at HT intersection; Raymer Eq. 15.2 [Brandt Main!C32 max-width upper-bound proxy -- estimate, real empennage width is narrower]
        AR_exposed_ht     = 2.114   % --    EXPOSED-planform AR, physical construction value; Raymer Eq. 15.2 weights input [TO/USAF -- NOT reconcilable with Brandt exposed geometry (clean-derived 2.4274, +14.8%); todo 2026-07-24 GeomL3 §1]
        lambda_exposed_ht = 0.390   % --    EXPOSED-planform taper, physical [TO/USAF -- clean-derived 0.3252, -16.6%; same todo item]
        x_le_ht           = 36.0    % ft    HT root LE x-station aft of the nose [Brandt Main!C23 'X Location', live-read 2026-07-25] -- ADDED sub-step 2h; fixes Xexp_ht = 38.9368 [Brandt Geom!B8 = 38.93685]. Currently worth 0.000% of Amax (the HT section begins aft of the governing station) -- a geometric fact for this configuration, NOT a reason to omit it: the governing station can migrate under mutation (todo 2026-07-25 Phase 2 §16.5)

        % -- Vertical tail: FULL planform, single panel ---------------------- %
        S_vt              = 60.0    % ft^2  FULL reference planform area [Brandt Main!H18]
        AR_vt             = 1.6     % --    FULL aspect ratio (single panel) [Brandt Main!H19]
        lambda_vt         = 0.5     % --    FULL taper ratio      [Brandt Main!H20]
        LE_sweep_vt       = 47.5    % deg   LE sweep, PHYSICAL [TO 1F-16A-1] -- INTENTIONAL divergence from L2's 40 [Brandt Main!H21] (todo 2026-07-24 GeomL3 §2)
        tc_r_vt           = 0.053   % --    root t/c, biconvex ~5.3% [TO 1F-16A-1 Sec. I] -- this pair is now the SINGLE t/c basis (locked decision 6): the former uniform tc_vt = 0.04 input [Brandt Main!H22 'NACA 4-digit' = '0004'; citation corrected 2026-07-25 from H24, which is 'Y Location'] is gone, and tc_vt is the Dependent mean 0.0415
        tc_t_vt           = 0.030   % --    tip  t/c, biconvex ~3.0% [TO 1F-16A-1 Sec. I]
        S_r               = 11.65   % ft^2  rudder area           [TO 1F-16A-1 Fig. 1-2]
        H_t               = 0       % ft    HT height above fuselage CL; F-16 conventional (non-T) tail, H_t/H_v = 0 [Raymer 6th ed. §15.3]
        H_v               = 1       % ft    any nonzero denominator for H_t/H_v [Raymer 6th ed. §15.3]
        AR_exposed_vt     = 1.294   % --    EXPOSED-planform AR, physical; Raymer Eq. 15.3 weights input [TO/USAF -- the one of the four that reconciles: clean-derived 1.3025, +0.7%]
        lambda_exposed_vt = 0.437   % --    EXPOSED-planform taper, physical [TO/USAF -- clean-derived 0.5731, +31.1%; todo 2026-07-24 GeomL3 §1]
        x_le_vt           = 36.0    % ft    VT root LE x-station aft of the nose [Brandt Main!H23 'X Location'] -- ADDED sub-step 2h; fixes Xexp_vt = 38.7283 (vs Brandt Geom!B10 = 38.09775, the SAME intentional 47.5-vs-40 deg sweep divergence, not a new error). Like the HT, worth 0.000% of Amax today (todo §16.5)

        % -- Fuselage / whole aircraft --------------------------------------- %
        L_fus          = 47.5      % ft    fuselage length, PHYSICAL [TO 1F-16A-1] -- INTENTIONAL divergence from L2's 46.5 [Brandt Main!B32] (todo 2026-07-24 GeomL3 §3). Feeds the fuselage Reynolds number and Roskam Eq. 12.3; DISTINCT from L_aircraft. Since sub-step 2h it ALSO stretches the normalized frame table, hence Amax.
        W_max_fuselage = 7.0       % ft    max width             [Brandt Main!C32 / TO 1F-16A-1]
        H_max_fuselage = 5.0       % ft    max DEPTH (weights' "D_fus", the Raymer Eq. 15.4 structural depth -- NOT the Dependent D_fus) [Brandt Main!D32; TO 1F-16A-1 cross-section]

        % -- Fuselage cross-section distribution (area-ruled Amax) ----------- %
        %    (N,3) NORMALIZED frame table, columns [x_over_L, w_over_Wmax,
        %    h_over_Hmax], Brandt's nose->tail frame order.  ADDED sub-step 2h
        %    (variant D, locked user decision 2026-07-25): stored NORMALIZED so
        %    that L_fus / W_max_fuselage / H_max_fuselage above rescale it --
        %    that rescaling is what puts Amax back under the control of the
        %    fuselage envelope (with the raw table W_max moved Amax the WRONG
        %    WAY and H_max not at all, todo §16.5).  Raw numbers are Brandt's
        %    [Main!A34:F53; readme_geom.md §2] divided by his own envelope
        %    (46.5 / 7.0 / 5.0); the z_chine and z_center columns are dropped
        %    because they cancel exactly out of the AREA (readme_geom.md §4.2).
        %    ★ The affine-rescaling assumption behind this is UNCITED -- see
        %    GeomL3.denormalize_frames and todo 2026-07-25 Phase 2 §4.
        %    Full provenance: f16a_L3.json .geometry.fuselage._frames_normalized_src.
        %    A stored distribution is unavoidable: the fuselage supplies 52.7%
        %    of the governing station's total, and the only zero-new-input
        %    alternative (constant section from the 3 envelope scalars) makes
        %    Amax WORSE than the ellipse it replaces (+20% to +41%, todo §16.1).
        frames_normalized = zeros(0,3)
        L_aircraft     = 47.65     % ft    OVERALL aircraft length; feeds ONLY the Raymer 6th ed. Eq. 12.44 Sears-Haack term as (Amax/l)^2. Not derivable in-model (no nose-boom/tailcone x-stations). PROVENANCE CAVEAT, carried from the JSON's _TODO_overall_length_ft: the VALUE is user-approved (2026-07-25) as the published F-16A airframe length 47 ft 7.75 in = 47.6458 ft (47.65 is a +0.009% rounding), but the CITATION IS NOT PINNED -- no overall-length figure appears anywhere in air_vehicle_design/sizing/ (grepped 2026-07-25). Brandt Geom!B21 = 48.303947 does NOT pin it: that cell is a MAX() over his component x-station columns, i.e. an EXTENT of his own layout, a different quantity (report row annotated 'definitional', -1.35%). STANDING OPEN item: VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §6.

        % -- Inlet / duct (airframe side only) ------------------------------- %
        L_duct         = 14.0      % ft    inlet-duct length (inlet lip -> compressor face) -- a genuine AIRFRAME input [Brandt Main!F32, label Main!E32 = 'Compr Face'; readme_geom.md §3]
        x_inlet        = 15.0      % ft    inlet-lip x-station aft of the nose [Brandt Main!F31, label Main!E31 = 'Inlet(s):', live-verified over Excel COM 2026-07-25]. ★ TRAP, recorded so nobody "corrects" it: the read-only GroundTruth/f16a_geometry.json key inlet_x_ft = 14.0 is MISLABELLED -- 14.0 is Main!F32, the DUCT LENGTH already stored above, not an x-station. BrandtGeometry.nacelleFrameArea consumes the mislabel, so its nacelle range [14.0, 43.9166] is 1.0 ft low at BOTH ends vs the live chain Geom!C480->C482->C484 = [15.0, 44.9166]. Numerically identical over these 20 stations (luck of the spacing); only the live chain is defensible on any other grid. todo 2026-07-25 Phase 2 §18
        n_engines      = 1         % --    number of engines [Brandt Main!B28, live-confirmed inside the Geom!H47 and Geom!AE31 formulas]. Lives in GEOMETRY only because the Amax flow-through deduction needs it and no propulsion class exposes an engine count today (F16PropL2 exposes engine_type, T_SL, T_SL_wet, T_SL_mil, T_t4_max_F, TSFC_install_factor, TR -- no count). If a propulsion-side n_engines is added it should move to .propulsion and arrive by DI, exactly as T_AB_SLS_lb already does. todo §16.1 row 5

        % -- Configuration --------------------------------------------------- %
        L_t            = 22.0      % ft    tail arm, wing 1/4-MAC -> HT 1/4-MAC [estimate; verify TO 1F-16A-1] -- derivable only if component apex-x inputs are added (Brandt Main row 23 X-locations); todo 2026-07-24 GeomL3 §6
        S_cs           = 190       % ft^2  total control-surface area = flaperon + HT + rudder + LEF [estimate] -- unpinned; no control-surface geometry exists in GeomL2/GeometryBase

        % -- Injected collaborator (NOT numeric spec data) ------------------- %
        prop                       % (1,1) PropulsionBase -- injected propulsion object; supplies prop.T_SL to the Dependent T_AB_SLS_lb (Phase 2/3a). At the L3 rung this is an F16PropL2: no L3 propulsion tier exists (locked decision 2026-07-25).

        % -- Control-surface areas (sizing-loop OUTPUTS, not JSON inputs) ---- %
        % NaN until SizingLoopL2 sets them (src/sizing/SizingLoopL2.m,
        % src/sizing/ControlSurfaceSizer.m -- docs/subplans/08_sizing.md).
        % Plain (not Dependent), same rationale as F16GeomL2's identically-
        % named properties (see that class's header): ControlSurfaceSizer
        % computes them externally each iteration, so there is no closed-form
        % get.S_ail/etc. Distinct from S_r/S_csw/S_cs above, which are
        % separate fixed WEIGHTS-equation inputs (T.O./estimate figures), not
        % sizing-loop outputs -- no naming collision, but don't conflate them.
        S_ail  = NaN   % ft^2  aileron area  [Raymer 6th ed. Fig. 6.3]
        S_elev = NaN   % ft^2  elevator area [Raymer 6th ed. Table 6.5] -- 0 for the F-16 (all-moving stabilator, no separate elevator; see F16 ControlSurfaceSizer wiring)
        S_rud  = NaN   % ft^2  rudder area   [Raymer 6th ed. Table 6.5]
    end

    % ===================================================================== %
    % DERIVED -- 45 quantities computed live from the inputs above on every
    % read (no cache, never stale).  Read-only: assigning to any of these
    % errors (no set-method), which is correct -- they are outputs.
    % Authoritative table with all citations: F16GeomL3.md §3.
    % ===================================================================== %
    properties (Dependent)
        % -- Wing ------------------------------------------------------------ %
        b_wing         % ft    GeometryBase.compute_span(AR_wing, S_ref)
        c_root_wing    % ft    GeometryBase.compute_root_chord [Raymer 7th ed. Eq. 7.6]
        c_tip_wing     % ft    GeometryBase.compute_tip_chord  [Raymer 7th ed. Eq. 7.7]
        cbar_wing      % ft    GeometryBase.compute_mac        [Raymer 7th ed. Eq. 7.8]; L3 aero l_ref_comp(1)
        QC_sweep_wing  % deg   Lambda_c/4, GeometryBase.convert_sweep(x=0.25) -- MIRRORED 4/AR
        TE_sweep_wing  % deg   GeometryBase.convert_sweep(x=1.0); matches Brandt Main!B27 = -0.00024343
        tc_r_wing      % --    mirrors tc_wing (wing modeled uniform-tc) (weights' "tc_root")
        tc_t_wing      % --    mirrors tc_wing; see tc_r_wing
        S_exposed_wing % ft^2  GeomL2.compute_S_exposed_horizontal (weights' "S_w")
        S_wet_wing     % ft^2  get_S_wet_wing() [Roskam Vol. II Eq. 12.1]

        % -- Horizontal tail (all of it from the S_ht + B_h pair) ------------ %
        AR_ht          % --    FULL aspect ratio = B_h^2/S_ht = 3.1690 (Decision 1); definitional
        b_ht           % ft    mirrors B_h (the PRIMARY span)
        c_root_ht      % ft    GeometryBase.compute_root_chord [Raymer 7th ed. Eq. 7.6]
        c_tip_ht       % ft    GeometryBase.compute_tip_chord  [Raymer 7th ed. Eq. 7.7]
        QC_sweep_ht    % deg   GeometryBase.convert_sweep(x=0.25) -- MIRRORED 4/AR
        TE_sweep_ht    % deg   GeometryBase.convert_sweep(x=1.0)
        tc_ht          % --    uniform t/c = (tc_r_ht + tc_t_ht)/2 = 0.0475
        S_exposed_ht   % ft^2  GeomL2.compute_S_exposed_horizontal (weights' "S_ht")
        S_wet_ht       % ft^2  get_S_wet_HT() [Roskam Vol. II Eq. 12.1]

        % -- Vertical tail --------------------------------------------------- %
        b_vt           % ft    sqrt(S_vt*AR_vt) -- full single-panel span, NOT halved [readme_geom.md §4.3]
        c_root_vt      % ft    GeometryBase.compute_root_chord [Raymer 7th ed. Eq. 7.6]
        c_tip_vt       % ft    GeometryBase.compute_tip_chord  [Raymer 7th ed. Eq. 7.7]
        QC_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=0.25) -- SINGLE-PANEL 2/AR
        TE_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=1.0)  -- SINGLE-PANEL 2/AR
        tc_vt          % --    uniform t/c = (tc_r_vt + tc_t_vt)/2 = 0.0415
        S_exposed_vt   % ft^2  GeomL2.compute_S_exposed_vertical (weights' "S_vt")
        S_wet_vt       % ft^2  get_S_wet_VT() [Roskam Vol. II Eq. 12.1]

        % -- Fuselage / whole aircraft --------------------------------------- %
        L_fuselage     % ft    mirrors L_fus (duplicate name kept for GeometryModelL2 contract parity)
        D_fus          % ft    (W_max+H_max)/2 equivalent diameter -- Roskam Eq. 12.3 term ONLY, NOT the weights depth
        Amax           % ft^2  AREA-RULED whole-aircraft maximum, GeomL3.get_Amax [Brandt Geom!H26:H45 -> H47] -- NOT the envelope ellipse (that is L2's, and stays there)

        % -- Inlet / duct ---------------------------------------------------- %
        T_AB_SLS_lb    % lbf   = prop.T_SL (INJECTED) [Brandt Engn(s)!T_AB_SLS = Main!D29 = 23770]
        D_inlet        % ft    GeometryBase.compute_nacelle_diameter(T_AB_SLS_lb) [Brandt Engn(s) D_nac; readme_geom.md §3]
        D_exit         % ft    = D_inlet (Brandt models the nacelle as a constant-diameter cylinder)
        L_engine       % ft    GeomL3.compute_engine_length(D_inlet) = 4.5*D [Brandt Geom!D475]
        x_nacelle_aft  % ft    x_inlet + L_duct + L_engine [Brandt Geom!C484 = C482 + D475]

        % -- Area-ruled Amax intermediates (all derivable -- todo §16.1) ----- %
        c_exp_root_wing % ft   exposed root chord [Brandt Geom!F7  = 13.3564, exact]
        c_exp_root_ht   % ft   exposed root chord [cf. Brandt Geom!F8 = 6.8391; L3 gives 6.7315 via Decision 1's span]
        c_exp_root_vt   % ft   exposed root chord [Brandt Geom!F10 = 7.1233, exact]
        G_hs_exp_wing   % ft   exposed half-span = b/2 - W_max/2   [Brandt Geom!G7  = 11.5]
        G_hs_exp_ht     % ft   exposed half-span = B_h/2 - W_max/2 [cf. Geom!G8 = 5.5; L3 gives 5.75]
        G_hs_exp_vt     % ft   exposed span (single panel) = b_vt - H_max/2 [Brandt Geom!G10 = 7.298]
        Xexp_wing       % ft   exposed-root LE station [Brandt Geom!B7  = 20.72268]
        Xexp_ht         % ft   exposed-root LE station [Brandt Geom!B8  = 38.93685]
        Xexp_vt         % ft   exposed-root LE station [cf. Geom!B10 = 38.09775 at his 40 deg; L3 gives 38.7283 at 47.5 deg]

        % -- Total ----------------------------------------------------------- %
        S_wet          % ft^2  wing + HT + VT + fuselage + duct (duct term ADDED in Phase 2)
    end

    methods

        function obj = F16GeomL3(json_path, prop)
        %F16GEOML3  Construct from a required unified L3 input JSON path
        %   (f16a_spec_path(3)) plus a required injected propulsion object.
        %   Reads the JSON's .geometry block.  NO silent default on either
        %   argument: the path must be supplied, and the propulsion object must
        %   be supplied (a defaulted injection is the defect class Phase 2
        %   removes -- it would silently re-freeze the engine thrust).  Sets
        %   ONLY the input properties; every derived quantity is produced live
        %   by its Dependent getter.
        %
        %   prop must be a PropulsionBase subclass; only prop.T_SL is read (the
        %   SLS afterburning thrust), and only to size the nacelle diameter.
        %   At the L3 rung pass an F16PropL2 -- there is no L3 propulsion tier
        %   (locked decision 2026-07-25).
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                prop      (1,1) PropulsionBase
            end
            G = jsondecode(fileread(json_path)).geometry;

            obj.prop = prop;   % injected: supplies the Dependent T_AB_SLS_lb

            % ---- wing -------------------------------------------------- %
            obj.S_ref         = G.wing.S_ft2;         % [Brandt Main!B18]
            obj.AR_wing       = G.wing.AR;            % [Brandt Main!B19]
            obj.lambda_wing   = G.wing.taper;         % [Brandt Main!B20]
            obj.LE_sweep_wing = G.wing.sweep_LE_deg;  % [Brandt Main!B21]
            obj.tc_wing       = G.wing.tc_ratio;      % [Brandt Main!B22, NACA 4-digit 1404]
            obj.S_csw         = G.wing.S_csw_ft2;     % [TO 1F-16A-1 Fig. 1-2]
            obj.x_apex_wing   = G.wing.x_apex_ft;     % [Brandt Main!B23 'X Location']

            % ---- horizontal tail (FULL planform + physical exposed set) - %
            %      No AR key by design: S_ft2 + span_ft fix the planform and
            %      AR_ht is Dependent (Decision 1, F16GeomL3.md §4).
            obj.S_ht              = G.horizontal_tail.S_ft2;         % [Brandt Main!C18]
            obj.B_h               = G.horizontal_tail.span_ft;       % [USAF 3-view] PRIMARY span
            obj.lambda_ht         = G.horizontal_tail.taper;         % [Brandt Main!C20]
            obj.LE_sweep_ht       = G.horizontal_tail.sweep_LE_deg;  % [Brandt Main!C21]
            obj.tc_r_ht           = G.horizontal_tail.tc_root;       % [TO 1F-16A-1 Sec. I]
            obj.tc_t_ht           = G.horizontal_tail.tc_tip;        % [TO 1F-16A-1 Sec. I]
            obj.F_w               = G.horizontal_tail.F_w_ft;        % [Brandt Main!C32 proxy]
            obj.AR_exposed_ht     = G.horizontal_tail.AR_exposed;    % [TO/USAF, physical]
            obj.lambda_exposed_ht = G.horizontal_tail.taper_exposed; % [TO/USAF, physical]
            obj.x_le_ht           = G.horizontal_tail.x_le_ft;       % [Brandt Main!C23 'X Location']

            % ---- vertical tail (FULL planform + physical exposed set) --- %
            obj.S_vt              = G.vertical_tail.S_ft2;           % [Brandt Main!H18]
            obj.AR_vt             = G.vertical_tail.AR;              % [Brandt Main!H19]
            obj.lambda_vt         = G.vertical_tail.taper;           % [Brandt Main!H20]
            obj.LE_sweep_vt       = G.vertical_tail.sweep_LE_deg;    % 47.5 [TO 1F-16A-1]
            obj.tc_r_vt           = G.vertical_tail.tc_root;         % [TO 1F-16A-1 Sec. I]
            obj.tc_t_vt           = G.vertical_tail.tc_tip;          % [TO 1F-16A-1 Sec. I]
            obj.S_r               = G.vertical_tail.rudder_area_ft2; % [TO 1F-16A-1 Fig. 1-2]
            obj.H_t               = G.vertical_tail.H_t_ft;          % [Raymer 6th ed. §15.3]
            obj.H_v               = G.vertical_tail.H_v_ft;          % [Raymer 6th ed. §15.3]
            obj.AR_exposed_vt     = G.vertical_tail.AR_exposed;      % [TO/USAF, physical]
            obj.lambda_exposed_vt = G.vertical_tail.taper_exposed;   % [TO/USAF, physical]
            obj.x_le_vt           = G.vertical_tail.x_le_ft;         % [Brandt Main!H23 'X Location']

            % ---- fuselage / whole aircraft ----------------------------- %
            obj.L_fus          = G.fuselage.length_ft;     % 47.5 [TO 1F-16A-1]
            obj.W_max_fuselage = G.fuselage.max_width_ft;  % [Brandt Main!C32]
            obj.H_max_fuselage = G.fuselage.max_depth_ft;  % [Brandt Main!D32]
            obj.L_aircraft     = G.overall_length_ft;      % 47.65 -- citation NOT pinned, todo §6

            % ---- fuselage cross-section distribution ------------------- %
            %      Flattened from the JSON's per-frame objects into the (N,3)
            %      numeric table [x_over_L, w_over_Wmax, h_over_Hmax] the
            %      area-rule statics take.  The `frame` field is Brandt's 1..20
            %      index label -- traceability only, not a design value, so it
            %      is deliberately not stored.  NOTHING is rescaled here: the
            %      denormalization is done live inside GeomL3.get_Amax, so an
            %      optimizer moving L_fus / W_max / H_max moves Amax.
            fr = G.fuselage.frames_normalized;             % [Brandt Main!A34:F53, normalized]
            obj.frames_normalized = [ [fr.x_over_L].', ...
                                      [fr.w_over_Wmax].', ...
                                      [fr.h_over_Hmax].' ];

            % ---- inlet / duct (airframe side only) --------------------- %
            %      Engine thrust deliberately absent: T_AB_SLS_lb is Dependent
            %      on the injected prop.T_SL.
            obj.L_duct    = G.engine.duct_length_ft;       % [Brandt Main!F32]
            obj.x_inlet   = G.engine.x_inlet_ft;           % 15.0 [Brandt Main!F31] -- NOT 14.0, todo §18
            obj.n_engines = G.engine.n_engines;            % [Brandt Main!B28]

            % ---- configuration ----------------------------------------- %
            obj.L_t  = G.tail_arm_ft;                        % [estimate]
            obj.S_cs = G.total_control_surface_area_ft2;     % [estimate]
        end

        % ================================================================ %
        % Accessors required by the abstract contract (GeometryBase +
        % GeometryModelL3).  Each delegates to the GeomL3 static toolbox,
        % which reuses the GeomL2 low-level statics (Roskam Eq. 12.1
        % lifting-surface S_wet, Roskam Eq. 12.3 fuselage S_wet, Raymer §7.3
        % duct frustum, exposed-area clips) -- no formula lives here.
        % ================================================================ %

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj)
        %GET_S_WET  Total wetted area (wing+HT+VT+fuselage+duct).  No W_TO
        %   argument -- L3 has real planform geometry (mirrors F16GeomL2's
        %   zero-arg decision, RESOLVED 2026-07-22).  The duct term was ADDED
        %   in Phase 2 along with L_duct and the injected nacelle diameter.
            val = GeomL3.get_S_wet(obj);
        end

        function val = get_S_wet_wing(obj)
            val = GeomL3.get_S_wet_wing(obj);
        end

        function val = get_S_wet_HT(obj)
            val = GeomL3.get_S_wet_HT(obj);
        end

        function val = get_S_wet_VT(obj)
            val = GeomL3.get_S_wet_VT(obj);
        end

        function val = get_S_wet_fuselage(obj)
            val = GeomL3.get_S_wet_fuselage(obj);
        end

        function val = get_S_wet_duct(obj)
            val = GeomL3.get_S_wet_duct(obj);
        end

        function val = get_S_exposed_wing(obj)
            val = GeomL3.get_S_exposed_wing(obj);
        end

        % ================================================================ %
        % DERIVED-property getters -- recompute live from the inputs on every
        % read.  Cheap closed-form algebra; no caching.
        % ================================================================ %

        % ---- Wing ------------------------------------------------------- %
        function v = get.b_wing(obj)
            v = GeometryBase.compute_span(obj.AR_wing, obj.S_ref);
        end
        function v = get.c_root_wing(obj)
            v = GeometryBase.compute_root_chord(obj.S_ref, obj.b_wing, obj.lambda_wing);
        end
        function v = get.c_tip_wing(obj)
            v = GeometryBase.compute_tip_chord(obj.c_root_wing, obj.lambda_wing);
        end
        function v = get.cbar_wing(obj)
            % Raymer 7th ed. Eq. 7.8, on the FULL-planform root chord + taper.
            v = GeometryBase.compute_mac(obj.c_root_wing, obj.lambda_wing);
        end
        function v = get.QC_sweep_wing(obj)
            % MIRRORED surface -> convert_sweep's 4/AR form.
            v = GeometryBase.convert_sweep(obj.LE_sweep_wing, obj.AR_wing, obj.lambda_wing, 0.25);
        end
        function v = get.TE_sweep_wing(obj)
            v = GeometryBase.convert_sweep(obj.LE_sweep_wing, obj.AR_wing, obj.lambda_wing, 1.0);
        end
        function v = get.tc_r_wing(obj)
            v = obj.tc_wing;   % wing modeled uniform-tc; mirrors tc_wing
        end
        function v = get.tc_t_wing(obj)
            v = obj.tc_wing;   % wing modeled uniform-tc; mirrors tc_wing
        end
        function v = get.S_exposed_wing(obj)
            % Fuselage-clipped exposed wing area, live from the wing full-
            % planform inputs -- mirrors F16GeomL2.get.S_exposed_wing.
            fw = obj.W_max_fuselage / 2;   % fuselage half-width [readme_geom.md §4.3]
            v  = GeomL2.compute_S_exposed_horizontal(obj.c_root_wing, obj.c_tip_wing, obj.b_wing/2, fw);
        end
        function v = get.S_wet_wing(obj)
            v = obj.get_S_wet_wing();
        end

        % ---- Horizontal tail -------------------------------------------- %
        function v = get.AR_ht(obj)
            % DECISION 1 (user, 2026-07-25 -- option B): the HT planform is
            % fixed by the measured S_ht + B_h pair, so the FULL-planform
            % aspect ratio is DERIVED, not stored:  AR == b^2/S by definition
            % (the inverse of GeometryBase.compute_span).  Area and span are
            % what a 3-view measures; aspect ratio is definitional.  A stored
            % AR_ht would be both contradictable (sqrt(3.0*108) = 18.0 ft vs
            % the physical 18.5) and stale the instant an optimizer moved B_h.
            % Brandt Main!C19 = 3.0 is a comparison reference only (+5.63 %).
            v = obj.B_h^2 / obj.S_ht;
        end
        function v = get.b_ht(obj)
            % Mirrors the PRIMARY span input.  sqrt(AR_ht*S_ht) returns the
            % identical value by construction of get.AR_ht, so there is no
            % circularity -- the mirror is exact and cheaper.
            v = obj.B_h;
        end
        function v = get.c_root_ht(obj)
            v = GeometryBase.compute_root_chord(obj.S_ht, obj.b_ht, obj.lambda_ht);
        end
        function v = get.c_tip_ht(obj)
            v = GeometryBase.compute_tip_chord(obj.c_root_ht, obj.lambda_ht);
        end
        function v = get.QC_sweep_ht(obj)
            % MIRRORED surface (conventional HT) -> convert_sweep's 4/AR form,
            % fed the DERIVED AR_ht = 3.1690 (Decision 1).
            v = GeometryBase.convert_sweep(obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 0.25);
        end
        function v = get.TE_sweep_ht(obj)
            % 2.5617 deg, vs L2's -0.0002 (which matches Brandt Main!C27
            % exactly).  BY DESIGN: the derived AR_ht = 3.1690 aft-sweeps the
            % L3 HT trailing edge -- a consequence of Decision 1's span choice,
            % not an error.
            v = GeometryBase.convert_sweep(obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 1.0);
        end
        function v = get.tc_ht(obj)
            % Root/tip mean, needed only where a single uniform t/c is required
            % (the Brandt Geom!B13 uniform-t/c S_wet comparison alternate and
            % the Raymer Eq. 12.30 form factor).  The T.O. root/tip split is
            % the single t/c basis at L3 (locked decision 6), so this is
            % DERIVED, never a stored 0.04.
            v = (obj.tc_r_ht + obj.tc_t_ht) / 2;
        end
        function v = get.S_exposed_ht(obj)
            % Fuselage-clipped exposed HT area, live from the FULL-planform
            % chords (themselves from the S_ht + B_h pair).  51.1486 ft^2:
            % +2.611 % vs Brandt Geom!8 = 49.8473, an INTENTIONAL divergence
            % (Decision 1) to be annotated BY DESIGN, never as an error.
            fw = obj.W_max_fuselage / 2;   % fuselage half-width [readme_geom.md §4.3]
            v  = GeomL2.compute_S_exposed_horizontal(obj.c_root_ht, obj.c_tip_ht, obj.b_ht/2, fw);
        end
        function v = get.S_wet_ht(obj)
            v = obj.get_S_wet_HT();
        end

        % ---- Vertical tail ---------------------------------------------- %
        function v = get.b_vt(obj)
            v = sqrt(obj.S_vt * obj.AR_vt);   % full single-panel span, not halved [readme_geom.md §4.3]
        end
        function v = get.c_root_vt(obj)
            v = GeometryBase.compute_root_chord(obj.S_vt, obj.b_vt, obj.lambda_vt);
        end
        function v = get.c_tip_vt(obj)
            v = GeometryBase.compute_tip_chord(obj.c_root_vt, obj.lambda_vt);
        end
        function v = get.QC_sweep_vt(obj)
            % SINGLE-PANEL form (2/AR): AR_vt is defined on the one VT panel,
            % whose root->tip spans the full b_vt -- not a mirrored semispan.
            % Using the mirrored convert_sweep here double-counts the taper
            % term (it would return 41.4437 instead of 44.6293 deg).
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25);
        end
        function v = get.TE_sweep_vt(obj)
            % SINGLE-PANEL form -- see get.QC_sweep_vt.  34.0052 deg; the
            % mirrored form would give a taper-double-counted 14.4655.
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0);
        end
        function v = get.tc_vt(obj)
            v = (obj.tc_r_vt + obj.tc_t_vt) / 2;   % root/tip mean -- see get.tc_ht
        end
        function v = get.S_exposed_vt(obj)
            % Clipped by the fuselage HALF-HEIGHT (not half-width).  NB this
            % static takes NO sweep argument, so the L3 value is bit-identical
            % to L2's and to Brandt Geom!10 = 40.8897 and CANNOT diverge
            % despite the 47.5 deg LE sweep -- a genuine positive control.
            % Do NOT invent a sweep-dependent exposed-area formula to create a
            % divergence here (todo 2026-07-25 Phase 2 §7(a)).
            fh = obj.H_max_fuselage / 2;   % fuselage half-height [readme_geom.md §4.3]
            v  = GeomL2.compute_S_exposed_vertical(obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt, fh);
        end
        function v = get.S_wet_vt(obj)
            v = obj.get_S_wet_VT();
        end

        % ---- Fuselage / whole aircraft ---------------------------------- %
        function v = get.L_fuselage(obj)
            v = obj.L_fus;   % mirrors L_fus (duplicate name kept for GeometryModelL2 contract parity)
        end
        function v = get.D_fus(obj)
            % Equivalent diameter for the Roskam Eq. 12.3 fuselage S_wet term
            % ONLY (Brandt low-fi D_avg convention).  NOT the Raymer Eq. 15.4
            % structural depth the weights DI reads (that is H_max_fuselage).
            v = (obj.W_max_fuselage + obj.H_max_fuselage) / 2;
        end
        function v = get.Amax(obj)
            % WHOLE-AIRCRAFT AREA-RULED maximum cross-sectional area, ft^2
            % [Brandt Geom!H26:H45 -> H47 -> B20; readme_geom.md §§4.2/4.5]:
            %
            %   Amax = MAX_x(A_fuse + A_wing + A_HT + A_VT + A_nacelle)
            %          - n_engines*pi*D_engine^2/5
            %
            % Feeds the Raymer 6th ed. Eq. 12.44 Sears-Haack wave-drag term as
            % (Amax/L_aircraft)^2.  Every equation, citation and open item lives
            % on the GeomL3 statics this delegates to -- including the two
            % citation gaps that are stated, not papered over: the affine
            % frame-table rescaling (GeomL3.denormalize_frames) and the bare
            % "/5" flow-through divisor (GeomL3.compute_Amax_area_ruled), both
            % STANDING OPEN, todo.md 2026-07-25 Phase 2 §4 and §5.
            %
            % SUB-STEP 2h (locked user decision, 2026-07-25) REPLACED the
            % fuselage-envelope ellipse (pi/4)*W*H = 27.488936 that used to sit
            % here.  That is the LOW-fidelity, fuselage-only definition by
            % readme_geom.md §7's own fidelity table, and in the FINEST tier it
            % inflated CD0_wave by +23.15 % and pushed the L3 constraint optimum
            % out of bounds (todo §16.6 / §17).
            % GeometryBase.compute_Amax_elliptical is untouched and remains
            % F16GeomL2's answer -- correctly, since L2 IS the low-fidelity tier.
            %
            % Verified live 2026-07-25: as-built 24.703652 ft^2 (-1.62 % vs
            % Brandt Geom!B20 = 25.110556 -- a physical fidelity divergence
            % driven by L3's 47.5 ft fuselage, not an error), and -- ROUND-TRIP
            % CONTROL -- 25.110534 (-0.000 %) when L_fus is set to Brandt's own
            % 46.5.  That control proves the method rather than fitting it:
            % normalizing and de-normalizing by the same envelope is an
            % identity.  E_WD = 2.2 needs NO retune: the as-built wave term
            % lands within -0.54 % of the Brandt-referenced one.
            v = GeomL3.get_Amax(obj);
        end

        % ---- Inlet / duct ----------------------------------------------- %
        function v = get.T_AB_SLS_lb(obj)
            % INJECTED, not stored: the SLS afterburning thrust comes from the
            % propulsion object, so the nacelle diameter -> duct wetted area ->
            % CD0 chain tracks the engine instead of a frozen 23,770 lbf copy
            % (Phase 2/3a).  [Brandt Engn(s)!T_AB_SLS = Main!D29]
            v = obj.prop.T_SL;
        end
        function v = get.D_inlet(obj)
            % Brandt nacelle sizing, extracted into a cited static in Phase 2
            % [Brandt Engn(s) D_nac; readme_geom.md §3].
            v = GeometryBase.compute_nacelle_diameter(obj.T_AB_SLS_lb);
        end
        function v = get.D_exit(obj)
            v = obj.D_inlet;   % constant-diameter cylinder nacelle -> frustum degenerates to pi*D*L
        end
        function v = get.L_engine(obj)
            % 4.5 * D_engine = 15.9166 ft [Brandt Geom!D475 = C475 *
            % 'Engn(s) Old'!Q22, Q22 = ='Engn(s)'!R22 = 4.5; todo §18].
            % DERIVED from the injected thrust via D_inlet -- never stored.
            v = GeomL3.compute_engine_length(obj.D_inlet);
        end
        function v = get.x_nacelle_aft(obj)
            % Aft limit of the nacelle cross-section, ft = 44.9166.  The LIVE
            % workbook chain, inlet lip -> compressor face -> nozzle:
            %   Geom!C480 = Main!F31        = x_inlet            = 15.0
            %   Geom!C482 = C480 + Main!F32 = + L_duct           = 29.0
            %   Geom!C484 = C482 + D475     = + L_engine         = 44.9166
            % NOT BrandtGeometry.m's [14.0, 43.9166], which is 1.0 ft low at
            % both ends via the mislabelled `inlet_x_ft` key (todo §18).
            v = obj.x_inlet + obj.L_duct + obj.L_engine;
        end

        % ---- Area-ruled Amax intermediates ------------------------------ %
        % All DERIVED (todo §16.1 verified each is derivable from inputs L3
        % already carries), so none may ever be stored.  Formulas + citations
        % are on GeomL3.compute_c_root_exposed and readme_geom.md §§4.3/4.5.

        function v = get.c_exp_root_wing(obj)
            % Chord where the fuselage side cuts the wing.  13.35641 ft --
            % reproduces Brandt Geom!F7 = 13.3564 exactly.
            v = GeomL3.compute_c_root_exposed(obj.c_root_wing, obj.c_tip_wing, ...
                    obj.b_wing/2, obj.W_max_fuselage/2);
        end
        function v = get.c_exp_root_ht(obj)
            % 6.73148 ft vs Brandt Geom!F8 = 6.8391 (-1.57 %).  BY DESIGN:
            % entirely Decision 1's physical span 18.5 vs Brandt's 18.0.
            v = GeomL3.compute_c_root_exposed(obj.c_root_ht, obj.c_tip_ht, ...
                    obj.b_ht/2, obj.W_max_fuselage/2);
        end
        function v = get.c_exp_root_vt(obj)
            % Vertical surface: the taper runs over the FULL single-panel span
            % b_vt and the fuselage clips it by HALF-DEPTH, not half-width
            % [readme_geom.md §4.3].  7.12330 ft -- Brandt Geom!F10 = 7.1233,
            % exact (this static takes no sweep, so the 47.5-vs-40 deg
            % divergence cannot reach it -- a genuine positive control).
            v = GeomL3.compute_c_root_exposed(obj.c_root_vt, obj.c_tip_vt, ...
                    obj.b_vt, obj.H_max_fuselage/2);
        end
        function v = get.G_hs_exp_wing(obj)
            v = obj.b_wing/2 - obj.W_max_fuselage/2;   % 11.5 ft [Brandt Geom!G7]
        end
        function v = get.G_hs_exp_ht(obj)
            % 5.75 ft vs Brandt Geom!G8 = 5.5 -- again purely the 18.5 span.
            v = obj.b_ht/2 - obj.W_max_fuselage/2;
        end
        function v = get.G_hs_exp_vt(obj)
            % Full single-panel span less the fuselage HALF-DEPTH, not halved
            % and not width-clipped.  7.29796 ft [Brandt Geom!G10 = 7.298].
            v = obj.b_vt - obj.H_max_fuselage/2;
        end
        function v = get.Xexp_wing(obj)
            % x of the exposed root LE = apex + (half-width)*tan(LE sweep):
            % the LE has swept aft by the time it clears the fuselage side.
            % 20.722849 ft [Brandt Geom!B7 = 20.72268; the 2e-4 gap is x_apex_wing 17.786 vs Brandt Main!B23 17.785833, todo 2026-07-25 Phase 2].
            v = obj.x_apex_wing + (obj.W_max_fuselage/2) * tand(obj.LE_sweep_wing);
        end
        function v = get.Xexp_ht(obj)
            v = obj.x_le_ht + (obj.W_max_fuselage/2) * tand(obj.LE_sweep_ht);   % 38.936849 [Geom!B8 = 38.93685]
        end
        function v = get.Xexp_vt(obj)
            % VERTICAL surface -> clipped by half-DEPTH, not half-width
            % [readme_geom.md §4.3].  38.72827 ft at L3's physical 47.5 deg
            % sweep, vs Brandt Geom!B10 = 38.09775 at his 40 deg -- the SAME
            % intentional sweep divergence documented in the class header, not
            % a new error.
            v = obj.x_le_vt + (obj.H_max_fuselage/2) * tand(obj.LE_sweep_vt);
        end

        % ---- Total ------------------------------------------------------ %
        function v = get.S_wet(obj)
            v = obj.get_S_wet();
        end

    end
end

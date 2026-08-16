classdef F16GeomL3 < GeometryModelL3
%F16GEOML3  F-16A Block 10 Level-3 geometry student class.
%
%   Inherits from GeometryModelL3. Every abstract method delegates to a GeomL3
%   static (which reuses the GeomL2 / GeometryBase statics; the only new formulas
%   are GeometryBase.compute_Amax_elliptical and compute_nacelle_diameter).
%
%   L3 is the HIGHER-fidelity PHYSICAL / T.O.-geometry tier consumed by L3
%   geometry + aero + weights. Where a physical/T.O. value differs from Brandt,
%   GeomL3 uses the physical one (VT LE sweep 47.5 deg, L_fus 47.5 ft, HT span
%   B_h 18.5 ft as the PRIMARY span, exposed HT/VT AR 2.114/1.294 and tapers
%   0.390/0.437). Those divergences from GeomL2 are INTENTIONAL fidelity
%   differences, not errors. Authoritative spec: F16GeomL3.md.
%
%   INPUT vs DERIVED — the optimization-ready pattern (F16GeomL2.m is the
%   reference implementation). Inputs are mutable spec data an optimizer varies
%   (38 numbers + the 20x3 NORMALIZED fuselage frame table); Dependent getters
%   (45) recompute on read (no stored copy, read-only). AR_ht, S_exposed_ht,
%   S_exposed_vt, tc_ht and tc_vt are Dependent and must never be re-frozen.
%
%   Constructor: F16GeomL3(json_path, prop) — reads the .geometry block of the
%   L3 JSON (f16a_spec_path(3)) plus a required injected propulsion object. No
%   silent default. Sets only input properties.
%
%   NAMING: AR_ht / lambda_ht / S_ht / S_vt mean FULL planform on both tiers;
%   exposed values live under AR_exposed_ht / lambda_exposed_ht /
%   AR_exposed_vt / lambda_exposed_vt. A weights DI must read S_exposed_ht /
%   S_exposed_vt (51.15 / 40.89), NOT S_ht / S_vt (108 / 60); and H_max_fuselage
%   (5.0, Raymer Eq. 15.4 structural depth), NOT the Dependent D_fus (6.0,
%   Roskam Eq. 12.3 equivalent diameter).
%
%   DECISION 1 ("physical span primary"): the whole HT planform derives from the
%   S_ht=108 + B_h=18.5 INPUT PAIR, so AR_ht is DERIVED = B_h^2/S_ht = 3.1690,
%   not stored. Area and span are what a 3-view measures; aspect ratio is
%   definitional. Brandt Main!C19 = 3.0 is a comparison reference, not an input.
%
%   DECISION 2: the OFFICIAL L3 lifting-surface wetted-area formula is Roskam
%   Vol. II Eq. 12.1 fed the T.O. root/tip t/c splits (as L2). Brandt's
%   uniform-t/c Geom!B13 form stays reachable via
%   GeomL2.compute_wet_planform(S_exposed, tc_ht|tc_vt) as a comparison-report
%   alternate row only.
%
%   VERTICAL-TAIL SWEEP FORM: QC_sweep_vt/TE_sweep_vt use
%   GeometryBase.convert_sweep_panel (SINGLE-PANEL, 2/AR). Wing and HT are
%   mirrored and keep convert_sweep.
%
%   PROPULSION INJECTION: engine SLS thrust is not geometry spec data. A
%   propulsion object is injected and T_AB_SLS_lb is Dependent on prop.T_SL, so
%   the nacelle diameter D_inlet — and hence the duct wetted area and CD0 —
%   tracks a thrust change. At the L3 rung the injected object is an F16PropL2:
%   there is NO L3 propulsion tier. T_AB_SLS_lb and prop are concrete-only, not
%   part of the GeometryModelL3 abstract contract.
%
%   AREA-RULED Amax: Amax is Brandt's whole-aircraft buildup [Geom!H26:H45 ->
%   H47], MAX over the 20 frame stations of fuselage + wing + HT + VT + nacelle
%   cross-sections less an n_engines*pi*D_engine^2/5 flow-through deduction (NOT
%   the low-fidelity envelope ellipse, which stays at L2). Two citation gaps
%   remain OPEN: the affine frame-table rescaling has no textbook source, and
%   the "/5" divisor is a bare literal in the workbook.
%
%   As-built S_wet and Amax values and Brandt comparison are in F16GeomL3.md.
%
%   Inheritance: GeometryBase -> GeometryModelL3 -> F16GeomL3
%   (GeomL3 is the static toolbox alongside, NOT in the chain.)
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, Main/Geom/Engn(s) tabs, reproduced in
%       examples/F16A/inputs/f16a_L3.json (.geometry, per-value _src fields).
%       Main row 20 = 'Taper Ratio', row 21 = 'Sweep, deg', row 22 =
%       'NACA 4-digit' (last two digits = % chord t/c).
%     [TO]     T.O. 1F-16A-1 -- physical lengths/sweeps and the HT/VT biconvex
%       root/tip t/c splits.
%     [USAF]   USAF 3-view -- HT span B_h = 18 ft 6 in.

    % ===================================================================== %
    % INPUTS -- 38 numeric physical / T.O. spec values plus the 20x3 normalized
    % fuselage frame table, plus the injected propulsion object. Mutable spec
    % data. Citations: F16GeomL3.md §2.
    % ===================================================================== %
    properties
        % -- Wing (full-planform inputs; chords/MAC/sweeps/areas are DERIVED) %
        S_ref          = 300       % ft^2  reference wing area   [Brandt Main!B18]
        AR_wing        = 3.0       % --    aspect ratio          [Brandt Main!B19]
        lambda_wing    = 0.2275    % --    FULL taper ratio      [Brandt Main!B20]
        LE_sweep_wing  = 40        % deg   LE sweep              [Brandt Main!B21]
        tc_wing        = 0.04      % --    uniform t/c; tc_r_wing/tc_t_wing mirror it as Dependent [Brandt Main!B22 'NACA 4-digit' = 1404 -> 4% chord; TO 1F-16A-1 Fig. 1-2, NACA 64A204]
        S_csw          = 68.03     % ft^2  wing control-surface area = flaperon 31.32 + LEF 36.71 [TO 1F-16A-1 Fig. 1-2]
        x_apex_wing    = 17.786    % ft    wing apex (root LE) x-station aft of the nose [Brandt Main!B23 'X Location'] -- feeds the area-ruled Amax (Xexp_wing). Not derivable in-framework

        % -- Horizontal tail: FULL planform from the S_ht + B_h pair --------- %
        %    (Decision 1 -- AR_ht is DERIVED, deliberately absent here.)
        S_ht              = 108.0   % ft^2  FULL reference planform area [Brandt Main!C18]
        B_h               = 18.5    % ft    HT full span (18 ft 6 in), PRIMARY span [USAF 3-view]
        lambda_ht         = 0.2275  % --    FULL taper ratio      [Brandt Main!C20]
        LE_sweep_ht       = 40      % deg   LE sweep              [Brandt Main!C21]
        tc_r_ht           = 0.060   % --    root t/c, biconvex ~6%   [TO 1F-16A-1 Sec. I] -- the T.O. root/tip split is the single t/c basis; Dependent tc_ht is the mean 0.0475
        tc_t_ht           = 0.035   % --    tip  t/c, biconvex ~3.5% [TO 1F-16A-1 Sec. I]
        F_w               = 7.0     % ft    fuselage width at HT intersection; Raymer Eq. 15.2 [Brandt Main!C32 proxy -- estimate, real empennage is narrower]
        AR_exposed_ht     = 2.114   % --    EXPOSED-planform AR, physical; Raymer Eq. 15.2 weights input [TO/USAF -- not reconcilable with Brandt exposed geometry]
        lambda_exposed_ht = 0.390   % --    EXPOSED-planform taper, physical [TO/USAF]
        x_le_ht           = 36.0    % ft    HT root LE x-station aft of the nose [Brandt Main!C23 'X Location'] -- feeds Xexp_ht = 38.9368 [Brandt Geom!B8]. Worth 0.000% of Amax for this config, but the governing station can migrate under mutation

        % -- Vertical tail: FULL planform, single panel ---------------------- %
        S_vt              = 60.0    % ft^2  FULL reference planform area [Brandt Main!H18]
        AR_vt             = 1.6     % --    FULL aspect ratio (single panel) [Brandt Main!H19]
        lambda_vt         = 0.5     % --    FULL taper ratio      [Brandt Main!H20]
        LE_sweep_vt       = 47.5    % deg   LE sweep, PHYSICAL [TO 1F-16A-1] -- INTENTIONAL divergence from L2's 40 [Brandt Main!H21]
        tc_r_vt           = 0.053   % --    root t/c, biconvex ~5.3% [TO 1F-16A-1 Sec. I] -- the T.O. root/tip split is the single t/c basis; Dependent tc_vt is the mean 0.0415
        tc_t_vt           = 0.030   % --    tip  t/c, biconvex ~3.0% [TO 1F-16A-1 Sec. I]
        S_r               = 11.65   % ft^2  rudder area           [TO 1F-16A-1 Fig. 1-2]
        H_t               = 0       % ft    HT height above fuselage CL; conventional (non-T) tail, H_t/H_v = 0 [Raymer 6th ed. §15.3]
        H_v               = 1       % ft    any nonzero denominator for H_t/H_v [Raymer 6th ed. §15.3]
        AR_exposed_vt     = 1.294   % --    EXPOSED-planform AR, physical; Raymer Eq. 15.3 weights input [TO/USAF]
        lambda_exposed_vt = 0.437   % --    EXPOSED-planform taper, physical [TO/USAF]
        x_le_vt           = 36.0    % ft    VT root LE x-station aft of the nose [Brandt Main!H23 'X Location'] -- feeds Xexp_vt = 38.7283. Worth 0.000% of Amax today

        % -- Fuselage / whole aircraft --------------------------------------- %
        L_fus          = 47.5      % ft    fuselage length, PHYSICAL [TO 1F-16A-1] -- INTENTIONAL divergence from L2's 46.5 [Brandt Main!B32]. Feeds the fuselage Reynolds number, Roskam Eq. 12.3 and (via the normalized frame table) Amax; DISTINCT from L_aircraft
        W_max_fuselage = 7.0       % ft    max width             [Brandt Main!C32 / TO 1F-16A-1]
        H_max_fuselage = 5.0       % ft    max DEPTH (weights' "D_fus", the Raymer Eq. 15.4 structural depth -- NOT the Dependent D_fus) [Brandt Main!D32; TO 1F-16A-1 cross-section]

        % -- Fuselage cross-section distribution (area-ruled Amax) ----------- %
        %    (N,3) NORMALIZED frame table, columns [x_over_L, w_over_Wmax,
        %    h_over_Hmax], Brandt's nose->tail frame order. Stored NORMALIZED so
        %    that L_fus / W_max_fuselage / H_max_fuselage rescale it, putting Amax
        %    under the control of the fuselage envelope. Raw numbers are Brandt's
        %    [Main!A34:F53; readme_geom.md §2] divided by his own envelope; the
        %    z_chine and z_center columns cancel out of the AREA (readme_geom.md
        %    §4.2). ★ The affine-rescaling assumption is UNCITED -- see
        %    GeomL3.denormalize_frames.
        frames_normalized = zeros(0,3)
        L_aircraft     = 47.65     % ft    OVERALL aircraft length; feeds ONLY the Raymer 6th ed. Eq. 12.44 Sears-Haack term as (Amax/l)^2. Not derivable in-model. Value is the published F-16A length 47 ft 7.75 in = 47.6458 ft (47.65 is +0.009%); CITATION NOT PINNED — no overall-length figure appears in sizing/ (Brandt Geom!B21 = 48.30 is a MAX-extent, a different quantity)

        % -- Inlet / duct (airframe side only) ------------------------------- %
        L_duct         = 14.0      % ft    inlet-duct length (inlet lip -> compressor face) -- a genuine AIRFRAME input [Brandt Main!F32, label Main!E32 = 'Compr Face'; readme_geom.md §3]
        x_inlet        = 15.0      % ft    inlet-lip x-station aft of the nose [Brandt Main!F31, label Main!E31 = 'Inlet(s):']. ★ TRAP: the read-only GroundTruth/f16a_geometry.json key inlet_x_ft = 14.0 is MISLABELLED (14.0 is Main!F32, the duct length, not an x-station). Use the live chain 15.0; do not "correct" this to 14.0
        n_engines      = 1         % --    number of engines [Brandt Main!B28]. Lives in GEOMETRY only because the Amax flow-through deduction needs it and no propulsion class exposes a count. If added propulsion-side, move to .propulsion and arrive by DI

        % -- Configuration --------------------------------------------------- %
        L_t            = 22.0      % ft    tail arm, wing 1/4-MAC -> HT 1/4-MAC [estimate; verify TO 1F-16A-1] -- derivable only if component apex-x inputs are added
        S_cs           = 190       % ft^2  total control-surface area = flaperon + HT + rudder + LEF [estimate] -- unpinned; no control-surface geometry exists in GeomL2/GeometryBase

        % -- Injected collaborator (NOT numeric spec data) ------------------- %
        prop                       % (1,1) PropulsionBase -- supplies prop.T_SL to the Dependent T_AB_SLS_lb. At the L3 rung this is an F16PropL2: no L3 propulsion tier exists
    end

    % ======================================================================= %
    % Sizing-loop OUTPUTS (not JSON inputs, not spec data).
    % ======================================================================= %
    properties
        % -- Control-surface areas ------------------------------------------ %
        % NaN until an external control-surface-sizing object
        % (ControlSurfaceSizer, injected into SizingLoopL2) writes them in.
        % Plain (not Dependent): no closed-form get.S_ail/etc. from this
        % object's own inputs alone. Distinct from S_r/S_csw/S_cs above, which
        % are separate fixed WEIGHTS-equation inputs.
        S_ail  = NaN   % ft^2  aileron area  [Raymer 6th ed. Fig. 6.3]
        S_elev = NaN   % ft^2  elevator area [Raymer 6th ed. Table 6.5] -- 0 for the F-16 (all-moving stabilator, no separate elevator)
        S_rud  = NaN   % ft^2  rudder area   [Raymer 6th ed. Table 6.5]
    end

    % ===================================================================== %
    % DERIVED -- 45 quantities computed live from the inputs on every read;
    % read-only. Citations: F16GeomL3.md §3.
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
        S_wet          % ft^2  wing + HT + VT + fuselage + duct
    end

    methods

        function obj = F16GeomL3(json_path, prop)
        %F16GEOML3  Construct from a required unified L3 input JSON path
        %   (f16a_spec_path(3), .geometry block) plus a required injected
        %   propulsion object. No silent default. Sets only input properties.
        %   prop.T_SL (SLS afterburning thrust) sizes the nacelle diameter. At
        %   the L3 rung pass an F16PropL2: there is no L3 propulsion tier.
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
        %   argument -- L3 has real planform geometry (mirrors F16GeomL2).
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
            % DECISION 1: the HT planform is fixed by the measured S_ht + B_h
            % pair, so the FULL-planform aspect ratio is DERIVED = b^2/S, not
            % stored. Brandt Main!C19 = 3.0 is a comparison reference only.
            v = obj.B_h^2 / obj.S_ht;
        end
        function v = get.b_ht(obj)
            v = obj.B_h;   % mirrors the PRIMARY span input
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
            % 2.5617 deg vs L2's -0.0002. BY DESIGN: the derived AR_ht = 3.1690
            % aft-sweeps the L3 HT trailing edge (Decision 1), not an error.
            v = GeometryBase.convert_sweep(obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 1.0);
        end
        function v = get.tc_ht(obj)
            % Root/tip mean, needed only where a single uniform t/c is required
            % (the Brandt Geom!B13 uniform-t/c S_wet comparison alternate and the
            % Raymer Eq. 12.30 form factor).
            v = (obj.tc_r_ht + obj.tc_t_ht) / 2;
        end
        function v = get.S_exposed_ht(obj)
            % Fuselage-clipped exposed HT area = 51.1486 ft^2, +2.611 % vs Brandt
            % Geom!8 = 49.8473 — an INTENTIONAL divergence (Decision 1), BY DESIGN.
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
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25);
        end
        function v = get.TE_sweep_vt(obj)
            % SINGLE-PANEL form -- see get.QC_sweep_vt.
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0);
        end
        function v = get.tc_vt(obj)
            v = (obj.tc_r_vt + obj.tc_t_vt) / 2;   % root/tip mean -- see get.tc_ht
        end
        function v = get.S_exposed_vt(obj)
            % Clipped by the fuselage HALF-HEIGHT (not half-width). This static
            % takes NO sweep argument, so the L3 value is bit-identical to L2's
            % and to Brandt Geom!10 = 40.8897 despite the 47.5 deg LE sweep — a
            % positive control.
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
            % (Amax/L_aircraft)^2. NOT the low-fidelity envelope ellipse (that
            % stays at L2). Two citation gaps are STANDING OPEN: the affine
            % frame-table rescaling (GeomL3.denormalize_frames) and the bare "/5"
            % flow-through divisor (GeomL3.compute_Amax_area_ruled). As-built
            % 24.7037 ft^2 (-1.62 % vs Brandt Geom!B20 = 25.1106, a physical
            % divergence from L3's 47.5 ft fuselage).
            v = GeomL3.get_Amax(obj);
        end

        % ---- Inlet / duct ----------------------------------------------- %
        function v = get.T_AB_SLS_lb(obj)
            % INJECTED, not stored: the SLS afterburning thrust comes from the
            % propulsion object, so the nacelle diameter -> duct wetted area ->
            % CD0 chain tracks the engine. [Brandt Engn(s)!T_AB_SLS = Main!D29]
            v = obj.prop.T_SL;
        end
        function v = get.D_inlet(obj)
            % Brandt nacelle sizing [Brandt Engn(s) D_nac; readme_geom.md §3].
            v = GeometryBase.compute_nacelle_diameter(obj.T_AB_SLS_lb);
        end
        function v = get.D_exit(obj)
            v = obj.D_inlet;   % constant-diameter cylinder nacelle -> frustum degenerates to pi*D*L
        end
        function v = get.L_engine(obj)
            % 4.5 * D_engine = 15.9166 ft [Brandt Geom!D475].
            v = GeomL3.compute_engine_length(obj.D_inlet);
        end
        function v = get.x_nacelle_aft(obj)
            % Aft limit of the nacelle cross-section = x_inlet + L_duct +
            % L_engine = 44.9166 ft [Brandt live chain Geom!C480->C482->C484].
            % NOT BrandtGeometry.m's [14.0, 43.9166] (mislabelled inlet_x_ft).
            v = obj.x_inlet + obj.L_duct + obj.L_engine;
        end

        % ---- Area-ruled Amax intermediates ------------------------------ %
        % All DERIVED from inputs L3 already carries. Formulas + citations are on
        % GeomL3.compute_c_root_exposed and readme_geom.md §§4.3/4.5.

        function v = get.c_exp_root_wing(obj)
            % Chord where the fuselage side cuts the wing = 13.3564 ft [Brandt Geom!F7].
            v = GeomL3.compute_c_root_exposed(obj.c_root_wing, obj.c_tip_wing, ...
                    obj.b_wing/2, obj.W_max_fuselage/2);
        end
        function v = get.c_exp_root_ht(obj)
            % 6.7315 ft vs Brandt Geom!F8 = 6.8391 (-1.57 %) — BY DESIGN, Decision
            % 1's physical span 18.5 vs Brandt's 18.0.
            v = GeomL3.compute_c_root_exposed(obj.c_root_ht, obj.c_tip_ht, ...
                    obj.b_ht/2, obj.W_max_fuselage/2);
        end
        function v = get.c_exp_root_vt(obj)
            % Vertical surface: taper runs over the FULL single-panel span b_vt,
            % clipped by HALF-DEPTH not half-width [readme_geom.md §4.3]. 7.1233
            % ft [Brandt Geom!F10, exact — no sweep argument, a positive control].
            v = GeomL3.compute_c_root_exposed(obj.c_root_vt, obj.c_tip_vt, ...
                    obj.b_vt, obj.H_max_fuselage/2);
        end
        function v = get.G_hs_exp_wing(obj)
            v = obj.b_wing/2 - obj.W_max_fuselage/2;   % 11.5 ft [Brandt Geom!G7]
        end
        function v = get.G_hs_exp_ht(obj)
            % 5.75 ft vs Brandt Geom!G8 = 5.5 — purely the 18.5 span.
            v = obj.b_ht/2 - obj.W_max_fuselage/2;
        end
        function v = get.G_hs_exp_vt(obj)
            % Full single-panel span less the fuselage HALF-DEPTH. 7.298 ft
            % [Brandt Geom!G10].
            v = obj.b_vt - obj.H_max_fuselage/2;
        end
        function v = get.Xexp_wing(obj)
            % x of the exposed root LE = apex + (half-width)*tan(LE sweep) =
            % 20.7228 ft [Brandt Geom!B7 = 20.72268].
            v = obj.x_apex_wing + (obj.W_max_fuselage/2) * tand(obj.LE_sweep_wing);
        end
        function v = get.Xexp_ht(obj)
            v = obj.x_le_ht + (obj.W_max_fuselage/2) * tand(obj.LE_sweep_ht);   % 38.9368 [Geom!B8]
        end
        function v = get.Xexp_vt(obj)
            % VERTICAL surface -> clipped by half-DEPTH [readme_geom.md §4.3].
            % 38.7283 ft at L3's physical 47.5 deg sweep vs Brandt Geom!B10 =
            % 38.09775 at 40 deg — the intentional sweep divergence, not an error.
            v = obj.x_le_vt + (obj.H_max_fuselage/2) * tand(obj.LE_sweep_vt);
        end

        % ---- Total ------------------------------------------------------ %
        function v = get.S_wet(obj)
            v = obj.get_S_wet();
        end

    end
end

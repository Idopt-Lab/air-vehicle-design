classdef F16GeomL2 < GeometryModelL2
%F16GEOML2  F-16A Block 10 Level-2 geometry student class.
%
%   Inherits from GeometryModelL2 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL2 statics — no formulas
%   are duplicated here.
%
%   2026-07-22: Geometry's former L3 tier was eliminated and merged into L2
%   (user decision — see src/disciplines/geometry/GeomL2.md's dated note).
%   This class is the merge of the former F16GeomL2 and F16GeomL3 — full
%   HT/VT breakdown (root/tip chords, sweep conversions, root/tip t/c) and
%   the inlet/duct component now live here. HT/VT properties use the
%   lowercase `_ht`/`_vt` suffix convention resolved in F16GeomL2.md: only
%   the trailing HT/VT suffix is lowercased (e.g. `QC_sweep_ht`, matching
%   the pre-existing `QC_sweep_wing` prefix casing), never the whole
%   property name.
%
%   ============================================================================
%   INPUT vs DERIVED — the optimization-ready pattern (2026-07-22).
%   *** THIS IS THE REFERENCE IMPLEMENTATION OF THE PATTERN TO BE FOLLOWED ***
%   *** by every future Tier-3 concrete class (F16AeroL*, F16WeightsL*, ...) ***
%
%   Properties split into two blocks:
%
%     (1) INPUTS — a plain, mutable `properties` block. These are the genuine
%         design-variable spec inputs an optimizer varies (reference areas,
%         aspect ratios, taper, LE sweep, t/c, fuselage envelope, duct
%         length, engine thrust). The constructor sets them once from the
%         JSON; an optimizer is free to mutate them between/within iterations.
%
%     (2) DERIVED — a `properties (Dependent)` block. These are the planform
%         quantities COMPUTED from the inputs (span, root/tip chord, MAC,
%         sweep-station conversions, exposed & wetted areas, equivalent /
%         nacelle diameters). Each has a `get.<name>` method that recomputes
%         live from the current inputs on every read via GeometryBase/GeomL2
%         statics. There is NO stored/cached copy, so a derived value can
%         never go stale: the instant an input changes (e.g. an optimizer
%         sets obj.AR_wing), every dependent read reflects it. This replaces
%         the earlier "compute-once-in-the-constructor, freeze-into-a-plain-
%         property" approach, which silently went stale under mutation.
%
%   Why Dependent (recompute-on-read) rather than a cache invalidated by set-
%   methods: the formulas here are cheap closed-form algebra (the priciest is
%   a 20-point fuselage frame integration, and that isn't even on the default
%   read path), so recomputing on each read costs nothing measurable and buys
%   correctness-by-construction with zero cache-coherency bookkeeping.
%   ============================================================================
%
%   CONSTRUCTOR SIGNATURE (CHANGED 2026-07-25, Phase 2): F16GeomL2(json_path, prop).
%   It reads the .geometry block of a required unified L2 input JSON (see
%   f16a_spec_path(2); the same file's .aerodynamics block feeds F16AeroL2) and
%   takes a REQUIRED injected propulsion object. Argument order chosen as
%   path-first: json_path keeps position 1 exactly as before, so every call site
%   takes an APPENDED argument rather than a reorder, and the class reads as
%   "build from this spec, using that engine". Neither argument has a default —
%   a silent default is the exact defect class Phase 2 removes.
%   It sets ONLY the input properties; every derived quantity (span, root/tip
%   chord, MAC, sweep-station conversions, exposed areas, t/c means, Amax,
%   nacelle diameter, wetted areas) is produced live by its Dependent getter —
%   none are hand-frozen literals, fixing the documented "QC_sweep_wing=37 deg"
%   bug (correct value ≈32.2 deg; see F16GeomL2.md).
%
%   PHASE-2 CHANGES (2026-07-25, locked user decisions; spec in
%   examples/F16A/F16GeomL3.md — that doc governs BOTH tiers):
%     * PROPULSION IS INJECTED. `T_AB_SLS_lb = 23770` was a stored input, i.e.
%       propulsion data frozen into geometry: verified live that setting
%       p2.T_SL = 30000 left geom.D_inlet and the aero CD0 unchanged, so
%       155.57 ft² of duct wetted area stayed pinned to the old engine and a
%       thrust-growing sizing loop under-predicted drag. It is now Dependent on
%       prop.T_SL, and D_inlet/D_exit/duct S_wet track the engine.
%     * tc_ht / tc_vt are DERIVED root/tip means (0.0475 / 0.0415), not stored
%       0.04 inputs — the T.O. root/tip split is now the single t/c basis and
%       the L2 JSON no longer carries a uniform HT/VT tc_ratio. The wing is
%       untouched: it is genuinely uniform-tc with no split available.
%     * L_aircraft (overall_length_ft = 47.65) is a new INPUT and Amax a new
%       DERIVED property, so BOTH geometry tiers can feed an injected aero
%       object the Raymer Eq. 12.44 wave-drag inputs it previously carried as
%       frozen Brandt outputs. See the property comments for Amax's missing
%       citation and L_aircraft's provenance caveat.
%     * BRANDT CELL CITATIONS CORRECTED (12 sites in this file; F16GeomL3.md §2
%       is authoritative). Main row 20 = 'Taper Ratio', row 21 = 'Sweep, deg',
%       row 22 = 'NACA 4-digit' (last two digits = % chord t/c). This file
%       previously cited row 21 for taper, row 20 for sweep and row 24 for t/c;
%       row 24 is 'Y Location' with B24/C24 EMPTY. ZERO computed values change —
%       only the audit trail moves.
%
%   Inheritance: GeometryBase → GeometryModelL2 → F16GeomL2
%
%   S_wet breakdown (official formulas: Roskam Eq. 12.1 wing/HT/VT + Roskam
%   Eq. 12.3 fuselage + Raymer Sec. 7.3 duct — see GeomL2.m for citations
%   and get_S_wet's duct-inclusion note). Verified 2026-07-22 and re-verified
%   UNCHANGED 2026-07-25 after the Phase-2 edits, via
%   mcp__matlab__evaluate_matlab_code against a fresh
%   F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))):
%     Wing:      396.38 ft^2   (Brandt Geom!B14 = 392.02, +1.1%)
%     HT:        101.39 ft^2   (Brandt Geom!B16 =  99.59, +1.8%)
%     VT:         83.14 ft^2   (Brandt Geom!B17 =  81.69, +1.8%)
%     Fuselage:  730.30 ft^2   (Roskam Eq.12.3, D_fus=6.0, L_fus=46.5; Brandt
%                               low-fi Geom!B3 = 730.42, high-fi Geom!D23 = 676.33)
%     Duct:      155.57 ft^2   (frustum degenerates to cylinder, D=D_nacelle=3.537 ft)
%     Total:    1466.77 ft^2
%   Reference: Brandt F-16A.xls Main!L3 = 1371.09 ft^2 (+7.0%; expected —
%   different formula families for lifting surfaces (Roskam Eq. 12.1 vs.
%   Brandt's own uniform-tc formula) and a different duct/nacelle model
%   (exposed inlet-to-exit frustum vs. Brandt's full-cylinder nacelle GT).
%   All 4 S_exposed values (wing 196.23, HT 49.85, VT 40.89) independently
%   match Brandt's own exposed-planform ground truth almost exactly (Brandt
%   Geom!H7/H8/H9-equivalent), confirming the exposed-area formulas
%   themselves (GeomL2.compute_S_exposed_horizontal/_vertical) are correct.
%   Phase 2 did NOT move any of these numbers (verified live 2026-07-25):
%   tc_ht/tc_vt becoming Dependent means (0.0475/0.0415) cannot shift the
%   official S_wet, which uses the root/tip pair via Roskam Eq. 12.1 — it only
%   affects the Brandt uniform-t/c COMPARISON alternate, which the report
%   already computed on the root/tip-mean basis (wing 392.02, HT 99.78,
%   VT 81.72). New at L2 in Phase 2: Amax = 27.4889 ft^2 and
%   L_aircraft = 47.65 ft.
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, Main tab (via
%       VnV/BrandtF16A/GroundTruth/f16a_geometry.json), reproduced in
%       examples/F16A/f16a_L2.json (.geometry) — genuine spec/ground-truth inputs.
%     [TO]     T.O. 1F-16A-1, Sec. I — HT/VT root/tip t/c splits (not a
%       Brandt value; Brandt uses one uniform tc per surface).

    properties (Constant)
        mainwheel_S_front = (25.5*8.0)/(12^2);   % ft^2  frontal area of main wheels [estimated; TO] -- unused, carried forward from former F16GeomL3
        nosewheel_S_front = (18*5.5)/(12^2);     % ft^2  frontal area of nosewheel   [estimated; TO] -- unused, carried forward from former F16GeomL3
    end

    % ======================================================================= %
    % INPUTS — design-variable spec data (mutable; set once by the
    % constructor, may be varied by an optimizer between/within iterations).
    % Every DERIVED (Dependent) property below recomputes live from these.
    % ======================================================================= %
    properties
        S_ref          = 300       % ft^2  [Brandt Main!B18, wing S_ref]

        % ── Wing (NACA 64A204 / 1404) ────────────────────────────────────── %
        tc_wing        = 0.04      % —     [Brandt Main!B22 'NACA 4-digit' = 1404 -> last two digits = 4% chord; citation corrected 2026-07-25 from B24, which is the empty 'Y Location' cell] wing single-value t/c; wing is modeled uniform-tc, so tc_r_wing/tc_t_wing (Dependent) mirror this
        lambda_wing    = 0.2275    % —     [Brandt Main!B20 'Taper Ratio'; citation corrected 2026-07-25 from B21]
        AR_wing        = 3.0       % —     [Brandt Main!B19]
        LE_sweep_wing  = 40        % deg   [Brandt Main!B21 'Sweep, deg'; citation corrected 2026-07-25 from B20]

        % ── Horizontal tail (all-moving stabilator; biconvex) ───────────── %
        S_ht           = 108.0     % ft^2  full reference planform area [Brandt Main!C18]
        lambda_ht      = 0.2275    % —     [Brandt Main!C20 'Taper Ratio'; citation corrected 2026-07-25 from C21]
        AR_ht          = 3.0       % —     [Brandt Main!C19]
        LE_sweep_ht    = 40        % deg   [Brandt Main!C21 'Sweep, deg'; citation corrected 2026-07-25 from C20]
        tc_r_ht        = 0.060     % —     [TO Sec I; biconvex root ~6%] — NOT a Brandt value, see class header. Now the SINGLE t/c basis: Brandt's uniform HT t/c [Main!C22 'NACA 4-digit' = '0004' -> 0.04; citation corrected from C24] is no longer an input, and the Dependent tc_ht is this pair's mean.
        tc_t_ht        = 0.035     % —     [TO Sec I; biconvex tip ~3.5%]

        % ── Vertical tail (biconvex) ─────────────────────────────────────── %
        S_vt           = 60.0      % ft^2  full reference planform area [Brandt Main!H18]
        lambda_vt      = 0.5       % —     [Brandt Main!H20 'Taper Ratio'; citation corrected 2026-07-25 from H21]
        AR_vt          = 1.6       % —     [Brandt Main!H19]
        LE_sweep_vt    = 40        % deg   [Brandt Main!H21 'Sweep, deg'; citation corrected 2026-07-25 from H20]
        tc_r_vt        = 0.053     % —     [TO Sec I; biconvex root ~5.3%] — NOT a Brandt value, see class header. Now the SINGLE t/c basis: Brandt's uniform VT t/c [Main!H22 'NACA 4-digit' = '0004' -> 0.04; citation corrected from H24] is no longer an input, and the Dependent tc_vt is this pair's mean.
        tc_t_vt        = 0.030     % —     [TO Sec I; biconvex tip ~3.0%]

        % ── Fuselage (equivalent cylindrical midsection) ─────────────────── %
        L_fus          = 46.5      % ft    [Brandt Main!B32]
        W_max_fuselage = 7.0       % ft    [Brandt Main!C32]
        H_max_fuselage = 5.0       % ft    [Brandt Main!D32]

        % ── Whole aircraft ───────────────────────────────────────────────── %
        L_aircraft     = 47.65     % ft    OVERALL aircraft length; feeds ONLY the Raymer 6th ed. Eq. 12.44 Sears-Haack wave-drag term as (Amax/l)^2. DISTINCT from L_fus = 46.5 — do not conflate the two length scales. Not derivable in-model (the geometry object has no nose-boom/tailcone x-stations). PROVENANCE CAVEAT, carried from the JSON's _TODO_overall_length_ft: the VALUE is user-approved (2026-07-25) as the published F-16A airframe length 47 ft 7.75 in = 47.6458 ft (47.65 is a +0.009% rounding), but the CITATION IS NOT PINNED — no overall-length figure appears anywhere in air_vehicle_design/sizing/ (grepped 2026-07-25). Brandt Geom!B21 = 48.303947 does NOT pin it: that cell is a MAX() over his component x-station columns, i.e. an EXTENT of his own layout, a different quantity (report row annotated 'definitional', −1.35%). STANDING OPEN item: VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §6.

        % ── Inlet + engine duct (F100-PW-200) ────────────────────────────── %
        L_duct         = 14.0      % ft    [Brandt engine.duct_length_ft] — a genuine AIRFRAME input, unlike the engine thrust below

        % ── Injected collaborator (NOT numeric spec data) ─────────────────── %
        prop                       % (1,1) PropulsionBase — injected propulsion object; supplies prop.T_SL to the Dependent T_AB_SLS_lb, which sizes the nacelle diameter (Phase 2/3a, 2026-07-25). Concrete-only: not in the GeometryModelL2 abstract contract (it is engine, not airframe, data; a different concrete class may size its duct differently).
    end

    % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
    % PRIMARY, production tail-volume coefficients [Raymer 7th ed. Table 6.4 +
    % text corrections] -- mirrors the deleted F16TailL1's constructor exactly
    % (0.315/0.063). This is the path SizingLoopL2 actually calls via
    % size_tail(obj) below.
    %
    % SECONDARY/alternate Nicolai & Carichner coefficients -- mirrors the
    % deleted F16TailL2's constructor exactly (0.3/0.094). NEVER wired into
    % the production sizing loop (see size_tail_nicolai below); preserved only
    % for its citation and test/comparison-report coverage.
    properties
        c_HT (1,1) double   % net horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 + text corrections] = 0.315
        c_VT (1,1) double   % net vertical-tail volume coefficient   [Raymer 7th ed. Table 6.4 + text corrections] = 0.063

        C_HT_nicolai (1,1) double = 0.3    % horizontal-tail volume coefficient [Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289] -- SECONDARY, not production
        C_VT_nicolai (1,1) double = 0.094  % vertical-tail volume coefficient   [Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289] -- SECONDARY, not production
    end
    % ==================================================================================================================================== %

    % ======================= CONTROL SURFACE SIZING (absorbed from the former src/sizing/ControlSurfaceSizer.m, 2026-08-03) ============= %
    % F-16 chord/span fraction defaults, matching the deleted
    % design_study_02_L2.m's hardcoded ControlSurfaceSizer(0.20, 0.40, 0, 0,
    % 0.30, 0.90) call exactly. Per-property citations preserved verbatim from
    % ControlSurfaceSizer.m's header.
    properties
        c_ail_frac  (1,1) double = 0.20   % aileron chord/wing chord   [Raymer 6th ed. Fig. 6.3 -- a representative point from the historical-guidelines band: midpoint of the text's stated typical 15-25% range]
        b_ail_frac  (1,1) double = 0.40   % aileron span/wing span     [Raymer 6th ed. Fig. 6.3 -- the band's typical/lower value at that chord, consistent with a fighter's relatively compact aileron]
        c_elev_frac (1,1) double = 0      % elevator Ce/C (tail chord) [Raymer 6th ed. Table 6.5, Fighter/attack row (0.30) footnoted "Supersonic usually all-moving tail without separate elevator" -- the F-16's HT is an all-moving stabilator, so 0 is the physically-correct choice, not a placeholder]
        b_elev_frac (1,1) double = 0      % elevator span/tail span    [same rationale as c_elev_frac]
        c_rud_frac  (1,1) double = 0.30   % rudder Cr/C (tail chord)   [Raymer 6th ed. Table 6.5, Fighter/attack row]
        b_rud_frac  (1,1) double = 0.90   % rudder span/tail span      [Raymer 6th ed. p.161, "extend to the tip of the tail or to about 90% of the tail span"]
    end
    % ==================================================================================================================================== %

    % ======================================================================= %
    % Sizing-loop OUTPUTS (not JSON inputs, not spec data).
    % ======================================================================= %
    properties
        % ── Control-surface areas ──────────────────────────────────────── %
        % NaN until size_control_surfaces() sets them (self-mutating, see
        % below). Plain (not Dependent) because there is no closed-form
        % get.S_ail/etc. in terms of this object's OWN inputs alone -- the
        % values are set once per call by size_control_surfaces(), not
        % recomputed automatically on every read.
        S_ail  = NaN   % ft^2  aileron area  [Raymer 6th ed. Fig. 6.3]
        S_elev = NaN   % ft^2  elevator area [Raymer 6th ed. Table 6.5] -- 0 for the F-16 (all-moving stabilator, no separate elevator; see this class's control-surface fraction defaults above)
        S_rud  = NaN   % ft^2  rudder area   [Raymer 6th ed. Table 6.5]
    end

    % ======================================================================= %
    % DERIVED — computed live from the inputs above on every read (no cache,
    % never stale). Each satisfies its abstract-property contract via a
    % `get.<name>` method. Read-only: assigning to any of these errors
    % (there are no set-methods), which is correct — they are outputs.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area (wing+HT+VT+fuselage+duct)

        % ── Wing ──────────────────────────────────────────────────────────── %
        b_wing         % ft    GeometryBase.compute_span(AR_wing, S_ref)
        c_root_wing    % ft    GeometryBase.compute_root_chord [Raymer 7th ed. Eq. 7.6]
        c_tip_wing     % ft    GeometryBase.compute_tip_chord  [Raymer 7th ed. Eq. 7.7]
        cbar_wing      % ft    GeometryBase.compute_mac        [Raymer 7th ed. Eq. 7.8]
        QC_sweep_wing  % deg   Λ_c/4  GeometryBase.convert_sweep(x=0.25) — fixes the historical "37 deg" bug -> ~32.2 deg
        TE_sweep_wing  % deg   GeometryBase.convert_sweep(x=1.0)
        tc_r_wing      % —     mirrors tc_wing (wing modeled uniform-tc; no root/tip split available from Brandt)
        tc_t_wing      % —     mirrors tc_wing; see tc_r_wing
        S_exposed_wing % ft^2  GeomL2.compute_S_exposed_horizontal
        S_wet_wing     % ft^2  get_S_wet_wing() [Roskam Eq. 12.1]

        % ── Horizontal tail ─────────────────────────────────────────────── %
        b_ht           % ft    GeometryBase.compute_span(AR_ht, S_ht)
        c_root_ht      % ft    GeometryBase.compute_root_chord (full-planform chord, NOT exposed-derived; feeds compute_S_exposed_horizontal, ~9.78 ft)
        c_tip_ht       % ft    GeometryBase.compute_tip_chord (full-planform chord, ~2.22 ft)
        QC_sweep_ht    % deg   GeometryBase.convert_sweep(x=0.25)
        TE_sweep_ht    % deg   GeometryBase.convert_sweep(x=1.0)
        tc_ht          % —     uniform HT t/c = (tc_r_ht+tc_t_ht)/2 = 0.0475 (root/tip mean; the split is the single t/c basis)
        S_exposed_ht   % ft^2  GeomL2.compute_S_exposed_horizontal
        S_wet_ht       % ft^2  get_S_wet_HT() [Roskam Eq. 12.1]

        % ── Vertical tail ───────────────────────────────────────────────── %
        b_vt           % ft    sqrt(S_vt*AR_vt) — full single-panel span, not halved [readme_geom.md Sec. 4.3]
        c_root_vt      % ft    GeometryBase.compute_root_chord (full-planform chord, NOT exposed-derived)
        c_tip_vt       % ft    GeometryBase.compute_tip_chord (full-planform chord)
        QC_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=0.25) — SINGLE-PANEL (2/AR), not the mirrored wing/HT form
        TE_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=1.0)  — SINGLE-PANEL (2/AR)
        tc_vt          % —     uniform VT t/c = (tc_r_vt+tc_t_vt)/2 = 0.0415 (root/tip mean; the split is the single t/c basis)
        S_exposed_vt   % ft^2  GeomL2.compute_S_exposed_vertical
        S_wet_vt       % ft^2  get_S_wet_VT() [Roskam Eq. 12.1]

        % ── Fuselage / whole aircraft ─────────────────────────────────────── %
        L_fuselage     % ft    mirrors L_fus (duplicate name required by the GeometryModelL2 abstract contract)
        D_fus          % ft    (W_max_fuselage+H_max_fuselage)/2 — JUDGMENT CALL (Brandt low-fi D_avg convention as the equivalent diameter fed to the official Roskam Eq. 12.3 fuselage S_wet formula; the L2 .geometry block has no D_fus field)
        Amax           % ft^2  GeometryBase.compute_Amax_elliptical(W_max, H_max) = (pi/4)*W*H — standard elliptical identity, NO equation number (todo 2026-07-25 Phase 2 §4); Raymer Eq. 12.44 input

        % ── Inlet + engine duct ───────────────────────────────────────────── %
        T_AB_SLS_lb    % lbf   = prop.T_SL (INJECTED, no longer a stored copy) [Brandt Engn(s)!T_AB_SLS = Main!D29 = 23770]
        D_inlet        % ft    GeometryBase.compute_nacelle_diameter(T_AB_SLS_lb) = sqrt(T/1900) [Brandt Engn(s) tab, D_nac; readme_geom.md Sec. 3]
        D_exit         % ft    = D_inlet (Brandt models the nacelle as a constant-diameter cylinder)
    end

    methods

        function obj = F16GeomL2(json_path, prop)
        %F16GEOML2  Construct from a required unified L2 input JSON path
        %   (f16a_spec_path(2)) plus a required injected propulsion object;
        %   reads the JSON's .geometry block. NO silent default on either
        %   argument: the path must be supplied, and so must the propulsion
        %   object (a defaulted injection would silently re-freeze the engine
        %   thrust — the defect class Phase 2 removes). Sets ONLY the input
        %   properties; all derived quantities are produced live by their
        %   Dependent getters.
        %
        %   prop must be a PropulsionBase subclass; only prop.T_SL is read (the
        %   SLS afterburning thrust), and only to size the nacelle diameter.
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                prop      (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path)).geometry;

            obj.prop = prop;   % injected: supplies the Dependent T_AB_SLS_lb

            % ---- wing ---------------------------------------------------- %
            obj.S_ref         = J.wing.S_ft2;        % [Brandt Main!B18]
            obj.AR_wing       = J.wing.AR;           % [Brandt Main!B19]
            obj.lambda_wing   = J.wing.taper;        % [Brandt Main!B20]
            obj.LE_sweep_wing = J.wing.sweep_LE_deg; % [Brandt Main!B21]
            obj.tc_wing       = J.wing.tc_ratio;     % [Brandt Main!B22, NACA 4-digit 1404]

            % ---- horizontal tail (all-moving stabilator / "pitch_ctrl") -- %
            %      No tc_ratio read: the T.O. root/tip split is the single t/c
            %      basis and tc_ht is the Dependent mean.
            obj.S_ht        = J.horizontal_tail.S_ft2;         % [Brandt Main!C18]
            obj.AR_ht       = J.horizontal_tail.AR;            % [Brandt Main!C19]
            obj.lambda_ht   = J.horizontal_tail.taper;         % [Brandt Main!C20]
            obj.LE_sweep_ht = J.horizontal_tail.sweep_LE_deg;  % [Brandt Main!C21]
            obj.tc_r_ht     = J.horizontal_tail.tc_root;   % [TO Sec I; biconvex root]
            obj.tc_t_ht     = J.horizontal_tail.tc_tip;    % [TO Sec I; biconvex tip]

            % ---- vertical tail ------------------------------------------- %
            obj.S_vt        = J.vertical_tail.S_ft2;           % [Brandt Main!H18]
            obj.AR_vt       = J.vertical_tail.AR;              % [Brandt Main!H19]
            obj.lambda_vt   = J.vertical_tail.taper;           % [Brandt Main!H20]
            obj.LE_sweep_vt = J.vertical_tail.sweep_LE_deg;    % [Brandt Main!H21]
            obj.tc_r_vt     = J.vertical_tail.tc_root;
            obj.tc_t_vt     = J.vertical_tail.tc_tip;

            % ---- fuselage / whole aircraft ------------------------------- %
            obj.L_fus          = J.fuselage.length_ft;     % [Brandt Main!B32]
            obj.W_max_fuselage = J.fuselage.max_width_ft;  % [Brandt Main!C32]
            obj.H_max_fuselage = J.fuselage.max_height_ft; % [Brandt Main!D32]
            obj.L_aircraft     = J.overall_length_ft;      % 47.65 — citation NOT pinned, todo §6

            % ---- engine / duct ------------------------------------------- %
            %      Engine thrust deliberately NOT read here: T_AB_SLS_lb is
            %      Dependent on the injected prop.T_SL.
            obj.L_duct = J.engine.duct_length_ft;

            % ---- tail sizing (absorbed 2026-08-03) ----------------------- %
            %      PRIMARY, production Raymer coefficients -- mirrors the
            %      deleted F16TailL1's constructor exactly. C_HT_nicolai/
            %      C_VT_nicolai default in the properties block above (not set
            %      here) -- they are hardcoded F-16 spec facts, not JSON inputs,
            %      same category as the deleted F16TailL2's wiring.
            [obj.c_HT, obj.c_VT] = GeomL1.compute_tail_volume_coeffs('jet_fighter', true, true);
        end

        % ================================================================== %
        % Accessors required by the abstract method contract. These delegate
        % to the GeomL2 static toolbox, which reads the (Dependent) component
        % properties live -- so they too are always consistent with the
        % current inputs.
        % ================================================================== %

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj)
        %GET_S_WET  Total wetted area. No W_TO argument (RESOLVED 2026-07-22,
        %   user decision) -- L2 has real planform geometry and never needed
        %   it. Call as obj.get_S_wet() with zero arguments.
            val = GeomL2.get_S_wet(obj);
        end

        function val = get_S_wet_wing(obj)
            val = GeomL2.get_S_wet_wing(obj);
        end

        function val = get_S_wet_HT(obj)
            val = GeomL2.get_S_wet_HT(obj);
        end

        function val = get_S_wet_VT(obj)
            val = GeomL2.get_S_wet_VT(obj);
        end

        function val = get_S_wet_fuselage(obj)
            val = GeomL2.get_S_wet_fuselage(obj);
        end

        function val = get_S_wet_duct(obj)
            val = GeomL2.get_S_wet_duct(obj);
        end

        % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %

        function result = size_tail(obj)
        %SIZE_TAIL  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  PRIMARY, production path
        %   (this is what SizingLoopL2 actually calls). Self-references
        %   obj's own S_ref/b_wing/cbar_wing/L_fus, cross-calls
        %   GeomL1.size_tail (reuse, not duplication), THEN self-mutates
        %   obj.S_ht/obj.S_vt -- this REPLACES what SizingLoopL2 used to do
        %   externally by assigning geom.S_ht = tail_result.S_ht after
        %   calling a separate injected tail object. Also returns the result.
            result   = GeomL1.size_tail(obj, obj.S_ref, obj.b_wing, obj.cbar_wing, obj.L_fus);
            obj.S_ht = result.S_ht;
            obj.S_vt = result.S_vt;
        end

        function result = size_tail_nicolai(obj)
        %SIZE_TAIL_NICOLAI  Horizontal- and vertical-tail reference areas
        %   [ft^2], Nicolai & Carichner F-16-specific coefficient method.
        %   [Nicolai & Carichner Table 11.6 F-16 row]  SECONDARY/alternate --
        %   never wired into the production sizing loop. Deliberately does
        %   NOT self-mutate obj.S_ht/obj.S_vt: this is a pure, non-mutating
        %   query/comparison method (used by tail_sizing_brandt_comparison.m
        %   and its own unit tests), and must not silently clobber the
        %   primary size_tail path's output.
            result = GeomL2.size_tail_nicolai(obj);
        end

        % ==================================================================================================================================== %

        % ======================= CONTROL SURFACE SIZING (absorbed from the former src/sizing/ControlSurfaceSizer.m, 2026-08-03) ============= %

        function result = size_control_surfaces(obj)
        %SIZE_CONTROL_SURFACES  Aileron/elevator/rudder areas [ft^2].
        %   [Raymer 6th ed. Fig. 6.3 (aileron) / Table 6.5 (elevator, rudder)]
        %   Self-references obj's own chord/span fraction properties and
        %   S_ref/S_ht/S_vt, cross-calls GeomL2.compute_control_surface_areas
        %   (reuse, not duplication), THEN self-mutates obj.S_ail/obj.S_elev/
        %   obj.S_rud -- replaces what SizingLoopL2/ControlSurfaceSizer did
        %   externally before. Also returns the result.
            result    = GeomL2.compute_control_surface_areas( ...
                obj.c_ail_frac, obj.b_ail_frac, obj.c_elev_frac, obj.b_elev_frac, ...
                obj.c_rud_frac, obj.b_rud_frac, obj.S_ref, obj.S_ht, obj.S_vt);
            obj.S_ail  = result.S_ail;
            obj.S_elev = result.S_elev;
            obj.S_rud  = result.S_rud;
        end

        % ==================================================================================================================================== %

        function val = get_S_exposed_wing(obj)
            val = GeomL2.get_S_exposed_wing(obj);
        end

        % ================================================================== %
        % DERIVED-property getters — recompute live from the inputs on every
        % read (see the class header's INPUT vs DERIVED note). Cheap
        % closed-form algebra; no caching.
        % ================================================================== %

        % ---- Wing --------------------------------------------------------- %
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
            v = GeometryBase.compute_mac(obj.c_root_wing, obj.lambda_wing);
        end
        function v = get.QC_sweep_wing(obj)
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
            fw = obj.W_max_fuselage / 2;   % fuselage half-width [readme_geom.md Sec. 4.3]
            v  = GeomL2.compute_S_exposed_horizontal(obj.c_root_wing, obj.c_tip_wing, obj.b_wing/2, fw);
        end
        function v = get.S_wet_wing(obj)
            v = obj.get_S_wet_wing();
        end

        % ---- Horizontal tail ---------------------------------------------- %
        function v = get.b_ht(obj)
            v = GeometryBase.compute_span(obj.AR_ht, obj.S_ht);
        end
        function v = get.c_root_ht(obj)
            v = GeometryBase.compute_root_chord(obj.S_ht, obj.b_ht, obj.lambda_ht);
        end
        function v = get.c_tip_ht(obj)
            v = GeometryBase.compute_tip_chord(obj.c_root_ht, obj.lambda_ht);
        end
        function v = get.QC_sweep_ht(obj)
            v = GeometryBase.convert_sweep(obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 0.25);
        end
        function v = get.TE_sweep_ht(obj)
            v = GeometryBase.convert_sweep(obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 1.0);
        end
        function v = get.tc_ht(obj)
            % Root/tip mean, DERIVED (2026-07-25) — needed only where a single
            % uniform t/c is required (the Brandt Geom!B13 uniform-t/c S_wet
            % comparison alternate, and the Raymer Eq. 12.30 form factor). The
            % T.O. root/tip split is the single t/c basis, so the former stored
            % 0.04 input [Brandt Main!C22, citation corrected from C24] is gone
            % and the L2 JSON no longer carries a HT tc_ratio key.
            v = (obj.tc_r_ht + obj.tc_t_ht) / 2;
        end
        function v = get.S_exposed_ht(obj)
            fw = obj.W_max_fuselage / 2;
            v  = GeomL2.compute_S_exposed_horizontal(obj.c_root_ht, obj.c_tip_ht, obj.b_ht/2, fw);
        end
        function v = get.S_wet_ht(obj)
            v = obj.get_S_wet_HT();
        end

        % ---- Vertical tail ------------------------------------------------ %
        function v = get.b_vt(obj)
            v = sqrt(obj.S_vt * obj.AR_vt);   % full single-panel span, not halved [readme_geom.md Sec. 4.3]
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
            % Using the mirrored convert_sweep here double-counted the taper
            % term (fixed 2026-07-25; was 32.24 deg, correct 36.31 deg).
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25);
        end
        function v = get.TE_sweep_vt(obj)
            % SINGLE-PANEL form -- see get.QC_sweep_vt. Was a physically
            % impossible 0.33 deg under the mirrored form; correct 22.90 deg.
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0);
        end
        function v = get.tc_vt(obj)
            % Root/tip mean, DERIVED (2026-07-25) — see get.tc_ht. The former
            % stored 0.04 input [Brandt Main!H22, citation corrected from H24]
            % is gone and the L2 JSON no longer carries a VT tc_ratio key.
            v = (obj.tc_r_vt + obj.tc_t_vt) / 2;
        end
        function v = get.S_exposed_vt(obj)
            fh = obj.H_max_fuselage / 2;   % fuselage half-height [readme_geom.md Sec. 4.3]
            v  = GeomL2.compute_S_exposed_vertical(obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt, fh);
        end
        function v = get.S_wet_vt(obj)
            v = obj.get_S_wet_VT();
        end

        % ---- Fuselage / whole aircraft ------------------------------------ %
        function v = get.L_fuselage(obj)
            v = obj.L_fus;   % mirrors L_fus (duplicate name required by the abstract contract)
        end
        function v = get.D_fus(obj)
            % JUDGMENT CALL: the L2 .geometry block has no D_fus field (width/height
            % only), so the equivalent diameter reuses Brandt's own low-fi
            % D_avg convention [Brandt F-16A.xls, Geom!B3] (same formula as
            % compute_s_wet_fus_brandt_lowfi) fed to the official Roskam
            % Eq. 12.3 formula (get_S_wet_fuselage).
            v = (obj.W_max_fuselage + obj.H_max_fuselage) / 2;
        end
        function v = get.Amax(obj)
            % Maximum cross-section of the equivalent elliptical-section
            % fuselage the model already assumes (the same envelope whose
            % D_fus = (W+H)/2 feeds Roskam Eq. 12.3); consumed by the Raymer
            % 6th ed. Eq. 12.44 Sears-Haack wave-drag term as
            % (Amax/L_aircraft)^2. ADDED 2026-07-25 so an injected aero object
            % reads it live instead of carrying Brandt's frozen Geom!B20 output.
            % The formula has NO pinnable equation number — it is cited as a
            % standard elliptical-cross-section identity following the
            % GeometryBase.convert_sweep precedent (GeometryBase.md, RESOLVED
            % 2026-07-21); STANDING OPEN item, todo.md 2026-07-25 Phase 2 §4.
            % See GeometryBase.compute_Amax_elliptical for the full citation note and
            % why Brandt's Geom!B20 = 25.110556 is a different quantity (a
            % whole-aircraft area-ruled max net of engine flow-through).
            v = GeometryBase.compute_Amax_elliptical(obj.W_max_fuselage, obj.H_max_fuselage);
        end

        % ---- Inlet + engine duct ------------------------------------------ %
        function v = get.T_AB_SLS_lb(obj)
            % INJECTED, not stored (2026-07-25, Phase 2/3a): the SLS
            % afterburning thrust comes from the propulsion object, so the
            % nacelle diameter -> duct wetted area -> CD0 chain tracks the
            % engine instead of a frozen 23,770 lbf copy.
            % [Brandt Engn(s)!T_AB_SLS = Main!D29]
            v = obj.prop.T_SL;
        end
        function v = get.D_inlet(obj)
            % Brandt nacelle sizing [Engn(s) tab D_nac; readme_geom.md Sec. 3].
            % The sqrt(T/1900) expression was inline here until 2026-07-25;
            % Phase 2 needed it at L3 too, so it was extracted into the cited
            % static GeometryBase.compute_nacelle_diameter rather than copying the
            % uncited literal 1900 across two tiers (F16GeomL3.md §3 reuse gap;
            % todo.md 2026-07-25 Phase 2 §12).
            v = GeometryBase.compute_nacelle_diameter(obj.T_AB_SLS_lb);
        end
        function v = get.D_exit(obj)
            v = obj.D_inlet;   % constant-diameter cylinder nacelle -> frustum degenerates to pi*D*L
        end

        % ---- Total -------------------------------------------------------- %
        function v = get.S_wet(obj)
            v = obj.get_S_wet();
        end

    end
end

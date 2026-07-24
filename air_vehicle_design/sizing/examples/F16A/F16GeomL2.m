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
%   Constructor reads the .geometry block of a required unified L2 input JSON
%   (see f16a_spec_path(2); the same file's .aerodynamics block feeds
%   F16AeroL2). It sets ONLY the input properties; every
%   derived quantity (span, root/tip chord, MAC, sweep-station conversions,
%   exposed areas, nacelle diameter, wetted areas) is produced live by its
%   Dependent getter — none are hand-frozen literals, fixing the documented
%   "QC_sweep_wing=37 deg" bug (correct value ≈32.2 deg; see F16GeomL2.md).
%
%   Inheritance: GeometryBase → GeometryModelL2 → F16GeomL2
%
%   S_wet breakdown (official formulas: Roskam Eq. 12.1 wing/HT/VT + Roskam
%   Eq. 12.3 fuselage + Raymer Sec. 7.3 duct — see GeomL2.m for citations
%   and get_S_wet's duct-inclusion note). Verified 2026-07-22 via
%   mcp__matlab__evaluate_matlab_code against a fresh F16GeomL2() instance:
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
        tc_wing        = 0.04      % —     [Brandt Main!B24] wing single-value t/c; wing is modeled uniform-tc, so tc_r_wing/tc_t_wing (Dependent) mirror this
        lambda_wing    = 0.2275    % —     [Brandt Main!B21]
        AR_wing        = 3.0       % —     [Brandt Main!B19]
        LE_sweep_wing  = 40        % deg   [Brandt Main!B20]

        % ── Horizontal tail (all-moving stabilator; biconvex) ───────────── %
        S_ht           = 108.0     % ft^2  full reference planform area [Brandt Main!C18]
        tc_ht          = 0.04      % —     [Brandt Main!C24] single-value uniform-tc (Brandt); distinct from the T.O. root/tip split below
        lambda_ht      = 0.2275    % —     [Brandt Main!C21]
        AR_ht          = 3.0       % —     [Brandt Main!C19]
        LE_sweep_ht    = 40        % deg   [Brandt Main!C20]
        tc_r_ht        = 0.060     % —     [TO Sec I; biconvex root ~6%] — NOT a Brandt value, see class header
        tc_t_ht        = 0.035     % —     [TO Sec I; biconvex tip ~3.5%]

        % ── Vertical tail (biconvex) ─────────────────────────────────────── %
        S_vt           = 60.0      % ft^2  full reference planform area [Brandt Main!H18]
        tc_vt          = 0.04      % —     [Brandt Main!H24] single-value uniform-tc (Brandt)
        lambda_vt      = 0.5       % —     [Brandt Main!H21]
        AR_vt          = 1.6       % —     [Brandt Main!H19]
        LE_sweep_vt    = 40        % deg   [Brandt Main!H20]
        tc_r_vt        = 0.053     % —     [TO Sec I; biconvex root ~5.3%] — NOT a Brandt value, see class header
        tc_t_vt        = 0.030     % —     [TO Sec I; biconvex tip ~3.0%]

        % ── Fuselage (equivalent cylindrical midsection) ─────────────────── %
        L_fus          = 46.5      % ft    [Brandt Main!B32]
        W_max_fuselage = 7.0       % ft    [Brandt Main!C32]
        H_max_fuselage = 5.0       % ft    [Brandt Main!D32]

        % ── Inlet + engine duct (F100-PW-200) ────────────────────────────── %
        L_duct         = 14.0      % ft    [Brandt engine.duct_length_ft]
        T_AB_SLS_lb    = 23770     % lbf   engine AB thrust — borrowed input used ONLY to size the nacelle diameter (D=sqrt(T_AB_SLS_lb/1900), Brandt Engn(s) D_nac). Concrete-only: not in the GeometryModelL2 abstract contract (it is engine, not airframe, data; a different concrete class may size its duct differently).
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
        S_exposed_ht   % ft^2  GeomL2.compute_S_exposed_horizontal
        S_wet_ht       % ft^2  get_S_wet_HT() [Roskam Eq. 12.1]

        % ── Vertical tail ───────────────────────────────────────────────── %
        b_vt           % ft    sqrt(S_vt*AR_vt) — full single-panel span, not halved [readme_geom.md Sec. 4.3]
        c_root_vt      % ft    GeometryBase.compute_root_chord (full-planform chord, NOT exposed-derived)
        c_tip_vt       % ft    GeometryBase.compute_tip_chord (full-planform chord)
        QC_sweep_vt    % deg   GeometryBase.convert_sweep(x=0.25)
        TE_sweep_vt    % deg   GeometryBase.convert_sweep(x=1.0)
        S_exposed_vt   % ft^2  GeomL2.compute_S_exposed_vertical
        S_wet_vt       % ft^2  get_S_wet_VT() [Roskam Eq. 12.1]

        % ── Fuselage ──────────────────────────────────────────────────────── %
        L_fuselage     % ft    mirrors L_fus (duplicate name required by the GeometryModelL2 abstract contract)
        D_fus          % ft    (W_max_fuselage+H_max_fuselage)/2 — JUDGMENT CALL (Brandt low-fi D_avg convention as the equivalent diameter fed to the official Roskam Eq. 12.3 fuselage S_wet formula; the L2 .geometry block has no D_fus field)

        % ── Inlet + engine duct ───────────────────────────────────────────── %
        D_inlet        % ft    nacelle formula D=sqrt(T_AB_SLS_lb/1900) [Brandt Engn(s) tab, D_nac; readme_geom.md Sec. 3]
        D_exit         % ft    = D_inlet (Brandt models the nacelle as a constant-diameter cylinder)
    end

    methods

        function obj = F16GeomL2(json_path)
        %F16GEOML2  Construct from a required unified L2 input JSON path
        %   (f16a_spec_path(2)); reads its .geometry block. No silent default:
        %   the path must be supplied. Sets ONLY the input properties; all
        %   derived quantities are produced live by their Dependent getters.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).geometry;

            % ---- wing ---------------------------------------------------- %
            obj.S_ref         = J.wing.S_ft2;        % [Brandt Main!B18]
            obj.AR_wing       = J.wing.AR;           % [Brandt Main!B19]
            obj.lambda_wing   = J.wing.taper;        % [Brandt Main!B21]
            obj.LE_sweep_wing = J.wing.sweep_LE_deg; % [Brandt Main!B20]
            obj.tc_wing       = J.wing.tc_ratio;     % [Brandt Main!B24]

            % ---- horizontal tail (all-moving stabilator / "pitch_ctrl") -- %
            obj.S_ht        = J.horizontal_tail.S_ft2;         % [Brandt Main!C18]
            obj.AR_ht       = J.horizontal_tail.AR;
            obj.lambda_ht   = J.horizontal_tail.taper;
            obj.LE_sweep_ht = J.horizontal_tail.sweep_LE_deg;
            obj.tc_ht       = J.horizontal_tail.tc_ratio;
            obj.tc_r_ht     = J.horizontal_tail.tc_root;   % [TO Sec I; biconvex root]
            obj.tc_t_ht     = J.horizontal_tail.tc_tip;    % [TO Sec I; biconvex tip]

            % ---- vertical tail ------------------------------------------- %
            obj.S_vt        = J.vertical_tail.S_ft2;           % [Brandt Main!H18]
            obj.AR_vt       = J.vertical_tail.AR;
            obj.lambda_vt   = J.vertical_tail.taper;
            obj.LE_sweep_vt = J.vertical_tail.sweep_LE_deg;
            obj.tc_vt       = J.vertical_tail.tc_ratio;
            obj.tc_r_vt     = J.vertical_tail.tc_root;
            obj.tc_t_vt     = J.vertical_tail.tc_tip;

            % ---- fuselage ------------------------------------------------ %
            obj.L_fus          = J.fuselage.length_ft;     % [Brandt Main!B32]
            obj.W_max_fuselage = J.fuselage.max_width_ft;  % [Brandt Main!C32]
            obj.H_max_fuselage = J.fuselage.max_height_ft; % [Brandt Main!D32]

            % ---- engine / duct ------------------------------------------- %
            obj.L_duct      = J.engine.duct_length_ft;
            obj.T_AB_SLS_lb = J.engine.T_AB_SLS_lb;   % feeds the nacelle-diameter Dependent getter D_inlet
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
            v = GeometryBase.convert_sweep(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25);
        end
        function v = get.TE_sweep_vt(obj)
            v = GeometryBase.convert_sweep(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0);
        end
        function v = get.S_exposed_vt(obj)
            fh = obj.H_max_fuselage / 2;   % fuselage half-height [readme_geom.md Sec. 4.3]
            v  = GeomL2.compute_S_exposed_vertical(obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt, fh);
        end
        function v = get.S_wet_vt(obj)
            v = obj.get_S_wet_VT();
        end

        % ---- Fuselage ----------------------------------------------------- %
        function v = get.L_fuselage(obj)
            v = obj.L_fus;   % mirrors L_fus (duplicate name required by the abstract contract)
        end
        function v = get.D_fus(obj)
            % JUDGMENT CALL: the L2 .geometry block has no D_fus field (width/height
            % only), so the equivalent diameter reuses Brandt's own low-fi
            % D_avg convention (compute_s_wet_fus_brandt_lowfi) fed to the
            % official Roskam Eq. 12.3 formula (get_S_wet_fuselage).
            v = (obj.W_max_fuselage + obj.H_max_fuselage) / 2;
        end

        % ---- Inlet + engine duct ------------------------------------------ %
        function v = get.D_inlet(obj)
            % Brandt nacelle sizing [Engn(s) tab D_nac; readme_geom.md Sec. 3].
            v = sqrt(obj.T_AB_SLS_lb / 1900);
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

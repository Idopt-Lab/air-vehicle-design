classdef F16GeomL2 < GeometryModelL2
%F16GEOML2  F-16A Block 10 Level-2 geometry student class.
%
%   Inherits from GeometryModelL2. Every abstract method delegates to a GeomL2
%   static. This class carries the full L2 core plus the FIGHTER-specific
%   detailed drag-build-up geometry (per-surface t/c, LE/TE/QC sweeps, taper,
%   aspect ratios, root/tip chords, per-surface wetted areas, inlet/duct, and
%   the whole-aircraft wave-drag geometry Amax/L_aircraft). Those detail members
%   are concrete here, not an abstract obligation on every L2 geometry; the drag
%   consumers (F16AeroL2/L3, F16WeightsL3, F16SubsystemsL2) read them off this
%   object.
%
%   INPUT vs DERIVED — the optimization-ready pattern; this is the reference
%   implementation for every Tier-3 concrete class. Inputs are mutable spec data
%   an optimizer varies; Dependent getters recompute on read (no stored copy,
%   read-only), so a derived value never goes stale.
%
%   Constructor: F16GeomL2(json_path, prop) — reads the .geometry block of the
%   unified L2 JSON (f16a_spec_path(2)) plus a required injected propulsion
%   object (prop.T_SL sizes the nacelle diameter). No silent default. Sets only
%   input properties.
%
%   Inheritance: GeometryBase → GeometryModelL2 → F16GeomL2
%
%   S_wet uses Roskam Eq. 12.1 (wing/HT/VT) + Roskam Eq. 12.3 (fuselage) +
%   Raymer Sec. 7.3 (duct). As-built S_wet values and Brandt comparison are in
%   F16GeomL2.md.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, Main tab (via
%       VnV/BrandtF16A/GroundTruth/f16a_geometry.json), reproduced in
%       examples/F16A/inputs/f16a_L2.json (.geometry) — genuine spec/ground-truth inputs.
%     [TO]     T.O. 1F-16A-1, Sec. I — HT/VT root/tip t/c splits (not a
%       Brandt value; Brandt uses one uniform tc per surface).

    properties (Constant)
        mainwheel_S_front = (25.5*8.0)/(12^2);   % ft^2  frontal area of main wheels [estimated; TO] -- unused
        nosewheel_S_front = (18*5.5)/(12^2);     % ft^2  frontal area of nosewheel   [estimated; TO] -- unused
    end

    % ======================================================================= %
    % INPUTS — mutable design-variable spec data. Every DERIVED (Dependent)
    % property below recomputes live from these.
    % ======================================================================= %
    properties
        S_ref          = 300       % ft^2  [Brandt Main!B18, wing S_ref]

        % ── Wing (NACA 64A204 / 1404) ────────────────────────────────────── %
        tc_wing        = 0.04      % —     [Brandt Main!B22 'NACA 4-digit' = 1404 -> last two digits = 4% chord] wing uniform t/c; tc_r_wing/tc_t_wing (Dependent) mirror this
        lambda_wing    = 0.2275    % —     [Brandt Main!B20 'Taper Ratio']
        AR_wing        = 3.0       % —     [Brandt Main!B19]
        LE_sweep_wing  = 40        % deg   [Brandt Main!B21 'Sweep, deg']

        % ── Horizontal tail (all-moving stabilator; biconvex) ───────────── %
        S_ht           = 108.0     % ft^2  full reference planform area [Brandt Main!C18]
        lambda_ht      = 0.2275    % —     [Brandt Main!C20 'Taper Ratio']
        AR_ht          = 3.0       % —     [Brandt Main!C19]
        LE_sweep_ht    = 40        % deg   [Brandt Main!C21 'Sweep, deg']
        tc_r_ht        = 0.060     % —     [TO Sec I; biconvex root ~6%]. The T.O. root/tip split is the single t/c basis; Dependent tc_ht is this pair's mean
        tc_t_ht        = 0.035     % —     [TO Sec I; biconvex tip ~3.5%]

        % ── Vertical tail (biconvex) ─────────────────────────────────────── %
        S_vt           = 60.0      % ft^2  full reference planform area [Brandt Main!H18]
        lambda_vt      = 0.5       % —     [Brandt Main!H20 'Taper Ratio']
        AR_vt          = 1.6       % —     [Brandt Main!H19]
        LE_sweep_vt    = 40        % deg   [Brandt Main!H21 'Sweep, deg']
        tc_r_vt        = 0.053     % —     [TO Sec I; biconvex root ~5.3%]. The T.O. root/tip split is the single t/c basis; Dependent tc_vt is this pair's mean
        tc_t_vt        = 0.030     % —     [TO Sec I; biconvex tip ~3.0%]

        % ── Fuselage (equivalent cylindrical midsection) ─────────────────── %
        L_fus          = 46.5      % ft    [Brandt Main!B32]
        W_max_fuselage = 7.0       % ft    [Brandt Main!C32]
        H_max_fuselage = 5.0       % ft    [Brandt Main!D32]

        % ── Whole aircraft ───────────────────────────────────────────────── %
        L_aircraft     = 47.65     % ft    OVERALL aircraft length; feeds ONLY the Raymer 6th ed. Eq. 12.44 Sears-Haack wave-drag term as (Amax/l)^2. DISTINCT from L_fus = 46.5. Value is the published F-16A length 47 ft 7.75 in = 47.6458 ft (47.65 is +0.009%); CITATION NOT PINNED — no overall-length figure appears in sizing/ (Brandt Geom!B21 = 48.30 is a MAX-extent, a different quantity)

        % ── Inlet + engine duct (F100-PW-200) ────────────────────────────── %
        L_duct         = 14.0      % ft    [Brandt engine.duct_length_ft] — a genuine AIRFRAME input, unlike the engine thrust
        n_engines      = 1         % double  engine count [Brandt Main!B28]. Exposed for mission DI (geom.n_engines); NOT used by any L2 geometry quantity

        % ── Injected collaborator (NOT numeric spec data) ─────────────────── %
        prop                       % (1,1) PropulsionBase — supplies prop.T_SL to the Dependent T_AB_SLS_lb, which sizes the nacelle diameter. Concrete-only: not in the GeometryModelL2 abstract contract (engine, not airframe, data)
    end

    % ======================================================================= %
    % Sizing-loop OUTPUTS (not JSON inputs, not spec data).
    % ======================================================================= %
    properties
        % ── Control-surface areas ──────────────────────────────────────── %
        % NaN until an external control-surface-sizing object
        % (ControlSurfaceSizer, injected into SizingLoopL2) writes them in.
        % Plain (not Dependent): no closed-form get.S_ail/etc. from this
        % object's own inputs alone.
        S_ail  = NaN   % ft^2  aileron area  [Raymer 6th ed. Fig. 6.3]
        S_elev = NaN   % ft^2  elevator area [Raymer 6th ed. Table 6.5] -- 0 for the F-16 (all-moving stabilator, no separate elevator)
        S_rud  = NaN   % ft^2  rudder area   [Raymer 6th ed. Table 6.5]
    end

    % ======================================================================= %
    % DERIVED — computed live from the inputs on every read; read-only.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area (wing+HT+VT+fuselage+duct)
        S_wet_fuselage % ft^2  wetted area of the fuselage

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
        % Mod (08/18/2026) (Claude) -- S_wet_wing removed. Call
        %   GeomL2.compute_S_wet_planform_roskam(S_exposed_wing, tc_r_wing, tc_t_wing, lambda_wing).

        % ── Horizontal tail ─────────────────────────────────────────────── %
        b_ht           % ft    GeometryBase.compute_span(AR_ht, S_ht)
        c_root_ht      % ft    GeometryBase.compute_root_chord (full-planform chord, NOT exposed-derived; feeds compute_S_exposed_horizontal, ~9.78 ft)
        c_tip_ht       % ft    GeometryBase.compute_tip_chord (full-planform chord, ~2.22 ft)
        QC_sweep_ht    % deg   GeometryBase.convert_sweep(x=0.25)
        TE_sweep_ht    % deg   GeometryBase.convert_sweep(x=1.0)
        tc_ht          % —     uniform HT t/c = (tc_r_ht+tc_t_ht)/2 = 0.0475 (root/tip mean; the split is the single t/c basis)
        S_exposed_ht   % ft^2  GeomL2.compute_S_exposed_horizontal
        % Mod (08/18/2026) (Claude) -- S_wet_ht removed. See S_wet_wing above.

        % ── Vertical tail ───────────────────────────────────────────────── %
        b_vt           % ft    sqrt(S_vt*AR_vt) — full single-panel span, not halved [readme_geom.md Sec. 4.3]
        c_root_vt      % ft    GeometryBase.compute_root_chord (full-planform chord, NOT exposed-derived)
        c_tip_vt       % ft    GeometryBase.compute_tip_chord (full-planform chord)
        QC_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=0.25) — SINGLE-PANEL (2/AR), not the mirrored wing/HT form
        TE_sweep_vt    % deg   GeometryBase.convert_sweep_panel(x=1.0)  — SINGLE-PANEL (2/AR)
        tc_vt          % —     uniform VT t/c = (tc_r_vt+tc_t_vt)/2 = 0.0415 (root/tip mean; the split is the single t/c basis)
        S_exposed_vt   % ft^2  GeomL2.compute_S_exposed_vertical
        % Mod (08/18/2026) (Claude) -- S_wet_vt removed. See S_wet_wing above.

        % ── Fuselage / whole aircraft ─────────────────────────────────────── %
        L_fuselage     % ft    mirrors L_fus (duplicate name required by the GeometryModelL2 abstract contract)
        D_fus          % ft    (W_max_fuselage+H_max_fuselage)/2 — JUDGMENT CALL (Brandt low-fi D_avg convention as the equivalent diameter fed to the official Roskam Eq. 12.3 fuselage S_wet formula; the L2 .geometry block has no D_fus field)
        Amax           % ft^2  F16GeomL2.compute_Amax_elliptical(W_max, H_max) = (pi/4)*W*H — standard elliptical identity, NO equation number (todo 2026-07-25 Phase 2 §4); Raymer Eq. 12.44 input

        % ── Inlet + engine duct ───────────────────────────────────────────── %
        T_AB_SLS_lb    % lbf   = prop.T_SL (INJECTED, no longer a stored copy) [Brandt Engn(s)!T_AB_SLS = Main!D29 = 23770]
        D_inlet        % ft    F16GeomL2.compute_nacelle_diameter(T_AB_SLS_lb) = sqrt(T/1900) [Brandt Engn(s) tab, D_nac; readme_geom.md Sec. 3]
        D_exit         % ft    = D_inlet (Brandt models the nacelle as a constant-diameter cylinder)
    end

    methods

        function obj = F16GeomL2(json_path, prop)
        %F16GEOML2  Construct from a required unified L2 input JSON path
        %   (f16a_spec_path(2), .geometry block) plus a required injected
        %   propulsion object. No silent default. Sets only input properties.
        %   prop.T_SL (SLS afterburning thrust) sizes the nacelle diameter.
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
            % n_engines: read from spec when present; single-engine default
            % otherwise. Exposed for mission DI, not used by L2 geometry.
            if isfield(J.engine, 'n_engines')
                obj.n_engines = J.engine.n_engines;
            end
        end

        % ================================================================== %
        % Accessors required by the abstract method contract. These delegate
        % to the GeomL2 static toolbox, which reads the (Dependent) component
        % properties live -- so they too are always consistent with the
        % current inputs.
        % ================================================================== %

        % TODO (8/18/2026)(Casey): This still doesn't mutate the argument.
        % Idea: Repurpose this into a wrapper that recomputes the main wing's geometry.
        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_design_S_wet_components(obj)
        %GET_S_WET  Total wetted area. No W_TO argument -- L2 has real planform
        %   geometry. Call as obj.get_S_wet() with zero arguments.
            % val = GeomL2.get_S_wet(obj);

            % TODO (8/18/2026)(Casey): Currently, the L2 sizing loop gives a fuel weight of 6.3k lbf. This 
            % is different from the previous merge. I'm pretty sure the problem is that the 
            % geometry values aren't being updated correctly, so it's just reiterating over the same
            % S_wet every time. Gotta fix that.
            % Get S_wet of each component
            % S_wet of the main wings
            S_wet_wing = GeomL2.compute_S_wet_planform_roskam(obj.S_exposed_wing, obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
            % % S_wet of strakes (these aren't in L2, leaving this here so I don't forget about it)
            % S_wet_strakes = GeomL2.compute_S_wet_planform_roskam(obj.S_exposed_strake, obj.tc_r_strake, obj.tc_t_strake, obj.lambda_strake);
            % S_wet of tail (horizontal)
            S_wet_ht = GeomL2.compute_S_wet_planform_roskam(obj.S_exposed_ht, obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht);
            % S_wet of tail (vertical)
            S_wet_vt = GeomL2.compute_S_wet_planform_roskam(obj.S_exposed_vt, obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt);
            % S_wet of fuselage
            S_wet_fuselage = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
            % S_wet of the duct
            S_wet_duct = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
            % Sum the components
            S_wet = S_wet_wing + S_wet_ht + S_wet_vt + S_wet_fuselage + S_wet_duct;
            % Return the final value.
            val = S_wet;
        end

        % Note (8/18/2026)(Casey): Does this include the nose? If not, we must add a method for estimating the wetted area of conical cylinders.
        % function val = get_S_wet_fuselage(obj)
        %     val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        % end

        % function val = get_S_wet_duct(obj)
        %     val = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        % end

        % Note (8/18/2026)(Casey): Required due to enforcer contract.
        % function val = get_S_exposed_wing(obj)
        %     val = GeomL2.compute_S_exposed_horizontal(obj.c_root_wing, obj.c_tip_wing, obj.b_wing/2, obj.W_max_fuselage/2);
        % end

        % ================================================================== %
        % DERIVED-property getters — recompute live from the inputs on every read.
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
        % Mod (08/18/2026) (Claude)
        %   get.S_wet_wing deleted, with get.S_wet_ht and get.S_wet_vt. Each
        %   called a removed method. Consumers now call
        %   GeomL2.compute_S_wet_planform_roskam with explicit arguments. Reason in
        %   GeomL2.md.

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
            % Root/tip mean, needed only where a single uniform t/c is required
            % (the Brandt Geom!B13 uniform-t/c S_wet comparison alternate and the
            % Raymer Eq. 12.30 form factor).
            v = (obj.tc_r_ht + obj.tc_t_ht) / 2;
        end
        function v = get.S_exposed_ht(obj)
            fw = obj.W_max_fuselage / 2;
            v  = GeomL2.compute_S_exposed_horizontal(obj.c_root_ht, obj.c_tip_ht, obj.b_ht/2, fw);
        end
        % Mod (08/18/2026) (Claude) -- get.S_wet_ht deleted. See get.S_wet_wing.

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
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25);
        end
        function v = get.TE_sweep_vt(obj)
            % SINGLE-PANEL form -- see get.QC_sweep_vt.
            v = GeometryBase.convert_sweep_panel(obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0);
        end
        function v = get.tc_vt(obj)
            % Root/tip mean -- see get.tc_ht.
            v = (obj.tc_r_vt + obj.tc_t_vt) / 2;
        end
        function v = get.S_exposed_vt(obj)
            fh = obj.H_max_fuselage / 2;   % fuselage half-height [readme_geom.md Sec. 4.3]
            v  = GeomL2.compute_S_exposed_vertical(obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt, fh);
        end
        % Mod (08/18/2026) (Claude) -- get.S_wet_vt deleted. See get.S_wet_wing.

        % ---- Fuselage / whole aircraft ------------------------------------ %
        % TODO (8/18/2026)(Casey): A requirement of the abstract contracts, but why doesn't it mutate
        % the input?
        function v = get.L_fuselage(obj)
            v = obj.L_fus;   % mirrors L_fus (duplicate name required by the abstract contract)
        end
        function v = get.D_fus(obj)
            % JUDGMENT CALL: the L2 .geometry block has no D_fus field, so the
            % equivalent diameter reuses Brandt's low-fi D_avg convention [Brandt
            % Geom!B3] fed to the official Roskam Eq. 12.3 (get_S_wet_fuselage).
            v = (obj.W_max_fuselage + obj.H_max_fuselage) / 2;
        end
        function v = get.Amax(obj)
            % Maximum cross-section of the equivalent elliptical-section fuselage;
            % consumed by the Raymer 6th ed. Eq. 12.44 Sears-Haack wave-drag term
            % as (Amax/L_aircraft)^2. The formula has NO pinnable equation number
            % (standard elliptical-cross-section identity; STANDING OPEN item).
            % See compute_Amax_elliptical below for the citation note.
            % Mod (08/19/2026) (Claude)
            v = F16GeomL2.compute_Amax_elliptical(obj.W_max_fuselage, obj.H_max_fuselage);
        end
        function v = get.S_wet_fuselage(obj)
            v = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        % ---- Inlet + engine duct ------------------------------------------ %
        function v = get.T_AB_SLS_lb(obj)
            % INJECTED, not stored: the SLS afterburning thrust comes from the
            % propulsion object, so the nacelle diameter -> duct wetted area ->
            % CD0 chain tracks the engine. [Brandt Engn(s)!T_AB_SLS = Main!D29]
            v = obj.prop.T_SL;
        end
        function v = get.D_inlet(obj)
            % Brandt nacelle sizing [Engn(s) tab D_nac; readme_geom.md Sec. 3].
            % Mod (08/19/2026) (Claude)
            v = F16GeomL2.compute_nacelle_diameter(obj.T_AB_SLS_lb);
        end
        function v = get.D_exit(obj)
            v = obj.D_inlet;   % constant-diameter cylinder nacelle -> frustum degenerates to pi*D*L
        end

        % ---- Total -------------------------------------------------------- %
        function v = get.S_wet(obj)
            v = obj.get_design_S_wet_components();
        end
    end

    methods (Static)

        % TODO (8/19/2026)(Casey): This should be in F16GeomL2 because it's specific to the F16.
        % This appears to use a Brandt equation. While I want to avoid using his work as much as possible in 
        % THIS part of the code, this is an exception because it's necessary and I cannot find any substitutes from Raymer, Nicolai, or Roskam. 
        % Need to do a scan with Claude, later.
        function val = compute_nacelle_diameter(T_AB_SLS_lb)
        %COMPUTE_NACELLE_DIAMETER  Engine/nacelle diameter [ft] from SLS
        %   afterburning thrust.  [Brandt F-16A.xls, Engn(s) tab, D_engine]
        %
        %   TODO: the 1900 divisor is hardcoded and silently assumes an
        %   afterburning engine -- Brandt uses 1900 only when T_dry ~= T_AB, and
        %   2000 otherwise (todo.md 2026-07-25 Phase 2 §18).
            arguments
                T_AB_SLS_lb (1,1) double {mustBePositive}
            end
            val = sqrt(T_AB_SLS_lb / 1900);
        end

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        % Note (8/19/2026): TODO from 7/28/2026 is complete.
        function val = compute_Amax_elliptical(W_max, H_max)
        %COMPUTE_AMAX_ELLIPTICAL  Max cross-section of an equivalent elliptical
        %   fuselage [ft^2]. Feeds the Sears-Haack term [Raymer 6th ed. Eq. 12.44].
        %   Low-fidelity fuselage-only form used at L2; L3 uses a whole-aircraft
        %   area-ruled Amax (F16GeomL3.get_Amax).
        %
        %   Standard elliptical-cross-section identity; no textbook equation
        %   number could be pinned against the references in this repo. Same
        %   status as GeometryBase.convert_sweep. It holds no Brandt content and
        %   no F-16 number, but F16GeomL2.get.Amax is its only caller, so it
        %   lives here.  Mod (08/19/2026) (Claude)
        %
        %   TODO: standard elliptical-cross-section identity with no known
        %   textbook equation number. Pin a citation or accept the
        %   standard-identity status in writing (todo.md 2026-07-25 Phase 2 §4).
            arguments
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            val = (pi/4) * W_max * H_max;
        end

    end
end

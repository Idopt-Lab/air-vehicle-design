classdef B777GeomL2 < GeometryModelL2
%B777GEOML2  Boeing 777-200LR Level-2 geometry: real trapezoidal planform with
%   MAC and EXPOSED planform areas (metabook Chapter 7, Example 7.1).
%
%   Adds the equivalent-trapezoidal planform parameters (metabook Table 7.2) for
%   the wing, horizontal tail, and vertical tail, and from them computes:
%     - the mean aerodynamic chord and 40%-MAC location  [Eq. 7.2-7.9]
%     - the EXPOSED planform areas of the wing/HT/VT      [Table 7.3]
%     - the fuselage wetted area                          [Table 7.3]
%   These feed B777WeightsL2 (Algorithm 5): wing/HT/VT weights use the exposed
%   planform areas, the fuselage weight uses the wetted area [Table 7.1].
%
%   Inherits GeometryModelL2, the aircraft-AGNOSTIC L2 core (exposed wing/HT/VT
%   areas, HT/VT write-back slots, wing span, fuselage length + wetted area,
%   get_S_exposed_wing / get_S_wet_fuselage). It does NOT carry the F-16's
%   detailed drag-build-up geometry (that lives on F16GeomL2). It preserves the
%   B777GeomL1 consumer contract (S_ref, S_wet, cbar_wing, n_engines, get_S_ref,
%   get_S_wet).
%
%   S_ref COUPLING (the sizing lever): S_ref is the wing design variable; the
%   wing trapezoid scales isometrically (linear dims ~ sqrt(S_ref/S_ref_baseline),
%   holding AR and taper), so the exposed wing area -- and wing weight -- tracks
%   S_ref. The HT/VT trapezoids are held at their Table 7.2 baseline; S_ht/S_vt
%   remain the tail-sizing write-back slots.
%
%   EXPOSED-AREA METHOD: exposed = gross trapezoid - the body-covered center,
%   covered = w_body*c_root - (c_root-c_tip)/b*(w_body^2/2). VT root is exposed
%   (w_body = 0). The metabook prints the exposed areas (Table 7.3) but not the
%   equations, so the body widths and fuselage wetted form factor are tuned to
%   reproduce Table 7.3 (see the fuselage block of b777_L1.json).
%
%   Inheritance: GeometryBase -> GeometryModelL2 -> B777GeomL2
%
%   SOURCES: [metabook] AE481 metabook, docs/reference_extracts/metabook_data.md
%   §7.2. Table 7.2 (777-200LR trapezoids); Table 7.3 (exposed areas 3923/903/
%   604, fuselage wetted 13125); Eq. 7.2-7.9 (MAC, 40%-MAC). S_ref/AR [Table
%   4.3]; S_wet_rest [Eq. 4.58]. Companion doc: B777GeomL2.md.

    % ======================================================================= %
    % INPUTS -- design-variable spec data (mutable; set once by the constructor).
    % ======================================================================= %
    properties
        S_ref       = 4605     % ft^2  wing reference area (design variable) [metabook Table 4.3]
        AR          = 9.8       % --    wing reference aspect ratio [metabook Table 4.3]
        S_wet_rest  = 19081    % ft^2  wetted area of everything except the wing [metabook Eq. 4.58]
        L_fus       = 209      % ft    fuselage/overall length [metabook _TODO stand-in; b777_L1.md §2.2]
        n_engines   = 2        % --    engine count [metabook §4.11]

        % Table 7.2 equivalent-trapezoidal planforms (structs: c_root_ft,
        % c_tip_ft, b_ft, Lambda_LE_deg, x_RLE_ft) [metabook Table 7.2].
        wing_trapezoid
        htail_trapezoid
        vtail_trapezoid

        % Fuselage geometry (struct: diameter_ft, width_at_wing_ft,
        % width_at_htail_ft, wetted_form_factor) [b777_L1.json fuselage block].
        fuselage

        % Tail reference areas -- sizing-loop write-back slots (NaN until the
        % tail-sizing object writes them). Same pattern as B777GeomL1.
        S_ht        = NaN      % ft^2  H-tail reference area [B777TailL1.size]
        S_vt        = NaN      % ft^2  V-tail reference area [B777TailL1.size]
    end

    properties (Constant, Access = private)
        S_REF_BASELINE = 4605  % ft^2  S_ref the Table 7.2 wing trapezoid is defined at (wing scaling anchor)
    end

    % ======================================================================= %
    % DERIVED -- computed live from the inputs on every read (no cache).
    % ======================================================================= %
    properties (Dependent)
        % --- preserved B777GeomL1 contract ---
        S_wet         % ft^2  total wetted area = S_wet_rest + 2*S_ref [metabook Eq. 4.58]
        b_wing        % ft    span = sqrt(AR*S_ref)
        cbar_wing     % ft    standard mean chord = S_ref/b_wing
        L_fuselage    % ft    mirrors L_fus (GeometryModelL1 abstract contract)

        % --- L2 additions: exposed areas + fuselage wetted [Table 7.3] ---
        S_exposed_wing   % ft^2  exposed wing planform (scales with S_ref)  [Table 7.3: 3923]
        S_exposed_ht     % ft^2  exposed H-tail planform                    [Table 7.3: 903]
        S_exposed_vt     % ft^2  exposed V-tail planform (= full trapezoid) [Table 7.3: 604]
        S_wet_fus        % ft^2  fuselage wetted area = pi*D*L*factor        [Table 7.3: 13125]

        % --- L2 additions: MAC + 40%-MAC location [Eq. 7.2-7.9] ---
        MAC_wing         % ft    wing mean aerodynamic chord              [Eq. 7.5]
        MAC_htail        % ft    H-tail MAC
        MAC_vtail        % ft    V-tail MAC                               [Eq. 7.8]
        x40MAC_wing      % ft    wing 40%-MAC location from the nose      [Eq. 7.6]
        x40MAC_htail     % ft    H-tail 40%-MAC location                  [Eq. 7.7]
        x40MAC_vtail     % ft    V-tail 40%-MAC location (uses 2*b)       [Eq. 7.9]
    end

    methods

        function obj = B777GeomL2(json_path)
        %B777GEOML2  Construct from the .geometry block of the unified input JSON
        %   (b777_spec_path(1)). No silent default.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).geometry;
            obj.S_ref           = J.S_ref;            % [metabook Table 4.3]
            obj.AR              = J.AR;               % [metabook Table 4.3]
            obj.S_wet_rest      = J.S_wet_rest;       % [metabook Eq. 4.58]
            obj.L_fus           = J.L_fus;            % [_TODO stand-in]
            obj.n_engines       = J.n_engines;        % [metabook §4.11]
            obj.wing_trapezoid  = J.wing_trapezoid;   % [metabook Table 7.2]
            obj.htail_trapezoid = J.htail_trapezoid;  % [metabook Table 7.2]
            obj.vtail_trapezoid = J.vtail_trapezoid;  % [metabook Table 7.2]
            obj.fuselage        = J.fuselage;         % [b777_L1.json fuselage block]
        end

        % ================================================================== %
        % GeometryBase / GeometryModelL1 abstract contract (preserved from L1).
        % ================================================================== %

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
            val = obj.S_wet;
        end

        function val = get_S_wet_statistical(obj, ~) %#ok<STOUT>
            error('B777GeomL2:notApplicable', ...
                ['B777GeomL2 has a real planform and computes S_wet = ', ...
                 'S_wet_rest + 2*S_ref [metabook Eq. 4.58], NOT a W_TO ', ...
                 'statistical regression. Read obj.S_wet instead.']);
        end

        function val = get_L_fus(obj, ~) %#ok<STOUT>
            error('B777GeomL2:notApplicable', ...
                ['B777GeomL2 reads L_fus as a direct spec input, NOT a W_TO ', ...
                 'regression. Read obj.L_fus / obj.L_fuselage instead.']);
        end

        % ================================================================== %
        % GeometryModelL2 agnostic-core method contract.
        % ================================================================== %

        function val = get_S_wet_fuselage(obj)
        %GET_S_WET_FUSELAGE  Fuselage wetted area, ft^2 [metabook Table 7.3].
        %   Read by the L2 weights fuselage term; same value as S_wet_fus.
            val = obj.S_wet_fus;
        end

        function val = get_S_exposed_wing(obj)
        %GET_S_EXPOSED_WING  Passthrough accessor for the exposed wing area.
            val = obj.S_exposed_wing;
        end

        % ================================================================== %
        % Preserved L1 derived getters.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.S_wet_rest + 2 * obj.S_ref;   % [metabook Eq. 4.58]
        end

        function v = get.b_wing(obj)
            v = GeometryBase.compute_span(obj.AR, obj.S_ref);
        end

        function v = get.cbar_wing(obj)
            v = obj.S_ref / obj.b_wing;
        end

        function v = get.L_fuselage(obj)
            v = obj.L_fus;
        end

        % ================================================================== %
        % L2 exposed areas [metabook Table 7.3].
        % ================================================================== %

        function v = get.S_exposed_wing(obj)
            t = obj.scaled_wing_();   % wing trapezoid scaled to the current S_ref
            v = B777GeomL2.exposed_area(t.c_root, t.c_tip, t.b, ...
                obj.fuselage.width_at_wing_ft);
        end

        function v = get.S_exposed_ht(obj)
            t = obj.htail_trapezoid;
            v = B777GeomL2.exposed_area(t.c_root_ft, t.c_tip_ft, t.b_ft, ...
                obj.fuselage.width_at_htail_ft);
        end

        function v = get.S_exposed_vt(obj)
            % VT root IS the exposed root -> whole trapezoid (body width 0).
            t = obj.vtail_trapezoid;
            v = B777GeomL2.exposed_area(t.c_root_ft, t.c_tip_ft, t.b_ft, 0);
        end

        function v = get.S_wet_fus(obj)
            % pi*D*L with a form factor for the nose/tail taper [Table 7.3].
            v = pi * obj.fuselage.diameter_ft * obj.L_fus * obj.fuselage.wetted_form_factor;
        end

        % ================================================================== %
        % L2 MAC + 40%-MAC location [metabook Eq. 7.2-7.9].
        % ================================================================== %

        function v = get.MAC_wing(obj)
            t = obj.scaled_wing_();
            v = B777GeomL2.mac(t.c_root, t.c_tip);
        end

        function v = get.MAC_htail(obj)
            t = obj.htail_trapezoid;
            v = B777GeomL2.mac(t.c_root_ft, t.c_tip_ft);
        end

        function v = get.MAC_vtail(obj)
            t = obj.vtail_trapezoid;
            v = B777GeomL2.mac(t.c_root_ft, t.c_tip_ft);
        end

        function v = get.x40MAC_wing(obj)
            t = obj.scaled_wing_();
            v = B777GeomL2.x40_mac(t.x_RLE, t.c_root, t.c_tip, t.b, ...
                obj.wing_trapezoid.Lambda_LE_deg, false);
        end

        function v = get.x40MAC_htail(obj)
            t = obj.htail_trapezoid;
            v = B777GeomL2.x40_mac(t.x_RLE_ft, t.c_root_ft, t.c_tip_ft, ...
                t.b_ft, t.Lambda_LE_deg, false);
        end

        function v = get.x40MAC_vtail(obj)
            % Eq. 7.9: use TWICE the span for the vertical tail.
            t = obj.vtail_trapezoid;
            v = B777GeomL2.x40_mac(t.x_RLE_ft, t.c_root_ft, t.c_tip_ft, ...
                t.b_ft, t.Lambda_LE_deg, true);
        end

    end

    methods (Access = private)

        function t = scaled_wing_(obj)
        %SCALED_WING_  Wing trapezoid scaled isometrically to the current S_ref.
        %   Linear dimensions scale by sqrt(S_ref/S_REF_BASELINE); taper and
        %   trapezoidal AR are held. Returns a struct with c_root, c_tip, b,
        %   x_RLE at the current S_ref.
            s = sqrt(obj.S_ref / B777GeomL2.S_REF_BASELINE);
            w = obj.wing_trapezoid;
            t.c_root = w.c_root_ft * s;
            t.c_tip  = w.c_tip_ft  * s;
            t.b      = w.b_ft      * s;
            t.x_RLE  = w.x_RLE_ft;   % root-LE position held (wing grows about its root)
        end

    end

    methods (Static)

        function A = exposed_area(c_root, c_tip, b, w_body)
        %EXPOSED_AREA  Exposed trapezoidal planform area [ft^2]: gross trapezoid
        %   minus the center covered by a body of width w_body.
        %   covered = w_body*c_root - (c_root-c_tip)/b*(w_body^2/2). w_body = 0
        %   gives the whole trapezoid (exposed root, e.g. the VT).
        %   [metabook Table 7.3; body widths tuned to Table 7.3, see class header.]
            gross = b * (c_root + c_tip) / 2;
            if w_body <= 0
                A = gross;
                return
            end
            covered = w_body * c_root - (c_root - c_tip) / b * (w_body^2 / 2);
            A = gross - covered;
        end

        function m = mac(c_root, c_tip)
        %MAC  Trapezoidal mean aerodynamic chord [ft].  [metabook Eq. 7.2/7.5]
        %   MAC = (2/3)*(c_root + c_tip - c_root*c_tip/(c_root+c_tip)).
            m = (2/3) * (c_root + c_tip - c_root * c_tip / (c_root + c_tip));
        end

        function x = x40_mac(x_RLE, c_root, c_tip, b, Lambda_LE_deg, use_twice_span)
        %X40_MAC  Streamwise 40%-MAC location from the nose [ft].
        %   [metabook Eq. 7.3/7.4/7.6, and Eq. 7.9 for the VT with 2*span]:
        %     x_MAC = x_RLE + (b/6)*(c_root+2*c_tip)/(c_root+c_tip)*tan(Lambda_LE)
        %     x_40%MAC = x_MAC + 0.4*MAC
        %   For the vertical tail, TWICE the span is used in place of b (Eq. 7.9).
            b_eff = b;
            if use_twice_span
                b_eff = 2 * b;
            end
            x_MAC = x_RLE + (b_eff / 6) * (c_root + 2 * c_tip) / (c_root + c_tip) ...
                * tand(Lambda_LE_deg);
            x = x_MAC + 0.4 * B777GeomL2.mac(c_root, c_tip);
        end

    end
end

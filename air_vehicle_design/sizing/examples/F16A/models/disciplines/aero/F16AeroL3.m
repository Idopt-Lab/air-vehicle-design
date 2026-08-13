classdef F16AeroL3 < AeroModelL3
%F16AEROL3  F-16A Block 10 Level-3 aerodynamics student class.
%
%   Inherits AeroModelL3 (abstract enforcer).  L3 is the Raymer Eq. 12.24
%   component drag build-up plus the F-16's own supersonic wave-drag term
%   (Raymer Eq. 12.41, M >= 1.2). Most methods delegate to the AeroL3 static
%   toolbox; drag_polar/get_CD0_buildup add the wave-drag term on top.
%
%   ============================================================================
%   DEPENDENCY INJECTION + INPUT vs DERIVED (optimization-ready design).
%   Constructor takes a REQUIRED injected geometry object and a REQUIRED
%   unified L3 input JSON path (f16a_spec_path(3); reads its .aerodynamics
%   block; no silent defaults). Properties split:
%
%     (1) INPUTS -- plain/Constant blocks of genuine aero constants only:
%         per-component interference Q, laminar fraction, body/surface flag,
%         surface roughness, max-thickness chordwise station, airfoil section
%         data, wave-drag factor, misc/leakage drag allowances, and the
%         high-lift/gear control-surface estimates. From the unified L3 JSON's
%         .aerodynamics block.
%
%     (2) DERIVED (Dependent) -- ALL geometry read LIVE from the injected
%         geometry object: reference area/AR/sweep/taper AND the per-component
%         wetted-area / reference-length / diameter / t-c / max-thickness-line-
%         sweep arrays (component order: wing, HT, VT, fuselage, duct). NO
%         geometry number is stored on this class -- the historical hardcoded
%         component arrays (S_wet_comp=[397 130 111 644 139], l_ref_comp,
%         D_comp, tc_comp, Lambda_m_comp=[35 35 42 0 0], Lambda_c4_deg=37) are
%         gone; each is rebuilt live from obj.geom on every read.
%   ============================================================================
%
%   Inheritance: AerodynamicsBase -> AeroModelL3 -> F16AeroL3
%   Component order: [1] wing, [2] HT, [3] VT, [4] fuselage, [5] duct

    % ======================================================================= %
    % INPUTS -- aero-only constants (from the unified L3 JSON's .aerodynamics
    % block). NO geometry.
    % ======================================================================= %
    properties
        geom              % injected geometry object (all geometry read live from it)
        ctrl              % injected ControlSurfaceSizer -- supplies the flaperon AND leading-edge-flap chord/span fractions (see the constructor and the Dependent block)

        aircraft_category % string; canonical top-level class flag, read from the unified JSON's top-level aircraft_category key (same as F16AeroL1/L2 expose). Not used by any L3 aero equation -- exposed so mission analysis can read aero.aircraft_category by DI at every fidelity for the Roskam Table 2.1/2.2 row.

        % Airfoil (NACA 64A204).
        alpha_L0          % deg; zero-lift AOA (drives CL_minD -> K2)
        cl_max_2D         % 2-D section cl_max (feeds clean CLmax, Eq. 12.15)
        cl_alpha_2D       % 1/rad; 2-D lift slope -> eta term (Raymer Eq. 12.8). Added 2026-07-25: without it AeroL2.get_CL_alpha fell back to eta=0.95, so L3 was LESS informed than L2 on the same airfoil.

        % Per-component aero constants (component order above).
        x_c_max_comp      % — chordwise max-thickness station (surfaces; 0 for bodies)
        Q_comp            % — interference factor            [Raymer Table 12.6]
        f_lam_comp        % — laminar-flow fraction
        is_body_comp      % logical — true selects the body form factor (Eq. 12.31)

        k                 % ft  — equivalent surface roughness (smooth paint) [Raymer Table 12.4/12.5]
        E_WD              % — wave-drag efficiency factor (TUNED calibration input) [Raymer Eq. 12.45]
        CD0_LandP         % — leakage & protuberance allowance [Raymer Sec. 12.5]

        % Miscellaneous drag areas (D/q, ft^2) composing CD0_misc [Raymer Table 12.7].
        Dq_gun_port       % single cannon port
        Dq_hook_USAF      % arresting hook, USAF
    end

    properties (Constant)
        % --- Trailing-edge flaperon control-surface estimates (aero spec, not
        % geometry; not in the aero JSON).
        % delta_flap_TO/L_deg = 20 deg, BOTH takeoff and landing, web-sourced
        % 2026-07-30 (f-16.net forum + Aerosoft F-16 simulator manual, cross-
        % checking each other): with gear down the flaperons go to 20 deg as
        % trailing-edge flaps; during ground roll before liftoff the TEF is
        % also 20 deg down (only retracting above 240-370 kt once airborne).
        % Was previously an uncited 15/20 deg split (TO/L) -- the 15 deg TO
        % figure is corrected; the two conditions use the SAME TEF setting.
        % c_flap_over_c / eta_flap_in / eta_flap_out MOVED 2026-08-10 to the
        % Dependent block, reading the injected obj.ctrl -- see the constructor.
        % The 20 deg down deflection is now CORROBORATED by a configuration
        % summary the user supplied 2026-08-10 (same class of secondary web
        % source as the 2026-07-30 note above): flaperon 20 deg down, 23 deg up.
        % The 23 deg up figure has no consumer in the high-lift path.
        hld_TE            = "plain"
        delta_flap_TO_deg = 20
        delta_flap_L_deg  = 20
        k_f_flap          = 0.28    % Raymer 6th ed. Eq. 12.62 (partial-span)

        % --- Leading-edge flap.
        %
        % ★ WHAT THIS DEVICE IS: the F-16's LEF is NOT a control effector --
        % it does not respond to pitch, roll or yaw commands. It DOES respond
        % to angle of attack: the flight control system schedules it on AoA
        % and dynamic-to-static pressure ratio to keep the flow over the wing
        % from separating (delay stall), not to fly the aircraft (user
        % clarification, 2026-08-10/2026-08-11). The three actual effectors
        % are the all-moving stabilator, the flaperons and the rudder. This
        % matters for reading the code: the LEF appears in
        % ControlSurfaceSizer's output and in geom.S_csw/S_cs because it is an
        % actuated surface with real area that a weight equation must see --
        % NOT because it flies the aeroplane.
        %
        % c_lef_over_c / eta_lef_in / eta_lef_out (RENAMED from c_slat_over_c/
        % eta_slat_* 2026-08-11) MOVED 2026-08-10 to the Dependent block,
        % reading the injected obj.ctrl's LEF fractions.
        %
        % RECLASSIFIED 2026-08-11 from Raymer Table 12.2's 'slat' row to its
        % 'leading-edge flap' row (VnV/BrandtF16A/todo.md 2026-08-11). Brandt's
        % own F-16A.xls 'Main' sheet chart ("Chart 17", series "LE Flap",
        % Geom!$L$186:$M$190) names this device a FLAP and draws it as a
        % constant-chord parallelogram (1.3105 ft inboard, 1.3106 ft outboard)
        % -- a hinged, non-translating panel, consistent with Raymer's
        % 'leading-edge flap'/'kruger flap' row (flat Delta_cl_max=0.3, no
        % chord-extension c'/c term), not 'slat' (0.4*c'/c, for devices that
        % translate forward on tracks). This retires the 2026-08-11
        % cp_over_c_slat placeholder -- there is no c'/c to source for this
        % row. hld_LE used to stay "slat" only because that was the literal
        % Table 12.2 row name being looked up; it no longer is.
        %
        % TODO: verify vs T.O. 1F-16A-1. The LEF is NOT a fixed "TO/L config"
        % value in reality -- it is auto-scheduled by the flight control
        % computer as a function of AoA and Mach, and sits at -2 deg only
        % during ground roll/taxi before rotation (web-sourced 2026-07-30,
        % same sources as the TEF note above). delta_lef_TO/L_deg = 17 here
        % is a stand-in for the LEF position near the high-AoA rotation/
        % touchdown condition these CLmax_TO/CLmax_L values represent, NOT
        % the ground-roll -2 deg figure -- plugging in -2 deg would be wrong
        % for a different flight regime. Still unpinned against a primary
        % schedule (AoA/Mach breakpoints, not a single number).
        hld_LE            = "leading-edge flap"
        F_lef             = 0.0144  % Raymer Eq. 12.61 "F_flap" analog (plain, un-slotted)
        delta_lef_TO_deg  = 17
        delta_lef_L_deg   = 17
        k_lef             = 0.14    % Raymer Eq. 12.62 "k_f" analog (full-span)

        % --- Landing-gear component-buildup inputs [Raymer Table 12.6].
        Dq_wheels        = 0.18     % regular wheel + tire
        Dq_strut_highRE  = 0.30     % round strut, high Re
        Dq_strut_lowRE   = 1.17     % round strut, low Re
        strut_ref_length = 0.3      % ft (estimated strut diameter) -- TODO verify
        n_nosewheel      = 1
        n_mainwheel      = 2
        n_gear_legs      = 3
    end

    % ======================================================================= %
    % DERIVED -- geometry read live from obj.geom on every read (no cache).
    % Read-only. Component arrays are in the order wing/HT/VT/fuselage/duct.
    % ======================================================================= %
    properties (Dependent)
        S_ref             % ft^2  <- geom.S_ref
        AR                % —     <- geom.AR_wing
        Lambda_LE_deg     % deg   <- geom.LE_sweep_wing
        Lambda_c4_deg     % deg   <- geom.QC_sweep_wing (~32.2, fixes the 37 bug)
        taper             % —     <- geom.lambda_wing

        %HIGH-LIFT-DEVICE FRACTIONS  Chord fractions and span bands for the two
        %   wing devices, read LIVE from the injected ControlSurfaceSizer (ADDED
        %   2026-08-10). Same surfaces whose AREAS that object sizes, so the
        %   framework holds ONE description of each instead of the three
        %   disagreeing copies it held before -- see the constructor.
        %   c_lef_over_c (RENAMED from c_slat_over_c 2026-08-11) is the F-16's
        %   leading-edge FLAP, per Raymer Table 12.2's 'leading-edge flap' row
        %   (see the properties block's reclassification note).
        c_flap_over_c     % —     flaperon chord/wing chord   <- ctrl.c_flaperon_frac
        eta_flap_in       % —     flaperon inboard station    <- ctrl.eta_flaperon_in
        eta_flap_out      % —     flaperon outboard station   <- ctrl.eta_flaperon_out
        c_lef_over_c      % —     LEF chord/wing chord (cf/c) <- ctrl.c_lef_frac
        eta_lef_in        % —     LEF inboard station         <- ctrl.eta_lef_in
        eta_lef_out       % —     LEF outboard station        <- ctrl.eta_lef_out

        S_wet_comp        % ft^2  per-component wetted area   <- geom (Roskam Eq.12.1/12.3, frustum)
        l_ref_comp        % ft    per-component MAC / length  <- geom (MAC = Raymer Eq. 7.8)
        D_comp            % ft    per-component body diameter  <- geom (0 for surfaces)
        tc_comp           % —     per-component thickness ratio<- geom (mean root/tip for HT/VT)
        Lambda_m_comp     % deg   per-component max-thickness-line sweep <- geom (convert_sweep at x_c_max)

        %AMAX_FT2, L_AIRCRAFT_FT  Whole-aircraft wave-drag geometry, now read
        %   LIVE from the injected geometry object (Phase 2, 2026-07-25). Both
        %   were plain INPUT properties fed from f16a_L3.json's
        %   .aerodynamics.wave_drag block, whose values were Brandt geometry
        %   OUTPUTS (Geom!B20 = 25.110556, Geom!B21 = 48.303947) frozen as aero
        %   inputs — while geometry_brandt_comparison.m reported Amax as "NOT
        %   MODELED". The framework consumed as an input the very number it
        %   reported as unmodelled, and the Sears-Haack term could not respond to
        %   a fuselage change. That JSON block is deleted; these are Dependent.
        Amax_ft2          % ft^2 <- geom.Amax. TIER-SPECIFIC: area-ruled buildup at L3 (24.7037, what Eq. 12.44 wants), fuselage-envelope ellipse at L2 (27.4889). See get.Amax_ft2.
        L_aircraft_ft     % ft   <- geom.L_aircraft (overall length input, distinct from the fuselage L_fus)

        CD0_misc          % — (Dq_gun_port + Dq_hook_USAF)/S_ref  [Raymer Table 12.7], live (S_ref from geom)
    end

    methods

        function obj = F16AeroL3(geom, json_path, ctrl)
        %F16AEROL3  Construct from a required injected geometry object, a
        %   required unified L3 input JSON path (f16a_spec_path(3)) whose
        %   .aerodynamics block is read, and a required injected
        %   ControlSurfaceSizer. No silent defaults: all three must be
        %   supplied. Sets ONLY the aero constants; all geometry (incl.
        %   per-component arrays) is produced live by the Dependent getters
        %   from obj.geom, and the high-lift devices' chord/span fractions from
        %   obj.ctrl.
        %
        %   ctrl ADDED 2026-08-10 -- SINGLE SOURCE OF TRUTH for both wing
        %   devices. c_flap_over_c / eta_flap_in/out were hardcoded here AND,
        %   verbatim, on F16AeroL2, while ControlSurfaceSizer described the same
        %   flaperon with different numbers. All six fractions are Dependent on
        %   obj.ctrl now.
        %
        %   DELIBERATELY STILL OWNED HERE: deflections (delta_flap_*,
        %   delta_lef_*), the Table 12.2 device rows (hld_TE/hld_LE) and the
        %   Raymer equation coefficients (k_f_flap, k_lef, F_lef) -- aero
        %   operating conditions and equation constants, not resizable geometry.
            arguments
                % GeometryBase is too weak a guard -- it declares only
                % S_ref/S_wet/get_S_ref/get_S_wet, while this class reads ~20
                % members off obj.geom. A wrong tier therefore constructed
                % cleanly and then died mid-run inside get.S_wet_comp, or worse
                % resolved members whose MEANING differed (before Phase 2's
                % rename, GeometryModelL3's AR_ht/lambda_ht were EXPOSED-planform
                % while GeometryModelL2's are FULL -- silently wrong MAC, Re and
                % form factor, no error). Narrowed 2026-07-25 so a bad tier fails
                % at CONSTRUCTION; both L2 and L3 geometry satisfy the contract.
                geom      (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                ctrl      (1,1) ControlSurfaceSizer
            end
            obj.geom = geom;
            obj.ctrl = ctrl;

            Jfull = jsondecode(fileread(json_path));
            obj.aircraft_category = string(Jfull.aircraft_category);
            J = Jfull.aerodynamics;
            obj.alpha_L0    = J.airfoil.alpha_L0_deg;   % [NACA 64A204]
            obj.cl_max_2D   = J.airfoil.cl_max_2D;      % 1.20 (locked, matches L2)
            obj.cl_alpha_2D = J.airfoil.cl_alpha_per_deg * 180/pi;   % deg -> rad, same conversion as F16AeroL2

            % Per-component constants (order: wing, HT, VT, fuselage, duct).
            obj.x_c_max_comp = [J.x_c_max.wing, J.x_c_max.horizontal_tail, ...
                                J.x_c_max.vertical_tail, J.x_c_max.fuselage, J.x_c_max.duct];
            obj.Q_comp       = [J.interference_factor_Q.wing, J.interference_factor_Q.horizontal_tail, ...
                                J.interference_factor_Q.vertical_tail, J.interference_factor_Q.fuselage, ...
                                J.interference_factor_Q.duct];
            obj.f_lam_comp   = [J.laminar_fraction_f_lam.wing, J.laminar_fraction_f_lam.horizontal_tail, ...
                                J.laminar_fraction_f_lam.vertical_tail, J.laminar_fraction_f_lam.fuselage, ...
                                J.laminar_fraction_f_lam.duct];
            obj.is_body_comp = logical([J.is_body.wing, J.is_body.horizontal_tail, ...
                                J.is_body.vertical_tail, J.is_body.fuselage, J.is_body.duct]);
            obj.k            = J.surface_roughness_k_ft.wing;   % uniform roughness
            obj.E_WD         = J.wave_drag_factor_E_WD;
            % Amax_ft2 / L_aircraft_ft are NOT read here any more -- they are
            % Dependent on obj.geom (Phase 2, 2026-07-25). The
            % .aerodynamics.wave_drag JSON block they used to come from is gone.
            obj.CD0_LandP    = J.CD0_LandP;
            obj.Dq_gun_port  = J.misc_drag_areas.Dq_gun_port_ft2;
            obj.Dq_hook_USAF = J.misc_drag_areas.Dq_hook_USAF_ft2;
        end

        % ---- Dependent scalar geometry getters (live from obj.geom) -------- %
        function v = get.S_ref(obj);         v = obj.geom.S_ref;         end
        function v = get.AR(obj);            v = obj.geom.AR_wing;       end
        function v = get.Lambda_LE_deg(obj); v = obj.geom.LE_sweep_wing; end
        function v = get.Lambda_c4_deg(obj); v = obj.geom.QC_sweep_wing; end
        function v = get.taper(obj);         v = obj.geom.lambda_wing;   end

        % ---- High-lift-device fractions, live from the injected sizer ----- %
        function v = get.c_flap_over_c(obj); v = obj.ctrl.c_flaperon_frac; end
        function v = get.eta_flap_in(obj);   v = obj.ctrl.eta_flaperon_in; end
        function v = get.eta_flap_out(obj);  v = obj.ctrl.eta_flaperon_out; end
        function v = get.c_lef_over_c(obj);  v = obj.ctrl.c_lef_frac;      end
        function v = get.eta_lef_in(obj);    v = obj.ctrl.eta_lef_in;      end
        function v = get.eta_lef_out(obj);   v = obj.ctrl.eta_lef_out;     end

        % ---- Dependent per-component geometry arrays (live from obj.geom) -- %
        function v = get.S_wet_comp(obj)
            g = obj.geom;
            v = [g.S_wet_wing, g.S_wet_ht, g.S_wet_vt, g.get_S_wet_fuselage(), g.get_S_wet_duct()];
        end
        function v = get.l_ref_comp(obj)
            % Reference length per component: wing/HT/VT MAC (Raymer Eq. 7.8),
            % fuselage/duct length. HT/VT MAC is not exposed by the geometry
            % object directly, so it is recomputed from the injected root chord
            % and taper via the shared GeometryBase.compute_mac static.
            g = obj.geom;
            mac_ht = GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht);
            mac_vt = GeometryBase.compute_mac(g.c_root_vt, g.lambda_vt);
            v = [g.cbar_wing, mac_ht, mac_vt, g.L_fus, g.L_duct];
        end
        function v = get.D_comp(obj)
            g = obj.geom;
            v = [0, 0, 0, g.D_fus, g.D_inlet];
        end
        function v = get.tc_comp(obj)
            % Wing modeled uniform-tc; HT/VT use the mean of the injected
            % root/tip t/c pair; bodies use 0 (they take the body form factor).
            g = obj.geom;
            v = [g.tc_wing, (g.tc_r_ht + g.tc_t_ht)/2, (g.tc_r_vt + g.tc_t_vt)/2, 0, 0];
        end
        function v = get.Lambda_m_comp(obj)
            % Max-thickness-line sweep per surface: convert the injected LE
            % sweep to the chordwise max-thickness station x_c_max via the
            % shared GeometryBase sweep identities (fixes the old hardcoded
            % [35 35 42] estimate). Wing/HT are MIRRORED surfaces (4/AR form);
            % the VT is a SINGLE PANEL, so it takes convert_sweep_panel's 2/AR
            % form -- using the mirrored form there fed a wrong max-thickness
            % sweep into the Raymer Eq. 12.30 VT form factor and hence the whole
            % L3 CD0 buildup (fixed 2026-07-25: 28.70 -> 34.73 deg). Bodies: 0.
            g = obj.geom;
            wing = GeometryBase.convert_sweep(g.LE_sweep_wing, g.AR_wing, g.lambda_wing, obj.x_c_max_comp(1));
            ht   = GeometryBase.convert_sweep(g.LE_sweep_ht,   g.AR_ht,   g.lambda_ht,   obj.x_c_max_comp(2));
            vt   = GeometryBase.convert_sweep_panel(g.LE_sweep_vt, g.AR_vt, g.lambda_vt, obj.x_c_max_comp(3));
            v = [wing, ht, vt, 0, 0];
        end
        function v = get.CD0_misc(obj)
            v = (obj.Dq_gun_port + obj.Dq_hook_USAF) / obj.S_ref;   % [Raymer Table 12.7]
        end

        function v = get.Amax_ft2(obj)
            % Whole-aircraft max cross-section, live from the injected geometry.
            %
            % WHAT THIS IS DEPENDS ON THE INJECTED TIER, deliberately:
            %   F16GeomL3 -> the AREA-RULED buildup: MAX over 20 x-stations of
            %      (rescaled fuselage frames + wing/HT/VT cosine sections +
            %      nacelle) less n_eng*pi*D^2/5. F-16A: 24.7037 ft^2. This is
            %      the quantity Raymer Eq. 12.44 actually wants, and it is what
            %      an L3 aero object should be given.
            %   F16GeomL2 -> the fuselage-ENVELOPE ellipse (pi/4)*W*H = 27.4889,
            %      which readme_geom.md Sec 7 classifies as the LOW-fidelity
            %      Amax. Correct for L2, WRONG for L3 -- injecting an L2 geometry
            %      here silently substitutes a fuselage-only quantity for a
            %      whole-aircraft one and inflates CD0_wave ~23%.
            %
            % With the area-ruled Amax, CD0_wave sits -0.54% from the
            % Brandt-referenced term with E_WD = 2.2 UNCHANGED -- no retune.
            %
            % Brandt Geom!B20 = 25.110556 is the same KIND of quantity as the L3
            % value -- an area-ruled MAX (32.971053) net of a 7.8605 ft^2 engine
            % flow-through deduction -- so the -1.62% gap is a genuine, small
            % fidelity difference (L3's fuselage is 47.5 ft vs Brandt's 46.5),
            % not the definitional mismatch the ellipse had. TestGeomL3's
            % round-trip control reproduces Geom!B20 to -0.0001% when L_fus is
            % set back to 46.5. See F16GeomL3.md §4 and
            % VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 Sec 4b (the affine
            % rescaling is UNCITED) and Sec 5 (the bare pi*D^2/5 literal).
            v = obj.geom.Amax;
        end

        function v = get.L_aircraft_ft(obj)
            % Overall aircraft length, live from geometry (47.65 ft published
            % airframe length). Distinct from the fuselage L_fus used for the
            % component skin-friction Re and FF_body -- do not conflate the two
            % length scales. Provenance is a STANDING OPEN item: the value is
            % user-approved but is not traceable to any document in this repo,
            % and Brandt Geom!B21 = 48.303947 is a MAX() over x-stations, i.e. an
            % extent rather than a spec length, so it does not pin it
            % (todo.md 2026-07-25 Phase 2 §6).
            v = obj.geom.L_aircraft;
        end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, state)
        %DRAG_POLAR  L3 component buildup + F-16 supersonic wave drag.
        %   Delegates the regime handling and K1/K2 to AeroL3.drag_polar, which
        %   calls obj.get_CD0_buildup (this class's override, adding wave drag
        %   for M >= 1.2) via dynamic dispatch.
            polar = AeroL3.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Geometry-based clean CLmax, Raymer 6th ed. Eq. 12.15
        %   (0.9*cl_max_2D*cos(Lambda_c/4)), same basis as L2. See
        %   AeroL2.CLmax_clean for the F-16 vortex-lift (LEX/strake) limitation.
            CLmax = AeroL2.CLmax_clean(obj.cl_max_2D, obj.Lambda_c4_deg);
        end

        function val = get_CD0_buildup(obj, state)
        %GET_CD0_BUILDUP  Generic Raymer Eq. 12.24 buildup (AeroL3) + the F-16's
        %   own supersonic wave-drag term (Eq. 12.41), added only for M >= 1.2
        %   (Eq. 12.41's own domain). No transonic fairing (1.0 < M < 1.2).
            val = AeroL3.get_CD0_buildup(obj, state);
            if state.mach >= 1.2
                val = val + obj.compute_CD0_wave(state);
            end
        end

        function val = compute_CD0_wave(obj, state)
        %COMPUTE_CD0_WAVE  Supersonic wave drag due to volume distribution.
        %   Raymer 6th ed. Eq. 12.44 (Sears-Haack) + Eq. 12.45 (E_WD / sweep /
        %   Mach correction), valid M >= 1.2:
        %     (D/q)_SH   = (9*pi/2)*(Amax/l)^2                                  [12.44]
        %     (D/q)_wave = E_WD*[1 - 0.386*(M-1.2)^0.57*(1 - pi*Lambda_LE^0.77/100)]*(D/q)_SH  [12.45]
        %     CD0_wave   = (D/q)_wave / S_ref
        %   Amax/l are WHOLE-AIRCRAFT quantities read LIVE from the injected
        %   geometry object via the Dependent obj.Amax_ft2 / obj.L_aircraft_ft
        %   (Phase 2, 2026-07-25) -- so this term now responds to a fuselage
        %   change instead of staying pinned to the baseline airframe. They are
        %   distinct from the fuselage-component L_fus/D_fus used elsewhere for
        %   the skin-friction Re/FF_body calc; do not conflate the two length
        %   scales.
        %
        %   E_WD IS NOT MIS-CALIBRATED BY THIS CHANGE, and was not retuned.
        %   E_WD = 2.2 was tuned against Brandt's own Amax/l pair, so the risk of
        %   replacing his frozen inputs was that the tuning would no longer
        %   apply. It still does, because the L3 Amax is the same KIND of
        %   quantity he computed: (Amax/l)^2 moves only 0.270239 -> 0.268780,
        %   and CD0_wave lands -0.54% from the Brandt-referenced term with
        %   E_WD = 2.2 untouched. The E_WD that would make it exact is 2.2119 --
        %   0.54% away, i.e. well inside the noise of a tuned factor, so no
        %   retune is justified or applied.
        %   (An intermediate 2026-07-25 version used the fuselage-ENVELOPE
        %   ellipse here, which DID inflate this term +23.15% and would have
        %   needed E_WD = 1.7864 to hide it. That was a fidelity inversion --
        %   a low-fidelity Amax in the high-fidelity tier -- and was replaced by
        %   the area-ruled buildup rather than absorbed by retuning. See
        %   f16a_L3.json's _amax_via_DI note; the _TODO_wave_drag_factor_E_WD
        %   marker stays open for the separate question of whether 2.2 is
        %   sourceable at all.)
            M     = state.mach;
            Dq_SH = (9*pi/2) * (obj.Amax_ft2 / obj.L_aircraft_ft)^2;
            val   = obj.E_WD ...
                * (1 - 0.386 * (M - 1.2)^0.57 * (1 - (pi*obj.Lambda_LE_deg^0.77)/100)) ...
                * Dq_SH / obj.S_ref;
        end

        % ---- Auxiliary accessors + buildup primitives (delegations) ------- %
        function e = get_e_osw(obj)
            e = AeroL3.get_e_osw(obj);
        end

        function e = get_e_osw_brandt(obj)
        %GET_E_OSW_BRANDT  Brandt Aero!G12 alternate (comparison report ONLY).
            e = AeroL2.oswald_eff_brandt(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_K1(obj, M)
            val = AeroL3.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL3.get_K2(obj, K1_sub, M);
        end

        function val = get_CL_alpha(obj, M)
            val = AeroL3.get_CL_alpha(obj, M);
        end

        function Re = compute_Re(~, state, l_ref)
            Re = AeroL3.compute_Re(state, l_ref);
        end

        % ================================================================ %
        % High-lift-device / gear deltas (L3: TE flaperon + LE flap from real
        % geometry; gear from the Reynolds-based component buildup). Geometry
        % (taper, S_ref, sweeps) read live via the Dependent getters above.
        % ================================================================ %

        % compute_S_flapped_ratio (Roskam Part II Eq. 7.10) MOVED 2026-08-10 to
        % AeroL2.compute_S_flapped_ratio, the toolbox's low-level tier. It was
        % duplicated verbatim here and on F16AeroL2, and ControlSurfaceSizer is
        % now a third caller (it sizes the flaperon/LEF areas from it). Note the
        % argument list lost its leading ~ -- it is a static now, not a method.

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (plain flap, F_flap=0.0144).
            F_flap = 0.0144;
            S_flapped_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62 (wing quarter-chord sweep).
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CD0_lef(obj, delta_lef_deg)
        %DELTA_CD0_LEF  Raymer 6th ed. Eq. 12.61 FORM, adapted for the F-16 LE
        %   flap (no separately-cited LE analog exists in the text). RENAMED
        %   from Delta_CD0_slat 2026-08-11 -- unaffected by that entry's
        %   reclassification, which only touched Delta_CLmax_lef; this term
        %   still uses c_lef_over_c (cf/c), unchanged.
            S_lef_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_lef_out, obj.eta_lef_in, obj.taper);
            val = obj.F_lef * obj.c_lef_over_c * S_lef_ratio * (delta_lef_deg - 10);
        end

        function val = Delta_CDi_lef(obj, Delta_CL_lef)
        %DELTA_CDI_LEF  Raymer 6th ed. Eq. 12.62 FORM, adapted for the LE flap.
        %   RENAMED from Delta_CDi_slat 2026-08-11.
            val = obj.k_lef * Delta_CL_lef^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21.  config 'TO'/'L'.
            S_flapped_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = AeroL2.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_lef(obj, config)
        %DELTA_CLMAX_LEF  Raymer 6th ed. Table 12.2 + Eq. 12.21 for the LE
        %   flap (full-span; hinge line = wing LE sweep). RENAMED from
        %   Delta_CLmax_slat 2026-08-11 -- RECLASSIFIED from Raymer's 'slat'
        %   row (0.4*c'/c) to its 'leading-edge flap' row (flat 0.3, no chord
        %   term at all -- see the properties block). NaN is passed for the
        %   chord-ratio argument: the lookup's switch never reads it for
        %   'leading-edge flap'/'kruger flap', so there is no value to source
        %   here (unlike 'slat', which would multiply by it).
            S_lef_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_lef_out, obj.eta_lef_in, obj.taper);
            S_lef_area  = S_lef_ratio * obj.S_ref;
            Delta_cl_max = AeroL2.lookup_Delta_cl_max_values(obj.hld_LE, config, NaN);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_lef_area, obj.S_ref, obj.Lambda_LE_deg);
        end

        function val = compute_Delta_CD0_geardown(obj, state)
        %COMPUTE_DELTA_CD0_GEARDOWN  Landing-gear parasite-drag increment via
        %   the Reynolds-based component machinery + Dq_wheels/Dq_strut_*
        %   [Raymer Table 12.6]. F-16 tricycle gear: 1 nose + 2 main, 3 struts.
            Re = obj.compute_Re(state, obj.strut_ref_length);
            if Re > 3.0e5
                CD0_strut = obj.Dq_strut_highRE / obj.S_ref;
            else
                CD0_strut = obj.Dq_strut_lowRE / obj.S_ref;
            end
            CD0_wheels = obj.Dq_wheels / obj.S_ref;
            val = CD0_wheels * (obj.n_nosewheel + obj.n_mainwheel) + CD0_strut * obj.n_gear_legs;
        end

        function val = get_Delta_e_osw_TO(obj)
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj, state)
        %GET_DELTA_CD0_TO  Flap (Eq. 12.61) + LEF (Eq. 12.61 form) + gear (buildup).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.Delta_CD0_lef(obj.delta_lef_TO_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CD0_L(obj, state)
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.Delta_CD0_lef(obj.delta_lef_L_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CLmax_TO(obj)
            val = obj.Delta_CLmax_flap('TO') + obj.Delta_CLmax_lef('TO');
        end

        function val = get_Delta_CLmax_L(obj)
            val = obj.Delta_CLmax_flap('L') + obj.Delta_CLmax_lef('L');
        end

        function val = get_Delta_CDi_TO(obj)
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('TO')) + obj.Delta_CDi_lef(obj.Delta_CLmax_lef('TO'));
        end

        function val = get_Delta_CDi_L(obj)
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('L')) + obj.Delta_CDi_lef(obj.Delta_CLmax_lef('L'));
        end

        function val = get_CLmax_TO(obj)
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range (Roskam Table 3.6).
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

    end
end

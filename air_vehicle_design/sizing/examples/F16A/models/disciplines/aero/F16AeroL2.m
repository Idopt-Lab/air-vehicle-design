classdef F16AeroL2 < AeroModelL2
%F16AEROL2  F-16A Block 10 Level-2 aerodynamics student class.
%
%   Inherits AeroModelL2 (abstract enforcer).  L2 is the GEOMETRY-DEPENDENT
%   clean drag polar + finite-wing lift; every abstract method delegates to the
%   AeroL2 static toolbox, EXCEPT drag_polar's supersonic branch (see below).
%
%   SUPERSONIC WAVE DRAG (added 2026-07-29): the generic AeroL2 toolbox's
%   supersonic CD0 is turbulent skin friction only (no wave-drag term -- see
%   AeroL2.get_CD0_supersonic's header), which reads LOWER than the subsonic
%   CD0 at the F-16's M=1.6 Max Mach point -- physically backwards, and found
%   to be the dominant reason the L2 constraint diagram's Max Mach curve read
%   ~70-80% low vs. Brandt across the whole W/S range. This class overrides
%   drag_polar to add Brandt's own whole-aircraft wave-drag increment
%   (compute_CD0_wave, Brandt Aero!B8/G8) on top of the subsonic CD0 for
%   M >= MACH_SUPERSONIC_MIN -- deliberately kept HERE (F-16-specific), not in
%   the generic toolbox, since it is Brandt's own tuned formula (E_WD=2.2),
%   not a generic textbook equation another aircraft could reuse untuned. This
%   is intentionally simpler than L3's full Raymer Eq. 12.44/12.45 buildup
%   (F16AeroL3.compute_CD0_wave) -- no per-component analysis, just the
%   whole-aircraft Sears-Haack term -- appropriate to L2's fidelity tier.
%
%   ============================================================================
%   DEPENDENCY INJECTION + INPUT vs DERIVED (optimization-ready design).
%   The constructor takes a REQUIRED injected geometry object and a REQUIRED
%   unified L2 input JSON path (f16a_spec_path(2); reads its .aerodynamics
%   block). No silent defaults for either.
%   Properties split into two blocks, mirroring F16GeomL2:
%
%     (1) INPUTS -- a plain, mutable `properties` block holding ONLY genuine
%         aero spec data (equivalent skin-friction coefficient, airfoil section
%         properties, Oswald-e method selector, and control-surface / high-lift
%         estimates). Set once by the constructor from the JSON.
%
%     (2) DERIVED (Dependent) -- geometry read LIVE from the injected geometry
%         object on every read (S_ref, S_wet, AR, leading-edge & quarter-chord
%         sweep, taper, characteristic length). NO geometry number is stored on
%         this class: when an optimizer mutates a geometry input
%         (obj.geom.AR_wing = ...), the next aero read reflects it. This
%         removes the historical hardcoded-geometry bugs (S_wet=1371 [a Brandt
%         back-calc output], Lambda_c4_deg=37 [wrong; the injected quarter-chord
%         sweep is ~32.2 deg], AR/S_ref/Lambda_LE/taper literals).
%   ============================================================================
%
%   Inheritance: AerodynamicsBase -> AeroModelL2 -> F16AeroL2
%
%   Expected outputs (fresh F16GeomL2, subsonic clean):
%     CD0   = Cfe*(S_wet/S_ref) = 0.0035*1466.8/300 ~ 0.0171   [Raymer Eq. 12.23]
%     e     = Raymer Eq. 12.49 (AR=3, Lambda_LE=40) ~ 0.908
%     K1    = 1/(pi*AR*e) ~ 0.117
%     CLmax = 0.9*1.20*cos(32.2 deg) ~ 0.914                    [Raymer Eq. 12.15]

    % ======================================================================= %
    % INPUTS -- aero-only spec data (mutable; from the unified L2 JSON's
    % .aerodynamics block). NO geometry here (see the Dependent block below).
    % ======================================================================= %
    properties
        geom              % injected geometry object (all geometry read live from it)
        ctrl              % injected ControlSurfaceSizer -- supplies the flaperon chord/span fractions (see the constructor and the Dependent block)

        %AIRCRAFT_CATEGORY  Canonical class flag ("jet_fighter"); selects the
        %   Raymer Table 12.3 Cfe row. Read from the single top-level
        %   aircraft_category key -- see the Dependent Cfe below.
        aircraft_category

        e_method          % Oswald-e selector; "official" -> Raymer Eq. 12.48/12.49

        % Airfoil section data (NACA 64A204) -- from JSON airfoil block.
        airfoil_name
        airfoiltype       % "cambered"/"uncambered"; a nonzero alpha_L0 -> K2 != 0
        design_CL         % airfoil design lift coefficient (0.2 for 64A204)
        alpha_L0          % deg; zero-lift AOA (drives CL_minD -> K2)
        cl_max_2D         % 2-D section cl_max (feeds clean CLmax, Eq. 12.15)
        cl_alpha_2D       % 1/rad; 2-D lift slope (optional eta term, Eq. 12.8)

        % --- Trailing-edge flap (flaperon) aero spec. NOT geometry and not in
        % the aero JSON; carried as flagged hardcoded inputs.
        %
        % c_flap_over_c / eta_flap_in / eta_flap_out MOVED 2026-08-10 to the
        % Dependent block, reading the injected obj.ctrl -- see the constructor
        % for why. What stays here is deflection and equation-coefficient data,
        % which no sizing loop resizes.
        %
        % delta_flap_L_deg = 20 CORROBORATED 2026-08-10 against a
        % configuration summary the user supplied (F-16.net / StackExchange /
        % ryanporto.com, secondary web sources): the flaperon deflects up to 20
        % deg DOWN and 23 deg UP. The high-lift path uses the down deflection
        % only, so the 20 matches. The 23 deg up figure has no consumer here.
        % delta_flap_TO_deg = 15 remains UNCITED and disagrees with F16AeroL3's
        % 20 for the same aircraft -- see that class, which records web-sourced
        % evidence (2026-07-30) that takeoff and landing use the SAME 20 deg
        % setting. Left at 15 here rather than silently changed: it moves L2
        % takeoff CLmax and belongs in a deliberate aero decision, not this
        % control-surface change. Logged in VnV/BrandtF16A/todo.md.
        hld_TE            = "plain"
        delta_flap_TO_deg = 15
        delta_flap_L_deg  = 20
        k_f_flap          = 0.28    % Raymer 6th ed. Eq. 12.62 (partial-span)

        % --- Leading-edge flap, ADDED 2026-08-10 -- L2 previously modeled NO
        % leading-edge device at all, only the trailing-edge flaperon above.
        % That is a real fidelity gap, not a simplification: LandingConstraint.
        % WS_max() and TakeoffConstraint read CLmax_TO/CLmax_L straight from
        % this class, so SizingLoopL2's landing wall was missing the LEF's
        % lift contribution entirely while SizingLoopL3 (via F16AeroL3) had
        % it -- exactly the gap VnV/BrandtF16A/todo.md's 2026-08-10 entry
        % traces as the reason L2 and L3's W/S optima, which happened to
        % coincide before that entry's flaperon-band correction, diverged
        % afterward.
        %
        % RECLASSIFIED 2026-08-11 from Raymer Table 12.2's 'slat' row to its
        % 'leading-edge flap' row (VnV/BrandtF16A/todo.md 2026-08-11). Brandt's
        % own F-16A.xls 'Main' sheet chart ("Chart 17", series "LE Flap",
        % Geom!$L$186:$M$190) names this device a FLAP, not a slat, and draws
        % it as a constant-chord parallelogram (1.3105 ft inboard, 1.3106 ft
        % outboard) -- a hinged, non-translating panel, not a device that
        % slides forward on tracks. Raymer's 'leading-edge flap'/'kruger flap'
        % row is a flat Delta_cl_max=0.3 with NO chord-extension (c'/c) term
        % at all, unlike 'slat' (0.4*c'/c) -- so this reclassification also
        % retires the earlier (2026-08-11) cp_over_c_slat placeholder; there
        % is no c'/c to source for this row.
        %
        % Values, fractions, and citations are IDENTICAL to F16AeroL3's -- same
        % physical device on the same airframe, no L2-specific evidence exists
        % for a different deflection or coefficient, so there is no reason for
        % the two fidelity levels to disagree here. c_lef_over_c/eta_lef_in/
        % eta_lef_out are Dependent below, reading the SAME injected ctrl
        % object F16AeroL3 does (f16a_control_surfaces()), so both classes
        % share one description of the LEF, not two.
        %
        % ★ THE LEF IS NOT A CONTROL EFFECTOR. It does not respond to pitch,
        % roll or yaw commands. It DOES respond to angle of attack: the flight
        % control system schedules it on AoA and dynamic-to-static pressure
        % ratio to keep the flow over the wing from separating (delay stall),
        % not to fly the aircraft (user clarification, 2026-08-10/2026-08-11).
        % It is modeled here for its LIFT and DRAG contribution to
        % CLmax_TO/CLmax_L/CD0_TO/CD0_L -- the three actual control effectors
        % are the all-moving stabilator, the flaperons and the rudder.
        %
        % TODO (ported from F16AeroL3, same open item): the LEF is NOT a fixed
        % "TO/L config" value in reality -- it is auto-scheduled by the flight
        % control computer as a function of AoA and Mach, and sits at -2 deg
        % only during ground roll/taxi before rotation (web-sourced
        % 2026-07-30). delta_lef_TO/L_deg = 17 is a stand-in for the LEF
        % position near the high-AoA rotation/touchdown condition these
        % CLmax_TO/CLmax_L values represent, NOT the ground-roll -2 deg figure.
        % Still unpinned against a primary schedule (AoA/Mach breakpoints, not
        % a single number) -- see TestAeroL2.testTODO_LEFScheduleNotPinned.
        hld_LE            = "leading-edge flap"
        F_lef             = 0.0144  % Raymer Eq. 12.61 "F_flap" analog (plain, un-slotted)
        delta_lef_TO_deg  = 17
        delta_lef_L_deg   = 17
        k_lef             = 0.14    % Raymer Eq. 12.62 "k_f" analog (full-span)

        %E_WD  Wave-drag efficiency factor [Brandt F-16A.xls Aero tab, Aero!B8
        %   formula; VnV/BrandtF16A/BrandtAerodynamics.m's Ewd / readme_aero.md
        %   "Wave drag factor (Sears-Haack reference)"]. A TUNED calibration
        %   input (back-checked to Brandt/Casey, not a measured F-16 datum) --
        %   same value/status as F16AeroL3's E_WD; see f16a_L2.json's
        %   "_TODO_wave_drag_factor_E_WD" and TestAeroL2.testTODO_EWDCalibrationInput.
        E_WD
    end

    % ======================================================================= %
    % DERIVED -- geometry read live from obj.geom on every read (no cache,
    % never stale). Read-only (no set-methods). Fixes the historical hardcoded-
    % geometry bugs by construction.
    % ======================================================================= %
    properties (Dependent)
        %CFE  Equivalent skin-friction coefficient, Raymer Table 12.3, selected
        %   by aircraft_category (0.0035 for an Air Force fighter). Was a stored
        %   JSON input until Phase 3 (2026-07-25): a published table constant is
        %   not an input, and holding it as one invited tuning it -- the
        %   0.005908 value was used to force CD0 onto Brandt's mission
        %   polar, exactly the back-calculated-value-as-input pattern PLAN.md
        %   forbids. The JSON now supplies only the category that selects it.
        Cfe

        S_ref             % ft^2  wing reference area          <- geom.S_ref
        S_wet             % ft^2  total wetted area            <- geom.S_wet
        AR                % —     wing aspect ratio            <- geom.AR_wing
        Lambda_LE_deg     % deg   wing leading-edge sweep      <- geom.LE_sweep_wing
        Lambda_c4_deg     % deg   wing quarter-chord sweep     <- geom.QC_sweep_wing (~32.2, fixes the 37 bug)
        taper             % —     wing taper ratio             <- geom.lambda_wing
        L_char            % ft    characteristic length for the aircraft-level
                          %       supersonic Reynolds number   <- geom.L_fus

        %C_FLAP_OVER_C, ETA_FLAP_IN, ETA_FLAP_OUT  Flaperon chord fraction and
        %   span band, read LIVE from the injected ControlSurfaceSizer (ADDED
        %   2026-08-10). Same physical surface whose AREA that object sizes, so
        %   there is exactly one description of the F-16's flaperon in the
        %   framework now instead of three disagreeing ones -- see the
        %   constructor for the full record. Dependent rather than copied in the
        %   constructor for the usual reason (CLAUDE.md): a copy goes stale the
        %   moment anything changes the sizer.
        c_flap_over_c     % —     flaperon chord/wing chord    <- ctrl.c_flaperon_frac
        eta_flap_in       % —     inboard span station         <- ctrl.eta_flaperon_in
        eta_flap_out      % —     outboard span station        <- ctrl.eta_flaperon_out

        %C_LEF_OVER_C, ETA_LEF_IN, ETA_LEF_OUT  Leading-edge-flap chord
        %   fraction and span band, read LIVE from the injected
        %   ControlSurfaceSizer (ADDED 2026-08-10, closing L2's missing-LEF
        %   fidelity gap -- see the properties block above). c_lef_over_c
        %   (cf/c, RENAMED from c_slat_over_c 2026-08-11) is Raymer's
        %   "flap-chord-fraction" quantity, distinct from the 'slat'-row's
        %   c'/c the class briefly (and incorrectly) used -- see the
        %   properties block's reclassification note. ctrl.c_lef_frac itself
        %   was updated 2026-08-11 from an uncited 0.15 to 0.1157, MEASURED
        %   off Brandt's own chart: cf = 1.31 ft (Main! Chart 17, "LE Flap"
        %   series) / cbar_wing = 11.32 ft (Raymer Eq. 7.8 MAC) -- see
        %   f16a_control_surfaces.m for the full derivation. The SAME
        %   ctrl.c_lef_frac/eta_lef_in/eta_lef_out F16AeroL3 already reads, so
        %   L2 and L3 share one description of the device instead of L2
        %   simply omitting it.
        c_lef_over_c      % —     LEF chord/wing chord (cf/c)  <- ctrl.c_lef_frac
        eta_lef_in        % —     inboard span station         <- ctrl.eta_lef_in
        eta_lef_out       % —     outboard span station        <- ctrl.eta_lef_out

        %AMAX_FT2, L_AIRCRAFT_FT  Whole-aircraft wave-drag geometry, read LIVE
        %   from the injected geometry object (mirrors F16AeroL3's identically-
        %   named Dependent pair). TIER-SPECIFIC, deliberately: obj.geom.Amax is
        %   the fuselage-ENVELOPE ellipse (pi/4)*W*H at L2 -- the correct
        %   L2-fidelity form per F16GeomL2.m's Amax getter and CLAUDE.md's Amax
        %   tiering note -- NOT L3's area-ruled buildup. Do not "unify" the two.
        Amax_ft2          % ft^2  <- geom.Amax (fuselage-envelope ellipse at L2)
        L_aircraft_ft     % ft    <- geom.L_aircraft
    end

    methods

        function obj = F16AeroL2(geom, json_path, ctrl)
        %F16AEROL2  Construct from a required injected geometry object, a
        %   required unified L2 input JSON path (f16a_spec_path(2)) whose
        %   .aerodynamics block is read, and a required injected
        %   ControlSurfaceSizer. No silent defaults: all three must be
        %   supplied. Sets ONLY the aero inputs; all geometry is produced live
        %   by the Dependent getters from obj.geom, and the trailing-edge
        %   flap's chord/span fractions live on obj.ctrl (see below).
        %
        %   ctrl ADDED 2026-08-10 -- SINGLE SOURCE OF TRUTH for the flaperon.
        %   c_flap_over_c / eta_flap_in / eta_flap_out used to be hardcoded
        %   constants here AND, verbatim, on F16AeroL3, while
        %   ControlSurfaceSizer independently described the same physical
        %   surface with different numbers (0.20 x 0.40 as an "aileron"). One
        %   surface, three descriptions, none agreeing. The three fractions are
        %   Dependent getters onto obj.ctrl now, so the flaperon that sets the
        %   high-lift and drag deltas is the same flaperon whose AREA the
        %   sizing loop computes. Same DI pattern F16SandCL3 already uses for
        %   c_elev_frac (commit 8f987af).
        %
        %   DELIBERATELY STILL OWNED HERE: the flap DEFLECTIONS
        %   (delta_flap_TO_deg / delta_flap_L_deg), hld_TE and k_f_flap. Those
        %   are aerodynamic operating conditions and Raymer-equation
        %   coefficients, not control-surface geometry -- a deflection schedule
        %   is not something a sizing loop resizes.
        %
        %   LEADING-EDGE FLAP ADDED 2026-08-10, same ctrl DI pattern: the same
        %   c_lef_over_c/eta_lef_in/eta_lef_out fractions F16AeroL3 already
        %   read from obj.ctrl. L2 previously had NO leading-edge device model
        %   at all -- see the properties block for why that was a real fidelity
        %   gap, not a simplification, and VnV/BrandtF16A/todo.md 2026-08-10.
        %   RECLASSIFIED 'slat' -> 'leading-edge flap' 2026-08-11, see the
        %   properties block.
            arguments
                % GeometryBase is too weak a guard: it declares only
                % S_ref/S_wet/get_S_ref/get_S_wet, so an F16GeomL1 (whose
                % S_wet is a TOGW regression, not a planform) or any other
                % subclass constructed fine and then produced wrong or zero
                % drag at first use rather than failing here. Narrowed
                % 2026-07-25 to the tiers that actually satisfy the aero
                % contract; both L2 and L3 geometry do.
                geom      (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                ctrl      (1,1) ControlSurfaceSizer
            end
            obj.geom = geom;
            obj.ctrl = ctrl;

            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            % ONE canonical category key, top-level: it selects rows in several
            % different discipline tables, so it is not aerodynamics' property to
            % own. Until Phase 3 it was stored three times under two spellings
            % (.geometry.aircraft_category, .aerodynamics.aircraft_type,
            % .weights.aircraft_category) with nothing keeping them in sync.
            obj.aircraft_category = string(J.aircraft_category);
            obj.e_method = string(A.e_method);
            af = A.airfoil;
            obj.airfoil_name = string(af.name);
            obj.airfoiltype  = string(af.airfoiltype);
            obj.design_CL    = af.design_CL;
            obj.alpha_L0     = af.alpha_L0_deg;      % [NACA 64A204]
            obj.cl_max_2D    = af.cl_max_2D;
            % JSON gives the 2-D lift slope per degree; Raymer Eq. 12.8 uses 1/rad.
            obj.cl_alpha_2D  = af.cl_alpha_per_deg * 180/pi;
            obj.E_WD         = A.wave_drag_factor_E_WD;
        end

        % ---- Dependent geometry getters (live from obj.geom) -------------- %
        function v = get.Cfe(obj)
            % Raymer Table 12.3 row selected by the canonical category.
            v = AeroL2.lookup_Cfe(obj.aircraft_category);
        end

        function v = get.S_ref(obj);         v = obj.geom.S_ref;         end
        function v = get.S_wet(obj);         v = obj.geom.S_wet;         end
        function v = get.AR(obj);            v = obj.geom.AR_wing;       end
        function v = get.Lambda_LE_deg(obj); v = obj.geom.LE_sweep_wing; end
        function v = get.Lambda_c4_deg(obj); v = obj.geom.QC_sweep_wing; end
        function v = get.taper(obj);         v = obj.geom.lambda_wing;   end
        function v = get.L_char(obj);        v = obj.geom.L_fus;         end

        % ---- Flaperon fractions, live from the injected sizer ------------- %
        function v = get.c_flap_over_c(obj); v = obj.ctrl.c_flaperon_frac; end
        function v = get.eta_flap_in(obj);   v = obj.ctrl.eta_flaperon_in; end
        function v = get.eta_flap_out(obj);  v = obj.ctrl.eta_flaperon_out; end

        % ---- LEF fractions, live from the injected sizer ------------------ %
        function v = get.c_lef_over_c(obj);  v = obj.ctrl.c_lef_frac;      end
        function v = get.eta_lef_in(obj);    v = obj.ctrl.eta_lef_in;      end
        function v = get.eta_lef_out(obj);   v = obj.ctrl.eta_lef_out;     end
        function v = get.Amax_ft2(obj);      v = obj.geom.Amax;          end
        function v = get.L_aircraft_ft(obj); v = obj.geom.L_aircraft;    end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Subsonic/transonic: unchanged, delegates to the generic
        %   AeroL2 toolbox. Supersonic: F-16-SPECIFIC override -- the generic
        %   toolbox's AeroL2.get_CD0_supersonic is turbulent skin friction only
        %   (no wave drag; see its own header), which reads BELOW the subsonic
        %   CD0 at the F-16's Max Mach point (M=1.6) -- physically backwards,
        %   and the dominant reason the L2 constraint diagram's Max Mach curve
        %   used to read 70-80% low vs. Brandt across the full W/S range
        %   (2026-07-29 investigation). This class instead adds Brandt's own
        %   whole-aircraft wave-drag increment (compute_CD0_wave) on top of the
        %   subsonic CD0, matching the "CD0 = CD0_subsonic + CD_wave" split
        %   Brandt's own Aero-tab methodology uses. K1/K2 are untouched (the
        %   generic K1_supersonic already tracks Brandt's supersonic K1 to a
        %   few percent -- not part of the gap this override fixes).
            M = state.mach;
            regime = AeroL2.flight_regime(M);
            if regime == "supersonic"
                cd0 = AeroL2.get_CD0(obj) + obj.compute_CD0_wave(state);
                k1  = AeroL2.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
                polar = struct('CD0', cd0, 'K1', k1, 'K2', 0);
            else
                polar = AeroL2.drag_polar(obj, state);
            end
        end

        function val = compute_CD0_wave(obj, state)
        %COMPUTE_CD0_WAVE  Whole-aircraft supersonic wave-drag increment.
        %   [Brandt F-16A.xls Aero tab, Aero!B8/G8 -- Sears-Haack volume-wave-
        %   drag term; VnV/BrandtF16A/BrandtAerodynamics.m's aero_at_mach,
        %   readme_aero.md "Wave drag factor (Sears-Haack reference)"]:
        %     CD0_wave = (4.5*pi/S_ref)*(Amax/L_aircraft)^2 * E_WD
        %                * (0.74 + 0.37*cos(Lambda_LE)) * [1 - 0.3*sqrt(M - M_CD0max)]
        %     M_CD0max = (1/cos(Lambda_LE))^0.2                          [Aero!G8]
        %   Distinct from Raymer Eq. 12.44/12.45's own sweep/Mach fairing used
        %   at L3 (F16AeroL3.compute_CD0_wave) -- same (9*pi/2)=(4.5*pi)
        %   Sears-Haack coefficient, different empirical correction terms; this
        %   is Brandt's own formula, not a Raymer-textbook one, so it is kept
        %   here (F-16-specific) rather than folded into the generic AeroL2
        %   toolbox. Amax/L_aircraft read LIVE from the injected L2 geometry
        %   (obj.geom.Amax = fuselage-envelope ellipse, the L2-fidelity form --
        %   see the Amax_ft2 property comment).
        %
        %   Clamped at M_CD0max via max(0, ...): Brandt's own worksheet only
        %   applies this term for M >= M_wave, fairing linearly from Mcrit in
        %   the transition band below that -- reproducing that finer transonic
        %   fairing is out of scope here (AeroL2's transonic band, 0.95-1.05,
        %   is already explicitly "not modeled"); the clamp just keeps the
        %   sqrt real for the narrow sliver between MACH_SUPERSONIC_MIN (1.05)
        %   and M_CD0max (1.0547 for the F-16's 40 deg LE sweep).
            M = state.mach;
            M_CD0max = (1 / cosd(obj.Lambda_LE_deg))^0.2;
            Dq_SH = 4.5*pi * (obj.Amax_ft2 / obj.L_aircraft_ft)^2;
            val = (Dq_SH / obj.S_ref) * obj.E_WD * (0.74 + 0.37*cosd(obj.Lambda_LE_deg)) ...
                * (1 - 0.3*sqrt(max(0, M - M_CD0max)));
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL2.get_CLmax(obj);
        end

        % ---- Auxiliary accessors (used by the comparison reports, etc.) ------ %
        function e = get_e_osw(obj)
        %GET_E_OSW  OFFICIAL Oswald efficiency (Raymer Eq. 12.48/12.49).
            e = AeroL2.get_e_osw(obj);
        end

        function e = get_e_osw_brandt(obj)
        %GET_E_OSW_BRANDT  Brandt Aero!G12 alternate (comparison report ONLY).
            e = AeroL2.oswald_eff_brandt(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_K1(obj, M)
            val = AeroL2.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL2.get_K2(obj, K1_sub, M);
        end

        function val = get_CD0(obj)
        %GET_CD0  Subsonic clean CD0 = Cfe*(S_wet/S_ref)  [Raymer Eq. 12.23].
            val = AeroL2.get_CD0(obj);
        end

        function val = get_CL_alpha(obj, M)
            val = AeroL2.get_CL_alpha(obj, M);
        end

        % ================================================================ %
        % High-lift-device deltas (L2: trailing-edge flaperon AND leading-edge
        % flap, from real geometry -- the LEF closed 2026-08-10; see the
        % properties block). Geometry (taper, S_ref, quarter-chord and
        % leading-edge sweep) is read live via the Dependent getters above;
        % the flap/LEF control-surface estimates are aero inputs. Delta_e_osw
        % stays tabulated -- Raymer has no closed-form flapped-wing Oswald-
        % efficiency formula.
        % ================================================================ %

        % compute_S_flapped_ratio (Roskam Part II Eq. 7.10) MOVED 2026-08-10 to
        % AeroL2.compute_S_flapped_ratio, the toolbox's low-level tier. It was
        % duplicated verbatim here and on F16AeroL3, and ControlSurfaceSizer is
        % now a third caller (it sizes the flaperon/LEF areas from it). Note the
        % argument list lost its leading ~ -- it is a static now, not a method.

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (Sec. 12.6.5). Plain flap
        %   F_flap=0.0144.  S_flapped ratio from live wing taper.
            F_flap = 0.0144;
            S_flapped_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62.  Lambda is the wing
        %   quarter-chord sweep (read live via obj.Lambda_c4_deg).
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21.  config 'TO'/'L'.
            S_flapped_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = AeroL2.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = Delta_CD0_lef(obj, delta_lef_deg)
        %DELTA_CD0_LEF  Raymer 6th ed. Eq. 12.61 FORM, adapted for the F-16 LE
        %   flap (no separately-cited LE analog exists in the text). ADDED
        %   2026-08-10, mirrors F16AeroL3's method of the same name exactly.
        %   RENAMED from Delta_CD0_slat 2026-08-11 -- see the properties block's
        %   reclassification note. Uses c_lef_over_c (cf/c); unaffected by the
        %   2026-08-11 reclassification, which only touched Delta_CLmax_lef.
            S_lef_ratio = AeroL2.compute_S_flapped_ratio(obj.eta_lef_out, obj.eta_lef_in, obj.taper);
            val = obj.F_lef * obj.c_lef_over_c * S_lef_ratio * (delta_lef_deg - 10);
        end

        function val = Delta_CDi_lef(obj, Delta_CL_lef)
        %DELTA_CDI_LEF  Raymer 6th ed. Eq. 12.62 FORM, adapted for the LE
        %   flap. ADDED 2026-08-10, mirrors F16AeroL3's method of the same
        %   name exactly. RENAMED from Delta_CDi_slat 2026-08-11.
            val = obj.k_lef * Delta_CL_lef^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_lef(obj, config)
        %DELTA_CLMAX_LEF  Raymer 6th ed. Table 12.2 + Eq. 12.21 for the LE
        %   flap (full-span; hinge line = wing LE sweep). ADDED 2026-08-10,
        %   mirrors F16AeroL3's method of the same name exactly. RENAMED from
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

        function val = get_Delta_e_osw_TO(obj)
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Flap (Eq. 12.61) + LEF (Eq. 12.61 form, ADDED
        %   2026-08-10) + gear (Roskam Table 3.6, tabulated).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.Delta_CD0_lef(obj.delta_lef_TO_deg) ...
                + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CD0_L(obj)
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.Delta_CD0_lef(obj.delta_lef_L_deg) ...
                + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CLmax_TO(obj)
        %GET_DELTA_CLMAX_TO  Flaperon + LEF (ADDED 2026-08-10; see the
        %   properties block for why L2 previously omitted the LEF).
        %
        %   The LEF was briefly REMOVED from all six high-lift sums on
        %   2026-08-11 as a deliberate experiment (to see whether L2 and L3
        %   would separate once L2's CLmax was genuinely lower-fidelity), then
        %   RESTORED the same day. Recorded because the experiment is in the
        %   session history and its numbers should not be mistaken for
        %   current: with the LEF out, L2 read CLmax_L = 1.1196 and its
        %   landing wall fell to 109.21 psf, which made the wall bind HARDER
        %   (margin -27.46 psf against L2's own envelope minimum, versus
        %   -15.28 with the LEF in). Removing it moved L2 further from
        %   Brandt's bounds-but-does-not-bind structure, not closer.
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

        function val = roskam_Delta_CD0(~, flapconfig)
        %ROSKAM_DELTA_CD0  Mean of AeroL1.Delta_CD0's "Delta_CD0" range (Roskam Table 3.6).
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.Delta_CD0{1});
        end

    end
end

classdef F16AeroL2 < AeroModelL2
%F16AEROL2  F-16A Block 10 Level-2 aerodynamics student class.
%
%   Inherits AeroModelL2 (abstract enforcer).  L2 is the GEOMETRY-DEPENDENT
%   clean drag polar + finite-wing lift; every abstract method delegates to the
%   AeroL2 static toolbox.
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

        Cfe               % equivalent skin-friction coefficient [Raymer Table 12.3, 0.0035 AF fighter]
        e_method          % Oswald-e selector; "official" -> Raymer Eq. 12.48/12.49

        % Airfoil section data (NACA 64A204) -- from JSON airfoil block.
        airfoil_name
        airfoiltype       % "cambered"/"uncambered"; a nonzero alpha_L0 -> K2 != 0
        design_CL         % airfoil design lift coefficient (0.2 for 64A204)
        alpha_L0          % deg; zero-lift AOA (drives CL_minD -> K2)
        cl_max_2D         % 2-D section cl_max (feeds clean CLmax, Eq. 12.15)
        cl_alpha_2D       % 1/rad; 2-D lift slope (optional eta term, Eq. 12.8)

        % --- Trailing-edge flap (flaperon) control-surface estimates. These
        % are genuine aero/control-surface spec (NOT geometry), not in the aero
        % JSON; carried as flagged hardcoded inputs. TODO: verify against T.O.
        % 1F-16A-1 (flaperon is a small-authority camber device, ~20 deg max).
        hld_TE            = "plain"
        c_flap_over_c     = 0.25
        eta_flap_in       = 0.10
        eta_flap_out      = 0.90
        delta_flap_TO_deg = 15
        delta_flap_L_deg  = 20
        k_f_flap          = 0.28    % Raymer 6th ed. Eq. 12.62 (partial-span)
    end

    % ======================================================================= %
    % DERIVED -- geometry read live from obj.geom on every read (no cache,
    % never stale). Read-only (no set-methods). Fixes the historical hardcoded-
    % geometry bugs by construction.
    % ======================================================================= %
    properties (Dependent)
        S_ref             % ft^2  wing reference area          <- geom.S_ref
        S_wet             % ft^2  total wetted area            <- geom.S_wet
        AR                % —     wing aspect ratio            <- geom.AR_wing
        Lambda_LE_deg     % deg   wing leading-edge sweep      <- geom.LE_sweep_wing
        Lambda_c4_deg     % deg   wing quarter-chord sweep     <- geom.QC_sweep_wing (~32.2, fixes the 37 bug)
        taper             % —     wing taper ratio             <- geom.lambda_wing
        L_char            % ft    characteristic length for the aircraft-level
                          %       supersonic Reynolds number   <- geom.L_fus
    end

    methods

        function obj = F16AeroL2(geom, json_path)
        %F16AEROL2  Construct from a required injected geometry object and a
        %   required unified L2 input JSON path (f16a_spec_path(2)); reads its
        %   .aerodynamics block. No silent defaults: both the geometry object
        %   and the path must be supplied. Sets ONLY the aero inputs; all
        %   geometry is produced live by the Dependent getters from obj.geom.
            arguments
                geom      (1,1) GeometryBase
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            obj.geom = geom;

            A = jsondecode(fileread(json_path)).aerodynamics;
            obj.Cfe      = A.Cfe_subsonic_clean;    % [Raymer Table 12.3]
            obj.e_method = string(A.e_method);
            af = A.airfoil;
            obj.airfoil_name = string(af.name);
            obj.airfoiltype  = string(af.airfoiltype);
            obj.design_CL    = af.design_CL;
            obj.alpha_L0     = af.alpha_L0_deg;      % [NACA 64A204]
            obj.cl_max_2D    = af.cl_max_2D;
            % JSON gives the 2-D lift slope per degree; Raymer Eq. 12.8 uses 1/rad.
            obj.cl_alpha_2D  = af.cl_alpha_per_deg * 180/pi;
        end

        % ---- Dependent geometry getters (live from obj.geom) -------------- %
        function v = get.S_ref(obj);         v = obj.geom.S_ref;         end
        function v = get.S_wet(obj);         v = obj.geom.S_wet;         end
        function v = get.AR(obj);            v = obj.geom.AR_wing;       end
        function v = get.Lambda_LE_deg(obj); v = obj.geom.LE_sweep_wing; end
        function v = get.Lambda_c4_deg(obj); v = obj.geom.QC_sweep_wing; end
        function v = get.taper(obj);         v = obj.geom.lambda_wing;   end
        function v = get.L_char(obj);        v = obj.geom.L_fus;         end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, state)
            polar = AeroL2.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL2.get_CLmax(obj);
        end

        % ---- Auxiliary accessors (used by fidelity_comparison, etc.) ------ %
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
        % High-lift-device deltas (L2: trailing-edge flap from real geometry).
        % Geometry (taper, S_ref, quarter-chord sweep) is read live via the
        % Dependent getters above; the flap control-surface estimates are aero
        % inputs. Delta_e_osw stays tabulated -- Raymer has no closed-form
        % flapped-wing Oswald-efficiency formula.
        % ================================================================ %

        function val = compute_S_flapped_ratio(~, eta_out, eta_in, lambda_taper)
        %COMPUTE_S_FLAPPED_RATIO  S_flapped/S_ref for a flap spanning
        %   [eta_in, eta_out] of the semispan.  Roskam Part II Eq. 7.10.
            val = (eta_out - eta_in) * (2 - (1 - lambda_taper) * (eta_in + eta_out)) / (1 + lambda_taper);
        end

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (Sec. 12.6.5). Plain flap
        %   F_flap=0.0144.  S_flapped ratio from live wing taper.
            F_flap = 0.0144;
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62.  Lambda is the wing
        %   quarter-chord sweep (read live via obj.Lambda_c4_deg).
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21.  config 'TO'/'L'.
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = AeroL2.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = get_Delta_e_osw_TO(obj)
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Flap (Eq. 12.61) + gear (Roskam Table 3.6, tabulated).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CD0_L(obj)
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CLmax_TO(obj)
            val = obj.Delta_CLmax_flap('TO');
        end

        function val = get_Delta_CLmax_L(obj)
            val = obj.Delta_CLmax_flap('L');
        end

        function val = get_Delta_CDi_TO(obj)
            val = obj.Delta_CDi_flap(obj.get_Delta_CLmax_TO());
        end

        function val = get_Delta_CDi_L(obj)
            val = obj.Delta_CDi_flap(obj.get_Delta_CLmax_L());
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

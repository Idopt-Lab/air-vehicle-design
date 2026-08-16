classdef F16AeroL2 < AeroModelL2
%F16AEROL2  F-16A Block 10 Level-2 aerodynamics student class.
%
%   Inherits AeroModelL2 (abstract enforcer).  L2 is the geometry-dependent
%   clean drag polar + finite-wing lift; every abstract method delegates to the
%   AeroL2 static toolbox, except drag_polar's supersonic branch (see below).
%
%   SUPERSONIC WAVE DRAG: the generic AeroL2 toolbox's supersonic CD0 is
%   turbulent skin friction only (no wave-drag term), which reads lower than
%   the subsonic CD0 at the F-16's M=1.6 point. This class overrides drag_polar
%   to add Brandt's whole-aircraft wave-drag increment (compute_CD0_wave,
%   Brandt Aero!B8/G8) on top of the subsonic CD0 for M >= MACH_SUPERSONIC_MIN.
%   Kept here (F-16-specific) rather than in the generic toolbox, since it is
%   Brandt's tuned formula (E_WD=2.2), not a generic textbook equation. Simpler
%   than L3's full Raymer Eq. 12.44/12.45 buildup -- whole-aircraft Sears-Haack
%   term only.
%
%   DEPENDENCY INJECTION + INPUT vs DERIVED (optimization-ready design).
%   The constructor takes a required injected geometry object and a required
%   unified L2 input JSON path (f16a_spec_path(2); reads its .aerodynamics
%   block). No silent defaults. Properties split, mirroring F16GeomL2:
%     (1) INPUTS -- plain mutable block of aero spec data only (Cfe-selector,
%         airfoil section, Oswald-e method, control-surface/high-lift
%         estimates), set once by the constructor.
%     (2) DERIVED (Dependent) -- geometry read live from the injected geometry
%         object on every read. No geometry number is stored on this class, so
%         a mutated geometry input reflects on the next aero read.
%
%   Inheritance: AerodynamicsBase -> AeroModelL2 -> F16AeroL2
%
%   Expected outputs (fresh F16GeomL2, subsonic clean):
%     CD0   = Cfe*(S_wet/S_ref) = 0.0035*1466.8/300 ~ 0.0171   [Raymer Eq. 12.23]
%     e     = Raymer Eq. 12.49 (AR=3, Lambda_LE=40) ~ 0.908
%     K1    = 1/(pi*AR*e) ~ 0.117
%     CLmax = 0.9*1.20*cos(32.2 deg) ~ 0.914                    [Raymer Eq. 12.15]

    % INPUTS -- aero-only spec data (mutable; from the unified L2 JSON's
    % .aerodynamics block). No geometry here (see the Dependent block below).
    properties
        geom              % injected geometry object (all geometry read live from it)

        %AIRCRAFT_CATEGORY  Canonical class flag ("jet_fighter"); selects the
        %   Raymer Table 12.3 Cfe row -- see the Dependent Cfe below.
        aircraft_category

        e_method          % Oswald-e selector; "official" -> Raymer Eq. 12.48/12.49

        % Airfoil section data (NACA 64A204) -- from JSON airfoil block.
        airfoil_name
        airfoiltype       % "cambered"/"uncambered"; a nonzero alpha_L0 -> K2 != 0
        design_CL         % airfoil design lift coefficient (0.2 for 64A204)
        alpha_L0          % deg; zero-lift AOA (drives CL_minD -> K2)
        cl_max_2D         % 2-D section cl_max (feeds clean CLmax, Eq. 12.15)
        cl_alpha_2D       % 1/rad; 2-D lift slope (optional eta term, Eq. 12.8)

        % --- Trailing-edge flap (flaperon) control-surface estimates. Aero/
        % control-surface spec (not geometry), not in the aero JSON; hardcoded
        % inputs. TODO: verify against T.O. 1F-16A-1 (flaperon ~20 deg max).
        hld_TE            = "plain"
        c_flap_over_c     = 0.25
        eta_flap_in       = 0.10
        eta_flap_out      = 0.90
        delta_flap_TO_deg = 15
        delta_flap_L_deg  = 20
        k_f_flap          = 0.28    % Raymer 6th ed. Eq. 12.62 (partial-span)

        %E_WD  Wave-drag efficiency factor [Brandt F-16A.xls Aero tab, Aero!B8
        %   formula; VnV/BrandtF16A/BrandtAerodynamics.m's Ewd / readme_aero.md
        %   "Wave drag factor (Sears-Haack reference)"]. A tuned calibration
        %   input; same value/status as F16AeroL3's E_WD.
        E_WD
    end

    % DERIVED -- geometry read live from obj.geom on every read (no cache,
    % never stale). Read-only (no set-methods).
    properties (Dependent)
        %CFE  Equivalent skin-friction coefficient, Raymer Table 12.3, selected
        %   by aircraft_category (0.0035 for an Air Force fighter). The JSON
        %   supplies only the category that selects it, not the value.
        Cfe

        S_ref             % ft^2  wing reference area          <- geom.S_ref
        S_wet             % ft^2  total wetted area            <- geom.S_wet
        AR                % —     wing aspect ratio            <- geom.AR_wing
        Lambda_LE_deg     % deg   wing leading-edge sweep      <- geom.LE_sweep_wing
        Lambda_c4_deg     % deg   wing quarter-chord sweep     <- geom.QC_sweep_wing (~32.2)
        taper             % —     wing taper ratio             <- geom.lambda_wing
        L_char            % ft    characteristic length for the aircraft-level
                          %       supersonic Reynolds number   <- geom.L_fus

        %AMAX_FT2, L_AIRCRAFT_FT  Whole-aircraft wave-drag geometry, read live
        %   from the injected geometry object. Tier-specific: obj.geom.Amax is
        %   the fuselage-envelope ellipse (pi/4)*W*H at L2 (the correct
        %   L2-fidelity form), not L3's area-ruled buildup. Do not unify the two.
        Amax_ft2          % ft^2  <- geom.Amax (fuselage-envelope ellipse at L2)
        L_aircraft_ft     % ft    <- geom.L_aircraft
    end

    methods

        function obj = F16AeroL2(geom, json_path)
        %F16AEROL2  Construct from a required injected geometry object and a
        %   required unified L2 input JSON path (f16a_spec_path(2)); reads its
        %   .aerodynamics block. No silent defaults: both the geometry object
        %   and the path must be supplied. Sets ONLY the aero inputs; all
        %   geometry is produced live by the Dependent getters from obj.geom.
            arguments
                % GeometryBase is too weak a guard (only S_ref/S_wet), so an
                % F16GeomL1 or other subclass would construct fine then produce
                % wrong drag. Narrowed to the tiers that satisfy the aero
                % contract; both L2 and L3 geometry do.
                geom      (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            obj.geom = geom;

            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            % ONE canonical top-level category key -- selects rows in several
            % discipline tables, so not aerodynamics' property to own.
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
        function v = get.Amax_ft2(obj);      v = obj.geom.Amax;          end
        function v = get.L_aircraft_ft(obj); v = obj.geom.L_aircraft;    end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Subsonic/transonic: delegates to the generic AeroL2
        %   toolbox. Supersonic: F-16-specific override -- the generic
        %   AeroL2.get_CD0_supersonic is turbulent skin friction only, which
        %   reads below the subsonic CD0 at the F-16's Max Mach point (M=1.6).
        %   This class adds Brandt's whole-aircraft wave-drag increment
        %   (compute_CD0_wave) on top of the subsonic CD0, matching Brandt's
        %   "CD0 = CD0_subsonic + CD_wave" split. K1/K2 untouched.
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
        %   Distinct from Raymer Eq. 12.44/12.45's fairing used at L3 -- same
        %   (9*pi/2)=(4.5*pi) Sears-Haack coefficient, different empirical
        %   correction terms; Brandt's own formula, kept here (F-16-specific).
        %   Amax/L_aircraft read live from the L2 geometry (fuselage-envelope
        %   ellipse, the L2-fidelity form).
        %
        %   Clamped at M_CD0max via max(0, ...) to keep the sqrt real for the
        %   narrow sliver between MACH_SUPERSONIC_MIN (1.05) and M_CD0max
        %   (1.0547 for the F-16's 40 deg LE sweep).
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

        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Per-high-lift-config polar, built on the F-16 L2 clean
        %   drag polar plus this class's config-distinguishing methods
        %   (get_CLmax_TO/_L, get_Delta_CD0_TO/_L) -- the AerodynamicsBase
        %   contract the FAR-25 field-length/climb constraints read. The six
        %   configs are low-speed high-lift states, so the clean polar is taken
        %   at a nominal takeoff/landing condition (sea level, M = 0.2). Both
        %   takeoff_* configs map to the takeoff deltas, both landing_* plus
        %   approach to the landing deltas.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            ref   = AircraftState(0, 0.2);   % nominal low-speed takeoff/landing condition
            clean = obj.drag_polar(ref);
            switch config
                case "clean"
                    CD0 = clean.CD0;                          CLmax = obj.get_CLmax(ref);
                case {"takeoff_flaps_gear_up", "takeoff_flaps_gear_down"}
                    CD0 = clean.CD0 + obj.get_Delta_CD0_TO(); CLmax = obj.get_CLmax_TO();
                otherwise   % landing_flaps_gear_up/down, approach
                    CD0 = clean.CD0 + obj.get_Delta_CD0_L();  CLmax = obj.get_CLmax_L();
            end
            cfg = struct('CD0', CD0, 'K1', clean.K1, 'K2', clean.K2, 'CLmax', CLmax);
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

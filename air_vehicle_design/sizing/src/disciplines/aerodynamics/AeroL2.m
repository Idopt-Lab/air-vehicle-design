classdef AeroL2
%AEROL2  Level-2 aerodynamics static toolbox: geometry-dependent clean polar.
%
%   Call as AeroL2.method(...); never instantiated, not in the inheritance
%   chain. F16AeroL2 inherits AeroModelL2 and delegates to these statics.
%
%   All geometry is read from the injected geometry object through the concrete
%   class's Dependent getters; this toolbox never sees a hardcoded geometry
%   number. The skin-friction primitives (dyn_viscosity, compute_Re,
%   Cf_turbulent) live here as the single source of truth and are also called
%   by the L3 component buildup.
%
%   Sources: [Raymer 6th ed. Eq. 12.23] parasite drag; [Table 12.3] Cfe;
%   [Eq. 12.48/12.49] Oswald e; [Eq. 12.50/12.51] K1; [Eq. 12.6] lift slope;
%   [Eq. 12.15] clean CLmax; [Eq. 12.25/12.27] Reynolds number and Cf;
%   [Sec. 12.3.1] viscosity. K2 subsonic follows [Brandt Sec. 4.3, Aero!G17].
%
%   TRANSONIC BAND (MACH_SUBSONIC_MAX < M < MACH_SUPERSONIC_MIN) is not
%   modelled: Eq. 12.51 has a pole at 4*AR*beta = 2 (M ~ 1.014 at AR = 3), so
%   that band returns NaN as an explicit "not modelled" signal rather than a
%   singular value.
%
%   Companion doc: src/disciplines/aerodynamics/AeroL2.md

    properties (Constant)
        % Transonic-band boundaries (see class header). Subsonic below
        % MACH_SUBSONIC_MAX; supersonic at/above MACH_SUPERSONIC_MIN; the band
        % in between is "not modeled". MACH_SUPERSONIC_MIN=1.05 sits clear of
        % the Eq. 12.51 pole at M~1.014 (AR=3).
        MACH_SUBSONIC_MAX  = 0.95
        MACH_SUPERSONIC_MIN = 1.05
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): Again, another artefact of the subclass-to-enforcer era. Relocate to 
        % F-16 example if it hasn't already been.
        function polar = drag_polar(obj, state)
        %DRAG_POLAR  L2 clean drag polar {CD0, K1, K2} at the flight state.
        %   Subsonic: Cfe-based CD0, Oswald K1, camber K2. Supersonic:
        %   turbulent-Cf CD0, linearized K1 (Eq. 12.51), K2=0. Transonic band
        %   returns NaN (not modeled -- avoids the Eq. 12.51 pole).
            M      = state.mach;
            regime = AeroL2.flight_regime(M);
            switch regime
                case "transonic"
                    warning('AeroL2:transonicNotModeled', ...
                        ['L2 drag polar is not modeled in the transonic band ' ...
                         '(%.2f < M=%.4f < %.2f): the Raymer Eq. 12.51 supersonic ' ...
                         'K1 is singular near M=1. Returning NaN.'], ...
                        AeroL2.MACH_SUBSONIC_MAX, M, AeroL2.MACH_SUPERSONIC_MIN);
                    polar = struct('CD0', NaN, 'K1', NaN, 'K2', NaN);
                case "subsonic"
                    cd0 = AeroL2.get_CD0(obj);
                    e   = AeroL2.get_e_osw(obj);
                    k1  = AeroL2.K1_subsonic(e, obj.AR);
                    k2  = AeroL2.get_K2(obj, k1, M);
                    polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
                otherwise   % "supersonic"
                    cd0 = AeroL2.get_CD0_supersonic(obj, state);
                    k1  = AeroL2.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
                    k2  = 0;   % K2=0 for M>=1 (linearized supersonic theory) [Brandt Sec. 4.3]
                    polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
            end
        end

        % TODO (8/14/2026): Same as with the previous function; an artefact of being a subclass, which it
        % no longer is. Relocate to F-16 example if it hasn't been already.
        function CLmax = get_CLmax(obj)
        %GET_CLMAX  Geometry-based clean CLmax.  Raymer 6th ed. Eq. 12.15.
        %   Reads obj.cl_max_2D (airfoil) and obj.Lambda_c4_deg (injected
        %   quarter-chord sweep). See CLmax_clean for the F-16 vortex-lift
        %   limitation.
            CLmax = AeroL2.CLmax_clean(obj.cl_max_2D, obj.Lambda_c4_deg);
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function e = get_e_osw(obj)
        %GET_E_OSW  OFFICIAL Oswald efficiency (Raymer Eq. 12.48/12.49).
        %   Selected by obj.e_method ("official"). Brandt's own e0 (Aero!G12)
        %   is available as the SEPARATE static oswald_eff_brandt for the
        %   comparison report ONLY -- it is never what drag_polar returns.
            switch string(obj.e_method)
                case "official"
                    e = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);
                otherwise
                    error('AeroL2:unknownEMethod', ...
                        ['e_method="%s" is not recognized. The official K1 must ' ...
                         'use Raymer Eq. 12.48/12.49 (e_method="official"); ' ...
                         'Brandt e0 is a comparison-only alternate ' ...
                         '(AeroL2.oswald_eff_brandt), never the drag_polar value.'], ...
                        obj.e_method);
            end
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = get_CD0(obj)
        %GET_CD0  Subsonic clean CD0 = Cfe*(S_wet/S_ref).  Raymer Eq. 12.23.
        %   Cfe (obj.Cfe) is the genuine Raymer Table 12.3 spec value
        %   (0.0035, AF fighter); S_wet/S_ref are read live from the injected
        %   geometry object.
            val = AeroL2.CD0_from_Cf(obj.Cfe, obj.S_wet, obj.S_ref);
        end

        function val = get_CD0_supersonic(obj, state)
            Re  = AeroL2.compute_Re(state, obj.L_char);
            Cf  = AeroL2.Cf_turbulent(Re, state.mach);
            val = AeroL2.CD0_from_Cf(Cf, obj.S_wet, obj.S_ref);
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = get_K1(obj, M)
        %GET_K1  Induced-drag factor at Mach M (subsonic or supersonic branch).
        %   Transonic band errors (use drag_polar for the NaN signal).
            regime = AeroL2.flight_regime(M);
            switch regime
                case "subsonic"
                    val = AeroL2.K1_subsonic(AeroL2.get_e_osw(obj), obj.AR);
                case "supersonic"
                    val = AeroL2.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
                otherwise
                    error('AeroL2:transonicNotModeled', ...
                        'K1 not modeled in the transonic band (M=%.4f).', M);
            end
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term (Convention A).
        %   Subsonic: CL_minD = CL_alpha(M)*(-deg2rad(alpha_L0)/2) (see
        %   compute_CL_minD -- not Brandt's own method), then
        %   K2 = -2*K1_sub*CL_minD [Brandt Aero!G17]. Nonzero for the
        %   F-16's cambered NACA 64A204 (design_CL=0.2). M>=1: K2=0.
            CL_alpha_M = AeroL2.get_CL_alpha(obj, M);
            CL_minD    = AeroL2.compute_CL_minD(CL_alpha_M, obj.alpha_L0);
            val        = AeroL2.K2_value(K1_sub, CL_minD, M);
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = get_CL_alpha(obj, M)
            if ~isprop(obj, 'cl_alpha_2D') || isempty(obj.cl_alpha_2D)
                error('AeroL2:missingClAlpha2D', ...
                    ['%s must define a non-empty cl_alpha_2D [1/rad] to use ', ...
                     'get_CL_alpha (Raymer Eq. 12.8 eta term). Read it from the ', ...
                     'input JSON''s .aerodynamics.airfoil.cl_alpha_per_deg ', ...
                     '(x 180/pi), or call AeroL2.CL_alpha directly with an empty ', ...
                     'slope to opt into the eta = 0.95 default deliberately.'], ...
                    class(obj));
            end
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M, [], [], [], obj.cl_alpha_2D);
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
        %COMPUTE_DELTA_CL_MAX_VALUES  Wing CLmax increment from a deployed HLD.
        %   0.9 * Delta_cl_max * (S_flapped/S_ref) * cos(Lambda_HL)
        %   Raymer 6th ed. Eq. 12.21.
            val = 0.9 * Delta_cl_max * (S_flapped / S_ref) * cosd(Lambda_HL_deg);
        end

        function val = compute_S_flapped_ratio(eta_out, eta_in, lambda_taper)
        %COMPUTE_S_FLAPPED_RATIO  S_flapped/S_ref for a spanwise device covering
        %   [eta_in, eta_out] of the semispan on a tapered wing.
        %   [Roskam, "Airplane Design Part II," Eq. 7.10]:
        %     S_flapped/S_ref = (eta_out - eta_in)
        %                       * (2 - (1-lambda)*(eta_in + eta_out)) / (1 + lambda)
        %
        %   PROMOTED HERE 2026-08-10. It used to be an identical instance method
        %   on BOTH F16AeroL2 and F16AeroL3 (a verbatim duplicate). It is a pure
        %   function of three scalars with no object access, so it belongs in this
        %   toolbox's low-level tier -- and it now has a THIRD caller outside
        %   aerodynamics: ControlSurfaceSizer sizes the flaperon and leading-edge
        %   flap areas from it. That cross-discipline static call follows the
        %   established pattern in this framework (SandCL3.CL_alpha_h delegates to
        %   AeroL2.CL_alpha; TailL2 delegates to TailL1.compute_tail_arm).
        %
        %   NOTE ON WHAT THIS RETURNS: the ratio is the fraction of the WING
        %   REFERENCE AREA lying in the device's span band -- NOT the device's own
        %   planform area. Multiply by the device's chord fraction to get that
        %   (see ControlSurfaceSizer.size).
        %
        %   eta_in, eta_out -- inboard/outboard span stations, fraction of semispan
        %   lambda_taper    -- wing taper ratio (tip chord / root chord)
            arguments
                eta_out      (1,1) double {mustBeInRange(eta_out, 0, 1)}
                eta_in       (1,1) double {mustBeInRange(eta_in, 0, 1)}
                lambda_taper (1,1) double {mustBePositive}
            end
            if eta_out < eta_in
                error('AeroL2:invalidSpanStations', ...
                    ['Outboard span station eta_out = %g is inboard of eta_in = %g. ' ...
                     'The argument order is (eta_out, eta_in), outboard FIRST.'], ...
                    eta_out, eta_in);
            end
            val = (eta_out - eta_in) * (2 - (1 - lambda_taper) * (eta_in + eta_out)) ...
                  / (1 + lambda_taper);
        end

        % TODO (8/14/2026): Tagged "artefact of subclass era. Relocate to F-16 example if it hasn't been already."
        function val = lookup_Delta_cl_max_values(liftdevice, config, cp_c)
        %LOOKUP_DELTA_CL_MAX_VALUES  [Raymer 6th ed. Table 12.2.]
        %
        %   cp_c IS THE EXTENDED-CHORD RATIO, NOT A CHORD FRACTION (bug found
        %   2026-08-11, VnV/BrandtF16A/todo.md): Raymer's caption defines
        %   cp_c = c'/c as the ratio of the chord WITH the device deployed to
        %   the chord WITHOUT it -- c' is the extended chord length (user
        %   confirmation, 2026-08-11), c is the retracted chord. For a device
        %   that mostly rotates rather than translates (a slat), cp_c is close
        %   to 1.0, NOT the device's own chord as a fraction of the wing chord
        %   (that quantity is cf/c -- a different, correctly-named parameter
        %   used by Eq. 12.61/12.62's F_flap/k_f drag terms, e.g. F16AeroL2's
        %   c_flap_over_c/c_slat_over_c). Cross-checked against DATCOM 1978
        %   Sec. 6.1.1.3's equivalent formula (reproduced with the identical
        %   "ratio of the chord with and without deflection" definition in
        %   Scholz, "Aircraft Design" course notes, Ch.8 Eq.(8.5)/p.8-13,
        %   HAW Hamburg) -- both sources use c'/c for the same physical
        %   quantity. Only 'fowler'/'double slotted'/'triple slotted'/'slat'
        %   multiply by cp_c (devices that meaningfully extend chord); the
        %   'leading-edge flap'/'kruger flap' row does NOT (flat base=0.3),
        %   because that device rotates on a hinge rather than translating --
        %   cp_c is ignored for that branch and callers may pass NaN.
        %   F16AeroL2/L3's Delta_CLmax_lef briefly (2026-08-11) passed a chord
        %   FRACTION here under the WRONG row ('slat', via the LEF's own
        %   cf/c = 0.15), understating Delta_cl_max ~6.7x, before being
        %   RECLASSIFIED to 'leading-edge flap' the same day once Brandt's own
        %   geometry chart showed the device to be a hinged, non-translating
        %   panel (VnV/BrandtF16A/todo.md 2026-08-11) -- so no cp_c value was
        %   ultimately needed for the F-16's LEF at all.
            switch liftdevice
                case {'plain','split'},          base = 0.9;
                case 'slotted',                  base = 1.3;
                case 'fowler',                   base = 1.3 * cp_c;
                case 'double slotted',           base = 1.6 * cp_c;
                case 'triple slotted',           base = 1.9 * cp_c;
                case 'fixed slot',               base = 0.2;
                case {'leading-edge flap','kruger flap'}, base = 0.3;
                case 'slat',                     base = 0.4 * cp_c;
                otherwise
                    error('AeroL2:unknownDevice', ...
                        'Unrecognized lift device "%s".', liftdevice);
            end
            if ismember(config, {'takeoff','TO'})
                val = base * 0.6;
            elseif ismember(config, {'landing','L'})
                val = base * 0.8;
            else
                warning('AeroL2:unrecognizedConfig', ...
                    ['Unrecognized high-lift config "%s" -- expected one of ' ...
                     '''takeoff''/''TO'' or ''landing''/''L''. Using the full, ' ...
                     'undiminished value with no takeoff/landing reduction.'], ...
                    string(config));
                val = base;
            end
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- scalars/arrays only, no object access.
        % Shared with L3 (single source of truth for the induced/skin-friction
        % primitives).
        % ================================================================== %

        function regime = flight_regime(M)
        %FLIGHT_REGIME  Classify Mach into "subsonic"/"transonic"/"supersonic"
        %   per the AeroL2 transonic-band constants. The transonic band is not
        %   modeled (avoids the Raymer Eq. 12.51 K1 pole near M=1).
            arguments
                M (1,1) double {mustBeReal, mustBeNonnegative}
            end
            if M < AeroL2.MACH_SUBSONIC_MAX
                regime = "subsonic";
            elseif M >= AeroL2.MACH_SUPERSONIC_MIN
                regime = "supersonic";
            else
                regime = "transonic";
            end
        end

        function e = oswald_eff(AR, Lambda_LE_deg)
        %OSWALD_EFF  OFFICIAL Oswald span efficiency.
        %   Raymer 6th ed. Eq. 12.48 (Lambda_LE < 30 deg) / Eq. 12.49 (>= 30 deg).
            arguments
                AR            (1,1) double {mustBePositive}
                Lambda_LE_deg (1,1) double {mustBeReal}
            end
            if Lambda_LE_deg < 30
                e = 1.78 * (1 - 0.045 * AR^0.68) - 0.64;
            else
                e = 4.61 * (1 - 0.045 * AR^0.68) * cosd(Lambda_LE_deg)^0.15 - 3.1;
            end
        end

        % TODO (8/14/2026): I want the toolboxes to remain as independent from Brandt as possible; remove this from this toolbox.
        function e = oswald_eff_brandt(AR, Lambda_LE_deg)
            arguments
                AR            (1,1) double {mustBePositive}
                Lambda_LE_deg (1,1) double {mustBeReal}
            end
            e = max(0.4, 4.6 * (1 - 0.033 * AR^0.53) * cosd(Lambda_LE_deg)^0.1 - 3.3);
        end

        function K1 = K1_subsonic(e_osw, AR)
        %K1_SUBSONIC  K1 = 1/(pi*AR*e)  [Raymer 6th ed. Eq. 12.50].
            arguments
                e_osw (1,1) double {mustBePositive}
                AR    (1,1) double {mustBePositive}
            end
            K1 = 1 / (pi * AR * e_osw);
        end

        function K1 = K1_supersonic(M, AR, Lambda_LE_deg)
            arguments
                M             (1,1) double {mustBeReal}
                AR            (1,1) double {mustBePositive}
                Lambda_LE_deg (1,1) double {mustBeReal}
            end
            if M <= 1
                error('AeroL2:subsonicMach', ...
                    'K1_supersonic called with M=%.3f; use K1_subsonic for M<1.', M);
            end
            beta = sqrt(M^2 - 1);
            K1   = AR * (M^2 - 1) * cosd(Lambda_LE_deg) / (4 * AR * beta - 2);
        end

        function K2 = K2_value(K1_sub, CL_minD, M)
        %K2_VALUE  Polar-offset term (Convention A).
        %   K2 = -2*K1_sub*CL_minD  (M<1)   [Brandt Aero!G17 -- this
        %   structure is genuinely Brandt's; see compute_CL_minD for the
        %   CL_minD input, which is NOT Brandt's own method]
        %   K2 = 0                  (M>=1)  (linearized supersonic theory)
            if M >= 1
                K2 = 0;
            else
                K2 = -2 * K1_sub * CL_minD;
            end
        end

        function Cfe = lookup_Cfe(aircraft_category)
            arguments
                aircraft_category (1,1) string
            end
            switch aircraft_category
                case {"jet_fighter", "fighter"}, Cfe = 0.0035;  % Air Force fighter
                case "navy_fighter",             Cfe = 0.0040;
                case "bomber",                   Cfe = 0.0030;
                case "civil_transport",          Cfe = 0.0026;
                case "military_cargo",           Cfe = 0.0035;  % high-upsweep fuselage
                case "supersonic_cruise",        Cfe = 0.0025;  % clean supersonic cruise
                case "light_aircraft_single",    Cfe = 0.0055;
                case "light_aircraft_twin",      Cfe = 0.0045;
                case "prop_seaplane",            Cfe = 0.0065;
                case "jet_seaplane",             Cfe = 0.0040;
                otherwise
                    error('AeroL2:unknownAircraftCategory', ...
                        ['Unknown aircraft_category "%s" for the Raymer Table 12.3 ', ...
                         'Cfe lookup. Add the row with its cited table value rather ', ...
                         'than passing a number in through the input JSON.'], ...
                        aircraft_category);
            end
        end

        function CD0 = CD0_from_Cf(Cf, S_wet, S_ref)
        %CD0_FROM_CF  Equivalent-skin-friction CD0 = Cf*(S_wet/S_ref).
        %   Raymer 6th ed. Eq. 12.23 / Table 12.3.  S_ref guarded positive.
            arguments
                Cf    (1,1) double {mustBeNonnegative}
                S_wet (1,1) double {mustBeNonnegative}
                S_ref (1,1) double {mustBePositive}
            end
            CD0 = Cf * S_wet / S_ref;
        end

        function CL_minD = compute_CL_minD(CL_alpha, alpha_L0_deg)
        %COMPUTE_CL_MIND  CL at minimum drag.
        %   CL_minD = CL_alpha * (-deg2rad(alpha_L0)/2). Standard thin-
        %   airfoil zero-lift relation, NOT Brandt's own method (Brandt
        %   derives an equivalent quantity from the airfoil's NACA 4-digit
        %   designation at Aero!G20; per Casey, that method is unclear and
        %   not being reproduced here -- this equation is kept deliberately
        %   as the framework's own choice, corrected 2026-07-30 from a
        %   previous, inaccurate "[Brandt Sec. 4.3]" citation that implied
        %   this exact form was Brandt's; see audit finding A-2).
        %   Uncambered airfoil (alpha_L0 = 0) -> CL_minD = 0 -> K2 = 0.
            CL_minD = CL_alpha * (-deg2rad(alpha_L0_deg) / 2);
        end

        function CL_a = CL_alpha(AR, Lambda_c4_deg, M, S_exposed, S_ref, F, Cl_alpha_2D)
            if nargin < 6 || isempty(S_exposed) || isempty(S_ref) || isempty(F)
                exposed_factor = 1;
            else
                exposed_factor = (S_exposed / S_ref) * F;
            end
            M    = min(M, 0.99);
            beta = sqrt(1 - M^2);   % Raymer Eq. 12.7
            if nargin < 7 || isempty(Cl_alpha_2D)
                eta = 0.95;   % Raymer Eq. 12.8 default when 2-D Cl_alpha unknown
            else
                eta = Cl_alpha_2D / (2*pi/beta);   % Raymer Eq. 12.8
            end
            Lambda_c4_rad = Lambda_c4_deg * pi / 180;
            CL_a = 2 * pi * AR / ...
                   (2 + sqrt(4 + (AR * beta / eta)^2 * (1 + tan(Lambda_c4_rad)^2 / beta^2))) ...
                   * exposed_factor;
        end

        function CLmax = CLmax_clean(cl_max_2D, Lambda_c4_deg)
            CLmax = 0.9 * cl_max_2D * cosd(Lambda_c4_deg);
        end

        % TODO (8/14/2026): I feel like this should go in some sort of utility class, but hold off on that, for now.
        function mu = dyn_viscosity(T_atm_R)
        %DYN_VISCOSITY  Sutherland's law, English units (Raymer 6th ed. Sec. 12.3.1).
        %   Returns mu in slug/(ft*s).  mu_ref=3.737e-7 at T_ref=518.67 R,
        %   Sutherland constant C=198.6 R.  Shared with the L3 component buildup.
            mu_ref = 3.737e-7;
            T_ref  = 518.67;
            C_suth = 198.6;
            mu     = mu_ref * (T_atm_R/T_ref)^1.5 * (T_ref+C_suth)/(T_atm_R+C_suth);
        end

        % TODO (8/14/2026): Where is this used?
        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer 6th ed. Eq. 12.25).
        %   Shared with the L3 component buildup.
            mu = AeroL2.dyn_viscosity(state.T_atm);
            Re = state.rho * state.V * l_ref / mu;
        end

        % TODO (8/14/2026): It appears that some of the component-level drag buildup has bled into L2.
        function Cf = Cf_turbulent(Re, M)
        %CF_TURBULENT  Compressible turbulent flat-plate Cf.
        %   Cf = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Raymer 6th ed. Eq. 12.27.
        %   Shared with the L3 component buildup and the L2 supersonic CD0.
            Cf = 0.455 / (log10(Re)^2.58 * (1 + 0.144*M^2)^0.65);
        end

    end
end

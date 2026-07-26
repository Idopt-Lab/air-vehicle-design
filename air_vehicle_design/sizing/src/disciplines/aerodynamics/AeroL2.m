classdef AeroL2
%AEROL2  Level-2 aerodynamics static toolbox -- geometry-DEPENDENT clean polar.
%
%   Call as AeroL2.method_name(args) -- no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL2, etc.) inherit
%   from AeroModelL2 and call these statics.  All geometry (S_ref, S_wet, AR,
%   sweep, taper, t/c, characteristic length) is read from the injected
%   geometry object via the student object's Dependent getters -- this toolbox
%   never sees a hardcoded geometry number.
%
%   This toolbox is the home of the geometry-dependent skin-friction / induced
%   machinery that used to live in AeroL1 (migrated here 2026-07-23), PLUS the
%   finite-wing lift-slope / clean-CLmax content that was already at L2. The
%   pure-math skin-friction primitives (dyn_viscosity, compute_Re,
%   Cf_turbulent) live here as the single source of truth; the L3 component
%   buildup calls them.
%
%   EQUATIONS:
%     CD0 (subsonic clean) = Cfe*(S_wet/S_ref)          Raymer 6th ed. Eq. 12.23 / Table 12.3
%     CD0 (supersonic)     = Cf(Re,M)*(S_wet/S_ref)     Raymer 6th ed. Eq. 12.27 (Cf), Eq. 12.23 (form)
%     e (Lambda_LE<30 deg) = 1.78*(1-0.045*AR^0.68)-0.64            Eq. 12.48
%     e (Lambda_LE>=30 deg)= 4.61*(1-0.045*AR^0.68)*cos(L)^0.15-3.1 Eq. 12.49
%     K1 subsonic          = 1/(pi*AR*e)                Eq. 12.50
%     K1 supersonic        = AR*(M^2-1)*cos(L_LE)/(4*AR*beta-2)     Eq. 12.51, beta=sqrt(M^2-1)
%     K2 subsonic          = -2*K1_sub*CL_minD          Brandt Sec. 4.3 / Aero!G17
%     K2 supersonic        = 0                          (linearized theory)
%     CL_alpha             = finite-wing Datcom slope   Eq. 12.6 (beta Eq. 12.7, eta Eq. 12.8)
%     CLmax (clean)        = 0.9*cl_max_2D*cos(L_c/4)   Eq. 12.15
%     Cf turbulent         = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Eq. 12.27
%     Re                   = rho*V*l/mu                 Eq. 12.25
%     mu                   = Sutherland's law (English) Sec. 12.3.1
%
%   TRANSONIC BAND (MACH_SUBSONIC_MAX < M < MACH_SUPERSONIC_MIN) is NOT
%   modeled: the Raymer Eq. 12.51 supersonic K1 has a pole at 4*AR*beta=2
%   (M~1.014 for AR=3), so the transonic band returns a clear NaN "not modeled"
%   signal rather than a singular value. Subsonic uses M < 0.95; supersonic
%   uses M >= 1.05 (clear of the pole; Brandt's tabulated M=1.0547 lands in the
%   supersonic branch).

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

        function CLmax = get_CLmax(obj)
        %GET_CLMAX  Geometry-based clean CLmax.  Raymer 6th ed. Eq. 12.15.
        %   Reads obj.cl_max_2D (airfoil) and obj.Lambda_c4_deg (injected
        %   quarter-chord sweep). See CLmax_clean for the F-16 vortex-lift
        %   limitation.
            CLmax = AeroL2.CLmax_clean(obj.cl_max_2D, obj.Lambda_c4_deg);
        end

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

        function val = get_CD0(obj)
        %GET_CD0  Subsonic clean CD0 = Cfe*(S_wet/S_ref).  Raymer Eq. 12.23.
        %   Cfe (obj.Cfe) is the genuine Raymer Table 12.3 spec value
        %   (0.0035, AF fighter); S_wet/S_ref are read live from the injected
        %   geometry object.
            val = AeroL2.CD0_from_Cf(obj.Cfe, obj.S_wet, obj.S_ref);
        end

        function val = get_CD0_supersonic(obj, state)
        %GET_CD0_SUPERSONIC  Supersonic CD0 = Cf(Re,M)*(S_wet/S_ref).
        %   Cf via the compressible turbulent flat-plate formula (Raymer Eq.
        %   12.27); the aircraft-level Reynolds number uses a characteristic
        %   length obj.L_char (injected fuselage length). Raymer does not pin
        %   the reference length for this whole-aircraft equivalent-Cf; the
        %   fuselage length (the longest streamwise wetted dimension) is a
        %   documented modeling choice -- see obj.L_char and F16AeroL2.md.
            Re  = AeroL2.compute_Re(state, obj.L_char);
            Cf  = AeroL2.Cf_turbulent(Re, state.mach);
            val = AeroL2.CD0_from_Cf(Cf, obj.S_wet, obj.S_ref);
        end

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

        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term (Convention A).
        %   Subsonic: CL_minD = CL_alpha(M)*(-deg2rad(alpha_L0)/2)
        %   [Brandt Sec. 4.3], then K2 = -2*K1_sub*CL_minD. Nonzero for the
        %   F-16's cambered NACA 64A204 (design_CL=0.2). M>=1: K2=0.
            CL_alpha_M = AeroL2.get_CL_alpha(obj, M);
            CL_minD    = AeroL2.compute_CL_minD(CL_alpha_M, obj.alpha_L0);
            val        = AeroL2.K2_value(K1_sub, CL_minD, M);
        end

        function val = get_CL_alpha(obj, M)
        %GET_CL_ALPHA  Finite-wing lift-curve slope (Raymer Eq. 12.6); reads
        %   geometry (AR, quarter-chord sweep) from the injected object and
        %   passes the 2-D airfoil lift slope obj.cl_alpha_2D [1/rad] through to
        %   the eta term (Eq. 12.8).
        %
        %   cl_alpha_2D is REQUIRED of every caller. It used to be optional
        %   (absent -> eta = 0.95 via an isprop() guard), which silently masked
        %   F16AeroL3 never supplying it -- so the higher-fidelity level ran on
        %   the less-informed default (fixed 2026-07-25). AeroL2.CL_alpha still
        %   accepts an empty slope and falls back to 0.95, for a caller that
        %   genuinely has no airfoil data; that fallback must now be an explicit
        %   choice at the call site, not an accident of a missing property.
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

        function val = compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
        %COMPUTE_DELTA_CL_MAX_VALUES  Wing CLmax increment from a deployed HLD.
        %   0.9 * Delta_cl_max * (S_flapped/S_ref) * cos(Lambda_HL)
        %   Raymer 6th ed. Eq. 12.21.
            val = 0.9 * Delta_cl_max * (S_flapped / S_ref) * cosd(Lambda_HL_deg);
        end

        function val = lookup_Delta_cl_max_values(liftdevice, config, cp_c)
        %LOOKUP_DELTA_CL_MAX_VALUES  Section cl_max increment for a HLD type.
        %   liftdevice -- "plain","split","slotted","fowler","double slotted",
        %                 "triple slotted","fixed slot","leading-edge flap",
        %                 "kruger flap","slat"
        %   config     -- "takeoff"/"TO" or "landing"/"L"
        %   cp_c       -- c'/c for chord-changing devices
        %   Raymer 6th ed. Sec. 12.5 (Table 12.2 / Fig. 12.18).
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

        function e = oswald_eff_brandt(AR, Lambda_LE_deg)
        %OSWALD_EFF_BRANDT  ALTERNATE (comparison-only) Oswald efficiency.
        %   Brandt F-16A workbook, Aero!G12:
        %     e0 = max(0.4, 4.6*(1-0.033*AR^0.53)*cos(Lambda_LE)^0.1 - 3.3)
        %   Distinct constants/exponents from Raymer Eq. 12.49; for the F-16
        %   (AR=3, Lambda_LE=40) gives e0~0.914. This is a SEPARATELY-cited
        %   alternate for the Brandt comparison report ONLY -- it must never be
        %   the value drag_polar/get_e_osw returns (AeroL2.md: keep both,
        %   distinctly cited).
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
        %K1_SUPERSONIC  Linearized supersonic K1  [Raymer 6th ed. Eq. 12.51].
        %   K1 = AR*(M^2-1)*cos(Lambda_LE)/(4*AR*beta - 2),  beta = sqrt(M^2-1).
        %   Has a pole at 4*AR*beta = 2 (M~1.014 for AR=3); only evaluated at
        %   M >= MACH_SUPERSONIC_MIN=1.05 (clear of the pole) via flight_regime.
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
        %   K2 = -2*K1_sub*CL_minD  (M<1)   [Brandt Sec. 4.3 / Aero!G17]
        %   K2 = 0                  (M>=1)  (linearized supersonic theory)
            if M >= 1
                K2 = 0;
            else
                K2 = -2 * K1_sub * CL_minD;
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
        %   CL_minD = CL_alpha * (-deg2rad(alpha_L0)/2)  [Brandt Sec. 4.3].
        %   Uncambered airfoil (alpha_L0 = 0) -> CL_minD = 0 -> K2 = 0.
            CL_minD = CL_alpha * (-deg2rad(alpha_L0_deg) / 2);
        end

        function CL_a = CL_alpha(AR, Lambda_c4_deg, M, S_exposed, S_ref, F, Cl_alpha_2D)
        %CL_ALPHA  Finite-wing CL_alpha (per rad) via Raymer 6th ed. Eq. 12.6.
        %   AR            -- aspect ratio
        %   Lambda_c4_deg -- quarter-chord sweep (deg); used as approx. for the
        %                    max-thickness-line sweep in Eq. 12.6 (documented
        %                    approximation).
        %   M             -- Mach (subsonic; clamped to 0.99 internally)
        %   S_exposed,S_ref,F -- optional; (S_exposed/S_ref)*F fuselage-lift
        %                    factor (Eq. 12.9), defaults to 1 when omitted
        %                    (Raymer caps the true product near 0.98).
        %   Cl_alpha_2D   -- optional 2-D airfoil lift slope [1/rad];
        %                    eta = Cl_alpha_2D/(2*pi/beta) [Eq. 12.8], else 0.95.
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
        %CLMAX_CLEAN  Wing clean CLmax = 0.9*cl_max_2D*cos(Lambda_c/4).
        %   Raymer 6th ed. Eq. 12.15.
        %
        %   TODO (F-16 limitation): Eq. 12.15 is a plain swept-wing relation
        %   that IGNORES the F-16's leading-edge-extension (strake/LEX) vortex
        %   lift. With cl_max_2D=1.20 and Lambda_c/4~32.2 deg it gives
        %   CLmax~0.91 (near Brandt's clean 0.984) -- but the real
        %   whole-aircraft CLmax is ~1.6 once vortex lift is added. A
        %   vortex-lift correction (e.g. Polhamus leading-edge suction) is not
        %   modeled here.  See F16AeroL2.md / VnV/BrandtF16A/todo.md.
            CLmax = 0.9 * cl_max_2D * cosd(Lambda_c4_deg);
        end

        function mu = dyn_viscosity(T_atm_R)
        %DYN_VISCOSITY  Sutherland's law, English units (Raymer 6th ed. Sec. 12.3.1).
        %   Returns mu in slug/(ft*s).  mu_ref=3.737e-7 at T_ref=518.67 R,
        %   Sutherland constant C=198.6 R.  Shared with the L3 component buildup.
            mu_ref = 3.737e-7;
            T_ref  = 518.67;
            C_suth = 198.6;
            mu     = mu_ref * (T_atm_R/T_ref)^1.5 * (T_ref+C_suth)/(T_atm_R+C_suth);
        end

        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer 6th ed. Eq. 12.25).
        %   Shared with the L3 component buildup.
            mu = AeroL2.dyn_viscosity(state.T_atm);
            Re = state.rho * state.V * l_ref / mu;
        end

        function Cf = Cf_turbulent(Re, M)
        %CF_TURBULENT  Compressible turbulent flat-plate Cf.
        %   Cf = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Raymer 6th ed. Eq. 12.27.
        %   Shared with the L3 component buildup and the L2 supersonic CD0.
            Cf = 0.455 / (log10(Re)^2.58 * (1 + 0.144*M^2)^0.65);
        end

    end
end

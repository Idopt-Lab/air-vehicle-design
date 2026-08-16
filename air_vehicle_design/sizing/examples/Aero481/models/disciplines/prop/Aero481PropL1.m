classdef Aero481PropL1 < PropulsionModelL1
%Aero481PROPL1  F-35A (Aero 481 Design01 provenance) Level-1 propulsion class.
%
%   Single afterburning F135-PW-100. Inherits PropulsionModelL1 (abstract
%   enforcer); every equation lives in the PropL1 static toolbox -- no equation
%   is duplicated here.
%
%   Level-1 model:
%     thrust_lapse -- density-ratio law alpha = sigma^m, sigma = rho/rho_SL,
%                     m = 0.6 (low-bypass AB turbofan) [Martins AE481 metabook
%                     Eq. 10.9, via PropL1.sigma_lapse]. The fighter rating set
%                     is "mil"/"AB":
%                       "AB":  alpha = sigma^0.6 (full AB/max scale).
%                       "mil": alpha_mil = (T_SL_mil/T_SL)*sigma^0.6, the
%                                     mil-power lapse renormalized onto the ONE
%                                     max/AB T_SL basis (mirrors PropL2.
%                                     get_thrust_lapse_mil_on_AB_scale). The
%                                     scale is 28000/43000 = 0.6512.
%     get_TSFC     -- categorical by Mach regime (1/hr): static/SLS 0.35,
%                     subsonic cruise 0.65, supersonic AB dash 1.70
%                     [A481 Design01.m:78-80]. _TODO -- UNCITED (student values;
%                     the Part I F135 dry deck ~0.886 is a DIFFERENT basis --
%                     installed cruise). Guarded by a labelled testTODO.
%
%   ==========================================================================
%   NO ALTITUDE LAPSE -- FAITHFUL TO AERO 481 (discrepancy A6, REVERSED
%   2026-08-15). Aero 481 applies NO thrust lapse: every +Constraints/* uses
%   installed thrust at altitude with no alpha = T(alt)/T_SL term. To reproduce
%   Aero 481's constraint diagram AND its A02 sizing, this class sets
%   lapse_exponent_m = 0 (from the JSON), so alpha = sigma^0 = 1 at every
%   altitude -- no derating. An earlier build used the framework density lapse
%   alpha = sigma^0.6; that was the largest deviation from Aero 481 and it broke
%   the sizing match, so it was turned off (USER decision 2026-08-15). The
%   mil-on-AB thrust-SETTING scale alpha_mil = (T_SL_mil/T_SL) = 0.6512 still
%   applies for the "mil" rating (a power setting, not an altitude effect).
%   With m = 0 the sigma^m form below collapses to 1; the exponent stays a cited
%   input so the choice is explicit. See aero481_discrepancies.md A6 and
%   Aero481PropL1.md section 4.
%   ==========================================================================
%
%   INPUT vs DERIVED. Inputs are a plain mutable properties block set once by
%   the constructor from the JSON .propulsion block (an optimizer may mutate
%   them, e.g. the sizing loop overwrites T_SL in place). T_SL_wet is Dependent
%   on T_SL (an AB-scale alias) so the two cannot diverge under mutation.
%
%   CONSTRUCTOR: Aero481PropL1(json_path). Reads the .propulsion block of a
%   required unified L1 input JSON (aero481_spec_path(1)). No silent default -- the
%   path must be supplied (a no-arg call errors).
%
%   Inheritance: PropulsionBase -> PropulsionModelL1 -> Aero481PropL1
%
%   SOURCES:
%     [A481]     University of Michigan AEROSP 481 (Fall 2024) starter code by
%                Max Arnson -- design PROVENANCE, not a primary source.
%                Design01.m (T_SL, T_SL_mil, TSFC values, NEng=1).
%     [metabook] Martins/AE481 course notes (metabook), Eq. 10.9 (lapse
%                exponent m), docs/reference_extracts/metabook_data.md.
%     [Part I]   docs/reference_extracts/aero481_data.md Part I (F135-PW-100 thrust
%                values) -- published cross-check, wired as the spec stand-in.

    % ======================================================================= %
    % INPUTS -- engine-spec data (mutable; set once by the constructor from the
    % JSON .propulsion block, may be varied by an optimizer -- the sizing loop
    % overwrites T_SL in place, so it is deliberately not defensively guarded).
    % ======================================================================= %
    properties
        engine_type      = "low_bypass_turbofan_AB"  % PropulsionModelL1 contract; F135-PW-100 [aero481_data.md Part I]. Selects the PropL1 lapse exponent basis; the exponent itself is carried explicitly below.
        T_SL             = 43000    % lbf  AB (max) SLS thrust; PropulsionBase contract property AND the design variable the sizing loop overwrites [aero481_data.md Part I]
        T_SL_mil         = 28000    % lbf  mil (dry/intermediate) SLS thrust [aero481_data.md Part I]
        n_engines        = 1        % --   engine count (single F135) [aero481_data.md Part I; A481 NEng=1]
        lapse_exponent_m = 0        % --   density-ratio lapse exponent alpha = sigma^m. Set to 0 (from JSON) => alpha = 1, NO altitude lapse, FAITHFUL to Aero 481 (its constraints apply no lapse; disc A6, USER decision 2026-08-15). Was 0.6 (framework sigma^0.6 convention). _TODO -- UNCITED: restore m=0.6 only if the F-35 is later held to the framework lapse convention instead of A481 fidelity. Carried as an explicit cited INPUT (like B777PropL1).
        tsfc_sls         = 0.35     % 1/hr static / sea-level-static TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED; guarded by a labelled testTODO.
        tsfc_cruise      = 0.65     % 1/hr subsonic cruise TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED; guarded by a labelled testTODO.
        tsfc_dash        = 1.70     % 1/hr supersonic afterburning dash TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED (afterburning); guarded by a labelled testTODO.
        % (No stored TSFC property. TSFC is state-dependent -- call
        % get_TSFC(obj, state). This matches F16PropL1/B777PropL1.)
    end

    % ======================================================================= %
    % DERIVED -- recomputed live on every read; read-only (no set-method).
    % ======================================================================= %
    properties (Dependent)
        %T_SL_WET  lbf -- AB (max) SLS thrust; an ALIAS for T_SL, kept because
        %   the mil-on-AB scale and other call sites read the wet/AB name
        %   explicitly (mirrors F16PropL1). It is Dependent on T_SL so an
        %   optimizer changing T_SL cannot leave T_SL_wet stale.
        T_SL_wet
    end

    % ======================================================================= %
    % CONSTANTS -- Mach-regime thresholds for the categorical TSFC selector.
    % ======================================================================= %
    properties (Constant, Access = private)
        %MACH_STATIC_MAX  Mach below which the static / SLS TSFC row applies.
        %   Static and takeoff conditions (M ~ 0) take tsfc_sls; anything with
        %   forward speed up to sonic takes the cruise row. 0.1 is the L1 split
        %   point (the A481 static/takeoff vs cruise vs dash grouping has no
        %   explicit Mach boundary -- this reproduces its 3-way SLS/cruise/dash
        %   grouping). _TODO -- UNCITED (L1 regime-boundary approximation).
        MACH_STATIC_MAX = 0.1
        %MACH_SUPERSONIC_MIN  Mach at or above which the afterburning dash TSFC
        %   row applies (supersonic). M0.85 cruise -> cruise row; M1.6 dash ->
        %   dash row, matching the A481 segment grouping (aero481_data.md II.8).
        MACH_SUPERSONIC_MIN = 1.0
    end

    methods

        function obj = Aero481PropL1(json_path)
        %Aero481PROPL1  Construct from a required unified L1 input JSON path
        %   (aero481_spec_path(1)); reads its .propulsion block. No silent default:
        %   the path must be supplied.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).propulsion;
            obj.engine_type      = string(J.engine_type);
            obj.T_SL             = J.T_SL;
            obj.T_SL_mil         = J.T_SL_mil;
            obj.n_engines        = J.n_engines;
            obj.lapse_exponent_m = J.lapse_exponent_m;
            obj.tsfc_sls         = J.tsfc_sls;
            obj.tsfc_cruise      = J.tsfc_cruise;
            obj.tsfc_dash        = J.tsfc_dash;
            % T_SL_wet is NOT read: it is Dependent on T_SL (see its comment).
        end

        function v = get.T_SL_wet(obj)
            v = obj.T_SL;   % wet/AB SLS thrust IS T_SL by the PropulsionBase convention
        end

        % ================================================================== %
        % PropulsionBase / PropulsionModelL1 contract.
        % ================================================================== %

        function alpha = thrust_lapse(obj, state, rating)
        %THRUST_LAPSE  Density-ratio lapse at the given fighter power rating.
        %   alpha = sigma^m, sigma = rho/rho_SL, m = obj.lapse_exponent_m
        %   [metabook Eq. 10.9, via PropL1.sigma_lapse].
        %     "AB":  alpha = sigma^m -- full AB/max scale (used with T_SL for
        %            constraint analysis and sizing).
        %     "mil": alpha_mil = (T_SL_mil/T_SL)*sigma^m -- the mil-power lapse
        %            renormalized onto the ONE max/AB T_SL basis (28000/43000 =
        %            0.6512), so a dry condition stays comparable with an AB one
        %            on the same T_SL/W_TO diagram axis. Mirrors
        %            PropL2.get_thrust_lapse_mil_on_AB_scale.
        %   The rating is REQUIRED and validated against the fighter set
        %   ["mil","AB"] (as F16PropL1 does) so a caller cannot silently pass a
        %   setting the F135 does not have. The constraint infrastructure passes
        %   the requirements-JSON power_setting straight through, and the F-35
        %   requirements only carry "mil"/"AB" (Takeoff hardcodes "AB").
        %   DELIBERATE DEVIATION: Aero 481 applies NO lapse (disc A6) -- see
        %   the class header and Aero481PropL1.md section 4.
            arguments
                obj
                state  (1,1) AircraftState
                rating (1,1) string {mustBeMember(rating, ["mil","AB"])}
            end
            base = PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m);  % sigma^m [metabook Eq. 10.9]
            if rating == "mil"
                alpha = base * (obj.T_SL_mil / obj.T_SL);   % mil-on-AB scale = 28000/43000 = 0.6512
            else
                alpha = base;   % "AB" = full AB/max scale
            end
        end

        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  PropulsionModelL1 contract: the base (AB/max)
        %   density-ratio lapse sigma^m, no mil renormalization
        %   [metabook Eq. 10.9].
            alpha = PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m);
        end

        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Categorical TSFC [1/hr] by Mach regime [A481 Design01.m:78-80].
        %   M < MACH_STATIC_MAX (0.1)        -> tsfc_sls    = 0.35 (static/SLS)
        %   MACH_STATIC_MAX <= M < 1.0       -> tsfc_cruise = 0.65 (subsonic cruise)
        %   M >= MACH_SUPERSONIC_MIN (1.0)   -> tsfc_dash   = 1.70 (supersonic AB dash)
        %   This reproduces the A481 SLS/cruise/dash grouping (M0.85 -> cruise,
        %   M1.6 -> dash; aero481_data.md II.8). No AB Mach-correction term at L1.
        %   _TODO -- UNCITED: the TSFC values and the regime boundaries are
        %   student stand-ins; guarded by labelled testTODO tests.
            if state.mach < obj.MACH_STATIC_MAX
                c_t = obj.tsfc_sls;
            elseif state.mach < obj.MACH_SUPERSONIC_MIN
                c_t = obj.tsfc_cruise;
            else
                c_t = obj.tsfc_dash;
            end
        end

        function c_t = lookup_TSFC(obj, state)
        %LOOKUP_TSFC  PropulsionModelL1 contract alias for get_TSFC.
            c_t = obj.get_TSFC(state);
        end

    end

end

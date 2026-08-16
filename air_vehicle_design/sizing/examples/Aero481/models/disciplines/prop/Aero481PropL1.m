classdef Aero481PropL1 < PropulsionModelL1
%Aero481PROPL1  F-35A (Aero 481 Design01 provenance) Level-1 propulsion class.
%
%   Single afterburning F135-PW-100. Inherits PropulsionModelL1 (abstract
%   enforcer); every equation lives in the PropL1 static toolbox.
%
%   Level-1 model:
%     thrust_lapse -- density-ratio law alpha = sigma^m, sigma = rho/rho_SL
%                     [metabook Eq. 10.9, via PropL1.sigma_lapse]. Fighter rating
%                     set "mil"/"AB": "AB" gives alpha = sigma^m; "mil" gives
%                     alpha_mil = (T_SL_mil/T_SL)*sigma^m, the mil-power lapse
%                     renormalized onto the AB T_SL basis (28000/43000 = 0.6512;
%                     mirrors PropL2.get_thrust_lapse_mil_on_AB_scale).
%     get_TSFC     -- categorical by Mach regime (1/hr): static/SLS 0.35,
%                     subsonic cruise 0.65, supersonic AB dash 1.70
%                     [A481 Design01.m:78-80]. _TODO -- UNCITED, testTODO-guarded.
%
%   NO ALTITUDE LAPSE -- FAITHFUL TO AERO 481 (disc A6). lapse_exponent_m = 0
%   (from JSON), so alpha = sigma^0 = 1 at every altitude, matching Aero 481
%   (which applies no lapse). The mil-on-AB thrust-SETTING scale (0.6512) still
%   applies for "mil" (a power setting, not an altitude effect). The exponent
%   stays a cited input so the choice is explicit.
%
%   Inputs are set once from the JSON .propulsion block (an optimizer may mutate
%   them; the sizing loop overwrites T_SL). T_SL_wet is Dependent on T_SL.
%   CONSTRUCTOR: Aero481PropL1(json_path) -- required, no silent default.
%
%   Inheritance: PropulsionBase -> PropulsionModelL1 -> Aero481PropL1
%   History and rationale: docs/decision_log.md; companion .md; discrepancies
%   examples/Aero481/aero481_discrepancies.md (A6).
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
    % INPUTS -- engine-spec data set once from the JSON .propulsion block; an
    % optimizer may mutate them (the sizing loop overwrites T_SL in place).
    % ======================================================================= %
    properties
        engine_type      = "low_bypass_turbofan_AB"  % PropulsionModelL1 contract; F135-PW-100 [aero481_data.md Part I]. Selects the PropL1 lapse basis; the exponent is carried explicitly below.
        T_SL             = 43000    % lbf  AB (max) SLS thrust; PropulsionBase contract property AND the design variable the sizing loop overwrites [aero481_data.md Part I]
        T_SL_mil         = 28000    % lbf  mil (dry/intermediate) SLS thrust [aero481_data.md Part I]
        n_engines        = 1        % --   engine count (single F135) [aero481_data.md Part I; A481 NEng=1]
        lapse_exponent_m = 0        % --   density-ratio lapse exponent alpha = sigma^m. 0 (from JSON) => alpha = 1, NO altitude lapse, FAITHFUL to Aero 481 (disc A6). Explicit cited INPUT (like B777PropL1).
        tsfc_sls         = 0.35     % 1/hr static / sea-level-static TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED; testTODO-guarded.
        tsfc_cruise      = 0.65     % 1/hr subsonic cruise TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED; testTODO-guarded.
        tsfc_dash        = 1.70     % 1/hr supersonic afterburning dash TSFC [A481 Design01.m:78-80]. _TODO -- UNCITED; testTODO-guarded.
        % (No stored TSFC property -- TSFC is state-dependent, call get_TSFC.)
    end

    % ======================================================================= %
    % DERIVED -- recomputed live on every read; read-only (no set-method).
    % ======================================================================= %
    properties (Dependent)
        %T_SL_WET  lbf -- AB (max) SLS thrust; an alias for T_SL (call sites read
        %   the wet/AB name explicitly). Dependent on T_SL so it cannot go stale.
        T_SL_wet
    end

    % ======================================================================= %
    % CONSTANTS -- Mach-regime thresholds for the categorical TSFC selector.
    % A481 groups TSFC by segment with no explicit Mach boundary; these split
    % points reproduce that 3-way grouping. _TODO -- UNCITED (L1 approximation).
    % ======================================================================= %
    properties (Constant, Access = private)
        MACH_STATIC_MAX = 0.1        % below this -> static/SLS TSFC row
        MACH_SUPERSONIC_MIN = 1.0    % at/above this -> AB dash TSFC row [aero481_data.md II.8]
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
        %     "AB":  alpha = sigma^m -- full AB/max scale.
        %     "mil": alpha_mil = (T_SL_mil/T_SL)*sigma^m -- mil lapse on the AB
        %            T_SL basis (28000/43000 = 0.6512; mirrors
        %            PropL2.get_thrust_lapse_mil_on_AB_scale).
        %   Rating is REQUIRED, validated against ["mil","AB"] (as F16PropL1).
        %   With m = 0 (disc A6) alpha collapses to 1; see the class header.
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
        %   Reproduces the A481 SLS/cruise/dash grouping [aero481_data.md II.8].
        %   _TODO -- UNCITED (student stand-ins), testTODO-guarded.
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

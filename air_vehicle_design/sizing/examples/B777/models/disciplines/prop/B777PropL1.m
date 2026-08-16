classdef B777PropL1 < PropulsionModelL1
%B777PROPL1  Boeing 777-200LR Level-1 propulsion class (2x GE90-110B).
%
%   Inherits PropulsionModelL1 (abstract enforcer). Every method delegates to
%   the PropL1 static toolbox.
%
%   Level-1 model (metabook Example 4.2):
%     thrust_lapse -- density-ratio law alpha = sigma^m, sigma = rho/rho_SL
%                     [metabook Eqs. 4.55/10.9], at a transport rating
%                     ("TO"/"max" = takeoff; "cont" = 0.94*sigma^m, Eq. 4.25). m
%                     is the INPUT lapse_exponent_m = 0.6 (generic Eq. 10.9 fit),
%                     carried explicitly rather than from the engine-type table
%                     (decision D5, b777_L1.md §4.2).
%     get_TSFC     -- cruise TSFC from tsfc_cruise (the GE90 deck value, see §4).
%
%   NO AFTERBURNER. A high-bypass transport uses the transport rating set
%   "cont"/"TO"/"max" (not the fighter "mil"/"AB"). T_SL is the max (takeoff)
%   SLS thrust; "TO"/"max" give the full sigma^m lapse, "cont" the 0.94 derate.
%
%   CONSTRUCTOR: B777PropL1(json_path) -- reads .propulsion, no silent default.
%
%   Inheritance: PropulsionBase -> PropulsionModelL1 -> B777PropL1
%
%   SOURCES:
%     [metabook] AE481 metabook Example 4.2, docs/reference_extracts/
%       metabook_data.md. T_SL = 220000 lbf total [Fig. 4.7 caption];
%       lapse_exponent_m = 0.6 [Eqs. 4.55-4.57 / 10.9]; TSFC [Eq. 10.11].

    % ======================================================================= %
    % INPUTS -- engine-spec data (mutable; set once by the constructor from the
    % JSON .propulsion block, may be varied by an optimizer).
    % ======================================================================= %
    properties
        engine_type      = "high_bypass_turbofan"  % PropulsionModelL1 contract; [metabook §4.11, GE90-110B]. Carried for the contract + documentation; the lapse exponent is read from lapse_exponent_m below, not resolved from this key.
        T_SL             = 220000   % lbf  max SLS thrust, total (2x GE90-110B) [PropulsionBase contract; metabook Fig. 4.7 caption]
        n_engines        = 2        % --   engine count [metabook §4.11]
        lapse_exponent_m = 0.6      % --   density-ratio lapse exponent alpha = sigma^m [metabook Eqs. 4.55/10.9; decision D5, b777_L1.md §4.2]. Carried as an explicit INPUT rather than a table lookup so the modelling choice is cited.
        tsfc_cruise      = 0.52     % 1/hr cruise TSFC [metabook Table 10.1, GE90 at 40,000 ft ~0.50-0.54]. Used instead of the generic Mattingly Eq. 10.11 (which overestimates the GE90 ~30% and diverges converge_W0). See get_TSFC + b777_L1.md §4.
    end

    properties (Constant, Access = private)
        MAX_CONTINUOUS_FRACTION = 0.94   % -- max-continuous thrust is 94% of takeoff thrust [metabook Eq. 4.25]
    end

    methods

        function obj = B777PropL1(json_path)
        %B777PROPL1  Construct from a required unified L1 input JSON path
        %   (b777_spec_path(1)); reads its .propulsion block. No silent default.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).propulsion;
            obj.engine_type      = string(J.engine_type);
            obj.T_SL             = J.T_SL;
            obj.n_engines        = J.n_engines;
            obj.lapse_exponent_m = J.lapse_exponent_m;
            if isfield(J, 'tsfc_cruise')
                obj.tsfc_cruise = J.tsfc_cruise;
            end
        end

        % ================================================================== %
        % PropulsionBase / PropulsionModelL1 contract -- single delegations.
        % ================================================================== %

        function alpha = thrust_lapse(obj, state, rating)
        %THRUST_LAPSE  Density-ratio lapse at the given transport rating.
        %   "TO"/"max": alpha = sigma^m, sigma = rho/rho_SL [metabook Eqs.
        %   4.55/10.9]. "cont": 0.94 * sigma^m (max-continuous) [metabook
        %   Eq. 4.25]. Transport rating set "cont"/"TO"/"max" (no afterburner).
        %   m = obj.lapse_exponent_m (explicit input, engine-type table bypassed,
        %   decision D5), via PropL1.sigma_lapse.
            arguments
                obj
                state  (1,1) AircraftState
                rating (1,1) string {mustBeMember(rating, ["cont","TO","max"])}
            end
            base = PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m);
            if rating == "cont"
                alpha = B777PropL1.MAX_CONTINUOUS_FRACTION * base;   % Eq. 4.25
            else
                alpha = base;   % "TO"/"max" = full takeoff thrust
            end
        end

        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  PropulsionModelL1 contract: the base (max/takeoff)
        %   density-ratio lapse sigma^m, no rating derate.
            alpha = PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m);
        end

        function c_t = get_TSFC(obj, ~)
        %GET_TSFC  Cruise TSFC [1/hr] = obj.tsfc_cruise, the GE90's real deck SFC
        %   [metabook Table 10.1, ~0.52 at 40,000 ft]. NOT the generic Mattingly
        %   form (Eq. 10.11), which overestimates the GE90 ~30% and diverges
        %   converge_W0. PropL1.tsfc_mattingly_hibpr stays available for the
        %   comparison report. See the tsfc_cruise property.
            c_t = obj.tsfc_cruise;
        end

        function c_t = lookup_TSFC(obj, state)
        %LOOKUP_TSFC  PropulsionModelL1 contract alias for get_TSFC.
            c_t = obj.get_TSFC(state);
        end

    end

end

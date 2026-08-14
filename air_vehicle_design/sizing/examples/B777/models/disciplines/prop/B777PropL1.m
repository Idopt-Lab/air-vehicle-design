classdef B777PropL1 < PropulsionModelL1
%B777PROPL1  Boeing 777-200LR Level-1 propulsion class (2x GE90-110B).
%
%   Inherits PropulsionModelL1 (abstract enforcer). Every method delegates to
%   the PropL1 static toolbox -- no equations are duplicated here.
%
%   Level-1 model (metabook Example 4.2):
%     thrust_lapse -- density-ratio law alpha = sigma^m, sigma = rho/rho_SL
%                     [metabook Eqs. 4.55/10.9]. m is carried as the INPUT
%                     lapse_exponent_m = 0.6 (the metabook's generic Eq. 10.9
%                     fit) rather than resolved from the engine-type table, so
%                     the modelling choice is explicit and cited (b777_L1.md §4.2,
%                     decision D5).
%     get_TSFC     -- high-bypass Mattingly form c = (0.4 + 0.45*M)*sqrt(theta)
%                     [1/hr] [metabook Eq. 10.11 = Mattingly 1996 Eq. 1.36a],
%                     theta from AircraftState. This is the Mach/temperature-
%                     dependent form the B777 mission prefers over PropL1's crude
%                     categorical TSFC row.
%
%   NO AFTERBURNER. A high-bypass transport has no AB, so the wet/mil/AB thrust
%   distinction the F-16 carries collapses to a single basis: T_SL is the max
%   SLS thrust, thrust_lapse and thrust_lapse_mil_on_AB_scale are the SAME lapse
%   (see the overridden method below).
%
%   CONSTRUCTOR: B777PropL1(json_path). Reads the .propulsion block of a
%   required unified L1 input JSON (b777_spec_path(1)). No silent default.
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
        tsfc_cruise      = 0.52     % 1/hr cruise TSFC [metabook Table 10.1, GE90 cruise-partial-power rows at 40,000 ft (~0.50-0.54)]. USED instead of the generic Mattingly Eq. 10.11 form (which gives ~0.675 at M0.84/40kft -- a ~30% overestimate of the real GE90 that makes the max-range mission fuel exceed the aircraft's capacity, so converge_W0 diverges). Using the engine's OWN deck SFC (Table 10.1) is a metabook-DATA value, not backfilled from the sizing answer, and lets the modelled 777 close near its size (matching the metabook's own feasible-777 Fig. 4.7). See get_TSFC + b777_L1.md.
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

        function alpha = thrust_lapse(obj, state)
        %THRUST_LAPSE  alpha = sigma^m, sigma = rho/rho_SL [metabook Eqs. 4.55/
        %   10.9]. m is obj.lapse_exponent_m (an explicit input), passed
        %   straight to the pure-math static PropL1.sigma_lapse(rho, m) -- the
        %   engine-type table is bypassed on purpose (decision D5).
            alpha = PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m);
        end

        function alpha = get_thrust_lapse(obj, state)
            alpha = obj.thrust_lapse(state);
        end

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  A high-bypass transport has NO afterburner,
        %   so mil and AB thrust are one and the same: the mil-on-AB-scale lapse
        %   IS thrust_lapse. Overrides the PropulsionBase default (which already
        %   returns thrust_lapse) only to document that this is deliberate, not an
        %   omission. One basis; b777_L1.md §4.
            alpha = obj.thrust_lapse(state);
        end

        function c_t = get_TSFC(obj, ~)
        %GET_TSFC  Cruise TSFC [1/hr] = obj.tsfc_cruise, the GE90's real deck
        %   SFC [metabook Table 10.1, ~0.52 at 40,000 ft].
        %
        %   NOT the generic Mattingly high-bypass form c = (0.4+0.45*M)*sqrt(theta)
        %   [metabook Eq. 10.11], which gives ~0.675 at M0.84/40kft and
        %   overestimates the real GE90 by ~30%. That overestimate makes the
        %   8,555-nmi max-range mission demand more fuel than the aircraft can
        %   carry, so the TOGW closure (converge_W0) diverges. The engine's own
        %   Table 10.1 deck value is a metabook-sourced DATA input (see the
        %   tsfc_cruise property) -- using it, the modelled 777 closes and sits
        %   in the T-S feasible region, as the metabook's own Fig. 4.7 shows.
        %   PropL1.tsfc_mattingly_hibpr (Eq. 10.11) stays available; the
        %   comparison report evaluates it to quantify the overestimate.
            c_t = obj.tsfc_cruise;
        end

        function c_t = lookup_TSFC(obj, state)
        %LOOKUP_TSFC  PropulsionModelL1 contract alias for get_TSFC.
            c_t = obj.get_TSFC(state);
        end

    end

end

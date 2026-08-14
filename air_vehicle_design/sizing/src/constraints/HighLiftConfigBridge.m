classdef HighLiftConfigBridge
%HIGHLIFTCONFIGBRIDGE  Minimal-blast-radius bridge to per-high-lift-config polars.
%
%   WHY THIS EXISTS. The FAR-25 field-length and climb-gradient constraints
%   (TakeoffFieldLength, LandingFieldLength, ClimbGradient) each need the drag
%   polar AND CLmax of a SPECIFIC high-lift configuration (flaps + gear state),
%   not the single clean polar the enforced AerodynamicsBase interface exposes.
%   AerodynamicsBase declares only drag_polar(state) and get_CLmax(state) as
%   abstract -- there is no per-configuration accessor on the contract.
%
%   The clean fix is a HighLiftConfig value class taken as a first-class
%   argument to drag_polar(state, config)/get_CLmax(state, config). That
%   touches the two CORE abstract aero methods every discipline consumer calls
%   (weights, propulsion coupling, every comparison script) -- a large blast
%   radius that needs its own citation review and its own plan, so it is
%   DEFERRED (docs/ToDo_Darshan.md item 1). Do NOT trigger that rewrite here.
%
%   THIS BRIDGE is the minimal successor idiom to TakeoffConstraint's
%   duck-typed get_Delta_CD0_TO_dispatched reflection: a concrete aero class
%   exposes one extra method, get_config_polar(config), returning a
%   struct(CD0, K1, K2, CLmax) for the named configuration. This class routes
%   the constraint's request to that method and validates the seam, so a
%   missing or malformed aero implementation fails loudly HERE rather than
%   downstream inside a constraint's arithmetic.
%
%   NO ARITY REFLECTION. Unlike the F16 get_Delta_CD0_* dispatch (whose
%   signature varies by fidelity level -- L1/L2 take no state, L3 takes state),
%   get_config_polar's signature is uniform by definition from day one:
%   (obj, config) -> struct at every level. This is the lesson learned from the
%   F16 dispatched-method mess -- a uniform contract needs no metaclass
%   reflection.
%
%   THE SIX CONFIG STRINGS are exactly the Roskam Table 3.6 configuration rows
%   plus gear state, plus the metabook approach convention:
%     clean, takeoff_flaps_gear_up, takeoff_flaps_gear_down,
%     landing_flaps_gear_up, landing_flaps_gear_down, approach.
%   They are chosen so they become the future HighLiftConfig named presets --
%   each concrete get_config_polar collapses to a one-line adapter into that
%   value class when the deferred rewrite lands.
%
%   Companion: docs/ToDo_Darshan.md item 1 (the deferred HighLiftConfig plan).

    properties (Constant)
        %CONFIGS  The six recognized high-lift configuration names. See class
        %   header for provenance (Roskam Table 3.6 rows + gear state + metabook
        %   approach convention). Kept as a Constant so the constraint classes,
        %   the test stubs, and the future HighLiftConfig presets share one
        %   source of truth for the valid set.
        CONFIGS = ["clean", ...
                   "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                   "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                   "approach"];
    end

    methods (Static)

        function cfg = polar(aero, config)
        %POLAR  Drag polar + CLmax for a named high-lift configuration.
        %   cfg = HighLiftConfigBridge.polar(aero, config) returns the
        %   struct(CD0, K1, K2, CLmax) the aero object reports for CONFIG.
        %
        %   AERO   an AerodynamicsBase-derived object that additionally exposes
        %          get_config_polar(config). CONFIG one of CONFIGS.
        %
        %   Errors (loud at the seam, never silent):
        %     HighLiftConfigBridge:contractNotImplemented  aero has no
        %         get_config_polar method.
        %     HighLiftConfigBridge:badPolarStruct  the returned value is not a
        %         struct with fields CD0/K1/K2/CLmax.
            arguments
                aero   (1,1) AerodynamicsBase
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end

            if ~ismethod(aero, 'get_config_polar')
                error('HighLiftConfigBridge:contractNotImplemented', ...
                    ['aero (class %s) has no get_config_polar method. The FAR-25 ', ...
                     'field-length and climb-gradient constraints need a per-high-', ...
                     'lift-configuration polar, which the enforced AerodynamicsBase ', ...
                     'interface (drag_polar/get_CLmax only) does not expose. Until ', ...
                     'the deferred HighLiftConfig rewrite lands (docs/ToDo_Darshan.md ', ...
                     'item 1), a concrete aero class must implement ', ...
                     'get_config_polar(config) -> struct(CD0, K1, K2, CLmax) for ', ...
                     'config in {%s}.'], ...
                    class(aero), strjoin(HighLiftConfigBridge.CONFIGS, ", "));
            end

            cfg = aero.get_config_polar(config);

            required = ["CD0", "K1", "K2", "CLmax"];
            if ~isstruct(cfg) || ~all(isfield(cfg, required))
                if isstruct(cfg)
                    got = strjoin(string(fieldnames(cfg))', ", ");
                else
                    got = sprintf('a %s (not a struct)', class(cfg));
                end
                error('HighLiftConfigBridge:badPolarStruct', ...
                    ['aero.get_config_polar("%s") (class %s) must return a struct ', ...
                     'with fields CD0, K1, K2, CLmax; got %s.'], ...
                    config, class(aero), got);
            end
        end

    end

end

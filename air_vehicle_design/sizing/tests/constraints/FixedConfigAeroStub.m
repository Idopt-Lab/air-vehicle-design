classdef FixedConfigAeroStub < AerodynamicsBase
%FIXEDCONFIGAEROSTUB  A deterministic per-config aero stand-in, used only by tests.
%
%   WHY THIS EXISTS. The FAR-25 field-length and climb-gradient constraints
%   (TakeoffFieldLength, LandingFieldLength, ClimbGradient) read a per-high-
%   lift-configuration polar via HighLiftConfigBridge.polar(aero, config),
%   which forwards to aero.get_config_polar(config) -> struct(CD0,K1,K2,CLmax).
%   FixedConfigAeroStub is the deterministic aero for those constraints' unit
%   tests: get_config_polar(config) returns known CD0/K1/K2/CLmax per config so
%   a test can assert a hand-computed constraint value against the metabook
%   Example 4.2 numbers, without dragging a real F16AeroLN model into the loop.
%
%   It subclasses AerodynamicsBase only because that is the type the constraint
%   constructors (and HighLiftConfigBridge.polar's arguments block) require.
%   The AerodynamicsBase abstract methods drag_polar/get_CLmax are implemented
%   minimally against the CLEAN configuration -- they exist to satisfy the
%   contract, and a test that wants a specific config uses get_config_polar.
%
%   SHIPPED VALUES (no-arg constructor) are the metabook Example 4.2 twin-jet
%   (B777-class) drag polars [metabook_data.md §4.11 Example 4.2, p.44]:
%
%     config                    CD0       K1        K2   CLmax
%     clean                     0.01597   0.03815   0    0.90
%     takeoff_flaps_gear_up     0.03597   0.04054   0    2.00
%     takeoff_flaps_gear_down   0.06097   0.04054   0    2.00
%     landing_flaps_gear_up     0.09097   0.04324   0    2.60
%     landing_flaps_gear_down   0.11597   0.04324   0    2.60
%     approach                  0.08847   0.04324   0    2.21
%
%   approach CD0 = mean(takeoff_flaps_gear_down, landing_flaps_gear_down) =
%   mean(0.06097, 0.11597) = 0.08847; approach CLmax = 0.85 * 2.60 = 2.21.
%
%   DISCREPANCY NOTE for the test-writer (log entry D1): the metabook prints a
%   CLmax of 2.2 in its climb-gradient EQUATIONS but 2.0/2.6 in its config
%   TABLE. This STUB carries the config-table CLmax (takeoff 2.0, landing 2.6).
%   The climb equations' 2.2 is a separate per-condition input the climb-
%   gradient constraint tests must supply DIRECTLY -- do not read it off this
%   stub.
%
%   A custom configMap may be passed instead (see the constructor) for tests
%   that need other numbers.

    % --- Clean-config polar the AerodynamicsBase contract methods report ---
    % Plain properties (a stub, not an optimization-facing Tier-3 class): the
    % clean values drag_polar/get_CLmax echo. get_config_polar uses configMap.
    properties
        CD0_clean   = 0.01597   % [metabook_data.md §4.11 Example 4.2, p.44]
        K1_clean    = 0.03815   % [metabook_data.md §4.11 Example 4.2, p.44]
        K2_clean    = 0         % [metabook_data.md §4.11 Example 4.2, p.44]
        CLmax_clean = 0.90      % [metabook_data.md §4.11 Example 4.2, p.44]
        configMap               % containers.Map: config string -> struct(CD0,K1,K2,CLmax)
    end

    methods

        function obj = FixedConfigAeroStub(configMap)
        %FIXEDCONFIGAEROSTUB  Build the stub.
        %   FixedConfigAeroStub() ships the metabook Example 4.2 values (see
        %   class header). FixedConfigAeroStub(configMap) uses a caller-supplied
        %   map instead, where configMap is a containers.Map (or struct) keyed
        %   by the six HighLiftConfigBridge config strings, each value a
        %   struct(CD0, K1, K2, CLmax).
            arguments
                configMap = FixedConfigAeroStub.defaultConfigMap()
            end
            if isstruct(configMap)
                configMap = FixedConfigAeroStub.structToMap(configMap);
            end
            if ~isa(configMap, 'containers.Map')
                error('FixedConfigAeroStub:badConfigMap', ...
                    ['configMap must be a containers.Map or struct keyed by the ', ...
                     'HighLiftConfigBridge config strings; got a %s.'], class(configMap));
            end
            obj.configMap = configMap;

            % Keep the AerodynamicsBase clean-config accessors consistent with
            % the map's clean entry when one is present.
            if isKey(obj.configMap, 'clean')
                c = obj.configMap('clean');
                obj.CD0_clean   = c.CD0;
                obj.K1_clean    = c.K1;
                obj.K2_clean    = c.K2;
                obj.CLmax_clean = c.CLmax;
            end
        end

        % --- AerodynamicsBase abstract contract (clean config) --------------

        function polar = drag_polar(obj, ~)
        %DRAG_POLAR  Clean drag polar, state-independent. Satisfies the
        %   AerodynamicsBase abstract contract; a test wanting a specific
        %   high-lift config uses get_config_polar instead.
            polar = struct('CD0', obj.CD0_clean, 'K1', obj.K1_clean, 'K2', obj.K2_clean);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Clean CLmax, state-independent. Satisfies the
        %   AerodynamicsBase abstract contract.
            CLmax = obj.CLmax_clean;
        end

        % --- The bridge contract HighLiftConfigBridge.polar forwards to -----

        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Per-configuration polar from the stored map.
        %   config one of the six HighLiftConfigBridge config strings; returns
        %   struct(CD0, K1, K2, CLmax).
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            key = char(config);
            if ~isKey(obj.configMap, key)
                error('FixedConfigAeroStub:configNotInMap', ...
                    'FixedConfigAeroStub has no entry for config "%s".', config);
            end
            cfg = obj.configMap(key);
        end

    end

    methods (Static, Access = private)

        function m = defaultConfigMap()
        %DEFAULTCONFIGMAP  The metabook Example 4.2 twin-jet polars.
        %   [metabook_data.md §4.11 Example 4.2, p.44] -- see class header for
        %   the table and the approach-row derivations.
            keys = {'clean', ...
                    'takeoff_flaps_gear_up', 'takeoff_flaps_gear_down', ...
                    'landing_flaps_gear_up', 'landing_flaps_gear_down', ...
                    'approach'};
            vals = { ...
                struct('CD0', 0.01597, 'K1', 0.03815, 'K2', 0, 'CLmax', 0.90), ...
                struct('CD0', 0.03597, 'K1', 0.04054, 'K2', 0, 'CLmax', 2.00), ...
                struct('CD0', 0.06097, 'K1', 0.04054, 'K2', 0, 'CLmax', 2.00), ...
                struct('CD0', 0.09097, 'K1', 0.04324, 'K2', 0, 'CLmax', 2.60), ...
                struct('CD0', 0.11597, 'K1', 0.04324, 'K2', 0, 'CLmax', 2.60), ...
                struct('CD0', 0.08847, 'K1', 0.04324, 'K2', 0, 'CLmax', 2.21)};
            m = containers.Map(keys, vals);
        end

        function m = structToMap(s)
        %STRUCTTOMAP  Convert a struct keyed by config name into a Map.
            fn = fieldnames(s);
            m = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:numel(fn)
                m(fn{i}) = s.(fn{i});
            end
        end

    end

end

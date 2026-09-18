classdef TtpaWeights < WeightsModelL2
%TTPAWEIGHTS  Tier-1 component build-up weight model for a piston-prop aircraft.
%
%   Component build-up:
%
%       OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage
%             + W_landing_gear + W_installed_engine + W_all_else_empty
%
%   Geometry and propulsion quantities are supplied through dependency
%   injection. Derived properties recompute live from the injected models.
%
%   The previous empirical relationship
%
%       OEW = 0.911 * W_TO^0.947
%
%   is retained only as a reference/check and is not used as the primary
%   component build-up.
%
%   Inheritance:
%       WeightsBase -> WeightsModelL2 -> TtpaWeights

    % ===================================================================== %
    % INPUTS / STATE
    % ===================================================================== %
    properties
        aircraft_category = 'general_aviation'
        % ----- WeightsBase abstract properties ----- %
        W_TO                 = NaN    % lbf  candidate gross takeoff weight
        W_energy             = NaN    % lbf  total fuel/battery weight
        W_payload_expendable = 0      % lbf  expendable payload
        W_payload_fixed      = 1200   % lbf  fixed payload + crew

        % ----- Injected collaborators ----- %
        geom                 % GeometryModelL2
        prop                 % PropulsionBase
    end

    % ===================================================================== %
    % DERIVED
    % ===================================================================== %
    properties (Dependent)

        % ----- Geometry / propulsion -------------------------------------- %
        N_en                 % engine count
        S_exp                % exposed wing area [ft^2]
        S_ht                 % exposed horizontal-tail area [ft^2]
        S_vt                 % exposed vertical-tail area [ft^2]
        S_wet_fuse           % fuselage wetted area [ft^2]
        W_en                 % single-engine weight [lbf]

        % ----- Component / group weights ---------------------------------- %
        W_wings              % wing weight [lbf]
        W_tail               % struct containing HT and VT weights [lbf]
        W_fuselage           % fuselage weight [lbf]
        W_landing_gear       % landing gear weight [lbf]
        W_installed_engine   % installed engine weight [lbf]
        W_all_else_empty     % all-else-empty weight [lbf]

        % ----- Total weights ---------------------------------------------- %
        OEW                   % empty operating weight [lbf]
        W_empty               % empty weight [lbf]
        W_payload             % total payload [lbf]
    end

    methods

        % ================================================================= %
        % Constructor
        % ================================================================= %

        function obj = TtpaWeights(geom, prop)

            arguments
                geom (1,1) GeometryBase
                prop (1,1) PropulsionBase2
            end

            obj.geom = geom;
            obj.prop = prop;
        end

        % ================================================================= %
        % OEW / major component build-up
        % ================================================================= %

        function oew = get_OEW_major_component_buildup(obj)
        %GET_OEW_MAJOR_COMPONENT_BUILDUP  Calculate OEW from component weights.
        %
        %   All components are evaluated at the supplied candidate W_TO.

            tail = obj.W_tail();

            oew = obj.get_wing_weight() ...
                + tail.HT ...
                + tail.VT ...
                + obj.W_fuselage() ...
                + obj.W_landing_gear() ...
                + obj.W_installed_engine() ...
                + obj.W_all_else_empty();
        end

        % ================================================================= %
        % Component weight methods
        % ================================================================= %

        function W = get_wing_weight(obj, ~)
        %GET_WING_WEIGHT  Calculate wing structural weight.

            W = WeightsL2.compute_weight_wing( ...
                obj.aircraft_category, obj.S_exp);
        end

        function W = weight_tail(obj, ~)
        %WEIGHT_TAIL  Calculate horizontal and vertical tail weights.

            W = struct( ...
                'HT', WeightsL2.compute_weight_HT( ...
                    obj.aircraft_category, obj.S_ht), ...
                'VT', WeightsL2.compute_weight_VT( ...
                    obj.aircraft_category, obj.S_vt));
        end

        function W = weight_fuselage(obj, ~)
        %WEIGHT_FUSELAGE  Calculate fuselage structural weight.

            W = WeightsL2.compute_weight_fuselage( ...
                obj.aircraft_category, obj.S_wet_fuse);
        end

        function W = weight_landing_gear(obj)
        %WEIGHT_LANDING_GEAR  Calculate landing gear weight.

            W = WeightsL2.compute_weight_landing_gear( ...
                obj.aircraft_category, obj.W_TO);
        end

        function W = weight_installed_engine(obj, ~)
        %WEIGHT_INSTALLED_ENGINE  Calculate installed engine weight.

            W = 5.47*obj.prop.P_SL^0.780;
        end

        function W = weight_all_else_empty(obj, W_TO)
        %WEIGHT_ALL_ELSE_EMPTY  Calculate remaining empty weight.

            W = WeightsL2.compute_weight_all_else_empty( ...
                obj.aircraft_category, W_TO);
        end

        % ================================================================= %
        % Derived getters
        % ================================================================= %

        function v = get.N_en(obj)
            v = obj.prop.n_engines;
        end

        function v = get.S_exp(obj)
            v = obj.geom.S_exposed_wing;
        end

        function v = get.S_ht(obj)
            v = obj.geom.S_exposed_ht;
        end

        function v = get.S_vt(obj)
            v = obj.geom.S_exposed_vt;
        end

        function v = get.S_wet_fuse(obj)
            v = obj.geom.S_wet_fuse;
        end

        function v = get.W_en(obj)
            % Single piston engine weight.
            %
            % TODO: Replace with an appropriate piston-engine weight
            % relationship rather than the current generic WeightsL2 call.

            v = WeightsL2.jet_engine_weight_roskam(obj.prop.P_SL / obj.N_en);
        end

        function v = get.W_wings(obj)
            v = obj.get_wing_weight([]);
        end

        function v = get.W_tail(obj)
            v = obj.weight_tail();
        end

        function v = get.W_fuselage(obj)
            v = obj.weight_fuselage([]);
        end

        function v = get.W_landing_gear(obj)
            v = obj.weight_landing_gear();
        end

        function v = get.W_installed_engine(obj)
            v = obj.weight_installed_engine([]);
        end

        function v = get.W_all_else_empty(obj)
            v = obj.weight_all_else_empty( ...
                obj.requireWTO('W_all_else_empty'));
        end

        function v = get.OEW(obj)
            v = obj.get_OEW_major_component_buildup();
        end

        function v = get.W_empty(obj)
            v = obj.OEW;
        end

        function v = get.W_payload(obj)
            v = obj.W_payload_fixed + obj.W_payload_expendable;
        end

    end

    % ===================================================================== %
    % PRIVATE HELPERS
    % ===================================================================== %
    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it is not set.

            W_TO = obj.W_TO;

            if ~isfinite(W_TO) || W_TO <= 0
                error('TtpaWeights:WTONotSet', ...
                    ['%s requires obj.W_TO to be set to a positive value ', ...
                     'first (currently %g). Set it from the sizing loop, ', ...
                     'or evaluate the build-up using an explicit W_TO.'], ...
                    whatFor, W_TO);
            end
        end

    end
end
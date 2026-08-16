classdef F16SandCL2 < SandCModelL2
%F16SANDCL2  F-16A Block 10/15 Level-2 stability & control student class.
%
%   Inherits from SandCModelL2 (abstract enforcer). Computes ONLY the
%   aircraft center-of-gravity x-station, x_cg: F16GeomL2 exposes no x-station
%   properties, so none of Eqs. 16.4-16.15 are computable at this fidelity.
%
%   METHOD:  x_cg = Sum(W_i * x_i) / Sum(W_i)  [SandCL2.weighted_cg]
%   over the 10 WeightsL2-matched component groups (wing, horizontal_tail,
%   vertical_tail, fuselage, landing_gear, installed_engine, subsystems_lump,
%   strake, payload, fuel) in
%   examples/F16A/inputs/f16a_L2.json .stability_control.component_x_stations
%   .groups. Each group's x-station (cg_x_ft) is read once from the JSON at
%   construction; each group's weight is read live from the injected
%   F16WeightsL2 object (see group_weight for the weights-property mapping).
%
%   front_edge_x_ft is never read -- always null at L2; this class needs only
%   cg_x_ft.
%
%   DEPENDENCY INJECTION -- one required injected collaborator plus a required
%   JSON path, no silent defaults:
%     weights -- (1,1) F16WeightsL2 (CONCRETE). Typed concretely because
%                W_strake and W_tail.HT/W_tail.VT are F16WeightsL2-specific,
%                not on any abstract weights contract.
%
%   x_cg propagates NaN gracefully for the 'fuel' group: W_energy reads NaN
%   until the mission/sizing loop sets it, and IEEE arithmetic inside
%   SandCL2.weighted_cg propagates that NaN with no error. Other groups
%   (landing_gear, subsystems_lump) need obj.weights.W_TO set first and error
%   loudly through F16WeightsL2.requireWTO if it is not.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [readme_bsc.md] VnV/BrandtF16A/readme_bsc.md "CG closure" -- the
%       weighted-average CG identity this class's one formula implements.
%     Component weight/x-station data: the "Component-x-location buildup"
%       re-aggregated into this framework's own 10 WeightsL2/L3 groups.
%
%   Companion doc: examples/F16A/models/disciplines/sandc/F16SandCL2.md

    % Fixed group order -- matches f16a_L2.json
    % .stability_control.component_x_stations.groups key order. Hardcoded so
    % the group_weight mapping is unambiguous and order-stable.
    properties (Constant)
        COMPONENT_GROUP_NAMES = {'wing', 'horizontal_tail', 'vertical_tail', ...
            'fuselage', 'landing_gear', 'installed_engine', 'subsystems_lump', ...
            'strake', 'payload', 'fuel'}
    end

    % INPUTS -- set once by the constructor. component_cg_x_ft is static spec
    % data (read once); weights are read live.
    properties
        component_cg_x_ft (1,10) double   % ft  [f16a_L2.json .stability_control.component_x_stations.groups.*.cg_x_ft, COMPONENT_GROUP_NAMES order]

        % ----- Injected collaborator (NOT numeric spec data) -------------- %
        weights   % (1,1) F16WeightsL2 -- supplies every component group's WEIGHT live, by DI
    end

    % ======================================================================= %
    % DERIVED -- recomputed live from the injected weights object on every
    % read (no cache, never stale). Read-only (no set-method).
    % ======================================================================= %
    properties (Dependent)
        x_cg   % ft  [StabControlBase contract] = SandCL2.weighted_cg(component_weights, component_cg_x_ft)
    end

    methods

        function obj = F16SandCL2(json_path, weights)
        %F16SANDCL2  Construct from a required unified L2 input JSON path
        %   (f16a_spec_path(2); reads its .stability_control block) and a
        %   required injected F16WeightsL2 object. No silent default on either.
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                weights   (1,1) F16WeightsL2
            end
            obj.weights = weights;

            J = jsondecode(fileread(json_path));
            groups = J.stability_control.component_x_stations.groups;

            names = F16SandCL2.COMPONENT_GROUP_NAMES;
            x = zeros(1, numel(names));
            for i = 1:numel(names)
                x(i) = groups.(names{i}).cg_x_ft;
            end
            obj.component_cg_x_ft = x;
        end

        % ================================================================== %
        % DERIVED-property getter -- recomputes live on every read.
        % ================================================================== %

        function v = get.x_cg(obj)
            v = SandCL2.weighted_cg(obj.component_weights(), obj.component_cg_x_ft);
        end

    end

    methods (Access = private)

        function w = component_weights(obj)
        %COMPONENT_WEIGHTS  Live weight [lbf] for each of the 10 groups, in
        %   COMPONENT_GROUP_NAMES order -- one call per group into
        %   group_weight, which does the actual DI reads.
            names = obj.COMPONENT_GROUP_NAMES;
            w = zeros(1, numel(names));
            for i = 1:numel(names)
                w(i) = obj.group_weight(names{i});
            end
        end

        function val = group_weight(obj, name)
        %GROUP_WEIGHT  Live weight [lbf] for ONE named group, read from the
        %   injected F16WeightsL2 object. Mapping matches
        %   f16a_L2.json .stability_control.component_x_stations.groups.*
        %   .weights_property field-for-field:
        %     wing              -> W_wings
        %     horizontal_tail   -> W_tail.HT
        %     vertical_tail     -> W_tail.VT
        %     fuselage          -> W_fuselage
        %     landing_gear      -> W_landing_gear                (needs weights.W_TO set -- requireWTO)
        %     installed_engine  -> W_installed_engine
        %     subsystems_lump   -> W_all_else_empty               (needs weights.W_TO set -- requireWTO)
        %     strake            -> W_strake
        %     payload           -> W_payload_fixed + W_payload_expendable
        %     fuel              -> W_energy                       (mission-analysis STATE; NaN pre-mission -- propagates gracefully, see class header)
            wts = obj.weights;
            switch name
                case 'wing',             val = wts.W_wings;
                case 'horizontal_tail',  val = wts.W_tail.HT;
                case 'vertical_tail',    val = wts.W_tail.VT;
                case 'fuselage',         val = wts.W_fuselage;
                case 'landing_gear',     val = wts.W_landing_gear;
                case 'installed_engine', val = wts.W_installed_engine;
                case 'subsystems_lump',  val = wts.W_all_else_empty;
                case 'strake',           val = wts.W_strake;
                case 'payload',          val = wts.W_payload_fixed + wts.W_payload_expendable;
                case 'fuel',             val = wts.W_energy;
                otherwise
                    error('F16SandCL2:unknownComponentGroup', ...
                        ['Unknown component-x-station group "%s" -- not one of ' ...
                         'F16SandCL2.COMPONENT_GROUP_NAMES. Check ' ...
                         'f16a_L2.json .stability_control.component_x_stations.groups.'], name);
            end
        end

    end

end

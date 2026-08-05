classdef F16SandCL2 < SandCModelL2
%F16SANDCL2  F-16A Block 10/15 Level-2 stability & control student class.
%
%   Inherits from SandCModelL2 (abstract enforcer). Computes ONLY the
%   aircraft center-of-gravity x-station, x_cg -- per
%   docs/subplans/10_stability_control.md's "DECIDED (Casey, 2026-08-03):
%   F16SandCL2 is limited to the CG term only" note: F16GeomL2 exposes NO
%   x-station properties at all, so none of Eqs. 16.4/16.5/16.7/16.8/16.9/
%   16.11/16.12/16.13/16.14/16.15 are computable at this fidelity level --
%   this is not a scope choice, it is what the injected geometry object can
%   supply.
%
%   METHOD:  x_cg = Sum(W_i * x_i) / Sum(W_i)  [SandCL2.weighted_cg]
%   over the 10 WeightsL2-matched component groups (wing, horizontal_tail,
%   vertical_tail, fuselage, landing_gear, installed_engine, subsystems_lump,
%   strake, payload, fuel) in
%   examples/F16A/jsons/f16a_L2.json .stability_control.component_x_stations
%   .groups. Each group's x-STATION (cg_x_ft) is READ ONCE from the JSON at
%   construction (static spec data, an engineering estimate re-aggregated
%   from the legacy temp_Casey "Stability&Control" sheet -- see that JSON
%   block's own _cg_x_ft_estimate_method note); each group's WEIGHT is read
%   LIVE, on every call, from the injected F16WeightsL2 object, via
%   group_weight's own switch (see that method's header for the exact
%   weights-property mapping, matching the JSON's own "weights_property"
%   documentation field name-for-name).
%
%   front_edge_x_ft is DELIBERATELY never read -- it is always null at L2
%   (F16GeomL2 has no x-station properties to cite one from), and this class
%   needs no cross-check field, only cg_x_ft, per the JSON's own
%   _L2_has_no_front_edge_data note.
%
%   ============================================================================
%   DEPENDENCY INJECTION.  Mirrors F16GeomL2(json_path, prop)'s pattern: ONE
%   required injected collaborator plus a required JSON path, no silent
%   defaults on either.
%     weights -- (1,1) F16WeightsL2 (CONCRETE, not the abstract WeightsBase/
%                WeightsModelL2 enforcer tier). Typed concretely because
%                W_strake and the W_tail.HT/W_tail.VT struct-field access this
%                class reads are F16WeightsL2-specific -- W_strake is not
%                part of ANY abstract weights contract (it is an F-16-only
%                LERX term), so a WeightsModelL2 guard would not actually
%                guarantee the members this class reads. The
%                component_x_stations grouping itself is explicitly built
%                "from THIS framework's own WeightsL2/WeightsL3 groups"
%                (docs/subplans/10_stability_control.md "Component-x-location
%                buildup"), i.e. tied to this exact concrete class's shape,
%                not a generic weights contract -- matching the launch
%                instruction's own "Inject F16WeightsL2" (concrete) wording.
%   ============================================================================
%
%   x_cg MUST PROPAGATE NaN GRACEFULLY for the 'fuel' group: W_energy is a
%   mission-analysis STATE that reads NaN until the mission/sizing loop sets
%   it (WeightsBase.m contract) -- reading it here is a PLAIN property read
%   (never a computed/guarded getter), so it simply returns NaN, and ordinary
%   IEEE arithmetic inside SandCL2.weighted_cg propagates that NaN into x_cg
%   with no error. By contrast, several OTHER groups (landing_gear,
%   subsystems_lump) genuinely need obj.weights.W_TO to already be set (they
%   are W_TO-scaled fractions guarded by F16WeightsL2.requireWTO) -- reading
%   x_cg before a candidate W_TO exists errors loudly through THAT existing
%   guard, which is correct and expected (you cannot compute a CG without a
%   candidate gross weight), and is a DIFFERENT situation from the fuel-NaN
%   case this class is asked to handle gracefully.
%
%   SOURCES:
%     [readme_bsc.md] VnV/BrandtF16A/readme_bsc.md "CG closure" -- the
%       weighted-average CG identity this class's one formula implements.
%     Component weight/x-station data: docs/subplans/10_stability_control.md
%       "Component-x-location buildup" (re-aggregated from
%       temp_Casey/inputs/F-16A Block 50.xlsx's "Stability&Control" sheet,
%       22 rows, into this framework's own 10 WeightsL2/L3 groups).
%
%   Companion doc: examples/F16A/F16SandCL2.md

    % ======================================================================= %
    % Fixed group order -- matches f16a_L2.json
    % .stability_control.component_x_stations.groups' own key order exactly
    % (Casey, 2026-08-03). Hardcoded here rather than relying on JSON
    % object-key iteration order so the mapping in group_weight is always
    % unambiguous and order-stable.
    % ======================================================================= %
    properties (Constant)
        COMPONENT_GROUP_NAMES = {'wing', 'horizontal_tail', 'vertical_tail', ...
            'fuselage', 'landing_gear', 'installed_engine', 'subsystems_lump', ...
            'strake', 'payload', 'fuel'}
    end

    % ======================================================================= %
    % INPUTS -- set once by the constructor. component_cg_x_ft is static
    % spec data (an engineering estimate, fidelity-independent between L2/L3
    % per the JSON's own note) -- fine to read once, unlike the LIVE weights.
    % ======================================================================= %
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
        %   required injected F16WeightsL2 object. NO silent default on
        %   either argument -- a defaulted injection would silently re-freeze
        %   weights data, the defect class this framework's DI convention
        %   removes elsewhere (F16GeomL2.m / F16WeightsL2.m).
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

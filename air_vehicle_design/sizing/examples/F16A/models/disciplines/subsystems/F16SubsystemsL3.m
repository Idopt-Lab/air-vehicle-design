classdef F16SubsystemsL3 < SubsystemsModelL3
%F16SUBSYSTEMSL3  F-16A Block 10/15 Level-3 subsystems student class.
%
%   Inherits from SubsystemsModelL3 (abstract enforcer). Every abstract
%   method is satisfied by a single delegation line to SubsystemsL3 statics
%   -- no equations are duplicated here.
%
%   Same equations as F16SubsystemsL2 (Raymer Eq. 7.14 fuselage volume,
%   Roskam Eq. 6.2/6.3 wing volume, Nicolai fuel/avionics tables); the ONLY
%   difference is that the fuselage raw-volume term is fed A_top/A_side from
%   the injected L3 geometry's frame-integrated station table instead of
%   L2's envelope-ellipse approximation (Fidelity split). SubsystemsL3
%   reuses SubsystemsL2's statics directly for every level-agnostic equation
%   -- see SubsystemsL3.m's header.
%
%   The "landing-gear bay volume not auto-summed" note is identical to
%   F16SubsystemsL2 -- see that class's header for the full rationale
%   (item 11's citation gap; Objectives §3 is aspirational).
%
%   DEPENDENCY INJECTION -- identical shape to F16SubsystemsL2, but geom is
%   typed to GeometryModelL3 (guarded at the L3 ENFORCER), and
%   fuel_weight_source is typically an F16WeightsL3 instance (also a
%   WeightsBase). See F16SubsystemsL2.m for the full fuel_weight_source
%   rationale (one injected object serves both the fuel-sufficiency check
%   and the avionics W_empty term).
%
%   CONSTRUCTOR: F16SubsystemsL3(json_path, geom, fuel_weight_source). All
%   three REQUIRED, no silent default.
%
%   SOURCES: same as F16SubsystemsL2 -- see that class's header.
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL3.md

    % INPUTS (3) + 2 injected objects -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16SubsystemsL3.md §2.
    properties
        fuel_type                 = 'JP-8'                              % [f16a_L3.json .subsystems.fuel.fuel_type]
        packaging_factor_category = 'Integral tank — shallow fuselage'   % [f16a_L3.json .subsystems.fuel.packaging_factor_category]
        avionics_table_row        = 'Fighters'                          % [f16a_L3.json .subsystems.avionics.aircraft_category_table_row]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL3 -- supplies fuselage/wing geometry for the volume terms
        fuel_weight_source  % (1,1) WeightsBase -- supplies W_energy (fuel sufficiency check) and OEW/W_TO (avionics W_empty)
    end

    % AVIONICS COMPONENTS, read from f16a_L3.json
    % .subsystems.unclassified_avionics_equipment.components.
    properties
        avionics_components = {}
    end

    properties (Dependent)
        avionics_weight_fraction
        avionics_density
        avionics_weight
        avionics_volume
        fuel_density
        fuselage_usable_fuel_volume
        wing_fuel_volume
        fuel_volume  % = L3's own fuselage_usable_fuel_volume + wing_fuel_volume [SubsystemsBase.m]
    end

    methods

        function obj = F16SubsystemsL3(json_path, geom, fuel_weight_source)
        %F16SUBSYSTEMSL3  Construct from a required unified L3 input JSON
        %   path (f16a_spec_path(3)), a required injected L3 geometry
        %   object, and a required injected weights object. NO silent
        %   default on any argument.
            arguments
                json_path                {mustBeTextScalar, mustBeNonzeroLengthText}
                geom               (1,1) GeometryModelL3
                fuel_weight_source (1,1) WeightsBase
            end
            J = jsondecode(fileread(json_path));

            obj.geom               = geom;
            obj.fuel_weight_source = fuel_weight_source;

            obj.fuel_type                 = char(J.subsystems.fuel.fuel_type);
            obj.packaging_factor_category = char(J.subsystems.fuel.packaging_factor_category);
            obj.avionics_table_row        = char(J.subsystems.avionics.aircraft_category_table_row);
            obj.avionics_components       = J.subsystems.unclassified_avionics_equipment.components;   % Mod (09/11/2026) (Claude)
        end

        % ================================================================== %
        % Methods required by the abstract contract 
        % ================================================================== %

        function val = battery_volume(obj, E_required_kWh)
            val = SubsystemsL3.battery_volume(obj, E_required_kWh);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
            val = SubsystemsL3.fuel_volume_from_weight(obj, fuel_weight_lb);
        end

        function result = fuel_volume_check(obj)
            result = SubsystemsL3.fuel_volume_check(obj);
        end

        % Estimate the total weight of avionics equipment onboard.
        function [val, parts] = get_avionics_weight_component_buildup(obj)
            C  = obj.avionics_components;
            nm = strings(numel(C), 1);
            W  = nan(numel(C), 1);
            V  = W;
            Pw = W;
            for i = 1:numel(C)
                nm(i) = string(C{i}.name);
                [W(i), V(i), Pw(i)] = F16SubsystemsL3.box(C{i});
            end
            parts = table(categorical(nm, nm, 'Ordinal', true), W, V, Pw, ...
                'VariableNames', {'Component', 'Weight_lbf', 'Volume_ft3', 'Power_W'});
            val = sum(W(isfinite(W)));
        end

        function val = get_internal_volume(obj)
        %GET_INTERNAL_VOLUME  Fuselage internal volume [ft^3] from the injected
        %   geometry's station table. The table is stored normalized, so it is
        %   rescaled by the fuselage envelope first.
            [frame_x, frame_w, frame_h] = GeomL3.denormalize_frames( ...
                obj.geom.frames_normalized, obj.geom.L_fus, ...
                obj.geom.W_max_fuselage, obj.geom.H_max_fuselage);

            val = SubsystemsL3.compute_volume_from_control_stations( ...
                      frame_x, frame_w, frame_h);
        end

        % ================================================================== %
        % DERIVED-property getters required by the abstract contract
        % ================================================================== %

    end

    methods (Static, Access = private)

        function [w, v, p] = box(c)
        %BOX  Weight [lbf], volume [ft^3] and power [W] for one box.
        %   Whichever of the three the JSON gives drives the other two
        %   through Table 8.8, which inverts in every direction. A sourced
        %   figure is never overwritten by an estimate. Without a category
        %   the box keeps only what the JSON gives it. A "a + b" category is
        %   one box holding both functions, so its known quantity splits
        %   evenly between the two rows. Mod (09/11/2026) (Claude)
            w = NaN; v = NaN; p = NaN;
            if isfinite(c.weight_lb),  w = c.weight_lb;  end
            if isfinite(c.volume_ft3), v = c.volume_ft3; end
            if isfinite(c.power_W),    p = c.power_W;    end
            if isempty(c.category), return; end

            rows = strtrim(split(string(c.category), '+'));
            n    = numel(rows);
            if     isfinite(w), src = 'w'; x = w / n;
            elseif isfinite(v), src = 'v'; x = v / n;
            elseif isfinite(p), src = 'p'; x = p / n;
            else,  return
            end

            wt = 0; vol = 0; pw = 0;
            for k = 1:n
                r = char(rows(k));
                switch src
                    case 'w', wk = x;
                    case 'v', wk = SubsystemsL3.compute_avionics_weight_statistical(r, [], x);
                    case 'p', wk = SubsystemsL3.compute_avionics_weight_statistical(r, x, []);
                end
                wt  = wt  + wk;
                vol = vol + F16SubsystemsL3.attempt(@() SubsystemsL3.compute_avionics_volume_statistical(r, [], wk));
                pw  = pw  + F16SubsystemsL3.attempt(@() SubsystemsL3.compute_avionics_power_statistical(r, wk, []));
            end
            if ~isfinite(w), w = wt;  end
            if ~isfinite(v), v = vol; end
            if ~isfinite(p), p = pw;  end
        end

        function y = attempt(f)
        %ATTEMPT  Evaluate f, or NaN where the fit has no valid inverse
        %   (a linear row below its intercept).
            try
                y = f();
            catch
                y = NaN;
            end
        end

    end

end

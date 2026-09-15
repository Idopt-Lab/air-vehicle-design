classdef F16SubsystemsL3 < SubsystemsModelL3
%F16SUBSYSTEMSL3  F-16A Block 10/15 Level-3 subsystems student class.
%
%   Inherits from SubsystemsModelL3. The fuselage volume comes from the
%   injected geometry's station table. The avionics group is built one box at
%   a time from the input JSON.
%
%   Properties:
%       fuel_type (char): fuel selecting the density table row.
%       packaging_factor_category (char): tank type. Unused.
%       avionics_table_row (char): Raymer Table 11.6 row.
%       fuselage_packaging_factor_category (char): tank type selecting the
%           fuselage packaging factor.
%       wing_packaging_factor_category (char): tank type. Unused.
%       geom (GeometryModelL3): injected. Supplies frames_normalized, L_fus,
%           W_max_fuselage, H_max_fuselage, S_ref, b_wing, tc_r_wing,
%           tc_t_wing, lambda_wing.
%       fuel_weight_source (WeightsBase): injected. Supplies W_energy and
%           OEW(W_TO).
%       avionics_components (cell): one struct per avionics box, read from the
%           input JSON.
%
%   Properties (Dependent):
%       avionics_weight_fraction (double): fraction of W_empty.
%       avionics_density (double): avionics weight / avionics volume (lb/ft^3).
%       avionics_weight (double): avionics weight (lbf).
%       total_avionics_volume_occupied (double): avionics volume (ft^3).
%       fuel_density (double): fuel density (lb/ft^3).
%       fuselage_usable_fuel_volume (double): fuselage volume x packaging
%           factor (ft^3).
%       wing_fuel_volume (double): wing fuel volume (ft^3).
%       total_fuel_volume_occupied (double): volume the fuel occupies (ft^3).
%       total_design_volume (double): wing fuel volume + fuselage volume (ft^3).
%
%   Methods:
%       get_fuselage_volume: fuselage internal volume (ft^3) from the station
%           table.
%       get_fuselage_fuel_volume_available: fuselage volume x packaging factor
%           (ft^3).
%       get_wing_fuel_volume_available: wing fuel volume (ft^3).
%       get_total_fuel_volume_available: wing + fuselage usable fuel volume (ft^3).
%       get_total_fuel_volume_occupied: fuel weight / density (ft^3).
%       get_design_total_volume: wing fuel volume + fuselage volume (ft^3).
%       get_avionics_weight_component_buildup: avionics weight (lbf) and the
%           per-box table.
%       get_total_avionics_volume_component_buildup: avionics volume (ft^3)
%           and the per-box table.
%       fuel_volume_from_weight: BROKEN. Calls a SubsystemsL3 static that does
%           not exist.
%       fuel_volume_check: BROKEN. Passes the design object to a two-scalar
%           static.
%
%   Constructor: F16SubsystemsL3(json_path, geom, fuel_weight_source). All
%   three required.
%
%   Landing-gear bay volume is NOT summed into any volume here.
%
%   Sources: Raymer 6th ed. Fig. 7.38 p.207, Table 11.6 p.375; Roskam Airplane
%   Design Part II Ch.6 Eq. 6.2/6.3 p.153; Nicolai & Carichner Ch.8 p.210,
%   Table 8.8 p.212.
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL3.md

    % INPUTS (3) + 2 injected objects -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16SubsystemsL3.md §2.
    properties
        fuel_type                 = 'JP-8'                              % [f16a_L3.json .subsystems.fuel.fuel_type]
        packaging_factor_category = 'Integral tank — shallow fuselage'   % [f16a_L3.json .subsystems.fuel.packaging_factor_category]
        avionics_table_row        = 'Fighters'                          % [f16a_L3.json .subsystems.avionics.aircraft_category_table_row]
        fuselage_packaging_factor_category = 'Integral tank — shallow fuselage'
        wing_packaging_factor_category = 'Integral tank — wing'
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
        total_avionics_volume_occupied
        fuel_density
        fuselage_usable_fuel_volume
        wing_fuel_volume
        total_fuel_volume_occupied  % = L3's own fuselage_usable_fuel_volume + wing_fuel_volume [SubsystemsBase.m]
        total_design_volume
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

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
            val = SubsystemsL3.fuel_volume_from_weight(obj, fuel_weight_lb);
        end

        function result = fuel_volume_check(obj)
            result = SubsystemsL3.fuel_volume_check(obj);
        end

        function val = get_wing_fuel_volume_available(obj)
            val = SubsystemsL2.compute_wing_fuel_volume_roskam(obj.geom.S_ref, ...
                      obj.geom.b_wing, obj.geom.tc_r_wing, obj.geom.tc_t_wing, ...
                      obj.geom.lambda_wing);
        end

        function val = get_total_fuel_volume_available(obj)
            fuel_vol_wing = obj.get_wing_fuel_volume_available();
            fuel_vol_fuselage = obj.get_fuselage_fuel_volume_available();
            
            % Sum the components
            val = fuel_vol_wing + fuel_vol_fuselage;
        end

        function val = get_fuselage_fuel_volume_available(obj)
            vol_fuselage = obj.get_fuselage_volume();
            pf = SubsystemsL2.lookup_packaging_factor_nicolai(obj.fuselage_packaging_factor_category);
            fuel_vol_fuselage = vol_fuselage*pf;
            val = fuel_vol_fuselage;
        end

        function val = get_design_total_volume(obj)
            vol_wing = obj.get_wing_fuel_volume_available(); % N.B: This is the fuel volume, which is closer to the wing's actual volume than guessing "0".
            vol_fuselage = obj.get_fuselage_volume();
            
            % Sum the components
            val = vol_wing + vol_fuselage;
        end

        % Estimate the total weight of avionics equipment onboard.
        function [val, parts] = get_avionics_weight_component_buildup(obj)
            parts = obj.avionics_parts();
            val   = sum(parts.Weight_lbf(isfinite(parts.Weight_lbf)));
        end

        % Estimate the total volume of avionics equipment onboard.
        function [val, parts] = get_total_avionics_volume_component_buildup(obj)
            parts = obj.avionics_parts();
            val   = sum(parts.Volume_ft3(isfinite(parts.Volume_ft3)));
        end

        function val = get_total_fuel_volume_occupied(obj, fuel_weight_lb)
            val = fuel_weight_lb / obj.fuel_density;
        end

        function val = get_fuselage_volume(obj)
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

        function val = get.avionics_weight_fraction(obj)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            val   = mean(range);
        end

        function val = get.avionics_density(obj)
        % L3 weighs real boxes, so the density is an OUTPUT of the buildup.
        % It is not read from a table. Mod (09/15/2026) (Claude)
            val = obj.avionics_weight / obj.total_avionics_volume_occupied;
        end

        function val = get.avionics_weight(obj)
            val = obj.get_avionics_weight_component_buildup();
        end

        function val = get.total_avionics_volume_occupied(obj)
            val = obj.get_total_avionics_volume_component_buildup();
        end

        function val = get.fuel_density(obj)
            val = SubsystemsBase.lookup_fuel_density_lb_per_ft_3(obj.fuel_type);
        end

        function val = get.fuselage_usable_fuel_volume(obj)
            val = obj.get_fuselage_fuel_volume_available();
        end

        function val = get.wing_fuel_volume(obj)
            val = obj.get_wing_fuel_volume_available();
        end

        function val = get.total_fuel_volume_occupied(obj)
            val = obj.get_total_fuel_volume_occupied(obj.fuel_weight_source.W_energy);
        end

        function val = get.total_design_volume(obj)
            val = obj.get_design_total_volume();
        end

    end

    methods (Access = private)

        function parts = avionics_parts(obj)
        %AVIONICS_PARTS  One row per avionics box: weight [lbf], volume [ft^3]
        %   and power [W]. A box resolves its missing quantities through
        %   F16SubsystemsL3.box. Mod (09/15/2026) (Claude)
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
        end

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

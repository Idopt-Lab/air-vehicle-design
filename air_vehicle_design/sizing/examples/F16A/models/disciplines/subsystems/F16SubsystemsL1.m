classdef F16SubsystemsL1 < SubsystemsModelL1
%F16SUBSYSTEMSL1  F-16A Block 10/15 Level-1 subsystems student class.
%
%   Inherits from SubsystemsModelL1. L1 is tabulation only: no geometry, so
%   no available volume and no packaging factor.
%
%   Properties:
%       fuel_type (char): energy medium, hydrocarbon or battery.
%       fuel_name (char): fuel or battery chemistry selecting the table row.
%       avionics_table_row (char): Raymer Table 11.6 row.
%       fuel_weight_source (WeightsBase): injected, OPTIONAL. Supplies
%           W_energy and OEW(W_TO).
%
%   Properties (Dependent):
%       avionics_weight_fraction (double): fraction of W_empty.
%       avionics_density (double): avionics packing density (lb/ft^3).
%       fuel_density (double): fuel density (lb/ft^3).
%       total_fuel_volume_occupied (double): volume the fuel occupies (ft^3).
%           NaN without the injected collaborator.
%       total_avionics_volume_occupied (double): avionics volume (ft^3).
%           NaN without the injected collaborator.
%
%   Methods:
%       get_avionics_weight_fraction: fraction of W_empty for the table row.
%       get_avionics_weight_categorical: avionics weight (lbf) from W_empty.
%       get_avionics_volume_categorical: avionics volume (ft^3) from W_empty.
%       get_total_fuel_volume_occupied: fuel weight / density (ft^3).
%       fuel_volume_check: required against available fuel volume, returns a
%           struct. Available is 0 at L1.
%
%   Constructor: F16SubsystemsL1(json_path, fuel_weight_source). The path is
%   required; the collaborator is not.
%
%   Sources: Nicolai & Carichner Table 8.6 p.210; Raymer 6th ed. Table 11.6
%   p.375 and the density range in the paragraph before it.
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL1.md

    % INPUTS (2) -- plain mutable properties, set once by the constructor.
    % Authoritative table with all citations: F16SubsystemsL1.md §2.
    properties
        fuel_type = "hydrocarbon"
        fuel_name          = 'JP-8'      % [Nicolai & Carichner Table 8.6; f16a_L1.json .subsystems.fuel.fuel_type]
        avionics_table_row = 'Fighters'  % selects SubsystemsL1.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6; f16a_L1.json .subsystems.avionics.aircraft_category_table_row]

        % OPTIONAL injected collaborator. Supplies W_energy and OEW(W_TO) to
        % the two zero-arg volume getters. Without it they read NaN; the
        % W_empty-taking methods work either way.
        fuel_weight_source = []   % (1,1) WeightsBase
    end

    % DERIVED (5) -- zero-extra-arg quantities that read only the inputs above.
    % Dependent getters, recomputed live on every read. SubsystemsBase declares
    % these as abstract PROPERTIES, not abstract methods.
    % fuselage_raw_volume/fuel_volume are honestly 0 at L1 (no fuselage/fuel-bay
    % geometry at this tier).
    properties (Dependent)
        avionics_weight_fraction
        avionics_density
        fuel_density
        total_fuel_volume_occupied
        total_avionics_volume_occupied
    end

    methods

        function obj = F16SubsystemsL1(json_path, fuel_weight_source)
        %F16SUBSYSTEMSL1  Construct from a required unified L1 input JSON
        %   path (f16a_spec_path(1)); reads its .subsystems block. NO silent
        %   default: the path must be supplied.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                fuel_weight_source = []
            end
            J = jsondecode(fileread(json_path));
            obj.fuel_name          = char(J.subsystems.fuel.fuel_type);                    % [f16a_L1.json .subsystems.fuel.fuel_type]
            obj.avionics_table_row = char(J.subsystems.avionics.aircraft_category_table_row); % [f16a_L1.json .subsystems.avionics.aircraft_category_table_row]
            obj.fuel_weight_source = fuel_weight_source;
        end

        % ================================================================== %
        % Methods required by the abstract contract
        % ================================================================== %

        function val = get_avionics_weight_fraction(obj)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            val = mean(range);
        end

        function val = get_avionics_weight_categorical(obj, W_empty)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            avi_WF = mean(range);
            val = SubsystemsL1.compute_avionics_weight(avi_WF, W_empty);
        end

        function vol_avionics = get_avionics_volume_categorical(obj, W_empty)
            W_avionics = obj.get_avionics_weight_categorical(W_empty);
            vol_avionics = SubsystemsL1.compute_avionics_volume(W_avionics, SubsystemsL1.AVIONICS_DENSITY);
        end

        function val = get_total_fuel_volume_occupied(obj, fuel_weight_lb)
        %FUEL_VOLUME_FROM_WEIGHT  No packaging factor: L1 has no raw volume.
            val = fuel_weight_lb / obj.fuel_density;
        end

        function result = fuel_volume_check(obj, required_weight_lb)
        %FUEL_VOLUME_CHECK  Available is honestly 0: L1 has no fuel-bay geometry.
            required_vol = obj.get_total_fuel_volume_occupied(required_weight_lb);
            result = struct('available_vol_ft3', 0, ...
                            'required_vol_ft3',  required_vol, ...
                            'sufficient',        required_vol <= 0);
        end

        % ================================================================== %
        % DERIVED-property getters required by the abstract contract --
        % recomputed live on every read.
        % Mod (09/07/2026) (Claude)
        % ================================================================== %

        function val = get.avionics_weight_fraction(obj)
            val = mean(SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row));
        end

        function val = get.avionics_density(obj) %#ok<MANU>
            val = SubsystemsL1.AVIONICS_DENSITY;
        end

        function val = get.fuel_density(obj)
            val = SubsystemsBase.lookup_fuel_density_lb_per_ft_3(obj.fuel_type, obj.fuel_name);
        end

        % Both need a weight, so they read the injected collaborator. NaN
        % when nothing is injected; the W_empty-taking methods still work.

        function val = get.total_fuel_volume_occupied(obj)
            if isempty(obj.fuel_weight_source), val = NaN; return; end
            val = obj.get_total_fuel_volume_occupied(obj.fuel_weight_source.W_energy);
        end

        function val = get.total_avionics_volume_occupied(obj)
            if isempty(obj.fuel_weight_source), val = NaN; return; end
            ws  = obj.fuel_weight_source;
            val = obj.get_avionics_volume_categorical(ws.get_OEW(ws.W_TO));
        end

    end

end

classdef F16SubsystemsL1 < SubsystemsModelL1
%F16SUBSYSTEMSL1  F-16A Block 10/15 Level-1 subsystems student class.
%
%   Inherits from SubsystemsModelL1 (abstract enforcer). Every abstract
%   method is satisfied by a single delegation line to SubsystemsL1 statics
%   -- no equations are duplicated here.
%
%   L1 is tabulation-only: fuel-type density [Nicolai & Carichner Table 8.6]
%   and avionics weight-fraction/density [Raymer 6th ed. Table 11.6 + its
%   own following-paragraph density-range average, ~37.5 lb/ft^3]. No
%   geometry, no injected collaborators -- methods that need an external
%   weight (W_empty, a required fuel weight) take it as an explicit
%   argument, exactly as F16WeightsL1.get_OEW(obj, W_TO) does.
%
%   No fuel-tank packaging factor is applied here (not usable at L1 -- no
%   geometric raw volume exists yet) and there is no landing-gear
%   counterpart at this tier at all.
%
%   CONSTRUCTOR: F16SubsystemsL1(json_path). Reads the .subsystems block of
%   a required unified L1 input JSON (f16a_spec_path(1)). NO silent default.
%
%   SOURCES:
%     [Nicolai] Nicolai & Carichner, "Fundamentals of Aircraft and Airship
%               Design," Ch.8, p.210 (fuel density Table 8.6; avionics
%               density Sec.8.1.11 -- not used at L1, see avionics_density).
%     [Raymer]  D.P. Raymer, Aircraft Design 6th ed., Table 11.6, p.375
%               (avionics weight fraction + following-paragraph density range).
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL1.md

    % INPUTS (2) -- plain mutable properties, set once by the constructor.
    % Authoritative table with all citations: F16SubsystemsL1.md §2.
    properties
        fuel_type          = 'JP-8'      % selects SubsystemsL1.lookup_fuel_density [Nicolai & Carichner Table 8.6; f16a_L1.json .subsystems.fuel.fuel_type]
        avionics_table_row = 'Fighters'  % selects SubsystemsL1.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6; f16a_L1.json .subsystems.avionics.aircraft_category_table_row]
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
        fuselage_raw_volume  % honestly 0 at L1 -- SubsystemsBase.m header note
        fuel_volume          % honestly 0 at L1 -- SubsystemsBase.m header note
    end

    methods

        function obj = F16SubsystemsL1(json_path)
        %F16SUBSYSTEMSL1  Construct from a required unified L1 input JSON
        %   path (f16a_spec_path(1)); reads its .subsystems block. NO silent
        %   default: the path must be supplied.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            obj.fuel_type          = char(J.subsystems.fuel.fuel_type);                    % [f16a_L1.json .subsystems.fuel.fuel_type]
            obj.avionics_table_row = char(J.subsystems.avionics.aircraft_category_table_row); % [f16a_L1.json .subsystems.avionics.aircraft_category_table_row]
        end

        % ================================================================== %
        % Methods required by the abstract contract
        % ================================================================== %

        function val = get_avionics_weight_categorical(obj, W_empty)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            avi_WF = mean(range);
            val = SubsystemsL1.compute_avionics_weight(avi_WF, W_empty);
        end

        function vol_avionics = get_avionics_volume_categorical(obj, W_empty)
            W_avionics = obj.get_avionics_weight_categorical(W_empty);
            vol_avionics = SubsystemsBase.compute_avionics_volume(W_avionics, SubsystemsL1.AVIONICS_DENSITY);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
        %FUEL_VOLUME_FROM_WEIGHT  No packaging factor: L1 has no raw volume.
            fuel_density = SubsystemsBase.lookup_fuel_density_lb_per_ft_3(obj.fuel_type);
            val = fuel_weight_lb/fuel_density;
        end

        function val = get_internal_volume(obj, W_empty)
        %GET_INTERNAL_VOLUME  Avionics volume only: no fuel or gear bay at L1.
            val = obj.get_avionics_volume_categorical(W_empty);
        end

        function result = fuel_volume_check(obj, required_weight_lb)
        %FUEL_VOLUME_CHECK  Available is honestly 0: L1 has no fuel-bay geometry.
            required_vol = obj.fuel_volume_from_weight(required_weight_lb);
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

        function val = get.avionics_density(obj)
            val = SubsystemsL1.AVIONICS_DENSITY;
        end

        function val = get.fuel_density(obj)
            val = SubsystemsBase.lookup_fuel_density_lb_per_ft_3(obj.fuel_type);
        end

        function val = get.fuselage_raw_volume(obj) %#ok<MANU>
            val = 0;   % L1 has no fuselage geometry
        end

        function val = get.fuel_volume(obj) %#ok<MANU>
            val = 0;   % L1 has no fuel-bay geometry
        end

    end

end

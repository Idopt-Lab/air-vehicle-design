classdef (Abstract) SubsystemsBase < handle
%SUBSYSTEMSBASE  Tier-1 abstract enforcer for all subsystems discipline classes.
%
%   Properties (Abstract):
%       total_fuel_volume_occupied (double): literally the volume occupied by fuel (ft^3) (usually computed from mission analysis)
%       total_avionics_volume_occupied (double): total volume occupied by the design's avionics (ft^3)
%
%   Methods (Abstract):
%       get_total_avionics_volume_occupied: User must obtain the total volume occupied by the design avionics.
%       get_total_fuel_volume_occupied: User must obtain the total volume occupied by the design's fuel weight.
%
%   Methods (Static):
%       lookup_fuel_density_lb_per_ft_3: returns the density of a given liquid jet fuel, in lb/ft^3.
%       lookup_fuel_density_lb_per_gal: returns the density of a given liquid jet fuel, in lb/gal (for convenience).
%
%   Companion doc: src/base/SubsystemsBase.md.
%   History and rationale: docs/decision_log.md.

    properties (Abstract)
        %FUEL_VOLUME_OCCUPIED  Total volume occupied by chosen energy storage medium [ft^3]
        % Internal + external stores.
        total_fuel_volume_occupied

        %TOTAL_AVIONICS_VOLUME_OCCUPIED
        % The total volume occupied by avionics equipment [ft^3]
        total_avionics_volume_occupied
    end

    methods (Abstract)
        %GET_TOTAL_AVIONICS_VOLUME_OCCUPIED
        % Obtain the total volume taken up by avionics equipment [ft^3]
        val = get_total_avionics_volume_occupied(obj)

        % GET_TOTAL_FUEL_VOLUME_OCCUPIED
        % This should be agnostic enough to include both hydrocarbon and electric aircraft,
        % while allowing for both designs to use this function.
        val = get_total_fuel_volume_occupied(fuel_density, energy_medium_weight)
    end

    methods (Static)

        function d = lookup_fuel_density_lb_per_ft_3(fuel_type)
        %LOOKUP_FUEL_DENSITY  Fuel density [lb/ft^3] by type.
        %   [Nicolai & Carichner, Table 8.6, p.210]
            switch fuel_type
                case 'JP-4',          d = 48.6;
                case 'JP-5',          d = 51.1;
                case 'JP-8',          d = 50.0;
                case 'Aviation gas',  d = 44.9;
                case 'BATTERY'
                otherwise
                    error('SubsystemsL1:unknownFuelType', ...
                        ['Unknown fuel type "%s". Known types (Nicolai & ' ...
                         'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                        fuel_type);
            end
        end

        function d = lookup_fuel_density_lb_per_gal(fuel_type)
        %LOOKUP_FUEL_DENSITY_LB_PER_GAL  Fuel density [lb/gal] by type
        %  [Nicolai & Carichner, Table 8.6, p.210]
            switch fuel_type
                case 'JP-4',          d = 6.5;
                case 'JP-5',          d = 6.8;
                case 'JP-8',          d = 6.7;
                case 'Aviation gas',  d = 6.0;
                case 'BATTERY'
                otherwise
                    error('SubsystemsL1:unknownFuelType', ...
                        ['Unknown fuel type "%s". Known types (Nicolai & ' ...
                         'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                        fuel_type);
            end
        end


    end
end

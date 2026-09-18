classdef (Abstract) SubsystemsBase < handle
%SUBSYSTEMSBASE  Tier-1 abstract enforcer for all subsystems discipline classes.
%
%   Properties (Abstract):
%       fuel_type (char): energy medium, hydrocarbon or battery.
%       fuel_name (char): fuel or battery chemistry selecting the table row.
%       total_fuel_volume_occupied (double): volume the energy medium occupies (ft^3).
%       total_avionics_volume_occupied (double): volume the avionics occupy (ft^3).
%
%   Methods (Abstract):
%       get_total_avionics_volume_occupied: user must obtain the avionics volume (ft^3).
%       get_total_fuel_volume_occupied: user must obtain the energy-medium volume (ft^3).
%
%   Methods (Static):
%       lookup_fuel_density_lb_per_ft_3: fuel density (lb/ft^3), or battery
%           energy density (Wh/ft^3), by type and name.
%       lookup_fuel_density_lb_per_gal: the same two tables per US gallon.
%
%   Both lookups return a MASS density for hydrocarbon and an ENERGY density
%   for battery. See SubsystemsBase.md.
%
%   Sources: Nicolai & Carichner Table 8.6 p.210 (fuel); Raymer 6th ed.
%   Table 20.1 p.748 (battery).
%
%   Companion doc: src/base/SubsystemsBase.md.
%   History and rationale: docs/decision_log.md.

    properties (Abstract)
        fuel_type % Type of fuel: hydrocarbon or electric
        fuel_name % Name of fuel: if hydrocarbon, give the name of the gas. If electric, state the battery chemistry.

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

        function d = lookup_fuel_density_lb_per_ft_3(fuel_type, fuel_name)
        %LOOKUP_FUEL_DENSITY  Energy-medium density by type and name.
        %   hydrocarbon -> mass density [lb/ft^3]
        %       [Nicolai & Carichner Table 8.6, p.210]
        %   battery -> volumetric energy density [Wh/ft^3]
        %       [Raymer 6th ed. Table 20.1, p.748]
        %   The two branches return different units. See SubsystemsBase.md.
            if fuel_type == "hydrocarbon"
                switch fuel_name
                    case 'JP-4',          d = 48.6;
                    case 'JP-5',          d = 51.1;
                    case 'JP-8',          d = 50.0;
                    case 'Aviation gas',  d = 44.9;
                    otherwise
                        error('SubsystemsL1:unknownFuelName', ...
                            ['Unknown fuel type "%s". Known names (Nicolai & ' ...
                            'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                            fuel_type);
                end
            elseif fuel_type == "battery"
                % Table 20.1 "Energy Density" column, Wh/L, all 20 chemistries.
                % Source: Table 20.1, Raymer 6th edition, page 748.
                switch fuel_name
                    case 'Lead-acid',        d = 100;
                    case 'Alkaline',         d = 300;
                    case 'NiFe',             d = 30;
                    case 'NiCd',             d = 150;
                    case 'NiH',              d = 60;
                    case 'NiMH',             d = 300;
                    case 'NiZn',             d = 280;
                    case 'Li-ion',           d = mean([250, 700]);
                    case 'Li-ion Polymer',   d = mean([250, 730]);
                    case 'LiFePO4',          d = 170;
                    case 'LiNiMnCoO2 (NMC)', d = 500;
                    case 'Li-S',             d = 250;
                    case 'Licerion (US)',    d = 1000;
                    case 'Li-titanate',      d = 170;
                    case 'Li-air',           d = 200;
                    case 'Na-ion',           d = 50;
                    case 'Molten salt',      d = 290;
                    case 'Silver Zinc',      d = 700;
                    case {'LiCoO2', 'LiMn2O4'}
                        error('SubsystemsBase:batteryEnergyDensityNotPrinted', ...
                            ['Raymer Table 20.1 prints no energy density for "%s", ' ...
                             'only its specific energy in Wh/kg.'], fuel_name);
                    otherwise
                        error('SubsystemsBase:unknownBatteryChemistry', ...
                            ['Unknown battery chemistry "%s". Known chemistries ' ...
                             '(Raymer 6th ed. Table 20.1): Lead-acid, Alkaline, ' ...
                             'NiFe, NiCd, NiH, NiMH, NiZn, Li-ion, Li-ion Polymer, ' ...
                             'LiCoO2, LiFePO4, LiMn2O4, LiNiMnCoO2 (NMC), Li-S, ' ...
                             'Licerion (US), Li-titanate, Li-air, Na-ion, ' ...
                             'Molten salt, Silver Zinc.'], fuel_name);
                end
                d = d * 28.316846592;   % Wh/L -> Wh/ft^3. 1 ft^3 = 28.316846592 L.
            else
                error('SubsystemsBase:unknownFuelType', ...
                    'Unknown fuel type "%s". Known types: hydrocarbon, battery.', ...
                    fuel_type);
            end
        end
    

        function d = lookup_fuel_density_lb_per_gal(fuel_type, fuel_name)
        %LOOKUP_FUEL_DENSITY_LB_PER_GAL  Energy-medium density by type and name.
        %   hydrocarbon -> mass density [lb/gal]
        %       [Nicolai & Carichner Table 8.6, p.210]
        %   battery -> volumetric energy density [Wh/gal]
        %       [Raymer 6th ed. Table 20.1, p.748]
        %   The two branches return different units. See SubsystemsBase.md.
            if fuel_type == "hydrocarbon"
                switch fuel_name
                    case 'JP-4',          d = 6.5;
                    case 'JP-5',          d = 6.8;
                    case 'JP-8',          d = 6.7;
                    case 'Aviation gas',  d = 6.0;
                    otherwise
                        error('SubsystemsL1:unknownFuelName', ...
                            ['Unknown fuel type "%s". Known names (Nicolai & ' ...
                            'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                            fuel_name);
                end
            elseif fuel_type == "battery"
                % Table 20.1 "Energy Density" column, Wh/L, all 20 chemistries.
                % Source: Table 20.1, Raymer 6th edition, page 748.
                switch fuel_name
                    case 'Lead-acid',        d = 100;
                    case 'Alkaline',         d = 300;
                    case 'NiFe',             d = 30;
                    case 'NiCd',             d = 150;
                    case 'NiH',              d = 60;
                    case 'NiMH',             d = 300;
                    case 'NiZn',             d = 280;
                    case 'Li-ion',           d = mean([250, 700]);
                    case 'Li-ion Polymer',   d = mean([250, 730]);
                    case 'LiFePO4',          d = 170;
                    case 'LiNiMnCoO2 (NMC)', d = 500;
                    case 'Li-S',             d = 250;
                    case 'Licerion (US)',    d = 1000;
                    case 'Li-titanate',      d = 170;
                    case 'Li-air',           d = 200;
                    case 'Na-ion',           d = 50;
                    case 'Molten salt',      d = 290;
                    case 'Silver Zinc',      d = 700;
                    case {'LiCoO2', 'LiMn2O4'}
                        error('SubsystemsBase:batteryEnergyDensityNotPrinted', ...
                            ['Raymer Table 20.1 prints no energy density for "%s", ' ...
                             'only its specific energy in Wh/kg.'], fuel_name);
                    otherwise
                        error('SubsystemsBase:unknownBatteryChemistry', ...
                            ['Unknown battery chemistry "%s". Known chemistries ' ...
                             '(Raymer 6th ed. Table 20.1): Lead-acid, Alkaline, ' ...
                             'NiFe, NiCd, NiH, NiMH, NiZn, Li-ion, Li-ion Polymer, ' ...
                             'LiCoO2, LiFePO4, LiMn2O4, LiNiMnCoO2 (NMC), Li-S, ' ...
                             'Licerion (US), Li-titanate, Li-air, Na-ion, ' ...
                             'Molten salt, Silver Zinc.'], fuel_name);
                end
                d = d * 3.785411784;    % Wh/L -> Wh/gal. 1 US gal = 3.785411784 L.
            else
                error('SubsystemsBase:unknownFuelType', ...
                    'Unknown fuel type "%s". Known types: hydrocarbon, battery.', ...
                    fuel_type);
            end
        end


    end
end

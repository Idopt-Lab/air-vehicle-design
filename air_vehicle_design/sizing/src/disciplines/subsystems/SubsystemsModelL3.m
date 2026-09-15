classdef (Abstract) SubsystemsModelL3 < SubsystemsBase
%SUBSYSTEMSMODELL3  Tier-2 abstract enforcer for Level-3 subsystems.
%
%   Inherits SubsystemsBase directly.
%
%   Properties (Abstract):
%       fuel_type (char): energy medium, hydrocarbon or battery.
%       fuel_name (char): fuel or battery chemistry selecting the table row.
%       packaging_factor_category (char): tank type selecting the packaging factor.
%       avionics_table_row (char): Raymer Table 11.6 row.
%       avionics_weight (double): avionics weight (lbf).
%       wing_fuel_volume (double): wing fuel volume (ft^3).
%       total_design_volume (double): total volume of the design (ft^3).
%
%   Methods (Abstract):
%       get_avionics_weight_component_buildup: avionics weight (lbf), one box
%           at a time.
%       get_total_avionics_volume_component_buildup: avionics volume (ft^3),
%           one box at a time.
%       get_wing_fuel_volume_available: fuel-usable volume of the main wings (ft^3).
%       get_total_fuel_volume_available: fuel-usable volume of the whole
%           aircraft (ft^3).
%       get_design_total_volume: total volume of the design (ft^3).
%
%   Methods:
%       get_avionics_weight: bridge to get_avionics_weight_component_buildup.
%       get_total_avionics_volume_occupied: bridge to
%           get_total_avionics_volume_component_buildup.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL3.md

    properties (Abstract)
        packaging_factor_category  % string, e.g. 'Integral tank — shallow fuselage' [Nicolai & Carichner p.210]
        avionics_table_row         % string, e.g. 'Fighters' [Raymer 6th ed. Table 11.6]
    end


    properties (Abstract)
        %AVIONICS_WEIGHT  fraction * W_empty, self-referencing the injected
        %   fuel_weight_source.
        avionics_weight

        %WING_FUEL_VOLUME  [Roskam Eq. 6.2/6.3] off obj.geom's wing planform.
        % Wing volume usable for fuel.
        wing_fuel_volume

        %TOTAL_DESIGN_VOLUME
        % Entire design's volume (fuselage + wings)
        total_design_volume
    end

    methods (Abstract)

        % Estimate the weight of individual avionics components available
        val = get_avionics_weight_component_buildup(obj)

        % Estimate the fuel-useable volume of the aircraft's main wings.
        % This can be the fuselage (tube-and-wing) or just the wings (flying wing).
        val = get_wing_fuel_volume_available(obj)

        % Estimate the fuel-useable volume of the entire aircraft.
        val = get_total_fuel_volume_available(obj)

        % Estimate the design's total avionics volume.
        val = get_total_avionics_volume_component_buildup(obj)

        % GET_DESIGN_TOTAL_VOLUME
        % Estimate the design's total volume using rough geometric methods by Raymer and/or Roskam.
        % User is expected to estimate internal volumes of major aircraft parts, such as the main wings and fuselage.
        val = get_design_total_volume(obj)
    end

    methods
        function v = get_avionics_weight(obj)
            v = obj.get_avionics_weight_component_buildup();
        end

        function v = get_total_avionics_volume_occupied(obj)
            v = obj.get_total_avionics_volume_component_buildup();
        end
    end

end

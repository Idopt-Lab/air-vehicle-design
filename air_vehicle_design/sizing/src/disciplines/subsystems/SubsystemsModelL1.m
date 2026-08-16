classdef (Abstract) SubsystemsModelL1 < SubsystemsBase
%SUBSYSTEMSMODELL1  Tier-2 abstract enforcer for Level-1 subsystems.
%
%   Inherits SubsystemsBase directly. L1 is tabulation only: no geometry, no
%   injected collaborators. Methods needing an external weight take it as an
%   explicit argument. No packaging factor and no landing-gear bay at L1.
%
%   History and rationale: docs/decision_log.md
%   Toolbox companion: src/disciplines/subsystems/SubsystemsL1.md

    properties (Abstract)
        fuel_type          % string, e.g. 'JP-8' -- selects SubsystemsL1.lookup_fuel_density [Nicolai & Carichner Table 8.6]
        avionics_table_row % string, e.g. 'Fighters' -- selects SubsystemsL1.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6]
    end

    % ======================================================================= %
    % avionics_weight_fraction, avionics_density, fuel_density,
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase. Only
    % avionics_weight and avionics_volume stay methods here: L1 has no injected
    % weights object, so both take W_empty as an explicit argument. L2/L3
    % implement the same-named members as Dependent properties instead.
    % ======================================================================= %
    methods (Abstract)

        %AVIONICS_WEIGHT  W_avionics = fraction * W_empty [lbf].
        val = avionics_weight(obj, W_empty)

        %AVIONICS_VOLUME  W_avionics / avionics_density [ft^3]. MUST be
        %   summed into internal_volume() -- see SubsystemsBase header.
        val = avionics_volume(obj, W_empty)

    end

end

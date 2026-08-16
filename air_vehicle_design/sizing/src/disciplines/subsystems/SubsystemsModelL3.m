classdef (Abstract) SubsystemsModelL3 < SubsystemsBase
%SUBSYSTEMSMODELL3  Tier-2 abstract enforcer for Level-3 subsystems.
%
%   Inherits SubsystemsBase directly. Same abstract contract as
%   SubsystemsModelL2; L3 refines the fuselage raw-volume term with GeomL3's
%   frame-integrated station areas instead of GeomL2's envelope ellipse. Kept
%   separate from SubsystemsModelL2 only because geom is typed to
%   GeometryModelL3 (enforced by the concrete class's constructor).
%
%   History and rationale: docs/decision_log.md
%   Toolbox companion: src/disciplines/subsystems/SubsystemsL3.md

    properties (Abstract)
        fuel_type                  % string, e.g. 'JP-8' [Nicolai & Carichner Table 8.6]
        packaging_factor_category  % string, e.g. 'Integral tank — shallow fuselage' [Nicolai & Carichner p.210]
        avionics_table_row         % string, e.g. 'Fighters' [Raymer 6th ed. Table 11.6]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL3
        fuel_weight_source  % (1,1) WeightsBase
    end

    % ======================================================================= %
    % avionics_weight_fraction, avionics_density, fuel_density,
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase. As in
    % SubsystemsModelL2, each member below takes zero extra arguments and reads
    % only obj's own inputs/collaborators, so it is an abstract PROPERTY.
    % ======================================================================= %
    properties (Abstract)
        %AVIONICS_WEIGHT  fraction * W_empty, self-referencing the injected
        %   fuel_weight_source.
        avionics_weight

        %AVIONICS_VOLUME  MUST be summed into internal_volume().
        avionics_volume

        %FUSELAGE_USABLE_FUEL_VOLUME  fuselage_raw_volume * packaging_factor.
        %   Packaging factor MUST be applied before comparison.
        fuselage_usable_fuel_volume

        %WING_FUEL_VOLUME  [Roskam Eq. 6.2/6.3] off obj.geom's wing planform.
        wing_fuel_volume
    end

    methods (Abstract)

        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation gap, same as
        %   L2. Stays a METHOD -- see SubsystemsModelL2.battery_volume.
        val = battery_volume(obj, E_required_kWh)

    end

end

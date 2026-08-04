classdef (Abstract) SubsystemsModelL3 < SubsystemsBase
%SUBSYSTEMSMODELL3  Tier-2 abstract enforcer for Level-3 subsystems.
%
%   Inherits SubsystemsBase directly, not SubsystemsModelL2: each fidelity
%   level satisfies the Tier-1 contract independently (same rationale as
%   GeometryModelL3 inheriting GeometryBase directly).
%
%   Same shape and same abstract contract as SubsystemsModelL2 -- L3 refines
%   the fuselage raw-volume term with GeomL3's frame-integrated station
%   areas instead of GeomL2's envelope-ellipse approximation (docs/subplans/
%   09_subsystems.md Fidelity split), but every equation is otherwise
%   identical. Kept as a SEPARATE abstract class (rather than reusing
%   SubsystemsModelL2) only because geom is typed to a different concrete
%   tier (GeometryModelL3, not GeometryModelL2) -- MATLAB abstract property
%   lists carry no type constraint, but the concrete F16SubsystemsL3's
%   constructor arguments block enforces it, mirroring F16WeightsL3's own
%   geom (1,1) GeometryModelL3 DI guard.
%
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
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase, not
    % here (2026-08-03 -- see that file's header note). Same rationale as
    % SubsystemsModelL2 for what remains: zero extra arguments, reads only
    % obj's own stored inputs/injected collaborators, so declared as an
    % ABSTRACT PROPERTY rather than an abstract method.
    % ======================================================================= %
    properties (Abstract)
        %AVIONICS_WEIGHT  fraction * W_empty, self-referencing the injected
        %   fuel_weight_source.
        avionics_weight

        %AVIONICS_VOLUME  MUST be summed into internal_volume().
        avionics_volume

        %FUSELAGE_USABLE_FUEL_VOLUME  fuselage_raw_volume * packaging_factor.
        %   Packaging factor MUST be applied before comparison (item 5b).
        fuselage_usable_fuel_volume

        %WING_FUEL_VOLUME  [Roskam Eq. 6.2/6.3] off obj.geom's wing planform.
        wing_fuel_volume
    end

    methods (Abstract)

        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation GAP, same as
        %   L2 (subplan Eq. §7). Stays a METHOD -- same rationale as
        %   SubsystemsModelL2.battery_volume (external argument, and a
        %   Dependent getter must never be allowed to throw).
        val = battery_volume(obj, E_required_kWh)

    end

end

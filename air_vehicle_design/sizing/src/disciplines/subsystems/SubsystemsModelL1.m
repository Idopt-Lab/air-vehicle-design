classdef (Abstract) SubsystemsModelL1 < SubsystemsBase
%SUBSYSTEMSMODELL1  Tier-2 abstract enforcer for Level-1 subsystems.
%
%   Inherits SubsystemsBase directly, not another SubsystemsModelLN.
%
%   L1 is TABULATION ONLY -- Nicolai & Carichner Ch.8-style lookups, no
%   geometry, no injected collaborators. A concrete L1 class injects nothing;
%   every method that needs an external weight (avionics W_empty, a required
%   fuel weight) takes it as an explicit argument, exactly the way
%   F16WeightsL1.OEW(obj, W_TO) takes W_TO rather than injecting a weights
%   object at L1.
%
%   No fuel-tank packaging factor is usable at L1 (docs/subplans/09_subsystems.md
%   Equations & Citations item 1: "not usable at L1 -- no geometric raw volume
%   exists yet"), and there is no landing-gear counterpart at L1 at all (no
%   fuselage envelope to place a bay into).
%
%   Toolbox companion: src/disciplines/subsystems/SubsystemsL1.md

    properties (Abstract)
        fuel_type          % string, e.g. 'JP-8' -- selects SubsystemsL1.lookup_fuel_density [Nicolai & Carichner Table 8.6]
        avionics_table_row % string, e.g. 'Fighters' -- selects SubsystemsL1.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6]
    end

    % ======================================================================= %
    % avionics_weight_fraction, avionics_density, fuel_density,
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase, not
    % here -- see that file's 2026-08-03 header note. avionics_weight and
    % avionics_volume stay declared HERE (not lifted): L1 has no injected
    % weights object, so both MUST take W_empty as an explicit argument
    % [WeightsBase.OEW(obj, W_TO) is the established precedent for this
    % "stays a method because it takes an explicit external argument" shape]
    % -- a kind (method) that L2/L3 deliberately do NOT share, since they
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

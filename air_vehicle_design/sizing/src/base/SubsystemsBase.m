classdef (Abstract) SubsystemsBase < handle
%SUBSYSTEMSBASE  Tier-1 abstract enforcer for all subsystems discipline classes.
%
%   Declares the contract orchestrators call -- internal_volume (total usable
%   internal volume, ft^3) and fuel_volume_check (fuel/battery sufficiency
%   against that volume) -- plus one fidelity-independent utility.
%
%   Inheritance: SubsystemsBase -> SubsystemsModelLN (abstract) -> F16SubsystemsLN.
%   The SubsystemsLN static toolboxes are not in this chain.
%
%   The two abstract methods below are declared at their widest signature (the
%   one L1 needs); L2/L3 override with the zero-extra-arg form and read an
%   injected weights collaborator live. Every internal_volume()
%   implementation must sum its avionics-volume term.
%
%   Companion doc: src/base/SubsystemsBase.md.
%   History and rationale: docs/decision_log.md.
    properties (Abstract)
        %AVIONICS_WEIGHT_FRACTION  Fraction of W_empty.
        %   [Raymer 6th ed. Table 11.6, p.375]
        avionics_weight_fraction

        %AVIONICS_DENSITY  Avionics packing density [lb/ft^3]. Same name at
        %   every level, different cited value: L1 uses Raymer's range average
        %   (~37.5); L2/L3 use Nicolai's flat 45 [Sec.8.1.11].
        avionics_density

        %FUEL_DENSITY  Fuel density [lb/ft^3] for obj.fuel_type.
        %   [Nicolai & Carichner Table 8.6, p.210]
        fuel_density

        %FUSELAGE_RAW_VOLUME  Raw geometric fuselage-internal volume [ft^3],
        %   before any fuel-tank packaging factor. [Raymer 6th ed. Eq. 7.14]
        %   at L2/L3. Honestly 0 at L1 (no fuselage geometry).
        % fuselage_raw_volume

        %FUEL_VOLUME  Total usable fuel volume [ft^3] -- fuselage-internal
        %   (packaged) + wing-internal at L2/L3; 0 at L1. Equals
        %   fuel_volume_check's 'available_vol_ft3', exposed as a property.
        fuel_volume
    end

    methods (Abstract)
        % Get avionics weight
        val = get_avionics_weight(obj, W_empty)

        % Get fuel volume
        % This should be agnostic enough to include both hydrocarbon and electric aircraft,
        % while allowing for both designs to use this function.
        % val = get_energy_storage_volume(energy_medium_density, energy_medium_weight)

        %INTERNAL_VOLUME  Total usable internal volume [ft^3] for this level.
        %   L1: avionics volume only. L2/L3: fuselage-internal (packaged) fuel
        %   volume + wing-internal fuel volume + avionics volume. Landing-gear
        %   bay volume is not auto-summed (citation gap) -- see
        %   F16SubsystemsL2.md/F16SubsystemsL3.md.
        val = get_internal_volume(obj, W_empty)

        %FUEL_VOLUME_CHECK  Does available fuel volume cover the required fuel
        %   weight, converted through this class's fuel-density path? Returns a
        %   struct with 'available_vol_ft3', 'required_vol_ft3', 'sufficient'.
        %   L1 callers pass required_weight_lb; L2/L3 read it live from an
        %   injected fuel_weight_source.
        result = fuel_volume_check(obj, required_weight_lb)

        %FUEL_VOLUME_FROM_WEIGHT  Volume [ft^3] a fuel weight [lbf] occupies at
        %   this class's fuel_density -- the definitional conversion, fuel path.
        %   No packaging factor applied (that applies only to the geometric raw
        %   volume).
        val = fuel_volume_from_weight(obj, fuel_weight_lb)
    end

    methods (Static)

        % TODO (9/7/2026)(Casey): Unsure about keeping this here.
        % Useful for L1/2, unsure about L3. Depends on if Nicolai
        % or anyone has anything better.
        function vol = weight_to_volume(W_lb, density_lb_per_ft3)
        %WEIGHT_TO_VOLUME  Generic weight -> volume conversion [ft^3].
        %   Definitional (vol = W/density); the citation belongs to whichever
        %   density value the caller supplies, not to this identity.
            arguments
                W_lb               (1,1) double {mustBeNonnegative}
                density_lb_per_ft3 (1,1) double {mustBePositive}
            end
            vol = W_lb / density_lb_per_ft3;
        end

        function d = lookup_fuel_density_lb_per_ft_3(fuel_type)
        %LOOKUP_FUEL_DENSITY  Fuel density [lb/ft^3] by type.
        %   [Nicolai & Carichner, Table 8.6, p.210]
            switch fuel_type
                case 'JP-4',          d = 48.6;
                case 'JP-5',          d = 51.1;
                case 'JP-8',          d = 50.0;
                case 'Aviation gas',  d = 44.9;
                otherwise
                    error('SubsystemsL1:unknownFuelType', ...
                        ['Unknown fuel type "%s". Known types (Nicolai & ' ...
                         'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                        fuel_type);
            end
        end

        function d = lookup_fuel_density_lb_per_gal(fuel_type)
        %LOOKUP_FUEL_DENSITY_LB_PER_GAL  Fuel density [lb/gal] by type, for
        %   consistency-checking against the input JSON's density_lb_per_gal.
        %   The volume math uses lookup_fuel_density (lb/ft^3), not this
        %   figure. [Nicolai & Carichner, Table 8.6, p.210]
            switch fuel_type
                case 'JP-4',          d = 6.5;
                case 'JP-5',          d = 6.8;
                case 'JP-8',          d = 6.7;
                case 'Aviation gas',  d = 6.0;
                otherwise
                    error('SubsystemsL1:unknownFuelType', ...
                        ['Unknown fuel type "%s". Known types (Nicolai & ' ...
                         'Carichner Table 8.6): JP-4, JP-5, JP-8, Aviation gas.'], ...
                        fuel_type);
            end
        end

    end
end

classdef SubsystemsL1
%SUBSYSTEMSL1  Level-1 subsystems static toolbox: tabulation-only lookups.
%
%   Call as SubsystemsL1.method(...); never instantiated. F16SubsystemsL1
%   delegates here. L1 is a pure tabulation tier: no geometry, no injected
%   collaborators. Each high-level method takes an explicit weight argument.
%
%   Sources: fuel density [Nicolai & Carichner Ch.8 p.210]; avionics weight
%   fraction [Raymer 6th ed. Table 11.6 p.375]. L1 avionics density is
%   Raymer's own range average (~37.5 lb/ft^3); L2/L3 use Nicolai's flat 45.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the object (+ an explicit weight), return result.
        % ================================================================== %

        function val = avionics_weight_fraction(obj)
        %AVIONICS_WEIGHT_FRACTION  Fraction of W_empty = Table 11.6 row's
        %   range midpoint. [Raymer 6th ed. Table 11.6, p.375]
            val = SubsystemsL1.lookup_avionics_weight_fraction(obj.avionics_table_row);
        end

        function val = avionics_density(obj) %#ok<INUSD>
        %AVIONICS_DENSITY  L1 range-average density [lb/ft^3]. Average of
        %   Raymer's stated 30-45 range; NOT Nicolai's flat 45 (the L2/L3
        %   figure). [Raymer 6th ed. Ch.11 p.375, prose after Table 11.6]
            val = mean([30, 45]);   % = 37.5
        end

        function val = avionics_weight(obj, W_empty)
        %AVIONICS_WEIGHT  W_avionics = fraction * W_empty [lbf].
            arguments
                obj
                W_empty (1,1) double {mustBeNonnegative}
            end
            val = SubsystemsL1.avionics_weight_fraction(obj) * W_empty;
        end

        function val = avionics_volume(obj, W_empty)
        %AVIONICS_VOLUME  W_avionics / avionics_density [ft^3].
            val = SubsystemsBase.weight_to_volume( ...
                SubsystemsL1.avionics_weight(obj, W_empty), ...
                SubsystemsL1.avionics_density(obj));
        end

        function val = fuel_density(obj)
        %FUEL_DENSITY  [Nicolai & Carichner Table 8.6, p.210]
            val = SubsystemsL1.lookup_fuel_density(obj.fuel_type);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
        %FUEL_VOLUME_FROM_WEIGHT  fuel_weight_lb / fuel_density [ft^3].
        %   No packaging factor: none is usable at L1 (no geometric raw
        %   volume exists yet).
            arguments
                obj
                fuel_weight_lb (1,1) double {mustBeNonnegative}
            end
            val = SubsystemsBase.weight_to_volume(fuel_weight_lb, SubsystemsL1.fuel_density(obj));
        end

        function val = fuselage_raw_volume(obj) %#ok<INUSD>
        %FUSELAGE_RAW_VOLUME  Honestly 0: L1 has no fuselage geometry
        %   (tabulation-only tier). Declared on SubsystemsBase so every
        %   fidelity level provides this member.
            val = 0;
        end

        function val = fuel_volume(obj) %#ok<INUSD>
        %FUEL_VOLUME  Total usable fuel volume [ft^3]. Honestly 0 at L1, same
        %   rationale as fuselage_raw_volume above.
            val = 0;
        end

        function val = internal_volume(obj, W_empty)
        %INTERNAL_VOLUME  L1 total usable internal volume [ft^3] = avionics
        %   volume only. No fuel-bay or gear-bay geometry exists at this tier.
            val = SubsystemsL1.avionics_volume(obj, W_empty);
        end

        function result = fuel_volume_check(obj, required_weight_lb)
        %FUEL_VOLUME_CHECK  L1 sufficiency check. No fuel-bay geometry exists
        %   at this tier, so 'available' is honestly 0 ft^3. required_vol_ft3
        %   is still computed via the fuel-type density lookup, so a caller
        %   sees the volume needed. 'sufficient' is true only when required
        %   fuel is zero.
            arguments
                obj
                required_weight_lb (1,1) double {mustBeNonnegative}
            end
            required_vol = SubsystemsL1.fuel_volume_from_weight(obj, required_weight_lb);
            result = struct('available_vol_ft3', 0, ...
                             'required_vol_ft3', required_vol, ...
                             'sufficient', required_vol <= 0);
        end

        % ================================================================== %
        % LOW-LEVEL: pure lookups -- scalars/strings only, no object access.
        % ================================================================== %

        function d = lookup_fuel_density(fuel_type)
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

        function range = lookup_avionics_weight_fraction_range(table_row)
        %LOOKUP_AVIONICS_WEIGHT_FRACTION_RANGE  [low, high] fraction of
        %   W_empty by category. Full 8-row table, verbatim.
        %   [Raymer 6th ed. Table 11.6, p.375]
            switch table_row
                case 'General aviation-single engine', range = [0.01, 0.03];
                case 'Light twin',                     range = [0.02, 0.04];
                case 'Turboprop transport',             range = [0.02, 0.04];
                case 'Business jet',                    range = [0.04, 0.05];
                case 'Jet transport',                   range = [0.01, 0.02];
                case 'Fighters',                        range = [0.03, 0.08];
                case 'Bombers',                          range = [0.06, 0.08];
                case 'Jet trainers',                     range = [0.03, 0.04];
                otherwise
                    error('SubsystemsL1:unknownAvionicsCategory', ...
                        ['Unknown avionics table row "%s". Known rows ' ...
                         '(Raymer 6th ed. Table 11.6): General aviation-single ' ...
                         'engine, Light twin, Turboprop transport, Business jet, ' ...
                         'Jet transport, Fighters, Bombers, Jet trainers.'], table_row);
            end
        end

        function val = lookup_avionics_weight_fraction(table_row)
        %LOOKUP_AVIONICS_WEIGHT_FRACTION  Fraction = the row's range midpoint.
        %   [Raymer 6th ed. Table 11.6, p.375]
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(table_row);
            val   = mean(range);
        end

    end
end

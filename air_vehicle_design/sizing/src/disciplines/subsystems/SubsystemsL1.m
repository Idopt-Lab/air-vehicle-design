classdef SubsystemsL1
%SUBSYSTEMSL1  Level-1 subsystems static toolbox: tabulation-only lookups.
%
%   Call as SubsystemsL1.method(...); never instantiated, not in the
%   inheritance chain. F16SubsystemsL1 inherits SubsystemsModelL1 and
%   delegates here.
%
%   L1 is a pure tabulation tier -- no geometry, no injected collaborators.
%   Every "high-level" method below still takes an explicit weight argument
%   (W_empty or a required fuel weight) rather than reading an injected
%   object, exactly as F16WeightsL1.OEW(obj, W_TO) takes W_TO as an argument.
%
%   Official sources: fuel-type density and fuel-tank packaging factors
%   [Nicolai & Carichner, Ch.8, p.210]; avionics weight fraction
%   [Raymer 6th ed. Table 11.6, p.375]; avionics density, L1 only, is
%   Raymer's OWN following-paragraph range average (~37.5 lb/ft^3) -- L2/L3
%   switch to Nicolai's flat 45.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object (+ an explicit weight), return
        % the result.
        % ================================================================== %

        function val = avionics_weight_fraction(obj)
        %AVIONICS_WEIGHT_FRACTION  Decided fraction of W_empty -- the Table
        %   11.6 row's own range midpoint. [Raymer 6th ed. Table 11.6, p.375]
            val = SubsystemsL1.lookup_avionics_weight_fraction(obj.avionics_table_row);
        end

        function val = avionics_density(obj) %#ok<INUSD>
        %AVIONICS_DENSITY  L1's own Raymer-range-average density [lb/ft^3].
        %   [Raymer 6th ed. Ch.11, p.375, prose immediately after Table 11.6:
        %   "volume can be estimated assuming that avionics has an average
        %   density of about 30-45 lb/ft^3"] -- range average, NOT Nicolai's
        %   flat 45 (that is the L2/L3 figure; docs/subplans/09_subsystems.md
        %   Equations & Citations item 4, fidelity-split decision).
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
        %   NO packaging factor applied -- not usable at L1 (docs/subplans/
        %   09_subsystems.md Equations & Citations item 1 status: "Not
        %   usable at L1 -- no geometric raw volume exists yet").
            arguments
                obj
                fuel_weight_lb (1,1) double {mustBeNonnegative}
            end
            val = SubsystemsBase.weight_to_volume(fuel_weight_lb, SubsystemsL1.fuel_density(obj));
        end

        function val = fuselage_raw_volume(obj) %#ok<INUSD>
        %FUSELAGE_RAW_VOLUME  Honestly 0 -- no fuselage geometry exists at L1
        %   (docs/subplans/09_subsystems.md Objectives, Fidelity split: L1 is
        %   tabulation-only). Not guessed -- matches the same "no bay
        %   geometry yet" answer fuel_volume_check already gives at this
        %   tier. Declared on SubsystemsBase so every fidelity level provides
        %   this member, even where the honest answer is a constant.
            val = 0;
        end

        function val = fuel_volume(obj) %#ok<INUSD>
        %FUEL_VOLUME  Total available (usable) fuel volume [ft^3] --
        %   honestly 0 at L1, same rationale as fuselage_raw_volume above.
            val = 0;
        end

        function val = internal_volume(obj, W_empty)
        %INTERNAL_VOLUME  L1 total usable internal volume [ft^3] = avionics
        %   volume only -- no fuel-bay or gear-bay geometry exists at this
        %   tier (Fidelity split, docs/subplans/09_subsystems.md Objectives).
            val = SubsystemsL1.avionics_volume(obj, W_empty);
        end

        function result = fuel_volume_check(obj, required_weight_lb)
        %FUEL_VOLUME_CHECK  L1 sufficiency check. NO fuel-bay geometry exists
        %   at this tier, so 'available' is honestly reported as 0 ft^3, not
        %   guessed -- required_vol_ft3 is still computed via the fuel-type
        %   density lookup so a caller can see how much volume WOULD be
        %   needed. 'sufficient' is therefore true only in the trivial case
        %   of zero required fuel.
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
        %   [Nicolai & Carichner, Table 8.6, p.210]. Replaces the legacy
        %   code's single hardcoded, uncited 6.47 (JP-4-only, threw on any
        %   other type -- docs/subplans/09_subsystems.md "Legacy Bugs to
        %   Avoid" item 4).
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
        %   citation completeness / consistency-checking against the input
        %   JSON's echoed density_lb_per_gal value. The framework's own
        %   volume math uses lookup_fuel_density (lb/ft^3) directly, not
        %   this gal-based figure. [Nicolai & Carichner, Table 8.6, p.210]
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
        %   W_empty by category. [Raymer 6th ed. Table 11.6, p.375]. Full
        %   8-row table, reproduced verbatim.
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
        %LOOKUP_AVIONICS_WEIGHT_FRACTION  Decided fraction = the row's own
        %   range midpoint [Raymer 6th ed. Table 11.6, p.375]. DECIDED
        %   (Casey, 2026-08-03): use the midpoint rather than the legacy
        %   code's low-end value (docs/subplans/09_subsystems.md Equations &
        %   Citations item 3).
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(table_row);
            val   = mean(range);
        end

    end
end

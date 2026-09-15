classdef SubsystemsL1
%SUBSYSTEMSL1  Level-1 subsystems static toolbox: tabulation-only lookups.
%
%   Call as SubsystemsL1.method(...). Holds the Raymer
%   avionics content only.
%
%   Properties (Constant):
%       AVIONICS_DENSITY (double): avionics packing density, 37.5 lb/ft^3.
%
%   Methods (Static):
%       compute_avionics_weight: fraction x W_empty, returns avionics weight (lbf).
%       compute_avionics_volume: weight / density, returns avionics volume (ft^3).
%           Density is an argument.
%       lookup_avionics_weight_fraction_range: [low, high] fraction of W_empty
%           for one aircraft category. Raymer Table 11.6, all 8 rows verbatim.
%
%   Source: Raymer 6th ed. Table 11.6 p.375; density from the paragraph before it.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL1.md

    properties (Constant)
        %AVIONICS_DENSITY  L1 range-average density [lb/ft^3]. 
        %   Source: Raymer 6th ed. Ch.11 p.375, just before Table 11.6
        AVIONICS_DENSITY = mean([30, 45]) % lbf/ft^3
    end

    methods (Static)

        function val = compute_avionics_weight(avi_WF, W_empty)
        %AVIONICS_WEIGHT  W_avionics = fraction * W_empty [lbf].
        % ARGS:
        %   avi_WF = Avionics weight fraction (coefficient)
        %   W_empty = Empty weight (lbf)
        % RETURNS:
        %   val = avionics weight (lbf)
            arguments
                avi_WF (1,1) double {mustBeNonnegative}
                W_empty (1,1) double {mustBeNonnegative}
            end
            val = avi_WF * W_empty;
        end

        function val = compute_avionics_volume(W_avionics, density_lb_per_ft3)
        %COMPUTE_AVIONICS_VOLUME  Avionics volume [ft^3]. The density is the
        %   caller's choice: L1 uses Raymer's range average, L2/L3 Nicolai's
        %   flat 45.
            arguments
                W_avionics               (1,1) double {mustBeNonnegative}
                density_lb_per_ft3 (1,1) double {mustBePositive}
            end
            val = W_avionics / density_lb_per_ft3;
        end

        function range = lookup_avionics_weight_fraction_range(aircraft_category)
        %LOOKUP_AVIONICS_WEIGHT_FRACTION_RANGE  [low, high] fraction of
        %   W_empty by category. Full 8-row table, verbatim.
        %   [Raymer 6th ed. Table 11.6, p.375]
            switch aircraft_category
                case 'General aviation-single engine', range = [0.01, 0.03];
                case 'Light twin',                     range = [0.02, 0.04];
                case 'Turboprop transport',             range = [0.02, 0.04];
                case 'Business jet',                    range = [0.04, 0.05];
                case 'Jet transport',                   range = [0.01, 0.02];
                case 'Fighters',                        range = [0.03, 0.08];
                case 'Bombers',                         range = [0.06, 0.08];
                case 'Jet trainers',                    range = [0.03, 0.04];
                otherwise
                    error('SubsystemsL1:unknownAvionicsCategory', ...
                        ['Unknown avionics table row "%s". Known rows ' ...
                         '(Raymer 6th ed. Table 11.6): General aviation-single ' ...
                         'engine, Light twin, Turboprop transport, Business jet, ' ...
                         'Jet transport, Fighters, Bombers, Jet trainers.'], aircraft_category);
            end
        end

    end
end

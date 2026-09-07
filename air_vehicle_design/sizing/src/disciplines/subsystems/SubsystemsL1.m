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

        function val = compute_avionics_volume(W_avionics)
        %AVIONICS_VOLUME  W_avionics / avionics_density [ft^3].
        % ARGS
        %   W_avionics = Weight of avionics (lbf)
            val = W_avionics / SubsystemsL1.AVIONICS_DENSITY;
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
                % Mod (09/07/2026) (Claude)
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

        % function val = lookup_avionics_weight_fraction(table_row)
        % %LOOKUP_AVIONICS_WEIGHT_FRACTION  Fraction = the row's range midpoint.
        % %   [Raymer 6th ed. Table 11.6, p.375]
        %     range = SubsystemsL1.lookup_avionics_weight_fraction_range(table_row);
        %     val   = mean(range);
        % end

    end
end

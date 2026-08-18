classdef GeomL1
%GEOML1  Level-1 geometry static toolbox: statistical regressions on TOGW.
%   Call as GeomL1.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL1 inherits GeometryModelL1 and delegates to these statics.
%
%   Sources: [Roskam Vol. I Table 3.5] wetted area; [Raymer 6th ed. Table 6.3]
%   fuselage length; [Raymer 7th ed. Table 4.1] equivalent aspect ratio;
%   [Raymer 7th ed. Table 6.5] control surfaces.
%
%   Companion doc: src/disciplines/geometry/GeomL1.md

    methods (Static)

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access.
        % ================================================================== %

        function val = compute_s_wet_regression(aircraft_category, W_TO)
        %COMPUTE_S_WET_REGRESSION  [Roskam Vol. I Table 3.5]
            arguments
                aircraft_category
                W_TO (1,1) double {mustBePositive}
            end
            [c, d] = GeomL1.lookup_swet(aircraft_category);
            val = 10^c * W_TO^d;
        end

        function val = compute_l_fus_regression(aircraft_category, W_TO)
        %COMPUTE_L_FUS_REGRESSION  [Raymer 6th ed. Table 6.3]
            arguments
                aircraft_category
                W_TO (1,1) double {mustBePositive}
            end
            [a, C] = GeomL1.lookup_lfus(aircraft_category);
            val = a * W_TO^C;
        end

        function val = compute_AR_eq(aircraft_category, M_max)
            %COMPUTE_AR_EQ  [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
            arguments
                aircraft_category
                M_max (1,1) double {mustBePositive}
            end
            [a, C] = GeomL1.lookup_AR_eq(aircraft_category);
            val = a * M_max^C;
        end

        function [c, d] = lookup_swet(aircraft_category)
        %LOOKUP_SWET  [Roskam Vol. I Table 3.5]
            switch aircraft_category
                case 'jet_fighter',    c = -0.1289; d = 0.7506;
                case 'jet_bomber',     c =  0.1213; d = 0.7306;
                % transport_jet d = 0.7531 per metabook_data.md Eq. 4.9 /
                % Eq. 4.42; reproduces the printed 28,291 ft^2 (disposition D3).
                case 'transport_jet',  c =  0.0199; d = 0.7531;
                case 'business_jet',   c =  0.2263; d = 0.6977;
                case 'military_cargo', c = -0.0866; d = 0.8099;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_swet.', aircraft_category);
            end
        end

        function [a, C] = lookup_lfus(aircraft_category)
        %LOOKUP_LFUS  [Raymer 6th ed. Table 6.3]; ft from lbf.
            switch aircraft_category
                case 'jet_fighter',    a = 0.93; C = 0.39;
                case 'jet_trainer',    a = 0.79; C = 0.41;
                case 'transport_jet',  a = 0.67; C = 0.43;
                case 'military_cargo', a = 0.23; C = 0.50;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_lfus.', aircraft_category);
            end
        end

        % TODO (8/14/2026): Missing categories for sailplanes, homebuilt, general aviation (single & twin engine), agricultural aircraft, twin turboprop, flying boats, jet trainer, jet fighter (dogfighter & other), military jet cargo/bomber, and jet transport.
        % For sailplanes, the equivalent aspect ratio is 0.19*(best L/D)^(1.3).
        % For props, the equivalent AR is a fixed number.
        % For jets, the equivalent AR is determined via equation, a*M_max^c. The table 4.1 gives the coefficients based on aircraft's category.
        % It should be noted that the equivalent aspect ratio = wing span squared divided by wing/canard areas ( (b^2)/(S_ref), where S_ref can be for the wings in question).
        function [a, C] = lookup_AR_eq(aircraft_category)
        %LOOKUP_AR_EQ  [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
            switch aircraft_category
                case 'jet_fighter',    a = 5.416; C = -0.6222;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for AR_eq — only the Raymer 7th ed. Table 4.1 jet-fighter (dogfighter) row is implemented.', aircraft_category);
            end
        end

        % TODO (8/14/2026): Add categories for jet transport, jet trainer, business jet, general aviation (single & twin engine), and sailplane.
        function val = lookup_control_surface_fraction(aircraft_category, surface)
        %LOOKUP_CONTROL_SURFACE_FRACTION  [Raymer 7th ed. Table 6.5, jet-fighter row]
        %   Elevator 0.30 is the all-moving-tail row value, not a hinged-elevator
        %   chord fraction.
        %
        %   TODO: the jet-fighter row has no aileron fraction, so 'aileron'
        %   errors. Guarded by TestGeomL1.testTODO_AileronFractionNotAvailable.
            switch aircraft_category
                case 'jet_fighter'
                    switch surface
                        case 'elevator', val = 0.30;
                        case 'rudder',   val = 0.33;
                        case 'aileron'
                            error('GeomL1:unknownControlSurface', ...
                                'Aileron chord fraction is not available in Raymer 7th ed. Table 6.5 jet-fighter row — not implemented, not guessed.');
                        otherwise
                            error('GeomL1:unknownControlSurface', ...
                                'Unknown control surface "%s". Add it to GeomL1.lookup_control_surface_fraction.', surface);
                    end
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for control-surface fractions — only the Raymer 7th ed. Table 6.5 jet-fighter row is implemented.', aircraft_category);
            end
        end

    end
end

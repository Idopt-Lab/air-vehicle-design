classdef GeomL1
%GEOML1  Level-1 geometry static toolbox: statistical regressions on TOGW.
%   Call as GeomL1.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL1 inherits GeometryModelL1 and delegates to these statics.
%
%   Sources: [Roskam Vol. I Table 3.5] wetted area; [Raymer 6th ed. Table 6.3]
%   fuselage length; [Raymer 7th ed. Table 4.1] equivalent aspect ratio;
%   [Raymer 7th ed. Table 6.5] control surfaces.
%
%   Only the jet-fighter rows of the Raymer tables are implemented; any other
%   category errors rather than being guessed. Tail sizing lives in the
%   standalone tail_sizing discipline, not here.
%
%   A lookup_* static returns the coefficients of one table row. A compute_*
%   static evaluates one equation. No static takes an aircraft object. The design
%   class picks the row, then feeds the equation. See GeomL1.md.
%
%   REMOVED IN THIS PASS. These statics took an aircraft object. Their TODOs are
%   kept here. GeomL1.md gives the reason and the new call path.
%     get_S_wet_statistical, get_L_fus, get_AR_eq, get_control_surface_fraction
%       % TODO (8/14/2026): Why do you need a function whose sole purpose is to call a SINGLE OTHER FUNCTION???
%     compute_control_surface_fraction
%       % TODO (8/14/2026): Why do you need a separate function for the sole purpose of calling another function... what????
%   Mod (08/17/2026) (Claude)
%
%   Companion doc: src/disciplines/geometry/GeomL1.md

    methods (Static)

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access. compute_*
        % holds one equation; lookup_* holds one table.
        % ================================================================== %

        % Mod (08/17/2026) (Claude)
        function val = compute_s_wet_regression(c, d, W_TO)
        %COMPUTE_S_WET_REGRESSION  Wetted area [ft^2] from TOGW [lbf].
        %   log10(S_wet) = c + d*log10(W_TO), so S_wet = 10^c * W_TO^d.
        %   Coefficients come from lookup_swet. c is negative for a fighter, so
        %   neither coefficient is validated positive.
        %   [Roskam Vol. I Eq. 3.22, p. 122]
            arguments
                c    (1,1) double {mustBeReal}
                d    (1,1) double {mustBeReal}
                W_TO (1,1) double {mustBePositive}
            end
            val = 10^c * W_TO^d;
        end

        % Mod (08/17/2026) (Claude)
        function val = compute_l_fus_regression(a, c, W_TO)
        %COMPUTE_L_FUS_REGRESSION  Fuselage length [ft] from TOGW [lbf].
        %   L_fus = a * W_TO^c.  Coefficients come from lookup_lfus.
        %   [Raymer 6th ed. Table 6.3]
            arguments
                a    (1,1) double {mustBeReal}
                c    (1,1) double {mustBeReal}
                W_TO (1,1) double {mustBePositive}
            end
            val = a * W_TO^c;
        end

        % TODO (8/14/2026): This looks fine. Don't touch.
        % _TODO (8/17/2026): Two rows disagree with the printed table. Do not
        %   change a coefficient without sign-off. See GeomL1.md.
        %     military_cargo holds the Regional Turboprops row (table row 6).
        %       Row 10, Mil. Patrol/Bomb/Transport, is 0.1628 / 0.7316.
        %     jet_bomber holds 0.1213 / 0.7306, which matches no table row and no
        %       other source in docs/reference_extracts/.
        %   The table has 12 rows. Eight are absent here.
        %   The Fighters row uses CLEAN take-off weight, with no stores.
        % Mod (08/17/2026) (Claude)
        function [c, d] = lookup_swet(cat)
        %LOOKUP_SWET  [Roskam Vol. I Table 3.5, p. 122]
            switch cat
                case 'jet_fighter',    c = -0.1289; d = 0.7506;
                case 'jet_bomber',     c =  0.1213; d = 0.7306;
                % transport_jet d = 0.7531 per metabook_data.md Eq. 4.9 /
                % Eq. 4.42; reproduces the printed 28,291 ft^2 (disposition D3).
                case 'transport_jet',  c =  0.0199; d = 0.7531;
                case 'business_jet',   c =  0.2263; d = 0.6977;
                case 'military_cargo', c = -0.0866; d = 0.8099;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_swet.', cat);
            end
        end

        % TODO (8/14/2026): This looks fine. Don't touch.
        function [a, C] = lookup_lfus(cat)
        %LOOKUP_LFUS  [Raymer 6th ed. Table 6.3]; ft from lbf.
            switch cat
                case 'jet_fighter',    a = 0.93; C = 0.39;
                case 'jet_trainer',    a = 0.79; C = 0.41;
                case 'transport_jet',  a = 0.67; C = 0.43;
                case 'military_cargo', a = 0.23; C = 0.50;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_lfus.', cat);
            end
        end

        % TODO (8/14/2026): This looks fine, but I wonder why there's a dependency injection in this.
        % Mod (08/17/2026) (Claude)
        function val = compute_AR_eq(a, C, M_max)
        %COMPUTE_AR_EQ  Equivalent aspect ratio from design Mach.
        %   AR_eq = a * M_max^C.  Coefficients come from lookup_AR_eq.
        %   This is the JET form only. See lookup_AR_eq for sailplanes and props.
        %   [Raymer 7th ed. Table 4.1]
            arguments
                a     (1,1) double {mustBeReal}
                C     (1,1) double {mustBeReal}
                M_max (1,1) double {mustBePositive}
            end
            val = a * M_max^C;
        end

        % TODO (8/14/2026): Missing categories for sailplanes, homebuilt, general aviation (single & twin engine), agricultural aircraft, twin turboprop, flying boats, jet trainer, jet fighter (dogfighter & other), military jet cargo/bomber, and jet transport.
        % For sailplanes, the equivalent aspect ratio is 0.19*(best L/D)^(1.3).
        % For props, the equivalent AR is a fixed number.
        % For jets, the equivalent AR is determined via equation, a*M_max^c. The table 4.1 gives the coefficients based on aircraft's category.
        % It should be noted that the equivalent aspect ratio = wing span squared divided by wing/canard areas ( (b^2)/(S_ref), where S_ref can be for the wings in question).
        function [a, C] = lookup_AR_eq(cat)
        %LOOKUP_AR_EQ  [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
            switch cat
                case 'jet_fighter',    a = 5.416; C = -0.6222;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for AR_eq — only the Raymer 7th ed. Table 4.1 jet-fighter (dogfighter) row is implemented.', cat);
            end
        end

        % TODO (8/14/2026): Add categories for jet transport, jet trainer, business jet, general aviation (single & twin engine), and sailplane.
        % Mod (08/17/2026) (Claude)
        function val = lookup_control_surface_fraction(cat, surface)
        %LOOKUP_CONTROL_SURFACE_FRACTION  [Raymer 7th ed. Table 6.5, jet-fighter row]
        %   Elevator 0.30 is the all-moving-tail row value, not a hinged-elevator
        %   chord fraction.
        %
        %   A chord fraction is READ from the table, not computed from it, so
        %   this lookup is the whole answer -- there is no compute_* partner and
        %   a design class calls it directly.
        %
        %   TODO: the jet-fighter row has no aileron fraction, so 'aileron'
        %   errors. Guarded by TestGeomL1.testTODO_AileronFractionNotAvailable.
            switch cat
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
                        'Unknown aircraft_category "%s" for control-surface fractions — only the Raymer 7th ed. Table 6.5 jet-fighter row is implemented.', cat);
            end
        end

    end
end

classdef GeomL1
%GEOML1  Level-1 geometry static toolbox: statistical regressions on TOGW.
%
%   Call as GeomL1.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL1 inherits GeometryModelL1 and delegates to these statics.
%
%   Sources: [Roskam Vol. I Table 3.5] wetted area; [Raymer 6th ed. Table 6.3]
%   fuselage length; [Raymer 7th ed. Table 4.1] equivalent aspect ratio;
%   [Raymer 7th ed. Table 6.5] control surfaces.
%
%   Only the jet-fighter rows of the Raymer tables are implemented; any other
%   category errors rather than being guessed.
%
%   RESTORED 2026-08-03: compute_tail_volume_coeffs, lookup_tail_volume_coeffs,
%   compute_tail_arm, compute_S_HT, compute_S_VT are back (Casey's decision:
%   tail sizing IS geometry's job after all). The standalone tail_sizing
%   discipline (src/disciplines/tail_sizing/ -- TailSizingBase, TailL1/L2/L3,
%   TailSizingModelL1/L2/L3, F16TailL1/L2/L3) is RETIRED, not this toolbox --
%   see the TAIL SIZING section below, ported verbatim from the deleted
%   TailL1.m (same bodies/citations, high-level method renamed size->size_tail
%   to avoid ambiguity with MATLAB's builtin size() now that this lives in a
%   class used pervasively for geometry sizing).
%
%   Companion doc: src/disciplines/geometry/GeomL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the concrete object, return the result.
        % ================================================================== %

        function val = get_S_wet_statistical(obj, W_TO)
        %GET_S_WET_STATISTICAL  Total wetted area [ft^2].  [Roskam Vol. I Table 3.5]
            val = GeomL1.compute_s_wet_regression(obj.aircraft_category, W_TO);
        end

        function val = get_L_fus(obj, W_TO)
        %GET_L_FUS  Fuselage length [ft].  [Raymer 6th ed. Table 6.3]
            val = GeomL1.compute_l_fus_regression(obj.aircraft_category, W_TO);
        end

        function val = get_AR_eq(obj)
        %GET_AR_EQ  Equivalent aspect ratio from design Mach.  [Raymer 7th ed. Table 4.1]
            val = GeomL1.compute_AR_eq(obj.aircraft_category, obj.M_max);
        end

        function val = get_control_surface_fraction(obj, surface)
        %GET_CONTROL_SURFACE_FRACTION  Chord fraction C/c.  [Raymer 7th ed. Table 6.5]
        %   surface: 'elevator' | 'rudder'.
            val = GeomL1.compute_control_surface_fraction(obj.aircraft_category, surface);
        end

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access.
        % ================================================================== %

        function val = compute_s_wet_regression(aircraft_category, W_TO)
        %COMPUTE_S_WET_REGRESSION  [Roskam Vol. I Table 3.5]
            [c, d] = GeomL1.lookup_swet(aircraft_category);
            val = 10^c * W_TO^d;
        end

        function val = compute_l_fus_regression(aircraft_category, W_TO)
        %COMPUTE_L_FUS_REGRESSION  [Raymer 6th ed. Table 6.3]
            [a, C] = GeomL1.lookup_lfus(aircraft_category);
            val = a * W_TO^C;
        end

        function [c, d] = lookup_swet(cat)
        %LOOKUP_SWET  [Roskam Vol. I Table 3.5]
            switch cat
                case 'jet_fighter',    c = -0.1289; d = 0.7506;
                case 'jet_bomber',     c =  0.1213; d = 0.7306;
                case 'transport_jet',  c =  0.0199; d = 0.7351;
                case 'business_jet',   c =  0.2263; d = 0.6977;
                case 'military_cargo', c = -0.0866; d = 0.8099;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_swet.', cat);
            end
        end

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

        function val = compute_AR_eq(aircraft_category, M_max)
        %COMPUTE_AR_EQ  [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
            arguments
                aircraft_category
                M_max (1,1) double {mustBePositive}
            end
            [a, C] = GeomL1.lookup_AR_eq(aircraft_category);
            val = a * M_max^C;
        end

        function [a, C] = lookup_AR_eq(cat)
        %LOOKUP_AR_EQ  [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
            switch cat
                case 'jet_fighter',    a = 5.416; C = -0.6222;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for AR_eq — only the Raymer 7th ed. Table 4.1 jet-fighter (dogfighter) row is implemented.', cat);
            end
        end

        function val = compute_control_surface_fraction(aircraft_category, surface)
        %COMPUTE_CONTROL_SURFACE_FRACTION  [Raymer 7th ed. Table 6.5]
            val = GeomL1.lookup_control_surface_fraction(aircraft_category, surface);
        end

        function val = lookup_control_surface_fraction(cat, surface)
        %LOOKUP_CONTROL_SURFACE_FRACTION  [Raymer 7th ed. Table 6.5, jet-fighter row]
        %   Elevator 0.30 is the all-moving-tail row value, not a hinged-elevator
        %   chord fraction.
        %
        %   TODO: the table's jet-fighter row carries no aileron fraction, so
        %   'aileron' errors rather than returning a guess. Guarded by
        %   TestGeomL1.testTODO_AileronFractionNotAvailable.
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

        % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
        % Ported verbatim from the deleted src/disciplines/tail_sizing/TailL1.m
        % (same bodies, arguments validation, comments, citations). Only the
        % high-level entry point is renamed size -> size_tail (the four
        % low-level statics below keep their exact original names).
        %
        % METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed.,
        % AIAA, 2018, Table 6.4 + accompanying text]:
        %
        %   L_HT = L_VT = 0.475 * L_fus     [aft-mounted single-engine text
        %                                    rule; 0.475 is the midpoint of the
        %                                    stated 0.45-0.50 range]
        %   S_VT = c_VT * b    * S_ref / L_VT     [Table 6.4]
        %   S_HT = c_HT * cbar * S_ref / L_HT     [Table 6.4]
        %
        % Base coefficients are looked up by aircraft category (a Table 6.4
        % row), then corrected by two independent text rules that apply
        % per-aircraft: relaxed static stability (RSS, -10% on both c_HT/c_VT)
        % and an all-moving stabilator (-12.5% on c_HT only). Both corrections
        % are generic, category-driven statics (compute_tail_volume_coeffs /
        % lookup_tail_volume_coeffs) so a different aircraft's Tier-3 class can
        % apply a different combination -- F16GeomL1's constructor calls
        % compute_tail_volume_coeffs('jet_fighter', true, true), since the
        % F-16 has both properties, giving c_HT=0.315, c_VT=0.063.
        %
        % Only the jet-fighter row is implemented; any other category errors
        % rather than being guessed.
        % ==================================================================================================================================== %

        function result = size_tail(obj, S_ref, b, cbar, L_fus)
        %SIZE_TAIL  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  obj must expose c_HT/c_VT
        %   (the F-16's net, corrected coefficients -- see F16GeomL1).
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt).
            arguments
                obj
                S_ref (1,1) double {mustBePositive}
                b     (1,1) double {mustBePositive}
                cbar  (1,1) double {mustBePositive}
                L_fus (1,1) double {mustBePositive}
            end
            L_HT = GeomL1.compute_tail_arm(L_fus);
            L_VT = L_HT;
            S_ht = GeomL1.compute_S_HT(obj.c_HT, cbar, S_ref, L_HT);
            S_vt = GeomL1.compute_S_VT(obj.c_VT, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

        function [c_HT, c_VT] = compute_tail_volume_coeffs(aircraft_category, has_rss, has_all_moving_tail)
        %COMPUTE_TAIL_VOLUME_COEFFS  Tail volume coefficients with Raymer's
        %   text corrections applied.  [Raymer 7th ed. Table 6.4 + text]
        %     has_rss             -- relaxed static stability: -10% on both
        %     has_all_moving_tail -- all-moving stabilator: -12.5% on c_HT
        %                            (midpoint of Raymer's 10-15% range)
            arguments
                aircraft_category
                has_rss (1,1) logical
                has_all_moving_tail (1,1) logical
            end
            [c_HT, c_VT] = GeomL1.lookup_tail_volume_coeffs(aircraft_category);
            if has_rss
                c_HT = c_HT * (1 - 0.10);
                c_VT = c_VT * (1 - 0.10);
            end
            if has_all_moving_tail
                c_HT = c_HT * (1 - 0.125);
            end
        end

        function [c_HT, c_VT] = lookup_tail_volume_coeffs(cat)
        %LOOKUP_TAIL_VOLUME_COEFFS  Base coefficients, before text corrections.
        %   [Raymer 7th ed. Table 6.4, jet-fighter row]
            switch cat
                case 'jet_fighter', c_HT = 0.40; c_VT = 0.07;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        ['Unknown aircraft_category "%s" for tail-volume ' ...
                         'coefficients -- only the Raymer 7th ed. Table 6.4 ' ...
                         'jet-fighter row is implemented.'], cat);
            end
        end

        function L = compute_tail_arm(L_fus)
        %COMPUTE_TAIL_ARM  Tail moment arm [ft] as a fraction of fuselage
        %   length.  [Raymer 7th ed., aft-mounted single-engine text rule;
        %   0.475 is the midpoint of the stated 0.45-0.50 range]
            arguments
                L_fus (1,1) double {mustBePositive}
            end
            L = 0.475 * L_fus;
        end

        function val = compute_S_HT(c_HT, cbar, S_ref, L_HT)
        %COMPUTE_S_HT  Horizontal-tail area [ft^2].  [Raymer 7th ed. Table 6.4]
            arguments
                c_HT  (1,1) double {mustBeNonnegative}
                cbar  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
            end
            val = c_HT * cbar * S_ref / L_HT;
        end

        function val = compute_S_VT(c_VT, b, S_ref, L_VT)
        %COMPUTE_S_VT  Vertical-tail area [ft^2].  [Raymer 7th ed. Table 6.4]
            arguments
                c_VT  (1,1) double {mustBeNonnegative}
                b     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
            val = c_VT * b * S_ref / L_VT;
        end

    end
end

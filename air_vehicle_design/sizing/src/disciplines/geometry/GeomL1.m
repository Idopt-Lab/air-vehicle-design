classdef GeomL1
%GEOML1  Level-1 geometry static toolbox: statistical regression from TOGW.
%
%   Call as GeomL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16GeomL1, etc.) inherit
%   from GeometryModelL1 and call these statics to implement each abstract method.
%
%   EQUATIONS:
%     Total S_wet:
%       S_wet = 10^c * W_TO^d
%       Roskam, Airplane Design Vol. I, Table 3.5 [Jan Roskam, 1997]
%       Jet fighter: c = -0.1289, d = 0.7506
%
%     Fuselage length:
%       L_fus = a * W_TO^C
%       Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Table 6.3
%       [Daniel P. Raymer, AIAA, 2018]
%       Jet fighter: a = 0.93, C = 0.39
%
%     Equivalent aspect ratio (Task 2, GeomL1.md):
%       AR_eq = a * M_max^C   [Raymer 7th ed., Table 4.1, "Jet fighter
%       (dogfighter)" row only]   a = 5.416, C = -0.6222
%
%     Tail volume coefficients (Task 2, GeomL1.md):
%       S_HT = c_HT * cbar * S_ref / L_HT
%       S_VT = c_VT * b    * S_ref / L_VT
%       [Raymer 7th ed., Table 6.4, "Jet fighter" row]  c_HT_base = 0.40,
%       c_VT_base = 0.07, with F-16-specific text corrections applied (RSS
%       flight-control system, all-moving tail) — see compute_tail_volume_coeffs.
%       Tail arm: L_HT = L_VT = 0.475*L_fus (Raymer aft-single-engine text
%       rule, midpoint of stated 0.45-0.50 range).
%
%     Control-surface chord fractions (Task 2, GeomL1.md):
%       [Raymer 7th ed., Table 6.5, "Jet fighter" row]  elevator C_e/c=0.30
%       (all-moving-tail row value), rudder C_r/c=0.33.  Aileron fraction is
%       NOT available in the given table — lookup errors explicitly rather
%       than fabricating a value (see lookup_control_surface_fraction).

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet_statistical(obj, W_TO)
        %GET_S_WET_STATISTICAL  Total S_wet from Roskam Vol. I Table 3.5 regression.
        %   Reads obj.aircraft_category.
            val = GeomL1.compute_s_wet_regression(obj.aircraft_category, W_TO);
        end

        function val = get_L_fus(obj, W_TO)
        %GET_L_FUS  Fuselage length from Raymer 6th ed. Table 6.3 regression.
        %   Reads obj.aircraft_category.
            val = GeomL1.compute_l_fus_regression(obj.aircraft_category, W_TO);
        end

        function val = get_AR_eq(obj)
        %GET_AR_EQ  Equivalent aspect ratio from Raymer 7th ed. Table 4.1
        %   "Jet fighter (dogfighter)" row.  Reads obj.aircraft_category,
        %   obj.M_max.
            val = GeomL1.compute_AR_eq(obj.aircraft_category, obj.M_max);
        end

        function val = get_control_surface_fraction(obj, surface)
        %GET_CONTROL_SURFACE_FRACTION  Chord fraction (C/c) for a named
        %   control surface, Raymer 7th ed. Table 6.5 "Jet fighter" row.
        %   Reads obj.aircraft_category.  surface: 'elevator' | 'rudder'
        %   ('aileron' errors explicitly — see lookup_control_surface_fraction).
            val = GeomL1.compute_control_surface_fraction(obj.aircraft_category, surface);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/strings, no object access.
        % ================================================================== %

        function val = compute_s_wet_regression(aircraft_category, W_TO)
        %COMPUTE_S_WET_REGRESSION  S_wet = 10^c * W_TO^d  (Roskam Vol. I Table 3.5).
            [c, d] = GeomL1.lookup_swet(aircraft_category);
            val = 10^c * W_TO^d;
        end

        function val = compute_l_fus_regression(aircraft_category, W_TO)
        %COMPUTE_L_FUS_REGRESSION  L_fus = a * W_TO^C  (Raymer 6th ed. Table 6.3).
            [a, C] = GeomL1.lookup_lfus(aircraft_category);
            val = a * W_TO^C;
        end

        function [c, d] = lookup_swet(cat)
        %LOOKUP_SWET  Roskam Vol. I Table 3.5: S_wet = 10^c * W_TO^d.
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
        %LOOKUP_LFUS  Raymer 6th ed. Table 6.3: L_fus = a * W_TO^C  (ft, lbf).
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

        % ================================================================== %
        % Task 2 (2026-07-22): AR_eq, tail-volume coefficients, and
        % control-surface chord fractions.  See GeomL1.md's "Task 2" section
        % for the full derivation/citation trail.
        % ================================================================== %

        function val = compute_AR_eq(aircraft_category, M_max)
        %COMPUTE_AR_EQ  AR_eq = a * M_max^C  (Raymer 7th ed. Table 4.1,
        %   "Jet fighter (dogfighter)" row only).
            arguments
                aircraft_category
                M_max (1,1) double {mustBePositive}
            end
            [a, C] = GeomL1.lookup_AR_eq(aircraft_category);
            val = a * M_max^C;
        end

        function [a, C] = lookup_AR_eq(cat)
        %LOOKUP_AR_EQ  Raymer 7th ed. Table 4.1 "Jet fighter (dogfighter)"
        %   row ONLY: AR_eq = a*M_max^C.  Table 4.1's other rows (other
        %   fighter subtypes, transports, etc.) are not implemented and must
        %   not be guessed — any other aircraft_category errors explicitly.
            switch cat
                case 'jet_fighter',    a = 5.416; C = -0.6222;   % "Jet fighter (dogfighter)" row
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for AR_eq — only the Raymer 7th ed. Table 4.1 "Jet fighter (dogfighter)" row is implemented. Add it to GeomL1.lookup_AR_eq.', cat);
            end
        end

        function [c_HT, c_VT] = compute_tail_volume_coeffs(aircraft_category, has_rss, has_all_moving_tail)
        %COMPUTE_TAIL_VOLUME_COEFFS  Raymer 7th ed. Table 6.4 "Jet fighter"
        %   row base coefficients (c_HT_base=0.40, c_VT_base=0.07), with
        %   optional Raymer text corrections applied:
        %     has_rss             — active/computerized FCS, relaxed static
        %                            stability: c_HT, c_VT *= (1 - 0.10)
        %     has_all_moving_tail — all-moving stabilator (HT-only):
        %                            c_HT *= (1 - 0.125)  [midpoint of
        %                            Raymer's stated 0.10-0.15 range]
        %   For the F-16 (has_rss=true, has_all_moving_tail=true):
        %     c_HT = 0.40*(1-0.10)*(1-0.125) = 0.315
        %     c_VT = 0.07*(1-0.10)           = 0.063
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
        %LOOKUP_TAIL_VOLUME_COEFFS  Raymer 7th ed. Table 6.4 "Jet fighter"
        %   row base coefficients (before any text corrections).
            switch cat
                case 'jet_fighter', c_HT = 0.40; c_VT = 0.07;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for tail-volume coefficients — only the Raymer 7th ed. Table 6.4 "Jet fighter" row is implemented. Add it to GeomL1.lookup_tail_volume_coeffs.', cat);
            end
        end

        function L = compute_tail_arm(L_fus)
        %COMPUTE_TAIL_ARM  L_HT = L_VT = 0.475*L_fus.
        %   Raymer's aft-fuselage-mounted-single-engine text rule approximates
        %   the tail moment arm as a fraction of fuselage length, stated as a
        %   range 0.45-0.50; midpoint 0.475 chosen (F-16 is single-engine,
        %   aft-mounted).
            arguments
                L_fus (1,1) double {mustBePositive}
            end
            L = 0.475 * L_fus;
        end

        function val = compute_S_HT(c_HT, cbar, S_ref, L_HT)
        %COMPUTE_S_HT  S_HT = c_HT*cbar*S_ref/L_HT  (Raymer 7th ed. Table 6.4).
        %   L_HT guarded positive since it is this formula's denominator.
            arguments
                c_HT  (1,1) double {mustBeNonnegative}
                cbar  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
            end
            val = c_HT * cbar * S_ref / L_HT;
        end

        function val = compute_S_VT(c_VT, b, S_ref, L_VT)
        %COMPUTE_S_VT  S_VT = c_VT*b*S_ref/L_VT  (Raymer 7th ed. Table 6.4).
        %   L_VT guarded positive since it is this formula's denominator.
            arguments
                c_VT  (1,1) double {mustBeNonnegative}
                b     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
            val = c_VT * b * S_ref / L_VT;
        end

        function val = compute_control_surface_fraction(aircraft_category, surface)
        %COMPUTE_CONTROL_SURFACE_FRACTION  Chord fraction C/c for a named
        %   control surface (Raymer 7th ed. Table 6.5 "Jet fighter" row).
            val = GeomL1.lookup_control_surface_fraction(aircraft_category, surface);
        end

        function val = lookup_control_surface_fraction(cat, surface)
        %LOOKUP_CONTROL_SURFACE_FRACTION  Raymer 7th ed. Table 6.5 "Jet
        %   fighter" row: elevator C_e/c=0.30 (supersonic all-moving-tail row
        %   value, not a hinged-elevator chord fraction), rudder C_r/c=0.33.
        %
        %   GAP: the "Jet fighter" row (as given) does not include an aileron
        %   chord-fraction value. Do NOT fabricate one — 'aileron' errors
        %   explicitly (GeomL1:unknownControlSurface) so a later-phase test
        %   requiring it fails loudly instead of silently substituting a
        %   plausible-looking number or a different table's value.
            switch cat
                case 'jet_fighter'
                    switch surface
                        case 'elevator', val = 0.30;
                        case 'rudder',   val = 0.33;
                        case 'aileron'
                            error('GeomL1:unknownControlSurface', ...
                                'Aileron chord fraction is not available in Raymer 7th ed. Table 6.5 "Jet fighter" row as given to this toolbox — not implemented, not guessed.');
                        otherwise
                            error('GeomL1:unknownControlSurface', ...
                                'Unknown control surface "%s". Add it to GeomL1.lookup_control_surface_fraction.', surface);
                    end
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s" for control-surface fractions — only the Raymer 7th ed. Table 6.5 "Jet fighter" row is implemented. Add it to GeomL1.lookup_control_surface_fraction.', cat);
            end
        end

    end
end

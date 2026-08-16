classdef TailL1
%TAILL1  Level-1 tail-sizing static toolbox: volume-coefficient method.
%
%   Call as TailL1.method(...); never instantiated. F16TailL1 inherits
%   TailSizingModelL1 and delegates to these statics.
%
%   METHOD [Raymer 7th ed., 2018, Table 6.4 + text]:
%     L_HT = L_VT = 0.475 * L_fus     [aft single-engine text rule;
%                                      midpoint of the 0.45-0.50 range]
%     S_VT = c_VT * b    * S_ref / L_VT     [Table 6.4]
%     S_HT = c_HT * cbar * S_ref / L_HT     [Table 6.4]
%
%   Base coefficients come from an aircraft-category Table 6.4 row, then get
%   two independent per-aircraft text corrections: relaxed static stability
%   (RSS, -10% on both c_HT/c_VT) and an all-moving stabilator (-12.5% on
%   c_HT). The F-16 has both, giving c_HT=0.315, c_VT=0.063. Only the
%   jet-fighter and jet-transport rows are implemented; any other category
%   errors.
%
%   History and rationale: docs/decision_log.md;
%   TailSizing_scribe_plan.md Sec. 2. Companion doc: TailL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the concrete object, return the result.
        % ================================================================== %

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  HT and VT reference areas [ft^2].  [Raymer 7th ed. Table 6.4
        %   + text]  obj must expose corrected c_HT/c_VT (see F16TailL1).
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt).
            arguments
                obj
                S_ref (1,1) double {mustBePositive}
                b     (1,1) double {mustBePositive}
                cbar  (1,1) double {mustBePositive}
                L_fus (1,1) double {mustBePositive}
            end
            L_HT = TailL1.compute_tail_arm(L_fus);
            L_VT = L_HT;
            S_ht = TailL1.compute_S_HT(obj.c_HT, cbar, S_ref, L_HT);
            S_vt = TailL1.compute_S_VT(obj.c_VT, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access.
        % ================================================================== %

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
            [c_HT, c_VT] = TailL1.lookup_tail_volume_coeffs(aircraft_category);
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
                case 'jet_transport'
                    % Jet-transport typical tail-volume coefficients.
                    % [metabook_data.md Ch.8 Eqs. 8.1/8.2, lines 599-600:
                    %  "cVT ~ 0.09 jet transports", "cHT ~ 1.0 jet transports";
                    %  agrees with Raymer 7th ed. Table 6.4 jet-transport row.]
                    c_HT = 1.00; c_VT = 0.09;
                otherwise
                    error('TailL1:unknownCategory', ...
                        ['Unknown aircraft_category "%s" for tail-volume ' ...
                         'coefficients -- only the Raymer 7th ed. Table 6.4 ' ...
                         'jet-fighter and jet-transport rows are implemented.'], cat);
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

        function L = compute_tail_arm_wing_mounted(L_fus)
        %COMPUTE_TAIL_ARM_WING_MOUNTED  Tail moment arm [ft] for a
        %   wing-mounted-engine transport, as a fraction of fuselage length.
        %     L_HT = L_VT = 0.525 * L_fus  [Raymer text, wing-mounted-engine
        %     transport tail arm 50-55% of fuselage length; 0.525 is the
        %     midpoint].
        %
        %   *** UNCITED IN THE REPO EXTRACTS *** Labeled TODO per repo
        %   citation policy: a deliberately-failing testTODO must guard it
        %   until the Raymer text is transcribed. Do NOT cite to
        %   metabook_data.md. See docs/decision_log.md.
            arguments
                L_fus (1,1) double {mustBePositive}
            end
            L = 0.525 * L_fus;   % [UNCITED -- see the TODO above]
        end

        function val = compute_S_HT(c_HT, cbar, S_ref, L_HT)
        %COMPUTE_S_HT  Horizontal-tail area [ft^2].  [Raymer 7th ed. Table 6.4]
            arguments
                c_HT  (1,1) double {mustBeNonnegative}
                cbar  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
            end
            val = TailSizingBase.tail_volume_area(c_HT, cbar, S_ref, L_HT);
        end

        function val = compute_S_VT(c_VT, b, S_ref, L_VT)
        %COMPUTE_S_VT  Vertical-tail area [ft^2].  [Raymer 7th ed. Table 6.4]
            arguments
                c_VT  (1,1) double {mustBeNonnegative}
                b     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
            val = TailSizingBase.tail_volume_area(c_VT, b, S_ref, L_VT);
        end

    end
end

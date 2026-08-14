classdef TailL1
%TAILL1  Level-1 tail-sizing static toolbox: volume-coefficient method.
%
%   Call as TailL1.method(...); never instantiated, not in the inheritance
%   chain. F16TailL1 inherits TailSizingModelL1 and delegates to these
%   statics.
%
%   METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
%   2018, Table 6.4 + accompanying text]:
%
%     L_HT = L_VT = 0.475 * L_fus     [aft-mounted single-engine text rule;
%                                      0.475 is the midpoint of the stated
%                                      0.45-0.50 range]
%     S_VT = c_VT * b    * S_ref / L_VT     [Table 6.4]
%     S_HT = c_HT * cbar * S_ref / L_HT     [Table 6.4]
%
%   Base coefficients are looked up by aircraft category (a Table 6.4 row),
%   then corrected by two independent text rules that apply per-aircraft:
%   relaxed static stability (RSS, -10% on both c_HT/c_VT) and an
%   all-moving stabilator (-12.5% on c_HT only). Both corrections are
%   generic, category-driven statics (compute_tail_volume_coeffs /
%   lookup_tail_volume_coeffs) so a different aircraft's Tier-3 class can
%   apply a different combination -- F16TailL1's constructor calls
%   compute_tail_volume_coeffs('jet_fighter', true, true), since the F-16
%   has both properties, giving c_HT=0.315, c_VT=0.063.
%
%   MIGRATION NOTE (2026-07-28): these statics are PORTED, not re-derived,
%   from the orphaned src/disciplines/geometry/GeomL1.m methods of the same
%   names (compute_tail_volume_coeffs, lookup_tail_volume_coeffs,
%   compute_tail_arm, compute_S_HT, compute_S_VT) -- see
%   TailSizing_scribe_plan.md Sec. 2 for the full discrepancy-resolution
%   record: two competing L1 tail-sizing implementations existed in this
%   repo (the live TailSizingLevel1.m, 0.40/0.07/6th-ed./0.5*L_fus, and this
%   orphaned, never-called GeomL1 set, 7th-ed./0.475*L_fus plus text
%   corrections); this is the corrected one, adopted as canonical.
%   GeomL1.m has had these five methods DELETED as part of this migration
%   -- tail sizing is not geometry's job.
%
%   Only the jet-fighter row is implemented; any other category errors
%   rather than being guessed.
%
%   Companion doc: src/disciplines/tail_sizing/TailL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the concrete object, return the result.
        % ================================================================== %

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  obj must expose c_HT/c_VT
        %   (the F-16's net, corrected coefficients -- see F16TailL1).
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
        %
        %   L_HT = L_VT = 0.525 * L_fus  [Raymer text, wing-mounted-engine
        %   transport tail arm 50-55% of fuselage length; 0.525 is the
        %   midpoint of that range].
        %
        %   *** UNCITED IN THE REPO EXTRACTS ***  metabook_data.md does NOT
        %   carry the wing-mounted-engine 50-55% tail-arm rule (its Ch.8 has
        %   only the tail-volume coefficients, not the arm fraction), and no
        %   other docs/reference_extracts/ file transcribes it. The 0.525
        %   value is therefore a labeled TODO per repo citation policy: it is
        %   used so the B777 path is functional, but a deliberately-failing
        %   testTODO must guard it in the tail tests until the printed Raymer
        %   text is transcribed into an extract. Do NOT cite this to
        %   metabook_data.md.
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

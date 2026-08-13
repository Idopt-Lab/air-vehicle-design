classdef TailL1
%TAILL1  Level-1 tail-sizing static toolbox: volume-coefficient method.
%
%   Call as TailL1.method(...); never instantiated, not in the inheritance
%   chain. F16TailL1 inherits TailSizingModelL1 and delegates to these
%   statics.
%
%   METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
%   2018, Table 6.4 + accompanying text; the same section is Sec. 6.5.2,
%   Eqs. (6.26)-(6.29) and Table 6.4 in the 6th ed., pp.158-160, which is the
%   edition docs/reference_extracts/Raymer_Aircraft_Design_6ed/
%   06_initial_sizing.md transcribes and the source of every quotation below]:
%
%     S_VT = c_VT * b    * S_ref / L_VT     [Eq. (6.28) / Table 6.4]
%     S_HT = c_HT * cbar * S_ref / L_HT     [Eq. (6.29) / Table 6.4]
%
%   WHAT L_HT AND L_VT ARE (corrected 2026-08-11 -- this was the tail-sizing
%   definition bug). Raymer, Sec. 6.5.2, p.158, defines the moment arm
%   verbatim as: "Moment arm L is approximated as tail-quarter-chord to
%   wing-quarter-chord distance." It is a station-to-station distance in the
%   LAYOUT, not a fraction of fuselage length. The fuselage-length fraction
%   ("front-mounted prop engine ~60%; wing-mounted engines ~50-55%;
%   aft-mounted engines ~45-50%; sailplane ~65%", p.160) is Raymer's own
%   APPROXIMATION OF THAT SAME QUANTITY for the stage where no layout exists
%   yet -- he introduces it with "Moment arm is approximated AT THIS STAGE as
%   a percent of fuselage length" (p.159, emphasis added). Nicolai &
%   Carichner define the same arm c.g.-referenced instead; see TailL2.m.
%
%   size() therefore RECEIVES L_HT and L_VT rather than computing them from
%   L_fus: whoever holds the layout (a GeometryModelL2/L3 object, via its
%   Dependent L_HT/L_VT) owns the arm, and TailL1 owns only the volume-
%   coefficient equation. compute_tail_arm(L_fus) is kept for the genuine
%   no-layout case -- GeometryModelL1 has no planform at all, so Raymer's
%   stage-appropriate fraction is the only cited option there.
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

        function result = size(obj, S_ref, b, cbar, L_HT, L_VT)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 6th ed. Eqs. (6.28)/(6.29), Table 6.4 + text]  obj must
        %   expose c_HT/c_VT (the F-16's net, corrected coefficients -- see
        %   F16TailL1).
        %
        %   SIGNATURE CHANGED 2026-08-11: the fifth argument was L_fus and the
        %   arm was computed inside as 0.475*L_fus. It is now the ARM ITSELF,
        %   supplied by the caller, and the vertical tail gets its own arm --
        %   Raymer prints separate L_VT/L_HT in Eqs. (6.28)/(6.29), and once
        %   the arms come from real stations they genuinely differ (the VT mac
        %   quarter-chord is not the HT mac quarter-chord). See this file's
        %   header for the definition and for why the fuselage fraction was
        %   only ever an approximation of this quantity.
        %
        %   L_HT -- wing mac c/4 to HORIZONTAL-tail mac c/4 distance, ft
        %   L_VT -- wing mac c/4 to VERTICAL-tail   mac c/4 distance, ft
        %   (Both available live as GeometryModelL2/L3's Dependent L_HT/L_VT;
        %   a caller with no layout at all uses compute_tail_arm(L_fus) for
        %   both, which is what the pre-2026-08-11 behaviour was.)
        %
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt).
            arguments
                obj
                S_ref (1,1) double {mustBePositive}
                b     (1,1) double {mustBePositive}
                cbar  (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
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
                otherwise
                    error('TailL1:unknownCategory', ...
                        ['Unknown aircraft_category "%s" for tail-volume ' ...
                         'coefficients -- only the Raymer 7th ed. Table 6.4 ' ...
                         'jet-fighter row is implemented.'], cat);
            end
        end

        function L = compute_tail_arm(L_fus)
        %COMPUTE_TAIL_ARM  PRE-LAYOUT APPROXIMATION of the tail moment arm
        %   [ft], as a fraction of fuselage length.
        %   [Raymer 6th ed. Sec. 6.5.2, p.159-160: "Moment arm is approximated
        %   at this stage as a percent of fuselage length", with "aft-mounted
        %   engines ~45-50%" for this configuration; 0.475 is the midpoint of
        %   that stated range. Same rule, 7th ed.]
        %
        %   THIS IS NOT AN ALTERNATIVE DEFINITION of the arm (clarified
        %   2026-08-11). Raymer's arm is defined on p.158 as the tail-mac
        %   quarter-chord to wing-mac quarter-chord distance; this fraction is
        %   his estimate of THAT distance before a layout exists. Use it only
        %   where no layout exists -- i.e. at L1, where GeometryModelL1 has no
        %   planform, no apex station and no sweep. Where the layout IS
        %   available (L2/L3 geometry), use
        %   compute_tail_arm_quarter_chord against real stations: for the
        %   F-16A the fraction gives 22.09 ft against a real 15.09 ft, +46 %,
        %   and S_HT is inversely proportional to it.
            arguments
                L_fus (1,1) double {mustBePositive}
            end
            L = 0.475 * L_fus;
        end

        function L = compute_tail_arm_quarter_chord(x_c4_tail, x_c4_wing)
        %COMPUTE_TAIL_ARM_QUARTER_CHORD  Tail moment arm [ft], Raymer's own
        %   definition: the distance from the WING mac quarter-chord to the
        %   TAIL mac quarter-chord.
        %   [Raymer 6th ed. Sec. 6.5.2, p.158, verbatim: "Moment arm L is
        %   approximated as tail-quarter-chord to wing-quarter-chord
        %   distance."  Fig. 6.2, p.159, draws it.]
        %
        %     L = x_c/4,tail - x_c/4,wing
        %
        %   Both stations are built with
        %   GeometryBase.compute_y_mac(_panel)/compute_x_mac_le/
        %   compute_x_mac_quarter_chord from each surface's own apex station,
        %   LE sweep, span and taper. The wing quarter-MAC station this
        %   subtracts is also the conceptual-design c.g. reference: Raymer
        %   states the arm against the wing c/4 rather than a computed c.g.
        %   precisely so tail sizing does not need a c.g. it cannot yet have
        %   (Nicolai & Carichner, Sec. 11.1, p.284, makes the same point
        %   explicitly -- "c.g. location depends on knowing tail-surface
        %   weight (size) -- a circular dependency. Thus tail surfaces are
        %   sized here via a shortcut"). Feeding a fully-computed c.g. back in
        %   would restore the circularity the method exists to break; see
        %   TailL2.compute_x_cg_initial for Nicolai's own stated stand-in.
        %
        %   x_c4_tail must lie aft of x_c4_wing for a conventional aft tail;
        %   the guard below rejects a non-positive arm rather than returning a
        %   negative area from Eq. (6.28)/(6.29). A canard is a DIFFERENT
        %   method [Raymer Sec. 6.5.2 "Canard"; Nicolai Eq. (11.3)] and is not
        %   implemented here.
            arguments
                x_c4_tail (1,1) double {mustBeReal}
                x_c4_wing (1,1) double {mustBeReal}
            end
            L = x_c4_tail - x_c4_wing;
            if L <= 0
                error('TailL1:nonPositiveTailArm', ...
                    ['Tail mac quarter-chord (%.4f ft) is not aft of the wing ' ...
                     'mac quarter-chord (%.4f ft), so the aft-tail moment arm ' ...
                     'is %.4f ft. Raymer Eq. (6.29) divides by it. A forward ' ...
                     'surface is a canard and needs Raymer Sec. 6.5.2''s ' ...
                     'canard method / Nicolai Eq. (11.3), not this one.'], ...
                    x_c4_tail, x_c4_wing, L);
            end
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

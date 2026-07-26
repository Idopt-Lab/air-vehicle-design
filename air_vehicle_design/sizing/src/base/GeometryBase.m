classdef (Abstract) GeometryBase < handle
%GEOMETRYBASE  Tier-1 abstract enforcer for all geometry discipline classes.
%
%   Declares ONLY the methods orchestrators (ConstraintAnalysis, SizingLoop,
%   MissionAnalysis) call. No equations, no coefficients.
%
%   Inheritance chain per fidelity level:
%     GeometryBase → GeometryModelLN (abstract) → GeomLN (toolbox) → F16GeomLN

properties (Abstract)
    S_ref
    S_wet
end

    methods (Abstract)
        %GET_S_REF  Wing reference area, ft^2.
        val = get_S_ref(obj)

        %GET_S_WET  Total aircraft wetted area, ft^2.
        %   W_TO is takeoff gross weight in lbf, needed only by L1's
        %   statistical regression (S_wet can't be known from geometry alone
        %   at L1 -- it's a TOGW-based regression). This abstract stub keeps
        %   the (obj, W_TO) signature as the widest case any implementer
        %   might need, but MATLAB does NOT enforce matching arity between an
        %   abstract declaration and its concrete override (verified
        %   2026-07-22) -- so a concrete class that doesn't need W_TO is free
        %   to implement get_S_wet(obj) with no second parameter at all.
        %
        %   RESOLVED (2026-07-22, user decision): F16GeomL2's get_S_wet no
        %   longer takes a W_TO argument -- L2 has real planform geometry and
        %   never needed it (the old signature just carried an ignored `~`
        %   parameter). Call it as obj.get_S_wet() with zero arguments. L1
        %   (F16GeomL1) still requires get_S_wet(obj, W_TO) -- it's a genuine
        %   dependency there, not boilerplate. See
        %   src/disciplines/geometry/GeomL2.md's dated note.
        val = get_S_wet(obj, W_TO)
    end

    methods (Static)
        % ================================================================== %
        % Fidelity-independent planform identities (Task 2, approved
        % 2026-07-21/22 -- see GeometryBase.md). Concrete/computed for every
        % L>=2 fidelity level; equations never change with fidelity, only the
        % inputs feeding them do. Kept here (Base tier, Static) rather than
        % duplicated per-fidelity toolbox, matching AerodynamicsBase's
        % existing pattern of concrete utility methods shared unchanged
        % across fidelity levels.
        % ================================================================== %

        function c_root = compute_root_chord(S_ref, b, lambda)
        %COMPUTE_ROOT_CHORD  c_root = 2*S_ref / (b*(1+lambda))
        %   Raymer, Aircraft Design: A Conceptual Approach, 7th ed., Eq. 7.6.
        %   S_ref   — reference (full) planform area, ft^2
        %   b       — span, ft
        %   lambda  — taper ratio (c_tip/c_root); mustBeNonnegative guards
        %             the (1+lambda) denominator against lambda=-1.
            arguments
                S_ref  (1,1) double {mustBePositive}
                b      (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            c_root = 2 * S_ref / (b * (1 + lambda));
        end

        function c_tip = compute_tip_chord(c_root, lambda)
        %COMPUTE_TIP_CHORD  c_tip = lambda * c_root
        %   Raymer 7th ed., Eq. 7.7.
            arguments
                c_root (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            c_tip = lambda * c_root;
        end

        function cbar = compute_mac(c_root, lambda)
        %COMPUTE_MAC  cbar = (2/3)*c_root*(1 + lambda + lambda^2)/(1 + lambda)
        %   Mean aerodynamic chord.  Raymer 7th ed., Eq. 7.8.
        %   lambda guarded nonnegative for the same (1+lambda) denominator
        %   reason as compute_root_chord.
            arguments
                c_root (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            cbar = (2/3) * c_root * (1 + lambda + lambda^2) / (1 + lambda);
        end

        function b = compute_span(AR, S_ref)
        %COMPUTE_SPAN  b = sqrt(AR * S_ref)
        %   Definitional (AR ≡ b^2/S_ref by definition of aspect ratio) — not
        %   a numbered textbook equation.
            arguments
                AR    (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            b = sqrt(AR * S_ref);
        end

        function Lambda_x_deg = convert_sweep(Lambda_LE_deg, AR, lambda, x)
        %CONVERT_SWEEP  Convert LE sweep to sweep at chord-fraction station x,
        %   for a MIRRORED surface (wing, conventional horizontal tail).
        %   tan(Lambda_x) = tan(Lambda_LE) - (4/AR)*x*(1-lambda)/(1+lambda)
        %   x=0.25 -> quarter-chord sweep, x=1.0 -> trailing-edge sweep, etc.
        %
        %   MIRRORED ONLY. The 4/AR coefficient assumes root->tip spans the
        %   SEMIspan b/2 with AR = b^2/S on the full mirrored planform:
        %     tan(Lambda_x) = tan(Lambda_LE) - x*(c_root - c_tip)/(b/2)
        %   and substituting c_root = 2S/(b(1+lambda)) (compute_root_chord)
        %   gives 4x*S*(1-lambda)/(b^2*(1+lambda)) = (4/AR)*x*(1-lambda)/(1+lambda).
        %   For a SINGLE-PANEL surface (vertical tail), where root->tip spans
        %   the full b, the same derivation gives 2/AR instead -- use
        %   convert_sweep_panel. Passing a single-panel AR here double-counts
        %   the taper term (fixed 2026-07-25: the F-16's VT trailing-edge sweep
        %   read a physically impossible 0.33 deg instead of 22.90 deg).
        %
        %   CITATION: standard swept-wing planform geometry identity —
        %   uncited to a specific textbook edition/equation number (no
        %   Raymer/Roskam edition+eq# could be pinned down against the
        %   references available in this repo; see GeometryBase.md's
        %   "Sweep-angle conversion" section, RESOLVED 2026-07-21 user
        %   decision: cite as a standard identity rather than guess a number).
            arguments
                Lambda_LE_deg (1,1) double {mustBeGreaterThanOrEqual(Lambda_LE_deg,-90), mustBeLessThanOrEqual(Lambda_LE_deg,90)}
                AR            (1,1) double {mustBePositive}
                lambda        (1,1) double {mustBeNonnegative}
                x             (1,1) double {mustBeGreaterThanOrEqual(x,0), mustBeLessThanOrEqual(x,1)}
            end
            tan_Lambda_x = tand(Lambda_LE_deg) - (4/AR) * x * (1 - lambda) / (1 + lambda);
            Lambda_x_deg = atand(tan_Lambda_x);
        end

        function Lambda_x_deg = convert_sweep_panel(Lambda_LE_deg, AR, lambda, x)
        %CONVERT_SWEEP_PANEL  Convert LE sweep to sweep at chord-fraction
        %   station x, for a SINGLE-PANEL surface (vertical tail).
        %   tan(Lambda_x) = tan(Lambda_LE) - (2/AR)*x*(1-lambda)/(1+lambda)
        %
        %   Single-panel counterpart of convert_sweep (see its header for the
        %   mirrored 4/AR form and why the two differ). A vertical tail is one
        %   panel: root->tip spans the FULL span b, and AR = b^2/S is defined on
        %   that single panel, so
        %     tan(Lambda_x) = tan(Lambda_LE) - x*(c_root - c_tip)/b
        %   with c_root = 2S/(b(1+lambda)) (compute_root_chord holds unchanged
        %   for a single panel, since S = b*c_root*(1+lambda)/2 either way)
        %   giving 2x*S*(1-lambda)/(b^2*(1+lambda)) = (2/AR)*x*(1-lambda)/(1+lambda)
        %   -- exactly half the mirrored coefficient.
        %
        %   Verified against the repo's own F-16 VT chords (readme_geom.md
        %   Sec. 4.3: S_vt=60, AR_vt=1.6, lambda_vt=0.5 -> b_vt=9.798,
        %   c_root=8.165, c_tip=4.082): with Lambda_LE=40 deg this returns
        %   TE sweep 22.90 deg and quarter-chord sweep 36.31 deg, matching a
        %   direct chord-geometry calculation. (Introduced 2026-07-25.)
        %
        %   CITATION: same standard planform-geometry identity as
        %   convert_sweep, specialized to a single panel — see that method's
        %   citation note.
            arguments
                Lambda_LE_deg (1,1) double {mustBeGreaterThanOrEqual(Lambda_LE_deg,-90), mustBeLessThanOrEqual(Lambda_LE_deg,90)}
                AR            (1,1) double {mustBePositive}
                lambda        (1,1) double {mustBeNonnegative}
                x             (1,1) double {mustBeGreaterThanOrEqual(x,0), mustBeLessThanOrEqual(x,1)}
            end
            tan_Lambda_x = tand(Lambda_LE_deg) - (2/AR) * x * (1 - lambda) / (1 + lambda);
            Lambda_x_deg = atand(tan_Lambda_x);
        end

        % ------------------------------------------------------------------ %
        % Fuselage / nacelle identities (added 2026-07-25, Phase 2). Placed
        % here for the same reason as the planform identities above: both are
        % fidelity-INDEPENDENT and are called by more than one tier
        % (F16GeomL2 and F16GeomL3 both use them), so neither belongs in a
        % per-fidelity toolbox. They were briefly authored into GeomL3 during
        % Phase 2, which made the L2 concrete class depend on the L3 toolbox —
        % a layering inversion; moved here to remove it.
        % ------------------------------------------------------------------ %

        function val = compute_Amax_elliptical(W_max, H_max)
        %COMPUTE_AMAX_ELLIPTICAL  Maximum cross-sectional area of an equivalent
        %   elliptical-section fuselage:
        %       Amax = (pi/4) * W_max * H_max
        %   i.e. the area of an ellipse with semi-axes W_max/2 and H_max/2 —
        %   the maximum cross-section of the very same equivalent elliptical
        %   fuselage the rest of the geometry model already assumes when it
        %   feeds D_fus = (W+H)/2 into Roskam Eq. 12.3.
        %
        %   Consumed by the Raymer 6th ed. Eq. 12.44 Sears-Haack supersonic
        %   wave-drag term as (Amax/L_aircraft)^2.
        %
        %   CITATION: standard elliptical-cross-section identity. Stated
        %   plainly: NO Raymer, Roskam, Mattingly or Brandt equation number is
        %   known for it — it appears in no reference extract in this repo. It
        %   is documented as a standard identity following the precedent already
        %   set for convert_sweep above (see GeometryBase.md, RESOLVED
        %   2026-07-21 user decision). No equation number was invented.
        %   TODO: pin a citation, or accept the standard-identity status in
        %   writing — STANDING OPEN item, VnV/BrandtF16A/todo.md 2026-07-25
        %   Phase 2 §4.
        %
        %   Brandt comparison target, never an input: Geom!B20 = Geom!H47 =
        %   25.110556 ft^2, itself a whole-aircraft area-ruled MAX(H26:H45) =
        %   32.971053 NET of an N_eng*pi*D^2/5 = 7.8605 engine flow-through
        %   deduction. That is a DIFFERENT QUANTITY from this envelope figure
        %   (F-16A: 27.4889, +9.47 % vs 25.110556, -16.6 % vs the raw max), so
        %   the report row is annotated `definitional`, not an agreement check
        %   (F16GeomL3.md §4; the /5-vs-/4 question is todo.md §5, OPEN).
            arguments
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            val = (pi/4) * W_max * H_max;
        end

        function val = compute_nacelle_diameter(T_AB_SLS_lb)
        %COMPUTE_NACELLE_DIAMETER  Engine/nacelle diameter from SLS afterburning
        %   thrust:
        %       D_nac = sqrt(T_AB_SLS_lb / 1900)      [ft, from lbf]
        %   F-16A: sqrt(23770/1900) = 3.537 ft.
        %
        %   [Brandt F-16A workbook, Engn(s) tab, D_engine; reproduced in
        %    VnV/BrandtF16A/readme_geom.md Section 3:
        %    "D_engine = sqrt(T_AB_SLS / 1900) = sqrt(23770/1900) = 3.537 ft"]
        %
        %   Extracted into a named, cited static in Phase 2 (2026-07-25): the
        %   expression previously existed ONLY inline in F16GeomL2.get.D_inlet,
        %   and Phase 2 needed it at L3 too — copying the literal 1900 would
        %   have duplicated an uncited magic number across two tiers
        %   (F16GeomL3.md §3 reuse gap 2; todo.md 2026-07-25 §12). Both
        %   F16GeomL2 and F16GeomL3 call this one method.
        %
        %   The 1900 lbf/ft^2 divisor is Brandt's own empirical thrust-density
        %   constant; no textbook equation number is claimed for it, only the
        %   workbook cell it comes from.
        %
        %   CAVEAT -- 1900 IS THE AFTERBURNING CONSTANT (found 2026-07-25 by a
        %   live COM read; VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §18). The
        %   workbook actually selects between two constants:
        %       Geom!C475 = IF(Main!C29 = Main!D29,
        %                      (T_AB / 'Engn(s)'!L10)^0.5,     % L10 = 2000, dry
        %                      (T_AB / 'Engn(s)'!L22)^0.5)     % L22 = 1900, AB
        %   'Engn(s)'!K13 labels the L22 block "Afterburning Engines". For the
        %   F-16A the test is false (Main!C29 = 15000 mil vs Main!D29 = 23770 AB),
        %   so 1900 is the correct branch and this method is numerically right
        %   for THIS aircraft. But the constant is hardcoded, so a
        %   NON-afterburning engine (T_mil == T_AB) would silently get the AB
        %   value and a nacelle ~2.6% too small. Left as a documented
        %   single-aircraft assumption rather than fixed here: making it
        %   conditional needs an is-afterburning input, which changes this
        %   signature and every call site for zero numeric effect on the F-16A.
        %   Revisit when a second aircraft or a dry engine appears.
        %
        %   NOTE the argument is ENGINE data, not airframe data: geometry
        %   receives it from the injected propulsion object (prop.T_SL), never
        %   as a geometry input — see F16GeomL2/F16GeomL3's T_AB_SLS_lb.
            arguments
                T_AB_SLS_lb (1,1) double {mustBePositive}
            end
            val = sqrt(T_AB_SLS_lb / 1900);
        end
    end
end

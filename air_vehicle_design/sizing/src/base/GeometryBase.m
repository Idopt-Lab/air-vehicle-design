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
        %CONVERT_SWEEP  Convert LE sweep to sweep at chord-fraction station x.
        %   tan(Lambda_x) = tan(Lambda_LE) - (4/AR)*x*(1-lambda)/(1+lambda)
        %   x=0.25 -> quarter-chord sweep, x=1.0 -> trailing-edge sweep, etc.
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
    end
end

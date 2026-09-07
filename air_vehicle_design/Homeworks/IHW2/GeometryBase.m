classdef (Abstract) GeometryBase < handle
%GEOMETRYBASE  Tier-1 abstract enforcer for all geometry discipline classes.
%
%   Declares the contract orchestrators call, plus the fidelity-independent
%   planform and fuselage identities every level shares.
%
%   Inheritance: GeometryBase -> GeometryModelLN (abstract) -> F16GeomLN
%   The GeomLN static toolboxes are NOT in this chain.
%
%   Companion doc: src/base/GeometryBase.md
%
%   REMOVED IN THIS PASS
%   Mod (08/19/2026) (Claude)
%   compute_nacelle_diameter(T_AB_SLS_lb) moved to the F-16 example, at
%   examples/F16A/models/disciplines/geom/F16GeomL2.m. The equation is
%   unchanged, so no number moves. Its TODOs travelled with it, verbatim:
%     % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
%     % TODO: the 1900 divisor is hardcoded and silently assumes an
%     %   afterburning engine -- Brandt uses 1900 only when T_dry ~= T_AB, and
%     %   2000 otherwise (todo.md 2026-07-25 Phase 2 §18).
%   Reason: the equation is Brandt's, and the divisor is an F-16 convention.
%   Recorded in GeometryBase.md.
%
%   compute_Amax_elliptical(W_max, H_max) moved to the F-16 example, at
%   examples/F16A/models/disciplines/geom/F16GeomL2.m (Casey, 2026-08-19). The
%   equation is unchanged, so no number moves. Its TODOs travelled with it,
%   verbatim:
%     % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
%     %   TODO: standard elliptical-cross-section identity with no known
%     %   textbook equation number. Pin a citation or accept the
%     %   standard-identity status in writing (todo.md 2026-07-25 Phase 2 §4).
%   Reason: F16GeomL2.get.Amax is the ONLY caller in the repo. L3 does not call
%   it -- L3 Amax is the area-ruled buildup -- and no other L2 geometry declares
%   Amax at all. Gate 4 argued the opposite and was wrong. Recorded in
%   GeometryBase.md.

properties (Abstract)
    S_ref   % ft^2 — wing reference area
    S_wet   % ft^2 — total aircraft wetted area
end

    methods (Abstract)
        %GET_S_REF  Wing reference area [ft^2].
        val = get_S_ref(obj)

        %GET_S_WET  Total aircraft wetted area [ft^2].
        %   The (obj, W_TO) signature is the widest any implementer needs: L1's
        %   regression takes gross weight, L2/L3 have real planform geometry and
        %   implement get_S_wet(obj). MATLAB does not enforce matching arity
        %   between an abstract declaration and its override.
        val = get_S_wet(obj, W_TO)
    end

    methods (Static)

        function c_root = compute_root_chord(S_ref, b, lambda)
        %COMPUTE_ROOT_CHORD  Root chord [ft].  [Raymer 7th ed. Eq. 7.6]
            arguments
                S_ref  (1,1) double {mustBePositive}
                b      (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            c_root = 2 * S_ref / (b * (1 + lambda));
        end

        function c_tip = compute_tip_chord(c_root, lambda)
        %COMPUTE_TIP_CHORD  Tip chord [ft].  [Raymer 7th ed. Eq. 7.7]
            arguments
                c_root (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            c_tip = lambda * c_root;
        end

        function cbar = compute_mac(c_root, lambda)
        %COMPUTE_MAC  Mean aerodynamic chord [ft].  [Raymer 7th ed. Eq. 7.8]
            arguments
                c_root (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            cbar = (2/3) * c_root * (1 + lambda + lambda^2) / (1 + lambda);
        end

        function b = compute_span(AR, S_ref)
        %COMPUTE_SPAN  Span [ft] from aspect ratio and reference area.
        %   Definitional (AR = b^2/S_ref).
            arguments
                AR    (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            b = sqrt(AR * S_ref);
        end

        function Lambda_x_deg = convert_sweep(Lambda_LE_deg, AR, lambda, x)
        %CONVERT_SWEEP  LE sweep -> sweep at chord fraction x [deg], MIRRORED
        %   surfaces (wing, conventional HT).
        %
        %   Use convert_sweep_panel for a single-panel surface (vertical tail);
        %   passing a single-panel AR here double-counts the taper term.
        %
        %   Standard planform-geometry identity; no textbook equation number
        %   could be pinned against the references in this repo.
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
        %CONVERT_SWEEP_PANEL  LE sweep -> sweep at chord fraction x [deg],
        %   SINGLE-PANEL surfaces (vertical tail).
        %
        %   Same identity as convert_sweep with half the coefficient, because
        %   root->tip spans the full b rather than the semispan. See
        %   GeometryBase.md for the derivation.
            arguments
                Lambda_LE_deg (1,1) double {mustBeGreaterThanOrEqual(Lambda_LE_deg,-90), mustBeLessThanOrEqual(Lambda_LE_deg,90)}
                AR            (1,1) double {mustBePositive}
                lambda        (1,1) double {mustBeNonnegative}
                x             (1,1) double {mustBeGreaterThanOrEqual(x,0), mustBeLessThanOrEqual(x,1)}
            end
            tan_Lambda_x = tand(Lambda_LE_deg) - (2/AR) * x * (1 - lambda) / (1 + lambda);
            Lambda_x_deg = atand(tan_Lambda_x);
        end

    end
end

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

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        function val = compute_Amax_elliptical(W_max, H_max)
        %COMPUTE_AMAX_ELLIPTICAL  Max cross-section of an equivalent elliptical
        %   fuselage [ft^2]. Feeds the Sears-Haack term [Raymer 6th ed. Eq. 12.44].
        %
        %   This is the LOW-fidelity, fuselage-only form used at L2. L3 computes
        %   a whole-aircraft area-ruled Amax instead (GeomL3.get_Amax).
        %
        %   TODO: standard elliptical-cross-section identity with no known
        %   textbook equation number. Pin a citation or accept the
        %   standard-identity status in writing (todo.md 2026-07-25 Phase 2 §4).
            arguments
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            val = (pi/4) * W_max * H_max;
        end

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        function val = compute_nacelle_diameter(T_AB_SLS_lb)
        %COMPUTE_NACELLE_DIAMETER  Engine/nacelle diameter [ft] from SLS
        %   afterburning thrust.  [Brandt F-16A.xls, Engn(s) tab, D_engine]
        %
        %   TODO: the 1900 divisor is hardcoded and silently assumes an
        %   afterburning engine — Brandt uses 1900 only when T_dry ~= T_AB, and
        %   2000 otherwise (todo.md 2026-07-25 Phase 2 §18).
            arguments
                T_AB_SLS_lb (1,1) double {mustBePositive}
            end
            val = sqrt(T_AB_SLS_lb / 1900);
        end

    end
end

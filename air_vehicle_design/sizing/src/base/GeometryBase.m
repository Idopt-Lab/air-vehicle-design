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

        % ------------------------------------------------------------------ %
        % MAC STATION (added 2026-08-11 with the tail-arm definition fix).
        %
        % These four statics build the x-station of a lifting surface's mean
        % aerodynamic chord and its quarter-chord point -- the reference
        % station BOTH tail-volume-coefficient methods measure the tail moment
        % arm between:
        %   [Raymer 6th ed. Sec. 6.5.2, p.158]  "Moment arm L is approximated
        %     as tail-quarter-chord to wing-quarter-chord distance."
        %   [Nicolai & Carichner, Eqs. (11.1)/(11.2), pp.286/289]  l_VT/l_HT =
        %     distance from the initial c.g. estimate to the quarter-chord of
        %     the tail mac (Fig. 11.1, p.285).
        % Before this addition no x_MAC/y_MAC quantity existed outside the
        % stability-and-control toolbox, which is why tail sizing had to fall
        % back on Raymer's pre-layout fuselage-length fraction.
        % ------------------------------------------------------------------ %

        function y = compute_y_mac(b, lambda)
        %COMPUTE_Y_MAC  Spanwise station of the MAC measured from the
        %   centreline [ft], MIRRORED surfaces (wing, conventional HT):
        %     y_MAC = (b/6) * (1 + 2*lambda) / (1 + lambda)
        %   b is the FULL span, not the semispan.
        %
        %   Use compute_y_mac_panel for a single-panel surface (vertical
        %   tail); passing a single panel's span here halves the answer.
        %
        %   Standard linearly-tapered-planform identity; no textbook equation
        %   number could be pinned against the references in this repo -- the
        %   same citation status convert_sweep already carries, and the same
        %   formula the pre-existing SandCL3.y_MAC_span carries (that method
        %   now delegates here rather than duplicating it). It reproduces
        %   VnV/BrandtF16A/readme_bsc.md's own y_MAC term and
        %   BrandtBalanceStabControl.surfaceGeom_'s
        %   y_MAC = (semispan/3)*(1+2*lambda)/(1+lambda) exactly.
        %
        %   TODO (citation gap, 2026-08-11): this identity sits with Raymer's
        %   Eqs. 7.6-7.8, which this file already cites by number, but
        %   docs/reference_extracts/ holds NO Raymer Chapter-7 extract, so the
        %   equation number cannot be verified here and is deliberately not
        %   guessed. Pin it when a Ch. 7 extract exists.
            arguments
                b      (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            y = (b/6) * (1 + 2*lambda) / (1 + lambda);
        end

        function y = compute_y_mac_panel(b_panel, lambda)
        %COMPUTE_Y_MAC_PANEL  Spanwise station of the MAC measured from the
        %   ROOT [ft], SINGLE-PANEL surfaces (vertical tail):
        %     y_MAC = (b_panel/3) * (1 + 2*lambda) / (1 + lambda)
        %
        %   Same identity as compute_y_mac with twice the coefficient, because
        %   root->tip spans the full b_panel rather than a semispan -- the same
        %   mirrored/panel pairing convert_sweep/convert_sweep_panel already
        %   uses. This is literally the form
        %   BrandtBalanceStabControl.surfaceGeom_ applies to every surface,
        %   because that method is fed a semispan for mirrored surfaces and a
        %   panel span for the vertical tail. Citation status as compute_y_mac.
            arguments
                b_panel (1,1) double {mustBePositive}
                lambda  (1,1) double {mustBeNonnegative}
            end
            y = (b_panel/3) * (1 + 2*lambda) / (1 + lambda);
        end

        function x = compute_x_mac_le(x_apex, y_mac, LE_sweep_deg)
        %COMPUTE_X_MAC_LE  x-station of the LEADING EDGE of a lifting
        %   surface's MAC [ft], from the surface's own apex (root-chord LE)
        %   station:
        %     x_MAC_LE = x_apex + y_MAC * tan(Lambda_LE)
        %   [VnV/BrandtF16A/readme_bsc.md, "MAC station and aerodynamic
        %   center": x_MAC = x_LE,r + y_MAC*tan(Lambda_LE); implemented in
        %   BrandtBalanceStabControl.surfaceGeom_]. Standard swept-planform
        %   identity, same citation status as compute_y_mac.
            arguments
                x_apex       (1,1) double {mustBeReal}
                y_mac        (1,1) double {mustBeReal}
                LE_sweep_deg (1,1) double {mustBeReal}
            end
            x = x_apex + y_mac * tand(LE_sweep_deg);
        end

        function x = compute_x_mac_quarter_chord(x_mac_le, cbar)
        %COMPUTE_X_MAC_QUARTER_CHORD  x-station of the QUARTER-CHORD point of
        %   a lifting surface's MAC [ft]:
        %     x_c/4 = x_MAC_LE + 0.25 * cbar
        %   This is the station Raymer's tail moment arm is measured between
        %   [Raymer 6th ed. Sec. 6.5.2, p.158] and the station Nicolai's tail
        %   moment arm ends at [Nicolai & Carichner Eqs. (11.1)/(11.2)]. The
        %   0.25 is definitional (a quarter chord), not a fitted coefficient.
        %   [VnV/BrandtF16A/readme_bsc.md: x_ac = x_MAC + 0.25*MAC]
            arguments
                x_mac_le (1,1) double {mustBeReal}
                cbar     (1,1) double {mustBePositive}
            end
            x = x_mac_le + 0.25 * cbar;
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

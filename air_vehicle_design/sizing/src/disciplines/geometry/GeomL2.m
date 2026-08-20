classdef GeomL2
%GEOML2  Level-2 geometry static toolbox: component wetted and exposed areas.
%   Call as GeomL2.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL2 inherits GeometryModelL2 and delegates to these statics.
%
%   Official formulas: lifting surfaces [Roskam Vol. II Eq. 12.1], fuselage
%   [Roskam Vol. II Eq. 12.3], duct [Raymer 6th ed. Sec. 7.3]. Brandt's own
%   uniform-t/c and fuselage formulas are named alternates for the comparison
%   report, not the default path.
%
%   Companion doc: src/disciplines/geometry/GeomL2.md
%
%   _TODO (08/19/2026) (Claude) -- two open citation gaps at the freeze:
%     1. Roskam Vol. II is not scraped, so Eq. 12.1 and Eq. 12.3 above are
%        UNVERIFIED. The only Vol. II extract is a method summary, no equations.
%     2. compute_S_exposed_horizontal and _vertical cite Brandt only. Both are
%        plain trapezoid clipping, so a textbook pin should exist. Casey marked
%        both "Don't touch" on 2026-08-18, so the code stays as it is.

% Note (8/20/2026)(Casey): I'm not seeing a function to size the control mechanisms. Add that.
    methods (Static)

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/arrays, no object access.
        % ================================================================== %

        % Note (8/18/2026)(Casey): This is a RAYMER equation that BRANDT uses.
        function val = compute_S_wet_planform_raymer(S_exp, tc)
        %COMPUTE_S_WET_PLANFORM_RAYMER  Lifting-surface wetted area [ft^2], uniform t/c.
        %   t/c < 0.05:  S_wet = 2.003 * S_exp             [Raymer 6th ed. Eq. 7.11]
        %   t/c >= 0.05: S_wet = S_exp*(1.977 + 0.52*t/c)  [Raymer 6th ed. Eq. 7.12]
        %   A paper-thin surface gives 2*S_exp. Thickness raises the area.
        %   Alternate to compute_S_wet_planform_roskam, which takes a root/tip t/c pair.
        %
        %   Mod (08/18/2026) (Claude)
        %   ALL THREE F-16 SURFACES TAKE THE Eq. 7.11 BRANCH: wing t/c 0.0400,
        %   HT 0.0475, VT 0.0415. Brandt applied the Eq. 7.12 form to all three,
        %   outside its stated t/c > 0.05 range. So this static no longer
        %   reproduces Brandt exactly. Expected gaps: wing +0.26%, HT +0.065%,
        %   VT +0.22%. The comparison report names each gap.
            arguments
                S_exp (1,1) double {mustBePositive}
                tc    (1,1) double {mustBePositive}
            end

            if tc<0.05
                val = 2.003*S_exp; % Raymer, 6th ed, 7.11
            elseif tc>=0.05
                val = S_exp * (1.977 + 0.52 * tc); % Raymer, 6th ed, 7.12
            else
                error("GeomL2, compute_S_wet_planform_raymer: tc not accepted.")
            end
        end

        % TODO (8/14/2026): This answers my previous question.
        function val = compute_S_wet_planform_roskam(S_exp, tc_r, tc_t, lambda)
        %COMPUTE_S_WET_PLANFORM_ROSKAM  Lifting-surface wetted area [ft^2], variable
        %   root/tip t/c.  [Roskam Vol. II Eq. 12.1]
        %   Validators guard the tc_t and (1+lambda) denominators.
            arguments
                S_exp  (1,1) double {mustBePositive}
                tc_r   (1,1) double {mustBePositive}
                tc_t   (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            val = 2 * S_exp * (1 + 0.25*tc_r * (1 + (tc_r/tc_t)*lambda) / (1 + lambda));
        end

        function val = compute_s_wet_fus_cyl(D_fus, L_fus)
        %COMPUTE_S_WET_FUS_CYL  Fuselage wetted area [ft^2], cylindrical midsection.
        %   [Roskam Vol. II Eq. 12.3]
        %   Valid only for fineness ratio L/D > 2; errors below that (the
        %   formula would return a complex number).
            arguments
                D_fus (1,1) double {mustBePositive}
                L_fus (1,1) double {mustBePositive}
            end
            lambda_f = L_fus / D_fus;
            if lambda_f <= 2
                error('GeomL2:invalidFinenessRatio', ...
                    ['Fuselage fineness ratio L/D = %.3f <= 2 -- Roskam Eq. ' ...
                     '12.3 (cylindrical-midsection S_wet) is only valid for ' ...
                     'L/D > 2; a short/wide fuselage would otherwise silently ' ...
                     'return a complex number. D_fus=%.3f ft, L_fus=%.3f ft.'], ...
                    lambda_f, D_fus, L_fus);
            end
            val = pi * D_fus * L_fus ...
                  * (1 - 2/lambda_f)^(2/3) ...
                  * (1 + 1/lambda_f^2);
        end

        % TODO (8/14/2026): Do not include Brandt in the toolbox.
        % ------------------------------------------------------------------ %
        % MOVED OUT 2026-08-18 -> examples/F16A/models/disciplines/geom/
        %                          F16GeomBrandtAlt.m
        % Mod (08/18/2026) (Claude)
        %   Three Brandt-only statics left this toolbox: compute_s_wet_fus_brandt_lowfi,
        %   compute_s_wet_fus_brandt_highfi, compute_frame_perimeter. Brandt verifies
        %   the framework; he does not supply its equations. compute_frame_perimeter
        %   also models an F-16 "chine", which is design-specific.
        %   Their TODOs travelled with them, verbatim. Equations unchanged, so no
        %   number moves. Reason recorded in GeomL2.md.
        % Mod (08/19/2026) (Claude)
        %   Casey then moved two of the three on to the GeomL3 toolbox:
        %   compute_s_wet_from_control_stations (renamed from
        %   compute_s_wet_fus_brandt_highfi) and compute_frame_perimeter. The
        %   chine stays a parameter, so a design with no chine sets z_chine =
        %   z_center. See GeomL3.md. Only compute_s_wet_fus_brandt_lowfi is
        %   still in the F-16 example.
        %   The official fuselage method stays here: compute_s_wet_fus_cyl,
        %   [Roskam Vol. II Eq. 12.3].
        % ------------------------------------------------------------------ %

        % TODO (8/18/2026)(Casey): This is acceptable. Don't touch.
        function val = compute_s_wet_duct(D_inlet, D_exit, L_duct)
        %COMPUTE_S_WET_DUCT  Duct wetted area [ft^2] as a right circular frustum.
        %   [Raymer 6th ed. Sec. 7.3]. Degenerates to a cylinder when
        %   D_inlet == D_exit. The triple D_inlet = D_exit = L_duct = 0 means
        %   "no duct given": it warns and returns 0, so a spec omission stays
        %   visible.
            arguments
                D_inlet (1,1) double {mustBeNonnegative}
                D_exit  (1,1) double {mustBeNonnegative}
                L_duct  (1,1) double {mustBeNonnegative}
            end
            if D_inlet == 0 && D_exit == 0 && L_duct == 0
                warning('GeomL2:noDuctGeometry', ...
                    ['No duct geometry given (D_inlet = D_exit = L_duct = 0); ' ...
                     'returning 0 duct wetted area.']);
                val = 0;
                return;
            end
            r1  = D_inlet / 2;
            r2  = D_exit  / 2;
            val = pi * (r1 + r2) * sqrt((r2 - r1)^2 + L_duct^2);
        end

        % TODO (8/18/2026)(Casey): This is acceptable. Don't touch.
        function val = compute_S_exposed_horizontal(c_root, c_tip, hs, fw)
        %COMPUTE_S_EXPOSED_HORIZONTAL  Exposed planform area [ft^2] of a mirrored
        %   horizontal surface, clipped at the fuselage HALF-WIDTH.
        %   [Brandt F-16A.xls; readme_geom.md Sec. 4.3]
            arguments
                c_root (1,1) double {mustBePositive}
                c_tip  (1,1) double {mustBeNonnegative}
                hs     (1,1) double {mustBePositive}
                fw     (1,1) double {mustBeNonnegative}
            end
            c_exp_root = c_root - (fw/hs) * (c_root - c_tip);
            hs_exp     = hs - fw;
            val        = (c_exp_root + c_tip)/2 * hs_exp * 2;
        end

        % TODO (8/18/2026)(Casey): This is acceptable. Don't touch.
        function val = compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)
        %COMPUTE_S_EXPOSED_VERTICAL  Exposed planform area [ft^2] of the vertical
        %   tail, clipped at the fuselage HALF-HEIGHT, single panel (no mirroring).
        %   [Brandt F-16A.xls; readme_geom.md Sec. 4.3]
            arguments
                S      (1,1) double {mustBePositive}
                AR     (1,1) double {mustBePositive}
                c_root (1,1) double {mustBePositive}
                c_tip  (1,1) double {mustBeNonnegative}
                fh     (1,1) double {mustBeNonnegative}
            end
            b_vt       = sqrt(S * AR);
            c_exp_root = c_root - (fh/b_vt) * (c_root - c_tip);
            span_exp   = b_vt - fh;
            val        = (c_exp_root + c_tip)/2 * span_exp;
        end

        % Note (8/20/2026)(casey): I cannot find a statistical method of estimating control surface
        % sizes in Ramyer, Nicolai, or Roskam. However, Nicolai has a sophisticated way of 
        % sizing those things, but it's dependent on purely geometry, which means it's best suited for L3.
        % My current best option is to leave it out of L2, and implement the high-fidelity version in GeomL3.

        % ================================================================== %
        % PURE GEOMETRY CALCULATIONS
        % ================================================================== %

        % TODO (8/14/2026): We should have individual "compute" functions that compute
        % the wetted areas of generic shapes of arbitrary dimensions.
        % Decompose this into functions that compute the wetted/surface areas of these shapes. Syntax: Shape(arguments/dimensions)
        % Cone(radius, length)
        % Pyramid(face_side_length1, face_side_length2, face_side_length3, face_side_length4, height)
        % Sphere(radius)
        % Cylinder(radius, length)
        % Oval(width, height, length)
        % Note: The difference between this and L3 is that L3 SHOULD/WILL be more focused on cross-section and stations.
        % Note (8/19/2026): This should go back into L2.

        % _TODO (08/19/2026) (Claude) -- NO CONSUMER. Only a commented-out line in
        %   F16GeomL3.get_design_S_wet_components names it. Both shape statics
        %   below return the CLOSED body, so they count the attachment face. A
        %   caller must subtract it, as Casey's own comment says.
        function val = compute_S_wet_cylinder(r, L)
            % Casey Chamberlain
            % Computes the wetted area of a circular cylinder of radius "r" and length "L."
            % Args: 
            %   r = radius (ft)
            %   L = length (ft)
            % Returns:
            %   val = wetted area (ft^2)

            % Now compute the wetted area (will need to subtract area of attachment face)
            val = 2*pi*r^2 + L*2*pi*r;
        end

        % _TODO (08/19/2026) (Claude) -- NO CONSUMER. See the note above.
        function val = compute_S_wet_cone(r, L)
            % Casey Chamberlain
            % Computes the wetted area of a circular cone of 
            % radius "r" and length "L."
            % Args:
            %   r = radius (ft)
            %   L = length (ft)
            % Returns:
            %   val = wetted area (ft^2)

            % Need slant height, "S."
            s = sqrt(r^2 + L^2);

            % Now compute the wetted area (will need to subtract area of attachment face)
            val = pi*r^2 + pi*r*s;
        end

    end
end

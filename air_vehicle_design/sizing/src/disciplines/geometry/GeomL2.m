classdef GeomL2
%GEOML2  Level-2 geometry static toolbox: component-level wetted-area formulas.
%
%   Call as GeomL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16GeomL2, etc.) inherit
%   from GeometryModelL2 and call these statics to implement each abstract method.
%
%   2026-07-22: Geometry's former L3 tier was eliminated and merged into L2
%   (user decision — see this file's own GeomL2.md dated note for full
%   rationale). The variable-tc lifting-surface formula (Roskam Eq. 12.1)
%   and the inlet/duct component that used to live in the now-deleted
%   GeomL3.m are folded in below as additional, separately-citable named
%   methods, alongside the pre-existing uniform-tc Brandt formula and
%   fuselage formula.
%
%   EQUATIONS:
%     Lifting surfaces (uniform t/c, Brandt's own formula):
%       S_wet = S_exposed * (1.977 + 0.52 * tc)
%       [S. Brandt et al., Introduction to Aeronautics, AIAA, 2004;
%        F-16A workbook, Geom sheet, cell B13]
%     Lifting surfaces (variable root/tip t/c) *(moved from former L3)*:
%       S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.1]
%       RESOLVED 2026-07-22: this is the OFFICIAL formula used by
%       get_S_wet_wing/HT/VT — a strict generalization of the uniform-tc
%       formula above (special case tc_root=tc_tip). The uniform-tc formula
%       stays available as a named alternate (compute_wet_planform), not
%       removed.
%     Fuselage (cylindrical midsection, Roskam):
%       S_wet = pi*D*L*(1-2/lambda_f)^(2/3)*(1+1/lambda_f^2)
%       where lambda_f = L/D  (fineness ratio)
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.3]
%     Fuselage (Brandt low-fi, "1/3-cone + 2/3-cylinder"):
%       D_avg = (max_width+max_height)/2;  S_wet = (5/6)*pi*D_avg*L_fuse
%       [Brandt F-16A workbook, Geom sheet, cell B3;
%        VnV/BrandtF16A/readme_geom.md Section 4.1]
%     Fuselage (Brandt high-fi, frame integration):
%       S_wet = sum_i (P_i+P_{i+1})/2 * dx_i  (trapezoidal integration of
%       per-frame perimeter, cosine cross-section model)
%       [Brandt F-16A workbook, Geom!D23; VnV/BrandtF16A/readme_geom.md
%        Sections 4.1-4.2]
%     Duct/inlet (frustum) *(moved from former L3)*:
%       S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2)
%       [Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Sec. 7.3]
%       Degenerates to pi*D*L for a constant-section duct (D_inlet==D_exit).
%     Lifting-surface exposed area (horizontal / vertical, boundary =
%     fuselage half-width / half-height respectively):
%       [Brandt F-16A workbook; VnV/BrandtF16A/readme_geom.md Section 4.3]

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet(obj)
        %GET_S_WET  Total: wing + HT + VT + fuselage + duct.
        %   RESOLVED (2026-07-22, user decision): no W_TO argument -- L2 has
        %   real planform geometry and never needed it (the prior signature
        %   carried an ignored `~` second parameter purely to satisfy
        %   GeometryBase's abstract stub; confirmed MATLAB does not enforce
        %   matching arity between an abstract declaration and its concrete
        %   override, so dropping the parameter here is safe). Call as
        %   GeomL2.get_S_wet(obj) / obj.get_S_wet() with a single argument.
        %   DECISION (2026-07-22 L3 merge): duct is included unconditionally.
        %   Every current F16GeomL2-derived concrete class defines
        %   D_inlet/D_exit/L_duct (absorbed from the former GeometryModelL3
        %   contract), so there is no concrete L2 class today without a duct
        %   term. A future concrete class with no real duct should set
        %   D_inlet=D_exit=L_duct=0 (the frustum formula then degenerates to
        %   0 ft^2) rather than this method needing an isprop/conditional
        %   branch.
            val = GeomL2.get_S_wet_wing(obj)     + GeomL2.get_S_wet_HT(obj) + ...
                  GeomL2.get_S_wet_VT(obj)        + GeomL2.get_S_wet_fuselage(obj) + ...
                  GeomL2.get_S_wet_duct(obj);
        end

        function val = get_S_wet_wing(obj)
        %GET_S_WET_WING  Official: Roskam Eq. 12.1 (variable root/tip tc).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_wing, ...
                      obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
        end

        function val = get_S_wet_HT(obj)
        %GET_S_WET_HT  Official: Roskam Eq. 12.1 (variable root/tip tc).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_ht, ...
                      obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht);
        end

        function val = get_S_wet_VT(obj)
        %GET_S_WET_VT  Official: Roskam Eq. 12.1 (variable root/tip tc).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_vt, ...
                      obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt);
        end

        function val = get_S_wet_fuselage(obj)
        %GET_S_WET_FUSELAGE  Official: Roskam Eq. 12.3 (cylindrical midsection).
        %   Brandt's own low-fi/high-fi alternates are available as named
        %   methods (compute_s_wet_fus_brandt_lowfi/_highfi) but are not the
        %   default here.
            val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        function val = get_S_wet_duct(obj)
        %GET_S_WET_DUCT  Inlet + engine duct wetted area (frustum formula).
        %   Moved from the former GeomL3 (2026-07-22 L3-elimination merge).
            val = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        end

        function val = get_S_exposed_wing(obj)
        %GET_S_EXPOSED_WING  Passthrough accessor for the wing exposed area.
        %   Moved from the former GeomL3.
            val = obj.S_exposed_wing;
        end

        function val = get_S_wet_fuselage_brandt_lowfi(obj)
        %GET_S_WET_FUSELAGE_BRANDT_LOWFI  Brandt "1/3-cone+2/3-cylinder" fuselage
        %   S_wet, reading obj.W_max_fuselage/H_max_fuselage/L_fuselage.
            val = GeomL2.compute_s_wet_fus_brandt_lowfi(obj.W_max_fuselage, ...
                      obj.H_max_fuselage, obj.L_fuselage);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/arrays, no object access.
        % ================================================================== %

        function val = compute_wet_planform(S_exp, tc)
        %COMPUTE_WET_PLANFORM  S_wet = S_exposed*(1.977 + 0.52*tc)  (uniform tc)
        %   [Brandt F-16A workbook, Geom sheet, cell B13]
            arguments
                S_exp (1,1) double {mustBePositive}
                tc    (1,1) double {mustBePositive}
            end
            val = S_exp * (1.977 + 0.52 * tc);
        end

        function val = compute_roskam_planform(S_exp, tc_r, tc_t, lambda)
        %COMPUTE_ROSKAM_PLANFORM  S_wet via Roskam Vol. II Eq. 12.1 (variable
        %   root/tip tc).  *(moved from former L3)*
        %   S_exp  — exposed planform area (ft^2)
        %   tc_r   — root t/c ratio
        %   tc_t   — tip  t/c ratio  (mustBePositive guards the tc_r/tc_t
        %            division: a zero tip t/c would otherwise silently
        %            return Inf — flagged in GeomL2.md's "Guard gaps" note)
        %   lambda — taper ratio (c_tip/c_root); mustBeNonnegative guards
        %            the (1+lambda) denominator against lambda=-1
            arguments
                S_exp  (1,1) double {mustBePositive}
                tc_r   (1,1) double {mustBePositive}
                tc_t   (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            val = 2 * S_exp * (1 + 0.25*tc_r * (1 + (tc_r/tc_t)*lambda) / (1 + lambda));
        end

        function val = compute_s_wet_fus_cyl(D_fus, L_fus)
        %COMPUTE_S_WET_FUS_CYL  Roskam Vol. II Eq. 12.3 cylindrical-midsection fuselage.
        %   lambda_f = L/D  (fineness ratio).  Roskam Eq. 12.3 is only valid
        %   for lambda_f > 2 -- a short/wide fuselage otherwise makes
        %   (1-2/lambda_f) negative, which combined with the ^(2/3) power
        %   would silently return a complex number (GeomL2.md's "Guard
        %   gaps" note). Errors explicitly instead.
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

        function val = compute_s_wet_fus_brandt_lowfi(max_width, max_height, L_fuse)
        %COMPUTE_S_WET_FUS_BRANDT_LOWFI  "1/3-cone + 2/3-cylinder" fuselage
        %   approximation.  [Brandt F-16A workbook, Geom!B3;
        %   VnV/BrandtF16A/readme_geom.md Section 4.1]
            arguments
                max_width  (1,1) double {mustBePositive}
                max_height (1,1) double {mustBePositive}
                L_fuse     (1,1) double {mustBePositive}
            end
            D_avg = (max_width + max_height) / 2;
            val   = (5/6) * pi * D_avg * L_fuse;
        end

        function val = compute_s_wet_fus_brandt_highfi(frame_x, frame_zchine, frame_z, frame_w, frame_h)
        %COMPUTE_S_WET_FUS_BRANDT_HIGHFI  Trapezoidal integration of
        %   per-frame perimeters (cosine cross-section model) along the
        %   fuselage x-axis.  Nose (x=0) and the point beyond the last frame
        %   both close to zero perimeter.
        %   [Brandt F-16A workbook, Geom!D23; VnV/BrandtF16A/readme_geom.md
        %    Sections 4.1-4.2]
        %   frame_x/frame_zchine/frame_z/frame_w/frame_h — per-frame vectors
        %   (station x, chine z, centerline z, width, height), one entry per
        %   fuselage frame, e.g. VnV/BrandtF16A/GroundTruth/f16a_geometry.json
        %   fuselage.frames.
            arguments
                frame_x      double {mustBeVector}
                frame_zchine double {mustBeVector}
                frame_z      double {mustBeVector}
                frame_w      double {mustBeVector, mustBePositive}
                frame_h      double {mustBeVector, mustBePositive}
            end
            nf = numel(frame_x);
            if ~isequal(nf, numel(frame_zchine), numel(frame_z), numel(frame_w), numel(frame_h))
                error('GeomL2:frameVectorLengthMismatch', ...
                    ['frame_x/frame_zchine/frame_z/frame_w/frame_h must all be ' ...
                     'the same length (one entry per fuselage frame); got %d, ' ...
                     '%d, %d, %d, %d.'], nf, numel(frame_zchine), numel(frame_z), ...
                    numel(frame_w), numel(frame_h));
            end
            P  = zeros(1, nf);
            for i = 1:nf
                P(i) = GeomL2.compute_frame_perimeter(frame_w(i), frame_h(i), ...
                           frame_zchine(i), frame_z(i));
            end

            x_all = [0, reshape(frame_x, 1, [])];
            P_all = [0, P];

            dS = zeros(1, numel(x_all) - 1);
            for k = 1:(numel(x_all) - 1)
                dS(k) = (P_all(k) + P_all(k+1)) / 2 * (x_all(k+1) - x_all(k));
            end
            val = sum(dS);
        end

        function P = compute_frame_perimeter(w, h, z_chine, z_center)
        %COMPUTE_FRAME_PERIMETER  Perimeter of one fuselage frame's
        %   cosine-model cross-section.
        %   Upper boundary: z = z_chine + (z_top-z_chine)*cos(pi/2 * y/hw)
        %   Lower boundary: z = z_chine + (z_bot-z_chine)*cos(pi/2 * y/hw)
        %   where hw=w/2, z_top=z_center+h/2, z_bot=z_center-h/2. Sampled at
        %   6 points from centerline (y=0) to chine (y=hw); full perimeter is
        %   twice the right-half path length (left half symmetric).
        %   [Brandt F-16A workbook, Geom sheet frame cross-section model;
        %    VnV/BrandtF16A/readme_geom.md Section 4.2]
            arguments
                w       (1,1) double {mustBePositive}
                h       (1,1) double {mustBePositive}
                z_chine (1,1) double
                z_center (1,1) double
            end
            n_pts = 6;
            hw    = w / 2;
            z_top = z_center + h / 2;
            z_bot = z_center - h / 2;

            t    = linspace(0, 1, n_pts);
            y    = t * hw;
            z_up = z_chine + (z_top - z_chine) * cos(pi/2 * t);
            z_dn = z_chine + (z_bot - z_chine) * cos(pi/2 * t);

            % Right-side path: top-center -> right-chine -> bottom-center.
            y_path = [y,    fliplr(y(1:end-1))];
            z_path = [z_up, fliplr(z_dn(1:end-1))];

            ds = sqrt(diff(y_path).^2 + diff(z_path).^2);
            P  = 2 * sum(ds);   % full perimeter (left side symmetric)
        end

        function val = compute_s_wet_duct(D_inlet, D_exit, L_duct)
        %COMPUTE_S_WET_DUCT  Lateral area of a right circular frustum (inlet/duct).
        %   *(moved from former L3)*  [Raymer 6th ed., Sec. 7.3]
        %   Degenerates to pi*D*L for constant-section duct (D_inlet == D_exit).
            arguments
                D_inlet (1,1) double {mustBeNonnegative}
                D_exit  (1,1) double {mustBeNonnegative}
                L_duct  (1,1) double {mustBePositive}
            end
            r1  = D_inlet / 2;
            r2  = D_exit  / 2;
            val = pi * (r1 + r2) * sqrt((r2 - r1)^2 + L_duct^2);
        end

        function val = compute_S_exposed_horizontal(c_root, c_tip, hs, fw)
        %COMPUTE_S_EXPOSED_HORIZONTAL  Exposed planform area of a horizontal
        %   lifting surface (wing/HT), clipped by the fuselage HALF-WIDTH,
        %   both panels (mirrored).
        %   c_root, c_tip — full-planform root/tip chord, ft
        %   hs            — half span (full planform), ft; guarded positive
        %                    since it is the fw/hs division's denominator
        %   fw            — fuselage half-width, ft
        %   [Brandt F-16A workbook; VnV/BrandtF16A/readme_geom.md Section 4.3]
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

        function val = compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)
        %COMPUTE_S_EXPOSED_VERTICAL  Exposed planform area of the vertical
        %   tail, clipped by the fuselage HALF-HEIGHT (not half-width), full
        %   single-panel span (no mirroring).
        %   S, AR         — full-planform VT reference area/aspect ratio
        %                    (used to recover the full span b_vt=sqrt(S*AR));
        %                    guarded positive since b_vt is the fh/b_vt
        %                    division's denominator
        %   c_root, c_tip — full-planform root/tip chord, ft
        %   fh            — fuselage half-height, ft
        %   [Brandt F-16A workbook; VnV/BrandtF16A/readme_geom.md Section 4.3]
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

    end
end

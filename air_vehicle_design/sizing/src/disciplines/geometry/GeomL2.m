classdef GeomL2
%GEOML2  Level-2 geometry static toolbox: component wetted and exposed areas.
%
%   Call as GeomL2.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL2 inherits GeometryModelL2 and delegates to these statics.
%
%   Official formulas: lifting surfaces [Roskam Vol. II Eq. 12.1], fuselage
%   [Roskam Vol. II Eq. 12.3], duct [Raymer 6th ed. Sec. 7.3].
%
%   Brandt's own uniform-t/c and fuselage formulas are kept as separately named
%   alternates for the comparison report; they are not the default path.
%
%   Companion doc: src/disciplines/geometry/GeomL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet(obj)
        %GET_S_WET  Total wetted area [ft^2]: wing + HT + VT + fuselage + duct.
        %   Takes no W_TO argument (contrast L1). The duct is included
        %   unconditionally; a concrete class with no duct should set
        %   D_inlet = D_exit = L_duct = 0, which degenerates the frustum
        %   formula to zero.
            val = GeomL2.get_S_wet_wing(obj)     + GeomL2.get_S_wet_HT(obj) + ...
                  GeomL2.get_S_wet_VT(obj)        + GeomL2.get_S_wet_fuselage(obj) + ...
                  GeomL2.get_S_wet_duct(obj);
        end

        function val = get_S_wet_wing(obj)
        %GET_S_WET_WING  Wing wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
            val = GeomL2.compute_roskam_planform(obj.S_exposed_wing, ...
                      obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
        end

        function val = get_S_wet_HT(obj)
        %GET_S_WET_HT  Horizontal-tail wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
            val = GeomL2.compute_roskam_planform(obj.S_exposed_ht, ...
                      obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht);
        end

        function val = get_S_wet_VT(obj)
        %GET_S_WET_VT  Vertical-tail wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
            val = GeomL2.compute_roskam_planform(obj.S_exposed_vt, ...
                      obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt);
        end

        function val = get_S_wet_fuselage(obj)
        %GET_S_WET_FUSELAGE  Fuselage wetted area [ft^2].  [Roskam Vol. II Eq. 12.3]
        %   Brandt's low-fi and high-fi alternates are available as named methods.
            val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        function val = get_S_wet_duct(obj)
        %GET_S_WET_DUCT  Inlet + duct wetted area [ft^2].  [Raymer 6th ed. Sec. 7.3]
            val = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        end

        function val = get_S_exposed_wing(obj)
        %GET_S_EXPOSED_WING  Wing exposed planform area [ft^2] (passthrough).
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
        %COMPUTE_WET_PLANFORM  Lifting-surface wetted area [ft^2], uniform t/c.
        %   [Brandt F-16A.xls, Geom!B13]. Alternate to compute_roskam_planform.
            arguments
                S_exp (1,1) double {mustBePositive}
                tc    (1,1) double {mustBePositive}
            end
            val = S_exp * (1.977 + 0.52 * tc);
        end

        function val = compute_roskam_planform(S_exp, tc_r, tc_t, lambda)
        %COMPUTE_ROSKAM_PLANFORM  Lifting-surface wetted area [ft^2], variable
        %   root/tip t/c.  [Roskam Vol. II Eq. 12.1]
        %   Validators guard the two denominators: tc_t against a zero-division
        %   to Inf, lambda against (1+lambda) = 0.
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
        %   Valid only for fineness ratio L/D > 2; below that the formula would
        %   silently return a complex number, so it errors instead.
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
        %COMPUTE_S_WET_FUS_BRANDT_LOWFI  Fuselage wetted area [ft^2], Brandt's
        %   "1/3-cone + 2/3-cylinder" approximation.  [Brandt F-16A.xls, Geom!B3]
            arguments
                max_width  (1,1) double {mustBePositive}
                max_height (1,1) double {mustBePositive}
                L_fuse     (1,1) double {mustBePositive}
            end
            D_avg = (max_width + max_height) / 2;
            val   = (5/6) * pi * D_avg * L_fuse;
        end

        function val = compute_s_wet_fus_brandt_highfi(frame_x, frame_zchine, frame_z, frame_w, frame_h)
        %COMPUTE_S_WET_FUS_BRANDT_HIGHFI  Fuselage wetted area [ft^2] by trapezoidal
        %   integration of per-frame perimeters.  [Brandt F-16A.xls, Geom!D23]
        %   Inputs are per-frame vectors (station x, chine z, centreline z,
        %   width, height), one entry per frame.
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
        %COMPUTE_FRAME_PERIMETER  Perimeter [ft] of one fuselage frame under the
        %   cosine cross-section model.  [Brandt F-16A.xls, Geom frame model]
        %   Sampled at 6 points per quarter; the full perimeter is twice the
        %   right-half path length.
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
        %COMPUTE_S_WET_DUCT  Duct wetted area [ft^2] as a right circular frustum.
        %   [Raymer 6th ed. Sec. 7.3]. Degenerates to a cylinder when
        %   D_inlet == D_exit.
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

    end
end

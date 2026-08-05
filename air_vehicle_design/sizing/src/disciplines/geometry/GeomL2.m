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
        %   D_inlet = D_exit = L_duct = 0, which warns and gives 0 duct
        %   wetted area (see compute_s_wet_duct).
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

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
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
        %   D_inlet == D_exit. A concrete class with no duct sets
        %   D_inlet = D_exit = L_duct = 0; this is treated as "no duct given"
        %   rather than a normal zero-length duct, so it warns and returns 0
        %   instead of silently degenerating (a genuine spec omission should
        %   be visible, not indistinguishable from a design choice).
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

        % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
        % Ported (renamed size->size_tail_nicolai) from the deleted
        % src/disciplines/tail_sizing/TailL2.m. SECONDARY/alternate F-16-
        % specific-coefficient path (Nicolai & Carichner Table 11.6),
        % preserved for its citation and test coverage but NOT the one wired
        % into the production sizing loop -- SizingLoopL2 calls GeomL1's
        % Raymer-based size_tail (via F16GeomL2.size_tail), never this one.
        %
        % METHOD -- same governing identity as GeomL1's Raymer 7th ed.
        % Table 6.4 form, confirmed algebraically identical to Nicolai &
        % Carichner's own Eq. (11.1)/(11.2) [docs/reference_extracts/
        % 11_tail_sizing.md Secs. 11.2-11.3, pp. 286, 289]:
        %
        %   C_VT = (l_VT*S_VT)/(b*S_ref)      ==>  S_VT = C_VT*b*S_ref/l_VT
        %   C_HT = (l_HT*S_HT)/(cbar*S_ref)   ==>  S_HT = C_HT*cbar*S_ref/l_HT
        %
        % COEFFICIENT SOURCE: Nicolai & Carichner Table 11.6, "General Dynamics
        % F-16" row, p.289 [docs/reference_extracts/
        % 11_tail_sizing.md] -- an F-16-SPECIFIC measured coefficient, not a
        % generic category row: C_HT=0.3, C_VT=0.094. EXPLICITLY NOT the
        % conflicting C_HT=0.68, C_VT=0.041 figure that appears in
        % nicolai_data.md / roskam_vol2_data.md / usaf_f16_data.md -- those
        % three reference-extract digest files mis-transcribe the same Table 11.6 row
        % (flagged, left OPEN/unresolved elsewhere; see VnV/BrandtF16A/todo.md
        % Finding 1).
        %
        % TAIL MOMENT ARM CARRIES FORWARD GeomL1's RULE, UNCHANGED:
        % GeometryModelL2 has no x-station properties at all, so a genuinely
        % geometry-derived moment arm is not achievable at L2 with today's
        % inputs: L_HT = L_VT = GeomL1.compute_tail_arm(L_fus) = 0.475*L_fus
        % [Raymer 7th ed. text rule, reused verbatim via a cross-toolbox static
        % call -- deliberately NOT a duplicated copy].
        %
        % AREA REUSE IS INDIRECT ONLY: size_tail_nicolai(obj) returns
        % struct('S_ht','S_vt') and nothing else, and does NOT self-mutate
        % obj.S_ht/obj.S_vt (unlike size_tail) -- this is a pure, non-mutating
        % query/comparison method, never wired into the production loop, and
        % must not silently clobber the primary path's output.
        % ==================================================================================================================================== %

        function result = size_tail_nicolai(obj)
        %SIZE_TAIL_NICOLAI  Horizontal- and vertical-tail reference areas
        %   [ft^2], Nicolai & Carichner F-16-specific coefficient method.
        %   [Nicolai & Carichner Table 11.6 F-16 row; Raymer 7th ed. tail-arm
        %   text rule, carried forward from GeomL1]  obj must expose
        %   C_HT_nicolai/C_VT_nicolai and its own S_ref/b_wing/cbar_wing/L_fus
        %   -- reads them LIVE on every call, so a mutated obj is reflected
        %   immediately -- no cached copy. Returns struct('S_ht', S_ht,
        %   'S_vt', S_vt) ONLY -- does NOT mutate obj.S_ht/obj.S_vt.
            S_ref = obj.S_ref;
            b     = obj.b_wing;
            cbar  = obj.cbar_wing;
            L_fus = obj.L_fus;

            L_HT = GeomL1.compute_tail_arm(L_fus);   % carried forward from GeomL1, unchanged
            L_VT = L_HT;

            S_ht = GeomL2.compute_S_HT(obj.C_HT_nicolai, cbar, S_ref, L_HT);
            S_vt = GeomL2.compute_S_VT(obj.C_VT_nicolai, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

        function val = compute_S_HT(C_HT, cbar, S_ref, L_HT)
        %COMPUTE_S_HT  Horizontal-tail area [ft^2]. Nicolai-coefficient-shaped
        %   (distinct from GeomL1.compute_S_HT's Raymer-coefficient-shaped
        %   static of the same name -- no collision, different class).
        %   [Nicolai & Carichner Eq. 11.2, solved for S_HT:
        %   C_HT = (l_HT*S_HT)/(cbar*S_ref)  =>  S_HT = C_HT*cbar*S_ref/l_HT]
            arguments
                C_HT  (1,1) double {mustBeNonnegative}
                cbar  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
            end
            val = C_HT * cbar * S_ref / L_HT;
        end

        function val = compute_S_VT(C_VT, b, S_ref, L_VT)
        %COMPUTE_S_VT  Vertical-tail area [ft^2]. Nicolai-coefficient-shaped
        %   (distinct from GeomL1.compute_S_VT's Raymer-coefficient-shaped
        %   static of the same name -- no collision, different class).
        %   [Nicolai & Carichner Eq. 11.1, solved for S_VT:
        %   C_VT = (l_VT*S_VT)/(b*S_ref)  =>  S_VT = C_VT*b*S_ref/l_VT]
            arguments
                C_VT  (1,1) double {mustBeNonnegative}
                b     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
            val = C_VT * b * S_ref / L_VT;
        end
        % ==================================================================================================================================== %

        % ======================= CONTROL SURFACE SIZING (absorbed from the former src/sizing/ControlSurfaceSizer.m, 2026-08-03) ============= %
        % Ported from the deleted src/sizing/ControlSurfaceSizer.m -- the low-
        % level static combines that class's constructor validation + size()
        % formula into one pure static; the high-level static reads obj's own
        % fraction properties + S_ref/S_ht/S_vt directly (no more separate
        % injected geom sub-object -- the geometry object IS the object now).
        %
        % METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed.,
        % AIAA, 2018]. Control surfaces are tapered to a constant percent chord
        % along their span (p.162, Fig. 6.4), so area is well approximated as
        % (chord fraction) x (span fraction) x (reference area):
        %   S_ail  = c_ail_frac  * b_ail_frac  * S_ref
        %   S_elev = c_elev_frac * b_elev_frac * S_ht
        %   S_rud  = c_rud_frac  * b_rud_frac  * S_vt
        %
        % Elevator/rudder chord fractions (c_elev_frac, c_rud_frac) come from
        % Table 6.5, p.162 ("Elevator Ce/C", "Rudder Cr/C" -- NOT an aileron
        % column; Table 6.5 has none). Aileron chord/span fractions come from
        % Fig. 6.3, p.161, a shaded historical-guidelines BAND (chord/wing-chord
        % 0.10-0.35 vs. aileron-span/wing-span ~0.3-0.9), not a single value or a
        % per-category table -- callers must pick a representative point from
        % that band (see F16GeomL2/L3's wiring for the chosen point and why).
        % Elevator/rudder span fractions default to Raymer's stated ~90% of tail
        % span (p.161: "Elevators and rudders generally begin at the side of the
        % fuselage and extend to the tip of the tail or to about 90% of the tail
        % span").
        %
        % CORRECTS docs/subplans/08_sizing.md's "S_ail = f_ail x S_ref ...
        % fractions from Table 6.5" -- verified against the actual Raymer text:
        % Table 6.5 has no aileron column at all (aileron is Fig. 6.3, a chart),
        % and its Ce/C, Cr/C entries are TAIL CHORD fractions, not area fractions
        % of S_ht/S_vt directly -- the span-fraction factor above is required to
        % get an area estimate, not just the chord fraction alone.
        %
        % Zero is a legal c_elev_frac/b_elev_frac (an all-moving stabilator with
        % no separate elevator, e.g. the F-16 -- Table 6.5's own footnote:
        % "Supersonic usually all-moving tail without separate elevator"), so
        % these are NOT validated positive, only nonnegative.
        % ==================================================================================================================================== %

        function result = compute_control_surface_areas(c_ail_frac, b_ail_frac, ...
                c_elev_frac, b_elev_frac, c_rud_frac, b_rud_frac, S_ref, S_ht, S_vt)
        %COMPUTE_CONTROL_SURFACE_AREAS  Aileron/elevator/rudder areas [ft^2].
        %   Returns struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud)
        %   -- lowercase-first-letter field names matching this framework's
        %   S_ail/S_elev/S_rud property casing (e.g. F16GeomL2.S_ail).
            arguments
                c_ail_frac  (1,1) double {mustBeNonnegative}
                b_ail_frac  (1,1) double {mustBeNonnegative}
                c_elev_frac (1,1) double {mustBeNonnegative}
                b_elev_frac (1,1) double {mustBeNonnegative}
                c_rud_frac  (1,1) double {mustBeNonnegative}
                b_rud_frac  (1,1) double {mustBeNonnegative}
                S_ref       (1,1) double {mustBePositive}
                S_ht        (1,1) double {mustBeNonnegative}
                S_vt        (1,1) double {mustBePositive}
            end
            S_ail  = c_ail_frac  * b_ail_frac  * S_ref;
            S_elev = c_elev_frac * b_elev_frac * S_ht;
            S_rud  = c_rud_frac  * b_rud_frac  * S_vt;
            result = struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud);
        end

        function result = size_control_surfaces(obj)
        %SIZE_CONTROL_SURFACES  Aileron/elevator/rudder areas [ft^2], reading
        %   obj's own c_ail_frac/b_ail_frac/c_elev_frac/b_elev_frac/
        %   c_rud_frac/b_rud_frac and S_ref/S_ht/S_vt live on every call.
        %   Returns struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud).
            result = GeomL2.compute_control_surface_areas( ...
                obj.c_ail_frac, obj.b_ail_frac, obj.c_elev_frac, obj.b_elev_frac, ...
                obj.c_rud_frac, obj.b_rud_frac, obj.S_ref, obj.S_ht, obj.S_vt);
        end
        % ==================================================================================================================================== %

    end
end

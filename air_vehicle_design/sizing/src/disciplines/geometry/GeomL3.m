classdef GeomL3
%GEOML3  Level-3 geometry static toolbox: the physical / T.O. tier.
%   Call as GeomL3.method(...); never instantiated, not in the inheritance
%   chain. F16GeomL3 inherits GeometryModelL3 and delegates to these statics.
%
%   Most equations are reused from GeomL2 and GeometryBase; L3 differs by the
%   physical/T.O. inputs it is fed, not by the formulas. The only formulas
%   originating here are the area-ruled Amax buildup and its helpers
%   compute_c_root_exposed and compute_engine_length.
%
%   Official lifting-surface wetted area: [Roskam Vol. II Eq. 12.1], fed the
%   T.O. root/tip t/c splits.
%
%   Companion doc: src/disciplines/geometry/GeomL3.md

    methods (Static)

        % REMOVED 2026-08-19 -> examples/F16A/models/disciplines/geom/F16GeomL3.m
        % Mod (08/19/2026) (Claude)
        %   get_Amax(obj) moved to the F-16 example, Casey's decision. It took a
        %   design object and read about 20 fields, so it broke the toolbox rule.
        %   The equation is unchanged, so Amax still reads 24.7036516658 ft^2.
        %   Its helpers stay here. Its TODOs, verbatim:
        %     % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        %     % TODO (7/28/2026): This seems too specific in this form. I like the idea of having conic/cross sections, but it should be generic.
        %     % Cross sections that the toolbox can focus on: fuselage & main wings.
        %     % TODO (8/19/2026): This seems too high-fidelity to be in L2.
        %   The first TODO is now done.

        % ================================================================== %
        % LOW-LEVEL: pure math on scalars/vectors, no object. These area-ruled
        % Amax formulas are the only ones originating in this toolbox; every
        % other equation is reused from GeomL2 / GeometryBase.
        % ================================================================== %

        % Mod (08/19/2026) (Claude) -- the uncited flag is withdrawn. This is unit
        %   scaling: a fraction times a reference length gives a length. No
        %   citation needed. One assumption to know: the shape stretches affinely,
        %   so the normalized table must stay valid at a new fuselage size.
        function [x, w, h] = denormalize_frames(frames_normalized, L_fus, W_max, H_max)
        %DENORMALIZE_FRAMES  Station table [ft] from a normalized table.
        %   Columns are x/L, w/W_max, h/H_max.
            arguments
                frames_normalized (:,3) double
                L_fus             (1,1) double {mustBePositive}
                W_max             (1,1) double {mustBePositive}
                H_max             (1,1) double {mustBePositive}
            end
            x = frames_normalized(:,1) * L_fus;
            w = frames_normalized(:,2) * W_max;
            h = frames_normalized(:,3) * H_max;
        end

        % Mod (08/19/2026) (Claude) -- the math is generic, the SHAPE is not.
        %   Integrating cos(pi/2*t) over the quarter outline gives exactly
        %   A = (2/pi)*w*h. So the arithmetic needs no citation, but the cosine
        %   cross-section does: it is Brandt's model. An ellipse would give
        %   (pi/4)*w*h, so the cosine section is about 19 % smaller.
        %   [Brandt F-16A.xls, Geom frame model]
        %   _TODO -- I_cos = 0.63137515 is Brandt's 6-point trapezoid of the same
        %   integral. The exact value is 2/pi = 0.63661977, so every frame area
        %   reads 0.82 % low. compute_frame_cs_area_exact below holds the exact
        %   form and has NO CONSUMER. Pick one at the next Amax review.
        function A = compute_frame_cs_area(w, h)
        %COMPUTE_FRAME_CS_AREA  Cross-section area [ft^2] of one cosine frame.
            arguments
                w (:,1) double {mustBeNonnegative}
                h (:,1) double {mustBeNonnegative}
            end
            N_PTS = 6;                                % Brandt's sampling grid
            t     = linspace(0, 1, N_PTS);            % [0 .2 .4 .6 .8 1]
            I_cos = trapz(t, cos(pi/2 * t));          % 0.63137515
            A     = w .* h * I_cos;
        end

        % _TODO (08/19/2026) (Claude) -- NO CONSUMER. The exact 2/pi form. See
        %   the note on compute_frame_cs_area above.
        function A = compute_frame_cs_area_exact(w, h)
            arguments
                w (:,1) double {mustBeNonnegative}
                h (:,1) double {mustBeNonnegative}
            end
            A = (2/pi) * w .* h;
        end

        
        function val = compute_c_root_exposed(c_root, c_tip, span_root_to_tip, span_clipped)
            arguments
                c_root           (1,1) double {mustBePositive}
                c_tip            (1,1) double {mustBeNonnegative}
                span_root_to_tip (1,1) double {mustBePositive}
                span_clipped     (1,1) double {mustBeNonnegative}
            end
            val = c_root - (span_clipped/span_root_to_tip) * (c_root - c_tip);
        end

        % TODO (8/14/2026): Include "lifting" in the name, to specifiy that this is for "lifting_surfaces."
        function A = compute_surface_cs_area(x, Xexp, c_exp_root, c_tip, ...
                                             G_hs_exp, sweep_LE_deg, tc)
        %COMPUTE_SURFACE_CS_AREA  Cross-section [ft^2] contributed by one
        %   lifting surface at each station, under Brandt's cosine
        %   area-distribution model.  [Brandt F-16A.xls, Geom!Y/AA/AC 26:45]
        %   Xexp is the exposed-root leading-edge station; G_hs_exp the
        %   exposed half-span (mirrored) or full span (VT).
        %
        %   Two Brandt spreadsheet bugs are NOT replicated (each worth 0.000 %
        %   of Amax): the VT column's wing-tip-chord copy-paste and the strake
        %   column's divisor.
        %
        %   TODO: the cosine area-distribution model is Brandt's own
        %   construction with no textbook source in this repo (todo.md Phase 2).
        %   Mod (08/19/2026) (Claude) -- searched for a substitute. None exists.
        %   Two parts, and only one needs a source:
        %     y_span = min(G_hs_exp, (x-Xexp)/tan_sweep) is plain planform
        %       geometry, so it needs no citation.
        %     (1 - cos(2*pi*xi)) is a shaping function, not geometry. Raymer
        %       Fig. 7.38, p. 207 wants a station-area table, but he expects the
        %       designer to MEASURE each area off the layout. He gives no formula
        %       for a lifting surface. So this factor stays Brandt's.
            arguments
                x            (:,1) double
                Xexp         (1,1) double
                c_exp_root   (1,1) double {mustBePositive}
                c_tip        (1,1) double {mustBeNonnegative}
                G_hs_exp     (1,1) double {mustBePositive}
                sweep_LE_deg (1,1) double
                tc           (1,1) double {mustBeNonnegative}
            end
            DIVISOR = 2;                 % wing / HT / VT (Brandt's strake col. uses 1 — see above)

            tan_sweep   = tand(sweep_LE_deg);
            X_max_range = max(c_exp_root, G_hs_exp*tan_sweep + c_tip);
            X_max_cos   = X_max_range;   % one expression: the VT copy-paste bug is NOT replicated

            active = x > Xexp & x < Xexp + X_max_range;
            y_span = min(G_hs_exp, (x - Xexp)/tan_sweep);
            xi     = (x - Xexp)/X_max_cos;

            A = zeros(size(x));
            A(active) = tc * (c_exp_root + c_tip) * y_span(active) ...
                        .* (1 - cos(2*pi*xi(active))) / DIVISOR;
        end

        % TODO (8/14/2026): Unsourced/uncited.
        % Mod (08/19/2026) (Claude) -- the source is Brandt, as Casey thought:
        %   4.5 * 3.5370 = 15.9166 ft [Brandt F-16A.xls, Geom!D475]. It is a
        %   fineness-ratio rule of thumb, not a textbook equation.
        % Mod (08/19/2026) (Claude) -- SUPERSEDED, NO CONSUMER. Casey chose
        %   Raymer's statistical form, which already sits in the propulsion
        %   toolbox: PropL2.engine_length_AB(T, M) = 0.255*T^0.4*M^0.2
        %   [Raymer 6th ed. Eq. 10.11]. F16GeomL3.get.L_engine now calls that.
        %   Eq. 10.1 (L = L_nominal*SF^0.4) was the other option; it needs a
        %   nominal engine's length and thrust, which this repo does not hold.
        %   This function stays as the record of Brandt's value, 15.9166 ft.
        function val = compute_engine_length(D_engine)
        %COMPUTE_ENGINE_LENGTH  Engine length [ft] at a fixed fineness ratio.
            arguments
                D_engine (1,1) double {mustBePositive}
            end
            L_OVER_D = 4.5;
            val      = L_OVER_D * D_engine;
        end

        function A = compute_nacelle_cs_area(x, n_engines, D_engine, x_start, x_end)
            arguments
                x         (:,1) double
                n_engines (1,1) double {mustBeNonnegative}
                D_engine  (1,1) double {mustBeNonnegative}
                x_start   (1,1) double
                x_end     (1,1) double
            end
            A = zeros(size(x));
            A(x >= x_start & x <= x_end) = n_engines * pi * D_engine^2 / 4;
        end

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        % TODO (8/14/2026): Still seems too design-specific to be inside this toolbox. I don't like how it references Brandt, because
        % I want the toolboxes to be independent from Brandt as much as possible.
        function val = compute_Amax_area_ruled(A_total_stations, n_engines, D_engine)
            arguments
                A_total_stations (:,1) double
                n_engines        (1,1) double {mustBeNonnegative}
                D_engine         (1,1) double {mustBeNonnegative}
            end
            INLET_FLOW_THROUGH_DIVISOR = 5;   % ★ Brandt's bare literal — see above
            val = max(A_total_stations) ...
                  - n_engines * pi * D_engine^2 / INLET_FLOW_THROUGH_DIVISOR;
        end


        % Mod (08/19/2026) (Claude)
        function val = compute_s_wet_from_perimeter_curve(x, P)
        %COMPUTE_S_WET_FROM_PERIMETER_CURVE  Wetted area [ft^2] under a perimeter curve.
        %   [Raymer 6th ed. Fig. 7.37, p. 206; Fig. 7.4, p. 171]
        %   x is the longitudinal station. P is the cross-section perimeter at
        %   each station. The area under the curve is the wetted area.
        %   Raymer uses it for any component: fuselage, wing, tail, canopy,
        %   nacelle. It holds no shape model, so the caller supplies P from
        %   whatever cross-section it has.
        %   Leave joined intersections out of P. A wing-to-fuselage joint is not
        %   wetted.
            arguments
                x double {mustBeVector}
                P double {mustBeVector, mustBeNonnegative}
            end
            if numel(x) ~= numel(P)
                error('GeomL3:perimeterCurveLengthMismatch', ...
                    'x and P must be the same length; got %d and %d.', ...
                    numel(x), numel(P));
            end
            val = trapz(x, P);
        end

        % Mod (08/19/2026) (Claude)
        % Note (8/19/2026)(Casey): Moved from L2 to L3 because L3 no longer deals in simple shapes.
        function val = compute_s_wet_from_control_stations(frame_x, frame_zchine, frame_z, frame_w, frame_h)
        %COMPUTE_S_WET_FROM_CONTROL_STATIONS  Wetted area [ft^2] from a station table.
        %   Inputs are per-station vectors (station x, chine z, centreline z,
        %   width, height), one entry per station. It builds the perimeter at
        %   each station with compute_frame_perimeter, then integrates with
        %   compute_s_wet_from_perimeter_curve.
        %   The leading (0, 0) station closes the nose to a point. A component
        %   that does not close to a point needs a different first station.
        %   F-16A value: 677.9260 ft^2 [Brandt F-16A.xls, Geom!D23].
            arguments
                frame_x      double {mustBeVector}
                frame_zchine double {mustBeVector}
                frame_z      double {mustBeVector}
                frame_w      double {mustBeVector, mustBePositive}
                frame_h      double {mustBeVector, mustBePositive}
            end
            nf = numel(frame_x);
            if ~isequal(nf, numel(frame_zchine), numel(frame_z), numel(frame_w), numel(frame_h))
                error('GeomL3:frameVectorLengthMismatch', ...
                    ['frame_x/frame_zchine/frame_z/frame_w/frame_h must all be ' ...
                     'the same length (one entry per fuselage frame); got %d, ' ...
                     '%d, %d, %d, %d.'], nf, numel(frame_zchine), numel(frame_z), ...
                    numel(frame_w), numel(frame_h));
            end
            P = zeros(1, nf);
            for i = 1:nf
                P(i) = GeomL3.compute_frame_perimeter(frame_w(i), frame_h(i), ...
                           frame_zchine(i), frame_z(i));
            end

            val = GeomL3.compute_s_wet_from_perimeter_curve( ...
                      [0, reshape(frame_x, 1, [])], [0, P]);
        end

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        % TODO (7/28/2026): This seems too high-fidelity to be in L2. Also, there's areference to "chines," which
        % are design-specific, and therefore don't belong inside this toolbox.
        % Mod (08/18/2026) (Claude) -- moved from GeomL2, unchanged. Both TODOs
        %   are now done: this is the F-16 example, not a toolbox.
        % Mod (08/19/2026) (Claude)
        function P = compute_frame_perimeter(w, h, z_chine, z_center)
        %COMPUTE_FRAME_PERIMETER  Perimeter [ft] of one station under the chine
        %   cosine cross-section model.  [Brandt F-16A.xls, Geom frame model]
        %   Sampled at 6 points per quarter. The left side is symmetric, so the
        %   full perimeter is twice the right-half path length.
        %
        %   NO CHINE: set z_chine = z_center. Note what that gives. The outline
        %   has y linear in t and z cosine in t, so it is NOT an ellipse. For a
        %   round section of diameter D it returns 17.5275 against the true
        %   pi*D = 18.8496, which is 7.01 % low. More sample points do not close
        %   the gap: the curve converges to 17.5643, still 6.8 % low. So this
        %   model suits a chined body. A round or oval body needs an ellipse
        %   perimeter instead.
        %   _TODO (08/19/2026) (Claude): the cosine section model has no textbook
        %   source in docs/reference_extracts/. Only the integrator above is cited.
        %   Mod (08/19/2026) (Claude) -- VECTORIZED. It takes one station or a
        %   whole column of them, and returns one P per station. A scalar call
        %   behaves exactly as before.
            arguments
                w        double {mustBePositive,  mustBeVector}
                h        double {mustBePositive,  mustBeVector}
                z_chine  double {mustBeVector}
                z_center double {mustBeVector}
            end
            w = w(:); h = h(:); z_chine = z_chine(:); z_center = z_center(:);
            if ~isscalar(unique([numel(w), numel(h), numel(z_chine), numel(z_center)]))
                error('GeomL3:stationVectorLengthMismatch', ...
                    'w, h, z_chine and z_center must be the same length; got %d, %d, %d, %d.', ...
                    numel(w), numel(h), numel(z_chine), numel(z_center));
            end
            n_pts = 6;
            z_top = z_center + h / 2;
            z_bot = z_center - h / 2;

            t    = linspace(0, 1, n_pts);          % 1 x n_pts, broadcast over rows
            y    = (w / 2) .* t;
            z_up = z_chine + (z_top - z_chine) .* cos(pi/2 * t);
            z_dn = z_chine + (z_bot - z_chine) .* cos(pi/2 * t);

            % Right-side path: top-center -> right-chine -> bottom-center.
            y_path = [y,    fliplr(y(:, 1:end-1))];
            z_path = [z_up, fliplr(z_dn(:, 1:end-1))];

            ds = sqrt(diff(y_path, 1, 2).^2 + diff(z_path, 1, 2).^2);
            P  = 2 * sum(ds, 2);   % full perimeter (left side symmetric)
        end


    end
end

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

        % ================================================================== %
        % HIGH-LEVEL: take the object, return the result. Each selects a reused
        % GeomL2 low-level static — no new formula here. get_Amax is the
        % exception: it assembles the area-ruling statics further down.
        % ================================================================== %

        function val = get_S_wet(obj)
            val = GeomL3.get_S_wet_wing(obj) + GeomL3.get_S_wet_HT(obj) + ...
                  GeomL3.get_S_wet_VT(obj)   + GeomL3.get_S_wet_fuselage(obj) + ...
                  GeomL3.get_S_wet_duct(obj);
        end

        function val = get_S_wet_wing(obj)
        %GET_S_WET_WING  Wing wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
        %   The wing is modelled uniform-t/c, so Eq. 12.1 degenerates to its
        %   equal-t/c special case here.
            val = GeomL2.compute_roskam_planform(obj.S_exposed_wing, ...
                      obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
        end

        function val = get_S_wet_HT(obj)
        %GET_S_WET_HT  Horizontal-tail wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
        %   Fed the T.O. 1F-16A-1 Sec. I biconvex root/tip t/c splits.
            val = GeomL2.compute_roskam_planform(obj.S_exposed_ht, ...
                      obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht);
        end

        function val = get_S_wet_VT(obj)
        %GET_S_WET_VT  Vertical-tail wetted area [ft^2].  [Roskam Vol. II Eq. 12.1]
        %   Fed the T.O. 1F-16A-1 Sec. I biconvex root/tip t/c splits.
            val = GeomL2.compute_roskam_planform(obj.S_exposed_vt, ...
                      obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt);
        end

        function val = get_S_wet_fuselage(obj)
        %GET_S_WET_FUSELAGE  Fuselage wetted area [ft^2].  [Roskam Vol. II Eq. 12.3]
        %   D_fus is the equivalent diameter (W+H)/2, not the max depth.
            val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        function val = get_S_wet_duct(obj)
        %GET_S_WET_DUCT  Inlet + duct wetted area [ft^2].  [Raymer 6th ed. Sec. 7.3]
        %   D_inlet == D_exit here, so the frustum degenerates to a cylinder.
            val = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        end

        function val = get_S_exposed_wing(obj)
        %GET_S_EXPOSED_WING  Wing exposed area [ft^2] (passthrough; the
        %   Dependent getter does the compute).
            val = obj.S_exposed_wing;
        end

        % TODO (7/28/2026): This seems too specific to be inside this toolbox. Relocate this to the F-16 example.
        function val = get_Amax(obj)
            % Max cross-sectional area of the whole aircraft (fuselage + wings).
            [x, w, h] = GeomL3.denormalize_frames(obj.frames_normalized, ...
                            obj.L_fus, obj.W_max_fuselage, obj.H_max_fuselage);

            A_fuse = GeomL3.compute_frame_cs_area(w, h);

            A_wing = GeomL3.compute_surface_cs_area(x, obj.Xexp_wing, ...
                         obj.c_exp_root_wing, obj.c_tip_wing, ...
                         obj.G_hs_exp_wing, obj.LE_sweep_wing, obj.tc_wing);

            A_HT   = GeomL3.compute_surface_cs_area(x, obj.Xexp_ht, ...
                         obj.c_exp_root_ht, obj.c_tip_ht, ...
                         obj.G_hs_exp_ht, obj.LE_sweep_ht, obj.tc_ht);

            A_VT   = GeomL3.compute_surface_cs_area(x, obj.Xexp_vt, ...
                         obj.c_exp_root_vt, obj.c_tip_vt, ...
                         obj.G_hs_exp_vt, obj.LE_sweep_vt, obj.tc_vt);

            A_nac  = GeomL3.compute_nacelle_cs_area(x, obj.n_engines, ...
                         obj.D_inlet, obj.x_inlet, obj.x_nacelle_aft);

            val = GeomL3.compute_Amax_area_ruled( ...
                      A_fuse + A_wing + A_HT + A_VT + A_nac, ...
                      obj.n_engines, obj.D_inlet);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math on scalars/vectors, no object. These area-ruled
        % Amax formulas are the only ones originating in this toolbox; every
        % other equation is reused from GeomL2 / GeometryBase.
        % ================================================================== %

        function [x, w, h] = denormalize_frames(frames_normalized, L_fus, W_max, H_max)
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

        function A = compute_frame_cs_area(w, h)
            arguments
                w (:,1) double {mustBeNonnegative}
                h (:,1) double {mustBeNonnegative}
            end
            N_PTS = 6;                                % Brandt's sampling grid
            t     = linspace(0, 1, N_PTS);            % [0 .2 .4 .6 .8 1]
            I_cos = trapz(t, cos(pi/2 * t));          % 0.63137515
            A     = w .* h * I_cos;
        end

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

        function val = compute_engine_length(D_engine)
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

    end
end

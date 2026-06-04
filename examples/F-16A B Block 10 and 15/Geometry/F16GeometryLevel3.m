classdef F16GeometryLevel3 < GeometryModelLevel3
     %F16GEOMETRYLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     % Personal notes: After working with this particular design, trying to
     % generalize delta-wing geometry computations for all other designs
     % has proven difficult due to their particular needs varying between
     % aircraft. I think it's wiser to relegate fewer "general" functions
     % to the "general low-level geometry class" than it is to try and fit
     % as many particularities into that same class.
     % So what I'm saying is that Geometry should be very barebones, unless
     % it's the user-end class that they create themselves.

     properties
          mainwings
          HT
          VT
          fuselage
          strakes
          design
     end

     methods
          function obj = F16GeometryLevel3(design)
               obj.mainwings = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'QC_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'exposed_halfspan', [], ...
                    'exposed_rc', [], ...
                    'c_tip', [], ...
                    'lambda', [], ...
                    'x_loc', [], ...
                    'airfoil_type', []);

               obj.HT = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'QC_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'exposed_halfspan', [], ...
                    'exposed_rc', [], ...
                    'c_tip', [], ...
                    'lambda', [], ...
                    'x_loc', [], ...
                    'c_HT', [], ...
                    'airfoil_type', []);

               obj.VT = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'QC_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'exposed_halfspan', [], ...
                    'exposed_rc', [], ...
                    'c_tip', [], ...
                    'lambda', [], ...
                    'x_loc', [], ...
                    'c_VT', [], ...
                    'airfoil_type', []);

               obj.strakes = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'QC_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'exposed_halfspan', [], ...
                    'exposed_rc', [], ...
                    'c_tip', [], ...
                    'lambda', [], ...
                    'x_loc', [], ...
                    'airfoil_type', []);

               obj.fuselage = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'L', [], ...
                    'W_max', [], ...
                    'h_max', []);

               obj.design = struct(...
                    'S_wet', [],...
                    'W_max', [], ...
                    'total_length', []);

               % Now load the design's geometry!
               if nargin > 0 && ~isempty(design)
                    GeometryUtils.loaddesigngeometry(obj, design)
               end

               % Load the planform area of any strakes
               obj.strakes.S_ref = design.geom.wings.Strakes.PlanformAreaft2;
               obj.strakes.tc = design.geom.wings.Strakes.tc;
               obj.strakes.LE_sweep = design.geom.wings.Strakes.SweepLEDeg;
               obj.strakes.AR = design.geom.wings.Strakes.AspectRatio;
               obj.strakes.lambda = design.geom.wings.Strakes.TaperRatio;
               obj.strakes.c_tip = design.geom.wings.Strakes.TipChordLengthft;
               obj.strakes.c_root = design.geom.wings.Strakes.RootChordLengthft;
               obj.strakes.exposed_halfspan = design.geom.wings.Strakes.ExposedHalfspan;
               obj.strakes.exposed_rc = design.geom.wings.Strakes.ExposedRootChord;

               % Get the tip lengths of the wings
               obj.mainwings.c_tip = design.geom.wings.Main.TipChordLengthft;
               obj.strakes.c_tip = design.geom.wings.Strakes.TipChordLengthft;
               obj.HT.c_tip = design.geom.wings.HorizontalTail.TipChordLengthft;
               obj.VT.c_tip = design.geom.wings.VerticalTail.TipChordLengthft;

               % Get S_ref for tails
               obj.HT.S_ref = design.geom.wings.HorizontalTail.PlanformAreaft2;
               obj.VT.S_ref = design.geom.wings.VerticalTail.PlanformAreaft2;

               % Get S_exposed for each component
               obj.mainwings.S_exposed = GeometryLevel3.get_S_exposed(obj.mainwings.c_tip, obj.mainwings.exposed_rc, obj.mainwings.exposed_halfspan);
               obj.HT.S_exposed = GeometryLevel3.get_S_exposed(obj.HT.c_tip, obj.HT.exposed_rc, obj.HT.exposed_halfspan);
               obj.VT.S_exposed = GeometryLevel3.get_S_exposed(obj.VT.c_tip, obj.VT.exposed_rc, obj.VT.exposed_halfspan);
               obj.strakes.S_exposed = GeometryLevel3.get_S_exposed(obj.strakes.c_tip, obj.strakes.c_root, obj.strakes.exposed_halfspan);

               % Get S_wet for each component
               obj.mainwings.S_wet = GeometryLevel3.get_S_wet_wing(obj.mainwings.S_exposed, obj.mainwings.tc);
               obj.HT.S_wet = GeometryLevel3.get_S_wet_wing(obj.HT.S_exposed, obj.HT.tc);
               obj.VT.S_wet = GeometryLevel3.get_S_wet_wing(obj.VT.S_exposed, obj.VT.tc);
               obj.fuselage.S_wet = obj.get_S_wet_fuselage(obj.design.total_length, obj.fuselage.W_max, obj.fuselage.h_max);
               obj.strakes.S_wet = GeometryLevel3.get_S_wet_wing(obj.strakes.S_exposed, obj.strakes.tc);
               % obj.fuselage.S_wet = get_S_wet_fuselage(obj, 46.50, 7.0, obj.fuselage.h_max);

               % Load the planform area of tail
               % [obj.HT.S_ref, obj.VT.S_ref] = GeometryLevel3.Tail_Sizing(obj.VT.c_VT, obj.HT.c_HT, obj.mainwings.b, obj.mainwings.S_ref, obj.fuselage.L, obj.mainwings.MeanGeometricChord);


          end

          % Recompute main wing dimensions using S_ref
          % This should return a struct instead of directly updating the
          % geometry objects.
          function [b, c_root, c_tip, S_exposed, S_wet] = reconstruct_wings(geometry_obj, AR, lambda, S_ref, exposed_rc, exposed_halfspan, tc)
               b = GeometryLevel3.compute_b(AR, S_ref);
               c_root = GeometryLevel3.compute_c_root(S_ref, b, lambda);
               c_tip = GeometryLevel3.compute_c_tip(lambda, c_root);
               S_exposed = GeometryLevel3.get_S_exposed(c_tip, exposed_rc, exposed_halfspan);
               S_wet = GeometryLevel3.get_S_wet_wing(S_exposed, tc);
          end

          % Recompute horizontal and vertical tail dimensions using S_ref
          % function output = reconstruct_tailwings(geometry_obj, S_HT, S_VT)
          %      geometry_obj.HT.b = sqrt(geometry_obj.HT.AR*S_HT);
          %      geometry_obj.HT.c_root = (2 * geometry_obj.HT.S_ref)/(geometry_obj.HT.b*(1 + geometry_obj.HT.lambda));
          %      geometry_obj.HT.c_tip = geometry_obj.HT.lambda * geometry_obj.HT.c_root;
          %      geometry_obj.HT.S_exposed = GeometryLevel3.get_S_exposed(geometry_obj.HT.c_tip, geometry_obj.HT.exposed_rc, geometry_obj.HT.exposed_halfspan);
          %      geometry_obj.HT.S_wet = GeometryLevel3.get_S_wet_wing(geometry_obj.HT.S_exposed, geometry_obj.HT.tc);
          %
          %      geometry_obj.VT.b = sqrt(geometry_obj.VT.AR*S_VT);
          %      geometry_obj.VT.c_root = (2 * geometry_obj.VT.S_ref)/(geometry_obj.VT.b*(1 + geometry_obj.VT.lambda));
          %      geometry_obj.VT.c_tip = geometry_obj.VT.lambda * geometry_obj.VT.c_root;
          %      geometry_obj.VT.S_exposed = GeometryLevel3.get_S_exposed(geometry_obj.VT.c_tip, geometry_obj.VT.exposed_rc, geometry_obj.VT.exposed_halfspan);
          %      geometry_obj.VT.S_wet = GeometryLevel3.get_S_wet_wing(geometry_obj.VT.S_exposed, geometry_obj.VT.tc);
          % end

          % % size control surfaces
          % function S_control = size_control_surface_raymer( ...
          %           deltaCL_req, ...
          %           S_ref, ...
          %           K_f, ...
          %           dcl_ddelta_airfoil, ...
          %           delta_max_deg, ...
          %           Lambda_HL_deg)
          %
          %      % Raymer-style plain-flap/control-surface sizing.
          %      % deltaCL_req: required section/surface lift coefficient increment
          %      % S_ref: parent reference area, e.g. S_h for elevator, S_v for rudder, S_w for flap/aileron
          %      % K_f: empirical correction factor
          %      % dcl_ddelta_airfoil: 2D lift increment per radian of deflection
          %      % delta_max_deg: maximum control deflection in degrees
          %      % Lambda_HL_deg: hinge-line sweep angle in degrees
          %
          %      delta_max_rad = deg2rad(delta_max_deg);
          %
          %      S_control = (deltaCL_req * S_ref) / ...
          %           (0.9 * K_f * dcl_ddelta_airfoil * delta_max_rad * cosd(Lambda_HL_deg));
          % end
          %
          % function L_hinge = compute_hinge_length_from_stations(y_in, y_out, Lambda_h_deg)
          %      % Computes hinge length from projected span and hinge-line sweep.
          %      %
          %      % y_in: inboard span station [ft]
          %      % y_out: outboard span station [ft]
          %      % Lambda_h_deg: hinge-line sweep angle [deg]
          %
          %      b_control = abs(y_out - y_in);
          %      L_hinge = b_control / cosd(Lambda_h_deg);
          % end
          %
          % % Estimate the wetted area of the aircraft
          function S_wet = get_design_S_wet(geometry_obj, W_TO)
               % c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               % d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               % S_wet = 10^(c) * W_TO^(d); % ft^2
               S_wet = GeometryLevel3.get_design_S_wet(W_TO);
               % Component-level analysis... so sum the exposed wetted areas of
               % wings, strakes, tail, fuselage, nose.
               % Get exposed areas
               S_exp_w = geometry_obj.mainwings.S_exposed;
               S_exp_strake = geometry_obj.strakes.S_exposed;
               S_exp_VT = geometry_obj.VT.S_exposed;
               S_exp_HT = geometry_obj.HT.S_exposed;

               % Get wetted areas of the exposed areas
               S_wet_w = geometry_obj.mainwings.S_wet;
               S_wet_strake = geometry_obj.strakes.S_wet;
               S_wet_VT = geometry_obj.VT.S_wet;
               S_wet_HT = geometry_obj.HT.S_wet;
               S_wet_fuselage = geometry_obj.fuselage.S_wet;

               % Where's the engine inlet?

               % Get total wetted area
               S_wet = S_wet_w + S_wet_strake + S_wet_VT + S_wet_HT + S_wet_fuselage;
          end

          % Estimate wetted area (fuselage) (Brandt's 2/3 cylinder + 1/3
          % cone approximation)
          % This is here because it's unique to the F-16.
          function S_wet_fuselage = get_S_wet_fuselage(geometry_obj, fuselage_length, fuselage_max_width, max_height)
               S_wet_fuselage = (5/6) * fuselage_length * (fuselage_max_width + max_height)*2*pi/4;
          end
          %
          % % Size the tail
          % function [S_HT, S_VT] = size_tail(geometry_obj, design, S_ref)
          %      b_w = geometry_obj.mainwings.b;
          %      c_VT = geometry_obj.VT.c_VT;
          %      c_HT = geometry_obj.HT.c_HT;
          %      L_fus = geometry_obj.fuselage.L;
          %      cbar_geo_w = design.geom.wings.Main.MeanGeometricChord;
          %      [S_HT, S_VT] = GeometryLevel3.Tail_Sizing(c_VT, c_HT, b_w, S_ref, L_fus, cbar_geo_w);
          % end
          %
          % % Estimate exposed surface area (lifting surface)
          % % Source: Brandt, "F16A", "Geom" sheet, cell H7.
          % function S_exposed = get_S_exposed(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
          %      S_exposed = exposed_halfspan*(exposed_rc + tip_length);
          % end
          %
          % % Estimate exposed wetted areas (lifting surfaces)
          % function S_exposed = get_S_wet_wing(geometry_obj, S_exposed, tc)
          %      S_exposed = S_exposed*(1.977 + 0.52*tc); % Brandt, "Geom" sheet, cell B13
          % end
          %
          % % Estimate wetted area (fuselage) (Brandt's 2/3 cylinder + 1/3
          % % cone approximation)
          % function S_wet_fuselage = get_S_wet_fuselage(fuselage_length, fuselage_max_width, max_height)
          %      S_wet_fuselage = (5/6) * fuselage_length * (fuselage_max_width + max_height)*2*pi/4;
          % end
          %
          % % Estimate wing sweep at quarter-chord (deg)
          % function qc_sweep = get_sweep_qc(b, LE_sweep_deg, root_chord, c_tip)
          %      qc_sweep = atand(tand(LE_sweep_deg) - (root_chord - c_tip)/(2*b));
          % end
     end
     methods (Access = private)

     end
end
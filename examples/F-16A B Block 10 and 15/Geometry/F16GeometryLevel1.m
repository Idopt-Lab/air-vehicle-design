classdef F16GeometryLevel1 < GeometryModelLevel1
     %F16GEOMETRYLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          mainwings
          HT
          VT
          strakes
          fuselage
          design
     end

     methods

          % CONSTRUCTOR
          function obj = F16GeometryLevel1(design, weight_obj)
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

               % Get main wing geometry
               obj.mainwings.c_tip = design.geom.wings.Main.TipChordLengthft;

               % % Get horizontal tail geometry
               % obj.HT.c_tip = design.geom.wings.HorizontalTail.TipChordLengthft;
               % 
               % % Get vertical tail geometry
               % obj.VT.c_tip = design.geom.wings.VerticalTail.TipChordLengthft;
               % 
               % % Get S_ref for tails
               % obj.HT.S_ref = design.geom.wings.HorizontalTail.PlanformAreaft2;
               % obj.VT.S_ref = design.geom.wings.VerticalTail.PlanformAreaft2;

               % % Get S_exposed for each component
               % obj.mainwings.S_exposed = obj.get_S_exposed_wing(obj.mainwings.c_tip, obj.mainwings.exposed_rc, obj.mainwings.exposed_halfspan);
               % obj.HT.S_exposed = obj.get_S_exposed_wing(obj.HT.c_tip, obj.HT.exposed_rc, obj.HT.exposed_halfspan);
               % obj.VT.S_exposed = obj.get_S_exposed_wing(obj.VT.c_tip, obj.VT.exposed_rc, obj.VT.exposed_halfspan);
               % obj.strakes.S_exposed = obj.get_S_exposed_wing(obj.strakes.c_tip, obj.strakes.c_root, obj.strakes.exposed_halfspan);
               %
               % % Get S_wet for each component
               % obj.mainwings.S_wet = obj.get_S_wet_wing(obj.mainwings.S_exposed, obj.mainwings.tc);
               % obj.HT.S_wet = obj.get_S_wet_wing(obj.HT.S_exposed, obj.HT.tc);
               % obj.VT.S_wet = obj.get_S_wet_wing(obj.VT.S_exposed, obj.VT.tc);
               % obj.fuselage.S_wet = GeometryLevel2.compute_S_wet_body(obj.design.total_length, obj.fuselage.W_max, obj.fuselage.h_max);
               % obj.strakes.S_wet = obj.get_S_wet_wing(obj.strakes.S_exposed, obj.strakes.tc);
               % obj.fuselage.S_wet = get_S_wet_fuselage(obj, 46.50, 7.0, obj.fuselage.h_max);

               % Load the planform area of tail
               % [obj.HT.S_ref, obj.VT.S_ref] = GeometryLevel2.Tail_Sizing(obj.VT.c_VT, obj.HT.c_HT, obj.mainwings.b, obj.mainwings.S_ref, obj.fuselage.L, obj.mainwings.MeanGeometricChord);

               % Compute the design's wetted area
               % obj.design.S_wet = obj.get_design_S_wet(A_top, A_side);
               % obj.design.S_wet = obj.get_design_S_wet;

               % Estimate fuselage length
               obj.fuselage.L = obj.get_fus_len("jet fighter", weight_obj.W_TO_guess);

               % % Get the tail stuff early
               % [obj.HT.c_HT, obj.VT.c_VT] = obj.est_tail_propers("jet fighter");
          end

          function L_fuselage = get_fus_len(geometry_obj, aircraft_type, W_TO)
               L_fuselage = GeometryLevel1.get_fus_len(aircraft_type, W_TO);
          end

          function S_wet = get_design_S_wet(geometry_obj, aircraft_type, W_TO)
               S_wet = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
          end
     end
end
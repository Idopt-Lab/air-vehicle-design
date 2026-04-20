classdef F16GeometryStuff < GeometryEstModel
     %F16GEOMETRYSTUFF Summary of this class goes here
     %   Detailed explanation goes here

     properties
          % Organize by physical object; separate into tail (horizontal,
          % vertical), fuselage, etc?
          % I should definitely use structs for this. Organize into wings,
          % tails, fuselage.
          % S_wet
          % S_exposed
          % S_HT
          % S_VT
          % L_VT
          % L_HT
          % c_VT
          % c_HT
          % S_ref
          % L_fus
          % MeanGeometricChord

          mainwings
          HT
          VT
          fuselage
          strakes
          design
     end

     methods


          function obj = F16GeometryStuff(design)
               obj.mainwings = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'airfoil_type', []);

               obj.HT = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'airfoil_type', []);

               obj.VT = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'airfoil_type', []);

               obj.strakes = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'b', [], ...
                    'c_root', [], ...
                    'MeanGeometricChord', [], ...
                    'LE_sweep', [], ...
                    'AR', [], ...
                    'xc', [], ...
                    'tc', [], ...
                    'airfoil_type', []);

               obj.fuselage = struct( ...
                    'S_ref', [], ...
                    'S_exposed', [], ...
                    'S_wet', [], ...
                    'L', [], ...
                    'W_max', []);

               obj.design = struct(...
                    'S_wet', []);

               % Now load the design's geometry!
               if nargin > 0 && ~isempty(design)
                    obj.loaddesigngeometry(design)
               end
          end

          % Load design geometry for initial calculations
          function loaddesigngeometry(obj, design)
               % ---------- Main wing ----------
               if isfield(design.geom.wings, 'Main')
                    wing = design.geom.wings.Main;

                    if isfield(wing, 'PlanformAreaft2')
                         obj.mainwings.S_ref = wing.PlanformAreaft2;
                    end
                    if isfield(wing, 'Spanft')
                         obj.mainwings.b = wing.Spanft;
                    end
                    if isfield(wing, 'RootChordLengthft')
                         obj.mainwings.c_root = wing.RootChordLengthft;
                    end
                    if isfield(wing, 'MeanGeometricChord')
                         obj.mainwings.MeanGeometricChord = wing.MeanGeometricChord;
                    end
                    if isfield(wing, 'SweepLEDeg')
                         obj.mainwings.LE_sweep = wing.SweepLEDeg;
                    end
                    if isfield(wing, 'AspectRatio')
                         obj.mainwings.AR = wing.AspectRatio;
                    end
                    if isfield(wing, 'xc')
                         obj.mainwings.xc = wing.xc;
                    end
                    if isfield(wing, 'tc')
                         obj.mainwings.tc = wing.tc;
                    end
               end

               % ---------- Horizontal tail ----------
               if isfield(design.geom.wings, 'HorizontalTail')
                    ht = design.geom.wings.HorizontalTail;

                    if isfield(ht, 'Spanft')
                         obj.HT.b = ht.Spanft;
                    end
                    if isfield(ht, 'RootChordLengthft')
                         obj.HT.c_root = ht.RootChordLengthft;
                    end
                    if isfield(ht, 'MeanGeometricChord')
                         obj.HT.MeanGeometricChord = ht.MeanGeometricChord;
                    end
                    if isfield(ht, 'SweepLEDeg')
                         obj.HT.LE_sweep = ht.SweepLEDeg;
                    end
                    if isfield(ht, 'AspectRatio')
                         obj.HT.AR = ht.AspectRatio;
                    end
                    if isfield(ht, 'xc')
                         obj.HT.xc = ht.xc;
                    end
                    if isfield(ht, 'tc')
                         obj.HT.tc = ht.tc;
                    end
               end

               % ---------- Vertical tail ----------
               if isfield(design.geom.wings, 'VerticalTail')
                    vt = design.geom.wings.VerticalTail;

                    if isfield(vt, 'Spanft')
                         obj.VT.b = vt.Spanft;
                    end
                    if isfield(vt, 'RootChordLengthft')
                         obj.VT.c_root = vt.RootChordLengthft;
                    end
                    if isfield(vt, 'MeanGeometricChord')
                         obj.VT.MeanGeometricChord = vt.MeanGeometricChord;
                    end
                    if isfield(vt, 'SweepLEDeg')
                         obj.VT.LE_sweep = vt.SweepLEDeg;
                    end
                    if isfield(vt, 'AspectRatio')
                         obj.VT.AR = vt.AspectRatio;
                    end
                    if isfield(vt, 'xc')
                         obj.VT.xc = vt.xc;
                    end
                    if isfield(vt, 'tc')
                         obj.VT.tc = vt.tc;
                    end
               end

               % ---------- Fuselage ----------
               if isfield(design.geom, 'fuselage') && isfield(design.geom.fuselage, 'Fuselage')
                    fus = design.geom.fuselage.Fuselage;

                    if isfield(fus, 'Lengthft')
                         obj.fuselage.L = fus.Lengthft;
                    end
                    if isfield(fus, 'MaxWidthft')
                         obj.fuselage.W_max = fus.MaxWidthft;
                    end
               end
          end

          % Add functions for estimating control surface sizing

          % Estimate the wetted area of the aircraft
          function output = get_design_S_wet(obj, W_TO)
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               obj.design.S_wet = 10^(c) * W_TO^(d); % ft^2
               output = obj.design.S_wet;
          end

          % Size the tail
          function [S_HT, S_VT] = size_tail(obj, design, S_ref)
               [S_HT, S_VT] = Tail_Sizing_IV(obj, design.geom.wings.VerticalTail.c_VT, design.geom.wings.HorizontalTail.c_HT, design.geom.wings.Main.Spanft, S_ref, design.geom.fuselage.Fuselage.Lengthft, design.geom.wings.Main.MeanGeometricChord);
          end

          % Estimate exposed wetted areas (lifting surfaces)
          function output = S_wet_est(obj, S_exposed, tc)
               output = S_exposed*(1.977 + 0.52*tc); % Brandt, "Geom" sheet, cell B13
          end
     end

     methods (Access = private)

          % Size the tail
          function [S_HT, S_VT] = Tail_Sizing_IV(obj, c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W)

               % NOTE: S_REF IS USED BUT ITS SUPPOSED TO BE S_REF OF THE
               % MAIN WINGS
               % Assuming tail located 90% down fuselage
               L_VT = L_fus*0.8;
               L_HT = L_fus*0.8; % Allow operator to adjust this, later.

               obj.VT.L = L_VT;
               obj.HT.L = L_HT;

               S_VT = c_VT*b_W*S_ref/obj.VT.L; % eq 6.28, 2nd edition

               S_HT = c_HT*Cbar_W*S_ref/obj.HT.L; % eq 6.29, 2nd edition

               obj.VT.S_ref = S_VT;
               obj.HT.S_ref = S_HT;

          end
     end
end
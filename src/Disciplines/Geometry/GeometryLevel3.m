classdef GeometryLevel3 < GeometryEstModel
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


          function obj = GeometryLevel3(design)
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
                    'tip_chord', [], ...
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
                    'tip_chord', [], ...
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
                    'tip_chord', [], ...
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
                    'tip_chord', [], ...
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
                    obj.loaddesigngeometry(design)
               end

               % Get S_exposed for each component
               obj.mainwings.S_exposed = get_S_exposed(obj, obj.mainwings.tip_chord, obj.mainwings.exposed_rc, obj.mainwings.exposed_halfspan);
               obj.HT.S_exposed = get_S_exposed(obj, obj.HT.tip_chord, obj.HT.exposed_rc, obj.HT.exposed_halfspan);
               obj.VT.S_exposed = get_S_exposed(obj, obj.VT.tip_chord, obj.VT.exposed_rc, obj.VT.exposed_halfspan);

               % Get S_wet for each component
               obj.mainwings.S_wet = get_S_wet_wing(obj, obj.mainwings.S_exposed, obj.mainwings.tc);
               obj.HT.S_wet = get_S_wet_wing(obj, obj.HT.S_exposed, obj.HT.tc);
               obj.VT.S_wet = get_S_wet_wing(obj, obj.VT.S_exposed, obj.VT.tc);
               obj.fuselage.S_wet = get_S_wet_fuselage(obj, obj.design.total_length, obj.fuselage.W_max, obj.fuselage.h_max);
               % obj.fuselage.S_wet = get_S_wet_fuselage(obj, 46.50, 7.0, obj.fuselage.h_max);

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
                    if isfield(wing, 'ExposedHalfspan')
                         obj.mainwings.exposed_halfspan = wing.ExposedHalfspan;
                    end
                    if isfield(wing, 'ExposedRootChord')
                         obj.mainwings.exposed_rc = wing.ExposedRootChord;
                    end
                    if isfield(wing, 'TipChordLengthft')
                         obj.mainwings.tip_chord = wing.TipChordLengthft;
                    end
                    if isfield(wing, 'AngleOfQuarterchordLinerad')
                         obj.mainwings.QC_sweep = rad2deg(wing.AngleOfQuarterchordLinerad)
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
                    if isfield(ht, 'ExposedHalfspan')
                         obj.HT.exposed_halfspan = ht.ExposedHalfspan;
                    end
                    if isfield(ht, 'ExposedRootChord')
                         obj.HT.exposed_rc = ht.ExposedRootChord;
                    end
                    if isfield(ht, 'TipChordLengthft')
                         obj.HT.tip_chord = ht.TipChordLengthft;
                    end
                    if isfield(ht, 'AngleOfQuarterchordLinerad')
                         obj.HT.QC_sweep = rad2deg(ht.AngleOfQuarterchordLinerad);
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
                    if isfield(vt, 'ExposedHalfspan')
                         obj.VT.exposed_halfspan = vt.ExposedHalfspan;
                    end
                    if isfield(vt, 'ExposedRootChord')
                         obj.VT.exposed_rc = vt.ExposedRootChord;
                    end
                    if isfield(vt, 'TipChordLengthft')
                         obj.VT.tip_chord = vt.TipChordLengthft;
                    end
                    if isfield(vt, 'AngleOfQuarterchordLinerad')
                         obj.VT.QC_sweep = rad2deg(vt.AngleOfQuarterchordLinerad);
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
                    if isfield(fus, 'MaxHeightft')
                         obj.fuselage.h_max = fus.MaxHeightft;
                    end
               end

               % ---------- Design ----------
               if isfield(design.geom, 'fuselage') && isfield(design.geom.fuselage, 'Fuselage')
                    tot = design.geom.fuselage.Total;

                    if isfield(tot, 'Lengthft')
                         obj.design.total_length = tot.Lengthft;
                    end
                    if isfield(tot, 'MaxWidthft')
                         obj.design.W_max = tot.MaxWidthft;
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

          % Estimate exposed surface area (lifting surface)
          % Source: Brandt, "F16A", "Geom" sheet, cell H7.
          function output = get_S_exposed(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
               output = exposed_halfspan*(exposed_rc + tip_length);
          end

          % Estimate exposed wetted areas (lifting surfaces)
          function output = get_S_wet_wing(geometry_obj, S_exposed, tc)
               output = S_exposed*(1.977 + 0.52*tc); % Brandt, "Geom" sheet, cell B13
          end

          % Estimate wetted area (fuselage) (Brandt's 2/3 cylinder + 1/3
          % cone approximation)
          function output = get_S_wet_fuselage(geometry_obj, fuselage_length, fuselage_max_width, max_height)
               output = (5/6) * fuselage_length * (fuselage_max_width + max_height)*2*pi/4;
          end

          % Estimate wing sweep at quarter-chord (deg)
          function output = get_sweep_qc(geometry_obj, b, LE_sweep_deg, root_chord, tip_chord)
               output = atand(tand(LE_sweep_deg) - (root_chord - tip_chord)/(2*b));
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
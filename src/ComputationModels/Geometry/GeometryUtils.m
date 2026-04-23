classdef GeometryUtils
     %GEOMETRYUTILS Summary of this class goes here
     %   Detailed explanation goes here

     methods (Static)
          % Load design geometry for initial calculations
          function loaddesigngeometry(geometry_obj, design)
               % ---------- Main wing ----------
               if isfield(design.geom.wings, 'Main')
                    wing = design.geom.wings.Main;

                    if isfield(wing, 'PlanformAreaft2')
                         geometry_obj.mainwings.S_ref = wing.PlanformAreaft2;
                    end
                    if isfield(wing, 'Spanft')
                         geometry_obj.mainwings.b = wing.Spanft;
                    end
                    if isfield(wing, 'RootChordLengthft')
                         geometry_obj.mainwings.c_root = wing.RootChordLengthft;
                    end
                    if isfield(wing, 'MeanGeometricChord')
                         geometry_obj.mainwings.MeanGeometricChord = wing.MeanGeometricChord;
                    end
                    if isfield(wing, 'SweepLEDeg')
                         geometry_obj.mainwings.LE_sweep = wing.SweepLEDeg;
                    end
                    if isfield(wing, 'AspectRatio')
                         geometry_obj.mainwings.AR = wing.AspectRatio;
                    end
                    if isfield(wing, 'xc')
                         geometry_obj.mainwings.xc = wing.xc;
                    end
                    if isfield(wing, 'tc')
                         geometry_obj.mainwings.tc = wing.tc;
                    end
                    if isfield(wing, 'ExposedHalfspan')
                         geometry_obj.mainwings.exposed_halfspan = wing.ExposedHalfspan;
                    end
                    if isfield(wing, 'ExposedRootChord')
                         geometry_obj.mainwings.exposed_rc = wing.ExposedRootChord;
                    end
                    if isfield(wing, 'TipChordLengthft')
                         geometry_obj.mainwings.tip_chord = wing.TipChordLengthft;
                    end
                    if isfield(wing, 'AngleOfQuarterchordLinerad')
                         geometry_obj.mainwings.QC_sweep = rad2deg(wing.AngleOfQuarterchordLinerad)
                    end
               end

               % ---------- Horizontal tail ----------
               if isfield(design.geom.wings, 'HorizontalTail')
                    ht = design.geom.wings.HorizontalTail;

                    if isfield(ht, 'Spanft')
                         geometry_obj.HT.b = ht.Spanft;
                    end
                    if isfield(ht, 'RootChordLengthft')
                         geometry_obj.HT.c_root = ht.RootChordLengthft;
                    end
                    if isfield(ht, 'MeanGeometricChord')
                         geometry_obj.HT.MeanGeometricChord = ht.MeanGeometricChord;
                    end
                    if isfield(ht, 'SweepLEDeg')
                         geometry_obj.HT.LE_sweep = ht.SweepLEDeg;
                    end
                    if isfield(ht, 'AspectRatio')
                         geometry_obj.HT.AR = ht.AspectRatio;
                    end
                    if isfield(ht, 'xc')
                         geometry_obj.HT.xc = ht.xc;
                    end
                    if isfield(ht, 'tc')
                         geometry_obj.HT.tc = ht.tc;
                    end
                    if isfield(ht, 'ExposedHalfspan')
                         geometry_obj.HT.exposed_halfspan = ht.ExposedHalfspan;
                    end
                    if isfield(ht, 'ExposedRootChord')
                         geometry_obj.HT.exposed_rc = ht.ExposedRootChord;
                    end
                    if isfield(ht, 'TipChordLengthft')
                         geometry_obj.HT.tip_chord = ht.TipChordLengthft;
                    end
                    if isfield(ht, 'AngleOfQuarterchordLinerad')
                         geometry_obj.HT.QC_sweep = rad2deg(ht.AngleOfQuarterchordLinerad);
                    end
               end

               % ---------- Vertical tail ----------
               if isfield(design.geom.wings, 'VerticalTail')
                    vt = design.geom.wings.VerticalTail;

                    if isfield(vt, 'Spanft')
                         geometry_obj.VT.b = vt.Spanft;
                    end
                    if isfield(vt, 'RootChordLengthft')
                         geometry_obj.VT.c_root = vt.RootChordLengthft;
                    end
                    if isfield(vt, 'MeanGeometricChord')
                         geometry_obj.VT.MeanGeometricChord = vt.MeanGeometricChord;
                    end
                    if isfield(vt, 'SweepLEDeg')
                         geometry_obj.VT.LE_sweep = vt.SweepLEDeg;
                    end
                    if isfield(vt, 'AspectRatio')
                         geometry_obj.VT.AR = vt.AspectRatio;
                    end
                    if isfield(vt, 'xc')
                         geometry_obj.VT.xc = vt.xc;
                    end
                    if isfield(vt, 'tc')
                         geometry_obj.VT.tc = vt.tc;
                    end
                    if isfield(vt, 'ExposedHalfspan')
                         geometry_obj.VT.exposed_halfspan = vt.ExposedHalfspan;
                    end
                    if isfield(vt, 'ExposedRootChord')
                         geometry_obj.VT.exposed_rc = vt.ExposedRootChord;
                    end
                    if isfield(vt, 'TipChordLengthft')
                         geometry_obj.VT.tip_chord = vt.TipChordLengthft;
                    end
                    if isfield(vt, 'AngleOfQuarterchordLinerad')
                         geometry_obj.VT.QC_sweep = rad2deg(vt.AngleOfQuarterchordLinerad);
                    end
               end

               % ---------- Fuselage ----------
               if isfield(design.geom, 'fuselage') && isfield(design.geom.fuselage, 'Fuselage')
                    fus = design.geom.fuselage.Fuselage;

                    if isfield(fus, 'Lengthft')
                         geometry_obj.fuselage.L = fus.Lengthft;
                    end
                    if isfield(fus, 'MaxWidthft')
                         geometry_obj.fuselage.W_max = fus.MaxWidthft;
                    end
                    if isfield(fus, 'MaxHeightft')
                         geometry_obj.fuselage.h_max = fus.MaxHeightft;
                    end
               end

               % ---------- Design ----------
               if isfield(design.geom, 'fuselage') && isfield(design.geom.fuselage, 'Fuselage')
                    tot = design.geom.fuselage.Total;

                    if isfield(tot, 'Lengthft')
                         geometry_obj.design.total_length = tot.Lengthft;
                    end
                    if isfield(tot, 'MaxWidthft')
                         geometry_obj.design.W_max = tot.MaxWidthft;
                    end
               end

          end
     end
end
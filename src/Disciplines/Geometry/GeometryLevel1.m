classdef GeometryLevel1 < GeometryModelLevel1
     %GEOMETRYLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          mainwings
          HT
          VT
          fuselage
          design
     end

     methods
          function obj = GeometryLevel1(design)
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
                    obj.est_tail_propers(design.Type); % Incorporate this
               end

          end

          function L_fuselage = get_fus_len(geometry_obj, aircraft_type, W_TO)
               if aircraft_type == "Sailplane - unpowered"
                    a = 0.86;
                    C = 0.48;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Sailplane - powered"
                    a = 0.71;
                    C = 0.48;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Homebuilt - metal") || (aircraft_type == "Homebuilt - wood")
                    a = 3.68;
                    C = 0.23;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Homebuilt - composite"
                    a = 3.50;
                    C = 0.23;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "General aviation - single engine"
                    a = 4.37;
                    C = 0.23;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "General aviation - twin engine"
                    a = 0.86;
                    C = 0.42;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Agricultural aircraft"
                    a = 4.04;
                    C = 0.23;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Twin turboprop"
                    a = 0.37;
                    C = 0.51;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Flying boat"
                    a = 1.05;
                    C = 0.40;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Jet trainer"
                    a = 0.79;
                    C = 0.41;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "Jet fighter"
                    a = 0.93;
                    C = 0.39;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Military cargo") || (aircraft_type == "Military bomber")
                    a = 0.23;
                    C = 0.50;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Jet transport")
                    a = 0.67;
                    C = 0.43;
                    output = geometry_obj.compute_fus_len(a, C, W_TO);
               else
                    error("Unrecognized aircraft type.") % Include list of acceptable parameters
               end
               L_fuselage = output;
               geometry_obj.fuselage.L = L_fuselage;

          end

          % Estimate fuselage length based on historical trend
          function output = compute_fus_len(geometry_obj, a, C, W_TO)
               output = a*W_TO^(C); % Raymer, 6th ed, table 6.3
          end

          % Estimate tail properties based on historical trend of aircraft
          % types
          % This is probably better for stability and control
          function [c_HT, c_VT] = est_tail_propers(geometry_obj, aircraft_type)
               if aircraft_type == "Sailplane"
                    c_HT = 0.50;
                    c_VT = 0.02;
               elseif (aircraft_type == "Homebuilt")
                    c_HT = 0.50;
                    c_VT = 0.04;
               elseif aircraft_type == "General aviation - single engine"
                    c_HT = 0.70;
                    c_VT = 0.04;
               elseif aircraft_type == "General aviation - twin engine"
                    c_HT = 0.80;
                    c_VT = 0.07;
               elseif aircraft_type == "Agricultural"
                    c_HT = 0.50;
                    c_VT = 0.04;
               elseif aircraft_type == "Twin turboprop"
                    c_HT = 0.90;
                    c_VT = 0.08;
               elseif aircraft_type == "Flying boat"
                    c_HT = 0.70;
                    c_VT = 0.06;
               elseif aircraft_type == "Jet trainer"
                    c_HT = 0.70;
                    c_VT = 0.06;
               elseif aircraft_type == "Jet fighter"
                    c_HT = 0.40;
                    c_VT = 0.07; % 0.07 - 0.12, longer fuselage -> higher value
               elseif (aircraft_type == "Military cargo") || (aircraft_type == "Military bomber")
                    c_HT = 1.00;
                    c_VT = 0.08;
               elseif (aircraft_type == "Jet transport")
                    c_HT = 1.00;
                    c_VT = 0.09;
               else
                    error("Unrecognized aircraft type.") % Include list of acceptable parameters
               end

               geometry_obj.HT.c_root = c_HT;
               geometry_obj.VT.c_root = c_VT;

          end
     end

     methods (Access = private)

     end
end
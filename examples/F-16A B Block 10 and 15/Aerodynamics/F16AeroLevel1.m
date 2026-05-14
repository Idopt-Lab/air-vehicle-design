classdef F16AeroLevel1 < AerodynamicsModelLevel1
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     % Level 1 fidelity: estimation based on aircraft type. So, the user
     % tabulates the value, then enters that here (e.g., CD0, K, etc).
     % alternatively, I can have the user specify the aircraft type, then
     % pull values from a pre-configured table. That... might work.

     properties
          e_osw
          LD_max
          AR_wet
          K_LD
          K
     end

     methods

          % Constructor
          function obj = F16AeroLevel1(aircraft_type, geometry_obj, weight_obj)
               obj.e_osw = 0.914;
               AR = geometry_obj.mainwings.AR;
               obj.K = obj.get_K(AR, obj.e_osw);
               W_TO = weight_obj.W_TO_guess;
               S_wet = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
               obj.LD_max = obj.get_LDmax(aircraft_type, AR, S_wet, S_ref);
          end

          %% L/Dmax for the design
          % Estimate L/Dmax
          function LDmax = get_LDmax(aero_obj, aircraft_type, AR, S_wet, S_ref)
               % Determine K_LD
               K_LD = AeroLevel1.tab_K_LD(aircraft_type);
               AR_wetted = AeroLevel1.compute_AR_wetted(AR, S_wet, S_ref);
               LDmax = AeroLevel1.compute_LDmax(K_LD, AR_wetted);
               aero_obj.K_LD = K_LD;
               aero_obj.AR_wet = AR_wetted;
          end

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 1: Should be hard-coded or whatever. Independent of
               % design geometry.
               aero_obj.e_osw = e_osw;
          end

          % Get K value (gross estimate, tabulated)
          function K = get_K(aero_obj, AR, e_osw)
               % aero_obj.K1 = 1/(pi*AR*e_osw);
               K = AeroLevel1.compute_K(AR, e_osw);
          end

          % Compute CD0
          % User must have tabulated these values beforehand: CD0, CL
          function DragResults = get_design_drag(aero_obj, CD0, CL)

               aero_obj.CD0 = CD0;
               aero_obj.CL = CL;

               aero_obj.CD = aero_obj.CD0 + aero_obj.K*aero_obj.CL^2;
          end

          % Get design drag
          function DragResults = get_design_CD0(input)

          end

          % Get design CD
          function output = get_design_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               aero_obj.CD = CD0 + K*CL^2;
               output = aero_obj.CD;
          end

          %% FOR MISSION ANALYSIS
          % Compute L/D
          function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
               W_by_W_TO = W / W_TO;
               W_by_S = W_by_W_TO * W_S;
               LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          end

     end
end
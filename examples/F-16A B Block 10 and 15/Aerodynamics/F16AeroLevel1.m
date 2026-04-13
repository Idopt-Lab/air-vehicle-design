classdef F16AeroLevel1 < AerodynamicsModel
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
          CL_max
          CD0
          K
          K1 % Might need additional abstract classes for each fidelity level
          K2
     end

     methods

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 1: Should be hard-coded or whatever. Independent of
               % design geometry.
               aero_obj.e_osw = e_osw;
          end

          % Get K value (gross estimate, tabulated)
          function K = get_K(aero_obj, K)
               % aero_obj.K1 = 1/(pi*AR*e_osw);
               aero_obj.K = K;
          end

          function output = compute_LoverD_cruise(input1)
               output = input1;
          end

          function output = compute_LD_revised(input1)
               output = input1;
          end

          % Compute CD0
          % User must have tabulated these values beforehand: CD0, CL
          function DragResults = get_drag(aero_obj, CD0, CL)

               aero_obj.CD0 = CD0;
               aero_obj.CL = CL;

               aero_obj.CD = aero_obj.CD0 + aero_obj.K*aero_obj.CL^2;
          end

     end
end
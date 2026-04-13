classdef F16AeroLevel2 < AerodynamicsModel
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties
          e_osw
          CL_max
          CD0
          K1
          K2
     end

     methods

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
          function e_osw = compute_e_osw(aero_obj, e_osw)
               % Level 1: Should be hard-coded or whatever. Independent of
               % design geometry.
               aero_obj.e_osw = e_osw;
          end

          % Compute K
          function K1 = compute_K1(aero_obj, e_osw, AR)
               aero_obj.K1 = 1/(pi*AR*e_osw);
          end

          function output = compute_LoverD_cruise(input1)
               output = input1;
          end

          function output = compute_LD_revised(input1)
               output = input1;
          end

          % Compute CD0
          function CD = compute_drag(aero_obj, design, mission_obj, requirements_obj)

               Cf = 0.0035; % Skin friction coefficient. Take from table (... which should be loaded into design).
               CD0 = Cf * S_wet/S_ref;

               
          end

     end
end
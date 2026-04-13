classdef F16AeroLevel2 < AerodynamicsModel
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties
          e_osw
          Cf
          CL
          CL_max
          CD0
          CD
          K
          K1
          K2
     end

     methods

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 2: Actually compute this?
               aero_obj.e_osw = e_osw;
          end

          % Compute K
          function K = compute_K(aero_obj, e_osw, AR)
               aero_obj.K = 1/(pi*AR*e_osw);
          end

          function output = compute_LoverD_cruise(input1)
               output = input1;
          end

          function output = compute_LD_revised(input1)
               output = input1;
          end

          % Get Cf (should be tabulated by user or the program? Stick with
          % user, for now)
          function Cf = get_Cf(aero_obj, Cf)
               aero_obj.Cf = Cf;
          end

          % Get CD0
          function CD = get_drag(aero_obj, geometry_obj)

               aero_obj.CD0 = aero_obj.Cf * geometry_obj.S_wet/geometry_obj.S_ref;

               aero_obj.CD = aero_obj.CD0 + aero_obj.K*aero_obj.CL^2;
               
          end

     end
end
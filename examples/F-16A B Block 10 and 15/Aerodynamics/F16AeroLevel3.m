classdef F16AeroLevel3 < AerodynamicsModel
     %F16AEROLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 3 aerodynamics equations go here.
     % Should utilize textbook methods, like Raymer and Nicolai.
     % Should compute:
     %    - drag (CD, CD0 [sub & sup])
     %    - lift
     %    - Mach drag divergence
     %    - Sears-Haack stuff?

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
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Level 3: Actually compute this
               % Discern between straight and swept wings.
               if Lambda_LE > 30 % Can I add a section for function handles?
                    aero_obj.e_osw = 4.61*(1 - 0.045*AR^(0.68)) * cosd(Lambda_LE)^(0.15) - 3.1;
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    aero_obj.e_osw = 1.78*(1 - 0.045*AR^(0.68)) - 0.64;
               else
                    error("Error handler, get e_osw level 3.")
               end
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
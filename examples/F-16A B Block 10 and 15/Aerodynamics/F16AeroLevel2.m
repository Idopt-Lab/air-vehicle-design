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

          % Compute Oswald span efficiency factor
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 2: Actually compute this?
               aero_obj.e_osw = e_osw;
          end

          % Compute K
          function K = compute_K(aero_obj, e_osw, AR)
               aero_obj.K = 1/(pi*AR*e_osw);
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

          % Get CD0
          function DragResults = get_design_CD0(input)

          end

          %% FOR MISSION ANALYSIS
          % Compute L/D (using revised method) (I should probably store
          % mission segment results somewhere...)
          function [LD_ratio] = compute_revised_LD_ratio(W, q, S, CD0, e, AR)
               CL = 2*W/(q*S);
               K = 1/(pi*e*AR);
               LD_ratio = CL/(CD0 + K * CL^2);
          end

     end
end
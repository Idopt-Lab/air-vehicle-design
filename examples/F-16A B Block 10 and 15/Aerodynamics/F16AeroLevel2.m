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
          DragResults
     end

     methods

          % Compute Oswald span efficiency factor
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 2: Actually compute this?
               aero_obj.e_osw = e_osw;
          end

          % Compute K
          function K = compute_K(aero_obj, e_osw, AR)
               K = 1/(pi*AR*e_osw);
               aero_obj.K = K;
          end

          % Get Cf (should be tabulated by user or the program? Stick with
          % user, for now)
          function Cf = get_Cf(aero_obj, Cf)
               aero_obj.Cf = Cf;
          end

          % Get CD0
          function DragResults = get_design_drag(aero_obj, geometry_obj, state_input)
               W = state_input(4);

               % Get q
               q = AerodynamicsModel.compute_q(aero_obj, state_input);

               % Get CL
               aero_obj.CL = AerodynamicsModel.compute_CL(aero_obj, W, q, geometry_obj.mainwings.S_ref);

               % Get CD0
               DragResults.CD0 = get_design_CD0(aero_obj, aero_obj.Cf, geometry_obj.design.S_wet, geometry_obj.mainwings.S_ref);

               % Compute K
               aero_obj.compute_K(aero_obj.e_osw, geometry_obj.mainwings.AR);

               % Compute the CD
               DragResults.CD = get_design_CD(aero_obj, DragResults.CD0, aero_obj.K, aero_obj.CL);

               % Compute the drag
               DragResults.D = AerodynamicsModel.compute_D(aero_obj, q, DragResults.CD, geometry_obj.mainwings.S_ref);

          end

          % Get design CD
          function output = get_design_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               aero_obj.CD = CD0 + K*CL^2;
               output = aero_obj.CD;
          end

          % Get CD0
          function output = get_design_CD0(aero_obj, Cf, S_wet_aircraft, S_ref)
               aero_obj.CD0 = Cf * S_wet_aircraft/S_ref;
               output = aero_obj.CD0;
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

     methods (Access = private)
     end
end
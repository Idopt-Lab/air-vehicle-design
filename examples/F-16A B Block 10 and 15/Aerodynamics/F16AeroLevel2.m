classdef F16AeroLevel2 < AerodynamicsModelLevel2
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties
          e_osw
          Cf
          CL_max
          CD0
          K
     end

     methods

          % Constructor
          function obj = F16AeroLevel2(geometry_obj)
               AR = geometry_obj.mainwings.AR;

               obj.e_osw = obj.get_e_osw(0.914); % This is excessive
               obj.K = obj.get_K(obj.e_osw, AR);
               obj.Cf = obj.get_Cf(0.0035); % Again, EXTREMELY excessive
               obj.CL_max = 1.5;
          end

          % Compute Oswald span efficiency factor
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 2: Actually compute this?
               aero_obj.e_osw = e_osw;
          end

          % Compute K
          function K = get_K(aero_obj, e_osw, AR)
               K = AeroLevel2.compute_K(e_osw, AR);
          end

          % Get Cf (should be tabulated by user or the program? Stick with
          % user, for now)
          function Cf = get_Cf(aero_obj, Cf)
               Cf = Cf;
          end

          % Get design drag
          function DragResults = get_design_drag(aero_obj, geometry_obj, state_input)
               W = state_input(4);
               e_osw = aero_obj.e_osw;
               S_ref = geometry_obj.mainwings.S_ref;
               S_wet = geometry_obj.design.S_wet;
               AR = geometry_obj.mainwings.AR;

               % Get q
               q = AeroUtils.compute_q(state_input);

               % Get CL
               CL = AeroUtils.compute_CL(W, q, S_ref);

               % Get CD0
               CD0 = aero_obj.get_design_CD0(aero_obj.Cf, S_wet, S_ref);

               % Compute K
               % K = AeroLevel2.compute_K(e_osw, AR);

               % Compute the CD
               CD = aero_obj.get_design_CD(CD0, aero_obj.K, CL);

               % Compute the drag
               D = AeroUtils.compute_D(q, CD, S_ref);

               DragResults.CD0 = CD0;
               DragResults.CD = CD;
               DragResults.D = D;
          end

          % Get design CD
          function CD = get_design_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               % CD = CD0 + K*CL^2;
               CD = AeroLevel2.compute_CD(CD0, K, CL);
          end

          % Get CD0
          function CD0 = get_design_CD0(aero_obj, Cf, S_wet_aircraft, S_ref)
               % CD0 = Cf * S_wet_aircraft/S_ref;
               CD0 = AeroLevel2.compute_CD0(Cf, S_wet_aircraft, S_ref);
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
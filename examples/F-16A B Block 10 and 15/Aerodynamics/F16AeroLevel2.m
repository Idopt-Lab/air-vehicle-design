classdef F16AeroLevel2 < AerodynamicsModelLevel2
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties
          e_osw_clean
          e_osw_TO
          e_osw_Landing
          LD_max
          AR_wet
          K_LD
          K
          K1
          K2
          Cf
          CL_minD
          CL_max_clean
          CL_max_TO
          CL_max_Land
          Delta_CL_max_TO
          Delta_CL_max_Land
          Delta_CD0_TO
          Delta_CD0_Landing
          Delta_CD0_geardown
     end

     methods

          % Constructor
          function obj = F16AeroLevel2(geometry_obj)
               AR = geometry_obj.mainwings.AR;
               Lambda_LE = geometry_obj.mainwings.LE_sweep;
               obj.e_osw = obj.get_e_osw(AR, Lambda_LE); % This feels excessive
               obj.Cf = obj.get_Cf(0.0035); % Again, EXTREMELY excessive
               obj.CL_max = 1.5;
          end

          % Get Delta_CL_max values
          function Delta_CL_max = get_Delta_CL_max_values(CL_max_dirty, CL_max_clean, isTakeoffOrLanding)
               % CL_max_dirty = CL_max that isn't clean (e.g.,
               % CL_max_takeoff, CL_max_landing, etc)
               % Condition = "Landing" or "Takeoff"
               if (isTakeoffOrLanding == ["landing", "L"])
                    Delta_CL_max = AeroLevel2.Delta_CL_max_L(CL_max_dirty, CL_max_clean);
               elseif (isTakeOffOrLanding == ["takeoff", "TO"])
                    Delta_CL_max = AeroLevel2.Delta_CL_max_TO(CL_max_dirty, CL_max_clean);
               else
                    error("Error handler.")
               end
          end

          % Get CL_max values
          % Wrapper
          % Raymer: "CL_max will increase if the wing is low-AR, or if it
          % has sufficient sweep & a sharp LE."
          function CL_max = get_CL_max_values(aero_obj, cl_max, Lambda_qc_deg)
               CL_max = AeroLevel2.CL_max_clean(cl_max, Lambda_qc_deg);
          end




          % Get L/D max
          function LD_max = get_LD_max(aero_obj, AR, e_osw, CD0)
               LD_max = AeroLevel2.LD_max(AR, e_osw, CD0);
          end

          % Compute Oswald span efficiency factor (wrapper)
          % Account for biplanes? (Raymer, 6th edi, p 444)
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Level 3: Actually compute this
               % Discern between straight and swept wings.
               if Lambda_LE > 30 % Can I add a section for function handles?
                    e_osw = AeroLevel3.e_swept(AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    e_osw = AeroLevel3.e_straight(AR);
               else
                    error("Error handler, get e_osw level 2.")
               end
               aero_obj.e_osw = e_osw;
          end

          % Get K value (gross estimate)
          function [K1, K2] = get_K(aero_obj, AR, e_osw, M, LE_sweep_deg, CLminD)
               aero_obj.K = 1/(pi*AR*e_osw);
               K1 = aero_obj.compute_K1(M, AR, e_osw, LE_sweep_deg);
               K2 = aero_obj.compute_K2(M, K1, CLminD);
          end

          % Compute K1
          function K1 = compute_K1(aero_obj, M, AR, e_osw, LE_sweep_deg)
               if (0.0 < M) && (M < 1.0)
                    K1 = AeroUtils.compute_K1_sub(AR, e_osw);
               elseif (M >= 1.0)
                    K1 = AeroUtils.compute_K1_sup(AR, M, LE_sweep_deg);
               else
                    error("Error handler.")
               end
          end

          % Compute K2
          function K2 = compute_K2(aero_obj, M, K1, CLminD)
               if (0.0 < M) && (M < 1.0)
                    K2 = AeroUtils.compute_K2_sub(K1, CLminD);
               elseif (M >= 1.0)
                    K2 = AeroUtils.compute_K2_sup();
               else
                    error("Error handler.")
               end
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
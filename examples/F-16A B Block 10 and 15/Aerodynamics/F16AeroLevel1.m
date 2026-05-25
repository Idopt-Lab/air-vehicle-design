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
               AR = geometry_obj.mainwings.AR;
               Lambda_LE_deg = geometry_obj.mainwings.LE_sweep;
               obj.e_osw = obj.get_e_osw(AR, Lambda_LE_deg);
               obj.K = obj.get_K(AR, obj.e_osw);
               W_TO = weight_obj.W_TO_guess;
               b = geometry_obj.mainwings.b;
               S_wet = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
               obj.LD_max = obj.get_LDmax(aircraft_type, b, S_wet);
          end

          % Compute K1
          function K1 = compute_K1(aero_obj, M, AR, e_osw, LE_sweep_deg)
               if (0.0 < M < 1.0)
                    K1 = AeroUtils.compute_K1_sub(AR, e_osw);
               elseif (1.0 <= M)
                    K1 = AeroUtils.compute_K1_sup(AR, M, LE_sweep_deg);
               else
                    error("Error handler.")
               end
          end

          % Compute K2
          function K2 = compute_K2(aero_obj, M, K1, CLminD)
               if (0.0 < M <1.0)
                    K2 = AeroUtils.compute_K2_sub(K1, CLminD);
               elseif (1.0 <= M)
                    K2 = AeroUtils.compute_K2_sup();
               else
                    error("Error handler.")
               end
          end


          %% L/Dmax for the design
          % Estimate L/Dmax
          function LDmax = get_LDmax(aero_obj, aircraft_type, b, S_wet)
               % Determine K_LD
               K_LD = AeroLevel1.tab_K_LD(aircraft_type);
               AR_wetted = aero_obj.get_AR_wet(b, S_wet);
               LDmax = aero_obj.get_LD_max(K_LD, AR_wetted);
               aero_obj.K_LD = K_LD;
               aero_obj.AR_wet = AR_wetted;
          end

          % Compute Oswald span efficiency factor
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Discern between straight and swept wings.
               if Lambda_LE > 30 % Can I add a section for function handles?
                    e_osw = AeroUtils.e_swept(AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    e_osw = AeroUtils.e_straight(AR);
               else
                    error("Error handler, get e_osw level 1.")
               end
          end

          % Get K value (gross estimate, tabulated)
          function K = get_K(aero_obj, AR, e_osw)
               % aero_obj.K1 = 1/(pi*AR*e_osw);
               K = AeroLevel1.compute_K(AR, e_osw);
          end

          % Compute design drag
          function DragResults = get_design_drag(aero_obj, statevector, W, aircraft_type, n_engines, S_wet, S_ref)

               Cf = AeroLevel1.get_Cf(aircraft_type, n_engines);
               CD0 = AeroLevel1.compute_CD0(Cf, S_wet, S_ref);
               q = AeroUtils.compute_q(statevector);
               CL = AeroUtils.compute_CL(W, q, S_ref);
               CD = aero_obj.get_design_CD(CD0, aero_obj.K, CL);

               DragResults.CD0 = CD0;
               DragResults.CD = CD;
          end

          % Get design CD
          function CD = get_design_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K*CL^2;
          end

          % Compute AR wetted
          function AR_wetted = get_AR_wet(aero_obj, b, S_wet)
               AR_wetted = AeroLevel1.compute_AR_wetted(b, S_wet);
          end

          % Compute LD max
          function LD_max = get_LD_max(aero_obj, K_LD, AR_wetted)
               LD_max = AeroLevel1.compute_LDmax(K_LD, AR_wetted);
          end

          % %% FOR MISSION ANALYSIS
          % % Compute L/D
          % function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
          %      W_by_W_TO = W / W_TO;
          %      W_by_S = W_by_W_TO * W_S;
          %      LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          % end



     end
end
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
          e_osw_clean
          e_osw_TO
          e_osw_L
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
          CL_max_L
          % Delta_CL_max_TO
          % Delta_CL_max_L
          Delta_CD0_TO
          Delta_CD0_L
          Delta_CD0_geardown
     end

     methods

          % Constructor
          function obj = F16AeroLevel1(aircraft_type, geometry_obj, weight_obj)
               AR = geometry_obj.mainwings.AR;
               Lambda_LE_deg = geometry_obj.mainwings.LE_sweep;
               obj.e_osw_clean = obj.get_e_osw(AR, Lambda_LE_deg);
               % [obj.K1, obj.K2] = obj.get_K(AR, obj.e_osw, M, LE_sweep_deg, CLminD);
               W_TO = weight_obj.W_TO_guess;
               b = geometry_obj.mainwings.b;
               S_wet = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
               obj.LD_max = obj.get_LDmax(aircraft_type, b, S_wet);
               % obj@AerodynamicsModelLevel1()
          end

          % Get the skin friction coefficient
          function output = tab_Cf(aero_obj, aircraft_type, n_engines)
               output = aero_obj.get_Cf(aircraft_type, n_engines);
               % This calls AerodynamicsModelLevel1's function "get_Cf".
          end

          % Get Delta_CD0 and e_osw change for flap configs
          function [out1, out2] = get_Delta_CD0(aero_obj, configuration, rangeMode)
               out1 = aero_obj.tab_DeltaCD0(configuration, "Delta_CD0", rangeMode);
               out2 = aero_obj.tab_DeltaCD0(configuration, "e_osw", rangeMode);
          end

          % Get CL_minD
          function output = get_CL_minD(aero_obj, CL_alpha, alpha_L0_deg)
               output = aero_obj.comp_CL_minD(CL_alpha, alpha_L0_deg);
          end

          % Get CL_max for various conditions
          function output = get_CL_max_values(aero_obj, aircrafttype, condition, rangeMode)
               output = AeroLevel1.tab_CLmax_values(aircrafttype, condition, rangeMode);
          end

          % % Get Delta_CL_max_TO
          % function output = get_Delta_CL_max_TO(aero_obj, CL_max_TO, CL_max)
          %      output = aero_obj.comp_Delta_CL_max_TO(CL_max_TO, CL_max);
          % end
          % 
          % % Get Delta_CL_max_L
          % function output = get_Delta_CL_max_L(aero_obj, CL_max_L, CL_max)
          %      output = aero_obj.comp_Delta_CL_max_L(CL_max_L, CL_max);
          % end

          % Compute K1
          function K1 = compute_K1(aero_obj, M, AR, e_osw, LE_sweep_deg)
               if (0.0 < M) && (M < 1.0)
                    K1 = aero_obj.K1_sub(AR, e_osw);
               elseif (M >= 1.0)
                    K1 = aero_obj.K1_sup(AR, M, LE_sweep_deg);
               else
                    error("Error handler.")
               end
          end

          % Compute K2
          function K2 = compute_K2(aero_obj, M, K1, CLminD)
               if (0.0 < M) && (M < 1.0)
                    K2 = aero_obj.K2_sub(K1, CLminD);
               elseif (M >= 1.0)
                    K2 = aero_obj.K2_sup();
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
                    e_osw = aero_obj.e_swept(AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    e_osw = aero_obj.e_straight(AR);
               else
                    error("Error handler, get e_osw level 1.")
               end
          end

          % Get K values
          function [K1, K2] = get_K(aero_obj, AR, e_osw, M, LE_sweep_deg, CLminD)
               % aero_obj.K1 = 1/(pi*AR*e_osw);
               K1 = aero_obj.compute_K1(M, AR, e_osw, LE_sweep_deg);
               K2 = aero_obj.compute_K2(M, K1, CLminD);
          end

          % Get CD
          function CD = get_CD(aero_obj, CD0, K, CL)
               CD = aero_obj.CD_uncambered(K, CL);
               % Right now, we're not considering cambered wings. No detailed geometry.
          end

          % Get CD0
          function output = get_CD0(aero_obj, Cf, S_wet, S_ref)
               output = aero_obj.CD0(Cf, S_wet, S_ref);
          end

          % Get CDi
          function output = get_CDi(aero_obj, statevector, CL, e_osw, AR)
               M = statevector(1);
               h_alt = statevector(2);
               alpha_deg = statevector(3); % Angle of attack (deg)
               if (0.0 < M) && (M <1.0)
                    output = aero_obj.CDi_subsonic(CL, e_osw, AR);
               elseif (1.0 <= M)
                    output = aero_obj.CDi_supersonic(CL, alpha_deg);
               else
                    error("Error handler.")
               end
          end

          % Compute AR wetted
          function AR_wetted = get_AR_wet(aero_obj, b, S_wet)
               AR_wetted = aero_obj.compute_AR_wetted(b, S_wet);
          end

          % Compute LD max
          function LD_max = get_LD_max(aero_obj, K_LD, AR_wetted)
               LD_max = aero_obj.compute_LDmax(K_LD, AR_wetted);
          end

     end
end
classdef F16AeroLevel2 < AerodynamicsModelLevel2
     %F16AEROLEVEL2
     % This is an example that uses the given Aerodynamics discipline's
     % base toolset (method functions in AeroLevel2) to predict various
     % aerodynamic properties of the F-16A/B Block 10/15.
     % It uses an abstract class (AerodynamicsModelLevel2) to help ensure
     % that all minimum function requirements are met for sizing at level 2
     % fidelity.

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
          Delta_CL_max_TO
          Delta_CL_max_L
          Delta_cl_max_TO % Contribution from high-lift devices (take-off config)
          Delta_cl_max_L % Contribution from high-lift devices (landing config)
          Delta_CD0_TO
          Delta_CD0_Landing
          Delta_CD0_geardown
          Delta_CDi
     end

     properties (Constant) % These should be values that are tabulated based on geometry.
          hld_TE = "plain"; % High-lift device, trailing edge (type)
          hld_LE = "slat"; % High-lift device, leading edge (type)
          delta_hld_TE_TO = 20; % Deflection of high-lift device, trailing edge, take-off config (deg)
          delta_hld_TE_L = 60; % Deflection of high-lift device, trailing edge, landing config (deg)
          C1 = 0.5; % Tabulated from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 = 0.65; % Tabulatef from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_base = 0.91; % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg) = 2.76.
          sharpness_param = 0.7720; % Computed from Table 12.1 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          % Delta_CL_max % (Not using the one from Fig 12.14)
          CL_max_cl_max = 1.1; % Tabulated from Fig 12.9 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed), Lambda_LE_deg = 40.
          cl_max = 1.0; % Obtained from page 14 of https://ntrs.nasa.gov/api/citations/19870017427/downloads/19870017427.pdf
     end

     methods

          % Constructor
          function obj = F16AeroLevel2()
               % AR = geometry_obj.mainwings.AR;
               % Lambda_LE = geometry_obj.mainwings.LE_sweep;
               % obj.e_osw_clean = obj.get_e_osw(AR, Lambda_LE); % This feels excessive
               % obj.Cf = obj.get_Cf(0.0035); % Again, EXTREMELY excessive
               % obj.CL_max = 1.5;
          end

          % Get cl_max
          function cl_max = geT_cl_max()

          end

          % Get CDi
          function CDi = get_CDi(aero_obj, statevector, CL, e_osw, AR)
               M = statevector(1);
               alpha_deg = statevector(3);

               if (0.0 < M) && (M < 1.0)
                    CDi = AeroUtils.compute_CDi_subsonic(CL, e_osw, AR);
               elseif (1.0 <= M)
                    CDi = AeroUtils.compute_CDi_supersonic(CL, alpha_deg);
               else
                    error("Error handler.")
               end
          end


          % Get Delta_CDi
          function Delta_CDi = get_Delta_CDi(aero_obj, areFlapsFullOrHalfSpan, Delta_CL_flap, Lambda_cbar_q_deg)
               if (areFlapsFullOrHalfSpan == ["full"])
                    k_f = 0.14;
               elseif (areFlapsFullOrHalfSpan == ["half"])
                    k_f = 0.28;
               else
                    error("Error handler.")
               end

               Delta_CDi = AeroLevel2.Delta_CDi_flap(k_f, Delta_CL_flap, Lambda_cbar_q_deg);
          end 

          % Get Delta_CD0 from flaps
          function Delta_CD0 = get_Delta_CD0(aero_obj, flaptype, cf_c, S_flapped, S_ref, delta_flap_deg)
               % Check which value of F_flap we should use.
               if (flaptype == "plain")
                    F_flap = 0.0144;
               elseif (flaptype == "slotted")
                    F_flap=0.0074;
               else
                    F_flap=(0.0144+0.0074)/2; % Averaged
               end
               Delta_CD0 = AeroLevel2.Delta_CD0_flap(F_flap, cf_c, S_flapped, S_ref, delta_flap_deg);
          end

          % Get Delta_CD0 from landing gear
          function Delta_CD0_L = get_Delta_CD0_L(aero_obj)
               Delta_CD0_L = AeroLevel1.tab_DeltaCD0("geardown", "Delta_CD0", "mean");
          end

          % Get CL_minD
          function output = get_CL_minD(aero_obj, airfoil_type, CL_min, CD0)
               % First, check for which airfoil type
               % If uncambered, CD0 = CD_min, which is CL_minD = 0
               % If cambered, CL_minD = CL_min/CD_min, CD_min = CD where
               % CL_=0.
               if (airfoil_type == "uncambered")
                    output = CD0;
               elseif (airfoil_type == "cambered")
                    output = CL_min/CD0;
               else
                    error("Error handler.")
               end
          end

          % Get Delta_cl_max
          function Delta_cl_max = get_Delta_cl_max_values(aero_obj, liftdevice, config, cp_c)
               % liftdevice = Type of lift device ("plain", "split",
               % "slotted", "fowler", "double slotted", "triple slotted",
               % "fixed slat", "LE slat", "kruger slat", "slat")
               % config = "takeoff", "TO", or "landing", "L".
               % cp_c = c'/c (Total chord of wing + flap, over the wing's
               % chord length)

               % Index the lift device
               idx = AeroLevel2.Delta_cl_max_table.("High-Lift Device")==liftdevice;

               % Extract the Delta_cl_max
               Delta_cl_max = AeroLevel2.Delta_cl_max_table{idx, 2};

               % Apply modifiers if necessary
               if (ismember(liftdevice, ["fowler", "double slotted", "triple slotted", "slat"]))
                    Delta_cl_max = Delta_cl_max*cp_c;
               end

               % Apply take-off/landing modifiers
               % 60-80% of the tabulated value
               if ismember(config, ["takeoff", "TO"])
                    Delta_cl_max = Delta_cl_max*0.6; % Leaving the modifier here in case I want to change one, later.
               elseif ismember(config, ["landing", "L"])
                    Delta_cl_max = Delta_cl_max*0.8;
               end
          end

          % % Get Delta_CL_max values
          % function Delta_CL_max = get_Delta_CL_max_values(aero_obj, CL_max_dirty, CL_max_clean, isTakeoffOrLanding)
          %      % CL_max_dirty = CL_max that isn't clean (e.g.,
          %      % CL_max_takeoff, CL_max_landing, etc)
          %      % Condition = "Landing" or "Takeoff"
          %      if (isTakeoffOrLanding == ["landing", "L"])
          %           Delta_CL_max = AeroLevel2.Delta_CL_max_L(CL_max_dirty, CL_max_clean);
          %      elseif (isTakeOffOrLanding == ["takeoff", "TO"])
          %           Delta_CL_max = AeroLevel2.Delta_CL_max_TO(CL_max_dirty, CL_max_clean);
          %      else
          %           error("Error handler.")
          %      end
          % end


          % Get Delta_CL_max values
          function Delta_CL_max = get_Delta_CL_max_values(aero_obj, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
               % Lambda_HL_deg = Angle of the flap's hinge line (deg)
               Delta_CL_max = AeroLevel2.Delta_CL_max(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg);
          end

          % Get CL_max values
          % Wrapper
          % Raymer: "CL_max will increase if the wing is low-AR, or if it
          % has sufficient sweep & a sharp LE."
          function CL_max = get_CL_max_values(aero_obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
               % Check if high or low AR
               AR_check = AeroUtils.AR_check(AR, aero_obj.C1, Lambda_LE_deg);
               if (AR_check == "Low")
                    CL_max = AeroLevel2.CL_max_clean_LowAR(CL_max_base, Delta_CL_max);
               elseif (AR_check == "High")
                    CL_max = AeroLevel2.CL_max_clean_HighAR(cl_max, CL_max_cl_max, Delta_CL_max);
               end
          end




          % Get L/D max
          function LD_max = get_LD_max(aero_obj, AR, e_osw, CD0)
               LD_max = AeroLevel2.LD_max(AR, e_osw, CD0);
          end

          % Compute Oswald span efficiency factor (wrapper)
          % Account for biplanes? (Raymer, 6th edi, p 444)
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Discern between straight and swept wings.
               if Lambda_LE > 30 % Can I add a section for function handles?
                    e_osw = AeroLevel3.e_swept(AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    e_osw = AeroLevel3.e_straight(AR);
               else
                    error("Error handler, get e_osw level 2.")
               end
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

          % Get Cf
          function Cf = get_Cf(aero_obj, aircraft_type, n_engines)
               Cf = AeroLevel2.get_Cf(aircraft_type, n_engines);
               % N.b: using L1's function for now until I can find a
               % suitable L2 replacement.
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
               CD0 = aero_obj.get_CD0(aero_obj.Cf, S_wet, S_ref);

               % Compute K
               % K = AeroLevel2.compute_K(e_osw, AR);

               % Compute the CD
               CD = aero_obj.get_CD(CD0, aero_obj.K, CL);

               % Compute the drag
               D = AeroUtils.compute_D(q, CD, S_ref);

               DragResults.CD0 = CD0;
               DragResults.CD = CD;
               DragResults.D = D;
          end

          % Get design CD
          function CD = get_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               % CD = CD0 + K*CL^2;
               CD = AeroLevel2.compute_CD(CD0, K, CL);
          end

          % Get CD0
          function CD0 = get_CD0(aero_obj, Cf, S_wet_aircraft, S_ref)
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
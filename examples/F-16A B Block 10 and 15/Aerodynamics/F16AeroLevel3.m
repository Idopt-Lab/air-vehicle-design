classdef F16AeroLevel3 < AerodynamicsModelLevel3
     %F16AEROLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 3 aerodynamics equations go here.
     % Should utilize textbook methods, like Raymer and Nicolai.
     % Should compute:
     %    - drag (CD, CD0 [sub & sup])
     %    - lift
     %    - Mach drag divergence
     %    - Sears-Haack stuff? (Should probably leave that to Level IV)
     % USE STUFF FROM AERO LEVEL 4 YOU'VE ALREADY DONE THIS

     properties
          % Are these for the entire design, or for a specific component?
          % I could pick the "component" interpretation. That would be
          % specific enough to stop overthinking stuff.
          % Each "object" could be an individual part of the design.
          AR_wet
          CD0_LandP % Contributions to CD0 from leakages and protuberances
          CD0_misc % Contribution to CD0 resulting from miscellaneous objects
          CD0_wave
          CD0_body
          CD0_wing
          CD0_mainwings
          CD0_HT
          CD0_VT
          Cf
          cl_alpha
          CL_max_clean
          CL_max_L
          CL_max_TO
          CL_minD
          Delta_CD0_geardown

          Delta_CD0_L
          Delta_CD0_TO
          Delta_CDi
          Delta_CL_max_L
          Delta_cl_max_L % Contribution from high-lift devices (landing config)
          Delta_CL_max_TO
          Delta_cl_max_TO % Contribution from high-lift devices (take-off config)
          Dq_searshaack_val
          e_osw_clean
          e_osw_L
          e_osw_TO
          F % Fuselage interference factor
          FF
          K
          K1
          K2
          K_LD
          LD_max
          R_components
          R_cutoff
     end

     properties (Constant) % These should be values that are tabulated based on geometry.
          airfoiltype = "cambered"; % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
          alpha_L0 = -1.01 % Zero-lift AOA (deg)
          C1 = 0.5; % Tabulated from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 = 0.65; % Tabulatef from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CD0_gun = 0.02; % D/q, as a percent of total CD0
          CD0_hook = 0.10; % D/q, as a percent of total CD0
          cl_max = 1.0; % Obtained from page 14 of https://ntrs.nasa.gov/api/citations/19870017427/downloads/19870017427.pdf
          CL_max_base = 0.91; % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg) = 2.76.
          CL_max_cl_max = 1.1; % Tabulated from Fig 12.9 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed), Lambda_LE_deg = 40.
          % Delta_CL_max % (Not using the one from Fig 12.14)
          delta_hld_TE_L = 20; % Deflection of high-lift device, trailing edge, landing config (deg)
          delta_hld_TE_TO = 20; % Deflection of high-lift device, trailing edge, take-off config (deg)
          delta_hld_LE_TO = -2; % Deflection of high-lift device, leading edge, take-off configuration (deg)
          delta_hld_LE_L = 15; % Deflection of high-lift device, leading edge, landing approach configuration (deg)
          E_WD = 1.8; % Equivalent wave drag parameter
          hld_LE = "slat"; % High-lift device, leading edge (type)
          hld_TE = "plain"; % High-lift device, trailing edge (type)
          k = 2.08*10^(-5) % Skin roughness factor
          sharpness_param = 0.7720; % Computed from Table 12.1 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
     end


     % These are for the landing gear drag components
     % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th ed,
     % Table 12.6
     properties (Constant)
          Dq_wheels = 0.18; % Regular wheel and tire
          Dq_strut_highRE = 0.30; % Round strut
          Dq_strut_lowRE = 1.17; % Round strut
          Dq_hook_USAF = 0.15; % ft^2

          mainwheel_S_front = (25.5*8.0)/(12^2); % Frontal area of main wheels (in^2 -> ft^2)
          nosewheel_S_front = (18*5.5)/(12^2); % Frontal area of nosewheel (in^2 -> ft^2)
     end

     % Custom properties
     properties
          DragResults
          CD
          CDi
          CD0
          CD_wave
          CL_val
          D

          Delta_CD0_TO_flap
          Delta_CD0_TO_slat
          Delta_CD0_L_flap
          Delta_CD0_L_slat

          Delta_CL_max_TO_flap
          Delta_CL_max_TO_slat
          Delta_CL_max_L_flap
          Delta_CL_max_L_slat
     end

     methods


          % Get CL_alpha, accounting for strakes
          % Brandt
          function output = CL_alpha_strakes(CL_alpha_w, S_ref, S_strakes)
               output = CL_alpha_w * (S_ref + S_strakes)/S_ref;
          end

          % Get CD0_wave values
          function output = compute_CD0_wave(aero_obj, M, Lambda_LE_deg, A_max, l, S_ref)
               aero_obj.Dq_searshaack_val = aero_obj.Dq_searshaack(A_max, l);
               Dq_wave = aero_obj.Dq_wave(aero_obj.E_WD, M, Lambda_LE_deg, aero_obj.Dq_searshaack_val);
               % Dq_wave = aero_obj.Dq_searshaack(A_max, l);
               % Dq_wave = aero_obj.Dq_searshaack_val;
               output = Dq_wave/S_ref;
          end

          % Get CL_minD (using brandt's equation)
          function output = compute_CL_minD(aero_obj, CL_alpha, alpha_L0_deg)
               alpha_L0_rad = deg2rad(alpha_L0_deg);
               aero_obj.CL_minD = CL_alpha*(-1*alpha_L0_rad/2);
               output = aero_obj.CL_minD;
          end

          % Get component CD0 (subsonic) (wrapper)
          function output = compute_CD0_sub(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)

               M = statevector(1);
               % h_ft = statevector(2);

               % Get component drag values

               % Compute component "drag values" (the numerator in the CD0
               % equation)
               component_drag_value = aero_obj.get_component_drag_values_sub(design, statevector, geometry_obj);
               output = component_drag_value.total/S_ref; % Dividing by the S_ref gives the CD0
          end

          % Get design CD0 (supersonic) (wrapper)
          function output = compute_CD0_sup(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)
               M = statevector(1);
               % h_ft = statevector(2);

               % Get component drag values

               % Compute component "drag values" (the numerator in the CD0
               % equation)
               component_drag_value = aero_obj.get_component_drag_values_supersonic(design, statevector, geometry_obj);
               output = component_drag_value.total/S_ref; % Dividing by S_ref gives the CD0.
          end

          % Compute K1
          function K1 = compute_K1(aero_obj, M, AR, e_osw, LE_sweep_deg)
               % compute_K1@AerodynaamicsModelLevel1(
               if (0.0 < M) && (M < 1.0)
                    K1 = aero_obj.K1_sub(AR, e_osw);
               elseif (M >= 1.0)
                    K1 = aero_obj.K1_sup(AR, M, LE_sweep_deg);
               else
                    warning("M = 0 or something. Setting K1 = K = 1/(pi*e_osw*AR).")
                    K1 = 1/(pi*e_osw*AR);
                    % error("Error handler.")
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

          % Compute eta for mach number and 2-D lift-curve slope
          % Ramyer, 6th ed, eq 12.8
          function output = eta_mach(obj, cl_alpha, beta_mach)
               % output = cl_alpha/(2*pi/beta_mach);
               output = eta_mach@AerodynamicsModelLevel2(obj, cl_alpha, beta_mach);
          end

          % constructor
          function obj = F16AeroLevel3()
               % obj.k = 2.08*10^(-5); % Set skin roughness to "smooth paint"
               % AR = geometry_obj.mainwings.AR;
               % LE_sweep_deg = geometry_obj.mainwings.LE_sweep;
               % obj.alpha_L0_deg = design.geom.wings.Main.alphaL0;
               % obj.e_osw = get_e_osw(obj, AR, LE_sweep_deg);
          end

          % Get CD
          % I could probably move "get_CD0" and "get_CDi"
          % into here...
          function CD = get_CD(aero_obj, CD0, CDi, CL, CL_minD, airfoiltype, statevector, K1)
               if airfoiltype == "uncambered"
                    % Uncambered:
                    % CD = CD0 + CDi;
                    CD = aero_obj.compute_CD_uncambered(K1, CL);
               elseif airfoiltype == "cambered"
                    % Cambered:
                    M = statevector(1);
                    if M >= 1.0
                         % CD = CD0 + K1.*(CL - CL_minD).^2;
                         CD = aero_obj.compute_CD_cambered(CD0, K1, CL, CL_minD);
                    elseif M < 1.0
                         % CD = CD0 + K1.*(CL - CL_minD).^2;
                         CD = aero_obj.compute_CD_cambered(CD0, K1, CL, CL_minD);
                    else
                         error("Error handler, compute_design_CD, F16aero_obj.")
                    end
               else
                    error("Error handler, compute_design_CD, F16aero_obj.")
               end
               % aero_obj.CD = CD;
          end

          % Get design CD0 (wrapper)
          function CD0_components = get_CD0(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)
               M = statevector(1);
               h_ft = statevector(2);
               % Check if super/subsonic conditions:
               if M >= 1.2
                    % Supersonic (Q & FF = 1.0)
                    Q = 1.0;
                    FF = 1.0;
                    CD0_components = aero_obj.compute_CD0_sup(statevector, design, geometry_obj, S_ref, propulsion_obj);
               elseif (M < 1.0) && (0.0 <= M)
                    % Subsonic (Q & FF =/= 1.0)
                    CD0_components = aero_obj.compute_CD0_sub(statevector, design, geometry_obj, S_ref, propulsion_obj);
               else
                    error("Mach number must be > 0.")
               end
          end

          % Get CD0 for a given component (leakage and protuberance model)
          function component_CD0 = get_CD0_LandP(aero_obj, component_Dq, S_ref)
               component_CD0 = aero_obj.get_component_CD0_from_Dq(component_Dq, S_ref);
               % Recall that D/q * q = drag force
               % D/q divided by S_ref = CD0_component
          end

          % Get design CDi for some given state (wrapper)
          % I should differentiate usage between "get" and "compute."
          % "get" = "wrapper"
          % "compute" = "non-wrapper"
          function CDi_design = get_CDi(aero_obj, statevector, S_ref, e_osw, AR, L)
               M = statevector(1);
               q = AeroUtils.q(statevector);

               % Check if sup/subsonic:
               if M >=1.0
                    % Supersonic
                    alpha_deg = statevector(3);
                    CL = aero_obj.get_CL(L, q, S_ref);
                    CDi_design = aero_obj.CDi_supersonic(CL, alpha_deg);
               elseif M<1.0
                    % Subsonic
                    CL = aero_obj.CL(L, q, S_ref);
                    CDi_design = aero_obj.CDi_subsonic(CL, e_osw, AR);
               else
                    error("Error handler, get_CDi, aero_obj.")
               end
          end

          % Get Cf (should return turb and lam) (wrapper)
          function [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R, M)
               % Differentiate between TURBULENT and LAMINAR RE
               % Laminar:
               Cf_lam_result = aero_obj.Cf_lam(R);

               % Turbulent:
               Cf_turb_result = aero_obj.Cf_turb(R, M);
          end

          % Get CL
          function CL = get_CL(aero_obj, L, q, S_ref)
               CL = aero_obj.CL(L, q, S_ref);
          end

          % Get cl_alpha (2-D)
          function cl_alpha = get_cl_alpha(aero_obj, M)
               if (0.0 < M) && (M < 1.0)
                    cl_alpha = aero_obj.cl_alpha_2D_sub(M);
               elseif (1.0 <= M)
                    cl_alpha = aero_obj.cl_alpha_2D_sup(M);
               else
                    % error("Error handler.")
                    warning("M = 0; setting cl_alpha = 0.")
                    cl_alpha = 0;
               end
          end

          % % Get CL_alpha (wrapper) (using Raymer's methods) (CL per rad)
          % (divide result by 57.3 to get something close to Brandt's
          % CL_alpha values) (I THINK it's the "wing" one).
          % Get CL_alpha
          % Output: Radians
          function output = get_CL_alpha(aero_obj, M, cl_alpha, AR, S_exposed, S_ref, F, Lambda_max_t_deg)
               if (0.0 < M) && (M < 1.0)
                    beta_mach = sqrt(1 - M^2);
                    eta_mach = aero_obj.eta_mach(cl_alpha, beta_mach);
                    output = aero_obj.CL_alpha_wing_sub(AR, S_exposed, S_ref, F, Lambda_max_t_deg, beta_mach, eta_mach);
               elseif (1.0 <= M)
                    beta_mach = sqrt(M^2 - 1);
                    output = aero_obj.CL_alpha_wing_sup(beta_mach);
               else
                    % error("Error handler.")
                    warning("M = 0. Settting CL_alpha = 0.")
                    output = 0;
               end
          end

          % Get CL_max values
          % Wrapper
          % Raymer: "CL_max will increase if the wing is low-AR, or if it
          % has sufficient sweep & a sharp LE."
          function CL_max = get_CL_max_values(aero_obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
               % Check if high or low AR
               AR_check = AeroUtils.AR_check(AR, aero_obj.C1, Lambda_LE_deg);
               if (AR_check == "Low")
                    CL_max = aero_obj.CL_max_clean_LowAR(CL_max_base, Delta_CL_max);
               elseif (AR_check == "High")
                    CL_max = aero_obj.CL_max_clean_HighAR(cl_max, CL_max_cl_max, Delta_CL_max);
               end
          end

          % Get CL_minD
          function output = get_CL_minD(aero_obj, CL_alpha, alpha_L0)
               output = aero_obj.compute_CL_minD(CL_alpha, alpha_L0);
          end

          function Cf_turb_result = get_Cf_turb(aero_obj, Cf_turb_value, R, R_cutoff, M)
               if R_cutoff < R
                    Cf_turb_result = aero_obj.Cf_turb(R_cutoff, M);
               else
                    Cf_turb_result = Cf_turb_value;
               end
          end

          % Compute the dimensionless "component drag value" for the
          % user-specified component. Dq
          function [component_drag_value, Cf_component] = get_component_drag_val_subsonic(aero_obj, statevector, ref_length, Q_component, S_wet_component, component_type, component_specs)
               % Arguments:
               % aero_obj = aerodynamics object
               % statevector = [u; h] -> [Mach number, altitude (ft)] (ASL)
               % ref_length = reference length (ft)
               % Q_component = Interference factor (dimensionless, usually 1.0 - 1.2
               % S_wet_component = wetted area of component
               % S_ref_component = reference area of component

               % Ouptuts:
               % CD0 = Zero-lift drag coefficient for given component and
               % state vector
               M = statevector(1);
               h_ft = statevector(2);

               % Extract V and mu from altitude
               bingus = AeroUtils.get_V_and_mu(M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = aero_obj.R(ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = aero_obj.get_R_cutoff(ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = aero_obj.get_Cf(R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = aero_obj.get_Cf_turb(Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = aero_obj.computeavgcf(R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = aero_obj.get_FF(component_type, component_specs, M);

               % Compute the component drag
               component_drag_value = aero_obj.compute_component_drag(Cf_component, Q_component, S_wet_component, FF_component);

               % THIS ISN'T ACTUALLY THE CD0 THIS IS THE NUMERATOR FOR THE
               % CD0 EQUATION FOR THE ENTIRE DESIGN
               % Remember this is the NUMERATOR for the final calculation
          end

          % Compute dimensionless "component drag value" for supersonic
          % case
          function [component_drag_value, Cf_component] = get_component_drag_val_supersonic(aero_obj, statevector, ref_length, Q_component, S_wet_component)
               % Arguments:
               % aero_obj = aerodynamics object
               % statevector = [u; h] -> [Mach number, altitude (ft)] (ASL)
               % ref_length = reference length (ft)
               % Q_component = Interference factor (dimensionless, usually 1.0 - 1.2
               % S_wet_component = wetted area of component
               % S_ref_component = reference area of component

               % Ouptuts:
               % CD0 = Zero-lift drag coefficient for given component and
               % state vector
               M = statevector(1);
               h_ft = statevector(2);

               % Extract V and mu from altitude
               bingus = AeroUtils.get_V_and_mu(M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = aero_obj.R(ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = aero_obj.get_R_cutoff(ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = aero_obj.get_Cf_turb(Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = aero_obj.computeavgcf(R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = 1.0; % It's 1.0 because we're in supersonic flow.

               % Compute the component drag
               component_drag_value = aero_obj.compute_component_drag(Cf_component, Q_component, S_wet_component, FF_component);

               % Now compute the CD0
               % THIS ISN'T ACTUALLY THE CD0 THIS IS THE NUMERATOR FOR THE
               % CD0 EQUATION FOR THE ENTIRE DESIGN
               % Remember this is the NUMERATOR for the final calculation
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
               Delta_CD0 = aero_obj.Delta_CD0_flap(F_flap, cf_c, S_flapped, S_ref, delta_flap_deg);
          end

          % Get Delta_CD0 from landing gear
          % Rewrite this for L3
          function Delta_CD0_geardown = get_Delta_CD0_geardown(aero_obj, S_ref, Re, n_nosegear, n_maingear, n_legs)
               % n_nosegear and n_maingear should definitely be a constant
               % property somewhere. Probably weight.

               CD0_nosewheel = aero_obj.Dq_wheels/S_ref;
               CD0_mainwheels = aero_obj.Dq_wheels/S_ref;
               % CD0_strut_highRE = aero_obj.Dq_strut_highRE/S_ref;
               % CD0_strut_lowRE = aero_obj.DQ_strut_lowRE/S_ref;

               if (Re > 3.0*10^5)
                    CD0_strut = aero_obj.Dq_strut_highRE/S_ref;
               elseif (Re <= 3.0*10^5)
                    CD0_strut = aero_obj.Dq_strut_lowRE/S_ref;
               end



               Delta_CD0_geardown = CD0_nosewheel*n_nosegear + CD0_mainwheels*n_maingear + CD0_strut*n_legs;
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

               Delta_CDi = aero_obj.Delta_CDi_flap(k_f, Delta_CL_flap, Lambda_cbar_q_deg);
          end

          % Get Delta_CL_max values
          function Delta_CL_max = get_Delta_CL_max_values(aero_obj, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
               % Lambda_HL_deg = Angle of the flap's hinge line (deg)
               Delta_CL_max = aero_obj.Delta_CL_max(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg);
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
               idx = aero_obj.Delta_cl_max_table.("High-Lift Device")==liftdevice;

               % Extract the Delta_cl_max
               Delta_cl_max = aero_obj.Delta_cl_max_table{idx, 2};

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

          % Compute Mach drag divergence

          % Get drag results (mega wrapper) (for an entire design)
          % I think it'd be easier if I refactored this to compute drag for
          % specific components.
          % That could push the design-wide computation to a higher level,
          % leaving this area more room and more specificity. Good.
          function DragResults = get_drag(aero_obj, geometry_obj, design, propulsion_obj, W, state_input, airfoiltype)

               % Compute q
               q = AeroUtils.compute_q(state_input);

               % Compute design CD0 (done)
               DragResults.CD0_design = aero_obj.get_CD0(state_input, design, geometry_obj, geometry_obj.mainwings.S_ref, propulsion_obj);

               % Compute CDi (done)
               DragResults.CDi_design = aero_obj.get_CDi(state_input, geometry_obj.mainwings.S_ref, aero_obj.e_osw, geometry_obj.mainwings.AR, W);

               % Is this for the entire design, or one component? Confirm?
               % This is for one component, the main wings
               % Get CL_alpha
               aero_obj.CL_alpha = aero_obj.CL_alpha_Raymer(state_input, geometry_obj.mainwings.S_exposed, geometry_obj.mainwings.S_ref, geometry_obj.mainwings.QC_sweep, geometry_obj.mainwings.LE_sweep, geometry_obj.mainwings.AR, geometry_obj.fuselage.W_max, geometry_obj.mainwings.b);

               % Is this for the entire design, or one component? Confirm?
               % Compute CL_minD (done)
               DragResults.CL_minD = aero_obj.compute_CL_minD(aero_obj.CL_alpha, aero_obj.alpha_L0_deg);

               % Compute CD (done?) (double-check results later)
               aero_obj.K1 = aero_obj.K1(aero_obj.e_osw, geometry_obj.mainwings.AR, state_input(1), geometry_obj.mainwings.LE_sweep);
               DragResults.CD_design = get_CD(aero_obj, DragResults.CD0_design, DragResults.CDi_design, aero_obj.CL, DragResults.CL_minD, airfoiltype, state_input, aero_obj.K1);

               % Compute D for given state (done)
               % DragResults.D_design = compute_D(aero_obj, state_input, DragResults.CD_design, geometry_obj.S_ref); % lbf
               DragResults.D_design = AeroUtils.compute_D(q, DragResults.CD_design, geometry_obj.mainwings.S_ref);
          end

          % Compute Oswald span efficiency factor (wrapper)
          % Account for biplanes? (Raymer, 6th edi, p 444)
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Discern between straight and swept wings.
               if Lambda_LE > 30
                    e_osw = aero_obj.e_swept(AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    e_osw = aero_obj.e_straight(AR);
               else
                    error("Error handler, get e_osw level 3.")
               end
          end

          % Get fuselage lift factor
          function F = get_F(aero_obj, fuselage_diam, b)
               F = aero_obj.F_comp(fuselage_diam, b);
          end

          % Compute form factor (wrapper?)
          function FF = get_FF(aero_obj, component_type, component_specs, M)
               if (component_type == "wing") || (component_type == "tail") || (component_type == "strut") || (component_type == "pylon")
                    x_c = component_specs.xc;
                    t_c = component_specs.tc;
                    Lambda_m = component_specs.Lambda_m;
                    FF = aero_obj.FF_1(x_c, t_c, M, Lambda_m);
               elseif (component_type == "fuselage") || (component_type == "smooth canopy")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    f = aero_obj.f(l, A_max);
                    FF = aero_obj.FF_2(f);
               elseif (component_type == "nacelle") || (component_type == "smooth external store")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    FF = aero_obj.FF_3(l, A_max);
               elseif (component_type == "double wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = aero_obj.FF_doublewedge(d, l);
               elseif (component_type == "single wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = aero_obj.FF_singlewedge(d, l);
               else
                    error("Couldn't identify part. Use: wing, tail, strut, pylon, fuselage, smooth canopy, nacelle, smooth external store, double wedge, single wedge.")
               end
          end

          % Get K value (gross estimate)
          function [K1, K2] = get_K(aero_obj, AR, e_osw, M, LE_sweep_deg, CLminD)
               aero_obj.K = 1/(pi*AR*e_osw);
               K1 = aero_obj.compute_K1(M, AR, e_osw, LE_sweep_deg);
               K2 = aero_obj.compute_K2(M, K1, CLminD);
          end

          % Get L/D max
          function LD_max = get_LD_max(aero_obj, AR, e_osw, CD0)
               LD_max = aero_obj.LD_max(AR, e_osw, CD0);
          end

          % Get R_cutoff (differentiate between sub and supersonic)
          % (wrapper)
          function R_cutoff = get_R_cutoff(aero_obj, ref_length, M)
               if M > 1.0
                    R_cutoff = aero_obj.R_cutoff_sup(ref_length, M, aero_obj.k);
               elseif M <= 1.0
                    R_cutoff = aero_obj.R_cutoff_sub(ref_length, aero_obj.k);
               end
          end

          % Get CD0_LandP values
          function CD0_LandP = compute_CD0_LandP(aero_obj, S_ref)
               CD0_LandP.gun = aero_obj.get_CD0_LandP(aero_obj.CD0_gun, S_ref);
               CD0_LandP.hook = aero_obj.get_CD0_LandP(aero_obj.CD0_hook, S_ref);
               CD0_LandP.total = CD0_LandP.gun + CD0_LandP.hook;
          end

          %
          % % Get CD0_misc values
          function CD0_misc = compute_CD0_misc(aero_obj, design, propulsion_obj, S_ref)
               CD0_misc.windmillingjet = aero_obj.Dq_windmillingjet(pi*(propulsion_obj.enginestats.D/2)^2)/S_ref;
               % CD0_misc.upsweep = aero_obj.Dq_upsweep(0.01, pi*(design.geom.fuselage.Fuselage.MaxWidthft/2)^2)/S_ref;
               CD0_misc.upsweep = 0;
               CD0_misc.total = CD0_misc.windmillingjet + CD0_misc.upsweep;
          end

     end

     methods (Access = private)



          % Get component drag values (subsonic)
          function output = get_component_drag_values_sub(aero_obj, design, statevector, geometry_obj)
               % High-level outline:
               % Get CD0 of all components (probably use a loop or
               % something) (PICK UP HERE NEXT TIME)
               % Get component drag values for: fuselage, main wings, and
               % tail
               fuselage_specs.l = geometry_obj.design.total_length;
               fuselage_specs.d = geometry_obj.fuselage.W_max;
               fuselage_specs.A_max = pi*(fuselage_specs.d/2)^2;

               wings_specs.xc = geometry_obj.mainwings.xc;
               wings_specs.tc = geometry_obj.mainwings.tc;
               wings_specs.Lambda_m = geometry_obj.mainwings.QC_sweep; % Use Lambda_m instead of LE

               HT_specs.xc = geometry_obj.HT.xc;
               HT_specs.tc = geometry_obj.HT.tc;
               HT_specs.Lambda_m = geometry_obj.HT.QC_sweep; % Use Lambda_m instead of LE

               VT_specs.xc = geometry_obj.VT.xc;
               VT_specs.tc = geometry_obj.VT.tc;
               VT_specs.Lambda_m = geometry_obj.VT.QC_sweep; % Use Lambda_m instead of LE

               component_drag_value.fuselage = get_component_drag_val_subsonic(aero_obj, statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet, "fuselage", fuselage_specs);
               component_drag_value.mainwings = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet, "wing", wings_specs); % Produces a complex value.
               component_drag_value.HT = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.HorizontalTail.AverageChord, 1.05, geometry_obj.HT.S_wet, "tail", HT_specs);
               component_drag_value.VT = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.VerticalTail.AverageChord, 1.05, geometry_obj.VT.S_wet, "tail", VT_specs);

               % Get total component drag value
               component_drag_value.total = component_drag_value.fuselage + component_drag_value.mainwings + component_drag_value.HT + component_drag_value.VT;

               output = component_drag_value;
          end

          % Get component drag values (supersonic)
          function output = get_component_drag_values_supersonic(aero_obj, design, statevector, geometry_obj)
               % High-level outline:
               % Get CD0 of all components (probably use a loop or
               % something) (PICK UP HERE NEXT TIME)
               % Get component drag values for: fuselage, main wings, and
               % tail
               % Fuselage
               fuselage_specs.l = geometry_obj.design.total_length;
               fuselage_specs.d = geometry_obj.fuselage.W_max;
               fuselage_specs.A_max = pi*(fuselage_specs.d/2)^2;

               % Main wings
               wings_specs.xc = geometry_obj.mainwings.xc;
               wings_specs.tc = geometry_obj.mainwings.tc;
               wings_specs.Lambda_m = geometry_obj.mainwings.QC_sweep; % Use Lambda_m instead of LE

               % Horizontal tail
               HT_specs.xc = geometry_obj.HT.xc;
               HT_specs.tc = geometry_obj.HT.tc;
               HT_specs.Lambda_m = geometry_obj.HT.QC_sweep; % Use Lambda_m instead of LE

               % Vertical tail
               VT_specs.xc = geometry_obj.VT.xc;
               VT_specs.tc = geometry_obj.VT.tc;
               VT_specs.Lambda_m = geometry_obj.VT.QC_sweep; % Use Lambda_m instead of LE

               [component_drag_value.fuselage, Cf.fuselage] = aero_obj.get_component_drag_val_supersonic(statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet);
               [component_drag_value.mainwings, Cf.mainwings] = aero_obj.get_component_drag_val_supersonic(statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet);
               [component_drag_value.HT, Cf.HT] = aero_obj.get_component_drag_val_supersonic(statevector, geometry_obj.HT.MeanGeometricChord, 1.00, geometry_obj.HT.S_wet);
               [component_drag_value.VT, Cf.VT] = aero_obj.get_component_drag_val_supersonic(statevector, geometry_obj.VT.MeanGeometricChord, 1.00, geometry_obj.VT.S_wet);

               % Get total skin friction coefficient
               % aero_obj.0.0Cf = Cf.fuselage + Cf.mainwings + Cf.HT + Cf.VT;

               % Get total component drag value
               component_drag_value.total = component_drag_value.fuselage + component_drag_value.mainwings + component_drag_value.HT + component_drag_value.VT;

               output = component_drag_value;
          end


     end

end

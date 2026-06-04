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
          airfoiltype % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
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
          Delta_CD0_L
          Delta_CD0_geardown
          Delta_CDi
          F % Fuselage interference factor
          R_components
          R_cutoff
          FF
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
          alpha_L0 = -1.01 % Zero-lift AOA (deg)
          k = 2.08*10^(-5) % Skin roughness factor
     end

     methods
          % constructor
          function obj = F16AeroLevel3(geometry_obj, design)
               % obj.k = 2.08*10^(-5); % Set skin roughness to "smooth paint"
               AR = geometry_obj.mainwings.AR;
               LE_sweep_deg = geometry_obj.mainwings.LE_sweep;
               obj.alpha_L0_deg = design.geom.wings.Main.alphaL0;
               obj.e_osw = get_e_osw(obj, AR, LE_sweep_deg);
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
                    error("Error handler, get e_osw level 3.")
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

          % % Get CL_alpha (wrapper) (using Raymer's methods) (CL per rad)
          % (divide result by 57.3 to get something close to Brandt's
          % CL_alpha values) (I THINK it's the "wing" one).
          function CL_alpha = CL_alpha_Raymer(aero_obj, statevector, S_exposed, S_ref, Lambda_max_t_rad, Lambda_LE_deg, AR, fuselage_width, b, cl_alpha)
               M = statevector(1);
               Lambda_LE_rad = deg2rad(Lambda_LE_deg);
               if M>=(1/cos(Lambda_LE_rad))
                    % Supersonic (leading edge is purely in supersonic
                    % flow):
                    CL_alpha = AeroLevel3.CL_alpha_wing_sup(M);
               elseif M<(1/cos(Lambda_LE_rad))
                    % Subsonic:
                    aero_obj.F = AeroLevel3.F(fuselage_width, b);
                    beta = AeroLevel3.beta_mach(M);
                    % eta = AeroLevel3.eta_mach(cl_alpha, beta);
                    eta = 0.95; % Raymer: if it's unknown, we may assume 0.95.
                    CL_alpha = AeroLevel3.CL_alpha_wing_sub(AR, S_exposed, S_ref, aero_obj.F, Lambda_max_t_rad, beta, eta);
               else
                    error("Error handler, get_CL_alpha, AeroLevel3.")
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
               aero_obj.K1 = AeroLevel3.K1(aero_obj.e_osw, geometry_obj.mainwings.AR, state_input(1), geometry_obj.mainwings.LE_sweep);
               DragResults.CD_design = get_CD(aero_obj, DragResults.CD0_design, DragResults.CDi_design, aero_obj.CL, DragResults.CL_minD, airfoiltype, state_input, aero_obj.K1);

               % Compute D for given state (done)
               % DragResults.D_design = compute_D(aero_obj, state_input, DragResults.CD_design, geometry_obj.S_ref); % lbf
               DragResults.D_design = AeroUtils.compute_D(q, DragResults.CD_design, geometry_obj.mainwings.S_ref);
          end

          % Get CD
          % I could probably move "get_CD0" and "get_CDi"
          % into here...
          function CD = get_CD(aero_obj, CD0, CDi, CL, CL_minD, airfoiltype, statevector, K1)
               if airfoiltype == "uncambered"
                    % Uncambered:
                    CD = CD0 + CDi;
               elseif airfoiltype == "cambered"
                    % Cambered:
                    M = statevector(1);
                    if M >= 1.0
                         CD = CD0 + K1.supersonic*(CL - CL_minD)^2;
                    elseif M < 1.0
                         CD = CD0 + K1.subsonic*(CL - CL_minD)^2;
                    end
               else
                    error("Error handler, compute_design_CD, F16AeroLevel3.")
               end
               aero_obj.CD = CD;
          end

          % Get CL_minD (using brandt's equation)
          function output = compute_CL_minD(aero_obj, CL_alpha, alpha_L0_deg)
               alpha_L0_rad = deg2rad(alpha_L0_deg);
               aero_obj.CL_minD = CL_alpha*(-1*alpha_L0_rad/2);
               output = aero_obj.CL_minD;
          end

          % % Get CL_alpha (wrapper) (using Raymer's methods) (CL per rad)
          % (divide result by 57.3 to get something close to Brandt's
          % CL_alpha values) (I THINK it's the "wing" one).
          function CL_alpha = get_CL_alpha(aero_obj, statevector, S_exposed, S_ref, Lambda_max_t, Lambda_LE_deg, AR, fuselage_width, b)
               M = statevector(1);
               Lambda_LE_rad = deg2rad(Lambda_LE_deg);
               if M>=(1/cos(Lambda_LE_rad))
                    % Supersonic (leading edge is purely in supersonic
                    % flow)
                    beta = AeroLevel3.beta_mach(M);
                    CL_alpha = AeroLevel3.CL_alpha_wing_sup(beta);
               elseif M<(1/cos(Lambda_LE_rad))
                    % Subsonic:
                    beta = sqrt(1-M^2); % Raymer, 6th ed, eq 12.7
                    F = AeroLevel3.F(fuselage_width, b);
                    CL_alpha = AeroLevel3.CL_alpha_wing_sub(AR, S_exposed, S_ref, F, Lambda_max_t, beta, eta);
               else
                    error("Error handler, get_CL_alpha, AeroLevel3.")
               end
               aero_obj.CL_alpha = CL_alpha;
          end

          % Get design CDi for some given state (wrapper)
          % I should differentiate usage between "get" and "compute."
          % "get" = "wrapper"
          % "compute" = "non-wrapper"
          function CDi_design = get_CDi(aero_obj, statevector, S_ref, e_osw, AR, L)
               M = statevector(1);
               q = AeroUtils.compute_q(statevector);

               % Check if sup/subsonic:
               if M >=1.0
                    % Supersonic
                    alpha_deg = statevector(3);
                    CL = AeroUtils.compute_CL(L, q, S_ref);
                    CDi_design = AeroUtils.compute_CDi_supersonic(CL, alpha_deg);
               elseif M<1.0
                    % Subsonic
                    CL = AeroUtils.compute_CL(L, q, S_ref);
                    CDi_design = AeroUtils.compute_CDi_subsonic(CL, e_osw, AR);
               else
                    error("Error handler, get_CDi, AeroLevel3.")
               end
               aero_obj.CL = CL;
          end

          % Get Cf (should return turb and lam) (wrapper)
          function [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R, M)
               % Differentiate between TURBULENT and LAMINAR RE
               % Laminar:
               Cf_lam_result = AeroLevel3.Cf_lam(R);

               % Turbulent:
               Cf_turb_result = AeroLevel3.Cf_turb(R, M);
          end

          % Get R_cutoff (differentiate between sub and supersonic)
          % (wrapper)
          function R_cutoff = get_R_cutoff(aero_obj, ref_length, M)
               if M > 1.0
                    R_cutoff = AeroLevel3.R_cutoff_sup(ref_length, M, aero_obj.k);
               elseif M <= 1.0
                    R_cutoff = AeroLevel3.R_cutoff_sub(ref_length, aero_obj.k);
               end
          end

          % Compute form factor (wrapper?)
          function FF = get_FF(aero_obj, component_type, component_specs, M)
               if (component_type == "wing") || (component_type == "tail") || (component_type == "strut") || (component_type == "pylon")
                    x_c = component_specs.xc;
                    t_c = component_specs.tc;
                    Lambda_m = component_specs.Lambda_m;
                    FF = AeroLevel3.FF_1(x_c, t_c, M, Lambda_m);
               elseif (component_type == "fuselage") || (component_type == "smooth canopy")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    FF = AeroLevel3.FF_2(l, A_max);
               elseif (component_type == "nacelle") || (component_type == "smooth external store")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    FF = AeroLevel3.FF_3(l, A_max);
               elseif (component_type == "double wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = AeroLevel3.FF_doublewedge(d, l);
               elseif (component_type == "single wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = AeroLevel3.FF_singlewedge(d, l);
               else
                    error("Couldn't identify part. Use: wing, tail, strut, pylon, fuselage, smooth canopy, nacelle, smooth external store, double wedge, single wedge.")
               end
          end

          % Get design CD0 (wrapper)
          function CD0_design = get_CD0(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)
               M = statevector(1);
               h_ft = statevector(2);
               % Check if super/subsonic conditions:
               if M >= 1.2
                    % Supersonic (Q & FF = 1.0)
                    Q = 1.0;
                    FF = 1.0;
                    CD0_design = aero_obj.compute_design_CD0_sup(statevector, design, geometry_obj, S_ref, propulsion_obj);
               elseif (M < 1.0) && (0.0 <= M)
                    % Subsonic (Q & FF =/= 1.0)
                    CD0_design = aero_obj.compute_design_CD0_sub(statevector, design, geometry_obj, S_ref, propulsion_obj);
               else
                    error("Mach number must be > 0.")
               end
          end

          % Get design CD0 (supersonic) (wrapper)
          function output = compute_design_CD0_sup(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)
               M = statevector(1);
               % h_ft = statevector(2);

               % Get component drag values

               % Compute component "drag values" (the numerator in the CD0
               % equation)
               component_drag_value = aero_obj.get_component_drag_values_supersonic(design, statevector, geometry_obj);

               % Now for the miscellaneous components:
               % Get CD0_misc for each component
               CD0_misc = aero_obj.compute_CD0_misc(design, propulsion_obj, S_ref);

               % Leakages and protuberances:
               % Get CD0_LandP
               CD0_LandP = aero_obj.compute_CD0_LandP(S_ref);

               % Wave drag for entire design:
               CD0_wave = AeroLevel3.compute_CD0_wave(M, geometry_obj.mainwings.LE_sweep, pi*(geometry_obj.fuselage.W_max/2)^2, geometry_obj.fuselage.L, S_ref);

               % Supersonic CD0: eq 12.41, Raymer 6th edition.
               output = component_drag_value.total/S_ref + CD0_misc.total + CD0_LandP.total + CD0_wave;

          end

          % Get design CD0 (subsonic) (wrapper)
          function output = compute_design_CD0_sub(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)

               M = statevector(1);
               % h_ft = statevector(2);

               % Get component drag values

               % Compute component "drag values" (the numerator in the CD0
               % equation)
               component_drag_value = aero_obj.get_component_drag_values_sub(design, statevector, geometry_obj);

               % Now for the miscellaneous components:
               % Get CD0_misc for each component
               CD0_misc = aero_obj.compute_CD0_misc(design, propulsion_obj, S_ref);

               % Leakages and protuberances:
               % Get CD0_LandP
               CD0_LandP = compute_CD0_LandP(aero_obj, S_ref);

               % Subsonic CD0: eq 12.24, Raymer 6th edition
               output = component_drag_value.total/S_ref + CD0_misc.total + CD0_LandP.total;
          end

          % Compute the dimensionless "component drag value" for the
          % user-specified component.
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
               bingus = AeroLevel3.get_V_and_mu(M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = AeroLevel3.R(ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = aero_obj.get_R_cutoff(ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = aero_obj.get_Cf(R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = AeroLevel3.get_Cf_turb(Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = AeroLevel3.computeavgcf(R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = aero_obj.get_FF(component_type, component_specs, M);

               % Compute the component drag
               component_drag_value = AeroLevel3.compute_component_drag(Cf_component, Q_component, S_wet_component, FF_component);

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
               bingus = AeroLevel3.get_V_and_mu(M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = AeroLevel3.R(ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = aero_obj.get_R_cutoff(ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = AeroLevel3.get_Cf_turb(Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = AeroLevel3.computeavgcf(R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = 1.0;

               % Compute the component drag
               component_drag_value = AeroLevel3.compute_component_drag(Cf_component, Q_component, S_wet_component, FF_component);

               % Now compute the CD0
               % THIS ISN'T ACTUALLY THE CD0 THIS IS THE NUMERATOR FOR THE
               % CD0 EQUATION FOR THE ENTIRE DESIGN
               % Remember this is the NUMERATOR for the final calculation
          end

          % Get CD0 for a given component (leakage and protuberance model)
          function component_CD0 = get_CD0_LandP(aero_obj, component_Dq, S_ref)
               component_CD0 = AeroLevel3.get_component_CD0_from_Dq(component_Dq, S_ref);
               % Recall that D/q * q = drag force
               % D/q divided by S_ref = CD0_component
          end

     end

     methods (Access = private)


          % Get CD0_LandP values
          function CD0_LandP = compute_CD0_LandP(aero_obj, S_ref)
               CD0_LandP.gun = aero_obj.get_CD0_LandP(0.20, S_ref);
               CD0_LandP.hook = aero_obj.get_CD0_LandP(0.10, S_ref);
               CD0_LandP.total = CD0_LandP.gun + CD0_LandP.hook;
          end
          %
          % % Get CD0_misc values
          function CD0_misc = compute_CD0_misc(aero_obj, design, propulsion_obj, S_ref)
               CD0_misc.windmillingjet = AeroLevel3.Dq_windmillingjet(pi*(propulsion_obj.enginestats.D/2)^2)/S_ref;
               CD0_misc.upsweep = AeroLevel3.Dq_upsweep(0.01, pi*(design.geom.fuselage.Fuselage.MaxWidthft/2)^2)/S_ref;
               CD0_misc.total = CD0_misc.windmillingjet + CD0_misc.upsweep;
          end

          % Get component drag values (supersonic)
          function output = get_component_drag_values_supersonic(aero_obj, design, statevector, geometry_obj)
               % High-level outline:
               % Get CD0 of all components (probably use a loop or
               % something) (PICK UP HERE NEXT TIME)
               % Get component drag values for: fuselage, main wings, and
               % tail
               fuselage_specs.l = geometry_obj.fuselage.L;
               fuselage_specs.d = geometry_obj.fuselage.W_max;
               fuselage_specs.A_max = pi*(fuselage_specs.d/2)^2;

               wings_specs.xc = geometry_obj.mainwings.xc;
               wings_specs.tc = geometry_obj.mainwings.tc;
               wings_specs.Lambda_m = geometry_obj.mainwings.LE_sweep; % Use Lambda_m instead of LE

               HT_specs.xc = geometry_obj.HT.xc;
               HT_specs.tc = geometry_obj.HT.tc;
               HT_specs.Lambda_m = geometry_obj.HT.LE_sweep; % Use Lambda_m instead of LE

               VT_specs.xc = geometry_obj.VT.xc;
               VT_specs.tc = geometry_obj.VT.tc;
               VT_specs.Lambda_m = geometry_obj.VT.LE_sweep; % Use Lambda_m instead of LE

               [component_drag_value.fuselage, Cf.fuselage] = aero_obj.get_component_drag_val_supersonic(statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet);
               [component_drag_value.mainwings, Cf.mainwings] = aero_obj.get_component_drag_val_supersonic(statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet);
               [component_drag_value.HT, Cf.HT] = aero_obj.get_component_drag_val_supersonic(statevector, geometry_obj.HT.MeanGeometricChord, 1.00, geometry_obj.HT.S_wet);
               [component_drag_value.VT, Cf.VT] = aero_obj.get_component_drag_val_supersonic(statevector, geometry_obj.VT.MeanGeometricChord, 1.00, geometry_obj.VT.S_wet);

               % Get total skin friction coefficient
               aero_obj.Cf = Cf.fuselage + Cf.mainwings + Cf.HT + Cf.VT;

               % Get total component drag value
               component_drag_value.total = component_drag_value.fuselage + component_drag_value.mainwings + component_drag_value.HT + component_drag_value.VT;

               output = component_drag_value;
          end


          % Get component drag values (subsonic)
          function output = get_component_drag_values_sub(aero_obj, design, statevector, geometry_obj)
               % High-level outline:
               % Get CD0 of all components (probably use a loop or
               % something) (PICK UP HERE NEXT TIME)
               % Get component drag values for: fuselage, main wings, and
               % tail
               fuselage_specs.l = geometry_obj.fuselage.L;
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

     end

end
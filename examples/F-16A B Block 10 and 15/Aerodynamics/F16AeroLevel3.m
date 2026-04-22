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
          e_osw
          alpha_L0_deg
          Cf
          CL
          CL_alpha
          CL_max
          CL_minD
          CD0
          CD
          D
          K
          K1
          K2
          R_components
          R_cutoff
          k
          FF
          Q
          DragResults
     end

     methods
          % constructor
          function obj = F16AeroLevel3(geometry_obj, design)
               % Set to "smooth paint"
               obj.k = set_skin_roughness(obj, 2.08*10^(-5));
               obj.e_osw = get_e_osw(obj, geometry_obj.mainwings.AR, geometry_obj.mainwings.LE_sweep);
               obj.alpha_L0_deg = design.geom.wings.Main.alphaL0;
          end

          % Compute Oswald span efficiency factor (wrapper)
          % Account for biplanes? (Raymer, 6th edi, p 444)
          function e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
               % Level 3: Actually compute this
               % Discern between straight and swept wings.
               if Lambda_LE > 30 % Can I add a section for function handles?
                    aero_obj.e_osw = e_swept(aero_obj, AR, Lambda_LE);
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    aero_obj.e_osw = e_straight(aero_obj, AR);
               else
                    error("Error handler, get e_osw level 3.")
               end
               e_osw = aero_obj.e_osw;
          end

          % Compute Mach drag divergence

          % Get drag results (mega wrapper) (for an entire design)
          % I think it'd be easier if I refactored this to compute drag for
          % specific components.
          % That could push the design-wide computation to a higher level,
          % leaving this area more room and more specificity. Good.
          function DragResults = get_design_drag(aero_obj, geometry_obj, design, propulsion_obj, W, state_input, airfoiltype)

               % Compute q
               q = AerodynamicsModelLevel3.compute_q(aero_obj, state_input);

               % Compute design CD0 (done)
               DragResults.CD0_design = get_design_CD0(aero_obj, state_input, design, geometry_obj, geometry_obj.mainwings.S_ref, propulsion_obj);

               % Compute CDi (done)
               DragResults.CDi_design = get_design_CDi(aero_obj, state_input, geometry_obj.mainwings.S_ref, aero_obj.e_osw, geometry_obj.mainwings.AR, W);

               % Is this for the entire design, or one component? Confirm?
               % This is for one component, the main wings
               % Get CL_alpha
               aero_obj.CL_alpha = get_CL_alpha(aero_obj, state_input, geometry_obj.mainwings.S_exposed, geometry_obj.mainwings.S_ref, geometry_obj.mainwings.QC_sweep, geometry_obj.mainwings.LE_sweep, geometry_obj.mainwings.AR, geometry_obj.fuselage.W_max, geometry_obj.mainwings.b);

               % Is this for the entire design, or one component? Confirm?
               % Compute CL_minD (done)
               DragResults.CL_minD = compute_CL_minD(aero_obj, aero_obj.CL_alpha, aero_obj.alpha_L0_deg);

               % Compute CD (done?) (double-check results later)
               aero_obj.K1 = compute_K1(aero_obj, aero_obj.e_osw, geometry_obj.mainwings.AR, state_input(1), geometry_obj.mainwings.LE_sweep);
               DragResults.CD_design = get_design_CD(aero_obj, DragResults.CD0_design, DragResults.CDi_design, aero_obj.CL, DragResults.CL_minD, airfoiltype, state_input, aero_obj.K1);

               % Compute D for given state (done)
               % DragResults.D_design = compute_D(aero_obj, state_input, DragResults.CD_design, geometry_obj.S_ref); % lbf
               DragResults.D_design = AerodynamicsModelLevel3.compute_D(aero_obj, q, DragResults.CD_design, geometry_obj.mainwings.S_ref);
          end

          % Get design drag
          function output = compute_D(aero_obj, statevector, CD, S_ref)
               q = compute_q(aero_obj, statevector);
               aero_obj.D = CD*q*S_ref;
               output = aero_obj.D;
          end

          % Get CD
          % I could probably move "get_design_CD0" and "get_design_CDi"
          % into here...
          function output = get_design_CD(aero_obj, CD0, CDi, CL, CL_minD, airfoiltype, statevector, K1)
               if airfoiltype == "uncambered"
                    % Uncambered:
                    aero_obj.CD = CD0 + CDi;
               elseif airfoiltype == "cambered"
                    % Cambered:
                    M = statevector(1);
                    if M >= 1.0
                         aero_obj.CD = CD0 + K1.supersonic*(CL - CL_minD)^2;
                    elseif M < 1.0
                         aero_obj.CD = CD0 + K1.subsonic*(CL - CL_minD)^2;
                    end
               else
                    error("Error handler, compute_design_CD, F16AeroLevel3.")
               end
               output = aero_obj.CD;
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
          function output = get_CL_alpha(aero_obj, statevector, S_exposed, S_ref, Lambda_max_t, Lambda_LE_deg, AR, fuselage_width, b)
               M = statevector(1);
               Lambda_LE_rad = deg2rad(Lambda_LE_deg);
               if M>=(1/cos(Lambda_LE_rad))
                    % Supersonic (leading edge is purely in supersonic
                    % flow):
                    aero_obj.CL_alpha = compute_CL_alpha_supersonic(aero_obj, M);
               elseif M<(1/cos(Lambda_LE_rad))
                    % Subsonic:
                    aero_obj.CL_alpha = compute_CL_alpha_subsonic(aero_obj, S_exposed, S_ref, Lambda_max_t, M, AR, fuselage_width, b);
               else
                    error("Error handler, get_CL_alpha, F16AeroLevel3.")
               end
               output = aero_obj.CL_alpha;
          end

          % Compute CL_alpha, subsonic
          function output = compute_CL_alpha_subsonic(aero_obj, S_exposed, S_ref, Lambda_max_t, M, AR, d, b)
               beta = sqrt(1 - M^2);
               % If cl_alpha not given, assume eta = 0.95
               % eta = cl_alpha/(2*pi/beta);
               eta = 1.0;
               F = compute_F(aero_obj, d, b);
               output = (2*pi*AR)/(2 + sqrt(4 + ( ((AR^2 * beta^2)/eta^2)) * (1 + (tand(Lambda_max_t)^2/(beta^2)))))* (S_exposed/S_ref)*F;
          end

          % Compute fuselage lift factor
          function output = compute_F(aero_obj, d, b)
               output = 1.07*(1 + d/b);
          end

          % Compute CL_alpha, supersonic
          function output = compute_CL_alpha_supersonic(aero_obj, M)
               beta = sqrt(M^2 - 1);
               output = 4/beta;
          end

          % Get design CDi for some given state (wrapper)
          % I should differentiate usage between "get" and "compute."
          % "get" = "wrapper"
          % "compute" = "non-wrapper"
          function CDi_design = get_design_CDi(aero_obj, statevector, S_ref, e_osw, AR, L)
               M = statevector(1);
               q = AerodynamicsModelLevel3.compute_q(aero_obj, statevector);

               % Check if sup/subsonic:
               if M >=1.0
                    % Supersonic
                    alpha_deg = statevector(3);
                    aero_obj.CL = AerodynamicsModelLevel3.compute_CL(aero_obj, L, q, S_ref);
                    CDi_design = compute_CDi_supersonic(aero_obj, aero_obj.CL, alpha_deg);
               elseif M<1.0
                    % Subsonic
                    aero_obj.CL = AerodynamicsModelLevel3.compute_CL(aero_obj, L, q, S_ref);
                    CDi_design = compute_CDi_subsonic(aero_obj, aero_obj.CL, e_osw, AR);
               else
                    error("Error handler, get_design_CDi, F16AeroLevel3.")
               end
          end

          % Compute CDi (subsonic case)
          function output = compute_CDi_subsonic(aero_obj, CL, e_osw, AR)
               CDi = ( (CL^2) / (pi * e_osw * AR));
               output = CDi;
          end

          % Compute CDi (supersonic case)
          function output = compute_CDi_supersonic(aero_obj, CL, alpha_deg)
               CDi = CL*sind(alpha_deg);
               output = CDi;
          end

          % Get Cf (should return turb and lam) (wrapper)
          function [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R, M)
               % Differentiate between TURBULENT and LAMINAR RE
               % Laminar:
               Cf_lam_result = Cf_lam(aero_obj, R);

               % Turbulent:
               Cf_turb_result = Cf_turb(aero_obj, R, M);
          end

          % Get R_cutoff (differentiate between sub and supersonic)
          % (wrapper)
          function R_cutoff = get_R_cutoff(aero_obj, ref_length, M)
               if M > 1.0
                    R_cutoff = R_cutoff_sup(aero_obj, ref_length, M, aero_obj.k);
               elseif M <= 1.0
                    R_cutoff = R_cutoff_sub(aero_obj, ref_length, aero_obj.k);
               end
          end

          % Compute form factor (wrapper?)
          function FF = get_FF(aero_obj, component_type, component_specs, M)
               if (component_type == "wing") || (component_type == "tail") || (component_type == "strut") || (component_type == "pylon")
                    x_c = component_specs.xc;
                    t_c = component_specs.tc;
                    Lambda_m = component_specs.Lambda_m;
                    FF = FF_1(aero_obj, x_c, t_c, M, Lambda_m);
               elseif (component_type == "fuselage") || (component_type == "smooth canopy")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    FF = FF_2(aero_obj, l, d, A_max);
               elseif (component_type == "nacelle") || (component_type == "smooth external store")
                    l = component_specs.l;
                    d = component_specs.d;
                    A_max = component_specs.A_max;
                    FF = FF_3(aero_obj, l, d, A_max);
               elseif (component_type == "double wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = FF_doublewedge(d, l);
               elseif (component_type == "single wedge")
                    l = component_specs.l;
                    d = component_specs.d;
                    FF = FF_singlewedge(d, l);
               else
                    error("Couldn't identify part. Use: wing, tail, strut, pylon, fuselage, smooth canopy, nacelle, smooth external store, double wedge, single wedge.")
               end
          end

          % Get design CD0 (wrapper)
          function CD0_design = get_design_CD0(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj)
               M = statevector(1);
               h_ft = statevector(2);
               % Check if super/subsonic conditions:
               if M >= 1.2
                    % Supersonic (Q & FF = 1.0)
                    Q = 1.0;
                    FF = 1.0;
                    CD0_design = compute_design_CD0_sup(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj);
               elseif M < 1.0
                    % Subsonic (Q & FF =/= 1.0)
                    CD0_design = compute_design_CD0_sub(aero_obj, statevector, design, geometry_obj, S_ref, propulsion_obj);
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
               component_drag_value = get_component_drag_values_supersonic(aero_obj, design, statevector, geometry_obj);

               % Now for the miscellaneous components:
               % Get CD0_misc for each component
               CD0_misc = compute_CD0_misc(aero_obj, design, propulsion_obj, S_ref);

               % Leakages and protuberances:
               % Get CD0_LandP
               CD0_LandP = compute_CD0_LandP(aero_obj, S_ref);

               % Wave drag for entire design:
               CD0_wave = compute_CD0_wave(aero_obj, M, geometry_obj.mainwings.LE_sweep, pi*(geometry_obj.fuselage.W_max/2)^2, geometry_obj.fuselage.L, S_ref);

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
               component_drag_value = get_component_drag_values_sub(aero_obj, design, statevector, geometry_obj);

               % Now for the miscellaneous components:
               % Get CD0_misc for each component
               CD0_misc = compute_CD0_misc(aero_obj, design, propulsion_obj, S_ref);

               % Leakages and protuberances:
               % Get CD0_LandP
               CD0_LandP = compute_CD0_LandP(aero_obj, S_ref);

               % Subsonic CD0: eq 12.24, Raymer 6th edition
               output = component_drag_value.total/S_ref + CD0_misc.total + CD0_LandP.total;
          end

          % Compute the dimensionless "component drag value" for the
          % user-specified component.
          function output = get_component_drag_val_subsonic(aero_obj, statevector, ref_length, Q_component, S_wet_component, component_type, component_specs)
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
               bingus = get_V_and_mu(aero_obj, M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = R(aero_obj, ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = get_R_cutoff(aero_obj, ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = get_Cf_turb(aero_obj, Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = computeavgcf(aero_obj, R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = get_FF(aero_obj, component_type, component_specs, M);

               % Compute the component drag
               output = get_component_drag(aero_obj, Cf_component, Q_component, S_wet_component, FF_component);

               % THIS ISN'T ACTUALLY THE CD0 THIS IS THE NUMERATOR FOR THE
               % CD0 EQUATION FOR THE ENTIRE DESIGN
               % Remember this is the NUMERATOR for the final calculation
          end

          % Compute dimensionless "component drag value" for supersonic
          % case
          function output = get_component_drag_val_supersonic(aero_obj, statevector, ref_length, Q_component, S_wet_component)
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
               bingus = get_V_and_mu(aero_obj, M, h_ft);
               V = bingus(1);
               mu = bingus(2);
               rho = bingus(3);

               % Compute the component's reynolds number at the given state
               R_component = R(aero_obj, ref_length, rho, V, mu);

               % Get cutoff Reynolds number
               R_cutoff = get_R_cutoff(aero_obj, ref_length, M);

               % Next, compute the skin friction coefficient for each component
               [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R_component, M);

               % Determine which CF_turb to use
               Cf_turb_result = get_Cf_turb(aero_obj, Cf_turb_result, R_component, R_cutoff, M);

               % Get the average Cf
               Cf_avg = computeavgcf(aero_obj, R_component, R_cutoff, Cf_turb_result, Cf_lam_result);
               Cf_component = Cf_avg;

               % Get form factor
               FF_component = 1.0;

               % Compute the component drag
               output = get_component_drag(aero_obj, Cf_component, Q_component, S_wet_component, FF_component);

               % Now compute the CD0
               % THIS ISN'T ACTUALLY THE CD0 THIS IS THE NUMERATOR FOR THE
               % CD0 EQUATION FOR THE ENTIRE DESIGN
               % Remember this is the NUMERATOR for the final calculation
          end

          % Set skin roughness value
          function k = set_skin_roughness(aero_obj, k)
               aero_obj.k = k;
          end

          % Compute K1
          function output = compute_K1(aero_obj, e_osw, AR, M, Lambda_LE_degrees)
               % Lambda_LE must be in DEGREES!!!

               % Subsonic:
               K1.subsonic = 1/(pi*AR*e_osw); % eq 12.50

               % Supersonic:
               K1.supersonic = (AR*(M^2 - 1)*cosd(Lambda_LE_degrees))/(4*AR*sqrt(M^2 - 1) - 2);
               % eq 12.51

               aero_obj.K1 = K1;

               output = K1;
          end

          % Compute K2
          function K2 = compute_K2(aero_obj, K1, CL_minD)
               aero_obj.K2.subsonic = -2 * K1.subsonic * CL_minD; % Brandt, cell G17
               aero_obj.K2.supersonic = 0;
          end

          % Get component drag value (whatever that is, Raymer won't
          % specify it)
          function Component_Drag = get_component_drag(aero_obj, Cf, Q, S_wet, FF)
               Component_Drag = Cf*Q*S_wet*FF;
          end

          % Get CD0 for a given component (leakage and protuberance model)
          function component_CD0 = get_CD0_LandP(aero_obj, component_Dq, S_ref)
               component_CD0 = get_component_CD0_from_Dq(aero_obj, component_Dq, S_ref);
               % Recall that D/q * q = drag force
               % D/q divided by S_ref = CD0_component
          end

          function output = get_component_CD0_from_Dq(aero_obj, component_Dq, S_ref)
               output = component_Dq/S_ref;
          end

     end

     methods (Access = private)

          % Get CD0_wave values
          function output = compute_CD0_wave(aero_obj, M, Lambda_LE_deg, A_max, l, S_ref)
               Dq_wave_value = Dq_wave(aero_obj, 2.2, M, Lambda_LE_deg, A_max, l);
               CD0_wave = Dq_wave_value/S_ref;
               output = CD0_wave;
          end

          % Get CD0_LandP values
          function output = compute_CD0_LandP(aero_obj, S_ref)
               CD0_LandP.gun = get_CD0_LandP(aero_obj, 0.20, S_ref);
               CD0_LandP.hook = get_CD0_LandP(aero_obj, 0.10, S_ref);
               CD0_LandP.total = CD0_LandP.gun + CD0_LandP.hook;
               output = CD0_LandP;
          end

          % Get CD0_misc values
          function output = compute_CD0_misc(aero_obj, design, propulsion_obj, S_ref)
               CD0_misc.windmillingjet = Dq_windmillingjet(aero_obj, pi*(propulsion_obj.enginestats.D/2)^2)/S_ref;
               CD0_misc.upsweep = Dq_upsweep(aero_obj, 0.01, pi*(design.geom.fuselage.Fuselage.MaxWidthft/2)^2)/S_ref;
               CD0_misc.total = CD0_misc.windmillingjet + CD0_misc.upsweep;
               output = CD0_misc;
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

               component_drag_value.fuselage = get_component_drag_val_supersonic(aero_obj, statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet);
               component_drag_value.mainwings = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet);
               component_drag_value.HT = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.HorizontalTail.AverageChord, 1.00, geometry_obj.HT.S_wet);
               component_drag_value.VT = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.VerticalTail.AverageChord, 1.00, geometry_obj.VT.S_wet);

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

          % Determing which Cf_turb to use
          % If R_cuttoff < R, recompute Cf_turb using R_cutoff. Otherwise,
          % use Cf_turb calculated with R.
          function output = get_Cf_turb(aero_obj, Cf_turb_result, R, R_cutoff, M)
               if R_cutoff < R
                    output = Cf_turb(aero_obj, R_cutoff, M);
               else
                    output = Cf_turb_result;
               end
          end

          % Get velocity, mu, and rho, given Mach number and altitude
          function output = get_V_and_mu(aero_obj, M, h_ft)
               [T, a, ~, rho] = atmosisa(h_ft*0.3048);
               rho = rho*0.00194032033; % Convert from kg/m^3 to imperial
               a = a*3.2808399; % Convert from m/s -> ft/s
               V = a*M;
               T = T*1.8; % Convert Kelvin to Rankine
               mu = compute_dynamicviscosity(aero_obj, T);   % dynamic viscosity
               output = [V, mu, rho];
          end

          % Compute dynamic viscosity (mu) (should probably be in utilities...)
          function mu = compute_dynamicviscosity(aero_obj, T)
               % Using Sutherland's Formula
               T_0 = 518.7; % Rankine
               mu_0 = 3.62*10^(-7); % (lb*s)/(ft^2)
               mu = mu_0 * (T/T_0)^(1.5) * ((T_0 + 198.72)/(T + 198.72));
          end

          %% COMPONENT DRAG BUILDUP METHOD

          % Compute average Cf
          function avg_Cf = computeavgcf(aero_obj, R, R_cutoff, Cf_turb, Cf_lam)
               avg_Cf = ((abs(R - R_cutoff))/R_cutoff * Cf_turb + (abs(R - R_cutoff))/R_cutoff * Cf_lam)/2;
          end

          % Get form factor (component drag buildup)
          % Form factor
          % f
          function output = f(aero_obj, l, d, A_max)
               output = (l/(sqrt((4/pi)*A_max))); % Raymer, eq 12.33, 6th edition
          end

          % Flat-plat skin friction coefficient.
          % For wings, tails struts, pylons
          function output = FF_1(aero_obj, x_c, t_c, M, Lambda_m)
               output = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cosd(Lambda_m)^0.28);
               % Raymer, eq 12.30, 6th edition
          end

          % Flat-plate skin friction coefficient.
          % Fuselage, smooth canopy
          function output = FF_2(aero_obj, l, d, A_max)
               output = (0.9 + 5 / (aero_obj.f(l,d,A_max)^(1.5)) + aero_obj.f(l,d,A_max)/400);
          end
          % Raymer, eq 12.31, 6th edition

          % Flat-plate skin friction coefficient
          % Nacelle and smooth external store
          function output = FF_3(aero_obj, l, d, A_max)
               output = (1 + (0.35 / aero_obj.f(l,d,A_max)));
          end
          % Raymer, eq 12.32, 6th edition

          % Boundary layer diverters (double wedge, single wedge,
          % respectively)
          function output = FF_doublewedge(d,l)
               output = (1+(d/l)); % Raymer, eq 12.34, 6th edition
          end

          function output = FF_singlewedge(d,l)
               output = (1 + ((2*d)/l)); % Raymer, eq 12.35, 6th edition
          end

          function output = R_cutoff_sub(aero_obj, ref_length, k)
               output = (38.21*(ref_length/k)^(1.053)); % Raymer, eq 12.28, 6th edition. Use when R_cutoff < R_component
          end

          function output = R_cutoff_sup(aero_obj, ref_length, Mach, k)
               output = (44.62*(ref_length/k)^(1.053)*Mach^(1.16)); % Raymer, eq 12.29, 6th edition
          end

          function output = R(aero_obj, ref_length, rho, V, mu)
               output = (rho*V*ref_length/mu); % Raymer, eq 12.25, 6th edition
          end

          function output = Cf_lam(aero_obj, R)
               output = (1.328/(sqrt(R))); % eq 12.26, 6th ed
          end

          function output = Cf_turb(aero_obj, R, Mach)
               output = (0.455/(((log(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
               % eq 12.27, 6th ed
          end

          function output = Dq_upsweep(aero_obj, u, A_max) 
               output = (3.83*u^(2.5)*A_max); % eq 12.36
          end
          % What's upsweep?
          % I dunno, what about you? AAAYY

          function output = Dq_base_sub(aero_obj, M, A_base)
               output = ((0.139 + 0.419*(M - 0.161)^2)*A_base); % eq 12.37
          end

          function output = Dq_base_sup(aero_obj, M, A_base)
               output = ((0.064 + 0.042*(M - 3.84)^2)*A_base); % eq 12.38
          end

          function output = Dq_windmillingjet(aero_obj, A_engine_front_face)
               output = (0.3*A_engine_front_face); % eq 12.40
          end

          function output = Dq_searshaack(aero_obj, A_max, l)
               output = (9*pi/2 * (A_max/l)^2); % eq 12.44, 6thh ed
          end

          function output = Dq_wave(aero_obj, E_WD, M, Lambda_LE_deg, A_max, l)
               output = (E_WD*(1-0.2*(M-1.2)^(0.57)*(1 - (pi*(Lambda_LE_deg^0.77))/100))*(Dq_searshaack(aero_obj, A_max, l))); % eq 12.45, 6th ed
               % Using 0.2 instead of 0.386 due to Raymer's recommendation.
          end

          function output = e_straight(aero_obj, AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          function output = e_swept(aero_obj, AR, Lambda_LE_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cosd(Lambda_LE_deg)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end

     end

end
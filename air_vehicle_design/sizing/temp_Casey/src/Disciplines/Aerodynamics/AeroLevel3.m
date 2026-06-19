classdef AeroLevel3
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
          % airfoiltype % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
          % e_osw
          % alpha_L0_deg
          % Cf
          % CL
          % CL_alpha
          % CL_max
          % CL_minD
          % CD0
          % CD
          % D
          % K
          % K1
          % K2
          % R_components
          % R_cutoff
          % k
          % FF
          % Q
          % DragResults
     end

     methods (Static)

          % Compute CD for an uncambered wing
          % Raymer, 6th ed, eq 12.4
          function output = CD_uncambered(CD0, CDi)
               output = CD0 + CDi;
          end

          % Compute CD for a cambered wing
          % Raymer, 6th ed, eq 12.5
          function output = CD_cambered(CD_min, K, CL, CL_minD)
               output = CD_min + K*(CL-CL_minD)^2;
          end

          % Estimate theoretical lift-curve slope for 2-D airfoil
          % (subsonic)
          % Raymer, 6th ed, fig 12.6
          function output = CL_alpha_2D_sub(M)
               output = 2*pi/(sqrt(1-M^2));
          end

          % Estimate theoretical lift-curve slope for a supersonic 2-D
          % airfoil
          % Raymer, 6th ed, fig 12.6
          function output = CL_alpha_2D_sup(M)
               output = 4/(sqrt(M^2 - 1));
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (subsonic)
          % Raymer, 6th ed, eq 12.6
          function output = CL_alpha_wing_sub(AR, S_exposed, S_ref, F, Lambda_max_t_deg, beta, eta)
               % beta = sqrt(1 - M^2);
               % eta = cl_alpha/(2*pi/beta);

               output = (2*pi*AR)/((2 + sqrt(4 + ((AR^2 * beta^2)/(eta^2))*(1 + tand(Lambda_max_t_deg)^2/(beta^2)))))*(S_exposed/S_ref)*F;
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (supersonic)
          % Raymer, 6th ed, eq 12.12
          function output = CL_alpha_wing_sup(beta_mach)
               output = 4/beta_mach;
          end

          % Estimate CL_max (clean)
          % Raymer, 6th ed, eq 12.15
          function output = CL_max_clean(cl_max, Lambda_qc_deg)
               output = 0.9*cl_max*cosd(Lambda_qc_deg);
          end

          % Compute leading edge sharpness parameter (Delta-y)
          % Raymer, 6th ed, Table 12.1
          function output = leading_edge_sharpness_param(airfoiltype, tc)
               if (airfoiltype ~= "NACA")
                    error(fprintf("Only accepts NACA airfoils.\nSyntax: NACA n digit or NACA n series or Biconvex."))
               else
                    if (airfoiltype == "NACA 4 digit") || (airfoiltype == "NACA 5 digit")
                         output = 26*tc;
                    elseif (airfoiltype == "NACA 64 series")
                         output = 21.3*tc;
                    elseif (airfoiltype == "NACA 65 series")
                         output = 19.3*tc;
                    elseif (airfoiltype == "Biconvex")
                         output = 11.8*tc;
                    else
                         error(fprintf("Accepted airfoil types:\nNACA 4 digit\nNACA 5 digit\nNACA 64 series\nNACA 65 series\nBiconvex"))
                    end
               end
          end


          % % Check if design is "low AR"
          % % Raymer, 6th ed, eq 12.18
          % function output = AR_check(AR_in,C1, Lambda_LE_deg)
          %      AR_comparison = 3/((C1+1) * cosd(Lambda_LE_deg));
          %      if (AR_in <= AR_comparison)
          %           % Low AR
          %           output = "Low AR";
          %      else
          %           output = "High AR";
          %      end
          % end


          % Estimate CL_max_clean for high AR wings
          % Raymer, 6th ed, eq 12.16
          function output = CL_max_clean_highAR(cl_max, CL_max_cl_max, Delta_CL_max)
               % cl_max = airfoil's max lift coefficient at M =0 .2
               % CL_max_cl_max is tabulated from figure 12.9 in Raymer's
               % book
               output = cl_max*CL_max_cl_max + Delta_CL_max;
          end


          % AOA yielding CL_max for high AR wings
          % Raymer, 6th ed, eq 12.17
          function output = alpha_CL_max_highAR(CL_max, CL_alpha, alpha_L0, Delta_alpha_CL_max)
               % Delta_alpha_CL_max - obtained from Fig 12.11
               output = CL_max/CL_alpha + alpha_L0 + Delta_alpha_CL_max;
          end

          % Estimate CL_max_clean for low-AR wings
          % Raymer, 6th ed, eq 12.19
          function output = CL_max_clean_lowAR(CL_max_base, Delta_CL_max)
               % CL_max_base - obtained from Fig 12.13
               % Delta_CL_max - obtained from Fig 12.14
               output = CL_max_base + Delta_CL_max;
          end

          % Estimate AOA yielding CL_max for low-AR wings
          % Raymer, 6th ed, eq 12.20
          function output = alpha_CL_max_lowAR(alpha_CL_max_base, Delta_alpha_CL_max)
               % alpha_CL_max_base - obtained from Fig 12.15
               % Delta_alpha_CL_max - obtained from Fig 12.16
               output = alpha_CL_max_base + Delta_alpha_CL_max;
          end


          % HIGH LIFT DEVICES

          % Estimate Delta_CL_max with a flap deployed
          % Raymer, 6th ed, eq 12.21
          function output = Delta_CL_max_flapdown(liftdevicetype, liftdevicename, S_flapped, S_ref, Lambda_hingeline_deg, device_chordlength, wing_chordlength)
               c_c = device_chordlength/wing_chordlength; % denoted " c'/c " in Raymer's book.
               if (liftdevicetype == "flap") || (liftdevicetype == "flaps") || (liftdevicetype == "Flap") || (liftdevicetype == "Flaps")
                    if (liftdevicename == "plain") || (liftdevicename == "split")
                         output = 0.9;
                    elseif (liftdevicename == "slotted")
                         output = 1.3;
                    elseif (liftdevicename == "fowler")
                         output = 1.3*c_c;
                    elseif (liftdevicename == "double slotted")
                         output = 1.6*c_c;
                    elseif (liftdevicename == "triple slotted")
                         output = 1.9*c_c;
                    else
                         error("Accepted lift device names: plain, split, slotted, fowler, double slotted, triple slotted.")
                    end
               elseif (liftdevicetype == "leading-edge device") || (liftdevicetype == "slats")
                    if (liftdevicename == "fixed slot")
                         output = 0.2;
                    elseif (liftdevicename == "leading-edge flap")
                         output = 0.3;
                    elseif (liftdevicename == "kruger flap")
                         output = 0.3;
                    elseif (liftdevicename == "slat")
                         output = 0.4*c_c;
                    else
                         error("Accepted leading edge devices: fixed slot, leading-edge flap, kruger flap, slat.")
                    end
               else
                    error("Accepted lift device types: flaps, leading-edge device.")
               end
          end



          % Compute fuselage lift factor
          % Raymer, 6th ed, eq 12.9
          function output = F(d, b)
               output = 1.07*(1 + d/b);
          end

          % Compute CL_alpha, supersonic
          % Raymer, 6th ed, eq 12.12
          function output = compute_CL_alpha_supersonic(M)
               beta = sqrt(M^2 - 1);
               output = 4/beta;
          end


          % Get CL_minD (using brandt's equation)
          function output = CL_minD(CL_alpha, alpha_L0_deg)
               alpha_L0_rad = deg2rad(alpha_L0_deg);
               output = CL_alpha*(-1*alpha_L0_rad/2);
          end

          % Get CL_alpha for wing + body
          % Brandt
          function output = CL_alpha_wb(CL_alpha_HT, CL_alpha_strakes, delta_epsilon_delta_alpha, S_HT, S_ref)
               output = CL_alpha_strakes + CL_alpha_HT*(1-delta_epsilon_delta_alpha)*(S_HT/S_ref);
          end

          % Get CL_alpha, accounting for strakes
          % Brandt
          function output = CL_alpha_strakes(CL_alpha_w, S_ref, S_strakes)
               output = CL_alpha_w * (S_ref + S_strakes)/S_ref;
          end

          % Set skin roughness value
          % Why do I have this?
          function k = set_skin_roughness(k)
               k = k;
          end

          % Compute K1
          % Returns a struct:
          %    K1.subsonic
          %    K1.supersonic
          function output = K1(e_osw, AR, M, Lambda_LE_degrees)
               % Lambda_LE must be in DEGREES!!!

               % Subsonic:
               output.subsonic = 1/(pi*AR*e_osw); % eq 12.50

               % Supersonic:
               output.supersonic = (AR*(M^2 - 1)*cosd(Lambda_LE_degrees))/(4*AR*sqrt(M^2 - 1) - 2);
               % eq 12.51
          end

          % Compute K2
          function output = K2(K1, CL_minD)
               output.subsonic = -2 * K1.subsonic * CL_minD; % Brandt, cell G17
               output.supersonic = 0;
          end

          % Get component drag value (whatever that is, Raymer won't
          % specify it)
          function Component_Drag = compute_component_drag(Cf, Q, S_wet, FF)
               Component_Drag = Cf*Q*S_wet*FF;
          end

          % % Get CD0 for a given component (leakage and protuberance model)
          % function component_CD0 = get_CD0_LandP(aero_obj, component_Dq, S_ref)
          %      component_CD0 = get_component_CD0_from_Dq(aero_obj, component_Dq, S_ref);
          %      % Recall that D/q * q = drag force
          %      % D/q divided by S_ref = CD0_component
          % end

          function CD0_dq = get_component_CD0_from_Dq(component_Dq, S_ref)
               CD0_dq = component_Dq/S_ref;
          end



          % methods (Access = private)

          % Get CD0_wave values
          function output = compute_CD0_wave(M, Lambda_LE_deg, A_max, l, S_ref)
               Dq_wave_value = AeroLevel3.Dq_wave(2.2, M, Lambda_LE_deg, A_max, l);
               CD0_wave = Dq_wave_value/S_ref;
               output = CD0_wave;
          end

          % Get CD0_LandP values
          % function output = compute_CD0_LandP(S_ref) % These might be better as design-specific.
          %      CD0_LandP.gun = AeroLEvel3.get_CD0_LandP(0.20, S_ref);
          %      CD0_LandP.hook = AeroLevel3.get_CD0_LandP(0.10, S_ref);
          %      CD0_LandP.total = CD0_LandP.gun + CD0_LandP.hook;
          %      output = CD0_LandP;
          % end

          % Get CD0_misc values
          % These might be better as design-specific.
          % function CD0_misc = compute_CD0_misc(design, propulsion_obj, S_ref)
          %      CD0_misc.windmillingjet = AeroLevel3.Dq_windmillingjet(pi*(propulsion_obj.enginestats.D/2)^2)/S_ref;
          %      CD0_misc.upsweep = AeroLevel3.Dq_upsweep(0.01, pi*(design.geom.fuselage.Fuselage.MaxWidthft/2)^2)/S_ref;
          %      CD0_misc.total = CD0_misc.windmillingjet + CD0_misc.upsweep;
          % end

          % % Get component drag values (supersonic)
          % function output = get_component_drag_values_supersonic(aero_obj, design, statevector, geometry_obj)
          %      % High-level outline:
          %      % Get CD0 of all components (probably use a loop or
          %      % something) (PICK UP HERE NEXT TIME)
          %      % Get component drag values for: fuselage, main wings, and
          %      % tail
          %      fuselage_specs.l = geometry_obj.fuselage.L;
          %      fuselage_specs.d = geometry_obj.fuselage.W_max;
          %      fuselage_specs.A_max = pi*(fuselage_specs.d/2)^2;
          %
          %      wings_specs.xc = geometry_obj.mainwings.xc;
          %      wings_specs.tc = geometry_obj.mainwings.tc;
          %      wings_specs.Lambda_m = geometry_obj.mainwings.LE_sweep; % Use Lambda_m instead of LE
          %
          %      HT_specs.xc = geometry_obj.HT.xc;
          %      HT_specs.tc = geometry_obj.HT.tc;
          %      HT_specs.Lambda_m = geometry_obj.HT.LE_sweep; % Use Lambda_m instead of LE
          %
          %      VT_specs.xc = geometry_obj.VT.xc;
          %      VT_specs.tc = geometry_obj.VT.tc;
          %      VT_specs.Lambda_m = geometry_obj.VT.LE_sweep; % Use Lambda_m instead of LE
          %
          %      component_drag_value.fuselage = get_component_drag_val_supersonic(aero_obj, statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet);
          %      component_drag_value.mainwings = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet);
          %      component_drag_value.HT = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.HorizontalTail.AverageChord, 1.00, geometry_obj.HT.S_wet);
          %      component_drag_value.VT = get_component_drag_val_supersonic(aero_obj, statevector, design.geom.wings.VerticalTail.AverageChord, 1.00, geometry_obj.VT.S_wet);
          %
          %      % Get total component drag value
          %      component_drag_value.total = component_drag_value.fuselage + component_drag_value.mainwings + component_drag_value.HT + component_drag_value.VT;
          %
          %      output = component_drag_value;
          % end


          % Get component drag values (subsonic)
          % function output = get_component_drag_values_sub(aero_obj, design, statevector, geometry_obj)
          %      % High-level outline:
          %      % Get CD0 of all components (probably use a loop or
          %      % something) (PICK UP HERE NEXT TIME)
          %      % Get component drag values for: fuselage, main wings, and
          %      % tail
          %      fuselage_specs.l = geometry_obj.fuselage.L;
          %      fuselage_specs.d = geometry_obj.fuselage.W_max;
          %      fuselage_specs.A_max = pi*(fuselage_specs.d/2)^2;
          %
          %      wings_specs.xc = geometry_obj.mainwings.xc;
          %      wings_specs.tc = geometry_obj.mainwings.tc;
          %      wings_specs.Lambda_m = geometry_obj.mainwings.QC_sweep; % Use Lambda_m instead of LE
          %
          %      HT_specs.xc = geometry_obj.HT.xc;
          %      HT_specs.tc = geometry_obj.HT.tc;
          %      HT_specs.Lambda_m = geometry_obj.HT.QC_sweep; % Use Lambda_m instead of LE
          %
          %      VT_specs.xc = geometry_obj.VT.xc;
          %      VT_specs.tc = geometry_obj.VT.tc;
          %      VT_specs.Lambda_m = geometry_obj.VT.QC_sweep; % Use Lambda_m instead of LE
          %
          %      component_drag_value.fuselage = get_component_drag_val_subsonic(aero_obj, statevector, fuselage_specs.l, 1.00, geometry_obj.fuselage.S_wet, "fuselage", fuselage_specs);
          %      component_drag_value.mainwings = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.Main.AverageChord, 1.00, geometry_obj.mainwings.S_wet, "wing", wings_specs); % Produces a complex value.
          %      component_drag_value.HT = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.HorizontalTail.AverageChord, 1.05, geometry_obj.HT.S_wet, "tail", HT_specs);
          %      component_drag_value.VT = get_component_drag_val_subsonic(aero_obj, statevector, design.geom.wings.VerticalTail.AverageChord, 1.05, geometry_obj.VT.S_wet, "tail", VT_specs);
          %
          %      % Get total component drag value
          %      component_drag_value.total = component_drag_value.fuselage + component_drag_value.mainwings + component_drag_value.HT + component_drag_value.VT;
          %
          %      output = component_drag_value;
          % end

          % Determing which Cf_turb to use
          % If R_cuttoff < R, recompute Cf_turb using R_cutoff. Otherwise,
          % use Cf_turb calculated with R.
          function Cf_turb_result = get_Cf_turb(Cf_turb_value, R, R_cutoff, M)
               if R_cutoff < R
                    Cf_turb_result = AeroLevel3.Cf_turb(R_cutoff, M);
               else
                    Cf_turb_result = Cf_turb_value;
               end
          end

          % Get velocity, mu, and rho, given Mach number and altitude
          function output = get_V_and_mu(M, h_ft)
               [T, a, ~, rho] = atmosisa(h_ft*0.3048);
               rho = rho*0.00194032033; % Convert from kg/m^3 to imperial
               a = a*3.2808399; % Convert from m/s -> ft/s
               V = a*M;
               T = T*1.8; % Convert Kelvin to Rankine
               mu = AeroLevel3.mu(T);   % dynamic viscosity
               output = [V, mu, rho];
          end

          % Compute dynamic viscosity (mu) (should probably be in utilities...)
          function output = mu(T)
               % Using Sutherland's Formula
               T_0 = 518.7; % Rankine
               mu_0 = 3.62*10^(-7); % (lb*s)/(ft^2)
               output = mu_0 * (T/T_0)^(1.5) * ((T_0 + 198.72)/(T + 198.72));
          end

          %% COMPONENT DRAG BUILDUP METHOD

          % Compute average Cf
          function avg_Cf = computeavgcf(R, R_cutoff, Cf_turb, Cf_lam)
               % Get the percentage of flow that is turbulent
               f_turb = R/R_cutoff;
               % Get the percent of flow that's laminar
               f_lam = 1 - f_turb;
               % avg_Cf = ((abs(R - R_cutoff))/R_cutoff * Cf_turb + (abs(R - R_cutoff))/R_cutoff * Cf_lam)/2;
               avg_Cf = f_lam*Cf_lam + f_turb*Cf_turb;
          end

          % Get form factor (component drag buildup)
          % Form factor
          % f
          function output = f(l, A_max)
               output = (l/(sqrt((4/pi)*A_max))); % Raymer, eq 12.33, 6th edition
          end

          % Flat-plat skin friction coefficient.
          % For wings, tails struts, pylons
          function output = FF_1(x_c, t_c, M, Lambda_m)
               output = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cosd(Lambda_m)^0.28);
               % Raymer, eq 12.30, 6th edition
          end

          % Flat-plate skin friction coefficient.
          % Fuselage, smooth canopy
          function output = FF_2(l, A_max)
               output = (0.9 + 5 / (AeroLevel3.f(l,A_max)^(1.5)) + AeroLevel3.f(l,A_max)/400);
          end
          % Raymer, eq 12.31, 6th edition

          % Flat-plate skin friction coefficient
          % Nacelle and smooth external store
          function output = FF_3(l, A_max)
               output = (1 + (0.35 / AeroLevel3.f(l,A_max)));
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

          function output = R_cutoff_sub(ref_length, k)
               output = (38.21*(ref_length/k)^(1.053)); % Raymer, eq 12.28, 6th edition. Use when R_cutoff < R_component
          end

          function output = R_cutoff_sup(ref_length, Mach, k)
               output = (44.62*(ref_length/k)^(1.053)*Mach^(1.16)); % Raymer, eq 12.29, 6th edition
          end

          function output = R(ref_length, rho, V, mu)
               output = (rho*V*ref_length/mu); % Raymer, eq 12.25, 6th edition
          end

          function output = Cf_lam(R)
               output = (1.328/(sqrt(R))); % eq 12.26, 6th ed
          end

          function output = Cf_turb(R, Mach)
               output = (0.455/(((log10(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
               % eq 12.27, 6th ed
          end

          function output = Dq_upsweep(u, A_max)
               output = (3.83*u^(2.5)*A_max); % eq 12.36
          end
          % What's upsweep?
          % Not much, what about you? AAAYY

          function output = Dq_base_sub(M, A_base)
               output = ((0.139 + 0.419*(M - 0.161)^2)*A_base); % eq 12.37
          end

          function output = Dq_base_sup(M, A_base)
               output = ((0.064 + 0.042*(M - 3.84)^2)*A_base); % eq 12.38
          end

          function output = Dq_windmillingjet(A_engine_front_face)
               output = (0.3*A_engine_front_face); % eq 12.40
          end

          function output = Dq_searshaack(A_max, l)
               output = (9*pi/2 * (A_max/l)^2); % eq 12.44, 6thh ed
          end

          function output = Dq_wave(E_WD, M, Lambda_LE_deg, A_max, l)
               output = (E_WD*(1-0.2*(M-1.2)^(0.57)*(1 - (pi*(Lambda_LE_deg^0.77))/100))*(AeroLevel3.Dq_searshaack(A_max, l))); % eq 12.45, 6th ed
               % Using 0.2 instead of 0.386 due to Raymer's recommendation.
          end

          function output = e_straight(AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          function output = e_swept(AR, Lambda_LE_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cosd(Lambda_LE_deg)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end

          % end



          % Compute beta for mach number
          % Raymer, 6th ed, eq 12.7
          function output = beta_mach(M)
               output = sqrt(1-M^2);
          end

          % Compute eta for mach number and 2-D lift-curve slope
          % Ramyer, 6th ed, eq 12.8
          function output = eta_mach(cl_alpha, beta_mach)
               output = cl_alpha/(2*pi/beta_mach);
          end
     end

     % Helper methods
     methods (Access = private)

     end
end
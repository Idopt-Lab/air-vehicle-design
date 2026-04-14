classdef F16AeroLevel3 < AerodynamicsModel
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
          e_osw
          alpha_L0_deg
          Cf
          CL
          CL_max
          CD0
          CD
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

          % Set skin roughness value
          function k = set_skin_roughness(aero_obj, k)
               aero_obj.k = k;
          end

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
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

          % Compute K1
          function K1 = compute_K1(aero_obj, e_osw, AR, M, Lambda_LE_degrees)
               % Lambda_LE must be in DEGREES!!!

               % Subsonic:
               aero_obj.K1.subsonic = 1/(pi*AR*e_osw); % eq 12.50

               % Supersonic:
               aero_obj.K1.supersonic = (AR*(M^2 - 1)*cosd(Lambda_LE_degrees))/(4*AR*sqrt(M^2 - 1) - 2);
               % eq 12.51
          end

          % Compute K2
          function K2 = compute_K2(aero_obj)
               aero_obj.K2.subsonic = -2 * aero_obj.K1.subsonic * aero_obj.CL_minD; % Brandt, cell G17
               aero_obj.K2.supersonic = 0;
          end

          % Compute CL_minD
          % Can I automate the computation of alpha_L0?
          function CL_minD = compute_CL_minD(aero_obj, alpha_L0_deg)
               aero_obj.alpha_L0_deg = alpha_L0_deg;
               aero_obj.CL_minD = CL_alpha*(-1*aero_obj.alpha_L0_deg/2); % Brandt, cell G20
          end





          % Get Cf (should return turb and lam)
          function [Cf_lam_result, Cf_turb_result] = get_Cf(aero_obj, R, M)
               % Differentiate between TURBULENT and LAMINAR RE
               % Laminar:
               Cf_lam_result = Cf_lam(aero_obj, R);

               % Turbulent:
               Cf_turb_result = Cf_turb(aero_obj, R, M);
          end

          % Get R_cutoff (differentiate between sub and supersonic)
          function R_cutoff = get_R_cutoff(aero_obj, ref_length, M)
               if M > 0.87
                    R_cutoff = R_cutoff_sup(aero_obj, ref_length, Mach, aero_obj.k);
               elseif M <= 0.87
                    R_cutoff = R_cutoff_sub(aero_obj, ref_length, aero_obj.k);
               end
          end

          % Get component drag value (whatever that is, Raymer won't
          % specify it)
          function Component_Drag = get_component_drag(aero_obj, Cf, Q, S_wet)
               Component_Drag = Cf*Q*S_wet;
          end



          function CD0 = get_CD0(aero_obj, statevector, ref_length, Q_component, S_wet_component, S_ref_component)
               % Arguments:
               % aero_obj = aerodynamics object
               % statevector = [u; h] -> [Mach number, altitude (ft)]
               % (ASL)
               % ref_length = reference length (ft)
               % Q_component = Interference factor (dimensionless, usually
               % 1.0 - 1.2
               % S_wet_component = wetted area of component
               % S_ref_component = reference area of component

               % Ouptuts:
               % CD0 = Zero-lift drag coefficient for given component and
               % state vector

               M = statevector(1);
               h_ft = statevector(2);

               % Extract V and mu from altitude
               output = get_V_and_mu(aero_obj, M, h_ft);
               V = output(1);
               mu = output(2);
               rho = output(3);

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

               % Compute the component drag
               Component_Drag_val = get_component_drag(aero_obj, Cf_avg, Q_component, S_wet_component);

               % Hard-code some values (these aren't for level III)
               CD_misc = 0;
               CD_LandP = 0;

               CD0 = Component_Drag_val/S_ref_component + CD_misc + CD_LandP;
          end




          % Get drag results
          function DragResults = get_drag(aero_obj, geometry_obj, design, mission_obj, state_input)
               % This does nothing right now
          end

     end







     methods (Access = private)

          % Determing which Cf_turb to use
          % If R_cuttoff < R, recompute Cf_turb using R_cutoff. Otherwise,
          % use Cf_turb calculated with R.
          function Cf_turb_result = get_Cf_turb(aero_obj, Cf_turb_result, R, R_cutoff, M)
               if R_cutoff < R
                    Cf_turb_result = Cf_turb(aero_obj, R_cutoff, M);
               end
          end


          % Given Mach number and altitude (ft)
          function output = get_V_and_mu(aero_obj, M, h_ft)
               [T, a, ~, rho] = atmosisa(h_ft*0.3048);
               rho = rho*0.00194032033; % Convert from kg/m^3 to imperial
               a = a*0.3048; % Convert from m/s to ft/s
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
               output = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cos(Lambda_m)^0.28);
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
          function output = FF_3(l, d, A_max)
               output = (1 + (0.35 / obj.f(l,d,A_max)));
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

          function output = Dq_upsweep(aero_obj, u,A_max)
               output = (3.83*u^(2.5)*A_max); % eq 12.36
          end

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
               output = (E_WD*(1-0.386*(M-1.2)^(0.57)*(1 - (pi*Lambda_le_deg^0.77)/100))*(Dq_searshaack(A_max, l))); % eq 12.45, 6th ed
          end

          function output = e_straight(aero_obj, AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          function output = e_swept(aero_obj, AR, Lambda_le_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cos(Lambda_le_deg*pi/180)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end


     end


end
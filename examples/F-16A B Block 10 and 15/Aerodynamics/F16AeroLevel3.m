classdef F16AeroLevel3 < AerodynamicsModel
     %F16AEROLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 3 aerodynamics equations go here.
     % Should utilize textbook methods, like Raymer and Nicolai.
     % Should compute:
     %    - drag (CD, CD0 [sub & sup])
     %    - lift
     %    - Mach drag divergence
     %    - Sears-Haack stuff?
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
                    aero_obj.e_osw = 4.61*(1 - 0.045*AR^(0.68)) * cosd(Lambda_LE)^(0.15) - 3.1;
               elseif (0 <= Lambda_LE) && (Lambda_LE < 30)
                    aero_obj.e_osw = 1.78*(1 - 0.045*AR^(0.68)) - 0.64;
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

          % Compute


          % Get Cf (should be tabulated by user or the program? Stick with
          % user, for now)
          function Cf = get_Cf(aero_obj, Cf)
               aero_obj.Cf = Cf;
          end

          % Get drag results
          function DragResultsOrWhatever = get_drag(aero_obj, geometry_obj, design, mission_obj)
               % Atmosphere_data = atmosphere information for the instant
               % you're computing.
               % You can use this for mission segments or just a point
               % analysis.
               % Right now, it's just for the entire mission.

               % Using component drag buildup method
               % Get Reynolds numbers
               segments = mission_obj.missiondata.meta.outerLabels.fields;
               seg_count = length(mission_obj.missiondata.meta.outerLabels.fields);
               for i = 1:seg_count
                    segment = segments{i};

                    atmosphere_data.rho = mission_obj.missiondata.(segment).rhoslugft3;
                    atmosphere_data.h_ft = mission_obj.missiondata.(segment).Altitudeft;
                    M = mission_obj.missiondata.(segment).MachNumber;
                    atmosphere_data.mu = mission_obj.missiondata.(segment).muSlugsfts;
                    atmosphere_data.a = mission_obj.missiondata.(segment).afts;
                    atmosphere_data.V = atmosphere_data.a*M;

                    % Assemble structs containing component Reynolds
                    % numbers
                    aero_obj.R_components.(segment) = get_component_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment);
                    aero_obj.R_cutoff.(segment) = get_cutoff_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment, M);
               end

          end

     end







     methods (Access = private)

          % Given Mach number and altitude (ft)
          function output = compute_Reynolds_number_alt(aero_obj, ref_length, M, h_ft)
               [T, a, ~, rho] = atmosisa(h_ft*0.3048);
               rho = rho*0.00194032033; % Convert from kg/m^3 to imperial
               a = a*0.3048; % Convert from m/s to ft/s
               V = a*M;
               T = T*1.8; % Convert Kelvin to Rankine
               mu = compute_dynamicviscosity(T);   % dynamic viscosity
               output = rho*V*ref_length/mu;
          end

          % Compute dynamic viscosity (mu) (should probably be in utilities...)
          function mu = compute_dynamicviscosity(aero_obj, T)
               % Using Sutherland's Formula
               T_0 = 518.7; % Rankine
               mu_0 = 3.62*10^(-7); % (lb*s)/(ft^2)
               mu = mu_0 * (T/T_0)^(1.5) * ((T_0 + 198.72)/(T + 198.72));
          end



          %% COMPONENT DRAG BUILDUP METHOD


          % Get Reynolds number of each component
          function R_components = get_component_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment)
               % Update these to use the GEOMETRY object!
               % Loop through mission segments & design components!!!
               % I think I can use this "mission segment extractor" up one
               % layer higher.
               rho = atmosphere_data.rho;
               V = atmosphere_data.V;
               mu = atmosphere_data.mu;

               R_components.R_fuselage = R(aero_obj, design.geom.fuselage.Fuselage.Lengthft, rho, V, mu);
               R_components.R_mainwings = R(aero_obj, design.geom.wings.Main.AverageChord, rho, V, mu);
               R_components.R_HT = R(aero_obj, design.geom.wings.HorizontalTail.AverageChord, rho, V, mu);
               R_components.R_VT = R(aero_obj, design.geom.wings.VerticalTail.AverageChord, rho, V, mu);
          end


          % Get cutoff reynolds number for each component
          function R_cutoff = get_cutoff_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment, M)
               % Update these to use the GEOMETRY object!
               % Loop through mission segments & design components!!!

               if M<0.87
                    R_cutoff.R_cutoff_fuselage = R_cutoff_sub(aero_obj, design.geom.fuselage.Fuselage.Lengthft, aero_obj.k);
                    R_cutoff.R_cutoff_mainwings = R_cutoff_sub(aero_obj, design.geom.wings.Main.AverageChord, aero_obj.k);
                    R_cutoff.R_cutoff_HT = R_cutoff_sub(aero_obj, design.geom.wings.HorizontalTail.AverageChord, aero_obj.k);
                    R_cutoff.R_cutoff_VT = R_cutoff_sub(aero_obj, design.geom.wings.VerticalTail.AverageChord, aero_obj.k);
               else
                    R_cutoff.R_cutoff_fuselage = R_cutoff_sup(aero_obj, design.geom.fuselage.Fuselage.Lengthft, M, aero_obj.k);
                    R_cutoff.R_cutoff_mainwings = R_cutoff_sup(aero_obj, design.geom.wings.Main.AverageChord, M, aero_obj.k);
                    R_cutoff.R_cutoff_HT = R_cutoff_sup(aero_obj, design.geom.wings.HorizontalTail.AverageChord, M, aero_obj.k);
                    R_cutoff.R_cutoff_VT = R_cutoff_sup(aero_obj, design.geom.wings.VerticalTail.AverageChord, M, aero_obj.k);
               end
          end




          % Get form factor (component drag buildup)
                   % Form factor
          % f
          function output = f(l, d, A_max)
               output = (l/(sqrt((4/pi)*A_max))); % Raymer, eq 12.33, 6th edition
          end

          % Flat-plat skin friction coefficient.
          % For wings, tails struts, pylons
          function output = FF_1(x_c, t_c, M, Lambda_m)
               output = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cos(Lambda_m)^0.28);
               % Raymer, eq 12.30, 6th edition
          end

          % Flat-plate skin friction coefficient.
          % Fuselage, smooth canopy
          function output = FF_2(l, d, A_max)
               output = (0.9 + 5 / (obj.f(l,d,A_max)^(1.5)) + obj.f(l,d,A_max)/400);
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

          function output = Cf_lam(R)
               output = (1.328/(sqrt(R))); % eq 12.26, 6th ed
          end

          function output = Cf_turb(R, Mach)
               output = (0.455/(((log(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
               % eq 12.27, 6th ed
          end

          function output = Dq_upsweep(u,A_max)
               output = (3.83*u^(2.5)*A_max); % eq 12.36
          end

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
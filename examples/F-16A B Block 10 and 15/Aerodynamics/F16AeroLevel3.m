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
          function CD = get_drag(aero_obj, geometry_obj, design, mission_obj)
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

                    aero_obj.R_components.(segment) = get_component_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment);
                    aero_obj.R_cutoff.(segment) = get_cutoff_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment, M);
               end

          end



          % Get Reynolds number
          % Split: if user gives all atmospheric properties, use them.
          % Otherwise, use atmosisa
          function R = get_Reynolds_number(aero_obj, ref_length, rho, V, mu)


               R = compute_Reynolds_number(aero_obj, ref_length, rho, V, mu);
               % % Case 1: user supplied rho and mu directly
               % if ~isempty(rho) && ~isempty(mu)
               %      R = compute_Reynolds_number(aero_obj, ref_length, rho, V, mu);
               %      return
               % end
               %
               % % Case 2: user supplied altitude, so compute atmosphere
               % if ~isempty(h)
               %      R = compute_Reynolds_number_alt(aero_obj, ref_length, M, h_ft);
               %      return
               % end
               %
               % error(['Insufficient inputs. Provide either:' newline ...
               %      '  1) "rho" and "mu", or' newline ...
               %      '  2) "Altitude".']);
          end

     end







     methods (Access = private)

          %% COMPUTING REYNOLDS NUMBER
          % Given V, rho, dynamic viscosity (mu)
          function output = compute_Reynolds_number(aero_obj, ref_length, rho, V, mu)
               output = (rho*V*ref_length/mu);
          end

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

               R_components.R_fuselage = get_Reynolds_number(aero_obj, design.geom.fuselage.Fuselage.Lengthft, rho, V, mu);
               R_components.R_mainwings = get_Reynolds_number(aero_obj, design.geom.wings.Main.AverageChord, rho, V, mu);
               R_components.R_HT = get_Reynolds_number(aero_obj, design.geom.wings.HorizontalTail.AverageChord, rho, V, mu);
               R_components.R_VT = get_Reynolds_number(aero_obj, design.geom.wings.VerticalTail.AverageChord, rho, V, mu);
          end


          % Get cutoff reynolds number for each component
          function R_cutoff = get_cutoff_Reynolds_numbers(aero_obj, geometry_obj, design, atmosphere_data, segment, M)
               % Update these to use the GEOMETRY object!
               % Loop through mission segments & design components!!!

               if M<0.87
                    R_cutoff.R_cutoff_fuselage = get_R_cutoff_sub(aero_obj, design.geom.fuselage.Fuselage.Lengthft);
                    R_cutoff.R_cutoff_mainwings = get_R_cutoff_sub(aero_obj, design.geom.wings.Main.AverageChord);
                    R_cutoff.R_cutoff_HT = get_R_cutoff_sub(aero_obj, design.geom.wings.HorizontalTail.AverageChord);
                    R_cutoff.R_cutoff_VT = get_R_cutoff_sub(aero_obj, design.geom.wings.VerticalTail.AverageChord);
               else
                    R_cutoff.R_cutoff_fuselage = get_R_cutoff_sup(aero_obj, design.geom.fuselage.Fuselage.Lengthft, M);
                    R_cutoff.R_cutoff_mainwings = get_R_cutoff_sup(aero_obj, design.geom.wings.Main.AverageChord, M);
                    R_cutoff.R_cutoff_HT = get_R_cutoff_sup(aero_obj, design.geom.wings.HorizontalTail.AverageChord, M);
                    R_cutoff.R_cutoff_VT = get_R_cutoff_sup(aero_obj, design.geom.wings.VerticalTail.AverageChord, M);
               end
          end




          % Get form factor (component drag buildup)
          function ff = get_form_factor(aero_obj, l, A_max)
               ff = (l/(sqrt((4/pi)*A_max)));
          end

          %% Get flat-plate skin-friction coefficients
          % Components: wings, tails, struts, pylons
          function FF_1 = get_FF_1(aero_obj, x_c, t_c, M, Lambda_m)
               FF_1 = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cos(Lambda_m)^0.28); % Raymer, eq 12.30, 6th edition
          end

          % Components: Fuselage, smooth canopy
          function FF_2 = get_FF_2(aero_obj, l, d, A_max)
               FF_2 = (0.9 + 5/(f(l,d,A_max)^(1.5)) + f(l,d,A_max)/400); % Raymer, eq 12.31, 6th edition
          end

          % Components: Boundary layer diverters (double/single wedge,
          % respectively)
          function FF_doublewedge = get_FF_doublewedge(aero_obj, d, l)
               FF_doublewedge = (1 + (d/l)); % Raymer, eq 12.34, 6th edition
          end

          function FF_singlewedge = get_FF_singlewedge(aero_obj, d, l)
               FF_singlewedge = (1 + ((2*d)/l)); % Raymer, eq 12.35, 6th edition
          end

          %% ESTIMATE REYNOLDS NUMBER OF COMPONENT
          % Get cutoff reynolds number (subsonic)
          function R_cutoff_sub = get_R_cutoff_sub(aero_obj, ref_length)
               R_cutoff_sub =  (38.21*(ref_length/aero_obj.k)^(1.053)); % Raymer, eq 12.28, 6th edition. Use when R_cutoff < R_component
          end

          % Cutoff reynolds number (supersonic)
          function R_cutoff_sup = get_R_cutoff_sup(aero_obj, ref_length, Mach)
               R_cutoff_sup = (44.62*(ref_length/aero_obj.k)^(1.053)*Mach^(1.16)); % Raymer, eq 12.29, 6th edition
          end

          %% SKIN FRICTION COEFFICIENTS - COMPONENTS
          % Get Cf for:
          % LAMINAR REGIONS
          function Cf_lam = get_Cf_lam(aero_obj, R)
               Cf_lam = (1.328/(sqrt(R)));
          end

          % TURBULENT REGIONS
          function Cf_turb = get_Cf_turb(aero_obj, R, Mach)
               Cf_turb = (0.455/(((log(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
          end

          %% INTERFERENCE FACTORS
          % This will change per design.
          % User should provide a list or something.
          % User should provide a struct of interference factors labeled
          % using the method: Q_componentname
          % Q_fuselage, Q_BLDiverter, Q_tail, Q_misc, Q_wing
          function Q_factors = get_Q_factors(aero_obj, struct)
               Q_factors = struct;
          end


     end


end
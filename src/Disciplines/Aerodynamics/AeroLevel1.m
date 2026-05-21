classdef AeroLevel1
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
     end

     methods (Static)

          % Get K value (gross estimate, tabulated)
          function K = compute_K(AR, e_osw)
               K = 1/(pi*AR*e_osw);
          end

          % Get CD
          function CD = compute_CD(CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K*CL^2;
          end

          %% FOR MISSION ANALYSIS
          % Tabulate L/Dmax (cruise)
          function output = get_LDmax_cruise(LDmax, enginetype)
               if (enginetype == "jet")
                    LDmax_cruise = 0.866*LDmax;
               elseif (enginetype == "prop")
                    LDmax_cruise = LDmax;
               else
                    error("Error handler.")
               end
               output = LDmax_cruise;
          end

          % Tabulate L/Dmax (loiter)
          function output = get_LDmax_loiter(LDmax, enginetype)
               if (enginetype == "jet")
                    LDmax_loiter = LDmax;
               elseif (enginetype == "prop")
                    LDmax_loiter = 0.866*LDmax;
               else
                    error("Error handler.")
               end
               output = LDmax_loiter;
          end

          % Compute LD_max
          function LD_max = compute_LDmax(K_LD, AR_wetted)
               LD_max = K_LD*sqrt(AR_wetted); % Raymer, 6th ed, eq 3.12
          end

          % Compute AR wetted
          function AR_wetted = compute_AR_wetted(b, S_wet)
               AR_wetted = b^2/S_wet; % Raymer, 6th ed, eq 3.11
          end

          % Tabulate K_LD
          % Raymer, 6th ed, page 40
          function K_LD = tab_K_LD(design_type)
               if (design_type == "civil jet")
                    K_LD = 15.5;
               elseif (design_type == "military jet") || (design_type == "Jet fighter") || (design_type == "jet fighter")
                    K_LD = 14;
               elseif (design_type == "retractable prop")
                    K_LD = 11;
               elseif (design_type == "nonretractable prop")
                    K_LD = 9;
               elseif (design_type == "high-AR aircraft")
                    K_LD = 13;
               elseif (design_type == "sailplane")
                    K_LD = 15;
               else
                    error("Error handler.")
               end
          end

          % Equivalent aspect ratio
          % Raymer, table 4.1, 6th edition
          function equiv_AR = tabulate_equivAR(aircraft_type, engine_type, n_engines, LDbest, M_max)
               if ((aircraft_type == "sailplane") && (engine_type == "none")) || (aircraft_type == "sailplane")
                    equiv_AR = 0.19*(LDbest^(1.3));
               elseif (engine_type == "propeller") || (engine_type == "prop")
                    if (aircraft_type == "homebuilt")
                         equiv_AR = 6.0;
                    elseif (aircraft_type == "general aviation")
                         if (n_engines == 1)
                              equiv_AR = 7.6;
                         elseif (n_engines == 2)
                              equiv_AR = 7.8;
                         else
                              warning("Table lacks entry for engine count. Setting equiv_AR to 7.8.")
                              equiv_AR = 7.8;
                         end
                    elseif (aircraft_type == "agricultural")
                         equiv_AR = 7.5;
                    elseif (aircraft_type == "turboprop")
                         if (n_engines == 2)
                              equiv_AR = 9.2;
                         else
                              warning("No entry for engine count. Setting equiv_AR = 9.2.")
                              equiv_AR = 9.2;
                         end
                    else
                         error(sprintf("Couldn't determine aircraft type.\nAccepted types for engine class 'propeller'/'prop': \n   * homebuilt \n   * general aviation \n   * agricultural \n   * turboprop"))
                    end
               elseif (engine_type == "jet")
                    if (aircraft_type == "trainer")
                         a = 4.737;
                         c = -0.979;
                    elseif (aircraft_type == "fighter") || (aircraft_type == "dogfighter")
                         a = 5.416;
                         c = -0.622;
                    elseif (aircraft_type == "fighter") && (aircraft_type ~= "dogfighter") % e.g., interceptors, fighter-bombers, etc.
                         a = 4.110;
                         c = -0.622;
                    elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber") || (aircraft_type == "cargo") || (aircraft_type == "bomber")
                         a = 5.570;
                         c = -1.075;
                    elseif (aircraft_type == "transport")
                         a = 8.75;
                         c = 0;
                    else
                         error(sprintf("Couldn't determine aircraft type.\nAccepted types for engine class 'jet': \n   * trainer\n   * fighter/dogfighter/other\n   * military cargo/bomber\n   * transport"))
                    end
                    % Compute equivalent AR
                    equiv_AR = AeroLevel1.compute_equiv_AR_jet(a, c, M_max);
               else
                    error(sprintf("Couldn't determine engine type.\nAccepted types:\n   * propeller\n   * jet\n   * none"))
               end
          end

          % Compute equivalent AR for jet
          function equiv_AR = compute_equiv_AR_jet(a, c, M_max)
               equiv_AR = a*M_max^c;
          end

     end
end
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
               elseif (design_type == "military jet") || (design_type == "Jet fighter")
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
          
     end
end
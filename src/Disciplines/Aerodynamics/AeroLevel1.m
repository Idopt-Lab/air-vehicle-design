classdef AeroLevel1 < AerodynamicsModelLevel3
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
          e_osw
          CL
          CD
          CD0
          K
          K1 % Might need additional abstract classes for each fidelity level
          K2
     end

     methods

          % Compute Oswald span efficiency factor (WOOPDIE-DOO IT'S e!!!)
          function e_osw = get_e_osw(aero_obj, e_osw)
               % Level 1: Should be hard-coded or whatever. Independent of
               % design geometry.
               aero_obj.e_osw = e_osw;
          end

          % Get K value (gross estimate, tabulated)
          function K = get_K(aero_obj, K)
               % aero_obj.K1 = 1/(pi*AR*e_osw);
               aero_obj.K = K;
          end

          % Compute CD0
          % User must have tabulated these values beforehand: CD0, CL
          function DragResults = get_design_drag(aero_obj, CD0, CL)

               aero_obj.CD0 = CD0;
               aero_obj.CL = CL;

               aero_obj.CD = aero_obj.CD0 + aero_obj.K*aero_obj.CL^2;
          end

          % Get design drag
          function DragResults = get_design_CD0(input)

          end

          % Get design CD
          function output = get_design_CD(aero_obj, CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               aero_obj.CD = CD0 + K*CL^2;
               output = aero_obj.CD;
          end

          %% FOR MISSION ANALYSIS
          % Tabulate L/Dmax (cruise)
          function output = get_LDmax_cruise(aero_obj, LDmax, enginetype)
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
          function output = get_LDmax_loiter(aero_obj, LDmax, enginetype)
               if (enginetype == "jet")
                    LDmax_loiter = LDmax;
               elseif (enginetype == "prop")
                    LDmax_loiter = 0.866*LDmax;
               else
                    error("Error handler.")
               end
               output = LDmax_loiter;
          end

          %% L/Dmax for the design
          % Estimate L/Dmax
          function output = get_LDmax(aero_obj, geometry_obj, design_type)
               % Determine K_LD
               K_LD = aero_obj.tab_K_LD(design_type);
               AR_wetted = aero_obj.compute_AR_wetted(geometry_obj.mainwings.AR, geometry_obj.design.S_wet, geometry_obj.mainwings.S_ref);
               LDmax = K_LD*sqrt(AR_wetted); % Raymer, 6th edi, eq 3.12
               output = LDmax;
          end

          % Compute AR wetted
          function output = compute_AR_wetted(aero_obj, AR, S_wet, S_ref)
               AR_wetted = AR/(S_wet/S_ref); % Raymer, 6th ed, eq 3.11
               output = AR_wetted;
          end

          % Tabulate K_LD
          % Raymer, 6th ed, page 40
          function output = tab_K_LD(aero_obj, design_type)
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
               output = K_LD;
          end
          
     end
end
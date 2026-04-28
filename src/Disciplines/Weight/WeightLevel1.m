classdef WeightLevel1 < WeightModelLevel1
     %F16WEIGHTESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          MTOW
          OEW
          OEW_frac
          W_TO
          W_fixed
     end

     methods
          % Constructor
          function obj = WeightLevel1(design)
               obj.W_fixed = design.weights.Weights.Fixedlbf;
          end

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function output = get_OEW(weight_obj, design_type, W_TO)
               % Hard-coding some values (placeholders)
               if (design_type == "Sailplane_unpowered")
                    a = 0.86;
                    c = -0.05;
               elseif (design_type == "Sailplane_powered")
                    a = 0.91;
                    c = -0.05;
               elseif (design_type == "Homebuilt_metalorwood")
                    a = 1.19;
                    c = -0.09;
               elseif (design_type == "Homebuilt_composite")
                    a = 1.15;
                    c = -0.09;
               elseif (design_type == "General_aviation_single_engine")
                    a = 2.36;
                    c = -0.18;
               elseif (design_type == "General_aviation_twin_engine")
                    a = 1.51;
                    c = -0.10;
               elseif (design_type == "Agricultural_aircraft")
                    a = 0.74;
                    c = -0.03;
               elseif (design_type == "twin_turboprop")
                    a = 0.96;
                    c = -0.05;
               elseif (design_type == "flying_boat")
                    a = 1.09;
                    c = -0.05;
               elseif (design_type == "jet_trainer")
                    a = 1.59;
                    c = -0.10;
               elseif (design_type == "jet_fighter")
                    a = 2.34;
                    c = -0.13;
               elseif (design_type == "Military_cargo") || (design_type == "Military_bomber")
                    a = 0.93;
                    c = -0.07;
               elseif (design_type == "jet_transport")
                    a = 1.02;
                    c = -0.06;
               elseif (design_type == "UAV") || (design_type == "Tac_Recce") || (design_type == "UCAV")
                    a = 1.67;
                    c = -0.16;
               elseif (design_type == "UAV_high_altitude")
                    a = 2.75;
                    c = -0.18;
               elseif (design_type == "UAV_small")
                    a = 0.97;
                    c = -0.06;
               else
                    error("Error handler.")
               end

               weight_obj.OEW_frac = a*W_TO^c;

               weight_obj.OEW = weight_obj.OEW_frac*W_TO;

               output = weight_obj.OEW;
          end
     end
end
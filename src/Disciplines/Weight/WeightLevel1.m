classdef WeightLevel1
     %F16WEIGHTESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          MTOW
          OEW
          OEW_frac
          W_TO
          W_TO_guess
          W_fixed
          total_fuel_used
          fuel_fraction
          K_vs
     end

     methods (Static)

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function [OEW, OEW_frac] = get_OEW(design_type, W_TO)
               % Hard-coding some values (placeholders)
               if (design_type == "sailplane - unpowered")
                    a = 0.86;
                    c = -0.05;
               elseif (design_type == "sailplane - powered")
                    a = 0.91;
                    c = -0.05;
               elseif (design_type == "homebuilt metal or wood") || (design_type == "homebuilt - metal") || (design_type == "homebuilt - wood")
                    a = 1.19;
                    c = -0.09;
               elseif (design_type == "homebuilt - composite")
                    a = 1.15;
                    c = -0.09;
               elseif (design_type == "general aviation - single engine")
                    a = 2.36;
                    c = -0.18;
               elseif (design_type == "general aviation twin engine")
                    a = 1.51;
                    c = -0.10;
               elseif (design_type == "agricultural aircraft")
                    a = 0.74;
                    c = -0.03;
               elseif (design_type == "twin turboprop")
                    a = 0.96;
                    c = -0.05;
               elseif (design_type == "flying boat")
                    a = 1.09;
                    c = -0.05;
               elseif (design_type == "jet trainer")
                    a = 1.59;
                    c = -0.10;
               elseif (design_type == "jet fighter") || (design_type == "Jet fighter")
                    a = 2.34;
                    c = -0.13;
               elseif (design_type == "military cargo") || (design_type == "military bomber")
                    a = 0.93;
                    c = -0.07;
               elseif (design_type == "jet transport")
                    a = 1.02;
                    c = -0.06;
               elseif (design_type == "UAV") || (design_type == "Tac Recce") || (design_type == "UCAV")
                    a = 1.67;
                    c = -0.16;
               elseif (design_type == "UAV - high altitude")
                    a = 2.75;
                    c = -0.18;
               elseif (design_type == "UAV - small")
                    a = 0.97;
                    c = -0.06;
               else
                    error("Error handler.")
               end

               OEW_frac = a*W_TO^c;

               OEW = OEW_frac*W_TO;
          end
     end
end
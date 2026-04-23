classdef WeightLevel1 < WeightModelLevel3
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
          function output = get_OEW(weight_obj, W_TO)
               % Hard-coding some values (placeholders)
               a = 2.34;
               b = -0.13;

               weight_obj.OEW_frac = a*W_TO^b;

               weight_obj.OEW = weight_obj.OEW_frac*W_TO;

               output = weight_obj.OEW;
          end
     end
end
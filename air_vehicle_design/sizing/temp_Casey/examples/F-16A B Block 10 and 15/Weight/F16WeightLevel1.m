classdef F16WeightLevel1 < WeightModelLevel1
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

     methods

          % Constructor
          % Constructor
          function obj = F16WeightLevel1(design)
               obj.W_fixed = 5100;
               obj.W_TO_guess = 45000;
               obj.K_vs = design.weights.Coefficients.Kvs;
               [obj.OEW, obj.OEW_frac] = obj.get_OEW("jet fighter", obj.W_TO_guess);
          end

          function [OEW, OEW_frac] = get_OEW(weight_obj, design_type, W_TO)
               [OEW, OEW_frac] = WeightLevel1.get_OEW(design_type, W_TO);
          end

     end
end
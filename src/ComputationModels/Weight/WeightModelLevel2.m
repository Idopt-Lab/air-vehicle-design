classdef (Abstract) WeightModelLevel2 < handle
     %WEIGHTESTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          MTOW
          OEW
          W_fixed
     end

     methods (Abstract)
          % MTOW = estimate_design_weight(input)
          OEW = get_OEW(weight_obj, W0, AR, T, S_ref, M_max, K_vs)
     end
end
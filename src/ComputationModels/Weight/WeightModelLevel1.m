classdef (Abstract) WeightModelLevel1 < handle
     %WEIGHTMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          MTOW
          OEW
          OEW_frac
          W_TO
          W_fixed
     end

     methods (Abstract)
          OEW = get_OEW(weight_obj, design_type, W_TO)
     end
end
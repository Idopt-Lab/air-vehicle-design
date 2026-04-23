classdef (Abstract) WeightModelLevel1 < handle
     %WEIGHTMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          MTOW
          OEW
          W_TO
          W_fixed
     end

     methods (Abstract)
          output = get_OEW(weight_obj, W_TO)
     end
end
classdef (Abstract) WeightModelLevel1 < WeightBase
     %WEIGHTMODELLEVEL1 Level-1 (regression) weight-estimation contract.
     %   MTOW / OEW / W_fixed are inherited from WeightBase.

     properties (Abstract)
          OEW_frac
          W_TO
     end

     methods (Abstract)
          [OEW, OEW_frac] = get_OEW(weight_obj, design_type, W_TO)
     end
end
classdef (Abstract) WeightModelLevel2 < WeightBase
     %WEIGHTMODELLEVEL2 Level-2 (parametric) weight-estimation contract.
     %   MTOW / OEW / W_fixed are inherited from WeightBase.

     methods (Abstract)
          OEW = get_OEW(weight_obj, W0, AR, T, S_ref, M_max, K_vs)
     end
end
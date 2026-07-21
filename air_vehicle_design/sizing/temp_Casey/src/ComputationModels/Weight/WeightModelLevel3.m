classdef (Abstract) WeightModelLevel3 < WeightBase
     %WEIGHTMODELLEVEL3 Level-3 (component-buildup) weight-estimation contract.
     %   MTOW / OEW / W_fixed are inherited from WeightBase.

     properties (Abstract)
          OEW_frac
          wings
          tail
          fuselage
          subsystems
          engine
          landinggear
          W_TO_guess
          W_TO
     end

     methods (Abstract)
          % MTOW = estimate_design_weight(input)
          subsystem_weight = get_subsystem_weight(weight_obj, mission_obj, propulsion_obj, design)
          engine_weight = get_engine_weight(weight_obj, propulsion_obj, mission_obj, design)
          OEW = get_OEW(weight_obj, propulsion_obj, mission_obj, design, geometry_obj, W_TO)
     end
end
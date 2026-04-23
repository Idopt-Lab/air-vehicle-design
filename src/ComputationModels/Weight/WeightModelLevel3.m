classdef (Abstract) WeightModelLevel3 < handle
     %WEIGHTESTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          MTOW
          OEW
          OEW_frac
          wings
          tail
          subsystems
          engine
          landinggear_weight
          W_TO_guess
          W_TO
          W_fixed
     end

     methods (Abstract)
          % MTOW = estimate_design_weight(input)
          subsystem_weight = get_subsystem_weight(weight_obj, mission_obj, propulsion_obj, design)
          engine_weight = get_engine_weight(weight_obj, propulsion_obj, mission_obj, design)
          OEW = get_OEW(weight_obj, propulsion_obj, mission_obj, design, geometry_obj, W_TO)
     end
end
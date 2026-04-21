classdef (Abstract) WeightEstModel < handle
     %WEIGHTESTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          MTOW
          wings
          tail
          subsystems
          engine
          landinggear
          eps % Error tolerance
     end

     methods (Abstract)
          % MTOW = estimate_design_weight(input)
          [output] = get_subsystem_weight(input)
          [output] = get_engine_weight(input)
          [output] = get_OEW(input)
     end
end
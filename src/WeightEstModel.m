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
          MTOW = compute_MTOW(input)
          [output1, output2] = size_tail(input)
          [output] = get_subsystem_weight(input)
          [output] = get_engine_weight(input)

     end
end
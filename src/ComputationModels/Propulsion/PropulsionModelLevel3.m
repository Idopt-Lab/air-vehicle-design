classdef (Abstract) PropulsionModelLevel3 < handle
     %PROPULSIONMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          enginetype % Literally the type of engine (jet [high/low bpr], prop [pison, turbo])
          enginestats % A struct containing engine information (weight, geometry, quantity, performance specs)
          TSFC
          T0
     end

     methods (Abstract)
          output = get_engine_stats(propulsion_obj, mission_obj, design)
     end
end
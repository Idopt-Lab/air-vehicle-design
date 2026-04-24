classdef (Abstract) PropulsionModelLevel3 < handle
     %PROPULSIONMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          enginestats
          TSFC
          T0
     end

     methods (Abstract)
          output = get_propulsion_stats(propulsion_obj, mission_obj, design)
          enginestats = get_engine_stats(propulsion_obj, T, M, BPR, isafterburning)
     end
end
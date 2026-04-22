classdef (Abstract) PropulsionModelLevel3 < handle
     %PROPULSIONMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          enginestats
          TSFC
          T0
     end

     methods (Abstract)
          enginestats = get_propulsion_stats(propulsion_obj, mission_obj, design)
     end
end
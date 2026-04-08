classdef (Abstract) PropulsionModel < handle
     %PROPULSIONMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          enginestats
     end

     methods (Abstract)
          output = get_propulsion_stats(input)
     end
end
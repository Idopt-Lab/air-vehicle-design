classdef (Abstract) PropulsionBase < handle
     %PROPULSIONBASE Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          TR
          alpha % Thrust lapse rate (not dry or wet) (dry/wet should be design-specific)
          TSFC
     end

     methods (Abstract)
          TSFC = get_TSFC()
          alpha = get_thrust_lapse_rate()
     end
end
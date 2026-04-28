classdef (Abstract) PropulsionModelLevel1 < handle
     %PROPULSIONMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          TSFC
     end

     methods (Abstract)
          TSFC = get_TSFC(propulsion_obj, engine_type)
     end
end
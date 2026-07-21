classdef (Abstract) GeometryBase < handle
     %GEOMETRYBASE Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          S_ref
          S_wet
     end

     methods (Abstract)
          S_wet = get_S_wet()
          S_ref = get_S_ref()
     end
end
classdef (Abstract) GeometryEstModel < handle
     %GEOMETRYEST Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          % S_wet
     end

     methods (Abstract)
          size_tail(obj, design)
     end
end
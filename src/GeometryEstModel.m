classdef (Abstract) GeometryEstModel < handle
     %GEOMETRYEST Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          % S_wet
     end

     methods (Abstract)
          output = get_S_wet(obj, design)
          [s_ht, S_vt] = size_tail(obj, design)
     end
end
classdef (Abstract) GeometryEstModel < handle
     %GEOMETRYEST Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          mainwings
          HT
          VT
          fuselage
          strakes
          design
     end

     methods (Abstract)
          output = get_S_wet(obj, design)
          [s_ht, S_vt] = size_tail(obj, design)
     end
end
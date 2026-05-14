classdef (Abstract) GeometryModelLevel2 < handle
     %GEOMETRYMODELLEVEL2 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          mainwings
          HT
          VT
          fuselage
          design
     end

     methods (Abstract)
          S_wet_body = get_S_wet_body(geometry_obj, A_top, A_side)
          S_exposed_wing = get_S_exposed_wing(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
          S_wet_wing = get_S_wet_wing(geometry_obj, S_exposed, tc)
     end
end
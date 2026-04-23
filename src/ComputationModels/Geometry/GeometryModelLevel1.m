classdef (Abstract) GeometryModelLevel1 < handle
     %GEOMETRYMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          mainwings
          HT
          VT
          fuselage
          design
     end

     methods (Abstract)
          L_fuselage = get_fus_len(geometry_obj, aircraft_type, W_TO)
          [c_HT, c_VT] = est_tail_propers(geometry_obj, aircraft_type)
          % S_ref_mainwing = get_wing_area(geometry_obj, W_TO) % Figure out
          % the logistics of this. Update from "Size aircraft" or from
          % here?
     end
end
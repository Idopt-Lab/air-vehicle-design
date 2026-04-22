classdef (Abstract) GeometryModelLevel3 < handle
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
          output = get_design_S_wet(obj, W_TO)
          [s_ht, S_vt] = size_tail(obj, design, S_ref)
          S_exposed = get_S_exposed(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
          S_wet_wing = get_S_wet_wing(geometry_obj, S_exposed, tc)
          S_wet_fuselage = get_S_wet_fuselage(geometry_obj, fuselage_length, fuselage_max_width, max_height)
          QC_sweep = get_sweep_qc(geometry_obj, b, LE_sweep_deg, root_chord, tip_chord)
     end
end
classdef (Abstract) GeometryModelLevel3 < GeometryBase
     %GEOMETRYMODELLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     % Properties for the entire design
     properties (Abstract)
          S_ref
          S_wet
     end

     % Properties for the fuselage
     properties (Abstract)
          L_fuselage % Fuselage length
          W_max_fuselage % Maximum width of the fuselage
          H_max_fuselage % Maximum height of the fuselage
     end

     % Properties for the main wings
     properties (Abstract)
          S_exposed_wing
          S_wet_wing
          QC_sweep_wing
          lambda_wing
          b_wing
          AR_wing
          LE_sweep_wing
          TE_sweep_wing
          c_tip_wing
          c_root_wing
     end

     methods (Abstract)
          % output = get_design_S_wet(obj, W_TO)
          % [S_ht, S_vt] = size_tail(obj, design, S_ref)
          % S_exposed = get_S_exposed(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
          % S_wet_wing = get_S_wet_wing(geometry_obj, S_exposed, tc)
          % S_wet_fuselage = get_S_wet_fuselage(geometry_obj, fuselage_length, fuselage_max_width, max_height)
          % QC_sweep = get_sweep_qc(geometry_obj, b, LE_sweep_deg, root_chord, tip_chord)
     end
end
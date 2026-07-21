classdef (Abstract) GeometryModelLevel2 < GeometryBase
     %GEOMETRYMODELLEVEL2 Summary of this class goes here
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
          S_wet_body = get_S_wet_body(geometry_obj, A_top, A_side)
          S_exposed_wing = get_S_exposed_wing(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
          S_wet_wing = get_S_wet_wing(geometry_obj, S_exposed, tc)
     end
end
classdef (Abstract) GeometryModelL3 < GeometryBase
%GEOMETRYMODELL3  Tier-2a abstract enforcer for Level-3 geometry.
%
%   Inherits GeometryBase directly — NOT GeometryModelL2.
%   Adds an inlet/engine-duct component beyond the L2 surface set.
%
%   Inheritance: GeometryBase → GeometryModelL3 → GeomL3 → F16GeomL3

    % Abstract properties cannot have validation attributes in MATLAB.
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

     % Properties for the horizontal tail
    properties (Abstract)
          S_exposed_HT
          S_wet_HT
          QC_sweep_HT
          lambda_HT
          b_HT
          AR_HT
          LE_sweep_HT
          TE_sweep_HT
          c_tip_HT
          c_root_HT
    end

         % Properties for the vertical tail
    properties (Abstract)
          S_exposed_VT
          S_wet_VT
          QC_sweep_VT
          lambda_VT
          b_VT
          AR_VT
          LE_sweep_VT
          TE_sweep_VT
          c_tip_VT
          c_root_VT
    end

    % Include properties for any additional lifting surfaces (canards, etc).

    % Properties for any landing gear:
    % leg length
    % leg thickness/width/diameter
    % how many landing gear legs there are
    % wheel count per leg
    % wheel dimensions (length, width, thickness)
    % Frontal area
    % If you have no landing gear, set these to 0.

    % Properties for any high-lift devices:
    % HLD types (if you have multiple, split these accordingly, one property for each type)
    % hinge line angle
    % planform reference area of the HLD itself
    % "flapped" area
    % c'
    % c_flap &/or c_slat (chord length of whatever high-lift device you're using)
    % If you have no HLDs, set these to 0.

    % Properties for any engine inlet:
    % inlet shape
    % inlet length
    % inlet width/diameter
    % If you have no inlet, set these to 0.


     % For your own designs, add "properties" for each category of component to your own class.
     % For example, landing gear, high-lift devices, external objects... 
     % ... anything you can model reasonably at this level.

    methods (Abstract)
        %GET_S_WET_WING  Wing wetted area via Roskam Eq 12.1 (variable tc).
        val = get_S_wet_wing(obj)

        %GET_S_WET_HT  Horizontal tail wetted area.
        val = get_S_wet_HT(obj)

        %GET_S_WET_VT  Vertical tail wetted area.
        val = get_S_wet_VT(obj)

        %GET_S_WET_FUSELAGE  Fuselage wetted area (cylindrical midsection).
        val = get_S_wet_fuselage(obj)

        %GET_S_WET_DUCT  Inlet + engine duct wetted area (frustum formula).
        val = get_S_wet_duct(obj)

        %GET_S_EXPOSED_WING get the exposed area for a wing/lifting surface
        val = get_S_exposed_wing(obj)
    end
end

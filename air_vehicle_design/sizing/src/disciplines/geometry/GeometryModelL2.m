classdef (Abstract) GeometryModelL2 < GeometryBase
%GEOMETRYMODELL2  Tier-2a abstract enforcer for Level-2 geometry.
%
%   Inherits GeometryBase directly — NOT GeometryModelL1.
%   Each fidelity level independently satisfies the Tier-1 contract.
%
%   Declares the component-level S_wet sub-methods a concrete L2 toolbox
%   must implement.  No equations, no formula constants.
%
%   Inheritance: GeometryBase → GeometryModelL2 → GeomL2 → F16GeomL2

    % Abstract properties cannot have validation attributes in MATLAB.
    % Size/type validation is enforced in the first concrete class (GeomL2).
    % Properties for the fuselage
    properties (Abstract)
        L_fuselage % Fuselage length (ft)
        W_max_fuselage % Maximum width of the fuselage (ft)
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
        %GET_S_WET_WING  Wing exposed wetted area using planform + t/c correction.
        val = get_S_wet_wing(obj)

        %GET_S_WET_HT  Horizontal tail wetted area.
        val = get_S_wet_HT(obj)

        %GET_S_WET_VT  Vertical tail wetted area.
        val = get_S_wet_VT(obj)

        %GET_S_WET_FUSELAGE  Fuselage wetted area (cylindrical midsection model).
        val = get_S_wet_fuselage(obj)
    end
end

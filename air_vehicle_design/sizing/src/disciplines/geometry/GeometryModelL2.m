classdef (Abstract) GeometryModelL2 < GeometryBase
%GEOMETRYMODELL2  Tier-2 abstract enforcer for Level-2 geometry -- the
%   aircraft-agnostic core contract. Declares only the L2 geometry every
%   aircraft supplies and cross-discipline consumers read: exposed
%   wing/HT/VT areas and fuselage wetted area (L2 weights), wing span and
%   HT/VT reference areas (tail sizing), and fuselage length (tail arm).
%   Both F16GeomL2 and B777GeomL2 satisfy this set.
%
%   Detailed drag-build-up geometry (per-surface t/c, sweeps, duct, Amax,
%   L_aircraft) is not agnostic and stays concrete on F16GeomL2. A concrete
%   class supplies inputs as plain properties and derived quantities as
%   Dependent getters. See docs/decision_log.md.

    % Abstract properties cannot have validation attributes in MATLAB.
    % The first concrete class enforces size/type.
    properties (Abstract)
        % L_fuselage      % ft    fuselage length (anchors the tail arm) (commented out because not all designs have this)
        b_wing          % ft    wing span (tail-volume / tail-sizing input)

        % S_ht            % ft^2  FULL H-tail reference planform area -- sizing-loop
        %                 %       write-back slot the tail-sizing object sets
        % S_vt            % ft^2  FULL V-tail reference planform area -- write-back slot

        S_exposed_wing  % ft^2  exposed wing planform   (L2 weights build-up)
        % S_exposed_ht    % ft^2  exposed H-tail planform  (L2 weights build-up) (commented out because not all designs have this)
        % S_exposed_vt    % ft^2  exposed V-tail planform  (L2 weights build-up) (commented out because not all designs have this)
    end

    methods (Abstract) 
        % (commented out because not all designs have this)
        %GET_S_WET_FUSELAGE  Fuselage wetted area [ft^2]. Read by the L2
        %   weights fuselage term.
        % val = get_S_wet_fuselage(obj)

        %GET_S_EXPOSED_WING  Wing exposed area [ft^2] (passthrough).
        val = get_S_exposed_wing(obj)

        % TODO (8/19/2026)(Casey): There should be a method function for the control surfaces.
        % (Placeholder) Basically, size the mechanisms that enable control authority for your design.
        % Wasn't "control sizing" a different discipline?
        % Note (8/20/2026)(Casey): I'm pretty sure control effector sizing was moved to L1 and L2.
        % val = get_control_effectors_size(obj)
    end

    methods
        % See if you can merge both the fuselage and exposed wing wetted functions.
        function val = get_S_wet(obj)
            val = obj.get_design_S_wet_components();
        end
    end
end

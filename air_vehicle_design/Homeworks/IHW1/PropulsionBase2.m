classdef (Abstract) PropulsionBase2 < handle
%PROPULSIONBASE2  Abstract interface for aircraft propulsion models.
%
%   Defines the common interface required by aircraft sizing and
%   performance models. Concrete propulsion classes determine how
%   available shaft power, brake-specific fuel consumption, and
%   propeller efficiency are calculated.
%
%   The propulsion model is responsible for providing the appropriate
%   engine performance for a given aircraft state and propulsion rating.
%   The specific implementation may represent piston, turboprop,
%   electric, or other power-producing propulsion systems.
%
%   Examples:
%       PistonPropulsion
%       TurbopropPropulsion
%       ElectricPropulsion

    properties (Abstract)
        engine_type    % string; identifies the propulsion/engine type
        P_SL           % scalar; rated shaft power at sea level [hp]
    end

    methods (Abstract)

        % POWER_AVAILABLE
        %   Returns available shaft power [hp] for the given aircraft
        %   state and propulsion rating.
        P = power_available(obj, state, rating)

        % C_BHP
        %   Returns brake-specific fuel consumption [lbm/(hp*hr)]
        %   for the given aircraft state and propulsion rating.
        C_bhp = C_bhp(obj, state, rating)

        % PROP_EFF
        %   Returns propeller efficiency [-] for the given aircraft
        %   state.
        eta_p = prop_eff(obj, state)

    end

end
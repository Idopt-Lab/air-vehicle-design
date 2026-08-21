classdef (Abstract) PropulsionBase2 < handle
%PROPULSIONBASE  Abstract interface for aircraft propulsion models.
%
%   Defines the common interface required by aircraft sizing and
%   performance models. Concrete propulsion classes determine how
%   available thrust/power and fuel consumption are calculated.
%
%   Examples:
%       JetPropulsion
%       TurbopropPropulsion
%       PistonPropulsion
%       ElectricPropulsion

    properties (Abstract)
        engine_type    % string; selects the PropL1 lapse exponent and TSFC row
    end

    methods (Abstract)

        % AVAILABLE_THRUST
        %   Returns available propulsive thrust [lbf] for the given
        %   aircraft state and propulsion rating.
        T = available_thrust(obj, state, rating)

        % FUEL_FLOW
        %   Returns fuel mass flow rate [lbm/hr] for the given
        %   aircraft state and propulsion rating.
        mdot_f = fuel_flow(obj, state, rating)

    end

end
classdef AircraftState < handle
    % Common flight-condition input for all discipline methods.
    % Construct with altitude and Mach; atmospheric properties and
    % dynamic pressure are computed automatically.
    %
    % Usage:
    %   state = AircraftState(0, 0.9);   % sea-level, Mach 0.9
    %   state.q                          % dynamic pressure (lbf/ft²)

    properties
        altitude    % Pressure altitude (ft)
        mach        % Mach number (-)

        % Atmosphere (English units)
        T_atm       % Ambient temperature (°R)
        P_atm       % Ambient pressure (lbf/ft²)
        rho         % Air density (slug/ft³)
        a           % Speed of sound (ft/s)
        V           % True airspeed (ft/s)
        q           % Dynamic pressure (lbf/ft²)

        % Body-frame velocity components (ft/s)
        u           % Forward (default = V)
        v           % Lateral (default = 0)
        w           % Vertical (default = 0)

        % Derived angles (rad)
        alpha       % Angle of attack
        beta        % Sideslip angle
    end

    methods
        function obj = AircraftState(altitude_ft, mach)
            obj.altitude = altitude_ft;
            obj.mach     = mach;

            % Standard atmosphere — atmosisa expects altitude in meters
            [T_K, ~, P_Pa, rho_SI] = atmosisa(altitude_ft * 0.3048);

            % Convert to English units
            obj.T_atm = T_K   * 1.8;             % K  → °R
            obj.P_atm = P_Pa  * 0.020885;         % Pa → lbf/ft²
            obj.rho   = rho_SI * 0.00194032;       % kg/m³ → slug/ft³

            % Speed of sound and airspeed
            a_SI  = sqrt(1.4 * P_Pa / rho_SI);    % m/s
            obj.a = a_SI * 3.28084;               % ft/s
            obj.V = mach * obj.a;

            % Dynamic pressure
            obj.q = 0.5 * obj.rho * obj.V^2;

            % Default: straight-and-level flight
            obj.u     = obj.V;
            obj.v     = 0;
            obj.w     = 0;
            obj.alpha = 0;
            obj.beta  = 0;
        end
    end
end

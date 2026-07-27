classdef AircraftState
%AIRCRAFTSTATE  Immutable ISA atmosphere state at a given altitude and Mach.
%
%   s = AircraftState(altitude_ft, mach) builds the flight condition passed
%   into most discipline methods. All outputs are English units: lbf, ft, slug,
%   ft/s, deg R.
%
%   VALUE class (not handle): properties are set once in the constructor.
%
%   Atmosphere: MATLAB Aerospace Toolbox atmosisa (ICAO 1993).
%   Ratios: [Mattingly 2nd ed. Eq. 2.52]
%
%   Companion doc: src/core/AircraftState.md

    % ------------------------------------------------------------------ %
    properties (Constant, Access = private)
        T_STD_R   = 518.67;    % deg R  — standard sea-level static temperature
        P_STD_PSF = 2116.22;   % lbf/ft^2 — standard sea-level static pressure
    end

    % ------------------------------------------------------------------ %
    properties (SetAccess = private)
        altitude_ft (1,1) double   % ft        — geometric pressure altitude (input)
        mach        (1,1) double   % —         — flight Mach number (input)
        T_atm       (1,1) double   % deg R     — static temperature
        P_atm       (1,1) double   % lbf/ft^2  — static pressure
        rho         (1,1) double   % slug/ft^3 — air density
        a           (1,1) double   % ft/s      — speed of sound
        V           (1,1) double   % ft/s      — true airspeed (= mach * a)
        q           (1,1) double   % lbf/ft^2  — dynamic pressure (= 0.5*rho*V^2)
        theta       (1,1) double   % —         — T_atm / T_std   [Mattingly Eq. 2.52a]
        delta       (1,1) double   % —         — P_atm / P_std   [Mattingly Eq. 2.52b]
        theta_0     (1,1) double   % —         — theta*(1 + 0.2*M^2)   [Mattingly Eq. 2.52a]
        delta_0     (1,1) double   % —         — delta*(1 + 0.2*M^2)^3.5 [Mattingly Eq. 2.52b]
    end

    % ------------------------------------------------------------------ %
    methods
        function obj = AircraftState(altitude_ft, mach)
        %AIRCRAFTSTATE  Construct atmosphere state at altitude_ft and mach.
        %
        %   altitude_ft — geometric pressure altitude, ft (must be >= 0)
        %   mach        — flight Mach number (must be >= 0)
            arguments
                altitude_ft (1,1) double {mustBeNonnegative}
                mach        (1,1) double {mustBeNonnegative}
            end

            obj.altitude_ft = altitude_ft;
            obj.mach        = mach;

            % Unit conversion factors (exact where defined)
            ft2m         = 0.3048;         % m/ft  (exact by definition)
            K_to_R       = 1.8;            % deg R per K
            Pa_to_psf    = 0.3048^2 / 4.44822162;   % lbf/ft^2 per Pa  ≈ 0.020885
            kgm3_to_slug = (0.3048^3) / 14.5939029; % slug/ft^3 per kg/m^3  ≈ 0.0019403
            ms_to_fts    = 1.0 / ft2m;    % ft/s per m/s  ≈ 3.28084

            % ISA standard atmosphere (Aerospace Toolbox)
            [T_K, a_ms, P_Pa, rho_kgm3] = atmosisa(altitude_ft * ft2m);

            obj.T_atm = T_K      * K_to_R;       % deg R
            obj.P_atm = P_Pa     * Pa_to_psf;    % lbf/ft^2
            obj.rho   = rho_kgm3 * kgm3_to_slug; % slug/ft^3
            obj.a     = a_ms     * ms_to_fts;    % ft/s
            obj.V     = mach     * obj.a;         % ft/s
            obj.q     = 0.5      * obj.rho * obj.V^2; % lbf/ft^2

            % Dimensionless ratios  [Mattingly, Eq. 2.52]
            obj.theta   = obj.T_atm / AircraftState.T_STD_R;
            obj.delta   = obj.P_atm / AircraftState.P_STD_PSF;
            obj.theta_0 = obj.theta * (1 + 0.2 * mach^2);
            obj.delta_0 = obj.delta * (1 + 0.2 * mach^2)^3.5;
        end
    end
end

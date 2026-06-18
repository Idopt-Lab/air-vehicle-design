classdef AeroLevel2 < AerodynamicsBase
    % Level II aerodynamics: Oswald efficiency factor and Roskam S_wet regression.
    %
    % Improvement over Level I: K2 is computed from the actual Oswald span
    % efficiency factor (1/(pi*e*AR)) rather than the K_LD factor approximation.
    % CD0 still uses a tabulated equivalent Cf times the total S_wet/S_ref.
    % K1 = 0 (symmetric polar; use Level III for cambered-polar correction).
    %
    % Usage:
    %   Cf   = AeroLevel1.get_Cf('air force fighter', 1);
    %   aero = AeroLevel2('fighter', Cf, 3.0, 0.8, S_wet, S_ref);
    %   polar = aero.drag_polar(AircraftState(35000, 0.85));

    properties
        aircraft_type   % normalized type string, used for CLmax table
        Cf              % equivalent skin friction coefficient (-)
        AR              % wing aspect ratio (-)
        e_osw           % Oswald span efficiency factor (-)
        S_wet           % total aircraft wetted area (ft²)
        S_ref           % wing reference area (ft²)
    end

    methods
        function obj = AeroLevel2(aircraft_type, Cf, AR, e_osw, S_wet, S_ref)
            obj.aircraft_type = aircraft_type;
            obj.Cf    = Cf;
            obj.AR    = AR;
            obj.e_osw = e_osw;
            obj.S_wet = S_wet;
            obj.S_ref = S_ref;
        end

        function polar = drag_polar(obj, state) %#ok<INUSD>
            CD0 = AeroLevel2.compute_CD0(obj.Cf, obj.S_wet, obj.S_ref);
            K2  = AeroLevel2.compute_K(obj.e_osw, obj.AR);
            polar.CD0 = CD0;
            polar.K1  = 0;
            polar.K2  = K2;
        end

        function CL = CLmax(obj, state) %#ok<INUSD>
            CL = AeroLevel1.tab_CLmax_values(obj.aircraft_type, "clean");
        end
    end

    %% Static computation methods
    methods (Static)

        function K = compute_K(e_osw, AR)
            K = 1 / (pi * AR * e_osw);
        end

        function CD = compute_CD(CD0, K, CL)
            CD = CD0 + K*CL^2;
        end

        function CD0 = compute_CD0(Cf, S_wet_aircraft, S_ref)
            CD0 = Cf * S_wet_aircraft / S_ref;
        end

    end

end

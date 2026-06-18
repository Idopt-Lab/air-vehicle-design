classdef F16AeroLevel1 < AeroLevel1
    % F-16 Level I aerodynamics: type-based friction and K_LD lookup.
    %
    % Uses Brandt anchor S_wet (1331.09 ft²) computed from Roskam regression
    % at TOGW = 31377 lb.  S_ref and b from JSON.

    methods
        function obj = F16AeroLevel1(geom_json)
            aircraft_type = 'jet fighter';
            S_ref  = geom_json.wing.S_ref_ft2;
            AR     = geom_json.wing.AR;
            b      = sqrt(AR * S_ref);
            W_TO   = geom_json.mission.W_TO_lb;

            % Cf from type table (Raymer equivalent skin friction)
            Cf  = AeroLevel1.get_Cf('air force fighter', geom_json.engine.n_engines);

            % K_LD from Raymer-type table
            K_LD = AeroLevel1.tab_K_LD('jet fighter');

            % S_wet from Roskam regression at Brandt W_TO
            [S_wet, ~, ~] = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);

            obj@AeroLevel1(aircraft_type, Cf, K_LD, S_wet, S_ref, b);
        end
    end
end

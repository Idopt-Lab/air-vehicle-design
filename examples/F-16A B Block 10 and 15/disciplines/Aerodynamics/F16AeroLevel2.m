classdef F16AeroLevel2 < AeroLevel2
    % F-16 Level II aerodynamics: Oswald efficiency + Cfe from JSON.
    %
    % Uses effective Cf (Cfe) back-calculated from Brandt's Miss!CD0 = 0.0270
    % and Brandt S_wet = 1331.09 ft².  Cfe = 0.005908 (JSON aero.Cfe).

    methods
        function obj = F16AeroLevel2(geom_json)
            aircraft_type = 'jet fighter';
            S_ref  = geom_json.wing.S_ref_ft2;
            AR     = geom_json.wing.AR;
            lambda = geom_json.wing.taper;
            W_TO   = geom_json.mission.W_TO_lb;

            % Tabulated Cfe from Raymer lookup (appropriate for Roskam S_wet regression)
            Cf = geom_json.aero.Cfe_tab;

            % Oswald efficiency (Raymer formula for swept wing)
            Lambda_LE = geom_json.wing.sweep_LE_deg;
            e_osw = 4.61*(1 - 0.045*AR^0.68)*cosd(Lambda_LE)^0.15 - 3.1;
            e_osw = max(0.5, min(0.95, e_osw));  % clamp to physical range

            % S_wet from Roskam regression at Brandt W_TO
            [S_wet, ~, ~] = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);

            obj@AeroLevel2(aircraft_type, Cf, AR, e_osw, S_wet, S_ref);
        end
    end
end

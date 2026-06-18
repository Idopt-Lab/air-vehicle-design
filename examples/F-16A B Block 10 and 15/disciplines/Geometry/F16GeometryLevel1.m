classdef F16GeometryLevel1 < GeometryLevel1
    % F-16 Level I geometry: Roskam S_wet and L_fus regression for fighters.

    methods
        function obj = F16GeometryLevel1(geom_json)
            S_ref = geom_json.wing.S_ref_ft2;
            W_TO  = geom_json.mission.W_TO_lb;  % Brandt anchor weight
            obj@GeometryLevel1('jet fighter', W_TO, S_ref);
        end
    end
end

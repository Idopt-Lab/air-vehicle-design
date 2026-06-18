classdef F16AeroLevel3 < AeroLevel3
    % F-16 Level III aerodynamics: component drag buildup via F16GeometryLevel3.
    %
    % Wraps AeroLevel3 with the F-16 geometry object.

    methods
        function obj = F16AeroLevel3(geom_json)
            geom = F16GeometryLevel3(geom_json);
            obj@AeroLevel3(geom);
        end
    end
end

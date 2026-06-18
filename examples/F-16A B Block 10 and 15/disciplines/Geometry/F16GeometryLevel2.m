classdef F16GeometryLevel2 < GeometryLevel2
    % F-16 Level II geometry: Roskam S_wet regression + explicit wing dimensions.

    methods
        function obj = F16GeometryLevel2(geom_json)
            S_ref  = geom_json.wing.S_ref_ft2;
            AR     = geom_json.wing.AR;
            lambda = geom_json.wing.taper;
            tc     = geom_json.wing.tc_ratio;
            W_TO   = geom_json.mission.W_TO_lb;
            b      = sqrt(AR * S_ref);
            obj@GeometryLevel2('jet fighter', W_TO, S_ref, b, AR, tc, lambda);
        end
    end
end

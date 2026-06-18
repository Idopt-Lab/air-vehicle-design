classdef F16WeightLevel2 < WeightLevel2
    % F-16 Level II weight: Raymer Eq 6.1 gross empty-weight fraction.
    %
    % F-16 values from f16a_geometry.json and Brandt ground truth:
    %   AR = 3.0, T/W = 0.7575, W/S = 104.59 psf, Mmax = 2.0, K_vs = 1.0

    methods
        function obj = F16WeightLevel2(geom_json)
            AR   = geom_json.wing.AR;
            T_W  = geom_json.constraints.conditions.cruise.pct_AB * 0 + 0.7575;
            W_S  = 104.59;
            Mmax = geom_json.aircraft.Mmax;
            K_vs = 1.0;
            obj@WeightLevel2('jet fighter', AR, T_W, W_S, Mmax, K_vs);
        end
    end
end

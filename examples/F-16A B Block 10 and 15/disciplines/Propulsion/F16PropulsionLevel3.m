classdef F16PropulsionLevel3 < PropulsionLevel3
    % F-16 Level III propulsion: Mattingly dry/wet thrust lapse model.

    methods
        function obj = F16PropulsionLevel3(geom_json)
            T_SL_AB = geom_json.engine.T_AB_SLS_lb;
            BPR     = 0.6;
            obj@PropulsionLevel3('low_bypass_mixed_turbofan', 'max', BPR);
            obj.T0 = T_SL_AB;
        end
    end
end

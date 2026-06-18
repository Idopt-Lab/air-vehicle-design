classdef F16PropulsionLevel2 < PropulsionLevel2
    % F-16 Level II propulsion: Mattingly installed TSFC.

    methods
        function obj = F16PropulsionLevel2(geom_json)
            T_SL_AB = geom_json.engine.T_AB_SLS_lb;
            BPR     = 0.6;  % F100 low-bypass turbofan BPR
            obj@PropulsionLevel2('low_bypass_mixed_turbofan', 'max', BPR);
            obj.T0 = T_SL_AB;
        end
    end
end

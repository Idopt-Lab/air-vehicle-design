classdef F16PropulsionLevel1 < PropulsionLevel1
    % F-16 Level I propulsion: tabulated TSFC by engine type.
    %
    % The F-16 uses a low-bypass-ratio mixed-flow turbofan (F100 engine).
    % Thrust lapse: density-ratio power law (exponent 1.0 for low-BPR with AB).

    methods
        function obj = F16PropulsionLevel1(geom_json)
            T_SL_AB = geom_json.engine.T_AB_SLS_lb;
            obj@PropulsionLevel1('low_bypass_mixed_turbofan');
            obj.T0 = T_SL_AB;
        end
    end
end

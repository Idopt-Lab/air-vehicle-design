classdef F16WeightLevel1 < WeightLevel1
    % F-16 Level I weight: Raymer Table 6.1 fighter regression.

    methods
        function obj = F16WeightLevel1()
            obj@WeightLevel1('jet fighter');
        end
    end
end

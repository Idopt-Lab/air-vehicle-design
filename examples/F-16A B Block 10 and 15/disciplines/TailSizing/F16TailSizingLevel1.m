classdef F16TailSizingLevel1 < TailSizingLevel1
    % F-16 tail sizing using Raymer Table 6.4 volume coefficients for fighters.
    %   c_HT = 0.40, c_VT = 0.07

    methods
        function obj = F16TailSizingLevel1()
            obj@TailSizingLevel1(0.40, 0.07);
        end
    end
end

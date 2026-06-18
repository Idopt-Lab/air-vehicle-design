classdef F16MissionLevel2 < MissionAnalysisLevel2
    % F-16 Level II mission: segment-by-segment Breguet.
    % No F-16-specific configuration needed — all inputs come through req and
    % aero/prop discipline objects.

    methods
        function obj = F16MissionLevel2()
            obj@MissionAnalysisLevel2();
        end
    end
end

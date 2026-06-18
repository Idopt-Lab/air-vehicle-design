classdef F16MissionLevel1 < MissionAnalysisLevel1
    % F-16 Level I mission: Roskam fuel fractions for fighter aircraft.

    methods
        function obj = F16MissionLevel1()
            obj@MissionAnalysisLevel1('fighter', 'jet');
        end
    end
end

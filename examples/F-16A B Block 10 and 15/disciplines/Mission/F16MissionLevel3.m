classdef F16MissionLevel3 < MissionAnalysisLevel3
    % F-16 Level III mission: sub-segmented numerical integration.
    % No F-16-specific configuration needed.

    methods
        function obj = F16MissionLevel3(n_sub)
            if nargin < 1; n_sub = 20; end
            obj@MissionAnalysisLevel3(n_sub);
        end
    end
end

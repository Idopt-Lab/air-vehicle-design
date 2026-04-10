% Written by ChatGPT
% Extracts leaf values from the end of a struct.

% S = 1 step from end of structure branch.
% Example: missions.missiondata.Climb
function vals = getLeafValues(S)
    vals = {};

    if ~isstruct(S)
        vals = {S};
        return
    end

    fn = fieldnames(S);

    for k = 1:numel(fn)
        value = S.(fn{k});

        if isstruct(value)
            vals = [vals; getLeafValues(value)];
        else
            vals = [vals; {value}];
        end
    end
end
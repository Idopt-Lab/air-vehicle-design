function [p] = ttpa_requirements_path()
%TTPA_REQUIREMENTS_PATH  Absolute path to the IHW3a requirements JSON.
%
%   p = ttpa_requirements_path() returns Ttpa_requirements_IHW3.json.
%
%   IHW3a has its own requirements file. It carries the aerodynamics, the
%   propulsion, the constraints and the missions blocks of the IHW2 file
%   forward, so the IHW1 mission analysis and the IHW2 constraint analysis
%   both run against it unchanged, and it adds the geometry, weights and
%   sizing blocks the loop needs. Read this file and only this file in
%   IHW3a.
%
%   The JSON is looked for in this folder first and in the folder above
%   after that, so the code runs both from a flat folder and from the
%   homework tree.

    here = fileparts(mfilename('fullpath'));

    local = fullfile(here, 'Ttpa_requirements_IHW3.json');

    if isfile(local)
        p = string(local);
    else
        p = string(fullfile(here, '..', 'Ttpa_requirements_IHW3.json'));
    end

end

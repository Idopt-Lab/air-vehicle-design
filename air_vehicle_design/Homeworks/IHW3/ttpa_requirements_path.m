function [p] = ttpa_requirements_path()
%TTPA_REQUIREMENTS_PATH  Absolute path to the IHW2 requirements JSON.
%
%   p = ttpa_requirements_path() returns Ttpa_requirements_IHW2.json.
%
%   IHW2 has its own requirements file. It repeats the geometry and the
%   mission blocks of the IHW1 file unchanged, and adds the aerodynamic,
%   the propulsion and the constraint data the matching analysis needs.
%   Read this file and only this file in IHW2.
%
%   The JSON is looked for in this folder first, and in the folder above
%   after that, so the code runs both from a flat folder and from the
%   homework tree.

    here = fileparts(mfilename('fullpath'));

    local = fullfile(here, 'Ttpa_requirements_IHW2.json');

    if isfile(local)
        p = string(local);
    else
        p = string(fullfile(here, '..', 'Ttpa_requirements_IHW2.json'));
    end

end

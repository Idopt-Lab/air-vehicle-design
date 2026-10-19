function root = setup_aero_path()
%SETUP_AERO_PATH  Put this lesson's helpers on the path.
%
%   root = SETUP_AERO_PATH() adds helpers/ to the MATLAB path and returns
%   the package root folder. Call it at the top of every lecture and lab
%   script. It is safe to call more than one time.

    root = fileparts(mfilename('fullpath'));
    addpath(root);                          % so lecture/ and lab/ scripts find this file
    addpath(fullfile(root, 'helpers'));
end

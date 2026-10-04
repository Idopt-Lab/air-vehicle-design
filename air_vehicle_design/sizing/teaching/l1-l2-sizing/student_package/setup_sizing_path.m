function root = setup_sizing_path()
%SETUP_SIZING_PATH  Put the sizing framework on the MATLAB path.
%
%   root = SETUP_SIZING_PATH() adds this package's framework/ tree and
%   helpers/ folder to the MATLAB path and returns the package root folder.
%   Call it at the top of every lecture and lab script. It is safe to call
%   more than one time.
%
%   The package is self-contained. Nothing outside this folder is used.

    root = fileparts(mfilename('fullpath'));

    fw = fullfile(root, 'framework');
    if ~isfolder(fw)
        error('setup_sizing_path:noFramework', ...
            ['The framework/ folder is missing from %s.\n', ...
             'Unzip the whole package, then run START_HERE again.'], root);
    end

    addpath(genpath(fullfile(fw, 'src')));
    addpath(genpath(fullfile(fw, 'examples')));
    addpath(fullfile(root, 'helpers'));
end

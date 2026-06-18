function startup()
% startup  Add all Air Vehicle Design framework paths to MATLAB.
%
%   Called automatically when a MATLAB Project session opens, or run
%   manually before using the framework:
%
%       >> startup
%
%   This is the single source of truth for paths.  Do NOT call addpath
%   from individual scripts or test files; call startup() instead.

root = fileparts(mfilename('fullpath'));

% Framework source (generic, aircraft-agnostic)
addpath(root);                                          % +avd package root
addpath(genpath(fullfile(root, 'src')));                % legacy + new discipline classes

% F-16 example (path must handle the space in the folder name)
f16_root = fullfile(root, 'examples', 'F-16A B Block 10 and 15');
if isfolder(f16_root)
    addpath(f16_root);
    addpath(genpath(fullfile(f16_root, 'disciplines')));
    addpath(genpath(fullfile(f16_root, 'tests')));
end

fprintf('[avd] Framework ready.  Root: %s\n', root);
end

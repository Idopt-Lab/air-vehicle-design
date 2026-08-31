function startup
%STARTUP  Repo-local MATLAB startup for air-vehicle-design.
%   Initializes the Simulink Agentic Toolkit (SATK) so the MCP model_* tools
%   (model_overview, model_read, model_check, ...) resolve, and puts the mbse
%   example models on the path so those tools can find them by filename.
%
%   Without this, the model_* tools fail with "Unrecognized function or
%   variable 'model_overview'" even though Claude shows the tool schemas -- the
%   MCP layer and the MATLAB layer are separate and neither implies the other.
%
%   MATLAB runs this file only when it starts in the repo root. Launching from
%   the Start Menu will not pick it up; start MATLAB from this folder, or run
%   startup manually.

repoRoot = fileparts(mfilename('fullpath'));

initializeSatk();
addpath(genpath(fullfile(repoRoot, 'air_vehicle_design', 'mbse', 'examples')));
end


function initializeSatk()
%INITIALIZESATK  Put SATK on the path and initialize it.
%   Warns rather than errors: a broken toolkit must not stop MATLAB starting.

satkRoot = fullfile(getenv('USERPROFILE'), '.matlab', 'agentic-toolkits', 'simulink');
if isempty(dir(fullfile(satkRoot, 'satk_initialize.*')))
    warning('startup:satkMissing', ...
        'SATK not found at %s; the MCP model_* tools will not work.', satkRoot);
    return
end

addpath(satkRoot);
try
    satk_initialize;   % prints its own installation report
catch err
    warning('startup:satkFailed', 'satk_initialize failed: %s', err.message);
end

% satk_initialize short-circuits once it believes it has already run, and that
% guard survives a path reset -- so re-add the tool folders ourselves if the
% entry points are still missing.
if isempty(which('model_overview'))
    addToolFolders(satkRoot);
end

if isempty(which('model_overview'))
    warning('startup:satkIncomplete', ...
        'SATK initialized but model_overview is still unresolved.');
end
end


function addToolFolders(satkRoot)
%ADDTOOLFOLDERS  Add each SATK tool folder (one folder per model_* entry point).

toolsRoot = fullfile(satkRoot, 'tools');
folders = dir(toolsRoot);
folders = folders([folders.isdir] & ~startsWith({folders.name}, '.'));

addpath(toolsRoot);
for k = 1:numel(folders)
    addpath(fullfile(toolsRoot, folders(k).name));
end
rehash path;
end

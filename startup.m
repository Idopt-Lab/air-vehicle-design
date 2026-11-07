function startup
%STARTUP  Repo-local MATLAB startup for air-vehicle-design.
%   Puts the mbse example models on the path so the MCP model_* tools
%   (model_overview, model_read, model_check, ...) can find them by bare
%   filename.
%
%   The model_* tools themselves come from the Simulink Agentic Toolkit, which
%   the MathWorks Agentic Toolkits installer adds as a MATLAB Add-On; it is on
%   the path in every session and needs no initialization here.
%
%   MATLAB runs this file only when it starts in the repo root. Launching from
%   the Start Menu will not pick it up; start MATLAB from this folder, or run
%   startup manually.

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(repoRoot, 'air_vehicle_design', 'mbse', 'examples')));
end

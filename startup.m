function startup
%STARTUP  Repo-local MATLAB startup for air-vehicle-design.
%   Puts the F-16A RFLP example on the path so the MCP model_* tools
%   (model_overview, model_read, model_check, ...) can find its models by bare
%   filename, and run_ai_tests resolves without opening the project.
%
%   Only the f16a folders are added, not every example: ex1/ and ex2/ both
%   contain an Aircraft.slx, and putting both on the path makes one silently
%   shadow the other. Open those examples by absolute path or from their folder.
%
%   The model_* tools themselves come from the Simulink Agentic Toolkit Add-On;
%   it is on the path in every session and needs no initialization here.
%
%   MATLAB runs this file only when it starts in the repo root. Launching from
%   the Start Menu will not pick it up; start MATLAB from this folder, or run
%   startup manually.

f16a = fullfile(fileparts(mfilename('fullpath')), ...
    'air_vehicle_design', 'mbse', 'examples', 'f16a');
addpath(f16a, ...
    fullfile(f16a, 'requirements'), ...
    fullfile(f16a, 'functions'), ...
    fullfile(f16a, 'logical'), ...
    fullfile(f16a, 'physical'), ...
    fullfile(f16a, 'verification'), ...
    fullfile(f16a, 'tests_for_ai_coding'));
end

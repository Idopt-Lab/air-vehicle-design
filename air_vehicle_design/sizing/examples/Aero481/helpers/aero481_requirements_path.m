function p = aero481_requirements_path()
%Aero481_REQUIREMENTS_PATH  Absolute path to the F-35 requirements JSON.
%   p = aero481_requirements_path() returns examples/Aero481/inputs/aero481_requirements.json.
%
%   REQUIREMENTS vs SPEC -- aero481_spec_path(N) holds what the airframe/engine
%   ARE; this file holds what the aircraft must DO (constraint conditions + the
%   DCA mission profile). Requirements do not vary with fidelity, so this takes
%   NO level argument. Never mix the two.
%
%   Consumers: Aero481ConstraintSet (the ConstraintType map) and the mission
%   analysis (reads the .missions.dca profile).
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', 'aero481_requirements.json');
end

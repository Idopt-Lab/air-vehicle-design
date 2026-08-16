function p = aero481_requirements_path()
%Aero481_REQUIREMENTS_PATH  Absolute path to the F-35 requirements JSON.
%   p = aero481_requirements_path() returns examples/Aero481/inputs/aero481_requirements.json.
%
%   REQUIREMENTS vs SPEC -- the same distinction f16a_requirements_path and
%   b777_requirements_path enforce. aero481_spec_path(N) returns AIRCRAFT SPEC data:
%   what this airframe and engine ARE (reference areas, aspect ratio, thrust,
%   engine model). The requirements file holds what the aircraft must DO: the
%   constraint conditions (cruise/dash, sustained/instantaneous turns, specific
%   excess power, ceiling, the six climb segments, takeoff/landing) and the DCA
%   mission profile. Requirements do not vary with fidelity level, so -- unlike
%   aero481_spec_path -- this takes NO level argument. Never put spec data here, and
%   never put a requirement in a spec file.
%
%   Consumers: Aero481ConstraintSet (the condition-name -> ConstraintType map fed to
%   ConstraintAnalysis.from_requirements) and the mission analysis
%   (from_requirements reads the .missions.dca profile).
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', 'aero481_requirements.json');
end

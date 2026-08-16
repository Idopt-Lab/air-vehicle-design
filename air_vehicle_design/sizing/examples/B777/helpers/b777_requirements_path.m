function p = b777_requirements_path()
%B777_REQUIREMENTS_PATH  Absolute path to the B777-200LR requirements JSON.
%   p = b777_requirements_path() returns examples/B777/inputs/b777_requirements.json.
%
%   REQUIREMENTS vs SPEC -- b777_spec_path(N) holds what the airframe/engine ARE;
%   this file holds what the aircraft must DO (field lengths, climb gradients,
%   cruise/ceiling conditions, design range, mission profiles). Requirements do
%   not vary with fidelity, so this takes NO level argument. Never mix the two.
%
%   Consumers: B777ConstraintSet (the ConstraintType map) and the mission
%   analysis (reads the .missions profiles).
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', 'b777_requirements.json');
end

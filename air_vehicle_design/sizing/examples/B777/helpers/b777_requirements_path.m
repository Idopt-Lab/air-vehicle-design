function p = b777_requirements_path()
%B777_REQUIREMENTS_PATH  Absolute path to the B777-200LR requirements JSON.
%   p = b777_requirements_path() returns examples/B777/inputs/b777_requirements.json.
%
%   REQUIREMENTS vs SPEC -- the same distinction f16a_requirements_path enforces.
%   b777_spec_path(N) returns AIRCRAFT SPEC data: what this airframe and engine
%   ARE (reference areas, aspect ratio, thrust, engine model). The requirements
%   file holds what the aircraft must DO: field lengths, climb gradients, the
%   cruise/ceiling conditions, design range, and the mission profiles.
%   Requirements do not vary with fidelity level, so -- unlike b777_spec_path --
%   this takes NO level argument. Never put spec data here, and never put a
%   requirement in a spec file.
%
%   Consumers: B777ConstraintSet (the condition-name -> ConstraintType map fed to
%   ConstraintAnalysis.from_requirements) and the mission analysis
%   (from_requirements reads the .missions profiles).
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', 'b777_requirements.json');
end

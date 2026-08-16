function p = b777_spec_path(level)
%B777_SPEC_PATH  Absolute path to the unified B777-200LR input JSON for a level.
%   p = b777_spec_path(1) returns examples/B777/inputs/b777_L1.json.
%   One file holds the geometry (.geometry), aerodynamics (.aerodynamics),
%   propulsion (.propulsion) and weights (.weights) inputs the level's
%   B777GeomL2 / B777AeroL1 / B777PropL1 / B777WeightsL2 classes read.
%
%   B777 is L1-ONLY (metabook Example 4.2 is the only fidelity), so mustBeMember
%   pins level to 1 (same idiom as f16a_spec_path).
    arguments
        level (1,1) double {mustBeMember(level, 1)}
    end
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', sprintf('b777_L%d.json', level));
end

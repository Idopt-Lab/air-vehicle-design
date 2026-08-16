function p = aero481_spec_path(level)
%Aero481_SPEC_PATH  Absolute path to the unified F-35 input JSON for a level.
%   p = aero481_spec_path(1) returns examples/Aero481/inputs/aero481_L1.json.
%   One file holds the geometry (.geometry), aerodynamics (.aerodynamics),
%   propulsion (.propulsion) and weights (.weights) inputs the level's
%   Aero481GeomL1 / Aero481AeroL1 / Aero481PropL1 / Aero481WeightsL1 classes read.
%
%   F-35 is L1-ONLY (Aero 481 Design01 is the only fidelity), so mustBeMember
%   pins level to 1 (same idiom as b777_spec_path).
    arguments
        level (1,1) double {mustBeMember(level, 1)}
    end
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', sprintf('aero481_L%d.json', level));
end

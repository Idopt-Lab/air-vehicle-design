function p = f16a_spec_path(level)
%F16A_SPEC_PATH  Absolute path to the unified F-16A input JSON for a fidelity level.
%   p = f16a_spec_path(N) returns examples/F16A/inputs/f16a_LN.json (N = 1, 2, or 3).
%   One file per level holds both the geometry (.geometry) and aerodynamics
%   (.aerodynamics) inputs the level's F16GeomLN / F16AeroLN classes read.
    arguments
        level (1,1) double {mustBeMember(level, [1 2 3])}
    end
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', sprintf('f16a_L%d.json', level));
end

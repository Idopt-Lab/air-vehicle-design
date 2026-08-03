function p = mission_profile_path()
%MISSION_PROFILE_PATH  Absolute path to the F-16A CAP mission-profile JSON.
%   p = mission_profile_path() returns examples/F16A/jsons/mission_profile.json.
%   Fidelity-independent (unlike f16a_spec_path): F16MissionL1/L2/L3 all read
%   the same CAP profile file. Added 2026-07-30 so F16MissionL1/L2/L3's
%   constructors can require an explicit path argument, matching every other
%   discipline's "no silent default" convention (CLAUDE.md), instead of each
%   resolving fileparts(mfilename('fullpath')) internally.
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, 'jsons', 'mission_profile.json');
end

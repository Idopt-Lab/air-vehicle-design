function p = f16a_stations_path()
%F16A_STATIONS_PATH  Absolute path to the F-16A geometry-station JSON.
%   p = f16a_stations_path() returns examples/F16A/inputs/F16_geom_stations.json.
%
%   The file holds CONTROL STATIONS: a cross-section table for the fuselage and
%   the nacelle, planform corner points for each lifting surface, and the
%   whole-aircraft cross-sectional-area distribution. It takes no level
%   argument: station coordinates do not vary with fidelity.
%
%   Consumer: F16GeomL3.get_S_wet_fuselage_stations.
%
%   Mod (08/19/2026) (Claude)
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, '..', 'inputs', 'F16_geom_stations.json');
end

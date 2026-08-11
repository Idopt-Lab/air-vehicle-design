function r = F16AMissionReference(options)
%F16AMISSIONREFERENCE The /sizing/ mission analysis, run once and remembered.
%   R = F16AMISSIONREFERENCE() returns the raw result struct from
%   sizing/VnV/BrandtF16A/BrandtMission.run, covering all 14 reference
%   segments. Fields used here: segment_names, fuel_lb, time_min, dist_nm,
%   alt_ft, mach_end, pct_AB, total_fuel_lb, total_time_min.
%
%   F16AMISSIONREFERENCE(Reset=true) forgets the cached answer and re-runs.
%
%   The answer is CACHED because every mission-phase action asks for it
%   (F16AMissionSegment is bound to all ten), and running the chain once per
%   action would be ten identical analyses per model update.
%
%   The cache holds the RESULT STRUCT, not the Brandt objects, so nothing
%   outlives the path guard and no handle into /sizing/ is left behind.
%
%   See also F16AMISSIONSEGMENT, F16AMISSIONANALYSIS.

arguments
    options.Reset (1,1) logical = false
end

persistent cached
if options.Reset
    cached = [];
end
if ~isempty(cached)
    r = cached;
    return
end

SIZING_POINT_LB = 31377;   % Wt!B3, the same point the cost model prices

% /sizing/ is three levels above the example root and is reached by PATH, never
% by project membership (D-047). The guard puts the path back on return; a bare
% addpath would leave sizing/ resolvable for every later suite in the session.
avd  = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16AMissionReference:noSizingModel", ...
        "The mission analysis was not found at %s. This model DELEGATES the " + ...
        "mission to /sizing/ rather than restating the segment equations, so " + ...
        "the folder has to be present.", bDir);
end
oldPath = path();
guard   = onCleanup(@() path(oldPath));  %#ok<NASGU> held until this function returns
addpath(bDir);

% Argument order is (aero, eng, geom) -- BrandtMission is the one class in that
% folder that is not geometry-first.
geom = BrandtGeometry();          geom.analyze();
aero = BrandtAerodynamics(geom);  aero.analyze();
eng  = BrandtEngine();            eng.analyze();
miss = BrandtMission(aero, eng, geom);

cached = miss.run(SIZING_POINT_LB);
r = cached;

end

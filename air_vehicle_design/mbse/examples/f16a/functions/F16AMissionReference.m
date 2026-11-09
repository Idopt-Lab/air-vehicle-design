function r = F16AMissionReference(options)
%F16AMISSIONREFERENCE Run the /sizing/ mission analysis one time and keep the result.
%   R = F16AMISSIONREFERENCE() returns the raw result struct from
%   sizing/VnV/BrandtF16A/BrandtMission.run for all 14 reference segments.
%   The fields that this example uses are: segment_names, fuel_lb, time_min,
%   dist_nm, alt_ft, mach_end, pct_AB, total_fuel_lb, total_time_min.
%
%   F16AMISSIONREFERENCE(Reset=true) deletes the cached result and runs the
%   analysis again.
%
%   The result is cached because each mission-phase action requests it
%   (F16AMissionSegment is bound to all ten actions). Without the cache, each
%   model update would run ten identical analyses.
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

SIZING_POINT_LB = 31377;   % Wt!B3, the same point that the cost model uses

% /sizing/ is three levels above the example root. The guard restores the path
% when this function returns, so sizing/ does not stay on the path.
avd  = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16AMissionReference:noSizingModel", ...
        "The mission analysis is not at %s. This model calls /sizing/ for the " + ...
        "mission and does not restate the segment equations. Make sure that " + ...
        "the folder is present.", bDir);
end
oldPath = path();
guard   = onCleanup(@() path(oldPath));  % kept until this function returns
addpath(bDir);

% The argument order is (aero, eng, geom). BrandtMission is the only class in
% that folder that does not take the geometry first.
geom = BrandtGeometry();          geom.analyze();
aero = BrandtAerodynamics(geom);  aero.analyze();
eng  = BrandtEngine();            eng.analyze();
miss = BrandtMission(aero, eng, geom);

cached = miss.run(SIZING_POINT_LB);
r = cached;

end

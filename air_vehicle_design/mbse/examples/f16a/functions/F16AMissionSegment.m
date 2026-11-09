function s = F16AMissionSegment(phaseName)
%F16AMISSIONSEGMENT Return the fuel and time of one mission phase (the behaviour of each action).
%   S = F16AMISSIONSEGMENT(PHASENAME) returns the flight condition, the fuel
%   and the time for one phase of F16A_MissionActivity, for example "Cruise".
%
%   S fields: Fuel_lb, Time_min, Dist_nm, Alt_ft, Mach, PctAB.
%
%   This function is the link to the analysis. Each phase action in
%   F16A_MissionActivity has F16AMissionSegment('<its name>') as its
%   BehaviorDefinition. Thus the model records how each number is computed,
%   and does not store the number. This function does not compute the
%   numbers. They come from the /sizing/ mission analysis
%   (F16AMissionReference), which is the only location of the segment
%   equations.
%
%   See also F16AMISSIONREFERENCE, F16AMISSIONANALYSIS.

arguments
    phaseName (1,1) string
end

r     = F16AMissionReference();
names = string(r.segment_names(:));
k     = find(names == phaseName, 1);

if isempty(k)
    error("F16AMissionSegment:noSuchPhase", ...
        "The mission analysis has no segment named '%s'. Its segments are: %s.", ...
        phaseName, strjoin(names, ", "));
end

s = struct( ...
    Fuel_lb  = r.fuel_lb(k), ...
    Time_min = r.time_min(k), ...
    Dist_nm  = r.dist_nm(k), ...
    Alt_ft   = r.alt_ft(k), ...
    Mach     = r.mach_end(k), ...
    PctAB    = r.pct_AB(k));

end

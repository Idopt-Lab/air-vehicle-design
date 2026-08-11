function s = F16AMissionSegment(phaseName)
%F16AMISSIONSEGMENT What one mission phase costs. The behaviour of each action.
%   S = F16AMISSIONSEGMENT(PHASENAME) returns the flight condition and the fuel
%   and time for one phase of F16A_MissionActivity, e.g. "Cruise".
%
%   S fields: Fuel_lb, Time_min, Dist_nm, Alt_ft, Mach, PctAB.
%
%   THIS IS THE ANALYSIS LINK. Every phase action in F16A_MissionActivity
%   carries F16AMissionSegment('<its name>') as its BehaviorDefinition, so the
%   model records HOW each number is computed instead of storing the number.
%   Re-run the analysis and the model follows it.
%
%   The numbers are not computed here. They are read from the /sizing/ mission
%   analysis (F16AMissionReference); the segment equations have one home, and
%   it is not this repository's MBSE example.
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
        "The mission analysis has no segment called '%s'. It knows: %s.", ...
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

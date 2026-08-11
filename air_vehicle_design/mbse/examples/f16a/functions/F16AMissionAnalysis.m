function results = F16AMissionAnalysis()
%F16AMISSIONANALYSIS Walk the mission profile and add up the fuel and the time.
%   RESULTS = F16AMISSIONANALYSIS() runs the /sizing/ mission analysis and
%   reports what each of the ten phases of F16A_MissionActivity costs.
%
%   RESULTS fields: TotalFuel_lb, TotalTime_min, Phases, Table.
%
%   It runs as five printed steps -- name the phases, run the analysis, check
%   nothing was lost, read each phase, report -- and prints every number it
%   reads and the running total, so a reader can add the phases up by hand.
%
%   THE MODEL FLIES TEN PHASES; THE ANALYSIS WALKS FOURTEEN SEGMENTS. Step 3
%   proves the four the model omits are free -- zero fuel AND zero time -- so
%   the shorter list costs the same mission. If that ever stops being true the
%   run stops, because then the model would be flying a cheaper mission than
%   the one it claims (D-059).
%
%   Feeds MeasureOfMerit.MissionFuel_lb, and through it the cost model.
%
%   See also F16AMISSIONSEGMENT, F16AMISSIONREFERENCE, F16APHYSICALFUELROLLUP.

% ---------------------------------------------------------------------
% WHAT THIS ANALYSIS IS ABOUT. The ten phases, and the two figures to beat.
% ---------------------------------------------------------------------
PHASES      = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
               "Egress","Cruise2","Loiter","Landing"];
REF_FUEL_LB  = 6000.43;   % Miss!O9
REF_TIME_MIN = 94.06;     % Miss!O8
TOL          = 0.01;      % the +/-1% band /sizing/ holds itself to

fprintf("\n==========================================================\n");
fprintf("  MISSION FUEL ANALYSIS\n");
fprintf("  Question: how much fuel does the design mission burn?\n");
fprintf("  Backs: REQ_F16A_001-010 (the 'required' side of REQ_F16A_P01)\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- NAME THE TEN PHASES THE MODEL FLIES
% =====================================================================
fprintf("\n[STEP 1] NAME THE TEN PHASES THE MODEL FLIES\n");
fprintf("  These are the actions of F16A_MissionActivity, in flow order:\n");
fprintf("  %s\n", strjoin(PHASES, " -> "));

% =====================================================================
% STEP 2 -- RUN THE /sizing/ ANALYSIS
%
% Nothing is computed in this file. The segment equations live in
% sizing/VnV/BrandtF16A/BrandtMission.m and are CALLED, never copied -- the
% same delegation the cost model and the static-margin verification use.
% =====================================================================
fprintf("\n[STEP 2] RUN THE /sizing/ MISSION ANALYSIS\n");
r = F16AMissionReference();
allNames = string(r.segment_names(:));
fprintf("  Analysis  : sizing/VnV/BrandtF16A/BrandtMission.m\n");
fprintf("  Segments  : %d\n", numel(allNames));
fprintf("  Flown at  : 31377 lb take-off gross weight (Wt!B3)\n");

% =====================================================================
% STEP 3 -- CHECK NOTHING WAS LOST BETWEEN FOURTEEN AND TEN
%
% The model omits three zero-duration Patrol waypoints and a degenerate Climb2
% re-entry node. Omitting a segment is only honest if it is free, so each one
% is CHECKED rather than assumed.
% =====================================================================
fprintf("\n[STEP 3] CHECK THE FOUR OMITTED SEGMENTS ARE FREE\n");
omitted = allNames(~ismember(allNames, PHASES));
for nm = omitted'
    k = find(allNames == nm, 1);
    fprintf("  %s omitted -- %.1f lb, %.1f min\n", ...
        pad(nm + " ", 22, "right", "."), r.fuel_lb(k), r.time_min(k));
end
assertOmittedAreFree(r, allNames, omitted);
fprintf("\n  -> all %d cost nothing, so ten phases fly the same mission as %d.\n", ...
    numel(omitted), numel(allNames));

% =====================================================================
% STEP 4 -- READ EACH PHASE
%
% Each phase is read through F16AMissionSegment -- the very function the
% activity's actions carry as their behaviour. The walk below and the model
% therefore cannot disagree: they are the same call.
% =====================================================================
fprintf("\n[STEP 4] READ EACH PHASE, AND ADD IT UP\n");
fprintf("  %-22s %9s %9s   %s\n", "Phase", "Fuel_lb", "Time_min", "running total");
n = numel(PHASES);
[fuel, time, dist, alt, mach, ab] = deal(zeros(n,1));
total = 0;
for i = 1:n
    s = F16AMissionSegment(PHASES(i));
    fuel(i)=s.Fuel_lb; time(i)=s.Time_min; dist(i)=s.Dist_nm;
    alt(i)=s.Alt_ft;   mach(i)=s.Mach;     ab(i)=s.PctAB;
    total = total + s.Fuel_lb;
    fprintf("  %-22s %9.1f %9.2f   %9.1f lb\n", PHASES(i), s.Fuel_lb, s.Time_min, total);
end

T = table(PHASES(:), fuel, time, dist, alt, mach, ab, 'VariableNames', ...
    {'Phase','Fuel_lb','Time_min','Dist_nm','Alt_ft','Mach','PctAB'});
results = struct(TotalFuel_lb = r.total_fuel_lb, TotalTime_min = r.total_time_min, ...
                 Phases = PHASES, Table = T);

% =====================================================================
% STEP 5 -- REPORT
% =====================================================================
fprintf("\n[STEP 5] REPORT\n");
fprintf("  Mission fuel : %8.2f lb   (Miss!O9 ref %.2f, %+.2f%%)\n", ...
    r.total_fuel_lb, REF_FUEL_LB, 100*(r.total_fuel_lb/REF_FUEL_LB - 1));
fprintf("  Mission time : %8.2f min  (Miss!O8 ref %.2f, %+.2f%%)\n", ...
    r.total_time_min, REF_TIME_MIN, 100*(r.total_time_min/REF_TIME_MIN - 1));
checkAgainstReference(r, REF_FUEL_LB, REF_TIME_MIN, TOL);

% The total is BrandtMission's own, not this walk's sum. They agree here only
% because Landing burns nothing: the total excludes Landing by construction
% (BrandtMission.m:292). Saying so is cheaper than a reader discovering it.
fprintf("\n  The ten phases above sum to %.2f lb. The reported total is the\n", total);
fprintf("  analysis's own, which EXCLUDES Landing -- they agree only because\n");
fprintf("  Landing burns %.1f lb. Combat's %.0f lb weapons release is already\n", ...
    fuel(PHASES=="Landing"), 4400);
fprintf("  netted out of its fuel figure, so it is not subtracted twice.\n\n");

end

% =====================================================================
function assertOmittedAreFree(r, allNames, omitted)
%ASSERTOMITTEDAREFREE Stop if a segment the model drops has started to cost something.
for nm = omitted'
    k = find(allNames == nm, 1);
    if r.fuel_lb(k) ~= 0 || r.time_min(k) ~= 0
        error("F16AMissionAnalysis:omittedSegmentIsNotFree", ...
            "Segment '%s' is not in the model's ten phases but now costs " + ...
            "%.2f lb and %.2f min. The model would be flying a cheaper " + ...
            "mission than the one it claims -- add the phase to the activity " + ...
            "or explain the omission (D-059).", nm, r.fuel_lb(k), r.time_min(k));
    end
end
end

% =====================================================================
function checkAgainstReference(r, refFuel, refTime, tol)
%CHECKAGAINSTREFERENCE Stop if the delegation has drifted off the spreadsheet.
%   The point of calling /sizing/ is that its answer is the validated one. A
%   silent drift would leave the cost model pricing a mission nobody checked.
if abs(r.total_fuel_lb/refFuel - 1) > tol
    error("F16AMissionAnalysis:fuelOffReference", ...
        "Mission fuel is %.2f lb against Miss!O9 = %.2f lb, outside +/-%.0f%%.", ...
        r.total_fuel_lb, refFuel, 100*tol);
end
if abs(r.total_time_min/refTime - 1) > tol
    error("F16AMissionAnalysis:timeOffReference", ...
        "Mission time is %.2f min against Miss!O8 = %.2f min, outside +/-%.0f%%.", ...
        r.total_time_min, refTime, 100*tol);
end
fprintf("  Both inside the +/-%.0f%% band /sizing/ holds itself to.\n", 100*tol);
end

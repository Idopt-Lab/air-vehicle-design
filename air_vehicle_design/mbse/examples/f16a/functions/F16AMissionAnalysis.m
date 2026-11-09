function results = F16AMissionAnalysis()
%F16AMISSIONANALYSIS Add the fuel and the time of each phase of the mission profile.
%   RESULTS = F16AMISSIONANALYSIS() runs the /sizing/ mission analysis and
%   reports the fuel and time of each of the ten phases of
%   F16A_MissionActivity.
%
%   RESULTS fields: TotalFuel_lb, TotalTime_min, Phases, Table.
%
%   It prints each number that it reads and the running total, so that you
%   can add the phases by hand. It stops if a total is more than 1% different
%   from the Brandt spreadsheet that the /sizing/ analysis reproduces.
%
%   The model flies ten phases, but the analysis has fourteen segments. Step 3
%   checks that the four segments that the model omits use zero fuel and zero
%   time. F16ARunAnalyses writes the totals into the Measures of Merit of the
%   aircraft.
%
%   See also F16AMISSIONSEGMENT, F16AMISSIONREFERENCE, F16APHYSICALFUELROLLUP.

% ---------------------------------------------------------------------
% THE SUBJECT OF THIS ANALYSIS: the ten phases, and the two reference figures.
% ---------------------------------------------------------------------
PHASES      = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
               "Egress","Cruise2","Loiter","Landing"];
REF_FUEL_LB  = 6000.43;   % Miss!O9
REF_TIME_MIN = 94.06;     % Miss!O8
TOL          = 0.01;      % the +/-1% band that /sizing/ uses for itself

fprintf("\n==========================================================\n");
fprintf("  MISSION FUEL ANALYSIS\n");
fprintf("  Question: how much fuel does the design mission burn?\n");
fprintf("  Supports: REQ_F16A_001-010 (the 'required' side of REQ_F16A_P01)\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- LIST THE TEN PHASES THAT THE MODEL FLIES
% =====================================================================
fprintf("\n[STEP 1] LIST THE TEN PHASES THAT THE MODEL FLIES\n");
fprintf("  These are the actions of F16A_MissionActivity, in flow order:\n");
fprintf("  %s\n", strjoin(PHASES, " -> "));

% =====================================================================
% STEP 2 -- RUN THE /sizing/ ANALYSIS
%
% This file computes nothing. The segment equations are in
% sizing/VnV/BrandtF16A/BrandtMission.m. This file calls them and does not copy
% them. The cost model and the static-margin verification use the same method.
% =====================================================================
fprintf("\n[STEP 2] RUN THE /sizing/ MISSION ANALYSIS\n");
r = F16AMissionReference();
allNames = string(r.segment_names(:));
fprintf("  Analysis  : sizing/VnV/BrandtF16A/BrandtMission.m\n");
fprintf("  Segments  : %d\n", numel(allNames));
fprintf("  Flown at  : 31377 lb take-off gross weight (Wt!B3)\n");

% =====================================================================
% STEP 3 -- CHECK THAT NOTHING IS LOST FROM FOURTEEN SEGMENTS TO TEN PHASES
%
% The model omits three zero-duration Patrol waypoints and a degenerate Climb2
% re-entry node. It is correct to omit a segment only if the segment uses no
% fuel and no time. Thus the code checks each omitted segment, and does not
% assume this.
% =====================================================================
fprintf("\n[STEP 3] CHECK THAT THE FOUR OMITTED SEGMENTS USE NO FUEL OR TIME\n");
omitted = allNames(~ismember(allNames, PHASES));
for nm = omitted'
    k = find(allNames == nm, 1);
    fprintf("  %s omitted: %.1f lb, %.1f min\n", ...
        pad(nm + " ", 22, "right", "."), r.fuel_lb(k), r.time_min(k));
end
assertOmittedAreFree(r, allNames, omitted);
fprintf("\n  -> All %d use no fuel or time. Thus the ten phases fly the same mission as the %d segments.\n", ...
    numel(omitted), numel(allNames));

% =====================================================================
% STEP 4 -- READ EACH PHASE
%
% The code reads each phase through F16AMissionSegment. This is the same
% function that the actions of the activity have as their behaviour. Thus the
% loop below and the model cannot disagree, because they use the same call.
% =====================================================================
fprintf("\n[STEP 4] READ EACH PHASE AND ADD IT TO THE TOTAL\n");
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

% The total comes from BrandtMission, and it does not include Landing. It
% agrees with the sum of this loop only because Landing burns no fuel.
fprintf("\n  The sum of the ten phases above is %.2f lb. The reported total comes\n", total);
fprintf("  from the analysis, and it does not include Landing. The two values agree\n");
fprintf("  only because Landing burns %.1f lb. The fuel figure of Combat already\n" + ...
    "  includes the effect of its %.0f lb weapons release, so the release is\n", ...
    fuel(PHASES=="Landing"), 4400);
fprintf("  not subtracted twice.\n\n");

end

% =====================================================================
function assertOmittedAreFree(r, allNames, omitted)
%ASSERTOMITTEDAREFREE Stop if a segment that the model omits now uses fuel or time.
for nm = omitted'
    k = find(allNames == nm, 1);
    if r.fuel_lb(k) ~= 0 || r.time_min(k) ~= 0
        error("F16AMissionAnalysis:omittedSegmentIsNotFree", ...
            "Segment '%s' is not one of the ten phases of the model, but it now " + ...
            "uses %.2f lb and %.2f min. Thus the model flies a mission that uses " + ...
            "less fuel and time than the mission that it claims. Add the phase " + ...
            "to the activity.", ...
            nm, r.fuel_lb(k), r.time_min(k));
    end
end
end

% =====================================================================
function checkAgainstReference(r, refFuel, refTime, tol)
%CHECKAGAINSTREFERENCE Stop if the /sizing/ result is no longer within tolerance of the spreadsheet.
%   This code calls /sizing/ because its answer is validated. If the result
%   changed without a warning, the cost model would calculate the cost of a
%   mission that nobody checked.
if abs(r.total_fuel_lb/refFuel - 1) > tol
    error("F16AMissionAnalysis:fuelOffReference", ...
        "Mission fuel is %.2f lb. Miss!O9 is %.2f lb. The difference is more than +/-%.0f%%.", ...
        r.total_fuel_lb, refFuel, 100*tol);
end
if abs(r.total_time_min/refTime - 1) > tol
    error("F16AMissionAnalysis:timeOffReference", ...
        "Mission time is %.2f min. Miss!O8 is %.2f min. The difference is more than +/-%.0f%%.", ...
        r.total_time_min, refTime, 100*tol);
end
fprintf("  Both values are inside the +/-%.0f%% band that /sizing/ uses for itself.\n", 100*tol);
end

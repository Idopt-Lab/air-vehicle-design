function requiredFuel_lb = F16APhysicalMissionFuel()
%F16APHYSICALMISSIONFUEL Fuel required to fly the design mission.
%   REQUIREDFUEL_LB = F16APHYSICALMISSIONFUEL() returns the total fuel (lb)
%   needed to complete the F-16A design mission profile (REQ_F16A_001-010).
%
%   This is the "required" side of REQ_F16A_P01 (fuel volume sufficiency);
%   the "available" side is F16APhysicalFuelRollup. The verify test checks
%   available >= required.
%
%   It READS MeasureOfMerit.MissionFuel_lb off the model rather than re-running
%   the analysis, which is what makes it symmetric with the available side:
%   both ask the model, and the model is what section 9c wrote (D-059).
%
%   It returned NaN by design until D-060. The example now carries a mission
%   the model can actually fly, so the requirement is answered rather than
%   permanently pending -- see the decision log for what that cost.
%
%   See also F16APHYSICALFUELROLLUP, F16AMISSIONANALYSIS.

MODEL   = "F16A_Physical";
PROFILE = "F16A_PhysicalProps";

root = f16aRoot();
addpath(fullfile(root, "physical"));
m = systemcomposer.loadModel(MODEL);

aircraft = lookup(m, Path=char(MODEL + "/Aircraft"));
requiredFuel_lb = str2double(string(getProperty(aircraft, ...
    char(PROFILE + ".MeasureOfMerit.MissionFuel_lb"))));

% An unset Measure of Merit must not read as a mission that burns nothing --
% that would make REQ_F16A_P01 pass for the worst possible reason (D-021).
if ~isfinite(requiredFuel_lb) || requiredFuel_lb <= 0
    error("F16APhysicalMissionFuel:missionNotAnalysed", ...
        "MissionFuel_lb on the aircraft is %s. The mission has not been " + ...
        "analysed into this model, so the required side of REQ_F16A_P01 " + ...
        "cannot be evaluated -- run generate_f16a_physical (section 9c).", ...
        string(num2str(requiredFuel_lb)));
end

end

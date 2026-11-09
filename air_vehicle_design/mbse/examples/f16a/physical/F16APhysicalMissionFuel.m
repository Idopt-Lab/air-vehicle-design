function requiredFuel_lb = F16APhysicalMissionFuel()
%F16APHYSICALMISSIONFUEL Return the fuel that is required to fly the design mission.
%   REQUIREDFUEL_LB = F16APHYSICALMISSIONFUEL() returns the total fuel (lb)
%   that is necessary to complete the F-16A design mission profile
%   (REQ_F16A_001-010).
%
%   This value is the "required" side of REQ_F16A_P01 (fuel volume
%   sufficiency). The "available" side is F16APhysicalFuelRollup. The
%   verification test checks that available >= required.
%
%   It reads MeasureOfMerit.MissionFuel_lb from the model, and does not run
%   the analysis again. Thus both sides of the check get their values from
%   the model. F16ARunAnalyses writes the value into the model.
%
%   See also F16APHYSICALFUELROLLUP, F16AMISSIONANALYSIS.

MODEL   = "F16A_Physical";
PROFILE = "F16A_PhysicalProps";

m = systemcomposer.loadModel(MODEL);

aircraft = lookup(m, Path=char(MODEL + "/Aircraft"));
requiredFuel_lb = str2double(string(getProperty(aircraft, ...
    char(PROFILE + ".MeasureOfMerit.MissionFuel_lb"))));

% An unset Measure of Merit must not read as a mission that burns no fuel.
% That result would make REQ_F16A_P01 pass for the worst possible reason.
if ~isfinite(requiredFuel_lb) || requiredFuel_lb <= 0
    error("F16APhysicalMissionFuel:missionNotAnalysed", ...
        "MissionFuel_lb on the aircraft is %s. The mission analysis has not " + ...
        "written its result into this model, so the required side of " + ...
        "REQ_F16A_P01 cannot be evaluated. Run F16ARunAnalyses.", ...
        string(num2str(requiredFuel_lb)));
end

end

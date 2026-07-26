function requiredFuel_lb = F16APhysicalMissionFuel()
%F16APHYSICALMISSIONFUEL Fuel required to fly the design mission (stub).
%   REQUIREDFUEL_LB = F16APHYSICALMISSIONFUEL() returns the total fuel (lb)
%   needed to complete the F-16A design mission profile (REQ_F16A_001-010):
%   the sum of the segment fuel burns from a mission analysis.
%
%   This is the "required" side of REQ_F16A_P01 (fuel volume sufficiency);
%   the "available" side is F16APhysicalFuelRollup. The verify test checks
%   available >= required.
%
%   STATUS: STUB. Returns NaN ("not yet computed") on purpose -- we do not
%   invent a mission-fuel number. It will be connected to the mission /
%   sizing analysis in /sizing/ (e.g. the Brandt mission model, which burns
%   each segment and sums the fuel). Until then the comparison is NaN and the
%   verify test FAILS -- an honest, traceable "verification pending" marker.

% TODO: connect to the mission analysis in /sizing/ (e.g. BrandtMission) to
% sum the design-mission segment fuel burns and return required fuel in lb.
requiredFuel_lb = NaN;

end

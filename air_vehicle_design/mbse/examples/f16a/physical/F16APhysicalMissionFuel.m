function requiredFuel_lb = F16APhysicalMissionFuel()
%F16APHYSICALMISSIONFUEL Fuel required to fly the design mission (NaN by design).
%   REQUIREDFUEL_LB = F16APHYSICALMISSIONFUEL() returns the total fuel (lb)
%   needed to complete the F-16A design mission profile (REQ_F16A_001-010).
%
%   This is the "required" side of REQ_F16A_P01 (fuel volume sufficiency);
%   the "available" side is F16APhysicalFuelRollup. The verify test checks
%   available >= required.
%
%   IT RETURNS NaN BY DESIGN (D-042), permanently. No mission-fuel number is
%   invented here, so available (6300) >= NaN is false and
%   F16AFuelVerificationTest FAILS -- and the RED TEST IS THE DELIVERABLE: it
%   is the example's only "verification set up, traceable, not yet satisfied"
%   marker, the state a real programme lives in for most of its life. Wiring
%   this to the mission analysis in /sizing/ would turn it green and teach the
%   opposite lesson, so it is NOT wired, now or later.
%
%   THIS IS NOT A STUB AND NOT A TODO. D-042 lists it under "not TODOs" so
%   that a future sweep does not "finish" it.
%
%   See also F16APHYSICALFUELROLLUP.

requiredFuel_lb = NaN;

end

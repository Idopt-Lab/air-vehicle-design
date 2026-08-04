function requiredFuel_lb = F16APhysicalMissionFuel()
%F16APHYSICALMISSIONFUEL Fuel required to fly the design mission (NaN by design).
%   REQUIREDFUEL_LB = F16APHYSICALMISSIONFUEL() returns the total fuel (lb)
%   needed to complete the F-16A design mission profile (REQ_F16A_001-010).
%
%   This is the "required" side of REQ_F16A_P01 (fuel volume sufficiency);
%   the "available" side is F16APhysicalFuelRollup. The verify test checks
%   available >= required.
%
%   IT RETURNS NaN BY DESIGN (D-042), permanently -- NOT a stub and NOT a TODO.
%   Nothing is computed, so available >= NaN is false and
%   F16AFuelVerificationTest fails. The RED TEST IS THE DELIVERABLE: it is the
%   example's "verification set up, traceable, not yet satisfied" state, which
%   a real programme lives in for most of its life. Wiring this to /sizing/
%   would turn it green and teach the opposite lesson.
%
%   See also F16APHYSICALFUELROLLUP.

requiredFuel_lb = NaN;

end

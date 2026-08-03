function generate_f16a_physical_derived_requirements()
%GENERATE_F16A_PHYSICAL_DERIVED_REQUIREMENTS Build the F-16A physical-layer requirements.
%   Creates requirements/f16a_physical_derived.slreqx with the requirements
%   surfaced and VERIFIED at the Physical layer (RFLP "P") -- ones that only
%   make sense once the aircraft has concrete parts to measure. A separate
%   set, alongside f16a_functional_derived.slreqx and
%   f16a_logical_derived.slreqx; the sizing-derived f16a.slreqx stays
%   pristine.
%
%     REQ_F16A_P01  Fuel volume sufficiency. Verified by comparing a roll-up
%                   of available fuel capacity against a mission-analysis
%                   estimate of required fuel (F16AFuelVerificationTest).
%
%   That test FAILS by design and permanently: F16APhysicalMissionFuel
%   returns NaN by design (D-042). The red test IS the teaching artifact --
%   verification that is set up, traceable and not yet satisfied -- not a
%   gap awaiting closure.
%
%   Idempotent: re-run to regenerate from scratch.

thisDir = fileparts(mfilename("fullpath"));
reqFile = fullfile(thisDir, "f16a_physical_derived.slreqx");

slreq.clear();
if isfile(reqFile); delete(reqFile); end
rs = slreq.new(fullfile(thisDir, "f16a_physical_derived"));
rs.Description = "Requirements owned and verified at the Physical layer (RFLP P) of the F-16A model. Kept separate from the sizing-derived set (f16a.slreqx), the functional-derived set, and the logical-derived set.";

% ---- Root container ----
root = add(rs, Id="REQ_F16A_PHYSICAL", Summary="F-16A physical-layer requirements", ...
    Description="Root container for requirements surfaced and verified at the Physical layer, where concrete parts and roll-up analyses exist to measure them.");
root.Type = "Container";
root.Keywords = ["draft","derived","physical"];

% ---- P01: Fuel volume sufficiency ----
% No "verify"/"todo" keyword: the Verify link is the record that a
% requirement has a test (D-048).
r = add(root, Id="REQ_F16A_P01", Summary="Fuel volume sufficiency", ...
    Description="The aircraft shall provide sufficient internal fuel tankage (volume, expressed as fuel-weight capacity) to carry the fuel required to complete the design mission profile (REQ_F16A_001-010), without reliance on external tanks. Verification method: the total available fuel capacity (a roll-up over the internal fuel tanks) shall be greater than or equal to the mission fuel required (from mission analysis).");
r.Rationale = "Range/endurance closure depends on carrying enough fuel, and the check belongs at P because it needs concrete tanks to roll up an available capacity from. The mission-fuel side is NaN BY DESIGN (D-042), so this verification is permanently pending and its test fails by design -- a requirement that is traceable and not yet satisfied, which is the state a real programme lives in for most of its life. Do not read the failing test as work outstanding.";
r.Keywords = ["draft","derived","physical"];

save(rs);
fprintf("Saved f16a_physical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

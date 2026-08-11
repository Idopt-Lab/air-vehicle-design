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
%                   of available fuel capacity against the mission fuel the
%                   /sizing/ analysis computes (F16AFuelVerificationTest).
%     REQ_F16A_P02  Life-cycle cost. Answered by MeasureOfMerit.
%                   LifeCycleCost_USD, which only exists once the mission is
%                   real -- fuel burn is its only mission input (D-061).
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
r.Rationale = "Range/endurance closure depends on carrying enough fuel, and the check belongs at P because it needs concrete tanks to roll up an available capacity from. Both sides are now real numbers: the tanks roll up to 6300 lb and the mission analysis burns about 5960 lb, so the requirement is met with roughly 340 lb of margin (D-060).";
r.Keywords = ["draft","derived","physical"];

% ---- P02: Life-cycle cost ----
% It POSES the question and does not answer it. No cap is stated: this example
% has no sourced affordability target, and inventing one would be inventing a
% requirement (D-037, D-045).
r2 = add(root, Id="REQ_F16A_P02", Summary="Life-cycle cost", ...
    Description="The aircraft's life-cycle cost -- unit flyaway cost plus operating and support cost over the service life -- shall be quantified for the design mission profile (REQ_F16A_001-010). Verification method: MeasureOfMerit.LifeCycleCost_USD on the aircraft, computed by F16APhysicalCostModel from this model's rolled-up empty weight and its mission fuel and sortie time. No cost ceiling is stated: no sourced affordability target exists for this example, and inventing one would be inventing a requirement.");
r2.Rationale = "Mission fuel reaches cost through exactly one path -- the operating and support terms -- so life-cycle cost is the only Measure of Merit that moves when the mission changes; the unit flyaway does not (D-043, D-061). Without this requirement LifeCycleCost_USD would sit on the aircraft traced to nothing. Cross-check: BrandtCost's own life-cycle figure is about $93.26M.";
r2.Keywords = ["draft","derived","physical"];

save(rs);
fprintf("Saved f16a_physical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

function generate_f16a_physical_derived_requirements()
%GENERATE_F16A_PHYSICAL_DERIVED_REQUIREMENTS Build the F-16A physical-layer requirements.
%   Creates requirements/f16a_physical_derived.slreqx with requirements that
%   are surfaced and VERIFIED at the Physical layer (RFLP "P") -- ones that
%   only make sense once the aircraft has concrete parts to measure.
%
%   Requirements:
%     REQ_F16A_P01  Fuel volume sufficiency -- enough internal tankage to
%                   carry the mission fuel. Verified by comparing a roll-up
%                   of available fuel capacity against a mission-analysis
%                   estimate of required fuel (F16APhysicalVerificationTest).
%
%   This is the first requirement in the project with a "verified by" test
%   relationship: a unit test computes both sides and checks the requirement
%   is met. The mission-fuel side is a stub (NaN) until the /sizing/ analysis
%   is connected, so that test is expected to FAIL for now -- an honest,
%   traceable "verification pending" marker rather than a hidden gap.
%
%   The original f16a.slreqx is kept pristine (Excel-input provenance only);
%   this is a separate set for requirements owned at the Physical layer,
%   alongside f16a_functional_derived.slreqx and f16a_logical_derived.slreqx.
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
r = add(root, Id="REQ_F16A_P01", Summary="Fuel volume sufficiency", ...
    Description="The aircraft shall provide sufficient internal fuel tankage (volume, expressed as fuel-weight capacity) to carry the fuel required to complete the design mission profile (REQ_F16A_001-010), without reliance on external tanks. Verification method: the total available fuel capacity (a roll-up over the internal fuel tanks) shall be greater than or equal to the mission fuel required (from mission analysis).");
r.Rationale = "Range/endurance closure depends on carrying enough fuel. This is verified at the Physical layer because it needs concrete tanks (to roll up available capacity) and a mission-fuel estimate to compare against. The mission-fuel estimate is currently a stub (NaN) pending connection to the sizing mission analysis in /sizing/, so verification is intentionally pending (the verify test fails until the analysis is wired in).";
r.Keywords = ["draft","derived","physical","verify","todo"];

save(rs);
fprintf("Saved f16a_physical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

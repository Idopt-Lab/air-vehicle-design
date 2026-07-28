function generate_f16a_logical_derived_requirements()
%GENERATE_F16A_LOGICAL_DERIVED_REQUIREMENTS Build the F-16A logical decision requirements.
%   Creates requirements/f16a_logical_derived.slreqx with the DESIGN
%   DECISION requirements for the three Logical-layer (RFLP "L") roles that
%   have more than one credible solution option. Where the Functional layer
%   says WHAT the aircraft must do, the Logical layer enumerates HOW it
%   could be done -- it presents the options but does NOT pick between
%   them. The pick is made one layer down, by the Physical-layer trade
%   study over concrete parameterized candidates, and is recorded here as a
%   decision requirement so the model can always answer "why this option,
%   and not the alternative?".
%
%   Decision requirements (one per variant role, see generate_f16a_logical.m
%   for the options and physical/F16APhysicalTradeStudy.m for the decision):
%     REQ_F16A_L01  Propulsion       -> single-engine (P&W F100)
%     REQ_F16A_L02  Flight control   -> analog fly-by-wire
%     REQ_F16A_L03  Airframe/wing    -> blended cranked-delta + LERX
%
%   The selected option (the active variant choice at L) is Implement-linked
%   to its decision requirement by the PHYSICAL trade study, and the
%   Rationale field below records the weighted-score result that justified
%   the pick. This requirement -- not the variant flag -- is where the
%   decision is authoritatively recorded; the L model's active variant is a
%   derived artifact, written back by the trade and unresolved until the
%   trade has run. The alternatives are NOT deleted -- they stay in the
%   model as the options that were traded.
%
%   The original f16a.slreqx is kept pristine (Excel-input provenance only)
%   and the functional-derived set (f16a_functional_derived.slreqx) is left
%   untouched; this is a THIRD, separate set, holding the decisions recorded
%   against the L roles.
%
%   Idempotent: re-run to regenerate from scratch. Any existing
%   f16a_logical_derived.slreqx (and its in-memory copy) is cleared first.

% Save into this script's own requirements/ folder, independent of pwd.
thisDir = fileparts(mfilename("fullpath"));
reqFile = fullfile(thisDir, "f16a_logical_derived.slreqx");

% Idempotent clean rebuild: drop any in-memory copy and the existing file
% so slreq.new does not error on an already-existing set.
slreq.clear();
if isfile(reqFile); delete(reqFile); end
rs = slreq.new(fullfile(thisDir, "f16a_logical_derived"));
rs.Description = "Design-decision requirements for the F-16A logical roles: recorded at the Logical layer (RFLP L) as the design decisions those roles embody, but DECIDED by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores concrete parameterized candidates. L presents the options; P picks. Each requirement records which solution option was selected to realize a role, and why. Kept separate from the sizing-derived set (f16a.slreqx) and the functional-derived set (f16a_functional_derived.slreqx).";

% ---- Root container ----
root = add(rs, Id="REQ_F16A_LOGICAL", Summary="F-16A logical design decisions", ...
    Description="Root container for the design decisions recorded against the Logical-layer roles. Each captures the selected option for a role that had multiple credible alternatives, with the rationale from the Physical-layer trade study that decided it.");
root.Type = "Container";
root.Keywords = ["draft","derived","logical","decision"];

% ---- L01: Propulsion architecture ----
r = add(root, Id="REQ_F16A_L01", Summary="Propulsion: single-engine selection", ...
    Description="The PropulsionSystem role shall be realized by a single afterburning turbofan (Pratt & Whitney F100 class), rather than a twin-engine installation. This is the production F-16A configuration and the outcome of the Lightweight Fighter (YF-16 vs YF-17) trade.");
r.Rationale = "Decided by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores concrete parameterized engine candidates -- three of them: two single-engine and one twin-engine installation -- not numbers carried on the logical role. Score = weighted sum of declared value functions (Benefit/10, (TRL-1)/8, M_baseline/M against the role's Brandt baseline mass) with weights 0.50 / 0.25 / 0.25; unit cost is a pending Measure of Merit, left at NaN and excluded, with the remaining weights renormalized over the criteria that do have values -- so the classic single-vs-twin cost argument is stated here, not scored. The winning candidate takes the trade on technology readiness and installed mass DESPITE a mid-pack benefit score: this decision is carried by maturity and weight, not by raw capability, and it accepts lower engine-out survivability than a twin installation. The alternative (TwinEngine) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L02: Flight control architecture ----
r = add(root, Id="REQ_F16A_L02", Summary="Flight control: analog fly-by-wire selection", ...
    Description="The FlightControlSystem role shall be realized by a (quad-redundant) analog fly-by-wire system enabling relaxed static stability, rather than a conventional hydro-mechanical control system. The F-16A was the first production fighter to fly a fly-by-wire flight control system.");
r.Rationale = "Decided by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores concrete parameterized flight-control candidates, not numbers carried on the logical role. Score = weighted sum of declared value functions (Benefit/10, (TRL-1)/8, M_baseline/M against the role's Brandt baseline mass) with weights 0.50 / 0.25 / 0.25; unit cost is a pending Measure of Merit, left at NaN and excluded, with the remaining weights renormalized over the criteria that do have values -- so the higher acquisition cost of fly-by-wire is recorded here rather than scored. The fly-by-wire candidate wins on maneuver/agility benefit (it unlocks relaxed static stability and the associated turn performance) and on control-system mass, outweighing its lower technology readiness relative to hydro-mechanical linkages; it realizes the FlyByWire kind at L. The alternative (HydroMechanical) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L03: Airframe / wing planform ----
r = add(root, Id="REQ_F16A_L03", Summary="Airframe: blended cranked-delta wing selection", ...
    Description="The Airframe role shall be realized by a cropped/cranked-delta blended wing-body with leading-edge root extensions (LERX), rather than a conventional trapezoidal wing on a discrete fuselage. This is the production F-16A configuration.");
r.Rationale = "Decided by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores concrete parameterized airframe candidates, not numbers carried on the logical role. Score = weighted sum of declared value functions (Benefit/10, (TRL-1)/8, M_baseline/M against the role's Brandt baseline mass) with weights 0.50 / 0.25 / 0.25; unit cost is a pending Measure of Merit, left at NaN and excluded, with the remaining weights renormalized over the criteria that do have values -- so the higher aero-development cost of the blended configuration is recorded here rather than scored. The blended cranked-delta candidate wins on high-alpha / sustained-turn benefit and on structural efficiency (a lighter structure relative to the role's baseline mass), outweighing its lower technology readiness relative to a conventional trapezoidal wing on a discrete fuselage. The alternative (ConventionalTrapWing) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

save(rs);
fprintf("Saved f16a_logical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

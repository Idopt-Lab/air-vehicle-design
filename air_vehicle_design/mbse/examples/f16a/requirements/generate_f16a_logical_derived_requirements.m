function generate_f16a_logical_derived_requirements()
%GENERATE_F16A_LOGICAL_DERIVED_REQUIREMENTS Build the F-16A logical decision requirements.
%   Creates requirements/f16a_logical_derived.slreqx: one DESIGN DECISION
%   requirement per Logical-layer (RFLP "L") role that has more than one
%   credible solution option. A third set, separate from the sizing-derived
%   f16a.slreqx and from f16a_functional_derived.slreqx.
%
%     REQ_F16A_L01  PropulsionSystem     SingleEngine        or TwinEngine
%     REQ_F16A_L02  FlightControlSystem  FlyByWire           or HydroMechanical
%     REQ_F16A_L03  Airframe             BlendedCrankedDelta or ConventionalTrapWing
%
%   Each POSES its decision and names where the answer is recorded; none
%   contains the answer -- no winner, no vendor, no weight, no score
%   (D-037, D-040). The verdict lives at P, carried by the winning
%   candidate's Rationale.Justification and by the Implement link that
%   physical/F16APhysicalTradeStudy.m creates; until that trade runs these
%   three are correctly un-implemented (D-019).
%
%   Idempotent: re-run to regenerate from scratch.

% Save into this script's own requirements/ folder, independent of pwd.
thisDir = fileparts(mfilename("fullpath"));
reqFile = fullfile(thisDir, "f16a_logical_derived.slreqx");

% Clean rebuild so slreq.new does not error on an existing set.
slreq.clear();
if isfile(reqFile); delete(reqFile); end
rs = slreq.new(fullfile(thisDir, "f16a_logical_derived"));
rs.Description = "Design-decision requirements for the three F-16A logical roles whose realization is undecided. A role with more than one credible realization is an open question rather than a settled part (D-002): the question is recorded at L, and the decision is taken at P, where the candidates carry numbers (D-001). The Physical-layer trade study (physical/F16APhysicalTradeStudy.m) scores concrete parameterized candidates and answers all three.";

% ---- Root container. The framing shared by all three decisions is stated
% here, once, so each requirement below carries only what is specific to it.
root = add(rs, Id="REQ_F16A_LOGICAL", Summary="F-16A logical design decisions", ...
    Description="Root container for the design decisions posed against the Logical-layer roles. Each names a role with more than one credible solution option, the kinds presented for it, and the Physical-layer trade study that decides between them. The answer is read from the Implement link the trade creates into the requirement from the winning kind in logical/F16A_Logical.slx, and from that winner's Rationale.Justification in physical/F16A_Physical.slx. No weight, score or winner appears in any requirement here by construction: the applied weights are derived at run time (D-026), and this set is generated before the trade runs, so any outcome stated here would be a claim rather than a record (D-037, D-040).");
root.Type = "Container";
root.Keywords = ["draft","derived","logical","decision"];

% ---- L01: Propulsion architecture ----
r = add(root, Id="REQ_F16A_L01", Summary="Propulsion: single-engine or twin-engine installation?", ...
    Description="The PropulsionSystem role shall be realized by exactly one of the kinds the Logical layer presents for it -- SingleEngine or TwinEngine. The choice is made by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores the concrete parameterized engine candidates realizing each kind. This requirement poses the decision and does not contain its answer (D-040).");
r.Rationale = "It is worth posing rather than assuming because a twin installation buys engine-out survivability, while a single installation avoids the installed mass and complexity of a duplicated engine and accessory group.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L02: Flight control architecture ----
r = add(root, Id="REQ_F16A_L02", Summary="Flight control: fly-by-wire or hydro-mechanical?", ...
    Description="The FlightControlSystem role shall be realized by exactly one of the kinds the Logical layer presents for it -- FlyByWire or HydroMechanical. The choice is made by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores the concrete parameterized flight-control candidates realizing each kind. This requirement poses the decision and does not contain its answer (D-040).");
r.Rationale = "It is worth posing rather than assuming because only a control system able to supply artificial stability makes the negative static margin REQ_F16A_025 requires flyable.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L03: Airframe / wing planform ----
r = add(root, Id="REQ_F16A_L03", Summary="Airframe: blended cranked-delta or conventional trapezoidal wing?", ...
    Description="The Airframe role shall be realized by exactly one of the kinds the Logical layer presents for it -- BlendedCrankedDelta or ConventionalTrapWing. The choice is made by the Physical-layer trade study (physical/F16APhysicalTradeStudy.m), which scores the concrete parameterized airframe candidates realizing each kind. This requirement poses the decision and does not contain its answer (D-040).");
r.Rationale = "It is worth posing rather than assuming because a blended cranked-delta planform buys high-alpha and sustained-turn performance, while a conventional trapezoidal wing is a better-understood shape carrying less aerodynamic development risk.";
r.Keywords = ["draft","derived","logical","decision"];

save(rs);
fprintf("Saved f16a_logical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

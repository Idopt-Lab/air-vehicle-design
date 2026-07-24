function generate_f16a_logical_derived_requirements()
%GENERATE_F16A_LOGICAL_DERIVED_REQUIREMENTS Build the F-16A logical decision requirements.
%   Creates requirements/f16a_logical_derived.slreqx with the DESIGN
%   DECISION requirements produced by the Logical-layer (RFLP "L") trade
%   studies. Where the Functional layer says WHAT the aircraft must do,
%   the Logical layer chooses HOW -- and for the three roles that have
%   more than one credible solution (options, plural), a trade study picks
%   one. Each pick is recorded here as a decision requirement so the model
%   can always answer "why this option, and not the alternative?".
%
%   Decision requirements (one per variant role, see generate_f16a_logical.m
%   and F16ALogicalTradeStudy.m):
%     REQ_F16A_L01  Propulsion       -> single-engine (P&W F100)
%     REQ_F16A_L02  Flight control   -> analog fly-by-wire
%     REQ_F16A_L03  Airframe/wing    -> blended cranked-delta + LERX
%
%   The selected option (the active variant choice) is Implement-linked to
%   its decision requirement by the trade study. The Rationale field records
%   the weighted-score result that justified the pick. The alternatives are
%   NOT deleted -- they stay in the model as the choices that were traded.
%
%   The original f16a.slreqx is kept pristine (Excel-input provenance only)
%   and the functional-derived set (f16a_functional_derived.slreqx) is left
%   untouched; this is a THIRD, separate set for decisions made at L.
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
rs.Description = "Design-decision requirements for the F-16A, produced by the Logical-layer (RFLP L) trade studies. Each records which solution option was selected to realize a role, and why. Kept separate from the sizing-derived set (f16a.slreqx) and the functional-derived set (f16a_functional_derived.slreqx).";

% ---- Root container ----
root = add(rs, Id="REQ_F16A_LOGICAL", Summary="F-16A logical design decisions", ...
    Description="Root container for design-decision requirements produced at the Logical layer. Each captures the selected option for a role that had multiple credible alternatives, with the trade-study rationale.");
root.Type = "Container";
root.Keywords = ["draft","derived","logical","decision"];

% ---- L01: Propulsion architecture ----
r = add(root, Id="REQ_F16A_L01", Summary="Propulsion: single-engine selection", ...
    Description="The PropulsionSystem role shall be realized by a single afterburning turbofan (Pratt & Whitney F100 class), rather than a twin-engine installation. This is the production F-16A configuration and the outcome of the Lightweight Fighter (YF-16 vs YF-17) trade.");
r.Rationale = "Logical-layer trade study (F16ALogicalTradeStudy): the single-engine option wins the weighted score by dominating on unit cost, installed weight, and technology readiness, accepting lower engine-out survivability than the twin-engine alternative. The alternative (TwinEngine_LWF) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L02: Flight control architecture ----
r = add(root, Id="REQ_F16A_L02", Summary="Flight control: analog fly-by-wire selection", ...
    Description="The FlightControlSystem role shall be realized by a (quad-redundant) analog fly-by-wire system enabling relaxed static stability, rather than a conventional hydro-mechanical control system. The F-16A was the first production fighter to fly a fly-by-wire flight control system.");
r.Rationale = "Logical-layer trade study (F16ALogicalTradeStudy): the fly-by-wire option wins the weighted score on maneuver/agility benefit (it unlocks relaxed static stability and the associated turn performance) and control-system weight, outweighing its lower technology readiness and higher cost relative to the hydro-mechanical alternative. The alternative (HydroMechanical) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

% ---- L03: Airframe / wing planform ----
r = add(root, Id="REQ_F16A_L03", Summary="Airframe: blended cranked-delta wing selection", ...
    Description="The Airframe role shall be realized by a cropped/cranked-delta blended wing-body with leading-edge root extensions (LERX), rather than a conventional trapezoidal wing on a discrete fuselage. This is the production F-16A configuration.");
r.Rationale = "Logical-layer trade study (F16ALogicalTradeStudy): the blended cranked-delta option wins the weighted score on high-alpha / sustained-turn benefit and structural efficiency (lower structural weight fraction), outweighing its lower technology readiness and higher aero-development cost relative to the conventional-wing alternative. The alternative (ConventionalTrapWing) is retained in the model as the traded option.";
r.Keywords = ["draft","derived","logical","decision"];

save(rs);
fprintf("Saved f16a_logical_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

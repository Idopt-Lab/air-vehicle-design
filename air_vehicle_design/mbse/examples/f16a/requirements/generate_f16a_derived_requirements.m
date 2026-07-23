function generate_f16a_derived_requirements()
%GENERATE_F16A_DERIVED_REQUIREMENTS Build the F-16A derived functional requirements set.
%   Creates requirements/f16a_functional_derived.slreqx with DRAFT
%   PLACEHOLDER requirements identified during the Functional-layer (RFLP
%   "F") analysis. These capture aircraft functions that are required to
%   complete the mission -- Aviate (maneuver, fuel management), Navigate,
%   Communicate, and the F2T2EA kill-chain sub-functions (Find, Fix,
%   Track, Target, Assess) -- but that are NOT present in the
%   sizing-derived requirement set (f16a.slreqx).
%
%   The original f16a.slreqx is kept pristine (Excel-input provenance
%   only). This separate set documents the RFLP story: functional
%   decomposition surfaces needs the initial requirements did not capture,
%   which are then recorded as DERIVED requirements and linked back to the
%   functions that implement them (see generate_f16a_functional.m).
%
%   Quantitative acceptance criteria are intentionally left as TBD
%   placeholders for the program/class to define.
%
%   Re-run to regenerate.

rs = slreq.new("f16a_functional_derived");
rs.Description = "Derived functional/capability requirements for the F-16A, identified during Functional-layer (RFLP F) analysis. PLACEHOLDER values - quantitative acceptance criteria to be defined. Kept separate from the sizing-derived set (f16a.slreqx) to preserve original provenance.";

% ---- Root container ----
root = add(rs, Id="REQ_F16A_DERIVED", Summary="F-16A derived functional requirements (placeholders)", ...
    Description="Root container for functional requirements derived during RFLP Functional-layer analysis. Each captures an aircraft function required to complete the mission that is not covered by the sizing-derived requirement set. Values are PLACEHOLDER (TBD).");
root.Type = "Container";
root.Keywords = ["draft","derived","placeholder"];

% ---- Aviate: maneuver + fuel ----
r = add(root, Id="REQ_F16A_D01", Summary="Maneuvering capability", ...
    Description="The aircraft shall provide maneuvering capability (attitude and flight-path control) sufficient to fly the mission profile and combat maneuvers. PLACEHOLDER: quantitative criteria TBD (e.g. roll rate, sustained/instantaneous turn rate, control authority across the flight envelope).");
r.Rationale = "Derived from functional analysis: the Maneuver function is required to execute the mission profile and F2T2EA engagement but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

r = add(root, Id="REQ_F16A_D02", Summary="Fuel management", ...
    Description="The aircraft shall manage onboard fuel (storage, sequencing, feed, and transfer) to complete the mission profile with the required reserves. PLACEHOLDER: quantitative criteria TBD (usable fuel, feed sequencing, CG-neutral transfer).");
r.Rationale = "Derived from functional analysis: the ManageFuel function is required to complete the mission profile but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

% ---- Navigate ----
r = add(root, Id="REQ_F16A_D03", Summary="Navigation", ...
    Description="The aircraft shall determine its position and follow the planned mission route. PLACEHOLDER: quantitative criteria TBD (position accuracy, waypoint tracking, route-following tolerance).");
r.Rationale = "Derived from functional analysis: the Navigate function is required to fly the mission route but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

% ---- Communicate ----
r = add(root, Id="REQ_F16A_D04", Summary="Communication and identification", ...
    Description="The aircraft shall exchange voice and data communications and identify friend or foe (IFF). PLACEHOLDER: quantitative criteria TBD (datalink availability, communication range, IFF interrogation/response).");
r.Rationale = "Derived from functional analysis: the Communicate function is required to operate in a networked battlespace but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

% ---- F2T2EA kill-chain sub-functions (Engage already traces to REQ_F16A_021) ----
r = add(root, Id="REQ_F16A_D05", Summary="Find targets", ...
    Description="The aircraft shall detect potential targets within the combat area. PLACEHOLDER: quantitative criteria TBD (detection range, sensor field of regard).");
r.Rationale = "Derived from functional analysis: the Find step of the F2T2EA kill chain is required for combat but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

r = add(root, Id="REQ_F16A_D06", Summary="Fix targets", ...
    Description="The aircraft shall determine the location and identity of detected targets to a fix. PLACEHOLDER: quantitative criteria TBD (geolocation accuracy, identification confidence).");
r.Rationale = "Derived from functional analysis: the Fix step of the F2T2EA kill chain is required for combat but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

r = add(root, Id="REQ_F16A_D07", Summary="Track targets", ...
    Description="The aircraft shall maintain track on fixed targets. PLACEHOLDER: quantitative criteria TBD (number of simultaneous tracks, track continuity).");
r.Rationale = "Derived from functional analysis: the Track step of the F2T2EA kill chain is required for combat but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

r = add(root, Id="REQ_F16A_D08", Summary="Target and assign weapons", ...
    Description="The aircraft shall prioritize and designate targets and assign weapons. PLACEHOLDER: quantitative criteria TBD (targeting timeline, weapon-target pairing).");
r.Rationale = "Derived from functional analysis: the Target step of the F2T2EA kill chain is required for combat but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

r = add(root, Id="REQ_F16A_D09", Summary="Assess engagement", ...
    Description="The aircraft shall assess engagement results (battle damage assessment). PLACEHOLDER: quantitative criteria TBD (BDA reporting, re-attack decision support).");
r.Rationale = "Derived from functional analysis: the Assess step of the F2T2EA kill chain is required for combat but is not covered by the sizing-derived requirement set.";
r.Type = "Functional";
r.Keywords = ["draft","derived","placeholder","todo"];

save(rs);
fprintf("Saved f16a_functional_derived.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

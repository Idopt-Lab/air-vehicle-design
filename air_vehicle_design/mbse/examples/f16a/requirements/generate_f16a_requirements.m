function generate_f16a_requirements()
%GENERATE_F16A_REQUIREMENTS Build the F-16A top-level requirements set.
%   Creates mbse/examples/f16a.slreqx with DRAFT top-level aircraft
%   requirements derived from sizing/VnV/BrandtF16A, cross-referenced
%   against Brandt-F16-A.xls (Main tab, mission block J32:Y39 and
%   constraints block R1:X13). Only Excel INPUT cells (literal values,
%   not formulas) are stated as requirements; computed/formula cells are
%   noted as such in the Description for traceability but are not
%   themselves requirement values.
%
%   Re-run to regenerate. Delete f16a.slreqx first for a clean rebuild
%   (existing IDs are otherwise preserved on regeneration).

rs = slreq.new("f16a");
rs.Description = "Top-level Aircraft Requirements for the F-16A, derived from the Brandt F-16A reference sizing model (sizing/VnV/BrandtF16A) and cross-referenced against Brandt-F16-A.xls Main tab. DRAFT - for RFLP Requirements phase review.";

% ---- Root container ----
root = add(rs, Id="REQ_F16A_000", Summary="F-16A top-level aircraft requirements", ...
    Description="Root container for top-level requirements derived from the Brandt F-16A sizing analysis (VnV/BrandtF16A) and the Brandt-F16-A.xls Main tab.");
root.Type = "Container";
root.Keywords = ["draft","auto-generated"];

% =====================================================================
% Mission container - one requirement per mission-profile segment,
% stating only the Excel INPUT cells from Main!J32:Y39. Three
% zero-duration "Patrol" placeholder waypoints and the degenerate
% "Climb2" re-entry node (0 min, same condition as Climb) are excluded
% as non-independent, behaviorally trivial segments.
% =====================================================================
mission = add(root, Id="REQ_F16A_MISSION", Summary="Mission profile requirements");
mission.Type = "Container";
mission.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_001", Summary="Takeoff condition", ...
    Description="When executing the Takeoff segment, the aircraft shall operate at sea level (Altitude = 0 ft, Main!K33, input) using 100% afterburner (Main!K36, input). End Mach (0.282, Main!K35) is a computed liftoff speed (=Miss!B5), not a given input.");
r.Rationale = "Fixes the ground-roll flight condition used to size takeoff thrust and field length.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_002", Summary="Acceleration condition", ...
    Description="While in the Accel segment, the aircraft shall accelerate at an altitude of 10,000 ft (Main!L33, input) to an end Mach number of 0.87 (Main!L35, input) using 0% afterburner / dry power (Main!L36, input). All three values are direct Excel inputs, not formulas.");
r.Rationale = "Defines the dry-power acceleration leg from takeoff climb-out to design cruise Mach.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_003", Summary="Climb condition", ...
    Description="While in the Climb segment, the aircraft shall climb to an altitude of 40,000 ft (Main!M33, input) using 0% afterburner / dry power (Main!M36, input). End Mach (0.87, Main!M35) is inherited from the Accel segment via formula (=L35), not an independent input.");
r.Rationale = "Establishes the target cruise altitude used by all subsequent cruise/dash/combat/egress legs.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_004", Summary="Outbound cruise condition", ...
    Description="While in the Cruise segment, the aircraft shall cruise using 0% afterburner / dry power (Main!N36, input). Altitude (40,000 ft) and Mach (0.87) are carried forward from the Climb/Accel segments via formulas (=M33, =M35), not independent inputs at this segment.");
r.Rationale = "Specifies dry-power cruise to the combat area.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_005", Summary="Dash condition", ...
    Description="While in the Dash segment, the aircraft shall use 50% afterburner (Main!P36, input) to cover a distance of 50 nm (Main!P38, input). Altitude and Mach are carried forward from Cruise via formulas.");
r.Rationale = "Defines the partial-afterburner ingress dash leg distance and power setting.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_006", Summary="Combat condition", ...
    Description="When entering the Combat segment, the aircraft shall operate at an altitude of 25,000 ft (Main!R33, input) for a duration of 2 min (Main!R39, input), while releasing its expendable payload (Miss!I10, 4400 lb). %AB (Main!R36 = P36 = 50%) is tied to the Dash segment's afterburner setting via formula, not an independent input at this segment.");
r.Rationale = "Fixes the combat-persistence duration, altitude, and store-release event.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_007", Summary="Egress condition", ...
    Description="While in the Egress segment, the aircraft shall use 0% afterburner / dry power (Main!S36, input) to cover a distance of 50 nm (Main!S38, input) at an altitude of 40,000 ft (Main!S33, input).");
r.Rationale = "Defines the dry-power return leg from the combat area.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_008", Summary="Return cruise condition", ...
    Description="While in the Cruise2 segment (second cruise leg, toward base), the aircraft shall cruise using 0% afterburner / dry power (Main!V36, input). Altitude and Mach are carried forward via formulas, not independent inputs at this segment. Distance for this leg (Main!V38) is an Excel-computed closure value balancing the overall mission distance budget, not a directly given input.");
r.Rationale = "Specifies dry-power cruise on the return leg; unlike Dash/Egress, this leg's range is a computed closure value, not a design input.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_009", Summary="Loiter condition", ...
    Description="While in the Loiter segment, the aircraft shall loiter at an altitude of 10,000 ft (Main!W33, input) and Mach 0.30 (Main!W35, input) using 0% afterburner (Main!W36, input) for a duration of 20 min (Main!W39, input).");
r.Rationale = "Provides the pre-landing holding/approach-delay reserve.";
r.Keywords = ["draft","auto-generated"];

r = add(mission, Id="REQ_F16A_010", Summary="Landing condition", ...
    Description="While in the Landing segment, the aircraft shall land at sea level (Altitude = 0 ft, Main!X33, input). Landing ground-roll distance (Main!X36 = 2884.95 ft) is an Excel-computed value (=Miss!O6), not a given input; the available landing field length is instead stated as a design input in the Point Performance container (S_land = 4000 ft).");
r.Rationale = "Fixes the sea-level landing condition; actual ground-roll performance is verified against the landing field-length requirement.";
r.Keywords = ["draft","auto-generated"];

% =====================================================================
% Point Performance container - one requirement per constraint condition
% from Main!R1:X13, stating only Excel INPUT cells. Duplicate "Ps" rows
% 9-10 (a documented copy/paste artifact, formula-tied to row 8) are
% excluded as non-independent.
% =====================================================================
perf = add(root, Id="REQ_F16A_PERF", Summary="Point performance requirements");
perf.Type = "Container";
perf.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_011", Summary="Max-Mach point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S3, computed elsewhere from fuel-state cells), an altitude of 36,000 ft (Main!T3, input), and a load factor n of 1 (Main!V3, input) with 100% afterburner (Main!W3, input), the aircraft shall be capable of sustained level flight (Ps = 0, Main!X3, input) at Mach 1.6 (Main!U3, input).");
r.Rationale = "Defines the top-speed design point on the T/W-vs-W/S constraint diagram (Consts row 23).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_012", Summary="Cruise point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S4), an altitude of 36,000 ft (Main!T4, input), and a load factor n of 1 (Main!V4, input) with 0% afterburner (Main!W4, input), the aircraft shall be capable of sustained level flight (Ps = 0, Main!X4, input) at Mach 0.87 (Main!U4, input).");
r.Rationale = "Defines the dry-power cruise design point on the constraint diagram (Consts row 24).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_013", Summary="Max-altitude point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S5), a load factor n of 1 (Main!V5, input) with 100% afterburner (Main!W5, input), the aircraft shall be capable of sustained level flight (Ps = 0, Main!X5, input) at an altitude of 50,000 ft (Main!T5, input) and Mach 0.87 (Main!U5, input).");
r.Rationale = "Defines the service-ceiling design point on the constraint diagram (Consts row 25).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_014", Summary="Subsonic combat-turn point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S6), an altitude of 20,000 ft (Main!T6, input), and Mach 0.87 (Main!U6, input) with 100% afterburner (Main!W6, tied to the Max-Altitude condition's setting via formula =W5), the aircraft shall sustain a load factor n of at least 4.5 (Main!V6, input) at Ps = 0 (Main!X6, input).");
r.Rationale = "Defines subsonic sustained-turn maneuverability (Consts row 26).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_015", Summary="Supersonic combat-turn point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S7), an altitude of 36,000 ft (Main!T7, input), and Mach 1.4 (Main!U7, input) with 100% afterburner (Main!W7, tied to the subsonic combat-turn condition's setting via formula =W6), the aircraft shall sustain a load factor n of at least 1.4 (Main!V7, input) at Ps = 0 (Main!X7, input).");
r.Rationale = "Defines supersonic sustained-turn maneuverability (Consts row 27).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_016", Summary="Specific-excess-power point performance", ...
    Description="At a weight fraction W/W_TO of 0.8997 (Main!S8), an altitude of 10,000 ft (Main!T8, input), and Mach 0.87 (Main!U8, input) with 100% afterburner (Main!W8, tied via formula =W5) and load factor n = 1 (Main!V8, tied via formula =V5), the aircraft shall achieve a specific excess power of at least 500 ft/s (Main!X8, input). Rows 9-10 (Main!R9:X10) duplicate this same condition via formulas and are not independent requirements.");
r.Rationale = "Defines minimum energy-maneuverability at a representative combat condition (Consts row 28; rows 29-30 are a documented copy/paste duplicate).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_017", Summary="Takeoff field-length point performance", ...
    Description="At sea level (Main!T12 = 0 ft, input) and full takeoff weight (W/W_TO = 1, Main!S12, input), using a liftoff-speed factor V/V_stall of 1.2 (Main!U12, input), a rolling-friction coefficient mu of 0.03 (Main!V12, input), and 100% afterburner (Main!W12, input), the aircraft shall achieve takeoff within a ground-roll distance of 4,000 ft (Main!X12, input).");
r.Rationale = "Defines the available takeoff field length and takeoff power/speed assumptions (Consts row 32).";
r.Keywords = ["draft","auto-generated"];

r = add(perf, Id="REQ_F16A_018", Summary="Landing field-length point performance", ...
    Description="At sea level (Main!T13 = 0 ft, input) and full landing weight (W/W_TO = 1, Main!S13, input), using an approach-speed factor V/V_stall of 1.3 (Main!U13, input), a braking-friction coefficient mu of 0.5 (Main!V13, input), and 0% afterburner (Main!W13, input), the aircraft shall land within a ground-roll distance of 4,000 ft (Main!X13, input).");
r.Rationale = "Defines the available landing field length and landing power/speed assumptions (Consts row 33).";
r.Keywords = ["draft","auto-generated"];

% ---- Structural container ----
struct_reqs = add(root, Id="REQ_F16A_STRUCT", Summary="Structural requirements");
struct_reqs.Type = "Container";
struct_reqs.Keywords = ["draft","auto-generated"];

r = add(struct_reqs, Id="REQ_F16A_019", Summary="Ultimate structural load factor", ...
    Description="The aircraft primary structure shall withstand an ultimate design load factor n_ult of 9 g (Main!Q27, input) without structural failure.");
r.Rationale = "Sets the structural design envelope used to size wing, fuselage, and empennage structural weights (Wt tab).";
r.Keywords = ["draft","auto-generated"];

% ---- Weight container ----
weight = add(root, Id="REQ_F16A_WEIGHT", Summary="Weight and payload requirements");
weight.Type = "Container";
weight.Keywords = ["draft","auto-generated"];

r = add(weight, Id="REQ_F16A_020", Summary="Permanent payload capacity", ...
    Description="The aircraft shall carry a permanent (non-expended) payload of 700 lb (Main!O16, input).");
r.Rationale = "Defines the fixed mission payload (e.g. gun, fixed avionics/equipment) that is retained for the full mission and drives OEW.";
r.Keywords = ["draft","auto-generated"];

r = add(weight, Id="REQ_F16A_021", Summary="Expendable payload capacity", ...
    Description="The aircraft shall carry an expendable payload (stores) of 4,400 lb (Main!O17, input), which shall be released during the Combat mission segment (see REQ_F16A_006; Miss!I10 drop event).");
r.Rationale = "Defines the mission store/weapons capacity and ties its release to the combat-segment event that drives post-combat weight fraction and egress performance.";
r.Keywords = ["draft","auto-generated"];

% ---- Materials container ----
materials = add(root, Id="REQ_F16A_MATERIALS", Summary="Materials requirements");
materials.Type = "Container";
materials.Keywords = ["draft","auto-generated"];

r = add(materials, Id="REQ_F16A_022", Summary="Composite material fraction limit", ...
    Description="The airframe structural material mix shall use composite materials (carbon fiber + fiberglass) for no more than 20% of structural weight fraction: carbon fiber = 20% (Cost!B42, input), fiberglass = 0% (Cost!B43, input). The remainder shall be Aluminum 65% (Cost!B41, input), Steel 5% (Cost!B44, input), and Titanium 10% (Cost!B45, input); all five fractions are direct Excel inputs summing to 100% (Cost!B46, formula check).");
r.Rationale = "Bounds material technology assumptions used in the DAPCA IV cost model's material factor D47 (Cost tab) and reflects a legacy-metallic airframe design philosophy.";
r.Keywords = ["draft","auto-generated"];

% ---- Balance container ----
% NOTE: No program-specified minimum values exist yet for these two
% requirements. TODO placeholders reference the Brandt F-16A model's
% computed results (BrandtBalanceStabControl) for context only -- those
% are analysis outputs of the reference model, not design requirements.
balance = add(root, Id="REQ_F16A_BALANCE", Summary="Balance requirements");
balance.Type = "Container";
balance.Keywords = ["draft","auto-generated"];

r = add(balance, Id="REQ_F16A_023", Summary="Tipback angle (TODO)", ...
    Description="TODO: the aircraft shall provide a main-gear tipback angle of at least TBD deg across the operational CG range. No program-specified minimum has been provided yet. For reference only: the Brandt F-16A reference model computes a tipback angle of about 21.5 deg (BrandtBalanceStabControl validation target) -- this is an analysis output of the reference aircraft, not a design requirement value.");
r.Rationale = "Ensures adequate ground clearance/rotation margin during takeoff rotation without a tail strike.";
r.Keywords = ["draft","auto-generated","todo"];

r = add(balance, Id="REQ_F16A_024", Summary="Rollover angle (TODO)", ...
    Description="TODO: the aircraft shall provide a rollover angle of at least TBD deg across the operational CG and gear track range. No program-specified minimum has been provided yet. For reference only: the Brandt F-16A reference model computes a rollover angle of about 74.4 deg (BrandtBalanceStabControl validation target) -- this is an analysis output of the reference aircraft, not a design requirement value.");
r.Rationale = "Bounds lateral ground stability (resistance to tip-over in crosswind taxi/turning operations).";
r.Keywords = ["draft","auto-generated","todo"];

% ---- Stability & Control container ----
% NOTE: No program-specified static margin bounds exist yet. TODO
% placeholder references the Brandt F-16A model's computed CG/neutral
% point results for context only.
sc = add(root, Id="REQ_F16A_SC", Summary="Stability and control requirements");
sc.Type = "Container";
sc.Keywords = ["draft","auto-generated"];

r = add(sc, Id="REQ_F16A_025", Summary="Static margin (TODO)", ...
    Description="TODO: the aircraft shall maintain a static margin between TBD %MAC and TBD %MAC across the operational CG range (takeoff through landing weight). No program-specified bounds have been provided yet. For reference only: the Brandt F-16A reference model computes xnp ~ 26.168 ft, xcg_TO ~ 26.193 ft, and xcg_land ~ 26.137 ft (BrandtBalanceStabControl validation targets) -- these are analysis outputs of the reference aircraft, not design requirement values.");
r.Rationale = "Bounds longitudinal stability/controllability margin used to size the horizontal tail/stabilator and permissible CG travel.";
r.Keywords = ["draft","auto-generated","todo"];

% ---- Cost container ----
cost = add(root, Id="REQ_F16A_COST", Summary="Cost requirements");
cost.Type = "Container";
cost.Keywords = ["draft","auto-generated"];

r = add(cost, Id="REQ_F16A_026", Summary="Unit flyaway cost target", ...
    Description="The program shall achieve a unit flyaway cost not exceeding approximately $68.4M (program-year dollars), per the BrandtCost DAPCA IV validation target.");
r.Rationale = "Provides an affordability target that constrains material/weight and production-quantity assumptions.";
r.Keywords = ["draft","auto-generated"];

save(rs);
fprintf("Saved f16a.slreqx with %d requirements/containers.\n", numel(find(rs, Type="Requirement")));

end

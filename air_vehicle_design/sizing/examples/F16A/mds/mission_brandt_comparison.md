# F-16A CAP Mission (L1/L2/L3) vs Brandt Miss-Tab Ground Truth

Generated 2026-07-24. W_TO = 31377 lbf.

**CAP (10 segments) and Brandt's Miss tab (14 segments) are DIFFERENT mission profiles by design** (docs/subplans/07_mission_analysis.md). Large disagreement on total fuel is documented, expected precedent (docs/subplans/07_mission_analysis.md) -- this table is **informational only**, never a pass/fail comparison.

| Parameter | Fidelity | Computed | Brandt | %Diff | Source | Notes |
|---|---|---|---|---|---|---|
| **[MISSION-LEVEL SUMMARY TARGETS]** | | | | | | |
| Total mission fuel (segments 1-13) [lb] | L1 / L2 / L3 (CAP profile) | L1=8938.4 | L2=6052.8 | L3=6406.5 lb | 6000.43 | L1=+49.0% | L2=+0.9% | L3=+6.8% | Miss!O9; BrandtMission.total_fuel_lb; test_BrandtMission.testTotalFuel | 1% tolerance in test_BrandtMission.m. This is the Brandt Miss-tab total -- NOT expected to match F16MissionL1's CAP-profile total (see file-level _comment). |
| Total mission time (segments 1-13) [min] | TBD | N/A (not computed by MissionL1/L2/L3 -- get_mission_fuel's breakdown has no time/duration total) | 94.06 | N/A | Miss!O8; BrandtMission.total_time_min; test_BrandtMission.testTotalTime | 1% tolerance in test_BrandtMission.m. |
| Landing ground roll distance [ft] | TBD | N/A (not computed by MissionL1/L2/L3 -- ground-roll distance is a Constraints-discipline quantity, not produced by Mission) | 2884.95 | N/A | Miss!O6; BrandtMission.landing_dist_ft; test_BrandtMission.testLandingDist | 1% tolerance in test_BrandtMission.m. No fuel burned during Landing itself; distance-only segment. |
| Final W/W_TO (after Loiter, before Landing) | L1 / L2 / L3 (CAP profile) | L1=0.5940 | L2=0.6812 | L3=0.6705 | 0.6685 | L1=-11.15% | L2=+1.90% | L3=+0.30% | Miss!O12; BrandtMission.W_Wto(end-1); test_BrandtMission.testFinalWeightFraction | 1% tolerance in test_BrandtMission.m. |
| **[PER-SEGMENT FUEL BURN -- Brandt Miss-tab 14-segment profile, Miss!B9:N9]** | | | | | | |
| Fuel: Takeoff [lb] | TBD | N/A (different profile) | 1540.1 | N/A (different profile) | Miss!B9; test_BrandtMission.testFuelTakeoff | 1% tol |
| Fuel: Accel   [lb] | TBD | N/A (different profile) | 377.2 | N/A (different profile) | Miss!C9; test_BrandtMission.testFuelAccel | 1% tol. CAP has no distinct Accel leg. |
| Fuel: Climb   [lb] | TBD | N/A (different profile) | 449.1 | N/A (different profile) | Miss!D9; test_BrandtMission.testFuelClimb | 2% tol in test_BrandtMission.m -- traces to the documented Geom!B19 S_wet double-count (readme_geom.md), not a Mission-discipline issue. |
| Fuel: Cruise  [lb] | TBD | N/A (different profile) | 1003.3 | N/A (different profile) | Miss!E9; test_BrandtMission.testFuelCruise | 1% tol |
| Fuel: Patrol  [lb] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!F9; test_BrandtMission.testFuelPatrol | 0-duration bookkeeping waypoint (absolute tol 5.0 lb in test). CAP omits this row entirely (not a distinct leg). |
| Fuel: Dash    [lb] | TBD | N/A (different profile) | 484.1 | N/A (different profile) | Miss!G9; test_BrandtMission.testFuelDash | 1% tol |
| Fuel: Patrol2 [lb] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!H9; test_BrandtMission.testFuelPatrol2 | 0-duration bookkeeping waypoint (absolute tol 5.0 lb). CAP omits this row. |
| Fuel: Combat  [lb] | TBD | N/A (different profile) | 564.0 | N/A (different profile) | Miss!I9; test_BrandtMission.testFuelCombat | 1% tol |
| Fuel: Egress  [lb] | TBD | N/A (different profile) | 304.6 | N/A (different profile) | Miss!J9; test_BrandtMission.testFuelEgress | 2% tol -- Geom!B19 S_wet double-count (same root cause as Climb). CAP has no distinct Egress leg -- one of only two Brandt legs genuinely absent from CAP. |
| Fuel: Patrol3 [lb] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!K9; test_BrandtMission.testFuelPatrol3 | 0-duration bookkeeping waypoint (absolute tol 5.0 lb). CAP omits this row. |
| Fuel: Climb2  [lb] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!L9; test_BrandtMission.testFuelClimb2 | 0-duration bookkeeping waypoint, 'same conditions' as prior segment (absolute tol 5.0 lb). CAP omits this row. |
| Fuel: Cruise2 [lb] | TBD | N/A (different profile) | 789.4 | N/A (different profile) | Miss!M9; test_BrandtMission.testFuelCruise2 | 2% tol -- Geom!B19 S_wet double-count. |
| Fuel: Loiter  [lb] | TBD | N/A (different profile) | 488.6 | N/A (different profile) | Miss!N9; test_BrandtMission.testFuelLoiter | 1% tol |
| **[PER-SEGMENT TIME -- Brandt Miss-tab 14-segment profile, Miss!B8:N8]** | | | | | | |
| Time: Takeoff [min] | TBD | N/A (different profile) | 0.223 | N/A (different profile) | Miss!B8; test_BrandtMission.testTimeTakeoff | 1% tol |
| Time: Accel   [min] | TBD | N/A (different profile) | 2.256 | N/A (different profile) | Miss!C8; test_BrandtMission.testTimeAccel | 1% tol |
| Time: Climb   [min] | TBD | N/A (different profile) | 4.508 | N/A (different profile) | Miss!D8; test_BrandtMission.testTimeClimb | 2% tol -- S_wet discrepancy |
| Time: Cruise  [min] | TBD | N/A (different profile) | 22.95 | N/A (different profile) | Miss!E8; test_BrandtMission.testTimeCruise | 1% tol |
| Time: Patrol  [min] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!F8; test_BrandtMission.testTimePatrol | given 0 min (absolute tol 0.01) |
| Time: Dash    [min] | TBD | N/A (different profile) | 6.017 | N/A (different profile) | Miss!G8; test_BrandtMission.testTimeDash | 1% tol |
| Time: Patrol2 [min] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!H8; test_BrandtMission.testTimePatrol2 | given 0 min (absolute tol 0.01) |
| Time: Combat  [min] | TBD | N/A (different profile) | 2.0 | N/A (different profile) | Miss!I8; test_BrandtMission.testTimeCombat | given exactly (absolute tol 0.01). Matches CAP's Combat time_min_given=2.0 exactly. |
| Time: Egress  [min] | TBD | N/A (different profile) | 6.017 | N/A (different profile) | Miss!J8; test_BrandtMission.testTimeEgress | 1% tol. CAP has no distinct Egress leg. |
| Time: Patrol3 [min] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!K8; test_BrandtMission.testTimePatrol3 | given 0 min (absolute tol 0.01) |
| Time: Climb2  [min] | TBD | N/A (different profile) | 0.0 | N/A (different profile) | Miss!L8; test_BrandtMission.testTimeClimb2 | given 0 min, 'same conditions' (absolute tol 0.01) |
| Time: Cruise2 [min] | TBD | N/A (different profile) | 30.08 | N/A (different profile) | Miss!M8; test_BrandtMission.testTimeCruise2 | 2% tol -- S_wet discrepancy |
| Time: Loiter  [min] | TBD | N/A (different profile) | 20.0 | N/A (different profile) | Miss!N8; test_BrandtMission.testTimeLoiter | given exactly (absolute tol 0.01). Matches CAP's Loiter time_min_given=20.0 exactly. |
| **[PER-SEGMENT WEIGHT FRACTION W/W_TO (at END of segment) -- Brandt Miss-tab, Miss!B12:N12]** | | | | | | |
| W/W_TO after Takeoff | TBD | N/A (different profile) | 0.9509 | N/A (different profile) | Miss!B12; test_BrandtMission.testWfracTakeoff | 1% tol |
| W/W_TO after Accel | TBD | N/A (different profile) | 0.9389 | N/A (different profile) | Miss!C12; test_BrandtMission.testWfracAccel | 1% tol |
| W/W_TO after Climb | TBD | N/A (different profile) | 0.9246 | N/A (different profile) | Miss!D12; test_BrandtMission.testWfracClimb | 2% tol |
| W/W_TO after Cruise | TBD | N/A (different profile) | 0.8926 | N/A (different profile) | Miss!E12; test_BrandtMission.testWfracCruise | 1% tol |
| W/W_TO after Patrol | TBD | N/A (different profile) | 0.8926 | N/A (different profile) | Miss!F12; test_BrandtMission.testWfracPatrol | 1% tol (unchanged from Cruise -- 0-fuel waypoint) |
| W/W_TO after Dash | TBD | N/A (different profile) | 0.8772 | N/A (different profile) | Miss!G12; test_BrandtMission.testWfracDash | 1% tol |
| W/W_TO after Patrol2 | TBD | N/A (different profile) | 0.8772 | N/A (different profile) | Miss!H12; test_BrandtMission.testWfracPatrol2 | 1% tol (unchanged from Dash -- 0-fuel waypoint) |
| W/W_TO after Combat | TBD | N/A (different profile) | 0.7190 | N/A (different profile) | Miss!I12; test_BrandtMission.testWfracCombat | 1% tol. Includes both Combat fuel burn AND the 4,400 lb payload drop. |
| W/W_TO after Egress | TBD | N/A (different profile) | 0.7093 | N/A (different profile) | Miss!J12; test_BrandtMission.testWfracEgress | 2% tol |
| W/W_TO after Patrol3 | TBD | N/A (different profile) | 0.7093 | N/A (different profile) | Miss!K12; test_BrandtMission.testWfracPatrol3 | 2% tol (unchanged from Egress -- 0-fuel waypoint) |
| W/W_TO after Climb2 | TBD | N/A (different profile) | 0.7093 | N/A (different profile) | Miss!L12; test_BrandtMission.testWfracClimb2 | 2% tol (unchanged from Patrol3 -- 0-fuel waypoint) |
| W/W_TO after Cruise2 | TBD | N/A (different profile) | 0.6841 | N/A (different profile) | Miss!M12; test_BrandtMission.testWfracCruise2 | 2% tol |
| W/W_TO after Loiter (= Miss!O12, final) | TBD | N/A (different profile) | 0.6685 | N/A (different profile) | Miss!N12 = Miss!O12; test_BrandtMission.testWfracLoiter / testFinalWeightFraction | 1% tol |
| **[CAP vs. BRANDT -- INFORMATIONAL DISCLAIMER, NOT A COMPARISON ROW]** | | | | | | |
| F16MissionL1/L2/L3 CAP-profile total fuel vs. Brandt Miss-tab total (6000.43 lb) | N/A | N/A | 6000.43 | EXPECTED LARGE (10-25% per precedent) | docs/subplans/07_mission_analysis.md ('F-16 Mission Profile Discrepancy') | Do NOT treat disagreement here as a bug. CAP (examples/F16A/mission_profile.json) and Brandt's Miss tab are two different mission profiles by design (subplan 07's 'CAP mission profile vs. Brandt's 14-segment Miss-tab profile' section) -- CAP omits Accel and Egress as distinct legs, and its Dash/Combat conditions differ from Brandt's (Dash M=1.60 vs Brandt's M=0.87; Combat M=0.80 vs Brandt's M=0.87). This row exists purely to pre-warn a future reader of mission_brandt_comparison.m's output, per the parent task's explicit instruction. |

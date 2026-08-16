# Sizing-loop dependency diagrams

```
################################################################################
################################################################################
##                                                                            ##
##      #####   ####     ##   #####    ##   ##   ####     ##  ###   ##        ##
##      ##  ##  ##  ##  ####  ##  ##  ####  ##  ##  ##   ####  ##   ##        ##
##      #####   ####   ##  ## ##  ## ##  ## ##  ##  ##  ##  ## ##   ##        ##
##                                                                            ##
##            THIS FILE WAS ORIGINALLY WRITTEN ON 2026-08-13                   ##
##            THIS FILE WAS ORIGINALLY WRITTEN ON 2026-08-13                   ##
##            THIS FILE WAS ORIGINALLY WRITTEN ON 2026-08-13                   ##
##                                                                            ##
##      >>>  IT WAS COMMITTED LATER, ON 2026-08-14.  <<<                       ##
##      >>>  THE COMMIT DATE IS NOT THE WRITE DATE.  <<<                       ##
##                                                                            ##
##      Every statement in this file describes the code as it stood on         ##
##      2026-08-13. CHECK IT AGAINST THE SOURCE BEFORE YOU TRUST IT.           ##
##                                                                            ##
################################################################################
################################################################################
```

> ## ORIGINALLY WRITTEN: **2026-08-13**
>
> Committed 2026-08-14. The file sat untracked for one day, so git records no
> history before the commit. The write date comes from the file's own modified
> timestamp, which is the only record of it.

Mermaid diagrams of `SizingLoopL1` and `SizingLoopL2`, traced to every class,
method and property that the loops call or read at run time. The diagrams show
the iteration loop and the implicit feedback paths.

Closes the in-code request at `SizingLoopL2.m:479` ("Make a mermaid chart to see
exactly what data goes where during runtime. Don't forget the loop.").

**Read this first.** Two different arrow types are used:

| Arrow | Meaning |
| --- | --- |
| solid | An explicit call or an explicit property write in the loop body. |
| dotted | An implicit path. No argument carries the value. A `Dependent` getter reads a handle live, so the next read gets the new value. |

The colour classes are the same in every diagram:

| Colour | Kind of node |
| --- | --- |
| blue | Orchestrator or aggregator |
| green | Concrete F-16 discipline object (Tier 3) |
| orange | Static equation toolbox (not in the inheritance chain) |
| grey | Generic Layer-1 class, base class, or data file |

**Fidelity note.** `SizingLoopL2` serves both L2 and L3. Where the two rungs
differ, the diagram marks the node. There is no L3 propulsion tier, so the L3
rung uses `F16PropL2`.

---

## 1. Level 1: object graph

What `design_study_01_L1.m` builds, and which object holds which handle.

```mermaid
flowchart LR
    subgraph DATA["Input files"]
        SPEC1["f16a_L1.json<br/>via f16a_spec_path(1)"]
        REQ["f16a_requirements.json<br/>via f16a_requirements_path()"]
    end

    STUDY["design_study_01_L1.m"]

    subgraph DISC["Discipline objects (Tier 3)"]
        AERO["F16AeroL1"]
        PROP["F16PropL1"]
        WTS["F16WeightsL1"]
        GEOM["F16GeomL1"]
    end

    subgraph ANALYSIS["Cross-discipline analysis"]
        MISS["MissionAnalysisL1"]
        CON["ConstraintAnalysis"]
    end

    LOOP["SizingLoopL1"]

    STUDY --> AERO
    STUDY --> PROP
    STUDY --> WTS
    STUDY --> GEOM
    STUDY --> MISS
    STUDY --> CON
    STUDY --> LOOP

    SPEC1 --> AERO
    SPEC1 --> PROP
    SPEC1 --> WTS
    SPEC1 --> GEOM
    REQ --> GEOM
    REQ --> MISS
    REQ --> CON

    AERO -. injected .-> MISS
    PROP -. injected .-> MISS
    GEOM -. injected .-> MISS
    AERO -. injected .-> CON
    PROP -. injected .-> CON

    AERO --> LOOP
    PROP --> LOOP
    WTS --> LOOP
    GEOM --> LOOP
    MISS --> LOOP
    CON --> LOOP

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef disc fill:#d6f5d6,stroke:#2f855a,color:#000
    classDef data fill:#e6e6e6,stroke:#666,color:#000
    class LOOP,MISS,CON,STUDY orch
    class AERO,PROP,WTS,GEOM disc
    class SPEC1,REQ data
```

**Point to note.** `F16AeroL1` takes no geometry object. It reads `AR` and
`Lambda_LE_deg` as plain spec scalars. This is what makes the L1 constraint
envelope independent of `S_ref`, and it is why `SizingLoopL1` calls
`con.optimal_point()` one time only, before the loop.

---

## 2. Level 1: one iteration, with the loop

```mermaid
flowchart TD
    START(["run(W_TO_guess)"]) --> OPT["con.optimal_point()<br/>ONE time, before the loop"]
    OPT --> INIT["W_TO = W_TO_guess"]
    INIT --> ITER{{"for iter = 1 : max_iter"}}

    ITER --> S1["S_ref = W_TO / WS_opt<br/>WRITE geom.S_ref"]
    S1 --> S2["T_SL = TW_opt * W_TO<br/>WRITE prop.T_SL"]
    S2 --> S3["W_fuel = miss.compute_fuel(aero, prop, W_TO)"]
    S3 --> S4["W_OEW = wts.OEW(W_TO)"]
    S4 --> S5["WRITE wts.W_TO, wts.W_energy"]
    S5 --> S6["W_payload = wts.W_payload_fixed<br/>+ wts.W_payload_expendable"]
    S6 --> S7["denom = 1 - W_OEW/W_TO - W_fuel/W_TO"]
    S7 --> BR{"denom > MIN_DENOM<br/>MIN_DENOM = 0.05"}
    BR -- yes --> RAY["W_TO_new = W_payload / denom<br/>Raymer Eq. 3.4"]
    BR -- no --> NIC["W_TO_new = W_OEW + W_fuel + W_payload<br/>Nicolai Eq. 5.1<br/>n_fallback = n_fallback + 1"]
    RAY --> HIST["history(end+1) = struct(...)"]
    NIC --> HIST
    HIST --> CONV{"abs(W_TO_new - W_TO) < tol"}
    CONV -- no --> RELAX["W_TO = relaxation*W_TO<br/>+ (1-relaxation)*W_TO_new"]
    RELAX -.->|"NEXT ITERATION"| ITER
    CONV -- yes --> DONE["W_TO = W_TO_new<br/>converged = true"]

    DONE --> POST["POST-LOOP re-derive<br/>S_ref = W_TO/WS_opt, WRITE geom.S_ref<br/>T_SL = TW_opt*W_TO, WRITE prop.T_SL<br/>WRITE wts.W_TO"]
    POST --> RESULT(["result struct<br/>W_TO, S_ref, T_SL, n_iter,<br/>converged, history, n_fallback"])

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    class OPT,S3,S4 orch
```

**Two facts about the L1 loop that the diagram makes visible.**

1. `prop.T_SL` is write-only inside the L1 loop. `PropL1.get_thrust_lapse` is a
   density-ratio law, so it does not read `T_SL`. The L1 mission uses only
   `FixedFractionSegment`, `BreguetRangeSegment` and `BreguetEnduranceSegment`,
   and none of those read `prop.T_SL` either. `T_SL` is therefore a pure output
   at L1.
2. The loop does not set `geom.W_TO`. `F16GeomL1.S_wet` and
   `F16GeomL1.L_fuselage` are `Dependent` on `W_TO` and error if read before it
   is set. Nothing in the L1 loop reads them, because `F16AeroL1` holds no
   geometry object and the mission reads only `geom.get_S_ref()` and
   `geom.n_engines`.

---

## 3. Level 2 and Level 3: object graph

`design_study_02_L2.m` and `design_study_03_L3.m` build the same shape. The
differences are marked.

```mermaid
flowchart LR
    subgraph DATA["Input files"]
        SPEC["f16a_L2.json or f16a_L3.json<br/>via f16a_spec_path(2 or 3)"]
        REQ["f16a_requirements.json"]
    end

    STUDY["design_study_02_L2.m<br/>design_study_03_L3.m"]

    subgraph DISC["Discipline objects (Tier 3)"]
        PROP["F16PropL2<br/>SHARED by L2 and L3"]
        GEOM["F16GeomL2 or F16GeomL3"]
        AERO["F16AeroL2 or F16AeroL3"]
        WTS["F16WeightsL2 or F16WeightsL3"]
    end

    subgraph SIZERS["Sizing helpers"]
        TAIL["F16TailL1<br/>SHARED by L2 and L3"]
        CTRL["ControlSurfaceSizer<br/>via f16a_control_surfaces()"]
    end

    subgraph ANALYSIS["Cross-discipline analysis"]
        MISS["MissionAnalysisL2<br/>SHARED by L2 and L3"]
        CON["ConstraintAnalysis"]
    end

    LOOP["SizingLoopL2"]

    STUDY --> PROP
    STUDY --> GEOM
    STUDY --> CTRL
    STUDY --> AERO
    STUDY --> WTS
    STUDY --> MISS
    STUDY --> TAIL
    STUDY --> CON
    STUDY --> LOOP

    SPEC --> PROP
    SPEC --> GEOM
    SPEC --> AERO
    SPEC --> WTS
    REQ --> WTS
    REQ --> MISS
    REQ --> CON

    PROP -->|"CONSTRUCTOR ARG<br/>sizes the nacelle"| GEOM
    GEOM -->|"CONSTRUCTOR ARG"| AERO
    CTRL -->|"CONSTRUCTOR ARG<br/>flap chord and span fractions"| AERO
    GEOM -->|"CONSTRUCTOR ARG"| WTS
    PROP -->|"CONSTRUCTOR ARG"| WTS

    AERO -. injected .-> MISS
    PROP -. injected .-> MISS
    GEOM -. injected .-> MISS
    AERO -. injected .-> CON
    PROP -. injected .-> CON

    AERO --> LOOP
    PROP --> LOOP
    WTS --> LOOP
    GEOM --> LOOP
    MISS --> LOOP
    CON --> LOOP
    TAIL --> LOOP
    CTRL --> LOOP

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef disc fill:#d6f5d6,stroke:#2f855a,color:#000
    classDef data fill:#e6e6e6,stroke:#666,color:#000
    class LOOP,MISS,CON,STUDY orch
    class PROP,GEOM,AERO,WTS disc
    class TAIL,CTRL,SPEC,REQ data
```

**Construction order is not free.** `prop` must exist before `geom`, because
`geom.T_AB_SLS_lb` is `Dependent` on `prop.T_SL`. `ctrl` must exist before
`aero`, because the aero high-lift model reads the flaperon and leading-edge-flap
fractions off `ctrl`.

---

## 4. Level 2 and Level 3: one iteration, with the loop

The order of the blocks is significant. The comments in `SizingLoopL2.m` state
why. The diagram keeps that order.

```mermaid
flowchart TD
    START(["run(W_TO_guess, T_SL_guess)"]) --> INIT["W_TO = W_TO_guess<br/>T_SL = T_SL_guess"]
    INIT --> ITER{{"for iter = 1 : max_iter"}}

    ITER --> A1["con.optimal_point()<br/>EVERY ITERATION, not once"]
    A1 --> A2["S_ref = W_TO / WS_opt<br/>WRITE geom.S_ref"]
    A2 --> A3["T_SL_new = TW_opt * W_TO<br/>WRITE prop.T_SL"]
    A3 --> A4["tail.size(geom.S_ref, geom.b_wing,<br/>geom.cbar_wing, geom.L_HT, geom.L_VT)"]
    A4 --> A5["WRITE geom.S_ht, geom.S_vt"]
    A5 --> A6["ctrl.size(geom)<br/>AFTER the tail, never before"]
    A6 --> A7["WRITE geom.S_ail, S_elev, S_rud,<br/>S_flaperon, S_lef, S_stab"]
    A7 --> A8["W_fuel = miss.compute_fuel(aero, prop, W_TO)"]
    A8 --> A9["W_OEW = wts.OEW(W_TO)"]
    A9 --> A10["WRITE wts.W_TO, wts.W_energy"]
    A10 --> A11["W_payload = wts.W_payload_fixed<br/>+ wts.W_payload_expendable"]
    A11 --> A12["denom = 1 - W_OEW/W_TO - W_fuel/W_TO"]
    A12 --> BR{"denom > MIN_DENOM<br/>MIN_DENOM = 0.05"}
    BR -- yes --> RAY["W_TO_new = W_payload / denom<br/>Raymer Eq. 3.4"]
    BR -- no --> NIC["W_TO_new = W_OEW + W_fuel + W_payload<br/>Nicolai Eq. 5.1<br/>n_fallback = n_fallback + 1"]
    RAY --> HIST["history(end+1), 15 fields"]
    NIC --> HIST
    HIST --> CONV{"abs(diff_W) < tol<br/>AND abs(diff_T) < tol"}
    CONV -- no --> RELAX["W_TO = relaxation*W_TO + (1-relaxation)*W_TO_new<br/>T_SL = relaxation*T_SL + (1-relaxation)*T_SL_new"]
    RELAX -.->|"NEXT ITERATION"| ITER
    CONV -- yes --> DONE["W_TO = W_TO_new<br/>T_SL = T_SL_new<br/>converged = true"]

    DONE --> POST["POST-LOOP repeat of the whole block:<br/>con.optimal_point(), geom.S_ref, prop.T_SL,<br/>tail.size(...), ctrl.size(...), wts.W_TO"]
    POST --> RESULT(["result struct<br/>W_TO, S_ref, T_SL, n_iter,<br/>converged, history, n_fallback"])

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    class A1,A4,A6,A8,A9 orch
```

### 4b. The feedback paths inside one L2 or L3 iteration

The block order above hides the couplings, because no argument carries them.
This diagram shows the same iteration as a data-flow graph. Every dotted edge is
a `Dependent` getter that reads a shared handle live.

```mermaid
flowchart LR
    WTO(["W_TO<br/>state variable"])
    TSL(["T_SL<br/>state variable"])

    CON["ConstraintAnalysis<br/>optimal_point()"]
    WSOPT(["WS_opt"])
    TWOPT(["TW_opt"])

    SREF["geom.S_ref"]
    PTSL["prop.T_SL"]

    GEOMD["geom Dependent cascade<br/>b_wing, cbar_wing, chords,<br/>exposed areas, S_wet, Amax,<br/>x_c4 stations, L_HT, L_VT"]

    TAILS["tail.size(...)"]
    SHT["geom.S_ht, geom.S_vt"]
    CTRLS["ctrl.size(geom)"]
    CS["geom.S_ail, S_elev, S_rud,<br/>S_flaperon, S_lef, S_stab"]

    AERO["aero.drag_polar(state)<br/>CD0, K1, K2<br/>and CLmax, CLmax_TO, CLmax_L"]
    MISS["miss.compute_fuel(...)"]
    WTS["wts.OEW(W_TO)"]

    WFUEL(["W_fuel"])
    WOEW(["W_OEW"])
    NEW(["W_TO_new"])

    CON --> WSOPT
    CON --> TWOPT
    WSOPT --> SREF
    WTO --> SREF
    TWOPT --> PTSL
    WTO --> PTSL

    SREF -.-> GEOMD
    PTSL -.->|"T_AB_SLS_lb -> D_inlet<br/>-> duct wetted area"| GEOMD
    GEOMD -.->|"S_wet, S_ref, AR, sweeps,<br/>taper, Amax, L_aircraft"| AERO

    GEOMD --> TAILS
    TAILS --> SHT
    SHT -.-> GEOMD
    SHT --> CTRLS
    SREF --> CTRLS
    CTRLS --> CS
    CS -.->|"L3 ONLY: S_csw, S_r, S_cs"| GEOMD

    AERO --> MISS
    PTSL --> MISS
    MISS --> WFUEL
    GEOMD -.->|"exposed areas, S_wet_fus,<br/>and at L3 the whole planform"| WTS
    PTSL -.->|"engine weight, Raymer Eq. 10.10"| WTS
    WTS --> WOEW

    WFUEL --> NEW
    WOEW --> NEW
    NEW -.->|"under-relaxed<br/>NEXT ITERATION"| WTO

    AERO -.->|"ONE ITERATION LAGGED:<br/>the next optimal_point() reads<br/>this iteration's CD0 and CLmax"| CON

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef state fill:#fff2cc,stroke:#b7791f,color:#000
    class CON,MISS,WTS,AERO,TAILS,CTRLS orch
    class WTO,TSL,WSOPT,TWOPT,WFUEL,WOEW,NEW state
```

**Why `optimal_point()` runs every iteration at L2 and L3, but one time at L1.**
The dotted edge from `aero` back to `ConstraintAnalysis` closes a real loop.
`geom.S_ref` and `prop.T_SL` both move the wetted area, therefore `CD0`,
therefore every constraint curve. Each call reads the previous iteration's
values, because the loop assigns this iteration's values immediately after the
call. That one-iteration lag is the same lag the under-relaxed state variables
have.

**The L2 and L3 difference in the control-surface path.** At L3 the six areas
feed `geom.S_csw`, `geom.S_r` and `geom.S_cs`, which the Raymer Eq. 15.1, 15.3
and 15.17 weight terms consume. At L2 the areas reach only `history` and the
report scripts, because `F16GeomL2` declares no such properties and
`F16WeightsL2` consumes none.

---

## 5. `ConstraintAnalysis.optimal_point()`, expanded

Both loops enter this subtree. The constraint set comes from
`F16ConstraintSet.constraint_map()`, and the sweep is
`PointPerformanceBase.WS_RANGE_SIZING`, 31 points from 20 to 160 psf.

```mermaid
flowchart TD
    OP["ConstraintAnalysis.optimal_point()"]
    OP --> ENV["envelope()"]
    OP --> WALL["min_wall()"]
    ENV --> PR["producer_rows()<br/>every constraint that is NOT an Only_WbyS"]
    OP --> ARG["grid argmin of the envelope,<br/>over the part of WS_range<br/>at or below the tightest wall"]
    ARG --> OUT(["WS_opt, TW_opt"])

    PR --> LF["LevelFlightConstraint x 3<br/>Max Mach, Cruise, Max Alt"]
    PR --> ST["SustainedTurnConstraint x 2<br/>Combat Turn 1, Combat Turn 2"]
    PR --> EP["ExcessPowerConstraint x 1<br/>Excess Power"]
    PR --> TO["TakeoffConstraint x 1"]
    WALL --> LD["LandingConstraint x 1<br/>Only_WbyS wall"]

    LF --> ME["MasterEquationConstraint.required_TW(WS)"]
    ST --> ME
    EP --> ME

    ME --> MEA["aero.drag_polar(state)<br/>CD0, K1, K2"]
    ME --> MEP["get_alpha()"]
    MEP --> MEP1["prop.thrust_lapse(state)<br/>power_setting = AB"]
    MEP --> MEP2["prop.thrust_lapse_mil_on_AB_scale(state)<br/>power_setting = mil"]
    ME --> MES["state.q, state.V<br/>AircraftState"]
    ME --> MET["A/WS + B*WS + C + D<br/>Mattingly master equation"]

    TO --> TOA["aero.get_CLmax_TO()"]
    TO --> TOB["aero.drag_polar(state).CD0<br/>+ aero.get_Delta_CD0_TO(...)"]
    TO --> TOC["prop.thrust_lapse(state)"]
    TO --> TOD["state.rho"]
    TO --> TOE["B*WS + C<br/>ground-roll relation"]

    LD --> LDA["aero.get_CLmax_L()"]
    LD --> LDB["aero.drag_polar(state).CD0<br/>+ aero.get_Delta_CD0_L(...)"]
    LD --> LDC["state.rho"]
    LD --> LDD["WS_max()"]

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef gen fill:#e6e6e6,stroke:#666,color:#000
    class OP,ENV,WALL,PR,ARG orch
    class LF,ST,EP,TO,LD,ME gen
```

**Note on `get_Delta_CD0_TO` and `get_Delta_CD0_L`.** The arity is not uniform
across the fidelity levels. `F16AeroL1` and `F16AeroL2` take no argument.
`F16AeroL3` takes the flight state, for a gear-strut Reynolds-number lookup.
`TakeoffConstraint` and `LandingConstraint` each dispatch on the declared
`InputNames` by metaclass reflection.

**Note on `StallConstraint`.** The class exists and has unit tests, but the
requirements JSON carries no Stall condition, so no Stall wall is built for the
F-16.

---

## 6. `miss.compute_fuel(...)`, expanded: Level 1

```mermaid
flowchart TD
    CF["MissionAnalysisBase.compute_fuel(aero, prop, W_TO)<br/>the aero and prop arguments are accepted<br/>for signature compatibility and NOT used;<br/>the INJECTED handles are used"]
    CF --> TF["total_fuel(W_TO)"]
    TF --> CTX["build_context(W_TO)<br/>reads aero.aircraft_category<br/>and geom.n_engines"]
    TF --> LOOP2["for each segment: seg.step(W, ctx)<br/>threads W_before -> W_after"]
    LOOP2 --> RES["W_fuel = raw_burn * (1 + reserve_fuel_fraction)<br/>Roskam Part I Eq. 2.14/2.15"]

    LOOP2 --> FF["FixedFractionSegment<br/>Startup, Taxi, Takeoff, Climb, Landing"]
    LOOP2 --> BR["BreguetRangeSegment<br/>Cruise, Dash, Cruise2"]
    LOOP2 --> BE["BreguetEnduranceSegment<br/>Combat, Loiter"]

    FF --> FFA["MissionEquations.roskam_fixed_fraction<br/>(ctx.aircraft_category, segment_type)<br/>Roskam Part I Table 2.1"]

    BR --> BRA["ctx.aero.drag_polar(state)"]
    BR --> BRB["ctx.geom.get_S_ref()"]
    BR --> BRC["ctx.aero.compute_CL(W_before, state.q, S_ref)"]
    BR --> BRD["ctx.aero.compute_CD(CD0, K1, K2, CL)"]
    BR --> BRE["MissionEquations.select_tsfc(ctx.prop, state, percent_ab)"]
    BR --> BRF["MissionEquations.breguet_range_wf<br/>Roskam Eq. 2.10"]

    BE --> BEA["ctx.aero.drag_polar(state)"]
    BE --> BEB["ctx.geom.get_S_ref()"]
    BE --> BEC["ctx.aero.compute_CL / compute_CD"]
    BE --> BED["MissionEquations.select_tsfc(...)"]
    BE --> BEE["MissionEquations.breguet_endurance_wf<br/>Roskam Eq. 2.12"]

    BRE --> TSFC["prop.compute_TSFC_installed(state)<br/>if present, else prop.get_TSFC(state)"]
    BED --> TSFC
    TSFC --> TSFCAB["AB blend if percent_ab > 0.<br/>F16PropL1 has NO AB model,<br/>so the AB value degrades to dry<br/>and the segment reports ab_degraded"]

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef tb fill:#ffe0b3,stroke:#c05621,color:#000
    class CF,TF,CTX,LOOP2 orch
    class FFA,BRE,BRF,BED,BEE,TSFC,TSFCAB tb
```

---

## 7. `miss.compute_fuel(...)`, expanded: Level 2 and Level 3

`MissionAnalysisL2` serves both rungs. There is no L3 mission tier.

```mermaid
flowchart TD
    CF["MissionAnalysisBase.compute_fuel(aero, prop, W_TO)"]
    CF --> TF["total_fuel(W_TO)"]
    TF --> CTX["build_context(W_TO)"]
    TF --> SEG["for each segment: seg.step(W, ctx)"]
    SEG --> RES["W_fuel = raw_burn * (1 + reserve_fuel_fraction)"]

    SEG --> FF["FixedFractionSegment<br/>Startup, Taxi, Landing"]
    SEG --> TOS["TakeoffSegment<br/>Takeoff"]
    SEG --> CLS["ClimbSegment<br/>Climb"]
    SEG --> CRS["CruiseSegment<br/>Cruise, Dash, Cruise2"]
    SEG --> LOS["LoiterSegment<br/>Loiter"]
    SEG --> COS["CombatSegment<br/>Combat"]

    CLS --> MES["MasterEquationSegment<br/>shared base"]
    CRS --> MES
    LOS --> MES

    FF --> FFA["MissionEquations.roskam_fixed_fraction<br/>Roskam Table 2.1"]

    TOS --> TOA["ctx.aero.get_CLmax_TO()"]
    TOS --> TOB["ctx.geom.get_S_ref()"]
    TOS --> TOC["ctx.prop.T_SL"]
    TOS --> TOD["MissionEquations.select_tsfc(...)<br/>roll value and dry value"]
    TOS --> TOE["warmup and start fuel<br/>SUPPRESSED when the profile has<br/>explicit Startup or Taxi legs"]

    MES --> MA["ctx.geom.get_S_ref()"]
    MES --> MB["ctx.aero.drag_polar(start state)<br/>ctx.aero.drag_polar(end state)"]
    MES --> MC["ctx.aero.compute_CL / compute_CD<br/>on the averaged polar"]
    MES --> MD["MissionEquations.select_tsfc(ctx.prop, state, percent_ab)"]
    MES --> ME2["segment_time():<br/>Cruise from distance_nm / V<br/>Loiter from time_min<br/>Climb from the Ps relation"]
    CLS --> CLA["ctx.prop.T_SL / ctx.W_TO<br/>and MissionEquations.select_alpha"]

    COS --> COA["MissionEquations.select_alpha(ctx.prop, st, percent_ab)"]
    COS --> COB["T_avail = ctx.prop.T_SL * alpha"]
    COS --> COC["MissionEquations.select_tsfc(...)"]
    COS --> COD["ctx.geom.get_S_ref()<br/>ctx.aero.drag_polar(st)<br/>compute_CL / compute_CD<br/>with cd0_increment for stores"]

    MD --> TSFC["prop.compute_TSFC_installed / compute_TSFC_AB_installed<br/>F16PropL2 has both"]
    TOD --> TSFC
    COC --> TSFC
    CLA --> ALPHA["prop.thrust_lapse_mil_on_AB_scale<br/>and prop.thrust_lapse<br/>blended by percent_ab"]
    COA --> ALPHA

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef tb fill:#ffe0b3,stroke:#c05621,color:#000
    class CF,TF,CTX,SEG orch
    class FFA,TOD,MD,COC,COA,CLA,TSFC,ALPHA tb
```

---

## 8. `tail.size(...)` and `ctrl.size(geom)`, expanded

L2 and L3 only. `SizingLoopL1` has neither object.

```mermaid
flowchart TD
    LOOP["SizingLoopL2 iteration"]

    LOOP -->|"1st"| T["F16TailL1.size(S_ref, b_wing, cbar_wing, L_HT, L_VT)"]
    T --> TT["TailL1.size(obj, ...)"]
    TT --> TC["TailL1.compute_S_HT(c_HT, cbar, S_ref, L_HT)<br/>TailL1.compute_S_VT(c_VT, b, S_ref, L_VT)<br/>Raymer 6th ed. Eqs. 6.28 and 6.29"]
    TC --> TR(["S_ht, S_vt"])
    TR --> TW["WRITE geom.S_ht, geom.S_vt"]

    CTOR["F16TailL1 constructor<br/>TailL1.compute_tail_volume_coeffs<br/>('jet_fighter', RSS=true, all-moving=true)<br/>c_HT = 0.315, c_VT = 0.063"] -.-> T

    LOOP -->|"2nd, never before"| C["ControlSurfaceSizer.size(geom)"]
    C --> F1["Family 1, chord x span fraction<br/>Raymer Fig. 6.3 and Table 6.5<br/>S_ail  = c_ail_frac  * b_ail_frac  * geom.S_ref<br/>S_elev = c_elev_frac * b_elev_frac * geom.S_ht<br/>S_rud  = c_rud_frac  * b_rud_frac  * geom.S_vt"]
    C --> F2["Family 2, wing flaps by span station<br/>AeroL2.compute_S_flapped_ratio<br/>Roskam Part II Eq. 7.10<br/>reads geom.lambda_wing and geom.S_ref<br/>S_flaperon, S_lef"]
    C --> F3["All-moving tail flag<br/>S_stab = geom.S_ht, S_elev stays 0<br/>Raymer Table 6.5 footnote"]
    F1 --> CR(["S_ail, S_elev, S_rud,<br/>S_flaperon, S_lef, S_stab"])
    F2 --> CR
    F3 --> CR
    CR --> CW["WRITE the six geom properties"]

    TW -.->|"geom.S_ht feeds<br/>S_elev, S_stab, S_rud"| C
    CW -.->|"L3 ONLY<br/>S_csw = S_flaperon + S_lef<br/>S_r   = S_rud<br/>S_cs  = S_csw + S_stab + S_rud"| L3W["F16GeomL3 Dependent<br/>-> F16WeightsL3"]

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef tb fill:#ffe0b3,stroke:#c05621,color:#000
    class LOOP,T,C orch
    class TT,TC,F1,F2,CTOR tb
```

**Why the order is fixed.** `S_elev`, `S_stab` and `S_rud` are sized off `S_ht`
and `S_vt`. If the two blocks were reversed, they would use the previous
iteration's tail.

**Feedback in the tail arm.** `geom.L_HT` and `geom.L_VT` are `Dependent` on
`x_c4_wing`, `x_c4_ht` and `x_c4_vt`, which move with both `S_ref` and
`S_ht`/`S_vt`. The arm is therefore part of the fixed point, lagged by one
iteration. The lag is stable, because a larger `S_ht` makes the arm longer,
which makes the next `S_ht` smaller.

---

## 9. `wts.OEW(W_TO)`, expanded, all three levels

```mermaid
flowchart TD
    subgraph L1["Level 1"]
        O1["F16WeightsL1.OEW(W_TO)"]
        O1 --> W1["WeightsL1.OEW(obj, W_TO)"]
        W1 --> W1A["We/W_TO = K_vs * A * W_TO^C<br/>Raymer 6th ed. Table 3.1<br/>row from aircraft_category"]
        NOTE1["No injected object at all.<br/>L1 is the only weights level<br/>with no dependency injection."]
    end

    subgraph L2["Level 2"]
        O2["F16WeightsL2.OEW(W_TO)"]
        O2 --> W2["WeightsL2.OEW(obj, W_TO) + obj.W_strake"]
        W2 --> W2A["weight_wing"]
        W2 --> W2B["weight_tail, HT and VT"]
        W2 --> W2C["weight_fuselage"]
        W2 --> W2D["weight_landing_gear"]
        W2 --> W2E["weight_installed_engine"]
        W2 --> W2F["weight_all_else_empty"]
        G2["Dependent, read live off geom:<br/>S_w = geom.S_exposed_wing<br/>S_ht = geom.S_exposed_ht<br/>S_vt = geom.S_exposed_vt<br/>S_wet_fus = geom.get_S_wet_fuselage()"] -.-> W2
        P2["Dependent, read live off prop:<br/>W_en = PropL2.engine_weight_AB<br/>(prop.T_SL, design_mach, prop.bypass_ratio)<br/>Raymer Eq. 10.10"] -.-> W2E
    end

    subgraph L3["Level 3"]
        O3["F16WeightsL3.OEW(W_TO)"]
        O3 --> W3["WeightsL3.OEW(obj, W_TO) + obj.W_strake"]
        W3 --> W3A["weight_wing, Raymer Eq. 15.1<br/>consumes geom.S_csw"]
        W3 --> W3B["weight_tail, Raymer Eqs. 15.2 and 15.3<br/>Eq. 15.3 consumes geom.S_r"]
        W3 --> W3C["weight_fuselage"]
        W3 --> W3D["weight_landing_gear, main and nose"]
        W3 --> W3E["weight_engine_section"]
        W3 --> W3F["weight_systems, Raymer Eq. 15.17<br/>consumes geom.S_cs"]
        G3["Dependent, read live off geom:<br/>full planform, exposed areas,<br/>AR, taper, sweeps, t/c, spans,<br/>fuselage envelope, L_t,<br/>and S_csw / S_r / S_cs"] -.-> W3
        P3["Dependent, read live off prop:<br/>T = prop.T_SL<br/>W_en via PropL2.engine_weight_AB<br/>TSFC via prop.get_TSFC(cruise state)"] -.-> W3
    end

    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    classDef tb fill:#ffe0b3,stroke:#c05621,color:#000
    class O1,O2,O3 orch
    class W1,W2,W3,W1A tb
```

**`OEW` takes `W_TO` as an argument at every level.** The loop's current iterate
is passed in. It is not read off `obj.W_TO`. The loop writes `wts.W_TO` after the
call, for the reporting scripts and for the `Dependent` weight-breakdown
properties.

---

## 10. The geometry `Dependent` cascade

This is the mechanism behind most of the dotted edges above. Nothing is cached.
Every getter recomputes on read.

```mermaid
flowchart LR
    subgraph WRITTEN["Written by SizingLoopL2 each iteration"]
        SR["S_ref"]
        SHT["S_ht"]
        SVT["S_vt"]
        SCS6["S_ail, S_elev, S_rud,<br/>S_flaperon, S_lef, S_stab"]
    end

    subgraph EXTERNAL["Read off the injected prop handle"]
        PT["prop.T_SL"]
    end

    SR --> BW["b_wing"]
    SR --> CRW["c_root_wing"]
    BW --> CRW
    CRW --> CTW["c_tip_wing"]
    CRW --> CBW["cbar_wing"]
    SR --> SEW["S_exposed_wing"]
    SEW --> SWW["S_wet_wing"]
    BW --> XML["x_mac_le_wing"]
    XML --> XC4W["x_c4_wing"]

    SHT --> BHT["b_ht"]
    BHT --> CRHT["c_root_ht, c_tip_ht"]
    SHT --> SEHT["S_exposed_ht"]
    SEHT --> SWHT["S_wet_ht"]
    BHT --> XC4H["x_c4_ht"]

    SVT --> BVT["b_vt"]
    BVT --> CRVT["c_root_vt, c_tip_vt"]
    SVT --> SEVT["S_exposed_vt"]
    SEVT --> SWVT["S_wet_vt"]
    BVT --> XC4V["x_c4_vt"]

    PT --> TAB["T_AB_SLS_lb"]
    TAB --> DIN["D_inlet, D_exit<br/>GeometryBase.compute_nacelle_diameter"]
    DIN --> SWD["S_wet_duct"]

    SWW --> SWET["S_wet TOTAL<br/>wing + HT + VT + fuselage + duct"]
    SWHT --> SWET
    SWVT --> SWET
    SWD --> SWET
    FUS["S_wet_fuselage<br/>from the fuselage envelope inputs"] --> SWET

    XC4W --> LHT["L_HT"]
    XC4H --> LHT
    XC4W --> LVT["L_VT"]
    XC4V --> LVT

    AMAX["Amax<br/>L2: fuselage-envelope ellipse<br/>L3: whole-aircraft area-ruled buildup<br/>TIER-SPECIFIC BY DESIGN"]

    SCS6 --> CSW["L3 ONLY<br/>S_csw = S_flaperon + S_lef<br/>S_r = S_rud<br/>S_cs = S_csw + S_stab + S_rud"]

    SWET -.->|"aero.S_wet"| AERO["F16AeroL2 / F16AeroL3<br/>CD0 = Cfe * S_wet / S_ref<br/>Raymer Eq. 12.23"]
    SR -.->|"aero.S_ref"| AERO
    AMAX -.->|"aero.Amax_ft2<br/>Sears-Haack wave drag,<br/>Raymer Eq. 12.44"| AERO

    SEW -.-> WTS["F16WeightsL2 / F16WeightsL3"]
    SEHT -.-> WTS
    SEVT -.-> WTS
    CSW -.-> WTS
    LHT -.-> TAIL["F16TailL1.size(...)"]
    LVT -.-> TAIL
    BW -.-> TAIL
    CBW -.-> TAIL
    SR -.-> TAIL

    classDef written fill:#fff2cc,stroke:#b7791f,color:#000
    classDef orch fill:#cfe4ff,stroke:#2b6cb0,color:#000
    class SR,SHT,SVT,SCS6,PT written
    class AERO,WTS,TAIL orch
```

---

## 11. Class inheritance

The three-tier discipline pattern, plus the classes the two loops touch. The
static toolboxes (`AeroL1`, `GeomL2`, `PropL2`, `WeightsL3`, `TailL1`,
`MissionEquations`, ...) are **not** in any inheritance chain. They are shown in
the diagrams above as call targets only.

```mermaid
classDiagram
    class SizingLoopL1 {
        <<handle>>
        +MIN_DENOM 0.05
        +run(W_TO_guess, opts) result
    }
    class SizingLoopL2 {
        <<handle>>
        +MIN_DENOM 0.05
        +run(W_TO_guess, T_SL_guess, opts) result
    }

    class AerodynamicsBase {
        <<abstract handle>>
        +drag_polar(state)*
        +get_CLmax(state)*
        +compute_CD(CD0,K1,K2,CL)
        +compute_CL(L,q,S_ref)
    }
    class PropulsionBase {
        <<abstract handle>>
        +T_SL*
        +thrust_lapse(state)*
        +get_TSFC(state)*
        +thrust_lapse_mil_on_AB_scale(state)
    }
    class WeightsBase {
        <<abstract handle>>
        +W_TO*
        +W_energy*
        +W_payload_fixed*
        +W_payload_expendable*
        +OEW(W_TO)*
    }
    class GeometryBase {
        <<abstract handle>>
        +get_S_ref()*
        +get_S_wet()*
    }
    class MissionAnalysisBase {
        <<abstract handle>>
        +total_fuel(W_TO)
        +compute_fuel(aero, prop, W_TO)
        +build_context(W_TO)
    }
    class ConstraintAnalysis {
        <<value class>>
        +optimal_point() WS_opt_and_TW_opt
        +envelope() TW_envelope
        +from_requirements(aero, prop, json_path, classMap, WS_range)$
    }
    class TailSizingBase {
        <<abstract handle>>
        +size(S_ref,b,cbar,L_HT,L_VT)*
    }
    class ControlSurfaceSizer {
        <<handle>>
        +size(geom) result
    }
    class PointPerformanceBase {
        <<abstract handle>>
        +WS_RANGE_BRANDT
        +WS_RANGE_SIZING
        +constraint_residual(dp)*
    }
    class MissionSegment {
        <<abstract handle>>
        +step(W_before, ctx)
        +fuel_burn(ctx)*
    }
    class AircraftState {
        <<value class>>
        +rho, q, V, mach, altitude_ft
        +theta, delta
    }

    AerodynamicsBase <|-- AeroModelL1
    AerodynamicsBase <|-- AeroModelL2
    AerodynamicsBase <|-- AeroModelL3
    AeroModelL1 <|-- F16AeroL1
    AeroModelL2 <|-- F16AeroL2
    AeroModelL3 <|-- F16AeroL3

    PropulsionBase <|-- PropulsionModelL1
    PropulsionBase <|-- PropulsionModelL2
    PropulsionModelL1 <|-- F16PropL1
    PropulsionModelL2 <|-- F16PropL2

    WeightsBase <|-- WeightsModelL1
    WeightsBase <|-- WeightsModelL2
    WeightsBase <|-- WeightsModelL3
    WeightsModelL1 <|-- F16WeightsL1
    WeightsModelL2 <|-- F16WeightsL2
    WeightsModelL3 <|-- F16WeightsL3

    GeometryBase <|-- GeometryModelL1
    GeometryBase <|-- GeometryModelL2
    GeometryBase <|-- GeometryModelL3
    GeometryModelL1 <|-- F16GeomL1
    GeometryModelL2 <|-- F16GeomL2
    GeometryModelL3 <|-- F16GeomL3

    MissionAnalysisBase <|-- MissionAnalysisL1
    MissionAnalysisBase <|-- MissionAnalysisL2

    TailSizingBase <|-- TailSizingModelL1
    TailSizingModelL1 <|-- F16TailL1

    PointPerformanceBase <|-- Both_WbyS_TbyW
    PointPerformanceBase <|-- Only_WbyS
    PointPerformanceBase <|-- Only_TbyW
    Both_WbyS_TbyW <|-- MasterEquationConstraint
    Both_WbyS_TbyW <|-- TakeoffConstraint
    MasterEquationConstraint <|-- LevelFlightConstraint
    MasterEquationConstraint <|-- SustainedTurnConstraint
    MasterEquationConstraint <|-- ExcessPowerConstraint
    Only_WbyS <|-- LandingConstraint
    Only_WbyS <|-- StallConstraint

    MissionSegment <|-- FixedFractionSegment
    MissionSegment <|-- BreguetRangeSegment
    MissionSegment <|-- BreguetEnduranceSegment
    MissionSegment <|-- TakeoffSegment
    MissionSegment <|-- CombatSegment
    MissionSegment <|-- MasterEquationSegment
    MasterEquationSegment <|-- ClimbSegment
    MasterEquationSegment <|-- CruiseSegment
    MasterEquationSegment <|-- LoiterSegment

    SizingLoopL1 o-- AerodynamicsBase
    SizingLoopL1 o-- PropulsionBase
    SizingLoopL1 o-- WeightsBase
    SizingLoopL1 o-- GeometryBase
    SizingLoopL1 o-- MissionAnalysisBase
    SizingLoopL1 o-- ConstraintAnalysis

    SizingLoopL2 o-- AerodynamicsBase
    SizingLoopL2 o-- PropulsionBase
    SizingLoopL2 o-- WeightsBase
    SizingLoopL2 o-- GeometryBase
    SizingLoopL2 o-- MissionAnalysisBase
    SizingLoopL2 o-- ConstraintAnalysis
    SizingLoopL2 o-- TailSizingBase
    SizingLoopL2 o-- ControlSurfaceSizer

    ConstraintAnalysis o-- PointPerformanceBase
    MissionAnalysisBase o-- MissionSegment
    PointPerformanceBase ..> AircraftState
    MissionSegment ..> AircraftState
```

---

## 12. Difference summary, L1 against L2 and L3

| Item | `SizingLoopL1` | `SizingLoopL2`, used by L2 and L3 |
| --- | --- | --- |
| State variables | `W_TO` | `W_TO` and `T_SL` |
| Injected objects | 6 | 8, with `tail` and `ctrl` added |
| `con.optimal_point()` | One time, before the loop | Every iteration, plus one time after |
| Why | L1 aero is geometry-free and the L1 thrust lapse is self-normalized, so the envelope cannot move | `geom.S_ref` and `prop.T_SL` both move `S_wet`, therefore `CD0`, therefore every curve |
| `S_ref` | Solved, `W_TO / WS_opt` | Solved, `W_TO / WS_opt` |
| `prop.T_SL` inside the loop | Write-only, no reader | Read by `geom.T_AB_SLS_lb`, by the weights engine terms, and by the `TakeoffSegment`, `ClimbSegment` and `CombatSegment` |
| Tail and control surfaces | Not sized | Sized every iteration, tail first |
| Convergence test | `abs(W_TO_new - W_TO) < tol` | The same test on `W_TO` **and** on `T_SL` |
| Closure | Raymer Eq. 3.4, with the Nicolai Eq. 5.1 fallback | The same |
| `history` fields | 6 | 15 |

---

## 13. Source files

| Diagram | Primary source |
| --- | --- |
| 1, 2 | `src/sizing/SizingLoopL1.m`, `examples/F16A/design_study_01_L1.m` |
| 3, 4 | `src/sizing/SizingLoopL2.m`, `examples/F16A/design_study_02_L2.m`, `design_study_03_L3.m` |
| 5 | `src/constraints/*.m`, `examples/F16A/F16ConstraintSet.m`, `jsons/f16a_requirements.json` |
| 6, 7 | `src/core/mission/**`, `jsons/f16a_requirements.json` CAP profile |
| 8 | `src/disciplines/tail_sizing/TailL1.m`, `examples/F16A/F16TailL1.m`, `src/sizing/ControlSurfaceSizer.m`, `examples/F16A/f16a_control_surfaces.m` |
| 9 | `src/disciplines/weights/WeightsL*.m`, `examples/F16A/F16WeightsL*.m` |
| 10 | `examples/F16A/F16GeomL2.m`, `F16GeomL3.m`, `src/disciplines/geometry/GeomL2.m`, `GeomL3.m` |
| 11 | `src/base/*.m`, the full `src/` and `examples/F16A/` trees |

# Work Routing

How to decide who handles what in AOE 4065 Air Vehicle Design.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|---------|
| Requirements, RFP, MoMs | Ripley | "Define the F-16A mission profile", "What's the TOGW threshold?" |
| Gate review, traceability | Hicks | "Review this plan", "Is this implementation complete?", "Go/no-go on merge" |
| MATLAB OOP, class design, PR review | Bishop | "Design the abstract aerodynamics class", "Review Drake's PR" |
| Sizing loop, xDSM, trade studies | Hudson | "Wire up the sizing loop", "Run a T/W vs W/S sweep" |
| Aerodynamics code (drag_polar, CLmax) | Drake | "Implement Level II drag polar", "Code the skin friction build-up" |
| Propulsion code (thrust_lapse, TSFC) | Gorman | "Implement Mattingly TSFC", "Code the thrust lapse model" |
| Weights code (OEW) | Apone | "Implement Level I OEW fraction", "Code Raymer component weights" |
| Geometry code (S_ref, S_wet, planform) | Ferro | "Implement the geometry class", "Code the Brandt geometry sheet" |
| Stability & Control (tail sizing, static margin) | Frost | "Size the horizontal tail", "Compute static margin" |
| Mission analysis (fuel burn, segments) | Dietrich | "Implement the 7-segment mission", "Code the Breguet cruise segment" |
| Constraint analysis (T/W vs W/S diagram) | Burke | "Build the constraint diagram", "Find the optimal W/S and T/W" |
| F-16A validation, Brandt spec | Dallas | "Validate Level I TOGW", "Write the Level-Brandt spec" |
| Session logging, decision merging | Scribe | Automatic — never needs routing |
| Code review | Bishop | Review PRs, check OOP quality, enforce interface contracts |
| Testing | Discipline specialist + Bishop | Write MATLAB unit tests, integration tests |
| Scope & priorities | Ripley + Hicks | What to tackle next, fidelity-level advancement |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Ralph |
| `squad:{name}` | Pick up issue and complete the work | Named member |

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "What is Brandt's value for CD0?" if it's in Dallas's charter.
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If Vasquez is implementing a discipline, spawn Dallas to prepare validation comparisons simultaneously.
7. **Handoff gates are mandatory.** Never skip Hicks' go/no-go, even under time pressure.
8. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. Ralph handles all `squad` (base label) triage.

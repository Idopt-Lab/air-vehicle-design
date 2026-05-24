# AOE 4065 Air Vehicle Design — Constitution

## Core Principles

### I. Equations Are Given, Not Discovered

Every discipline class must implement only equations explicitly provided by the professor (Raymer, Mattingly, Brandt, Nikolai, Roskam, etc.). No agent, no AI, no team member invents or looks up their own formulas. Every equation in code must be cited in a comment: author, edition, equation number (e.g., `% Raymer 6th ed, Eq 12.30`). Uncited equations are rejected at code review.

### II. Ground Truth Is the F-16A (Brandt-F16-A.xls)

Every numeric output must be compared to `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls` with a % difference reported. The comparison must cite the specific Excel cell (e.g., `Size&Opt!B14`). Ballpark agreement is acceptable at lower fidelity levels per the tolerance bands defined below. Unacceptable divergence blocks progress.

**Tolerance bands (% difference vs. Brandt XLS):**

| Variable | Level I | Level II | Level III | Level-Brandt |
|----------|---------|----------|-----------|--------------|
| TOGW | ±15% | ±10% | ±5% | ±1% |
| OEW | ±15% | ±10% | ±5% | ±1% |
| S_ref | ±20% | ±15% | ±10% | ±1% |
| T0 | ±20% | ±15% | ±10% | ±1% |
| Fuel used | ±20% | ±15% | ±10% | ±1% |
| LD_max | ±15% | ±10% | ±5% | ±1% |

### III. No Code Is Merged Without Gate Approval

Hicks reviews every plan and checks traceability before any implementation agent executes. Implementation agents cannot start until Hicks issues "go." Bishop reviews all MATLAB code for OOP compliance before Hicks gates the merge. Dallas's validation report is a hard gate before any Level II+ implementation is accepted.

### IV. Fidelity Levels Build on Each Other

Level II must produce results consistent with Level I trends. Level III consistent with Level II. A higher-fidelity model that produces a wildly different answer must explain why with a physics reason, not "there might be a code bug." Only Ripley can authorize moving from one fidelity level to the next.

### V. The Sizing Loop Is the Integration Contract

Every discipline agent must produce outputs that feed the sizing loop without modification by another agent. The five abstract method names — `drag_polar`, `CLmax`, `thrust_lapse`, `TSFC`, `OEW` — are frozen. No agent changes these signatures without an ADR approved by Bishop and Hudson.

### VI. English Units — No Exceptions

All weights in **lbf**, areas in **ft²**, distances in **ft**, altitudes in **ft**, thrust in **lbf**, TSFC in lb/hr/lb. Do not mix unit systems. Unit conversions must be explicit and commented. `AircraftState` stores all atmospheric quantities in English units.

### VII. OOP Contract — Abstract Base Classes First

Bishop defines abstract base classes before Vasquez writes any concrete implementation. The Gold Standard pattern is `WeightEstimationStrategy` + `RaymerWeightEstimation` in `src/Disciplines/Weight/`. Every discipline abstract class must declare: required properties (with types and validation), required methods (with signatures), and the output struct schema. No concrete physics in abstract classes.

### VIII. Level-Brandt Is Standalone

`src/level_brandt/` is a direct, faithful MATLAB reimplementation of the Brandt F-16A Excel model. It does not inherit from `Disciplines/` or `ComputationModels/`. It uses static methods only. It is the definitive reference implementation against which all higher-fidelity levels are calibrated. Dallas owns its spec; Vasquez implements it.

## Agent Governance

| Agent | Decision Authority |
|-------|-------------------|
| Ripley | Requirements, MoMs, fidelity-level advancement |
| Hicks | go/no-go on plans; go/no-go on merges |
| Bishop | OOP architecture, interface signatures, PR approval |
| Hudson | I/O contracts, sizing loop sequencing |
| Vasquez | Physics implementation choices (within prof-provided equations) |
| Dallas | Level-Brandt spec, validation pass/fail determination |

## Development Workflow

```
1. Ripley issues work package brief (written, versioned)
2. Hicks: go/no-go against requirements + traceability matrix
3. Bishop + Hudson: define abstract interfaces + xDSM (co-authored plan.md)
4. Hicks: go/no-go on interface plan
5. Vasquez: implement concrete classes
6. Bishop: PR code review (OOP compliance)
7. Dallas: F-16A validation report (% diff vs. Brandt)
8. Hicks: merge gate approval
9. Ripley: fidelity-level advancement decision
```

## Governance

This Constitution supersedes all other practices. Amendments require:
1. A written ADR in `.squad/decisions/inbox/`
2. Approval from Ripley (if it affects requirements/tolerances) or Bishop (if it affects OOP contracts)
3. Update to this document

**Version:** 1.0.0 | **Ratified:** 2026-05-24 | **Last Amended:** 2026-05-24


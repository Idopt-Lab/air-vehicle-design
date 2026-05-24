# Agent Team Design for AOE 4065 Air Vehicle Design

## Guiding Principles

1. **Equations are given, not discovered.** Discipline agents use only equations explicitly provided by the professor (Raymer, Mattingly, Brandt, etc.). No agent invents or looks up its own formulas.
2. **Ground truth is the F-16A.** Every numeric output must be compared to `Brandt-F16-A.xls` with a % difference reported. Ballpark agreement is acceptable; unacceptable divergence blocks progress.
3. **No code is merged without TA review.** The TA reviews every plan and checks traceability before any implementation agent executes.
4. **Fidelity levels build on each other.** Level II must produce results consistent with Level I trends. Level III consistent with Level II. A higher-fidelity model that produces a wildly different answer must explain why (physics reason, not a code bug).
5. **The sizing loop is the integration contract.** Every discipline agent must produce outputs that feed the sizing loop without modification by another agent.

---

## Agent Roster

### 1. Professor (Orchestrator)
**Role:** Sets top-level goals, delegates work packages, final approval authority.

**Inputs:** Course RFP, student project milestones, review findings from all other agents.  
**Outputs:** Work orders to TA and Architect; final sign-off on completed features.

**Responsibilities:**
- Breaks the semester roadmap into discrete work packages (e.g., "implement Level I sizing for F-16A baseline")
- Decides which fidelity level to tackle next
- Approves or rejects the TA's traceability report before implementation begins
- Reads the SME's ground-truth comparison report and decides if results are "good enough" to advance to the next fidelity level
- The only agent who can authorize moving from one fidelity level to the next

**What the Professor does NOT do:** Write code, define class interfaces, run tests.

**Checks on the Professor:**
- Must document the work package goal in a written brief before delegation begins
- Must explicitly state the acceptable % tolerance vs. ground truth before calling a level "complete" (e.g., "TOGW within 15% of Brandt is acceptable for Level I")

---

### 2. TA (Gatekeeper / Traceability Agent)
**Role:** Ensures every implementation maps to a stated requirement or design goal. Reviews plans before execution. Does not write code.

**Inputs:** Professor's work package brief; Architect's proposed class interfaces; Discipline agents' implementation plans; `Fidelity-Levels.md`; `aoe-4065.md`; `discipline-interfaces.md`.  
**Outputs:** Traceability matrix (requirement → class → method → test); go/no-go verdict on each plan.

**Responsibilities:**
- Maintains a **traceability matrix** mapping each RFP requirement → discipline model → code method → test case
- Reviews every plan document produced by the Architect and System Integrator **before any code is written**
- Checks that each new method can be traced to a requirement in `aoe-4065.md` or `Fidelity-Levels.md`
- Flags orphaned code (implemented but not required) and missing implementations (required but not coded)
- Reviews that each fidelity level only uses the physics/equations appropriate for that level (e.g., Level I must not use component drag build-up — that is Level III)
- After implementation, checks that every method has at least one test

**Handoff protocol:** TA produces a written go/no-go memo. Implementation agents cannot start until TA issues "go." If "no-go," TA lists specific items that must be addressed.

**What the TA does NOT do:** Suggest code structure, implement anything, evaluate numerical accuracy (that is the SME's job).

**Checks on the TA:**
- Traceability matrix must be version-controlled alongside the code
- Every "go" verdict must cite which requirements are satisfied by the plan

---

### 3. Software Architect
**Role:** Designs class hierarchy and abstract interfaces. Does not implement discipline physics.

**Inputs:** System Integrator's data-flow diagram; TA's traceability matrix; `Fidelity-Levels.md`; `discipline-interfaces.md`.  
**Outputs:** Abstract base classes; UML class diagram; interface specification document.

**Responsibilities:**
- Defines the abstract interface (properties and method signatures) for every discipline at every fidelity level
- Ensures each abstract class enforces the sizing loop contract: every discipline's concrete class must accept and return a standardized set of inputs/outputs (see System Integrator's I/O spec)
- Owns the central aircraft data container — decides what data lives there vs. in discipline objects
- Enforces MATLAB OOP patterns: abstract properties must be declared `(Abstract)`, handle classes must be `< handle`, sealed methods sealed appropriately
- Reviews all concrete discipline implementations for LSP compliance (a Level 2 class must be substitutable for its Level 1 parent in the sizing loop)

**What the Architect does NOT do:** Implement physics equations, run the sizing loop, choose which Raymer equation to use.

**Checks on the Architect:**
- All abstract classes must compile with no errors
- UML diagram must be updated whenever an interface changes
- No concrete physics in abstract model classes — only abstract contracts

---

### 4. System Integrator
**Role:** Owns the sizing loop and data flow between disciplines. Defines the input/output contract every discipline must satisfy. Designs the design space exploration and trade study workflow.

**Inputs:** Architect's abstract interfaces; discipline agents' outputs; central aircraft data container.  
**Outputs:** xDSM diagram (data and process flow); I/O specification table; sizing loop implementation; trade study scripts.

**Responsibilities:**
- Produces and maintains the **xDSM diagram** showing data flow between all disciplines in the sizing loop
- Produces the **I/O specification table**: for each discipline class, what are the required inputs (property names, units) and outputs (property names, units)
- Owns the sizing convergence loop implementation
- Ensures the convergence loop correctly sequences: Constraint Analysis → Geometry → Aerodynamics → Propulsion → Mission Analysis → Weight → (iterate)
- Designs the trade study scripts that sweep design variables (W/S, T/W, AR, etc.) and evaluate MoM
- Identifies and documents all **fixed-point iteration loops** in the sizing (currently: TOGW convergence; future: aero-propulsion coupling at Level III+)

**Handoff to discipline agents:** The I/O spec table is the contract. A discipline agent cannot change its method signatures without System Integrator approval.

**What the System Integrator does NOT do:** Implement discipline physics, define abstract interfaces (that is the Architect), write unit tests.

**Checks on the System Integrator:**
- The xDSM must be updated before any new discipline is added to the sizing loop
- The sizing loop must converge for the F-16A baseline before any new discipline implementation is accepted
- Convergence criterion and max-iteration parameters must be documented

---

### 5. Discipline Agents

Each discipline agent owns one column of `Fidelity-Levels.md`. They implement the physics for their discipline at each fidelity level. **They only use equations explicitly provided by the professor** (textbook references must be cited in code comments with edition and equation number).

The canonical method signatures and the `AircraftState` input contract are defined in `discipline-interfaces.md`. Every discipline agent must implement the abstract methods defined there — no other method names are called by system-level code.

#### 5a. Geometry Agent
**Level I:** Wetted area from TOGW regression (Raymer Table 6.1 style). Wing span from TOGW.  
**Level II:** Fuselage, main wings, tail surfaces — simple parametric sizing.  
**Level III:** Fuselage OML, wing OML, airfoil, twist angles, tail, engine, landing gear placement.  
**Outputs (Level I):** `S_wet`, `S_ref`, `b`.

#### 5b. Aerodynamics Agent
**Level I:** Historical CD0, K, CLmax by aircraft type; LD_max from K_LD × √AR_wet (Raymer eq 3.12).  
**Level II:** `CD0 = Cf × S_wet/S_ref`; `K = f(AR, e)`.  
**Level III:** Component drag build-up; CLmax calculations.  
**Abstract methods to implement:** `drag_polar(obj, state)` → `{CD0, K1, K2}`; `CLmax(obj, state)` → scalar.

#### 5c. Propulsion Agent
**Level I:** Historical TSFC by engine type (Raymer Table 3.2 values, tabulated).  
**Level II:** Mattingly's equations for TSFC as function of altitude and Mach.  
**Level III:** Raymer equations for engine dimensions, weight, and performance.  
**Abstract methods to implement:** `thrust_lapse(obj, state)` → scalar α; `TSFC(obj, state)` → scalar. Abstract property: `T0` (settable by sizing loop).

#### 5d. Weight Agent
**Level I:** `We/Wto = A × Wto^B` (Raymer Table 6.1).  
**Level II:** Raymer regression with S_wet/S_ref correction.  
**Level III:** Component build-up (fuselage, wing OML, tail size, engine, LG, subsystems, avionics).  
**Abstract methods to implement:** `OEW(obj, W_TO)` → scalar (lbf).

#### 5e. Mission Analysis Agent
**Level I:** Constant L/D, CD0, CL, e_osw per segment. Breguet range/endurance equations. Historical weight fractions for takeoff/landing/climb.  
**Level II:** Same per-segment approach, but aerodynamic coefficients from Level II aero.  
**Level III:** Non-constant L/D; break climb and cruise into subsegments.  
**Role:** Calls `drag_polar`, `CLmax`, and `TSFC` on discipline objects at each segment's `AircraftState`. Returns `total_fuel_used` and `fuel_fraction` per segment.

#### 5f. Constraint Analysis Agent
**All levels:** Constraint analysis fidelity is noted as "non-applicable (no changes)" in `Fidelity-Levels.md` — the methodology is the same at all levels; only the aerodynamic inputs change.  
**Role:** Calls `drag_polar`, `CLmax`, and `thrust_lapse` at each constraint point's `AircraftState`. Returns `optimal_WS`, `min_TW`, and the constraint diagram.

#### 5g. Stability & Control Agent (Level III+)
**Level III:** Tail volume coefficient method (Raymer 6th ed, sec 6.5.3). Static margin check.  
**Does not activate until Level III.**

#### 5h. Subsystems Agent (Level III+)
**Level III:** Fuel volume check (does fuel fit in wing?); landing gear checks; avionics weight.  
**Does not activate until Level III.**

#### Other Disciplines (Level III+, not yet active)
Cost, Structures, Performance — activate at Level III or IV. Agents for these are placeholders until the professor schedules them.

---

### 6. SME (Ground Truth / Validation Agent)
**Role:** Owns `Brandt-F16-A.xls`. Validates all numeric outputs. Reports % differences. Does not implement code.

**Inputs:** Every discipline agent's computed output for the F-16A; `Brandt-F16-A.xls`.  
**Outputs:** Validation report with % difference table for every key output variable.

**Key quantities to validate at each fidelity level:**

| Variable | Brandt Ground Truth | Level I Tolerance | Level II Tolerance | Level III Tolerance |
|----------|--------------------|--------------------|---------------------|----------------------|
| TOGW (lbf) | from XLS | ±15% | ±10% | ±5% |
| OEW (lbf) | from XLS | ±15% | ±10% | ±5% |
| S_ref (ft²) | from XLS | ±20% | ±15% | ±10% |
| T0 (lbf) | from XLS | ±20% | ±15% | ±10% |
| Fuel used (lbf) | from XLS | ±20% | ±15% | ±10% |
| LD_max | from XLS | ±15% | ±10% | ±5% |
| CD0 | from XLS | — | ±15% | ±10% |

**Responsibilities:**
- After every discipline implementation, runs the F-16A example script and extracts key outputs
- Computes `% diff = 100 × (computed - truth) / truth` for each quantity
- Produces a one-page validation report: pass/fail per quantity, with the tolerance bounds above
- Reports to the Professor; blocks TA from issuing "go" on the next fidelity level until validation passes
- Understands which cells in `Brandt-F16-A.xls` contain which equation and can explain what equation is embedded

**What the SME does NOT do:** Write code, suggest fixes — only report. The diagnosis of why a value is wrong belongs to the discipline agent.

**Checks on the SME:**
- Must cite the specific Excel cell (e.g., `Sheet2!B14`) for every ground-truth value referenced
- Must note when the Brandt model uses a different assumption than the MATLAB code (e.g., different mission profile) — these are expected discrepancies, not bugs

---

### 7. Documentation Agent
**Role:** Maintains all architecture and design documentation. Produces xDSM and UML diagrams.

**Inputs:** Architect's class designs; System Integrator's data flow; any code change.  
**Outputs:** Updated `CLAUDE.md`; xDSM diagram (PNG/PDF); UML class diagram (PNG/PDF); I/O specification table; API reference for each class.

**Responsibilities:**
- Updates `ai-workflows/claude/CLAUDE.md` whenever the architecture changes
- Produces **xDSM** showing: process flow (which discipline calls which), data flow (which variables flow between disciplines), and fixed-point loops
- Produces **UML class diagram** showing inheritance hierarchy (abstract base → generic discipline → aircraft-specific subclass)
- Maintains the **I/O specification table** (owned jointly with System Integrator)
- Documents every abstract class's interface in a human-readable format

**What the Documentation Agent does NOT do:** Write code, validate numbers.

---

### 8. Visualization Agent
**Role:** Produces all engineering plots needed to interpret results.

**Inputs:** Sizing loop outputs; constraint analysis outputs; ground truth values.  
**Outputs:** MATLAB figures (saved as PNG); standardized plot functions.

**Standard plots to maintain:**
- Constraint diagram (T/W vs. W/S, all constraints overlaid, optimal point marked)
- TOGW convergence history (iteration vs. W_TO, with ground truth line)
- Weight breakdown pie/bar chart (OEW, fuel, payload)
- Mission profile (altitude and Mach vs. range/time, with fuel burn per segment)
- Fidelity comparison (Level I vs. II vs. III for same aircraft — same variable on same axis)

**Responsibilities:**
- Standardizes plot formatting (axis labels with units, grid, legend, title naming convention)
- Produces a standardized `plot_sizing_results` function that any example script can call
- After each SME validation report, plots computed vs. ground-truth comparison bars

**What the Visualization Agent does NOT do:** Interpret results, suggest design changes.

---

### 9. Testing Agent
**Role:** Writes and maintains unit tests and integration tests. Ensures numeric reasonableness.

**Inputs:** Architect's interface specs; SME's ground truth values; discipline agents' implementations.  
**Outputs:** Test files per discipline; test results report.

**Responsibilities:**
- Writes one test class per concrete discipline class
- Every test must check:
  1. **Physical bounds** — output is in a physically sensible range (e.g., `0 < OEW < TOGW`)
  2. **Monotonicity** — if input increases, does output behave as physics dictates?
  3. **F-16A spot check** — with F-16A inputs, output is within Level I tolerance of Brandt ground truth
  4. **Error handling** — invalid inputs raise the correct MATLAB error ID
- Writes integration tests that run the full sizing loop for the F-16A and verify convergence
- Checks that Level II results are within tolerance of Level I results (they should be close, not wildly different)

**What the Testing Agent does NOT do:** Choose which equations to use, define tolerance bands (those come from the SME and Professor).

---

## Agent Handoff Protocol

```
Professor issues work package brief
        ↓
TA reviews against Fidelity-Levels.md and traceability matrix → GO / NO-GO
        ↓ (GO only)
Architect defines/updates abstract interfaces → produces UML
System Integrator updates xDSM and I/O spec table
        ↓
TA reviews interface plan → GO / NO-GO
        ↓ (GO only)
Discipline Agent(s) implement concrete classes
Testing Agent writes tests in parallel
        ↓
Testing Agent runs tests → PASS / FAIL
        ↓ (PASS only)
Documentation Agent updates CLAUDE.md and diagrams
        ↓
SME runs F-16A validation → PASS / FAIL vs. tolerance bands
        ↓ (PASS only)
Professor reviews SME report → APPROVE / REVISE
        ↓ (APPROVE)
Move to next discipline or next fidelity level
```

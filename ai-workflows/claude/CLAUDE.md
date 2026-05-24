# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository implements an **aircraft sizing framework** for the AOE 4065 Air Vehicle Design course at Virginia Tech. Student teams receive an RFP, then use this framework to size aircraft concepts, make quantitative trades, and select a Preferred System Concept (PSC).

The F-16A (Block 10/15) is used as the **baseline validation aircraft** — since it is already designed, its known geometry and performance data serve as ground truth for verifying each model.

## Language & Runtime

All source code is **MATLAB** (`.m` files). There is no Python, build system, or package manager. Everything runs inside a MATLAB session.

## Key Definitions

- **Mission analysis** — walks through each mission segment and computes total fuel burn (or battery energy)
- **Constraint analysis** — translates point performance requirements into required thrust loading (T/W) and wing loading (W/S)
- **Weight estimation** — estimates operating empty weight (OEW)
- **Sizing** — uses the above three analyses together to converge on TOGW, sea-level static thrust (T₀), and wing reference area (S_ref)

## Discipline Interfaces

Full interface definitions are in `ai-workflows/discipline-interfaces.md`. Key points for coding:

**`AircraftState`** is the common input to all discipline calculations. Constructed as `AircraftState(altitude_ft, mach)`. It automatically calls `atmosisa` and stores atmospheric properties (T, P, ρ, a) and derived quantities (V, q) in English units. The underlying 12×1 state vector is always available but not needed for AOE 4065 fidelity levels.

**Five abstract methods** are the only names system-level code ever calls:

| Method | Discipline | Returns |
|--------|-----------|---------|
| `drag_polar(obj, state)` | Aerodynamics | struct: `{CD0, K1, K2}` |
| `CLmax(obj, state)` | Aerodynamics | scalar |
| `thrust_lapse(obj, state)` | Propulsion | scalar α (0–1) |
| `TSFC(obj, state)` | Propulsion | scalar (1/s) |
| `OEW(obj, W_TO)` | Weights | scalar (lbf) |

Swapping a Level I implementation for a Level III one requires no changes to constraint analysis, mission analysis, or the sizing loop.

**`AircraftControl`** (control effectors, control vector) is out of scope for AOE 4065. It is deferred to AOE 4066.

## Fidelity Levels

Full fidelity level definitions are in `ai-workflows/Fidelity-Levels.md`. The framework is organized into four fidelity levels. Higher levels require more geometric detail but allow finer discrimination between aircraft concepts.

| Level | Conceptual Goal | Aerodynamics | Weights | Propulsion | Geometry | Mission Analysis |
|-------|----------------|--------------|---------|------------|----------|-----------------|
| **I** | Cannot distinguish F-18 from F-35 | Historical CD0, K, CLmax by aircraft type | `We/Wto = A * Wto^-B` (Raymer Table 6.1) | Historical TSFC by engine type | Bare minimums for regressions | Constant L/D, CD0, CL, e_osw per segment |
| **II** | Distinguish within a category (fighter vs. fighter) | `CD0 = f(Swet/Sref)`, `K = f(AR, e)` | `We/Wto = f(Raymer)` | Mattingly's equations | Fuselage, main wings, tail | Constant L/D, CD0, CL, e_osw per segment |
| **III** | Meaningfully compare 4 concepts → select PSC | Component drag build-up, CLmax calculations | Component build-up (fuselage, wing OML, tail size, engine, LG, subsystems) | Raymer equations for dimensions, weight, performance | Fuselage, wings, tail, engine, landing gear; airfoils, twist angles | Non-constant L/D; break climb & cruise into subsegments |
| **IV** | (Higher fidelity, in development) | — | — | — | — | — |

Stability & Control and Systems (fuel volume check, LG checks) enter at **Level III**.

## Agent Team

The full agent team design is in `ai-workflows/claude/agent-team.md`. Summary:

| Agent | Owns | Does NOT do |
|-------|------|-------------|
| **Professor** | Top-level goals, fidelity-level advancement decisions, final approval | Write code, define interfaces |
| **TA** | Traceability matrix; go/no-go before every implementation | Implement anything |
| **Architect** | Abstract interfaces; central data container; UML | Implement physics |
| **System Integrator** | Sizing loop; xDSM; I/O spec table; trade studies | Define abstract interfaces |
| **Discipline Agents** | Concrete implementations per discipline per fidelity level | Invent equations |
| **SME** | `Brandt-F16-A.xls` validation; % difference reports | Write code or suggest fixes |
| **Documentation** | `CLAUDE.md`; xDSM; UML diagrams; I/O spec table | Write code |
| **Visualization** | Standardized engineering plots | Interpret results |
| **Testing** | Unit + integration tests per discipline | Choose equations or tolerances |

**Handoff order:** Professor → TA (go/no-go) → Architect + Integrator → TA (go/no-go) → Discipline + Testing agents → Documentation → SME → Professor.

**Non-negotiable rule:** Discipline agents use **only equations explicitly provided by the professor**. Textbook reference (author, edition, equation number) must be cited in the code comment. No agent finds its own formulas.

**Ground truth tolerance bands (% difference vs. Brandt XLS):**

| Variable | Level I | Level II | Level III |
|----------|---------|----------|-----------|
| TOGW | ±15% | ±10% | ±5% |
| OEW | ±15% | ±10% | ±5% |
| S_ref | ±20% | ±15% | ±10% |
| T0 | ±20% | ±15% | ±10% |
| Fuel used | ±20% | ±15% | ±10% |
| LD_max | ±15% | ±10% | ±5% |

## Units Convention

All weights in **lbf**, areas in **ft²**, distances/ranges in **ft**, altitudes in **ft**, thrust in **lbf**. TSFC in lb/hr/lb (Level I/II). Do not mix unit systems.

## Physics Constraints to Preserve

- Closure equation: `W_TO = OEW + W_fixed + W_fuel`
- OEW bounds: `0 < OEW < TOGW`; fighter OEW/TOGW typically 50–90%
- `W/S` and `T/W` come from the constraint diagram — never free parameters
- Higher-fidelity models must produce results consistent with (or traceable from) lower-fidelity results

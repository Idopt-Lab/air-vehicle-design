# Discipline Interfaces

## Design Goal

System-level calculations (constraint analysis, mission analysis, sizing loop) must call the same method names regardless of fidelity level or aircraft. A user who defines a new aircraft or a new fidelity level implements the discipline methods — they do not touch the system-level code.

Every discipline method that depends on the flight state accepts an `AircraftState` object as input. In AOE 4065, all fidelity levels read only altitude and Mach from it. The method signature does not change.

---

## AircraftState

`AircraftState` is the common input to all discipline calculations. It represents the flight condition used by the discipline methods in AOE 4065.

### Constructor

```matlab
state = AircraftState(altitude_ft, mach)
```

This is the minimum required input. Everything else is computed automatically or defaults to straight-and-level trimmed flight (zero sideslip, zero angular rates, wings level).

### What the constructor computes automatically

On construction from `(altitude_ft, mach)`, the object immediately:

1. Converts altitude to meters and calls MATLAB's `atmosisa` to get the standard atmosphere at that altitude
2. Stores all atmospheric properties in English units (the framework's unit convention)
3. Computes airspeed, dynamic pressure, and angle of attack from the velocity components
4. Populates the 12×1 state vector

The student does not need to call `atmosisa` or compute `q` manually — those are always available as named properties.

### Properties

**Set at construction (always available):**

| Property | Description | Units |
|----------|-------------|-------|
| `altitude` | Pressure altitude | ft |
| `mach` | Mach number | — |
| `T_atm` | Ambient temperature | °R |
| `P_atm` | Ambient pressure | lbf/ft² |
| `rho` | Air density | slug/ft³ |
| `a` | Speed of sound | ft/s |
| `V` | True airspeed (`mach * a`) | ft/s |
| `q` | Dynamic pressure (`0.5 * rho * V²`) | lbf/ft² |

**Velocity components (body frame), default zero except `u`:**

| Property | Description | Units | Default |
|----------|-------------|-------|---------|
| `u` | Forward velocity | ft/s | `V` |
| `v` | Lateral velocity (positive right) | ft/s | 0 |
| `w` | Vertical velocity (positive down) | ft/s | 0 |

**Derived from velocity components:**

| Property | Description | Units |
|----------|-------------|-------|
| `alpha` | Angle of attack (`atan2(w, u)`) | rad |
| `beta` | Sideslip angle (`asin(v / V)`) | rad |

**Attitude and rates (default to trimmed level flight):**

| Property | Description | Units | Default |
|----------|-------------|-------|---------|
| `phi` | Roll angle | rad | 0 |
| `theta` | Pitch angle | rad | `alpha` (trimmed) |
| `psi` | Heading angle | rad | 0 |
| `p`, `q_rate`, `r` | Roll, pitch, yaw rates | rad/s | 0 |

**Full state vector (always kept consistent):**

| Property | Description |
|----------|-------------|
| `x` | 12×1 column vector: `[p_N; p_E; p_D; u; v; w; phi; theta; psi; p; q_rate; r]` |

The state vector ordering follows the North-East-Down (NED) convention: position first, then body velocities, then Euler angles, then angular rates. Any setter that updates a named property (e.g., `set_alpha`) automatically updates `x` to stay consistent.

### How fidelity levels use AircraftState

| Fidelity | What the discipline reads |
|----------|--------------------------|
| Level I | `state.altitude`, `state.mach` |
| Level II | + `state.V`, `state.q`, `state.rho` |
| Level III | + `state.alpha`, `state.beta`, full `state.x` |
| Research / grad | Full state vector, angular rates |

A Level I aerodynamics implementation only reads `state.mach` and `state.altitude`. A vortex-lattice aerodynamics implementation might read `state.alpha` and `state.beta`. The calling code passes the same `AircraftState` object either way.

---

## AircraftControl

`AircraftControl` is out of scope for AOE 4065 discipline interfaces.

For all implemented fidelity levels in this course, discipline methods do not consume controls or a control vector.

Detailed control-effector definitions and control interfaces are intentionally deferred to AOE 4066.

---

## What System-Level Calculations Consume

### Constraint Analysis

| Quantity | Source | Notes |
|----------|--------|-------|
| `CD0` | `aero.drag_polar(state)` | Zero-lift drag coefficient |
| `K1` | `aero.drag_polar(state)` | Linear CL term |
| `K2` | `aero.drag_polar(state)` | Induced drag: `1/(π·e·AR)` |
| `CLmax` | `aero.CLmax(state)` | For stall and landing constraints |
| `α` (thrust lapse) | `prop.thrust_lapse(state)` | Thrust ratio at condition vs. T_SLS |
| `q` | `state.q` | Computed automatically by AircraftState |
| `β` | Set per constraint point | Fraction of W_TO at that constraint |

### Mission Analysis

Mission analysis computes fuel burn over mission segments using discipline calls at each segment condition.

| Quantity | Source | Notes |
|----------|--------|-------|
| `CD0`, `K1`, `K2` | `aero.drag_polar(state)` | Per segment |
| `CLmax` | `aero.CLmax(state)` | For climb ceiling, maneuver segments |
| `TSFC` | `prop.TSFC(state)` | Per segment flight condition |
| `q` | `state.q` | From AircraftState |
| `OEW` | `weights.OEW(W_TO)` | Each sizing iteration |

### Sizing Loop

The sizing loop iterates: `W_TO -> calculate fuel burn, calculate empty weight -> new W_TO`, then repeats until convergence.

Depending on implementation, a constraint-analysis call may or may not be required within each sizing-loop pass.

| Quantity | Source | Notes |
|----------|--------|-------|
| `OEW` | `weights.OEW(W_TO)` | Once per iteration |
| `fuel` | `mission.compute_fuel(...)` | Calls aero and prop internally |
| `W/S`, `T/W` | `constraint.optimal_point()` | Optimal point from constraint diagram |

---

## Abstract Interfaces

### Abstract Aerodynamics

**Abstract methods:**

```
drag_polar(obj, state)  →  struct with fields: CD0, K1, K2
```
Returns the three drag polar coefficients at the given aircraft state.
Drag model: `CD = CD0 + K1·CL + K2·CL²`

For fidelity-specific implementations, see `Fidelity-Levels.md`.

```
CLmax(obj, state)  →  scalar
```
Returns the maximum usable lift coefficient at the given state.
Used by stall speed and landing constraints, and climb ceiling calculations.

**No abstract properties.** Geometry (S_ref, AR, S_wet) lives on the Geometry object. The aerodynamics object receives geometry at construction or via a setter — it does not own geometry.

---

### Abstract Propulsion

**Abstract methods:**

```
thrust_lapse(obj, state)  →  scalar  (α, dimensionless, 0–1)
```
Returns the ratio of available thrust at the given state to sea-level static thrust T0.
Constraint analysis computes `T = α · T0`.

For fidelity-specific implementations, see `Fidelity-Levels.md`.

```
TSFC(obj, state)  →  scalar  (1/s)
```
Returns thrust-specific fuel consumption at the given state.
Mission analysis integrates fuel burn using this directly.

For fidelity-specific implementations, see `Fidelity-Levels.md`.

**Abstract property:**

```
T0  (lbf)  —  settable
```
Sea-level static thrust. The sizing loop sets this each iteration (`T0 = (T/W) · W_TO`). Every concrete propulsion class must expose this as a settable property.

---

### Abstract Weights

**Abstract methods:**

```
OEW(obj, W_TO)  →  scalar  (lbf)
```
Returns operating empty weight given a takeoff gross weight guess.
The sizing loop calls this once per iteration.

For fidelity-specific implementations, see `Fidelity-Levels.md`.

---

### Abstract Geometry

Geometry is a shared data source, not a calculation discipline. Its abstract interface defines the minimum properties the aerodynamics discipline and sizing loop are allowed to read.

**Abstract properties:**

```
S_ref   (ft²)   Wing reference area
S_wet   (ft²)   Total wetted area
```

`S_ref` and `S_wet` are required base attributes. They are not independent: when `S_ref` changes, `S_wet` must be updated consistently.

Additional geometry attributes can be defined by each fidelity implementation. For fidelity-specific detail, see `Fidelity-Levels.md`.

---

### Abstract Mission

Mission analysis computes the total fuel burned over all mission segments given discipline objects and a TOGW estimate.

**Abstract methods:**

```
compute_fuel(obj, aero, prop, W_TO, req)  →  scalar  (lbf)
```

| Argument | Type | Description |
|----------|------|-------------|
| `aero` | `AerodynamicsBase` subclass | Provides `drag_polar` and `CLmax` |
| `prop` | `PropulsionBase` subclass | Provides `TSFC` and `thrust_lapse` |
| `W_TO` | scalar (lbf) | Current takeoff gross weight guess |
| `req` | struct | Mission definition — see below |

**`req` struct required fields:**

```
req.W_payload    — payload weight (lbf)
req.S_ref        — wing reference area (ft²)
req.AR           — aspect ratio (used by L2/L3 for drag polar inversion)
req.segments     — array of structs, each with:
    .name        — 'startup','taxi','takeoff','climb','cruise','dash',
                   'combat','loiter','descent','landing'
    .altitude_ft — flight altitude (ft)
    .mach        — Mach number
    .range_ft    — segment range (ft)  for cruise/dash
    .time_min    — segment time (min)  for loiter/combat
    .W_drop      — weight jettisoned at segment end (lbf)
```

| Fidelity | Implementation |
|----------|----------------|
| L1 | Roskam fuel fractions for fixed segments; single-point Breguet with tabulated LD and TSFC for cruise/loiter. Does NOT call `aero.drag_polar` or `prop.TSFC`. |
| L2 | Calls `aero.drag_polar(state)` and `prop.TSFC(state)` for each segment; single-point Breguet per segment. |
| L3 | Same interface; cruise and climb sub-segmented (default 20 sub-segments) with L/D recomputed at each sub-segment weight. |
| L4 | Delegates to L3 logic; higher-fidelity drag and TSFC come through the L4 discipline objects. |

---

### Abstract Tail Sizing

Tail sizing is a separate discipline called only by `SizingLoopL2` and above. It is not called by `SizingLoopL1`.

**Abstract methods:**

```
size(obj, S_ref, b, cbar, L_fus)  →  struct with fields: S_HT, S_VT
```

| Argument | Description | Units |
|----------|-------------|-------|
| `S_ref` | Wing reference area | ft² |
| `b` | Wingspan | ft |
| `cbar` | Mean aerodynamic chord | ft |
| `L_fus` | Fuselage length | ft |

Returns:

| Field | Description | Units |
|-------|-------------|-------|
| `S_HT` | Horizontal tail reference area | ft² |
| `S_VT` | Vertical tail reference area | ft² |

The Level I implementation uses the Raymer tail volume coefficient method (Eq 6.28–6.29). The constructor takes `c_HT` and `c_VT` as inputs.

---

### Abstract Constraints

```
optimal_point(obj, aero, prop)  →  struct with fields: W_S, T_W
```

Returns the design point (wing loading and thrust-to-weight ratio) that satisfies all performance constraints with the minimum required T/W. The sizing loop uses this to determine S_ref (L1) or T_SL (L2).

---

## How System-Level Code Uses These Interfaces

The calling pattern is identical regardless of fidelity level or aircraft. Fidelity-specific behavior is documented in `Fidelity-Levels.md`.

### Constraint analysis (one constraint point)

```matlab
state = AircraftState(altitude_ft, mach);

polar = aero.drag_polar(state);       % {CD0, K1, K2} — same call at any fidelity
alpha = prop.thrust_lapse(state);     % scalar α — same call at any fidelity
```

### Mission segment (cruise)

```matlab
state = AircraftState(altitude_ft, mach);

polar = aero.drag_polar(state);
tsfc  = prop.TSFC(state);
```

### Sizing loop (one iteration)

Two fidelity levels of sizing loop exist. Both call only the abstract interface methods.

**`SizingLoopL1` — 1 state variable (W_TO)**

S_ref and T_SL are derived outputs:
```matlab
opt      = con.optimal_point(aero, prop);   % → struct(W_S, T_W)
S_ref    = W_TO / opt.W_S;
prop.T0  = opt.T_W * W_TO;
fuel     = miss.compute_fuel(aero, prop, W_TO, req);
oew      = weights.OEW(W_TO);
W_TO_new = oew + W_payload + fuel;
```

**`SizingLoopL2` — 2 state variables (W_TO, T_SL); S_ref is a fixed input**

Tail surfaces are sized each iteration:
```matlab
opt      = con.optimal_point(aero, prop);   % → T_W (S_ref fixed; W_S not used)
prop.T0  = opt.T_W * W_TO;
result   = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus);  % → S_HT, S_VT
fuel     = miss.compute_fuel(aero, prop, W_TO, req);
oew      = weights.OEW(W_TO);
W_TO_new = oew + W_payload + fuel;
```

Convergence is checked on both W_TO and T_SL. Both loops use under-relaxation (default 0.5) for stability.

This section defines the interface-level call flow only. Detailed equations and convergence implementation are kept in code.

The seven method names — `drag_polar`, `CLmax`, `thrust_lapse`, `TSFC`, `OEW`, `compute_fuel`, `size` — are the only names the system-level code ever calls. A new fidelity level or a new aircraft provides concrete classes that implement these methods. Nothing else changes.

---

## What This Enables

| What the user defines | What they do NOT need to touch |
|-----------------------|-------------------------------|
| `drag_polar` using a chosen textbook method | Constraint analysis, mission analysis |
| `TSFC` using a chosen textbook method | Mission analysis |
| `OEW` using a detailed structural build-up | Sizing loop |
| A new aircraft with its own geometry | Any discipline implementation |
| A new fidelity level | Any existing fidelity level |

---

## What This Document Does Not Define

The following are separate design decisions, to be specified in dedicated files:

- MATLAB class naming conventions and file/directory structure
- How geometry and control interfaces are defined for future courses
- How the mission profile (segment sequence, flight conditions, payload drops) is defined as data
- How the constraint diagram is constructed and the optimal point extracted
- How the sizing loop convergence criterion and iteration limit are set
- The specific state vector ordering and unit convention (English vs. SI internal storage)
- Fidelity-specific discipline details (see `Fidelity-Levels.md`)

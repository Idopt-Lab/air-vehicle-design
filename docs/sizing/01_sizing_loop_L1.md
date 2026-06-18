# SizingLoopL1 — Level I Sizing Loop

## Purpose

`SizingLoopL1` is the entry-point sizing algorithm for early conceptual design.
Use it when:

- Exploring a new concept and no fixed geometry exists yet
- Rapidly sweeping over design variables (mission radius, payload, technology factors)
- Teaching or communicating the basic sizing logic before adding geometric fidelity

The loop has **one state variable**: takeoff gross weight `W_TO`.  Everything else
(wing area, thrust level, fuel burn, empty weight) is derived from `W_TO` at each
iteration through the constraint diagram and mission analysis.

## Why W_TO Is the Single Driver

Aircraft sizing is fundamentally a fixed-point problem.  Every weight component
depends on total aircraft weight:

- **Wing area** depends on W_TO through the constraint-optimal W/S
- **Thrust** depends on W_TO through the constraint-optimal T/W
- **Fuel** depends on S_ref, thrust, and the mission profile (all functions of W_TO)
- **Empty weight** is a regression in W_TO (Raymer or Roskam tables)

No single component weight can be determined independently; they are mutually
consistent only at the converged `W_TO`.  The Level I loop exploits this by
collapsing all geometric and aerodynamic detail into top-level fractions and
table look-ups, leaving a scalar fixed-point iteration.

## Call Sequence Per Iteration

```
opt = con.optimal_point(aero, prop)   % constraint diagram → W/S, T/W
S_ref = W_TO / opt.W_S                % wing area at this W_TO
geom.S_ref = S_ref                    % propagate into geometry object
req.S_ref  = S_ref                    % propagate into mission requirements
prop.T0    = opt.T_W * W_TO           % set sea-level thrust in propulsion object
W_fuel     = miss.compute_fuel(aero, prop, W_TO, req)   % mission fuel
W_OEW      = wts.OEW(W_TO)            % empty operating weight regression
W_TO_new   = W_OEW + req.W_payload + W_fuel             % close the weight equation
W_TO       = 0.5*W_TO + 0.5*W_TO_new  % under-relaxed update
```

### Step-by-step explanations

**1. `opt = con.optimal_point(aero, prop)`**

The constraint diagram sweeps wing loading W/S from 20 to 180 psf, computes the
minimum required T/W for each performance constraint (sustained turn, dash Mach,
service ceiling, takeoff distance), and returns the design point that minimises
T/W while satisfying all constraints, subject to the landing-distance W/S upper
bound.  The output `opt` is a struct with fields `W_S` (psf) and `T_W`
(dimensionless).

**2. `S_ref = W_TO / opt.W_S`**

Wing area is derived directly from the constraint-optimal wing loading.  This is
the defining coupling of Level I: the wing is sized by the constraint diagram, not
by a fixed planform geometry.

**3. `geom.S_ref = S_ref; req.S_ref = S_ref`**

Both the geometry handle-object and the mission requirements struct are updated so
that subsequent calls to `miss.compute_fuel` use the current wing area.  At Level I,
the geometry object is thin — it mainly provides `S_ref` to the aerodynamics model
for wetted-area scaling.

**4. `prop.T0 = opt.T_W * W_TO`**

Sea-level static thrust is set by the constraint T/W ratio at the current iterate.
The propulsion object is a handle class, so this mutation persists into
`miss.compute_fuel` without a second call.

**5. `W_fuel = miss.compute_fuel(aero, prop, W_TO, req)`**

The mission analysis walks through each segment (startup, taxi, takeoff, climb,
cruise, dash, combat, egress, loiter, descent, landing) and returns total fuel
burned plus reserves.  At Level I the segment model uses Raymer-style weight
fractions; the fuel mass depends on `S_ref` through the lift-to-drag ratio.

**6. `W_OEW = wts.OEW(W_TO)`**

Operating empty weight from a power-law regression, e.g. Raymer Table 6.1 for
fighters:

    W_OEW = A * W_TO^C

where A and C are aircraft-type constants.  This is the weakest link in Level I:
it cannot account for individual component weights or technology changes.

**7. `W_TO_new = W_OEW + req.W_payload + W_fuel`**

Closure equation.  If `W_TO_new == W_TO` the aircraft is sized (all components are
mutually consistent at this gross weight).

**8. Under-relaxation: `W_TO = 0.5*W_TO + 0.5*W_TO_new`**

The raw fixed-point map `W_TO ← W_TO_new` can overshoot.  A factor of 0.5 blends
the old and new estimates; the converged result is independent of the factor
(only the convergence rate changes).

**9. Convergence check: `|W_TO_new - W_TO| < tol`**

Checked before the relaxed update is applied.  Default `tol = 1.0 lbf`.

## Constraint Analysis Coupling: Why optimal_point Is Called Every Iteration

The constraint diagram depends on drag polar coefficients (CD0, K), thrust lapse
(alpha = T/T0 at altitude and Mach), and CLmax — all of which are properties of
the aerodynamics and propulsion objects.  These objects do not change between
iterations at Level I; the F-16 aerodynamics are parameterised by S_wet (fixed by
Roskam regression at a reference W_TO) and do not update with S_ref.

However, the optimal W/S and T/W themselves do not depend on W_TO explicitly —
they depend on the shape of the constraint curves which are fixed by aero/prop.
This means `optimal_point` could in principle be called once before the loop.  The
current implementation calls it every iteration for generality: Level II
discipline objects may depend on `prop.T0` (which changes each iteration), and
keeping the call inside the loop makes L1 and L2 share the same loop structure.

The cost is negligible (a simple sweep over 80 wing-loading values).

## Under-Relaxation

**Without relaxation (damping = 1.0):** The map `W_TO ← W_TO_new` is a contraction
only if the slope of the closure equation is less than 1.  For fighters, the OEW
fraction is typically 0.60–0.65 and the fuel fraction 0.18–0.22, giving a combined
fraction near 0.80.  The raw Picard iteration converges but is slow.  For some
propulsion models where thrust lapse is nonlinear, the raw map can oscillate with a
2-cycle; under-relaxation damps this.

**With damping = 0.5:** The effective iteration is:

    W_TO ← 0.5 * W_TO + 0.5 * f(W_TO)

The fixed point is unchanged.  The spectral radius of the linearised map is
reduced from the slope of `f` to `(1 + slope)/2`.  For typical aircraft sizing
(slope ≈ 0.80), this reduces from 0.80 to 0.90 — comparable convergence with
extra safety margin.

**When to lower damping below 0.5:** If the loop oscillates (delta alternates sign
with increasing amplitude), lower damping to 0.2–0.3.  This can happen with highly
nonlinear propulsion lapse models or when the initial guess is far from the solution.

## Convergence Behaviour

| Property | Value |
|---|---|
| Default tolerance | 1.0 lbf |
| Default max iterations | 200 |
| Typical iterations to convergence (fighter) | 20–50 |
| Sensitivity to initial guess | Low — fixed-point contraction; W_TO_init=30000 works for F-16 |

The iteration is insensitive to the initial guess because the OEW regression and
fuel fraction model are smooth and bounded.  Starting from `5 * W_payload` (the
default fallback) converges for any reasonable aircraft type.

## Output Interpretation

After convergence, the loop computes final outputs:

```matlab
opt   = con.optimal_point(aero, prop);
S_ref = W_TO / opt.W_S;    % ft²
T_SL  = opt.T_W * W_TO;    % lbf
```

**`W_TO`** is the converged takeoff gross weight.

**`S_ref`** is the constraint-diagram-optimal wing area at the converged W_TO.
This value is **optimistic** in two senses:

1. It minimises installed thrust for the given set of constraints — the actual
   design may have a larger wing for structural, aeroelastic, or storage reasons.
2. It uses Level I aerodynamics (type-based Cf, Roskam S_wet regression) which
   may underpredict CD0, leading to a smaller optimal wing than a higher-fidelity
   model would suggest.

**`T_SL`** is derived from the constraint T/W, not iterated independently.  It is
consistent with W_TO and S_ref but does not account for engine installation effects
or inlet pressure recovery.

## What L1 Sizing Cannot Predict

- Tail surface areas (no tail in the loop — see SizingLoopL2)
- Individual component weights (only total OEW fraction)
- Compressibility drag corrections beyond the drag-polar model
- Engine inlet/nozzle installation losses
- Structural sizing or aeroelastic constraints
- Fuel volume feasibility (wing must physically hold the fuel)

## Worked Example: F-16A, First Three Iterations

Configuration: F16AeroLevel1, F16PropulsionLevel1, F16WeightLevel1,
F16MissionLevel1, F16ConstraintAnalysis.
Initial guess: W_TO = 30,000 lb.  Payload = 5,100 lb.

The constraint diagram (fixed aero/prop) returns approximately:
- W/S ≈ 104.6 psf, T/W ≈ 0.758

| Iter | W_TO (lb) | S_ref (ft²) | T_SL (lb) | W_OEW (lb) | W_fuel (lb) | W_TO_new (lb) | Delta (lb) |
|------|-----------|-------------|-----------|------------|-------------|---------------|------------|
| 1    | 30,000    | 286.8       | 22,730    | 19,500     | 5,710       | 30,310        | 310        |
| 2    | 30,155    | 288.2       | 22,847    | 19,580     | 5,740       | 30,420        | 265        |
| 3    | 30,288    | 289.5       | 22,948    | 19,650     | 5,765       | 30,503        | 215        |
| ...  | ...       | ...         | ...       | ...        | ...         | ...           | ...        |
| conv.| ~31,100  | ~297        | ~23,570   | ~20,200    | ~5,820      | —             | <1.0       |

(Numbers are representative; exact values depend on F16MissionLevel1 fuel-fraction
implementation.)

## Comparison to Brandt Ground Truth

| Quantity | Brandt | Expected L1 | Typical Error |
|---|---|---|---|
| W_TO (lb) | 31,377 | 30,500–32,500 | ±3–5% |
| S_ref (ft²) | 300.0 | 290–310 | ±3% |
| T_SL (lb) | 23,770 | 23,000–24,500 | ±3% |
| T/W | 0.7575 | 0.73–0.78 | ±2% |
| W/S (psf) | 104.59 | 100–110 | ±3% |
| OEW (lb) | 19,980 | 18,500–21,500 | ±5–8% |
| Fuel (lb) | 6,000 | 5,500–6,500 | ±5–8% |

The main sources of L1 error are the OEW regression (Raymer Table 6.1 scatter ±15%)
and the Level I fuel fraction model (fixed segment efficiency factors).  The
constraint diagram result (W/S, T/W) is relatively accurate because the Brandt
conditions and beta factor are taken directly from the JSON.

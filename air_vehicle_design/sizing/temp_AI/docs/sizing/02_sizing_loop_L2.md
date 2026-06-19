# SizingLoopL2 — Level II Sizing Loop

## Purpose

`SizingLoopL2` is used once a wing reference area has been fixed — either from a
Level I run, a trade study, or a design constraint (e.g. a hard storage requirement).
It iterates **two state variables simultaneously**: takeoff gross weight `W_TO` and
sea-level static thrust `T_SL`.  Wing area `S_ref` is a **fixed input**.

Use L2 when:

- `S_ref` has been committed (design review milestone, physical constraint)
- Tail surfaces must be sized for weight estimation
- Higher-fidelity aerodynamics (Oswald efficiency, calibrated Cfe) are available
- You need T_SL as a closed, iterated variable rather than derived from a T/W ratio

## Why S_ref Is a Fixed Input

In Level I, the optimal W/S from the constraint diagram drives S_ref.  Once
geometry is fixed, the wing area is no longer a free variable.  For the F-16:

- `S_ref = 300 ft²` is the Brandt ground-truth value
- The constraint diagram now only returns T/W (the W/S axis is unused for sizing)
- OEW is influenced by wing area through structural weight components (at L3; at
  L2 the Raymer regression absorbs this implicitly)

Fixing `S_ref` transforms the problem from a one-dimensional search (W_TO) to a
two-dimensional coupled iteration (W_TO, T_SL).  The additional state is needed
because T_SL now feeds directly into mission fuel burn through installed TSFC, and
the OEW depends on engine weight which scales with T_SL.

## Two-Variable Iteration

The two state variables are coupled:

- `T_SL = T_W * W_TO` (from constraint T/W at current W_TO)
- `W_TO = W_OEW(W_TO) + W_payload + W_fuel(T_SL, W_TO)`

Changing W_TO changes T_SL; changing T_SL changes W_fuel.  The loop must converge
both simultaneously.  The convergence criterion is:

    |W_TO_new - W_TO| < tol   AND   |T_SL_new - T_SL| < tol

Both conditions must hold in the same iteration.

## Call Sequence Per Iteration

```
opt      = con.optimal_point(aero, prop)   % T/W from constraint diagram (S_ref fixed)
T_SL_new = opt.T_W * W_TO                  % new thrust estimate
prop.T0  = T_SL_new                         % update propulsion object
tail_result = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)  % tail sizing
geom.S_HT = tail_result.S_HT               % store tail areas in geometry
geom.S_VT = tail_result.S_VT
W_fuel   = miss.compute_fuel(aero, prop, W_TO, req)   % mission fuel at new T_SL
W_OEW    = wts.OEW(W_TO)
W_TO_new = W_OEW + req.W_payload + W_fuel
W_TO     = 0.5*W_TO + 0.5*W_TO_new         % under-relaxed update
T_SL     = 0.5*T_SL + 0.5*T_SL_new
```

### Step-by-step explanations

**1. `opt = con.optimal_point(aero, prop)`**

Same call as L1, but now only the T/W output matters.  The constraint diagram still
sweeps W/S to find the minimum-T/W design point; that T/W is applied at the fixed
`S_ref`.  The returned `opt.W_S` is ignored for sizing (S_ref is already fixed).

**2. `T_SL_new = opt.T_W * W_TO`**

New thrust estimate from the current W_TO iterate.  This is the second state
variable update.

**3. `prop.T0 = T_SL_new`**

The propulsion handle object is mutated immediately so that `miss.compute_fuel`
in step 5 uses the updated thrust level.  Installed TSFC depends on T/T0 at each
mission point; a change in T0 changes every segment fuel burn.

**4. Tail sizing**

```matlab
tail_result = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)
geom.S_HT   = tail_result.S_HT
geom.S_VT   = tail_result.S_VT
```

The tail sizer uses Raymer volume-coefficient method:

    S_HT = c_HT * cbar * S_ref / L_HT
    S_VT = c_VT * b    * S_ref / L_VT

For the F-16: c_HT = 0.40, c_VT = 0.07.  `L_HT` and `L_VT` are estimated from
`geom.L_fus`.  The resulting tail areas are stored back into the geometry object
as handle-class mutations.

**Why tail sizing is inside the loop:** At Level II, the weight model may query
`geom.S_HT` and `geom.S_VT` inside `wts.OEW(W_TO)` (this is the case at Level III
where a component-weight model is used).  Even at Level II where the OEW regression
does not use tail areas directly, keeping tail sizing in the loop ensures `geom`
is always consistent with the current `W_TO` and allows a smooth upgrade to Level III
without structural changes to the loop.

**5–7. Fuel, OEW, closure** — same as L1.

**8. Under-relaxation on both variables**

```matlab
W_TO = 0.5*W_TO + 0.5*W_TO_new
T_SL = 0.5*T_SL + 0.5*T_SL_new
```

Two coupled equations can create oscillations even when each individual update
would converge in isolation.  Equal damping factors of 0.5 on both variables have
been found sufficient for the F-16 disciplines.  If divergence is observed, reduce
both damping factors to 0.2.

## Handle Class Mutations

`SizingLoopL2` mutates three handle objects during the loop:

| Object | Property mutated | When |
|---|---|---|
| `prop` | `T0` | Every iteration (step 3) |
| `geom` | `S_HT`, `S_VT` | Every iteration (step 4) |
| `geom` | implicitly via `S_ref` (fixed at `req.S_ref`) | Initialisation only |

Because MATLAB handle classes pass by reference, the caller's `prop` and `geom`
objects reflect the converged values after `sizer.run()` returns.  This is
intentional — it allows downstream post-processing to query final geometry without
redundant re-computation.

## Convergence

| Property | Value |
|---|---|
| Default tolerance | 1.0 lbf (applied to both W_TO and T_SL) |
| Default max iterations | 200 |
| Typical iterations (fighter, L2 disciplines) | 25–60 |
| Sensitivity to initial W_TO guess | Low |
| Sensitivity to initial T_SL | Low (pre-initialised from constraint T/W before loop) |

The pre-initialisation step (computing `opt` and setting `T_SL` before the first
iteration) avoids a cold-start where `prop.T0 = 0` would produce infinite TSFC.

## What L2 Produces That L1 Does Not

| Output | L1 | L2 |
|---|---|---|
| W_TO | Iterated | Iterated |
| S_ref | From constraint W/S | Fixed input |
| T_SL | Derived post-convergence | Iterated state variable |
| S_HT | Not computed | Computed each iteration; stored in geom |
| S_VT | Not computed | Computed each iteration; stored in geom |
| prop.T0 at exit | Consistent with W_TO | Converged value |

## Worked Example: F-16A, First Three Iterations

Configuration: F16AeroLevel2, F16PropulsionLevel2, F16WeightLevel2,
F16MissionLevel2, F16ConstraintAnalysis, F16TailSizingLevel1.
`S_ref = 300 ft²` (fixed).  Initial W_TO = 30,000 lb.  Payload = 5,100 lb.
Pre-initialisation: T_SL ≈ 22,730 lb.

Tail parameters: `b = sqrt(3*300) = 30 ft`, `cbar ≈ 11.1 ft`, `L_fus = 46.5 ft`.
Expected tail output: S_HT ≈ 108 ft², S_VT ≈ 60 ft² (independent of W_TO; depends
only on `S_ref`, wing geometry, and fuselage length).

| Iter | W_TO (lb) | T_SL (lb) | S_HT (ft²) | S_VT (ft²) | W_TO_new (lb) | T_SL_new (lb) | dW_TO (lb) | dT_SL (lb) |
|------|-----------|-----------|------------|------------|---------------|---------------|------------|------------|
| 1    | 30,000    | 22,730    | 108        | 60         | 30,350        | 22,995        | 350        | 265        |
| 2    | 30,175    | 22,863    | 108        | 60         | 30,520        | 23,114        | 345        | 251        |
| 3    | 30,348    | 22,989    | 108        | 60         | 30,680        | 23,225        | 332        | 236        |
| ...  | ...       | ...       | ...        | ...        | ...           | ...           | ...        | ...        |
| conv.| ~31,200  | ~23,650   | 108        | 60         | —             | —             | <1.0       | <1.0       |

Note that `S_HT` and `S_VT` are constant across iterations because they depend only
on fixed geometry (`S_ref`, `b`, `cbar`, `L_fus`).  The tail-sizing call is
idempotent for fixed-geometry disciplines.

## Transition from L1 to L2

The recommended workflow is:

1. Run `SizingLoopL1` with L1 disciplines → obtain `S_ref_L1`, `W_TO_L1`
2. Round or select `S_ref` (design choice; may equal `S_ref_L1` or a nearby round number)
3. Set `req.S_ref = S_ref` and `req.W_TO_init = W_TO_L1` (warm start)
4. Upgrade discipline objects to Level II
5. Run `SizingLoopL2` → obtain `W_TO_L2`, `T_SL_L2`, tail areas

Using `W_TO_L1` as the initial guess for L2 reduces the number of L2 iterations
needed.  For the F-16, `S_ref_L1 ≈ 297 ft²` from L1; setting `S_ref = 300 ft²`
(Brandt value) is a negligible change and the L2 loop converges from the L1 starting
point in approximately 30–40 iterations.

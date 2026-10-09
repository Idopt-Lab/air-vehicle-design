# Aircraft Sizing — the closure loop, and what a second level of fidelity buys

**AOE 4065 — Air Vehicle Design**

> This is the browsable companion to `Sizing_Guide.pdf`. Same content, same
> numbers; the PDF is the one to print or project. The diagrams also open in
> `diagrams.html`, which zooms and pans and needs no internet.
>
> Every number here is reproduced by the Live Scripts in `lecture/` and `lab/`.

---

## 1. The sizing problem

Sizing answers one question: *what is the smallest aircraft that can fly this
mission and meet these requirements?* Three numbers come out.

| Symbol | Meaning | Units |
|---|---|---|
| `W_TO`  | takeoff gross weight | lbf |
| `S_ref` | wing reference area | ft² |
| `T_SL`  | sea-level static thrust | lbf |

The difficulty is circularity. Start from the only statement you can write down
with confidence:

```
W_TO = W_empty + W_fuel + W_payload
```

Payload is a requirement, so it is known. The other two are not, and both of
them **depend on `W_TO`**:

- a heavier aircraft needs a bigger wing and a bigger engine, so more
  structure, so `W_empty` rises;
- a heavier aircraft makes more drag at the same lift coefficient, so it burns
  more fuel over the same mission, so `W_fuel` rises.

You cannot evaluate the right-hand side without already knowing the left-hand
side. That is what makes sizing a loop rather than a calculation.

> **The one sentence to remember.** Sizing is a fixed-point problem. Guess a
> takeoff weight, ask the discipline models what that aircraft would actually
> weigh, and keep going until the answer equals the question.

---

## 2. The three governing relations

### 2.1 Closure — the weight equation

```
W_TO_new = W_payload / (1 - W_empty/W_TO - W_fuel/W_TO)
```

Raymer 6th ed. Eq. 3.4; Martins metabook Algorithm 1. In code:
`SizingSteps.togw_update`, which returns the denominator alongside the answer
because it carries so much information.

> **Watch the denominator.** If the empty and fuel fractions together reach 1,
> the denominator hits zero and no positive `W_TO` closes the payload. The
> function returns `NaN` and the loops raise `closureInfeasible`. Physically:
> this aircraft is all structure and fuel, with nothing left to carry.

### 2.2 The design point — constraint analysis

Each performance requirement becomes one curve in the `T/W` against `W/S`
plane. Most are **producers**, built on the Mattingly master equation

```
T/W = A/(W/S) + B*(W/S) + C + D
A = q*CD0/alpha         B = (q/alpha)*K1*(n*beta/q)^2
C = K2*n*beta/alpha     D = (beta/alpha)*(Ps/V)
```

and a few are **walls**, which cap `W/S` and say nothing about thrust. Landing
field length is the usual wall.

A feasible design sits above every producer and left of every wall. The design
point is the best corner: for a jet, the smallest engine (lowest `T/W`), then
the highest `W/S` that still reaches it. `ConstraintAnalysis.optimal_point_continuous`
finds it with `fmincon`, minimising `T/W` subject to every signed residual
`g_i = required - available <= 0`.

Given the design point, a weight fixes both sizes:

```
S_ref = W_TO / (W/S)*        T_SL = (T/W)* * W_TO
```

> **The most useful output of constraint analysis.**
> `[WS, TW, info] = con.optimal_point_continuous()` returns
> `info.active_names`: the requirements whose residual is exactly zero at the
> optimum. Those are the ones holding the design where it is.
>
> For the Boeing 777 here there is exactly one: *Climb 3 (2nd segment, FAR
> 25.121)*. For the F-16A at Level 2 there are two: *Max Mach* and *Landing*.

### 2.3 The fuel fraction — mission analysis

The mission model walks the profile leg by leg, threading the weight through.
Cruise and loiter use Breguet; startup, taxi, takeoff, climb, descent and
landing use historical fractions (Roskam Part I Table 2.1). A reserve markup is
applied to the total. In code: `[W_fuel, breakdown] = miss.total_fuel(W_TO)`.

The profile lives in the **requirements** file, not in any discipline model. A
*spec* file says what the aircraft **is**; a *requirements* file says what it
must **do**. Sizing changes the spec until it satisfies the requirements.

---

## 3. Algorithm form

### Algorithm 1 — `SizingLoopL1`, one state variable  *(Martins slide 6)*

```
solve (W/S)*, (T/W)*  ONCE, before the loop
W = W_guess
repeat
    S_ref   = W / (W/S)*                      write into geom
    T_SL    = (T/W)* * W                      write into prop
    W_fuel  = miss.total_fuel(W)
    W_OEW   = wts.get_OEW(W)
    denom   = 1 - W_OEW/W - W_fuel/W
    if denom <= 0:  error, the closure is infeasible
    W_new   = W_payload / denom               Raymer Eq. 3.4
    if |W_new - W| / W_new < 1e-6:  converged, stop
    W       = W + w*(W_new - W)               under-relax
```

### Algorithm 2 — `SizingLoopL2`, two state variables  *(Martins slide 8)*

```
W = W_guess ;  T = T_guess
prop.T_SL = T                                 seed BEFORE the first solve
solve (W/S)*, (T/W)*
repeat
    1.  S_ref            = W / (W/S)*
    2.  S_ht, S_vt       = tail.size()        before the weights read them
    3.  prop.T_SL        = T                  before the design-point solve
    4.  (W/S)*, (T/W)*   = optimal_point_continuous([WS, TW])   EVERY pass
        T_new            = (T/W)* * W
    5.  W_fuel           = miss.total_fuel(W)
        W_OEW            = wts.get_OEW(W)
    6.  W_new            = W_payload / (1 - W_OEW/W - W_fuel/W)
    if BOTH states settled to 1e-6:  converged, stop
    W = W + w_W*(W_new - W)
    T = T + w_T*(T_new - T)
```

> **Three details in Algorithm 2 that are easy to get wrong.**
> 1. **Order.** Wing, tail, thrust, *then* the design-point solve. Sizing the
>    tail after the weights means the weights read last pass's tail. Writing
>    the thrust after the solve means the solve reads last pass's drag.
> 2. **`T_new = (T/W)* * W`.** From the design point and the current weight,
>    not from the relaxed state `T`.
> 3. **The convergence test is `&&`, not `||`.** Stopping when the weight
>    settles leaves the thrust still moving.

### Under-relaxation

```
x = x + w*(x_new - x)          SizingSteps.relax(x_old, x_new, w)
```

> **The argument order.** `w` weights the **new** value. `w = 1` takes the full
> undamped step; `w = 0.5`, the default, goes halfway. Writing
> `x = w*x + (1-w)*x_new` is the opposite convention and is the most common
> mistake in this lab.

---

## 4. Flowchart — the control flow

![SizingLoopL1 control flow](figures/flow_L1.png)

![SizingLoopL2 control flow](figures/flow_L2.png)

Yellow in the second chart marks what Level 1 does not have.

---

## 5. XDSM — the data flow

A flowchart shows what happens next. It does not show what data goes where,
and in a coupled problem that is the thing you need.

> **Reading an XDSM** *(Lambe and Martins, Struct. Multidisc. Optim. 46 (2012)
> 273–284)*
> - Cells on the diagonal are **components**: something that computes.
> - Cells off the diagonal are **data**. Row *i*, column *j* carries data
>   produced by component *i* and consumed by component *j*.
> - **Above** the diagonal is feed-forward. **Below** is feedback, drawn in red.
> - The grey highway is the data path: out of a component along its row, then
>   along the consumer's column.
> - The number at the corner of a component is its place in the process.

![XDSM of SizingLoopL1](figures/xdsm_L1.png)

![XDSM of SizingLoopL2](figures/xdsm_L2.png)

---

## 6. Design structure matrix — where the feedback is

![Design structure matrices](figures/n2_L1_L2.png)

> **Why this diagram is worth drawing.** A process with no feedback is not a
> loop, it is a checklist: run the components in order and you are done. Every
> mark below the diagonal is a place where a later component sends something
> back to an earlier one, which one pass cannot satisfy. Count the marks below
> the diagonal and you have counted the reasons the process must iterate.

---

## 7. One pass, as a sequence

![Sequence diagram of one L2 pass](figures/sequence_L2.png)

> **Handle semantics.** Every discipline object is a MATLAB `handle`. The
> sizing loop does not return a new aircraft; it **writes into the objects you
> gave it**. Derived geometry properties are `Dependent` and recompute on every
> read, so a change to `geom.S_ref` is visible to the aerodynamics model
> immediately, with no argument passing anything.
>
> The practical consequence: **build a fresh stack before every run**. A second
> run on a used stack starts from the first run's leftovers.

---

## 8. The fixed point

Everything above is one equation, `W = f(W)`, where `f` is a single closure
pass. Plot `f` against the 45-degree line and the whole method becomes visible.

![The closure map](figures/cobweb_b777.png)

The slope of `f` at the crossing carries two separate meanings.

**It decides whether the iteration converges.** An error `e` becomes `f'*e`
after one plain pass. If `|f'| < 1` the error shrinks; if `|f'| > 1` it grows
and plain substitution diverges. Under-relaxation changes the effective slope
to `1 + w*(f' - 1)`, which is how a smaller `w` rescues a steep map.

**It is the growth factor** — how many pounds of takeoff weight one extra pound
of payload buys. See section 10.

> **A worked case: the 777 diverges without relaxation.** `lecture/L04` runs
> plain substitution on the Boeing 777. It does not converge. The first eight
> passes go
>
> `700,000 → 822,000 → 630,000 → 1,066,000 → 480,000 → 10,349,000 → 272,000 → NaN`
>
> The slope from the first two passes is
> `(629,500 - 822,400)/(822,400 - 700,000) ≈ -1.58`: steeper than 1 in
> magnitude, and negative, so the error grows and flips sign every pass. By
> pass 7 the denominator has gone negative and there is no such aircraft.
>
> At `w = 0.5` the effective slope becomes `1 + 0.5*(-1.58 - 1) = -0.29`, and
> the same problem converges in 14 passes.

---

## 9. Level 1 against Level 2

### 9.1 Two different things are called "Level 2"

![The two fidelity axes](figures/fidelity_ladder.png)

**Loop fidelity** is how many unknowns the sizing loop solves for and what it
re-solves on every pass: `SizingLoopL1` against `SizingLoopL2`.
**Discipline fidelity** is how one model computes its own answer: a statistical
regression, a component build-up, or a detailed physical geometry.

The Boeing 777 example runs a *Level-2 loop* over *Level-2 geometry and
weights* but *Level-1 aerodynamics and propulsion*. That mix is deliberate: for
a transport it is the empty weight that drives the answer.

There is no `SizingLoopL3`. Sizing has no equations of its own that change with
fidelity, only a count of unknowns, so the same `SizingLoopL2` class drives the
Level-3 F-16 rung as well.

### 9.2 What changes in the loop

| | `SizingLoopL1` | `SizingLoopL2` |
|---|---|---|
| Injected objects | 6 | **7** — adds `tail` |
| State variables | `W_TO` | **`W_TO` and `T_SL`** |
| Design point | **frozen**: solved once, before the loop, and not re-solved after it | **freed**: re-solved every pass, warm-started, plus once more at the end |
| `T_SL` in the loop | slaved `(T/W)*·W`, write-only, nothing reads it back | an independent under-relaxed state; read by geometry (nacelle → CD0), by weights (engine weight), and by the mission |
| Tail | never sized | `tail.size()` every pass → `geom.S_ht`, `geom.S_vt` |
| Mission breakdown | discarded | consumed → `wts.W_landing` (Level 3 only) |
| Convergence test | `abs(dW)/W_new < tol` | the same **and** the same test on `T_SL` |
| `history` fields | 6 | 13 |
| Feedback couplings | 1 | 3 (2 states + 1 coupling) |
| Citation | Martins slide 6 | Martins slide 8 |

### 9.3 Why Level 1 is allowed to freeze the design point

Because at Level 1 the aerodynamics object takes **no geometry**. It reads
aspect ratio and sweep as plain numbers from the spec file. Nothing the loop
changes can move a drag polar, so nothing can move a constraint curve, so the
design point genuinely cannot change.

At Level 2 the aerodynamics object *holds* the geometry object, and
`CD0 = Cfe*S_wet/S_ref`. Both of the things the loop writes — the wing area
and the thrust, through the nacelle — move the wetted area. Measured on the 777
in `lecture/L06`: shrink the wing by a quarter and `CD0` goes from 0.01597 to
0.01956, moving the design point from (161 psf, 0.2657) to (165 psf, 0.2722).

### 9.4 What it actually buys, measured

Same aircraft, same discipline models, same starting guess. From `lecture/L06`:

| Boeing 777-200LR | Level-1 loop | Level-2 loop | Real aircraft |
|---|---:|---:|---:|
| `W_TO` [lbf]   | 740,125 | 740,060 | 766,800 |
| `T_SL` [lbf]   | 196,671 | 196,674 | 220,000 |
| `S_ref` [ft²]  | 4,597   | 4,598.5 | 4,605 |
| `(W/S)*` [psf] | 161.00  | 160.93  | 142.45 |
| `(T/W)*`       | 0.26573 | 0.26575 | 0.28691 |
| `S_ht` [ft²]   | *never sized* | 907.8 | — |
| `S_vt` [ft²]   | *never sized* | 800.7 | — |
| passes         | 14      | 52      | — |

**1. The answer barely moved.** Less than a hundredth of a percent on takeoff
weight. Say this out loud: extra fidelity did *not* change the answer here. The
reason is in the spec file — the wing area already in it was 4,605 ft² and the
loop converged to 4,598 ft². The starting aircraft was already the finished
aircraft, so Level 1 froze its design point in the right place and got away
with it.

**2. Level 2 sized the tail; Level 1 could not.** There is no tail object in
`SizingLoopL1`, and the 777 geometry file carries no tail areas, so after a
Level-1 run they are still undefined.

> **Sized is not the same as consumed.** It is tempting to go on and say *and
> the empty weight sees the new tail*. On this aircraft that is **false**.
> `B777GeomL2` derives its exposed tail areas from the fixed Chapter-7
> trapezoids, not from the loop-written reference areas, so on the 777 the tail
> resize is **write-only**. Double `geom.S_ht` and `S_exposed_ht`, `S_wet`,
> `W_tail` and `get_OEW` all move by exactly zero.
>
> On the **F-16A** the same test moves every one of them, because `F16GeomL2`
> builds its tail chords and span from `S_ht`. Same loop, same step, different
> coupling. Section 10 shows both.

**3. Now start from the wrong aircraft.** Put 2,600 ft² in the spec instead of
4,605 and change nothing else:

| | L1, good start | L1, **bad start** | L2, good start | L2, **bad start** |
|---|---:|---:|---:|---:|
| `W_TO` [lbf]   | 740,125 | **761,614** | 740,060 | 739,821 |
| `(W/S)*` [psf] | 161.00  | **170.00**  | 160.93  | 160.75 |
| `(T/W)*`       | 0.26573 | **0.28068** | 0.26575 | 0.26574 |

> **What Level 2 is really for.** Level 1 moved by 2.9 % and reported a design
> point that is plainly wrong: 170 psf and 0.281 against a true optimum near
> 161 psf and 0.266. Level 2 landed within a few hundred pounds of where it was
> before.
>
> So the value of the Level-2 loop is not a better number on a good day. It is
> **not depending on the guess you started from**. In real design work you do
> not know the answer in advance, which is exactly the situation the bad-start
> column reproduces.
>
> The cost is real: 52 passes against 14, each one running `fmincon` instead of
> reusing a frozen answer.

---

## 10. What actually moves, pass by pass

### 10.1 Two unknowns, three outputs

Sizing produces three numbers, so it is natural to assume the loop iterates on
three unknowns. It does not.

| Quantity | Kind | How it is produced |
|---|---|---|
| `W_TO` | **STATE** | under-relaxed each pass from the weight closure |
| `T_SL` | **STATE** | under-relaxed each pass from `(T/W)* * W_TO` |
| `S_ref` | **SLAVED** | recomputed, never iterated: `S_ref = W_TO / (W/S)*` |

All three *change* every pass, but only two are unknowns. `SizingLoopL2`
under-relaxes exactly two quantities and tests exactly two residuals. The wing
area moves for two reasons at once: the weight it carries changes, **and** the
design point it is sized against changes. The second reason is the one Level 1
does not have.

### 10.2 Tracing the loop

`SizingLoopL2` logs 13 quantities per pass — enough to know whether it
converged, not enough to know why. `helpers/trace_sizing_L2.m` is a replica of
the loop body that records about thirty. It checks itself against the class at
the end of every call and errors if the two have drifted.

```matlab
T = trace_sizing_L2(@build_f16_stack_L2, 30000, 20000);
plot_sizing_history(T);      % twelve panels
plot_weight_history(T);      % the component build-up, pass by pass
plot_what_changed(T);        % one bar chart: what moved, what did not
```

![F-16A iteration history](figures/history_f16.png)

### 10.3 Smaller is draggier

Follow panels 7 to 10. The wing shrinks, so the exposed and wetted areas
shrink — but `S_ref` shrinks **faster** than `S_wet` does, because the fuselage
and the inlet duct do not shrink at all. The ratio `S_wet/S_ref` therefore
**rises**, 5.09 → 6.18. Since `CD0 = Cfe*S_wet/S_ref`, parasite drag rises 21%,
`L/D_max` falls 11.0 → 9.9, every constraint curve lifts, and the design point
demands more thrust.

**A smaller aeroplane is a draggier aeroplane, per unit of wing.** One reason
fighters do not shrink indefinitely.

![F-16A weight build-up](figures/weights_f16.png)

> **A flat band is information.** A component that does not move is one the loop
> has no lever on. Any error in it passes straight through to `W_OEW` without
> being traded against anything else.

### 10.4 One chart per aircraft

![F-16A: what changed](figures/changed_f16.png)

![B777: what changed](figures/changed_b777.png)

On the F-16A everything is coupled. On the 777, `S_ht` and `S_vt` move +8.8%
but `S_exp_ht`, `S_exp_vt` and `W_tail` all read *did not move*.

> **Trace before you trust.** Both aircraft converge. Both look healthy. Only
> one has the tail coupling you would have assumed from reading the loop. The
> converged answer cannot tell you this; the trace can.

---

## 11. Growth factor

Add one pound of payload to a sized aircraft and the takeoff weight goes up by
more than one pound, because the loop settles at a new and heavier fixed point.
The amplification is the **growth factor**.

If the fractions held still, the growth factor would be exactly `1/denom`. They
do not. For the 777, `1/denom = 9.4`, but re-sizing with 5,000 lbf more payload
gives a measured growth factor of **3.3**. The gap is real physics: follow the
`denom` column in the `lecture/L04` table and it *rises* with aircraft size
(0.074 at 630,000 lbf, 0.107 at 740,000, 0.164 at 1,070,000). Each pound of
growth buys a little less growth than the pound before it, so the runaway damps
itself.

Keep `1/denom` anyway, as a warning light. A small denominator means structure
and fuel have eaten nearly the whole aircraft, and such a design is violently
sensitive to everything.

### Which requirements are expensive

`lecture/L07` nudges four inputs by ±10 % and re-sizes each time. Dividing by
the input change gives an **elasticity**: percent change in `W_TO` per percent
change in the input.

| Input (Boeing 777) | `W_TO` at −10 % | `W_TO` at +10 % | elasticity (up) |
|---|---:|---:|---:|
| cruise TSFC       | −9.66 % | +10.38 % | **1.04** |
| cruise range      | −9.42 % | +10.09 % | **1.01** |
| skin friction Cfe | −4.79 % | +4.67 %  | 0.47 |
| payload           | −3.57 % | +3.47 %  | 0.35 |

> **Reading the table.** Cruise range and cruise TSFC both come out near 1.0. A
> one percent longer mission, or a one percent thirstier engine, buys a one
> percent heavier aeroplane. Those are the expensive knobs.
>
> Payload comes out near 0.35, which does *not* contradict the growth factor of
> 3.3. Each **pound** of payload still costs 3.3 lbf of aircraft, but payload is
> only about 11 % of the takeoff weight, so ten percent of it is not many
> pounds. Growth factor and elasticity answer different questions — one per
> pound, one per percent — and design work needs both.
>
> Note also that technology knobs (TSFC, Cfe) and requirement knobs (payload,
> range) land on the same axis in the same units. That is how conceptual design
> decides whether to buy a better engine or to renegotiate the mission.

---

## 12. Where each equation lives in the code

| What | File | Reference |
|---|---|---|
| Weight closure, under-relaxation | `src/sizing/SizingSteps.m` | Raymer 6th ed. Eq. 3.4; metabook Algorithm 1 |
| One-state loop | `src/sizing/SizingLoopL1.m` | Martins slide 6 |
| Two-state loop | `src/sizing/SizingLoopL2.m` | Martins slide 8 |
| Design point, `fmincon` | `src/constraints/ConstraintAnalysis.m` | Raymer ch. 5 |
| Master equation curves | `src/constraints/MasterEquationConstraint.m` | Mattingly 2nd ed. |
| Mission fuel | `src/core/mission/` | Roskam Part I Eqs. 2.10–2.15 |
| Tail volume coefficients | `src/disciplines/tail_sizing/TailL1.m` | Raymer 7th ed. Table 6.4 |
| Standard atmosphere | `src/core/AircraftState.m` | ICAO 1993, via `atmosisa` |

> **Toolboxes.** The sizing path needs two: **Aerospace Toolbox** for
> `atmosisa`, which builds every flight condition, and **Optimization Toolbox**
> for `fmincon`, which both loops use to find the design point.
> `START_HERE.mlx` checks for both.

---

## 13. Running the material

| File | What it does |
|---|---|
| `START_HERE.mlx` | path setup, toolbox check, and a smoke solve |
| **`lecture/` — Boeing 777-200LR, instructor walkthrough** | |
| `L01_build_the_stack` | the six objects, and why the construction order is forced |
| `L02_constraint_design_point` | ten requirements → one design point |
| `L03_fuel_and_empty_weight` | the two questions the closure asks |
| `L04_one_closure_step_by_hand` | one pass, every number on screen; divergence; under-relaxation |
| `L05_run_the_L1_loop` | the Level-1 loop to convergence |
| `L06_run_the_L2_loop` | the Level-2 loop, and the bad-start test |
| `L07_sensitivity_growth_factor` | growth factor and elasticities |
| **`lab/` — F-16A, your turn** | |
| `LAB00_warmup_L1_loop` | complete and runnable; read every line |
| `LAB01_write_the_L2_loop` | six `TODO`s; a checker grades your loop against `SizingLoopL2` |
| `LAB_worksheet.pdf` | experiments to run on the loop you wrote |

> **On the F-16A numbers.** The lab converges to roughly 23,300 lbf against a
> Brandt F-16A reference of 31,377 lbf. That gap is a statement about the
> textbook discipline models and the requirement set, **not** about your loop.
> The lab grades one thing: does your loop reproduce `SizingLoopL2` to within a
> pound? Agreement with a real aircraft is a separate question, and the
> framework keeps the two deliberately apart.

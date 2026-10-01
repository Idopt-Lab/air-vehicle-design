# IHW3a — XDSMs of the two sizing loops

**Two** diagrams, one per driver, both drawn as eXtended Design Structure
Matrices (Lambe & Martins, 2012). An XDSM carries the same information as a
block diagram but shows the *loop structure* rather than the physical layout.

| file | driver | what it draws |
| --- | --- | --- |
| `ttpa_sizing_xdsm` | `run_ttpa_sizing` | the **lecture** framework: `S_ref` is an input, two states |
| `ttpa_mainloop_xdsm` | `run_ttpa_sizing_mainloop` | the **whiteboard** framework: `S_ref` is an output, three states |

Regenerate either with:

```bash
python xdsm_ttpa_sizing.py
python xdsm_ttpa_mainloop.py
```

Needs `pyxdsm` and a LaTeX install; writes `.tex`, `.tikz` and `.pdf`. To make
the `.png`: `pdftocairo -png -r 200 -singlefile <name>.pdf <name>`.

## How to read it

| Element | Meaning |
| --- | --- |
| **diagonal** | the analysis blocks, in execution order, numbered |
| **above the diagonal** | data flowing forward |
| **below the diagonal** | feedback — this is what makes it a loop |
| **thick grey line** | the process path, `0,8 → 1 … → 7 → 0` |
| **parallelograms on top** | external inputs |
| **parallelograms on the left** | outputs |

## What it shows

The orange block is `sizing_loop`, holding both states, `W_0` and `P_0`. It is
one solver, not two, because the loop tests both residuals together — the
lecture draws the MTOW iteration and the `T_0` iteration as separate red boxes,
but they close simultaneously in the same fixed point.

**`S_ref` is bold in the input box** because it is the design variable of the
default `fixed_wing_area` mode. The wing loading `W_0/S_ref` that the solver
hands to `design_diagram` is *computed*, not chosen — which is why the design
diagram is read at one wing loading rather than swept. In `design_point` mode
that arrow reverses: the design diagram supplies `(W/S)` and `S_ref` becomes an
output.

**The two feedback entries below the diagonal are the two red loops:**
`(W/P) ⇒ P_0^new` from the design diagram, and `W_0^new` from the TOGW closure.
Everything else flows forward.

The vertical stacks of forward data show which blocks are genuinely coupled:
`TtpaProp` feeds four downstream blocks (nacelle length, power available,
fuel consumption, engine weight), and `TtpaGeom` feeds three (drag, mission,
weights). Those are the couplings the loop exists to resolve — in IHW1 and IHW2
most of them did not exist, which is why neither needed a loop.

---

## `ttpa_mainloop_xdsm` — the main loop, where `S_ref` is an output

Same eight blocks, arranged the same way. **Three differences, and they are the
whole story.**

**1. The solver carries three states, not two.** `W_0`, `P_0` *and* `S_ref` all
sit inside the orange block. In the lecture diagram `S_ref` is a green input at
the top; here it comes out at the bottom left, in bold, because producing it is
the point of the loop.

**2. `AR` and `λ` are the bold inputs instead.** They are what you hold constant
while the loop solves for everything else — the whiteboard writes "constant"
next to them for exactly this reason.

**3. There are three feedback entries below the diagonal, not two.** The extra
one is `(W/S) ⇒ S_ref^new`, and it is what turns the wing area from something
you choose into something the analysis returns. The other two are the same two
red loops as before: `(W/P) ⇒ P_0^new` and `W_0^new` from the closure.

One more structural difference, in block 4. The lecture diagram calls
`design_diagram`, which reads the matching chart at **one** wing loading,
because a chosen `S_ref` fixes `W/S`. Here block 4 is `matching_envelope`,
which solves the **whole** chart on every pass and returns its least-engine
corner. That is more work per pass, and it is unavoidable: if you do not know
`W/S` in advance you cannot read the chart at a single point.

### What the diagram cannot show

The vertical stacks tell you `TtpaProp` feeds four downstream blocks and
`TtpaGeom` feeds three, so the couplings are real. What the topology does *not*
tell you is whether the `(W/S) ⇒ S_ref` feedback carries any information, and on
this airplane it mostly does not: the corner sits pinned on the landing wall at
43.240 psf in the default configuration, so `S_ref` is `W_TO` divided by a
constant. The arrow exists and is correctly drawn; the physics behind it is
degenerate. See the main README for the measured detail.

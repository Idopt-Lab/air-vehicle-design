# IHW3a — XDSM of the sizing framework

`ttpa_sizing_xdsm.pdf` (and `.png`) is the IHW3a sizing framework drawn as an
eXtended Design Structure Matrix (Lambe & Martins, 2012). It is the same
information as the lecture's preliminary-design-framework block diagram, but in
the form that shows the *loop structure* rather than the physical layout.

Regenerate with:

```bash
python xdsm_ttpa_sizing.py
```

Needs `pyxdsm` and a LaTeX install; writes `.tex`, `.tikz` and `.pdf`.

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

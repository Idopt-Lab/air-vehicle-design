"""
sizing_L1_xdsm.py — SizingLoopL1 call-sequence XDSM diagram.

Shows the Level I sizing iteration: one state variable (W_TO),
all discipline calls per iteration, and the convergence check.

Usage:
    python sizing_L1_xdsm.py

Requires pyxdsm >= 2.2.0.
Output: sizing_L1_xdsm.pdf  and  sizing_L1_xdsm.tikz
"""

from pyxdsm.XDSM import XDSM, OPT, FUNC, MDA, IFUNC, LEFT, RIGHT


def build_sizing_L1_xdsm():
    x = XDSM(use_sfmath=False)

    # --- Systems ---
    x.add_system("loop",    OPT,   [r"\text{SizingLoopL1}", r"\text{(iterates } W_{TO})"])
    x.add_system("con",     FUNC,  [r"\text{Constraint}", r"\text{Analysis}"])
    x.add_system("geom",    FUNC,  [r"\text{Geometry}", r"(S_{ref}, b)"])
    x.add_system("prop",    IFUNC, [r"\text{Propulsion}", r"(T_0 \leftarrow)"])
    x.add_system("miss",    FUNC,  [r"\text{Mission}", r"\text{Analysis}"])
    x.add_system("wts",     FUNC,  [r"\text{Weights}", r"W_{OEW}"])
    x.add_system("close",   MDA,   [r"\text{Weight}", r"\text{Closure}"])

    # --- Inputs to the loop ---
    x.add_input("loop",  r"W_{TO}^{(0)}, W_{pay}, \text{req}")
    x.add_input("con",   r"CD_0, K_2, \alpha(\cdot)")
    x.add_input("miss",  r"\text{segments}, \text{type}")
    x.add_input("wts",   r"\text{type}")

    # --- Connections ---
    # SizingLoopL1 → ConstraintAnalysis: current W_TO (for alpha scaling)
    x.connect("loop", "con",  r"W_{TO}^{(k)}")

    # ConstraintAnalysis → loop: design-point W/S and T/W
    x.connect("con", "loop",  r"(W/S)^*, (T/W)^*")

    # loop → geom: update S_ref = W_TO / W_S
    x.connect("loop", "geom", r"S_{ref} = W_{TO}/(W/S)^*")

    # loop → prop: set sea-level thrust T0
    x.connect("loop", "prop", r"T_0 = (T/W)^* \cdot W_{TO}")

    # loop (via geom/prop) → miss: S_ref and T0 for fuel burn
    x.connect("geom", "miss", r"S_{ref}")
    x.connect("prop", "miss", r"T_0,\ \text{TSFC}(\cdot),\ \alpha(\cdot)")

    # mission → loop: fuel weight
    x.connect("miss", "loop", r"W_{fuel}")

    # loop → wts: current W_TO for empty-weight regression
    x.connect("loop", "wts",  r"W_{TO}^{(k)}")

    # wts → loop: OEW
    x.connect("wts", "loop",  r"W_{OEW}")

    # loop → closure: assemble new W_TO
    x.connect("loop", "close", r"W_{OEW} + W_{pay} + W_{fuel}")

    # closure → loop: new W_TO (under-relaxed)
    x.connect("close", "loop", r"W_{TO}^{(k+1)}")

    # --- Outputs ---
    x.add_output("loop",  r"W_{TO}^*, S_{ref}^*, T_{SL}^*", side=RIGHT)

    # --- Iteration arrow (the fixed-point loop) ---
    x.add_process(["loop", "con", "geom", "prop", "miss", "wts", "close", "loop"],
                  arrow=True)

    x.write("sizing_L1_xdsm", outdir=".")


if __name__ == "__main__":
    build_sizing_L1_xdsm()
    print("Wrote sizing_L1_xdsm.pdf and sizing_L1_xdsm.tikz")

"""
sizing_L2_xdsm.py — SizingLoopL2 call-sequence XDSM diagram.

Shows the Level II sizing iteration: two state variables (W_TO, T_SL),
fixed S_ref, and the addition of tail sizing at every iteration.

Usage:
    python sizing_L2_xdsm.py

Requires pyxdsm >= 2.2.0.
Output: sizing_L2_xdsm.pdf  and  sizing_L2_xdsm.tikz
"""

from pyxdsm.XDSM import XDSM, OPT, FUNC, MDA, IFUNC, LEFT, RIGHT


def build_sizing_L2_xdsm():
    x = XDSM(use_sfmath=False)

    # --- Systems ---
    x.add_system("loop",    OPT,   [r"\text{SizingLoopL2}",
                                    r"\text{(iterates } W_{TO}, T_{SL})"])
    x.add_system("con",     FUNC,  [r"\text{Constraint}", r"\text{Analysis}"])
    x.add_system("prop",    IFUNC, [r"\text{Propulsion}", r"(T_0 \leftarrow)"])
    x.add_system("tail",    FUNC,  [r"\text{Tail Sizing}",
                                    r"S_{HT}, S_{VT}"])
    x.add_system("geom",    FUNC,  [r"\text{Geometry}", r"(\text{stores }S_{HT}, S_{VT})"])
    x.add_system("miss",    FUNC,  [r"\text{Mission}", r"\text{Analysis}"])
    x.add_system("wts",     FUNC,  [r"\text{Weights}", r"W_{OEW}"])
    x.add_system("close",   MDA,   [r"\text{Weight}", r"\text{Closure}"])

    # --- Inputs to the loop ---
    x.add_input("loop",  r"W_{TO}^{(0)},\ T_{SL}^{(0)},\ S_{ref}\ \text{(fixed)}")
    x.add_input("con",   r"CD_0, K_2, \alpha(\cdot)")
    x.add_input("tail",  r"c_{HT}, c_{VT}\ \text{(type constants)}")
    x.add_input("miss",  r"\text{segments}")
    x.add_input("wts",   r"T_{SL}/W_{TO}, S_{ref}\ \text{(for L2 regression)}")

    # --- Connections ---
    # loop → constraint: current W_TO (for thrust lapse scaling)
    x.connect("loop", "con",  r"W_{TO}^{(k)}, S_{ref}")

    # constraint → loop: optimal T/W at fixed S_ref
    x.connect("con", "loop",  r"(T/W)^*")

    # loop → prop: updated T_SL
    x.connect("loop", "prop", r"T_{SL}^{(k)} = (T/W)^* \cdot W_{TO}^{(k)}")

    # loop → tail: current geometry for tail sizing
    x.connect("loop", "tail", r"S_{ref}, b, \bar{c}, L_{fus}")

    # tail → geom: write S_HT, S_VT into geometry
    x.connect("tail", "geom", r"S_{HT}, S_{VT}")

    # geom → miss: updated geometry (S_HT, S_VT affect drag at L2+)
    x.connect("geom", "miss", r"S_{ref}, S_{HT}, S_{VT}")

    # prop → miss: TSFC, thrust lapse
    x.connect("prop", "miss", r"T_0,\ \text{TSFC}(\cdot),\ \alpha(\cdot)")

    # loop → miss: current W_TO for segment analysis
    x.connect("loop", "miss", r"W_{TO}^{(k)}")

    # miss → loop: fuel weight
    x.connect("miss", "loop", r"W_{fuel}")

    # loop → wts: current W_TO
    x.connect("loop", "wts",  r"W_{TO}^{(k)}")

    # wts → loop: OEW
    x.connect("wts", "loop",  r"W_{OEW}")

    # loop → closure: assemble new W_TO
    x.connect("loop", "close", r"W_{OEW} + W_{pay} + W_{fuel}")

    # closure → loop: new W_TO (under-relaxed)
    x.connect("close", "loop",
              r"W_{TO}^{(k+1)},\ T_{SL}^{(k+1)}\ \text{(under-relaxed)}")

    # --- Outputs ---
    x.add_output("loop",  r"W_{TO}^*, T_{SL}^*", side=RIGHT)
    x.add_output("geom",  r"S_{HT}^*, S_{VT}^*", side=RIGHT)

    # --- Iteration arrow ---
    x.add_process(["loop", "con", "prop", "tail", "geom", "miss",
                   "wts", "close", "loop"], arrow=True)

    x.write("sizing_L2_xdsm", outdir=".")


if __name__ == "__main__":
    build_sizing_L2_xdsm()
    print("Wrote sizing_L2_xdsm.pdf and sizing_L2_xdsm.tikz")

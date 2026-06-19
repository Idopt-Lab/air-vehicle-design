"""
framework_xdsm.py — Overall aircraft sizing framework XDSM diagram.

Shows the top-level data flow for Level I and Level II sizing, including
which blocks are active at each fidelity level.

Usage:
    python framework_xdsm.py

Requires pyxdsm >= 2.2.0.
Output: framework_xdsm.pdf  and  framework_xdsm.tikz
"""

from pyxdsm.XDSM import (
    XDSM, OPT, SUBOPT, FUNC, MDA, MDASPLIT, MDACHAIN, ICOMP, IFUNC, LEFT, RIGHT
)


def build_framework_xdsm():
    x = XDSM(use_sfmath=False)

    # ------------------------------------------------------------------ #
    # Systems                                                              #
    # ------------------------------------------------------------------ #

    # Inputs / driver
    x.add_system("inputs",      FUNC,  r"\text{Config JSON}")
    x.add_system("req",         FUNC,  r"\text{Mission Req.}")

    # Sizing driver (iteration controller)
    x.add_system("sizing",      MDA,   [r"\text{SizingLoop}", r"(L1: }W_{TO}\text{; L2: }W_{TO},T_{SL}\text{)}"])

    # Discipline blocks
    x.add_system("constraint",  FUNC,  r"\text{Constraint}", r"\text{Analysis}")
    x.add_system("geometry",    FUNC,  r"\text{Geometry}", r"\text{Update}")
    x.add_system("mission",     FUNC,  r"\text{Mission}", r"\text{Analysis}")
    x.add_system("weight",      FUNC,  r"\text{Weight}", r"\text{Estimation}")
    x.add_system("tail",        FUNC,  [r"\text{Tail Sizing}", r"\text{(L2 only)}"])

    # Output collector
    x.add_system("outputs",     FUNC,  r"\text{Outputs}")

    # ------------------------------------------------------------------ #
    # Inputs to systems                                                    #
    # ------------------------------------------------------------------ #

    # Config JSON feeds discipline constructors
    x.add_input("constraint",  "geom\_json",  r"S_{ref},\, \text{conditions},\, \beta_{perf}")
    x.add_input("geometry",    "geom\_json",  r"S_{ref,0},\, AR,\, \lambda,\, L_{fus}")
    x.add_input("mission",     "geom\_json",  r"\text{mission segments}")
    x.add_input("weight",      "geom\_json",  r"\text{aircraft type}")
    x.add_input("tail",        "geom\_json",  r"c_{HT}=0.40,\, c_{VT}=0.07")

    # Mission requirements
    x.add_input("req",         "W\_payload",  r"W_{payload} = 5100\,\text{lb}")
    x.add_input("req",         "S\_ref",      r"S_{ref}\;\text{(L2: fixed; L1: from W/S)}")
    x.add_input("sizing",      "W\_TO\_init", r"W_{TO,0} = 30{,}000\,\text{lb}")

    # ------------------------------------------------------------------ #
    # Data connections                                                     #
    # ------------------------------------------------------------------ #

    # req → sizing
    x.connect("req",         "sizing",      r"W_{payload},\, S_{ref,0}")

    # sizing → constraint
    x.connect("sizing",      "constraint",  r"W_{TO}^{(k)}")

    # constraint → geometry (W/S drives S_ref at L1)
    x.connect("constraint",  "geometry",    r"W/S \Rightarrow S_{ref}\;\text{(L1)}")

    # constraint → sizing (T/W returns to update T_SL)
    x.connect("constraint",  "sizing",      r"T/W")

    # geometry → mission (S_ref needed for L/D)
    x.connect("geometry",    "mission",     r"S_{ref},\, b,\, \bar{c}")

    # geometry → tail (L2 only)
    x.connect("geometry",    "tail",        r"S_{ref},\, b,\, \bar{c},\, L_{fus}\;\text{(L2)}")

    # tail → geometry mutation (S_HT, S_VT stored back)
    x.connect("tail",        "geometry",    r"S_{HT},\, S_{VT}\;\text{(L2)}")

    # tail → weight (L2: tail areas used in OEW at L3)
    x.connect("tail",        "weight",      r"S_{HT},\, S_{VT}\;\text{(L2)}")

    # mission → sizing (fuel burn closes W_TO loop)
    x.connect("mission",     "sizing",      r"W_{fuel}")

    # weight → sizing
    x.connect("weight",      "sizing",      r"W_{OEW}")

    # sizing internal feedback (W_TO, T_SL)
    x.connect("sizing",      "sizing",      r"W_{TO}^{(k+1)},\; T_{SL}^{(k+1)}")

    # sizing → outputs
    x.connect("sizing",      "outputs",     r"W_{TO}^*,\; T_{SL}^*,\; S_{ref}^*")
    x.connect("geometry",    "outputs",     r"S_{HT},\; S_{VT}\;\text{(L2)}")
    x.connect("weight",      "outputs",     r"W_{OEW}^*")
    x.connect("mission",     "outputs",     r"W_{fuel}^*")

    # ------------------------------------------------------------------ #
    # Outputs (left side)                                                  #
    # ------------------------------------------------------------------ #

    x.add_output("outputs",  "W\_TO",   r"W_{TO}^* = 31{,}377\,\text{lb}", side=LEFT)
    x.add_output("outputs",  "T\_SL",   r"T_{SL}^* = 23{,}770\,\text{lb}", side=LEFT)
    x.add_output("outputs",  "S\_ref",  r"S_{ref}^* = 300\,\text{ft}^2",   side=LEFT)
    x.add_output("outputs",  "OEW",     r"W_{OEW}^* = 19{,}980\,\text{lb}", side=LEFT)
    x.add_output("outputs",  "Fuel",    r"W_{fuel}^* = 6{,}000\,\text{lb}", side=LEFT)
    x.add_output("outputs",  "S\_HT",   r"S_{HT}^* = 108\,\text{ft}^2\;\text{(L2)}", side=LEFT)
    x.add_output("outputs",  "S\_VT",   r"S_{VT}^* = 60\,\text{ft}^2\;\text{(L2)}",  side=LEFT)

    # ------------------------------------------------------------------ #
    # Render                                                               #
    # ------------------------------------------------------------------ #
    x.write("framework_xdsm")
    print("Written: framework_xdsm.pdf  framework_xdsm.tikz")


if __name__ == "__main__":
    build_framework_xdsm()

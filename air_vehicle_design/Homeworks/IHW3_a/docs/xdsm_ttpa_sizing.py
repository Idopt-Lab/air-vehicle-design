"""
xdsm_ttpa_sizing.py -- XDSM of the IHW3a TTPA sizing framework.

Draws the preliminary design framework as an eXtended Design Structure Matrix
(Lambe & Martins, 2012), in the default "fixed_wing_area" mode: S_ref is a
design variable, the wing loading is computed, and the design diagram is read
at that single wing loading.

Reading an XDSM:
  * diagonal            = the analysis blocks, in execution order
  * ABOVE the diagonal  = data flowing forward
  * BELOW the diagonal  = feedback, i.e. what makes it a loop
  * thick grey line     = the process, numbered
  * grey parallelograms = external inputs (top) and outputs (left)

Run:  python xdsm_ttpa_sizing.py
Makes ttpa_sizing_xdsm.tex and ttpa_sizing_xdsm.pdf in the same folder.
"""

from pyxdsm.XDSM import XDSM, SOLVER, FUNC, LEFT

x = XDSM(use_sfmath=True)

# ---------------------------------------------------------------- systems
# The two red loops of the lecture diagram are ONE solver here: the loop
# carries both states, W_0 and P_0, and tests both residuals together.
x.add_system("solver", SOLVER, (r"\text{0,8}\rightarrow\text{1:}",
                                r"\texttt{sizing\_loop}",
                                r"\text{states } W_0,\ P_0"))

x.add_system("prop",  FUNC, (r"\text{1: } \texttt{TtpaProp}",
                             r"\text{engine wt, length, lapse}"))
x.add_system("geom",  FUNC, (r"\text{2: } \texttt{TtpaGeom}",
                             r"\text{planform, tails, } S_{wet}"))
x.add_system("aero",  FUNC, (r"\text{3: } \texttt{TtpaAero}",
                             r"\text{drag polar II}"))
x.add_system("ddiag", FUNC, (r"\text{4: } \texttt{design\_diagram}",
                             r"\text{read at one } W/S"))
x.add_system("miss",  FUNC, (r"\text{5: } \texttt{mission\_fuel}",
                             r"\texttt{run\_mission\_L2}"))
x.add_system("wts",   FUNC, (r"\text{6: } \texttt{TtpaWeights}",
                             r"\text{empty weight II/III}"))
x.add_system("close", FUNC, (r"\text{7: } \texttt{SizingSteps}",
                             r"\texttt{.togw\_update}"))

# ------------------------------------------------------- external inputs
x.add_input("solver", r"W_{0,guess},\ P_{0,guess}")
x.add_input("prop",   r"n_{eng},\ c_{bhp},\ \eta_p")
x.add_input("geom",   (r"\mathbf{S_{ref}},\ AR,\ \lambda",
                       r"L_{fus},\ D_{fus},\ V_h,\ V_v"))
x.add_input("aero",   r"C_{fe},\ \Delta C_{D_0},\ C_{L_{max}}")
x.add_input("ddiag",  r"s_{FL},\ G,\ I_p,\ \beta")
x.add_input("miss",   r"R,\ V,\ \text{profile}")
x.add_input("wts",    r"\text{Raymer Tbl 15.2 / 15.46}")
x.add_input("close",  r"W_{payload}")

# -------------------------------------------------- forward data (above)
# state out of the solver
x.connect("solver", "prop",  r"P_0")
x.connect("solver", "ddiag", r"W_0/S_{ref}")
x.connect("solver", "miss",  r"W_0")
x.connect("solver", "wts",   r"W_0")

# the engine sizes the nacelle
x.connect("prop", "geom",  r"L_{engine}")
# and sets the power available at each condition
x.connect("prop", "ddiag", r"k_P,\ \eta_p")
x.connect("prop", "miss",  r"c_{bhp},\ \eta_p")
x.connect("prop", "wts",   r"W_{engine}")

# the wing sizes the drag
x.connect("geom", "aero", r"S_{wet}/S_{ref}")
x.connect("geom", "miss", r"S_{ref}")
x.connect("geom", "wts",  (r"S_{exp},\ S_{ht},",
                           r"S_{vt},\ S_{wet,fus}"))

# the drag sizes the climb constraints and the mission
x.connect("aero", "ddiag", r"C_{D_0},\ K")
x.connect("aero", "miss",  r"C_{D_0},\ K")

# what the closure consumes
x.connect("miss", "close", r"W_f")
x.connect("wts",  "close", r"W_e")

# ------------------------------------------------------ feedback (below)
# THE TWO RED LOOPS OF THE LECTURE DIAGRAM
x.connect("ddiag", "solver", r"(W/P) \Rightarrow P_0^{new}")
x.connect("close", "solver", r"W_0^{new}")

# ------------------------------------------------------------- outputs
x.add_output("solver", r"W_{TO},\ P_{SL},\ S_{ref}", side=LEFT)
x.add_output("miss",   r"\text{fuel burn}", side=LEFT)

# ------------------------------------------------------------- process
x.add_process(
    ["solver", "prop", "geom", "aero", "ddiag", "miss", "wts", "close", "solver"],
    arrow=True,
)

x.write("ttpa_sizing_xdsm")
print("wrote ttpa_sizing_xdsm.tex / .pdf")

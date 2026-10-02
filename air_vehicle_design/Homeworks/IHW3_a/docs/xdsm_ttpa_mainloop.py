"""
xdsm_ttpa_mainloop.py -- XDSM of run_ttpa_sizing_mainloop.

The whiteboard framework: AR and taper are held constant, and THREE states
are iterated to a consistent set -- the takeoff weight, the shaft power and
the wing area. S_ref is an OUTPUT here, not an input.

Contrast with xdsm_ttpa_sizing.py, which draws the LECTURE framework that
run_ttpa_sizing uses. Two differences, and they are the whole story:

  * there S_ref is an external input and the solver carries TWO states;
    here S_ref is a solver state and comes out at the bottom left.
  * there the design diagram is read at ONE wing loading, because W/S is
    fixed by the chosen S_ref. Here the WHOLE matching diagram is solved
    on every pass and its least-engine corner supplies W/S.

So this diagram has THREE feedback entries below the diagonal instead of
two. That third one, (W/S) => S_ref, is what makes the wing area an answer.

Reading an XDSM:
  * diagonal            = the analysis blocks, in execution order
  * ABOVE the diagonal  = data flowing forward
  * BELOW the diagonal  = feedback, i.e. what makes it a loop
  * thick grey line     = the process, numbered
  * grey parallelograms = external inputs (top) and outputs (left)

Run:  python xdsm_ttpa_mainloop.py
Makes ttpa_mainloop_xdsm.tex and ttpa_mainloop_xdsm.pdf in the same folder.
"""

from pyxdsm.XDSM import XDSM, SOLVER, FUNC, LEFT

x = XDSM(use_sfmath=True)

# ---------------------------------------------------------------- systems
# ONE solver carrying all three states. The whiteboard draws the weight
# loop and the thrust loop as two separate red circles, but they close
# simultaneously in the same fixed point, and S_ref rides along with them.
x.add_system("solver", SOLVER, (r"\text{0,8}\rightarrow\text{1:}",
                                r"\texttt{main\_loop}",
                                r"\text{states } W_0,\ P_0,\ S_{ref}"))

x.add_system("prop", FUNC, (r"\text{1: } \texttt{TtpaProp}",
                            r"\text{engine wt, length, lapse}"))
x.add_system("geom", FUNC, (r"\text{2: } \texttt{TtpaGeom}",
                            r"\text{planform, tails, } S_{wet}"))
x.add_system("aero", FUNC, (r"\text{3: } \texttt{TtpaAero}",
                            r"\text{drag polar II}"))
x.add_system("ca",   FUNC, (r"\text{4: } \texttt{matching\_envelope}",
                            r"\text{whole diagram, least-engine corner}"))
x.add_system("miss", FUNC, (r"\text{5: } \texttt{mission\_fuel}",
                            r"\texttt{run\_mission\_L2}"))
x.add_system("wts",  FUNC, (r"\text{6: } \texttt{TtpaWeights}",
                            r"\text{empty weight II/III}"))
x.add_system("close", FUNC, (r"\text{7: } \texttt{SizingSteps}",
                             r"\texttt{.togw\_update}"))

# ------------------------------------------------------- external inputs
x.add_input("solver", r"W_{0,guess},\ P_{0,guess},\ S_{0,guess}")
x.add_input("prop",   r"n_{eng},\ c_{bhp},\ \eta_p")
x.add_input("geom",   (r"\mathbf{AR},\ \boldsymbol{\lambda}\ \text{(held constant)}",
                       r"L_{fus},\ D_{fus},\ V_h,\ V_v"))
x.add_input("aero",   r"C_{fe},\ \Delta C_{D_0},\ C_{L_{max}}")
x.add_input("ca",     r"s_{FL},\ G,\ I_p,\ \beta")
x.add_input("miss",   r"R,\ V,\ \text{profile}")
x.add_input("wts",    r"\text{Raymer Tbl 15.2 / Eq 15.46}")
x.add_input("close",  r"W_{payload}")

# -------------------------------------------------- forward data (above)
# The two state writes that resize the whole airplane. Everything else in
# the geometry and the aerodynamics is a Dependent property of these.
x.connect("solver", "prop", r"P_0")
x.connect("solver", "geom", r"S_{ref}")
x.connect("solver", "miss", r"W_0")
x.connect("solver", "wts",  r"W_0")

# the engine sizes the nacelle, the power available, the fuel flow, its weight
x.connect("prop", "geom", r"L_{engine}")
x.connect("prop", "ca",   r"k_P,\ \eta_p")
x.connect("prop", "miss", r"c_{bhp},\ \eta_p")
x.connect("prop", "wts",  r"W_{engine}")

# the wing sizes the drag, the mission and four weight rows
x.connect("geom", "aero", r"S_{wet}/S_{ref}")
x.connect("geom", "miss", r"S_{ref}")
x.connect("geom", "wts",  (r"S_{exp},\ S_{ht},",
                           r"S_{vt},\ S_{wet,fus}"))

# the drag polar moves the climb and cruise curves, and the mission
x.connect("aero", "ca",   r"C_{D_0},\ K")
x.connect("aero", "miss", r"C_{D_0},\ K")

# what the closure consumes
x.connect("miss", "close", r"W_f")
x.connect("wts",  "close", r"W_e")

# ------------------------------------------------------ feedback (below)
# THREE loops, not two. The third is the one that makes S_ref an answer.
x.connect("ca", "solver", (r"(W/S) \Rightarrow S_{ref}^{new}",
                           r"(W/P) \Rightarrow P_0^{new}"))
x.connect("close", "solver", r"W_0^{new}")

# ------------------------------------------------------------- outputs
x.add_output("solver", r"W_{TO},\ P_{SL},\ \mathbf{S_{ref}}", side=LEFT)
x.add_output("ca",     r"(W/S),\ (W/P),\ \text{driving}", side=LEFT)
x.add_output("miss",   r"\text{fuel burn}", side=LEFT)
x.add_output("wts",    r"\text{7 weight rows}", side=LEFT)

# ------------------------------------------------------------- process
x.add_process(
    ["solver", "prop", "geom", "aero", "ca", "miss", "wts", "close", "solver"],
    arrow=True,
)

x.write("ttpa_mainloop_xdsm")
print("wrote ttpa_mainloop_xdsm.tex / .pdf")

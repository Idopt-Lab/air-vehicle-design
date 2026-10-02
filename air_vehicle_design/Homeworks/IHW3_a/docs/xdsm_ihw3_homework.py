"""XDSM of the IHW3 homework: the TTPA main sizing loop (pyXDSM).
Each block is labelled with the problem that builds it.
One solver (the sizing loop, P12) carries three states: W_0, P_0, S_ref.
Blocks run in pass order (P11): propulsion, geometry, aerodynamics, constraint
analysis, sizing of wing and engine, mission, weights, takeoff-weight closure.
Rows/cols follow execution order. Above diagonal = feed-forward data,
below diagonal = feedback data. Thin black lines = process order."""
from pyxdsm.XDSM import XDSM, SOLVER, FUNC, LEFT

x = XDSM(use_sfmath=True)
T = lambda s: r"\text{" + s + "}"

# ---- Systems (diagonal, in execution order) ----
x.add_system("loop",  SOLVER, [T("Sizing loop (P12)"), r"W_0,\ P_0,\ S_{ref}"])
x.add_system("prop",  FUNC,   [T("Propulsion (P1)"), T("engine weight, length")])
x.add_system("geom",  FUNC,   [T("Geometry (P2)"), T("planform, tails, wetted area")])
x.add_system("aero",  FUNC,   [T("Aerodynamics (P3)"), r"C_{D_0} = C_{fe}\,S_{wet}/S_{ref}"])
x.add_system("ca",    FUNC,   [T("Constraint analysis"), T("+ cruise, Level 2 (P5)")])
x.add_system("size",  FUNC,   [T("Size wing, engine (P11)"), r"S = W_0/(W/S),\ P = W_0/(W/P)"])
x.add_system("miss",  FUNC,   [T("Mission, Level 2"), T("(P6, P7, P8, P9)")])
x.add_system("wts",   FUNC,   [T("Weights (P4)"), T("component build-up")])
x.add_system("close", FUNC,   [T("TOGW closure (P10)"), r"W_0^{new} = W_{pay}/(1 - W_f/W_0 - OEW/W_0)"])

# ---- External inputs (requirements file) ----
x.add_input("loop",  [T("Guesses, tol, relax"), r"W_0,\ P_0,\ S_0,\ w"])
x.add_input("prop",  [T("Raymer Tbl 10.4"), r"n_{eng}"])
x.add_input("geom",  [r"AR,\ \lambda\ \text{(constant)}", T("tails, fuselage, nacelle")])
x.add_input("aero",  r"C_{fe}")
x.add_input("ca",    [T("Requirements"), T("field, climb, cruise")])
x.add_input("miss",  [T("Mission profile"), T("range, speed, loiter, reserve")])
x.add_input("wts",   [T("Raymer Tbl 15.2"), T("unit weights")])
x.add_input("close", r"W_{payload}")

# ---- The loop writes the three states into the airplane ----
x.connect("loop", "prop",  r"P_0")
x.connect("loop", "geom",  r"S_{ref}")
x.connect("loop", "size",  r"W_0")
x.connect("loop", "miss",  r"W_0")
x.connect("loop", "wts",   r"W_0")
x.connect("loop", "close", r"W_0")

# ---- Propulsion ----
x.connect("prop", "geom", r"L_{eng}")
x.connect("prop", "ca",   r"k_P")
x.connect("prop", "miss", r"P_{SL},\ c,\ \eta_p")
x.connect("prop", "wts",  r"W_{eng}")

# ---- Geometry ----
x.connect("geom", "aero", r"S_{wet}/S_{ref}")
x.connect("geom", "miss", r"S_{ref}")
x.connect("geom", "wts",  r"S_{exp},\ S_{ht},\ S_{vt},\ S_{wet,fus}")

# ---- Aerodynamics ----
x.connect("aero", "ca",   r"C_{D_0},\ K")
x.connect("aero", "miss", r"C_{D_0},\ K")

# ---- Constraint analysis -> sizing ----
x.connect("ca", "size", r"(W/S),\ (W/P)")

# ---- Mission and weights -> closure ----
x.connect("miss", "wts",   r"W_f")
x.connect("miss", "close", r"W_f")
x.connect("wts",  "close", r"OEW")

# ---- Feedback to the loop (below diagonal) ----
x.connect("size",  "loop", r"S^{new},\ P^{new}")
x.connect("close", "loop", r"W_0^{new}")

# ---- Outputs ----
x.add_output("loop", [T("Converged airplane"), r"W_{TO},\ P_{SL},\ S_{ref}"], side=LEFT)
x.add_output("miss", T("fuel burn"), side=LEFT)
x.add_output("wts",  T("7 weight rows"), side=LEFT)

# ---- Process: one pass, then back to the loop ----
x.add_process(["loop", "prop", "geom", "aero", "ca", "size", "miss", "wts", "close", "loop"])

x.write("ihw3_homework_xdsm", quiet=True)

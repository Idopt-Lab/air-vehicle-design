%[text] # L03 - The wing in cruise: three levels of fidelity
%[text] **AOE 4065 - Aerodynamics and Wing Design, Lecture 3 of 5 (Boeing 737 MAX 8)**
%[text] We compute the cruise drag of the 737 MAX 8 three times. Each level needs more geometry than the level before it:
%[text] - **Level 1** - one correlation for the whole aircraft. Needs the span and the total wetted area.
%[text] - **Level 2** - planform methods. Needs the wing planform and the size of each component.
%[text] - **Level 3** - component build-up. Also needs the airfoil (thickness, its position, lift slope), the Reynolds number of each component, and the interference of each component. \
%%
%[text] ## The cruise condition
%[text] M 0.785 at 35,000 ft (Boeing 737-800 technical page). The atmosphere is the 1976 U.S. Standard Atmosphere (`isa_si`). The weight is the weight at the start of cruise: MTOW x 0.970 (warm-up and takeoff) x 0.985 (climb), from Raymer Table 3.2, p. 34.
%[text] $C\_L = \\frac{W}{q S}, \\quad q = \\frac{1}{2}\\rho V^2$
setup_aero_path;
ac  = b737_baseline();
atm = isa_si(ac.H_cruise);
V   = ac.M_cruise*atm.a;
q   = 0.5*atm.rho*V^2;
W   = ac.MTOW*ac.frac_to*ac.frac_cl*9.80665;      % N
CL  = W/(q*ac.S);
cruise = table([atm.T; atm.rho; atm.a; V; q; W; CL], 'VariableNames', "Value", 'RowNames', ...
    {'T (K)', 'rho (kg/m^3)', 'a (m/s)', 'V (m/s)', 'q (Pa)', 'W (N)', 'C_L'})
%%
%[text] ## Level 1 - one correlation for the whole aircraft
%[text] The maximum lift-to-drag ratio follows the **wetted aspect ratio** $A\_{wet} = b^2/S\_{wet}$:
%[text] $\\left(\\frac{L}{D}\\right)\_{max} = K\_{LD}\\sqrt{A\_{wet}}, \\quad K\_{LD} = 15.5 \\text{ for civil jets}$
%[text] Reference: Raymer Eqs. 3.11 and 3.12, pp. 39-40. Nicolai Fig. G.8 (p. 739) plots the same idea against $b/\\sqrt{S\_{wet}}$. The span is the reference span (34.30 m), without the winglets.
o3   = aero_737(ac, 3);
Awet = o3.planform.b^2/o3.S_wet;
LDmax_L1    = 15.5*sqrt(Awet);
LDmax_G8    = interp1(book_data().figG_8.x, book_data().figG_8.centre, sqrt(Awet));
level1 = table([Awet; LDmax_L1; LDmax_G8], 'VariableNames', "Value", 'RowNames', ...
    {'A_wet', '(L/D)max, Raymer Eq. 3.12', '(L/D)max, Nicolai Fig. G.8 centre line'})
%[text] Level 1 cannot tell you **why**. It has no drag polar, so it cannot give the drag at the cruise $C\_L$, and it cannot tell a swept wing from a straight one.
%%
%[text] ## Level 2 - planform methods
%[text] - $C\_{D0} = C\_{fe} S\_{wet}/S$, with $C\_{fe} = 0.0026$ for a civil transport (Raymer Table 12.3, p. 417).
%[text] - $K = 1/(\\pi A e)$. Two Level-2 methods give $e$ (below). $A$ is the effective AR with winglets.
%[text] - $C\_{L\\alpha}$ from Raymer Eq. 12.6 with $\\eta = 0.95$. \
%[text] **Method A - Raymer's statistical fits.** Straight wing: $e = 1.78(1 - 0.045 A^{0.68}) - 0.64$ (Eq. 12.48). Swept wing, $\\Lambda\_{LE} > 30\\degree$: $e = 4.61(1 - 0.045 A^{0.68})(\\cos\\Lambda\_{LE})^{0.15} - 3.1$ (Eq. 12.49). Between 0° and 30°, interpolate linearly (p. 444).
%[text] **Method B - Kroo, with Shevell's flight-test factor.** The fuselage reduces the span efficiency, and the viscous drag grows with lift:
%[text] $e = \\frac{1}{\\frac{1}{u s} + K C\_{D0} \\pi A}, \\quad s = 1 - 2\\left(\\frac{d\_F}{b}\\right)^2, \\quad u = 0.99, \\quad K = 0.38$
%[text] Reference: Nita & Scholz, "Estimating the Oswald Factor from Basic Aircraft Geometrical Parameters", Deutscher Luft- und Raumfahrtkongress 2012, Eqs. 6-8, p. 2 (method of Kroo; $K = 0.38$ from DC-8 and DC-9 flight tests). $C\_{D0}$ is the Level-2 value above. This is the method Level 2 uses.
o2 = aero_737(ac, 2);
[e_int, e48, e49] = oswald_raymer(o2.A_eff, o2.planform.sweep_LE);
[e_kroo, s_fus] = oswald_kroo(o2.A_eff, o2.CD0, sqrt(ac.fus_w*ac.fus_h)/o2.planform.b);
oswald = table([e48; e49; e_int; s_fus; e_kroo], 'VariableNames', "Value", 'RowNames', ...
    {'A: Eq. 12.48 (straight wing)', 'A: Eq. 12.49 at the 737 LE sweep', ...
     sprintf('A: interpolated at %.1f deg', o2.planform.sweep_LE), ...
     'B: fuselage factor s', 'B: e, Kroo/Shevell (used at Level 2)'})
%[text] **Method A fails here.** Eq. 12.49 is a fit to swept wings, mostly fighters, and it falls quickly as $A$ increases. At the 737's $A \\approx 11$ it gives $e \\approx 0.38$, and the interpolated value is near it. A real airliner has $e$ near 0.75 to 0.85.
%[text] Method B gives $e \\approx 0.80$, because it is built on transport flight data. Both methods use only the planform and the fuselage size. Neither can see the leading edge.
%%
%[text] ## Level 3 - component build-up
%[text] $C\_{D0} = \\frac{\\sum\_c C\_{f,c} FF\_c Q\_c S\_{wet,c}}{S} + C\_{D,LP}$  (Raymer Eq. 12.24, p. 417)
%[text] - $C\_f$: fully turbulent flat plate, $C\_f = 0.455/\[(\\log\_{10} Re)^{2.58}(1 + 0.144 M^2)^{0.65}\]$ (Nicolai Eqs. 2.22 and 2.25, p. 64). $Re$ on the MAC for the wing and tails, on the length for bodies (Raymer Eq. 12.25, p. 418). $Re$ is limited by surface roughness (Raymer Eq. 12.28, p. 421; smooth paint).
%[text] - $FF$: wing and tails, $\[1 + \\frac{0.6}{(x/c)\_m}\\frac{t}{c} + 100(\\frac{t}{c})^4\]\[1.34 M^{0.18}(\\cos\\Lambda\_m)^{0.28}\]$ (Eq. 12.30); fuselage, $0.9 + 5/f^{1.5} + f/400$ (Eq. 12.31); nacelle, $1 + 0.35/f$ (Eq. 12.32), p. 422-423.
%[text] - $Q$: wing 1.0, fuselage 1.0, tails 1.04, nacelles 1.3 (Raymer p. 425). Leakage and protuberance: 3.5 % (Raymer Table 12.8, p. 431: 2-5 % for jet transports). \
o3.buildup
CD0_parts = table(o3.CD0 - o3.CD0_LP, o3.CD0_LP, o3.CD0, ...
    'VariableNames', ["Sum_of_components", "Leakage_protuberance", "CD0_total"])
%%
%[text] ## Level 3 - drag due to lift by leading-edge suction
%[text] Raymer's leading-edge-suction method uses the two limits of $K$:
%[text] $K\_0 = \\frac{1}{C\_{L\\alpha}} \\text{ (no suction)}, \\quad K\_{100} = \\frac{1}{\\pi A} \\text{ (full suction)}, \\quad K = S K\_{100} + (1 - S) K\_0$
%[text] Here $S$ is the **leading-edge suction**, not the wing area. It is the fraction of the ideal suction force on the wing nose that the wing really gets. The low pressure around a round nose pulls the wing forward and cancels part of the drag due to lift. $S = 1$ gives the ideal $K\_{100}$; $S = 0$ gives $K\_0$.
%[text] Reference: Raymer Eqs. 12.56 and 12.57, p. 447. For a large-radius airliner wing, $S \\approx 0.93$ (p. 450).
%[text] $C\_{L\\alpha}$ is Raymer Eq. 12.6 with the section slope of the NACA 4412: $\\eta = c\_{l\\alpha}/(2\\pi/\\beta)$ (Eq. 12.8). With the Prandtl-Glauert rule (Nicolai Eq. 2.7), $\\beta$ cancels. Raymer p. 400 limits $(S\_{exp}/S)F$ to 0.98.
%[text] Lesson model (assumption): Nicolai's non-elliptic factors $\\tau$ and $\\delta$ (Fig. 2.10) correct $C\_{L\\alpha}$ and $K\_{100}$ for the taper ratio. At the 737's taper ratio they are small.
lift = table([o3.eta; o3.CLa_info.SF; o3.CLa_info.SF_used; o3.tau; o3.delta; o3.CLa; o3.e; o3.K], ...
    'VariableNames', "Value", 'RowNames', {'eta', '(S_exp/S)F', '(S_exp/S)F used (limit 0.98)', ...
    'tau (Nicolai Fig. 2.10)', 'delta (Nicolai Fig. 2.10)', 'C_L alpha (per rad)', 'e', 'K'})
%%
%[text] ## The three levels side by side
%[text] $\\frac{L}{D} = \\frac{C\_L}{C\_{D0} + K C\_L^2}, \\quad \\left(\\frac{L}{D}\\right)\_{max} = \\frac{1}{2\\sqrt{C\_{D0} K}}$
K2A = 1/(pi*o2.A_eff*e_int);                 % Level 2, method A (Raymer fits)
LD2A = CL/(o2.CD0 + K2A*CL^2);   LD2 = CL/(o2.CD0 + o2.K*CL^2);   LD3 = CL/(o3.CD0 + o3.K*CL^2);
ladder = table( ...
    ["b, S_wet"; "planform, component sizes"; "planform, component sizes"; "+ airfoil, Re, interference"], ...
    [NaN; o2.CD0; o2.CD0; o3.CD0], [NaN; e_int; o2.e; o3.e], [NaN; LD2A; LD2; LD3], ...
    [LDmax_L1; 1/(2*sqrt(o2.CD0*K2A)); 1/(2*sqrt(o2.CD0*o2.K)); 1/(2*sqrt(o3.CD0*o3.K))], ...
    'VariableNames', ["Geometry_needed", "CD0", "e", "LD_cruise", "LD_max"], ...
    'RowNames', {'Level 1', 'Level 2, A: Raymer fits', 'Level 2, B: Kroo/Shevell', 'Level 3'})
%[text] Level 1 and Level 3 agree on $(L/D)\_{max}$. The two Level-2 methods use the same geometry and differ by about 40 %: A is about 20 % low, and B is about 11 % high (its $C\_{fe}$ gives a lower $C\_{D0}$ than the Level-3 build-up, and a higher $e$). **More fidelity is not always closer - but at a low fidelity, the answer depends on which correlation you pick, and a method that cannot see the variable that matters (here, the leading edge) can be badly wrong.**
fig = new_figure([100 100 900 450]);
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
CLv = linspace(0, 1.0, 100);
plot(ax, o2.CD0 + K2A*CLv.^2,  CLv, ':',  'LineWidth', 1.6, 'DisplayName', 'Level 2, A: Raymer fits');
plot(ax, o2.CD0 + o2.K*CLv.^2, CLv, '--', 'LineWidth', 1.6, 'DisplayName', 'Level 2, B: Kroo/Shevell');
plot(ax, o3.CD0 + o3.K*CLv.^2, CLv, '-',  'LineWidth', 1.8, 'DisplayName', 'Level 3');
yline(ax, CL, ':', sprintf('cruise C_L = %.2f', CL), 'HandleVisibility', 'off');
xlabel(ax, 'C_D'); ylabel(ax, 'C_L'); legend(ax, 'Location', 'southeast');
title(ax, '737 MAX 8 cruise drag polar, M 0.785, 35,000 ft');
%[text] Not included: wave drag. The form factors are valid up to the drag-divergence Mach number (Raymer p. 422). **Assumption:** M 0.785 is below the drag-divergence Mach number of the 737 wing. (The maximum operating Mach number is 0.82, EASA TCDS IM.A.120.)

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

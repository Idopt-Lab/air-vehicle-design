%[text] # L02 - The airfoil section (2-D)
%[text] **AOE 4065 - Aerodynamics and Wing Design, Lecture 2 of 5 (Boeing 737 MAX 8)**
%[text] A wing is made of airfoil sections. The section data are the **input** to every wing method in L03 to L05. This lecture shows the section data of the NACA 4412, and how thickness, camber and leading-edge radius change a section.
%%
%[text] ## NACA 4412 section data: Nicolai Table F.1
%[text] NACA 4-digit name: 4 = maximum camber 4 % chord, 4 = at 40 % chord, 12 = thickness 12 % chord.
%[text] ![Nicolai and Carichner, Table F.1, NACA 4412](text:image:nicolai_tableF1)
%[text] Source: Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design*, Vol. I, Table F.1. The column header of $\\alpha\_{c\_{l,max}}$ says "per deg", but the value is an angle in degrees.
setup_aero_path;
F1 = book_data().tableF1;
tableF1 = table([F1.alpha0L_deg; F1.cm0; F1.cla_per_deg; F1.ac; F1.alpha_clmax; F1.clmax; F1.alpha_star], ...
    'VariableNames', "Value", 'RowNames', ...
    {'alpha zero lift (deg)', 'c_m0', 'c_l alpha (per deg)', 'aerodynamic centre (x/c)', ...
     'alpha at c_l max (deg)', 'c_l max', 'alpha* (deg)'})
%%
%[text] ## The section drag: Abbott and von Doenhoff, NACA 4412
%[text] ![Abbott and von Doenhoff, Theory of Wing Sections, App. IV, NACA 4412, annotated](text:image:avd_naca4412)
%[text] Source: Abbott & von Doenhoff, *Theory of Wing Sections*, App. IV, pp. 488-489. Left: lift and moment against angle of attack. Right: drag and moment against lift coefficient. Use the curve for Re = 9 x 10^6 (diamond symbols).
%[text] How to read the annotations:
%[text] - Left, red: $c\_{l,max} = 1.67$ at $\\alpha = 14$ deg, the values of Table F.1. Blue: $\\alpha\_{0L} = -3.8$ deg.
%[text] - Right, red: the minimum drag, $c\_{d,min} = 0.0060$, at $c\_l = 0.6$ (the red vertical line).
%[text] - Right, blue: a second point, $c\_d = 0.010$ at $c\_l = 1.2$.
%[text] - Right, magenta: these two points give $k''$.
%[text] - Right, green: $c\_d = 0.0062$ at $c\_l = 0$. \
%[text] **Careful - three handwritten slips on this figure.** The notes "$c\_{l,min} = 0.04$" and "$c\_l = 0.06$" must read **0.6**: the red line is at $c\_l = 0.6$, and $0.6/0.006 = 100$. The note "$(c\_l/c\_d)\_{max} = 100$" is $c\_l/c\_d$ **at minimum drag**, not the maximum. The next section finds the maximum.
AvD = book_data().avd4412;
readings = table([AvD.cl_min; AvD.cl_2; 0], [AvD.cd_min; AvD.cd_2; AvD.cd_cl0], ...
    ["red: minimum drag"; "blue: second point"; "green: zero lift"], ...
    'VariableNames', ["c_l", "c_d", "On_the_figure"], ...
    'RowNames', {'point 1', 'point 2', 'check point'})
%%
%[text] ## From the readings to the section polar
%[text] Near the drag minimum, the section drag is a parabola about the lift coefficient of minimum drag (Nicolai & Carichner, Eq. 2.6a, p. 41):
%[text] $c\_d = c\_{d,min} + k''(c\_l - c\_{l,min})^2$
%[text] Put point 2 into it:
%[text] $k'' = \\frac{c\_{d,2} - c\_{d,min}}{(c\_{l,2} - c\_{l,min})^2}$
%[text] The maximum of $c\_l/c\_d$ is **not** at minimum drag. Set $d(c\_l/c\_d)/dc\_l = 0$:
%[text] $c\_l^{\\ast} = \\sqrt{c\_{d,min}/k'' + c\_{l,min}^2}$
kpp      = (AvD.cd_2 - AvD.cd_min)/(AvD.cl_2 - AvD.cl_min)^2;
polar2d  = @(cl) AvD.cd_min + kpp*(cl - AvD.cl_min).^2;          % Nicolai Eq. 2.6a
clOpt    = sqrt(AvD.cd_min/kpp + AvD.cl_min^2);
sectionPolar = table([kpp; AvD.cl_min/AvD.cd_min; clOpt; clOpt/polar2d(clOpt); ...
                      polar2d(F1.clmax); polar2d(0); AvD.cd_cl0], 'VariableNames', "Value", ...
    'RowNames', {'k''''', 'c_l/c_d at minimum drag', 'c_l for maximum c_l/c_d', ...
     'maximum c_l/c_d', 'c_d at c_l max = 1.67 (parabola)', 'c_d at c_l = 0 (parabola)', ...
     'c_d at c_l = 0 (figure)'})
cl  = linspace(-0.2, F1.clmax, 200);
fig = new_figure([100 100 1000 420]);
tl = tiledlayout(fig, 1, 2, 'Padding', 'compact');
ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
plot(ax, polar2d(cl), cl, 'LineWidth', 1.6, 'DisplayName', 'Eq. 2.6a through points 1 and 2');
plot(ax, [AvD.cd_min AvD.cd_2], [AvD.cl_min AvD.cl_2], 'ks', 'MarkerFaceColor', 'k', 'DisplayName', 'points 1 and 2');
plot(ax, AvD.cd_cl0, 0, 'g^', 'MarkerFaceColor', 'g', 'DisplayName', 'check point (figure)');
xlabel(ax, 'c_d'); ylabel(ax, 'c_l'); title(ax, 'NACA 4412 section polar'); legend(ax, 'Location', 'southeast');
ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
plot(ax, cl, cl./polar2d(cl), 'LineWidth', 1.6);
xline(ax, clOpt, ':', 'max c_l/c_d'); xline(ax, AvD.cl_min, '--', 'min c_d');
xlabel(ax, 'c_l'); ylabel(ax, 'c_l / c_d'); title(ax, 'Section lift-to-drag ratio');
%[text] Three results:
%[text] 1. $k'' \\approx 0.011$, and $c\_d \\approx 0.0187$ at $c\_{l,max}$. These agree with the blue notes on the figure.
%[text] 2. $c\_l/c\_d$ is 100 at minimum drag, but its maximum is about 129, at $c\_l \\approx 0.95$. Away from the minimum, the lift grows faster than the drag.
%[text] 3. At $c\_l = 0$ the parabola gives $c\_d \\approx 0.0100$, but the figure gives 0.0062. The parabola is good near the two points that define it. Below the minimum, the real drag bucket is much flatter. \
%[text] A section has $c\_l/c\_d$ near 130. A complete aircraft has $L/D$ near 18 (L03). The difference is the subject of L03: induced drag, the fuselage, the tails and the nacelles.
%%
%[text] ## Thickness
%[text] A thicker section has more pressure drag, so its drag rises. Its maximum lift rises up to about 13 % thickness and then falls.
d = book_data();
fig = new_figure([100 100 1000 420]);
tl = tiledlayout(fig, 1, 2, 'Padding', 'compact');
ax = nexttile(tl); plot(ax, 100*d.fig4_11.tc, d.fig4_11.cd_cl0, '-o', 'LineWidth', 1.4); grid(ax, 'on');
xlabel(ax, 't/c (%)'); ylabel(ax, 'c_d at c_l = 0'); title(ax, 'NACA 24XX drag  [Raymer Fig. 4.11, p. 69]');
ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
plot(ax, 100*d.fig4_13.tc_24, d.fig4_13.cl_24, '-o', 'LineWidth', 1.4, 'DisplayName', '24XX');
plot(ax, 100*d.fig4_13.tc_14, d.fig4_13.cl_14, '-s', 'LineWidth', 1.4, 'DisplayName', '14XX');
plot(ax, 100*d.fig4_13.tc_00, d.fig4_13.cl_00, '-^', 'LineWidth', 1.4, 'DisplayName', '00XX');
xlabel(ax, 't/c (%)'); ylabel(ax, 'c_{l max}'); legend(ax, 'Location', 'southeast');
title(ax, 'Maximum lift  [Raymer Fig. 4.13, p. 70]');
%[text] Section drag increases with thickness: about +30 % from 8 % to 16 % thickness. Nicolai Table 7.1 says that thickness has **no effect** on subsonic $C\_{D0}$. L05 shows what the complete aircraft does.
%%
%[text] ## Camber
%[text] Camber moves the whole lift curve up. Two rules:
%[text] - "The negative angle of attack for zero lift in degrees equals the airfoil's percent camber" (Raymer, p. 397). NACA 4412: 4 % camber, and $\\alpha\_{0L} = -3.8\\degree $.
%[text] - The lift slope does not change: $c\_{l\\alpha} \\approx 2\\pi$ per rad for all low-speed sections (Nicolai, Sec. 7.5, p. 178). \
%[text] Camber also moves the drag bucket to a higher $c\_l$, and it increases $c\_{l,max}$.
camberTable = table(d.camber.pct(:), d.camber.clmax(:), ...
    ["NACA 0012 (Raymer Fig. 4.13)"; "NACA 1412 (Raymer Fig. 4.13)"; ...
     "NACA 2412 (Raymer Fig. 4.13)"; "NACA 4412 (Nicolai Table F.1)"], ...
    'VariableNames', ["Camber_pct", "cl_max", "Source"])
%[text] The bucket centres of the NACA 2415 and 4415 (Raymer App. D, pp. 981-982) are near $c\_l$ = 0.22 and 0.40. This lesson uses $c\_{l,min} \\approx 0.1 \\times$ (camber in %) as an **assumption** for L05.
%%
%[text] ## Leading-edge radius
%[text] A sharp leading edge makes the flow separate early, at a lower angle of attack. So $c\_{l,max}$ generally increases with a larger leading-edge radius (Nicolai, p. 176).
%[text] In a NACA family the leading-edge radius is not free: it scales with $(t/c)^2$. Raymer App. D prints 0.40 % chord for the NACA 0006 and 0.89 % for the 0009: $0.40 \\times (9/6)^2 = 0.90$. So when you change the thickness of a NACA section, you also change its leading-edge radius. L05 uses this.
rle = table([d.le_radius.naca0006; d.le_radius.naca0009; d.le_radius.naca0006*(9/6)^2], ...
    'VariableNames', "LE_radius_pct_chord", 'RowNames', ...
    {'NACA 0006 (Raymer App. D)', 'NACA 0009 (Raymer App. D)', 'NACA 0006 scaled by (9/6)^2'})

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

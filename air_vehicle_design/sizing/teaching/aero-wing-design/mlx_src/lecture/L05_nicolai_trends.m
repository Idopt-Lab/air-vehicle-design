%[text] # L05 - Wing design trends: Nicolai Table 7.1, cell by cell
%[text] **AOE 4065 - Aerodynamics and Wing Design, Lecture 5 of 5 (Boeing 737 MAX 8)**
%[text] Nicolai & Carichner, Table 7.1 (p. 193) summarizes how each wing variable changes the aircraft. It is the last slide of the lecture deck.
%[text] ![Nicolai and Carichner, Table 7.1: summary of airfoil and planform effects](text:image:nicolai_table7_1)
%[text] Here we **compute** the cells: we change one variable of the 737 wing and keep all the others (and the wing area) at the baseline. The 737 is a subsonic aircraft, so we compute the subsonic columns only.
%[text] For each cell we compare three things:
%[text] - **Nicolai's arrow.**
%[text] - **Level 2** (dashed lines): planform-only methods ($e$ by Kroo/Shevell, L03 method B).
%[text] - **Level 3** (solid lines): planform, airfoil and component methods (see L03). \
%[text] **"No effect"** here means the curve stays inside a band of ±3 % of its baseline value (the grey strip).
setup_aero_path;
%%
%[text] ## Aspect ratio
%[text] A longer, narrower wing at the same area: $K$ falls (less induced drag), $C\_{L\\alpha}$ rises, the wing gets heavier (Raymer Eq. 15.25: $A^{0.5}$) and holds less fuel (Roskam Eq. 6.2: $S^2/b$).
fig = plot_trend_row(trend_737("AR"));
%[text] Two cells disagree with Nicolai:
%[text] - $C\_{D0}$ **rises 5 %.** At a fixed area, a narrower root chord leaves less wing inside the fuselage. So the exposed (wetted) wing area grows, and the shorter chord has a lower Reynolds number and a higher $C\_f$. Nicolai's "no effect" ignores these second-order changes.
%[text] - $C\_{L,max}$**: no effect.** Neither Raymer Eq. 12.15 nor Eq. 12.16 has an aspect-ratio term for a high-AR wing. But Nicolai's own data (next section) show the effect. The methods cannot show what they do not contain. \
%%
%[text] ## In class 1: aspect ratio and maximum lift
%[text] Nicolai Fig. 2.9 (p. 44) gives measured $C\_L$ against $\\alpha$ for wings of NACA 65-410 section at four aspect ratios. The maximum lift rises with AR, because a finite wing loses lift near its tips.
%[text] ![Nicolai and Carichner, Fig. 2.9: effect of finite span on lift, NACA 65-410](text:image:nicolai_fig2_9)
d = book_data().fig2_9;
fig29 = table(d.AR(:), d.CLmax(:), 'VariableNames', ["AR", "CL_max"])
%[text] The Raymer equations are for the **high-AR** range and fold this effect into one constant (the 0.9 in Eq. 12.15). To see it, you need a method with the spanwise lift distribution (lifting-line theory): a higher fidelity, with more geometry.
%%
%[text] ## In class 2: aspect ratio and K - the method that fails
%[text] Level 2 has two methods for $e$ (L03). The figure shows $K$ against AR for both, and for Level 3.
ARs = linspace(6, 14, 41);  base = b737_baseline();
[KA, KB, K3] = deal(zeros(size(ARs)));
for i = 1:numel(ARs)
    a = base;  a.AR = ARs(i);
    o2 = aero_737(a, 2);  o3 = aero_737(a, 3);
    KA(i) = 1/(pi*o2.A_eff*o2.e_raymer);   KB(i) = o2.K;   K3(i) = o3.K;
end
fig = new_figure([100 100 900 420]);
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
plot(ax, ARs, KA, ':',  'LineWidth', 1.8, 'DisplayName', 'Level 2, A: Raymer fits (Eqs. 12.48/12.49)');
plot(ax, ARs, KB, '--', 'LineWidth', 1.6, 'DisplayName', 'Level 2, B: Kroo/Shevell');
plot(ax, ARs, K3, '-',  'LineWidth', 1.8, 'DisplayName', 'Level 3: leading-edge suction');
xline(ax, base.AR, ':', '737', 'HandleVisibility', 'off');
xlabel(ax, 'geometric aspect ratio'); ylabel(ax, 'K'); legend(ax, 'Location', 'northeast');
title(ax, '737 MAX 8 at cruise: K against aspect ratio, three methods');
%[text] Method A gives a $K$ that **rises** again at high AR. That is not physical. Eq. 12.49 is a fit for swept fighter wings. Method B and Level 3 give a $K$ that falls all the way. A method is good only inside the range of the data it was fitted to. In the trend figures, the dashed Level-2 line is method B.
%%
%[text] ## Sweep
fig = plot_trend_row(trend_737("Sweep"));
%[text] All cells agree. $C\_{L\\alpha}$ and $C\_{L,max}$ fall with $\\cos\\Lambda$; the wing gets heavier ($1/\\cos\\Lambda$ in Raymer Eq. 15.25: the structural span grows).
%[text] **In class 3: sweep and** $C\_{D0}$**.** The form factor of Raymer Eq. 12.30 has $(\\cos\\Lambda\_m)^{0.28}$, so $C\_{D0}$ falls by about 3 %: right at the edge of the band. Is that "no effect"? It depends on where you draw the line. Nicolai's table is qualitative; the computed number tells you how much.
%%
%[text] ## Taper ratio
fig = plot_trend_row(trend_737("Taper"));
%[text] $K$ and $C\_{L\\alpha}$ have their best values near $\\lambda$ = 0.3 to 0.4, where the lift distribution is closest to elliptic. Only Level 3 shows this: Level 2 has no taper term for $K$ or $C\_{L\\alpha}$. The curves use Nicolai Fig. 2.10 ($\\tau$, $\\delta$) with this lesson's combination rule.
%[text] $C\_{D0}$ rises about 6 %: a larger taper ratio gives a smaller root chord, and again more exposed wing area. Nicolai says "no effect".
%%
%[text] ## Thickness ratio
fig = plot_trend_row(trend_737("t/c"));
%[text] A thicker wing is lighter ($(t/c)^{-0.4}$ in Raymer Eq. 15.25) and holds more fuel. These are the reasons to make a wing thick.
%[text] $C\_{D0}$ rises about 7 %: the form factor and the wetted area both increase with $t/c$, and Raymer Fig. 4.11 shows the section drag rising too. Nicolai's table says "no effect". Here the two books disagree.
%[text] $C\_{L,max}$: the section $c\_{l,max}$ peaks near 13 % (Fig. 4.13), and Raymer Fig. 12.9 reduces the wing ratio as the leading edge gets blunter. In this range the two effects cancel.
%%
%[text] ## Leading-edge radius (proxies)
fig = plot_trend_row(trend_737("LE radius"));
%[text] No source gives $K$ or $C\_{L,max}$ as a function of the leading-edge radius. So this row uses **proxies**:
%[text] - $K$: the **leading-edge suction** $S$, from 0.85 to 0.95. $S$ is not the wing area here. It is the fraction of the ideal suction force on the wing nose that the wing really gets (Raymer Eqs. 12.56-12.57, p. 447; see L03). The low pressure around a round nose pulls the wing forward and cancels part of the drag due to lift. $S = 1$: all of the suction, $K = 1/(\\pi A)$. $S = 0$: none, $K = 1/C\_{L\\alpha}$. Raymer (p. 447) gives $S$ = 0.85 to 0.95 for a wing with moderate sweep and a large leading-edge radius. A larger radius keeps more suction.
%[text] - $C\_{L,max}$: the NACA 00XX family from 6 % to 12 % thickness. Its radius grows with $(t/c)^2$ (L02). \
%[text] Wing volume: Nicolai says it rises, but no equation in our sources has the radius. It is not modelled.
%%
%[text] ## Camber
fig = plot_trend_row(trend_737("Camber"));
%[text] Camber moves the drag polar up: the minimum drag is at a $C\_L$ above zero (Nicolai Eq. 2.17). So the drag at $C\_L = 0$ rises, and the extra drag at the cruise $C\_L$ falls: that is the $K$ "decrease" in the table. The $C\_L$ of minimum drag ($0.1 \\times$ camber %) is an assumption.
%%
%[text] ## How do these models compare to the trends?
%[text] Each cell: Nicolai's arrow | the Level-3 arrow.
scoreGrid = trend_table()
%[text] Three lessons:
%[text] 1. **A method cannot show the effect of a variable it does not contain.** Level 2 has no taper term for $K$, no thickness term for weight, no airfoil at all. To see those trends, you need Level 3 and its extra geometry.
%[text] 2. **A method is good only inside the data it was fitted to.** Raymer Eq. 12.49 fails for a high-AR airliner.
%[text] 3. **"No effect" is a size, not a zero.** Several of Nicolai's "no effect" cells are real effects of 3-7 %. A trend table tells you the direction; a calculation tells you how much. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # L01 - The 737 MAX 8 wing: what the geometry is
%[text] **AOE 4065 - Aerodynamics and Wing Design, Lecture 1 of 5 (Boeing 737 MAX 8)**
%[text] The message of this lesson: **the right fidelity matters, and a higher fidelity needs more geometry.** A low-fidelity method needs only the aircraft type or a few areas. A higher-fidelity method needs the planform, the airfoil and each component. If the method does not know a variable, it cannot show the effect of that variable.
%[text] This lecture sets up the geometry that all the other lectures use. Every number has a source.
%[text] Units: SI (m, kg, N, Pa, s). Angles in degrees.
%%
%[text] ## The inputs and their sources
%[text] Boeing does not publish a wing area, sweep, taper or airfoil for the 737 MAX. The official Boeing document (the ACAP) gives the span, the fuselage and the weights. The reference wing comes from a textbook data file, Jenkinson, Simpkin & Rhodes, *Civil Jet Aircraft Design* (1999), Data A, for the 737-800. **Assumption:** the MAX has the 737-800 reference wing, plus its own winglet.
%[text] The airfoil is a stand-in: NACA 4412, with data from Nicolai & Carichner, Table F.1. Boeing does not publish the MAX airfoils.
setup_aero_path;
[ac, sources] = b737_baseline();
sources
%%
%[text] ## The trapezoidal reference wing
%[text] A conceptual-design wing is a straight-tapered trapezoid that goes through the fuselage to the centreline. From the area $S$, the aspect ratio $A$ and the taper ratio $\\lambda$:
%[text] $b = \\sqrt{A S}, \\quad c\_{root} = \\frac{2S}{b(1+\\lambda)}, \\quad c\_{tip} = \\lambda c\_{root}$
%[text] $\\bar{c} = \\frac{2}{3} c\_{root} \\frac{1 + \\lambda + \\lambda^2}{1 + \\lambda}, \\quad \\bar{Y} = \\frac{b}{6} \\frac{1 + 2\\lambda}{1 + \\lambda}$
%[text] Reference: Raymer, *Aircraft Design*, 6th ed., Eqs. 7.5 to 7.9, pp. 191-192.
p = wing_planform(ac.S, ac.AR, ac.lambda, ac.sweep_c4, ac.fus_w, ac.xc_m);
planform = table([p.b; p.c_root; p.c_tip; p.MAC; ac.MAC_tcds; p.ybar; p.S_exp], ...
    'VariableNames', "Value", 'RowNames', ...
    {'span b (m)', 'root chord (m)', 'tip chord (m)', 'MAC (m)', ...
     'MAC, EASA TCDS IM.A.120 (m)', 'MAC spanwise position (m)', 'exposed area, both sides (m^2)'})
%[text] The trapezoid MAC is within 1.5 % of the certified MAC. So the reference trapezoid is a good model of the real wing.
%%
%[text] ## Sweep of the other chord lines
%[text] Each equation wants a different sweep. The lift-curve slope and the form factor want the sweep of the **maximum-thickness line**. The Oswald fits and the maximum-lift chart want the **leading-edge** sweep. The wing-weight equation wants the **quarter-chord** sweep. Mix them up and the answer is wrong.
%[text] $\\tan\\Lambda\_n = \\tan\\Lambda\_m - \\frac{4}{A}(n - m)\\frac{1 - \\lambda}{1 + \\lambda}$
%[text] $n$ and $m$ are chord fractions: 0 is the leading edge, 0.25 the quarter chord, 1 the trailing edge. Reference: Gudmundsson, *General Aviation Aircraft Design* (2014), Eq. 9-11, p. 305, from USAF DATCOM.
sweeps = table([sweep_at(0, ac.sweep_c4, 0.25, ac.AR, ac.lambda); ac.sweep_c4; ...
                sweep_at(ac.xc_m, ac.sweep_c4, 0.25, ac.AR, ac.lambda); ...
                sweep_at(1, ac.sweep_c4, 0.25, ac.AR, ac.lambda)], ...
    'VariableNames', "Sweep_deg", 'RowNames', ...
    {'leading edge', 'quarter chord (input)', 'max thickness (0.30c)', 'trailing edge'})
fig = new_figure([100 100 900 480]);
ax = axes(fig);
draw_half_wing(ax, p, ac.fus_w, ac.xc_m);
title(ax, '737 MAX 8 reference wing, right half (winglet not shown)');
%%
%[text] ## Winglets
%[text] A winglet makes the wing act as if it had a larger span. Raymer gives
%[text] $A\_{effective} = A\\left(1 + \\frac{h}{b}\\right)^2$
%[text] with $h$ the winglet height and $b$ the span without winglets (Raymer Eq. 12.11, p. 400). The ACAP gives $h = 2.92$ m.
A_eff = ac.AR*(1 + ac.h_winglet/p.b)^2;
aspect = table([ac.AR; A_eff], 'VariableNames', "Aspect_ratio", ...
    'RowNames', {'geometric', 'effective, Raymer Eq. 12.11'})
%%
%[text] ## Wetted areas
%[text] Skin friction acts on the wetted area, so the drag build-up in L03 needs the wetted area of each component.
%[text] - Wing and tails: $S\_{wet} = S\_{exp}(1.977 + 0.52 \\cdot t/c)$ for $t/c > 0.05$ (Raymer Eq. 7.12, p. 204).
%[text] - Fuselage with a cylindrical mid-section: $S\_{wet} = \\pi D l (1 - 2/f)^{2/3}(1 + 1/f^2)$, $f = l/D$ (Roskam, *Airplane Design* Part II, Eq. 12.3, p. 284). $D$ is the equivalent diameter $\\sqrt{w h}$ (assumption).
%[text] - Nacelles: the side area of a cylinder, $\\pi d l$. \
D_fus = sqrt(ac.fus_w*ac.fus_h);
Swet = [wetted_area("surface", p.S_exp, ac.tc); ...
        wetted_area("fuselage", ac.fus_l, D_fus); ...
        wetted_area("surface", ac.ht_S, ac.tail_tc); ...
        wetted_area("surface", ac.vt_S, ac.tail_tc); ...
        ac.n_eng*wetted_area("cylinder", ac.nac_l, ac.nac_d)];
wetted = table(Swet, 100*Swet/sum(Swet), 'VariableNames', ["S_wet_m2", "Share_pct"], ...
    'RowNames', {'wing', 'fuselage', 'horizontal tail', 'vertical tail', 'nacelles (2)'})
SwetOverS = sum(Swet)/ac.S
%[text] The total wetted area is about 6.4 times the wing area. The wing is only about a quarter of it. Remember this when you change the wing: most of the skin-friction drag does not belong to the wing.
function draw_half_wing(ax, p, d_fus, xc_m)
    % Right half of the reference trapezoid, seen from above. y is spanwise
    % (0 = centreline), x is chordwise (0 = root leading edge, positive aft).
    % Each chord line n is at x = y*tan(sweep_LE) + n*c(y).
    hold(ax, 'on'); grid(ax, 'on'); axis(ax, 'equal'); set(ax, 'YDir', 'reverse');
    y   = [0, p.b/2];
    xLE = y*tand(p.sweep_LE);
    c   = [p.c_root, p.c_tip];
    fill(ax, [y, fliplr(y)], [xLE, fliplr(xLE + c)], [0.85 0.90 1.0], ...
         'EdgeColor', 'k', 'LineWidth', 1.4, 'DisplayName', 'reference trapezoid');
    lines = [0.25, xc_m];
    names = ["quarter chord", sprintf("max thickness (%.2fc)", xc_m)];
    styles = ["--", ":"];
    for k = 1:numel(lines)
        plot(ax, y, xLE + lines(k)*c, styles(k), 'LineWidth', 1.4, 'DisplayName', names(k));
    end
    % Fuselage side: the wing inboard of this line is covered (not exposed)
    xline(ax, d_fus/2, '-.', 'fuselage side', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    % Mean aerodynamic chord at its spanwise position
    xm = p.ybar*tand(p.sweep_LE);
    plot(ax, [p.ybar p.ybar], [xm, xm + p.MAC], '-', 'LineWidth', 2.5, 'DisplayName', 'MAC');
    xlabel(ax, 'spanwise position y (m)'); ylabel(ax, 'chordwise position x (m)');
    legend(ax, 'Location', 'northeast');
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

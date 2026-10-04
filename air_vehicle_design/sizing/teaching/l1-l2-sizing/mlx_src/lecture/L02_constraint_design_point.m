%[text] # L02 - From requirements to a design point
%[text] **AOE 4065 - Aircraft Sizing, Lecture 2 of 7 (Boeing 777-200LR)**
%[text] The sizing loop needs two numbers before it can size anything: a wing loading $(W/S)^{\ast}$ and a thrust-to-weight ratio $(T/W)^{\ast}$. Those two numbers are the **design point**. They come from the requirements, not from the aircraft.
%[text] Each requirement becomes one curve in the $T/W$ against $W/S$ plane. A design is acceptable if it sits **above every producer curve** and **to the left of every wall**. The design point is the best corner of that acceptable region.

%%
%[text] ## Build a fresh stack
setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_b777_stack();

%%
%[text] ## What the ten requirements are
%[text] The 777 carries ten conditions: two field lengths, six FAR-25 climb gradients, a ceiling, and cruise. They live in the requirements JSON. The constraint object turns each one into an object that can answer one question: at this wing loading, what thrust-to-weight do I demand?

names = strings(1, numel(con.constraints));
kind  = strings(size(names));
for k = 1:numel(con.constraints)
    c = con.constraints{k};
    names(k) = string(c.name);
    if isa(c, 'Only_WbyS')
        kind(k) = "wall  (limits W/S only)";
    else
        kind(k) = "producer  (demands T/W)";
    end
end
requirements = table(names(:), kind(:), ...
    'VariableNames', ["Condition", "Type"])

%%
%[text] ## The two kinds of curve
%[text] A **producer** answers `required_TW(W/S)`. Level flight, climb and takeoff all work this way, through the Mattingly master equation
%[text] $\frac{T}{W} = \frac{A}{W/S} + B \frac{W}{S} + C + D$
%[text] with $A=qC_{D0}/\alpha$, $B=(q/\alpha)K_1(n\beta/q)^2$, $C=K_2 n\beta/\alpha$, and $D=(\beta/\alpha)(P_s/V)$. Reference: Mattingly, *Aircraft Engine Design*, 2nd ed.
%[text] A **wall** answers `WS_max()` and says nothing about thrust. Landing field length is a wall: the aircraft must be slow enough to stop, whatever the engine does.
%[text] Every curve reads the aero and propulsion objects **live**. Change the drag and every curve moves. Remember that for L06.

fig = con.plot_diagram();
fig.Color = 'w';
if isprop(fig, 'Theme'), fig.Theme = 'light'; end
ax = fig.CurrentAxes;
title(ax, "B777-200LR constraint diagram  [metabook Fig. 4.6]");

%%
%[text] ## Pick the design point
%[text] For a jet transport, **down and to the right** is better: low $T/W$ is a small engine, high $W/S$ is a small and efficient wing. So the design point is the bottom-right corner of the acceptable region.
%[text] Two solvers find it. `optimal_point` walks the wing-loading grid and takes the best grid node. `optimal_point_continuous` runs `fmincon` to minimise $T/W$ subject to every residual staying at or below zero, and gets the exact corner. Both loops in this course use the continuous one.

[WS_grid, TW_grid] = con.optimal_point();
[WS_opt, TW_opt, info] = con.optimal_point_continuous();

WS_actual = 142.45;              % psf   [metabook Table 4.3]
TW_actual = 220000 / 766800;     % = 0.287  [metabook Fig. 4.7]

design = table( ...
    [WS_grid; WS_opt; WS_actual], [TW_grid; TW_opt; TW_actual], ...
    'VariableNames', ["W_over_S_psf", "T_over_W"], ...
    'RowNames', {'grid search', 'fmincon (used by the loops)', 'the real 777-200LR'})

%%
%[text] ## Which requirements are actually doing the work
%[text] At the optimum some residuals are exactly zero. Those are the **binding** constraints: the ones holding the design where it is. Every other requirement is satisfied with margin and is not driving anything. This list is the single most useful output of constraint analysis.

binding = info.active_names(:)

%%
%[text] ## Mark the real aircraft
%[text] The real 777 sits up and to the left of the corner, inside the acceptable region. It carries margin: more thrust than the requirements demand, and a slightly bigger wing. The sizing loop will not reproduce that margin, because it is asked for the *smallest* aircraft that meets the requirements. Keep that in mind when we compare numbers in L05 and L06.

hold(ax, 'on');
plot(ax, WS_opt, TW_opt, 'ko', 'MarkerSize', 10, 'LineWidth', 1.6, ...
    'DisplayName', 'Design point (loop target)');
plot(ax, WS_actual, TW_actual, 'kp', 'MarkerSize', 18, 'LineWidth', 1.0, ...
    'MarkerFaceColor', [0.95 0.75 0.10], 'DisplayName', 'Actual 777-200LR');
hold(ax, 'off');
fig

%%
%[text] ## What the loop does with these two numbers
%[text] Ratios, not sizes. The design point fixes only the *shape* of the aircraft:
%[text] $S_{ref} = \frac{W_{TO}}{(W/S)^{\ast}} \qquad T_{SL} = (T/W)^{\ast}  W_{TO}$
%[text] Give it a takeoff weight and both follow. So the sizing problem reduces to finding one number, $W_{TO}$. That is L04.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

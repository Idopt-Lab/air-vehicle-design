%[text] # L06 - The Level-2 sizing loop, and what the extra fidelity buys
%[text] **AOE 4065 - Aircraft Sizing, Lecture 6 of 7 (Boeing 777-200LR)**
%[text] Level 1 froze the design point before the loop started. That is a **modelling assumption**: it says the constraint curves do not move while the aircraft changes size. Level 2 stops assuming it and checks instead.
%[text] Three changes, and that is all:
%[text] 1. **Two state variables** instead of one. $T_{SL}$ becomes an independent under-relaxed unknown, not a number slaved to the weight.
%[text] 2. **The design point is re-solved every pass**, warm-started from the previous one.
%[text] 3. **The tail is resized every pass**, and the empty weight sees the new tail. \
%[text] Reference: Martins slide 8. Same aircraft, same discipline models, same closure equation. Only the loop changes.

%%
%[text] ## Why the design point can move at all
%[text] The 777 aerodynamics object **holds** the geometry object. Its parasite drag is $C_{D0} = C_{fe}\,S_{wet}/S_{ref}$, so a change in wing area moves the drag, which moves every constraint curve, which moves the design point. Watch it happen.

setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_b777_stack();

S0 = geom.S_ref;
p0 = aero.drag_polar(AircraftState(40000, 0.85));
[ws0, tw0] = con.optimal_point_continuous();
geom.S_ref = 0.75 * S0;                         % shrink the wing by a quarter
p1 = aero.drag_polar(AircraftState(40000, 0.85));
[ws1, tw1] = con.optimal_point_continuous();
geom.S_ref = S0;                                % put it back

moves = table([S0; 0.75*S0], [p0.CD0; p1.CD0], [ws0; ws1], [tw0; tw1], ...
    'VariableNames', ["S_ref_ft2", "CD0", "W_over_S_psf", "T_over_W"], ...
    'RowNames', {'as built', 'wing shrunk 25%'})

%%
%[text] **That is the whole argument for Level 2.** If the design point moves when the aircraft changes, then solving it once with the *starting* aircraft answers a question about an aircraft you are not going to build.

%%
%[text] ## Run both loops, same aircraft, same guess
%[text] A fresh stack for each, because the discipline objects are handles and the first run leaves them mutated.

[a1, p1o, w1, g1, m1, c1]     = build_b777_stack();
r1 = SizingLoopL1(a1, p1o, w1, g1, m1, c1).run(700000);

[a2, p2, w2, g2, m2, c2, t2]  = build_b777_stack();
r2 = SizingLoopL2(a2, p2, w2, g2, m2, c2, t2).run(700000, 200000);

compare = table( ...
    [r1.W_TO;  r1.T_SL;  r1.S_ref;  r1.WS;  r1.TW;  r1.n_iter], ...
    [r2.W_TO;  r2.T_SL;  r2.S_ref;  r2.WS;  r2.TW;  r2.n_iter], ...
    'VariableNames', ["Level_1_loop", "Level_2_loop"], 'RowNames', ...
    {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]', 'W/S [psf]', 'T/W [-]', 'iterations'})

%%
%[text] ## Result 1: the answer barely moved
%[text] Under a hundredth of a percent on takeoff weight. **Level 2 did not change the answer here.** That is worth saying out loud, because it is the honest result and it is a useful one.
%[text] The reason is in the numbers from L05: the wing area in the spec file was 4,605 ft², and the loop converged to about 4,598 ft². The starting aircraft was already the finished aircraft, so the frozen design point was frozen in the right place. Level 1 got away with its assumption.

%%
%[text] ## Result 2: Level 2 sized the tail, Level 1 could not
%[text] `SizingLoopL2` calls `tail.size()` on every pass and writes the areas into the geometry. `SizingLoopL1` has no tail object at all, and the 777 geometry file carries no tail areas, so after a Level-1 run they are still undefined.

tails = table([g1.S_ht; g1.S_vt], [r2.S_ht; r2.S_vt], ...
    'VariableNames', ["Level_1_loop", "Level_2_loop"], ...
    'RowNames', {'S_ht [ft^2]', 'S_vt [ft^2]'})

%%
%[text] **But be careful what you claim next.** It is tempting to say *and the empty weight sees the new tail*. On this aircraft that is **false**. `B777GeomL2` derives its exposed tail areas from the fixed Chapter-7 trapezoids, not from the loop-written reference areas, so the tail resize is write-only here. Double the tail and nothing downstream moves:

g1.S_ht = r2.S_ht;  g1.S_vt = r2.S_vt;  w1.W_TO = r2.W_TO;
before = [g1.S_exposed_ht; g1.S_wet; w1.W_tail.HT; w1.get_OEW(r2.W_TO)];
g1.S_ht = 2*r2.S_ht;
after  = [g1.S_exposed_ht; g1.S_wet; w1.W_tail.HT; w1.get_OEW(r2.W_TO)];
g1.S_ht = r2.S_ht;

tail_coupling = table(before, after, after - before, ...
    'VariableNames', ["S_ht_nominal", "S_ht_doubled", "change"], ...
    'RowNames', {'geom.S_exposed_ht', 'geom.S_wet', 'wts.W_tail.HT', 'wts.get_OEW'})

%%
%[text] All zeros. On the **F-16A** the same test moves every row, because `F16GeomL2` builds its tail chords and span from `S_ht`. Same loop, same step, different coupling, because the two geometry models were built to different plans.
%[text] **L06b** traces both aircraft properly and shows this in one chart. If you are teaching the coupling story, use that file.

%%
%[text] ## Result 3: now start from the wrong aircraft
%[text] Here is the test that separates the two loops. Put a badly wrong wing in the spec - 2,600 ft² instead of 4,605 - and size again. Nothing else changes.
%[text] Level 1 solves its design point **once, against that wrong wing**, and then never looks again. Level 2 re-solves every pass and walks away from the bad start.

[a3, p3, w3, g3, m3, c3]      = build_b777_stack();
g3.S_ref = 2600;
r1b = SizingLoopL1(a3, p3, w3, g3, m3, c3).run(700000);

[a4, p4, w4, g4, m4, c4, t4]  = build_b777_stack();
g4.S_ref = 2600;
r2b = SizingLoopL2(a4, p4, w4, g4, m4, c4, t4).run(700000, 200000);

bad_start = table( ...
    [r1.W_TO;  r1.WS;  r1.TW],  [r1b.W_TO; r1b.WS; r1b.TW], ...
    [r2.W_TO;  r2.WS;  r2.TW],  [r2b.W_TO; r2b.WS; r2b.TW], ...
    'VariableNames', ["L1_good_start", "L1_BAD_start", "L2_good_start", "L2_BAD_start"], ...
    'RowNames', {'W_TO [lbf]', 'W/S [psf]', 'T/W [-]'})

%%
%[text] **Read that table.** The Level-1 answer moved by about 3 % and its design point is plainly wrong: it reports 170 psf and 0.281 when the true optimum is about 161 psf and 0.266. The Level-2 answer is the same as before, to within a few hundred pounds.
%[text] So the value of the Level-2 loop is not a better number on a good day. It is **not depending on the guess you started from**. In real design work you do not know the answer in advance, which is the situation this test reproduces.

%%
%[text] ## What it cost
%[text] Level 2 runs `fmincon` on every pass instead of once, and carries a second under-relaxed state, so it takes several times as many passes and considerably more wall-clock time. That is the trade: robustness against cost.

plot_convergence(r2, "B777-200LR, SizingLoopL2");

%%
%[text] ## The two meanings of Level 2, one more time
%[text] **Loop fidelity** is what this lecture changed: how many unknowns, and what gets re-solved each pass. `SizingLoopL1` against `SizingLoopL2`.
%[text] **Discipline fidelity** is a separate axis: how one model computes its answer. The 777 stack used `B777WeightsL2`, a component build-up, next to `B777AeroL1` and `B777PropL1`, which are simple. Nothing forces the two axes to match, and mixing them on purpose is normal practice.
%[text] The same `SizingLoopL2` class also drives the Level-3 F-16 rung. There is no `SizingLoopL3`, because sizing has no equations of its own that change with fidelity - only a count of unknowns.
%[text] Next: **L07**, how hard the answer pushes back when a requirement changes.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

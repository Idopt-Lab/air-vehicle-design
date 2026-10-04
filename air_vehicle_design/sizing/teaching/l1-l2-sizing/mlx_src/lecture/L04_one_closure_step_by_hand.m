%[text] # L04 - One closure step, by hand
%[text] **AOE 4065 - Aircraft Sizing, Lecture 4 of 7 (Boeing 777-200LR)**
%[text] This is the centre of the course. Everything before it was setup; everything after it is repetition and bookkeeping.
%[text] One closure step takes a guess at the takeoff weight and returns a better one. Five sub-steps, in this order:
%[text] 1. size the wing from the design point, $S_{ref} = W_{TO}/(W/S)^{\ast}$
%[text] 2. size the engine from the design point, $T_{SL} = (T/W)^{\ast}\ W_{TO}$
%[text] 3. ask the mission for the fuel
%[text] 4. ask the weights model for the empty weight
%[text] 5. close, $W_{TO}^{new} = W_{payload}/(1 - W_{empty}/W_{TO} - W_{fuel}/W_{TO})$ \
%[text] Reference: Martins slide 6; Raymer 6th ed. Eq. 3.4; metabook Algorithm 1.

%%
%[text] ## Setup: a fresh stack and a frozen design point
setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_b777_stack();
[WS, TW] = con.optimal_point_continuous();
W0 = 700000;      % our first guess, deliberately off the answer

%%
%[text] ## Step through it once, with nothing hidden
%[text] `one_closure_step` is the body of `SizingLoopL1`, unrolled a single time. Open `helpers/one_closure_step.m` and read it: there are about fifteen lines of real work in there, and you have now seen every one of them.

s1 = one_closure_step(aero, prop, wts, geom, miss, WS, TW, W0);
print_closure_step(s1, "PASS 1");

%%
%[text] ## The answer disagrees with the question
%[text] We asked about a 700 000 lbf aeroplane. The models replied with a different weight. So try again with the reply.

s2 = one_closure_step(aero, prop, wts, geom, miss, WS, TW, s1.W0_new);
print_closure_step(s2, "PASS 2 - start from what pass 1 returned");

%%
%[text] ## Keep feeding the output back in
%[text] No under-relaxation yet. Straight substitution: whatever the closure returns becomes the next guess. Watch the residual column.

W = 700000;
rows = [];
for k = 1:8
    try
        s = one_closure_step(aero, prop, wts, geom, miss, WS, TW, W);
    catch
        rows = [rows; k, W, NaN, NaN, NaN, NaN, NaN, NaN]; %#ok<AGROW>
        break
    end
    rows = [rows; k, W, s.S_ref, s.W_fuel, s.W_OEW, s.denom, s.W0_new, s.residual]; %#ok<AGROW>
    W = s.W0_new;
end
plain = array2table(rows, 'VariableNames', ...
    ["pass", "W_TO_in", "S_ref", "W_fuel", "W_OEW", "denom", "W_TO_out", "residual"])

%%
%[text] ## It does not settle. It blows up.
%[text] Look at the residual column: it changes sign every pass and it gets **bigger**, not smaller. By pass 5 the closure is being asked about a ten-million-pound aeroplane; by pass 7 the denominator has gone negative, which says empty plus fuel now eats more than the whole takeoff weight. There is no such aircraft, so the closure returns `NaN` and stops.
%[text] Here is why. The closure map has a slope. From the first two passes 
%[text] $\frac{\Delta W^{new}}{\Delta W} \approx \frac{629{ }500 - 822{ }400}{822{ }400 - 700{ }000} \approx -1.6$
%[text] A slope steeper than 1 in magnitude means every pass **amplifies** the error instead of shrinking it. The negative sign is why it oscillates. Plain substitution cannot solve this problem.

%%
%[text] ## Under-relaxation: do not take the whole step
%[text] The fix is to move only part of the way to the new value:
%[text] $W \leftarrow W + w\ (W^{new} - W)$
%[text] In code this is `SizingSteps.relax(x_old, x_new, w)`. **Read the argument order carefully: `w` weights the NEW value.** So `w = 1` is the full undamped step you just watched fail, and `w = 0.5`, the default, goes halfway. Smaller `w` is slower but steadier.
%[text] The arithmetic: relaxation turns an effective slope of $-1.6$ into $1 + w(-1.6 - 1) = -0.29$ at $w = 0.5$. Under 1 in magnitude, so it converges - and quickly.

W = 700000;  w = 0.5;
rows = [];
for k = 1:8
    s = one_closure_step(aero, prop, wts, geom, miss, WS, TW, W);
    W_next = SizingSteps.relax(W, s.W0_new, w);
    rows = [rows; k, W, s.W0_new, W_next, abs(s.W0_new - W)/s.W0_new]; %#ok<AGROW>
    W = W_next;
end
relaxed = array2table(rows, 'VariableNames', ...
    ["pass", "W_TO_in", "W_TO_out", "W_TO_next_relaxed", "rel_residual"])

%%
%[text] ## The same thing as a picture
%[text] Plot what the closure does: the output weight against the input weight, with the 45-degree line. Where the two cross, input equals output and the aircraft is sized. The staircase is the iteration walking to that crossing.
%[text] The **slope** of the closure map at the crossing is worth staring at. It is the growth factor: how many pounds of takeoff weight one extra pound of payload buys. It also decides whether the plain iteration converges at all. A slope shallower than the 45-degree line converges; steeper than it diverges, and under-relaxation is what rescues you.

plot_cobweb(@build_b777_stack, WS, TW, linspace(500e3, 1000e3, 25), 700e3, 0.5, 10);

%%
%[text] ## Stop when the residual is small enough
%[text] The loop stops on a **relative** test 
%[text] $\frac{|W^{new} - W|}{W^{new}} < 10^{-6}$
%[text] Relative, so the same tolerance works for a 30 000 lbf fighter and a 750 000 lbf transport. Reference: metabook Algorithm 1 uses the same test.
%[text] That is the whole algorithm. **L05** hands it to the framework class and lets it run to convergence.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # L05 - The Level-1 sizing loop
%[text] **AOE 4065 - Aircraft Sizing, Lecture 5 of 7 (Boeing 777-200LR)**
%[text] L04 did one closure step by hand and repeated it. `SizingLoopL1` is exactly that, wrapped in a class with a convergence test, under-relaxation, a history log, and error messages for the ways it can fail.
%[text] **One state variable: $W_{TO}$.** The design point is solved **once, before the loop**, and then held. The wing and the engine are slaved to the weight through the two ratios. Reference: Martins slide 6.

%%
%[text] ## Build a fresh stack and run
%[text] The guess of 700,000 lbf is deliberately off the answer, so that a converged result proves the loop found the value instead of starting at it.

setup_sizing_path;
[aero, prop, wts, geom, miss, con] = build_b777_stack();
loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
result = loop.run(700000);

sized = table([result.W_TO; result.T_SL; result.S_ref; result.WS; result.TW; ...
               result.W_OEW; result.W_fuel; result.n_iter], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO  takeoff weight [lbf]', 'T_SL  sea-level thrust [lbf]', ...
     'S_ref wing area [ft^2]', 'W/S   wing loading [psf]', 'T/W   thrust-to-weight [-]', ...
     'W_OEW empty weight [lbf]', 'W_fuel mission fuel [lbf]', 'iterations'})

%%
%[text] ## The algorithm, in the order the code runs it
%[text] 1. solve the design point `[WS, TW] = con.optimal_point_continuous()` -- ONCE, before the loop
%[text] 2. `W = W_guess`
%[text] 3. repeat: `geom.S_ref = W / WS`
%[text] 4. repeat: `prop.T_SL = TW * W`
%[text] 5. repeat: `W_fuel = miss.total_fuel(W)`
%[text] 6. repeat: `W_OEW = wts.get_OEW(W)`
%[text] 7. repeat: `W_new = W_payload / (1 - W_OEW/W - W_fuel/W)`
%[text] 8. stop when `abs(W_new - W) / W_new < 1e-6`
%[text] 9. otherwise `W = SizingSteps.relax(W, W_new, 0.5)` and go again \
%[text] Six objects go in. One number iterates. Everything else is slaved to it.

%%
%[text] ## Watch it converge
%[text] Panel 2 is the one to look at: the residual falls by roughly a constant factor every pass. That straight line on a log axis is **linear convergence**, and its slope is set by the growth factor and the relaxation weight together.

plot_convergence(result, "B777-200LR, SizingLoopL1");

%%
%[text] ## The history log
%[text] Every pass is recorded. The `W0` column is the guess that pass started with; `W0_new` is what the closure returned. Compare them row by row and you are reading L04 again, one row per hand calculation.

history = struct2table(result.history)

%%
%[text] ## Compare with the real aircraft
%[text] Wing area lands almost exactly on the real 777. Takeoff weight comes out a few percent low and thrust lower still - and that is expected, not a bug. The loop sizes the **constraint optimum**: the smallest engine that still meets every requirement, $T/W = 0.266$. The real 777 was built with margin, at $T/W = 0.287$. A bigger engine means a heavier aircraft.

target = [766800; 220000; 4605];
got    = [result.W_TO; result.T_SL; result.S_ref];
versus_real = table(got, target, 100*(got - target)./target, ...
    'VariableNames', ["Sized", "Real_777_200LR", "Percent_diff"], ...
    'RowNames', {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]'})

%%
%[text] ## What the loop left alone
%[text] The tail. `SizingLoopL1` has no tail sizer, so the horizontal and vertical tails were never given an area. The 777 geometry file does not carry one either, so they are still undefined.
%[text] That is the first concrete thing Level 2 buys, and it is where **L06** starts.

untouched = table([geom.S_ht; geom.S_vt], ...
    'VariableNames', "Area_ft2", 'RowNames', {'S_ht horizontal tail', 'S_vt vertical tail'})

%%
%[text] ## Where the weight went

plot_weight_breakdown(result, wts, "B777-200LR, Level-1 loop");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

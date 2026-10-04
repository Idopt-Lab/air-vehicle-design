%[text] # LAB 01 - Write the Level-2 sizing loop
%[text] **AOE 4065 - Aircraft Sizing Lab (F-16A Block 10/15)**
%[text] Your job: write the body of a **two-state** sizing loop for the F-16A. The discipline models, the stack wiring and the checker are all given. You write about thirty lines.
%[text] The Level-2 loop differs from LAB 00 in three ways:
%[text] 1. **Two unknowns.** $T_{SL}$ is now an independent state, under-relaxed like $W_{TO}$, not a number slaved to the weight.
%[text] 2. **The design point is re-solved every pass**, warm-started from the previous one. At Level 2 the aero object holds the geometry, so a wing change moves the drag, which moves every constraint curve.
%[text] 3. **The tail is resized every pass**, and the empty weight reads the new tail areas. \
%[text] Reference: Martins slide 8. Look at `framework/src/sizing/SizingLoopL2.m` only **after** you have tried it.

%%
%[text] ## Given: setup and a fresh stack
%[text] Construction order is forced by dependency injection: `prop` first, then `geom(prop)`, then `aero(geom)`, then `wts(geom, prop)`, then `tail(geom)`. Read `helpers/build_f16_stack_L2.m` if you want to see it.

setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_f16_stack_L2();

W_TO_guess = 30000;      % lbf
T_SL_guess = 20000;      % lbf
tol_rel    = 1e-6;
max_iter   = 200;
relax_W    = 0.5;
relax_T    = 0.5;

%%
%[text] ## Given: the seed
%[text] Write the thrust guess into the propulsion object **before** the first design-point solve. The F-16 nacelle is sized from engine thrust, the nacelle sets part of the wetted area, the wetted area sets $C_{D0}$, and $C_{D0}$ sets every constraint curve. Seed it in the wrong order and the first solve answers a question about the wrong engine.

W0   = W_TO_guess;
T_SL = T_SL_guess;

prop.T_SL = T_SL;
[WS, TW]  = con.optimal_point_continuous();

converged = false;
hist      = [];

%%
%[text] ## YOUR CODE - the loop body
%[text] Six steps. Do them **in this order**; the order is part of the answer.
%[text] **1. Wing.** Set `geom.S_ref` from `W0` and `WS`.
%[text] **2. Tail.** Call `tail.size()` - it takes no arguments, it reads the geometry it was given. Write the two areas it returns into `geom.S_ht` and `geom.S_vt`. Do this **before** step 5, because the weights model reads those areas.
%[text] **3. Thrust.** Write the current state `T_SL` into `prop.T_SL`. Do this **before** step 4, so the design-point solve sees this pass drag, not the previous pass drag.
%[text] **4. Design point.** Re-solve with a warm start: `con.optimal_point_continuous([WS, TW])`. Then form the new thrust demand, `T_SL_new = TW * W0`.
%[text] **5. Fuel and empty weight.** `miss.total_fuel(W0)` and `wts.get_OEW(W0)`, then set `wts.W_TO` and `wts.W_energy`.
%[text] **6. Close, test, relax.** Use `SizingSteps.togw_update`. Stop when **both** states have converged - the test is an `&&`, not an `||`. Otherwise under-relax both with `SizingSteps.relax`. \
%[text] Delete each `error(...)` line as you replace it.

for iter = 1:max_iter

    % ---- 1. Wing resize from the current design point -------------------
    error("TODO 1: set geom.S_ref from W0 and WS");

    % ---- 2. Tail resize -------------------------------------------------
    error("TODO 2: tail_result = tail.size(), then write geom.S_ht and geom.S_vt");

    % ---- 3. Thrust write, BEFORE the constraint solve --------------------
    error("TODO 3: write the current T_SL state into prop.T_SL");

    % ---- 4. Re-solve the design point, warm-started ----------------------
    error("TODO 4: [WS, TW] = con.optimal_point_continuous([WS, TW]); T_SL_new = TW*W0");

    % ---- 5. Mission fuel and empty weight --------------------------------
    error("TODO 5: W_fuel from miss, W_OEW from wts, then set wts.W_TO and wts.W_energy");

    % ---- 6. Close the weight ---------------------------------------------
    error("TODO 6: W_payload, then SizingSteps.togw_update");

    % ---- given: the history log ------------------------------------------
    hist = [hist; iter, W0, T_SL, WS, TW, geom.S_ref, ...
            tail_result.S_ht, tail_result.S_vt, W_OEW, W_fuel, W0_new, T_SL_new, denom]; %#ok<AGROW>

    % ---- 6b. converge on BOTH states, or relax BOTH -----------------------
    error("TODO 6b: the && convergence test, then SizingSteps.relax on W0 and on T_SL");
end

mine = struct('W_TO', W0, 'T_SL', T_SL, 'S_ref', geom.S_ref, ...
              'n_iter', iter, 'converged', converged);

%%
%[text] ## Check your loop
%[text] The checker builds a brand-new stack, runs `SizingLoopL2` from the same guesses, and compares. A correct loop matches to less than a pound.

[ok, report] = check_my_loop(mine);

%%
%[text] ## Look at what you built

answer = table([mine.W_TO; mine.T_SL; mine.S_ref; WS; TW; mine.n_iter], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]', 'W/S [psf]', 'T/W [-]', 'iterations'})

passes = array2table(hist, 'VariableNames', ...
    ["iter", "W0", "T_SL", "WS", "TW", "S_ref", "S_ht", "S_vt", ...
     "W_OEW", "W_fuel", "W0_new", "T_SL_new", "denom"])

%%
%[text] ## Watch the second state converge
%[text] The bottom-right panel is the one LAB 00 did not have: $T_{SL}$ walking to its own fixed point at the same time as the weight.

[a, p, w, g, m, c, t] = build_f16_stack_L2();
ref = SizingLoopL2(a, p, w, g, m, c, t).run(W_TO_guess, T_SL_guess);
plot_convergence(ref, "F-16A, SizingLoopL2, CAP mission");

%%
%[text] ## How close is this to a real F-16A?
%[text] Not very. Understand why before you worry about it.
%[text] The loop sizes the **constraint optimum** - the smallest aircraft that meets the eight requirements in the file - using textbook regressions for the drag, the engine deck and the structure. The real F-16A carries margin on all of them. The gap is a statement about the discipline models and the requirement set, **not** about your loop.
%[text] Your loop is correct if the checker above says PASS. That is the thing this lab is testing.

brandt = [31377; 23770; 300];
got    = [ref.W_TO; ref.T_SL; ref.S_ref];
versus = table(got, brandt, 100*(got - brandt)./brandt, ...
    'VariableNames', ["Sized", "Brandt_F16A", "Percent_diff"], ...
    'RowNames', {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]'})

%%
%[text] ## Now answer the worksheet
%[text] Open `lab/LAB_worksheet.pdf` and work through it. Every question is an experiment you run on the loop you just wrote.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

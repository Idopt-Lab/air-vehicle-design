%[text] # LAB 01 - SOLUTION
%[text] **AOE 4065 - Aircraft Sizing Lab (F-16A Block 10/15) - instructor copy**
%[text] The completed Level-2 loop. Every line matches `framework/src/sizing/SizingLoopL2.m` step for step, so the checker agrees to the last pound.

%%
%[text] ## Setup and a fresh stack
setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_f16_stack_L2();

W_TO_guess = 30000;
T_SL_guess = 20000;
tol_rel    = 1e-6;
max_iter   = 200;
relax_W    = 0.5;
relax_T    = 0.5;

%%
%[text] ## Seed
W0   = W_TO_guess;
T_SL = T_SL_guess;

prop.T_SL = T_SL;                       % nacelle, hence CD0, hence every curve
[WS, TW]  = con.optimal_point_continuous();

converged = false;
hist      = [];

%%
%[text] ## The loop
for iter = 1:max_iter

    % ---- 1. Wing resize from the current design point -------------------
    geom.S_ref = W0 / WS;

    % ---- 2. Tail resize. Before the empty weight, which reads these. ----
    tail_result = tail.size();
    geom.S_ht = tail_result.S_ht;
    geom.S_vt = tail_result.S_vt;

    % ---- 3. Thrust write, BEFORE the constraint solve --------------------
    prop.T_SL = T_SL;

    % ---- 4. Re-solve the design point, warm-started ----------------------
    [WS, TW] = con.optimal_point_continuous([WS, TW]);
    T_SL_new = TW * W0;

    % ---- 5. Mission fuel and empty weight --------------------------------
    [W_fuel, ~] = miss.total_fuel(W0);
    W_OEW        = wts.get_OEW(W0);
    wts.W_TO     = W0;
    wts.W_energy = W_fuel;

    % ---- 6. Close the weight  [Raymer Eq. 3.4; metabook Algorithm 1] -----
    W_payload = wts.W_payload_fixed + wts.W_payload_expendable;
    [W0_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);

    % ---- given: the history log ------------------------------------------
    hist = [hist; iter, W0, T_SL, WS, TW, geom.S_ref, ...
            tail_result.S_ht, tail_result.S_vt, W_OEW, W_fuel, W0_new, T_SL_new, denom]; %#ok<AGROW>

    % ---- 6b. converge on BOTH states, or relax BOTH -----------------------
    if abs(W0_new - W0) / W0_new < tol_rel && ...
       abs(T_SL_new - T_SL) / T_SL_new < tol_rel
        W0   = W0_new;
        T_SL = T_SL_new;
        converged = true;
        break
    end
    W0   = SizingSteps.relax(W0,   W0_new,   relax_W);
    T_SL = SizingSteps.relax(T_SL, T_SL_new, relax_T);
end

mine = struct('W_TO', W0, 'T_SL', T_SL, 'S_ref', geom.S_ref, ...
              'n_iter', iter, 'converged', converged);

%%
%[text] ## Check
[ok, report] = check_my_loop(mine);

%%
%[text] ## Result

answer = table([mine.W_TO; mine.T_SL; mine.S_ref; WS; TW; mine.n_iter], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]', 'W/S [psf]', 'T/W [-]', 'iterations'})

passes = array2table(hist, 'VariableNames', ...
    ["iter", "W0", "T_SL", "WS", "TW", "S_ref", "S_ht", "S_vt", ...
     "W_OEW", "W_fuel", "W0_new", "T_SL_new", "denom"])

%%
%[text] ## Marking notes
%[text] Six mistakes account for nearly every failure:
%[text] 1. **Relaxation backwards.** `SizingSteps.relax(x_old, x_new, w)` returns `x_old + w*(x_new - x_old)`. The weight `w` is on the NEW value. Writing `w*x_old + (1-w)*x_new` converges to the same fixed point but by a different path, so the iteration count differs and, when the loop is stopped early, so does the answer.
%[text] 2. **Thrust written after the design-point solve.** Then the solve reads the previous pass drag. The answer still converges, but to a slightly different point.
%[text] 3. **Tail sized after the empty weight.** The weights model then sees the previous pass tail.
%[text] 4. **`||` instead of `&&`** in the convergence test. The loop stops as soon as the weight settles, while the thrust is still moving.
%[text] 5. **`T_SL_new` taken from the relaxed state** rather than from `TW * W0`.
%[text] 6. **Re-using a stack.** Running the loop twice without rebuilding starts the second run from the first run leftovers. \
%[text] A student whose numbers are close but not equal has almost certainly hit 1, 2 or 3. Ask them to print the `passes` table and compare row 1 against the reference.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

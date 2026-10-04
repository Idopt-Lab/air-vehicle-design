%[text] # LAB 00 - Warm-up: the Level-1 loop, written out
%[text] **AOE 4065 - Aircraft Sizing Lab (F-16A Block 10/15)**
%[text] This file is **complete**. Run it, read it, and make sure you can follow every line. In LAB 01 you write the Level-2 version yourself, and it is the same shape with three things added.
%[text] Aircraft: F-16A. Mission: **CAP**, combat air patrol. The comparison values come from the Brandt F-16A workbook: $W_{TO} = 31{,}377$ lbf, $T_{SL} = 23{,}770$ lbf, $S_{ref} = 300$ ft².

%%
%[text] ## Setup
setup_sizing_path;
[aero, prop, wts, geom, miss, con] = build_f16_stack_L1();

W_TO_guess = 30000;      % lbf
tol_rel    = 1e-6;
max_iter   = 200;
relaxation = 0.5;

%%
%[text] ## Step 0 - solve the design point, ONCE
%[text] At Level 1 the aerodynamics object holds **no geometry**. It reads aspect ratio and sweep as plain numbers from the spec file, so the drag polar cannot change when the wing changes, so no constraint curve can move. That is what makes it legal to solve the design point once and freeze it.

[WS, TW] = con.optimal_point_continuous();

design_point = table([WS; TW], 'VariableNames', "Value", ...
    'RowNames', {'(W/S)* [psf]', '(T/W)* [-]'})

%%
%[text] ## The loop
%[text] Five things happen on every pass, and this is the order:
%[text] 1. size the wing from the design point
%[text] 2. size the engine from the design point
%[text] 3. ask the mission for the fuel
%[text] 4. ask the weights model for the empty weight
%[text] 5. close the weight, test, and under-relax \

W0        = W_TO_guess;
converged = false;
hist      = [];

for iter = 1:max_iter

    % 1. Wing, sized by the fixed design point.
    geom.S_ref = W0 / WS;
    if isprop(geom, 'W_TO')       % L1 regression geometries carry W_TO
        geom.W_TO = W0;
    end

    % 2. Engine, sized by the fixed design point.
    prop.T_SL = TW * W0;

    % 3. Mission fuel at the current weight.
    [W_fuel, ~] = miss.total_fuel(W0);

    % 4. Empty weight at the current weight.
    W_OEW = wts.get_OEW(W0);
    wts.W_TO     = W0;            % bookkeeping the weights object wants
    wts.W_energy = W_fuel;

    % 5. Close, test, relax.   [Raymer 6th ed. Eq. 3.4; metabook Algorithm 1]
    W_payload = wts.W_payload_fixed + wts.W_payload_expendable;
    [W0_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);

    hist = [hist; iter, W0, W_OEW, W_fuel, denom, W0_new]; %#ok<AGROW>

    if abs(W0_new - W0) / W0_new < tol_rel
        W0 = W0_new;
        converged = true;
        break
    end
    W0 = SizingSteps.relax(W0, W0_new, relaxation);   % w weights the NEW value
end

mine = struct('W_TO', W0, 'T_SL', TW*W0, 'S_ref', W0/WS, ...
              'n_iter', iter, 'converged', converged);

%%
%[text] ## What it found

answer = table([mine.W_TO; mine.T_SL; mine.S_ref; WS; TW; mine.n_iter; mine.converged], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]', 'W/S [psf]', 'T/W [-]', ...
     'iterations', 'converged'})

%%
%[text] ## Every pass, in a table
%[text] Column `W0` is the guess that pass started with. Column `W0_new` is what the closure returned. The loop stops when the two agree to one part in a million.

passes = array2table(hist, 'VariableNames', ...
    ["iter", "W0", "W_OEW", "W_fuel", "denom", "W0_new"])

%%
%[text] ## Check against the framework class
%[text] `SizingLoopL1` is the same algorithm as a class. On a brand-new stack, from the same guess, it must give the same answer.

[a, p, w, g, m, c] = build_f16_stack_L1();
ref = SizingLoopL1(a, p, w, g, m, c).run(W_TO_guess);

check = table([mine.W_TO; mine.T_SL; mine.S_ref], [ref.W_TO; ref.T_SL; ref.S_ref], ...
    abs([mine.W_TO - ref.W_TO; mine.T_SL - ref.T_SL; mine.S_ref - ref.S_ref]), ...
    'VariableNames', ["Yours", "SizingLoopL1", "AbsDiff"], ...
    'RowNames', {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]'})

%%
%[text] ## Compare with the real F-16A
%[text] Not close, and that is fine. The Level-1 models are regressions and the loop sizes the constraint optimum, not the aircraft General Dynamics actually built. **Accuracy against the real aircraft is a different question from whether your loop is correct.** This lab grades the second one.

plot_convergence(ref, "F-16A, SizingLoopL1, CAP mission");

brandt = [31377; 23770; 300];
got    = [ref.W_TO; ref.T_SL; ref.S_ref];
versus = table(got, brandt, 100*(got - brandt)./brandt, ...
    'VariableNames', ["Sized", "Brandt_F16A", "Percent_diff"], ...
    'RowNames', {'W_TO [lbf]', 'T_SL [lbf]', 'S_ref [ft^2]'})

%%
%[text] ## Before you move on
%[text] Make sure you can answer these without looking:
%[text] 1. Why is the design point solved outside the loop and not inside it?
%[text] 2. What does `SizingSteps.relax(W0, W0_new, 0.5)` return, and which of the two weights does the 0.5 apply to?
%[text] 3. What does the denominator going to zero mean, physically?
%[text] 4. Why does this file call `build_f16_stack_L1` a second time before running `SizingLoopL1`? \
%[text] Now open **LAB01_write_the_L2_loop.mlx**.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

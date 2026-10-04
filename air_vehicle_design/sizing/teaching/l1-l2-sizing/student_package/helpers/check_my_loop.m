function [ok, tbl] = check_my_loop(mine, W_TO_guess, T_SL_guess, tol_lbf)
%CHECK_MY_LOOP  Grade a hand-written Level-2 sizing loop.
%
%   [ok, tbl] = CHECK_MY_LOOP(mine) compares your answer with the framework
%   class SizingLoopL2, run on a BRAND-NEW F-16A stack from the same guesses.
%
%   mine  struct with fields W_TO, T_SL, S_ref  (n_iter and converged
%         are reported when present)
%
%   A correct loop matches to less than 1 lbf. This is not a comparison with
%   the real F-16. It asks one question only: does your loop do the same
%   arithmetic, in the same order, as the reference implementation?
%
%   How close the sized aircraft is to the real F-16A is a separate question,
%   and the lab looks at it separately.

    arguments
        mine       (1,1) struct
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
        tol_lbf    (1,1) double {mustBePositive} = 1.0
    end

    need = ["W_TO", "T_SL", "S_ref"];
    miss = need(~isfield(mine, need));
    if ~isempty(miss)
        error('check_my_loop:missingFields', ...
            ['Your result struct has no field %s.\n', ...
             'Build it like this:  mine = struct(''W_TO'', W0, ''T_SL'', T_SL, ' ...
             '''S_ref'', geom.S_ref);'], strjoin(miss, ', '));
    end

    [a, p, w, g, m, c, t] = build_f16_stack_L2();
    ref = SizingLoopL2(a, p, w, g, m, c, t).run(W_TO_guess, T_SL_guess);

    got  = [mine.W_TO;  mine.T_SL;  mine.S_ref];
    want = [ref.W_TO;   ref.T_SL;   ref.S_ref];
    dif  = abs(got - want);
    tol  = [tol_lbf; tol_lbf; 0.01];          % lbf, lbf, ft^2
    pass = dif <= tol;

    tbl = table(got, want, dif, tol, pass, ...
        'VariableNames', ["Yours", "Reference", "AbsDiff", "Tolerance", "Pass"], ...
        'RowNames', {'W_TO  [lbf]', 'T_SL  [lbf]', 'S_ref [ft^2]'});

    ok = all(pass);
    fprintf('\n');
    disp(tbl);
    if ok
        fprintf('  PASS -- your loop reproduces SizingLoopL2.\n');
        if isfield(mine, 'n_iter')
            fprintf('         %d iterations, reference took %d.\n', mine.n_iter, ref.n_iter);
        end
    else
        fprintf('  FAIL -- look at the first row that does not pass.\n');
        fprintf('  Things that catch people out:\n');
        fprintf('    * SizingSteps.relax(x_old, x_new, w) weights the NEW value.\n');
        fprintf('    * Write prop.T_SL BEFORE the constraint solve, not after.\n');
        fprintf('    * Size the tail BEFORE asking for the empty weight.\n');
        fprintf('    * The convergence test needs AND on both states, not OR.\n');
        fprintf('    * Relax with T_SL_new = TW*W0, not with the TW from the seed solve.\n');
        fprintf('    * Build a FRESH stack before your loop. Handles keep their state.\n');
    end
    fprintf('\n');
end
